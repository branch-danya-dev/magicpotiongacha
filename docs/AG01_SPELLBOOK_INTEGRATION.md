# AG-01 — Reproducible Spellbook Lectern

**Status: IMPLEMENTED / CODE CANDIDATE; native Play review in progress.**
Task [#28](https://github.com/branch-danya-dev/magicpotiongacha/issues/28),
[Draft PR #30](https://github.com/branch-danya-dev/magicpotiongacha/pull/30).
Base `integration/ag00-base` @ `7d6d47826e919683ee991c911185215cda0d3d2e`
([AG-00](AG00_INTEGRATION_BASE.md)); work branch `feat/ag01-spellbook-reproducible`.
Exact delivered SHA and CI are recorded in the PR and `build/ag00-integration.json`.
No merge, game publication, public access, Creator Store listing, economy/schema or release-flag changes.

## Acquisition and actual import

On 2026-11-12 the owner supplied a renewed download from
[Shuriken Studio](https://shuriken.studio/models/props/spellbook-lectern).
`C:\Users\keara\Downloads\spellbook-lectern.glb` is 239260 bytes and byte-identical
to the tracked source. SHA-256:
`ff12f9f121daa74d444601240d3601a16849e1c9ee69dbf83a83c5db22b76a52`.
Creation/write timestamp 09:31:30 UTC and NTFS Zone.Identifier identify the publisher
media URL and shuriken.studio referrer. The applicable reacquisition license is
[version 2026-11-12](https://shuriken.studio/legal/models), permitting incorporation
in game/source/place files, not standalone redistribution or Creator Store listings.
This supersedes the missing receipt for the historical November 7 acquisition.

The owner authorized private import in the existing experience. Studio confirmed:
`GameId=10776120489`, `PlaceId=125724638469407`, `CreatorType=Group`,
`CreatorId=925845207` (**addout studio**). Studio 0.747.0.7471481 imported with this
creator selected, Upload to Roblox / Add to Workspace / Anchored on, Stud scale 1,
Merge Meshes and Import as Package off, scene-origin pivot. Import completed with
a green status. No new permissions were enabled. Save to File exported the actual
root as `assets/props/SpellbookLectern.rbxmx`; source model asset is `92876851534007`.

Source: 10 nodes, 9 meshes, 23 material primitives, 4194 triangles, 9 materials,
no images/textures, external buffers, animations or skins. Actual export: 11 Models
(including the importer scene wrapper) and **23 MeshParts** with persistent MeshIds.
All IDs, source-to-native primitive mappings, source material factors, import settings,
raw/export hashes and evidence status are in [the manifest](../assets/props/spellbook-lectern.manifest.json).

## Material repair and limits

The actual importer discarded all source material colors/factors and double-sided
flags: every MeshPart was default grey Plastic, DoubleSided=false. This was observed
both in the preview and by reading all 23 parts in Studio. The deterministic
`scripts/spellbook-asset.mjs --normalize` repairs the exported properties using the
source primitive/name mapping: linear baseColorFactor becomes sRGB Color3 bytes;
double-sided rendering is restored. Gold maps to Metal; only source-emissive
Fire/Crystal/Magic map to Neon; other surfaces map to SmoothPlastic. Geometry,
pivots, hierarchy and persistent IDs remain from the actual export. Parts are
anchored, non-colliding, non-touching, non-querying; Reflectance stays zero.

**Known fidelity limit:** native roughness and emission strength are approximations,
not a faithful numeric PBR conversion. No fabricated texture maps or extra light
sources were introduced. Owner art acceptance remains open. Roblox's
[material API](https://create.roblox.com/docs/reference/engine/enums/Material) and
[PBR guide](https://create.roblox.com/docs/art/modeling/surface-appearance) describe
these distinct rendering paths.

## Reproducible build and visual fallback

1. Check out this feature branch (full history), run `npm run tools`, then `npm test`.
2. Run `node scripts/check-integration-base.mjs` on a clean committed tree. This
   verifies ancestry and builds the ordinary place again, comparing exact bytes.
3. Open `build/PotionTycoon.rbxlx` in Studio and press Play. No Import 3D step is
   needed: Rojo maps the pinned native XML to `ServerStorage.SpellbookLectern`.
4. Existing Studio memory-mode safeguards remain. Do not publish to test the build.
   Existing `UIFoundationDemo` can cover real gameplay UI; disable that workspace
   attribute only in the local Play client when checking the real HUD.

Server placement validates the exact 23-mesh allowlist and inert hierarchy before
creating one clone per fixed plot. It fits the visual uniformly to 6.5 studs and
bottom-centers it on terrain (plot floor fallback). EnergyPoint and ParticlePoint
are passive attachments on Cover. No world.update wrapper, profile/save mutation,
new remote, prompt reparenting or anchor Size/CFrame/physics mutation is used.
Repeated installation/placement is idempotent; foreign links cannot steal another
plot's clone. Failed preparation/publication discards only the new visual and logs
a bounded diagnostic, leaving the old crystal and its interactions intact.

Client mesh loading is shared across all eight clones: 23 pinned references, one
PreloadAsync attempt and a 15-second terminal timeout. A book is revealed only after
all references succeed. The old crystal is hidden with LocalTransparencyModifier,
so server updates cannot flash it back. Denied/missing/slow assets retain the ordinary
crystal; late success after timeout does not cause a pop. Removing a visual/link
restores the previous local transparency and disconnects its listeners.

Budget: 23 MeshParts / 4194 source triangles per plot; 184 / 33552 for eight plots;
9 source materials, zero textures, zero emitters/lights, two attachments per plot.
Full/Reduced/Minimal and Reduce Motion share the static model. No per-frame work or
runtime texture churn. Draw calls/device performance are not measured by CLI.

## Verification matrix

- Local: 1142 inherited tests preserved byte-for-byte; 13 new AG01 cases pass.
  174 Luau sources compile, portable analysis passes with the two inherited C01
  warnings. Both Rojo builds/sourcemaps and historical preservation checks pass.
- Asset check validates GLB/native hashes, primitive/material mapping, persistent
  IDs, hierarchy, inert physics, deterministic normalization and build inclusion.
- Native import/export and identity: observed in Studio, completed 2026-11-12.
- Ordinary Play/rebuild, owner/permission checks and engine fallback audit: results
  will be recorded after the native run, separately from portable tests.
- Phone, 2–8 real clients, real DataStore backend and performance: NOT RUN/BLOCKED.
- AG-01 OWNER ACCEPTED / PUBLISHED: NO. AG-02 visual gate remains open.
