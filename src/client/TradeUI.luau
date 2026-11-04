--!nonstrict
-- Two-column review and explicit intents; server snapshots are the only item data.
local TradeUI={}
function TradeUI.new(config)
	local ui={}; local page,reviewHash,dismissed=1,nil,nil
	local status={invited="Приглашение",negotiating="Выбор предметов",both_ready="Оба готовы: проверь итог",frozen="Сохранение обмена",recovering="Восстановление обмена",settled="Обмен завершён",aborted="Обмен безопасно отменён",cancelled="Обмен отменён",declined="Приглашение отклонено"}
	local terminal={settled=true,aborted=true,cancelled=true,declined=true}
	local function description(entry)
		local item=entry.data; local origin=item.provenance
		local text=(entry.kind=="pet" and item.name or config.cauldronTypes[item.type].name).."\nID: "..entry.id
		if entry.kind=="pet" then
			text..="\n"..item.rarity.." · эволюция "..item.evolution
			for _,skill in ipairs({"Farming","Hauling","Brewing"}) do text..="\n"..skill..": "..item.stats[skill].." → "..((entry.effective or {})[skill] or 0) end
			text..="\nСправа — предел на твоих текущих станциях; назначение отдельно."
		else text..="\nТип: "..item.type.." · скорость варки +"..((item.brewSpeedBonus or 0)*100).."% · x2 +"..(item.bonus*100).." п.п. (общий предел "..(config.maxDoubleChance*100).."%)" end
		text..="\n"..(item.locked and "Защищён" or "Не защищён").." · источник: "..tostring(origin and origin.source or "неизвестен")
		text..="\nПлатное происхождение: "..(origin and origin.paidDerived and "да" or "нет")
		if origin and origin.parents and #origin.parents>0 then text..="\nFuse: "..table.concat(origin.parents,", ") end
		return text
	end
	function ui.draw(ctx)
		local value=ctx.value
		if not value then ctx.text("Ожидаем серверное состояние обмена…",60); return end
		if not value.enabled then ctx.text("Публичная торговля выключена. Доступ появится после живой проверки обменов и сохранений.",100); return end
		local t=value.session
		if t and dismissed==t.id and terminal[t.state] then t=nil end
		if value.blocked and not t then ctx.text(value.message or "Восстанавливаем обмен. Повторной выдачи предметов нет.",100); return end
		if not t then
			ctx.text("Подойдите вдвоём к стойке базара. Обмениваются только свободные фамильяры и редкие котлы, до 6 предметов с каждой стороны. Стартовые рабочие защищены.",110)
			for _,peer in ipairs(value.peers) do ctx.action("Пригласить: "..peer.name,function() ctx.send("tradeInvite",{targetToken=peer.token}) end) end
			if #value.peers==0 then ctx.text("Рядом нет доступных игроков. Оба участника должны находиться у стойки базара.",70) end
			return
		end
		ctx.text(status[t.state] or t.state,42)
		if t.reason then ctx.text(t.reason,60) end
		if terminal[t.state] then ctx.action("Новый обмен",function() dismissed=t.id; reviewHash=nil; ctx.redraw() end); return end
		local function send(action,extra)
			local payload=extra or {}; payload.tradeId=t.id; payload.version=t.version; ctx.send(action,payload)
		end
		if t.state=="invited" then
			ctx.text(t.sides[1].name.." → "..t.sides[2].name,56)
			if t.sides[2].mine then ctx.action("Принять приглашение",function() send("tradeAccept") end) end
			ctx.action("Отказать / отменить",function() send("tradeCancel") end); return
		end
		if t.state=="frozen" or t.state=="recovering" then
			ctx.text("Предметы временно недоступны. Сервер проверяет сохранённый результат. После подтверждённой передачи отмена не вернёт старое владение.",120)
			ctx.action("Запросить отмену до решения",function() send("tradeCancel") end); return
		end
		ctx.text("Предложение v"..t.version.." · готовность обеих сторон сбрасывается при любом изменении.",72)
		local row=ctx.text("",1)
		for i,side in ipairs(t.sides) do
			local column=Instance.new("Frame")
			column.BackgroundTransparency=1; column.Size=UDim2.new(0.5,-5,0,0); column.Position=UDim2.new((i-1)*0.5,(i-1)*5,0,0)
			column.AutomaticSize=Enum.AutomaticSize.Y; column.Parent=row
			local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,8); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Parent=column
			local function label(text,order)
				local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.TextColor3=Color3.fromRGB(237,239,246)
				l.TextWrapped=true; l.TextXAlignment=Enum.TextXAlignment.Left; l.Font=Enum.Font.Gotham; l.TextSize=13
				l.Size=UDim2.new(1,0,0,30); l.AutomaticSize=Enum.AutomaticSize.Y; l.LayoutOrder=order; l.Text=text; l.Parent=column
			end
			label((side.mine and "ТЫ: " or "ПАРТНЁР: ")..side.name.."\n"..(t.ready[tostring(i)] and "Готов" or "Выбирает"),0)
			for n,entry in ipairs(side.items) do label(description(entry),n) end
			if #side.items==0 then label("Ничего не передаёт (подарок)",1) end
		end
		local mine=t.sides[1].mine and t.sides[1] or t.sides[2]
		local mineIndex=t.sides[1].mine and "1" or "2"
		ctx.action("Отменить обмен",function() send("tradeCancel") end)
		if t.hash then ctx.text("Точный итог · v"..t.version.."\nSHA-256: "..t.hash,100) end
		ctx.action(t.ready[mineIndex] and "Снять готовность" or "Предложение готово",function() reviewHash=nil; send("tradeReady",{ready=not t.ready[mineIndex]}) end)
		if t.state=="both_ready" then
			if reviewHash~=t.hash then
				ctx.action("Проверил обе колонки — открыть подтверждение",function() reviewHash=t.hash; ctx.redraw() end)
			elseif not t.confirmed[mineIndex] then
				ctx.action("Подтвердить именно v"..t.version.." · "..string.sub(t.hash,1,12),function() send("tradeConfirm",{offerHash=t.hash}) end)
			else ctx.text("Твоё подтверждение принято. Ожидаем вторую сторону.",60) end
		end
		ctx.text("Твой инвентарь · выбор предметов",42)
		local maxPage=math.max(1,math.ceil(#value.inventory/6)); page=math.clamp(page,1,maxPage)
		for i=(page-1)*6+1,math.min(#value.inventory,page*6) do
			local entry=value.inventory[i]; local included=false
			for _,item in ipairs(mine.items) do if item.id==entry.id then included=true end end
			ctx.text(description(entry).."\n"..(entry.available and "Доступен для обмена" or (entry.reason or "Недоступен")),200)
			if entry.available or included then
				ctx.action((included and "Убрать: " or "Предложить: ")..(entry.data.name or config.cauldronTypes[entry.data.type].name),function()
					local items={}; for _,item in ipairs(mine.items) do if item.id~=entry.id then table.insert(items,{kind=item.kind,id=item.id}) end end
					if not included then table.insert(items,{kind=entry.kind,id=entry.id}) end
					reviewHash=nil; send("tradeOffer",{items=items})
				end)
			end
		end
		ctx.text("Страница "..page.." / "..maxPage,36)
		if page>1 then ctx.action("Предыдущие 6",function() page-=1; ctx.redraw() end) end
		if page<maxPage then ctx.action("Следующие 6",function() page+=1; ctx.redraw() end) end
	end
	return ui
end
return TradeUI
