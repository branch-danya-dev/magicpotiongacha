# C01 first-session balance — NOT APPROVED

Owner chose variant A: a new profile starts with the temple, the Essence crystal, one familiar choice, and a one-time Gold grant. The garden and cauldron are bought and installed on their existing fixed spots. Free placement stays in C02.

`Config.firstSession.ownerApproved` stays **false**. These numbers are a proposal. The server does not grant Gold, sell the garden, the cauldron, or seeds, exchange Essence, or sell automation until the owner turns that flag on.

Historical profiles, and profiles already saved by the previous C01 build with a built garden or cauldron, keep those stations, pets, balances, timers, quests, and receipts. Rebirth still restores the historical station levels from `initialLevel`. The hauler stays at its existing starter level; it does not produce ingredients. Its configured first upgrade price is 0, so making it a paid starter station needs a separate decision.

| Parameter | Proposal | Role |
| --- | ---: | --- |
| Starter Gold | 40, once | Pays for the garden, the cauldron, and two seeds, with 4 Gold left. |
| First garden | 16 | Installed at the existing `legacy:garden` placement. A second purchase does not charge again. |
| First cauldron | 16 | Installed at the existing cauldron placement. Same replay rule. |
| Mandrake seed | 2 Gold, 1 crop, 8 seconds | Two seeds make one Healing. |
| Automation, each | 28 | Replant, harvest, supply, brew, and seed restock. Each flag is bought once. |
| Restock target | 2 seeds | Buys one seed per second while Gold can pay and the stock is below two. |
| Essence exchange | 10 Essence → 1 Gold | Active click recovery only. Offline simulation does not exchange. |

Healing still sells for the existing 14 Gold and still needs 2 Mandrake and 3 Essence. Crystal level 1 still gives no passive Essence. Crystal level 2 still costs 140 Gold and gives 1 Essence per second. That upgrade is the existing M1 price, not a new proposal.

## First cycle and the self-sustaining floor

| Question | Proposal |
| --- | --- |
| First cycle, normal | 16 + 16 + 2×2 = 36 Gold. Two crops take 16 seconds, the brew takes 6 seconds, and three clicks supply Essence. The sale returns 14 Gold. Operating profit after the equipment is already owned is 14 − 4 = 10 Gold per potion. |
| Minimum Gold to reach that sale | 36. The proposed grant is 40. |
| Minimum to leave the loop running by itself | Equipment 32, five automation flags 140, and crystal level 2 at its existing 140. That is 312 Gold, plus 4 Gold of seed stock. Sales after the first potion fund it: each potion nets 10 Gold once seeds are the only repeating cost. |
| Bad purchases | Seeds already bought stay in the inventory. A second station purchase does not charge. Spending the whole grant on seeds leaves the garden and cauldron unbought; the crops cannot be grown until the garden is bought, and the seeds are not deleted. |
| Zero Gold | Ten clicked Essence convert to 1 Gold. Nine Essence convert to nothing and are not consumed. Rebuilding a 16 Gold station from zero takes 160 clicks. One Healing returns 14 Gold for 3 Essence plus two seeds, so the exchange is much weaker and cannot replace the potion. |
| Empty seed stock | Restock spends earned Gold on real seeds. With no Gold it waits. A full raw store leaves the mature plant in the bed. Neither case deletes Gold, seeds, or a crop, and neither mints a crop. |

The manual garden harvest and an assigned farmer no longer create Mandrake on a new profile. A historical profile with `starter.legacyGrant` keeps the old harvest.

## Studio check

Not run here. In a memory Studio session, a new user should see an empty familiar list, a crystal, and an unbuilt garden and cauldron. Buying them, seeds, and the Essence exchange answers that the price is not approved. A profile that already owns those stations keeps them. Historical free harvest remains only for the old three-familiar grant.
