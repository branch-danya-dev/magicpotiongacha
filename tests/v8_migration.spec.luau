--!nonstrict
-- C00b: V8 is an additive projection. Historical profiles keep their bytes.
local Config = require("../src/shared/Config")
local Factory = require("../src/shared/Factory")
local ProfileStore = require("../src/server/ProfileStore")
local Settings = require("../src/server/ServerSettings")
local Monetization = require("../src/shared/Monetization")
local M6 = require("./M6Harness")
local v1 = require("./fixtures/m0-profile")
local v2 = require("./fixtures/m1-profile")
local v3 = require("./fixtures/m2-profile")
local v4 = require("./fixtures/m3-profile")
local v5 = require("./fixtures/m4-pending").profile
local pendingV6 = require("./fixtures/m5-progression-pending")
local function copy(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for key, child in pairs(value) do result[key] = copy(child) end
	return result
end
local function count(map)
	local total = 0
	for _ in pairs(map) do total += 1 end
	return total
end
local projectionKeys = { "layout", "temple", "seeds", "plants", "outputMode", "potionStacks", "uniquePotions", "atlas", "starter", "workforce", "charms" }
local function strip(profile)
	local body = copy(profile)
	for _, key in ipairs(projectionKeys) do body[key] = nil end
	return body
end

return function(T: any)
	local engine = Factory.new(Config)
	local function expectProjection(profile)
		T.equal(profile.schemaVersion, 8)
		T.truthy(engine.validate(profile))
		T.equal(profile.layout.legacy, true)
		T.equal(count(profile.layout.placements), #Config.stationOrder)
		T.equal(#Config.stationOrder, 13)
		for _, id in ipairs(Config.stationOrder) do
			local place = profile.layout.placements[id]
			local offset = Config.stations[id].offset
			T.equal(place.instanceId, "legacy:" .. id, id)
			T.equal(place.slotId, id)
			T.equal(place.archetype, Config.stations[id].archetype)
			T.equal(place.x, offset[1])
			T.equal(place.y, offset[2])
			T.equal(place.z, offset[3])
			T.equal(place.rotation, 0)
			T.equal(place.legacy, true)
			T.truthy(profile.stations[id])
			if Config.stations[id].defaultRecipe then T.equal(profile.outputMode[id], "auto-sell")
			else T.equal(profile.outputMode[id], nil) end
		end
		for _, id in ipairs({ "warehouse", "orders", "altar", "blueprint", "garden", "mine", "crystal", "logistics" }) do
			T.equal(profile.outputMode[id], nil, id)
		end
		T.equal(profile.layout.placements.warehouse, nil)
		T.equal(profile.temple.level, profile.phase)
		T.equal(profile.temple.tracksPhase, true)
		T.same(profile.temple.envelope, { minX = -42.5, maxX = 42.5, minZ = -49.5, maxZ = 33.5 })
		T.same(profile.temple.buildable, { minX = -38.5, maxX = 38.5, minZ = -45.5, maxZ = 29.5 })
		T.same(profile.seeds, {})
		T.same(profile.plants, {})
		T.same(profile.potionStacks, {})
		T.same(profile.uniquePotions, {})
		T.equal(profile.nextPotionSerial, nil)
		T.same(profile.atlas.discovered, profile.discoveredRecipes)
		if profile.starter.legacyGrant then
			T.same(profile.starter, { claimed = true, legacyGrant = true })
			T.equal(profile.starter.choice, nil)
		else
			T.equal(profile.starter.claimed, false)
			T.equal(profile.starter.legacyGrant, false)
			T.equal(profile.starter.choice, nil)
			T.same(profile.automation, { replant = false, harvest = false, supply = false, brew = false })
			T.equal(count(profile.pets), 0)
		end
		T.same(profile.workforce, { ownedCap = Config.maxPets })
		T.equal(profile.workforce.activeCap, nil)
		T.same(profile.charms, { active = {} })
		for _, pet in pairs(profile.pets) do T.equal(pet.xp, nil) end
	end
	local function retain(source, migrated)
		for key, value in pairs(source) do
			if key == "schemaVersion" then
			elseif key == "stations" or key == "manualReadyAt" then
				if source.schemaVersion >= 2 or key == "manualReadyAt" then
					for id, old in pairs(value) do T.same(migrated[key][id], old, key .. "." .. id) end
				end
			elseif key == "pets" and source.schemaVersion < 3 then
				for id, pet in pairs(value) do
					for field, old in pairs(pet) do T.same(migrated.pets[id][field], old, id .. "." .. field) end
					T.equal(migrated.pets[id].rarity, "Legacy")
					T.equal(migrated.pets[id].provenance.source, "legacy")
				end
			else
				T.same(migrated[key], value, key)
			end
		end
		T.equal(count(migrated.pets), count(source.pets))
		T.equal(migrated.gold, source.gold)
		T.equal(migrated.essence, source.essence)
		T.equal(migrated.rngState, source.rngState)
		T.same(migrated.inventory, source.inventory)
	end
	local function roundTrip(source)
		local untouched = copy(source)
		local migrated, reason = engine.migrate(copy(source))
		T.truthy(migrated, reason)
		T.same(source, untouched)
		retain(source, migrated)
		expectProjection(migrated)
		T.equal(engine.migrate(migrated), migrated)
		local again = copy(migrated)
		T.equal(engine.migrate(again), again)
		T.same(again, migrated)
		T.equal(again.nextPetSerial, migrated.nextPetSerial)
		T.equal(count(again.pets), count(migrated.pets))
		local body = strip(migrated)
		body.schemaVersion = 7
		local remigrated = assert(engine.migrate(copy(body)))
		local rebuilt = strip(remigrated)
		rebuilt.schemaVersion = 7
		T.same(rebuilt, body)
		T.equal(remigrated.gold, source.gold)
		return migrated
	end

	T.test("V8 migration: new profiles keep schema 8 and do not grant three familiars", function()
		local profile = engine.newProfile(123, 100023)
		T.equal(Config.schemaVersion, 8)
		T.equal(Config.pipesCost, 28)
		T.equal(Config.stations.crystal.upgradeCosts[2], 140)
		T.equal(Config.maxPets, 128)
		T.equal(#Config.starterPets, 3)
		T.equal(profile.gold, 0)
		T.equal(profile.essence, 0)
		T.equal(profile.phase, 1)
		T.equal(count(profile.pets), 0)
		expectProjection(profile)
		T.equal(engine.migrate(profile), profile)
	end)

	for _, entry in ipairs({
		{ "V1", v1 }, { "V2", v2 }, { "V3", v3 }, { "V4", v4 }, { "V5", v5 }, { "V6", pendingV6.pending },
	}) do
		T.test("V8 migration: historical " .. entry[1] .. " keeps resources, pets and station ids", function()
			roundTrip(entry[2])
		end)
	end

	T.test("V8 migration: stored V7 keeps an active haul, quest queue and receipt-free balances", function()
		local current = roundTrip(v2)
		local stored = strip(current)
		stored.schemaVersion = 7
		local migrated = assert(engine.migrate(copy(stored)))
		T.same(migrated.stations.logistics.job, v2.stations.logistics.job)
		T.same(migrated.stations.cauldron.questQueue, v2.stations.cauldron.questQueue)
		T.same(migrated.stations.distillery.job, v2.stations.distillery.job)
		T.equal(migrated.stations.cauldron.questQueue.healing, 2)
		T.same(migrated.order, v2.order)
		T.equal(migrated.gold, v2.gold)
		T.equal(migrated.essence, v2.essence)
		T.same(migrated.inventory, v2.inventory)
		T.same(migrated.questStock, v2.questStock)
		expectProjection(migrated)
	end)

	T.test("V8 migration: locked familiar, locked resonant cauldron and serials survive", function()
		local pets = roundTrip(v3)
		local gear = roundTrip(v4)
		T.equal(pets.pets["123:pet:7"].locked, true)
		T.equal(gear.cauldrons["123:cauldron:1"].locked, true)
		T.equal(gear.cauldrons["123:cauldron:1"].type, "resonant")
		T.equal(gear.nextCauldronSerial, v4.nextCauldronSerial)
		T.equal(pets.nextPetSerial, v3.nextPetSerial)
		T.equal(count(pets.pets), count(v3.pets))
	end)

	T.test("V8 migration: pending trades and V7 purchase proofs are not rewritten", function()
		local prepared = roundTrip(v5)
		local committed = roundTrip(pendingV6.pending)
		T.same(prepared.trade, v5.trade)
		T.truthy(prepared.trade.pending)
		T.same(committed.trade.pending, pendingV6.pending.trade.pending)
		T.equal(committed.trade.sequence, pendingV6.pending.trade.sequence)
		local h = M6.new()
		T.truthy(h.process())
		h.receipt = { PlayerId = 101, ProductId = 1002, PurchaseId = "cauldron-lock" }
		T.truthy(h.process())
		local snapshot = copy(h.profile())
		snapshot.pets["101:starter_farmer"].locked = true
		local spectralId = nil
		for id, item in pairs(snapshot.cauldrons) do
			if item.type == "spectral" then item.locked = true; spectralId = id end
		end
		T.truthy(spectralId)
		local v7 = strip(snapshot)
		v7.schemaVersion = 7
		local migrated = assert(engine.migrate(copy(v7)))
		T.same(migrated.monetization, snapshot.monetization)
		T.same(migrated.pets, snapshot.pets)
		T.same(migrated.cauldrons, snapshot.cauldrons)
		T.equal(migrated.pets["101:starter_farmer"].locked, true)
		T.equal(migrated.cauldrons[spectralId].locked, true)
		T.equal(migrated.nextPetSerial, snapshot.nextPetSerial)
		T.equal(migrated.nextCauldronSerial, snapshot.nextCauldronSerial)
		T.equal(migrated.gold, snapshot.gold)
		T.equal(migrated.essence, snapshot.essence)
		T.same(migrated.monetization.receipts, snapshot.monetization.receipts)
		T.equal(count(migrated.monetization.receipts) >= 1, true)
		T.same(Monetization.initial().receipts, {})
	end)

	T.test("V8 simulation: migration adds no Gold and one tick matches the pre-V8 oracle", function()
		local source = copy(v1)
		local migrated = assert(engine.migrate(copy(source)))
		T.equal(migrated.gold, source.gold)
		T.equal(migrated.essence, source.essence)
		T.equal(migrated.rngState, source.rngState)
		T.same(migrated.inventory, source.inventory)
		T.same(migrated.potionStacks, {})
		local left = copy(migrated)
		local right = copy(migrated)
		local layout = copy(migrated.layout)
		local first = engine.advance(left, source.lastSimulatedAt + 8, true)
		local second = engine.advance(right, source.lastSimulatedAt + 8, true)
		T.truthy(first.ok)
		T.same(first, second)
		T.same(left, right)
		T.same(left.layout, layout)
		T.same(left.seeds, {})
		T.same(left.plants, {})
		T.same(left.potionStacks, {})
		T.same(left.uniquePotions, {})
		T.same(left.charms, migrated.charms)
		T.equal(left.inventory.fire_extract, 2)
		T.equal(left.stations.distillery.output.fire_extract, 1)
		T.equal(left.essence, source.essence + 8)
		T.equal(left.gold, right.gold)
		local replay = copy(migrated)
		engine.advance(replay, source.lastSimulatedAt + 8, true)
		T.equal(replay.gold, left.gold)
		T.equal(replay.essence, left.essence)
		T.same(replay.inventory, left.inventory)
	end)

	local function unchanged(record, userId)
		local before = copy(record)
		local written = false
		local backend = { UpdateAsync = function(_, _, transform)
			local produced = transform(copy(record))
			if produced then written = true; record = copy(produced) end
			return copy(produced)
		end }
		local store = ProfileStore.new({ dataStore = backend, now = function() return 200000 end, owner = "c00b",
			validate = engine.validate, migrate = engine.migrate, sleep = function() end })
		local loaded = store:load(userId or record.profile.userId, function() return engine.newProfile(record.profile.userId or 123, 200000) end)
		T.falsy(loaded)
		T.falsy(written)
		T.same(record, before)
		T.equal(record.revision, before.revision)
	end

	for _, defect in ipairs({ "zero", "nine", "ninety-nine", "fraction", "garbage", "missing-layout", "v4-layout", "v4-trade", "v7-layout", "wrong-user" }) do
		T.test("V8 migration: corrupt profile is not replaced / " .. defect, function()
			local profile
			if defect == "v4-layout" or defect == "v4-trade" then profile = copy(v4)
			elseif defect == "v7-layout" then
				profile = strip(engine.newProfile(123, 100023))
				profile.schemaVersion = 7
			else profile = copy(v1) end
			if defect == "zero" then profile.schemaVersion = 0
			elseif defect == "nine" then profile.schemaVersion = 9
			elseif defect == "ninety-nine" then profile.schemaVersion = 99
			elseif defect == "fraction" then profile.schemaVersion = 8.5
			elseif defect == "garbage" then
				profile = engine.newProfile(123, 100023)
				profile.layout = { legacy = true, placements = {}, extra = true }
			elseif defect == "missing-layout" then
				profile = engine.newProfile(123, 100023)
				profile.layout = nil
			elseif defect == "v4-layout" then profile.layout = {}
			elseif defect == "v4-trade" then profile.trade = { sequence = 0 }
			elseif defect == "v7-layout" then profile.layout = {}
			else profile.userId = 456 end
			local record = { schemaVersion = 1, revision = 4, lastOperationId = "kept", profile = profile }
			unchanged(record, defect == "wrong-user" and 123 or profile.userId)
			if defect == "wrong-user" then T.truthy(engine.migrate(copy(profile)))
			else T.equal(engine.migrate(copy(profile)), nil) end
		end)
	end

	T.test("V8 migration: release switches stay off", function()
		T.equal(Settings.TradingEnabled, false)
		T.equal(Settings.TradingQAPlaceId, 0)
		T.equal(Settings.MonetizationEnabled, false)
		T.equal(Settings.PurchaseQAApproved, false)
		T.equal(Settings.PurchaseQAPlaceId, 0)
		T.equal(Settings.EnvironmentArtEnabled, false)
		T.equal(Settings.UseMemoryInStudio, true)
		T.equal(Settings.DataStoreName, "PotionTycoon_M0_dev_v1")
		T.equal(Settings.PlotCount, 8)
		for _, sku in pairs(Settings.PurchaseSkus) do T.equal(sku, 0) end
	end)
end
