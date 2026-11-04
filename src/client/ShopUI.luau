--!nonstrict
-- Fixed outcomes and separate Gold/native-payment intents; no local grant method.
local UI={}
function UI.new()
	local ui={}; local reviewed
	local status={available="Доступно",upcoming="Событие ещё не началось",ended="Событие завершено",owned="Право уже получено",unavailable="Недоступно",epoch_unavailable="Недоступно в этой эпохе"}
	function ui.draw(ctx)
		local s=ctx.state.shop
		ctx.text("Событие / Магазин\nТочные предметы за заработанный Gold или отдельную покупку Roblox. Gold, Essence и Time Shards не продаются.",108)
		ctx.text("Покупки — рядом с алтарём на своём участке. Характеристики Gold- и Robux-экземпляров одинаковы. Срок события не удаляет полученные предметы.",96)
		for _,card in ipairs(s.cards) do
			ctx.text(card.name.." · "..(status[card.status] or card.status),48)
			if ctx.preview then ctx.preview(card.visual) end
			if card.stats then ctx.text("Farming "..card.stats.Farming.." / Hauling "..card.stats.Hauling.." / Brewing "..card.stats.Brewing,54) end
			ctx.text(card.effect,90)
			if card.event then ctx.text("Окно UTC: "..ctx.utc(card.event.startAtUtc).." → "..ctx.utc(card.event.endAtUtc)..". После окончания новые покупки закрываются; предмет остаётся навсегда.",108)
			else ctx.text("Постоянное предложение. Право привязано к аккаунту и не передаётся.",64) end
			ctx.text("В коллекции: "..card.owned.." · Оплачено, ждёт места: "..card.queued.." · Доставленных покупок: "..card.delivered,68)
			if card.delivered>0 then ctx.text("Уже обработанные чеки не создают копию после обмена или Fuse.",60) end
			ctx.text("Цена за заработанный Gold: "..card.goldCost,44)
			if card.available and card.room then
				if reviewed and reviewed.offerId==card.offerId and reviewed.sequence==s.sequence then
					local request=s.sequence+1
					ctx.action("Подтвердить "..card.goldCost.." Gold: "..card.name,function() ctx.send("buyEventGold",{offerId=card.offerId,confirmed=true,requestId=request}) end)
					ctx.action("Отменить покупку за Gold",function() reviewed=nil; ctx.redraw() end)
				else ctx.action("Купить за Gold: "..card.name,function() reviewed={offerId=card.offerId,sequence=s.sequence}; ctx.redraw() end) end
			elseif not card.room then ctx.text("Коллекция заполнена: новые покупки закрыты. Освободи место через подходящий Fuse или разрешённый обмен; оплаченные права остаются.",100) end
			local price=ctx.price and ctx.price(card)
			if card.robuxAvailable and price~=nil then
				ctx.action("Купить за Robux: "..price.." · "..card.name,function() ctx.send("requestPurchase",{offerId=card.offerId}) end)
				ctx.text("Цена получена от Roblox. Окончательная цена и подтверждение — в окне платформы.",65)
			else ctx.text("Robux: недоступно или цена не подтверждена. Бесплатный путь за Gold сохраняется.",64) end
		end
		if s.queued>0 then ctx.action("Доставить оплаченные предметы ("..s.queued..")",function() ctx.send("deliverPurchases",{requestId=s.sequence+1}) end) end
		ctx.action("Обновить права и доставки",function() ctx.send("refreshPurchases",{}) end)
	end
	return ui
end
return UI
