--!nonstrict
-- Production collision guard after Roblox's ordinary camera. Does not drive
-- look direction/Focus/subject or own Lighting; no diagnostic camera controls.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Clearance=require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.CameraClearance)
local Collision={}; local owned=false
function Collision.start()
	assert(not owned,"Camera collision already owned"); owned=true
	local player=Players.LocalPlayer
	local saved={min=player.CameraMinZoomDistance,max=player.CameraMaxZoomDistance}
	-- Set a temporary lower bound first: Roblox clamps min/max against each
	-- other, so the old range must not silently defeat the requested new range.
	player.CameraMinZoomDistance=.5
	player.CameraMaxZoomDistance=Clearance.maxZoom; player.CameraMinZoomDistance=Clearance.minZoom
	local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
	params.IgnoreWater=true; params.RespectCanCollide=true
	local lastCamera,lastCharacter,lastFocus,previous
	RunService:BindToRenderStep("M7CameraCollision",Enum.RenderPriority.Camera.Value+1,function(dt)
		local camera=workspace.CurrentCamera; local character=player.Character
		if not camera or not character or camera.CameraType==Enum.CameraType.Scriptable then
			previous=nil; lastFocus=nil; return
		end
		local focus=camera.Focus.Position; local desired=camera.CFrame; local delta=desired.Position-focus
		if camera~=lastCamera or character~=lastCharacter or (lastFocus and (focus-lastFocus).Magnitude>20) then previous=nil end
		lastCamera,lastCharacter,lastFocus=camera,character,focus
		if delta.Magnitude<.001 then previous=nil; return end
		params.FilterDescendantsInstances={character}
		local size=camera.ViewportSize
		local radius=Clearance.radius(camera.FieldOfView,size.X/math.max(1,size.Y),camera.NearPlaneZ)
		local hit=workspace:Spherecast(focus,radius,delta,params)
		-- Spherecast does not detect initial overlap. A center ray also protects
		-- the inside-to-outside case at a wall adjacent to the subject.
		local ray=workspace:Raycast(focus,delta,params)
		local distance=hit and hit.Distance
		if ray then distance=math.min(distance or math.huge,ray.Distance) end
		previous=Clearance.distance(previous,delta.Magnitude,distance,dt)
		if previous<delta.Magnitude then camera.CFrame=desired+(focus+delta.Unit*previous-desired.Position) end
	end)
	local stopped=false
	return function()
		if stopped then return end; stopped=true; owned=false
		RunService:UnbindFromRenderStep("M7CameraCollision")
		player.CameraMinZoomDistance=.5
		player.CameraMaxZoomDistance=saved.max; player.CameraMinZoomDistance=saved.min
	end
end
return Collision
