--!strict
-- Screen placement for the foundation. Components do not invent their own margins.
local Layout = {}

export type Rect = { x: number, y: number, w: number, h: number }
export type Insets = { top: number?, right: number?, bottom: number?, left: number? }
export type Screen = { safe: Rect, hud: Rect, window: Rect, inspector: Rect }

function Layout.touch(size: number): number
	return math.max(size, 44)
end

function Layout.overlaps(a: Rect, b: Rect): boolean
	return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h
end

function Layout.inside(outer: Rect, inner: Rect): boolean
	return inner.x >= outer.x - 0.01 and inner.y >= outer.y - 0.01
		and inner.x + inner.w <= outer.x + outer.w + 0.01
		and inner.y + inner.h <= outer.y + outer.h + 0.01
end

function Layout.demo(viewportW: number, viewportH: number, inset: Insets?): Screen
	local pad: Insets = if inset then inset else {}
	local top = math.max(0, pad.top or 0)
	local right = math.max(0, pad.right or 0)
	local bottomInset = math.max(0, pad.bottom or 0)
	local left = math.max(0, pad.left or 0)
	local safe: Rect = {
		x = left, y = top,
		w = math.max(120, viewportW - left - right),
		h = math.max(160, viewportH - top - bottomInset),
	}
	local margin = 12
	local gap = 12
	local hud: Rect = {
		x = safe.x + margin, y = safe.y + 8,
		w = math.min(460, safe.w - margin * 2), h = 52,
	}
	local windowTop = hud.y + hud.h + gap
	local bottom = safe.y + safe.h - margin
	local room = math.max(0, bottom - windowTop)
	local desiredInspector = safe.w < 760 and 220 or 116
	local inspectorH = desiredInspector
	if desiredInspector + 48 + gap > room then
		inspectorH = math.min(desiredInspector, math.floor(room * 0.62))
	end
	local inspector: Rect = {
		x = safe.x + margin,
		y = bottom - inspectorH,
		w = safe.w - margin * 2,
		h = inspectorH,
	}
	local windowW = math.min(440, safe.w - margin * 2)
	local window: Rect = {
		x = safe.x + (safe.w - windowW) / 2,
		y = windowTop,
		w = windowW,
		h = math.min(340, math.max(0, inspector.y - gap - windowTop)),
	}
	return { safe = safe, hud = hud, window = window, inspector = inspector }
end

return Layout
