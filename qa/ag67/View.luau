--!nonstrict
-- Stage A only: pooled local art. The production Rojo project never includes this folder.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local P=require(script.Parent.Policy)
local Shared=game.ReplicatedStorage.PotionTycoon.Shared
local Feedback=require(Shared.SpellbookFeedback)
local Controller=require(script.Parent.Parent.EnvironmentController)
local prefix="rbxasset://ag67-soul-v2/"
local cyan=Color3.fromRGB(109,224,255)
local violet=Color3.fromRGB(172,125,255)
local white=Color3.fromRGB(228,247,255)
local ember=Color3.fromRGB(255,140,53)
local View={}

local function part(parent,name,size)
 local v=Instance.new("Part");v.Name=name;v.Size=size;v.Transparency=1
 v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false;v.CastShadow=false;v.Parent=parent
 return v
end
local function surface(parent,face)
 local v=Instance.new("SurfaceGui");v.Face=face;v.CanvasSize=Vector2.new(512,512)
 v.LightInfluence=0;v.Brightness=1.7;v.AlwaysOnTop=false;v.Parent=parent;return v
end
local function image(parent,texture,color)
 local v=Instance.new("ImageLabel");v.BackgroundTransparency=1;v.Size=UDim2.fromScale(1,1)
 v.Image=prefix..texture..".png";v.ImageColor3=color;v.ImageTransparency=1;v.Parent=parent;return v
end
local function glyph(parent,i)
 local v=part(parent,"OrbitRune"..i,Vector3.new(1.45,1.85,.015))
 return {part=v,images={image(surface(v,Enum.NormalId.Front),"glyph"..(i%4),cyan),image(surface(v,Enum.NormalId.Back),"glyph"..(i%4),cyan)}}
end
local function emitter(parent,name,color)
 local e=Instance.new("ParticleEmitter");e.Name=name;e.Enabled=false;e.Rate=0
 e.Texture="rbxasset://textures/particles/sparkles_main.dds";e.Color=ColorSequence.new(color,white)
 e.LightEmission=.75;e.LightInfluence=0;e.Lifetime=NumberRange.new(.3,.55);e.Speed=NumberRange.new(.4,1.2)
 e.SpreadAngle=Vector2.new(70,70);e.Drag=2;e.Acceleration=Vector3.new(0,.5,0)
 e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.12),NumberSequenceKeypoint.new(.4,.06),NumberSequenceKeypoint.new(1,0)})
 e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.15),NumberSequenceKeypoint.new(.6,.45),NumberSequenceKeypoint.new(1,1)})
 e.Parent=parent;return e
end
local function valid(model)
 local back=model:FindFirstChild("LecternAnchor");local anchor=back and back.Value
 local link=anchor and anchor:FindFirstChild("SpellbookVisual")
 return model:IsDescendantOf(workspace) and model:GetAttribute("SpellbookLoadState")=="ready"
  and anchor and anchor.Parent==model.Parent and link and link.Value==model
end

function View.start()
 assert(RunService:IsStudio(),"AG67 art preview is Studio-only")
 local player=Players.LocalPlayer
 local records,tracked={},{}
 local time,elapsed,signature=0,0,""
 local config=P.quality(Controller.quality,Controller.reduceMotion)
 local ritual=P.new();local ritualBook,cursor,connection,stateConnection
 local folder=Instance.new("Folder");folder.Name="AG67LocalArtPreview";folder.Parent=workspace
 local stats={updates=0,totalMs=0,maxMs=0,errors=0,emitted=0,peakPages=0}
 local pool={pages={},streams={},emitters={}}
 local function hideRitual()
  for _,page in ipairs(pool.pages) do for _,panel in ipairs(page.panels) do
   for _,im in ipairs(panel.images) do im.ImageTransparency=1 end
   for _,im in ipairs(panel.edges) do im.ImageTransparency=1 end
  end end
  for _,s in ipairs(pool.streams) do for _,b in ipairs(s.beams) do b.Enabled=false end end
  for _,e in ipairs(pool.emitters) do e:Clear() end
  if pool.light then pool.light.Brightness=0 end
 end
 local function cancel()
  ritual.cancel();ritualBook=nil;hideRitual()
 end
 local function clearPool()
  cancel();if pool.root then pool.root:Destroy() end
  pool={pages={},streams={},emitters={}}
 end
 local function buildPool()
  clearPool()
  pool.root=Instance.new("Folder");pool.root.Name="RitualPool";pool.root.Parent=folder
  pool.carrier=part(pool.root,"BeamCarrier",Vector3.new(.05,.05,.05))
  for i=1,config.pages do
   local page={panels={}}
   for side=0,1 do
    local v=part(pool.root,"FoldedPage"..i.."_"..side,Vector3.new(.38,.88,.01))
    local images,edges={},{}
    for _,face in ipairs({Enum.NormalId.Front,Enum.NormalId.Back}) do
     local gui=surface(v,face);gui.Brightness=1.1
     local im=image(gui,"page",white);im.ImageRectOffset=Vector2.new(side*128,0);im.ImageRectSize=Vector2.new(128,256)
     local edge=image(gui,"page-edge",ember);edge.ImageRectOffset=im.ImageRectOffset;edge.ImageRectSize=im.ImageRectSize;edge.ZIndex=2
     table.insert(edges,edge)
     table.insert(images,im)
    end
    table.insert(page.panels,{part=v,images=images,edges=edges,side=side})
   end
   table.insert(pool.pages,page)
  end
  for i=1,config.streams do
   local s={nodes={},beams={}}
   for j=1,4 do local a=Instance.new("Attachment");a.Name="Soul"..i.."Node"..j;a.Parent=pool.carrier;table.insert(s.nodes,a) end
   for j=1,3 do for layer=1,2 do
    local b=Instance.new("Beam");b.Name=layer==1 and "SoulHalo" or "SoulCore"
    b.Attachment0=s.nodes[j];b.Attachment1=s.nodes[j+1];b.Segments=8;b.FaceCamera=true
    b.Color=ColorSequence.new(layer==1 and (i%2==0 and violet or cyan) or white)
    b.LightEmission=1;b.LightInfluence=0;b.Width0=layer==1 and .23 or .055;b.Width1=b.Width0*.65
    b.Enabled=false;b.Parent=pool.carrier;table.insert(s.beams,b)
   end end
   table.insert(pool.streams,s)
  end
  pool.book=Instance.new("Attachment");pool.book.Parent=pool.carrier
  pool.ash=Instance.new("Attachment");pool.ash.Parent=pool.carrier
  pool.chest=Instance.new("Attachment");pool.chest.Parent=pool.carrier
  for i,a in ipairs({pool.book,pool.ash,pool.chest}) do table.insert(pool.emitters,emitter(a,"BoundedSparks"..i,i==2 and ember or cyan)) end
  if config.light then
   pool.light=Instance.new("PointLight");pool.light.Name="AG67LocalLight";pool.light.Shadows=false;pool.light.Range=7
   pool.light.Color=cyan;pool.light.Brightness=0;pool.light.Parent=pool.book
  end
 end
 local function remove(model)
  local r=records[model];if not r then return end
  if ritualBook==model then cancel() end
  for _,entry in ipairs(r.hidden) do if entry.part.Parent then entry.part.LocalTransparencyModifier=entry.alpha end end
  for _,entry in ipairs(r.pages) do if entry.part.Parent then entry.part.CFrame=entry.frame end end
  r.root:Destroy();records[model]=nil
 end
 local function add(model)
  local source=model:FindFirstChild("SpellbookLectern")
  local cover=source and source:FindFirstChild("Spellbook") and source.Spellbook:FindFirstChild("Cover")
  local energy=cover and cover:FindFirstChild("EnergyPoint")
  if not energy then return end
  local root=Instance.new("Folder");root.Name="SigilAndRunes";root.Parent=folder
  local r={root=root,energy=energy,hidden={},pages={},runes={},sectors={},phase=0,boost=0}
  records[model]=r -- own partial allocations before setup
  for _,v in ipairs(source:GetDescendants()) do if v:IsA("MeshPart") then
   if v.Name=="Rune0.001" or v.Name=="RingOuter" then table.insert(r.hidden,{part=v,alpha=v.LocalTransparencyModifier});v.LocalTransparencyModifier=1 end
   if v.Parent.Name=="LoosePages" then table.insert(r.pages,{part=v,frame=v.CFrame}) end
  end end
  r.plane=part(root,"SoulAbsorptionSigil",Vector3.new(10.5,.015,10.5))
  -- Clear the existing grass/road overlay at the lectern's floor pivot.
  r.plane.CFrame=CFrame.new(model:GetPivot().Position+Vector3.new(0,.32,0))
  local gui=surface(r.plane,Enum.NormalId.Top)
  for i=1,6 do local im=image(gui,"sector",cyan);im.Rotation=(i-1)*60;table.insert(r.sectors,im) end
  r.inner=image(gui,"inner",violet);r.channels=image(gui,"channels",cyan)
  for i=1,config.runes do table.insert(r.runes,glyph(root,i)) end
 end
 local function characterChest()
  local character=player.Character
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  local chest=P.chest(character)
  if not humanoid or humanoid.Health<=0 or not chest or not chest:IsDescendantOf(workspace) then return nil end
  return chest
 end
 local function ritualStep(now)
  if not ritualBook or not ritual.started then return end
  local r=records[ritualBook];local chest=characterChest()
  if not r or not chest or not valid(ritualBook) or ritualBook.Parent:GetAttribute("OwnerUserId")~=player.UserId then cancel();return end
  local age=now-ritual.started
  if age>=P.seconds then cancel();return end
  local origin=r.energy.WorldPosition;local target=chest.Position
  pool.book.WorldPosition=origin;pool.chest.WorldPosition=target;pool.ash.WorldPosition=origin+Vector3.new(0,1.2,0)
  local flash=P.flash(now,ritual.lastPulse)
  if pool.light then
   local absorb=config.calm and 0 or P.flash(age,1.03)
   pool.light.Brightness=.16*P.envelope(age)+flash*(config.calm and .28 or .8)+absorb*.9
   pool.light.Parent=(age<.8 or config.calm) and pool.book or pool.chest
  end
  for i,page in ipairs(pool.pages) do
   local s=P.page(age,i,#pool.pages,false)
   local amplitude=Controller.quality=="minimal" and .55 or 1
   local cf=CFrame.new(origin+Vector3.new(s.x,s.y,s.z)*amplitude)*CFrame.Angles(s.pitch,s.yaw,s.roll)
   local color=Color3.fromRGB(255,242,214):Lerp(ember,math.sin(s.burn*math.pi)*.85):Lerp(Color3.fromRGB(42,23,52),P.smooth((s.burn-.5)*2))
   for _,panel in ipairs(page.panels) do
    local sign=panel.side==0 and -1 or 1
    panel.part.Size=Vector3.new(.38,.88,.01)*s.scale
    panel.part.CFrame=cf*CFrame.Angles(0,sign*s.fold,0)*CFrame.new(sign*.19*s.scale,0,0)
    for _,im in ipairs(panel.images) do im.ImageTransparency=1-s.alpha;im.ImageColor3=color end
    for _,im in ipairs(panel.edges) do
     im.ImageTransparency=1-s.alpha*math.sin(s.burn*math.pi)*(.8+.2*math.sin(age*9+i))
     im.ImageColor3=ember:Lerp(violet,(i%3)/3)
    end
   end
  end
  for i,s in ipairs(pool.streams) do
   local head=(age-.2-(i-1)*.07)/.85
   local opacity=P.smooth(head/.15)*(1-P.smooth((head-1)/.18))
   local points={}
   for j=1,4 do
    local u=math.clamp(head-(4-j)*.085,0,1);local p=P.soul(u,i)
    points[j]=origin:Lerp(target,p.blend)+Vector3.new(p.x,p.y,p.z)
   end
   for j=1,4 do
    local tangent=points[math.min(4,j+1)]-points[math.max(1,j-1)]
    local x=tangent.Magnitude>.001 and tangent.Unit or Vector3.xAxis
    local z=x:Cross(math.abs(x.Y)<.95 and Vector3.yAxis or Vector3.zAxis).Unit
    s.nodes[j].WorldCFrame=CFrame.fromMatrix(points[j],x,z:Cross(x),z)
   end
   for k,b in ipairs(s.beams) do
    local j=math.ceil(k/2);local length=(points[j+1]-points[j]).Magnitude
    b.Enabled=opacity>.01 and length>.003;b.CurveSize0=length/3;b.CurveSize1=length/3
    b.Transparency=NumberSequence.new(1-opacity*(k%2==1 and .5 or .9))
   end
  end
  if age>.55 and not pool.burned then pool.burned=true;local n=math.floor(config.sparks*.5);pool.emitters[2]:Emit(n);stats.emitted+=n end
  if age>1.03 and not pool.absorbed then pool.absorbed=true;local n=math.floor(config.sparks*.5);pool.emitters[3]:Emit(n);stats.emitted+=n end
 end
 local self={}
 function self.attach(model)
  if tracked[model] then return end
  local n=0;for _ in pairs(tracked) do n+=1 end
  if n<8 then tracked[model]=true end
 end
 function self.detach(model) tracked[model]=nil;remove(model) end
 function self.stats()
  local books,count=0,0;for _ in pairs(records) do books+=1 end;for _ in pairs(tracked) do count+=1 end
  return {mode="prototype",tracked=count,active=books,sheets=#pool.pages,beams=#pool.streams*6,runes=books*config.runes,
   lights=pool.light and 1 or 0,emitters=#pool.emitters,instances=#folder:GetDescendants(),feedback=ritual.confirmed,batches=ritual.batches,
   activeRitual=ritual.started~=nil,emitted=stats.emitted,errors=stats.errors,updates=stats.updates,
   averageMs=stats.totalMs/math.max(1,stats.updates),maxMs=stats.maxMs,connections=2}
 end
 function self.stop()
  if connection then connection:Disconnect() end;if stateConnection then stateConnection:Disconnect() end
  clearPool();for model in pairs(records) do remove(model) end;table.clear(tracked);folder:Destroy()
 end
 stateConnection=game.ReplicatedStorage.PotionTycoon.Remotes.State.OnClientEvent:Connect(function(snapshot)
  local owned=player:GetAttribute("PotionPlotIndex");local confirmed
  cursor,confirmed=Feedback.consume(cursor,snapshot.presentation and snapshot.presentation.essenceClick,owned)
  if not confirmed or snapshot.writable~=true then return end
  for model,r in pairs(records) do
   if valid(model) and model:GetAttribute("PlotIndex")==owned and model.Parent:GetAttribute("OwnerUserId")==player.UserId and characterChest() then
    local fresh=ritual.trigger(time);ritualBook=model;r.pulse=time
    if fresh then pool.burned=false;pool.absorbed=false;hideRitual() end
    model:SetAttribute("AG67ConfirmedFeedback",ritual.confirmed);break
   end
  end
 end)
 connection=RunService.Heartbeat:Connect(function(dt)
  time+=dt;elapsed+=dt
  local nextSignature=Controller.quality..tostring(Controller.reduceMotion)
  if signature~=nextSignature then
   signature=nextSignature;config=P.quality(Controller.quality,Controller.reduceMotion)
   for model in pairs(records) do remove(model) end;buildPool();elapsed=1
  end
  if elapsed<1/config.hz then return end
  local step=math.min(elapsed,.1);elapsed=0;local started=os.clock()
  local ok,err=pcall(function()
   local camera=workspace.CurrentCamera;local candidates={}
   for model in pairs(tracked) do
    if valid(model) and camera then
     local d=(camera.CFrame.Position-model:GetPivot().Position).Magnitude
     if d<=config.range then table.insert(candidates,{model=model,d=d,owned=model.Parent:GetAttribute("OwnerUserId")==player.UserId}) end
    else remove(model) end
   end
   table.sort(candidates,function(a,b) if a.owned~=b.owned then return a.owned end;return a.d<b.d end)
   local active={};for i=1,math.min(config.books,#candidates) do active[candidates[i].model]=true end
   for model in pairs(records) do if not active[model] then remove(model) end end
   for model in pairs(active) do
    if not records[model] then add(model) end
    local r=records[model];if not r then continue end
    local flash=P.flash(time,r.pulse);r.boost+=(flash*1.7-r.boost)*math.min(1,step*5);r.phase+=r.boost*step
    for i,im in ipairs(r.sectors) do
     local wave=r.pulse and P.flash(time,r.pulse+(i-1)*.065) or 0
     im.ImageTransparency=.35-wave*.32;im.ImageColor3=cyan:Lerp(white,wave*.8)
     im.Rotation=(i-1)*60+(config.motion and time*1.7 or 0)
    end
    r.inner.Rotation=config.motion and -time*3.1 or 0;r.inner.ImageTransparency=.3-flash*.25
    r.channels.Rotation=config.motion and time*.9 or 0;r.channels.ImageTransparency=.3-flash*.25
    for i,g in ipairs(r.runes) do
     local s=P.rune(time,i,config.motion,r.phase)
     g.part.CFrame=CFrame.new(r.energy.WorldPosition+Vector3.new(s.x,s.y,s.z))*CFrame.Angles(0,s.yaw,s.roll)
     for _,im in ipairs(g.images) do im.ImageTransparency=1-s.glow;im.ImageColor3=(i%2==0 and cyan or violet):Lerp(white,flash*.7) end
    end
    for i,entry in ipairs(r.pages) do entry.part.CFrame=entry.frame*(config.motion and CFrame.new(0,math.sin(time*.8+i)*.10,0)*CFrame.Angles(0,0,math.sin(time*.63+i)*.04) or CFrame.identity) end
   end
   ritualStep(time)
  end)
  if not ok then stats.errors+=1;warn("[AG67 preview] removed failed art: "..tostring(err));clearPool();for model in pairs(records) do remove(model) end;table.clear(tracked) end
  local ms=(os.clock()-started)*1000;stats.updates+=1;stats.totalMs+=ms;stats.maxMs=math.max(stats.maxMs,ms)
 end)
 return self
end
return View
