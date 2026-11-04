--!nonstrict
local H=require("./M6Harness")
local M3=require("./M3Harness")
local firstCycle=require("./Scenarios")
local fullCycle=require("./M3Scenario")
local Config=H.Config
local Factory=require("../src/shared/Factory")
local Model=require("../src/shared/Monetization")
local LongTerm=require("../src/shared/LongTerm")
local Progression=require("../src/shared/Progression")
local Familiars=require("../src/shared/Familiars")
return function(T:any)
	local earnedFactory
	for _,route in ipairs({"new","veteran-rebirth","restricted"}) do
		T.test("M6 F2P: earned event wolf and cauldron inside real UTC window / "..route,function()
			local start=Config.events.spectral_2026.startAtUtc; local e=Factory.new(Config)
			local initial={engine=e,profile=e.newProfile(-1,start),now=start}; local priorSeconds=0
			if route=="veteran-rebirth" then
				local veteran=fullCycle("automation",initial); priorSeconds=veteran.now-start
				T.truthy(LongTerm.new(Config).apply(veteran.profile,"rebirth",{expectedRebirthCount=0,confirmed=true,requestId=1},e,{now=veteran.now}))
				initial={engine=e,profile=veteran.profile,now=veteran.now}; T.equal(initial.profile.gold,0)
			end
			local r=firstCycle("automation",nil,initial); local p,now=r.profile,r.now; local m=Model.new(Config)
			local spent=Config.pipesCost+math.ceil(Config.stations.crystal.upgradeCosts[2]*(route=="veteran-rebirth" and 1.1 or 1))
			if route=="veteran-rebirth" then spent=math.ceil(Config.pipesCost*1.1)+math.ceil(Config.stations.crystal.upgradeCosts[2]*1.1) end
			local income=p.gold+spent; local bought={}
			for _,offerId in ipairs({"ghost_wolf_v1","spectral_cauldron_v1"}) do
				local price=Config.monetization.offers[offerId].goldCost
				for _=1,240 do if p.gold>=price then break end; now+=60; local report=e.advance(p,now,false); T.truthy(report.ok); income+=report.goldEarned end
				T.truthy(p.gold>=price,"No zero-admin softlock"); T.truthy(now<Config.events.spectral_2026.endAtUtc)
				local ok,result=m.apply(p,"buyEventGold",{offerId=offerId,confirmed=true,requestId=p.monetization.sequence+1},e,
					{now=now,policy={randomAllowed=false,tradingAllowed=false,status=route=="restricted" and "restricted" or "unavailable"}})
				T.truthy(ok); spent+=price; bought[offerId]=result.instanceId
				print(string.format("M6_F2P route=%s offer=%s elapsed=%ds priorCycle=%ds clicks=%d harvests=%d income=%d spent=%d Gold=%d",route,offerId,now-start,priorSeconds,r.clicks,r.harvests,income,spent,p.gold))
			end
			T.equal(p.gold,income-spent); T.equal(H.count(p.monetization.receipts),0); T.equal(H.count(p.monetization.passes),0)
			T.falsy(p.pets[bought.ghost_wolf_v1].paidOrigin); T.falsy(p.cauldrons[bought.spectral_cauldron_v1].provenance.paidDerived)
			if route=="new" then
				T.truthy(e.act(p,"assign",{stationId="logistics",petId=bought.ghost_wolf_v1},now))
				T.truthy(e.act(p,"setAuto",{stationId="cauldron",enabled=false},now))
				while p.stations.cauldron.job do now+=1; T.truthy(e.advance(p,now,false).ok) end
				T.truthy(Progression.new(Config).apply(p,"equipCauldron",{slotId="cauldron",cauldronId=bought.spectral_cauldron_v1,requestId=p.progression.sequence+1},e,now))
				T.truthy(e.act(p,"setAuto",{stationId="cauldron",enabled=true},now)); earnedFactory={profile=H.copy(p),now=now,engine=e}
			end
		end)
	end
	T.test("M6 simulation: paid/free effects retain exact 7200-second online/offline parity",function()
		T.truthy(earnedFactory); local r=earnedFactory; local income
		for _,paid in ipairs({false,true}) do
			local seed=H.copy(r.profile)
			if paid then
				-- Controlled A/B fixture: replace the two earned instances via the actual paid grant method.
				local wolf=seed.stations.logistics.workerId; seed.stations.logistics.workerId=nil; seed.pets[wolf]=nil
				local pot=seed.stations.cauldron.cauldronId; seed.stations.cauldron.cauldronId=nil; seed.cauldrons[pot]=nil
				local m=Model.new(Config)
				local ok,w=m.acceptReceipt(seed,{PlayerId=-1,ProductId=1001,PurchaseId="parity-wolf"},"ghost_wolf_v1",r.engine,{now=r.now}); T.truthy(ok)
				local good,c=m.acceptReceipt(seed,{PlayerId=-1,ProductId=1002,PurchaseId="parity-cauldron"},"spectral_cauldron_v1",r.engine,{now=r.now}); T.truthy(good)
				seed.stations.logistics.workerId=w.instanceId; seed.stations.cauldron.cauldronId=c.instanceId
			end
			local online,offline=H.copy(seed),H.copy(seed)
			for i=1,7200 do T.truthy(r.engine.advance(online,r.now+i,false).ok) end
			T.truthy(r.engine.advance(offline,r.now+7200,true).ok); T.same(online,offline)
			local before=H.copy(offline); T.truthy(r.engine.advance(offline,r.now+7200,true).ok); T.same(offline,before)
			local earned=offline.gold-seed.gold; if income then T.equal(earned,income) end; income=earned
		end
		print(string.format("M6_FACTORY tier1 identicalPaidAndGoldIncome7200=%d",income))
	end)
	for tier=1,3 do
		T.test("M6 throughput: one existing carrier, tier cap and real delivered cargo / tier"..tier,function()
			local measured={}
			for _,seasonal in ipairs({false,true}) do
				local h=M3.new(); h.toPhase(4); local p=h.profile; p.inventory={mandrake=20}; p.pipes=false
				for _,s in pairs(p.stations) do s.workerId=nil; s.auto=false; s.output={}; s.input={}; s.essence=0; s.job=nil; s.progress=0 end
				p.stations.cauldron.recipeId="healing"; p.stations.logistics.level=tier
				local id="123:starter_slime"
				if seasonal then local m=Model.new(Config); local ok,r=m.acceptReceipt(p,{PlayerId=123,ProductId=1001,PurchaseId="bench-wolf"},"ghost_wolf_v1",h.engine,{now=h.now}); T.truthy(ok); id=r.instanceId end
				h.act("assign",{stationId="logistics",petId=id}); local start=h.now; h.advance(1)
				local amount=p.stations.logistics.job.amount; local skill=h.engine.stationState(p,"logistics").effectiveSkill
				while (p.stations.cauldron.input.mandrake or 0)==0 do h.advance(1); T.truthy(h.now-start<30) end
				measured[seasonal and "event" or "base"]={amount=amount,seconds=h.now-start,skill=skill}
			end
			local a,b=measured.base,measured.event; T.truthy(b.skill<=Config.stations.logistics.statCaps[tier]); T.truthy(b.amount/b.seconds>=a.amount/a.seconds)
			if tier>1 then T.truthy(b.amount/b.seconds>a.amount/a.seconds) else T.same(a,b) end
			print(string.format("M6_HAUL tier=%d base=%d/%ds skill=%d event=%d/%ds skill=%d",tier,a.amount,a.seconds,a.skill,b.amount,b.seconds,b.skill))
		end)
	end
	T.test("M6 brew: measured speed bonus consumes same inputs and preserves double-output chance",function()
		local result={}
		for _,seasonal in ipairs({false,true}) do
			local h=M3.new(); h.toPhase(4); local p=h.profile; p.pipes=false; local s=h.built("cauldron",3,"ascension")
			local f=Familiars.new(Config); p.pets["bench-cat"]=f.create("bench-cat","void_cat",Config.familiarShop.void_cat.stats,"shop",false); h.act("assign",{stationId="cauldron",petId="bench-cat"})
			if seasonal then
				local ok,r=Model.new(Config).acceptReceipt(p,{PlayerId=123,ProductId=1002,PurchaseId="bench-cauldron"},"spectral_cauldron_v1",h.engine,{now=h.now}); T.truthy(ok)
				T.truthy(h.command("equipCauldron",{slotId="cauldron",cauldronId=r.instanceId})); s=p.stations.cauldron
			end
			local start=h.now; s.input=H.copy(Config.recipes.ascension.inputs); s.essence=20; h.act("brew",{stationId="cauldron"})
			local duration,chance=s.job.duration,s.job.doubleChance; T.equal(next(s.input),nil); T.equal(s.essence,0)
			while s.job do h.advance(1) end
			local seconds=h.now-start; result[seasonal and "event" or "base"]={duration=duration,chance=chance,seconds=seconds}
		end
		local a,b=result.base,result.event; T.near(a.duration/b.duration,1.05); T.equal(a.chance,b.chance); T.truthy(b.seconds<a.seconds)
		print(string.format("M6_BREW ascension base=%.6fs (%ds ticks, %.2f batches/1200s) event=%.6fs (%ds ticks, %.2f batches/1200s) chance=%.3f",a.duration,a.seconds,1200/a.seconds,b.duration,b.seconds,1200/b.seconds,a.chance))
	end)
	T.test("M6 technology: event equipment cannot build a slot, unlock a recipe or waive inputs",function()
		local h=H.new(); h.receipt.ProductId=1002; T.truthy(h.process()); local p=h.profile(); local id=p.monetization.receipts[H.hash(h.receipt.PurchaseId)].instanceId
		local progression=Progression.new(Config)
		T.falsy(progression.apply(p,"equipCauldron",{slotId="cauldron2",cauldronId=id,requestId=1},h.engine,h.now)); T.equal(p.stations.cauldron2.level,0)
		T.truthy(progression.apply(p,"equipCauldron",{slotId="cauldron",cauldronId=id,requestId=1},h.engine,h.now)); T.falsy(h.engine.act(p,"brew",{stationId="cauldron"},h.now))
		T.falsy(h.engine.act(p,"setRecipe",{stationId="cauldron",recipeId="ascension"},h.now)); T.equal(p.phase,1); T.equal(p.rebirths,0)
	end)
end
