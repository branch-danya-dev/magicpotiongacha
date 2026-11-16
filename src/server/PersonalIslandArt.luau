--!nonstrict
-- Bounded reuse of approved M7 templates/prop plans; no external assets or Lighting owner.
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Island=require(Shared.PersonalIsland)
local Plan=require(Shared.PropPlan)
local Env=require(Shared.EnvironmentConfig)
local Art={}
local function color(key) return Color3.fromRGB(table.unpack(Plan.palette[key])) end
local function part(parent,name,size,cf,tint,material,collides)
	local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=tint;p.Material=material
	p.Anchored=true;p.CanCollide=collides==true;p.CanQuery=collides==true;p.CanTouch=false;p.Reflectance=0
	p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
end
function Art.prop(parent,name,pieces,basis)
	local model=Instance.new("Model");model.Name=name
	local entries={}
	for _,d in ipairs(pieces) do
		local p=Instance.new(d.shape=="Wedge" and "WedgePart" or "Part");p.Name=d.name
		p.Size=Vector3.new(table.unpack(d.size))
		p.CFrame=basis*CFrame.new(table.unpack(d.position))*CFrame.Angles(math.rad(d.rotation[1]),math.rad(d.rotation[2]),math.rad(d.rotation[3]))
		if d.shape=="Cylinder" then p.Shape=Enum.PartType.Cylinder end
		if d.shape=="Sphere" then local m=Instance.new("SpecialMesh");m.MeshType=Enum.MeshType.Sphere;m.Parent=p end
		p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Reflectance=0
		p.Color=color(d.tint);p.Material=Enum.Material[d.material];p.Transparency=1;p.Parent=model
		table.insert(entries,{part=p,definition=d})
	end
	model.Parent=parent;return {model=model,entries=entries}
end
function Art.display(record,state)
	for _,e in ipairs(record.entries) do
		local visible,tint,material=Plan.appearance(e.definition,state)
		e.part.Transparency=visible and 0 or 1;e.part.Color=color(tint);e.part.Material=Enum.Material[material]
	end
end
function Art.attach(root,plot)
	local origin=plot.origin
	local floor=part(root,"ForestFloor",Vector3.new(85,1,83),CFrame.new(origin+Vector3.new(0,0,-8)),Color3.fromRGB(109,139,101),Enum.Material.SmoothPlastic,true)
	local folder=Instance.new("Folder");folder.Name="EnvironmentArt";folder.Parent=root
	local stone=Color3.fromRGB(89,100,98)
	local base=part(folder,"IslandStone",Vector3.new(88,21,86),CFrame.new(origin+Vector3.new(0,-10,-8)),stone,Enum.Material.Slate,false)
	local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=base
	-- Visible low edge stones define the same safe envelope used by recovery.
	for _,e in ipairs({{-42,0,-8,1,2,83},{42,0,-8,1,2,83},{0,0,-49,85,2,1},{0,0,33,85,2,1}}) do
		part(folder,"IslandRim",Vector3.new(e[4],e[5],e[6]),CFrame.new(origin+Vector3.new(e[1],e[2],e[3])),stone,Enum.Material.Slate,true)
	end
	for i=0,4 do
		local p=part(folder,"TemplePath_"..i,Vector3.new(4,.08,2.8),CFrame.new(origin+Vector3.new(0,.57,17-i*3.6)),Color3.fromRGB(157,153,124),Enum.Material.SmoothPlastic,false)
		p.CastShadow=false
	end
	local templates=game:GetService("ServerStorage"):FindFirstChild("M7NatureTemplates")
	local definitions=require(Shared.EnvironmentPlan).build(Env,Env.pilotPlot).parts
	local count=0
	if templates then for _,d in ipairs(definitions) do
		local x,z=d.position[1]-origin.X,d.position[3]-origin.Z
		-- Only perimeter foliage from the approved pilot. No market/fences/global terrain.
		if (d.template or d.forest) and not d.barrier and Island.contains(x,z,2)
			and (math.abs(x)>35 or z<-42 or z>27) and not string.find(d.template or "","RockPath",1,true) then
			local model
			if d.forest then model=require(script.Parent.ForestArt).build(d,templates)
			else local source=templates:FindFirstChild(d.template);if source then model=source:Clone();model:ScaleTo(d.scale) end end
			if model then
				local items=model:GetDescendants();local parts=0
				for _,p in ipairs(items) do if p:IsA("BasePart") then parts+=1 end end
				if count+parts>Island.maxSceneryParts then model:Destroy() else
					count+=parts;model.Name=d.id
					model:PivotTo(CFrame.new(origin+Vector3.new(x,.5,z))*CFrame.Angles(0,math.rad(d.rotation[2]),0))
					for _,p in ipairs(items) do if p:IsA("BasePart") then
						p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
						p:SetAttribute("EnvironmentDetail",math.min(d.detail or 1,2))
					end end
					model.Parent=folder
				end
			end
		end
	end end
	for i,v in ipairs({{-8,16},{8,16},{-36,-22},{36,-22}}) do
		local anchor=part(folder,"IslandLantern_"..i,Vector3.new(.5,.5,.5),CFrame.new(origin+Vector3.new(v[1],5,v[2])),color("amber"),Enum.Material.SmoothPlastic,false)
		anchor.Transparency=1;anchor:SetAttribute("EnvironmentLight",true);anchor:SetAttribute("EnvironmentDetail",1)
		part(folder,"LanternPost_"..i,Vector3.new(.3,4.7,.3),CFrame.new(origin+Vector3.new(v[1],2.7,v[2])),color("wood"),Enum.Material.Wood,false)
		local lamp=Art.prop(folder,"Lantern_"..i,Plan.lantern(),anchor.CFrame)
		Art.display(lamp,{level=1,phase=1})
		for _,e in ipairs(lamp.entries) do if string.find(e.part.Name,"AmberPane",1,true) then e.part:SetAttribute("EnvironmentLanternPane",anchor.Name) end end
	end
	root:SetAttribute("IslandSceneryParts",count);root:SetAttribute("EnvironmentArtEnabled",true)
	return floor,folder
end
return Art
