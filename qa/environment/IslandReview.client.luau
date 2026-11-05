--!nonstrict
-- Optional full-game QA only. Native UI remains visible; no gameplay rewards.
if not game:GetService("RunService"):IsStudio() then return end
local player=game:GetService("Players").LocalPlayer
local root=workspace:WaitForChild("PotionTycoonWorld")
local Controller=require(script.Parent:WaitForChild("PotionTycoon").EnvironmentController)
local points={
	{name="spawn",position={-142.5,4,-45},offset={9,7,12}},
	{name="west-coast",position={-203,4,0},offset={22,26,22}},
	{name="bazaar-overview",position={0,4,8},offset={60,60,85}},
	{name="opposite-farm",position={142.5,4,105},offset={-9,9,-16}},
	{name="east-coast",position={203,4,0},offset={-22,26,-22}},
}
local index,poseIndex,busy=1,1,false; local poses={"day","sunset","night","rain"}
local function audit()
	local camera=workspace.CurrentCamera
	print("M7_19A_FRAME view="..points[index].name.." pose="..poses[poseIndex].." viewport="..tostring(camera.ViewportSize).." graphics="..UserSettings().GameSettings.SavedQualityLevel.Name.." quality="..Controller.quality.." camera="..tostring(camera.CFrame).." surface="..tostring(root:GetAttribute("IslandSurfaceVersion")))
end
local function move()
	local char=player.Character; if not char then return end
	local p=points[index]; local position=Vector3.new(table.unpack(p.position))
	char:PivotTo(CFrame.new(position)); local hrp=char:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.AssemblyLinearVelocity=Vector3.zero end
	local c=workspace.CurrentCamera; c.CameraType=Enum.CameraType.Custom
	c.Focus=CFrame.new(position); c.CFrame=CFrame.lookAt(position+Vector3.new(table.unpack(p.offset)),position)
	task.delay(1,audit)
end
local function walk()
	if busy then return end; busy=true; index=1; move(); task.wait(1)
	local char=player.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
	if not hum then busy=false; return end
	-- Use the outer approach, not a straight line through existing factory stations.
	local route={{-142.5,-28},{-142.5,0},{-70,0},{0,8},{70,0},{142.5,0},{195,0},{195,64},{195,128},{142.5,128},{142.5,105},{142.5,128},{203,128},{203,64},{203,0}}
	for i,p in ipairs(route) do
		hum:MoveTo(Vector3.new(p[1],4,p[2])); local reached=hum.MoveToFinished:Wait()
		print("M7_19A_WALK step="..i.." reached="..tostring(reached).." alive="..tostring(hum.Health>0))
		if not reached or player.Character~=char then break end
	end
	busy=false
end
game:GetService("UserInputService").InputBegan:Connect(function(key,handled)
	if handled then return end
	if key.KeyCode==Enum.KeyCode.F8 then index=1; move()
	elseif key.KeyCode==Enum.KeyCode.F6 then index=index%#points+1; move()
	elseif key.KeyCode==Enum.KeyCode.L and Controller.view then poseIndex=poseIndex%#poses+1; Controller.view.setPose(poses[poseIndex])
	elseif key.KeyCode==Enum.KeyCode.J then task.spawn(walk)
	elseif key.KeyCode==Enum.KeyCode.P then audit() end
end)
task.spawn(function()
	while not Controller.view do task.wait(.2) end
	Controller.view.setPose("day")
end)
