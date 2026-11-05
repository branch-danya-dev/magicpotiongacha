--!nonstrict
-- Full game, unchanged HUD/economy; isolated camera and motion QA only.
if not game:GetService("RunService"):IsStudio() then return end
local player=game.Players.LocalPlayer
local root=workspace:WaitForChild("PotionTycoonWorld")
local Controller=require(script.Parent:WaitForChild("PotionTycoon").EnvironmentController)
local points={
	{name="spawn",actor={-142.5,4,-45},camera={-133.5,11,-33},target={-142.5,4,-45}},
	{name="farm",actor={-142.5,4,-45},camera={-110,27,-24},target={-145,0,-73}},
	{name="meadow",actor={-180,4,-35},camera={-174,4,-30},target={-186,1,-53}},
}
local index,busy=1,false
local function audit()
	local stats=Controller.view.stats(); local n=0
	for _,p in ipairs(root.EnvironmentArt:GetDescendants()) do if p:IsA("BasePart") and p:GetAttribute("Meadow") then
		assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery,"Meadow interferes with gameplay")
		n+=1
	end end
	print("M7_19C_FRAME view="..points[index].name.." graphics="..UserSettings().GameSettings.SavedQualityLevel.Name.." quality="..Controller.quality.." camera="..tostring(workspace.CurrentCamera.CFrame).." plants="..n.." stats="..game.HttpService:JSONEncode(stats))
end
local function move()
	local p=points[index]; local char=player.Character
	if char then char:PivotTo(CFrame.new(table.unpack(p.actor))); char.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero end
	local c=workspace.CurrentCamera; c.CameraType=Enum.CameraType.Scriptable; c.FieldOfView=70
	c.CFrame=CFrame.lookAt(Vector3.new(table.unpack(p.camera)),Vector3.new(table.unpack(p.target)))
	task.delay(2,audit)
end
local function motionAudit()
	if busy then return end; busy=true
	local original=Controller.quality
	for _,quality in ipairs({"full","reduced","minimal"}) do
		Controller.setQuality(quality); task.wait(2)
		local stats=Controller.view.stats(); assert((stats.meadowMoving or 0)<=({full=64,reduced=32,minimal=0})[quality]); audit()
	end
	Controller.setQuality("reduced"); Controller.setReduceMotion(true); task.wait(1)
	local before={}; for _,p in ipairs(root.EnvironmentArt:GetDescendants()) do if p:IsA("BasePart") and p:GetAttribute("Meadow") then before[p]=p.CFrame end end
	task.wait(1); for p,cf in pairs(before) do assert(p.CFrame==cf,"Reduce Motion drift") end
	assert((Controller.view.stats().meadowMoving or 0)==0)
	Controller.setReduceMotion(false); task.wait(2)
	local changes=0; for p,cf in pairs(before) do if p.CFrame~=cf then changes+=1 end end
	if next(before) then assert(changes>0,"No actual mesh movement") end
	local View=require(script.Parent.PotionTycoon.EnvironmentView)
	assert(not pcall(function() View.start(root) end),"Duplicate owner admitted")
	Controller.view.stop(); for p,cf in pairs(before) do assert(p.CFrame==cf,"Wind not restored") end
	Controller.view=View.start(root,{quality=original,pose="day"}); Controller.setQuality(original)
	print("M7_19C_MOTION PASS tiers=3 reduceMotion=stable resumedMeshes="..changes.." duplicateOwner=rejected restoration=exact")
	busy=false
end
game:GetService("UserInputService").InputBegan:Connect(function(key,handled)
	if handled then return end
	if key.KeyCode==Enum.KeyCode.F8 then index=1; move()
	elseif key.KeyCode==Enum.KeyCode.F6 then index=index%#points+1; move()
	elseif key.KeyCode==Enum.KeyCode.P then audit()
	elseif key.KeyCode==Enum.KeyCode.R then task.spawn(motionAudit)
	elseif key.KeyCode==Enum.KeyCode.Q then Controller.setQuality(Controller.quality=="full" and "reduced" or "full"); task.delay(2,audit)
	elseif key.KeyCode==Enum.KeyCode.C then workspace.CurrentCamera.CameraType=Enum.CameraType.Custom end
end)
task.spawn(function() while not Controller.view do task.wait(.2) end; Controller.view.setPose("day") end)
