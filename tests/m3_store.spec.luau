--!nonstrict
local M=require("./M3Harness")
local Config=require("../src/shared/Config")
local legacy=require("./fixtures/m2-profile")
return function(T: any)
	T.test("M3 migration: authentic V3 preserves rolls, locks, ancestry, receipts and active factory",function()
		local h=M.new(); local before=M.copy(legacy); local migrated,reason=h.engine.migrate(M.copy(legacy))
		T.truthy(migrated,reason); T.equal(migrated.schemaVersion,4)
		for key,value in pairs(legacy) do
			if key=="stations" or key=="manualReadyAt" then for id,old in pairs(value) do T.same(migrated[key][id],old,key.."."..id) end
			elseif key~="schemaVersion" then T.same(migrated[key],value,key) end
		end
		T.equal(migrated.phase,1); T.equal(next(migrated.cauldrons),nil); T.equal(migrated.progression.sequence,0)
		for _,id in ipairs({"garden2","cauldron2","distillery2","mushrooms","berries","press","centrifuge"}) do T.equal(migrated.stations[id].level,0) end
		T.same(legacy,before); T.same(h.engine.migrate(M.copy(migrated)),migrated); T.truthy(h.engine.validate(migrated))
	end)
	T.test("M3 migration: callback replay/lost reply and offline cap do not grant twice",function()
		local h=M.new(); h.now=legacy.lastSimulatedAt; h.record={schemaVersion=1,revision=9,profile=M.copy(legacy)}
		h.replays=3; h.afterFailures=1; local store=h.store(); local p=store:load(123,function() return h.profile end)
		T.truthy(p); T.equal(h.record.revision,10); T.equal(next(p.cauldrons),nil)
		h.now+=10800; local report=h.engine.advance(p,h.now,true); T.equal(report.processedSeconds,7200); T.equal(report.skippedSeconds,3600)
		T.truthy(store:save(123)==false) -- Expired lease cannot persist catch-up on stale owner.
		h.now+=121; local nextStore=h.store("B"); local fresh=nextStore:load(123,function() return h.profile end)
		T.truthy(fresh); T.truthy(h.engine.advance(fresh,h.now,true).ok); T.truthy(nextStore:save(123)); T.truthy(nextStore:release(123))
		local again=h.store("C"); local restored=again:load(123,function() return h.profile end)
		local before=M.copy(restored); T.equal(h.engine.advance(restored,h.now,true).processedSeconds,0); T.same(restored,before)
	end)
	for _,defect in ipairs({"future","unknown-old-fields","old-roll","phase","cauldron-owner","cauldron-bonus","double-equip","locked-slot","future-tech","input-cursor","receipt"}) do
		T.test("M3 persistence: corrupt/future records fail closed / "..defect,function()
			local h=M.new(); h.toPhase(3); local p=M.copy(h.profile); local itemId=next(p.cauldrons)
			if defect=="future" then p.schemaVersion=Config.schemaVersion+1
			elseif defect=="unknown-old-fields" then p=M.copy(legacy); p.cauldrons={}
			elseif defect=="old-roll" then p=M.copy(legacy); p.pets["123:pet:7"].stats.Farming=999
			elseif defect=="phase" then p.phase=0
			elseif defect=="cauldron-owner" then p.cauldrons[itemId].ownerId=999
			elseif defect=="cauldron-bonus" then p.cauldrons[itemId].bonus=1
			elseif defect=="double-equip" then p.stations.cauldron.cauldronId=itemId; p.stations.cauldron2.cauldronId=itemId
			elseif defect=="locked-slot" then p.stations.centrifuge.level=1; p.stations.centrifuge.recipeId="aether_serum"
			elseif defect=="future-tech" then p.discoveredRecipes.ascension=true
			elseif defect=="input-cursor" then p.inputCursors.spore_paste=#Config.machineOrder+1
			else p.progression.sequence=10 end
			h.record={schemaVersion=1,revision=5,profile=p}; local before=M.copy(h.record)
			T.equal(h.store():load(123,function() return h.profile end),nil); T.same(h.record,before); T.equal(h.revisionWrites,0)
		end)
	end
	local function fixture(action)
		local h=M.new()
		if action=="advancePhase" then h.toPhase(2); h.phasePrerequisites()
		elseif action=="equipCauldron" then h.toPhase(3)
		else h.toPhase(2) end
		local store=h.store(); T.truthy(store:load(123,function() return h.profile end))
		local payload=action=="advancePhase" and {expectedPhase=2} or (action=="equipCauldron" and {slotId="cauldron",cauldronId=next(h.profile.cauldrons)} or {upgradeId="garden2",expectedLevel=0})
		payload.requestId=h.profile.progression.sequence+1
		local function execute()
			return store:transact(123,function(candidate) return h.progression.apply(candidate,action,payload,h.engine,h.now) end)
		end
		return h,store,execute,payload
	end
	for _,action in ipairs({"build","advancePhase","equipCauldron"}) do
		for _,mode in ipairs({"before","after"}) do
			T.test("M3 persistence: atomic rollback/reconciliation / "..action.."/"..mode,function()
				local h,store,execute=fixture(action); local before=M.copy(store:get(123))
				if mode=="before" then h.beforeFailures=3 else h.afterFailures=3 end
				T.falsy(execute()); T.same(store:get(123),before); T.falsy(store:isWritable(123)); T.falsy(store:save(123)); T.falsy(store:release(123))
				h.now=100300; local nextStore=h.store("B"); local p=nextStore:load(123,function() return h.profile end)
				T.truthy(p); T.equal(p.progression.sequence,before.progression.sequence+(mode=="after" and 1 or 0))
				if action=="build" then T.equal(p.stations.garden2.level,mode=="after" and 1 or 0)
				elseif action=="advancePhase" then T.equal(p.phase,mode=="after" and 3 or 2); T.equal(M.count(p.cauldrons),mode=="after" and 1 or 0)
				else T.equal(p.stations.cauldron.cauldronId~=nil,mode=="after") end
			end)
		end
	end
	for _,action in ipairs({"build","advancePhase","equipCauldron"}) do
		T.test("M3 persistence: concurrent identical intents commit once / "..action,function()
			local h,store,execute=fixture(action); local entered=0; local before=M.copy(store:get(123))
			h.beforeUpdate=function() entered+=1; if entered==1 then T.same(store:get(123),before); T.falsy(store:isWritable(123)); coroutine.yield() end end
			h.sleep=function() coroutine.yield() end; h.replays=3
			local aResult,bResult
			local a=coroutine.create(function() aResult={execute()} end); local b=coroutine.create(function() bResult={execute()} end)
			T.truthy(coroutine.resume(a)); T.truthy(coroutine.resume(b)); T.truthy(coroutine.resume(a)); T.truthy(coroutine.resume(b))
			T.truthy(aResult[1]); T.truthy(bResult[1]); T.same(aResult[2],bResult[2]); T.equal(h.record.revision,2)
			T.equal(store:get(123).progression.sequence,before.progression.sequence+1)
		end)
	end
	T.test("M3 persistence: committed phase receipt survives rejoin without another milestone item",function()
		local h,store,execute,payload=fixture("advancePhase"); h.afterFailures=1; h.replays=2
		T.truthy(execute()); T.equal(M.count(store:get(123).cauldrons),1); T.truthy(store:release(123))
		local nextStore=h.store("B"); T.truthy(nextStore:load(123,function() return h.profile end))
		T.truthy(nextStore:transact(123,function(p) return h.progression.apply(p,"advancePhase",payload,h.engine,h.now) end))
		T.equal(M.count(nextStore:get(123).cauldrons),1)
	end)
	T.test("M3 persistence: conflicting concurrent construction cannot spend the same request twice",function()
		local h,store,execute,payload=fixture("build"); local entered=0
		h.beforeUpdate=function() entered+=1; if entered==1 then coroutine.yield() end end; h.sleep=function() coroutine.yield() end
		local other=M.copy(payload); other.upgradeId="distillery2"
		local first,second
		local a=coroutine.create(function() first=execute() end)
		local b=coroutine.create(function() second=store:transact(123,function(p) return h.progression.apply(p,"build",other,h.engine,h.now) end) end)
		T.truthy(coroutine.resume(a)); T.truthy(coroutine.resume(b)); T.truthy(coroutine.resume(a)); T.truthy(coroutine.resume(b))
		T.truthy(first); T.falsy(second); T.equal(store:get(123).stations.garden2.level,1); T.equal(store:get(123).stations.distillery2.level,0)
	end)
	T.test("M3 persistence: M2 shop and phase transition share one gate without lost updates",function()
		local h,store,execute=fixture("advancePhase"); local before=M.copy(store:get(123)); local entered=0
		h.beforeUpdate=function() entered+=1; if entered==1 then coroutine.yield() end end; h.sleep=function() coroutine.yield() end
		local first,second
		local a=coroutine.create(function() first=execute() end)
		local b=coroutine.create(function() second=store:transact(123,function(p) return h.collection.apply(p,"shopFamiliar",{offerId="slime",requestId=p.collection.sequence+1},h.context()) end) end)
		T.truthy(coroutine.resume(a)); T.truthy(coroutine.resume(b)); T.truthy(coroutine.resume(a)); T.truthy(coroutine.resume(b))
		T.truthy(first); T.truthy(second); local p=store:get(123)
		T.equal(p.phase,3); T.equal(p.gold,before.gold-1400-120); T.equal(M.count(p.pets),M.count(before.pets)+1); T.equal(M.count(p.cauldrons),1)
	end)
	T.test("M3 persistence: current schema roundtrips equipped locked cauldron and ancestry",function()
		local h=M.new(); h.toPhase(3); local itemId,item=next(h.profile.cauldrons)
		item.provenance.paidDerived=true -- Prepared future-origin fixture; no paid-grant endpoint exists.
		T.truthy(h.command("lockCauldron",{cauldronId=itemId,locked=true}))
		T.truthy(h.command("equipCauldron",{slotId="cauldron",cauldronId=itemId}))
		local store=h.store(); T.truthy(store:load(123,function() return h.profile end)); T.truthy(store:release(123))
		T.same(h.store("B"):load(123,function() return h.engine.newProfile(123,h.now) end),h.profile)
	end)
end
