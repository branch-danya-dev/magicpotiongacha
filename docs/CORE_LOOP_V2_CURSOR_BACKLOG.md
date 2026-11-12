# Cursor delivery backlog — Core Loop V2

> **Historical task contract (2026-11-06):** The unchecked C00/C01 boxes below are
> no longer a live progress tracker. C00/C00b V8 and C01 now exist as code
> candidates on the Spellbook HEAD. See the [2026-11-12 audit](PROJECT_AUDIT_2026-11-12.md),
> [release roadmap](RELEASE_ROADMAP_V2.md) and [current agent queue](AGENT_WORK_QUEUE.md).
> Do not redo the implemented steps merely because an old checkbox is open.

**Purpose:** implement the owner-directed gameplay redesign without silently replacing the working M0–M6 engine or unfinished M7 environment work.
**Design contract:** [CORE_LOOP_V2_SPEC.md](CORE_LOOP_V2_SPEC.md). **Status:** tasks only; no V2 gameplay code implemented by this document.
**Review base:** new design branch from M7 #17 head at 34f617b5f36975d5f71638746494c0341e88bf45. Do not amend/merge Draft PR #17. Later Cursor work may stack new Draft PRs from the accepted code base; verify branch HEAD, docs and active art gates first.

## Golden rules for Cursor

1. **Keep clicker + tycoon + idle as the mandatory loop:** clicks -> Essence -> supply/brew -> Gold -> upgrades -> higher idle output. New complexity must be optional or progressively automated.
2. Implement **thin vertical slices**, with a playable recovery path after every slice. Do not attempt one huge rewrite of World/Factory/Protocol/ProfileStore.
3. Keep simulation pure/portable. Server authenticates ownership, prices, layout, timers, inventories, XP, item serials, odds and transactions; client sends validated intents.
4. Treat all existing profiles and V1–V7 receipts as real user data. No destructive reset, duplication, new free grants or unvalidated migration. No silently changed paid ancestry, unknown outcomes or open trading/monetization flags.
5. Keep versioned documented owner choices separate from provisional economy numbers. No paid randomness, new currency or commission/purchase of 3D assets without further approval.
6. Work from **one task at a time** with tests and exact-head CI, ordinary Roblox Studio build, acceptance/blocked matrix. No merge/publish unless separately authorized.
7. M7 07D owner review -> UX #18 -> 08 eight-plot art rollout remains **independent and open**. Do not mark it complete as a side effect of V2.

## C00 — Architecture inventory, save migration plan, playable baseline (P0)

Written inventory and the V8 migration contract: [CORE_LOOP_V2_C00.md](CORE_LOOP_V2_C00.md). C00b implements sections 6–7 and adds `tests/v8_migration.spec.luau`. `Config.schemaVersion` is 8. Owner numbers in that contract stay `TBD`; the sign-off checkbox stays open.

- [ ] Trace actual Factories, Protocol, Config, ProfileStore, World, UI, M1–M6 progression and 13 fixed slots; identify every direct slot-ID coordinate or forced auto-export dependency.
- [ ] Publish current→target invariant map for profile fields, items, active contracts, stored/timed work, RNG, receipts, locked/traded/reserved items, paid provenance and Rebirth.
- [ ] Design additive V8+ schema: owned instance placements, temple level and build polygon, seed stock/plants, output routing, potion inventory, starter choice, active pet slots, trained skill XP, charm registry.
- [ ] Identify migration path for existing owners: original fixed stations get deterministic safe placements and durable IDs; old 3 starters stay intact without claiming a new starter. No occupied/locked/in-flight object is lost.
- [ ] Owner sign-off gates: active cap vs owned cap, temple vs phases, seed starter budget, potion rarity order. Use explicit TODOs/config for unresolved values, not invention.
- [x] Baseline tests/CI unchanged prior to runtime edits; add schema migration fixtures for all versions and malformed/future/ambiguous DataStore states.

**Done when:** written interfaces and migration tests show no old-data loss; all release flags still disabled. This task may produce design-code scaffolding but no gameplay behaviour change.

## C01 — First-session clicker/tycoon vertical slice (P0)

- [ ] New player gets one-time affordable Gold seed budget, fixed temple/crystal and **one selected owl/slime/cat familiar**; idempotent choice, disallow second claimed starter; preserve all existing profiles.
- [ ] Click crystal produces Essence; earned passive crystal tier remains available. All actions server-rate-limited; cap/disable any optional click-overcharge pending balance approval.
- [ ] Bazaar sells earned-Gold seed stock. One bed accepts planted seed; timer-based growth and real collection use shared online/offline state.
- [ ] One cauldron consumes ingredients+Essence, manually discovers Healing, then can be configured for automatic batches. Preserve a free low-tech supply path before pipes and without requiring all three familiar specialists.
- [ ] Ordinary output defaults to reliable automatic Gold sale; Gold buys a tangible next upgrade. Automatic seed replenishment/harvesting become earned options so routine actions stop being required.
- [ ] Tutorial saves real server milestones; recovery from spent Gold, no seed, unstaffed machine, full inventory or lost connection remains possible without paid items, gacha or admin grants.

**Done when:** fresh profile can reach first sell and set up self-sustaining auto-production in a realistic Studio session; zero-Gold/detour and 7200-s online/offline scenarios are reproducible; no auto-sale duplication.

## C02 — Free building with temple expansion (P0)

- [ ] Convert fixed slot coordinates into server-owned station instances with immutable IDs, type/tier/phase, local snapped X/Z/rotation, and persistable occupied bounds.
- [ ] Client placement preview + rotate/move + quick-build/preset option on PC and touch; reject placement at server for invalid funds/phase, overlap, protected hill, neighbour, restricted zone, spawn/path and maximum instance limit.
- [ ] Make temple central and non-movable; upgrades unlock plot-local build area within fixed 8-plot protected envelopes. Connect existing four technology gates provisionally to temple progression, pending approved mapping.
- [ ] Moving a bought building is recoverable and cannot duplicate refunds/resources, teleport in-flight loads, bypass idle/busy equipment restrictions or alter another owner. Construction must not softlock access.
- [ ] Keep optional pipes/haulers as meaningful throughput improvements; no quadratic routing scans across arbitrary station positions. Provide determinism/owner isolation under 8 simultaneous plots.
- [ ] Existing saves with 13 legacy stations load as a usable layout, never zero/missing stations; preserve cargo, jobs and original tier/phase prices until explicitly rebalanced.

**Done when:** free placement persists through rejoin, relocation and safe expansion; deterministic arbitrary overlap/property tests and ordinary Studio movement succeed.

## C03 — Potion Atlas, storage, laboratory and output policy (P1)

- [ ] Define recipe archive and server-verified first manual discovery; old discovered recipes migrate intact, without granting unknown discoveries.
- [ ] Add output modes (auto-sell / keep / fulfill active contract), with ordinary auto-sell default and rare protected keep default; explicit routing priority for already-reserved order quotas.
- [ ] Distinguish stackable ordinary potion quantities from serialised rare/unique item instances; retain item provenance, lock, owner, recipe/effects/material and no silent capacity overflow.
- [ ] Warehouse manages bulk inputs and ordinary stacks; laboratory panel opened from inventory displays stored potions, lets player inspect/hold a bottle visually (client-side preview only).
- [ ] Atomic once-only sell, explicit hold/consume, contract reserve/claim/expiry and output-mode switches; repeated requests/rejoins never duplicate Gold or items.
- [ ] Start with a few reusable meshes/variants and icons; no bespoke 3D per recipe as a dependency.

**Done when:** one player can automatically sell ordinary Healing while keeping a rare collectible and reliably inspecting it; conservation, overflow, contract and Rebirth boundaries pass portable tests.

## C04 — Familiar training and workforce, active slots (P1)

- [ ] Replace new-account three-starter grant with exactly one chosen beginner; preserve legacy starter and gifted/purchased pet serials. Do not silently reduce the 128 collection capacity.
- [ ] Initially cap **concurrently deployed** familiars at three (proposed, owner confirmation required); extra active slots earnable by temple/Gold. No required Robux.
- [ ] Add Farming/Alchemy/Logistics mastery progression tied to legitimate work; reserve Defense for future Siege (no combat code now). Existing Farming/Hauling/Brewing stat rolls and Fuse remain meaningful.
- [ ] Pet rarity/potential, training XP, potion enhancements and cosmetics are distinct persisted fields. Skill gains bounded/idempotent across online/offline without AFK exploit or reroll.
- [ ] Baseline auto-production must not require three simultaneously equipped workers; familiar assignments accelerate and specialise, and cosmetic following cannot double-count production.
- [ ] Verify pet custody, gifts/locks, Fuse ancestry/paid provenance, market fixed purchases and existing M4 trading-disabled protocol unchanged.

**Done when:** one starter choice is sufficient for first income, trained pets persist through rejoin/Rebirth, pet-swap replays cannot farm XP or duplicate production.

## C05 — Three contract types / Bazaar economy (P1)

- [ ] Preserve three visible eligible offers, one active, explicit server acceptance/claim and already-implemented safe expiration semantics.
- [ ] Support potion delivery, actual harvested plant delivery, and measurable familiar training/improvement orders, with reachability checks for phase/seed/recipe/familiar.
- [ ] Ensure quest completion cannot be fabricated through client reports, repeated assignment, no-op XP attempts or stale timestamps; reserve only the required resources, never protected locked items silently.
- [ ] Maintain Gold sources/sinks and safe early recoverability; monitor expected player session pace, production stalls and contract failure states. Keep automatic sale of excess output.
- [ ] Existing M1/M3 contract and M5 daily receipts remain idempotent after introduction of new offer types.

**Done when:** three contract categories can be reached from earned resources, claimed exactly once, and interrupted/expired without inventory or currency loss.

## C06 — Rare synthesizer and controlled reward engine (P2; after rarity decision)

- [ ] Owner decides potion rarity ordering (Mythic / Legendary / Unique), which items are serialised, exact result table, eligibility, compensation after losses, and UI disclosures.
- [ ] First legitimately brewed legendary potion unlocks an optional **Gold purchase** of the Enchanted Synthesizer; no early-game dependency.
- [ ] Validate two owned eligible Mythic+ inputs, preview explicit consumed IDs/quantities, provide confirm/decline, store sampled RNG result/receipt atomically; rare double-effect outcomes must have a defined item schema.
- [ ] Never mint a second outcome after timeout/retry, accept used/stale input, consume a locked/reserved item or roll client-side. Define recoverable failure on uncertain database commit.
- [ ] Keep any chance-based synthesis independent of Robux purchases/paid currency sources until formal Roblox paid-random-item review; do not enable real-money luck rerolls/paid attempts or item trading.
- [ ] Exact probabilities and potential deterministic compensation require owner approval before coding.

**Done when:** one legitimate fusion and all refund/rollback/rejoin/duplicate-intent/adversarial cases pass; no silent purchases or RNG divergence.

## C07 — Rebirth, epochs and academic-cycle charms (P2)

- [ ] Preserve existing three repeating themes and four technology phases in each, as well as one separate actual final-batch requirement, explicit confirmation and exactly-once Time Shard.
- [ ] Reset temporary Gold/Essence, production station instances/placements, raw stock, seeds, ordinary potions, assignments and temporary timers as approved; do not wipe titles, offers/rights or historical receipts incorrectly.
- [ ] Retain familiars with mastery/customisation, unique and collection potions, resonant/spectral cauldrons, discovered Atlas, permanent perks and new capped academic-cycle charms.
- [ ] Define bounded charm loadout (slots/effects), acquired through gameplay/earned shards rather than a new unapproved currency; no exponential stacking across repeated epochs.
- [ ] Keep protected rare items viewable but not usable to bypass fresh phase/recipe/machine gating.
- [ ] Test Rebirth vs trade reservation, unfinished brews, contracts, storage, offline catch-up, duplicate confirmations, legacy profiles and failure boundary.

**Done when:** full earned 3-epoch zero-admin routes, idempotent Rebirth and deterministic 7200-s online/offline equality pass without invented grants.

## C08 — UX, asset readiness, monetization boundaries and final QA (P2/P3)

- [ ] Preserve the ordinary clicker HUD and short goals despite richer systems; menus for growing/Atlas/Lab/Build must be contextual, not persistent world-space clutter.
- [ ] Player can operate starter loop, build mode, held potion, pets and production upgrades with mobile touch and low graphics. Test normal Play, not only beauty harness.
- [ ] Create a game-ready asset checklist for temple/crystal, 3 starter familiar rigs, cauldron, starter crops, base bottles, synthesizer; free licensed Quaternius scenery remains reusable. No paid asset commissioning without separate user approval.
- [ ] Keep native prompt/receipt, PolicyService, paid-derived provenance, M4 trade policy and all M6 flags disabled until distinct live gates; paid terrain speed-ups/deploy slots are design proposals, not purchases enabled here.
- [ ] Test 2–8 owner isolation with free build, worst-case station/pet/seed count, storage and local/remote exploit attempts; measure mobile FPS/memory rather than inventing performance claims.
- [ ] Full migration/normal-Play checklist, exact SHA tests/CI on Win+Ubuntu, open blockers and owner-visible acceptance matrix.

**Done when:** owner approves the actual V2 build independently of the M7 07D/08 art work. No implicit merge/public release.

## Suggested bounded pull request sequence

1. C00 schema/invariants/tests.
2. C01 basic clicker + seed + cauldron + auto-sell vertical slice.
3. C02 construction/temple (can branch in parallel only after shared schema contract fixed).
4. C03 collection/Atlas/lab.
5. C04 skills/starter/active slots.
6. C05 orders.
7. C06 synthesizer (blocked by rarity/odds decision).
8. C07 Rebirth and charms.
9. C08 acceptance and optional art assets.

Each PR reports: code diff, migration/receipt implications, what changed/what was untouched, deterministic tests and exact CI link, owner-normal-Play build route, **KNOWN BLOCKED** device/backend/compliance checks, and next gate. Never conflate implementation with art approval or release.

## Existing references

- [CORE_LOOP_V2_C00.md](CORE_LOOP_V2_C00.md) — M0–M7 inventory and additive V8 migration contract (plan only).
- [DESIGN.md](DESIGN.md) — historical implemented baseline (fixed-slot).
- [ROADMAP.md](ROADMAP.md) — M0–M7 accepted scheduling and separate V2 target.
- [M7_REWORK_PLAN.md](M7_REWORK_PLAN.md) — 07D and 08 visual gates.
- [M1_BALANCE.md](M1_BALANCE.md) — zero-resource recovery/early economy facts to rebaseline, not carry as new V2 test expectations.
- [M2_RULES.md](M2_RULES.md) / [M4_TRADING.md](M4_TRADING.md) — familiar provenance and transactional policy.
- [M3_RULES.md](M3_RULES.md) — fixed production graph to preserve semantically during free-build conversion.
- [M5_REBIRTH.md](M5_REBIRTH.md) — durable Rebirth/epoch reset boundaries.
- [M6_MONETIZATION.md](M6_MONETIZATION.md) — purchases disabled and receipt protections.
- [Roblox paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items), [PolicyService](https://create.roblox.com/docs/reference/engine/classes/PolicyService).
