--!nonstrict
-- PHASE A STATIC ART REVIEW ONLY. Not included by default.project.json.
-- No selection callbacks, rewards, gameplay remote or persistent changes.
local Run=game:GetService("RunService")
if not Run:IsStudio() then return end
local Players=game:GetService("Players")
local CAS=game:GetService("ContextActionService")
local Prompts=game:GetService("ProximityPromptService")
local GuiService=game:GetService("GuiService")
local Shared=game.ReplicatedStorage:WaitForChild("PotionTycoon"):WaitForChild("Shared")
local Config=require(Shared.Config)
local Atlas=require(Shared.ui.ArcadeAssets)
local player=Players.LocalPlayer
local gui=player:WaitForChild("PlayerGui"):WaitForChild("PotionTycoonUI")
local world=workspace:WaitForChild("PotionTycoonWorld")
while not player:GetAttribute("PotionPlotIndex") do task.wait(.1) end
local plot=world:WaitForChild("Plot_"..player:GetAttribute("PotionPlotIndex"))
local crystal=plot:WaitForChild("crystal")
plot:WaitForChild("SpellbookLectern",20)
local Controller=require(script.Parent:WaitForChild("PotionTycoon").EnvironmentController)
while not Controller.view do task.wait(.1) end
task.wait(2) -- Let inherited owners bind before taking the bounded QA lease.
local controls=require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
local camera=workspace.CurrentCamera
local savedCamera={kind=camera.CameraType,cf=camera.CFrame,fov=camera.FieldOfView}
local savedMotion=Controller.reduceMotion
local savedPrompts=Prompts.Enabled
local savedEnvironment={}
local savedGui={}
local hidden,alpha,ui,physical={}, {}, {}, {}
-- Backdrop and input shield cover the viewport; only card content uses safe insets.
local layer=Instance.new("Frame"); layer.Name="AG72DesignReview"; layer.Size=UDim2.fromScale(1,1)
layer.BackgroundTransparency=1; layer.ZIndex=100; layer.Active=true; layer.Parent=gui
layer:SetAttribute("Phase","A_STATIC_NO_GRANT")
local backdrop=Instance.new("TextButton"); backdrop.Name="Backdrop"; backdrop.Size=UDim2.fromScale(1,1)
backdrop.BackgroundColor3=Color3.fromRGB(12,18,29); backdrop.BackgroundTransparency=.38; backdrop.BorderSizePixel=0
backdrop.Text=""; backdrop.AutoButtonColor=false; backdrop.Active=true; backdrop.Selectable=false; backdrop.Modal=true
backdrop.ZIndex=101; backdrop.Parent=layer
local root=Instance.new("Frame"); root.Name="SafeContent"; root.BackgroundTransparency=1
root.ZIndex=102; root.Parent=layer
local running=false
local function stash(o)
 if o and o.Parent and not hidden[o] then hidden[o]=o.Parent; o.Parent=nil end
end
local function invisible(o)
 if o:IsA("BasePart") and alpha[o]==nil then alpha[o]=o.LocalTransparencyModifier; o.LocalTransparencyModifier=1 end
end
local function focus()
 savedCamera={kind=camera.CameraType,cf=camera.CFrame,fov=camera.FieldOfView}
 savedMotion=Controller.reduceMotion; savedPrompts=Prompts.Enabled
 savedGui={insets=gui.ScreenInsets,clip=gui.ClipToDeviceSafeArea,compatibility=gui.SafeAreaCompatibility,selected=GuiService.SelectedObject}
 gui.ScreenInsets=Enum.ScreenInsets.None; gui.ClipToDeviceSafeArea=false
 gui.SafeAreaCompatibility=Enum.SafeAreaCompatibility.None; GuiService.SelectedObject=nil
 savedEnvironment={pose=Controller.view.pose,hour=Controller.view.clockHour,weather=Controller.view.weather,preview=Controller.view.previewStart~=nil}
 -- Remove whole inert presentations from the local world, preserving instances
 -- and their original parents. Server FirstSessionReveal stays authoritative.
 for _,p in ipairs(world:GetChildren()) do if p:GetAttribute("PlotIndex") then
  for _,o in ipairs(p:GetChildren()) do
   if o:IsA("BasePart") and o.Name~="Floor" then
    invisible(o); physical[o]={o.CanCollide,o.CanTouch,o.CanQuery}; o.CanCollide=false; o.CanTouch=false; o.CanQuery=false
   end
   if o.Name=="PilotProps" then for _,model in ipairs(o:GetChildren()) do
    if not model.Name:match("^Lantern_") then stash(model) end
   end end
  end
 end end
 stash(world:FindFirstChild("TradePost"))
 stash(workspace:FindFirstChild("FarmAffordance"))
 if player.Character then for _,o in ipairs(player.Character:GetDescendants()) do invisible(o) end end
 for _,o in ipairs(gui:GetChildren()) do if o:IsA("GuiObject") and o~=layer then
  ui[o]=o.Visible; o.Visible=false
 end end
 Prompts.Enabled=false; controls:Disable()
 CAS:BindActionAtPriority("AG72StaticReviewInput",function() return Enum.ContextActionResult.Sink end,false,5000,
  Enum.UserInputType.MouseButton1,Enum.UserInputType.MouseButton2,Enum.UserInputType.Touch,
  Enum.KeyCode.E,Enum.KeyCode.F,Enum.KeyCode.X,Enum.KeyCode.Space,Enum.KeyCode.ButtonA,Enum.KeyCode.ButtonB,Enum.KeyCode.ButtonX,Enum.KeyCode.ButtonY,Enum.KeyCode.ButtonR1,
  Enum.KeyCode.M,Enum.KeyCode.I,Enum.KeyCode.P,Enum.KeyCode.DPadLeft,Enum.KeyCode.DPadRight,Enum.KeyCode.DPadUp,Enum.KeyCode.DPadDown,
  Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right)
 Controller.setReduceMotion(true); Controller.view.setPreview(false); Controller.view.setPose("day")
 camera.CameraType=Enum.CameraType.Scriptable; camera.FieldOfView=49
 camera.CFrame=CFrame.lookAt(crystal.Position+Vector3.new(18,9,29),crystal.Position+Vector3.new(0,1,0))
end
local function restore()
 for o,parent in pairs(hidden) do if parent.Parent then o.Parent=parent end end; table.clear(hidden)
 for o,value in pairs(alpha) do if o.Parent then o.LocalTransparencyModifier=value end end; table.clear(alpha)
 for o,value in pairs(physical) do if o.Parent then o.CanCollide=value[1]; o.CanTouch=value[2]; o.CanQuery=value[3] end end; table.clear(physical)
 for o,value in pairs(ui) do if o.Parent then o.Visible=value end end; table.clear(ui)
 gui.ScreenInsets=savedGui.insets; gui.ClipToDeviceSafeArea=savedGui.clip; gui.SafeAreaCompatibility=savedGui.compatibility
 if savedGui.selected and savedGui.selected.Parent then GuiService.SelectedObject=savedGui.selected end
 Prompts.Enabled=savedPrompts; controls:Enable(); CAS:UnbindAction("AG72StaticReviewInput")
 Controller.setReduceMotion(savedMotion==true); Controller.view.setPose(savedEnvironment.pose)
 if savedEnvironment.hour~=nil then Controller.view.setTime(savedEnvironment.hour) end
 if savedEnvironment.weather~=nil then Controller.view.setWeather(savedEnvironment.weather) end
 if savedEnvironment.preview then Controller.view.setPreview(true) end
 camera.CameraType=savedCamera.kind; camera.CFrame=savedCamera.cf; camera.FieldOfView=savedCamera.fov
end
local C=Color3.fromRGB
local cream=C(255,239,200); local muted=C(195,202,211)
local roles={farmer={"ВЫРАЩИВАНИЕ","Больше силы для твоих грядок","owl",C(161,218,159),"Farming"},
 slime={"ПЕРЕНОСКА","Помощник в доставке ресурсов","slime",C(120,219,217),"Hauling"},
 brewer={"АЛХИМИЯ","Самый сильный старт в варке","cat",C(202,166,245),"Brewing"}}
local function frame(parent,name,x,y,w,h,tint,transparency)
 local o=Instance.new("Frame"); o.Name=name; o.BorderSizePixel=0; o.Position=UDim2.fromOffset(x,y); o.Size=UDim2.fromOffset(w,h)
 o.BackgroundColor3=tint or C(24,28,43); o.BackgroundTransparency=transparency or 0; o.ZIndex=parent.ZIndex+1; o.Parent=parent; return o
end
local function round(o,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r); c.Parent=o end
local function stroke(o,tint,thickness,transparency)
 local s=Instance.new("UIStroke"); s.Color=tint; s.Thickness=thickness; s.Transparency=transparency or 0; s.Parent=o
end
local function label(parent,text,x,y,w,h,size,tint,font)
 local o=Instance.new("TextLabel"); o.Name="Copy"; o.BackgroundTransparency=1; o.Text=text; o.TextColor3=tint or cream
 o.Font=font or Enum.Font.GothamMedium; o.TextSize=size; o.TextWrapped=true
 o.Position=UDim2.fromOffset(x,y); o.Size=UDim2.fromOffset(w,h); o.ZIndex=parent.ZIndex+5; o.Parent=parent; return o
end
local function picture(parent,art,x,y,size)
 local o=Instance.new("ImageLabel"); o.Name=art.."Portrait"; o.Image=Atlas.image; o.BackgroundTransparency=1
 local slot=Atlas.slots[art]; o.ImageRectOffset=Vector2.new(slot%4*Atlas.size,math.floor(slot/4)*Atlas.size)
 o.ImageRectSize=Vector2.new(Atlas.size,Atlas.size); o.Position=UDim2.fromOffset(x,y); o.Size=UDim2.fromOffset(size,size)
 o.ZIndex=parent.ZIndex+4; o.Parent=parent
end
local function rebuild()
 for _,o in ipairs(root:GetChildren()) do o:Destroy() end
 local pose=workspace:GetAttribute("AG72DesignPose") or "cards"
 if pose=="off" then if running then running=false; restore() end; layer.Visible=false; return end
 if not running then running=true; focus() end
 layer.Visible=true; backdrop.Visible=pose~="scene"
 local safe=GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)
 local offset=safe.Min-layer.AbsolutePosition
 root.Position=UDim2.fromOffset(offset.X,offset.Y); root.Size=UDim2.fromOffset(safe.Width,safe.Height)
 local w,h=safe.Width,safe.Height; if w<1 or h<1 then return end
 layer:SetAttribute("Pose",pose)
 label(root,"AG-72 · ХУДОЖЕСТВЕННЫЙ МАКЕТ · ВЫДАЧА НЕ ПОДКЛЮЧЕНА",0,h-20,w,18,10,muted)
 if pose=="scene" then return end
 local compact=h<440; local narrow=w<h
 local selected=workspace:GetAttribute("AG72DesignSelected") or "farmer"
 local confirmation=pose=="confirm"
 label(root,confirmation and "Ваш первый союзник" or "Магия начинается с дружбы",12,compact and 0 or 24,w-24,compact and 29 or 44,compact and 24 or 38,cream,Enum.Font.Antique)
 label(root,confirmation and "Один спутник. Начало большой истории." or "Выбери спутника для своей будущей мастерской",12,compact and 29 or 70,w-24,18,compact and 11 or 14,muted)
 local count=confirmation and 1 or 3
 local gap=compact and 12 or 26
 local cardW=math.min(286,(w-32-gap*(count-1))/count)
 local cardH=math.min(438,h-(compact and 80 or 166))
 local top=compact and 55 or math.max(110,(h-cardH)*.42)
 local container=root
 if narrow and not confirmation then
  cardW=math.min(300,w-36); cardH=380; top=85
  container=Instance.new("ScrollingFrame"); container.Name="PortraitScroll"; container.BackgroundTransparency=1; container.BorderSizePixel=0
  container.Position=UDim2.fromOffset(0,top); container.Size=UDim2.new(1,0,1,-top-24)
  container.CanvasSize=UDim2.fromOffset(0,3*(cardH+20)); container.ScrollBarThickness=4; container.ZIndex=root.ZIndex+1; container.Parent=root
 end
 local index=0
 for _,pet in ipairs(Config.starterPets) do if not confirmation or pet.species==selected then
  index+=1; local role=assert(roles[pet.species]); local chosen=pet.species==selected
  local x=(w-(cardW*count+gap*(count-1)))/2+(index-1)*(cardW+gap)
  local y=top+(chosen and 0 or (compact and 4 or 12))
  if narrow and not confirmation then x=(w-cardW)/2; y=(index-1)*(cardH+20)+4 end
  local card=frame(container,pet.species,x,y,cardW,cardH,chosen and C(38,43,54) or C(29,31,47),.04); round(card,14)
  stroke(card,chosen and cream or role[4],chosen and 2 or 1,chosen and .05 or .35)
  for i=1,3 do
   local glow=frame(card,"SoftFrame",-i*3,-i*3,cardW+i*6,cardH+i*6,nil,1); round(glow,14+i*3); stroke(glow,role[4],2,.84+i*.035)
  end
  local gradient=Instance.new("UIGradient"); gradient.Color=ColorSequence.new(C(255,255,255),C(120,110,155)); gradient.Rotation=90; gradient.Parent=card
  local gem=frame(card,"Crest",cardW/2-5,-5,10,10,chosen and cream or role[4],0); gem.Rotation=45; stroke(gem,C(65,64,86),2)
  local small=cardH<320; local artSize=small and math.max(52,cardH*.27) or 146
  local halo=frame(card,"PortraitHalo",cardW/2-artSize*.43,small and 10 or 32,artSize*.86,artSize*.86,role[4],.92); round(halo,200); stroke(halo,role[4],1,.65)
  picture(card,role[3],(cardW-artSize)/2,small and 4 or 18,artSize)
  local nameY=small and artSize+7 or 171
  local title=pet.name:gsub("%a[%w']*",function(word) return word:sub(1,1):upper()..word:sub(2) end)
  label(card,title,8,nameY,cardW-16,26,small and 19 or 26,cream,Enum.Font.Antique)
  label(card,role[1],8,nameY+28,cardW-16,16,small and 9 or 11,role[4],Enum.Font.GothamBold)
  if not small then label(card,role[2],18,nameY+50,cardW-36,32,13,muted) end
  local statY=small and nameY+48 or 278
  for k,stat in ipairs({"Farming","Hauling","Brewing"}) do
   local sw=(cardW-24)/3; local sx=12+(k-1)*sw; local primary=stat==role[5]
   label(card,tostring(pet.stats[stat]),sx,statY,sw,small and 23 or 31,small and 20 or 28,primary and role[4] or cream,Enum.Font.GothamBold)
   label(card,({"Выращивание","Переноска","Варка"})[k],sx,statY+(small and 24 or 34),sw,14,small and 8 or 10,primary and role[4] or muted)
  end
  local actionY=cardH-(confirmation and 80 or 56)
  local action=frame(card,"IllustratedAction",12,actionY,cardW-24,44,chosen and role[4] or C(61,58,80),0); round(action,8)
  label(action,confirmation and ("Начать с "..title) or "Выбрать",4,0,cardW-32,44,small and 12 or 14,chosen and C(25,39,43) or cream,Enum.Font.GothamBold)
  if confirmation then label(card,"Вернуться к трём картам",8,cardH-32,cardW-16,24,11,muted) end
  card:SetAttribute("Species",pet.species); card:SetAttribute("StatsFrom","Config.starterPets")
 end end
 print("AG72 DESIGN",pose,selected,w,h,"STATIC / NO GRANT")
end
local connections={}
table.insert(connections,layer:GetPropertyChangedSignal("AbsoluteSize"):Connect(rebuild))
table.insert(connections,GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(rebuild))
for _,key in ipairs({"AG72DesignPose","AG72DesignSelected"}) do table.insert(connections,workspace:GetAttributeChangedSignal(key):Connect(rebuild)) end
-- Keep only the review layer visible while the inherited snapshot UI updates.
table.insert(connections,Run.RenderStepped:Connect(function()
 if not running then return end
 for _,o in ipairs(gui:GetChildren()) do if o:IsA("GuiObject") and o~=layer then
  if ui[o]==nil then ui[o]=o.Visible end; o.Visible=false
 end end
 camera.CameraType=Enum.CameraType.Scriptable
end))
script.Destroying:Connect(function() for _,c in ipairs(connections) do c:Disconnect() end; if running then restore() end; layer:Destroy() end)
rebuild()
