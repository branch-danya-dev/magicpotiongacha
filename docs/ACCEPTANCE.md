# Manual acceptance checklist

CLI/CI passing is necessary but does not mark any item below as completed.

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
