--!strict
-- Pure authorization checks used by World with server-owned identity/positions.
local Access = {}

function Access.target(action: string, payload: any): string?
	if action == "click" then return "crystal" end
	if action == "buy" then return payload.upgradeId == "pipes" and "warehouse" or payload.upgradeId end
	if action == "hire" or action == "discard" then return "warehouse" end
	if action == "acceptOrder" or action == "claimOrder" then return "orders" end
	if action == "assign" or action == "harvest" or action == "collect" or action == "load"
		or action == "brew" or action == "setRecipe" or action == "setAuto" then return payload.stationId end
	return nil
end

function Access.allowed(ownerMatches: boolean, alive: boolean, distance: number, maximum: number): boolean
	return ownerMatches == true and alive == true and distance == distance and distance >= 0
		and maximum == maximum and maximum > 0 and maximum < math.huge and distance <= maximum
end

return Access
