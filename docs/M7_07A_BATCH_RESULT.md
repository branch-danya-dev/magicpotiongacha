# 07A A1–A8 — one integrated candidate

Source base: owner documentation `62f0822`, following the partial implementation
`9d1dbe9`. Requirements: [batch specification](M7_07A_FIX_BATCH.md). This report
replaces the partial candidate as the current delivery; historical files stay intact.

**Code/asset changes are IMPLEMENTED for the whole package. Native rendering and
ordinary Play are NOT VERIFIED; technical acceptance is still pending.** There is
one final full-game build, no additional camera helper or media deliverable, and no
request for the owner to test intermediate changes. 07B/07C/08 have not started.

| ID | Cause and change | Available technical evidence | Final native status |
| --- | --- | --- | --- |
| A1 | Historical sky used the wrong lateral adjacency. Roblox's installed sky has `ft.R=lf.L`, not `ft.R=rt.L`. Regenerated our original CC0 sky with correct lateral/polar orientation; versioned `m7task07a-v1`, no stock pixels reused, no fog masking. | Read-only DDS diagnosis finds all 24 directed neighbor edges independently; closest mean error 0.318–1.044 RGB, next candidate >5. Historical project faces fail four joins by 48–53 RGB; replacement passes all 12 undirected joins exactly. New hashes/installer/CI artifact. | NOT VERIFIED in native renderer, including horizon, poles, filtering, six moods. |
| A2 | A center ray could miss initial sphere overlap. Before the native sweep, the complete near-plane sphere is moved outside conservative collidable part bounds and actual cached solid Terrain cells. Then one Spherecast starts from a clear volume. Inward correction is immediate, outward recovery damped. Respawn, camera type/camera object and large moves reset history. | Corner/edge/inside/tangent/negative-side overlap tests; actual occupancy buffer tests, indexing and cache bounds; existing near-plane/zoom/damping cases. Ordinary camera subject, rotation, Focus and character transparency are not replaced. | NOT VERIFIED: fast orbit, walls/slopes/mesh corners, natural movement, touch, tight-space character visibility and fallback. |
| A3 | Keep eight closed, overlapping ridge colliders. Add art-gated server recovery after escape beyond a six-stud exterior grace band, using the existing ownership-validated own spawn and cooldown. Recovery supplements physical boundaries. | 360 radial/diagonal crossings, all reserved routes/pads/spawns, ridge summits outside, lower/upper bounds and finite escape input tests. | NOT VERIFIED: real jumping/climbing, diagonal contact and visual fit of invisible boundaries. |
| A4 | Four walking blockers now follow rail yaw/projected length and overlap post endpoints. Explicit low-fence role separates these 3.2-stud decorative fences from the 80-stud outer barrier. | Fence/post extent and entrance-clearance tests. No new fence blockers; main entrance stays >25.4 studs wide. Jumping a low decorative fence is intentional. | NOT VERIFIED: native Humanoid walking/contact through each fence. |
| A5 | Retain avatar-based hysteresis/fading. Dynamic lights are bound to the actual emissive panes, with replication-order handling. Only six existing small lantern models are persistent; panes cast no self-shadow and never participate in nature LOD. | Slot handover/caps/midpoint/distance tests plus permanent visible pane tests. Geometry is independent of local-light count, including Minimal. | NOT VERIFIED: renderer culling/shading and fast 180/360-degree turns on real graphics tiers. |
| A6 | Production manual transitions use one forward phase for sun clock and celestial overlays. Independent weather controls do not reset the sun. One Studio-only request attribute feeds the existing owner; repeating it does not restart the timer. Post effects ease on quality changes. | All-hour clock inversion, forward day/night and sunset/dawn, weather retargeting, parser rejection/idempotent setters and frame-rate-independent easing. Existing automatic-cycle/seam tests retained. | NOT VERIFIED: perceived smoothness, native shadows/clouds, successive manual commands. |
| A7 | Preserve protected M6 gameplay/persistence and World topology. Extend existing server recovery only; no gameplay/UI/economy/remote/save-schema edits. | Full regression suite, protected-source hashes, original Factory layout, eight plots/worker routes/station pads, persistence/economy tests. | NOT VERIFIED in the final ordinary Play: spawning, Factory touch entry, build/upgrade/worker movement. |
| A8 | Keep geometry/texture/light/particle limits. Replace two casts per camera frame with at most one cast plus one bounds query; cache actual Terrain instead of reading it every frame. Smooth small post effects, enforce hard slot/particle caps immediately. | 1037 tests = 1012 inherited + 25 new, 139 compiled Luau sources, portable analysis, release and review builds; exact-head Windows/Ubuntu CI accompanies final artifact. | Manual 5/Automatic/full-game graphics and physical phone FPS/heat NOT VERIFIED/BLOCKED. |

## What was actually diagnosed

[Sky diagnosis](evidence/m7-07a-batch/sky-diagnosis.json) records the installed
Roblox version, all six vendor DDS SHA-256 hashes, edge matches and alternatives.
`scripts/diagnose-native-sky.py` reproduces that optional read-only calculation
with Pillow; vendor pixels are neither copied into the game nor committed.
`scripts/check-07a.mjs` decodes our PNGs and checks native edge pairs directly,
without importing the generator's ray mapping. The old sky is a negative control.
The new pack reuses project-authored CC0 art; old assets/evidence remain immutable.

This diagnoses a source/layout defect, **not a successful native rendering test**.
The earlier Studio UI failure/app-access timeout is not reclassified as a pass.
No successful final ordinary Play or new native captures are claimed. The owner
performs the single integrated pass below after receiving the assembled package.

## Bounded cost and limitations

- Art pool remains **1175 / 1320 Parts**, planning triangles **324957 / 465000**;
  four pre-existing fence fillers and unchanged gameplay anchors remain outside
  that historical art-pool count. No extra geometric props were added in this batch.
- Runtime textures **30.484 MiB / 32 MiB**: the corrected sky replaces six resident
  faces rather than adding another sky layer. Old files remain archival on disk.
- Dynamic light limits remain **Full 6 / Reduced 3 / Minimal 0**. No new lights,
  emitters or rain/mote slots. Six small lamp assemblies persist; no whole-pilot
  persistence or island-wide art expansion. Up to six temporary one-shot attribute
  listeners handle late pane metadata and are disconnected on teardown.
- Camera: **at most 1 Spherecast + 1 bounds query per active frame**, no center ray.
  Eight bounded overlap-resolution passes, with a last-safe fallback. Actual Terrain
  is read in a 128-stud cube (32768 cells) initially and after >16 studs of subject
  travel; persistent solid flags occupy **32 KiB**. ReadVoxels' temporary Lua arrays
  and native query cost have not been profiled on a phone. No performance claim.
- The cache assumes this build's startup-only, fully replicated Terrain; streaming
  remains explicitly off in the project. Future runtime Terrain editing/streaming
  needs invalidation before enabling it. Part bounds are conservative for MeshParts,
  so camera distance near holes/concave meshes may be greater than strictly necessary.
  Deep entombment or an unsolved overlap increments `CameraCollision.stats().unresolved`;
  final acceptance requires zero such cases on the specified routes. These are
  explicit risks to check, not hidden runtime passes.
- No paid assets, new remotes, saves, currency changes, commerce/trade activation,
  merge or publishing. Real device, experience asset permissions and live load
  remain BLOCKED. PR #17 stays Draft.

## Single owner acceptance pass

1. Open the one delivered `M7-07A-Batch-Play.rbxlx`, press F5. It is the ordinary
   game with Studio memory profiles and the existing real UI, no camera helper.
2. Check spawn, movement/jump, Factory entry, building/upgrades, stations and workers.
   Walk the pilot fences/entrance and outer boundary; try diagonal corners and jumping.
   Approach slopes while orbiting/zooming. Verify camera and character remain legible.
3. Use the existing quality controls: Full, Reduced, Minimal, Reduce Motion, plus
   Roblox Manual graphics 5/Automatic. At two or three lamps, turn quickly several
   times. A pane should stay visible even when Minimal intentionally disables lights.
4. For deterministic atmosphere checks, use Studio's **client** Command Bar during
   Play; send commands to the existing environment owner, not directly to Lighting:

   ```lua
   workspace.PotionTycoonWorld:SetAttribute("EnvironmentReview", "night")
   ```

   Replace `night` with `day`, `dawn`, `sunset`, `rain`, `afterrain`, or `time:18.2`.
   `weather:rain`, `weather:clearing`, `weather:afterrain`, `weather:clear` change
   only weather. Repeat requests and interrupt them halfway through the eight-second
   transition. `preview` runs the existing 45-second cycle; `auto` restores automatic
   time/weather. These inputs work only in Studio and are not saved or network remotes.
5. Inspect sky joins at 360 degrees, horizon and poles for all six moods. Record
   A1–A8 results and the build SHA in text. No screenshot/video deliverable is required.
   Any remaining native defect keeps that A-item open; only the integrated technical
   pass unlocks 07B. Final art approval still follows 07B/07C in 07D.

Technical references: [Roblox skybox construction](https://create.roblox.com/docs/environment/skybox),
[spatial query/initial-overlap behavior](https://create.roblox.com/docs/reference/engine/classes/WorldRoot),
[model streaming controls](https://create.roblox.com/docs/reference/engine/classes/Model#ModelStreamingMode).
