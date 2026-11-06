--!nonstrict
-- Isolated fake platform + durable multi-key backend. Never installed in a Roblox place.
local Config=require("../src/shared/Config")
local Factory=require("../src/shared/Factory")
local C=require("../src/shared/TradeCodec")
local Catalog=require("../src/shared/OfferCatalog")
local Model=require("../src/shared/Monetization")
local Store=require("../src/server/ProfileStore")
local Journal=require("../src/server/ReceiptJournal")
local Coordinator=require("../src/server/PurchaseCoordinator")
local H={copy=C.copy,hash=C.sha256,Config=Config,Journal=Journal}
function H.count(t) local n=0; for _ in pairs(t) do n+=1 end; return n end
function H.new(config)
	config=config or Config
	local h={now=config.events.spectral_2026.startAtUtc,calls=0,records={},journals={},events={},identities={[101]={}},owns=true}
	h.engine,h.model=Factory.new(config),Model.new(config)
	h.records["p:101"]={schemaVersion=1,revision=1,profile=h.engine.newProfile(101,h.now)}
	h.engine.grantHistoricalStarters(h.records["p:101"].profile)
	h.skus={ghost_wolf_v1=1001,spectral_cauldron_v1=1002,aurora_theme_v1=2001}
	h.catalog=Catalog.new(config,h.skus)
	h.receipt={PlayerId=101,ProductId=1001,PurchaseId="purchase-0001"}
	function h.oracle()
		local paid={}
		for _,r in pairs(h.records) do
			assert(h.engine.validate(r.profile))
			for _,inventory in ipairs({r.profile.pets,r.profile.cauldrons}) do for _,item in pairs(inventory) do
				local hash=item.provenance.purchaseHash
				if hash then paid[hash]=(paid[hash] or 0)+1; assert(paid[hash]<=1,"Duplicate paid instance") end
			end end
		end
		for key,r in pairs(h.journals) do if string.sub(key,1,2)=="r:" and r.state=="APPLIED" then
			assert(h.records["p:"..r.userId].profile.monetization.receipts[r.keyHash],"Ack without durable right")
		end end
	end
	local function backend(records,kind)
		local b={}
		function b:UpdateAsync(key,fn)
			h.calls+=1; local call=h.calls
			if h.offline then error("backend unavailable") end
			if h.fault and h.fault.at==call and h.fault.mode=="before" then h.offline=h.fault.sticky; error("before write") end
			if h.beforeUpdate then h.beforeUpdate(kind,key) end
			for _=1,h.replays or 0 do fn(C.copy(records[key])) end
			local result=fn(C.copy(records[key])); if result then records[key]=C.copy(result) end
			table.insert(h.events,{kind=kind,key=key,call=call,state=result and result.state})
			h.oracle()
			if h.afterUpdate then h.afterUpdate(kind,key) end
			if h.fault and h.fault.at==call and h.fault.mode=="after" then h.offline=h.fault.sticky; error("lost write reply") end
			return C.copy(result)
		end
		return b
	end
	h.backend,h.journalBackend=backend(h.records,"profile"),backend(h.journals,"journal")
	function h.newStore(owner)
		return Store.new({dataStore=h.backend,owner=owner,now=function() return h.now end,sleep=function() end,validate=h.engine.validate,migrate=h.engine.migrate})
	end
	function h.load(owner)
		h.store=h.newStore(owner or "server:A")
		assert(h.store:loadExisting(101,function() return h.engine.newProfile(101,h.now) end))
	end
	h.load()
	function h.profile() return h.store:get(101) end
	function h.mutate(fn)
		if not h.identities[101] or h.busy then return false,"Player unavailable or operation busy" end
		return h.store:transact(101,function(p) return fn(p,{now=h.now,tradeActive=h.tradeActive,guard=function() return h.identities[101]~=nil end}) end)
	end
	h.journal=Journal.new({backend=h.journalBackend,sleep=function() end})
	h.coordinator=Coordinator.new({catalog=h.catalog,model=h.model,journal=h.journal,engine=h.engine,
		transact=function(uid,fn) if uid~=101 then return false,"Absent player" end; return h.mutate(fn) end,
		identity=function(uid) return h.identities[uid] end,
		ownsPass=function(uid,pass) assert(uid==101 and pass==2001); if h.onOwnership then h.onOwnership() end; if h.owns=="error" then error("Policy/API unavailable") end; return h.owns end})
	function h.process(receipt) return h.coordinator.process(receipt or h.receipt) end
	function h.action(action,payload)
		payload=C.copy(payload or {}); payload.requestId=payload.requestId or h.profile().monetization.sequence+1
		return h.mutate(function(p,ctx) return h.model.apply(p,action,payload,h.engine,ctx) end)
	end
	function h.gold(id) return h.action("buyEventGold",{offerId=id or "ghost_wolf_v1",confirmed=true}) end
	function h.restart()
		h.offline=false; h.fault=nil; h.beforeUpdate=nil; h.afterUpdate=nil; h.now+=181; h.identities[101]={}; h.load("server:B")
	end
	function h.fill(kind)
		local p=h.profile(); p.gold=1000000 -- Rich capacity fixture, never used in earned-economy scenarios.
		local offer=kind=="pet" and "ghost_wolf_v1" or "spectral_cauldron_v1"
		local target=kind=="pet" and config.maxPets or config.trading.maxCauldrons
		while H.count(kind=="pet" and p.pets or p.cauldrons)<target do
			assert(h.model.apply(p,"buyEventGold",{offerId=offer,confirmed=true,requestId=p.monetization.sequence+1},h.engine,{now=h.now}))
		end
		assert(h.store:save(101))
	end
	h.calls=0; h.events={}
	return h
end
return H
