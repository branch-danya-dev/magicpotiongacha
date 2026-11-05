# M7.1 A.2b — Fantasy Atmosphere Director

**ART PENDING. Draft only.** Runtime source: `39788eafaf93de4c21f7817f0aff4cb4e38ffd35`.
This extends A.2 on PR #17. It does not approve the art gate or unlock issues #18/#19.

## Implementation

`EnvironmentState` remains the pure deterministic sampler. Time follows continuous
day, sunset, dusk, night, predawn and dawn keys. Independent weather envelopes
describe clear, cloud buildup, rain, clearing and after-rain; the view consumes
continuous cloud/rain/wet/afterRain channels instead of switching scripts.
The normal time cycle is 1500 seconds and weather is 2100 seconds. The isolated
review harness compresses a complete cycle into 45 seconds with a continuous wrap.

`EnvironmentView` is the only lighting/VFX owner. It rejects a second start,
suspends existing sky, atmosphere, clouds, color correction/grading, bloom and
sun rays, and restores the original instances and Lighting/GlobalWind values on
stop. A single immutable sky asset set is assigned at start. No runtime texture
replacement, remotes, profile fields, production accounting or economy changes.

The six 256px sky faces, sun, crescent moon, mist and rainbow sprites are original
mathematical project art with a CC0 dedication. The generator and every delivered
asset have SHA-256 receipts. There are no Nintendo/Zelda or marketplace sources.
The decoded PNG edge test covers 3056 unique shared rays and 3064 duplicated edge
samples; polar faces also pass independent quarter-turn/reflection invariance.
An early version passed the mathematical seam test but showed a polar seam in
Studio. The delivered quiet wisps are invariant under the engine's polar face
orientation; the previously visible cut is absent in the recorded v4 sky view.

Dynamic variations use Clouds and Atmosphere. Local ground mist is three shallow
billboards positioned over raycast ground at the pilot perimeter, not an
Atmosphere.Offset trick. Six tiny dew/bioluminescent props and one directional
after-rain arc are pooled. Rain reuses its existing pool for nearby drops and
brief ground splashes. Wind fades within its cap, including camera changes.
Existing trees/ridge provide silhouettes; no new island or navigation obstacles.

## Quality and budgets

| Tier | Lights | Rain | Motes | Wind meshes | Mist | Glints | Arc |
|---|---:|---:|---:|---:|---:|---:|---:|
| Full | 6 | 60 | 24 | 12 | 3 | 6 | 1 |
| Reduced | 3 | 24 | 9 | 4 | 2 | 3 | 1 |
| Minimal | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

Core sky, color, clouds and weather haze remain in every tier. Reduce Motion
disables rain, mote and plant animation. No particle emitters were added.
The explicit increase is ten pooled noncolliding Parts for local atmospheric
props and 2.417 MiB RGBA8+mips for the authored textures. Combined texture storage
stays below the inherited 32 MiB ceiling; 650 art parts / 150000 triangles and
existing light/rain/mote/wind ceilings are unchanged. This is a budget audit,
not a measured mobile performance claim.

## Studio calibration and reproduction

Studio version tested: **0.746.0.7461264**, Windows desktop. Soft and Realistic
were compared at the same cameras and manual graphics 5. Their difference is
small at that setting. Realistic is the candidate, with quality priority enabled;
Full at graphics 10 was also inspected during the comparison iteration.
Rojo 7.7.1 needs an explicit legacy Technology value (ShadowMap / Future) so
Studio migration does not silently replace the intended modern LightingStyle.
Runtime writes to LightingStyle require plugin capability, so the comparison
uses separate static builds, never a competing lighting script.

Sunset is 17.65; the measured sun direction is approximately
`(-0.994856, 0.091415, 0.043652)` (5.245 degrees above the horizon). The direct-sun
diagnostic shows warmer light than the inherited north-facing review cameras.
Exposure preserves readable factory colors. Bloom threshold is 2.3; there is
no global Reflectance increase, Grass-to-Glass conversion or RoughnessMap scalar.

Build with `node scripts/build-atmosphere-comparison.mjs` and
`node scripts/build-local-preview.mjs`. Install the checked atmosphere files with
`node scripts/install-atmosphere-preview.mjs <existing Studio version directory>`;
the installer verifies both sides and refuses conflicting existing bytes.
Quaternius pilot assets must also be installed as documented in A.1.

The review builds use keys 1–6 for day/sunset/night/rain/dawn/after-rain, V for
fixed cameras, T for the 45-second cycle, Q for quality, R for Reduce Motion,
P for audit values, U for existing labels and H for the review caption.
`M7A2b-NightAudit.rbxlx` differs only in the initial QA pose/camera (night/sky);
all runtime modules are identical. The full-game local preview has the normal
server/UI, starts Reduced, uses memory saves in Studio and keeps commerce/trading
off. Its camera/pose shortcuts exist only in the disposable local preview.

The final runtime was actually played with the normal server and UI at default
Reduced (day/night/rain), then Full (rain), all at manual graphics 5. Original
atmosphere assets reported zero preload failures. HUD text retained contrast;
existing overlapping world labels remain a UI defect, deferred to issue #18.
Studio also logged unrelated local-universe chat/asset HTTP errors and a cloud
shader fallback warning; this is not an error-free engine certification.

The exact previously captured A.2 place (SHA-256 `29508ba916d6168434a6dce06eb50b5ccdcb7dcfc89d665d4b1bf0b04448a805`)
was reopened in the same Studio version. Its day/night spawn views reproduce
the noisy ground and pale fern/path edges. These defects predate A.2b; their
continued presence is not a visual acceptance pass.

The native Studio recording is supplied as a continuous 45.00-second excerpt
from the second preview loop, with no retiming, recoloring or compositing.
Frame sampling and a low-resolution adjacent-frame luminance audit found no
large full-frame flash/cut (maximum mean delta 2.208/255). This bounded check
does not certify absence of fine foliage shimmer or all temporal defects.

## Acceptance limits and unresolved defects

- **ART PENDING:** owner review is required for the mood and effect strength.
- **Night sky defect:** stars are configured and original moon art is supplied,
  but stars/moon are not yet convincingly visible in the inspected north/up
  camera. Lower night haze did not resolve this. Do not count this visual target
  as accepted.
- **Low-quality defect:** pale fern edges and noisy/triangulated path surfaces
  remain visible at manual graphics 5. Absence of a new regression is not the
  same as resolution; this needs a separate visual correction before acceptance.
- Legacy yellow purchase pads remain dominant even without excessive bloom.
- Local dawn mist, dew and wet glints are subtle at the standard cameras and
  need art review. The rainbow is intentionally conditional, not a permanent
  decoration. Long soft shadows depend on engine quality.
- **Experience asset permissions BLOCKED:** local files preload successfully,
  but no Roblox asset upload or experience permission validation was performed.
  These `rbxasset://` paths are Studio-local and are not deployable content IDs.
- **Real-device performance BLOCKED:** no physical phone was tested.
- Publishing, merging, purchases and public trading remain disabled/out of scope.

Actual captures, build hashes and Studio audit excerpts are in
[`evidence/m7-a2b`](evidence/m7-a2b/README.md). CLI/CI success does not approve
the visual gate or the unperformed experience/mobile checks.

References used for engine behavior: [Sky](https://create.roblox.com/docs/reference/engine/classes/Sky),
[Atmosphere](https://create.roblox.com/docs/environment/atmosphere),
[Roblox Staff skybox orientation guide](https://devforum.roblox.com/t/custom-skyboxes-101/2849003).
