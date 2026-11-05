--!nonstrict
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Config=require(Shared.EnvironmentConfig)
local Plan=require(Shared.EnvironmentPlan)
local State=require(Shared.EnvironmentState)
local Art={}
function Art.attach(world)
	local folder=Instance.new("Folder"); folder.Name="EnvironmentArt"; folder.Parent=world.root
	for _,d in ipairs(Plan.build(Config,Config.pilotPlot).parts) do
		local p=Instance.new("Part"); p.Name=d.id; p.Size=Vector3.new(table.unpack(d.size))
		p.CFrame=CFrame.new(table.unpack(d.position))*CFrame.Angles(math.rad(d.rotation[1]),math.rad(d.rotation[2]),math.rad(d.rotation[3]))
		p.Shape=d.kind=="trunk" and Enum.PartType.Cylinder or Enum.PartType.Block
		if d.kind=="ball" then
			-- PartType.Ball clamps to a sphere. Built-in Sphere mesh preserves the
			-- descriptor's ellipsoid proportions (paths, hills, leaves); no asset ID.
			local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Sphere; mesh.Parent=p
		end
		p.Color=Color3.fromRGB(table.unpack(Config.palette[d.color])); p.Material=Enum.Material[d.material]
		p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery=true,false,false,false
		p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
		p:SetAttribute("EnvironmentDetail",d.detail); p:SetAttribute("EnvironmentWind",d.wind==true); p:SetAttribute("EnvironmentLight",d.light==true)
		p.Parent=folder
	end
	world.root.ForestFloor.Color=Color3.fromRGB(112,145,102); world.root.ForestFloor.Material=Enum.Material.Grass
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
