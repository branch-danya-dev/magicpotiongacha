# M7.1 A.2c — atmosphere polish

**ART PENDING / Gate A.** A.2b was accepted as a direction, not as final art.
This patch stops at one pilot and its existing surroundings. The owner must
explicitly approve the actual result before #18. #19 follows the later UI gate.

## Result and scope

The native moon sat near the zenith at the night review time, outside the normal
spawn view. EnvironmentView now owns a low, world-oriented celestial rig: one
moon and a bounded star pool, using the existing original CC0 moon and a new
original CC0 star sprite. Translation follows the camera; rotation does not.
Night/cloud channels fade them continuously. Native moon/stars are suppressed,
so there is no second sky owner or duplicated moon. Day, sunset and night
lighting keys are unchanged from A.2b; night was not globally brightened.

Dawn uses peach/pink light and mint shadows, with the existing three mist sprites
repositioned low around the pilot perimeter. Their footprint is broader and
their opacity stronger. Dew remains six small pooled ellipsoids. Bloom thresholds
and tier intensities are unchanged. After rain, path stones darken mildly and
recover their exact original colors; local wet glints persist through clearing.
The inherited conditional rainbow and local drops remain. No reflective grass,
global Reflectance increase, scalar RoughnessMap, or texture changes per frame.

The ground fix replaces native Grass shading on ForestFloor and the pilot floor
with opaque SmoothPlastic and one immutable low-frequency top texture. Original
physical properties are saved before the material change; geometry, collisions,
epoch colors and the Aurora Neon appearance retain their contracts. The new
texture has exactly matching opposite edges and no alpha. A stable fern tint
reduces the contrast of pale atlas edges without modifying reviewed geometry.

No gameplay, production, economy, remotes or persistence changes. The existing
EnvironmentState/EnvironmentView pair remains the only state/render owner.
Release art, commerce and trading flags remain off.

## Diagnosis and unresolved defects

| Area | Evidence / action | Remaining limit |
| --- | --- | --- |
| Moon | Native direction at 22.5 was about 67 degrees above the horizon. Removing Atmosphere/Clouds in a disposable probe did not make it appear in that view. Low celestial rig is visible in final graphics 5/10 captures and Reduced Play. | Art-directed rather than astronomical path; judge size/style at Gate A. |
| Flat ground stippling | Same-camera Grass → SmoothPlastic probe removed the strong noise without moving geometry or lights. Final paired graphics 5 captures confirm the quieter floor. Floor tops are one stud apart; no coincident base-floor planes. | Probe was at manual 10, final comparisons at both 5 and 10. Native Grass on the distant Terrain hill still has grain. |
| Foliage | Original fern atlas has pale edge pixels; alpha cards and thin grass edges remain. Tint reduces contrast. | Fine alpha-edge aliasing/sparkle remains, especially at 5. No claim that a tint repairs the atlas or engine antialiasing. |
| Paths and shadows | Existing thin paths use Precise geometry, opaque SmoothPlastic, no SurfaceAppearance and CastShadow=false. Reduced disables global shadows. | Thin irregular path edges remain; not every possible mesh overlap is ruled out. |
| UI | Full game was opened with untouched billboards, pads and HUD. | Labels overlap and bright yellow pads dominate. #18 is intentionally gated. |

An initial local PBR MaterialVariant experiment failed Studio's TexturePack
loader even when generic preload reported success. It was removed before the
captured runtime commit. The final two new textures load successfully in Studio;
no MaterialVariant dependency remains. This is why preload success alone is not
used as visual acceptance.

## Budgets, assets and accessibility

All previous limits remain: 650 decorative parts, 150k authored triangles,
32 MiB decoded textures with mips, 6 lights / 60 rain parts / 24 motes / 12 wind
objects / 3 fog sprites / 6 glints / 1 rainbow maximum. Observed static art:
432 parts, one decorated plot. ParticleEmitter count remains zero.

Explicit increase over A.2b: one invisible noncolliding celestial anchor,
49 attachments + 49 BillboardGuis/ImageLabels (one moon, 48 stars), and two
original textures totaling **109,227 decoded RGBA8+mip bytes (0.104 MiB)**.
They are allocated once. Full/Reduced/Minimal show at most 48/24/12 stars and
one moon. Other caps are unchanged. This is a count/memory budget, not a measured
phone draw-call or FPS result.

Reduced retains the core sky/cloud/weather identity and two mist sprites; Minimal
retains core sky/clouds and celestial identity with no local rain/motes/mist.
Reduce Motion disables wind, rain motion and motes. It preserves the slow global
time/weather cycle and celestial visibility. Stopping restores original sky and
cloud object identities, Lighting properties, GlobalWind and wet path colors.

[CC0 license and exact-byte receipt](../assets/environment/polish/receipt.json)
pin the new generator and both PNGs. The six-face A.2b skybox and 14-model
Quaternius package are unchanged. No third-party Zelda/Nintendo assets.
The small license CRLF/LF mismatch found by the first Ubuntu CI run was fixed
with explicit generator line endings and Git byte-preservation attributes;
runtime and texture PNGs did not change.

**Experience asset permissions remain BLOCKED.** Local `rbxasset://m7a2c-v2/`
and `rbxasset://m7a2b-v4/` paths are for this Studio draft, not published asset IDs.
Physical phones and multiplayer load are also BLOCKED. No publishing was used
to bypass these gates.

## Validation and reproduction

867 portable tests pass, retaining all 859 A.2b tests and adding eight cases:
continuous normalized low moon trajectory, celestial weather fades, deterministic
bounded stars, distinct dawn, wet/dry restoration targets and three quality/
Reduce Motion star caps. Existing transition/weather/cycle seam tests remain.
The asset guard decodes delivered pixels to check meadow seams/opacity/frequency
and star alpha borders; six-face sky seams retain their independent pixel checks.

Actual Studio 0.746.0.7461264 checks passed: duplicate-owner rejection, original
object restoration, all poses/tier caps, Reduce Motion, immutable textures,
celestial cleanup, ground collision/physical-property contract and zero own
asset-load failures. The final harness and gameplay logs have no CreatorError.
This does not imply a clean Roblox network/backend log or live-backend acceptance.

[Evidence](evidence/m7-a2c/README.md) includes 20 raw matched before/after captures,
manual quality settings, full-game UI captures, a 45.00-second native recording,
sanitized audit lines and exact source/build hashes. Runtime source commit:
`18d36466f86f4a0bf9b4d3723482dac5b313c751`. Later license/evidence commits do not
change the captured runtime. CI also checks current runtime against its snapshot.

1. Run `npm run tools` and `npm test` (equivalent Node script entry points if npm
   is absent), then `node scripts/build-atmosphere-comparison.mjs` and
   `node scripts/build-local-preview.mjs`.
2. Install the checked local textures with
   `node scripts/install-atmosphere-preview.mjs STUDIO_VERSION_DIR atmosphere`
   and the same command ending in `polish`. The installer validates the closed
   file roster and hashes and refuses conflicting existing files.
3. Open `build/M7A2c-SpawnAudit.rbxlx`, Play, select manual Roblox quality 5/10.
   Keys 1/2/3/4/5/6: day/sunset/night/rain/dawn/afterrain. V changes camera;
   Q changes effect tier, R Reduce Motion, P prints audit, T starts the 45s loop.
4. For full game open `build/PotionTycoon-M7-LocalPreview.rbxlx`, Play. Starts
   Reduced; Q cycles tiers. C restores normal character camera/live time. These
   are Studio-only review helpers, absent from the release project. Progress is
   in memory, commerce/trading off. Do not publish these preview artifacts.

Art approval, fine-flicker clearance, phone performance, asset permissions and
multiuser acceptance cannot be inferred from CLI/CI or the isolated harness.
