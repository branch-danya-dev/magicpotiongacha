# 07A / #21 — candidate, acceptance still open

Based on the owner's docs-only `f81055f`, after task 07 `902d70d`.
This is a **partial 07A code/build delivery**, not a completed gate. Do not start
07B, 07C, UX or phase 08 on the basis of this report. The authoritative sequence
and acceptance requirements remain [the post-07 specification](M7_POST07_ART_FINALIZATION.md).

## Implemented candidate

- Lamp selection now uses the avatar's position (camera Focus only before the
  avatar exists), stable tie-breaking, a 10-stud retention margin and a 0.65-second
  fade. Turning/zooming the camera cannot reorder slots. Fading lamps occupy a
  slot until off. Nearby sun accents use the same bounded allocator. Downgrading
  quality immediately enforces its cap; no temporary extra lights.
- Manual time/weather retargeting retains the selected cyclic arc while the live
  target moves. Crossing the antipodal time no longer reverses the interpolation
  halfway through an eight-second blend. Repeating the same pose/preview request
  does not restart its timer. EnvironmentState/EnvironmentView remain the only
  time/weather/Lighting owners.
- An art-gated production camera collision guard runs after the ordinary Roblox
  camera. A sphere sized for the near plane and a center ray include collidable
  Terrain and transparent collision barriers, excluding the local character.
  Inward corrections are immediate; outward recovery is damped. Camera look,
  subject and Focus stay under Roblox control. Scriptable cameras are skipped;
  respawn/camera replacement/large subject moves reset the smoothing history.
  Zoom is 4–40 studs while art is active and restored on teardown. StarterPlayer
  explicitly selects Zoom occlusion; no unsupported LocalScript occlusion writes.
- Eight anchored/queryable/collidable invisible segments close the outer ridge
  contour, below the Terrain base through y=80, with overlapping corners. They
  keep at least four studs from the reserved plot/road/bazaar footprints. All seven
  ridge summits lie outside the contour. Existing physical fence rails/fillers
  and server fall recovery remain in place. No farm/worker/range coordinates changed.

## Still unresolved / NOT verified

- **Sky seams remain OPEN.** Task-06 texture bytes and their orientation have not
  been changed without a native rendering diagnosis. Their inherited pixel-edge
  checks pass, but this does not establish that Roblox folds/renders them correctly.
  The new Studio version `version-67c8b1dedbb74fed` initially lacked all three local
  atmosphere packs. The existing hash-verified installer installed them locally;
  this is a contributing possibility, not a proven root cause of the reported seam.
  No uploads or experience-permission claims were made.
- **Ordinary full-game Play was not reached.** Studio opened its file dialog;
  accessibility actions reported an unavailable cached element and native input
  did not produce an observed focus change. A second app-access attempt timed out.
  No successful walk, 360-degree rotation, lantern comparison or graphics-tier
  inspection is claimed. No frame/video deliverables or camera helper were made.
- Camera initial-overlap/near-plane behavior, character visibility next to walls,
  slope corners, hill jumping, fence passage, natural placement of invisible ridge
  limits, and visible lantern bodies still require the requested native repros.
  The ray supplements Spherecast's documented initial-overlap limitation; it is
  not evidence that all overlapping-volume cases are solved in the engine.
- Full/Reduced/Minimal, manual graphics 5/Automatic, Reduce Motion, sky 360-degree
  joins across all moods and rapid/manual/automatic time transitions remain OPEN
  for actual Play. Retest after every change that those checks require.
- Smartphone FPS/heat, experience asset permissions and multiplayer load remain
  **BLOCKED**. Final artistic approval is still pending. PR #17 remains Draft.

## Automated validation and budget

1012 tests: all 995 inherited cases plus 17 new regression cases. New cases cover
moving-target antipodes/midnight, interrupted time/weather blends, deterministic
lamp slots, distance hysteresis, slot handover and quality caps, camera clearance
math, viewport near-plane coverage, a closed ridge contour, reserved routes and
existing geometry limits. Compile, portable analysis and both Rojo builds run
through the existing Windows/Ubuntu workflow. These tests are not engine acceptance.
The exact final source SHA, build hash and CI result accompany the delivered build.

The added geometry is **8 invisible Parts + 1 Folder**, not eight-farm art rollout.
Nature + task-07 props + ridge barriers: **1175 Parts / 1320 existing limit**;
triangle planning charge **324957 / 465000**. Existing four fence fillers and
unchanged gameplay anchors remain outside that historical art-pool accounting.
No new textures, lights, emitters, remotes or persistent fields. Texture estimate
stays 30.484 MiB / 32 MiB. Active light caps stay Full 6, Reduced 3, Minimal 0.
Camera work adds one render binding, at most one spherecast plus one raycast per
active ordinary-camera frame; real device cost is unmeasured. No cap was raised.

## Resume the native checks

1. Open the delivered `M7-07A-Play.rbxlx` in Studio and start ordinary Play (F5).
   It uses Studio memory profiles and art enabled only in Studio; commerce/trading
   stay off. Rebuild with `node scripts/build-local-preview.mjs` without QA flags.
2. Verify Output reports zero local asset failures. After a Studio update, install
   `atmosphere`, `polish`, `fantasy` using `scripts/install-atmosphere-preview.mjs`
   against the actual current version folder, with receipt/hash validation.
3. Reproduce the original camera/hill/fence/lantern defects at all affected slopes
   using ordinary walking/jumping/zoom/turn controls. Check day and night on the
   existing pilot, Full and Reduced; validate Minimal and Reduce Motion separately.
4. Inspect sky/horizon and poles through 360 degrees after textures load, in six
   moods, then automatic and manual transitions. Diagnose and fix remaining seams
   before calling 07A complete. No fog masking or unverified face flips.
5. Record textual results and build SHA; owner reviews the actual pilot. Only move
   to 07B when 07A's remaining defects and native checks are resolved.

API references: [Roblox camera behavior](https://create.roblox.com/docs/workspace/camera),
[Camera near plane](https://create.roblox.com/docs/reference/engine/classes/Camera#NearPlaneZ),
[WorldRoot shape casts](https://create.roblox.com/docs/reference/engine/classes/WorldRoot#Spherecast),
[skybox construction](https://create.roblox.com/docs/environment/skybox).
