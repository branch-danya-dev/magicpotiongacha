# 07C — pilot landscape and distant landmarks

## Scope and acceptance

The owner explicitly requested 07C on 2026-11-06 after delivery of 07B `7aa500e`.
07A `04d3aea` remains owner accepted. This step implements the composition of the
single pilot and its northwestern outlook; it does not approve the new woodland
or close the final 07D art gate. PR #17 stays Draft. No purchase, asset upload,
publication, merge, UI redesign, economy/save change or seven-farm art rollout.

**07C IMPLEMENTED in code/build; native appearance NOT VERIFIED.** One ordinary
full-game Play file is supplied. Screenshots, videos and new camera helpers are
not deliverables, per the owner's continuing instruction.

## Composition

- Five compact, overlapping outer ridge crests reach **42–47 studs** on the west
  and northwest. Rock shoulders interrupt the grassy slopes. Their influence is
  exactly zero inside the accepted traversal polygon and its four-stud exterior
  margin. The common roads, eight plot footprints, spawns, stations and workers
  keep their existing ground. Island dimensions, ocean, resolution and write
  volume remain unchanged. This is local outer terrain sculpture, not rebuilding
  the eight-farm island.
- **Seven static canopy silhouettes** fill the rear layer behind the 29 whole
  Quaternius trees. They use the existing foliage meshes, partly embedded in the
  ridges, with no unseen trunks or new sphere proxies. The combined tree count is
  **36**, preserving the existing cap. A gap between the ridges frames the northern
  landmark. Ten exposed rock meshes add shelves; twelve small fern/clover/grass
  pockets connect the rougher ground to the existing woodland.
- Two offshore rock stacks carry **original fantasy watchtowers**, one to the
  north and one across the western water. Pitched roofs, narrow windows, gallery
  bands and buttresses create a readable distant outline using fifteen native
  Parts per tower. A ten-Part broken gate sits on the western ridge. These are
  inert scenery, not entrances, stations or climbable gameplay structures.
- The existing moon sprite grows from **44 to 62 studs** at the same celestial
  distance and follows the unchanged time/weather path. No second moon, new
  image, asset ID or copied franchise design is introduced. Tiny distant windows
  blend from the approved blue to amber with night and rain; they add **no lights**.
- Three existing mist pockets, four motes anchors and two warm light pools are
  repositioned around the forest edge and clearings. Wind, fireflies, pollen,
  cloud/rain/after-rain behavior, lantern allocation and exposure/bloom curves stay
  as accepted in 07A. Vista materials reuse the existing palette. The pilot's
  ground dressing, compound station models and build affordances are retained.

## Grounding, visibility and ownership

`RidgeComposition` is a pure startup terrain modifier. `VistaPlan` supplies a
deterministic 75-Part backdrop. `VistaArt` runs once and samples actual generated
Terrain for grounded objects; it does not assume the mathematical height equals
Roblox's voxel surface. The ruined gate shares one sampled foundation so its
lintel and columns stay aligned. Offshore stacks have fixed underwater bases.
All new props are anchored, noncolliding, nonqueryable, nontouchable and shadowless.
Full yaw/roll bounds of every prop are separated from the traversal contour by
at least six studs. Accepted camera/fence/boundary/recovery code is unchanged.

The existing **single EnvironmentView** owns quality fades and six window colors;
there is no added frame connection, per-prop script, emitter, remote or persistent
field. Distant canopies remain static and do not consume wind slots. Core forms
remain visible from the pilot on Full, Reduced and Minimal. Detail/ground fade
earlier and are hidden on Minimal. Visibility uses a 45-stud smooth fade band and
the inherited time-based alpha easing. Stop restores each prop's previous color
and local transparency; inherited atmosphere ownership/restoration remains exact.

Startup work adds bounded terrain calculations and cached downward grounding
rays. Runtime adds up to 75 visibility checks every half second and 75 small fade
records in the existing throttled update, including six window color writes.
No runtime mesh/map churn, new shadows or unbounded instance pools are added.

## Cost and verification

| Measure | 07B | 07C | Existing cap |
| --- | ---: | ---: | ---: |
| Nature/backdrop art Parts | 675 | 751 | 850 |
| Nature/backdrop triangle planning charge | 182040 | 199918 | 300000 |
| Whole pilot art Parts including eight ridge blockers | 1097 | 1173 | 1320 |
| Whole pilot triangle planning charge | 246032 | 263910 | 465000 |
| Resident texture estimate | 30.484 MiB | 30.484 MiB | 32 MiB |
| Terrain cells visited by the existing tile writer | 1082880 | 1082880 | 1100000 |

The separate vista costs **75 Parts / 17536 triangles**. A previously submerged
existing boulder site becomes dry after terrain sculpture, so ForestPlan admits
one extra boulder (**12 rather than 11**, +1 Part /342 triangles). This explains the
complete +76 /17878 delta. No hidden geometry is omitted from the art ledger.
Mesh triangles are source counts; native Part charges are planning estimates,
not GPU measurements. Inherited fence fillers, gameplay anchors, Terrain, UI and
weather pools remain outside the historical art count, as in prior reports.

Full/Reduced/Minimal light caps remain **6/3/0**, moving canopies **12/4/0**,
moving meadow plants **64/32/0**. Reduce Motion still stops environmental movement.
Fog, motes, rain and stars retain their existing pools. All 14 admitted CC0 models,
21 template meshes, IDs, maps and eleven smooth-alpha template settings are
byte-for-byte unchanged; the original and woodland receipts still verify.

**1062 tests** retain all **1045** inherited scenarios unchanged and add **17**
07C cases. They cover protected terrain and support continuity, dry foliage,
rotated prop clearance, complete triangle/Part accounting, coherent ruins,
underwater rock bases, quality fades, time/weather window continuity and limits.
An additional integrity check freezes **84 source/test hashes** from 07B and
permits only precise FarmGround/AtmosphereStyle insertion seams. Accepted sky
topology, camera, fence, light, transition, factory and release defaults remain
protected. All **145 Luau sources** compile; portable analysis and both Rojo
projects build. Exact-head Windows/Ubuntu results, build SHA-256, source hashes
and logs accompany the delivered ordinary Play file.

Geometric preflight checks north/west tower-tip sightlines against planned Terrain
from ordinary pilot viewpoints, with over five studs of clearance. This does
**not** validate foliage occlusion, renderer visibility, voxel contacts, artistic
balance or the appearance of the entire towers. The startup grounding code is
compiled and statically checked, not reported as a completed Studio run.

## Remaining 07D review and known limits

Open `M7-07C-Play.rbxlx` and press **F5**. With ordinary camera and UI, inspect the
pilot from spawn, the working floor, western/northern boundary and bazaar approach.
Check cliff grounding, tower silhouettes/roof joins, ruin contacts, transparent
leaf overlaps and the enlarged moon against day/dawn/sunset/night/rain/after-rain.
Use the unchanged `EnvironmentReview` controls documented in
[07A](M7_07A_BATCH_RESULT.md). Compare Full/Reduced/Minimal, Reduce Motion and Roblox
Low/Automatic/Manual 5; repeat camera-near-slope, fence and boundary behavior.
No media is required. This is the combined 07D review, not a claim that it passed.

Unresolved/unverified: native composition and long-distance haze/occlusion;
smooth-alpha foliage sorting, overdraw and Low-quality edge behavior; actual
ground contact of the large rock/tower meshes and shared ruin foundation; native
camera behavior against the changed ridges. The finite ocean edge at extreme
zoom remains an inherited limitation. Farther, undecorated farms await phase 08.
Part/triangle limits do not establish frame rate: Roblox recommends actual
[client performance measurement](https://create.roblox.com/docs/performance-optimization/identify).
Physical-phone FPS/heat, experience asset permissions and live multiplayer load
remain **BLOCKED**. Local asset provenance is verified; experience permissions
are a separate gate. **07D APPROVED → UX gate → 08 FINAL** remains the order.
