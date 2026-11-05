--!nonstrict
local Barriers={}
function Barriers.attach(art)
	local folder=Instance.new("Folder"); folder.Name="FenceCollisions"; folder.Parent=art.Parent
	for _,rail in ipairs(art:GetChildren()) do
		if rail:IsA("BasePart") and rail:GetAttribute("PhysicalBarrier") and rail.Size.X>1 then
			-- Thin rails alone let the Humanoid step/slide through. Fill the fence
			-- opening up to the existing post tops (3.2); never span the entrance.
			local p=Instance.new("Part"); p.Name=rail.Name.."Collision"
			p.Size=Vector3.new(rail.Size.X,3,.5)
			p.CFrame=CFrame.new(rail.Position.X,1.7,rail.Position.Z)
			p.Anchored=true; p.CanCollide=true; p.CanTouch=false; p.CanQuery=true
			p.Transparency=1; p.CastShadow=false; p.Parent=folder
		end
	end
end
return Barriers
