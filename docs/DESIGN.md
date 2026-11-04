# Design decisions — agreed baseline

## Product

Mobile-first Roblox tycoon/crafting/clicking/trading. Stylized low-poly magical forest, with restrained neon accents. Each player owns a separate fixed-slot factory. Target topology: 6–8 owners per server, visitors welcome, no shared factory ownership in the first release.

Three layout zones: agriculture to the left of the crystal; processing in the centre/right; storage and summoning in the rear. The automated coal mine is a resource annex to the agricultural side. Station coordinates are relative to a plot origin. Visual waypoints are presentation, not proof of economic delivery.

## Production and workers

- Essence: manual crystal clicks, a worker specifically assigned to the crystal, and crystal upgrades. Other workers do not generate Essence merely by existing.
- Mandrake and other future plants: farm workplaces. Coal: automated mining. Deployed slimes additionally generate byproduct slime on saved timed production rolls.
- Three familiar stats: Farming, Hauling, Brewing. Crystal gathering and mining use Farming in M0, without adding a fourth stat.
- Every familiar instance keeps its original stats. Effective skill is clamped by station tier; strong gifted pets are usable at capped effectiveness, not destroyed or forcibly removed.
- One familiar can occupy only one workplace. Cosmetic followers do not create a second production contribution.
- Recipes can require intermediates produced by another station. Improving a station retains older compatible recipes.
- First successful manual production discovers a recipe. A worker and discovery are required for auto-brewing.
- Pipes handle energy/liquids; haulers remain important for solids. No mandatory manual-only coal or wear mechanic.
- Raw/intermediate supplies and contract output have finite capacity. Excess raw stock can be intentionally discarded with confirmation. Ordinary finished potions export immediately and never fill the warehouse.
- Full offline simulation of the configured chain, up to two hours. No simulated clicking. Online/offline share rates and inventories.

## Orders

Three offers on the board, one active contract in M0. Production matching an active contract reserves only the required quantity. Extra production exports normally. The player claims a completed contract once. On expiry, already reserved production is exported at normal price rather than silently destroyed. Later dynamic contracts must be feasible using unlocked recipes and must not require a paid rescue.

## Collection, policy and trading — later milestones

Gacha familiars will have per-instance stat variation. Exact distributions, stat inheritance/Fuse arithmetic and economy pacing are balance work, not implied by illustrative numbers. Guaranteed shop alternatives must have a fully specified outcome, including stats; fixing only a species while selling hidden random stats is not the intended alternative.

Starter workers are granted once. Additional guaranteed workers can be earned without paid randomness. The restricted-user experience must remain a complete progression path. Paid randomness restrictions and paid-item trading permissions must be evaluated for each participant, with item provenance retained through fusion/transfers. Policy lookup failure must not enable a restricted feature.

Initial trading scope: same-server direct familiar/rare-cauldron exchange. No Gold/Essence/raw-ingredient transfer, no player Robux marketplace in this milestone. Strong pets remain constrained by workplace caps. A public auction/plaza is later work, not an assumed feature of Developer Products.

## Rebirth — later milestone

Four functional construction stages per cycle, with later themes changing their art/content. Keep the classic/steampunk/void-theme ambition, but first validate one greybox cycle.

Reset ordinary construction/upgrades, Gold/Essence, production buffers/cargo/jobs, ingredients/intermediates, active contracts and worker assignments. Preserve familiar and rare-cauldron inventory, cosmetic ownership, permanent entitlements, receipt history, permanent rebirth bonuses and discovered recipe collection. Discovered recipes require suitable rebuilt equipment.

Purchase preservation means permanent rights and the proper state of consumables; consumed products are never awarded again on Rebirth. The treatment of unspent Robux-purchased currency must be clearly disclosed before currency packs/Rebirth are enabled. Neither system is live in M0.

## Explicit M0 simplifications

- Familiar acquisition is deterministic (starters and fixed Gold hires); no gacha/stat rerolls/Fuse/trading.
- Single Mandrake plot, one coal mine, one distillery and one potion cauldron; three equipment levels rather than four fully modeled architectural phases.
- Essence is deducted centrally when a batch starts. No per-pipe Essence buffer yet.
- Quest crates are reserved immediately; physical heavy-crate delivery will be added in the next logistics expansion. Solid ingredients and bottled intermediates already use timed hauling.
- Simple local worker spheres and greybox scenery; no art acceptance or mobile FPS claim.
- Prices, rates and probabilities are provisional configuration, not a monetization forecast.

## Primary platform references

- https://create.roblox.com/docs/production/monetization/paid-random-items
- https://create.roblox.com/docs/reference/engine/classes/PolicyService
- https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing
- https://create.roblox.com/docs/cloud-services/memory-stores
- https://create.roblox.com/docs/creator-rewards

Creator Rewards are conditional platform rewards, not payment proportional to overnight AFK time. No income or retention claims have been measured for this prototype.
