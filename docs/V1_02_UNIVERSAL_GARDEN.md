# V1-02 — Universal garden (Studio-memory QA only)

**Base:** `feat/v1-01-extractor-cosmetic-familiars` @ `777db93c73a395fb5450b4c4c15aa9d50cc744a2` (Draft PR #67).

**Goal:** playable, extendable crop system for the V1 alchemy loop, not a single hardcoded mandrake timer. All changes are in `qa/garden` and generated-build adapters; original release `src/`, existing asset pipeline, M0–M6 and all V8 save migrations remain unchanged. Do NOT merge/publish this QA branch as a production save schema change.

## Gameplay contract

- Every named bed has independent saved progression. **One bed** is available after buying the original Garden station; **two more** unlock sequentially for earned Gold at **400** and **950** (provisional).
- The crop catalog `qa/garden/Catalog.luau` is the single source of growth, watering and harvest timing. **Mandrake:** 90 seconds of actual wet growth, initial watering, 2 seconds harvest, 2 raw ingredients, seed 20 Gold. **Antarctic Biter:** 250 seconds of wet growth, watering at planting and after 125 growth seconds, 5 seconds harvest, 3 raw ingredients, seed 45 Gold.
- Each planting consumes one owned seed. The first watering is manual; missed watering **pauses** progress without destroying plants. Growth and harvest share the existing deterministic server `Factory.advance` tick (online and capped 7,200-second offline simulation).
- **Sprinkler** for 300 Gold waters every owned bed automatically when its crop reaches a watering checkpoint. It NEVER plants or harvests. Harvest is one button which starts the crop-specific harvest duration; upon completion the server credits raw inventory once if there is capacity. A full warehouse does not delete the crop or award free duplicates.
- Other existing V1 automation only controls brewing and supply. The historical automatic seed replant/harvest/restock flags remain in previous profiles but are ignored in this QA garden mode.
- No need for familiars to water/grow/deliver. Starters/collection/stats remain intact. Farm crop is independent from worker skills.
- The second crop is a **mechanical/configuration example**; its future potion recipes and economy role will be designed in V1-03. Do not treat provisional timing and prices as accepted commercial balance.

## Persistence and safety

- Retains `profile.schemaVersion=8` and existing `crystal`/`garden` logical station IDs only in this QA build.
- New **`profile.gardenV1`** is a QA-only isolated state: owned bed count, optional sprinkler, and a map of crop progress by stable bed ID. Crops are strictly validated and protected by server-side ownership/distance check and protocol field allowlists. The release schema does **not** accept these extra fields yet; a future versioned migration and release owner approval are mandatory before live play.
- A previously planted `profile.plants["legacy:garden"]` V8 crop is converted once, retaining its maturity ratio, into `profile.gardenV1.plots["legacy:garden"]`, removing the old instance without duplicating ingredients or seeds. No data reset. Profiles with `starter.legacyGrant` retain untouched historical crop behavior.
- Additional raw seed `antarctic_biter` is accepted only in modern QA mode. No new paid products, trading, DataStore namespace, remotes or client-authoritative resource calculations.

## Build and acceptance

```sh
npm run tools
npm test
node scripts/build-alchemy-first.mjs --owner-user-id=YOUR_ROBLOX_USER_ID
```

Main candidate: `build/PotionTycoon-Alchemy-First-QA.rbxlx`, receipt `build/alchemy/build.json`.
All new domain tests: `qa/garden/run.luau` — watering checkpoints, harvest delay and exact rewards, independent purchased beds, duplicate prevention, auto sprinkler, interrupted growth, legacy conversion and online/offline parity. CI compiles and builds the same candidate on Windows and Ubuntu.

**Studio F5 acceptance OPEN:** buy first Garden, buy/plant/water Mandrake, verify 90-second growth and 2-second harvest, craft Healing; plant Biter in second bed and verify watering at 0 and 125 sec, harvest at 250 sec; purchase sprinkler; test occupied/empty bed, insufficient Gold, full inventory, reconnect, offline catchup, companion-only familiars, paths/mobile UI/no new FPS regression.

**Known boundaries:** real GLB garden/plant/watering models not imported; UI uses ordinary text/buttons on the existing station panel. No actual Studio F5 or live persistence acceptance evidenced. **Rollback:** reopen `feat/v1-01-extractor-cosmetic-familiars` at its original SHA. The default production place and profile schema have not been updated.
