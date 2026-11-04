--!nonstrict
local Config = require("../src/shared/Config")
local Familiars = require("../src/shared/Familiars")
local Protocol = require("../src/shared/Protocol")
local Access = require("../src/shared/Access")
local H = require("./M2Harness")
return function(T: any)
	local model = Familiars.new(Config)
	T.test("M2: exhaustive 100000 draws match every final outcome and tier exactly", function()
		local counts, tiers = {}, {}
		for roll = 1, 100000 do
			local species = model.pick("forest", roll)
			counts[species] = (counts[species] or 0) + 1
			local rarity = Config.petSpecies[species].rarity; tiers[rarity] = (tiers[rarity] or 0) + 1
		end
		T.same(counts, { farmer=24000, slime=23000, brewer=23000, bloom_owl=9000, golden_slime=8000, moon_cat=8000,
			ancient_owl=1650, prism_slime=1650, void_cat=1650, aether_sprite=50 })
		T.same(tiers, { Common=70000, Rare=25000, Legendary=4950, Secret=50 })
	end)
	T.test("M2: all disclosed tuples reconstruct total probability without sampling", function()
		local details, total = model.details("forest"), 0
		for _, outcome in ipairs(details.outcomes) do
			local combos = 0
			for _ = outcome.ranges.Farming[1], outcome.ranges.Farming[2] do
				for _ = outcome.ranges.Hauling[1], outcome.ranges.Hauling[2] do
					for _ = outcome.ranges.Brewing[1], outcome.ranges.Brewing[2] do combos += 1 end
				end
			end
			T.equal(combos, outcome.combinations)
			T.near(outcome.tuplePercent * combos, outcome.percent)
			total += outcome.tuplePercent * combos
		end
		T.near(total, 100)
	end)
	for species, def in pairs(Config.petSpecies) do
		T.test("M2: independent inclusive stat endpoints / " .. species, function()
			for _, high in ipairs({false, true}) do
				local calls = 0
				local stats = model.rollStats(species, function(lo, hi) calls += 1; return high and hi or lo end)
				T.equal(calls, 3)
				for skill, range in pairs(def.ranges) do T.equal(stats[skill], range[high and 2 or 1]) end
			end
			T.throws(function() model.rollStats(species, function(_, hi) return hi + 1 end) end)
		end)
	end
	for _, roll in ipairs({0, -1, 100001, 1.5, math.huge, 0/0}) do
		T.test("M2: invalid rarity roll rejected / " .. tostring(roll), function() T.throws(function() model.pick("forest", roll) end) end)
	end
	for _, defect in ipairs({"weight", "duplicate", "range", "offer", "evolution"}) do
		T.test("M2: invalid design data refuses startup / " .. defect, function()
			local c = H.copy(Config)
			if defect == "weight" then c.summonPools.forest.outcomes[1].weight += 1
			elseif defect == "duplicate" then c.summonPools.forest.outcomes[2].species = "farmer"
			elseif defect == "range" then c.petSpecies.farmer.ranges.Farming = {16, 8}
			elseif defect == "offer" then c.familiarShop.slime.stats.Hauling = 999
			else c.petSpecies.farmer.fuseTo = "farmer" end
			T.throws(function() Familiars.new(c) end)
		end)
	end
	T.test("M2: five summons charge once, unique IDs, separate production RNG", function()
		local h = H.new(); local rng = h.profile.rngState
		local ok, result = h.apply("summon", { poolId="forest", count=5 })
		T.truthy(ok); T.equal(#result.createdIds, 5); T.equal(h.draws, 20)
		T.equal(h.profile.essence, 99750); T.equal(h.profile.rngState, rng)
		local seen = {}; for _, id in ipairs(result.createdIds) do
			T.falsy(seen[id]); seen[id] = true; T.equal(h.profile.pets[id].provenance.source, "gacha")
		end
		T.truthy(h.engine.validate(h.profile))
	end)
	T.test("M2: current retry returns receipt without cost or RNG; old/conflicting ID rejected", function()
		local h = H.new(); local payload = { poolId="forest", count=1, requestId=1 }
		local ok, first = h.apply("summon", payload); T.truthy(ok)
		local snapshot = H.copy(h.profile)
		local again, result, replayed = h.apply("summon", payload)
		T.truthy(again); T.truthy(replayed); T.same(result, first); T.same(h.profile, snapshot); T.equal(h.draws, 4)
		T.falsy(h.apply("summon", { poolId="forest", count=5, requestId=1 }))
		T.truthy(h.apply("petLock", { petId=first.createdIds[1], locked=true }))
		T.falsy(h.apply("summon", payload)); T.equal(h.draws, 4)
	end)
	T.test("M2: collection cooldown includes lock and fixed shop operations", function()
		local h = H.new(); T.truthy(h.apply("shopFamiliar", {offerId="slime"}))
		local before = H.copy(h.profile)
		T.falsy(h.collection.apply(h.profile, "summon", {poolId="forest",count=1,requestId=2},h.context()))
		T.same(h.profile,before); T.equal(h.draws,0)
	end)
	for _, action in ipairs({"summon", "shopFamiliar", "hire"}) do
		T.test("M2: full inventory rejects before charge and RNG / " .. action, function()
			local h=H.new()
			for i=4,Config.maxPets do local id="123:fixture:"..i; h.profile.pets[id]=model.create(id,"slime",Config.hires.slime.stats,"shop",false) end
			local before=H.copy(h.profile)
			local payload=action=="summon" and {poolId="forest",count=1} or (action=="hire" and {speciesId="slime"} or {offerId="slime"})
			T.falsy(h.apply(action,payload)); T.same(h.profile,before); T.equal(h.draws,0)
		end)
	end
	T.test("M2: insufficient Essence cannot consume RNG; cannot use machine Essence", function()
		local h=H.new(); h.profile.essence=49; h.profile.stations.cauldron.essence=24
		local before=H.copy(h.profile); T.falsy(h.apply("summon",{poolId="forest",count=1})); T.same(h.profile,before); T.equal(h.draws,0)
	end)
	T.test("M2: only complete batches fit the remaining inventory", function()
		local h=H.new()
		for i=4,126 do local id="123:fixture:"..i; h.profile.pets[id]=model.create(id,"slime",Config.hires.slime.stats,"shop",false) end
		T.falsy(h.apply("summon",{poolId="forest",count=5})); T.equal(h.draws,0)
		T.truthy(h.apply("summon",{poolId="forest",count=1})); T.equal(H.count(h.profile.pets),127)
	end)
	for _, reason in ipairs({"unknown-pool", "bad-count", "serial-limit", "collision"}) do
		T.test("M2: rejected summon is atomic / "..reason,function()
			local h=H.new(); local payload={poolId="forest",count=1}
			if reason=="unknown-pool" then payload.poolId="unknown" elseif reason=="bad-count" then payload.count=2
			elseif reason=="serial-limit" then h.profile.nextPetSerial=Config.maxCount
			else h.profile.pets["123:pet:1"]=model.create("123:pet:1","slime",Config.hires.slime.stats,"shop",false) end
			local before=H.copy(h.profile); T.falsy(h.apply("summon",payload)); T.same(h.profile,before)
		end)
	end
	for _, offerId in ipairs({"farmer","slime","brewer","bloom_owl","golden_slime","moon_cat","ancient_owl","prism_slime","void_cat","aether_sprite"}) do
		T.test("M2: fixed offer is exact and available without policy / "..offerId,function()
			local h=H.new(); local ctx=h.context(); ctx.policy=nil; ctx.nextInteger=function() error("shop must not draw") end
			local offer=Config.familiarShop[offerId]; local before=h.profile[offer.currency]
			local ok,result=h.apply("shopFamiliar",{offerId=offerId},ctx); T.truthy(ok)
			T.same(h.profile.pets[result.createdIds[1]].stats,offer.stats); T.equal(h.profile[offer.currency],before-offer.cost)
		end)
	end
	for _, species in ipairs({"farmer","slime","brewer","bloom_owl","golden_slime","moon_cat"}) do
		T.test("M2: deterministic monotonic evolution / "..species,function()
			local h=H.new(); local ids=h.buyFive(species); local preview=h.preview(ids)
			for _,id in ipairs(ids) do for skill,value in pairs(h.profile.pets[id].stats) do T.truthy(preview.stats[skill]>=value) end end
			local context=h.context(preview); local beforeGold=h.profile.gold
			local ok,result=h.apply("fuse",{petIds=ids,previewToken=preview.token,confirmed=true},context)
			T.truthy(ok,result); T.equal(H.count(h.profile.pets),4); T.equal(h.profile.gold,beforeGold); T.equal(h.draws,0)
			for _,id in ipairs(ids) do T.equal(h.profile.pets[id],nil) end
			local pet=h.profile.pets[result.createdIds[1]]; T.same(pet.stats,preview.stats); T.same(pet.provenance.parents,preview.parentIds)
			T.equal(pet.species,Config.petSpecies[species].fuseTo); T.truthy(h.engine.validate(h.profile))
		end)
	end
	for _, defect in ipairs({"duplicate","missing","mixed","locked","assigned","terminal","legacy-high","expired","changed","no-confirm"}) do
		T.test("M2: Fuse refuses invalid parents/preview atomically / "..defect,function()
			local h=H.new(); local ids=h.buyFive(defect=="terminal" and "ancient_owl" or "slime")
			local preview = defect~="terminal" and h.preview(ids) or {token="server-preview",expiresAt=h.now+60}
			if defect=="duplicate" then ids[5]=ids[1] elseif defect=="missing" then ids[5]="123:missing"
			elseif defect=="mixed" then ids[5]="123:starter_farmer"
			elseif defect=="locked" then h.profile.pets[ids[2]].locked=true
			elseif defect=="assigned" then h.profile.stations.logistics.workerId=ids[2]
			elseif defect=="legacy-high" then model.upgradeLegacy(h.profile.pets[ids[2]]); h.profile.pets[ids[2]].stats.Hauling=500
			elseif defect=="expired" then preview.expiresAt=h.now
			elseif defect=="changed" then h.profile.pets[ids[2]].stats.Hauling=13 end
			local before=H.copy(h.profile)
			T.falsy(h.apply("fuse",{petIds=ids,previewToken=preview.token,confirmed=defect~="no-confirm"},h.context(preview)))
			T.same(h.profile,before); T.equal(h.draws,0)
		end)
	end
	T.test("M2: improving any parent stat cannot weaken Fuse across all allowed integers",function()
		for species,def in pairs(Config.petSpecies) do
			if def.fuseTo and Config.familiarShop[species] then -- M2 permanent-shop families; M6 seasonal Fuse has its own acquisition/provenance tests.
				local h=H.new(); local ids=h.buyFive(species)
				for skill,range in pairs(def.ranges) do
					local last=-1
					for value=range[1],range[2] do
						h.profile.pets[ids[1]].stats[skill]=value
						local preview=h.collection.preview(h.profile,ids)
						T.truthy(preview.stats[skill]>=last); T.truthy(preview.stats[skill]>=value)
						last=preview.stats[skill]
					end
				end
			end
		end
	end)
	T.test("M2: paid ancestry survives fixed purchases, gacha, lock and Fuse",function()
		local h=H.new(); h.profile.currencyPaid.gold=true; h.profile.currencyPaid.essence=true
		local ids=h.buyFive("slime"); local preview=h.preview(ids)
		T.truthy(preview.paidDerived)
		local ok,result=h.apply("fuse",{petIds=ids,previewToken=preview.token,confirmed=true},h.context(preview)); T.truthy(ok)
		local id=result.createdIds[1]; T.truthy(h.profile.pets[id].paidOrigin)
		T.truthy(h.apply("petLock",{petId=id,locked=true})); T.truthy(h.profile.pets[id].provenance.paidDerived)
		local summoned,reward=h.apply("summon",{poolId="forest",count=1}); T.truthy(summoned)
		T.truthy(h.profile.pets[reward.createdIds[1]].paidOrigin); T.truthy(h.engine.validate(h.profile))
	end)
	T.test("M2: one paid parent taints result; Legacy ancestry and statistics survive",function()
		local h=H.new(); local ids=h.buyFive("slime"); local parent=h.profile.pets[ids[1]]
		parent.paidOrigin=true; model.upgradeLegacy(parent)
		local preview=h.preview(ids); T.truthy(preview.paidDerived); T.equal(parent.rarity,"Legacy")
		local ok,result=h.apply("fuse",{petIds=ids,previewToken=preview.token,confirmed=true},h.context(preview))
		T.truthy(ok); T.truthy(h.profile.pets[result.createdIds[1]].provenance.paidDerived)
	end)
	T.test("M2: Fuse frees four slots even at capacity and removes slime timers",function()
		local h=H.new(); local ids=h.buyFive("slime")
		for i=9,128 do local id="123:fixture:"..i; h.profile.pets[id]=model.create(id,"slime",Config.hires.slime.stats,"shop",false) end
		h.profile.slimeWorkSeconds[ids[1]]=17
		local preview=h.preview(ids)
		T.truthy(h.apply("fuse",{petIds=ids,previewToken=preview.token,confirmed=true},h.context(preview)))
		T.equal(H.count(h.profile.pets),124); T.equal(h.profile.slimeWorkSeconds[ids[1]],nil); T.truthy(h.engine.validate(h.profile))
	end)
	for _, field in ipairs({"stats","species","price","reward","policy","seed","userId","paidOrigin","now"}) do
		T.test("M2: spoofed authority rejected / "..field,function()
			local h=H.new(); local payload={poolId="forest",count=1}; payload[field]=1
			local before=H.copy(h.profile); T.falsy(h.apply("summon",payload)); T.same(h.profile,before); T.equal(h.draws,0)
		end)
	end
	T.test("M2: strict intents reject malformed arrays, IDs, booleans and sequence",function()
		for _,ids in ipairs({ {"a","b","c","d","d"}, {"a","b","c","d"}, {"a","b","c","d","e",extra=true}, {[1]="a",[2]="b",[3]="c",[4]="d",[6]="e"} }) do
			T.falsy(Protocol.validate("previewFuse",{petIds=ids}))
		end
		for _,seq in ipairs({0,-1,1.1,math.huge,0/0,"1"}) do T.falsy(Protocol.validate("petLock",{petId="123:pet:1",locked=true,requestId=seq})) end
		T.falsy(Protocol.validate("petLock",{petId="123:pet:1",locked=1,requestId=1}))
		T.falsy(Protocol.validate("summon",{poolId="forest|x",count=1,requestId=1}))
	end)
	T.test("M2: all collection intents use own altar and shared rate limiter",function()
		for _,action in ipairs({"summon","shopFamiliar","petLock","previewFuse","fuse","refreshPolicy"}) do T.equal(Access.target(action,{}),"altar") end
		T.falsy(Access.allowed(false,true,0,20)); T.falsy(Access.allowed(true,true,21,20))
		local gate=Protocol.new(); local denied=false
		for _=1,100 do if not gate:check(123,"summon",{poolId="forest",count=1,requestId=1},10) then denied=true end end
		T.truthy(denied)
	end)
end
