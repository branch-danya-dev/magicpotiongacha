--!nonstrict
local Config=require("../src/shared/Config")
local H=require("./M2Harness")
local scenario=require("./M2Scenario")
local legacy=require("./fixtures/m1-profile")
return function(T: any)
	T.test("M2 migration: genuine V2 preserves every existing field, cargo and paid job",function()
		local h=H.new(); local before=H.copy(legacy); local p=h.engine.migrate(H.copy(legacy))
		T.truthy(p); T.truthy(h.engine.validate(p)); T.equal(p.schemaVersion,Config.schemaVersion)
		for key,value in pairs(legacy) do
			if key=="pets" then
				for id,pet in pairs(value) do
					for field,v in pairs(pet) do T.same(p.pets[id][field],v,id.."."..field) end
					T.equal(p.pets[id].rarity,"Legacy"); T.equal(p.pets[id].provenance.source,"legacy")
					T.equal(p.pets[id].provenance.paidDerived,pet.paidOrigin)
				end
			elseif key=="stations" or key=="manualReadyAt" then
				for id, old in pairs(value) do T.same(p[key][id],old,key.."."..id) end
			elseif key~="schemaVersion" then T.same(p[key],value,key) end
		end
		T.same(legacy,before); T.same(h.engine.migrate(H.copy(p)),p)
		T.equal(p.collection.sequence,0); T.same(p.currencyPaid,{gold=false,essence=false})
	end)
	T.test("M2 migration: V2 callback replay/lost response upgrades only once",function()
		local h=H.new(); h.record={schemaVersion=1,revision=5,profile=H.copy(legacy)}
		h.replays=2; h.afterFailures=1; h.now=legacy.lastSimulatedAt
		local store=h.store(); local p=store:load(123,function() return h.profile end)
		T.truthy(p); T.equal(h.record.revision,6); T.equal(H.count(p.pets),H.count(legacy.pets))
		T.truthy(store:release(123)); local nextStore=h.store("B")
		T.same(nextStore:load(123,function() return h.profile end),p)
	end)
	T.test("M2 migration: pending jobs and cargo have identical online/offline completion",function()
		local h=H.new(); local online=h.engine.migrate(H.copy(legacy)); local offline=H.copy(online)
		for i=1,120 do T.truthy(h.engine.advance(online,legacy.lastSimulatedAt+i,false).ok) end
		T.truthy(h.engine.advance(offline,legacy.lastSimulatedAt+120,true).ok); T.same(online,offline)
		local done=H.copy(offline); T.truthy(h.engine.advance(offline,legacy.lastSimulatedAt+120,true).ok); T.same(offline,done)
	end)
	for _,defect in ipairs({"future","bad-old-tank","bad-old-pet","missing-origin","paid-laundering","out-of-range","wrong-stage","bad-receipt","bad-paid-currency"}) do
		T.test("M2 migration: invalid saves preserved, never replaced / "..defect,function()
			local h=H.new(); local p=h.engine.migrate(H.copy(legacy))
			if defect=="future" then p.schemaVersion=Config.schemaVersion+1
			elseif defect=="bad-old-tank" then p=H.copy(legacy); p.stations.cauldron.essence=-1
			elseif defect=="bad-old-pet" then p=H.copy(legacy); p.pets["123:starter_farmer"].stats.Farming=0/0
			elseif defect=="missing-origin" then p.pets["123:starter_farmer"].provenance=nil
			elseif defect=="paid-laundering" then p.pets["123:starter_farmer"].provenance.paidDerived=false
			elseif defect=="out-of-range" then p=H.copy(h.profile); p.pets["123:starter_farmer"].stats.Farming=500
			elseif defect=="wrong-stage" then p=H.copy(h.profile); p.pets["123:starter_farmer"].evolution=1
			elseif defect=="bad-receipt" then p.collection.sequence=1
			else p.currencyPaid.essence="false" end
			h.record={schemaVersion=1,revision=5,profile=p}; local before=H.copy(h.record)
			T.equal(h.store():load(123,function() return h.profile end),nil)
			if defect=="bad-old-pet" then T.truthy(h.record.profile.pets["123:starter_farmer"].stats.Farming~=h.record.profile.pets["123:starter_farmer"].stats.Farming)
			else T.same(h.record,before) end
			T.equal(h.revisionWrites,0)
		end)
	end
	for _,status in ipairs({"restricted","unavailable"}) do
		T.test("M2 F2P: zero resources through tutorial, fixed Fuse and autonomous Rage / "..status,function()
			local result=scenario(status)
			T.truthy(result.engine.tutorialState(result.profile).complete)
			T.equal(result.profile.pets[result.evolved].species,"golden_slime")
			T.truthy(result.profile.discoveredRecipes.rage); T.truthy(result.automaticRage>0)
			T.equal(result.profile.collection.sequence,8) -- Five fixed parents, Fuse, two role hires.
			print(string.format("M2_ECONOMY %s: evolved=%ds rage=%ds autoRage1200s=%d Gold=%d Essence=%d",status,result.evolvedAt,result.rageAt,result.automaticRage,result.gold,result.essence))
			local p=result.profile; local online,offline=H.copy(p),H.copy(p)
			for i=1,600 do T.truthy(result.engine.advance(online,result.now+i,false).ok) end
			T.truthy(result.engine.advance(offline,result.now+600,true).ok); T.same(online,offline)
		end)
	end
	T.test("M2: station caps affect new forms without changing base stats",function()
		local h=H.new(); local ok,result=h.apply("shopFamiliar",{offerId="aether_sprite"}); T.truthy(ok)
		local pet=h.profile.pets[result.createdIds[1]]; local base=H.copy(pet.stats)
		T.truthy(h.engine.act(h.profile,"assign",{stationId="garden",petId=pet.id},h.now))
		T.equal(h.engine.productionState(h.profile).garden.effectiveSkill,Config.stations.garden.statCaps[1])
		T.same(pet.stats,base); T.truthy(h.engine.validate(h.profile))
	end)
end
