--!nonstrict
local new=require("./TradeSessionHarness")
local C=require("../src/shared/TradeCodec")
local Protocol=require("../src/shared/Protocol")
return function(T: any)
	T.test("M4 session: two distinct ready and exact-hash confirmations settle once",function()
		local h=new(); h.negotiate(); h.ready(); T.truthy(h.confirm(101)); T.equal(next(h.journals),nil)
		T.truthy(h.confirm(202)); T.equal(h.views[101].state,"settled"); T.equal(h.views[202].state,"settled"); T.equal(h.forced,2)
		T.truthy(h.checkOutcome()); T.falsy(h.call(202,"tradeConfirm",{tradeId="trade-uuid-1",version=3,offerHash=h.views[202].hash}))
	end)
	T.test("M4 session: any offer edit invalidates both ready/confirm flags and old hash",function()
		local h=new(); h.negotiate(); local hash=h.ready(); T.truthy(h.confirm(101)); local version=h.views[101].version
		T.truthy(h.call(202,"tradeOffer",{items={{kind="pet",id="202:pet:1"}}}))
		T.equal(next(h.views[101].ready),nil); T.equal(next(h.views[202].confirmed),nil)
		T.falsy(h.call(202,"tradeConfirm",{version=version,offerHash=hash})); h.ready()
		T.falsy(h.call(202,"tradeConfirm",{offerHash=hash})); T.equal(next(h.journals),nil)
	end)
	for _,defect in ipairs({"disabled","self","cross-server","out-of-range","busy","policy-missing","policy-restricted","policy-failure"}) do
		T.test("M4 session: invitation admission / "..defect,function()
			local h=new(); local token="token202"
			if defect=="disabled" then h.enabled=false elseif defect=="self" then token="token101"
			elseif defect=="cross-server" then token="elsewhere" elseif defect=="out-of-range" then h.positions[202]=false
			elseif defect=="busy" then h.valueOperation=true elseif defect=="policy-missing" then h.policies[202].tradingKnown=nil
			elseif defect=="policy-restricted" then h.policies[202].tradingAllowed=false else h.onPolicy=function() error("lookup failed") end end
			T.falsy(h.call(101,"tradeInvite",{targetToken=token})); T.equal(next(h.journals),nil); T.equal(h.session.current(101),nil)
		end)
	end
	T.test("M4 session: invitee decline, invitation expiry and cooldown",function()
		local h=new(); T.truthy(h.call(101,"tradeInvite",{targetToken="token202"})); T.falsy(h.call(101,"tradeAccept"))
		T.truthy(h.call(202,"tradeCancel")); T.equal(h.views[101].state,"declined")
		T.falsy(h.call(101,"tradeInvite",{targetToken="token202"})); h.now+=16
		T.truthy(h.call(101,"tradeInvite",{targetToken="token202"})); h.now+=31; h.session.poll(); T.equal(h.session.current(101),nil)
	end)
	T.test("M4 session: third player cannot use another offer or occupy its participants",function()
		local h=new(); h.negotiate(); local t=h.session.current(101)
		T.falsy(h.call(303,"tradeInvite",{targetToken="token202"}))
		T.falsy(h.call(303,"tradeOffer",{tradeId=t.id,version=t.version,items={}}))
		T.equal(h.session.current(303),nil)
	end)
	T.test("M4 session: policy yield reserves the invitation slot and rechecks identity",function()
		local h=new(); local nested
		h.onPolicy=function(uid) if uid==101 then nested=h.call(303,"tradeInvite",{targetToken="token202"}); h.identities[202]={id=202} end end
		T.falsy(h.call(101,"tradeInvite",{targetToken="token202"})); T.falsy(nested); T.equal(h.session.current(101),nil)
	end)
	for _,change in ipairs({"lock","assign","stats","provenance"}) do
		T.test("M4 session: stale item snapshot invalidates final confirmation / "..change,function()
			local h=new(); h.negotiate(); h.ready(); h.confirm(101)
			local p=h.profile(101); local item=p.pets["101:pet:1"]
			if change=="lock" then item.locked=true elseif change=="assign" then p.stations.logistics.workerId=item.id
			elseif change=="stats" then item.stats.Hauling=11 else item.paidOrigin=true; item.provenance.paidDerived=true end
			T.falsy(h.confirm(202)); T.equal(next(h.views[101].confirmed),nil); T.equal(next(h.journals),nil)
		end)
	end
	for _,change in ipairs({"policy","expired","identity","position","disabled","cancel","disconnect"}) do
		T.test("M4 session: final post-yield guard aborts safely / "..change,function()
			local h=new(); h.negotiate(); h.ready(); h.confirm(101)
			h.onPolicy=function(uid,force)
				if force and uid==202 then
					if change=="policy" then h.policies[202].tradingAllowed=false elseif change=="expired" then h.now+=61
					elseif change=="identity" then h.identities[202]={id=202} elseif change=="position" then h.positions[202]=false
					elseif change=="disabled" then h.enabled=false elseif change=="cancel" then h.call(101,"tradeCancel")
					else h.session.leave(101); h.identities[101]=nil end
				end
			end
			T.truthy(h.confirm(202)); T.equal(h.views[202].state,"aborted"); T.falsy(h.checkOutcome())
		end)
	end
	T.test("M4 session: unknown commit never reports success or permits more mutations",function()
		local h=new(); h.negotiate(); h.ready(); h.confirm(101); h.calls=0; h.fault={at=7,mode="after",sticky=true}
		T.truthy(h.confirm(202)); T.equal(h.views[101].state,"recovering"); T.truthy(h.session.busy(101))
		T.falsy(h.call(101,"tradeOffer",{items={}})); T.truthy(h.call(101,"tradeCancel"))
		h.offline=false; h.fault=nil; h.session.poll(); T.equal(h.views[101].state,"settled"); T.truthy(h.checkOutcome())
	end)
	T.test("M4 session: pre-commit leave cancels and negotiation timeout releases slots",function()
		local h=new(); h.negotiate(); h.session.leave(202); T.equal(h.views[101].state,"cancelled"); T.equal(h.session.current(101),nil)
		h.now+=16; h.negotiate(); h.now+=301; h.session.poll(); T.equal(h.session.current(202),nil); T.equal(next(h.journals),nil)
	end)
	T.test("M4 session: failed presentation callback cannot strand a frozen exchange",function()
		local h=new(); h.negotiate(); h.ready(); h.confirm(101); h.presentationFailure=true
		T.truthy(h.confirm(202)); T.truthy(h.checkOutcome()); T.falsy(h.session.busy(101)); T.equal(h.session.current(101),nil)
	end)
	T.test("M4 session: low admission budget clears confirms without freezing or writing",function()
		local h=new(); h.negotiate(); h.ready(); h.confirm(101); h.noBudget=true
		T.falsy(h.confirm(202)); T.equal(next(h.journals),nil); T.falsy(h.session.busy(101)); T.equal(next(h.views[101].confirmed),nil)
		h.noBudget=false; T.truthy(h.confirm(101)); T.truthy(h.confirm(202)); T.truthy(h.checkOutcome())
	end)
	T.test("M4 session: aggregate control budget applies to trade spam",function()
		local gate=Protocol.new(); local accepted=0
		for _=1,100 do if gate:check(101,"tradeInvite",{targetToken="token202"},100) then accepted+=1 end end
		T.equal(accepted,10)
	end)
	T.test("M4: bounded eight-user request workload stays isolated",function()
		local start=os.clock(); local requests,trades=0,0
		local users={101,202,303,404,505,606,707,808}; local h=new(users)
		for round=1,5 do
			for _,uid in ipairs(users) do h.policies[uid].expiresAt=h.now+60 end
			-- Four simultaneous negotiations on the same session manager/backend.
			for pair=1,4 do
				local a,b=users[pair*2-1],users[pair*2]
				T.truthy(h.call(a,"tradeInvite",{targetToken="token"..b})); T.truthy(h.call(b,"tradeAccept"))
				local pet={kind="pet",id=a..":pet:1"}; local cauldron={kind="cauldron",id=b..":cauldron:1"}
				T.truthy(h.call(a,"tradeOffer",{items={round%2==1 and pet or cauldron}}))
				T.truthy(h.call(b,"tradeOffer",{items={round%2==1 and cauldron or pet}}))
				T.truthy(h.call(a,"tradeReady",{ready=true})); T.truthy(h.call(b,"tradeReady",{ready=true})); requests+=6
			end
			for _,uid in ipairs(users) do T.truthy(h.confirm(uid)); requests+=1 end
			for _,uid in ipairs(users) do T.equal(h.views[uid].state,"settled"); T.equal(h.session.current(uid),nil) end
			trades+=4; h.oracle(); h.now+=16
		end
		local before=C.copy(h.records); h.enabled=false
		for i=1,1000 do T.falsy(h.call(users[(i-1)%8+1],"tradeInvite",{targetToken="token202"})); requests+=1 end
		T.same(h.records,before)
		print(string.format("M4_BENCH 8 users / %d settled trades / %d requests (1000 disabled): %.3f CPU seconds; no Roblox latency claim",trades,requests,os.clock()-start))
	end)
end
