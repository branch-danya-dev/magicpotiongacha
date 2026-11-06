# Core Loop V2 — Product Contract (Cursor handoff)

**Status: OWNER-DIRECTED TARGET DESIGN, NOT IMPLEMENTED.** Recorded 2026-11-06.
**Current production/portable behaviour:** M0–M6 rules in DESIGN.md, M1_BALANCE.md, M2_RULES.md, M3_RULES.md, M4_TRADING.md, M5_REBIRTH.md, M6_MONETIZATION.md, and unfinished M7 Draft PR #17 remain the implemented truth until dedicated migrations are shipped.
**Implementation backlog:** [CORE_LOOP_V2_CURSOR_BACKLOG.md](CORE_LOOP_V2_CURSOR_BACKLOG.md).
**Do not touch the unfinished M7 art branch, approve 07D, activate monetization/trading, merge or publish as part of this design change.**

## Product identity and non-negotiable loop

Cozy Light Fantasy alchemy **clicker + tycoon + idle factory**, with optional depth in freely arranged land, plant cultivation, familiar collection, rare alchemy and laboratory display. The core repeatable loop remains:

1. Interact with temple crystal to gain **Essence**.
2. Supply ingredients, select known recipes and brew potions; ordinary production must become repeatable/automatic.
3. Sell ordinary output or claim a contract for **Gold**.
4. Spend Gold on machinery, upgrades, planting, temple/plot progression and familiar capabilities.
5. Higher production rate and better recipes yield higher income; optional Rebirth provides capped persistent progression.

Clicking, production/sales, upgrades and passive earnings are first-class, independently of optional decorating, rare collection or experimentation. **No required per-batch manual seed purchase, planting, carrying, brewing or sale after automation unlocks.** Active interaction should boost, not be the sole sustain mechanism. Offline catch-up stays capped at 7200 server seconds and never simulates user clicks.

## New-profile onboarding

- Each server still hosts up to eight owner-separated plots and a communal Bazaar; others may visit but may not edit/sell from another plot.
- Each new plot starts mostly empty: a **fixed central temple + Essence crystal**, a modest **one-time starter Gold** allowance (amount TBD), and a small valid build zone.
- **Exactly one** selectable initial familiar from the three original beginner identities (owl/slime/cat), once per new profile, with confirmed, idempotent choice. A full new-user free path exists irrespective of choice, including without a specialist familiar.
- First-session tutorial is short and skippable/recoverable: click crystal -> buy/place a first planting bed -> buy/plant starter seed -> harvest -> buy/place/operate basic cauldron -> brew Healing -> choose sale -> use Gold to upgrade -> learn first automatic production. The starter budget must fund the necessary starter actions, and a no-Gold/nonrandom recovery route must survive overspending.
- First sale, a useful purchase and first auto-production should be reachable during the initial session; timing targets are hypotheses, not proven retention metrics. Tutorial facts are saved based on validated server events, not UI acknowledgments.
- The world teaches only the relevant next step. Complex synthesis, Rebirth, advanced recipes and future combat are not tutorial requirements.

## Land, construction, temple

- **Replace 13 hard-coded slot positions with server-authoritative purchased station instances**. Each placed instance has stable ID, type, tier, owner, valid plot-local snapped position, snapped rotation, buildable-boundary rule and safe upgrade/move/removal semantics.
- Preserve the eight plot ownership boundaries and natural M7 hills/outer collision boundary. Plot expansion by temple level occurs **inside a preallocated safe plot envelope**, without stealing neighbours' parcels, invading shared routes or allowing placement on protected hills.
- The temple is a fixed central landmark (not freely moved). Its tiers are the visible upgrade/progression axis; **map the existing four functional phases to temple milestones** provisionally instead of adding a confusing second phase paywall. Preserve era/epoch as a separate Rebirth dimension. Exact prices, phase recipes and buildable footprint are balance TBD.
- Offer (a) quick placement/presets for tycoon players and (b) full movable/rotatable snapped placement and decoration. A preview cannot grant ownership; the server validates money, unlock, bounds, overlap, neighbour/access restrictions and capacity before atomic save. Free relocation of owned idle structures is proposed.
- Stations cannot block guaranteed playable routes, altar/crystal/temple access, player spawns, emergency recovery or necessary NPC/familiar movement.
- Pipes remain an optional *visible throughput/integration upgrade* for Essence/liquids. Default manual supply/low-level autonomous routing must remain possible before pipes. Solid logistics and fair sharing preserve the prior M1/M3 no-softlock purpose; arbitrary placement must not introduce O(all station pairs) routing.

## Crystal/clicker

- Manual crystal clicking remains an important active Essence source; passive temple/crystal tiers remain earnable with Gold. No clicking is simulated offline.
- Optional bounded crystal overcharge/charge bar may translate deliberate active interaction into a short manufacturing speed or yield boost, with server rate limits and no uncapped autoclick advantage; value, cooldown and effect TBD.
- One Essence reservoir/server-authoritative accounting source. Avoid turning Essence into an instant Robux -> random rewards path; paid features remain off until a separate policy gate.

## Seeds, fields, plant growth

- Bazaar sells defined, server-priced seed types and bulk quantities for earned Gold; list/species and final recipes are TBD. The first viable seed is always earnable, with a recoverable starting path.
- Purchased planting beds permit selection of seed and manual planting/harvesting for discovery. Growth is timer-based, server-authored and deterministic across online/offline; explicit saved progress/crop state must survive rejoin and Rebirth rules.
- After the first learning loop, **auto-replant / auto-harvest** become obtainable and can be toggled for an owned bed, consuming stocked seeds. No perpetual mandatory click-to-harvest.
- Familiar Farming increases throughput/bonuses; a missing Farming specialist may slow but never permanently halt viable progression. Resources flow into existing raw/intermediate storage and machine demand accounting with capacity/recovery rules.
- Preserve special resource/intermediate chains by translating old M3/epoch source stations into plant beds or other fixed-income producers as appropriate; do not silently delete Coal/Slime/intermediate dependencies.

## Potions, recipes, sale modes, inventory

- First valid manual brew records recipe discovery in persistent **Atlas**. Some later recipes may be learned via deterministic rewards/purchases; experimental discovery is optional and needs an explicit finite recipe/result table (no arbitrary expensive RNG).
- Each machine has a player-selectable recipe and output destination: **Auto-sell**, **Keep/Collection**, **Active contract** (contract matching and quota reservation still have precedence). Ordinary potions default to auto-sell for classic idle throughput; rare/unique output defaults to protected retention or explicit choice.
- Finished potions now exist as server-owned inventory quantities or serialized unique items instead of always disappearing into Gold. **Warehouse** stores bulk seeds/raw/intermediates/ordinary stacks; **Laboratory**, opened from inventory, displays detailed potion records and permits selecting a bottle to inspect/hold. Physical bottle mesh is instantiated on demand; no unique mesh/serialization for every common batch.
- Define fixed recipe ID, rarity, effect(s), visual variant, stack/unique-instance semantics, ownership/provenance and optional lock before implementing item exchange. Selling, consumption, switching destination, contract fulfilment and synthesis must be transactional, idempotent and capacity-aware. No silent deletion of protected rarities or duplicating sold items.
- **Atlas** records discovered recipes and optionally the first rare synthesis event; it persists across Rebirth. Laboratory viewing/holding is visual, never an economy-authoritative client operation.
- Keep active contract queue reservations, safe expiry settlement and automatic ordinary exports from M1–M3; allow orders to draw only eligible items, with exact once-only payout.

## Familiars

- Starter is **one chosen pet**, not three automatically granted. Old accounts keep existing purchased/starter pets; migrating them must not grant a new starter or delete anything.
- Proposed **three concurrently active/working familiar slots** by default. This is intentionally distinct from existing **128 owned/collection capacity**, necessary for collecting, Fuse and future trading. Owner should confirm whether 'maximum three familiars' means active slots; do NOT reduce collection to 3 silently.
- Earn additional deployable slots through temple improvements/Gold; optional paid acceleration/cosmetic extras require a fairness check before any future competitive ladder. Any paid specific familiar must preserve a viable earned equivalent for performance; monetization off in this phase.
- Add individual trainable skill XP/levels for **Farming, Alchemy(Brewing), Logistics(Hauling), Defense(reserved for future Siege)**. Production tasks train the relevant equipped familiar once per legitimate server-completed action (bounded gain; no no-op/idle reassign exploit). Rarity/base potential and trained experience are separate; preserve old stat rolls and existing Fuse ancestry.
- One familiar cannot multiply production by both working and cosmetic follow. Baseline equipment/low-tier auto-work continues without mandatory simultaneous workers for every role; familiars provide specialization and throughput.
- Eggs/guaranteed familiars through Bazaar, deterministic fixed offers and existing 100%-preview Fuse remain, with original policy and immutable receipts. No unreviewed paid randomness or new item-trading functionality.

## Orders and Bazaar

- Keep three eligible visible offers and one active contract unless a separate balance decision changes this. Extend offers to (1) potion delivery, (2) bounded familiar training/upgrades, (3) plant-growing/delivery.
- Server checks attainable level, available recipe/seed/species, real action completion, delivered quantity, deadline and reward claim. Familiar-training orders must not reward repeated fake no-op commands or require sacrificing a protected familiar without a clear explicit rule.
- Bazaar remains communal but shop effects are per-owner profile, not shared stock. Purchases and quotas have receipt-based idempotency; current M4 trade flag stays disabled.

## Endgame synthesizer, rarity, Rebirth

- After the **first actually brewed legendary potion**, allow a Gold purchase of the **Enchanted Synthesizer**. Candidate design uses two player-owned eligible potions (the lower input rarity is Mythic), clearly previewed consumption and final-result odds; exceedingly rare dual-effect fusion is possible.
- **Potion rarity ladder is separate from familiar rarity.** The position of Mythic versus Legendary, ingredient gates, synthesis results, guaranteed fallback/dust mechanics, odds and sell prices are **OPEN DESIGN/BALANCE DECISIONS**. Do not implement an invented rarity taxonomy or unbounded chance distribution.
- Only earned/non-Robux resources must enter any random synthesis while monetization review is pending. If any direct/indirect paid source is introduced later, consult Roblox Paid Random Items / PolicyService restrictions, per-outcome numerical odds and trading eligibility.
- Rebirth is opt-in, confirmed and atomic after a real themed final potion and preserves the existing three repeating epochs (Classic, Steampunk, Void), with their four technology tiers. Rebirth resets Gold, Essence, machines, ordinary ingredient/potion stock, placements and assignments; preserves familiars and trained skills, recipe Atlas, owned unique items/potions, rare cauldrons, rights and capped permanent perks/charms.
- **Academic-cycle charms** are a proposed permanent collectible loadout with capped simultaneously active slots, not infinitely stackable multiplier currency. Exact slot count/effects TBD; integrate with existing earned Time Shards only after owner approval, without inventing new currencies.
- Preserved unique display items must not bypass a fresh cycle's technology/recipe unlocks. Prior idempotent Rebirth receipt/trade blocking, offline fairness and server-only rewards remain mandatory.

## Art production and non-goals

- Unique Blender/game-ready art: temple/crystal upgrade variants; starter familiars + rigs/animations; signature cauldron, rare potion silhouettes and Enchanted Synthesizer; Atlas/Laboratory; distinctive rare herbs. Build model prototypes against Quaternius Stylized Nature MegaKit environment style.
- Reuse licensed/provenance-checked free scenery, trees/grass, barrels, fences, ordinary benches, light environmental VFX. No unreviewed Toolbox scripts or remote asset references. Avoid one 3D mesh per intermediate or common potion.
- Siege/Defense gameplay, challenges, magical combat, battle-pass competitive ladder, player-to-player potion trade, real-money potion gacha, public trading/purchases, cross-server markets and publication are **not in initial V2 migration scope**.
- Art rollout M7 07D -> UX #18 -> Phase 08 remains a separate owner-reviewed track; V2 must not falsely mark M7 art accepted.

## Open owner decisions — do not silently resolve in code

1. Is three the **active familiar cap** (recommended) or the total owned cap? Safest V2 assumes active=3, owned=128 until confirmed.
2. Starting Gold and exact affordable first garden/seed/cauldron prices; early automated progression thresholds.
3. Should temple tiers replace existing paid phase gates or complement them? Recommended: **replace as one visible progression track**.
4. Free building limits: station counts per tier/plot area, grid resolution, relocation policy and standard presets.
5. Distinct **potion** rarities and Mythic/Legendary position; when a potion becomes a unique serialized item; synthesis outcome probabilities and whether unsuccessful experiments grant a deterministic compensation.
6. Whether rare potion instances are tradeable later; paid provenance controls will be required independently.
7. Permanent charm slots/effects and preservation of non-unique potions across Rebirth (recommended ordinary stock resets).

All numeric balance and monetization plans remain provisional. Capture explicit approvals before changing saved economy/probability contracts.

## Non-regression and delivery gates

- Follow repository AGENTS.md: gameplay server authoritative, validated client intents, deterministic online/offline parity, no failed/future save overwrite, durable item/Gold/Essence conservation, idempotent receipts, rollback-safe migration of existing V1–V7 and preserved paid/provenance/trade records.
- Replace hard-coded station IDs with stable new instance identity without losing live jobs/contract reserves; preserve legacy fixed-layout profiles via safe coordinates or bounded recovery. Never mint Gold, Essence, starters or items during migration.
- Add portable Luau scenarios for starter choice, seed economics, forced zero Gold, initial manual/auto brewing, arbitrary placement collision/ownership/capacity, 1->3 active pet slots, XP, inventory sale/contract/synthesis, Rebirth and offline parity; run Windows and Ubuntu CI on exact delivery SHA.
- Actual normal Roblox Studio Play, phone touch/portrait/landscape, 2–8 owner plots, genuine DataStore failure/rejoin, performance and PolicyService are separately measured gates. Unperformed checks remain BLOCKED.
- Do not merge, publish or enable payment/trading without owner direction.
