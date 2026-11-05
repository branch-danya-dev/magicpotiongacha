--!nonstrict
-- Authored pilot woodland. Existing bark/ground meshes plus original solid crowns.
local runtimeScript=rawget(getfenv(),"script")
local Island=require(runtimeScript and runtimeScript.Parent.IslandTerrain or "./IslandTerrain")
local Ground=require(runtimeScript and runtimeScript.Parent.FarmGround or "./FarmGround")
local Forest={version=1,maxTrees=36,maxParts=260,maxTriangleCharge=195000,
	-- Native sphere/cylinder tessellation is engine-owned: these are planning
	-- charges, not measured GPU triangle counts. Mesh counts are exact.
	ballCharge=1024,cylinderCharge=192,
	glades={{-76,-38,5},{-27,-104,5}},
	forms={
		oak={template="CommonTree_1",height=23.137352,stemWide=1.06,stemY=.75,width=14,stemRadius=7},
		birch={template="CommonTree_3",height=19.187424,stemWide=1.08,stemY=1.05,width=7,stemRadius=4},
		apple={template="CommonTree_5",height=15.450907,stemWide=1.20,stemY=.92,width=12,stemRadius=4},
		pine={template="Pine_2",height=24.047497,stemWide=.82,stemY=.90,width=13,stemRadius=6},
		elder={template="TwistedTree_1",height=22.173241,stemWide=.88,stemY=.72,width=18,stemRadius=11},
	}}
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
local function piece(shape,size,position,role,tint)
	return {shape=shape,size=size,position=position,role=role,tint=tint}
end
function Forest.crowns(species,variant)
	local f=assert(Forest.forms[species]); local h,w=f.height*f.stemY,f.width
	local tint=variant%3+1
	if species=="pine" then
		return {piece("Ball",{w,h*.42,w*.86},{0,h*.53,0},"core",tint),
			piece("Ball",{w*.76,h*.47,w*.65},{.5,h*.76,.3},"core",tint%3+1),
			piece("Ball",{w*.44,h*.44,w*.40},{.2,h*.98,0},"core",3),
			piece("Ball",{w*.66,h*.27,w*.58},{-1,h*.62,-1},"detail",1)}
	end
	return {piece("Ball",{w*.82,h*.53,w*.74},{0,h*.83,0},"core",tint),
		piece("Ball",{w*.67,h*.39,w*.61},{-w*.25,h*.68,-w*.08},"core",1),
		piece("Ball",{w*.65,h*.44,w*.65},{w*.24,h*.77,w*.13},"core",2),
		piece("Ball",{w*.52,h*.32,w*.48},{w*.08,h*.99,-w*.17},"detail",3)}
end
function Forest.radius(species,scale)
	local f=Forest.forms[species]; local radius=f.stemRadius
	for _,p in ipairs(Forest.crowns(species,0)) do
		radius=math.max(radius,math.sqrt((math.abs(p.position[1])+p.size[1]/2)^2+(math.abs(p.position[3])+p.size[3]/2)^2))
	end
	return radius*scale
end
function Forest.logPieces()
	-- Cylinder axis is local X. Cut ends remain opaque at every quality tier.
	return {piece("Cylinder",{9,2.4,2.4},{0,1.1,0},"core",4),
		piece("Cylinder",{.10,2.05,2.05},{-4.54,1.1,0},"core",5),
		piece("Cylinder",{.10,2.05,2.05},{4.54,1.1,0},"core",5),
		piece("Ball",{4.2,.45,1.9},{-.7,2.25,0},"detail",1),
		piece("Ball",{2.1,.35,1.6},{2.1,2.19,.2},"detail",2)}
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
				parts=5,triangles=716+4*Forest.ballCharge,meshTriangles=716,nativeParts=4}
			table.insert(result,p); table.insert(trees,p)
		end
	end end
	for i,p in ipairs({{-65,-17},{-41,-81},{16,-84}}) do
		if Forest.clear(p[1],p[2],5.5) then table.insert(result,{forest="log",x=p[1],z=p[2],scale=1,angle=i*57,
			radius=5.5,parts=5,triangles=3*Forest.cylinderCharge+2*Forest.ballCharge,meshTriangles=0,nativeParts=5}) end
	end
	-- Sparse clearings and alternating fern/stone pockets under the layered trees.
	for i,t in ipairs(trees) do
		local x,z=t.x+math.cos(i*2.4)*6,t.z+math.sin(i*2.4)*6
		local scale=.65+(i%3)*.15; local radius=4.383*scale -- admitted fern bounds, rounded up
		if Forest.clear(x,z,radius) then table.insert(result,{forest="understory",template="Fern_1",x=x,z=z,scale=scale,
			angle=i*71,radius=radius,parts=1,triangles=288,meshTriangles=288,nativeParts=0}) end
		if i%2==0 then
			x,z=t.x-6,t.z+4
			scale=1.45+(i%3)*.18; radius=3.114*scale -- admitted boulder bounds, rounded up
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
