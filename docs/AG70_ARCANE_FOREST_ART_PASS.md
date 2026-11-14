# AG-70 — Arcane Forest 2.1, gated review candidate

**Status: GATED / BLOCKED ON AG-69. CODE CANDIDATE; partial Studio diagnostics only.
OWNER ART ACCEPTED: NO. PUBLISHED: NO.**

Issue: [#41](https://github.com/branch-danya-dev/magicpotiongacha/issues/41).
This is a saved experiment, not the final AG-70 result. The AG-69 dependency does
not currently meet the zero-native-asset-error gate; the remaining art work and
acceptance checks are stopped pending that repair.

## Exact source and dependency

- Branch: `feat/ag70-arcane-forest-art-pass`.
- Stacked base: Draft PR #42, `feat/ag69-m7-asset-restore`,
  `df5f3ee7f582764718390957d7234633bd6747e5`.
- Base Windows/Ubuntu CI: PASS,
  [run 43515825649](https://github.com/branch-danya-dev/magicpotiongacha/actions/runs/43515825649).
- AG-00 `7d6d47826e919683ee991c911185215cda0d3d2e` is in the dependency ancestry.
- Runtime and test revision used for the latest ordinary F5:
  `0f73e3003fe5342711be651c169c1747b467ed84`.
- `build/AG70-Review.rbxlx` is byte-identical to the ordinary Rojo
  `build/PotionTycoon.rbxlx`; SHA-256
  `6935adaed0615f199bbfc3084ccb7034447a4aa3a2210deb7d91f1fe8d10962b`.
- Evidence/report commits after that revision do not alter the runtime. The PR's
  HEAD and checks identify the final source delivery; the manifest identifies
  the actual captured build independently.

## Blocking defect: Image preload success is not Sky success

All twelve AG-69 Image probes report `Success`, with
`M7_19E_ASSETS failures=0 complete=true`. However, ordinary F5 also reports:

- Sky Sun texture `rbxassetid://127279777775296` fails to load.
- Sky Moon texture `rbxassetid://120296233207649` fails to load.
- `No asset content representation found while do_not_fallback_to_baseline is set to true.`

The same native errors exist in the saved AG-69 Studio session. See
[current errors](evidence/ag70/sky-consumer-errors.log) and
[AG-69 baseline errors](evidence/ag70/ag69-sky-consumer-errors.log).
The cause is not established: the error does not itself prove that the group
grant is missing. Image-probe success must not be presented as proof of the
actual Sky consumer, sun/moon appearance, or the complete AG-69 gate.

No IDs, grants, privacy settings, upload, or sky textures were changed by AG-70.
Resume after AG-69 verifies the native Sky consumer in a fresh build and in the
intended private Experience. If different IDs, reuploads, or permissions are
needed, those belong to the AG-69 scope and its owner authorization. Re-run the
visual matrix afterward; current captures cannot establish final art acceptance.

## Candidate implementation

`ArcaneForest.luau` is a pure projection of the existing continuous environment
sample. `EnvironmentView` remains the sole owner of Lighting, Atmosphere,
ColorCorrection, Bloom, SunRays and its existing local light pools. There are no
new instances, render connections, remotes, assets or persisted fields.

Studio default is the documented review name `AG70`; published default remains
`OFF`. `look:OFF`, `look:A/B/C`, `look:AG68` and `look:AG70` use the existing local
Studio bridge. `EnvironmentArtEnabled` is not forced. OFF and legacy rendering
code are preserved outside named, verified AG-70 insertions.

The existing first canopy light is repositioned toward the pilot lectern/path
only while AG70 is active, with its original position restored for other looks.
Existing lamps are warmer, while the canopy pool provides a restrained cold
night focus. Their shadow flags, ranges, pool sizes and culling remain inherited.
No Spellbook material, mesh, rune, award/VFX code or interaction was changed.

### Palette anchors (interpolated, not fixed world states)

RGB values are 0–255. Weather and the existing continuous day weights blend the
anchors, so measured screenshots need not equal an anchor numerically.

| Parameter | Day | Sunset | Night | Dawn |
| --- | --- | --- | --- | --- |
| Brightness / exposure | 2.7 / -0.12 | 3 / 0.06 | 1.8 / 0.02 | 2.5 / 0.06 |
| Ambient | 37,69,92 | 66,78,108 | 43,61,95 | 61,87,100 |
| OutdoorAmbient | 97,133,157 | 124,137,172 | 85,112,160 | 130,155,162 |
| ColorCorrection tint | 233,248,255 | 255,247,237 | 237,244,255 | 255,246,248 |
| Contrast / saturation | 0.19 / 0.02 | 0.11 / 0.025 | 0.09 / 0.015 | 0.12 / 0.045 |
| Atmosphere color | 135,196,214 | 243,187,164 | 78,102,157 | 224,189,204 |
| Atmosphere decay | 83,111,151 | 77,95,151 | 39,58,106 | 99,135,162 |
| Density / haze / glare | 0.30 / 1.5 / 0.16 | 0.32 / 1.8 / 0.24 | 0.34 / 1.85 / 0.01 | 0.31 / 1.6 / 0.12 |
| EnvironmentDiffuseScale | 0.25 | 0.18 | 0.10 | 0.23 |

Rain progressively cools light, reduces contrast and direct brightness, adds
bounded haze, and preserves a lower night fill than day. After-rain reduces
haze/density. Density stays between 0.25 and 0.35; haze stays below 2.2 before the
inherited quality multiplier. Specular is bounded at 0.045–0.11. No material swap,
global Reflectance, global Blur/DoF or runtime texture churn is introduced.

| Budget | Full | Reduced | Minimal |
| --- | --- | --- | --- |
| Existing active environment lights | ≤6 | ≤3 | 0 |
| Bloom intensity cap | 0.10 | 0.045 | 0 |
| SunRays intensity cap | 0.025 | 0.008 | 0 |
| Bloom threshold / size | 1.9 / 20 | 1.9 / 20 | disabled |

Night disables rays. Reduce Motion keeps the same color composition and uses the
existing motion suppression. Minimal also scales contrast by 0.72. No expensive
LightingStyle is forced by runtime. Native Soft/Realistic toggles appear only in
the optional, unmapped QA script.

## Native evidence and observations

Studio `0.747.0.7471481`, ordinary full-game F5 in the Rojo build, local
`GameId=0/PlaceId=0`. The production HUD, starter choice and purchase outlines
remain visible. No mock renderer, generated image, retouching or hidden HUD.
Raw capture/video hashes and paired camera metadata are in
[manifest.json](evidence/ag70/manifest.json).

Three native iterations were saved:

1. `14a68aee7890477a4a274b8839ef70101adf7723`: night too dark for clothing and
   forest detail; day highlights too green/white. Four native states and hashes
   in [iteration1.json](evidence/ag70/iteration1.json).
2. `955b7c15bfa6e7b7b2f327e77d31856343b77285`: improved night fill/local book
   focus, but day still too similar to OFF. See
   [iteration2.json](evidence/ag70/iteration2.json).
3. Captured runtime `0f73e3003fe5342711be651c169c1747b467ed84`: cooler day
   shadows and lower exposure/fill; warmer local lamps with cool night depth.
   This remains an experiment behind the AG-69 gate, not an accepted final look.

The 32 captures use day 13.2, sunset 17.65, night 22.5 and the inherited rain
preset. FOV 65; fixed near/wide cameras; Full/Reduced; Reduce Motion true to
stabilize moving vegetation. The manifest checks identical CFrame/FOV/viewport
for each OFF/candidate pair. Separate motion-enabled rain/after-rain captures
and Minimal/reverse/graphics5 views are retained alongside them.

| State / tier | Near OFF | Near AG70 | Wide OFF | Wide AG70 |
| --- | --- | --- | --- | --- |
| Day Full | [OFF](evidence/ag70/day-full-near-OFF.jpg) | [AG70](evidence/ag70/day-full-near-AG70.jpg) | [OFF](evidence/ag70/day-full-wide-OFF.jpg) | [AG70](evidence/ag70/day-full-wide-AG70.jpg) |
| Day Reduced | [OFF](evidence/ag70/day-reduced-near-OFF.jpg) | [AG70](evidence/ag70/day-reduced-near-AG70.jpg) | [OFF](evidence/ag70/day-reduced-wide-OFF.jpg) | [AG70](evidence/ag70/day-reduced-wide-AG70.jpg) |
| Sunset Full | [OFF](evidence/ag70/sunset-full-near-OFF.jpg) | [AG70](evidence/ag70/sunset-full-near-AG70.jpg) | [OFF](evidence/ag70/sunset-full-wide-OFF.jpg) | [AG70](evidence/ag70/sunset-full-wide-AG70.jpg) |
| Sunset Reduced | [OFF](evidence/ag70/sunset-reduced-near-OFF.jpg) | [AG70](evidence/ag70/sunset-reduced-near-AG70.jpg) | [OFF](evidence/ag70/sunset-reduced-wide-OFF.jpg) | [AG70](evidence/ag70/sunset-reduced-wide-AG70.jpg) |
| Night Full | [OFF](evidence/ag70/night-full-near-OFF.jpg) | [AG70](evidence/ag70/night-full-near-AG70.jpg) | [OFF](evidence/ag70/night-full-wide-OFF.jpg) | [AG70](evidence/ag70/night-full-wide-AG70.jpg) |
| Night Reduced | [OFF](evidence/ag70/night-reduced-near-OFF.jpg) | [AG70](evidence/ag70/night-reduced-near-AG70.jpg) | [OFF](evidence/ag70/night-reduced-wide-OFF.jpg) | [AG70](evidence/ag70/night-reduced-wide-AG70.jpg) |
| Rain Full | [OFF](evidence/ag70/rain-full-near-OFF.jpg) | [AG70](evidence/ag70/rain-full-near-AG70.jpg) | [OFF](evidence/ag70/rain-full-wide-OFF.jpg) | [AG70](evidence/ag70/rain-full-wide-AG70.jpg) |
| Rain Reduced | [OFF](evidence/ag70/rain-reduced-near-OFF.jpg) | [AG70](evidence/ag70/rain-reduced-near-AG70.jpg) | [OFF](evidence/ag70/rain-reduced-wide-OFF.jpg) | [AG70](evidence/ag70/rain-reduced-wide-AG70.jpg) |

[Unedited native OFF → AG70 → OFF video](evidence/ag70/native-off-ag70-off.mp4).
The raw clip is 34.616 seconds, including a 21-second switch sequence and
untrimmed recording padding. Native recording began before the existing local review switch; timing markers
are in the filtered session log. The switch changes only the look, with fixed
camera/time/weather. A smooth day→night walking recording is **NOT RUN**.

### Unresolved visual defects

- **P0 dependency:** native Sky Sun/Moon failure above. Current sky comparisons
  are diagnostic, not evidence of restored AG-69 art.
- **Graphics5:** triangular/stippled path patches and coarser vegetation are
  visible under Realistic, and path patches also exist in
  [OFF](evidence/ag70/graphics5-day-OFF.jpg). The root cause is not proven.
  [Soft](evidence/ag70/graphics5-soft-day.jpg) and
  [Realistic](evidence/ag70/graphics5-realistic-day.jpg) are included. Geometry,
  materials and global engine style were not changed to conceal the defect.
- **Sunset:** the hill occludes the direct key at 17.65 in the main views.
  Cooler shadow separation improves, but the desired strong directional amber
  foreground is not established. The reverse view exposes this limitation.
- **Night:** warm pools and the cold book focus are distinguishable, but dark
  avatar clothing can merge into the ground between sources, especially Reduced.
  The owner must judge legibility; no blind visual test or art PASS is claimed.
- **Inherited UX:** the large starter-familiar panel occludes the left side;
  bright yellow boundaries and temporary station geometry remain. AG-70 does
  not hide or redesign these.

## Verification and remaining gates

The [native session](evidence/ag70/native-session.log) is filtered to project QA
records; [structured records](evidence/ag70/native-records.json) include actual
properties, light counts and book counters. Unrelated host telemetry is omitted.

| Check | Result / scope |
| --- | --- |
| Ordinary full-game F5 | RUN; candidate visible, gameplay running; asset-error gate FAIL |
| 80 OFF/candidate switches | PASS in four 20-switch batches: day/Reduced/motion, sunset/Full/motion, night/Minimal/reduced motion, rain/Reduced/reduced motion |
| OFF numeric restoration | PASS in those batches for sampled Lighting/Atmosphere/PostFX/Clouds/light properties, tolerance 1e-6 |
| Effect accumulation | PASS in those batches: same Lighting/Terrain instances; workspace and Spellbook counts stable |
| Full/Reduced/Minimal × motion × six looks | 36 native states PASS selection/status; old OFF/A/B/C/AG68 retained |
| E and actual mouse prompt | PASS: server state 0 → 5 → 10 Essence; +5 each; native screenshot retained |
| Eight plots | PASS structural native check: one real Spellbook per plot; not eight active clients |
| Spellbook | Existing effects and interaction visible; counters report zero errors during checked batches; no changes to source |
| Every weather × tier × motion switch combination | NOT RUN; 80 switches do not imply the full Cartesian matrix |
| Controller Stop/Restart, original pool position | NOT RUN natively; optional QA script is supplied, not claimed as evidence |
| Forced Spellbook fallback regression | NOT RUN in AG-70; inherited tests retained |
| Phone landscape emulation / day→night walk | NOT RUN; stopped on AG-69 dependency |
| Real low/mid-range phones | NOT RUN: no physical device session/thermal measurements |
| 2–8 clients / published private-server backend | NOT RUN; local F5 is not that gate |
| OWNER ART ACCEPTED | OPEN; only owner can accept, after AG-69 restoration |
| Merge / publication / paid action | NOT PERFORMED |

Local verification: `npm run tools`, then `npm test`: 1292 Luau tests
(1281 inherited + 11 AG70), 13 Node tests, pinned Luau/Rojo build. New tests
cover continuous state/weather projection, night/day fill, tier caps/fades,
bounded local lights, published OFF, and non-mutating repeated switches.
Preservation guards compare inherited gameplay, assets, UI, Spellbook and tests
against the exact base; EnvironmentView differs only at bounded AG70 seams.
Two existing C01 lint warnings remain; they are not new AG70 errors.
Exact final CI results belong to the Draft PR's Windows/Ubuntu checks.

### Desktop measurements

RTX 5070 Ti, Windows Studio, ordinary full game, graphics5 Realistic, fixed near
day camera, Reduce Motion false. OFF/AG70/AG70/OFF, five seconds per run after
three seconds settling, repeated for Full/Reduced/Minimal. No recording or
screenshot capture during measurements. Other stopped Studio windows remain
open; these are short desktop diagnostics, not mobile estimates or a proof of
long-session stability. Raw per-run CPU/GPU/frame/memory/draw/light data:
[performance.json](evidence/ag70/performance.json).

Arithmetic means of the two per-run medians (ms except draw calls and MB):

| Tier / look | Frame | CPU render | GPU render | Draw calls | Memory MB | Lights |
| --- | --- | --- | --- | --- | --- | --- |
| Full OFF | 4.109 | 2.993 | 0.978 | 371.0 | 3137.730 | 6 |
| Full AG70 | 4.093 | 3.042 | 1.047 | 370.5 | 3137.809 | 6 |
| Reduced OFF | 4.100 | 2.921 | 0.920 | 339.5 | 3137.969 | 3 |
| Reduced AG70 | 4.081 | 2.904 | 1.023 | 339.0 | 3138.000 | 3 |
| Minimal OFF | 4.112 | 2.746 | 0.789 | 304.0 | 3138.957 | 0 |
| Minimal AG70 | 4.087 | 2.780 | 0.884 | 304.0 | 3138.080 | 0 |

Frame time is effectively unchanged in this short desktop sample. GPU render
time increased by roughly 0.07–0.10 ms. This is not a phone performance claim;
the measurements include the inherited scene and its asset-loading defects.

## Reproduction after the gate is repaired

1. Check out the feature branch; run `npm run tools`, `npm test` and
   `node scripts/check-integration-base.mjs`.
2. Open `build/PotionTycoon.rbxlx` in Studio; use ordinary Play (F5).
3. In the **client** Command Bar, install `qa/ag70-command-bar.luau`, then the
   optional capture/check script. QA files are excluded from the Rojo runtime.
   They use the actual owner bridges; they do not require a second controller.
4. `workspace.PotionTycoonWorld:SetAttribute("EnvironmentReview", "look:OFF")`
   or `"look:AG70"` selects the look; the same attribute accepts `day`, `sunset`,
   `night`, `rain`, `afterrain`. Quality/motion use the existing client settings.
5. Repeat native Sky checks first, then complete the missing gates above and
   obtain owner feedback. Do not proceed to UI or claim publication readiness.

Roblox references used for the implementation:
[Lighting](https://create.roblox.com/docs/reference/engine/classes/Lighting),
[environment lighting](https://create.roblox.com/docs/environment/lighting),
[Atmosphere](https://create.roblox.com/docs/environment/atmosphere),
[local lights](https://create.roblox.com/docs/effects/light-sources).
