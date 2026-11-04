--!nonstrict
-- Roblox adapter. Admission is private-QA-only; recovery never depends on UI or login.
local Players=game:GetService("Players")
local DataStoreService=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local C=require(Shared.TradeCodec)
local Trading=require(Shared.Trading)
local TradeSession=require(Shared.TradeSession)
local Journal=require(script.Parent.TradeJournal)
local Coordinator=require(script.Parent.TradeCoordinator)
local ProfileStore=require(script.Parent.ProfileStore)
local Runtime={}
function Runtime.new(options)
	local config,settings,store=options.config,options.settings,options.store
	local model=Trading.new(config); local service={}; local tokens,peers,outcomes,lastSnapshots={},{},{},{}
	local owner="trade:"..HttpService:GenerateGUID(false)
	local function enabled()
		return settings.TradingEnabled==true and (RunService:IsStudio() or (settings.TradingQAPlaceId>0 and game.PlaceId==settings.TradingQAPlaceId))
	end
	local function budget(minimum)
		return options.memoryMode or DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)>=(minimum or 1)
	end
	local journalBackend=options.memoryMode and options.backend or DataStoreService:GetDataStore(settings.TradeJournalName)
	local journal=Journal.new({backend=journalBackend,now=os.time,sleep=task.wait,validate=model.validateJournal,
		retentionSeconds=config.trading.retentionSeconds,shards=config.trading.journalShards,capacity=config.trading.journalCapacity,budget=budget})
	local port={}
	function port.mutate(userId,transform)
		if not budget(3) then return false,"Recovery request budget low" end
		if store:get(userId) and store:hasLease(userId) then return store:transactTrade(userId,transform) end
		-- A fresh recovery owner acquires the ordinary lease; an existing live
		-- foreign lease blocks it. Never mutate another server's active profile.
		local recovery=ProfileStore.new({dataStore=options.backend,now=os.time,sleep=task.wait,
			owner="recovery:"..HttpService:GenerateGUID(false),validate=options.engine.validate,migrate=options.engine.migrate,leaseSeconds=settings.LeaseSeconds})
		local p,reason=recovery:loadExisting(userId,function() return options.engine.newProfile(userId,os.time()) end)
		if not p then return false,reason end
		local ok,result=recovery:transactTrade(userId,transform)
		local released=recovery:release(userId)
		return ok and released,result
	end
	local coordinator=Coordinator.new({journal=journal,model=model,profiles=port,now=os.time,owner=owner,prepareSeconds=config.trading.prepareSeconds})
	local function playerFor(userId)
		for _,player in ipairs(Players:GetPlayers()) do if player.UserId==userId then return player end end
		return nil
	end
	local function identity(userId)
		local player=playerFor(userId); return player and options.active(player) and player or nil
	end
	local manager
	local function decorate(items,p)
		local caps={Farming=0,Hauling=0,Brewing=0}
		for id,station in pairs(p.stations) do
			local def=config.stations[id]
			if station.level>0 then caps[def.skill]=math.max(caps[def.skill],def.statCaps[station.level]) end
		end
		for _,entry in ipairs(items) do
			if entry.kind=="pet" then entry.effective={}; for skill,base in pairs(entry.data.stats) do entry.effective[skill]=math.min(base,caps[skill]) end end
		end
	end
	function service.send(player,terminalTrade)
		if player.Parent~=Players then return end
		local p=store:get(player.UserId)
		local t=terminalTrade or manager.current(player.UserId)
		if terminalTrade and (t.state=="settled" or t.state=="aborted" or t.state=="cancelled" or t.state=="declined") then outcomes[player]=manager.view(t,player.UserId) end
		local value={enabled=enabled(),session=manager.view(t,player.UserId) or C.copy(outcomes[player]),peers={},inventory={},blocked=p and Trading.frozen(p) or false}
		if not p or not options.active(player) or Trading.frozen(p) then
			value.message="Обмен восстанавливается. Предметы временно недоступны."
		else
			if value.session then for _,side in ipairs(value.session.sides) do decorate(side.items,p) end end
			if enabled() and options.inBazaar(player) then
				for _,other in ipairs(Players:GetPlayers()) do
					if other~=player and options.active(other) and options.inBazaar(other) then
						if not tokens[other] then local token="peer:"..HttpService:GenerateGUID(false); tokens[other]=token; peers[token]=other end
						table.insert(value.peers,{token=tokens[other],name=other.DisplayName})
					end
				end
				for _,kind in ipairs({"pet","cauldron"}) do
					for id,item in pairs(kind=="pet" and p.pets or p.cauldrons) do
						local eligible,reason=model.item(p,kind,id)
						table.insert(value.inventory,{id=id,kind=kind,data=C.copy(item),available=eligible~=nil,reason=reason})
					end
				end
				decorate(value.inventory,p); table.sort(value.inventory,function(a,b) return a.id<b.id end)
			end
		end
		local encoded=C.encode(value)
		if lastSnapshots[player]~=encoded then lastSnapshots[player]=encoded; options.remote:FireClient(player,value) end
	end
	manager=TradeSession.new({config=config,model=model,enabled=enabled,now=os.time,identity=identity,
		name=function(uid) local p=playerFor(uid); return p and p.DisplayName or "Player" end,
		resolve=function(token) local p=peers[token]; return p and p.Parent==Players and options.active(p) and p.UserId or nil end,
		uuid=function() return HttpService:GenerateGUID(false) end,
		profile=function(uid) return store:get(uid) end,
		inBazaar=function(uid) local p=playerFor(uid); return p and options.inBazaar(p) or false end,
		writable=function(uid) local p=playerFor(uid); return p and store:isWritable(uid) and not options.valueBusy(p) end,
		leaseActive=function(uid) local p=playerFor(uid); return p and options.active(p) and store:hasLease(uid) and not options.closing() end,
		policy=function(uid,force) local p=playerFor(uid); return p and options.policy.get(p,force) or {} end,
		canStart=function() return budget(30) end,
		commit=coordinator.start,recover=function(id,cancel) return coordinator.recover(id,cancel and owner or nil) end,
		changed=function(t)
			for _,side in ipairs(t.sides) do
				local player=playerFor(side.userId)
				if player then
					service.send(player,t)
					if t.state=="settled" or t.state=="aborted" then
						if store:isWritable(player.UserId) then options.updated(player)
						elseif options.active(player) then player:Kick("Обмен обработан. Войдите снова, чтобы загрузить подтверждённый инвентарь.") end
					end
				end
			end
		end,
	})
	function service.busy(userId) return manager.busy(userId) end
	function service.activeTrade(userId) return manager.current(userId)~=nil end
	function service.handle(player,action,payload)
		if not enabled() then return false,"Торговля выключена до живой приёмки." end
		if not options.active(player) or options.closing() then return false,"Player session unavailable" end
		return manager.handle(player.UserId,action,payload)
	end
	function service.leave(player)
		manager.leave(player.UserId)
		outcomes[player],lastSnapshots[player]=nil,nil
		if tokens[player] then peers[tokens[player]]=nil; tokens[player]=nil end
	end
	function service.recoverPlayer(player)
		local p=store:get(player.UserId)
		if not p or not Trading.frozen(p) then return true end
		service.send(player)
		local ok,reason=coordinator.recover(p.trade.pending.id)
		local current=store:get(player.UserId)
		return ok and current~=nil and not Trading.frozen(current),reason
	end
	function service.sweep()
		manager.poll()
		if not budget(20) then return end
		for _=1,config.trading.scanPerPass do
			local id,entry=journal.nextKey(); if not id then break end
			local j,reason=journal.read(id)
			if j then
				if j.state=="COMPLETE" then journal.collect(id)
				elseif j.state~="PREPARING" or os.time()>=j.deadline then coordinator.recover(id) end
			elseif reason=="Journal missing" then journal.cleanMissing(id,entry) end
		end
	end
	return service
end
return Runtime
