--!nocheck
-- Optional Client Command Bar after ag68-command-bar. F8 advances.
-- Pause after index 108 and enable landscape device emulation before 109.
local q=assert(_G.AG68QA)
assert(game:GetService("RunService"):IsStudio())
if _G.AG68CaptureConnection then _G.AG68CaptureConnection:Disconnect() end
local shots={}
for _,category in ipairs({"reverse","minimal","mobile"}) do
 for _,pose in ipairs({"day","night"}) do
  for _,look in ipairs({"OFF","AG68"}) do
   table.insert(shots,{category=category,pose=pose,look=look,
    camera=category=="reverse" and "reverse" or "near",
    quality=category=="minimal" and "minimal" or "reduced"})
  end
 end
end
local index,busy=0,false
_G.AG68CaptureConnection=game:GetService("UserInputService").InputBegan:Connect(function(input,processed)
 if processed or input.KeyCode~=Enum.KeyCode.F8 or busy then return end
 index+=1;local s=shots[index];if not s then return end;busy=true
 task.spawn(function()
  q.pose(s.pose);q.quality(s.quality);q.motion(true);q.look(s.look);q.camera(s.camera)
  task.wait(s.look=="OFF" and 9 or 1)
  local name=s.category.."-"..s.pose.."-"..s.look;q.status(name)
  local c=workspace.CurrentCamera
  print("AG68 CAPTURE_READY "..game:GetService("HttpService"):JSONEncode({name=name,index=index+100,
   pose=s.pose,look=s.look,quality=s.quality,reduceMotion=true,camera=s.camera,
   cframe={c.CFrame:GetComponents()},fov=c.FieldOfView,viewport={c.ViewportSize.X,c.ViewportSize.Y},
   graphics=tostring(settings().Rendering.QualityLevel)}))
  busy=false
 end)
end)
