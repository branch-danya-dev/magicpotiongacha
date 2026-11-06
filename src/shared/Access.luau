--!strict
-- Pure authorization checks used by World with server-owned identity/positions.
local Access = {}

function Access.target(action: string, payload: any): string?
	if action=="buyEventGold" or action=="deliverPurchases" or action=="requestPurchase" or action=="refreshPurchases" then return "altar" end
	if action=="rebirth" or action=="buyRebirthPerk" or action=="chooseRebirthPet" or action=="claimDaily" or action=="claimCalendar" or action=="deliverCalendarPet" then return "blueprint" end
	if action == "advancePhase" then return "blueprint" end
	if action == "equipCauldron" then return payload.slotId end
	if action == "lockCauldron" then return "altar" end
	if action == "prioritize" then return payload.stationId end
	if action == "summon" or action == "shopFamiliar" or action == "petLock" or action == "previewFuse" or action == "fuse" or action == "refreshPolicy" then return "altar" end
	if action == "click" then return "crystal" end
	if action == "chooseStarter" then return "altar" end
	if action == "plantSeed" or action == "harvestCrop" then return "garden" end
	if action == "buySeed" then return "garden" end
	if action == "exchangeEssence" then return "crystal" end
	if action == "buyStarterStation" then return payload.stationId end
	if action == "buyAutomation" then return "cauldron" end
	if action == "buy" or action == "build" then return payload.upgradeId == "pipes" and "warehouse" or payload.upgradeId end
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
