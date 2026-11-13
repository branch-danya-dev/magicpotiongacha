--!nonstrict
-- Run in CLIENT Command Bar of the local QA place. Never mapped by Rojo.
-- Scoped prototype diagnostics; not production/mobile/multiplayer acceptance.
assert(game:GetService("RunService"):IsStudio() and game.PlaceId==0,"Local Studio file required")
local bridge=game.Players.LocalPlayer.PlayerScripts.PotionTycoon.SpellbookEffects.ArtPreview
local Http=game:GetService("HttpService")
local function report(label)
 local s=bridge:Invoke("inspect")
 assert(s.errors==0,label..": runtime errors")
 print("AG67_DIAGNOSTIC",label,Http:JSONEncode(s))
 return s
end
task.spawn(function()
 bridge:Invoke("mode","prototype");bridge:Invoke("motion",false)
 for _,entry in ipairs({{"full",22,18},{"reduced",12,12},{"minimal",4,6}}) do
  bridge:Invoke("quality",entry[1]);task.wait(.5)
  local s=report(entry[1]);assert(s.sheets==entry[2] and s.beams==entry[3])
 end
 bridge:Invoke("quality","full");bridge:Invoke("motion",true);task.wait(.5)
 local calm=report("reduceMotion");assert(calm.sheets==0 and calm.beams==0 and calm.activeRitual==false)
 bridge:Invoke("motion",false);task.wait(.5)
 local baseline=report("beforeSwitches")
 for i=1,10 do
  bridge:Invoke("mode","original");task.wait(.1)
  assert(not workspace:FindFirstChild("AG67LocalArtPreview"),"Prototype folder leaked after OFF")
  bridge:Invoke("mode","prototype");task.wait(.2)
  local s=bridge:Invoke("inspect");assert(s.instances==baseline.instances and s.errors==0,"Allocation drift on switch "..i)
 end
 report("after20Switches")
 local states={}
 for _,m in game:GetService("CollectionService"):GetTagged("SpellbookLecternVisual") do
  states[m]=m:GetAttribute("SpellbookLoadState");m:SetAttribute("SpellbookLoadState","fallback")
 end
 task.wait(.5)
 local fallback=report("simulatedFallback");assert(fallback.active==0 and fallback.activeRitual==false)
 for m,state in pairs(states) do m:SetAttribute("SpellbookLoadState",state) end
 task.wait(.5)
 local recovered=report("recovered");assert(recovered.instances==baseline.instances)
 bridge:Invoke("mode","original");task.wait(.2)
 assert(not workspace:FindFirstChild("AG67LocalArtPreview"),"Prototype folder leaked after final OFF")
 print("AG67_DIAGNOSTIC_PASS","Quality caps, calm mode, 20 switches, simulated fallback, restoration. No rewards requested.")
end)
