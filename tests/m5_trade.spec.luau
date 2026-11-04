--!nonstrict
local session=require("./TradeSessionHarness")
local H=require("./M5Harness")
local Config=require("../src/shared/Config")
local LongTerm=require("../src/shared/LongTerm")
local Dailies=require("../src/shared/Dailies")
local function fixture()
	local h=session(); local m=H.new(); m.profile=h.profile(101)
	-- Rich failure fixture; the separate F2P traces never inject balances.
	m.profile.gold,m.profile.essence=100000,100000; m.profile.longTerm.milestoneClaimed=true
	m.complete(); h.now=m.now; assert(h.stores[101]:save(101))
	local model=LongTerm.new(Config)
	function h.meta(action,payload)
		payload=H.copy(payload); payload.requestId=payload.requestId or h.profile(101).longTerm.sequence+1
		return h.stores[101]:transact(101,function(p)
			return model.apply(p,action,payload,h.engine,{now=h.now,tradeActive=h.session.current(101)~=nil,
				guard=function() return h.identities[101]~=nil and h.session.current(101)==nil end})
		end)
	end
	function h.reset() return h.meta("rebirth",{expectedRebirthCount=0,confirmed=true}) end
	return h
end
return function(T:any)
	T.test("M5/M4: transferred pet and cauldron ownership survive reset and a reverse trade",function()
		local h=fixture(); T.truthy(h.start()); T.truthy(h.checkOutcome())
		local p=h.profile(101); local pets,cauldrons,trade=H.copy(p.pets),H.copy(p.cauldrons),H.copy(p.trade)
		T.truthy(h.reset()); p=h.profile(101); T.same(p.pets,pets); T.same(p.cauldrons,cauldrons); T.same(p.trade,trade)
		local reverse=h.proposal(101,202,{{kind="cauldron",id="202:cauldron:1"}},{{kind="pet",id="101:pet:1"}})
		T.truthy(h.coordinator.start("trade-after-rebirth",reverse,function() return function() return true end end))
		T.same(h.profile(101).pets["101:pet:1"],h.original["101:pet:1"]); T.equal(h.profile(101).cauldrons["202:cauldron:1"],nil)
		T.same(h.profile(202).cauldrons["202:cauldron:1"],h.original["202:cauldron:1"])
		T.equal(h.profile(101).trade.sequence,2); T.equal(h.profile(101).longTerm.shards,1); h.oracle()
	end)
	for _,stage in ipairs({"invited","negotiating","ready"}) do
		T.test("M5/M4: live negotiation blocks reset before any journal exists / "..stage,function()
			local h=fixture()
			if stage=="invited" then T.truthy(h.call(101,"tradeInvite",{targetToken="token202"}))
			else h.negotiate(); if stage=="ready" then h.ready() end end
			local before=H.copy(h.records); T.falsy(h.reset()); T.same(h.records,before); T.equal(next(h.journals),nil)
			T.truthy(h.call(101,"tradeCancel")); T.truthy(h.reset()); T.equal(h.profile(101).longTerm.shards,1)
		end)
	end
	T.test("M5/M4: policy yield has already reserved the negotiation and prevents reset",function()
		local h=fixture(); local attempts=0
		h.onPolicy=function()
			attempts+=1; local before=H.copy(h.profile(101)); T.falsy(h.reset()); T.same(h.profile(101),before)
		end
		T.truthy(h.call(101,"tradeInvite",{targetToken="token202"})); T.equal(attempts,2); T.equal(h.profile(101).rebirths,0)
	end)
	T.test("M5/M4: pending reset write prevents invitation and publishes only confirmed inventory",function()
		local h=fixture(); local old=H.copy(h.profile(101)); local attempted=false
		h.valueOperation=true
		h.beforeUpdate=function(kind,key)
			if kind=="profile" and key=="p:101" then
				attempted=true; T.same(h.profile(101),old); T.falsy(h.stores[101]:isWritable(101))
				T.falsy(h.call(101,"tradeInvite",{targetToken="token202"})); T.equal(h.session.current(101),nil)
			end
		end
		T.truthy(h.reset()); T.truthy(attempted); h.beforeUpdate=nil; h.valueOperation=false
		h.negotiate(); local tradeId=h.session.current(101).id; h.ready(); T.truthy(h.confirm(101)); T.truthy(h.confirm(202))
		T.equal(h.journals["t:"..tradeId].state,"COMPLETE"); T.equal(h.profile(101).pets["101:pet:1"],nil)
		T.truthy(h.profile(202).pets["101:pet:1"]); T.truthy(h.profile(101).cauldrons["202:cauldron:1"]); h.oracle()
		T.equal(h.profile(101).rebirths,1); T.equal(h.profile(101).longTerm.shards,1)
	end)
	for _,action in ipairs({"rebirth","buyRebirthPerk","chooseRebirthPet","claimDaily","claimCalendar","deliverCalendarPet"}) do
		T.test("M5/M4: persistent reservation denies all meta commands / "..action,function()
			local h=fixture(); h.fault={at=h.calls+7,mode="after",sticky=true}; h.start(); h.offline=false; h.fault=nil
			T.truthy(h.profile(101).trade.pending); local before=H.copy(h.records)
			local payloads={rebirth={expectedRebirthCount=0,confirmed=true},buyRebirthPerk={perkId="industry",expectedLevel=0},
				chooseRebirthPet={offerId="moon_cat",confirmed=true},claimDaily={questId="essence",expectedDay=Dailies.day(h.now)},
				claimCalendar={expectedDay=Dailies.day(h.now)},deliverCalendarPet={}}
			T.falsy(h.meta(action,payloads[action])); T.same(h.records,before)
			h.restart(); T.truthy(h.recover()); T.truthy(h.checkOutcome()); h.load(101); T.truthy(h.reset())
		end)
	end
	T.test("M5/M4: fixed shard pet carries paid-origin metadata into normal trade restrictions",function()
		local h=fixture(); T.truthy(h.reset()); local p=h.profile(101); p.longTerm.shardsPaid=true
		local ok,result=h.meta("chooseRebirthPet",{offerId="moon_cat",confirmed=true}); T.truthy(ok)
		local pet=h.profile(101).pets[result.petId]; T.truthy(pet.paidOrigin); T.truthy(pet.provenance.paidDerived)
		T.truthy(h.model.item(h.profile(101),"pet",result.petId)) -- Known paid ancestry is retained; both-party policy is the admission gate.
		h.policies[202].tradingAllowed=false; T.falsy(h.call(101,"tradeInvite",{targetToken="token202"}))
		T.truthy(h.profile(101).pets[result.petId]); T.equal(h.session.current(101),nil)
	end)
end
