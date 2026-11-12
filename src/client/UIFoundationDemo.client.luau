--!nonstrict
-- Studio developer preview for the Alchemy / Arcane Matte skin on the UI foundation.
-- It does not replace PotionTycoonUI, bind M / I / P, or send a remote.
-- Escape and gamepad B close only this preview window.
--
-- In Roblox Studio the preview is already on. Press Play to see it.
-- Workspace.UIFoundationDemo is true in the place; set it to false to hide
-- the preview. A published server never shows this screen.
--
-- Engine checks left for Studio: GuiService selection on a gamepad, Button B,
-- a hidden or disabled previous target, and scrolling a clipped column.
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
local mounted = {}

local function playerGui()
	return player:FindFirstChildOfClass("PlayerGui")
end

local function hide()
	if host then
		host.destroy()
		host = nil
	end
	table.clear(mounted)
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

local function own(id, widget)
	mounted[id] = widget
	return widget
end

local function show()
-- AG64_BEGIN_HIDE_DEMO
	if workspace:GetAttribute("LandscapeHUDEnabled")~=false then hide(); return end
-- AG64_END_HIDE_DEMO
	if not Gate.preview(RunService:IsStudio(), workspace:GetAttribute("UIFoundationDemo")) then
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
	local tokens = host.theme
	local folder = player:WaitForChild("PlayerGui")
	if not Gate.preview(RunService:IsStudio(), workspace:GetAttribute("UIFoundationDemo")) then
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
	hud.setPadding(0)
	hud.root.ClipsDescendants = true
	hud.root.ZIndex = 4
	local gold = own("gold", Kit.resourceCounter(host, hud.root, "Gold"))
	gold.setValue(resources.goldText)
	local essence = own("essence", Kit.resourceCounter(host, hud.root, "Essence"))
	essence.setValue(resources.essenceText)
	local tooltip = Kit.tooltip(host, gui)
	tooltip.root.ZIndex = 30
	for _, item in ipairs({ { "nav-m", "M", "Магазин" }, { "nav-i", "I", "Инвентарь" }, { "nav-p", "P", "Фамильяры" } }) do
		local icon = own(item[1], Kit.iconButton(host, hud.root, item[2]))
		icon.root.ZIndex = 5
		local function showTip()
			tooltip.setText(item[3])
			tooltip.show(icon.root)
		end
		host.connect(icon.root.MouseEnter, showTip)
		host.connect(icon.root.SelectionGained, showTip)
		host.connect(icon.root.MouseLeave, function() tooltip.hide() end)
		host.connect(icon.root.SelectionLost, function() tooltip.hide() end)
	end

	local modal = Kit.modal(host, gui)
	modal.setTitle("Алхимия")
	for index, name in ipairs({ "Обзор", "Запасы", "Заметки" }) do
		local tab = own("tab-" .. index, Kit.button(host, modal.body, name, "tab"))
		tab.onActivated = function()
			for other = 1, 3 do
				mounted["tab-" .. other].setSelected(other == index)
			end
		end
	end
	mounted["tab-1"].setSelected(true)
	for index, card in ipairs(sample.cards) do
		local panel = own("card-" .. index, Kit.panel(host, modal.body, "card"))
		panel.setPadding(tokens.size.inset)
		local heading = Kit.label(host, panel.content, card.title, "heading")
		heading.root.Size = UDim2.new(1, 0, 0, tokens.size.title)
		heading.root.AutomaticSize = Enum.AutomaticSize.None
		local copy = Kit.label(host, panel.content, card.body, "body")
		copy.root.Position = UDim2.fromOffset(0, tokens.size.title + tokens.size.hudPad)
		copy.root.Size = UDim2.new(1, 0, 1, -(tokens.size.title + tokens.size.hudPad))
		copy.root.AutomaticSize = Enum.AutomaticSize.None
	end
	local progress = own("progress", Kit.progress(host, modal.body))
	progress.setRatio(sample.progress)
	local accept = own("accept", Kit.button(host, modal.body, "Принять"))
	accept.onActivated = function() end
	local locked = own("locked", Kit.button(host, modal.body, "Закрыто"))
	locked.setDisabled(true)
	own("prompt", Kit.prompt(host, modal.body, "Демонстрационные данные. Игровые действия не отправляются."))

	local inspector = Kit.panel(host, gui)
	inspector.setPadding(0)
	inspector.root.ClipsDescendants = true
	inspector.root.ZIndex = 12
	local inspectorScroll = Kit.scroller(host, inspector.root)
	inspectorScroll.root.Size = UDim2.fromScale(1, 1)
	inspectorScroll.root.ZIndex = 13
	for _, name in ipairs(Theme.names()) do
		local choice = own("theme-" .. name, Kit.button(host, inspectorScroll.root, name))
		choice.onActivated = function()
			host.setTheme(name)
		end
	end
	local sampleButton = own("sample", Kit.button(host, inspectorScroll.root, "Sample"))
	for _, state in ipairs({ "Default", "Hover", "Pressed", "Disabled", "Focused" }) do
		local choice = own("state-" .. state, Kit.button(host, inspectorScroll.root, state))
		choice.onActivated = function()
			if state == "Default" then sampleButton.clearForce() else sampleButton.force(state) end
		end
	end
	local motion = own("motion", Kit.button(host, inspectorScroll.root, host.reduceMotion and "Reduced" or "Motion"))
	motion.onActivated = function()
		host.setReduceMotion(not host.reduceMotion)
		motion.root.Text = host.reduceMotion and "Reduced" or "Motion"
	end
	local windowToggle = own("window", Kit.button(host, inspectorScroll.root, "Window"))
	windowToggle.onActivated = function()
		if modal.isOpen() then modal.close() else modal.open() end
	end
	local note = Kit.modal(host, gui)
	note.setTitle("Заметка")
	local noteCopy = Kit.prompt(host, note.body, "Второе окно для проверки фокуса. Игровых действий нет.")
	local back = Kit.button(host, note.body, "Назад")
	back.onActivated = function()
		note.close()
	end
	local noteToggle = own("note", Kit.button(host, inspectorScroll.root, "Note"))
	noteToggle.onActivated = function()
		if note.isOpen() then note.close() else note.open() end
	end

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
		-- AbsoluteSize is already inside CoreUISafeInsets, so no second inset is added.
		local plan = Layout.demo(width, height)
		place(hud, plan.hud)
		place(modal, plan.window)
		place(note, plan.window)
		place(inspector, plan.inspector)
		modal.placeChrome(plan.chrome)
		modal.placeBody(plan.body)
		note.placeChrome(plan.chrome)
		local noteHeight = tokens.size.pad + tokens.size.prompt + tokens.size.gap + tokens.size.touch + tokens.size.pad
		note.placeBody({
			viewportH = plan.body.viewportH,
			contentH = math.max(plan.body.viewportH, noteHeight),
			scrolls = plan.body.viewportH + 0.5 < noteHeight,
		})
		noteCopy.root.Position = UDim2.fromOffset(tokens.size.pad, tokens.size.pad)
		noteCopy.root.Size = UDim2.new(1, -(tokens.size.pad * 2 + tokens.size.scroll), 0, tokens.size.prompt)
		back.root.Position = UDim2.fromOffset(tokens.size.pad, tokens.size.pad + tokens.size.prompt + tokens.size.gap)
		back.root.Size = UDim2.fromOffset(math.min(tokens.size.button, math.max(tokens.size.touch, plan.window.w - tokens.size.pad * 2 - tokens.size.scroll)), tokens.size.touch)
		inspectorScroll.setCanvas(plan.inspectorColumn.contentH, plan.inspectorColumn.viewportH, plan.inspectorColumn.scrolls)
		local function move(items)
			for _, item in ipairs(items) do
				local widget = mounted[item.id]
				if widget then
					widget.root.Position = UDim2.fromOffset(item.x, item.y)
					widget.root.Size = UDim2.fromOffset(item.w, item.h)
				end
			end
		end
		move(plan.hudItems)
		move(plan.body.items)
		move(plan.inspectorColumn.items)
	end
	layout()
	host.connect(gui:GetPropertyChangedSignal("AbsoluteSize"), layout)
	modal.open()
end

local function refresh()
	if Gate.preview(RunService:IsStudio(), workspace:GetAttribute("UIFoundationDemo")) then
		show()
	else
		hide()
	end
end

workspace:GetAttributeChangedSignal("UIFoundationDemo"):Connect(refresh)
-- AG64_BEGIN_DEMO_ROLLBACK
workspace:GetAttributeChangedSignal("LandscapeHUDEnabled"):Connect(refresh)
-- AG64_END_DEMO_ROLLBACK
refresh()
