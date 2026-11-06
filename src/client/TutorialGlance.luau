--!nonstrict
-- Briefly aims the camera at the current tutorial target, then returns it.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Glance = { running = false }
local highlight
local connection
local inputConnection
local savedType
local notify

local skipKeys = {
	[Enum.KeyCode.W] = true, [Enum.KeyCode.A] = true, [Enum.KeyCode.S] = true, [Enum.KeyCode.D] = true,
	[Enum.KeyCode.Space] = true, [Enum.KeyCode.Thumbstick1] = true,
}

local function ensureHighlight()
	if highlight then return highlight end
	highlight = Instance.new("Highlight")
	highlight.Name = "TutorialTarget"
	highlight.FillColor = Color3.fromRGB(255, 214, 120)
	highlight.OutlineColor = Color3.fromRGB(255, 214, 120)
	highlight.FillTransparency = 0.65
	highlight.OutlineTransparency = 0
	highlight.Enabled = false
	highlight.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return highlight
end

function Glance.stop()
	if connection then connection:Disconnect() connection = nil end
	if inputConnection then inputConnection:Disconnect() inputConnection = nil end
	local camera = workspace.CurrentCamera
	if camera and savedType and camera.CameraType == Enum.CameraType.Scriptable then
		camera.CameraType = savedType
	end
	savedType = nil
	Glance.running = false
	if notify then notify(false) end
end

function Glance.onRunning(callback)
	notify = callback
end

function Glance.play(part, reduceMotion)
	Glance.stop()
	local marker = ensureHighlight()
	marker.Adornee = part
	marker.Enabled = part ~= nil
	if reduceMotion == true or part == nil then return end
	local camera = workspace.CurrentCamera
	if not camera then return end
	savedType = camera.CameraType
	local origin = camera.CFrame
	local focus = part.Position
	local back = origin.Position - focus
	if back.Magnitude < 1 then back = Vector3.new(0, 8, 18) end
	local distance = math.clamp(back.Magnitude, 12, 28)
	local goal = CFrame.new(focus + back.Unit * distance + Vector3.new(0, 4, 0), focus)
	camera.CameraType = Enum.CameraType.Scriptable
	Glance.running = true
	if notify then notify(true) end
	local started = os.clock()
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - started
		if elapsed < 0.45 then
			camera.CFrame = origin:Lerp(goal, elapsed / 0.45)
		elseif elapsed < 1.2 then
			camera.CFrame = goal
		else
			Glance.stop()
		end
	end)
	inputConnection = Input.InputBegan:Connect(function(key, processed)
		if processed then return end
		if key.UserInputType == Enum.UserInputType.Touch or skipKeys[key.KeyCode] then Glance.stop() end
	end)
end

function Glance.clear()
	Glance.stop()
	if highlight then highlight.Enabled = false highlight.Adornee = nil end
end

return Glance
