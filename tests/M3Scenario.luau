--!nonstrict
-- All balances/materials/workers are earned through validated intents; no fixture grants.
local Config=require("../src/shared/Config")
local Collection=require("../src/shared/Collection")
local Progression=require("../src/shared/Progression")
local Protocol=require("../src/shared/Protocol")
local Epochs=require("../src/shared/Epochs")
local firstCycle=require("./Scenarios")
return function(strategy,initial)
	local first=firstCycle(strategy=="manual" and "manual" or (strategy=="detour" and "detour" or "automation"),nil,initial)
	local e,p,now=first.engine,first.profile,first.now
	local epoch=Epochs.rules(Config,p); local epochId=Epochs.id(p)
	local collection,progression,gate=Collection.new(Config),Progression.new(Config),Protocol.new()
	local spent=Epochs.cost(Config,p,Config.pipesCost)+Epochs.cost(Config,p,Config.stations.crystal.upgradeCosts[2])
		+(strategy=="detour" and Epochs.cost(Config,p,Config.stations.garden.upgradeCosts[2]) or 0)
	local earned,clicks,harvests,discards=p.gold+spent,first.clicks,first.harvests,0
	local phases={}; local start=first.start
	local function waitFor(seconds)
		now+=seconds; local report=e.advance(p,now,false); assert(report.ok,report.error)
		earned+=report.goldEarned; assert(e.validate(p)); return report
	end
	local function intent(action,payload)
		waitFor(1); payload=payload or {}
		assert(gate:check(p.userId,action,payload,now))
		local before=p.gold; local ok,result=e.act(p,action,payload,now)
		assert(ok or (action=="collect" and result=="Nothing to collect or storage is full"),action..": "..tostring(result))
		earned+=math.max(0,p.gold-before); spent+=math.max(0,before-p.gold)
		if action=="click" then clicks+=1 elseif action=="harvest" then harvests+=1 elseif action=="discard" then discards+=1 end
		assert(e.validate(p)); return result
	end
	local function durable(action,payload)
		waitFor(1); payload.requestId=Progression.isAction(action) and p.progression.sequence+1 or p.collection.sequence+1
		assert(gate:check(p.userId,action,payload,now))
		local before=p.gold; local ok,result
		if Progression.isAction(action) then ok,result=progression.apply(p,action,payload,e,now)
		else ok,result=collection.apply(p,action,payload,{now=now,policy={status=strategy=="automation" and "unavailable" or "restricted",randomAllowed=false,expiresAt=now+60},nextInteger=function() error("No familiar luck allowed") end}) end
		assert(ok,action..": "..tostring(result)); spent+=math.max(0,before-p.gold); assert(e.validate(p)); return result
	end
	local function waitUntil(predicate,limit,label)
		for _=1,limit do if predicate() then return end; waitFor(1) end
		assert(predicate(),"Timeout: "..label)
	end
	local function room()
		for _,kind in ipairs({"raw","intermediate"}) do
			local capacity=Config.warehouse[kind=="raw" and "rawCapacity" or "intermediateCapacity"][p.warehouseLevel+1]
			local total=0; for id,amount in pairs(p.inventory) do if Config.items[id].kind==kind then total+=amount end end
			if total>capacity-20 then
				local ids={}; for id in pairs(p.inventory) do if Config.items[id].kind==kind then table.insert(ids,id) end end
				table.sort(ids,function(a,b) return (p.inventory[a] or 0)==(p.inventory[b] or 0) and a<b or (p.inventory[a] or 0)>(p.inventory[b] or 0) end)
				for _,id in ipairs(ids) do
					local discard=math.min(math.max(0,(p.inventory[id] or 0)-3),total-(capacity-20))
					if discard>0 then intent("discard",{itemId=id,amount=discard}); total-=discard end
				end
			end
		end
	end
	local function stop(slot)
		if p.stations[slot].auto then intent("setAuto",{stationId=slot,enabled=false}) end
		waitUntil(function() return not p.stations[slot].job end,120,"finish "..slot)
	end
	local function selectRecipe(slot,recipe)
		stop(slot)
		if p.stations[slot].recipeId~=recipe then room(); intent("setRecipe",{stationId=slot,recipeId=recipe}) end
	end
	local craft
	local producers={fire_extract="distillery",spore_paste="press",berry_essence="distillery2",aether_serum="centrifuge",
		steam_catalyst="distillery",gear_oil="press",pressure_essence="centrifuge",void_plasma="distillery",antimatter="press",chrono_serum="centrifuge"}
	local function material(item,amount)
		for _=1,100 do
			if (p.inventory[item] or 0)>=amount then return end
			room()
			if producers[item] then
				craft(item,producers[item]); intent("collect",{stationId=producers[item]})
			elseif item=="slime" then waitUntil(function() return (p.inventory.slime or 0)>=amount end,1800,"deployed slime byproduct")
			else
				local source
				for _,id in ipairs(Config.sourceOrder) do if Config.stations[id].outputItem==item and p.stations[id].level>0 then source=id; break end end
				assert(source,"No source for "..item)
				if p.manualReadyAt[source]>now then waitFor(p.manualReadyAt[source]-now) end
				intent("harvest",{stationId=source})
			end
		end
		error("Cannot supply "..item)
	end
	craft=function(recipeId,slot)
		selectRecipe(slot,recipeId); local recipe=Config.recipes[recipeId]; local station=p.stations[slot]
		local inputIds={}; for item in pairs(recipe.inputs) do table.insert(inputIds,item) end; table.sort(inputIds)
		for _=1,100 do
			local ready=station.essence>=recipe.essenceCost
			for _,item in ipairs(inputIds) do
				local amount=recipe.inputs[item]
				local missing=amount-(station.input[item] or 0)
				if missing>0 then ready=false; material(item,missing) end
			end
			if ready then break end
			while p.essence+station.essence<recipe.essenceCost do intent("click") end
			waitFor(1)
			local ok,reason=e.act(p,"load",{stationId=slot},now)
			assert(ok or reason=="No ingredients or Essence to load",reason)
		end
		intent("brew",{stationId=slot})
		waitUntil(function() return not station.job end,120,"manual "..recipeId)
		assert(p.discoveredRecipes[recipeId])
	end
	local function income(cost)
		for _=1,1000 do
			if p.gold>=cost then return end
			room()
			if strategy=="manual" then craft("healing","cauldron")
			else
				if p.stations.cauldron.recipeId~="healing" then selectRecipe("cauldron","healing") end
				if not p.stations.cauldron.auto then intent("setAuto",{stationId="cauldron",enabled=true}) end
				waitFor(30)
			end
		end
		error("Income stalled for "..cost)
	end
	local function build(id)
		local state=progression.buildState(p,id); assert(state.available,state.reason); income(state.cost)
		durable("build",{upgradeId=id,expectedLevel=state.level})
	end
	local function phase()
		income(progression.phaseState(p).cost); durable("advancePhase",{expectedPhase=p.phase})
		table.insert(phases,{phase=p.phase,seconds=now-start,clicks=clicks,harvests=harvests,income=earned,spent=spent,gold=p.gold})
	end
	local function worker(slot,species)
		if p.stations[slot].workerId then return end
		if initial then
			local assigned={}; for _,station in pairs(p.stations) do if station.workerId then assigned[station.workerId]=true end end
			local ids={}; for id,pet in pairs(p.pets) do if pet.species==species and not assigned[id] then table.insert(ids,id) end end
			table.sort(ids); if ids[1] then intent("assign",{stationId=slot,petId=ids[1]}); return end
		end
		income(Config.familiarShop[species].cost)
		local pet=durable("shopFamiliar",{offerId=species}).createdIds[1]
		intent("assign",{stationId=slot,petId=pet})
	end
	if strategy=="manual" then stop("cauldron") end
	if strategy=="detour" then
		local gold,sequence=p.gold,p.progression.sequence
		local ok=progression.apply(p,"advancePhase",{expectedPhase=4,requestId=sequence+1},e,now)
		assert(not ok and p.gold==gold and p.progression.sequence==sequence)
		stop("cauldron"); waitFor(1800); room() -- Real output fills storage; explicit disposal recovers it.
		intent("assign",{stationId="garden",petId=""}); waitFor(120)
		intent("assign",{stationId="garden",petId="-1:starter_farmer"})
		intent("setAuto",{stationId="cauldron",enabled=true})
	end
	phase(); build("garden2"); build("cauldron2"); build("distillery2")
	build("mine"); build("distillery"); build("cauldron"); build("warehouse")
	if epochId==0 then craft("fire_extract","distillery"); craft("rage","cauldron")
	else craft(epoch.phaseRecipes[3][1],"distillery") end
	phase(); build("mushrooms"); build("berries"); build("press"); build("cauldron2")
	if epochId==0 then craft("focus","cauldron2"); craft("flare","cauldron2")
	else craft(epoch.phaseRecipes[4][1],"press"); craft(epoch.phaseRecipes[4][2],"cauldron2") end
	phase(); build("centrifuge"); build("cauldron2"); build("crystal"); build("logistics"); build("warehouse")
	craft(epoch.finalRecipe,"cauldron2")
	local completeAt=now-start; assert(progression.phaseState(p).complete)
	-- Finish with multiple staffed lines, using exact fixed workers only.
	for _,slot in ipairs({"mine","garden2","mushrooms","berries"}) do worker(slot,"farmer") end
	for _,slot in ipairs({"distillery","distillery2","press","centrifuge","cauldron2"}) do worker(slot,"brewer") end
	local recipes={distillery="fire_extract",distillery2="berry_essence",press="spore_paste",centrifuge="aether_serum",cauldron="focus",cauldron2="ascension"}
	if epochId~=0 then recipes={distillery=epoch.phaseRecipes[3][1],distillery2="berry_essence",press=epoch.phaseRecipes[4][1],
		centrifuge=epochId==1 and "pressure_essence" or "chrono_serum",cauldron="healing",cauldron2=epoch.finalRecipe} end
	for _,slot in ipairs(Config.machineOrder) do
		selectRecipe(slot,recipes[slot]); intent("setAuto",{stationId=slot,enabled=true})
	end
	room(); local setupAt=now-start; local report=waitFor(1200)
	assert((report.sold[epoch.finalRecipe] or 0)>0 and (report.sold[recipes.cauldron] or 0)>0,"Parallel late-game lines must sell")
	assert(p.gold==earned-spent,"Gold accounting must reconcile exactly")
	return {profile=p,engine=e,now=now,epoch=epochId,phases=phases,completeAt=completeAt,setupAt=setupAt,clicks=clicks,harvests=harvests,discards=discards,
		income=earned,spent=spent,finalSales=report.sold,seconds=now-start}
end
