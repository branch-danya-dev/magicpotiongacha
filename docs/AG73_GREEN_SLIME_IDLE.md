# AG73 — Green Slime rig and Idle

2026-11-15. **PHASE A CANDIDATE / PARTIAL STUDIO PREVIEW VERIFIED /
OWNER ART PENDING / NOT PUBLISHED.** Issue #48 remains open.

Branch: `feat/ag73-green-slime-idle`. Exact base: PR #45
`feat/ag71-ui-art-concepts` @ `8dc804ab33e3f9d052dc4d15a97d90b3cd46a02b`,
Windows/Ubuntu CI run `43607496544` SUCCESS. This is independent of AG72/PR #47.
Final delivery HEAD and its exact CI run are recorded in the Draft PR to avoid
self-referential commit receipts.

The isolated asset package contains owner source copies, a reproducible
nonhumanoid Blender rig, normalized skinning and one 3.2-second Idle clip.
No `src/`, gameplay tests, Rojo mappings, HUD, economy, saves, remotes, starter
grant or live asset registry changes. The ordinary game build does not load this
candidate. Rollback removes the package, checker and task-specific documentation.

## Checks performed

| Check | Result / limits |
| --- | --- |
| Owner source access | PASS: real local files read; FBX matches issue hash |
| Source texture consistency | PASS against verified FBX's embedded PNG; supplied PNG differs from issue's listed PNG hash; discrepancy retained in provenance |
| Rights | Owner confirms paid Meshy generation in own account; source terms reviewed; not a CC0 asset or independent input-rights audit |
| Clean source inspection | One geometry_0 mesh, no imported Cube/Camera/Light; 1321 vertices, 2603 triangles; 35 boundary edges belong to eye rims |
| Rig/weights | Eight bones; <=4 normalized weights per vertex; no Root weights; eye rims rigid to Head |
| Evaluated 97-frame Idle | Seam delta 0; minimum ground clearance 0.0127999997 authoring units; maximum travel 0.0522483; maximum local edge strain 28.54% |
| Seam velocity diagnostic | Maximum first/last one-frame displacement difference 0.000113801 units; not a claim of exact derivative equality |
| Fresh FBX imports, Blender 4.5.9 | Both files: 1 armature, 1 mesh, same 8 bones, vertices/tris, <=4 weights, exact packed PNG; rest file has no action |
| Fresh animated FBX | One 3.2-second action, frame range 1–97 at 30 FPS; seam delta 0; min ground 0.0127998516; quarter-cycle travel 0.0359454 |
| Render review | Neutral, head tilt, center compression/edge stretch and all sampled Idle frames inspected; silhouette/eyes preserved, no observed ground penetration or tearing; compression min ground 0.0127999997 |
| Native Blender | Saved scene opened in installed 5.3.0; hierarchy inspected and timeline playback observed advancing; no resave in 5.3 |
| Native Roblox 3D Importer | Local rest FBX preview displayed original texture and all 8 bones; preview closed without final import |
| Ordinary Studio Play / Animator | **BLOCKED: import uploads underlying data; new asset upload not authorized** |
| Low graphics / physical phone / collision proxy | **NOT RUN**, require native imported rig; no performance claim from Blender |
| Owner visual approval | **PENDING**, required before Move/React/VFX and live upload |

Numeric deformation checks establish continuity and ground bounds, not artistic
acceptance. A 28.54% peak local edge strain warrants visual review of extreme
poses; it is below the recipe's explicit 35% diagnostic threshold, not a Roblox
quality standard. No new animation or rig IDs have been created.

## Evidence and reproduction

- [Rig, build instructions and native handoff](../assets/familiars/green_slime/rig_v1/README.md)
- [Source rights, hashes and discrepancies](../assets/familiars/green_slime/source/PROVENANCE.md)
- [Complete package manifest](../assets/familiars/green_slime/manifest.json)
- [Blender hierarchy](evidence/ag73/blender-hierarchy.jpg)
- [Studio importer preview only](evidence/ag73/studio-importer-preview.jpg)
- [Actual Blender Idle video](../assets/familiars/green_slime/rig_v1/previews/GreenSlime_Idle.mp4)
- [Neutral](../assets/familiars/green_slime/rig_v1/previews/neutral.png),
  [head test](../assets/familiars/green_slime/rig_v1/previews/head_test.png),
  [edge test](../assets/familiars/green_slime/rig_v1/previews/edge_test.png),
  [center compression](../assets/familiars/green_slime/rig_v1/previews/center_compression.png)

`npm test` now also checks each package digest and parses the actual FBX geometry,
skin clusters and animation curves offline on Windows/Ubuntu. This does not run
Blender or Roblox on CI. The explicit Blender recipe/re-import checks are separate
recorded local checks. Inherited test/build results and CI links are in the PR.
