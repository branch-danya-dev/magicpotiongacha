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

### Imported source and preparation

The owner explicitly approved direct static inspection, optimization and Studio
import on 2026-11-05 despite the absent game-dev CLI. That exception is fulfilled;
no canonical game-dev receipt is claimed. The exact free 2024 Standard archive
contains CC0-1.0 proof. See [asset provenance](../assets/environment/README.md).

Fourteen reviewed models now provide branched trees, pine, a red landmark tree,
grass, clover, fern, flowering bushes, flowers and rocks. The pilot uses native
bounded Terrain, painted bark/leaf atlases and warm native stone paths/wood lamps.
Paths retain the imported geometry, with a quiet native surface to reduce atlas
noise. Source preparation retains whole leaf cards and limits trees to 2,000
triangles, small props to 500; the actual imported IDs are in the receipt.

### Review contract

This is the replacement candidate for the rejected primitive pilot, not an
ART APPROVED result. [Current Studio evidence](evidence/m7-revision/README.md)
separates beauty views from ordinary gameplay. Existing machines, purchase pads,
and crystal are still M6 greybox; final machinery belongs to later art work.
Seven other plots remain unchanged. Do not duplicate the pilot before explicit
ART APPROVED and the separate #18 UX check; #19 builds the shared island later.

The authored mesh/Part count is 432; mesh plus native box estimate is 116,626
triangles, excluding engine-generated Terrain. The complete imported texture set
is 27.96 MiB RGBA8 plus mipmaps (conservative file-derived estimate, not GPU usage).
Full/reduced/minimal light caps remain 6/3/0. Draw calls, total visible triangles,
FPS, thermal behavior and real-phone usability remain unmeasured. Prior draw-call
and grass-density targets are targets only; the current full-detail composition
is not certified for low-end phones.
