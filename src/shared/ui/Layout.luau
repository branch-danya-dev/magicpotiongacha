--!strict
-- Screen placement for the foundation. Components do not invent their own margins.
local Theme = require("./Theme")
local Layout = {}

export type Rect = { x: number, y: number, w: number, h: number }
export type Insets = { top: number?, right: number?, bottom: number?, left: number? }
export type Block = { id: string, w: number, h: number, interactive: boolean? }
export type Placement = { id: string, x: number, y: number, w: number, h: number, interactive: boolean }
export type Column = { items: { Placement }, contentH: number, viewportH: number, scrolls: boolean }
export type Chrome = { title: Rect, close: Rect }
export type Screen = {
	safe: Rect,
	hud: Rect,
	window: Rect,
	inspector: Rect,
	hudItems: { Placement },
	chrome: Chrome,
	body: Column,
	inspectorColumn: Column,
}

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

function Layout.flow(width: number, blocks: { Block }, gap: number): ({ Placement }, number)
	local items: { Placement } = {}
	local x = 0
	local y = 0
	local rowH = 0
	local limit = math.max(0, width)
	local function pushRow()
		if rowH > 0 then
			y += rowH + gap
			x = 0
			rowH = 0
		end
	end
	for _, block in ipairs(blocks) do
		local w = math.min(block.w, limit)
		local h = block.h
		if block.interactive == true then
			w = math.max(w, math.min(44, limit))
			h = math.max(h, 44)
		end
		if x > 0 and x + w > limit + 0.01 then
			pushRow()
		end
		table.insert(items, {
			id = block.id,
			x = x,
			y = y,
			w = w,
			h = h,
			interactive = block.interactive == true,
		})
		x += w + gap
		rowH = math.max(rowH, h)
	end
	local contentH = if rowH > 0 then y + rowH else 0
	return items, contentH
end

function Layout.reachable(item: Rect, viewportH: number, contentH: number): boolean
	if item.h <= 0 or viewportH <= 0 then
		return false
	end
	if item.y + item.h <= viewportH + 0.01 then
		return true
	end
	if contentH <= viewportH + 0.01 then
		return false
	end
	local maxScroll = contentH - viewportH
	if item.h <= viewportH + 0.01 then
		return item.y + item.h - viewportH <= maxScroll + 0.01
	end
	return item.y <= maxScroll + 0.01
end

local function stack(width: number, sections: { { Block } }, gap: number): ({ Placement }, number)
	local items: { Placement } = {}
	local y = 0
	local started = false
	for _, blocks in ipairs(sections) do
		local placed, height = Layout.flow(width, blocks, gap)
		if height > 0 then
			if started then
				y += gap
			end
			for _, item in ipairs(placed) do
				item.y += y
				table.insert(items, item)
			end
			y += height
			started = true
		end
	end
	return items, y
end

local function offset(items: { Placement }, dx: number, dy: number)
	for _, item in ipairs(items) do
		item.x += dx
		item.y += dy
	end
end

local function column(items: { Placement }, contentH: number, viewportH: number): Column
	return {
		items = items,
		contentH = contentH,
		viewportH = viewportH,
		scrolls = contentH > viewportH + 0.5,
	}
end

function Layout.demo(viewportW: number, viewportH: number, inset: Insets?): Screen
	local size = Theme.resolve("Default").size
	local pad: Insets = if inset then inset else {}
	local top = math.max(0, pad.top or 0)
	local right = math.max(0, pad.right or 0)
	local bottomInset = math.max(0, pad.bottom or 0)
	local left = math.max(0, pad.left or 0)
	local safe: Rect = {
		x = left,
		y = top,
		w = math.max(0, viewportW - left - right),
		h = math.max(0, viewportH - top - bottomInset),
	}
	local margin = size.margin
	local gap = size.gap
	local insetPx = size.inset
	local touch = size.touch
	local chrome = size.chrome
	local hudW = math.min(460, math.max(0, safe.w - margin * 2))
	local hudInner = math.max(0, hudW - size.hudPad * 2)
	local hudBlocks: { Block } = {
		{ id = "gold", w = size.counterMin, h = touch, interactive = true },
		{ id = "essence", w = size.counterMin, h = touch, interactive = true },
		{ id = "nav-m", w = touch, h = touch, interactive = true },
		{ id = "nav-i", w = touch, h = touch, interactive = true },
		{ id = "nav-p", w = touch, h = touch, interactive = true },
	}
	local hudItems, hudContent = Layout.flow(hudInner, hudBlocks, gap)
	offset(hudItems, size.hudPad, size.hudPad)
	local hud: Rect = {
		x = safe.x + margin,
		y = safe.y + margin,
		w = hudW,
		h = hudContent + size.hudPad * 2,
	}
	local windowTop = hud.y + hud.h + gap
	local bottom = safe.y + safe.h - margin
	local room = math.max(0, bottom - windowTop)
	local windowW = math.min(440, math.max(0, safe.w - margin * 2))
	local inspectorW = math.max(0, safe.w - margin * 2)
	local bodyInner = math.max(0, windowW - size.pad * 2 - size.scroll)
	local tabW = math.max(touch, math.min(size.button, math.floor((bodyInner - gap * 2) / 3)))
	local cardShare = math.floor((bodyInner - gap * 2) / 3)
	local cardW = if cardShare >= size.cardMin then cardShare else math.min(size.cardMin, bodyInner)
	local actionW = math.min(size.button, bodyInner)
	local bodySections: { { Block } } = {
		{
			{ id = "tab-1", w = tabW, h = touch, interactive = true },
			{ id = "tab-2", w = tabW, h = touch, interactive = true },
			{ id = "tab-3", w = tabW, h = touch, interactive = true },
		},
		{
			{ id = "card-1", w = cardW, h = size.card, interactive = false },
			{ id = "card-2", w = cardW, h = size.card, interactive = false },
			{ id = "card-3", w = cardW, h = size.card, interactive = false },
		},
		{ { id = "progress", w = bodyInner, h = size.progress, interactive = false } },
		{
			{ id = "accept", w = actionW, h = touch, interactive = true },
			{ id = "locked", w = actionW, h = touch, interactive = true },
		},
		{ { id = "prompt", w = bodyInner, h = size.prompt, interactive = false } },
	}
	local bodyItems, bodyFlow = stack(bodyInner, bodySections, gap)
	offset(bodyItems, size.pad, size.pad)
	local bodyContent = bodyFlow + size.pad * 2
	local inspectorInner = math.max(0, inspectorW - insetPx * 2 - size.scroll)
	local choice = math.min(size.choice, inspectorInner)
	local inspectorBlocks: { Block } = {}
	for _, name in ipairs(Theme.names()) do
		table.insert(inspectorBlocks, { id = "theme-" .. name, w = choice, h = touch, interactive = true })
	end
	local inspectorNames = { "sample", "state-Default", "state-Hover", "state-Pressed", "state-Disabled", "state-Focused", "motion", "window" }
	for _, name in ipairs(inspectorNames) do
		table.insert(inspectorBlocks, { id = name, w = choice, h = touch, interactive = true })
	end
	local inspectorItems, inspectorFlow = Layout.flow(inspectorInner, inspectorBlocks, gap)
	offset(inspectorItems, insetPx, insetPx)
	local inspectorContent = inspectorFlow + insetPx * 2
	local inspectorFull = inspectorContent
	local minWindow = chrome + touch
	local minInspector = math.min(inspectorFull, insetPx * 2 + touch)
	local windowH: number
	local inspectorH: number
	if room >= inspectorFull + gap + size.window then
		inspectorH = inspectorFull
		windowH = size.window
	elseif room >= inspectorFull + gap + minWindow then
		inspectorH = inspectorFull
		windowH = math.min(size.window, room - gap - inspectorH)
	else
		windowH = math.min(size.window, math.max(math.min(minWindow, room), room - gap - minInspector))
		inspectorH = math.max(0, room - gap - windowH)
		if windowH < minWindow and inspectorH > minInspector and room >= minWindow then
			local give = math.min(minWindow - windowH, inspectorH - minInspector)
			windowH += give
			inspectorH -= give
		end
	end
	local inspector: Rect = {
		x = safe.x + margin,
		y = bottom - inspectorH,
		w = inspectorW,
		h = inspectorH,
	}
	local window: Rect = {
		x = safe.x + (safe.w - windowW) / 2,
		y = windowTop,
		w = windowW,
		h = math.max(0, math.min(windowH, inspector.y - gap - windowTop)),
	}
	local titleW = math.max(0, window.w - touch - size.pad - gap)
	local chromeBox: Chrome = {
		title = { x = size.pad, y = 0, w = titleW, h = chrome },
		close = { x = math.max(0, window.w - touch), y = 0, w = touch, h = chrome },
	}
	local bodyViewport = math.max(0, window.h - chrome)
	return {
		safe = safe,
		hud = hud,
		window = window,
		inspector = inspector,
		hudItems = hudItems,
		chrome = chromeBox,
		body = column(bodyItems, bodyContent, bodyViewport),
		inspectorColumn = column(inspectorItems, inspectorContent, inspector.h),
	}
end

return Layout
