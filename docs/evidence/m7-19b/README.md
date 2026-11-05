# M7 task 03 / #19b — farm ground integration

**Implemented; first visual checkpoint REVIEW PENDING.** PR #17 remains Draft.
Runtime/captured source: `e77905569ec40ca4a091af52a536157bbdd11d87`.
Baseline task 02: `8eb1cfe89d1965061f029fdbc3d7f142c9411853`.

## Result

Farm floors and the bazaar slab are visually hidden. Terrain reaches just below
their original collision surfaces, with smooth approaches and a curved central
path. The spawn marker stays at the same position as the same RespawnLocation,
but its visible/collidable hump is removed. Existing floor physics are retained.
Only the pilot receives interior path dressing; the other seven farms receive
ground integration and access, not the later artistic rollout.

A thin rounded yellow boundary shows the local player's plot. The permanent buy
pads are hidden; a soft green patch appears only near the currently selected,
unobstructed, owned, technologically available and affordable upgrade. The
existing prompt opens the existing UI. This is a visual hint, never purchase
authority. No economy, saves, remotes, trading or Rebirth changes.

## Actual Studio evidence

- `before/after-{5,10}-{spawn,farm,bazaar,build-empty}.jpg`: eight matched pairs,
  full game HUD, daytime, default Reduced. Positions/orientations and FOV 70 are
  identical, frozen by the same isolated QA camera helper. Studio titlebar
  variants change viewport height by roughly 1%; these are not pixel-identical
  raster comparisons. Original full-window screenshots are unretouched.
- `after-5-build-ready.jpg`: 70 Gold earned by five ordinary starter brews through
  existing validated intents. No currency grant or purchase. QA positioning
  between stations is setup, not evidence of manual traversal. At 0 Gold the
  glow is absent; at 70 it shows. Full and Minimal supplemental images retain it.
- [Actual walk video](19b-farm-walk.mp4): Reduced, manual graphics 5. Initial
  affordable-build view, one setup position reset, then 12 real Humanoid movement
  segments through the farm entrance/interior to the bazaar; all reached alive.
  First continuous 45 seconds requested from a 53.49-second native recording;
  variable-frame-rate output is 44.87 seconds. No internal cuts, acceleration or
  generated frames. H.264 1280×670; sound/metadata removed. Recorder frame rate
  is not a performance measurement.
- `plain-play-desktop.jpg`: delivered build opened and started with one ordinary
  Play, without any QA scripts or fixed weather/camera controls. The normal
  atmosphere cycle and gameplay HUD work. Project-script errors were not
  observed. Stock Studio/backend asset 403 and absent local Rojo connection
  messages are not counted as project runtime failures.
- `studio-audit.txt`: only relevant project events from baseline, candidate and
  delivery sessions. All 8 original plot/spawn anchors and bazaar anchor pass;
  2,888 terrain samples measure 0.40527–0.40625 below original floor top 0.5.
  The inherited terrain telemetry prefix remains `M7_19A_TERRAIN`.

## Build and reproduction

Local handoff: `outputs/M7-19b-review/M7-19b-Play.rbxlx` and `review.html` in the
parent workspace. Open the place and press Play on the prepared computer.
The existing original local atmosphere textures remain a prerequisite on another
machine; no new asset dependency is introduced here.

Build SHA-256: `b24b51c13a88a486626ff826fd98eb44177e815938da083611d8702a31077eef`.
The manifest records delivered, recorded and baseline build hashes. XML source
comparison verifies all 55 delivered/recorded runtime scripts against the commit;
the only build substitution enables environment art **in Studio only**. The
recording adds exactly two QA scripts. Baseline has 52 task-02 runtime scripts
plus the same two helpers. No helpers are shipped in the ordinary build.

Rebuild with `node scripts/build-local-preview.mjs`; the output is
`build/PotionTycoon-M7-LocalPreview.rbxlx` (rename/copy for the handoff).
For diagnostic reproduction add `--farm`: F8 resets spawn camera, F6 cycles the
four views, P logs camera/counters, Q cycles quality, N runs five existing
starter recipe intent sequences, J walks the route, C releases the fixed camera.
These controls exist only in the separate QA build.

## Verification and budgets

939 tests pass: all 922 inherited tests and 17 task-03 tests. Compile/portable
analysis/Rojo and historical-evidence integrity checks pass (115 Luau sources).
[Runtime CI Windows/Ubuntu](https://github.com/branch-danya-dev/magicpotiongacha/actions/runs/42080393846)
passes. The final evidence commit is checked again by the same workflow.
`verification.log` archives the local check; the final commit also adds evidence
integrity checks. This does not replace artistic acceptance.

Terrain stays at 1,082,880 cells (675,287 written); candidate startup was 4.364 s,
ordinary delivery 4.291 s on this desktop. New budget: 23 local nonphysical parts
(20 boundary segments + 3 nested glow discs), no new textures/particles/lights.
Only one owned boundary and one selected glow exist; boundary culls at 110 studs,
glow at 8. Existing 10 Hz context update drives them. Static geometry needs no
motion animation at any quality; pool count stays 23 in Full/Reduced/Minimal.

## Remaining defects and limits

- Thin distant yellow edges can appear jagged/dashed at graphics 5. No claim that
  all low-quality aliasing is solved. Local green glow is intentionally faint.
- Repeated grass texture and sparse vegetation remain tasks 04/05. Colored
  station blocks, translucent unbuilt volumes, crystal and bazaar proxy are
  task 07. Their materials/models were not changed in this patch.
- Far water boundary, old mixed-language labels and legacy UI details remain.
- Other seven farms have no new interior artistic dressing. Task 08 still needs
  explicit final pilot APPROVED; tasks 04–08 were not started here.
- Physical smartphones, experience asset permissions and multiplayer load are
  **BLOCKED**. Reduce Motion toggle and all weather states were not rechecked in
  this pass; the new affordance has no motion. Full/Minimal live verification is
  limited to the build viewpoint. Full M1–M6 progression was not replayed live.
- No purchases, public trade activation, merge or publishing performed.

The owner must review the first checkpoint after task 03: the island and farms
should no longer read as raised rectangular platforms. No new artistic APPROVED
status is inferred from passing code checks.
