# AG-63 — Global look experiment

Issue #32. Stacked on Draft PR #33, base `081bf33ba88178312207f8ad4f3a21b698511766`
(Windows/Ubuntu CI run `43233181998`). Branch `feat/ag63-postfx-lookdev`.
Owner comparison OPEN; no preset accepted or enabled for release.

## Implementation

`PostFXLook` is a pure projection of the existing time/weather sample. The sole
`EnvironmentView` applies it after its original lighting writes. OFF returns no
override: the next owner update writes the exact contemporary baseline, including
while time/weather are transitioning. Corrections never feed back into the baseline
or bloom smoother. No new effect instances, lights, frame callbacks or clocks.
Existing Sky/Clouds, SunRays, all local Spellbook effects, server/client gameplay,
quality controls, assets, saved data and release flags are unchanged.

OFF is the default. Live clients cannot select looks. In Studio **Play, Client
Command Bar** use the existing local review attribute:

```lua
workspace.PotionTycoonWorld:SetAttribute("EnvironmentReview", "look:A")
-- look:B, look:C, look:OFF; day, sunset, night, rain still work independently.
```

No player preset menu. A read-only Studio `PostFXInspect` BindableFunction reports
the actual owner's state (Command Bar module cache is separate). The endpoint is
destroyed by `stop()`. Disabled environment art stays disabled.

## Parameters

All numbers below are relative to the inherited dynamic sample, at Full strength.
RGB values are targets mixed with the original color, not replacement colors.
Reduced applies 85% color/lighting correction; Minimal 55%. Bloom uses the
listed multiplier against the existing quality-specific bloom value. Night warm outdoor correction is
attenuated by up to 75%, and contrast correction by up to 55% for legibility.

| Parameter | OFF Original | A Cozy Fantasy | B Arcane Forest | C Cinematic Fantasy |
|---|---|---|---|---|
| Brightness multiplier | 1 | 1.04 | 1.02 | 1.06 |
| Exposure delta | 0 | -0.04 | -0.05 | -0.07 |
| Ambient target / mix | original | 168,158,140 / 13% | 108,138,183 / 28% | 105,129,166 / 24% |
| Outdoor target / mix | original | 195,188,160 / 12% | 143,173,199 / 18% | 211,183,147 / 16% |
| Tint target / mix | original | 255,251,238 / 32% | 224,235,255 / 30% | 249,242,233 / 14% |
| Saturation delta | 0 | -0.015 | +0.018 | -0.025 |
| Contrast delta (base 0.025) | 0 | -0.010 | +0.018 | +0.070 |
| Atmosphere density multiplier / add | 1 / 0 | 0.92 / 0 | 1 / 0.016 | 0.94 / 0 |
| Haze multiplier | 1 | 0.80 | 1.15 | 1.05 |
| Bloom intensity multiplier | 1 | 0.35 | 0.65 | 0.45 |
| Sun tint target / mix | original | 255,229,194 / 10% | 211,226,255 / 12% | 255,208,158 / 22% |

Density is bounded to 0.10–0.38. Minimal disables extra haze/density addition and
bloom. Existing quality still controls shadows, sun rays and local VFX budgets.
Bloom size 18 / threshold 2.3 remain unchanged. No Blur/DoF or animated preset
interpolation; Reduce Motion is respected by the original owner and gains no new
motion. Sun tint is weighted by daylight and cloud cover. No permanent darkening
of world lights. Cinematic uses the existing sun/shadows/rays, not an extra pass.

## Reproduction and evidence

`npm run tools`, `npm test`. Build `default.project.json`, then open the resulting
place and run ordinary Play. Do not use the isolated environment preview for
acceptance. `qa/ag63-command-bar.luau` is an optional native Client Command Bar
helper, excluded from both Rojo trees. It fixes a camera, reports the actual owner,
snapshots Lighting/effect properties, runs 20 switches and samples engine timings.
Allow the inherited 8-second transition to settle after choosing a time/weather
pose. Change Full/Reduced/Minimal and Reduce Motion using the actual Factory
quality controls. Keep viewport, camera, graphics level and pose identical within
each comparison set. Stop Play to discard all temporary QA changes.

Portable checks retain all 1181 inherited tests and add 12 projection/continuity/
weather/quality/immutability tests. The preservation guard pins all inherited
`src/` and test files plus the Rojo project. Only eight bounded insertion blocks
in EnvironmentView are allowed; removing them must reproduce the exact base file.
This also protects economy, Spellbook VFX, the five connections, single frame owner
and existing cleanup/restoration logic.

## Verified delivery — 2026-11-12

**IMPLEMENTED/CODE; STUDIO VERIFIED for the bounded checks below; OWNER ACCEPTED:
NO; PUBLISHED: NO.** [Draft PR #34](https://github.com/branch-danya-dev/magicpotiongacha/pull/34)
is stacked on PR #33, not main. The PR's final evidence commit changes documentation
and captures only; its exact HEAD is recorded in the PR. The actual runtime tested
in Studio is `6fe6649868420cfc7a8bb73e4d6cc894d8c2a271`.

- Base: `081bf33ba88178312207f8ad4f3a21b698511766` (PR #33).
- AG01 ancestor: `341b7f6dd9ac1692781f865bf25fed63a05e9d8a`; AG00 ancestor:
  `7d6d47826e919683ee991c911185215cda0d3d2e`.
- Runtime CI: [43239583185](https://github.com/branch-danya-dev/magicpotiongacha/actions/runs/43239583185),
  Windows and Ubuntu PASS. Final evidence-HEAD CI is linked in the PR.
- `npm run tools`, `npm test`: **1193/1193** (1142 core + 13 AG01 + 26 AG62A +
  12 AG63); 185 Luau sources compiled, portable analysis and preservation guards PASS.
- Clean detached checkout at the runtime SHA: tool verification, full tests,
  integration ancestry checks and repeated Rojo builds PASS. Both builds and the
  native `AG63-lookdev-r2.rbxlx` are byte-identical, SHA-256
  `31048c4aa3487036395142aa570eebd5a0dc37bbc93172484b4a99fc5377242e`.

### Native Studio evidence

Ordinary full-game Play, **Studio 0.747.0.7471481 / LightingStyle Soft / manual
graphics Level05**, on Windows desktop. No isolated scene was substituted. New-game
HUD/Factory and Spellbook remained present; no gameplay reward/save requests were
injected. The existing local UI demo was hidden for the comparison only, without
changing its source or default. Temporary QA changes were discarded by Stop Play;
the original Studio graphics level was restored to Level21.

The 12 comparison JPEGs are direct, unprocessed 2560×1392 Studio window captures.
The fixed game viewport is 2113×1115 after the Command Bar collapsed; the earlier
CAMERA log's 2113×1028 describes helper installation, before these captures.
Camera position (-129.5, 12, -46), FOV 65; complete matrix and image SHA-256 hashes
are in [manifest.json](evidence/ag63/manifest.json). All comparison frames use
Reduced, Reduce Motion off, identical camera and settled pose within each row.
Only existing local VFX continue animating between captures.

[Interactive local comparison gallery](evidence/ag63/compare.html) — open the
downloaded HTML alongside its JPEGs. GitHub viewers can open the originals below:

| Time / quality | OFF Original | A Cozy Fantasy | B Arcane Forest | C Cinematic Fantasy |
|---|---|---|---|---|
| Day / Reduced | [OFF](evidence/ag63/day-OFF.jpg) | [A](evidence/ag63/day-A.jpg) | [B](evidence/ag63/day-B.jpg) | [C](evidence/ag63/day-C.jpg) |
| Sunset / Reduced (17.65) | [OFF](evidence/ag63/sunset-OFF.jpg) | [A](evidence/ag63/sunset-A.jpg) | [B](evidence/ag63/sunset-B.jpg) | [C](evidence/ag63/sunset-C.jpg) |
| Night / Reduced (22.5) | [OFF](evidence/ag63/night-OFF.jpg) | [A](evidence/ag63/night-A.jpg) | [B](evidence/ag63/night-B.jpg) | [C](evidence/ag63/night-C.jpg) |

Additional native checks: [Full](evidence/ag63/quality-full.jpg),
[Full + Reduce Motion](evidence/ag63/quality-reduce-motion.jpg),
[Minimal + Reduce Motion](evidence/ag63/quality-minimal.jpg),
[rain B / Reduced](evidence/ag63/rain-B.jpg).

| Check | Observed result |
|---|---|
| Default / ownership | OFF, Reduced; one EnvironmentView; no CreatorError in accepted run |
| Actual projection applied | C/day/Reduced: contrast 0.0845, bloom 0.0054, exposure -0.0095 |
| 20 switches, Reduced day | PASS; all sampled Lighting/Atmosphere/CC/Bloom/SunRays/Clouds/Sky properties restored (tolerance 1e-6), same 5 Lighting descendants |
| 20 switches, Full night | PASS; same instances, exact OFF baseline; quality/motion unchanged |
| 20 switches, Minimal night + Reduce Motion | PASS; same instances, exact OFF baseline; quality/motion unchanged |
| 20 switches, Reduced rain | PASS; same instances, exact OFF baseline; quality/motion unchanged |
| Full + Reduce Motion | Wind/motes/moving meadow 0; no added preset animation |
| Minimal + Reduce Motion | Bloom disabled/intensity 0, shadows false; environmental lights/motes/wind/glints 0; Spellbook emitters/lights 0 |
| Existing weather | Rain B retained clouded sky, 24 nearby rain streaks, 2 fog props; clear/day, sunset and night retained their identity |
| Disable environment | Existing weather folder and diagnostic probe removed; 0 M7 Lighting children; subsequent look request leaves exposure unchanged |

An initial native run exposed re-entrant startup when the read-only probe was
parented directly to Workspace. The accepted runtime parents it to the existing
client weather folder, avoiding the bootstrap's root ChildAdded listener; a guard
pins this ownership constraint. The initial failed run supplies no acceptance
frames or timings. The accepted ordinary Play ran without that collision.

[studio-evidence.log](evidence/ag63/studio-evidence.log) retains only actual AG63
CreatorOutput records (not command echoes or unrelated account/plugin logs).
[native-results.json](evidence/ag63/native-results.json) contains the parsed records.

### Performance observations

Native engine samples, approximately 5 seconds / 301–302 frames per look. Render
CPU/GPU values are reported in ms; frame interval comes from RenderStepped.
The fixed camera, graphics 5 and Reduced/day are shared by the first four rows.

| Look / condition | Median FPS | Frame median / p95 ms | Render CPU median / p95 ms | Render GPU median / p95 ms | Median draw calls |
|---|---:|---:|---:|---:|---:|
| OFF / Reduced day | 60.05 | 16.652 / 17.900 | 2.786 / 3.354 | 0.654 / 1.146 | 293 |
| A / Reduced day | 60.08 | 16.643 / 17.982 | 2.799 / 3.259 | 0.684 / 1.129 | 294 |
| B / Reduced day | 60.06 | 16.649 / 17.834 | 2.730 / 3.147 | 0.693 / 1.165 | 295 |
| C / Reduced day | 59.93 | 16.687 / 17.836 | 2.790 / 3.283 | 0.683 / 1.119 | 294 |
| C / Full night | 60.02 | 16.662 / 17.801 | 2.994 / 3.475 | 0.756 / 1.214 | 322 |

These are short desktop observations with other applications open, not controlled
benchmarks, phone evidence or an FPS improvement claim. A/B/C introduce no extra
render effect instances. Full/night is a separate quality sanity check, not a
like-for-like performance comparison with the daytime rows.

## Open gates

- Owner art choice A/B/C remains OPEN.
- Real-device smartphone performance and multi-client load remain BLOCKED/unperformed.
- Inherited M7 sky texture integration/asset permission gates remain separate and
  unresolved; **12 inherited local texture failures** were reported by the actual
  EnvironmentView in this run. AG63 does not upload, replace or remap those textures.
- Art remains a comparison, not a final selection. Existing Spellbook runes are
  still pale/bright and night is deliberately dark; bloom is lower than OFF in
  A/B/C, but the owner must judge rune contrast and world readability. No source
  change to those local VFX is included. Soft/graphics 5 also limits volumetric
  appearance; C does not promise a custom volumetric shader.
- Long-duration, multi-camera and all hardware/weather combinations were not
  exhaustively visually verified; deterministic continuity tests cover the full
  time/weather sample cycle. The checks above do not close broader M7 gates.
- No merge, publication, public access change, purchases or subsequent UI work.

Rollback: select `look:OFF`; revert the isolated AG63 commit(s) to remove the
experiment entirely. No data migration or asset rollback is needed.
