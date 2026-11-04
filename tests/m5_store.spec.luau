--!nonstrict
local H=require("./M5Harness")
local Config=require("../src/shared/Config")
local Dailies=require("../src/shared/Dailies")
local M4=require("./M4Harness")
local LongTerm=require("../src/shared/LongTerm")
local fixture=require("./fixtures/m4-pending")
local function setup(action)
	local h=H.new(); local payload={}
	if action=="rebirth" then h.complete(); payload={expectedRebirthCount=0,confirmed=true}
	elseif action=="buyRebirthPerk" or action=="chooseRebirthPet" then
		h.complete(); assert(h.rebirth()); payload=action=="buyRebirthPerk" and {perkId="industry",expectedLevel=0} or {offerId="moon_cat",confirmed=true}
	elseif action=="claimDaily" then Dailies.record(Config,h.profile,"essence",50,h.now); payload={questId="essence",expectedDay=Dailies.day(h.now)}
	elseif action=="claimCalendar" then payload={expectedDay=Dailies.day(h.now)}
	else
		h.profile.longTerm.calendar={lastDay=Dailies.day(h.now),step=7,series=1,uniqueAwarded=true,pendingPet=true,delivered=false}; h.profile.entitlements.chronicler=true
	end
	payload.requestId=h.profile.longTerm.sequence+1
	local store=h.store(); assert(store:load(123,function() return h.profile end))
	local function execute()
		return store:transact(123,function(p) return h.run(action,payload,p) end)
	end
	return h,store,execute,payload
end
return function(T:any)
	for _,mode in ipairs({"before","after"}) do
		T.test("M5 persistence: unique seventh-day entitlement survives unknown claim / "..mode,function()
			local h=H.new()
			for day=2,7 do h.now=day*86400+10; T.truthy(h.run("claimCalendar",{expectedDay=day})) end
			h.now=8*86400+10; local store=h.store(); T.truthy(store:load(123,function() return h.profile end))
			local payload={expectedDay=8,requestId=h.profile.longTerm.sequence+1}
			if mode=="before" then h.beforeFailures=3 else h.afterFailures=3 end
			T.falsy(store:transact(123,function(p) return h.run("claimCalendar",payload,p) end)); T.falsy(store:isWritable(123))
			h.now=math.floor(h.now)+181; local other=h.store("another-server")
			local p=other:loadExisting(123,function() return h.engine.newProfile(123,h.now) end); T.truthy(p)
			T.equal(p.longTerm.calendar.pendingPet,mode=="after")
			T.truthy(other:transact(123,function(candidate) return h.run("claimCalendar",payload,candidate) end))
			T.truthy(other:get(123).longTerm.calendar.pendingPet); T.equal(other:get(123).longTerm.calendar.series,1)
			T.equal(H.count(other:get(123).pets),3); T.equal(other:get(123).entitlements.chronicler,true)
		end)
	end
	for _,action in ipairs({"rebirth","buyRebirthPerk","chooseRebirthPet","claimDaily","claimCalendar","deliverCalendarPet"}) do
		for _,mode in ipairs({"before","after"}) do
			T.test("M5 persistence: unknown write fences old state and restores exactly once / "..action.."/"..mode,function()
				local h,store,execute,payload=setup(action); local before=H.copy(store:get(123)); local expected=H.copy(before)
				T.truthy(h.run(action,payload,expected)); if mode=="before" then h.beforeFailures=3 else h.afterFailures=3 end
				T.falsy(execute()); T.same(store:get(123),before); T.falsy(store:isWritable(123)); T.falsy(store:save(123)); T.falsy(store:release(123))
				h.now=math.floor(h.now)+181; local nextStore=h.store("B"); local p=nextStore:loadExisting(123,function() return h.engine.newProfile(123,h.now) end)
				T.truthy(p); T.same(p,mode=="after" and expected or before)
				if mode=="after" then
					local snapshot=H.copy(p); T.truthy(nextStore:transact(123,function(candidate) return h.run(action,payload,candidate) end)); T.same(nextStore:get(123),snapshot)
				end
			end)
		end
		T.test("M5 persistence: callback replay and concurrent same intent grant once / "..action,function()
			local h,store,execute=setup(action); local entered=0; local first,second; local before=H.copy(store:get(123))
			h.replays=3; h.sleep=function() coroutine.yield() end
			h.beforeUpdate=function() entered+=1; if entered==1 then T.same(store:get(123),before); T.falsy(store:isWritable(123)); coroutine.yield() end end
			local a=coroutine.create(function() first={execute()} end); local b=coroutine.create(function() second={execute()} end)
			T.truthy(coroutine.resume(a)); T.truthy(coroutine.resume(b)); T.truthy(coroutine.resume(a)); T.truthy(coroutine.resume(b))
			T.truthy(first[1]); T.truthy(second[1]); T.same(first[2],second[2]); T.equal(h.record.revision,2)
			T.equal(store:get(123).longTerm.sequence,before.longTerm.sequence+1)
		end)
	end
	T.test("M5 persistence: conflicting same request cannot buy two permanent rewards",function()
		local h,store,execute,payload=setup("buyRebirthPerk"); local entered=0; local aResult,bResult
		h.sleep=function() coroutine.yield() end; h.beforeUpdate=function() entered+=1; if entered==1 then coroutine.yield() end end
		local other={offerId="moon_cat",confirmed=true,requestId=payload.requestId}
		local a=coroutine.create(function() aResult=execute() end)
		local b=coroutine.create(function() bResult=store:transact(123,function(p) return h.run("chooseRebirthPet",other,p) end) end)
		T.truthy(coroutine.resume(a)); T.truthy(coroutine.resume(b)); T.truthy(coroutine.resume(a)); T.truthy(coroutine.resume(b))
		T.truthy(aResult); T.falsy(bResult); T.equal(store:get(123).longTerm.shards,0); T.equal(H.count(store:get(123).pets),3)
	end)
	T.test("M5 persistence: queued command rechecks departed Player before reset",function()
		local h,store,_,payload=setup("rebirth"); local before=H.copy(store:get(123))
		T.falsy(store:transact(123,function(p) return h.run("rebirth",payload,p,{guard=function() return false end}) end)); T.same(store:get(123),before)
	end)
	T.test("M5 migration: V5 pending COMMIT recovers before any reset or offline payout",function()
		local h=M4.new(); h.stores={}
		h.records["p:101"]={schemaVersion=1,revision=5,profile=H.copy(fixture.profile)}
		h.records["p:202"]={schemaVersion=1,revision=5,profile=H.copy(fixture.other)}
		h.journals["t:trade-uuid-1"]=H.copy(fixture.journal); h.now+=181
		local p=h.load(101); local before=H.copy(p); T.equal(p.schemaVersion,6); T.same(p.trade,fixture.profile.trade)
		T.equal(p.longTerm.shards,0); T.falsy(p.longTerm.cycle.finalProduced)
		T.falsy(h.stores[101]:transact(101,function(candidate) return LongTerm.new(Config).apply(candidate,"rebirth",{expectedRebirthCount=0,confirmed=true,requestId=1},h.engine,{now=h.now}) end))
		T.same(h.profile(101),before); T.truthy(h.recover()); T.truthy(h.checkOutcome()); T.truthy(h.stores[101]:isWritable(101))
	end)
	T.test("M5 migration: every V5 field is retained without invented history",function()
		local h=H.new(); local old=H.copy(fixture.profile); local p=h.engine.migrate(H.copy(old)); T.truthy(p)
		for key,value in pairs(old) do if key~="schemaVersion" then T.same(p[key],value,key) end end
		T.equal(p.schemaVersion,6); T.equal(p.longTerm.sequence,0); T.equal(p.longTerm.earned,0); T.equal(p.longTerm.spent,0)
		T.equal(p.longTerm.daily.day,-1); T.equal(p.longTerm.calendar.lastDay,-1); T.same(h.engine.migrate(H.copy(p)),p)
	end)
	for _,defect in ipairs({"future","historical-state","shards","perk","free-perk","foreign-epoch-stock","cycle","completion","daily-day","daily-claim","calendar","pending-right","receipt"}) do
		T.test("M5 persistence: invalid migration/current meta never overwrites / "..defect,function()
			local h=H.new(); local p=H.copy(h.profile)
			if defect=="future" then p.schemaVersion=7 elseif defect=="historical-state" then p=H.copy(fixture.profile); p.longTerm={}
			elseif defect=="shards" then p.longTerm.shards=1 elseif defect=="perk" then p.longTerm.perks.industry=99
			elseif defect=="free-perk" then p.longTerm.perks.industry=1 elseif defect=="foreign-epoch-stock" then p.inventory.void_plasma=1
			elseif defect=="cycle" then p.longTerm.cycle.id=1 elseif defect=="completion" then p.longTerm.cycle.finalProduced=true
			elseif defect=="daily-day" then p.longTerm.daily.day=0/0 elseif defect=="daily-claim" then p.longTerm.daily.claimed.essence=true
			elseif defect=="calendar" then p.longTerm.calendar.step=8 elseif defect=="pending-right" then p.longTerm.calendar.pendingPet=true
			else p.longTerm.sequence=1 end
			h.record={schemaVersion=1,revision=3,profile=p}; local before=H.copy(h.record)
			T.equal(h.engine.migrate(H.copy(p)),nil); T.equal(h.store():loadExisting(123,function() return h.engine.newProfile(123,h.now) end),nil)
			if defect~="daily-day" then T.same(h.record,before) else T.equal(h.record.revision,3) end
			T.equal(h.revisionWrites,0)
		end)
	end
end
