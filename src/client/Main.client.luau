--!nonstrict
-- Presentation and intent only: the client never grants currency, ingredients or pets.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("PotionTycoon"):WaitForChild("Shared")
local Config = require(shared.Config)
local collectionUI = require(script.Parent.CollectionUI).new(Config)
local tradeUI = require(script.Parent.TradeUI).new(Config)
local longTermUI = require(script.Parent.LongTermUI).new(Config)
local LongTerm = require(shared.LongTerm)
local Codec = require(shared.TradeCodec)
local remotes = ReplicatedStorage.PotionTycoon:WaitForChild("Remotes")
local Action, State, Notice, Focus = remotes:WaitForChild("Action"), remotes:WaitForChild("State"), remotes:WaitForChild("Notice"), remotes:WaitForChild("Focus")
local Ready = remotes:WaitForChild("Ready")
local TradeState = remotes:WaitForChild("TradeState")

local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn = "PotionTycoonUI", false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local BG, SURFACE, TEXT, ACCENT = Color3.fromRGB(22, 26, 34), Color3.fromRGB(42, 48, 61), Color3.fromRGB(237, 239, 246), Color3.fromRGB(119, 91, 195)
local state, selected, petPicker, hasReport = nil, "crystal", false, false
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
	if collectionActions[action] or progressionActions[action] or LongTerm.isAction(action) then
		payload.requestId = payload.requestId or (LongTerm.isAction(action) and state.longTerm.requestId or (progressionActions[action] and state.progression.sequence or state.collection.sequence)+1)
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
hud.Size, hud.Position = UDim2.new(1, -24, 0, 76), UDim2.fromOffset(12, 10)
hud.BackgroundColor3, hud.Parent = BG, gui
	round(hud)
local balance = label(hud, "Загрузка профиля…", 36)
balance.Position, balance.Size = UDim2.fromOffset(12, 0), UDim2.new(1, -130, 0, 36)
balance.TextSize = 17
local status = label(hud, "M5 · эпохи и постоянное развитие", 32)
status.Position, status.Size = UDim2.fromOffset(12, 38), UDim2.new(1, -24, 0, 32)
status.TextSize = 11
local toggle = button(hud, "Фабрика", function() end)
toggle.Size, toggle.Position = UDim2.fromOffset(100, 34), UDim2.new(1, -112, 0, 3)

local toast = label(gui, "Подойди к кристаллу. Назначь рабочих через меню объектов.", 54)
toast.Position, toast.Size = UDim2.new(0, 16, 0, 90), UDim2.new(1, -32, 0, 54)
toast.TextXAlignment = Enum.TextXAlignment.Center
toast.BackgroundColor3, toast.BackgroundTransparency = BG, 0.15
round(toast)

local panel = Instance.new("Frame")
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
contents.Position, contents.Size = UDim2.fromOffset(12, 94), UDim2.new(1, -24, 1, -106)
contents.BackgroundTransparency, contents.BorderSizePixel, contents.ScrollBarThickness = 1, 0, 4
contents.AutomaticCanvasSize, contents.CanvasSize = Enum.AutomaticSize.Y, UDim2.new()
contents.Parent = panel

local guide = button(gui, "Обучение · загрузка…", function() end)
guide.BackgroundColor3 = ACCENT
local draw, refresh

local function resize()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local viewport = camera.ViewportSize
	local landscape = viewport.X > viewport.Y
	if landscape then
		hud.Size, hud.Position = UDim2.new(0.44, -16, 0, 88), UDim2.fromOffset(8, 8)
		guide.Position, guide.Size = UDim2.fromOffset(8, 100), UDim2.new(0.44, -16, 0, 44)
		panel.AnchorPoint, panel.Position = Vector2.new(1, 0), UDim2.new(1, -8, 0, 8)
		panel.Size = UDim2.new(0.55, 0, 0, math.max(180, viewport.Y - 150))
	else
		hud.Size, hud.Position = UDim2.new(1, -16, 0, 88), UDim2.fromOffset(8, 8)
		guide.Position, guide.Size = UDim2.fromOffset(8, 100), UDim2.new(1, -16, 0, 44)
		panel.AnchorPoint, panel.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 152)
		panel.Size = UDim2.new(1, -16, 0, math.max(180, viewport.Y - 342))
	end
	toast.Position, toast.Size = UDim2.new(0, 16, 0, 48), UDim2.new(landscape and 0.44 or 1, -32, 0, 44)
	toast.Visible = false
end
local cameraConnection
local function watchCamera()
	if cameraConnection then cameraConnection:Disconnect() end
	if workspace.CurrentCamera then cameraConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
	resize()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()
guide.Activated:Connect(function()
	if not state then return end
	selected, petPicker, panel.Visible = state.tutorial.complete and "blueprint" or state.tutorial.target, false, true
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
	if selected=="bazaar" then
		title.Text="Магический базар · обмен"
		tradeUI.draw({value=tradeState,text=text,action=action,send=send,redraw=draw})
		return
	end
	if not state then text("Ожидаем безопасную загрузку профиля…"); return end
	if selected=="rebirth" or selected=="dailies" or selected=="shards" then
		title.Text=selected=="rebirth" and "Rebirth · новая эпоха" or (selected=="dailies" and "Ежедневные награды" or "Time Shards · магазин")
		longTermUI.draw({state=state,currentState=function() return state end,bindText=bindText,mode=selected,text=text,action=action,send=send,redraw=draw}); refresh(); return
	end
	local tutorial = text("", 96)
	bindText(tutorial, function() return "Обучение " .. state.tutorial.step .. "/" .. state.tutorial.total .. " · " .. state.tutorial.text end)
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
		if stationId == "crystal" then
			local click=action("",function() send("click",{}) end)
			bindText(click,function() return "Собрать эссенцию +"..state.longTerm.manualClickEssence end)
		elseif definition.outputItem then
			local output = text("", 44)
			bindText(output, function() return "У источника: " .. names(getStation().output) end)
			action("Собрать вручную", function() send("harvest", { stationId = stationId }) end)
			action("Забрать выращенное / добытое", function() send("collect", { stationId = stationId }) end)
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
				return def and (def.name .. " · " .. names(def.inputs) .. " · Essence: " .. def.essenceCost
					.. " · Выпуск: " .. def.quantity .. " · Продажа: " .. state.recipes[stationId][station.recipeId].saleValue .. " Gold") or "Рецепт не выбран"
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
		bindText(upgrade, function() return "Улучшить · " .. tostring(upgradePrice(stationId) or "MAX") .. " Gold · " .. state.builds[stationId].reason end)
		text("Действия доступны рядом с этим объектом на твоём участке. Питомца можно снять и назначить на другое место.", 58)
	end
	refresh()
end

refresh = function()
	if not state then return end
	balance.Text = "Gold: " .. math.floor(state.gold) .. "  |  Essence: " .. math.floor(state.essence)
	status.Text = (state.mode == "STUDIO_MEMORY" and "STUDIO: прогресс НЕ сохраняется после Stop" or "DataStore: сохранение включено") .. (state.writable and "" or " · запись приостановлена")
	guide.Text = state.tutorial.complete and ("Фаза "..state.phase.phase.."/4 · "..state.phase.message) or ("Шаг " .. state.tutorial.step .. "/" .. state.tutorial.total .. " · " .. (Config.stations[state.tutorial.target] and Config.stations[state.tutorial.target].name or state.tutorial.target) .. " · Подсказка")
	for _, update in ipairs(bindings) do update() end
end

local tabList={{"blueprint","Развитие"},{"rebirth","Rebirth"},{"dailies","Daily"},{"shards","Осколки"},{"bazaar","Обмен"}}
for _,id in ipairs(Config.stationOrder) do table.insert(tabList,{id,Config.stations[id].name}) end
for _,tab in ipairs({{"warehouse","Склад"},{"orders","Заказы"},{"altar","Фамильяры"}}) do table.insert(tabList,tab) end
for _, tab in ipairs(tabList) do
	local tabButton = button(tabs, tab[2], function() selected, petPicker = tab[1], false; draw() end)
	tabButton.Size = UDim2.fromOffset(104, 44)
end

local toastGeneration = 0
local function showToast(message, duration)
	toastGeneration += 1
	local generation = toastGeneration
	toast.Text, toast.Visible = message, true
	task.delay(duration or 4, function() if generation == toastGeneration then toast.Visible = false end end)
end

State.OnClientEvent:Connect(function(value)
	local first = state == nil
	local longTermChanged=state and (state.longTerm.requestId~=value.longTerm.requestId or state.longTerm.day~=value.longTerm.day)
	local longTermPanel=selected=="rebirth" or selected=="dailies" or selected=="shards"
	local longTermViewChanged=longTermPanel and state and Codec.encode(state.longTerm)~=Codec.encode(value.longTerm)
	if (state and state.rebirths~=value.rebirths) or (first and value.longTerm.last and value.longTerm.last.action=="rebirth") then selected,petPicker,panel.Visible="rebirth",false,true end
	local collectionChanged = state and collectionUI.signature(state) ~= collectionUI.signature(value)
	local progressionChanged = state and (state.progression.sequence~=value.progression.sequence or state.phase.complete~=value.phase.complete
		or table.concat(state.orderOffers,"|")~=table.concat(value.orderOffers,"|"))
	if state and (state.collection.sequence ~= value.collection.sequence or state.progression.sequence~=value.progression.sequence or longTermChanged) then collectionPending = false end
	state = value
	if first or progressionChanged or longTermChanged or longTermViewChanged or (selected == "altar" and collectionChanged) then draw() else refresh() end
	if not hasReport and value.offlineReport and value.offlineReport.processedSeconds > 5 then
		hasReport = true
		showToast("С возвращением! Учтено " .. value.offlineReport.processedSeconds .. " сек. работы. Gold: +" .. math.floor(value.offlineReport.goldEarned or 0) .. ". Уже сохранено.", 8)
	end
end)
TradeState.OnClientEvent:Connect(function(value)
	local previous=tradeState and tradeState.session
	tradeState=value
	local current=value.session
	if current and (not previous or previous.id~=current.id or previous.state~=current.state) then
		selected,petPicker,panel.Visible="bazaar",false,true
	end
	if value.blocked then selected,petPicker,panel.Visible="bazaar",false,true end
	if selected=="bazaar" then draw() end
end)
Notice.OnClientEvent:Connect(function(value)
	collectionPending = false
	showToast(value.text)
end)
Focus.OnClientEvent:Connect(function(stationId)
	if Config.stations[stationId] or stationId == "warehouse" or stationId == "orders" or stationId == "altar" or stationId == "blueprint" or stationId=="bazaar" then
		selected, petPicker, panel.Visible = stationId, false, true
		draw()
	end
end)
draw()
Ready:FireServer()
task.spawn(function()
	while not state do task.wait(3); Ready:FireServer() end
end)
