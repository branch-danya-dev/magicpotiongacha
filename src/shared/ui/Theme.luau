--!strict
-- Design tokens for the UI foundation. Gameplay code does not read this module.
-- Alchemy / Arcane Matte: one charcoal and ink-plum base. Themes differ by accent.
local Theme = {}

export type RGB = { number }
export type Tokens = {
	name: string,
	color: { [string]: RGB },
	transparency: { [string]: number },
	font: { [string]: string },
	size: { [string]: number },
	stroke: { [string]: number },
}
export type TextStyle = { font: string, color: RGB, text: number }
export type PaintMarks = { selected: boolean?, focused: boolean? }
export type Paint = {
	background: RGB,
	line: RGB,
	text: RGB,
	thickness: number,
	transparency: number,
}
export type Effect = { id: string, host: string, active: boolean }

local accents: { [string]: RGB } = {
	Default = { 176, 156, 122 },
	Soul = { 148, 132, 176 },
	Alchemy = { 134, 142, 150 },
	Familiar = { 168, 132, 112 },
	Reward = { 184, 164, 112 },
}

local names = { "Default", "Soul", "Alchemy", "Familiar", "Reward" }

-- Dormant sockets. Later VFX may activate these; nothing here animates.
local effects: { Effect } = {
	{ id = "liquid", host = "progress", active = false },
	{ id = "pulse", host = "modal", active = false },
	{ id = "smoke", host = "modal", active = false },
	{ id = "glyph", host = "counter", active = false },
	{ id = "halo", host = "button", active = false },
}

local function rgb(r: number, g: number, b: number): RGB
	return { r, g, b }
end

local function copy(color: RGB): RGB
	return { color[1], color[2], color[3] }
end

local function channel(value: number): number
	return math.clamp(math.floor(value + 0.5), 0, 255)
end

local function mix(a: RGB, b: RGB, amount: number): RGB
	return {
		channel(a[1] + (b[1] - a[1]) * amount),
		channel(a[2] + (b[2] - a[2]) * amount),
		channel(a[3] + (b[3] - a[3]) * amount),
	}
end

function Theme.names(): { string }
	local list = {}
	for _, name in ipairs(names) do
		table.insert(list, name)
	end
	return list
end

function Theme.effects(): { Effect }
	local list = {}
	for _, effect in ipairs(effects) do
		table.insert(list, { id = effect.id, host = effect.host, active = effect.active })
	end
	return list
end

function Theme.textStyle(tokens: Tokens, role: string): TextStyle
	if role == "heading" then
		return { font = tokens.font.title, color = copy(tokens.color.ink), text = tokens.size.title }
	elseif role == "caption" then
		return { font = tokens.font.body, color = copy(tokens.color.muted), text = tokens.size.caption }
	end
	return { font = tokens.font.body, color = copy(tokens.color.muted), text = tokens.size.small }
end

function Theme.resolve(name: string?): Tokens
	local themeName = "Default"
	if type(name) == "string" and accents[name] ~= nil then
		themeName = name
	end
	local accent = accents[themeName]
	return {
		name = themeName,
		color = {
			canvas = rgb(16, 14, 20),
			surface = rgb(34, 31, 40),
			raised = rgb(48, 44, 56),
			well = rgb(20, 18, 26),
			veil = rgb(86, 80, 98),
			ink = rgb(236, 228, 214),
			muted = rgb(176, 166, 156),
			line = rgb(98, 88, 112),
			engraving = rgb(132, 122, 146),
			shadow = rgb(6, 5, 10),
			accent = { accent[1], accent[2], accent[3] },
		},
		transparency = { panel = 0.08, scrim = 0.35, tooltip = 0.04, sheen = 0.9 },
		font = { body = "Gotham", title = "GothamMedium" },
		size = {
			text = 15, title = 18, caption = 12, small = 13,
			touch = 44, icon = 44, radius = 8, socket = 14,
			pad = 12, gap = 8, margin = 8, inset = 8, hudPad = 4,
			hud = 52, button = 148, choice = 80,
			chrome = 44, card = 108, cardMin = 96, counterMin = 88,
			prompt = 36, progress = 8, window = 340, scroll = 6,
		},
		stroke = { thickness = 1, focus = 1.5 },
	}
end

function Theme.paint(tokens: Tokens, role: string, state: string, marks: PaintMarks?): Paint
	local color = tokens.color
	local selected = marks ~= nil and marks.selected == true or state == "Selected"
	local focused = marks ~= nil and marks.focused == true or state == "Focused"
	local background = color.surface
	local line = color.engraving
	local text = color.ink
	local thickness = tokens.stroke.thickness
	local transparency = 0
	if role == "progressFill" then
		background = color.accent
		line = color.accent
	elseif role == "progressTrack" then
		background = color.well
		line = color.line
	elseif role == "tooltip" then
		background = color.raised
		transparency = tokens.transparency.tooltip
	elseif role == "card" then
		background = mix(color.surface, color.raised, 0.72)
		transparency = tokens.transparency.panel
	elseif role == "modal" or role == "panel" or role == "counter" then
		background = color.surface
		line = color.line
		transparency = tokens.transparency.panel
	elseif role == "button" or role == "icon" or role == "tab" then
		local resting = if role == "tab" then color.surface else color.raised
		background = resting
		text = if role == "tab" then color.muted else color.ink
		if state == "Disabled" then
			background = color.surface
			line = color.line
			text = color.muted
			selected = false
			focused = false
		elseif state == "Pressed" then
			background = mix(resting, color.well, 0.7)
			line = color.accent
			text = color.ink
		elseif selected then
			background = mix(color.raised, color.accent, 0.2)
			line = color.accent
			text = color.ink
		elseif state == "Hover" then
			background = mix(resting, color.veil, 0.5)
			line = color.accent
			text = color.ink
		end
		if focused then
			line = color.accent
			thickness = tokens.stroke.focus
			text = color.ink
		end
	end
	return {
		background = copy(background),
		line = copy(line),
		text = copy(text),
		thickness = thickness,
		transparency = transparency,
	}
end

return Theme
