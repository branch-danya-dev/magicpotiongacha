--!nonstrict
-- Resolve inward obstruction immediately, release outward smoothly. Never let
-- damping place the camera beyond a newly encountered collision.
local Clearance={skin=.15,maxZoom=40,minZoom=4}
function Clearance.distance(previous,desired,hit,dt)
	local safe=math.max(0,math.min(desired,hit and hit-Clearance.skin or desired))
	if not previous or safe<=previous then return safe end
	return math.min(safe,previous+(safe-previous)*(1-math.exp(-12*math.max(0,dt))))
end
function Clearance.radius(fov,aspect,near)
	local half=math.tan(math.rad(fov)/2)*math.abs(near)
	return math.max(.6,math.sqrt(half*half*(1+aspect*aspect)+near*near)+.1)
end
return Clearance
