# Task 07 / #19f — authored gameplay props

**Code/build delivery. Studio appearance and artistic acceptance remain unverified.**
The owner requested task 07 after task 06, continuing without frames, screenshots
or video. No new media or Studio session is produced. PR #17 remains Draft.
Task 08 still requires the owner's explicit final pilot **APPROVED**.

## Visible changes

The pilot's 13 production slots and four service objects now have original
compound native models. The violet crystal has cut tips, a rune plinth and
upgrade satellites. Cauldrons have tripod feet, a round vessel, rolled rim,
potion surface, side handles and a ladle. Copper stills have a boiler, swan-neck
pipe, condenser and coil bands. Gardens contain soil beds and mandrakes;
mushroom and berry beds have distinct crops. The mine has rock faces and timber
supports; logistics has a wheeled delivery cart and bottles. A framed screw press
and vial centrifuge complete the later production chain.

Service models include a storage shelf/chest, roofed contract noticeboard,
offering altar and planning desk. Six existing lantern bulbs are dressed with
cages, feet and pitched caps. The two existing bazaar sample stalls receive
roofs, valances, counter legs and bottles; the original central trade anchor
receives a ledger/counter model. This is the existing small sample, not the
whole-bazaar or seven-farm expansion reserved for task 08.

The original broad phase frames/canopies are hidden on the pilot. An open-front
pavilion occupies its unused rear strip from phase 2. Phase 3 adds masonry and
phase 4 adds copper conduits and cyan inlays. The pavilion has no enclosing
front wall or collision. Materials use a consistent wood, muted sage, iron,
copper, parchment and stone palette. No external meshes/textures, imports,
uploads, asset IDs, purchases or provider jobs were used.

## Construction and gameplay contract

- An unbuilt station shows two low survey pegs and a small plan. Purchased
  equipment appears only from its actual committed station level. Tier 2/3 add
  a band/seal, and vessel colors distinguish tier and equipped resonant/spectral
  cauldrons. The free warehouse is visible at level zero and remains visible at
  every capacity upgrade.
- Production inlays reflect existing server statuses. The existing context card
  retains the textual reason for stopped production; the art introduces no new
  source of production, rewards or authority.
- Available purchases keep the existing owner/proximity/affordability-gated
  local green ground cue. Survey pegs do not promise affordability. Context
  highlighting now follows the visible model; native prompts still target the
  original station/pad.
- World retains every anchor instance, size, CFrame, collision, waypoint,
  callback, request sequence, owner and range check. Four explicit presentation
  seams create/project/reset inert models. The existing M6 World hash check
  removes only those lines and still verifies the rest of the file exactly.
- Original pilot blocks/pads/sign/phase frames are made transparent. Their
  existing interaction/collision geometry remains; no new obstacle is added.
  Authored parts are anchored, noncolliding, nontouching and nonqueryable.
- One PropArt projection reads the committed profile after World updates, with
  no profile writes. Models are pooled once and updates only write changed
  appearance. Rebirth, unequip, release and a new tenant remove stale tiers,
  equipment tint and pavilion phases. Other seven plots retain their current
  presentation and mechanics.

## Budgets and quality

The complete preallocated prop pool is **414 BaseParts / 63,896 triangle
charges**, including invisible future upgrades and pavilion pieces. The new
explicit prop caps are 560 / 160,000. Combined with task-05 nature, the pilot
composition is **1,167 parts / 324,861 triangle charges**. The combined cap is
explicitly increased from the old nature-only 850/300,000 to **1,320/465,000**;
the original nature cap and its tests remain unchanged. Hidden original anchor
and gameplay objects, terrain, UI and client weather pools are separate, as in
the inherited accounting. Hiding a part does not remove its Instance cost.

Charges use the same planning estimates as task 05: 1,024 per Sphere mesh, 192
per cylinder, 12 per box/wedge. Roblox chooses actual native tessellation; these
are not GPU measurements. The pool is static at all quality tiers so functional
station silhouettes are never culled. Existing nature LOD and Full/Reduced/
Minimal/Reduce Motion remain unchanged. There are **no new textures, emitters,
lights, frame callbacks or animated parts**. The existing single atmosphere
owner controls the original lantern lights through their retained anchors.
The inherited gameplay spectral-cauldron light is also unchanged.

## Verification and handoff

`npm run tools`, `npm test`, and `node scripts/build-local-preview.mjs` produce
the ordinary complete game. The suite contains **995 cases: all 979 inherited
plus 16 new**. Compile coverage is **128 Luau files**. The added cases cover:

- Deterministic recipes for every slot, native shape validity and rotated bounds.
- All purchase-pad clearances, ground/label bounds and cauldron surface overlap.
- Initial/unbuilt/bought/max-tier and free-warehouse appearance.
- Actual build failure, successful purchase and replay; all three paid tiers.
- Real phase advancement and Rebirth, release/new-tenant projection, no mutation
  of economy/inventory/jobs/configuration, equipment tint and working/waiting.
- Rear pavilion/market approach clearance and the full preallocated budget.

Native adapter scripts are compiled but are not executed by portable tests.
The existing isolated QA project now explicitly includes the needed landscape,
fence, forest and prop modules; its previously incomplete module mapping is
fixed. No QA/camera helper is included in the normal Play build, and no new
claim of passing a live Studio audit is made. Historical evidence/assets and
all 70 protected M6 files remain unchanged.

The parent workspace handoff folder is `outputs/M7-19f-review`. Its manifest pins
the exact source commit, every serialized runtime script, place SHA-256 and
Windows/Ubuntu CI. The local atmosphere/polish/fantasy packs from task 06 remain
necessary for Studio on another computer or after a Studio version update.
Art is enabled only in Studio, progress uses memory and trading/monetization
remain disabled. No merge or game publication.

## Remaining limits

- Ordinary Play appearance, recognizability of the assembled native forms,
  visible-ground contact, original invisible collider fit, camera occlusion,
  Highlight behavior and actual engine time remain unverified in Studio.
- Physical smartphones, experience asset permissions and multiplayer load stay
  **BLOCKED**. The higher Instance budget needs actual device measurement.
- Familiar worker spheres and moving delivery crates retain their existing
  cosmetic rendering; they were not part of these station/building recipes.
- The pavilion is an open workshop facade, not a furnished enterable building.
  Sound, new character/production animations and island-wide architecture are
  not introduced by this patch.
- This code/build completion does not certify the artistic criterion that the
  pilot contains no visually perceived placeholders. Final pilot **APPROVED**
  is still required before task 08.
