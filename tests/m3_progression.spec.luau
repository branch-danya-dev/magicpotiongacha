--!nonstrict
local Config=require("../src/shared/Config")
local Protocol=require("../src/shared/Protocol")
local Access=require("../src/shared/Access")
local M=require("./M3Harness")
return function(T: any)
	T.test("M3: phase graph prerequisites precede unlocks and fit configured buffers",function()
		for phase=2,4 do
			local def=Config.phases[phase]
			for _,recipe in ipairs(def.recipes) do T.truthy((Config.recipes[recipe].phase or 1)<phase) end
			for slot in pairs(def.stations) do T.truthy(Config.stations[slot].phase<phase) end
		end
		for _,recipe in pairs(Config.recipes) do
			local inputs=0; for item,n in pairs(recipe.inputs) do T.truthy(Config.items[item]); inputs+=n end
			T.truthy(inputs<=Config.machineInputCapacity); T.truthy(recipe.essenceCost<=Config.essenceBufferCapacity)
		end
		T.equal(Config.pipesCost,28); T.equal(Config.stations.crystal.upgradeCosts[2],140)
	end)
	for phase=2,4 do
		T.test("M3: phase purchase is explicit, paid once and opens distinct content / "..phase,function()
			local h=M.new(); h.toPhase(phase-1)
			local before=M.copy(h.profile); T.falsy(h.command("advancePhase",{expectedPhase=phase-1}))
			T.same(h.profile,before); h.phasePrerequisites()
			local gold=h.profile.gold; local sequence=h.profile.progression.sequence+1
			T.truthy(h.command("advancePhase",{expectedPhase=phase-1,requestId=sequence}))
			T.equal(h.profile.phase,phase); T.equal(h.profile.gold,gold-Config.phases[phase].cost)
			local committed=M.copy(h.profile)
			local ok,_,replayed=h.command("advancePhase",{expectedPhase=phase-1,requestId=sequence}); T.truthy(ok); T.truthy(replayed)
			T.same(h.profile,committed); T.equal(M.count(h.profile.cauldrons),phase>=3 and 1 or 0)
			T.truthy(h.engine.validate(h.profile))
		end)
	end
	T.test("M3: insufficient phase funds and skipped/stale phase preserve economy",function()
		local h=M.new(); h.phasePrerequisites(); h.profile.gold=399
		local before=M.copy(h.profile)
		T.falsy(h.command("advancePhase",{expectedPhase=1})); T.falsy(h.command("advancePhase",{expectedPhase=3})); T.same(h.profile,before)
	end)
	for _,slot in ipairs({"garden2","cauldron2","distillery2","mushrooms","berries","press","centrifuge"}) do
		for tier=1,3 do
			T.test("M3: fixed slot tier gate, payment and replay / "..slot.."/"..tier,function()
				local h=M.new(); local phase=Config.stations[slot].tierPhases[tier]
				h.toPhase(phase)
				-- Prepared lower tier isolates this purchase; full earned paths are separate.
				local station=h.profile.stations[slot]; station.level=tier-1; station.recipeId=tier>1 and Config.stations[slot].defaultRecipe or nil
				if tier>1 then station.output={}; station.essence=Config.stations[slot].defaultRecipe and 8 or 0 end
				local gold=h.profile.gold; local sequence=h.profile.progression.sequence+1
				T.truthy(h.command("build",{upgradeId=slot,expectedLevel=tier-1,requestId=sequence}))
				T.equal(h.profile.stations[slot].level,tier); T.equal(h.profile.gold,gold-Config.stations[slot].upgradeCosts[tier])
				local before=M.copy(h.profile)
				T.truthy(h.command("build",{upgradeId=slot,expectedLevel=tier-1,requestId=sequence})); T.same(h.profile,before)
				T.falsy(h.command("build",{upgradeId=slot,expectedLevel=tier-1})); T.same(h.profile,before)
				T.truthy(h.engine.validate(h.profile))
			end)
		end
	end
	T.test("M3: locked slots cannot be bought by bypassing the UI",function()
		local h=M.new(); local before=M.copy(h.profile)
		for _,slot in ipairs({"garden2","cauldron2","distillery2","mushrooms","berries","press","centrifuge"}) do
			T.falsy(h.command("build",{upgradeId=slot,expectedLevel=0})); T.falsy(h.engine.act(h.profile,"buy",{upgradeId=slot,expectedLevel=0},h.now))
		end
		-- Pure engine rejection may advance only time/diagnostics, never currency/buildings.
		T.equal(h.profile.gold,before.gold); T.equal(h.profile.progression.sequence,0)
	end)
	T.test("M3: phase four completion is status only; no Rebirth or reward",function()
		local h=M.new(); h.toPhase(4); T.falsy(h.progression.phaseState(h.profile).complete)
		h.profile.discoveredRecipes.ascension=true; h.profile.longTerm.cycle.finalProduced=true -- Current-cycle production fixture; archive alone is insufficient in V6.
		local before=M.copy(h.profile)
		T.truthy(h.progression.phaseState(h.profile).complete); T.same(h.profile,before); T.equal(h.profile.rebirths,0)
		T.falsy(h.command("advancePhase",{expectedPhase=4})); T.same(h.profile,before)
	end)
	T.test("M3: upgrades preserve prepaid jobs, ingredients, cargo and original stats",function()
		local h=M.new(); h.toPhase(4); local station=h.built("cauldron2",1,"healing")
		h.profile.pipes=false
		station.input.mandrake=2; station.essence=12
		h.act("assign",{stationId="cauldron2",petId="123:starter_brewer"}); h.act("brew",{stationId="cauldron2"})
		local job=M.copy(station.job); local pet=M.copy(h.profile.pets["123:starter_brewer"])
		T.truthy(h.command("build",{upgradeId="cauldron2",expectedLevel=1}))
		T.same(station.job,job); T.same(h.profile.pets[pet.id],pet); T.equal(station.essence,9)
		T.equal(station.job.duration,job.duration)
	end)
	T.test("M3: guaranteed cauldron is owned, unique, capped and cannot duplicate on equip",function()
		local h=M.new(); h.toPhase(3); local itemId,item=next(h.profile.cauldrons)
		T.equal(item.ownerId,123); T.equal(item.bonus,0.05); T.falsy(item.provenance.paidDerived)
		h.built("cauldron2",2,"healing")
		T.truthy(h.command("equipCauldron",{slotId="cauldron",cauldronId=itemId}))
		T.falsy(h.command("equipCauldron",{slotId="cauldron2",cauldronId=itemId}))
		T.falsy(h.command("equipCauldron",{slotId="press",cauldronId=itemId}))
		T.falsy(h.command("equipCauldron",{slotId="cauldron2",cauldronId="other:cauldron:1"}))
		T.truthy(h.command("lockCauldron",{cauldronId=itemId,locked=true})); T.truthy(item.locked)
		local station=h.profile.stations.cauldron; station.input.mandrake=2; station.essence=3
		h.act("brew",{stationId="cauldron"}); T.equal(station.job.doubleChance,0.05)
		local before=M.copy(station.job); T.falsy(h.command("equipCauldron",{slotId="cauldron",cauldronId=""})); T.same(station.job,before)
		h.advance(10); T.truthy(h.command("equipCauldron",{slotId="cauldron",cauldronId=""}))
		T.truthy(h.command("equipCauldron",{slotId="cauldron2",cauldronId=itemId})); T.equal(M.count(h.profile.cauldrons),1)
	end)
	T.test("M3: cauldron bonus cannot exceed production cap or alter active batch",function()
		local h=M.new(); h.toPhase(3); local itemId=next(h.profile.cauldrons)
		local station=h.profile.stations.cauldron; station.level=3; station.workerId="123:starter_brewer"
		local pet=h.profile.pets[station.workerId]; pet.rarity="Legacy"; pet.provenance.source="legacy"; pet.provenance.tradeKnown=false; pet.stats.Brewing=500
		T.truthy(h.command("equipCauldron",{slotId="cauldron",cauldronId=itemId}))
		station.input.mandrake=2; station.essence=3; h.act("brew",{stationId="cauldron"})
		T.near(station.job.doubleChance,math.min(Config.maxDoubleChance,75*0.002+0.05)); T.equal(pet.stats.Brewing,500)
	end)
	for _,field in ipairs({"cost","bonus","ownerId","phase","level","reward","complete","paidDerived"}) do
		T.test("M3: forged economic payload refused / "..field,function()
			local h=M.new(); local payload={upgradeId="garden2",expectedLevel=0,requestId=1}; payload[field]=999
			local before=M.copy(h.profile); T.falsy(h.progression.apply(h.profile,"build",payload,h.engine,h.now)); T.same(h.profile,before)
		end)
	end
	T.test("M3: intents have explicit targets, sequence and bounded expected phase",function()
		T.equal(Access.target("advancePhase",{}),"blueprint"); T.equal(Access.target("build",{upgradeId="garden2"}),"garden2")
		T.equal(Access.target("equipCauldron",{slotId="cauldron2"}),"cauldron2"); T.equal(Access.target("lockCauldron",{}),"altar")
		for _,value in ipairs({0,5,1.5,math.huge,0/0}) do T.falsy(Protocol.validate("advancePhase",{expectedPhase=value,requestId=1})) end
		T.falsy(Protocol.validate("build",{upgradeId="garden2",expectedLevel=0}))
		T.falsy(Protocol.validate("equipCauldron",{slotId="cauldron2",cauldronId="a",requestId=1,ownerId=123}))
	end)
end
