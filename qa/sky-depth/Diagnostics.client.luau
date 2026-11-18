--!nonstrict
-- Bounded opt-in checks. No screenshots, camera writes, gameplay intents or saves.
local Run=game:GetService("RunService")
if not Run:IsStudio() or not workspace:GetAttribute("SkyLandmarkQA")then return end
local Controller=require(script.Parent.EnvironmentController)
local Http=game:GetService("HttpService")
local root=workspace:WaitForChild("PotionTycoonWorld")
local function emit(kind,value)print("SKY_DEPTH_"..kind,Http:JSONEncode(value))end
local function stats()return Controller.view and Controller.view.stats().skyLandmark end
local running=false
local function checks()
 if running then return false end;running=true
 local oldQuality,oldMotion,oldMode=Controller.quality,Controller.reduceMotion,workspace:GetAttribute("SkyTreeDepthMode")
 local pose=Controller.view.pose;local moon=Controller.view.stats().lunar.forced
 local ok,err=pcall(function()
  local initial=assert(stats());assert(initial.ready);assert(initial.depth.ready,initial.depth.error)
  local camera=workspace.CurrentCamera;assert(camera.CameraType==Enum.CameraType.Custom,"Choose a familiar normally first")
  local fov=camera.FieldOfView;local anchors=Http:JSONEncode(initial.depth.anchors)
  for i=1,20 do
   workspace:SetAttribute("SkyTreeDepthMode",i%2==0 and "R4" or "R3")
   Controller.setQuality(({"full","reduced","minimal"})[(i-1)%3+1]);Controller.setReduceMotion(i%2==0);task.wait(.35)
   local s=stats();assert(s.instances==71 and s.depth.instances==26 and s.images==4 and s.depth.images==1)
   assert(s.depth.meshResources==6 and s.depth.pixelWrites==1 and s.pixelWrites==4)
   assert(Http:JSONEncode(s.depth.anchors)==anchors,"World anchors moved")
   if Controller.quality=="minimal"then assert(s.depth.mode=="R3")end
  end
  local timings={};Controller.setReduceMotion(true)
  for _,q in ipairs({"full","reduced","minimal"})do
   timings[q]={};Controller.setQuality(q)
   for _,mode in ipairs({"R3","R4"})do
    workspace:SetAttribute("SkyTreeDepthMode",mode);task.wait(4)
    local frames,updates={},{};local last=-1
    for _=1,120 do
     table.insert(frames,Run.RenderStepped:Wait()*1000);local s=stats()
     if s.updates~=last then last=s.updates;table.insert(updates,s.lastMs)end
    end
    table.sort(frames);table.sort(updates)
    timings[q][mode]={frameMedianMs=frames[60],frameP95Ms=frames[114],updates=#updates,updateP95Ms=updates[math.max(1,math.ceil(#updates*.95))],totalClientMemoryMb=game:GetService("Stats"):GetTotalMemoryUsageMb(),landmark=stats()}
   end
  end
  for _,p in ipairs({"day","dusk","night"})do Controller.view.setPose(p);task.wait(9);emit("POSE",{pose=p,landmark=stats()})end
  for _,m in ipairs({"pearl","blood","frost"})do Controller.view.setMoon(m);task.wait(9);emit("MOON",{moon=m,landmark=stats()})end
  assert(camera.CameraType==Enum.CameraType.Custom and camera.FieldOfView==fov)
  emit("PASS",{timings=timings,visualGate="Not assessed by numeric checks; owner must inspect walking/parallax/occlusion",cameraUntouched=true})
 end)
 Controller.setQuality(oldQuality);Controller.setReduceMotion(oldMotion);workspace:SetAttribute("SkyTreeDepthMode",oldMode)
 Controller.view.setPose(pose);Controller.view.setMoon(moon or "auto")
 if not ok then emit("FAIL",{error=tostring(err)})end;running=false;return ok
end
local control=Instance.new("BindableFunction");control.Name="SkyLandmarkQA";control.Parent=root
control.OnInvoke=function(action,value)
 if action=="depth"then if value~="R3" and value~="R4"then return false end;workspace:SetAttribute("SkyTreeDepthMode",value);return true end
 if action=="pose"then Controller.view.setPose(value);return true end
 if action=="moon"then return Controller.view.setMoon(value)end
 if action=="quality"then Controller.setQuality(value);return true end
 if action=="motion"then Controller.setReduceMotion(value);return true end
 if action=="check"then task.spawn(checks);return true end
 return stats()
end
task.spawn(function()
 for _=1,600 do
  local s=stats();if s and s.ready then
   emit("READY",s)
   if workspace:GetAttribute("SkyDepthAutoCheck")then
    for _=1,600 do
     if workspace.CurrentCamera.CameraType==Enum.CameraType.Custom and root:GetAttribute("WillowV2Ready")then task.wait(3);checks();return end
     task.wait(.2)
    end
    emit("BLOCKED",{reason="Choose familiar normally to enable checks"})
   end
   return
  end;task.wait(.1)
 end;emit("BLOCKED",{reason="Renderer did not become ready",landmark=stats()})
end)
script.Destroying:Connect(function()control:Destroy()end)
