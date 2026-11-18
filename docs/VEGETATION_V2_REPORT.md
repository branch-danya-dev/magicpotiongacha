# Vegetation V2 — first pair, code and local build

Status: **FIRST PAIR CODE CANDIDATE / STUDIO NOT RUN / OWNER ART PENDING**.
This is not completion or admission of the nine-model library. On 2026-11-18
the owner deferred Studio work and requested code/build only.

Branch: `feat/vegetation-v2-library`.
Base: PR #62, `deb2ba18e1dda7f68713923a1e6164abd0df7f0f`.
Base Windows/Ubuntu CI: run `44339538104`, both successful. Candidate CI is
not inherited from that result; see verification below.

## Source audit and current scope

All nine exact Sketchfab UIDs were read through the public model metadata API
on 2026-11-18. Each declares downloadable content under CC BY 4.0, including
dungdao. Author/profile/license links are recorded in
`assets/environment/vegetation-v2/ATTRIBUTION.md`, with metadata in
`source-audit.json` and explicit admission states in `catalog.json`.

| Model | Status |
|---|---|
| Stylized Tree — stefan | Original archive retained; two local derived candidates |
| Magic Tree — Igor Zukowicz | Original archive retained; two local derived candidates |
| Oak Tree — Maple | **BLOCKED_NOAI**; metadata only; no source download, import or generative processing |
| Magic tree — nyomryu | Waiting for the first pair's complete Studio gate |
| Fantasy Tree — Šimon Ustal | Waiting for the first pair's complete Studio gate |
| Sakura Tree 01 — Jogoss | Waiting for the first pair's complete Studio gate |
| Japanese Cherry Tree — Sereib | Waiting for the first pair's complete Studio gate |
| Stylized Tree — Voyage | Waiting for the first pair's complete Studio gate |
| Stylized Tree — dungdao | CC BY 4.0 declaration explicitly verified; waiting for first pair |

The NoAI restriction is honored independently of the CC license wording.
No alternative asset was substituted for a requested source.

Original authenticated downloads and extracted files are unchanged and pinned
in each `sources/<key>/receipt.json`. Derivative hashes are in `manifest.json`.
The `game-dev` CLI is unavailable on this host, so this uses the project's
existing direct Blender/Rojo approach; no canonical game-dev admission receipt
is claimed. No paid provider or generative image/3D service was used.

## Prepared candidates

| Species | Natural triangles | Windswept triangles | Editable parts | Bones | Atlas |
|---|---:|---:|---:|---:|---|
| stefan | 3,322 | 3,092 | 5 | 10 | 512 × 512 |
| Igor Zukowicz | 8,020 | 8,018 | 7 | 10 | 1024 × 1024 |

Each `prepared/<key>/` contains `Editable.blend`, `Natural.fbx`, `Windswept.fbx`,
`Atlas.png`, `Tree.mesh.json`, `build-report.json`, and `validation.json`.
Roots/Trunk/Branches/Foliage/FoliageSecondary are independently editable.
Magic Tree also has stone and crystal extras. The original preview armature
and drop-shadow plane were omitted from the derivative. Degenerate source
faces are removed; geometry is not increased.

Geometry controls live in `geometry-presets.json`: trunk height/width/curvature,
branch spread, crown size/shape and foliage density. Change the recipe and rerun
the Blender builder to produce new geometry. Blender custom properties record
the recipe; they are **not live Geometry Nodes sliders**. The two presets have
distinct geometry and are also independently editable in the `.blend` file.

Density removes complete small disconnected leaf cards. It does not cut holes
in connected crown surfaces; therefore Magic Tree's density change is modest
(two triangles here), while its height, crown shape and spread do change.

The original textures are retained. The preview uses one padded albedo/alpha
atlas per species, independent material tint channels and smooth wood normals
across editable part boundaries. Original normal/PBR maps are not applied in
this mobile atlas prototype. That visual simplification needs owner review.
Stefan's converted leaf mask is taken from alpha, not its white RGB channels.

## Runtime and isolation

`qa/vegetation` is an isolated extension of the existing tree architecture.
The generated ordinary-game QA scene replaces its tree-wind entry point with
one `TreeWindController`, shared by the existing willow and the two candidates.
It does not start a second controller alongside the old one. Original
`qa/trees` files and all R3/R4 World Tree, horizon and cloud sources stay intact.

- Visual updates are client-only and read `Workspace.GlobalWind`.
- Root bones stay at identity. Trunk response is weaker than branches;
  matching crown sectors have delayed response and stronger motion.
- Stable per-instance phases; consistent bone phases across separate mesh parts.
- Natural, Enchanted and Blossom palettes; separate BarkColor, LeafColor,
  LeafSecondaryColor, MagicGlowColor/Intensity, GeometryVariant and WindStrength.
- Crystal glow uses a local SurfaceAppearance emissive mask, without new lights
  or changes to global Bloom/Lighting.
- Per-species active caps: Full 8, Reduced 4, Minimal 1. Global caps remain
  20/12/6 including the willow. Near rates are 30/15/6 Hz, with lower middle/far
  rates and no motion past 180/125/70 studs for the candidates.
- Reduce Motion resets bones. Variant changes stop the scheduler and release
  previous meshes before allocating replacements. Allocation/rig failure keeps
  the existing willow operational and reports a clear error.
- `RenderFidelity.Automatic` is requested; distant skeletal motion stops.
  Hand-authored low-poly mesh LODs are **not yet prepared**.
- Candidate surfaces are non-collidable; original collision and station data
  remain unchanged. Final placement/colliders are not admitted to production.

The raw atlas allocation is 5 MiB for the pair, shared across their instances.
Only one geometry variant per species is loaded at a time: 12 editable meshes
and 2 images for the pair. These are allocation counts, **not device memory or
FPS measurements**. Dense transparent foliage/overdraw remains a native check.

No game authority, Factory, economy, saves, remotes, stations, routes or
publication settings were changed. No mass replacement of island vegetation.

## Reproduce

From the repository root, with existing Blender 4.5.9:

```powershell
python scripts/vegetation/test_staging.py
# Repeat for stylized_stefan and magic_igor:
blender --background --factory-startup --disable-autoexec --python-exit-code 1 --python scripts/vegetation/build_pair.py -- stylized_stefan
blender --background --factory-startup --disable-autoexec --python-exit-code 1 --python scripts/vegetation/validate_blender.py -- stylized_stefan
node scripts/vegetation/manifest.mjs
npm run tools
npm test
node scripts/build-vegetation.mjs --owner-user-id=11924805007
```

The portable Blender executable on this host is
`G:\Codex\2026-11-04\github-issue-4-m1-https-github\work\tools\blender-4.5.9-windows-x64\blender.exe`.
Do not enable scripts from downloaded `.blend` files. The source staging tool
refuses NoAI sources, path escapes, symlinks, unexpected executable files,
case-colliding names and oversized archives before extraction.

Mesh JSON and PNGs should reproduce exactly from the recipe; Blender/FBX
container metadata can change on re-export. Refresh the derivative receipt
only after validating the new exports. The original download hashes remain fixed.

QA build: `build/PotionTycoon-VegetationV2-FirstPair.rbxlx`.
Owner copy: `G:\Codex\PotionTycoon-VegetationV2.rbxlx`.
The sidecar `.build.json` records exact source HEAD and place SHA-256.
This is an ordinary game with memory-only QA profiles, the existing HUD,
familiar selection and normal camera. Candidates are placed near the south
corners for inspection; their placement still needs native review.

## Verification

Local Blender checks passed for all four FBX exports: 10-bone round-trip,
normalized weights with at most four influences, unchanged topology count,
moving foliage and stationary roots/extras. Both editable files have packed
textures, organized variants and two retained authoring wind-preview actions.
No Blender render, screenshot or video was produced.

Windows: `npm run tools` PASS (hash-pinned Luau 0.745/Rojo 7.7.1).
`npm test` PASS: **1,443 Luau + 43 Node = 1,486 tests**, 319 Luau sources compiled,
portable analysis and inherited Rojo builds passed. All 1,472 inherited tests
remain; 14 new Luau/Node checks passed. Seven additional Python intake tests
passed. Two pre-existing test lint warnings remain (unused `session` and shadowed
`second`); no new type errors. Logs: `build/vegetation/test.log` and `tools.log`.

Repeating Blender preparation reproduced the exact mesh JSON and PNG hashes
for both species, followed by another successful four-FBX reimport. Derivative
receipt and asset tests passed after that repeat.
Candidate GitHub Windows/Ubuntu CI: **NOT RUN** (local branch; no push/PR in this
delivery). The base's successful CI is not evidence for the candidate.

| Check | Status |
|---|---|
| Original archive integrity and declared licenses | PASS for first pair; metadata for all nine |
| Blender numerical preparation / FBX reimport | PASS, 4 exports |
| Native Studio Play / materials / bones / day-night | **NOT RUN — owner deferred to code/build only** |
| Real mobile performance, multiplayer | **NOT RUN** |
| Owner visual acceptance | **PENDING** |
| Remaining six non-NoAI models | **WAIT FIRST PAIR STUDIO GATE** |
| NoAI Oak | **BLOCKED** |
| Roblox uploads/permissions | None performed; any new upload requires approval |
| Merge / Roblox publication / production integration | None |

For the later native check, open the owner copy and use F5, then choose a
familiar. On the **client** Command Bar, these local QA calls are available:

```lua
workspace.PotionTycoonWorld.VegetationQA:Invoke("inspect")
workspace.PotionTycoonWorld.VegetationQA:Invoke("palette", "Enchanted")
workspace.PotionTycoonWorld.VegetationQA:Invoke("variant", "Windswept")
workspace.PotionTycoonWorld.VegetationQA:Invoke("appearance", {WindStrength = 0.7, MagicGlowIntensity = 0.4})
workspace.PotionTycoonWorld.VegetationQA:Invoke("checks")
```

`checks` is a bounded numerical routine: palette/variant swaps, 20 quality/motion
changes, root identity, object counts, non-collision, ordinary camera, frame and
wind-update timings. It restores the prior candidate state and makes no
captures. Day/dusk/night still use the existing `CurrentGameQA` lighting owner.
No automatic results from this routine are claimed before it actually runs.
