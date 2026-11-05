--!nonstrict
-- Presentation height field for the first farm only. No ownership/economy state.
local Terrain={bounds={min={-244,-24,-184},max={-88,36,-16}},resolution=4}
local function smooth(v) v=math.clamp(v,0,1); return v*v*(3-2*v) end
function Terrain.reserved(x,z)
	local u,v=x+142.5,z+65
	return (math.abs(u)<=42.5 and v>=-49.5 and v<=33.5) or (math.abs(u)<=7 and v>=29 and v<=53)
end
function Terrain.height(x,z)
	local u,v=x+142.5,z+65
	-- A flat clearing extends beyond every original station/pad and the entrance.
	local dx=math.max(math.abs(u)-40,0)
	local dz=math.max(-47-v,v-53,0)
	local edge=smooth(math.sqrt(dx*dx+dz*dz)/17)
	local hills=0
	for _,h in ipairs({{-57,-62,10,31},{-16,-78,15,38},{39,-77,11,30},{-66,-9,7,25}}) do
		hills+=h[3]*math.exp(-((u-h[1])^2+(v-h[2])^2)/(h[4]^2))
	end
	local shore=smooth((math.sqrt(((u+6)/101)^2+((v+14)/105)^2)-.78)/.22)
	return .45+edge*(hills+.45*math.sin(u*.11)*math.cos(v*.09))-shore*21
end
function Terrain.contains(x,z)
	return x>=Terrain.bounds.min[1] and x<Terrain.bounds.max[1] and z>=Terrain.bounds.min[3] and z<Terrain.bounds.max[3]
end
return Terrain
