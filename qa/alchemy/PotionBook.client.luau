--!nonstrict
-- Empty, client-only recipe book. Recipes will be added after their gameplay contract is approved.
-- No DataStore, currency, remotes or local reward calculation.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() or workspace:GetAttribute("AlchemyFirstQA")~=true then return end
local Players=game:GetService("Players")
local user=Players.LocalPlayer
local gui=Instance.new("ScreenGui")
gui.Name="AlchemyPotionBook";gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
gui.DisplayOrder=100;gui.Parent=user:WaitForChild("PlayerGui")
local function rounded(parent)
 local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,12);c.Parent=parent
end
local button=Instance.new("TextButton")
button.Name="OpenBook";button.AnchorPoint=Vector2.new(1,0)
button.Position=UDim2.new(1,-12,0,104);button.Size=UDim2.fromOffset(136,42)
button.BackgroundColor3=Color3.fromRGB(54,66,63)
button.TextColor3=Color3.fromRGB(242,230,210)
button.Font=Enum.Font.GothamMedium;button.TextSize=15
button.Text="Книга зелий";button.Parent=gui;rounded(button)
local shade=Instance.new("TextButton")
shade.Name="Backdrop";shade.Size=UDim2.fromScale(1,1)
shade.BackgroundColor3=Color3.new(0,0,0);shade.BackgroundTransparency=.42
shade.Text="";shade.Visible=false;shade.Modal=true;shade.Parent=gui
local panel=Instance.new("Frame")
panel.Name="PotionBookPages";panel.AnchorPoint=Vector2.new(.5,.5)
panel.Position=UDim2.fromScale(.5,.5);panel.Size=UDim2.new(.88,0,.65,0)
panel.BackgroundColor3=Color3.fromRGB(236,222,192);panel.Parent=shade;rounded(panel)
local constraint=Instance.new("UISizeConstraint")
constraint.MinSize=Vector2.new(260,190);constraint.MaxSize=Vector2.new(560,420)
constraint.Parent=panel
local title=Instance.new("TextLabel")
title.Name="Title";title.Position=UDim2.fromOffset(18,16)
title.Size=UDim2.new(1,-88,0,40);title.BackgroundTransparency=1
title.Text="Книга зелий";title.TextXAlignment=Enum.TextXAlignment.Left
title.TextColor3=Color3.fromRGB(50,42,41)
title.Font=Enum.Font.GothamBold;title.TextSize=24;title.Parent=panel
local close=Instance.new("TextButton")
close.Name="CloseBook";close.Position=UDim2.new(1,-54,0,12)
close.Size=UDim2.fromOffset(40,40);close.Text="×";close.TextSize=28
close.TextColor3=Color3.fromRGB(50,42,41)
close.BackgroundColor3=Color3.fromRGB(216,199,169);close.Parent=panel;rounded(close)
local list=Instance.new("ScrollingFrame")
list.Name="Recipes";list.Position=UDim2.fromOffset(18,68)
list.Size=UDim2.new(1,-36,1,-86);list.BackgroundTransparency=1
list.BorderSizePixel=0;list.ScrollBarThickness=4;list.CanvasSize=UDim2.new()
list.AutomaticCanvasSize=Enum.AutomaticSize.Y;list.Parent=panel
local layout=Instance.new("UIListLayout")
layout.Padding=UDim.new(0,8);layout.Parent=list
local placeholder=Instance.new("TextLabel")
placeholder.Name="EmptyRecipes";placeholder.LayoutOrder=1
placeholder.Size=UDim2.new(1,-8,0,100);placeholder.BackgroundTransparency=1
placeholder.TextColor3=Color3.fromRGB(104,89,73)
placeholder.Font=Enum.Font.Gotham;placeholder.TextWrapped=true;placeholder.TextSize=17
placeholder.Text="Пока здесь нет открытых рецептов.\nРецепты добавим на следующем этапе."
placeholder.Parent=list
local function show(value)
 shade.Visible=value;button.Visible=not value
end
button.Activated:Connect(function()show(true)end)
close.Activated:Connect(function()show(false)end)
shade.Activated:Connect(function()show(false)end)
