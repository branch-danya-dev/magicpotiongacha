--!nonstrict
local H=require("./M4Harness")
local C=require("../src/shared/TradeCodec")
local Config=require("../src/shared/Config")
return function(T: any)
	T.test("M4: SHA-256 known vectors and canonical field order",function()
		T.equal(C.sha256(""),"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
		T.equal(C.sha256("abc"),"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
		T.equal(C.sha256(string.rep("a",1000000)),"cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0")
		T.equal(C.hash({a=1,b={x="v"}}),C.hash({b={x="v"},a=1}))
		T.truthy(C.hash({a="1"})~=C.hash({a=1}))
	end)
	local baseline=H.new(); assert(baseline.start()); local steps=baseline.calls
	T.test("M4: durable item exchange preserves IDs/metadata and acknowledges both",function()
		T.truthy(baseline.checkOutcome()); T.equal(baseline.journals["t:trade-uuid-1"].state,"COMPLETE")
		T.same(baseline.profile(202).pets["101:pet:1"],baseline.original["101:pet:1"])
		T.equal(baseline.profile(101).gold,0); T.equal(baseline.profile(202).essence,0)
		local before=C.copy(baseline.records); T.truthy(baseline.recover()); T.same(baseline.records,before)
		print("M4_PROTOCOL normal journal/profile requests="..steps)
	end)
	for call=1,steps do
		for _,mode in ipairs({"before","after"}) do
			T.test("M4 crash oracle at every durable boundary / "..call.."/"..mode,function()
				local h=H.new(); local old=h.stores[101]; h.replays=2
				h.fault={at=call,mode=mode,sticky=true}; h.start(); h.oracle()
				h.restart(); T.truthy(h.recover()); h.checkOutcome()
				local before=C.copy(h.records); T.falsy(old:save(101)); T.same(h.records,before)
				T.truthy(h.recover()); T.same(h.records,before)
			end)
		end
	end
	for call=1,steps do
		T.test("M4: transient lost reply is idempotent / "..call,function()
			local h=H.new(); h.replays=3; h.fault={at=call,mode="after",sticky=false}
			h.start(); h.restart(); T.truthy(h.recover()); h.checkOutcome()
		end)
	end
	local function recoveryFixture()
		local h=H.new(); h.fault={at=7,mode="after",sticky=true}; h.start(); h.restart(); h.calls=0
		return h
	end
	local recovered=recoveryFixture(); assert(recovered.recover()); local recoverySteps=recovered.calls
	T.test("M4: absent-player recovery has bounded lease/write/release work",function()
		T.truthy(recovered.checkOutcome()); T.equal(next(recovered.stores),nil)
		print("M4_PROTOCOL absent-profile recovery requests="..recoverySteps)
	end)
	for call=1,recoverySteps do
		for _,mode in ipairs({"before","after"}) do
			T.test("M4 recovery crash oracle including absent-profile leases / "..call.."/"..mode,function()
				local h=recoveryFixture(); h.replays=2; h.fault={at=call,mode=mode,sticky=true}
				h.recover(); h.oracle(); h.restart(); T.truthy(h.recover()); T.truthy(h.checkOutcome())
				local before=C.copy(h.records); T.truthy(h.recover()); T.same(h.records,before)
			end)
		end
	end
	T.test("M4: decision denial aborts and fences delayed prepares on both sides",function()
		local h=H.new(); local proposal=h.proposal(); h.denyCommit=true
		T.truthy(h.start(proposal)); T.falsy(h.checkOutcome())
		local old={id="trade-uuid-1",state="PREPARING",hash=C.hash(proposal),sides=proposal.sides,deadline=h.now+120}
		for index,side in ipairs(proposal.sides) do
			T.falsy(h.model.reserve(h.profile(side.userId),old,index,h.now))
		end
	end)
	T.test("M4: abort barrier also fences a side never prepared",function()
		local h=H.new(); local proposal=h.proposal(); local now=h.now
		local j={schemaVersion=1,id="trade-uuid-1",coordinator="server:A",version=1,hash=C.hash(proposal),sides=proposal.sides,
			createdAt=now,deadline=now+120,state="PREPARING",prepared={},applied={},cleared={}}
		T.truthy(h.journal.create(j)); T.truthy(h.coordinator.recover(j.id,"server:A"))
		for index,side in ipairs(j.sides) do T.falsy(h.model.reserve(h.profile(side.userId),j,index,now)) end
		T.falsy(h.checkOutcome())
	end)
	T.test("M4: absent users settle through recovery leases without logging in",function()
		local h=H.new(); local proposal=h.proposal(); h.fault={at=7,mode="after",sticky=true}
		h.start(proposal); h.restart(); T.truthy(h.recover()); h.checkOutcome(); T.equal(next(h.stores),nil)
	end)
	T.test("M4: recovery refuses foreign live lease and missing profile",function()
		local h=H.new(); h.fault={at=7,mode="after",sticky=true}; h.start(); h.offline=false; h.fault=nil; h.stores={}
		local before=C.copy(h.records); T.falsy(h.recover()); T.same(h.records,before)
		h.now+=181; T.truthy(h.recover()); h.checkOutcome()
		local s=h.newStore("missing"); T.equal(s:loadExisting(999,function() return h.engine.newProfile(999,h.now) end),nil)
		T.equal(h.records["p:999"],nil)
	end)
	T.test("M4: completed journal compacts, retains audit then expires without recreation",function()
		local h=H.new(); local proposal=h.proposal(); T.truthy(h.start(proposal))
		local j=h.journals["t:trade-uuid-1"]; T.equal(j.sides[1].items,nil); T.falsy(h.journal.collect(j.id))
		h.now+=Config.trading.retentionSeconds+121; T.truthy(h.journal.collect(j.id)); T.equal(h.journals["t:"..j.id],nil)
		for _,registry in pairs(h.journals) do T.equal(next(registry.entries),nil) end
		local old={schemaVersion=1,id=j.id,coordinator=j.coordinator,version=1,hash=j.hash,sides=proposal.sides,
			createdAt=j.createdAt,deadline=j.deadline,state="PREPARING",prepared={},applied={},cleared={}}
		T.equal(h.journal.create(old),nil); T.falsy(h.coordinator.recover(j.id)); h.oracle()
	end)
	T.test("M4: budget exhaustion cannot change ownership or delete reservations",function()
		local h=H.new(); h.noBudget=true; local before=C.copy(h.records)
		T.falsy(h.start()); T.same(h.records,before); T.equal(next(h.journals),nil)
		h.noBudget=false; T.truthy(h.start()); T.truthy(h.checkOutcome())
	end)
	for _,first in ipairs({101,202}) do
		T.test("M4: new-server login stays frozen until both profiles settle / "..first,function()
			local h=H.new(); h.fault={at=8,mode="after",sticky=true}; h.start(); h.restart()
			local p=h.load(first); T.truthy(p.trade.pending); T.falsy(h.stores[first]:isWritable(first))
			T.falsy(h.engine.act(p,"click",{},h.now)); T.truthy(h.recover()); h.checkOutcome()
			T.truthy(h.stores[first]:isWritable(first)); h.load(first==101 and 202 or 101); h.checkOutcome()
		end)
	end
	T.test("M4: overlapping journal cannot reserve the same item or disturb the first reservation",function()
		local h=H.new(); local proposal=h.proposal(); local other=h.proposal(101,303,{{kind="pet",id="101:pet:1"}},{{kind="pet",id="303:pet:1"}})
		local j={schemaVersion=1,id="trade-uuid-1",coordinator="server:A",version=1,hash=C.hash(proposal),sides=proposal.sides,
			createdAt=h.now,deadline=h.now+120,state="PREPARING",prepared={},applied={},cleared={}}
		T.truthy(h.journal.create(j)); T.truthy(h.stores[101]:transactTrade(101,function(p) return h.model.reserve(p,j,1,h.now) end)); T.truthy(h.journal.prepared(j.id,1))
		T.falsy(h.coordinator.start("other-trade",other,function() return function() return true end end))
		T.equal(h.profile(101).trade.pending.id,j.id); T.equal(h.journals["t:other-trade"].decision,"ABORT")
		T.truthy(h.start(proposal)); T.truthy(h.checkOutcome())
	end)
	T.test("M4: abort racing a delayed second prepare fences both sides",function()
		local h=H.new(); local entered=false
		h.beforeUpdate=function(kind,key)
			if kind=="profile" and key=="p:202" and not entered then entered=true; T.truthy(h.journal.decide("trade-uuid-1","ABORT","server:A")) end
		end
		T.truthy(h.start()); T.falsy(h.checkOutcome())
	end)
	T.test("M4: durable scanner advances fixed registry shards instead of starving later journals",function()
		local h=H.new(); local proposal=h.proposal(); T.truthy(h.start()); local template=h.journals["t:trade-uuid-1"]
		for i=2,7 do
			local j={schemaVersion=1,id="trade-uuid-"..i,coordinator=template.coordinator,version=1,hash=template.hash,sides=proposal.sides,
				createdAt=h.now,deadline=h.now+120,state="PREPARING",prepared={},applied={},cleared={}}
			T.truthy(h.journal.create(j))
		end
		local seen={}; for _=1,7 do local id=h.journal.nextKey(); T.truthy(id); seen[id]=true end
		local n=0; for _ in pairs(seen) do n+=1 end; T.equal(n,7)
	end)
	T.test("M4: corrupt/missing journal never unlocks a loaded pending profile",function()
		local h=H.new(); h.fault={at=4,mode="before",sticky=true}; h.start(); h.restart()
		local p=h.load(101); T.truthy(p.trade.pending)
		local old=h.journals["t:trade-uuid-1"]; h.journals["t:trade-uuid-1"]=nil
		T.falsy(h.coordinator.recover("trade-uuid-1")); T.truthy(h.profile(101).trade.pending); T.falsy(h.stores[101]:isWritable(101))
		h.journals["t:trade-uuid-1"]=old; T.truthy(h.recover()); T.falsy(h.checkOutcome())
	end)
	T.test("M4: a delayed profile callback cannot write with an expired dispatch-time lease",function()
		local h=H.new(); local before=C.copy(h.records["p:101"]); local entered=false
		h.beforeUpdate=function(kind,key) if kind=="profile" and key=="p:101" and not entered then entered=true; h.now+=121 end end
		T.falsy(h.stores[101]:transactTrade(101,function(p) p.gold+=1; return true,{} end))
		T.same(h.records["p:101"],before); T.falsy(h.stores[101]:isWritable(101))
	end)
	T.test("M4: bounded registry refuses admission before touching another profile",function()
		local h=H.new({shards=1,capacity=1}); T.truthy(h.start()); local before=C.copy(h.records)
		local ok,reason=h.coordinator.start("another-trade",h.proposal(202,101,{{kind="pet",id="101:pet:1"}},{{kind="cauldron",id="202:cauldron:1"}}),function() return function() return true end end)
		T.falsy(ok); T.equal(reason,"Recovery registry full; new trades paused"); T.same(h.records,before); T.equal(h.journals["t:another-trade"],nil)
	end)
	T.test("M4: registry orphan survives lost registration reply and expires only after creation deadline",function()
		local h=H.new(); h.fault={at=1,mode="after",sticky=true}; T.falsy(h.start())
		h.offline=false; h.fault=nil
		local id,entry=h.journal.nextKey(); T.equal(id,"trade-uuid-1"); T.equal(h.journals["t:"..id],nil)
		T.falsy(h.journal.cleanMissing(id,entry)); h.now+=121; T.truthy(h.journal.cleanMissing(id,entry))
		T.equal(h.journal.nextKey(),nil); h.checkOutcome()
	end)
	T.test("M4: unknown GC delete outcome cannot recreate a completed exchange",function()
		local h=H.new(); T.truthy(h.start()); local original=h.journalBackend.RemoveAsync
		h.journalBackend.RemoveAsync=function(self,key) original(self,key); error("lost delete reply") end
		h.now+=Config.trading.retentionSeconds+121; T.falsy(h.journal.collect("trade-uuid-1"))
		local id,entry=h.journal.nextKey(); T.equal(id,"trade-uuid-1"); T.truthy(h.journal.cleanMissing(id,entry))
		T.equal(h.journal.nextKey(),nil); h.oracle()
	end)
	T.test("M4: delayed journal creation after orphan cleanup cannot escape the registry",function()
		local h=H.new(); local entered=false
		h.beforeUpdate=function(kind,key)
			if kind=="journal" and key=="t:trade-uuid-1" and not entered then
				entered=true; h.now+=121; local id,entry=h.journal.nextKey(); T.truthy(h.journal.cleanMissing(id,entry))
			end
		end
		T.falsy(h.start()); T.equal(h.journals["t:trade-uuid-1"],nil); T.equal(h.journal.nextKey(),nil); h.checkOutcome()
	end)
end
