--!nonstrict
-- Roblox mount for the shared UI tokens. No remotes and no profile mutation.
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Shared = game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Theme = require(Shared.ui.Theme)
local Motion = require(Shared.ui.Motion)
local Interact = require(Shared.ui.Interact)
local Windows = require(Shared.ui.Windows)
local Decor = require(Shared.ui.Decor)

local Kit = {}
local nextId = 0

local function key()
	nextId += 1
	return tostring(nextId)
end

local function rgb(value)
	return Color3.fromRGB(value[1], value[2], value[3])
end

local function font(name)
	if name == "GothamMedium" then return Enum.Font.GothamMedium end
	if name == "GothamBold" then return Enum.Font.GothamBold end
	return Enum.Font.Gotham
end

local function pointer(input)
	local kind = input.UserInputType
	return kind == Enum.UserInputType.MouseButton1
		or kind == Enum.UserInputType.Touch
		or kind == Enum.UserInputType.Gamepad1
		or kind == Enum.UserInputType.Gamepad2
		or kind == Enum.UserInputType.Gamepad3
		or kind == Enum.UserInputType.Gamepad4
end

local function corner(parent, radius)
	local object = Instance.new("UICorner")
	object.CornerRadius = UDim.new(0, radius)
	object.Parent = parent
	return object
end

local function stroke(parent, color, thickness)
	local object = Instance.new("UIStroke")
	object.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	object.Color = color
	object.Thickness = thickness
	object.Parent = parent
	return object
end

local function circle(parent)
	local object = Instance.new("UICorner")
	object.CornerRadius = UDim.new(1, 0)
	object.Parent = parent
	return object
end

local function dormant(parent, name)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Active = false
	frame.Size = UDim2.fromScale(1, 1)
	frame.ZIndex = 1
	frame.Parent = parent
	return frame
end

local function engraving(parent, color, radius)
	local inset = Decor.inset
	local guide = Instance.new("Frame")
	guide.Name = "engraving"
	guide.BackgroundTransparency = 1
	guide.BorderSizePixel = 0
	guide.Active = false
	guide.Position = UDim2.fromOffset(inset, inset)
	guide.Size = UDim2.new(1, -inset * 2, 1, -inset * 2)
	guide.ZIndex = 2
	guide.Parent = parent
	corner(guide, math.max(0, radius - inset))
	return stroke(guide, color, 1)
end

local function sheen(parent, color, transparency, radius)
	local inset = Decor.inset
	local band = Instance.new("Frame")
	band.Name = "sheen"
	band.BackgroundColor3 = color
	band.BackgroundTransparency = transparency
	band.BorderSizePixel = 0
	band.Active = false
	band.Position = UDim2.fromOffset(inset, inset)
	band.Size = UDim2.new(1, -inset * 2, 0, Decor.sheenHeight)
	band.ZIndex = 1
	band.Parent = parent
	corner(band, math.max(0, radius - inset))
	return band
end

function Kit.host()
	local self = {
		theme = Theme.resolve("Default"),
		reduceMotion = false,
		tweens = {},
		connections = {},
		widgets = {},
		controls = {},
		modals = {},
		windows = Windows.new(),
	}
	function self.cancel(name)
		local old = self.tweens[name]
		if old then old:Cancel() end
		self.tweens[name] = nil
	end
	function self.play(name, instance, kind, props)
		self.cancel(name)
		local duration = Motion.seconds(kind, self.reduceMotion)
		if duration <= 0 then
			for field, value in pairs(props) do instance[field] = value end
			return
		end
		local animation = TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
		self.tweens[name] = animation
		animation:Play()
	end
	function self.connect(signal, callback)
		local connection = signal:Connect(callback)
		table.insert(self.connections, connection)
		return connection
	end
	function self.watch(widget)
		table.insert(self.widgets, widget)
	end
	local inputKind = "Mouse"
	local function rememberInput(last)
		if last and last.Name then
			inputKind = Interact.inputKind(last.Name)
		end
	end
	function self.inputKind()
		return inputKind
	end
	function self.controlFor(instance)
		if instance == nil then
			return nil
		end
		for _, widget in ipairs(self.controls) do
			if widget.root == instance then
				return widget
			end
		end
		return nil
	end
	function self.windowOf(object)
		local current = object
		while current do
			for id, modal in pairs(self.modals) do
				if current == modal.window or current == modal.body then
					return id
				end
			end
			current = current.Parent
		end
		return nil
	end
	function self.describe(instance)
		if instance == nil or instance.Parent == nil then
			return {
				id = instance,
				present = instance ~= nil,
				mounted = false,
				visible = false,
				ancestorsVisible = false,
				selectable = false,
				disabled = true,
			}
		end
		local visible = true
		if instance:IsA("GuiObject") then
			visible = instance.Visible
		end
		local ancestors = true
		local parent = instance.Parent
		while parent and parent ~= game do
			if parent:IsA("GuiObject") and parent.Visible == false then
				ancestors = false
				break
			end
			if parent:IsA("LayerCollector") and parent.Enabled == false then
				ancestors = false
				break
			end
			parent = parent.Parent
		end
		local widget = self.controlFor(instance)
		return {
			id = widget or instance,
			present = true,
			mounted = true,
			visible = visible,
			ancestorsVisible = ancestors,
			selectable = (not instance:IsA("GuiObject")) or instance.Selectable ~= false,
			disabled = widget ~= nil and widget.disabled() or false,
			window = widget and widget.windowId or nil,
			prefer = widget and widget.prefer,
		}
	end
	function self.order()
		local list = {}
		for _, widget in ipairs(self.controls) do
			table.insert(list, self.describe(widget.root))
		end
		return list
	end
	function self.nextSelectable(current)
		return Interact.handoff(self.order(), current, self.windows.current())
	end
	function self.firstInside(windowId)
		return Interact.firstInside(self.order(), windowId)
	end
	function self.retarget(windowId)
		for _, widget in ipairs(self.controls) do
			if widget.windowId == windowId and widget.apply then
				widget.apply()
			end
		end
	end
	function self.releaseHiddenSelection()
		local selected = GuiService.SelectedObject
		local described = self.describe(selected)
		if selected ~= nil and not Interact.available(described, self.windows.current()) then
			GuiService.SelectedObject = nil
		end
	end
	function self.assignSelection(choice)
		if typeof(choice) == "Instance" then
			GuiService.SelectedObject = choice
		elseif type(choice) == "table" and choice.root then
			GuiService.SelectedObject = choice.root
		else
			GuiService.SelectedObject = nil
		end
	end
	function self.setTheme(name)
		self.theme = Theme.resolve(name)
		for _, widget in ipairs(self.widgets) do widget.apply() end
	end
	function self.setReduceMotion(value)
		self.reduceMotion = value == true
		if self.reduceMotion then
			for _, animation in pairs(self.tweens) do animation:Cancel() end
			table.clear(self.tweens)
		end
		for _, widget in ipairs(self.widgets) do widget.apply() end
	end
	function self.destroy()
		local selected = GuiService.SelectedObject
		if self.controlFor(selected) then
			GuiService.SelectedObject = nil
		end
		for _, widget in ipairs(self.widgets) do
			if widget.destroy then widget.destroy() end
		end
		for _, animation in pairs(self.tweens) do animation:Cancel() end
		for _, connection in ipairs(self.connections) do connection:Disconnect() end
		table.clear(self.tweens)
		table.clear(self.connections)
		table.clear(self.widgets)
		table.clear(self.controls)
		table.clear(self.modals)
	end
	local ok, lastInput = pcall(function()
		return UserInputService:GetLastInputType()
	end)
	if ok then
		rememberInput(lastInput)
	end
	self.connect(UserInputService.LastInputTypeChanged, rememberInput)
	return self
end

local function palette(host, role, state, marks)
	local paint = Theme.paint(host.theme, role, state, {
		selected = marks.selected == true,
		focused = marks.focused == true,
	})
	return rgb(paint.background), rgb(paint.line), rgb(paint.text), paint.thickness
end

local function control(host, className, parent, label, role)
	local icon = role == "icon"
	local tokens = host.theme
	local root = Instance.new(className)
	root.AutoButtonColor = false
	root.BackgroundColor3 = rgb(tokens.color.raised)
	root.BorderSizePixel = 0
	root.Text = label
	root.TextColor3 = rgb(tokens.color.ink)
	root.Font = font(tokens.font.body)
	root.TextSize = icon and tokens.size.title or tokens.size.text
	root.TextWrapped = true
	root.Selectable = true
	root.Size = icon and UDim2.fromOffset(tokens.size.icon, tokens.size.icon) or UDim2.fromOffset(tokens.size.button, tokens.size.touch)
	root.Parent = parent
	corner(root, icon and math.floor(tokens.size.icon / 2) or tokens.size.radius)
	local border = stroke(root, rgb(tokens.color.engraving), tokens.stroke.thickness)
	local scale = Instance.new("UIScale")
	scale.Parent = root
	local halo = dormant(root, "fx-halo")
	local ring = nil
	local ringStroke = nil
	if icon then
		ring = Instance.new("Frame")
		ring.Name = "ring"
		ring.BackgroundTransparency = 1
		ring.BorderSizePixel = 0
		ring.Active = false
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.fromScale(0.5, 0.5)
		ring.Size = UDim2.new(1, -10, 1, -10)
		ring.ZIndex = 2
		ring.Parent = root
		circle(ring)
		ringStroke = stroke(ring, rgb(tokens.color.engraving), 1)
	end
	local id = key()
	local flags = { disabled = false, pressed = false, hover = false, focused = false, selected = false }
	local forced = nil
	local widget = {
		root = root,
		navigable = true,
		prefer = true,
		windowId = host.windowOf(parent),
		fx = { halo = halo, glyph = ring },
	}
	function widget.disabled()
		return flags.disabled
	end
	function widget.apply()
		local state = forced or Interact.resolve(flags)
		local marks = Interact.marks(flags)
		local visual = Interact.visual(state, host.reduceMotion)
		local background, line, text, thickness = palette(host, role, state, marks)
		local motion = state == "Pressed" and "press" or "hover"
		local shown = widget.windowId == nil or host.windows.isOpen(widget.windowId)
		local selectable = shown and forced ~= "Disabled" and marks.selectable
		root.Selectable = selectable
		root.Active = selectable
		root.Font = font(host.theme.font.body)
		root.TextSize = icon and host.theme.size.title or host.theme.size.text
		host.play(id, root, motion, { BackgroundColor3 = background, TextColor3 = text, TextTransparency = visual.textTransparency })
		host.play(id .. ":line", border, motion, { Color = line, Thickness = thickness })
		if ringStroke then
			host.play(id .. ":ring", ringStroke, motion, { Color = line })
		end
		host.play(id .. ":scale", scale, motion, { Scale = visual.scale })
	end
	function widget.setDisabled(value)
		local wasFocused = GuiService.SelectedObject == root
		flags.disabled = value == true
		if flags.disabled then
			flags.pressed = false
			flags.hover = false
		end
		widget.apply()
		if flags.disabled and wasFocused then
			host.assignSelection(host.nextSelectable(widget))
		end
	end
	function widget.setSelected(value)
		flags.selected = value == true
		widget.apply()
	end
	function widget.force(state)
		forced = state
		widget.apply()
	end
	function widget.clearForce()
		forced = nil
		widget.apply()
	end
	host.connect(root.MouseEnter, function()
		if flags.disabled then return end
		flags.hover = true
		widget.apply()
	end)
	host.connect(root.MouseLeave, function()
		flags.hover = false
		flags.pressed = false
		widget.apply()
	end)
	host.connect(root.InputBegan, function(input)
		if flags.disabled or not pointer(input) then return end
		flags.pressed = true
		widget.apply()
	end)
	host.connect(root.InputEnded, function(input)
		if not pointer(input) then return end
		flags.pressed = false
		widget.apply()
	end)
	host.connect(root.Activated, function()
		if flags.disabled then return end
		if widget.onActivated then widget.onActivated() end
	end)
	host.connect(GuiService:GetPropertyChangedSignal("SelectedObject"), function()
		flags.focused = GuiService.SelectedObject == root
		widget.apply()
	end)
	table.insert(host.controls, widget)
	host.watch(widget)
	widget.apply()
	return widget
end

function Kit.button(host, parent, label, role)
	return control(host, "TextButton", parent, label, role or "button")
end

function Kit.iconButton(host, parent, mark)
	return control(host, "TextButton", parent, mark, "icon")
end

function Kit.panel(host, parent, role)
	local kind = role or "panel"
	local tokens = host.theme
	local paint = Theme.paint(tokens, kind, "Default")
	local root = Instance.new("Frame")
	root.BackgroundColor3 = rgb(paint.background)
	root.BackgroundTransparency = paint.transparency
	root.BorderSizePixel = 0
	root.Parent = parent
	corner(root, tokens.size.radius)
	local border = stroke(root, rgb(paint.line), tokens.stroke.thickness)
	local inner = engraving(root, rgb(tokens.color.engraving), tokens.size.radius)
	local lift = nil
	if kind == "panel" then
		lift = sheen(root, rgb(tokens.color.veil), tokens.transparency.sheen, tokens.size.radius)
	end
	local content = Instance.new("Frame")
	content.Name = "content"
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Size = UDim2.fromScale(1, 1)
	content.ZIndex = 3
	content.Active = false
	content.Parent = root
	local padding = Instance.new("UIPadding")
	local pad = tokens.size.pad
	padding.PaddingTop = UDim.new(0, pad)
	padding.PaddingBottom = UDim.new(0, pad)
	padding.PaddingLeft = UDim.new(0, pad)
	padding.PaddingRight = UDim.new(0, pad)
	padding.Parent = content
	local widget = { root = root, content = content, fx = {} }
	function widget.apply()
		local tokensNow = host.theme
		local nextPaint = Theme.paint(tokensNow, kind, "Default")
		root.BackgroundColor3 = rgb(nextPaint.background)
		root.BackgroundTransparency = nextPaint.transparency
		border.Color = rgb(nextPaint.line)
		inner.Color = rgb(tokensNow.color.engraving)
		if lift then
			lift.BackgroundColor3 = rgb(tokensNow.color.veil)
			lift.BackgroundTransparency = tokensNow.transparency.sheen
		end
	end
	function widget.setPadding(amount)
		local px = UDim.new(0, amount)
		padding.PaddingTop = px
		padding.PaddingBottom = px
		padding.PaddingLeft = px
		padding.PaddingRight = px
	end
	host.watch(widget)
	return widget
end

function Kit.label(host, parent, text, role)
	local style = Theme.textStyle(host.theme, role)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Font = font(style.font)
	label.TextSize = style.text
	label.TextColor3 = rgb(style.color)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.Text = text
	label.Parent = parent
	local widget = { root = label }
	function widget.apply()
		local nextStyle = Theme.textStyle(host.theme, role)
		label.Font = font(nextStyle.font)
		label.TextSize = nextStyle.text
		label.TextColor3 = rgb(nextStyle.color)
	end
	function widget.setText(value)
		label.Text = value
	end
	host.watch(widget)
	return widget
end

function Kit.resourceCounter(host, parent, title)
	local panel = Kit.panel(host, parent, "counter")
	panel.setPadding(6)
	panel.root.Size = UDim2.fromOffset(host.theme.size.counterMin, host.theme.size.touch)
	local socket = host.theme.size.socket
	local mark = Instance.new("Frame")
	mark.Name = "fx-glyph"
	mark.BackgroundTransparency = 1
	mark.BorderSizePixel = 0
	mark.Active = false
	mark.Size = UDim2.fromOffset(socket, socket)
	mark.Position = UDim2.fromOffset(0, 4)
	mark.ZIndex = 3
	mark.Parent = panel.content
	circle(mark)
	local markLine = stroke(mark, rgb(host.theme.color.engraving), 1)
	panel.fx.glyph = mark
	local caption = Kit.label(host, panel.content, title, "caption")
	caption.root.Position = UDim2.fromOffset(socket + 4, 0)
	caption.root.Size = UDim2.new(1, -(socket + 4), 0, host.theme.size.caption)
	caption.root.AutomaticSize = Enum.AutomaticSize.None
	local value = Kit.label(host, panel.content, "0", "heading")
	value.root.Position = UDim2.fromOffset(socket + 4, host.theme.size.caption)
	value.root.Size = UDim2.new(1, -(socket + 4), 1, -host.theme.size.caption)
	value.root.AutomaticSize = Enum.AutomaticSize.None
	local previous = panel.apply
	function panel.apply()
		previous()
		markLine.Color = rgb(host.theme.color.engraving)
	end
	function panel.setValue(text)
		value.setText(tostring(text))
	end
	return panel
end

function Kit.tooltip(host, parent)
	local panel = Kit.panel(host, parent, "tooltip")
	panel.root.Visible = false
	panel.root.AutomaticSize = Enum.AutomaticSize.XY
	panel.root.ZIndex = 20
	panel.content.AutomaticSize = Enum.AutomaticSize.XY
	panel.content.Size = UDim2.fromOffset(0, 0)
	local label = Kit.label(host, panel.content, "", "body")
	label.root.AutomaticSize = Enum.AutomaticSize.XY
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(220, 80)
	limit.Parent = label.root
	function panel.setText(text)
		label.setText(text)
	end
	function panel.show(owner)
		panel.root.Visible = true
		local origin = owner.AbsolutePosition - parent.AbsolutePosition
		panel.root.Position = UDim2.fromOffset(origin.X, origin.Y + owner.AbsoluteSize.Y + host.theme.size.gap)
	end
	function panel.hide()
		panel.root.Visible = false
	end
	return panel
end

function Kit.progress(host, parent)
	local trackPaint = Theme.paint(host.theme, "progressTrack", "Default")
	local fillPaint = Theme.paint(host.theme, "progressFill", "Default")
	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, 0, 0, host.theme.size.progress)
	track.BackgroundColor3 = rgb(trackPaint.background)
	track.BorderSizePixel = 0
	track.Parent = parent
	corner(track, math.floor(host.theme.size.radius / 2))
	local trackLine = stroke(track, rgb(trackPaint.line), 1)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = rgb(fillPaint.background)
	fill.BorderSizePixel = 0
	fill.Parent = track
	corner(fill, math.floor(host.theme.size.radius / 2))
	local liquid = dormant(fill, "fx-liquid")
	local widget = { root = track, ratio = 0, fx = { liquid = liquid } }
	function widget.setRatio(ratio)
		widget.ratio = math.clamp(tonumber(ratio) or 0, 0, 1)
		fill.Size = UDim2.fromScale(widget.ratio, 1)
	end
	function widget.apply()
		local trackNow = Theme.paint(host.theme, "progressTrack", "Default")
		local fillNow = Theme.paint(host.theme, "progressFill", "Default")
		track.BackgroundColor3 = rgb(trackNow.background)
		trackLine.Color = rgb(trackNow.line)
		fill.BackgroundColor3 = rgb(fillNow.background)
	end
	host.watch(widget)
	return widget
end

function Kit.prompt(host, parent, text)
	local widget = Kit.label(host, parent, text, "body")
	widget.root.Size = UDim2.new(1, 0, 0, host.theme.size.prompt)
	widget.root.AutomaticSize = Enum.AutomaticSize.None
	return widget
end

function Kit.scroller(host, parent)
	local frame = Instance.new("ScrollingFrame")
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.ScrollBarThickness = 4
	frame.ScrollBarImageColor3 = rgb(host.theme.color.line)
	frame.ScrollingDirection = Enum.ScrollingDirection.Y
	frame.AutomaticCanvasSize = Enum.AutomaticSize.None
	frame.CanvasSize = UDim2.fromOffset(0, 0)
	frame.Parent = parent
	local widget = { root = frame }
	function widget.apply()
		frame.ScrollBarImageColor3 = rgb(host.theme.color.line)
	end
	function widget.setCanvas(height, viewport, scrolls)
		frame.CanvasSize = UDim2.fromOffset(0, height)
		frame.ScrollingEnabled = scrolls == true
		if not scrolls then
			frame.CanvasPosition = Vector2.zero
		end
		widget.viewport = viewport
	end
	host.watch(widget)
	return widget
end

function Kit.modal(host, parent)
	local tokens = host.theme
	local id = "modal-" .. key()
	local window = Instance.new("CanvasGroup")
	window.Name = "FoundationWindow"
	window.BackgroundColor3 = rgb(tokens.color.surface)
	window.BackgroundTransparency = tokens.transparency.panel
	window.BorderSizePixel = 0
	window.GroupTransparency = 1
	window.Visible = false
	window.ClipsDescendants = true
	window.ZIndex = 6
	window.Parent = parent
	corner(window, tokens.size.radius)
	local border = stroke(window, rgb(tokens.color.line), tokens.stroke.thickness)
	local inner = engraving(window, rgb(tokens.color.engraving), tokens.size.radius)
	local lift = sheen(window, rgb(tokens.color.veil), tokens.transparency.sheen, tokens.size.radius)
	local smoke = dormant(window, "fx-smoke")
	local pulse = dormant(window, "fx-pulse")
	local scale = Instance.new("UIScale")
	scale.Scale = 0.98
	scale.Parent = window
	local title = Kit.label(host, window, "", "heading")
	title.root.ZIndex = 7
	title.root.TextYAlignment = Enum.TextYAlignment.Center
	title.root.AutomaticSize = Enum.AutomaticSize.None
	local opened = false
	local dismiss = nil
	local widget = { root = window, window = window, title = title.root, fx = { smoke = smoke, pulse = pulse } }
	host.modals[id] = widget
	local close = Kit.iconButton(host, window, "x")
	close.prefer = false
	close.root.ZIndex = 8
	local body = Kit.scroller(host, window)
	body.root.ZIndex = 7
	body.root.Position = UDim2.fromOffset(0, tokens.size.chrome)
	widget.body = body.root
	widget.close = close
	local function unbind()
		if dismiss then
			dismiss:Disconnect()
			dismiss = nil
		end
	end
	function widget.peekFocus()
		return host.windows.peek(id)
	end
	local function focusInstance(focus)
		if typeof(focus) == "Instance" then
			return focus
		end
		if type(focus) == "table" and focus.root ~= nil then
			return focus.root
		end
		return nil
	end
	local function restoreFocus(focus)
		local instance = focusInstance(focus)
		local described = if instance ~= nil then host.describe(instance) else nil
		host.assignSelection(Interact.restore(described, host.order(), nil))
	end
	local function animateClose(ticket, restore)
		opened = false
		unbind()
		host.retarget(id)
		host.cancel(ticket.keys.group)
		host.cancel(ticket.keys.scale)
		if restore == false then
			window.Visible = false
			window.GroupTransparency = 1
			scale.Scale = 0.98
			return
		end
		local duration = Motion.seconds("close", host.reduceMotion)
		if duration <= 0 then
			window.Visible = false
			window.GroupTransparency = 1
			scale.Scale = 0.98
		else
			host.play(ticket.keys.group, window, "close", { GroupTransparency = 1 })
			host.play(ticket.keys.scale, scale, "close", { Scale = 0.98 })
			task.delay(duration, function()
				if window.Parent and host.windows.shouldHide(id, ticket.generation) then
					window.Visible = false
				end
			end)
		end
		restoreFocus(ticket.focus)
	end
	function widget.apply()
		local now = host.theme
		local paint = Theme.paint(now, "modal", "Default")
		window.BackgroundColor3 = rgb(paint.background)
		window.BackgroundTransparency = paint.transparency
		border.Color = rgb(paint.line)
		inner.Color = rgb(now.color.engraving)
		lift.BackgroundColor3 = rgb(now.color.veil)
		lift.BackgroundTransparency = now.transparency.sheen
		body.root.Position = UDim2.fromOffset(0, now.size.chrome)
	end
	function widget.setTitle(text)
		title.setText(text)
	end
	function widget.placeChrome(chrome)
		title.root.Position = UDim2.fromOffset(chrome.title.x, chrome.title.y)
		title.root.Size = UDim2.fromOffset(chrome.title.w, chrome.title.h)
		close.root.Position = UDim2.fromOffset(chrome.close.x, chrome.close.y)
		close.root.Size = UDim2.fromOffset(chrome.close.w, chrome.close.h)
	end
	function widget.placeBody(plan)
		body.root.Size = UDim2.new(1, 0, 0, plan.viewportH)
		body.setCanvas(plan.contentH, plan.viewportH, plan.scrolls)
	end
	function widget.isOpen()
		return opened
	end
	function widget.open()
		if opened then return end
		local remembered = GuiService.SelectedObject
		local ownerWidget = host.controlFor(remembered)
		local ownerId = ownerWidget and ownerWidget.windowId or nil
		local focusTarget = remembered
		if ownerId ~= nil then
			local ownerModal = host.modals[ownerId]
			focusTarget = ownerModal and ownerModal.peekFocus() or nil
		elseif ownerWidget then
			focusTarget = ownerWidget
		end
		local ticket, displaced = host.windows.open(id, focusTarget, ownerId)
		if displaced then
			local other = host.modals[displaced.id]
			if other and other ~= widget then
				other.finishClose(displaced, false)
			end
		end
		opened = true
		window.Visible = true
		host.retarget(id)
		if not dismiss then
			dismiss = UserInputService.InputBegan:Connect(function(input)
				if Windows.dismiss(input.KeyCode.Name) and opened then
					widget.close()
				end
			end)
		end
		host.play(ticket.keys.group, window, "open", { GroupTransparency = 0 })
		host.play(ticket.keys.scale, scale, "open", { Scale = 1 })
		if Interact.claimsFocus(host.inputKind()) then
			host.assignSelection(host.firstInside(id))
		else
			host.releaseHiddenSelection()
		end
	end
	function widget.finishClose(ticket, restore)
		animateClose(ticket, restore)
	end
	function widget.close()
		if not opened then return end
		animateClose(host.windows.close(id), true)
	end
	function widget.destroy()
		unbind()
		if opened then
			host.windows.close(id)
			opened = false
		end
		host.cancel(id .. ":group")
		host.cancel(id .. ":scale")
	end
	close.onActivated = function()
		widget.close()
	end
	host.watch(widget)
	return widget
end

return Kit
