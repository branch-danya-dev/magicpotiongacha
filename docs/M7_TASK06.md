# Task 06 / #19e — fantasy atmosphere

**Implemented in code/build; Studio appearance and device performance unverified.**
The owner requested task 06 without frames, screenshots or video. No new media,
capture helper or Studio session is part of this delivery. PR #17 stays Draft.
The ordinary full-game place is the handoff; this is not artistic APPROVED.

## Result

Six original sky faces now contain turquoise/cream atmospheric bands, five
cloud banks with shaped lobes and three low distant ridge silhouettes. The
project's deterministic Python generator uses mathematical shapes, with no
external imagery, provider, purchased asset or copyrighted game art. The pack
has its own CC0 dedication and hash receipt in `assets/environment/fantasy`.
An independent PNG decoder checks every pixel, all cube edges and polar-face
orientation invariance. This proves texture continuity, not engine appearance.

One immutable sky set is used for the entire session. Existing Clouds and
Atmosphere provide continuous weather overlays. Sun, moon, star, mist and
rainbow sprites keep their existing asset packs. No runtime texture swaps,
extra time source, remotes, gameplay/economy change or save migration.

The pure AtmosphereStyle module enriches the existing EnvironmentState sample;
EnvironmentView remains the single lighting/weather/VFX owner. Day has cooler
ambient shadows, warmer outdoor fill and less haze. Dawn retains peach/mint
tones and ground-local mist; sunset retains the inherited 17.6–18.5 clock curve.
Night receives a deeper blue tint, darker clouds, stars, moon and warm lanterns.
Rain attenuates sunlight/pollen and strengthens the common wind; after-rain
retains wet glints and the existing sunlight-dependent rainbow. No claim of new
sun-position or LightingStyle calibration in Studio is made.

Two restrained downward light pools accent the pilot's vegetation. Their
intensity fades continuously with weather, time and actual solar elevation.
Pollen is distributed over four small terrain-relative pockets; all nine
Reduced mote slots can contribute during daylight. Existing localized fog and
dew pools are reused. Glints use correctly scaled Sphere SpecialMeshes; there
are no new wet materials, global Reflectance changes or blanket Glass swaps.

One deterministic gust drives GlobalWind, grass/crown sway amplitude, pollen
drift and rain slant. Four lobes of a crown receive one common transform, keeping
their silhouette connected. Selection counts every lobe, including fading or
currently hidden detail. Camera turns cannot double the motion budget. Reduce
Motion clears animated pools and restores vegetation transforms. Stop restores
lighting, wind, original forest alpha/positions and wet-stone colors, removes
owned effects and reinstates displaced lighting objects.

## Quality and cost

| Active effect cap | Full | Reduced (default) | Minimal |
| --- | ---: | ---: | ---: |
| Local lights, total | 6 | 3 | 0 |
| Reserved sun accents | 2 | 1 | 0 |
| Remaining lantern lights | 4 | 2 | 0 |
| Foliage parts moving, including whole crowns | 12 | 4 | 0 |
| Separate grass motion pool | 64 | 32 | 0 |
| Pollen/firefly parts | 24 | 9 | 0 |

Sun slots stay reserved at night to avoid abrupt light reassignment; their
brightness reaches zero. Emissive lantern geometry remains. Reduced now enables
directional shadows and small SunRays intensity (.008 maximum); Minimal keeps
both disabled. Bloom stays at its inherited low intensity/2.3 threshold. Core
sky/cloud/time/weather color identity remains at all tiers. These settings
request rendering features; actual availability depends on Roblox/device quality.

The effect pool adds **two invisible local BaseParts and two SpotLights**:
eight local Light instances are allocated instead of six, while the **active
ceiling stays six**. The six glints add Sphere mesh children, not BaseParts.
Rain/mote/fog/glint/star/grass budgets and emitter count remain unchanged. All
effects are pooled at start; no per-frame Instance creation or texture churn.
Distance selection stays 2 Hz and the existing update loop stays at most 30 Hz.

Pilot server art remains **753 parts / 260,965 estimated triangle charges**,
under 850/300,000. Native-geometry charges are planning estimates, not measured
GPU counts. The new six faces replace the old six faces at the same **2 MiB**
RGBA8+mip estimate. The current combined catalog/sky/sprite estimate is
**30.484 MiB**, under the inherited 32 MiB ceiling. Historical sky files remain
in the repository, but the runtime does not load their old six faces.

## Verification and handoff

Run `npm run tools`, then `npm test`, then
`node scripts/build-local-preview.mjs`. The suite retains all 964 inherited cases
and adds 15 task-06 cases (979 total): mood/weather overlays, continuous day and
weather seams, manual transition blending, deterministic bounded gusts, sunlight
gating, pollen locality, Reduced identity, Reduce Motion and grouped allocation
under repeated camera/quality changes. The asset check decodes all six PNGs,
checks 3,056 unique edge directions (3,064 repeated edge matches), exact hashes,
opacity, distinctive sides, orientation invariance and texture memory.

The existing isolated Studio audit additionally checks crown transform/alpha
restoration, total light caps during transitions, owned-light removal and grass
Reduce Motion. Its obsolete fixed part count, numbered path reference and opaque
floor assertions were updated to the current forest/integrated ground. This
audit is **compiled but not executed** here and is absent from the ordinary Play
handoff. Source-protection checks still preserve 70 M6 files and historical art
evidence; the two narrow task-06 state/Reduced seams are documented in the checker.

The handoff is in the parent workspace's `outputs/M7-19e-review` folder. Its
manifest pins the exact committed runtime sources, place SHA-256 and Windows/
Ubuntu CI results. Local Studio needs the existing atmosphere/polish packs plus
the new fantasy pack, installed with `scripts/install-atmosphere-preview.mjs`.
The installer verifies hashes, confines the destination to that Studio version's
content directory and refuses to overwrite differing files. It does not upload
anything or establish published-experience permissions. Another computer or a
Studio version update needs installation again.

## Remaining limits

- New sky readability at night, cloud layering, in-engine cube seams, low-quality
  stippling, shadow softness, sun-pool placement, motion appearance and frame time
  remain unverified in Studio. Code checks cannot establish artistic acceptance.
- Physical smartphones, experience asset permissions and multiplayer load remain
  **BLOCKED**. Enabling Reduced shadows particularly requires device measurement.
- Gameplay prop proxies remain task 07. Remaining-farm dressing is task 08 and
  still requires explicit final pilot **APPROVED** after task 07.
- No purchases, trade activation, merge or game publication.
