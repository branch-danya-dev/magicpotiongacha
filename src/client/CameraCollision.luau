--!nonstrict
-- Production collision guard after Roblox's ordinary camera. Does not drive
-- look direction/Focus/subject or own Lighting; no diagnostic camera controls.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Clearance=require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.CameraClearance)
local Geometry=require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.CameraGeometry)
local TerrainCache=require(script.Parent.CameraTerrain)
local Collision={}; local owned=false; local metrics=nil
function Collision.stats() return metrics and table.clone(metrics) or nil end
function Collision.start(root)
	assert(not owned,"Camera collision already owned"); owned=true
	local player=Players.LocalPlayer
	local saved={min=player.CameraMinZoomDistance,max=player.CameraMaxZoomDistance}
	-- Set a temporary lower bound first: Roblox clamps min/max against each
	-- other, so the old range must not silently defeat the requested new range.
	player.CameraMinZoomDistance=.5
	player.CameraMaxZoomDistance=Clearance.maxZoom; player.CameraMinZoomDistance=Clearance.minZoom
	local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Include
	params.IgnoreWater=true; params.RespectCanCollide=true
	params.FilterDescendantsInstances={root,workspace.Terrain}
	local overlaps=OverlapParams.new(); overlaps.FilterType=Enum.RaycastFilterType.Include
	-- Characters and decorative meshes are not part of the static world boundary.
	overlaps.FilterDescendantsInstances={root}; overlaps.RespectCanCollide=true
	local terrain=TerrainCache.new(workspace.Terrain)
	local lastCamera,lastCharacter,lastFocus,lastType,previous,lastSafe,lastOrigin
	metrics={frames=0,casts=0,boundsQueries=0,terrainReads=0,overlapRecoveries=0,unresolved=0,maxCastsPerFrame=1,cacheBytes=Geometry.terrainCells}
	local function resolve(position,parts,radius,reference)
		for _=1,Geometry.iterations do
			local moved=false
			local raised,inCache=terrain.lift(position,radius)
			if not inCache then return nil end
			if raised~=position then position=raised; moved=true end
			for _,p in ipairs(parts) do
				if p:IsA("BasePart") and p.CanCollide then
					local v=p.CFrame:PointToObjectSpace(position); local h=p.Size*.5
					local r=p.CFrame:PointToObjectSpace(reference)
					local out,hit=Geometry.exit({v.X,v.Y,v.Z},{h.X,h.Y,h.Z},radius,{r.X,r.Y,r.Z})
					if hit then position=p.CFrame:PointToWorldSpace(Vector3.new(table.unpack(out))); moved=true end
				end
			end
			if not moved then return position end
		end
		return nil
	end
	RunService:BindToRenderStep("M7CameraCollision",Enum.RenderPriority.Camera.Value+1,function(dt)
		local camera=workspace.CurrentCamera; local character=player.Character
		if not camera or not character or camera.CameraType==Enum.CameraType.Scriptable then
			previous=nil; lastFocus=nil; lastSafe=nil; lastOrigin=nil; return
		end
		local focus=camera.Focus.Position; local desired=camera.CFrame; local delta=desired.Position-focus
		if camera~=lastCamera or character~=lastCharacter or camera.CameraType~=lastType or (lastFocus and (focus-lastFocus).Magnitude>20) then previous=nil; lastSafe=nil; lastOrigin=nil end
		lastCamera,lastCharacter,lastFocus,lastType=camera,character,focus,camera.CameraType
		if delta.Magnitude<.001 then previous=nil; return end
		local size=camera.ViewportSize
		local radius=Clearance.radius(camera.FieldOfView,size.X/math.max(1,size.Y),camera.NearPlaneZ)+Clearance.skin
		terrain.ensure(focus); metrics.terrainReads=terrain.reads
		local extra=Vector3.one*(radius+8)
		local low=focus:Min(desired.Position):Min(lastSafe or focus)-extra
		local high=focus:Max(desired.Position):Max(lastSafe or focus)+extra
		local parts=workspace:GetPartBoundsInBox(CFrame.new((low+high)/2),high-low,overlaps)
		metrics.boundsQueries+=1; metrics.frames+=1
		-- Unlike a center ray, this checks the complete initial camera volume.
		-- Mesh OBBs and occupied Terrain cells are conservative collision bounds.
		local origin=resolve(focus,parts,radius,focus)
		if not origin or (origin-focus).Magnitude>8 then
			origin=lastSafe and resolve(lastSafe,parts,radius,focus)
			if not origin then metrics.unresolved+=1; previous=nil; return end
		end
		if (origin-focus).Magnitude>.01 then metrics.overlapRecoveries+=1 end
		if lastOrigin and (origin-lastOrigin).Magnitude>8 then previous=nil end
		lastOrigin=origin
		delta=desired.Position-origin
		if delta.Magnitude<.001 then lastSafe=origin; return end
		local hit=workspace:Spherecast(origin,radius,delta,params); metrics.casts+=1
		previous=Clearance.distance(previous,delta.Magnitude,hit and hit.Distance,dt)
		local position=origin+delta.Unit*previous
		camera.CFrame=desired+(position-desired.Position); lastSafe=position
	end)
	local stopped=false
	return function()
		if stopped then return end; stopped=true; owned=false
		RunService:UnbindFromRenderStep("M7CameraCollision")
		metrics=nil
		player.CameraMinZoomDistance=.5
		player.CameraMaxZoomDistance=saved.max; player.CameraMinZoomDistance=saved.min
	end
end
return Collision
