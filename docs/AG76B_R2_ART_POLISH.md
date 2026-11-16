# AG-76B-R2 — Cliff, woodland and Minimal-night polish

**CODE CANDIDATE / STUDIO PLAY CHECKED / ART PENDING / NOT INTEGRATED / NOT PUBLISHED.**
Owner review is still required. These images demonstrate the candidate, not approval.

## Revision and isolation

- Branch: `feat/ag76b-r2-wizard-island-poc`.
- Follow-up base: `2f981f7ffee8785457dce866f1f7f1d604e4b27d`.
- Exact delivery HEAD is recorded by `scripts/build-wizard-island.mjs` in
  `build/wizard-island-build.json` after committing. The tracked evidence manifest
  pins every captured source file and the artifact independently of that receipt.
- Captured artifact SHA-256: `55013e59203419ccb58eb84d79c8cb3ca6bb04f7e1d55e6d01845263184562ce`.
- `src/`, `assets/`, `default.project.json`, gameplay coordinates, economy,
  profiles and original asset files have no diff from the follow-up base.
- This is a separate Studio-only F5 art scene, without the production bootstrap,
  gameplay remotes or persistence. Nothing was uploaded, integrated, merged or published.

## Changes visible in Play

The 18 stretched stock-rock cliff masses were removed. One original closed
surface now supplies the entire underbody: **3,936 vertices / 7,868 triangles**,
shared smooth normals, asymmetric taper, irregular rim and low-frequency erosion.
It uses native Slate and per-vertex moss tint. Runtime checks reject degenerate
faces, invalid normals and edges with other than two incident faces. The native
mesh retains its authored local coordinates; its position was verified in Play.

The original source is `qa/wizard-island/Cliff.luau`; it creates an EditableMesh
and a single client MeshPart during Studio Play. This requires no external model,
texture or Roblox upload. The mesh is noncolliding; the existing walkable proxy
and altar location remain unchanged. The captured client contains 238 MeshParts;
the authored triangle estimate is 93,892 nature + 4,194 book + 7,868 cliff =
105,954, excluding avatar, terrain and primitive props.

The woodland uses fewer repetitive pines, three exposed twisted branch silhouettes,
cooler subdued foliage and smaller ground-cover clusters. Original leaf alpha and
color maps remain intact. All imported nature remains the existing admitted
Quaternius CC0 subset; Spellbook and its materials remain unchanged. The route
now uses 24 low, broad pebbles instead of 35 noisy rock-path clusters.

The QA lighting projection desaturates the scene slightly and preserves a single
unchanged EnvironmentView owner. Dusk is clock 17.6. Night is clock 0, Ambient
147/166/192, OutdoorAmbient 162/182/211, Brightness 2.6, Exposure .38 and
Atmosphere Density .10. Minimal remains readable without local light support.
These settings affect only this art place; they are not production look changes.

## Native evidence and bounded checks

Six original PNG files in [evidence/ag76r2-polish](evidence/ag76r2-polish/manifest.json)
were saved using Studio's Screenshot command during ordinary F5 Play. No external
rendering, generated imagery, color grading or image retouching was used.

| Capture | State |
| --- | --- |
| [Spawn](evidence/ag76r2-polish/01-spawn-dusk.png) | Dusk / Full |
| [Whole island](evidence/ag76r2-polish/02-island-dusk.png) | Dusk / Full |
| [Altar](evidence/ag76r2-polish/03-altar-dusk.png) | Dusk / Full |
| [Minimal night](evidence/ag76r2-polish/04-spawn-night-minimal.png) | Night / Minimal / Reduce Motion |
| [Full night](evidence/ag76r2-polish/05-spawn-night-full.png) | Night / Full |
| [Day](evidence/ag76r2-polish/06-spawn-day.png) | Day / Full |

The spawn camera, target and FOV are identical across the three times and both
night quality settings. The earlier candidate's evidence is preserved separately.
Final Play began at 2026-11-16 18:33:57 UTC in Studio 0.747.0.7471481. Native asset
preload succeeded with no failed assets. Minimal + Reduce Motion reported zero
enabled PointLights, wind objects and motes, one cliff, and one set of inherited
Lighting effects. [The native log extract](evidence/ag76r2-polish/studio-qa.txt)
contains the actual counts and measurements.

| Quality | FPS | Median frame interval | P95 frame interval | View lights / motes / wind |
| --- | ---: | ---: | ---: | --- |
| Full | 233.3 | 4.16 ms | 5.44 ms | 6 / 24 / 12 |
| Reduced | 232.9 | 4.18 ms | 5.37 ms | 3 / 9 / 4 |
| Minimal | 239.2 | 4.09 ms | 5.10 ms | 0 / 0 / 0 |

Each is a 15-second RenderStepped sample after four seconds of settling, at the
same spawn camera and dusk pose. RTX 5070 Ti, Studio Q6, viewport 1566×1095.
These are frame intervals, not isolated GPU timings; results approach the desktop
frame cap. Reported Studio/client memory was approximately 2,659–2,662 MiB and
is not incremental island memory. Full/Reduced also retain one existing altar
light outside EnvironmentView's light count; it is disabled in Minimal.

## Reproduction and status

Run `npm run tools`, `npm test`, then `node scripts/build-wizard-island.mjs`.
Open `build/WizardIsland-AG76B-R2-ART-PENDING.rbxlx` and press F5. Keys: 1 spawn,
2 overview, 3 altar, 4 free walk; 5 day, 6 dusk, 7 night; Q quality; R Reduce Motion.

- Tools: PASS, pinned local Luau and Rojo verified.
- Regression: **1,360 Luau + 14 Node tests passed**, 267 Luau sources compiled;
  standard Rojo builds passed. Logs: `build/ag76r2-polish-tools.log` and
  `build/ag76r2-polish-check.log`.
- After the final visual-only placement/path adjustments, all five QA Luau files
  were recompiled and the standalone build/native Play were rechecked. No domain
  changes were made after the regression run.
- Repeated art build: matching SHA-256 above, matching native capture source hashes.
- Windows/Ubuntu CI for this local follow-up: **NOT RUN**; inherited PR55 CI is not
  evidence for this revision.
- Owner art approval, real phones, production integration and multiplayer load:
  **OPEN / NOT RUN**. Native local EditableMesh success is not published-game validation.
- Existing vegetation remains stylized Quaternius geometry. Its suitability for
  the requested Dark Fairytale direction is explicitly left to owner review.

Roblox native geometry API reference:
[EditableMesh](https://create.roblox.com/docs/reference/engine/classes/EditableMesh).
No new asset license or permission grant was needed for this local candidate.
