--!nonstrict
-- Existing licensed static models use EnvironmentView's existing plant wind/LOD.
assert(game:GetService("RunService"):IsStudio() and workspace:GetAttribute("LandscapePilotQA"))
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local P=require(Shared.LandscapePlan)
local Island=require(Shared.PersonalIsland)
local Geometry=require(Shared.NatureGeometry)
local audit=P.audit(require(Shared.Config),Island);assert(audit.ok,table.concat(audit.errors,"; "))
local O=Vector3.new(table.unpack(Island.origin))
local root=workspace:WaitForChild("PotionTycoonWorld")
while not root:GetAttribute("GroundCoverReady")do task.wait(.1)end
local folder=Instance.new("Folder");folder.Name="LandscapeStatic";folder.Parent=root.EnvironmentArt
local library=game:GetService("ServerStorage"):WaitForChild("M7NatureTemplates")
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={workspace.Terrain}
local count,triangles=0,0
local function place(name,x,z,scale,yaw,id,detail)
	local hit=workspace:Raycast(O+Vector3.new(x,20,z),Vector3.new(0,-40,0),params)
	assert(hit,"Unsupported vegetation root: "..id)
	local model=assert(library:FindFirstChild(name),name):Clone();model.Name=id;model.WorldPivot=CFrame.identity
	model:ScaleTo(scale);model:PivotTo(CFrame.new(O.X+x,hit.Position.Y-.035,O.Z+z)*CFrame.Angles(0,math.rad(yaw),0))
	for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")then
		p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p:SetAttribute("EnvironmentDetail",detail)
		local leaf=detail==2 or p.Name:match("_2$")
		local c=Color3.new(table.unpack(leaf and P.palette.leaf or P.palette.bark));p.Color=c
		local sa=p:FindFirstChildOfClass("SurfaceAppearance");if sa then sa.Color=c end
		count+=1
	end end
	model:SetAttribute("LandscapeAsset",name);model:SetAttribute("LandscapeScale",scale);model.Parent=folder
	triangles+=Geometry[name].triangles
end
local ok,err=pcall(function()
	for _,t in ipairs(P.trees)do if t.template then place(t.template,t.x,t.z,t.scale,t.yaw,t.id,1)end end
	for i,p in ipairs(P.cover)do place(p[1],p[2],p[3],p[4],p[5],"Undergrowth_"..i,2)end
end)
if not ok then folder:Destroy();count=0;triangles=0;root:SetAttribute("LandscapeStaticError",tostring(err));warn("LANDSCAPE_STATIC_BLOCKED",err)end
root:SetAttribute("LandscapeStaticParts",count);root:SetAttribute("LandscapeStaticTriangles",triangles)
root:SetAttribute("LandscapeStaticReady",ok)
root:SetAttribute("LandscapeReady",true)
print("LANDSCAPE_STATIC_STATE",game:GetService("HttpService"):JSONEncode({ready=ok,error=err,parts=count,triangles=triangles,audit=audit}))
