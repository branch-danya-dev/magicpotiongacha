--!nonstrict
-- Greybox presentation only. Resource accounting never depends on physics or models.
local World = {}
World.__index = World
local Access = require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.Access)

local OFFSETS = {
	crystal = Vector3.new(0, 3, -2),
	garden = Vector3.new(-20, 1.5, 0),
	mine = Vector3.new(-20, 1.5, -20),
	distillery = Vector3.new(15, 2, -18),
	cauldron = Vector3.new(20, 2, 0),
	logistics = Vector3.new(0, 2, -27),
	warehouse = Vector3.new(-8, 2, -30),
	orders = Vector3.new(10, 2, -30),
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

function World.new(config, count, callbacks)
	local self = setmetatable({ config = config, plots = {}, owners = {}, callbacks = callbacks }, World)
	local root = Instance.new("Folder")
	root.Name, root.Parent = "PotionTycoonWorld", workspace
	self.root = root
	part(root, "ForestFloor", Vector3.new(420, 1, 250), Vector3.new(0, -1, 0), Color3.fromRGB(40, 51, 44))
	local bazaar = part(root, "Bazaar", Vector3.new(350, 0.3, 24), Vector3.new(0, 0, 0), Color3.fromRGB(91, 87, 97))
	billboard(bazaar, "МАГИЧЕСКИЙ БАЗАР · M1\nЗаказы и производство", Vector3.new(0, 8, 0))
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
			anchors = {}, labels = {}, pads = {}, padLabels = {}, ownerLabel = ownerLabel }
		self.plots[index] = plot
		for id, offset in pairs(OFFSETS) do
			local station = config.stations[id]
			local title = station and station.name or (id == "warehouse" and "Склад" or "Доска заказов")
			local size = id == "crystal" and Vector3.new(4, 6, 4) or Vector3.new(8, 3, 7)
			local anchor = part(model, id, size, origin + offset, COLORS[id])
			anchor:SetAttribute("StationId", id)
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
			if station or id == "warehouse" then
				local pad = part(model, "Buy_" .. id, Vector3.new(5, 0.25, 4), origin + offset + Vector3.new(0, -offset.Y + 0.8, 7), Color3.fromRGB(182, 157, 70))
				pad.Material = Enum.Material.Neon
				pad.CanCollide = false
				plot.pads[id], plot.padLabels[id] = pad, billboard(pad, "Улучшить", Vector3.new(0, 2.5, 0))
				-- Body-part contacts can recur while a player stays on a pad.
				-- Spend Gold only after an explicit keyboard/gamepad/touch activation.
				local purchasePrompt = prompt(pad, "Купить улучшение", title, function(player)
					if plot.owner ~= player then return end
					local level = pad:GetAttribute("ExpectedLevel")
					if level ~= nil then callbacks.action(player, "buy", { upgradeId = id, expectedLevel = level }) end
				end)
				purchasePrompt.MaxActivationDistance = 8
				purchasePrompt.HoldDuration = 0.5
				purchasePrompt.KeyboardKeyCode = Enum.KeyCode.F
			end
		end
	end
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
	for _, pad in pairs(plot.pads) do pad:SetAttribute("ExpectedLevel", nil) end
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
	plot.ownerLabel.Text = player.DisplayName .. " · Rebirth " .. profile.rebirths
	local production = self.callbacks.production(profile)
	for id, station in pairs(profile.stations) do
		local anchor = plot.anchors[id]
		if anchor then
			local definition = self.config.stations[id]
			anchor.Transparency = station.level > 0 and 0 or 0.78
			anchor:SetAttribute("Tier", station.level)
			anchor:SetAttribute("WorkerId", station.workerId)
			local pet = station.workerId and profile.pets[station.workerId]
			anchor:SetAttribute("WorkerName", pet and pet.name)
			anchor:SetAttribute("WorkerSpecies", pet and pet.species)
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
					anchor:SetAttribute("HaulFrom", from and from.Position)
					anchor:SetAttribute("HaulTo", target and target.Position)
					anchor:SetAttribute("HaulProgress", math.clamp(station.progress / job.duration, 0, 1))
				else
					anchor:SetAttribute("HaulFrom", nil)
					anchor:SetAttribute("HaulTo", nil)
					anchor:SetAttribute("HaulProgress", nil)
					anchor:SetAttribute("CargoAmount", nil)
					anchor:SetAttribute("CargoItem", nil)
				end
			end
			plot.labels[id].Text = definition.name .. " · ур. " .. station.level .. "\n" .. state.text
			plot.pads[id]:SetAttribute("ExpectedLevel", station.level)
			local cost = definition.upgradeCosts[station.level + 1]
			plot.padLabels[id].Text = cost and ("Улучшить: " .. cost .. " Gold") or "Максимальный уровень"
		end
	end
	local warehouseCost = self.config.warehouse.upgradeCosts[(profile.warehouseLevel or 0) + 1]
	plot.pads.warehouse:SetAttribute("ExpectedLevel", profile.warehouseLevel)
	plot.padLabels.warehouse.Text = warehouseCost and ("Склад: " .. warehouseCost .. " Gold") or "Склад MAX"
	local order = self.callbacks.orderProgress(profile)
	plot.labels.orders.Text = profile.order and ("Заказ NPC: " .. order.delivered .. "/" .. profile.order.count
		.. "\nУ котла: " .. order.queued .. " · В пути: " .. order.travelling .. " · " .. order.remainingSeconds .. " сек.") or "Доска заказов · выбери контракт"
end

return World
