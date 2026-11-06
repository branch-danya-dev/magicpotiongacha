-- Pure data: all economy values are provisional and can be tuned without changing the engine.
local Config = {
	schemaVersion = 8,
	trading = { maxItems=6,maxCauldrons=16,prepareSeconds=120,inviteSeconds=30,negotiateSeconds=300,
		inviteCooldown=15,retentionSeconds=604800,journalShards=16,journalCapacity=128,scanPerPass=1,recoverySeconds=30 },
	maxOfflineSeconds = 7200,
	maxAdvanceSeconds = 7200,
	maxBalance = 1000000000000,
	maxCount = 1000000,
	maxBaseStat = 10000,
	maxPets = 128,
	balancedStoragePhase = 3,
	maxTimestamp = 1000000000000,
	maxJobDuration = 3600,
	sourceCapacity = 30,
	machineInputCapacity = 20,
	machineOutputCapacity = 20,
	manualHarvestCooldown = 4,
	manualClickEssence = 1, -- Historical click. Economy V2 profiles use economyV2.clickEssence.
	crystalSkillPerEssence = 5,
	gatherSpeedPerSkill = 0.04,
	brewSpeedPerSkill = 0.035,
	doubleChancePerSkill = 0.002,
	maxDoubleChance = 0.25,
	slimePeriod = 60,
	slimeChance = 0.35,
	baseHaulDuration = 4,
	pipesCost = 28,
	essenceBufferCapacity = 24,
	pipeEssencePerSecond = 2,
	questQueueCapacity = 6,
	maxHaulCapacity = 16,
	haulSkillPerSlot = 5,
	haulSpeedPerSkill = 0.025,
	tutorialSteps = { "crystal", "ingredients", "workers", "manual", "sale", "pipes", "upgrade", "automation", "orderAccepted", "orderClaimed" },
	stationOrder = { "crystal", "garden", "mine", "distillery", "cauldron", "logistics" },
	machineOrder = { "distillery", "cauldron" },
	sourceOrder = { "garden", "mine", "distillery" },
	items = {
		mandrake = { name = "Mandrake", kind = "raw", fluid = false },
		coal = { name = "Magic coal", kind = "raw", fluid = false },
		slime = { name = "Slime", kind = "raw", fluid = false },
		fire_extract = { name = "Fire extract", kind = "intermediate", fluid = true },
		healing = { name = "Healing potion", kind = "potion", fluid = false },
		rage = { name = "Rage elixir", kind = "potion", fluid = false },
	},
	stations = {
		crystal = {
			name = "Magic crystal", skill = "Farming", initialLevel = 1,
			upgradeCosts = { 0, 140, 700 }, statCaps = { 10, 25, 60 },
			passiveEssence = { 0, 1, 3 },
		},
		garden = {
			name = "Mandrake garden", skill = "Farming", initialLevel = 1,
			upgradeCosts = { 0, 100, 450 }, statCaps = { 10, 25, 60 },
			outputItem = "mandrake", growDuration = 8,
		},
		mine = {
			name = "Coal mine", skill = "Farming", initialLevel = 0,
			upgradeCosts = { 60, 150, 600 }, statCaps = { 10, 25, 60 },
			outputItem = "coal", growDuration = 10,
		},
		distillery = {
			name = "Distillery", skill = "Brewing", initialLevel = 0,
			upgradeCosts = { 100, 250, 900 }, statCaps = { 10, 25, 60 },
			defaultRecipe = "fire_extract",
		},
		cauldron = {
			name = "Cauldron", skill = "Brewing", initialLevel = 1,
			upgradeCosts = { 0, 180, 750 }, statCaps = { 15, 35, 75 },
			defaultRecipe = "healing",
		},
		logistics = {
			name = "Hauling station", skill = "Hauling", initialLevel = 1,
			upgradeCosts = { 0, 120, 500 }, statCaps = { 10, 25, 60 },
		},
	},
	warehouse = {
		upgradeCosts = { 180, 650, 1800 },
		rawCapacity = { 50, 100, 200, 400 },
		intermediateCapacity = { 20, 40, 80, 160 },
		questCapacity = { 100, 150, 250, 400 },
	},
	recipes = {
		healing = {
			name = "Healing potion", inputs = { mandrake = 2 }, essenceCost = 3,
			duration = 6, output = "healing", quantity = 1, goldValue = 14,
			station = "cauldron", requiredLevel = 1, kind = "potion",
		},
		fire_extract = {
			name = "Fire extract", inputs = { coal = 2 }, essenceCost = 5,
			duration = 8, output = "fire_extract", quantity = 1, goldValue = 0,
			station = "distillery", requiredLevel = 1, kind = "intermediate",
		},
		rage = {
			name = "Rage elixir", inputs = { mandrake = 2, fire_extract = 1, slime = 1 },
			essenceCost = 8, duration = 12, output = "rage", quantity = 1, goldValue = 70,
			station = "cauldron", requiredLevel = 2, kind = "potion",
		},
	},
	orders = {
		healing_small = {
			name = "Healer's request", recipeId = "healing", itemId = "healing",
			count = 5, rewardGold = 110, duration = 600,
		},
		healing_large = {
			name = "Clinic supplies", recipeId = "healing", itemId = "healing",
			count = 12, rewardGold = 280, duration = 1200,
		},
		rage_small = {
			name = "Knight's request", recipeId = "rage", itemId = "rage",
			count = 4, rewardGold = 420, duration = 1200,
		},
	},
	collection = { policyTTL = 60, policyTimeout = 4, cooldownSeconds = 1, pageSize = 6, fuseCount = 5, fuseBonus = 5 },
	rarityOrder = { Legacy = 0, Common = 1, Rare = 2, Legendary = 3, Secret = 4 },
	petSpecies = {
		farmer = { name = "Sprout owl", rarity = "Common", evolution = 0, fuseTo = "bloom_owl", ranges = { Farming = {8,16}, Hauling = {1,3}, Brewing = {1,3} } },
		slime = { name = "Green slime", rarity = "Common", evolution = 0, fuseTo = "golden_slime", slimeProducer = true, ranges = { Farming = {1,3}, Hauling = {7,13}, Brewing = {1,2} } },
		brewer = { name = "Magic cat", rarity = "Common", evolution = 0, fuseTo = "moon_cat", ranges = { Farming = {2,4}, Hauling = {1,3}, Brewing = {18,28} } },
		bloom_owl = { name = "Bloom owl", rarity = "Rare", evolution = 1, fuseTo = "ancient_owl", ranges = { Farming = {14,26}, Hauling = {3,8}, Brewing = {3,8} } },
		golden_slime = { name = "Golden slime", rarity = "Rare", evolution = 1, fuseTo = "prism_slime", slimeProducer = true, ranges = { Farming = {3,8}, Hauling = {14,26}, Brewing = {2,7} } },
		moon_cat = { name = "Moon cat", rarity = "Rare", evolution = 1, fuseTo = "void_cat", ranges = { Farming = {4,9}, Hauling = {3,8}, Brewing = {28,40} } },
		ancient_owl = { name = "Ancient owl", rarity = "Legendary", evolution = 2, ranges = { Farming = {28,60}, Hauling = {8,16}, Brewing = {8,16} } },
		prism_slime = { name = "Prism slime", rarity = "Legendary", evolution = 2, slimeProducer = true, ranges = { Farming = {8,16}, Hauling = {28,60}, Brewing = {7,14} } },
		void_cat = { name = "Void cat", rarity = "Legendary", evolution = 2, ranges = { Farming = {9,18}, Hauling = {8,16}, Brewing = {42,75} } },
		aether_sprite = { name = "Aether sprite", rarity = "Secret", evolution = 0, ranges = { Farming = {80,100}, Hauling = {80,100}, Brewing = {80,100} } },
	},
	summonPools = {
		forest = { name = "Forest familiars", essenceCost = 50, totalWeight = 100000, counts = { 1, 5 },
			outcomes = {
				{ species = "farmer", weight = 24000 }, { species = "slime", weight = 23000 }, { species = "brewer", weight = 23000 },
				{ species = "bloom_owl", weight = 9000 }, { species = "golden_slime", weight = 8000 }, { species = "moon_cat", weight = 8000 },
				{ species = "ancient_owl", weight = 1650 }, { species = "prism_slime", weight = 1650 }, { species = "void_cat", weight = 1650 },
				{ species = "aether_sprite", weight = 50 },
			} },
	},
	familiarShop = {
		farmer = { species = "farmer", currency = "gold", cost = 120, stats = { Farming = 12, Hauling = 2, Brewing = 2 } },
		slime = { species = "slime", currency = "gold", cost = 120, stats = { Farming = 2, Hauling = 10, Brewing = 1 } },
		brewer = { species = "brewer", currency = "gold", cost = 180, stats = { Farming = 3, Hauling = 2, Brewing = 25 } },
		bloom_owl = { species = "bloom_owl", currency = "gold", cost = 700, stats = { Farming = 22, Hauling = 5, Brewing = 5 } },
		golden_slime = { species = "golden_slime", currency = "gold", cost = 700, stats = { Farming = 5, Hauling = 22, Brewing = 4 } },
		moon_cat = { species = "moon_cat", currency = "gold", cost = 1000, stats = { Farming = 6, Hauling = 5, Brewing = 36 } },
		ancient_owl = { species = "ancient_owl", currency = "gold", cost = 3500, stats = { Farming = 50, Hauling = 12, Brewing = 12 } },
		prism_slime = { species = "prism_slime", currency = "gold", cost = 3500, stats = { Farming = 12, Hauling = 50, Brewing = 10 } },
		void_cat = { species = "void_cat", currency = "gold", cost = 5000, stats = { Farming = 14, Hauling = 12, Brewing = 65 } },
		aether_sprite = { species = "aether_sprite", currency = "essence", cost = 12000, stats = { Farming = 90, Hauling = 90, Brewing = 90 } },
	},
	hires = {
		farmer = { cost = 120, name = "Sprout owl", stats = { Farming = 12, Hauling = 2, Brewing = 2 } },
		slime = { cost = 120, name = "Green slime", stats = { Farming = 2, Hauling = 10, Brewing = 1 } },
		brewer = { cost = 180, name = "Magic cat", stats = { Farming = 3, Hauling = 2, Brewing = 25 } },
	},
	starterPets = {
		{ id = "starter_farmer", species = "farmer", name = "Sprout owl", stats = { Farming = 12, Hauling = 2, Brewing = 2 } },
		{ id = "starter_slime", species = "slime", name = "Green slime", stats = { Farming = 2, Hauling = 10, Brewing = 1 } },
		{ id = "starter_brewer", species = "brewer", name = "Magic cat", stats = { Farming = 3, Hauling = 2, Brewing = 25 } },
	},
	-- Economy V2 v0.1, the prototype balance specified for the first cycle.
	-- Historical recipes, station prices and accepted contracts stay on the tables above.
	firstSession = {
		ownerApproved = true,
		starterGold = 1000,
		seedItem = "mandrake",
		seedCost = 20,
		seedYield = 2,
		growSeconds = 8,
		bedId = "legacy:garden",
		bedCost = 200,
		cauldronCost = 300,
		automationCost = 500,
		restockTarget = 5,
		openingSeeds = 5,
		tutorialSteps = { "familiar", "essence", "garden", "seeds", "crop", "cauldron", "brew", "sale", "automation", "passive" },
	},
	economyV2 = {
		clickEssence = 5,
		healing = { essenceCost = 15, goldValue = 250, mandrake = 2 },
		crystal = {
			upgradeCosts = { 0, 900, 4500, 20000, 80000 },
			passiveEssence = { 0, 2, 6, 18, 48 },
		},
		garden = {
			upgradeCosts = { 0, 5000, 24000, 100000 },
			yield = { 2, 6, 12, 18 },
			growSeconds = { 8, 8, 5, 3 },
		},
		cauldron = {
			upgradeCosts = { 0, 6500, 32000, 140000 },
			batch = { 1, 3, 6, 10 },
			brewSeconds = { 6, 8, 5, 3 },
		},
	},
}

-- Fixed slot instances. Existing IDs and prices are deliberately unchanged.
local additions = {
	garden2 = { name="Second Mandrake garden", archetype="garden", phase=2, skill="Farming", initialLevel=0,
		upgradeCosts={160,240,600}, statCaps={10,25,60}, outputItem="mandrake", growDuration=8 },
	cauldron2 = { name="Second cauldron", archetype="cauldron", phase=2, skill="Brewing", initialLevel=0,
		upgradeCosts={220,350,1000}, statCaps={15,35,75}, defaultRecipe="healing" },
	distillery2 = { name="Second distillery", archetype="distillery", phase=2, skill="Brewing", initialLevel=0,
		upgradeCosts={200,350,1000}, statCaps={10,25,60}, defaultRecipe="fire_extract" },
	mushrooms = { name="Magic mushrooms", archetype="garden", phase=3, skill="Farming", initialLevel=0,
		upgradeCosts={300,450,1000}, statCaps={10,25,60}, outputItem="mushroom", growDuration=10 },
	berries = { name="Fire berries", archetype="garden", phase=3, skill="Farming", initialLevel=0,
		upgradeCosts={350,500,1100}, statCaps={10,25,60}, outputItem="berry", growDuration=12 },
	press = { name="Spore press", archetype="press", phase=3, skill="Brewing", initialLevel=0,
		upgradeCosts={450,650,1400}, statCaps={10,25,60}, defaultRecipe="spore_paste" },
	centrifuge = { name="Aether centrifuge", archetype="centrifuge", phase=4, skill="Brewing", initialLevel=0,
		upgradeCosts={1200,1800,3000}, statCaps={15,35,75}, defaultRecipe="aether_serum" },
}
for id, def in pairs(Config.stations) do def.archetype, def.phase = id, 1 end
for _, id in ipairs({"garden2","cauldron2","distillery2","mushrooms","berries","press","centrifuge"}) do
	local def=additions[id]; Config.stations[id]=def; table.insert(Config.stationOrder,id)
	def.tierPhases={def.phase,math.max(3,def.phase),4}
	if def.defaultRecipe then table.insert(Config.machineOrder,id) end
	if def.outputItem or def.defaultRecipe then table.insert(Config.sourceOrder,id) end
end
Config.routes = {
	{kind="input",slot="distillery"},{kind="input",slot="cauldron"},
	{kind="output",slot="garden"},{kind="output",slot="mine"},{kind="output",slot="distillery"},
	{kind="questQueue",slot="distillery"},{kind="questQueue",slot="cauldron"},
}
for _,id in ipairs({"garden2","cauldron2","distillery2","mushrooms","berries","press","centrifuge"}) do
	if additions[id].defaultRecipe then table.insert(Config.routes,{kind="input",slot=id}) end
	table.insert(Config.routes,{kind="output",slot=id})
	if additions[id].defaultRecipe then table.insert(Config.routes,{kind="questQueue",slot=id}) end
end
local offsets={crystal={0,3,-2},garden={-20,1.5,0},mine={-20,1.5,-20},distillery={15,2,-18},cauldron={20,2,0},logistics={0,2,-27},
	garden2={-32,1.5,14},cauldron2={20,2,16},distillery2={32,2,-18},mushrooms={-32,1.5,-10},berries={-32,1.5,-32},press={8,2,16},centrifuge={32,2,4}}
for id,offset in pairs(offsets) do
	Config.stations[id].offset=offset
	Config.stations[id].waypoints={input={offset[1]-3,offset[2],offset[3]},output={offset[1]+3,offset[2],offset[3]}}
end
Config.items.mushroom={name="Magic mushroom",kind="raw",fluid=false}
Config.items.berry={name="Fire berry",kind="raw",fluid=false}
Config.items.spore_paste={name="Spore paste",kind="intermediate",fluid=false}
Config.items.berry_essence={name="Berry essence",kind="intermediate",fluid=true}
Config.items.aether_serum={name="Aether serum",kind="intermediate",fluid=true}
for _,id in ipairs({"focus","flare","ascension"}) do Config.items[id]={name=id,kind="potion",fluid=false} end
Config.recipes.spore_paste={name="Spore paste",inputs={mushroom=2},essenceCost=4,duration=8,output="spore_paste",quantity=1,goldValue=0,station="press",requiredLevel=1,phase=3,kind="intermediate"}
Config.recipes.berry_essence={name="Berry essence",inputs={berry=2},essenceCost=6,duration=10,output="berry_essence",quantity=1,goldValue=0,station="distillery",requiredLevel=1,phase=3,kind="intermediate"}
Config.recipes.focus={name="Focus potion",inputs={spore_paste=1,mandrake=1},essenceCost=6,duration=10,output="focus",quantity=1,goldValue=95,station="cauldron",requiredLevel=1,phase=3,kind="potion"}
Config.recipes.flare={name="Flare potion",inputs={berry_essence=1,coal=1},essenceCost=8,duration=12,output="flare",quantity=1,goldValue=130,station="cauldron",requiredLevel=2,phase=3,kind="potion"}
Config.recipes.aether_serum={name="Aether serum",inputs={spore_paste=1,berry_essence=1},essenceCost=12,duration=14,output="aether_serum",quantity=1,goldValue=0,station="centrifuge",requiredLevel=1,phase=4,kind="intermediate"}
Config.recipes.ascension={name="Ascension elixir",inputs={aether_serum=1,fire_extract=1,mandrake=1},essenceCost=20,duration=20,output="ascension",quantity=1,goldValue=360,station="cauldron",requiredLevel=3,phase=4,kind="potion"}
Config.phases={
	{ name="Лесная поляна",cost=0,recipes={},stations={} },
	{ name="Хижина ведьмы",cost=400,recipes={"healing"},stations={crystal=2},pipes=true },
	{ name="Каменная лаборатория",cost=1400,recipes={"rage"},stations={cauldron2=1,distillery=1} },
	{ name="Кибер-алхимический комплекс",cost=4500,recipes={"focus","flare"},stations={press=1,distillery2=1},warehouse=1 },
}
Config.orders.focus_small={name="Scholar's focus",recipeId="focus",itemId="focus",count=4,rewardGold=500,duration=1800,phase=3}
Config.orders.healing_quick={name="Forest first aid",recipeId="healing",itemId="healing",count=3,rewardGold=60,duration=480}
Config.orders.healing_small.priority=30
Config.orders.healing_large.priority=20
Config.orders.healing_quick.priority=10
-- New early contracts. The original healing orders stay so an accepted receipt still matches its stored reward.
Config.orders.healing_quick_v2={name="Forest first aid",recipeId="healing",itemId="healing",count=3,rewardGold=1125,duration=480,priority=12,economy="v2"}
Config.orders.healing_small_v2={name="Healer's request",recipeId="healing",itemId="healing",count=5,rewardGold=2000,duration=600,priority=32,economy="v2"}
Config.orders.healing_large_v2={name="Clinic supplies",recipeId="healing",itemId="healing",count=12,rewardGold=4500,duration=1200,priority=22,economy="v2"}
Config.orders.flare_small={name="Lantern supply",recipeId="flare",itemId="flare",count=4,rewardGold=680,duration=1800,phase=3}
Config.orders.ascension_small={name="Final experiment",recipeId="ascension",itemId="ascension",count=3,rewardGold=1500,duration=3600,phase=4}
Config.cauldronTypes={resonant={name="Resonant copper cauldron",bonus=0.05}}
Config.epochRules={
	[0]={name="Классическая алхимия",color={94,153,100},cost=1,sale=1,duration=1,finalRecipe="ascension",
		phaseRecipes={[2]={"healing"},[3]={"rage"},[4]={"focus","flare"}},resourceNames={}},
	[1]={name="Стимпанк",color={187,139,66},cost=1.10,sale=1.20,duration=0.95,finalRecipe="steam_ascension",
		phaseRecipes={[2]={"healing"},[3]={"steam_catalyst"},[4]={"gear_oil","steam_tonic"}},resourceNames={coal="Coke",berry="Oil berry",mushroom="Copper spore"}},
	[2]={name="Кибер-алхимия Пустоты",color={126,89,205},cost=1.20,sale=1.40,duration=0.90,finalRecipe="void_ascension",
		phaseRecipes={[2]={"healing"},[3]={"void_plasma"},[4]={"antimatter","void_tonic"}},resourceNames={coal="Dark carbon",berry="Void berry",mushroom="Quantum spore"}},
}
local epochRecipes={
	steam_catalyst={name="Steam Catalyst",epoch=1,inputs={coal=2},essenceCost=5,duration=7,station="distillery",requiredLevel=1,phase=2,kind="intermediate",fluid=true},
	gear_oil={name="Gear Oil",epoch=1,inputs={berry_essence=1,mushroom=1},essenceCost=5,duration=9,station="press",requiredLevel=1,phase=3,kind="intermediate",fluid=false},
	steam_tonic={name="Steam Tonic",epoch=1,inputs={steam_catalyst=1,spore_paste=1},essenceCost=8,duration=11,station="cauldron",requiredLevel=2,phase=3,kind="potion",goldValue=180},
	pressure_essence={name="Pressure Essence",epoch=1,inputs={steam_catalyst=1,gear_oil=1},essenceCost=12,duration=13,station="centrifuge",requiredLevel=1,phase=4,kind="intermediate",fluid=true},
	steam_ascension={name="Steam Ascension",epoch=1,inputs={pressure_essence=1,coal=1,mandrake=2},essenceCost=20,duration=18,station="cauldron",requiredLevel=3,phase=4,kind="potion",goldValue=480},
	void_plasma={name="Void Plasma",epoch=2,inputs={coal=1,mandrake=1},essenceCost=6,duration=8,station="distillery",requiredLevel=1,phase=2,kind="intermediate",fluid=true},
	antimatter={name="Antimatter",epoch=2,inputs={coal=2,berry_essence=1},essenceCost=8,duration=10,station="press",requiredLevel=1,phase=3,kind="intermediate",fluid=false},
	void_tonic={name="Void Tonic",epoch=2,inputs={void_plasma=1,spore_paste=1},essenceCost=10,duration=13,station="cauldron",requiredLevel=2,phase=3,kind="potion",goldValue=220},
	chrono_serum={name="Chrono Serum",epoch=2,inputs={antimatter=1,void_plasma=1},essenceCost=14,duration=16,station="centrifuge",requiredLevel=1,phase=4,kind="intermediate",fluid=true},
	void_ascension={name="Void Ascension",epoch=2,inputs={chrono_serum=1,berry_essence=1,mandrake=1},essenceCost=22,duration=22,station="cauldron",requiredLevel=3,phase=4,kind="potion",goldValue=600},
}
for id,recipe in pairs(epochRecipes) do
	recipe.output=id; recipe.quantity=1; recipe.goldValue=recipe.goldValue or 0; Config.recipes[id]=recipe
	Config.items[id]={name=recipe.name,kind=recipe.kind,fluid=recipe.fluid==true,epoch=recipe.epoch}
	if recipe.kind=="potion" then Config.orders[id.."_small"]={name=recipe.name.." order",recipeId=id,itemId=id,count=3,rewardGold=recipe.goldValue*4,duration=2400,phase=recipe.phase,epoch=recipe.epoch} end
end
Config.longTerm={
	perkOrder={"industry","essence","title"},perks={
		industry={name="Производительность",cost=1,max=3,description="+5% скорости работы за уровень; пределы статов сохраняются"},
		essence={name="Энергия времени",cost=1,max=3,description="+1 Essence за клик и +1/с у улучшенного пассивного кристалла за уровень"},
		title={name="Титул: Хрононавт",cost=1,max=1,description="Постоянный титул"},
	},
	choiceOrder={"bloom_owl","golden_slime","moon_cat"},choiceCost=1,
	daily={essence={name="Собери Essence вручную",targets={30,40,50},reward={gold=40}},brew={name="Заверши ручные варки зелий онлайн",targets={3,4,5},reward={gold=60}},orders={name="Выполни заказ NPC",targets={1,1,1},reward={gold=90}}},
	dailyOrder={"essence","brew","orders"},
	calendar={{gold=30},{essence=25},{gold=60},{essence=50},{gold=90},{essence=75},{gold=140}},
	calendarPet="moon_cat",
}
-- Released grant definitions are immutable archives: close offers, never reuse IDs or nerf owned instances.
Config.petSpecies.ghost_wolf={name="Призрачный Волк",rarity="Rare",evolution=1,fuseTo="ghost_alpha",visual="ghost",
	ranges={Farming={10,10},Hauling={28,28},Brewing={8,8}}}
Config.petSpecies.ghost_alpha={name="Призрачный Вожак",rarity="Legendary",evolution=2,visual="ghost",
	ranges={Farming={15,15},Hauling={34,34},Brewing={13,13}}}
Config.cauldronTypes.spectral={name="Призрачный котёл",bonus=0,brewSpeedBonus=0.05,visual="spectral"}
Config.events={spectral_2026={name="Призрачная коллекция",startAtUtc=1793836800,endAtUtc=1795046400}}
Config.monetization={maxReceipts=4096,maxQueued=64,offerOrder={"ghost_wolf_v1","spectral_cauldron_v1","aurora_theme_v1"},offers={
	ghost_wolf_v1={name="Призрачный Волк",version=1,kind="pet",species="ghost_wolf",stats={Farming=10,Hauling=28,Brewing=8},
		eventId="spectral_2026",goldCost=1800,platformKind="product",enabled=true,supportedEpochs={true,true,true},effect="Hauling 28, ограничен уровнем логистики; один перевозчик",visual="ghost"},
	spectral_cauldron_v1={name="Призрачный котёл",version=1,kind="cauldron",cauldronType="spectral",bonus=0,brewSpeedBonus=0.05,
		eventId="spectral_2026",goldCost=2600,platformKind="product",enabled=true,supportedEpochs={true,true,true},effect="+5% скорости варки; без бонуса случайного выпуска; построенный слот и все ингредиенты обязательны",visual="spectral"},
	aurora_theme_v1={name="Сияние Авроры",version=1,kind="cosmetic",entitlement="aurora_theme",eventId="permanent",goldCost=4500,
		platformKind="pass",enabled=true,supportedEpochs={true,true,true},effect="Только свечение лаборатории; без влияния на производство",visual="aurora"},
}}
return Config
