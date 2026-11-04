--!nonstrict
local H=require("./M4Harness")
local C=require("../src/shared/TradeCodec")
local Config=require("../src/shared/Config")
local Trading=require("../src/shared/Trading")
local Collection=require("../src/shared/Collection")
local Progression=require("../src/shared/Progression")
local Familiars=require("../src/shared/Familiars")
local Protocol=require("../src/shared/Protocol")
local M2=require("./M2Harness")
local Policy=require("../src/shared/Policy")
return function(T: any)
	for _,defect in ipairs({"foreign","locked","assigned","starter","legacy","unknown-origin","cauldron-owner","cauldron-bonus","equipped","duplicate","currency","seven"}) do
		T.test("M4: reject unusable/forged offers without inventory mutation / "..defect,function()
			local h=H.new(); local a,b=h.profile(101),h.profile(202); local items={{kind="pet",id="101:pet:1"}}
			if defect=="foreign" then items[1].id="202:pet:1"
			elseif defect=="locked" then a.pets[items[1].id].locked=true
			elseif defect=="assigned" then a.stations.logistics.workerId=items[1].id
			elseif defect=="starter" then items[1].id="101:starter_farmer"
			elseif defect=="legacy" then Familiars.new(Config).upgradeLegacy(a.pets[items[1].id])
			elseif defect=="unknown-origin" then a.pets[items[1].id].provenance=nil
			elseif defect=="cauldron-owner" then items={{kind="cauldron",id="101:cauldron:1"}}; a.cauldrons[items[1].id].ownerId=202
			elseif defect=="cauldron-bonus" then items={{kind="cauldron",id="101:cauldron:1"}}; a.cauldrons[items[1].id].bonus=1
			elseif defect=="equipped" then items={{kind="cauldron",id="101:cauldron:1"}}; a.stations.cauldron.cauldronId=items[1].id
			elseif defect=="duplicate" then items[2]=C.copy(items[1])
			elseif defect=="currency" then items={{kind="gold",id="balance"}}
			else for i=2,7 do items[i]=C.copy(items[1]) end end
			local before=C.copy(a); T.equal(h.model.proposal(a,b,items,{},1),nil); T.same(a,before)
		end)
	end
	for _,shape in ipairs({"1:1","2:1","3:2","gift"}) do
		T.test("M4: bounded multi-item and gift conservation / "..shape,function()
			local h=H.new(); local x={{kind="pet",id="101:pet:1"}}; local y={{kind="pet",id="202:pet:1"}}
			if shape=="2:1" or shape=="3:2" then table.insert(x,{kind="cauldron",id="101:cauldron:1"}) end
			if shape=="3:2" then table.insert(x,{kind="pet",id="101:pet:2"}); table.insert(y,{kind="cauldron",id="202:cauldron:1"}) end
			if shape=="gift" then y={} end
			local a,b=h.profile(101),h.profile(202); a.pets["101:pet:1"].paidOrigin=true; a.pets["101:pet:1"].provenance.paidDerived=true; a.slimeWorkSeconds["101:pet:1"]=23
			local proposal=h.proposal(101,202,x,y); T.truthy(h.start(proposal)); h.oracle()
			for _,item in ipairs(x) do local inventory=item.kind=="pet" and h.profile(202).pets or h.profile(202).cauldrons; T.truthy(inventory[item.id]); T.equal(inventory[item.id].id,item.id) end
			T.truthy(h.profile(202).pets["101:pet:1"].provenance.paidDerived); T.equal(h.profile(202).slimeWorkSeconds["101:pet:1"],23)
			T.truthy(a.pets["101:starter_farmer"]); T.truthy(b.pets["202:starter_farmer"])
		end)
	end
	T.test("M4: capacity uses simultaneous incoming/outgoing and rejects collisions",function()
		local h=H.new(); local a,b=h.profile(101),h.profile(202); local f=Familiars.new(Config)
		for i=6,128 do local id="202:extra:"..i; b.pets[id]=f.create(id,"slime",Config.familiarShop.slime.stats,"shop",false) end
		T.truthy(h.engine.validate(b)); T.equal(h.model.proposal(a,b,{{kind="pet",id="101:pet:1"}},{},1),nil)
		T.truthy(h.model.proposal(a,b,{{kind="pet",id="101:pet:1"}},{{kind="pet",id="202:pet:1"}},1))
		b.pets["101:pet:1"]=C.copy(a.pets["101:pet:1"])
		T.equal(h.model.proposal(a,b,{{kind="pet",id="101:pet:1"}},{{kind="pet",id="202:pet:1"}},1),nil)
	end)
	T.test("M4: rare cauldron net capacity cannot overflow",function()
		local h=H.new(); local a,b=h.profile(101),h.profile(202)
		for i=2,16 do local item=C.copy(b.cauldrons["202:cauldron:1"]); item.id="202:cauldron:"..i; b.cauldrons[item.id]=item end
		T.equal(h.model.proposal(a,b,{{kind="cauldron",id="101:cauldron:1"}},{},1),nil)
		T.truthy(h.model.proposal(a,b,{{kind="cauldron",id="101:cauldron:1"}},{{kind="cauldron",id="202:cauldron:1"}},1))
	end)
	T.test("M4: persistent reservation blocks every economic path and stale saves",function()
		local h=H.new(); local proposal=h.proposal()
		local j={id="reserved",hash=C.hash(proposal),state="PREPARING",deadline=h.now+120,sides=proposal.sides}
		T.truthy(h.stores[101]:transactTrade(101,function(p) return h.model.reserve(p,j,1,h.now) end))
		local a=h.profile(101); local before=C.copy(a)
		for _,action in ipairs({"click","assign","buy","harvest","load","brew","setRecipe","acceptOrder","prioritize","hire"}) do T.falsy(h.engine.act(a,action,{},h.now+1)) end
		T.falsy(h.engine.advance(a,h.now+7200,true).ok)
		for _,action in ipairs({"summon","shopFamiliar","hire","fuse","petLock"}) do T.falsy(Collection.new(Config).apply(a,action,{},{})) end
		for _,action in ipairs({"build","advancePhase","equipCauldron","lockCauldron"}) do T.falsy(Progression.new(Config).apply(a,action,{},h.engine,h.now)) end
		T.equal(Familiars.new(Config).preview(a,{}),nil); T.falsy(h.stores[101]:isWritable(101)); T.truthy(h.stores[101]:hasLease(101))
		T.falsy(h.stores[101]:transact(101,function(p) p.gold+=1; return true,{} end)); T.same(a,before)
		T.truthy(h.stores[101]:save(101)); local durable=C.copy(h.records["p:101"])
		a.trade.pending=nil; a.trade.last={id=j.id,hash=j.hash,sequence=1,decision="ABORT"}
		T.falsy(h.stores[101]:save(101)); T.same(h.records["p:101"],durable)
	end)
	for _,field in ipairs({"ownerId","price","stats","paidDerived","position","reward","decision","timestamp"}) do
		T.test("M4: exact Remote shape rejects forged field / "..field,function()
			local payload={tradeId="abc",version=1,items={{kind="pet",id="101:pet:1"}}}; payload[field]=1
			T.falsy(Protocol.validate("tradeOffer",payload)); payload[field]=nil; payload.items[1][field]=1
			T.falsy(Protocol.validate("tradeOffer",payload))
		end)
	end
	for _,case in ipairs({"allowed","restricted","missing","expired","failure","random-only"}) do
		T.test("M4 policy: explicit trading permission for all provenance / "..case,function()
			local p={tradingKnown=true,tradingAllowed=true,expiresAt=100,status="unrestricted"}
			if case=="restricted" then p.tradingAllowed=false elseif case=="missing" then p.tradingKnown=false
			elseif case=="expired" then p.expiresAt=50 elseif case=="failure" then p={} elseif case=="random-only" then p.status="restricted"; p.randomAllowed=false end
			T.equal(Trading.policyAllowed(p,50),case=="allowed" or case=="random-only")
		end)
	end
	for _,ancestry in ipairs({"known-paid","legacy-parent","historical-fuse"}) do
		T.test("M4: Fuse retains paid ancestry and cannot launder unknown origin / "..ancestry,function()
			local h=M2.new(); h.profile.currencyPaid.gold=true; local ids=h.buyFive("slime")
			if ancestry=="legacy-parent" then Familiars.new(Config).upgradeLegacy(h.profile.pets[ids[1]]) end
			local preview=h.preview(ids); local ok,result=h.apply("fuse",{petIds=ids,previewToken=preview.token,confirmed=true},h.context(preview))
			T.truthy(ok); local item=h.profile.pets[result.createdIds[1]]; T.truthy(item.provenance.paidDerived)
			if ancestry=="historical-fuse" then item.provenance.tradeKnown=nil end
			local offer=Trading.new(Config).item(h.profile,"pet",item.id)
			T.equal(offer~=nil,ancestry=="known-paid")
			if ancestry=="legacy-parent" then T.equal(item.provenance.tradeKnown,false) end
		end)
	end
	T.test("M4: transferred strong familiar retains origin ID and recipient station cap",function()
		local h=H.new(); local id="101:pet:1"
		h.profile(101).pets[id]=Familiars.new(Config).create(id,"aether_sprite",{Farming=100,Hauling=100,Brewing=100},"gacha",false)
		T.truthy(h.start()); local recipient=h.profile(202)
		T.truthy(h.engine.act(recipient,"assign",{stationId="cauldron",petId=id},h.now))
		T.equal(h.engine.stationState(recipient,"cauldron").effectiveSkill,15); T.equal(recipient.pets[id].stats.Brewing,100)
		T.equal(recipient.pets[id].id,id)
	end)
	T.test("M4 policy: forced lookup cannot reuse an older cached permission when superseded",function()
		local calls=0
		local policy=Policy.new({now=function() return 100 end,ttl=60,lookup=function()
			calls+=1; local call=calls
			if call>1 then coroutine.yield() end
			return {ArePaidRandomItemsRestricted=false,IsPaidItemTradingAllowed=call~=3}
		end})
		T.truthy(Trading.policyAllowed(policy.get("A"),100))
		local first,second
		local a=coroutine.create(function() first=policy.get("A",true) end)
		local b=coroutine.create(function() second=policy.get("A",true) end)
		T.truthy(coroutine.resume(a)); T.truthy(coroutine.resume(b)); T.truthy(coroutine.resume(a))
		T.falsy(Trading.policyAllowed(first,100)); T.truthy(coroutine.resume(b)); T.falsy(Trading.policyAllowed(second,100))
	end)
end
