# M7.1 environment / Gate A contract

**2026-11-05 owner revision:** the primitive pilot below is **ART REJECTED**.
Historical screenshots and 841 passing tests do not pass the artistic or normal
gameplay UI gates. [Revised direction and asset measurements](M7_ART_DIRECTION.md).
The ordered route is revised one-farm Gate A, then #18 UI declutter; #19 full
eight-farm island requires explicit ART APPROVED and the UX check. The free
MegaKit Standard archive is now acquired and statically inspected outside the
repo; canonical admission/import remain BLOCKED because game-dev is unavailable.
No new runtime artwork, imported Roblox IDs or live acceptance is claimed here.

Branch feat/m7-environment-artpass → feat/m6-collectible-monetization (Draft).
EnvironmentArtEnabled=false by default. No publication, merge, payment, public
trading or schema/economy change. M6 V7 and all 810 cases must remain.

## Authority and topology

World's existing eight logical plots, 4×2 origins, 13 stations, auxiliary anchors,
input/output waypoints, floor height, spawn, pads, owner guards, prompts, distances
and Bazaar/TradePost are immutable. New geometry is a separate decoration folder;
it never carries StationId, prompts, remotes or resources. All decoration is anchored,
noncolliding, nontouchable and nonqueryable. Existing functional floor collision
remains. Thin path surfaces do not create a new walking height or collision.

Only Plot_1 is decorated for Gate A, with a small Bazaar framing sample. Other
seven plots remain unchanged. The builder is deterministic and bounded, reusable
later, but Gate B is not enabled by a setting in this delivery. Floor/epoch/theme
presentation is applied after World:update so gameplay ticks cannot revert art.
Personal epochs/aurora never drive global weather. Function remains in old anchors.

## Environment and quality

One client controller owns Lighting, Atmosphere, Clouds, correction and bloom while
the feature is enabled. Synchronized time comes from Workspace:GetServerTimeNow;
shared pure schedules contain no player, economy or persistence references.
Smooth cyclic interpolation, clear/soft rain, no lightning or wetness simulation.
Feature-off leaves old lighting and geometry untouched. Studio-only review poses
must never become client authority over server state.

Full/reduced/minimal are local presentation preferences. Rain and foliage movement
are off in minimal or Reduce Motion. Distance LOD hides detail only, never prompts,
anchors, floors, gates or owned machines. Client-only rain has fixed population;
no server-replicated emitters. Light distance/count caps and modest bloom keep night
readable. Explicit settings are in the existing menu; no new economic Remote.

Billboard text is contextually selected on the client at 4 Hz: closest first,
non-overlapping screen rectangles, <=6 desktop / <=3 narrow-screen labels. This
does not remove parts, change their text, disable ProximityPrompts or alter server
callbacks. Original Enabled values are restored on teardown. The isolated beauty
view can suppress annotations; U restores this same contextual selection for audit.

Provisional Gate A ceilings: 650 decorative primitive parts, <=12 distinct RGB
material groups, <=6 local active lights, <=60 active rain streaks, <=12 animated
foliage groups, zero external textures, zero server particles. Primitive render
tessellation is engine-owned: report part counts and conservative estimates, not
invented mesh triangle measurements. Gate B projections are arithmetic, not a built
or approved full map. Real load time, triangles, FPS, thermal behavior and memory
are BLOCKED until measured on hardware.

## Reproducibility and admission

Pure decoration descriptors → Roblox builder → Rojo build. Every primitive's
position/size/palette is versioned. Local preview is generated from the same source
modules, not a separately painted concept. Archive raw captures with exact source
and named pose; label actual Studio versus mockup. Never claim visuals from code
compilation alone. No external Toolbox code/plugins.

Quaternius official page links a public Drive directory, not a versioned zip.
Record selected files and SHA-256 individually; do not invent an archive hash.
Stage source outside runtime, inspect OBJ/MTL references, verify CC0, then obtain
canonical package verification with game-dev before admission. Native fallback
is original work, not a conversion. Actual mesh import/AssetIds and permissions
remain BLOCKED until that pipeline and owner-authorized Roblox import are available.

## Acceptance

Gate A: one scene, four states and three camera positions; readable UI, open paths,
pure schedule regression and quality ceilings. Full source/test/CI evidence and
live observations are recorded after implementation. The owner's visual decision
is ART REJECTED; a revised implementation is required. Gate B is withheld. DataStore/payment/policy/phone/2–8-player gates remain
BLOCKED even if a local Studio visual preview can be captured.

## Gate A implementation evidence — 2026-11-05

**Technical pilot / visual review candidate, not an accepted finished art pass.**
All 810 M6 tests are preserved unchanged; 31 environment tests bring the total to
841. `check-environment.mjs` also verifies 70 M6 source/test file hashes and the
entire original World after removing only five presentation lines and its optional
flag argument. This protects IDs, callbacks, offsets, transforms, waypoints, spawn,
owner/range checks, phase logic and disabled commerce. CI builds both places from
the exact PR head and uploads source maps, provenance manifest and verification log.

Studio 0.745.462.7451125 loaded and ran the isolated review place. Its server
reported `M7_VISUAL_HARNESS parts=358 plots=8 decorated=1 collisionGuards=PASS`.
No M7 script exception was found in that session's log. Studio automatically
migrated legacy Compatibility lighting to Voxel on opening; these captures are
from that engine mode, not a claim about all renderers. The renderer also logged
`CloudsUpsampleNoHistoryFS is not available`; cloud rendering parity requires a
separate device/renderer check. Unpublished-place platform API warnings do not
constitute successful backend acceptance.

The captured build SHA-256 is
`b8fd4f81cb6896dcf935bfa58d0335bfe90bd3795a32f1b2a5fe23be3b8120e6`.
The filename `M7PilotReview4.rbxlx` in raw screenshots was the fourth local review
iteration; it is byte-identical to the final `M7PilotReview.rbxlx` generated by
the checked-in sources. Manifest source hashes identify the captured implementation.
Screenshots are unedited Studio window captures in `docs/evidence/m7/`; beauty
views disable annotations **only in the isolated harness**. Audit captures restore
them. This is not a Blender mockup, phone test or active gameplay session.

### Measured counts and limits

These are descriptor/runtime **instance counts**, not GPU measurements. Baseline
means additional M7 presentation overhead with the flag off, not total M6 world.

| Metric | Flag-off baseline | Gate A candidate | Ceiling / eight-plot projection |
| --- | ---: | ---: | --- |
| Decorative Parts | 0 | 358 | <=650/pilot; <=2,864 naive eightfold upper bound |
| Built-in Sphere SpecialMeshes | 0 | 288 | <=650/pilot; <=2,304 eightfold upper bound |
| Geometry + mesh instances | 0 | 646 | One art folder additional; full map not built |
| Distinct decor colors / materials | 0 / 0 | 10 / 4 | <=12 colors; shared palette/materials |
| New external mesh/texture IDs / decals | 0 | 0 | 0 until verified admission |
| Local lights full/reduced/minimal | 0 | <=6 / 3 / 0 | Global per-client cap remains 6 for future map |
| Active rain streaks full/reduced/minimal | 0 | <=60 / 24 / 0 | 60 preallocated Parts; no server particles |
| Animated foliage full/reduced/minimal | 0 | 3 / 3 / 0 | <=12; Reduce Motion disables all rain/wind |
| Detail 1 / 2 / 3 Parts | 0 | 149 / 53 / 156 | Reduced hides detail 3, minimal keeps detail 1 |
| Imported texture memory | 0 | 0 | Engine material memory not measured |
| Triangles, total GPU memory, FPS, load time | Unmeasured | Unmeasured | BLOCKED: hardware profiler; no invented figures |

Eightfold counts intentionally overcount the shared Bazaar sample; they are an
upper-bound planning exercise, not a measured or implemented eight-plot valley.
Future external mesh targets: <=2k triangles/tree, <=500/small prop, <20k/mesh;
provisional total visible environment target <=150k triangles, <=32 MiB imported
textures, <=5 s incremental warm load. Those targets require validation and do not
assert the built-in engine sphere tessellation meets a measured triangle budget.

### Requirement → evidence → outstanding gate

| Requirement | Automated evidence | Visual evidence | Remaining gate |
| --- | --- | --- | --- |
| One pilot, clear work area, original eight origins | Gate-A guard, deterministic descriptors; World source contract; Studio noncollision assertions | Historical day overview and spawn | ART REJECTED; revised production art and acceptance required |
| Day/sunset/night/dawn/rain | Named presets, finite bounds, cyclic continuity, synchronized schedule | Same overview in all five states | Subjective palette/night approval; renderer cloud parity |
| Gameplay authority / online-offline / V7 | All 810 M6 tests + unchanged domain/persistence sources | Isolated harness deliberately has no backend | Real saves/PolicyService/receipts/2–8 clients remain BLOCKED |
| Quality and Reduce Motion | Three presets, fixed ceilings, no mutation, local controller | Full quality captures only | Live tier switching, portrait/landscape and 10–15 min real phone test BLOCKED |
| Epochs and M6 aurora | Three epoch surface cases and exact aurora color/material; World contract | No multi-epoch capture in this gate | Three epochs/aurora in full game BLOCKED |
| Bazaar gate and access | Unchanged World + Access hash and M4 cases | Bazaar audit retains QA-closed notice and original TradePost | Human traversal and multiplayer range/collision check BLOCKED |
| UI readability | Nearest-first screen rectangle selection, tie/cap/hidden/offscreen regression; prompts untouched | Corrected spawn/Bazaar and sunset annotation captures | Real phone portrait/landscape and human interaction acceptance BLOCKED |
| External asset provenance | Manifest/license/source audit, null hashes/IDs rejected as admission | Original native fallback clearly labelled | Quaternius download quota + missing game-dev package pipeline BLOCKED |
| Rollback | Default-off flags, no harness in main project | Separate main and review builds | Restart server with false flag; no published map changed |

No full-map rollout, publication, merge, paid purchase or public trading occurred.
Keep Issue #16 open: Quaternius integration, real-phone UI readability and artistic
acceptance are outstanding; Gate B follows only the owner's pilot approval.
