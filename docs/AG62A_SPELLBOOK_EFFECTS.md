# AG-62A — Spellbook idle and confirmed Essence feedback

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
Full ≤24, Reduced ≤8 including the global burst bucket and idle populations.
Quality changes clear existing particles; no catch-up emission after a long frame.

The single update scope is marked `AG62A Spellbook effects` for MicroProfiler.
`require(PlayerScripts.PotionTycoon.SpellbookEffects).current.stats()` exposes
local counts and observed scheduler CPU duration for native diagnostics. These
are desktop measurements, not phone FPS or GPU/draw-call evidence.

## Verification and delivery status

Implementation candidate; native QA and exact-head CI evidence will be recorded
before delivery. Existing 1155 tests are retained. New portable cases cover
receipts, real click economy, movement bounds, quality and particle limits,
duplicate attach, capacity, fallback, reappearance, engine fault and shutdown.
The scope guard also compares gameplay/permission/save/asset files to the fixed
base and rejects new remotes. Normal build: `npm run tools`, `npm test`, then
`node scripts/check-integration-base.mjs` from a clean committed checkout.
Open `build/PotionTycoon.rbxlx` and use F5, not a presentation-only scene.

Native mouse/upgrade, owner visual approval, touch/phone, second account, 2–8 real
players, backend and low-device performance are separate gates. No false PASS
from portable tests or server-intent diagnostics. Missing local M7 sky textures
remain outside scope. No merge, publication, Store listing, spending or activation
of monetization/trading is authorized by this work.

Runtime references checked 2026-11-12: [ParticleEmitter](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter)
for Emit/Clear and lifetime budgeting; [RunService](https://create.roblox.com/docs/reference/engine/classes/RunService)
for the shared scheduler; [debug](https://create.roblox.com/docs/reference/engine/libraries/debug)
for the native profiling marker.
