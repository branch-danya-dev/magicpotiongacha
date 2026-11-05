--!nonstrict
if not game:GetService("RunService"):IsStudio() then return end
local root=workspace:WaitForChild("PotionTycoonWorld")
while not root:GetAttribute("EnvironmentArtEnabled") do task.wait(.1) end
game:GetService("RunService").Heartbeat:Wait()
local filter=RaycastParams.new(); filter.FilterType=Enum.RaycastFilterType.Include; filter.FilterDescendantsInstances={workspace.Terrain}
local samples,highest=0,-math.huge
for i=1,8 do
	local plot=root:WaitForChild("Plot_"..i); local ox=((i-1)%4-1.5)*95; local oz=i<=4 and -65 or 85
	assert(plot.Floor.Position==Vector3.new(ox,0,oz-8),"Plot floor moved")
	assert(plot.Spawn.Position==Vector3.new(ox,1,oz+20),"Spawn moved")
	for x=-37,37,4 do for z=-44,28,4 do
		local hit=workspace:Raycast(Vector3.new(ox+x,60,oz+z),Vector3.new(0,-110,0),filter)
		if hit then highest=math.max(highest,hit.Position.Y); assert(hit.Position.Y<.5,"Terrain buries work floor "..i) end
		samples+=1
	end end
end
assert(root.TradePost.Position==Vector3.new(0,2,0),"Trade post moved")
print("M7_19A_CLEARANCE plots=8 samples="..samples.." highest="..highest.." worldAnchors=PASS")
if root:GetAttribute("IslandSurfaceVersion") then
	assert(root.ForestFloor.Transparency==1 and root.ForestFloor.CanCollide,"Base contract changed")
	print("M7_19A_BASE hidden=true collisionRetained=true")
end
