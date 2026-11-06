# C01 first-session balance — NOT APPROVED

These numbers are a recommendation for the owner. `Config.firstSession.ownerApproved` is **false**. While that flag stays false, the server does not grant starter Gold, sell seeds, or sell automation. The manual click → garden harvest → Healing → sale path does not use these numbers.

The fixed starter plot still includes the existing crystal, garden, cauldron, and logistics at their current `initialLevel`. C01 does not add a second bed price or a cauldron price on top of stations the player already has. A non-zero price for “the first bed” or “the first cauldron” is blocked until the owner decides those stations are no longer the free starter placement. Extra plots, moving, and rotation stay in C02.

| Parameter | Recommended value | Status |
| --- | ---: | --- |
| Starter Gold | 40 | Not approved. Granted once, only after `ownerApproved`, and never on a historical three-familiar profile. |
| First bed | No charge | Blocked as a price. The existing garden is the one starter bed (`legacy:garden`). |
| First cauldron | No charge | Blocked as a price. The existing cauldron is already level 1. |
| Mandrake seed | 2 Gold, yields 1 | Not approved. |
| Seed growth | 8 seconds | Matches the existing garden `growDuration`. Not a new price. |
| Automation (each of replant, harvest, supply, brew) | 28 Gold | Not approved. Same unit as pipes. Each flag is bought once. |

## What the recommendation pays for

Healing still sells for the existing 14 Gold and still needs 2 Mandrake and 3 Essence. Essence clicks stay at 1 and are not simulated offline. Crystal level 1 still produces 0 passive Essence.

| Question | Recommendation |
| --- | --- |
| Cost of the first full cycle | 0 Gold on the manual garden path (2 free harvests, 3 clicks, 6 seconds of brewing). 4 Gold if both Mandrake come from seeds. |
| Minimum starter budget | 0 Gold is enough to reach the first sale and to recover from zero Gold. 40 Gold is the suggested cushion: 4 seeds (8) plus one automation feature (28) plus 4 Gold left after one mistaken extra seed. |
| Time to the first sale | One cooldown between the two garden harvests (4 seconds) plus the 6 second brew. Clicks and loading are instant in the simulation. The earlier M1 trace, which also assigned three workers, reached the sale at about 19 seconds. |
| Time to the first useful upgrade | Crystal level 2 still costs 140 Gold. That is 10 Healing sales. The upgrade is unchanged and already approved in M1. |
| Time to stable automation | All four features cost 112 Gold, which is 8 Healing sales after the player has bought them. One bed grows one seed every 8 seconds, and Healing needs two seeds, so a stocked bed plus the 6 second brew is the repeat cycle. Autoreplant stops when the seed stock is empty. |
| Recovery from a bad purchase or zero Gold | Manual garden harvest, crystal clicks, loading, and one brew do not require Gold, seeds, or a familiar. A player who spends the whole starter grant on seeds can still finish a Healing with the free garden. |

Tests that buy seeds or automation copy `firstSession` and set `ownerApproved = true` on that copy only. They assert against those copied fields. They do not turn the live flag on.

## Studio check

These checks need Roblox Studio. They were not run in this change.

1. Sync the place with Rojo and play a new user whose DataStore key is empty. Use a Studio memory session (`UseMemoryInStudio`) or a fresh user id.
2. The plot already has the temple, crystal, garden, and cauldron. The familiar list is empty. Three buttons offer Sprout Owl, Green Slime, or Magic Cat.
3. Stand at the altar and choose one. Choose the same one again, then the other two. The roster stays at one familiar.
4. Stand at the crystal and click until Essence is 3. Stand at the garden, harvest twice, and wait out the 4 second cooldown between harvests.
5. Stand at the cauldron, load, brew Healing, and wait 6 seconds. Gold increases by 14 once. Brewing again without ingredients does not add Gold.
6. Seed purchase and the four automation buttons currently answer that the price is not approved. That is expected until `ownerApproved` is set. Do not flip it in this branch to make the buttons pass.
7. Leave and rejoin. The chosen familiar, Gold, and any planted crop remain. Offline time does not invent clicks. A damaged profile is kicked instead of replaced.
