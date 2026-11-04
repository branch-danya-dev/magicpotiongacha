--!nonstrict
-- Presentation and intent only: the client never grants currency, ingredients or pets.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("PotionTycoon"):WaitForChild("Shared")
local Config = require(shared.Config)
local remotes = ReplicatedStorage.PotionTycoon:WaitForChild("Remotes")
local Action, State, Notice, Focus = remotes:WaitForChild("Action"), remotes:WaitForChild("State"), remotes:WaitForChild("Notice"), remotes:WaitForChild("Focus")
local Ready = remotes:WaitForChild("Ready")

local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn = "PotionTycoonUI", false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local BG, SURFACE, TEXT, ACCENT = Color3.fromRGB(22, 26, 34), Color3.fromRGB(42, 48, 61), Color3.fromRGB(237, 239, 246), Color3.fromRGB(119, 91, 195)
local state, selected, petPicker, hasReport = nil, "crystal", false, false
local bindings = {}

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
	value.Size = UDim2.new(1, -8, 0, 42)
	value.BackgroundColor3, value.TextColor3 = SURFACE, TEXT
	value.Font, value.TextSize, value.TextWrapped = Enum.Font.GothamMedium, 14, true
	value.Text, value.Parent = text, parent
	round(value)
	value.Activated:Connect(callback)
	return value
end
local function send(action, payload)
	if not state or not state.writable then return end
	Action:FireServer(action, payload or {})
end
local function names(items)
	local parts = {}
	for id, amount in pairs(items or {}) do
		if amount > 0 then table.insert(parts, (Config.items[id] and Config.items[id].name or id) .. ": " .. amount) end
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
local status = label(hud, "M0 · серверная фабрика", 32)
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
panel.AnchorPoint, panel.Position = Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -12)
panel.Size, panel.BackgroundColor3 = UDim2.new(0.94, 0, 0.67, 0), BG
panel.Parent = gui
round(panel)
local sizeLimit = Instance.new("UISizeConstraint")
sizeLimit.MinSize, sizeLimit.MaxSize, sizeLimit.Parent = Vector2.new(280, 260), Vector2.new(560, 640), panel
local title = label(panel, "Управление фабрикой", 34)
title.Position = UDim2.fromOffset(12, 4)
local close = button(panel, "×", function() panel.Visible = false end)
close.Size, close.Position = UDim2.fromOffset(32, 30), UDim2.new(1, -40, 0, 4)
toggle.Activated:Connect(function() panel.Visible = not panel.Visible end)

local tabs = Instance.new("Frame")
tabs.BackgroundTransparency, tabs.Size = 1, UDim2.new(1, -16, 0, 80)
tabs.Position, tabs.Parent = UDim2.fromOffset(8, 42), panel
local grid = Instance.new("UIGridLayout")
grid.CellSize, grid.CellPadding, grid.Parent = UDim2.new(0.25, -4, 0, 34), UDim2.fromOffset(4, 4), tabs

local contents = Instance.new("ScrollingFrame")
contents.Position, contents.Size = UDim2.fromOffset(12, 126), UDim2.new(1, -24, 1, -138)
contents.BackgroundTransparency, contents.BorderSizePixel, contents.ScrollBarThickness = 1, 0, 4
contents.AutomaticCanvasSize, contents.CanvasSize = Enum.AutomaticSize.Y, UDim2.new()
contents.Parent = panel

local draw, refresh
local function bindText(widget, getter)
	table.insert(bindings, function() widget.Text = getter() end)
end
local function getStation()
	return state and state.stations[selected]
end
local function upgradePrice(id)
	if not state then return "…" end
	if id == "warehouse" then return Config.warehouse.upgradeCosts[(state.warehouseLevel or 0) + 1] end
	local station = state.stations[id]
	return station and Config.stations[id].upgradeCosts[station.level + 1]
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
		return object
	end
	local function action(value, callback)
		order += 1
		local object = button(contents, value, callback)
		object.LayoutOrder = order
		return object
	end
	if not state then text("Ожидаем безопасную загрузку профиля…"); return end
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
		return
	end
	if selected == "warehouse" then
		title.Text = "Склад"
		local inventory = text("", 70)
		bindText(inventory, function() return "Ингредиенты: " .. names(state.inventory) end)
		local quest = text("", 50)
		bindText(quest, function() return "Под заказы: " .. names(state.questStock) end)
		local upgrade = action("", function() send("buy", { upgradeId = "warehouse" }) end)
		bindText(upgrade, function() return "Расширить склад · " .. tostring(upgradePrice("warehouse") or "MAX") .. " Gold" end)
		local pipes = action("", function() send("buy", { upgradeId = "pipes" }) end)
		bindText(pipes, function() return state.pipes and "Трубы установлены" or ("Жидкостные трубы · " .. Config.pipesCost .. " Gold") end)
		text("Магазин контрактов · гарантированный наём", 32)
		for _, speciesId in ipairs({ "farmer", "slime", "brewer" }) do
			local offer = Config.hires[speciesId]
			action("Нанять " .. Config.petSpecies[speciesId].name .. " · " .. offer.cost .. " Gold", function()
				send("hire", { speciesId = speciesId })
			end)
		end
		text("Освободить место · сырьё и полуфабрикаты", 32)
		for _, itemId in ipairs({ "mandrake", "coal", "slime", "fire_extract" }) do
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
		local current = text("", 64)
		bindText(current, function()
			if not state.order then return "Нет активного заказа. Выбери один из доступных контрактов." end
			return "Активный заказ: " .. tostring(state.order.id or state.order.orderId or "NPC") .. "\nРезерв: " .. names(state.questStock)
		end)
		local ids = {}
		for id in pairs(Config.orders) do table.insert(ids, id) end
		table.sort(ids)
		for _, id in ipairs(ids) do
			local contract = Config.orders[id]
			action(contract.name .. " · " .. contract.count .. " шт. → " .. contract.rewardGold .. " Gold", function() send("acceptOrder", { orderId = id }) end)
		end
		action("Сдать готовый заказ", function() send("claimOrder", {}) end)
		text("Принятый заказ резервирует только нужное количество. Остальная продукция продаётся автоматически.", 60)
	else
		local stationId = selected
		local definition = Config.stations[stationId]
		title.Text = definition.name
		local info = text("", 70)
		bindText(info, function()
			local station = getStation()
			local pet = station.workerId and state.pets[station.workerId]
			local cap = definition.statCaps[station.level] or 0
			local work = pet and (pet.name .. " · " .. definition.skill .. " " .. pet.stats[definition.skill] .. " → " .. math.min(pet.stats[definition.skill], cap)) or "Не назначен"
			return "Уровень: " .. station.level .. "\nРабочий: " .. work
		end)
		if stationId == "crystal" then
			action("Собрать эссенцию +1", function() send("click", {}) end)
		elseif stationId == "garden" or stationId == "mine" then
			action("Собрать вручную", function() send("harvest", { stationId = stationId }) end)
			action("Забрать выращенное / добытое", function() send("collect", { stationId = stationId }) end)
		elseif stationId == "cauldron" or stationId == "distillery" then
			local recipe = text("", 48)
			bindText(recipe, function()
				local station = getStation()
				local def = Config.recipes[station.recipeId]
				return def and (def.name .. " · " .. names(def.inputs) .. " · Essence: " .. def.essenceCost) or "Рецепт не выбран"
			end)
			for _, recipeId in ipairs({ "healing", "fire_extract", "rage" }) do
				local def = Config.recipes[recipeId]
				if def.station == stationId then
					action("Рецепт: " .. def.name, function() send("setRecipe", { stationId = stationId, recipeId = recipeId }) end)
				end
			end
			action("Загрузить ингредиенты со склада", function() send("load", { stationId = stationId }) end)
			action("Сварить одну партию", function() send("brew", { stationId = stationId }) end)
			local auto = action("", function() send("setAuto", { stationId = stationId, enabled = not getStation().auto }) end)
			bindText(auto, function() return "Автоварка: " .. (getStation().auto and "ВКЛ" or "ВЫКЛ") end)
			action("Забрать полуфабрикаты", function() send("collect", { stationId = stationId }) end)
			local buffers = text("", 72)
			bindText(buffers, function()
				local station = getStation()
				local progress = station.job and (" · работа: " .. math.floor(station.progress or 0) .. " / " .. tostring(station.job.duration)) or " · ожидание"
				return "Вход: " .. names(station.input) .. "\nВыход: " .. names(station.output) .. progress
			end)
		end
		action("Назначить фамильяра", function() petPicker = true; draw() end)
		local upgrade = action("", function() send("buy", { upgradeId = stationId }) end)
		bindText(upgrade, function() return "Улучшить · " .. tostring(upgradePrice(stationId) or "MAX") .. " Gold" end)
		text("Действия доступны рядом с этим объектом на твоём участке. Питомца можно снять и назначить на другое место.", 58)
	end
	refresh()
end

refresh = function()
	if not state then return end
	balance.Text = "Gold: " .. math.floor(state.gold) .. "  |  Essence: " .. math.floor(state.essence)
	status.Text = (state.mode == "STUDIO_MEMORY" and "STUDIO: прогресс НЕ сохраняется после Stop" or "DataStore: сохранение включено") .. (state.writable and "" or " · запись приостановлена")
	for _, update in ipairs(bindings) do update() end
end

for _, tab in ipairs({ {"crystal", "Кристалл"}, {"garden", "Грядка"}, {"mine", "Шахта"}, {"distillery", "Экстракт"}, {"cauldron", "Котёл"}, {"logistics", "Перевозчик"}, {"warehouse", "Склад"}, {"orders", "Заказы"} }) do
	button(tabs, tab[2], function() selected, petPicker = tab[1], false; draw() end)
end

State.OnClientEvent:Connect(function(value)
	local first = state == nil
	state = value
	if first then draw() else refresh() end
	if not hasReport and value.offlineReport and value.offlineReport.processedSeconds > 5 then
		hasReport = true
		toast.Text = "С возвращением! Учтено " .. value.offlineReport.processedSeconds .. " сек. работы. Gold: +" .. math.floor(value.offlineReport.goldEarned or 0) .. ". Уже сохранено."
	end
end)
Notice.OnClientEvent:Connect(function(value) toast.Text = value.text end)
Focus.OnClientEvent:Connect(function(stationId)
	if Config.stations[stationId] or stationId == "warehouse" or stationId == "orders" then
		selected, petPicker, panel.Visible = stationId, false, true
		draw()
	end
end)
draw()
Ready:FireServer()
task.spawn(function()
	while not state do task.wait(3); Ready:FireServer() end
end)
