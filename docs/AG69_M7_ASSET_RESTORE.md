# AG-69 — Restored M7 texture delivery

**IMPLEMENTED / STUDIO VERIFIED (scope below). OWNER ART OPEN. NOT PUBLISHED.**

Issue [#40](https://github.com/branch-danya-dev/magicpotiongacha/issues/40),
Draft [PR #42](https://github.com/branch-danya-dev/magicpotiongacha/pull/42),
branch `feat/ag69-m7-asset-restore`. Base: CI-green PR #39 / `feat/ag68-world-look`
at `418d85f519232ea10e373a4b1944132ee389acd2` (run 43482710612).
AG-00 ancestor: `7d6d47826e919683ee991c911185215cda0d3d2e`.
Exact delivery HEAD and its own Windows/Ubuntu CI are recorded in PR #42.
AG-70 Issue #41 has not started; no merge or place publication.

## Defect and fix

The ordinary game requested twelve developer-local `rbxasset://` files that Rojo
cannot deliver. The AG-68 baseline recorded 12 failures. The existing single
EnvironmentView owner now uses a frozen shared Image-ID map; EnvironmentArt uses
the same map for meadow. Source art, palette, release flags, HUD, Spellbook VFX,
economy, saves and remotes are unchanged. No Studio content installation required.

One bounded preload uses twelve temporary unparented ImageLabels, destroyed on
completion or owner stop. Native diagnosis found that Roblox's generic bare-ID
route failed for these permitted Images, while the typed image route succeeded.
The initial failed candidate screenshot `ordinary-first-f5.jpg` is diagnostic
history, **not** a successful after capture. Its loader was corrected before the
verified build. No retry loop, new render loop or extra remote was introduced.

Pending loading is explicit (`assetComplete=false`), never inferred from an
initial zero failure count. Missing callbacks fail closed; duplicate failures
cannot overcount or resurrect an asset. All six sky faces switch together only
after successful loading; otherwise the complete native sky remains. Unavailable
sprites/meadow hide independently, preserving healthy assets and gameplay.
Late completion cannot mutate a stopped owner. Stop restores meadow transparency,
Lighting objects/values and wind; restart has independent delivery state.

## Sources, licensing and exact Image IDs

Canonical [manifest](../assets/environment/ag69-delivery.json) records original
paths, PNG SHA-256, decoded RGBA SHA-256, dimensions, bytes, original licenses and
receipts, uploaded Image IDs and target access. There are no Decal wrappers.

| Source key | Roblox Image ID | Dimensions | PNG bytes |
|---|---|---:|---:|
| sky_bk | `130725840424597` | 256 × 256 | 11613 |
| sky_dn | `83662321011462` | 256 × 256 | 667 |
| sky_ft | `87150286021124` | 256 × 256 | 10935 |
| sky_lf | `106481090533297` | 256 × 256 | 13086 |
| sky_rt | `96243370555026` | 256 × 256 | 11899 |
| sky_up | `127569253577461` | 256 × 256 | 7065 |
| sun | `127279777775296` | 128 × 128 | 4431 |
| moon | `120296233207649` | 128 × 128 | 1897 |
| mist | `106126272501921` | 128 × 128 | 3429 |
| rainbow | `96590033453082` | 256 × 128 | 12943 |
| meadow | `104321131031052` | 128 × 128 | 4354 |
| star | `99406398694311` | 64 × 64 | 862 |

Original project-authored mathematical images; no downloaded or Nintendo/Zelda
pixels. Existing CC0-1.0 licenses permit this use and redistribution. Source
receipts pin original PNGs, license files and LF-normalized generators:
`create-stability-sky.py` (and `create-fantasy-sky.py`),
`create-atmosphere-assets.py`, `create-polish-assets.py`.
No individual human author is asserted beyond the original project contribution.
Receipt commits: sky `04d3aea63964e86c3a0d46f49ec055971b3bfca6`, atmosphere
`39788eafaf93de4c21f7817f0aff4cb4e38ffd35`, polish
`8c91195d6b2f94456646ad045e624e07e943bf23`.
All twelve reproduced byte for byte in isolated regeneration:
[source proof](evidence/ag69/source-reproduction.json).
83,181 encoded bytes / 1,982,464 decoded RGBA8 bytes before mipmaps; no resolution
or steady-state VFX budget increase. At most twelve short-lived preload probes.

## Upload, identity and access evidence

The owner separately approved exactly these twelve PNGs on 2026-11-13: Restricted
Group **addout studio / 925845207**, permanent access only to Universe
**10776120489**, private Place **125724638469407**. Group Asset Privacy was already
enabled; no setting was changed. The twelve images were uploaded **once**, all
imports completed, all twelve Dashboard pages showed Restricted, and all twelve
correct-Universe grants returned **Changes Saved**. No Open Use, Creator Store,
collaborator grant, purchase or public access was used.

Dashboard filtered the asset names to `####`. Identity was therefore established
by exact dimensions and SHA-256 of decoded RGBA8 from Studio EditableImage, not
names or inventory order. All 12 match the local decoded source bytes:
[identity log](evidence/ag69/studio-image-identity.log), reproducible optional
[identity probe](../qa/ag69-identify-images.luau).
The [upload/access receipt](evidence/ag69/upload-access-receipt.json) binds each ID
to three native permission records, pixel identity, and runtime evidence hashes.
The Dashboard states saved Experience entries are not shown afterward; an empty
entry list is not evidence that the recorded grant failed. Do not upload again.

Two native runtime checks are deliberately distinguished:

1. **Correct private Experience F5 client**: twelve temporary ImageLabels preloaded
   successfully, unique=12, failures=0, Universe 10776120489 / Place 125724638469407.
   This was an access probe in the existing private baseplate/import scene, not
   the full game: [log](evidence/ag69/private-f5-access.log),
   [native image](evidence/ag69/private-f5-access.jpg).
2. **Ordinary full-game F5** from fresh `default.project.json` Rojo output, GameId 0:
   all twelve callbacks Success and completed `assetFailures=0`. No developer
   content installation. [Native log](evidence/ag69/ordinary-f5.log).
   This does not certify an independent account or a published Roblox server.

## Native checks and build provenance

Checked 2026-11-14 Europe/Moscow in Roblox Studio 0.747, on the existing desktop.
Native captures are unmodified Studio window screenshots, never generated art.
QA commands in [ag69-play.luau](../qa/ag69-play.luau) are excluded from Rojo and use
existing owner bridges; they never grant rewards or publish.

- Automatic ordinary Play: Reduced, AG68, Reduce Motion off; all twelve ready.
- Full/Reduced/Minimal × motion off/on × OFF/AG68: 12 combinations, all ready,
  zero failures, no sky fallback. Minimal reports zero local lights/rain/motes/fog.
- All eight plots have a crystal and exactly one Spellbook visual binding. This
  is a structural eight-plot check, not an eight-player load test.
- Real keyboard E: Essence 0 → 5. Real mouse click on the interaction prompt:
  5 → 10. Exactly two Spellbook feedback events. Clicking the upper book mesh
  did not trigger collection at this angle; the visible prompt did.
  [E](evidence/ag69/ordinary-e-plus5.jpg),
  [mouse prompt](evidence/ag69/ordinary-mouse-plus5.jpg).
- Owner stop/restart/stop: original Lighting property values and child instances,
  wind and weather-folder cleanup restored; restarted preload again 12/12.
- Default engine graphics Q21 in the captures. Real phone/frame-time benchmarking
  and a new manual graphics-5 acceptance are not claimed.

Verified runtime build: `build/AG69-Verified.rbxlx`, SHA-256
`8eb14671401c78a8ca15792be3ec0769a3cce9b3e887ed685a5575ba43260e56`.
The final exact-HEAD ordinary build must match this hash. Tests/repeat-build
receipt are generated in `build/verification.log` and `build/ag00-integration.json`.
No QA-only command changes are saved into the delivered place.

## Before/after comparison

AG-68 baseline images are in `evidence/ag68`; AG-69 images are in `evidence/ag69`.
Day/sunset/night/rain use the same existing review poses, AG68 look, Reduced,
Reduce Motion on, FOV 65, and near/wide camera transforms. Runtime logs retain
camera components and viewport size. Compare world appearance, not pixel-perfect
HUD/avatar matching: starter-modal and player state differ between runs.
AG69 viewport is 2113 × 1113; the baseline is usually 2113 × 1115 (sunset-near
2095 × 1097). Camera transforms and FOV match, viewport dimensions do not.

| State | Before | After |
|---|---|---|
| day near | [AG68](evidence/ag68/day-reduced-near-AG68.jpg) | [AG69](evidence/ag69/day-reduced-near-AG68.jpg) |
| day wide | [AG68](evidence/ag68/day-reduced-wide-AG68.jpg) | [AG69](evidence/ag69/day-reduced-wide-AG68.jpg) |
| sunset near | [AG68](evidence/ag68/sunset-reduced-near-AG68.jpg) | [AG69](evidence/ag69/sunset-reduced-near-AG68.jpg) |
| sunset wide | [AG68](evidence/ag68/sunset-reduced-wide-AG68.jpg) | [AG69](evidence/ag69/sunset-reduced-wide-AG68.jpg) |
| night near | [AG68](evidence/ag68/night-reduced-near-AG68.jpg) | [AG69](evidence/ag69/night-reduced-near-AG68.jpg) |
| night wide | [AG68](evidence/ag68/night-reduced-wide-AG68.jpg) | [AG69](evidence/ag69/night-reduced-wide-AG68.jpg) |
| rain near | [AG68](evidence/ag68/rain-reduced-near-AG68.jpg) | [AG69](evidence/ag69/rain-reduced-near-AG68.jpg) |
| rain wide | [AG68](evidence/ag68/rain-reduced-wide-AG68.jpg) | [AG69](evidence/ag69/rain-reduced-wide-AG68.jpg) |

## Automated checks and limits

`npm run tools` verifies hash-pinned Luau/Rojo, then `npm test` retains all 1268
inherited Luau tests and adds 13 delivery-state tests plus 13 Node provenance /
evidence tests. Compilation, portable analysis, ordinary/review Rojo and inherited
seam/security guards remain enabled. The bounded URI/preload seams are restored
to their exact PR39 text by preservation checks; unrelated art/gameplay is still
pinned. Two inherited nonfatal C01 lints remain (LocalShadow/LocalUnused).

`node scripts/check-ag69.mjs --require-delivery` validates the recorded source,
identity, Restricted grants and both native runtime proofs. It does not run Studio
inside CI. Missing/changed proof fails; booleans alone cannot pass the gate.

Remaining checks: owner art review, real smartphones, 2–8 clients, independent
account / published-server asset use. Rights were not revoked to force live
permission failure: per-face/sprite fallback and missing/late callback cases are
covered by state tests; owner restoration is native-verified. The original native
sampling seam acceptance remains an artistic review, beyond mathematical seam
continuity and these fixed-view screenshots. No controlled FPS claim: several
Studio instances were open. Rojo's disconnected localhost plugin and Studio
telemetry/plugin-lock diagnostics are not texture delivery failures.

Known inherited visual issues remain: graphics-5 shadow stippling, starter-modal
occlusion, unfinished outer-plot art, and the need for AG70 lighting review.
No artistic approval is inferred from technical delivery. Rollback restores the
asset seams/map without touching saves; a Git rollback cannot revoke permanent
Roblox Experience grants. Merge and publishing remain prohibited.
