--!nonstrict
-- One pilot's background. Original architecture + already admitted nature meshes.
-- No new image, model asset, random source, gameplay position or saved field.
local runtimeScript=rawget(getfenv(),"script")
local Nature=require(runtimeScript and runtimeScript.Parent.NatureGeometry or "./NatureGeometry")
local Ground=require(runtimeScript and runtimeScript.Parent.FarmGround or "./FarmGround")
local Config=require(runtimeScript and runtimeScript.Parent.EnvironmentConfig or "./EnvironmentConfig")
local palette=Config.palette
local Vista={version=1,maxParts=76,maxTriangles=20000,canopyCount=7,moonSize=62,
	fogAnchors={{-218.5,-103},{-169.5,-169},{-108,-128}},
	pollenAnchors={{-181,-83},{-168,-111},{-121,-103},{-155,-42}},
	sunPools={{-179,-91},{-119,-102}},
	palette={rock=palette.stone,canopy=palette.leafLight,stone=palette.sage,edge=palette.stone,
		roof=palette.leaf,window=palette.blue,banner=palette.flower}}
local function smooth(x) x=math.clamp(x,0,1); return x*x*(3-2*x) end
function Vista.alpha(role,tier,distance)
	if not (distance>=0 and distance<math.huge) then return 1 end
	local limits=({full={core=680,detail=440,ground=135},reduced={core=620,detail=340,ground=95},minimal={core=560,detail=0,ground=0}})[tier]
		or {core=620,detail=340,ground=95}
	local limit=limits[role] or 0
	if limit==0 then return 1 end
	return smooth((distance-limit+45)/45)
end
function Vista.window(sample)
	local strength=sample.night*(1-.25*sample.rain)
	local a,b=palette.blue,palette.amber
	return {a[1]+(b[1]-a[1])*strength,a[2]+(b[2]-a[2])*strength,a[3]+(b[3]-a[3])*strength}
end
function Vista.build()
	local parts={}; local metrics={parts=0,triangles=0,canopies=0,lights=0,textures=0}
	local function add(d)
		d.id="Vista_"..(#parts+1); d.role=d.role or "core"; d.angle=d.angle or 0; d.color=d.color or "stone"
		table.insert(parts,d); metrics.parts+=1; metrics.triangles+=d.triangles or 12
		if d.canopy then metrics.canopies+=1 end
	end
	local function mesh(name,index,x,z,scale,bottom,grounded,color,role,canopy,angle)
		local asset=Nature[name]; local p=asset.parts[index]
		local size={p.size[1]*scale[1],p.size[2]*scale[2],p.size[3]*scale[3]}
		local triangles=canopy and asset.triangles-asset.barkTriangles or asset.triangles
		local y=(grounded and Ground.column(x,z) or 0)+bottom+size[2]/2
		add({shape="Mesh",template=name,source=p.name,size=size,position={x,y,z},grounded=grounded,
			bottom=bottom,color=color,role=role,canopy=canopy,angle=angle,triangles=triangles})
	end
	-- Seven canopy-only silhouettes + 29 whole trees = the unchanged 36-tree cap.
	-- Lower foliage is sunk into the ridge. Never floating unrooted full trees.
	for i,p in ipairs({{-267,-57},{-265,-100},{-252,-125},{-218,-178},{-207,-170},{-145,-176},{-91,-185}}) do
		local name=({"CommonTree_1","Pine_2","TwistedTree_1"})[(i-1)%3+1]
		mesh(name,2,p[1],p[2],{1.40,1.25,1.25},-2,true,"canopy","core",true,i*53)
	end
	for i,p in ipairs({{-241,-38},{-242,-74},{-244,-113},{-236,-147},{-218,-153},
		{-192,-155},{-166,-158},{-140,-159},{-110,-160},{-85,-164}}) do
		mesh("Rock_Medium_1",1,p[1],p[2],{2.1,2.7+(i%3)*.5,2.1},-3,true,"rock","core",false,i*47)
	end
	local function tower(x,z,base,scale,yaw)
		local function part(shape,size,at,color,role,turn,window,roll)
			local a=math.rad(yaw); local px,pz=at[1]*scale,at[3]*scale
			add({shape=shape,size={size[1]*scale,size[2]*scale,size[3]*scale},
				position={x+px*math.cos(a)+pz*math.sin(a),base+at[2]*scale,z-px*math.sin(a)+pz*math.cos(a)},
				angle=yaw+(turn or 0),color=color,role=role,window=window,roll=roll})
		end
		part("Block",{16,4,14},{0,2,0},"edge")
		part("Block",{10,42,9},{0,25,0},"stone")
		part("Block",{14,3,13},{0,47.5,0},"edge")
		part("Block",{7,13,6},{0,55,0},"stone")
		part("Block",{9,.6,10},{-2.8,64.8,0},"roof",nil,nil,nil,50)
		part("Block",{9,.6,10},{2.8,64.8,0},"roof",nil,nil,nil,-50)
		part("Block",{1,9,1},{0,73,0},"roof")
		for _,side in ipairs({-1,1}) do part("Wedge",{3,18,5},{side*6,13,0},"edge",nil,side*90) end
		for _,y in ipairs({18,30,54}) do part("Block",{1.2,3,.16},{0,y,y==54 and 3.1 or 4.6},"window","core",nil,true) end
		for _,y in ipairs({12,36}) do part("Block",{11,1,10},{0,y,0},"edge") end
		part("Block",{.14,6,3},{5.08,32,0},"banner","detail")
	end
	-- Small offshore rock stacks: absolute elevations, outside the playable world.
	for i,p in ipairs({{-197,-306,1,8},{-390,-95,.78,-18}}) do
		local x,z,s=p[1],p[2],p[3]
		mesh("Rock_Medium_1",1,x,z,{12*s,10*s,11*s},-17,false,"rock","core",false,19*i)
		mesh("Rock_Medium_1",1,x-17*s,z+7*s,{7*s,7*s,8*s},-17,false,"rock","core",false,48*i)
		mesh("Rock_Medium_1",1,x+13*s,z-9*s,{6*s,6*s,7*s},-17,false,"rock","core",false,83*i)
		tower(x,z,-17+31*s,s,p[4])
	end
	-- A broken coastal gate, visible when looking toward the western water.
	local x,z=-267,-116; local floor=Ground.column(x,z)
	for i,p in ipairs({{-8,8,0,3,16,4},{8,10,0,3,20,4},{0,17,0,19,3,5},
		{-9,1,0,6,2,7},{9,1,0,6,2,7},{-9,16,0,5,2,6},{8,20,0,5,2,6},
		{14,1,4,4,2,3},{-15,1,-3,4,2,3},{1,1,6,6,2,4}}) do
		add({shape="Block",size={p[4],p[5],p[6]},position={x+p[1],floor+p[2],z+p[3]},
			grounded=true,groundAnchor={x,z},bottom=p[2]-p[5]/2,angle=i>7 and i*29 or -12,color=i%3==0 and "edge" or "stone"})
	end
	-- Ground detail is bounded and culled; no planting along gameplay routes.
	for i,p in ipairs({{-234,-31},{-235,-54},{-247,-60},{-244,-105},{-219,-151},{-200,-155},
		{-179,-141},{-155,-142},{-134,-141},{-113,-140},{-94,-142},{-82,-145}}) do
		local name=i<=6 and "Fern_1" or (i<=8 and "Clover_2" or "Grass_Wispy_Tall")
		local scale=name=="Clover_2" and 2.5 or .8
		mesh(name,1,p[1],p[2],{scale,scale,scale},-.06,true,"canopy","ground",false,i*67)
	end
	assert(metrics.parts<=Vista.maxParts and metrics.triangles<=Vista.maxTriangles,"Vista budget exceeded")
	return {parts=parts,metrics=metrics}
end
return Vista
