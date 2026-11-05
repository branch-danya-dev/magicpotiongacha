--!nonstrict
-- Complete hash-reviewed meshes. No sphere crowns, runtime imports or map changes.
local Plan=require(game.ReplicatedStorage.PotionTycoon.Shared.ForestPlan)
local Art={}
local leafTints={{244,255,232},{226,248,211},{251,244,218}}
function Art.build(d,templates)
	local model
	local function mark(part,role)
		part:SetAttribute("ForestRole",role); part:SetAttribute("ForestAnchor",Vector3.new(d.position[1],0,d.position[3]))
	end
	if d.forest=="log" then
		model=Instance.new("Model"); model.Name=d.id
		for _,p in ipairs(Plan.logPieces()) do
			local part=assert(templates:FindFirstChild(p.template):FindFirstChild(p.source)):Clone()
			part.Size=Vector3.new(table.unpack(p.sourceSize))*d.scale
			part.CFrame=CFrame.new(Vector3.new(table.unpack(p.position))*d.scale)*CFrame.Angles(0,0,p.roll)
			mark(part,p.role); part.Parent=model
		end
	else
		local source=assert(templates:FindFirstChild(d.template),"Reviewed woodland mesh missing")
		model=source:Clone(); model.Name=d.id
		for _,p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then
			local canopy=d.forest=="tree" and string.match(p.Name,"_2$")~=nil
			mark(p,(d.forest=="tree" or d.forest=="boulder") and "core" or "ground")
			if canopy then
				p:SetAttribute("ForestCanopy",true)
				local surface=p:FindFirstChildOfClass("SurfaceAppearance")
				if surface then surface.Color=Color3.fromRGB(table.unpack(leafTints[(d.variant or 0)%#leafTints+1])) end
			end
		end end
		model.WorldPivot=CFrame.identity; model:ScaleTo(d.scale)
	end
	model.WorldPivot=CFrame.identity
	return model
end
function Art.slopeFrame(cf,normal)
	local right=cf.RightVector-normal*cf.RightVector:Dot(normal)
	if right.Magnitude<.001 then return cf end
	right=right.Unit
	return CFrame.fromMatrix(cf.Position,right,normal,right:Cross(normal))
end
return Art
