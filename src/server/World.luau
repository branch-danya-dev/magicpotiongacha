--!nonstrict
-- Greybox presentation only. Resource accounting never depends on physics or models.
local World = {}
World.__index = World
local Access = require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.Access)
local EnvironmentArt = require(script.Parent.EnvironmentArt)
local PropArt = require(script.Parent.PropArt)
local SessionReveal = require(script.Parent.FirstSessionReveal)

local OFFSETS = {
	warehouse = Vector3.new(-8,2,-30), orders = Vector3.new(10,2,-30),
	altar = Vector3.new(27,2,-32), blueprint = Vector3.new(0,2,10),
}
local COLORS = {
	crystal = Color3.fromRGB(137, 95, 234),
	garden = Color3.fromRGB(82, 128, 87),
	mine = Color3.fromRGB(74, 79, 89),
	distillery = Color3.fromRGB(160, 117, 79),
	cauldron = Color3.fromRGB(93, 109, 130),
	logistics = Color3.fromRGB(106, 154, 161),
	warehouse = Color3.fromRGB(129, 112, 86),
	orders = Color3.fromRGB(173, 145, 88),
	altar = Color3.fromRGB(125, 94, 179), blueprint = Color3.fromRGB(100,180,190),
	press = Color3.fromRGB(154,118,163), centrifuge = Color3.fromRGB(112,193,203),
}

local function part(parent, name, size, position, color)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Position = name, size, position
	p.Anchored, p.Color = true, color
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function billboard(adornee, text, offset)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(230, 64)
	gui.StudsOffset = offset or Vector3.new(0, 5, 0)
	gui.MaxDistance = 115
	gui.AlwaysOnTop = true
	gui.Adornee, gui.Parent = adornee, adornee
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.25
	label.BackgroundColor3 = Color3.fromRGB(21, 25, 33)
	label.TextColor3 = Color3.fromRGB(233, 236, 241)
	label.Font = Enum.Font.GothamMedium
	label.TextSize, label.TextWrapped = 14, true
	label.Text, label.Parent = text, gui
	local corner = Instance.new("UICorner")
	corner.Parent = label
	return label
end

local function prompt(adornee, text, object, callback)
	local p = Instance.new("ProximityPrompt")
	p.ActionText, p.ObjectText = text, object
	p.HoldDuration, p.MaxActivationDistance = 0, 16
	p.RequiresLineOfSight = false
	p.Parent = adornee
	p.Triggered:Connect(callback)
	return p
end

function World.new(config, count, callbacks, environmentArtEnabled)
	for id,def in pairs(config.stations) do OFFSETS[id]=Vector3.new(table.unpack(def.offset)) end
	local self = setmetatable({ config = config, plots = {}, owners = {}, callbacks = callbacks }, World)
	local root = Instance.new("Folder")
	root.Name, root.Parent = "PotionTycoonWorld", workspace
	self.root = root
	self.environmentArtEnabled=environmentArtEnabled==true
	root:SetAttribute("EnvironmentArtEnabled",false)
	part(root, "ForestFloor", Vector3.new(420, 1, 250), Vector3.new(0, -1, 0), Color3.fromRGB(40, 51, 44))
	local bazaar = part(root, "Bazaar", Vector3.new(350, 0.3, 24), Vector3.new(0, 0, 0), Color3.fromRGB(91, 87, 97))
	billboard(bazaar, "МАГИЧЕСКИЙ БАЗАР · M4\nПрямой обмен · закрытая QA-проверка", Vector3.new(0, 8, 0))
	self.tradePost=part(root,"TradePost",Vector3.new(5,2,5),Vector3.new(0,2,0),Color3.fromRGB(121,98,171))
	prompt(self.tradePost,"Trade / Обмен","Магический базар",function(player)
		if self:inBazaar(player) then callbacks.focus(player,"bazaar") end
	end)
	for index = 1, count do
		local column = (index - 1) % 4
		local row = math.floor((index - 1) / 4)
		local origin = Vector3.new((column - 1.5) * 95, 0, row == 0 and -65 or 85)
		local model = Instance.new("Model")
		model.Name = "Plot_" .. index
		model:SetAttribute("PlotIndex", index)
		model.Parent = root
		part(model, "Floor", Vector3.new(77, 1, 75), origin + Vector3.new(0, 0, -8), Color3.fromRGB(65, 70, 68))
		local sign = part(model, "Sign", Vector3.new(11, 1, 1), origin + Vector3.new(0, 7, 27), Color3.fromRGB(65, 70, 68))
		local ownerLabel = billboard(sign, "Свободный участок", Vector3.new(0, 2, 0))
		local spawn = Instance.new("SpawnLocation")
		spawn.Name, spawn.Size = "Spawn", Vector3.new(6, 1, 6)
		spawn.Position, spawn.Anchored, spawn.Neutral = origin + Vector3.new(0, 1, 20), true, true
		spawn.Duration, spawn.Transparency, spawn.Parent = 0, 0.5, model
		local plot = { index = index, model = model, origin = origin, spawn = spawn,
			anchors = {}, labels = {}, pads = {}, padLabels = {}, architecture = {}, ownerLabel = ownerLabel }
		self.plots[index] = plot
		-- Replaceable non-colliding greybox modules; no economic state in geometry.
		for phase=2,4 do
			local color=phase==2 and Color3.fromRGB(115,92,69) or (phase==3 and Color3.fromRGB(128,133,141) or Color3.fromRGB(84,166,181))
			for _,x in ipairs({-36,36}) do
				local frame=part(model,"Phase"..phase.."Frame",Vector3.new(1,phase*3,58),origin+Vector3.new(x,phase*1.5,-10),color)
				frame.CanCollide,frame.CanTouch,frame.CanQuery,frame.Transparency=false,false,false,1
				frame.Material=phase==2 and Enum.Material.Wood or (phase==3 and Enum.Material.Concrete or Enum.Material.Neon)
				table.insert(plot.architecture,{phase=phase,part=frame})
			end
			local canopy=part(model,"Phase"..phase.."Canopy",Vector3.new(72,0.4,12),origin+Vector3.new(0,phase*3,-37),color)
			canopy.CanCollide,canopy.CanTouch,canopy.CanQuery,canopy.Transparency=false,false,false,1
			table.insert(plot.architecture,{phase=phase,part=canopy})
		end
		for id, offset in pairs(OFFSETS) do
			local station = config.stations[id]
			local title = station and station.name or (id == "warehouse" and "Склад" or (id == "altar" and "Алтарь · фамильяры" or (id == "blueprint" and "Развитие / Rebirth / Daily" or "Доска заказов")))
			local size = id == "crystal" and Vector3.new(4, 6, 4) or Vector3.new(8, 3, 7)
			local anchor = part(model, id, size, origin + offset, COLORS[id] or COLORS[station and station.archetype] or Color3.fromRGB(140,140,150))
			anchor:SetAttribute("StationId", id)
			if station then
				anchor:SetAttribute("InputWaypoint",origin+Vector3.new(table.unpack(station.waypoints.input)))
				anchor:SetAttribute("OutputWaypoint",origin+Vector3.new(table.unpack(station.waypoints.output)))
			end
			if id == "crystal" then
				anchor.Material = Enum.Material.Neon
				anchor.CFrame *= CFrame.Angles(0, math.rad(45), math.rad(10))
			end
			plot.anchors[id] = anchor
			plot.labels[id] = billboard(anchor, title)
			prompt(anchor, id == "crystal" and "+1 эссенция" or "Управление", title, function(player)
				if plot.owner ~= player then return end
				if id == "crystal" then callbacks.action(player, "click", {})
				else callbacks.focus(player, id) end
			end)
			if station or id == "warehouse" or id == "blueprint" then
				local pad = part(model, "Buy_" .. id, Vector3.new(5, 0.25, 4), origin + offset + Vector3.new(0, -offset.Y + 0.8, 7), Color3.fromRGB(182, 157, 70))
				pad.Material = Enum.Material.Neon
				pad.CanCollide = false
				plot.pads[id], plot.padLabels[id] = pad, billboard(pad, "Улучшить", Vector3.new(0, 2.5, 0))
				-- Body-part contacts can recur while a player stays on a pad.
				-- Spend Gold only after an explicit keyboard/gamepad/touch activation.
				local purchasePrompt = prompt(pad, "Купить улучшение", title, function(player)
					if plot.owner ~= player then return end
					local level, requestId = pad:GetAttribute("ExpectedLevel"), pad:GetAttribute("ExpectedRequestId")
					if level ~= nil and requestId then
						if id=="blueprint" then callbacks.action(player,"advancePhase",{expectedPhase=level,requestId=requestId})
						else callbacks.action(player,"build",{upgradeId=id,expectedLevel=level,requestId=requestId}) end
					end
				end)
				purchasePrompt.MaxActivationDistance = 8
				purchasePrompt.HoldDuration = 0.5
				purchasePrompt.KeyboardKeyCode = Enum.KeyCode.F
			end
		end
	end
	if self.environmentArtEnabled then EnvironmentArt.attach(self) end
	if self.environmentArtEnabled then PropArt.attach(self) end
	return self
end

function World:claim(player)
	for _, plot in ipairs(self.plots) do
		if not plot.owner then
			plot.owner = player
			plot.model:SetAttribute("OwnerUserId", player.UserId)
			plot.ownerLabel.Text = player.DisplayName .. " · Лаборатория"
			self.owners[player.UserId] = plot
			player.RespawnLocation = plot.spawn
			player:SetAttribute("PotionPlotIndex", plot.index)
			return plot
		end
	end
	return nil
end

function World:release(player)
	local plot = self.owners[player.UserId]
	if not plot or plot.owner ~= player then return end
	plot.owner, self.owners[player.UserId] = nil, nil
	plot.model:SetAttribute("OwnerUserId", nil)
	plot.ownerLabel.Text = "Свободный участок"
	for _, anchor in pairs(plot.anchors) do
		anchor:SetAttribute("WorkerId", nil)
		anchor:SetAttribute("WorkerName", nil)
		anchor:SetAttribute("Working", false)
		anchor:SetAttribute("HaulFrom", nil)
		anchor:SetAttribute("HaulTo", nil)
		anchor:SetAttribute("HaulProgress", nil)
		anchor:SetAttribute("CargoAmount", nil)
		anchor:SetAttribute("CargoItem", nil)
		anchor:SetAttribute("QueuedCrates", nil)
	end
	for _, pad in pairs(plot.pads) do pad:SetAttribute("ExpectedLevel", nil); pad:SetAttribute("ExpectedRequestId",nil) end
	for _,module in ipairs(plot.architecture) do module.part.Transparency=1 end
	if self.environmentArtEnabled then PropArt.release(plot) end
end

function World:inBazaar(player)
	local character=player.Character
	local hrp=character and character:FindFirstChild("HumanoidRootPart")
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then return false end
	return math.abs(hrp.Position.Z)<=12 and Access.allowed(true,humanoid.Health>0,(hrp.Position-self.tradePost.Position).Magnitude,20)
end

function World:inRange(player, action, payload, maxDistance)
	local plot = self.owners[player.UserId]
	if not plot or plot.owner ~= player then return false end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid or humanoid.Health <= 0 then return false end
	local id = Access.target(action, payload)
	local anchor = plot.anchors[id]
	return anchor ~= nil and Access.allowed(plot.owner == player, humanoid.Health > 0, (hrp.Position - anchor.Position).Magnitude, maxDistance)
end

function World:update(player, profile)
	local plot = self.owners[player.UserId]
	if not plot or plot.owner ~= player then return end
	local phase=self.callbacks.phaseState(profile)
	local epoch=self.config.epochRules[profile.rebirths%3]; local color=Color3.fromRGB(table.unpack(epoch.color))
	plot.model.Floor.Color=color:Lerp(Color3.fromRGB(45,45,50),0.55)
	plot.model.Floor.Material=profile.entitlements.aurora_theme and Enum.Material.Neon or Enum.Material.Grass
	if profile.entitlements.aurora_theme then plot.model.Floor.Color=Color3.fromRGB(96,116,168) end
	local title=profile.entitlements.chrononaut and " · Хрононавт" or (profile.entitlements.chronicler and " · Летописец" or "")
	plot.ownerLabel.Text = player.DisplayName .. title.." · "..epoch.name.."\n"..phase.name.." · цикл "..profile.rebirths
	for _,module in ipairs(plot.architecture) do module.part.Transparency=module.phase==profile.phase and 0.35 or 1; module.part.Color=color end
	for _,pad in pairs(plot.pads) do pad:SetAttribute("ExpectedRequestId",profile.progression.sequence+1) end
	plot.pads.blueprint:SetAttribute("ExpectedLevel",profile.phase)
	plot.padLabels.blueprint.Text=phase.cost and ("Фаза "..(profile.phase+1)..": "..phase.cost.." Gold\n"..table.concat(phase.reasons,"; ")) or phase.message
	plot.labels.blueprint.Text=phase.name.."\n"..phase.message
	local production = self.callbacks.production(profile)
	for id, station in pairs(profile.stations) do
		local anchor = plot.anchors[id]
		if anchor then
			local definition = self.config.stations[id]
			anchor.Transparency = station.level > 0 and 0 or 0.78
			anchor:SetAttribute("Tier", station.level)
			anchor:SetAttribute("CauldronId", station.cauldronId)
			if definition.archetype=="cauldron" then
				anchor.Material=station.level>=3 and Enum.Material.Metal or Enum.Material.SmoothPlastic
				anchor.Color=station.level>=3 and Color3.fromRGB(115,192,204) or (station.level==2 and Color3.fromRGB(178,119,75) or COLORS.cauldron)
				local item=station.cauldronId and profile.cauldrons[station.cauldronId]
				if item and item.type=="spectral" then anchor.Color=Color3.fromRGB(119,225,237); anchor.Material=Enum.Material.Neon end
				local glow=anchor:FindFirstChild("SpectralGlow")
				if not glow then glow=Instance.new("PointLight"); glow.Name="SpectralGlow"; glow.Color=Color3.fromRGB(119,225,237); glow.Range=8; glow.Brightness=1.2; glow.Parent=anchor end
				glow.Enabled=item~=nil and item.type=="spectral" and station.job~=nil
			end
			anchor:SetAttribute("WorkerId", station.workerId)
			local pet = station.workerId and profile.pets[station.workerId]
			anchor:SetAttribute("WorkerName", pet and pet.name)
			anchor:SetAttribute("WorkerSpecies", pet and pet.species)
			anchor:SetAttribute("WorkerRarity", pet and pet.rarity)
			local state = production[id]
			anchor:SetAttribute("Working", state.code == "working")
			anchor:SetAttribute("ProductionStatus", state.code)
			anchor:SetAttribute("Essence", station.essence)
			anchor:SetAttribute("QueuedCrates", state.queued)
			if id == "logistics" then
				local job = station.job
				if job and job.kind == "haul" then
					local from = job.sourceKind == "inventory" and plot.anchors.warehouse or plot.anchors[job.sourceStationId]
					local target = job.destinationKind == "questStock" and plot.anchors.orders
						or (job.destinationKind == "inventory" and plot.anchors.warehouse or plot.anchors[job.destinationStationId])
					anchor:SetAttribute("CargoAmount", job.amount)
					anchor:SetAttribute("CargoItem", job.itemId)
					anchor:SetAttribute("HaulFrom", from and (from:GetAttribute("OutputWaypoint") or from.Position))
					anchor:SetAttribute("HaulTo", target and (target:GetAttribute("InputWaypoint") or target.Position))
					anchor:SetAttribute("HaulProgress", math.clamp(station.progress / job.duration, 0, 1))
				else
					anchor:SetAttribute("HaulFrom", nil)
					anchor:SetAttribute("HaulTo", nil)
					anchor:SetAttribute("HaulProgress", nil)
					anchor:SetAttribute("CargoAmount", nil)
					anchor:SetAttribute("CargoItem", nil)
				end
			end
			local name=definition.outputItem and epoch.resourceNames[definition.outputItem] or definition.name
			plot.labels[id].Text = name .. " · ур. " .. station.level .. "\n" .. state.text
			plot.pads[id]:SetAttribute("ExpectedLevel", station.level)
			local build=self.callbacks.buildState(profile,id)
			plot.padLabels[id].Text = build.cost and ("Купить: " .. build.cost .. " Gold\n" .. build.reason) or "Максимальный уровень"
		end
	end
	local warehouseCost = self.callbacks.buildState(profile,"warehouse").cost
	plot.pads.warehouse:SetAttribute("ExpectedLevel", profile.warehouseLevel)
	plot.padLabels.warehouse.Text = warehouseCost and ("Склад: " .. warehouseCost .. " Gold") or "Склад MAX"
	local order = self.callbacks.orderProgress(profile)
	plot.labels.orders.Text = profile.order and ("Заказ NPC: " .. order.delivered .. "/" .. profile.order.count
		.. "\nУ котла: " .. order.queued .. " · В пути: " .. order.travelling .. " · " .. order.remainingSeconds .. " сек.") or "Доска заказов · выбери контракт"
	SessionReveal.apply(self, plot, profile)
	if self.environmentArtEnabled then EnvironmentArt.update(plot,profile.rebirths,profile.entitlements.aurora_theme==true) end
	if self.environmentArtEnabled then PropArt.update(plot,profile,production) end
end

return World
