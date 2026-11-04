# M0 player persistence

## Scope and verification status

`src/server/ProfileStore.luau` stores one player profile per DataStore key and
uses a renewable lease to prevent concurrent live writers. It contains no Roblox
globals: its backend, clock, validator, and sleep function are injected.

The automated suite in `tests/profile_store.spec.luau` uses a controllable fake
DataStore. It covers callback replay, unknown request outcomes, lease takeover,
failed loads, invalid profiles, and save/release concurrency. Passing these tests
does **not** verify Roblox Studio, real DataStore quotas/latency, or production
shutdown behavior. The integration checklist below remains a release gate.

This adapter is not a two-player trade transaction system. Trading, paid
purchases, receipt processing, and schema migration are not implemented by it.

## Construction and public contract

```luau
local store = ProfileStore.new({
    dataStore = DataStoreService:GetDataStore("PotionTycoon_M0_qa_v1"),
    now = os.time,
    owner = game.JobId .. ":" .. HttpService:GenerateGUID(false),
    validate = Factory.validate,
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
| `store:isWritable(userId)` | True only while the local session is usable and its confirmed lease has sufficient time remaining. |
| `store:save(userId)` | Returns `true` after a confirmed snapshot write and lease renewal, otherwise `false, errorCode`. |
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
  explicitly and tested; there is no automatic reset to a new player.
- Failed saves pause gameplay writes. A subsequent save can recover while the
  adapter can still prove ownership of an unexpired lease. Expired, lost, or
  conflicting leases cannot be reclaimed by saving a stale local snapshot.
- A failed release retains the local profile for retry and does not deliberately
  clear the stored lease. If recovery cannot complete, another server must wait for
  expiry. Quarantined sessions remain blocked on the current server.
- A server crash or an unavailable backend can lose progress after the last
  successful snapshot. Neither `PlayerRemoving` nor `BindToClose` guarantees a
  successful final network write. The runtime uses a bounded shutdown wait; an
  individual in-flight Roblox API call is not cancellable by this adapter.
- No MemoryStore or server-RAM log substitutes for persistent ownership records.
  Safe future P2P trading requires a separate durable transaction/escrow protocol;
  two profile saves are not an atomic exchange.
- `receipts`/`entitlements` fields in a profile are reserved data. Their presence
  is not an implementation of Roblox purchase receipt validation or fulfilment.

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

Set `UseMemoryInStudio = false`, select a QA-only `DataStoreName`, and enable the
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
