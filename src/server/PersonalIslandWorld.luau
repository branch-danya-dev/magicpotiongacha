--!nonstrict
-- No slot allocator. An authenticated, configured owner is admitted before load;
-- presentation is constructed only after profile recovery and confirmed save.
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Island=require(Shared.PersonalIsland)
local Session=require(Shared.IslandSession)
local Access=require(Shared.Access)
local Guide=require(Shared.FirstSessionView)
local Props=require(Shared.PropPlan)
local Art=require(script.Parent.PersonalIslandArt)
local Lectern=require(script.Parent.SpellbookLectern)
local World={};World.__index=World
local function anchor(parent,id,position,size)
	local p=Instance.new("Part");p.Name=id;p.Size=size or Vector3.one;p.Position=position
	p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Transparency=1;p.Parent=parent
	return p
end
function World.forOwner(ownerUserId)
	-- Constructor factory keeps this immutable configuration outside client intents.
	assert(Island.validOwner(ownerUserId,true),"Missing AG76QAOwnerUserId")
	return {new=function(config,_count,callbacks,_art)
		local session=Session.new(ownerUserId,game:GetService("RunService"):IsStudio(),true)
		local root=Instance.new("Folder");root.Name="PotionTycoonWorld"
		root:SetAttribute("PersonalIsland",true);root:SetAttribute("IslandId",session.islandId)
		root:SetAttribute("EnvironmentArtEnabled",false);root.Parent=workspace
		return setmetatable({config=config,callbacks=callbacks,root=root,session=session,owners={},plots={}},World)
	end}
end
function World:claim(player)
	local token,reason=self.session:admit(player.UserId,player)
	if not token then warn("AG76_ADMISSION_DENIED",player.UserId,reason) end
	return token
end
function World:activate(player,profile)
	local token=self.session.current
	if not self.session:matches(player,token,"loading") or profile.userId~=self.session.ownerUserId then return false end
	local origin=Vector3.new(table.unpack(Island.origin))
	local model=Instance.new("Model");model.Name="Island_primary"
	model:SetAttribute("IslandId",token.islandId);model:SetAttribute("OwnerUserId",token.ownerUserId)
	model:SetAttribute("IslandGeneration",token.generation);model:SetAttribute("PlotIndex",1) -- visual-only compatibility, never admission
	model.Parent=self.root
	local plot={model=model,origin=origin,index=1,islandId=token.islandId,owner=player,anchors={},props={}}
	self.pendingModel=model -- cleanup also covers a constructor error before activation
	anchor(model,"Floor",origin+Vector3.new(0,-.1,-8),Vector3.new(77,1,75))
	local spawn=Instance.new("SpawnLocation");spawn.Name="Spawn";spawn.Size=Vector3.new(6,1,6)
	spawn.Position=origin+Vector3.new(0,1,20);spawn.Anchored=true;spawn.Transparency=1
	spawn.CanCollide=false;spawn.CanTouch=false;spawn.CanQuery=false;spawn.Neutral=true;spawn.Duration=0;spawn.Parent=model;plot.spawn=spawn
	local offsets=table.clone(Island.serviceOffsets)
	for _,id in ipairs(self.config.stationOrder) do offsets[id]=self.config.stations[id].offset end
	for id,offset in pairs(offsets) do
		local p=anchor(model,id,origin+Vector3.new(table.unpack(offset)),id=="crystal" and Vector3.new(4,6,4) or Vector3.new(8,3,7))
		p:SetAttribute("StationId",id);p:SetAttribute("IslandId",token.islandId)
		local definition=self.config.stations[id]
		if definition then
			p:SetAttribute("InputWaypoint",origin+Vector3.new(table.unpack(definition.waypoints.input)))
			p:SetAttribute("OutputWaypoint",origin+Vector3.new(table.unpack(definition.waypoints.output)))
		end
		local prompt=Instance.new("ProximityPrompt");prompt.MaxActivationDistance=16;prompt.RequiresLineOfSight=false
		prompt.ActionText=id=="crystal" and "+5 Essence" or "Управление";prompt.ObjectText=definition and definition.name or id;prompt.Parent=p
		prompt.Triggered:Connect(function(actor)
			if not self:owned(actor) then return end
			if id=="crystal" then self.callbacks.action(actor,"click",{}) else self.callbacks.focus(actor,id) end
		end)
		plot.anchors[id]=p
	end
	Art.attach(self.root,plot)
	Lectern.ensure(plot,plot.anchors.crystal)
	local book=model:FindFirstChild("SpellbookLectern")
	if book then book:SetAttribute("IslandId",token.islandId);book:SetAttribute("IslandGeneration",token.generation) end
	if not self.session:activate(player,token,profile.userId) then model:Destroy();return false end
	self.owners[player.UserId]=plot;self.plots={plot};self.pendingModel=nil
	player.RespawnLocation=spawn;player:SetAttribute("PotionIslandId",token.islandId)
	player:SetAttribute("PotionIslandGeneration",token.generation);player:SetAttribute("PotionPlotIndex",1)
	return true
end
function World:owned(player)
	local plot=self.owners[player.UserId]
	return plot and plot.owner==player and self.session:matches(player,self.session.current,"active") and plot or nil
end
function World:inBazaar(_player) return false end -- M4 remains OFF; never a UI authorization bypass.
function World:inRange(player,intent,payload,maximum)
	local plot=self:owned(player);if not plot then return false end
	local character=player.Character;local hrp=character and character:FindFirstChild("HumanoidRootPart")
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid or humanoid.Health<=0 then return false end
	if intent=="chooseStarter" or Island.marketAllowed(true,true,intent) then return true end
	local p=plot.anchors[Access.target(intent,payload)]
	return p~=nil and Access.allowed(true,true,(hrp.Position-p.Position).Magnitude,maximum)
end
function World:update(player,profile)
	local plot=self:owned(player);if not plot then return end
	local production=self.callbacks.production(profile)
	for id,station in pairs(profile.stations) do
		local p=plot.anchors[id];local pet=station.workerId and profile.pets[station.workerId]
		p:SetAttribute("Tier",station.level);p:SetAttribute("CauldronId",station.cauldronId)
		p:SetAttribute("WorkerId",station.workerId);p:SetAttribute("WorkerName",pet and pet.name)
		p:SetAttribute("WorkerSpecies",pet and pet.species);p:SetAttribute("WorkerRarity",pet and pet.rarity)
		p:SetAttribute("Working",production[id].code=="working");p:SetAttribute("ProductionStatus",production[id].code)
		p:SetAttribute("Essence",station.essence);p:SetAttribute("QueuedCrates",production[id].queued)
		if id=="logistics" then
			local fromId,toId=Island.haulEndpoints(station.job);local from,to=plot.anchors[fromId],plot.anchors[toId]
			p:SetAttribute("CargoAmount",from and station.job.amount);p:SetAttribute("CargoItem",from and station.job.itemId)
			p:SetAttribute("HaulFrom",from and (from:GetAttribute("OutputWaypoint") or from.Position))
			p:SetAttribute("HaulTo",to and (to:GetAttribute("InputWaypoint") or to.Position))
			p:SetAttribute("HaulProgress",from and math.clamp(station.progress/station.job.duration,0,1))
		end
		if id~="crystal" then
			if station.level>0 and not plot.props[id] then
				plot.props[id]=Art.prop(plot.model,id.."Model",Props.station(self.config,id),CFrame.new(p.Position.X,.5,p.Position.Z))
				local link=Instance.new("ObjectValue");link.Name="PresentationModel";link.Value=plot.props[id].model;link.Parent=p
			end
			if plot.props[id] then
				local state=Props.state(self.config,profile,id,production)
				if not Guide.stationVisible(profile,self.config,id) then state.level=-1 end
				Art.display(plot.props[id],state)
			end
		end
	end
	for id,p in pairs(plot.anchors) do
		local visible=Guide.stationVisible(profile,self.config,id)
		p:SetAttribute("FirstSessionHidden",not visible)
		local prompt=p:FindFirstChildOfClass("ProximityPrompt");prompt.Enabled=visible
		p.Transparency=1 -- only the original crystal fallback may be visible
		if id=="crystal" then
			p.Material=Enum.Material.SmoothPlastic;p.Color=Color3.fromRGB(137,95,234);p.Transparency=0
			prompt.ActionText="+"..tostring(profile.starter and not profile.starter.legacyGrant and self.config.economyV2.clickEssence or self.config.manualClickEssence).." Essence"
		end
	end
end
function World:release(player)
	local token=self.session.current
	if not self.session:matches(player,token) then return end
	self.root:SetAttribute("EnvironmentArtEnabled",false)
	local plot=self.owners[player.UserId]
	if plot then plot.model:Destroy() end
	if self.pendingModel then self.pendingModel:Destroy();self.pendingModel=nil end
	for _,name in ipairs({"EnvironmentArt","ForestFloor"}) do local p=self.root:FindFirstChild(name);if p then p:Destroy() end end
	self.owners[player.UserId]=nil;self.plots={};self.session:release(player,token)
	player.RespawnLocation=nil;player:SetAttribute("PotionIslandId",nil);player:SetAttribute("PotionIslandGeneration",nil);player:SetAttribute("PotionPlotIndex",nil)
end
return World
