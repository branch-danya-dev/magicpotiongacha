--!nonstrict
local H=require("./M6Harness")
local Catalog=require("../src/shared/OfferCatalog")
local Coordinator=require("../src/server/PurchaseCoordinator")
return function(T:any)
	T.test("M6 receipts: four confirmed boundaries precede acknowledgment",function()
		local h=H.new(); local before=H.count(h.profile().pets); T.truthy(h.process()); T.equal(h.calls,4)
		T.equal(h.events[1].key,"sku:product:1001"); T.equal(h.events[2].state,"RECORDED")
		T.equal(h.events[3].key,"p:101"); T.equal(h.events[4].state,"APPLIED")
		T.equal(H.count(h.profile().pets),before+1); T.truthy(h.process()); T.equal(H.count(h.profile().pets),before+1); h.oracle()
	end)
	for boundary=1,4 do for _,mode in ipairs({"before","after"}) do
		T.test("M6 receipts: crash/reconnect at durable boundary "..boundary.." / "..mode,function()
			local h=H.new(); local n=H.count(h.profile().pets); h.fault={at=boundary,mode=mode,sticky=true}
			T.falsy(h.process()); h.oracle()
			if boundary==3 then T.falsy(h.store:isWritable(101)) end
			h.restart(); T.truthy(h.process()); T.truthy(h.process()); h.oracle()
			T.equal(H.count(h.profile().pets),n+1); T.equal(H.count(h.profile().monetization.receipts),1)
		end)
	end end
	for boundary=1,4 do
		T.test("M6 receipts: lost reply retried at boundary "..boundary,function()
			local h=H.new(); h.fault={at=boundary,mode="after",sticky=false}; T.truthy(h.process()); h.oracle(); T.equal(H.count(h.profile().monetization.receipts),1)
		end)
	end
	T.test("M6 receipts: UpdateAsync callback replay is pure and bounded",function()
		local h=H.new(); h.replays=4; T.truthy(h.process()); T.equal(h.profile().nextPetSerial,2); T.equal(H.count(h.profile().monetization.receipts),1)
	end)
	T.test("M6 receipts: separate legitimate purchase IDs each grant once",function()
		local h=H.new(); T.truthy(h.process()); local receipt=H.copy(h.receipt); receipt.PurchaseId="purchase-0002"
		T.truthy(h.process(receipt)); T.truthy(h.process(receipt)); T.equal(h.profile().nextPetSerial,3)
	end)
	T.test("M6 receipts: confirmed proof can acknowledge after player leaves",function()
		local h=H.new(); T.truthy(h.process()); h.identities[101]=nil; T.truthy(h.process()); T.equal(h.profile().nextPetSerial,2)
	end)
	for _,action in ipairs({"buyEventGold","deliverPurchases"}) do for _,mode in ipairs({"before","after"}) do
		T.test("M6 intents: unknown profile write preserves charge/right / "..action.."/"..mode,function()
			local h=H.new(); local payload={}
			if action=="buyEventGold" then h.profile().gold=10000; assert(h.store:save(101)); payload={offerId="ghost_wolf_v1",confirmed=true}
			else
				h.fill("cauldron"); h.receipt.ProductId=1002; T.truthy(h.process())
				-- Capacity fixture; the independent Fuse and M4 tests exercise real slot release.
				h.profile().cauldrons[next(h.profile().cauldrons)]=nil; assert(h.store:save(101))
			end
			payload.requestId=h.profile().monetization.sequence+1; local before=H.copy(h.profile())
			h.fault={at=h.calls+1,mode=mode,sticky=true}; T.falsy(h.action(action,payload)); T.same(h.profile(),before); T.falsy(h.store:save(101))
			h.restart(); T.truthy(h.action(action,payload)); local after=H.copy(h.profile()); T.truthy(h.action(action,payload)); T.same(h.profile(),after)
			if action=="buyEventGold" then T.equal(h.profile().gold,8200) else T.equal(h.model.queued(h.profile()),0); T.equal(H.count(h.profile().cauldrons),16) end
		end)
	end end
	for _,kind in ipairs({"pet","cauldron"}) do
		T.test("M6 receipts: full "..kind.." inventory retains acknowledged queue across restart",function()
			local h=H.new(); h.fill(kind); if kind=="cauldron" then h.receipt.ProductId=1002 end
			local before=H.copy(h.profile()); T.falsy(h.gold(kind=="pet" and "ghost_wolf_v1" or "spectral_cauldron_v1")); T.same(h.profile(),before)
			local ok,status=h.process(); T.truthy(ok); T.equal(status,"queued"); h.restart()
			T.equal(h.model.queued(h.profile()),1); T.falsy(h.action("deliverPurchases")); T.truthy(h.process())
			T.equal(h.model.queued(h.profile()),1); h.oracle()
		end)
	end
	for _,reason in ipairs({"absent","busy","trade"}) do
		T.test("M6 receipts: durable record waits for "..reason.." without acknowledgment",function()
			local h=H.new(); if reason=="absent" then h.identities[101]=nil elseif reason=="busy" then h.busy=true else h.tradeActive=true end
			local before=H.copy(h.profile()); T.falsy(h.process()); T.same(h.profile(),before)
			T.equal(h.journals[H.Journal.key(h.receipt.PurchaseId)].state,"RECORDED")
			h.identities[101]={}; h.busy=false; h.tradeActive=false; T.truthy(h.process())
		end)
	end
	T.test("M6 receipts: concurrent reentrant callbacks cannot enter the profile gate",function()
		local h=H.new(); local attempted=false
		h.beforeUpdate=function(kind) if kind=="profile" then h.beforeUpdate=nil; attempted=true; T.falsy(h.process()) end end
		T.truthy(h.process()); T.truthy(attempted); T.truthy(h.process()); T.equal(h.profile().nextPetSerial,2)
	end)
	T.test("M6 receipts: live lease excludes another server; expired old writer cannot grant",function()
		local h=H.new(); local other=h.newStore("server:other")
		T.falsy(other:loadExisting(101,function() error("must not reset") end))
		local old=h.store; h.restart(); T.truthy(h.process())
		T.falsy(old:transact(101,function(p) return h.model.acceptReceipt(p,h.receipt,"ghost_wolf_v1",h.engine,{now=h.now}) end)); h.oracle()
	end)
	T.test("M6 receipts: two server coordinators reconcile one shared receipt and lease",function()
		local h=H.new(); local otherStore=h.newStore("server:competing")
		local other=Coordinator.new({catalog=h.catalog,model=h.model,journal=h.journal,engine=h.engine,
			transact=function(uid,fn) return otherStore:transact(uid,function(p) return fn(p,{now=h.now}) end) end})
		local competed=false
		h.beforeUpdate=function(kind) if kind=="profile" then h.beforeUpdate=nil; competed=true
			T.falsy(otherStore:loadExisting(101,function() error("must not create") end)); T.falsy(other.process(h.receipt))
		end end
		T.truthy(h.process()); T.truthy(competed); T.truthy(other.process(h.receipt)); T.equal(h.profile().nextPetSerial,2); h.oracle()
	end)
	for _,field in ipairs({"PlayerId","ProductId","PurchaseId"}) do
		T.test("M6 receipts: malformed trusted input / "..field,function()
			local h=H.new(); local receipt=H.copy(h.receipt); receipt[field]=field=="PurchaseId" and "" or 0
			T.falsy(h.process(receipt)); T.equal(h.calls,0)
		end)
	end
	T.test("M6 receipts: unknown SKU and conflicting identity never grant",function()
		local h=H.new(); local receipt=H.copy(h.receipt); receipt.ProductId=9999; T.falsy(h.process(receipt)); T.equal(h.calls,0)
		T.truthy(h.process()); receipt.ProductId=1002; T.falsy(h.process(receipt)); receipt.ProductId=1001; receipt.PlayerId=202; T.falsy(h.process(receipt)); h.oracle()
	end)
	T.test("M6 receipts: previously bound SKU rejects a changed grant even for a new purchase",function()
		local h=H.new(); T.truthy(h.process()); local config=H.copy(H.Config); config.monetization.offers.ghost_wolf_v1.version=2
		local catalog=Catalog.new(config,h.skus); local called=false
		local other=Coordinator.new({catalog=catalog,model=h.model,journal=h.journal,engine=h.engine,transact=function() called=true; return true end})
		local receipt=H.copy(h.receipt); receipt.PurchaseId="new-id-after-rebind"; T.falsy(other.process(receipt)); T.falsy(called)
	end)
	T.test("M6 receipts: archive grant survives event end and sales disable",function()
		local config=H.copy(H.Config); config.monetization.offers.ghost_wolf_v1.enabled=false
		local h=H.new(config); h.now=config.events.spectral_2026.endAtUtc+100; h.restart(); T.falsy(h.gold()); T.truthy(h.process()); T.equal(h.profile().nextPetSerial,2)
	end)
	T.test("M6 receipts: journal collision/invalid future state fails closed",function()
		local h=H.new(); local key=H.Journal.key(h.receipt.PurchaseId); T.equal(#key,50)
		h.journals[key]={schemaVersion=2,state="APPLIED"}; T.falsy(h.process()); T.equal(h.profile().nextPetSerial,1)
	end)
	for _,owns in ipairs({false,"error",true}) do
		T.test("M6 passes: server ownership lookup / "..tostring(owns),function()
			local h=H.new(); h.owns=owns; local ok=h.coordinator.syncPass(101,"aurora_theme_v1"); T.equal(ok,owns==true)
			T.equal(h.profile().entitlements.aurora_theme,owns==true and true or nil)
			if owns==true then T.truthy(h.coordinator.syncPass(101,"aurora_theme_v1")); T.equal(H.count(h.profile().monetization.passes),1) end
		end)
	end
	T.test("M6 passes: ownership yielding across reconnect cannot mutate a replacement session",function()
		local h=H.new(); h.onOwnership=function() h.identities[101]={} end; T.falsy(h.coordinator.syncPass(101,"aurora_theme_v1")); T.equal(h.calls,0)
	end)
	for boundary=1,2 do for _,mode in ipairs({"before","after"}) do
		T.test("M6 passes: durable fault "..boundary.." / "..mode,function()
			local h=H.new(); h.fault={at=boundary,mode=mode,sticky=true}; T.falsy(h.coordinator.syncPass(101,"aurora_theme_v1"))
			h.restart(); T.truthy(h.coordinator.syncPass(101,"aurora_theme_v1")); T.equal(H.count(h.profile().monetization.passes),1)
		end)
	end end
	T.test("M6 receipts: history and queue saturation never evict old proof",function()
		local config=H.copy(H.Config); config.monetization.maxReceipts=1; local h=H.new(config); T.truthy(h.process())
		local before=H.copy(h.profile().monetization); local receipt=H.copy(h.receipt); receipt.PurchaseId="limit-2"; T.falsy(h.process(receipt)); T.same(h.profile().monetization,before)
		config=H.copy(H.Config); config.monetization.maxQueued=1; h=H.new(config); h.fill("pet"); T.truthy(h.process()); receipt=H.copy(h.receipt); receipt.PurchaseId="queue-2"
		T.falsy(h.process(receipt)); T.equal(h.model.queued(h.profile()),1); T.truthy(h.process())
	end)
end
