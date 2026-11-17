--!nonstrict
-- Studio-only source-backed renderer. Shared geometry/textures, no asset uploads.
local Asset=game:GetService("AssetService")
local Config=require(script.Parent.TreeVisualConfig)
local M={}
function M.load(data,pixels)
	assert(game:GetService("RunService"):IsStudio(),"Tree candidate is Studio-only")
	local self={meshes={},images={},templates={},trees={}};local variants={}
	function self.destroy()
		for _,set in ipairs({self.trees,self.templates,self.meshes,self.images})do for _,v in ipairs(set)do v:Destroy()end;table.clear(set)end
	end
	local ok,err=pcall(function()
		local maps={}
		for i,key in ipairs({"bark","foliage"})do
			local item=pixels[key];local image=assert(Asset:CreateEditableImage({Size=Vector2.new(item.size,item.size)}),"Image budget")
			table.insert(self.images,image);local bytes=game:GetService("EncodingService"):Base64Decode(buffer.fromstring(item.rgba))
			assert(buffer.len(bytes)==item.size*item.size*4);image:WritePixelsBuffer(Vector2.zero,image.Size,bytes);maps[i]=image
		end
		for vi,variant in ipairs(data.variants)do
			variants[vi]={}
			for mi,source in ipairs(variant.meshes)do
				local mesh=assert(Asset:CreateEditableMesh(),"Mesh budget");table.insert(self.meshes,mesh);local ids={}
				for i,p in ipairs(source.vertices)do ids[i]=mesh:AddVertex(Vector3.new(table.unpack(p)))end
				for i,tri in ipairs(source.triangles)do
					local f=mesh:AddTriangle(ids[tri[1]+1],ids[tri[2]+1],ids[tri[3]+1]);local uv,normals={},{}
					for j=1,3 do uv[j]=mesh:AddUV(Vector2.new(table.unpack(source.uv[i][j])));normals[j]=mesh:AddNormal(Vector3.new(table.unpack(source.normals[i][j])))end
					mesh:SetFaceUVs(f,uv);mesh:SetFaceNormals(f,normals)
				end
				if source.weights then
					local bones={}
					for i,b in ipairs(variant.bones)do
						local props={Name=b.name,CFrame=CFrame.new(table.unpack(b.position)),Virtual=false};if i>1 then props.ParentId=bones[1]end;bones[i]=mesh:AddBone(props)
					end
					for i,w in ipairs(source.weights)do
						-- Root-only vertices must not submit duplicate Root bone IDs.
						if w[2]==0 then mesh:SetVertexBones(ids[i],{bones[1]});mesh:SetVertexBoneWeights(ids[i],{1})
						else mesh:SetVertexBones(ids[i],{bones[1],bones[w[1]+1]});mesh:SetVertexBoneWeights(ids[i],{1-w[2],w[2]})end
					end
				end
				local p=Asset:CreateMeshPartAsync(Content.fromObject(mesh),{CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Precise})
				table.insert(self.templates,p);variants[vi][mi]=p;p.Name=source.name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.DoubleSided=mi==2;p.Color=Color3.new(1,1,1)
				local surface=Asset:CreateSurfaceAppearanceAsync({ColorMap=Content.fromObject(maps[mi])})
				surface.AlphaMode=mi==2 and Enum.AlphaMode.Transparency or Enum.AlphaMode.Overlay;surface.Parent=p
				if source.weights then
					local root
					for i,b in ipairs(variant.bones)do
						local bone=p:FindFirstChild(b.name,true)
						if not bone then bone=Instance.new("Bone");bone.Name=b.name;bone.CFrame=CFrame.new(table.unpack(b.position));bone.Parent=root or p end
						if i==1 then root=bone end
					end
				end
			end
		end
	end)
	if not ok then self.destroy();error(err)end
	function self.create(parent,at,species,id)
		local c=assert(Config.species[species]);local appearance=Config.select(species,id)
		local tree=Instance.new("Model");tree.Name="Tree_"..id;tree:SetAttribute("TreeSpecies",species);tree:SetAttribute("StableTreeId",id)
		for key,value in pairs(appearance)do tree:SetAttribute(key,value)end
		tree:SetAttribute("WindPhase",appearance.phase)
		for i,f in ipairs(data.variants[appearance.crown].branchFactors)do tree:SetAttribute("BranchFactor"..i,f)end
		for mi,index in ipairs({appearance.root,appearance.crown})do
			local p=variants[index][mi]:Clone();p.CFrame=CFrame.identity;p.Parent=tree
			p:FindFirstChildOfClass("SurfaceAppearance").Color=Color3.new(table.unpack(mi==1 and c.barkPalette[appearance.bark] or c.foliagePalette[appearance.foliage]))
		end
		local d=c.collider;local collider=Instance.new("Part");collider.Name="TrunkCollider";collider.Size=Vector3.new(d.width,d.height,d.depth);collider.CFrame=CFrame.new(d.x,d.y,d.z)
		collider.Anchored=true;collider.Transparency=1;collider.CanCollide=true;collider.CanTouch=false;collider.CanQuery=true;collider.Parent=tree
		tree.PrimaryPart=tree.Willow_Trunk;tree:ScaleTo(appearance.scale);tree:PivotTo(at);tree.Parent=parent
		table.insert(self.trees,tree);return tree
	end
	return self
end
return M
