# Willow V2 source package

Derivative of the existing owner-paid Meshy willow, not a new generation.
V1 and its six Restricted Roblox assets are preserved under `../willow/`.
This folder has no uploaded Roblox IDs; the Studio QA scene reads local source
geometry and shared V1 atlas/bark pixels. It does not modify access or publish.

Three FBXs and the packed Blender file retain nine bones, two materials,
the S-shaped trunk and the same UV atlas. Each tree has 5,783 triangles:
2,591 wood + 3,192 leaves, 76 groups / 228 curved ribbons. Three root shapes
and three crowns can be mixed independently from six shared mesh resources.
Four bark tints and three foliage tints are in `qa/trees/TreeVisualConfig.luau`.
Per-instance variants use stable string IDs; no random runtime selection.

Rebuild with Blender 4.5.9 `--background --python scripts/willow/build_v2.py`,
then `--background --python scripts/willow/validate_v2.py`, followed by
`node scripts/willow/manifest-v2.mjs`. No command creates renders or screenshots.
The mesh JSON, not Blender/FBX metadata timestamps, is the deterministic runtime
payload. FBX imports may require applying the documented material tint in Studio;
the local QA adapter applies it explicitly. Texture alpha pixels are unchanged:
rounded geometry, reduced ribbon width and existing soft alpha create the
candidate edge treatment, whose artistic adequacy still needs owner review.

Primary owner delivery: `node scripts/build-willow-v2-game.mjs --owner-user-id=11924805007`
creates `build/PotionTycoon-WillowV2-Game-QA.rbxlx`, with the ordinary playable
game, familiar selection, HUD and player camera. Tree V2 occupies the existing
hero location. No benchmark deck or camera override is included in this game.

`node scripts/build-willow-v2.mjs` creates the optional isolated diagnostics `.rbxlx`. It checks V1 and
all production sources against the base before building. No runtime economy,
save data, station positions or production scene admission is included.
