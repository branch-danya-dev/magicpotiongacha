# AG-01 — Reproducible Spellbook Lectern

**Status: IMPLEMENTED / scoped STUDIO VERIFIED; OWNER ACCEPTANCE OPEN.**
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

Client mesh loading is shared across all eight clones: 23 pinned MeshPart instances, one
PreloadAsync attempt and a 15-second terminal timeout. A book is revealed only after
all references succeed. The old crystal is hidden with LocalTransparencyModifier,
so server updates cannot flash it back. Denied/missing/slow assets retain the ordinary
crystal; late success after timeout does not cause a pop. Removing a visual/link
restores the previous local transparency and disconnects its listeners.
Passing the typed instances matters: bare ID strings were interpreted as texture
requests by Studio and failed with IncorrectAssetType. The final implementation
uses MeshParts and all 23 mesh requests succeeded. WorldContext keeps the old
visual hidden and highlights the book only while its client load state is ready.

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
- All 23 mesh IDs report Group 925845207 / addout studio through MarketplaceService.
  An initial burst hit HTTP 429; the paced retry verified all 23. Local Studio
  delivery succeeded under the importing account. This does **not** prove delivery
  to another account or a published server; no permission settings were changed.
- Ordinary F5 Play used runtime SHA `2ebd71b16515879eb8a4e66ef20611c4d2e23ac6`.
  A separate clean detached checkout with pinned tools produced byte-identical
  ordinary and repeat builds. Place SHA-256:
  `d9ed643247df26c3d6bd5cf91c943adebd0b89d6cec9b665ed3292d6224ee15f`.
  Final delivery changes only evidence and normalization receipt handling;
  final-head CI/receipt must independently confirm the same place hash.
- All eight plots: ready, 23 inert MeshParts, two attachments, no scripts/lights/
  emitters, no overlap with the old crystal. Native measured height 6.4963 studs,
  bottom Y 0.40625, original anchor Size (4,6,4), prompt distance 16 unchanged.
  Avatar spawned, walked to the book, and native **E** credited **5 Essence**.
  Highlight targeted the book; Full, Reduced and Minimal + Reduce Motion kept all
  eight books ready. Removing/re-adding the visual tag restored the eight-part
  old presentation / hid 23 book parts, then restored the book with eight clones
  total. These are one-client/eight-plot checks, not eight-player checks.
- Engine gameplay diagnostic, using the existing validated client intents and
  ordinary movement: two Healing crops/brews/sales, then crystal level 1 → 2,
  Gold 940 → 40 (900 cost), Essence 15 → 25 over the following five seconds.
  No grants, profile mutation, time acceleration or prerequisite bypass. This
  confirms the server upgrade/passive flow; the native upgrade-button gate is open.
- Missing/invalid template, denied/slow/partial mesh delivery, late-success timeout,
  rollback/idempotence and ownership isolation have portable regression coverage.
  Native tag-removal restoration passed. An actual permission revocation was
  deliberately not performed; denied-permission engine testing remains NOT RUN.
- Phone, 2–8 real clients, real DataStore backend and performance: NOT RUN/BLOCKED.
- AG-01 OWNER ACCEPTED / PUBLISHED: NO. AG-02 visual gate remains open.

## Evidence and remaining review

[Filtered native evidence](evidence/ag01/README.md) records only AG01 diagnostics,
with raw output excerpts and their SHA-256 values. No screenshots/video deliverable
was produced, following the owner's continuing instruction. The normal place was
opened locally (GameId/PlaceId 0, STUDIO_MEMORY); the group experience was used for
the authorized import and identity/creator checks, not a published runtime test.

Existing environment warning: twelve M7 local-only CC0 sky files were unavailable
in this Studio installation (`M7_19E_ASSETS failures=12`, LOCAL_ONLY). This is separate
from the book's 23 successfully delivered Roblox mesh assets. Material roughness/
emission approximation and owner art review remain open. The inherited UI foundation
demo was disabled only in the local Play client to inspect the real HUD.

Owner review must still exercise native mouse/touch controls, the upgrade button
and complete onboarding without Command Bar assistance, approve material appearance,
and arrange real-device/multi-account checks. No extra rights were requested or
enabled. AG-02 may use this build as its visual candidate; its live acceptance and
the AG-01 owner gate are not automatically closed by these technical checks.
