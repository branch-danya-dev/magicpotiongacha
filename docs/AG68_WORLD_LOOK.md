# AG-68 — Arcane Forest 2.0

Work in progress. Issue #38; stacked base PR #37 at
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
