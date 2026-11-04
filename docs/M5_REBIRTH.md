# M5 rules: Rebirth, epochs and daily progression

Contract written before V6 migration or economic commands. Base: M4 Draft PR #11,
`8be6af541aa5aa2a82710db8f75044966047c22f`. Public trading stays disabled. Studio,
real DataStore/PolicyService/mobile/multiplayer acceptance remains BLOCKED.

## Reset / preserve / recompute

Rebirth is an explicit candidate transaction under the existing profile gate,
lease/revision and unknown-outcome fencing. It is not a migration or login reward.

| State | Rule |
| --- | --- |
| Gold, Essence, raw/intermediate/quest inventories | Reset to zero/empty; disclose before confirmation |
| Phase, 13 fixed slots, upgrades, warehouse, pipes | Reset to original phase-one construction; same slot IDs/coordinates |
| Machine tanks/input/output/queues/jobs, logistics cargo, active NPC order | Clear; no refund/replay of old cycle production |
| Assignments and installed cauldrons | Unassign/unequip all; never delete inventory instances |
| Pets and cauldrons | Preserve every field, ID, stats, rarity/evolution, locks, owner, paid provenance and parents |
| Item serials, M2 collection, M3 progression and M4 trade sequences/receipts | Preserve unchanged; old request IDs cannot replay a reward |
| Durable trade pending/journal/escrow | Never reset; any active negotiation or unresolved trade blocks Rebirth |
| Recipe discoveries | Preserve archive; current epoch, phase and tier independently gate production |
| Tutorial, historical telemetry, entitlements, purchase/consumption receipts | Preserve; no repeated starter grants or consumable refunds |
| Time Shards, perks, daily state, calendar rights and history | Preserve; exactly one additional shard for a newly committed Rebirth |
| Current-cycle final production flag | Reset false; archived final discovery does not complete the next cycle |
| lastSimulatedAt, manual cooldowns, slime timers, pipe/input routing turns | Reset/checkpoint at trusted server time; no old catch-up is banked |
| Production PRNG | Recompute deterministically from prior state and new cycle; never draw a Rebirth reward |
| Rebirth count/cycle ID, epoch | Increment count once; cycle ID equals count, epoch = count modulo 3 |
| One-time phase-three cauldron grant | Permanent milestone flag; no second grant after Rebirth or trading it away |

The server advances simulation to its current time inside the candidate, then
rechecks phase 4 plus an actually completed final recipe in this cycle. It checks
expectedRebirthCount, stable monotonic requestId, active Player identity/proximity,
writable lease and absence of any active trade again after waiting for the gate.
The reset, count, shard and receipt commit together. Unknown outcomes fence old
memory and require normal reconciliation; no manual regrant or speculative UI.
Exact retry of the last intent returns its saved result; old/conflicting IDs fail.

Ordinary Gold/Essence are intentionally reset. M6 currency sales are absent. If
historical currencyPaid indicates a potentially paid positive balance, Rebirth
fails closed until a separate M6 carry/refund/disclosure policy exists; it never
silently destroys such balances or recreates consumed purchases. Paid-origin
flags and receipts stay preserved even when the corresponding balance is zero.

## Epoch content and bounded economy

All epochs keep M1 manual click/harvest/Healing, guaranteed hires and shops, and
the same four construction phases. Existing recipe IDs remain stable. Additional
recipes have distinct IDs and explicit epoch/phase requirements. Old recipes stay
in the archive; another epoch's exclusive recipes cannot be manufactured there.

| Count modulo 3 | Theme | New chain / final recipe | Cost / sale / duration factors |
| --- | --- | --- | --- |
| 0 | Classic alchemy | M3 graph → Ascension | 1 / 1 / 1 |
| 1 | Steampunk | Steam Catalyst + Gear Oil → Pressure Essence → Steam Ascension | 1.10 / 1.20 / 0.95 |
| 2 | Void cyber-alchemy | Void Plasma + Antimatter → Chrono Serum → Void Ascension | 1.20 / 1.40 / 0.90 |

Counts >=3 repeat these three themes with **no additional exponential scaling**.
Prices round up; potion sale values round down. Fixed worker/shop costs are
unchanged. Every epoch retains free manual Healing income and the earned path to
automation. Phase prerequisites use that epoch's intermediate discoveries and
fixed machines. Colours/names are greybox presentation, never accounting inputs.
Time/earnings/click traces for all three strategies in each epoch are recorded
below; modeled seconds are not observed playtime or retention.

Steampunk continuously supplies Coke → Steam Catalyst and Oil Berry → Berry
Essence → solid Gear Oil (with Copper Spore) → Pressure Essence → Steam Ascension.
The final cauldron also consumes Coke/Mandrake. Void supplies Dark Carbon +
Mandrake → Void Plasma and Void Berry → Berry Essence → solid Antimatter (with
Dark Carbon) → Chrono Serum → Void Ascension. These graphs sustain within two
distilleries, one press and one centrifuge; no third distillery is assumed. The
other cauldron can keep producing Healing. Phase 4 requires the themed tonic,
which also uses the classic Spore Paste branch. All raw resource IDs stay stable;
theme labels and new exclusive intermediate/potion IDs distinguish the content.

## Earned shards, perks and special altar

Each committed Rebirth grants exactly one shard. Shards are never traded or sold
for Robux in M5. A bounded earned/spent ledger and all perk levels survive reset.

| Guaranteed purchase | Cost | Limit / effect |
| --- | --- | --- |
| Industry | 1 shard per level | 3 levels; +5% work speed per level, after ordinary stat caps |
| Essence | 1 shard per level | 3 levels; +1 Essence per manual click and +1/sec only on an upgraded passive crystal per level |
| Chrononaut title | 1 shard | Once; permanent visible title, no economic multiplier |
| Special altar direct choice | 1 shard | Choose fixed Bloom Owl (22/5/5), Golden Slime (5/22/4), or Moon Cat (6/5/36) |

M5 explicitly selects the Issue #12 **direct-choice-first** option: no random
Time Shard summon, weighted pool, odds claim or random remote is enabled. All users,
including restricted/lookup-failure users, get the same exact outcomes and prices;
capacity is checked before debit/serial allocation. Existing M2 random summons
still require their original disclosure/policy checks. New pet provenance records
the fixed shard-shop source and any future paid-shard ancestry; M4 policy remains.
Any future randomized shard altar requires separate policy review and actual
server odds disclosure before activation.

## UTC daily quests and calendar

One day is floor(trusted server epoch seconds / 86400). No client clock/date/timezone
is accepted. Stored day IDs never move backwards. Three quests rotate deterministically
by day modulo 3: manually collect Essence (30/40/50), finish manual potion batches
online (3/4/5), and claim one NPC contract. Rewards/targets are Config data. Only
actual server events count; offline catch-up and automatic brewing do not count.
The UI explicitly states this. All targets are reachable with phase-one Healing.
On day change old unclaimed quests expire; day generation + progress/claim flags
commit with the profile. Each quest is claimed explicitly once per day. Rebirth
does not clear that day's progress/claims or reassign the quests.

Calendar rewards require explicit claim and at most one claim per UTC day. A
consecutive claim advances day 1…7; skipping a UTC day restarts at day 1. Day 8
starts a new seven-day sequence. Day 1/3/5 give 30/60/90 Gold; day 2/4/6 give
25/50/75 Essence. The first completed series earns a permanent Chronicler title
and a fixed Moon Cat (6/5/36); subsequent day 7 gives 140 Gold, never another
unique reward. Titles already owned are not duplicated. Gold/Essence rewards
follow the displayed Rebirth-reset rule; claims/history remain permanent.

The day-seven familiar entitlement is persisted even if the 128-pet inventory is
full. Delivery is a separate idempotent command: it consumes that right only with
a successful pet insertion, and cannot overflow or lose it on a later day, skipped
streak, Rebirth or rejoin. UI keeps the claim visible and explains that Fuse can
free slots. No paid/random action or trade is required for daily progression.
Fixed altar purchases likewise fail without debit when capacity is unavailable.

## V6 migration, UI and evidence gates

V1–V5 conversion runs under the existing lease. It preserves all old fields,
including pending M4 reservations, and initializes empty long-term state: no
invented shards, perks, claims or completion. A current-cycle final batch must be
produced after migration to qualify; migration never triggers a Rebirth. Existing
phase >=3 or advanced cauldron serial marks the already-issued one-time milestone.
M4 recovery still precedes offline catch-up and normal gameplay. Invalid/future
records fail closed. No journal schema/decision semantics are changed.

The panel shows current/next theme, final gate, exact reward, reset/preserve list,
paid-balance block and perk effects. Review and confirm are separate taps; confirm
contains expectedRebirthCount and requestId. A confirmed server result shows the
new era, preserved collection and shard, with a Continue button that grants nothing.
Dailies, calendar entitlement and direct choices use server snapshots and existing
scroll/touch controls. Closing the panel restores the ordinary movement/camera UI.

Required portable evidence: retained 581 tests; reset/receipt/migration/conservation,
unknown writes and concurrent commands, active/persistent trade interleavings,
UTC/clock rollback/streak 1/7/8/skip, full inventory, old-cycle reward denial,
bounded coefficients, nine zero-admin progression traces and offline parity.
Exact final-SHA Windows/Ubuntu CI and requirements→tests matrix go in the Draft PR.
Studio, true persistence/policy, phone and 2–8 clients remain separately BLOCKED.

Official references rechecked 2026-11-05: [paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items)
supports a guaranteed direct-choice alternative; [DataStore best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices)
informs single-key atomic candidates, bounded ordered retries and unknown outcomes.

## Measured portable routes — 2026-11-05

`m5_acceptance.spec` runs three continuous zero-admin campaigns. Each begins with
the actual empty profile and three starters; all subsequent balances, materials,
workers and shards come from validated intents/production. After Classic and
Steampunk, an actual Rebirth spends its earned shard on one industry level. The
preserved fixed workers are reused. No familiar RNG, trade or daily/calendar
subsidy is used. The detour route buys an unnecessary early garden tier, attempts
a stale phase request, idles, unassigns/reassigns a worker and recovers full stock
by explicit disposal. Both restricted and unavailable random-policy paths use
fixed hires. All nine routes retain 12 pets and one original rare cauldron.

| Route / epoch | Phase 2 / 3 / 4 (seconds from reset) | First final batch | Full parallel setup | Final potions in next 1200 s |
| --- | --- | ---: | ---: | ---: |
| Manual / Classic | 783 / 1832 / 4848 | 6877 | 7357 | 13 |
| Manual / Steam | 783 / 1739 / 4450 | 6283 | 6298 | 15 |
| Manual / Void | 775 / 1512 / 3825 | 5459 | 5474 | 19 |
| Automation / Classic | 791 / 2459 / 7149 | 10273 | 11341 | 16 |
| Automation / Steam | 826 / 2475 / 7048 | 10101 | 10117 | 13 |
| Automation / Void | 778 / 1937 / 5320 | 7739 | 7755 | 22 |
| Detour / Classic | 2782 / 4267 / 9012 | 12173 | 13214 | 16 |
| Detour / Steam | 2787 / 4052 / 7870 | 10375 | 10391 | 14 |
| Detour / Void | 2755 / 3766 / 7167 | 9498 | 9514 | 22 |

| Route / epoch | Clicks / harvests / disposals | Total Gold earned | Total Gold spent | Closing Gold |
| --- | --- | ---: | ---: | ---: |
| Manual / Classic | 30 / 608 / 0 | 19994 | 14068 | 5926 |
| Manual / Steam | 30 / 643 / 0 | 23382 | 13957 | 9425 |
| Manual / Void | 33 / 456 / 0 | 32456 | 15226 | 17230 |
| Automation / Classic | 100 / 30 / 22 | 20993 | 14068 | 6925 |
| Automation / Steam | 113 / 25 / 0 | 22326 | 13957 | 8369 |
| Automation / Void | 96 / 22 / 0 | 35185 | 15226 | 19959 |
| Detour / Classic | 51 / 36 / 25 | 21281 | 14168 | 7113 |
| Detour / Steam | 57 / 25 / 7 | 23046 | 14067 | 8979 |
| Detour / Void | 51 / 24 / 3 | 35280 | 15346 | 19934 |

Each route reconciles Gold exactly and proves simultaneous sales from both
cauldrons. Three further actual resets wrap Void → Classic with the third capped
industry level. Each epoch's staffed factory has exact complete-profile equality
after 7200 one-second online advances versus one offline catch-up, and a repeated
catch-up awards nothing. Logs contain `M5_ECONOMY` for every phase (including its
clicks, harvests, income, spending and balance) and `M5_COMPLETE` for each route.
Three additional fresh phase-one runs earn all daily goals, claim all three and
verify that another server cannot claim them again. These are model reachability
and conservation results; navigation, latency, retention and mobile performance
are unmeasured.
