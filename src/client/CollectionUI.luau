--!nonstrict
-- Lightweight paged text controls. This module only sends intents and renders snapshots.
local UI = {}
local function statText(stats) return "Farming " .. stats.Farming .. " · Hauling " .. stats.Hauling .. " · Brewing " .. stats.Brewing end
local function sortedKeys(map) local result = {}; for key in pairs(map) do table.insert(result, key) end; table.sort(result); return result end
local function workplace(state, petId)
	for id, station in pairs(state.stations) do if station.workerId == petId then return id end end
	return nil
end
function UI.new(config)
	local self = { mode = "inventory", page = 1, sort = "rarity", freeOnly = false, query = "", target = "cauldron", chosen = {}, detailsSeen = false, confirmSummon = nil, confirmOffer = nil }
	function self.signature(state)
		local fields = { tostring(state.collection.sequence), tostring(state.writable), state.collectionPolicy.status, state.fusePreview and state.fusePreview.token or "" }
		for _, id in ipairs(config.stationOrder) do
			table.insert(fields, (state.stations[id].workerId or "") .. ":" .. state.stations[id].level)
		end
		return table.concat(fields, "|")
	end
	function self.draw(ctx)
		local state, text, action, redraw, send = ctx.state, ctx.text, ctx.action, ctx.redraw, ctx.send
		for id in pairs(self.chosen) do if not state.pets[id] then self.chosen[id] = nil end end
		text("Фамильяры · " .. #sortedKeys(state.pets) .. "/" .. config.maxPets .. " · " .. (state.writable and "Готово" or "Сохранение / ожидание"), 44)
		if state.collection.lastResult then text("Сохранено: " .. state.collection.lastResult.message, 48) end
		for _, tab in ipairs({ {"inventory", "Коллекция"}, {"summon", "Призыв / Шансы"}, {"shop", "Гарантированный магазин"}, {"fuse", "Fuse / Эволюция"} }) do
			action((self.mode == tab[1] and "• " or "") .. tab[2], function() self.mode, self.confirmSummon, self.confirmOffer = tab[1], nil, nil; redraw() end)
		end
		if self.mode == "inventory" then
			action("Свободные: " .. (self.freeOnly and "ДА" or "ВСЕ"), function() self.freeOnly = not self.freeOnly; self.page = 1; redraw() end)
			for _, order in ipairs({ "rarity", "Farming", "Hauling", "Brewing" }) do
				action("Сортировка: " .. order .. (self.sort == order and " ✓" or ""), function() self.sort, self.page = order, 1; redraw() end)
			end
			local search = Instance.new("TextBox")
			search.Size, search.TextSize, search.ClearTextOnFocus = UDim2.new(1, -8, 0, 44), 16, false
			search.Text, search.PlaceholderText = self.query, "Поиск по имени, виду или ID"
			search.TextColor3, search.BackgroundColor3 = Color3.fromRGB(237,239,246), Color3.fromRGB(42,48,61)
			ctx.mount(search)
			search.FocusLost:Connect(function() self.query = string.sub(search.Text, 1, 80); self.page = 1; redraw() end)
			action("Место для назначения: " .. config.stations[self.target].name, function()
				local index = table.find(config.stationOrder, self.target) or 1
				self.target = config.stationOrder[index % #config.stationOrder + 1]; redraw()
			end)
			local ids = {}
			for id, pet in pairs(state.pets) do
				if (not self.freeOnly or not workplace(state, id)) and string.find(string.lower(pet.name .. " " .. pet.species .. " " .. id), string.lower(self.query), 1, true) then table.insert(ids, id) end
			end
			table.sort(ids, function(a, b)
				local pa, pb = state.pets[a], state.pets[b]
				local va = self.sort == "rarity" and config.rarityOrder[pa.rarity] or pa.stats[self.sort]
				local vb = self.sort == "rarity" and config.rarityOrder[pb.rarity] or pb.stats[self.sort]
				return va == vb and a < b or va > vb
			end)
			local pages = math.max(1, math.ceil(#ids / config.collection.pageSize))
			self.page = math.clamp(self.page, 1, pages)
			text("Страница " .. self.page .. "/" .. pages .. " · найдено " .. #ids, 36)
			action("Предыдущая страница", function() self.page = math.max(1, self.page - 1); redraw() end)
			action("Следующая страница", function() self.page = math.min(pages, self.page + 1); redraw() end)
			for index = (self.page - 1) * config.collection.pageSize + 1, math.min(#ids, self.page * config.collection.pageSize) do
				local id = ids[index]
				local pet, assigned = state.pets[id], workplace(state, id)
				local definition, station = config.stations[self.target], state.stations[self.target]
				local effective = math.min(pet.stats[definition.skill], definition.statCaps[station.level] or 0)
				text(pet.name .. " · " .. pet.rarity .. " · ступень " .. pet.evolution .. "\nID: " .. id .. "\nБаза: " .. statText(pet.stats)
					.. "\n" .. definition.name .. ": " .. definition.skill .. " " .. pet.stats[definition.skill] .. " → " .. effective
					.. "\n" .. (assigned and ("Занят: " .. config.stations[assigned].name) or "Свободен") .. (pet.locked and " · Защищён" or "")
					.. "\nИсточник: " .. pet.provenance.source .. (pet.provenance.paidDerived and " · платное происхождение" or ""), 152)
				action(pet.locked and "Снять защиту" or "Защитить от Fuse", function() send("petLock", { petId = id, locked = not pet.locked }) end)
				action(assigned and "Снять с рабочего места" or ("Назначить: " .. definition.name), function()
					send("assign", { stationId = assigned or self.target, petId = assigned and "" or id })
				end)
				action(self.chosen[id] and "Убрать из Fuse" or "Выбрать для Fuse", function()
					if self.chosen[id] then self.chosen[id] = nil
					elseif not pet.locked and not assigned and #sortedKeys(self.chosen) < 5 then self.chosen[id] = true end
					redraw()
				end)
			end
			text("Для защиты и Fuse подойди к своему алтарю. Для назначения/снятия — к нужному рабочему месту. Защищённых и занятых нельзя расходовать.", 88)
		elseif self.mode == "summon" then
			local details, access = state.summonDetails, state.collectionPolicy
			text("Призыв: " .. details.cost .. " Essence за питомца. Случайный вид и три случайных стата.", 64)
			action("Details / Шансы видов и характеристик", function() self.detailsSeen = true; redraw() end)
			if self.detailsSeen then
				local tiers = {}
				for _, outcome in ipairs(details.outcomes) do tiers[outcome.rarity] = (tiers[outcome.rarity] or 0) + outcome.percent end
				local tierLines = {}
				for _, rarity in ipairs({ "Common", "Rare", "Legendary", "Secret" }) do table.insert(tierLines, rarity .. " " .. string.format("%.2f%%", tiers[rarity] or 0)) end
				text(table.concat(tierLines, " · "), 60)
				text("Все значения каждого стата в указанном диапазоне равновероятны и независимы. Шанс точной тройки = шанс вида / число сочетаний. Десятичные проценты округлены; дроби задают точное значение.", 112)
				for _, outcome in ipairs(details.outcomes) do
					local lines = { outcome.name .. " · " .. outcome.rarity .. " · " .. string.format("%.2f%%", outcome.percent) }
					for _, skill in ipairs({ "Farming", "Hauling", "Brewing" }) do
						local range = outcome.ranges[skill]; local n = range[2] - range[1] + 1
						table.insert(lines, skill .. " " .. range[1] .. "…" .. range[2] .. ": каждое число 1/" .. n .. " = " .. string.format("%.10f%%", 100 / n))
					end
					table.insert(lines, "Любая точная тройка: " .. string.format("%.10f%%", outcome.tuplePercent) .. " (" .. outcome.weight .. "/" .. details.totalWeight .. "/" .. outcome.combinations .. ")")
					text(table.concat(lines, "\n"), 168)
				end
			end
			if not access.randomAllowed or access.status ~= "unrestricted" then
				text(access.status == "restricted" and "Случайный призыв недоступен для этого аккаунта. Выбери конкретного питомца в магазине." or "Доступность призыва не подтверждена. Гарантированный магазин работает.", 88)
				action("Открыть гарантированный магазин", function() self.mode = "shop"; redraw() end)
				action("Обновить доступность призыва", function() send("refreshPolicy", {}) end)
			elseif self.detailsSeen then
				for _, n in ipairs({ 1, 5 }) do action("Призвать " .. n .. " · " .. n * details.cost .. " Essence", function() self.confirmSummon = n; redraw() end) end
				if self.confirmSummon then
					local n = self.confirmSummon
					text("Подтверди расход " .. n * details.cost .. " Essence за " .. n .. " случайных питомцев. Сведения о шансах приведены выше.", 72)
					action("Подтверждаю призыв", function() self.confirmSummon = nil; send("summon", { poolId = details.id, count = n }) end)
				end
			else text("Открой Details / Шансы перед подтверждением призыва.", 52) end
		elseif self.mode == "shop" then
			text("Каждый вид и все статы известны заранее. Магазин доступен и при ограничении случайных наград.", 72)
			for _, offerId in ipairs(sortedKeys(state.familiarShop)) do
				local offer = state.familiarShop[offerId]
				local def = config.petSpecies[offer.species]
				text(def.name .. " · " .. def.rarity .. "\n" .. statText(offer.stats) .. "\nЦена: " .. offer.cost .. " " .. offer.currency, 100)
				action("Выбрать " .. def.name, function() self.confirmOffer = offerId; redraw() end)
				if self.confirmOffer == offerId then action("Подтверждаю: " .. offer.cost .. " " .. offer.currency, function() self.confirmOffer = nil; send("shopFamiliar", { offerId = offerId }) end) end
			end
		elseif self.mode == "fuse" then
			local ids = sortedKeys(self.chosen)
			text("5 одинаковых видов одной ступени → 1 следующая форма. Результат гарантирован. Выбирай родителей в коллекции; стартеры тоже расходуются только после подтверждения.", 104)
			for _, id in ipairs(ids) do text(state.pets[id].name .. "\nID: " .. id .. "\n" .. statText(state.pets[id].stats), 84) end
			action("Очистить выбор", function() self.chosen = {}; redraw() end)
			if #ids == 5 then action("Рассчитать точный результат", function() send("previewFuse", { petIds = ids }) end) end
			local preview = state.fusePreview
			if preview and table.concat(preview.parentIds, "|") == table.concat(ids, "|") then
				text("Будут удалены ровно эти 5 ID:\n" .. table.concat(preview.parentIds, "\n"), 144)
				text("Получишь: " .. preview.name .. " · " .. preview.rarity .. "\n" .. statText(preview.stats) .. "\nУспех: 100%" .. (preview.paidDerived and " · платное происхождение сохраняется" or ""), 100)
				action("Подтверждаю удаление 5 и создание 1", function() send("fuse", { petIds = ids, previewToken = preview.token, confirmed = true }) end)
			end
		end
	end
	return self
end
return UI
