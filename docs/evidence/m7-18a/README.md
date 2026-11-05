# Task 01 / #18a — critical Play defects

**Implementation ready for visual review; TASK_01_REVIEW_PENDING.** Earlier
artistic Gate A is APPROVED only for that historical result. PR #17 stays Draft.
The owner's revised eight-task sequence is in [M7_REWORK_PLAN](../../M7_REWORK_PLAN.md).
No island/vegetation/station redesign is included in this patch.

## Exact builds and ordinary Play

- Final runtime: `c0c1912185ea19bfbae5755d717e2da8fdec2b93`.
- Plain delivered place: `M7-18a-Play.rbxlx`, 464348 bytes, SHA-256
  `309cf3b131f8df60b8a019c090d6137dbf95e01eb70e031cf71548a21ef7f9c4`.
- Time/physics recording and matched desktop captures:
  `3b89acb7f8ad507fa9db570bec5e3056e710b529`; instrumented place SHA-256
  `63ea58997c79f65097a712ef2d4a4cc6a880469897a1434c1f8cd04ebf6776c2`.
- Final mobile captures/videos use the **plain c0c1912 place**, without QA scripts.
  The only runtime changes since the time/physics capture are two compact-button
  visibility lines and its 30px upward move; [exact diff](recorded-to-final.diff).
  Time, fence and recovery code are identical in both builds.
- Baseline runtime: `d6c836f5ea96269e20259b26fb7d173b2e8aa1f7`, historical
  UI18 local place, with only the same SafetyReview instrumentation substituted.
  Baseline ordinary place hash is recorded in [UI18 evidence](../m7-ui18/README.md).

All 50 serialized runtime Luau sources in both candidate places were compared
with their named commits. The sole preview substitution enables art in Studio
in ServerSettings. [Manifest, source and media hashes](captures.json),
[final source snapshot](source-snapshot.json), [local validation](verification.log).

On the prepared review computer, open the delivered place and press **Play**.
The full game, art, collisions, recovery and mobile entry work without commands,
special modes or a hidden HUD. The plain place was opened and played in Studio.
Rebuild with `npm run tools`, `npm test`, then
`node scripts/build-local-preview.mjs`; use `build/PotionTycoon-M7-LocalPreview.rbxlx`.
The CI artifact includes that plain preview alongside the release-disabled build.
On a fresh computer, install the existing local atmosphere textures using the
[A.2c setup](../../M7_A2C_ATMOSPHERE.md); those dependencies are unchanged.
Progress is in memory in Studio; purchases and trading are off. Do not publish it.

## Real video and observed results

Windows Roblox Studio **0.746.0.7461264**, one local player, default **Reduced**.
These are native Studio recordings, not rendered mockups or a beauty-only scene.
H.264 recompression, audio/metadata removal and desktop downscale only: no cuts,
speed changes or generated frames. Native file hashes are retained in the manifest.

- [Continuous time/fence/fall video — 2m56.5s](18a-continuous-play.mp4).
  Day → sunset at approximately 0:15 → night at 0:49; fence traversal near 1:45;
  falling/recovery near 2:12. Manual graphics **5**, ordinary game/UI visible.
  The optional helper places the actor at each test start, then uses Humanoid
  movement and real engine physics. These setup teleports are **not** a continuous
  walking route and do not implement the recovery being tested.
- [Final portrait menu — 48.5s](18a-mobile-portrait.mp4).
  Factory opens/closes while the native player list remains open; button returns
  after closing; joystick and jump stay available. Native recording 400×864.
- [Final landscape menu — 4m40.1s](18a-mobile-landscape.mp4).
  Open/close with native player list visible, separate Factory and nearby-action
  rail. Includes idle observation; native recording 864×400.

Time transitions now blend from the displayed state over eight seconds, including
diagnostic changes and retargeting. The existing single EnvironmentView owner
remains. Baseline diagnostic switching logged a **4.85-hour / 1.55-brightness**
single-frame step. In the recorded candidate window, sampled maximum frame changes
were **0.0464 hour / 0.0148 brightness**; these observations are not an FPS claim.
The same session exercised dawn, rain, clearing and day afterwards; maximum sampled
clock step over that longer diagnostic window was 0.0836 hour. See the timestamped
[project-only audit](studio-audit.txt), which excludes backend/account log content.

The baseline avatar passed through the fence to z=-43.25. The fixed fence stopped
two trials at z=-36.30 / -36.28, alive, original character, health 100. Ten existing
posts/rails are physical and four invisible fill colliders prevent stepping through
thin rails. Fill colliders are separate from visual LOD, at the existing fence
height, and do not span the entry. Budget increase: **four static invisible parts**;
no extra rendered meshes, textures, VFX or per-frame collision allocation.

Baseline falling destroyed the root before engine respawn. The candidate server
returned the **same living character** to its owned Plot_1 spawn, health 100.
Recovery checks the current character, live humanoid, root-parent/plot ownership,
height and downward velocity, with a cooldown and no yields between validation
and movement. No remotes, profile writes, rewards or economy changes were added.

## Before / after at matched cameras

The same F8 actor position, Custom camera offset `(9,7,12)` and target above its
spawn were used for these full-game views. Native UI remains visible. Grass,
foliage and existing lighting targets intentionally retain their previous look;
the time fix is demonstrated by the continuous recording, not a retouched still.

| View | Before | After |
| --- | --- | --- |
| Day, graphics 5 | [before](before-day-g5.jpg) | [after](after-day-g5.jpg) |
| Night, graphics 5 | [before](before-night-g5.jpg) | [after](after-night-g5.jpg) |
| Day, graphics 10 | [before](before-day-g10.jpg) | [after](after-day-g10.jpg) |
| Graphics setting 5 | [before](before-settings5.jpg) | [after](after-settings5.jpg) |
| Graphics setting 10 | [before](before-settings10.jpg) | [after](after-settings10.jpg) |

Additional action evidence: [baseline passes fence](before-fence-g5.jpg),
[candidate stopped](after-fence-g5.jpg), [alive after recovery](after-fall-g5.jpg).
These action shots are not matched-position art comparisons.

Final mobile: [landscape closed](final-landscape-closed.jpg),
[landscape open](final-landscape-open.jpg), [portrait closed](final-portrait-closed.jpg),
[portrait open](final-portrait-open.jpg). The native player list stays open.
Compare the [old portrait overlap](before-portrait-g10.jpg). Mobile camera/lighting
are not matched to the baseline, and final mobile graphics level was not separately
verified; graphics 5/10 comparison applies to the desktop pairs above.
[Plain Play without diagnostic setup](plain-play-desktop.jpg).

## Tests and remaining limits

**907 passed; 0 failed**: all 892 inherited + 15 new tests. All 104 Luau sources
compile, portable analysis and normal/review Rojo builds pass. New cases cover
transition start/settle/retarget, circular seam and six pose bounds, fence entry
geometry, fall prediction/cooldown/non-finite coordinates and three mobile sizes.
Historical source/media checks and original economy/intent/payment guards remain.
The PR links the final Windows/Ubuntu run; CLI results do not replace Studio QA.

- Physical phones, asset permissions in the Roblox experience and multiplayer
  load remain **BLOCKED**. The emulator is not a phone-performance test.
- Open visual work: rectangular platforms, sparse/flat grass, existing trees,
  greybox production blocks and bazaar, mixed RU/EN text. They belong to later
  tasks and are visible in ordinary Play; no claim of final art quality.
- Native player list still overlaps the right edge of the portrait resource/guide
  area, although it no longer covers Factory. That broader UI coexistence issue
  is not declared fixed. Landscape sheet has limited height and needs scrolling.
- Inherited foliage/path-edge and distant Terrain shimmer is not declared fixed.
- Full/Minimal/Reduce Motion were not rerun live in this task; existing tests and
  historical captures remain. No exhaustive M1–M6 progression replay, real gamepad,
  second-player plot or disconnect/rejoin acceptance is claimed. Fence entry is
  checked geometrically; a separate live entrance traversal was not recorded.
- The global Studio log contains inherited Rojo/plugin/backend warnings. Only
  project-generated observations are included; a clean backend session is not claimed.

Task 02 is not started. No purchases, trade activation, merge or publishing.
