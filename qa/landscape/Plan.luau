--!nonstrict
-- Stage 1 only. Authored southwest grove; all coordinates are island-relative.
local P={}
P.trees={
	{id="alder-edge",source="stylized_stefan",variant="Natural",x=-47,z=18,scale=.50,yaw=20,radius=7.4,wind=.70},
	{id="alder-lean",source="stylized_stefan",variant="Windswept",x=-20,z=37,scale=.42,yaw=-65,radius=7.3,wind=.88},
	{id="small-broadleaf",template="CommonTree_5",x=-9,z=43,scale=.62,yaw=48,radius=4.7},
	{id="rim-conifer",template="Pine_2",x=-53,z=2,scale=.40,yaw=110,radius=5.3},
	{id="quiet-magic",source="magic_igor",variant="Natural",x=-51,z=-12,scale=.42,yaw=190,radius=11.2,wind=.56,magic=true},
}
-- A few loose groups, with open intervals; no seeded scatter or per-frame spawning.
P.cover={
	{"Bush_Common_Flowers",-49,-19,.55,21},{"Fern_1",-47,-18,.45,68},
	{"Grass_Common_Short",-45,-17,1.1,14},{"Fern_1",-50,-3,.50,125},
	{"Bush_Common_Flowers",-50,9,.56,82},{"Fern_1",-47,10,.52,39},
	{"Grass_Common_Short",-45,11,.9,130},{"Flower_3_Group",-46,13,.65,75},
	{"Fern_1",-46,20,.48,18},{"Bush_Common_Flowers",-43,20,.52,120},
	{"Grass_Common_Short",-43,21,1.15,36},{"Fern_1",-23,33,.48,145},
	{"Grass_Common_Short",-22,32,1.1,60},{"Flower_3_Group",-23,34,.65,45},
	{"Bush_Common_Flowers",-19,34,.60,82},{"Fern_1",-17,34,.46,101},
	{"Grass_Common_Short",-16,35,1.15,172},{"Bush_Common_Flowers",-13,41,.56,13},
	{"Fern_1",-11,39,.45,55},{"Flower_3_Group",-8,39,.7,35},
	{"Grass_Common_Short",-7,37,1,63},{"Grass_Common_Short",-6,40,.9,113},
}
P.palette={bark={.78,.74,.66},leaf={.64,.76,.61},secondary={.55,.68,.61},
	magicLeaf={.60,.72,.70},magicSecondary={.57,.63,.72},glow={.47,.69,.77},glowIntensity=.12}
P.budgets={full={hz=24,distance=155,trees=3,scale=1},reduced={hz=12,distance=110,trees=2,scale=.7},minimal={hz=5,distance=65,trees=1,scale=.3}}
function P.windBudgets(source)
	assert(source=="stylized_stefan" or source=="magic_igor")
	local out={};for q,b in pairs(P.budgets)do
		out[q]=table.clone(b)
		out[q].trees=if source=="magic_igor"then (q=="minimal" and 0 or 1)else (q=="full" and 2 or 1)
	end;return out
end
function P.detailAlpha(role,quality,distance)
	assert(P.budgets[quality],"Unknown quality")
	if role~="LeafSecondary"then return 0 end
	if quality=="minimal"then return 1 end
	local far=quality=="full" and 130 or 90
	return math.clamp((distance-(far-20))/20,0,1)
end
-- R3 terrain has concave notches inside the navigation ellipse. Root support
-- must follow that unchanged coastline, not just PersonalIsland.surfaceContains.
function P.terrainMargin(x,z)
	local a=math.atan2((z+8)/53,x/59)
	return (1+.10*math.sin(a*5)+.035*math.cos(a*7)-math.sqrt((x/59)^2+((z+8)/53)^2))*53
end
function P.inPilot(x,z)return x < -5 and z > -23 end
function P.keepTrees(trees)
	local out={};for _,t in ipairs(trees)do if not t.hero and not P.inPilot(t.x,t.z)then table.insert(out,t)end end;return out
end
function P.keepClusters(clusters)
	local out={};for _,p in ipairs(clusters)do if not P.inPilot(p[1],p[2])then table.insert(out,p)end end;return out
end
local function rectangleDistance(x,z,b)
	local dx=math.max(b.minX-x,0,x-b.maxX);local dz=math.max(b.minZ-z,0,z-b.maxZ);return math.sqrt(dx*dx+dz*dz)
end
local function segmentDistance(x,z,a,b)
	local dx,dz=b[1]-a[1],b[2]-a[2];local t=math.clamp(((x-a[1])*dx+(z-a[2])*dz)/(dx*dx+dz*dz),0,1)
	return math.sqrt((x-a[1]-t*dx)^2+(z-a[2]-t*dz)^2)
end
function P.audit(config,island,trees)
	local errors={};local minimum=math.huge;local ids={}
	for _,t in ipairs(trees or P.trees)do
		if ids[t.id]then table.insert(errors,t.id..": duplicate")end;ids[t.id]=true
		if not island.surfaceContains(t.x,t.z,1)then table.insert(errors,t.id..": root off island")end
		if P.terrainMargin(t.x,t.z)<2.1 then table.insert(errors,t.id..": terrain notch")end
		-- Whole crown envelope, stronger than a trunk-only collision audit.
		if rectangleDistance(t.x,t.z,island.buildable)<t.radius then table.insert(errors,t.id..": crown/buildable overlap")end
		for _,id in ipairs(config.stationOrder)do
			local d=config.stations[id];local gap=math.sqrt((t.x-d.offset[1])^2+(t.z-d.offset[3])^2)-t.radius
			minimum=math.min(minimum,gap);if gap<4 then table.insert(errors,t.id..": station "..id)end
			for _,w in pairs(d.waypoints)do if math.sqrt((t.x-w[1])^2+(t.z-w[3])^2)-t.radius<3 then table.insert(errors,t.id..": waypoint "..id)end end
		end
		for id,p in pairs(island.serviceOffsets)do if math.sqrt((t.x-p[1])^2+(t.z-p[3])^2)-t.radius<3 then table.insert(errors,t.id..": service "..id)end end
		if segmentDistance(t.x,t.z,{0,20},{0,-2})<t.radius+3 then table.insert(errors,t.id..": book path")end
		for _,eye in ipairs({{0,20},{0,-2},{18,12}})do
			if segmentDistance(t.x,t.z,eye,{510,-5175})<t.radius+2 then table.insert(errors,t.id..": World Tree sightline")end
		end
	end
	return {ok=#errors==0,errors=errors,minStationCrownGap=minimum,stations=#config.stationOrder,trees=#(trees or P.trees)}
end
return P
