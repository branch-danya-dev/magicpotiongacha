--!nonstrict
-- AG71 B, mounted only by LandscapeHUD. No subscription, remote or reward owner.
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Model=require(Shared.ui.Arcade)
local Assets=require(Shared.ui.ArcadeAssets)
local Legacy=require(Shared.ui.Landscape)
local RunService=game:GetService("RunService")
local GuiService=game:GetService("GuiService")
local View={}
local function color(r,g,b) return Color3.fromRGB(r,g,b) end
local ink=color(52,46,67); local gold=color(255,223,160); local pale=color(226,250,255)
local function box(o,r) o.Position=UDim2.fromOffset(r.x,r.y); o.Size=UDim2.fromOffset(r.w,r.h) end
function View.new(gui,callbacks)
 local self={arcade=true,cursor=nil,connection=nil,untilTime=0,shown=false,popupCount=0}
 local root=Instance.new("Frame"); root.Name="LandscapeHUD"; root.BackgroundTransparency=1
 root.Size=UDim2.fromScale(1,1); root.Parent=gui; self.root=root
 root:SetAttribute("ArtVariant","AG71_B")
 local connections={}; local scales={}; local controls={}; local snapshot,pending,reduceMotion
 local picked="farmer"; local moreOpen=false; local modal=false; local bookOpen=false
 local function frame(name,parent)
  local f=Instance.new("Frame"); f.Name=name; f.BackgroundTransparency=1; f.BorderSizePixel=0; f.Parent=parent or root; return f
 end
 local function label(name,parent,text,size,tint,serif)
  local t=Instance.new("TextLabel"); t.Name=name; t.Text=text; t.BackgroundTransparency=1
  t.TextColor3=tint or pale; t.Font=serif and Enum.Font.Antique or Enum.Font.GothamBold; t.TextSize=size
  t.TextXAlignment=Enum.TextXAlignment.Left; t.TextWrapped=true; t.Parent=parent
  table.insert(scales,{t,size}); return t
 end
 local function stroke(o,tint,thickness)
  local s=Instance.new("UIStroke"); s.Color=tint; s.Thickness=thickness or 1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=o; return s
 end
 local function round(o,r)
  local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r); c.Parent=o
 end
 local function icon(parent,name,x,y,w,h)
  local i=Instance.new("ImageLabel"); i.Name=name.."Art"; i.BackgroundTransparency=1; i.Image=Assets.image
  local slot=Assets.slots[name]; i.ImageRectOffset=Vector2.new(slot%4*Assets.size,math.floor(slot/4)*Assets.size)
  i.ImageRectSize=Vector2.new(Assets.size,Assets.size); i.ScaleType=Enum.ScaleType.Fit
  i.Position=UDim2.fromOffset(x,y); i.Size=UDim2.fromOffset(w,h); i.Parent=parent; return i
 end
 local function button(name,parent,callback)
  local b=Instance.new("TextButton"); b.Name=name; b.Text=""; b.BackgroundTransparency=1; b.AutoButtonColor=false
  b.Active=true; b.Selectable=true; b.Parent=parent; table.insert(controls,b)
  table.insert(connections,b.Activated:Connect(function() if b.Active then callback() end end))
  return b
 end
 local function enable(b,on) b.Active=on; b.Selectable=on; b:SetAttribute("Available",on) end
 local goal=button("Goal",root,callbacks.quest)
 local level=label("Level",goal,"—",16,gold); level.Size=UDim2.fromOffset(32,44)
 local goalText=label("Objective",goal,"",13,pale); goalText.Position=UDim2.fromOffset(38,0); goalText.Size=UDim2.new(1,-38,1,0)
 local track=frame("Progress",goal); track.BackgroundTransparency=.5; track.BackgroundColor3=gold
 track.Position=UDim2.new(0,38,1,-4); track.Size=UDim2.new(1,-38,0,2)
 local fill=frame("Completed",track); fill.BackgroundTransparency=0; fill.BackgroundColor3=gold; fill.Size=UDim2.fromScale(0,1)
 local counters={}; local counterFrames={}
 for _,name in ipairs({"gold","essence"}) do
  local f=frame(name); counterFrames[name]=f; icon(f,name,0,2,36,38)
  local t=label("Amount",f,"—",23,name=="gold" and gold or pale)
  t.Position=UDim2.fromOffset(38,0); t.Size=UDim2.new(1,-38,1,0); t.TextStrokeColor3=ink; t.TextStrokeTransparency=.45
  local limit=Instance.new("UITextSizeConstraint"); limit.MinTextSize=14; limit.MaxTextSize=23; limit.Parent=t; t.TextScaled=true
  counters[name]=t
 end
 local nav=frame("QuickNavigation"); local more=frame("MoreRoutes"); more.Visible=false
 more.BackgroundTransparency=.07; more.BackgroundColor3=color(52,36,61); round(more,10); stroke(more,color(137,97,58))
 local function route(name,art,caption,parent,index,count,activate)
  local b=button(name,parent,activate or function() moreOpen=false; callbacks.open(Model.routes[name]) end)
  b.Position=UDim2.new((index-1)/count,0,0,0); b.Size=UDim2.new(1/count,0,1,0)
  local img=icon(b,art,0,0,36,40); img.AnchorPoint=Vector2.new(.5,0); img.Position=UDim2.new(.5,0,0,0)
  local text=label("Caption",b,caption,10,pale); text.TextXAlignment=Enum.TextXAlignment.Center
  text.Position=UDim2.new(0,0,1,-20); text.Size=UDim2.new(1,0,0,20)
  return b
 end
 route("Book","book","Книга",nav,1,5); route("Familiars","owl","Спутники",nav,2,5)
 route("Brew","brew","Варка",nav,3,5); route("Lab","lab","Лаборат.",nav,4,5)
 route("More","more","Ещё",nav,5,5,function() local open=not moreOpen; callbacks.close(); moreOpen=open; more.Visible=open end)
 for j,s in ipairs({{"Shop","shop","Магазин"},{"Rewards","rewards","Награды"},{"Settings","settings","Настройки"}}) do
  local b=route(s[1],s[2],s[3],more,1,1); b.Position=UDim2.new(0,0,(j-1)/3,0); b.Size=UDim2.new(1,0,1/3,0)
  local img=b:FindFirstChild(s[2].."Art"); img.AnchorPoint=Vector2.zero; img.Position=UDim2.fromOffset(5,3); img.Size=UDim2.fromOffset(38,38)
  local caption=b.Caption; caption.Position=UDim2.fromOffset(46,0); caption.Size=UDim2.new(1,-50,1,0); caption.TextSize=12; caption.TextXAlignment=Enum.TextXAlignment.Left
 end
 local page=frame("Storybook"); page.Visible=false; page.BackgroundTransparency=0; page.BackgroundColor3=color(248,239,217)
 round(page,9); stroke(page,color(217,172,97),2)
 local gradient=Instance.new("UIGradient"); gradient.Color=ColorSequence.new(color(248,239,217),color(225,209,175)); gradient.Rotation=75; gradient.Parent=page
 local spine=frame("VioletSpine",page); spine.BackgroundTransparency=0; spine.BackgroundColor3=color(76,49,88); spine.Size=UDim2.new(0,7,1,0); round(spine,3)
 local bookmark=frame("Bookmark",page); bookmark.BackgroundTransparency=0; bookmark.BackgroundColor3=color(132,203,193); bookmark.Position=UDim2.new(1,-28,0,0); bookmark.Size=UDim2.fromOffset(10,34)
 local eyebrow=label("Eyebrow",page,"КНИГА ИСТОЧНИКА",9,ink); eyebrow.Position=UDim2.fromOffset(22,12); eyebrow.Size=UDim2.new(1,-70,0,16)
 local heading=label("Heading",page,"Гримуар",26,ink,true); heading.Position=UDim2.fromOffset(22,28); heading.Size=UDim2.new(1,-52,0,32)
 local subtitle=label("Level",page,"",11,ink); subtitle.Position=UDim2.fromOffset(22,63); subtitle.Size=UDim2.new(1,-44,0,20)
 icon(page,"book",18,85,82,65)
 local perTap=label("PerTap",page,"",13,ink); perTap.Position=UDim2.fromOffset(110,85); perTap.Size=UDim2.new(1,-130,0,28)
 local copy=label("Description",page,"Собирай эссенцию для первых зелий",11,ink); copy.Position=UDim2.fromOffset(110,113); copy.Size=UDim2.new(1,-130,0,35)
 local close=button("CloseBook",page,callbacks.close); close.Text="×"; close.Font=Enum.Font.Gotham; close.TextSize=25; close.TextColor3=ink
 close.Position=UDim2.new(1,-44,0,0); close.Size=UDim2.fromOffset(44,44)
 local collect=button("Collect",page,callbacks.collect); collect.Position=UDim2.new(0,18,1,-90); collect.Size=UDim2.new(.5,-23,0,44)
 collect.BackgroundTransparency=0; collect.BackgroundColor3=color(87,61,112); round(collect,9)
 local collectText=label("Caption",collect,"",12,pale); collectText.Size=UDim2.fromScale(1,1); collectText.TextXAlignment=Enum.TextXAlignment.Center
 local upgrade=button("Upgrade",page,callbacks.upgrade); upgrade.Position=UDim2.new(.5,5,1,-90); upgrade.Size=UDim2.new(.5,-23,0,44)
 upgrade.BackgroundTransparency=0; upgrade.BackgroundColor3=color(230,190,119); round(upgrade,9)
 local upgradeText=label("Caption",upgrade,"",11,ink); upgradeText.Size=UDim2.fromScale(1,1); upgradeText.TextXAlignment=Enum.TextXAlignment.Center
 local manage=button("AssignWorker",page,callbacks.manage); manage.Position=UDim2.new(0,18,1,-44); manage.Size=UDim2.new(1,-36,0,44)
 local reason=label("Reason",manage,"",10,ink); reason.Size=UDim2.fromScale(1,1); reason.TextXAlignment=Enum.TextXAlignment.Center
 local chooser=frame("StarterChooser")
 local chooserTitle=label("Title",chooser,"Первый спутник",20,gold,true); chooserTitle.Size=UDim2.new(1,0,0,26)
 local chooserCopy=label("Instruction",chooser,"Кого возьмём с собой?",11,pale); chooserCopy.Position=UDim2.fromOffset(0,26); chooserCopy.Size=UDim2.new(1,0,0,20)
 local selections={}; local portraits={}
 local confirm=button("ConfirmStarter",chooser,function() if Model.present(snapshot,pending,callbacks.config).canChoose then callbacks.choose(picked) end end)
 confirm.Position=UDim2.new(0,0,1,-44); confirm.Size=UDim2.fromOffset(180,44); confirm.BackgroundTransparency=.05; confirm.BackgroundColor3=color(89,62,112); round(confirm,9)
 local confirmText=label("Caption",confirm,"",12,gold); confirmText.Size=UDim2.fromScale(1,1); confirmText.TextXAlignment=Enum.TextXAlignment.Center
 local function selectChoice(id)
  if not Model.choice(id) then return end
  picked=id; confirmText.Text=Model.choice(id).confirm
  for key,line in pairs(selections) do line.Transparency=key==id and 0 or 1 end
 end
 for i,entry in ipairs(Model.choices) do
  local b=button(entry.id,chooser,function() selectChoice(entry.id) end)
  table.insert(portraits,b)
  b.Position=UDim2.new((i-1)/3,0,0,48); b.Size=UDim2.new(1/3,-6,0,70); round(b,8)
  selections[entry.id]=stroke(b,gold,2); icon(b,entry.icon,4,0,56,51)
  local name=label("Name",b,entry.name,10,pale); name.TextXAlignment=Enum.TextXAlignment.Center; name.Position=UDim2.new(0,0,1,-18); name.Size=UDim2.new(1,0,0,18)
 end
 selectChoice(picked)
 local gain=label("ConfirmedEssence",root,"",18,pale); gain.Visible=false; gain.ZIndex=12; gain.Size=UDim2.fromOffset(150,32); gain.TextStrokeTransparency=.4
 for i,b in ipairs(controls) do b.SelectionOrder=i end
 function self.hideFeedback()
  gain.Visible=false; self.untilTime=0; counters.essence.TextColor3=pale
  if self.connection then self.connection:Disconnect(); self.connection=nil end
 end
 function self.flash(amount)
  self.popupCount+=1; self.untilTime=os.clock()+1.0; gain.Text="+"..tostring(amount).." Essence"
  counters.essence.TextColor3=color(200,170,255)
  if self.connection then return end
  self.connection=RunService.Heartbeat:Connect(function()
   local camera=workspace.CurrentCamera; local anchor=callbacks.anchor(); local remaining=self.untilTime-os.clock()
   if remaining<=0 or not root.Parent or not root.Visible or not gui.Enabled or not camera or not anchor then self.hideFeedback(); return end
   local point,visible=camera:WorldToViewportPoint(anchor.Position+Vector3.new(0,3.8,0))
   local offset=GuiService:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets).Min-root.AbsolutePosition
   local x,y=point.X+offset.X+18,point.Y+offset.Y-20-(reduceMotion and 0 or (1-remaining)*12)
   gain.Position=UDim2.fromOffset(x,y); gain.TextTransparency=math.clamp(1-remaining/.3,0,1)
   gain.Visible=visible and point.Z>0 and x>0 and x+150<root.AbsoluteSize.X and y>0 and y+32<root.AbsoluteSize.Y
  end)
 end
 function self.receipt(value,owned,maxBalance)
  local amount; self.cursor,amount=Legacy.feedback(self.cursor,value,owned,maxBalance)
  if amount then self.flash(amount) end
 end
 function self.layout(width,height,touch,chatRight)
  local p=Model.layout(width,height,touch,chatRight); self.plan=p
  box(goal,p.goal); box(nav,p.nav); box(more,p.more); box(page,p.page); box(chooser,p.chooser)
  for _,b in ipairs(portraits) do b.Position=UDim2.new(b.Position.X.Scale,0,0,height<320 and 42 or 48); b.Size=UDim2.new(1/3,-6,0,height<320 and 62 or 70) end
  for name,f in pairs(counterFrames) do box(f,p[name]) end
  for _,entry in ipairs(scales) do entry[1].TextSize=entry[2]*p.scale end
  return p
 end
 function self.update(value,isPending,selected,isModal,motion)
  snapshot,pending,reduceMotion=value,isPending,motion; modal=isModal
  local data=Model.present(value,isPending,callbacks.config); bookOpen=self.bookActive==true
  counters.gold.Text=data.gold; counters.essence.Text=data.essence; level.Text=data.level; goalText.Text=data.goal; fill.Size=UDim2.fromScale(data.progress,1)
  goal.Visible=not data.intro and self.plan.goal.w>=80
  chooser.Visible=data.intro and self.plan.chooserFits; page.Visible=bookOpen
  nav.Visible=not bookOpen; if modal then moreOpen=false end; more.Visible=moreOpen and not modal
  subtitle.Text="Уровень "..data.level.." · Магия начинается здесь"; perTap.Text="+"..data.amount.." Essence за касание"
  collectText.Text="Собрать +"..data.amount; upgradeText.Text=data.upgradeText
  reason.Text=(data.upgrade.enabled and "Назначить рабочего" or data.upgrade.reason.." · Рабочие")
  enable(collect,data.canCollect); enable(upgrade,data.upgrade.enabled); enable(confirm,data.canChoose)
  collect.BackgroundTransparency=data.canCollect and 0 or .45; upgrade.BackgroundTransparency=data.upgrade.enabled and 0 or .45
  confirmText.Text=isPending and "Ожидание…" or not data.canChoose and "Недоступно" or Model.choice(picked).confirm
  root:SetAttribute("BookLevel",data.level); root:SetAttribute("UpgradeEnabled",data.upgrade.enabled)
  root:SetAttribute("SelectedMenu",selected); root:SetAttribute("Pending",isPending); self.shown=true
 end
 function self.back()
  if moreOpen then moreOpen=false; more.Visible=false; return true end
  return false
 end
 function self.blocked(extra,chatRect)
  local result={}; if chatRect then table.insert(result,chatRect) end
  local inset=GuiService:GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets).Min
  local function add(o)
   if not o.Visible then return end; local p,s=o.AbsolutePosition,o.AbsoluteSize
   if s.X>0 and s.Y>0 then table.insert(result,{x=p.X-inset.X,y=p.Y-inset.Y,w=s.X,h=s.Y}) end
  end
  for _,o in ipairs({goal,counterFrames.gold,counterFrames.essence,nav,more,page,chooser}) do add(o) end
  for _,o in ipairs(extra or {}) do if not (bookOpen and o.Name=="ContextPanel") then add(o) end end
  return result
 end
 function self.destroy()
  self.hideFeedback(); for _,c in ipairs(connections) do c:Disconnect() end
  local focused=GuiService.SelectedObject; if focused and focused:IsDescendantOf(root) then GuiService.SelectedObject=nil end
  root:Destroy()
 end
 return self
end
return View
