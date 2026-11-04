--!strict
-- Shape/rate gate only. The server still owns authorization, ranges and economics.
-- No Roblox APIs: the exact module is exercised by the standalone Luau tests.

export type Config = {
	aggregateRate: number?,
	aggregateBurst: number?,
	clickRate: number?,
	clickBurst: number?,
	controlRate: number?,
	controlBurst: number?,
}

type Limits = {
	aggregateRate: number,
	aggregateBurst: number,
	clickRate: number,
	clickBurst: number,
	controlRate: number,
	controlBurst: number,
}

type Bucket = {
	lastTime: number,
	aggregate: number,
	click: number,
	control: number,
}

local Protocol = {}
Protocol.__index = Protocol

type GateData = {
	_limits: Limits,
	_buckets: { [number]: Bucket? },
}

export type Gate = typeof(setmetatable({} :: GateData, Protocol))

local SCHEMAS: { [string]: { [string]: string } } = {
	tradeInvite = { targetToken="id" },
	tradeAccept = { tradeId="id",version="sequence" },
	tradeCancel = { tradeId="id",version="sequence" },
	tradeOffer = { tradeId="id",version="sequence",items="trade-items" },
	tradeReady = { tradeId="id",version="sequence",ready="boolean" },
	tradeConfirm = { tradeId="id",version="sequence",offerHash="id" },
	click = {},
	assign = { stationId = "id", petId = "id-or-empty" },
	harvest = { stationId = "id" },
	collect = { stationId = "id" },
	load = { stationId = "id" },
	brew = { stationId = "id" },
	setRecipe = { stationId = "id", recipeId = "id" },
	setAuto = { stationId = "id", enabled = "boolean" },
	buy = { upgradeId = "id", expectedLevel = "level" },
	build = { upgradeId = "id", expectedLevel = "level", requestId = "sequence" },
	advancePhase = { expectedPhase = "phase", requestId = "sequence" },
	equipCauldron = { slotId = "id", cauldronId = "id-or-empty", requestId = "sequence" },
	lockCauldron = { cauldronId = "id", locked = "boolean", requestId = "sequence" },
	prioritize = { stationId = "id" },
	hire = { speciesId = "id", requestId = "sequence" },
	summon = { poolId = "id", count = "count", requestId = "sequence" },
	shopFamiliar = { offerId = "id", requestId = "sequence" },
	petLock = { petId = "id", locked = "boolean", requestId = "sequence" },
	previewFuse = { petIds = "five-ids" },
	refreshPolicy = {},
	fuse = { petIds = "five-ids", previewToken = "id", confirmed = "true", requestId = "sequence" },
	discard = { itemId = "id", amount = "count" },
	acceptOrder = { orderId = "id" },
	claimOrder = {},
}

local DEFAULTS: Limits = {
	aggregateRate = 20,
	aggregateBurst = 30,
	clickRate = 8,
	clickBurst = 8,
	controlRate = 5,
	controlBurst = 10,
}

local MAX_SAFE_INTEGER = 9007199254740991
local MAX_ID_LENGTH = 64

local function finite(value: any): boolean
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function validId(value: any, allowEmpty: boolean): boolean
	if type(value) ~= "string" or #value > MAX_ID_LENGTH then
		return false
	end
	if value == "" then
		return allowEmpty
	end
	-- These are opaque identifiers, not display names or arbitrary user text.
	return string.match(value, "^[%w_:%-%.]+$") ~= nil
end

local function validatePayload(action: any, payload: any): (boolean, string)
	if type(action) ~= "string" or #action > MAX_ID_LENGTH then
		return false, "invalid_action"
	end
	local schema = SCHEMAS[action]
	if schema == nil then
		return false, "invalid_action"
	end
	if type(payload) ~= "table" or getmetatable(payload) ~= nil then
		return false, "invalid_payload"
	end
	for key in pairs(payload) do
		if type(key) ~= "string" or schema[key] == nil then
			return false, "unexpected_field"
		end
	end
	for key, kind in pairs(schema) do
		local value = payload[key]
		if kind == "trade-items" then
			if type(value)~="table" or getmetatable(value)~=nil or #value>6 then return false,"invalid_payload" end
			local seen: { [string]: boolean } = {}; local count=0
			for index,entry in pairs(value) do
				if type(index)~="number" or not finite(index) or index%1~=0 or index<1 or index>#value
					or type(entry)~="table" or getmetatable(entry)~=nil then return false,"invalid_payload" end
				for field in pairs(entry) do if field~="id" and field~="kind" then return false,"unexpected_field" end end
				local offeredId: any = (entry :: any).id
				if (entry.kind~="pet" and entry.kind~="cauldron") or type(offeredId)~="string" or not validId(offeredId,false) or seen[offeredId] then return false,"invalid_payload" end
				seen[offeredId]=true; count+=1
			end
			if count~=#value then return false,"invalid_payload" end
		elseif kind == "five-ids" then
			if type(value) ~= "table" or getmetatable(value) ~= nil or #value ~= 5 then return false, "invalid_payload" end
			local seen: { [string]: boolean } = {}
			local count = 0
			for index, id in pairs(value) do
				if type(index) ~= "number" or not finite(index) or index % 1 ~= 0 or index < 1 or index > 5
					or type(id) ~= "string" or not validId(id, false) or seen[id] then return false, "invalid_payload" end
				seen[id], count = true, count + 1
			end
			if count ~= 5 then return false, "invalid_payload" end
		elseif kind == "phase" then
			if not finite(value) or value % 1 ~= 0 or value < 1 or value > 4 then return false, "invalid_payload" end
		elseif kind == "sequence" then
			if not finite(value) or value % 1 ~= 0 or value < 1 or value > 1000000000000 then return false, "invalid_payload" end
		elseif kind == "true" then
			if value ~= true then return false, "invalid_payload" end
		elseif kind == "boolean" then
			if type(value) ~= "boolean" then
				return false, "invalid_payload"
			end
		elseif kind == "count" or kind == "level" then
			if not finite(value) or value % 1 ~= 0 or value < (kind == "level" and 0 or 1) or value > 1000000 then
				return false, "invalid_payload"
			end
		elseif not validId(value, kind == "id-or-empty") then
			return false, "invalid_payload"
		end
	end
	return true, "ok"
end

function Protocol.new(config: Config?): Gate
	local limits: Limits = table.clone(DEFAULTS)
	if config ~= nil then
		assert(type(config) == "table" and getmetatable(config) == nil, "Protocol config must be a plain table")
		for key, value in pairs(config :: any) do
			assert((DEFAULTS :: any)[key] ~= nil, "Unknown Protocol option: " .. tostring(key))
			assert(finite(value), "Protocol limits must be finite numbers")
			if string.find(key, "Burst", 1, true) then
				assert(value >= 1 and value % 1 == 0, "Protocol bursts must be positive integers")
			else
				assert(value >= 0, "Protocol rates cannot be negative")
			end
			(limits :: any)[key] = value
		end
	end
	return setmetatable({
		_limits = limits,
		_buckets = {} :: { [number]: Bucket? },
	}, Protocol)
end

-- nowMonotonic must come from the server, never the RemoteEvent payload.
function Protocol.check(self: Gate, userId: any, action: any, payload: any, nowMonotonic: any): (boolean, string)
	if not finite(userId) or userId % 1 ~= 0 or math.abs(userId) > MAX_SAFE_INTEGER then
		return false, "invalid_identity"
	end
	-- Negative/zero Studio user IDs are valid identities for local multiplayer tests.
	if not finite(nowMonotonic) or nowMonotonic < 0 then
		return false, "invalid_time"
	end
	local now: number = nowMonotonic
	local limits: Limits = self._limits
	local existing: Bucket? = self._buckets[userId]
	local bucket: Bucket
	if existing == nil then
		bucket = {
			lastTime = now,
			aggregate = limits.aggregateBurst,
			click = limits.clickBurst,
			control = limits.controlBurst,
		}
		self._buckets[userId] = bucket
	else
		bucket = existing
	end
	if now < bucket.lastTime then
		return false, "clock_rewind"
	end
	local elapsed = now - bucket.lastTime
	bucket.lastTime = now
	bucket.aggregate = math.min(limits.aggregateBurst, bucket.aggregate + elapsed * limits.aggregateRate)
	bucket.click = math.min(limits.clickBurst, bucket.click + elapsed * limits.clickRate)
	bucket.control = math.min(limits.controlBurst, bucket.control + elapsed * limits.controlRate)
	if bucket.aggregate < 1 then
		return false, "rate_limited"
	end
	-- Malformed and subtype-throttled requests also spend aggregate budget.
	bucket.aggregate -= 1
	local valid, reason = validatePayload(action, payload)
	if not valid then
		return false, reason
	end
	if action == "click" then
		if bucket.click < 1 then
			return false, "rate_limited"
		end
		bucket.click -= 1
	else
		if bucket.control < 1 then
			return false, "rate_limited"
		end
		bucket.control -= 1
	end
	return true, "ok"
end

function Protocol.forget(self: Gate, userId: number)
	self._buckets[userId] = nil
end

Protocol.validate = validatePayload

return Protocol
