--!nonstrict
local Config=require("../src/shared/Config")
local Factory=require("../src/shared/Factory")
local Familiars=require("../src/shared/Familiars")
local Trading=require("../src/shared/Trading")
local C=require("../src/shared/TradeCodec")
local ProfileStore=require("../src/server/ProfileStore")
local Journal=require("../src/server/TradeJournal")
local Coordinator=require("../src/server/TradeCoordinator")
local H={copy=C.copy}
function H.new(options)
	options=options or {}
	local h={now=100000,calls=0,events={},records={},journals={},stores={},serial=0,original={}}
	h.engine,h.model=Factory.new(Config),Trading.new(Config)
	local familiar=Familiars.new(Config)
	for _,userId in ipairs(options.users or {101,202,303}) do
		local p=h.engine.newProfile(userId,h.now)
		for i,species in ipairs({"slime","brewer"}) do
			local id=tostring(userId)..":pet:"..i
			p.pets[id]=familiar.create(id,species,Config.familiarShop[species].stats,"shop",false)
			h.original[id]=C.copy(p.pets[id])
		end
		p.nextPetSerial=3
		local id=tostring(userId)..":cauldron:1"
		p.cauldrons[id]={id=id,ownerId=userId,type="resonant",bonus=0.05,locked=false,provenance={source="phase3",paidDerived=false}}
		p.nextCauldronSerial=2; h.original[id]=C.copy(p.cauldrons[id])
		assert(h.engine.validate(p)); h.records["p:"..userId]={schemaVersion=1,revision=1,profile=p}
	end
	function h.oracle()
		local available,present={},{}
		for _,record in pairs(h.records) do
			assert(h.engine.validate(record.profile))
			for _,inventory in ipairs({record.profile.pets,record.profile.cauldrons}) do
				for id in pairs(inventory) do
					present[id]=true
					if not Trading.frozen(record.profile) then available[id]=(available[id] or 0)+1; assert(available[id]<=1,"Dual-use item: "..id) end
				end
			end
		end
		for key,j in pairs(h.journals) do
			if string.sub(key,1,2)=="t:" then
				assert(h.model.validateJournal(j))
				for _,side in ipairs(j.sides) do for _,item in ipairs(side.items or {}) do present[item.id]=true end end
			end
		end
		for id in pairs(h.original) do assert(present[id],"Irrecoverably missing: "..id) end
	end
	local function backend(records,kind)
		local b={}
		function b:UpdateAsync(key,transform)
			h.calls+=1; local call=h.calls
			if h.offline then error("process/backend unavailable") end
			if h.fault and h.fault.at==call and h.fault.mode=="before" then h.offline=h.fault.sticky; error("before write") end
			if h.beforeUpdate then h.beforeUpdate(kind,key) end
			for _=1,h.replays or 0 do transform(C.copy(records[key])) end
			local result=transform(C.copy(records[key]))
			if result then records[key]=C.copy(result) end
			table.insert(h.events,{kind=kind,key=key,state=result and (result.state or (result.profile and result.profile.trade.pending and result.profile.trade.pending.stage) or "record"),call=call})
			h.oracle()
			if h.fault and h.fault.at==call and h.fault.mode=="after" then h.offline=h.fault.sticky; error("lost response") end
			return C.copy(result)
		end
		function b:RemoveAsync(key) records[key]=nil end
		return b
	end
	h.backend=backend(h.records,"profile"); h.journalBackend=backend(h.journals,"journal")
	function h.newStore(owner)
		return ProfileStore.new({dataStore=h.backend,owner=owner,now=function() return h.now end,sleep=function() end,validate=h.engine.validate,migrate=h.engine.migrate})
	end
	function h.load(userId)
		local store=h.newStore("live:"..userId); h.stores[userId]=store
		assert(store:loadExisting(userId,function() return h.engine.newProfile(userId,h.now) end)); return store:get(userId)
	end
	h.load(101); h.load(202)
	function h.profile(id) return h.stores[id] and h.stores[id]:get(id) or h.records["p:"..id].profile end
	local port={}
	function port.mutate(userId,transform)
		local store=h.stores[userId]
		if store then return store:transactTrade(userId,transform) end
		h.serial+=1; store=h.newStore("recovery:"..h.serial)
		local p,reason=store:loadExisting(userId,function() return h.engine.newProfile(userId,h.now) end)
		if not p then return false,reason end
		local ok,result=store:transactTrade(userId,transform)
		local released=store:release(userId)
		return ok and released,result
	end
	h.journal=Journal.new({backend=h.journalBackend,now=function() return h.now end,sleep=function() end,validate=h.model.validateJournal,
		retentionSeconds=Config.trading.retentionSeconds,shards=options.shards or Config.trading.journalShards,capacity=options.capacity or Config.trading.journalCapacity,budget=function() return not h.noBudget end})
	h.coordinator=Coordinator.new({journal=h.journal,model=h.model,profiles=port,now=function() return h.now end,owner="server:A",prepareSeconds=Config.trading.prepareSeconds})
	function h.proposal(a,b,x,y)
		return assert(h.model.proposal(h.profile(a or 101),h.profile(b or 202),x or {{kind="pet",id="101:pet:1"}},y or {{kind="cauldron",id="202:cauldron:1"}},1))
	end
	function h.start(proposal)
		return h.coordinator.start("trade-uuid-1",proposal or h.proposal(),function() return function() return not h.denyCommit end end)
	end
	function h.restart()
		h.offline=false; h.fault=nil; h.now+=181; h.stores={}; h.beforeUpdate=nil
	end
	function h.recover()
		if not h.journals["t:trade-uuid-1"] then return true,"never created" end
		return h.coordinator.recover("trade-uuid-1")
	end
	function h.checkOutcome()
		h.oracle(); local j=h.journals["t:trade-uuid-1"]
		local committed=j~=nil and j.decision=="COMMIT"
		local a,b=h.records["p:101"].profile,h.records["p:202"].profile
		assert(not a.trade.pending and not b.trade.pending)
		assert((a.pets["101:pet:1"]==nil)==committed)
		assert((b.pets["101:pet:1"]~=nil)==committed)
		assert((a.cauldrons["202:cauldron:1"]~=nil)==committed)
		assert((b.cauldrons["202:cauldron:1"]==nil)==committed)
		if committed then assert(a.cauldrons["202:cauldron:1"].ownerId==101) end
		return committed
	end
	h.calls=0; h.events={}
	return h
end
return H
