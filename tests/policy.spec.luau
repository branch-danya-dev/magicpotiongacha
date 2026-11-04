--!nonstrict
local Policy = require("../src/shared/Policy")
local H = require("./M2Harness")
return function(T: any)
	for _,mode in ipairs({"unrestricted","restricted","error","nil","missing","wrong-type"}) do
		T.test("M2 policy: server permission and guaranteed fallback / "..mode,function()
			local h=H.new(); local calls=0
			local policy=Policy.new({now=function() return h.now end,ttl=60,lookup=function()
				calls+=1
				if mode=="error" then error("timeout") elseif mode=="nil" then return nil elseif mode=="missing" then return {}
				elseif mode=="wrong-type" then return {ArePaidRandomItemsRestricted="false"} end
				return {ArePaidRandomItemsRestricted=mode=="restricted",IsPaidItemTradingAllowed=true}
			end})
			T.falsy(Policy.allowed(policy.peek(123),h.now))
			local state=policy.get(123); T.equal(Policy.allowed(state,h.now),mode=="unrestricted")
			policy.get(123); T.equal(calls,1)
			local ctx=h.context(); ctx.policy=state
			local before=H.copy(h.profile)
			T.equal(h.apply("summon",{poolId="forest",count=1},ctx),mode=="unrestricted")
			if mode~="unrestricted" then T.same(h.profile,before); T.equal(h.draws,0) end
			T.truthy(h.apply("shopFamiliar",{offerId="slime"},ctx))
			h.now+=61; T.falsy(Policy.allowed(policy.peek(123),h.now)); policy.get(123); T.equal(calls,2)
		end)
	end
	T.test("M2 policy: expiry fails closed at exact boundary, permission can be revoked",function()
		local now,restricted=10,false
		local service=Policy.new({now=function() return now end,ttl=60,lookup=function() return {ArePaidRandomItemsRestricted=restricted} end})
		T.truthy(Policy.allowed(service.get(1),now)); now=70
		T.falsy(Policy.allowed(service.peek(1),now)); restricted=true
		T.falsy(Policy.allowed(service.get(1),now)); T.equal(service.peek(1).status,"restricted")
	end)
	T.test("M2 policy: late result cannot revive departed player or overwrite newer result",function()
		local calls=0
		local service=Policy.new({now=function() return 10 end,ttl=60,lookup=function()
			calls+=1
			if calls==1 then coroutine.yield(); return {ArePaidRandomItemsRestricted=false} end
			return {ArePaidRandomItemsRestricted=true}
		end})
		local old=coroutine.create(function() service.get(1) end); T.truthy(coroutine.resume(old))
		service.forget(1); T.equal(service.get(1).status,"restricted")
		T.truthy(coroutine.resume(old)); T.equal(service.peek(1).status,"restricted")
		service.forget(1); T.equal(service.peek(1).status,"unavailable")
	end)
	T.test("M2 policy: trading remains denied unless explicitly granted by platform",function()
		local service=Policy.new({now=function() return 10 end,ttl=60,lookup=function() return {ArePaidRandomItemsRestricted=false,IsPaidItemTradingAllowed="true"} end})
		T.falsy(service.get(1).tradingAllowed)
	end)
end
