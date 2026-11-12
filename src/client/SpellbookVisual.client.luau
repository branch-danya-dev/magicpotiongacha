--!nonstrict
-- Client-only content gate. A failed/denied/slow mesh keeps the working crystal.
-- No remotes, rewards, timers per plot, dynamic lights or quality-dependent geometry.
local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local shared = game:GetService("ReplicatedStorage"):WaitForChild("PotionTycoon"):WaitForChild("Shared")
local Plan = require(shared.SpellbookLecternPlan)
local LoadGate = require(shared.SpellbookLoadGate)
local records = {}
local state = "loading"
local function restore(model)
	local record = records[model]
	if not record then return end
	for part, value in pairs(record.hidden) do
		if part.Parent then part.LocalTransparencyModifier = value end
	end
	for _, part in ipairs(record.parts) do if part.Parent then part.Transparency = 1 end end
	for _, connection in ipairs(record.connections) do connection:Disconnect() end
	records[model] = nil
end
local function reveal(model, record)
	if state ~= "ready" or records[model] ~= record or not model.Parent then return end
	local anchor = record.anchor
	local link = anchor:FindFirstChild("SpellbookVisual")
	if anchor.Parent ~= model.Parent or not link or not link:IsA("ObjectValue") or link.Value ~= model then return end
	local function hide(part)
		if not part:IsA("BasePart") then return end
		if record.hidden[part] == nil then record.hidden[part] = part.LocalTransparencyModifier end
		part.LocalTransparencyModifier = 1
	end
	hide(anchor)
	local old = anchor:FindFirstChild("PresentationModel")
	if old and old:IsA("ObjectValue") and old.Value then
		for _, part in ipairs(old.Value:GetDescendants()) do hide(part) end
	end
	for _, part in ipairs(record.parts) do part.Transparency = 0 end
	model:SetAttribute("SpellbookLoadState", "ready")
end
local function watch(model)
	if records[model] then return end
	local record = { parts = {}, hidden = {}, connections = {} }
	records[model] = record
	task.spawn(function()
		local back = model:WaitForChild("LecternAnchor", 10)
		if records[model] ~= record or not back or not back:IsA("ObjectValue") then restore(model); return end
		local anchor = back.Value
		if not anchor or anchor.Parent ~= model.Parent then restore(model); return end
		record.anchor = anchor
		local entries = {}
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("MeshPart") then
				table.insert(record.parts, part)
				table.insert(entries, { name = part.Name, meshId = part.MeshId, textureId = part.TextureID,
					anchored = part.Anchored, collides = part.CanCollide or part.CanTouch or part.CanQuery })
			end
		end
		local valid, reason = Plan.validateParts(entries)
		if not valid then
			warn("[AG01] Client keeps crystal fallback: " .. tostring(reason)); restore(model); return
		end
		local link = anchor:WaitForChild("SpellbookVisual", 10)
		if records[model] ~= record or not link or not link:IsA("ObjectValue") or link.Value ~= model then restore(model); return end
		table.insert(record.connections, link:GetPropertyChangedSignal("Value"):Connect(function() restore(model) end))
		table.insert(record.connections, model.AncestryChanged:Connect(function(_, parent)
			if parent ~= anchor.Parent then restore(model) end
		end))
		model:SetAttribute("SpellbookLoadState", state)
		reveal(model, record)
	end)
end
CollectionService:GetInstanceAddedSignal(Plan.tag):Connect(watch)
CollectionService:GetInstanceRemovedSignal(Plan.tag):Connect(restore)
for _, model in ipairs(CollectionService:GetTagged(Plan.tag)) do watch(model) end

local function finish(success, reason)
	if state ~= "loading" then return end -- timeout is terminal for this client session
	state = LoadGate.finish(state, success and Plan.meshCount or 0, Plan.meshCount, success)
	if not success then warn("[AG01] Mesh load failed; crystal remains interactive: " .. tostring(reason)) end
	for model, record in pairs(records) do
		model:SetAttribute("SpellbookLoadState", state)
		if record.anchor then reveal(model, record) end
	end
end
task.delay(Plan.loadTimeout, function() finish(false, "timeout") end)
task.spawn(function()
	local ids, successful = {}, {}
	for _, id in pairs(Plan.assets) do table.insert(ids, id) end
	local ok, failure = pcall(function()
		ContentProvider:PreloadAsync(ids, function(id, status)
			if status == Enum.AssetFetchStatus.Success then successful[id] = true end
		end)
	end)
	local count = 0
	for _ in pairs(successful) do count += 1 end
	finish(ok and count == Plan.meshCount, failure or (tostring(count) .. "/" .. Plan.meshCount .. " meshes"))
end)
