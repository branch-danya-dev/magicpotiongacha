-- Run manually in the CLIENT Command Bar of ordinary local Studio Play.
-- No injected rewards: all click intents pass through the existing server.
assert(game:GetService("RunService"):IsStudio() and game.GameId == 0, "Local Studio only")
local p = game.Players.LocalPlayer
local bridge = p.PlayerScripts.PotionTycoon.SpellbookEffects.Inspect
local remotes = game.ReplicatedStorage.PotionTycoon.Remotes
local camera = workspace.CurrentCamera
local latest
local connection = remotes.State.OnClientEvent:Connect(function(s) latest = s end)
local function report(label)
 local s = bridge:Invoke()
 print("AG67B_QA", label, game.HttpService:JSONEncode(s))
 assert(s.errors == nil or s.errors == 0, label .. " runtime error")
 return s
end
local function click() remotes.Action:FireServer("click", {}) end
local models = game.CollectionService:GetTagged("SpellbookLecternVisual")
local owned
for _, m in models do if m.Parent:GetAttribute("OwnerUserId") == p.UserId then owned = m end end
assert(owned and #models == 8)
local origin = owned.LecternAnchor.Value.Position
local function near()
 p.Character:PivotTo(CFrame.new(origin + Vector3.new(0,0,6)))
 camera.CameraType = Enum.CameraType.Scriptable
 camera.CFrame = CFrame.lookAt(origin + Vector3.new(13,9,16),origin)
end
task.spawn(function()
 local ok, err = pcall(function()
 near(); task.wait(1.2)
 local initial = report("after-native-E-and-mouse")
 assert(initial.mode == "soul" and initial.content == "ready" and initial.tracked == 8)
 assert(initial.feedback == 2 and latest.essence == 10, "native E and mouse receipts")
 for _, quality in {"full","reduced","minimal"} do
  bridge:Invoke("quality",quality); task.wait(.3)
  local before = report(quality.."-idle"); local balance = latest.essence
  click(); task.wait(.65)
  local active = report(quality.."-ritual")
  assert(latest.essence == balance + 5 and active.feedback == before.feedback + 1)
  assert(active.sheets == (quality == "full" and 22 or quality == "reduced" and 12 or 0))
  assert(active.sigilSparks - before.sigilSparks == (quality == "full" and 32 or quality == "reduced" and 16 or 0))
  task.wait(2)
 end
 bridge:Invoke("quality","full"); bridge:Invoke("motion",true); task.wait(.3)
 click(); task.wait(.65); local calm = report("reduce-motion")
 assert(calm.sheets == 0 and calm.beams == 0 and calm.emitters == 0)
 task.wait(2); bridge:Invoke("motion",false); bridge:Invoke("quality","reduced"); task.wait(.3)
 local before = report("before-invalid"); local balance = latest.essence
 remotes.Action:FireServer("click", {amount=100}); task.wait(.5)
 assert(report("invalid-rejected").feedback == before.feedback and latest.essence == balance)
 p.Character:PivotTo(CFrame.new(origin + Vector3.new(0,0,45))); task.wait(.5); click(); task.wait(.5)
 assert(report("distance-rejected").feedback == before.feedback and latest.essence == balance)
 near(); task.wait(.5)
 for _=1,100 do click() end
 task.wait(.65); local spam = report("100-rapid-intents")
 assert(spam.feedback-before.feedback > 0 and spam.feedback-before.feedback < 100)
 assert(spam.batches == before.batches + 1 and spam.sheets == 12 and spam.lights <= 1 and spam.emitters <= 6)
 task.wait(3)
 local pooled = report("pool-after-spam")
 click(); task.wait(.65)
 assert(report("pool-reused").instances == pooled.instances)
 bridge:Invoke("fallback",true); task.wait(.3)
 assert(report("fallback").mode == "original" and not workspace:FindFirstChild("SpellbookSoulVFX"))
 bridge:Invoke("fallback",false); task.wait(.3)
 assert(report("restored").sheets == 0)
 for i=1,20 do
  bridge:Invoke("mode","original"); assert(not workspace:FindFirstChild("SpellbookSoulVFX"))
  bridge:Invoke("mode","soul"); bridge:Invoke("quality",i%2==0 and "reduced" or "full"); task.wait(.08)
 end
 local reset = report("20-owner-quality-switches")
 assert(reset.connections == 3 and reset.sheets == 0 and reset.instances == 32)
 -- Distance-cull each plot separately, without changing ownership or rewards.
 table.sort(models,function(a,b) return a:GetAttribute("PlotIndex")<b:GetAttribute("PlotIndex") end)
 for _,m in models do
  local pivot=m:GetPivot().Position
  camera.CFrame=CFrame.lookAt(pivot+Vector3.new(12,9,15),pivot)
  task.wait(.2)
  local folder=workspace.SpellbookSoulVFX
  local plane=folder:FindFirstChild("SoulAbsorptionSigil",true)
  assert(plane and math.abs(plane.Position.X-pivot.X)<.001 and math.abs(plane.Position.Z-pivot.Z)<.001)
  assert(plane.Position.Y>=pivot.Y and plane.Position.Y-pivot.Y<.5)
  print("AG67B_FLOOR",m:GetAttribute("PlotIndex"),plane.Position,plane.Position.Y-pivot.Y)
 end
 near(); task.wait(.3); print("AG67B_QA_COMPLETE")
 end)
 connection:Disconnect()
 if not ok then warn("AG67B_QA_FAILED",err) end
end)
