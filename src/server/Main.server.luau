--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("PotionTycoon"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Factory = require(Shared.Factory).new(Config)
local Protocol = require(Shared.Protocol).new()
local CollectionModule = require(Shared.Collection)
local Collection = CollectionModule.new(Config)
local ProgressionModule = require(Shared.Progression)
local Progression = ProgressionModule.new(Config)
local LongTermModule = require(Shared.LongTerm)
local LongTerm = LongTermModule.new(Config)
local MonetizationModule = require(Shared.Monetization)
local Monetization = MonetizationModule.new(Config)
local PurchaseRuntime = require(script.Parent.PurchaseRuntime)
local Policy = require(Shared.Policy)
local PolicyService = game:GetService("PolicyService")
local summonRandom = Random.new() -- Separate server-only RNG; never seeded from production/profile/client.
local ProfileStore = require(script.Parent.ProfileStore)
local Settings = require(script.Parent.ServerSettings)
local World = require(script.Parent.World)
local TradeRuntime = require(script.Parent.TradeRuntime)
local TradeSession = require(Shared.TradeSession)

local folder = Instance.new("Folder")
folder.Name, folder.Parent = "Remotes", ReplicatedStorage.PotionTycoon
local function remote(name)
	local value = Instance.new("RemoteEvent")
	value.Name, value.Parent = name, folder
	return value
end
local Action, State, Notice, Focus, Ready = remote("Action"), remote("State"), remote("Notice"), remote("Focus"), remote("Ready")
local TradeState = remote("TradeState")
local PurchasePrompt = remote("PurchasePrompt")
local memoryMode = RunService:IsStudio() and Settings.UseMemoryInStudio

local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = copy(child) end
	return result
end

local dataStore
if memoryMode then
	-- Explicit Studio mode only. A real backend failure NEVER selects this backend.
	local records = {}
	dataStore = { UpdateAsync = function(_, key, transform)
		local updated = transform(copy(records[key]))
		if updated ~= nil then records[key] = copy(updated) end
		return copy(updated)
	end }
	function dataStore:RemoveAsync(key) records[key]=nil end
else
	dataStore = DataStoreService:GetDataStore(Settings.DataStoreName)
end

local store = ProfileStore.new({
	dataStore = dataStore,
	now = os.time,
	owner = game.JobId .. ":" .. HttpService:GenerateGUID(false),
	validate = Factory.validate,
	migrate = Factory.migrate,
	sleep = task.wait,
	leaseSeconds = Settings.LeaseSeconds,
})
local sessions, offlineReports, readyAt, noticesAt = {}, {}, {}, {}
local closing = false
local world
local trade
local purchases
local policy = Policy.new({ now = os.time, ttl = Config.collection.policyTTL, lookup = function(player)
	local finished, ok, result, abandoned = false, false, nil, false
	task.spawn(function()
		local success, value = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)
		if not abandoned then ok, result, finished = success, value, true end
	end)
	local deadline = os.clock() + Config.collection.policyTimeout
	while not finished and os.clock() < deadline do task.wait(0.05) end
	abandoned = true
	if not finished or not ok then error("policy_unavailable") end
	return result
end })

local function active(player)
	local session = sessions[player.UserId]
	return session and session.player == player and session.phase == "active"
end

local function notice(player, text, code)
	if player.Parent ~= Players then return end
	local now = os.clock()
	if now - (noticesAt[player.UserId] or -10) < 0.2 then return end
	noticesAt[player.UserId] = now
	Notice:FireClient(player, { text = text, code = code })
end

local function snapshot(player)
	local profile = store:get(player.UserId)
	if not active(player) or not profile or player.Parent ~= Players then return end
	if trade then trade.send(player) end
	if profile.trade.pending then return end -- Never expose a partially applied inventory.
	local builds, recipes = {}, {}
	for _, id in ipairs(Config.stationOrder) do
		builds[id] = Progression.buildState(profile, id)
		if Config.stations[id].defaultRecipe then
			recipes[id] = {}
			for recipeId, recipe in pairs(Config.recipes) do
				if recipe.station == Config.stations[id].archetype then recipes[id][recipeId] = Factory.recipeState(profile, id, recipeId) end
			end
		end
	end
	builds.warehouse, builds.pipes = Progression.buildState(profile,"warehouse"), Progression.buildState(profile,"pipes")
	local longTerm=LongTerm.state(profile,os.time())
	if trade.activeTrade(player.UserId) then longTerm.available=false; table.insert(longTerm.reasons,"Заверши активный обмен") end
	local orderAvailability = {}
	for id in pairs(Config.orders) do
		local available, reason = Factory.orderEligible(profile,id)
		orderAvailability[id] = { available=available, reason=reason or "" }
	end
	-- Explicit allowlist: no PRNG state, receipts, session leases or future private metadata.
	State:FireClient(player, {
		gold = profile.gold, essence = profile.essence,
		pets = copy(profile.pets), stations = copy(profile.stations),
		inventory = copy(profile.inventory), questStock = copy(profile.questStock),
		order = copy(profile.order), rebirths = profile.rebirths,
		longTerm=longTerm,
		shop=purchases.decorate(profile,Monetization.state(profile,os.time())),
		discoveredRecipes = copy(profile.discoveredRecipes),
		warehouseLevel = profile.warehouseLevel, pipes = profile.pipes,
		production = Factory.productionState(profile), tutorial = Factory.tutorialState(profile),
		orderProgress = Factory.orderState(profile), serverTime = profile.lastSimulatedAt,
		storage = Factory.storageState(profile),
		collection = { sequence = profile.collection.sequence, lastResult = profile.collection.last and copy(profile.collection.last.result) },
		progression = { sequence = profile.progression.sequence, lastResult = profile.progression.last and copy(profile.progression.last.result) },
		phase = Progression.phaseState(profile), builds = builds, recipes = recipes, orderOffers = Factory.orderOffers(profile), orderAvailability=orderAvailability, cauldrons = copy(profile.cauldrons),
		collectionPolicy = copy(policy.peek(player)), summonDetails = Collection.details("forest"), familiarShop = copy(Config.familiarShop),
		fusePreview = copy(sessions[player.UserId].fusePreview),
		offlineReport = offlineReports[player.UserId],
		writable = store:isWritable(player.UserId) and not sessions[player.UserId].collectionBusy and not (trade and trade.busy(player.UserId)),
		mode = memoryMode and "STUDIO_MEMORY" or "DATASTORE",
		starter = { claimed = profile.starter.claimed, legacyGrant = profile.starter.legacyGrant, choice = profile.starter.choice },
		seeds = copy(profile.seeds), plants = copy(profile.plants),
		crop = Factory.gardenState(profile),
		automation = copy(profile.automation or { replant = false, harvest = false, supply = false, brew = false, restock = false }),
		firstSession = {
			ownerApproved = Config.firstSession.ownerApproved, starterGold = Config.firstSession.starterGold,
			seedCost = Config.firstSession.seedCost, seedItem = Config.firstSession.seedItem,
			seedYield = Config.firstSession.seedYield, openingSeeds = Config.firstSession.openingSeeds,
			growSeconds = Config.firstSession.growSeconds, bedId = Config.firstSession.bedId,
			bedCost = Config.firstSession.bedCost, cauldronCost = Config.firstSession.cauldronCost,
			automationCost = Config.firstSession.automationCost, restockTarget = Config.firstSession.restockTarget,
			clickEssence = Config.economyV2.clickEssence,
		},
	})
end

local function handleDurable(player, action, payload)
	local session = sessions[player.UserId]
	session.collectionBusy = true
	snapshot(player)
	local ok, committed, result = pcall(function()
		local access = action == "summon" and policy.get(player) or policy.peek(player)
		-- Policy and a queued save can yield. Recheck identity, position and session.
		if sessions[player.UserId] ~= session or not active(player) or closing or not store:isWritable(player.UserId)
			or not world:inRange(player, action, payload, Settings.InteractDistance) then return false, "Session or position changed" end
		return store:transact(player.UserId, function(candidate)
			if sessions[player.UserId] ~= session or not active(player) or closing
				or not world:inRange(player, action, payload, Settings.InteractDistance) then return false, "Session or position changed" end
			local now = os.time()
			if MonetizationModule.isAction(action) then
				return Monetization.apply(candidate,action,payload,Factory,{now=now,tradeActive=trade.activeTrade(player.UserId),
					guard=function() return active(player) and not closing and not trade.activeTrade(player.UserId) and world:inRange(player,action,payload,Settings.InteractDistance) end})
			end
			if LongTermModule.isAction(action) then
				return LongTerm.apply(candidate,action,payload,Factory,{now=now,tradeActive=trade.activeTrade(player.UserId),
					guard=function() return active(player) and not closing and not trade.activeTrade(player.UserId) and world:inRange(player,action,payload,Settings.InteractDistance) end})
			end
			local report = Factory.advance(candidate, now, false)
			assert(report.ok, report.error)
			if ProgressionModule.isAction(action) then return Progression.apply(candidate,action,payload,Factory,now) end
			return Collection.apply(candidate, action, payload, { now = now, policy = access, preview = session.fusePreview,
				nextInteger = function(lo, hi) return summonRandom:NextInteger(lo, hi) end })
		end)
	end)
	session.collectionBusy = false
	if sessions[player.UserId] ~= session or not active(player) then return end
	if not ok or (not committed and not store:isWritable(player.UserId)) then
		store:invalidate(player.UserId)
		session.quarantined, session.phase = true, "blocked"
		player:Kick("Не удалось подтвердить сохранение операции. Войдите снова: сохранённая операция будет восстановлена без повторной выдачи.")
		return
	end
	if committed then
		if action == "fuse" then session.fusePreview = nil end
		if action == "rebirth" then session.fusePreview=nil; offlineReports[player.UserId]=nil end
		notice(player, result.message, "collection_committed")
		world:update(player, store:get(player.UserId))
	else notice(player, tostring(result), "collection_rejected") end
	snapshot(player)
end

local function handleAction(player, action, payload)
	local allowed, reason = Protocol:check(player.UserId, action, payload, os.clock())
	if not allowed then
		if reason ~= "rate_limited" then notice(player, "Запрос отклонён: " .. tostring(reason), "rejected") end
		return
	end
	-- Legacy pure-domain buy remains for regression/migration fixtures only.
	if action == "buy" then notice(player, "Обнови клиент: покупки требуют подтверждённого сохранения.", "obsolete_intent"); return end
	if TradeSession.isAction(action) then
		local ok,accepted,message=pcall(trade.handle,player,action,payload)
		if not ok then notice(player,"Обмен ожидает безопасного восстановления.","trade_pending")
		elseif not accepted then notice(player,tostring(message),"trade_rejected") end
		return
	end
	if closing or not active(player) or not store:isWritable(player.UserId) then
		notice(player, "Профиль загружается или ожидает безопасного сохранения.", "profile_locked")
		return
	end
	if sessions[player.UserId].collectionBusy then notice(player, "Коллекция сохраняется. Дождись результата.", "collection_busy"); return end
	if trade.busy(player.UserId) then notice(player,"Обмен сохраняется. Дождись результата.","trade_pending"); return end
	if not world:inRange(player, action, payload, Settings.InteractDistance) then
		notice(player, "Подойди к нужному объекту на своём участке.", "out_of_range")
		return
	end
	if CollectionModule.isAction(action) or ProgressionModule.isAction(action) or LongTermModule.isAction(action) or MonetizationModule.isAction(action) then handleDurable(player, action, payload); return end
	if action=="requestPurchase" then
		local _,message=purchases.prompt(player,payload.offerId); notice(player,tostring(message),"purchase_prompt"); return
	end
	if action=="refreshPurchases" then
		local session=sessions[player.UserId]; if session.purchaseRefreshing then return end
		session.purchaseRefreshing=true; local ok=pcall(purchases.refresh,player); session.purchaseRefreshing=false
		if not ok then notice(player,"Права пока не подтверждены; повтори позже.","purchase_pending") end
		snapshot(player); return
	end
	if action == "refreshPolicy" then
		local session = sessions[player.UserId]
		if session.policyRefreshing then return end
		session.policyRefreshing = true
		policy.get(player)
		session.policyRefreshing = false
		if sessions[player.UserId] == session and active(player) then snapshot(player) end
		return
	end
	local profile = store:get(player.UserId)
	if action == "previewFuse" then
		local preview, reason = Collection.preview(profile, payload.petIds)
		if preview then
			preview.token, preview.expiresAt = HttpService:GenerateGUID(false), os.time() + Config.collection.policyTTL
			sessions[player.UserId].fusePreview = preview
		else
			sessions[player.UserId].fusePreview = nil
			notice(player, reason, "fuse_preview_rejected")
		end
		snapshot(player)
		return
	end
	local ok, success, message = pcall(function()
		local result = Factory.advance(profile, os.time(), false)
		assert(result.ok ~= false, result.error or "simulation_failed")
		local success, message = Factory.act(profile, action, payload, os.time())
		local valid, reason = Factory.validate(profile)
		assert(valid, reason or "invalid_action_result")
		return success, message
	end)
	if not ok then
		store:invalidate(player.UserId)
		sessions[player.UserId].quarantined = true
		sessions[player.UserId].phase = "blocked"
		warn("Factory action failed; profile disabled", player.UserId, success)
		player:Kick("Внутренняя ошибка фабрики. Профиль остановлен, попробуйте войти снова.")
		return
	end
	if not success then notice(player, tostring(message), "action_failed")
	elseif action ~= "click" then
		notice(player, tostring(message or "Готово"), "ok")
		snapshot(player)
		world:update(player, profile)
	end
end

local function purchaseTransaction(userId,transform)
	local session=sessions[userId]; local player=session and session.player
	if not player or closing or not active(player) or session.collectionBusy or trade.activeTrade(userId) or not store:isWritable(userId) then return false,"Profile unavailable; paid right waits" end
	session.collectionBusy=true
	local ok,committed,result=pcall(function()
		return store:transact(userId,function(candidate)
			local function guard() return sessions[userId]==session and active(player) and not closing and not trade.activeTrade(userId) end
			if not guard() then return false,"Player session changed" end
			return transform(candidate,{now=os.time(),tradeActive=trade.activeTrade(userId),guard=guard})
		end)
	end)
	session.collectionBusy=false
	if not ok or (not committed and not store:isWritable(userId)) then
		store:invalidate(userId); session.quarantined=true
		if active(player) then player:Kick("Покупка ожидает подтверждения сохранения. Повтори вход; оплаченные права не выдаются повторно.") end
		return false,"Profile purchase outcome unconfirmed"
	end
	if committed and active(player) then world:update(player,store:get(userId)); snapshot(player) end
	return committed,result
end

world = World.new(Config, Settings.PlotCount, {
	production = Factory.productionState,
	buildState = Progression.buildState,
	phaseState = Progression.phaseState,
	orderProgress = Factory.orderState,
	action = handleAction,
	focus = function(player, stationId)
		if active(player) then Focus:FireClient(player, stationId) end
	end,
}, Settings.EnvironmentArtEnabled)
trade = TradeRuntime.new({config=Config,settings=Settings,store=store,backend=dataStore,engine=Factory,policy=policy,
	memoryMode=memoryMode,remote=TradeState,active=active,closing=function() return closing end,
	inBazaar=function(player) return world:inBazaar(player) end,
	valueBusy=function(player) return sessions[player.UserId] and sessions[player.UserId].collectionBusy end,
	updated=function(player) if active(player) then world:update(player,store:get(player.UserId)); snapshot(player) end end,
})
purchases = PurchaseRuntime.new({config=Config,settings=Settings,store=store,backend=dataStore,engine=Factory,model=Monetization,
	memoryMode=memoryMode,active=active,profile=function(uid) return store:get(uid) end,
	writable=function(uid) return store:isWritable(uid) end,
	busy=function(uid) return closing or not sessions[uid] or sessions[uid].collectionBusy or trade.activeTrade(uid) end,
	inRange=function(player) return world:inRange(player,"requestPurchase",{},Settings.InteractDistance) end,
	transact=purchaseTransaction,promptRemote=PurchasePrompt})
Action.OnServerEvent:Connect(handleAction)
Ready.OnServerEvent:Connect(function(player)
	local now = os.clock()
	if now - (readyAt[player.UserId] or -10) < 2 then return end
	readyAt[player.UserId] = now
	snapshot(player)
end)

local function placeCharacter(player, character)
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	local plot = world.owners[player.UserId]
	if hrp and plot and plot.owner == player and player.Parent == Players then
		character:PivotTo(CFrame.new(plot.spawn.Position + Vector3.new(0, 4, 0)))
	end
end

local function clearPresentation(session)
	local player, userId = session.player, session.player.UserId
	trade.leave(player)
	purchases.leave(player)
	world:release(player)
	policy.forget(player)
	if sessions[userId] ~= session then return end
	Protocol:forget(userId)
	offlineReports[userId], readyAt[userId], noticesAt[userId] = nil, nil, nil
end

local function closeSession(session)
	if session.closeRunning then return end
	trade.leave(session.player)
	if session.phase == "loading" then
		session.cancelled = true
		return -- The in-flight load owns cleanup until it returns.
	end
	session.closeRunning = true
	local player, userId = session.player, session.player.UserId
	local wasActive = session.phase == "active"
	session.phase = "closing"
	if wasActive and store:isWritable(userId) and not trade.busy(userId) then
		local ok, result = pcall(Factory.advance, store:get(userId), os.time(), false)
		if not ok or result.ok == false then
			session.quarantined = true
			store:invalidate(userId)
		end
	end
	local released = store:get(userId) == nil
	local deadline = os.clock() + 22
	local attempts = 0
	while not released and not session.quarantined and os.clock() < deadline and attempts < 5 do
		attempts += 1
		local ok, result, err = pcall(store.release, store, userId)
		released = ok and result
		if not released then
			warn("Profile release pending", userId, err or result)
			task.wait(0.5)
		end
	end
	clearPresentation(session)
	if sessions[userId] == session then
		if released then sessions[userId] = nil
		else session.phase = "blocked" end
	end
	session.closeRunning = false
end

local function onPlayer(player)
	local userId = player.UserId
	if closing then player:Kick("Сервер завершает работу."); return end
	if sessions[userId] then
		player:Kick("Предыдущая сессия ещё завершается. Повторите вход или выберите другой сервер.")
		return
	end
	local session = { player = player, phase = "loading", cancelled = false }
	sessions[userId] = session
	local plot = world:claim(player)
	if not plot then
		sessions[userId] = nil
		player:Kick("Все участки заняты. Выберите другой сервер.")
		return
	end
	player.CharacterAdded:Connect(function(character) placeCharacter(player, character) end)
	if player.Character then task.spawn(placeCharacter, player, player.Character) end
	local profile, errorCode = store:load(player.UserId, function()
		return Factory.newProfile(player.UserId, os.time())
	end)
	if not profile then
		clearPresentation(session)
		if sessions[userId] == session then sessions[userId] = nil end
		warn("Profile load denied", player.UserId, errorCode)
		if player.Parent == Players then player:Kick("Не удалось безопасно загрузить прогресс. Попробуйте позже.") end
		return
	end
	if closing or session.cancelled or player.Parent ~= Players then
		session.phase = "closing"
		closeSession(session)
		return
	end
	Factory.claimStarterBudget(profile)
	if profile.trade.pending then
		local recovered=trade.recoverPlayer(player)
		profile=store:get(userId)
		if not recovered or not profile or profile.trade.pending then
			session.phase="closing"
			player:Kick("Обмен ещё восстанавливается. Предметы сохранены в журнале; повторите вход позже.")
			closeSession(session); return
		end
	end
	local ok, report = pcall(Factory.advance, profile, os.time(), true)
	if not ok or report.ok == false then
		warn("Offline simulation failed", player.UserId, report)
		-- Never overwrite a profile after a simulation failure.
		store:invalidate(userId)
		session.quarantined, session.phase = true, "blocked"
		player:Kick("Ошибка расчёта фабрики. Прогресс не перезаписан.")
		closeSession(session)
		return
	end
	-- Persist the catch-up timestamp and rewards BEFORE allowing actions or showing the report.
	local saved, saveError = store:save(player.UserId)
	if not saved then
		warn("Offline save failed", player.UserId, saveError)
		session.phase = "closing"
		player:Kick("Не удалось сохранить офлайн-прогресс. Повторите вход позже.")
		closeSession(session)
		return
	end
	if closing or session.cancelled or player.Parent ~= Players then
		session.phase = "closing"
		closeSession(session)
		return
	end
	session.phase = "active"
	task.spawn(function() local ok=pcall(purchases.refresh,player); if not ok then warn("Purchase rights refresh pending",userId) end end)
	task.spawn(function()
		policy.get(player)
		if sessions[userId] == session and active(player) then snapshot(player) end
	end)
	offlineReports[player.UserId] = report
	world:update(player, profile)
	snapshot(player)
end

local function safeJoin(player)
	local ok, err = pcall(onPlayer, player)
	if ok then return end
	warn("Player initialization failed", player.UserId, err)
	local session = sessions[player.UserId]
	if session and session.player == player then
		if store:get(player.UserId) then
			store:invalidate(player.UserId)
			session.quarantined, session.phase = true, "blocked"
		else
			sessions[player.UserId] = nil
		end
		clearPresentation(session)
	end
	if player.Parent == Players then player:Kick("Не удалось безопасно запустить фабрику. Повторите вход позже.") end
end

Players.PlayerAdded:Connect(function(player) task.spawn(safeJoin, player) end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(safeJoin, player) end

local function onLeave(player)
	local session = sessions[player.UserId]
	if session and session.player == player then closeSession(session) end
end
Players.PlayerRemoving:Connect(onLeave)

task.spawn(function()
	while not closing do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			if active(player) then
				if store:isWritable(player.UserId) and not sessions[player.UserId].collectionBusy and not trade.busy(player.UserId) then
					local ok, result = pcall(Factory.advance, store:get(player.UserId), os.time(), false)
					if not ok or result.ok == false then
						store:invalidate(player.UserId)
						sessions[player.UserId].quarantined = true
						sessions[player.UserId].phase = "blocked"
						warn("Simulation disabled", player.UserId, result)
						player:Kick("Ошибка фабрики. Выполните повторный вход.")
					else world:update(player, store:get(player.UserId)) end
				end
				snapshot(player)
			end
		end
	end
end)

task.spawn(function()
	while not closing do
		task.wait(Settings.AutosaveSeconds)
		for _, player in ipairs(Players:GetPlayers()) do
			if active(player) and not closing then
				local session = sessions[player.UserId]
				task.spawn(function()
					if sessions[player.UserId] ~= session or not active(player) or closing then return end
					local saved, err = store:save(player.UserId)
					if not saved then
						warn("Autosave failed", player.UserId, err)
						notice(player, "Сохранение временно недоступно. Действия могут быть приостановлены.", "save_error")
					end
				end)
			end
		end
	end
end)

task.spawn(function()
	task.wait(5 + math.random()*5)
	while not closing do
		local ok=pcall(trade.sweep)
		if not ok then warn("Trade recovery pass deferred") end
		task.wait(Config.trading.recoverySeconds + math.random()*3)
	end
end)

game:BindToClose(function()
	closing = true
	for _, session in pairs(sessions) do
		task.spawn(closeSession, session)
	end
	local deadline = os.clock() + 28
	while os.clock() < deadline do
		local pending = false
		for _, session in pairs(sessions) do
			if session.phase == "loading" or session.closeRunning then pending = true; break end
		end
		if not pending then break end
		task.wait(0.1)
	end
end)
