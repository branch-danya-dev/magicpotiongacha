--!nonstrict
-- AG76B: geographic/session policy only. No economy, saves or paid rights.
local Island = {}
Island.origin = {-142.5, 0, -65} -- keeps the approved pilot's lighting/VFX coordinates
Island.core = {minX=-42.5,maxX=42.5,minZ=-49.5,maxZ=33.5}
Island.buildable = {minX=-38.5,maxX=38.5,minZ=-45.5,maxZ=29.5}
Island.serviceOffsets = {warehouse={-8,2,-30},orders={10,2,-30},altar={27,2,-32},blueprint={0,2,10}}
-- exchangeEssence is deliberately unavailable in Factory; do not offer or revive it.
Island.marketIntents = {buySeed=true,shopFamiliar=true,buyEventGold=true}
Island.maxSceneryParts = 650
local function integer(value)
	return type(value)=="number" and value==value and math.abs(value)<9007199254740991 and value%1==0
end
function Island.validOwner(userId, studio)
	return integer(userId) and (userId>0 or (studio==true and userId<0))
end
function Island.identity(userId)
	assert(Island.validOwner(userId,true),"Invalid island owner")
	return "u:"..string.format("%.0f",userId)..":primary"
end
function Island.contains(x,z,margin)
	if type(x)~="number" or type(z)~="number" or x~=x or z~=z then return false end
	local b=Island.core; local m=margin or 0
	return x>=b.minX+m and x<=b.maxX-m and z>=b.minZ+m and z<=b.maxZ-m
end
function Island.offset(config,id)
	local station=config.stations[id]
	return station and station.offset or Island.serviceOffsets[id]
end
function Island.haulEndpoints(job)
	if not job or job.kind~="haul" then return nil,nil end
	return job.sourceKind=="inventory" and "warehouse" or job.sourceStationId,
		job.destinationKind=="questStock" and "orders" or (job.destinationKind=="inventory" and "warehouse" or job.destinationStationId)
end
function Island.marketAllowed(owner,alive,intent)
	return owner==true and alive==true and Island.marketIntents[intent]==true
end
return Island
