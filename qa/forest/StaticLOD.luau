--!nonstrict
-- Two fixed, unskinned meshes per existing source variant; atlas is borrowed.
-- No asset upload, geometry randomization, runtime LOD allocation or extra loop.
local Asset=game:GetService("AssetService")
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Factory=require(Shared.MeshFactory)
local M={}
function M.load(lib,data,variantName)
	local variant;for _,v in ipairs(data.variants)do if v.id==variantName then variant=v end end
	assert(variant);local templates={}
	for _,role in ipairs({"Bark","Leaf"})do
		local lo,hi=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
		local mesh=Factory.build(function(mesh)
			for _,s in ipairs(variant.meshes)do
				-- Secondary leaf cards and emissive extras are near-only. The main
				-- crown, trunk, major branches and root stones retain their shapes.
				if (role=="Leaf" and s.role=="Leaf")or(role=="Bark" and s.role~="Leaf" and s.role~="LeafSecondary")then
					local ids={};for i,v in ipairs(s.vertices)do
						local p=Vector3.new(table.unpack(v));ids[i]=mesh:AddVertex(p);lo=lo:Min(p);hi=hi:Max(p)
					end
					local uvCache,nCache={},{}
					for i,tri in ipairs(s.triangles)do
						local face=mesh:AddTriangle(ids[tri[1]+1],ids[tri[2]+1],ids[tri[3]+1]);local uv,n={},{}
						for j=1,3 do
							local a=s.uv[i][j];local key=table.concat(a,",")
							if not uvCache[key]then uvCache[key]=mesh:AddUV(Vector2.new(table.unpack(a)))end;uv[j]=uvCache[key]
							a=s.normals[i][j];key=table.concat(a,",")
							if not nCache[key]then nCache[key]=mesh:AddNormal(Vector3.new(table.unpack(a)))end;n[j]=nCache[key]
						end
						mesh:SetFaceUVs(face,uv);mesh:SetFaceNormals(face,n)
						if i%256==0 then task.wait()end
					end
				end
			end
		end)
		table.insert(lib.meshes,mesh)
		local p=Asset:CreateMeshPartAsync(Content.fromObject(mesh),{CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Automatic})
		table.insert(lib.templates,p);table.insert(templates,p)
		p.Name="LOD_"..role;p:SetAttribute("ForestStaticLOD",true);p:SetAttribute("VegetationRole",role)
		p:SetAttribute("ForestBoundCenter",(lo+hi)*.5);p:SetAttribute("ForestBoundHalf",(hi-lo)*.5);p:SetAttribute("ForestOccluder",true)
		p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.DoubleSided=role=="Leaf";p.LocalTransparencyModifier=1
		local surface=Asset:CreateSurfaceAppearanceAsync({ColorMap=Content.fromObject(lib.images[1])})
		surface.AlphaMode=role=="Leaf" and Enum.AlphaMode.Transparency or Enum.AlphaMode.Overlay;surface.Parent=p
	end
	return templates
end
return M
