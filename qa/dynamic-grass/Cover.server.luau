--!nonstrict
assert(game:GetService("RunService"):IsStudio(),"R4A is an isolated Studio art scene")
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local P=require(Shared.GrassPlan)
local Island=require(Shared.PersonalIsland)
local Config=require(Shared.Config)
local Geometry=require(Shared.NatureGeometry)
local Layout=require(Shared.RomanticLayout)
local root=workspace:WaitForChild("PotionTycoonWorld")
while not root:GetAttribute("WizardReady") do task.wait() end
local O=Vector3.new(table.unpack(Island.origin))
local terrain=workspace.Terrain
-- Decoration/GrassLength are serialized in the Rojo place (not a runtime hack).
local region=Region3.new(O+Vector3.new(-68,-8,-72),O+Vector3.new(68,8,56)):ExpandToGrid(4)
local corner=region.CFrame.Position-region.Size/2
local mats,occupancy=terrain:ReadVoxels(region,4)
local changed=0
for ix=1,#mats do for iy=1,#mats[ix] do for iz=1,#mats[ix][iy] do
	if mats[ix][iy][iz]==Enum.Material.Grass then
		local x=corner.X+(ix-.5)*4-O.X;local z=corner.Z+(iz-.5)*4-O.Z
		local mat=Enum.Material[P.surface(x,z,Config)]
		if mat~=mats[ix][iy][iz] then changed+=1;mats[ix][iy][iz]=mat end
	end
end end end
-- Exact same voxel occupancy: no displacement, extra hill, collision or island resizing.
terrain:WriteVoxels(region,4,mats,occupancy)
terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(83,119,96))
terrain:SetMaterialColor(Enum.Material.LeafyGrass,Color3.fromRGB(88,111,87))
local folder=Instance.new("Folder");folder.Name="DynamicGroundCover";folder.Parent=root.EnvironmentArt
local library=game:GetService("ServerStorage"):WaitForChild("M7NatureTemplates")
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={terrain}
-- WriteVoxels updates physics asynchronously. Wait for an actual surface before placing plants.
local ready=false
for _=1,120 do
	game:GetService("RunService").Heartbeat:Wait()
	if workspace:Raycast(O+Vector3.new(0,16,20),Vector3.new(0,-28,0),params) then ready=true;break end
end
assert(ready,"R4A terrain query surface did not become ready")
-- R3 authored some low plants at a constant Y even on the irregular rim. Seat
-- only grass/clover/ferns on the real surface; leave trees and every landmark alone.
local seated,unsupported=0,0
for _,m in ipairs(root.EnvironmentArt:GetChildren()) do
	if m:IsA("Model") and (m.Name:match("^Grass_") or m.Name:match("^Clover_") or m.Name:match("^Fern_")) then
		local pivot=m:GetPivot();local pos=pivot.Position
		local hit=workspace:Raycast(Vector3.new(pos.X,O.Y+16,pos.Z),Vector3.new(0,-28,0),params)
		if hit then m:PivotTo(pivot+Vector3.new(0,hit.Position.Y-.035-pos.Y,0));seated+=1
		else m:Destroy();unsupported+=1 end
	end
end
local parts,triangles,skipped=0,0,0
local details={0,0,0};local zones={}
for i,d in ipairs(P.build(Config,Island,Geometry,Layout)) do
	local hit=workspace:Raycast(O+Vector3.new(d.x,16,d.z),Vector3.new(0,-28,0),params)
	if not hit then skipped+=1;continue end
	local m=assert(library:FindFirstChild(d.name),d.name):Clone()
	m.WorldPivot=CFrame.identity;m:ScaleTo(d.scale);m.Name=string.format("Cover_%03d_%s",i,d.zone)
	m:PivotTo(CFrame.new(hit.Position-Vector3.new(0,.035,0))*CFrame.Angles(0,math.rad(d.yaw),0))
	for _,p in ipairs(m:GetDescendants()) do if p:IsA("MeshPart") then
		p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false
		p.Color=Color3.fromRGB(table.unpack(d.tint));local a=p:FindFirstChildOfClass("SurfaceAppearance");if a then a.Color=p.Color end
		p:SetAttribute("EnvironmentDetail",d.detail);p:SetAttribute("Meadow",true)
		p:SetAttribute("MeadowWind",d.wind);p:SetAttribute("MeadowGroundY",hit.Position.Y)
		p:SetAttribute("GrassZone",d.zone);parts+=1;details[d.detail]+=1
	end end
	triangles+=Geometry[d.name].triangles;zones[d.zone]=(zones[d.zone] or 0)+1;m.Parent=folder
end
root:SetAttribute("GrassAddedParts",parts);root:SetAttribute("GrassAddedTriangles",triangles)
assert(parts>=150,"R4A ground cover placement failed; do not accept an empty decorative layer")
root:SetAttribute("GroundCoverReady",true)
print("GRASS_COVER "..game:GetService("HttpService"):JSONEncode({parts=parts,triangles=triangles,
	details=details,zones=zones,skipped=skipped,materialVoxelsChanged=changed,occupancyChanged=0,
	decoration=terrain.Decoration,grassLength=terrain.GrassLength,collision=false,seatedExisting=seated,removedUnsupported=unsupported}))
