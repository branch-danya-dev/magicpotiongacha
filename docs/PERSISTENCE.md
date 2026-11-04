# M4 player persistence

## Scope and verification status

`src/server/ProfileStore.luau` stores one player profile per DataStore key and
uses a renewable lease to prevent concurrent live writers. It contains no Roblox
globals: its backend, clock, validator, and sleep function are injected.

The automated suite in `tests/profile_store.spec.luau` uses a controllable fake
DataStore. It covers callback replay, unknown request outcomes, lease takeover,
failed loads, invalid profiles, and save/release concurrency. Passing these tests
does **not** verify Roblox Studio, real DataStore quotas/latency, or production
shutdown behavior. The integration checklist below remains a release gate.

This adapter remains a **single-profile** lease/revision boundary. M4 builds a
separate durable journal/coordinator on top; two profile writes alone are not an
atomic exchange. Paid purchases and platform receipt processing remain absent.
The pure migration hook and ordinary lease protocol remain in use.

## Construction and public contract

```luau
local store = ProfileStore.new({
    dataStore = DataStoreService:GetDataStore("PotionTycoon_M0_qa_v1"),
    now = os.time,
    owner = game.JobId .. ":" .. HttpService:GenerateGUID(false),
    validate = Factory.validate,
    migrate = Factory.migrate,
    sleep = task.wait,
    leaseSeconds = 120,
})
```

| Option | Contract / default |
| --- | --- |
| `dataStore` | Provides `:UpdateAsync(key, transform)` with Roblox-compatible cancellation semantics. |
| `now` | Trusted server epoch seconds. Never a client timestamp. |
| `owner` | Nonempty, unique identifier for this live adapter/server session. Never reuse a prior server's identifier. |
| `validate` | Pure, non-yielding `validate(profile) -> boolean, reason?`. |
| `migrate` | Optional pure, non-yielding `migrate(isolatedProfile) -> profile?`; used only when loading an existing record. |
| `sleep` | Yielding wait function used for retries and the local write gate. |
| `leaseSeconds` | `120`; the runtime autosaves every `30` seconds. |
| `safetyMarginSeconds` | `15` for the default lease; freezes gameplay before lease expiry. |
| `retries` | `3` attempts per backend operation. |
| `retryDelaySeconds` | `0.25`, with exponential backoff between attempts. |
| `gateTimeoutSeconds` | `10`; bounds waiting for another local operation on the same key. |

Methods use colon syntax:

| Method | Result and responsibility |
| --- | --- |
| `store:load(userId, createProfileFn)` | Returns the live profile or `nil, errorCode`. The zero-argument factory runs outside the DataStore callback. Its result initializes only a missing key. |
| `store:get(userId)` | Returns the live in-memory table or `nil`. This alone does **not** authorize mutation. |
| `store:isWritable(userId)` | True only while the local session is usable, its confirmed lease has sufficient time remaining, and no persistent trade is pending. |
| `store:hasLease(userId)` | Internal recovery check: same lease/session fences, allowing persistent trade pending. Not permission for ordinary gameplay. |
| `store:loadExisting(userId, placeholderFn)` | Recovery load under a new normal lease; missing keys fail closed, placeholder is never written. |
| `store:transactTrade(userId, transform)` | Trusted server-only reserve/apply/clear port; same gate, validation, lease, revision and unknown-outcome fences as transact. Never expose a transform to clients. |
| `store:save(userId)` | Returns `true` after a confirmed snapshot write and lease renewal, otherwise `false, errorCode`. |
| `store:transact(userId, transform)` | Runs a non-yielding trusted transform on an isolated candidate under the same gate. Confirms its atomic save before replacing live state. Returns `true, result` only after confirmation or a previously committed receipt replay. |
| `store:release(userId)` | Freezes new gameplay, persists the latest safe snapshot, and clears its own lease. A duplicate successful release is a no-op. |
| `store:invalidate(userId)` | Quarantines a potentially damaged in-memory profile without writing it. Future saves/releases are rejected. |

User IDs must be finite safe integers. Zero and negative IDs are accepted for
Studio test players. The runtime always obtains the ID from the server's Player
object, not from a remote payload.

Profiles must contain only JSON-compatible primitives, string-keyed dictionaries,
and dense one-based arrays. Cycles, metatables, functions, mixed/sparse tables,
NaN, and infinity are rejected. If the profile has a `userId`, it must match the
DataStore key being loaded or saved.

## Stored envelope

Keys have the form `p:<userId>` within the configured DataStore:

```luau
{
    schemaVersion = 1,
    profile = { -- Full, validated gameplay snapshot.
        -- Balances, inventory, jobs, PRNG state, lastSimulatedAt, etc.
    },
    lease = {
        owner = "unique-live-session-id",
        expiresAt = 1234567890,
    },
    revision = 1,
    lastOperationId = "stable-id-for-one-load-save-or-release",
}
```

`lease` is absent after a successful release. Expiry is a logical ownership check;
it does not delete the persistent key. `revision` and `lastOperationId` are adapter
metadata, not gameplay data and not client-visible state.

## Lifecycle invariants

1. Acquire the profile and its lease atomically with `UpdateAsync`. Refuse a live
   lease owned by another session. An expired lease can be acquired by a new owner.
2. Run offline catch-up on the loaded snapshot. Save the rewards, inventory,
   pending jobs, random state, and processed timestamp together **before** enabling
   player actions or displaying the catch-up report.
3. Permit a gameplay mutation only for the current Player/session identity and
   while `isWritable()` is true. The client never supplies an authoritative profile.
4. Save periodically. The local per-key gate serializes load/save/release, and a
   queued release takes its snapshot only after preceding saves have finished.
5. On departure or shutdown, stop accepting actions and perform bounded release
   retries. Loading sessions remain tracked until their acquisition/cleanup returns.
   A stale Player callback must not release a newer Player's plot or session.
6. On a simulation exception or failed simulation invariant, call `invalidate`
   before cleanup. Do not persist the partially modified profile. A save already
   in flight owns an independent, pre-invalidation snapshot and may safely finish;
   it must not re-enable this quarantined session.

Every save/release checks the stored owner, lease expiry, and revision again inside
`UpdateAsync`. A stale server cannot overwrite a new owner's profile or clear its
lease. One operation's ID stays stable during retries, so a request whose response
was lost can recognize its already committed result without applying it again.

After an exhausted request with an unknown outcome, a subsequent call can discover
a revision conflict and remain blocked. This deliberately favors preserving the
backend state over guessing whether a previous write succeeded.

## Failure behavior and limits

- A failed or rejected load has no writable local default profile. Backend errors
  never activate the Studio in-memory backend.
- Invalid/future envelope or profile schemas fail closed. Migration must be added
  explicitly and tested; there is no automatic reset to a new player. Only the
  explicit gameplay V1/V2/V3/V4→V5 migration is supported.
- Failed saves pause gameplay writes. A subsequent save can recover while the
  adapter can still prove ownership of an unexpired lease. Expired, lost, or
  conflicting leases cannot be reclaimed by saving a stale local snapshot.
- Failed collection or progression commits additionally fence the old live snapshot permanently
  for that session: an unknown outcome may already contain a reward. Rejoin must
  reconcile durable state after the old lease expires; do not retry by saving old
  memory or rerolling inside a storage callback.
- A failed release retains the local profile for retry and does not deliberately
  clear the stored lease. If recovery cannot complete, another server must wait for
  expiry. Quarantined sessions remain blocked on the current server.
- A server crash or an unavailable backend can lose progress after the last
  successful snapshot. Neither `PlayerRemoving` nor `BindToClose` guarantees a
  successful final network write. The runtime uses a bounded shutdown wait; an
  individual in-flight Roblox API call is not cancellable by this adapter.
- No MemoryStore or server-RAM log substitutes for persistent ownership records.
  M4 uses the separate [durable exchange protocol](M4_TRADING.md);
  two profile saves are not an atomic exchange.
- `receipts`/`entitlements` fields in a profile are reserved data. Their presence
  is not an implementation of Roblox purchase receipt validation or fulfilment.

## Historical V1 → V2 conversion, retained inside V1 → V5

The DataStore **envelope remains version 1** and the namespace is unchanged, so
existing keys are found. `Factory.validate` accepts only current V5 gameplay
profiles. For V1, `Factory.migrate` first checks the previous shape/invariants,
then copies it and initializes empty machine Essence tanks/quest queues, a pipe
cursor, tutorial facts and diagnostic tables. Existing balances, paid jobs,
inventory, already-delivered quest stock, cargo, timers, assignments, RNG and
timestamp are retained. A captured V1 fixture was validated with PR #3's Factory.

An old brewing job is already paid; it gains an `automatic` flag from its saved
station mode and finishes without another Essence debit. Old liquid hauling jobs
retain their item/amount/destination/progress and finish; new routes never pick
up liquids. Existing recipe discoveries count as prior manual learning. First
diagnostic timestamps are not invented. No starter, tutorial currency or pipe
grant occurs. An old automated factory without pipes needs the newly affordable
28-Gold pipes or manual refilling; its reservoir remains intact.

The adapter clones/serialization-checks an existing profile, invokes migration
under `pcall`, then checks serialization, identity and current validation again.
The migrated profile is committed **with the load lease/revision in the same
UpdateAsync**, only after the normal envelope and competing-lease checks pass.
Callback replay and a lost response cannot apply grants or acquire a second
revision for the same operation. An exception, nil, cycle, identity change,
invalid old data or future schema cancels the write. Save/release paths never
migrate or weaken validation; quarantine and revision fencing are unchanged.

Offline simulation still follows lease acquisition and is saved before gameplay.
V2 is not backward writable by M0 servers: deploy coherently to a private QA
environment first and do not downgrade a migrated key by resetting it. Real
DataStore migration/lease and multi-client rollout remain **BLOCKED (D1/S1)**.

## Historical V2 → V3 conversion and collection recovery

The envelope/namespace and lease/revision rules remain unchanged. V2 is validated
with its M1 shape before copying; `tests/fixtures/m1-profile.luau` was generated
and validated using PR #5 at `322f027465e8909902a79eaa9682c9017cf997c2`.
All existing fields are preserved, including high legacy base stats, paidOrigin,
assignments, pending prepaid jobs, in-flight cargo, Essence buffers, quest queues,
tutorial, diagnostics and RNG. Each old pet gets rarity `Legacy`, stage 0,
unlocked, provenance source `legacy`, empty parent IDs, and paidDerived equal to
its existing paidOrigin. No invented historical draw or entitlement is granted.

V3 initializes collection sequence 0 and false paid-currency flags. M0/M1 have no
paid currency purchase endpoint; the independent existing pet paidOrigin still
survives. New pet sources are starter/hire/shop/gacha/fuse. Fuse records the five
consumed IDs plus the OR of paid ancestry, avoiding recursive unbounded trees.
New fixed/rolled stats must obey species ranges; legacy stats keep the old bound.

A command uses sequence + 1, canonical intent fingerprint and latest durable
receipt. Payment/parents/result/serial/receipt commit in one profile snapshot.
The latest identical retry returns that receipt (even after reconnect and preview
expiry); older sequence IDs fail without spending. A different intent cannot use
an existing successful ID. Only one receipt is retained, so the ledger is bounded.
Clients receive the latest result, never an unconfirmed candidate or RNG seed.

On an ambiguous commit failure, wait for the prior lease to expire and load with
a fresh session. If the operation committed, its currency and full output/removed
inputs/receipt are present together; if it did not, the prior state remains. Never
manually regrant a missing-looking pet before checking durable state. Invalid or
future records remain untouched. V3 cannot be written by M1 servers: use a coherent
private QA rollout and backed-up keys; do not downgrade by resetting migrated data.
Real rollback/recovery and platform quotas/latency remain **BLOCKED (D1/S1)**.

## Historical V1/V2/V3 → V4 and progression recovery

The envelope and namespace are unchanged. `LegacyConfig` freezes the M2 vocabulary
so new slots/recipes/items cannot be smuggled into an old-version record. A captured
V3 fixture was generated and validated with PR #7 at
`f9c34c8383bee2a0fdd1ef08167103725a924672`. It contains rolled/locked Secret stats,
paid Fuse ancestry, latest collection receipt, assignments, prepaid production,
queues and in-flight cargo. The test compares every preexisting field after load.

V4 retains those fields, all balances/timers/RNG/tutorial/discoveries and the old
seven route indices. It adds phase 1, empty rare-cauldron inventory, serial 1,
progression sequence 0, empty material-turn cursors and seven empty unbuilt slots.
New source cooldowns start at the saved simulation timestamp. Migration does not
infer historical phase purchases or grant milestone items. V1/V2 first receive
their historical M1/M2 additions; V3 collection metadata/receipts are not rebuilt.
V4 records validate before the subsequent V5 conversion. Unexpected progression fields in
an old version, future schemas, out-of-range cursors and invalid technology/owner/
bonus/equipment state fail closed without a default overwrite.

Rare cauldrons persist unique ID, ownerId, type, canonical bonus, lock and source /
paidDerived provenance. A slot stores only the installed item's ID; validation
rejects duplicate installations and wrong owners/archetypes. Source is the free
phase-three milestone. Persisted paid ancestry is retained for future protocols;
M3 creates no paid item, transfer or purchase endpoint.

Construction, phase advance, equip and lock use the existing `transact` gate and a
separate bounded progression receipt. Payment, phase/slot changes, milestone item,
serial and receipt commit together. M2 and M3 share one gate and live pending guard.
The last identical retry is replayed after rejoin; conflicting/stale IDs do not
spend. Failed/ambiguous writes permanently fence the old live candidate. Reload
after lease expiry reconciles committed state; never manually rebuild a slot or
regrant a milestone item based on a missing success notification.

Tests cover before/after-commit loss, replay, identical/conflicting concurrency,
M2-shop/M3-phase interleaving, current equipped/locked-item roundtrip, offline cap
and stale lease rejection. These are fake-backend results. V4 cannot be downgraded
to an M2 server: use coherent private QA deployment and backed-up keys. Real
DataStore/PolicyService and multi-client recovery remain **BLOCKED (D1/S1)**.

## Gameplay V1/V2/V3/V4 → V5 and trade recovery

The envelope stays version 1 and existing player keys/namespaces stay unchanged.
A genuine V4 fixture was captured and validated on M3 PR #9 at
`2d9e6eb6dbb3417ec4a5aa3438bf9d3b035b39e9`. V4 validation uses the M3 vocabulary;
V1/V2/V3 retain frozen LegacyConfig validation and their prior conversions. V5
adds only `trade={sequence=0}` after old conversions. It does not rewrite V3/V4
pets, rolls, paid ancestry, cauldrons, serials, receipts, factory buffers/jobs,
fairness cursors, balances, tutorial, timestamps or RNG. Future versions or any
unexpected historical trade state fail closed before a backend write.

New trade state contains a monotonic sequence, one last decision receipt, and
optional `{id,hash,sequence,stage}` pending marker. An applied pending marker must
match its receipt. Reserve increments sequence and freezes the entire profile;
ordinary transact and pure economic functions refuse it. Ordinary save/release
can persist only an unchanged pending profile, preserving the reservation while
renewing/releasing the lease. An unknown trade write fences the old memory exactly
like an unknown collection commit. Callback-time clock checks prevent queued
requests from using an expired dispatch-time lease.

The journal is separate (`TradeJournalName`); configure it alongside the player
namespace. A 16-shard, 128-entry-per-shard durable registry admits UUID/hash/deadline
before journal creation. It bounds retained journals to 2048 and drives recovery
independently of player activity. Full shards stop new admission; never evict
unfinished records. The journal CAS decides COMMIT or ABORT once. Apply is
idempotent; both profiles must acknowledge apply before either reservation is
cleared. COMPLETE compacts snapshots, then retains audit metadata for seven days.
Confirmed deletion precedes registry removal; expired registration-only orphans
are removed only after a consistent missing-journal read. Full ordering, proof
and request budgets are in [M4_TRADING.md](M4_TRADING.md).

On login, pending recovery precedes inventory, offline simulation and gameplay.
The server uses its own valid lease for local profiles and ordinary temporary
recovery leases for absent users. Foreign live leases block recovery. It never
creates a missing participant record or resets a bad journal/profile. A surviving
server periodically resolves decided/expired journals even when both players
never return and TradingEnabled is false. Availability waits for backend and lease
recovery; timeout alone never rolls back a COMMIT. Simulation resumes with the
same saved timestamp and existing catch-up rules after settlement.

Historical Fuse metadata cannot prove that all consumed ancestors were known.
Such pets and Legacy pets remain usable but untradeable, without changing their
saved data. New Fuse carries `tradeKnown` as AND of parent proofs, independently
of paidDerived OR; unknown ancestry cannot become tradeable by repeated fusion.
All known items require fresh explicit trading permission for both users.

Portable evidence: 404 retained + 177 M4 tests, faults before/after each of 16
durable calls, lost replies/callback replay, old-server fencing, reverse login,
absent recovery, policy/provenance, registry bounds/GC and V4 field equality.
Real storage, shutdown/reconnect, PolicyService and mobile/multiplayer acceptance
remain **BLOCKED**. V5 cannot be downgraded by older servers; deploy coherent
versions only to the isolated private QA environment before any live acceptance.

## Studio and real-backend acceptance checklist

Use a **separate private test experience and a dedicated QA DataStore name**.
Do not enable Studio API access against live player data just to run these tests.

### Studio memory mode

With `UseMemoryInStudio = true`, run a local multi-client test and confirm:

- Each player gets only their own plot, profile, resources, and station assignments.
- The UI identifies `STUDIO_MEMORY` mode.
- Leaving/rejoining within the same surviving test server preserves that server's
  in-memory record; stopping the server resets it. This mode is not persistent
  storage and must not be reported as a real DataStore save test.
- A previous Player's delayed cleanup cannot remove a later session's plot.

### Isolated real DataStore mode

Set `UseMemoryInStudio = false`, select QA-only `DataStoreName` and
`TradeJournalName`, and enable the
necessary Studio API access for that private test experience. Verify:

- Earn currency, start a production job, make assignments, leave, and rejoin.
  Balances, inventories, jobs, and ownership restore correctly; starter grants do
  not repeat.
- Repeat rapid leave/rejoin and server switching. A lease collision produces a
  retryable load failure, never a fresh profile or duplicate inventory.
- Stop a server while loading and while saving. Check that cleanup is bounded;
  if final persistence fails, the next session respects the prior lease and restores
  the last durable state rather than overwriting it.
- Verify offline catch-up and its cap with QA-only prepared records. A second
  immediate login must not grant the same interval or reroll its saved random state.
- Disable test API access or use the fake backend's injected failures to verify
  fail-closed behavior. Do not manufacture an outage against production services.
- In an isolated QA key, test unsupported schema and invalid profile data. No
  default/reset write should replace that key. Preserve a backup before the test.
- Exercise failed simulation handling: the Player is blocked/removed, a tainted
  profile is not written, and another session can later load the prior safe snapshot.
- Inspect server logs and UI on failure. Do not log full private profiles, receipts,
  lease identifiers, or credentials to clients.

Record the tested build SHA, Studio/platform version, test experience and namespace,
scenarios, and observed results before enabling real players.

## References

- [Roblox Data Stores](https://create.roblox.com/docs/cloud-services/data-stores)
- [Player data, session locking, and purchasing systems](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing)
- [DataStore best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices)
