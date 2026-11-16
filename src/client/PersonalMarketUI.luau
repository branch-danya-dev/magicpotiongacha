--!nonstrict
-- Existing fixed-result offers only. All prices, eligibility and grants remain server-owned.
local Config=require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.Config)
local UI={};local category="seeds";local reviewed
local function stats(s) return "Farming "..s.Farming.." · Hauling "..s.Hauling.." · Brewing "..s.Brewing end
function UI.draw(ctx)
	local state=ctx.state
	for _,tab in ipairs({{"seeds","Семена"},{"familiars","Фамильяры"},{"events","Событие за Gold"}}) do
		ctx.action((category==tab[1] and "• " or "")..tab[2],function() category=tab[1];reviewed=nil;ctx.redraw() end)
	end
	ctx.text("Личные покупки доступны с любой точки своего острова. Essence используется для алхимии; обмен валют и торговля между игроками недоступны.",92)
	if not state.writable then ctx.text("Покупки приостановлены: ожидаем подтверждение сохранения.",64);return end
	if category=="seeds" then
		local s=state.firstSession
		ctx.text("Семя · "..s.seedCost.." Gold",44)
		if state.stations.garden.level<1 then ctx.text("Сначала построй грядку в разделе «Ресурсы».",64);return end
		for _,amount in ipairs({1,s.openingSeeds}) do
			ctx.action("Купить "..amount.." · "..amount*s.seedCost.." Gold",function() ctx.send("buySeed",{amount=amount}) end)
		end
	elseif category=="familiars" then
		local ids={};for id in pairs(state.familiarShop) do table.insert(ids,id) end;table.sort(ids)
		for _,id in ipairs(ids) do
			local offer=state.familiarShop[id];local species=Config.petSpecies[offer.species]
			ctx.text(species.name.." · "..species.rarity.."\n"..stats(offer.stats).."\n"..offer.cost.." "..offer.currency,100)
			local key="pet:"..id..":"..state.collection.sequence
			if reviewed==key then
				ctx.action("Подтвердить: "..offer.cost.." "..offer.currency,function() reviewed=nil;ctx.send("shopFamiliar",{offerId=id}) end)
			else ctx.action("Выбрать "..species.name,function() reviewed=key;ctx.redraw() end) end
		end
	else
		for _,card in ipairs(state.shop.cards) do
			ctx.text(card.name.." · "..card.goldCost.." Gold",52)
			if card.stats then ctx.text(stats(card.stats),60) end
			ctx.text(card.effect,80)
			if card.available and card.room then
				local key="event:"..card.offerId..":"..state.shop.sequence
				if reviewed==key then
					local sequence=state.shop.sequence+1
					ctx.action("Подтвердить: "..card.goldCost.." Gold",function() reviewed=nil;ctx.send("buyEventGold",{offerId=card.offerId,confirmed=true,requestId=sequence}) end)
				else ctx.action("Выбрать "..card.name,function() reviewed=key;ctx.redraw() end) end
			else ctx.text(card.room and "Предложение сейчас недоступно." or "В коллекции нет свободного места.",60) end
		end
	end
end
return UI
