--!nonstrict
-- Same-server negotiation; this RAM state never grants/transfers an item.
local runtimeScript=rawget(getfenv(),"script")
local C=require(runtimeScript and runtimeScript.Parent.TradeCodec or "./TradeCodec")
local Trading=require(runtimeScript and runtimeScript.Parent.Trading or "./Trading")
local Protocol=require(runtimeScript and runtimeScript.Parent.Protocol or "./Protocol")
local Session={}
function Session.isAction(action) return type(action)=="string" and string.sub(action,1,5)=="trade" end
function Session.new(options)
	local service={}; local trades,byUser,cooldown={},{},{}
	local config,model=options.config,options.model
	local terminal={settled=true,aborted=true,cancelled=true,declined=true}
	local function changed(t)
		if terminal[t.state] then
			for _,side in ipairs(t.sides) do if byUser[side.userId]==t.id then byUser[side.userId]=nil end end
			trades[t.id]=nil
		end
		-- Presentation failure must not interrupt the durable protocol or strand
		-- a frozen negotiation before its first journal write.
		if options.changed then pcall(options.changed,t) end
	end
	local function live(t,allowPending)
		for _,side in ipairs(t.sides) do
			if options.identity(side.userId)~=side.identity or not options.inBazaar(side.userId)
				or not (allowPending and options.leaseActive(side.userId) or not allowPending and options.writable(side.userId)) then return false end
		end
		return true
	end
	local function reset(t,reason)
		t.version+=1; t.ready={}; t.confirmed={}; t.state="negotiating"; t.reason=reason; t.proposal=nil
	end
	local function proposal(t)
		return model.proposal(options.profile(t.sides[1].userId),options.profile(t.sides[2].userId),t.sides[1].selection,t.sides[2].selection,t.version)
	end
	function service.busy(userId)
		local t=trades[byUser[userId]]
		return t~=nil and (t.state=="frozen" or t.state=="recovering")
	end
	function service.current(userId) return trades[byUser[userId]] end
	function service.view(t,userId)
		if not t then return nil end
		local result={id=t.id,version=t.version,state=t.state,reason=t.reason,hash=t.proposal and C.hash(t.proposal),ready=C.copy(t.ready),confirmed=C.copy(t.confirmed),sides={}}
		for i,side in ipairs(t.sides) do
			result.sides[i]={mine=side.userId==userId,name=side.name,items=t.proposal and C.copy(t.proposal.sides[i].items) or C.copy(side.items or {})}
		end
		return result
	end
	function service.handle(userId,action,payload)
		if not options.enabled() then return false,"Trading is disabled until live QA" end
		local valid,reason=Protocol.validate(action,payload)
		if not Session.isAction(action) or not valid then return false,reason end
		if action=="tradeInvite" then
			local target=options.resolve(payload.targetToken)
			if not target or target==userId then return false,"Choose another player on this server" end
			if byUser[userId] or byUser[target] then return false,"A participant already has a trade" end
			if options.now()<(cooldown[userId] or 0) then return false,"Invitation cooldown" end
			local t={id=options.uuid(),version=1,state="invited",ready={},confirmed={},createdAt=options.now(),expiresAt=options.now()+config.trading.inviteSeconds,sides={}}
			for _,uid in ipairs({userId,target}) do
				local identity=options.identity(uid); if not identity then return false,"Player unavailable" end
				table.insert(t.sides,{userId=uid,identity=identity,name=options.name(uid),selection={},items={}})
			end
			if not live(t,false) then return false,"Both players must be active in the Bazaar" end
			-- Reserve the one-negotiation slots before the policy lookup yields.
			trades[t.id]=t; byUser[userId],byUser[target]=t.id,t.id; cooldown[userId]=options.now()+config.trading.inviteCooldown
			for _,side in ipairs(t.sides) do
				local lookupOK,policy=pcall(options.policy,side.userId,false)
				if not lookupOK or not Trading.policyAllowed(policy,options.now()) or not live(t,false) or t.state~="invited" then
					t.state="cancelled"; t.reason="Trading permission unavailable"; changed(t); return false,t.reason
				end
			end
			changed(t); return true,"Invitation sent"
		end
		local t=trades[payload.tradeId]
		if not t or byUser[userId]~=t.id then return false,"Unknown trade or participant" end
		local index=t.sides[1].userId==userId and 1 or 2
		if options.identity(userId)~=t.sides[index].identity then return false,"Player session changed" end
		if payload.version~=t.version then return false,"Offer version changed; review again" end
		if action=="tradeCancel" then
			if t.state=="frozen" or t.state=="recovering" then
				t.cancelRequested=true; t.reason="Cancellation requested; checking durable decision"; changed(t)
				return true,t.reason
			end
			t.state=t.state=="invited" and index==2 and "declined" or "cancelled"; changed(t); return true,"Cancelled"
		end
		if t.state=="frozen" or t.state=="recovering" then return false,"Trade is recovering" end
		if options.now()>=t.expiresAt or not live(t,false) then t.state="cancelled"; t.reason="Expired or participant left Bazaar"; changed(t); return false,t.reason end
		if action=="tradeAccept" then
			if t.state~="invited" or index~=2 then return false,"Only the invitee may accept" end
			t.state="negotiating"; t.expiresAt=options.now()+config.trading.negotiateSeconds; changed(t); return true,"Choose items"
		end
		if t.state=="invited" then return false,"Accept invitation first" end
		if action=="tradeOffer" then
			local items,err=model.offer(options.profile(userId),payload.items); if not items then return false,err end
			t.sides[index].selection=C.copy(payload.items); t.sides[index].items=items; reset(t)
			t.proposal=proposal(t); changed(t); return true,"Both confirmations reset"
		end
		local current,err=proposal(t)
		if not current or (t.proposal and C.encode(current)~=C.encode(t.proposal)) then reset(t,err or "Offered item changed"); changed(t); return false,t.reason end
		t.proposal=current
		if action=="tradeReady" then
			t.ready[tostring(index)]=payload.ready or nil; t.confirmed={}
			t.state=t.ready["1"] and t.ready["2"] and "both_ready" or "negotiating"; changed(t); return true,"Readiness updated"
		end
		if action~="tradeConfirm" or t.state~="both_ready" or payload.offerHash~=C.hash(t.proposal) then return false,"Review the exact final offer first" end
		t.confirmed[tostring(index)]=true; changed(t)
		if not t.confirmed["1"] or not t.confirmed["2"] then return true,"Waiting for the other confirmation" end
		if options.canStart and not options.canStart() then t.confirmed={}; t.reason="Trade storage budget low; confirm again later"; changed(t); return false,t.reason end
		t.state="frozen"; t.frozenAt=options.now(); changed(t)
		local ok,settled,result=pcall(options.commit,t.id,t.proposal,function()
			local permissions={}
			for _,side in ipairs(t.sides) do permissions[side.userId]=options.policy(side.userId,true) end
			return function(now)
				if t.cancelRequested or not options.enabled() or not live(t,true) then return false end
				for _,side in ipairs(t.sides) do if not Trading.policyAllowed(permissions[side.userId],now) then return false end end
				return true
			end
		end)
		if ok and settled and type(result)=="table" and result.state=="COMPLETE" then
			t.state=result.decision=="COMMIT" and "settled" or "aborted"; t.reason=result.decision
		else t.state="recovering"; t.reason="Pending durable recovery; do not regrant items" end
		changed(t); return true,t.reason
	end
	function service.poll()
		for _,t in pairs(trades) do
			if t.state=="recovering" then
				local ok,result=options.recover(t.id,t.cancelRequested)
				if ok and type(result)=="table" and result.state=="COMPLETE" then t.state=result.decision=="COMMIT" and "settled" or "aborted"; t.reason=result.decision; changed(t) end
				if not ok and result=="Journal missing" and options.now()>t.frozenAt+config.trading.prepareSeconds then
					local clear=true
					for _,side in ipairs(t.sides) do local p=options.profile(side.userId); if not p or Trading.frozen(p) then clear=false end end
					if clear then t.state="aborted"; t.reason="No durable trade was created"; changed(t) end
				end
			elseif t.state~="frozen" and (options.now()>=t.expiresAt or not live(t,false)) then t.state="cancelled"; changed(t) end
		end
	end
	function service.leave(userId)
		local t=trades[byUser[userId]]; cooldown[userId]=nil
		if t then
			if t.state=="frozen" or t.state=="recovering" then t.cancelRequested=true
			else t.state="cancelled"; changed(t) end
		end
	end
	return service
end
return Session
