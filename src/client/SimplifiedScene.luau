--!nonstrict
-- AG75: reversible Studio-only presentation cleanup. No server state/physics edits.
local RunService=game:GetService("RunService")
local Scene={}
function Scene.new()
 local self={modified={},world=nil,connections={},active=false,elapsed=0}
 local function enabled()
-- AG76_BEGIN_OWNED_WORLD
  if workspace:GetAttribute("AG76PersonalIsland")==true then return false end
-- AG76_END_OWNED_WORLD
  return RunService:IsStudio() and workspace:GetAttribute("AG75SimplifiedSceneEnabled")~=false
 end
 local function plotOf(object)
  local p=object
  while p and p~=self.world do
   if p:GetAttribute("PlotIndex") then return p end
   p=p.Parent
  end
  return nil
 end
 local function keep(plot,object)
  if object:IsDescendantOf(plot) then
   local item=object
   while item and item~=plot do
    if item.Name=="SpellbookLectern" or item.Name:match("^Lantern_") then return true end
    item=item.Parent
   end
   if object.Name=="Floor" and object.Parent==plot then return true end
  end
  return false
 end
 local function cosmetic(object)
  if not self.world or not object:IsDescendantOf(self.world) then return false end
  local plot=plotOf(object)
  if plot then return not keep(plot,object) end
  local ancestor=object
  while ancestor and ancestor.Parent~=self.world do ancestor=ancestor.Parent end
  if not ancestor then return false end
  return ancestor.Name=="TradePost" or
   (ancestor.Name=="Bazaar" and object:IsA("BillboardGui"))
 end
 local function update(object)
  if not object or not self.active or not cosmetic(object) then return end
  if object:IsA("BasePart") then
   if object.Name=="crystal" and object.Parent and not object.Parent:FindFirstChild("SpellbookLectern") then return end
   if self.modified[object]==nil then self.modified[object]={kind="part",old=object.LocalTransparencyModifier,collision=object.CanCollide} end
   object.LocalTransparencyModifier=1
   -- Hidden greybox collision is otherwise still a wall to the player.
   object.CanCollide=false
  elseif object:IsA("BillboardGui") or object:IsA("ProximityPrompt") then
   if object:IsA("ProximityPrompt") and object.Parent and object.Parent.Name=="crystal" then return end
   if self.modified[object]==nil then self.modified[object]={kind="enabled",old=object.Enabled} end
   object.Enabled=false
  end
 end
 local function restore()
  for object,receipt in pairs(self.modified) do
   if object.Parent then
    if receipt.kind=="part" then object.LocalTransparencyModifier=receipt.old;object.CanCollide=receipt.collision
    else object.Enabled=receipt.old end
   end
  end
  table.clear(self.modified)
 end
 local function sync()
  local on=enabled()
  if self.active and not on then self.active=false;restore()
  elseif on then
   self.active=true
   if self.world then
    for _,object in ipairs(self.world:GetDescendants()) do update(object) end
   end
  end
 end
 local function connect(world)
  self.world=world
  table.insert(self.connections,world.DescendantAdded:Connect(function(object)
   if self.active then
    update(object)
    if object.Name=="SpellbookLectern" then
     local plot=plotOf(object)
     if plot then update(plot:FindFirstChild("crystal")) end
    end
   end
  end))
  sync()
 end
 local current=workspace:FindFirstChild("PotionTycoonWorld")
 if current then connect(current) else
  table.insert(self.connections,workspace.ChildAdded:Connect(function(child)
   if child.Name=="PotionTycoonWorld" and not self.world then connect(child) end
  end))
 end
 table.insert(self.connections,workspace:GetAttributeChangedSignal("AG75SimplifiedSceneEnabled"):Connect(sync))
 -- Other presentation systems update local alpha during play. Reconcile the
 -- hidden set twice per second so greybox props cannot reappear after a tick.
 table.insert(self.connections,RunService.Heartbeat:Connect(function(dt)
  if not self.active then return end
  self.elapsed+=dt;if self.elapsed<.5 then return end
  self.elapsed=0
  for object,receipt in pairs(self.modified) do
   if not object.Parent then self.modified[object]=nil
   elseif receipt.kind=="part" then
    if object.LocalTransparencyModifier~=1 then object.LocalTransparencyModifier=1 end
    if object.CanCollide then object.CanCollide=false end
   elseif object.Enabled then object.Enabled=false end
  end
 end))
 function self.destroy()
  self.active=false;restore()
  for _,connection in ipairs(self.connections) do connection:Disconnect() end
 end
 return self
end
return Scene
