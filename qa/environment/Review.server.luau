--!nonstrict
-- ISOLATED VISUAL HARNESS: never included in default.project.json, no DataStore/payment/trade runtime.
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Config=require(Shared.Config)
local Factory=require(Shared.Factory).new(Config)
local Progression=require(Shared.Progression).new(Config)
local World=require(script.Parent.World)
local world=World.new(Config,8,{production=Factory.productionState,buildState=Progression.buildState,
	phaseState=Progression.phaseState,orderProgress=Factory.orderState,action=function() end,focus=function() end},true)
local owner={UserId=1,DisplayName="Honeyglade · Pilot",SetAttribute=function() end}
world:claim(owner); world:update(owner,Factory.newProfile(1,0))
world.root:SetAttribute("VisualHarness",true)
local count=0
for _,p in ipairs(world.root.EnvironmentArt:GetDescendants()) do
	if not p:IsA("BasePart") then continue end
	local barrier=p:GetAttribute("PhysicalBarrier")==true
	assert(p.Anchored and p.CanCollide==barrier and not p.CanTouch and p.CanQuery==barrier,"Unsafe decoration/barrier")
	assert(not p:FindFirstChildWhichIsA("ProximityPrompt",true),"Art contains a prompt")
	count+=1
end
assert(#world.plots==8 and count<=650,"Pilot topology/budget violated")
local path=world.root.EnvironmentArt.Decor_16:FindFirstChildWhichIsA("BasePart",true)
print("M7_PATH",path.Position,path.Size)
assert(path.Size.X>5 and path.Size.Y<.4,"Path scale/flattening failed")
for _,p in ipairs(world.root.EnvironmentArt:GetDescendants()) do
	if p:IsA("MeshPart") and string.find(p.Name,"RockPath") then
		local rx=(math.abs(p.CFrame.RightVector.X)*p.Size.X+math.abs(p.CFrame.LookVector.X)*p.Size.Z)/2
		local rz=(math.abs(p.CFrame.RightVector.Z)*p.Size.X+math.abs(p.CFrame.LookVector.Z)*p.Size.Z)/2
		for _,pad in pairs(world.plots[1].pads) do
			assert(math.abs(p.Position.X-pad.Position.X)>=rx+pad.Size.X/2 or math.abs(p.Position.Z-pad.Position.Z)>=rz+pad.Size.Z/2,"Path obscures a purchase pad")
		end
	end
end
local filter=RaycastParams.new(); filter.FilterType=Enum.RaycastFilterType.Include; filter.FilterDescendantsInstances={workspace.Terrain}
for x=-37,37,4 do for z=-44,28,4 do
	local hit=workspace:Raycast(Vector3.new(-142.5+x,30,-65+z),Vector3.new(0,-40,0),filter)
	assert(not hit or hit.Position.Y<.5,"Terrain intrudes on work floor")
end end
print("M7_VISUAL_HARNESS parts="..count.." plots=8 decorated=1 collisionGuards=PASS; no gameplay/backend acceptance")
local floor=world.plots[1].model.Floor
local grass=PhysicalProperties.new(Enum.Material.Grass)
assert(floor.CustomPhysicalProperties.Friction==grass.Friction,"Meadow changed ground physics")
assert(floor.Material==Enum.Material.SmoothPlastic and floor.M7Meadow:IsA("Texture"),"Quiet meadow missing")
assert(floor.Transparency==0 and floor.Reflectance==0,"Ground alpha/reflectance regression")
assert(floor.Position.Y-floor.Size.Y/2>=world.root.ForestFloor.Position.Y+world.root.ForestFloor.Size.Y/2,"Overlapping floor planes")
print("M7_A2C_GROUND PASS opaque matte top texture, original Grass friction, separated floor planes")
