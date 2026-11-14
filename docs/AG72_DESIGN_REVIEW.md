# AG-72 — Phase A: starter familiar cards

**DESIGN CANDIDATE / OWNER REVIEW REQUIRED / PHASE B NOT STARTED / NOT PUBLISHED.**

Issue #46, stacked on Draft PR #45 at
`8dc804ab33e3f9d052dc4d15a97d90b3cd46a02b` (Windows + Ubuntu run
43607496544 PASS). Branch: `feat/ag72-starter-card-concept`.
Integration ancestor: `integration/ag00-base` at `7d6d478`.
The final source SHA and exact-head CI are recorded in this branch's Draft PR.

## What is ready for art review

A static native Roblox composition over the actual pilot scene: three cards in
one row, approved AG71 portraits, softly outlined magical frames, a lifted and
brighter selected card, specialty, canonical stats, an illustrated selection
action, and a separate confirmation pose. Desktop and phone-landscape layouts
share the same art direction. No new asset or upload is required.

| Card | Farming | Hauling | Brewing | Emphasis |
| --- | ---: | ---: | ---: | --- |
| Sprout Owl | 12 | 2 | 2 | Growing |
| Green Slime | 2 | 10 | 1 | Delivery |
| Magic Cat | 3 | 2 | 25 | Brewing |

The displayed values are read from `Config.starterPets`, not maintained as a
second balance table. Portraits use the existing approved AG71 atlas
`rbxassetid://127092357608242`; they are images, not new familiar models.

**The cards are intentionally inert.** This isolated review does not implement
hover/bob/shake/particles, input navigation, pending/rejection states, starter
grant or server distance changes. Those belong to Phase B after owner approval.
Reduce Motion is active for these static compositions. The normal underlying
game still uses the inherited AG71 starter chooser and altar-range policy.

## Reproduce locally

Run `npm run tools`, `npm test`, then `node scripts/build-ag72-design.mjs`.
Open `build/AG72-DesignReview.rbxlx` in Studio and press F5. The extra local
script is injected only by this separate builder; `default.project.json`,
`src/`, `assets/` and `tests/` are unchanged from the base. The ordinary place
does not contain the AG72 layer. All publication/commerce/trading flags retain
their inherited values. The review uses Studio memory profiles.

The builder produces SHA-256
`64cdcb4ab39ef0d0ea20aa4e6b53ef545869b79d031e0eeded0ccf85b6056c60`.
The locally opened `AG72-PhaseA-Final.rbxlx` is a byte-identical convenience copy.

In the **client** command bar during Play, set one of these workspace attributes:

```lua
workspace:SetAttribute("AG72DesignPose", "cards") -- default, three cards
workspace:SetAttribute("AG72DesignSelected", "brewer") -- farmer / slime / brewer
workspace:SetAttribute("AG72DesignPose", "confirm") -- static confirmation
workspace:SetAttribute("AG72DesignPose", "scene") -- unobstructed pedestal scene
workspace:SetAttribute("AG72DesignPose", "off") -- restore inherited game view
```

They are QA attributes, not remotes or published settings. Restart Play for a
fresh review. Normal click/touch/E is blocked while the static layer owns focus;
the apparent buttons do not send requests or award a pet.

## Scene inventory and temporary focus

Before editing, ordinary AG71 Play was inspected on 2026-11-14. The visible
noise consisted of a foreground blueprint table, warehouse stall, orders board,
logistics cart, altar, future-station marker plates/stakes and yellow plot edge.
The actual `Plot_1/PilotProps` inventory was read from that running scene.

The review temporarily unparents, locally only, these presentations while
preserving every original instance and its parent:

- `warehouseModel`, `blueprintModel`, `ordersModel`, `logisticsModel`, `altarModel`;
- `mineModel`, `gardenModel`, `garden2Model`, `cauldronModel`, `cauldron2Model`,
  `centrifugeModel`, `distillery2Model`, `mushroomsModel` marker presentations;
- fallback `crystalModel`, `RearWorkshop`, `MarketSample_-12`,
  `MarketSample_12`, `BarterCounter` when present;
- `PotionTycoonWorld/TradePost` and the client `FarmAffordance` overlay.

Direct station/marker parts on all eight generated plots are locally hidden,
with collision/touch/query disabled and original values saved for restoration.
This is not a server deletion or a change to `FirstSessionReveal`. Prompts and
avatar controls are temporarily disabled during the static review. The avatar
and inherited HUD are locally hidden. OFF restores the saved parents, part
flags, alpha, GUI visibility, camera, prompt state and environment QA pose.

Kept: `SpellbookLectern`, its existing effects, plot floor, forest, hills,
flowers, rocks, paths, sky/weather owner, ridge/fence safety and all six pilot
`Lantern_*` presentations. No world/economy progression code is removed.

## Evidence and limits

Native Studio captures and their receipt are in `docs/evidence/ag72/`.
They are unmodified captures of the actual local game with a deliberately
static QA overlay, not generated gameplay images. Phone frames are the Studio
iPhone 17 Pro landscape emulator, not evidence from a physical phone.

| Review | Desktop | Phone landscape |
| --- | --- | --- |
| Three cards | [capture](evidence/ag72/cards-desktop.jpg) | [capture](evidence/ag72/cards-mobile-landscape.jpg) |
| Confirmation | [capture](evidence/ag72/confirm-desktop.jpg) | [capture](evidence/ag72/confirm-mobile-landscape.jpg) |
| Pedestal scene | [capture](evidence/ag72/scene-desktop.jpg) | [capture](evidence/ag72/scene-mobile-landscape.jpg) |

Studio 0.747.0.7471481: desktop review area 1580x1055; phone review safe area
750x324 within the 874x402 emulator. Three native OFF/on cycles restored 950
plot parts' original parents and collision/touch/query properties. This checks
one local client's generated plots, not eight connected owners. The final
preview remains open in Play on the three-card pose.

The session log also contains an asset-type error for unrelated ID `203785492`,
a `CloudsUpsampleNoHistoryFS` shader warning, and the disconnected Rojo plugin's
localhost retries. The three approved portraits rendered. These broader Studio
warnings were not fixed or certified resolved by this static design task.

The inherited CLI suite, ordinary build, repeat review build and platform CI
are reported separately in the Draft PR. This design review is not full-game
acceptance. In particular, hiding the stations does not prove the first loop
remains playable: ordinary production uses the unchanged project, and the
eventual PedestalFocus gameplay contract still requires Phase B verification.

Open gates: owner art approval; animation/interactions; safe gamepad/keyboard
navigation; pending/error UI; server `chooseStarter` range exception with
idempotence/lease/save tests; new/rejoined/legacy profiles; eight active owners;
full first loop with focus OFF; real phones and live backend. No merge or
publication has been performed.
