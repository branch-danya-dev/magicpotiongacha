--!nonstrict
local scenario=require("./M3Scenario")
local H=require("./M5Harness")
local Config=require("../src/shared/Config")
local Epochs=require("../src/shared/Epochs")
local LongTerm=require("../src/shared/LongTerm")
return function(T:any)
	local baselines={}; local model=LongTerm.new(Config)
	for _,strategy in ipairs({"manual","automation","detour"}) do
		local previous
		for epoch=0,2 do
			T.test("M5 F2P: four phases, real final batch, no familiar RNG / "..strategy.."/epoch"..epoch,function()
				local initial
				if epoch>0 then
					T.truthy(previous,"Previous zero-admin cycle must complete")
					local p,e,now=previous.profile,previous.engine,previous.now
					local pets,cauldrons=H.copy(p.pets),H.copy(p.cauldrons)
					T.truthy(model.apply(p,"rebirth",{expectedRebirthCount=epoch-1,confirmed=true,requestId=p.longTerm.sequence+1},e,{now=now}))
					T.equal(p.gold,0); T.equal(p.essence,0); T.equal(p.phase,1); T.same(p.pets,pets); T.same(p.cauldrons,cauldrons)
					T.truthy(model.apply(p,"buyRebirthPerk",{perkId="industry",expectedLevel=epoch-1,requestId=p.longTerm.sequence+1},e,{now=now}))
					T.equal(p.longTerm.shards,0); T.equal(p.longTerm.perks.industry,epoch)
					initial={profile=p,engine=e,now=now}
				end
				local r=scenario(strategy,initial); previous=r
				if strategy=="automation" then baselines[epoch]=H.copy(r.profile); baselines[epoch].testNow=r.now end
				T.equal(#r.phases,3); T.equal(r.epoch,epoch); T.equal(r.profile.phase,4); T.truthy(r.profile.longTerm.cycle.finalProduced)
				T.truthy(r.profile.discoveredRecipes[Epochs.rules(Config,r.profile).finalRecipe]); T.equal(r.profile.rebirths,epoch)
				T.equal(H.count(r.profile.cauldrons),1); T.equal(r.profile.gold,r.income-r.spent)
				for _,phase in ipairs(r.phases) do
					print(string.format("M5_ECONOMY %s epoch=%d phase=%d time=%ds clicks=%d harvests=%d income=%d spent=%d Gold=%d",strategy,epoch,phase.phase,phase.seconds,phase.clicks,phase.harvests,phase.income,phase.spent,phase.gold))
				end
				print(string.format("M5_COMPLETE %s epoch=%d finalBatch=%ds fullSetup=%ds clicks=%d harvests=%d discards=%d income=%d spent=%d final1200s=%d pets=%d",strategy,epoch,r.completeAt,r.setupAt,r.clicks,r.harvests,r.discards,r.income,r.spent,r.finalSales[Epochs.rules(Config,r.profile).finalRecipe] or 0,H.count(r.profile.pets)))
			end)
		end
		T.test("M5 F2P: earned third reset wraps to Classic with bounded benefit / "..strategy,function()
			T.truthy(previous); local p,e,now=previous.profile,previous.engine,previous.now
			T.equal(p.rebirths,2); T.truthy(model.apply(p,"rebirth",{expectedRebirthCount=2,confirmed=true,requestId=p.longTerm.sequence+1},e,{now=now}))
			T.equal(Epochs.id(p),0); T.equal(p.longTerm.earned,3); T.equal(p.longTerm.spent,2); T.equal(p.longTerm.shards,1)
			T.truthy(model.apply(p,"buyRebirthPerk",{perkId="industry",expectedLevel=2,requestId=p.longTerm.sequence+1},e,{now=now}))
			T.equal(p.longTerm.perks.industry,3); T.near(Epochs.work(p),1.15); T.equal(p.phase,1); T.equal(p.gold,0)
		end)
	end
	for epoch=0,2 do
		T.test("M5 F2P: epoch factory exact 7200-second online/offline parity / "..epoch,function()
			local saved=baselines[epoch]; T.truthy(saved); local now=saved.testNow; saved.testNow=nil
			local online,offline=H.copy(saved),H.copy(saved); local e=H.new().engine
			for i=1,7200 do T.truthy(e.advance(online,now+i,false).ok) end
			T.truthy(e.advance(offline,now+7200,true).ok); T.same(online,offline)
			local checkpoint=H.copy(offline); T.truthy(e.advance(offline,now+7200,true).ok); T.same(offline,checkpoint)
			T.equal(offline.longTerm.shards,saved.longTerm.shards); T.equal(offline.longTerm.calendar.lastDay,saved.longTerm.calendar.lastDay)
		end)
	end
end
