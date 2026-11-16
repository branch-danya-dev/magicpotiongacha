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
-- The main cliffs/underbody remain imported MeshParts. Terrain exists only in this place.
local terrain=workspace.Terrain
terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(92,110,99))
terrain:SetMaterialColor(Enum.Material.Ground,Color3.fromRGB(116,108,95))
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
-- Authored tree silhouettes: open centre, asymmetric framing and layered far bank.
local trees={
	{"TwistedTree_1",-17,12,1.13,35},{"CommonTree_3",20,12,1.15,-35},
	{"CommonTree_5",-40,6,.9,90},{"CommonTree_1",44,0,.84,-22},
	{"TwistedTree_1",-23,-28,1.3,20},{"CommonTree_3",27,-28,1.28,-14},
	{"CommonTree_5",-5,-42,1.28,55},{"CommonTree_1",12,-44,1.2,84},
	{"CommonTree_1",-37,-29,1.15,90},{"Pine_2",37,-34,1.12,17},
	{"CommonTree_3",-15,-48,.92,0},{"CommonTree_5",29,-46,.83,-25},
	{"TwistedTree_1",-43,-15,.9,60},{"CommonTree_5",43,16,.78,82},
	{"CommonTree_3",-32,34,.84,120},{"CommonTree_1",18,40,.76,9},
	{"CommonTree_3",-14,-35,1.45,72},{"CommonTree_5",16,-30,1.34,104},
	{"Pine_2",-30,-42,1.2,24},{"CommonTree_3",3,-48,1.4,13},
}
for index,d in ipairs(trees) do
	local m=mesh(d[1],d[2],.4,d[3],d[4],d[5],{172,179,190})
	for _,p in ipairs(m:GetChildren()) do if p:IsA("MeshPart") and p.Name:match("_2$") then
		local s=p:FindFirstChildOfClass("SurfaceAppearance")
		if d[1]=="TwistedTree_1" then
			-- Expose the old twisting branches; no red plastic-looking crown.
			p.Transparency=1;p:SetAttribute("EnvironmentDetail",99)
		else
			-- Preserve leaf alpha/albedo: removing it reveals the mesh's leaf cards.
			local palette={{107,131,127},{126,143,132},{96,119,130},{135,146,137}}
			p.Color=Color3.fromRGB(table.unpack(palette[index%4+1]))
			if s then s.Color=p.Color end
		end
	end end
end
-- Ground-cover in clusters, leaving central movement and anchor positions intact.
local rng=Random.new(7602)
local clusters={{-16,13},{15,18},{-24,-20},{23,-21},{-39,4},{35,1},{-10,-39},{14,-35},{-26,30},{32,27}}
for n,c in ipairs(clusters) do
	mesh("Bush_Common_Flowers",c[1],.45,c[2],1.1+(n%3)*.15,n*41,{133,157,172})
	for j=1,6 do
		local a=j*2.39996;local r=2+j*.72
		local name=j%3==0 and "Fern_1" or (j%2==0 and "Grass_Wispy_Tall" or "Clover_2")
		mesh(name,c[1]+math.cos(a)*r,.5,c[2]+math.sin(a)*r,name=="Clover_2" and 2.5 or 1.05,n*27+j*29,{120,148,161},nil,2)
	end
end
for i=1,55 do
	local a=rng:NextNumber()*math.pi*2;local r=rng:NextNumber(.67,.96)
	local x,z=math.cos(a)*53*r,-8+math.sin(a)*49*r
	mesh(i%4==0 and "Rock_Medium_1" or "Grass_Wispy_Tall",x,.4,z,i%4==0 and rng:NextNumber(.7,1.7) or rng:NextNumber(1.1,1.9),i*73,{162,182,154},nil,2)
end
-- Ruined shrine, built from existing stone meshes. It frames rather than hides the altar.
for _,x in ipairs({-10,10}) do
	for i=0,2 do rock("Rock_Medium_1",x,i*2.1,-13,1.05,.8,1.1,i*67,{173,180,172}) end
	mesh("Pebble_Round_1",x,5.9,-13,2.8,20,{181,185,171})
end
rock("Rock_Medium_1",0,6.3,-13,4.7,.65,1.05,2,{166,175,169})
for _,d in ipairs({{-18,-10},{18,-11},{-33,17}}) do
	mesh("Rock_Medium_1",d[1],.45,d[2],1.65,32,{145,154,137})
	mesh("Fern_1",d[1]+1,.65,d[2]-1,1.1,75,{156,184,161},nil,2)
end
-- Four small lanterns are the only visible primitive-built props (32 pieces).
for i,v in ipairs({{-7,15},{7,10},{-12,-10},{12,-10}}) do
	local x,z=v[1],v[2]
	local anchor=part("WizardLantern_"..i,{x,4.1,z},{.1,.1,.1},{255,199,111});anchor.Transparency=1
	anchor:SetAttribute("EnvironmentLight",true)
	part("LanternStem",{x,2,z},{.22,3.2,.22},{55,58,54},"Metal")
	local pane=part("AmberPane",{x,4.1,z},{.62,.92,.62},{255,193,102},"Neon")
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
local glow=Instance.new("PointLight");glow.Name="AltarGlow";glow.Color=Color3.fromRGB(106,184,222)
glow.Brightness=.65;glow.Range=12;glow.Shadows=false;glow.Parent=book:FindFirstChild("Cover",true)
local spawn=Instance.new("SpawnLocation");spawn.Name="Spawn";spawn.Size=Vector3.new(6,1,6)
spawn.Position=O+Vector3.new(0,1,20);spawn.Anchored=true;spawn.Transparency=1;spawn.CanCollide=false
spawn.Neutral=true;spawn.Duration=0;spawn.Parent=root
Players.PlayerAdded:Connect(function(p) p.RespawnLocation=spawn end)
for _,p in ipairs(Players:GetPlayers()) do p.RespawnLocation=spawn end
root:SetAttribute("EnvironmentArtEnabled",true);root:SetAttribute("WizardReady",true)
root:SetAttribute("MeshParts",meshCount);root:SetAttribute("NatureTriangles",triangles)
print("WIZARD_SCENE_READY",meshCount,triangles,"Studio art only; no economy or saves")
