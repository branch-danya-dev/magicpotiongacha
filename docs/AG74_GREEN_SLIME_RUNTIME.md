# AG-74 — Green Slime runtime QA

Issue #50; branch `feat/ag74-green-slime-runtime`, stacked on Draft PR #49,
`feat/ag73-green-slime-idle` at `8796abfbb8345dd90f2ebc7052c415782e056eaa`.
Base HEAD was rechecked on 2026-11-16; inherited Windows/Ubuntu run
[43741788473](https://github.com/branch-danya-dev/magicpotiongacha/actions/runs/43741788473)
passed. This is a Studio QA candidate, not release acceptance.

## Scope and reproducibility

The canonical `slime` species can use the imported skinned visual in the existing
`FamiliarView` owner. Five tagged presentation seams preserve the previous renderer
byte-for-byte after removal. All inherited `src`, tests, QA and asset files are
checked against PR #49, with that one renderer exception. Factory, server requests,
stats, starter grants, persistence and economics are unchanged.

`default.project.json` remains unchanged and does not contain the rig template or
enable flag. `FamiliarRigView` requires both `RunService:IsStudio()` and
`Workspace.GreenSlimeRigPreviewEnabled=true`. No published-game activation.

The separate QA place includes the real game and its current HUD/environment,
the reproducible rig template, and two local cosmetic previews on the local
player's plot. These do not grant familiars, change assignments, or write a profile.
The QA place uses the inherited memory store; trading and monetization remain OFF.
Do not publish the review file.

From the repository root:

```powershell
npm run tools
npm test
node scripts/build-ag74-preview.mjs
```

Open `build/PotionTycoon-AG74-GreenSlime-QA.rbxlx` in Studio, then press F5.
Two Green Slimes appear beside the character. Their positions are fixed for idle
inspection; this task does not implement following, Move, Carry or other clips.
They stop idle while the character moves. Full/Reduced animate; Minimal and Reduce
Motion keep the rig visible in its rest pose. Stop Play with Shift+F5.

For rollback, set the client Workspace flag to false: the previews and their
tracks are destroyed, while assigned workers return to their inherited proxies.
Re-enable to recreate. An actual assigned `slime` is rendered at the existing
worker proxy position; the logical station/worker and cargo remain unchanged.
Loading failures leave the old worker visible and do not retry every frame.
Retry by toggling the flag or replacing the worker assignment.

`node scripts/build-ag74-preview.mjs --checks` creates the separate
`build/AG74-NativeChecks.rbxlx`. F5 runs opt-in local visual fixtures, including
an intentionally invalid animation ID. It never sends a grant or server request.
Its local station attributes are restored after the checks, including on failure.
This diagnostic script is not included in the normal QA review file.

## Assets and rights

Owner authorized the private model/texture and exactly two existing Idle uploads
in Issue #50 and the chat. No new paid generation, public distribution or extra
animation was authorized or performed. The inherited paid-Meshy source ownership,
PNG discrepancy history and all 58 source-package hashes remain in
`assets/familiars/green_slime/source/PROVENANCE.md` and `manifest.json`.

| Asset | Roblox ID | Source |
| --- | --- | --- |
| Skinned mesh | 76181395589964 | `rig_v1/GreenSlime_Rig.fbx` |
| Image texture | 107809848451619 | inherited 2048 PNG |
| Idle_Calm | 73712172546084 | `rig_v2/Idle_Calm.fbx`, 3.6 seconds |
| Idle_Active | 89284758082218 | `rig_v2/Idle_Active.fbx`, 3.0 seconds |

Creator: **addout studio (925845207)**. Creator Dashboard showed **Restricted**
for all four assets; Experience **10776120489** resolved and Done was saved for
each permission entry. No Creator Store or Open Use. Intended private place:
**125724638469407**. The native local-file runs have PlaceId/GameId **0/0** and
therefore do not independently certify delivery to a server for that Experience.

`GreenSlime.imported.rbxmx` is the native export; `GreenSlime.rbxmx` is normalized
deterministically by `scripts/green-slime-runtime-asset.mjs --write`.
`runtime-manifest.json` pins both file sizes/SHA-256 and the import/permission receipt.
Normalization removes import metadata (30 CFrameValues), preserves eight bone
transforms, removes gray mesh tint, restores a consistent foot pivot/orientation,
and adds an AnimationController/Animator plus a simple invisible reference proxy.
There are no asset scripts. All parts are anchored, noncolliding, nontouching,
nonqueryable and shadowless; bone deformation is not treated as physical collision.

Source: 1,321 unique vertices, 2,603 triangles, eight bones, one UV set and one PNG;
maximum four weights per vertex. Native mesh size at scale 1:
**3.06562567 × 0.556249857 × 2.70468473 studs** (the source is a shallow puddle).
This is a candidate size for owner review, not an approved scale/readability claim.

## Animation ownership and budgets

Each rig loads exactly two tracks once per lifetime. The cosmetic selector chooses
50/50 after each full cycle. Choosing the same clip continues without resetting
time; a different clip crossfades for 0.3 seconds. Each pet has independent local
RNG and phase. The initial partial randomized cycle cannot trigger a selection;
stale/outgoing callbacks cannot make a second choice. Haul/React, Minimal and Reduce
Motion stop idle; resuming reuses the same two tracks.

Maximum ten simultaneous rig views per client, two tracks and two DidLoop
connections each; the separate owner preview is two of those ten. Loading has a
12-second timeout. Removal, flag OFF and destruction release tracks, animations,
connections, model and in-flight loader. Failed assets produce one fallback warning
per attempted lifetime, not per render frame. QA previews update at 10 Hz; the
existing assigned-worker owner retains its inherited render loop.

Native checking found and fixed a rapid OFF/ON race: a flag transition between
preview ticks could leave disposed records. Cleanup now observes the flag event
directly and the worker owner recreates a deliberately disposed view.

## Verification and open gates

Machine-readable native results and exact tested file/source hashes are in
`docs/evidence/ag74/native-checks.json`. The final PR records its exact commit and
Windows/Ubuntu run. `build/verification.log` starts with the tested source SHA;
`build/ag00-integration.json` proves the ordinary build repeats byte-for-byte.

CLI adds 13 selector/lifecycle tests to the inherited 1,321 Luau tests; all 14
inherited Node tests remain. Asset hashes, FBX audits, strict preservation checks,
compilation, portable analysis and Rojo builds remain required. The two inherited
C01 analysis warnings are not introduced by AG-74.

Native Studio 0.747.0.7471481 checks are scoped to one authenticated desktop client
in ordinary F5 Play, using the memory-store full-game QA place. Eight plots exist,
one is owned, and previews are restricted to that owner; this is not an eight-client
isolation/load test. Local fixture assignments are not evidence of server progression.

**Unresolved / NOT RUN:**

- Owner visual acceptance of size, eye rims, ground contact, colors and both clips
  remains OPEN. On 2026-11-16 the owner explicitly requested no video/screenshots;
  none were made for this continuation. Earlier visual observations are historical.
- Studio emitted an optimized texture representation warning for texture
  107809848451619 (`do_not_fallback_to_baseline`). Explicit ContentProvider preload
  reports Success for mesh, texture and both clips. That does not prove the final
  material rendered correctly after that warning; visual texture acceptance remains
  open. No re-upload or permissions workaround was attempted.
- Physical phone/low-end GPU and low-FPS native testing, two camera distances,
  death/reset, server reconnect/rejoin, and real backend delivery are NOT RUN.
  Delayed callbacks and disposal are tested portably; that is not device testing.
- Desktop Heartbeat frequency is only a scheduler diagnostic, not measured rendered
  FPS, GPU timings or an AG-74 baseline/candidate performance comparison.
- Existing unrelated asset 203785492 reports an incorrect asset type in Studio;
  no AG-74 source references it. It remains outside this change.

**IMPLEMENTED/CODE:** QA integration. **STUDIO VERIFIED:** only the explicitly
recorded technical checks. **OWNER ACCEPTED:** no. **PUBLISHED:** no.
No merge, public game changes, economy/save changes, further uploads or expansion
to the remaining six animations occurred.
