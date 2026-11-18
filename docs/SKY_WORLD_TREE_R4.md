# Sky World Tree R4 — isolated 2.5D depth prototype

**EXPERIMENTAL PROTOTYPE / OWNER ART REVIEW PENDING.** Native Play status is
reported separately below. No screenshots or video, generation charges, asset
uploads, merge, production integration or Roblox publication.

Branch: `feat/ag76b-sky-world-tree-r4-depth`. Exact base: Draft PR #61,
`c1689262ae73a06426a7308b02235b501cf6c167` (R3; Windows/Ubuntu CI 44328385986 PASS).
The branch is stacked on `feat/ag76b-sky-world-tree`, not main. The R3 sources,
builder, owner artifact and original art are retained unchanged.

## Structure and reproducibility

`assets/environment/sky-world-tree/r4/recipe.json` contains hand-authored regions
for the actual foliage and branch groups in the approved R2/R3 art. Offline
alpha masks partition that art into rear crown, middle branches and foreground
foliage, plus a sparse ridge highlight mask. RGB comes from the original image;
these are not complete copies shifted on top of each other. A central painted
trunk region is removed to expose the actual mesh. The original image remains
byte-identical. No new concept or third-party source is introduced.

`node scripts/prepare-sky-depth.mjs` reproduces the 1024² RGBA atlas, six authored
swept branch meshes and a provenance/hash manifest. The atlas has four padded
1008×240 regions. Meshes have smooth radial normals, overlapping roots, closed
ends and less than 2048 studs on every individual bounding axis. Six meshes,
280 vertices, 536 triangles; no individual leaves or micro-branches.
The installed game-dev CLI is unavailable; this uses the existing deterministic
local asset workflow, and does not claim a game-dev canonical-package receipt.

The crown centers are fixed in world space at +900 / 0 / −900 studs along the
landmark viewing axis. Their sizes compensate perspective at a fixed reference
eye `(0,6,20)` relative to PersonalIsland.origin. The central anchor and apparent
composition at that reference are the same as R3. The planes are BillboardGui
cards, so they face the viewing camera, but their anchors NEVER follow it.
No screen-position offsets or camera/FOV writes occur. Two additional cloud
wisps are placed at +460 and −1180 depth; the original eight-bank ocean stays.
All cards use AlwaysOnTop=false. Native transparent sorting/occlusion still
requires inspection, particularly against the 3D trunk.

The trunk is six local-only EditableMesh/MeshPart pieces bridging the planes.
It uses the built-in Wood material, native scene illumination and restrained
color from the existing R3 sun/moon light projection. Rear foliage is cooler
and darker; front foliage has a separate local ridge highlight. Pearl, Blood
and Frost reuse existing lighting weights; no second clock or light owner.

`scripts/build-sky-depth.mjs` composes an adapter around the R3 renderer only.
The generated R3 EnvironmentView is referenced unchanged, with its SHA recorded
in the build receipt. Production `src/`, quality settings, GlobalWind, 1500s
clock, lunar 60/20/20, V8, 13 stations, routes, spawn and economy are unchanged.
The sharp horizon is an **unresolved R3 defect**, outside this task.

## Cost relative to R3

| Resource | R3 | R4 Full / Reduced | R4 Minimal |
| --- | ---: | ---: | ---: |
| Landmark-owned instances | 45 | 71 (+26) | 71 pooled; R4 hidden |
| EditableImages | 4 | 5 (+1 atlas) | 5 retained for switching |
| Decoded RGBA texture bytes | 6,553,600 (6.25 MiB) | 10,747,904 (10.25 MiB) | same allocation |
| Added mesh resources / parts | 0 | 6 / 6 | retained, invisible |
| Added vertices / mesh triangles | 0 / 0 | 280 / 536 | not drawn |
| Extra canopy/cloud cards | 0 | 6 | disabled |
| Maximum visible image labels | 16 including transition | 17 | inherited R3 cap |
| Update limit | 30 / 15 / 5 Hz | same owner cadence | 5 Hz, R3 visuals |
| New frame connections / lights | 0 / 0 | 0 / 0 | 0 / 0 |
| Texture writes | 4, initialization only | 5, initialization only | no new writes |

Added objects: folder1, fixed anchors5, BillboardGui5, ImageLabel6,
UIGradient3, MeshPart6 =26. Editable resources are counted separately.
536 is the authored mesh triangle count; the engine's UI tessellation is not
included. Base64 source adds about 5.33 MiB of Lua string data; initialization
also allocates temporary encoded/decoded buffers. Thus 4 MiB is **not** a claim
about total client-memory growth. Actual device memory/FPS remains unmeasured.

All additional allocations occur once. Mode/quality changes only enable/hide
the pool; no repeated image/mesh creation. Partial allocation failure releases
the R4 pool and leaves R3 visible, with `SKY_DEPTH_FALLBACK` and a reason.
Owner cleanup releases R4 before R3. Minimal selects R3 immediately. Reduce
Motion retains the existing R3 motion freeze; parallax is natural perspective,
not an extra animation. Retained R4 memory in Minimal is a deliberate prototype
tradeoff for instant comparison, not a mobile optimization claim.

## Build and ordinary Play

```powershell
npm run tools
npm test
node scripts/build-sky-depth.mjs --owner-user-id=11924805007
```

Output: `build/PotionTycoon-SkyWorldTree-R4-Experimental.rbxlx`; exact HEAD,
artifact hash, R3 comparison hash and EnvironmentView hash are in
`build/sky-depth/build.json`. Ordinary gameplay, memory-only Studio profile,
explicit owner, no forced camera or automatic test sequencing. Optional
`--verify` enables bounded textual diagnostic checks after the player normally
chooses a familiar. It is a separate development artifact.

For an A/B comparison, use the **client** Command Bar during ordinary Play:

```lua
workspace.PotionTycoonWorld.SkyLandmarkQA:Invoke("pose", "dusk")
-- Wait for the inherited lighting transition, then compare without moving camera:
workspace.PotionTycoonWorld.SkyLandmarkQA:Invoke("depth", "R3")
workspace.PotionTycoonWorld.SkyLandmarkQA:Invoke("depth", "R4")
```

Other actions: `pose` day/dusk/night (nil restores the clock), `moon`
pearl/blood/frost/auto, `quality` full/reduced/minimal, `motion` true/false,
`check` for the bounded numeric/timing suite. `Invoke("stats")` returns state.
No remote or game UI is added. Mode R3 restores the underlying R3 visual
composition at its evolving time/phase; it does not reset the weather.

The native probe measures 120 frame intervals and distinct owner updates for
R3/R4 in every quality, then checks poses and moons. It preserves the camera
and restores the selected mode, quality, motion, pose and moon override. Timing
comparison is meaningful only with the same camera/load. GPU render timing,
phone behavior and visual depth are not inferred from the probe.

## Evidence and open checks

- Automated: `npm run tools` and the complete local `npm test` PASS: 1,434 Luau
  +37 Node =1,471 tests, 313 compiled sources and inherited builds. The final
  directional-accent refinement was then compiled and all 9 R4 Luau tests passed
  (one additional test); the current complete suite contains 1,472 tests. Exact
  HEAD Windows/Ubuntu results are recorded in the Draft PR. New coverage tests reference framing,
  natural island-scale parallax, upright basis, cloud depth ordering, quality/
  fallback selection, continuous light and inherited moons; Node checks reproduce
  every asset byte, independent alpha silhouettes, closed nondegenerate meshes,
  per-part limits and resource budgets.
- Native attempt: the existing R3 Studio window was found and its file dialog
  read without a capture. Filename set-value had no observed effect; clicking
  returned `coordinate input geometry is unavailable`. Keyboard attempts did
  not change the observed dialog. No new Studio window was launched.
- **R4 Play/actual rendering/performance: NOT RUN**, awaiting a working native
  launch. No report may label this prototype Studio Verified from CLI results.
- No screenshots/video were taken. Walking at the island edges, rotated views,
  daylight/dusk/all moons, transparency/mesh intersections, owner cleanup and
  visible quality switches remain native checks. Phones/multiplayer NOT RUN.

## Visual limits to review

This is a depth-card prototype, not a fully modeled tree. Cards turn to face the
camera; extreme off-axis views can expose layering. The fixed reference matches
framing analytically; other camera pitches differ from a single R3 billboard.
Natural parallax is deliberately unamplified: a 124-stud traverse gives roughly
8 projected pixels of front/back separation at focal length1000; whether that
is visually strong enough is an owner art gate. Each atlas strip has 240 vertical
pixels versus the original 370-pixel crop, so fine details may soften.

Central mask-to-trunk joins, overlapping smooth tubes, cloud depth sorting and
seams exposed by motion must be reviewed in Play. No claim is made that the
flat-image impression or the inherited horizon defect has been resolved.
