# ISLAND-FOREST-P0

Base: PR #64, `a1bb4edf76df6f631512256b520128fc0fdf3062`.
Branch: `fix/island-forest-p0`. Studio-only, memory-backed QA build.

## Diagnosis

- PR64 reduced Terrain GrassLength from .24 to .14 and replaced the central
  clearing's Grass with LeafyGrass. The latter removes native grass blades.
  Its unconditional `inPilot` also excluded all inherited decorative clusters.
- In real Studio Play, the R4 trunk region shows the background sky through the
  tree: pale by day, dark at dusk/night. R3 at the identical camera has the
  intact painted trunk. This is not an island tree occluding the World Tree.
  The R4 atlas explicitly cuts that region out for its distant 3D limbs; this
  composition does not fill the cut in the tested view. Exact engine-side
  clipping/blending cause is not claimed proven. R3 is the safe default;
  experimental R4 and its original inputs remain intact and defective.
- Baseline stationary medians hide regular movement spikes. The tree-only
  traversal has a roughly 56 ms p99, while no-forest is about 6 ms. Wind disabled
  does not remove those spikes. Frequency is consistent with the existing 5 Hz
  skinned-part visibility writes; wind CPU samples are far smaller.

## Candidate

- Restore native grass height .24 and broad Grass/moss distribution. Preserve
  paths, stations and work endpoints as Ground. Validate legacy plants by whole
  footprint and skip duplicates/root overlaps; one writer owns surviving plants.
- Keep 184×172 and all 48 authored tree placements. High-detail skinned trees
  are bounded to 8/4/1. Further trees use two merged unskinned meshes per source
  variant, borrowing the original atlas; no new asset or upload. Main crowns,
  trunks and roots remain, secondary cards are near-only. Distance/rank
  hysteresis avoids swaps around equal distances. Understory has distance caps.
- Skip unchanged transparency writes; use the existing 5 Hz visibility poll
  and one bone scheduler. Split expensive mesh construction into yielding batches.
- Camera-obscuring crowns use their unskinned silhouette for local fading;
  skinned parts are either fully shown or hidden. A one-second hold prevents
  oscillation at the camera/crown boundary. This is the second and final measured
  optimization iteration; the first reduced spikes but retained a 48 ms movement
  p99, so it is not the final candidate.
- Lazy-load R4 only on explicit QA selection. Default fixed mesh resource cap
  stays 24 (17 original skinned + 6 static LOD + 1 cliff); experimental R4
  adds 6 meshes and 4 MiB of decoded pixels on demand, peak 30 fixed meshes.

## Measurement method

Windows Roblox Studio 0.748.0.7481526, D3D11 NVIDIA GeForce RTX 5070 Ti
(approximately 16 GB VRAM), viewport 2095×1095, FOV 70, manual Play graphics 5.
Same open Studio window, Reduced scene quality, a real character and familiar.
Five controlled states, each 10 s warmup + 80 s sampled: 15 s stationary,
65 s Humanoid movement through west/east/north/south paths with camera turns.
No builds or full test suites run during sampling. Other desktop applications
were not closed; this is a desktop Studio comparison, not a mobile benchmark.

The no-forest case hides the new 48-tree stand and its understory, retaining the
base ground cover, terrain, island and game. Drawcalls/triangles are the engine
scene counters; visible MeshParts means nontransparent candidates in Workspace,
including offscreen parts. Those are deliberately different metrics.
CPU render times and scene counts use the [Roblox Stats API](https://create.roblox.com/docs/reference/engine/classes/Stats).
Frame quantiles use every RenderStepped sample; freezes mean frames over 100 ms,
with >33.333 ms counts also retained. One-second resource/wind samples are not
substituted for per-frame latency.

Reproduce: build the owner QA scene, then `node scripts/build-forest-profile.mjs Candidate`.
In ordinary Play choose a familiar, then invoke
`workspace.PotionTycoonWorld.ForestPerfQA:Invoke("run","candidate")` in the client
Command Bar. `"soak"` runs five minutes of movement and quality/motion/time changes.
The bounded harness restores the normal camera, character, quality and tree mode.
`scripts/forest-profile-report.mjs` exports only the task's measurement JSON,
never the raw Studio log. The game-dev CLI/adapter is unavailable on this host;
these are native Studio measurements, not a sealed game-dev run.

Results and final verification are pending the candidate run.

## Functional checks already observed

Ordinary F5, normal familiar selection, native GrassLength .24/Decoration true,
48-tree scene and an unobstructed walk from spawn to the book. A normal click
advanced the tutorial and increased Essence from 0 to exactly 5. The server's
read-only scene check verifies all 13 original station positions and V8/memory
isolation. Station production/accounting is covered by the inherited regression
suite; a fresh full progression playthrough of all 13 machines is not claimed.
Twenty quality/motion switches passed root, bone reset, no-collision, one-scheduler
and constant allocation/instance assertions. Day and night Minimal were visually
inspected using technical window captures only, with no report images/video saved.

## Open gates

Real mobile device, multiplayer/server load, persistent DataStore/rejoin and
owner visual approval are not covered by this local scene. No merge, production
integration, Roblox publication, new asset upload or permission change.
