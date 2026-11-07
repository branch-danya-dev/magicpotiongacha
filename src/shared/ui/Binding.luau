--!strict
-- Turns an existing snapshot into display values. This module never sends an intent.
local Binding = {}

export type Resources = { gold: number, essence: number, goldText: string, essenceText: string }
export type Card = { title: string, body: string }
export type Demo = { gold: number, essence: number, progress: number, cards: { Card } }

local function amount(value: any): number
	if type(value) ~= "number" or value ~= value or value >= math.huge or value <= -math.huge then
		return 0
	end
	return math.floor(value)
end

function Binding.text(value: any): string
	local count = math.abs(amount(value))
	local body = tostring(count)
	if count >= 1000 then
		local scaled = count
		local unit = ""
		for _, name in ipairs({ "K", "M", "B" }) do
			if scaled < 1000 then
				break
			end
			scaled /= 1000
			unit = name
		end
		body = string.format("%.2f", scaled)
		body = string.gsub(body, "0+$", "")
		body = string.gsub(body, "%.$", "")
		body ..= unit
	end
	if type(value) == "number" and value < 0 then
		return "-" .. body
	end
	return body
end

function Binding.resources(snapshot: any): Resources
	local gold = 0
	local essence = 0
	if type(snapshot) == "table" then
		gold = amount(snapshot.gold)
		essence = amount(snapshot.essence)
	end
	return { gold = gold, essence = essence, goldText = Binding.text(gold), essenceText = Binding.text(essence) }
end

function Binding.demo(): Demo
	return {
		gold = 1000,
		essence = 40,
		progress = 0.62,
		cards = {
			{ title = "Ink vial", body = "Чернила для спокойной варки." },
			{ title = "Quiet salt", body = "A measured pinch, nothing more." },
			{ title = "Familiar note", body = "Один спутник на этот цикл." },
		},
	}
end

return Binding
