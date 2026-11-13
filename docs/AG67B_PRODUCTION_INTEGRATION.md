# AG-67B — Soul Absorption production integration

Base: Draft PR #36, `feat/ag67-soul-absorption-prototype` at
`4a158b96e2b679605e89e2b36fe3425208fea315` (rechecked unchanged, draft and unmerged).
Branch: `feat/ag67b-soul-absorption-integration`.
Exact delivery HEAD and Windows/Ubuntu CI are recorded in the stacked Draft PR.

**IMPLEMENTED/CODE; scoped STUDIO VERIFIED; OWNER ACCEPTED pending; PUBLISHED NO.**
The owner's explicit AG-67B request authorizes this integration despite the older
Stage A report's gate. It does not approve the new art or a production release.

## Ordinary build and rollback

Run `npm run tools`, then `npm test`. Open **`build/PotionTycoon.rbxlx`** and press
Play. This is the standard Rojo project: no QA project, manual texture directory,
Command Bar activation or local Studio installation is needed for these VFX.
Studio automatically preloads three group-owned Image IDs using typed ImageLabel
probes and switches to Soul Absorption after all succeed. The previous VFX remain
active while loading and on failure or the 15-second timeout. Late results cannot
revive a stopped or timed-out owner.

`SpellbookSoulPolicy.releaseEnabled = false`: published clients retain the previous
implementation without fetching the new textures. The legacy module is preserved
byte-for-byte from the base. Stop-before-start switching restores the source model
and disposes the old owner before creating its replacement. In Studio only, the
`PlayerScripts.PotionTycoon.SpellbookEffects.Inspect` BindableFunction supports
`mode/original`, `mode/soul`, quality, motion and simulated fallback diagnostics.
It is a local QA bridge, not a new remote or player-facing UI.

All inherited server code, economy, saved data, remotes, receipts, imported model,
global lighting, UI and default project mapping are preserved by the new guard.
The source `qa/ag67/` prototype remains reproducible and is not required at runtime.

## Art and bounds

Six staggered sigil sectors, independently phased inner lines, tangent/radial
sparks, rising motes and a low-opacity volume replace the thin static prototype
ring. Camera-facing rune glyphs retain independent orbit/roll/bob without turning
edge-on. Layered curved soul ribbons track the live R6/R15 chest and contract into
it. Folded paper uses eight baked burn frames with strictly decreasing opaque
silhouette area, separate emissive edges and a bounded ember burst.

| Mode | Active books / tracked | Flying pages | Beams | Glyphs/book | Sigil burst | Lights | Emitters | Update cap |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Full | 2 / 8 | 22 | 18 | 6 | 32 | 1 | 6 | 60 Hz |
| Reduced | 1 / 8 | 12 | 12 | 4 | 16 | 1 | 6 | 30 Hz |
| Minimal | 1 / 8 | 0 | 0 | 2 | 0 | 0 | 0 | 20 Hz |
| Reduce Motion | quality book cap / 8 | 0 | 0 | quality glyph cap | 0 | at most 1 | 0 | quality cap |

All emitters have Rate=0 and controlled Emit calls. Full has an additional 5
surge particles, 6 falling embers and 6 chest particles per batch; Reduced has
5 + 3 + 3. Idle emissions are four particles per 0.45/0.9 seconds, without
catch-up loops. No shadows, physics, touch/query participation, global lighting
changes, per-click coroutine or runtime texture replacement. One shared 2.4-second
ritual pool coalesces repeated confirmations without extending its lifetime.

Observed descendants: Full 411, Reduced 226, Minimal 19 (17 before first pulse),
Full Reduce Motion 62. The telemetry's `peakInstances` is a peak of inspection
samples, not a continuous profiler counter. Three presentation connections remain
constant. Culling distances are 100/72/32 studs, with owned book priority.

Compared with Stage A, six bounded emitters replace three; original-art decoded
RGBA increases from 3.75 MiB to **8.25 MiB** (two 1024² atlases + one 256² wisp).
This is an explicit texture-budget increase; real phone memory/GPU acceptance is
pending. Shared textures are loaded once, not per book or per click.

## Asset receipt

The three original procedural PNGs, SVG sources and generator are in
`assets/vfx/ag67b/` and `scripts/build-ag67b-art.mjs`. Their bytes and alpha/burn
coverage are checked and regenerated deterministically on both CI hosts.
No third-party or paid asset was introduced.

| Name | Group-owned Image ID |
| --- | --- |
| AG67B_SigilAtlas | 76491767385771 |
| AG67B_PageBurnAtlas | 71524045190344 |
| AG67B_SoulWisp | 79556416543344 |

The owner authorized exactly the three manifest hashes and confirmed Asset Privacy
enabled before upload to **addout studio (925845207)**. All three completed import.
Typed preload succeeded inside the existing private Experience **10776120489** /
Place **125724638469407**, and in ordinary local Play. Metadata confirmed names,
creator and IsPublicDomain=false. That field alone does not establish Restricted
permissions: independent resulting-asset permissions UI review remains open.
The frozen upload-request manifest is retained; `roblox-assets.json` is the separate
post-upload receipt. No Creator Store listing or game publishing occurred.

## Validation and native evidence

Local tools and complete suite: **1254 PASS / 0 FAIL** (1233 inherited + 21 new).
Tests cover release/quality gates, receipt batching, burn progression, directional
budgets, R6/R15 selection, bounded motion and terminal preload state. Source guards
verify preservation of every inherited source/test/asset, owner teardown ordering,
single update/receipt owner, asset hashes, deterministic art and standard project.

Ordinary full-game Play automatically entered soul/ready with eight tracked books.
Native E changed Essence 0 → 5; mouse changed 5 → 10. The native regression script
then verified one +5 receipt in every mode, rejected malformed/out-of-range
requests, 100 rapid intents (8 server acceptances, one bounded batch), pool reuse,
fallback mid-ritual, 20 owner/quality switches with stable connections, and all
eight sigil positions. Each ground plane was y=0.545, 0.13875 above its model pivot.
These are local Studio profiles, not live DataStore or multi-client results.

The paired local-only rig scripts replaced the ephemeral test character with R6
and R15, then killed the R15 and allowed normal respawn. Both generated exactly
one accepted receipt, moved at least 1.5 studs while the ritual followed the chest,
and retained bounded pools. Maximum sampled chest-target errors: R6 0.00439 studs,
R15 0.00094; after respawn 0.00051. On death the VFX folder had zero descendants,
pages, beams, lights and emitters within 0.2 seconds. Character removal checks
passed. The normal avatar returned and played another accepted ritual. No
production character model or server script was changed; stopping Play removed
all temporary diagnostic observers and test rigs.

Reproduction scripts in `qa/ag67b/` are manual local-only diagnostics, excluded
from the ordinary project. `check-play.luau` and `measure-play.luau` run in the
client Command Bar. They use the unchanged server click intent, not direct rewards.

### Measured performance

Studio 0.747.0.7471481, desktop Q21, 2113×988 viewport, same camera,
three real click requests per mode over about nine seconds; no video recording
during measurement. RenderStepped timings include the whole game/editor overhead;
update CPU covers only the instrumented presentation body, not GPU/render cost.

| Mode | FPS mean | p95 frame interval | Mean VFX update CPU | Frames |
| --- | --- | --- | --- | --- |
| Full | 174.93 | 8.81 ms | 0.645 ms | 1577 |
| Reduced | 225.46 | 5.96 ms | 0.384 ms | 2031 |
| Minimal | 236.58 | 5.51 ms | 0.099 ms | 2132 |

This is a short current-PC sample, not a comparative benchmark or mobile claim.
Maximum observed instrumented update across the mixed run: 2.154 ms, zero errors.

### Art review

Actual Studio captures are in `docs/evidence/ag67b/`: idle 10 seconds, ritual
15 seconds, wide 10 seconds, old/new sequence, desktop and landscape PNGs.
F12 records the ordinary game viewport. Video handling is limited to trimming,
encoding and removing audio; no generated, composited or retouched effects.
Landscape is Studio iPhone emulator, actual viewport 750×382, not a physical phone.
HUD remains visible. Fixed camera coordinates are documented in the QA scripts.

### Open checks and known limitations

- Owner art review remains OPEN; no final release selection.
- Real phone GPU/memory/thermal/touch testing and real 2–8-client sessions NOT RUN.
- Independent resulting Image permission UI review and access from another account
  remain open; owner-confirmed privacy and successful owner Studio loads are scoped evidence.
- Live backend/save/policy/purchases and published-experience delivery NOT RUN.
- Existing M7 local `rbxasset://m7a2b-v4/` and `m7a2c-v2/` atmosphere textures are
  missing in this Studio installation; this task does not migrate that separate pipeline.
- Existing “Magic crystal” interaction label obscures part of the book, particularly
  in landscape. UI is unchanged. Wide-camera soul contrast remains an owner art judgement.

No merge, game publishing, public access, trading or monetization activation.
