# M4 ADR: durable two-profile exchange

Status: implemented Draft; contract written before trading Remotes, then refined
with fault tests. Public trading is disabled. Base: M3 PR #9,
`2d9e6eb6dbb3417ec4a5aa3438bf9d3b035b39e9`. This is a protocol argument with
portable evidence, not live Roblox acceptance.

## Decision and authority

One profile write is atomic; two profile writes are not. A separate persistent
`t:<server-generated UUID>` journal is the sole decision authority. It contains
both participant IDs, each next trade sequence, canonical immutable item snapshots,
offer version/hash, coordinator identity, prepare deadline and acknowledgments.
No client supplies a snapshot, price, item owner, clock or transaction decision.

State: PREPARING → COMMIT or ABORT → SETTLED → COMPLETE. COMMIT and ABORT are
mutually exclusive, irreversible decisions made by UpdateAsync on the journal.
COMMIT's successful conditional write is the linearization point. Before it,
items belong to their original profiles but a persistent reservation makes them
unavailable. After it, the journal determines the final owners; physical profile
copies may lag, and neither side becomes usable until BOTH apply acknowledgments
are durable. An intermediate duplicate copy is never a second available item.

The profile stores a monotonic `trade.sequence`, bounded last receipt, and optional
pending `{id, hash, sequence, stage}`. Prepare increments sequence and freezes the
whole profile, deliberately stronger than locking only offered items. Factory
actions/catch-up, collection mutations, assignment, Fuse, equipment and new trades
are denied until settlement. Ordinary saves/releases can preserve the reservation
but cannot remove it. Recovery writes use the same profile gate, lease, revision
and unknown-outcome fences as ordinary transactions. No foreign active lease is
overwritten. No MemoryStore or process-local lock is an ownership authority.

## Write order and crash recovery

1. Both users explicitly ready then confirm the current version and SHA-256 label.
   Any offer change clears both ready/confirm flags. Revalidate exact server-side
   snapshots, identities, positions, policy and net inventory capacities.
2. Register the UUID/hash/deadline in its fixed durable registry shard, then create
   a PREPARING journal (120-second deadline), before reserving either profile.
   A delayed create callback rejects an expired deadline. Full registry denies
   admission before any profile reservation.
3. Under each participant's existing lease, persist its exact reservation; record
   that participant's prepared acknowledgment in the journal. Items stay in their
   original inventories. A lost profile response fences its old live session.
4. Refresh BOTH policy results and recheck identities/proximity. The journal CAS
   commits only with both durable prepares, an unexpired deadline, fresh allowed
   policy and the original coordinator. A racing abort wins or loses that same CAS.
5. Apply the decision independently under each profile lease. COMMIT removes exact
   outgoing snapshots and inserts exact incoming snapshots (cauldron owner changes;
   ID/provenance/stats/locks do not). ABORT preserves inventory. Save an applied
   marker before recording that side's journal acknowledgment. Retries are no-ops.
6. After both apply acknowledgments, persist SETTLED. Each profile may now clear
   pending and retain its bounded receipt. Record each clearance, then compact to
   COMPLETE. Success UI requires COMPLETE; earlier outcomes display Recovering.

An ABORT must fence even a participant whose prepare never happened. It writes a
sequence barrier on that profile, or proves its sequence has already advanced to
another operation. This prevents a delayed prepare from reserving items after the
abort was acknowledged. COMMIT apply always requires the matching reservation.
Old handlers cannot re-apply after a later trade because their sequence is stale.
No timeout alone releases a reservation after COMMIT.

On login, pending recovery runs BEFORE inventory snapshots, offline catch-up or
gameplay. A missing/corrupt journal fails closed; never regrant/reset a profile.
The coordinator also scans the fixed durable registry. It aborts expired
PREPARING records, applies decided records and clears settled reservations using
normal leases, including temporary recovery leases for absent players. Thus either
player may return on any server, or never return. If an old lease is active, wait;
after expiry a fresh recovery owner can proceed. If no server/backend is available,
settlement waits until one is; safety does not depend on continuous availability.

Unknown journal write outcomes are read back through UpdateAsync, never cached
GetAsync guesses. Decisions never revert. Unknown profile outcomes fence stale
memory; a fresh lease/load reconciles the committed record. Retries/callback replay
reuse the same immutable journal/sequence. Save/release cannot overwrite a newer
revision or remove persistent pending state using a stale snapshot.

## Bounds, discovery and garbage collection

At most one active negotiation per player; 6 items per side, max 128 familiars and
16 rare cauldrons after simultaneous outgoing/incoming changes. Gifts are allowed,
but original starter familiars and unknown Legacy provenance cannot be offered.
This preserves the guaranteed free production path. Empty/empty trades are denied.
Currency, ingredients, contracts, Robux and equipped/assigned/locked items are denied.

Discovery uses **16 fixed keys `r:00`…`r:15`, at most 128 entries each** in the
journal namespace. SHA-256(UUID)'s first 32 bits modulo 16 select a shard; entries
contain only UUID, offer hash and creation deadline. Register BEFORE creating the
`t:` record. Thus at most **2048 current journal keys + 16 registry keys** exist;
an occupied shard rejects new admission even if another shard has room. Retained
COMPLETE tombstones count toward this quota. This is an intentionally conservative
private-QA capacity, not a production throughput claim. Changing shard count needs
an explicit registry migration; never change it on an existing namespace.

A scanner caches at most one 128-entry shard and advances all 16 in round-robin
order. It reads at most 16 registry keys to find work, then handles at most one
journal per pass, every 30–33 seconds after initial jitter. Active-session recovery
is also polled; login directly resolves its pending UUID. The registry survives a
server crash and is independent of either player returning. Scanning a full
registry on a lone server can be slow; retries, hot-key contention and actual
throughput remain live-QA measurements. Recovery requires a running server, an
available backend and eventual ordinary lease acquisition.

Registry/journal operations retry at most twice with 0.25-second backoff; profile
operations retain their existing three-attempt backoff. Runtime checks UpdateAsync
budget before admission (30), background discovery (20) and individual work. Budget
checks are advisory, not quota reservations; concurrent work can still exhaust it.
Insufficient budget leaves recoverable Pending state. Invitations expire at 30 s,
negotiations at 300 s; 15 s invitation cooldown and Protocol budgets limit spam.
Unresolved entries are NEVER evicted for capacity. Full shards pause admission;
the sweeper continues while public admission is disabled.

After BOTH clearances, COMPLETE drops item snapshots, retaining only safe IDs,
hashes, sequences, decision and timestamps. Retain this small audit tombstone for
7 days, then delete it. Deletion is allowed only after confirmed completion and
the original creation deadline. Delayed creation is now expired; delayed prepares
are blocked by persistent sequence barriers. Missing completed history is never
interpreted as permission to recreate or transfer. Failed deletion is retried
later. Remove the registry entry only after confirmed journal deletion. A lost
delete reply leaves an entry; a later consistent UpdateAsync read proving the
journal missing can remove it after its creation deadline. The same rule cleans
registration-only crash orphans: no profile was reserved, and expired creation
callbacks cannot resurrect the journal after removal. Neither cleanup path deletes
an undecided or partially applied record. DataStore's platform version retention
remains outside this application's
control. Logs contain trade IDs/status only, never full profiles or item payloads.

The no-failure path measures **16 UpdateAsync calls**: registry admission, journal
creation, two profile prepares + two acknowledgments, decision, consistent read,
two applies + two acknowledgments, two clearances + two acknowledgments. This
excludes invitation policy reads and includes no background scanning/autosaves;
there are two forced policy lookups immediately before decision. Temporary recovery
leases may add a load and release around each absent-profile mutation (up to four
mutations / eight additional calls for apply + clear of both absent users).
UpdateAsync consumes read and write budgets. No unlimited retry loop is permitted.

## Policy matrix and release switch

Conservative M4 rule: BOTH users need a fresh, complete PolicyService response
with IsPaidItemTradingAllowed=true for ANY offered item, including known-free
shop/hire and guaranteed milestone cauldrons. A false/missing field, failed lookup,
expired result or unknown Legacy provenance denies the trade. Paid/Fuse ancestry
is preserved and cannot be laundered by the free-item path. A random-summon
restriction alone does not deny trading if trading permission is explicitly true.
Policy is forced fresh before the decision; its expiry is checked inside the CAS.
After COMMIT, recovery follows the decision instead of attempting a policy rollback.

| Item / policy | Admission |
| --- | --- |
| Known shop/hire/gacha pet; both explicit trading=true | Allowed if other ownership/use/capacity checks pass |
| Paid-derived pet, known Fuse descendant, phase-three cauldron; both true | Same gate; paid ancestry is never stripped |
| Either false, missing/incomplete, error, expired, superseded forced result | Denied; no cached earlier permission substitutes for a failed refresh |
| Legacy or historical Fuse without proof of all ancestors | Denied even when both users are allowed |
| Original starter, assigned/locked familiar, equipped/locked cauldron | Denied; unassign/unequip explicitly before offering eligible items |

New Fuse outputs store `provenance.tradeKnown = AND(parent provenance known)`.
Unknown ancestry cannot become known through fusion. Historical Fuse outputs stay
unchanged and usable in production but cannot be traded; their parents were
consumed before complete origin proof existed. Migration never retroactively
rewrites these pets. Paid ancestry remains OR across parents independently.

TradingEnabled defaults false. Enabling requires explicit server configuration
and Studio or a specifically allowlisted private QA place ID. Public economic
trade intents reject at the server even if sent without UI. Recovery remains
available when admission is disabled. The normal factory/F2P path is unaffected.

## Portable evidence and remaining gates

`trade_durable.spec` injects crashes before and after all 16 normal boundaries,
lost responses at every boundary and repeated callbacks. Its oracle runs after
every backend write: each original item remains in a profile or immutable journal,
and at most one unfrozen profile can use its ID. Recovery must reach the journal's
unique decision with unchanged metadata. The absent-player recovery path measures
17 calls; another crash matrix interrupts before/after each of those calls,
including acquiring and releasing temporary leases, then restarts recovery again.
Tests also cover reverse join order,
absent participants, stale leases, delayed callbacks, overlapping transactions,
abort/late-prepare races, missing journals, registry exhaustion/orphans and GC.

`trade_model.spec`, `trade_session.spec` and `trade_migration.spec` cover exact
intents, multilateral confirmation resets, 1:1/2:1/3:2/gifts, net capacities, all
value-operation conflicts, policy/provenance, strong-pet caps and V4 preservation.
The synthetic load runs eight distinct users in one manager/backend, four
simultaneous negotiations per round, **20 settled exchanges / 1160 requests**
(including 1000 denied while disabled). It is CPU/fake-backend evidence only.
The full suite retains 404 M0–M3 tests and adds 177 M4 tests (581 total).
See [acceptance matrix](ACCEPTANCE.md) and the Draft PR for exact-SHA CI evidence.

## Platform references rechecked 2026-11-05

- [Data stores](https://create.roblox.com/docs/cloud-services/data-stores): UpdateAsync
  callbacks do not yield; updates coordinate a single key, not multiple profiles.
- [Best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices):
  unknown writes, ordered bounded retries and stable key prefixes informed this ADR.
- [Memory stores](https://create.roblox.com/docs/cloud-services/memory-stores): ephemeral
  data is not the durable decision journal.
- [Paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items)
  and [PolicyService](https://create.roblox.com/docs/reference/engine/classes/PolicyService/GetPolicyInfoForPlayerAsync):
  server permission checks and paid ancestry remain mandatory; M4's all-item gate
  is deliberately stricter than a paid-item-only gate.

Studio, real DataStore crash/reconnect, true PolicyService, real phone and 2–8
clients are BLOCKED. Public trading stays off until that evidence is recorded.
