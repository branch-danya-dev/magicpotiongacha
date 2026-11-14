# AG71 variant B — production icon atlas

Original generated illustrations approved by the owner with variant B on
2026-11-14. Source and exact generation prompt are retained in
`docs/art/ag71/concept-atlas.png` and `imagegen-prompt.txt`; this is not a third-party
icon pack, Roblox marketplace content or copied Zelda artwork.

`AG71_ArcadeAtlas.png` contains twelve aspect-fitted illustrations in 256px cells,
with 12px minimum padding, in a single 1024px RGBA image. `pack-ag71-art.mjs`
reproduces the approved SVG crops using local Chromium canvas. It does not upload.
The original source and approved Phase A exports remain unchanged.

`upload-manifest.json` binds exact bytes, source SHA, cell coordinates and intended
destination: Restricted asset, addout studio group 925845207, access only to
Experience 10776120489. The owner authorized this exact file in chat on
2026-11-14. Image **127092357608242** was uploaded as the group, observed
Restricted, and granted to the specified Experience. The manifest records the
receipt. No Creator Store, Open Use or paid content. Dashboard moderation was
last observed as In Review; successful Studio delivery is a separate observation.

Runtime uses native ImageLabel sprite rectangles and one image fetch, with no
EditableImage or dynamic texture churn. A temporary ImageLabel is preloaded and
destroyed; successful delivery enables B, failure keeps AG64. The actual artwork
and LOADED status were verified in ordinary Studio Play on 2026-11-14.
Repeat packing reproduced the authorized hash and preserved the upload receipt.
Image behavior: https://create.roblox.com/docs/reference/engine/classes/ImageLabel
