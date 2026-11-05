--!nonstrict
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Config=require(Shared.EnvironmentConfig)
local Plan=require(Shared.EnvironmentPlan)
local State=require(Shared.EnvironmentState)
local Art={}
local function meadow(floor,enabled)
	-- Preserve the existing collision/friction contract while replacing only
	-- native Grass shading. Local PBR packs fail Studio's TexturePack loader;
	-- an immutable, low-frequency top Texture works at graphics 5 and 10.
	if floor.CustomPhysicalProperties==nil then floor.CustomPhysicalProperties=PhysicalProperties.new(floor.Material) end
	local texture=floor:FindFirstChild("M7Meadow")
	if not texture then
		texture=Instance.new("Texture"); texture.Name="M7Meadow"; texture.Face=Enum.NormalId.Top
		texture.Texture=Config.polishPrefix.."meadow.png"; texture.StudsPerTileU=14; texture.StudsPerTileV=14; texture.Parent=floor
	end
	texture.Color3=floor.Color; texture.Transparency=enabled and 0 or 1
	if enabled then floor.Material=Enum.Material.SmoothPlastic end
end
function Art.attach(world)
	assert(not world.root:FindFirstChild("EnvironmentArt"),"Environment already attached")
	local templates=game:GetService("ServerStorage"):FindFirstChild("M7NatureTemplates")
	assert(templates,"Reviewed nature templates missing from build")
	require(script.Parent.IslandLandscape).attach(world)
	-- Terrain collision data becomes queryable on the following simulation step.
	game:GetService("RunService").Heartbeat:Wait()
	local ground=RaycastParams.new(); ground.FilterType=Enum.RaycastFilterType.Include
	ground.FilterDescendantsInstances={workspace.Terrain,world.root.ForestFloor,world.plots[Config.pilotPlot].model.Floor}
	-- TASK05_FOREST_GROUND_BEGIN: new forest follows visible soil, not hidden slabs.
	local forestGround=RaycastParams.new(); forestGround.FilterType=Enum.RaycastFilterType.Include
	forestGround.FilterDescendantsInstances={workspace.Terrain}; forestGround.IgnoreWater=true
	-- TASK05_FOREST_GROUND_END
	local folder=Instance.new("Folder"); folder.Name="EnvironmentArt"; folder.Parent=world.root
	for _,d in ipairs(Plan.build(Config,Config.pilotPlot).parts) do
		local position=Vector3.new(table.unpack(d.position)); local surfaceNormal
		if d.template or d.forest then
			local hit=workspace:Raycast(Vector3.new(position.X,60,position.Z),Vector3.new(0,-110,0),d.forest and forestGround or ground)
			assert(hit,"Decoration has no supporting ground: "..d.id.." / "..tostring(d.template or d.forest))
			position=Vector3.new(position.X,hit.Position.Y+(d.flatten~=1 and (.16+(tonumber(string.match(d.id,"%d+"))%7)*.045) or -.08),position.Z)
			surfaceNormal=hit.Normal
			if d.meadow then position=Vector3.new(position.X,hit.Position.Y-.035,position.Z) end
		end
		local cf=CFrame.new(position)*CFrame.Angles(math.rad(d.rotation[1]),math.rad(d.rotation[2]),math.rad(d.rotation[3]))
		local model
		if d.forest then
			local forest=require(script.Parent.ForestArt)
			if d.forest=="log" then cf=forest.slopeFrame(cf,surfaceNormal) end
			model=forest.build(d,templates); model:PivotTo(cf)
		elseif d.template then
			local source=templates:FindFirstChild(d.template); assert(source and source:IsA("Model"),"Unknown nature template")
			model=source:Clone(); model.Name=d.id
			if string.find(d.template,"Grass") then for _,p in ipairs(model:GetDescendants()) do
				if p:IsA("SurfaceAppearance") then p.Color=Color3.fromRGB(138,195,112) end
			end end
			-- The original fern atlas has pale edge pixels. A stable leaf tint limits
			-- their contrast without removing alpha or changing the reviewed mesh.
			if d.template=="Fern_1" then for _,p in ipairs(model:GetDescendants()) do
				if p:IsA("SurfaceAppearance") then p.Color=Color3.fromRGB(143,190,107) end
			end end
			if d.template=="RockPath_Round_Small_1" then for _,p in ipairs(model:GetDescendants()) do
				-- The heavily flattened stones use a quiet native surface; retain the
				-- reviewed geometry without magnifying the source atlas's dark seams.
				if p:IsA("SurfaceAppearance") then p:Destroy()
				elseif p:IsA("MeshPart") then p.TextureID=""; p.Color=Color3.fromRGB(186,176,149); p.Material=Enum.Material.SmoothPlastic; p.CastShadow=false end
			end end
			if d.flatten~=1 then for _,p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then
				p.Size=Vector3.new(p.Size.X,p.Size.Y*d.flatten,p.Size.Z)
				p.Position=Vector3.new(p.Position.X,p.Position.Y*d.flatten,p.Position.Z)
			end end end
			model.WorldPivot=CFrame.identity; model:ScaleTo(d.scale); model:PivotTo(cf)
		else
			model=Instance.new("Part"); model.Name=d.id; model.Size=Vector3.new(table.unpack(d.size)); model.CFrame=cf
			model.Color=Color3.fromRGB(table.unpack(Config.palette[d.color])); model.Material=Enum.Material[d.material]
		end
		local objects=model:IsA("BasePart") and {model} or model:GetDescendants()
		-- TASK04_MEADOW_BEGIN: static tint/grounding, no new asset or material URI.
		if d.meadow then for _,p in ipairs(objects) do
			if p:IsA("SurfaceAppearance") then p.Color=Color3.fromRGB(table.unpack(d.tint)) end
			if p:IsA("BasePart") then
				p.CastShadow=false; p:SetAttribute("Meadow",true); p:SetAttribute("MeadowWind",d.meadowWind)
				p:SetAttribute("MeadowGroundY",position.Y); p:SetAttribute("MeadowRadius",d.radius)
			end
		end end
		-- TASK04_MEADOW_END
		for _,p in ipairs(objects) do if p:IsA("BasePart") then
			p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,d.barrier==true,false,d.barrier==true
			p:SetAttribute("PhysicalBarrier",d.barrier==true)
			p:SetAttribute("EnvironmentDetail",d.detail); p:SetAttribute("EnvironmentWind",false); p:SetAttribute("EnvironmentLight",d.light==true)
		end end
		model.Parent=folder
	end
	require(script.Parent.FenceBarriers).attach(folder)
	require(script.Parent.RidgeBarriers).attach(world.root)
	require(script.Parent.VistaArt).attach(world,folder,templates)
	world.root.ForestFloor.Color=Color3.fromRGB(table.unpack(Config.palette.grass)); world.root.ForestFloor.Material=Enum.Material.Grass
	meadow(world.root.ForestFloor,false)
	require(script.Parent.FarmLandscape).attach(world)
	world.root.Bazaar.Color=Color3.fromRGB(table.unpack(Config.palette.stone)); world.root.Bazaar.Material=Enum.Material.Sandstone
	world.root:SetAttribute("EnvironmentArtEnabled",true); world.root:SetAttribute("EnvironmentPilotPlot",Config.pilotPlot)
	Art.update(world.plots[Config.pilotPlot],0,false)
end
function Art.update(plot,rebirths,aurora)
	if plot.index~=Config.pilotPlot then return end
	local surface=State.surface(Config,rebirths,aurora)
	plot.model.Floor.Color=Color3.fromRGB(table.unpack(surface.color)); plot.model.Floor.Material=Enum.Material[surface.material]
	meadow(plot.model.Floor,false)
end
return Art
