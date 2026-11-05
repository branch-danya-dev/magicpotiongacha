--!nonstrict
-- Engine-independent visibility policy; no new owner, connection or Instance pool.
local LOD={tiers={full={core=290,detail=115,ground=105},reduced={core=240,detail=75,ground=70},minimal={core=185,detail=0,ground=0}},fadeBand=18}
function LOD.alpha(role,quality,distance)
	local tier=LOD.tiers[quality] or LOD.tiers.reduced
	local limit=tier[role]
	if not limit or limit==0 or not (distance>=0 and distance<math.huge) then return 1 end
	local t=math.clamp((distance-(limit-LOD.fadeBand))/LOD.fadeBand,0,1)
	return t*t*(3-2*t)
end
function LOD.step(current,target,elapsed)
	return current+math.clamp(target-current,-math.clamp(elapsed,0,.1)*2,math.clamp(elapsed,0,.1)*2)
end
return LOD
