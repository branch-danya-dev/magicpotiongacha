--!strict
-- Image-backed sun shares the existing camera-relative moon/star rig. No lighting.
local Celestial={sunDegrees=7}
function Celestial.sunDiameter(distance:number):number
	return 2*distance*math.tan(math.rad(Celestial.sunDegrees/2))
end
function Celestial.sunAlpha(elevation:number,cloud:number,rain:number):number
	-- Fade across the horizon and with the same continuous weather state; never
	-- draw a bright disk through overcast rain. Geometry still occludes the GUI.
	local horizon=math.clamp((elevation+.02)/.08,0,1)
	horizon=horizon*horizon*(3-2*horizon)
	return horizon*(1-math.clamp(cloud,0,1)*.75)*(1-math.clamp(rain,0,1))
end
return table.freeze(Celestial)
