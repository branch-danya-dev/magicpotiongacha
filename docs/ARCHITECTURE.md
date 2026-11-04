# Architecture — M2

## Boundaries

| Layer | Responsibility | Authority |
| --- | --- | --- |
| `src/shared/Config.luau` | Recipes, costs, storage limits, station caps, fixed hires | Server reads canonical values |
| `src/shared/Factory.luau` | Profile schema, commands, production and catch-up | Pure deterministic state transitions |
| `src/shared/Familiars.luau` | Species/range validation, exact outcome disclosure, evolution preview | Pure canonical model |
| `src/shared/Collection.luau` | Summon/fixed purchase/lock/Fuse candidate and operation receipt | Server supplies policy, clock, preview and RNG |
| `src/shared/Policy.luau` | Bounded permission cache, fail-closed access, late-result fencing | Server injects PolicyService lookup |
| `src/shared/Protocol.luau` | Exact request shapes and per-player token buckets | Server only |
| `src/shared/Access.luau` | Intent target and finite range checks, called with server-owned identity/position | Server only |
| `src/server/ProfileStore.luau` | Session lease, validation, snapshot writes, retry fencing | One persistent player key |
| `src/server/Main.server.luau` | Player lifecycle, ownership/distance checks, simulation and save scheduling | Server |
| `src/server/World.luau` | Greybox plots, pads, prompts, public visual attributes | Server presentation |
| `src/client/` | Adaptive controls, notifications, cosmetic familiar proxies | No rewards or economic writes |

Pure modules are shared source, not shared authority. Knowing a recipe or a price does not allow a client to decide the result.

## State and time

The profile stores `lastSimulatedAt`, balances, station jobs and buffers, cargo in transit, familiar instance IDs and base stats, ingredient/quest stock, active order, deterministic PRNG state and deployed-slime timers. It has a versioned schema. Recipes, persistent purchase/receipt fields and rebirth count are present for later expansion, but later features are not enabled.

One simulated tick is one integer second. Both online updates and join catch-up run this same function. Offline work is capped at 7200 seconds; the skipped tail is consumed by advancing the saved timestamp, not banked for a second login. Offline catch-up is durably saved before the player can interact or see its rewards. The welcome report is informational, not a reward-grant request.

At batch start, machine inputs and the machine's own Essence tank are consumed once. The crystal reservoir cannot power a batch directly. Manual `load` transfers missing ingredients and one recipe's Essence. Purchased pipes rotate first priority and transfer up to the configured rate per built machine each second, plus liquids through the intermediate store. Jobs contain their recipe, automatic/manual origin and effective timing; completing a job cannot charge the same batch again. Automatic jobs pause without a master. Manual jobs can finish without a worker.

Hauling removes cargo from its source into a persisted in-transit record, then delivers only what fits. Unassigning a carrier pauses its cargo rather than deleting it. New routes use solids and quest crates only; legacy liquid cargo may finish once. The fixed route duration is work to perform; each tick advances by `1 + capped Hauling * haulSpeedPerSkill`. Replacement workers use their current capped skill. Cargo already picked up is not resized to the replacement's capacity. Routes rotate among warehouse-to-input, source-to-warehouse and machine-queue-to-quest-stock to avoid starvation.

Full buffers block their own operation. Raw, intermediate, machine crate queues and delivered quest stock have separate capacities. Regular potion output bypasses storage and is sold immediately. A contract's quota counts **queued + travelling + delivered**. Before completing a batch, room for the maximum possible matching output is checked; waiting neither spends again nor rerolls the saved RNG. Excess above the quota exports. Expiry exports all three completed-crate locations once and clears only the affected cargo. An unfinished batch completes normally later. Claim checks delivered stock only and clears the active order before any second claim can succeed.

The V2 profile also stores `pipeCursor`, per-machine `essence`/`questQueue`, tutorial facts, first-event timestamps and bounded per-station stall seconds. These use the same integer-second simulation online/offline. Telemetry is local profile diagnostics, not external analytics. First events cover manual brew, automatic brew, upgrade, contract claim and tutorial completion; there is no user-supplied event endpoint or tutorial reward endpoint.

The saved PRNG is used only for prototype production events (slime and double output). Gacha uses an independent server `Random.new()` instance; neither its seed nor the production `rngState` is sent to the client.

V3 adds instance rarity/evolution/lock/provenance, `currencyPaid`, and a bounded last collection receipt. Old V1/V2 pets keep their IDs/stats/assignments and receive explicit `Legacy` metadata. See [PERSISTENCE.md](PERSISTENCE.md) for migration and recovery. No collection action occurs during offline simulation; evolved slime species retain the existing deployed-slime production behavior.

## Command flow

1. Protocol validates the exact payload and consumes request budgets.
2. Main requires the sender's active, writable session and proximity to their own target station.
3. Factory advances server time, validates state, and applies an intent using canonical configuration.
4. Main sends an explicit public snapshot, including production codes/shortages/progress, storage capacities, tutorial target and queued/travelling/delivered order totals. PRNG state, receipt history, diagnostic history and leases are omitted.
5. Periodic saves persist immutable snapshots. Player departure freezes actions before final saving.

The client never supplies a reward amount, price, drop, owner identity, clock, completion time or generated pet stats. `discard` is an explicit, confirmed ingredient-management action, not a general inventory deletion endpoint.

`buy` includes `expectedLevel` (0/1 for pipes). A stale repeated request fails before payment instead of buying the next level. Protocol validates its exact shape; World pads supply the displayed server level and UI buttons supply the last received snapshot level. Ownership, range, Player/session identity and writable lease checks still precede all economic actions. The action result is validated before presentation; unexpected invalid results quarantine the session.

Tutorial records facts when actions/production actually occur, including actions out of order. It grants no resources. Free harvest, click and manual refill remain available; recipe changes, missing assignments and excess raw stock have explicit recovery controls. The menu starts closed, uses 44-pixel action buttons, horizontal station navigation and orientation-dependent bounds reserving the lower screen. Server attributes place cosmetic crates at a queue or saved route position; visual movement never triggers delivery. Engine/device usability remains a manual gate.

## Durable collection commands

Summon, fixed shop, legacy hire, lock and Fuse pass Protocol, own-object distance,
active Player identity and lease checks. The runtime freezes factory actions/ticks
while a command is pending. A random command obtains a server PolicyService result
(60-second cache, 4-second lookup timeout); only explicit unexpired unrestricted
permission passes. Both identity and distance are rechecked after lookup and after
waiting for the profile gate. Guaranteed operations do not depend on this lookup.

`ProfileStore:transact` clones the latest profile under its existing per-key gate.
The pure command checks capacity/funds/parents before mutating the candidate; the
server draws outside the retrying DataStore callback. The candidate, payment,
parents/output, serial and operation receipt are saved together under the same
lease/revision. Only a confirmed write replaces live memory and produces a success
notice. Unknown write outcomes freeze the session for reconciliation by a fresh
lease/load; autosave cannot restore the older live snapshot over a reward.

Client `requestId` must be the saved sequence + 1. Repeating the latest identical
canonical intent returns its durable receipt without saving/drawing again; older
IDs and conflicting intents fail. A one-second collection cooldown supplements the
shared Protocol token buckets and per-session pending guard. Fuse requires five
exact IDs, a 60-second server preview token and explicit confirmation; parents,
stats, assignments, lock state and paid ancestry are revalidated at commit.

Inventory snapshots contain at most 128 instances. The client renders six text
cards per page, search/sort/free-worker controls, base/effective stats and known
shop outcomes. Only deployed workplace proxies animate. Viewing the Details panel
is required by the standard summon UI before its explicit spend confirmation;
the server still enforces restrictions against forged UI/remotes. Displayed
probabilities are derived from the same Config as the sampler.

## Lifecycle and failure handling

A local session is bound to the actual Player instance, not just its numeric ID. A second arrival cannot replace a still-loading/closing session. Cleanup verifies owner identity before touching the plot. Shutdown considers pending joins and releases within Roblox's shutdown time budget.

An unexpected simulation failure invalidates the profile before disconnecting the player. Quarantined memory is never written; the last valid save remains authoritative. A previous immutable snapshot already in flight may finish, but it cannot reopen the quarantined session. See PERSISTENCE.md for the storage adapter's limits.

## Deferred distributed operations

There is no live trading endpoint and no Robux purchase handler in M2. Later trading requires durable escrow/journaling, unique operation IDs, crash recovery, both-party confirmation invalidation and item provenance. MemoryStore or an in-memory mutex alone is not a durable transaction. Monetization requires receipt idempotency and actual purchase QA in addition to M2's policy checks. These must not be enabled by adding a client button alone.
