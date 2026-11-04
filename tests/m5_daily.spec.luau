--!nonstrict
local H=require("./M5Harness")
local Config=require("../src/shared/Config")
local Dailies=require("../src/shared/Dailies")
local Familiars=require("../src/shared/Familiars")
local Protocol=require("../src/shared/Protocol")
local scenario=require("./Scenarios")
local function calendar(h,day)
	h.now=day*86400+10
	return h.run("claimCalendar",{expectedDay=day})
end
local function full(h)
	local f=Familiars.new(Config); local p=h.profile
	for i=1,125 do local id="123:pet:"..i; p.pets[id]=f.create(id,"slime",Config.familiarShop.slime.stats,"shop",false) end
	p.nextPetSerial=126; assert(h.engine.validate(p))
end
return function(T:any)
	for day=10,12 do
		T.test("M5 daily: all three goals earned in phase one and cannot be reclaimed on another server / "..day,function()
			local h=H.new(); local e=h.engine; local p=e.newProfile(-1,day*86400+10)
			local r=scenario("manual",nil,{engine=e,profile=p,now=day*86400+10}); h.now=r.now
			local target=Config.longTerm.daily.essence.targets[day%3+1]
			while p.longTerm.daily.progress.essence<target do
				h.now+=1; T.truthy(e.advance(p,h.now,false).ok); T.truthy(e.act(p,"click",{},h.now))
			end
			T.equal(p.phase,1); local gold=p.gold
			for _,id in ipairs(Config.longTerm.dailyOrder) do
				T.truthy(h.run("claimDaily",{questId=id,expectedDay=day},p))
			end
			T.equal(p.gold,gold+190)
			local store=h.store(); T.truthy(store:load(-1,function() return p end)); T.truthy(store:release(-1))
			local other=h.store("next-server"); local loaded=other:loadExisting(-1,function() return e.newProfile(-1,h.now) end)
			T.truthy(loaded); local before=H.copy(loaded)
			for _,id in ipairs(Config.longTerm.dailyOrder) do
				T.falsy(other:transact(-1,function(candidate) return h.run("claimDaily",{questId=id,expectedDay=day},candidate) end))
			end
			T.same(other:get(-1),before)
		end)
	end
	T.test("M5 daily: real manual Essence actions count and claims are explicit/idempotent",function()
		local h=H.new(); local day=Dailies.day(h.now); local target=Config.longTerm.daily.essence.targets[day%3+1]
		for _=1,target do h.act("click") end
		T.equal(h.profile.longTerm.daily.progress.essence,target); local gold=h.profile.gold
		local request={questId="essence",expectedDay=day,requestId=1}; T.truthy(h.run("claimDaily",request)); T.equal(h.profile.gold,gold+40)
		local p=H.copy(h.profile); T.truthy(h.run("claimDaily",request)); T.same(h.profile,p)
		T.falsy(h.run("claimDaily",{questId="essence",expectedDay=day})); T.same(h.profile,p)
	end)
	T.test("M5 daily: completion uses manual online batch events; offline and automation excluded",function()
		for _,mode in ipairs({"manual","offline","automatic"}) do
			local h=H.new(); local p=h.profile; local station=p.stations.cauldron
			station.input.mandrake=2; station.essence=3
			if mode=="automatic" then p.discoveredRecipes.healing=true; station.workerId="123:starter_brewer"; station.auto=true
			else h.act("brew",{stationId="cauldron"}) end
			h.advance(12,mode=="offline")
			T.equal(p.longTerm.daily.progress.brew,mode=="manual" and 1 or 0); T.truthy(p.gold>100000)
		end
	end)
	T.test("M5 daily: quest claim requires completion and rejects client clock/progress",function()
		local h=H.new(); local before=H.copy(h.profile); local day=Dailies.day(h.now)
		T.falsy(h.run("claimDaily",{questId="brew",expectedDay=day})); T.same(h.profile,before)
		for _,field in ipairs({"progress","timestamp","timezone","reward","completed"}) do
			local payload={questId="brew",expectedDay=day,requestId=1}; payload[field]=999
			T.falsy(Protocol.validate("claimDaily",payload)); T.falsy(h.run("claimDaily",payload)); T.same(h.profile,before)
		end
	end)
	T.test("M5 daily: UTC rollover is deterministic, atomic on claim and cannot roll back",function()
		local h=H.new(); h.now=2*86400-1; h.act("click"); local old=H.copy(h.profile)
		local state=h.longTerm.state(h.profile,2*86400); T.equal(state.day,2); T.equal(state.daily[1].progress,0); T.same(h.profile,old)
		h.now=2*86400; T.falsy(h.run("claimDaily",{questId="essence",expectedDay=1})); T.same(h.profile,old)
		h.act("click"); T.equal(h.profile.longTerm.daily.day,2); T.equal(h.profile.longTerm.daily.progress.essence,1)
		local before=H.copy(h.profile); Dailies.record(Config,h.profile,"essence",100,86400); T.same(h.profile,before)
		T.falsy(h.run("claimDaily",{questId="essence",expectedDay=1},nil,{now=86400})); T.same(h.profile,before)
	end)
	T.test("M5 daily: all three day rotations are reachable phase-one goals",function()
		local h=H.new()
		for day=10,12 do
			local s=h.longTerm.state(h.profile,day*86400); T.equal(#s.daily,3)
			T.equal(s.daily[1].target,Config.longTerm.daily.essence.targets[day%3+1]); T.equal(s.daily[2].target,Config.longTerm.daily.brew.targets[day%3+1]); T.equal(s.daily[3].target,1)
		end
		T.equal(h.profile.longTerm.daily.day,-1)
	end)
	T.test("M5 calendar: day 1/7/8, unique entitlement and next-series fixed replacement",function()
		local h=H.new(); local original=H.count(h.profile.pets)
		for day=2,8 do
			T.truthy(calendar(h,day)); T.equal(h.profile.longTerm.calendar.step,day-1)
			local view=h.longTerm.state(h.profile,h.now); T.equal(view.calendarStep,day-1); T.truthy(view.calendarClaimed)
			T.equal(view.calendarSpecial,day==8)
		end
		local c=h.profile.longTerm.calendar
		T.truthy(c.pendingPet); T.truthy(h.profile.entitlements.chronicler); T.equal(H.count(h.profile.pets),original); T.equal(c.series,1)
		T.truthy(h.run("deliverCalendarPet",{})); T.equal(H.count(h.profile.pets),original+1); T.falsy(h.profile.longTerm.calendar.pendingPet)
		local receipt=h.profile.longTerm.sequence; local before=H.copy(h.profile)
		T.truthy(h.run("deliverCalendarPet",{requestId=receipt})); T.same(h.profile,before); T.falsy(h.run("deliverCalendarPet",{}))
		T.truthy(calendar(h,9)); T.equal(h.profile.longTerm.calendar.step,1)
		for day=10,15 do T.truthy(calendar(h,day)) end
		T.equal(h.profile.longTerm.calendar.series,2); T.falsy(h.profile.longTerm.calendar.pendingPet); T.equal(H.count(h.profile.pets),original+1)
		T.falsy(h.longTerm.state(h.profile,h.now).calendarSpecial); T.equal(h.longTerm.state(h.profile,h.now).calendarReward.gold,140)
	end)
	T.test("M5 calendar: skip resets streak; same-day and backwards-day claims deny",function()
		local h=H.new(); T.truthy(calendar(h,2)); T.truthy(calendar(h,3)); T.truthy(calendar(h,5))
		T.equal(h.profile.longTerm.calendar.step,1); local before=H.copy(h.profile)
		T.falsy(calendar(h,5)); T.same(h.profile,before); T.falsy(calendar(h,4)); T.same(h.profile,before)
	end)
	T.test("M5 calendar: full inventory retains claim across day change Rebirth and reload",function()
		local h=H.new(); h.complete(); full(h)
		for day=2,8 do T.truthy(calendar(h,day)) end
		local before=H.copy(h.profile); T.falsy(h.run("deliverCalendarPet",{})); T.same(h.profile,before); T.truthy(h.profile.longTerm.calendar.pendingPet)
		T.truthy(calendar(h,10)); T.truthy(h.rebirth()); T.truthy(h.profile.longTerm.calendar.pendingPet)
		local store=h.store(); T.truthy(store:load(123,function() return h.profile end)); T.truthy(store:release(123))
		local reopened=h.store("B"); h.profile=assert(reopened:loadExisting(123,function() return h.engine.newProfile(123,h.now) end))
		local ids={}; for i=1,5 do table.insert(ids,"123:pet:"..i) end
		local preview=h.preview(ids); T.truthy(h.apply("fuse",{petIds=ids,previewToken=preview.token,confirmed=true},h.context(preview)))
		T.equal(H.count(h.profile.pets),124); T.truthy(h.run("deliverCalendarPet",{})); T.equal(H.count(h.profile.pets),125)
		T.falsy(h.run("deliverCalendarPet",{})); T.truthy(h.engine.validate(h.profile))
	end)
	T.test("M5 altar: full inventory never debits shards or advances serial",function()
		local h=H.new(); h.complete(); T.truthy(h.rebirth()); full(h); local before=H.copy(h.profile)
		T.falsy(h.run("chooseRebirthPet",{offerId="moon_cat",confirmed=true})); T.same(h.profile,before)
	end)
	T.test("M5 rewards: balance overflow preserves unclaimed rights",function()
		local h=H.new(); h.profile.gold=Config.maxBalance; Dailies.record(Config,h.profile,"essence",50,h.now); local before=H.copy(h.profile)
		T.falsy(h.run("claimDaily",{questId="essence",expectedDay=Dailies.day(h.now)})); T.same(h.profile,before)
		T.falsy(h.run("claimCalendar",{expectedDay=Dailies.day(h.now)})); T.same(h.profile,before)
	end)
end
