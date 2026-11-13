-- CLIENT Command Bar in local ordinary Play. Start Studio F12 recording first.
assert(game:GetService("RunService"):IsStudio() and game.GameId == 0)
local p = game.Players.LocalPlayer
local bridge = p.PlayerScripts.PotionTycoon.SpellbookEffects.Inspect
local camera = workspace.CurrentCamera
local action = game.ReplicatedStorage.PotionTycoon.Remotes.Action
local origin
for _, m in game.CollectionService:GetTagged("SpellbookLecternVisual") do
 if m.Parent:GetAttribute("OwnerUserId") == p.UserId then origin = m.LecternAnchor.Value.Position end
end
assert(origin)
task.spawn(function()
 bridge:Invoke("quality", "reduced"); bridge:Invoke("motion", false)
 p.Character:PivotTo(CFrame.new(origin + Vector3.new(0, 0, 6)))
 camera.CameraType = Enum.CameraType.Scriptable
 camera.CFrame = CFrame.lookAt(origin + Vector3.new(22, 13, 26), origin)
 print("AG67B_CAPTURE_WIDE_START")
 for i = 1, 4 do action:FireServer("click", {}); task.wait(3) end
 camera.CFrame = CFrame.lookAt(origin + Vector3.new(13, 9, 16), origin)
 bridge:Invoke("mode", "original")
 print("AG67B_CAPTURE_OLD_START")
 task.wait(1)
 for i = 1, 3 do action:FireServer("click", {}); task.wait(3) end
 bridge:Invoke("mode", "soul")
 print("AG67B_CAPTURE_NEW_START")
 task.wait(1)
 for i = 1, 3 do action:FireServer("click", {}); task.wait(3) end
 print("AG67B_CAPTURE_DONE")
end)
