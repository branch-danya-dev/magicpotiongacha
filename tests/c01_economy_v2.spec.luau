--!nonstrict
-- Economy V2 v0.1. The live config is the prototype balance. Historical profiles keep the old Healing price.
local Config = require("../src/shared/Config")
local Factory = require("../src/shared/Factory")

local BED = Config.firstSession.bedId

local function note(profile, before, earned, spent)
	if profile.gold > before then earned.n += profile.gold - before
	elseif profile.gold < before then spent.n += before - profile.gold end
end

local function play(limit)
	local engine = Factory.new(Config)
	local profile = engine.newProfile(77, 100000)
	assert(engine.claimStarterBudget(profile))
	local earned, spent = { n = 0 }, { n = 0 }
	local function act(action, payload)
		local before = profile.gold
		local ok, reason = engine.act(profile, action, payload or {}, profile.lastSimulatedAt)
		note(profile, before, earned, spent)
		return ok, reason
	end
	act("chooseStarter", { speciesId = "farmer" })
	act("buyStarterStation", { stationId = "garden" })
	act("assign", { stationId = "garden", petId = "77:starter_farmer" })
	act("buySeed", { amount = Config.firstSession.openingSeeds })
	act("plantSeed", { bedId = BED })
	local saleAt, autoAt, crystalAt
	local snapshots = {}
	for second = 1, limit do
		if profile.stations.crystal.level < 2 and profile.stations.cauldron.level >= 1
			and profile.essence < Config.economyV2.healing.essenceCost then
			for _ = 1, 3 do
				if profile.essence >= Config.economyV2.healing.essenceCost then break end
				act("click", {})
			end
		end
		local plant = profile.plants[BED]
		if plant and plant.progress >= plant.duration then act("harvestCrop", { bedId = BED }) end
		if not profile.plants[BED] and (profile.seeds.mandrake or 0) > 0 and profile.stations.garden.level >= 1 then
			act("plantSeed", { bedId = BED })
		end
		if profile.stations.cauldron.level < 1 and (profile.inventory.mandrake or 0) >= Config.economyV2.healing.mandrake then
			act("buyStarterStation", { stationId = "cauldron" })
		end
		if profile.stations.cauldron.level >= 1 and not profile.stations.cauldron.job and not profile.automation.brew then
			act("load", { stationId = "cauldron" })
			act("brew", { stationId = "cauldron" })
		end
		local before = profile.gold
		local now = profile.lastSimulatedAt + 1
		local report = engine.advance(profile, now, false)
		assert(report.ok, report.error)
		note(profile, before, earned, spent)
		if not saleAt and profile.tutorial.sale then saleAt = second end
		if profile.tutorial.sale and not profile.automation.brew and profile.gold >= Config.firstSession.automationCost then
			act("buyAutomation", { feature = "basic" })
		end
		if not autoAt and profile.automation.brew then autoAt = second end
		local function afford(station)
			local cost = Config.economyV2[station].upgradeCosts[profile.stations[station].level + 1]
			return cost and cost > 0 and profile.gold >= cost
		end
		local function buy(station)
			if afford(station) then act("buy", { upgradeId = station, expectedLevel = profile.stations[station].level }) end
		end
		if profile.tutorial.sale and profile.automation.brew then
			local crystalLevel = profile.stations.crystal.level
			local cauldronLevel = profile.stations.cauldron.level
			local nextCauldron = math.min(cauldronLevel + 1, #Config.economyV2.cauldron.batch)
			local batch = Config.economyV2.cauldron.batch[nextCauldron]
			local brew = Config.economyV2.cauldron.brewSeconds[nextCauldron]
			local demand = batch * Config.economyV2.healing.essenceCost / brew
			local supply = Config.economyV2.crystal.passiveEssence[crystalLevel] or 0
			if crystalLevel < 2 or (supply < demand and crystalLevel < nextCauldron + 1) then buy("crystal")
			elseif profile.stations.garden.level <= cauldronLevel then buy("garden")
			elseif nextCauldron > cauldronLevel then buy("cauldron")
			else buy("crystal"); buy("garden"); buy("cauldron") end
		end
		if not crystalAt and profile.stations.crystal.level >= 2 and profile.automation.brew then crystalAt = second end
		if second == 300 or second == 900 or second == 1800 or second == 3600 then
			snapshots[second] = {
				earned = earned.n, spent = spent.n, gold = profile.gold,
				garden = profile.stations.garden.level, cauldron = profile.stations.cauldron.level,
				crystal = profile.stations.crystal.level,
			}
		end
	end
	return {
		saleAt = saleAt, autoAt = autoAt, crystalAt = crystalAt, snapshots = snapshots,
		earned = earned.n, spent = spent.n, profile = profile, engine = engine,
	}
end

return function(T)
	T.test("C01 economy: the opening budget pays for one potion and basic automation", function()
		local engine = Factory.new(Config)
		local profile = engine.newProfile(70, 4000)
		local session = Config.firstSession
		T.truthy(engine.claimStarterBudget(profile))
		T.falsy(engine.act(profile, "buy", { upgradeId = "mine", expectedLevel = 0 }, profile.lastSimulatedAt))
		T.equal(profile.gold, session.starterGold)
		T.truthy(engine.act(profile, "buyStarterStation", { stationId = "garden" }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "buyStarterStation", { stationId = "cauldron" }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "buySeed", { amount = session.openingSeeds }, profile.lastSimulatedAt))
		T.equal(profile.gold, 400)
		T.truthy(engine.act(profile, "plantSeed", { bedId = BED }, profile.lastSimulatedAt))
		T.truthy(engine.advance(profile, profile.lastSimulatedAt + session.growSeconds, false).ok)
		T.truthy(engine.act(profile, "harvestCrop", { bedId = BED }, profile.lastSimulatedAt))
		for _ = 1, 3 do T.truthy(engine.act(profile, "click", {}, profile.lastSimulatedAt)) end
		T.truthy(engine.act(profile, "load", { stationId = "cauldron" }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "brew", { stationId = "cauldron" }, profile.lastSimulatedAt))
		T.truthy(engine.advance(profile, profile.lastSimulatedAt + Config.economyV2.cauldron.brewSeconds[1], false).ok)
		T.equal(profile.gold, 650)
		T.truthy(engine.act(profile, "buyAutomation", { feature = "basic" }, profile.lastSimulatedAt))
		T.equal(profile.gold, 150)
		T.truthy(engine.act(profile, "buyAutomation", { feature = "basic" }, profile.lastSimulatedAt))
		T.equal(profile.gold, 150)
		profile.gold = 0
		T.truthy(engine.claimStarterBudget(profile))
		T.equal(profile.gold, 0)
	end)

	T.test("C01 economy: historical Healing, clicks and accepted orders keep their old numbers", function()
		local engine = Factory.new(Config)
		local profile = engine.newProfile(71, 5000)
		engine.grantHistoricalStarters(profile)
		profile.inventory.mandrake = 2
		profile.essence = Config.recipes.healing.essenceCost
		T.truthy(engine.act(profile, "load", { stationId = "cauldron" }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "brew", { stationId = "cauldron" }, profile.lastSimulatedAt))
		T.truthy(engine.advance(profile, profile.lastSimulatedAt + Config.recipes.healing.duration, false).ok)
		T.equal(profile.gold, Config.recipes.healing.goldValue)
		profile.essence = 0
		T.truthy(engine.act(profile, "click", {}, profile.lastSimulatedAt))
		T.equal(profile.essence, Config.manualClickEssence)
		local saved = engine.newProfile(72, 6000)
		engine.grantHistoricalStarters(saved)
		saved.discoveredRecipes.healing = true
		saved.order = {
			id = "healing_small", recipeId = "healing", itemId = "healing", count = 5, rewardGold = 110,
			acceptedAt = 6000, expiresAt = 6600,
		}
		T.truthy(engine.validate(saved))
		saved.questStock.healing = 5
		T.truthy(engine.act(saved, "claimOrder", {}, saved.lastSimulatedAt))
		T.equal(saved.gold, 110)
		local modern = engine.newProfile(73, 7000)
		modern.stations.garden.level = 1
		modern.stations.cauldron.level = 1
		modern.stations.cauldron.recipeId = "healing"
		modern.discoveredRecipes.healing = true
		modern.tutorial.sale = true
		local oldOffer, newOffer = false, false
		for _, id in ipairs(engine.orderOffers(modern)) do
			if id == "healing_small" or id == "healing_quick" or id == "healing_large" then oldOffer = true end
			if id == "healing_small_v2" or id == "healing_quick_v2" then newOffer = true end
		end
		T.falsy(oldOffer)
		T.truthy(newOffer)
		local legacyOffers = engine.orderOffers(saved)
		local legacyNew = false
		for _, id in ipairs(legacyOffers) do if string.sub(id, -3) == "_v2" then legacyNew = true end end
		T.falsy(legacyNew)
	end)

	T.test("C01 economy: a partly bought automation bundle is kept and completed once", function()
		local engine = Factory.new(Config)
		local profile = engine.newProfile(74, 8000)
		profile.tutorial.sale = true
		profile.automation.harvest = true
		profile.automation.replant = true
		profile.gold = Config.firstSession.automationCost
		T.truthy(engine.act(profile, "buyAutomation", { feature = "basic" }, profile.lastSimulatedAt))
		T.equal(profile.automation.harvest, true)
		T.equal(profile.automation.restock, true)
		T.equal(profile.automation.brew, true)
		T.equal(profile.gold, 0)
		T.truthy(engine.act(profile, "buyAutomation", { feature = "basic" }, profile.lastSimulatedAt))
		T.equal(profile.gold, 0)
		T.truthy(engine.validate(profile))
	end)

	T.test("C01 economy: an active hour funds stronger stations without duplicating a sale", function()
		local first = play(3600)
		local second = play(3600)
		T.equal(first.saleAt, second.saleAt)
		T.equal(first.autoAt, second.autoAt)
		T.equal(first.crystalAt, second.crystalAt)
		T.equal(first.profile.gold, second.profile.gold)
		T.truthy(first.saleAt <= 90)
		T.truthy(first.autoAt <= 180)
		T.truthy(first.crystalAt <= 300)
		local five, fifteen, thirty, hour = first.snapshots[300], first.snapshots[900], first.snapshots[1800], first.snapshots[3600]
		T.truthy(five.crystal >= 2)
		T.truthy(fifteen.garden + fifteen.cauldron + fifteen.crystal > five.garden + five.cauldron + five.crystal)
		T.truthy(thirty.garden + thirty.cauldron + thirty.crystal > fifteen.garden + fifteen.cauldron + fifteen.crystal)
		T.truthy(hour.garden + hour.cauldron + hour.crystal >= thirty.garden + thirty.cauldron + thirty.crystal)
		T.truthy(hour.earned > thirty.earned)
		print(string.format("C01 economy timeline sale=%ds auto=%ds crystal2=%ds", first.saleAt, first.autoAt, first.crystalAt))
		for _, second in ipairs({ 300, 900, 1800, 3600 }) do
			local row = first.snapshots[second]
			print(string.format("C01 economy %ds earned=%d spent=%d gold=%d garden=%d cauldron=%d crystal=%d",
				second, row.earned, row.spent, row.gold, row.garden, row.cauldron, row.crystal))
		end
		local beforeGold, beforeEssence = first.profile.gold, first.profile.essence
		local passive = Config.economyV2.crystal.passiveEssence[first.profile.stations.crystal.level]
		local offline = first.engine.advance(first.profile, first.profile.lastSimulatedAt + 7200, true)
		T.equal(offline.processedSeconds, 7200)
		T.truthy((offline.sold.healing or 0) > 0)
		T.truthy(first.profile.gold > beforeGold)
		T.truthy(first.profile.essence <= beforeEssence + passive * 7200)
		T.truthy(first.engine.validate(first.profile))
	end)
end
