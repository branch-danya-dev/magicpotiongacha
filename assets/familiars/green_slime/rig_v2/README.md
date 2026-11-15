# Green Slime — two complementary Idle clips

**ART REVIEW PENDING / BLENDER CHECKED / ROBLOX PLAY BLOCKED / NOT PUBLISHED.**
Owner requested both clips in PR #49 on 2026-11-15. They are a shared set, not
mutually exclusive design alternatives. V1 remains untouched for comparison.

| Clip | Duration / baked samples | Character |
| --- | --- | --- |
| `Idle_Calm.fbx` | 3.6 s / 109 samples at 30 FPS | Slow breathing, phased edge wave, 7° head lift with gentle sway |
| `Idle_Active.fbx` | 3.0 s / 91 samples at 30 FPS | Stronger asymmetric body displacement, broader edge spread, 10° head lift, gather/release/settle timing |

Both clips use the **exact same V1 rest mesh, UV, eight bone names/hierarchy,
bind matrices and skin weights**. The common rest FBX is
`../rig_v1/GreenSlime_Rig.fbx`; the original linked/embedded PNG is unchanged.
No new mesh or eye geometry, no remesh, no animated scale, no Root/Contact motion.
The low front of the head is held by a compensating local bone translation while
the raised portion tilts. This avoids simply doubling all V1 deformations.

`GreenSlime_TwoIdles.blend` contains the two editable actions and a separate
`Calm_Active_Calm_QA` demonstration action. The QA action is **not** exported as a
third runtime clip. Only one named animation stack is baked into each FBX;
fresh Blender imports read `GreenSlimeRig|Idle_Calm` / `GreenSlimeRig|Idle_Active`.
Roblox importer naming and the final published track IDs are unverified.

## Viewing

- `previews/sequence-game.mp4`: Calm → Active → Calm, 10.2 s.
- `previews/sequence-detail.mp4`: identical timing, close view for face/skin review.
- `previews/calm-game.mp4`, `active-game.mp4`: separate loop previews.
- `previews/v1-game.mp4`: unchanged V1 at the same camera for comparison.
- PNGs show each clip's initial and raised-head pose at both camera distances.

The scale preview uses a 2.4-stud width, matching the current worker proxy in
`src/client/FamiliarView.client.luau`. Perspective camera: distance 12 studs,
elevation 38°, vertical FOV 70°, 960×540 output. **This is a Blender scale proxy,
not a real Studio frame.** Current native camera framing was not measured;
12 studs is an explicit review assumption. The pet occupies about 76 pixels of
width at this framing, so motion is more restrained than in the close view.
Do not mark the owner's 1–2-second readability gate passed from the close-up.
See `preview-camera.json` for actual projected width and rendering setup.

The sequence changes at 3.6 s and 6.6 s, after complete cycles. For the next
0.3 s the outgoing clip continues its loop and fades out while the incoming clip
starts at frame zero and fades in. The saved QA action approximates the blend
with linear small-angle Euler channels; actual Roblox AnimationTrack blending
must still be checked after upload approval. It is a fixed review sequence,
not evidence of an implemented random runtime selector.

## Diagnostics

Calm peak local edge strain is 28.68%; Active 34.12% on fresh FBX import,
compared with V1's 28.54%. The cap stays 35%, an internal diagnostic threshold,
not a Roblox standard. Early higher-amplitude candidates failed that cap and
were discarded. All delivered clips have zero evaluated loop seam and positive
minimum ground clearance (~0.0128 authoring units). Check `validation.json`,
`fbx-roundtrip.json` and `continuity.json`; all are bound by the root manifest.

The fresh-import check compares actual rest vertices, polygons, UV, skin and
bone matrices directly to V1, verifies the 35 eye-rim vertices are rigid Head
weights, and evaluates every half-frame for ground/strain/continuity. The saved
sequence is independently checked around both fade start/end boundaries.
These checks do not certify self-intersection absence, phone performance or
Roblox's renderer. Face/ground/loop readability still needs owner review.

## Reproduce

Use Blender 4.5.9 LTS from the repository root. Source V1 .blend SHA-256 is pinned
inside the recipe. No provider/network call occurs. V1/source files are read-only.
V1's historical instructions belong to commit `59eda121a3c42cf68e820c0ac87a4a76b143161f`;
on the current branch use this V2 recipe/receipt instead of regenerating the
pinned V1 .blend or running its legacy manifest writer.

```text
blender --background --factory-startup --python-exit-code 1 --python assets/familiars/green_slime/rig_v2/scripts/build_idles.py
blender --background --factory-startup --python-exit-code 1 --python assets/familiars/green_slime/rig_v2/scripts/verify_exports.py
blender --background --factory-startup --python-exit-code 1 --python assets/familiars/green_slime/rig_v2/scripts/verify_transitions.py
blender --background --factory-startup --python-exit-code 1 --python assets/familiars/green_slime/rig_v2/scripts/render_previews.py -- stills
blender --background --factory-startup --python-exit-code 1 --python assets/familiars/green_slime/rig_v2/scripts/render_previews.py -- sequence-game
```

Repeat the last command with `sequence-detail`, `calm-game`, `active-game`,
`v1-game`, then run `verify_previews.py` with the same Blender command to verify
the five completed videos' dimensions, frame count and duration.
Cycles uses OptiX when available with CPU fallback; no preferences
are saved. Rendering is not a target-device benchmark. Metadata/pixels may vary
by hardware; the pose/skin/timing recipe is deterministic. After reviewing:

```text
python assets/familiars/green_slime/rig_v2/scripts/receipt.py
node scripts/check-green-slime.mjs
npm run tools
npm test
```

CI checks exact delivery hashes and actual FBX semantics; it does not install
Blender or execute Roblox. Current original provenance remains in
`../source/PROVENANCE.md`, including the supplied PNG/issue-hash discrepancy.

## Gate

V1 importer preview is historical and does not certify these two new clips.
No V2 native import, AnimationController/Animator Play, low graphics, collision
proxy or mobile checks were performed. Owner art acceptance and explicit private
Roblox upload approval are still required. No gameplay integration, new asset
IDs, merge or publication. See [future selector contract](RUNTIME_SELECTOR.md).
