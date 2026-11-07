--!nonstrict
-- Studio developer preview for the UI foundation.
-- It does not replace PotionTycoonUI, bind M / I / P, or send a remote.
--
-- In Roblox Studio: select Workspace, add a boolean attribute named
-- UIFoundationDemo, set it to true, then press Play. Set it back to false
-- to remove the preview. A published server never shows this screen.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PotionTycoon"):WaitForChild("Shared")
local Theme = require(Shared.ui.Theme)
local Gate = require(Shared.ui.DemoGate)
local Layout = require(Shared.ui.Layout)
local Binding = require(Shared.ui.Binding)
local Host = require(Shared.ui.Host)
local Kit = require(script.Parent.ui.Kit)
local environment = require(script.Parent.EnvironmentController)

local player = Players.LocalPlayer
local surface = Host.new()
local host = nil
local gui = nil

local function playerGui()
	return player:FindFirstChildOfClass("PlayerGui")
end

local function hide()
	if host then
		host.destroy()
		host = nil
	end
	local existing = playerGui()
	if existing then
		local previous = existing:FindFirstChild("UIFoundationDemo")
		if previous then previous:Destroy() end
	end
	if gui then gui:Destroy() end
	gui = nil
	surface.unmount()
end

local function place(widget, rect)
	widget.root.Position = UDim2.fromOffset(rect.x, rect.y)
	widget.root.Size = UDim2.fromOffset(rect.w, rect.h)
end

local function row(parent)
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.Parent = parent
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.Padding = UDim.new(0, 6)
	list.Wraps = true
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = frame
	return frame
end

local function show()
	if not Gate.allowed(RunService:IsStudio(), workspace:GetAttribute("UIFoundationDemo") == true) then
		hide()
		return
	end
	if surface.mounted() then
		return
	end
	local existing = playerGui()
	if existing then
		local previous = existing:FindFirstChild("UIFoundationDemo")
		if previous then previous:Destroy() end
	end
	if not surface.mount() then
		return
	end

	host = Kit.host()
	host.setReduceMotion(environment.reduceMotion == true)
	local sample = Binding.demo()
	local resources = Binding.resources(sample)
	local folder = player:WaitForChild("PlayerGui")
	if not Gate.allowed(RunService:IsStudio(), workspace:GetAttribute("UIFoundationDemo") == true) then
		hide()
		return
	end
	gui = Instance.new("ScreenGui")
	gui.Name = "UIFoundationDemo"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 30
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.Parent = folder

	local hud = Kit.panel(host, gui)
	hud.setPadding(4)
	hud.root.ClipsDescendants = true
	hud.root.ZIndex = 4
	local hudList = Instance.new("UIListLayout")
	hudList.FillDirection = Enum.FillDirection.Horizontal
	hudList.VerticalAlignment = Enum.VerticalAlignment.Center
	hudList.Padding = UDim.new(0, 8)
	hudList.SortOrder = Enum.SortOrder.LayoutOrder
	hudList.Parent = hud.root
	local gold = Kit.resourceCounter(host, hud.root, "Gold")
	gold.setPadding(6)
	gold.setValue(resources.goldText)
	gold.root.LayoutOrder = 1
	local essence = Kit.resourceCounter(host, hud.root, "Essence")
	essence.setPadding(6)
	essence.setValue(resources.essenceText)
	essence.root.LayoutOrder = 2
	local tooltip = Kit.tooltip(host, gui)
	tooltip.root.ZIndex = 30
	local icons = {}
	for index, item in ipairs({ { "M", "Магазин" }, { "I", "Инвентарь" }, { "P", "Фамильяры" } }) do
		local icon = Kit.iconButton(host, hud.root, item[1])
		icon.root.LayoutOrder = 2 + index
		icon.root.ZIndex = 5
		host.connect(icon.root.MouseEnter, function()
			tooltip.setText(item[2])
			tooltip.show(icon.root)
		end)
		host.connect(icon.root.MouseLeave, function()
			tooltip.hide()
		end)
		host.connect(icon.root.SelectionGained, function()
			tooltip.setText(item[2])
			tooltip.show(icon.root)
		end)
		host.connect(icon.root.SelectionLost, function()
			tooltip.hide()
		end)
		icons[index] = icon
	end

	local modal = Kit.modal(host, gui)
	modal.setTitle("Foundation")
	local column = Instance.new("UIListLayout")
	column.FillDirection = Enum.FillDirection.Vertical
	column.Padding = UDim.new(0, 8)
	column.SortOrder = Enum.SortOrder.LayoutOrder
	column.Parent = modal.body
	local tabs = row(modal.body)
	tabs.LayoutOrder = 1
	local tabButtons = {}
	for index, name in ipairs({ "Обзор", "Запасы", "Заметки" }) do
		local tab = Kit.button(host, tabs, name)
		tab.root.LayoutOrder = index
		tab.root.Size = UDim2.fromOffset(104, 44)
		tabButtons[index] = tab
	end
	local function selectTab(chosen)
		for index, tab in ipairs(tabButtons) do
			if index == chosen then tab.force("Focused") else tab.clearForce() end
		end
	end
	for index, tab in ipairs(tabButtons) do
		host.connect(tab.root.MouseButton1Click, function()
			selectTab(index)
		end)
	end
	selectTab(1)
	local cards = row(modal.body)
	cards.LayoutOrder = 2
	local cardRoots = {}
	for index, card in ipairs(sample.cards) do
		local panel = Kit.panel(host, cards)
		panel.root.LayoutOrder = index
		panel.root.Size = UDim2.fromOffset(128, 108)
		local heading = Instance.new("TextLabel")
		heading.BackgroundTransparency = 1
		heading.Size = UDim2.new(1, 0, 0, 20)
		heading.Font = Enum.Font.GothamMedium
		heading.TextSize = 14
		heading.TextXAlignment = Enum.TextXAlignment.Left
		heading.TextColor3 = Color3.fromRGB(226, 221, 212)
		heading.Text = card.title
		heading.Parent = panel.root
		local body = Instance.new("TextLabel")
		body.BackgroundTransparency = 1
		body.Position = UDim2.fromOffset(0, 24)
		body.Size = UDim2.new(1, 0, 1, -24)
		body.Font = Enum.Font.Gotham
		body.TextSize = 13
		body.TextWrapped = true
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextColor3 = Color3.fromRGB(154, 148, 140)
		body.Text = card.body
		body.Parent = panel.root
		cardRoots[index] = panel.root
	end
	local progress = Kit.progress(host, modal.body)
	progress.root.LayoutOrder = 3
	progress.setRatio(sample.progress)
	local actions = row(modal.body)
	actions.LayoutOrder = 4
	local accept = Kit.button(host, actions, "Принять")
	accept.root.LayoutOrder = 1
	accept.root.Size = UDim2.fromOffset(148, 44)
	local locked = Kit.button(host, actions, "Закрыто")
	locked.root.LayoutOrder = 2
	locked.root.Size = UDim2.fromOffset(148, 44)
	locked.setDisabled(true)
	local prompt = Kit.prompt(host, modal.body, "Демонстрационные данные. Игровые действия не отправляются.")
	prompt.root.LayoutOrder = 5
	prompt.root.Size = UDim2.new(1, 0, 0, 36)

	local inspector = Kit.panel(host, gui)
	inspector.setPadding(8)
	inspector.root.ClipsDescendants = true
	inspector.root.ZIndex = 12
	local inspectorList = Instance.new("UIListLayout")
	inspectorList.FillDirection = Enum.FillDirection.Vertical
	inspectorList.Padding = UDim.new(0, 6)
	inspectorList.SortOrder = Enum.SortOrder.LayoutOrder
	inspectorList.Parent = inspector.root
	local themeRow = row(inspector.root)
	themeRow.LayoutOrder = 1
	for index, name in ipairs(Theme.names()) do
		local choice = Kit.button(host, themeRow, name)
		choice.root.LayoutOrder = index
		choice.root.Size = UDim2.fromOffset(80, 44)
		host.connect(choice.root.MouseButton1Click, function()
			host.setTheme(name)
		end)
	end
	local stateRow = row(inspector.root)
	stateRow.LayoutOrder = 2
	local sampleButton = Kit.button(host, stateRow, "Sample")
	sampleButton.root.LayoutOrder = 1
	sampleButton.root.Size = UDim2.fromOffset(80, 44)
	local states = { "Default", "Hover", "Pressed", "Disabled", "Focused" }
	for index, state in ipairs(states) do
		local choice = Kit.button(host, stateRow, state)
		choice.root.LayoutOrder = index + 1
		choice.root.Size = UDim2.fromOffset(80, 44)
		host.connect(choice.root.MouseButton1Click, function()
			if state == "Default" then sampleButton.clearForce() else sampleButton.force(state) end
		end)
	end
	local motion = Kit.button(host, stateRow, host.reduceMotion and "Reduced" or "Motion")
	motion.root.LayoutOrder = 8
	motion.root.Size = UDim2.fromOffset(80, 44)
	host.connect(motion.root.MouseButton1Click, function()
		host.setReduceMotion(not host.reduceMotion)
		motion.root.Text = host.reduceMotion and "Reduced" or "Motion"
	end)
	local windowToggle = Kit.button(host, stateRow, "Window")
	windowToggle.root.LayoutOrder = 9
	windowToggle.root.Size = UDim2.fromOffset(80, 44)
	host.connect(windowToggle.root.MouseButton1Click, function()
		if modal.isOpen() then modal.close() else modal.open() end
	end)

	local function layout()
		local size = gui.AbsoluteSize
		local width, height = size.X, size.Y
		if width < 50 or height < 50 then
			local camera = workspace.CurrentCamera
			local viewport = camera and camera.ViewportSize
			if viewport then
				width, height = viewport.X, viewport.Y
			else
				width, height = 1280, 720
			end
		end
		local plan = Layout.demo(width, height)
		place(hud, plan.hud)
		place(modal, plan.window)
		place(inspector, plan.inspector)
		local inner = math.max(0, plan.window.w - 24)
		local tabW = math.max(72, math.floor((inner - 12) / 3))
		for _, tab in ipairs(tabButtons) do
			tab.root.Size = UDim2.fromOffset(tabW, 44)
		end
		local cardW = math.floor((inner - 12) / 3)
		if cardW < 96 then cardW = math.max(72, inner) end
		for _, cardRoot in ipairs(cardRoots) do
			cardRoot.Size = UDim2.fromOffset(cardW, 108)
		end
		local counterW = math.max(72, math.floor((plan.hud.w - 8 - 44 * 3 - 8 * 4) / 2))
		gold.root.Size = UDim2.fromOffset(counterW, 44)
		essence.root.Size = UDim2.fromOffset(counterW, 44)
	end
	layout()
	host.connect(gui:GetPropertyChangedSignal("AbsoluteSize"), layout)
	modal.open()
	surface.track(function() end)
end

local function refresh()
	if Gate.allowed(RunService:IsStudio(), workspace:GetAttribute("UIFoundationDemo") == true) then
		show()
	else
		hide()
	end
end

workspace:GetAttributeChangedSignal("UIFoundationDemo"):Connect(refresh)
refresh()
