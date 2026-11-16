--!nonstrict
-- Original local sculpture, generated only in Studio Play. No remote mesh/upload.
-- A single closed surface, shared vertices/normals, coherent erosion and moss tint.
local Cliff={}
function Cliff.create(parent,origin)
	assert(game:GetService("RunService"):IsStudio(),"Local art sculpture only")
	local asset=game:GetService("AssetService")
	local editable=assert(asset:CreateEditableMesh(),"Local editable mesh memory unavailable")
	local sides,rows=96,40
	local points,ids,normals,colors,uvs,sums={},{},{},{},{},{}
	local function rim(a) return 1+.10*math.sin(a*5)+.035*math.cos(a*7) end
	for j=0,rows do
		local t=j/rows
		-- Broad upper shoulders erode into one asymmetric root, not stacked boulders.
		local taper=(1-t)^.56
		for i=0,sides-1 do
			local a=i/sides*math.pi*2
			local fold=math.sin(a*7+t*2)*.035+math.sin(a*11-t*4)*.018
			local erosion=math.noise(math.cos(a)*3.4,math.sin(a)*3.4,t*5.5)*.07
			local r=math.max(.006,taper*(rim(a)+math.sin(t*math.pi)*(fold+erosion)))
			local y=-2-t*76+math.sin(a*3+t*3)*math.sin(t*math.pi)*2.2
			local p=Vector3.new(math.cos(a)*59*r-8*t*t,y,-8+math.sin(a)*53*r+6*t*t)
			local k=#points+1;points[k]=p;ids[k]=editable:AddVertex(p);sums[k]=Vector3.zero
			normals[k]=editable:AddNormal(Vector3.yAxis)
			local variation=.94+.10*math.noise(p.X*.08,p.Y*.1,p.Z*.08)
			local moss=math.clamp(1-t*8+math.noise(p.X*.07,0,p.Z*.07)*.5,0,1)
			local stone=Color3.fromRGB(110,119,126):Lerp(Color3.fromRGB(77,94,78),moss)
			colors[k]=editable:AddColor(Color3.new(stone.R*variation,stone.G*variation,stone.B*variation),1)
			uvs[k]=editable:AddUV(Vector2.new(i/sides*18,t*12))
		end
	end
	local faces,edgeUses={},{}
	local function face(a,b,c)
		local n=(points[b]-points[a]):Cross(points[c]-points[a])
		assert(n.Magnitude>1e-8,"Degenerate cliff face")
		for _,k in ipairs({a,b,c}) do sums[k]+=n end
		local f=editable:AddTriangle(ids[a],ids[b],ids[c]);table.insert(faces,{f,a,b,c})
		for _,edge in ipairs({{a,b},{b,c},{c,a}}) do
			local lo,hi=math.min(edge[1],edge[2]),math.max(edge[1],edge[2])
			local key=lo..":"..hi;edgeUses[key]=(edgeUses[key] or 0)+1
		end
		editable:SetFaceNormals(f,{normals[a],normals[b],normals[c]})
		editable:SetFaceColors(f,{colors[a],colors[b],colors[c]})
		editable:SetFaceUVs(f,{uvs[a],uvs[b],uvs[c]})
	end
	for j=0,rows-1 do for i=0,sides-1 do
		local a=j*sides+i+1;local b=j*sides+(i+1)%sides+1
		local c=(j+1)*sides+i+1;local d=(j+1)*sides+(i+1)%sides+1
		face(a,b,c);face(b,d,c)
	end end
	-- Caps close the mesh below the existing Terrain skin and at the root tip.
	for i=2,sides-1 do face(1,i+1,i) end
	local last=rows*sides+1
	for i=1,sides-2 do face(last,last+i,last+i+1) end
	for _,uses in pairs(edgeUses) do assert(uses==2,"Open or non-manifold cliff edge") end
	for k,n in ipairs(sums) do assert(n.Magnitude>1e-8,"Invalid cliff normal");editable:SetNormal(normals[k],n.Unit) end
	local part=asset:CreateMeshPartAsync(Content.fromObject(editable),{CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Precise})
	part.Name="WizardContinuousCliff";part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false
	part.Material=Enum.Material.Slate;part.Color=Color3.new(1,1,1)
	-- EditableMesh vertices retain their authored local coordinates in native Play.
	part.CFrame=CFrame.new(origin)
	part:SetAttribute("EnvironmentDetail",1);part.Parent=parent
	parent:SetAttribute("OriginalCliffVertices",#points);parent:SetAttribute("OriginalCliffTriangles",#faces)
	print("WIZARD_CLIFF_READY",#points,#faces,part.Size)
	return {part=part,mesh=editable,vertices=#points,triangles=#faces}
end
return Cliff
