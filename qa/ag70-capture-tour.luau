--!nocheck
-- Optional native capture tour, installed AFTER ag70-command-bar in F5 Client.
-- F8 advances one settled comparison. No GUI hiding, asset replacement or filters.
local q=assert(_G.AG70QA)
local Http=game:GetService("HttpService")
local Run=game:GetService("RunService")
assert(Run:IsStudio() and Run:IsClient())
if _G.AG70CaptureConnection then _G.AG70CaptureConnection:Disconnect() end
local shots={}
for _,pose in ipairs({"day","sunset","night","rain"}) do
 for _,quality in ipairs({"reduced","full"}) do
  for _,camera in ipairs({"near","wide"}) do
   for _,look in ipairs({"OFF","AG70"}) do table.insert(shots,{pose=pose,quality=quality,camera=camera,look=look}) end
  end
 end
end
local index,busy,previous=0,false,nil
local function nextShot()
 if busy then return end
 index+=1;local s=shots[index]
 if not s then print("AG70 CAPTURE_DONE true");return end
 busy=true
 task.spawn(function()
  q.pose(s.pose);q.quality(s.quality);q.motion(true);q.look(s.look);q.camera(s.camera)
  -- Reduce Motion stabilizes grass and local VFX for BOTH halves. Rain identity
  -- remains cloud/light/haze here; separate moving rain capture shows droplets.
  task.wait((not previous or previous.pose~=s.pose) and 9 or previous.quality~=s.quality and 4 or 1)
  s.name=s.pose.."-"..s.quality.."-"..s.camera.."-"..s.look
  q.status(s.name)
  local c=workspace.CurrentCamera
  print("AG70 CAPTURE_READY "..Http:JSONEncode({name=s.name,index=index,pose=s.pose,look=s.look,quality=s.quality,reduceMotion=true,
   camera=s.camera,cframe={c.CFrame:GetComponents()},fov=c.FieldOfView,viewport={c.ViewportSize.X,c.ViewportSize.Y}}))
  previous=s;busy=false
 end)
end
_G.AG70CaptureConnection=game:GetService("UserInputService").InputBegan:Connect(function(input,processed)
 if not processed and input.KeyCode==Enum.KeyCode.F8 then nextShot() end
end)
print("AG70 CAPTURE_INSTRUCTIONS F8 advances; keep game viewport focused; capture only after CAPTURE_READY")
