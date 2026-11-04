--!nonstrict
-- No seeded money, materials or pets: all progress uses M1/M2 player intents.
local Config=require("../src/shared/Config")
local Collection=require("../src/shared/Collection")
local Protocol=require("../src/shared/Protocol")
local scenario=require("./Scenarios")
return function(policyStatus)
	local first=scenario("automation")
	local e,p,now=first.engine,first.profile,first.now
	local collection,gate=Collection.new(Config),Protocol.new()
	local function waitFor(seconds)
		now+=seconds; local report=e.advance(p,now,false); assert(report.ok,report.error)
		local valid,reason=e.validate(p); assert(valid,reason); return report
	end
	local function intent(action,payload)
		waitFor(1); payload=payload or {}
		if action=="buy" then
			local id=payload.upgradeId; payload.expectedLevel=id=="warehouse" and p.warehouseLevel or p.stations[id].level
		end
		local allowed,reason=gate:check(p.userId,action,payload,now); assert(allowed,reason)
		local ok,message=e.act(p,action,payload,now); assert(ok,action..": "..tostring(message))
		assert(e.validate(p))
	end
	local function untilReady(predicate,limit,label)
		for _=1,limit do if predicate() then return end; waitFor(1) end
		assert(predicate(),"Timed out: "..label)
	end
	local function command(action,payload,preview)
		waitFor(1); payload.requestId=p.collection.sequence+1
		assert(gate:check(p.userId,action,payload,now))
		local ok,result=collection.apply(p,action,payload,{now=now,preview=preview,
			policy={status=policyStatus,randomAllowed=false,expiresAt=now+60},
			nextInteger=function() error("F2P path must never draw a familiar") end})
		assert(ok,result); assert(e.validate(p)); return result
	end
	local function buyPet(id)
		untilReady(function() return p.gold>=Config.familiarShop[id].cost end,3600,"earn "..id)
		return command("shopFamiliar",{offerId=id}).createdIds[1]
	end
	local ids={}; for _=1,5 do table.insert(ids,buyPet("slime")) end
	local preview=collection.preview(p,ids); assert(preview)
	preview.token,preview.expiresAt="reviewed-five-ids",now+60
	local evolved=command("fuse",{petIds=ids,previewToken=preview.token,confirmed=true},preview).createdIds[1]
	local evolvedAt=now-first.start
	intent("assign",{stationId="logistics",petId=evolved})
	local function upgrade(id)
		local cost=id=="warehouse" and Config.warehouse.upgradeCosts[p.warehouseLevel+1] or Config.stations[id].upgradeCosts[p.stations[id].level+1]
		untilReady(function() return p.gold>=cost end,3600,"earn upgrade "..id)
		intent("buy",{upgradeId=id})
	end
	upgrade("mine"); upgrade("distillery"); upgrade("cauldron"); upgrade("warehouse")
	intent("assign",{stationId="mine",petId=buyPet("farmer")})
	intent("assign",{stationId="distillery",petId=buyPet("brewer")})
	untilReady(function() return (p.stations.distillery.input.coal or 0)>=2 and p.stations.distillery.essence>=5 end,600,"Fire Extract inputs")
	intent("brew",{stationId="distillery"})
	untilReady(function() return p.discoveredRecipes.fire_extract end,60,"manual Fire Extract")
	intent("setAuto",{stationId="distillery",enabled=true})
	intent("setAuto",{stationId="cauldron",enabled=false})
	untilReady(function() return not p.stations.cauldron.job end,60,"finish Healing")
	-- Returning loaded ingredients uses the same capacity rules as the UI.
	if (p.inventory.mandrake or 0)>30 then intent("discard",{itemId="mandrake",amount=30}) end
	intent("setRecipe",{stationId="cauldron",recipeId="rage"})
	untilReady(function()
		local station=p.stations.cauldron
		return (station.input.mandrake or 0)>=2 and (station.input.fire_extract or 0)>=1 and (station.input.slime or 0)>=1 and station.essence>=8
	end,1800,"Rage ingredients including existing production slime")
	intent("brew",{stationId="cauldron"})
	untilReady(function() return p.discoveredRecipes.rage end,60,"manual Rage")
	local rageAt=now-first.start
	intent("setAuto",{stationId="cauldron",enabled=true})
	local goldBefore=p.gold; local report=waitFor(1200)
	assert((report.sold.rage or 0)>0 and p.gold>goldBefore,"Autonomous Rage must sell")
	return {engine=e,profile=p,now=now,evolvedAt=evolvedAt,rageAt=rageAt,automaticRage=report.sold.rage,
		gold=p.gold,essence=p.essence,evolved=evolved}
end
