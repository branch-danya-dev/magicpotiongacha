-- CLIENT Command Bar, before rig-server. Test-only; never mapped by Rojo.
assert(game:GetService("RunService"):IsStudio() and game.GameId == 0)
local p = game.Players.LocalPlayer
local bridge = p.PlayerScripts.PotionTycoon.SpellbookEffects.Inspect
local action = game.ReplicatedStorage.PotionTycoon.Remotes.Action
local function inspectCharacter(character)
 task.spawn(function()
  local ok, err = pcall(function()
   local hum = character:WaitForChild("Humanoid", 10)
   if not hum then return end
   local rig = hum.RigType.Name
   hum.Died:Once(function()
    task.wait(.2)
    local stats = bridge:Invoke()
    assert(stats.instances == 0 and stats.sheets == 0 and stats.active == 0, "death cleanup")
    print("AG67B_RIG_DEATH_PASS", rig, game.HttpService:JSONEncode(stats))
   end)
   task.wait(2)
   local origin
   for _, m in game.CollectionService:GetTagged("SpellbookLecternVisual") do
    if m.Parent:GetAttribute("OwnerUserId") == p.UserId then origin = m.LecternAnchor.Value.Position end
   end
   assert(origin)
   bridge:Invoke("quality", "reduced")
   character:PivotTo(CFrame.new(origin + Vector3.new(0, 0, 6)))
   workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
   workspace.CurrentCamera.CFrame = CFrame.lookAt(origin + Vector3.new(13, 9, 16), origin)
   task.wait(.8)
   local before = bridge:Invoke()
   action:FireServer("click", {})
   task.wait(.3)
   assert(bridge:Invoke().feedback == before.feedback + 1, "one accepted receipt")
   local chest = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
   assert(chest, "R6/R15 chest")
   local start = chest.Position
   local maxError = 0
   for i = 1, 8 do
    character:PivotTo(character:GetPivot() + Vector3.new(.25, 0, 0))
    task.wait(.06)
    local absorption = workspace.SpellbookSoulVFX:FindFirstChild("AbsorptionOrigin", true)
    assert(absorption, "absorption target")
    maxError = math.max(maxError, (absorption.WorldPosition - chest.Position).Magnitude)
   end
   assert((chest.Position - start).Magnitude >= 1.5 and maxError < .6, "moving chest tracking")
   print("AG67B_RIG_MOTION_PASS", rig, chest.Name, "errorStuds", maxError, game.HttpService:JSONEncode(bridge:Invoke()))
  end)
  if not ok then warn("AG67B_RIG_FAILED", err) end
 end)
end
p.CharacterAdded:Connect(inspectCharacter)
p.CharacterRemoving:Connect(function()
 task.wait(.05)
 assert(bridge:Invoke().sheets == 0, "character removal pool cleanup")
 print("AG67B_CHARACTER_REMOVING_PASS")
end)
print("AG67B_RIG_OBSERVER_READY")
