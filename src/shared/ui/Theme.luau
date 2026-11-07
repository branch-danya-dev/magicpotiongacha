--!strict
-- Design tokens for the UI foundation. Gameplay code does not read this module.
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

local accents: { [string]: RGB } = {
	Default = { 176, 156, 122 },
	Soul = { 148, 132, 176 },
	Alchemy = { 122, 148, 138 },
	Familiar = { 168, 132, 112 },
	Reward = { 184, 164, 112 },
}

local names = { "Default", "Soul", "Alchemy", "Familiar", "Reward" }

local function rgb(r: number, g: number, b: number): RGB
	return { r, g, b }
end

function Theme.names(): { string }
	local copy = {}
	for _, name in ipairs(names) do
		table.insert(copy, name)
	end
	return copy
end

export type TextStyle = { font: string, color: RGB, text: number }

function Theme.textStyle(tokens: Tokens, role: string): TextStyle
	if role == "heading" then
		return { font = tokens.font.title, color = tokens.color.ink, text = tokens.size.title }
	elseif role == "caption" then
		return { font = tokens.font.body, color = tokens.color.muted, text = tokens.size.caption }
	end
	return { font = tokens.font.body, color = tokens.color.muted, text = tokens.size.small }
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
			canvas = rgb(24, 23, 28),
			surface = rgb(38, 36, 44),
			raised = rgb(50, 47, 56),
			ink = rgb(226, 221, 212),
			muted = rgb(154, 148, 140),
			line = rgb(86, 80, 92),
			accent = { accent[1], accent[2], accent[3] },
		},
		transparency = { panel = 0.08, scrim = 0.35, tooltip = 0.04 },
		font = { body = "Gotham", title = "GothamMedium" },
		size = {
			text = 15, title = 18, caption = 12, small = 13,
			touch = 44, icon = 44, radius = 8,
			pad = 12, gap = 8, margin = 8, inset = 8, hudPad = 4,
			hud = 52, button = 148, choice = 80,
			chrome = 44, card = 108, cardMin = 96, counterMin = 88,
			prompt = 36, progress = 8, window = 340, scroll = 6,
		},
		stroke = { thickness = 1 },
	}
end

return Theme
