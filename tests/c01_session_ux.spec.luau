--!nonstrict
-- First-session presentation. Factory remains the only place that grants currency or familiars.
local Config = require("../src/shared/Config")
local Factory = require("../src/shared/Factory")
local View = require("../src/shared/FirstSessionView")
local Rain = require("../src/shared/RainField")
local Boundary = require("../src/shared/IslandBoundary")
local Environment = require("../src/shared/EnvironmentState")
local ProfileStore = require("../src/server/ProfileStore")

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = copy(child) end
	return result
end

local function count(map)
	local total = 0
	for _ in pairs(map) do total += 1 end
	return total
end

local function ids(list)
	local result = {}
	for _, entry in ipairs(list) do table.insert(result, entry.id) end
	return result
end

return function(T)
	local session = Config.firstSession
	local bed = session.bedId

	T.test("C01 UX: a new player gets the familiar choice and only the crystal", function()
		T.equal(Config.schemaVersion, 8)
		local engine = Factory.new(Config)
		local profile = engine.newProfile(70, 17000)
		local gold, essence = profile.gold, profile.essence
		local view = View.present(profile, Config)
		T.equal(view.intro, true)
		T.equal(view.step, "familiar")
		T.same(ids(view.actions), { "farmer", "slime", "brewer" })
		T.equal(#view.menus, 0)
		T.equal(View.stationVisible(profile, Config, "crystal"), true)
		for _, stationId in ipairs(Config.stationOrder) do
			if stationId ~= "crystal" then T.equal(View.stationVisible(profile, Config, stationId), false, stationId) end
			T.equal(View.padVisible(profile, Config, stationId), false, stationId)
		end
		T.equal(View.stationVisible(profile, Config, "orders"), false)
		T.equal(View.stationVisible(profile, Config, "altar"), false)
		T.equal(profile.gold, gold)
		T.equal(profile.essence, essence)
		T.equal(count(profile.pets), 0)
	end)

	T.test("C01 UX: choice, rejoin, repeated actions and tutorial order stay server-owned", function()
		local engine = Factory.new(Config)
		local persisted = nil
		local now = 18000
		local fake = {}
		function fake:UpdateAsync(_key, transform)
			local updated = transform(persisted and copy(persisted) or nil)
			if updated == nil then return nil end
			persisted = copy(updated)
			return copy(persisted)
		end
		local function store(owner)
			return ProfileStore.new({
				dataStore = fake, now = function() return now end, owner = owner,
				validate = engine.validate, migrate = engine.migrate, sleep = function() end,
			})
		end
		local first = store("ux-a")
		local profile = first:load(70, function() return engine.newProfile(70, now) end)
		T.truthy(engine.claimStarterBudget(profile))
		T.truthy(engine.act(profile, "chooseStarter", { speciesId = "farmer" }, now))
		T.truthy(engine.act(profile, "chooseStarter", { speciesId = "farmer" }, now))
		T.falsy(engine.act(profile, "chooseStarter", { speciesId = "slime" }, now))
		T.equal(count(profile.pets), 1)
		T.equal(profile.starter.choice, "farmer")
		T.truthy(first:save(70))
		T.truthy(first:release(70))
		local rejoined = store("ux-b"):load(70, function() return engine.newProfile(70, now) end)
		T.equal(View.intro(rejoined), false)
		T.equal(count(rejoined.pets), 1)
		T.truthy(engine.act(rejoined, "chooseStarter", { speciesId = "farmer" }, now))
		T.equal(count(rejoined.pets), 1)
		local firstStep = View.step(rejoined, Config)
		local seen = { firstStep }
		local function remember()
			local step = View.step(rejoined, Config)
			if step and seen[#seen] ~= step then table.insert(seen, step) end
		end
		local gold = rejoined.gold
		T.truthy(engine.act(rejoined, "click", {}, now))
		T.equal(View.essenceDelta(0, rejoined.essence), Config.economyV2.clickEssence)
		T.equal(rejoined.gold, gold)
		T.truthy(engine.act(rejoined, "click", {}, now))
		T.equal(rejoined.essence, Config.economyV2.clickEssence * 2)
		T.equal(View.essenceDelta(rejoined.essence, rejoined.essence), 0)
		T.equal(rejoined.gold, gold)
		remember()
		T.equal(View.stationVisible(rejoined, Config, "garden"), true)
		T.equal(View.padVisible(rejoined, Config, "garden"), true)
		T.equal(View.stationVisible(rejoined, Config, "cauldron"), false)
		T.truthy(engine.act(rejoined, "buyStarterStation", { stationId = "garden" }, now))
		remember()
		T.truthy(engine.act(rejoined, "buySeed", { amount = session.openingSeeds }, now))
		remember()
		T.same(ids(View.actions(rejoined, Config)), { "plant" })
		T.truthy(engine.act(rejoined, "plantSeed", { bedId = bed }, now))
		T.equal(#View.actions(rejoined, Config), 0)
		T.falsy(engine.act(rejoined, "harvestCrop", { bedId = bed }, now))
		T.truthy(engine.advance(rejoined, now + session.growSeconds, false).ok)
		T.same(ids(View.actions(rejoined, Config)), { "harvest" })
		T.truthy(engine.act(rejoined, "harvestCrop", { bedId = bed }, now + session.growSeconds))
		T.falsy(engine.act(rejoined, "harvestCrop", { bedId = bed }, now + session.growSeconds))
		remember()
		T.equal(View.stationVisible(rejoined, Config, "cauldron"), true)
		T.equal(View.padVisible(rejoined, Config, "cauldron"), true)
		T.equal(View.stationVisible(rejoined, Config, "mine"), false)
		for _ = 1, 3 do T.truthy(engine.act(rejoined, "click", {}, rejoined.lastSimulatedAt)) end
		T.truthy(engine.act(rejoined, "buyStarterStation", { stationId = "cauldron" }, rejoined.lastSimulatedAt))
		remember()
		T.same(ids(View.actions(rejoined, Config)), { "brew" })
		T.truthy(engine.act(rejoined, "setRecipe", { stationId = "cauldron", recipeId = "healing" }, rejoined.lastSimulatedAt))
		T.truthy(engine.act(rejoined, "load", { stationId = "cauldron" }, rejoined.lastSimulatedAt))
		T.truthy(engine.act(rejoined, "brew", { stationId = "cauldron" }, rejoined.lastSimulatedAt))
		T.truthy(engine.advance(rejoined, rejoined.lastSimulatedAt + Config.economyV2.cauldron.brewSeconds[1], false).ok)
		T.equal(View.displayStep("brew", rejoined, Config), "sale")
		T.same(ids(View.actions(rejoined, Config, "brew")), { "sale" })
		T.equal(View.displayStep("sale", rejoined, Config), "automation")
		remember()
		T.truthy(engine.act(rejoined, "buyAutomation", { feature = "basic" }, rejoined.lastSimulatedAt))
		remember()
		T.equal(View.padVisible(rejoined, Config, "crystal"), true)
		T.equal(View.stationVisible(rejoined, Config, "mine"), false)
		local beforeUpgrade = rejoined.gold
		T.falsy(engine.act(rejoined, "buy", { upgradeId = "crystal", expectedLevel = rejoined.stations.crystal.level }, rejoined.lastSimulatedAt))
		T.equal(rejoined.gold, beforeUpgrade)
		T.equal(rejoined.stations.crystal.level, 1)
		T.same(seen, { "essence", "garden", "seeds", "crop", "cauldron", "brew", "automation", "passive" })
		local menus = View.menus(rejoined)
		T.same(ids(menus), { "supplies", "inventory", "familiars" })
		T.same(ids(View.menus(rejoined)), ids(menus))
		T.equal(rejoined.gold, beforeUpgrade)
		local client = copy(rejoined)
		client.tutorial = engine.tutorialState(rejoined)
		T.equal(View.present(client, Config).step, "passive")
		T.equal(View.present(client, Config).intro, false)
		local finished = copy(rejoined)
		for _, stepId in ipairs(session.tutorialSteps) do finished.tutorial[stepId] = true end
		T.equal(select(2, View.step(finished, Config)), true)
		T.equal(View.stationVisible(finished, Config, "garden"), true)
		T.equal(View.stationVisible(finished, Config, "cauldron"), true)
		T.equal(View.stationVisible(finished, Config, "mine"), false)
		T.equal(View.stationVisible(finished, Config, "orders"), true)
		T.equal(View.present(finished, Config).visible, false)
	end)

	T.test("C01 UX: a historical profile keeps the full station yard", function()
		local engine = Factory.new(Config)
		local profile = engine.newProfile(71, 19000)
		engine.grantHistoricalStarters(profile)
		T.equal(View.intro(profile), false)
		T.equal(#View.menus(profile), 3)
		for _, stationId in ipairs(Config.stationOrder) do
			T.equal(View.stationVisible(profile, Config, stationId), true, stationId)
			T.equal(View.padVisible(profile, Config, stationId), true, stationId)
		end
		local gold = profile.gold
		View.present(profile, Config)
		T.equal(profile.gold, gold)
		T.equal(count(profile.pets), 3)
	end)

	T.test("C01 UX: rain follows the camera across the island without changing weather", function()
		local cameras = {
			{ -142.5, -65 }, { -47.5, -65 }, { 47.5, -65 }, { 142.5, -65 },
			{ -142.5, 85 }, { -47.5, 85 }, { 47.5, 85 }, { 142.5, 85 },
			{ 0, 0 }, { 0, 10 },
		}
		for _, camera in ipairs(cameras) do
			for index = 1, 60 do
				local x, z = Rain.world(index, camera[1], camera[2])
				local dx, dz = x - camera[1], z - camera[2]
				local distance = math.sqrt(dx * dx + dz * dz)
				T.truthy(distance <= 20)
				T.truthy(distance >= 5.99)
				T.equal(Boundary.contains(x, z, 8), true)
			end
			local movedX, movedZ = Rain.world(1, camera[1] + 8, camera[2] - 4)
			local homeX, homeZ = Rain.world(1, camera[1], camera[2])
			T.truthy(math.abs((movedX - homeX) - 8) < 0.001)
			T.truthy(math.abs((movedZ - homeZ) + 4) < 0.001)
		end
		local farX = Rain.world(1, 142.5, 85)
		T.truthy(farX > -100)
		local full = Environment.quality(require("../src/shared/EnvironmentConfig"), "full", false)
		local reduced = Environment.quality(require("../src/shared/EnvironmentConfig"), "reduced", false)
		local minimal = Environment.quality(require("../src/shared/EnvironmentConfig"), "minimal", false)
		local still = Environment.quality(require("../src/shared/EnvironmentConfig"), "full", true)
		T.equal(full.rain, 60)
		T.equal(reduced.rain, 24)
		T.equal(minimal.rain, 0)
		T.equal(still.rain, 0)
		T.equal(Rain.visible(1, still.rain, 1, true), false)
		T.equal(Rain.visible(24, reduced.rain, 1, true), true)
		T.equal(Rain.visible(25, reduced.rain, 1, true), false)
		T.equal(Rain.visible(1, full.rain, 0, true), false)
		T.equal(Rain.visible(1, full.rain, 1, false), false)
	end)
end
