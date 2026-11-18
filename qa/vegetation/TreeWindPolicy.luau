--!strict
-- Shared wind budgets and rig response. Pure math: no time/environment owner.
local M = {}
M.caps = {full = 20, reduced = 12, minimal = 6}
M.roles = {
	Root = {strength = 0, delay = 0},
	Trunk = {strength = .12, delay = 0},
	Branch = {strength = .65, delay = .10},
	Foliage = {strength = 1, delay = .24},
	Extras = {strength = .65, delay = .10},
}

function M.strength(value: any): number
	if value == nil then return 1 end
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return 0 end
	return math.clamp(value, 0, 1.5)
end

function M.rate(budget: any, distance: number): number
	if distance ~= distance or distance < 0 or distance > budget.distance then return 0 end
	-- Same near budget as Willow V2; middle/far tiers reduce bone writes.
	if distance > budget.distance * .7 then return math.max(2, budget.hz / 3) end
	if distance > budget.distance * .35 then return math.max(3, budget.hz / 2) end
	return budget.hz
end

function M.select(candidates: {any}, quality: string): {any}
	assert(M.caps[quality], "Unknown tree quality")
	local sorted:{any} = {}
	for _,v in ipairs(candidates) do
		if v.distance >= 0 and M.rate(v.budget, v.distance) > 0 then table.insert(sorted, v) end
	end
	table.sort(sorted, function(a:any,b:any)
		if a.distance == b.distance then return a.id < b.id end
		return a.distance < b.distance
	end)
	local chosen:{any} = {}
	local speciesCounts:{[string]:number} = {}
	for _,v in ipairs(sorted) do
		local n = speciesCounts[v.species] or 0
		if #chosen < M.caps[quality] and n < v.budget.trees then
			table.insert(chosen,v)
			speciesCounts[v.species] = n + 1
		end
	end
	return chosen
end

return M
