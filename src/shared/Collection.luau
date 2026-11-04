--!nonstrict
-- Pure commands on a transaction candidate. Runtime MUST commit before acknowledgement.
local runtimeScript = rawget(getfenv(), "script")
local Familiars = require(runtimeScript and runtimeScript.Parent.Familiars or "./Familiars")
local Protocol = require(runtimeScript and runtimeScript.Parent.Protocol or "./Protocol")
local Policy = require(runtimeScript and runtimeScript.Parent.Policy or "./Policy")
local Collection = {}
local actions = { summon = true, shopFamiliar = true, hire = true, fuse = true, petLock = true }
local function copy(v)
	if type(v) ~= "table" then return v end
	local result = {}; for k, child in pairs(v) do result[k] = copy(child) end; return result
end
local function fingerprint(action, payload)
	local parts = { action }
	local fields = {}; for key in pairs(payload) do table.insert(fields, key) end; table.sort(fields)
	for _, key in ipairs(fields) do
		local value = payload[key]
		if type(value) == "table" then value = copy(value); table.sort(value); value = table.concat(value, ",") end
		table.insert(parts, key .. "=" .. tostring(value))
	end
	return table.concat(parts, "|")
end
local function count(map) local n = 0; for _ in pairs(map) do n += 1 end; return n end
local function samePreview(a, b)
	if not a or not b or a.species ~= b.species or a.paidDerived ~= b.paidDerived or a.tradeKnown~=b.tradeKnown then return false end
	for index, id in ipairs(a.parentIds) do if b.parentIds[index] ~= id then return false end end
	for skill, value in pairs(a.stats) do if b.stats[skill] ~= value then return false end end
	return true
end

function Collection.isAction(action) return actions[action] == true end
function Collection.new(config)
	local model = Familiars.new(config)
	local service = { preview = model.preview, details = model.details }
	function service.apply(p, action, payload, context)
		if p.trade and p.trade.pending then return false,"Trade recovery pending" end
		local valid, reason = Protocol.validate(action, payload)
		if not actions[action] or not valid then return false, reason or "Unknown collection action" end
		local key = fingerprint(action, payload)
		local progress = p.collection
		if payload.requestId == progress.sequence and progress.last then
			if progress.last.fingerprint ~= key then return false, "Request ID already used for another intent" end
			return true, copy(progress.last.result), true
		end
		if payload.requestId ~= progress.sequence + 1 or progress.sequence >= config.maxBalance then return false, "Stale collection request; refresh inventory" end
		if progress.last and context.now - progress.last.at < config.collection.cooldownSeconds then return false, "Collection action is on cooldown" end
		local pending, consumed, currency, cost = {}, {}, nil, 0
		local message = "Collection updated"
		local function create(species, stats, source, paid, parents, tradeKnown)
			local serial = p.nextPetSerial + #pending
			if serial >= config.maxCount then return false end
			local id = string.format("%.0f", p.userId) .. ":pet:" .. serial
			if p.pets[id] then return false end
			table.insert(pending, model.create(id, species, stats, source, paid, parents, tradeKnown))
			return true
		end
		if action == "summon" then
			if not Policy.allowed(context.policy, context.now) then return false, "Random summon unavailable; use the guaranteed shop" end
			local pool = config.summonPools[payload.poolId]
			if not pool or not table.find(pool.counts, payload.count) then return false, "Unknown summon pool or count" end
			currency, cost = "essence", pool.essenceCost * payload.count
			if count(p.pets) + payload.count > config.maxPets then return false, "Familiar inventory is full" end
			if p.essence < cost then return false, "Not enough Essence" end
			if p.nextPetSerial + payload.count > config.maxCount then return false, "Familiar identity limit" end
			for _ = 1, payload.count do
				local species = model.pick(payload.poolId, context.nextInteger(1, pool.totalWeight))
				local stats = model.rollStats(species, context.nextInteger)
				if not create(species, stats, "gacha", p.currencyPaid.essence) then return false, "Familiar identity conflict" end
			end
			message = "Summoned " .. payload.count .. " familiar(s)"
		elseif action == "shopFamiliar" or action == "hire" then
			local offer = config.familiarShop[action == "hire" and payload.speciesId or payload.offerId]
			if not offer or (action == "hire" and not config.hires[payload.speciesId]) then return false, "Unknown fixed offer" end
			if count(p.pets) >= config.maxPets then return false, "Familiar inventory is full" end
			currency, cost = offer.currency, offer.cost
			if p[currency] < cost then return false, "Not enough " .. currency end
			if not create(offer.species, offer.stats, action == "hire" and "hire" or "shop", p.currencyPaid[currency]) then return false, "Familiar identity conflict" end
			message = "Purchased fixed " .. config.petSpecies[offer.species].name
		elseif action == "fuse" then
			local preview, err = model.preview(p, payload.petIds)
			if not preview then return false, err end
			if not context.preview or context.preview.token ~= payload.previewToken or context.preview.expiresAt <= context.now
				or not samePreview(preview, context.preview) then return false, "Preview changed; review the five inputs again" end
			consumed = preview.parentIds
			if not create(preview.species, preview.stats, "fuse", preview.paidDerived, consumed, preview.tradeKnown) then return false, "Familiar identity conflict" end
			message = "Evolved into " .. preview.name
		elseif action == "petLock" then
			if not p.pets[payload.petId] then return false, "Unknown familiar" end
			message = payload.locked and "Familiar locked" or "Familiar unlocked"
		end
		-- Commit the complete, prevalidated candidate in one non-yielding section.
		if currency then p[currency] -= cost end
		for _, id in ipairs(consumed) do p.pets[id], p.slimeWorkSeconds[id] = nil, nil end
		local result = { createdIds = {}, consumedIds = copy(consumed), message = message }
		for _, pet in ipairs(pending) do p.pets[pet.id] = pet; table.insert(result.createdIds, pet.id) end
		p.nextPetSerial += #pending
		if action == "petLock" then p.pets[payload.petId].locked = payload.locked end
		p.collection = { sequence = payload.requestId, last = { requestId = payload.requestId, action = action, fingerprint = key, at = context.now, result = copy(result) } }
		return true, result, false
	end
	return service
end
return Collection
