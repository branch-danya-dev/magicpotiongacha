--!nonstrict
-- Server presentation adapter. Original anchors, collisions, prompts and intents
-- remain in World; these inert models never decide ownership or spend resources.
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Plan=require(Shared.PropPlan)
local EnvironmentPlan=require(Shared.EnvironmentPlan)
local EnvironmentConfig=require(Shared.EnvironmentConfig)
local Art={}
local function color(tint) return Color3.fromRGB(table.unpack(Plan.palette[tint])) end
local function build(parent,name,pieces,basis)
	local model=Instance.new("Model"); model.Name=name
	local entries={}
	for _,d in ipairs(pieces) do
		local p=Instance.new(d.shape=="Wedge" and "WedgePart" or "Part"); p.Name=d.name
		p.Size=Vector3.new(table.unpack(d.size))
		p.CFrame=basis*CFrame.new(table.unpack(d.position))*CFrame.Angles(math.rad(d.rotation[1]),math.rad(d.rotation[2]),math.rad(d.rotation[3]))
		if d.shape=="Cylinder" then p.Shape=Enum.PartType.Cylinder end
		if d.shape=="Sphere" then local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Sphere; mesh.Scale=Vector3.one; mesh.Parent=p end
		p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false
		p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
		p.Reflectance=0; p.CastShadow=d.role~="status"; p.Transparency=1
		p.Color=color(d.tint); p.Material=Enum.Material[d.material]
		p.Parent=model; table.insert(entries,{part=p,definition=d})
	end
	model.Parent=parent
	return {model=model,entries=entries}
end
local function display(record,state)
	for _,entry in ipairs(record.entries) do
		local visible,tint,material=Plan.appearance(entry.definition,state)
		local alpha=visible and 0 or 1; local p=entry.part
		if p.Transparency~=alpha then p.Transparency=alpha end
		if entry.tint~=tint then p.Color=color(tint); entry.tint=tint end
		if entry.material~=material then p.Material=Enum.Material[material]; entry.material=material end
	end
end
local function hideAnchors(plot)
	for _,anchor in pairs(plot.anchors) do anchor.Transparency=1 end
	for _,pad in pairs(plot.pads) do pad.Transparency=1 end
	for _,module in ipairs(plot.architecture) do module.part.Transparency=1 end
	plot.model.Sign.Transparency=1
end
function Art.attach(world)
	local plot=assert(world.plots[EnvironmentConfig.pilotPlot])
	assert(not plot.props,"Pilot prop owner already attached")
	local folder=Instance.new("Folder"); folder.Name="PilotProps"; folder.Parent=plot.model
	local props={folder=folder,stations={},static={},config=world.config}; plot.props=props
	local filter=RaycastParams.new(); filter.FilterType=Enum.RaycastFilterType.Include; filter.FilterDescendantsInstances={workspace.Terrain}
	local function ground(x,z)
		local hit=workspace:Raycast(Vector3.new(x,60,z),Vector3.new(0,-110,0),filter)
		return hit and hit.Position.Y+.025 or .5
	end
	local partCount,triangles=0,0
	local function create(name,pieces,cf)
		local count,cost=Plan.metrics(pieces); partCount+=count; triangles+=cost
		assert(partCount<=Plan.maxParts and triangles<=Plan.maxTriangleCharge,"Pilot prop budget exceeded")
		return build(folder,name,pieces,cf)
	end
	local function link(anchor,model)
		assert(not anchor:FindFirstChild("PresentationModel"),"Duplicate presentation link")
		local value=Instance.new("ObjectValue"); value.Name="PresentationModel"; value.Value=model; value.Parent=anchor
	end
	for id,anchor in pairs(plot.anchors) do
		local position=anchor.Position
		local record=create(id.."Model",Plan.station(world.config,id),CFrame.new(position.X,ground(position.X,position.Z),position.Z))
		props.stations[id]=record; link(anchor,record.model)
	end
	props.workshop=create("RearWorkshop",Plan.workshop(),CFrame.new(plot.origin.X,ground(plot.origin.X,plot.origin.Z-41.5),plot.origin.Z-41.5))
	-- Dress only the six existing lamps and two sample stalls. Their original
	-- EnvironmentLight anchors remain for the single EnvironmentView light owner.
	local env=EnvironmentPlan.build(EnvironmentConfig,EnvironmentConfig.pilotPlot)
	for i,d in ipairs(env.parts) do
		if d.light then
			local anchor=assert(world.root.EnvironmentArt:FindFirstChild(d.id))
			local lamp=create("Lantern_"..i,Plan.lantern(),CFrame.new(anchor.Position))
			table.insert(props.static,lamp); anchor.Transparency=1
			local cap=env.parts[i+1]
			assert(cap and cap.position[1]==d.position[1] and cap.position[3]==d.position[3],"Lamp cap moved")
			world.root.EnvironmentArt[cap.id].Transparency=1
		end
		if math.abs(d.position[1])==12 and (d.position[3]==-18 or d.position[3]==-23 or d.position[3]==-20.5 or d.position[3]==-22) then
			local old=assert(world.root.EnvironmentArt:FindFirstChild(d.id)); assert(not d.barrier and not d.light)
			old.Transparency=1
		end
	end
	for _,x in ipairs({-12,12}) do
		table.insert(props.static,create("MarketSample_"..x,Plan.market(false),CFrame.new(x,ground(x,-20.5),-20.5)))
	end
	local post=world.tradePost
	local trading=create("BarterCounter",Plan.market(true),CFrame.new(post.Position.X,ground(post.Position.X,post.Position.Z),post.Position.Z))
	table.insert(props.static,trading); link(post,trading.model); post.Transparency=1
	for _,record in ipairs(props.static) do display(record,{level=1,phase=1}) end
	world.root:SetAttribute("PilotPropParts",partCount); world.root:SetAttribute("PilotPropTriangleCharge",triangles)
	world.root:SetAttribute("PilotPropVersion",1)
	Art.update(plot,nil,nil)
end
function Art.update(plot,profile,production)
	local props=plot.props; if not props then return end
	hideAnchors(plot)
	for id,record in pairs(props.stations) do display(record,Plan.state(props.config,profile,id,production)) end
	display(props.workshop,Plan.state(props.config,profile,"workshop",production))
end
function Art.release(plot) Art.update(plot,nil,nil) end
return Art
