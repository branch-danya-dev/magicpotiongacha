--!nonstrict
local Barriers={}
local Geometry=require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.FenceGeometry)
function Barriers.attach(art)
	local folder=Instance.new("Folder"); folder.Name="FenceCollisions"; folder.Parent=art.Parent
	for _,rail in ipairs(art:GetChildren()) do
		if rail:IsA("BasePart") and rail:GetAttribute("PhysicalBarrier") and rail.Size.X>1 then
			-- Thin rails alone let the Humanoid step/slide through. Fill the fence
			-- opening up to the existing post tops (3.2); never span the entrance.
			local p=Instance.new("Part"); p.Name=rail.Name.."Collision"
			local direction=rail.CFrame.RightVector
			local projected=math.sqrt(direction.X^2+direction.Z^2)
			p.Size=Vector3.new(rail.Size.X*projected+Geometry.endpointOverlap*2,Geometry.top-Geometry.bottom,Geometry.depth)
			p.CFrame=CFrame.new(rail.Position.X,(Geometry.top+Geometry.bottom)/2,rail.Position.Z)*CFrame.Angles(0,math.atan2(-direction.Z,direction.X),0)
			p:SetAttribute("BarrierRole","LowFence")
			p.Anchored=true; p.CanCollide=true; p.CanTouch=false; p.CanQuery=true
			p.Transparency=1; p.CastShadow=false; p.Parent=folder
		end
	end
end
return Barriers
