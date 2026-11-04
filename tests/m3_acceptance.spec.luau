--!nonstrict
local scenario=require("./M3Scenario")
local M=require("./M3Harness")
return function(T: any)
	local baseline
	for _,strategy in ipairs({"manual","automation","detour"}) do
		T.test("M3 F2P: four phases from zero, no familiar RNG / "..strategy,function()
			local r=scenario(strategy); if strategy=="automation" then baseline=r end
			T.equal(#r.phases,3); T.equal(r.profile.phase,4); T.truthy(r.profile.discoveredRecipes.ascension)
			T.equal(r.profile.rebirths,0); T.equal(M.count(r.profile.cauldrons),1); T.equal(r.profile.gold,r.income-r.spent)
			for _,phase in ipairs(r.phases) do
				print(string.format("M3_ECONOMY %s phase=%d time=%ds clicks=%d harvests=%d income=%d spent=%d Gold=%d",strategy,phase.phase,phase.seconds,phase.clicks,phase.harvests,phase.income,phase.spent,phase.gold))
			end
			print(string.format("M3_COMPLETE %s firstAscension=%ds fullSetup=%ds clicks=%d harvests=%d discards=%d income=%d spent=%d focus1200s=%d ascension1200s=%d",strategy,r.completeAt,r.setupAt,r.clicks,r.harvests,r.discards,r.income,r.spent,r.finalSales.focus or 0,r.finalSales.ascension or 0))
		end)
	end
	T.test("M3: complete multistation factory has exact 7200-second online/offline parity",function()
		T.truthy(baseline); local online,offline=M.copy(baseline.profile),M.copy(baseline.profile)
		for i=1,7200 do T.truthy(baseline.engine.advance(online,baseline.now+i,false).ok) end
		T.truthy(baseline.engine.advance(offline,baseline.now+7200,true).ok); T.same(online,offline)
		local saved=M.copy(offline); T.truthy(baseline.engine.advance(offline,baseline.now+7200,true).ok); T.same(offline,saved)
	end)
	T.test("M3: bounded eight-plot synthetic catch-up workload",function()
		T.truthy(baseline); local profiles={}; for i=1,8 do profiles[i]=M.copy(baseline.profile) end
		local start=os.clock()
		for _,profile in ipairs(profiles) do T.truthy(baseline.engine.advance(profile,baseline.now+7200,true).ok) end
		local elapsed=os.clock()-start
		for i=2,8 do T.same(profiles[i],profiles[1]) end
		profiles[1].gold+=1; T.truthy(profiles[1].gold~=profiles[2].gold)
		print(string.format("M3_BENCH 8 independent snapshots x 13 slots x 7200 ticks: %.3f CPU seconds; portable only, no FPS/replication claim",elapsed))
	end)
end
