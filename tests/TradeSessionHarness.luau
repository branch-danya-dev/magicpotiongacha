--!nonstrict
local H=require("./M4Harness")
local Config=require("../src/shared/Config")
local Session=require("../src/shared/TradeSession")
local C=require("../src/shared/TradeCodec")
return function(users)
	users=users or {101,202,303}
	local h=H.new({users=users}); for _,uid in ipairs(users) do if not h.stores[uid] then h.load(uid) end end
	h.enabled=true; h.identities={}; h.positions={}; h.policies={}; h.views={}; h.forced=0; h.uuidSerial=0
	for _,uid in ipairs(users) do h.identities[uid]={id=uid}; h.positions[uid]=true; h.policies[uid]={tradingKnown=true,tradingAllowed=true,expiresAt=h.now+60,status="unrestricted"} end
	h.session=Session.new({config=Config,model=h.model,enabled=function() return h.enabled end,now=function() return h.now end,
		identity=function(uid) return h.identities[uid] end,name=function(uid) return "Player "..uid end,
		resolve=function(token) for uid in pairs(h.identities) do if token=="token"..uid then return uid end end; return nil end,
		uuid=function() h.uuidSerial+=1; return "trade-uuid-"..h.uuidSerial end,
		inBazaar=function(uid) return h.positions[uid]==true end,profile=h.profile,
		writable=function(uid) return h.stores[uid] and h.stores[uid]:isWritable(uid) and not h.valueOperation end,
		leaseActive=function(uid) return h.stores[uid] and h.stores[uid]:hasLease(uid) end,
		canStart=function() return not h.noBudget end,
		policy=function(uid,force)
			if force then h.forced+=1 end
			if h.onPolicy then h.onPolicy(uid,force) end
			return C.copy(h.policies[uid])
		end,
		commit=h.coordinator.start,recover=function(id,cancel) return h.coordinator.recover(id,cancel and "server:A" or nil) end,
		changed=function(t) if h.presentationFailure then error("presentation unavailable") end; for _,side in ipairs(t.sides) do h.views[side.userId]=h.session.view(t,side.userId) end end,
	})
	function h.call(uid,action,payload)
		payload=C.copy(payload or {})
		if action~="tradeInvite" then local t=h.session.current(uid); payload.tradeId=payload.tradeId or (t and t.id); payload.version=payload.version or (t and t.version) end
		return h.session.handle(uid,action,payload)
	end
	function h.negotiate()
		assert(h.call(101,"tradeInvite",{targetToken="token202"})); assert(h.call(202,"tradeAccept"))
		assert(h.call(101,"tradeOffer",{items={{kind="pet",id="101:pet:1"}}}))
		assert(h.call(202,"tradeOffer",{items={{kind="cauldron",id="202:cauldron:1"}}}))
	end
	function h.ready()
		assert(h.call(101,"tradeReady",{ready=true})); assert(h.call(202,"tradeReady",{ready=true})); return h.views[101].hash
	end
	function h.confirm(uid) return h.call(uid,"tradeConfirm",{offerHash=h.views[uid].hash}) end
	return h
end
