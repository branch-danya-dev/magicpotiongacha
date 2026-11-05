--!nonstrict
-- Authored pilot woodland using complete admitted Quaternius silhouettes.
local runtimeScript=rawget(getfenv(),"script")
local Island=require(runtimeScript and runtimeScript.Parent.IslandTerrain or "./IslandTerrain")
local Ground=require(runtimeScript and runtimeScript.Parent.FarmGround or "./FarmGround")
local Nature=require(runtimeScript and runtimeScript.Parent.NatureGeometry or "./NatureGeometry")
local Forest={version=2,maxTrees=36,maxParts=260,maxTriangleCharge=195000,
	glades={{-76,-38,5},{-27,-104,5}},
	forms={
		oak={template="CommonTree_1"},birch={template="CommonTree_3"},apple={template="CommonTree_5"},
		pine={template="Pine_2"},elder={template="TwistedTree_1"},
	}}
for _,f in pairs(Forest.forms) do
	f.height=Nature[f.template].height; f.stemWide=1; f.stemY=1
end
local function rect(x,z,cx,cz,rx,rz)
	return math.sqrt(math.max(math.abs(x-cx)-rx,0)^2+math.max(math.abs(z-cz)-rz,0)^2)
end
function Forest.clear(x,z,radius)
	-- Root and crown extents remain in the northwest pilot envelope, not the
	-- other seven farms. Protect their full floors and the common access route.
	local wx,wz=x-142.5,z-65
	if wx-radius< -282 or wx+radius> -87 or wz-radius< -216 or wz+radius> -23 then return false end
	for i=1,8 do
		local ox,oz=Island.origin(i)
		if rect(wx,wz,ox,oz-8,38.5,37.5)<radius+1.5 then return false end
	end
	if rect(wx,wz,0,0,214,18)<radius+2 then return false end
	for _,g in ipairs(Forest.glades) do if math.sqrt((x-g[1])^2+(z-g[2])^2)<radius+g[3] then return false end end
	local h=Ground.column(wx,wz)
	return h>Island.water+3
end
function Forest.crowns(species,variant)
	local result={}; local f=assert(Forest.forms[species])
	for _,p in ipairs(Nature[f.template].parts) do if p.foliage then
		table.insert(result,{shape="Mesh",size=p.size,position=p.position,role="core",source=p.name,variant=variant})
	end end
	return result
end
function Forest.radius(species,scale)
	return Nature[Forest.forms[species].template].radius*scale
end
function Forest.logPieces()
	-- Actual curved Quaternius bark as fallen wood, with no proxy cylinders.
	local p=Nature.CommonTree_3.parts[1]; local s=.4
	return {{shape="Mesh",template="CommonTree_3",source=p.name,role="core",
		size={p.size[2]*s,p.size[1]*s,p.size[3]*s},position={0,p.size[1]*s/2+.03,0},
		sourceSize={p.size[1]*s,p.size[2]*s,p.size[3]*s},roll=math.pi/2}}
end
function Forest.build()
	local result={}; local trees={}; local serial=0
	local rows={
		{{-58,17},{-64,-5},{-55,-27},{-56,-49},{-39,-62},{-17,-63},{7,-62},{31,-62},{47.5,-34},{47.5,-7},{46,-62}},
		{{-77,17},{-73,-5},{-72,-23},{-65,-47},{-63,-66},{-40,-77},{-19,-79},{3,-79},{26,-80},{45,-81}},
		{{-95,16},{-84,0},{-81,-19},{-79,-61},{-34,-86},{-7,-96},{9,-99},{25,-100},{42,-101},{39,-118}},
	}
	local species={"oak","elder","apple","pine","oak","birch"}
	for layer,row in ipairs(rows) do for i,position in ipairs(row) do
		serial+=1
		local kind=position[1]>45 and "birch" or species[(serial-1)%#species+1]
		local scale=position[1]>45 and .88 or (.94+(serial%4)*.08+(layer-1)*.05)
		local radius=Forest.radius(kind,scale)
		if Forest.clear(position[1],position[2],radius) then
			local p={forest="tree",species=kind,template=Forest.forms[kind].template,x=position[1],z=position[2],
				scale=scale,angle=(serial*137.5)%360,radius=radius,layer=layer,variant=serial%3,
				parts=2,triangles=Nature[Forest.forms[kind].template].triangles,
				meshTriangles=Nature[Forest.forms[kind].template].triangles,nativeParts=0}
			table.insert(result,p); table.insert(trees,p)
		end
	end end
	for i,p in ipairs({{-65,-17},{-41,-81},{16,-84}}) do
		if Forest.clear(p[1],p[2],5.5) then table.insert(result,{forest="log",x=p[1],z=p[2],scale=1,angle=i*57,
			radius=5.5,parts=1,triangles=Nature.CommonTree_3.barkTriangles,meshTriangles=Nature.CommonTree_3.barkTriangles,nativeParts=0}) end
	end
	-- Sparse clearings and alternating fern/stone pockets under the layered trees.
	for i,t in ipairs(trees) do
		local x,z=t.x+math.cos(i*2.4)*6,t.z+math.sin(i*2.4)*6
		local name=({"Fern_1","Bush_Common_Flowers","Fern_1","Clover_2","Flower_3_Group"})[(i-1)%5+1]
		local asset=Nature[name]; local scale=name=="Clover_2" and 2.4 or .65+(i%3)*.15
		local radius=asset.radius*scale
		if Forest.clear(x,z,radius) then table.insert(result,{forest="understory",template=name,x=x,z=z,scale=scale,
			angle=i*71,radius=radius,parts=#asset.parts,triangles=asset.triangles,meshTriangles=asset.triangles,nativeParts=0}) end
		if i%2==0 then
			x,z=t.x-6,t.z+4
			scale=1.45+(i%3)*.18; radius=Nature.Rock_Medium_1.radius*scale
			if Forest.clear(x,z,radius) then table.insert(result,{forest="boulder",template="Rock_Medium_1",x=x,z=z,scale=scale,
				angle=i*43,radius=radius,parts=1,triangles=342,meshTriangles=342,nativeParts=0}) end
		end
	end
	local metrics={trees=#trees,parts=0,triangles=0,meshTriangles=0,nativeParts=0,logs=0,understory=0,boulders=0}
	for _,p in ipairs(result) do
		for _,k in ipairs({"parts","triangles","meshTriangles","nativeParts"}) do metrics[k]+=p[k] end
		if p.forest=="log" then metrics.logs+=1 elseif p.forest=="understory" then metrics.understory+=1 elseif p.forest=="boulder" then metrics.boulders+=1 end
	end
	assert(metrics.trees<=Forest.maxTrees and metrics.parts<=Forest.maxParts and metrics.triangles<=Forest.maxTriangleCharge,"Forest budget exceeded")
	return result,metrics
end
return Forest
