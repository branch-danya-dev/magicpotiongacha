--!strict
-- Ephemeral presentation receipt, never part of a profile or an economy intent.
local Feedback = {}
function Feedback.accept(sequence: number?, action: string, success: boolean): number
	local current = sequence or 0
	return if action == "click" and success and current < 9007199254740991 then current + 1 else current
end
function Feedback.consume(previous: number?, receipt: any, ownedPlot: number?): (number?, boolean)
	if type(receipt) ~= "table" then return previous, false end
	local n = receipt.sequence
	if type(n) ~= "number" or n ~= n or n < 0 or n > 9007199254740991 or n % 1 ~= 0 then return previous, false end
	-- Initial state seeds the cursor. Old/replayed snapshots never rewind it.
	if previous == nil then return n, false end
	if n <= previous then return previous, false end
	return n, ownedPlot ~= nil and receipt.plotIndex == ownedPlot
end
return Feedback
