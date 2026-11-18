# AG-76B Sky World Tree

**Current candidate: [R3 — directional lighting and horizon investigation](SKY_WORLD_TREE_R3.md).**
Previous candidate: [R2 — monumental crown and cloud ocean](SKY_WORLD_TREE_R2.md).
The remainder of this document preserves the historical R1 implementation/results.

**CODE CANDIDATE / STUDIO RETEST PENDING / OWNER ART PENDING.**
Base: `6540ba350cb933c598d5abe0eb22167878e55fc9` (Draft PR #60, Windows/Ubuntu
green). PR #59 `fdaf931b179ad188555147c720b768dd9334b17b` is already an ancestor;
neither PR is merged. Branch: `feat/ag76b-sky-world-tree`. Exact candidate HEAD
and place SHA-256 are in the build receipt and Draft PR.

## Deliverables and rebuild

- Original concept + separate transparent tree/cloud/glow masters:
  `assets/environment/sky-world-tree/source/` (all 1536x1024).
- Original generation requests, provenance and byte hashes: `generation.json`
  and `manifest.json` in the same package. No third-party game image references.
- Four optimized PNG layers, including the static Minimal composition.
- `qa/sky-landmark`: world renderer, pure presentation model/config, resource
  cache and optional numeric diagnostics.
- `node scripts/build-sky-landmark.mjs --owner-user-id=11924805007` creates
  **`build/PotionTycoon-SkyWorldTree-QA.rbxlx`**, the ordinary playable game.
  Use F5, choose a starter familiar and use the normal character camera.
  Owner copy: `G:\Codex\PotionTycoon-SkyWorldTree.rbxlx`.
- `node scripts/sky-landmark-assets.mjs` deterministically exports from the
  preserved masters. Source generation is not claimed to be seed-reproducible.

## Rendering candidate and budgets

A single world-anchored `BillboardGui` with `AlwaysOnTop=false` holds six fixed
ImageLabels. Local EditableImages are prepared once and shared by those labels.
Using one GUI gives explicit internal Z-order: glow, tree, haze, stationary cloud,
drifting cloud, Minimal composite. Nearby geometry can depth-occlude the GUI.
This avoids a camera-locked overlay, a rigged 3D model or a replacement skybox.
Billboard orientation avoids oblique quad distortion. **This remains a candidate
choice until the owner confirms visual occlusion/appearance in Play.** Numeric
projection and object properties do not prove absence of a sticker-like look.

Reference: [Roblox BillboardGui documentation](https://create.roblox.com/docs/reference/engine/classes/BillboardGui).

World offset from island origin: `(-910,-672,-3360)`, square billboard size 2576
studs. Transparent padding means the actual visible crown is much smaller than
the square. The crown is around/below island height, with no visible ground,
root or supporting platform. Apparent scale varies less than 5% across the
124x116 island. No collision, touch, query, interaction, light or physical rig.
The existing under-island cloud bank remains intact; these cloud layers only
serve the landmark, not a second global cloud system.

| Budget | Result |
|---|---|
| EditableImages | 4, fixed across quality changes |
| Decoded RGBA | 6,553,600 bytes / 6.25 MiB (not total application memory) |
| World instances | 9: folder, invisible anchor, GUI, six labels |
| Steady Full / Reduced / Minimal visible layers | 5 / 3 / 1 |
| During quality crossfade | At most 6 |
| Update caps | 30 / 15 / 5 Hz, invoked by existing EnvironmentView loop |
| Additional render/Heartbeat connections | 0 |
| Lifecycle connection | 1, disconnected on destruction |
| New lights / meshes / emitters / remotes | 0 for the landmark |

The renderer receives the already blended environment sample, existing lunar
weights and existing GlobalWind. Day silhouette is pale; dusk and night increase
readability and restrained champagne glow. Blood/frost make small tint changes,
never replace the original colors. The 1500-second cycle and 60/20/20 selection
are untouched. Cloud drift follows the signed horizontal wind projection.
Minimal/Reduce Motion freeze additional motion; day/weather transitions remain
under the existing owner. No global Bloom/Lighting changes are introduced.

The transparent tree bottom is permanent; drifting clouds cannot uncover a hard
lower edge. Minimal uses a precomposited layer; mode switches reuse all resources
and crossfade without per-frame texture writes or allocation.

## Checks and evidence boundary

Local tests cover scale/placement, input immutability, lunar/clock preservation,
continuous palettes/weather, motion freezing and direction, budgets, resource
caching/disposal, allocation failure, PNG hashes, soft alpha and transparent
borders. Inherited tests remain in `npm test`. CI checks both Windows and Ubuntu
on the exact PR HEAD. Final results are recorded in the PR.

An actual ordinary F5 development run in Studio **0.748.0.7481526** on 2026-11-18
confirmed the server loaded all 13 stations, V8 and memory-only owner admission.
The landmark allocated four images and nine instances, wrote pixels four times,
and added no render connection. Day/dusk/night settled at clock 13/18.55/night;
the three moon transitions, twenty quality switches, frozen Reduce Motion,
resource destruction and restoration of twelve Lighting properties + GlobalWind
passed the numeric probe. Day/dusk moon angular separations were about 85.6° and
108.7°. Full pose/moon-cycle overlap still needs owner inspection.

**That run also exposed an inherited Willow V2 EditableMesh budget failure.**
Consequently it is not evidence of a clean final game or accepted performance.
The generated composition adapter now allocates only the exact hero's selected
root mesh and crown mesh (two), instead of eagerly preparing all six variants.
It preserves that tree's vertices, UVs, materials, bones and deterministic choice;
the PR #60 source module and assets remain unchanged. This fix compiles/builds,
but its runtime retest is **PENDING**: the owner explicitly requested continuing
only code/build work when Studio's save dialog blocked text-only control.

The development timing sample (90 frames/mode) was 4.0–4.3 ms median frame time,
5.25–5.51 ms p95 and 0.0145–0.0234 ms sampled landmark update time. Application
memory was about 3137 MiB. These are **not accepted performance metrics**: the
willow failed and the old probe did not wait for complete quality crossfades.
The probe now waits five seconds. No fresh performance/phone claim is made.

The initial camera was Scriptable during starter selection. No player-camera
override was added by the landmark. Free walking, a manual 360° camera sweep,
visibility from several island positions, visual transparency/depth order,
distortion, final dusk/night aesthetics and absence of a flat-sticker effect
remain owner/native checks. No screenshots/videos were created to evaluate them.
No mobile device, multiplayer or real-backend checks were performed.

## Safety, fallback and rollback

Production `src`, default project, lunar/Willow sources/assets, economy, V8,
stations, routes and island geometry are protected against the base. The build
is Studio-only, with memory-only profiles, trading/monetization disabled. An
allocation failure disposes partial landmark resources and logs a concrete error
without replacing or taking ownership of the environment. Native V2 asset
uploads, access changes and production integration remain separately gated.
Rollback: open the unchanged Willow V2 game preview. No merge, publication,
paid provider job or new Roblox upload/access grant was performed.
