--!nonstrict
-- Pure collection data/model. No server RNG, clocks, service calls or rewards here.
local Familiars = {}
function Familiars.provenanceKnown(pet)
	local origin=pet.provenance
	return type(origin)=="table" and origin.source~="legacy" and origin.tradeKnown~=false
		and (origin.source~="fuse" or origin.tradeKnown==true)
end
local skills = { "Farming", "Hauling", "Brewing" }
local sources = { starter = true, hire = true, shop = true, gacha = true, fuse = true, legacy = true, rebirth_shop=true, calendar=true }
local function integer(value, lo, hi)
	return type(value) == "number" and value == value and value % 1 == 0 and value >= lo and value <= hi
end
local function plain(value) return type(value) == "table" and getmetatable(value) == nil end
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for k, v in pairs(value) do result[k] = copy(v) end
	return result
end
local function ids(value, maximum)
	if not plain(value) or #value > maximum then return false end
	local count, seen = 0, {}
	for k, id in pairs(value) do
		if not integer(k, 1, #value) or type(id) ~= "string" or #id < 1 or #id > 80 or seen[id] then return false end
		count += 1; seen[id] = true
	end
	return count == #value
end

function Familiars.new(config)
	for _, def in pairs(config.petSpecies) do
		assert(config.rarityOrder[def.rarity] and def.rarity ~= "Legacy", "invalid_species_rarity")
		assert(integer(def.evolution, 0, 2), "invalid_species_stage")
		for _, skill in ipairs(skills) do
			local range = def.ranges[skill]
			assert(range and integer(range[1], 0, config.maxBaseStat) and integer(range[2], range[1], config.maxBaseStat), "invalid_stat_range")
		end
		if def.fuseTo then
			local target = config.petSpecies[def.fuseTo]
			assert(target and target.evolution == def.evolution + 1, "invalid_evolution_target")
			for _, skill in ipairs(skills) do assert(target.ranges[skill][2] >= def.ranges[skill][2], "evolution_weakens_stat") end
		end
	end
	for _, pool in pairs(config.summonPools) do
		local totalWeight, seen = 0, {}
		assert(integer(pool.essenceCost, 1, config.maxBalance) and integer(pool.totalWeight, 1, 1000000000), "invalid_pool")
		for _, outcome in ipairs(pool.outcomes) do
			assert(config.petSpecies[outcome.species] and not seen[outcome.species] and integer(outcome.weight, 1, pool.totalWeight), "invalid_outcome")
			seen[outcome.species] = true; totalWeight += outcome.weight
		end
		assert(totalWeight == pool.totalWeight, "invalid_pool_total")
	end
	for _, offer in pairs(config.familiarShop) do
		local def = config.petSpecies[offer.species]
		assert(def and (offer.currency == "gold" or offer.currency == "essence") and integer(offer.cost, 1, config.maxBalance), "invalid_fixed_offer")
		for _, skill in ipairs(skills) do assert(integer(offer.stats[skill], def.ranges[skill][1], def.ranges[skill][2]), "invalid_fixed_stats") end
	end
	local model = {}
	function model.create(id, species, stats, source, paid, parents, tradeKnown)
		local def = config.petSpecies[species]
		return { id = id, species = species, name = def.name, stats = copy(stats), paidOrigin = paid,
			rarity = def.rarity, evolution = def.evolution, locked = false,
			provenance = { source = source, paidDerived = paid, parents = copy(parents or {}),
				tradeKnown=source=="fuse" and tradeKnown==true or source~="fuse" and source~="legacy" } }
	end
	function model.upgradeLegacy(pet)
		pet.rarity, pet.evolution, pet.locked = "Legacy", 0, false
		pet.provenance = { source = "legacy", paidDerived = pet.paidOrigin, parents = {} }
	end
	function model.validatePet(pet)
		local def = config.petSpecies[pet.species]
		local origin = pet.provenance
		if not def or type(pet.locked) ~= "boolean" or not plain(origin) or not sources[origin.source]
			or type(origin.paidDerived) ~= "boolean" or origin.paidDerived ~= pet.paidOrigin
			or not ids(origin.parents, config.collection.fuseCount) then return false end
		if origin.tradeKnown~=nil and type(origin.tradeKnown)~="boolean" then return false end
		if origin.source=="legacy" and origin.tradeKnown==true then return false end
		if origin.source == "legacy" then
			return pet.rarity == "Legacy" and pet.evolution == 0
				and (pet.species == "farmer" or pet.species == "slime" or pet.species == "brewer") and #origin.parents == 0
		end
		if pet.rarity ~= def.rarity or pet.evolution ~= def.evolution then return false end
		if #origin.parents ~= (origin.source == "fuse" and config.collection.fuseCount or 0) then return false end
		for _, skill in ipairs(skills) do
			local range = def.ranges[skill]
			if not integer(pet.stats[skill], range[1], range[2]) then return false end
		end
		return true
	end
	function model.validateProgress(p)
		local c, paid = p.collection, p.currencyPaid
		if not plain(c) or not integer(c.sequence, 0, config.maxBalance) or not plain(paid)
			or type(paid.gold) ~= "boolean" or type(paid.essence) ~= "boolean" then return false end
		if c.sequence == 0 then return c.last == nil end
		local last = c.last
		if not plain(last) or last.requestId ~= c.sequence or not integer(last.at, 0, config.maxTimestamp)
			or not ({ summon = true, shopFamiliar = true, hire = true, fuse = true, petLock = true })[last.action]
			or type(last.fingerprint) ~= "string" or #last.fingerprint > 2048 or #last.fingerprint < 1
			or not plain(last.result) or not ids(last.result.createdIds, 5) or not ids(last.result.consumedIds, 5)
			or type(last.result.message) ~= "string" or #last.result.message > 256 then return false end
		return true
	end
	function model.pick(poolId, roll)
		local pool = config.summonPools[poolId]
		assert(pool and integer(roll, 1, pool.totalWeight), "invalid_pool_draw")
		local cumulative = 0
		for _, outcome in ipairs(pool.outcomes) do
			cumulative += outcome.weight
			if roll <= cumulative then return outcome.species end
		end
		error("unreachable_pool_draw")
	end
	function model.rollStats(species, nextInteger)
		local result = {}
		for _, skill in ipairs(skills) do
			local range = config.petSpecies[species].ranges[skill]
			local value = nextInteger(range[1], range[2])
			assert(integer(value, range[1], range[2]), "invalid_stat_draw")
			result[skill] = value
		end
		return result
	end
	function model.preview(p, parentIds)
		if p.trade and p.trade.pending then return nil,"Trade recovery pending" end
		if not ids(parentIds, config.collection.fuseCount) or #parentIds ~= config.collection.fuseCount then return nil, "Choose five distinct familiars" end
		local parents = copy(parentIds); table.sort(parents)
		local first = p.pets[parents[1]]
		local definition = first and config.petSpecies[first.species]
		if not definition or not definition.fuseTo then return nil, "This form cannot evolve" end
		local target = config.petSpecies[definition.fuseTo]
		local stats, paid, tradeKnown = { Farming = 0, Hauling = 0, Brewing = 0 }, false, true
		for _, id in ipairs(parents) do
			local pet = p.pets[id]
			if not pet or pet.species ~= first.species or pet.evolution ~= first.evolution then return nil, "Five matching species and stages required" end
			if pet.locked then return nil, "Unlock each selected familiar first" end
			for _, station in pairs(p.stations) do if station.workerId == id then return nil, "Unassign every selected familiar first" end end
			paid = paid or pet.paidOrigin or pet.provenance.paidDerived
			tradeKnown = tradeKnown and Familiars.provenanceKnown(pet)
			for _, skill in ipairs(skills) do
				if pet.stats[skill] > target.ranges[skill][2] then return nil, "Legacy stat exceeds the next form; keep this familiar" end
				stats[skill] = math.max(stats[skill], pet.stats[skill])
			end
		end
		for _, skill in ipairs(skills) do stats[skill] = math.clamp(stats[skill] + config.collection.fuseBonus, target.ranges[skill][1], target.ranges[skill][2]) end
		return { parentIds = parents, species = definition.fuseTo, name = target.name, rarity = target.rarity,
			evolution = target.evolution, stats = stats, paidDerived = paid, tradeKnown=tradeKnown }
	end
	function model.details(poolId)
		local pool = config.summonPools[poolId]
		if not pool then return nil end
		local result = { id = poolId, name = pool.name, cost = pool.essenceCost, totalWeight = pool.totalWeight, outcomes = {} }
		for _, outcome in ipairs(pool.outcomes) do
			local def = config.petSpecies[outcome.species]
			local combinations = 1
			for _, skill in ipairs(skills) do combinations *= def.ranges[skill][2] - def.ranges[skill][1] + 1 end
			table.insert(result.outcomes, { species = outcome.species, name = def.name, rarity = def.rarity,
				weight = outcome.weight, percent = outcome.weight * 100 / pool.totalWeight,
				ranges = copy(def.ranges), combinations = combinations,
				tuplePercent = outcome.weight * 100 / pool.totalWeight / combinations })
		end
		return result
	end
	return model
end

return Familiars
