--!strict
-- Decorative geometry. Content padding never moves these layers.
local Decor = {}

export type Box = { x: number, y: number, w: number, h: number }

Decor.inset = 2
Decor.sheenHeight = 8

local function span(length: number, inset: number): (number, number)
	local limit = math.max(0, length) / 2
	local pad = math.clamp(inset, 0, limit)
	return pad, math.max(0, length - pad * 2)
end

function Decor.engraving(width: number, height: number): Box
	local x, w = span(width, Decor.inset)
	local y, h = span(height, Decor.inset)
	return { x = x, y = y, w = w, h = h }
end

function Decor.sheen(width: number, height: number): Box
	local plate = Decor.engraving(width, height)
	return { x = plate.x, y = plate.y, w = plate.w, h = math.min(Decor.sheenHeight, plate.h) }
end

function Decor.content(width: number, height: number, pad: number): Box
	local x, w = span(width, pad)
	local y, h = span(height, pad)
	return { x = x, y = y, w = w, h = h }
end

function Decor.strokeBounds(box: Box, thickness: number): Box
	local outset = math.max(0, thickness) / 2
	return {
		x = box.x - outset,
		y = box.y - outset,
		w = box.w + math.max(0, thickness),
		h = box.h + math.max(0, thickness),
	}
end

function Decor.contains(width: number, height: number, box: Box): boolean
	return box.x >= -0.01 and box.y >= -0.01
		and box.w >= -0.01 and box.h >= -0.01
		and box.x + box.w <= width + 0.01
		and box.y + box.h <= height + 0.01
end

function Decor.layers(role: string): { string }
	if role == "panel" or role == "modal" then
		return { "engraving", "sheen" }
	end
	return { "engraving" }
end

return Decor
