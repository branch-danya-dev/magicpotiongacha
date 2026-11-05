# M7.1 Gate A.2 — lighting and weather

[Issue #20](https://github.com/branch-danya-dev/magicpotiongacha/issues/20),
Draft PR #17, one decorated pilot only. **ART PENDING; low-quality stippling OPEN.**
This is a review candidate, not completion of the visual gate. #18 UI, #19 island,
station models and music remain outside this patch. No merge or publication.

## Runtime

EnvironmentState interpolates every lighting field with smoothstep, including the
midnight/cycle seam. Rain ramps both in and out over 90 seconds. The normal cycle
uses server time; the Studio-only 45-second preview uses an elapsed local clock.
Presets expose day, golden-hour sunset, blue night, pastel dawn and overcast rain.
The final overview sunset has warmer directional highlights and longer shadows,
but its horizon remains muted rather than strongly pink/amber; art review is open.
One EnvironmentView owns Lighting, Sky, Atmosphere, Clouds, ColorCorrection, Bloom
and SunRays. It suspends prior effects, rejects duplicate ownership and restores
the prior effects/properties on idempotent stop. There are no economic calls.

Bloom stays below 0.05 with threshold 2.3. Local warm lamps brighten continuously
as night arrives. Sparse pollen/fireflies stay around the planted perimeter;
their opacity changes slowly, without flashes. Wind rotates a bounded set of
nearest leaf/grass meshes by at most 0.009 radians around their bases. No camera
shake, audio layer or crystal sparkle was added. The imported package is unchanged.

| Client preset | Lights | Rain drops | Motes | Wind meshes | Shadows / post effects |
| --- | ---: | ---: | ---: | ---: | --- |
| Full | 6 | 60 | 24 | 12 | Shadows, subtle Bloom/SunRays |
| Reduced (game default) | 3 | 24 | 9 | 4 | No shadows/rays; reduced Bloom/haze |
| Minimal | 0 | 0 | 0 | 0 | No shadows/Bloom/rays; reduced haze |
| Any + Reduce Motion | tier cap | 0 | 0 | 0 | Static light/weather still follows time |

These are **per-client total caps**, not per farm. Rain/motes are pooled anchored,
noncolliding Parts; ParticleEmitter count is zero. Hidden pooled objects still
exist (84 Parts), so active counts are not instance or draw-call counts. Motion
and lighting update at up to 30 Hz, culling/nearest selection twice a second.
Roblox graphics quality and these application presets are independent settings.

Future eight-farm planning: retain these global effect caps and a single sky/weather
owner. Blindly copying the current pilot would imply about 3,456 decor Parts and
933,008 authored triangles, before Terrain, players or machines. This is a warning
estimate, not an implemented eight-farm scene or measured visible budget. #19
requires streaming/LOD and actual device profiling before a useful target is set.

## Low-quality investigation

Baseline is A.1 commit f343966580e91b20db4f1516741bae1d0e8ee291.
Same overview camera is compared at Automatic and Manual 5, day and night.
Automatic can change its internal level over time; comparisons are observations,
not deterministic GPU benchmarks. Original JPEGs and settings proofs are retained.

| Controlled intervention | Observed result / decision |
| --- | --- |
| Slate path material → SmoothPlastic | Fine surface grain reduced; retained in source |
| Shadow-disabled configuration diagnostic | Did not establish a complete fix; command-context config mutation is not proof that the running controller consumed it |
| Raise paths by 2 studs | Distant marks remain; ground coplanarity alone does not explain them |
| Disable DoubleSided | Visible missing stone triangles; rejected |
| Increase stone thickness ×4 | More craggy side faces, no convincing complete fix; rejected |
| Remove tree leaf SurfaceAppearance | Opaque cards retain light/dark triangular patterns; alpha sampling is not the sole explanation; rejected |
| Mesh fidelity inspection | Reviewed templates already use Precise; forcing quality 10 is not a fix |

Near paths are quieter, night is substantially more readable. Thin distant stone
faces and leaf cards can still show marks at Automatic/low quality. **Root cause
is not fully isolated and the stippling acceptance item remains OPEN.** Do not
report the material change as universal repair. Next useful step is controlled
mesh-card topology/normals inspection with an actual low-end device capture;
no unreviewed replacement geometry is admitted here.

## Evidence and reproducible motion preview

[Raw Studio evidence and capture manifest](evidence/m7-a2/README.md) include
source/build/image hashes. The isolated harness is for rendering only. The
separate full-game preview retains the actual HUD and contextual labels.

Build: `node scripts/setup-tools.mjs`, `node scripts/check.mjs`.
Open `build/M7PilotReview.rbxlx`, press Play, then **T** for a repeating 45-second
cycle including sunset, night, dawn, rain and clearing. **1–5** select still
presets; **V** switches named cameras; **Q** cycles effect presets; **R** toggles
Reduce Motion; **P** prints active effect counts. **H/U** toggle review label and
annotations. No backend is present in this disposable harness.

For the full game: `node scripts/build-local-preview.mjs`. Open the generated
place and Play. **Z/X** set the review camera with day/night while keeping the
real UI; **C** restores normal camera and server-time weather. These keys exist
only in the disposable Studio preview, never the release project. Do not publish
either preview. Production art, monetization and trading flags remain false.

The reproducible preview is the motion deliverable allowed by Issue #20. A recorded
video is **BLOCKED / not supplied**: the available native automation captures
stills only and no video recorder was available in the inspected toolchain.
The still gallery must not be presented as proof of smooth animation.

## Validation boundary

All 844 inherited tests are retained; seven additional environment cases cover
continuous fields, seams, weather ramps, preview timing, tier/Reduce Motion caps
and deterministic bounded motes. Required total: **851**. The real Studio harness
also asserts singleton ownership, all effect caps, Reduce Motion, repeated stop
and restoration of prior lighting. Earlier runtime permission/timing failures
were corrected before the final build. Source integrity protects 70 M6 files,
gameplay World seams, release flags and the unchanged imported asset receipt.

Actual phone FPS/thermals, 2–8 players, published asset permissions, real DataStore,
PolicyService, purchases and trade/Rebirth backend acceptance remain **BLOCKED**.
No static counts or desktop screenshots pass those gates. Owner visual approval
and low-quality repair are still required before moving on to #18.
