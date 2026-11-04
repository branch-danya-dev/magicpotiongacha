--!nonstrict
-- Cosmetic client-side worker proxies. Never used as proof of delivery or ownership.
local RunService = game:GetService("RunService")
local world = workspace:WaitForChild("PotionTycoonWorld")
local folder = Instance.new("Folder")
folder.Name, folder.Parent = "LocalFamiliarVisuals", workspace
local proxies = {}
local colors = { slime = Color3.fromRGB(112, 222, 149), brewer = Color3.fromRGB(200, 151, 239), farmer = Color3.fromRGB(235, 203, 141) }

local function discover(anchor)
	if not anchor:IsA("BasePart") or not anchor:GetAttribute("StationId") then return end
	if proxies[anchor] then return end
	local pet = Instance.new("Part")
	pet.Name, pet.Shape, pet.Size = "WorkerProxy", Enum.PartType.Ball, Vector3.new(2.4, 2.4, 2.4)
	pet.Anchored, pet.CanCollide, pet.CanTouch, pet.CanQuery, pet.CastShadow = true, false, false, false, false
	pet.Material, pet.Transparency, pet.Parent = Enum.Material.SmoothPlastic, 1, folder
	proxies[anchor] = pet
end
for _, descendant in ipairs(world:GetDescendants()) do discover(descendant) end
world.DescendantAdded:Connect(discover)

RunService.RenderStepped:Connect(function()
	local time = os.clock()
	for anchor, pet in pairs(proxies) do
		if not anchor.Parent then
			pet:Destroy()
			proxies[anchor] = nil
		elseif anchor:GetAttribute("WorkerId") then
			pet.Transparency = 0
			pet.Color = colors[anchor:GetAttribute("WorkerSpecies")] or Color3.fromRGB(190, 190, 210)
			local position = anchor.Position + Vector3.new(5, 1.5 + math.sin(time * 2) * 0.2, 0)
			local from, destination, progress = anchor:GetAttribute("HaulFrom"), anchor:GetAttribute("HaulTo"), anchor:GetAttribute("HaulProgress")
			if from and destination and progress then position = from:Lerp(destination, progress) + Vector3.new(0, 3, 0) end
			pet.CFrame = pet.CFrame:Lerp(CFrame.new(position), 0.2)
		else pet.Transparency = 1 end
	end
end)
