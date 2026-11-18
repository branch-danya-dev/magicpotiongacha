# Island vegetation — Stage 1 grove

**CODE CANDIDATE / STUDIO LOAD VERIFIED / OWNER ART REVIEW PENDING.**
This is the requested first trial composition. Whole-island planting (Stage 2)
and final art acceptance remain gated on the owner's review of this build.
No screenshots/video, Roblox uploads, permission changes, merge or publication.

Branch: `feat/island-vegetation-pilot`.
Exact local dependency: `b9c5a3c1ba99f5f6079a91ffe9f53f3f823bcf1e`
(Vegetation V2). Confirmed remote parent: Draft PR #62
`deb2ba18e1dda7f68713923a1e6164abd0df7f0f`, still Draft/open, CI Windows/Ubuntu PASS.
The new PR includes the unpublished first-pair library commit as a dependency;
it targets the R4 branch, not bootstrap main.

## Composition and source rights

An asymmetric southwest rim grove, with a deliberate open interval at the
concave cliff notch and a lower foreground group. No uniform tree wall or
procedural runtime scatter. The west magic tree is a small accent; the distant
World Tree remains the landmark. Island surface, World Tree/clouds/lunar light,
13 stations, waypoints, camera, book, economy and V8 are unchanged.

| Instance | Model / geometry | X / Z | Scale / yaw |
| --- | --- | --- | --- |
| West broadleaf | stefan / Natural | −47 / 18 | .50 / 20° |
| Foreground leaning tree | stefan / Windswept | −20 / 37 | .42 / −65° |
| Low foreground broadleaf | Quaternius CommonTree_5 | −9 / 43 | .62 / 48° |
| West conifer | Quaternius Pine_2 | −53 / 2 | .40 / 110° |
| Restrained magical tree | Igor Zukowicz / Natural | −51 / −12 | .42 / 190° |

Coordinates are relative to `PersonalIsland.origin`. These are three ordinary
model types and one magical type, not three newly downloaded species.

- [Stylized Tree — stefan](https://sketchfab.com/3d-models/stylized-tree-4475c38dac544c8abe49ffa602df6595)
  and [Magic Tree — Igor Zukowicz](https://sketchfab.com/3d-models/magic-tree-ba0869cea1944722825abf4d18a6ae41):
  recorded **CC BY 4.0**, modified as documented in
  `assets/environment/vegetation-v2/ATTRIBUTION.md`. Original archives, license
  metadata, hashes, Blender sources and FBX roundtrip reports retained.
- Quaternius Standard **CC0**, existing admitted templates: CommonTree_5, Pine_2,
  Bush_Common_Flowers, Fern_1, Grass_Common_Short, Flower_3_Group.
  `assets/environment/woodland/receipt.json` and template hashes rechecked.
- No new downloads or paid jobs. NoAI Maple remains excluded; the other six
  unprepared Sketchfab sources are not used. No additional Roblox IDs introduced.
- Existing Roblox mesh permissions/loading need native verification. The first
  pair uses local Studio EditableMesh/EditableImage, not newly uploaded assets.

The old willow and its ancient-tree proxy are absent from the active candidate.
Their original sources and all earlier QA builds remain intact. The candidate
does not even allocate or replicate the willow's former image/mesh payload.
Existing background vegetation outside the pilot remains unchanged.

## Editable models, wind and LOD

`qa/landscape/Plan.luau` is the reproducible placement/palette recipe. The first
pair retains the two Blender/FBX geometry variants prepared in Vegetation V2.
Per-instance scale/yaw vary silhouettes; source rigs preserve independent trunk,
branch and foliage weights. This does not claim live geometry-node sliders.
Current color multipliers use restrained green, grey-brown and muted teal/lilac;
magic emissive strength is .12, attenuated at lower quality. **Zero new lights.**

The existing Vegetation wind scheduler owns only the three skinned candidates.
Maximum animated candidates: **Full 3 at 24 Hz / Reduced 2 at 12 Hz /
Minimal 1 at 5 Hz**, further reduced by distance. Strength varies .56–.88;
stable ID phases differ, root bone strength is exactly zero. Reduce Motion
restores all bones. Minimal leaves the magical tree static.

Quaternius leaves/ferns/grass reuse the existing EnvironmentView plant animation
and quality culling. Their trunks are static. The skinned trees live outside
EnvironmentArt, preventing competing transform/visibility writers. No change to
EnvironmentView, GlobalWind or time ownership; no new frame loop relative to the
previous Vegetation preview. The existing 5 Hz additions poll handles optional
secondary-foliage fades. Main silhouettes stay visible; RenderFidelity.Automatic
is retained. This is distance/animation/detail LOD, **not new low-poly mesh LODs**.

All new decorative parts have collisions, touch and queries disabled. Trees and
plants are seated once by Terrain-only raycast. The portable clearance audit
includes the actual R3 concave coastline, full scaled crown envelopes, all 13
stations/waypoints, service points, six-stud book route and three World Tree
sightline corridors. The envelope test reads actual prepared mesh vertices.
Passing it does not prove every third-person camera angle is unobstructed.

Allocation/rig failures release partial Editable resources and report a blocker.
Static setup failure removes its partial group and does not stall other art
initialization. Quality/motion switches reuse the pool; scene destruction stops
wind and destroys resources. Native failure injection remains unperformed.

### Native loading regression and fix (2026-11-18)

The owner's Play of `0910661` reproduced a real failure: static planting created
34 parts, but the seventh expandable EditableMesh allocation failed in Cliff,
aborting Additions before Grove.start. The six R4 branch meshes already held
expandable capacity. The old successful build/test result did not cover this
native memory limit.

The isolated candidate now shares one MeshFactory across R4, cliff and grove.
Each recipe uses a serialized temporary expandable mesh, clones the completed
topology into a FixedSize mesh, then destroys the temporary mesh. Native vertex,
face and bone counts are checked across compaction. The retained resources are
24 fixed meshes (6 R4 + 1 cliff + 17 grove), with at most one expandable scratch.
The original source geometry/rigs and protected modules remain byte-identical;
the builder generates these allocation adapters only for this candidate.
Cliff startup is isolated so an unrelated failure cannot suppress the grove.

Ordinary F5 on the owner Fix build at **2026-11-18 20:42:12 UTC**, Studio
0.748.0.7481526, produced `LANDSCAPE_CLIENT_STATE ready=true`: **3 rigged trees,
17 meshes, 3 images, 150 rigged descendants, 34 static parts**, one wind connection.
Allocation counters: **24 completed / 0 failed / 0 live scratch / peak 1**.
`WIZARD_CLIFF_READY` reports the unchanged **3,936 vertices / 7,868 triangles**.
The initial full-game diagnostic reports one Lighting owner and no active willow.
This proves runtime creation, not artistic visibility or correct deformation at
every angle. Reported client memory was approximately **2,848 MiB**, a whole-game
Studio snapshot, not a grove-only cost, steady-state figure or mobile benchmark.

The native run used the pre-commit Fix artifact; its hash and the final delivery
hash are recorded separately in the PR. No screenshot/video was taken. Quality
cycling, camera/wind/skin appearance, teardown/failure injection, FPS comparison,
physical phones and multiplayer still require separate verification.

## Resource budget and checks

New pilot content, before subtracting removed old trees/undergrowth/willow:

| Resource | Budget |
| --- | ---: |
| Skinned / static trees | 3 / 2 |
| Low-plant models | 22 |
| Rigged geometry | 14,434 triangles / 17 MeshParts |
| Static trees + undergrowth | 9,834 triangles / 34 MeshParts |
| Total added pilot geometry | 24,268 triangles / 51 MeshParts |
| EditableMesh / EditableImage pools | 17 / 3 |
| Shared retained meshes (R4 + cliff + grove) / transient expandable cap | 24 fixed / 1 |
| Decoded tree atlases | 6 MiB (two 512², one 1024²) |
| Additional lights / update loops vs first-pair preview | 0 / 0 |

The 24 static models contain 92 serialized instances. The first native creation
reported 150 rigged descendants; bone details are available through Studio. The
6 MiB atlas figure excludes mesh buffers, Lua/base64 data and engine overhead.
Compared with the first pair's 5 MiB atlases, the Windswept pool adds 1 MiB;
removing the willow saves other allocations, but **no total-memory/FPS claim**
is made without measurement. Original PBR/normal textures remain in source
archives; this mobile candidate uses the existing albedo atlases.

Validation commands:

```powershell
npm run tools
npm test
node scripts/build-landscape.mjs --owner-user-id=11924805007
```

Local Windows result: `npm run tools` PASS; `npm test` **1,503 PASS**
(1,456 Luau + 47 Node), 325 compiled Luau sources and all inherited Rojo builds.
All 1,486 inherited tests retained; 17 added. Two inherited C01 analyzer warnings
(unused session, shadowed second) remain; no new compiler/type failures.

Eight new portable tests cover clearance, concave root support, protected layout,
mixed-species wind caps and detail fading; three Node tests validate actual mesh
envelopes, resource totals and existing CC0 template digests. Six additional
regressions cover the old allocation failure, fixed retention, error cleanup,
concurrent serialization and all three generated memory adapters. CI builds this
candidate on Windows/Ubuntu with a test owner and compiles its generated adapters.
Exact run results are recorded in the PR; local logs and build receipt are under
`build/landscape/`. Receipt contains source HEAD, owner, asset/environment hashes
and the final `.rbxlx` SHA-256. Repeated builds must match byte-for-byte.

## Owner review in the ordinary game

Owner file: `G:\Codex\PotionTycoon-Island-Vegetation-Pilot.rbxlx`.
Open it in the existing Studio window, F5, choose a familiar and walk toward
the left edge/foreground planting. It is the ordinary game with HUD and book,
normal camera and owner `11924805007`; profile persistence is memory-only.
No screenshot or video is needed. Native F5 creation is confirmed as detailed
above; FPS, mobile performance and full visual/interaction checks are NOT RUN.

Optional Client Command Bar diagnostics after choosing a familiar:

```lua
workspace.PotionTycoonWorld.LandscapeQA:Invoke("inspect")
workspace.PotionTycoonWorld.LandscapeQA:Invoke("checks")
workspace.PotionTycoonWorld.CurrentGameQA:Invoke("quality", "minimal")
workspace.PotionTycoonWorld.CurrentGameQA:Invoke("motion", true)
```

`checks` runs 20 quality/motion changes, checks stable resource counts, fixed
roots and inert collisions, then records 120 frame intervals per quality,
wind timings and total client memory, restoring prior settings. It is opt-in,
not an automatic artistic PASS or real-device benchmark.
`LandscapeQA:Invoke("appearance", {id="quiet-magic", values={LeafColor={.6,.7,.7}}})`
allows material-channel review without geometry churn; commit final choices to
Plan and rebuild. Geometry changes use prepared variants and a rebuild.

Open gates: visual asset delivery and skin deformation, camera/cliff
views, color coherence in day/dusk/night, cleanup/fallback in engine, actual
performance and phones/multiplayer. Whole-island rollout waits for pilot art
approval. No main integration or publication is implied by this draft.
