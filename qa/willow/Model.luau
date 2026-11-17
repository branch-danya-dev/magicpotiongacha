--!nonstrict
-- Local Studio prototype reconstructed from the exact exported Blender mesh data.
-- Two shared mesh resources and two immutable textures; never uploads anything.
local Asset=game:GetService("AssetService")
local M={}
function M.load(data,pixels)
	assert(game:GetService("RunService"):IsStudio(),"Willow prototype is Studio-only")
	local self={meshes={},images={},templates={},trees={}}
	local function image(item)
		local result=assert(Asset:CreateEditableImage({Size=Vector2.new(item.size,item.size)}),"Image memory budget")
		table.insert(self.images,result)
		local bytes=game:GetService("EncodingService"):Base64Decode(buffer.fromstring(item.rgba))
		assert(buffer.len(bytes)==item.size*item.size*4)
		result:WritePixelsBuffer(Vector2.zero,result.Size,bytes)
		return result
	end
	function self.destroy()
		for _,set in ipairs({self.trees,self.templates,self.meshes,self.images})do
			for _,v in ipairs(set)do v:Destroy()end;table.clear(set)
		end
	end
	local ok,err=pcall(function()
		local maps={image(pixels.bark),image(pixels.foliage)}
		for mi,source in ipairs(data.meshes) do
			local mesh=assert(Asset:CreateEditableMesh(),"Mesh memory budget");table.insert(self.meshes,mesh)
			local ids={}
			for i,p in ipairs(source.vertices)do ids[i]=mesh:AddVertex(Vector3.new(table.unpack(p)))end
			for i,tri in ipairs(source.triangles)do
				local f=mesh:AddTriangle(ids[tri[1]+1],ids[tri[2]+1],ids[tri[3]+1])
				local uv,normals={},{}
				for j=1,3 do
					uv[j]=mesh:AddUV(Vector2.new(table.unpack(source.uv[i][j])))
					normals[j]=mesh:AddNormal(Vector3.new(table.unpack(source.normals[i][j])))
				end
				mesh:SetFaceUVs(f,uv);mesh:SetFaceNormals(f,normals)
			end
			if source.weights then
				local bones={}
				for i,b in ipairs(data.bones)do
					local props={Name=b.name,CFrame=CFrame.new(table.unpack(b.position)),Virtual=false}
					if i>1 then props.ParentId=bones[1] end
					bones[i]=mesh:AddBone(props)
				end
				for i,w in ipairs(source.weights)do
					mesh:SetVertexBones(ids[i],{bones[1],bones[w[1]+1]})
					mesh:SetVertexBoneWeights(ids[i],{1-w[2],w[2]})
				end
			end
			local part=Asset:CreateMeshPartAsync(Content.fromObject(mesh),{CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Precise})
			table.insert(self.templates,part);part.Name=source.name
			part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false
			part.DoubleSided=mi==2;part.Transparency=0;part.Color=Color3.new(1,1,1)
			local surface=Asset:CreateSurfaceAppearanceAsync({ColorMap=Content.fromObject(maps[mi])})
			surface.AlphaMode=mi==2 and Enum.AlphaMode.Transparency or Enum.AlphaMode.Overlay
			if mi==1 then part.Color=Color3.fromRGB(123,104,82) end
			surface.Parent=part
			if source.weights then
				local root
				for i,b in ipairs(data.bones)do
					local bone=part:FindFirstChild(b.name,true)
					if not bone then
						bone=Instance.new("Bone");bone.Name=b.name;bone.CFrame=CFrame.new(table.unpack(b.position));bone.Parent=root or part
					end
					if i==1 then root=bone end
				end
			end
		end
	end)
	if not ok then self.destroy();error(err)end
	function self.create(parent,at,index)
		local tree=Instance.new("Model");tree.Name="Willow_"..index
		for _,source in ipairs(self.templates)do local p=source:Clone();p.CFrame=at;p.Parent=tree end
		local collider=Instance.new("Part");collider.Name="TrunkCollider";collider.Size=Vector3.new(3.8,9,3.8)
		collider.CFrame=at*CFrame.new(-3,4.5,0);collider.Transparency=1;collider.Anchored=true
		collider.CanCollide=true;collider.CanQuery=true;collider.CanTouch=false;collider.Parent=tree
		tree.PrimaryPart=tree.Willow_Trunk;tree.Parent=parent;table.insert(self.trees,tree);return tree
	end
	return self
end
return M
