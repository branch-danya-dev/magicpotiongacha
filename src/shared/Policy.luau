--!nonstrict
-- Server service adapter injects lookup/clock; tests inject deterministic results.
local Policy = {}
function Policy.allowed(state, now)
	return type(state) == "table" and state.status == "unrestricted" and state.randomAllowed == true
		and type(state.expiresAt) == "number" and state.expiresAt > now
end
function Policy.new(options)
	local cache, generations = {}, {}
	local nextGeneration = 0
	local service = {}
	function service.peek(key)
		local current = cache[key]
		if current and current.expiresAt > options.now() then return current end
		return { status = "unavailable", randomAllowed = false, tradingAllowed = false, expiresAt = 0 }
	end
	function service.get(key)
		local cached = cache[key]
		if cached and cached.expiresAt > options.now() then return cached end
		nextGeneration += 1
		local generation = nextGeneration
		generations[key] = generation
		local ok, result = pcall(options.lookup, key)
		local state = { status = "unavailable", randomAllowed = false, tradingAllowed = false, expiresAt = options.now() + options.ttl }
		if ok and type(result) == "table" and type(result.ArePaidRandomItemsRestricted) == "boolean" then
			state.status = result.ArePaidRandomItemsRestricted and "restricted" or "unrestricted"
			state.randomAllowed = not result.ArePaidRandomItemsRestricted
			state.tradingAllowed = result.IsPaidItemTradingAllowed == true
		end
		if generations[key] ~= generation then return service.peek(key) end
		cache[key] = state
		return state
	end
	function service.forget(key)
		cache[key] = nil
		generations[key] = nil -- Late lookup cannot revive a departed Player or retain its reference.
	end
	return service
end
return Policy
