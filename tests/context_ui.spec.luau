--!nonstrict
local UI=require("../src/shared/ContextUI")
local Config=require("../src/shared/Config")
local Codec=require("../src/shared/TradeCodec")
local function entry(id,changes)
	local e={id=id,owner=1,enabled=true,visible=true,clear=true,distance=6,maximum=16,x=400,y=250,z=10,aim=0,station="crystal"}
	for k,v in pairs(changes or {}) do e[k]=v end
	return e
end
return function(T:any)
	T.test("UI18: desktop panel clears native chat at both review resolutions",function()
		for _,w in ipairs({1366,1920}) do
			local l=UI.layout(w,768,false,w*.4)
			T.truthy(not l.chatModal); T.truthy(l.left>w*.4)
			T.truthy(l.left+l.width<w-250)
		end
	end)
	T.test("UI18: narrow screens yield to open native chat and restore on close",function()
		for _,s in ipairs({{402,816,true},{874,344,true},{800,600,false}}) do
			T.truthy(UI.layout(s[1],s[2],s[3],s[1]*.4).chatModal)
			T.truthy(not UI.layout(table.unpack(s)).chatModal)
		end
		T.truthy(UI.layout(1366,768,false,1100).chatModal)
	end)
	T.test("UI18: HUD and reserved action rail cannot be overlapped by native prompt",function()
		local list={entry("blocked"),entry("clear",{x=800})}
		local selected=UI.candidates(list,1,1280,720,{{x=350,y=230,w=100,h=40}})
		T.equal(#selected,1); T.equal(selected[1].id,"clear")
	end)
	T.test("UI18: price and shortfall follow current server snapshot without mutation",function()
		local state={gold=10,builds={garden={cost=100,reason="Нужна фаза 2"}}}; local before=Codec.copy(state)
		local text,cost=UI.upgradeDetails(state,"garden"); T.equal(cost,100); T.truthy(string.find(text,"90 Gold",1,true)); T.truthy(string.find(text,"Нужна фаза 2",1,true)); T.same(state,before)
		state.gold=120; text=UI.upgradeDetails(state,"garden"); T.truthy(string.find(text,"Gold достаточно",1,true))
	end)
	T.test("UI18: max upgrade and phase prerequisites remain inspectable",function()
		local text,cost=UI.upgradeDetails({gold=0,builds={garden={}}},"garden"); T.equal(cost,nil); T.truthy(string.find(text,"Максимальный",1,true))
		text,cost=UI.upgradeDetails({gold=100,phase={cost=400,reasons={"Трубы","Кристалл 2"}}},"blueprint"); T.equal(cost,400); T.truthy(string.find(text,"Трубы; Кристалл 2",1,true))
	end)
	T.test("UI18: own and public contexts exclude neighbours",function()
		local a=UI.candidates({entry("own"),entry("foreign",{owner=2}),entry("public",{owner=2,public=true})},1,1280,720)
		T.equal(#a,2); T.equal(a[1].id,"own"); T.equal(a[2].id,"public")
	end)
	for _,reason in ipairs({"disabled","hidden","occluded","far","behind","left","top","bottom","nan"}) do
		T.test("UI18: rejects unavailable context / "..reason,function()
			local changes=({disabled={enabled=false},hidden={visible=false},occluded={clear=false},far={distance=17},behind={z=-1},left={x=5},top={y=10},bottom={y=700},nan={distance=0/0}})[reason]
			T.equal(#UI.candidates({entry("bad",changes)},1,1280,720),0)
		end)
	end
	T.test("UI18: exact native activation limit is retained",function()
		T.equal(#UI.candidates({entry("pad",{maximum=8,distance=8})},1,1280,720),1)
		T.equal(#UI.candidates({entry("pad",{maximum=8,distance=8.001})},1,1280,720),0)
	end)
	T.test("UI18: selection is deterministic, singular and does not mutate inputs",function()
		local a={entry("z"),entry("a")}; local before=Codec.copy(a)
		local list=UI.candidates(a,1,1280,720); T.equal(UI.choose(list,nil,false).id,"a"); T.same(a,before)
		T.equal(UI.choose({},"a",false),nil)
	end)
	T.test("UI18: cycling moves and wraps without activating a purchase",function()
		local list={entry("a"),entry("b")}
		T.equal(UI.choose(list,"a",true).id,"b"); T.equal(UI.choose(list,"b",true).id,"a")
	end)
	T.test("UI18: small movement does not oscillate focus, stale focus expires",function()
		local list={entry("a"),entry("b",{distance=7})}
		T.equal(UI.choose(list,"b",false).id,"b")
		T.equal(UI.choose(list,"gone",false).id,"a")
		list[2].distance=10; T.equal(UI.choose(list,"b",false).id,"a")
	end)
	for _,size in ipairs({{1366,768,false},{1920,1080,false},{844,390,true},{390,844,true},{320,568,true}}) do
		T.test("UI18: safe panel and action rail / "..size[1].."x"..size[2],function()
			local l=UI.layout(table.unpack(size))
			T.truthy(l.width<=size[1]-24); T.truthy(l.height<=size[2]-72)
			T.truthy(l.hudWidth<=size[1]-24 and l.railWidth<=size[1]-24)
			if size[3] then T.truthy(l.compact); T.truthy(l.bottom==(l.portrait and 150 or 20)) end
			if size[1]<size[2] then T.truthy(l.portrait); T.truthy(l.height<=size[2]*.53) end
		end)
	end
	T.test("UI18: short context titles contain no prices or status blocks",function()
		T.equal(UI.description(entry("c"),Config),Config.stations.crystal.name)
		T.equal(UI.description({station="blueprint"},Config),"Развитие")
		T.equal(UI.description({public=true},Config),"Магический базар")
		T.equal(UI.description(nil,Config),"")
	end)
end
