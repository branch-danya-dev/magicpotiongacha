--!nonstrict
-- Swaps the crystal generator's visible mesh for an imported Spellbook Lectern.
-- The crystal anchor, prompt, upgrades and Essence stay exactly where the simulation left them.
-- Studio import, after opening build/PotionTycoon.rbxlx:
-- 1. Home or Avatar tab → Import 3D.
-- 2. Choose assets/props/spellbook-lectern.glb. Leave scale at the file default.
-- 3. Name the inserted Model SpellbookLectern.
-- 4. Move that Model to ServerStorage. Do not add scripts, lights or emitters.
-- 5. Press Play. Rebuilding the rbxlx removes the import, so repeat these steps after npm test.
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Plan = require(ReplicatedStorage.PotionTycoon.Shared.SpellbookLecternPlan)

local Lectern = {}

local function modelNamed(parent)
	if not parent then return nil end
	local found = parent:FindFirstChild(Plan.templateName)
	if found and found:IsA("Model") then return found end
	return nil
end

function Lectern.findTemplate()
	local direct = modelNamed(ServerStorage)
	if direct then return direct end
	local stored = modelNamed(ServerStorage:FindFirstChild("PotionTycoon"))
	if stored then return stored end
	local shared = ReplicatedStorage:FindFirstChild("PotionTycoon")
	return modelNamed(shared)
end

local function hostPart(model)
	local named = model:FindFirstChild("Spellbook", true)
	if named and named:IsA("BasePart") then return named end
	if model.PrimaryPart then return model.PrimaryPart end
	for _, child in ipairs(model:GetDescendants()) do
		if child:IsA("BasePart") then return child end
	end
	return nil
end

local function fit(model)
	local _, size = model:GetBoundingBox()
	if size.Y <= 0.05 or not model.GetScale or not model.ScaleTo then return size end
	local nextScale = model:GetScale() * Plan.uniformScale(size.Y)
	local ok = pcall(function() model:ScaleTo(nextScale) end)
	if not ok then return size end
	local _, fitted = model:GetBoundingBox()
	return fitted
end

local function floorY(plot, anchor)
	local fallback = plot.origin.Y + 0.5
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	local hit = workspace:Raycast(Vector3.new(anchor.Position.X, anchor.Position.Y + 40, anchor.Position.Z), Vector3.new(0, -120, 0), params)
	if hit then return hit.Position.Y end
	return fallback
end

local function seat(model, base)
	local boxCf, boxSize = model:GetBoundingBox()
	local pivot = model:GetPivot()
	local bottomY = boxCf.Position.Y - boxSize.Y / 2
	model:PivotTo(pivot + Vector3.new(base.X - boxCf.Position.X, base.Y - bottomY, base.Z - boxCf.Position.Z))
	model.WorldPivot = CFrame.new(base)
end

local function markParts(model)
	local scripts = {}
	for _, child in ipairs(model:GetDescendants()) do
		if child:IsA("LuaSourceContainer") then table.insert(scripts, child) end
	end
	for _, child in ipairs(scripts) do child:Destroy() end
	for _, child in ipairs(model:GetDescendants()) do
		if child:IsA("BasePart") then
			child.Anchored = true
			child.CanCollide = false
			child.CanTouch = false
			child.CanQuery = false
			child:SetAttribute("LecternPart", child.Name)
		end
	end
end

local function addPoint(model, name, worldPos)
	local host = hostPart(model)
	if not host then return end
	local point = Instance.new("Attachment")
	point.Name = name
	point.Position = host.CFrame:PointToObjectSpace(worldPos)
	point.Parent = host
end

function Lectern.hideProcedural(anchor)
	local link = anchor:FindFirstChild("PresentationModel")
	local presented = link and link.Value
	if not presented then return end
	for _, child in ipairs(presented:GetDescendants()) do
		if child:IsA("BasePart") then child.Transparency = 1 end
	end
end

function Lectern.ensure(plot, anchor)
	if not plot or not anchor or not Lectern.findTemplate() then return false end
	local xz = Vector3.new(anchor.Position.X, 0, anchor.Position.Z)
	anchor.Transparency = 1
	anchor.Material = Enum.Material.SmoothPlastic
	anchor.CastShadow = false
	local link = anchor:FindFirstChild("SpellbookVisual")
	local model = link and link.Value
	if not model or not model.Parent then
		model = Lectern.findTemplate():Clone()
		model.Name = Plan.templateName
		model:SetAttribute("StationId", Plan.stationId)
		model:SetAttribute("GeneratorId", Plan.stationId)
		markParts(model)
		model.Parent = plot.model
		local size = fit(model)
		local base = Vector3.new(xz.X, floorY(plot, anchor), xz.Z)
		seat(model, base)
		local energy = Plan.point(Plan.energy, { x = size.X, y = size.Y, z = size.Z })
		local particles = Plan.point(Plan.particles, { x = size.X, y = size.Y, z = size.Z })
		addPoint(model, "EnergyPoint", base + Vector3.new(energy[1], energy[2], energy[3]))
		addPoint(model, "ParticlePoint", base + Vector3.new(particles[1], particles[2], particles[3]))
		local value = link or Instance.new("ObjectValue")
		value.Name = "SpellbookVisual"
		value.Value = model
		value.Parent = anchor
		anchor:SetAttribute("VisualModel", Plan.templateName)
		local boxCf, boxSize = model:GetBoundingBox()
		anchor.Size = boxSize
		anchor.CFrame = CFrame.new(xz.X, boxCf.Position.Y, xz.Z)
	end
	Lectern.hideProcedural(anchor)
	return true
end

function Lectern.install(world)
	local function refresh(plot)
		if plot and plot.anchors then Lectern.ensure(plot, plot.anchors.crystal) end
	end
	for _, plot in ipairs(world.plots) do refresh(plot) end
	local previous = world.update
	function world.update(self, player, profile)
		previous(self, player, profile)
		local owned = self.owners[player.UserId]
		if owned then refresh(owned) end
	end
end

return Lectern
