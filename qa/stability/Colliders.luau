--!nonstrict
-- Server-owned invisible collision surfaces for art meshes which live on clients.
-- Only physical props: no foliage/leaves, no RemoteEvents or changes to save data.
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Plan=require(Shared.LandscapePlan)
local Collisions=require(Shared.V1CollisionPlan)
local Island=require(Shared.PersonalIsland)
local M={}
function M.attach(root,plot)
 local group=Instance.new("Folder")
 group.Name="V1PhysicalProxies"
 group:SetAttribute("ServerOwned",true)
 group.Parent=plot.model
 local floor=root:FindFirstChild("ForestFloor")
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances=floor and {floor,workspace.Terrain} or {workspace.Terrain}
 local count=0
 for _,d in ipairs(Collisions.build(Plan)) do
  if Island.surfaceContains(d.x,d.z,1) then
   local wx=plot.origin.X+d.x
   local wz=plot.origin.Z+d.z
   local hit=workspace:Raycast(Vector3.new(wx,40,wz),Vector3.new(0,-80,0),params)
   local ground=hit and hit.Position.Y or (plot.origin.Y+Island.surface.topY)
   local part=Instance.new("Part")
   part.Name=d.id
   part.Size=Vector3.new(d.width,d.height,d.width)
   part.CFrame=CFrame.new(wx,ground+d.height*.5-.25,wz)
   part.Anchored=true
   part.CanCollide=true;part.CanQuery=true;part.CanTouch=false
   part.CastShadow=false;part.Transparency=1
   part:SetAttribute("V1Collision",true)
   part:SetAttribute("ProxyKind",d.kind)
   part.Parent=group
   count+=1
  end
 end
 local decor=root:FindFirstChild("EnvironmentArt")
 if decor then
  for _,p in ipairs(decor:GetChildren()) do
   if p:IsA("BasePart") and p.Name:match("^LanternPost_") then
    p.CanCollide=true;p.CanQuery=true
   end
  end
 end
 group:SetAttribute("Count",count)
 return group
end
return M
