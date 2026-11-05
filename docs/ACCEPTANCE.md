# Manual acceptance checklist

CLI/CI passing is necessary but does not mark any item below as completed.

## Current: M7.1 A.2c — Gate A pending

**ART PENDING.** A.2b direction accepted; explicit owner APPROVED is still required.
Only A.2c was implemented. [Actual before/after Studio evidence](evidence/m7-a2c/README.md)
contains five states at graphics 5/10, full-game UI and a native 45-second recording.
[Implementation, diagnosis and budgets](M7_A2C_ATMOSPHERE.md).
867 tests preserve all 859 inherited cases. Studio verifies owner restoration,
all-tier caps, Reduce Motion and asset loading. The flat floor is quieter at 5;
fine foliage edges, Terrain grain and thin path artifacts remain open.
Physical phones, experience permissions and multiplayer load remain BLOCKED.
UI #18 waits for Gate A; island #19 waits for art and later UX approval. Draft,
no merge/publish. Earlier sections below are historical milestone records.

## M7.1 Gate A.2 — Issue #20

**ART PENDING; low-quality stippling OPEN; live/device gates BLOCKED.**
[Implementation, caps and diagnostic limits](M7_A2_ATMOSPHERE.md),
[raw Studio evidence and reproducible preview](evidence/m7-a2/README.md).
851 portable tests preserve all 844 inherited cases. Studio verifies the effect
lifecycle and caps, plus the five visual presets and ordinary UI day/night views.
A 45-second reproducible Studio preview is supplied; recorded video is not.
This does not pass owner visual approval, #18 UX, real-phone performance,
multiplayer or backend acceptance. Do not start #19 or merge/publish.

## M7.1 revised one-farm Gate A — 2026-11-05

[Issue #16](https://github.com/branch-danya-dev/magicpotiongacha/issues/16), stacked
on M6 PR #15 at `bbc8891d45e551b691363383d1cacf2d69354283`.
844 CLI cases (all 810 original + 34 environment), source integrity and both
Rojo builds are required. Actual Studio screenshots cover five light/weather poses,
spawn, foliage, Bazaar and ordinary gameplay UI. [Evidence and limits](M7_ENVIRONMENT.md),
[current raw images](evidence/m7-revision/README.md), [asset provenance](../assets/environment/README.md).

**The earlier primitive pilot is ART REJECTED; the replacement is OWNER REVIEW
PENDING.** The owner approved direct preparation/import despite missing game-dev.
Fourteen inspected CC0 MegaKit Standard models are imported and render in Studio;
the receipt pins the actual mesh/texture IDs. The new one-farm composition uses
bounded Terrain, 432 decor Parts and 116,626 authored triangles excluding Terrain.
Studio collision guards passed. Beauty captures pin Roblox Manual quality 10;
dark stippling at Automatic/lower quality remains an open renderer/device check.
The ordinary full-game capture uses Automatic quality and memory-only progress.
The existing contextual billboard filter does not resolve the normal gameplay UI
acceptance: issue #18 remains an explicit UX gate on PC and phone. **Gate B / #19
is withheld until ART APPROVED and the UX check.** See the revised art direction.
`EnvironmentArtEnabled=false`, monetization/trading/SKUs unchanged. Studio visual
rendering and noncollision property assertions do not pass gameplay traversal,
real DataStore, PolicyService, payments, phone or multiplayer acceptance.

## M6 implementation record — 2026-11-05

Scope: [Issue #14](https://github.com/branch-danya-dev/magicpotiongacha/issues/14).
Branch `feat/m6-collectible-monetization`, stacked on open/unmerged Draft
[PR #13](https://github.com/branch-danya-dev/magicpotiongacha/pull/13), branch
`feat/m5-rebirth-epochs-dailies`, base SHA
`9da973f221ee162660184ae7da80953631c5b5b7`.
Rules/protocol in M6_MONETIZATION were recorded before code changes. No merge,
Roblox publication, real purchase or live acceptance was performed.
**MonetizationEnabled=false, PurchaseQAApproved=false, all SKUs=0,
TradingEnabled=false. All live gates remain BLOCKED.**

| Issue #14 criterion | Portable implementation / evidence | Remaining live evidence |
| --- | --- | --- |
| Fixed catalogue, honest UTC windows and disabled SKU | `m6_model.spec`: before/start/inside/end/after, malformed config, default switches, exact shapes rejecting price/clock/owner/proof; server rechecks identity/proximity/availability | Real Dashboard IDs, actual price, native prompt and date approval |
| Same earned/paid outcomes; no sold currency/resources/randomness | Exact pet/cauldron comparison, cosmetic changes only entitlement, no bonus balance, no chance modifier; server grant port never exposed through remotes | Product/pass settings and disclosure |
| Three attainable F2P routes | `m6_acceptance.spec`: new, genuinely earned Rebirth veteran, restricted/no-gacha/no-trade; both seasonal items; exact income/spend/action traces in M6_MONETIZATION | Human pacing/retention unmeasured |
| Measured bounded production effect | Tier 1/2/3 single-carrier delivery, capped stats, captured brew duration, same inputs/chance, no slot/recipe/input bypass; Gold/paid 7200-s parity | Real rendering, phone performance and full-load supply bottlenecks |
| Four-boundary purchase recovery | `m6_receipt.spec`: each before/after crash, restart/new lease, transient lost replies, repeated callbacks, reentrant callbacks/two server coordinators, old writer fencing | Real DataStore budgets/timeouts/shutdown and Marketplace replay |
| Exact purchase identity and archival grants | Wrong player/product/ID, unknown SKU, conflicting immutable grant, invalid future journal, separate genuine PurchaseIds, receipt after window/sales close, ack after player leave | Dashboard mapping review and real delayed callbacks |
| Full-capacity delivery and no duplicate charge | 128 pets/16 cauldrons, durable queue/restart, actual Fuse releases space, Gold/delivery unknown-write retries, bounded history/queue with no eviction | Actual platform purchase with raced/full inventory, support UI |
| Permanent pass ownership | True/false/error lookup, session change during yield, repeat positive ownership, each durable before/after fault; Gold gives same account cosmetic | Real ownership cache propagation and finished-event hint |
| M2/M4 interoperability | Seasonal Fuse exact outcome, paid OR/known AND, paid pet/cauldron transfer then receipt replay, both-player policy denial, pending trade recovery and negotiation exclusion | Both actual policies, private transfer, disconnect/server switch |
| M5 preservation and exclusion | Items, entitlements, paid provenance, queued rights and proofs survive real reset command; same value gate excludes receipt/reset race; original legacy-balance guard retained | Actual rejoin/Rebirth before/after payment and pending M4 |
| V1–V6 → V7 | All original migration cases plus authentic V6 progressed/pending-COMMIT fixture; no old-field changes, no fabricated receipts; future save never reset | Disposable real old-schema keys and coherent V7 rollout |
| Shop UI has no authority | `m6_ui.spec`: three previews, distinct Gold review, stable retry, native prompt intent only, missing-price denial, ended/full/queued display, cancel/refresh | Portrait/landscape, joystick/camera, loading/error states |
| Regression and build | **810 tests = all 696 inherited + 2 new generic-species cases + 112 dedicated M6**; 81 Luau sources; compile, portable analyze, Rojo place/sourcemap | Exact final SHA and Windows/Ubuntu CI jobs/artifacts recorded in Draft PR |

No original case was removed. M2's permanent-shop Fuse loop still covers all its
original families; the new seasonal family has separate acquisition/Fuse tests.
Current-schema/future-schema assertions were advanced in the M5 persistence suite.
Native adapters compile and package; CLI tests do not execute Roblox services.

### M6 live acceptance steps — all BLOCKED

- **Owner preparation:** approve provisional 5–19 November 2026 UTC event and Gold
  prices/bonus; supply immutable product/pass IDs and real Dashboard prices; close
  external sales consistently with the window. Preserve released mapping archives.
  Use separate QA profile/trade/receipt stores and a private allowlisted place.
  No task here authorizes real spending or publication.
- **S1 / Marketplace:** in an explicitly authorized QA session with real persistence,
  review all three previews/Gold prices/native platform prices. Cancel a native
  prompt, then separately approve a genuine product/pass test. Confirm no grant
  from product-finished events; repeat receipt and rejoin; verify pass lookup.
  Disable flags/API access and confirm Gold and normal production remain usable.
- **D1 / durability:** force authorized QA disconnections/controlled store failures
  around each recorded boundary; rejoin another server, inspect proof and original
  instance identity. Test full inventories, queued recovery, event ending while
  payment is pending, mapping conflict, unavailable player, server close and pass
  query delay. Never edit/delete proofs to make a purchase appear successful.
- **P1 / trading and Rebirth:** separately approve private M4 testing, check both
  players' real policy before commit; transfer seasonal items, Fuse paid ancestry,
  replay original receipt, then reset a completed factory. During negotiation or
  recovery, new grants wait. Verify queue/rights survive reset and no legacy paid
  balance disappears. Restore TradingEnabled=false after QA.
- **M1 / phone:** small portrait and landscape, all three cards, review/confirm,
  native prompt price, ended/owned/queued/delivered messages, repeated taps,
  close/reopen, joystick/camera and ghost-trail/brewing-light readability.
- **P2 / 2–8 clients:** concurrent callbacks, trades, resets, quit/rejoin and delayed
  session cleanup; measure actual frame/server time, replication and datastore
  budget. Record device, Studio/Roblox version, tested SHA and namespaces.

Every unchecked live item remains a release gate. M7 art/audio/mobile optimization
is the next roadmap stage and is not claimed complete here. Older records below
are historical evidence for their own milestone.

## M5 implementation record — 2026-11-05

Scope: [Issue #12](https://github.com/branch-danya-dev/magicpotiongacha/issues/12).
Branch `feat/m5-rebirth-epochs-dailies`, stacked on open/unmerged Draft
[PR #11](https://github.com/branch-danya-dev/magicpotiongacha/pull/11), branch
`feat/m4-secure-p2p-trading`, base HEAD
`8be6af541aa5aa2a82710db8f75044966047c22f`. No merge or Roblox publication.
**TradingEnabled=false. Studio/real backend/phone/multiplayer acceptance BLOCKED.**
Earlier milestone records remain historical. M5's rules were written before the
schema/commands; exact final head and CI run/job evidence are recorded in its PR.

| Issue #12 acceptance point | Portable evidence | Remaining limit |
| --- | --- | --- |
| Reset/preserve/recompute contract | `M5_REBIRTH.md`; explicit whitelist, complete preservation assertions in `m5_model.spec` | Two-stage on-device review S1/M1 |
| Real phase-4 final gate, checkpoint, exactly one shard | `m5_model.spec`: actual batch, archived-only denial, stale cycle, no confirmation, paid-balance guard, reset timers/jobs/stock, no old offline replay | True DataStore acknowledgement/shutdown D1 |
| Collection/cauldron/rights/history conservation | Full original metadata/locks/paid ancestry/serials/receipts/tutorial preserved; old M2/M3 receipts cannot regrant; milestone remains consumed after transfer | Real join and rendering S1/D1 |
| Trade compatibility | `m5_trade.spec`: transfer before reset, reverse transfer after reset, invitation/negotiation/ready and yielding-policy denial, reset save blocks new invitation, all six commands blocked by persistent pending; M4 crash oracle retained | True crash/other-server recovery and both-player policy D1/P1 |
| Atomic writes and stable operation identity | `m5_store.spec`: all six commands × before/after unknown writes, repeated callbacks and simultaneous identical requests; conflicting rewards, changed Player guard, lease takeover, unique day-seven uncertain claim | Roblox quota/latency/retry/shutdown D1 |
| Three epochs, distinct dependencies and bounded factors | `Config.epochRules`, `m5_model.spec` high-count bounds, nine real routes in `m5_acceptance.spec`; generated intermediate/recipe IDs and active-epoch validation | Greybox theme readability S1/M1 |
| Complete F2P route in each epoch | 3 strategies × 3 cycles, zero admin grants/RNG/trade/daily subsidy; actual final batch and two automatic lines, exact Gold accounting, original 12 earned pets/one cauldron retained; table/logs in `M5_REBIRTH.md` | Model time excludes travel/latency; retention unmeasured |
| Offline parity, no automatic meta rewards | Complete-profile equality for each epoch at 7200 seconds; repeated catch-up gives nothing; actual third reset wraps to bounded Classic | Real leave/rejoin D1 |
| Permanent perks and direct-choice special altar | Exact prices/stats, max/owned-title denial, no draw, capacity-before-debit, paid ancestry; 1.15 industry cap after stat caps | No random shard altar or paid shards implemented; M2 policy gates unchanged |
| Three UTC daily goals | `m5_daily.spec`: real click/manual batch/NPC events, online/offline/auto distinction, all day rotations actually earned in phase 1, explicit claims and another-server replay denial, clock/day spoof/rollback | Device timezone and midnight UX M1 |
| Seven-day calendar and inventory rights | Days 1/7/8, skipped/backwards/duplicate days, later-series replacement, day-seven uncertain writes; 128-slot reward right survives date change/Rebirth/reload and is delivered once after Fuse | Touch delivery/error copy M1 |
| V1–V5 → V6 migration | All historical suites retained; authentic pre-M5 V5 pending-COMMIT fixture preserves every old field, recovers before payout; future/invalid metadata/shards/perks/cycle/epoch stock/claims/receipt never overwrites | Isolated real mixed-version recovery D1; no old-server downgrade |
| UI has no reward authority | `m5_ui.spec`: two distinct taps, stable cycle/request, stale review invalidation, cancel/welcome/reopen/Continue send no grant | Compilation is not layout/joystick/camera acceptance; portrait/landscape BLOCKED |
| Regression/toolchain | **696/696 tests: 581 retained + 115 M5**, 66 Luau sources; pinned Luau 0.745/Rojo 7.7.1; compile, portable analyze, Rojo place+sourcemap | npm absent locally: exact scripts `node scripts/setup-tools.mjs` then `node scripts/check.mjs`; exact-SHA Windows/Ubuntu run evidence in Draft PR |
| Release scope | ServerSettings unchanged; TradingEnabled=false; no Robux/products/gamepasses, paid shards, global market, final art or publication | All Issue #2 live gates remain BLOCKED |

The existing M3 completion fixture now sets current-cycle final production in
addition to archived discovery; its assertion remains. The M4 conservation oracle
validates a temporary migrated view of historical records, never mutating stored
fixtures. No original test case was removed.

### M5 live acceptance steps (all BLOCKED)

- **S1 — Studio:** run each greybox theme and four phases with real controls;
  inspect recipes, prices, both parallel lines and staff reuse. Produce the final
  batch, inspect reset/preserve values, cancel once, then confirm once. Reopen
  welcome/Continue and verify no additional shard or reset. Complete two further
  cycles; check repeating Classic and no second milestone cauldron.
- **D1 — isolated DataStore:** use separate private QA stores and coherent V6
  servers. Test unknown before/after saves for reset, perk, pet and calendar day 7,
  disconnect/close/rejoin, lease expiry and stale clients. Import representative
  historical saves, including a pending M4 COMMIT; verify recovery precedes
  catch-up. Inspect collection identities/provenance, claim flags and ledgers.
- **P1 — policy/trade:** in the allowlisted private QA place only, test restricted,
  allowed, failed and changing policy for both participants. The fixed shard altar
  remains deterministic; existing random summons keep disclosure. Attempt Rebirth
  during invite, ready, commit and recovery. Transfer before and after reset,
  crash one side, then reconnect on another server. Restore TradingEnabled=false.
- **M1 — phone:** portrait/landscape at small widths; scroll long reset text and
  all reward cards; tap review/confirm without accidental reset, close panels and
  check joystick/camera. Inspect shortage/full-inventory messages, title display,
  UTC-midnight update, skipped-day and day-eight calendar. Change phone timezone;
  verify server day/claim history does not change.
- **P2 — 2–8 clients:** independent cycles, simultaneous claims and private test
  trades; verify no cross-plot interaction, stale-session cleanup or shared state.
  Measure actual device/server performance separately from portable traces.

## M4 implementation record — 2026-11-05

Scope: [Issue #10](https://github.com/branch-danya-dev/magicpotiongacha/issues/10).
Branch `feat/m4-secure-p2p-trading`, stacked on the actual open/unmerged Draft
[PR #9](https://github.com/branch-danya-dev/magicpotiongacha/pull/9), base branch
`feat/m3-four-phase-tycoon`, HEAD
`2d9e6eb6dbb3417ec4a5aa3438bf9d3b035b39e9`, rechecked before submission.
No merge or Roblox publication. **TradingEnabled=false; live acceptance BLOCKED.**
Earlier milestone records below remain historical, not current feature exclusions.

| Issue #10 acceptance point | Actual status | Evidence / remaining limit |
| --- | --- | --- |
| ADR before Remotes; decision/ownership/dual-use argument | **PASS (design + fake backend)** | [M4_TRADING](M4_TRADING.md), `Trading`, `TradeJournal`, `TradeCoordinator`: persistent whole-profile reservations, immutable UUID/hash/snapshots, journal COMMIT CAS, ABORT barriers, both apply acknowledgments before clearance. CLI evidence does not prove the live backend. |
| Bazaar, same-server identity/proximity, single negotiation, expiry/spam | **PASS (portable); runtime BLOCKED** | `trade_session.spec`: self/foreign-server token, wrong actual session, out of range, third player, busy value operation, post-policy-yield race, decline/cancel/expiry/cooldown; exact Protocol + shared control budget. World has central prompt; actual movement/prompt remains S1. |
| Two columns, six items, exact version/hash, independent confirmations | **PASS (model/compile); visual BLOCKED** | Offer edits invalidate both ready/confirm states; stale hash/version and metadata changes reject. 1:1, 2:1, 3:2 and safe gifts in `trade_model.spec`. `TradeUI` displays IDs, rarity/evolution, raw/current-cap stats, ancestry, cauldron type/bonus and eligibility; two-step explicit review, Cancel, six-card pages. Phone readability and touches remain M1. |
| Only pets/rare cauldrons; locks/use/ownership/capacity | **PASS (portable)** | `trade_model.spec`: wrong owner/type/bonus, foreign/missing/duplicate ID, locked/assigned/equipped item, protected starter, legacy/unknown origin, currency, over-six offer, net 128 pets/16 cauldrons, incoming collision. Existing idle-only equipment/prepaid-job tests retained. |
| Persistent conflict protection and stable metadata | **PASS (fake backend)** | Pending denies Factory act/advance, collection/shop/summon/Fuse preview/lock, progression/equipment and ordinary transact. Ordinary save/release preserves exact reservation; forged removal fails. Original IDs/stats/parents/paid flags/timers retained, cauldron owner changes; workstation cap still applies to a 100-stat gift. M3 phase receipts still prevent repeated milestone issuance. |
| All durable boundaries / unknown replies / duplicate callbacks | **PASS (fake backend)** | `trade_durable.spec`: 16 normal calls including registry admission; crash before AND after each, transient lost reply at each, 2–3 callback replays. Oracle after every backend write checks no dual-use and no original item absent from both profiles and escrow; final outcome matches the unique decision. Unknown COMMIT UI stays recovering; later cancellation cannot undo it. |
| Partial apply, cross-server/reverse join, absent participant, stale lease | **PASS (fake backend)** | All apply/clear boundaries injected; recovery itself interrupted before/after all 17 absent-player lease/write/release calls. New-server loads in both orders, frozen gameplay until reconciliation, foreign lease rejection, missing profile/journal fail closed, old snapshots cannot save, delayed callback rejects expired lease. No test grants defaults as recovery. |
| Concurrent overlapping trades / ABORT race | **PASS (fake backend)** | Second journal offering the same item cannot disturb the first reservation; ABORT also persists a sequence barrier for a never-prepared side; a delayed prepare and racing second-side reservation cannot escape it. |
| Bounded registry, retention and budget | **PASS (fake backend)** | Fixed 16×128 registry; full shard denies before profile changes, round-robin discovery reaches later shards, lost registration response/orphan cleanup, delayed creation after cleanup, seven-day COMPLETE retention/compaction, lost delete reply and retry. Low admission budget clears confirmations without freezing. Unfinished records never evicted. Live quota/hot-key throughput remain D1/P1. |
| Both-party PolicyService / paid and unknown ancestry | **PASS (portable); actual service BLOCKED** | `trade_model.spec` + `trade_session.spec`: allowed/restricted/missing/error/expired, fresh post-yield guard, revoked permission, superseded forced refresh, actual Fuse of paid/Legacy/historical parents. AND known-origin proof and OR paid ancestry; fixed shop and milestone items use the same conservative both-allowed gate. Unknown history never becomes free-tradeable. |
| Exact intents and presentation failures | **PASS (portable/compile)** | Forged prices, owners, snapshots/stats, rewards, decisions, clocks and policy rejected at outer and item levels; duplicate requests do not reapply. A failed presentation callback cannot strand a frozen exchange before persistence. Server admission switch rejects even direct intents. Roblox remote routing remains S1. |
| V1/V2/V3/V4 → V5, no historical rewrite | **PASS (fake backend)** | Retained historical migration suites plus authentic M3 fixture in `trade_migration.spec`: every old field, equipped locked cauldron, paid ancestry, receipt, job and fairness cursor preserved. Future/invalid sequence/hash/stage/receipt/old trade state cancel before overwrite. |
| Retain 404 M0–M3 tests / F2P and offline | **PASS** | No tests removed; current-schema assertion updated, three high-stat fixtures explicitly mark Legacy origin proof false. All economy/production, RNG, offline equality/cap, policy, collection, construction, lease and quarantine regressions still run. |
| Eight-user bounded synthetic workload | **PASS (fake backend)** | Eight distinct users in one manager/backend, four simultaneous negotiations per round, 20 exchanges and 1160 intents, including 1000 denied with trading disabled; one local run 0.344 CPU s. This excludes network latency and does not establish Roblox FPS/replication/throughput. |
| Local tool integrity, compile, analyze, tests, place/sourcemap | **PASS** | Windows x64 / Node 24.22.1: **581/581 tests** (404 + 177), **54 Luau sources**. Pinned Luau 0.745/Rojo 7.7.1 verified. Exact package script entry points used (`node scripts/setup-tools.mjs`, `node scripts/check.mjs`) because npm is absent locally. |
| Exact final SHA Windows + Ubuntu CI | **Recorded in M4 Draft PR** | PR body records final SHA, run/job links, source-SHA log lines, counts and artifacts after CI. Existing SHA-pinned actions/tools and explicit PR-head checkout retained. Local Windows run is not Ubuntu evidence. |
| Public release, Studio, live backend/policy/phone/2–8 clients | **BLOCKED — S1/D1/M1/P1** | No live Studio, real QA DataStore crash/reconnect, actual policy, real phone or multiplayer performance session performed. Issue #2 remains open. Public trade is off; private QA also needs explicit server flag and Studio/allowlisted place. |

### M4 live acceptance steps (all BLOCKED)

1. Use a separate private QA experience and dedicated **both** player/journal
   namespaces. Set TradingEnabled=true only in that QA build and TradingQAPlaceId
   to its place; use UseMemoryInStudio=false for persistence evidence. Do not
   alter production data or the existing registry shard count. Confirm the normal
   build rejects every trade intent even if the UI is bypassed.
2. With two clients, meet at the central Bazaar. Test invite/decline/expiry,
   leaving the zone, same-user/rejoined Player identity, a third participant,
   edits after ready and after one confirm, gifts and multiple objects. Compare
   both visible columns/hash/version; no timeout or partner action confirms for
   the other user. Check long IDs/parents, scrolling and 44px controls on portrait,
   landscape emulator and a real phone.
3. Obtain actual policy outcomes for both participants, including missing/error
   and changed permission between invite and commit. Use backed-up QA fixtures
   for paid and unknown historical origins. Forge the exact remote directly;
   UI hiding must not be the only denial. Production/fixed purchases still work.
4. Instrument the QA backend at the ADR's 16 boundaries: pause/stop before and
   after registry, journal, each prepare/ack, COMMIT, each apply/ack and clearance.
   Observe persisted records and reconnect in both orders/on another server.
   Distinguish a rejected write from a committed write with a lost response.
   At every stage count **available** copies; both profiles must converge to the
   single journal decision. Never repair by manually duplicating a reward.
5. Keep one or both participants absent; let another surviving QA server acquire
   ordinary expired leases and scan the durable registry. Repeat with admission
   disabled, a still-live foreign lease, low quota, a full registry shard, failed
   deletion, a registration-only orphan and a missing/corrupt journal. Pending
   remains inaccessible; no defaults or unfinished-transaction GC are allowed.
6. Migrate backed-up V1/V2/V3/V4 records under real leases. Compare historical
   money, items/IDs/ancestry, paid jobs, offline timestamp/RNG and receipts; repeat
   login/catch-up and stale-server save. Never downgrade a migrated key.
7. Run 2–8 clients with full factories and overlapping trades. Measure queue,
   decision/recovery latency, DataStore budgets/throttling, server CPU/memory,
   replication and phone FPS. Record exact build SHA, Studio/platform version,
   device, private namespaces, scenario results and safe audit IDs/hashes before
   changing any live acceptance status. No credentials or full profiles in logs.

## M3 implementation record — 2026-11-04

Scope: [Issue #8](https://github.com/branch-danya-dev/magicpotiongacha/issues/8).
Branch `feat/m3-four-phase-tycoon`, stacked on open/unmerged Draft
[PR #7](https://github.com/branch-danya-dev/magicpotiongacha/pull/7), base branch
`feat/m2-familiars-gacha-fuse`, HEAD
`f9c34c8383bee2a0fdd1ef08167103725a924672`. No merge or Roblox publication.
Overall live acceptance: **BLOCKED**. Earlier records below remain historical.

| Requirement | Actual status | Evidence / remaining limit |
| --- | --- | --- |
| Preserve 316 M0–M2 tests | **PASS** | No tests removed. `m2.spec` uses current/future schema constants and compares every old station/cooldown field; `migration.spec` compares all original cooldowns while allowing new empty slots. All policy/gacha/shop/Fuse/lease regressions still run. |
| Four phases, fixed builds and graph | **PASS (portable)** | `m3_progression.spec`: every phase purchase, all 21 new slot/tier purchases, insufficient funds/prerequisites, stale/conflicting IDs, exact costs, no final reset/payout. Config defines 13 IDs/archetypes/waypoints; World reflects committed state. Physical prompts/geometry remain S1. |
| New sources, six recipes, three-operation final chain | **PASS (portable)** | `m3_factory.spec`: each recipe's exact prepaid inputs/Essence, discovery, phase/tier/archetype gates. `M3Scenario` manually discovers all technologies through real inputs, then staffs six processors and two cauldrons. |
| Multiple routes, scarce supply and capacity | **PASS (portable)** | Two consumers share single-item solid and liquid streams across validated reloads; supply-next resumes rotation; intake targets preserve room; old cargo survives phase unlock; sources/pipes/solids remain separate. Original seven route indices retained; bounded O(slots × types) scan. |
| Parallel NPC reserve/expiry/claim | **PASS (portable)** | Shared quota across two cauldrons, excess export, second queue's own delivery, carrier removal/expiry, no repeated sale/claim; three initial reachable offers, new phase/discovery/source-chain eligibility and one active contract. |
| Rare-cauldron item | **PASS (portable)** | Unique free phase-three grant, ownership, incompatible/duplicate equip rejection, lock, idle-only swap, snapshotted bonus/cap, preserved strong base stats; current equipped/locked item and provenance roundtrip. No trade, gacha or deletion handler. |
| Durable construction and economy protection | **PASS (fake backend / portable)** | `m3_store.spec`: build/phase/equip before/after-commit failures, lost responses, identical/conflicting concurrency, replay after rejoin and M2-shop/M3-phase shared gate. `m3_progression.spec` rejects client price/bonus/owner/phase/reward/completion fields and validates access targets. Runtime authorization still S1. |
| V1/V2/V3 → V4 | **PASS (fake backend)** | Historical suites + genuine V3 fixture captured/validated with M2 HEAD; every old field preserved, new slots empty, no inferred phase grant; future/corrupt owner/bonus/technology/cursor/receipt fail closed; lease takeover and repeated catch-up tested. |
| Three full free progression routes | **PASS (portable)** | `m3_acceptance.spec`/`M3Scenario`: zero balances, manual/early-auto/detour, restricted or unavailable policy, no familiar RNG/admin grants; final recipe and 1200-second parallel output. Cumulative time/click/income/spending tables in [M3_RULES](M3_RULES.md). |
| Offline equality and synthetic scale | **PASS (portable)** | Complete 7200-second online/offline equality and zero repeat; 8 independent profiles × 13 slots × 7200 ticks, one recorded local run 1.925 CPU s. No Roblox FPS/replication/server latency claim. |
| Local tools / compile / analyze / build | **PASS** | Windows x64 / Node 24.22.1: **404/404 tests**, **40 Luau sources**, portable analysis, Rojo place/sourcemap. Exact package entry points used because npm is absent locally. Tool/action SHA pins retained. |
| Final Windows + Ubuntu CI | **Recorded in M3 Draft PR** | Exact final head SHA, run/job links and log results recorded there. Explicit PR-head checkout; each OS artifact includes verification.log/place/sourcemap. Local Windows results do not count as Ubuntu evidence. |
| Studio, true persistence/policy, touch and scale | **BLOCKED — S1/D1/M1/P1** | No live Studio/QA DataStore/PolicyService/phone/2–8-client session. Code compilation, fake backend and synthetic workload do not close Issue #2. |

### M3 live acceptance steps (all BLOCKED)

- Play from empty clearing through all four phases without grants or summons,
  including the saved M1 tutorial/NPC order. Repeat under actual restricted and
  failed PolicyService results; record observed timings separately from model data.
- Inspect agriculture left, processing centre/right and warehouse/altar rear.
  Verify each fixed slot, waypoint, phase frame and local tier; no overlapping
  prompts, obstructed movement or disappearing jobs/cargo during upgrades.
- Walk over build pads: no debit. Hold the explicit prompt once: one durable
  purchase and visual update. Double-tap, stale request, other plot, respawn and
  disconnect during build/phase/equip must not bypass authorization or duplicate.
- Run both cauldrons with shared scarce paste/liquids; change supply priority,
  remove workers and fill stores. Check intake targets, cargo conservation, idle
  reasons, recipe changes, quest reservations/delivery/expiry and exactly three
  reachable board offers at each technology level.
- Equip the guaranteed item on one idle cauldron, lock it, move it after a batch,
  rejoin and inspect backed-up QA records. Active-job swaps and duplicate installs
  must fail; milestone gift occurs once; no Rebirth/trading action exists.
- In an isolated private QA namespace, migrate V1/V2/V3 fixtures with real cargo,
  paid ancestry and receipts; test lease contention, failed/ambiguous saves and
  two-hour catch-up. Do not reset a rejected record or downgrade a migrated key.
- On portrait/landscape emulator and real phone, inspect the phase graph, long
  prerequisite text, horizontal tabs, recipe/worker selection, rare-item controls,
  44px actions and closed-menu movement/camera. Compile is not visual acceptance.
- Run 2–8 clients with full factories; measure FPS, memory, replication, server
  tick/catch-up and commit latency, then respawn/reconnect/leave. Record source SHA,
  Studio version, QA namespace and device details before closing live blockers.

## M2 implementation record — 2026-11-04

Scope: [Issue #6](https://github.com/branch-danya-dev/magicpotiongacha/issues/6).
Branch `feat/m2-familiars-gacha-fuse` stacks on the actual open/unmerged Draft
[PR #5](https://github.com/branch-danya-dev/magicpotiongacha/pull/5), HEAD
`322f027465e8909902a79eaa9682c9017cf997c2`, rechecked before submission.
M2 targets `feat/m1-production-onboarding`. No merge, Roblox publication or
live-backend setting change is included. Overall live acceptance: **BLOCKED**.

| Requirement | Actual status | Evidence / remaining limit |
| --- | --- | --- |
| All M0/M1 regression coverage | **PASS** | All 203 tests retained. Existing assertions now target current schema; migrated pets compare every old field plus Legacy metadata, high-stat preservation fixtures identify Legacy origin, and hire protocol includes requestId. No tests removed. |
| Exact final species and stat probabilities | **PASS (portable)** | `collection.spec`: exhaustive 100000 rarity integers match ten exact weights and four tier totals; disclosed tuple counts/probabilities reconstruct 100%; all species endpoints, independent stat calls, invalid ranges/config/rolls tested. Standard UI discloses percentages/ranges/exact fractions before confirmation; actual rendering remains S1/M1. |
| Unique instances, caps, inventory capacity, fixed shop | **PASS (portable)** | `collection.spec`/`m2.spec`: distinct IDs, serial/collision rejection, full/partial batch capacity before spend/RNG, exact ten fixed offers, capped effective skill with unchanged base stats. Search/sort/lock/free filter and six-card paging compile; live usability remains S1/M1. |
| Deterministic Fuse and provenance | **PASS (portable)** | All six evolution recipes, every allowed integer improvement, duplicate/missing/mixed/locked/assigned/terminal/over-cap Legacy parents, stale/expired preview and explicit confirmation, one paid parent, paid currency, full-inventory net -4 and timer cleanup. |
| Replay/concurrency/failure durability | **PASS (fake backend)** | `collection_store.spec`: hidden candidate until confirmation; CAS replay; lost response before/after commit; frozen old state; reconnect; concurrent identical/conflicting summons and concurrent Fuse; failed Fuse; leave/invalidation during commit; thrown RNG. No live DataStore claim. |
| Policy unrestricted/restricted/failure | **PASS (portable)** | `policy.spec`: explicit permission only, TTL boundary, error/missing/malformed/timeout adapter result, revoked permission, cache and late-result fencing; guaranteed fallback works. Spoofed policy/price/stats/seed/IDs/time are rejected. Actual PolicyService/lookup timeout integration remains S1/D1. |
| V1/V2 migration and working factory | **PASS (portable)** | Old V1 suite retained; authentic V2 fixture preserves every field, strong paid Legacy worker, jobs/tanks/queues/cargo; callback replay/lost reply, malformed/future metadata and paid laundering fail closed; complete online/offline equality and no repeated interval. |
| F2P restricted and lookup failure through Rage/Fuse | **PASS (portable)** | `M2Scenario` starts at zero with valid intents; earned fixed hires only, full M1 tutorial/NPC, Golden Slime at 796 s, first Rage at 1347 s, seven automatic Rage sales in next 1200 s, no familiar RNG. Model timing is not observed player timing. See [rules/balance](M2_RULES.md). |
| Local compile / analysis / build | **PASS** | Windows x64 / Node 24.22.1: **316/316 tests**, **31 Luau sources**, portable analysis, Rojo place and sourcemap. Local commands are exact package-script entry points (`node scripts/setup-tools.mjs`, `node scripts/check.mjs`) because npm is unavailable here. |
| Final Windows + Ubuntu CI | **Recorded in M2 Draft PR** | PR contains exact head SHA and run/job evidence. Existing SHA-pinned actions/tools and explicit head checkout retained; artifacts include `verification.log`, place and sourcemap. |
| Altar, disclosure UI, real policy, reconnect, mobile, 2–8 clients | **BLOCKED — S1/D1/M1/P1** | No Studio, private QA DataStore/PolicyService session, real phone or multiplayer performance run performed. Portable results do not close Issue #2. |

### M2 live acceptance steps (all BLOCKED)

- At the own rear altar, inspect all ten final probabilities, uniform stat ranges,
  exact fractions and fixed shop outcomes before spending; verify wrapping/scroll
  and 44-pixel touch controls in portrait/landscape and on a real phone.
- For unrestricted/restricted/error policy cases, observe the actual server lookup
  and UI fallback. Forge random requests directly: restriction/error must deny
  without debit, while earned fixed purchases and production remain available.
- Double-tap summon/Fuse, disconnect during saving, reconnect, and inspect a
  backed-up QA key. There must be one complete operation or no operation, never
  partial parents/payment or a success notification before durable confirmation.
- Select five exact Legacy/new IDs, lock or assign one before confirming; server
  must reject changed inputs. Repeat stale preview and previously committed intent.
- Load V1/V2 QA fixtures with jobs/cargo; compare all old IDs/stats/paidOrigin,
  assignments/tutorial and offline results after repeated joins. Never reset a
  rejected future/malformed key or send full private profiles to clients/logs.
- Play from empty clearing through Healing/NPC/Rage and fixed Fuse under a
  restricted account, without admin grants. Record observed timings separately.
- Fill collection to 128 and inspect paging/search/sort/caps. Run 2–8 clients;
  verify own-plot authorization, respawn/leave cleanup and bounded deployed proxies.
  Measure FPS, replication, tick and commit latency; no performance pass is claimed.

## M1 implementation record — 2026-11-04

Scope: [Issue #4](https://github.com/branch-danya-dev/magicpotiongacha/issues/4).
Branch `feat/m1-production-onboarding`, based on the actual
[PR #3](https://github.com/branch-danya-dev/magicpotiongacha/pull/3) HEAD
`a72ef9ecd61ed2e29b9c686174e057a3e94e1603`. PR #3 is still Draft/unmerged, so the
M1 Draft targets `fix/m0-1-acceptance`. Do not bypass that dependency or close
Issue #2's manual gates. Overall live acceptance is **BLOCKED**.

| Requirement / check | Actual status | Reproducible evidence / limit |
| --- | --- | --- |
| Essence source → machine tank; manual → pipes | **PASS (portable)** | `m1.spec`: no reservoir debit at brew, explicit refill, tank capacity/conservation, rotating scarce supply; `factory.spec`: paid batch consumes once. |
| Liquid intermediates versus solid/crate carriers | **PASS (portable)** | `m1.spec`: no new fluid hauls; `factory.spec`: actual manually discovered Fire Extract → Rage and hired workers; two-machine two-hour equivalence. |
| Queued / travelling / delivered crates | **PASS (portable)** | `m1.spec`: disjoint accounting, capped pickup, slower replacement worker, partial delivery, full queue, saved cargo, recipe switch, expiry boundary and repeated claim. |
| No loss/duplication across mixed transitions | **PASS (portable)** | 500 deterministic production/order/assignment/expiry transitions check produced = sold + claimed + reserved after every transition. |
| Complete onboarding with no injected resources | **PASS (portable)** | `Scenarios.luau`: manual, early automation, 100-Gold spending detour; every tutorial fact and 5-Healing order completed, followed by 600 autonomous seconds. See `M1_BALANCE.md`. |
| Tutorial persistence / out-of-order completion | **PASS (fake backend)** | Every recorded milestone plus an in-progress first manual brew survives save/release/reload; facts, pets and complete profile compare exactly. |
| Two-hour cap, repeat join and chain equivalence | **PASS (portable/fake backend)** | Both Healing and Fire Extract → Rage chains match one-second online state over 7200 seconds. A 10800-second absence consumes the skipped tail; immediate rejoin grants nothing. |
| V1 → V2 profile migration | **PASS (fake backend)** | Captured V1 fixture, prepaid brew, old fluid cargo, historical quest stock, callback replay, lost reply, competing lease, invalid/future schema and broken migrator cases. |
| Schemas, rates, ownership/range, stale purchases | **PASS (portable only)** | Original Protocol/lease regression suites; new forged Essence/cargo/time/tutorial payloads, foreign pet, rate limits, pure Access checks and `expectedLevel` purchase replay. Engine authorization still S1. |
| Previous regression coverage | **PASS** | All 154 tests retained. Adaptations: V2 schema assertion, exact `buy.expectedLevel`, early pipes/refill in fixtures, quota assertion now checks source queue, claim scenario performs actual hauling first. No test removed. |
| Local compile / analysis / build | **PASS** | Windows x64, Node 24.22.1: **203/203 tests**, all **20 Luau sources** compiled, portable analysis and Rojo build/sourcemap passed. `build/verification.log` records the source SHA and results. |
| Windows + Ubuntu CI on final source | **Recorded in Draft PR** | The PR gives exact SHA, run/job links and final PASS/FAIL. Checkout explicitly uses PR head SHA; each artifact contains `verification.log`, place and sourcemap. Local results are not claimed as Ubuntu execution. |
| Work/status/crate UI and portrait/landscape layout | **BLOCKED — S1/M1** | Engine scripts compile; no Studio/device session was run. Verify 44px controls, horizontal tabs, closed-menu movement/camera, guided focus, server status text and crate route visuals. |
| Real DataStore migration / lease / offline saves | **BLOCKED — D1** | No isolated private QA backend session; fake backend does not establish platform behavior. |
| 2–8 clients, respawn/reconnect, performance | **BLOCKED — S1/P1** | No live multi-client run, mobile device or measured FPS/tick/replication data. |

Local validation uses `node scripts/setup-tools.mjs` and `node scripts/check.mjs`,
the exact package-script entry points, because this workstation has no npm.
CI runs the documented `npm run tools` and `npm test` on both OSes. Tool archives
and CI actions retain their SHA pins. No external analytics, marketplace code,
M2 mechanics, public Roblox publication or merge into main is included.

### Additional M1 live steps (all BLOCKED pending S1/D1/M1/P1)

- New QA profile: follow the saved guide from zero resources through manual Healing,
  ordinary sale, pipes, passive crystal, automatic Healing and delivered NPC order.
- Save/respawn/reconnect during first manual brew and with partially delivered cargo;
  compare progress, single workplace assignments, stocks and diagnostic events.
- Remove the carrier while carrying crates, replace with a weaker worker, fill
  storage, switch the active recipe and cross the order deadline while disconnected.
- Confirm real prompts and forged remotes from a second player's plot cannot refill,
  buy, assign or claim on someone else's behalf; repeat a stale purchase payload.
- Run portrait and landscape on emulator and real phone; inspect text wrapping,
  scrolling, touch targets, closed-menu joystick/camera, toast and offline report.
- Exercise V1 migration in a backed-up QA key, repeat join and simulate normal
  lease contention; record the build SHA, Studio version, QA namespace and logs.
- Measure eight clients, server tick/catch-up cost, FPS and replication. Close the
  existing Issue #2 gates only after actual observations; CLI does not close them.

## M0.1 execution record — 2026-11-04

Scope: [Issue #2](https://github.com/branch-danya-dev/magicpotiongacha/issues/2),
based on PR #1 at `4a6292aa76ce758d4a0f666c9f02756f90821cf3`.
Fix branch: `fix/m0-1-acceptance`. Overall acceptance: **BLOCKED**.
The owner confirmed that Studio and an isolated private QA experience are not
available. No live test below was executed. PR #1 must remain Draft and unmerged.

| Check | Actual status | Evidence / missing prerequisite |
| --- | --- | --- |
| Windows tool installation | **PASS after fix** | Luau 0.745 / Rojo 7.7.1 archives passed the existing SHA-256 checks; installation and cached reinstallation succeeded. |
| Compile, portable analysis, domain regression tests | **PASS** | Windows x64 / Node 24.22.1: 154 tests passed, 0 failed; all 15 Luau sources compiled; portable analysis passed. |
| Rojo build and sourcemap | **PASS** | `build/PotionTycoon.rbxlx` and `build/sourcemap.json` generated successfully. This is not a Studio launch. |
| First-player production in the portable model | **PASS** | `tests/acceptance.spec.luau`: zero starting resources, negative Studio identity, real Protocol intents, first manual Healing, worker assignments, earned crystal upgrade and 600 seconds of autonomous production. No currency or ingredients injected. |
| Two-hour cap and immediate second login in the fake backend | **PASS** | Same suite: save/release, 10,800-second absence, exactly 7,200 seconds processed and 3,600 skipped, save/release/reload, zero repeated reward and unchanged complete profile. |
| Baseline CI | **PASS (baseline only)** | [Run 41886239421](https://github.com/branch-danya-dev/magicpotiongacha/actions/runs/41886239421): Windows and Ubuntu passed for the original PR. |
| Final fix CI | **PASS** | [Fix PR #3](https://github.com/branch-danya-dev/magicpotiongacha/pull/3) records the final source SHA and Windows/Ubuntu push-run evidence: 154 tests, 15 compiled Luau sources, analysis and Rojo build on each OS. |
| All Studio greybox checks below | **BLOCKED — S1** | Roblox Studio unavailable. No Output log, 2-client run, prompt interaction or engine authorization evidence. |
| All real save/catch-up checks below | **BLOCKED — D1** | No isolated private QA experience, QA namespace or real DataStore session. Fake-backend tests are separate evidence only. |
| Emulator and real-phone interaction | **BLOCKED — M1** | Studio emulator and a connected phone test session unavailable. |
| Eight clients, reconnect/respawn and performance | **BLOCKED — P1** | No live clients or server session. FPS, frametime, memory, server tick, replication and live catch-up duration were not measured. |

### Defects and verification limits

- **M01-01 / P2 / fixed, locally verified:** `node scripts/setup-tools.mjs`
  failed on Windows when `Expand-Archive` could not import its PowerShell script
  module under Restricted execution policy. Use the Windows 10/11 built-in
  `tar.exe` to unpack the already hash-verified ZIP, with direct argument passing.
  No execution-policy change or dependency installation is required.
- **M01-02 / P2 / code fix, live verification BLOCKED (S1):** the old pad
  `Touched` handler accepted another purchase after three seconds, even without
  a deliberate new purchase. Multiple body-part contacts could therefore buy
  successive levels while moving on a pad. Static callback inspection found
  this risk; it was not reproduced in Studio. Pads now require an explicit
  half-second purchase prompt (F / gamepad / touch); walking onto a pad alone
  does not spend Gold. The existing owner, range, rate and affordability checks
  still apply. Existing domain tests verify one level per accepted purchase and
  no charge when unaffordable. Physical prompt behavior still needs S1.

Local commands were the exact package-script entry points,
`node scripts/setup-tools.mjs` and `node scripts/check.mjs`, because npm is absent
from this workstation. CI must also run the documented `npm run tools` and
`npm test` entry points. No production namespace, saved profile, API setting or
Roblox publication was modified. No Studio/mobile screenshots are claimed.

Before completing M0.1, record Studio version, tested source SHA, private QA
experience/namespace, device details, observed results and performance logs.
Resolve S1/D1/M1/P1 and verify M01-02 in the engine. There is no basis yet to
declare the live first-cycle/persistence/authorization P1/P2 gate satisfied.

## Studio greybox (memory mode)

**Status for every unchecked item in this section: BLOCKED (S1).**

- [ ] Open the generated place; Output has no script errors.
- [ ] HUD clearly says Studio progress is not persisted after Stop.
- [ ] Start Server with 2 clients: separate plots and separate balances (negative Studio UserIds supported).
- [ ] Walk onto own upgrade pad: no automatic spend. Activate the purchase prompt once: exactly one upgrade; insufficient Gold does not build anything. Continued contact without another activation must not buy again.
- [ ] Visit another plot: all economic interactions are refused; public worker visuals remain visible.
- [ ] Click crystal; collect Mandrake; manually load and brew Healing; exactly one sale credited.
- [ ] Enable automation only after first successful manual recipe, with a brewer assigned.
- [ ] Assign/unassign workers: no simultaneous workplace assignment, original versus capped skill visible.
- [ ] Upgrade crystal; run autonomous Healing with farmer, carrier and brewer.
- [ ] Earn Gold, hire extra workers, unlock mine/distillery/Rage and complete the two-stage production chain.
- [ ] Full raw storage does not prevent a loaded ordinary potion from exporting.
- [ ] Discard requires confirmation; cannot discard quest stock through the ingredient control.
- [ ] Carrier with cargo pauses when removed and resumes without duplication when assigned again.
- [ ] Complete and claim a contract; repeated claim does not award twice; extras export.
- [ ] Test expiration of a contract and ordinary sale of its reserved output.
- [ ] Pipes move liquid intermediates but do not bypass solid transport.

## Real save / catch-up (isolated private QA experience)

**Status for every unchecked item in this section: BLOCKED (D1).**

- [ ] Set Studio memory mode false only in a separately published QA experience.
- [ ] Leave/rejoin: balances, workers, jobs, cargo, inputs and recipe discoveries survive.
- [ ] Offline production matches configured sources/transport/recipes; no duplicate gold for reserved potions.
- [ ] Rejoin repeatedly/open the welcome UI: no duplicate catch-up and no new slime rolls for the same interval.
- [ ] Test a gap longer than two hours; excess time is not collectable by another reconnect.
- [ ] Rapid reconnect/server change cannot run two writable sessions for the same profile.
- [ ] API access disabled or backend error: no writable fresh fallback and no overwrite of real data.
- [ ] Server shutdown saves active profiles; interrupted/unconfirmed saves fail closed and eventually recover from the last valid record.
- [ ] Future/malformed schema in a disposable QA key is rejected; it is not reset automatically.

## Mobile and scale

**Status for every unchecked item in this section: BLOCKED (M1/P1).**

- [ ] Device emulator at narrow portrait and landscape sizes: text readable, buttons reachable, scrolling works.
- [ ] Real phone: joystick/camera remain usable when the factory menu is closed.
- [ ] Station → assign → choose worker works with touch; a closed menu does not intercept input.
- [ ] Eight-client max-load scenario: measure frame time, server step time, replication, memory and catch-up duration.
- [ ] Repeated respawns and join/leave cycles do not duplicate UI, plots or familiar visual instances.

**Public release remains blocked** until real-backend, mobile and multiplayer acceptance is recorded. Paid purchases/trading also require their own later security and policy gates.
