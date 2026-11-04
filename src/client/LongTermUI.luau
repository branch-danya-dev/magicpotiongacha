--!nonstrict
-- Server snapshots only; review/continue never grant rewards locally.
local UI={}
function UI.new(config)
	local ui={}; local reviewed,choice,dismissed=nil,nil,nil
	local function rewardText(reward)
		local result={}; for _,key in ipairs({"gold","essence"}) do if reward[key] then table.insert(result,reward[key].." "..(key=="gold" and "Gold" or "Essence")) end end
		return table.concat(result," + ")
	end
	function ui.draw(ctx)
		local p,s=ctx.state,ctx.state.longTerm
		ctx.text(s.epoch.." · цикл "..s.rebirths.."\nTime Shards: "..s.shards,70)
		ctx.text("Действия — у площадки развития на своём участке. Коллекция и награды подтверждаются сервером.",64)
		if ctx.mode=="rebirth" then
			if s.last and s.last.action=="rebirth" and dismissed~=s.rebirths then
				local result=s.last.result
				ctx.text("Добро пожаловать в новую эпоху!\n"..result.epoch.." · получен 1 Time Shard\nСохранены: "..result.petsKept.." фамильяров, "..result.cauldronsKept.." редких котлов. Постоянные улучшения действуют.",140)
				ctx.action("Продолжить новую фабрику",function() dismissed=s.rebirths; reviewed=nil; ctx.redraw() end); return
			end
			ctx.text("Следующая эпоха: "..s.nextEpoch.."\nНаграда: ровно 1 Time Shard",72)
			local function resetText()
				local current=ctx.currentState and ctx.currentState() or p
				return "Будут удалены: весь Gold (сейчас "..current.gold.."), вся Essence ("..current.essence.."), ингредиенты, полуфабрикаты, партии, грузы и текущий заказ. Постройки, склад, трубы и улучшения начнутся с фазы 1."
			end
			local resetLabel=ctx.text(resetText(),150)
			if ctx.bindText then ctx.bindText(resetLabel,resetText) end
			ctx.text("Сохранятся все фамильяры и редкие котлы, их статы и защита, архив рецептов, постоянные права, Time Shards, перки, обучение и ежедневные награды. Работники и котлы будут сняты с оборудования.",140)
			ctx.text(#s.reasons==0 and "Текущий финальный рецепт произведён. Можно проверить и подтвердить Rebirth." or table.concat(s.reasons,"\n"),96)
			if s.available then
				if not reviewed or reviewed.cycle~=s.rebirths or reviewed.requestId~=s.requestId then
					ctx.action("Я прочитал: проверить перерождение",function() reviewed={cycle=s.rebirths,requestId=s.requestId}; ctx.redraw() end)
				else
					ctx.text("Подтверди сброс всего текущего Gold, Essence и фабрики. Коллекция сохранится. Это начало нового цикла.",100)
					ctx.action("Подтвердить Rebirth и сброс фабрики",function() ctx.send("rebirth",{expectedRebirthCount=reviewed.cycle,confirmed=true,requestId=reviewed.requestId}) end)
					ctx.action("Отмена",function() reviewed=nil; ctx.redraw() end)
				end
			end
		elseif ctx.mode=="dailies" then
			ctx.text("Ежедневные задания · общий день UTC "..s.day.."\nУчитываются ручные действия и завершённые ручные варки онлайн. Офлайн и автоварка не считаются. Неполученные задания сменятся в 00:00 UTC.",130)
			for _,quest in ipairs(s.daily) do
				ctx.text(quest.name.." · "..quest.progress.."/"..quest.target.."\nНаграда: "..rewardText(quest.reward)..(quest.claimed and " · получена" or ""),70)
				if not quest.claimed and quest.progress>=quest.target then ctx.action("Получить: "..quest.name,function() ctx.send("claimDaily",{questId=quest.id,expectedDay=s.day,requestId=s.requestId}) end) end
			end
			local reward=s.calendarSpecial and "титул Летописец + фиксированный Moon Cat (F6/H5/B36)" or rewardText(s.calendarReward)
			ctx.text("Календарь · день "..s.calendarStep.."/7\n"..reward.."\nОдин явный claim в день UTC. Пропуск начинает серию с дня 1; после дня 7 — новая серия. Особая награда выдаётся один раз.",130)
			if s.calendarClaimed then ctx.text("Сегодня награда календаря уже получена.",45)
			else ctx.action("Получить награду календаря",function() ctx.send("claimCalendar",{expectedDay=s.day,requestId=s.requestId}) end) end
			if s.calendarPending then
				ctx.text("Moon Cat ждёт доставки: Farming 6 / Hauling 5 / Brewing 36. Право сохраняется без срока. При 128 питомцах освободи места через Fuse; получить можно позже.",108)
				ctx.action("Получить Moon Cat в коллекцию",function() ctx.send("deliverCalendarPet",{requestId=s.requestId}) end)
			end
		else
			ctx.text("Постоянные улучшения · каждый Rebirth даёт 1 Time Shard. Случайного призыва за осколки нет: ниже можно выбрать точного питомца.",100)
			for _,key in ipairs(config.longTerm.perkOrder) do
				local def=config.longTerm.perks[key]
				ctx.text(def.name.." · "..s.perks[key].."/"..def.max.."\n"..def.description.."\nЦена: "..def.cost.." Time Shard",100)
				if s.perks[key]<def.max then ctx.action("Купить: "..def.name,function() ctx.send("buyRebirthPerk",{perkId=key,expectedLevel=s.perks[key],requestId=s.requestId}) end) end
			end
			for _,key in ipairs(config.longTerm.choiceOrder) do
				local def=config.familiarShop[key]; local species=config.petSpecies[key]
				ctx.text(species.name.." · "..species.rarity.."\nFarming "..def.stats.Farming.." / Hauling "..def.stats.Hauling.." / Brewing "..def.stats.Brewing.."\nФиксированно: "..config.longTerm.choiceCost.." Time Shard; без случайности",105)
				if choice==key then ctx.action("Подтвердить покупку: "..species.name,function() ctx.send("chooseRebirthPet",{offerId=key,confirmed=true,requestId=s.requestId}); choice=nil end)
				else ctx.action("Выбрать: "..species.name,function() choice=key; ctx.redraw() end) end
			end
		end
	end
	return ui
end
return UI
