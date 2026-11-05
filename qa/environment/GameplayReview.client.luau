--!nonstrict
-- Disposable local preview only. The release project never includes this file.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local Input=game:GetService("UserInputService")
local Controller=require(script.Parent:WaitForChild("PotionTycoon").EnvironmentController)
local Config=require(game.ReplicatedStorage.PotionTycoon.Shared.EnvironmentConfig)
Input.InputBegan:Connect(function(input,handled)
	if handled or not Controller.view then return end
	if input.KeyCode==Enum.KeyCode.Z or input.KeyCode==Enum.KeyCode.X then
		Controller.view.setPreview(false)
		Controller.view.setPose(input.KeyCode==Enum.KeyCode.Z and "day" or "night")
		local c=Config.cameras.spawn; local camera=workspace.CurrentCamera
		camera.CameraType=Enum.CameraType.Scriptable; camera.FieldOfView=53
		camera.CFrame=CFrame.lookAt(Vector3.new(table.unpack(c.position)),Vector3.new(table.unpack(c.target)))
	elseif input.KeyCode==Enum.KeyCode.C then
		Controller.view.setPose(nil); workspace.CurrentCamera.CameraType=Enum.CameraType.Custom
	end
end)
