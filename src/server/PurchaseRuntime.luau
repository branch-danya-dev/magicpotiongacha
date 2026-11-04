--!nonstrict
-- The only platform receipt registration. No client callback can grant payment rights.
local MarketplaceService=game:GetService("MarketplaceService")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local DataStoreService=game:GetService("DataStoreService")
local Shared=game:GetService("ReplicatedStorage").PotionTycoon.Shared
local Catalog=require(Shared.OfferCatalog)
local Journal=require(script.Parent.ReceiptJournal)
local Coordinator=require(script.Parent.PurchaseCoordinator)
local Runtime={}
function Runtime.new(options)
	local settings,config=options.settings,options.config
	local catalog=Catalog.new(config,settings.PurchaseSkus); local service={}; local prompting,lastPrompt,lastRefresh,warnings={},{},{},{}
	local backend=options.memoryMode and options.backend or DataStoreService:GetDataStore(settings.ReceiptJournalName)
	local journal=Journal.new({backend=backend,sleep=task.wait})
	local function identity(userId)
		local p=Players:GetPlayerByUserId(userId); return p and options.active(p) and p or nil
	end
	local coordinator=Coordinator.new({catalog=catalog,model=options.model,journal=journal,engine=options.engine,transact=options.transact,
		identity=identity,ownsPass=function(userId,id) return MarketplaceService:UserOwnsGamePassAsync(userId,id) end})
	local function enabled()
		return settings.MonetizationEnabled==true and settings.PurchaseQAApproved==true and not options.memoryMode
			and (RunService:IsStudio() or settings.PurchaseQAPlaceId>0 and game.PlaceId==settings.PurchaseQAPlaceId)
	end
	local function diagnostic(code,sku)
		local key=tostring(sku)..":"..tostring(code); local now=os.clock()
		if now-(warnings[key] or -60)>=60 then warnings[key]=now; warn("Purchase reconciliation pending",sku,code) end
	end
	MarketplaceService.ProcessReceipt=function(receipt)
		-- Studio-memory sessions may never acknowledge a real financial transaction.
		if options.memoryMode then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local ok,accepted,result=pcall(coordinator.process,receipt)
		if ok and accepted then return Enum.ProductPurchaseDecision.PurchaseGranted end
		diagnostic(ok and result or "processing_error",receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	function service.decorate(p,state)
		for _,card in ipairs(state.cards) do
			local def=config.monetization.offers[card.offerId]; local id=catalog.sku(card.offerId)
			card.platformKind=def.platformKind
			card.robuxAvailable=enabled() and id>0 and card.available and card.room and not options.busy(p.userId)
				and state.receiptCount<config.monetization.maxReceipts and state.queued<config.monetization.maxQueued
			card.sku=card.robuxAvailable and id or 0
		end
		state.paidEnabled=enabled(); return state
	end
	function service.prompt(player,offerId)
		local uid=player.UserId; local def=config.monetization.offers[offerId]; local sku=catalog.sku(offerId)
		if not def or not enabled() or sku<=0 or prompting[player] or os.clock()-(lastPrompt[player] or -10)<5 then return false,"Покупки за Robux недоступны" end
		local function allowed()
			local p=options.profile(uid)
			return enabled() and identity(uid)==player and not options.busy(uid) and options.inRange(player) and p
				and options.writable(uid) and catalog.available(p,offerId,os.time()) and options.model.room(p,catalog.grant(offerId))
				and options.model.queued(p)<config.monetization.maxQueued and options.model.state(p,os.time()).receiptCount<config.monetization.maxReceipts
		end
		if not allowed() then return false,"Предложение, место или сессия недоступны" end
		prompting[player]=true; lastPrompt[player]=os.clock()
		local success,accepted,reason=pcall(function()
			local info=MarketplaceService:GetProductInfoAsync(sku,def.platformKind=="product" and Enum.InfoType.Product or Enum.InfoType.GamePass)
			if not info or info.IsForSale~=true or type(info.PriceInRobux)~="number" or not allowed() then return false,"Платформа не подтвердила доступность" end
			local bound,err=journal.bind(def.platformKind,sku,offerId,catalog.fingerprint(offerId)); if not bound then return false,err end
			if not allowed() then return false,"Условия изменились; открой магазин снова" end
			options.promptRemote:FireClient(player,{offerId=offerId,sku=sku,kind=def.platformKind})
			return true,"Проверь цену в нативном окне Roblox"
		end)
		prompting[player]=nil
		return success and accepted,success and reason or "Покупка сейчас недоступна"
	end
	function service.refresh(player,platformHint)
		if identity(player.UserId)~=player then return end
		local now=os.clock()
		if not platformHint and now-(lastRefresh[player] or -10)<10 then return end
		lastRefresh[player]=now
		for _,offerId in ipairs(config.monetization.offerOrder) do
			local def=config.monetization.offers[offerId]
			if def.platformKind=="pass" and catalog.sku(offerId)>0 and not options.memoryMode then coordinator.syncPass(player.UserId,offerId) end
		end
		if identity(player.UserId)~=player then return end
		local p=options.profile(player.UserId)
		if p and options.model.queued(p)>0 then
			options.transact(player.UserId,function(candidate,ctx)
				return options.model.apply(candidate,"deliverPurchases",{requestId=candidate.monetization.sequence+1},options.engine,ctx)
			end)
		end
	end
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player,passId)
		if catalog.resolve("pass",passId) then task.spawn(function() service.refresh(player,true) end) end -- Completion is a lookup hint, never evidence.
	end)
	function service.leave(player) prompting[player],lastPrompt[player],lastRefresh[player]=nil,nil,nil end
	return service
end
return Runtime
