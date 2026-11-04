--!nonstrict
local H = require("./M2Harness")
return function(T: any)
	local function fixture()
		local h=H.new(); local store=h.store()
		T.truthy(store:load(123,function() return h.profile end))
		local function summon(payload)
			return store:transact(123,function(candidate)
				return h.collection.apply(candidate,"summon",payload or {poolId="forest",count=5,requestId=1},h.context())
			end)
		end
		return h,store,summon
	end
	T.test("M2 store: candidate hidden and factory frozen until durable confirmation",function()
		local h,store,summon=fixture(); local live=store:get(123); local before=H.copy(live)
		h.beforeUpdate=function()
			T.falsy(store:isWritable(123)); T.same(store:get(123),before)
			coroutine.yield("write pending")
		end
		local completed=false
		local co=coroutine.create(function() T.truthy(summon()); completed=true end)
		T.truthy(coroutine.resume(co)); T.falsy(completed); T.same(store:get(123),before)
		T.truthy(coroutine.resume(co)); T.truthy(completed); T.truthy(store:isWritable(123))
		T.equal(store:get(123).essence,before.essence-250); T.equal(H.count(store:get(123).pets),8)
		T.same(live,before); T.same(h.record.profile,store:get(123))
	end)
	T.test("M2 store: CAS replay and one lost reply do not reroll or charge twice",function()
		local h,store,summon=fixture(); h.replays=3; h.afterFailures=1
		T.truthy(summon()); T.equal(h.draws,20); T.equal(h.record.revision,2); T.equal(h.revisionWrites,2)
		T.equal(store:get(123).essence,99750); local calls=h.calls
		local ok,receipt=summon(); T.truthy(ok); T.equal(#receipt.createdIds,5); T.equal(h.calls,calls); T.equal(h.draws,20)
	end)
	for _,mode in ipairs({"before-write","after-write"}) do
		T.test("M2 store: ambiguous failure freezes old live state; rejoin reconciles / "..mode,function()
			local h,store,summon=fixture(); local before=H.copy(store:get(123))
			if mode=="before-write" then h.beforeFailures=3 else h.afterFailures=3 end
			T.falsy(summon()); T.same(store:get(123),before); T.falsy(store:isWritable(123))
			T.falsy(store:save(123)); T.falsy(store:release(123)); T.falsy(summon()); T.equal(h.draws,20)
			h.now=100200; local nextStore=h.store("B")
			local loaded=nextStore:load(123,function() return h.profile end); T.truthy(loaded)
			T.equal(loaded.essence,mode=="after-write" and 99750 or 100000)
			T.equal(loaded.collection.sequence,mode=="after-write" and 1 or 0)
			T.equal(H.count(loaded.pets),mode=="after-write" and 8 or 3)
			if mode=="after-write" then
				T.truthy(nextStore:transact(123,function(candidate) return h.collection.apply(candidate,"summon",{poolId="forest",count=5,requestId=1},h.context()) end))
				T.equal(h.draws,20)
			end
		end)
	end
	T.test("M2 store: simultaneous identical requests serialize to one reward",function()
		local h,_store,summon=fixture(); local entered=0
		h.beforeUpdate=function() entered+=1; if entered==1 then coroutine.yield("write") end end
		h.sleep=function() coroutine.yield("gate") end
		local first,second
		local a=coroutine.create(function() first={summon()} end)
		local b=coroutine.create(function() second={summon()} end)
		T.truthy(coroutine.resume(a)); T.truthy(coroutine.resume(b)); T.equal(second,nil)
		T.truthy(coroutine.resume(a)); T.truthy(coroutine.resume(b))
		T.truthy(first[1]); T.truthy(second[1]); T.same(first[2],second[2]); T.equal(h.draws,20); T.equal(h.record.revision,2)
	end)
	T.test("M2 store: simultaneous conflicting request ID cannot steal the receipt",function()
		local h,_store,summon=fixture(); local entered=0
		h.beforeUpdate=function() entered+=1; if entered==1 then coroutine.yield() end end
		h.sleep=function() coroutine.yield() end
		local second
		local a=coroutine.create(function() T.truthy(summon()) end)
		local b=coroutine.create(function() second=summon({poolId="forest",count=1,requestId=1}) end)
		T.truthy(coroutine.resume(a)); T.truthy(coroutine.resume(b)); T.truthy(coroutine.resume(a)); T.truthy(coroutine.resume(b))
		T.falsy(second); T.equal(h.draws,20); T.equal(h.record.profile.essence,99750)
	end)
	T.test("M2 store: disconnect during write releases committed candidate, not old profile",function()
		local h,store,summon=fixture(); local entered=0
		h.beforeUpdate=function() entered+=1; if entered==1 then coroutine.yield() end end
		h.sleep=function() coroutine.yield() end
		local a=coroutine.create(function() T.truthy(summon()) end)
		local b=coroutine.create(function() T.truthy(store:release(123)) end)
		T.truthy(coroutine.resume(a)); T.truthy(coroutine.resume(b)); T.truthy(coroutine.resume(a)); T.truthy(coroutine.resume(b))
		T.equal(h.record.profile.collection.sequence,1); T.equal(h.record.profile.essence,99750)
		T.equal(h.record.lease,nil); T.equal(store:get(123),nil)
	end)
	T.test("M2 store: invalidation during write never acknowledges or revives candidate",function()
		local h,store,summon=fixture(); local before=H.copy(store:get(123))
		h.beforeUpdate=function() store:invalidate(123) end
		T.falsy(summon()); T.falsy(store:isWritable(123)); T.same(store:get(123),before)
		T.equal(h.record.profile.collection.sequence,1); T.falsy(store:release(123))
	end)
	T.test("M2 store: partial RNG exception abandons candidate without charge or receipt",function()
		local h,store=fixture(); local before=H.copy(store:get(123)); local draws=0
		T.falsy(store:transact(123,function(candidate)
			local context=h.context(); context.nextInteger=function(lo) draws+=1; if draws==7 then error("RNG failed") end; return lo end
			return h.collection.apply(candidate,"summon",{poolId="forest",count=5,requestId=1},context)
		end))
		T.same(store:get(123),before); T.equal(h.record.revision,1); T.truthy(store:isWritable(123))
	end)
	T.test("M2 store: two concurrent Fuse commands consume five parents exactly once",function()
		local h=H.new(); local ids=h.buyFive("slime"); local preview=h.preview(ids); h.now+=1
		local store=h.store(); T.truthy(store:load(123,function() return h.profile end))
		local payload={petIds=ids,previewToken=preview.token,confirmed=true,requestId=6}
		local function command() return store:transact(123,function(p) return h.collection.apply(p,"fuse",payload,h.context(preview)) end) end
		local entered=0
		h.beforeUpdate=function() entered+=1; if entered==1 then coroutine.yield() end end
		h.sleep=function() coroutine.yield() end
		local first,second
		local a=coroutine.create(function() first={command()} end)
		local b=coroutine.create(function() second={command()} end)
		T.truthy(coroutine.resume(a)); T.truthy(coroutine.resume(b)); T.truthy(coroutine.resume(a)); T.truthy(coroutine.resume(b))
		T.truthy(first[1]); T.truthy(second[1]); T.same(first[2],second[2])
		T.equal(H.count(store:get(123).pets),4); T.equal(h.record.revision,2)
	end)
	for _,mode in ipairs({"before-write","after-write"}) do
		T.test("M2 store: failed Fuse never exposes partial deletion / "..mode,function()
			local h=H.new(); local ids=h.buyFive("slime"); local preview=h.preview(ids); h.now+=1
			local store=h.store(); T.truthy(store:load(123,function() return h.profile end))
			local before=H.copy(store:get(123))
			if mode=="before-write" then h.beforeFailures=3 else h.afterFailures=3 end
			T.falsy(store:transact(123,function(p) return h.collection.apply(p,"fuse",{petIds=ids,previewToken=preview.token,confirmed=true,requestId=6},h.context(preview)) end))
			T.same(store:get(123),before); T.falsy(store:isWritable(123)); T.falsy(store:release(123))
			h.now=100300; local nextStore=h.store("B"); local restored=nextStore:load(123,function() return h.profile end)
			T.truthy(restored); T.equal(H.count(restored.pets),mode=="after-write" and 4 or 8)
			for _,id in ipairs(ids) do T.equal(restored.pets[id]~=nil,mode=="before-write") end
		end)
	end
	T.test("M2 store: Fuse replay survives reconnect, cannot consume same parents twice",function()
		local h=H.new(); local ids=h.buyFive("slime"); local preview=h.preview(ids); h.now+=1
		local store=h.store(); T.truthy(store:load(123,function() return h.profile end))
		local payload={petIds=ids,previewToken=preview.token,confirmed=true,requestId=6}
		local function command(candidate) return h.collection.apply(candidate,"fuse",payload,h.context(preview)) end
		local ok,result=store:transact(123,command); T.truthy(ok); T.equal(#result.createdIds,1)
		T.truthy(store:release(123)); local nextStore=h.store("B"); T.truthy(nextStore:load(123,function() return h.profile end))
		h.now+=61; local ctx=h.context(); ctx.preview=nil
		local replayed,receipt=nextStore:transact(123,function(p) return h.collection.apply(p,"fuse",payload,ctx) end)
		T.truthy(replayed); T.same(receipt,result); T.equal(H.count(nextStore:get(123).pets),4)
		payload.requestId=7; T.falsy(nextStore:transact(123,command)); T.equal(H.count(nextStore:get(123).pets),4)
	end)
end
