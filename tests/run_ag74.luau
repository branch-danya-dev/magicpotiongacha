--!nonstrict
local T = require("./Test")
local Idle = require("../src/shared/FamiliarIdle")
local function fixture(values)
	local clock, index = 0, 0
	local tracks = {}
	for i = 1, 2 do
		local track = {Length = i == 1 and 3.6 or 3, plays = 0, stops = {}, destroyed = 0, connected = true}
		track.DidLoop = {Connect = function(_, cb)
			track.callback = cb
			return {Disconnect = function() track.connected = false end}
		end}
		function track:Play(fade) self.plays += 1; self.fade = fade end
		function track:Stop(fade) table.insert(self.stops, fade) end
		function track:Destroy() self.destroyed += 1 end
		tracks[i] = track
	end
	local driver = Idle.new(tracks, function() index += 1; return values[index] or 0 end, function() return clock end)
	return driver, tracks, function(t) clock = t end
end
T.test("AG74 default and validated configurable 50/50 weights", function()
	T.equal(Idle.calmProbability(nil), .5); T.equal(Idle.calmProbability({1,1}), .5)
	T.equal(Idle.calmProbability({3,1}), .75); T.equal(Idle.calmProbability({0,1}), 0)
	for _, bad in ipairs({{0,0},{-1,2},{math.huge,1},{0/0,1},{1,"x"}}) do T.equal(Idle.calmProbability(bad),.5) end
end)
T.test("AG74 Calm to Calm continues without restart", function()
	local d,t,clock = fixture({0,0,0}); d.setIdle(true); clock(3.6); t[1].callback()
	T.equal(d.current,1); T.equal(t[1].plays,1); T.equal(d.selections,1)
end)
T.test("AG74 Active to Active continues without restart", function()
	local d,t,clock = fixture({.9,0,.9}); d.setIdle(true); clock(3); t[2].callback()
	T.equal(d.current,2); T.equal(t[2].plays,1)
end)
for _, pair in ipairs({{0,.9,1,2,3.6},{.9,0,2,1,3}}) do
	T.test("AG74 crossfade "..pair[3].." to "..pair[4], function()
		local d,t,clock=fixture({pair[1],0,pair[2]}); d.setIdle(true); clock(pair[5]); t[pair[3]].callback()
		T.equal(d.current,pair[4]); T.equal(t[pair[3]].stops[1],.3); T.equal(t[pair[4]].fade,.3)
	end)
end
T.test("AG74 partial initial loop does not select before a full cycle", function()
	local d,t,clock=fixture({0,.5,.9}); d.setIdle(true); T.equal(t[1].TimePosition,1.8)
	clock(1.8); t[1].callback(); T.equal(d.selections,0)
	clock(5.4); t[1].callback(); T.equal(d.current,2)
end)
T.test("AG74 outgoing and duplicated loop callbacks cannot select twice", function()
	local d,t,clock=fixture({0,0,.9,0}); d.setIdle(true); clock(3.6); t[1].callback()
	t[1].callback(); t[2].callback(); T.equal(d.selections,1)
end)
T.test("AG74 movement interruption prevents late loop callback restart", function()
	local d,t,clock=fixture({0,0,.9}); d.setIdle(true); d.setIdle(false); clock(9); t[1].callback()
	T.equal(d.current,nil); T.equal(d.selections,0); T.equal(t[1].stops[1],.15)
	d.setIdle(false); T.equal(#t[1].stops,1)
end)
T.test("AG74 dispose disconnects and destroys exactly two tracks once", function()
	local d,t,clock=fixture({0,0}); d.setIdle(true); d.destroy(); d.destroy(); clock(20)
	t[1].callback(); d.setIdle(true); T.equal(d.current,nil); T.equal(#d.connections,0)
	for _, track in ipairs(t) do T.equal(track.destroyed,1); T.falsy(track.connected) end
end)
T.test("AG74 independent pets keep separate random selection and phase", function()
	local a,ta=fixture({0,.2}); local b,tb=fixture({.9,.7}); a.setIdle(true); b.setIdle(true)
	T.equal(a.current,1); T.equal(b.current,2); T.near(ta[1].TimePosition,.72); T.near(tb[2].TimePosition,2.1)
end)
T.test("AG74 delayed low-FPS callback only selects once", function()
	local d,t,clock=fixture({0,0,.9}); d.setIdle(true); clock(20); t[1].callback(); t[2].callback()
	T.equal(d.selections,1)
end)
T.test("AG74 refuses unloaded tracks", function()
	T.throws(function() Idle.new({{Length=0},{Length=3}}, function()return 0 end, function()return 0 end) end)
end)
T.test("AG74 repeated updates do not restart or reload tracks", function()
	local d,t=fixture({0,0}); for _=1,10000 do d.setIdle(true) end
	T.equal(t[1].plays,1); T.equal(t[2].plays,0); T.equal(#d.connections,2)
end)
T.finish()
