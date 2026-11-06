--!nonstrict
-- Economy V2 v0.1. The live config is the prototype balance. Historical profiles keep the old Healing price.
local Config = require("../src/shared/Config")
local Factory = require("../src/shared/Factory")
local ProfileStore = require("../src/server/ProfileStore")

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = copy(item) end
	return result
end

local BED = Config.firstSession.bedId

local function note(profile, before, earned, spent)
	if profile.gold > before then earned.n += profile.gold - before
	elseif profile.gold < before then spent.n += before - profile.gold end
end

local function play(limit, species)
	species = species or "farmer"
	local engine = Factory.new(Config)
	local profile = engine.newProfile(77, 100000)
	assert(engine.claimStarterBudget(profile))
	local earned, spent = { n = 0 }, { n = 0 }
	local potions = 0
	local function act(action, payload)
		local before = profile.gold
		local ok, reason = engine.act(profile, action, payload or {}, profile.lastSimulatedAt)
		note(profile, before, earned, spent)
		return ok, reason
	end
	local petId = "77:starter_" .. species
	act("chooseStarter", { speciesId = species })
	act("buyStarterStation", { stationId = "garden" })
	if species == "farmer" then act("assign", { stationId = "garden", petId = petId }) end
	if species == "slime" then act("assign", { stationId = "logistics", petId = petId }) end
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
		potions += report.sold.healing or 0
		note(profile, before, earned, spent)
		if species == "brewer" and profile.stations.cauldron.level >= 1 and not profile.stations.cauldron.workerId then
			act("assign", { stationId = "cauldron", petId = petId })
		end
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
			local stalls = profile.telemetry.stalls.cauldron or {}
			local upgrades = {}
			for _, station in ipairs({ "garden", "cauldron", "crystal" }) do
				local cost = Config.economyV2[station].upgradeCosts[profile.stations[station].level + 1]
				if cost == nil or cost <= 0 then upgrades[station] = "max"
				elseif profile.gold >= cost then upgrades[station] = "yes"
				else upgrades[station] = "no" end
			end
			snapshots[second] = {
				earned = earned.n, spent = spent.n, gold = profile.gold, potions = potions,
				garden = profile.stations.garden.level, cauldron = profile.stations.cauldron.level,
				crystal = profile.stations.crystal.level,
				essenceStall = stalls.waiting_essence or 0,
				mandrakeStall = stalls.waiting_ingredient or 0,
				queueFull = stalls.queue_full or 0,
				manual = stalls.manual_mode or 0,
				noMaster = stalls.no_master or 0,
				upgrades = upgrades,
			}
		end
	end
	return {
		saleAt = saleAt, autoAt = autoAt, crystalAt = crystalAt, snapshots = snapshots,
		earned = earned.n, spent = spent.n, potions = potions, profile = profile, engine = engine,
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

	local function opened(userId, now)
		local engine = Factory.new(Config)
		local profile = engine.newProfile(userId, now)
		T.truthy(engine.claimStarterBudget(profile))
		T.truthy(engine.act(profile, "chooseStarter", { speciesId = "slime" }, now))
		profile.stations.garden.level = 1
		profile.stations.cauldron.level = 1
		profile.stations.cauldron.recipeId = "healing"
		profile.discoveredRecipes.healing = true
		profile.tutorial.sale = true
		return engine, profile
	end

	local function fillCauldron(engine, profile, stationId, level)
		local station = profile.stations[stationId]
		station.level = level
		station.recipeId = "healing"
		local shown = engine.recipeState(profile, stationId, "healing")
		station.essence = shown.essenceCost
		station.input = { mandrake = shown.inputs.mandrake }
		return shown
	end

	T.test("C01 fix: a contract reserves only the queue that can hold the batch", function()
		local orders = { "healing_quick_v2", "healing_small_v2", "healing_large_v2" }
		for level = 1, 4 do
			for _, orderId in ipairs(orders) do
				local engine, profile = opened(80 + level, 20000)
				local shown = fillCauldron(engine, profile, "cauldron", level)
				T.truthy(engine.act(profile, "acceptOrder", { orderId = orderId }, profile.lastSimulatedAt))
				local order = Config.orders[orderId]
				T.equal(profile.order.rewardGold, order.rewardGold)
				local gold = profile.gold
				T.truthy(engine.act(profile, "brew", { stationId = "cauldron" }, profile.lastSimulatedAt))
				T.falsy(engine.act(profile, "brew", { stationId = "cauldron" }, profile.lastSimulatedAt))
				T.equal(profile.gold, gold)
				T.truthy(engine.advance(profile, profile.lastSimulatedAt + shown.duration, false).ok)
				local queued = profile.stations.cauldron.questQueue.healing or 0
				local expectedQueued = math.min(shown.quantity, order.count, Config.questQueueCapacity)
				T.equal(queued, expectedQueued)
				T.equal(profile.gold, gold + (shown.quantity - expectedQueued) * Config.economyV2.healing.goldValue)
				T.equal(profile.order.rewardGold, order.rewardGold)
				local remaining = profile.order.count - engine.orderState(profile).reserved
				if order.count >= Config.questQueueCapacity and remaining > 0 then
					profile.stations.cauldron.questQueue = { healing = Config.questQueueCapacity }
					fillCauldron(engine, profile, "cauldron", level)
					local brewed, brewReason = engine.act(profile, "brew", { stationId = "cauldron" }, profile.lastSimulatedAt)
					T.falsy(brewed, brewReason)
					T.falsy(profile.stations.cauldron.job)
					profile.stations.cauldron.questQueue = { healing = 2 }
					fillCauldron(engine, profile, "cauldron", level)
					T.truthy(engine.act(profile, "brew", { stationId = "cauldron" }, profile.lastSimulatedAt))
				elseif remaining > 0 then
					profile.stations.cauldron.questQueue = { healing = math.min(2, remaining) }
					fillCauldron(engine, profile, "cauldron", level)
					T.truthy(engine.act(profile, "brew", { stationId = "cauldron" }, profile.lastSimulatedAt))
				else
					profile.stations.cauldron.questQueue = { healing = math.min(Config.questQueueCapacity, order.count) }
					fillCauldron(engine, profile, "cauldron", level)
					T.truthy(engine.act(profile, "brew", { stationId = "cauldron" }, profile.lastSimulatedAt))
				end
				local valid, validReason = engine.validate(profile)
				T.truthy(valid, validReason)
			end
		end
	end)

	T.test("C01 fix: delivery moves a large batch and the next brew still fits", function()
		local engine, profile = opened(88, 30000)
		local shown = fillCauldron(engine, profile, "cauldron", 3)
		T.truthy(engine.act(profile, "acceptOrder", { orderId = "healing_large_v2" }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "assign", { stationId = "logistics", petId = "88:starter_slime" }, profile.lastSimulatedAt))
		local gold = profile.gold
		T.truthy(engine.act(profile, "brew", { stationId = "cauldron" }, profile.lastSimulatedAt))
		T.truthy(engine.advance(profile, profile.lastSimulatedAt + shown.duration, false).ok)
		T.equal(profile.stations.cauldron.questQueue.healing, Config.questQueueCapacity)
		T.equal(profile.gold, gold)
		T.truthy(engine.advance(profile, profile.lastSimulatedAt + 30, false).ok)
		T.truthy((profile.questStock.healing or 0) > 0)
		T.truthy((profile.stations.cauldron.questQueue.healing or 0) < Config.questQueueCapacity)
		fillCauldron(engine, profile, "cauldron", 3)
		T.truthy(engine.act(profile, "brew", { stationId = "cauldron" }, profile.lastSimulatedAt))
		local before = profile.gold
		local reserved = engine.orderState(profile).reserved
		T.truthy(engine.advance(profile, profile.lastSimulatedAt + shown.duration, false).ok)
		local added = ((profile.stations.cauldron.questQueue.healing or 0) + (profile.questStock.healing or 0) + ((profile.stations.logistics.job and profile.stations.logistics.job.destinationKind == "questStock") and profile.stations.logistics.job.amount or 0)) - reserved
		local sold = (profile.gold - before) / Config.economyV2.healing.goldValue
		T.equal(added + sold, shown.quantity)
		T.truthy(engine.validate(profile))
	end)

	T.test("C01 fix: logistics delivers a full cauldron batch", function()
		local engine, profile = opened(89, 32000)
		profile.phase = 2
		fillCauldron(engine, profile, "cauldron", 4)
		profile.stations.cauldron.input = {}
		profile.inventory.mandrake = 20
		T.truthy(engine.act(profile, "assign", { stationId = "logistics", petId = "89:starter_slime" }, profile.lastSimulatedAt))
		T.truthy(engine.advance(profile, profile.lastSimulatedAt + 40, false).ok)
		T.equal(profile.stations.cauldron.input.mandrake, 20)
		T.equal(profile.inventory.mandrake, nil)
	end)

	local function reserve(profile, queued, travelling, stock)
		profile.stations.cauldron.questQueue = queued > 0 and { healing = queued } or {}
		profile.questStock = stock > 0 and { healing = stock } or {}
		local logistics = profile.stations.logistics
		if travelling > 0 then
			logistics.job = {
				kind = "haul", itemId = "healing", amount = travelling, sourceKind = "questQueue",
				sourceStationId = "cauldron", destinationKind = "questStock", duration = 4,
			}
			logistics.progress = 0
		else
			logistics.job, logistics.progress = nil, 0
		end
	end

	T.test("C01 fix: an expired contract sells reserved potions at the profile price once", function()
		local cases = {
			{ 0, 0, 0 },
			{ 3, 0, 0 },
			{ 2, 2, 1 },
			{ 6, 4, 2 },
		}
		for _, parts in ipairs(cases) do
			local queued, travelling, stock = parts[1], parts[2], parts[3]
			local reserved = queued + travelling + stock
			local engine, profile = opened(91, 40000)
			T.truthy(engine.act(profile, "acceptOrder", { orderId = "healing_large_v2" }, profile.lastSimulatedAt))
			T.equal(profile.order.rewardGold, Config.orders.healing_large_v2.rewardGold)
			reserve(profile, queued, travelling, stock)
			local valid, validReason = engine.validate(profile)
			T.truthy(valid, validReason)
			local gold = profile.gold
			local report = engine.advance(profile, profile.order.expiresAt, false)
			T.truthy(report.ok, report.error)
			T.equal(profile.gold, gold + reserved * Config.economyV2.healing.goldValue)
			T.equal(profile.order, nil)
			T.equal(profile.questStock.healing, nil)
			T.equal(profile.stations.cauldron.questQueue.healing, nil)
			T.equal(profile.stations.logistics.job, nil)
			local again = profile.gold
			T.truthy(engine.advance(profile, profile.lastSimulatedAt, false).ok)
			T.equal(profile.gold, again)
		end
		local legacyEngine = Factory.new(Config)
		local legacy = legacyEngine.grantHistoricalStarters(legacyEngine.newProfile(92, 41000))
		T.truthy(legacyEngine.act(legacy, "acceptOrder", { orderId = "healing_small" }, legacy.lastSimulatedAt))
		T.equal(legacy.order.rewardGold, 110)
		legacy.stations.cauldron.questQueue.healing = 3
		legacy.questStock.healing = 2
		local before = legacy.gold
		T.truthy(legacyEngine.advance(legacy, legacy.order.expiresAt, false).ok)
		T.equal(legacy.gold, before + 5 * Config.recipes.healing.goldValue)
		T.equal(legacy.order, nil)
		T.truthy(legacyEngine.advance(legacy, legacy.lastSimulatedAt, false).ok)
		T.equal(legacy.gold, before + 5 * Config.recipes.healing.goldValue)
	end)

	T.test("C01 fix: claiming a contract pays its stored reward", function()
		local engine, profile = opened(93, 42000)
		T.truthy(engine.act(profile, "acceptOrder", { orderId = "healing_small_v2" }, profile.lastSimulatedAt))
		profile.questStock.healing = profile.order.count
		local gold = profile.gold
		T.truthy(engine.act(profile, "claimOrder", {}, profile.lastSimulatedAt))
		T.equal(profile.gold, gold + Config.orders.healing_small_v2.rewardGold)
		T.falsy(engine.act(profile, "claimOrder", {}, profile.lastSimulatedAt))
		T.equal(profile.gold, gold + Config.orders.healing_small_v2.rewardGold)
		local legacyEngine = Factory.new(Config)
		local legacy = legacyEngine.grantHistoricalStarters(legacyEngine.newProfile(94, 43000))
		T.truthy(legacyEngine.act(legacy, "acceptOrder", { orderId = "healing_small" }, legacy.lastSimulatedAt))
		legacy.questStock.healing = legacy.order.count
		local legacyGold = legacy.gold
		T.truthy(legacyEngine.act(legacy, "claimOrder", {}, legacy.lastSimulatedAt))
		T.equal(legacy.gold, legacyGold + 110)
	end)

	T.test("C01 fix: expiry survives save and reload without a second payout", function()
		local engine, profile = opened(95, 44000)
		T.truthy(engine.act(profile, "acceptOrder", { orderId = "healing_quick_v2" }, profile.lastSimulatedAt))
		reserve(profile, 3, 0, 0)
		T.truthy(engine.advance(profile, profile.order.expiresAt, false).ok)
		T.equal(profile.gold, 1000 + 3 * Config.economyV2.healing.goldValue)
		local persisted = nil
		local now = 45000
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
		local first = store("fix-a")
		local loaded = first:load(95, function() return copy(profile) end)
		T.equal(loaded.gold, profile.gold)
		T.equal(loaded.order, nil)
		T.truthy(first:save(95))
		T.truthy(first:release(95))
		local second = store("fix-b")
		local rejoined = second:load(95, function() return engine.newProfile(95, now) end)
		T.equal(rejoined.gold, profile.gold)
		T.equal(rejoined.order, nil)
		T.truthy(engine.advance(rejoined, now + 5, false).ok)
		T.equal(rejoined.gold, profile.gold)
	end)

	T.test("C01 fix: the server recipe and garden yield follow the station", function()
		local engine, profile = opened(96, 50000)
		local expected = {
			{ 1, 15, 1, 6, 2, 250 },
			{ 2, 45, 3, 8, 6, 750 },
			{ 3, 90, 6, 5, 12, 1500 },
			{ 4, 150, 10, 3, 20, 2500 },
		}
		for _, row in ipairs(expected) do
			profile.stations.cauldron.level = row[1]
			local shown = engine.recipeState(profile, "cauldron", "healing")
			T.equal(shown.essenceCost, row[2])
			T.equal(shown.quantity, row[3])
			T.equal(shown.duration, row[4])
			T.equal(shown.inputs.mandrake, row[5])
			T.equal(shown.saleValue, row[6])
			T.equal(shown.goldValue, Config.economyV2.healing.goldValue)
		end
		local yields = { 2, 6, 12, 18 }
		local grows = { 8, 8, 5, 3 }
		for level = 1, 4 do
			profile.stations.garden.level = level
			local crop = engine.gardenState(profile)
			T.equal(crop.yield, yields[level])
			T.equal(crop.duration, grows[level])
		end
		profile.phase = 4
		profile.stations.cauldron.level = 4
		profile.stations.distillery.level = 1
		profile.stations.distillery.recipeId = "fire_extract"
		local rage = engine.recipeState(profile, "cauldron", "rage")
		T.equal(rage.essenceCost, Config.recipes.rage.essenceCost)
		T.equal(rage.quantity, Config.recipes.rage.quantity)
		T.equal(rage.saleValue, Config.recipes.rage.goldValue)
		local extract = engine.recipeState(profile, "distillery", "fire_extract")
		T.equal(extract.essenceCost, Config.recipes.fire_extract.essenceCost)
		T.equal(extract.quantity, Config.recipes.fire_extract.quantity)
		local legacyEngine = Factory.new(Config)
		local legacy = legacyEngine.grantHistoricalStarters(legacyEngine.newProfile(97, 51000))
		legacy.stations.garden.level = 4
		legacy.stations.cauldron.level = 4
		local old = legacyEngine.recipeState(legacy, "cauldron", "healing")
		T.equal(old.essenceCost, 3)
		T.equal(old.quantity, 1)
		T.equal(old.saleValue, 14)
		T.equal(legacyEngine.gardenState(legacy).yield, Config.firstSession.seedYield)
	end)

	T.test("C01 fix: the second cauldron uses its own level", function()
		local engine, profile = opened(98, 52000)
		profile.phase = 2
		profile.stations.cauldron2.level = 1
		profile.stations.cauldron2.recipeId = "healing"
		local main = fillCauldron(engine, profile, "cauldron", 4)
		local extra = fillCauldron(engine, profile, "cauldron2", 1)
		T.equal(main.quantity, 10)
		T.equal(extra.quantity, 1)
		T.equal(extra.essenceCost, 15)
		T.truthy(engine.act(profile, "brew", { stationId = "cauldron" }, profile.lastSimulatedAt))
		T.truthy(engine.act(profile, "brew", { stationId = "cauldron2" }, profile.lastSimulatedAt))
		T.equal(profile.stations.cauldron.job.outputQuantity, 10)
		T.equal(profile.stations.cauldron.job.duration, 3)
		T.equal(profile.stations.cauldron2.job.outputQuantity, 1)
		T.equal(profile.stations.cauldron2.job.duration, 6)
		profile.stations.cauldron.level = 1
		T.truthy(engine.advance(profile, profile.lastSimulatedAt + 6, false).ok)
		T.equal(profile.gold, 1000 + 250 * 11)
		local legacyEngine = Factory.new(Config)
		local legacy = legacyEngine.grantHistoricalStarters(legacyEngine.newProfile(99, 53000))
		legacy.phase = 2
		legacy.stations.cauldron.level = 4
		legacy.stations.cauldron2.level = 1
		legacy.stations.cauldron2.recipeId = "healing"
		T.equal(legacyEngine.recipeState(legacy, "cauldron", "healing").quantity, 1)
		T.equal(legacyEngine.recipeState(legacy, "cauldron2", "healing").quantity, 1)
	end)

	T.test("C01 fix: a corrupt brew quantity cannot mint or replace a save", function()
		local engine, profile = opened(100, 54000)
		fillCauldron(engine, profile, "cauldron", 1)
		T.truthy(engine.act(profile, "brew", { stationId = "cauldron" }, profile.lastSimulatedAt))
		local job = profile.stations.cauldron.job
		job.outputQuantity = nil
		T.truthy(engine.validate(profile))
		T.truthy(engine.advance(profile, profile.lastSimulatedAt + job.duration, false).ok)
		T.equal(profile.gold, 1000 + Config.economyV2.healing.goldValue)
		fillCauldron(engine, profile, "cauldron", 1)
		T.truthy(engine.act(profile, "brew", { stationId = "cauldron" }, profile.lastSimulatedAt))
		local legal = copy(profile.stations.cauldron.job)
		for _, bad in ipairs({ -1, 0, 1.5, "6", 1000000 }) do
			profile.stations.cauldron.job.outputQuantity = bad
			local valid = engine.validate(profile)
			T.falsy(valid)
			local gold = profile.gold
			local report = engine.advance(profile, profile.lastSimulatedAt + 20, false)
			T.falsy(report.ok)
			T.equal(profile.gold, gold)
			T.equal(profile.stations.cauldron.job.outputQuantity, bad)
		end
		profile.stations.cauldron.job = legal
		T.truthy(engine.validate(profile))
		local persisted = nil
		local now = 55000
		local fake = {}
		function fake:UpdateAsync(_key, transform)
			local updated = transform(persisted and copy(persisted) or nil)
			if updated == nil then return nil end
			persisted = copy(updated)
			return copy(persisted)
		end
		local store = ProfileStore.new({
			dataStore = fake, now = function() return now end, owner = "fix-job",
			validate = engine.validate, migrate = engine.migrate, sleep = function() end,
		})
		local saved = store:load(100, function() return copy(profile) end)
		T.truthy(store:save(100))
		saved.stations.cauldron.job.outputQuantity = 1000000
		local savedOk = store:save(100)
		T.falsy(savedOk)
		T.equal(persisted.profile.stations.cauldron.job.outputQuantity, 1)
		persisted.profile.stations.cauldron.job.outputQuantity = "6"
		local blocked = ProfileStore.new({
			dataStore = fake, now = function() return now end, owner = "fix-job-b",
			validate = engine.validate, migrate = engine.migrate, sleep = function() end,
		})
		local replaced, reason = blocked:load(100, function() return engine.newProfile(100, now) end)
		T.equal(replaced, nil)
		T.truthy(reason)
		T.equal(persisted.profile.stations.cauldron.job.outputQuantity, "6")
		T.equal(persisted.profile.gold, profile.gold)
	end)

	T.test("C01 economy: Sprout Owl, Green Slime and Magic Cat stay inside the measured hour", function()
		for _, species in ipairs({ "farmer", "slime", "brewer" }) do
			local first = play(3600, species)
			local second = play(3600, species)
			T.equal(first.profile.gold, second.profile.gold)
			T.equal(first.potions, second.potions)
			T.truthy(first.saleAt <= 90)
			T.truthy(first.autoAt <= 180)
			T.truthy(first.crystalAt <= 300)
			print(string.format("C01 familiar %s sale=%ds auto=%ds crystal2=%ds potions=%d", species, first.saleAt, first.autoAt, first.crystalAt, first.potions))
			for _, mark in ipairs({ 300, 900, 1800, 3600 }) do
				local row = first.snapshots[mark]
				print(string.format(
					"C01 familiar %s %ds earned=%d spent=%d gold=%d garden=%d cauldron=%d crystal=%d potions=%d essenceStall=%d mandrakeStall=%d queue=%d manual=%d noMaster=%d nextGarden=%s nextCauldron=%s nextCrystal=%s",
					species, mark, row.earned, row.spent, row.gold, row.garden, row.cauldron, row.crystal, row.potions,
					row.essenceStall, row.mandrakeStall, row.queueFull, row.manual, row.noMaster,
					row.upgrades.garden, row.upgrades.cauldron, row.upgrades.crystal))
			end
			local beforeGold, beforeEssence = first.profile.gold, first.profile.essence
			local offline = first.engine.advance(first.profile, first.profile.lastSimulatedAt + 7200, true)
			T.equal(offline.processedSeconds, 7200)
			T.truthy((offline.sold.healing or 0) > 0)
			T.truthy(first.profile.gold > beforeGold)
			T.truthy(first.engine.validate(first.profile))
			print(string.format("C01 familiar %s offline7200 sold=%d gold=%d essence=%d bankedEssence=%d", species, offline.sold.healing or 0, first.profile.gold, first.profile.essence, beforeEssence))
		end
	end)
end
