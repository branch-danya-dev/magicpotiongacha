--!nonstrict
-- Reuse admitted bark meshes without their thin leaf cards. Crown geometry is
-- original native solid form; never imports, uploads or modifies source assets.
local Plan=require(game.ReplicatedStorage.PotionTycoon.Shared.ForestPlan)
local Art={}
local colors={{83,121,75},{108,143,79},{139,163,94},{100,76,56},{192,157,108}}
function Art.build(d,templates)
	local model=Instance.new("Model"); model.Name=d.id
	local function mark(part,role)
		part:SetAttribute("ForestRole",role); part:SetAttribute("ForestAnchor",Vector3.new(d.position[1],0,d.position[3]))
	end
	if d.forest=="tree" then
		local f=assert(Plan.forms[d.species]); local source=assert(templates:FindFirstChild(f.template))
		local trunk=assert(source:FindFirstChild(f.template.."_1"),"Reviewed bark mesh missing"):Clone()
		trunk.Size*=Vector3.new(f.stemWide,f.stemY,f.stemWide)*d.scale
		trunk.Position*=Vector3.new(f.stemWide,f.stemY,f.stemWide)*d.scale
		mark(trunk,"core"); trunk.Parent=model
	elseif d.template then
		model:Destroy(); model=assert(templates:FindFirstChild(d.template)):Clone(); model.Name=d.id
		for _,p in ipairs(model:GetDescendants()) do
			if p:IsA("BasePart") then mark(p,d.forest=="boulder" and "core" or "ground") end
			if p:IsA("SurfaceAppearance") and d.forest=="understory" then p.Color=Color3.fromRGB(126,170,101) end
		end
	end
	local pieces=d.forest=="tree" and Plan.crowns(d.species,d.variant) or (d.forest=="log" and Plan.logPieces() or {})
	for i,p in ipairs(pieces) do
		local part=Instance.new("Part"); part.Name=d.forest=="tree" and "ForestCrown_"..i or "FallenWood_"..i
		part.Size=Vector3.new(table.unpack(p.size))*d.scale; part.Position=Vector3.new(table.unpack(p.position))*d.scale
		if p.shape=="Ball" then
			-- Sphere SpecialMesh supports ellipsoids; PartType.Ball clamps its diameter.
			local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Sphere; mesh.Scale=Vector3.one; mesh.Parent=part
		else part.Shape=Enum.PartType.Cylinder end
		part.Material=d.forest=="log" and p.shape=="Cylinder" and Enum.Material.Wood or Enum.Material.SmoothPlastic
		local c=colors[p.tint]; local shift=d.variant and (d.variant-1)*4 or 0
		part.Color=Color3.fromRGB(c[1]+shift,c[2]+shift,c[3]); part.Reflectance=0
		part.TopSurface=Enum.SurfaceType.Smooth; part.BottomSurface=Enum.SurfaceType.Smooth
		part.CastShadow=p.role=="core"; mark(part,p.role); part.Parent=model
	end
	model.WorldPivot=CFrame.identity
	if d.template and d.forest~="tree" then model:ScaleTo(d.scale) end
	return model
end
function Art.slopeFrame(cf,normal)
	local right=cf.RightVector-normal*cf.RightVector:Dot(normal)
	if right.Magnitude<.001 then return cf end
	right=right.Unit
	return CFrame.fromMatrix(cf.Position,right,normal,right:Cross(normal))
end
return Art
