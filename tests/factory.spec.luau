--!strict
-- Deliberately dynamic at this boundary: this suite injects invalid persisted data.
local Config: any = require("../src/shared/Config")
local Factory: any = require("../src/shared/Factory")
local ProfileStore: any = require("../src/server/ProfileStore")

local START = 100000

local function clone(value: any): any
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = clone(item) end
	return result
end

local function count(map: any, itemId: string): number
	return map[itemId] or 0
end

local function size(map: any): number
	local result = 0
	for _ in pairs(map) do result += 1 end
	return result
end

local function petId(profile: any, species: string): string
	for id, pet in pairs(profile.pets) do
		if pet.species == species then return id end
	end
	error("Fixture familiar not found: " .. species)
end

return function(T: any)
	local function fresh(): (any, any)
		local engine = Factory.new(Config)
		local profile = engine.newProfile(123, START)
		engine.grantHistoricalStarters(profile)
		return engine, profile
	end

	local function act(engine: any, profile: any, action: string, payload: any, now: number?)
		if action == "buy" and payload.expectedLevel == nil then
			payload.expectedLevel = payload.upgradeId == "pipes" and (profile.pipes and 1 or 0)
				or (payload.upgradeId == "warehouse" and profile.warehouseLevel or profile.stations[payload.upgradeId].level)
		end
		local ok, reason = engine.act(profile, action, payload, now or profile.lastSimulatedAt)
		T.truthy(ok, action .. ": " .. tostring(reason))
		local valid, failure = engine.validate(profile)
		T.truthy(valid, action .. " produced invalid state: " .. tostring(failure))
	end

	local function advance(engine: any, profile: any, now: number, offline: boolean?): any
		local result = engine.advance(profile, now, offline == true)
		T.truthy(result.ok, result.error)
		local valid, failure = engine.validate(profile)
		T.truthy(valid, "advance produced invalid state: " .. tostring(failure))
		return result
	end

	local function assign(engine: any, profile: any, stationId: string, species: string)
		act(engine, profile, "assign", { stationId = stationId, petId = petId(profile, species) })
	end

	local function setupAutomated(): (any, any)
		local engine, profile = fresh()
		profile.gold = 1000
		-- Post-tutorial fixture; separate tests exercise the actual first-brew gate.
		profile.discoveredRecipes.healing = true
		act(engine, profile, "buy", { upgradeId = "crystal" })
		act(engine, profile, "buy", { upgradeId = "pipes" })
		assign(engine, profile, "garden", "farmer")
		assign(engine, profile, "logistics", "slime")
		assign(engine, profile, "cauldron", "brewer")
		act(engine, profile, "setAuto", { stationId = "cauldron", enabled = true })
		return engine, profile
	end

	local function manualHealing(engine: any, profile: any)
		profile.essence = math.max(profile.essence, Config.recipes.healing.essenceCost)
		profile.inventory.mandrake = math.max(count(profile.inventory, "mandrake"), 2)
		act(engine, profile, "load", { stationId = "cauldron" })
		act(engine, profile, "brew", { stationId = "cauldron" })
		return advance(engine, profile, profile.lastSimulatedAt + Config.recipes.healing.duration + 1)
	end

	local function resourceTotal(profile: any, itemId: string): number
		local amount = count(profile.inventory, itemId) + count(profile.questStock, itemId)
		for _, station in pairs(profile.stations) do
			amount += count(station.input, itemId) + count(station.output, itemId) + count(station.questQueue, itemId)
			if station.job and station.job.kind == "haul" and station.job.itemId == itemId then
				amount += station.job.amount
			end
		end
		return amount
	end

	T.test("factory: a new profile has no familiars; historical fixtures keep three", function()
		local engine = Factory.new(Config)
		local profile = engine.newProfile(123, START)
		T.truthy(engine.validate(profile))
		T.equal(profile.schemaVersion, Config.schemaVersion)
		T.equal(size(profile.pets), 0)
		T.equal(profile.starter.claimed, false)
		T.equal(profile.starter.legacyGrant, false)
		T.equal(profile.gold, 0)
		T.equal(profile.essence, 0)
		local _, historical = fresh()
		T.equal(size(historical.pets), 3)
		T.equal(historical.starter.legacyGrant, true)
		T.equal(historical.lastSimulatedAt, START)
		T.truthy(historical.tutorialGranted)
		for _, pet in pairs(historical.pets) do T.falsy(pet.paidOrigin) end
	end)

	T.test("factory: Studio and regular user identities have valid deterministic profiles", function()
		local engine = Factory.new(Config)
		for _, userId in ipairs({ -2, -1, 0, 1, 123, 9007199254740991 }) do
			local a, b = engine.newProfile(userId, START), engine.newProfile(userId, START)
			T.truthy(engine.validate(a))
			T.same(a, b)
		end
	end)

	T.test("factory: profile data does not alias configuration or another player", function()
		local engine, profile = fresh()
		local other = engine.newProfile(456, START)
		engine.grantHistoricalStarters(other)
		local id = petId(profile, "farmer")
		local original = profile.pets[id].stats.Farming
		profile.pets[id].stats.Farming = original + 1
		T.equal(other.pets[petId(other, "farmer")].stats.Farming, original)
		T.equal(Config.starterPets[1].stats.Farming, original)
	end)

	T.test("factory: starter instance IDs are unique across owners", function()
		local engine, profile = fresh()
		local other = engine.newProfile(456, START)
		engine.grantHistoricalStarters(other)
		for id in pairs(profile.pets) do T.equal(other.pets[id], nil) end
	end)

	T.test("factory: guaranteed hires spend configured Gold and have fixed stats", function()
		local engine, profile = fresh()
		local definition = Config.hires.farmer
		profile.gold = definition.cost * 2
		local rng = profile.rngState
		local original = clone(profile.pets)
		act(engine, profile, "hire", { speciesId = "farmer" })
		act(engine, profile, "hire", { speciesId = "farmer" })
		T.equal(profile.gold, 0)
		T.equal(size(profile.pets), size(original) + 2)
		T.equal(profile.rngState, rng)
		local hired = 0
		for id, pet in pairs(profile.pets) do
			if not original[id] then
				hired += 1
				T.equal(pet.species, "farmer")
				T.same(pet.stats, definition.stats)
				T.falsy(pet.paidOrigin)
			end
		end
		T.equal(hired, 2)
	end)

	T.test("factory: unaffordable or unknown hires cannot partially charge or mint", function()
		local engine, profile = fresh()
		local before = clone(profile)
		T.falsy(engine.act(profile, "hire", { speciesId = "farmer" }, START))
		T.falsy(engine.act(profile, "hire", { speciesId = "void_dragon" }, START + 100))
		T.same(profile, before)
	end)

	T.test("factory: hire capacity guard is checked before payment", function()
		local config = clone(Config)
		config.maxPets = #config.starterPets
		local engine = Factory.new(config)
		local profile = engine.newProfile(123, START)
		engine.grantHistoricalStarters(profile)
		profile.gold = 1000
		local before = clone(profile)
		T.falsy(engine.act(profile, "hire", { speciesId = "farmer" }, START))
		T.same(profile, before)
	end)

	T.test("factory: server click adds exactly one Essence", function()
		local engine, profile = fresh()
		act(engine, profile, "click", {})
		T.equal(profile.essence, 1)
		T.equal(profile.gold, 0)
		local before = clone(profile)
		T.falsy(engine.act(profile, "click", { amount = 1000000 }, START))
		T.same(profile, before)
	end)

	T.test("factory: unknown and malformed actions cannot advance or mutate a profile", function()
		local engine, profile = fresh()
		local before = clone(profile)
		T.falsy(engine.act(profile, "grantGold", {}, START + 100))
		T.falsy(engine.act(profile, "buy", { upgradeId = "not-a-slot" }, START + 100))
		T.falsy(engine.act(profile, "assign", { stationId = "garden", petId = "not-owned" }, START + 100))
		T.falsy(engine.act(profile, "setAuto", { stationId = "cauldron", enabled = "true" }, START + 100))
		T.same(profile, before)
	end)

	T.test("factory: clicks respect the finite balance ceiling", function()
		local engine, profile = fresh()
		profile.essence = Config.maxBalance
		T.falsy(engine.act(profile, "click", {}, START))
		T.equal(profile.essence, Config.maxBalance)
	end)

	T.test("factory: manual gathering has a persistent server-time cooldown", function()
		local engine, profile = fresh()
		act(engine, profile, "harvest", { stationId = "garden" })
		T.equal(count(profile.inventory, "mandrake"), 1)
		T.falsy(engine.act(profile, "harvest", { stationId = "garden" }, START))
		T.falsy(engine.act(profile, "harvest", { stationId = "garden" }, START + Config.manualHarvestCooldown - 1))
		act(engine, profile, "harvest", { stationId = "garden" }, START + Config.manualHarvestCooldown)
		T.equal(count(profile.inventory, "mandrake"), 2)
	end)

	T.test("factory: unbuilt mine cannot gather or host a worker", function()
		local engine, profile = fresh()
		T.falsy(engine.act(profile, "harvest", { stationId = "mine" }, START))
		T.falsy(engine.act(profile, "assign", { stationId = "mine", petId = petId(profile, "farmer") }, START))
		T.equal(profile.stations.mine.level, 0)
		T.equal(count(profile.inventory, "coal"), 0)
	end)

	T.test("factory: an unaffordable upgrade spends nothing", function()
		local engine, profile = fresh()
		local before = clone(profile)
		T.falsy(engine.act(profile, "buy", { upgradeId = "mine" }, START))
		T.same(profile, before)
	end)

	T.test("factory: an upgrade uses server configuration and applies once", function()
		local engine, profile = fresh()
		local price = Config.stations.mine.upgradeCosts[1]
		profile.gold = price
		act(engine, profile, "buy", { upgradeId = "mine" })
		T.equal(profile.gold, 0)
		T.equal(profile.stations.mine.level, 1)
		T.falsy(engine.act(profile, "buy", { upgradeId = "mine" }, START))
		T.equal(profile.stations.mine.level, 1)
	end)

	T.test("factory: maximum upgrades are bounded", function()
		local engine, profile = fresh()
		profile.gold = 100000
		for _ = 2, #Config.stations.crystal.upgradeCosts do
			act(engine, profile, "buy", { upgradeId = "crystal" })
		end
		local gold = profile.gold
		T.falsy(engine.act(profile, "buy", { upgradeId = "crystal" }, START))
		T.equal(profile.gold, gold)
	end)

	T.test("factory: one familiar cannot occupy two workplaces", function()
		local engine, profile = fresh()
		assign(engine, profile, "garden", "farmer")
		local id = petId(profile, "farmer")
		T.falsy(engine.act(profile, "assign", { stationId = "crystal", petId = id }, START))
		T.equal(profile.stations.garden.workerId, id)
		T.equal(profile.stations.crystal.workerId, nil)
		act(engine, profile, "assign", { stationId = "garden", petId = "" })
		act(engine, profile, "assign", { stationId = "crystal", petId = id })
		T.equal(profile.stations.garden.workerId, nil)
	end)

	T.test("factory: only crystal workplace and crystal upgrades generate Essence", function()
		local engine, profile = fresh()
		assign(engine, profile, "garden", "farmer")
		assign(engine, profile, "cauldron", "brewer")
		advance(engine, profile, START + 30)
		T.equal(profile.essence, 0)
		act(engine, profile, "assign", { stationId = "garden", petId = "" })
		assign(engine, profile, "crystal", "farmer")
		advance(engine, profile, START + 40)
		T.truthy(profile.essence > 0)
	end)

	T.test("factory: passive crystal upgrades work without occupying a familiar", function()
		local engine, profile = fresh()
		profile.gold = 1000
		act(engine, profile, "buy", { upgradeId = "crystal" })
		local result = advance(engine, profile, START + 10)
		T.equal(profile.essence, Config.stations.crystal.passiveEssence[2] * 10)
		T.equal(result.essenceEarned, profile.essence)
		T.equal(profile.stations.crystal.workerId, nil)
	end)

	T.test("factory: clamped stats preserve the original familiar roll", function()
		local engine, profile = fresh()
		local id = petId(profile, "brewer")
		profile.pets[id].stats.Brewing = 500
		-- Preserve a strong legacy instance, rather than invent an out-of-range new roll.
		profile.pets[id].rarity, profile.pets[id].provenance.source = "Legacy", "legacy"
		profile.pets[id].provenance.tradeKnown = false
		profile.essence = 100
		profile.inventory.mandrake = 2
		assign(engine, profile, "cauldron", "brewer")
		act(engine, profile, "load", { stationId = "cauldron" })
		act(engine, profile, "brew", { stationId = "cauldron" })
		local cap = Config.stations.cauldron.statCaps[1]
		T.near(profile.stations.cauldron.job.duration, Config.recipes.healing.duration / (1 + cap * 0.035))
		T.equal(profile.pets[id].stats.Brewing, 500)
	end)

	T.test("factory: farming above the station cap provides no extra throughput", function()
		local engine, high = fresh()
		local capped = clone(high)
		local id = petId(high, "farmer")
		high.pets[id].stats.Farming = 500
		high.pets[id].rarity, high.pets[id].provenance.source = "Legacy", "legacy"
		high.pets[id].provenance.tradeKnown = false
		capped.pets[id].stats.Farming = Config.stations.garden.statCaps[1]
		assign(engine, high, "garden", "farmer")
		assign(engine, capped, "garden", "farmer")
		advance(engine, high, START + 15)
		advance(engine, capped, START + 15)
		T.same(high.stations.garden, capped.stations.garden)
	end)

	T.test("factory: auto-brewing requires an assigned worker", function()
		local engine, profile = fresh()
		T.falsy(engine.act(profile, "setAuto", { stationId = "cauldron", enabled = true }, START))
		assign(engine, profile, "cauldron", "brewer")
		T.falsy(engine.act(profile, "setAuto", { stationId = "cauldron", enabled = true }, START))
		manualHealing(engine, profile)
		act(engine, profile, "setAuto", { stationId = "cauldron", enabled = true })
		T.truthy(profile.stations.cauldron.auto)
	end)

	T.test("factory: selecting an undiscovered recipe disables automation", function()
		local engine, profile = setupAutomated()
		profile.gold = 1000
		act(engine, profile, "buy", { upgradeId = "cauldron" })
		act(engine, profile, "setRecipe", { stationId = "cauldron", recipeId = "rage" })
		T.falsy(profile.stations.cauldron.auto)
		T.falsy(engine.act(profile, "setAuto", { stationId = "cauldron", enabled = true }, START))
	end)

	T.test("factory: loading conserves physical ingredients", function()
		local engine, profile = fresh()
		profile.inventory.mandrake = 5
		local before = resourceTotal(profile, "mandrake")
		act(engine, profile, "load", { stationId = "cauldron" })
		T.equal(resourceTotal(profile, "mandrake"), before)
		T.equal(count(profile.stations.cauldron.input, "mandrake"), Config.recipes.healing.inputs.mandrake)
	end)

	T.test("factory: a batch reserves ingredients and Essence exactly once", function()
		local engine, profile = fresh()
		profile.inventory.mandrake = 4
		profile.essence = 30
		act(engine, profile, "load", { stationId = "cauldron" })
		local before = resourceTotal(profile, "mandrake")
		act(engine, profile, "brew", { stationId = "cauldron" })
		T.equal(resourceTotal(profile, "mandrake"), before - Config.recipes.healing.inputs.mandrake)
		T.equal(profile.essence, 30 - Config.recipes.healing.essenceCost)
		local reserved = clone(profile)
		T.falsy(engine.act(profile, "brew", { stationId = "cauldron" }, START))
		T.same(profile, reserved)
	end)

	T.test("factory: missing inputs or Essence do not partially charge a batch", function()
		local engine, profile = fresh()
		profile.essence = 100
		local before = clone(profile)
		T.falsy(engine.act(profile, "brew", { stationId = "cauldron" }, START))
		T.same(profile, before)
		profile.essence = 0
		profile.stations.cauldron.input.mandrake = 2
		before = clone(profile)
		T.falsy(engine.act(profile, "brew", { stationId = "cauldron" }, START))
		T.same(profile, before)
	end)

	T.test("factory: ordinary potions export even when raw storage is full", function()
		local engine, profile = fresh()
		profile.inventory.mandrake = Config.warehouse.rawCapacity[1]
		profile.stations.cauldron.input.mandrake = 2
		profile.essence = 100
		act(engine, profile, "load", { stationId = "cauldron" })
		act(engine, profile, "brew", { stationId = "cauldron" })
		local result = advance(engine, profile, START + 10)
		T.equal(profile.gold, Config.recipes.healing.goldValue)
		T.equal(count(profile.inventory, "mandrake"), Config.warehouse.rawCapacity[1])
		T.equal(count(profile.questStock, "healing"), 0)
		T.equal(count(profile.inventory, "healing"), 0)
		T.equal(result.sold.healing, 1)
	end)

	T.test("factory: unfinished batches cannot be switched into another recipe", function()
		local engine, profile = fresh()
		profile.gold, profile.essence = 1000, 100
		act(engine, profile, "buy", { upgradeId = "cauldron" })
		profile.inventory.mandrake = 2
		act(engine, profile, "load", { stationId = "cauldron" })
		act(engine, profile, "brew", { stationId = "cauldron" })
		local before = clone(profile)
		T.falsy(engine.act(profile, "setRecipe", { stationId = "cauldron", recipeId = "rage" }, START))
		T.same(profile, before)
	end)

	T.test("factory: recipe switching returns loaded ingredients without loss", function()
		local engine, profile = fresh()
		profile.gold = 1000
		act(engine, profile, "buy", { upgradeId = "cauldron" })
		profile.inventory.mandrake = 4
		act(engine, profile, "load", { stationId = "cauldron" })
		act(engine, profile, "setRecipe", { stationId = "cauldron", recipeId = "rage" })
		T.equal(count(profile.inventory, "mandrake"), 4)
		T.equal(size(profile.stations.cauldron.input), 0)
	end)

	T.test("factory: recipe switching rejects when returning inputs would overflow", function()
		local engine, profile = fresh()
		profile.gold = 1000
		act(engine, profile, "buy", { upgradeId = "cauldron" })
		profile.inventory.mandrake = Config.warehouse.rawCapacity[1]
		profile.stations.cauldron.input.mandrake = 2
		local before = clone(profile)
		T.falsy(engine.act(profile, "setRecipe", { stationId = "cauldron", recipeId = "rage" }, START))
		T.same(profile, before)
	end)

	T.test("factory: station upgrades preserve older recipe compatibility", function()
		local engine, profile = fresh()
		profile.gold = 1000
		act(engine, profile, "buy", { upgradeId = "cauldron" })
		T.equal(profile.stations.cauldron.recipeId, "healing")
		manualHealing(engine, profile)
		T.truthy(profile.discoveredRecipes.healing)
		act(engine, profile, "setRecipe", { stationId = "cauldron", recipeId = "rage" })
		act(engine, profile, "setRecipe", { stationId = "cauldron", recipeId = "healing" })
		T.truthy(profile.discoveredRecipes.healing)
	end)

	T.test("factory: collection respects capacity and retains uncollected output", function()
		local engine, profile = fresh()
		profile.inventory.mandrake = Config.warehouse.rawCapacity[1] - 1
		profile.stations.garden.output.mandrake = 3
		local before = resourceTotal(profile, "mandrake")
		act(engine, profile, "collect", { stationId = "garden" })
		T.equal(count(profile.inventory, "mandrake"), Config.warehouse.rawCapacity[1])
		T.equal(count(profile.stations.garden.output, "mandrake"), 2)
		T.equal(resourceTotal(profile, "mandrake"), before)
		T.falsy(engine.act(profile, "collect", { stationId = "garden" }, START))
	end)

	T.test("factory: intermediate storage is independent of raw storage", function()
		local engine, profile = fresh()
		profile.gold = 1000
		act(engine, profile, "buy", { upgradeId = "distillery" })
		profile.inventory.mandrake = Config.warehouse.rawCapacity[1]
		profile.stations.distillery.output.fire_extract = 2
		act(engine, profile, "collect", { stationId = "distillery" })
		T.equal(count(profile.inventory, "fire_extract"), 2)
		T.equal(count(profile.inventory, "mandrake"), Config.warehouse.rawCapacity[1])
	end)

	T.test("factory: full intermediate output blocks only its own new batch", function()
		local engine, profile = fresh()
		profile.gold, profile.essence = 1000, 100
		act(engine, profile, "buy", { upgradeId = "distillery" })
		profile.stations.distillery.output.fire_extract = Config.machineOutputCapacity
		profile.stations.distillery.input.coal = 2
		local before = clone(profile)
		T.falsy(engine.act(profile, "brew", { stationId = "distillery" }, START))
		T.same(profile, before)
		local gold = profile.gold
		manualHealing(engine, profile)
		T.equal(profile.gold, gold + Config.recipes.healing.goldValue)
	end)

	T.test("factory: complete automated starter chain earns Gold", function()
		local engine, profile = setupAutomated()
		local gold = profile.gold
		local result = advance(engine, profile, START + 600)
		T.truthy(profile.gold > gold)
		T.truthy(result.goldEarned > 0)
		T.truthy(count(result.produced, "mandrake") > 0)
		T.truthy(count(result.sold, "healing") > 0)
	end)

	T.test("factory: missing Essence pauses brewing but not farming", function()
		local engine, profile = fresh()
		assign(engine, profile, "garden", "farmer")
		assign(engine, profile, "cauldron", "brewer")
		profile.stations.cauldron.input.mandrake = 2
		profile.discoveredRecipes.healing = true
		act(engine, profile, "setAuto", { stationId = "cauldron", enabled = true })
		advance(engine, profile, START + 30)
		T.equal(profile.stations.cauldron.job, nil)
		T.equal(profile.gold, 0)
		T.truthy(count(profile.stations.garden.output, "mandrake") > 0)
	end)

	T.test("factory: explicit discard removes only the specified owned quantity", function()
		local engine, profile = fresh()
		profile.inventory.slime = 15
		profile.inventory.fire_extract = 3
		act(engine, profile, "discard", { itemId = "slime", amount = 10 })
		T.equal(count(profile.inventory, "slime"), 5)
		T.equal(count(profile.inventory, "fire_extract"), 3)
		T.equal(profile.gold, 0)
		act(engine, profile, "discard", { itemId = "fire_extract", amount = 3 })
		T.equal(count(profile.inventory, "fire_extract"), 0)
	end)

	T.test("factory: invalid disposal cannot mint, overdraw or remove quest items", function()
		local engine, profile = fresh()
		profile.inventory.slime = 5
		act(engine, profile, "acceptOrder", { orderId = "healing_small" })
		profile.questStock.healing = 1
		local before = clone(profile)
		for _, amount in ipairs({ 0, -1, 1.5, 6, 0 / 0, math.huge, Config.maxCount + 1 }) do
			T.falsy(engine.act(profile, "discard", { itemId = "slime", amount = amount }, START))
		end
		T.falsy(engine.act(profile, "discard", { itemId = "healing", amount = 1 }, START))
		T.falsy(engine.act(profile, "discard", { itemId = "unknown", amount = 1 }, START))
		T.same(profile, before)
	end)

	T.test("factory: disposal can recover a line blocked by excess unused ingredients", function()
		local engine, profile = fresh()
		profile.essence = 100
		profile.pipes = true
		profile.inventory.slime = Config.warehouse.rawCapacity[1]
		profile.discoveredRecipes.healing = true
		assign(engine, profile, "garden", "farmer")
		assign(engine, profile, "logistics", "slime")
		assign(engine, profile, "cauldron", "brewer")
		act(engine, profile, "setAuto", { stationId = "cauldron", enabled = true })
		advance(engine, profile, START + 30)
		T.equal(profile.gold, 0)
		T.truthy(count(profile.stations.garden.output, "mandrake") > 0)
		act(engine, profile, "discard", { itemId = "slime", amount = 10 })
		advance(engine, profile, START + 90)
		T.truthy(profile.gold > 0)
	end)

	T.test("factory: hauler reserves cargo and conserves it while destination is blocked", function()
		local engine, profile = fresh()
		profile.inventory.mandrake = 10
		assign(engine, profile, "logistics", "slime")
		advance(engine, profile, START + 1)
		T.equal(profile.stations.logistics.job.kind, "haul")
		T.equal(resourceTotal(profile, "mandrake"), 10)
		profile.stations.cauldron.input.coal = Config.machineInputCapacity
		advance(engine, profile, START + 10)
		T.truthy(profile.stations.logistics.job ~= nil)
		T.equal(resourceTotal(profile, "mandrake"), 10)
		profile.stations.cauldron.input.coal = nil
		advance(engine, profile, START + 11)
		T.equal(resourceTotal(profile, "mandrake"), 10)
		T.equal(count(profile.stations.cauldron.input, "mandrake"), 2)
	end)

	T.test("factory: unassigning a hauler pauses rather than duplicates or deletes cargo", function()
		local engine, profile = fresh()
		profile.inventory.mandrake = 10
		assign(engine, profile, "logistics", "slime")
		advance(engine, profile, START + 1)
		local job = clone(profile.stations.logistics.job)
		act(engine, profile, "assign", { stationId = "logistics", petId = "" })
		advance(engine, profile, START + 100)
		T.same(profile.stations.logistics.job, job)
		T.equal(resourceTotal(profile, "mandrake"), 10)
		assign(engine, profile, "logistics", "slime")
		advance(engine, profile, START + 110)
		T.equal(resourceTotal(profile, "mandrake"), 10)
	end)

	T.test("factory: pipes move fluids but do not silently move solid ingredients", function()
		local engine, profile = fresh()
		profile.gold = 10000
		act(engine, profile, "buy", { upgradeId = "distillery" })
		act(engine, profile, "buy", { upgradeId = "cauldron" })
		act(engine, profile, "buy", { upgradeId = "pipes" })
		act(engine, profile, "setRecipe", { stationId = "cauldron", recipeId = "rage" })
		profile.stations.distillery.output.fire_extract = 3
		profile.stations.garden.output.mandrake = 3
		profile.inventory.mandrake = 4
		profile.inventory.slime = 2
		advance(engine, profile, START + 1)
		T.equal(count(profile.stations.cauldron.input, "fire_extract"), 1)
		T.equal(count(profile.inventory, "fire_extract"), 2)
		T.equal(count(profile.stations.cauldron.input, "mandrake"), 0)
		T.equal(count(profile.stations.cauldron.input, "slime"), 0)
		T.equal(count(profile.stations.garden.output, "mandrake"), 3)
	end)

	T.test("factory: order quota reserves only its count and exports extras", function()
		local engine, profile = fresh()
		act(engine, profile, "acceptOrder", { orderId = "healing_small" })
		for _ = 1, Config.orders.healing_small.count + 2 do manualHealing(engine, profile) end
		T.equal(count(profile.stations.cauldron.questQueue, "healing"), Config.orders.healing_small.count)
		T.equal(count(profile.questStock, "healing"), 0)
		T.equal(profile.gold, Config.recipes.healing.goldValue * 2)
		T.equal(count(profile.inventory, "healing"), 0)
	end)

	T.test("factory: order claim is awarded exactly once", function()
		local engine, profile = fresh()
		act(engine, profile, "acceptOrder", { orderId = "healing_small" })
		T.falsy(engine.act(profile, "claimOrder", {}, START))
		for _ = 1, Config.orders.healing_small.count do manualHealing(engine, profile) end
		T.falsy(engine.act(profile, "claimOrder", {}, profile.lastSimulatedAt))
		assign(engine, profile, "logistics", "slime")
		advance(engine, profile, profile.lastSimulatedAt + 30)
		act(engine, profile, "claimOrder", {})
		T.equal(profile.gold, Config.orders.healing_small.rewardGold)
		T.equal(profile.order, nil)
		T.equal(size(profile.questStock), 0)
		T.falsy(engine.act(profile, "claimOrder", {}, profile.lastSimulatedAt))
		T.equal(profile.gold, Config.orders.healing_small.rewardGold)
	end)

	T.test("factory: cannot replace an active order or accept a locked recipe", function()
		local engine, profile = fresh()
		T.falsy(engine.act(profile, "acceptOrder", { orderId = "rage_small" }, START))
		act(engine, profile, "acceptOrder", { orderId = "healing_small" })
		local before = clone(profile)
		T.falsy(engine.act(profile, "acceptOrder", { orderId = "healing_large" }, START))
		T.same(profile, before)
	end)

	T.test("factory: expired order stock exports once without contract bonus", function()
		local engine, profile = fresh()
		act(engine, profile, "acceptOrder", { orderId = "healing_small" })
		manualHealing(engine, profile)
		T.equal(profile.gold, 0)
		local expiry = profile.order.expiresAt
		advance(engine, profile, expiry, true)
		T.equal(profile.order, nil)
		T.equal(size(profile.questStock), 0)
		T.equal(profile.gold, Config.recipes.healing.goldValue)
		advance(engine, profile, expiry, true)
		T.equal(profile.gold, Config.recipes.healing.goldValue)
	end)

	T.test("factory: offline simulation matches one-second online simulation exactly", function()
		local engine, online = setupAutomated()
		act(engine, online, "acceptOrder", { orderId = "healing_large" })
		local offline = clone(online)
		for offset = 1, 1200 do advance(engine, online, START + offset) end
		advance(engine, offline, START + 1200, true)
		T.same(offline, online)
	end)

	T.test("factory: irregular update partitions preserve jobs and random outcomes", function()
		local engine, regular = setupAutomated()
		advance(engine, regular, START + 19)
		local irregular = clone(regular)
		for offset = 20, 600 do advance(engine, regular, START + offset) end
		for _, offset in ipairs({ 21, 38, 59, 61, 100, 175, 233, 401, 599, 600 }) do
			advance(engine, irregular, START + offset)
		end
		T.same(irregular, regular)
	end)

	T.test("factory: repeated catch-up cannot mint money, items or reroll slime", function()
		local engine, profile = setupAutomated()
		advance(engine, profile, START + 600, true)
		local before = clone(profile)
		local result = advance(engine, profile, START + 600, true)
		T.equal(result.processedSeconds, 0)
		T.equal(result.goldEarned, 0)
		T.equal(result.essenceEarned, 0)
		T.equal(size(result.produced), 0)
		T.same(profile, before)
	end)

	T.test("factory: offline cap discards the excess interval rather than banking it", function()
		local engine, exact = setupAutomated()
		local long = clone(exact)
		advance(engine, exact, START + Config.maxOfflineSeconds, true)
		local target = START + Config.maxOfflineSeconds * 3
		local result = advance(engine, long, target, true)
		T.equal(result.processedSeconds, Config.maxOfflineSeconds)
		T.equal(result.skippedSeconds, Config.maxOfflineSeconds * 2)
		T.equal(long.lastSimulatedAt, target)
		exact.lastSimulatedAt = target
		T.same(long, exact)
		local before = clone(long)
		advance(engine, long, target, true)
		T.same(long, before)
	end)

	T.test("factory: backwards and invalid clocks are rejected without state changes", function()
		local engine, profile = fresh()
		local before = clone(profile)
		T.falsy(engine.advance(profile, START - 1, true).ok)
		T.falsy(engine.advance(profile, 0 / 0, true).ok)
		T.falsy(engine.advance(profile, math.huge, true).ok)
		T.falsy(engine.advance(profile, START + 1, "yes").ok)
		T.same(profile, before)
	end)

	T.test("factory: deployed slime byproduct has deterministic saved randomness", function()
		local config = clone(Config)
		config.slimeChance = 1
		local engine = Factory.new(config)
		local profile = engine.newProfile(123, START)
		engine.grantHistoricalStarters(profile)
		assign(engine, profile, "logistics", "slime")
		advance(engine, profile, START + config.slimePeriod - 1)
		T.equal(count(profile.inventory, "slime"), 0)
		advance(engine, profile, START + config.slimePeriod)
		T.equal(count(profile.inventory, "slime"), 1)
		local after = clone(profile)
		advance(engine, profile, START + config.slimePeriod)
		T.same(profile, after)
	end)

	T.test("factory: unassigned slime has no passive production", function()
		local config = clone(Config)
		config.slimeChance = 1
		local engine = Factory.new(config)
		local profile = engine.newProfile(123, START)
		advance(engine, profile, START + config.slimePeriod * 3)
		T.equal(count(profile.inventory, "slime"), 0)
		T.equal(profile.rngState, engine.newProfile(123, START).rngState)
	end)

	T.test("factory: starter grant is not repeated on catch-up or profile reload", function()
		local engine, profile = fresh()
		local starters = clone(profile.pets)
		advance(engine, profile, START + 7200, true)
		local reloaded = clone(profile)
		advance(engine, reloaded, START + 7201, true)
		T.same(reloaded.pets, starters)
		T.equal(size(reloaded.pets), 3)
		T.truthy(reloaded.tutorialGranted)
	end)

	T.test("factory: two-stage recipe consumes a real produced intermediate", function()
		local engine, profile = fresh()
		profile.gold, profile.essence = 1000, 100
		act(engine, profile, "buy", { upgradeId = "distillery" })
		act(engine, profile, "buy", { upgradeId = "cauldron" })
		profile.inventory.coal = 2
		act(engine, profile, "load", { stationId = "distillery" })
		act(engine, profile, "brew", { stationId = "distillery" })
		advance(engine, profile, START + Config.recipes.fire_extract.duration)
		T.equal(count(profile.stations.distillery.output, "fire_extract"), 1)
		act(engine, profile, "collect", { stationId = "distillery" })
		profile.inventory.mandrake, profile.inventory.slime = 2, 1
		act(engine, profile, "setRecipe", { stationId = "cauldron", recipeId = "rage" })
		act(engine, profile, "load", { stationId = "cauldron" })
		local gold = profile.gold
		act(engine, profile, "brew", { stationId = "cauldron" })
		advance(engine, profile, profile.lastSimulatedAt + Config.recipes.rage.duration)
		T.equal(profile.gold, gold + Config.recipes.rage.goldValue)
		T.equal(resourceTotal(profile, "fire_extract"), 0)
		T.truthy(profile.discoveredRecipes.fire_extract)
		T.truthy(profile.discoveredRecipes.rage)
	end)

	T.test("factory: real fixed hires enable the complete automated two-stage chain", function()
		local engine, profile = fresh()
		-- Test funding only; every worker, assignment, building and batch uses a real command.
		profile.gold = 10000
		for _, upgradeId in ipairs({ "crystal", "mine", "distillery", "cauldron", "warehouse", "warehouse", "warehouse", "pipes" }) do
			act(engine, profile, "buy", { upgradeId = upgradeId })
		end
		assign(engine, profile, "garden", "farmer")
		assign(engine, profile, "logistics", "slime")
		assign(engine, profile, "cauldron", "brewer")
		local function hireAt(speciesId: string, stationId: string)
			local before = clone(profile.pets)
			act(engine, profile, "hire", { speciesId = speciesId })
			for id in pairs(profile.pets) do
				if not before[id] then
					act(engine, profile, "assign", { stationId = stationId, petId = id })
					return
				end
			end
			error("Hire did not add a familiar")
		end
		hireAt("farmer", "mine")
		hireAt("brewer", "distillery")
		T.equal(size(profile.pets), 5)
		act(engine, profile, "setRecipe", { stationId = "cauldron", recipeId = "rage" })
		advance(engine, profile, profile.lastSimulatedAt + 90)
		act(engine, profile, "brew", { stationId = "distillery" })
		advance(engine, profile, profile.lastSimulatedAt + Config.recipes.fire_extract.duration + 1)
		act(engine, profile, "setAuto", { stationId = "distillery", enabled = true })
		local function rageInputsReady(): boolean
			for itemId, required in pairs(Config.recipes.rage.inputs) do
				if count(profile.stations.cauldron.input, itemId) < required then return false end
			end
			return true
		end
		for _ = 1, 60 do
			if rageInputsReady() then break end
			advance(engine, profile, profile.lastSimulatedAt + 30)
		end
		T.truthy(rageInputsReady(), "Farm/mining/slime/hauling/pipes must supply the first rage batch")
		act(engine, profile, "brew", { stationId = "cauldron" })
		advance(engine, profile, profile.lastSimulatedAt + Config.recipes.rage.duration + 1)
		T.truthy(profile.discoveredRecipes.rage)
		act(engine, profile, "setAuto", { stationId = "cauldron", enabled = true })
		local result = advance(engine, profile, profile.lastSimulatedAt + 3600, true)
		T.truthy(count(result.produced, "fire_extract") > 0)
		T.truthy(count(result.sold, "rage") > 0)
		T.truthy(result.goldEarned > 0)
	end)

	T.test("factory: real profile survives lease-backed save and offline reload", function()
		local engine, fixture = setupAutomated()
		local persisted: any = nil
		local now = START
		local fakeDataStore = {}
		function fakeDataStore:UpdateAsync(_key: string, transform: any): any
			local updated = transform(clone(persisted))
			if updated == nil then return nil end
			persisted = clone(updated)
			return clone(persisted)
		end
		local function store(owner: string): any
			return ProfileStore.new({
				dataStore = fakeDataStore,
				now = function() return now end,
				owner = owner,
				validate = engine.validate,
				sleep = function() end,
			})
		end
		local first = store("session-A")
		local profile, reason = first:load(123, function() return clone(fixture) end)
		T.truthy(profile, reason)
		advance(engine, profile, START + 20)
		now = START + 20
		T.truthy(first:save(123))
		T.truthy(first:release(123))
		now = START + 620
		local second = store("session-B")
		-- The adapter may eagerly prepare a fallback before UpdateAsync; an existing
		-- record must win over that unused fresh candidate.
		local reloaded, failure = second:load(123, function() return engine.newProfile(123, now) end)
		T.truthy(reloaded, failure)
		T.same(reloaded, profile)
		local offline = advance(engine, reloaded, now, true)
		T.equal(offline.processedSeconds, 600)
		T.truthy(second:save(123))
		T.same(persisted.profile, reloaded)
		local before = clone(reloaded)
		advance(engine, reloaded, now, true)
		T.same(reloaded, before)
	end)

	local malformed: { { any } } = {
		{ "future schema", function(p: any) p.schemaVersion = Config.schemaVersion + 1 end },
		{ "NaN gold", function(p: any) p.gold = 0 / 0 end },
		{ "infinite Essence", function(p: any) p.essence = math.huge end },
		{ "negative item count", function(p: any) p.inventory.mandrake = -1 end },
		{ "fractional item count", function(p: any) p.inventory.mandrake = 1.5 end },
		{ "unknown inventory item", function(p: any) p.inventory.cheat = 1 end },
		{ "warehouse overflow", function(p: any) p.inventory.mandrake = Config.warehouse.rawCapacity[1] + 1 end },
		{ "invalid familiar stat", function(p: any) p.pets[petId(p, "farmer")].stats.Farming = 0 / 0 end },
		{ "duplicate assignment", function(p: any)
			p.stations.garden.workerId = petId(p, "farmer")
			p.stations.crystal.workerId = petId(p, "farmer")
		end },
		{ "worker in unbuilt station", function(p: any) p.stations.mine.workerId = petId(p, "farmer") end },
		{ "missing station", function(p: any) p.stations.garden = nil end },
		{ "unknown station", function(p: any) p.stations.hacked = clone(p.stations.garden) end },
		{ "invalid station level", function(p: any) p.stations.garden.level = 100 end },
		{ "potion in raw inventory", function(p: any) p.inventory.healing = 1 end },
		{ "orphan quest stock", function(p: any) p.questStock.healing = 1 end },
		{ "unknown recipe collection", function(p: any) p.discoveredRecipes.hacked = true end },
		{ "invalid RNG", function(p: any) p.rngState = 0 end },
		{ "infinite last timestamp", function(p: any) p.lastSimulatedAt = math.huge end },
	}
	for _, entry in ipairs(malformed) do
		T.test("factory: validator rejects " .. entry[1], function()
			local engine, profile = fresh()
			entry[2](profile)
			local ok, valid = pcall(engine.validate, profile)
			T.truthy(ok, "Validator threw on malformed saved data")
			T.falsy(valid)
			T.falsy(engine.advance(profile, START + 10, true).ok)
		end)
	end
end
