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
Reduced applies 85% correction; Minimal 55%. Night warm outdoor correction is
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

Native results, screenshots, exact build/HEAD hashes and CI will be appended after
verification. CLI passing is not Studio, phone or owner acceptance.

## Open gates

- Owner art choice A/B/C remains OPEN.
- Real-device smartphone performance and multi-client load remain BLOCKED/unperformed.
- Inherited M7 sky texture integration/asset permission gates remain separate and
  unresolved; AG63 does not upload, replace or remap those textures.
- No merge, publication, public access change, purchases or subsequent UI work.

Rollback: select `look:OFF`; revert the isolated AG63 commit(s) to remove the
experiment entirely. No data migration or asset rollback is needed.
