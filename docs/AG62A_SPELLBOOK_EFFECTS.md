# AG-62A — Spellbook idle and confirmed Essence feedback

This is the **initial AG-62A delivery record**. The owner requested stronger VFX
after viewing it; current R1 behavior/budgets and validation are recorded in
[AG62A_R1_ENHANCED_VFX.md](AG62A_R1_ENHANCED_VFX.md). Historical measurements below
apply to the original runtime, not the revised particle/light/paper budgets.

Issue #31. Stacked branch `feat/ag62a-spellbook-idle-vfx` on PR #30,
`feat/ag01-spellbook-reproducible` @ `341b7f6dd9ac1692781f865bf25fed63a05e9d8a`.
That exact base passed Windows/Ubuntu CI 43201487244. This task is only the bounded
Spellbook slice of AG-62; AG-60, full AG-62 and AG-01 owner gates remain open.

## Contract and implementation

Only AG01-ready models in Workspace acquire client effects. The existing load
gate owns reveal/fallback and calls effect attach/detach. One Heartbeat scheduler
updates up to eight records, prioritizing the local owner's book and nearby books.
No server-side VFX, transforms, emitters, new remotes or dependencies on Lighting.
Fallback/removal restores exact captured poses/colors, clears and destroys the
record's emitters. Script teardown disconnects both shared effect connections and
the visual tag listeners. Cosmetic update faults remove only that effect record;
the static book and gameplay continue. Re-attachment is idempotent.

The real imported hierarchy contains `FloatingRunes` (one merged rune mesh) and
`LoosePages` (three material meshes belonging to the same loose-page geometry).
All material pieces move together around the measured group bounding center,
not the importer's default model pivot. The open book, lectern, floor ring,
candles and logical anchor keep their original transforms. There is no skeleton:
**true page turning/bending is not implemented** and requires different geometry.

- Runes: at most 0.10 stud vertical offset and ±3° yaw, slow sine waves.
- Loose pages: 0.035 stud lift and 1.5° roll for four seconds every eighteen seconds.
- Source-emissive surfaces: 90–100% of original color, no added light. Candle flame:
  93–100% color, no size flicker. Material properties and global exposure unchanged.
- Confirmed click: one bounded 0.65-second color response (12% toward white) and
  a small particle burst; Reduce Motion uses a 0.9-second color response only.
- Particle sprite: Roblox's bundled `rbxasset://textures/particles/sparkles_main.dds`;
  no upload, download or third-party asset. Existing EnergyPoint/ParticlePoint only.

## Confirmed feedback, no balance inference

Existing State snapshots previously had no receipt that distinguished a manual
click from passive income. Main now adds `presentation.essenceClick` with a
session-only sequence and assigned plot index. The sequence advances only after
the existing action/range/rate/profile checks and successful Factory action and
validation. It is not stored in the profile and changes no reward or permission.
Native E and existing click UI share this same server action path.

The first snapshot seeds the client cursor; duplicate/stale receipts are ignored.
Every later receipt is consumed even if the model is unavailable, culled, wrong
owner or fallback, so it cannot replay when the book appears. Passive currency
changes and failed clicks do not advance the sequence. Only a ready, nearby,
owned book responds. Overlapping successes reuse one pulse; particle bursts have
a global token cap. Lost/intermediate snapshots are coalesced rather than replayed.

## Exact quality budgets

| Mode | Update Hz | Active books / radius | Idle particles/s/book | Burst / global refill |
| --- | ---: | --- | ---: | --- |
| Full | 30 | 3 / 100 studs | 0.6 | 6 / 12 particles/s |
| Reduced (default) | 20 | 2 / 72 studs | 0.2 | 3 / 4 particles/s |
| Minimal | 10 | 1 / 28 studs | 0 | 0 |
| Any + Reduce Motion | same mode cap | same radius | 0 | 0 |

All eight books remain visible at every quality. Minimal/Reduce Motion restore
original poses and steady colors and destroy particle objects; only confirmed
color feedback remains. Each visited active book owns at most two reused emitters
(idle + burst): at most 16 allocated across eight records, at most 3/2 idle emitters
enabled in Full/Reduced, zero lights. Culled emitters are disabled and cleared.
Idle lifetime ≤2 s, burst lifetime ≤0.9 s, particle size ≤0.12 stud, speed ≤1.8
stud/s, no acceleration, 18° spread, drag 0.8. Conservative live particle bound:
Full ≤26, Reduced ≤10 including the global burst bucket and idle populations.
Quality changes clear existing particles; no catch-up emission after a long frame.

The single update scope is marked `AG62A Spellbook effects` for MicroProfiler.
`PlayerScripts.PotionTycoon.SpellbookEffects.Inspect:Invoke()` exposes local counts,
actual quality/motion settings and observed scheduler CPU duration in Studio only.
This read-only local BindableFunction bridges Studio's separate Command Bar module
cache; it cannot change settings, emit feedback or send an economic intent. These
are desktop measurements, not phone FPS or GPU/draw-call evidence.

## Verification and delivery status

**IMPLEMENTED / scoped STUDIO VERIFIED / OWNER GATE OPEN.** Stacked Draft
[PR #33](https://github.com/branch-danya-dev/magicpotiongacha/pull/33); no merge or
publication. Existing 1155 tests are retained and all 18 new tests pass: **1173
total, zero failures**. All 180 Luau sources compile/analyze; both Rojo places,
sourcemaps, AG01 asset checks and ancestry/repeat-build checks pass. Two inherited
C01 lint warnings remain. New portable cases cover
receipts, real click economy, movement bounds, quality and particle limits,
duplicate attach, capacity, fallback, reappearance, engine fault and shutdown.
The scope guard also compares gameplay/permission/save/asset files to the fixed
base and rejects new remotes. Normal build: `npm run tools`, `npm test`, then
`node scripts/check-integration-base.mjs` from a clean committed checkout.
Open `build/PotionTycoon.rbxlx` and use F5, not a presentation-only scene.

The tested runtime commit is `4c5a0968647d12a71a71a4c9988d87eae5bedf1a`, with
[Windows/Ubuntu CI PASS](https://github.com/branch-danya-dev/magicpotiongacha/actions/runs/43224835155).
Final delivery adds only this report/evidence; the ordinary place is byte-identical.
Final exact HEAD and its CI run are recorded in PR #33 to avoid a self-referential
commit hash. Clean checkout and repeat build produced ordinary-place SHA-256:
`2ba416825b7a1a0590b7f7da4eb7fc4611c92012322b34a67c4e407e6b0c5887`.

### Native Studio session, 2026-11-12

Studio 0.747.0.7471481, Windows desktop, ordinary F5 Play from the default Rojo
project (`AG62A-review.rbxlx`, same bytes as `PotionTycoon.rbxlx`). Local
STUDIO_MEMORY, not a published experience/backend test. The inherited
`UIFoundationDemo` attribute was set false **only in the running client** to expose
the real gameplay HUD. No source flag, profile, clock, currency or permission was
overridden. Play was stopped without saving or publishing. No screenshots/video
deliverables, as requested by the owner.

| Check | Actual result |
| --- | --- |
| Physical keyboard E | At 13:15:25 UTC: Essence 0→5, receipt 0→1, feedback 0→1. |
| Native PC mouse, HUD button | At 13:15:46: Essence 5→10, receipt 1→2, feedback 1→2. |
| Native PC mouse, Roblox E prompt | At 13:22:30: receipt 11→12, feedback 10→11. Level 2 passive income was also running; balance delta alone was not used as evidence. |
| Native upgrade button | At 13:20:50: level 1→2, Gold 900→0, receipt stayed 11, feedback stayed 10. Preparation used ordinary validated intents and walking through two Healing sales; the final upgrade was a physical mouse click. No administrative grants. |
| Idle geometry | 200 samples over ~22 s: all 19 static mesh transforms unchanged. Runes and three loose-page pieces moved. Observed rune peak displacement from the initial animated sample 0.1845 stud; page pieces 0.0349/0.0340/0.0100 stud (not displacement from rest). |
| Eight plots | Each book ready, all 23 meshes visible, one active book at each nearby camera. All 8 anchors + 152 static mesh transforms unchanged during tour. Other plots have no second live player. |
| Full / Reduced | Changed using real settings buttons; running-controller probe confirmed the chosen modes, motion/color variation and 2 emitters on the nearby book. Rates/caps are in the table above. |
| Minimal / Reduced + Reduce Motion | Real settings buttons; zero emitters, zero moving meshes, zero changing colors in idle two-second samples. All eight records retained. Reduce Motion combinations for other qualities additionally covered by portable policy tests. |
| Forced fallback | Removed the AG01 tag in the live client: working crystal restored, book hidden, its emitters destroyed, registry 8→7. Physical E gave another 5 Essence (receipt 2→3), feedback stayed 2. |
| Reappearance | Tag restored: ready, registry 8, no replay of fallback receipt. Five further remove/re-add cycles kept 8 records and zero errors. |
| Particle cleanup | After visiting all plots: 16 pooled emitters, only 1 enabled. Removing own book destroyed its 2 emitters (14 retained, 0 enabled); reappearance returned to 16/1, no duplicate allocation. |
| Failed/rate-limited intents | An out-of-range click at the altar left receipt 3 and feedback 2 unchanged. A 30-request same-frame burst near the crystal accepted 8, produced exactly 8 feedback counts, and no feedback for the 22 rejected requests. These are server-intent diagnostics, not native-input claims. |
| Passive Essence | After level 2, balance rose repeatedly while receipt 11 and feedback 10 stayed unchanged until the next native click. |
| Server isolation | Server Command Bar found 8 book models, no client effect attributes, and 0 Spellbook emitters/Inspect objects in Workspace or ServerStorage. |

The filtered native Output evidence is
[`evidence/AG62A_STUDIO_2026-11-12.log`](evidence/AG62A_STUDIO_2026-11-12.log).
Only task measurements are retained, not the user's full Studio log. Reproduce
with default Play: approach own book, press E, use the HUD collect/upgrade buttons,
switch Quality settings, inspect the read-only probe, then remove/re-add the
`SpellbookLecternVisual` tag on a live client model. Do not change the shared asset.

Observed scheduler cost after the eight-plot tour: **0.101 ms average, 0.413 ms
maximum across 10,559 updates**, zero cosmetic faults; this includes mixed quality
modes and at most one simultaneously nearby book in this map. It measures the
Lua scheduler only, not renderer/GPU cost or full-game FPS. Full-cap concurrent
visibility, frame-time traces and phones require separate performance acceptance.

The first candidate's unsupported Color3 multiplication was found in real Play
and replaced with Color3:Lerp in `b74d1c6`; the final runtime had no AG62A errors.
The command-bar module cache was separately diagnosed, so all final quality/CPU
measurements use the read-only bridge into the actual running controller.

### Remaining gates / limitations

- Owner review of materials, glow strength and idle feel remains **OPEN**. This
  work does not close AG01 acceptance or the full AG62/AG60 gates.
- Phone/touch, second account, 2–8 real clients, low-end-device/GPU performance,
  real DataStore/rejoin and private-experience permission validation: **NOT RUN**.
  They require the relevant devices/accounts/private QA environment; no new upload
  or permission change was needed for this local run.
- True bending/page-turn animation needs a rig or different mesh and is absent.
- Existing missing local M7 sky/celestial/weather textures remain unresolved and
  outside scope. Existing generic HUD balance toasts still appear for passive
  income; the new book reward VFX correctly ignores it.
- No merge, publication, Store listing, purchases, monetization or trade activation.

Runtime references checked 2026-11-12: [ParticleEmitter](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter)
for Emit/Clear and lifetime budgeting; [RunService](https://create.roblox.com/docs/reference/engine/classes/RunService)
for the shared scheduler; [debug](https://create.roblox.com/docs/reference/engine/libraries/debug)
for the native profiling marker.
