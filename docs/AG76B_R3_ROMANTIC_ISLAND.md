# AG-76B-R3 — Romantic Dark Fairytale / Forgotten Sanctuary

**CODE CANDIDATE / STUDIO VERIFIED (bounded checks below) / OWNER ART PENDING.**
Separate, reproducible Studio-only composition. Not integrated or published.

## Base, references and scope

- Base: Draft PR #56, `feat/ag76b-r2-wizard-island-poc` at
  `34e28910c739f66ff2b6b0543c4fe628966e9ee3`; verified open/draft and CI green.
- Feature: `feat/ag76b-r3-romantic-island-layout`. Delivery HEAD is the commit
  containing this report; the PR records its full SHA and exact-head CI result.
- The owner's two Library downloads were accessible. The separate concept PNG
  exactly matches the PNG in the ZIP. Original PNG, SVG and brief are preserved
  under [references/ag76r3](references/ag76r3), with SHA-256 provenance. The builder
  rejects changed reference bytes. These are direction references, not Play proof.
- No `src/`, `assets/`, `default.project.json`, economy, Factory, Config, DataStore,
  profile schema, production feature flag or gameplay anchor was changed.
- Production `EnvironmentView` is reused unchanged as the only Lighting owner;
  QA configuration/style modules are mapped only into this separate place.
- No Meshy job, credits, new Roblox upload, permission grant or paid asset.

## Composition and protected space

The 124×116 walkable island, original R2 continuous cliff, spawn `(0,20)` and book
`(0,-2)` are retained. Eighteen varied peripheral trees replace the R2 interior
placements. The large tree is at `(47,-29)`, the ruin proxy at `(-47,-28)` and the
waterfall inlet at `(55,11)`, all relative to `PersonalIsland.origin`.

The temporary ancient tree combines the existing twisted trunk with a lowered,
widened green crown. The arch is a native stone-block proxy with uneven piers,
open seams, rubble and ferns. Both are explicitly marked `QAProxy`; neither is a
finished bespoke model. Low planted margins, stone outcrops and four lanterns
frame the open construction clearing. Native beams and pooled droplets create
the first waterfall pass using the already admitted mist texture.

`Layout.audit` checks conservative rotated bark bounds, the arch footprint and
lantern clearance against all 13 station offsets, 26 input/output waypoints, the
future buildable rectangle and the six-stud spawn-to-book corridor. Minimum
structural station clearance is **9.33 studs**. It rejects the reported R2 tree at
`(20,12)` near cauldron2. Decorative crowns can overhang above the clearing; all
decorations are non-colliding. Invisible QA markers preserve the 13 station/26
endpoint coordinates; **this scene does not run the production factory**.

## Lighting and quality

| State | Engine clock | Ambient RGB | Outdoor RGB | Exposure | Atmosphere density |
| --- | ---: | --- | --- | ---: | ---: |
| Dusk target | 18.55 | 141,154,192 | 157,171,206 | 0.22 | 0.23 |
| Night target | 0 | 147,166,192 | 162,182,211 | 0.38 | 0.12 |

These are input keys, before the inherited continuous state/style projection.
Day is retained. The existing sky textures are unchanged. Dusk now has an indigo
upper sky and violet transition; it is deliberately later than the brown early
sunset observed in the first local iteration. Minimal retains readable terrain,
landmarks, book and static waterfall without local lights or particle motion.

| Waterfall | Full | Reduced | Minimal | Reduce Motion |
| --- | ---: | ---: | ---: | ---: |
| Enabled beams | 3 | 1 | 1 | Tier's static beams |
| Particle rate / second | 18 | 7 | 0 | 0 |
| Added local lights | 0 | 0 | 0 | 0 |

Particles have bounded lifetimes (≤3 seconds), reuse four emitters, clear when
quality/motion changes, and are destroyed with the review script. Twenty quality
changes retained exactly **16 waterfall descendants**, without accumulation.
Full + Reduce Motion produced 0 wind slots, 0 motes and 0 waterfall particle rate.

## Native Play verification

Studio **0.747.0.7471481**, ordinary F5 client/server Play of the standalone place.
Native Q6 viewport 1566×1095. All admitted scene assets preloaded successfully;
the existing environment reported 0 asset failures. No scene script errors were
found in the final session's CreatorOutput. An unrelated installed Rojo plugin
was trying to connect to its absent local server; this QA place uses a disk build.

The standard Humanoid walked, without teleporting, through `(0,2)`, `(-20,2)`,
`(-30,-20)`, `(0,-30)`, `(28,-12)`, `(20,16)` and back to `(0,20)`. All seven
MoveTo endpoints succeeded, health stayed 100, and minimum root Y was 3.709.
This tests normal character physics and the clearing/routes; it is not an
exhaustive edge/fall-recovery or controller/device acceptance test.

Original native PNGs, saved by Studio's screenshot command, without crops,
retouching, external renders or generated substitutions:

1. [Spawn — dusk / Full](evidence/ag76r3/01-spawn-dusk.png)
2. [Whole island — dusk / Full](evidence/ag76r3/02-island-overview.png)
3. [Altar — dusk / Full](evidence/ag76r3/03-altar-dusk.png)
4. [Side — tree, arch and waterfall](evidence/ag76r3/04-tree-arch-side.png)
5. [Spawn — day / Full](evidence/ag76r3/05-spawn-day.png)
6. [Spawn — night / Minimal](evidence/ag76r3/06-night-minimal.png)

The matched spawn camera is a reproducible QA camera at `(0,8,32)`, looking at
`(0,6,-8)`, FOV 82. Overview/altar/side use explicit review cameras. Movement was
checked separately with the normal Custom/Humanoid camera. The camera metadata,
PNG hashes and exact artifact/source hashes are in the [manifest](evidence/ag76r3/manifest.json).

After tests finished, three 15-second RenderStepped samples were taken at the same
spawn camera/night, in the foreground Studio viewport:

| Quality | FPS | Median frame interval | p95 interval |
| --- | ---: | ---: | ---: |
| Full | 233.19 | 4.16 ms | 5.48 ms |
| Reduced | 235.36 | 4.13 ms | 5.37 ms |
| Minimal | 229.49 | 4.24 ms | 5.55 ms |

These are desktop frame intervals near the FPS cap, **not GPU timings**, a
benchmark improvement claim or phone evidence. The three samples differ within
ordinary run noise. Full/Reduced/Minimal settled at 4/3/0 environment lantern
lights (plus the separately bounded altar light in Full/Reduced), 12/4/0 wind
slots and 16/6/0 visible motes. Native source observations are in
[studio-observations.log](evidence/ag76r3/studio-observations.log).

## Build and automated checks

`npm run tools` PASS; `npm test` PASS: **1,365 Luau + 14 Node tests**, 275 Luau
sources compiled, analysis and Rojo verification passed. Five new regression
tests exercise valid placement and deliberately invalid station, construction,
route and off-island layouts. Two pre-existing analyzer warnings in C01 tests
remain unchanged. CI runs the new suite/builder on Windows and Ubuntu, and uploads
the separate R3 artifact and receipt. Exact-head CI is recorded on the Draft PR.

```text
npm run tools
npm test
node scripts/build-romantic-island.mjs
```

Open `build/WizardIsland-AG76B-R3-Romantic-ART-PENDING.rbxlx`, then F5. The receipt
is `build/romantic-island-build.json`; the build hash in the evidence manifest is
the one captured in Play. The builder verifies protected files against the exact
R2 base and the existing CC0 nature receipt. It never uploads or publishes.

Keys: 1 spawn, 2 overview, 3 altar, 4 normal movement, 8 side; 5 day, 6 dusk,
7 night; Q quality; R Reduce Motion; H QA footer; P 15-second timing sample.
Client Command Bar can invoke `workspace.PotionTycoonWorld.WizardReviewControl`
with `("walk")` to repeat the seven-point physics route.

## Open artistic/technical gates

- **OWNER ART PENDING:** the screenshots are a composition candidate, not a claim
  of matching the concept's finished asset detail. In particular, the tree/arch
  proxies, sparse understory, stone-block silhouette and simple ribbon waterfall
  still need the owner's artistic assessment before any next asset pass.
- Real smartphones, touch/gamepad input, multiplayer load and production factory
  integration are NOT RUN. Published EditableMesh availability is not established.
- No integration, merge, Roblox publication or new asset upload. Stop here for
  the owner's visual decision.
