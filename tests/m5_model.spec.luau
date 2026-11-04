--!nonstrict
local H=require("./M5Harness")
local Config=require("../src/shared/Config")
local Epochs=require("../src/shared/Epochs")
local Protocol=require("../src/shared/Protocol")
local Access=require("../src/shared/Access")
local Dailies=require("../src/shared/Dailies")
return function(T:any)
	T.test("M5: an already-owned permanent title cannot consume a shard again",function()
		local h=H.new(); h.complete(); T.truthy(h.rebirth()); h.profile.entitlements.chrononaut=true
		local before=H.copy(h.profile); T.falsy(h.run("buyRebirthPerk",{perkId="title",expectedLevel=0})); T.same(h.profile,before)
	end)
	T.test("M5: a capped perk rejects even when more earned shards are available",function()
		local h=H.new(); local p=h.profile
		p.rebirths=4; p.longTerm.cycle.id=4; p.longTerm.earned=4; p.longTerm.spent=3; p.longTerm.shards=1; p.longTerm.perks.industry=3
		T.truthy(h.engine.validate(p)); local before=H.copy(p)
		T.falsy(h.run("buyRebirthPerk",{perkId="industry",expectedLevel=3})); T.same(p,before)
	end)
	T.test("M5: completed batch grants one shard only through an explicit reset transaction",function()
		local h=H.new(); h.complete(); local p=h.profile
		T.equal(p.rebirths,0); T.equal(p.longTerm.shards,0); T.truthy(h.longTerm.state(p,h.now).available)
		local pets,cauldrons,serials=H.copy(p.pets),H.copy(p.cauldrons),{p.nextPetSerial,p.nextCauldronSerial}
		local request={expectedRebirthCount=0,confirmed=true,requestId=1}; T.truthy(h.run("rebirth",request))
		T.equal(p.rebirths,1); T.equal(p.longTerm.shards,1); T.equal(p.phase,1); T.falsy(p.longTerm.cycle.finalProduced)
		T.same(p.pets,pets); T.same(p.cauldrons,cauldrons); T.same({p.nextPetSerial,p.nextCauldronSerial},serials)
		local after=H.copy(p); T.truthy(h.run("rebirth",request)); T.same(p,after)
		T.falsy(h.run("rebirth",{expectedRebirthCount=0,confirmed=true})); T.same(p,after)
	end)
	T.test("M5: exhaustive cycle reset preserves inventory rights histories and daily claims",function()
		local h=H.new(); h.complete(); local p=h.profile; local cauldron=next(p.cauldrons)
		p.cauldrons[cauldron].locked=true; p.stations.cauldron.cauldronId=cauldron
		p.pets["123:starter_brewer"].locked=true; p.pets["123:starter_brewer"].paidOrigin=true; p.pets["123:starter_brewer"].provenance.paidDerived=true
		p.stations.garden.workerId="123:starter_farmer"; p.slimeWorkSeconds["123:starter_slime"]=12
		p.entitlements.test_dlc=true; p.receipts.consumed_product=true
		p.inventory.mandrake=3; p.stations.cauldron.input.mandrake=2; p.stations.cauldron.essence=3
		h.act("brew",{stationId="cauldron"}); h.act("acceptOrder",{orderId="healing_small"})
		Dailies.record(Config,p,"essence",50,h.now); T.truthy(h.run("claimDaily",{questId="essence",expectedDay=Dailies.day(h.now)}))
		local before=H.copy(p); T.truthy(h.rebirth())
		for _,key in ipairs({"pets","cauldrons","nextPetSerial","nextCauldronSerial","entitlements","receipts","collection","progression","trade","tutorial","telemetry","discoveredRecipes","currencyPaid"}) do T.same(p[key],before[key],key) end
		T.same(p.longTerm.daily,before.longTerm.daily); T.same(p.longTerm.calendar,before.longTerm.calendar)
		T.equal(p.gold,0); T.equal(p.essence,0); T.equal(next(p.inventory),nil); T.equal(next(p.questStock),nil); T.equal(p.order,nil)
		T.equal(p.warehouseLevel,0); T.falsy(p.pipes); T.equal(p.lastSimulatedAt,h.now); T.equal(next(p.slimeWorkSeconds),nil); T.equal(next(p.inputCursors),nil)
		for id,station in pairs(p.stations) do
			T.equal(station.level,Config.stations[id].initialLevel); T.equal(station.workerId,nil); T.equal(station.cauldronId,nil); T.equal(station.job,nil)
			T.falsy(station.auto); T.equal(station.progress,0); T.equal(station.essence,0); T.equal(next(station.input),nil); T.equal(next(station.output),nil); T.equal(next(station.questQueue),nil)
		end
		local state=H.copy(p); T.equal(h.engine.advance(p,h.now,true).processedSeconds,0); T.same(p,state)
		T.truthy(h.engine.advance(p,h.now+7200,true).ok); T.equal(p.gold,0); T.equal(p.essence,0)
	end)
	for _,defect in ipairs({"phase","archive-only","old-cycle","no-confirm","paid-gold","paid-essence","trade-negotiating","trade-pending","clock","identity"}) do
		T.test("M5: reset fails closed without mutation / "..defect,function()
			local h=H.new(); h.complete(); local p=h.profile; local payload={expectedRebirthCount=0,confirmed=true}; local ctx={}
			if defect=="phase" then p.phase=3 elseif defect=="archive-only" then p.longTerm.cycle.finalProduced=false
			elseif defect=="old-cycle" then payload.expectedRebirthCount=1 elseif defect=="no-confirm" then payload.confirmed=false
			elseif defect=="paid-gold" then p.currencyPaid.gold=true elseif defect=="paid-essence" then p.currencyPaid.essence=true
			elseif defect=="trade-negotiating" then ctx.tradeActive=true elseif defect=="trade-pending" then p.trade.pending={id="unresolved"}
			elseif defect=="clock" then ctx.now=h.now-1 else ctx.guard=function() return false end end
			local before=H.copy(p); T.falsy(h.run("rebirth",payload,nil,ctx)); T.same(p,before)
		end)
	end
	T.test("M5: archived technology survives but phase and epoch gate access anew",function()
		local h=H.new(); h.complete(); T.truthy(h.rebirth()); local p=h.profile
		T.truthy(p.discoveredRecipes.ascension); T.falsy(h.engine.recipeState(p,"cauldron","ascension").available)
		T.falsy(h.engine.recipeState(p,"distillery","void_plasma").available); T.falsy(h.longTerm.state(p,h.now).available)
		T.truthy(h.engine.recipeState(p,"cauldron","healing").available)
		T.equal(h.engine.recipeState(p,"cauldron","healing").saleValue,16)
		T.falsy(h.engine.act(p,"setRecipe",{stationId="cauldron",recipeId="ascension"},h.now))
	end)
	T.test("M5: old collection and phase receipts survive reset and cannot regrant",function()
		local h=H.new(); T.truthy(h.apply("shopFamiliar",{offerId="slime"})); h.complete()
		local old=H.copy(h.profile); T.truthy(h.rebirth()); local p=h.profile
		local before=H.copy(p); T.truthy(h.collection.apply(p,"shopFamiliar",{offerId="slime",requestId=old.collection.sequence},h.context()))
		T.truthy(h.progression.apply(p,"advancePhase",{expectedPhase=3,requestId=old.progression.sequence},h.engine,h.now)); T.same(p,before)
		-- Earned phase purchases in later cycles use new request IDs; the milestone stays issued even if its item was traded away.
		p.gold=100000; p.cauldrons={}; p.discoveredRecipes.steam_catalyst=true; p.phase=2
		p.stations.cauldron2.level=1; p.stations.cauldron2.recipeId="healing"; p.stations.distillery.level=1; p.stations.distillery.recipeId="fire_extract"
		T.truthy(h.command("advancePhase",{expectedPhase=2})); T.equal(next(p.cauldrons),nil); T.equal(p.nextCauldronSerial,old.nextCauldronSerial)
	end)
	for _,key in ipairs(Config.longTerm.perkOrder) do
		T.test("M5: permanent perk price maximum and replay / "..key,function()
			local h=H.new(); h.complete(); T.truthy(h.rebirth()); local p=h.profile
			T.truthy(h.run("buyRebirthPerk",{perkId=key,expectedLevel=0})); T.equal(p.longTerm.shards,0); T.equal(p.longTerm.perks[key],1)
			local before=H.copy(p); T.truthy(h.run("buyRebirthPerk",{perkId=key,expectedLevel=0,requestId=p.longTerm.sequence})); T.same(p,before)
			T.falsy(h.run("buyRebirthPerk",{perkId=key,expectedLevel=0})); T.same(p,before)
		end)
	end
	T.test("M5: perks affect work/Essence but do not bypass station skill caps",function()
		local h=H.new(); local p=h.profile; p.rebirths=6; p.longTerm.cycle.id=6; p.longTerm.earned=6; p.longTerm.spent=6
		p.longTerm.perks.industry=3; p.longTerm.perks.essence=3
		p.essence=0; h.act("click"); T.equal(p.essence,4)
		T.equal(h.longTerm.state(p,h.now).manualClickEssence,4)
		p.stations.crystal.level=2; h.advance(1); T.equal(p.essence,8)
		p.stations.cauldron.workerId="123:starter_brewer"; p.stations.cauldron.input.mandrake=2; p.stations.cauldron.essence=3
		h.act("brew",{stationId="cauldron"}); T.near(p.stations.cauldron.job.duration,6/1.15/(1+15*Config.brewSpeedPerSkill))
		T.equal(p.pets["123:starter_brewer"].stats.Brewing,25)
	end)
	for _,offer in ipairs(Config.longTerm.choiceOrder) do
		T.test("M5: guaranteed shard choice never draws RNG or needs random permission / "..offer,function()
			local h=H.new(); h.complete(); T.truthy(h.rebirth()); local p=h.profile; local rng=p.rngState
			local ok,result=h.run("chooseRebirthPet",{offerId=offer,confirmed=true},nil,{policy={status="unavailable"},nextInteger=function() error("Random disabled") end})
			T.truthy(ok); T.same(p.pets[result.petId].stats,Config.familiarShop[offer].stats); T.equal(p.pets[result.petId].provenance.source,"rebirth_shop")
			T.equal(p.rngState,rng); T.equal(p.longTerm.shards,0); T.equal(p.longTerm.spent,1)
		end)
	end
	for _,field in ipairs({"gold","shards","reward","epoch","cycleId","serverTime","stats","ownerId","policy","price"}) do
		T.test("M5: forged reset economic fields reject / "..field,function()
			local h=H.new(); local p={expectedRebirthCount=0,confirmed=true,requestId=1}; p[field]=999
			local before=H.copy(h.profile); T.falsy(Protocol.validate("rebirth",p)); T.falsy(h.run("rebirth",p)); T.same(h.profile,before)
		end)
	end
	T.test("M5: epoch strategy is explicit and bounded at large cycle counts",function()
		for _,n in ipairs({0,1,2,3,4,5,999999,1000000}) do
			local p={rebirths=n}; local e=Epochs.rules(Config,p); T.equal(Epochs.id(p),n%3)
			T.truthy(e.cost<=1.2 and e.sale<=1.4 and e.duration>=0.9); T.truthy(Config.recipes[e.finalRecipe])
			T.equal(Epochs.cost(Config,p,100),({100,110,120})[n%3+1])
		end
		T.equal(Access.target("rebirth",{}),"blueprint"); T.falsy(Protocol.validate("rebirth",{expectedRebirthCount=0,requestId=1}))
	end)
end
