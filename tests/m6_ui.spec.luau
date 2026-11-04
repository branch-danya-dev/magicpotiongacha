--!nonstrict
local H=require("./M6Harness")
local UI=require("../src/client/ShopUI")
local function fixture()
	local h=H.new(); h.ui=UI.new(); h.sent={}; h.previewed={}
	function h.render()
		h.buttons,h.texts={},{}; local state=h.model.state(h.profile(),h.now)
		for _,c in ipairs(state.cards) do c.robuxAvailable=h.paid==true; c.sku=1001 end
		h.ui.draw({state={shop=state},text=function(t) table.insert(h.texts,t) end,utc=function(n) return tostring(n).." UTC" end,
			price=function() return h.price end,preview=function(v) h.previewed[v]=true end,
			action=function(label,fn) h.buttons[label]=fn end,send=function(a,p) table.insert(h.sent,{action=a,payload=p}) end,redraw=h.render})
	end
	return h
end
return function(T:any)
	T.test("M6 UI: Gold review and explicit confirmation send one fixed intent",function()
		local h=fixture(); h.render(); local name=H.Config.monetization.offers.ghost_wolf_v1.name
		T.equal(h.buttons["Подтвердить 1800 Gold: "..name],nil); h.buttons["Купить за Gold: "..name](); T.equal(#h.sent,0)
		h.buttons["Подтвердить 1800 Gold: "..name](); h.buttons["Подтвердить 1800 Gold: "..name]()
		T.same(h.sent[1],{action="buyEventGold",payload={offerId="ghost_wolf_v1",confirmed=true,requestId=1}}); T.same(h.sent[1],h.sent[2])
		T.truthy(h.previewed.ghost); T.truthy(h.previewed.spectral); T.truthy(h.previewed.aurora)
	end)
	T.test("M6 UI: Robux requires known platform price; prompt carries no payment proof",function()
		local h=fixture(); h.paid=true; h.render(); local name=H.Config.monetization.offers.ghost_wolf_v1.name
		for label in pairs(h.buttons) do T.falsy(string.find(label,"Купить за Robux",1,true)) end
		h.price=123; h.render(); h.buttons["Купить за Robux: 123 · "..name]()
		T.same(h.sent[1],{action="requestPurchase",payload={offerId="ghost_wolf_v1"}})
	end)
	T.test("M6 UI: ended event hides acquisition but preserves delivery and processed explanation",function()
		local h=fixture(); h.fill("pet"); T.truthy(h.process()); h.now=H.Config.events.spectral_2026.endAtUtc; h.render()
		local name=H.Config.monetization.offers.ghost_wolf_v1.name; T.equal(h.buttons["Купить за Gold: "..name],nil)
		h.buttons["Доставить оплаченные предметы (1)"](); T.same(h.sent[1],{action="deliverPurchases",payload={requestId=h.profile().monetization.sequence+1}})
		T.truthy(string.find(table.concat(h.texts,"\n"),"Событие завершено",1,true)); T.truthy(string.find(table.concat(h.texts,"\n"),"Оплачено, ждёт места: 1",1,true))
	end)
	T.test("M6 UI: cancellation sends nothing; rights refresh is a request, never local grant",function()
		local h=fixture(); h.render(); h.buttons["Купить за Gold: "..H.Config.monetization.offers.ghost_wolf_v1.name](); h.buttons["Отменить покупку за Gold"](); T.equal(#h.sent,0)
		h.buttons["Обновить права и доставки"](); T.same(h.sent[1],{action="refreshPurchases",payload={}})
	end)
end
