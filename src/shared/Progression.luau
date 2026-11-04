--!nonstrict
-- Pure construction/equipment rules. Runtime commits this candidate before acknowledgement.
local runtimeScript=rawget(getfenv(),"script")
local Protocol=require(runtimeScript and runtimeScript.Parent.Protocol or "./Protocol")
local Progression={}
local actions={build=true,advancePhase=true,equipCauldron=true,lockCauldron=true}
local function integer(v,lo,hi) return type(v)=="number" and v==v and v%1==0 and v>=lo and v<=hi end
local function plain(v) return type(v)=="table" and getmetatable(v)==nil end
local function id(v) return type(v)=="string" and #v>0 and #v<=80 end
local function fingerprint(action,payload)
	local keys={}; for k in pairs(payload) do table.insert(keys,k) end; table.sort(keys)
	local parts={action}; for _,k in ipairs(keys) do table.insert(parts,k.."="..tostring(payload[k])) end
	return table.concat(parts,"|")
end
function Progression.isAction(action) return actions[action]==true end
function Progression.new(config)
	local service={}
	function service.buildState(p,slotId)
		if slotId=="pipes" then return {available=not p.pipes,cost=config.pipesCost,reason=p.pipes and "Pipes already built" or "",level=p.pipes and 1 or 0} end
		local def=slotId=="warehouse" and config.warehouse or config.stations[slotId]
		if not def then return {available=false,reason="Unknown fixed slot"} end
		local level=slotId=="warehouse" and p.warehouseLevel or p.stations[slotId].level
		local cost=def.upgradeCosts[level+1]
		local phase=def.tierPhases and def.tierPhases[level+1] or def.phase or 1
		local reason=not cost and "Maximum tier" or (p.phase<phase and ("Requires phase "..phase) or "")
		return {available=reason=="",reason=reason,cost=cost,level=level,requiredPhase=phase}
	end
	function service.phaseState(p)
		local nextPhase=config.phases[p.phase+1]; local reasons={}
		if nextPhase then
			for _,recipe in ipairs(nextPhase.recipes) do if not p.discoveredRecipes[recipe] then table.insert(reasons,"Discover "..config.recipes[recipe].name) end end
			for station,level in pairs(nextPhase.stations) do if p.stations[station].level<level then table.insert(reasons,config.stations[station].name.." tier "..level) end end
			if nextPhase.pipes and not p.pipes then table.insert(reasons,"Build pipes") end
			if nextPhase.warehouse and p.warehouseLevel<nextPhase.warehouse then table.insert(reasons,"Warehouse level "..nextPhase.warehouse) end
			if p.gold<nextPhase.cost then table.insert(reasons,"Need "..nextPhase.cost.." Gold") end
		end
		table.sort(reasons)
		local completed=p.phase==4 and p.discoveredRecipes.ascension==true
		return {phase=p.phase,name=config.phases[p.phase].name,nextName=nextPhase and nextPhase.name,cost=nextPhase and nextPhase.cost,
			available=nextPhase~=nil and #reasons==0,reasons=reasons,complete=completed,
			message=completed and "M3 завершён; Rebirth появится позже" or (p.phase==4 and "Изготовь Ascension: финальная технология M3" or "Открой следующую фазу")}
	end
	function service.validate(p)
		if not integer(p.phase,1,4) or not plain(p.progression) or not integer(p.progression.sequence,0,config.maxBalance)
			or not plain(p.cauldrons) or not integer(p.nextCauldronSerial,1,config.maxCount) then return false end
		local last=p.progression.last
		if p.progression.sequence==0 then if last~=nil then return false end
		elseif not plain(last) or last.requestId~=p.progression.sequence or not id(last.action) or not actions[last.action]
			or type(last.fingerprint)~="string" or #last.fingerprint>512 or #last.fingerprint<1
			or not plain(last.result) or type(last.result.message)~="string" or #last.result.message>256 then return false end
		local count=0
		for key,item in pairs(p.cauldrons) do
			count+=1; local def=plain(item) and config.cauldronTypes[item.type]
			if not id(key) or not def or item.id~=key or item.ownerId~=p.userId or item.bonus~=def.bonus
				or type(item.locked)~="boolean" or not plain(item.provenance) or item.provenance.source~="phase3"
				or type(item.provenance.paidDerived)~="boolean" then return false end
		end
		if count>16 then return false end
		local equipped={}
		for slotId,station in pairs(p.stations) do
			local itemId=station.cauldronId
			if itemId~=nil then
				if not p.cauldrons[itemId] or equipped[itemId] or config.stations[slotId].archetype~="cauldron" or station.level==0 then return false end
				equipped[itemId]=true
			end
			local def=config.stations[slotId]
			if station.level>0 and def.tierPhases and p.phase<def.tierPhases[station.level] then return false end
		end
		return true
	end
	function service.apply(p,action,payload,engine,now)
		if p.trade and p.trade.pending then return false,"Trade recovery pending" end
		if not actions[action] or not Protocol.validate(action,payload) then return false,"Invalid progression intent" end
		local progress=p.progression; local key=fingerprint(action,payload)
		if payload.requestId==progress.sequence and progress.last then
			if progress.last.fingerprint~=key then return false,"Request ID conflict" end
			return true,{message=progress.last.result.message,cauldronId=progress.last.result.cauldronId},true
		end
		if payload.requestId~=progress.sequence+1 or progress.sequence>=config.maxBalance then return false,"Stale progression request" end
		local result={message="Factory updated"}
		if action=="build" then
			local state=service.buildState(p,payload.upgradeId)
			if not state.available then return false,state.reason end
			if state.level~=payload.expectedLevel then return false,"Upgrade already changed" end
			local ok,reason=engine.act(p,"buy",{upgradeId=payload.upgradeId,expectedLevel=payload.expectedLevel},now)
			if not ok then return false,reason end
			result.message="Built/upgraded "..payload.upgradeId
		elseif action=="advancePhase" then
			if payload.expectedPhase~=p.phase then return false,"Phase already changed" end
			local state=service.phaseState(p)
			if not state.available then return false,#state.reasons>0 and table.concat(state.reasons,"; ") or "Final phase already built" end
			local nextPhase=p.phase+1
			local item
			if nextPhase==3 then
				local itemId=string.format("%.0f",p.userId)..":cauldron:"..p.nextCauldronSerial
				if p.nextCauldronSerial>=config.maxCount or p.cauldrons[itemId] then return false,"Cauldron identity conflict" end
				item={id=itemId,ownerId=p.userId,type="resonant",bonus=config.cauldronTypes.resonant.bonus,locked=false,provenance={source="phase3",paidDerived=false}}
			end
			p.gold-=config.phases[nextPhase].cost; p.phase=nextPhase
			if item then p.cauldrons[item.id]=item; p.nextCauldronSerial+=1; result.cauldronId=item.id end
			result.message="Opened "..config.phases[nextPhase].name
		elseif action=="equipCauldron" then
			local slot=p.stations[payload.slotId]
			if not slot or config.stations[payload.slotId].archetype~="cauldron" or slot.level==0 then return false,"Choose a built cauldron slot" end
			if slot.job then return false,"Finish the paid batch before changing equipment" end
			if payload.cauldronId~="" then
				local item=p.cauldrons[payload.cauldronId]
				if not item or item.ownerId~=p.userId then return false,"Cauldron not owned" end
				for _,other in pairs(p.stations) do if other.cauldronId==item.id then return false,"Unequip this cauldron from its current slot first" end end
			end
			slot.cauldronId=payload.cauldronId~="" and payload.cauldronId or nil
			result.message="Cauldron equipment updated"
		elseif action=="lockCauldron" then
			local item=p.cauldrons[payload.cauldronId]
			if not item or item.ownerId~=p.userId then return false,"Cauldron not owned" end
			item.locked=payload.locked; result.message="Cauldron lock updated"
		end
		p.progression={sequence=payload.requestId,last={requestId=payload.requestId,action=action,fingerprint=key,result=result}}
		return true,result,false
	end
	return service
end
return Progression
