--!nonstrict
-- Studio-only route/camera instrumentation. No hidden HUD, grants or fake actions.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local Input=game:GetService("UserInputService")
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local root=workspace:WaitForChild("PotionTycoonWorld")
local Controller=require(script.Parent:WaitForChild("PotionTycoon").EnvironmentController)
local route={"spawn","crystal","garden","Buy_garden","TradePost","neighbour"}
local routeIndex,poseIndex=1,1
local poses={"day","sunset","night","rain"}
local function plot() return root:FindFirstChild("Plot_"..tostring(player:GetAttribute("PotionPlotIndex") or 1)) end
local function audit()
	local enabled,labels=0,0; local names={}
	for _,v in ipairs(root:GetDescendants()) do
		if v:IsA("ProximityPrompt") and v.Enabled then enabled+=1; table.insert(names,v.Parent.Name) end
		if v:IsA("BillboardGui") and v.Enabled then labels+=1 end
	end
	local gui=player.PlayerGui:FindFirstChild("PotionTycoonUI")
	local panel=gui and gui:FindFirstChild("ContextPanel")
	local c=workspace.CurrentCamera
	print("UI18_AUDIT route="..route[routeIndex].." pose="..poses[poseIndex].." viewport="..c.ViewportSize.X.."x"..c.ViewportSize.Y.." touch="..tostring(Input.TouchEnabled).." prompts="..enabled.." labels="..labels.." selected="..table.concat(names,",").." panel="..tostring(panel and panel.Visible).." quality="..Controller.quality.." graphics="..UserSettings().GameSettings.SavedQualityLevel.Name)
	if gui then print("UI18_BOUNDS enabled="..tostring(gui.Enabled).." gui="..tostring(gui.AbsoluteSize).." panel="..(panel and tostring(panel.AbsolutePosition).." "..tostring(panel.AbsoluteSize) or "baseline")) end
	pcall(function() print("UI18_CHAT active="..tostring(game.StarterGui:GetCore("ChatActive")).." size="..tostring(game.StarterGui:GetCore("ChatWindowSize")).." position="..tostring(game.StarterGui:GetCore("ChatWindowPosition"))) end)
end
local function move()
	local p=plot(); local character=player.Character
	if not p or not character then return end
	local name=route[routeIndex]
	local target=name=="TradePost" and root.TradePost or name=="neighbour" and root.Plot_2.Spawn or name=="spawn" and p.Spawn or p:FindFirstChild(name)
	if not target then return end
	local position=target.Position+Vector3.new(0,4,(name=="spawn" or name=="neighbour") and 0 or 6)
	-- Fixed checkpoints only; all interactions are performed through real game UI.
	character:PivotTo(CFrame.lookAt(position,Vector3.new(target.Position.X,position.Y,target.Position.Z-.1)))
	local cam=workspace.CurrentCamera; cam.CameraType=Enum.CameraType.Custom
	cam.CFrame=CFrame.lookAt(position+Vector3.new(9,7,12),target.Position+Vector3.new(0,2,0))
	print("UI18_ROUTE "..name)
	task.delay(1,audit)
end
Input.InputBegan:Connect(function(key,handled)
	if handled then return end
	if key.KeyCode==Enum.KeyCode.F6 then routeIndex=routeIndex%#route+1; move()
	elseif key.KeyCode==Enum.KeyCode.L then
		poseIndex=poseIndex%#poses+1
		if Controller.view then Controller.view.setPose(poses[poseIndex]) end
		task.delay(1,audit)
	elseif key.KeyCode==Enum.KeyCode.P then audit()
	elseif key.KeyCode==Enum.KeyCode.F8 then routeIndex=1; move()
	end
end)
task.delay(6,function() if Controller.view then Controller.view.setPose("day") end; audit() end)
