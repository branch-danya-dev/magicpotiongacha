--!nonstrict
-- Roblox mount for the shared UI tokens. No remotes and no profile mutation.
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Shared = game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Theme = require(Shared.ui.Theme)
local Motion = require(Shared.ui.Motion)
local Interact = require(Shared.ui.Interact)

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

function Kit.host()
	local self = {
		theme = Theme.resolve("Default"),
		reduceMotion = false,
		tweens = {},
		connections = {},
		widgets = {},
	}
	function self.cancel(key)
		local old = self.tweens[key]
		if old then old:Cancel() end
		self.tweens[key] = nil
	end
	function self.play(key, instance, kind, props)
		self.cancel(key)
		local duration = Motion.seconds(kind, self.reduceMotion)
		if duration <= 0 then
			for field, value in pairs(props) do instance[field] = value end
			return
		end
		local animation = TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
		self.tweens[key] = animation
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
	function self.setTheme(name)
		self.theme = Theme.resolve(name)
		for _, widget in ipairs(self.widgets) do widget.apply() end
	end
	function self.setReduceMotion(value)
		self.reduceMotion = value == true
		for _, widget in ipairs(self.widgets) do widget.apply() end
	end
	function self.destroy()
		for _, animation in pairs(self.tweens) do animation:Cancel() end
		for _, connection in ipairs(self.connections) do connection:Disconnect() end
		table.clear(self.tweens)
		table.clear(self.connections)
		table.clear(self.widgets)
	end
	return self
end

local function palette(host, state)
	local color = host.theme.color
	local background = rgb(color.raised)
	local line = rgb(color.line)
	local text = rgb(color.ink)
	if state == "Hover" then
		background = rgb(color.raised):Lerp(rgb(color.accent), 0.16)
		line = rgb(color.accent)
	elseif state == "Pressed" then
		background = rgb(color.surface)
		line = rgb(color.accent)
	elseif state == "Focused" then
		line = rgb(color.accent)
	elseif state == "Disabled" then
		background = rgb(color.surface)
		text = rgb(color.muted)
	end
	return background, line, text
end

local function control(host, className, parent, label, icon)
	local tokens = host.theme
	local root = Instance.new(className)
	root.AutoButtonColor = false
	root.BackgroundColor3 = rgb(tokens.color.raised)
	root.BorderSizePixel = 0
	root.Text = label
	root.TextColor3 = rgb(tokens.color.ink)
	root.Font = font(tokens.font.body)
	root.TextSize = tokens.size.text
	root.TextWrapped = true
	root.Selectable = true
	root.Size = icon and UDim2.fromOffset(tokens.size.icon, tokens.size.icon) or UDim2.fromOffset(tokens.size.button, tokens.size.touch)
	root.Parent = parent
	corner(root, tokens.size.radius)
	local border = stroke(root, rgb(tokens.color.line), tokens.stroke.thickness)
	local scale = Instance.new("UIScale")
	scale.Parent = root
	local id = key()
	local flags = { disabled = false, pressed = false, hover = false, focused = false }
	local forced = nil
	local widget = { root = root }
	function widget.apply()
		local state = forced or Interact.resolve(flags)
		local visual = Interact.visual(state, host.reduceMotion)
		local background, line, text = palette(host, state)
		local motion = state == "Pressed" and "press" or "hover"
		host.play(id, root, motion, { BackgroundColor3 = background, TextColor3 = text, TextTransparency = visual.textTransparency })
		host.play(id .. ":line", border, motion, { Color = line, Thickness = state == "Focused" and 1.5 or host.theme.stroke.thickness })
		host.play(id .. ":scale", scale, motion, { Scale = visual.scale })
		root.Active = not flags.disabled
	end
	function widget.setDisabled(value)
		flags.disabled = value == true
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
		flags.hover = true
		widget.apply()
	end)
	host.connect(root.MouseLeave, function()
		flags.hover = false
		flags.pressed = false
		widget.apply()
	end)
	host.connect(root.MouseButton1Down, function()
		if flags.disabled then return end
		flags.pressed = true
		widget.apply()
	end)
	host.connect(root.MouseButton1Up, function()
		flags.pressed = false
		widget.apply()
	end)
	host.connect(GuiService:GetPropertyChangedSignal("SelectedObject"), function()
		flags.focused = GuiService.SelectedObject == root
		widget.apply()
	end)
	host.watch(widget)
	widget.apply()
	return widget
end

function Kit.button(host, parent, label)
	return control(host, "TextButton", parent, label, false)
end

function Kit.iconButton(host, parent, mark)
	local widget = control(host, "TextButton", parent, mark, true)
	widget.root.TextSize = host.theme.size.title
	return widget
end

function Kit.panel(host, parent)
	local tokens = host.theme
	local root = Instance.new("Frame")
	root.BackgroundColor3 = rgb(tokens.color.surface)
	root.BackgroundTransparency = tokens.transparency.panel
	root.BorderSizePixel = 0
	root.Parent = parent
	corner(root, tokens.size.radius)
	local border = stroke(root, rgb(tokens.color.line), tokens.stroke.thickness)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, tokens.size.pad)
	padding.PaddingBottom = UDim.new(0, tokens.size.pad)
	padding.PaddingLeft = UDim.new(0, tokens.size.pad)
	padding.PaddingRight = UDim.new(0, tokens.size.pad)
	padding.Parent = root
	local widget = { root = root }
	function widget.apply()
		local tokensNow = host.theme
		root.BackgroundColor3 = rgb(tokensNow.color.surface)
		root.BackgroundTransparency = tokensNow.transparency.panel
		border.Color = rgb(tokensNow.color.line)
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

function Kit.resourceCounter(host, parent, title)
	local panel = Kit.panel(host, parent)
	panel.root.Size = UDim2.fromOffset(132, host.theme.size.hud)
	local caption = Instance.new("TextLabel")
	caption.BackgroundTransparency = 1
	caption.Size = UDim2.new(1, 0, 0, 16)
	caption.Font = font(host.theme.font.body)
	caption.TextSize = 12
	caption.TextXAlignment = Enum.TextXAlignment.Left
	caption.TextColor3 = rgb(host.theme.color.muted)
	caption.Text = title
	caption.Parent = panel.root
	local value = Instance.new("TextLabel")
	value.BackgroundTransparency = 1
	value.Position = UDim2.fromOffset(0, 16)
	value.Size = UDim2.new(1, 0, 1, -16)
	value.Font = font(host.theme.font.title)
	value.TextSize = host.theme.size.title
	value.TextXAlignment = Enum.TextXAlignment.Left
	value.TextColor3 = rgb(host.theme.color.ink)
	value.Text = "0"
	value.Parent = panel.root
	function panel.setValue(text)
		value.Text = tostring(text)
	end
	local paint = panel.apply
	function panel.apply()
		paint()
		caption.TextColor3 = rgb(host.theme.color.muted)
		value.TextColor3 = rgb(host.theme.color.ink)
	end
	return panel
end

function Kit.tooltip(host, parent)
	local panel = Kit.panel(host, parent)
	panel.root.Visible = false
	panel.root.AutomaticSize = Enum.AutomaticSize.XY
	panel.root.ZIndex = 20
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.Font = font(host.theme.font.body)
	label.TextSize = 13
	label.TextColor3 = rgb(host.theme.color.ink)
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = panel.root
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(220, 80)
	limit.Parent = label
	function panel.setText(text)
		label.Text = text
	end
	function panel.show(owner)
		panel.root.Visible = true
		local origin = owner.AbsolutePosition - parent.AbsolutePosition
		panel.root.Position = UDim2.fromOffset(origin.X, origin.Y + owner.AbsoluteSize.Y + 6)
	end
	function panel.hide()
		panel.root.Visible = false
	end
	return panel
end

function Kit.progress(host, parent)
	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, 0, 0, 8)
	track.BackgroundColor3 = rgb(host.theme.color.canvas)
	track.BorderSizePixel = 0
	track.Parent = parent
	corner(track, 4)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = rgb(host.theme.color.accent)
	fill.BorderSizePixel = 0
	fill.Parent = track
	corner(fill, 4)
	local widget = { root = track, ratio = 0 }
	function widget.setRatio(ratio)
		widget.ratio = math.clamp(tonumber(ratio) or 0, 0, 1)
		fill.Size = UDim2.fromScale(widget.ratio, 1)
	end
	function widget.apply()
		track.BackgroundColor3 = rgb(host.theme.color.canvas)
		fill.BackgroundColor3 = rgb(host.theme.color.accent)
	end
	host.watch(widget)
	return widget
end

function Kit.prompt(host, parent, text)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, 18)
	label.Font = font(host.theme.font.body)
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = rgb(host.theme.color.muted)
	label.Text = text
	label.TextWrapped = true
	label.Parent = parent
	local widget = { root = label }
	function widget.setText(value)
		label.Text = value
	end
	function widget.apply()
		label.TextColor3 = rgb(host.theme.color.muted)
	end
	host.watch(widget)
	return widget
end

function Kit.modal(host, parent)
	local tokens = host.theme
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
	local scale = Instance.new("UIScale")
	scale.Scale = 0.98
	scale.Parent = window
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(tokens.size.pad, 8)
	title.Size = UDim2.new(1, -88, 0, 28)
	title.Font = font(tokens.font.title)
	title.TextSize = tokens.size.title
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = rgb(tokens.color.ink)
	title.Text = ""
	title.ZIndex = 7
	title.Parent = window
	local close = Kit.iconButton(host, window, "x")
	close.root.Position = UDim2.new(1, -tokens.size.icon - 8, 0, 8)
	close.root.ZIndex = 8
	local body = Instance.new("Frame")
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(tokens.size.pad, 48)
	body.Size = UDim2.new(1, -tokens.size.pad * 2, 1, -60)
	body.ZIndex = 7
	body.Parent = window
	local opened = false
	local widget = { root = window, window = window, body = body, close = close }
	function widget.apply()
		local now = host.theme
		window.BackgroundColor3 = rgb(now.color.surface)
		border.Color = rgb(now.color.line)
		title.TextColor3 = rgb(now.color.ink)
	end
	function widget.setTitle(text)
		title.Text = text
	end
	function widget.isOpen()
		return opened
	end
	function widget.open()
		if opened then return end
		opened = true
		window.Visible = true
		host.play("modal-group", window, "open", { GroupTransparency = 0 })
		host.play("modal-scale", scale, "open", { Scale = 1 })
	end
	function widget.close()
		if not opened then return end
		opened = false
		host.cancel("modal-group")
		host.cancel("modal-scale")
		local duration = Motion.seconds("close", host.reduceMotion)
		if duration <= 0 then
			window.Visible = false
			window.GroupTransparency = 1
			scale.Scale = 0.98
			return
		end
		host.play("modal-group", window, "close", { GroupTransparency = 1 })
		host.play("modal-scale", scale, "close", { Scale = 0.98 })
		task.delay(duration, function()
			if window.Parent and not opened then window.Visible = false end
		end)
	end
	host.connect(close.root.MouseButton1Click, function() widget.close() end)
	host.watch(widget)
	return widget
end

return Kit
