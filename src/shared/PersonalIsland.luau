--!nonstrict
-- AG76B: geographic/session policy only. No economy, saves or paid rights.
local Island = {}
Island.origin = {-142.5, 0, -65} -- keeps the approved pilot's lighting/VFX coordinates
Island.core = {minX=-42.5,maxX=42.5,minZ=-49.5,maxZ=33.5}
Island.buildable = {minX=-38.5,maxX=38.5,minZ=-45.5,maxZ=29.5}
-- Walkable art is larger than the frozen V8 temple/buildable projection.
-- AG76C owns any future change to persisted expansion/building boundaries.
Island.surface = {width=124,depth=116,centerZ=-8,topY=0.5,thickness=1.5}
Island.maxTerrainParts = 90
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
function Island.surfaceContains(x,z,margin)
	if type(x)~="number" or type(z)~="number" or x~=x or z~=z
		or math.abs(x)==math.huge or math.abs(z)==math.huge then return false end
	local s=Island.surface;local m=margin or 0
	if type(m)~="number" or m<0 or m~=m then return false end
	local rx=s.width*0.5-m;local rz=s.depth*0.5-m
	if rx<=0 or rz<=0 then return false end
	local dz=z-s.centerZ
	return (x/rx)^2+(dz/rz)^2<=1
end
-- Deterministic low-poly cliff/keel descriptors. Nothing creates a second
-- collider, light, economic station, DataStore entry or paid asset.
function Island.terrainPlan()
	local pieces={}
	local function add(name,shape,x,y,z,w,h,d,yaw,tint,material)
		pieces[#pieces+1]={name=name,shape=shape,position={x,y,z},size={w,h,d},yaw=yaw or 0,
			tint=tint,material=material}
	end
	local z0=Island.surface.centerZ
	add("IslandStone","Ball",0,-14,z0,126,29,118,0,"stone","Slate")
	add("IslandStratum","Ball",2,-29,z0-3,103,38,97,0,"stoneDark","Slate")
	add("IslandKeel","Ball",-2,-49,z0-6,67,38,65,0,"stoneDeep","Rock")
	for i=1,22 do
		local a=2*math.pi*i/22
		local radial=1+0.065*math.sin(i*2.37)
		local x=math.cos(a)*57*radial
		local z=z0+math.sin(a)*53*radial
		add("IslandCliff_"..i,"Wedge",x,-6-(i%3),z,8+(i%4)*1.5,
			9+(i%5)*1.4,10+(i%3)*2,math.deg(a)+90,
			i%3==0 and "stoneLight" or (i%2==0 and "stone" or "stoneDark"),"Slate")
	end
	for i=1,16 do
		local a=2*math.pi*(i+0.3)/16
		local x=math.cos(a)*(36+(i%4)*2.1)
		local z=z0+math.sin(a)*(33+(i%5)*1.6)
		add("IslandRidge_"..i,"Wedge",x,-24-(i%4),z,8+(i%3)*2,
			20+(i%4)*3,12+(i%5)*1.4,math.deg(a)+90,
			i%4==0 and "stoneLight" or "stoneDark","Rock")
	end
	for i=1,12 do
		local a=2*math.pi*(i+0.5)/12
		local x=math.cos(a)*(13+(i%3)*5)
		local z=z0+math.sin(a)*(14+(i%4)*3)
		add("IslandRoot_"..i,"Wedge",x,-46-(i%5)*1.5,z,6+(i%4)*1.7,
			22+(i%5)*3,9+(i%3)*2,math.deg(a)+90,
			i%3==0 and "stone" or "stoneDeep","Rock")
	end
	-- Subtle raised grassy/stone ridges stay outside the V8 construction core;
	-- their tops are decorative and cannot trap players or block familiar paths.
	for i=1,12 do
		local a=2*math.pi*(i+0.2)/12
		local x=math.cos(a)*(53+(i%3)*1.4)
		local z=z0+math.sin(a)*(49+(i%4))
		if Island.surfaceContains(x,z,4) and not Island.contains(x,z,2) then
			add("IslandGrassRidge_"..i,"Ball",x,0.2,z,9+(i%3)*2,1.3+(i%3)*0.4,
				10+(i%4)*1.6,math.deg(a),i%3==0 and "grassLight" or "grass","Grass")
		end
	end
	return pieces
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
