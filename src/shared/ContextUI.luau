--!nonstrict
-- Pure presentation decisions. Server Access/World remain authoritative.
local UI={}
function UI.candidates(entries,userId,width,height,blocked)
	local result={}
	for _,e in ipairs(entries) do
		local overlaps=false
		for _,r in ipairs(blocked or {}) do
			if e.x+120>r.x and e.x-120<r.x+r.w and e.y+50>r.y and e.y-50<r.y+r.h then overlaps=true; break end
		end
		if e.enabled and e.visible and e.clear and (e.public or e.owner==userId)
			and not overlaps
			and e.distance>=0 and e.distance<=e.maximum and e.z>0
			and e.x>=80 and e.x<=width-80 and e.y>=80 and e.y<=height-100 then
			table.insert(result,e)
		end
	end
	table.sort(result,function(a,b)
		local sa=a.distance+(a.aim or 0)*4
		local sb=b.distance+(b.aim or 0)*4
		if math.abs(sa-sb)<.001 then return a.id<b.id end
		return sa<sb
	end)
	return result
end
function UI.choose(candidates,previous,cycle)
	if #candidates==0 then return nil end
	for i,e in ipairs(candidates) do
		if e.id==previous then
			if cycle then return candidates[i%#candidates+1] end
			-- Hysteresis avoids oscillating between two adjacent stations.
			if e.distance<=candidates[1].distance+2 then return e end
		end
	end
	return candidates[1]
end
function UI.layout(width,height,touch,chatRight)
	local compact=touch or width<900
	local portrait=height>width
	local panelWidth=compact and (portrait and width-24 or math.min(400,width*.51)) or math.min(420,width-32)
	local panelHeight=compact and (portrait and math.min(height*.52,height-270,510) or height-132) or math.min(height-132,660)
	local left=chatRight and math.max(12,chatRight+12) or 12
	local chatModal=chatRight~=nil and (compact or left+panelWidth>width-12)
	return {compact=compact,portrait=portrait,left=left,chatModal=chatModal,width=math.max(240,panelWidth),height=math.max(180,panelHeight),
		factory={x=(width-104)/2,y=height-94,w=104,h=44},
		hudWidth=math.min(width-24,360),railWidth=math.min(width-24,300),bottom=touch and portrait and 150 or 20}
end
function UI.description(entry,config)
	if not entry then return "" end
	if entry.public then return "Магический базар" end
	local id=entry.station
	return (config.stations[id] and config.stations[id].name) or ({warehouse="Склад",orders="Заказы",altar="Фамильяры",blueprint="Развитие"})[id] or "Фабрика"
end
function UI.upgradeDetails(state,id)
	local phase=id=="blueprint"
	local offer=phase and state.phase or state.builds[id]
	local cost=offer and offer.cost
	local reason=phase and table.concat(state.phase.reasons,"; ") or (offer and offer.reason or "")
	local balance="У вас: "..math.floor(state.gold).." Gold"
	if not cost then return "Максимальный уровень\n"..balance,nil end
	local missing=math.max(0,cost-state.gold)
	return balance.."\n"..(missing>0 and ("Не хватает "..math.ceil(missing).." Gold") or "Gold достаточно")..(reason~="" and ("\n"..reason) or ""),cost
end
return UI
