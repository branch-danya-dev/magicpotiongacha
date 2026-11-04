--!nonstrict
-- Portable interaction contract only; this does not assert Roblox touch/layout acceptance.
local UI=require("../src/client/LongTermUI")
local H=require("./M5Harness")
local Config=require("../src/shared/Config")
local function fixture()
	local h=H.new(); h.complete(); h.ui=UI.new(Config); h.sent={}; h.buttons={}; h.texts={}
	function h.render(mode)
		h.buttons,h.texts={},{}
		h.ui.draw({state={gold=h.profile.gold,essence=h.profile.essence,longTerm=h.longTerm.state(h.profile,h.now)},mode=mode or "rebirth",
			text=function(value) table.insert(h.texts,value) end,action=function(label,callback) h.buttons[label]=callback end,
			send=function(action,payload) table.insert(h.sent,{action=action,payload=payload}) end,redraw=function() h.render(mode) end})
	end
	return h
end
return function(T:any)
	T.test("M5 UI: reset requires review and distinct confirmation tied to the same cycle/request",function()
		local h=fixture(); h.render(); T.equal(h.buttons["Подтвердить Rebirth и сброс фабрики"],nil)
		h.buttons["Я прочитал: проверить перерождение"](); T.equal(#h.sent,0)
		h.buttons["Подтвердить Rebirth и сброс фабрики"]()
		T.same(h.sent[1],{action="rebirth",payload={expectedRebirthCount=0,confirmed=true,requestId=1}})
		h.buttons["Подтвердить Rebirth и сброс фабрики"](); T.same(h.sent[1],h.sent[2])
	end)
	T.test("M5 UI: unrelated durable reward invalidates an old review and cancel sends nothing",function()
		local h=fixture(); h.render(); h.buttons["Я прочитал: проверить перерождение"]()
		T.truthy(h.run("claimCalendar",{expectedDay=math.floor(h.now/86400)})); h.render()
		T.equal(h.buttons["Подтвердить Rebirth и сброс фабрики"],nil)
		h.buttons["Я прочитал: проверить перерождение"](); h.buttons["Отмена"](); T.equal(#h.sent,0)
	end)
	T.test("M5 UI: welcome reopening and Continue have no economic command",function()
		local h=fixture(); T.truthy(h.rebirth()); local before=H.copy(h.profile)
		h.render(); h.render(); T.truthy(h.buttons["Продолжить новую фабрику"]); h.buttons["Продолжить новую фабрику"]()
		h.render(); T.equal(h.buttons["Продолжить новую фабрику"],nil); T.equal(#h.sent,0); T.same(h.profile,before)
	end)
end
