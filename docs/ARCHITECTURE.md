# Architecture — M0

## Boundaries

| Layer | Responsibility | Authority |
| --- | --- | --- |
| `src/shared/Config.luau` | Recipes, costs, storage limits, station caps, fixed hires | Server reads canonical values |
| `src/shared/Factory.luau` | Profile schema, commands, production and catch-up | Pure deterministic state transitions |
| `src/shared/Protocol.luau` | Exact request shapes and per-player token buckets | Server only |
| `src/server/ProfileStore.luau` | Session lease, validation, snapshot writes, retry fencing | One persistent player key |
| `src/server/Main.server.luau` | Player lifecycle, ownership/distance checks, simulation and save scheduling | Server |
| `src/server/World.luau` | Greybox plots, pads, prompts, public visual attributes | Server presentation |
| `src/client/` | Adaptive controls, notifications, cosmetic familiar proxies | No rewards or economic writes |

Pure modules are shared source, not shared authority. Knowing a recipe or a price does not allow a client to decide the result.

## State and time

The profile stores `lastSimulatedAt`, balances, station jobs and buffers, cargo in transit, familiar instance IDs and base stats, ingredient/quest stock, active order, deterministic PRNG state and deployed-slime timers. It has a versioned schema. Recipes, persistent purchase/receipt fields and rebirth count are present for later expansion, but later features are not enabled.

One simulated tick is one integer second. Both online updates and join catch-up run this same function. Offline work is capped at 7200 seconds; the skipped tail is consumed by advancing the saved timestamp, not banked for a second login. Offline catch-up is durably saved before the player can interact or see its rewards. The welcome report is informational, not a reward-grant request.

At batch start, inputs and Essence are reserved once. Jobs contain their recipe and effective timing; completing a job cannot charge the same batch again. Hauling removes cargo from its source into a persisted in-transit record, then delivers only what fits. Unassigning a carrier pauses its cargo rather than deleting it. Routes rotate to avoid starving a machine behind a permanently busy source.

Full buffers block their own operation. Raw and intermediate capacities are separate; quest stock is separate again. Regular potion output bypasses storage and is sold immediately. A contract reserves only its quota, with excess exported. Expired contract stock is exported at its ordinary value once; it does not receive the contract bonus.

The saved PRNG is used only for prototype production events (slime and double output). It is **not** a future paid-gacha randomness implementation.

## Command flow

1. Protocol validates the exact payload and consumes request budgets.
2. Main requires the sender's active, writable session and proximity to their own target station.
3. Factory advances server time, validates state, and applies an intent using canonical configuration.
4. Main sends an explicit public snapshot. PRNG state, receipt history and leases are omitted.
5. Periodic saves persist immutable snapshots. Player departure freezes actions before final saving.

The client never supplies a reward amount, price, drop, owner identity, clock, completion time or generated pet stats. `discard` is an explicit, confirmed ingredient-management action, not a general inventory deletion endpoint.

## Lifecycle and failure handling

A local session is bound to the actual Player instance, not just its numeric ID. A second arrival cannot replace a still-loading/closing session. Cleanup verifies owner identity before touching the plot. Shutdown considers pending joins and releases within Roblox's shutdown time budget.

An unexpected simulation failure invalidates the profile before disconnecting the player. Quarantined memory is never written; the last valid save remains authoritative. A previous immutable snapshot already in flight may finish, but it cannot reopen the quarantined session. See PERSISTENCE.md for the storage adapter's limits.

## Deferred distributed operations

There is no live trading endpoint and no Robux purchase handler in M0. Later trading requires durable escrow/journaling, unique operation IDs, crash recovery, both-party confirmation invalidation and item provenance. MemoryStore or an in-memory mutex alone is not a durable transaction. Monetization requires receipt idempotency and fail-closed per-player policy checks. These must not be enabled by adding a client button alone.
