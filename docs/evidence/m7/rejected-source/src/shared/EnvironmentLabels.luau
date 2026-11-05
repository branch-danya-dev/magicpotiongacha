--!nonstrict
-- Screen-space presentation only. Prompts and interactive objects are never hidden.
local Labels={}
function Labels.select(entries,width,height)
	local candidates={}
	for _,e in ipairs(entries) do
		if e.enabled and e.z>0 and e.distance<=115 and e.x>=0 and e.x<=width and e.y>=0 and e.y<=height then
			table.insert(candidates,e)
		end
	end
	table.sort(candidates,function(a,b)
		if a.distance==b.distance then return a.id<b.id end
		return a.distance<b.distance
	end)
	local chosen,rects={},{}
	local cap=width<700 and 3 or 6
	for _,e in ipairs(candidates) do
		local r={x1=e.x-e.w/2-8,x2=e.x+e.w/2+8,y1=e.y-e.h/2-8,y2=e.y+e.h/2+8}
		local overlaps=false
		for _,a in ipairs(rects) do
			if r.x1<a.x2 and r.x2>a.x1 and r.y1<a.y2 and r.y2>a.y1 then overlaps=true; break end
		end
		if not overlaps then chosen[e.id]=true; table.insert(rects,r); if #rects>=cap then break end end
	end
	return chosen
end
return Labels
