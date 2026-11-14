--!nonstrict
local Assets=require("../src/shared/EnvironmentAssets")
local function all(state,except)
	for _,key in ipairs(Assets.keys) do if key~=except then Assets.record(state,Assets.uri(key),true) end end
end
return function(T:any)
	T.test("AG69 canonical roster and IDs are immutable",function()
		T.equal(#Assets.keys,12); local seen={}
		for _,key in ipairs(Assets.keys) do T.falsy(seen[Assets.uri(key)]); seen[Assets.uri(key)]=true end
		T.throws(function() Assets.ids.sun="1" end); T.throws(function() Assets.keys[1]="moon" end)
		T.throws(function() Assets.uri("unknown") end)
	end)
	T.test("AG69 initial zero failures cannot be mistaken for completed loading",function()
		local s=Assets.new(); T.equal(Assets.failures(s),0); T.falsy(s.complete)
		all(s); T.falsy(Assets.skyReady(s)); T.falsy(Assets.ready(s,"sun"))
		Assets.finish(s); T.truthy(Assets.skyReady(s)); T.equal(Assets.failures(s),0)
	end)
	for i=1,6 do local key=Assets.keys[i]
		T.test("AG69 missing "..key.." falls back the complete sky without hiding healthy sprites",function()
			local s=Assets.new(); all(s,key); Assets.finish(s)
			T.equal(Assets.failures(s),1); T.falsy(Assets.skyReady(s)); T.truthy(Assets.ready(s,"moon"))
		end)
	end
	T.test("AG69 independent sprite failure preserves the healthy sky",function()
		local s=Assets.new(); all(s,"mist"); Assets.finish(s)
		T.truthy(Assets.skyReady(s)); T.falsy(Assets.ready(s,"mist")); T.truthy(Assets.ready(s,"rainbow"))
	end)
	T.test("AG69 duplicate failure callbacks count one asset and never resurrect it",function()
		local s=Assets.new(); all(s)
		for _=1,20 do Assets.record(s,Assets.uri("star"),false); Assets.record(s,Assets.uri("star"),true) end
		Assets.finish(s); T.equal(Assets.failures(s),1); T.falsy(Assets.ready(s,"star"))
	end)
	T.test("AG69 missing callbacks fail closed and repeated completion stays stable",function()
		local s=Assets.new(); Assets.finish(s); Assets.finish(s); all(s)
		T.truthy(s.complete); T.equal(Assets.failures(s),12); T.falsy(Assets.skyReady(s))
	end)
	T.test("AG69 unknown callbacks cannot satisfy the manifest",function()
		local s=Assets.new(); Assets.record(s,"rbxassetid://1",true); Assets.finish(s)
		T.equal(Assets.failures(s),12)
	end)
	T.test("AG69 restarted owner has independent delivery state",function()
		local old=Assets.new(); local current=Assets.new(); all(old); Assets.finish(old)
		T.truthy(Assets.skyReady(old)); T.falsy(current.complete); T.falsy(Assets.skyReady(current))
	end)
end
