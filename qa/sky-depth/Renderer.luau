--!nonstrict
-- Owned by the existing R3 renderer; no Lighting writes or frame connection.
local Asset=game:GetService("AssetService")
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Model=require(Shared.SkyDepthModel)
local Data=require(Shared.SkyDepthData)
local Config=require(Shared.SkyLandmarkConfig)
local Resources=require(Shared.SkyLandmarkResources)
local M={}
function M.create(parent,cloudImage,cloudRect)
 local self={ready=false,destroyed=false,error=nil,updates=0,lastMs=0,mode="R3",pixelWrites=0}
 local pool=Resources.new();local folder;local groups={};local limbs={};local anchors={};local currentMode
 local frame=Model.frame(Config.offset)
 local origin=Vector3.new(table.unpack(require(Shared.PersonalIsland).origin))
 local right,up,away=Vector3.new(table.unpack(frame.right)),Vector3.new(table.unpack(frame.up)),Vector3.new(table.unpack(frame.away))
 local treeCenter=origin+Vector3.new(table.unpack(Config.offset))
 function self.destroy()
  if self.destroyed then return end;self.destroyed=true;self.ready=false
  if folder then folder:Destroy();folder=nil end;pool.destroy();table.clear(groups);table.clear(limbs)
 end
 local ok,err=pcall(function()
  folder=Instance.new("Folder");folder.Name="R4DepthPrototype";folder.Parent=parent
  local atlas=pool.get("atlas",function()return Asset:CreateEditableImage({Size=Vector2.new(1024,1024)})end)
  local bytes=game:GetService("EncodingService"):Base64Decode(buffer.fromstring(Data.rgba))
  assert(buffer.len(bytes)==Model.textureBytes,"R4 pixel length");atlas:WritePixelsBuffer(Vector2.zero,atlas.Size,bytes);self.pixelWrites=1
  local function plane(name,x,y,depth,size,image,rect)
   local point,scale=Model.position(frame,x,y,depth,true)
   local a=Instance.new("Part");a.Name=name;a.Size=Vector3.one;a.Anchored=true;a.Transparency=1
   a.CanCollide=false;a.CanQuery=false;a.CanTouch=false;a.CastShadow=false;a.Position=origin+Vector3.new(table.unpack(point));a.Parent=folder
   anchors[name]={a.Position.X,a.Position.Y,a.Position.Z}
   local g=Instance.new("BillboardGui");g.Name=name.."Plane";g.Adornee=a;g.AlwaysOnTop=false;g.LightInfluence=0
   g.Size=UDim2.fromScale(size[1]*scale,size[2]*scale);g.MaxDistance=Config.maxDistance;g.Active=false;g.Enabled=false;g.Parent=a
   local l=Instance.new("ImageLabel");l.Name=name.."Mask";l.Size=UDim2.fromScale(1,1);l.BackgroundTransparency=1;l.Active=false
   l.ImageContent=Content.fromObject(image);l.ImageRectOffset=Vector2.new(rect.x,rect.y);l.ImageRectSize=Vector2.new(rect.width,rect.height);l.Parent=g
   local item={gui=g,label=l};groups[name]=item;return item
  end
  for i,name in ipairs({"rear","middle","front"})do plane(name,0,0,Model.depths[name],Config.tree.size,atlas,Data.rects[i])end
  local accent=groups.front.label:Clone();accent.Name="DirectionalAccent";accent.ZIndex=2
  local r=Data.rects[4];accent.ImageRectOffset=Vector2.new(r.x,r.y);accent.ImageRectSize=Vector2.new(r.width,r.height);accent.Parent=groups.front.gui
  self.accent=accent
  local directional=Instance.new("UIGradient");directional.Name="DirectionalRidgeLight"
  directional.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.5,.35),NumberSequenceKeypoint.new(1,1)})
  directional.Parent=accent;self.directional=directional
  -- Clouds cross different branch depths, separate from the unchanged ocean.
  for _,spec in ipairs({{"cloudBack",-1150,-690,2100,620},{"cloudFront",480,-1150,2850,680}})do
   local c=plane(spec[1],spec[2],spec[3],Model.depths[spec[1]],{spec[4],spec[5]},cloudImage,cloudRect)
   local g=Instance.new("UIGradient");g.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.23,.15),NumberSequenceKeypoint.new(.7,.15),NumberSequenceKeypoint.new(1,1)});g.Parent=c.label
  end
  for i,b in ipairs(Data.branches)do
   local mesh=pool.get("mesh"..i,function()return Asset:CreateEditableMesh()end)
   local ids,normals={},{}
   for j,p in ipairs(b.vertices)do ids[j]=mesh:AddVertex(Vector3.new(table.unpack(p)));normals[j]=mesh:AddNormal(Vector3.new(table.unpack(b.normals[j])))end
   for _,tri in ipairs(b.triangles)do
    local face=mesh:AddTriangle(ids[tri[1]+1],ids[tri[2]+1],ids[tri[3]+1])
    mesh:SetFaceNormals(face,{normals[tri[1]+1],normals[tri[2]+1],normals[tri[3]+1]})
   end
   local p=Asset:CreateMeshPartAsync(Content.fromObject(mesh),{CollisionFidelity=Enum.CollisionFidelity.Box,RenderFidelity=Enum.RenderFidelity.Precise})
   if self.destroyed or not parent.Parent or not folder.Parent then p:Destroy();error("R4 owner disposed during mesh creation")end
   p.Parent=folder;table.insert(limbs,p)
   -- Branch-local vertices are already centered. +Z faces the island.
   p.Name=b.name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Transparency=1
   p.Material=Enum.Material.Wood;p.CFrame=CFrame.fromMatrix(treeCenter+right*b.center[1]+up*b.center[2]-away*b.center[3],right,up,-away)
  end
  self.ready=true
 end)
 if not ok then self.error=tostring(err);self.destroy();warn("SKY_DEPTH_FALLBACK",err)end
 function self.update(current,quality,mode,oceanEnabled)
  if not self.ready then return false end
  local started=os.clock();local active=Model.mode(mode,quality,self.ready)=="R4";self.mode=active and "R4" or "R3"
  if currentMode~=self.mode then
   for _,g in pairs(groups)do g.gui.Enabled=active end
   for _,p in ipairs(limbs)do p.Transparency=active and 0 or 1 end
   currentMode=self.mode
  end
  if active then
   local light=Model.lighting(current,quality)
   for _,name in ipairs({"rear","middle","front"})do
    local l=groups[name].label;l.ImageColor3=Color3.new(table.unpack(light[name]))
    l.ImageTransparency=1-math.clamp(current.tree*(1-Config.tree.atmosphericFade),0,1)
   end
   self.accent.ImageColor3=Color3.new(table.unpack(light.color));self.accent.ImageTransparency=1-light.accent
   self.directional.Rotation=light.accentRotation
   for _,p in ipairs(limbs)do p.Color=Color3.new(table.unpack(light.bark))end
   for _,name in ipairs({"cloudBack","cloudFront"})do
    groups[name].gui.Enabled=oceanEnabled
    groups[name].label.ImageColor3=Color3.new(table.unpack(current.cloudColor))
    groups[name].label.ImageTransparency=1-current.cloud*(name=="cloudBack" and .20 or .38)*(quality=="reduced" and .8 or 1)
   end
  end
  self.updates+=1;self.lastMs=(os.clock()-started)*1000;return active
 end
 function self.stats()
  return {ready=self.ready,destroyed=self.destroyed,error=self.error,mode=self.mode,images=self.ready and 1 or 0,
   meshResources=self.ready and #Data.branches or 0,vertices=Data.vertices,triangles=Data.triangles,
   pixelBytes=self.ready and Model.textureBytes or 0,pixelWrites=self.pixelWrites,
   instances=folder and #folder:GetDescendants()+1 or 0,lastMs=self.lastMs,updates=self.updates,
   anchors=anchors,renderConnections=0,positionWritesPerUpdate=0,cloudLayers=2}
 end
 return self
end
return M
