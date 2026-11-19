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

## Measured results

Complete raw summaries: [baseline](evidence/forest-p0/baseline.json),
[first iteration](evidence/forest-p0/iteration1.json),
[final candidate](evidence/forest-p0/candidate.json).
Final measured runtime: `2e8fd7eaf01a8701b17503ac813202daa5fe9097`,
forest code SHA-256 `e229c07f93cc359c1a37d743ae707301c46d49a0cd5ae00e08ccc6f7d57017c2`.
The instrumented place SHA-256 is
`92d96c8eefb86b6d1d73eb37895dc71eb337cb2838f6a92cd9b3f8fbb0abd46c`.
The ordinary owner build receipt is [measured-build.json](evidence/forest-p0/measured-build.json).

Each row covers 80 sampled seconds, with 19 waypoint arrivals and zero timeouts.
FPS below is `1000 / mean frame time`, not the median instantaneous FPS.
Frame times are milliseconds; stationary and moving samples are also separated
in the raw data, including all median/p95/p99 and stall-duration fields.

| State | Version | FPS | Median / p95 / p99 | Moving p99 | Frames >33.333 ms | Frames >100 ms |
|---|---|---:|---|---:|---:|---:|
| No new forest | Base | 240.0 | 4.10 / 5.23 / 5.69 | 5.69 | 0 | 0 |
| No new forest | Fix | 240.0 | 4.10 / 5.19 / 5.69 | 5.69 | 0 | 0 |
| Trees | Base | 190.3 | 4.09 / 5.48 / 56.41 | 57.69 | 313 | 0 |
| Trees | Fix | 226.9 | 4.08 / 5.25 / 6.04 | 6.13 | 98 | 0 |
| Trees + understory | Base | 190.5 | 4.10 / 5.43 / 55.27 | 56.86 | 319 | 0 |
| Trees + understory | Fix | 227.1 | 4.09 / 5.23 / 5.91 | 6.06 | 95 | 0 |
| Wind + R3 | Base | 191.3 | 4.11 / 5.52 / 54.96 | 55.86 | 319 | 0 |
| Wind + R3 | Fix | 226.5 | 4.10 / 5.27 / 5.99 | 6.15 | 99 | 0 |
| Wind + R4 | Base | 189.3 | 4.11 / 5.58 / 56.65 | 57.80 | 315 | 0 |
| Wind + R4 | Fix | 226.2 | 4.10 / 5.28 / 5.94 | 6.11 | 102 | 0 |

R3 full-scene >33 ms frames decreased 69.0%, mean FPS rose 18.4%, and moving p99
decreased 89.0%. This meets the bounded desktop p99 target, **not a zero-hitch
claim**: 99 >33 ms frames remain, with a 68.11 ms maximum. >100 ms traversal
stalls were not reproduced on this GPU even in the baseline; their removal
cannot be claimed. Stationary p99 remained approximately 5.6–5.9 ms.

The counters below are whole-scene 1 Hz samples. Drawcalls/triangles are means;
memory and nontransparent MeshPart candidates are medians. Memory is total
Studio process scene usage, affected by previous scene loads and garbage
collection; the difference is not a proven forest memory saving.

| State | Drawcalls base → fix | Rendered triangles base → fix | Mesh candidates base → fix | Memory MiB base → fix | Wind p95 ms base → fix |
|---|---|---|---|---|---|
| No forest | 98.9 → 99.1 | 213,166 → 248,487 | 210 → 208 | 3579 → 3320 | .032 → .036 |
| Trees | 143.1 → 126.8 | 316,018 → 312,010 | 386 → 316 | 3589 → 3319 | .034 → .035 |
| Understory | 244.7 → 151.3 | 346,790 → 322,136 | 666 → 431 | 3590 → 3317 | .034 → .036 |
| Wind + R3 | 249.6 → 156.6 | 346,443 → 321,399 | 666 → 431 | 3586 → 3312 | .407 → .312 |
| Wind + R4 | 252.1 → 159.6 | 345,638 → 321,935 | 672 → 437 | 3587 → 3317 | .425 → .328 |

R3 median render CPU was 2.69 → 2.22 ms. Restored native blades explain why the
no-forest triangle count increases. All 48 trees remain; 29 original skinned
instances are still allocated, but only the bounded nearest non-occluding set
renders them. 13 legacy plants add 20 static parts and 3,888 triangles, within
the inherited dressing cap. Static dressing: 318 → 338 parts (199 structural
parts eligible in Minimal before distance culling); 171 → 184 cover models.
The six merged LOD meshes reuse all three existing vegetation atlases (6 MiB
decoded total), with no additional texture. No new lights or animation loops.

### Initial load limitation

A fresh F5 scene reload reached forest readiness in 3.75 s, with 135 sampled
startup frames, one 435.65 ms frame, startup p99 74.48 ms. This is a real remaining
startup hitch. Mesh construction yields between batches, but engine resource
creation and the inherited whole-scene initialization can still stall. The
counter starts when the profiling LocalScript runs, so earlier engine/load work
is excluded. Baseline readiness was 2.30 s but had **zero sampled startup frames**;
it is not a valid before/after startup-latency comparison. This was a fresh scene
in the existing Studio process, not an OS/cache-cold launch. Do not mark the
initial-load freeze criterion passed.

### Extended session

[Five-minute evidence](evidence/forest-p0/soak.json): 300 sampled seconds,
67,230 frames, 82 waypoint arrivals, zero timeouts. Every 30 seconds switches
Full/Reduced/Minimal, Reduce Motion and day/dusk/night. Median/p95/p99 were
4.09/5.29/6.14 ms; 438 frames >33 ms, none >100 ms, maximum 72.49 ms. This retains
the same small LOD/visibility hitch limitation rather than proving perfectly
smooth traversal. Total process memory median/max 3049.7/3055.2 MiB; grove
resources remained 23 meshes, three images and 1,532 instances, one wind
connection. The 30 fixed allocations include the previously requested R4
experiment; no further allocations accumulated while toggling quality.
Camera/character and shared quality/motion settings restored after the run.

## Automated verification

`npm run tools` passed the pinned Luau 0.745 / Rojo 7.7.1 hashes. `npm test`
passed: **1,521 tests (1,473 Luau + 48 Node)**, including all 1,516 inherited
tests and five new LOD/clearance/profiling regressions; 334 Luau sources compiled,
portable analysis and the full Rojo build chain passed. Two pre-existing test
lint warnings remain; no new analysis errors. Production source/assets, original
sky/vegetation modules and default project are byte-unchanged from PR #64.

Runtime commit `2e8fd7e` passes Windows and Ubuntu
[CI run 44486018078](https://github.com/branch-danya-dev/magicpotiongacha/actions/runs/44486018078).
Final documentation HEAD, its CI and owner build hash are recorded in
[Draft PR #65](https://github.com/branch-danya-dev/magicpotiongacha/pull/65).

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

**CODE VERIFIED / STUDIO VERIFIED (scoped desktop scenarios) /
OWNER VISUAL REVIEW PENDING. Full P0 acceptance remains OPEN:** the initial-load
hitch and residual 33–73 ms LOD/visibility hitches are measured limitations,
not declared fixed. R4 still has its known trunk defect when explicitly enabled.

Real mobile device, multiplayer/server load, persistent DataStore/rejoin and
owner visual approval are not covered by this local scene. No merge, production
integration, Roblox publication, new asset upload or permission change.
