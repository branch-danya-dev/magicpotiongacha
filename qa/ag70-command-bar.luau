--!nocheck
-- Paste into ordinary F5 CLIENT Command Bar. Optional QA only; excluded from Rojo.
-- Uses the ACTUAL owner bridges, never a second require cache or Lighting writer.
local Run=game:GetService("RunService")
assert(Run:IsStudio() and Run:IsClient(),"Studio Play CLIENT only")
local L=game:GetService("Lighting")
local Http=game:GetService("HttpService")
local Stats=game:GetService("Stats")
local root=workspace.PotionTycoonWorld
local inspect=assert(workspace.M7ClientWeather.PostFXInspect)
local book=game.Players.LocalPlayer.PlayerScripts.PotionTycoon.SpellbookEffects.Inspect
local q={}
local function report(tag,value) print("AG70 "..tag.." "..Http:JSONEncode(value)) end
local function get(object,key)
 local ok,value=pcall(function() return object[key] end)
 if not ok then return "UNAVAILABLE" end
 if typeof(value)=="Color3" then return {value.R,value.G,value.B} end
 if typeof(value)=="EnumItem" then return tostring(value) end
 return value
end
local fields={
 Lighting={"ClockTime","Brightness","ExposureCompensation","Ambient","OutdoorAmbient","ColorShift_Top","ColorShift_Bottom","EnvironmentDiffuseScale","EnvironmentSpecularScale","ShadowSoftness","GlobalShadows","GeographicLatitude","LightingStyle","PrioritizeLightingQuality"},
 Atmosphere={"Color","Decay","Density","Haze","Glare","Offset"},
 ColorCorrectionEffect={"Enabled","Brightness","Contrast","Saturation","TintColor"},
 BloomEffect={"Enabled","Intensity","Size","Threshold"},SunRaysEffect={"Enabled","Intensity","Spread"},
 Clouds={"Enabled","Color","Cover","Density"},
 PointLight={"Enabled","Color","Brightness","Range","Shadows"},SpotLight={"Enabled","Color","Brightness","Range","Shadows"},
}
function q.snapshot()
 local result={};local instances={L}
 for _,v in ipairs(L:GetChildren()) do table.insert(instances,v) end
 for _,v in ipairs(workspace.Terrain:GetChildren()) do table.insert(instances,v) end
 for _,v in ipairs(workspace:GetDescendants()) do if v:IsA("Light") and (v.Name=="M7LocalLantern" or v.Name=="CanopySun") then table.insert(instances,v) end end
 for _,v in ipairs(instances) do if fields[v.ClassName] then
  local data={};for _,key in ipairs(fields[v.ClassName]) do data[key]=get(v,key) end
  result[v:IsA("Light") and v:GetFullName() or v.Name]=data
 end end
 return result
end
function q.status(label)
 local counts,quality,motion=inspect:Invoke()
 report("STATE",{label=label,art=root:GetAttribute("EnvironmentArtEnabled"),counts=counts,quality=quality,reduceMotion=motion,
  graphics=get(settings().Rendering,"QualityLevel"),gameId=game.GameId,placeId=game.PlaceId})
 for name,properties in pairs(q.snapshot()) do report("PROPERTIES",{label=label,object=name,properties=properties}) end
 report("BOOK",{label=label,counts=book:Invoke()})
end
function q.look(name)
 assert(name=="OFF" or name=="AG68" or name=="AG70" or name=="A" or name=="B" or name=="C")
 root:SetAttribute("EnvironmentReview","look:"..name)
end
function q.pose(name) root:SetAttribute("EnvironmentReview",name) end
function q.quality(name) book:Invoke("quality",name) end
function q.motion(enabled) book:Invoke("motion",enabled) end
function q.camera(name)
 local p=root.Plot_1.crystal.Position
 local positions={near=Vector3.new(13,9,21),wide=Vector3.new(23,14,31),reverse=Vector3.new(-15,10,-22)}
 local c=workspace.CurrentCamera;c.CameraType=Enum.CameraType.Scriptable
 c.CFrame=CFrame.lookAt(p+assert(positions[name]),p+Vector3.new(0,2,-7));c.FieldOfView=65
 report("CAMERA",{name=name,cframe={c.CFrame:GetComponents()},fov=c.FieldOfView,viewport={c.ViewportSize.X,c.ViewportSize.Y}})
end
function q.placeAvatar()
 -- Test positioning only. No remote, reward, entitlement or save is touched.
 game.Players.LocalPlayer.Character:PivotTo(CFrame.new(root.Plot_1.crystal.Position+Vector3.new(0,0,6)))
end
local function near(a,b)
 if type(a)~=type(b) then return false end
 if type(a)=="number" then return math.abs(a-b)<1e-6 end
 if type(a)~="table" then return a==b end
 for k,v in pairs(a) do if not near(v,b[k]) then return false end end
 for k in pairs(b) do if a[k]==nil then return false end end
 return true
end
function q.switch20(pose,quality,motion)
 q.pose(pose);q.quality(quality);q.motion(motion);q.look("OFF");task.wait(9)
 local before=q.snapshot();local refs=L:GetChildren();local terrainRefs=workspace.Terrain:GetChildren()
 local instances=#workspace:GetDescendants();local bookBefore=book:Invoke()
 for i=1,20 do q.look(i%2==1 and "AG70" or "OFF");task.wait(.12) end
 local after=q.snapshot();local same=#refs==#L:GetChildren() and #terrainRefs==#workspace.Terrain:GetChildren()
 for _,v in ipairs(refs) do if v.Parent~=L then same=false end end
 for _,v in ipairs(terrainRefs) do if v.Parent~=workspace.Terrain then same=false end end
 local counts,tier,reduce=inspect:Invoke();local bookAfter=book:Invoke()
 report("SWITCH20",{pose=pose,quality=tier,reduceMotion=reduce,restored=near(before,after),sameInstances=same,
  countBefore=instances,countAfter=#workspace:GetDescendants(),look=counts.postFXLook,
  bookInstancesBefore=bookBefore.instances,bookInstancesAfter=bookAfter.instances,bookErrors=bookAfter.errors,
  lights=counts.lights,rain=counts.rain,motes=counts.motes,bloom=L.M7Bloom.Intensity,rays=L.M7SunRays.Intensity})
end
function q.matrix()
 task.spawn(function()
  q.switch20("day","reduced",false);q.switch20("sunset","full",false)
  q.switch20("night","minimal",true);q.switch20("rain","reduced",true)
  q.motion(false);q.quality("reduced");q.look("AG70");report("MATRIX_DONE",true)
 end)
end
function q.measure(name,seconds,rep)
 q.look(name);task.wait(3)
 local values={frame={},cpu={},gpu={},draws={},triangles={},memory={}}
 local properties={cpu="RenderCPUFrameTime",gpu="RenderGPUFrameTime",draws="SceneDrawcallCount",triangles="SceneTriangleCount"}
 local start=os.clock()
 while os.clock()-start<(seconds or 5) do
  table.insert(values.frame,Run.RenderStepped:Wait()*1000)
  for key,property in pairs(properties) do
   local value=get(Stats,property)
   if type(value)=="number" then table.insert(values[key],value*((key=="cpu" or key=="gpu") and 1000 or 1)) end
  end
  local ok,memory=pcall(function() return Stats:GetTotalMemoryUsageMb() end)
  if ok then table.insert(values.memory,memory) end
 end
 local counts,quality,motion=inspect:Invoke()
 local result={look=name,quality=quality,reduceMotion=motion,rep=rep,seconds=os.clock()-start,samples=#values.frame,
  lights=counts.lights,effects=#L:GetChildren(),graphics=get(settings().Rendering,"QualityLevel")}
 for key,list in pairs(values) do table.sort(list)
  result[key]=#list>0 and {median=list[math.ceil(#list*.5)],p95=list[math.ceil(#list*.95)]} or "UNAVAILABLE"
 end
 report("PERF",result)
end
function q.benchmark()
 task.spawn(function()
  q.pose("day");q.camera("near");q.motion(false);task.wait(9)
  for _,tier in ipairs({"full","reduced","minimal"}) do
   q.quality(tier);task.wait(4)
   for rep=1,2 do for _,look in ipairs(rep==1 and {"OFF","AG70"} or {"AG70","OFF"}) do q.measure(look,5,rep) end end
  end
  q.quality("reduced");q.look("AG70");report("BENCHMARK_DONE",true)
 end)
end
_G.AG70QA=q
q.status("automatic-start")
