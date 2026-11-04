# Manual acceptance checklist

CLI/CI passing is necessary but does not mark any item below as completed.

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
| Final fix CI | **PENDING at report commit** | Record the exact final source SHA and the Windows/Ubuntu push-run results in the linked fix PR. A baseline result does not satisfy this gate. |
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
