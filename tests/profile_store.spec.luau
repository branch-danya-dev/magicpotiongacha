--!nonstrict
local ProfileStore = require("../src/server/ProfileStore")

local function copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, child in pairs(value) do
		result[key] = copy(child)
	end
	return result
end

local function newProfile()
	return { schemaVersion = 1, gold = 0, inventory = {}, tutorialGranted = true }
end

local function validate(profile)
	if profile.schemaVersion ~= 1 then
		return false, "unsupported_profile_schema"
	end
	if type(profile.gold) ~= "number" or profile.gold < 0 or profile.gold % 1 ~= 0 then
		return false, "invalid_gold"
	end
	return true
end

local function fixture()
	local state = { time = 1000 }
	local dataStore = {
		records = {},
		calls = 0,
		writes = 0,
		beforeFailures = 0,
		afterFailures = 0,
		replays = 0,
	}
	function dataStore:UpdateAsync(key, transform)
		self.calls += 1
		if self.beforeFailures > 0 then
			self.beforeFailures -= 1
			error("simulated request failure")
		end
		if self.beforeUpdate then
			self.beforeUpdate(key)
		end
		for _ = 1, self.replays do
			transform(copy(self.records[key])) -- Discarded CAS callback attempt.
		end
		if self.conflict then
			transform(copy(self.records[key]))
			local conflict = self.conflict
			self.conflict = nil
			conflict(key)
		end
		local replacement = transform(copy(self.records[key]))
		if replacement ~= nil then
			self.records[key] = copy(replacement)
			self.writes += 1
		end
		if self.afterFailures > 0 then
			self.afterFailures -= 1
			error("simulated lost response after commit")
		end
		return copy(replacement)
	end
	state.dataStore = dataStore
	function state.adapter(owner, overrides)
		local options = {
			dataStore = dataStore,
			now = function() return state.time end,
			owner = owner or "server-A",
			validate = validate,
			sleep = function(seconds)
				if state.onSleep then
					state.onSleep(seconds)
				else
					state.time += seconds
				end
			end,
			leaseSeconds = 120,
			retries = 3,
		}
		for name, value in pairs(overrides or {}) do
			options[name] = value
		end
		return ProfileStore.new(options)
	end
	return state
end

return function(T)
	T.test("store: missing key acquires a lease and initializes once", function()
		local f = fixture()
		local store = f.adapter()
		local profile, reason = store:load(42, newProfile)
		T.truthy(profile)
		T.equal(reason, nil)
		T.equal(profile.gold, 0)
		T.equal(f.dataStore.records["p:42"].lease.owner, "server-A")
		T.equal(f.dataStore.records["p:42"].lease.expiresAt, 1120)
		T.equal(f.dataStore.records["p:42"].revision, 1)
		T.truthy(store:isWritable(42))
	end)

	T.test("store: local mutations do not change the stored snapshot", function()
		local f = fixture()
		local store = f.adapter()
		local profile = store:load(1, newProfile)
		profile.gold = 25
		profile.inventory.mandrake = 3
		T.equal(store:get(1), profile)
		T.equal(f.dataStore.records["p:1"].profile.gold, 0)
		T.equal(f.dataStore.records["p:1"].profile.inventory.mandrake, nil)
		T.truthy(store:save(1))
		T.equal(f.dataStore.records["p:1"].profile.gold, 25)
		profile.inventory.mandrake = 999
		T.equal(f.dataStore.records["p:1"].profile.inventory.mandrake, 3)
	end)

	T.test("store: duplicate load returns the same live profile without a second write", function()
		local f = fixture()
		local store = f.adapter()
		local profile = store:load(1, newProfile)
		profile.gold = 7
		local calls = f.dataStore.calls
		local again = store:load(1, function() error("must not create a default") end)
		T.equal(profile, again)
		T.equal(again.gold, 7)
		T.equal(f.dataStore.calls, calls)
	end)

	T.test("store: a second owner cannot load an active session", function()
		local f = fixture()
		local first = f.adapter("A")
		local second = f.adapter("B")
		first:load(1, newProfile)
		local profile, reason = second:load(1, newProfile)
		T.equal(profile, nil)
		T.equal(reason, "session_locked")
		T.equal(second:get(1), nil)
		T.falsy(second:isWritable(1))
		T.equal(f.dataStore.records["p:1"].lease.owner, "A")
		T.equal(f.dataStore.records["p:1"].revision, 1)
	end)

	T.test("store: different users have independent leases", function()
		local f = fixture()
		local a = f.adapter("A")
		local b = f.adapter("B")
		T.truthy(a:load(1, newProfile))
		T.truthy(b:load(2, newProfile))
		T.truthy(a:isWritable(1))
		T.truthy(b:isWritable(2))
	end)

	T.test("store: expiry permits takeover and fences the stale writer", function()
		local f = fixture()
		local a = f.adapter("A")
		local old = a:load(1, newProfile)
		old.gold = 10
		T.truthy(a:save(1))
		f.time += 121
		local b = f.adapter("B")
		local fresh = b:load(1, newProfile)
		T.equal(fresh.gold, 10)
		fresh.gold = 50
		T.truthy(b:save(1))
		old.gold = 999
		local ok, reason = a:save(1)
		T.falsy(ok)
		T.equal(reason, "lease_expired")
		T.falsy(a:isWritable(1))
		T.falsy(a:release(1))
		T.equal(f.dataStore.records["p:1"].profile.gold, 50)
		T.equal(f.dataStore.records["p:1"].lease.owner, "B")
	end)

	T.test("store: safety margin freezes actions but permits a verified renewal", function()
		local f = fixture()
		local store = f.adapter()
		store:load(1, newProfile)
		f.time = 1105
		T.falsy(store:isWritable(1))
		T.truthy(store:save(1))
		T.equal(f.dataStore.records["p:1"].lease.expiresAt, 1225)
		T.truthy(store:isWritable(1))
	end)

	T.test("store: an expired session cannot silently reacquire through save", function()
		local f = fixture()
		local store = f.adapter()
		store:load(1, newProfile)
		f.time = 1120
		local calls = f.dataStore.calls
		local ok, reason = store:save(1)
		T.falsy(ok)
		T.equal(reason, "lease_expired")
		T.equal(f.dataStore.calls, calls)
	end)

	T.test("store: lost ownership is checked against persisted state", function()
		local f = fixture()
		local store = f.adapter("A")
		store:load(1, newProfile)
		f.dataStore.records["p:1"].lease.owner = "B"
		local ok, reason = store:save(1)
		T.falsy(ok)
		T.equal(reason, "lease_lost")
		T.falsy(store:isWritable(1))
		T.falsy(store:release(1))
		T.equal(f.dataStore.records["p:1"].lease.owner, "B")
	end)

	T.test("store: revision conflicts cannot overwrite a newer snapshot", function()
		local f = fixture()
		local store = f.adapter()
		local profile = store:load(1, newProfile)
		profile.gold = 10
		f.dataStore.records["p:1"].revision += 1
		f.dataStore.records["p:1"].profile.gold = 900
		local ok, reason = store:save(1)
		T.falsy(ok)
		T.equal(reason, "revision_conflict")
		T.equal(f.dataStore.records["p:1"].profile.gold, 900)
		T.falsy(store:isWritable(1))
	end)

	T.test("store: future record schema is rejected without overwrite", function()
		local f = fixture()
		f.dataStore.records["p:1"] = { schemaVersion = 99, profile = newProfile(), revision = 1 }
		local store = f.adapter()
		local profile, reason = store:load(1, newProfile)
		T.equal(profile, nil)
		T.equal(reason, "unsupported_record_schema")
		T.equal(f.dataStore.writes, 0)
		T.falsy(store:save(1))
		T.equal(f.dataStore.records["p:1"].schemaVersion, 99)
	end)

	T.test("store: future game profile schema is rejected without defaults", function()
		local f = fixture()
		f.dataStore.records["p:1"] = {
			schemaVersion = 1, profile = { schemaVersion = 2, gold = 999 }, revision = 1,
		}
		local store = f.adapter()
		local profile, reason = store:load(1, newProfile)
		T.equal(profile, nil)
		T.equal(reason, "invalid_profile:unsupported_profile_schema")
		T.equal(f.dataStore.writes, 0)
		T.equal(f.dataStore.records["p:1"].profile.gold, 999)
	end)

	T.test("store: invalid stored profile never becomes a fresh player", function()
		local f = fixture()
		f.dataStore.records["p:1"] = {
			schemaVersion = 1, profile = { schemaVersion = 1, gold = -100 }, revision = 1,
		}
		local store = f.adapter()
		local profile, reason = store:load(1, newProfile)
		T.equal(profile, nil)
		T.equal(reason, "invalid_profile:invalid_gold")
		T.equal(store:get(1), nil)
		T.equal(f.dataStore.writes, 0)
	end)

	T.test("store: invalid envelope lease and revision are rejected", function()
		local f = fixture()
		f.dataStore.records["p:1"] = {
			schemaVersion = 1, profile = newProfile(), revision = 0,
		}
		local store = f.adapter()
		local _, reason = store:load(1, newProfile)
		T.equal(reason, "invalid_record_revision")
		f.dataStore.records["p:1"].revision = 1
		f.dataStore.records["p:1"].lease = { owner = "X", expiresAt = "tomorrow" }
		_, reason = store:load(1, newProfile)
		T.equal(reason, "invalid_record_lease")
		T.equal(f.dataStore.writes, 0)
	end)

	T.test("store: exhausted load errors leave no writable default profile", function()
		local f = fixture()
		f.dataStore.beforeFailures = 3
		local store = f.adapter()
		local profile, reason = store:load(1, newProfile)
		T.equal(profile, nil)
		T.equal(reason, "data_store_unavailable")
		T.equal(store:get(1), nil)
		T.falsy(store:isWritable(1))
		T.falsy(store:save(1))
		T.equal(f.dataStore.records["p:1"], nil)
		T.equal(f.dataStore.calls, 3)
	end)

	T.test("store: transient load errors retry with the same acquisition", function()
		local f = fixture()
		f.dataStore.beforeFailures = 2
		local store = f.adapter()
		T.truthy(store:load(1, newProfile))
		T.equal(f.dataStore.calls, 3)
		T.equal(f.dataStore.records["p:1"].revision, 1)
	end)

	T.test("store: unknown load outcome does not initialize a second profile", function()
		local f = fixture()
		f.dataStore.afterFailures = 1
		local store = f.adapter()
		local created = 0
		local profile = store:load(1, function()
			created += 1
			local p = newProfile()
			p.gold = 73
			return p
		end)
		T.truthy(profile)
		T.equal(created, 1)
		T.equal(profile.gold, 73)
		T.equal(f.dataStore.records["p:1"].revision, 1)
	end)

	T.test("store: lost load responses can be retried later without resetting data", function()
		local f = fixture()
		local store = f.adapter(nil, { retries = 1 })
		f.dataStore.afterFailures = 1
		local profile = store:load(1, function()
			local p = newProfile()
			p.gold = 81
			return p
		end)
		T.equal(profile, nil)
		T.equal(store:get(1), nil)
		T.equal(f.dataStore.records["p:1"].profile.gold, 81)
		profile = store:load(1, newProfile)
		T.equal(profile.gold, 81)
	end)

	T.test("store: save request failures pause writes and can recover before expiry", function()
		local f = fixture()
		local store = f.adapter()
		local profile = store:load(1, newProfile)
		profile.gold = 9
		f.dataStore.beforeFailures = 3
		local ok, reason = store:save(1)
		T.falsy(ok)
		T.equal(reason, "data_store_unavailable")
		T.falsy(store:isWritable(1))
		T.equal(f.dataStore.records["p:1"].profile.gold, 0)
		T.truthy(store:save(1))
		T.truthy(store:isWritable(1))
		T.equal(f.dataStore.records["p:1"].profile.gold, 9)
	end)

	T.test("store: save retries recognize an already committed operation", function()
		local f = fixture()
		local store = f.adapter()
		local profile = store:load(1, newProfile)
		profile.gold = 77
		f.dataStore.afterFailures = 1
		T.truthy(store:save(1))
		T.equal(f.dataStore.records["p:1"].revision, 2)
		T.equal(f.dataStore.records["p:1"].profile.gold, 77)
		T.truthy(store:isWritable(1))
	end)

	T.test("store: unconfirmed writes cannot later overwrite a newer revision", function()
		local f = fixture()
		local store = f.adapter(nil, { retries = 1 })
		local profile = store:load(1, newProfile)
		profile.gold = 33
		f.dataStore.afterFailures = 1
		T.falsy(store:save(1))
		T.equal(f.dataStore.records["p:1"].profile.gold, 33)
		local ok, reason = store:save(1)
		T.falsy(ok)
		T.equal(reason, "revision_conflict")
		T.falsy(store:isWritable(1))
	end)

	T.test("store: callback replay changes no gameplay state or revision twice", function()
		local f = fixture()
		f.dataStore.replays = 3
		local store = f.adapter()
		local profile = store:load(1, newProfile)
		T.equal(f.dataStore.records["p:1"].revision, 1)
		profile.gold = 100
		T.truthy(store:save(1))
		T.equal(profile.gold, 100)
		T.equal(f.dataStore.records["p:1"].profile.gold, 100)
		T.equal(f.dataStore.records["p:1"].revision, 2)
	end)

	T.test("store: callback replay observes a competing lease and cancels", function()
		local f = fixture()
		local store = f.adapter("A")
		store:load(1, newProfile)
		f.dataStore.conflict = function(key)
			f.dataStore.records[key].lease.owner = "B"
			f.dataStore.records[key].revision += 1
		end
		local ok, reason = store:save(1)
		T.falsy(ok)
		T.equal(reason, "lease_lost")
		T.equal(f.dataStore.records["p:1"].lease.owner, "B")
	end)

	T.test("store: release persists latest profile and clears its own lease", function()
		local f = fixture()
		local a = f.adapter("A")
		local profile = a:load(1, newProfile)
		profile.gold = 45
		T.truthy(a:release(1))
		T.equal(a:get(1), nil)
		T.falsy(a:isWritable(1))
		T.equal(f.dataStore.records["p:1"].lease, nil)
		local b = f.adapter("B")
		T.equal(b:load(1, newProfile).gold, 45)
	end)

	T.test("store: duplicate release is a no-op, not a second persistence write", function()
		local f = fixture()
		local store = f.adapter()
		store:load(1, newProfile)
		T.truthy(store:release(1))
		local calls = f.dataStore.calls
		T.truthy(store:release(1))
		T.equal(f.dataStore.calls, calls)
	end)

	T.test("store: failed release preserves the lock and freezes gameplay", function()
		local f = fixture()
		local store = f.adapter()
		store:load(1, newProfile).gold = 19
		f.dataStore.beforeFailures = 3
		T.falsy(store:release(1))
		T.equal(f.dataStore.records["p:1"].lease.owner, "server-A")
		T.falsy(store:isWritable(1))
		T.falsy(store:save(1))
		T.truthy(store:release(1))
		T.equal(f.dataStore.records["p:1"].profile.gold, 19)
		T.equal(f.dataStore.records["p:1"].lease, nil)
	end)

	T.test("store: release retries recognize a successful commit with a lost response", function()
		local f = fixture()
		local store = f.adapter()
		store:load(1, newProfile).gold = 28
		f.dataStore.afterFailures = 1
		T.truthy(store:release(1))
		T.equal(f.dataStore.records["p:1"].profile.gold, 28)
		T.equal(f.dataStore.records["p:1"].revision, 2)
		T.equal(f.dataStore.records["p:1"].lease, nil)
	end)

	T.test("store: failed validation on save does not persist corrupt memory", function()
		local f = fixture()
		local store = f.adapter()
		local profile = store:load(1, newProfile)
		profile.gold = -2
		local calls = f.dataStore.calls
		T.falsy(store:save(1))
		T.falsy(store:isWritable(1))
		T.equal(f.dataStore.calls, calls)
		T.equal(f.dataStore.records["p:1"].profile.gold, 0)
	end)

	T.test("store: a disappeared key is not replaced with the local snapshot", function()
		local f = fixture()
		local store = f.adapter()
		store:load(1, newProfile)
		f.dataStore.records["p:1"] = nil
		local ok, reason = store:save(1)
		T.falsy(ok)
		T.equal(reason, "record_missing")
		T.equal(f.dataStore.records["p:1"], nil)
	end)

	T.test("store: non-serializable profile values are rejected", function()
		local cases = {
			function(p) p.inventory.x = 0 / 0 end,
			function(p) p.inventory.x = math.huge end,
			function(p) p.inventory.x = function() end end,
			function(p) p.inventory.self = p end,
			function(p) p.inventory[false] = 2 end,
			function(p) setmetatable(p.inventory, {}) end,
			function(p) p.inventory = { [1] = 2, name = "mixed" } end,
			function(p) p.inventory = { [3] = "sparse" } end,
		}
		for _, corrupt in ipairs(cases) do
			local f = fixture()
			local store = f.adapter()
			local profile = store:load(1, newProfile)
			corrupt(profile)
			T.falsy(store:save(1))
			T.equal(f.dataStore.records["p:1"].revision, 1)
		end
	end)

	T.test("store: a failing validator or factory cannot create a record", function()
		local f = fixture()
		local store = f.adapter()
		local profile, reason = store:load(1, function() error("factory crashed") end)
		T.equal(profile, nil)
		T.equal(reason, "profile_factory_failed")
		local broken = f.adapter("B", { validate = function() error("validator crashed") end })
		T.equal(broken:load(1, newProfile), nil)
		T.equal(f.dataStore.calls, 0)
	end)

	T.test("store: invalid IDs are rejected, Studio negative IDs remain usable", function()
		local f = fixture()
		local store = f.adapter()
		T.equal(store:load("1", newProfile), nil)
		T.equal(store:load(1.5, newProfile), nil)
		T.falsy(store:save(0 / 0))
		T.falsy(store:release(math.huge))
		T.equal(f.dataStore.calls, 0)
		T.truthy(store:load(-1, newProfile))
		T.truthy(store:isWritable(-1))
	end)

	T.test("store: invalid clocks fail closed without persistence", function()
		local f = fixture()
		local store = f.adapter()
		store:load(1, newProfile)
		local calls = f.dataStore.calls
		f.time = 0 / 0
		T.falsy(store:isWritable(1))
		T.falsy(store:save(1))
		T.equal(f.dataStore.calls, calls)
	end)

	T.test("store: release waits for autosave then captures the newest memory", function()
		local f = fixture()
		local store = f.adapter()
		local profile = store:load(1, newProfile)
		profile.gold = 10
		local pause = true
		f.dataStore.beforeUpdate = function()
			if pause then
				pause = false
				coroutine.yield("saving")
			end
		end
		local saveResult
		local saving = coroutine.create(function() saveResult = store:save(1) end)
		local resumed, marker = coroutine.resume(saving)
		T.truthy(resumed)
		T.equal(marker, "saving")
		profile.gold = 20
		f.onSleep = function() coroutine.yield("waiting_for_save") end
		local releaseResult
		local closing = coroutine.create(function() releaseResult = store:release(1) end)
		resumed, marker = coroutine.resume(closing)
		T.truthy(resumed)
		T.equal(marker, "waiting_for_save")
		T.falsy(store:isWritable(1))
		T.truthy(coroutine.resume(saving))
		T.truthy(saveResult)
		T.equal(f.dataStore.records["p:1"].profile.gold, 10)
		T.truthy(coroutine.resume(closing))
		T.truthy(releaseResult)
		T.equal(f.dataStore.records["p:1"].profile.gold, 20)
		T.equal(f.dataStore.records["p:1"].lease, nil)
	end)

	T.test("store: a gate timeout preserves memory for a subsequent release retry", function()
		local f = fixture()
		local store = f.adapter(nil, { gateTimeoutSeconds = 0.1 })
		local profile = store:load(1, newProfile)
		local pause = true
		f.dataStore.beforeUpdate = function()
			if pause then
				pause = false
				coroutine.yield("saving")
			end
		end
		local saving = coroutine.create(function() store:save(1) end)
		T.truthy(coroutine.resume(saving))
		profile.gold = 30
		local ok, reason = store:release(1)
		T.falsy(ok)
		T.equal(reason, "profile_busy")
		T.equal(store:get(1).gold, 30)
		T.falsy(store:isWritable(1))
		T.truthy(coroutine.resume(saving))
		T.truthy(store:release(1))
		T.equal(f.dataStore.records["p:1"].profile.gold, 30)
	end)

	T.test("store: profile identity cannot disagree with the DataStore user key", function()
		local f = fixture()
		local store = f.adapter()
		local profile, reason = store:load(1, function()
			local p = newProfile()
			p.userId = 2
			return p
		end)
		T.equal(profile, nil)
		T.equal(reason, "profile_user_mismatch")
		T.equal(f.dataStore.calls, 0)
		f.dataStore.records["p:1"] = {
			schemaVersion = 1, revision = 1,
			profile = { schemaVersion = 1, userId = 2, gold = 99 },
		}
		profile, reason = store:load(1, newProfile)
		T.equal(profile, nil)
		T.equal(reason, "profile_user_mismatch")
		T.equal(f.dataStore.writes, 0)
	end)

	T.test("store: quarantine blocks saves/releases without touching persisted data", function()
		local f = fixture()
		local store = f.adapter()
		local profile = store:load(1, newProfile)
		profile.gold = 999
		T.truthy(store:invalidate(1))
		T.falsy(store:isWritable(1))
		T.equal(store:get(1), profile) -- Diagnostics only; never writable.
		local calls = f.dataStore.calls
		local saved, saveReason = store:save(1)
		local released, releaseReason = store:release(1)
		T.falsy(saved)
		T.falsy(released)
		T.equal(saveReason, "profile_invalidated")
		T.equal(releaseReason, "profile_invalidated")
		T.equal(f.dataStore.calls, calls)
		T.equal(f.dataStore.records["p:1"].profile.gold, 0)
		T.truthy(f.dataStore.records["p:1"].lease)
		T.equal(store:load(1, newProfile), nil)
	end)

	T.test("store: quarantine during in-flight save cannot reopen writable state", function()
		local f = fixture()
		local store = f.adapter()
		local profile = store:load(1, newProfile)
		profile.gold = 10
		local pause = true
		f.dataStore.beforeUpdate = function()
			if pause then
				pause = false
				coroutine.yield("saving")
			end
		end
		local result
		local saving = coroutine.create(function() result = store:save(1) end)
		T.truthy(coroutine.resume(saving))
		profile.gold = 999
		store:invalidate(1)
		T.truthy(coroutine.resume(saving))
		T.truthy(result) -- The independent pre-corruption snapshot safely committed.
		T.equal(f.dataStore.records["p:1"].profile.gold, 10)
		T.falsy(store:isWritable(1))
		T.falsy(store:save(1))
		T.falsy(store:release(1))
		T.equal(f.dataStore.records["p:1"].profile.gold, 10)
	end)

	T.test("store: a queued release after quarantine never snapshots tainted memory", function()
		local f = fixture()
		local store = f.adapter()
		local profile = store:load(1, newProfile)
		profile.gold = 5
		local pause = true
		f.dataStore.beforeUpdate = function()
			if pause then
				pause = false
				coroutine.yield("saving")
			end
		end
		local saving = coroutine.create(function() store:save(1) end)
		T.truthy(coroutine.resume(saving))
		f.onSleep = function() coroutine.yield("waiting") end
		local result, reason
		local closing = coroutine.create(function() result, reason = store:release(1) end)
		T.truthy(coroutine.resume(closing))
		profile.gold = 100000
		store:invalidate(1)
		T.truthy(coroutine.resume(saving))
		T.truthy(coroutine.resume(closing))
		T.falsy(result)
		T.equal(reason, "profile_invalidated")
		T.equal(f.dataStore.records["p:1"].profile.gold, 5)
		T.truthy(f.dataStore.records["p:1"].lease)
	end)
end
