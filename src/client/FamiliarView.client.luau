--!nonstrict
-- Cosmetic client-side worker proxies. Never used as proof of delivery or ownership.
local RunService = game:GetService("RunService")
-- AG74_BEGIN_IMPORT
local RigView = require(script.Parent.FamiliarRigView)
-- AG74_END_IMPORT
local world = workspace:WaitForChild("PotionTycoonWorld")
local folder = Instance.new("Folder")
folder.Name, folder.Parent = "LocalFamiliarVisuals", workspace
local proxies = {}
local crates = {}
-- AG74_BEGIN_STATE
local rigs = {}
local function clearRig(anchor)
	local record = rigs[anchor]
	if record and record.view then record.view.destroy() end
	rigs[anchor] = nil
end
-- AG74_END_STATE
local colors = { slime = Color3.fromRGB(112, 222, 149), brewer = Color3.fromRGB(200, 151, 239), farmer = Color3.fromRGB(235, 203, 141) }

local function discover(anchor)
	if not anchor:IsA("BasePart") or not anchor:GetAttribute("StationId") then return end
	if proxies[anchor] then return end
	local pet = Instance.new("Part")
	pet.Name, pet.Shape, pet.Size = "WorkerProxy", Enum.PartType.Ball, Vector3.new(2.4, 2.4, 2.4)
	pet.Anchored, pet.CanCollide, pet.CanTouch, pet.CanQuery, pet.CastShadow = true, false, false, false, false
	pet.Material, pet.Transparency, pet.Parent = Enum.Material.SmoothPlastic, 1, folder
	local a,b=Instance.new("Attachment"),Instance.new("Attachment"); a.Position,b.Position=Vector3.new(0,0.6,0),Vector3.new(0,-0.6,0); a.Parent,b.Parent=pet,pet
	local trail=Instance.new("Trail"); trail.Name="GhostTrail"; trail.Attachment0,trail.Attachment1=a,b; trail.Lifetime=0.6
	trail.Color=ColorSequence.new(Color3.fromRGB(120,234,247),Color3.fromRGB(165,116,240)); trail.LightEmission=0.6; trail.Enabled=false; trail.Parent=pet
	proxies[anchor] = pet
	local crate = Instance.new("Part")
	crate.Name, crate.Size = "QuestCrate", Vector3.new(2, 2, 2)
	crate.Anchored, crate.CanCollide, crate.CanTouch, crate.CanQuery = true, false, false, false
	crate.Color, crate.Material = Color3.fromRGB(173, 128, 72), Enum.Material.Wood
	crate.Transparency, crate.Parent = 1, folder
	crates[anchor] = crate
end
for _, descendant in ipairs(world:GetDescendants()) do discover(descendant) end
world.DescendantAdded:Connect(discover)

RunService.RenderStepped:Connect(function()
	local time = os.clock()
	for anchor, pet in pairs(proxies) do
-- AG74_BEGIN_CLEANUP
		if not anchor.Parent or not anchor:GetAttribute("WorkerId") or not RigView.enabled() then clearRig(anchor) end
-- AG74_END_CLEANUP
		if not anchor.Parent then
			pet:Destroy()
			crates[anchor]:Destroy()
			crates[anchor] = nil
			proxies[anchor] = nil
		elseif anchor:GetAttribute("WorkerId") then
			pet.Transparency = 0
			pet.Color = colors[anchor:GetAttribute("WorkerSpecies")] or Color3.fromRGB(190, 190, 210)
			local species=anchor:GetAttribute("WorkerSpecies"); local ghost=species=="ghost_wolf" or species=="ghost_alpha"
			pet.GhostTrail.Enabled=ghost; pet.Material=ghost and Enum.Material.Neon or Enum.Material.SmoothPlastic
			if ghost then pet.Color=Color3.fromRGB(120,234,247); pet.Transparency=0.2 end
			local position = anchor.Position + Vector3.new(5, 1.5 + math.sin(time * 2) * 0.2, 0)
			local from, destination, progress = anchor:GetAttribute("HaulFrom"), anchor:GetAttribute("HaulTo"), anchor:GetAttribute("HaulProgress")
			if from and destination and progress then position = from:Lerp(destination, progress) + Vector3.new(0, 3, 0) end
			pet.CFrame = pet.CFrame:Lerp(CFrame.new(position), 0.2)
-- AG74_BEGIN_RENDER
			if RigView.enabled() and species == "slime" then
				local id = anchor:GetAttribute("WorkerId")
				if rigs[anchor] and rigs[anchor].id ~= id then clearRig(anchor) end
				local previous = rigs[anchor] and rigs[anchor].view
				if previous and previous.disposed and not previous.failed then clearRig(anchor) end
				if not rigs[anchor] then rigs[anchor] = {id = id, view = RigView.create(species, folder)} end
				local view = rigs[anchor].view
				local hauling = from and destination and progress ~= nil
				local pivot = CFrame.new(pet.Position - Vector3.new(0, 1.2, 0))
				if view and view.update(pivot, not hauling and anchor:GetAttribute("WorkerReacting") ~= true) then pet.Transparency = 1 end
			else clearRig(anchor) end
-- AG74_END_RENDER
		else pet.Transparency = 1; pet.GhostTrail.Enabled=false end
		local crate = crates[anchor]
		if crate then
			local item = anchor:GetAttribute("CargoItem")
			local cargo = anchor:GetAttribute("CargoAmount") or 0
			local queued = anchor:GetAttribute("QueuedCrates") or 0
			if cargo > 0 and (item == "healing" or item == "rage") then
				local from, target = anchor:GetAttribute("HaulFrom"), anchor:GetAttribute("HaulTo")
				-- Replicated attributes may arrive separately within a frame.
				crate.Transparency = from and target and 0 or 1
				if from and target then crate.Position = from:Lerp(target, anchor:GetAttribute("HaulProgress") or 0) + Vector3.new(0, 5, 0) end
			elseif queued > 0 then
				crate.Transparency = 0
				crate.Position = anchor.Position + Vector3.new(-5, 1, 0)
			else crate.Transparency = 1 end
		end
	end
end)
-- AG74_BEGIN_DISPOSE
script.Destroying:Connect(function()
	for anchor in pairs(rigs) do clearRig(anchor) end
	folder:Destroy()
end)
-- AG74_END_DISPOSE
