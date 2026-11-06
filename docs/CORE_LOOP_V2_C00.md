# C00 — Architecture inventory and V8 migration contract

**Status: CONTRACT, with sections 6–7 implemented by C00b.** Recorded against `design/core-loop-v2-cursor` at `5779c902b3d31f1163c04faffb56dd76e35a82a9`.
**Product target:** [CORE_LOOP_V2_SPEC.md](CORE_LOOP_V2_SPEC.md). **Task order:** [CORE_LOOP_V2_CURSOR_BACKLOG.md](CORE_LOOP_V2_CURSOR_BACKLOG.md).
**Implemented gameplay truth:** M0–M6 rules in [DESIGN.md](DESIGN.md), [PERSISTENCE.md](PERSISTENCE.md), [ARCHITECTURE.md](ARCHITECTURE.md), and the M1–M6 rule documents. M7 art stays on Draft PR #17 and is not accepted here.

C00b implements sections 6–7 only. `Config.schemaVersion` is **8**. `Factory.migrate` accepts gameplay V1–V8 and rejects every other version. Simulation, Protocol, prices, flags, art, and the three-familiar `newProfile` grant are unchanged. Release switches stay off.

Unresolved owner numbers are written as `TBD`. They are not provisional prices.

## 1. What the current tree actually is

The branch contains the Rojo game (`default.project.json`, `src/client`, `src/server`, `src/shared`) plus the portable Luau suite. It is the M7 head plus the V2 design notes, not a V2 gameplay build.

| Layer | Path | What it owns today |
| --- | --- | --- |
| Economy tables | `src/shared/Config.luau` | `schemaVersion = 7`, 13 stations, recipes, phases, epochs, orders, familiars, fixed offers |
| Frozen M2 vocabulary | `src/shared/LegacyConfig.luau` | Validation of gameplay V1–V3 only (`schemaVersion` 3, six stations) |
| Simulation and profile shape | `src/shared/Factory.luau` | `validate`, `migrate`, `newProfile`, one-second `advance`, immediate potion sale |
| Phase / rare cauldron | `src/shared/Progression.luau` | Four phase gates, slot build, equip/lock, progression receipt |
| Rebirth / dailies | `src/shared/LongTerm.luau`, `Epochs.luau`, `Dailies.luau` | Atomic reset of listed factory fields; three epochs; UTC goals |
| Familiars | `src/shared/Familiars.luau`, `Collection.luau` | Instance stats, provenance, Fuse, locks; collection cap 128 |
| Purchases | `src/shared/Monetization.luau`, `OfferCatalog.luau`, `ItemOrigin.luau` | V7 proof/queue. No live SKUs |
| Trading | `src/shared/Trading.luau`, `TradeCodec.luau`, `TradeSession.luau` | Reserve/apply/clear. Public trading off |
| Intents | `src/shared/Protocol.luau`, `Access.luau` | Closed action schemas. Targets are fixed ids |
| Persistence | `src/server/ProfileStore.luau` | Envelope v1, key `p:<userId>`, lease, revision. One profile is not a trade |
| Separate journals | `TradeJournal.luau`, `ReceiptJournal.luau` plus coordinators | Trade CAS and purchase CAS. Not inside the profile blob |
| Presentation | `src/server/World.luau`, `src/client/Main.client.luau` | Greybox anchors named by slot id. Clients do not grant rewards |
| M7 art (gated) | `Environment*.luau`, `IslandTerrain.luau`, `PropArt.luau`, `FarmLandscape.luau` | Terrain and props. `EnvironmentArtEnabled = false` |

`src/server/ServerSettings.luau` is the live switch file:

| Switch | Current value |
| --- | --- |
| `TradingEnabled` | `false` |
| `TradingQAPlaceId` | `0` |
| `MonetizationEnabled` | `false` |
| `PurchaseQAApproved` | `false` |
| `PurchaseQAPlaceId` | `0` |
| `PurchaseSkus.*` | all `0` |
| `EnvironmentArtEnabled` | `false` |
| `UseMemoryInStudio` | `true` |
| `DataStoreName` | `PotionTycoon_M0_dev_v1` |
| `PlotCount` | `8` |

C00 does not flip any of these. Later tasks must not treat a document as permission to enable trading, purchases, or M7 rollout.

## 2. M0–M7 behaviour that V2 has to keep until replaced

### M0 — authority and saves

Gameplay changes only inside pure Factory/Progression/LongTerm/Collection/Trading/Monetization transitions. `Main.server.luau` checks the player session, then `ProfileStore:transact` / `save`. Clients send Protocol intents. `Access.target` maps each intent to a station id or to `warehouse`, `orders`, `altar`, `blueprint`, or `crystal`.

The DataStore envelope stays `{schemaVersion=1, profile, lease, revision, lastOperationId}`. Gameplay version lives on `profile.schemaVersion`. Invalid, future, and failed simulations are not overwritten with `newProfile`. A single-profile lease does not make a trade atomic.

Offline and online share `Factory.advance`. The cap is `maxOfflineSeconds = 7200`. Clicks are not simulated. `rngState` is the production PRNG (slime byproduct and double output). Gacha uses a separate server `Random`. Neither seed is sent to the client.

### M1 — supply, tutorial, forced export

Six original stations: `crystal`, `garden`, `mine`, `distillery`, `cauldron`, `logistics`. Each machine has a 24-unit Essence tank. `load` is free. Pipes cost 28 Gold. The crystal upgrade at 140 Gold is the passive Essence source. Tutorial facts are server-observed booleans, not UI acknowledgements.

`Factory.dispatch` is the export rule. Matching contract output, up to the remaining quota and the 6-crate queue, is copied into `station.questQueue`. Every other finished potion is sold in the same tick: `sell` adds Gold and increments the summary. Potion ids are rejected in `profile.inventory` (`kind ~= "potion"`). Ordinary bottles therefore never exist as items. The only persisted potion quantities are:

- `station.questQueue` on machine slots
- a logistics `job` with `destinationKind == "questStock"`
- `profile.questStock`

Expiry sells that reserved total once and clears those crates. Claim pays `rewardGold` once from delivered `questStock` only.

### M2 — three starters and provenance

`Factory.newProfile` always inserts three pets, once, with ids `{userId}:starter_farmer`, `{userId}:starter_slime`, `{userId}:starter_brewer` and source `starter`. Species are owl / slime / cat. Collection cap is `maxPets = 128`. Stats are `Farming`, `Hauling`, `Brewing`. There is no skill XP.

Provenance is per instance: `paidOrigin`, `provenance.source`, `paidDerived`, parent ids, `tradeKnown`. Legacy pets stay usable and untradeable. Fuse uses AND for known origin and OR for paid ancestry. Policy lookup failure does not open a restricted feature.

### M3 — thirteen fixed slots and four phases

Seven added ids, still keyed by name, not by a placed instance:

| Id | Archetype | Phase | Plot-local offset (x, y, z) |
| --- | --- | --- | --- |
| `crystal` | crystal | 1 | `0, 3, -2` |
| `garden` | garden | 1 | `-20, 1.5, 0` |
| `mine` | mine | 1 | `-20, 1.5, -20` |
| `distillery` | distillery | 1 | `15, 2, -18` |
| `cauldron` | cauldron | 1 | `20, 2, 0` |
| `logistics` | logistics | 1 | `0, 2, -27` |
| `garden2` | garden | 2 | `-32, 1.5, 14` |
| `cauldron2` | cauldron | 2 | `20, 2, 16` |
| `distillery2` | distillery | 2 | `32, 2, -18` |
| `mushrooms` | garden | 3 | `-32, 1.5, -10` |
| `berries` | garden | 3 | `-32, 1.5, -32` |
| `press` | press | 3 | `8, 2, 16` |
| `centrifuge` | centrifuge | 4 | `32, 2, 4` |

Waypoints are `offset ± 3` on X. They are presentation. Accounting uses the slot id. `Config.routes` is a fixed list of `{kind, slot}` and `stations.logistics.routeCursor` is an index into that list. Input fairness uses `inputCursors[itemId]`.

Unbuilt stations must have level 0, no worker, no recipe, no auto, no progress, empty buffers, and no job. Built stations may hold a job, cargo, Essence, and a quest queue. Rare cauldrons are separate instances (`cauldrons`, `nextCauldronSerial`) equipped by id on a built cauldron slot. Phase 3's resonant grant is one-time and is recorded on `longTerm.milestoneClaimed` when `phase >= 3` or the serial has already advanced. Migration must not grant another.

World anchors that are **not** `profile.stations` keys, from `World.luau`:

| Anchor | Plot-local offset | Intent target |
| --- | --- | --- |
| `warehouse` | `-8, 2, -30` | pipes, hire, discard, warehouse build |
| `orders` | `10, 2, -30` | accept/claim contract |
| `altar` | `27, 2, -32` | familiars, Fuse, locks, purchase UI |
| `blueprint` | `0, 2, 10` | phase advance, Rebirth, dailies |

### M4 — reservations

`profile.trade` is `{sequence, last?, pending?}`. `pending` freezes the whole profile. Ordinary saves may persist that frozen snapshot and renew the lease. They must not clear the reservation. Settlement is the trade journal plus `transactTrade`. Login recovery in `Main.server.luau` runs after a successful load and **before** offline `advance`. A V8 migration has to be a pure field addition on that frozen snapshot so recovery still sees the same items, hashes, and sequence.

### M5 — Rebirth

`LongTerm.apply` for `rebirth` copies a fresh `newProfile` and then replaces only:

`gold`, `essence`, `inventory`, `questStock`, `order`, `phase`, `stations`, `warehouseLevel`, `pipes`, `manualReadyAt`, `slimeWorkSeconds`, `pipeCursor`, `inputCursors`, `lastSimulatedAt`.

Pets, cauldrons, discoveries, entitlements, receipts, collection, trade, monetization, and the rest of `longTerm` stay. Assignments disappear because `stations` is replaced. The cycle increments by one and exactly one Time Shard is earned. Positive `currencyPaid` Gold or Essence blocks the reset. Epoch is `rebirths % 3` (Classic, Steampunk, Void) with bounded factors. No exponential growth.

This reset list is the implemented contract. C07 will have to extend it on purpose. C00 does not change it.

### M6 — receipts

V7 adds `monetization = {sequence=0, receipts={}, passes={}}` and nothing else. Profile proofs are not deleted when an item moves or is fused. Queued rights survive a full collection. SKUs in config are descriptive; `PurchaseSkus` are all zero, so no platform product is bound. Gold offers are the only path that can run without SKUs, and the master switch is still off.

### M7 — land, not economy

`Island.origin(i)` matches World: column `(i-1)%4`, spacing 95, row z `-65` or `85`. `Island.clearance` reserves a padded plot rectangle centred at `(ox, oz-8)` with half-extents **42.5 × 41.5**, the central bazaar, and connectors. Hills are outside those clearings. The visible floor is 77×75 at `origin+(0,0,-8)`. Eight owner plots and one communal bazaar are the ownership model. Art modules decorate the pilot plot only while the environment flag is on. V2 build expansion has to stay inside this already reserved envelope. It must not move a neighbour, the bazaar, a spawn, or a hill. Accepting that geometry is not 07D art approval.

## 3. Slot-id and auto-export dependencies

Anything that branches on a station **name** or assumes a potion becomes Gold in the same tick is a V2 coupling. The runtime still uses all of these:

**Identity and coordinates**

- `Config.stationOrder`, `machineOrder`, `sourceOrder`, `routes`, `stations[id].offset`, `waypoints`, `archetype`, `phase`
- `Factory` loops over those orders for pipes, crates, routing, recipe legality, and tutorial workers (`garden` + `logistics` + `cauldron` together)
- `Progression.buildState` / equip: cauldron slots only, by id
- `World` creates one anchored Part per station id plus the four service anchors, with `StationId` attribute and buy pads
- `PropArt` / `PropPlan` / `FarmGround` look up the same ids for the pilot plot
- `Access.target` and `Main.client.luau` selection, prompts, and recipe panels key off those ids
- Haul jobs store `sourceStationId` and `destinationStationId` as those names

**Forced auto-export**

- `dispatch` → `sell` for every potion unit that is not reserved for the active order
- `validate` forbids potion counts in `inventory`
- machine `output` buffers are not a player bottle cabinet; finished potions do not stay there
- no output-mode field exists; `setAuto` only toggles production, not sale versus keep
- client economy HUD reads Gold from sales, not a potion stack

C02 may replace coordinates. C03 may replace export. Until those PRs, simulation must keep reading `profile.stations[legacySlotId]` as the only cargo authority. A second copy of jobs would be a duplication bug.

## 4. Current V7 profile invariants

Envelope version is 1. Gameplay version is 7. Required gameplay fields, all JSON-safe:

| Group | Fields | Invariant |
| --- | --- | --- |
| Identity / time | `userId`, `lastSimulatedAt`, `rngState` | User id matches the key. Clock never moves backwards. RNG stays in `1 .. 2147483646` |
| Currency | `gold`, `essence`, `currencyPaid` | Non-negative, `<= maxBalance`. Paid flags are independent of pet `paidOrigin`. Positive paid balances block Rebirth |
| Factory | `stations` (exactly the 13 ids), `phase` 1–4, `warehouseLevel`, `pipes`, `pipeCursor`, `inputCursors`, `manualReadyAt`, `slimeWorkSeconds` | Unbuilt slots are empty. Jobs are prepaid. Cargo ids refer to built stations |
| Stock | `inventory` (raw/intermediate only), `questStock` (potions only while an order exists) | Capacity includes in-station buffers. Order reservation is queued + travelling + delivered and cannot exceed `order.count` |
| Contract | `order` or nil | Definition id, recipe, count, reward, and duration must match Config. No client-authored reward |
| People | `pets`, `nextPetSerial` | Count `<= 128`. One workplace per pet. Starter ids are stable. Locks and provenance survive |
| Equipment | `cauldrons`, `nextCauldronSerial` | Unique id, owner, type, bonus, lock, source. A slot stores only the equipped id |
| Knowledge | `discoveredRecipes`, `tutorial`, `tutorialGranted`, `telemetry` | Discoveries are real recipe ids. Tutorial booleans are from the fixed step list. No invented first-event timestamps |
| Commerce history | `receipts`, `entitlements`, `collection`, `progression`, `trade`, `longTerm`, `monetization` | Sequences and last receipts are the idempotency record. Pending trade matches its receipt. Shard ledger balances. Monetization proofs are append-only |
| Cycle | `rebirths` | Epoch is derived, not stored as a second counter |

`newProfile` additionally forces `gold = 0`, `essence = 0`, `phase = 1`, three starters, and level-0/1 stations from `initialLevel`. That function is the wrong tool for migration.

## 5. Current → target map

Target behaviour is the V2 spec. The right-hand column is the later task that may change runtime behaviour. C00 only names the mapping.

| Current fact | V8 meaning | Later task | Migration rule |
| --- | --- | --- | --- |
| 13 `stations[id]` with jobs and buffers | Legacy instances at the offsets above | C02 reads them; simulation keeps using them until then | Keep the table byte-for-byte. Add a placement record. Do not move cargo |
| `phase` 1–4 and phase Gold prices | Provisional temple level = phase. One track, not a second paywall | C02, after owner confirmation | Copy the number. Do not charge, refund, or skip a phase |
| Four service anchors | Temple/crystal stay fixed. Warehouse, orders, altar, blueprint stay landmarks until UI moves | C02 / C08 | Not profile stations. Do not delete the pads |
| `inventory` stacks | Warehouse bulk. Still not potions | C03 | Copy counts. Add empty potion containers |
| Immediate `sell` | Default output mode `auto-sell` for ordinary recipes | C03 | Record the mode. Do not resell, and do not mint bottles for past sales |
| `questQueue` / haul crate / `questStock` | Active-contract reservation, higher priority than keep/sell | C03 / C05 | Leave quantities and the order object unchanged |
| `discoveredRecipes` | Atlas seed | C03 | Alias the same recipe ids. Do not add discoveries |
| Three starter pets | Legacy grant, choice already consumed | C01 / C04 | Keep all three. Set a legacy marker. Do not insert a fourth |
| Assignments on any built slot | Grandfathered workforce. Proposed active cap is 3 | C04 | Do not unassign. Cap is not enforced by migration |
| Stat rolls | Base potential. Future XP is a new field | C04 | Do not write XP, and do not rescale stats |
| `maxPets = 128` | Owned cap stays 128 | C04 | Do not shrink the collection |
| `trade.pending` and journals | Same protocol, still disabled | unchanged | Field-add only. Recovery still runs before `advance` |
| `cauldrons`, locks, paid ancestry, M6 proofs | Same instances and receipts | unchanged | Deep-copy. No new serials |
| `longTerm` rebirth/dailies/calendar/shards | Same ledger | C07 | Do not grant a shard or reset a cycle |
| `rngState`, timers, `lastSimulatedAt` | Same clock and rolls | unchanged | Do not advance time inside migrate |
| Empty garden plots in the V2 sense | Not the current `garden` station | C01 | `seeds` and `plants` start empty. Garden growth stays on the station |
| No charms | Empty registry | C07 | `active` empty. Do not invent effects |
| M7 terrain envelope | Preallocated build polygon per plot | C02 | Record the existing clearance. Do not expand land |

## 6. Additive V8 shape (designed, not coded)

When a future PR bumps `Config.schemaVersion` to 8, `validate` for version 8 should require the fields below and `migrate` should refuse a historical profile that already contains them. Extra unknown keys remain illegal on the new objects. Existing V7 objects stay closed as they are today.

`stations` remains the cargo authority. `layout` is a projection.

```luau
-- Proposed. Not present in Config or Factory in this change.
layout = {
  legacy = true, -- true when every placement was synthesized from the 13 ids
  placements = {
    -- key = legacy slot id, also the first instance id
    crystal = {
      instanceId = "legacy:crystal",
      slotId = "crystal",
      archetype = "crystal",
      x = 0, y = 3, z = -2, rotation = 0, -- quarter-turns, 0..3
      legacy = true,
    },
    -- one entry per Config.stationOrder id, including level 0
  },
}
temple = {
  level = 1, -- copy of phase; TBD whether this replaces phase prices
  tracksPhase = true,
  -- Preallocated envelope in plot-local studs. Matches Island.clearance,
  -- not a new parcel. min/max are relative to the plot origin.
  envelope = { minX = -42.5, maxX = 42.5, minZ = -49.5, maxZ = 33.5 },
  buildable = { minX = -38.5, maxX = 38.5, minZ = -45.5, maxZ = 29.5 }, -- visible floor, TBD
}
seeds = {} -- itemId -> count, empty. No starter seed grant
plants = {} -- bedInstanceId -> { seedId, plantedAt, duration, progress } empty
outputMode = {} -- slotId -> "auto-sell". Machines only. Absent means auto-sell
potionStacks = {} -- ordinary recipeId -> count. Empty. Not a replay of old sales
uniquePotions = {} -- serial -> instance. Empty. nextPotionSerial is omitted until C03 mints one
atlas = { discovered = {} } -- copy of discoveredRecipes keys; same booleans, no new ids
starter = {
  claimed = true, -- existing profiles only
  legacyGrant = true, -- the historical three-pet grant
  choice = nil, -- owl/slime/cat is TBD for new profiles; never backfilled
}
workforce = {
  activeCap = nil, -- TBD. Proposal is 3. nil means "do not enforce"
  ownedCap = 128,
}
charms = { active = {} } -- no effects, no shard spend
```

Pet records do **not** gain `xp` until C04. Absence means "not trained", which is the truth for every current pet. Writing zeroes would look like a balance change and would complicate the historical validator.

`starter.choice` for a new profile is one of `farmer`, `slime`, `brewer` and is written only by the C01 choice command. Migration of an existing profile must leave it nil.

Temple envelope numbers come from the clearance rectangle centred on the floor (`oz-8` in world space is plot-local z `-8`): half-extents 42.5 and 41.5. `buildable` is the current 77×75 floor. Both are recorded so C02 can reject placements outside them. They are not a Gold purchase and not an expansion.

Service anchors (`warehouse`, `orders`, `altar`, `blueprint`) stay out of `placements`. They are not owned stations.

## 7. Migration scheme

### 7.1 When it runs

Same hook as today: `ProfileStore` calls `Factory.migrate` on a cloned profile inside the load `UpdateAsync`, after the envelope and lease checks, before the write. Save and release never migrate. Offline `advance` stays after trade recovery and must see the already migrated snapshot.

V8 is not writable by a V7 server. `Factory.migrate` on this commit rejects schema 8 and above (`integer(schemaVersion, 1, 6)` fails, and only exact 7 is returned as current). Shipping V8 requires one coherent QA build, backups, and no downgrade. That rollout is not this PR.

### 7.2 Algorithm

1. If `schemaVersion == 8`, validate as V8 and return the same table. Do not rebuild it.
2. If the version is not an integer 1–7, return nil. Do not call `newProfile`.
3. If a pre-V8 profile already has `layout`, `temple`, `seeds`, `plants`, `outputMode`, `potionStacks`, `uniquePotions`, `atlas`, `starter`, `workforce`, or `charms`, return nil (`Unexpected future layout state`).
4. Run the existing V1→V7 conversion unchanged, including LegacyConfig checks, empty-slot fill, legacy pet upgrade, `trade = {sequence=0}` only when missing, `longTerm.initial` only when missing, and empty monetization only when missing. A profile that fails that conversion is still not defaulted.
5. On the V7 result only, deep-copy and add the section 6 objects.
6. Placements: for each id in `stationOrder`, copy `Config.stations[id].offset` and archetype. `instanceId = "legacy:" .. id`. `rotation = 0`. Include level-0 stations so a purchased-but-empty slot cannot vanish. Do not read or write `station.job`, buffers, workers, or equipped cauldron ids in this step.
7. `temple.level = phase`. `tracksPhase = true`. Envelope constants as above.
8. `outputMode[id] = "auto-sell"` for stations whose archetype has `defaultRecipe`. Do not set it on gardens, the mine, the crystal, or logistics.
9. `atlas.discovered` is a shallow copy of `discoveredRecipes`.
10. `starter.claimed = true` and `legacyGrant = true` whenever the profile was migrated, including a V7 profile that somehow has zero pets. Lack of pets is not a reason to grant one. Do not scan species and do not insert ids.
11. Leave `workforce.activeCap` nil. Set `ownedCap` from `maxPets` (128).
12. Leave `seeds`, `plants`, `potionStacks`, `uniquePotions`, and `charms.active` empty.
13. Validate as V8. On failure, return nil. The stored key stays as it was.

Forbidden inside migrate: `newProfile`, Gold/Essence writes, pet or cauldron inserts, serial increments, recipe inserts, order edits, job edits, `advance`, RNG steps, receipt inserts, trade/journal writes, lock changes, and Rebirth.

### 7.3 What stays identical

For every successful V1–V7 fixture, the post-migration profile must equal the current V7 migration plus the new objects. In particular these are deep-equal to today's V7 output:

`userId`, `gold`, `essence`, `rngState`, `lastSimulatedAt`, `rebirths`, `pets`, `nextPetSerial`, `stations`, `inventory`, `questStock`, `order`, `discoveredRecipes`, `receipts`, `entitlements`, `collection`, `currencyPaid`, `trade`, `phase`, `progression`, `cauldrons`, `nextCauldronSerial`, `inputCursors`, `pipeCursor`, `tutorial`, `telemetry`, `warehouseLevel`, `pipes`, `manualReadyAt`, `slimeWorkSeconds`, `longTerm`, `monetization`, `tutorialGranted`.

`stations` equality is the in-flight guarantee: brew jobs, haul cargo, Essence tanks, quest queues, workers, recipes, progress, and equipped cauldron ids survive. Locked pets and locked cauldrons survive because those tables are not rebuilt. A pending trade survives because `trade` is not rebuilt. M6 queued proofs survive because `monetization` is not rebuilt.

### 7.4 New profiles versus old profiles

| Case | Starters | Gold | Stations |
| --- | --- | --- | --- |
| Missing key, C01 and later | One chosen familiar, idempotent. Not this PR | `TBD` starter budget. Not this PR | Fixed temple + crystal only, when C01 exists |
| Any stored V1–V7 profile | Whatever pets are already there, including the original three | Unchanged, including 0 | All 13 records kept, placed on the historical offsets |
| V7 profile with a pending trade | Unchanged | Unchanged | Unchanged, including reserved ids inside the trade snapshot |
| Schema 0, schema ≥ 9, or V8-shaped fields on an older version | No write | No write | No write |

C01 must branch on `starter.legacyGrant` / `starter.claimed` and must not call the current three-pet `newProfile` for a key that already exists. Changing `newProfile` is a C01 runtime change. It is out of scope here.

### 7.5 Rebirth, stated so C07 does not improvise

Not implemented now. The intended classification, once C07 is allowed to edit `LongTerm.apply`, is:

- **Reset with the factory:** Gold, Essence, ordinary `inventory`, `questStock`, `order`, phase/temple level back to the cycle start, `stations` and their placements, `outputMode`, `seeds`, `plants`, `potionStacks`, pipes, warehouse level, cursors, assignments, `lastSimulatedAt`.
- **Keep:** pets and any future XP, `uniquePotions`, cauldrons, `atlas` / `discoveredRecipes`, entitlements, collection and progression receipts, `trade`, `monetization`, shard ledger, perks, dailies, calendar rights, titles, `charms`.
- **Still blocked by:** `trade.pending`, an active negotiation, and positive paid Gold/Essence.

Unique items must not satisfy a new cycle's recipe or phase gate. Ordinary stacks reset. That last sentence is the spec's recommendation, not a code change.

### 7.6 Journals

Trade journals and receipt journals are separate DataStores. V8 does not rewrite them. Profile item ids inside an in-flight trade must remain the ids the journal hashed. Legacy station ids and pet ids therefore stay valid forever as aliases, even after C02 adds movable copies. A moved station keeps `instanceId` and may change `x/z/rotation` only through a later, idle, server-checked command. Cargo does not teleport with a preview.

## 8. Owner gates (do not invent)

These stay open. Code that needs a number waits.

| Gate | Safe assumption until the owner answers | Must not do |
| --- | --- | --- |
| Three familiars | Active cap proposal = 3. Owned cap = 128. `workforce.activeCap = nil` on migrated profiles | Unassign a fourth worker. Shrink `maxPets`. Delete starters |
| Starter Gold and seed/bed/cauldron prices | No number | Put a price in Config in this PR |
| Temple versus the four phase gates | Recommended: temple level displays phase. `tracksPhase = true` | Add a second paywall, or refund phase Gold |
| Build limits, grid, presets | Envelope recorded from current land. Grid `TBD` | Allow placement on hills, spawns, bazaar, or a neighbour |
| Potion rarity, Mythic versus Legendary, unique serialisation, synthesis odds | Unresolved. C06 stays blocked | Add a potion rarity enum or drop table |
| Charm slots and effects | Empty registry | Spend shards or add a currency |
| Whether rare potions are tradable | Not in V2 scope | Open `TradingEnabled` |

## 9. Transition plan

Work stays on new branches off the accepted V2 base. Nothing here merges to `main`, pushes to `design/core-loop-v2-cursor`, retargets PR #17, or publishes.

| Step | PR contents | Runtime |
| --- | --- | --- |
| **C00 (this change)** | This contract. Backlog/roadmap pointers. | None. Schema 7. Flags off. Existing tests unchanged |
| **C00b schema PR** | Sections 6–7 in `Factory.migrate` / `validate`, plus `tests/v8_migration.spec.luau`. No new intents and no World move. `newProfile` still grants the historical three familiars and only stamps the V8 projection so a current save validates | Migrated profiles gain empty projections. Simulation results for one tick match pre-V8 given the same inputs, because `dispatch` is untouched and new fields are unread |
| **C01** | New-profile choice, starter Gold `TBD` once set, first bed/seed/cauldron, auto-sell still the default | Must not run the three-starter grant on a `legacyGrant` profile |
| **C02** | Server placement commands. Client preview cannot spend | Legacy placements load at the offsets in section 2. Cargo stays on `stations` until a dedicated idle move |
| **C03–C08** | As the backlog states | Each one keeps the conservation rows in section 5 |

C02 must not start until the C00b schema PR has frozen `instanceId` and the envelope. Parallel free-build on schema 7 would fork the save.

Presentation can keep greybox anchors for legacy ids until C02. Deleting those parts in an earlier PR would remove click, build, and contract prompts (`Access` still targets them).

M7 07D, UX #18, and phase 08 stay a separate art track. Free placement has to respect `Island.clearance` and the hill list, and it does not mark 07D accepted.

### Playable baseline during C00

The playable game is still the fixed-slot M0–M6 loop: click crystal, garden/mine, cauldron, Gold, 13 pads, three starters, contracts, disabled trade, disabled purchases. No Studio session was run for this document. Live DataStore, phone, 2–8 client, PolicyService, and receipt acceptance stay **BLOCKED**, exactly as [ACCEPTANCE.md](ACCEPTANCE.md) and [PERSISTENCE.md](PERSISTENCE.md) already say.

## 10. Fixtures the schema PR must add

Not added in this change, because a fixture that calls `migrate` would require the runtime edit C00 is not allowed to ship. The baseline suite stays the current files:

- `tests/fixtures/m0-profile.luau` (gameplay 1)
- `tests/fixtures/m1-profile.luau` (gameplay 2)
- `tests/fixtures/m2-profile.luau` (gameplay 3)
- `tests/fixtures/m3-profile.luau` (gameplay 4)
- `tests/fixtures/m4-pending.luau` (envelope 1, gameplay 5, pending trade)
- `tests/fixtures/m5-progression-pending.luau` (gameplay 6)
- current `newProfile` / V7 cases already covered by `tests/migration.spec.luau`, `tests/trade_migration.spec.luau`, and the M5/M6 store specs

The schema PR adds comparisons, it does not replace those fixtures:

| Case | Required result |
| --- | --- |
| Each fixture above | Today's V7 object deep-equals the migrated profile with the section 6 keys removed. New keys match section 7. Pet count unchanged. No Gold delta |
| V7 profile with `trade.pending` | `pending` and `sequence` unchanged. Stations and pet ids unchanged |
| V7 profile with a logistics haul and a non-empty `questQueue` | Job and queue deep-equal |
| V7 profile with a locked pet, a locked resonant cauldron, and a monetization proof | Those records deep-equal. Serials unchanged |
| `schemaVersion` 0, 8-with-garbage, 9, 99 | `migrate` returns nil. A fake DataStore key is not replaced |
| V4 (or earlier) that already contains `layout` or `trade` | nil, same as today's "unexpected historical" rule |
| V7 that already contains `layout` | nil |
| Second `migrate` on a V8 result | Same table, no second starter, no serial bump |
| `userId` inside the profile changed by a bad transform | Rejected by the existing store identity check |

Release flags in `ServerSettings.luau` are asserted unchanged by reading the source constants in that PR, not by turning them on.

## 11. Out of scope

- Gameplay, UI, terrain, and asset edits
- `Factory.newProfile`, prices, recipes, odds, and the Rebirth reset list
- Enabling trade, purchases, or environment art
- Comments, pushes, or retargets of Draft PR #17
- Merge to `main` or publication
- Executable migration tests were out of scope for the C00 document commit. C00b adds them in `tests/v8_migration.spec.luau`
