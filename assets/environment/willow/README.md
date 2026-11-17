# Willow Tree — isolated prototype

Base: `fdaf931b179ad188555147c720b768dd9334b17b` (PR #59).
Branch: `feat/willow-tree-game-ready-prototype`.
Owner art approval and final integration are pending.

**Update: final group upload/access completed 2026-11-17.** Run `node scripts/build-willow.mjs --native`, then open `build/Willow-Native-Restricted-QA.rbxlx`. The checked-in `prepared/WillowRoblox.rbxmx` has final group IDs and prepared alpha materials; no repeat upload is needed. See `docs/WILLOW_NATIVE_DELIVERY.md` and `source/roblox-final-delivery.json` for authorization, Studio evidence and the raw foliage-image HTTP 502 limitation. Earlier personal-import/approval notes below record the preceding delivery stage and are superseded by this update. Owner art review is still pending.

## Source and rights

- Original: `C:\Users\keara\Downloads\Meshy_AI_model_20261117_generate.fbx`, preserved byte-for-byte.
- Meshy image-to-3D task: `01a1e765-fba3-7739-ac6c-e560f44b6856`, model meshy-t2.5, smart topology, untextured. Read-only task lookup; no paid jobs.
- Original SHA-256: `c6d4ce5eac77a3d260bb184583e86f5f0d3adb65f974fd923c47a9ed30a515a6`.
- The task response did not include a license. On 2026-11-17 the owner directly confirmed that **this willow** was created in their own Meshy account on a paid plan. The exact declaration and source binding are recorded in `source/owner-confirmation.json`; the account/plan confirmation gate is closed. This is an owner attestation, not an independent subscription audit. The later read-only Dashboard audit confirms all five existing assets are Restricted under `crystymoore`, with no grant to Experience 10776120489 in its full export; see `source/roblox-permission-audit.json`. Owner art review and authorization for final-asset delivery remain separate gates.
- Owner's two reference images are preserved in `source/`. Their Library identifiers are recorded in the task report; no signed download URLs or credentials are stored.
- Bark is reused from the already-vendored Quaternius Stylized Nature MegaKit Standard, `Bark_TwistedTree.png`, CC0. Original license is in `source/Quaternius-CC0.txt`.
- Foliage atlas is newly generated for this prototype using the built-in image tool; source PNG and prompts are preserved. Export normalization only scales to 1024 square, without painting/replacing the approved concept.

## Files and reproduction

`prepared/Willow.blend` contains the textured mesh, nine-bone rig, packed images, review lights/camera and an eight-second wind preview action. `prepared/Willow.fbx` contains only the two meshes and rig, embedded textures and baked preview animation. `Willow.mesh.json` transports the same bind-pose geometry/UVs/weights into the upload-independent Studio QA scene.

Run from the repository root with Blender 4.5.9 LTS on PATH:

```powershell
node scripts/willow/prepare-atlas.mjs
blender -b --factory-startup --python-exit-code 1 --python scripts/willow/build_willow.py -- --no-render
blender -b --factory-startup --python-exit-code 1 --python scripts/willow/validate_export.py
node scripts/willow/manifest.mjs
npm run tools
npm test
node scripts/build-willow.mjs
```

Open `build/Willow-Prototype-ART-PENDING.rbxlx` and press F5. This isolated scene has no production server, economy, profile loading, remote requests or existing island trees. Local EditableMesh/EditableImage data is rebuilt once per Play; 20 copies share two mesh resources and two images. This is a QA transport, not the proposed production delivery path.

Seed 76117; 84 groups, 252 curved seven-segment ribbons; 6,119 triangles (2,591 wood + 3,528 foliage); two materials/MeshParts, nine bones, at most two vertex influences. The trunk is unskinned. Original source had 4,535 triangles, no UVs/materials/rig, 138 disconnected components. Largest woody component was repaired; 137 detached coarse leaf components and 49 attached fin faces were removed. Voxel repair retains the S-trunk/major branch silhouette, and explicit duplicate removal prevents coincident faces.

FBX export uses `FBX_SCALE_UNITS`; importer Scale Unit **Stud**, factor **1**, Keep Zero Influence Bones and Anchored enabled, no cages. Native importer recognized two meshes/nine bones and the intended dimensions. **Do not repeat imports yet:** during verification Studio created online asset IDs even though Upload to Roblox had been unchecked. See the incident in `docs/WILLOW_TREE_PROTOTYPE.md`; no IDs are used by the reproducible QA build.

## Wind and quality

Only `EnvironmentView` owns scene lighting/GlobalWind. `qa/willow/Wind.luau` reads that wind on the client using one bounded Heartbeat scheduler; it writes only crown Bone.Transform values. Trunk/root stay fixed; phases vary by sector/tree.

| Mode | Updates/s | Radius | Maximum animated trees | Amplitude |
|---|---:|---:|---:|---:|
| Full | 30 | 220 | 20 | 1.0 |
| Reduced | 15 | 150 | 12 | 0.8 |
| Minimal | 6 | 90 | 6 | 0.4 |

Reduce Motion resets all bones to rest and disables sway. Distant/unparented trees reset once; stop disconnects and clears resources. Transparent leaves have no collision, touch or query; one invisible trunk box provides simple collision. The high branch overhangs intentionally have no collision.

Keys: 1 front, 2 side, 3 angle, 4 back, 5 walking camera; T one/20 trees, Q quality, R Reduce Motion, P ten-second measurement, H label visibility. Client Command Bar: `workspace.WillowQA:Invoke("camera","front")`; actions also include `count`, `quality`, `motion`, `time`, `pose`, `inspect`, `measure`, `stop`. Do not use this QA control surface in production.

The game-dev CLI is unavailable on this host; the requested Blender Python pipeline and direct Studio checks were used. No game-dev validation is claimed. No island/gameplay integration, merge, game publication or paid generation was performed.
