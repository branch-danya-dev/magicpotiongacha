--!nonstrict
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Config=require(Shared.EnvironmentConfig)
local Plan=require(Shared.EnvironmentPlan)
local Field=require(Shared.EnvironmentTerrain)
local State=require(Shared.EnvironmentState)
local Art={}
local function landscape()
	local terrain=workspace.Terrain; local b=Field.bounds; local r=Field.resolution
	local region=Region3.new(Vector3.new(table.unpack(b.min)),Vector3.new(table.unpack(b.max)))
	local materials,occupancy=terrain:ReadVoxels(region,r)
	-- Fill only empty voxels of the reserved pilot region; never clear existing terrain.
	for ix=1,#materials do for iy=1,#materials[ix] do for iz=1,#materials[ix][iy] do
		if occupancy[ix][iy][iz]==0 then
			local x,y,z=b.min[1]+(ix-.5)*r,b.min[2]+(iy-.5)*r,b.min[3]+(iz-.5)*r
			-- Keep the smoothed voxel skin below the original work floor. Studio
			-- raycast assertions cover this boundary; descriptor height alone cannot.
			local h=Field.reserved(x,z) and -2.4 or Field.height(x,z)-2.2
			local solid=math.clamp((h-y+r/2)/r,0,1)
			if solid>0 then
				materials[ix][iy][iz]=Field.height(x,z)<-.5 and Enum.Material.Sand or (y<h-5 and Enum.Material.Rock or Enum.Material.Grass)
				occupancy[ix][iy][iz]=solid
			elseif y< -2 then materials[ix][iy][iz]=Enum.Material.Water; occupancy[ix][iy][iz]=math.clamp((-2-y+r/2)/r,0,1) end
		end
	end end end
	terrain:WriteVoxels(region,r,materials,occupancy)
	terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(141,166,107))
	terrain:SetMaterialColor(Enum.Material.Rock,Color3.fromRGB(135,137,129))
	terrain:SetMaterialColor(Enum.Material.Sand,Color3.fromRGB(190,177,143))
	terrain.WaterColor=Color3.fromRGB(96,149,156); terrain.WaterTransparency=.35; terrain.WaterReflectance=.12
end
function Art.attach(world)
	assert(not world.root:FindFirstChild("EnvironmentArt"),"Environment already attached")
	local templates=game:GetService("ServerStorage"):FindFirstChild("M7NatureTemplates")
	assert(templates,"Reviewed nature templates missing from build")
	landscape()
	-- Terrain collision data becomes queryable on the following simulation step.
	game:GetService("RunService").Heartbeat:Wait()
	local ground=RaycastParams.new(); ground.FilterType=Enum.RaycastFilterType.Include
	ground.FilterDescendantsInstances={workspace.Terrain,world.root.ForestFloor,world.plots[Config.pilotPlot].model.Floor}
	local folder=Instance.new("Folder"); folder.Name="EnvironmentArt"; folder.Parent=world.root
	for _,d in ipairs(Plan.build(Config,Config.pilotPlot).parts) do
		local position=Vector3.new(table.unpack(d.position))
		if d.template then
			local hit=workspace:Raycast(Vector3.new(position.X,60,position.Z),Vector3.new(0,-110,0),ground)
			assert(hit,"Decoration has no supporting ground: "..d.id.." / "..d.template)
			position=Vector3.new(position.X,hit.Position.Y+(d.flatten~=1 and (.16+(tonumber(string.match(d.id,"%d+"))%7)*.045) or -.08),position.Z)
		end
		local cf=CFrame.new(position)*CFrame.Angles(math.rad(d.rotation[1]),math.rad(d.rotation[2]),math.rad(d.rotation[3]))
		local model
		if d.template then
			local source=templates:FindFirstChild(d.template); assert(source and source:IsA("Model"),"Unknown nature template")
			model=source:Clone(); model.Name=d.id
			if string.find(d.template,"Grass") then for _,p in ipairs(model:GetDescendants()) do
				if p:IsA("SurfaceAppearance") then p.Color=Color3.fromRGB(138,195,112) end
			end end
			if d.template=="RockPath_Round_Small_1" then for _,p in ipairs(model:GetDescendants()) do
				-- The heavily flattened stones use a quiet native surface; retain the
				-- reviewed geometry without magnifying the source atlas's dark seams.
				if p:IsA("SurfaceAppearance") then p:Destroy()
				elseif p:IsA("MeshPart") then p.TextureID=""; p.Color=Color3.fromRGB(186,176,149); p.Material=Enum.Material.Slate; p.CastShadow=false end
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
		for _,p in ipairs(objects) do if p:IsA("BasePart") then
			p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,false,false,false
			p:SetAttribute("EnvironmentDetail",d.detail); p:SetAttribute("EnvironmentWind",false); p:SetAttribute("EnvironmentLight",d.light==true)
		end end
		model.Parent=folder
	end
	world.root.ForestFloor.Color=Color3.fromRGB(table.unpack(Config.palette.grass)); world.root.ForestFloor.Material=Enum.Material.Grass
	world.root.Bazaar.Color=Color3.fromRGB(table.unpack(Config.palette.stone)); world.root.Bazaar.Material=Enum.Material.Sandstone
	world.root:SetAttribute("EnvironmentArtEnabled",true); world.root:SetAttribute("EnvironmentPilotPlot",Config.pilotPlot)
	Art.update(world.plots[Config.pilotPlot],0,false)
end
function Art.update(plot,rebirths,aurora)
	if plot.index~=Config.pilotPlot then return end
	local surface=State.surface(Config,rebirths,aurora)
	plot.model.Floor.Color=Color3.fromRGB(table.unpack(surface.color)); plot.model.Floor.Material=Enum.Material[surface.material]
end
return Art
