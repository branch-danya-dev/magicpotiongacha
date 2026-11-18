--!nonstrict
-- Local Studio preview only. Lazy one-variant allocation, shared atlas, no uploads.
local Asset=game:GetService("AssetService")
local Appearance=require(script.Parent.Appearance)
local Identity=require(script.Parent.TreeVisualConfig)
local M={}
function M.load(data,pixels,variantName)
	assert(game:GetService("RunService"):IsStudio(),"Vegetation candidate is Studio-only")
	local variant;for _,v in ipairs(data.variants)do if v.id==variantName then variant=v end end
	assert(variant,"Unprepared geometry variant")
	local self={meshes={},images={},templates={},trees={}}
	function self.destroy()
		for _,list in ipairs({self.trees,self.templates,self.meshes,self.images})do for _,v in ipairs(list)do v:Destroy()end;table.clear(list)end
	end
	local ok,err=pcall(function()
		local image=assert(Asset:CreateEditableImage({Size=Vector2.new(pixels.size,pixels.size)}),"Vegetation image budget exhausted")
		table.insert(self.images,image)
		local bytes=game:GetService("EncodingService"):Base64Decode(buffer.fromstring(pixels.rgba));assert(buffer.len(bytes)==pixels.size*pixels.size*4)
		image:WritePixelsBuffer(Vector2.zero,image.Size,bytes)
		for _,source in ipairs(variant.meshes)do
			local mesh=assert(Asset:CreateEditableMesh(),"Vegetation mesh budget exhausted");table.insert(self.meshes,mesh)
			local ids={};for i,p in ipairs(source.vertices)do ids[i]=mesh:AddVertex(Vector3.new(table.unpack(p)))end
			local uvCache,normalCache={},{}
			for i,tri in ipairs(source.triangles)do
				local face=mesh:AddTriangle(ids[tri[1]+1],ids[tri[2]+1],ids[tri[3]+1]);local uvs,normals={},{}
				for j=1,3 do
					local uv=source.uv[i][j];local key=table.concat(uv,",")
					if not uvCache[key]then uvCache[key]=mesh:AddUV(Vector2.new(table.unpack(uv)))end;uvs[j]=uvCache[key]
					local n=source.normals[i][j];key=table.concat(n,",")
					if not normalCache[key]then normalCache[key]=mesh:AddNormal(Vector3.new(table.unpack(n)))end;normals[j]=normalCache[key]
				end
				mesh:SetFaceUVs(face,uvs);mesh:SetFaceNormals(face,normals)
			end
			local used={[1]=true};for _,ws in ipairs(source.weights)do for _,w in ipairs(ws)do used[w[1]+1]=true end end
			local bones={}
			for i,b in ipairs(variant.bones)do if used[i] then
				local props={Name=b.name,CFrame=CFrame.new(table.unpack(b.position)),Virtual=false};if i>1 then props.ParentId=bones[1] end
				bones[i]=mesh:AddBone(props)
			end end
			for i,ws in ipairs(source.weights)do
				local bi,bw,total={},{},0;for _,w in ipairs(ws)do total+=w[2] end
				for _,w in ipairs(ws)do table.insert(bi,bones[w[1]+1]);table.insert(bw,w[2]/total)end
				mesh:SetVertexBones(ids[i],bi);mesh:SetVertexBoneWeights(ids[i],bw)
			end
			local part=Asset:CreateMeshPartAsync(Content.fromObject(mesh),{CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Automatic})
			table.insert(self.templates,part);part.Name=source.name;part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false
			part.Color=Color3.new(1,1,1);part.DoubleSided=source.role=="Leaf" or source.role=="LeafSecondary";part:SetAttribute("VegetationRole",source.role)
			local maps={ColorMap=Content.fromObject(image)};if source.role=="Magic" then maps.EmissiveMask=Content.fromObject(image) end
			local surface=Asset:CreateSurfaceAppearanceAsync(maps);surface.AlphaMode=part.DoubleSided and Enum.AlphaMode.Transparency or Enum.AlphaMode.Overlay;surface.Parent=part
			local root
			for i,b in ipairs(variant.bones)do if used[i] then
				local bone=part:FindFirstChild(b.name,true)
				if not bone then bone=Instance.new("Bone");bone.Name=b.name;bone.CFrame=CFrame.new(table.unpack(b.position));bone.Parent=root or part end
				if i==1 then root=bone end
			end end
		end
	end)
	if not ok then self.destroy();error(err)end
	function self.apply(tree,style,quality)
		for _,part in ipairs(tree:GetChildren())do if part:IsA("MeshPart")then
			local role=part:GetAttribute("VegetationRole");local key=Appearance.colorKey(role)
			local surface=part:FindFirstChildOfClass("SurfaceAppearance")
			if key then surface.Color=Color3.new(table.unpack(style[key]))end
			if role=="Magic"then surface.EmissiveTint=Color3.new(table.unpack(style.MagicGlowColor));surface.EmissiveStrength=style.MagicGlowIntensity*(quality=="minimal" and .3 or quality=="reduced" and .65 or 1)end
		end end
		for key,value in pairs(style)do tree:SetAttribute(key,type(value)=="table" and Color3.new(table.unpack(value)) or value)end
	end
	function self.create(parent,at,id,style,quality)
		local tree=Instance.new("Model");tree.Name="Vegetation_"..id;tree:SetAttribute("TreeSpecies",data.key);tree:SetAttribute("StableTreeId",id)
		table.insert(self.trees,tree)
		tree:SetAttribute("WindPhase",Identity.hash(id)%10000/10000*math.pi*2)
		local pivot=Instance.new("Part");pivot.Name="Origin";pivot.Size=Vector3.one;pivot.Anchored=true;pivot.Transparency=1;pivot.CanCollide=false;pivot.CanTouch=false;pivot.CanQuery=false;pivot.Parent=tree
		tree.PrimaryPart=pivot
		for _,template in ipairs(self.templates)do local part=template:Clone();part.CFrame=CFrame.identity;part.Parent=tree end
		self.apply(tree,style,quality);tree:PivotTo(at);tree.Parent=parent;return tree
	end
	return self
end
return M
