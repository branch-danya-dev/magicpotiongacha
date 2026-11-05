--!nonstrict
-- Bounded startup-only backdrop, wholly outside the accepted traversal contour.
local Plan=require(game.ReplicatedStorage.PotionTycoon.Shared.VistaPlan)
local Art={}
function Art.attach(world,parent,templates)
	assert(not parent:FindFirstChild("PilotVista"),"Pilot backdrop already built")
	local folder=Instance.new("Folder"); folder.Name="PilotVista"
	local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances={workspace.Terrain}; params.IgnoreWater=true
	local cache={}
	local function ground(x,z)
		local key=x..":"..z
		if cache[key] then return cache[key] end
		local hit=workspace:Raycast(Vector3.new(x,72,z),Vector3.new(0,-150,0),params)
		assert(hit,"Backdrop ground missing: "..key); cache[key]=hit.Position.Y
		return hit.Position.Y
	end
	local plan=Plan.build()
	for _,d in ipairs(plan.parts) do
		local p
		if d.shape=="Mesh" then
			p=assert(templates:FindFirstChild(d.template):FindFirstChild(d.source),"Unreviewed vista mesh"):Clone()
			local surface=p:FindFirstChildOfClass("SurfaceAppearance")
			if surface then surface.Color=Color3.fromRGB(table.unpack(Plan.palette[d.color])) end
		else
			p=Instance.new(d.shape=="Wedge" and "WedgePart" or "Part")
			p.Material=d.window and Enum.Material.Neon or Enum.Material.SmoothPlastic
			p.Color=Color3.fromRGB(table.unpack(Plan.palette[d.color])); p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
		end
		p.Name=d.id; p.Size=Vector3.new(table.unpack(d.size))
		local y=d.position[2]
		if d.grounded then
			local a=d.groundAnchor or {d.position[1],d.position[3]}
			y=ground(a[1],a[2])+d.bottom+d.size[2]/2
		end
		p.CFrame=CFrame.new(d.position[1],y,d.position[3])*CFrame.Angles(0,math.rad(d.angle),0)*CFrame.Angles(0,0,math.rad(d.roll or 0))
		p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery,p.CastShadow=true,false,false,false,false
		p:SetAttribute("VistaRole",d.role); p:SetAttribute("VistaWindow",d.window==true)
		p:SetAttribute("EnvironmentDetail",1); p.Parent=folder
	end
	folder.Parent=parent
	world.root:SetAttribute("PilotVistaVersion",Plan.version)
	world.root:SetAttribute("PilotVistaParts",plan.metrics.parts)
	world.root:SetAttribute("PilotVistaTriangleCharge",plan.metrics.triangles)
end
return Art
