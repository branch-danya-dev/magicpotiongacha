# Current full-game Studio preview — 2026-11-17

**CODE CANDIDATE / STUDIO SMOKE VERIFIED / OWNER ART PENDING / NOT PUBLISHED.**

Owner requested a consolidated test build with all recent work. Base is local
`c7f4764f7f18a6791cb41c21611d9a8f7d8ab19b`, descending from Draft PR #59
`fdaf931b179ad188555147c720b768dd9334b17b` (remote HEAD checked 2026-11-17).
Branch: `feat/current-game-studio-qa`. No branch merge or production admission.

## Included

- Existing AG-76 owner-island server gameplay, V8, all 13 stations, original
  positions/routes, factory accounting, familiar system, HUD/Book/Market,
  starter cards, Green Slime template/two Idle clips and Spellbook Soul VFX.
- R3 romantic sanctuary, continuous R2 mesh cliff, arch, waterfall and clouds.
- R4A native grass and 291 ground-cover meshes, quality-scaled wind.
- R4B refined Pearl/Blood/Frost moons, 60/20/20 nightly selection, +50% candidate,
  existing 1500-second cycle and one EnvironmentView owner.
- Authorized Restricted group willow template, replacing only the temporary
  ancient-tree proxy in this local preview; nine bones and quality-scaled wind.

The preview uses generated adapters under `build/`. `src/` and
`default.project.json` are byte-for-byte logically unchanged from the base
(line endings normalized for comparison). No new remotes, asset uploads,
permissions, economy or save migration. QA uses memory-only profiles, with
explicit owner **11924805007**. F5 starts a new test session; it does not retain
production progress. Never publish this QA place.

## Rebuild and open

```powershell
npm run tools
npm test
node scripts/build-current-game.mjs --owner-user-id=11924805007
```

Artifact: `build/PotionTycoon-Current-Game-QA.rbxlx`.
Delivery convenience copy: `G:\Codex\PotionTycoon-Latest.rbxlx`.
Receipt: `build/current-game-build.json` (exact source HEAD, hashes and owner).
Artifact SHA-256:
`d6d95c3975e87d45500ea22853df7ad53b8eccdb56bffbd9c4c0291d29b7e07f`.
Open locally and use F5. No owner command, Rojo connection or manual import is
needed. The normal game camera and normal game keyboard bindings remain active.

## Verification

- Pinned tools: Luau 0.745 and Rojo 7.7.1 verified.
- Full portable suite: 1396 Luau + 24 Node = **1420 passed**, 296 Luau sources
  compiled; original and QA builds passed. Existing C01 analyzer warnings remain.
- Combined generated adapters compile. Build asserts production-source
  preservation, safe settings, actual gameplay bootstraps and absence of the
  standalone art review camera. Repeated Rojo output is byte-identical.
- Ordinary native F5: owner profile loaded with 1000 Gold / 0 Essence,
  all 13 station anchors verified; schema 8, memory mode, no live purchases/trade.
- Full-screen starter choice selected and confirmed Green Slime; tutorial advanced.
- Normal-physics Humanoid MoveTo reached the book, health 100, distance 7.91 studs.
  A preceding diagnostic used an incorrect absolute goal; the corrected check
  resolves the actual book anchor and is the reported successful route.
- Native book prompt click changed Essence from 0 to exactly 5 and advanced the
  tutorial to buying the first bed. Spellbook local sigils/runes render.
- Tab opens Inventory/Market without Roblox PlayerList covering it.
- Full/Reduced/Minimal: exactly one weather/lighting owner, nine willow bones,
  moon images ready, four fixed pixel writes; waterfall rates 18/7/0 and beams
  3/1/1. All 12 environment image statuses became success. Reduce Motion resets
  willow bones to identity. Production camera remains player controlled.
- First combined run exposed a sibling-script replication race. Fixed by waiting
  for the existing game scripts/controller; repeat F5 passed without that error.

## Remaining checks

This is a startup and interaction smoke check, not a repeated complete factory,
NPC contract, rejoin durability, mobile, multiplayer or controlled performance
acceptance. Owner art approval remains open. Native moon/cliff Editable assets
are still a Studio-only delivery path. The inherited raw willow foliage Image
HTTP 502 check remains unresolved; its processed SurfaceAppearance rendered in
this Play. Native avatar accessory warnings are unrelated to the island asset.
No new GitHub CI was launched for this local convenience build.

The previous open Willow scene was preserved as
`build/Willow-LocalStudioBackup-20261117.rbxl` before reopening the combined game
in the same Studio window.
