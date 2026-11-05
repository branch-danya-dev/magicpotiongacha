--!nonstrict
-- The playable island is above -10. Rescue before the engine's destruction plane.
local Recovery={height=-45,interval=.1,cooldown=2}
function Recovery.needed(y,velocityY,dt,destroyHeight,lastRescue,now)
	if y~=y or velocityY~=velocityY or math.abs(y)==math.huge or math.abs(velocityY)==math.huge then return false end
	if now-lastRescue<Recovery.cooldown then return false end
	local threshold=math.max(Recovery.height,destroyHeight+24)
	return y<threshold or (velocityY<0 and y+velocityY*dt<threshold)
end
return Recovery
