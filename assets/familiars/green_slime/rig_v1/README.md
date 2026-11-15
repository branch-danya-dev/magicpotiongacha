# Green Slime — Idle v1 review candidate

**Phase A candidate. Studio importer preview verified; ordinary Studio Play
BLOCKED. Owner art acceptance PENDING. No Roblox asset IDs or gameplay integration.**

## Delivered files

- `GreenSlime_Idle.blend`: editable rig and baked Idle. A separate
  `QA_Presentation_NOT_EXPORTED` collection supplies the ground, camera and lights.
- `GreenSlime_Rig.fbx`: mesh + armature in rest pose, no animation.
- `GreenSlime_Idle.fbx`: same mesh + armature with exactly one baked Idle track.
- `GreenSlime.png`: unchanged owner texture; also embedded in both FBX files.
- `previews/`: actual Blender renders of neutral, head tilt, center compression, edge stretch and Idle,
  plus a 3.2-second MP4. These are not Roblox Play captures or AI reconstructions.
- `validation.json`, `fbx-roundtrip.json`: evaluated mesh and fresh-import checks.
- `../manifest.json`: exact checksums of all delivered package/evidence files.

See [source rights and input discrepancy](../source/PROVENANCE.md).

## Rig and animation

The original flat puddle and raised head retain 1321 vertices / 2603 triangles,
one UV map and one material. No remesh, subdivision, shapekey or new eye geometry.
Only uniform scale 3.2 and a ground-origin translation affect rest geometry.
Blender Z is up, face points toward negative Y. Export axes are -Z forward/Y up.
Studio world size/orientation still need confirmation after an authorized import.

```text
GreenSlimeRig
└── Root (no vertex weights, stationary)
    ├── Contact (fixed ground support)
    ├── Body
    │   └── Head
    ├── EdgeFL
    ├── EdgeFR
    ├── EdgeBL
    └── EdgeBR
```

Eight bones total, at most four normalized influences per vertex. Head weights
blend over the neck, with the eye rims held rigidly to Head. Contact prevents the
thin floor from moving below ground; Root carries no deformation or root motion.
Linear skinning avoids relying on Blender-only volume preservation. There is no
animated scale. Center breathing comes from local displacement and skin weights.

Idle is 30 FPS, frames 0–96 inclusive, 3.2 seconds. Body breathes gently, Head
tilts by up to 3.5°/3° with a small yaw, and four edges move with quarter-cycle
phase offsets. Each frame is baked with linear interpolation. First/last evaluated
vertices match exactly. The 96-frame video omits the duplicate endpoint.
The still head test uses 7°/6° tilt; the edge test raises Body and alternates edge
heights beyond the ordinary Idle amplitude. The compression test lowers Body by
0.032 authoring units with Contact fixed; the ground clearance remains 0.0128.
These are tests, not extra clips.

## Reproduce locally

Pinned authoring tool: **Blender 4.5.9 LTS**, build `8bf95cbd38d1`.
Run from the repository root, substituting the installed Blender executable:

```text
blender --background --factory-startup --python-exit-code 1 --python assets/familiars/green_slime/rig_v1/scripts/build_rig.py -- --render
blender --background --factory-startup --python-exit-code 1 --python assets/familiars/green_slime/rig_v1/scripts/verify_export.py
blender --background --factory-startup --python-exit-code 1 --python assets/familiars/green_slime/rig_v1/scripts/render_idle.py
python assets/familiars/green_slime/rig_v1/scripts/receipt.py
node scripts/check-green-slime.mjs
npm run tools
npm test
```

The recipe checks immutable source hashes before work. Outputs stay in `rig_v1`;
the source files are never overwritten. `--render` is optional for model rebuilds;
omit it to skip the still renders. The pinned version is important for Blender's
action API. Native inspection also opened the saved file in installed Blender
5.3.0 without resaving it.

Reproducibility means repeatable geometry, rig, weights and clip from these
source files. FBX/.blend metadata can vary between executions; byte-identical
Blender exports are **not** promised. The manifest fingerprints this delivery.
If regenerating, re-run the fresh-import audit, inspect the renders and explicitly
refresh the receipt. CI validates the current files, never rewrites the receipt.

Game Development Studio CLI was unavailable on this host. This is the direct
Blender workflow requested by Issue #48, not a claimed canonical package admission.

## Studio handoff — stop before Import

The local 3D Importer preview opened `GreenSlime_Rig.fbx`, displayed the texture
and all eight bones. No final Import/Start Import was clicked. No asset IDs were
created and nothing was inserted into production or published.

**Unchecking “Upload to Roblox” does not guarantee an offline import.** Roblox
staff clarify that underlying mesh/image/animation data are uploaded even when
optional inventory Model/MeshPart uploads are disabled:
[Roblox staff explanation](https://devforum.roblox.com/t/3d-import-uploads-animations-even-though-i-unchecked-upload-to-roblox/3138984).
Issue #48 forbids asset upload/new live IDs until owner art review. Therefore
ordinary Play cannot honestly be claimed within the current permission scope.

After owner art acceptance and explicit upload permission, use a separate QA
place. Select the authorized creator; preserve Root with “Keep Zero Influence
Bones”, set pivot to scene origin, disable cages, and use a custom/nonhumanoid
rig. Verify actual Workspace Bone descendants, material and world size.
Import the animation track from `GreenSlime_Idle.fbx` onto the rest rig in
Animation Editor; Blender reimports its track as `GreenSlimeRig|Scene`.
Do not rely on that label as the Roblox animation name. Review moderation and
Experience permissions before assigning any AnimationId.

Remaining native checks: AnimationController/Animator loop for multiple cycles,
neutral/head/edge deformation, ground contact, original face/UV/texture, low
graphics and phone, plus a simple invisible collision proxy. Bone deformation
does not update MeshPart collision geometry. No proxy/runtime script is shipped
or enabled in the game in Phase A. Move, React and VFX remain a later task.
