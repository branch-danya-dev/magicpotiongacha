# R4B Moon Atmosphere Refinement

**CODE CANDIDATE / STUDIO VERIFIED (bounded QA) / OWNER ART PENDING / NOT INTEGRATED.**

Follow-up in Draft PR #59, branch `feat/ag76b-r4b-moon-cycle`.
Starting HEAD: `463cf0ddc2562239c589bcececeba9b0b93c4ada` (clean tree,
Windows/Ubuntu green). PR base remains R4A `56666c072e66f7357ec2f054f818a642cae0abd9`.
Runtime source: `5e226a84f2ad2347c57d5d58d0e6321a73990426`.
This report supersedes the original R4B report's probabilities, halo and camera
settings; its earlier measurements remain historical evidence.

## Candidate and comparison

**+50% is the main candidate**; +35% and the original scale remain available.
The three approved crater layouts and colors are retained. Conservative edits
reduce fine surface contrast, widen the antialiased alpha boundary and preserve
large craters. A local 64x64 Gaussian-like halo falls monotonically outward,
with no annular peak. No global Bloom or other global lighting value was raised
for this refinement. Artistic acceptance remains the owner's decision.

The native night comparison uses relative camera position `(-43,8,14)`, target
`(0,27,-8)`, FOV 78, clock 20.5, viewport 1566x1095, Studio toolbar Q6.
All variants use this same framing, including the original texture/size.
The camera looks slightly higher than the original R4B review camera so the
larger disk fits. This is a QA camera adjustment, not a change of moon direction.
The moon still follows `Lighting:GetMoonDirection()`; a freely aimed camera can
naturally move it out of frame. It is not clamped to the screen.

| Native Play capture | Purpose |
|---|---|
| [01 — original, 100%](evidence/ag76r4b-refinement/01-before-pearl-100.png) | Original texture, halo and size |
| [02 — softened, 100%](evidence/ag76r4b-refinement/02-soft-pearl-100.png) | Isolate softness from size |
| [03 — softened, 135%](evidence/ag76r4b-refinement/03-soft-pearl-135.png) | Smaller candidate |
| [04 — softened, 150%](evidence/ag76r4b-refinement/04-soft-pearl-150.png) | Main candidate, Pearl |
| [05 — Blood, 150%](evidence/ag76r4b-refinement/05-soft-blood-150.png) | Same camera and time |
| [06 — Frost, 150%](evidence/ag76r4b-refinement/06-soft-frost-150.png) | Same camera and time |
| [07 — Reduced](evidence/ag76r4b-refinement/07-soft-pearl-reduced.png) | Weaker local halo |
| [08 — Minimal](evidence/ag76r4b-refinement/08-soft-pearl-minimal.png) | Small halo contribution, legible disk |
| [09 — Reduce Motion](evidence/ag76r4b-refinement/09-soft-pearl-reduce-motion.png) | Full, zero wind/moving meadow |
| [10 — lower, brighter sky](evidence/ag76r4b-refinement/10-soft-pearl-lower-sky.png) | Clock override 19.2, same camera |
| [11 — dawn](evidence/ag76r4b-refinement/11-dawn-moon-hidden.png) | Clock 6.1, mirrored dawn camera, hidden disk |

These are unmodified PNGs from Roblox Studio's screenshot command in ordinary
F5 Play. Native filenames and byte hashes are recorded in `captures.json`.
Screenshot pixels were not generated, retouched, composited or resized.
The isolated QA scene is not a production gameplay/backend acceptance.

## Selection and continuity

Exact roll buckets: **6000 Pearl / 2000 Blood / 2000 Frost out of 10000**.
The existing deterministic integer hash uses the night key
`floor((GetServerTimeNow() - 300) / 1500)`. A view caches one automatic choice
per key. The key changes at dusk and spans night, dawn and the following
invisible daytime. Rejoining computes the same choice instead of drawing a
new random result. Consecutive keys may select the same state; no forced
rotation is used. Manual QA overrides do not reroll the automatic choice.

This is deterministic pseudorandom presentation, not cryptographic randomness
or rewards. Bucket proportions are exact; finite sequences are not guaranteed
to contain exactly 60/20/20 percent. Tests cover every roll, dusk boundaries,
rejoin determinism, no mid-night reroll, manual overrides and repeated nights.
Native multi-client synchronization has not been tested.

The **1500-second cycle remains 300/375/675/150 seconds**. The inherited
eight-second interpolation, weather and single EnvironmentView Lighting/wind
owner remain in use. No new clock, remotes, persistence, reward or mechanic.

## Assets and cost

Original assets and manifest under `assets/environment/lunar/` are unchanged.
The refinement subdirectory records original, edited-source and reduced PNG
hashes, prompts, provenance and deterministic 512x512 area reduction. No new
concept or third-party franchise imagery. No Roblox uploads or new permissions.

Checks measure crater-layout grayscale correlation of 0.982/0.972/0.982 and
adjacent-pixel detail ratios of 0.555/0.581/0.565 for Pearl/Blood/Frost in the
central radius-150 region. These pixel metrics guard against accidental
layout drift or excessive blur; they do not establish artistic approval.

Still **4 EditableImages / 4 labels / 3,162,112 RGBA bytes**, zero extra lights
and zero extra render connections. Halo extent is 1.75 disk canvases; maximum
strength is Full 0.24 / Reduced 0.13 / Minimal 0.045, multiplied by disk visibility.
No per-frame pixel writes, texture decoding or image allocation. Explicit Studio
Before/After commands rewrite the existing four images; repeated selection of
the current style is a no-op. The comparison adds three original RGBA sources
to the QA module (about 4 MiB encoded constants), not three additional images.
This comparison-only memory is not a production asset solution.

## Reproduce

Run `npm run tools`, `npm test`, then `node scripts/build-lunar-island.mjs`.
Open `build/WizardIsland-AG76B-R4B-Moons-ART-PENDING.rbxlx`, press F5.
Receipt: `build/lunar-island-build.json`.

Keys: `J` +35%, `K` +50%, `L` original size; `V` original texture/halo,
`B` softened texture/halo; `Z/X/C` Pearl/Blood/Frost, `0` automatic;
`9` comparison camera, `5/6/7` day/dusk/night, `T` dawn;
`Q` quality, `R` Reduce Motion, `H` footer, `4` ordinary character control.
Wait eight seconds after changing time or moon for the inherited transition.
Default is softened +50%; automatic selection may show any of the three moons.

## Verification

Runtime CI Windows/Ubuntu passed in run `43987665647` at `5e226a8`.
Local `npm run tools` and `npm test`: **PASS, 1390 Luau + 19 Node tests**,
287 compiled Luau sources, portable analysis and Rojo builds. This includes
18 lunar semantic tests and 5 lunar asset/ownership tests (four and two added
by this refinement). Two inherited analyzer warnings remain: LocalShadow in
`c01_economy_v2.spec.luau:232` and LocalUnused in `c01_first_session.spec.luau:411`.
No new analyzer warning. Exact final documentation HEAD and its CI are recorded
in PR #59; runtime and artifact hashes above pin the tested visual implementation.
Native checks are in [native-checks.json](evidence/ag76r4b-refinement/native-checks.json):

- +35%/+50% full billboard bounds are inside the comparison viewport, with
  respective top margins 104.44/82.70 pixels (visible disk has additional padding).
  Direction dot product against `Lighting:GetMoonDirection()` is 1.0.
- Twenty quality/moon/style/motion switches: weather descendants before/peak/after
  **279/279/279**, four images/four labels; duplicate owner rejected. Steady-frame
  pixel-write count stays unchanged. No partial image-resource growth observed.
- Reduce Motion: GlobalWind `(0,0,0)`, zero moving meadow entries, readable moon.
- The inherited compressed 45-second preview ran for 53.03 seconds / 1005 samples:
  lunar alpha 0–0.95, rain 0–60, maximum Ambient channel step 0.02361 per
  approximately 0.05-second sample. Sampled diagnostics are not a guarantee about
  every rendered frame. A full natural 25-minute cycle was not observed.
- Stop restoration: all 12 Lighting properties, wind, original Lighting/Terrain
  child identities and removal of the weather folder passed. Fresh F5 Play was
  then started in the same existing Studio window for owner review.
- Native asset preload completed with no failed IDs.

Verified artifact SHA-256:
`c3b62762708b93d4842ca0d0fa68b825950105293227ecf553ab771aece2222d`.

## Preliminary desktop timing

Same Play session, comparison camera, clock 20.5, Pearl, motion enabled.
Each sample is 12 seconds of RenderStepped intervals after settling. No CLI
tests/builds ran during sampling. These are frame intervals, not GPU timestamps.

| Quality | Before FPS | After FPS | Before p95 ms | After p95 ms |
|---|---:|---:|---:|---:|
| Full, repeated pair | 235.66 | 228.54 | 5.41 | 5.75 |
| Reduced | 60.01 | 60.01 | 17.76 | 17.53 |
| Minimal | 60.01 | 60.01 | 17.62 | 17.56 |

The first Full pair was 213.87 vs 59.24 FPS and is **not comparable**: frame
cadence changed to approximately 60 FPS during that run. It is retained in
the raw record, not silently discarded. The repeated Full pair used a longer
10-second settling period; its roughly 3% FPS difference is preliminary.
Reduced/Minimal results have approximately 60-FPS pacing, limiting sensitivity.
No claim of GPU headroom, controlled benchmark acceptance or phone performance.
Total Studio memory was about 2961 MiB in the repeated pair; this long-lived
process retains earlier assets, so this is not the moon's memory allocation.
The fixed image budget and stable pixel-write counters are checked separately.

## Remaining gates

- Owner moon/halo art approval is pending. Softness and scale remain candidates.
- Real phones/tablets, physical low-memory allocation failure and multi-client
  consistency are NOT TESTED. Deterministic unit tests are not live multiplayer proof.
- This is Studio-only EditableImage delivery. Production asset admission,
  Roblox asset permissions and integration require a separate approved task.
- No production economy, stations, routes, geometry, V8, saves, GlobalWind policy
  or gameplay code changed. No merge or Roblox publication.
