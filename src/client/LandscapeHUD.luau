--!nonstrict
-- AG64: one mounted view inside PotionTycoonUI. State/actions belong to Main.
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Model=require(Shared.ui.Landscape)
local Kit=require(script.Parent.ui.Kit)
local GuiService=game:GetService("GuiService")
local RunService=game:GetService("RunService")
local HUD={}
local function rgb(c) return Color3.fromRGB(c[1],c[2],c[3]) end
local function place(object,r) object.Position=UDim2.fromOffset(r.x,r.y); object.Size=UDim2.fromOffset(r.w,r.h) end
local function rounded(object,radius,color,opacity)
 local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,radius); corner.Parent=object
 if color then local line=Instance.new("UIStroke"); line.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; line.Color=rgb(color); line.Transparency=opacity or .28; line.Parent=object end
end
function HUD.new(gui,callbacks)
-- AG71_BEGIN_FACTORY
 if callbacks.arcade then return require(script.Parent.ArcadeHUD).new(gui,callbacks) end
-- AG71_END_FACTORY
 local self={root=nil,plan=nil,cursor=nil,connection=nil,untilTime=0,shown=false,popupCount=0}
 local host=Kit.host(); host.theme=Model.tokens()
 local root=Instance.new("Frame"); root.Name="LandscapeHUD"; root.BackgroundTransparency=1; root.BorderSizePixel=0
 root.Size=UDim2.fromScale(1,1); root.Active=false; root.Parent=gui; self.root=root
 local nodes,labels,nav={},{},{}
 local function panel(name,color,alpha,radius,parent)
  local f=Instance.new("Frame"); f.Name=name; f.BackgroundColor3=rgb(color); f.BackgroundTransparency=alpha
  f.BorderSizePixel=0; f.Active=false; f.Parent=parent or root; rounded(f,radius,{114,98,125}); return f
 end
 local function text(parent,name,value,size,color,bold)
  local t=Instance.new("TextLabel"); t.Name=name; t.Text=value; t.BackgroundTransparency=1
  t.TextColor3=rgb(color); t.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
  t.TextSize=size; t.TextWrapped=true; t.TextXAlignment=Enum.TextXAlignment.Left; t.TextYAlignment=Enum.TextYAlignment.Center
  t.Active=false; t.Parent=parent; table.insert(labels,{object=t,size=size}); return t
 end
 -- Roblox fonts do not contain Figma's four-point stars. Native geometry keeps
 -- these symbols crisp and available without an uploaded texture or font fallback.
 local function symbol(parent,value,size,color)
  local mark=text(parent,"Symbol",value,size,color,true)
  if value=="✦" or value=="✧" then
   mark.Text=""
   local function ray(w,h,angle)
    local f=Instance.new("Frame"); f.Name="StarRay"; f.Active=false; f.BorderSizePixel=0
    f.AnchorPoint=Vector2.new(.5,.5); f.Position=UDim2.fromScale(.5,.5)
    f.Size=UDim2.fromOffset(w,h); f.Rotation=angle; f.BackgroundColor3=rgb(color); f.Parent=mark
    return f
   end
   if value=="✧" then
    local outline=ray(size*.5,size*.5,45); outline.BackgroundTransparency=1
    local line=Instance.new("UIStroke"); line.Thickness=1.5; line.Color=rgb(color); line.Parent=outline
   else ray(size*.34,size*.34,45) end
   ray(2,size*.85,0); ray(size*.85,2,0)
  end
  return mark
 end
 local ink={248,240,232}; local muted={200,192,210}; local gold={240,199,131}; local lilac={207,174,243}
 local function control(name,mark,parent,callback)
  local b=Kit.button(host,parent or root,mark); b.root.Name=name; b.onActivated=callback; return b
 end
 nodes.title=Instance.new("Frame"); nodes.title.Name="Identity"; nodes.title.BackgroundTransparency=1; nodes.title.Parent=root
 local gameTitle=text(nodes.title,"GameTitle","POTION TYCOON",17,{255,231,194},true)
 gameTitle.Position=UDim2.fromOffset(0,0); gameTitle.Size=UDim2.new(1,0,.6,0)
 local level=text(nodes.title,"Level","",11,{198,187,212},false); level.Position=UDim2.fromScale(0,.65); level.Size=UDim2.fromScale(1,.35)
 local counters={}
 for _,spec in ipairs({{"gold","GOLD","◆"},{"essence","ESSENCE","✦"}}) do
  local p=panel(spec[2],{23,26,43},.02,16); nodes[spec[1]]=p
  local icon=panel("Gem",{74,60,102},.1,11,p); icon.Position=UDim2.new(0,10,.5,-17); icon.Size=UDim2.fromOffset(35,35)
  local mark=symbol(icon,spec[3],22,{213,183,255}); mark.Size=UDim2.fromScale(1,1); mark.TextXAlignment=Enum.TextXAlignment.Center
  local caption=text(p,"Caption",spec[2],10,{189,185,205},true); caption.Position=UDim2.fromOffset(54,5); caption.Size=UDim2.new(1,-60,.34,0)
  local value=text(p,"Amount","—",18,{248,244,236},true); value.Position=UDim2.new(0,54,.36,0); value.Size=UDim2.new(1,-60,.54,0)
  counters[spec[1]]=value
 end
 local settings=control("Settings","",nil,function() callbacks.open("quality") end); nodes.settings=settings.root
 local gear=text(settings.root,"Symbol","⚙",23,{243,216,171},true); gear.Size=UDim2.fromScale(1,1); gear.TextXAlignment=Enum.TextXAlignment.Center
 local quest=control("Quest","",nil,callbacks.quest); nodes.quest=quest.root
 quest.root.BackgroundTransparency=.08
 local chapter=text(quest.root,"Chapter","ТЕКУЩЕЕ ЗАДАНИЕ",10,{212,182,250},true)
 chapter.Position=UDim2.fromOffset(12,6); chapter.Size=UDim2.new(1,-80,0,17)
 local steps=text(quest.root,"Steps","",10,{239,207,154},true); steps.Position=UDim2.new(1,-70,0,6); steps.Size=UDim2.fromOffset(58,17); steps.TextXAlignment=Enum.TextXAlignment.Right
 local questTitle=text(quest.root,"Title","",16,ink,true); questTitle.Position=UDim2.fromOffset(12,24); questTitle.Size=UDim2.new(1,-24,0,22)
 local questCopy=text(quest.root,"Instruction","",11,muted,false); questCopy.Position=UDim2.fromOffset(12,47); questCopy.Size=UDim2.new(1,-24,1,-62); questCopy.TextYAlignment=Enum.TextYAlignment.Top
 local track=panel("Progress",{75,67,93},0,3,quest.root); track.Position=UDim2.new(0,12,1,-11); track.Size=UDim2.new(1,-24,0,5)
 track:FindFirstChildOfClass("UIStroke"):Destroy()
 local fill=panel("Completed",lilac,0,3,track); fill.Size=UDim2.fromScale(0,1); fill:FindFirstChildOfClass("UIStroke"):Destroy()
 local shop=control("Shop","✧",nil,function() callbacks.open("supplies") end); nodes.shop=shop.root
 local rewards=control("Rewards","✦",nil,function() callbacks.open("dailies") end); nodes.rewards=rewards.root
 for _,entry in ipairs({{shop,"SHOP"},{rewards,"REWARDS"}}) do
  entry[1].root.Text=""
  local mark=symbol(entry[1].root,entry[2]=="SHOP" and "✧" or "✦",22,entry[2]=="SHOP" and gold or lilac)
  mark.Size=UDim2.new(1,0,1,-13); mark.TextXAlignment=Enum.TextXAlignment.Center
  local name=text(entry[1].root,"Caption",entry[2],9,muted,true); name.Position=UDim2.new(0,1,1,-14); name.Size=UDim2.new(1,-2,0,12); name.TextXAlignment=Enum.TextXAlignment.Center
 end
 nodes.book=panel("SpellbookUpgrade",{25,29,47},.04,16)
 local emblem=panel("BookLevel",{85,67,104},0,12,nodes.book); emblem.Position=UDim2.new(0,12,.5,-27); emblem.Size=UDim2.fromOffset(45,54)
 local star=symbol(emblem,"✦",23,{242,211,143}); star.Size=UDim2.new(1,0,0,32); star.TextXAlignment=Enum.TextXAlignment.Center
 local tier=text(emblem,"Level","—",11,{231,215,240},true); tier.Position=UDim2.fromOffset(0,32); tier.Size=UDim2.new(1,0,0,18); tier.TextXAlignment=Enum.TextXAlignment.Center
 local bookTitle=text(nodes.book,"Title","SPELLBOOK",12,{249,243,233},true); bookTitle.Position=UDim2.fromOffset(69,8); bookTitle.Size=UDim2.new(1,-78,0,18)
 local tap=text(nodes.book,"PerTap","",11,{197,189,207},false); tap.Position=UDim2.fromOffset(69,25); tap.Size=UDim2.new(1,-78,0,15)
 local upgradeTokens=Model.tokens(); upgradeTokens.color.raised={255,255,255}; upgradeTokens.color.surface={100,95,105}
 upgradeTokens.color.ink={38,31,44}; upgradeTokens.color.muted={215,207,222}
 local upgradeHost=setmetatable({theme=upgradeTokens},{__index=host})
 local upgrade=Kit.button(upgradeHost,nodes.book,"UPGRADE"); upgrade.root.Name="Upgrade"
 upgrade.root.Position=UDim2.new(1,-150,1,-49); upgrade.root.Size=UDim2.fromOffset(138,44)
 local gradient=Instance.new("UIGradient"); gradient.Color=ColorSequence.new(Color3.fromRGB(255,228,172),Color3.fromRGB(201,156,96)); gradient.Parent=upgrade.root
 upgrade.onActivated=callbacks.upgrade
 nodes.dock=panel("Navigation",{20,23,40},.09,16)
 for i,spec in ipairs({{"Book","✧"},{"Familiars","✦"},{"Brew","♧"},{"Lab","◈"}}) do
  local b=control(spec[1],"",nodes.dock,function() callbacks.open(Model.routes[spec[1]]) end)
  b.root.Position=UDim2.new(0,3,(i-1)/4,3); b.root.Size=UDim2.new(1,-6,.25,-4)
  b.root:FindFirstChildOfClass("UIStroke").Transparency=1
  local mark=symbol(b.root,spec[2],24,muted); mark.Position=UDim2.fromScale(0,.05); mark.Size=UDim2.fromScale(1,.57); mark.TextXAlignment=Enum.TextXAlignment.Center
  local caption=text(b.root,"Caption",string.upper(spec[1]),10,muted,true); caption.Position=UDim2.fromScale(0,.64); caption.Size=UDim2.fromScale(1,.28); caption.TextXAlignment=Enum.TextXAlignment.Center
  nav[spec[1]]={button=b,mark=mark,caption=caption}
 end
 local popup=panel("ConfirmedEssence",{60,44,81},.09,17)
 popup.Visible=false; popup.ZIndex=12; popup.Size=UDim2.fromOffset(104,35)
 local gain=text(popup,"Amount","",15,{244,219,250},true); gain.Size=UDim2.fromScale(1,1); gain.TextXAlignment=Enum.TextXAlignment.Center; gain.ZIndex=13
 local controls={quest,shop,rewards,upgrade,nav.Book.button,nav.Familiars.button,nav.Brew.button,nav.Lab.button,settings}
 for i,b in ipairs(controls) do
  b.root.SelectionOrder=i; b.root.NextSelectionDown=controls[i%#controls+1].root
  b.root.NextSelectionUp=controls[(i-2)%#controls+1].root
 end
 function self.hideFeedback()
  popup.Visible=false; self.untilTime=0
  if self.connection then self.connection:Disconnect(); self.connection=nil end
 end
 function self.flash(amount)
  self.popupCount+=1; gain.Text="+"..tostring(amount).." Essence"; self.untilTime=os.clock()+1.1
  if self.connection then return end
  self.connection=RunService.Heartbeat:Connect(function()
   local camera=workspace.CurrentCamera; local anchor=callbacks.anchor()
   if os.clock()>=self.untilTime or not root.Parent or not root.Visible or not gui.Enabled or not anchor or not camera then self.hideFeedback(); return end
   local point,visible=camera:WorldToViewportPoint(anchor.Position+Vector3.new(0,3.8,0))
   local origin=GuiService:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets).Min
   local x,y=point.X+origin.X,point.Y+origin.Y
   popup.Position=UDim2.fromOffset(x+18,y-20)
   popup.Visible=visible and point.Z>0 and x>0 and x+122<root.AbsoluteSize.X and y>20 and y<root.AbsoluteSize.Y
  end)
 end
 function self.layout(width,height,touch,chatRight)
  local p=Model.layout(width,height,touch,chatRight); self.plan=p
  for name,object in pairs(nodes) do place(object,p[name]) end
  for _,entry in ipairs(labels) do entry.object.TextSize=entry.size*p.scale end
  settings.root.TextSize=23*p.scale
  -- Keep legible copy in the shorter phone card; full instructions remain in the existing panel.
  questTitle.Visible=not p.compact
  questCopy.Position=UDim2.fromOffset(12,p.compact and 25 or 47)
  questCopy.Size=UDim2.new(1,-24,1,p.compact and -40 or -62)
  nodes.title.Visible=p.title.w>=180
  return p
 end
 function self.update(snapshot,pending,selected,modal,reduceMotion)
  local data=Model.present(snapshot,pending)
  counters.gold.Text=data.gold; counters.essence.Text=data.essence
  level.Text="WITCHWOOD  /  LEVEL "..data.level; tier.Text=data.level
  steps.Text=data.steps; questTitle.Text=data.questTitle; questCopy.Text=data.quest; fill.Size=UDim2.fromScale(data.progress,1)
  tap.Text=data.amount.." Essence / tap"
  upgrade.root.Text=data.upgrade.label; upgrade.root:SetAttribute("UnavailableReason",data.upgrade.reason)
  if upgrade.disabled()==data.upgrade.enabled then upgrade.setDisabled(not data.upgrade.enabled) end
  if host.reduceMotion~=reduceMotion then host.setReduceMotion(reduceMotion) end
  for name,item in pairs(nav) do
   local active=Model.routes[name]==selected
   if item.selected~=active then item.selected=active; item.button.setSelected(active) end
   item.button.root.BackgroundTransparency=active and .03 or 1
   item.mark.TextColor3=rgb(active and gold or {183,175,203}); item.caption.TextColor3=rgb(active and {246,233,207} or {183,175,203})
   for _,part in ipairs(item.mark:GetDescendants()) do
    if part:IsA("Frame") then part.BackgroundColor3=item.mark.TextColor3
    elseif part:IsA("UIStroke") then part.Color=item.mark.TextColor3 end
   end
  end
  for _,name in ipairs({"quest","shop","rewards","book"}) do nodes[name].Visible=not modal end
  root:SetAttribute("BookLevel",data.level); root:SetAttribute("UpgradeEnabled",data.upgrade.enabled)
  root:SetAttribute("SelectedMenu",selected); root:SetAttribute("Pending",pending)
  self.shown=true
 end
 function self.receipt(snapshot,owned,maxBalance)
  local amount; self.cursor,amount=Model.feedback(self.cursor,snapshot,owned,maxBalance)
  if amount then self.flash(amount) end
 end
 function self.blocked(extra,chatRect)
  local result={}; if chatRect then table.insert(result,chatRect) end
  local inset=GuiService:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets).Min
  local function add(o)
   if not o.Visible then return end
   local p,s=o.AbsolutePosition,o.AbsoluteSize
   if s.X>0 and s.Y>0 then table.insert(result,{x=p.X-inset.X,y=p.Y-inset.Y,w=s.X,h=s.Y}) end
  end
  for _,o in pairs(nodes) do add(o) end
  for _,o in ipairs(extra or {}) do add(o) end
  return result
 end
 function self.destroy() self.hideFeedback(); host.destroy(); root:Destroy() end
 return self
end
return HUD
