--!nonstrict
local Config = require("../src/shared/Config")
local Factory = require("../src/shared/Factory")
local Collection = require("../src/shared/Collection")
local ProfileStore = require("../src/server/ProfileStore")
local H = {}
function H.copy(v)
	if type(v) ~= "table" then return v end
	local r = {}; for k, x in pairs(v) do r[k] = H.copy(x) end; return r
end
function H.count(v) local n = 0; for _ in pairs(v) do n += 1 end; return n end
function H.new()
	local h = { now = 100000, draws = 0, calls = 0, revisionWrites = 0, beforeFailures = 0, afterFailures = 0 }
	h.engine, h.collection = Factory.new(Config), Collection.new(Config)
	h.profile = h.engine.newProfile(123, h.now)
	-- Funding is ONLY for isolated command/failure fixtures. F2P scenarios use earned income.
	h.profile.gold, h.profile.essence = 100000, 100000
	function h.context(preview)
		return { now = h.now, preview = preview, policy = { status = "unrestricted", randomAllowed = true, expiresAt = h.now + 60 },
			nextInteger = function(lo, hi) h.draws += 1; return h.highRoll and hi or lo end }
	end
	function h.apply(action, payload, context, profile)
		h.now += 1
		profile = profile or h.profile
		payload = H.copy(payload or {}); payload.requestId = payload.requestId or profile.collection.sequence + 1
		context = context or h.context(); context.now = h.now
		return h.collection.apply(profile, action, payload, context)
	end
	function h.buyFive(species)
		local ids = {}
		for _ = 1, 5 do
			local ok, result = h.apply("shopFamiliar", { offerId = species })
			assert(ok, result); table.insert(ids, result.createdIds[1])
		end
		return ids
	end
	function h.preview(ids)
		local preview, reason = h.collection.preview(h.profile, ids); assert(preview, reason)
		preview.token, preview.expiresAt = "server-preview", h.now + 60
		return preview
	end
	local backend = {}
	function backend:UpdateAsync(_, transform)
		h.calls += 1
		if h.beforeFailures > 0 then h.beforeFailures -= 1; error("request failed before write") end
		if h.beforeUpdate then h.beforeUpdate() end
		for _ = 1, (h.replays or 0) do transform(H.copy(h.record)) end
		local nextRecord = transform(H.copy(h.record))
		if nextRecord then
			if not h.record or nextRecord.revision ~= h.record.revision then h.revisionWrites += 1 end
			h.record = H.copy(nextRecord)
		end
		if h.afterFailures > 0 then h.afterFailures -= 1; error("response lost after write") end
		return H.copy(nextRecord)
	end
	function h.store(owner)
		return ProfileStore.new({ dataStore = backend, owner = owner or "A", now = function() return h.now end,
			validate = h.engine.validate, migrate = h.engine.migrate, sleep = function(seconds)
				if h.sleep then h.sleep(seconds) else h.now += seconds end
			end })
	end
	return h
end
return H
