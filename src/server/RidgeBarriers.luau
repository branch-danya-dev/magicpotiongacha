--!nonstrict
local Boundary=require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.IslandBoundary)
local Barriers={}
function Barriers.attach(root)
	assert(not root:FindFirstChild("RidgeCollisions"),"Duplicate ridge boundary")
	local folder=Instance.new("Folder"); folder.Name="RidgeCollisions"
	for i,s in ipairs(Boundary.segments()) do
		local a=Vector3.new(s.a[1],(Boundary.top+Boundary.bottom)/2,s.a[2])
		local b=Vector3.new(s.b[1],a.Y,s.b[2])
		local p=Instance.new("Part"); p.Name="Ridge_"..i
		-- Overlap the corners by a thickness; no diagonal corner cracks.
		p.Size=Vector3.new(Boundary.thickness,Boundary.top-Boundary.bottom,s.length+Boundary.thickness*2)
		p.CFrame=CFrame.lookAt((a+b)/2,b)
		p.Anchored=true; p.CanCollide=true; p.CanTouch=false; p.CanQuery=true
		p.Transparency=1; p.CastShadow=false; p.Parent=folder
		p:SetAttribute("BarrierRole","IslandBoundary")
	end
	folder.Parent=root
end
return Barriers
