--!nonstrict
-- AG75: one modal, responsive, first-session card view owned by Main.client.
-- It uses the existing chooseStarter intent; only the server awards a familiar.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local GuiService=game:GetService("GuiService")
local ContextActionService=game:GetService("ContextActionService")
local Model=require(ReplicatedStorage.PotionTycoon.Shared.StarterCardsModel)
local Atlas=require(ReplicatedStorage.PotionTycoon.Shared.ui.ArcadeAssets)
local View={}
local C=Color3.fromRGB
local cream=C(255,239,200)
local muted=C(190,202,214)
local controls={Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,
 Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right,
 Enum.KeyCode.Space,Enum.KeyCode.E,Enum.KeyCode.F,Enum.KeyCode.X,
 Enum.KeyCode.M,Enum.KeyCode.I,Enum.KeyCode.P,Enum.KeyCode.G,Enum.KeyCode.Tab}
local function round(o,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r); c.Parent=o end
local function label(parent,name,text,size,tint,font)
 local l=Instance.new("TextLabel");l.Name=name;l.Text=text;l.Font=font or Enum.Font.GothamMedium
 l.TextColor3=tint or cream;l.TextSize=size;l.TextWrapped=true;l.TextXAlignment=Enum.TextXAlignment.Center
 l.BackgroundTransparency=1;l.Size=UDim2.fromScale(1,1);l.ZIndex=parent.ZIndex+2;l.Parent=parent
 return l
end
local function frame(parent,name,x,y,w,h,tint,transparency)
 local f=Instance.new("Frame");f.Name=name;f.BorderSizePixel=0;f.Position=UDim2.fromOffset(x,y)
 f.Size=UDim2.fromOffset(w,h);f.BackgroundColor3=tint or C(29,31,47)
 f.BackgroundTransparency=transparency or 0;f.ZIndex=parent.ZIndex+1;f.Parent=parent;return f
end
local function stroke(o,c,t,a)
 local s=Instance.new("UIStroke");s.Color=c;s.Thickness=t or 1;s.Transparency=a or 0;s.Parent=o;return s
end
local function picture(parent,key,x,y,size)
 local i=Instance.new("ImageLabel");i.Name=key.."Portrait";i.BackgroundTransparency=1
 i.Image=Atlas.image;local slot=Atlas.slots[key]
 i.ImageRectOffset=Vector2.new((slot%4)*Atlas.size,math.floor(slot/4)*Atlas.size)
 i.ImageRectSize=Vector2.new(Atlas.size,Atlas.size)
 i.Position=UDim2.fromOffset(x,y);i.Size=UDim2.fromOffset(size,size)
 i.ZIndex=parent.ZIndex+3;i.Parent=parent;return i
end
function View.new(playerGui,config,choose)
 local screen=Instance.new("ScreenGui");screen.Name="StarterCardsAG75"
 screen.ResetOnSpawn=false;screen.DisplayOrder=120
 screen.ScreenInsets=Enum.ScreenInsets.None;screen.SafeAreaCompatibility=Enum.SafeAreaCompatibility.None
 screen.ClipToDeviceSafeArea=false;screen.Enabled=false;screen.Parent=playerGui
 local backdrop=Instance.new("TextButton");backdrop.Name="FullViewportBackdrop";backdrop.Text=""
 backdrop.Size=UDim2.fromScale(1,1);backdrop.BackgroundColor3=C(10,16,29)
 backdrop.BackgroundTransparency=.12;backdrop.BorderSizePixel=0;backdrop.Modal=true
 backdrop.AutoButtonColor=false;backdrop.ZIndex=1;backdrop.Parent=screen
 local content=frame(backdrop,"SafeContent",0,0,0,0,C(0,0,0),1)
 content.Active=false
 local entries=Model.cards(config)
 local self={screen=screen,selected=nil,stage="cards",pending=false,shown=false,
  ready=false,reduced=false,notification=nil,items={},connections={},persistent={},requestToken=0}
 local function title(parent,value,y,size,tint,font)
  local t=label(parent,"Text",value,size,tint,font);t.Position=UDim2.fromOffset(0,y)
  t.Size=UDim2.new(1,0,0,32);return t
 end
 local function button(parent,name,text,y,height,click,tint)
  local b=Instance.new("TextButton");b.Name=name;b.Text=text;b.Font=Enum.Font.GothamBold
  b.TextSize=13;b.TextColor3=C(24,36,43);b.BackgroundColor3=tint or cream
  b.AutoButtonColor=true;b.Size=UDim2.new(1,-24,0,height or 44)
  b.Position=UDim2.new(0,12,0,y);b.ZIndex=parent.ZIndex+4;b.Parent=parent
  round(b,9);table.insert(self.connections,b.Activated:Connect(click));return b
 end
 local function clear()
  table.clear(self.items)
  for _,obj in ipairs(content:GetChildren()) do obj:Destroy() end
  for _,conn in ipairs(self.connections) do conn:Disconnect() end
  table.clear(self.connections)
 end
 local rebuild
 rebuild=function()
  clear()
  local rect=GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)
  local origin=rect.Min-backdrop.AbsolutePosition
  content.Position=UDim2.fromOffset(origin.X,origin.Y)
  content.Size=UDim2.fromOffset(rect.Width,rect.Height)
  local w,h=rect.Width,rect.Height;if w<1 or h<1 then return end
  local confirming=self.stage=="confirm"
  local plan=Model.layout(w,h,confirming)
  local intro=confirming and "Твой первый спутник" or "Магия начинается с дружбы"
  title(content,intro,plan.small and 0 or 12,plan.small and 24 or 34,cream,Enum.Font.Antique)
  if not plan.small then title(content,"Выбери одного фамильяра для своей мастерской",57,14,muted) end
  if self.notification then
   local errorText=title(content,self.notification,h-33,12,C(255,176,164))
   errorText.TextWrapped=true
  end
  local cardsParent=content
  if plan.scroll then
   local list=Instance.new("ScrollingFrame");list.Name="PortraitScroll";list.BackgroundTransparency=1
   list.BorderSizePixel=0;list.ScrollBarThickness=4
   list.Position=UDim2.fromOffset(0,plan.top);list.Size=UDim2.new(1,0,1,-plan.top-32)
   list.ScrollingDirection=plan.scrollHorizontal and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y
   list.CanvasSize=plan.scrollHorizontal and UDim2.fromOffset(3*(plan.width+plan.gap)+8,0)
    or UDim2.fromOffset(0,3*(plan.height+20)+8)
   list.ZIndex=content.ZIndex+1;list.Parent=content;cardsParent=list
  end
  local visibleCount=confirming and 1 or #entries
  local visibleIndex=0
  for _,entry in ipairs(entries) do
   if not confirming or entry.id==self.selected then
    visibleIndex+=1
    local chosen=entry.id==self.selected
    local width,height=plan.width,plan.height
    local x=plan.scroll and (plan.scrollHorizontal and 12+(visibleIndex-1)*(width+plan.gap) or (w-width)/2)
     or (w-(width*visibleCount+plan.gap*(visibleCount-1)))/2+(visibleIndex-1)*(width+plan.gap)
    local y=plan.scroll and (plan.scrollHorizontal and 4 or (visibleIndex-1)*(height+20)+4)
     or plan.top+(chosen and 0 or 8)
    local accent=C(table.unpack(entry.color))
    local card=Instance.new("TextButton");card.Name=entry.id;card.Text="";card.AutoButtonColor=false
    card.BackgroundColor3=chosen and C(40,44,57) or C(27,32,48)
    card.BackgroundTransparency=.02;card.Position=UDim2.fromOffset(x,y)
    card.Size=UDim2.fromOffset(width,height);card.ZIndex=cardsParent.ZIndex+1;card.Parent=cardsParent
    round(card,14);local rim=stroke(card,accent,chosen and 2.5 or 1.5,chosen and 0 or .22)
    local g=Instance.new("UIGradient");g.Color=ColorSequence.new(C(255,255,255),C(116,119,160));g.Rotation=95;g.Parent=card
    local glow=frame(card,"GlowRim",-3,-3,width+6,height+6,accent,1);round(glow,16);stroke(glow,accent,2,.78)
    local crest=frame(card,"Crest",width/2-5,-5,10,10,accent,0);crest.Rotation=45
    local small=height<330
    local artSize=small and math.max(52,math.min(94,height*.27)) or 146
    local halo=frame(card,"Halo",(width-artSize*.84)/2,small and 12 or 30,artSize*.84,artSize*.84,accent,.89)
    round(halo,100)
    picture(card,entry.icon,(width-artSize)/2,small and 4 or 18,artSize)
    local nameY=small and artSize+4 or 168
    title(card,entry.name,nameY,small and 19 or 26,cream,Enum.Font.Antique)
    title(card,entry.title,nameY+30,small and 10 or 12,accent,Enum.Font.GothamBold)
    if not small then
     local description=title(card,entry.description,nameY+53,13,muted)
     description.Size=UDim2.new(1,-18,0,42);description.Position=UDim2.fromOffset(9,nameY+53)
    end
    local statY=small and nameY+50 or 279
    for i,stat in ipairs({"Farming","Hauling","Brewing"}) do
     local sw=(width-18)/3
     local statText=label(card,stat,tostring(entry.stats[stat]),small and 19 or 27,cream,Enum.Font.GothamBold)
     statText.Position=UDim2.fromOffset(9+(i-1)*sw,statY)
     statText.Size=UDim2.fromOffset(sw,small and 25 or 33)
     local statName=label(card,stat.."Name",({"Выращивание","Переноска","Варка"})[i],small and 8 or 10,muted)
     statName.Position=UDim2.fromOffset(9+(i-1)*sw,statY+(small and 22 or 32))
     statName.Size=UDim2.fromOffset(sw,18)
    end
    local footerY=height-54
    local action=button(card,"Choose",confirming and (self.pending and "Ожидание…" or "Подтвердить выбор") or "Выбрать",
     footerY,42,function()
      if self.pending or not self.ready then return end
      if confirming then
       self.pending=true;self.notification=nil;self.requestToken+=1
       local token=self.requestToken
       rebuild();choose(self.selected)
       task.delay(10,function()
        if self.shown and self.pending and self.requestToken==token then
         self.pending=false;self.notification="Нет ответа от сервера. Проверь соединение и повтори выбор."
         rebuild()
        end
       end)
      else self.selected=entry.id;self.stage="confirm";rebuild() end
     end,accent)
    action.Active=self.ready and not self.pending
    if confirming then
     local back=Instance.new("TextButton");back.Name="Back";back.Text="← Вернуться к выбору"
     back.Font=Enum.Font.GothamMedium;back.TextSize=11;back.TextColor3=muted
     back.BackgroundTransparency=1;back.ZIndex=card.ZIndex+4;back.Parent=card
     back.Position=UDim2.fromOffset(10,height-92);back.Size=UDim2.new(1,-20,0,28)
     table.insert(self.connections,back.Activated:Connect(function()
      if not self.pending then self.stage="cards";rebuild() end
     end))
    else
     table.insert(self.connections,card.Activated:Connect(function()
      if not self.pending and self.ready then self.selected=entry.id;self.stage="confirm";rebuild() end
     end))
    end
    table.insert(self.items,{frame=card,stroke=rim,glow=glow,base=Vector2.new(x,y),phase=visibleIndex*.8})
   end
  end
 end
 local function toggle(open)
  if self.shown==open then return end
  self.shown=open;screen.Enabled=open
  if open then
   self.stage="cards";self.selected=nil;self.pending=false;self.notification=nil
   ContextActionService:BindActionAtPriority("AG75CardFocus",function()
    return Enum.ContextActionResult.Sink end,false,5000,table.unpack(controls))
   rebuild()
  else ContextActionService:UnbindAction("AG75CardFocus") end
 end
 function self.update(snapshot,pending,reduceMotion)
  local enabled=RunService:IsStudio() and workspace:GetAttribute("AG75StarterCardsEnabled")~=false
  local want=enabled and Model.intro(snapshot)
  self.ready=Model.ready(snapshot,pending)
  self.reduced=reduceMotion==true
  toggle(want)
  if want then
   for _,record in ipairs(self.items) do
    local b=record.frame:FindFirstChild("Choose")
    if b then b.Active=self.ready and not self.pending end
   end
  end
 end
 function self.notice(message)
  if not self.shown or not self.pending then return end
  self.pending=false;self.notification=message;rebuild()
 end
 table.insert(self.persistent,backdrop:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
  if self.shown then rebuild() end end))
 local canvasConnection=RunService.RenderStepped:Connect(function()
  if not self.shown or self.reduced then return end
  local t=os.clock()
  for _,entry in ipairs(self.items) do
   local phase=t*1.6+entry.phase
   entry.frame.Position=UDim2.fromOffset(entry.base.X,entry.base.Y+math.sin(phase)*3)
   entry.frame.Rotation=math.sin(phase*.75)*.55
   entry.stroke.Transparency=.10+.16*(.5+.5*math.sin(phase))
  end
 end)
 function self.destroy()
  toggle(false);canvasConnection:Disconnect()
  for _,connection in ipairs(self.connections) do connection:Disconnect() end
  for _,connection in ipairs(self.persistent) do connection:Disconnect() end
  screen:Destroy()
 end
 return self
end
return View
