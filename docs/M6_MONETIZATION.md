# M6 fixed collectible purchases — contract before implementation

Base: M5 Draft PR #13, `9da973f221ee162660184ae7da80953631c5b5b7`.
This document precedes changes to the schema, catalogue and purchase commands.
Public sales and trading remain disabled; no real purchase, merge or publication
is authorized by this implementation. Live Studio/backend/policy/phone/2–8-client
acceptance is BLOCKED. Final visual production is M7.

## Economy and catalogue

No Gold, Essence, Time Shards, ingredients, intermediates, potions, currency
exchange, instant phase/Rebirth or paid random outcome is sold. Existing M2 gacha
uses earned Essence and its existing policy/disclosure. All M6 outcomes are exact.

| Stable offer / acquisition | Fixed outcome | Earned Gold cost | Limits / visual |
| --- | --- | ---: | --- |
| `ghost_wolf_v1` / Developer Product or Gold | Ghost Wolf: Farming 10, Hauling 28, Brewing 8 | 1800 | Existing single assignment/carrier; tier clamps all stats. Ghost trail greybox |
| `spectral_cauldron_v1` / Developer Product or Gold | Spectral cauldron: 5% brewing speed, zero additional double-output chance | 2600 | Built compatible idle slot, ordinary recipe/input/phase gates; spectral glow |
| `aurora_theme_v1` / Game Pass or Gold | Permanent laboratory Aurora glow entitlement | 4500 | Account-bound cosmetic, no production effect |

The provisional `spectral_2026` event is a real fixed UTC interval:
2026-11-05 00:00:00 inclusive through 2026-11-19 00:00:00 exclusive (14 days).
Both seasonal offers support all three epochs. No rolling countdown, fabricated
stock or reset discount. The cosmetic is permanent catalogue content. Gold remains
usable with zero SKU IDs and disabled monetization. Items never expire or lose
effects when the window closes. Repeatable products have no per-player purchase
limit; different authentic PurchaseIds represent distinct purchases. The pass is
one account right; already-owned Gold/pass cosmetics cannot be bought in our UI.

Gold and Robux instances have identical stats, appearance and effect. Only source
and protected provenance differ. Wolf can deterministically Fuse five matching
instances into Ghost Alpha (15/34/13), carrying paid ancestry with OR and known
ancestry with AND. No seasonal pet is added to a random pool. Paid wolf stats do
not exceed workplace caps or create a second carrier. The cauldron applies its
5% speed at batch start after capped Brewing and existing epoch/perk factors;
no luck modifier or free input/output is added. Model traces and measured effect
comparisons must precede activation; model seconds are not retention or device FPS.

## Immutable mapping and origin

ServerSettings starts with `MonetizationEnabled=false`, `PurchaseQAApproved=false`,
QA place ID zero, two ProductIds zero and GamePassId zero. Native paid prompts need
all switches, a configured SKU, writable active player, current event window,
supported epoch, capacity/history space, proximity and a fresh platform price.
Recovery of known already-paid receipts and pass ownership is independent of new
sale admission. Unknown SKU returns NotProcessedYet and a bounded diagnostic.

Each offer has an immutable versioned grant definition. A persistent
`sku:<kind>:<id>` binding stores its canonical grant fingerprint before prompting
or processing payment. A changed/reused SKU cannot bind to a different outcome.
Keep all released mappings and archived grant definitions indefinitely; end an
offer by closing admission, never by reusing/deleting its SKU or changing stats.
Unexpected mapping changes require investigation, not substitution or compensation.

| Origin | Lifetime right / instance | Paid-derived | Trade / Rebirth |
| --- | --- | --- | --- |
| Earned Gold | Ordinary unique pet/cauldron or cosmetic entitlement | False, unless legacy Gold flag already true | Item follows M4; preserve through Rebirth |
| Developer Product | Receipt-specific durable delivery right then unique instance | True | Original ID/provenance retained through transfer; receipt never regrants it |
| Game Pass | Verified account-bound cosmetic entitlement | True audit proof | Never offered as inventory; preserved through Rebirth |
| Fuse | Deterministic evolved instance with parent IDs | OR of parents; known proof AND | Existing policy gates for both players |

Instance provenance stores offer/event/version and a purchase hash/ProductId when
applicable; raw PurchaseId stays in the server-only journal. Product ownership is
not inferred from current inventory. Traded/fused items leave permanent receipt
proof. All inherited currencyPaid/legacy metadata and the M5 paid-balance reset
block remain unchanged. There is no Robux-to-farmed-currency conversion.

## Receipt protocol and failure argument

There is exactly one MarketplaceService.ProcessReceipt assignment. Product prompt
finished events never grant. The pure purchase coordinator receives trusted
receipt data from that callback; no receipt or paid-grant remote exists.

Journal and profile are separate keys: this is **not a cross-key atomic write**.
There are four durable boundaries:

1. CAS immutable SKU binding (kind/id → grant fingerprint).
2. CAS `r:<first 48 hex characters of SHA256(PurchaseId)>` (50-byte key) to RECORDED, with full hash, original PurchaseId,
   PlayerId, ProductId and immutable grant fingerprint. Conflicting identities,
   hashes, product mappings or malformed records fail closed. Replay is a no-op.
3. Under the ordinary profile gate/lease/revision, recheck identity, trade and
   value-operation guards. In one profile candidate, add the purchase proof and
   either insert the fixed item or retain `queued` delivery. **This profile commit
   is the linearization point of the player's paid right.** Capacity denial never
   consumes the right; queued delivery later inserts exactly one item atomically
   with status→delivered. No ordinary balance is awarded.
4. CAS the matching receipt to APPLIED only after confirmed profile proof. Then
   return PurchaseGranted. APPLIED certifies an independently recoverable profile
   right, not necessarily a currently owned instance. A duplicate can acknowledge
   this durable proof even after trade/Fuse. Failure/unknown outcome in any step
   returns NotProcessedYet; no speculative success or rollback/regrant.

Every CAS retries a bounded number of times with the same immutable input. No
journal lock spans a profile operation and there is no reverse lock order. Profile
unknown writes fence the old live session; a new lease/load reconciles. Concurrent
servers can repeat journal CAS but only the current profile lease can add/deliver
the same hash. Receipt proof survives Rebirth, so a later callback cannot reset a
factory or recreate a transferred/fused instance. The M4 journal semantics and
ownership rules remain unchanged.

If a player is absent, trade-reserved, busy or has an invalid/future profile, step 2
can retain RECORDED but step 3 does not proceed and the callback is not acknowledged.
Roblox's unacknowledged-receipt replay (rejoin or another purchase) is the durable
discovery mechanism for these not-yet-accepted rights; there is no invented timed
platform retry guarantee. The UI does not call them delivered. Already acknowledged
queued rights live in the profile, are visible in the shop and recover on join or
an explicit delivery request after space/settlement. Event expiry and disabled new
sales never discard a known paid right. No global unbounded recovery scan is added.

For bounded profile size, retain at most 4096 receipt tombstones and 64 queued
deliveries. Never evict deduplication proof. Prompt admission stops before either
limit. Unexpected outside-game paid receipts at a saturated history remain RECORDED
and NotProcessedYet until support extends/migrates storage; no acknowledgement of
an unrecorded right. Journal records/bindings have no TTL. These limits and backend
unavailability can delay delivery; they cannot justify deletion or manual regrant.

Permanent pass processing uses server UserOwnsGamePassAsync on join, explicit
refresh and purchase-finished notification. That notification only requests a new
ownership lookup. A verified true result, immutable binding and exact Player
identity are required before a profile transaction records the cosmetic right.
Failed/false/late queries never invent or delete a confirmed entitlement. Repeated
positive ownership is a no-op. Gold acquisition grants the same visual entitlement;
it does not manufacture platform pass ownership or a tradable item.

## Schema and UI

V1–V6 → V7 adds empty monetization sequence/last receipt, purchase-proof map and
verified pass map. Historical fields, pending M4 commit and M2/M3/M5 histories
remain unchanged. Current proof/queue validation rejects mismatched IDs, grants,
states, duplicate serials and future versions; never recreate invalid saves.
Deploy coherent V7 servers in isolated QA; older writers cannot downgrade V7.
M4 recovery still precedes offline catch-up. Receipt/pass grants advance the same
server simulation before changes; no catch-up applies a new bonus retroactively.

The existing adaptive UI gets a three-card Event/Shop view with greybox preview,
exact stats/effect/caps, UTC dates, earned Gold price and separate optional native
Robux button. Platform GetProductInfoAsync is queried on the client for its actual
personalized price; no fake Robux price is configured. The server independently
checks product availability before sending a prompt instruction. Only Roblox's
native confirmation can spend Robux. Refresh failure shows unavailable. Distinct
available/ended/owned/paid queued/delivered/already processed states explain claims.
Closing the panel does not retain camera/joystick input. Final art/audio is M7.

## Measured portable results — 2026-11-05

All 696 inherited cases remain. Two generic species cases now also cover the new
forms; 112 dedicated M6 tests bring the total to **810**, with **81 Luau sources**.
The M2 Fuse sweep still covers every permanent-shop family; seasonal acquisition,
Fuse, paid OR and known-origin AND have their own M6 tests. V6 fixture assertions
now distinguish the current schema from the next unsupported version.

These are deterministic simulation seconds, not measured human completion times,
retention, real platform latency or mobile performance. No balance, material, pet,
gacha luck, trade, daily reward or payment was injected in the three F2P routes.
Each route buys both event objects during the actual 14-day test window. The
veteran first earns a complete classic factory and performs the real Rebirth.

| Route / purchase | Seconds from event start | Seconds in current cycle | Manual clicks / harvests in current cycle | Cycle income / cumulative spend / remaining Gold |
| --- | ---: | ---: | --- | --- |
| New / Wolf | 1630 | 1630 | 100 / 3 | 2028 / 1968 / 60 |
| New / cauldron (both owned) | 3790 | 3790 | 100 / 3 | 4576 / 4568 / 8 |
| Veteran after Rebirth / Wolf | 13966 | 1425 | 113 / 4 | 1998 / 1985 / 13 |
| Veteran after Rebirth / cauldron | 15946 | 3405 | 113 / 4 | 4638 / 4585 / 53 |
| Restricted, no gacha/trade / Wolf | 1630 | 1630 | 100 / 3 | 2028 / 1968 / 60 |
| Restricted, no gacha/trade / cauldron | 3790 | 3790 | 100 / 3 | 4576 / 4568 / 8 |

Spend includes pipes/crystal plus 1800 and 2600 Gold. Veteran's preceding earned
cycle takes 12541 seconds; its own costs/actions remain in the M5 trace, not hidden
as gifted starting wealth. This does not require 24/7 AFK; dates/prices are still
provisional and need owner review before activation.

| Controlled comparison | Baseline | Seasonal | Interpretation |
| --- | --- | --- | --- |
| First solid delivery, logistics tier 1 | 2 units / 5 s; H10 | 2 / 5 s; capped H10 | No tier bypass |
| Logistics tier 2 | 2 / 5 s; H10 | 2 / 4 s; capped H25 | 20% less first-trip latency, same single carrier |
| Logistics tier 3 | 2 / 5 s; H10 | 2 / 4 s; H28 | Same recipe demand/capacity; no extra hauler |
| Ascension, fixed Void Cat B65, tier 3, supplied inputs | 6.106870 s → 7 integer ticks | 5.816067 s → 6 ticks | Exactly 1.05 duration divisor; one-second quantization |
| The same saturated batch timing projected to 1200 s | 171.43 batches | 200.00 batches | Projection excludes supply/start overhead; not a full-chain production claim |
| Double-output probability in that batch | 0.130 | 0.130 | Seasonal cauldron sells no chance increase |
| Earned tier-1 factory with both items, 7200 s | Gold-acquired +8624 Gold | Paid-method A/B fixture +8624 Gold | Complete-profile online/offline equality in each variant; equal income across variants |

The cauldron reduces continuous work duration by 4.76%; discrete tick thresholds
can change observed batch cadence by more than 5%. Slow inputs can erase the
whole-factory benefit. Current jobs retain captured duration; equipment requires
idle. Both variants consume identical ingredients/Essence and retain technology
gates. A normal guaranteed Prism Slime H50 can exceed the Wolf's H28; acquisition
does not establish a unique paid production ceiling.

## Required evidence and live activation

Retain all 696 tests. Add catalogue/UTC/identity/provenance/config/UI tests, all four
write boundaries before/after faults and replay, competing servers/leases, full
inventories, receipt after expiry, invalid/future data, pass true/false/error/stale,
Rebirth/trade/Fuse and queued delivery. Three zero-admin routes (new/returned/
restricted) must buy event items in the actual interval; compare paid/free effects,
tier limits and 7200-second parity. Requirements→tests/live steps and exact final
SHA Windows/Ubuntu evidence belong in ACCEPTANCE and the Draft PR.

Owner must supply real Creator Dashboard SKUs/prices, confirm dates and balance,
keep released mapping history, configure separate QA data stores/place, perform
explicitly authorized real receipt/pass tests and record mobile/2–8-player results
before switches can be enabled. No real-spend test is performed by this task.

The in-game gate does not disable external Creator Dashboard sales. Owner must
close platform sale availability in step with the UTC window, retain every released
SKU/archive mapping and reconcile already paid receipts after closure. Never
delete journals, empty proofs, reuse product IDs or re-enable memory receipts to
resolve a support incident. At 4096 proofs/64 queued rights, new in-game product
admission stops; externally initiated unexpected receipts remain RECORDED and
unacknowledged until capacity is safely extended/migrated. No refund is invented.

Primary references checked 2026-11-05:
[Developer Products](https://create.roblox.com/docs/production/monetization/developer-products),
[MarketplaceService API](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService),
[Passes](https://create.roblox.com/docs/production/monetization/passes),
[Paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items),
[Monetization](https://create.roblox.com/docs/production/monetization).
