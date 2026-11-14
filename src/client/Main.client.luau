--!nonstrict
-- Presentation and intent only: the client never grants currency, ingredients or pets.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("PotionTycoon"):WaitForChild("Shared")
local Config = require(shared.Config)
local ContextPolicy = require(shared.ContextUI)
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local collectionUI = require(script.Parent.CollectionUI).new(Config)
local tradeUI = require(script.Parent.TradeUI).new(Config)
local longTermUI = require(script.Parent.LongTermUI).new(Config)
local LongTerm = require(shared.LongTerm)
local Codec = require(shared.TradeCodec)
local Monetization = require(shared.Monetization)
local shopUI = require(script.Parent.ShopUI).new()
local shopPreview = require(script.Parent.ShopPreview)
local environment = require(script.Parent.EnvironmentController)
local Session = require(shared.FirstSessionView)
local Glance = require(script.Parent.TutorialGlance)
local ContextActionService = game:GetService("ContextActionService")
local MarketplaceService = game:GetService("MarketplaceService")
local remotes = ReplicatedStorage.PotionTycoon:WaitForChild("Remotes")
local Action, State, Notice, Focus = remotes:WaitForChild("Action"), remotes:WaitForChild("State"), remotes:WaitForChild("Notice"), remotes:WaitForChild("Focus")
local Ready = remotes:WaitForChild("Ready")
local TradeState = remotes:WaitForChild("TradeState")
local PurchasePrompt = remotes:WaitForChild("PurchasePrompt")

local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn = "PotionTycoonUI", false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = player:WaitForChild("PlayerGui")

local BG, SURFACE, TEXT, ACCENT = Color3.fromRGB(27, 40, 43), Color3.fromRGB(51, 68, 65), Color3.fromRGB(242, 238, 220), Color3.fromRGB(78, 101, 91)
local state, selected, petPicker, hasReport = nil, "crystal", false, false
-- AG64_BEGIN_IMPORT
local LandscapeModel=require(shared.ui.Landscape)
local LandscapeView=require(script.Parent.LandscapeHUD)
local landscape,syncLandscape,coachOpen=nil,nil,false
-- AG71_BEGIN_IMPORT
local ArcadeModel=require(shared.ui.Arcade)
local ArcadeAssets=require(shared.ui.ArcadeAssets)
local arcadeReady=false
-- AG71_END_IMPORT
-- AG64_END_IMPORT
local selectedUpgrade = false
local context, currentContext
local scrollPositions = {}
local drawnKey,drawGeneration=nil,0
local tradeState
local bindings = {}
local collectionPending = false
local pendingGeneration = 0
local collectionActions = { summon = true, shopFamiliar = true, hire = true, fuse = true, petLock = true }
local progressionActions = { build=true, advancePhase=true, equipCauldron=true, lockCauldron=true }

local function round(instance)
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 8), instance
end
local function label(parent, text, height)
	local value = Instance.new("TextLabel")
	value.BackgroundTransparency, value.TextColor3 = 1, TEXT
	value.Font, value.TextSize = Enum.Font.Gotham, 14
	value.TextWrapped, value.TextXAlignment = true, Enum.TextXAlignment.Left
	value.Size = UDim2.new(1, -8, 0, height or 40)
	value.Text, value.Parent = text, parent
	return value
end
local function button(parent, text, callback)
	local value = Instance.new("TextButton")
	value.Size = UDim2.new(1, -8, 0, 44)
	value.BackgroundColor3, value.TextColor3 = SURFACE, TEXT
	value.Font, value.TextSize, value.TextWrapped = Enum.Font.GothamMedium, 14, true
	value.Text, value.Parent = text, parent
	round(value)
	value.Activated:Connect(callback)
	return value
end
local function compact(value)
	if type(value) ~= "number" then return tostring(value) end
	local amount = math.floor(math.abs(value))
	local text = tostring(amount)
	if amount >= 1000 then
		local scaled, unit = amount, ""
		for _, name in ipairs({ "K", "M", "B", "T" }) do
			if scaled < 1000 then break end
			scaled /= 1000
			unit = name
		end
		text = string.format("%.2f", scaled)
		text = string.gsub(text, "0+$", "")
		text = string.gsub(text, "%.$", "")
		text = text .. unit
	end
	return (value < 0 and "-" or "") .. text
end
local function send(action, payload)
	if string.sub(action,1,5)=="trade" then Action:FireServer(action,payload or {}); return end
	if not state or not state.writable or collectionPending then return end
	payload = payload or {}
	if action == "buy" then
		local id = payload.upgradeId
		payload.expectedLevel = id == "pipes" and (state.pipes and 1 or 0)
			or (id == "warehouse" and state.warehouseLevel or state.stations[id].level)
		action = "build"
	end
	if collectionActions[action] or progressionActions[action] or LongTerm.isAction(action) or Monetization.isAction(action) then
		payload.requestId = payload.requestId or (Monetization.isAction(action) and state.shop.sequence+1 or LongTerm.isAction(action) and state.longTerm.requestId or (progressionActions[action] and state.progression.sequence or state.collection.sequence)+1)
		collectionPending = true
		pendingGeneration += 1
		local generation = pendingGeneration
		task.delay(10, function() if generation == pendingGeneration then collectionPending = false end end)
	end
	Action:FireServer(action, payload)
end
local function names(items)
	local parts = {}
	for id, amount in pairs(items or {}) do
		local epoch=state and state.longTerm and Config.epochRules[state.longTerm.epochId]
		if amount > 0 then table.insert(parts, (epoch and epoch.resourceNames[id] or (Config.items[id] and Config.items[id].name or id)) .. ": " .. amount) end
	end
	table.sort(parts)
	return #parts > 0 and table.concat(parts, "  ·  ") or "Пусто"
end

local hud = Instance.new("Frame")
hud.Name="ResourceBar"
hud.Size, hud.Position = UDim2.new(1, -24, 0, 76), UDim2.fromOffset(12, 10)
hud.BackgroundColor3, hud.Parent = BG, gui
	round(hud)
local balance = label(hud, "Загрузка профиля…", 36)
balance.Position, balance.Size = UDim2.fromOffset(12, 0), UDim2.new(1, -130, 0, 36)
balance.TextSize = 17
local status = label(hud, "", 32)
status.Position, status.Size = UDim2.fromOffset(12, 38), UDim2.new(1, -24, 0, 32)
status.TextSize = 11
local toggle = button(hud, "Фабрика", function() end)
toggle.Size, toggle.Position = UDim2.fromOffset(100, 34), UDim2.new(1, -112, 0, 3)

local toast = label(gui, "Подойди к кристаллу. Назначь рабочих через меню объектов.", 54)
toast.Name="Notice"; toast.Visible=false; toast.ZIndex=10
toast.Position, toast.Size = UDim2.new(0, 16, 0, 90), UDim2.new(1, -32, 0, 54)
toast.TextXAlignment = Enum.TextXAlignment.Center
toast.BackgroundColor3, toast.BackgroundTransparency = BG, 0.15
round(toast)

local panel = Instance.new("Frame")
panel.Name="ContextPanel"
panel.AnchorPoint, panel.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 146)
panel.Visible = false
panel.Size, panel.BackgroundColor3 = UDim2.new(0.94, 0, 0.67, 0), BG
panel.Parent = gui
round(panel)
local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MinSize, sizeLimit.MaxSize, sizeLimit.Parent = Vector2.new(0, 0), Vector2.new(560, 700), panel
local title = label(panel, "Управление фабрикой", 34)
title.Position = UDim2.fromOffset(12, 4)
title.Size = UDim2.new(1, -64, 0, 34)
local close = button(panel, "×", function() panel.Visible = false end)
close.Size, close.Position = UDim2.fromOffset(44, 44), UDim2.new(1, -48, 0, 0)
toggle.Activated:Connect(function() panel.Visible = not panel.Visible end)

local tabs = Instance.new("ScrollingFrame")
tabs.BorderSizePixel, tabs.ScrollBarThickness = 0, 2
tabs.AutomaticCanvasSize, tabs.CanvasSize = Enum.AutomaticSize.X, UDim2.new()
tabs.ScrollingDirection = Enum.ScrollingDirection.X
tabs.BackgroundTransparency, tabs.Size = 1, UDim2.new(1, -16, 0, 48)
tabs.Position, tabs.Parent = UDim2.fromOffset(8, 42), panel
local grid = Instance.new("UIListLayout")
grid.FillDirection, grid.Padding, grid.Parent = Enum.FillDirection.Horizontal, UDim.new(0, 4), tabs

local contents = Instance.new("ScrollingFrame")
contents.Name="Details"
contents.Position, contents.Size = UDim2.fromOffset(12, 94), UDim2.new(1, -24, 1, -106)
contents.BackgroundTransparency, contents.BorderSizePixel, contents.ScrollBarThickness = 1, 0, 4
contents.AutomaticCanvasSize, contents.CanvasSize = Enum.AutomaticSize.Y, UDim2.new()
contents.Parent = panel

local guide = button(gui, "Обучение · загрузка…", function() end)
guide.Name="Guide"
guide.BackgroundColor3 = ACCENT
local regionLabel=label(gui,"",24)
regionLabel.Name="PlotContext"; regionLabel.TextSize=12; regionLabel.TextColor3=Color3.fromRGB(232,220,184)
regionLabel.BackgroundColor3=BG; regionLabel.BackgroundTransparency=.15; regionLabel.Visible=false; round(regionLabel)
local draw, refresh
local rail=Instance.new("Frame")
rail.Name="NearbyActions"; rail.BackgroundColor3=BG; rail.Visible=false; rail.Parent=gui; round(rail)
local details=button(rail,"Подробнее",function()
	if not currentContext then return end
	selected=currentContext.public and "bazaar" or currentContext.station
	selectedUpgrade=currentContext.upgrade; petPicker=false; panel.Visible=true; draw()
end)
details.Size=UDim2.new(1,-104,1,-8); details.Position=UDim2.fromOffset(4,4)
local nextObject=button(rail,"Далее · X",function() if context then context.next() end end)
nextObject.Size=UDim2.new(0,96,1,-8); nextObject.Position=UDim2.new(1,-100,0,4)
local function updateContext(entry,count,region)
	currentContext=entry; rail.Visible=entry~=nil and not panel.Visible
	regionLabel.Visible=region~=nil and region~="Моя ферма" and not panel.Visible
	regionLabel.Text=region or ""
	if entry then
		details.Text=entry.upgrade and "Цена и условия" or "Подробнее"
		nextObject.Visible=count>1
		details.Size=UDim2.new(1,count>1 and -104 or -8,1,-8)
		nextObject.Text=UserInputService.TouchEnabled and ("Далее · "..count) or (UserInputService.GamepadEnabled and "Далее · RB" or "Далее · X")
	end
-- AG64_BEGIN_CONTEXT
	if landscape then
		rail.Visible=entry~=nil and entry.station~="crystal" and not panel.Visible and not coachOpen
		regionLabel.Visible=false
	end
-- AG64_END_CONTEXT
end
panel:GetPropertyChangedSignal("Visible"):Connect(function()
	toggle.Visible=not panel.Visible or toggle.Parent==hud
	if context then context.refresh() end
	if panel.Visible and UserInputService.GamepadEnabled then GuiService.SelectedObject=close end
-- AG64_BEGIN_PANEL
	if syncLandscape then syncLandscape() end
-- AG64_END_PANEL
end)
local prices={}
local function shopPrice(card)
	if not card.robuxAvailable or card.sku<=0 then return nil end
	local cached=prices[card.offerId]; local now=os.clock()
	if cached and cached.sku==card.sku and now<cached.untilTime then return cached.price end
	local entry={sku=card.sku,untilTime=now+30}; prices[card.offerId]=entry
	task.spawn(function()
		local ok,info=pcall(MarketplaceService.GetProductInfoAsync,MarketplaceService,card.sku,card.platformKind=="product" and Enum.InfoType.Product or Enum.InfoType.GamePass)
		if prices[card.offerId]~=entry then return end
		if ok and info and info.IsForSale==true and type(info.PriceInRobux)=="number" and info.PriceInRobux>=0 then entry.price=info.PriceInRobux end
		if selected=="shop" then draw() end
		task.delay(31,function() if selected=="shop" and prices[card.offerId]==entry then draw() end end)
	end)
	return nil
end

local chatRight,chatRect
local function readChat()
	local camera=workspace.CurrentCamera
	if not camera then return end
	local viewport=camera.ViewportSize
	local ok,active,size,position=pcall(function()
		return StarterGui:GetCore("ChatActive"),StarterGui:GetCore("ChatWindowSize"),StarterGui:GetCore("ChatWindowPosition")
	end)
	-- Read native chat bounds, never change CoreGui visibility or position. Core
	-- scripts can register late; reserve the current legacy chat's default region.
	local right,rect
	if not ok or active~=false then
		local p=typeof(position)=="UDim2" and Vector2.new(position.X.Scale*viewport.X+position.X.Offset,position.Y.Scale*viewport.Y+position.Y.Offset) or Vector2.zero
		local s=typeof(size)=="UDim2" and Vector2.new(size.X.Scale*viewport.X+size.X.Offset,size.Y.Scale*viewport.Y+size.Y.Offset) or Vector2.new(viewport.X*.4,viewport.Y*.335)
		right=p.X+s.X; rect={x=p.X,y=p.Y,w=s.X,h=s.Y+40}
	end
	local changed=right~=chatRight
	chatRight,chatRect=right,rect
	return changed
end
local function resize()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local viewport = camera.ViewportSize
	local safe=gui.AbsoluteSize
	readChat()
	local layout=ContextPolicy.layout(safe.X,safe.Y,UserInputService.TouchEnabled,chatRight)
	gui.Enabled=not layout.chatModal
	hud.Size,hud.Position=UDim2.fromOffset(layout.hudWidth,44),UDim2.fromOffset(layout.compact and 12 or layout.left,8)
	balance.TextSize=14; balance.Position=UDim2.fromOffset(12,4); balance.Size=UDim2.new(1,-114,0,36)
	toggle.Size,toggle.Position=UDim2.fromOffset(96,36),UDim2.new(1,-100,0,4)
	-- CoreGui's player list has no public bounds API. Keep the compact factory
	-- entry in the bottom centre, away from the top-right list and touch corners.
	if layout.compact then
		toggle.Parent=gui
		toggle.Size,toggle.Position=UDim2.fromOffset(layout.factory.w,layout.factory.h),UDim2.fromOffset(layout.factory.x,layout.factory.y)
		balance.Size=UDim2.new(1,-24,0,36)
	else toggle.Parent=hud end
	toggle.Visible=not panel.Visible or not layout.compact
	status.Visible=false
	guide.Position,guide.Size=UDim2.fromOffset(layout.compact and 12 or layout.left,58),UDim2.fromOffset(layout.hudWidth,44)
	regionLabel.Position,regionLabel.Size=UDim2.fromOffset(layout.compact and 12 or layout.left,106),UDim2.fromOffset(layout.hudWidth,24)
	panel.Size=UDim2.fromOffset(layout.width,layout.height)
	if layout.compact and layout.portrait then
		panel.AnchorPoint,panel.Position=Vector2.new(.5,1),UDim2.new(.5,0,1,-150)
	elseif not layout.compact then
		-- Keep the header/close button outside both native chat and player list.
		panel.AnchorPoint,panel.Position=Vector2.zero,UDim2.fromOffset(layout.left,116)
	else
		-- Touch locomotion occupies the bottom corners. Keep this sheet between them.
		panel.AnchorPoint,panel.Position=Vector2.new(.5,0),UDim2.new(.5,0,0,116)
	end
	rail.AnchorPoint,rail.Position=Vector2.new(.5,1),UDim2.new(.5,0,1,-layout.bottom)
	rail.Size=UDim2.fromOffset(layout.railWidth,48)
	toast.AnchorPoint=Vector2.new(.5,0)
	toast.Position,toast.Size=UDim2.new(.5,0,0,136),UDim2.fromOffset(layout.hudWidth,64)
	if not layout.compact then toast.AnchorPoint=Vector2.zero; toast.Position=UDim2.fromOffset(layout.left,136) end
-- AG64_BEGIN_RESIZE
	if syncLandscape then syncLandscape(true) end
-- AG64_END_RESIZE
end
task.spawn(function()
	while gui.Parent do task.wait(.5); if readChat() then resize() end end
end)
local cameraConnection
local function watchCamera()
	if cameraConnection then cameraConnection:Disconnect() end
	if workspace.CurrentCamera then cameraConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
	resize()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(resize)
guide.Activated:Connect(function()
	if not state then return end
	selected, petPicker, panel.Visible = state.tutorial.complete and "blueprint" or state.tutorial.target, false, true
	selectedUpgrade=false
	draw()
end)
local function bindText(widget, getter)
	table.insert(bindings, function() widget.Text = getter() end)
end
local function getStation()
	return state and state.stations[selected]
end
local function upgradePrice(id)
	if not state then return "…" end
	return state.builds[id] and state.builds[id].cost
end
local function assignedTo(petId)
	for id, station in pairs(state.stations) do
		if station.workerId == petId then return id end
	end
	return nil
end

draw = function()
	if drawnKey then scrollPositions[drawnKey]=contents.CanvasPosition.Y end
	drawnKey=selected..(selectedUpgrade and ":upgrade" or "")..(petPicker and ":picker" or "")
	drawGeneration+=1
	local generation=drawGeneration; local savedScroll=scrollPositions[drawnKey] or 0
	task.defer(function() if generation==drawGeneration then contents.CanvasPosition=Vector2.new(0,savedScroll) end end)
	for _, child in ipairs(contents:GetChildren()) do child:Destroy() end
	bindings = {}
	local layout = Instance.new("UIListLayout")
	layout.Padding, layout.SortOrder, layout.Parent = UDim.new(0, 7), Enum.SortOrder.LayoutOrder, contents
	local order = 0
	local function text(value, height)
		order += 1
		local object = label(contents, value, height)
		object.LayoutOrder = order
		object.AutomaticSize = Enum.AutomaticSize.Y
		return object
	end
	local function action(value, callback)
		order += 1
		local object = button(contents, value, callback)
		object.LayoutOrder = order
		return object
	end
	if state and selectedUpgrade then
		title.Text="Улучшение · "..ContextPolicy.description({station=selected},Config)
		local info=text("",92)
		bindText(info,function()
			return ContextPolicy.upgradeDetails(state,selected)
		end)
		local purchase=action("",function()
			if selected=="blueprint" then send("advancePhase",{expectedPhase=state.phase.phase})
			else send("buy",{upgradeId=selected}) end
		end)
		bindText(purchase,function()
			local price=selected=="blueprint" and state.phase.cost or upgradePrice(selected)
			return price and ("Купить · "..price.." Gold") or "Максимальный уровень"
		end)
		action("Управление объектом",function() selectedUpgrade=false; draw() end)
		refresh(); return
	end
	if selected=="bazaar" then
		title.Text="Магический базар · обмен"
		tradeUI.draw({value=tradeState,text=text,action=action,send=send,redraw=draw})
		return
	end
	if not state then text("Ожидаем безопасную загрузку профиля…"); return end
	if selected=="quality" then
		title.Text="Окружение · качество"
		text(state.mode=="STUDIO_MEMORY" and "Локальная проверка Studio: прогресс не сохраняется после Stop." or (state.writable and "Сохранение прогресса включено." or "Сохранение приостановлено."),64)
		text("Настройки действуют только на этом устройстве. Рабочие места, кнопки и производство остаются доступны.",88)
		for _,q in ipairs({{"full","Полное"},{"reduced","Умеренное"},{"minimal","Минимальное"}}) do
			action((environment.quality==q[1] and "✓ " or "")..q[2],function() environment.setQuality(q[1]); draw() end)
		end
		action("Уменьшить движение: "..(environment.reduceMotion and "да" or "нет"),function() environment.setReduceMotion(not environment.reduceMotion); draw() end)
		text("Минимальное качество и уменьшение движения отключают дождевые штрихи и покачивание листвы. Текущий выбор сохраняется до выхода.",100)
		refresh(); return
	end
	if selected=="shop" then
		title.Text="Событие / Магазин"
		shopUI.draw({state=state,text=text,action=action,send=send,redraw=draw,price=shopPrice,
			utc=function(timestamp) return DateTime.fromUnixTimestamp(timestamp):FormatUniversalTime("DD.MM.YYYY HH:mm","ru-ru") end,
			preview=function(style) order+=1; local view=shopPreview.create(contents,style); view.LayoutOrder=order end})
		refresh(); return
	end
	if selected=="supplies" then
		title.Text="Магазин ресурсов"
		text("Семена и постройки. Обмен с другими игроками — отдельно, на базаре.",48)
		local guideStep=Session.present(state,Config).step
		local seedCost=state.firstSession.seedCost
		if guideStep=="seeds" then
			action("Купить 5 семян · "..compact(seedCost*state.firstSession.openingSeeds).." Gold",function() send("buySeed",{amount=state.firstSession.openingSeeds}) end)
		else
			action("Купить 1 семя · "..compact(seedCost).." Gold",function() send("buySeed",{amount=1}) end)
			action("Купить 5 семян · "..compact(seedCost*state.firstSession.openingSeeds).." Gold",function() send("buySeed",{amount=state.firstSession.openingSeeds}) end)
		end
		if Session.offersStation(state,"garden") then action("Грядка · "..compact(state.firstSession.bedCost).." Gold",function() send("buyStarterStation",{stationId="garden"}) end)
		else text("Грядка уже построена.",32) end
		if Session.offersStation(state,"cauldron") then action("Котёл · "..compact(state.firstSession.cauldronCost).." Gold",function() send("buyStarterStation",{stationId="cauldron"}) end)
		else text("Котёл уже построен.",32) end
		if state.stations.cauldron.level>0 and not (state.automation and state.automation.brew) then
			action("Автоматизация · "..compact(state.firstSession.automationCost).." Gold",function() send("buyAutomation",{feature="basic"}) end)
		elseif state.automation and state.automation.brew then text("Автоматизация уже включена.",32) end
		local crystalPrice=upgradePrice("crystal")
		if crystalPrice then action("Кристалл · "..compact(crystalPrice).." Gold",function() send("buy",{upgradeId="crystal"}) end)
		else text("Кристалл уже максимального уровня.",32) end
		refresh(); return
	end
	if selected=="inventory" then
		title.Text="Инвентарь"
		text("Семена: "..names(state.seeds),48)
		text("Склад: "..names(state.inventory),48)
		text("Для заказа: "..names(state.questStock),48)
		refresh(); return
	end
	if selected=="familiars" then
		title.Text="Фамильяры"
		local choice=state.starter and state.starter.choice
		text(choice and ("Стартовый выбор: "..(Config.petSpecies[choice] and Config.petSpecies[choice].name or choice)) or "Стартовый фамильяр ещё не выбран.",48)
		local ids={}
		for id in pairs(state.pets) do table.insert(ids,id) end
		table.sort(ids)
		if #ids==0 then text("Фамильяров пока нет.",36) end
		for _,id in ipairs(ids) do
			local pet=state.pets[id]
			text(pet.name.." · "..tostring(pet.species or ""),36)
		end
		refresh(); return
	end
	if selected=="rebirth" or selected=="dailies" or selected=="shards" then
		title.Text=selected=="rebirth" and "Rebirth · новая эпоха" or (selected=="dailies" and "Ежедневные награды" or "Time Shards · магазин")
		longTermUI.draw({state=state,currentState=function() return state end,bindText=bindText,mode=selected,text=text,action=action,send=send,redraw=draw}); refresh(); return
	end
	if not state.tutorial.complete and selected==state.tutorial.target then
		local tutorial = text("", 54)
		bindText(tutorial, function() return state.tutorial.text end)
	end
	if state.starter and not state.starter.legacyGrant and not state.starter.claimed then
-- AG71_BEGIN_STARTER
		if not (landscape and landscape.arcade and landscape.plan and landscape.plan.chooserFits) then
-- AG71_END_STARTER
		text("Новый участок уже содержит храм и кристалл. Выбери ровно одного фамильяра у алтаря. Повторный выбор не создаст второго.", 72)
		for _, speciesId in ipairs({ "farmer", "slime", "brewer" }) do
			action("Выбрать: " .. Config.petSpecies[speciesId].name, function() send("chooseStarter", { speciesId = speciesId }) end)
		end
-- AG71_BEGIN_STARTER_END
		end
-- AG71_END_STARTER_END
	end
	if petPicker then
		title.Text = "Назначить рабочего"
		action("Назад", function() petPicker = false; draw() end)
		local stationId = selected
		local ids = {}
		for id in pairs(state.pets) do table.insert(ids, id) end
		table.sort(ids)
		for _, id in ipairs(ids) do
			local pet = state.pets[id]
			local workplace = assignedTo(id)
			if workplace == nil or workplace == stationId then
				local skill = Config.stations[stationId].skill
				local raw = pet.stats[skill]
				local tier = state.stations[stationId].level
				local cap = Config.stations[stationId].statCaps[tier] or 0
				action(pet.name .. " · " .. skill .. " " .. raw .. " → " .. math.min(raw, cap), function()
					send("assign", { stationId = stationId, petId = id })
					petPicker = false
					draw()
				end)
			else text(pet.name .. " — занят: " .. Config.stations[workplace].name, 30) end
		end
		action("Снять рабочего", function()
			send("assign", { stationId = stationId, petId = "" })
			petPicker = false
			draw()
		end)
		refresh()
		return
	end
	if selected == "blueprint" then
		title.Text = "Развитие · фаза "..state.phase.phase.."/4"
		local phase=state.phase
		text(phase.name.."\n"..phase.message,76)
		action("Эпохи / Rebirth",function() selected="rebirth"; draw() end)
		action("Ежедневные задания и календарь",function() selected="dailies"; draw() end)
		action("Постоянные улучшения / особый алтарь",function() selected="shards"; draw() end)
		if phase.cost then
			local prerequisites=text("",150)
			bindText(prerequisites,function()
				local current=state.phase
				return "Следующая: "..current.nextName.." · "..current.cost.." Gold\n"..(#current.reasons>0 and table.concat(current.reasons,"\n") or "Все технологические требования выполнены")
			end)
			action("Купить следующую фазу",function() send("advancePhase",{expectedPhase=phase.phase}) end)
		end
		text("Фазы открывают новые категории. Каждый слот покупается отдельно. Старые станции, рецепты и базовый алтарь сохраняются.",84)
		for _,id in ipairs(Config.stationOrder) do
			local build=state.builds[id]
			text(Config.stations[id].name.." · tier "..state.stations[id].level.." · "..(build.cost and (build.cost.." Gold · "..build.reason) or "MAX"),60)
			action("Открыть: "..Config.stations[id].name,function() selected=id; draw() end)
		end
		text("Редкие котлы · гарантированный подарок при покупке фазы 3. Установка — в меню котла. Защита — у алтаря.",84)
		for id,item in pairs(state.cauldrons) do
			text(Config.cauldronTypes[item.type].name.."\nID: "..id.."\nБонус x2: +"..(item.bonus*100).." п.п., общий предел "..(Config.maxDoubleChance*100).."% · "..(item.locked and "Защищён" or "Не защищён"),112)
			action(item.locked and "Снять защиту котла" or "Защитить котёл",function() send("lockCauldron",{cauldronId=id,locked=not item.locked}) end)
		end
	elseif selected == "altar" then
		title.Text = "Алтарь · коллекция"
		collectionUI.draw({ state = state, text = function(value, height)
			local object = text(value, height)
			object.AutomaticSize = Enum.AutomaticSize.Y -- Long IDs/disclosures can wrap on narrow phones.
			return object
		end, action = action, redraw = draw, send = send,
			mount = function(widget) order += 1; widget.LayoutOrder, widget.Parent = order, contents end })
	elseif selected == "warehouse" then
		title.Text = "Склад"
		local inventory = text("", 100)
		bindText(inventory, function()
			local s = state.storage
			return "Сырьё: " .. s.raw .. "/" .. s.rawCapacity .. " · Полуфабрикаты: " .. s.intermediate .. "/" .. s.intermediateCapacity
				.. "\nИнгредиенты: " .. names(state.inventory)
				.. (s.rawTarget and ("\nПриём на каждый вид: сырьё "..s.rawTarget..", полуфабрикат "..s.intermediateTarget..". Старые запасы и грузы сохраняются.") or "")
		end)
		local quest = text("", 50)
		bindText(quest, function() return "Квестовый склад: " .. state.orderProgress.delivered .. "/" .. state.orderProgress.capacity .. " · в пути: " .. state.orderProgress.travelling .. " · в лотках: " .. state.orderProgress.queued end)
		local upgrade = action("", function() send("buy", { upgradeId = "warehouse" }) end)
		bindText(upgrade, function() return "Расширить склад · " .. tostring(upgradePrice("warehouse") or "MAX") .. " Gold" end)
		local pipes = action("", function() send("buy", { upgradeId = "pipes" }) end)
		bindText(pipes, function() return state.pipes and "Трубы установлены" or ("Жидкостные трубы · " .. state.builds.pipes.cost .. " Gold") end)
		text("Магазин контрактов · гарантированный наём", 32)
		for _, speciesId in ipairs({ "farmer", "slime", "brewer" }) do
			local offer = Config.hires[speciesId]
			action("Нанять " .. Config.petSpecies[speciesId].name .. " · " .. offer.cost .. " Gold", function()
				send("hire", { speciesId = speciesId })
			end)
		end
		text("Освободить место · сырьё и полуфабрикаты", 32)
		local ingredientIds={}
		for itemId,item in pairs(Config.items) do if item.kind~="potion" then table.insert(ingredientIds,itemId) end end
		table.sort(ingredientIds)
		for _, itemId in ipairs(ingredientIds) do
			local confirmation = false
			local discardButton
			discardButton = action("Утилизировать до 10: " .. Config.items[itemId].name, function()
				if not confirmation then
					confirmation = true
					discardButton.Text = "Подтвердить удаление: " .. Config.items[itemId].name
					return
				end
				local amount = math.min(10, state.inventory[itemId] or 0)
				if amount > 0 then send("discard", { itemId = itemId, amount = amount }) end
				confirmation = false
				discardButton.Text = "Утилизировать до 10: " .. Config.items[itemId].name
			end)
		end
		text("Обычные зелья сразу продаются. Для склада и заказов не требуется нажимать «Забрать офлайн-награду».", 65)
	elseif selected == "orders" then
		title.Text = "Заказы NPC"
		local current = text("", 100)
		bindText(current, function()
			if not state.order then return "Нет активного заказа. Выбери один из доступных контрактов." end
			local p = state.orderProgress
			return "Заказ: " .. state.order.id .. " · " .. state.order.rewardGold .. " Gold"
				.. "\nУ котла: " .. p.queued .. " · В пути: " .. p.travelling .. " · Доставлено: " .. p.delivered .. "/" .. state.order.count
				.. "\nДо срока: " .. p.remainingSeconds .. " сек. · Резерв всего: " .. p.reserved
		end)
		for _, id in ipairs(state.orderOffers) do
			local contract = Config.orders[id]
			action(contract.name .. " · " .. contract.count .. " шт. → " .. contract.rewardGold .. " Gold", function() send("acceptOrder", { orderId = id }) end)
		end
		for id,availability in pairs(state.orderAvailability) do
			if not availability.available then text(Config.orders[id].name..": "..availability.reason,64) end
		end
		action("Сдать готовый заказ", function() send("claimOrder", {}) end)
		text("Принятый заказ резервирует только нужное количество. Остальная продукция продаётся автоматически.", 60)
	else
		local stationId = selected
		local definition = Config.stations[stationId]
		title.Text = definition.name
		local production = text("", 76)
		bindText(production, function()
			local info = state.production[stationId]
			return info.text .. "\nЦикл: " .. math.floor(info.progress * 100) .. "% · не хватает: " .. names(info.missingInputs)
		end)
		local info = text("", 70)
		bindText(info, function()
			local station = getStation()
			local pet = station.workerId and state.pets[station.workerId]
			local cap = definition.statCaps[station.level] or 0
			local work = pet and (pet.name .. " · " .. definition.skill .. " " .. pet.stats[definition.skill] .. " → " .. math.min(pet.stats[definition.skill], cap)) or "Не назначен"
			return "Уровень: " .. station.level .. "\nРабочий: " .. work
		end)
		if state.starter and not state.starter.legacyGrant and getStation().level < 1
			and (stationId == "garden" or stationId == "cauldron") and state.firstSession then
			local session = state.firstSession
			local price = stationId == "garden" and session.bedCost or session.cauldronCost
			local label = session.ownerApproved and (price .. " Gold") or "цена не утверждена"
			text("Место уже отмечено на стартовом участке. Покупка ставит станцию сюда. Свободное перемещение появится позже.", 72)
			action("Купить и установить · " .. label, function() send("buyStarterStation", { stationId = stationId }) end)
			refresh()
			return
		end
		if stationId == "crystal" then
			local click=action("",function() send("click",{}) end)
			bindText(click,function() return "Собрать эссенцию +"..state.longTerm.manualClickEssence end)
			if state.firstSession and state.starter and not state.starter.legacyGrant then
				text("Essence нужна для варки. Gold приносят зелья и заказы.", 36)
			end
		elseif definition.outputItem then
			local output = text("", 44)
			bindText(output, function() return "У источника: " .. names(getStation().output) end)
			if not (stationId == "garden" and state.starter and not state.starter.legacyGrant) then
				action("Собрать вручную", function() send("harvest", { stationId = stationId }) end)
			end
			action("Забрать выращенное / добытое", function() send("collect", { stationId = stationId }) end)
			if stationId == "garden" and state.firstSession and state.starter and not state.starter.legacyGrant then
				local bed = text("", 72)
				bindText(bed, function()
					local session = state.firstSession
					local plant = state.plants[session.bedId]
					local seeds = state.seeds[session.seedItem] or 0
					local growth = plant and (plant.progress .. "/" .. plant.duration) or "пусто"
					local price = session.ownerApproved and (session.seedCost .. " Gold") or "цена не утверждена"
					local crop = state.crop or {}
					return "Семена: " .. seeds .. " · грядка: " .. growth .. "\nСемя: " .. price .. " · урожай: " .. (crop.yield or session.seedYield) .. " · рост: " .. (crop.duration or session.growSeconds) .. " с"
				end)
				action("Посадить семя", function() send("plantSeed", { bedId = state.firstSession.bedId }) end)
				action("Собрать урожай с грядки", function() send("harvestCrop", { bedId = state.firstSession.bedId }) end)
				action("Купить 1 семя", function() send("buySeed", { amount = 1 }) end)
				action("Купить " .. state.firstSession.openingSeeds .. " семян", function() send("buySeed", { amount = state.firstSession.openingSeeds }) end)
			end
		elseif stationId == "logistics" then
			local cargo = text("", 76)
			bindText(cargo, function()
				local job = getStation().job
				if not job then return "Груза нет. Перевозчик доставляет сырьё и квестовые ящики; жидкости идут по трубам." end
				local source = job.sourceStationId and Config.stations[job.sourceStationId].name or "Склад"
				local target = job.destinationKind == "questStock" and "Квестовый склад" or (job.destinationStationId and Config.stations[job.destinationStationId].name or "Склад")
				return Config.items[job.itemId].name .. " × " .. job.amount .. "\n" .. source .. " → " .. target .. "\nСнятие рабочего приостанавливает груз."
			end)
		elseif definition.defaultRecipe then
			local recipe = text("", 48)
			bindText(recipe, function()
				local station = getStation()
				local def = Config.recipes[station.recipeId]
				local live = def and state.recipes[stationId][station.recipeId]
				return live and (def.name .. " · " .. names(live.inputs) .. " · Essence: " .. live.essenceCost
					.. " · Партия: " .. live.quantity .. " · " .. live.duration .. " с"
					.. " · Выручка: " .. live.saleValue .. " Gold") or "Рецепт не выбран"
			end)
			local recipeIds={}; for id in pairs(state.recipes[stationId]) do table.insert(recipeIds,id) end; table.sort(recipeIds)
			for _,recipeId in ipairs(recipeIds) do
				local def,availability=Config.recipes[recipeId],state.recipes[stationId][recipeId]
				action("Рецепт: "..def.name..(availability.available and "" or (" · "..availability.reason)),function() send("setRecipe",{stationId=stationId,recipeId=recipeId}) end)
			end
			action("Загрузить ингредиенты и Essence", function() send("load", { stationId = stationId }) end)
			action("Сварить одну партию", function() send("brew", { stationId = stationId }) end)
			local auto = action("", function() send("setAuto", { stationId = stationId, enabled = not getStation().auto }) end)
			bindText(auto, function() return "Автоварка: " .. (getStation().auto and "ВКЛ" or "ВЫКЛ") end)
			if stationId == "cauldron" and state.firstSession and state.starter and not state.starter.legacyGrant then
				local session = state.firstSession
				local ready = state.automation.replant and state.automation.harvest and state.automation.supply and state.automation.brew and state.automation.restock
				text("Базовая автоматизация сажает, собирает, докупает семена, загружает котёл, варит Healing и продаёт его. Она тратит обычные ресурсы и сама продолжится, когда Essence или Gold снова появятся.", 96)
				action((ready and "Базовая автоматизация · открыто" or ("Базовая автоматизация · " .. compact(session.automationCost) .. " Gold")), function()
					send("buyAutomation", { feature = "basic" })
				end)
			end
			action("Забрать полуфабрикаты", function() send("collect", { stationId = stationId }) end)
			local buffers = text("", 108)
			bindText(buffers, function()
				local station = getStation()
				local progress = station.job and (" · работа: " .. math.floor(station.progress or 0) .. " / " .. tostring(station.job.duration)) or " · ожидание"
				return "Бак Essence: " .. station.essence .. "/" .. Config.essenceBufferCapacity
					.. "\nВход: " .. names(station.input) .. "\nВыход: " .. names(station.output) .. progress
					.. "\nЯщики у котла: " .. state.production[stationId].queued .. "/" .. Config.questQueueCapacity
			end)
		end
		if definition.archetype=="cauldron" then
			text("Установленный редкий котёл: "..tostring(getStation().cauldronId or "базовый")..". Сначала заверши оплаченную партию.",76)
			for id,item in pairs(state.cauldrons) do
				action("Установить "..Config.cauldronTypes[item.type].name.." · "..id,function() send("equipCauldron",{slotId=stationId,cauldronId=id}) end)
			end
			action("Снять редкий котёл",function() send("equipCauldron",{slotId=stationId,cauldronId=""}) end)
		end
		action("Снабдить этот слот следующим",function() send("prioritize",{stationId=stationId}) end)
		action("Назначить фамильяра", function() petPicker = true; draw() end)
		local upgrade = action("", function() send("buy", { upgradeId = stationId }) end)
		bindText(upgrade, function()
			local price = upgradePrice(stationId)
			return "Улучшить · " .. (price and (compact(price) .. " Gold") or "MAX") .. " · " .. state.builds[stationId].reason
		end)
		text("Действия доступны рядом с этим объектом на твоём участке. Питомца можно снять и назначить на другое место.", 58)
	end
	refresh()
end

refresh = function()
	if not state then return end
	balance.Text = "Gold: " .. compact(state.gold) .. "  |  Essence: " .. compact(state.essence)
	guide.Text = not state.writable and "Сохранение приостановлено" or (state.tutorial.complete and ("Моя ферма · "..state.phase.name) or ("Шаг "..state.tutorial.step.."/"..state.tutorial.total.." · "..ContextPolicy.description({station=state.tutorial.target},Config)))
	for _, update in ipairs(bindings) do update() end
-- AG64_BEGIN_REFRESH
	if syncLandscape then syncLandscape() end
-- AG64_END_REFRESH
end

local tabList={{"blueprint","Развитие"},{"shop","Событие"},{"rebirth","Rebirth"},{"dailies","Daily"},{"shards","Осколки"},{"bazaar","Обмен"},{"quality","Качество"}}
for _,id in ipairs(Config.stationOrder) do table.insert(tabList,{id,Config.stations[id].name}) end
for _,tab in ipairs({{"warehouse","Склад"},{"orders","Заказы"},{"altar","Фамильяры"}}) do table.insert(tabList,tab) end
for _, tab in ipairs(tabList) do
	local tabButton = button(tabs, tab[2], function() selected, petPicker, selectedUpgrade = tab[1], false, false; draw() end)
	tabButton.Size = UDim2.fromOffset(104, 44)
end

local coach=Instance.new("Frame")
coach.Name,coach.AnchorPoint="FirstSession",Vector2.new(0.5,1)
coach.Position,coach.Size=UDim2.new(0.5,0,1,-12),UDim2.new(0.92,0,0,168)
coach.BackgroundColor3,coach.BackgroundTransparency=SURFACE,0.08
coach.Visible=false
coach.Parent=gui
local coachCorner=Instance.new("UICorner")
coachCorner.CornerRadius=UDim.new(0,12)
coachCorner.Parent=coach
local coachTitle=label(coach,"",28)
coachTitle.Position,coachTitle.Size=UDim2.fromOffset(16,10),UDim2.new(1,-32,0,28)
coachTitle.TextXAlignment=Enum.TextXAlignment.Left
coachTitle.Font=Enum.Font.GothamBold
local coachBody=label(coach,"",64)
coachBody.Position,coachBody.Size=UDim2.fromOffset(16,40),UDim2.new(1,-32,0,64)
coachBody.TextXAlignment,coachBody.TextYAlignment=Enum.TextXAlignment.Left,Enum.TextYAlignment.Top
coachBody.TextWrapped=true
local coachActions=Instance.new("Frame")
coachActions.BackgroundTransparency=1
coachActions.Position,coachActions.Size=UDim2.fromOffset(12,112),UDim2.new(1,-24,0,46)
coachActions.Parent=coach
local coachLayout=Instance.new("UIListLayout")
coachLayout.FillDirection,coachLayout.Padding=Enum.FillDirection.Horizontal,UDim.new(0,8)
coachLayout.Parent=coachActions
local quick=Instance.new("Frame")
quick.Name,quick.AnchorPoint="QuickAccess",Vector2.new(1,0)
quick.Position,quick.Size=UDim2.new(1,-12,0,92),UDim2.fromOffset(148,150)
quick.BackgroundTransparency,quick.Visible=1,false
quick.Parent=gui
local quickLayout=Instance.new("UIListLayout")
quickLayout.Padding=UDim.new(0,6)
quickLayout.Parent=quick
local function openMenu(menuId)
	if not state or Session.intro(state) then return end
	selected,petPicker,selectedUpgrade,panel.Visible=menuId,false,false,true
	draw()
end
for _,menu in ipairs({{"supplies","Магазин"},{"inventory","Инвентарь"},{"familiars","Фамильяры"}}) do
	local menuButton=button(quick,menu[2],function() openMenu(menu[1]) end)
	menuButton.Size=UDim2.fromOffset(148,44)
end
local acknowledged=nil
local renderCoach
local skipGlance=button(coach,"Пропустить показ",function() Glance.stop() end)
skipGlance.Position,skipGlance.Size=UDim2.new(1,-150,0,8),UDim2.fromOffset(136,28)
skipGlance.Visible=false
Glance.onRunning(function(active) skipGlance.Visible=active end)
local aimed=nil
local function aim(targetId)
	if targetId==nil then Glance.clear(); return true end
	local world=workspace:FindFirstChild("PotionTycoonWorld")
	local plot=nil
	if world then
		for _,child in ipairs(world:GetChildren()) do
			if child:GetAttribute("OwnerUserId")==player.UserId then plot=child break end
		end
	end
	local part=plot and plot:FindFirstChild(targetId)
	if not part then return false end
	Glance.play(part, environment.reduceMotion)
	return true
end
local function perform(entry)
	if entry.kind=="acknowledge" then acknowledged=entry.id; renderCoach(); return end
	if entry.intents then
		for _,intent in ipairs(entry.intents) do send(intent.action,intent.payload) end
	elseif entry.action=="build" then
		send("buy",{upgradeId=entry.payload.upgradeId})
	else send(entry.action,entry.payload) end
end
function renderCoach()
	if not state then coach.Visible,quick.Visible=false,false; return end
	local view=Session.present(state,Config,acknowledged)
	coach.Visible=view.visible
	coachTitle.Text,coachBody.Text=view.title,view.text
	for _,child in ipairs(coachActions:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	for _,entry in ipairs(view.actions) do
		local choice=button(coachActions,entry.label,function() perform(entry) end)
		choice.Size=UDim2.new(view.intro and 0.32 or 0.7,0,0,44)
	end
	quick.Visible=#view.menus>0
	if view.focus~=aimed then
		if aim(view.focus) then aimed=view.focus end
	elseif not view.visible then
		Glance.clear(); aimed=nil
	end
-- AG64_BEGIN_COACH
	if syncLandscape then syncLandscape() end
-- AG64_END_COACH
end
-- AG64_BEGIN_MOUNT
local legacyCoach={position=coach.Position,size=coach.Size,anchor=coach.AnchorPoint,actions=coachActions.Position,title=coachTitle.Size,body=coachBody.Size}
local coachClose=button(coach,"×",function() coachOpen=false; if syncLandscape then syncLandscape() end end)
coachClose.Name="CloseTutorial"; coachClose.Size=UDim2.fromOffset(44,44); coachClose.Position=UDim2.new(1,-48,0,0); coachClose.Visible=false
local function bookAnchor()
	local world=workspace:FindFirstChild("PotionTycoonWorld")
	local index=player:GetAttribute("PotionPlotIndex")
	local plot=world and index and world:FindFirstChild("Plot_"..index)
	return plot and plot:GetAttribute("OwnerUserId")==player.UserId and plot:FindFirstChild("crystal") or nil
end
syncLandscape=function(forceLayout)
	local camera=workspace.CurrentCamera; if not camera then return end
-- AG71_BEGIN_SWITCH
	local arcade=ArcadeModel.enabled(game:GetService("RunService"):IsStudio(),workspace:GetAttribute("ArcadeHUDEnabled"),arcadeReady,camera.ViewportSize.X,camera.ViewportSize.Y)
	local function bookPresentation(active)
		panel.BackgroundTransparency=active and 1 or 0
		for _,o in ipairs({title,close,tabs,contents}) do o.Visible=not active end
	end
	if landscape and landscape.arcade~=nil and not arcade or landscape and not landscape.arcade and arcade then
		landscape.destroy(); landscape=nil; bookPresentation(false); forceLayout=true
	end
-- AG71_END_SWITCH
	local enabled=LandscapeModel.enabled(workspace:GetAttribute("LandscapeHUDEnabled"),camera.ViewportSize.X,camera.ViewportSize.Y)
	if not enabled then
		if landscape then
			landscape.destroy(); landscape=nil; coachOpen=false
-- AG71_BEGIN_RESTORE
			bookPresentation(false)
-- AG71_END_RESTORE
			coach.Position,coach.Size,coach.AnchorPoint=legacyCoach.position,legacyCoach.size,legacyCoach.anchor
			coachActions.Position,coachTitle.Size,coachBody.Size=legacyCoach.actions,legacyCoach.title,legacyCoach.body
			hud.Visible=true; guide.Visible=true; resize(); renderCoach()
		end
		coachClose.Visible=false
		return
	end
	if not landscape then
		landscape=LandscapeView.new(gui,{
-- AG71_BEGIN_CALLBACKS
			arcade=arcade,config=Config,
			close=function() coachOpen=false; panel.Visible=false; renderCoach() end,
			collect=function() send("click",{}) end,
			choose=function(id)
				if not ArcadeModel.choice(id) or not Session.intro(state) then return end
				send("chooseStarter",{speciesId=id})
			end,
			manage=function() petPicker=true; selectedUpgrade=false; draw() end,
-- AG71_END_CALLBACKS
			anchor=bookAnchor,
			open=function(id)
				if not state then return end
				coachOpen=false; selected,petPicker,selectedUpgrade=id,false,false; panel.Visible=true; draw()
			end,
			quest=function()
				if not state then return end
				coachOpen=not coachOpen; panel.Visible=false; renderCoach()
			end,
			upgrade=function()
				if not LandscapeModel.upgrade(state,collectionPending).enabled then return end
				send("buy",{upgradeId="crystal"}); syncLandscape()
			end,
		})
		landscape.receipt(state,player:GetAttribute("PotionPlotIndex"),Config.maxBalance)
		forceLayout=true
	end
	if forceLayout then
		local p=landscape.layout(gui.AbsoluteSize.X,gui.AbsoluteSize.Y,UserInputService.TouchEnabled,chatRight)
		local function position(o,r) o.AnchorPoint=Vector2.zero; o.Position=UDim2.fromOffset(r.x,r.y); o.Size=UDim2.fromOffset(r.w,r.h) end
		position(panel,p.panel); position(toast,p.notice); position(coach,p.coach)
		if p.rail.w>=104 then position(rail,p.rail) end
		coachActions.Position=UDim2.new(0,12,1,-52)
		coachTitle.Size=UDim2.new(1,-68,0,28)
		coachBody.Size=UDim2.new(1,-32,1,-106)
	end
	hud.Visible=false; guide.Visible=false; toggle.Visible=false; quick.Visible=false; regionLabel.Visible=false
	coach.Visible=state~=nil and not panel.Visible and (Session.intro(state) or coachOpen)
	coachClose.Visible=coach.Visible and not Session.intro(state)
	if currentContext and currentContext.station=="crystal" then rail.Visible=false end
-- AG71_BEGIN_PRESENT
	local storybook=landscape.arcade and panel.Visible and selected=="crystal" and not petPicker
	bookPresentation(storybook)
	if landscape.arcade then
		landscape.bookActive=storybook
		if Session.intro(state) and landscape.plan.chooserFits then coach.Visible=false; coachClose.Visible=false end
	end
-- AG71_END_PRESENT
	landscape.update(state,collectionPending,selected,panel.Visible or coach.Visible,environment.reduceMotion)
end
-- AG71_BEGIN_ASSET_GATE
local arcadeFlagConnection=workspace:GetAttributeChangedSignal("ArcadeHUDEnabled"):Connect(function() resize(); renderCoach(); draw() end)
script.Destroying:Connect(function() arcadeFlagConnection:Disconnect() end)
task.defer(function()
	if not game:GetService("RunService"):IsStudio() or ArcadeAssets.image=="" then return end
	local loaded=false
	-- Image instances select the texture loader; an untyped content string can
	-- return without a callback in Studio. Keep the probe outside the live GUI.
	local probe=Instance.new("ImageLabel"); probe.Image=ArcadeAssets.image
	local ok=pcall(function()
		game:GetService("ContentProvider"):PreloadAsync({probe},function(_,status) loaded=status==Enum.AssetFetchStatus.Success end)
	end)
	probe:Destroy()
	if not gui.Parent then return end
	arcadeReady=ok and loaded
	gui:SetAttribute("AG71AssetStatus",arcadeReady and "LOADED" or "FAILED_USING_AG64")
	resize(); renderCoach(); draw()
end)
-- AG71_END_ASSET_GATE
workspace:GetAttributeChangedSignal("LandscapeHUDEnabled"):Connect(function() resize(); renderCoach() end)
ContextActionService:BindAction("LandscapeHUDBack",function(_,inputState)
	if not landscape or inputState~=Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
-- AG71_BEGIN_BACK
	if landscape.back and landscape.back() then return Enum.ContextActionResult.Sink end
-- AG71_END_BACK
	if panel.Visible then panel.Visible=false; return Enum.ContextActionResult.Sink end
	if coachOpen then coachOpen=false; syncLandscape(); return Enum.ContextActionResult.Sink end
	return Enum.ContextActionResult.Pass
end,false,Enum.KeyCode.ButtonB)
script.Destroying:Connect(function()
	if landscape then landscape.destroy(); landscape=nil end
	ContextActionService:UnbindAction("LandscapeHUDBack")
end)
syncLandscape(true)
-- AG64_END_MOUNT
local function bindMenu(name,menuId,keys)
	ContextActionService:BindAction(name,function(_,inputState)
		if inputState~=Enum.UserInputState.Begin or UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
		if not state or Session.intro(state) then return Enum.ContextActionResult.Pass end
		openMenu(menuId)
		return Enum.ContextActionResult.Sink
	end,false,table.unpack(keys))
end
bindMenu("PotionShop","supplies",{Enum.KeyCode.M,Enum.KeyCode.DPadLeft})
bindMenu("PotionInventory","inventory",{Enum.KeyCode.I,Enum.KeyCode.DPadDown})
bindMenu("PotionFamiliars","familiars",{Enum.KeyCode.P,Enum.KeyCode.DPadRight})

local toastGeneration = 0
local function showToast(message, duration)
	toastGeneration += 1
	local generation = toastGeneration
	toast.Text, toast.Visible = message, true
	task.delay(duration or 4, function() if generation == toastGeneration then toast.Visible = false end end)
end

State.OnClientEvent:Connect(function(value)
	local first = state == nil
	local previousEssence = state and state.essence
	local shopChanged=state and Codec.encode(state.shop)~=Codec.encode(value.shop)
	local longTermChanged=state and (state.longTerm.requestId~=value.longTerm.requestId or state.longTerm.day~=value.longTerm.day)
	local longTermPanel=selected=="rebirth" or selected=="dailies" or selected=="shards"
	local longTermViewChanged=longTermPanel and state and Codec.encode(state.longTerm)~=Codec.encode(value.longTerm)
	if (state and state.rebirths~=value.rebirths) or (first and value.longTerm.last and value.longTerm.last.action=="rebirth") then selected,petPicker,panel.Visible="rebirth",false,true; selectedUpgrade=false end
	local collectionChanged = state and collectionUI.signature(state) ~= collectionUI.signature(value)
	local progressionChanged = state and (state.progression.sequence~=value.progression.sequence or state.phase.complete~=value.phase.complete
		or table.concat(state.orderOffers,"|")~=table.concat(value.orderOffers,"|"))
	if state and (state.collection.sequence ~= value.collection.sequence or state.progression.sequence~=value.progression.sequence or state.shop.sequence~=value.shop.sequence or longTermChanged) then collectionPending = false end
	local function guideSignature(snapshot)
		if not snapshot or not snapshot.stations then return "" end
		local session=snapshot.firstSession or {}
		local plant=snapshot.plants and snapshot.plants[session.bedId]
		local seeds=snapshot.seeds and snapshot.seeds[session.seedItem] or 0
		return table.concat({
			tostring(snapshot.tutorial and snapshot.tutorial.id), tostring(snapshot.tutorial and snapshot.tutorial.complete),
			tostring(snapshot.gold), tostring(snapshot.essence), tostring(seeds),
			tostring(snapshot.stations.garden.level), tostring(snapshot.stations.cauldron.level), tostring(snapshot.stations.crystal.level),
			plant and tostring(plant.progress) or "0", tostring(snapshot.automation and snapshot.automation.brew),
		}, "|")
	end
	local guideChanged=state and guideSignature(state)~=guideSignature(value)
	state = value
-- AG64_BEGIN_RECEIPT
	if landscape then landscape.receipt(value,player:GetAttribute("PotionPlotIndex"),Config.maxBalance) end
-- AG64_END_RECEIPT
	if first and Session.intro(value) then panel.Visible=false end
	local gained=Session.essenceDelta(previousEssence,value.essence)
-- AG64_BEGIN_NO_DELTA_POPUP
	if not landscape then
-- AG64_END_NO_DELTA_POPUP
	if gained>0 then showToast("+"..gained.." Essence") end
-- AG64_BEGIN_END_DELTA_POPUP
	end
-- AG64_END_END_DELTA_POPUP
	renderCoach()
	if first or guideChanged or progressionChanged or longTermChanged or longTermViewChanged or (selected=="shop" and shopChanged) or (selected == "altar" and collectionChanged) or selected=="supplies" or selected=="inventory" or selected=="familiars" then draw() else refresh() end
	if not hasReport and value.offlineReport and value.offlineReport.processedSeconds > 5 then
		hasReport = true
		showToast("С возвращением! Учтено " .. value.offlineReport.processedSeconds .. " сек. работы. Gold: +" .. math.floor(value.offlineReport.goldEarned or 0) .. ". Уже сохранено.", 8)
	end
end)
PurchasePrompt.OnClientEvent:Connect(function(value)
	if not state then return end
	for _,card in ipairs(state.shop.cards) do
		if card.offerId==value.offerId and card.sku==value.sku and card.platformKind==value.kind and card.robuxAvailable then
			local ok=pcall(function()
				if value.kind=="product" then MarketplaceService:PromptProductPurchase(player,value.sku)
				else MarketplaceService:PromptGamePassPurchase(player,value.sku) end
			end)
			if not ok then showToast("Окно Roblox недоступно. Покупка не подтверждена; повтори позже.",5) end
			return
		end
	end
end)
TradeState.OnClientEvent:Connect(function(value)
	local previous=tradeState and tradeState.session
	tradeState=value
	local current=value.session
	if current and (not previous or previous.id~=current.id or previous.state~=current.state) then
		selected,petPicker,panel.Visible="bazaar",false,true
		selectedUpgrade=false
	end
	if value.blocked then selected,petPicker,panel.Visible="bazaar",false,true; selectedUpgrade=false end
	if selected=="bazaar" then draw() end
end)
Notice.OnClientEvent:Connect(function(value)
	collectionPending = false
	showToast(Session.explain(value.text))
-- AG64_BEGIN_NOTICE
	if syncLandscape then syncLandscape() end
-- AG64_END_NOTICE
end)
Focus.OnClientEvent:Connect(function(stationId)
	if Config.stations[stationId] or stationId == "warehouse" or stationId == "orders" or stationId == "altar" or stationId == "blueprint" or stationId=="bazaar" then
		selected, petPicker, panel.Visible = stationId, false, true
		selectedUpgrade=false
		draw()
	end
end)
draw()
task.spawn(function()
	context=require(script.Parent.WorldContext).start(updateContext,function() return panel.Visible or not gui.Enabled end,function()
-- AG64_BEGIN_OCCLUSION
		if landscape then return landscape.blocked({panel,coach,rail,toast},chatRect) end
-- AG64_END_OCCLUSION
		local inset=GuiService:GetGuiInset(); local rectangles={}
		if chatRect then table.insert(rectangles,chatRect) end
		for _,widget in ipairs({hud,guide,rail,toggle,coach,quick}) do
			local p,s=widget.AbsolutePosition,widget.AbsoluteSize
			table.insert(rectangles,{x=p.X+inset.X,y=p.Y+inset.Y,w=s.X,h=s.Y})
		end
		return rectangles
	end,function() return state end)
	local world=workspace:WaitForChild("PotionTycoonWorld")
	local function crystalFlash(object)
-- AG64_BEGIN_NO_UNCONFIRMED_POPUP
		local inheritedToast=showToast
		local function showToast(...) if not landscape then inheritedToast(...) end end
-- AG64_END_NO_UNCONFIRMED_POPUP
		if object:IsA("ProximityPrompt") and object.Parent and object.Parent:GetAttribute("StationId")=="crystal" and string.sub(object.Parent.Name,1,4)~="Buy_" then
			object.Triggered:Connect(function() showToast("Кристалл вспыхнул") end)
		end
	end
	for _,object in ipairs(world:GetDescendants()) do crystalFlash(object) end
	world.DescendantAdded:Connect(crystalFlash)
end)
Ready:FireServer()
task.spawn(function()
	while not state do task.wait(3); Ready:FireServer() end
end)
