--!strict
local Protocol = require("../src/shared/Protocol")

return function(T: any)
	local function check(action: any, payload: any): (boolean, string)
		return Protocol.new():check(123, action, payload, 100)
	end

	local cases = {
		{ "click", {} },
		{ "assign", { stationId = "garden", petId = "starter-farmer" } },
		{ "assign", { stationId = "garden", petId = "" } },
		{ "harvest", { stationId = "mine" } },
		{ "collect", { stationId = "garden" } },
		{ "load", { stationId = "cauldron" } },
		{ "brew", { stationId = "cauldron" } },
		{ "setRecipe", { stationId = "distillery", recipeId = "fire_extract" } },
		{ "setAuto", { stationId = "cauldron", enabled = true } },
		{ "setAuto", { stationId = "cauldron", enabled = false } },
		{ "buy", { upgradeId = "warehouse" } },
		{ "hire", { speciesId = "farmer" } },
		{ "discard", { itemId = "slime", amount = 10 } },
		{ "acceptOrder", { orderId = "healing-order" } },
		{ "claimOrder", {} },
	}
	for i, case in ipairs(cases) do
		T.test("protocol: valid exact payload " .. tostring(i) .. " / " .. tostring(case[1]), function()
			local ok, reason = check(case[1], case[2])
			T.truthy(ok, reason)
		end)
	end

	T.test("protocol: rejects unknown action", function()
		local ok, reason = check("grantGold", {})
		T.falsy(ok)
		T.equal(reason, "invalid_action")
	end)

	T.test("protocol: rejects non-string action", function()
		T.falsy(check({}, {}))
		T.falsy(check(7, {}))
		T.falsy(check(nil, {}))
	end)

	T.test("protocol: rejects nil and non-table payload", function()
		T.falsy(check("click", nil))
		T.falsy(check("click", true))
		T.falsy(check("click", "{}"))
		T.falsy(check("click", 0))
	end)

	T.test("protocol: rejects forged economic fields", function()
		T.falsy(check("click", { amount = 1000000 }))
		T.falsy(check("buy", { upgradeId = "mine", price = 0 }))
		T.falsy(check("hire", { speciesId = "farmer", cost = 0 }))
		T.falsy(check("assign", { stationId = "garden", petId = "x", targetUserId = 456 }))
	end)

	T.test("protocol: rejects missing fields", function()
		T.falsy(check("setRecipe", { stationId = "cauldron" }))
		T.falsy(check("assign", { stationId = "garden" }))
		T.falsy(check("setAuto", { stationId = "cauldron" }))
	end)

	T.test("protocol: rejects nested values and functions", function()
		T.falsy(check("buy", { upgradeId = { "mine" } }))
		T.falsy(check("brew", { stationId = function() return "cauldron" end }))
		T.falsy(check("setAuto", { stationId = "cauldron", enabled = {} }))
	end)

	T.test("protocol: boolean values are not coerced", function()
		T.falsy(check("setAuto", { stationId = "cauldron", enabled = 1 }))
		T.falsy(check("setAuto", { stationId = "cauldron", enabled = "true" }))
		T.falsy(check("setAuto", { stationId = "cauldron", enabled = "false" }))
	end)

	T.test("protocol: numeric values cannot replace opaque identifiers", function()
		T.falsy(check("buy", { upgradeId = 0 / 0 }))
		T.falsy(check("brew", { stationId = math.huge }))
		T.falsy(check("click", { amount = -math.huge }))
	end)

	T.test("protocol: discard amount must be a bounded positive integer", function()
		T.truthy(check("discard", { itemId = "slime", amount = 1 }))
		T.truthy(check("discard", { itemId = "slime", amount = 1000000 }))
		for _, amount in ipairs({ 0, -1, 1.5, 1000001, 0 / 0, math.huge, -math.huge, "1", true, {} }) do
			T.falsy(check("discard", { itemId = "slime", amount = amount }))
		end
		T.falsy(check("discard", { itemId = "slime" }))
		T.falsy(check("discard", { itemId = "slime", amount = 1, targetUserId = 123 }))
	end)

	T.test("protocol: identifiers are bounded and nonblank", function()
		T.truthy(check("buy", { upgradeId = string.rep("a", 64) }))
		T.falsy(check("buy", { upgradeId = string.rep("a", 65) }))
		T.falsy(check("buy", { upgradeId = "" }))
		T.falsy(check("buy", { upgradeId = " " }))
		T.falsy(check("buy", { upgradeId = "mine\0" }))
		T.falsy(check("buy", { upgradeId = "../mine/" }))
	end)

	T.test("protocol: rejects numeric and array keys", function()
		T.falsy(check("click", { [1] = "a" }))
		T.falsy(check("buy", { upgradeId = "mine", [1] = "a" }))
	end)

	T.test("protocol: rejects metatable payload without invoking it", function()
		local touched = false
		local payload = setmetatable({}, { __index = function()
			touched = true
			return "mine"
		end })
		T.falsy(check("buy", payload))
		T.falsy(touched)
	end)

	T.test("protocol: rejects invalid server identity and clock", function()
		local gate = Protocol.new()
		for _, id in ipairs({ 0 / 0, math.huge, -math.huge, 1.5, 9007199254740992 }) do
			T.falsy(gate:check(id, "click", {}, 0))
		end
		T.falsy(gate:check("123", "click", {}, 0))
		T.falsy(gate:check(123, "click", {}, -1))
		T.falsy(gate:check(123, "click", {}, math.huge))
		T.falsy(gate:check(123, "click", {}, 0 / 0))
		T.truthy(gate:check(123, "click", {}, 0))
	end)

	T.test("protocol: permits Studio test identities", function()
		T.truthy(Protocol.new():check(-1, "click", {}, 0))
		T.truthy(Protocol.new():check(0, "click", {}, 0))
	end)

	T.test("protocol: click burst then time-based replenishment", function()
		local gate = Protocol.new()
		for _ = 1, 8 do
			T.truthy(gate:check(123, "click", {}, 0))
		end
		T.falsy(gate:check(123, "click", {}, 0))
		T.falsy(gate:check(123, "click", {}, 0.1))
		T.truthy(gate:check(123, "click", {}, 0.125))
		T.falsy(gate:check(123, "click", {}, 0.125))
	end)

	T.test("protocol: control burst then time-based replenishment", function()
		local gate = Protocol.new()
		for _ = 1, 10 do
			T.truthy(gate:check(123, "collect", { stationId = "garden" }, 0))
		end
		T.falsy(gate:check(123, "collect", { stationId = "garden" }, 0))
		T.truthy(gate:check(123, "collect", { stationId = "garden" }, 0.2))
	end)

	T.test("protocol: invalid traffic consumes aggregate budget", function()
		local gate = Protocol.new()
		for _ = 1, 30 do
			T.falsy(gate:check(123, "notAnAction", {}, 0))
		end
		local ok, reason = gate:check(123, "click", {}, 0)
		T.falsy(ok)
		T.equal(reason, "rate_limited")
		T.truthy(gate:check(123, "click", {}, 0.05))
	end)

	T.test("protocol: aggregate limit combines click and controls", function()
		local gate = Protocol.new({ aggregateBurst = 3, aggregateRate = 0 })
		T.truthy(gate:check(123, "click", {}, 0))
		T.truthy(gate:check(123, "claimOrder", {}, 0))
		T.truthy(gate:check(123, "click", {}, 0))
		T.falsy(gate:check(123, "claimOrder", {}, 100))
	end)

	T.test("protocol: rewind is rejected without refilling", function()
		local gate = Protocol.new()
		for _ = 1, 8 do
			T.truthy(gate:check(123, "click", {}, 10))
		end
		local ok, reason = gate:check(123, "click", {}, 5)
		T.falsy(ok)
		T.equal(reason, "clock_rewind")
		T.falsy(gate:check(123, "click", {}, 10))
		T.truthy(gate:check(123, "click", {}, 10.125))
	end)

	T.test("protocol: budgets are isolated per player", function()
		local gate = Protocol.new()
		for _ = 1, 8 do
			T.truthy(gate:check(123, "click", {}, 0))
		end
		T.falsy(gate:check(123, "click", {}, 0))
		T.truthy(gate:check(456, "click", {}, 0))
	end)

	T.test("protocol: forget releases state for a new session", function()
		local gate = Protocol.new()
		for _ = 1, 8 do
			T.truthy(gate:check(123, "click", {}, 0))
		end
		gate:forget(123)
		T.truthy(gate:check(123, "click", {}, 0))
	end)

	T.test("protocol: long idle never accumulates beyond burst", function()
		local gate = Protocol.new()
		T.truthy(gate:check(123, "click", {}, 0))
		for _ = 1, 8 do
			T.truthy(gate:check(123, "click", {}, 1000000))
		end
		T.falsy(gate:check(123, "click", {}, 1000000))
	end)

	T.test("protocol: never mutates caller payload", function()
		local payload = { stationId = "garden", petId = "starter-farmer" }
		local before = table.clone(payload)
		T.truthy(check("assign", payload))
		T.same(payload, before)
	end)

	T.test("protocol: invalid configuration fails early", function()
		T.throws(function() Protocol.new({ clickBurst = 0 }) end)
		T.throws(function() Protocol.new({ clickRate = -1 }) end)
		T.throws(function() Protocol.new({ aggregateRate = 0 / 0 }) end)
		T.throws(function() Protocol.new({ controlBurst = 1.5 }) end)
	end)
end
