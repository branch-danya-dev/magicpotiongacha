--!nocheck
-- Optional F5 Client QA. Not mapped into the game. Set manual graphics 5 first.
local q=assert(_G.AG70QA);local Run=game:GetService("RunService");assert(Run:IsStudio() and Run:IsClient())
local Http=game:GetService("HttpService");local L=game:GetService("Lighting")
if _G.AG70CaptureConnection then _G.AG70CaptureConnection:Disconnect() end
local index,busy=0,false
local function ready(name)
 q.status(name);local c=workspace.CurrentCamera
 print("AG70 CAPTURE_READY "..Http:JSONEncode({name=name,index=index+200,camera="near",cframe={c.CFrame:GetComponents()},
 fov=c.FieldOfView,viewport={c.ViewportSize.X,c.ViewportSize.Y},graphics=tostring(settings().Rendering.QualityLevel)}))
end
_G.AG70CaptureConnection=game:GetService("UserInputService").InputBegan:Connect(function(input,processed)
 if processed or busy then return end
 if input.KeyCode==Enum.KeyCode.F8 then
  index+=1;busy=true
  task.spawn(function()
   q.look("AG70");q.camera("near");q.motion(true)
   if index<=3 then local tier=({"full","reduced","minimal"})[index];q.quality(tier);q.pose("night");task.wait(9);ready("graphics5-night-"..tier)
   elseif index<=5 then
    local soft=index==4;local ok,err=pcall(function()L.LightingStyle=soft and Enum.LightingStyle.Soft or Enum.LightingStyle.Realistic;L.PrioritizeLightingQuality=not soft end)
    print("AG70 STYLE_SET "..Http:JSONEncode({soft=soft,ok=ok,error=ok and "" or tostring(err)}))
    q.quality("reduced");q.pose("day");task.wait(9);ready(soft and "graphics5-soft-day" or "graphics5-realistic-day")
   end
   busy=false
  end)
 elseif input.KeyCode==Enum.KeyCode.F6 then
  -- Start native recording BEFORE F6. Live OFF -> AG70 -> OFF; no edits.
  q.look("OFF");print("AG70 VIDEO_COMPARE_START OFF")
  task.delay(6,function()q.look("AG70");print("AG70 VIDEO_COMPARE_AG70")end)
  task.delay(13,function()q.look("OFF");print("AG70 VIDEO_COMPARE_OFF")end)
  task.delay(21,function()print("AG70 VIDEO_COMPARE_DONE")end)
 elseif input.KeyCode==Enum.KeyCode.Y then
  busy=true
  task.spawn(function()
   q.motion(false);q.quality("reduced");q.look("AG70");q.pose("day")
   local character=game.Players.LocalPlayer.Character;local h=character:FindFirstChildOfClass("Humanoid")
   local p=workspace.PotionTycoonWorld.Plot_1.crystal.Position
   workspace.CurrentCamera.CameraType=Enum.CameraType.Custom;workspace.CurrentCamera.CameraSubject=h
   print("AG70 VIDEO_WALK_START")
   h:MoveTo(p+Vector3.new(14,0,-8));task.wait(5)
   h:MoveTo(p+Vector3.new(24,0,-12));task.wait(5)
   q.pose("night");task.wait(8)
   h:MoveTo(p+Vector3.new(6,0,-14));task.wait(5)
   h:MoveTo(p+Vector3.new(0,0,6));task.wait(5)
   print("AG70 VIDEO_WALK_DONE");busy=false
  end)
 end
end)
