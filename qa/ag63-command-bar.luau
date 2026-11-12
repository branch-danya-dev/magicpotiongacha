--!nocheck
-- Optional native Studio CLIENT Command Bar helper. Not included in either Rojo tree.
-- Ordinary Play must already be running. No server calls, rewards, release flags or assets.
local RunService=game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient(),"Use Studio Play CLIENT Command Bar")
local Lighting=game:GetService("Lighting")
local Stats=game:GetService("Stats")
local Http=game:GetService("HttpService")
local root=workspace:WaitForChild("PotionTycoonWorld")
local inspect=root:FindFirstChild("PostFXInspect")
assert(inspect,"Existing EnvironmentView must be running; do not enable a release flag")
local q={}
local function report(label,value) print("AG63 "..label.." "..Http:JSONEncode(value)) end
function q.status()
 local counts,quality,motion=inspect:Invoke()
 local book=game.Players.LocalPlayer.PlayerScripts.PotionTycoon.SpellbookEffects.Inspect
 local spellbook=book:Invoke()
 report("STATUS",{counts=counts,quality=quality,reduceMotion=motion,spellbook=spellbook})
 return counts,quality,motion
end
function q.look(name)
 assert(name=="OFF" or name=="A" or name=="B" or name=="C")
 root:SetAttribute("EnvironmentReview","look:"..name)
end
function q.pose(name) root:SetAttribute("EnvironmentReview",name) end -- allow 8 sec to settle
function q.camera()
 local p=root.Plot_1.crystal.Position
 local camera=workspace.CurrentCamera
 camera.CameraType=Enum.CameraType.Scriptable
 camera.CFrame=CFrame.lookAt(p+Vector3.new(13,9,21),p+Vector3.new(0,2,-7))
 camera.FieldOfView=65
 workspace:SetAttribute("UIFoundationDemo",false)
 report("CAMERA",{cframe={camera.CFrame:GetComponents()},fov=camera.FieldOfView,viewport={camera.ViewportSize.X,camera.ViewportSize.Y}})
end
local properties={
 Lighting={"ClockTime","Brightness","Ambient","OutdoorAmbient","GlobalShadows","ExposureCompensation","GeographicLatitude","ColorShift_Top","ColorShift_Bottom","EnvironmentDiffuseScale","EnvironmentSpecularScale","ShadowSoftness"},
 Atmosphere={"Color","Decay","Density","Haze","Glare","Offset"},
 ColorCorrectionEffect={"Enabled","TintColor","Saturation","Contrast","Brightness"},
 BloomEffect={"Enabled","Intensity","Size","Threshold"},
 SunRaysEffect={"Enabled","Intensity","Spread"},
 Clouds={"Enabled","Cover","Density","Color"},
 Sky={"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp","StarCount","CelestialBodiesShown"},
}
function q.snapshot()
 local result={}; local instances={Lighting}
 for _,v in ipairs(Lighting:GetDescendants()) do table.insert(instances,v) end
 for _,v in ipairs(workspace.Terrain:GetChildren()) do table.insert(instances,v) end
 for _,v in ipairs(instances) do
  if properties[v.ClassName] then
   local data={}
   for _,property in ipairs(properties[v.ClassName]) do
    local value=v[property]
    data[property]=typeof(value)=="Color3" and {value.R,value.G,value.B} or value
   end
   result[v:GetFullName()]=data
  end
 end
 return result
end
local function near(a,b)
 if type(a)~=type(b) then return false end
 if type(a)=="number" then return math.abs(a-b)<1e-6 end
 if type(a)~="table" then return a==b end
 for k,v in pairs(a) do if not near(v,b[k]) then return false end end
 for k in pairs(b) do if a[k]==nil then return false end end
 return true
end
function q.switchTest()
 task.spawn(function()
  q.look("OFF"); task.wait(2)
  local before=q.snapshot(); local refs=Lighting:GetDescendants()
  local beforeCount=#refs; local firstQuality,firstMotion
  local _,quality,motion=inspect:Invoke(); firstQuality=quality; firstMotion=motion
  for i=1,20 do q.look(({"A","B","C","OFF"})[(i-1)%4+1]); task.wait(.15) end
  task.wait(.2)
  local after=q.snapshot(); local counts,qualityAfter,motionAfter=inspect:Invoke()
  local sameRefs=true
  for _,v in ipairs(refs) do if not v:IsDescendantOf(Lighting) then sameRefs=false end end
  report("SWITCH20",{restored=near(before,after),sameInstances=sameRefs and #Lighting:GetDescendants()==beforeCount,
   beforeCount=beforeCount,afterCount=#Lighting:GetDescendants(),look=counts.postFXLook,
   qualityUnchanged=qualityAfter==firstQuality,motionUnchanged=motionAfter==firstMotion})
 end)
end
function q.measure(name,seconds)
 task.spawn(function()
  q.look(name); task.wait(2)
  local values={frame={},cpu={},gpu={},drawcalls={},triangles={}}
  local fields={cpu="RenderCPUFrameTime",gpu="RenderGPUFrameTime",drawcalls="SceneDrawcallCount",triangles="SceneTriangleCount"}
  local start=os.clock()
  while os.clock()-start<(seconds or 5) do
   local dt=RunService.RenderStepped:Wait(); table.insert(values.frame,dt*1000)
   for key,property in pairs(fields) do
    local ok,value=pcall(function() return Stats[property] end)
    if ok and type(value)=="number" then table.insert(values[key],value*((key=="cpu" or key=="gpu") and 1000 or 1)) end
   end
  end
  local result={look=name,seconds=os.clock()-start,samples=#values.frame}
  for key,list in pairs(values) do
   table.sort(list)
   if #list>0 then result[key]={median=list[math.ceil(#list*.5)],p95=list[math.ceil(#list*.95)]} end
  end
  local _,quality,motion=inspect:Invoke(); result.quality=quality; result.reduceMotion=motion
  result.fpsMedian=1000/result.frame.median
  report("METRICS",result)
 end)
end
_G.AG63QA=q
q.status()
