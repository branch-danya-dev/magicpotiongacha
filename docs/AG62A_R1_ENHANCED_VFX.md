# AG-62A-R1 — enhanced ambient and interaction VFX

Owner-requested revision in existing Draft PR #33. Base HEAD verified remotely:
`f1882ad0ffc7a5e4803dc13f75d752ba01df229a`, CI 43227213157 Windows/Ubuntu PASS.
Branch remains `feat/ag62a-spellbook-idle-vfx`; stacked base remains AG01 PR #30.
**Implementation candidate / native QA pending / owner art gate OPEN.**

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

Pending native Play and final exact-HEAD evidence. Initial AG62A results are kept
in `AG62A_SPELLBOOK_EFFECTS.md`, not reused as proof for this revision.
Portable regressions exercise trajectories/dissolve, batch coalescing and expiry,
quality/Reduce Motion, partial allocation failure, owner removal and recovery.
The scope guard pins the R1 server Main/receipt and all Environment/Weather/Lighting
sources byte-for-byte (line endings normalized) to the R1 base. Existing economic,
permissions, hitbox, imported-asset, save and release-flag checks remain active.

Owner art acceptance remains OPEN. Phone/touch, real 2–8 players, low-device GPU
performance and private backend/permissions are separate NOT RUN gates. Existing
missing local M7 sky/celestial textures remain out of scope; AG-63 is untouched.
No merge, publication, paid assets, trading or monetization activation.

Runtime reference checked 2026-11-12:
[PointLight](https://create.roblox.com/docs/reference/engine/classes/PointLight),
[ParticleEmitter](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter).
