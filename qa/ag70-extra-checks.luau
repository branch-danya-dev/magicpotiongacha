--!nocheck
-- Optional F5 CLIENT checks, excluded from Rojo. No gameplay intents or grants.
local q=assert(_G.AG70QA)
local Http=game:GetService("HttpService")
local root=workspace.PotionTycoonWorld
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient())
if _G.AG70RewardConnection then _G.AG70RewardConnection:Disconnect() end
local essence
_G.AG70RewardConnection=game.ReplicatedStorage.PotionTycoon.Remotes.State.OnClientEvent:Connect(function(s)
 if essence~=s.essence then
  print("AG70 ESSENCE "..Http:JSONEncode({value=s.essence,delta=essence and s.essence-essence or 0}))
  essence=s.essence
 end
end)
local shots={
 {"night","minimal","near",true},{"sunset","reduced","reverse",true},
 {"night","reduced","reverse",true},{"afterrain","reduced","near",false},
 {"rain","reduced","near",false},
}
if _G.AG70ExtraConnection then _G.AG70ExtraConnection:Disconnect() end
local index,busy=0,false
_G.AG70ExtraConnection=game:GetService("UserInputService").InputBegan:Connect(function(input,processed)
 if processed or busy then return end
 if input.KeyCode==Enum.KeyCode.K then
  index+=1;local s=shots[index];if not s then return end;busy=true
  task.spawn(function()
   q.look("AG70");q.pose(s[1]);q.quality(s[2]);q.camera(s[3]);q.motion(s[4]);task.wait(9)
   local name=s[1].."-"..s[2].."-"..s[3].."-motion-"..tostring(s[4])
   q.status(name);local c=workspace.CurrentCamera;local sun=game:GetService("Lighting"):GetSunDirection()
   print("AG70 CAPTURE_READY "..Http:JSONEncode({index=100+index,name=name,cframe={c.CFrame:GetComponents()},
    viewport={c.ViewportSize.X,c.ViewportSize.Y},fov=c.FieldOfView,sun={sun.X,sun.Y,sun.Z}}))
   busy=false
  end)
 elseif input.KeyCode==Enum.KeyCode.J then
  busy=true
  task.spawn(function()
   for _,tier in ipairs({"full","reduced","minimal"}) do for _,motion in ipairs({false,true}) do
    q.quality(tier);q.motion(motion);task.wait(2)
    for _,look in ipairs({"OFF","A","B","C","AG68","AG70"}) do
     q.look(look);task.wait(.5);q.status("compatibility-"..look)
     local counts=workspace.M7ClientWeather.PostFXInspect:Invoke();assert(counts.postFXLook==look)
    end
   end end
   for i=1,8 do
    local plot=assert(root:FindFirstChild("Plot_"..i));assert(plot:FindFirstChild("crystal"))
    local found=0
    for _,m in ipairs(game:GetService("CollectionService"):GetTagged("SpellbookLecternVisual")) do if m.Parent==plot then found+=1 end end
    assert(found==1);print("AG70 PLOT "..Http:JSONEncode({plot=i,books=found}))
   end
   q.quality("reduced");q.motion(false);q.look("AG70");print("AG70 COMPATIBILITY_DONE true");busy=false
  end)
 end
end)
