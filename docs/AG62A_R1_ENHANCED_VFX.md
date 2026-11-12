# AG-62A-R1 — enhanced ambient and interaction VFX

Owner-requested revision in existing Draft PR #33. Base HEAD verified remotely:
`f1882ad0ffc7a5e4803dc13f75d752ba01df229a`, CI 43227213157 Windows/Ubuntu PASS.
Branch remains `feat/ag62a-spellbook-idle-vfx`; stacked base remains AG01 PR #30.
**IMPLEMENTED / scoped STUDIO VERIFIED / owner art gate OPEN.**

## Presentation

- Floating runes use a locally applied blue-violet Neon material/tint. Original
  material/color is captured and restored on fallback, cull and removal. Existing
  rune and original loose-page movement is unchanged. No original mesh is edited.
- Rising Essence sparks are larger and more frequent. A low-opacity blue-violet
  smoke aura surrounds the book. Both sprites are built into Roblox, verified in
  the installed content directory: `sparkles_main.dds` and `smoke_main.dds`.
  No asset download, generation, upload or license/permission change.
- At most **one** client-local PointLight, on the nearby owned book's existing
  EnergyPoint. Range 8, no shadows, brightness Full 0.65 / Reduced 0.45, with
  at most +0.35 on a successful click. No global Lighting/Environment changes.
- The unchanged server receipt starts a 1.1-second rune whitening pulse (65%
  toward white) and 5 / 3 new paper Parts in Full / Reduced. Papers are thin
  0.45 × 0.025 × 0.65 stud cream-blue rectangles, client-only, anchored,
  non-collidable, non-touchable, non-queryable and shadowless. No source geometry
  is cloned, moved or replaced by them. They spiral up from EnergyPoint, radius
  ≤1.2 studs and rise ≤2 studs, then fade completely by 1.25 / 1.1 seconds.
- One client-wide paper batch, maximum 5 sheets. Rapid accepted receipts keep
  the existing glow/particle feedback but **coalesce papers while a batch lives**;
  they never restart its lifetime or queue later bursts. No delayed false reward.
- Minimal: steady readable rune tint, no particles/papers/light. Reduce Motion:
  no moving pages/runes, aura/particles or sheets; steady glow/local light and a
  smooth 1.2-second confirmed color response. Full/Reduced geometry remains visible.

## Exact revised budgets

| Setting | Full | Reduced | Minimal | Any + Reduce Motion |
| --- | ---: | ---: | ---: | --- |
| Shared update rate | 30 Hz | 20 Hz | 10 Hz | same quality |
| Active books / radius | 3 / 100 | 2 / 72 | 1 / 28 | same quality |
| Idle sparks/s/book | 3 | 1.2 | 0 | 0 |
| Aura sprites/s/book | 0.75 | 0.4 | 0 | 0 |
| Click sparks / global refill | 6 / 12 per s | 3 / 4 per s | 0 | 0 |
| Paper Parts, client-wide | 5 | 3 | 0 | 0 |
| Local lights, client-wide | 1 | 1 | 0 | same quality, steady idle |

Three pooled emitters per visited book, ≤24 retained across eight books (previous
AG62A: 16); ≤6/4 continuously enabled emitters Full/Reduced. Idle spark lifetime
≤2.4 s, click spark lifetime ≤0.9 s; spark size ≤0.26 stud, speed ≤1.8 stud/s,
upward acceleration 0.25 stud/s² and drag 0.4. Aura lifetime ≤2 s, size ≤3.4
studs, speed ≤0.08 stud/s; opacity peaks at 18%. Conservative live particle bounds
including the shared burst bucket: Full ≤46 / Reduced ≤14 (previously ≤26/10).
At most 5 extra paper draw objects and 1 shadowless local light.

The same shared Heartbeat updates papers; no per-paper connections, tasks, tweens,
physics or remotes. Record fallback/removal/cull cancels its paper batch and light,
restores mesh presentation, disables and clears particles; fallback/removal also
destroys all owned emitters. **Every** quality/motion change destroys previous
emitters, papers and light before applying the new budget. Shutdown disconnects
the shared listeners and clears all objects. A failed paper setup/flight cleans
all partial allocations, leaving the book and economic interaction intact.

`SpellbookEffects.Inspect:Invoke()` in running client Studio reports actual quality,
live sheets, paper bursts/peak, light count, emitter count and scheduler CPU.
This is read-only, Studio-only; no synthetic reward or setting setter.

## Validation status

Runtime commit: `bbe1cb2aa0472d06d2779870fdf54acd6a2637a6`. Initial AG62A results
are kept in `AG62A_SPELLBOOK_EFFECTS.md`, not reused as proof for this revision.
R1 adds eight portable cases: **1181 PASS, zero failures** (1142 main + 13 AG01
+ 26 AG62A/R1). All 1173 inherited cases remain. Pinned tools, 181 Luau sources,
both place builds/sourcemaps, asset/scope guards and clean repeat build PASS.
Two inherited C01 lint warnings remain. Runtime candidate Windows/Ubuntu CI:
[43230936507](https://github.com/branch-danya-dev/magicpotiongacha/actions/runs/43230936507), PASS.
The final documentation/evidence commit and its exact CI are linked in PR #33;
documentation-only changes must produce identical ordinary-place bytes.

Native Studio **0.747.0.7471481**, 2026-11-12, ordinary F5 Play / STUDIO_MEMORY:

- Opened `build/AG62A-R1-review.rbxlx`, not the environment-only preview.
  SHA-256 `4c9c3329cf755cd2d4b3cc60e888de9bb146ccbfaa3a1b17c9c2a884fe5cac0d`;
  identical to the clean runtime-commit `build/PotionTycoon.rbxlx`.
- Default Reduced, ordinary avatar camera: glowing runes and successful-click
  paper response visible. E: Essence 0→5, receipt/feedback/batch 0→1, 3 sheets;
  native mouse on Roblox prompt: 5→10, each counter +1. Sheets zero after expiry.
  Full diagnostic accepted click: 5 sheets at 0.4 s, zero after expiry.
- Actual in-game quality buttons selected Full, Minimal and Reduce Motion.
  Minimal: zero sheets/emitters/lights during accepted +5 and after it.
  Full + Reduce Motion: zero sheets/emitters, one local light; accepted +5 still
  increments feedback, without allocating a paper batch. Original idle movement
  is disabled by the shared policy. Existing source flags were not changed.
- 30 same-frame gameplay intents: 8 accepted receipts (+40 Essence), exactly
  8 feedback increments; only one new paper batch, peak 5, 6 emitted click sparks.
  No delayed paper replay; sheets zero at 1.7 s. Rejections add no feedback.
- Native fallback forced by removing the owner's visual tag 0.3 s into a burst:
  5 sheets → 0; emitters/light → 0; no owned transient descendants remain.
  A further ordinary intent gives +5 with no hidden-book feedback. Re-adding
  the tag restores `ready` without replaying that receipt or creating sheets.
- Diagnostic camera tour of all eight plots (one actual player): every book
  `ready`, ≤3 active books, ≤6 enabled / 24 retained emitters, ≤1 local light.
  Returning to Minimal destroyed all 24 pooled emitters and the light.
  Server Workspace/ServerStorage: **zero VFX objects**, eight source visuals.
- Zero cosmetic faults. Observed scheduler CPU through final quality check:
  average **0.130 ms**, max **0.967 ms**, 10,047 updates. Mixed desktop modes and
  camera tour; this is not phone/GPU/full-game performance evidence.

Only the live client's inherited `UIFoundationDemo` overlay was disabled to
expose the actual gameplay HUD. Navigation used ordinary Humanoid walking;
stress/fallback probes used existing validated intents and local presentation
changes. No admin grants or persistent changes. Play stopped without saving or
publishing. Filtered Output: `evidence/AG62A_R1_STUDIO_2026-11-12.log`.
No screenshot/video deliverables were produced, per owner preference.

Portable regressions exercise trajectories/dissolve, batch coalescing and expiry,
quality/Reduce Motion, partial allocation failure, owner removal and recovery.
The scope guard pins the R1 server Main/receipt and all Environment/Weather/Lighting
sources byte-for-byte (line endings normalized) to the R1 base. Existing economic,
permissions, hitbox, imported-asset, save and release-flag checks remain active.

Owner art acceptance remains OPEN: the blue-violet rune tint appears pale under
the inherited exposure/bloom; final color, aura contrast and paper styling need
the owner's in-game review. Global lighting is deliberately unchanged. Exact
in-flight quality-switch timing and source-object deletion were exercised through
portable lifecycle/burst tests, not separately timed native Play scenarios.
Phone/touch, real 2–8 players, low-device GPU
performance and private backend/permissions are separate NOT RUN gates. Existing
missing local M7 sky/celestial textures remain out of scope; AG-63 is untouched.
No merge, publication, paid assets, trading or monetization activation.

Runtime reference checked 2026-11-12:
[PointLight](https://create.roblox.com/docs/reference/engine/classes/PointLight),
[ParticleEmitter](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter).
