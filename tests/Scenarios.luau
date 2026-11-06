--!nonstrict
-- Reproducible economy traces; every resource comes from a valid player intent
-- or the production simulation. Travel/UI/network latency is not modeled.
local Config = require("../src/shared/Config")
local Factory = require("../src/shared/Factory")
local Protocol = require("../src/shared/Protocol")
local Epochs = require("../src/shared/Epochs")

return function(strategy, observe, initial)
	local engine, gate = initial and initial.engine or Factory.new(Config), Protocol.new()
	local start, now = initial and initial.now or 100000, initial and initial.now or 100000
	local profile = initial and initial.profile or engine.newProfile(-1, now)
	engine.grantHistoricalStarters(profile)
	local actions, clicks, harvests = 0, 0, 0
	local function waitFor(seconds)
		now += seconds
		local report = engine.advance(profile, now, false)
		assert(report.ok, report.error)
		local valid, reason = engine.validate(profile)
		assert(valid, reason)
		if observe then observe(profile) end
	end
	local function intent(action, payload)
		waitFor(1)
		payload = payload or {}
		if action == "buy" then
			local id = payload.upgradeId
			payload.expectedLevel = id == "pipes" and (profile.pipes and 1 or 0)
				or (id == "warehouse" and profile.warehouseLevel or profile.stations[id].level)
		end
		local accepted, rejection = gate:check(profile.userId, action, payload, now)
		assert(accepted, rejection)
		local ok, message = engine.act(profile, action, payload, now)
		-- A carrier/pipe may finish during this intent's simulated second.
		assert(ok or (action == "load" and message == "No ingredients or Essence to load"), action .. ": " .. tostring(message))
		assert(engine.validate(profile))
		if observe then observe(profile) end
		actions += 1
		if action == "click" then clicks += 1 end
		if action == "harvest" then harvests += 1 end
	end
	local function manual()
		local station = profile.stations.cauldron
		while station.job do waitFor(1) end
		while profile.essence + station.essence < Config.recipes.healing.essenceCost do intent("click") end
		while (profile.inventory.mandrake or 0) + (station.input.mandrake or 0) < 2 do
			waitFor(math.max(0, profile.manualReadyAt.garden - now))
			intent("harvest", { stationId = "garden" })
		end
		-- Transport may have filled all inputs while we were gathering.
		if station.essence < 3 or (station.input.mandrake or 0) < 2 then intent("load", { stationId = "cauldron" }) end
		for _ = 1, 30 do
			if station.essence >= 3 and (station.input.mandrake or 0) >= 2 then break end
			waitFor(1)
		end
		intent("brew", { stationId = "cauldron" })
		while station.job do waitFor(1) end
	end
	intent("click")
	intent("harvest", { stationId = "garden" })
	for _, pair in ipairs({ {"garden", "farmer"}, {"logistics", "slime"}, {"cauldron", "brewer"} }) do
		intent("assign", { stationId = pair[1], petId = "-1:starter_" .. pair[2] })
	end
	manual()
	local firstSale = now - start
	if strategy == "detour" then
		while profile.gold < Epochs.cost(Config,profile,Config.stations.garden.upgradeCosts[2]) do manual() end
		intent("buy", { upgradeId = "garden" })
		-- An unnecessary early purchase must not lock the tutorial or its income.
	end
	while profile.gold < Epochs.cost(Config,profile,Config.pipesCost) do manual() end
	intent("buy", { upgradeId = "pipes" })
	if strategy == "automation" then
		intent("setAuto", { stationId = "cauldron", enabled = true })
		for _ = 1, 1200 do
			if profile.gold >= Epochs.cost(Config,profile,Config.stations.crystal.upgradeCosts[2]) then break end
			intent("click")
		end
	else
		while profile.gold < Epochs.cost(Config,profile,Config.stations.crystal.upgradeCosts[2]) do manual() end
	end
	intent("buy", { upgradeId = "crystal" })
	intent("setAuto", { stationId = "cauldron", enabled = true })
	local autonomous = now - start
	for _ = 1, 120 do
		if profile.tutorial.automation then break end
		waitFor(1)
	end
	assert(profile.tutorial.automation, "First automatic Healing must complete")
	intent("acceptOrder", { orderId = "healing_small" })
	for _ = 1, Config.orders.healing_small.duration - 5 do
		if (profile.questStock.healing or 0) == Config.orders.healing_small.count then break end
		waitFor(1)
	end
	intent("claimOrder")
	assert(engine.tutorialState(profile).complete, "Full tutorial must finish")
	local claimed = now - start
	local before = profile.gold
	waitFor(600)
	assert(profile.gold > before, "Autonomous factory must earn without clicking or harvesting")
	return { engine = engine, profile = profile, now = now, start = start, strategy = strategy,
		firstSale = firstSale, autonomous = autonomous, claimed = claimed, actions = actions,
		clicks = clicks, harvests = harvests, goldAfterClaim = before, passiveGold = profile.gold - before }
end
