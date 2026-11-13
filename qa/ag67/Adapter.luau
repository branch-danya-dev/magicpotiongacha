--!nonstrict
-- The generated QA project maps this proxy instead of SpellbookEffects.
-- Default build never maps it. Switch stops/restores the prior owner first.
local RunService=game:GetService("RunService")
local Legacy=require(script.Parent.LegacySpellbookEffects)
local Controller=require(script.Parent.EnvironmentController)
local Adapter={current=nil}
function Adapter.start()
 if Adapter.current then return Adapter.current end
 if not RunService:IsStudio() then return Legacy.start() end
 local models,owner,mode={},nil,nil
 local connection,bridge
 local function switch()
  local wanted=workspace:GetAttribute("AG67SoulPreview")==true and "prototype" or "original"
  if wanted==mode then return end
  if owner then owner.stop() end
  mode=wanted
  owner=mode=="prototype" and require(script.Parent.AG67.View).start() or Legacy.start()
  for model in pairs(models) do owner.attach(model) end
 end
 local self={}
 function self.attach(model) models[model]=true;owner.attach(model) end
 function self.detach(model) models[model]=nil;owner.detach(model) end
 function self.stats() return owner.stats(),mode end
 function self.stop()
  if connection then connection:Disconnect() end;if bridge then bridge:Destroy() end
  if owner then owner.stop() end;table.clear(models);Adapter.current=nil
 end
 switch();connection=workspace:GetAttributeChangedSignal("AG67SoulPreview"):Connect(switch)
 bridge=Instance.new("BindableFunction");bridge.Name="ArtPreview"
 bridge.OnInvoke=function(command,value)
  if command=="mode" then workspace:SetAttribute("AG67SoulPreview",value=="prototype");switch()
  elseif command=="quality" then Controller.setQuality(value)
  elseif command=="motion" then Controller.setReduceMotion(value) end
  return owner.stats(),mode,Controller.quality,Controller.reduceMotion
 end
 bridge.Parent=script;Adapter.current=self;return self
end
return Adapter
