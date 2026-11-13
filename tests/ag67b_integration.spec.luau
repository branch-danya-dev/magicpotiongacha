--!nonstrict
return function(T: any)
	local P = require("../src/shared/SpellbookSoulPolicy")
	local Gate = require("../src/shared/SpellbookSoulGate")
	local Feedback = require("../src/shared/SpellbookFeedback")
	T.test("AG67B ordinary Studio is automatic but release cannot be opted in by an attribute", function()
		T.truthy(P.enabled(true, nil)); T.truthy(P.enabled(true, true)); T.falsy(P.enabled(true, false))
		T.falsy(P.enabled(false, nil)); T.falsy(P.enabled(false, true)); T.falsy(P.releaseEnabled)
	end)
	T.test("AG67B Full and Reduced preserve sheet counts and bound sparks", function()
		local full, reduced = P.quality("full", false), P.quality("reduced", false)
		T.equal(full.pages, 22); T.equal(reduced.pages, 12)
		T.truthy(full.sparks >= 25 and full.sparks <= 40); T.truthy(reduced.sparks >= 12 and reduced.sparks <= 20)
		T.equal(full.streams, 3); T.equal(reduced.streams, 2)
	end)
	T.test("AG67B Minimal retains legible static runes and pulse without flight", function()
		local c = P.quality("minimal", false)
		T.equal(c.pages, 0); T.equal(c.streams, 0); T.equal(c.sparks, 0)
		T.equal(c.runes, 2); T.falsy(c.motion); T.falsy(c.light); T.falsy(c.ambient)
	end)
	T.test("AG67B Reduce Motion removes every intensive moving layer", function()
		for _, quality in ipairs({"full", "reduced", "minimal"}) do
			local c = P.quality(quality, true)
			T.equal(c.pages, 0); T.equal(c.streams, 0); T.equal(c.sparks, 0); T.falsy(c.ambient); T.falsy(c.motion)
			T.truthy(P.flash(.3, 0, c.calm) > 0)
		end
	end)
	T.test("AG67B invalid quality fails to the Reduced budget", function()
		T.same(P.quality("unknown", false), P.quality("reduced", false))
	end)
	T.test("AG67B sector emission totals cannot exceed one burst under skipped frames", function()
		for _, quality in ipairs({"full", "reduced", "minimal"}) do
			local c = P.quality(quality, false)
			for _, step in ipairs({1 / 60, 1 / 30, .21, 1}) do
				local previous, total = 0, 0
				for tick = 0, math.ceil(2.4 / step) do
					local due = P.sectorsDue(tick * step)
					for sector = previous + 1, due do total += P.sectorCount(c.sparks, sector) end
					previous = due
				end
				T.equal(total, c.sparks)
			end
		end
	end)
	T.test("AG67B confirmed spam never extends the active batch", function()
		local r = P.new(); T.truthy(r.trigger(10))
		for i = 1, 1000 do T.falsy(r.trigger(10 + i / 1000)) end
		T.equal(r.started, 10); T.equal(r.batches, 1); T.equal(r.confirmed, 1001)
		T.truthy(r.trigger(12.5)); T.equal(r.batches, 2)
	end)
	T.test("AG67B cancel removes pending pulse and allows a fresh bounded batch", function()
		local r = P.new(); r.trigger(1); r.cancel(); T.equal(r.started, nil); T.equal(r.lastPulse, nil)
		T.truthy(r.trigger(1.1)); T.equal(r.batches, 2)
	end)
	T.test("AG67B replay wrong plot rejected and malformed receipts cannot trigger", function()
		local cursor = Feedback.consume(nil, {sequence = 10, plotIndex = 1}, 1)
		for _, receipt in ipairs({{sequence = 10, plotIndex = 1}, {sequence = 9, plotIndex = 1}, {sequence = 11, plotIndex = 2}, {sequence = 0 / 0}, {sequence = 12.5}, {}}) do
			local accepted; cursor, accepted = Feedback.consume(cursor, receipt, 1); T.falsy(accepted)
		end
		local nextCursor, accepted = Feedback.consume(cursor, {sequence = 12, plotIndex = 1}, 1)
		T.truthy(accepted); T.equal(nextCursor, 12)
	end)
	T.test("AG67B unsuccessful server click does not advance its receipt", function()
		T.equal(Feedback.accept(7, "click", false), 7)
		T.equal(Feedback.accept(7, "buy", true), 7)
		T.equal(Feedback.accept(7, "click", true), 8)
	end)
	T.test("AG67B content failure is terminal despite a late success", function()
		local gate = Gate.new(); T.truthy(gate.finish(false)); T.falsy(gate.finish(true)); T.equal(gate.status, "failed")
	end)
	T.test("AG67B successful preload cannot be reversed by its timeout", function()
		local gate = Gate.new(); T.truthy(gate.finish(true)); T.falsy(gate.finish(false)); T.equal(gate.status, "ready")
	end)
	T.test("AG67B stopping during preload prevents owner resurrection", function()
		local gate = Gate.new(); gate.stop(); T.falsy(gate.finish(true)); T.equal(gate.status, "pending")
	end)
	T.test("AG67B glyphs have independent orbits and screen-plane rotation", function()
		local a, b = P.rune(8, 1, true, 0), P.rune(8, 2, true, 0)
		T.truthy(math.abs(a.x - b.x) > .1); T.truthy(a.rotation ~= b.rotation)
		T.same(a, P.rune(8, 1, true, 0))
	end)
	T.test("AG67B calm glyphs do not orbit spin or hover", function()
		local a, b = P.rune(1, 2, false, 0), P.rune(100, 2, false, 10)
		T.equal(a.x, b.x); T.equal(a.y, b.y); T.equal(a.z, b.z); T.equal(a.rotation, b.rotation)
	end)
	T.test("AG67B atlas rects never cross frame or texture boundaries", function()
		for frame = 0, 7 do for side = 0, 1 do for _, edge in ipairs({false, true}) do
			local x, y = P.pageRect(frame, side, edge)
			T.truthy(x >= 0 and x + 128 <= 1024 and y >= 0 and y + 256 <= 1024)
			T.equal(x % 128, 0); T.equal(y % 256, 0)
		end end end
	end)
	T.test("AG67B burn progression is monotonic and reaches the broken silhouette", function()
		local last = 0
		for frame = 0, 120 do
			local current = P.burnFrame(P.page(frame / 50, 1).burn)
			T.truthy(current >= last); last = current
		end
		T.equal(last, 7)
	end)
	T.test("AG67B pages disappear by pool expiry and stay finite", function()
		for i = 1, 22 do
			T.equal(P.page(2.4, i).alpha, 0)
			for frame = 0, 144 do
				local sample = P.page(frame / 60, i)
				for _, value in pairs(sample) do T.truthy(value == value and math.abs(value) < 100) end
				T.truthy(sample.alpha >= 0 and sample.alpha <= 1 and sample.scale >= .5)
			end
		end
	end)
	T.test("AG67B soul starts at book and terminates exactly at the current chest", function()
		for i = 1, 3 do
			local a, b = P.soul(0, i), P.soul(1, i)
			T.equal(a.blend, 0); T.equal(b.blend, 1)
			T.near(a.x, 0); T.near(b.x, 0); T.near(b.y, 0); T.near(b.z, 0)
			local wrap = P.soul(.8, i); T.equal(wrap.blend, 1)
			T.truthy(math.abs(wrap.x) + math.abs(wrap.z) > .2)
		end
	end)
	T.test("AG67B R6 R15 missing and root-only rigs are supported", function()
		local function rig(parts) return {FindFirstChild = function(_, name) return parts[name] end} end
		T.equal(P.chest(rig({UpperTorso = 15, Torso = 6})), 15)
		T.equal(P.chest(rig({Torso = 6})), 6)
		T.equal(P.chest(rig({HumanoidRootPart = 1})), 1)
		T.equal(P.chest(rig({})), nil); T.equal(P.chest(nil), nil)
	end)
	T.test("AG67B pulse waits for each sector and settles without discontinuous reset", function()
		T.equal(P.flash(1, 1.2, false), 0)
		T.truthy(P.flash(1.3, 1.2, false) > .5)
		T.truthy(P.flash(5, 1.2, false) < .001)
	end)
end
