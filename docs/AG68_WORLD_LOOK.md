# AG-68 — Arcane Forest 2.0

Issue #38; stacked Draft PR [#39](https://github.com/branch-danya-dev/magicpotiongacha/pull/39), base PR #37 at
`34db02c7a09a0208c881d04ad14c51d0a663e55e` (CI 43407466365, Windows/Ubuntu green).
Branch `feat/ag68-world-look`. Owner acceptance NO; publication NO.

## Stage 1: ordinary-build diagnosis before changing runtime

2026-11-13, ordinary `build/PotionTycoon.rbxlx`, F5 client in Studio
0.747.0.7471481. The existing owner reports Reduced, Reduce Motion false, OFF,
EnvironmentArtEnabled true. Manual rendering Level21, LightingStyle Realistic,
PrioritizeLightingQuality true, local GameId/PlaceId 0. This differs from the old
AG63 evidence, which used Soft / graphics 5: those screenshots are not substituted
for current evidence. One M7 atmosphere/color/bloom/rays owner is active.

OFF/A/B/C were compared at the same camera, FOV 65, settled day 13.2, clear weather,
unchanged HUD and live local animations. Values genuinely change in the running
owner; there is no evidence of a second writer cancelling them. The changes are
small: day Reduced Bloom 0.012 OFF, 0.0042 A, 0.0078 B, 0.0054 C, threshold 2.3.
The default OFF and restrained grading both explain the weak result.

### Inherited texture blocker

All 12 M7 dependencies fail in this ordinary build, independently of AG63:

| Local prefix | Files | Visible consequence |
|---|---|---|
| `rbxasset://m7task07a-v1/` | bk/dn/ft/lf/rt/up.png | Intended six-face original sky unavailable; cannot accept sky appearance/seams |
| `rbxasset://m7a2b-v4/` | sun/moon.png | Intended celestial artwork unavailable |
| `rbxasset://m7a2b-v4/` | mist/rainbow.png | Local fog/rainbow artwork unavailable |
| `rbxasset://m7a2c-v2/` | meadow/star.png | Meadow sprites/night stars unavailable |

Studio reports File not found / Invalid image or texture and the owner's
`assetFailures=12`. These folders are absent from the active Studio version's
content directory. The repository contains original local preview packages and
`scripts/install-atmosphere-preview.mjs`; an ordinary Rojo place cannot distribute
these workstation-relative paths. AG68 does not install, replace, upload, suppress
or change their permissions. Follow-up requires reproducible approved Roblox asset
integration and an actual Experience permission check. **Art acceptance BLOCKED**
while these substantial scene dependencies are unresolved. Lighting code and
relative OFF/AG68 comparisons can still be evaluated with identical failures.

Real-device performance and actual 2–8 client testing: NOT RUN.

## Implementation and rollout

`WorldLook.luau` projects the existing continuous EnvironmentState channels into
one palette. EnvironmentView still creates and owns the same Atmosphere, Sky,
ColorCorrection, Bloom, SunRays and Clouds; no new instance, connection, timer,
clock or permanent render loop is added. Weather mixes independently over the
day/dawn/sunset/night weights, including interrupted transitions and after-rain.
There is no texture churn, material substitution, global Blur or depth of field.

Studio selects AG68 automatically when the existing environment owner starts.
`EnvironmentArtEnabled` is respected, never forced. Published clients select OFF;
`releaseEnabled=false`, and the AG68 request path is Studio-only. Old A/B/C remain
available as inherited experiments. OFF first computes the original dynamic
baseline; extended Bloom size/threshold are reset explicitly. Existing stop and
displaced-effect restoration remain unchanged.

All inherited server, economy, saves, remotes, HUD, Spellbook VFX, assets and
default Rojo mapping are unchanged. A byte-preservation guard checks PR37; only
six explicitly bounded additions in EnvironmentView are permitted. Historical
guards normalize those additions before their original exact comparisons.

### Palette anchors (RGB 0–255, interpolated, not discrete switches)

| Parameter | Day | Sunset | Night | Dawn |
|---|---|---|---|---|
| Brightness | 2.65 | 2.70 | 1.90 | 2.55 |
| Exposure | -0.06 | 0.30 | 0.72 | 0.14 |
| Ambient | 66,107,142 | 117,101,161 | 124,141,224 | 103,150,156 |
| OutdoorAmbient | 125,164,186 | 192,149,172 | 156,177,241 | 162,186,183 |
| Tint | 221,243,255 | 255,222,231 | 218,218,255 | 247,229,247 |
| Contrast / saturation | .145 / .025 | .115 / .045 | .09 / .06 | .105 / .035 |
| Atmosphere density / haze | .29 / 1.35 | .32 / 1.75 | .30 / 1.20 | .30 / 1.45 |
| Atmosphere color | 137,202,227 | 249,170,191 | 85,90,169 | 231,184,218 |
| Atmosphere decay | 92,115,172 | 114,99,166 | 54,57,121 | 123,143,185 |
| Sun color shift | 255,218,158 | 255,161,89 | 159,191,255 | 255,205,164 |

Clouds blend the palette toward diffuse cool light and reduce glare, contrast and
saturation. Rain bounds density to .20–.36 and adds at most .50 haze; after-rain
reduces haze/density again. Existing time, cloud cover/density, weather VFX,
lanterns and light budgets are preserved. Atmosphere.Offset is unchanged.

| Tier | Bloom cap / size / threshold | SunRays cap | Added objects/lights |
|---|---|---|---|
| Full | .16 / 24 / 1.45 | .035 | 0 |
| Reduced | .085 / 20 / 1.55 | .012 | 0 |
| Minimal | 0 / 18 / 2.3 | 0 | 0 |

The inexpensive palette remains present in Minimal. Reduce Motion continues to
control the inherited animation pipeline and adds no new animation. Rays fade
with night/rain. No LightingStyle or PrioritizeLightingQuality writes are added;
the project does not force a more expensive rendering mode on phones.

## Reproduce ordinary Play and evidence

Run `npm run tools`, `npm test`, then open `build/PotionTycoon.rbxlx` and F5.
No QA script or manual activation is necessary to see AG68. For comparisons only,
use Client Command Bar:

```lua
workspace.PotionTycoonWorld:SetAttribute("EnvironmentReview", "look:OFF")
workspace.PotionTycoonWorld:SetAttribute("EnvironmentReview", "look:AG68")
```

Optional `qa/ag68-command-bar.luau` uses the actual running owner's existing
PostFXInspect and the existing local Spellbook quality/motion bridge. It never
requires a second owner or sends gameplay remotes. `q.status`, `q.matrix`,
`q.benchmark`, `q.camera` and `q.pose` provide auditable data. The capture-tour and
extra-captures helpers are excluded from the Rojo mapping and advance with F8.

The 32 primary native JPEGs in `docs/evidence/ag68` form the full requested matrix:
OFF/AG68 × day/sunset/night/rain × near/wide × Reduced/Full. Compare them with
[the local viewer](evidence/ag68/compare.html). No generated imagery, filters,
color correction, crops or compositing are applied to these JPEGs. Both sides use
Reduce Motion true to stabilize foliage/local VFX; moving rain is separate.
Camera CFrames, FOV 65, viewport, timestamps and state labels are in
`captures.json`. Baseline OFF/A/B/C belongs to the unmodified base, not AG68.

The initial night candidate was too close to OFF during actual Play. The final
candidate strengthens moonlit fill and blue-violet shadows; that change was
tested again and all final comparisons were recaptured. Initial iteration images
are excluded from the submitted matrix.

## Validation status

**IMPLEMENTED/CODE. Scoped STUDIO VERIFIED. OWNER ART ACCEPTED: NO.
PUBLISHED: NO. MOBILE hardware: NOT RUN. MULTIPLAYER 2–8 clients: NOT RUN.**

CLI: 1,268 tests (1,254 inherited + 14 AG68), pinned Luau/Rojo, portable analysis
and ordinary build pass. Two inherited portable-analysis warnings remain.
AG68 tests cover strict Studio defaults, invalid requests, OFF nonmutation,
weather overlays, full-cycle continuity/seams, interrupted transitions, quality
caps, legibility bounds and repeated switching. Scope guards retain all inherited
tests and verify unchanged server/gameplay/asset sources.

Native final-palette run: four series of 20 alternating OFF/AG68 requests at
day/Reduced, sunset/Full, night/Minimal/Reduce Motion, rain/Reduced/Reduce Motion.
All 80 switches restored every sampled property within 1e-6; the same Lighting
and Terrain effect instances survived, workspace/book counts did not grow, and
book errors remained zero. This is separate from pure CLI coverage.

Native owner stop/restart also PASS: all sampled original parameters, displaced
effect identities and GlobalWind restored; M7ClientWeather removed on stop;
restart selected AG68. The existing EnvironmentArtEnabled value was restored.
Keyboard E changed Essence 0 -> 5; one mouse interaction changed 5 -> 10 and
showed the inherited flying-page effect. No reward was injected by QA helpers.

### Native visual evidence and limits

- 32 matched primary captures plus 17 supplemental captures: reversed day/night,
  Minimal day/night, iPhone 17 Pro landscape emulation, manual graphics 5,
  Soft/PrioritizeLightingQuality false versus Realistic/true.
- [Live OFF -> AG68 -> OFF](evidence/ag68/live-off-ag68.mp4): 19.49 seconds,
  fixed ordinary camera, day, Reduced, motion enabled.
- [Farm walk day -> night](evidence/ag68/farm-walk-day-night.mp4): 42.26 seconds,
  native Custom character camera, four Humanoid MoveTo waypoints inside the farm,
  inherited smooth night transition. Includes setup lead-in; no montage.
- Both videos are original Roblox F12 H.264/AAC recordings at 2112x1104,
  approximately 30 FPS. They are not reconstructed from screenshots, trimmed,
  recolored or re-encoded. Source hashes are in the evidence manifest.
- Moonlit fill now makes roads/terrain more legible; cool daytime shadows and
  rose-violet sunset are clearly different in these comparisons. This is an
  implementation assessment, not the owner's artistic approval.
- Minimal retains the palette with Bloom/Rays zero; existing Neon presentation
  differs when the inherited Bloom pipeline is disabled. No new source lights.
- **Unresolved:** manual graphics 5 / Realistic shows stippled road shadows in
  the native image. Soft reduces that artifact but also reduces scene depth.
  AG68 does not force either rendering mode. Low-quality visual polish is open.
- **Unresolved inherited HUD:** the starter-familiar panel obscures the book and
  center of the landscape phone emulator. HUD was left unchanged; mobile art
  legibility cannot be signed off from this emulation.
- **Unresolved inherited art:** 12 M7 local texture failures, unfinished greybox
  outer plots and fallback sky remain visible. Art acceptance stays BLOCKED.

The optional masked CIELAB Delta E 1976 check decodes the original JPEGs without
altering them. It checks identical camera/state metadata, excludes HUD, avatar,
book/sigil/runes and cursor using the same mask on both sides, and samples every
third pixel. Mean differences: day 13.13–13.55, sunset 12.28–12.45, night
19.74–20.02, rain 11.64–11.86. This supports visible change only; it is not an
acceptance threshold. Compression, residual motion and missing sky art limit it.
See [perceptual-difference.json](evidence/ag68/perceptual-difference.json).

### Desktop performance

Final palette only, 2026-11-13 18:01–18:03 UTC, ordinary F5, NVIDIA RTX 5070 Ti,
Studio 0.747.0.7471481, graphics 21, Realistic / PrioritizeLightingQuality true,
day/near, FOV65, 2113x1115 viewport, Reduce Motion false. Per tier: OFF/AG68 then
AG68/OFF, two 5-second samples per look, 3-second settling before each sample.
No compilation or video encoding ran during measurement. Values below average
the two medians; p95 is the range of the two frame-time p95s, not pooled p95.

| Tier/look | Frame ms | Frame p95 ms | Render CPU/GPU ms | Draw calls | Memory MB | Environment lights |
|---|---:|---|---|---:|---:|---:|
| Full OFF | 4.064 | 5.377–5.395 | 2.904 / 2.018 | 325.0 | 3178.4 | 6 |
| Full AG68 | 4.086 | 5.262–5.423 | 2.777 / 1.991 | 326.5 | 3179.9 | 6 |
| Reduced OFF | 4.084 | 5.226–5.235 | 2.743 / 1.929 | 286.0 | 3178.1 | 3 |
| Reduced AG68 | 4.087 | 5.263–5.328 | 2.731 / 1.983 | 286.0 | 3178.1 | 3 |
| Minimal OFF | 4.072 | 5.176–5.294 | 2.382 / 1.545 | 246.0 | 3179.6 | 0 |
| Minimal AG68 | 4.097 | 5.200–5.292 | 2.421 / 1.534 | 246.0 | 3179.7 | 0 |

Five Lighting children in every case; AG68 adds zero objects. Short desktop
samples show no material regression, but are near the 240 FPS cap and cannot
establish phone performance. Memory is Studio's Stats total including editor
overhead, not isolated production-client memory. Raw medians/p95/sample counts,
triangles and all 12 runs: [performance.json](evidence/ag68/performance.json).

### Provenance and remaining gates

Native final-runtime SHA: `52128f21c4daea9e3210a45b8d7b32482d1f142a`.
Ordinary Rojo SHA-256:
`a74d142e1d7ee2a51068d449dcfb617c590d5cd96631c7f49d08f1e28508b562`.
Subsequent evidence/documentation/optional-QA changes do not change the runtime
or ordinary build. Exact delivery HEAD and its Windows/Ubuntu CI are recorded in
Draft PR #39. Runtime revision CI 43476393008 passed both platforms.

Evidence [manifest](evidence/ag68/manifest.json) records SHA-256 hashes, base,
runtime and build revisions. [runtime.json](evidence/ag68/runtime.json) contains
only tagged AG68 diagnostics, not unrelated Studio/plugin logs. It includes
automatic start, weather/quality counts, 80 switches, ownership restoration,
render measurements and video markers. One resized-window capture was discarded
and recaptured at the matched viewport; captures.json records this explicitly.

Still open: owner's visible-world review; M7 texture delivery/permission and sky
art gate; graphics-5 stippling; mobile HUD occlusion; actual low/mid-range phones;
2–8 simultaneous clients. No publish, merge, permission change, asset upload,
economy change or final release activation was performed.
