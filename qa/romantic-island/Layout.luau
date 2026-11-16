--!nonstrict
-- Pure QA layout + conservative trunk footprint audit. No game configuration writes.
local L={}
L.tree={x=47,z=-29};L.arch={x=-47,z=-28};L.waterfall={x=55,z=11}
L.trees={
	{name="TwistedTree_1",x=47,z=-29,scale=.95,yaw=0,hero=true},
	{name="CommonTree_3",x=-30,z=-54,scale=.75,yaw=30},
	{name="CommonTree_5",x=-21,z=-59,scale=.80,yaw=-35},
	{name="Pine_2",x=-9,z=-59,scale=.95,yaw=15},
	{name="CommonTree_3",x=4,z=-60,scale=.88,yaw=76},
	{name="CommonTree_1",x=17,z=-57,scale=1.0,yaw=-20},
	{name="CommonTree_5",x=31,z=-51,scale=.72,yaw=62},
	{name="CommonTree_3",x=-50,z=-6,scale=.95,yaw=20},
	{name="CommonTree_5",x=-52,z=8,scale=.70,yaw=-16},
	{name="CommonTree_3",x=-44,z=24,scale=.84,yaw=90},
	{name="CommonTree_3",x=-31,z=36,scale=.65,yaw=-40},
	{name="CommonTree_5",x=-18,z=43,scale=.65,yaw=68},
	{name="CommonTree_5",x=54,z=-5,scale=.75,yaw=30},
	{name="CommonTree_3",x=46,z=27,scale=.65,yaw=-30},
	{name="Pine_2",x=34,z=37,scale=.55,yaw=20},
	{name="CommonTree_5",x=20,z=43,scale=.72,yaw=70},
	{name="CommonTree_1",x=-44,z=-41,scale=.56,yaw=0},
	{name="CommonTree_3",x=41,z=-44,scale=.65,yaw=0},
}
L.lanterns={{-5,25},{5,25},{-7,-8},{7,-8}}
L.clusters={{-12,36},{12,36},{-24,34},{25,34},{-43,20},{49,17},
	{-51,-4},{52,-6},{-45,-29},{46,-35},{-25,-53},{12,-54},{30,-49},{-16,42},{17,42}}
local function overlap(a,b)
	return a.minX<b.maxX and a.maxX>b.minX and a.minZ<b.maxZ and a.maxZ>b.minZ
end
local function distance(b,x,z)
	local dx=math.max(b.minX-x,0,x-b.maxX);local dz=math.max(b.minZ-z,0,z-b.maxZ)
	return math.sqrt(dx*dx+dz*dz)
end
function L.trunkBounds(t,g)
	local out={minX=math.huge,maxX=-math.huge,minZ=math.huge,maxZ=-math.huge}
	local a=math.rad(t.yaw);local c,s=math.cos(a),math.sin(a)
	for _,p in ipairs(g[t.name].parts) do if not p.foliage then
		for _,u in ipairs({-1,1}) do for _,v in ipairs({-1,1}) do
			local x=(p.position[1]+u*p.size[1]/2)*t.scale
			local z=(p.position[3]+v*p.size[3]/2)*t.scale
			local wx,wz=t.x+c*x+s*z,t.z-s*x+c*z
			out.minX=math.min(out.minX,wx);out.maxX=math.max(out.maxX,wx)
			out.minZ=math.min(out.minZ,wz);out.maxZ=math.max(out.maxZ,wz)
		end end
	end end
	return out
end
function L.audit(config,island,geometry,trees)
	local errors={};local minClearance=math.huge;local footprints={}
	for i,t in ipairs(trees or L.trees) do
		local b=L.trunkBounds(t,geometry);b.name="Tree"..i
		table.insert(footprints,b)
		if not island.surfaceContains(t.x,t.z,1) then table.insert(errors,b.name..": outside walkable ellipse") end
	end
	-- Full conservative footprint includes the arch blocks, with a 12-stud width.
	table.insert(footprints,{name="Arch",minX=-53,maxX=-41,minZ=-29.4,maxZ=-26.6})
	for _,b in ipairs(footprints) do
		if overlap(b,island.buildable) then table.insert(errors,b.name..": construction overlap") end
		for _,id in ipairs(config.stationOrder) do
			local d=config.stations[id];local gap=distance(b,d.offset[1],d.offset[3])
			minClearance=math.min(minClearance,gap)
			if gap<8 then table.insert(errors,b.name..": station "..id) end
			for key,w in pairs(d.waypoints) do
				if distance(b,w[1],w[3])<3 then table.insert(errors,b.name..": waypoint "..id.."/"..key) end
			end
		end
		if overlap(b,{minX=-3,maxX=3,minZ=-2,maxZ=20}) then table.insert(errors,b.name..": main path") end
	end
	for i,l in ipairs(L.lanterns) do
		for _,id in ipairs(config.stationOrder) do local p=config.stations[id].offset
			if math.sqrt((l[1]-p[1])^2+(l[2]-p[3])^2)-.5<8 then table.insert(errors,"Lantern"..i..": station "..id) end
		end
	end
	return {ok=#errors==0,errors=errors,minStationClearance=minClearance,stations=#config.stationOrder,
		waypoints=#config.stationOrder*2,structuralFootprints=#footprints,pathWidth=6,footprints=footprints}
end
return L
