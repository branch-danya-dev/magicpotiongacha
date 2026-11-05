--!nonstrict
-- Optional full-game instrumentation, excluded from the plain playable deliverable.
-- Setup teleports place the actor only. Movement/collisions/recovery use real physics.
if not game:GetService("RunService"):IsStudio() then return end
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local player=Players.LocalPlayer
local root=workspace:WaitForChild("PotionTycoonWorld")
local Controller=require(script.Parent:WaitForChild("PotionTycoon").EnvironmentController)
local poses={"day","sunset","night","dawn","rain","afterrain"}
local pose=0; local busy=false; local preview=false
local function actor(position,target)
	local character=player.Character; if not character then return end
	character:PivotTo(CFrame.new(position))
	local camera=workspace.CurrentCamera; camera.CameraType=Enum.CameraType.Custom
	camera.CFrame=CFrame.lookAt(position+Vector3.new(9,7,12),target)
	return character,character:FindFirstChildOfClass("Humanoid")
end
local function audit()
	local gui=player.PlayerGui:FindFirstChild("PotionTycoonUI")
	local cam=workspace.CurrentCamera
	print("M7_18A_FRAME viewport="..tostring(cam.ViewportSize).." graphics="..UserSettings().GameSettings.SavedQualityLevel.Name.." quality="..Controller.quality.." clock="..game.Lighting.ClockTime.." touch="..tostring(Input.TouchEnabled).." gui="..tostring(gui and gui.Enabled))
end
local function traverse(kind)
	if busy then return end; busy=true
	local start=kind=="fence" and Vector3.new(-126,4,-31) or Vector3.new(204,4,45)
	local target=kind=="fence" and Vector3.new(-126,4,-44) or Vector3.new(230,4,45)
	local character,humanoid=actor(start,target)
	if not humanoid then busy=false; return end
	task.wait(.5)
	humanoid:MoveTo(target)
	task.wait(5)
	local hrp=character:FindFirstChild("HumanoidRootPart")
	print("M7_18A_PHYSICS "..kind.." originalCharacter="..tostring(player.Character==character).." health="..humanoid.Health.." position="..tostring(hrp and hrp.Position))
	busy=false
end
Input.InputBegan:Connect(function(key,handled)
	if handled then return end
	if key.KeyCode==Enum.KeyCode.F8 then
		local plot=root:FindFirstChild("Plot_"..tostring(player:GetAttribute("PotionPlotIndex") or 1))
		if plot then actor(plot.Spawn.Position+Vector3.new(0,4,0),plot.Spawn.Position+Vector3.new(0,2,0)) end
	elseif key.KeyCode==Enum.KeyCode.J then task.spawn(traverse,"fence")
	elseif key.KeyCode==Enum.KeyCode.K then task.spawn(traverse,"fall")
	elseif key.KeyCode==Enum.KeyCode.L and Controller.view then
		pose=pose%#poses+1; Controller.view.setPose(poses[pose]); print("M7_18A_REQUEST "..poses[pose])
	elseif key.KeyCode==Enum.KeyCode.T and Controller.view then
		preview=not preview; Controller.view.setPreview(preview); print("M7_18A_PREVIEW "..tostring(preview))
	elseif key.KeyCode==Enum.KeyCode.P then audit() end
end)
local elapsed=0; local previous=nil; local maximumClock,maximumBrightness=0,0
RunService.RenderStepped:Connect(function(dt)
	local clock,brightness=game.Lighting.ClockTime,game.Lighting.Brightness
	if previous then
		maximumClock=math.max(maximumClock,math.abs((clock-previous[1]+12)%24-12))
		maximumBrightness=math.max(maximumBrightness,math.abs(brightness-previous[2]))
	end
	previous={clock,brightness}; elapsed+=dt
	if elapsed>=5 then
		print(string.format("M7_18A_CONTINUITY clock=%.4f brightness=%.4f maxFrameClock=%.4f maxFrameBrightness=%.4f",clock,brightness,maximumClock,maximumBrightness))
		elapsed=0; maximumClock=0; maximumBrightness=0
	end
end)
