--!nonstrict
-- Disposable local preview only. The release project never includes this file.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local Input=game:GetService("UserInputService")
local Controller=require(script.Parent:WaitForChild("PotionTycoon").EnvironmentController)
local Config=require(game.ReplicatedStorage.PotionTycoon.Shared.EnvironmentConfig)
local poses={"day","sunset","night","rain","dawn","afterrain"}
local tiers={"reduced","full","minimal"}; local quality=1; local review=false; local preview=false
local function camera()
	local c=Config.cameras.spawn; local cam=workspace.CurrentCamera
	cam.CameraType=Enum.CameraType.Scriptable; cam.FieldOfView=53
	cam.CFrame=CFrame.lookAt(Vector3.new(table.unpack(c.position)),Vector3.new(table.unpack(c.target)))
end
RunService:BindToRenderStep("A2bGameplayReviewCamera",Enum.RenderPriority.Camera.Value+1,function() if review then camera() end end)
Input.InputBegan:Connect(function(input,handled)
	if handled or not Controller.view then return end
	local index=table.find({Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three,Enum.KeyCode.Four,Enum.KeyCode.Five,Enum.KeyCode.Six},input.KeyCode)
	if index or input.KeyCode==Enum.KeyCode.Z or input.KeyCode==Enum.KeyCode.X then
		review=true; preview=false
		Controller.view.setPreview(false)
		local pose=index and poses[index] or (input.KeyCode==Enum.KeyCode.Z and "day" or "night")
		Controller.view.setPose(pose); camera()
		print("M7_A2B_GAMEPLAY pose="..pose.." quality="..Controller.quality.." style="..game.Lighting.LightingStyle.Name)
	elseif input.KeyCode==Enum.KeyCode.Q then
		quality=quality%#tiers+1; Controller.setQuality(tiers[quality]); print("M7_A2B_GAMEPLAY quality="..tiers[quality])
	elseif input.KeyCode==Enum.KeyCode.T then
		review=true; preview=not preview; Controller.view.setPreview(preview)
	elseif input.KeyCode==Enum.KeyCode.C then
		review=false; preview=false; Controller.view.setPreview(false); Controller.view.setPose(nil); workspace.CurrentCamera.CameraType=Enum.CameraType.Custom
	end
end)
