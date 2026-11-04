# Design decisions — agreed baseline

## Product

Mobile-first Roblox tycoon/crafting/clicking/trading. Stylized low-poly magical forest, with restrained neon accents. Each player owns a separate fixed-slot factory. Target topology: 6–8 owners per server, visitors welcome, no shared factory ownership in the first release.

Three layout zones: agriculture to the left of the crystal; processing in the centre/right; storage and summoning in the rear. The automated coal mine is a resource annex to the agricultural side. Station coordinates are relative to a plot origin. Visual waypoints are presentation, not proof of economic delivery.

## Production and workers

- Essence: manual crystal clicks, a worker specifically assigned to the crystal, and crystal upgrades. Other workers do not generate Essence merely by existing.
- Mandrake, mushrooms and Fire Berries: farm workplaces. Coal: automated mining. Deployed slimes additionally generate byproduct slime on saved timed production rolls.
- Three familiar stats: Farming, Hauling, Brewing. Crystal gathering and mining use Farming in M0, without adding a fourth stat.
- Every familiar instance keeps its original stats. Effective skill is clamped by station tier; strong gifted pets are usable at capped effectiveness, not destroyed or forcibly removed.
- One familiar can occupy only one workplace. Cosmetic followers do not create a second production contribution.
- Recipes can require intermediates produced by another station. Improving a station retains older compatible recipes.
- First successful manual production discovers a recipe. A worker and discovery are required for auto-brewing.
- Pipes handle energy/liquids; haulers remain important for solids. No mandatory manual-only coal or wear mechanic.
- Raw/intermediate supplies and contract output have finite capacity. Excess raw stock can be intentionally discarded with confirmation. Ordinary finished potions export immediately and never fill the warehouse.
- Full offline simulation of the configured chain, up to two hours. No simulated clicking. Online/offline share rates and inventories.

## Orders

Three eligible offers on the board, one active contract. M3 replaces lower-priority offers with discovered, reachable technology; the tutorial pins its first Healing contract. Production matching an active contract reserves only the required quantity across all compatible slots. Extra production exports normally. The player claims a completed contract once. On expiry, already reserved production is exported at normal price rather than silently destroyed. No paid rescue is required.

## Construction and technology — M3

Four functional phases are separate from equipment tiers and Rebirth epochs.
[M3_RULES.md](M3_RULES.md) records the graph, fixed slot coordinates/waypoints,
prices, recipes and three measured portable routes. Original six IDs and early
upgrades remain available; seven additional slots unlock by phase. All slots are
individual purchases. Geometry only reflects confirmed server state.

The final berry → essence → serum → Ascension route has three manufacturing steps,
with a solid paste branch. Two cauldrons can produce simultaneously. Per-material
saved turns share scarce solid/liquid inputs; phase-three intake targets prevent
one idle material from taking every warehouse slot. Existing stock and cargo are
conserved. Manual load/discard and one-turn supply priority remain available.

Phase 3 grants one free unique resonant cauldron with ownership, provenance, lock
and a capped bonus captured at batch start. Changing equipment requires an idle
slot. M4 can transfer the unequipped item without repeating the milestone grant.
Phase 4 plus an actual final batch in the current cycle displays completion.
Only a separate confirmed Rebirth transaction resets production or grants a shard.

## Collection and policy — M2

M2 implements per-instance uniform integer stat rolls, exact final-species weights, a fixed-stat shop, and deterministic five-parent evolution. [M2_RULES.md](M2_RULES.md) records the configuration, probability law, prices, inheritance formula, policy matrix and measured portable progression. These are provisional balance values. There are no Robux purchases, luck modifiers or paid rerolls.

Starter workers are granted once. Additional guaranteed workers can be earned without paid randomness. The restricted-user experience must remain a complete progression path. Paid randomness restrictions and paid-item trading permissions must be evaluated for each participant, with item provenance retained through fusion/transfers. Policy lookup failure must not enable a restricted feature.

M4 implements same-server direct familiar/rare-cauldron exchange behind a disabled
server release switch. No Gold/Essence/raw-ingredient transfer or player Robux
marketplace is enabled. Strong pets remain constrained by workplace caps. Both
users need fresh explicit IsPaidItemTradingAllowed=true even for known-free items;
the stricter all-item matrix is in [M4_TRADING.md](M4_TRADING.md). Protected starters
cannot be gifted. Unknown Legacy/historical Fuse ancestry cannot be laundered by
fusion: new outputs propagate known-origin proof with AND, paid ancestry with OR.
Existing historical pets remain unchanged and usable in production. A durable
whole-profile reservation temporarily freezes actions until settlement; neither
ordinary saves nor a timeout can undo a committed transfer. Public trading remains
off until real backend, policy, mobile and multiplayer acceptance.

## Rebirth, epochs and daily progression — M5

[M5_REBIRTH.md](M5_REBIRTH.md) is the reset/preserve contract recorded before
migration/commands. A completed current-cycle final batch enables a separate
two-step Rebirth confirmation. One durable profile transaction resets the factory,
increments the cycle, grants exactly one Time Shard and stores its receipt.
All pets, rare cauldrons, recipe archive, rights and operation histories survive;
assignments/equipment clear. Any active trade negotiation or durable reservation
blocks reset. Phase-three's rare-cauldron milestone remains one-time.

Count modulo three selects Classic, Steampunk or Void, each with four construction
phases and the same 13 slots. Distinct recipe dependencies and bounded cost/sale/
duration factors change the production routes. Counts >=3 repeat the themes with
no exponential growth. Nine zero-admin traces cover manual, early automation and
mistaken-purchase/restricted routes. Model time is not measured retention.

Earned shards buy capped industry/Essence perks, a title or one of three exact
fixed-stat familiars. M5 uses the explicitly permitted direct-choice-first altar;
there is no random shard summon or paid-shard purchase. M2 gacha keeps its policy
and disclosure gates. Positive potentially paid Gold/Essence blocks Rebirth until
M6 defines carry/refund/disclosure; permanent rights and consumed receipts persist.

Three daily goals use real manual Essence, manual online potion completions and
NPC claims, with UTC day rotation and explicit durable rewards. Offline work and
automatic batches do not progress those goals. The explicit seven-day calendar
resets on a missed day and starts again after day seven. Its first special reward
is a title plus a fixed Moon Cat entitlement; later series give fixed Gold.
Full collection capacity delays pet delivery without losing or repeating the right.

## M1 routing and onboarding rules

These rules are recorded before implementation. Values are provisional and must
be measured by the portable early-game scenarios, not treated as retention data.

- `essence` is the crystal reservoir. Every machine has a 24-unit Essence tank.
  Manual **Load** transfers at most one recipe's missing Essence and ingredients
  from storage; brewing consumes only the tank and machine inputs. Loading is
  free, always available and does not require a familiar or purchased pipe.
- Pipes cost **28 Gold** (two ordinary Healing sales), have no discovery/tier
  prerequisite, and feed built machines at up to 2 Essence per machine per second,
  rotating first priority. They also transfer liquid intermediates through the
  separate intermediate store. Automatic haulers handle solids and quest crates;
  manual collection/loading of liquids remains available before pipes.
- The 140-Gold crystal upgrade enables passive Essence. The three fixed starters
  can staff garden, logistics and cauldron. All spending detours can recover via
  free clicking, harvesting, refilling and manual brewing; no tutorial reward,
  hire or random drop is necessary to unlock Healing income.
- Matching potion output enters a separate 6-crate machine queue. The quota counts
  queued + travelling + delivered crates. A full queue pauses batch completion
  without rerolling or losing output. Other potions and quota excess export at once,
  regardless of raw warehouse capacity. A single hauler rotates all solid and crate
  routes; delivery moves only what fits. Unassignment freezes the saved cargo.
- At expiry all completed matching crates, including paused cargo, export exactly
  once at ordinary value. An unfinished batch is still a batch and completes as
  ordinary output. Only explicit claim of fully delivered stock gives the order
  payment. Changing recipe cannot redirect a crate already in transit.
- Tutorial milestones are server-observed, saved facts, not client acknowledgments
  or grants. Out-of-order actions remain credited. Hints select the next missing
  milestone and explain recovery (refill, recipe selection, assignment, disposal).
  First manual Healing, first sale, pipes, passive crystal, first automatic Healing
  and a claimed NPC order are all required. The M1 guide does not require M2 acquisitions.
- V1 saves migrate atomically under the existing lease to V2. Prepaid jobs, stock,
  RNG, timers and cargo keep their meaning; old fluid cargo finishes its existing
  route once. No balance reset or repeated starter grants. Existing discovered
  recipes count as prior manual learning; no unrecorded income is invented.

## Remaining prototype simplifications

- Familiar collection uses ten greybox species and three evolution families, with a fixed calendar reward. There is no general pet deletion, reroll, luck/pity modifier or monetization handler. Trading is private-QA-only until live acceptance.
- Thirteen fixed workplaces, one carrier and six processing slots; four functional phases with replaceable greybox architecture. No free placement or physical bottle simulation.
- Simple local worker spheres and greybox scenery; no art acceptance or mobile FPS claim.
- Prices, rates and probabilities are provisional configuration, not a monetization forecast.

## Primary platform references

- https://create.roblox.com/docs/production/monetization/paid-random-items
- https://create.roblox.com/docs/reference/engine/classes/PolicyService
- https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing
- https://create.roblox.com/docs/cloud-services/memory-stores
- https://create.roblox.com/docs/creator-rewards

Creator Rewards are conditional platform rewards, not payment proportional to overnight AFK time. No income or retention claims have been measured for this prototype.
