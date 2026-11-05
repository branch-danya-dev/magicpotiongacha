# M7.1 / revised one-farm Gate A

Current patch: [Gate A.2 lighting/weather](M7_A2_ATMOSPHERE.md), Issue #20.
851 portable tests; new [raw evidence](evidence/m7-a2/README.md) includes Automatic
and Manual 5 comparisons. ART PENDING; stippling remains OPEN. The A.1 record
below is historical where it describes static foliage or 844 tests.

The primitive pilot was ART REJECTED. This revision replaces its nature with
14 inspected/optimized Quaternius MegaKit Standard models and bounded native
Terrain. The owner authorized direct preparation/import despite missing game-dev.
[Direction](M7_ART_DIRECTION.md), [asset provenance](../assets/environment/README.md),
[current raw Studio evidence](evidence/m7-revision/README.md).

Branch feat/m7-environment-artpass, Draft PR #17 over M6 bbc8891. Gate A remains
pending owner visual acceptance. #18 gameplay UI follows; #19 eight-farm island
requires explicit ART APPROVED and UX check. No merge, publication, purchases,
M7.2/M7.3 or decoration of the other seven plots.

## Gameplay boundary

All 70 protected M6 source/test hashes and the complete original World after
removing only explicit presentation seams are checked. Eight plot origins, floor
transforms, 13 stations, pads, prompts, ranges, ownership, transport waypoints,
spawn and Bazaar/TradePost remain intact. V7 economy/persistence is unchanged.
EnvironmentArtEnabled, MonetizationEnabled and TradingEnabled ship false.

Imported templates live inertly in ServerStorage. A separate decoration folder
contains anchored, noncolliding, nontouchable/nonqueryable geometry with no prompts
or economy attributes. Native Terrain fills only empty cells in the bounded pilot
region; it never clears existing Terrain. The original work floor stays in place.
Terrain collision does exist outside the floor. Studio raycasts assert that its
smoothed surface stays below the work floor; planting is grounded by raycasts
after a simulation step. Turning the feature off on a new server restores the
original world. Runtime deletion of Terrain is not used as rollback.

## Presentation

One client controller owns the deterministic day/night and weather cycle using
server time. Quality presets cap details, lights and fixed-count local rain.
Nested mesh descendants participate in LOD. No economic remotes/profile writes.
The existing contextual labels are unchanged; beauty captures suppress annotations
only in the isolated harness. They do not demonstrate the #18 UX gate.

| Metric | Authored limit/count | Evidence limitation |
| --- | ---: | --- |
| Decor mesh/box Parts | 432 / <=650 | Runtime assertion, one decorated plot |
| Geometry estimate | 116,626 triangles | Excludes Terrain, avatars, machines and GPU LOD |
| Trees / small props | <=2000 / <=500 triangles | Prepared glTF index counts checked |
| Imported texture set | 12 maps / 27.96 MiB | RGBA8+mips estimate, not GPU memory |
| Local lights full/reduced/minimal | <=6 / 3 / 0 | No mobile performance claim |
| Local rain full/reduced/minimal | <=60 / 24 / 0 | Reduce Motion disables rain |
| Animated imported foliage | 0 | Static silhouettes; wind not added |
| Total triangles/draw calls/FPS/load time | Unmeasured | Real device profiler required |

## Validation and review

The 841 existing portable tests are preserved, with the obsolete zero-texture
expectation updated for imported assets; 3 new terrain/catalog boundary cases
bring the total to 844. Compile/portable analysis, integrity and both Rojo builds
are required. Integrity checks the imported-file receipt, inert XML class
allowlist, actual mesh counts, historical captures and current capture sources.

Run `npm run tools` then `npm test` (equivalent node scripts work without npm).
Open build/M7PilotReview.rbxlx in Studio and Play for the isolated art harness:
1 day, 2 sunset, 3 night, 4 rain, 5 dawn; V cameras; U annotations; H label.
The harness has no DataStore, purchase or trade runtime. Full-game local preview:
`node scripts/build-local-preview.mjs`, then open the generated
build/PotionTycoon-M7-LocalPreview.rbxlx. Art is enabled only in Studio, progress
uses memory, commerce remains off. Never publish that disposable artifact.

Studio 0.745.462.7451125 / Future lighting is the observed renderer. Final local
harness reports 432 parts, 8 plots, 1 decorated, collisionGuards=PASS. Earlier
iteration errors (terrain readiness and runtime RenderFidelity permission) were
corrected before captures. Platform warnings from unpublished-place/avatar APIs
are not backend acceptance. Published asset permissions still require verification.

Outstanding: owner visual decision; #18 normal gameplay UI/PC+mobile flow; real
phone 10–15 minute profiling; second-account asset loading; 2–8 players; real
DataStore/PolicyService/receipts and full epoch/aurora checks. Keep Issue #16 open.

During automatic-quality startup, thin stone faces and foliage showed dark
stippling; it disappeared at fixed Roblox graphics quality 10. The final beauty
series therefore pins quality 10 (settings screenshot included). This is an open
low-quality renderer check, not a proven universal fix. Stone placements now
exclude the actual purchase-pad footprints; the Studio harness verifies rotated
mesh bounds against every pilot pad. Reduced/minimal presets disable shadows,
but require their own device review before mobile acceptance.
