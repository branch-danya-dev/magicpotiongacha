--!nonstrict
local Config=require("../src/shared/Config")
local M=require("./M3Harness")
return function(T: any)
	for _,recipeId in ipairs({"spore_paste","berry_essence","focus","flare","aether_serum","ascension"}) do
		T.test("M3: manual recipe prepays exactly once and discovers technology / "..recipeId,function()
			local h=M.new(); h.toPhase(4); h.profile.pipes=false
			local recipe=Config.recipes[recipeId]; local slot=recipe.station=="cauldron" and "cauldron2" or (recipe.station=="distillery" and "distillery2" or recipe.station)
			local station=h.built(slot,recipe.requiredLevel,recipeId)
			station.input=M.copy(recipe.inputs); station.essence=recipe.essenceCost
			local reservoir=h.profile.essence; h.act("brew",{stationId=slot})
			T.equal(station.essence,0); T.equal(next(station.input),nil)
			T.falsy(h.engine.act(h.profile,"brew",{stationId=slot},h.now))
			local gold=h.profile.gold; local report=h.advance(math.ceil(station.job.duration))
			T.truthy(h.profile.discoveredRecipes[recipeId]); T.equal(report.produced[recipe.output],1)
			if recipe.kind=="potion" then T.equal(h.profile.gold-gold,recipe.goldValue); T.equal(station.output[recipe.output],nil)
			else T.equal(station.output[recipe.output],1); T.equal(h.profile.gold,gold) end
			T.truthy(h.profile.essence>=reservoir); T.truthy(h.engine.validate(h.profile))
		end)
	end
	T.test("M3: later recipes reject phase/tier/archetype bypass and require manual discovery",function()
		local h=M.new(); T.falsy(h.engine.act(h.profile,"setRecipe",{stationId="cauldron",recipeId="focus"},h.now))
		h.toPhase(4); h.built("cauldron2",1,"healing")
		T.falsy(h.engine.act(h.profile,"setRecipe",{stationId="cauldron2",recipeId="ascension"},h.now))
		h.built("press",1); T.falsy(h.engine.act(h.profile,"setRecipe",{stationId="press",recipeId="healing"},h.now))
		h.act("assign",{stationId="press",petId="123:starter_brewer"})
		T.falsy(h.engine.act(h.profile,"setAuto",{stationId="press",enabled=true},h.now))
	end)
	T.test("M3: two cauldrons reserve one shared NPC quota and export excess",function()
		local h=M.new(); h.toPhase(2); h.profile.pipes=false
		h.built("cauldron2",1,"healing"); h.act("acceptOrder",{orderId="healing_small"})
		for _,id in ipairs({"cauldron","cauldron2"}) do
			local s=h.profile.stations[id]; s.essence=3; s.input.mandrake=2
			h.act("brew",{stationId=id}); s.job.doubleChance=0
		end
		h.profile.questStock.healing=4; local gold=h.profile.gold
		h.advance(8)
		local order=h.engine.orderState(h.profile); T.equal(order.reserved,5); T.equal(order.queued,1); T.equal(h.profile.gold-gold,14)
		T.equal(h.profile.stations.cauldron.questQueue.healing,1); T.equal(h.profile.stations.cauldron2.questQueue.healing,nil)
	end)
	T.test("M3: second cauldron crate follows its own route, survives reassignment and expiry",function()
		local h=M.new(); h.toPhase(2); h.profile.pipes=false; h.built("cauldron2",1,"healing")
		h.act("acceptOrder",{orderId="healing_small"}); h.profile.stations.cauldron2.questQueue.healing=5
		h.act("assign",{stationId="logistics",petId="123:starter_slime"})
		h.advance(1); local job=h.profile.stations.logistics.job
		T.equal(job.sourceStationId,"cauldron2"); T.equal(job.destinationKind,"questStock")
		h.act("assign",{stationId="logistics",petId=""}); local before=M.copy(job); h.advance(10)
		T.same(h.profile.stations.logistics.job,before)
		local gold=h.profile.gold; h.now=h.profile.order.expiresAt; local report=h.engine.advance(h.profile,h.now,true)
		T.truthy(report.ok); T.equal(h.profile.gold-gold,70); T.equal(h.profile.order,nil)
		T.equal(h.profile.stations.logistics.job,nil); T.equal(next(h.profile.stations.cauldron2.questQueue),nil)
		local saved=M.copy(h.profile); T.truthy(h.engine.advance(h.profile,h.now,true).ok); T.same(h.profile,saved)
	end)
	T.test("M3: phase-three stock intake leaves room for every raw source",function()
		local h=M.new(); h.toPhase(3); h.profile.pipes=false; h.profile.warehouseLevel=1
		for _,slot in ipairs({"garden","garden2","mine","mushrooms","berries"}) do
			local s=h.built(slot,1); s.output[Config.stations[slot].outputItem]=30
		end
		h.act("assign",{stationId="logistics",petId="123:starter_slime"}); h.advance(600)
		for _,item in ipairs({"mandrake","coal","mushroom","berry"}) do T.truthy((h.profile.inventory[item] or 0)>0,item); T.truthy(h.profile.inventory[item]<=20) end
		T.truthy(h.engine.storageState(h.profile).raw<=100); T.truthy(h.engine.validate(h.profile))
	end)
	T.test("M3: activating stock shares does not trap or delete earlier cargo",function()
		local h=M.new(); h.toPhase(2); h.profile.warehouseLevel=1; h.profile.inventory.mandrake=50
		h.profile.stations.logistics.job={kind="haul",itemId="mandrake",amount=3,sourceKind="output",sourceStationId="garden",destinationKind="inventory",duration=4}
		h.act("assign",{stationId="logistics",petId="123:starter_slime"}); h.phasePrerequisites()
		T.truthy(h.command("advancePhase",{expectedPhase=2})); h.advance(5)
		local cargo=h.profile.stations.logistics.job
		local total=h.profile.inventory.mandrake+(cargo and cargo.itemId=="mandrake" and cargo.amount or 0)
		for _,station in pairs(h.profile.stations) do total+=(station.input.mandrake or 0) end
		T.equal(total,53); T.truthy(not cargo or cargo.sourceKind~="output"); T.truthy(h.engine.validate(h.profile))
	end)
	T.test("M3: pipes move new liquids but leave solid paste to manual/hauler",function()
		local h=M.new(); h.toPhase(4)
		h.built("press",1,"spore_paste").output.spore_paste=2
		h.built("distillery2",1,"berry_essence").output.berry_essence=2
		h.built("centrifuge",1,"aether_serum"); h.advance(1)
		T.equal(h.profile.stations.press.output.spore_paste,2)
		T.equal(h.profile.stations.centrifuge.input.berry_essence,1); T.equal(h.profile.stations.centrifuge.input.spore_paste,nil)
		h.act("assign",{stationId="logistics",petId="123:starter_slime"}); h.advance(100)
		T.equal(h.profile.stations.centrifuge.input.spore_paste,1)
	end)
	for _,material in ipairs({"spore_paste","berry_essence"}) do
		T.test("M3: scarce shared input alternates consumers across save/rejoin / "..material,function()
			local h=M.new(); h.toPhase(4)
			h.built("cauldron",2,material=="spore_paste" and "focus" or "flare")
			h.built("centrifuge",1,"aether_serum")
			h.act("assign",{stationId="logistics",petId="123:starter_slime"})
			local received={cauldron=0,centrifuge=0}
			for _=1,12 do
				h.profile.inventory[material]=1; h.advance(20)
				for slot in pairs(received) do
					local input=h.profile.stations[slot].input
					received[slot]+=input[material] or 0; input[material]=nil
				end
				-- Resume from validated serialized state between each scarce arrival.
				h.profile=assert(h.engine.migrate(M.copy(h.profile)))
			end
			T.equal(received.cauldron,6); T.equal(received.centrifuge,6)
		end)
	end
	T.test("M3: supply-next changes bounded cursor and round robin resumes",function()
		local h=M.new(); h.toPhase(4); h.built("cauldron2",1,"healing"); h.profile.inventory.mandrake=4
		h.act("assign",{stationId="logistics",petId="123:starter_slime"})
		h.act("prioritize",{stationId="cauldron2"}); local cursor=h.profile.stations.logistics.routeCursor
		T.equal(Config.routes[cursor].slot,"cauldron2"); h.advance(1)
		T.equal(h.profile.stations.logistics.job.destinationStationId,"cauldron2")
		T.truthy(h.profile.stations.logistics.routeCursor~=cursor); h.advance(30)
		T.equal(h.profile.stations.cauldron.input.mandrake,2); T.equal(h.profile.stations.cauldron2.input.mandrake,2)
	end)
	T.test("M3: new contracts require discovered reachable technology and board has at most three",function()
		local h=M.new(); T.falsy(h.engine.orderEligible(h.profile,"focus_small")); T.equal(#h.engine.orderOffers(h.profile),3)
		T.equal(h.engine.orderOffers(h.profile)[1],"healing_small")
		h.toPhase(3); T.falsy(h.engine.orderEligible(h.profile,"focus_small"))
		h.profile.discoveredRecipes.focus=true; T.falsy(h.engine.orderEligible(h.profile,"focus_small"))
		h.built("press",1); h.built("mushrooms",1)
		T.truthy(h.engine.orderEligible(h.profile,"focus_small")); T.truthy(table.find(h.engine.orderOffers(h.profile),"focus_small"))
		h.act("acceptOrder",{orderId="focus_small"}); T.falsy(h.engine.act(h.profile,"acceptOrder",{orderId="healing_small"},h.now))
		h.profile.questStock.focus=4; local gold=h.profile.gold; h.act("claimOrder")
		T.equal(h.profile.gold-gold,500); T.falsy(h.engine.act(h.profile,"claimOrder",{},h.now))
	end)
	T.test("M3: original hauling route indices stay stable for migrated profiles",function()
		local expected={"input:distillery","input:cauldron","output:garden","output:mine","output:distillery","questQueue:distillery","questQueue:cauldron"}
		for index,value in ipairs(expected) do T.equal(Config.routes[index].kind..":"..Config.routes[index].slot,value) end
		T.truthy(#Config.routes<40); T.equal(#Config.stationOrder,13)
	end)
end
