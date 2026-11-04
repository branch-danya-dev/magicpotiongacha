--!nonstrict
local H=require("./M6Harness")
local Config=H.Config
local Catalog=require("../src/shared/OfferCatalog")
local Protocol=require("../src/shared/Protocol")
local Collection=require("../src/shared/Collection")
local Settings=require("../src/server/ServerSettings")
local function fuse(h,ids)
	local c=Collection.new(Config); local preview=assert(c.preview(h.profile(),ids)); preview.token="preview-m6"; preview.expiresAt=h.now+30
	return h.mutate(function(p) return c.apply(p,"fuse",{petIds=ids,previewToken=preview.token,confirmed=true,requestId=p.collection.sequence+1},{now=h.now,preview=preview}) end)
end
return function(T:any)
	T.test("M6 config: default release cannot prompt real spending or enable public trading",function()
		T.falsy(Settings.MonetizationEnabled); T.falsy(Settings.PurchaseQAApproved); T.equal(Settings.PurchaseQAPlaceId,0); T.falsy(Settings.TradingEnabled)
		for _,sku in pairs(Settings.PurchaseSkus) do T.equal(sku,0) end
		for _,def in pairs(Config.monetization.offers) do T.truthy(def.kind=="pet" or def.kind=="cauldron" or def.kind=="cosmetic"); T.equal(def.currency,nil) end
	end)
	for _,offset in ipairs({-1,0,1,14*86400-1,14*86400,14*86400+1}) do
		T.test("M6 catalog: UTC half-open sale interval / "..offset,function()
			local h=H.new(); local now=h.now+offset; local ok=h.catalog.available(h.profile(),"ghost_wolf_v1",now)
			T.equal(ok,offset>=0 and offset<14*86400)
		end)
	end
	for _,change in ipairs({"duplicateSKU","negativeSKU","unknownSKU","kind","stat","event","chance"}) do
		T.test("M6 catalog: malformed configuration fails closed / "..change,function()
			local config=H.copy(Config); local skus={ghost_wolf_v1=10,spectral_cauldron_v1=11,aurora_theme_v1=12}
			if change=="duplicateSKU" then skus.spectral_cauldron_v1=10 elseif change=="negativeSKU" then skus.ghost_wolf_v1=-1
			elseif change=="unknownSKU" then skus.unknown=100 elseif change=="kind" then config.monetization.offers.ghost_wolf_v1.kind="currency"
			elseif change=="stat" then config.monetization.offers.ghost_wolf_v1.stats.Hauling=999
			elseif change=="event" then config.events.spectral_2026.endAtUtc=config.events.spectral_2026.startAtUtc
			else config.monetization.offers.spectral_cauldron_v1.bonus=0.05 end
			T.throws(function() Catalog.new(config,skus) end)
		end)
	end
	for _,offerId in ipairs({"ghost_wolf_v1","spectral_cauldron_v1"}) do
		T.test("M6 model: Gold and paid gameplay/visual data are identical / "..offerId,function()
			local h=H.new(); h.profile().gold=10000; local goldBefore=h.profile().gold
			local ok,g=h.gold(offerId); T.truthy(ok); h.receipt.ProductId=h.skus[offerId]; T.truthy(h.process())
			local proof=h.profile().monetization.receipts[H.hash(h.receipt.PurchaseId)]
			local inventory=offerId=="ghost_wolf_v1" and h.profile().pets or h.profile().cauldrons
			local a,b=H.copy(inventory[g.instanceId]),H.copy(inventory[proof.instanceId])
			T.falsy(a.provenance.paidDerived); T.truthy(b.provenance.paidDerived)
			a.id,b.id="same","same"; a.provenance,b.provenance=nil,nil; a.paidOrigin,b.paidOrigin=nil,nil; T.same(a,b)
			T.equal(h.profile().gold,goldBefore-Config.monetization.offers[offerId].goldCost); T.equal(h.profile().essence,0); T.equal(h.profile().longTerm.shards,0)
		end)
	end
	T.test("M6 model: Gold retry is exact and conflicting/stale request does not charge",function()
		local h=H.new(); h.profile().gold=10000; local payload={offerId="ghost_wolf_v1",confirmed=true,requestId=1}
		T.truthy(h.action("buyEventGold",payload)); local before=H.copy(h.profile()); T.truthy(h.action("buyEventGold",payload)); T.same(h.profile(),before)
		payload.offerId="spectral_cauldron_v1"; T.falsy(h.action("buyEventGold",payload)); T.same(h.profile(),before)
		payload.requestId=0; T.falsy(h.action("buyEventGold",payload)); T.same(h.profile(),before)
	end)
	T.test("M6 model: legacy paid Gold remains paid-derived; fixed shop needs no random policy",function()
		local h=H.new(); h.profile().gold=10000; h.profile().currencyPaid.gold=true; local ok,r=h.gold(); T.truthy(ok); T.truthy(h.profile().pets[r.instanceId].paidOrigin)
	end)
	T.test("M6 model: no funds/clock/session can bypass purchase validation",function()
		local h=H.new(); T.falsy(h.gold()); local before=H.copy(h.profile()); h.profile().gold=10000
		T.falsy(h.model.apply(h.profile(),"buyEventGold",{offerId="ghost_wolf_v1",confirmed=true,requestId=1},h.engine,{now=h.now-1})); T.equal(H.count(h.profile().pets),H.count(before.pets))
		h.identities[101]=nil; T.falsy(h.gold()); T.equal(h.profile().gold,10000)
	end)
	for _,field in ipairs({"PurchaseId","ProductId","PlayerId","price","stats","paidDerived","now","reward","gold"}) do
		T.test("M6 protocol: client cannot supply trusted field / "..field,function()
			for _,action in ipairs({"buyEventGold","requestPurchase","deliverPurchases","refreshPurchases"}) do
				local p=action=="buyEventGold" and {offerId="ghost_wolf_v1",confirmed=true,requestId=1} or action=="requestPurchase" and {offerId="ghost_wolf_v1"} or action=="deliverPurchases" and {requestId=1} or {}
				p[field]=1; T.falsy(Protocol.validate(action,p))
			end
		end)
	end
	T.test("M6 model: five event wolves Fuse deterministically with paid OR and known AND",function()
		local h=H.new(); h.profile().gold=100000; local ids={}
		for _=1,4 do local ok,r=h.gold(); T.truthy(ok); table.insert(ids,r.instanceId) end
		T.truthy(h.process()); table.insert(ids,h.profile().monetization.receipts[H.hash(h.receipt.PurchaseId)].instanceId)
		local ok,result=fuse(h,ids); T.truthy(ok); local pet=h.profile().pets[result.createdIds[1]]
		T.equal(pet.species,"ghost_alpha"); T.same(pet.stats,{Farming=15,Hauling=34,Brewing=13}); T.truthy(pet.paidOrigin); T.truthy(pet.provenance.tradeKnown)
		for _,id in ipairs(ids) do T.equal(h.profile().pets[id],nil) end
		T.truthy(h.process()); T.equal(H.count(h.profile().pets),4); T.truthy(h.engine.validate(h.profile()))
	end)
	T.test("M6 queue: real Fuse frees slots and delivers each retained right once",function()
		local h=H.new(); h.fill("pet"); T.truthy(h.process()); local ids={}
		for id,pet in pairs(h.profile().pets) do if pet.species=="ghost_wolf" and #ids<5 then table.insert(ids,id) end end
		T.truthy(fuse(h,ids)); T.truthy(h.action("deliverPurchases")); T.equal(h.model.queued(h.profile()),0)
		T.equal(H.count(h.profile().pets),Config.maxPets-3); T.truthy(h.process()); T.falsy(h.action("deliverPurchases")); h.restart(); T.equal(h.model.queued(h.profile()),0)
	end)
	T.test("M6 Fuse: an unknown parent never becomes known through seasonal evolution",function()
		local h=H.new(); h.profile().gold=100000; local ids={}
		for _=1,5 do local ok,r=h.gold(); T.truthy(ok); table.insert(ids,r.instanceId) end
		h.profile().pets[ids[1]].provenance.tradeKnown=false; T.truthy(h.engine.validate(h.profile()))
		local ok,r=fuse(h,ids); T.truthy(ok); T.falsy(h.profile().pets[r.createdIds[1]].provenance.tradeKnown)
	end)
	T.test("M6 expiry: closing sales never changes owned stats, effects or provenance",function()
		local h=H.new(); h.profile().gold=10000; T.truthy(h.gold()); h.receipt.ProductId=1002; T.truthy(h.process())
		local pets,pots=H.copy(h.profile().pets),H.copy(h.profile().cauldrons)
		h.now=Config.events.spectral_2026.endAtUtc+1; h.restart(); T.falsy(h.gold()); T.same(h.profile().pets,pets); T.same(h.profile().cauldrons,pots)
	end)
	for _,kind in ipairs({"queuedInstance","duplicateProof","wrongHash","futureStatus","duplicateItem"}) do
		T.test("M6 validation: corrupt purchase evidence is rejected / "..kind,function()
			local h=H.new(); T.truthy(h.process()); local p=H.copy(h.profile()); local hash=H.hash(h.receipt.PurchaseId); local proof=p.monetization.receipts[hash]
			if kind=="queuedInstance" then proof.status="queued"
			elseif kind=="duplicateProof" then p.monetization.receipts[H.hash("another")]=H.copy(proof)
			elseif kind=="wrongHash" then proof.grantHash=H.hash("bad")
			elseif kind=="futureStatus" then proof.status="refund"
			else local pet=H.copy(p.pets[proof.instanceId]); pet.id="101:pet:999"; p.pets[pet.id]=pet end
			T.falsy(h.engine.validate(p))
		end)
	end
	T.test("M6 cosmetic: Gold entitlement is permanent, unique, fixed and account-bound",function()
		local h=H.new(); h.profile().gold=10000; local before=H.copy(h.profile()); T.truthy(h.gold("aurora_theme_v1")); T.truthy(h.profile().entitlements.aurora_theme)
		T.same(h.profile().pets,before.pets); T.same(h.profile().cauldrons,before.cauldrons); T.falsy(h.gold("aurora_theme_v1"))
		local gold=h.profile().gold; T.truthy(h.coordinator.syncPass(101,"aurora_theme_v1")); T.equal(h.profile().gold,gold)
	end)
end
