--!nonstrict
-- V1-03 clickable recipe book; server is authoritative for every reward and purchase.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() or workspace:GetAttribute("AlchemyV1QA")~=true then return end
local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("PotionTycoon"):WaitForChild("Shared")
local Config=require(Shared.Config)
local Alchemy=require(Shared.AlchemyV1)
local Remotes=game:GetService("ReplicatedStorage").PotionTycoon:WaitForChild("Remotes")
local State=Remotes:WaitForChild("State")
local Action=Remotes:WaitForChild("Action")
local player=Players.LocalPlayer
local book=Config.alchemyV1
local ownedState=nil
local optionalChosen={}
local gui=Instance.new("ScreenGui")
gui.Name="AlchemyPotionBook";gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
gui.DisplayOrder=100;gui.Parent=player:WaitForChild("PlayerGui")
local function corner(node,r)
 local u=Instance.new("UICorner");u.CornerRadius=UDim.new(0,r or 8);u.Parent=node
end
local function frame(parent,name,shade)
 local f=Instance.new("Frame");f.Name=name;f.BackgroundColor3=shade
 f.BorderSizePixel=0;f.Parent=parent;corner(f,10);return f
end
local ink=Color3.fromRGB(56,46,45)
local paper=Color3.fromRGB(240,226,194)
local gold=Color3.fromRGB(130,96,55)
local dark=Color3.fromRGB(51,67,65)
local function label(parent,content,height,weight,order)
 local text=Instance.new("TextLabel")
 text.BackgroundTransparency=1;text.TextColor3=ink
 text.Font=weight and Enum.Font.GothamBold or Enum.Font.Gotham
 text.TextSize=weight and 16 or 13;text.TextXAlignment=Enum.TextXAlignment.Left
 text.TextYAlignment=Enum.TextYAlignment.Center;text.TextWrapped=true
 text.Text=content;text.Size=UDim2.new(1,-12,0,height);text.LayoutOrder=order or 0
 text.Parent=parent;return text
end
local function button(parent,title,height,callback,order)
 local b=Instance.new("TextButton")
 b.Name="Action";b.Size=UDim2.new(1,-12,0,height or 33);b.LayoutOrder=order or 0
 b.Text=title;b.Font=Enum.Font.GothamMedium;b.TextSize=13;b.TextWrapped=true
 b.TextColor3=Color3.fromRGB(252,244,226)
 b.BackgroundColor3=dark;b.BorderSizePixel=0;b.Parent=parent;corner(b,7)
 b.Activated:Connect(callback);return b
end
local open=Instance.new("TextButton")
open.Name="OpenBook";open.AnchorPoint=Vector2.new(1,0)
open.Position=UDim2.new(1,-12,0,100);open.Size=UDim2.fromOffset(142,42)
open.BackgroundColor3=dark;open.TextColor3=paper
open.Font=Enum.Font.GothamBold;open.TextSize=15
open.Text="Книга зелий";open.Parent=gui;corner(open,9)
local shade=Instance.new("TextButton")
shade.Name="Backdrop";shade.Size=UDim2.fromScale(1,1);shade.BackgroundColor3=Color3.new(0,0,0)
shade.BackgroundTransparency=.38;shade.Text="";shade.Visible=false
shade.Modal=true;shade.Parent=gui
local panel=frame(shade,"BookPages",paper)
panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5)
panel.Size=UDim2.new(.92,0,.80,0)
local constraint=Instance.new("UISizeConstraint");constraint.MinSize=Vector2.new(280,230)
constraint.MaxSize=Vector2.new(700,690);constraint.Parent=panel
local title=label(panel,"Алхимическая книга зелий",46,true)
title.Position=UDim2.fromOffset(16,9);title.Size=UDim2.new(1,-86,0,42);title.TextSize=19
local close=Instance.new("TextButton")
close.Name="CloseBook";close.Position=UDim2.new(1,-55,0,10);close.Size=UDim2.fromOffset(39,39)
close.Text="×";close.Font=Enum.Font.GothamBold;close.TextSize=24
close.BackgroundColor3=Color3.fromRGB(217,201,169);close.TextColor3=ink;close.Parent=panel;corner(close,8)
local list=Instance.new("ScrollingFrame")
list.Name="RecipeList";list.Position=UDim2.fromOffset(14,61);list.Size=UDim2.new(1,-28,1,-75)
list.BackgroundTransparency=1;list.BorderSizePixel=0;list.ScrollBarThickness=4
list.CanvasSize=UDim2.new();list.AutomaticCanvasSize=Enum.AutomaticSize.Y;list.Parent=panel
local layout=Instance.new("UIListLayout")
layout.Padding=UDim.new(0,7);layout.SortOrder=Enum.SortOrder.LayoutOrder;layout.Parent=list
local function send(intent,payload)
 Action:FireServer(intent,payload)
end
local function sortedKeys(map)
 local keys={};for id in pairs(map or {}) do table.insert(keys,id) end
 table.sort(keys);return keys
end
local function requirement(id,n)
 local data=book.supplies[id]
 return (data and data.name or Config.items[id] and Config.items[id].name or id).." ×"..n
end
local function tier(state)
 return state and Alchemy.rank(Config,state.xp) or 1
end
local function render()
 for _,item in ipairs(list:GetChildren()) do if item~=layout then item:Destroy() end end
 local state=ownedState
 if not state then label(list,"Ожидание серверных данных...",42,false,1);return end
 local current=state.alchemyV1
 if type(current)~="table" then label(list,"Алхимия готовится. Обнови состояние острова.",58,false,1);return end
 local rank=tier(current)
 local order=0
 local function text(content,h,bold)
  order+=1;return label(list,content,h or 35,bold,order)
 end
 local function command(content,action,payload)
  order+=1;return button(list,content,36,function()send(action,payload)end,order)
 end
 text("Gold: "..tostring(state.gold or 0).."     Essence: "..tostring(state.essence or 0),29,true)
 text("Алхимия: "..book.classes[rank].name.." · опыт "..current.xp,30,true)
 local job=current.job
 if job then
  local recipe=book.recipes[job.recipeId]
  text("Котёл занят: "..recipe.name.."  "..job.progress.."/"..job.duration.." сек",40,true)
 else
  text("Котёл свободен. Для варки подойди к лабораторной станции.",40,false)
 end
 text("РЕЦЕПТЫ",28,true)
 for classIndex,class in ipairs(book.classes) do
  text(classIndex..". "..class.name.."  (опыт "..class.minXP.."+)",35,true)
  local present=false
  for _,id in ipairs(book.recipeOrder) do
   local recipe=book.recipes[id]
   if recipe.class==classIndex then
    present=true
    local locked=rank<recipe.class or (state.stations.cauldron and state.stations.cauldron.level or 0)<recipe.minCauldron
    local prefix=locked and "[Недоступно] " or ""
    text(prefix..recipe.name.." · "..recipe.duration.."с · "..recipe.essence.." Essence",46,true)
    text("База: "..requirement(recipe.base.id,recipe.base.amount),27,false)
    local core={}
    for itemId,n in pairs(recipe.core) do table.insert(core,requirement(itemId,n)) end
    table.sort(core)
    text("Основа: "..table.concat(core,", "),38,false)
    text("Котёл: уровень "..recipe.minCauldron.." · класс "..book.classes[recipe.class].name..
      " · ориентир продажи от "..recipe.goldValue.." Gold",52,false)
    if recipe.optional then
     local selected=optionalChosen[id]==true
     order+=1
     button(list,(selected and "Дополнительно: ВКЛ · " or "Дополнительно: ВЫКЛ · ")..
       requirement(recipe.optional.id,recipe.optional.amount),38,function()
        optionalChosen[id]=not selected;render()
       end,order)
    end
    if not locked then
     command("Сварить: "..recipe.name,"craftPotion",{
      recipeId=id,optionalId=optionalChosen[id] and recipe.optional and recipe.optional.id or "",
     })
    end
   end
  end
  if not present then text("Рецепты этого класса появятся позднее.",28,false) end
 end
 text("ЛАВКА КОМПОНЕНТОВ",32,true)
 for _,id in ipairs(sortedKeys(book.supplies)) do
  local def=book.supplies[id]
  command("Купить "..def.name.." за "..def.gold.." Gold · есть "..(current.supplies[id] or 0),
    "buyAlchemySupply",{itemId=id,amount=1})
 end
 text("ГОТОВЫЕ ЗЕЛЬЯ · "..#sortedKeys(current.owned),32,true)
 if not next(current.owned) then text("После варки зелье попадёт сюда. Продажа выполняется отдельно.",43,false) end
 for _,id in ipairs(sortedKeys(current.owned)) do
  local item=current.owned[id]
  local info=Alchemy.describe(Config,item)
  if info then
   text(info.name.." · "..info.rarity.." · "..item.price.." Gold",49,true)
   text("Эффект: "..info.effectId.." (параметры заглушки, бонус ещё не действует)",36,false)
   command("Продать за "..item.price.." Gold","sellPotion",{potionId=id})
  end
 end
end
local function show(visible)
 shade.Visible=visible;open.Visible=not visible
 if visible then render() end
end
open.Activated:Connect(function()show(true)end)
close.Activated:Connect(function()show(false)end)
shade.Activated:Connect(function()show(false)end)
State.OnClientEvent:Connect(function(value)
 if type(value)=="table" then
  ownedState=value
  if shade.Visible then render() end
 end
end)
script.Destroying:Connect(function()gui:Destroy()end)
