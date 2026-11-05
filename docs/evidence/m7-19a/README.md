# Task 02 / #19a — continuous island landscape

**TASK_02_REVIEW_PENDING.** Implemented for the owner's visual review in ordinary
full-game Play. PR #17 remains Draft. Tasks 03–07 have not started; decorating the
other seven farms (08) still requires explicit final-pilot APPROVED after 07.
Earlier atmosphere Gate A approval does not approve this island.

## Visible result and preserved gameplay

One native Terrain island now surrounds the existing 4×2 farms and central bazaar.
Seven blended hill masses, sloping coast, sand and water replace the exposed common
rectangular base. Farm origins, station/pad/spawn positions and bazaar remain exact.
The common ForestFloor is invisible but retains its existing collision/friction.
Plot clearings, central approach and southern walking loop have protected clearance.
The generator fills empty voxels only, with no clearing of pre-existing Terrain.
No profile, economy, remote, production or trading changes; no new asset imports.
The existing atmosphere pipeline, quality tiers and pilot decoration are retained.

Individual farm plates and the rectangular bazaar path remain visible: their
integration belongs to task 03. This is the island substrate, not the completed
eight-farm artwork. Only the historical pilot remains decorated.

## Exact builds and ordinary launch

- Runtime: `8eb1cfe89d1965061f029fdbc3d7f142c9411853`.
- Plain delivery: `M7-19a-Play.rbxlx`, 468665 bytes, SHA-256
  `1e9d717b504c228fad27322ad9b0342606e607f7a0511e493098545a0655afcc`.
- Recorded QA build: `M7-19a-candidate-v2.rbxlx`, SHA-256
  `56fb1aa3762e33dea651c8492260a7aa187934aaf40792cf0254e08fec0cc562`.
- Baseline runtime: `c0c1912185ea19bfbae5755d717e2da8fdec2b93`, task 01.
  Its plain historical file is unchanged. The comparison adds camera/audit helpers
  to that file; all 50 baseline runtime scripts match the named commit.
- All **52 runtime scripts** in both new places match the runtime commit, except
  the documented Studio-only art enablement in ServerSettings. QA scripts were
  also compared to their committed source. [Hashes and camera audit](captures.json),
  [immutable source snapshot](source-snapshot.json).

On the prepared review computer, open the plain file and press **Play** once.
No diagnostic mode or command is needed. This was actually done in Studio;
[plain Play screenshot](plain-play-desktop.jpg) shows the normal cycle at night.
Progress is in memory; purchases and trading stay off. Do not publish.
On another computer, the inherited local atmosphere textures still require the
[existing setup](../../M7_A2C_ATMOSPHERE.md). This is not proof of experience permissions.

Rebuild: `npm run tools`, `npm test`, `node scripts/build-local-preview.mjs`.
Open `build/PotionTycoon-M7-LocalPreview.rbxlx`. CI includes this plain preview.
For reproducible full-game QA only, add `--island`: F8 resets the actor/camera,
F6 advances the viewpoint, L changes pose smoothly, J runs the walking route,
P logs the current camera. The helper keeps the native HUD visible and grants
no resources. These helpers are absent from the plain delivery.

## Actual screenshots and video

Windows Roblox Studio **0.746.0.7461264**, one local player, default **Reduced**,
desktop game viewport **2113×1113**. Native graphics manually verified at 5 and 10.
Day is held constant by the optional helper for comparison; ordinary Play uses
the existing continuous day/weather cycle. No image retouching or generated frames.

| View | Graphics | Before | After |
| --- | --- | --- | --- |
| Pilot spawn | 5 | [before](before-spawn-g5.jpg) | [after](after-spawn-g5.jpg) |
| Central bazaar | 5 | [before](before-bazaar-g5.jpg) | [after](after-bazaar-g5.jpg) |
| West edge | 5 | [before](before-west-g5.jpg) | [after](after-west-g5.jpg) |
| Pilot spawn | 10 | [before](before-spawn-g10.jpg) | [after](after-spawn-g10.jpg) |
| Central bazaar | 10 | [before](before-bazaar-g10.jpg) | [after](after-bazaar-g10.jpg) |
| West edge | 10 | [before](before-west-g10.jpg) | [after](after-west-g10.jpg) |

Spawn and bazaar have **identical logged CFrames** at both qualities. At the west
edge, the native Custom camera settles **0.09375 stud higher** after the change;
orientation, zoom and XZ are identical. That pair is a near-match, not pixel exact.
Settings: [before 5](before-settings-g5.jpg), [after 5](after-settings-g5.jpg),
[before 10](before-settings-g10.jpg), [after 10](after-settings-g10.jpg).

Supplemental zoomed-out Play views: [before 10](before-wide-g10.jpg),
[after 10](after-wide-g10.jpg), [after 5](after-wide-g5.jpg). These share direction
and player position, but Terrain causes native camera collision to reduce the
candidate's distance; **they are not matched-camera comparisons**. They expose
the shoreline, all eight preserved farm pads and the distant water limitation.

[Actual 80-second Play recording](19a-island-walk.mp4): pilot → central bazaar →
east side → southern approach → opposite farm → east edge. Manual graphics 5,
Reduced, normal UI and real Humanoid physics. One setup teleport returns to the
starting point before walking; **no teleports during the 15 walking segments**.
All 15 report `reached=true alive=true` in the [project-only Studio audit](studio-audit.txt).
This is the first continuous 80 seconds of a native 317.35-second recording;
only the subsequent idle tail was removed. H.264 recompression/downscale to
1280×670, audio/metadata removed; no internal cuts, speed changes or generated
frames. The native file hash is retained in the manifest.

An earlier diagnostic route aimed through an existing station on plot 8 and
timed out. The final helper approaches from the free southern side. No station
or gameplay coordinates were moved to make the route pass.

## Validation and terrain budget

**922 tests passed, 0 failed**: all 907 inherited plus 15 island cases. Compilation
of 109 Luau sources, portable analysis and Rojo builds passed. [Local log](verification.log).
[Runtime CI: Windows and Ubuntu PASS](https://github.com/branch-danya-dev/magicpotiongacha/actions/runs/42067114186).
Tests cover all eight origins, pads/stations/spawns/worker routes, safe approaches,
dry old collision footprint, organic coast, continuity, materials, voxel-aligned
nonoverlapping tiles and bounds. Existing M1–M6 regressions and World contract pass.

Studio Terrain-only raycasts checked **2888 points** across all eight plot footprints:
highest ground **-0.4062538**, below the floor top 0.5. All world anchors pass;
base hidden/collision retained. The normal plain build also started successfully.
The walk covers representative cross-island access, not every station interaction.

The old pilot field is replaced by a larger startup-only island budget:
**1,082,880 cells visited, 675,289 filled** in a fresh world, **28,672 cells maximum
per write**, hard total cap **1,100,000**. Native 4-stud resolution, 128-stud XZ
tiles, a Heartbeat yield between writes. No per-frame Terrain writes or new props,
particles, textures or dynamic allocations. One final QA run measured **4.197s**
for island creation. This is a single desktop startup observation, not a frame-rate
benchmark or mobile acceptance. Terrain memory/replication cost needs device/load QA.

## Remaining defects and limits

- The finite water rectangle is visible at very distant zoom. Normal walking
  views are surrounded by relief/water; the extreme overview horizon is unfinished.
- Farm plates, straight bazaar paving and their exposed edges remain for task 03.
  The green pilot plate is intentionally still present. Final world-wide removal
  of the platform appearance is the checkpoint after task 03.
- Hills are sparsely dressed outside the pilot, native grass texture is repetitive;
  volumetric grass, replacement forest and deeper dressing belong to tasks 04/05/08.
- Station blocks and other inherited greybox props remain for task 07. Existing
  UI limitations, mixed RU/EN labels and distant foliage/terrain shimmer remain open.
- No live repeat of Full/Minimal/Reduce Motion, all weather states, complete M1–M6
  progression, swimming, full coastline traversal, every station interaction,
  second player or reconnect in this task. Existing automated coverage is retained.
- Physical smartphones, Roblox experience asset permissions and multiplayer load:
  **BLOCKED**. No merge, publishing, purchases or public trade activation.

Historical [task 01](../m7-18a/README.md), [UI](../m7-ui18/README.md) and
[atmosphere](../m7-a2c/README.md) evidence is preserved. Visual acceptance is the
owner's decision, not inferred from tests or these captures.
