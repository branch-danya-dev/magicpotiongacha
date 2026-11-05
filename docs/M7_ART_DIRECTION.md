# M7.1 / Gate A — Honeyglade pilot

## Owner revision — 2026-11-05 (takes precedence)

The existing primitive pilot is **ART REJECTED**, not pending approval. Its green
841-case CI proves technical regression coverage only. The authoritative
[art blocker](https://github.com/branch-danya-dev/magicpotiongacha/pull/17#issuecomment-6646049074)
and [ordered route](https://github.com/branch-danya-dev/magicpotiongacha/pull/17#issuecomment-6646176093)
require: revised ONE-farm Gate A → explicit artistic approval and the separate
[#18 gameplay UI gate](https://github.com/branch-danya-dev/magicpotiongacha/issues/18)
→ [#19 eight-farm island](https://github.com/branch-danya-dev/magicpotiongacha/issues/19).
No primitive duplication to the other seven farms. No merge or publication.

The world concept is one shared island per server, eight personal farms in the
existing 4×2 layout and a central Bazaar. UserId owns progress, not the temporary
plot number. MaxPlayers=8 needs a later manual place-setting check; eight plot
objects alone do not configure server capacity. These are Gate B requirements,
not implemented changes in this revision.

### Concrete visual direction before rebuilding

An open honey-lit workshop embedded in continuous meadow terrain. Three irregular
tree groups frame the clearing; lower planting and a worn earth path guide the eye
to the crystal and Bazaar. Rounded slopes and a small shoreline fragment sit
outside fixed gameplay surfaces. Keep the workstation floor, all logical anchors,
passages and interaction distances unchanged. Hide slab seams through terrain
composition rather than repeating rectangular cover blocks.

Official Quaternius references (author renders, **not Roblox evidence**):

1. [Forest path / lighting target](https://img.itch.zone/aW1hZ2UvMjg2MjIxNC8xNzEwOTU4Ny5wbmc=/original/R7DE6B.png):
   bright opening, layered crowns, soft depth and grass grouped along the path.
   Reduce the reference's lime saturation and vegetation density near machines.
2. [Open valley / relief](https://img.itch.zone/aW1hZ2UvMjg2MjIxNC8xNzEwOTU4MC5wbmc=/original/bgl8BP.png):
   continuous slopes, varied rock scale, alternating open and planted ground.
3. [Free Standard asset roster](https://img.itch.zone/aW1nLzE3MTA5NTc2LnBuZw==/original/WQSxXX.png):
   actual branched trees, layered foliage, modeled grass, fern, flowers and stones.

Updated palette: meadow #8DA66B, sage #638777, deep foliage #385C50, warm stone
#BAA68A, honey bark #99724D, cream light #EFD7AA, sky #B8D7DE. Lilac/turquoise
remain sparse magical accents. Matte surfaces, broad painted bark/stone variation,
no noisy scans. Dawn peach/cool shadow; day cream/blue-green shadow; sunset honey
side light; twilight light blue with amber lamps; rain cool diffuse with depth.
Do not promise the reference's Unity/Godot shaders in Roblox.

### Acquired source candidate, not yet admitted

The free [Stylized Nature MegaKit Standard](https://quaternius.itch.io/stylized-nature-megakit)
was downloaded on 2026-11-05 from the author's itch.io page. The archive contains
68 models and an explicit CC0-1.0 `License_Standard.txt`. It is an alternative to
the older Ultimate Stylized Nature Google Drive download, not the same package.
Archive SHA-256:
`298f6732b872e4cf7b30e6e7abf9641c7f6dc6b326df37ac089533ed7e3d58c9`.
The general site now carries QAL v1.0; preserve the exact 2024 Standard archive's
CC0 proof and do not generalize that license to other downloads or new releases.

| Source selection | Measured triangles per source model | Preparation required |
| --- | --- | --- |
| CommonTree_1 / 3 / 5 | 6265 / 3505 / 3182 | Reduce to <=2000, preserve branch/crown silhouette |
| TwistedTree_1; Pine_2 | 9564; 3648 | Optimize; sparse landmark/backdrop use |
| Grass_Common_Short; Grass_Wispy_Tall | 155; 622 | Short primary, tall sparse; simplify tall variant |
| Bush_Common_Flowers; Clover_2; Fern_1; Flower_3_Group | 1368; 615; 288; 755 | Simplify heavy groups; local flower patches |
| Rock_Medium_1; Pebble_Round_1; RockPath_Round_Small_1 | 342; 136; 998 | Simplify path; preserve gameplay collision |

Static audit: ZIP CRC and safe paths; no symlink records; all 68 glTF buffer/image
dependencies local and present; buffer sizes, index ranges and triangle counts
checked. Selected texture dimensions/hashes recorded. This is **not** a canonical
package receipt, malware certification, visual model QA or successful Roblox import.
No third-party code was executed. Files remain in staging outside the game repo.
[Source audit](../assets/environment/megakit-source-audit.json).

The selected vendoring skill explicitly requires `game-dev` package verification
and admission. That CLI is absent. **Runtime import remains BLOCKED** pending a
working CLI or the owner's explicit exception for a documented direct workflow.
Do not mark new artwork complete while this remains unresolved.

### Targets to validate, not measured performance

Trees <=2000 triangles, small props <=500; visible environment <=150k triangles;
imported texture budget <=32 MiB. Initial added draw-call targets: <=100 full,
<=60 reduced, <=35 minimal; visible grass groups <=80/35/12 per pilot. Local
lights <=6/3/0. Profile actual Roblox rendering before claiming these targets pass.

After rebuilding, capture the same camera at dawn/day/sunset/twilight/rain, plus
ground/tree closeups and normal gameplay spawn/crystal/Bazaar views. Do not hide
world labels to claim the #18 UX gate. Real phone and 2–8 player tests remain
BLOCKED until performed. New screenshots are not yet available in this revision.

## Historical first-pass direction (rejected implementation)

This document precedes the art implementation. The owner's Issue #16 authorizes
one pilot and lighting/weather comparisons. Gate B (eight decorated plots) waits
for the owner's visual acceptance. Base: M6 bbc8891d45e551b691363383d1cacf2d69354283.

Cozy Light Fantasy: an inhabited alchemist's clearing in a soft, generous valley.
Broad rounded silhouettes, quiet grass, honey wood, warm stone and cream cloth;
selective lilac crystal and amber lantern accents. Zelda is an atmosphere reference,
not an asset, character, composition or music source. No copyrighted game assets.

Palette: grass #86A66D, sage #638777, deep leaves #3E665C, stone #B5AA91,
honey wood #96724D, cream #F1DCAD, sky #B8D7DE. Saturation belongs to small flower
groups and the crystal. Avoid acid neon, noisy realistic PBR, hard polygon facets,
black nighttime shadows and bright white rain. Existing stations remain temporary.

Composition: keep the flat 77×75 work surface, agricultural left and processing
right. Low planting frames the entrance; trees form irregular rounded masses at
the outer edges and back. The crystal remains the focal point. A worn honey-stone
path and paired lanterns connect the clearing toward the existing Bazaar. Keep
the passage and TradePost visible. Hills stay outside floors, pads and waypoints.

Day should feel fresh and readable; sunset warm but not orange everywhere; night
blue with visible ground and amber accents; rain soft with broad cloud shadow.
One 25-minute deterministic presentation cycle; smooth long transitions. No rain
sound or music without a separately verified license. UI retains opaque dark
backing and light text; use an uncluttered art-review view separately from the
actual gameplay view, clearly labelled.

Nature source priority: Quaternius Ultimate Stylized Nature Pack, May 2022, CC0
1.0, official source https://quaternius.com/packs/ultimatestylizednature.html .
External source download, validated package admission, engine upload and artistic
approval are different gates. `game-dev` is unavailable on this workstation;
verified package admission remains BLOCKED. No loose external files are copied
into runtime. The first runnable fallback uses original deterministic Roblox
primitive artwork; it must not be described as imported Quaternius art. Source
selection/license/hash handoff is kept separately. No paid pack or AI spend.

Review: compare the same scene/camera in day/sunset/night/rain; also inspect spawn,
crystal overview and Bazaar approach. Request owner approval of palette, density,
tree silhouettes, clear work zones and night visibility. No eight-plot rollout
until that decision; Studio screenshots do not prove real-device performance.
