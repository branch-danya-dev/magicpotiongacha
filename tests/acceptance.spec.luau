--!nonstrict
-- Portable acceptance evidence only: no Roblox engine, clients or real DataStore.
local Config = require("../src/shared/Config")
local Factory = require("../src/shared/Factory")
local Protocol = require("../src/shared/Protocol")
local ProfileStore = require("../src/server/ProfileStore")

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = copy(child) end
	return result
end

return function(T)
	local function firstCycle()
		local engine, gate = Factory.new(Config), Protocol.new()
		local now = 100000
		local profile = engine.newProfile(-1, now)
		engine.grantHistoricalStarters(profile)
		local function waitFor(seconds)
			now += seconds
			local report = engine.advance(profile, now, false)
			T.truthy(report.ok, report.error)
			T.truthy(engine.validate(profile))
		end
		local function intent(action, payload)
			waitFor(1)
			if action == "buy" then
				payload.expectedLevel = payload.upgradeId == "pipes" and (profile.pipes and 1 or 0) or profile.stations[payload.upgradeId].level
			end
			local accepted, reason = gate:check(profile.userId, action, payload, now)
			T.truthy(accepted, reason)
			local ok, message = engine.act(profile, action, payload, now)
			T.truthy(ok, action .. ": " .. tostring(message))
			T.truthy(engine.validate(profile))
		end
		-- All resources are earned through the actual protocol and domain actions.
		for _ = 1, 3 do intent("click", {}) end
		intent("harvest", { stationId = "garden" })
		waitFor(Config.manualHarvestCooldown)
		intent("harvest", { stationId = "garden" })
		intent("load", { stationId = "cauldron" })
		intent("brew", { stationId = "cauldron" })
		waitFor(Config.recipes.healing.duration)
		T.equal(profile.gold, 14)
		T.truthy(profile.discoveredRecipes.healing)
		-- M1: earn the early pipes through a second manual sale; no seeded balance.
		for _ = 1, 3 do intent("click", {}) end
		intent("harvest", { stationId = "garden" })
		waitFor(Config.manualHarvestCooldown)
		intent("harvest", { stationId = "garden" })
		intent("load", { stationId = "cauldron" })
		intent("brew", { stationId = "cauldron" })
		waitFor(Config.recipes.healing.duration)
		intent("buy", { upgradeId = "pipes" })
		for station, id in pairs({ garden = "starter_farmer", logistics = "starter_slime", cauldron = "starter_brewer" }) do
			intent("assign", { stationId = station, petId = "-1:" .. id })
		end
		intent("setAuto", { stationId = "cauldron", enabled = true })
		for _ = 1, 300 do
			if profile.gold >= Config.stations.crystal.upgradeCosts[2] then break end
			intent("click", {})
		end
		T.truthy(profile.gold >= 140, "Starter chain must fund passive Essence without seeded resources")
		intent("buy", { upgradeId = "crystal" })
		T.equal(profile.stations.crystal.level, 2)
		local before = profile.gold
		waitFor(600)
		T.truthy(profile.gold > before, "Factory must keep producing without more clicks")
		return engine, profile, now
	end

	T.test("acceptance: zero-resource Studio identity reaches autonomous Healing through valid intents", function()
		firstCycle()
	end)

	T.test("acceptance: persisted two-hour cap survives an immediate second session without duplicate rewards", function()
		local engine, fixture, now = firstCycle()
		local records = {}
		local backend = { UpdateAsync = function(_, key, transform)
			local result = transform(copy(records[key]))
			if result ~= nil then records[key] = copy(result) end
			return copy(result)
		end }
		local function store(owner)
			return ProfileStore.new({ dataStore = backend, now = function() return now end,
				owner = owner, validate = engine.validate, sleep = function() end })
		end
		local first = store("A")
		T.truthy(first:load(-1, function() return copy(fixture) end))
		T.truthy(first:release(-1))
		now += 10800
		local second = store("B")
		local profile = second:load(-1, function() return engine.newProfile(-1, now) end)
		T.truthy(profile)
		T.same(profile, fixture) -- The fresh candidate must not replace an existing record.
		local expected = copy(fixture)
		local result = engine.advance(expected, now, true)
		local report = engine.advance(profile, now, true)
		T.truthy(report.ok)
		T.equal(report.processedSeconds, 7200)
		T.equal(report.skippedSeconds, 3600)
		T.truthy(report.goldEarned > 0)
		T.same(report, result)
		T.same(profile, expected)
		T.truthy(second:save(-1)) -- Runtime must confirm catch-up before showing it.
		T.truthy(second:release(-1))
		local third = store("C")
		local rejoined = third:load(-1, function() return engine.newProfile(-1, now) end)
		T.truthy(rejoined)
		local repeated = engine.advance(rejoined, now, true)
		T.truthy(repeated.ok)
		T.equal(repeated.processedSeconds, 0)
		T.equal(repeated.goldEarned, 0)
		T.same(rejoined, expected) -- Includes cargo, buffers, jobs and PRNG state.
		T.truthy(third:release(-1))
	end)
end
