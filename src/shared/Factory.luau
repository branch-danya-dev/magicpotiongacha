-- Deterministic, server-owned factory simulation. No Roblox services or clocks are used here.
local runtimeScript = rawget(getfenv(), "script")
local Familiars = require(runtimeScript and runtimeScript.Parent.Familiars or "./Familiars")
local LegacyConfig = require(runtimeScript and runtimeScript.Parent.LegacyConfig or "./LegacyConfig")
local Progression = require(runtimeScript and runtimeScript.Parent.Progression or "./Progression")
local Trading = require(runtimeScript and runtimeScript.Parent.Trading or "./Trading")
local Epochs = require(runtimeScript and runtimeScript.Parent.Epochs or "./Epochs")
local Dailies = require(runtimeScript and runtimeScript.Parent.Dailies or "./Dailies")
local LongTerm = require(runtimeScript and runtimeScript.Parent.LongTerm or "./LongTerm")
local Factory = {}
local function compatible(rules, slotId, recipe)
	local def = rules.stations[slotId]
	return def and recipe and (def.archetype or slotId) == recipe.station
end

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
	local familiars = Familiars.new(config)
	local progression = Progression.new(config)
	local longTerm = LongTerm.new(config)
	local itemIds = keys(config.items)
	local skills = { "Farming", "Hauling", "Brewing" }
	local rngModulus = 2147483647
	local routeCount = #config.routes

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

	local function inventoryRoom(profile, itemId, inFlight)
		local kind = config.items[itemId].kind
		local room = math.max(0, capacity(profile, kind) - stored(profile, kind))
		-- Laboratory intake leaves a share for every material. Existing stock/cargo
		-- is never deleted or trapped by a newly activated share limit.
		if not inFlight and profile.phase and profile.phase >= config.balancedStoragePhase then
			local types = 0; for _, item in pairs(config.items) do if item.kind == kind and Epochs.available(config,profile,item) then types += 1 end end
			room = math.min(room, math.max(0, math.floor(capacity(profile,kind)/types) - quantity(profile.inventory,itemId)))
		end
		return room
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

	-- A source pickup must not always feed the first downstream route. Persist a
	-- turn per material so competing machines share even a one-item supply stream.
	local function preferredInput(profile, itemId)
		local start = profile.inputCursors[itemId] or 1
		for offset=0,#config.machineOrder-1 do
			local index=(start-1+offset)%#config.machineOrder+1
			local slotId=config.machineOrder[index]; local station=profile.stations[slotId]
			local recipe=station.recipeId and config.recipes[station.recipeId]
			if station.level>0 and recipe and (recipe.inputs[itemId] or 0)>quantity(station.input,itemId)
				and total(station.input)<config.machineInputCapacity then return slotId,index end
		end
		return nil,nil
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

	local function validate(profile, version)
		local legacy = version == 1
		local modern = not version or version >= 4
		local cfg = not modern and LegacyConfig or config
		local function checkCounts(value, predicate, maximum)
			return countMap(value, function(item)
				return cfg.items[item] ~= nil and (version and not cfg.items[item].epoch or not version and Epochs.available(config,profile,cfg.items[item])) and predicate(item)
			end, maximum)
		end
		if not plain(profile) or profile.schemaVersion ~= (version or cfg.schemaVersion) then
			return false, "Unsupported profile schema"
		end
		if modern and not integer(profile.phase, 1, 4) then return false, "Invalid construction phase" end
		if not integer(profile.userId, -9007199254740991, 9007199254740991)
			or not integer(profile.lastSimulatedAt, 0, cfg.maxTimestamp)
			or not integer(profile.rngState, 1, rngModulus - 1)
			or not integer(profile.gold, 0, cfg.maxBalance)
			or not integer(profile.essence, 0, cfg.maxBalance)
			or not integer(profile.rebirths, 0, cfg.maxCount)
			or not integer(profile.nextPetSerial, 1, cfg.maxCount)
			or not integer(profile.warehouseLevel, 0, #cfg.warehouse.upgradeCosts)
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
				or type(pet.species) ~= "string" or not cfg.petSpecies[pet.species]
				or not identifier(pet.name, 80) or type(pet.paidOrigin) ~= "boolean"
				or not plain(pet.stats) then
				return false, "Invalid pet"
			end
			if version and version < 3 and pet.species ~= "farmer" and pet.species ~= "slime" and pet.species ~= "brewer" then return false, "Unknown legacy species" end
			for _, skill in ipairs(skills) do
				if not integer(pet.stats[skill], 0, cfg.maxBaseStat) then
					return false, "Invalid pet stat"
				end
			end
			for skill in pairs(pet.stats) do
				if skill ~= "Farming" and skill ~= "Hauling" and skill ~= "Brewing" then
					return false, "Unknown pet stat"
				end
			end
			if (modern or version == 3) and not familiars.validatePet(pet) then return false, "Invalid familiar metadata or range" end
		end
		if petCount > cfg.maxPets then
			return false, "Pet capacity exceeded"
		end
		local assigned = {}
		for stationId in pairs(profile.stations) do
			if not cfg.stations[stationId] then
				return false, "Unknown station"
			end
		end
		for _, stationId in ipairs(cfg.stationOrder) do
			local station = profile.stations[stationId]
			local definition = cfg.stations[stationId]
			if not plain(station) or not integer(station.level, 0, #definition.upgradeCosts)
				or type(station.auto) ~= "boolean" or not finite(station.progress)
				or station.progress < 0 or station.progress > cfg.maxJobDuration then
				return false, "Invalid station"
			end
			if stationId == "logistics" and not integer(station.routeCursor, 1, not modern and (legacy and 5 or 7) or routeCount) then
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
				local recipe = cfg.recipes[station.recipeId]
				if not recipe or (version and recipe.epoch) or (not version and not Epochs.available(config,profile,recipe)) or not compatible(cfg, stationId, recipe) or station.level < recipe.requiredLevel or (modern and profile.phase < (recipe.phase or 1)) then
					return false, "Invalid station recipe"
				end
			end
			if station.auto and (not station.recipeId or profile.discoveredRecipes[station.recipeId] ~= true) then
				return false, "Automation requires a discovered recipe"
			end
			local inputLimit = definition.defaultRecipe and cfg.machineInputCapacity or 0
			if not checkCounts(station.input, function(itemId)
				return cfg.items[itemId].kind ~= "potion"
			end, inputLimit) then
				return false, "Invalid machine input"
			end
			local outputLimit = definition.outputItem and cfg.sourceCapacity or cfg.machineOutputCapacity
			if not checkCounts(station.output, function(itemId)
				return definition.outputItem == itemId
					or (definition.defaultRecipe and cfg.items[itemId].kind == "intermediate" and cfg.recipes[itemId]
						and compatible(cfg, stationId, cfg.recipes[itemId]))
			end, outputLimit) then
				return false, "Invalid station output"
			end
			if station.level == 0 and (station.workerId or station.recipeId or station.job
				or station.auto or station.progress ~= 0 or total(station.input) > 0 or total(station.output) > 0) then
				return false, "Unbuilt station has active state"
			end
			if not legacy then
				local essenceLimit = definition.defaultRecipe and station.level > 0 and cfg.essenceBufferCapacity or 0
				if not integer(station.essence, 0, essenceLimit) or not checkCounts(station.questQueue, function(itemId)
					return cfg.items[itemId].kind == "potion" and cfg.recipes[itemId] ~= nil and compatible(cfg, stationId, cfg.recipes[itemId])
				end, station.level > 0 and cfg.questQueueCapacity or 0) then return false, "Invalid machine tank or crate queue" end
			end
			local job = station.job
			if job ~= nil then
				if not plain(job) or not finite(job.duration) or job.duration < 1
					or job.duration > cfg.maxJobDuration or station.progress > job.duration then
					return false, "Invalid job timing"
				end
				if job.kind == "brew" then
					local recipe = cfg.recipes[job.recipeId]
					if not recipe or not compatible(cfg, stationId, recipe) or station.recipeId ~= job.recipeId
						or not finite(job.doubleChance) or job.doubleChance < 0 or job.doubleChance > (legacy and 0.25 or cfg.maxDoubleChance)
						or (not legacy and type(job.automatic) ~= "boolean") then
						return false, "Invalid brewing job"
					end
				elseif job.kind == "haul" then
					if stationId ~= "logistics" or type(job.itemId) ~= "string"
						or not cfg.items[job.itemId] or (legacy and cfg.items[job.itemId].kind == "potion")
						or (version and cfg.items[job.itemId].epoch) or (not version and not Epochs.available(config,profile,cfg.items[job.itemId]))
						or not integer(job.amount, 1, cfg.maxHaulCapacity) then
						return false, "Invalid hauling cargo"
					end
					if not legacy and cfg.items[job.itemId].kind == "potion" then
						if job.sourceKind ~= "questQueue" or job.destinationKind ~= "questStock"
							or not cfg.stations[job.sourceStationId] or not cfg.stations[job.sourceStationId].defaultRecipe
							or not cfg.recipes[job.itemId] or not compatible(cfg, job.sourceStationId, cfg.recipes[job.itemId])
							or profile.stations[job.sourceStationId].level == 0 then return false, "Invalid crate route" end
					elseif job.sourceKind == "output" then
						if not cfg.stations[job.sourceStationId]
							or profile.stations[job.sourceStationId].level == 0
							or job.destinationKind ~= "inventory" then
							return false, "Invalid hauling source"
						end
					elseif job.sourceKind ~= "inventory" then
						return false, "Invalid hauling source"
					end
					if not legacy and job.destinationKind == "questStock" then
						if cfg.items[job.itemId].kind ~= "potion" then return false, "Invalid crate item" end
					elseif job.destinationKind == "input" then
						local target = cfg.stations[job.destinationStationId]
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
		if not checkCounts(profile.inventory, function(itemId)
			return cfg.items[itemId].kind ~= "potion"
		end, cfg.maxCount) or stored(profile, "raw") > capacity(profile, "raw")
			or stored(profile, "intermediate") > capacity(profile, "intermediate") then
			return false, "Invalid inventory or warehouse overflow"
		end
		if not checkCounts(profile.questStock, function(itemId)
			return cfg.items[itemId].kind == "potion"
		end, cfg.warehouse.questCapacity[profile.warehouseLevel + 1]) then
			return false, "Invalid order stock"
		end
		local reserved = {}
		for itemId, count in pairs(profile.questStock) do change(reserved, itemId, count) end
		if not legacy then
			for _, station in pairs(profile.stations) do
				for itemId, count in pairs(station.questQueue) do change(reserved, itemId, count) end
			end
			local cargo = profile.stations.logistics.job
			if cargo and cargo.destinationKind == "questStock" then change(reserved, cargo.itemId, cargo.amount) end
		end
		if profile.order ~= nil then
			local order = profile.order
			local definition = plain(order) and cfg.orders[order.id]
			if not definition or (version and definition.epoch) or (not version and not Epochs.available(config,profile,definition)) or order.recipeId ~= definition.recipeId or order.itemId ~= definition.itemId
				or (modern and definition.phase and (profile.phase < definition.phase or not profile.discoveredRecipes[definition.recipeId]))
				or order.count ~= definition.count or order.rewardGold ~= definition.rewardGold
				or not integer(order.acceptedAt, 0, cfg.maxTimestamp)
				or not integer(order.expiresAt, 0, cfg.maxTimestamp)
				or order.expiresAt - order.acceptedAt ~= definition.duration
				or quantity(reserved, order.itemId) > order.count then
				return false, "Invalid order"
			end
			for itemId, count in pairs(reserved) do
				if count > 0 and itemId ~= order.itemId then
					return false, "Unexpected reserved order item"
				end
			end
		elseif total(reserved) ~= 0 then
			return false, "Order stock without an order"
		end
		for _, stationId in ipairs(cfg.stationOrder) do
			if cfg.stations[stationId].outputItem and not integer(profile.manualReadyAt[stationId], 0, cfg.maxTimestamp) then
				return false, "Invalid manual cooldown"
			end
		end
		for stationId in pairs(profile.manualReadyAt) do
			if not cfg.stations[stationId] or not cfg.stations[stationId].outputItem then
				return false, "Unknown manual cooldown"
			end
		end
		for petId, seconds in pairs(profile.slimeWorkSeconds) do
			if not profile.pets[petId] or not cfg.petSpecies[profile.pets[petId].species].slimeProducer
				or not integer(seconds, 0, cfg.slimePeriod - 1) then
				return false, "Invalid familiar timer"
			end
		end
		for recipeId, discovered in pairs(profile.discoveredRecipes) do
			if not cfg.recipes[recipeId] or discovered ~= true or (version and cfg.recipes[recipeId].epoch)
				or (modern and (version or profile.rebirths==0) and (profile.phase < (cfg.recipes[recipeId].phase or 1) or cfg.recipes[recipeId].epoch~=nil)) then
				return false, "Invalid recipe collection"
			end
		end
		for receiptId, recorded in pairs(profile.receipts) do
			if not identifier(receiptId, 128) or recorded ~= true then
				return false, "Invalid receipt history"
			end
		end
		for entitlementId, value in pairs(profile.entitlements) do
			if not identifier(entitlementId, 80) or (type(value) ~= "boolean" and not integer(value, 0, cfg.maxBalance)) then
				return false, "Invalid entitlement"
			end
		end
		if not legacy then
			if not integer(profile.pipeCursor, 1, #cfg.machineOrder) or not plain(profile.tutorial)
				or not plain(profile.telemetry) or not plain(profile.telemetry.first)
				or not plain(profile.telemetry.stalls) then return false, "Invalid M1 progress" end
			local milestones = {}
			for _, id in ipairs(cfg.tutorialSteps) do milestones[id] = true end
			for id, done in pairs(profile.tutorial) do
				if not milestones[id] or done ~= true then return false, "Invalid tutorial milestone" end
			end
			for id, time in pairs(profile.telemetry.first) do
				if not ({ manual_brew = true, auto_brew = true, upgrade = true, contract = true, tutorial = true })[id]
					or not integer(time, 0, cfg.maxTimestamp) then return false, "Invalid diagnostic event" end
			end
			for stationId, reasons in pairs(profile.telemetry.stalls) do
				if not cfg.stations[stationId] or not plain(reasons) then return false, "Invalid stall station" end
				for reason, seconds in pairs(reasons) do
					if not ({ unbuilt = true, no_master = true, no_hauler = true, waiting_essence = true,
						waiting_ingredient = true, queue_full = true, manual_first = true,
						recipe_unavailable = true, no_path = true, manual_mode = true, idle = true })[reason]
						or not integer(seconds, 0, cfg.maxBalance) then return false, "Invalid stall counter" end
				end
			end
		end
		if (modern or version == 3) and not familiars.validateProgress(profile) then return false, "Invalid collection receipt or provenance" end
		if modern then
			if not plain(profile.inputCursors) then return false, "Invalid input fairness cursors" end
			for itemId,cursor in pairs(profile.inputCursors) do
				if not cfg.items[itemId] or cfg.items[itemId].kind=="potion" or (version and cfg.items[itemId].epoch)
					or (not version and not Epochs.available(config,profile,cfg.items[itemId])) or not integer(cursor,1,#cfg.machineOrder) then return false,"Invalid input fairness cursor" end
			end
			if not progression.validate(profile) then return false, "Invalid phase/equipment state" end
		end
		if (not version or version==5) and not Trading.validateProfile(profile,config.maxBalance) then return false,"Invalid trade reservation/receipt" end
		if not version and not longTerm.validate(profile) then return false,"Invalid long-term progression" end
		return true, nil
	end

	function engine.validate(profile) return validate(profile, nil) end

	local function copy(value)
		if type(value) ~= "table" then return value end
		local result = {}
		for key, child in pairs(value) do result[key] = copy(child) end
		return result
	end

	-- ProfileStore supplies a serializable isolated copy; this migration is pure.
	function engine.migrate(profile)
		if plain(profile) and profile.schemaVersion == config.schemaVersion then
			local valid, reason = engine.validate(profile)
			return valid and profile or nil, reason
		end
		if not plain(profile) or (profile.schemaVersion ~= 1 and profile.schemaVersion ~= 2 and profile.schemaVersion ~= 3 and profile.schemaVersion ~= 4 and profile.schemaVersion ~= 5) then return nil, "Unsupported profile schema" end
		local version = profile.schemaVersion
		if profile.longTerm~=nil then return nil,"Unexpected historical long-term state" end
		if version<5 and profile.trade~=nil then return nil,"Unexpected historical trading state" end
		if version>=4 then
			local valid,reason=validate(profile,version); if not valid then return nil,reason end
			local migrated=copy(profile); migrated.schemaVersion=config.schemaVersion
			if version<5 then migrated.trade={sequence=0} end
			migrated.longTerm=longTerm.initial(migrated)
			valid,reason=engine.validate(migrated); return valid and migrated or nil,reason
		end
		if profile.phase ~= nil or profile.progression ~= nil or profile.cauldrons ~= nil or profile.nextCauldronSerial ~= nil or profile.inputCursors ~= nil then return nil, "Unexpected future progression fields" end
		local valid, reason = validate(profile, version)
		if not valid then return nil, reason end
		local migrated = copy(profile)
		if version == 1 then
			migrated.pipeCursor = 1
			migrated.tutorial, migrated.telemetry = {}, { first = {}, stalls = {} }
			for _, station in pairs(migrated.stations) do
				station.essence, station.questQueue = 0, {}
				if station.job and station.job.kind == "brew" then station.job.automatic = station.auto end
			end
			if migrated.discoveredRecipes.healing then migrated.tutorial.manual = true end
			if migrated.pipes then migrated.tutorial.pipes = true end
			if migrated.stations.crystal.level >= 2 then migrated.tutorial.upgrade = true end
			if migrated.order then migrated.tutorial.orderAccepted = true end
		end
		migrated.schemaVersion = config.schemaVersion
		migrated.trade = {sequence=0}
		if version < 3 then
			migrated.collection, migrated.currencyPaid = { sequence = 0 }, { gold = false, essence = false }
			for _, pet in pairs(migrated.pets) do familiars.upgradeLegacy(pet) end
		end
		migrated.phase, migrated.progression, migrated.cauldrons, migrated.nextCauldronSerial = 1, {sequence=0}, {}, 1
		migrated.inputCursors = {}
		for _, id in ipairs(config.stationOrder) do
			if not migrated.stations[id] then
				migrated.stations[id] = {level=0,auto=false,progress=0,input={},output={},essence=0,questQueue={}}
				if config.stations[id].outputItem then migrated.manualReadyAt[id] = migrated.lastSimulatedAt end
			end
		end
		migrated.longTerm=longTerm.initial(migrated)
		valid, reason = engine.validate(migrated)
		return valid and migrated or nil, reason
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
			collection = { sequence = 0 }, currencyPaid = { gold = false, essence = false },
			trade = {sequence=0},
			phase = 1, progression = {sequence=0}, cauldrons = {}, nextCauldronSerial = 1, inputCursors = {},
			pipeCursor = 1, tutorial = {}, telemetry = { first = {}, stalls = {} },
			warehouseLevel = 0, pipes = false, manualReadyAt = { garden = now, mine = now }, slimeWorkSeconds = {},
		}
		for _, definition in ipairs(config.starterPets) do
			local petId = string.format("%.0f", userId) .. ":" .. definition.id
			profile.pets[petId] = familiars.create(petId, definition.species, definition.stats, "starter", false)
		end
		for _, stationId in ipairs(config.stationOrder) do
			local definition = config.stations[stationId]
			if definition.outputItem then profile.manualReadyAt[stationId] = now end
			profile.stations[stationId] = {
				level = definition.initialLevel, workerId = nil,
				recipeId = definition.initialLevel > 0 and definition.defaultRecipe or nil,
				auto = false, input = {}, output = {}, essence = 0, questQueue = {}, progress = 0, job = nil,
			}
			if stationId == "logistics" then profile.stations[stationId].routeCursor = 1 end
		end
		profile.longTerm=longTerm.initial(profile)
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

	local function event(profile, id, now)
		if not profile.telemetry.first[id] then profile.telemetry.first[id] = now end
	end

	local function updateTutorial(profile, now)
		local t = profile.tutorial
		if profile.stations.garden.workerId and profile.stations.logistics.workerId and profile.stations.cauldron.workerId then t.workers = true end
		if profile.pipes then t.pipes = true end
		if profile.stations.crystal.level >= 2 then t.upgrade = true end
		for _, id in ipairs(config.tutorialSteps) do if not t[id] then return end end
		event(profile, "tutorial", now)
	end

	function engine.orderState(profile)
		local queued, travelling, delivered = 0, 0, total(profile.questStock)
		for _, id in ipairs(config.machineOrder) do queued += total(profile.stations[id].questQueue) end
		local job = profile.stations.logistics.job
		if job and job.destinationKind == "questStock" then travelling = job.amount end
		return { queued = queued, travelling = travelling, delivered = delivered, reserved = queued + travelling + delivered,
			remainingSeconds = profile.order and math.max(0, profile.order.expiresAt - profile.lastSimulatedAt) or 0,
			capacity = config.warehouse.questCapacity[profile.warehouseLevel + 1] }
	end

	local function sell(profile, recipe, count, summary)
		if count > 0 then
			earn(profile, "gold", count * Epochs.sale(config,profile,recipe.goldValue), summary)
			change(summary.sold, recipe.output, count)
			if recipe.output == "healing" then profile.tutorial.sale = true end
		end
	end

	local function dispatch(profile, stationId, recipe, count, summary)
		local reserved = 0
		local order = profile.order
		if order and order.itemId == recipe.output then
			reserved = math.min(count, order.count - engine.orderState(profile).reserved,
				config.questQueueCapacity - total(profile.stations[stationId].questQueue))
			if reserved > 0 then
				change(profile.stations[stationId].questQueue, recipe.output, reserved)
				change(summary.orderReserved, recipe.output, reserved)
			end
		end
		sell(profile, recipe, count - reserved, summary)
	end

	local function expireOrder(profile, now, summary)
		if profile.order and profile.order.expiresAt <= now then
			local recipe = config.recipes[profile.order.recipeId]
			sell(profile, recipe, engine.orderState(profile).reserved, summary)
			for _, id in ipairs(config.machineOrder) do profile.stations[id].questQueue = {} end
			local logistics = profile.stations.logistics
			if logistics.job and logistics.job.destinationKind == "questStock" then logistics.job, logistics.progress = nil, 0 end
			profile.questStock = {}
			profile.order = nil
		end
	end

	local function outputBlocked(profile, station, recipe)
		if recipe.kind == "intermediate" then return total(station.output) + recipe.quantity * 2 > config.machineOutputCapacity end
		local order = profile.order
		local reserve = order and order.itemId == recipe.output and math.min(recipe.quantity * 2, order.count - engine.orderState(profile).reserved) or 0
		return total(station.questQueue) + reserve > config.questQueueCapacity
	end

	local function startBrew(profile, stationId, automatic)
		local station = profile.stations[stationId]
		local recipe = station.recipeId and config.recipes[station.recipeId]
		if not Epochs.available(config,profile,recipe) or not compatible(config, stationId, recipe) or profile.phase < (recipe.phase or 1)
			or station.level < recipe.requiredLevel or station.job then
			return false, "Machine unavailable"
		end
		if station.essence < recipe.essenceCost then
			return false, "Not enough essence"
		end
		if outputBlocked(profile, station, recipe) then
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
		station.essence = station.essence - recipe.essenceCost
		local skill = effectiveSkill(profile, stationId)
		local item = station.cauldronId and profile.cauldrons[station.cauldronId]
		station.job = { kind = "brew", recipeId = station.recipeId, automatic = automatic == true,
			duration = math.max(1, Epochs.duration(config,profile,recipe.duration) / (1 + skill * config.brewSpeedPerSkill)),
			doubleChance = math.min(config.maxDoubleChance, skill * config.doubleChancePerSkill + (item and item.bonus or 0)) }
		station.progress = 0
		return true, "Brewing started"
	end

	local function refill(profile, stationId, limit)
		local station = profile.stations[stationId]
		if station.level == 0 or not station.recipeId then return 0 end
		local target = limit and config.essenceBufferCapacity or config.recipes[station.recipeId].essenceCost
		local amount = math.min(profile.essence, math.max(0, target - station.essence), limit or config.essenceBufferCapacity)
		profile.essence -= amount
		station.essence += amount
		return amount
	end

	local function loadInputs(profile, stationId)
		local station = profile.stations[stationId]
		local recipe = station.recipeId and config.recipes[station.recipeId]
		if not recipe then
			return 0
		end
		local moved = 0
		for _, itemId in ipairs(itemIds) do
			local needed = (recipe.inputs[itemId] or 0) - quantity(station.input, itemId)
			if needed > 0 then
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

	local function pipeInputs(profile)
		-- Visit each material/slot pair once, beginning at that material's saved
		-- turn. Advancing only after a transfer shares scarce one-item streams.
		for _,itemId in ipairs(itemIds) do
			if config.items[itemId].fluid and quantity(profile.inventory,itemId)>0 then
				local start=profile.inputCursors[itemId] or 1
				for offset=0,#config.machineOrder-1 do
					local index=(start-1+offset)%#config.machineOrder+1
					local station=profile.stations[config.machineOrder[index]]
					local recipe=station.recipeId and config.recipes[station.recipeId]
					if station.level>0 and recipe then
						local needed=math.max(0,(recipe.inputs[itemId] or 0)-quantity(station.input,itemId))
						local amount=math.min(needed,quantity(profile.inventory,itemId),config.machineInputCapacity-total(station.input))
						if amount>0 then
							change(profile.inventory,itemId,-amount); change(station.input,itemId,amount)
							profile.inputCursors[itemId]=index%#config.machineOrder+1
						end
					end
					if quantity(profile.inventory,itemId)==0 then break end
				end
			end
		end
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
		local limit = math.min(config.maxHaulCapacity, 1 + math.floor(skill / config.haulSkillPerSlot))
		local duration = config.baseHaulDuration
		local preferences = {}
		for offset = 0, routeCount - 1 do
			local routeIndex = (station.routeCursor - 1 + offset) % routeCount + 1
			local route = config.routes[routeIndex]
			if route.kind == "input" then
				local targetId = route.slot
				local target = profile.stations[targetId]
				local recipe = target.recipeId and config.recipes[target.recipeId]
				if recipe and target.level > 0 then
					for _, itemId in ipairs(itemIds) do
						local needed = (recipe.inputs[itemId] or 0) - quantity(target.input, itemId)
						if needed > 0 and not config.items[itemId].fluid and quantity(profile.inventory,itemId)>0 then
							-- No input changes until this scan returns: cache each material's
							-- selection to keep the route scan O(slots * item types).
							if preferences[itemId]==nil then
								local preferred,index=preferredInput(profile,itemId)
								preferences[itemId]={slot=preferred,index=index}
							end
							local choice=preferences[itemId]
							local amount = math.min(limit, needed, quantity(profile.inventory, itemId), config.machineInputCapacity - total(target.input))
							if amount > 0 and choice.slot==targetId then
								change(profile.inventory, itemId, -amount)
								profile.inputCursors[itemId]=choice.index%#config.machineOrder+1
								station.job = { kind = "haul", itemId = itemId, amount = amount, sourceKind = "inventory",
									destinationKind = "input", destinationStationId = targetId, duration = duration }
								station.progress = 0
								station.routeCursor = routeIndex % routeCount + 1
								return
							end
						end
					end
				end
			elseif route.kind == "output" then
				local sourceId = route.slot
				local source = profile.stations[sourceId]
				for _, itemId in ipairs(itemIds) do
					if not config.items[itemId].fluid then
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
			else
				local sourceId = route.slot
				local source = profile.stations[sourceId]
				for _, itemId in ipairs(itemIds) do
					local amount = math.min(limit, quantity(source.questQueue, itemId), config.warehouse.questCapacity[profile.warehouseLevel + 1] - total(profile.questStock))
					if amount > 0 then
						change(source.questQueue, itemId, -amount)
						station.job = { kind = "haul", itemId = itemId, amount = amount, sourceKind = "questQueue", sourceStationId = sourceId,
							destinationKind = "questStock", duration = duration }
						station.progress, station.routeCursor = 0, routeIndex % routeCount + 1
						return
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
		station.progress = math.min(job.duration, station.progress + (1 + effectiveSkill(profile, "logistics") * config.haulSpeedPerSkill)*Epochs.work(profile))
		if station.progress < job.duration then
			return
		end
		local destination, room
		if job.destinationKind == "questStock" then
			destination = profile.questStock
			room = config.warehouse.questCapacity[profile.warehouseLevel + 1] - total(destination)
		elseif job.destinationKind == "inventory" then
			destination = profile.inventory
			room = inventoryRoom(profile, job.itemId, true)
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

	local statusText = {
		working = "Работает", unbuilt = "Построй объект", no_master = "Нет мастера — назначь фамильяра",
		no_hauler = "Нет перевозчика — назначь рабочего на логистику",
		waiting_essence = "Ждёт Essence — заправь бак или подключи трубы",
		waiting_ingredient = "Ждёт ингредиенты — собери и загрузи сырьё",
		queue_full = "Очередь заполнена — освободи склад или включи доставку",
		manual_first = "Нужна первая ручная варка этого рецепта",
		recipe_unavailable = "Рецепт недоступен", no_path = "Нет пути — купи трубы или загрузи вручную",
		manual_mode = "Ручной режим — запусти партию или включи автоварку", idle = "Нет груза для доставки",
	}

	function engine.stationState(profile, stationId)
		local station, definition = profile.stations[stationId], config.stations[stationId]
		local recipe, job = config.recipes[station.recipeId], station.job
		local code, missing = "working", {}
		if recipe then
			for itemId, amount in pairs(recipe.inputs) do
				if quantity(station.input, itemId) < amount then missing[itemId] = amount - quantity(station.input, itemId) end
			end
		end
		if station.level == 0 then code = "unbuilt"
		elseif stationId == "logistics" then
			if not station.workerId then code = "no_hauler"
			elseif not job then code = "idle"
			elseif station.progress >= job.duration then code = "queue_full" end
		elseif definition.defaultRecipe then
			if not recipe then code = "recipe_unavailable"
			elseif job then
				if job.automatic and not station.workerId then code = "no_master"
				elseif station.progress >= job.duration and outputBlocked(profile, station, recipe) then code = "queue_full" end
			elseif outputBlocked(profile, station, recipe) then code = "queue_full"
			elseif station.auto and not station.workerId then code = "no_master"
			elseif station.essence < recipe.essenceCost then code = profile.essence > 0 and not profile.pipes and "no_path" or "waiting_essence"
			elseif total(missing) > 0 then
				code = "waiting_ingredient"
				for itemId in pairs(missing) do
					if config.items[itemId].fluid and not profile.pipes then code = "no_path"; break end
					if not config.items[itemId].fluid and not profile.stations.logistics.workerId then code = "no_hauler" end
				end
			elseif not profile.discoveredRecipes[station.recipeId] then code = "manual_first"
			elseif not station.auto then code = "manual_mode" end
		elseif definition.outputItem then
			if total(station.output) >= config.sourceCapacity then code = "queue_full"
			elseif not station.workerId then code = "no_master" end
		elseif stationId == "crystal" and not station.workerId and definition.passiveEssence[station.level] == 0 then code = "manual_mode" end
		local duration = job and job.duration or (definition.growDuration and math.max(1, Epochs.duration(config,profile,definition.growDuration) / (1 + effectiveSkill(profile, stationId) * config.gatherSpeedPerSkill)))
		return { code = code, text = statusText[code], missingInputs = missing,
			essence = station.essence, essenceRequired = recipe and recipe.essenceCost or 0,
			progress = duration and math.min(1, station.progress / duration) or 0,
			effectiveSkill = effectiveSkill(profile, stationId), queued = total(station.questQueue) }
	end

	function engine.productionState(profile)
		local result = {}
		for _, id in ipairs(config.stationOrder) do result[id] = engine.stationState(profile, id) end
		return result
	end

	function engine.recipeState(profile, slotId, recipeId)
		local recipe, station = config.recipes[recipeId], profile.stations[slotId]
		local reason = not compatible(config, slotId, recipe) and "Wrong apparatus"
			or (not Epochs.available(config,profile,recipe) and "Recipe belongs to another epoch")
			or (profile.phase < (recipe.phase or 1) and ("Requires phase " .. recipe.phase))
			or (station.level < recipe.requiredLevel and ("Requires tier " .. recipe.requiredLevel)) or ""
		return { available = reason == "", reason = reason, saleValue=recipe and Epochs.sale(config,profile,recipe.goldValue) or 0 }
	end

	function engine.orderEligible(profile, orderId)
		local order = config.orders[orderId]
		if not order or not Epochs.available(config,profile,order) or profile.phase < (order.phase or 1) then return false, "Contract requires its epoch and phase" end
		local recipe = config.recipes[order.recipeId]
		local usable = false
		for _, slot in ipairs(config.machineOrder) do if engine.recipeState(profile, slot, order.recipeId).available then usable = true; break end end
		if not usable then return false, "Unlock the recipe first" end
		if order.phase and not profile.discoveredRecipes[order.recipeId] then return false, "Discover this recipe manually first" end
		if order.count > config.warehouse.questCapacity[profile.warehouseLevel+1] then return false, "Upgrade order storage first" end
		local function reachable(itemId, seen)
			if seen[itemId] then return false end
			seen[itemId] = true
			if itemId == "slime" then return true end -- Guaranteed base slime hire remains available.
			for _, slot in ipairs(config.sourceOrder) do
				if config.stations[slot].outputItem == itemId and profile.stations[slot].level > 0 then seen[itemId]=nil; return true end
			end
			local intermediate = config.recipes[itemId]
			if not intermediate then return false end
			local built = false
			for _, slot in ipairs(config.machineOrder) do if engine.recipeState(profile,slot,itemId).available then built=true; break end end
			if not built then return false end
			for input in pairs(intermediate.inputs) do if not reachable(input,seen) then return false end end
			seen[itemId] = nil; return true
		end
		if order.phase then for itemId in pairs(recipe.inputs) do if not reachable(itemId,{}) then return false, "Build the ingredient production chain first" end end end
		return true
	end

	function engine.orderOffers(profile)
		local eligible = {}
		for id, def in pairs(config.orders) do
			local allowed = engine.orderEligible(profile,id)
			if allowed and (id ~= "rage_small" or profile.discoveredRecipes.rage) then table.insert(eligible,id) end
		end
		table.sort(eligible,function(a,b)
			if not profile.tutorial.orderClaimed and (a=="healing_small" or b=="healing_small") then return a=="healing_small" end
			local pa,pb = config.orders[a].phase or 1,config.orders[b].phase or 1
			if pa~=pb then return pa>pb end
			local ta,tb=config.recipes[config.orders[a].recipeId].requiredLevel,config.recipes[config.orders[b].recipeId].requiredLevel
			if ta~=tb then return ta>tb end
			local ra,rb=config.orders[a].priority or 0,config.orders[b].priority or 0
			return ra==rb and a<b or ra>rb
		end)
		while #eligible > 3 do table.remove(eligible) end
		return eligible
	end

	function engine.storageState(profile)
		local types={raw=0,intermediate=0}
		for _,item in pairs(config.items) do if types[item.kind] and Epochs.available(config,profile,item) then types[item.kind]+=1 end end
		return { raw = stored(profile, "raw"), rawCapacity = capacity(profile, "raw"),
			intermediate = stored(profile, "intermediate"), intermediateCapacity = capacity(profile, "intermediate"),
			rawTarget = profile.phase >= config.balancedStoragePhase and math.floor(capacity(profile,"raw")/types.raw) or nil,
			intermediateTarget = profile.phase >= config.balancedStoragePhase and math.floor(capacity(profile,"intermediate")/types.intermediate) or nil }
	end

	function engine.tutorialState(profile)
		local hints = {
			crystal = { "crystal", "Подойди к кристаллу и собери Essence. Для Healing нужно 3." },
			ingredients = { "garden", "На грядке собери 2 Mandrake. Ручной сбор бесплатный." },
			workers = { "garden", "Назначь сову на грядку, слайма на логистику, кота на котёл. Все трое уже твои." },
			manual = { "cauldron", "Выбери Healing → загрузи ингредиенты и Essence → свари вручную. При нехватке вернись к кристаллу или грядке." },
			sale = { "cauldron", "Свари Healing для автопродажи за 14 Gold. Активный заказ сначала забирает свою квоту." },
			pipes = { "warehouse", "Накопи 28 Gold ручной варкой и купи трубы на складе: они заправляют котлы автоматически." },
			upgrade = { "crystal", "Накопи 140 Gold и улучши кристалл для пассивной Essence. До покупки клики остаются бесплатными." },
			automation = { "cauldron", "Выбери Healing, назначь кота и включи автоварку. Сова и слайм обеспечат ингредиенты. Дождись готовой партии." },
			orderAccepted = { "orders", "У доски NPC прими Healer's request: изготовь и доставь 5 Healing." },
			orderClaimed = { "orders", "Слайм везёт ящики от котла на квестовый склад. Когда доставлено 5/5, сдай заказ у доски. Истёкший заказ можно принять снова." },
		}
		for index, id in ipairs(config.tutorialSteps) do
			if not profile.tutorial[id] then
				local hint = hints[id]
				local target = hint[1]
				if id == "workers" then
					for _, stationId in ipairs({ "garden", "logistics", "cauldron" }) do
						if not profile.stations[stationId].workerId then target = stationId; break end
					end
				end
				return { step = index, total = #config.tutorialSteps, id = id, target = target, text = hint[2], complete = false }
			end
		end
		return { step = #config.tutorialSteps, total = #config.tutorialSteps, id = "complete", target = "orders", text = "Обучение завершено: фабрика и доставка работают!", complete = true }
	end

	local function tick(profile, now, summary, petIds, isOffline)
		expireOrder(profile, now, summary)
		local crystal = profile.stations.crystal
		if crystal.level > 0 then
			local gain = config.stations.crystal.passiveEssence[crystal.level]
			if gain>0 then gain+=Epochs.essence(profile) end
			if crystal.workerId then
				gain = gain + math.max(1, math.floor(effectiveSkill(profile, "crystal") / config.crystalSkillPerEssence))
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
				local duration = math.max(1, Epochs.duration(config,profile,definition.growDuration) / (1 + effectiveSkill(profile, stationId) * config.gatherSpeedPerSkill))
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
			local firstBuilt, nextBuilt
			for offset = 0, #config.machineOrder - 1 do
				local index = (profile.pipeCursor - 1 + offset) % #config.machineOrder + 1
				if profile.stations[config.machineOrder[index]].level > 0 then
					if not firstBuilt then firstBuilt = index elseif not nextBuilt then nextBuilt = index end
					refill(profile, config.machineOrder[index], config.pipeEssencePerSecond)
				end
			end
			profile.pipeCursor = nextBuilt or firstBuilt or 1
			for _, stationId in ipairs(config.machineOrder) do
				collectOutput(profile, stationId, true)
			end
			pipeInputs(profile)
		end
		tickHauler(profile)
		for _, stationId in ipairs(config.machineOrder) do
			local station = profile.stations[stationId]
			local job = station.job
			if job and (not job.automatic or station.workerId) then
				station.progress = math.min(job.duration, station.progress + 1)
				if station.progress >= job.duration and not outputBlocked(profile, station, config.recipes[job.recipeId]) then
					local recipe = config.recipes[job.recipeId]
					local produced = recipe.quantity
					if nextRandom(profile) < job.doubleChance then
						produced = produced * 2
					end
					change(summary.produced, recipe.output, produced)
					profile.discoveredRecipes[job.recipeId] = true
					if job.recipeId==Epochs.rules(config,profile).finalRecipe then profile.longTerm.cycle.finalProduced=true end
					if not isOffline and not job.automatic and recipe.kind=="potion" then Dailies.record(config,profile,"brew",1,now) end
					event(profile, job.automatic and "auto_brew" or "manual_brew", now)
					if job.recipeId == "healing" then profile.tutorial[job.automatic and "automation" or "manual"] = true end
					if recipe.kind == "potion" then
						dispatch(profile, stationId, recipe, produced, summary)
					else
						change(station.output, recipe.output, produced)
					end
					station.job = nil
					station.progress = 0
				end
			end
			if not station.job and station.auto and station.workerId then
				startBrew(profile, stationId, true)
			end
		end
		updateTutorial(profile, now)
		for _, stationId in ipairs(config.stationOrder) do
			local status = engine.stationState(profile, stationId).code
			if status ~= "working" then
				local stalls = profile.telemetry.stalls
				stalls[stationId] = stalls[stationId] or {}
				stalls[stationId][status] = math.min(config.maxBalance, (stalls[stationId][status] or 0) + 1)
			end
		end
	end

	function engine.advance(profile, now, isOffline)
		local summary = report()
		if Trading.frozen(profile) then summary.ok=false; summary.error="Trade recovery pending"; return summary end
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
			tick(profile, profile.lastSimulatedAt + offset, summary, petIds, isOffline)
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
		prioritize = { stationId = true }, buy = { upgradeId = true, expectedLevel = true }, hire = { speciesId = true }, acceptOrder = { orderId = true }, claimOrder = {},
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
			elseif key == "expectedLevel" then
				if not integer(payload[key], 0, config.maxCount) then return false end
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
		if Trading.frozen(profile) then return false,"Trade recovery pending" end
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
		if action == "prioritize" then
			for index, route in ipairs(config.routes) do if route.slot == stationId then profile.stations.logistics.routeCursor = index; break end end
			local index = table.find(config.machineOrder, stationId)
			if index then
				profile.pipeCursor = index
				local recipe=station.recipeId and config.recipes[station.recipeId]
				if recipe then for itemId in pairs(recipe.inputs) do profile.inputCursors[itemId]=index end end
			end
			return true, "This slot receives the next supply turn; fair rotation then resumes"
		elseif action == "click" then
			if profile.essence >= config.maxBalance then return false, "Essence limit reached" end
			local gained = math.min(config.manualClickEssence+Epochs.essence(profile), config.maxBalance - profile.essence)
			profile.essence += gained
			Dailies.record(config,profile,"essence",gained,math.floor(now))
			profile.tutorial.crystal = true
			return true, "+" .. gained .. " essence"
		elseif action == "assign" then
			if payload.petId ~= "" then
				for otherId, other in pairs(profile.stations) do
					if otherId ~= stationId and other.workerId == payload.petId then
						return false, "Familiar already has a workplace"
					end
				end
			end
			station.workerId = payload.petId ~= "" and payload.petId or nil
			updateTutorial(profile, math.floor(now))
			return true, "Assignment updated"
		elseif action == "harvest" then
			local itemId = config.stations[stationId].outputItem
			if not itemId then return false, "Not a gathering station" end
			local timestamp = math.floor(now)
			if timestamp > config.maxTimestamp - config.manualHarvestCooldown then return false, "Timestamp limit reached" end
			if timestamp < profile.manualReadyAt[stationId] then return false, "Gathering is on cooldown" end
			if inventoryRoom(profile, itemId) < 1 then
				return false, profile.phase >= config.balancedStoragePhase and "Material intake target reached; use or discard stored ingredients" or "Raw storage is full"
			end
			change(profile.inventory, itemId, 1)
			if itemId == "mandrake" then profile.tutorial.ingredients = true end
			profile.manualReadyAt[stationId] = timestamp + config.manualHarvestCooldown
			return true, "Ingredient gathered"
		elseif action == "collect" then
			if collectOutput(profile, stationId, false) == 0 then return false, "Nothing to collect or storage is full" end
			return true, "Output collected"
		elseif action == "load" then
			local moved = loadInputs(profile, stationId) + refill(profile, stationId, nil)
			if moved == 0 then return false, "No ingredients or Essence to load" end
			return true, "Ingredients and Essence loaded"
		elseif action == "brew" then
			return startBrew(profile, stationId)
		elseif action == "setRecipe" then
			local state = engine.recipeState(profile, stationId, payload.recipeId)
			if not state.available then return false, state.reason end
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
			profile.pets[petId] = familiars.create(petId, payload.speciesId, definition.stats, "hire", profile.currencyPaid.gold)
			profile.nextPetSerial = profile.nextPetSerial + 1
			return true, "Familiar hired"
		elseif action == "buy" then
			local state = progression.buildState(profile, payload.upgradeId)
			if not state.available then return false, state.reason end
			local upgradeId, cost = payload.upgradeId, nil
			local level = upgradeId == "pipes" and (profile.pipes and 1 or 0)
				or (upgradeId == "warehouse" and profile.warehouseLevel or profile.stations[upgradeId].level)
			if payload.expectedLevel ~= level then return false, "Upgrade already changed; refresh first" end
			if upgradeId == "pipes" then
				if profile.pipes then return false, "Pipes already purchased" end
				cost = config.pipesCost
			elseif upgradeId == "warehouse" then
				cost = config.warehouse.upgradeCosts[profile.warehouseLevel + 1]
			else
				cost = config.stations[upgradeId].upgradeCosts[profile.stations[upgradeId].level + 1]
			end
			cost=Epochs.cost(config,profile,cost)
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
			event(profile, "upgrade", math.floor(now))
			updateTutorial(profile, math.floor(now))
			return true, "Upgrade purchased"
		elseif action == "acceptOrder" then
			if profile.order then return false, "An order is already active" end
			local definition = config.orders[payload.orderId]
			if math.floor(now) > config.maxTimestamp - definition.duration then return false, "Timestamp limit reached" end
			local allowed, rejection = engine.orderEligible(profile, payload.orderId)
			if not allowed then return false, rejection end
			if definition.count > config.warehouse.questCapacity[profile.warehouseLevel + 1] then return false, "Upgrade order storage first" end
			profile.order = { id = payload.orderId, recipeId = definition.recipeId, itemId = definition.itemId,
				count = definition.count, rewardGold = definition.rewardGold,
				acceptedAt = math.floor(now), expiresAt = math.floor(now) + definition.duration }
			profile.tutorial.orderAccepted = true
			return true, "Order accepted"
		elseif action == "claimOrder" then
			local order = profile.order
			if not order or quantity(profile.questStock, order.itemId) < order.count then return false, "Order is not ready" end
			change(profile.questStock, order.itemId, -order.count)
			profile.gold = math.min(config.maxBalance, profile.gold + order.rewardGold)
			profile.order = nil
			profile.tutorial.orderClaimed = true
			Dailies.record(config,profile,"orders",1,math.floor(now))
			event(profile, "contract", math.floor(now))
			updateTutorial(profile, math.floor(now))
			return true, "Order delivered"
		end
		return false, "Unknown action"
	end

	return engine
end

return Factory
