--!nonstrict
local Controller=require(script.Parent.EnvironmentController)
local View=require(script.Parent.EnvironmentView)
local CameraCollision=require(script.Parent.CameraCollision)
local stopCamera
local root=workspace:WaitForChild("PotionTycoonWorld")
local function reconcile()
	if root:GetAttribute("EnvironmentArtEnabled")==true then
		if not Controller.view and root:FindFirstChild("EnvironmentArt") then
			Controller.view=View.start(root,{quality=Controller.quality}); Controller.view.setReduceMotion(Controller.reduceMotion)
			stopCamera=CameraCollision.start()
		end
	elseif Controller.view then
		Controller.view.stop(); Controller.view=nil
		if stopCamera then stopCamera(); stopCamera=nil end
	end
end
root:GetAttributeChangedSignal("EnvironmentArtEnabled"):Connect(reconcile)
root.ChildAdded:Connect(reconcile)
reconcile()
