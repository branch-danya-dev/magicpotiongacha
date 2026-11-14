# AG-70 — Arcane Forest 2.1, repaired-base review

**CODE candidate / scoped STUDIO VERIFIED; OWNER ART ACCEPTED: NO; PUBLISHED: NO.**

Issue [#41](https://github.com/branch-danya-dev/magicpotiongacha/issues/41), stacked Draft [PR #43](https://github.com/branch-danya-dev/magicpotiongacha/pull/43). The AG69 Sun/Moon consumer blocker is repaired; this report supersedes the previous gated review. Art acceptance remains with the owner.

## Exact source and dependency

- Branch: `feat/ag70-arcane-forest-art-pass`.
- Base: AG69 Draft PR #42 `6467bfd9b024dbf618496ca2901f5b6cac20abb1`; Windows/Ubuntu [43590430411](https://github.com/branch-danya-dev/magicpotiongacha/actions/runs/43590430411) PASS. AG00 ancestry retained; never based on main.
- Captured runtime: `89804f0ea070b3b685a9939b00872fa0b5fe2b55`, palette `2.1-iteration4`; Windows/Ubuntu [43591968246](https://github.com/branch-danya-dev/magicpotiongacha/actions/runs/43591968246) PASS.
- Ordinary build/review copy `build/AG70-R2-Review.rbxlx`: SHA256 `6b70cfe5c65e71127c4f2fd1215c49ff4dc360495d8e44cf29f6db45692236b5`. Later evidence/report commits do not alter runtime. Final delivery HEAD and exact-HEAD checks are in PR #43.
- [AG69 repair](AG69_CELESTIAL_REPAIR.md): unsupported native Sky KTX requests replaced by the existing owned celestial Image consumer. Same 12 source files, IDs and Restricted grants. No upload or permission changes. Fresh R2 F5 reports all twelve preloads successful and no Sun/Moon errors.

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
| Brightness / exposure | 2.7 / -0.12 | 3 / 0.10 | 1.8 / 0.02 | 2.5 / 0.06 |
| Ambient | 37,69,92 | 90,78,108 | 43,61,95 | 61,87,100 |
| OutdoorAmbient | 97,133,157 | 150,140,166 | 85,112,160 | 130,155,162 |
| ColorCorrection tint | 233,248,255 | 255,236,226 | 237,244,255 | 255,246,248 |
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

## Native evidence after the celestial repair

Studio 0.747.0.7471481, ordinary full-game F5, local GameId/PlaceId 0. Production HUD and starter panel remain visible. Captures are direct Studio window captures, without retouching or generated imagery.

Two post-repair iterations:

1. [R1 manifest](evidence/ag70/r1/manifest.json): runtime a609e1253c272f8f67ae12c321607802c9aedf87, iteration3, 12 matched day/sunset captures. The low sun is occluded by the pilot ridge; foreground warmth remained weak.
2. [R2 manifest](evidence/ag70/r2/manifest.json): runtime 89804f0ea070b3b685a9939b00872fa0b5fe2b55, iteration4. Raised warm sunset fill and existing local lamps without increasing light count or altering geometry. Final 32-image OFF/AG70 matrix plus additional quality/reverse/weather checks.

Older evidence directly in evidence/ag70 (without r1/r2) is HISTORICAL, before the celestial repair; it is not final verification.

The R2 matrix uses day 13.2, sunset 17.65, night 22.5 and the existing rain preset; FOV65, fixed near/wide cameras, Full/Reduced, Reduce Motion true. Camera, time, weather and viewport are recorded. Avatar/Spellbook idle remains live, so pairs are comparable rather than pixel-identical.

| State/tier | Near OFF | Near AG70 | Wide OFF | Wide AG70 |
| --- | --- | --- | --- | --- |
| day full | [near-OFF](evidence/ag70/r2/day-full-near-OFF.jpg) | [near-AG70](evidence/ag70/r2/day-full-near-AG70.jpg) | [wide-OFF](evidence/ag70/r2/day-full-wide-OFF.jpg) | [wide-AG70](evidence/ag70/r2/day-full-wide-AG70.jpg) |
| day reduced | [near-OFF](evidence/ag70/r2/day-reduced-near-OFF.jpg) | [near-AG70](evidence/ag70/r2/day-reduced-near-AG70.jpg) | [wide-OFF](evidence/ag70/r2/day-reduced-wide-OFF.jpg) | [wide-AG70](evidence/ag70/r2/day-reduced-wide-AG70.jpg) |
| sunset full | [near-OFF](evidence/ag70/r2/sunset-full-near-OFF.jpg) | [near-AG70](evidence/ag70/r2/sunset-full-near-AG70.jpg) | [wide-OFF](evidence/ag70/r2/sunset-full-wide-OFF.jpg) | [wide-AG70](evidence/ag70/r2/sunset-full-wide-AG70.jpg) |
| sunset reduced | [near-OFF](evidence/ag70/r2/sunset-reduced-near-OFF.jpg) | [near-AG70](evidence/ag70/r2/sunset-reduced-near-AG70.jpg) | [wide-OFF](evidence/ag70/r2/sunset-reduced-wide-OFF.jpg) | [wide-AG70](evidence/ag70/r2/sunset-reduced-wide-AG70.jpg) |
| night full | [near-OFF](evidence/ag70/r2/night-full-near-OFF.jpg) | [near-AG70](evidence/ag70/r2/night-full-near-AG70.jpg) | [wide-OFF](evidence/ag70/r2/night-full-wide-OFF.jpg) | [wide-AG70](evidence/ag70/r2/night-full-wide-AG70.jpg) |
| night reduced | [near-OFF](evidence/ag70/r2/night-reduced-near-OFF.jpg) | [near-AG70](evidence/ag70/r2/night-reduced-near-AG70.jpg) | [wide-OFF](evidence/ag70/r2/night-reduced-wide-OFF.jpg) | [wide-AG70](evidence/ag70/r2/night-reduced-wide-AG70.jpg) |
| rain full | [near-OFF](evidence/ag70/r2/rain-full-near-OFF.jpg) | [near-AG70](evidence/ag70/r2/rain-full-near-AG70.jpg) | [wide-OFF](evidence/ag70/r2/rain-full-wide-OFF.jpg) | [wide-AG70](evidence/ag70/r2/rain-full-wide-AG70.jpg) |
| rain reduced | [near-OFF](evidence/ag70/r2/rain-reduced-near-OFF.jpg) | [near-AG70](evidence/ag70/r2/rain-reduced-near-AG70.jpg) | [wide-OFF](evidence/ag70/r2/rain-reduced-wide-OFF.jpg) | [wide-AG70](evidence/ag70/r2/rain-reduced-wide-AG70.jpg) |

The recordings made before the owner’s stop request remain local in ignored build/AG70-R2-local-recordings, outside the PR. No further captures or recordings are made under the current instruction. The scripted comparison sequence ran for 21 seconds and the walk sequence for 28 seconds; continuous temporal/art acceptance is not inferred from a few sampled frames.

## Verification

[Native records](evidence/ag70/r2/native-records.json) and [filtered project log](evidence/ag70/r2/native-session.log) retain actual properties/counters. Some long STATE records were truncated by Studio; the manifest extracts only complete time/weather fields present in those raw strings. No missing fields are invented.

| Check | Result / scope |
| --- | --- |
| Ordinary full-game F5 | RUN on exact runtime above; all 12 AG69 preloads successful, no celestial loader failures |
| OFF/AG70 switching | PASS 120 switches across clear/buildup/rain/clearing/afterrain × Full/Reduced/Minimal × motion on/off |
| Restore and budgets | PASS every combination: original values and instances, original pool position, actual weather sample, 6/3/0 light caps, zero book errors |
| Owner stop/restart | PASS original Lighting instances/properties and wind restored, weather folder removed, restart defaults AG70 |
| Spellbook fallback | PASS three native cycles, legacy and soul modes, one effects folder on return, eight tracked books, lighting preserved |
| Legacy looks | PASS 36 combinations of OFF/A/B/C/AG68/AG70 × tier × motion |
| Gameplay | PASS real E and mouse input: server state 0 → 5 → 10 Essence; +5 each |
| Eight plots | PASS one real Spellbook per plot; structural check, not eight active clients |
| Graphics5, Soft/Realistic | RUN; native changes succeeded; path stippling remains an open defect |
| Desktop performance | 12 measured runs, below |
| Phone landscape emulation | NOT RUN; further visual work stopped at owner instruction |
| Real low/mid-range phones; thermals | NOT RUN; no physical device session |
| 2–8 clients / private production backend | NOT RUN; local F5 is not that gate |
| Owner art acceptance | OPEN |
| Merge / publication / new uploads or grants | NOT PERFORMED |

Automated checks: npm run tools then npm test, **1296 Luau tests (1285 inherited + 11 AG70), 14 Node tests**, analysis/compilation of 234 sources, pinned Rojo build. Exact-base preservation verifies gameplay, saves, economy, HUD, Spellbook and assets; the owner differs only at reviewed AG70 seams. Exact-HEAD repeat-build and final Windows/Ubuntu results are recorded in PR #43. Two inherited C01 lint warnings remain.

### Desktop measurements

Windows Studio, RTX 5070 Ti, graphics5 Realistic, ordinary full game, fixed day/near camera, Reduce Motion false. OFF/AG70/AG70/OFF for each tier, 5 seconds per measurement after 3 seconds settling. No screenshot or recording during measurement. Other stopped Studio windows remained open. [Raw runs](evidence/ag70/r2/performance.json).

Arithmetic means of two run medians:

| Tier / look | Frame ms | CPU ms | GPU ms | Draw calls | Memory MB | Lights |
| --- | --- | --- | --- | --- | --- | --- |
| full OFF | 4.146 | 3.000 | 0.967 | 372.500 | 3678.189 | 6 |
| full AG70 | 4.088 | 3.053 | 1.047 | 373.500 | 3678.189 | 6 |
| reduced OFF | 4.070 | 2.711 | 0.885 | 342.000 | 3678.346 | 3 |
| reduced AG70 | 4.087 | 2.682 | 0.955 | 341.000 | 3678.479 | 3 |
| minimal OFF | 4.101 | 2.728 | 0.798 | 306.000 | 3679.691 | 0 |
| minimal AG70 | 4.098 | 2.688 | 0.868 | 306.000 | 3678.479 | 0 |

GPU render time rose approximately 0.07–0.08 ms; frame time was essentially unchanged in this short sample. These are desktop diagnostics, not mobile estimates, long-session results or thermal guarantees.

## Unresolved checks and defects

- **Graphics5 path stippling:** triangular patches remain under Realistic; also observed in historical OFF. Root cause is unproven. Geometry/materials and runtime LightingStyle were not changed to hide it.
- **Sunset:** warmer fill and pools improve the foreground, but the ridge still occludes the direct sun at 17.65. Strong directional amber foreground is not established.
- **Night:** warm pools and blue depth differ clearly, but dark clothing can merge with ground between sources, especially Reduced. Legibility needs owner judgement.
- **Inherited UX:** starter-choice panel, yellow boundaries and temporary station geometry remain visible and unchanged.
- **Other native diagnostics:** local PlaceId=0 hash requests, unrelated asset 203785492 type mismatch and a CloudsUpsampleNoHistoryFS graphics warning were observed. [Diagnostic scope](evidence/ag70/r2/diagnostics.json). Zero Sun/Moon errors does not mean zero Studio warnings. No new asset upload/access change was attempted.
- Physical phones, multi-client load and owner art acceptance remain open. The owner stopped further screenshot/video work during this task; phone emulation was not completed.

## Reproduction

1. Check out the feature branch; run npm run tools, npm test and node scripts/check-integration-base.mjs.
2. Open build/PotionTycoon.rbxlx in Studio and use normal Play (F5). Studio defaults AG70; release default remains OFF.
3. Optional client-only QA files in qa/ag70-*.luau are excluded from Rojo; install ag70-command-bar.luau before other helpers. They use the existing owner bridges.
4. Client workspace.PotionTycoonWorld EnvironmentReview accepts look:OFF / look:AG70 and day / sunset / night / rain / afterrain. Existing settings control quality and Reduce Motion. No game HUD selector was added.
5. Further art capture work requires a new owner instruction; no merge, publication or UI-stage handoff is implied.
