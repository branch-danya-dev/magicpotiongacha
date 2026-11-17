# Willow V2 — ordinary playable preview

Status: **CODE CANDIDATE / PARTIAL STUDIO QA / OWNER ART PENDING**.
Base: `08e7603a124807318236ed6521e97ac1ea9f6277` (`feat/current-game-studio-qa`).
Feature: `feat/willow-v2-art-polish`. Exact build HEAD and SHA-256 are recorded in
`build/willow-v2/game-build.json`; the PR identifies the committed source revision.

## Owner delivery

Use **`build/PotionTycoon-WillowV2-Game-QA.rbxlx`**, not the diagnostic art scene.
Rebuild with `node scripts/build-willow-v2-game.mjs --owner-user-id=11924805007`.
The convenient local copy is `G:\Codex\PotionTycoon-WillowV2.rbxlx`.
Open this file and press F5. The game includes the normal character/camera, HUD,
starter familiar selection, Spellbook, stations, grass, moon cycle and island.
The new willow occupies the existing hero location at relative `(47, .38, -29)`.
There is no benchmark platform, fixed inspection camera or automatic camera tour.
The inherited settings menu controls quality and Reduce Motion.

This is an **ordinary game in a Studio-only local preview**. Production `src`,
V8 saves, economy, station coordinates, `default.project.json` and V1 assets are
unchanged and checked against the base. Memory-only profiles reset between Play
sessions. Real purchases, trading and live persistence remain disabled. No game
publication, merge, new Roblox asset upload or access change was performed.

## Art and reuse

| Property | Candidate |
|---|---|
| Height before instance variation | 30.99751 studs, +29.98% from V1 |
| Geometry | 5,783 triangles: 2,591 wood + 3,192 leaves |
| Crown | 76 hanging groups / 228 curved ribbons; three layouts |
| Roots | Three restrained variants of the original curved base |
| Palette | Three foliage tints, four bark tints |
| Instance size | Stable 0.96–1.04 variation, after proportional geometry editing |
| Shared resources | Six mesh templates, two images, two materials per tree |
| Rig | Nine bones, no more than two influences per vertex |

Trunk/large branches are lengthened nonuniformly; crown anchors rise more than
the strand tips. Narrower curved ribbons and gaps break up the solid crown.
Foliage tint reduces weighted palette brightness by about 18% and reduces yellow.
The existing Meshy trunk, UVs and texture pixels are preserved. Bark tints provide
warm wood variation while retaining the source shading. Three FBXs, a packed
Blender file, runtime mesh JSON and hash manifest are under
`assets/environment/willow-v2/`. See its README for the reproducible source path.

`qa/trees/TreeVisualConfig`, `TreeWindModel`, `TreeWindController` and `TreeModel`
separate species appearance, motion math, scheduling and Studio preview rendering.
Only willow is implemented. Stable tree IDs determine appearance; no appearance
randomization occurs on rejoin. Six cached meshes support mixed crown/root choices.

Wind consumes existing `workspace.GlobalWind`; no additional wind or lighting
owner. Base amplitude 0.077 radians (+40% over 0.055), speed 0.82, gust response
0.55, smoothing 1.1 seconds, branch delay 0.16 and phase spacing 0.79. Long branch
factors range 0.5–1.35. One Heartbeat scheduler caps Full/Reduced/Minimal at
30/15/6 Hz, 220/150/90 studs and 20/12/6 active trees. Reduce Motion restores
identity bone transforms; trunk is static. Only the trunk has a simple collider.

## Verification and limits

- Local pinned Luau 0.745 / Rojo 7.7.1 setup, compilation, portable analysis,
  regression suite and reproducible builders are run via `npm run tools` and
  `npm test`. The suite contains 1,406 Luau and 28 Node tests, including 14 new
  Willow V2 checks. Exact final-run and CI outcomes are reported in the PR.
- Blender 4.5.9 roundtrip: all three FBXs retain geometry counts, UVs, nine bones
  and bounded weights. Preview motion displacement 1.1437–1.14545 studs, static
  trunk 0. FBX baked loop seam is 0.00715–0.00718 studs (under 0.01 tolerance).
- Station/route checks cover all 13 inherited station footprints, the central
  path and trunk collider. Low geometry stays outside the building area. Some
  high foliage overhangs the edge above 7 studs; future tall buildings still need
  explicit clearance review. This is not a guarantee for unbuilt architecture.
- Actual Studio Play diagnostic log on 2026-11-17 at 10:00 UTC confirmed loading
  local geometry/material resources, nine bones, one lighting owner, all three
  crown/root/foliage and four bark variants across 20 instances. Twenty quality
  cycles retained 300 tree descendants, six mesh resources, two images and one
  scheduler connection; Reduce Motion identity restoration passed.
- That diagnostic run ended before the timed 1-versus-20 benchmark, walking and
  cleanup sequence finished. A single scheduler sample was 0.0452 ms; it is **not
  an FPS or performance result**. No completed native performance result exists.
- Its initial pose checks waited only two seconds during an eight-second
  environment transition. They do **not** establish settled day/dusk/night
  verification. The optional harness now waits nine seconds and runs only on K,
  never automatically. The normal gameplay build contains none of this harness.
- Opening the replacement ordinary-game file could not be completed through
  text-only Studio control: element actions report unavailable cached elements;
  the dialog did not accept field focus. The unfinished Open dialog was cancelled.
  The new ordinary-game V2 Play, walking and settled lighting checks therefore
  remain **PENDING**, separate from the earlier diagnostic Play evidence.
- Texture alpha pixels are unchanged; softer geometry and the existing alpha
  gradient form the candidate edge treatment. Visual softness, bark naturalness,
  branch movement and overall composition require owner review. FBX consumers
  must apply the documented material tints; importers may omit Blender MixRGB.
- V2 currently uses local EditableMesh/EditableImage in Studio, not new cloud
  MeshIds. Production/native V2 upload and permission verification remain gated
  on owner approval. V1 Restricted IDs are preserved and not represented as V2.
- Real phones, multi-client behavior, live persistence and artist acceptance are
  untested. No screenshots, videos, GIFs or renders were created.

The optional `build/WillowV2-ArtPolish-QA.rbxlx` remains a developer diagnostic
tool only. It is not the requested owner-facing game scene.
