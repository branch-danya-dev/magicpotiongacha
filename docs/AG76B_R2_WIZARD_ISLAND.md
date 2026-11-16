# AG-76B-R2 — Wizard Island, local art candidate

This is the preserved first candidate and its original evidence. The owner's
requested follow-up is in [AG76B_R2_ART_POLISH.md](AG76B_R2_ART_POLISH.md).

Status: **IMPLEMENTED/CODE + STUDIO VERIFIED (bounded checks below), ART PENDING,
NOT INTEGRATED, NOT PUBLISHED**. This is a review candidate, not a claim that the
owner has accepted Stylized Realism / Dark Fairytale quality.

## Base and isolation

- Branch: `feat/ag76b-r2-wizard-island-poc`.
- PR #55 was verified open/draft at `f21137e26478b83afd47625f48b2ffe9b717600d`.
  Its CI run [43882273636](https://github.com/branch-danya-dev/magicpotiongacha/actions/runs/43882273636)
  succeeded. This does **not** establish CI for R2.
- Local R1 base: `913231369629f8663e66dc9e18fecccc15d0ee68`.
  The original `b0af9f9` object is absent. Its previously verified mail patch is
  present as `2d04fd5`; the R1 validation follow-up is `9132313`.
- No changes to `src/`, `assets/`, `default.project.json`, profiles, economy,
  production stations, original gameplay coordinates or production feature flags.
- The art place contains no `Main` game bootstrap, gameplay remotes or persistence.
  Both entry scripts assert `RunService:IsStudio()`. It is an ordinary F5 **art
  scene**, not evidence that a full production session was retested.
- Current exact source HEAD and artifact digest are written to
  `build/wizard-island-build.json`; captured artifact/source hashes are also in
  [the evidence manifest](evidence/ag76r2/manifest.json).

## Reproduce and review

From the repository root:

```powershell
npm run tools
npm test
node scripts/build-wizard-island.mjs
```

Open `build/WizardIsland-AG76B-R2-ART-PENDING.rbxlx` in the existing Studio window
and press F5. It needs no owner-ID edit or access to a live save. The generated
Rojo project resolves tracked source files; there are no manual model imports
that disappear on rebuilding.

Keys: **1** spawn, **2** island overview, **3** altar, **4** ordinary character
camera; **5** day, **6** dusk, **7** night; **Q** Full/Reduced/Minimal, **R** Reduce
Motion, **H** QA caption, **P** 15-second frame interval sample. Lighting changes
continue through the unchanged `EnvironmentView` and its transition mechanism.
No second Lighting writer was added. The QA configuration substitutes only in
this separate place.

Camera positions are relative to the existing island origin `(-142.5, 0, -65)`:

| Camera | Position | Target | FOV |
| --- | --- | --- | --- |
| Spawn | 0, 8, 32 | 0, 5, -6 | 62 |
| Island | 120, 66, 140 | 0, -16, -8 | 47 |
| Altar | 13, 7.8, 12 | -1, 4.3, -4 | 52 |

## Scene construction and sources

The organic/scalloped rim and tapering underbody use imported rock MeshParts.
A thin native Terrain skin supplies grass/soil/rock material transitions without
stretching tiny mesh textures over the entire island. Native Slate covers the
large cliff meshes. This is **not** a custom sculpted cliff asset or a new PBR
texture set. Bark retains the pack's existing normal maps. No blanket reflection
or transparent grass-material substitution was used.

The scene has 20 trees with five silhouettes, clustered shrubs/ferns/clover,
stone paths, a small ruined arch, four lanterns and the existing lectern.
There are 266 MeshParts: 110,244 nature triangles plus 4,194 lectern triangles.
Primitive geometry is limited to the invisible collision/spawn helpers and
small lantern components; it does not build the visible island mass.
The lectern retains the existing crystal X/Z and 6.5-stud normalized height.
Terrain height was calibrated using Studio raycasts after the initial density
origin produced a surface two studs too high.
Imported foliage/path models retain their source base pivot rather than their
bounding-box center; the final Play check confirms full tree trunks above ground.

Sources already admitted to this project, with no new download/upload:

| Asset | Provenance / license / receipt |
| --- | --- |
| Quaternius nature subset | [Stylized Nature MegaKit Standard](https://quaternius.itch.io/stylized-nature-megakit), CC0; `assets/environment/megakit/License_Standard.txt`, `prepared/`, and both megakit/woodland receipts |
| Native imported nature template | `assets/environment/woodland/M7NatureTemplates.rbxmx`; SHA-256 `803ae25b3aacb215699f378dad60451e2fb1e025ac1fc40df7f8e6435735f5f5` |
| Spellbook Lectern | Existing Shuriken provenance/license in `assets/props/spellbook-lectern.manifest.json`; used inside this place, not redistributed as a standalone store model |
| Native lectern template | `assets/props/SpellbookLectern.rbxmx`; SHA-256 `c541c02e6d91099a3297de9919f2d3f52bca8a183f277af4f0dcf17a38ba59a2` |
| Sky, celestial/mist/star textures | Existing AG69 images and IDs through `EnvironmentAssets`; no replacement uploads or expanded permissions |

The nature receipt and template hashes are checked by the builder. Original
GLTF/BIN/textures and import receipts remain unchanged. The optional game-dev CLI
and Blender were unavailable locally; this candidate only reuses the already
owner-admitted subset and requires neither a new asset package nor paid generation.
Successful loads in this account's local Play do not close release-wide asset
permission verification.

## Lighting and local effects

Main dusk pose uses phase .30 / clock 17.2; night uses phase .51 / clock 0.
The QA config preserves the continuous EnvironmentState/EnvironmentView pipeline.
Night ambient was raised after observing insufficient Minimal readability.
Ground mist sprites are disabled in the QA config; Atmosphere provides light haze,
and three bounded client particle emitters provide the cloud bank below the island.

Clouds: 3 emitters, 30-second lifetime, Full .2 particles/s each, Reduced .1,
Minimal zero continuous rate; initial burst 5/5/2 per emitter. Reduce Motion
clears and suppresses these particles. Book motes: one emitter, 2/s, max 3-second
lifetime, disabled on Minimal/Reduce Motion. No request or reward events are used.

The inherited view has at most 6/3/0 active lights. This isolated art candidate
adds **one** shadowless altar light on Full/Reduced (total cap 7/4/0), an explicit
one-light increase for review, not a change to production budgets. The extra
emitter is likewise outside the inherited view's reported particle counts.

## Real Studio evidence

PNG files below are the native Studio **View → Screenshot** output during ordinary
F5 Play. No external renderer, image generation, retouching or color grading was
applied. All requested main captures use Full and the same Studio Q6 setting,
viewport 1566 × 1095. Exact original filenames and hashes are in the manifest.

| Image | Purpose |
| --- | --- |
| [01-spawn-dusk.png](evidence/ag76r2/01-spawn-dusk.png) | Spawn, character scale and central route |
| [02-island-dusk.png](evidence/ag76r2/02-island-dusk.png) | Floating silhouette / terrain and underbody |
| [03-altar-dusk.png](evidence/ag76r2/03-altar-dusk.png) | Lectern, stone ring, plants and shrine |
| [04-spawn-night.png](evidence/ag76r2/04-spawn-night.png) | Night at the exact spawn camera |
| [05-spawn-day.png](evidence/ag76r2/05-spawn-day.png) | Day at the exact spawn camera |

Observed: ordinary Play spawns a character, scene builds, and preloading reports
`ok=true, failed=[]`. All 12 EnvironmentView texture deliveries report success.
Full/Reduced/Minimal change effect budgets. Reduce Motion suppresses wind/motes
and altar/cloud emission. Lighting contains one each of the owned M7 Atmosphere,
Sky, ColorCorrection, Bloom and SunRays effects. No production scene was opened
or overwritten during these art checks; only one Studio window was used.

## Preliminary performance and tests

Desktop: NVIDIA RTX 5070 Ti (Studio log), Studio 0.747.0.7471481, Q6,
1566 × 1095. Three stable 15-second samples, spawn camera, dusk, no camera movement:

| Tier | Mean FPS | p50 frame interval | p95 frame interval | Client memory |
| --- | ---: | ---: | ---: | ---: |
| Full | 239.25 | 4.069 ms | 5.132 ms | 3416 MiB |
| Reduced | 239.50 | 4.089 ms | 5.073 ms | 3414 MiB |
| Minimal | 239.97 | 4.078 ms | 5.079 ms | 3414 MiB |

These are RenderStepped intervals, **not GPU timings**, and include Studio/client
overhead in memory. They are near the desktop frame cap, so they cannot establish
relative GPU cost or mobile suitability. The final benchmark and all delivered
captures use the same artifact SHA-256 recorded in the evidence manifest.

- `npm run tools`: Luau 0.745 and Rojo 7.7.1 SHA-256 verified.
- `npm test`: 1,360 Luau tests + 14 Node tests pass; 265 Luau sources compiled,
  standard place/review builds and preservation checks pass. Existing analyzer
  warnings remain; the command exits 0.
- Final QA Luau files compiled separately after the last placement edits; these
  QA-only edits followed the full regression run and were verified in native Play.
- Art builder and repeat build: identical output digest.
- Exact R2 Windows/Ubuntu CI: **NOT RUN** (local feature branch, no push/PR update).
  PR55's green CI belongs to its original head only.

## Open gates / known limits

- **Owner art review is still required.** Do not integrate this scene or label the
  task accepted based on tests or successful screenshots.
- The old approved concept image was not present in the inspected local material;
  composition follows the current written brief. Exact reference matching is open.
- Reused rock silhouettes remain visibly faceted and repetitive on the overview;
  the source foliage/lectern retain a stronger stylized appearance than realistic
  bespoke assets. The underside/cloud shape, tree placement at the rim, moss detail
  and overall Dark Fairytale direction need owner review and likely another art pass.
- Minimal removes local light contribution and is visibly darker than Full;
  the path/avatar remain visible, but its night readability needs owner review.
- The walk proxy is deliberately simple. Final edge navigation, collisions and
  placement against production construction zones were not accepted or integrated.
- Phone performance, multi-client load, real backend, publication/experience asset
  permissions and full-game integration are **NOT RUN / BLOCKED until their gates**.
- No merge, game publication, Roblox upload, permission grant or paid generation.

Rollback is removing the separate QA files/build; production source is unchanged.
