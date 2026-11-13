-- CLIENT Command Bar, local ordinary Play only. Does not change server rules.
assert(game:GetService("RunService"):IsStudio() and game.GameId == 0)
local p=game.Players.LocalPlayer
local bridge=p.PlayerScripts.PotionTycoon.SpellbookEffects.Inspect
local camera=workspace.CurrentCamera
local remotes=game.ReplicatedStorage.PotionTycoon.Remotes
local origin
for _,m in game.CollectionService:GetTagged("SpellbookLecternVisual") do
 if m.Parent:GetAttribute("OwnerUserId")==p.UserId then origin=m.LecternAnchor.Value.Position end
end
assert(origin)
task.spawn(function()
 local ok,err=pcall(function()
 p.Character:PivotTo(CFrame.new(origin+Vector3.new(0,0,6)))
 camera.CameraType=Enum.CameraType.Scriptable
 camera.CFrame=CFrame.lookAt(origin+Vector3.new(13,9,16),origin)
 for _,quality in {"full","reduced","minimal"} do
  bridge:Invoke("quality",quality); task.wait(1)
  local samples={}; local elapsed=0
  local before=bridge:Invoke()
  local c=game:GetService("RunService").RenderStepped:Connect(function(dt) table.insert(samples,dt); elapsed+=dt end)
  for i=1,3 do remotes.Action:FireServer("click",{}); task.wait(3) end
  c:Disconnect(); table.sort(samples)
  local after=bridge:Invoke()
  print("AG67B_PERF",quality,game.HttpService:JSONEncode({samples=#samples,seconds=elapsed,fps=#samples/elapsed,
   p95Ms=samples[math.ceil(#samples*.95)]*1000,averageUpdateMs=(after.averageMs*after.updates-before.averageMs*before.updates)/math.max(1,after.updates-before.updates),stats=after}))
 end
 bridge:Invoke("quality","reduced")
 print("AG67B_PERF_DONE",p.Character.Humanoid.RigType.Name,camera.ViewportSize)
 end)
 if not ok then warn("AG67B_PERF_FAILED",err) end
end)
