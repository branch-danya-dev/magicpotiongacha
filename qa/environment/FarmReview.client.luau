--!nonstrict
-- Isolated Studio QA: fixed gameplay cameras, optional walk and ordinary intents.
-- No grants, purchases, new remotes, saved progress or hidden UI.
if not game:GetService("RunService"):IsStudio() then return end
local player=game:GetService("Players").LocalPlayer
local root=workspace:WaitForChild("PotionTycoonWorld")
local Controller=require(script.Parent:WaitForChild("PotionTycoon").EnvironmentController)
local remotes=game.ReplicatedStorage.PotionTycoon:WaitForChild("Remotes")
local state
remotes.State.OnClientEvent:Connect(function(value) state=value end)
local points={
	{name="spawn",position={-142.5,4,-45},camera={-133.5,11,-33},target={-142.5,4,-45}},
	{name="farm",position={-142.5,4,-45},camera={-110,27,-24},target={-145,0,-73}},
	{name="bazaar",position={0,4,8},camera={12,15,28},target={0,2,0}},
	{name="build",position={-162.5,4,-73},camera={-151,12,-66},target={-162.5,1,-78}},
}
local index,busy=1,false
local function audit()
	local cam=workspace.CurrentCamera; local pool=workspace:FindFirstChild("FarmAffordance")
	local visible,glows=0,0
	if pool then for _,p in ipairs(pool:GetChildren()) do if p.Transparency<1 then
		if string.sub(p.Name,1,8)=="Boundary" then visible+=1 else glows+=1 end
	end end end
	print("M7_19B_FRAME view="..points[index].name.." graphics="..UserSettings().GameSettings.SavedQualityLevel.Name.." quality="..Controller.quality.." camera="..tostring(cam.CFrame).." integrated="..tostring(root:GetAttribute("FarmGroundVersion")).." pool="..(pool and #pool:GetChildren() or 0).." border="..visible.." glow="..glows.." station="..tostring(pool and pool:GetAttribute("GlowingStation")).." gold="..tostring(state and state.gold))
end
local function teleport(position)
	local char=player.Character; if not char then return end
	char:PivotTo(CFrame.new(position)); local hrp=char:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.AssemblyLinearVelocity=Vector3.zero end
end
local function move()
	local p=points[index]; teleport(Vector3.new(table.unpack(p.position)))
	local c=workspace.CurrentCamera; c.CameraType=Enum.CameraType.Scriptable; c.FieldOfView=70
	c.CFrame=CFrame.lookAt(Vector3.new(table.unpack(p.camera)),Vector3.new(table.unpack(p.target)))
	task.delay(1,audit)
end
local function walk()
	if busy then return end; busy=true; index=1; move(); task.wait(1)
	local char=player.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
	if not hum then busy=false; return end
	workspace.CurrentCamera.CameraType=Enum.CameraType.Custom
	local route={{-142.5,-28},{-142.5,-43},{-152,-43},{-152,-71},{-162.5,-73},{-152,-71},{-152,-43},{-142.5,-43},{-142.5,-28},{-142.5,0},{-70,0},{0,8}}
	for i,p in ipairs(route) do
		hum:MoveTo(Vector3.new(p[1],4,p[2])); local reached=hum.MoveToFinished:Wait()
		print("M7_19B_WALK step="..i.." reached="..tostring(reached).." alive="..tostring(hum.Health>0))
		if not reached or player.Character~=char then break end
	end
	busy=false
end
local function earn()
	if busy then return end; busy=true
	-- Repeat the unchanged starter recipe through existing proximity/rate validation.
	-- Positioning is QA setup; rewards always come from production on the server.
	for batch=1,5 do
		teleport(Vector3.new(-158,4,-63)); task.wait(.8)
		remotes.Action:FireServer("harvest",{stationId="garden"}); task.wait(4.2)
		remotes.Action:FireServer("harvest",{stationId="garden"}); task.wait(.5)
		teleport(Vector3.new(-138,4,-65)); task.wait(.8)
		for _=1,3 do remotes.Action:FireServer("click",{}); task.wait(.5) end
		teleport(Vector3.new(-118,4,-63)); task.wait(.8)
		remotes.Action:FireServer("load",{stationId="cauldron"}); task.wait(.6)
		remotes.Action:FireServer("brew",{stationId="cauldron"}); task.wait(7)
		print("M7_19B_EARN batch="..batch.." gold="..tostring(state and state.gold))
	end
	busy=false; index=4; move()
end
game:GetService("UserInputService").InputBegan:Connect(function(key,handled)
	if handled then return end
	if key.KeyCode==Enum.KeyCode.F8 then index=1; move()
	elseif key.KeyCode==Enum.KeyCode.F6 then index=index%#points+1; move()
	elseif key.KeyCode==Enum.KeyCode.J then task.spawn(walk)
	elseif key.KeyCode==Enum.KeyCode.N then task.spawn(earn)
	elseif key.KeyCode==Enum.KeyCode.P then audit()
	elseif key.KeyCode==Enum.KeyCode.Q then
		local tiers={"reduced","full","minimal"}; Controller.setQuality(tiers[(table.find(tiers,Controller.quality) or 1)%3+1]); audit()
	elseif key.KeyCode==Enum.KeyCode.C then workspace.CurrentCamera.CameraType=Enum.CameraType.Custom end
end)
task.spawn(function() while not Controller.view do task.wait(.2) end; Controller.view.setPose("day") end)
