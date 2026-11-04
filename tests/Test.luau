--!strict
-- Tiny dependency-free harness. Failed specs make the CLI exit nonzero.
local Test = {
	passed = 0,
	failed = 0,
	failures = {} :: { string },
}

local function describe(value: any): string
	if type(value) == "string" then
		return string.format("%q", value)
	end
	return tostring(value)
end

function Test.equal(actual: any, expected: any, message: string?)
	if actual ~= expected then
		error((message or "Values differ") .. ": expected " .. describe(expected) .. ", got " .. describe(actual), 2)
	end
end

function Test.truthy(value: any, message: string?)
	if not value then
		error(message or "Expected a truthy value", 2)
	end
end

function Test.falsy(value: any, message: string?)
	if value then
		error(message or "Expected a falsy value", 2)
	end
end

function Test.near(actual: number, expected: number, tolerance: number?, message: string?)
	if actual ~= actual or expected ~= expected or math.abs(actual - expected) > (tolerance or 1e-9) then
		error((message or "Numbers differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
	end
end

local function same(actual: any, expected: any, path: string, seen: { [any]: any })
	if type(actual) ~= type(expected) then
		error(path .. ": types differ (" .. type(actual) .. " vs " .. type(expected) .. ")", 3)
	end
	if type(expected) ~= "table" then
		Test.equal(actual, expected, path)
		return
	end
	if seen[expected] ~= nil then
		Test.equal(actual, seen[expected], path .. ": table references differ")
		return
	end
	seen[expected] = actual
	for key, value in pairs(expected) do
		same(actual[key], value, path .. "." .. tostring(key), seen)
	end
	for key in pairs(actual) do
		if expected[key] == nil then
			error(path .. ": unexpected key " .. tostring(key), 3)
		end
	end
end

function Test.same(actual: any, expected: any, message: string?)
	same(actual, expected, message or "root", {})
end

function Test.throws(callback: () -> (), message: string?)
	local ok = pcall(callback)
	if ok then
		error(message or "Expected an error", 2)
	end
end

function Test.test(name: string, callback: () -> ())
	local ok, failure = pcall(callback)
	if ok then
		Test.passed += 1
		print("PASS " .. name)
	else
		Test.failed += 1
		local description = name .. ": " .. tostring(failure)
		table.insert(Test.failures, description)
		print("FAIL " .. description)
	end
end

function Test.finish()
	print(string.format("\n%d passed; %d failed; %d total", Test.passed, Test.failed, Test.passed + Test.failed))
	if Test.failed > 0 then
		error("Regression suite failed:\n" .. table.concat(Test.failures, "\n"), 0)
	end
end

return Test
