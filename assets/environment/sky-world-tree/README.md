# Sky World Tree — original layered candidate

Current R2: `r2/` retains a sibling tree contrast edit, its exact prompt and a
separate manifest. `node scripts/sky-landmark-r2-assets.mjs` exports alpha-aware
crop metadata and four runtime images with the same 6.25 MiB decoded budget.
The original masters/textures and recipe below remain unchanged for rollback.
R2 game: `node scripts/build-sky-landmark.mjs --owner-user-id=11924805007`, output
`build/PotionTycoon-SkyWorldTree-R2-QA.rbxlx`.
See `docs/SKY_WORLD_TREE_R2.md` for native numeric QA and open art checks.

## Original R1 package

Original OpenAI ImageGen concept and three transparent layers created for this
project on 2026-11-18. The complete prompts, reference relationships and output
identities are in `generation.json`. No extracted Elden Ring imagery, paid
third-party generation or Roblox uploads. Generated artwork is subject to the
applicable OpenAI terms; no exclusive copyright or CC0 status is asserted.

`source/Concept.png` is the original concept; `Tree.png`, `Cloud.png`, `Glow.png`
are separate 1536x1024 masters. Masters are preserved exactly. Generation itself
is not deterministic: the saved PNGs, hashes and export script are the repeatable
inputs. No screenshots, QA renders, videos or GIFs are included.

`node scripts/sky-landmark-assets.mjs` recreates optimized textures and manifest:
transparent square padding, premultiplied alpha area reduction, then a fixed
Minimal composite of the same source layers. Tree 1024, cloud 512, glow 256,
Minimal 512 pixels; four decoded RGBA maps total 6,553,600 bytes (6.25 MiB).
All exported borders are fully transparent. Tree's bottom 10% is fully transparent
independently of the moving cloud mask, preventing an exposed rectangular stump.

Build the normal game with
`node scripts/build-sky-landmark.mjs --owner-user-id=11924805007`.
Output: `build/PotionTycoon-SkyWorldTree-QA.rbxlx`. This contains the existing
game and player camera, not a separate inspection platform. `--verify` enables
bounded numeric checks that change quality/time/moon and restore their settings;
the owner build omits this flag. `--reuse-game` is for a just-built compatible
Willow V2 game and is used by CI to avoid rebuilding its dependencies twice.

This is a local Studio-only composition over the draft lunar and willow stack,
not production asset admission. See `docs/SKY_WORLD_TREE.md` for validation and
the pending native memory-fix/visual checks.
