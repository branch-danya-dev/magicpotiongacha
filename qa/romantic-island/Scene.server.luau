--!nonstrict
-- Disposable Studio art scene. No gameplay bootstrap, profile, remotes or services.
local Run=game:GetService("RunService")
assert(Run:IsStudio(),"Wizard Island is a Studio-only art prototype; do not publish")
local Players=game:GetService("Players")
local Storage=game:GetService("ServerStorage")
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Island=require(Shared.PersonalIsland)
local Config=require(Shared.Config)
local Geometry=require(Shared.NatureGeometry)
local Layout=require(Shared.RomanticLayout)
local audit=Layout.audit(Config,Island,Geometry)
assert(audit.ok,table.concat(audit.errors,"; "))
local O=Vector3.new(table.unpack(Island.origin))
local library=Storage:WaitForChild("M7NatureTemplates")
local root=Instance.new("Folder");root.Name="PotionTycoonWorld";root.Parent=workspace
local art=Instance.new("Folder");art.Name="EnvironmentArt";art.Parent=root
local triangles,meshCount=0,0
local function inert(p)
	p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
end
local function mesh(name,x,y,z,scale,yaw,tint,material,detail,tilt)
	local m=assert(library:FindFirstChild(name),name):Clone()
	-- Admitted foliage/path vertices are authored with their base at world Y=0.
	-- A default Model pivot is its bounds centre and buries half of a whole tree.
	-- Rock masses intentionally use their centre for the underbody/shrine layout.
	if name~="Rock_Medium_1" and name~="Pebble_Round_1" then m.WorldPivot=CFrame.identity end
	m:ScaleTo(scale or 1);m.Name=name.."_"..meshCount
	m:PivotTo(CFrame.new(O+Vector3.new(x,y,z))*CFrame.Angles(tilt or 0,math.rad(yaw or 0),0))
	for _,p in ipairs(m:GetDescendants()) do if p:IsA("MeshPart") then
		inert(p);meshCount+=1;p:SetAttribute("EnvironmentDetail",detail or 1)
		if tint then
			p.Color=Color3.fromRGB(table.unpack(tint))
			local appearance=p:FindFirstChildOfClass("SurfaceAppearance")
			if appearance then appearance.Color=p.Color end
		end
		if material then
			for _,s in ipairs(p:GetChildren()) do if s:IsA("SurfaceAppearance") then s:Destroy() end end
			p.TextureID="";p.Material=Enum.Material[material]
		end
	end end
	triangles+=Geometry[name].triangles
	m.Parent=art;return m
end
local function rock(name,x,y,z,sx,sy,sz,yaw,tint,material)
	local m=mesh(name,x,y,z,1,yaw,tint,material)
	local pivot=m:GetPivot()
	for _,p in ipairs(m:GetChildren()) do if p:IsA("MeshPart") then
		local localCF=pivot:ToObjectSpace(p.CFrame);local pos=localCF.Position
		p.Size*=Vector3.new(sx,sy,sz)
		p.CFrame=pivot*CFrame.new(pos.X*sx,pos.Y*sy,pos.Z*sz)*localCF.Rotation
	end end
	return m
end
local function part(name,pos,size,tint,material,parent)
	local p=Instance.new("Part");p.Name=name;p.Position=O+Vector3.new(table.unpack(pos))
	p.Size=Vector3.new(table.unpack(size));p.Color=Color3.fromRGB(table.unpack(tint))
	p.Material=Enum.Material[material or "Slate"];inert(p);p.Parent=parent or art;return p
end
-- Hidden collision proxy; imported cliff meshes plus a thin native terrain skin.
local floor=part("ForestFloor",{0,-.3,-8},{1.6,124,116},{80,92,68},"Grass",root)
floor.Shape=Enum.PartType.Cylinder;floor.CFrame=CFrame.new(O+Vector3.new(0,-.3,-8))*CFrame.Angles(0,0,math.pi/2)
floor.Transparency=1;floor.CanCollide=true;floor.CanQuery=true
-- One original continuous smooth MeshPart is built locally by Cliff.luau in Play.
-- No duplicated, scaled stock boulders form the main island silhouette anymore.
-- A thin native terrain skin blends grass, soil and stone without stretched mesh UVs.
-- The original R2 continuous cliff is reused unchanged. Terrain exists only in this place.
local terrain=workspace.Terrain
terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(76,119,104))
terrain:SetMaterialColor(Enum.Material.Ground,Color3.fromRGB(117,113,100))
terrain:SetMaterialColor(Enum.Material.Rock,Color3.fromRGB(105,114,114))
local region=Region3.new(O+Vector3.new(-68,-8,-72),O+Vector3.new(68,8,56)):ExpandToGrid(4)
local corner=region.CFrame.Position-region.Size/2;local count=region.Size/4
local materials,occupancy={},{}
for ix=1,count.X do materials[ix]={};occupancy[ix]={}
	for iy=1,count.Y do materials[ix][iy]={};occupancy[ix][iy]={}
		for iz=1,count.Z do
			local x=corner.X+(ix-.5)*4-O.X;local z=corner.Z+(iz-.5)*4-O.Z
			local a=math.atan2((z+8)/53,x/59);local rim=1+.10*math.sin(a*5)+.035*math.cos(a*7)
			local radius=math.sqrt((x/59)^2+((z+8)/53)^2)
			local high=math.max(0,(radius-.6))*7*(.65+.35*math.sin(a*3))
			-- Roblox's smooth voxel isosurface lies half a cell above this density origin.
			-- Native raycasts calibrated the core at .5 (previous .5 origin rendered at 2.5).
			local top=-1.5+high
			local y=corner.Y+(iy-1)*4-O.Y
			local fill=radius<rim and math.clamp((top-y)/4,0,1) or 0
			local soil=(math.abs(x-math.sin((24-z)*.17)*1.2)<5.5 and z>-8 and z<29) or (x*x+(z+2)^2<65)
			local mat=y<-5 and Enum.Material.Rock or (soil and Enum.Material.Ground or Enum.Material.Grass)
			materials[ix][iy][iz]=fill>0 and mat or Enum.Material.Air;occupancy[ix][iy][iz]=fill
		end
	end
end
terrain:WriteVoxels(region,4,materials,occupancy)
-- Small stones create an irregular, readable route to the unchanged crystal coordinate.
for i=0,10 do
	local z=24-i*2.6;local x=math.sin(i*.45)*1.2
	rock("Pebble_Round_1",x,.62,z,1.7,.48,1.7,17*i-9,{130,144,143},"Slate")
end
for i=1,13 do local a=i*math.pi*2/13
	rock("Pebble_Round_1",math.cos(a)*6.2,.62,-2+math.sin(a)*6.2,1.05,.5,1.25,i*29,{137,147,144},"Slate")
end
-- The owner's v3 diagram: open buildable clearing, two landmarks and irregular rim.
local foliagePalette={{130,186,175},{149,190,163},{115,174,181},{141,181,162}}
for index,d in ipairs(Layout.trees) do
 local m=mesh(d.name,d.x,.4,d.z,d.scale,d.yaw,{208,197,181})
 m.Name=d.hero and "AncientTreeProxy" or "PeripheralTree_"..index
 m:SetAttribute("QAProxy",d.hero==true)
 for _,p in ipairs(m:GetChildren()) do if p:IsA("MeshPart") and p.Name:match("_2$") then
  if d.hero then p.Transparency=1;p:SetAttribute("EnvironmentDetail",99)
  else local tint=Color3.fromRGB(table.unpack(foliagePalette[index%4+1]))
   -- Wider, lower crowns overlap in depth without adding collidable trunks.
   if d.name~="Pine_2" then p.Size*=Vector3.new(1.65,.88,1.55) end
   p.Color=tint;local a=p:FindFirstChildOfClass("SurfaceAppearance");if a then a.Color=tint end
  end
 end end
 if d.hero then
  -- Temporary ancient oak: existing twisting trunk with a separate green crown.
  local crown=mesh("CommonTree_1",d.x,.4,d.z,1.20,0,{158,209,196})
  crown.Name="AncientTreeCrownProxy";crown:SetAttribute("QAProxy",true)
  for _,p in ipairs(crown:GetChildren()) do if p:IsA("MeshPart") and p.Name:match("_1$") then
   p.Transparency=1;p:SetAttribute("EnvironmentDetail",99)
  elseif p:IsA("MeshPart") then
   p.Size=Vector3.new(21,13,21);p.Position=O+Vector3.new(d.x,17.5,d.z)
  end end
 end
end
-- Low planted margins, not a wall of foliage and never a filled construction core.
for n,c in ipairs(Layout.clusters) do
 mesh("Bush_Common_Flowers",c[1],.45,c[2],.90+(n%3)*.13,n*41,{159,173,202})
 for j=1,5 do
  local a=j*2.39996;local r=1.8+j*.65
  local x,z=c[1]+math.cos(a)*r,c[2]+math.sin(a)*r
  local outside=x<Island.buildable.minX-1 or x>Island.buildable.maxX+1 or z<Island.buildable.minZ-1 or z>Island.buildable.maxZ+1
  if outside and Island.surfaceContains(x,z,1) then
   local name=j%3==0 and "Fern_1" or (j%2==0 and "Grass_Wispy_Tall" or "Clover_2")
   mesh(name,x,.5,z,name=="Clover_2" and 2.7 or .8,n*27+j*29,{128,182,165},nil,2)
  end
 end
end
-- Sparse small rock outcrops on the rim. The continuous underbody is not duplicated.
for i,c in ipairs({{-48,15},{49,23},{-33,36},{32,35},{-17,-56},{29,-49},{-54,-14},{55,-15}}) do
 rock("Rock_Medium_1",c[1],.45,c[2],.65,.42,.60,i*47,{111,140,138},"Slate")
end
-- Altar platform: low native stone ring; book height and logical anchor stay fixed.
rock("Pebble_Round_1",0,.54,-2,3.25,.14,3.25,0,{134,153,157},"Slate")
-- Temporary ruin proxy, 12 studs wide and 15 high; no external generation/upload.
local ruin=Instance.new("Model");ruin.Name="RuinedArchProxy";ruin:SetAttribute("QAProxy",true);ruin.Parent=art
for _,side in ipairs({-1,1}) do
 for j=0,2 do
  local b=part("WeatheredPier",{-47+side*4.8,2+j*3,-28},{2.1,3,2.25},{148+j*5,151+j*4,151+j*3},"Slate",ruin)
  b.CFrame*=CFrame.Angles(0,math.rad(side*(j-1)*3),math.rad(side*(j%2)*1.5))
 end
end
for i=0,6 do
 local a=math.pi*i/6
 local b=part("ArchStone",{-47+4.8*math.cos(a),9+4.8*math.sin(a),-28},{2.35,1.9,2.2},{158,162,163},"Slate",ruin)
 b.CFrame*=CFrame.Angles(0,0,a-math.pi/2)
end
for i,c in ipairs({{-52,-32},{-50,-24},{-44,-25}}) do
 rock("Rock_Medium_1",c[1],.7,c[2],.45,.40,.5,i*53,{124,148,133},"Slate")
 mesh("Fern_1",c[1],.9,c[2],.65,i*17,{120,173,148},nil,2)
end
-- Every protected gameplay anchor/worker endpoint is retained as an invisible QA marker.
local anchors=Instance.new("Folder");anchors.Name="ProtectedStations";anchors.Parent=root
for _,id in ipairs(Config.stationOrder) do
 local def=Config.stations[id]
 local a=part(id,def.offset,{.2,.2,.2},{255,255,255},"SmoothPlastic",anchors);a.Transparency=1
 a:SetAttribute("StationId",id)
 for key,w in pairs(def.waypoints) do local b=part(id.."_"..key,w,{.15,.15,.15},{255,255,255},"SmoothPlastic",anchors);b.Transparency=1 end
end
root:SetAttribute("ProtectedStationCount",audit.stations)
root:SetAttribute("ProtectedWaypointCount",audit.waypoints)
root:SetAttribute("MinStructuralStationClearance",audit.minStationClearance)
print("ROMANTIC_LAYOUT",game:GetService("HttpService"):JSONEncode(audit))
-- Four small lanterns are the only visible primitive-built props (32 pieces).
for i,v in ipairs(Layout.lanterns) do
	local x,z=v[1],v[2]
	local anchor=part("WizardLantern_"..i,{x,4.1,z},{.1,.1,.1},{255,199,111});anchor.Transparency=1
	anchor:SetAttribute("EnvironmentLight",true)
	part("LanternStem",{x,2,z},{.22,3.2,.22},{55,58,54},"Metal")
	local pane=part("AmberPane",{x,4.1,z},{.62,.92,.62},{255,191,112},"Neon")
	pane:SetAttribute("EnvironmentLanternPane",anchor.Name)
	part("LanternRoof",{x,4.7,z},{1,.16,1},{73,82,78},"Metal")
	part("LanternFoot",{x,3.5,z},{.9,.15,.9},{73,82,78},"Metal")
	for _,s in ipairs({{-1,-1},{-1,1},{1,-1},{1,1}}) do part("LanternFrame",{x+s[1]*.37,4.1,z+s[2]*.37},{.08,1.1,.08},{56,64,60},"Metal") end
end
-- Imported altar, original 6.5 stud height and crystal X/Z. No gameplay anchor is changed.
local book=Storage.SpellbookLectern:Clone();book.Name="SpellbookLectern";book.Parent=art
local _,sz=book:GetBoundingBox();book:ScaleTo(book:GetScale()*6.5/sz.Y)
local cf,size=book:GetBoundingBox();local offset=Vector3.new(table.unpack(Config.stations.crystal.offset))
book:PivotTo(book:GetPivot()+O+Vector3.new(offset.X,.5,offset.Z)-Vector3.new(cf.X,cf.Y-size.Y/2,cf.Z))
for _,p in ipairs(book:GetDescendants()) do if p:IsA("MeshPart") then
	inert(p);p.Transparency=0;p:SetAttribute("EnvironmentDetail",1);meshCount+=1
end end
local glow=Instance.new("PointLight");glow.Name="AltarGlow";glow.Color=Color3.fromRGB(108,194,245)
glow.Brightness=.65;glow.Range=12;glow.Shadows=false;glow.Parent=book:FindFirstChild("Cover",true)
local spawn=Instance.new("SpawnLocation");spawn.Name="Spawn";spawn.Size=Vector3.new(6,1,6)
spawn.Position=O+Vector3.new(0,1,20);spawn.Anchored=true;spawn.Transparency=1;spawn.CanCollide=false
spawn.Neutral=true;spawn.Duration=0;spawn.Parent=root
Players.PlayerAdded:Connect(function(p) p.RespawnLocation=spawn end)
for _,p in ipairs(Players:GetPlayers()) do p.RespawnLocation=spawn end
root:SetAttribute("EnvironmentArtEnabled",true);root:SetAttribute("WizardReady",true)
root:SetAttribute("MeshParts",meshCount);root:SetAttribute("NatureTriangles",triangles)
print("ROMANTIC_SCENE_READY",meshCount,triangles,"Studio art only; no economy or saves")
