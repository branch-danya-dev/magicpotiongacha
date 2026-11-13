-- SERVER Command Bar after rig-client, local ordinary Play ONLY.
-- Replaces ephemeral test rigs, then restores the normal player avatar.
assert(game:GetService("RunService"):IsStudio() and game.GameId == 0)
local players = game:GetService("Players")
local p = players:GetPlayers()[1]
assert(p)
task.spawn(function()
 local ok, err = pcall(function()
  for _, rigType in {Enum.HumanoidRigType.R6, Enum.HumanoidRigType.R15} do
   local description = Instance.new("HumanoidDescription")
   local rig = players:CreateHumanoidModelFromDescriptionAsync(description, rigType)
   description:Destroy()
   local old = p.Character
   rig.Name = p.Name; rig:PivotTo(old:GetPivot()); rig.Parent = workspace
   p.Character = rig; old:Destroy()
   print("AG67B_RIG_SERVER_CREATED", rigType.Name)
   task.wait(8)
  end
  -- Observer has tested a live moving R15. Death must remove its pool.
  p.Character.Humanoid.Health = 0
  print("AG67B_RIG_SERVER_DEATH")
  task.wait(8)
  if not p.Character or not p.Character:FindFirstChild("Humanoid") or p.Character.Humanoid.Health <= 0 then p:LoadCharacterAsync() end
  print("AG67B_RIG_SERVER_DONE")
 end)
 if not ok then warn("AG67B_RIG_SERVER_FAILED", err); p:LoadCharacterAsync() end
end)
