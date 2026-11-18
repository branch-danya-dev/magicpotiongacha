# Sky World Tree R3 — directional accents and horizon investigation

**CODE CANDIDATE / STUDIO QA PENDING / OWNER ART PENDING.**
Same Draft PR #61 and `feat/ag76b-sky-world-tree`.
Revision base: `3760c9081e9c0a19cc2622dadcc210bfe990986b`, exact-base CI
44322639495 Windows/Ubuntu PASS. PR base remains
`6540ba350cb933c598d5abe0eb22167878e55fc9` (PR #60, with PR #59 ancestry).
Final HEAD, artifact checksum and exact-HEAD CI are recorded in the PR/receipt.

## Horizon: evidence and limits

**The reported native line's cause is NOT YET CONFIRMED. This is not a claim that
the horizon defect is fixed.** The requested visual layer ablation is a separate
gate; parameter assertions, source pixels and successful builds cannot close it.

Read-only `node scripts/inspect-sky-horizon.mjs` verifies the six PNG hashes against
the existing AG69 upload manifest, then checks the independently recorded native
cube adjacency and source row profiles. No screenshot or edited image is produced.

- All six sources match the approved delivery; the maximum channel difference
  across corresponding face edges is **0/255**. This excludes a mismatched edge
  in those source files, not a native loading/filtering/atmosphere problem.
- R2 cloud crop edge alpha is **1/255**, so it has no opaque rectangular crop edge.
- The sky source contains **three low ridge silhouette bands** and **five baked
  cloud banks**, independently of R2's eight ocean banks. The largest adjacent-row
  mean luminance changes on lateral faces are 5.98–7.76/255 around rows 123–125 of
  256, just above the horizon. These are possible contributors, not native proof.
- The inherited EnvironmentView writes `Atmosphere.Offset=.15` each update.
  AG63/68/70/75 can subsequently alter density, haze, color and decay. A manual
  property edit outside that owner would be overwritten and is not a valid test.

Roblox's [atmosphere documentation](https://create.roblox.com/docs/environment/atmosphere)
describes Offset's role in horizon separation and its interaction with Density.
That explains the **hypothesis**, not the cause of this project's particular line.
No sky texture/asset IDs are replaced and no additional fog plane is introduced.

### Controlled comparisons

`Horizon.luau` is a pure plan. Only the generated QA adapter of EnvironmentView
applies it after all existing look projections. No additional lighting owner or
clock is created. Modes are reversible and do not mutate saves or settings.

| Mode | Offset | Sole comparison change from baseline |
|---|---:|---|
| `baseline` | 0.15 | Original atmosphere parameters |
| `offset0` | 0 | Offset only |
| `offsetNegative` | -0.05 | Offset only |
| `neutralScatter` | 0.15 | Density .12, Haze/Glare 0, Decay=Color |
| `noAtmosphere` | 0.15 | Owner Atmosphere temporarily unparented |
| `noOcean` | 0.15 | Eight R2 cloud masses and local drift hidden |
| `noSky` | 0.15 | Owner Sky temporarily unparented; engine fallback may appear |
| `noNativeClouds` | 0.15 | Terrain Clouds disabled |
| `candidate` | 0 | Complete R3 with all layers present; **unaccepted hypothesis** |

The candidate defaults to Offset 0 in this isolated QA place only. Density/Haze/
Color/Decay remain controlled by the inherited look/weather; the whole scene is
not fogged over. Returning to candidate resets all disabled layers. Stop also
destroys unparented diagnostic objects and restores displaced originals.

In the **client** Command Bar during F5, for example:

```luau
workspace.PotionTycoonWorld.SkyLandmarkQA:Invoke("pose", "day")
workspace.PotionTycoonWorld.SkyLandmarkQA:Invoke("horizon", "baseline")
```

Replace `baseline` with the mode being compared. Keep the same ordinary camera,
weather and pose; compare one mode at a time, then return to `candidate`.
Use `Invoke("pose", "dusk")` / `"night"` and `Invoke("moon", "pearl")` /
`"blood"` / `"frost"` for the other checks. `Invoke("moon", "auto")` restores
the existing nightly selection. `Invoke("pose", nil)` resumes the normal clock.
No scripts reposition the camera, character, island or tree for this review.

## Directional crown light

The existing EnvironmentView already reads `Lighting:GetSunDirection()` and
`Lighting:GetMoonDirection()` for its celestial visuals. R3 passes those same
vectors and the **final applied Atmosphere.Color** to the landmark. It does not
add global lights or rely on `BillboardGui.LightInfluence`, which stays zero.

Three overlapping copies of the existing tree image supply upper/left/right
accents. Static UIGradient transparency masks fade to fully transparent before
the center of the crown. Original alpha, branch detail and dark interior remain.
There are no new PNGs, EditableImages, pixel writes or per-frame mask generation.
[UIGradient reference](https://create.roblox.com/docs/reference/engine/classes/UIGradient).

The vectors are projected onto the billboard's current camera-facing right/up
axes, while **world altitude** controls whether the sun/moon is above the horizon.
A smooth altitude gate, existing night/warm/cloud weights and 0.6-second smoothing
drive the strength. This changes local opacity/tint, never global exposure/Bloom.

- Day: golden upper/side accents, stronger on the source-facing edge.
- Dusk: warmer amber edge accents while direct sunlight remains above the horizon.
- Pearl: silver-blue; Blood: restrained crimson; Frost: turquoise-blue.
- Weather attenuates direct accents; below-horizon sources cannot light the tree.
- Reduced scales accents to 85%; Minimal keeps only the upper accent at 70%.
- Reduce Motion freezes existing drift/pulse but still follows astronomical light.

This is a stylized 2D light approximation, not volumetric relighting or new 3D
geometry. Light response/visibility from the actual camera remains owner art QA.

## Cloud treatment and budgets

Nine static side-feather gradients soften the eight cloud masses and optional
local drift. Their central volume remains intact; edges fade to transparent.
The seven outer banks also use 82% of their previous opacity to reduce local
contrast against the sky; primary tree-base cover keeps its R2 opacity.
The previous dark blue tint is lightened and blended 18% toward the final owner's
atmosphere color. The baked sky clouds are **unchanged**; their contribution must
be isolated before editing or replacing any approved sky asset.

| Budget | R2 | R3 |
|---|---:|---:|
| Images / initial pixel writes | 4 / 4 | 4 / 4 |
| Decoded RGBA | 6.25 MiB | 6.25 MiB |
| Landmark world instances | 30 | 45 |
| Full / Reduced / Minimal steady layer caps | 12 / 10 / 9 | 15 / 13 / 10 |
| Quality crossfade layer cap | 13 | 16 |
| Added render connections / lights | 0 / 0 | 0 / 0 |
| Lifecycle connections | 1 | 1 |
| Full / Reduced / Minimal update caps | 30 / 15 / 5 Hz | unchanged |

Added objects: three image labels, three crown gradients, nine ocean gradients.
Enabled layer count depends on the actual light direction; caps are not forced
minimum counts. Mask sequences are allocated once. Runtime work adds two vector
projections, a bounded pure light calculation and three label color/alpha writes.
Actual GPU cost and performance regression require a native comparison.

R2 tree anchor `(510,1150,-5175)`, size `6400x2920`, all cloud/glow sizes/offsets,
camera/FOV, island/local tree geometry, 13 stations/26 routes, V8/economy,
1500-second clock, 60/20/20 moon selection and GlobalWind are preserved.
Production `src`, original assets, lunar and Willow modules have no diff.

## Verification and delivery

Targeted Luau: **20 PASS** (13 inherited + 7 R3). New checks cover unchanged
composition, direction selection, altitude gating, lunar accents, smooth dusk,
weather attenuation, Minimal/Reduce Motion and reversible ablation plans.
Full `npm run tools` / `npm test`: **PASS, 1426 Luau + 34 Node = 1460 tests**,
309 Luau sources compiled, portable analysis and inherited builds passed.
The final exact-HEAD Windows/Ubuntu CI is recorded in the PR. The last outer-bank
opacity adjustment preceded the full run's landmark tests/build; the changed
renderer/config also passed an explicit compile and targeted retest.

Native R3 verification is pending. Text-only Computer Use read the existing R2
window, but Stop did not take effect and the Test menu returned
`coordinate input geometry is unavailable`. The R3 task explicitly forbids
screenshots/video; no captures were made. The owner was asked to open the prepared
R3 development place in that existing window and start F5. Numeric diagnostics
can then be read from logs. They explicitly label horizon visual observation as
unrecorded; they cannot identify the source of the visible line by themselves.

Open: native ablation/cause confirmation, clear horizon while turning/walking,
tree/sky/cloud visual cohesion, five lighting states, native quality/restart/
performance checks, real devices/multiplayer and owner art review. No R2 Play
results are passed off as R3 verification.

Build: `node scripts/build-sky-landmark.mjs --owner-user-id=11924805007`.
Output: `build/PotionTycoon-SkyWorldTree-R3-QA.rbxlx`.
Owner copy: `G:\Codex\PotionTycoon-SkyWorldTree-R3.rbxlx`.
Optional `--verify` runs bounded native diagnostics; owner build has no automatic
pose/quality/ablation switching. R2 remains at `G:\Codex\PotionTycoon-SkyWorldTree-R2.rbxlx`.
No merge, production integration, Roblox upload/access change, payment or publication.
