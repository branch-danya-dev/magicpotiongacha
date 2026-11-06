--!nonstrict
-- Presentation rules for the first V2 cycle. Rewards, prices and saves stay in Factory.
local View = {}

local function v2(profile)
	return type(profile) == "table" and type(profile.starter) == "table" and profile.starter.legacyGrant ~= true
end

local function steps(config)
	local session = type(config) == "table" and config.firstSession or nil
	if type(session) == "table" and type(session.tutorialSteps) == "table" then return session.tutorialSteps end
	return {}
end

local function guide(profile)
	local tutorial = type(profile) == "table" and profile.tutorial or nil
	if type(tutorial) == "table" and (tutorial.text ~= nil or tutorial.complete ~= nil or tutorial.id ~= nil) then
		return nil, tutorial
	end
	return type(tutorial) == "table" and tutorial or {}, nil
end

function View.step(profile, config)
	if not v2(profile) then return nil, true end
	local flags, presentation = guide(profile)
	if presentation then
		if presentation.complete == true then return nil, true end
		return presentation.id, false
	end
	for _, id in ipairs(steps(config)) do
		if flags[id] ~= true then return id, false end
	end
	return nil, true
end

function View.intro(profile)
	return v2(profile) and profile.starter.claimed ~= true
end

local shown = {
	familiar = { crystal = true },
	essence = { crystal = true },
	garden = { crystal = true, garden = true },
	seeds = { crystal = true, garden = true },
	crop = { crystal = true, garden = true },
	cauldron = { crystal = true, garden = true, cauldron = true },
	brew = { crystal = true, garden = true, cauldron = true },
	sale = { crystal = true, garden = true, cauldron = true },
	automation = { crystal = true, garden = true, cauldron = true },
	passive = { crystal = true, garden = true, cauldron = true },
}

function View.stationVisible(profile, config, stationId)
	if not v2(profile) then return true end
	local step, done = View.step(profile, config)
	if done then
		if stationId == "crystal" or stationId == "orders" or stationId == "altar" or stationId == "warehouse" or stationId == "blueprint" then return true end
		local station = profile.stations and profile.stations[stationId]
		return type(station) == "table" and (tonumber(station.level) or 0) > 0
	end
	local allowed = shown[step] or { crystal = true }
	return allowed[stationId] == true
end

function View.collision(kind, visible, built)
	if kind == "barrier" then return { collide = true, query = true, touch = false } end
	if kind == "decoration" then return { collide = false, query = false, touch = false } end
	if kind == "pad" or kind == "marker" then
		return { collide = false, query = visible == true, touch = false }
	end
	if visible ~= true then return { collide = false, query = false, touch = false } end
	return { collide = built == true, query = true, touch = false }
end

function View.remoteShop(action)
	return action == "buySeed"
end

function View.offersStation(profile, stationId)
	local station = type(profile) == "table" and profile.stations and profile.stations[stationId]
	return type(station) == "table" and (tonumber(station.level) or 0) < 1
end

function View.glance(reduceMotion, skipped)
	local move = reduceMotion ~= true and skipped ~= true
	return { moveCamera = move, highlight = skipped ~= true, seconds = move and 1.2 or 0 }
end

local focusTarget = {
	familiar = "altar", essence = "crystal", garden = "garden", seeds = "garden", crop = "garden",
	cauldron = "cauldron", brew = "cauldron", sale = "cauldron", automation = "cauldron", passive = "crystal",
}
local shortLine = {
	familiar = "Выбери одного фамильяра.",
	essence = "Собери Essence с кристалла.",
	garden = "Купи грядку.",
	seeds = "Купи 5 семян.",
	crop = "Посади семя и собери урожай.",
	cauldron = "Купи котёл.",
	brew = "Свари Healing.",
	sale = "Зелье продано. Gold уже на счёте.",
	automation = "Включи автоматизацию.",
	passive = "Улучши кристалл.",
}

function View.focus(profile, config, acknowledged)
	local step = View.displayStep(acknowledged, profile, config)
	return focusTarget[step]
end

function View.line(profile, config, acknowledged)
	local step = View.displayStep(acknowledged, profile, config)
	if View.intro(profile) then return shortLine.familiar end
	if step == "crop" then
		local session = type(config) == "table" and config.firstSession or {}
		local plant = type(profile) == "table" and profile.plants and profile.plants[session.bedId or "legacy:garden"]
		if type(plant) == "table" and (tonumber(plant.progress) or 0) < (tonumber(plant.duration) or 1) then
			return "Подожди, пока урожай созреет."
		end
	end
	return shortLine[step] or ""
end

function View.explain(message)
	local known = {
		["Not enough gold"] = "Не хватает Gold.",
		["Buy the garden first"] = "Сначала купи грядку.",
		["Starter already chosen"] = "Фамильяр уже выбран.",
		["Finish the first Healing sale first"] = "Сначала продай первое зелье Healing.",
		["Upgrade already changed"] = "Уровень уже изменился.",
		["Stale progression request"] = "Запрос устарел. Повтори действие.",
		["Build this station first"] = "Сначала построй эту станцию.",
		["Seed limit reached"] = "Больше семян купить нельзя.",
		["Invalid seed price"] = "Такое количество семян купить нельзя.",
		["Starter station already built"] = "Эта станция уже построена.",
		["Automation already unlocked"] = "Автоматизация уже включена.",
		["Essence limit reached"] = "Essence уже на пределе.",
	}
	if type(message) ~= "string" or message == "" then return "Действие отклонено." end
	return known[message] or message
end

function View.padVisible(profile, config, stationId)
	if not v2(profile) then return true end
	if not View.stationVisible(profile, config, stationId) then return false end
	local step, done = View.step(profile, config)
	if done then return stationId ~= "orders" and stationId ~= "altar" end
	if step == "garden" and stationId == "garden" then return true end
	if step == "cauldron" and stationId == "cauldron" then return true end
	if step == "passive" and stationId == "crystal" then return true end
	return false
end

function View.displayStep(acknowledged, profile, config)
	local step, done = View.step(profile, config)
	if acknowledged == "brew" and (done or step == "automation" or step == "passive") then
		return "sale", false
	end
	return step, done
end

function View.actions(profile, config, acknowledged)
	if not v2(profile) then return {} end
	if View.intro(profile) then
		return {
			{ id = "farmer", label = "Sprout Owl", action = "chooseStarter", payload = { speciesId = "farmer" } },
			{ id = "slime", label = "Green Slime", action = "chooseStarter", payload = { speciesId = "slime" } },
			{ id = "brewer", label = "Magic Cat", action = "chooseStarter", payload = { speciesId = "brewer" } },
		}
	end
	local step = View.displayStep(acknowledged, profile, config)
	local session = config.firstSession or {}
	local bed = session.bedId or "legacy:garden"
	if step == "essence" then
		return { { id = "essence", label = "Собрать Essence", action = "click", payload = {} } }
	elseif step == "garden" then
		if not View.offersStation(profile, "garden") then return {} end
		return { { id = "garden", label = "Купить грядку", action = "buyStarterStation", payload = { stationId = "garden" } } }
	elseif step == "seeds" then
		return { { id = "seeds", label = "Купить 5 семян", action = "buySeed", payload = { amount = session.openingSeeds or 5 } } }
	elseif step == "crop" then
		local plant = profile.plants and profile.plants[bed]
		if type(plant) == "table" and (tonumber(plant.progress) or 0) >= (tonumber(plant.duration) or 1) then
			return { { id = "harvest", label = "Собрать урожай", action = "harvestCrop", payload = { bedId = bed } } }
		elseif type(plant) ~= "table" then
			return { { id = "plant", label = "Посадить семя", action = "plantSeed", payload = { bedId = bed } } }
		end
	elseif step == "cauldron" then
		if not View.offersStation(profile, "cauldron") then return {} end
		return { { id = "cauldron", label = "Купить котёл", action = "buyStarterStation", payload = { stationId = "cauldron" } } }
	elseif step == "brew" then
		return { { id = "brew", label = "Сварить Healing", kind = "brew", intents = {
			{ action = "setRecipe", payload = { stationId = "cauldron", recipeId = "healing" } },
			{ action = "load", payload = { stationId = "cauldron" } },
			{ action = "brew", payload = { stationId = "cauldron" } },
		} } }
	elseif step == "sale" and acknowledged == "brew" then
		return { { id = "sale", label = "Дальше", kind = "acknowledge" } }
	elseif step == "sale" then
		return {}
	elseif step == "automation" then
		return { { id = "automation", label = "Включить автоматизацию", action = "buyAutomation", payload = { feature = "basic" } } }
	elseif step == "passive" then
		local level = profile.stations and profile.stations.crystal and profile.stations.crystal.level or 1
		return { { id = "passive", label = "Улучшить кристалл", action = "build", payload = { upgradeId = "crystal", expectedLevel = level } } }
	end
	return {}
end

function View.menus(profile)
	if type(profile) ~= "table" or type(profile.starter) ~= "table" or View.intro(profile) then return {} end
	return {
		{ id = "supplies", label = "Магазин", key = "M", gamepad = "DPadLeft" },
		{ id = "inventory", label = "Инвентарь", key = "I", gamepad = "DPadDown" },
		{ id = "familiars", label = "Фамильяры", key = "P", gamepad = "DPadRight" },
	}
end

function View.essenceDelta(before, after)
	before, after = tonumber(before), tonumber(after)
	if not before or not after or after <= before then return 0 end
	return after - before
end

function View.present(profile, config, acknowledged)
	local step, done = View.displayStep(acknowledged, profile, config)
	local list = steps(config)
	local index = 0
	for i, id in ipairs(list) do
		if id == step then index = i end
	end
	local _, presentation = guide(profile)
	local intro = View.intro(profile)
	local title = intro and "Выберите одного фамильяра" or (presentation and ("Шаг " .. tostring(presentation.step) .. "/" .. tostring(presentation.total)) or ("Шаг " .. index .. "/" .. #list))
	local text = View.line(profile, config, acknowledged)
	return {
		visible = v2(profile) and (intro or not done),
		intro = intro,
		step = step,
		index = index,
		focus = View.focus(profile, config, acknowledged),
		title = title,
		text = text,
		actions = View.actions(profile, config, acknowledged),
		menus = View.menus(profile),
	}
end

return View
