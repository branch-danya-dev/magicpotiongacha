# A.2b Studio evidence — ART PENDING

Runtime source: `39788eafaf93de4c21f7817f0aff4cb4e38ffd35`.
Actual Windows Studio **0.746.0.7461264** captures, not concept renders.
No edits to the screenshot pixels. The final video is a continuous excerpt.

## Matched final views

All twelve final captures use **Full, manual graphics 5, Realistic, FOV 53**.
Both named cameras retain their inherited positions/targets. The isolated
review hides world labels; full-game UI captures below retain the actual UI.

| State | Overview | Spawn |
|---|---|---|
| Day | [frame](final-overview-day.jpg) | [frame](final-spawn-day.jpg) |
| Sunset | [frame](final-overview-sunset.jpg) | [frame](final-spawn-sunset.jpg) |
| Night | [frame](final-overview-night.jpg) | [frame](final-spawn-night.jpg) |
| Rain | [frame](final-overview-rain.jpg) | [frame](final-spawn-rain.jpg) |
| Dawn | [frame](final-overview-dawn.jpg) | [frame](final-spawn-dawn.jpg) |
| After rain | [frame](final-overview-afterrain.jpg) | [frame](final-spawn-afterrain.jpg) |

[45-second Studio recording](final-studio-cycle-45s.mp4): Full/manual 5, fixed
spawn camera, second continuous loop. Native 2112×1104; H.264 recompression,
45.00 seconds, no retiming/recoloring/compositing. SHA-256 and source recording
receipt are in [captures.json](captures.json). This is a visual preview, not a
performance benchmark. The 15-frame sample and adjacent-frame luminance audit
found no large full-frame cut/flash; fine shimmer remains unaccepted.

## Full game / baseline

- Actual default Reduced: [day](gameplay-reduced-day.jpg),
  [night](gameplay-reduced-night.jpg), [rain](gameplay-reduced-rain.jpg).
- Full: [rain](gameplay-full-rain.jpg). [Manual 5 proof](gameplay-graphics5.jpg).
- Exact original A.2 on the same engine: [day](baseline-spawn-day.jpg),
  [night](baseline-spawn-night.jpg), [Manual 5 proof](baseline-graphics5.jpg).
  Ground noise and pale fern/path edges are reproduced in the baseline.
- [Studio assertions and own-module log excerpts](studio-audit.txt): duplicate
  owner rejection, original-instance restoration, all-tier and Reduce Motion
  checks, all-pose/camera caps, immutable texture IDs and zero local preload
  failures. Full engine logs are deliberately not committed.

The full-game UI is readable but existing world labels overlap. Engine output
also includes local-universe chat/asset HTTP failures and a cloud shader fallback
warning; no claim of an entirely warning-free Studio session is made.

## Calibration diagnostics, not final-build captures

[Soft day](soft-day.jpg) / [Realistic day](realistic-day-low5.jpg) and
[Soft sunset](soft-sunset.jpg) / [Realistic sunset](realistic-sunset-low5.jpg)
were compared at manual 5 before the final polar seam correction. Differences
at this quality are small. Those older binaries were overwritten, so the
manifest marks their exact build provenance unavailable rather than assigning
the final SHA to them. They are supporting observations only.

[Earlier polar cut](diagnostic-sky-seam.jpg) / [v4 corrected sky](v4-seam-day-low5.jpg)
show the seam investigation. The corrected capture uses the retained SeamAudit
binary, whose runtime differs from the final only in later celestial/night
settings. [Direct sunset](sunset-sun-position.jpg) demonstrates the additional
west-facing diagnostic viewpoint; [arc](afterrain-rainbow.jpg) demonstrates
conditional anti-sun after-rain placement during calibration.

## Exact build identity

| Build | SHA-256 |
|---|---|
| Final captured NightAudit | `d1db8c61071e6f40b0fd2465c26455be81210c913f31e4c1beb3c123ef9e95a1` |
| Final full game | `61f41efb8230bd2b282e4172c975c49b55140cd14c52ad1fdd31674e8852d16e` |
| Original A.2 baseline | `29508ba916d6168434a6dce06eb50b5ccdcb7dcfc89d665d4b1bf0b04448a805` |

NightAudit differs from the final Realistic review build only in initial
night/sky pose; subsequent 1–6/V selections use the same modules. The complete
normalized runtime source snapshot and image/video hashes are checked by CI.

## Still open

Night stars/moon are not convincingly visible in the inspected views. Inherited
surface stippling and pale edges remain. Dawn mist/dew are subtle. Yellow pads
remain dominant and world labels overlap. **ART PENDING**; Roblox experience
asset permissions and physical-mobile performance are **BLOCKED**. Assets are
licensed CC0, but the delivered content paths work only in the local Studio
installation. No publishing, purchases, trade activation or merge occurred.
Issues #18 and #19 remain gated on owner visual review.
