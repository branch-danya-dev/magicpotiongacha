--!nonstrict
-- Paste into CLIENT Command Bar during ordinary Play of AG67-Prototype.rbxlx.
-- Never mapped by Rojo. Local-memory art capture only; does not grant rewards.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId==0,"Local Studio file required")
if _G.AG67Review then _G.AG67Review.restore() end
local p=game.Players.LocalPlayer
local bridge=p.PlayerScripts.PotionTycoon.SpellbookEffects.ArtPreview
local model
for _,v in game:GetService("CollectionService"):GetTagged("SpellbookLecternVisual") do
 if v:GetAttribute("PlotIndex")==p:GetAttribute("PotionPlotIndex") then model=v end
end
assert(model and model:GetAttribute("SpellbookLoadState")=="ready","Wait for imported lectern")
local origin=model:GetPivot().Position
local camera=workspace.CurrentCamera
local previousCamera={type=camera.CameraType,frame=camera.CFrame,fov=camera.FieldOfView}
local hud=p.PlayerGui:FindFirstChild("PotionTycoonUI")
local hudEnabled=hud and hud.Enabled
local hudParent=hud and hud.Parent
local environment=workspace:FindFirstChild("PotionTycoonWorld")
local previousPose=environment and environment:GetAttribute("EnvironmentReview")
local prompts=game:GetService("ProximityPromptService")
local promptEnabled=prompts.Enabled
local review={}
local stopped=false
function review.prepare(quality,close)
 stopped=false
 bridge:Invoke("quality",quality or "full");bridge:Invoke("motion",false);bridge:Invoke("mode","prototype")
 p.Character:PivotTo(CFrame.new(origin+Vector3.new(-5,3,1),origin+Vector3.new(0,3,0)))
 camera.CameraType=Enum.CameraType.Scriptable
 camera.FieldOfView=close and 55 or previousCamera.fov
 camera.CFrame=CFrame.new(origin+(close and Vector3.new(8,7,10) or Vector3.new(13,10,14)),origin+Vector3.new(-1,4,0))
 if hud then hud.Parent=nil end;prompts.Enabled=false
 if environment then environment:SetAttribute("EnvironmentReview","day") end
 print("AG67_CAPTURE_SETUP",quality or "full",camera.CFrame,origin)
end
function review.ritual()
 -- Start native F12 recording immediately after invoking this function.
 -- All four requests go through the unchanged server; no direct VFX trigger.
 local remotes=game.ReplicatedStorage.PotionTycoon.Remotes
 task.spawn(function()
  local started=os.clock();local lastSequence
  local connection=remotes.State.OnClientEvent:Connect(function(s)
   local receipt=s.presentation and s.presentation.essenceClick
   if receipt and receipt.sequence~=lastSequence then
    lastSequence=receipt.sequence;print("AG67_CAPTURE_RECEIPT",game.HttpService:JSONEncode(receipt))
   end
  end)
  for _,at in ipairs({3,6,9,9.18}) do
   task.wait(math.max(0,at-(os.clock()-started)))
   if stopped then break end
   remotes.Action:FireServer("click",{})
  end
  task.wait(2.6);connection:Disconnect()
  print("AG67_CAPTURE_STATS",game.HttpService:JSONEncode(bridge:Invoke("inspect")))
 end)
end
function review.restore()
 stopped=true;bridge:Invoke("mode","original")
 if hud then hud.Parent=hudParent;hud.Enabled=hudEnabled end;prompts.Enabled=promptEnabled
 if environment then environment:SetAttribute("EnvironmentReview",previousPose or "auto") end
 camera.CameraType=previousCamera.type;camera.CFrame=previousCamera.frame;camera.FieldOfView=previousCamera.fov
end
_G.AG67Review=review
review.prepare("full")
