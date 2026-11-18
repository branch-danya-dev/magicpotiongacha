--!nonstrict
-- Stage 1 only. Authored southwest grove; all coordinates are island-relative.
local P={}
P.trees={
	{id="alder-edge",source="stylized_stefan",variant="Natural",x=-47,z=18,scale=.50,yaw=32,radius=7.4,wind=.70,tone="shade"},
	{id="alder-lean",source="stylized_stefan",variant="Windswept",x=-20,z=37,scale=.42,yaw=-52,radius=7.3,wind=.88,tone="edge"},
	{id="small-broadleaf",template="CommonTree_5",x=-9,z=43,scale=.62,yaw=64,radius=4.7,tone="edge"},
	{id="rim-conifer",template="Pine_2",x=-53,z=2,scale=.40,yaw=110,radius=5.3,tone="shade"},
	{id="quiet-magic",source="magic_igor",variant="Natural",x=-51,z=-12,scale=.42,yaw=190,radius=11.2,wind=.56,magic=true,tone="arcane"},
}
-- Three authored pockets, feathered toward the clearing. Row fields:
-- template / X / Z / uniform scale / yaw / tone / quality-detail level.
-- Detail 1 is the structural understory; small flowers/tufts are optional.
P.cover={
	-- Cool, low planting around the magical tree; no extra light/VFX owner.
	{"Bush_Common_Flowers",-49,-18,.62,21,"arcane",1},
	{"Fern_1",-47,-18,.62,68,"arcane",1},
	{"Grass_Common_Short",-46,-16,1.45,14,"arcane",2},
	{"Flower_3_Group",-48,-15,.72,75,"arcane",2},
	{"Fern_1",-51.3,-7,.58,125,"arcane",1},
	{"Bush_Common_Flowers",-51,-3,.48,38,"shade",2},
	{"Grass_Common_Short",-49,-8,1.35,86,"arcane",2},
	{"Grass_Common_Short",-50,-5,1.65,18,"shade",2},
	{"Flower_3_Group",-49,-11,.64,153,"arcane",2},
	-- Uneven fern bank beneath the conifer and the main broadleaf.
	{"Bush_Common_Flowers",-52,6,.70,82,"shade",1},
	{"Fern_1",-49.8,3,.65,39,"shade",1},
	{"Fern_1",-50,9,.74,17,"shade",2},
	{"Grass_Common_Short",-48,6,1.75,130,"shade",2},
	{"Grass_Common_Short",-50,7,1.35,42,"shade",2},
	{"Bush_Common_Flowers",-49,14,.58,120,"shade",1},
	{"Fern_1",-47,13,.57,18,"shade",2},
	{"Grass_Common_Short",-48,12,1.55,36,"shade",2},
	{"Bush_Common_Flowers",-46,20,.66,54,"shade",1},
	{"Fern_1",-49,18,.60,141,"shade",1},
	{"Fern_1",-46,22,.47,78,"shade",2},
	{"Grass_Common_Short",-47,21,1.35,26,"shade",2},
	{"Flower_3_Group",-47,16,.67,105,"shade",2},
	-- Lower, warmer foreground. Keep the cliff notch between the two banks open.
	{"Bush_Common_Flowers",-22,34,.60,82,"edge",1},
	{"Fern_1",-23,33,.48,145,"edge",2},
	{"Grass_Common_Short",-21,33,1.70,60,"edge",2},
	{"Flower_3_Group",-22,35,.78,45,"edge",2},
	{"Bush_Common_Flowers",-18,39,.65,13,"edge",1},
	{"Fern_1",-18,34,.58,101,"edge",1},
	{"Grass_Common_Short",-16,35,1.55,172,"edge",2},
	{"Grass_Common_Short",-19,35,1.45,37,"edge",2},
	{"Flower_3_Group",-17,37,.70,115,"edge",2},
	{"Bush_Common_Flowers",-12,42,.53,67,"edge",1},
	{"Fern_1",-11,39,.57,55,"edge",1},
	{"Fern_1",-14,40,.46,152,"edge",2},
	{"Flower_3_Group",-8,39,.82,35,"edge",2},
	{"Flower_3_Group",-10,41,.66,85,"edge",2},
	{"Grass_Common_Short",-7,37,1.45,63,"edge",2},
	{"Grass_Common_Short",-6,40,1.20,113,"edge",2},
	{"Grass_Common_Short",-13,38,1.55,54,"edge",2},
	{"Grass_Common_Short",-16,39,1.30,19,"edge",2},
}
-- Existing CC0 meshes only: buried root stones and discontinuous old paving.
-- Last field is vertical seating offset; no terrain edits or new colliders.
P.stones={
	{"Rock_Medium_1",-49,-13,.50,35,"mossStone",1,-.20},
	{"Pebble_Round_1",-48,-10,.86,91,"stone",2,-.06},
	{"Pebble_Round_1",-49,-17,.67,170,"mossStone",2,-.06},
	{"Rock_Medium_1",-51,5,.48,112,"mossStone",1,-.19},
	{"Pebble_Round_1",-49,8,.90,46,"stone",2,-.08},
	{"Rock_Medium_1",-48,17,.56,156,"mossStone",1,-.22},
	{"Pebble_Round_1",-46,19,.92,68,"stone",2,-.08},
	{"Rock_Medium_1",-19,38,.43,73,"mossStone",1,-.16},
	{"Pebble_Round_1",-17,35,.72,135,"stone",2,-.05},
	{"Pebble_Round_1",-12,40,.90,26,"mossStone",2,-.07},
	{"RockPath_Round_Small_1",-41,19,1.30,34,"stone",1,.025},
	{"RockPath_Round_Small_1",-42.2,15,1.55,115,"stone",1,.025},
	{"RockPath_Round_Small_1",-43.2,11,1.20,68,"mossStone",1,.025},
	{"RockPath_Round_Small_1",-44.3,6,1.45,151,"stone",1,.025},
	{"RockPath_Round_Small_1",-45.5,1,1.25,16,"mossStone",1,.025},
	{"RockPath_Round_Small_1",-46.4,-4,1.40,82,"stone",1,.025},
}
P.groveRoute={{-40.5,22},{-42,16},{-43.5,10},{-45,4},{-46.5,-3},{-47,-7}}
P.palette={bark={.78,.74,.66},leaf={.64,.76,.61},secondary={.55,.68,.61},
	magicLeaf={.60,.72,.70},magicSecondary={.57,.63,.72},glow={.47,.69,.77},glowIntensity=.12}
P.tones={
	shade={bark={.76,.74,.68},leaf={.62,.74,.65},secondary={.54,.66,.60},flower={.76,.79,.76}},
	edge={bark={.82,.76,.66},leaf={.76,.81,.61},secondary={.65,.73,.57},flower={.91,.84,.68}},
	arcane={bark={.73,.73,.74},leaf={.63,.76,.73},secondary={.61,.65,.75},flower={.69,.78,.87}},
}
P.stoneColors={stone={.67,.70,.68},mossStone={.56,.65,.57}}
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
function P.auditDressing(config,island,geometry,cover,stones)
	local errors={};local count,parts,triangles,kept=0,0,0,0
	for _,list in ipairs({cover or P.cover,stones or P.stones})do for _,v in ipairs(list)do
		local name,x,z,scale=v[1],v[2],v[3],v[4];local g=geometry[name]
		if not g then table.insert(errors,"Unknown dressing asset "..name);continue end
		local radius=g.radius*scale;count+=1;parts+=#g.parts;triangles+=g.triangles
		if v[7]==1 then kept+=#g.parts end
		if not island.surfaceContains(x,z,1) or P.terrainMargin(x,z)<2.1 then table.insert(errors,name..": unsupported root")end
		if rectangleDistance(x,z,island.buildable)<radius+.25 then table.insert(errors,name..": construction overhang")end
		for _,id in ipairs(config.stationOrder)do
			local d=config.stations[id];local p=d.offset
			if math.sqrt((x-p[1])^2+(z-p[3])^2)<radius+3 then table.insert(errors,name..": station "..id)end
			for _,w in pairs(d.waypoints)do if math.sqrt((x-w[1])^2+(z-w[3])^2)<radius+2.5 then table.insert(errors,name..": waypoint "..id)end end
		end
		for id,p in pairs(island.serviceOffsets)do if math.sqrt((x-p[1])^2+(z-p[3])^2)<radius+3 then table.insert(errors,name..": service "..id)end end
		if segmentDistance(x,z,{0,20},{0,-2})<radius+3 then table.insert(errors,name..": book path")end
		if name~="RockPath_Round_Small_1" then
			for i=2,#P.groveRoute do
				if segmentDistance(x,z,P.groveRoute[i-1],P.groveRoute[i])<radius+1.5 then table.insert(errors,name..": grove walking strip");break end
			end
		end
	end end
	return {ok=#errors==0,errors=errors,models=count,parts=parts,triangles=triangles,minimalParts=kept}
end
return P
