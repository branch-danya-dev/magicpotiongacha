--!nonstrict
local Config = require("../src/shared/Config")
local Factory = require("../src/shared/Factory")
local ProfileStore = require("../src/server/ProfileStore")
local legacy = require("./fixtures/m0-profile")
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = copy(child) end
	return result
end

return function(T: any)
	local engine = Factory.new(Config)
	local NOW = 100023
	local function storedFixture()
		return { schemaVersion = 1, revision = 4, lastOperationId = "old-release", profile = copy(legacy) }
	end
	local function harness(record, loseReply, migrator)
		local calls = 0
		local backend = { UpdateAsync = function(_, _, transform)
			calls += 1
			local a, b = transform(copy(record)), transform(copy(record))
			T.same(a, b, "Migration must tolerate callback replay")
			if a then record = copy(a) end
			if loseReply and calls == 1 then error("committed_reply_lost") end
			return copy(a)
		end }
		local function session(owner)
			return ProfileStore.new({ dataStore = backend, now = function() return NOW end,
				owner = owner or "new-session", validate = engine.validate, migrate = migrator or engine.migrate, sleep = function() end })
		end
		return session, function() return copy(record) end
	end

	T.test("M1 migration: V1 preserves all balances, timers, stock and prepaid jobs", function()
		local session, record = harness(storedFixture())
		local store = session()
		local p, reason = store:load(123, function() return engine.newProfile(123, NOW) end)
		T.truthy(p, reason)
		T.equal(p.schemaVersion, 2)
		for _, field in ipairs({ "gold", "essence", "inventory", "questStock", "order", "pets", "nextPetSerial", "rngState", "lastSimulatedAt", "manualReadyAt", "slimeWorkSeconds", "discoveredRecipes", "receipts", "entitlements" }) do
			T.same(p[field], legacy[field], field)
		end
		T.equal(p.stations.distillery.essence, 0)
		T.equal(p.stations.distillery.job.automatic, false)
		T.equal(p.stations.distillery.job.duration, legacy.stations.distillery.job.duration)
		T.same(p.stations.logistics.job, legacy.stations.logistics.job)
		T.equal(p.stations.logistics.progress, legacy.stations.logistics.progress)
		T.truthy(p.tutorial.manual)
		T.same(p.telemetry.first, {})
		T.equal(record().revision, 5)
		T.equal(record().profile.schemaVersion, 2)
		T.truthy(store:release(123))
	end)

	T.test("M1 migration: lost load reply retries without a second upgrade or grant", function()
		local session, record = harness(storedFixture(), true)
		local store = session()
		local p = store:load(123, function() return engine.newProfile(123, NOW) end)
		T.truthy(p)
		T.equal(record().revision, 5)
		T.equal(p.gold, legacy.gold)
		T.truthy(store:release(123))
		local before = record().profile
		local nextStore = session("next-session")
		T.same(nextStore:load(123, function() return engine.newProfile(123, NOW) end), before)
	end)

	T.test("M1 migration: old liquid cargo finishes once and old brewing stays prepaid", function()
		local p = engine.migrate(copy(legacy))
		local source = p.essence
		local report = engine.advance(p, NOW + 8, true)
		T.truthy(report.ok)
		T.truthy(engine.validate(p))
		T.equal(p.inventory.fire_extract, 2)
		T.equal(p.stations.distillery.output.fire_extract, 1)
		T.equal(p.essence, source + 8) -- Crystal income; no second cost for the old batch.
		local before = copy(p)
		engine.advance(p, NOW + 8, true)
		T.same(p, before)
	end)

	for _, corruption in ipairs({ "future", "bad-version", "bad-cargo", "wrong-user", "bad-timer", "NaN-duration" }) do
		T.test("M1 migration: fail closed and leave bytes intact / " .. corruption, function()
			local current = storedFixture()
			if corruption == "future" then current.profile.schemaVersion = 99
			elseif corruption == "bad-version" then current.profile.schemaVersion = 0
			elseif corruption == "bad-cargo" then current.profile.stations.logistics.job.amount = -1
			elseif corruption == "wrong-user" then current.profile.userId = 456
			elseif corruption == "bad-timer" then current.profile.lastSimulatedAt = -1
			else
				current.profile.stations.distillery.job.duration = 0 / 0
			end
			local session, record = harness(current)
			T.falsy(session():load(123, function() return engine.newProfile(123, NOW) end))
			T.equal(record().revision, 4)
			T.equal(record().lastOperationId, "old-release")
			T.equal(record().lease, nil)
		end)
	end

	T.test("M1 migration: foreign active lease cannot be upgraded or stolen", function()
		local current = storedFixture()
		current.lease = { owner = "other-server", expiresAt = NOW + 100 }
		local session, record = harness(current)
		local p, reason = session():load(123, function() return engine.newProfile(123, NOW) end)
		T.falsy(p)
		T.equal(reason, "session_locked")
		T.same(record(), current)
	end)

	for _, failure in ipairs({ "throw", "nil", "identity", "cycle" }) do
		T.test("M1 migration: broken migrator cannot replace a saved profile / " .. failure, function()
			local current = storedFixture()
			local function migrate(p)
				if failure == "throw" then error("migration_failed") end
				if failure == "nil" then return nil end
				p = engine.migrate(p)
				if failure == "identity" then p.userId = 456 else p.cycle = p end
				return p
			end
			local session, record = harness(current, false, migrate)
			T.falsy(session():load(123, function() return engine.newProfile(123, NOW) end))
			T.same(record(), current)
		end)
	end
end
