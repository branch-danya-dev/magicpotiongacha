--!nonstrict
local Config = require("../src/shared/Config")
local Factory = require("../src/shared/Factory")
local Protocol = require("../src/shared/Protocol")
local Access = require("../src/shared/Access")
local ProfileStore = require("../src/server/ProfileStore")
local scenario = require("./Scenarios")

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for k, v in pairs(value) do result[k] = copy(v) end
	return result
end

return function(T: any)
	local START = 100000
	local function fresh(config)
		local engine = Factory.new(config or Config)
		return engine, engine.newProfile(123, START)
	end
	local function act(engine, p, action, payload)
		payload = payload or {}
		if action == "buy" then
			local id = payload.upgradeId
			payload.expectedLevel = id == "pipes" and (p.pipes and 1 or 0) or (id == "warehouse" and p.warehouseLevel or p.stations[id].level)
		end
		local ok, reason = engine.act(p, action, payload, p.lastSimulatedAt)
		T.truthy(ok, reason)
		T.truthy(engine.validate(p))
	end
	local function advance(engine, p, seconds, offline)
		local report = engine.advance(p, p.lastSimulatedAt + seconds, offline or false)
		T.truthy(report.ok, report.error)
		local valid, reason = engine.validate(p)
		T.truthy(valid, reason)
		return report
	end
	local function assign(engine, p, station, species)
		act(engine, p, "assign", { stationId = station, petId = "123:starter_" .. species })
	end
	local function makeCrates(engine, p, amount)
		act(engine, p, "acceptOrder", { orderId = "healing_large" })
		-- Prepared state for conservation tests only; zero-resource play is above.
		p.stations.cauldron.questQueue.healing = amount
		T.truthy(engine.validate(p))
	end

	for _, strategy in ipairs({ "manual", "automation", "detour" }) do
		T.test("M1: zero-resource full tutorial / " .. strategy, function()
			local result = scenario(strategy)
			T.truthy(result.engine.tutorialState(result.profile).complete)
			T.truthy(result.profile.telemetry.first.manual_brew)
			T.truthy(result.profile.telemetry.first.auto_brew)
			T.truthy(result.profile.telemetry.first.upgrade)
			T.truthy(result.profile.telemetry.first.contract)
			T.truthy(result.profile.telemetry.first.tutorial)
			print(string.format("ECONOMY %s: sale=%ds autonomous=%ds NPC=%ds actions=%d clicks=%d harvests=%d GoldAfterClaim=%d passive600s=%d",
				strategy, result.firstSale, result.autonomous, result.claimed, result.actions, result.clicks, result.harvests, result.goldAfterClaim, result.passiveGold))
		end)
	end

	T.test("M1: reservoir cannot power a brew without an explicit transfer", function()
		local e, p = fresh()
		p.essence, p.stations.cauldron.input.mandrake = 10, 2
		T.falsy(e.act(p, "brew", { stationId = "cauldron" }, START))
		T.equal(e.stationState(p, "cauldron").code, "no_path")
		act(e, p, "load", { stationId = "cauldron" })
		T.equal(p.essence, 7)
		T.equal(p.stations.cauldron.essence, 3)
		act(e, p, "brew", { stationId = "cauldron" })
		T.equal(p.essence, 7)
		T.equal(p.stations.cauldron.essence, 0)
	end)

	T.test("M1: tanks conserve Essence, stop at capacity and share scarce pipe supply", function()
		local e, p = fresh()
		p.gold, p.essence = 1000, 100
		act(e, p, "buy", { upgradeId = "distillery" })
		act(e, p, "buy", { upgradeId = "pipes" })
		advance(e, p, 30)
		T.equal(p.stations.distillery.essence, 24)
		T.equal(p.stations.cauldron.essence, 24)
		T.equal(p.essence, 52)
		p.essence, p.stations.distillery.essence, p.stations.cauldron.essence = 0, 0, 0
		for _ = 1, 2 do act(e, p, "click"); advance(e, p, 1) end
		T.equal(p.stations.distillery.essence, 1)
		T.equal(p.stations.cauldron.essence, 1)
	end)

	T.test("M1: automatic haulers never pick up liquids without pipes", function()
		local e, p = fresh()
		p.gold = 1000
		act(e, p, "buy", { upgradeId = "distillery" })
		act(e, p, "buy", { upgradeId = "cauldron" })
		act(e, p, "setRecipe", { stationId = "cauldron", recipeId = "rage" })
		p.stations.distillery.output.fire_extract, p.inventory.fire_extract = 2, 1
		assign(e, p, "logistics", "slime")
		advance(e, p, 20)
		T.equal(p.stations.logistics.job, nil)
		T.equal(p.stations.distillery.output.fire_extract, 2)
		T.equal(p.inventory.fire_extract, 1)
		act(e, p, "buy", { upgradeId = "pipes" })
		advance(e, p, 1)
		T.equal(p.stations.cauldron.input.fire_extract, 1)
	end)

	T.test("M1: crate source, transit and delivered stock are disjoint", function()
		local e, p = fresh()
		makeCrates(e, p, 5)
		T.equal(e.orderState(p).queued, 5)
		T.falsy(e.act(p, "claimOrder", {}, START))
		assign(e, p, "logistics", "slime")
		advance(e, p, 1)
		local progress = e.orderState(p)
		T.equal(progress.queued, 2)
		T.equal(progress.travelling, 3)
		T.equal(progress.delivered, 0)
		T.equal(progress.reserved, 5)
		advance(e, p, 4)
		T.equal(e.orderState(p).delivered, 3)
		T.equal(e.orderState(p).reserved, 5)
	end)

	T.test("M1: unassignment and slower replacement preserve paused crate cargo", function()
		local e, p = fresh()
		makeCrates(e, p, 5)
		assign(e, p, "logistics", "slime")
		advance(e, p, 2)
		local job, progress = copy(p.stations.logistics.job), p.stations.logistics.progress
		act(e, p, "assign", { stationId = "logistics", petId = "" })
		advance(e, p, 50)
		T.same(p.stations.logistics.job, job)
		T.equal(p.stations.logistics.progress, progress)
		assign(e, p, "garden", "slime")
		assign(e, p, "logistics", "farmer")
		advance(e, p, 1)
		T.near(p.stations.logistics.progress - progress, 1 + 2 * Config.haulSpeedPerSkill)
		advance(e, p, 20)
		T.equal(e.orderState(p).reserved, 5)
		T.equal(e.orderState(p).delivered, 5)
	end)

	T.test("M1: partial delivery retains remainder until quest storage has room", function()
		local config = copy(Config)
		config.warehouse.questCapacity[1] = 3
		config.orders.healing_small.count = 3
		local e, p = fresh(config)
		act(e, p, "acceptOrder", { orderId = "healing_small" })
		p.stations.cauldron.questQueue.healing = 3
		assign(e, p, "logistics", "slime")
		advance(e, p, 1)
		-- Capacity can shrink on configuration rollout while cargo is already out.
		config.warehouse.questCapacity[1] = 2
		advance(e, p, 4)
		T.equal(p.questStock.healing, 2)
		T.equal(p.stations.logistics.job.amount, 1)
		T.equal(e.stationState(p, "logistics").code, "queue_full")
		advance(e, p, 5)
		T.equal(e.orderState(p).reserved, 3)
		config.warehouse.questCapacity[1] = 3
		advance(e, p, 1)
		act(e, p, "claimOrder")
		local gold = p.gold
		T.falsy(e.act(p, "claimOrder", {}, p.lastSimulatedAt))
		T.equal(p.gold, gold)
	end)

	T.test("M1: queue backpressure waits without charging or rerolling the batch", function()
		local e, p = fresh()
		makeCrates(e, p, 4)
		p.stations.cauldron.essence, p.stations.cauldron.input.mandrake = 3, 2
		act(e, p, "brew", { stationId = "cauldron" })
		p.stations.cauldron.questQueue.healing = 6
		local rng = p.rngState
		advance(e, p, 10)
		T.equal(p.rngState, rng)
		T.truthy(p.stations.cauldron.job)
		T.equal(e.stationState(p, "cauldron").code, "queue_full")
		T.falsy(e.act(p, "brew", { stationId = "cauldron" }, p.lastSimulatedAt))
		assign(e, p, "logistics", "slime")
		advance(e, p, 1)
		T.equal(e.orderState(p).reserved, 7)
		T.equal(p.stations.cauldron.job, nil)
	end)

	T.test("M1: expiry sells queued, travelling and delivered crates once, even paused", function()
		local e, p = fresh()
		makeCrates(e, p, 5)
		p.questStock.healing = 2
		assign(e, p, "logistics", "slime")
		advance(e, p, 1)
		act(e, p, "assign", { stationId = "logistics", petId = "" })
		advance(e, p, p.order.expiresAt - p.lastSimulatedAt, true)
		T.equal(p.gold, 7 * Config.recipes.healing.goldValue)
		T.equal(p.order, nil)
		T.equal(p.stations.logistics.job, nil)
		T.equal(e.orderState(p).reserved, 0)
		local before = copy(p)
		advance(e, p, 0, true)
		T.same(p, before)
		T.falsy(e.act(p, "claimOrder", {}, p.lastSimulatedAt))
	end)

	T.test("M1: expiry at the delivery boundary exports without contract reward", function()
		local e, p = fresh()
		makeCrates(e, p, 3)
		assign(e, p, "logistics", "slime")
		advance(e, p, 1)
		p.lastSimulatedAt = p.order.expiresAt - 1
		p.stations.logistics.progress = p.stations.logistics.job.duration
		advance(e, p, 1)
		T.equal(p.gold, 42)
		T.equal(e.orderState(p).reserved, 0)
	end)

	T.test("M1: automatic batch pauses without its master and resumes prepaid", function()
		local e, p = fresh()
		p.discoveredRecipes.healing = true
		p.stations.cauldron.input.mandrake, p.stations.cauldron.essence = 2, 3
		assign(e, p, "cauldron", "brewer")
		act(e, p, "setAuto", { stationId = "cauldron", enabled = true })
		advance(e, p, 1)
		act(e, p, "assign", { stationId = "cauldron", petId = "" })
		local job = copy(p.stations.cauldron.job)
		advance(e, p, 30)
		T.same(p.stations.cauldron.job, job)
		T.equal(p.gold, 0)
		T.equal(e.stationState(p, "cauldron").code, "no_master")
		assign(e, p, "cauldron", "brewer")
		advance(e, p, 10)
		T.truthy(p.gold >= 14)
		T.equal(p.stations.cauldron.essence, 0)
	end)

	T.test("M1: current recipe changes cannot redirect a travelling quest crate", function()
		local e, p = fresh()
		p.gold = 1000
		act(e, p, "buy", { upgradeId = "cauldron" })
		makeCrates(e, p, 3)
		assign(e, p, "logistics", "slime")
		advance(e, p, 1)
		act(e, p, "setRecipe", { stationId = "cauldron", recipeId = "rage" })
		advance(e, p, 5)
		T.equal(p.questStock.healing, 3)
		T.equal(p.questStock.rage, nil)
	end)

	T.test("M1: repeated buy request is fenced by the expected level", function()
		local e, p = fresh()
		p.gold = 1000
		local payload = { upgradeId = "crystal", expectedLevel = 1 }
		T.truthy(e.act(p, "buy", payload, START))
		local before = copy(p)
		T.falsy(e.act(p, "buy", payload, START))
		T.same(p, before)
	end)

	T.test("M1: malicious logistics, tutorial and purchase payloads fail exact schemas", function()
		local e, p = fresh()
		for _, pair in ipairs({
			{ "load", { stationId = "cauldron", essence = 99 } },
			{ "claimOrder", { amount = 5 } },
			{ "assign", { stationId = "logistics", petId = "123:starter_slime", speed = 1000 } },
			{ "brew", { stationId = "cauldron", duration = 0 } },
			{ "buy", { upgradeId = "pipes" } },
			{ "buy", { upgradeId = "pipes", expectedLevel = 0 / 0 } },
			{ "completeTutorial", {} }, { "deliverCrate", {} },
		}) do
			T.falsy(Protocol.new():check(123, pair[1], pair[2], START))
			T.falsy(e.act(p, pair[1], pair[2], START))
		end
		T.falsy(e.act(p, "assign", { stationId = "logistics", petId = "456:starter_slime" }, START))
	end)

	T.test("M1: refilling is authorized at one's own live nearby machine only", function()
		T.equal(Access.target("load", { stationId = "cauldron" }), "cauldron")
		T.equal(Access.target("buy", { upgradeId = "pipes" }), "warehouse")
		T.equal(Access.target("claimOrder", {}), "orders")
		T.equal(Access.target("grant", { stationId = "crystal" }), nil)
		T.truthy(Access.allowed(true, true, 16, 16))
		T.falsy(Access.allowed(false, true, 1, 16))
		T.falsy(Access.allowed(true, false, 1, 16))
		T.falsy(Access.allowed(true, true, 17, 16))
		T.falsy(Access.allowed(true, true, 0 / 0, 16))
	end)

	T.test("M1: new controls remain under aggregate and per-action rate limits", function()
		local gate = Protocol.new()
		for _ = 1, 10 do T.truthy(gate:check(123, "load", { stationId = "cauldron" }, 1)) end
		T.falsy(gate:check(123, "load", { stationId = "cauldron" }, 1))
		T.truthy(gate:check(123, "load", { stationId = "cauldron" }, 2))
	end)

	T.test("M1: full tutorial survives save, offline catch-up and immediate second join", function()
		local result = scenario("automation")
		local e, fixture, now = result.engine, result.profile, result.now
		local records = {}
		local backend = { UpdateAsync = function(_, key, transform)
			local value = transform(copy(records[key]))
			if value then records[key] = copy(value) end
			return copy(value)
		end }
		local function session(owner)
			return ProfileStore.new({ dataStore = backend, now = function() return now end,
				owner = owner, validate = e.validate, migrate = e.migrate, sleep = function() end })
		end
		local first = session("A")
		T.truthy(first:load(-1, function() return copy(fixture) end))
		T.truthy(first:release(-1))
		now += 10800
		local second = session("B")
		local loaded = second:load(-1, function() return e.newProfile(-1, now) end)
		local online = copy(fixture)
		for _ = 1, 7200 do advance(e, online, 1) end
		local report = e.advance(loaded, now, true)
		T.equal(report.processedSeconds, 7200)
		online.lastSimulatedAt = now
		T.same(loaded, online)
		T.truthy(second:save(-1))
		T.truthy(second:release(-1))
		local third = session("C")
		local rejoined = third:load(-1, function() return e.newProfile(-1, now) end)
		T.equal(e.advance(rejoined, now, true).goldEarned, 0)
		T.same(rejoined, loaded)
		T.truthy(e.tutorialState(rejoined).complete)
	end)

	T.test("M1: every tutorial checkpoint resumes without resetting facts or starter workers", function()
		local engine = Factory.new(Config)
		local checkpoints = {}
		scenario("automation", function(p)
			for _, id in ipairs(Config.tutorialSteps) do
				if p.tutorial[id] and not checkpoints[id] then checkpoints[id] = copy(p) end
			end
			if p.stations.cauldron.job and not p.tutorial.manual and not checkpoints.manual_in_progress then checkpoints.manual_in_progress = copy(p) end
		end)
		T.truthy(checkpoints.manual_in_progress)
		for _, id in ipairs(Config.tutorialSteps) do T.truthy(checkpoints[id], "Missing saved checkpoint: " .. id) end
		for id, fixture in pairs(checkpoints) do
			T.truthy(fixture, "Missing saved checkpoint: " .. id)
			local saved
			local backend = { UpdateAsync = function(_, _, transform)
				local nextValue = transform(copy(saved))
				if nextValue then saved = copy(nextValue) end
				return copy(nextValue)
			end }
			local function session(owner)
				return ProfileStore.new({ dataStore = backend, now = function() return fixture.lastSimulatedAt end,
					owner = owner, validate = engine.validate, migrate = engine.migrate, sleep = function() end })
			end
			local a = session("A")
			T.truthy(a:load(-1, function() return copy(fixture) end))
			T.truthy(a:release(-1))
			local b = session("B")
			local rejoined = b:load(-1, function() return engine.newProfile(-1, fixture.lastSimulatedAt) end)
			T.same(rejoined, fixture)
			T.equal(engine.tutorialState(rejoined).id, engine.tutorialState(fixture).id)
		end
	end)

	T.test("M1: two-machine liquid chain and quest cargo match online for two hours", function()
		local e, p = fresh()
		p.gold = 10000 -- Post-tutorial equipment fixture; three zero-grant scenarios are separate.
		for _, id in ipairs({ "crystal", "mine", "distillery", "cauldron", "pipes", "warehouse", "warehouse", "warehouse" }) do act(e, p, "buy", { upgradeId = id }) end
		assign(e, p, "garden", "farmer")
		assign(e, p, "logistics", "slime")
		assign(e, p, "cauldron", "brewer")
		act(e, p, "hire", { speciesId = "farmer" })
		act(e, p, "assign", { stationId = "mine", petId = "123:hire:1" })
		act(e, p, "hire", { speciesId = "brewer" })
		act(e, p, "assign", { stationId = "distillery", petId = "123:hire:2" })
		p.discoveredRecipes.fire_extract, p.discoveredRecipes.rage = true, true
		act(e, p, "setRecipe", { stationId = "cauldron", recipeId = "rage" })
		act(e, p, "setAuto", { stationId = "cauldron", enabled = true })
		act(e, p, "setAuto", { stationId = "distillery", enabled = true })
		act(e, p, "acceptOrder", { orderId = "rage_small" })
		advance(e, p, 90)
		local offline = copy(p)
		for _ = 1, 7200 do advance(e, p, 1) end
		local report = advance(e, offline, 7200, true)
		T.truthy((report.produced.fire_extract or 0) > 0)
		T.truthy((report.produced.rage or 0) > 0)
		T.truthy((report.sold.rage or 0) > 0)
		T.equal(offline.order, nil) -- Expiry must also settle its crates in either schedule.
		T.same(offline, p)
	end)

	T.test("M1: a full raw warehouse never blocks already loaded normal potion export", function()
		local e, p = fresh()
		p.inventory.slime = Config.warehouse.rawCapacity[1]
		p.stations.cauldron.essence, p.stations.cauldron.input.mandrake = 3, 2
		act(e, p, "brew", { stationId = "cauldron" })
		advance(e, p, 6)
		T.equal(p.gold, 14)
		T.equal(p.inventory.slime, Config.warehouse.rawCapacity[1])
		act(e, p, "discard", { itemId = "slime", amount = 2 })
		act(e, p, "harvest", { stationId = "garden" })
		T.equal(p.inventory.mandrake, 1)
	end)

	T.test("M1: stock saved in transit resumes delivery rather than picking up twice", function()
		local e, p = fresh()
		makeCrates(e, p, 5)
		assign(e, p, "logistics", "slime")
		advance(e, p, 2)
		local saved
		local backend = { UpdateAsync = function(_, _, transform)
			local value = transform(copy(saved))
			if value then saved = copy(value) end
			return copy(value)
		end }
		local function session(owner)
			return ProfileStore.new({ dataStore = backend, now = function() return p.lastSimulatedAt end,
				owner = owner, validate = e.validate, migrate = e.migrate, sleep = function() end })
		end
		local first = session("A")
		T.truthy(first:load(123, function() return copy(p) end))
		T.truthy(first:release(123))
		local second = session("B")
		local rejoined = second:load(123, function() return e.newProfile(123, p.lastSimulatedAt) end)
		T.same(rejoined, p)
		advance(e, rejoined, 20, true)
		T.equal(e.orderState(rejoined).delivered, 5)
		T.equal(e.orderState(rejoined).reserved, 5)
	end)

	local invalid = {
		{ "tank overflow", function(p) p.stations.cauldron.essence = Config.essenceBufferCapacity + 1 end },
		{ "unbuilt tank", function(p) p.stations.distillery.essence = 1 end },
		{ "negative tank", function(p) p.stations.cauldron.essence = -1 end },
		{ "queue overflow", function(p) p.stations.cauldron.questQueue.healing = Config.questQueueCapacity + 1 end },
		{ "orphan crate", function(p) p.stations.cauldron.questQueue.healing = 1 end },
		{ "wrong source", function(p) p.stations.garden.questQueue.healing = 1 end },
		{ "pipe cursor", function(p) p.pipeCursor = 0 end },
		{ "unknown tutorial step", function(p) p.tutorial.cheat = true end },
		{ "false tutorial step", function(p) p.tutorial.manual = false end },
		{ "unknown telemetry", function(p) p.telemetry.first.cheat = START end },
		{ "negative stall", function(p) p.telemetry.stalls.cauldron = { waiting_essence = -1 } end },
	}
	for _, entry in ipairs(invalid) do
		T.test("M1: invalid saved state fails closed / " .. entry[1], function()
			local e, p = fresh()
			entry[2](p)
			local called, valid = pcall(e.validate, p)
			T.truthy(called)
			T.falsy(valid)
			T.falsy(e.advance(p, START + 1, true).ok)
		end)
	end

	T.test("M1: mixed production, recipe switches, expiry and claims conserve every potion", function()
		local e, p = fresh()
		p.gold, p.essence = 10000, 10000
		for _, id in ipairs({ "crystal", "cauldron", "pipes" }) do act(e, p, "buy", { upgradeId = id }) end
		assign(e, p, "garden", "farmer")
		assign(e, p, "logistics", "slime")
		assign(e, p, "cauldron", "brewer")
		p.discoveredRecipes.healing = true
		act(e, p, "setAuto", { stationId = "cauldron", enabled = true })
		local seed, made, sold, claimed = 927, 0, 0, 0
		for index = 1, 500 do
			seed = seed * 48271 % 2147483647
			local report = advance(e, p, index % 100 == 0 and 1300 or (seed % 13 + 1), index % 100 == 0)
			made += report.produced.healing or 0
			sold += report.sold.healing or 0
			local choice = seed % 7
			local action, payload
			if choice == 0 then action, payload = "acceptOrder", { orderId = "healing_small" }
			elseif choice == 1 then action, payload = "claimOrder", {}
			elseif choice == 2 then action, payload = "assign", { stationId = "logistics", petId = "" }
			elseif choice == 3 then action, payload = "assign", { stationId = "logistics", petId = "123:starter_slime" }
			elseif choice == 4 then action, payload = "setRecipe", { stationId = "cauldron", recipeId = "healing" }
			elseif choice == 5 then action, payload = "load", { stationId = "cauldron" }
			else action, payload = "harvest", { stationId = "garden" } end
			local orderCount = p.order and p.order.count or 0
			local success = e.act(p, action, payload, p.lastSimulatedAt)
			if success and action == "claimOrder" then claimed += orderCount end
			T.truthy(e.validate(p))
			T.equal(made, sold + claimed + e.orderState(p).reserved, "Potion conservation at transition " .. index)
		end
		T.truthy(made > 20)
		T.truthy(claimed > 0)
	end)
end
