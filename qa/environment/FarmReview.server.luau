--!nonstrict
if not game:GetService("RunService"):IsStudio() then return end
local root=workspace:WaitForChild("PotionTycoonWorld")
while not root:GetAttribute("EnvironmentArtEnabled") do task.wait(.1) end
game:GetService("RunService").Heartbeat:Wait()
local filter=RaycastParams.new(); filter.FilterType=Enum.RaycastFilterType.Include; filter.FilterDescendantsInstances={workspace.Terrain}
local samples,highest,lowest=0,-math.huge,math.huge
local integrated=root:GetAttribute("FarmGroundVersion")==1
for i=1,8 do
	local plot=root:WaitForChild("Plot_"..i); local ox=((i-1)%4-1.5)*95; local oz=i<=4 and -65 or 85
	assert(plot.Floor.Position==Vector3.new(ox,0,oz-8),"Plot floor moved")
	assert(plot.Spawn.Position==Vector3.new(ox,1,oz+20),"Spawn moved")
	if integrated then assert(plot.Floor.Transparency==1 and plot.Floor.CanCollide,"Floor contract"); assert(plot.Spawn.Transparency==1 and not plot.Spawn.CanCollide,"Spawn pedestal") end
	for x=-37,37,4 do for z=-44,28,4 do
		local hit=workspace:Raycast(Vector3.new(ox+x,60,oz+z),Vector3.new(0,-110,0),filter)
		assert(hit,"Missing ground"); highest=math.max(highest,hit.Position.Y); lowest=math.min(lowest,hit.Position.Y)
		assert(hit.Position.Y<.5,"Terrain buries work floor "..i); samples+=1
	end end
end
assert(root.TradePost.Position==Vector3.new(0,2,0),"Trade post moved")
if integrated then assert(root.Bazaar.Transparency==1 and root.Bazaar.CanCollide,"Bazaar contract") end
print("M7_19B_CLEARANCE plots=8 samples="..samples.." highest="..highest.." lowest="..lowest.." anchors=PASS integrated="..tostring(integrated))
