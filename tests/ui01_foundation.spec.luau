--!strict
-- UI foundation rules. Roblox instances stay in the client kit; these tests cover the shared contract.
local Theme = require("../src/shared/ui/Theme")
local Motion = require("../src/shared/ui/Motion")
local Interact = require("../src/shared/ui/Interact")
local Layout = require("../src/shared/ui/Layout")
local Binding = require("../src/shared/ui/Binding")
local Host = require("../src/shared/ui/Host")
local Gate = require("../src/shared/ui/DemoGate")
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
		T.equal(desktop.inspector.h, 116)
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
end
