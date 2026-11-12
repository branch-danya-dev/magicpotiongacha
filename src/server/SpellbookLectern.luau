--!nonstrict
-- Tracked native template -> inert per-plot clones. Logical anchors never move.
-- Clients reveal a clone only after its mesh references load successfully.
local ServerStorage = game:GetService("ServerStorage")
local Shared = game:GetService("ReplicatedStorage").PotionTycoon.Shared
local CollectionService = game:GetService("CollectionService")
local Plan = require(Shared.SpellbookLecternPlan)
local Placement = require(Shared.SpellbookPlacement)
local Lectern = {}
local installed = setmetatable({}, { __mode = "k" })
local warned = setmetatable({}, { __mode = "k" })

function Lectern.findTemplate()
	return ServerStorage:FindFirstChild(Plan.templateName)
end
local function validate(model)
	if not model then return false, "missing-template" end
	if not model:IsA("Model") then return false, "invalid-template-class" end
	local entries = {}
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("MeshPart") then
			table.insert(entries, { name = part.Name, meshId = part.MeshId,
				textureId = part.TextureID, anchored = part.Anchored,
				collides = part.CanCollide or part.CanTouch or part.CanQuery })
		elseif not part:IsA("Model") then
			return false, "unexpected-template-child: " .. part.ClassName
		end
	end
	return Plan.validateParts(entries)
end
Lectern.validate = validate
local function floorY(plot, anchor)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	local hit = workspace:Raycast(anchor.Position + Vector3.new(0, 40, 0), Vector3.new(0, -120, 0), params)
	return hit and hit.Position.Y or plot.origin.Y + 0.5
end
local ops = {}
function ops.target(plot, anchor)
	return plot and plot.model and anchor and anchor:IsA("BasePart")
		and anchor.Parent == plot.model and anchor:GetAttribute("StationId") == Plan.stationId
end
function ops.existing(anchor) return anchor:FindFirstChild("SpellbookVisual") end
function ops.belongs(link, plot, anchor)
	if not link:IsA("ObjectValue") then return false end
	local model = link.Value
	local back = model and model:FindFirstChild("LecternAnchor")
	return model and model:IsA("Model") and model.Parent == plot.model
		and back and back:IsA("ObjectValue") and back.Value == anchor
		and model:GetAttribute("PlotIndex") == plot.index
end
ops.template = Lectern.findTemplate
ops.validate = validate
function ops.clone(template) return template:Clone() end
function ops.prepare(model, plot, anchor)
	local _, size = model:GetBoundingBox()
	assert(Plan.validHeight(size.Y), "Invalid mesh bounds")
	model:ScaleTo(model:GetScale() * Plan.uniformScale(size.Y))
	local box, fitted = model:GetBoundingBox()
	assert(math.abs(fitted.Y - Plan.targetHeight) < 0.01, "Scale failed")
	local base = Vector3.new(anchor.Position.X, floorY(plot, anchor), anchor.Position.Z)
	model:PivotTo(model:GetPivot() + Vector3.new(base.X - box.Position.X,
		base.Y - (box.Position.Y - fitted.Y / 2), base.Z - box.Position.Z))
	model.WorldPivot = CFrame.new(base)
	model:SetAttribute("StationId", Plan.stationId)
	model:SetAttribute("GeneratorId", Plan.stationId)
	model:SetAttribute("PlotIndex", plot.index)
	local host
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("MeshPart") then
			part.Transparency = 1 -- fail closed visually until this client's mesh load succeeds
			if part.Name == "Cover" then host = part end
		end
	end
	assert(host, "Missing book attachment host")
	for name, offset in pairs({ EnergyPoint = Plan.energy, ParticlePoint = Plan.particles }) do
		local point = Plan.point(offset, { x = fitted.X, y = fitted.Y, z = fitted.Z })
		local attachment = Instance.new("Attachment")
		attachment.Name = name
		attachment.Position = host.CFrame:PointToObjectSpace(base + Vector3.new(table.unpack(point)))
		attachment.Parent = host
	end
	local back = Instance.new("ObjectValue")
	back.Name, back.Value, back.Parent = "LecternAnchor", anchor, model
end
function ops.publish(model, plot, anchor)
	local link = Instance.new("ObjectValue")
	link.Name, link.Value = "SpellbookVisual", model
	model.Parent = plot.model
	link.Parent = anchor
	CollectionService:AddTag(model, Plan.tag)
end
function ops.discard(model, anchor)
	local link = anchor:FindFirstChild("SpellbookVisual")
	if link and link:IsA("ObjectValue") and link.Value == model then link:Destroy() end
	model:Destroy()
end
function Lectern.ensure(plot, anchor)
	local ok, result = Placement.ensure(ops, plot, anchor)
	if not ok and plot and plot.model and not warned[plot.model] then
		warned[plot.model] = true
		warn("[AG01] Plot " .. tostring(plot.index) .. " keeps crystal fallback: " .. tostring(result))
	end
	return ok, result
end
function Lectern.install(world)
	if installed[world] then return end
	installed[world] = true
	for _, plot in ipairs(world.plots) do Lectern.ensure(plot, plot.anchors.crystal) end
	-- No world.update wrapper: visual instances belong to fixed plots, not profiles.
end
return Lectern
