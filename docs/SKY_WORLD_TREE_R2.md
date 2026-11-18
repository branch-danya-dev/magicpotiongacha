# Sky World Tree R2 — monumental crown and cloud ocean

**CODE CANDIDATE / STUDIO QA (numeric PASS) / OWNER ART PENDING.**
Existing Draft PR #61, branch `feat/ag76b-sky-world-tree`.
PR base: `6540ba350cb933c598d5abe0eb22167878e55fc9` (PR #60).
R2 revision base: `2a047c401529632150c902b9d7f6ef188dd88ec4` (R1).
Final HEAD and place SHA-256 are recorded in the build receipt and PR.

## Problem and result

R1 put a faint small crown below the horizon and used the same square area for
tree, clouds and glow. Most of that area was transparent padding. R2 raises the
crown, gives each layer its own size/offset, measures the actual alpha bounds,
and adds a continuous ring of volumetric cloud imagery below the island.

The owner's two Library files were retrieved through Computer Use and inspected:

- `image(7).png`, 2048x1074, SHA-256
  `54e7a3c1ca258b3749796dc749b95fefeddf5cca8fd5d05cbace4d5bad81d22a`.
  **The downloaded file has no visible red line.** Its camera/composition and
  the owner's explicit X 820–1805 / Y 140–560 target are the reference.
- `image(6).png`, SHA-256
  `377b35170cc72bbb7c8cda87e2c74b6ca97833f6bc7310fb54dbd48f89c2e0c6`,
  confirms R1's small low crown and barely visible cloud layer.

Those user-provided images are retained locally in `build/sky-r2-references/`;
they are not newly generated QA captures and are not uploaded in this PR.

## Placement and controls

All settings are in `qa/sky-landmark/Config.luau`. Sizes are world studs after
alpha-aware UV cropping. They are independent of the backing canvas size.

| Component | Size | Offset relative to main anchor |
|---|---|---|
| World anchor, relative to PersonalIsland.origin | — | `(510,1150,-5175)` |
| Tree | 6400 x 2920 | `(0,0)` |
| Primary cloud mass | 6750 x 2500 | `(0,-2070)` |
| Glow | 7350 x 3520 | `(0,130)` |
| Atmospheric haze | 6900 x 1600 | `(0,-1320)` |

Tree, cloud and glow each expose an independent scale. Tree atmospheric fade is
0.12; cloud opacity/density are 0.96/0.94; glow intensity is 0.72. The other seven
cloud banks surround the island at radius 5200, center height near -920, with
small deterministic size/height/density variation. They overlap even after
excluding the outer soft fringe. Existing Roblox Clouds/under-island mist remain.
No new global cloud/wind/Lighting controller is introduced.

Tree texture crop: `(52,288,921,370)` on 1024x1024. Alpha>=32 visible bounds:
`(61,296,903,341)`. All crops are measured from alpha>=3 plus a margin; edge alpha
is at most 1/255. Original masters are untouched. A sibling original-art edit
darkens interior branch/crown shadows while keeping the silhouette, gaps and
soft perimeter. Exact built-in ImageGen prompt/provenance are in
`assets/environment/sky-world-tree/r2/generation.json`. No paid third-party job.
Cloud/glow PNGs are reused byte-for-byte. Minimal uses the same edited tree at
512px plus the same static cloud ocean, without glow/haze/drift.

The reference test estimates the ordinary camera from the book/arch/pine positions:
relative X/Z about (-6.085,22.277), Y=8, yaw=-14.98 degrees, FOV=70, 2048x1074.
It projects the measured visible crown close to the target rectangle (within
15px per edge, about 48% screen width), roughly twice R1's apparent width.
**This is a geometric estimate, not reproduction or acceptance of the reference
camera.** Neither camera CFrame nor FOV is set by the implementation or probe.
Live diagnostics report approximate, unoccluded alpha bounds for manual review.

## Rendering and budgets

One primary BillboardGui retains explicit internal Z-order: glow, tree/Minimal,
haze, permanent cloud cover, drift. The permanent cloud mask is present in every
quality, including during crossfades. Seven additional depth-tested world cloud
billboards extend the mass around the horizon. All have AlwaysOnTop=false;
anchors are invisible, anchored, non-collidable, non-touching, non-querying.
Actual foreground occlusion and absence of a flat-image impression remain art QA.

| Budget | R1 | R2 |
|---|---:|---:|
| EditableImages / initial pixel writes | 4 / 4 | 4 / 4 |
| Decoded RGBA | 6.25 MiB | 6.25 MiB |
| World instances | 9 | 30 |
| Steady Full / Reduced / Minimal enabled layers | 5 / 3 / 1 | 12 / 10 / 9 |
| Maximum during a quality crossfade | 6 | 13 |
| Extra render/Heartbeat connections | 0 | 0 |
| Lifecycle connections | 1 | 1 |
| Update caps Full / Reduced / Minimal | 30 / 15 / 5 Hz | unchanged |

The 21 additional instances are seven static three-instance cloud banks, reusing
the same image. Enabled layers include banks outside the current view. No texture
allocation/writes, physics, lights or remotes occur during updates. One optional
local cloud drift and restrained glow variation freeze with Minimal/Reduce Motion.
Moon weights and weather come from the existing EnvironmentView. Clock 1500s,
60/20/20 moon probabilities, Lighting and GlobalWind ownership are unchanged.

## Verification

`npm run tools` and `npm test`: **PASS — 1419 Luau + 34 Node = 1453 tests**;
308 Luau sources compiled, portable analysis and inherited builds passed.
New coverage checks alpha crops/edge softness, measured reference bounds,
opposite-facing projection, cloud-ring overlap, night/Minimal cloud visibility,
fixed resource budgets and existing lifecycle tests. Exact-HEAD Windows/Ubuntu
results and repeat-build checksum are recorded in the PR.

Ordinary F5 development run, Roblox Studio 0.748.0.7481526, 2026-11-18
17:07–17:09 Moscow time. Native probe place SHA-256:
`ff2749b328c510046d4a7cd2c244d6a67f902af26a2d23a46cc2be70e89c437e`.
This is the optional `--verify` build, not the final unprobed owner file.

- Server: 13 stations, V8, memory-only profile, owner 11924805007, 291 grass parts.
- Willow loaded successfully: 2 meshes, 2 images, 9 bones, 5783 triangles,
  selected root 2/crown 3. R1's mesh-budget blocker did not recur in this run.
- After ordinary starter camera transition, the probe ran with **Custom camera,
  unchanged FOV 70**. No test-selected familiar or Scriptable camera override.
- Landmark: four images/four writes, thirty instances/eight cloud banks.
- Day/dusk/night and pearl/blood/frost completed; 20 quality switches passed.
- Full/Reduced/Minimal settled to 12/10/9 enabled layers, Reduce Motion froze.
- Disposal/restart released all images and restored twelve saved Lighting/
  GlobalWind properties. `SKY_LANDMARK_PASS`, no CreatorError in this run.
- Moon-center separation: day 102.9°, dusk 85.3°, night 80.7°. This does not prove
  separation over every moment of the full 1500-second cycle.

| Local desktop sample, 90 frames/mode | Full | Reduced | Minimal |
|---|---:|---:|---:|
| Median frame ms | 4.071 | 4.027 | 4.049 |
| p95 frame ms | 5.290 | 5.466 | 5.106 |
| Sampled landmark update mean ms | 0.0211 | 0.0198 | 0.0187 |
| Total client memory MiB | 3058.1 | 3057.7 | 3059.0 |

Short local timings, not GPU render timings, phone performance or a controlled
R1/R2 benchmark. R1's incomplete willow run is unsuitable as a baseline. The log
also contains inherited external warnings: asset 203785492 type mismatch,
avatar wrap mesh fetch, CloudsUpsampleNoHistoryFS and disconnected Rojo localhost.
No new asset permissions/uploads were attempted to address unrelated warnings.

### Open art/manual/platform checks

The untouched startup camera looks down: its approximate crown bounds were
X 816–1927, **Y -126–350**, so the crown top is outside that initial view.
This is different from the supplied near-horizontal reference camera. The owner
must manually raise/rotate the normal camera to the reference view; this code
does not silently change FOV, look direction or screen-lock the background.
Matching that reference, complete foreground/cloud occlusion, perceived cloud
volume/no white wall, moon readability, a 360° sweep and walking around the
island remain **OPEN**, as does final art approval. No report screenshots/videos
were created. Computer Use observations were used to operate the old scene's
save/close dialog and inspect the running game; they are not art-QA deliverables.
The follow-up UI check selected and confirmed Green Slime through the ordinary
starter cards. The modal closed and the normal HUD/character appeared. The larger
tree was visibly behind the book, pine and willow, with its top cropped in the
startup view. This confirms basic foreground ordering at spawn, not full-route
occlusion or reference-camera acceptance. Attempted movement/camera keyboard
input instead selected Explorer rows, so walking/360-degree review is not claimed.
Mobile, multiplayer and real-backend checks: **NOT RUN**.

## Build, comparison and rollback

```text
node scripts/sky-landmark-r2-assets.mjs
node scripts/build-sky-landmark.mjs --owner-user-id=11924805007
```

Output: `build/PotionTycoon-SkyWorldTree-R2-QA.rbxlx`.
Owner copy: `G:\Codex\PotionTycoon-SkyWorldTree-R2.rbxlx`.
F5 is the normal game. Add `--verify` only for numeric time/quality/moon checks;
the owner build omits it. The diagnostic waits for Custom camera and loaded willow.

R1 comparison: `G:\Codex\PotionTycoon-SkyWorldTree-R1.rbxlx`, original SHA-256
`0cc1ea5287f19e23d463f7810d79f5808bfd7333fd2517c33c37b0ea4c42ebd4`.
The previous Studio session was saved before closing and preserved separately as
`G:\Codex\PotionTycoon-SkyWorldTree-SessionBackup.rbxlx`.
Source rollback: revision base above. Original R1 art/export recipe remain intact.

Production source, island geometry, 13 stations/26 routes, local tree modules,
economy, saves and existing mechanics have no diff against R1. No merge,
production integration, Roblox upload/access grant or publication.
