--!nonstrict
-- Avatar-distance light slots, independent of camera orbit/zoom. Fading slots
-- remain occupied; replacing a lantern never briefly exceeds the quality cap.
local Lights={hysteresis=10,fadeSeconds=.65}
function Lights.step(entries,limit,distance,dt)
	local ranked=table.clone(entries)
	table.sort(ranked,function(a,b)
		local ar=a.distance-((a.selected or (a.weight or 0)>0) and Lights.hysteresis or 0)
		local br=b.distance-((b.selected or (b.weight or 0)>0) and Lights.hysteresis or 0)
		return ar==br and a.id<b.id or ar<br
	end)
	local desired=0
	for _,e in ipairs(ranked) do
		e.selected=e.distance<distance and desired<limit
		if e.selected then desired+=1 end
	end
	local occupied=0; local step=math.clamp(dt,0,.1)/Lights.fadeSeconds
	for _,e in ipairs(ranked) do
		e.weight=e.weight or 0
		-- Fade through the outer 20 studs; no hard distance switch.
		local target=e.selected and math.clamp((distance-e.distance)/20,0,1) or 0
		e.target=target
		if e.weight>0 then
			if occupied>=limit then e.weight=0
			else e.weight+=math.clamp(target-e.weight,-step,step) end
			if e.weight>0 then occupied+=1 end
		end
	end
	for _,e in ipairs(ranked) do
		if e.weight==0 and e.target>0 and occupied<limit then
			e.weight=math.min(e.target,step); occupied+=1
		end
	end
	return occupied
end
return Lights
