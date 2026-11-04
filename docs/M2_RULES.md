# M2 implementation contract

Recorded before implementation; provisional economy, no Robux or trading enabled.

- Summoning costs 50 earned Essence per familiar, with 1 or 5 summons per intent.
  One integer-weight pool has total 100000: Sprout Owl 24000, Green Slime 23000,
  Magic Cat 23000; Bloom Owl 9000, Golden Slime 8000, Moon Cat 8000; Ancient Owl,
  Prism Slime and Void Cat 1650 each; Aether Sprite 50. Tier totals are exactly
  Common 70%, Rare 25%, Legendary 4.95%, Secret 0.05%. Every final species and
  each independent uniform integer stat range is disclosed before spending.
- All stat ranges, weights, fixed offers, costs and evolution targets live in
  Config. Each integer in a stat's inclusive range is equiprobable, independently
  of the other two stats. A final species/stat tuple has probability
  `speciesWeight / poolTotal / (Fcount * Hcount * Bcount)`. No luck modifiers,
  pity, rerolls or undisclosed conditional outcomes are enabled.
- Three evolution families retain their roles: Sprout → Bloom → Ancient Owl;
  Green → Golden → Prism Slime; Magic → Moon → Void Cat. Five same-species,
  same-stage, unlocked, unassigned instances make one next-form familiar.
  For each stat the output is `clamp(max(parent stat) + 5, target min, target max)`.
  Preview is exact; success is 100%. A legacy parent exceeding a target's maximum
  is refused instead of weakening that parent. Legendary and Secret are terminal.
- Old starters and fixed Gold hires remain. The direct shop additionally offers
  Rare specialists for 700/700/1000 Gold, Legendary specialists for
  3500/3500/5000 Gold, and Aether Sprite for 12000 Essence. Every offer specifies
  exact stats. No randomness or policy lookup is needed for a fixed purchase.
- V3 adds locked/rarity/evolution/provenance, conservative paid-currency ancestry
  flags and a monotonic collection operation receipt. V1/V2 IDs, original stats,
  assignments, paidOrigin, paid jobs, cargo and production RNG are preserved.
  Existing pets receive the honest `Legacy` rarity and `legacy` provenance, not
  invented historical rolls. New pets have canonical species rarity/stage.
- A separate server RNG supplies summon draws; it never reads/writes production
  `rngState`. The sampled candidate and its receipt are immutable across storage
  callback retries. Collection mutations commit under the existing profile gate,
  lease and revision. No unconfirmed candidate reaches clients. An ambiguous
  failed commit freezes the session; rejoin discovers the durable receipt/state.
- A monotonic request ID and canonical intent fingerprint make the latest retry
  idempotent and reject older IDs or a conflicting payload. Only one collection
  operation per player can run; normal simulation/actions pause during its commit.
  Fuse also requires a server preview token and explicit confirmation of its IDs.
- PolicyService is checked server-side for every random action, using a bounded
  cached result (60 seconds). Only an explicit unrestricted, unexpired result
  allows a spin; error/missing fields/expiry fail closed. Factory, deterministic
  Fuse and fixed shops remain available. The future trading permission is retained
  for display/integration only; there is no trading endpoint.
- Paid-derived ancestry is an OR through Fuse. Future paid-currency provenance
  flags are conservative/sticky; no M2 endpoint grants paid currency or clears
  them. Existing `paidOrigin` is preserved. Essence is treated as potentially
  indirectly paid for access checks already, before M6 can sell it.

Official policy checked 2026-11-04: [paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items)
and [PolicyService](https://create.roblox.com/docs/reference/engine/classes/PolicyService/GetPolicyInfoForPlayerAsync).
The first source requires final-outcome disclosure for directly/indirectly paid
random items and describes guaranteed alternatives. Our M2 restriction for all
Essence spins is intentionally conservative preparation for the planned paid
Essence; M2 itself has no Robux purchase handler. Live PolicyService/DataStore,
Studio, phone and multiplayer acceptance remain separate BLOCKED gates.

## Exact configured outcomes

All ranges are inclusive uniform integers; Farming, Hauling and Brewing are
independent conditional on species. Fixed-shop stats below are F/H/B, not ranges.
Stage 0/1/2 follows the three evolution families; Aether Sprite is terminal stage 0.

| Species (ID) | Rarity | Final chance | Farming | Hauling | Brewing | Fixed F/H/B | Fixed price |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| Sprout owl (`farmer`) | Common | 24% | 8–16 | 1–3 | 1–3 | 12/2/2 | 120 Gold |
| Green slime (`slime`) | Common | 23% | 1–3 | 7–13 | 1–2 | 2/10/1 | 120 Gold |
| Magic cat (`brewer`) | Common | 23% | 2–4 | 1–3 | 18–28 | 3/2/25 | 180 Gold |
| Bloom owl (`bloom_owl`) | Rare | 9% | 14–26 | 3–8 | 3–8 | 22/5/5 | 700 Gold |
| Golden slime (`golden_slime`) | Rare | 8% | 3–8 | 14–26 | 2–7 | 5/22/4 | 700 Gold |
| Moon cat (`moon_cat`) | Rare | 8% | 4–9 | 3–8 | 28–40 | 6/5/36 | 1000 Gold |
| Ancient owl (`ancient_owl`) | Legendary | 1.65% | 28–60 | 8–16 | 8–16 | 50/12/12 | 3500 Gold |
| Prism slime (`prism_slime`) | Legendary | 1.65% | 8–16 | 28–60 | 7–14 | 12/50/10 | 3500 Gold |
| Void cat (`void_cat`) | Legendary | 1.65% | 9–18 | 8–16 | 42–75 | 14/12/65 | 5000 Gold |
| Aether sprite (`aether_sprite`) | Secret | 0.05% | 80–100 | 80–100 | 80–100 | 90/90/90 | 12000 Essence |

For example, each Sprout owl Farming value has conditional probability 1/9;
each Hauling/Brewing value 1/3. Each exact owl triple has probability
`24000 / 100000 / 81`, or about 0.2962962963%. UI shows the exact fractions and
rounded percentages for every species/stat range and exact triple. Five summons
are five independent outcomes at 250 Essence, with no discount or bonus odds.

Five fixed Green Slimes cost 600 Gold and evolve to **7/15/6** Golden Slime.
The 700-Gold direct Golden Slime is **5/22/4**: stronger hauling, weaker secondary
stats. High-roll parents retain benefits through `max + 5` (up to target caps).
Station caps still apply: the level-1 hauling station uses at most 10 Hauling,
so upgrade it to use the evolved worker's full main stat. All slime forms retain
the existing deployed production byproduct behavior. These costs and tradeoffs
need live playtesting, especially late fixed offers and long-term Essence sinks.

## Policy matrix

| Server result | Essence random summon | Fixed shop / Gold hire | Factory / Fuse | Paid-derived inventory |
| --- | --- | --- | --- | --- |
| Explicit unrestricted, cache valid | Allowed if other checks pass | Allowed | Allowed | Preserved |
| Restricted | Denied, no charge/draw | Allowed | Allowed | Preserved through evolution |
| Missing, malformed, error, timeout or expired | Denied until confirmed refresh | Allowed | Allowed | Never cleared |

No UI field can override the server result. The standard UI replaces unavailable
random actions with the guaranteed shop. Lookup failures are cached for at most
60 seconds; refresh after expiry retries the bounded lookup. Trading is absent
even if `IsPaidItemTradingAllowed` is true. Future Robux currency receipts must
atomically set the sticky currency ancestry flag before any spend and separately
pass paid-purchase QA; the flag is preparation, not a payment implementation.

## Portable F2P traces

`tests/M2Scenario.luau` starts with the unchanged zero-resource M1 scenario:
manual Healing → pipes/passive crystal → automatic Healing → delivered NPC order.
It then buys five fixed slimes with earned Gold, explicitly fuses them, deploys the
result, buys the mine/distillery/cauldron/warehouse upgrades and fixed role workers,
manually discovers Fire Extract and Rage, and enables automatic Rage.
No currency/material/pet injections or familiar RNG calls are permitted.

| Scenario | First evolved worker | First Rage | Automatic Rage sold in next 1200 s | Ending Gold / Essence |
| --- | ---: | ---: | ---: | ---: |
| Restricted policy | 796 s | 1347 s | 7 | 566 / 1900 |
| Lookup unavailable | 796 s | 1347 s | 7 | 566 / 1900 |

The trace validates the complete profile after every action and wait. Another
600 seconds produces identical complete online/offline profiles with the evolved
worker. These are reproducible simulation timings with user ID -1, not measured
human playtime: walking, network, UI and real save latency are excluded. Existing
production slime/double-output RNG remains; no gacha luck is needed to acquire
workers or evolve. Five guaranteed base hires always provide evolution inputs.
Free clicks/harvest/load/manual Healing remain recovery paths after overspending;
no compulsory random familiar or paid rescue is introduced.
