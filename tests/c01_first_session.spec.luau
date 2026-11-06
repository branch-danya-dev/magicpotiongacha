--!nonstrict
-- C01 first session. Prices below are test parameters on a copied config.
-- Live Config.firstSession.ownerApproved stays false.
local Config = require("../src/shared/Config")
local Factory = require("../src/shared/Factory")
local Protocol = require("../src/shared/Protocol")
local ProfileStore = require("../src/server/ProfileStore")
local v2 = require("./fixtures/m1-profile")

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

local function approved()
	local config = copy(Config)
	config.firstSession.ownerApproved = true
	return config
end

local function equip(profile)
	profile.stations.garden.level = 1
	profile.stations.cauldron.level = 1
	profile.stations.cauldron.recipeId = "healing"
end

return function(T)
	local BED = Config.firstSession.bedId

	T.test("C01: live prices stay unapproved and are not charged", function()
		T.equal(Config.schemaVersion, 8)
		T.equal(Config.firstSession.ownerApproved, false)
		local engine = Factory.new(Config)
		local profile = engine.newProfile(14, 1000)
		profile.gold = 1000
		local before = copy(profile)
		T.falsy(engine.claimStarterBudget(profile))
		T.falsy(engine.act(profile, "buySeed", { amount = 1 }, 1000))
		T.falsy(engine.act(profile, "buyStarterStation", { stationId = "garden" }, 1000))
		T.falsy(engine.act(profile, "exchangeEssence", { gold = 1 }, 1000))
		T.falsy(engine.act(profile, "buyAutomation", { feature = "brew" }, 1000))
		T.same(profile, before)
	end)

	T.test("C01: a new profile has no familiars until one starter is chosen", function()
		local engine = Factory.new(Config)
		local profile = engine.newProfile(21, 2000)
		T.equal(count(profile.pets), 0)
		T.equal(profile.starter.claimed, false)
		T.equal(profile.starter.legacyGrant, false)
		T.equal(profile.nextPetSerial, 1)
		T.equal(profile.stations.crystal.level, 1)
		T.equal(profile.stations.garden.level, 0)
		T.equal(profile.stations.cauldron.level, 0)
		T.equal(profile.stations.cauldron.recipeId, nil)
		T.truthy(profile.temple)
		T.equal(profile.layout.placements.garden.x, Config.stations.garden.offset[1])
		T.equal(profile.layout.placements.cauldron.z, Config.stations.cauldron.offset[3])
		T.equal(profile.gold, 0)
	end)

	for _, species in ipairs({ "farmer", "slime", "brewer" }) do
		T.test("C01: starter choice " .. species .. " is created once", function()
			local engine = Factory.new(Config)
			local profile = engine.newProfile(30, 3000)
			local definition
			for _, pet in ipairs(Config.starterPets) do
				if pet.species == species then definition = pet end
			end
			T.truthy(engine.act(profile, "chooseStarter", { speciesId = species }, 3000))
			local petId = "30:" .. definition.id
			local pet = profile.pets[petId]
			T.truthy(pet)
			T.equal(pet.species, species)
			T.same(pet.stats, definition.stats)
			T.equal(pet.provenance.source, "starter")
			T.falsy(pet.paidOrigin)
			T.equal(profile.starter.choice, species)
			T.equal(profile.starter.claimed, true)
			T.equal(profile.nextPetSerial, 1)
			T.equal(count(profile.pets), 1)
			local pets = copy(profile.pets)
			T.truthy(engine.act(profile, "chooseStarter", { speciesId = species }, 3000))
			T.same(profile.pets, pets)
			local other = species == "farmer" and "slime" or "farmer"
			T.falsy(engine.act(profile, "chooseStarter", { speciesId = other }, 3000))
			T.same(profile.pets, pets)
			T.truthy(engine.validate(profile))
		end)
	end

	T.test("C01: a historical profile keeps three familiars and cannot choose again", function()
		local engine = Factory.new(Config)
		local source = copy(v2)
		local migrated = engine.migrate(copy(source))
		T.truthy(migrated)
		T.equal(count(migrated.pets), count(source.pets))
		T.truthy(migrated.pets["123:starter_farmer"])
		T.truthy(migrated.pets["123:starter_slime"])
		T.truthy(migrated.pets["123:starter_brewer"])
		T.equal(migrated.starter.legacyGrant, true)
		T.equal(migrated.starter.choice, nil)
		local pets = copy(migrated.pets)
		local gold = migrated.gold
		T.falsy(engine.act(migrated, "chooseStarter", { speciesId = "farmer" }, migrated.lastSimulatedAt))
		T.falsy(engine.claimStarterBudget(migrated))
		T.same(migrated.pets, pets)
		T.equal(migrated.gold, gold)
		T.equal(migrated.stations.garden.level, source.stations.garden.level)
		T.equal(migrated.stations.cauldron.level, source.stations.cauldron.level)
		local legacy = engine.newProfile(123, migrated.lastSimulatedAt)
		engine.grantHistoricalStarters(legacy)
		T.truthy(engine.act(legacy, "harvest", { stationId = "garden" }, legacy.lastSimulatedAt))
		T.equal(legacy.inventory.mandrake, 1)
	end)

	T.test("C01: planting consumes one seed and a second plant does not", function()
		local engine = Factory.new(approved())
		local profile = engine.newProfile(40, 4000)
		equip(profile)
		profile.seeds.mandrake = 1
		T.truthy(engine.act(profile, "plantSeed", { bedId = BED }, 4000))
		T.equal(profile.seeds.mandrake, nil)
		T.equal(profile.plants[BED].seedId, "mandrake")
		T.equal(profile.plants[BED].progress, 0)
		local planted = copy(profile.plants)
		T.falsy(engine.act(profile, "plantSeed", { bedId = BED }, 4000))
		T.same(profile.plants, planted)
		T.equal(profile.seeds.mandrake, nil)
	end)

	T.test("C01: growth and harvest continue after save and rejoin", function()
		local engine = Factory.new(approved())
		local persisted = nil
		local now = 5000
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
		local first = store("c01-a")
		local profile = first:load(41, function()
			local created = engine.newProfile(41, now)
			equip(created)
			created.seeds.mandrake = 1
			return created
		end)
		T.truthy(engine.act(profile, "plantSeed", { bedId = BED }, now))
		now = 5003
		T.truthy(engine.advance(profile, now, false).ok)
		T.equal(profile.plants[BED].progress, 3)
		T.truthy(first:save(41))
		T.truthy(first:release(41))
		local second = store("c01-b")
		local rejoined = second:load(41, function() return engine.newProfile(41, now) end)
		T.equal(rejoined.plants[BED].progress, 3)
		T.equal(rejoined.seeds.mandrake, nil)
		T.truthy(engine.advance(rejoined, now + 5, true).ok)
		T.truthy(engine.act(rejoined, "harvestCrop", { bedId = BED }, now + 5))
		T.equal(rejoined.inventory.mandrake, 1)
		T.equal(rejoined.plants[BED], nil)
		T.falsy(engine.act(rejoined, "harvestCrop", { bedId = BED }, now + 5))
		T.equal(rejoined.inventory.mandrake, 1)
		T.truthy(second:save(41))
	end)

	T.test("C01: no gold, no seeds, and no worker is safe", function()
		local config = approved()
		local engine = Factory.new(config)
		local profile = engine.newProfile(42, 6000)
		equip(profile)
		T.equal(count(profile.pets), 0)
		T.falsy(engine.act(profile, "buySeed", { amount = 1 }, 6000))
		T.falsy(engine.act(profile, "plantSeed", { bedId = BED }, 6000))
		T.falsy(engine.act(profile, "setAuto", { stationId = "cauldron", enabled = true }, 6000))
		T.equal(profile.gold, 0)
		T.equal(profile.seeds.mandrake, nil)
		profile.inventory.mandrake = 2
		profile.essence = 3
		T.truthy(engine.act(profile, "load", { stationId = "cauldron" }, 6000))
		T.truthy(engine.act(profile, "brew", { stationId = "cauldron" }, 6000))
		T.truthy(profile.stations.cauldron.job)
		T.equal(profile.stations.cauldron.workerId, nil)
	end)

	T.test("C01: unstaffed Healing is produced and sold once", function()
		local config = approved()
		local engine = Factory.new(config)
		local session = config.firstSession
		local profile = engine.newProfile(43, 7000)
		T.truthy(engine.claimStarterBudget(profile))
		T.truthy(engine.act(profile, "buyStarterStation", { stationId = "garden" }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "buyStarterStation", { stationId = "cauldron" }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "buySeed", { amount = 2 }, profile.lastSimulatedAt))
		T.falsy(engine.act(profile, "harvest", { stationId = "garden" }, profile.lastSimulatedAt))
		T.equal(profile.inventory.mandrake, nil)
		T.truthy(engine.act(profile, "plantSeed", { bedId = BED }, profile.lastSimulatedAt))
		T.truthy(engine.advance(profile, profile.lastSimulatedAt + session.growSeconds, false).ok)
		T.truthy(engine.act(profile, "harvestCrop", { bedId = BED }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "plantSeed", { bedId = BED }, profile.lastSimulatedAt))
		T.truthy(engine.advance(profile, profile.lastSimulatedAt + session.growSeconds, false).ok)
		T.truthy(engine.act(profile, "harvestCrop", { bedId = BED }, profile.lastSimulatedAt))
		for _ = 1, 3 do
			T.truthy(engine.act(profile, "click", {}, profile.lastSimulatedAt))
		end
		T.equal(profile.essence, 3)
		T.truthy(engine.act(profile, "load", { stationId = "cauldron" }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "brew", { stationId = "cauldron" }, profile.lastSimulatedAt))
		local report = engine.advance(profile, profile.lastSimulatedAt + Config.recipes.healing.duration, false)
		T.equal(report.sold.healing, 1)
		T.equal(profile.gold, session.starterGold - session.bedCost - session.cauldronCost - session.seedCost * 2 + Config.recipes.healing.goldValue)
		T.truthy(profile.discoveredRecipes.healing)
		local again = engine.advance(profile, profile.lastSimulatedAt + Config.recipes.healing.duration, false)
		T.equal(again.sold.healing, nil)
		local soldGold = profile.gold
		T.falsy(engine.act(profile, "brew", { stationId = "cauldron" }, profile.lastSimulatedAt))
		T.equal(profile.gold, soldGold)
	end)

	T.test("C01: approved test parameters grant starter Gold once and automate without minting", function()
		local config = approved()
		local engine = Factory.new(config)
		local session = config.firstSession
		local profile = engine.newProfile(44, 8000)
		equip(profile)
		T.truthy(engine.claimStarterBudget(profile))
		T.equal(profile.gold, session.starterGold)
		T.truthy(engine.claimStarterBudget(profile))
		T.equal(profile.gold, session.starterGold)
		T.truthy(engine.act(profile, "buySeed", { amount = 2 }, profile.lastSimulatedAt))
		T.equal(profile.gold, session.starterGold - session.seedCost * 2)
		T.equal(profile.seeds.mandrake, 2)
		profile.gold = session.automationCost * 2
		T.truthy(engine.act(profile, "buyAutomation", { feature = "harvest" }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "buyAutomation", { feature = "replant" }, profile.lastSimulatedAt))
		local spent = profile.gold
		T.falsy(engine.act(profile, "buyAutomation", { feature = "harvest" }, profile.lastSimulatedAt))
		T.equal(profile.gold, spent)
		local report = engine.advance(profile, profile.lastSimulatedAt + 7200, true)
		T.equal(report.processedSeconds, 7200)
		T.equal(profile.inventory.mandrake, 2)
		T.equal(profile.seeds.mandrake, nil)
		T.equal(profile.essence, 0)
		T.equal(profile.gold, spent)
		local frozen = copy(profile)
		local idle = engine.advance(profile, profile.lastSimulatedAt + 100, false)
		T.equal(idle.goldEarned, 0)
		T.equal(profile.inventory.mandrake, frozen.inventory.mandrake)
		T.equal(profile.seeds.mandrake, frozen.seeds.mandrake)
		T.equal(profile.gold, spent)
	end)

	T.test("C01: online and offline growth match, and 7200 seconds is reproducible", function()
		local function grow(offline)
			local engine = Factory.new(approved())
			local profile = engine.newProfile(45, 9000)
			equip(profile)
			profile.seeds.mandrake = 1
			assert(engine.act(profile, "plantSeed", { bedId = BED }, 9000))
			local report = engine.advance(profile, 9008, offline)
			return profile.plants[BED].progress, profile.inventory.mandrake, report.processedSeconds, profile.rngState
		end
		local online = { grow(false) }
		local offline = { grow(true) }
		T.same(online, offline)
		T.equal(online[1], Config.firstSession.growSeconds)
		local function longRun()
			local engine = Factory.new(approved())
			local profile = engine.newProfile(46, 10000)
			equip(profile)
			profile.seeds.mandrake = 3
			profile.automation.harvest = true
			profile.automation.replant = true
			local report = engine.advance(profile, 10000 + 10000, true)
			engine.advance(profile, profile.lastSimulatedAt + 1800, true)
			return {
				processed = report.processedSeconds, skipped = report.skippedSeconds,
				item = profile.inventory.mandrake, seeds = profile.seeds.mandrake,
				gold = profile.gold, essence = profile.essence, rng = profile.rngState,
				plant = profile.plants[BED],
			}
		end
		local first, second = longRun(), longRun()
		T.same(first, second)
		T.equal(first.processed, 7200)
		T.equal(first.skipped, 2800)
		T.equal(first.item, 3)
		T.equal(first.seeds, nil)
		T.equal(first.gold, 0)
		T.equal(first.essence, 0)
	end)

	T.test("C01: repeated and malformed requests do not duplicate pets, seeds, or harvests", function()
		local config = approved()
		local engine = Factory.new(config)
		local profile = engine.newProfile(47, 11000)
		equip(profile)
		profile.gold = config.firstSession.automationCost
		profile.seeds.mandrake = 1
		local before = copy(profile)
		T.falsy(Protocol.validate("plantSeed", { bedId = BED, extra = true }))
		T.falsy(engine.act(profile, "plantSeed", { bedId = BED, extra = true }, 11000))
		T.falsy(engine.act(profile, "plantSeed", { bedId = "other-bed" }, 11000))
		T.falsy(engine.act(profile, "buySeed", { amount = 0 }, 11000))
		T.falsy(engine.act(profile, "chooseStarter", { speciesId = "dragon" }, 11000))
		T.falsy(engine.act(profile, "buyAutomation", { feature = "everything" }, 11000))
		T.falsy(engine.act(profile, "harvestCrop", { bedId = BED }, 11000))
		T.same(profile, before)
		T.truthy(engine.act(profile, "chooseStarter", { speciesId = "brewer" }, 11000))
		T.truthy(engine.act(profile, "chooseStarter", { speciesId = "brewer" }, 11000))
		T.equal(count(profile.pets), 1)
		T.truthy(engine.act(profile, "plantSeed", { bedId = BED }, 11000))
		T.falsy(engine.act(profile, "harvestCrop", { bedId = BED }, 11000))
		T.equal(profile.inventory.mandrake, nil)
		T.truthy(engine.advance(profile, 11000 + config.firstSession.growSeconds, false).ok)
		T.truthy(engine.act(profile, "harvestCrop", { bedId = BED }, profile.lastSimulatedAt))
		T.falsy(engine.act(profile, "harvestCrop", { bedId = BED }, profile.lastSimulatedAt))
		T.equal(profile.inventory.mandrake, config.firstSession.seedYield)
		T.truthy(engine.act(profile, "buyAutomation", { feature = "brew" }, profile.lastSimulatedAt))
		T.equal(profile.gold, 0)
		T.falsy(engine.act(profile, "buyAutomation", { feature = "brew" }, profile.lastSimulatedAt))
		T.equal(profile.gold, 0)
		profile.plants[BED] = { seedId = "mandrake", plantedAt = 1, duration = 8, progress = 0, watered = true }
		T.falsy(engine.validate(profile))
	end)

	T.test("C01: brewing automation repeats Healing without a specialist and without a worker", function()
		local config = approved()
		local engine = Factory.new(config)
		local profile = engine.newProfile(48, 12000)
		equip(profile)
		T.truthy(engine.act(profile, "chooseStarter", { speciesId = "farmer" }, 12000))
		T.equal(profile.stations.cauldron.workerId, nil)
		profile.inventory.mandrake = 2
		profile.essence = 3
		T.truthy(engine.act(profile, "load", { stationId = "cauldron" }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "brew", { stationId = "cauldron" }, profile.lastSimulatedAt))
		T.truthy(engine.advance(profile, profile.lastSimulatedAt + Config.recipes.healing.duration, false).ok)
		T.equal(profile.gold, Config.recipes.healing.goldValue)
		profile.gold += config.firstSession.automationCost * 2
		T.truthy(engine.act(profile, "buyAutomation", { feature = "brew" }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "buyAutomation", { feature = "supply" }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "setAuto", { stationId = "cauldron", enabled = true }, profile.lastSimulatedAt))
		profile.inventory.mandrake = 2
		profile.essence = 3
		local gold = profile.gold
		local report = engine.advance(profile, profile.lastSimulatedAt + Config.recipes.healing.duration + 2, false)
		T.equal(report.sold.healing, 1)
		T.equal(profile.gold, gold + Config.recipes.healing.goldValue)
		local idle = engine.advance(profile, profile.lastSimulatedAt + 30, false)
		T.equal(idle.goldEarned, 0)
		T.equal(profile.gold, gold + Config.recipes.healing.goldValue)
	end)

	T.test("C01: starter stations are bought once at the fixed placement", function()
		local config = approved()
		local engine = Factory.new(config)
		local session = config.firstSession
		local profile = engine.newProfile(50, 13000)
		T.truthy(engine.claimStarterBudget(profile))
		T.falsy(engine.act(profile, "buy", { upgradeId = "garden", expectedLevel = 0 }, profile.lastSimulatedAt))
		T.falsy(engine.act(profile, "buy", { upgradeId = "cauldron", expectedLevel = 0 }, profile.lastSimulatedAt))
		T.equal(profile.stations.garden.level, 0)
		T.equal(profile.gold, session.starterGold)
		T.truthy(engine.act(profile, "buyStarterStation", { stationId = "garden" }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "buyStarterStation", { stationId = "garden" }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "buyStarterStation", { stationId = "cauldron" }, profile.lastSimulatedAt))
		T.equal(profile.stations.garden.level, 1)
		T.equal(profile.stations.cauldron.level, 1)
		T.equal(profile.stations.cauldron.recipeId, "healing")
		T.equal(profile.layout.placements.garden.x, config.stations.garden.offset[1])
		T.equal(profile.layout.placements.cauldron.z, config.stations.cauldron.offset[3])
		T.equal(profile.gold, session.starterGold - session.bedCost - session.cauldronCost)
	end)

	T.test("C01: a built garden does not mint Mandrake, and Essence buys a little Gold once", function()
		local config = approved()
		local engine = Factory.new(config)
		local session = config.firstSession
		local profile = engine.newProfile(51, 14000)
		T.truthy(engine.claimStarterBudget(profile))
		T.truthy(engine.act(profile, "chooseStarter", { speciesId = "farmer" }, 14000))
		T.truthy(engine.act(profile, "buyStarterStation", { stationId = "garden" }, profile.lastSimulatedAt))
		profile.gold = 0
		T.falsy(engine.act(profile, "harvest", { stationId = "garden" }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "assign", { stationId = "garden", petId = "51:starter_farmer" }, profile.lastSimulatedAt))
		T.truthy(engine.advance(profile, profile.lastSimulatedAt + 30, false).ok)
		T.equal(profile.inventory.mandrake, nil)
		T.equal(profile.stations.garden.output.mandrake, nil)
		profile.essence = session.essencePerGold - 1
		T.falsy(engine.act(profile, "exchangeEssence", { gold = 1 }, profile.lastSimulatedAt))
		T.equal(profile.gold, 0)
		T.equal(profile.essence, session.essencePerGold - 1)
		profile.essence = session.essencePerGold
		T.truthy(engine.act(profile, "exchangeEssence", { gold = 1 }, profile.lastSimulatedAt))
		T.falsy(engine.act(profile, "exchangeEssence", { gold = 1 }, profile.lastSimulatedAt))
		T.equal(profile.gold, 1)
		T.equal(profile.essence, 0)
		T.truthy(session.essencePerGold > Config.recipes.healing.essenceCost)
	end)

	T.test("C01: full storage keeps the crop, and a previous C01 save keeps its stations", function()
		local engine = Factory.new(approved())
		local profile = engine.newProfile(52, 15000)
		equip(profile)
		profile.seeds.mandrake = 1
		T.truthy(engine.act(profile, "plantSeed", { bedId = BED }, 15000))
		T.truthy(engine.advance(profile, 15000 + Config.firstSession.growSeconds, false).ok)
		profile.inventory.mandrake = 50
		T.falsy(engine.act(profile, "harvestCrop", { bedId = BED }, profile.lastSimulatedAt))
		T.equal(profile.plants[BED].progress, Config.firstSession.growSeconds)
		T.equal(profile.inventory.mandrake, 50)
		profile.inventory.mandrake = 49
		T.truthy(engine.act(profile, "harvestCrop", { bedId = BED }, profile.lastSimulatedAt))
		T.equal(profile.inventory.mandrake, 50)
		T.equal(profile.plants[BED], nil)
		local saved = engine.newProfile(53, 16000)
		saved.stations.garden.level = 1
		saved.stations.cauldron.level = 1
		saved.stations.cauldron.recipeId = "healing"
		saved.automation.restock = nil
		saved.gold, saved.essence, saved.inventory.mandrake = 12, 4, 3
		T.truthy(engine.validate(saved))
		T.equal(engine.migrate(saved), saved)
		T.equal(saved.stations.garden.level, 1)
		T.equal(saved.stations.cauldron.level, 1)
		T.equal(saved.gold, 12)
		T.equal(saved.inventory.mandrake, 3)
	end)

	T.test("C01: restock, supply and brewing sustain Healing without creating ingredients", function()
		local config = approved()
		local engine = Factory.new(config)
		local session = config.firstSession
		local profile = engine.newProfile(60, 20000)
		T.truthy(engine.claimStarterBudget(profile))
		T.truthy(engine.act(profile, "buyStarterStation", { stationId = "garden" }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "buyStarterStation", { stationId = "cauldron" }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "buySeed", { amount = 2 }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "plantSeed", { bedId = BED }, profile.lastSimulatedAt))
		T.truthy(engine.advance(profile, profile.lastSimulatedAt + session.growSeconds, false).ok)
		T.truthy(engine.act(profile, "harvestCrop", { bedId = BED }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "plantSeed", { bedId = BED }, profile.lastSimulatedAt))
		T.truthy(engine.advance(profile, profile.lastSimulatedAt + session.growSeconds, false).ok)
		T.truthy(engine.act(profile, "harvestCrop", { bedId = BED }, profile.lastSimulatedAt))
		for _ = 1, 3 do T.truthy(engine.act(profile, "click", {}, profile.lastSimulatedAt)) end
		T.truthy(engine.act(profile, "load", { stationId = "cauldron" }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "brew", { stationId = "cauldron" }, profile.lastSimulatedAt))
		T.truthy(engine.advance(profile, profile.lastSimulatedAt + Config.recipes.healing.duration, false).ok)
		local saleGold = profile.gold
		profile.gold = saleGold + session.automationCost * 5 + Config.stations.crystal.upgradeCosts[2]
		for _, feature in ipairs({ "replant", "harvest", "supply", "brew", "restock" }) do
			T.truthy(engine.act(profile, "buyAutomation", { feature = feature }, profile.lastSimulatedAt))
		end
		T.truthy(engine.act(profile, "setAuto", { stationId = "cauldron", enabled = true }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "buy", { upgradeId = "crystal", expectedLevel = 1 }, profile.lastSimulatedAt))
		T.equal(profile.stations.crystal.level, 2)
		T.equal(profile.seeds.mandrake, nil)
		local startGold = profile.gold
		local report = engine.advance(profile, profile.lastSimulatedAt + 7200, true)
		local potions = report.sold.healing or 0
		local seedsLeft = profile.seeds.mandrake or 0
		local planted = profile.plants[BED] and 1 or 0
		local held = (profile.inventory.mandrake or 0) + (profile.stations.cauldron.input.mandrake or 0)
		local brewing = profile.stations.cauldron.job and 2 or 0
		local bought = seedsLeft + planted + held + brewing + 2 * potions
		T.truthy(potions > 1)
		T.equal(profile.gold, startGold - session.seedCost * bought + Config.recipes.healing.goldValue * potions)
		T.truthy(profile.gold > startGold)
		T.equal(report.processedSeconds, 7200)
		T.equal(profile.essence <= 7200, true)
		local second = engine.advance(profile, profile.lastSimulatedAt + 30, true)
		T.equal(second.processedSeconds, 30)
	end)
end
