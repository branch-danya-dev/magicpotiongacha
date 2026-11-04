# M3 implementation contract

Recorded before implementation. Greybox only; all prices are provisional. M2
baseline: PR #7 `f9c34c8383bee2a0fdd1ef08167103725a924672`, 316 tests.

## Progression graph

Phase is independent of equipment tier and future Rebirth epoch. Epoch remains 0.
All original station IDs, upgrades, Healing/Fire Extract/Rage and basic altar stay
available as before. Pipes remain 28 Gold, passive crystal 140 Gold. No gacha,
rare item or paid purchase is required for a phase.

| Phase | Name | Entry purchase and prerequisites | Additional capabilities |
| --- | --- | --- | --- |
| 1 | Forest clearing | New profile, free | Original six stations, M1 tutorial and M2 collection |
| 2 | Witch hut | 400 Gold; manual Healing discovered, pipes, crystal tier 2 | Second Mandrake garden, second cauldron and distillery; wood platform/canopy greybox |
| 3 | Stone laboratory | 1400 Gold; phase 2, second cauldron built, distillery built, Rage discovered | Mushrooms, Fire Berries, press, new intermediates/Focus/Flare; stone hall/store greybox; one guaranteed resonant cauldron |
| 4 | Cyber alchemy complex | 4500 Gold; phase 3, Focus and Flare discovered, press and second distillery built, warehouse level 1 | Centrifuge and Ascension chain; cyber frame/capsule greybox |

`phase 1 → Healing/pipes/crystal → phase 2 → Rage/second cauldron → phase 3 →
Focus/Flare/press/second distillery/warehouse → phase 4 → serum → Ascension`.
M3 completion requires phase 4 and manual discovery of Ascension; UI then says
"M3 complete; Rebirth comes later". No reset, shard, token or completion payout.

## Fixed slots and economy

Initial slot IDs retain all saved state. Each Config slot has archetype, local
coordinates and fixed input/output waypoints. Nothing is freely placed or moved.
New slots start unbuilt; phase purchase does not buy equipment automatically.

| New slot | Archetype / phase | Tier costs Gold | Stat caps | Output rate at zero skill |
| --- | --- | --- | --- | --- |
| garden2 | garden / 2 | 160, 240, 600 | 10,25,60 | Mandrake / 8 s |
| cauldron2 | cauldron / 2 | 220, 350, 1000 | 15,35,75 | Per recipe |
| distillery2 | distillery / 2 | 200, 350, 1000 | 10,25,60 | Per recipe |
| mushrooms | garden / 3 | 300, 450, 1000 | 10,25,60 | Mushroom / 10 s |
| berries | garden / 3 | 350, 500, 1100 | 10,25,60 | Fire berry / 12 s |
| press | press / 3 | 450, 650, 1400 | 10,25,60 | Per recipe |
| centrifuge | centrifuge / 4 | 1200, 1800, 3000 | 15,35,75 | Per recipe |

New slot tiers 2/3 require at least phases 3/4 (centrifuge remains phase 4).
Old tier rules remain unchanged to preserve M0–M2 saves and early progression.
Fixed familiars still cost 120/120/180 Gold for the three basic professions.
The three phase purchases consume 6300 Gold. New slots at tier 1 consume 2880
Gold; upgrades, worker hires and storage are additional explicit sinks. Income
comes only from ordinary exports and explicitly claimed NPC contracts. Neither
phase migration nor UI acknowledgments grant currency.

## New recipe graph

All input counts, Essence and durations are per batch, quantity 1. Any compatible
slot of sufficient tier can craft a recipe after its phase unlock. First manual
completion discovers it globally; only then can staffed slots automate it.

| Recipe / phase / tier | Inputs | Essence / seconds | Output and base sale |
| --- | --- | --- | --- |
| Spore paste / 3 / press 1 | 2 mushrooms | 4 / 8 | Solid intermediate |
| Berry essence / 3 / distillery 1 | 2 berries | 6 / 10 | Liquid intermediate |
| Focus / 3 / cauldron 1 | 1 paste, 1 Mandrake | 6 / 10 | Potion, 95 Gold |
| Flare / 3 / cauldron 2 | 1 berry essence, 1 coal | 8 / 12 | Potion, 130 Gold |
| Aether serum / 4 / centrifuge 1 | 1 paste, 1 berry essence | 12 / 14 | Liquid intermediate |
| Ascension / 4 / cauldron 3 | 1 serum, 1 Fire Extract, 1 Mandrake | 20 / 20 | Potion, 360 Gold |

The final graph includes three consecutive manufacturing operations:
`berries → Berry essence → Aether serum → Ascension`, plus the press and coal /
Fire Extract branches. Every raw resource has manual and staffed production.
Existing slime randomness is never a new technology prerequisite beyond the
preserved Rage route; familiar acquisition uses guaranteed fixed workers.

Original seven hauling routes retain their order; bounded routes for new slots
are appended. Round robin scans O(slots × item types), not all slot pairs.
Each material also has a persisted next-consumer turn: even a one-item stream
alternates between hungry machines. Solid target choices are cached during a
route scan; liquid distribution visits each material/slot pair once. This fixes
an observed model stall where centrifuge intake continually beat the Focus line
to a newly delivered paste. Solid and liquid scarcity regressions cover rejoin.
Only solids/crates travel with the carrier; pipes move Essence/liquids. A manual
"supply next" intent adjusts the next route/cursor once, after which fair rotation
continues. Storage categories, in-transit conservation and the 7200 s offline cap
stay shared between online/offline. Both cauldrons share the active order quota.

From phase 3, new warehouse intake per material targets floor(category capacity /
material types): five raw types and four intermediate types. This leaves room for
new sources instead of filling the raw store with Mandrake/slime. Existing stock
above the target is retained; already picked-up cargo uses actual global space,
so buying phase 3 cannot trap an earlier delivery. Manual recipe changes return
inputs under global capacity. Explicit disposal and warehouse upgrades recover
old full stores. Target limits are visible in the warehouse panel.

The board presents three eligible contracts, replacing low-tier offers
with the highest reachable discovered recipes. Locked offers are explained but
cannot be accepted; initial Healing offers remain to teach the first contract.
New Focus/Flare/Ascension orders require recipe discovery, compatible built tier,
phase, sources/intermediate equipment and capacity. One active contract remains.

| Added contract | Count | Reward Gold | Deadline seconds | Availability |
| --- | --- | --- | --- | --- |
| Quick Healing | 3 | 60 | 480 | Initial reachable third offer |
| Focus | 4 | 500 | 1800 | Phase 3 + discovered reachable chain |
| Flare | 4 | 680 | 1800 | Phase 3 + discovered reachable chain |
| Ascension | 3 | 1500 | 3600 | Phase 4 + discovered reachable chain |

The existing first Healing contract stays first until its tutorial claim. Then
phase/tier/priority order selects the board deterministically. Original contracts
and their acceptance semantics remain compatible with M0–M2 regressions.

## Rare cauldron and persistence

Entering phase 3 atomically grants one predictable free resonant cauldron:
unique ID, ownerId, type, bounded +0.05 double-output bonus, lock flag and milestone
provenance/paidDerived=false. It occupies at most one built cauldron slot, never a
second owner. Equip/unequip rejects a slot with a paid job; its capped bonus is
captured in the next job, never applied retroactively. There is no trading,
deletion, cauldron gacha or payment endpoint. Lock is retained for future trading.

Schema 4 migrates validated V1/V2/V3 under the existing lease. Existing objects,
stats, paid ancestry, M2 receipt, jobs/cargo/RNG/balances and timestamps are copied;
new slots are empty, phase starts at 1, no historical milestone item is invented.
Construction, phase and equipment intents use a separate monotonic receipt and
the same ProfileStore candidate transaction as M2. Client prices/rewards/levels
are not authoritative; expected phase/level only prevents stale requests.

## Measured portable economy — 2026-11-04

`tests/M3Scenario.luau` starts with zero Gold/Essence and the normal three fixed
starters. It uses validated player intents, earned purchases and normal simulated
time, including the entire M1 tutorial/claimed NPC order. No resource injection,
rare-item bonus, familiar summon or admin action is used. Its familiar RNG throws
if called. Manual/detour paths use restricted policy; early automation uses an
unavailable-policy context. Production's saved slime/x2 events remain normal game
events. These are model measurements, not observed player speed or retention.

All rows are cumulative from first arrival; the phase price is already paid.
Clicks count Essence taps, harvests count manual gathering actions. Spending
includes pipes, equipment, warehouse, phases and fixed workers.

| Strategy | Phase | Seconds | Clicks | Harvests | Gold income | Gold spent | Balance |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Manual | 2 | 783 | 30 | 7 | 1048 | 568 | 480 |
| Manual | 3 | 1832 | 30 | 108 | 3078 | 3068 | 10 |
| Manual | 4 | 4848 | 30 | 399 | 9029 | 9018 | 11 |
| Early automation | 2 | 791 | 100 | 3 | 1020 | 568 | 452 |
| Early automation | 3 | 2459 | 100 | 8 | 3092 | 3068 | 24 |
| Early automation | 4 | 7149 | 100 | 17 | 9043 | 9018 | 25 |
| Detour/recovery | 2 | 2782 | 51 | 10 | 1146 | 668 | 478 |
| Detour/recovery | 3 | 4267 | 51 | 13 | 3204 | 3168 | 36 |
| Detour/recovery | 4 | 9012 | 51 | 21 | 9155 | 9118 | 37 |

| Strategy | First manual Ascension | Full staffed setup | Clicks / harvests / disposals | Income / spending after next 1200 s | Focus / Ascension sales in those 1200 s |
| --- | ---: | ---: | --- | --- | --- |
| Manual | 6877 s | 7357 s | 30 / 608 / 0 | 19994 / 14068 Gold | 13 / 13 |
| Early automation | 10273 s | 11341 s | 100 / 30 / 22 | 20993 / 14068 Gold | 12 / 16 |
| Detour/recovery | 12173 s | 13214 s | 51 / 36 / 25 | 21281 / 14168 Gold | 14 / 16 |

Manual work exchanges many harvest actions for shorter modeled progression.
Automation waits on transport/Essence throughput and uses deliberate disposal
while changing recipes; it does not click continuously after passive crystal.
Detour buys an early optional 100-Gold upgrade, rejects a premature phase request,
runs 1800 seconds into storage saturation and pauses/reassigns a worker before
recovering. There are no bailouts. After final setup, both potion lines run for
1200 seconds without further manual input; all six processors are staffed.

The phase-three intake targets and per-material delivery turns were added after
these scenarios exposed warehouse monopolization and shared-paste starvation.
There is no confirmed softlock in the covered routes. Live economy/pacing still
needs observation; these provisional prices are not a claim that every player
will finish within these times.

## Validation and limits

404 tests = 316 retained + 88 M3. Complete late-factory state is identical after
7200 one-second online updates and one offline catch-up, including RNG, cargo,
cursors and queues. An immediate repeat does no work. On Windows x64 / Node
24.22.1 / Luau 0.745, one recorded synthetic run of eight independent 13-slot
profiles × 7200 ticks took **1.925 CPU seconds**. The log prints `M3_BENCH`; this
includes portable domain work only, with no time threshold or live FPS claim.

`node scripts/setup-tools.mjs` and `node scripts/check.mjs` are the exact local
package-script entry points (npm absent). CI uses npm on Windows and Ubuntu and
records final head SHA, 40 compiled Luau sources, portable analysis, tests, Rojo
place/sourcemap. Exact-SHA run/job evidence is in the M3 Draft PR.

Studio, real DataStore/PolicyService, phone and 2–8 clients remain **BLOCKED**.
See [ACCEPTANCE.md](ACCEPTANCE.md) for the requirement-to-evidence matrix and live
checklist. No Roblox publication, merge, Rebirth or trading is part of this work.
