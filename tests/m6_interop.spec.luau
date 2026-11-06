--!nonstrict
local H=require("./M6Harness")
local M4=require("./M4Harness")
local M5=require("./M5Harness")
local Session=require("./TradeSessionHarness")
local Model=require("../src/shared/Monetization")
local Catalog=require("../src/shared/OfferCatalog")
local Coordinator=require("../src/server/PurchaseCoordinator")
local LongTerm=require("../src/shared/LongTerm")
local fixture=require("./fixtures/m5-progression-pending")
local Config=H.Config
local function purchases(h)
	local model=Model.new(Config)
	local coordinator=Coordinator.new({catalog=Catalog.new(Config,{ghost_wolf_v1=1001,spectral_cauldron_v1=1002}),model=model,engine=h.engine,
		journal=H.Journal.new({backend=h.journalBackend,sleep=function() end}),
		transact=function(uid,fn) return h.stores[uid]:transact(uid,function(p) return fn(p,{now=h.now,tradeActive=h.session and h.session.current(uid)~=nil}) end) end})
	function h.pay(productId,purchaseId) return coordinator.process({PlayerId=101,ProductId=productId or 1001,PurchaseId=purchaseId or "event-receipt"}) end
	return model
end
return function(T:any)
	for _,kind in ipairs({"pet","cauldron"}) do
		T.test("M6/M4: paid "..kind.." transfers, receipt replay never recreates old ownership",function()
			local h=M4.new(); purchases(h); local product=kind=="pet" and 1001 or 1002; T.truthy(h.pay(product))
			local proof=h.profile(101).monetization.receipts[H.hash("event-receipt")]; local id=proof.instanceId
			local offer={{kind=kind,id=id}}; local proposal=h.proposal(101,202,offer,{{kind="pet",id="202:pet:1"}})
			T.truthy(h.coordinator.start("event-transfer",proposal,function() return function() return true end end)); T.truthy(h.pay(product))
			local inventory=kind=="pet" and "pets" or "cauldrons"
			T.equal(h.profile(101)[inventory][id],nil); T.truthy(h.profile(202)[inventory][id].provenance.paidDerived)
			T.equal(h.profile(101).monetization.receipts[H.hash("event-receipt")].instanceId,id); h.oracle()
		end)
	end
	T.test("M6/M4: pending durable trade defers payment then recovers before replay",function()
		local h=M4.new(); purchases(h); h.fault={at=7,mode="after",sticky=true}; h.start(); h.offline=false; h.fault=nil
		T.truthy(h.profile(101).trade.pending); T.falsy(h.pay()); T.equal(h.journals[H.Journal.key("event-receipt")].state,"RECORDED")
		h.restart(); T.truthy(h.recover()); h.load(101); T.truthy(h.pay()); h.oracle()
	end)
	for _,restricted in ipairs({101,202}) do
		T.test("M6/M4: paid seasonal inventory still obeys policy of player "..restricted,function()
			local h=Session(); purchases(h); T.truthy(h.pay()); h.policies[restricted].tradingAllowed=false
			T.falsy(h.call(101,"tradeInvite",{targetToken="token202"})); T.equal(h.session.current(101),nil)
		end)
	end
	T.test("M6/M4: value write excludes trade invitation and live negotiation excludes delivery",function()
		local h=Session(); purchases(h); h.valueOperation=true; local attempted=false
		h.beforeUpdate=function(kind) if kind=="profile" then attempted=true; T.falsy(h.call(101,"tradeInvite",{targetToken="token202"})) end end
		T.truthy(h.pay()); T.truthy(attempted); h.beforeUpdate=nil; h.valueOperation=false
		T.truthy(h.call(101,"tradeInvite",{targetToken="token202"})); T.falsy(h.pay(1002,"during-negotiation")); T.truthy(h.call(101,"tradeCancel")); T.truthy(h.pay(1002,"during-negotiation"))
	end)
	T.test("M6/M5: Rebirth preserves delivered items, queued rights, receipt proofs and pass",function()
		local h=H.new(); local rich=M5.new(); rich.profile=h.profile(); rich.now=h.now; rich.profile.gold=100000; rich.profile.essence=100000; rich.complete(); h.now=rich.now
		T.truthy(h.store:save(101)); T.truthy(h.process()); h.receipt={PlayerId=101,ProductId=1002,PurchaseId="cauldron-1"}; T.truthy(h.process())
		T.truthy(h.coordinator.syncPass(101,"aurora_theme_v1")); h.fill("pet"); h.receipt={PlayerId=101,ProductId=1001,PurchaseId="queued-1"}; T.truthy(h.process())
		local before=H.copy(h.profile()); local longTerm=LongTerm.new(Config)
		T.truthy(h.mutate(function(p,ctx) return longTerm.apply(p,"rebirth",{expectedRebirthCount=0,confirmed=true,requestId=p.longTerm.sequence+1},h.engine,ctx) end))
		local p=h.profile(); T.same(p.monetization,before.monetization); T.same(p.pets,before.pets); T.same(p.cauldrons,before.cauldrons); T.same(p.entitlements,before.entitlements)
		T.equal(p.phase,1); T.equal(p.gold,0); T.equal(p.essence,0); T.equal(p.longTerm.shards,1); T.equal(p.rebirths,1); T.truthy(h.process())
	end)
	T.test("M6/M5: receipt waiting at profile write cannot race reset",function()
		local h=H.new(); local longTerm=LongTerm.new(Config); local attempted=false
		h.beforeUpdate=function(kind) if kind=="profile" then h.beforeUpdate=nil; attempted=true
			T.falsy(h.store:transact(101,function(p) return longTerm.apply(p,"rebirth",{expectedRebirthCount=0,confirmed=true,requestId=1},h.engine,{now=h.now}) end))
		end end
		T.truthy(h.process()); T.truthy(attempted); T.equal(h.profile().rebirths,0)
	end)
	T.test("M6 migration: authentic V6 progressed profile gains empty V7 rights and the V8 projection",function()
		local h=H.new(); local old=H.copy(fixture.progressed); T.equal(old.schemaVersion,6); T.equal(old.rebirths,1)
		local p=assert(h.engine.migrate(old)); T.equal(p.schemaVersion,Config.schemaVersion); T.same(p.monetization,Model.initial())
		local body=H.copy(p); body.schemaVersion=6; body.monetization=nil
		for _,key in ipairs({"layout","temple","seeds","plants","outputMode","potionStacks","uniquePotions","atlas","starter","workforce","charms"}) do body[key]=nil end
		T.same(body,fixture.progressed); T.same(old,fixture.progressed)
	end)
	T.test("M6 migration: authentic V6 pending M4 commit recovers without losing inventory",function()
		local h=M4.new(); h.records["p:101"]={schemaVersion=1,revision=1,profile=H.copy(fixture.pending)}
		h.records["p:202"]={schemaVersion=1,revision=1,profile=H.copy(fixture.other)}; h.journals["t:trade-uuid-1"]=H.copy(fixture.journal)
		h.restart(); T.truthy(h.recover()); T.truthy(h.checkOutcome()); h.load(101); T.equal(h.profile(101).schemaVersion,Config.schemaVersion)
	end)
	for _,version in ipairs({1,2,3,4,5,6}) do
		T.test("M6 migration: V"..version.." cannot smuggle V7 payment state",function()
			local h=H.new(); local p=H.copy(fixture.progressed); p.schemaVersion=version; p.monetization=Model.initial(); T.falsy(h.engine.migrate(p))
		end)
	end
	T.test("M6 persistence: future/invalid V7 saved record is never overwritten by default",function()
		local h=H.new(); h.records["p:101"].profile.schemaVersion=Config.schemaVersion+1; local before=H.copy(h.records); h.now+=181
		local store=h.newStore("new"); T.falsy(store:loadExisting(101,function() error("no reset") end)); T.same(h.records,before)
	end)
end
