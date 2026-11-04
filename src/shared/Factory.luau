-- Deterministic, server-owned factory simulation. No Roblox services or clocks are used here.
local Factory = {}

local function finite(value)
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function integer(value, minimum, maximum)
	return finite(value) and value % 1 == 0 and value >= minimum and value <= maximum
end

local function plain(value)
	return type(value) == "table" and getmetatable(value) == nil
end

local function identifier(value, maximum)
	return type(value) == "string" and #value > 0 and #value <= maximum
end

local function keys(map)
	local result = {}
	for key in pairs(map) do
		table.insert(result, key)
	end
	table.sort(result)
	return result
end

local function quantity(map, itemId)
	return map[itemId] or 0
end

local function total(map)
	local result = 0
	for _, amount in pairs(map) do
		result = result + amount
	end
	return result
end

local function change(map, itemId, amount)
	local nextAmount = quantity(map, itemId) + amount
	if nextAmount == 0 then
		map[itemId] = nil
	else
		map[itemId] = nextAmount
	end
end

function Factory.new(config)
	assert(plain(config), "Factory.new requires a configuration table")
	local engine = {}
	local itemIds = keys(config.items)
	local skills = { "Farming", "Hauling", "Brewing" }
	local rngModulus = 2147483647
	local routeCount = #config.machineOrder + #config.sourceOrder

	local function capacity(profile, kind)
		local field = kind == "raw" and "rawCapacity" or "intermediateCapacity"
		return config.warehouse[field][profile.warehouseLevel + 1]
	end

	local function stored(profile, kind)
		local result = 0
		for itemId, amount in pairs(profile.inventory) do
			if config.items[itemId].kind == kind then
				result = result + amount
			end
		end
		return result
	end

	local function inventoryRoom(profile, itemId)
		local kind = config.items[itemId].kind
		return math.max(0, capacity(profile, kind) - stored(profile, kind))
	end

	local function effectiveSkill(profile, stationId)
		local station = profile.stations[stationId]
		local pet = station.workerId and profile.pets[station.workerId]
		if not pet or station.level == 0 then
			return 0
		end
		local definition = config.stations[stationId]
		return math.min(pet.stats[definition.skill], definition.statCaps[station.level])
	end

	local function nextRandom(profile)
		profile.rngState = (profile.rngState * 48271) % rngModulus
		return profile.rngState / rngModulus
	end

	local function countMap(value, predicate, maximum)
		if not plain(value) then
			return false
		end
		local amount = 0
		for itemId, count in pairs(value) do
			if type(itemId) ~= "string" or not config.items[itemId] or not predicate(itemId)
				or not integer(count, 0, config.maxCount) then
				return false
			end
			amount = amount + count
		end
		return amount <= maximum
	end

	function engine.validate(profile)
		if not plain(profile) or profile.schemaVersion ~= config.schemaVersion then
			return false, "Unsupported profile schema"
		end
		if not integer(profile.userId, -9007199254740991, 9007199254740991)
			or not integer(profile.lastSimulatedAt, 0, config.maxTimestamp)
			or not integer(profile.rngState, 1, rngModulus - 1)
			or not integer(profile.gold, 0, config.maxBalance)
			or not integer(profile.essence, 0, config.maxBalance)
			or not integer(profile.rebirths, 0, config.maxCount)
			or not integer(profile.nextPetSerial, 1, config.maxCount)
			or not integer(profile.warehouseLevel, 0, #config.warehouse.upgradeCosts)
			or type(profile.pipes) ~= "boolean" or profile.tutorialGranted ~= true then
			return false, "Invalid profile scalar"
		end
		if not plain(profile.pets) or not plain(profile.stations) or not plain(profile.manualReadyAt)
			or not plain(profile.slimeWorkSeconds) or not plain(profile.discoveredRecipes)
			or not plain(profile.receipts) or not plain(profile.entitlements) then
			return false, "Invalid profile collection"
		end
		local petCount = 0
		for petId, pet in pairs(profile.pets) do
			petCount = petCount + 1
			if not identifier(petId, 80) or not plain(pet) or pet.id ~= petId
				or type(pet.species) ~= "string" or not config.petSpecies[pet.species]
				or not identifier(pet.name, 80) or type(pet.paidOrigin) ~= "boolean"
				or not plain(pet.stats) then
				return false, "Invalid pet"
			end
			for _, skill in ipairs(skills) do
				if not integer(pet.stats[skill], 0, config.maxBaseStat) then
					return false, "Invalid pet stat"
				end
			end
			for skill in pairs(pet.stats) do
				if skill ~= "Farming" and skill ~= "Hauling" and skill ~= "Brewing" then
					return false, "Unknown pet stat"
				end
			end
		end
		if petCount > config.maxPets then
			return false, "Pet capacity exceeded"
		end
		local assigned = {}
		for stationId in pairs(profile.stations) do
			if not config.stations[stationId] then
				return false, "Unknown station"
			end
		end
		for _, stationId in ipairs(config.stationOrder) do
			local station = profile.stations[stationId]
			local definition = config.stations[stationId]
			if not plain(station) or not integer(station.level, 0, #definition.upgradeCosts)
				or type(station.auto) ~= "boolean" or not finite(station.progress)
				or station.progress < 0 or station.progress > config.maxJobDuration then
				return false, "Invalid station"
			end
			if stationId == "logistics" and not integer(station.routeCursor, 1, routeCount) then
				return false, "Invalid logistics route cursor"
			end
			if station.workerId ~= nil then
				if type(station.workerId) ~= "string" or not profile.pets[station.workerId]
					or assigned[station.workerId] or station.level == 0 then
					return false, "Invalid or duplicate worker assignment"
				end
				assigned[station.workerId] = true
			end
			if station.recipeId ~= nil then
				local recipe = config.recipes[station.recipeId]
				if not recipe or recipe.station ~= stationId or station.level < recipe.requiredLevel then
					return false, "Invalid station recipe"
				end
			end
			if station.auto and (not station.recipeId or profile.discoveredRecipes[station.recipeId] ~= true) then
				return false, "Automation requires a discovered recipe"
			end
			local inputLimit = definition.defaultRecipe and config.machineInputCapacity or 0
			if not countMap(station.input, function(itemId)
				return config.items[itemId].kind ~= "potion"
			end, inputLimit) then
				return false, "Invalid machine input"
			end
			local outputLimit = definition.outputItem and config.sourceCapacity or config.machineOutputCapacity
			if not countMap(station.output, function(itemId)
				return definition.outputItem == itemId
					or (stationId == "distillery" and itemId == "fire_extract")
			end, outputLimit) then
				return false, "Invalid station output"
			end
			if station.level == 0 and (station.workerId or station.recipeId or station.job
				or station.auto or station.progress ~= 0 or total(station.input) > 0 or total(station.output) > 0) then
				return false, "Unbuilt station has active state"
			end
			local job = station.job
			if job ~= nil then
				if not plain(job) or not finite(job.duration) or job.duration < 1
					or job.duration > config.maxJobDuration or station.progress > job.duration then
					return false, "Invalid job timing"
				end
				if job.kind == "brew" then
					local recipe = config.recipes[job.recipeId]
					if not recipe or recipe.station ~= stationId or station.recipeId ~= job.recipeId
						or not finite(job.doubleChance) or job.doubleChance < 0 or job.doubleChance > 0.25 then
						return false, "Invalid brewing job"
					end
				elseif job.kind == "haul" then
					if stationId ~= "logistics" or type(job.itemId) ~= "string"
						or not config.items[job.itemId] or config.items[job.itemId].kind == "potion"
						or not integer(job.amount, 1, 16) then
						return false, "Invalid hauling cargo"
					end
					if job.sourceKind == "output" then
						if not config.stations[job.sourceStationId]
							or profile.stations[job.sourceStationId].level == 0
							or job.destinationKind ~= "inventory" then
							return false, "Invalid hauling source"
						end
					elseif job.sourceKind ~= "inventory" then
						return false, "Invalid hauling source"
					end
					if job.destinationKind == "input" then
						local target = config.stations[job.destinationStationId]
						if not target or not target.defaultRecipe
							or profile.stations[job.destinationStationId].level == 0
							or job.sourceKind ~= "inventory" then
							return false, "Invalid hauling destination"
						end
					elseif job.destinationKind ~= "inventory" then
						return false, "Invalid hauling destination"
					end
				else
					return false, "Unknown job"
				end
			end
		end
		if not countMap(profile.inventory, function(itemId)
			return config.items[itemId].kind ~= "potion"
		end, config.maxCount) or stored(profile, "raw") > capacity(profile, "raw")
			or stored(profile, "intermediate") > capacity(profile, "intermediate") then
			return false, "Invalid inventory or warehouse overflow"
		end
		if not countMap(profile.questStock, function(itemId)
			return config.items[itemId].kind == "potion"
		end, config.warehouse.questCapacity[profile.warehouseLevel + 1]) then
			return false, "Invalid order stock"
		end
		if profile.order ~= nil then
			local order = profile.order
			local definition = plain(order) and config.orders[order.id]
			if not definition or order.recipeId ~= definition.recipeId or order.itemId ~= definition.itemId
				or order.count ~= definition.count or order.rewardGold ~= definition.rewardGold
				or not integer(order.acceptedAt, 0, config.maxTimestamp)
				or not integer(order.expiresAt, 0, config.maxTimestamp)
				or order.expiresAt - order.acceptedAt ~= definition.duration
				or quantity(profile.questStock, order.itemId) > order.count then
				return false, "Invalid order"
			end
			for itemId, count in pairs(profile.questStock) do
				if count > 0 and itemId ~= order.itemId then
					return false, "Unexpected reserved order item"
				end
			end
		elseif total(profile.questStock) ~= 0 then
			return false, "Order stock without an order"
		end
		for _, stationId in ipairs({ "garden", "mine" }) do
			if not integer(profile.manualReadyAt[stationId], 0, config.maxTimestamp) then
				return false, "Invalid manual cooldown"
			end
		end
		for stationId in pairs(profile.manualReadyAt) do
			if stationId ~= "garden" and stationId ~= "mine" then
				return false, "Unknown manual cooldown"
			end
		end
		for petId, seconds in pairs(profile.slimeWorkSeconds) do
			if not profile.pets[petId] or not config.petSpecies[profile.pets[petId].species].slimeProducer
				or not integer(seconds, 0, config.slimePeriod - 1) then
				return false, "Invalid familiar timer"
			end
		end
		for recipeId, discovered in pairs(profile.discoveredRecipes) do
			if not config.recipes[recipeId] or discovered ~= true then
				return false, "Invalid recipe collection"
			end
		end
		for receiptId, recorded in pairs(profile.receipts) do
			if not identifier(receiptId, 128) or recorded ~= true then
				return false, "Invalid receipt history"
			end
		end
		for entitlementId, value in pairs(profile.entitlements) do
			if not identifier(entitlementId, 80) or (type(value) ~= "boolean" and not integer(value, 0, config.maxBalance)) then
				return false, "Invalid entitlement"
			end
		end
		return true, nil
	end

	function engine.newProfile(userId, now)
		assert(integer(userId, -9007199254740991, 9007199254740991), "Invalid user ID")
		assert(finite(now) and now >= 0 and now <= config.maxTimestamp, "Invalid timestamp")
		now = math.floor(now)
		local profile = {
			schemaVersion = config.schemaVersion, userId = userId, lastSimulatedAt = now,
			rngState = math.abs(userId) % (rngModulus - 1) + 1, gold = 0, essence = 0,
			pets = {}, nextPetSerial = 1, stations = {}, inventory = {}, questStock = {}, order = nil,
			rebirths = 0, discoveredRecipes = {}, tutorialGranted = true, receipts = {}, entitlements = {},
			warehouseLevel = 0, pipes = false, manualReadyAt = { garden = now, mine = now }, slimeWorkSeconds = {},
		}
		for _, definition in ipairs(config.starterPets) do
			local petId = string.format("%.0f", userId) .. ":" .. definition.id
			profile.pets[petId] = {
				id = petId, species = definition.species, name = definition.name, paidOrigin = false,
				stats = { Farming = definition.stats.Farming, Hauling = definition.stats.Hauling, Brewing = definition.stats.Brewing },
			}
		end
		for _, stationId in ipairs(config.stationOrder) do
			local definition = config.stations[stationId]
			profile.stations[stationId] = {
				level = definition.initialLevel, workerId = nil,
				recipeId = definition.initialLevel > 0 and definition.defaultRecipe or nil,
				auto = false, input = {}, output = {}, progress = 0, job = nil,
			}
			if stationId == "logistics" then profile.stations[stationId].routeCursor = 1 end
		end
		return profile
	end

	local function report()
		return { ok = true, elapsedSeconds = 0, processedSeconds = 0, skippedSeconds = 0,
			goldEarned = 0, essenceEarned = 0, produced = {}, sold = {}, orderReserved = {} }
	end

	local function earn(profile, field, amount, summary)
		local actual = math.min(amount, config.maxBalance - profile[field])
		profile[field] = profile[field] + actual
		summary[field .. "Earned"] = summary[field .. "Earned"] + actual
	end

	local function sell(profile, recipe, count, summary)
		if count > 0 then
			earn(profile, "gold", count * recipe.goldValue, summary)
			change(summary.sold, recipe.output, count)
		end
	end

	local function dispatch(profile, recipe, count, summary)
		local reserved = 0
		local order = profile.order
		if order and order.itemId == recipe.output then
			reserved = math.min(count, order.count - quantity(profile.questStock, recipe.output),
				config.warehouse.questCapacity[profile.warehouseLevel + 1] - total(profile.questStock))
			if reserved > 0 then
				change(profile.questStock, recipe.output, reserved)
				change(summary.orderReserved, recipe.output, reserved)
			end
		end
		sell(profile, recipe, count - reserved, summary)
	end

	local function expireOrder(profile, now, summary)
		if profile.order and profile.order.expiresAt <= now then
			local recipe = config.recipes[profile.order.recipeId]
			sell(profile, recipe, quantity(profile.questStock, profile.order.itemId), summary)
			profile.questStock = {}
			profile.order = nil
		end
	end

	local function startBrew(profile, stationId)
		local station = profile.stations[stationId]
		local recipe = station.recipeId and config.recipes[station.recipeId]
		if not recipe or station.level < recipe.requiredLevel or station.job then
			return false, "Machine unavailable"
		end
		if profile.essence < recipe.essenceCost then
			return false, "Not enough essence"
		end
		if recipe.kind == "intermediate" and total(station.output) + recipe.quantity * 2 > config.machineOutputCapacity then
			return false, "Output tray is full"
		end
		for itemId, count in pairs(recipe.inputs) do
			if quantity(station.input, itemId) < count then
				return false, "Load the required ingredients"
			end
		end
		for itemId, count in pairs(recipe.inputs) do
			change(station.input, itemId, -count)
		end
		profile.essence = profile.essence - recipe.essenceCost
		local skill = effectiveSkill(profile, stationId)
		station.job = { kind = "brew", recipeId = station.recipeId,
			duration = math.max(1, recipe.duration / (1 + skill * 0.035)),
			doubleChance = math.min(0.25, skill * 0.002) }
		station.progress = 0
		return true, "Brewing started"
	end

	local function loadInputs(profile, stationId, fluidOnly)
		local station = profile.stations[stationId]
		local recipe = station.recipeId and config.recipes[station.recipeId]
		if not recipe then
			return 0
		end
		local moved = 0
		for _, itemId in ipairs(itemIds) do
			local needed = (recipe.inputs[itemId] or 0) - quantity(station.input, itemId)
			if needed > 0 and (not fluidOnly or config.items[itemId].fluid) then
				local amount = math.min(needed, quantity(profile.inventory, itemId), config.machineInputCapacity - total(station.input))
				if amount > 0 then
					change(profile.inventory, itemId, -amount)
					change(station.input, itemId, amount)
					moved = moved + amount
				end
			end
		end
		return moved
	end

	local function collectOutput(profile, stationId, fluidOnly)
		local station = profile.stations[stationId]
		local moved = 0
		for _, itemId in ipairs(itemIds) do
			if not fluidOnly or config.items[itemId].fluid then
				local count = quantity(station.output, itemId)
				if count > 0 then
					local amount = math.min(count, inventoryRoom(profile, itemId))
					if amount > 0 then
						change(station.output, itemId, -amount)
						change(profile.inventory, itemId, amount)
						moved = moved + amount
					end
				end
			end
		end
		return moved
	end

	local function beginHaul(profile)
		local station = profile.stations.logistics
		local skill = effectiveSkill(profile, "logistics")
		local limit = math.min(16, 1 + math.floor(skill / 5))
		local duration = math.max(1, config.baseHaulDuration / (1 + skill * 0.025))
		for offset = 0, routeCount - 1 do
			local routeIndex = (station.routeCursor - 1 + offset) % routeCount + 1
			if routeIndex <= #config.machineOrder then
				local targetId = config.machineOrder[routeIndex]
				local target = profile.stations[targetId]
				local recipe = target.recipeId and config.recipes[target.recipeId]
				if recipe and target.level > 0 then
					for _, itemId in ipairs(itemIds) do
						local needed = (recipe.inputs[itemId] or 0) - quantity(target.input, itemId)
						if needed > 0 and not (profile.pipes and config.items[itemId].fluid) then
							local amount = math.min(limit, needed, quantity(profile.inventory, itemId), config.machineInputCapacity - total(target.input))
							if amount > 0 then
								change(profile.inventory, itemId, -amount)
								station.job = { kind = "haul", itemId = itemId, amount = amount, sourceKind = "inventory",
									destinationKind = "input", destinationStationId = targetId, duration = duration }
								station.progress = 0
								station.routeCursor = routeIndex % routeCount + 1
								return
							end
						end
					end
				end
			else
				local sourceId = config.sourceOrder[routeIndex - #config.machineOrder]
				local source = profile.stations[sourceId]
				for _, itemId in ipairs(itemIds) do
					if not (profile.pipes and config.items[itemId].fluid) then
						local amount = math.min(limit, quantity(source.output, itemId), inventoryRoom(profile, itemId))
						if amount > 0 then
							change(source.output, itemId, -amount)
							station.job = { kind = "haul", itemId = itemId, amount = amount, sourceKind = "output", sourceStationId = sourceId,
								destinationKind = "inventory", duration = duration }
							station.progress = 0
							station.routeCursor = routeIndex % routeCount + 1
							return
						end
					end
				end
			end
		end
	end

	local function tickHauler(profile)
		local station = profile.stations.logistics
		if station.level == 0 or not station.workerId then
			return
		end
		local job = station.job
		if not job then
			beginHaul(profile)
			return
		end
		station.progress = math.min(job.duration, station.progress + 1)
		if station.progress < job.duration then
			return
		end
		local destination, room
		if job.destinationKind == "inventory" then
			destination = profile.inventory
			room = inventoryRoom(profile, job.itemId)
		else
			destination = profile.stations[job.destinationStationId].input
			room = config.machineInputCapacity - total(destination)
		end
		local amount = math.min(job.amount, room)
		if amount > 0 then
			change(destination, job.itemId, amount)
			job.amount = job.amount - amount
		end
		if job.amount == 0 then
			station.job = nil
			station.progress = 0
		end
	end

	local function tick(profile, now, summary, petIds)
		expireOrder(profile, now, summary)
		local crystal = profile.stations.crystal
		if crystal.level > 0 then
			local gain = config.stations.crystal.passiveEssence[crystal.level]
			if crystal.workerId then
				gain = gain + math.max(1, math.floor(effectiveSkill(profile, "crystal") / 5))
			end
			earn(profile, "essence", gain, summary)
		end
		local deployed = {}
		for _, stationId in ipairs(config.stationOrder) do
			local station = profile.stations[stationId]
			if station.workerId then
				deployed[station.workerId] = true
			end
			local definition = config.stations[stationId]
			if definition.outputItem and station.workerId and total(station.output) < config.sourceCapacity then
				local duration = math.max(1, definition.growDuration / (1 + effectiveSkill(profile, stationId) * 0.04))
				station.progress = station.progress + 1
				if station.progress >= duration then
					station.progress = 0
					change(station.output, definition.outputItem, 1)
					change(summary.produced, definition.outputItem, 1)
				end
			end
		end
		for _, petId in ipairs(petIds) do
			if deployed[petId] and config.petSpecies[profile.pets[petId].species].slimeProducer then
				local seconds = (profile.slimeWorkSeconds[petId] or 0) + 1
				if seconds >= config.slimePeriod then
					seconds = 0
					if nextRandom(profile) < config.slimeChance and inventoryRoom(profile, "slime") > 0 then
						change(profile.inventory, "slime", 1)
						change(summary.produced, "slime", 1)
					end
				end
				profile.slimeWorkSeconds[petId] = seconds
			end
		end
		if profile.pipes then
			for _, stationId in ipairs(config.machineOrder) do
				collectOutput(profile, stationId, true)
			end
			for _, stationId in ipairs(config.machineOrder) do
				loadInputs(profile, stationId, true)
			end
		end
		tickHauler(profile)
		for _, stationId in ipairs(config.machineOrder) do
			local station = profile.stations[stationId]
			local job = station.job
			if job then
				station.progress = math.min(job.duration, station.progress + 1)
				if station.progress >= job.duration then
					local recipe = config.recipes[job.recipeId]
					local produced = recipe.quantity
					if nextRandom(profile) < job.doubleChance then
						produced = produced * 2
					end
					change(summary.produced, recipe.output, produced)
					profile.discoveredRecipes[job.recipeId] = true
					if recipe.kind == "potion" then
						dispatch(profile, recipe, produced, summary)
					else
						change(station.output, recipe.output, produced)
					end
					station.job = nil
					station.progress = 0
				end
			end
			if not station.job and station.auto and station.workerId then
				startBrew(profile, stationId)
			end
		end
	end

	function engine.advance(profile, now, isOffline)
		local summary = report()
		local valid, reason = engine.validate(profile)
		if not valid or not finite(now) or now < 0 or now > config.maxTimestamp
			or (isOffline ~= nil and type(isOffline) ~= "boolean") then
			summary.ok = false
			summary.error = reason or "Invalid simulation arguments"
			return summary
		end
		now = math.floor(now)
		if now < profile.lastSimulatedAt then
			summary.ok = false
			summary.error = "Clock moved backwards"
			return summary
		end
		local elapsed = now - profile.lastSimulatedAt
		local limit = isOffline and config.maxOfflineSeconds or config.maxAdvanceSeconds
		local seconds = math.min(elapsed, limit)
		summary.elapsedSeconds, summary.processedSeconds, summary.skippedSeconds = elapsed, seconds, elapsed - seconds
		local petIds = keys(profile.pets)
		for offset = 1, seconds do
			tick(profile, profile.lastSimulatedAt + offset, summary, petIds)
		end
		-- The unprocessed tail is deliberately consumed; rejoining cannot reclaim a second cap.
		profile.lastSimulatedAt = now
		expireOrder(profile, now, summary)
		return summary
	end

	local payloadFields = {
		click = {}, assign = { stationId = true, petId = true }, harvest = { stationId = true },
		collect = { stationId = true }, load = { stationId = true }, brew = { stationId = true },
		setRecipe = { stationId = true, recipeId = true }, setAuto = { stationId = true, enabled = true },
		buy = { upgradeId = true }, hire = { speciesId = true }, acceptOrder = { orderId = true }, claimOrder = {},
		discard = { itemId = true, amount = true },
	}

	local function checkPayload(action, payload)
		local fields = type(action) == "string" and payloadFields[action]
		if not fields or not plain(payload) then
			return false
		end
		for key in pairs(payload) do
			if not fields[key] then
				return false
			end
		end
		for key in pairs(fields) do
			if key == "enabled" then
				if type(payload[key]) ~= "boolean" then return false end
			elseif key == "amount" then
				if not integer(payload[key], 1, config.maxCount) then return false end
			elseif type(payload[key]) ~= "string" or #payload[key] > 80 then
				return false
			end
		end
		if fields.stationId and not config.stations[payload.stationId] then return false end
		if fields.recipeId and not config.recipes[payload.recipeId] then return false end
		if fields.orderId and not config.orders[payload.orderId] then return false end
		if fields.speciesId and not config.hires[payload.speciesId] then return false end
		if fields.itemId and (not config.items[payload.itemId] or config.items[payload.itemId].kind == "potion") then return false end
		if fields.upgradeId and payload.upgradeId ~= "warehouse" and payload.upgradeId ~= "pipes"
			and not config.stations[payload.upgradeId] then return false end
		return true
	end

	function engine.act(profile, action, payload, now)
		if not checkPayload(action, payload) then
			return false, "Invalid action payload"
		end
		local valid, reason = engine.validate(profile)
		if not valid then return false, reason end
		if action == "assign" and payload.petId ~= "" and not profile.pets[payload.petId] then
			return false, "Unknown familiar"
		end
		local summary = engine.advance(profile, now, false)
		if not summary.ok then return false, summary.error end
		local stationId = payload.stationId
		local station = stationId and profile.stations[stationId]
		if station and station.level == 0 then return false, "Build this station first" end
		if action == "click" then
			if profile.essence >= config.maxBalance then return false, "Essence limit reached" end
			profile.essence = profile.essence + 1
			return true, "+1 essence"
		elseif action == "assign" then
			if payload.petId ~= "" then
				for otherId, other in pairs(profile.stations) do
					if otherId ~= stationId and other.workerId == payload.petId then
						return false, "Familiar already has a workplace"
					end
				end
			end
			station.workerId = payload.petId ~= "" and payload.petId or nil
			return true, "Assignment updated"
		elseif action == "harvest" then
			local itemId = config.stations[stationId].outputItem
			if not itemId then return false, "Not a gathering station" end
			local timestamp = math.floor(now)
			if timestamp > config.maxTimestamp - config.manualHarvestCooldown then return false, "Timestamp limit reached" end
			if timestamp < profile.manualReadyAt[stationId] then return false, "Gathering is on cooldown" end
			if inventoryRoom(profile, itemId) < 1 then return false, "Raw storage is full" end
			change(profile.inventory, itemId, 1)
			profile.manualReadyAt[stationId] = timestamp + config.manualHarvestCooldown
			return true, "Ingredient gathered"
		elseif action == "collect" then
			if collectOutput(profile, stationId, false) == 0 then return false, "Nothing to collect or storage is full" end
			return true, "Output collected"
		elseif action == "load" then
			if loadInputs(profile, stationId, false) == 0 then return false, "No ingredients to load" end
			return true, "Ingredients loaded"
		elseif action == "brew" then
			return startBrew(profile, stationId)
		elseif action == "setRecipe" then
			local recipe = config.recipes[payload.recipeId]
			if recipe.station ~= stationId or station.level < recipe.requiredLevel then return false, "Recipe is locked here" end
			if station.job then return false, "Finish the current batch first" end
			for _, kind in ipairs({ "raw", "intermediate" }) do
				local toReturn = 0
				for itemId, count in pairs(station.input) do
					if config.items[itemId].kind == kind then toReturn = toReturn + count end
				end
				if stored(profile, kind) + toReturn > capacity(profile, kind) then return false, "Make room to return loaded ingredients" end
			end
			for itemId, count in pairs(station.input) do change(profile.inventory, itemId, count) end
			station.input, station.recipeId = {}, payload.recipeId
			if not profile.discoveredRecipes[payload.recipeId] then station.auto = false end
			return true, "Recipe selected"
		elseif action == "setAuto" then
			if not config.stations[stationId].defaultRecipe then return false, "Not a brewing machine" end
			if payload.enabled and not station.workerId then return false, "Assign a brewer first" end
			if payload.enabled and not profile.discoveredRecipes[station.recipeId] then return false, "Brew this recipe manually once first" end
			station.auto = payload.enabled
			return true, "Automation updated"
		elseif action == "discard" then
			if quantity(profile.inventory, payload.itemId) < payload.amount then return false, "Not enough owned ingredients" end
			change(profile.inventory, payload.itemId, -payload.amount)
			return true, "Ingredients discarded"
		elseif action == "hire" then
			local definition = config.hires[payload.speciesId]
			if #keys(profile.pets) >= config.maxPets then return false, "Familiar inventory is full" end
			if profile.nextPetSerial >= config.maxCount then return false, "Familiar serial limit reached" end
			local petId = string.format("%.0f", profile.userId) .. ":hire:" .. profile.nextPetSerial
			if profile.pets[petId] then return false, "Familiar identity already exists" end
			if profile.gold < definition.cost then return false, "Not enough gold" end
			profile.gold = profile.gold - definition.cost
			profile.pets[petId] = { id = petId, species = payload.speciesId, name = definition.name, paidOrigin = false,
				stats = { Farming = definition.stats.Farming, Hauling = definition.stats.Hauling, Brewing = definition.stats.Brewing } }
			profile.nextPetSerial = profile.nextPetSerial + 1
			return true, "Familiar hired"
		elseif action == "buy" then
			local upgradeId, cost = payload.upgradeId, nil
			if upgradeId == "pipes" then
				if profile.pipes then return false, "Pipes already purchased" end
				cost = config.pipesCost
			elseif upgradeId == "warehouse" then
				cost = config.warehouse.upgradeCosts[profile.warehouseLevel + 1]
			else
				cost = config.stations[upgradeId].upgradeCosts[profile.stations[upgradeId].level + 1]
			end
			if not cost then return false, "Maximum upgrade reached" end
			if profile.gold < cost then return false, "Not enough gold" end
			profile.gold = profile.gold - cost
			if upgradeId == "pipes" then
				profile.pipes = true
			elseif upgradeId == "warehouse" then
				profile.warehouseLevel = profile.warehouseLevel + 1
			else
				local target = profile.stations[upgradeId]
				target.level = target.level + 1
				if not target.recipeId then target.recipeId = config.stations[upgradeId].defaultRecipe end
			end
			return true, "Upgrade purchased"
		elseif action == "acceptOrder" then
			if profile.order then return false, "An order is already active" end
			local definition = config.orders[payload.orderId]
			if math.floor(now) > config.maxTimestamp - definition.duration then return false, "Timestamp limit reached" end
			local recipe = config.recipes[definition.recipeId]
			if profile.stations[recipe.station].level < recipe.requiredLevel then return false, "Unlock the recipe first" end
			if definition.count > config.warehouse.questCapacity[profile.warehouseLevel + 1] then return false, "Upgrade order storage first" end
			profile.order = { id = payload.orderId, recipeId = definition.recipeId, itemId = definition.itemId,
				count = definition.count, rewardGold = definition.rewardGold,
				acceptedAt = math.floor(now), expiresAt = math.floor(now) + definition.duration }
			return true, "Order accepted"
		elseif action == "claimOrder" then
			local order = profile.order
			if not order or quantity(profile.questStock, order.itemId) < order.count then return false, "Order is not ready" end
			change(profile.questStock, order.itemId, -order.count)
			profile.gold = math.min(config.maxBalance, profile.gold + order.rewardGold)
			profile.order = nil
			return true, "Order delivered"
		end
		return false, "Unknown action"
	end

	return engine
end

return Factory
