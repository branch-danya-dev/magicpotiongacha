# Task 04 / #19c — pilot meadow

**Workflow amendment:** the owner subsequently removed frames, screenshots and
video for ongoing work and authorized task 05. The capture checklist below is
historical; media is no longer required to continue. Studio checks remain
unperformed, and no art approval is inferred.

**CODE / BUILD PREPARED; STUDIO VERIFICATION AND ART REVIEW PENDING.**
The owner deferred Studio use on 2026-11-05 and requested code/build work only.
There are no new task-04 screenshots, recordings or live acceptance results.
Historical task-03 captures do not prove this change. PR #17 remains Draft.

## Implementation

The pilot receives 456 planted models from the existing reviewed Quaternius
catalog: 374 short grass clusters, 16 tall grass clusters, 44 clover patches and
22 wildflower groups. Two ferns and one small flowering bush retain occasional
decorative accents. Grass varies in height (approximately 0.69–1.30 studs), tint,
orientation and distribution. No new external assets, textures or materials.

The deterministic planting plan reserves current and future station footprints,
purchase pads, worker approaches, spawn, the main paths and the entrance fence.
All new vegetation is anchored, noncolliding, nontouching and excluded from
interaction raycasts. Original gameplay coordinates, anchors, economics,
persistence and remotes are unchanged. The existing ground remains underneath
the volumetric plants; open work zones deliberately retain bare ground.

The existing EnvironmentView remains the single environment owner. Its current
weather wind strength drives continuous travelling gusts. Grass pivots at its
ground contact. Nearest visible clusters within 65 studs receive motion slots;
camera changes crossfade their weights. Clover and flowers remain static.
Quality/distance visibility fades over about half a second. Stop restores every
animated base transform; Reduce Motion and Minimal allocate no grass motion.

## Budgets

| Quantity | Full | Reduced (default) | Minimal |
| --- | ---: | ---: | ---: |
| Eligible planted models before distance culling | 456 | 401 | 273 |
| New grass motion slots, including fading-out slots | 64 | 32 | 0 |
| Inherited tree/fern motion ceiling | 12 | 4 | 0 |
| Combined moving-mesh ceiling | 76 | 36 | 0 |
| Vegetation draw distance, studs | 240 | 145 | 95 |

The motion increase is explicit: the former 12/4/0 ceiling still applies to the
inherited controller pool; task 04 adds a separate bounded 64/32/0 grass pool in
the same owner/update loop. Updating transforms remains at most 30 Hz; selecting
nearby visible clusters remains at most 2 Hz. No added render connection,
per-frame allocation of Instances, particles, lights or runtime texture changes.

The planned pilot art totals **593 parts / 134,153 triangles**, below inherited
650 / 150,000 limits. Catalog texture memory stays 27.96 MiB / 12 external
textures. These counts exclude existing gameplay and other environment systems,
as in the inherited art budget. They are not measured device performance.

## Verification and reproduction

949 tests: 939 inherited cases retained plus 10 new task-04 cases. The inherited
plant-placement test now checks meadow clearance inside the farm instead of
forbidding all interior vegetation; its closed-catalog check remains. New tests
cover deterministic geometry budgets, full future-station/pad clearance, open
walking/spawn lanes, variation, quality coverage, continuous weather-dependent
wind, hard motion caps during camera turns, quality downgrade and restart fades.
Compile and portable analysis cover 119 Luau sources.

Run `npm run tools`, then `npm test`. Build ordinary full-game Play with
`node scripts/build-local-preview.mjs`. It includes no camera/diagnostic helper;
only the existing Studio-only art substitution is applied, and progress stays in
memory. Existing local atmosphere textures are required on a different computer.

For the separate capture build use `node scripts/build-local-preview.mjs --meadow`.
F8 selects spawn; F6 cycles spawn/farm/near-meadow cameras; Q toggles Reduced/Full;
P logs camera, graphics level and counters. R runs the isolated Full/Reduced/
Minimal, Reduce Motion, actual transform-change, duplicate-owner and restoration
audit. C returns to the ordinary gameplay camera. The helper fixes daytime and
never grants currency, purchases or writes profiles. It has been compiled but
has **not yet run in Studio**.

The local handoff folder `outputs/M7-19c-review` contains ordinary and QA places,
the matching task-03 baseline with the same new camera helper, and a manifest
with exact runtime commit, file hashes and serialized-script comparisons.

## Remaining work / limitations

- Live checks are deferred: ordinary one-Play start, actual grass volume/wind,
  ground contact on slopes, soft culling, graphics-5 aliasing, Full/Reduced/
  Minimal and Reduce Motion/owner restoration in the engine.
- Capture matched before/after spawn, farm and near-meadow views at manual
  graphics 5 and 10, with default Reduced and full gameplay HUD. Record real
  Play video at both levels showing clear grass volume and movement. Capture
  supplemental Full/Minimal and an ordinary delivery launch without the helper.
- Numeric coverage is not proof of a lush appearance. Height, density, tint and
  wind may need adjustment after the first actual Studio inspection.
- The existing sparse trees, colored station proxies, mixed-language UI,
  distant water edge and thin-boundary aliasing remain. Tasks 05–08 are untouched.
- Physical smartphones, experience asset permissions and multiplayer load remain
  **BLOCKED**. No purchase, trade activation, merge or publishing is authorized.

The original capture requirement below was superseded by the owner amendment
above. Code/build delivery is complete; actual appearance remains unverified.
