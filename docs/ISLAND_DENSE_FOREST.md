# Expanded forest candidate — 2026-11-19

**CODE CANDIDATE / STUDIO VERIFIED (desktop scope below) / OWNER ART REVIEW PENDING.**

Owner requested a larger island with dense woodland except the centre. This
explicitly replaces the preceding five-tree trial scope. Branch
`feat/island-dense-forest`, exact base Draft PR #63
`2cbc8d5b970d086ffe41bd3081a39ac68b519107`. It is a stacked Studio-only ordinary-game
candidate; the former Grove Art Pilot remains available for rollback/comparison.

## Layout

The nominal island increases from 124 x 116 to **184 x 172 studs** (2.20x area).
One continuous cliff, terrain density and server traversal use the same irregular
outline. There are **48 trees** in staggered inner/outer banks on all four sides:
29 instances of the prepared stefan Natural/Windswept and Igor magical trees,
19 existing Quaternius conifers/broadleaves. Heights, yaw, crown shapes and depth
vary. The northern view corridor to the World Tree stays open. Four six-stud
forest approaches have no trunks or new understory footprints on them.

**171 understory models and 23 root stones** form asymmetric pockets. Structural
shrubs/ferns survive Minimal. The central construction rectangle and the route to
the book remain open; the centre uses low moss/ground cover instead of tall native
blades. The decorative waterfall moves 28 studs east to the expanded shore.
The 13 station offsets, worker paths, spawn, service points and book do not move.

No production module or original asset is edited. The builder generates candidate
adapters for PersonalIsland, terrain/cliff, grass, water placement, visibility and diagnostics.
The larger traversal area does not expand persisted construction rights: core,
buildable rectangle, V8 schema, economy and profile persistence are unchanged.
No unlock price, paid expansion, new remote, Lighting owner or time system.

## Resources and source rights

Uses the same CC BY 4.0 stefan/Igor sources and existing CC0 Quaternius templates
documented in `ISLAND_VEGETATION_PILOT.md` and vegetation-v2 `ATTRIBUTION.md`.
No new downloads, images, Roblox uploads, permission changes or paid jobs.

| Resource | Previous pilot | Expanded forest |
| --- | ---: | ---: |
| Trees | 5 | 48 |
| Understory / stone models | 40 / 16 | 171 / 23 |
| Planted rigged geometry, triangles | 14,434 | 112,600 |
| Static trees / dressing, triangles | 19,780 | 94,503 |
| Total planting triangles | 34,214 | 207,103 |
| Static MeshParts | 75 | 318 |
| Static parts retained in Minimal | 34 | 193 |
| Retained tree EditableMeshes / images | 17 / 3 | 17 / 3 |
| Decoded tree atlases | 6 MiB | 6 MiB |
| Shared fixed meshes incl. cliff / R4 | 24 | 24 |
| Concurrent expandable scratch meshes | 1 | 1 |
| Animated trees Full / Reduced / Minimal | 3 / 2 / 1 | 8 / 4 / 1 |
| Wind update Hz | 24 / 12 / 5 | 24 / 12 / 5 |
| Added lights / frame loops | 0 / 0 | 0 / 0 |

More rendered clones cost skinning, draw calls and instances despite identical
source pools. The 6 MiB figure excludes mesh buffers, Lua data, instance overhead
and engine caches. This is not a measured mobile memory/FPS guarantee. Shared
nearest-tree scheduling, distance fades, Reduce Motion and inert collisions remain.

Native walking exposed a camera enclosed by a conifer canopy. Candidate-only
occlusion adapters now fade tree parts intersecting the camera-to-character
segment. Static parts keep EnvironmentView as their only visibility writer;
skinned trees keep Grove's existing 5 Hz poll. The same pure box rule uses actual
prepared vertex bounds for skinned parts, scaled with each instance. There is no
camera movement override, raycast loop, new texture or permanent tree removal.
Opacity restores when the view clears; non-forest visibility remains unchanged.

A fresh Play exposed a terrain replication race: server ready attributes could
arrive before client terrain, causing the first root raycast to abort all skinned
trees. The candidate now waits for native support at all 29 authored roots before
allocating the source pools. Startup has a shared 20-second deadline and cancels
when the scene is removed; unsupported ground still fails explicitly. Portable
tests cover delayed arrival, permanent failure and cancellation.

## Reproduction and verification

```powershell
npm run tools
npm test
node scripts/build-forest.mjs --owner-user-id=11924805007
```

Output: `build/PotionTycoon-Dense-Forest.rbxlx`, receipt `build/forest/build.json`.
Convenient owner copy: `G:\Codex\PotionTycoon-Dense-Forest.rbxlx`.
Open in the existing Studio window and F5; the world is created at runtime.
It is the ordinary game with familiar choice, HUD and server book. QA profiles
are memory-only and cannot reach live persistence. Automatic owner/server checks
verify the 13 unchanged anchors, one book, dimensions and V8. The same
`LandscapeQA` / `CurrentGameQA` controls from the predecessor remain available.

Added tests cover expanded coastline/traversal agreement, preserved construction
rights and station offsets, woodland coverage/depth, supported roots, inter-trunk
spacing, four clear approaches, understory budgets and shared 8/4/1 wind caps.
Asset tests read actual prepared meshes, validate crown envelopes and distinguish
rendered instance triangles from unique resource pools. All inherited tests remain.

The suite now contains **1,516 tests** (1,468 Luau + 48 Node), all 1,505 predecessor
tests retained. Pinned tools passed; final full-suite and exact-HEAD Windows/Ubuntu
CI outcomes are recorded in the PR. Two inherited C01 analyzer warnings remain.

First native run (before occlusion correction): 48 trees, 318 static parts,
29 skinned instances / 1,416 descendants; 24 compact allocations / zero failures.
Character MoveTo traversal reached relative (-35,20), (-68,20), (-68,-6), with
endpoint errors below one stud and no boundary reset. This tests native Humanoid
movement, not manual WASD/touch input. 20 quality/motion switches passed with
stable pools, fixed roots, inactive collision flags and one wind connection.
120-frame desktop snapshots: Full p95 6.01 ms, Minimal p95 5.19 ms; total Studio
client memory around 3,008 MiB. These are short in-editor samples at one viewpoint,
not isolated grove cost, a controlled before/after benchmark or phone performance.

Final fresh native Play on 2026-11-19 (local time), with both corrections:

- Runtime code SHA-256: `f369f815b6adb723bdb09b06f72545f56d0676dac95ca1bc525279ef8e1614c3`.
- All 48 trees loaded: 29 skinned / 1,416 descendants plus 318 static parts;
  17 source meshes, three images, 24 compact allocations, zero allocation failures.
- Ordinary familiar selection succeeded; all 13 station anchors and V8 checks passed.
- The same three native movement endpoints were reached with errors below one
  stud. No reset at the former smaller boundary. No manual touch/WASD coverage.
- 20 quality/motion switches passed with stable resource counts, roots and collision
  flags. Full / Reduced / Minimal and Reduce Motion were exercised. Minimal night
  was inspected from the forest; the centre was inspected in Reduced daylight.
- At the previously obstructed viewpoint the character and path were visible;
  14 tree parts were faded. On return to the centre the camera stayed Custom and
  the occlusion rule reported zero obstructing parts.
  Quality/distance LOD fades remain independent of camera occlusion.
- Short 120-frame samples in the forest: Full frame p95 6.10 ms, Minimal 6.06 ms;
  total Studio client memory about 3,182–3,183 MiB. Full wind last sample 0.71 ms,
  Minimal wind p95 0.152 ms. This is not a controlled performance comparison.
- The expanded game was left running in the existing Studio window, with the
  character on the open central approach, Reduced and the normal time cycle.

Remaining visual limits: repeated source species, contrasting dark conifers and
lighter broadleaves, conservative box-based camera fades, and the inherited World
Tree/horizon composition still need owner review. The inherited warning for
`rbxassetid://203785492` (asset type mismatch) remains, outside forest source pools.
The failed intermediate startup is documented above; it is not counted as a pass.
Final artifact SHA-256 and exact commit are recorded in the build receipt and PR.
Physical phones, multiplayer, live backend and owner art acceptance remain open.
Technical Studio images are for diagnosis only; no report captures/video produced.
No main integration, merge, Roblox publication or automatic art acceptance.
