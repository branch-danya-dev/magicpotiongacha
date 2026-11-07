--!strict
-- UI foundation rules. Roblox instances stay in the client kit; these tests cover the shared contract.
local Theme = require("../src/shared/ui/Theme")
local Motion = require("../src/shared/ui/Motion")
local Interact = require("../src/shared/ui/Interact")
local Layout = require("../src/shared/ui/Layout")
local Binding = require("../src/shared/ui/Binding")
local Host = require("../src/shared/ui/Host")
local Gate = require("../src/shared/ui/DemoGate")
local Windows = require("../src/shared/ui/Windows")
local Test = require("./Test")

local function separated(a: Layout.Rect, b: Layout.Rect): boolean
	return not Layout.overlaps(a, b)
end

return function(T: typeof(Test))
	T.test("UI-01: five themes share layout tokens and keep their own accent", function()
		local names = Theme.names()
		T.equal(#names, 5)
		T.equal(names[1], "Default")
		T.equal(names[2], "Soul")
		T.equal(names[3], "Alchemy")
		T.equal(names[4], "Familiar")
		T.equal(names[5], "Reward")
		local first = Theme.resolve("Default")
		T.equal(first.size.touch, 44)
		T.truthy(first.size.icon >= 44)
		T.equal(first.font.body, "Gotham")
		T.equal(first.font.title, "GothamMedium")
		local seen: { [number]: boolean } = {}
		for _, name in ipairs(names) do
			local tokens = Theme.resolve(name)
			T.equal(tokens.name, name)
			T.equal(tokens.size.touch, first.size.touch)
			T.equal(tokens.size.button, first.size.button)
			T.equal(tokens.size.radius, first.size.radius)
			T.equal(tokens.stroke.thickness, first.stroke.thickness)
			T.equal(tokens.transparency.panel, first.transparency.panel)
			local accent = tokens.color.accent[1] * 1000000 + tokens.color.accent[2] * 1000 + tokens.color.accent[3]
			T.falsy(seen[accent], name)
			seen[accent] = true
		end
		local soul = Theme.resolve("Soul")
		local again = Theme.resolve("Soul")
		soul.color.accent[1] = 0
		soul.size.touch = 1
		T.equal(again.color.accent[1], 148)
		T.equal(again.size.touch, 44)
		T.equal(Theme.resolve("Garden").name, "Default")
		T.equal(Theme.resolve(nil).name, "Default")
	end)

	T.test("UI-01: interaction states resolve in one order", function()
		T.equal(Interact.resolve({}), "Default")
		T.equal(Interact.resolve({ hover = true }), "Hover")
		T.equal(Interact.resolve({ focused = true, hover = true }), "Focused")
		T.equal(Interact.resolve({ pressed = true, focused = true, hover = true }), "Pressed")
		T.equal(Interact.resolve({ disabled = true, pressed = true, focused = true, hover = true }), "Disabled")
		T.equal(Interact.visual("Pressed", false).scale, 0.97)
		T.equal(Interact.visual("Pressed", true).scale, 1)
		T.equal(Interact.visual("Hover", false).scale, 1)
		T.equal(Interact.visual("Disabled", false).textTransparency, 0.4)
		T.equal(Interact.visual("Default", false).textTransparency, 0)
	end)

	T.test("UI-01: motion durations cancel the previous generation", function()
		T.equal(Motion.seconds("hover", false), 0.15)
		T.equal(Motion.seconds("press", false), 0.10)
		T.equal(Motion.seconds("open", false), 0.22)
		T.equal(Motion.seconds("close", false), 0.15)
		T.equal(Motion.seconds("open", true), 0)
		T.equal(Motion.seconds("hover", true), 0)
		local track = Motion.track()
		local first = Motion.begin(track, "open", false)
		T.equal(track.duration, 0.22)
		local second = Motion.begin(track, "close", true)
		T.falsy(Motion.current(track, first))
		T.truthy(Motion.current(track, second))
		T.equal(track.kind, "close")
		T.equal(track.duration, 0)
	end)

	T.test("UI-01: demo regions stay inside the safe area on desktop, phone, and a short screen", function()
		local screens = {
			Layout.demo(1280, 720),
			Layout.demo(390, 844, { top = 47, right = 0, bottom = 34, left = 0 }),
			Layout.demo(800, 240),
		}
		for _, screen in ipairs(screens) do
			T.truthy(Layout.inside(screen.safe, screen.hud))
			T.truthy(Layout.inside(screen.safe, screen.window))
			T.truthy(Layout.inside(screen.safe, screen.inspector))
			T.truthy(separated(screen.hud, screen.window))
			T.truthy(separated(screen.hud, screen.inspector))
			T.truthy(separated(screen.window, screen.inspector))
			T.truthy(screen.hud.w > 0 and screen.hud.h > 0)
			T.truthy(screen.window.w > 0 and screen.window.h > 0)
			T.truthy(screen.inspector.w > 0 and screen.inspector.h > 0)
		end
		T.equal(Layout.touch(12), 44)
		T.equal(Layout.touch(48), 48)
		local desktop = screens[1]
		T.equal(desktop.window.h, 340)
		T.falsy(desktop.body.scrolls)
		T.falsy(desktop.inspectorColumn.scrolls)
	end)

	T.test("UI-01: binding formats resources without mutating the snapshot", function()
		local snapshot = { gold = 1000, essence = 40, extra = "keep" }
		local shown = Binding.resources(snapshot)
		T.equal(snapshot.gold, 1000)
		T.equal(snapshot.essence, 40)
		T.equal(snapshot.extra, "keep")
		T.equal(shown.gold, 1000)
		T.equal(shown.essence, 40)
		T.equal(shown.goldText, "1K")
		T.equal(shown.essenceText, "40")
		local invalid = Binding.resources({ gold = 0 / 0, essence = math.huge })
		T.equal(invalid.gold, 0)
		T.equal(invalid.essence, 0)
		T.equal(Binding.text(-1500), "-1.5K")
		local demo = Binding.demo()
		T.equal(#demo.cards, 3)
		for _, card in ipairs(demo.cards) do
			T.equal((card :: any).action, nil)
			T.truthy(string.len(card.title) > 0)
			T.truthy(string.len(card.body) > 0)
		end
		T.equal(demo.progress, 0.62)
	end)

	T.test("UI-01: the preview opens only in Studio with the developer flag", function()
		T.falsy(Gate.allowed(false, false))
		T.falsy(Gate.allowed(false, true))
		T.falsy(Gate.allowed(true, false))
		T.truthy(Gate.allowed(true, true))
		T.truthy(Gate.preview(true, nil))
		T.truthy(Gate.preview(true, true))
		T.falsy(Gate.preview(true, false))
		T.falsy(Gate.preview(false, nil))
		T.falsy(Gate.preview(false, true))
	end)

	T.test("UI-01: a surface mounts once and releases every listener", function()
		local surface = Host.new()
		local calls = 0
		T.falsy(surface.track(function() calls += 1 end))
		T.equal(surface.mount(), true)
		T.equal(surface.mount(), false)
		T.truthy(surface.track(function() calls += 1 end))
		T.truthy(surface.track(function() calls += 1 end))
		T.equal(surface.listeners(), 2)
		T.equal(surface.unmount(), true)
		T.equal(calls, 2)
		T.equal(surface.listeners(), 0)
		T.equal(surface.mounted(), false)
		T.equal(surface.unmount(), false)
		T.equal(calls, 2)
		T.equal(surface.mount(), true)
		T.equal(surface.listeners(), 0)
		T.equal(surface.unmount(), true)
	end)

	local function find(items: { Layout.Placement }, id: string): Layout.Placement
		for _, item in ipairs(items) do
			if item.id == id then
				return item
			end
		end
		error("Missing layout item " .. id, 2)
	end

	local function clashes(items: { Layout.Placement })
		for left = 1, #items do
			for right = left + 1, #items do
				T.falsy(Layout.overlaps(items[left], items[right]), items[left].id .. " overlaps " .. items[right].id)
			end
		end
	end

	T.test("UI-01B: every demo control stays reachable on the review viewports", function()
		local screens = {
			{ name = "320x568", screen = Layout.demo(320, 568), scrolls = true, wrapped = true },
			{ name = "390x844", screen = Layout.demo(390, 844, { top = 47, bottom = 34 }), scrolls = false, wrapped = false },
			{ name = "800x240", screen = Layout.demo(800, 240), scrolls = true, wrapped = false },
			{ name = "1280x720", screen = Layout.demo(1280, 720), scrolls = false, wrapped = false },
			{ name = "1920x1080", screen = Layout.demo(1920, 1080), scrolls = false, wrapped = false },
		}
		for _, entry in ipairs(screens) do
			local screen = entry.screen
			T.truthy(Layout.inside(screen.safe, screen.hud), entry.name)
			T.truthy(Layout.inside(screen.safe, screen.window), entry.name)
			T.truthy(Layout.inside(screen.safe, screen.inspector), entry.name)
			T.truthy(separated(screen.hud, screen.window), entry.name)
			T.truthy(separated(screen.hud, screen.inspector), entry.name)
			T.truthy(separated(screen.window, screen.inspector), entry.name)
			T.truthy(screen.window.h >= 44, entry.name)
			T.falsy(Layout.overlaps(screen.chrome.title, screen.chrome.close), entry.name)
			T.truthy(Layout.inside(screen.window, {
				x = screen.window.x + screen.chrome.close.x,
				y = screen.window.y + screen.chrome.close.y,
				w = screen.chrome.close.w,
				h = screen.chrome.close.h,
			}), entry.name)
			T.equal(screen.chrome.close.w, 44, entry.name)
			T.equal(screen.chrome.close.h, 44, entry.name)
			clashes(screen.hudItems)
			clashes(screen.body.items)
			clashes(screen.inspectorColumn.items)
			for _, item in ipairs(screen.hudItems) do
				T.truthy(item.w >= 44 and item.h >= 44, item.id)
				T.truthy(Layout.inside(screen.hud, {
					x = screen.hud.x + item.x, y = screen.hud.y + item.y, w = item.w, h = item.h,
				}), item.id)
			end
			for _, item in ipairs(screen.body.items) do
				T.truthy(Layout.reachable(item, screen.body.viewportH, screen.body.contentH), entry.name .. " " .. item.id)
				if item.interactive then
					T.truthy(item.w >= 44 and item.h >= 44, item.id)
				end
			end
			for _, item in ipairs(screen.inspectorColumn.items) do
				T.truthy(Layout.reachable(item, screen.inspectorColumn.viewportH, screen.inspectorColumn.contentH), entry.name .. " " .. item.id)
				T.truthy(item.w >= 44 and item.h >= 44, item.id)
			end
			T.equal(screen.body.scrolls, entry.scrolls, entry.name)
			local firstCard = find(screen.body.items, "card-1")
			local lastCard = find(screen.body.items, "card-3")
			local accept = find(screen.body.items, "accept")
			local locked = find(screen.body.items, "locked")
			T.truthy(Layout.reachable(accept, screen.body.viewportH, screen.body.contentH), entry.name)
			T.truthy(Layout.reachable(locked, screen.body.viewportH, screen.body.contentH), entry.name)
			if entry.wrapped then
				T.truthy(lastCard.y > firstCard.y, entry.name)
			else
				T.equal(firstCard.y, lastCard.y, entry.name)
			end
		end
		local narrow = screens[1].screen
		local wide = screens[4].screen
		T.truthy(find(narrow.hudItems, "nav-p").y > find(narrow.hudItems, "nav-m").y)
		T.equal(find(wide.hudItems, "nav-p").y, find(wide.hudItems, "nav-m").y)
		T.equal(wide.hud.h, 52)
		T.truthy(narrow.hud.h > 52)
		T.truthy(screens[3].screen.inspectorColumn.scrolls)
		T.falsy(wide.inspectorColumn.scrolls)
		T.equal(screens[5].screen.window.h, 340)
	end)

	T.test("UI-01B: one window owns the stage and a stale close cannot hide it", function()
		local windows = Windows.new()
		local first = windows.open("demo", "gold")
		T.equal(windows.count(), 1)
		T.equal(windows.listeners(), 1)
		local closing = windows.close("demo")
		T.equal(closing.focus, "gold")
		T.truthy(windows.shouldHide("demo", closing.generation))
		T.equal(windows.listeners(), 0)
		local second = windows.open("demo", "gold")
		T.falsy(windows.shouldHide("demo", closing.generation))
		T.truthy(windows.isOpen("demo"))
		T.equal(windows.count(), 1)
		T.equal(windows.listeners(), 1)
		T.truthy(first.generation ~= second.generation)
		T.equal(first.keys.group, "demo:group")
		local _, displaced = windows.open("other", "shop")
		T.truthy(displaced ~= nil)
		if displaced then
			T.truthy(windows.shouldHide("demo", displaced.generation))
			T.truthy(displaced.keys.group ~= windows.keys("other").group)
		end
		T.falsy(windows.isOpen("demo"))
		T.truthy(windows.isOpen("other"))
		T.equal(windows.count(), 1)
		T.equal(windows.listeners(), 1)
		windows.close("other")
		T.equal(windows.listeners(), 0)
		windows.open("other", "shop")
		T.equal(windows.listeners(), 1)
		T.truthy(Windows.dismiss("Escape"))
		T.truthy(Windows.dismiss("ButtonB"))
		T.falsy(Windows.dismiss("M"))
		T.falsy(Windows.dismiss("I"))
		T.falsy(Windows.dismiss("P"))
		T.falsy(Windows.dismiss("DPadLeft"))
		T.falsy(Windows.dismiss("DPadDown"))
		T.falsy(Windows.dismiss("DPadRight"))
	end)

	T.test("UI-01B: selected tabs stay distinct from gamepad focus", function()
		local both = Interact.marks({ selected = true, focused = true })
		T.truthy(both.selected)
		T.truthy(both.focused)
		T.truthy(both.selectable)
		T.equal(Interact.resolve({ selected = true }), "Selected")
		T.equal(Interact.resolve({ selected = true, focused = true }), "Focused")
		local blocked = Interact.marks({ selected = true, focused = true, disabled = true })
		T.falsy(blocked.selected)
		T.falsy(blocked.focused)
		T.falsy(blocked.selectable)
		T.falsy(Interact.selectable({ disabled = true }))
		T.equal(Interact.handoff({
			{ id = "a", disabled = false },
			{ id = "b", disabled = true },
			{ id = "c", disabled = false },
		}, "b"), "c")
		T.equal(Interact.handoff({
			{ id = "a", disabled = false },
			{ id = "b", disabled = true },
		}, "b"), "a")
		T.equal(Interact.handoff({ { id = "locked", disabled = true } }, "locked"), nil)
	end)

	T.test("UI-01B: text styles follow tokens across themes", function()
		for _, name in ipairs(Theme.names()) do
			local tokens = Theme.resolve(name)
			local heading = Theme.textStyle(tokens, "heading")
			local body = Theme.textStyle(tokens, "body")
			T.equal(heading.font, tokens.font.title)
			T.equal(heading.color[1], tokens.color.ink[1])
			T.equal(body.font, tokens.font.body)
			T.equal(body.color[1], tokens.color.muted[1])
			T.equal(body.text, tokens.size.small)
			T.equal(tokens.size.chrome, 44)
			T.equal(tokens.size.touch, 44)
		end
		T.equal(Motion.seconds("close", true), 0)
		T.equal(Motion.seconds("open", true), 0)
		local soul = Theme.resolve("Soul")
		local plain = Theme.resolve("Default")
		T.truthy(soul.color.accent[1] ~= plain.color.accent[1])
		T.equal(Theme.textStyle(soul, "heading").color[1], Theme.textStyle(plain, "heading").color[1])
	end)

	-- GuiService.SelectedObject itself is a Roblox Studio check. These cases decide the target.
	T.test("UI-01C: focus returns only to a control that is still available", function()
		local gold = { id = "gold" }
		local order = { gold, { id = "shop" } }
		T.equal(Interact.restore(nil, order, nil), nil)
		T.equal(Interact.restore({ id = "gone", present = false }, order, nil), "gold")
		T.equal(Interact.restore({ id = "removed", mounted = false }, order, nil), "gold")
		T.equal(Interact.restore({ id = "hidden", visible = false }, order, nil), "gold")
		T.equal(Interact.restore({ id = "child", ancestorsVisible = false }, order, nil), "gold")
		T.equal(Interact.restore({ id = "locked", disabled = true }, order, nil), "gold")
		T.equal(Interact.restore({ id = "a-close", window = "a" }, {
			{ id = "a-close", window = "a" },
			gold,
		}, nil), "gold")
		T.equal(Interact.restore({ id = "gone", present = false }, { { id = "locked", disabled = true } }, nil), nil)
		T.falsy(Interact.available({ id = "x", selectable = false }))
		T.truthy(Interact.available({ id = "close", window = "note" }, "note"))
		T.equal(Interact.handoff({
			{ id = "hidden", visible = false },
			{ id = "locked", disabled = true },
			{ id = "ok" },
		}, "hidden"), "ok")
		T.equal(Interact.firstInside({
			{ id = "close", window = "demo", prefer = false },
			{ id = "tab", window = "demo" },
			{ id = "locked", window = "demo", disabled = true },
			gold,
		}, "demo"), "tab")
		T.equal(Interact.inputKind("Gamepad1"), "Gamepad")
		T.equal(Interact.inputKind("Touch"), "Touch")
		T.equal(Interact.inputKind("MouseButton1"), "Mouse")
		T.truthy(Interact.claimsFocus("Gamepad"))
		T.falsy(Interact.claimsFocus("Mouse"))
		T.falsy(Interact.claimsFocus("Touch"))
	end)

	T.test("UI-01C: switching windows does not keep the hidden window as the restore target", function()
		local windows = Windows.new()
		windows.open("a", "gold")
		local _, displaced = windows.open("b", "a-close", "a")
		T.truthy(displaced ~= nil)
		if displaced then
			T.equal(displaced.focus, "gold")
		end
		T.equal(windows.current(), "b")
		T.equal(windows.count(), 1)
		T.equal(windows.listeners(), 1)
		T.falsy(windows.isOpen("a"))
		local back = windows.open("a", "b-close", "b")
		T.equal(back.focus, "gold")
		T.equal(windows.listeners(), 1)
		T.equal(windows.count(), 1)
		local closed = windows.close("a")
		T.equal(closed.focus, "gold")
		T.equal(windows.count(), 0)
		T.equal(windows.listeners(), 0)
		T.falsy(windows.shouldHide("a", back.generation))
		local again = windows.open("a", "a-button", "a")
		T.equal(again.focus, "gold")
		T.equal(windows.close("a").focus, "gold")
		T.equal(windows.listeners(), 0)
		local bare = windows.open("a", nil)
		T.equal(bare.focus, nil)
		T.equal(windows.close("a").focus, nil)
		T.equal(windows.listeners(), 0)
	end)

	local function channels(color: { number }): number
		return color[1] + color[2] + color[3]
	end

	T.test("UI-02A: themes share the matte base and differ by accent", function()
		local plain = Theme.resolve("Default")
		T.equal(plain.color.canvas[1], 16)
		T.equal(plain.color.ink[1], 236)
		T.equal(plain.stroke.focus, 1.5)
		T.equal(plain.transparency.sheen, 0.9)
		local alchemy = Theme.resolve("Alchemy")
		T.truthy(alchemy.color.accent[2] <= alchemy.color.accent[3])
		for _, name in ipairs(Theme.names()) do
			local tokens = Theme.resolve(name)
			T.equal(tokens.color.canvas[1], plain.color.canvas[1])
			T.equal(tokens.color.surface[1], plain.color.surface[1])
			T.equal(tokens.color.ink[1], plain.color.ink[1])
			T.equal(tokens.color.line[1], plain.color.line[1])
			T.equal(tokens.color.engraving[1], plain.color.engraving[1])
			T.equal(tokens.stroke.focus, plain.stroke.focus)
		end
		local dormant = 0
		local seen: { [string]: boolean } = {}
		for _, effect in ipairs(Theme.effects()) do
			T.falsy(effect.active, effect.id)
			T.falsy(seen[effect.id], effect.id)
			seen[effect.id] = true
			dormant += 1
		end
		T.equal(dormant, 5)
		T.truthy(seen.liquid)
		T.truthy(seen.pulse)
		T.truthy(seen.smoke)
		T.truthy(seen.glyph)
		T.truthy(seen.halo)
	end)

	T.test("UI-02A: component states stay distinct and readable", function()
		local tokens = Theme.resolve("Default")
		local idle = Theme.paint(tokens, "button", "Default")
		local hover = Theme.paint(tokens, "button", "Hover")
		local pressed = Theme.paint(tokens, "button", "Pressed")
		local focused = Theme.paint(tokens, "button", "Focused")
		local selected = Theme.paint(tokens, "button", "Selected")
		local disabled = Theme.paint(tokens, "button", "Disabled")
		T.truthy(channels(hover.background) > channels(idle.background))
		T.truthy(channels(pressed.background) < channels(idle.background))
		T.truthy(channels(selected.background) ~= channels(hover.background))
		T.equal(hover.line[1], tokens.color.accent[1])
		T.equal(selected.line[1], tokens.color.accent[1])
		T.truthy(focused.thickness > idle.thickness)
		T.equal(disabled.text[1], tokens.color.muted[1])
		T.truthy(channels(disabled.text) > channels(tokens.color.surface))
		local tab = Theme.paint(tokens, "tab", "Default")
		local tabOn = Theme.paint(tokens, "tab", "Selected")
		T.truthy(channels(tabOn.background) ~= channels(tab.background))
		T.equal(tab.text[1], tokens.color.muted[1])
		T.equal(tabOn.text[1], tokens.color.ink[1])
		local held = Theme.paint(tokens, "tab", "Focused", { selected = true, focused = true })
		T.equal(held.thickness, tokens.stroke.focus)
		T.equal(held.background[1], tabOn.background[1])
		local track = Theme.paint(tokens, "progressTrack", "Default")
		local fill = Theme.paint(tokens, "progressFill", "Default")
		T.equal(track.background[1], tokens.color.well[1])
		T.equal(fill.background[1], tokens.color.accent[1])
		local card = Theme.paint(tokens, "card", "Default")
		local panel = Theme.paint(tokens, "panel", "Default")
		T.truthy(channels(card.background) ~= channels(panel.background))
		T.equal(panel.transparency, tokens.transparency.panel)
		local soul = Theme.resolve("Soul")
		local soulSelected = Theme.paint(soul, "button", "Selected")
		T.truthy(soulSelected.background[1] ~= selected.background[1])
		T.equal(Theme.paint(soul, "button", "Default").background[1], idle.background[1])
	end)

	T.test("UI-02A: the review sizes still keep every control reachable", function()
		local screens = {
			{ name = "1920x1080", screen = Layout.demo(1920, 1080), scrolls = false },
			{ name = "1366x768", screen = Layout.demo(1366, 768), scrolls = false },
			{ name = "390x844", screen = Layout.demo(390, 844), scrolls = false },
			{ name = "360x640", screen = Layout.demo(360, 640), scrolls = true },
		}
		for _, entry in ipairs(screens) do
			local screen = entry.screen
			T.truthy(Layout.inside(screen.safe, screen.hud), entry.name)
			T.truthy(Layout.inside(screen.safe, screen.window), entry.name)
			T.truthy(Layout.inside(screen.safe, screen.inspector), entry.name)
			T.truthy(separated(screen.hud, screen.window), entry.name)
			T.truthy(separated(screen.window, screen.inspector), entry.name)
			T.falsy(Layout.overlaps(screen.chrome.title, screen.chrome.close), entry.name)
			T.equal(screen.chrome.close.w, 44, entry.name)
			T.equal(screen.body.scrolls, entry.scrolls, entry.name)
			for _, item in ipairs(screen.body.items) do
				T.truthy(Layout.reachable(item, screen.body.viewportH, screen.body.contentH), entry.name .. " " .. item.id)
			end
			for _, item in ipairs(screen.hudItems) do
				T.truthy(item.w >= 44 and item.h >= 44, item.id)
			end
		end
		T.equal(screens[1].screen.window.h, 340)
		T.equal(screens[2].screen.window.h, 340)
		T.truthy(find(screens[4].screen.hudItems, "nav-p").y > find(screens[4].screen.hudItems, "nav-m").y)
	end)
end
