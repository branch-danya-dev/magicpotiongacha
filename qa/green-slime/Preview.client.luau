--!nonstrict
-- Only included by build-ag74-preview. No remote calls/profile grants/extra starter.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local scripts = player:WaitForChild("PlayerScripts"):WaitForChild("PotionTycoon")
local View = require(scripts:WaitForChild("FamiliarRigView"))
local world = workspace:WaitForChild("PotionTycoonWorld")
local folder = Instance.new("Folder"); folder.Name = "AG74Preview"; folder.Parent = workspace
local records = {}; local character, plot, attempted = nil, nil, false
local probe = Instance.new("BindableFunction"); probe.Name = "Inspect"; probe.Parent = folder
probe.OnInvoke = function()
	local result = {count = View.count, pets = {}}
	for _, view in ipairs(records) do
		local driver = view.driver
		table.insert(result.pets, {ready = view.ready, disposed = view.disposed, failed = view.failed,
			tracks = #view.tracks, connections = driver and #driver.connections or 0,
			current = driver and driver.current or 0, selections = driver and driver.selections or 0,
			transitions = driver and table.clone(driver.transitions) or {}, fetch = table.clone(view.fetch)})
	end
	return result
end
local function clear()
	for _, record in ipairs(records) do record.destroy() end
	table.clear(records); attempted = false
end
-- Do not miss a quick OFF/ON pair between the 10 Hz preview updates.
local policy = workspace:GetAttributeChangedSignal("GreenSlimeRigPreviewEnabled"):Connect(function()
	if not View.enabled() then clear() end
end)
local elapsed = 0
local heartbeat = RunService.Heartbeat:Connect(function(dt)
	elapsed += dt; if elapsed < 0.1 then return end; elapsed = 0
	local current = player.Character
	local humanoid = current and current:FindFirstChildOfClass("Humanoid")
	local root = current and current:FindFirstChild("HumanoidRootPart")
	local owned
	for _, candidate in ipairs(world:GetChildren()) do
		if candidate:GetAttribute("OwnerUserId") == player.UserId then owned = candidate; break end
	end
	if character ~= current or plot ~= owned then clear(); character = current; plot = owned end
	if not View.enabled() or not root or not humanoid or humanoid.Health <= 0 or not plot then clear(); return end
	if not attempted then
		attempted = true
		local two = workspace:GetAttribute("AG74TwoPets") == true
		local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {current, folder}
		for i = 1, two and 2 or 1 do
			local spot = root.Position + root.CFrame.RightVector * (i == 1 and 4 or -4) + root.CFrame.LookVector * 3
			local hit = workspace:Raycast(spot + Vector3.new(0, 6, 0), Vector3.new(0, -30, 0), params)
			local view = View.create("slime", folder, 7400 + i)
			if view then
				view.pivot = CFrame.new(hit and hit.Position or spot-Vector3.new(0,3,0))
				view.model:SetAttribute("QAOwnerUserId", player.UserId)
				table.insert(records, view)
			end
		end
	end
	for _, view in ipairs(records) do
		view.update(view.pivot, humanoid.MoveDirection.Magnitude < 0.05 and workspace:GetAttribute("AG74React") ~= true)
	end
end)
script.Destroying:Connect(function() heartbeat:Disconnect(); policy:Disconnect(); clear(); folder:Destroy() end)
