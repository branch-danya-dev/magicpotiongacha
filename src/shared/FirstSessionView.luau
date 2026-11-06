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
	if step == "garden" then
		return { { id = "garden", label = "Купить грядку", action = "buyStarterStation", payload = { stationId = "garden" } } }
	elseif step == "seeds" then
		return { { id = "seeds", label = "Купить семена", action = "buySeed", payload = { amount = session.openingSeeds or 5 } } }
	elseif step == "crop" then
		local plant = profile.plants and profile.plants[bed]
		if type(plant) == "table" and (tonumber(plant.progress) or 0) >= (tonumber(plant.duration) or 1) then
			return { { id = "harvest", label = "Собрать урожай", action = "harvestCrop", payload = { bedId = bed } } }
		elseif type(plant) ~= "table" then
			return { { id = "plant", label = "Посадить семя", action = "plantSeed", payload = { bedId = bed } } }
		end
	elseif step == "cauldron" then
		return { { id = "cauldron", label = "Купить котёл", action = "buyStarterStation", payload = { stationId = "cauldron" } } }
	elseif step == "brew" then
		return { { id = "brew", label = "Загрузить и сварить", kind = "brew" } }
	elseif step == "sale" and acknowledged == "brew" then
		return { { id = "sale", label = "Дальше", kind = "acknowledge" } }
	elseif step == "sale" then
		return {}
	elseif step == "automation" then
		return { { id = "automation", label = "Включить автоматизацию", action = "buyAutomation", payload = { feature = "basic" } } }
	elseif step == "passive" then
		local level = profile.stations and profile.stations.crystal and profile.stations.crystal.level or 1
		return { { id = "passive", label = "Улучшить кристалл", action = "buy", payload = { upgradeId = "crystal", expectedLevel = level } } }
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
	local text = intro and "Короткое знакомство: один спутник помогает в саду, добыче или варке. Повторный выбор ничего не добавит." or (presentation and presentation.text or "")
	if step == "sale" and acknowledged == "brew" then
		text = "Партия Healing уже продана сервером, Gold на счёте. Дальше можно включить автоматизацию."
	end
	return {
		visible = v2(profile) and (intro or not done),
		intro = intro,
		step = step,
		index = index,
		title = title,
		text = text,
		actions = View.actions(profile, config, acknowledged),
		menus = View.menus(profile),
	}
end

return View
