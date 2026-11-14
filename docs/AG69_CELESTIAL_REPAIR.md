# AG69-R1 — celestial consumer repair

Base: Draft PR #42 `df5f3ee7f582764718390957d7234633bd6747e5`.
Runtime revision: `590e141094b0090804291d8b75b6b99df4bd871b`.
Status: CODE / STUDIO VERIFIED (local scope below); OWNER ART OPEN;
PUBLISHED NO. No upload, permission change, merge or economy change.

## Diagnosis and bounded repair

Fresh ordinary F5 on 2026-11-14 reproduced the two Sky errors from the previous
day. All twelve typed Image preloads succeeded, but `sky.sun` and `sky.moon`
requested a KTX representation unavailable for Image IDs `127279777775296` and
`120296233207649`. This is not evidence of missing Experience grants. The old
report's preload success must not be read as proof that these Sky consumers worked.

The moon already used a BillboardGui/ImageLabel; its duplicate native Sky moon
was hidden with angular size zero but still requested the failing texture.
R1 removes that redundant request and gives the sun the same existing owned
celestial image path. The uploaded files, twelve IDs, source hashes, Restricted
group ownership and universe grant are unchanged. This repairs the game's
consumer, **not Roblox's unsupported native Sky representation**.

The sun follows `Lighting:GetSunDirection()` at the existing 420-stud rig
distance with the former seven-degree angular extent. A continuous horizon /
cloud / rain fade prevents a bright disk in full rain. It is occluded by geometry
(`AlwaysOnTop=false`). It does not illuminate the scene; the original Lighting
sun remains the light source. Moon movement and size are unchanged.

Budget delta: exactly one Attachment, one BillboardGui, one ImageLabel (+3
instances; 50 celestial attachments including the existing moon and 48 star
slots). No new Part, light, emitter, render connection or event hook. The same
update loop and owner cleanup apply to Full, Reduced, Minimal and Reduce Motion.
Actual Sun/Moon `ImageLabel.IsLoaded` is exposed separately from preload status;
Roblox may defer an offscreen image until its first render.

## Reproduction

Run `npm run tools`, `npm test`; open ordinary `build/PotionTycoon.rbxlx`, F5.
The review copy `build/AG69-R1-Review.rbxlx` has SHA-256
`9181a356a0dbda6cc1f1ff24d7f56ca8b45862dc62b63587870f223ae003add7`.
Use client Command Bar `qa/ag69-celestial.luau`, then `_G.AG69R1.matrix()`
and `_G.AG69R1.restart()`. The QA module is not mapped into the game.
Its close sky views diagnose actual celestial consumers; they are not substitutes
for the ordinary gameplay art comparison in AG70.

Local suite: 1285 Luau tests (1281 inherited + four celestial tests), 14 Node
tests; compile, portable analysis and Rojo build passed. Two inherited C01 lint
warnings remain. New QA source was separately compiled after the suite enumerated
its inputs. Runtime CI Windows + Ubuntu passed in
[run 43589975555](https://github.com/branch-danya-dev/magicpotiongacha/actions/runs/43589975555).
Final report/guard HEAD checks are linked in PR #42.

## Native result, 2026-11-14

- Fresh ordinary F5, all twelve preloads Success; **zero Sun/Moon Sky errors**.
- Real celestial consumers loaded in all **12 Sun/Moon × tier × motion** cases;
  50 attachments, existing light caps 6/3/0.
- **Three stop/restart cycles**: original Lighting values and object identities,
  GlobalWind restored, weather folder removed, celestial images reload normally.
- Original diagnostic failure log, repaired session log, native sun/moon captures
  and exact source/build hashes: [receipt](evidence/ag69-r1/receipt.json).
- No runtime texture swaps, new uploads or permissions. The Studio editor emitted
  unrelated bundled-font-as-image warnings before F5; those are not M7 asset errors.

The AG69 celestial blocker for continuing AG70 is repaired. This is not owner
art acceptance, a physical-phone result or a fix to Roblox's backend KTX loader.

Physical phones, multi-client load, independent account and published-server
access are not tested by this local session. Existing private Experience identity
and permission evidence remains in `docs/evidence/ag69/`; no new grants are needed.
