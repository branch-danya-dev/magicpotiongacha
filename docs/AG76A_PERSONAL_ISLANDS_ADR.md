# AG-76A — Personal Islands: ownership, routing and migration ADR

**2026-11-16 · PROPOSED / ARCHITECTURE ONLY · OWNER REVIEW REQUIRED · NOT PUBLISHED.**
Scope: [Issue #53](https://github.com/branch-danya-dev/magicpotiongacha/issues/53), stage A only.
Base: Draft [PR #52](https://github.com/branch-danya-dev/magicpotiongacha/pull/52),
`feat/ag75-owner-feedback-p0` @ `a1a165be6b3120e707fd33fb746fb9bac4dfc078`.
Its parent is AG-74 PR #51 @ `f421ccdaa5da6c55535ebf4c1048eb186ccfb5d4`.
Base Windows/Ubuntu CI: [43794436530](https://github.com/branch-danya-dev/magicpotiongacha/actions/runs/43794436530), both SUCCESS.
Work branch: `feat/ag76a-personal-islands-architecture`. Delivery SHA and checks are recorded in the stacked Draft PR.

No executable code, schema, flags, asset IDs, place configuration or saved data changes in A.
The current build still generates eight plots. This ADR does not claim that Personal Islands work yet.
AG-75 remains a code candidate with native/owner gates open; AG-74's texture warning and outstanding device/backend checks are inherited.
No screenshots or recording are required by the owner's current instruction. Later native QA must still record textual results and errors honestly.

## 1. Decision and boundaries

The owner's topology decision is accepted: **one authoritative owner's island per live island server**, reconstructed on demand.
Only the old eight-owner/4×2 topology, neighbour boundaries, eight-plot art rollout and physical shared Bazaar assumptions are superseded.
Other V2 contracts survive, including server authority, the four phases/temple direction, offline simulation, eventual C02 free placement, provenance and economy.
Removing seven plots, hiding them on the client or setting `PlotCount = 1` cannot implement ownership or routing.

Proposed implementation: a minimal **Entry Place → reserved Island Place** flow, with a separate social Hub Place reserved for later work.
Entry authenticates routing; Island owns one profile lease and factory; Hub never becomes a second factory writer.
No continuously running server is allocated to an offline owner. Neither a server identifier nor an invitation is durable land ownership.
Alternatives rejected: first-arrival claims a public singleton (races/leaks); eight invisible plots (wrong ownership model); MaxPlayers=1 (precludes guests and still does not authenticate ownership); one permanent server per account (unnecessary).

AG-76B may implement isolated Studio routing adapters after A review. Real routing/place setup needs a separate approved QA plan.
The local adapter requires a server-configured QA owner UserId and fixture context; a second test client is denied. It must never infer ownership from first arrival or accept a client QA bypass. Test admission is unreachable outside Studio and the isolated QA build.
AG-76C needs migration review and the expansion/Rebirth decisions below before V9 writes, even in its QA candidate.
No automatic rollout from a green CI run.

## 2. Source inventory at the exact base

Paths below are relative to the repository and describe current behaviour, not proposed implementations.

| Source / seam | Current dependency | Required B/C adaptation |
| --- | --- | --- |
| `src/server/World.luau`: `new`, `claim`, `release`, `update`, `inRange` | Builds eight `Plot_<n>` models; claim selects the first vacant slot; owners map by UserId but membership also uses the exact Player object | Construct one island for a verified admission; explicit owner identity, no free-slot allocator; release only the matching session |
| `src/server/Main.server.luau`: startup, `onPlayer`, `placeCharacter`, `closeSession`, `handleAction` | World exists before admission; `onPlayer` claims/spawns before profile load; sessions bind Player; callbacks can yield | Authenticate before any owner profile load/claim; recover and load before playable spawn; recheck admission after each yield; retain fencing and close/save rules |
| `src/server/ServerSettings.luau` | PlotCount=8; memory in Studio; existing DataStore `PotionTycoon_M0_dev_v1`; P2P/purchases OFF | Explicit environment/role config; protected existing namespace; no MaxPlayers=1 shortcut; QA flags independent from publishing |
| `src/shared/Factory.luau`: `projectV8`, `projectionValid`, migrations/validation | V8 layout is an exact 13-slot projection; stations remain cargo authority; coordinates must equal Config offsets | Preserve V8 projection. C adds a separate island projection; do not relax old validation into arbitrary building |
| `src/shared/Config.luau`, `Progression.luau` | 13 logical slots, recipes, phase prerequisites, prices, input/output waypoints | Keep all IDs, costs and simulation values; map phase/temple to approved sector prerequisites only |
| `src/server/ProfileStore.luau`: key, `_snapshot`, load/save/transact | Key is already `p:<userId>`, not PlotIndex; envelope v1, revision, lease; migration on load only | Same writer boundary; validate island owner against expected UserId. No new independent island/economy writer |
| `src/shared/Access.luau` | Ownership/alive/distance checks; many personal intents currently target altar/crystal/garden | Narrow UI-market authorization policy; keep station interactions and all other guards intact |
| `src/shared/RPGNavigation.luau`, `Main.client.luau`, Trade UI | Inventory `bazaar` tab is currently “Обмен” (M4), not a functioning personal market | Replace that tab's content with allowed personal operations; never turn M4 proximity into an unconditional true |
| `TradeRuntime`, `PurchaseRuntime`, receipt/trade recovery | `world:inBazaar` passed to trading; purchase range targets altar; journals are separate durability boundaries | Physical Bazaar removal must not enable trading/purchase prompts. Retain recovery even when acquisition/trading is OFF |
| `src/shared/LongTerm.luau` | Rebirth resets a field whitelist and historical station levels; future island fields would otherwise survive implicitly | C needs an explicit reviewed geographic reset rule; do not rely on omission from the reset list |
| `EnvironmentArt`, `FarmLandscape`, `IslandLandscape`, `PropArt` | Plot loops, pilot index, floor/sign/pads, direct Bazaar accesses and eight-plot terrain | Island-specific generation and guards; one central lectern; bounded silhouettes; remove obsolete server geometry |
| `IslandTerrain`, `IslandBoundary`, `CameraClearance`, `CharacterSafety.server.luau` | Old world envelope, spawn parent and OwnerUserId checks | Bounds/navigation from island catalog; valid owner admission and safe reset; future guests separately authorized |
| `SpellbookLectern`, legacy/AG67 effects, `FarmAffordance`, `Main.client` | PlotIndex/`PotionPlotIndex` and owner attributes identify visuals/receipts | IslandId + OwnerUserId + presentation generation; original crystal intent and +5 C01 click untouched |
| `FamiliarView`, `WorldContext`, `ContextUI`, tutorial and QA builders | StationId scans, world anchors, legacy plot fixtures | Scope scans to active island; retain cargo/job identities and progress, starter-once UI and two Green Slime Idles |

Historical eight-plot tests remain useful baseline fixtures, not target-world acceptance. B adds island-specific tests and updates only genuinely obsolete topology assertions with an explicit mapping; it must not delete economy/preservation checks to obtain green CI.

## 3. Identity, routing and session fencing (proposed)

### Identities and service boundaries

- Stable primary `islandId = "u:" .. canonicalUserId .. ":primary"`; `ownerUserId` is the authenticated Player.UserId. In live data it must satisfy the existing user-id validator. Negative Studio test users exist only in isolated memory fixtures.
- `slotId="primary"` is land identity. A reserved GUID, JobId, PlotIndex, model name and client payload are **not** ownership.
- Entry router never loads the player's economic profile, catches up offline production, grants a starter or starts trade/receipt recovery.
- Island session is the only `ProfileStore` owner writer; future visitors do not load or acquire the owner's profile. Only the admitted owner receives its private snapshot.
- Future paid satellite areas belong to this owner. They are areas in the same writer session or require a serialized handoff; they cannot be simultaneous independent writers of `p:<ownerUserId>`.

### Admission flow and data

1. Entry derives the target primary island from the actual Player. Ignore client owner/island/role values. A future visit request uses a server-validated invitation service, not an arbitrary owner parameter.
2. A short-lived MemoryStore directory keyed by environment + islandId contains `{version, islandId, ownerUserId, placeId, reservedServerId, generation, status, activeJobId, expiresAt}`. It holds **routing only**, never balances, ownership entitlements or profile snapshots. Conditional updates serialize route allocation; no yielding or external calls inside update callbacks.
3. Router creates a bounded, expiring admission ticket: `{nonce, userId, islandId, ownerUserId, role="owner", generation, sourcePlaceId, destinationPlaceId, reservedServerId, expiresAt, consumedByJobId?}`. TeleportData carries only nonce/version. Client-visible data never grants authority. Limit one pending ticket per user/generation; invalidate a replaced ticket.
4. Destination verifies server-side join source against the configured experience/place allowlist; reserved-server type and expected identity; directory generation; ticket UserId, destination, expiry and role. Atomically bind the ticket and route to this JobId. A repeated callback in the same session may be idempotent; another JobId or Player instance cannot reuse it.
5. Only then acquire the existing ProfileStore lease, validate/migrate the snapshot, reconcile pending trades/receipts through existing coordinators, perform existing offline advancement, and construct/spawn the playable island. Preserve the current starter-budget/idempotency semantics; migration never grants it. Do not expose an active owner session before recovery succeeds.
6. Every post-yield continuation checks the exact Player instance, local admission generation, route generation, close state and profile writability. A late `CharacterAdded`/load/teleport callback cannot revive a released session.

Current Roblox documentation describes GUID-based `TeleportOptions.ReservedServerId`, matching destination PrivateServerId in production, with a distinct JobId per instance. Use that supported API in the future adapter rather than adding a legacy access-code implementation. Multiple runtime instances can still represent the same reserved identity: the route binding **and the existing profile lease** must reject a second writer. See [private-server API](https://create.roblox.com/docs/projects/teleport-private-servers).

Proposed operational values for fault tests, not game balance: route heartbeat 20 s, directory TTL 60 s, ticket TTL 120 s; 3 automatic teleport retries with bounded 1/2/4 s backoff plus jitter, then explicit Retry/Return. They do not shorten the existing 120 s profile lease or its safety margin. Revalidate supported APIs/quotas before implementation.

### Lifecycle and failures

| Event/state | Required behaviour |
| --- | --- |
| Entry → routing → admitted → loading/recovery → active | Each transition owns one cancellation token; no economic mutation before authenticated admission and profile lease |
| Direct public Island join, wrong source, forged/replayed ticket | Do not load a profile, build a factory or claim ownership; bounded return to Entry or explicit denial. Avoid a teleport retry loop |
| Two unrelated owners concurrently join | Different canonical island IDs and routes. Neither can see/claim/write the other's state; failure means Retry, never a shared spare plot |
| Same owner enters from two servers or a reserved identity has multiple instances | Active route binding plus ProfileStore lease admit at most one writer. Losing instance waits/retries with no default profile; no forced lease takeover |
| Teleport init fails or times out | Keep a non-economic Entry session; expire/cancel its ticket. Retry with fresh ticket and same validated route or a safely allocated replacement |
| MemoryStore is unavailable before entry | Fail closed with retry; no fallback to first-player ownership. Directory loss never implies absent durable progress |
| Active route heartbeat cannot be renewed | Freeze admissions. If route validity expires, stop accepting mutations, fence/close through ProfileStore; no parallel replacement writer until normal lease rules permit it |
| Owner leaves during load/recovery or final save | Cancel admission; in-flight load retains cleanup responsibility. No playable world for a failed load. Preserve existing unknown-write quarantine and bounded release |
| Disconnect, reset, reconnect, server crash | Reset uses the same admission/island; reconnect may use a fresh runtime after lease release/expiry. Reconstruct from saved state, not Instances. Do not duplicate jobs, models or starter grants |
| Unknown save/release result | Do not mint a new island or release someone else's route. Profile becomes unwritable until durable outcome is reconciled; conditional directory cleanup matches generation + JobId |
| Closing route | Block new admissions, stop mutations, save/release using existing protocol, then destroy presentation. Stale cleanup cannot remove a successor's directory record |

Proposed owner-disconnect policy for future guests: close the owner session and return visitors to Entry; no guest takes over. Guest capacity and final UX remain owner decisions. Do not set platform MaxPlayers=1: B/C admission allows **one owner and zero guests** while capacity remains separately configurable. Future Hub is a new role/place with no owner-profile writer.

## 4. World and compatibility contract

Proposed server-only interfaces (names describe the boundary, not implemented code):

- `Admission.resolve(player, serverContext)` returns a verified immutable owner/session context or a denial.
- `IslandWorld.new(config, context, catalog, callbacks)` creates exactly one owner world; `attachOwner`, `releaseOwner`, `updateOwner`, `canInteract` require that same context and Player.
- `context = {islandId, ownerUserId, slotId, sessionGeneration, role}`. Client requests do not select a context.
- A read-only logical anchor resolver maps stable station/service ID to island-local transform. Worker interpolation resolves from/to IDs through it. Travel visuals never alter haul duration, reservations, cargo arrival or offline accounting.
- Transitional `world.owners[userId]` or a one-element `world.plots` may support old renderers temporarily, but neither allocates/authorizes ownership. Remove PlotIndex-based authorization. Numeric visual shims are documented and removed after all consumers use IslandId.
- Client attributes and receipts carry island identity/presentation generation for filtering only. The server still derives all economic identity. Delayed effects from a destroyed world are discarded.

B keeps **all 13 station IDs**: crystal, garden, mine, distillery, cauldron, logistics, garden2, cauldron2, distillery2, mushrooms, berries, press, centrifuge. Preserve instance IDs `legacy:<slotId>` and offsets from Config. Level-zero slots remain logical anchors, not visible abandoned construction pads.
Service anchors warehouse `(-8,2,-30)`, orders `(10,2,-30)`, altar `(27,2,-32)`, blueprint `(0,2,10)` stay available to existing rules but need not become greybox props. Preserve the crystal at `(0,3,-2)` and safe spawn `(0,1,20)` in island-local space.

Build the terrain, safe boundaries, paths and limited silhouettes once on the server. Remove Bazaar, its prompt/sign, seven other plots, legacy barriers/signs/pads and their collision from actual generation. Do not merely hide them with AG75 SimplifiedScene. Use an island presentation branch for that mode; retain legacy rollback mode for comparison.
Keep one EnvironmentView owner, quality/Reduce Motion, original lectern VFX, AG75 cards/navigation and Green Slime animation lifecycle. No new lights/textures/asset uploads in this design. Resolve ground/weather/camera targets from the island model instead of global eight-plot scans.

## 5. Personal Market and access

Current `RPGNavigation` Inventory/Bazaar tab routes to M4 exchange UI. The personal market needs explicit content and authorization, not just a new label.

| Existing intent | Proposed personal Market access | Preserved checks |
| --- | --- | --- |
| `exchangeEssence` | Owner may invoke from Inventory → Market without crystal distance | Existing amount/rate/balance/sequence rules; no extra currency conversion |
| `buySeed` | Owner UI access without garden distance | Existing seed allowlist, quantity, Gold, capacity, request validation |
| `shopFamiliar` | Existing guaranteed choice offers via owner UI without altar distance | Existing price/stats, policy, inventory cap, provenance, idempotency |
| `buyEventGold` | Existing earned-Gold fixed offers only; do not broaden offer availability | Existing schedule/stock/price, durable transaction/receipt rules and acquisition restrictions |
| Other production, upgrade, summon, fuse, contract and paid-prompt intents | Keep existing authorization/location requirements unless separately reviewed | No generic `inRange=true` or client-supplied access mode |
| M4 invites/offers/confirm; purchase prompts | Remain OFF under existing settings | No physical Bazaar fallback that activates P2P; no new Robux products |

The four personal operations reuse their existing server handlers; no new prices, sale modes or currency sinks. UI opens safely even with no physical Market. Add a narrow server policy `canUsePersonalMarket(admission, actualPlayer, intent)` before the existing action checks: owner, active/alive, writable profile, lifecycle/rate limits and trade/value locks. Everything outside the allowlist retains existing access rules. A visitor cannot purchase into the owner's profile or receive its inventory snapshot.
Remove `World:inBazaar` from personal-market paths. M4 may keep a denied compatibility callback while disabled; its persistent recovery must still operate without a Bazaar. Later Hub trading requires a separate proximity/policy design and approval. Existing NPC contracts, brewing and auto-sales stay unchanged.

## 6. Proposed V9 geographic state — C only

Actual baseline: `Config.schemaVersion = 8`; profile keys already belong to UserId; V8 `layout` and `temple` are validated projections. **Do not rewrite them**. Envelope `schemaVersion=1` is separate from the profile's schema version and remains 1.

Proposed profile version 9 adds only `island`. Reconfirm version allocation before C if another schema task has landed. Closed-key shape:

```luau
island = {
  version = 1,
  id = "u:123:primary", ownerUserId = 123, slotId = "primary",
  templateId = "personal_v1", templateVersion = 1,
  unlockedSectors = { core = true }, -- approved progression may also include east_garden
  placements = {
    ["legacy:crystal"] = {
      slotId = "crystal", sectorId = "core",
      x2 = 0, y2 = 6, z2 = -4, rotation = 0,
    }, -- exactly the 13 existing placement IDs in C, including unbuilt stations
  },
  sequence = 0,
  -- last omitted until a confirmed island operation:
  -- last = {requestId=1, action="unlockSector", sectorId="east_garden",
  --         expectedRevision=0, resultRevision=1}
}
```

`x2/y2/z2` are signed integer half-stud units, preserving current 1.5-stud heights exactly; rotation is 0..3 quarter-turns. All coordinates are **island-local**, never server-world positions. C placements reference `profile.layout.placements[slotId].instanceId`; they are geographic projections, not a second collection of station levels/jobs/ownership. Legacy placement values must match the frozen V8 projection exactly. Moves/new production instances belong to C02 and require a later schema contract.

Validation: owner equals profile UserId and ProfileStore expectedUserId; canonical id/slot; known template/version and known sector IDs only; exactly 13 unique placement references, each station present once; finite bounded integers; valid sector/bounds/connectivity; closed keys throughout. Proposed hard geographic bounds ±1024 half-studs per axis, at most 16 catalog sectors, only the two catalog sectors in this slice, exactly 13 placements, canonical encoded island projection at most 16 KiB. These are implementation safety ceilings, **not** purchased capacity or approved progression counts. Validate before allocating Instances and before writes; reject oversize/malformed data rather than truncate it. Do not add ACL or paid fields with permissive defaults in V9.

### Sector catalog and concrete QA geometry (proposal, not approved balance)

Bounds, transforms, prefab names, buildability and connections come from a versioned **server catalog**, never from saved/client arbitrary meshes. Save only known unlocked IDs and placement references. No runtime fetching of client-chosen models.

| ID | Local geometry in studs | Prerequisite / flags | Navigation |
| --- | --- | --- | --- |
| `core` | Origin `(0,0,-8)`, terrain envelope x `[-42.5,42.5]`, z `[-49.5,33.5]`; old buildable x `[-38.5,38.5]`, z `[-45.5,29.5]` | Always unlocked; baseline factory buildable; original 13 anchors preserved | Safe spawn, central temple and service routes reserved |
| `east_garden` | Origin `(58.5,0,24)`, 32×32 terrain: x `[42.5,74.5]`, z `[8,40]`; buildable interior x `[46.5,70.5]`, z `[12,36]` | Proposed free unlock at existing phase/temple level 2, no separate charge; no production station grant | Shared boundary with core; reserve connector x `[34.5,46.5]`, z `[20,28]`; exclude path from placement |

The core preserves the existing clearance because shrinking it around built legacy stations would strand saves; it is compact relative to the former 420-stud shared world. New profiles show only actually available structures. Do not relocate legacy stations to make an artificially tiny new footprint. The east connector avoids existing station waypoints; B/C still must validate full collision footprints and path reachability in native QA, not infer clearance from points alone.

One C vertical slice: an allowlisted deterministic terrain prefab, safe connector, stable unlocked ID and rejoin reconstruction. No building placement editor or extra production bonuses. Proposed phase-2 owners receive the geometric entitlement during migration/new snapshot synchronization; phase-1 owners can unlock after existing progression. Exact threshold, footprint and reset semantics are D2/D3 below, so C cannot implement them until reviewed.
Until C02 changes that contract, eligibility reads authoritative `profile.phase`; the temple is its projection, not a second paid upgrade track or a client-provided level. Do not change existing phase prices or promote phase from a temple/UI value.
Server validates prerequisite, owner/lease, expected revision, quota, already-unlocked state, prefab bounds, overlap, reserved paths and connectivity before a single-profile transaction. Create the visual sector only after confirmed save; reconstruct it if the client misses the acknowledgement. Repeated same request returns its recorded result; conflicting payload/revision fails, old requests cannot replay; monotonic sequence is not reset by Rebirth. A current-generation duplicate unlock is also an idempotent no-op, never another terrain model or charge.

### Migration, conservation and rollback

1. Capture fixture/backup evidence in isolated QA. Do not rename or point QA at `PotionTycoon_M0_dev_v1`, even though its name says dev. Stage B keeps V8; no island state is persisted yet.
2. Preserve V1→V8 transformations exactly. Refactor their final version assignment carefully: `projectV8` currently uses `config.schemaVersion`; simply bumping Config would incorrectly label a V8-only result V9. Pin the historical intermediate result to 8 and add a separately validated 8→9 step, with regressions for all versions.
3. Validate historical schema and collisions before adding fields: any pre-V9 profile already carrying `island` is ambiguous and rejected. Pure migrator on a clone; no clock/RNG, grant, economic command, external API or yielding inside UpdateAsync.
4. Derive canonical identity from validated owner; copy every V8 field unchanged; add catalog-derived unlocked geography and the 13 projections (`x2=2*x`, etc.), then validate complete V9. Future versions/templates/unknown fields, missing anchors or mismatched owners fail closed. Running migration again on valid V9 is a no-op.
5. `ProfileStore.load` currently calls `_recordValid(..., true)` inside UpdateAsync before checking the existing lease; that may evaluate the pure migration even if a competing lease later rejects the write. Preserve validation and lease fencing: only a successful conditional update commits a migration. Never migrate on save/release or replace invalid data with defaults.
6. Preserve money, inventories, RNG, pet/cauldron serials/locks/provenance, all station data, in-flight cargos, route cursors/timers, order reservations, pending trades, receipt histories, purchases, starter choice/budget flags and lastSimulatedAt. Compare V8 to V9 with only schemaVersion/island removed **before** offline advancement, then compare identical offline simulation results. No reset/newProfile on load error; defaults only for a confirmed absent key through the existing protocol.
7. Retain unchanged M4/M6 journals and recovery ordering. A geography migration cannot consume or release a trade/receipt lock. Existing cross-profile journal recovery retains its reviewed coordinator and lease rules; routing grants no new bypass or profile authority. Reject economic mutation while unresolved; no world exposure before safe recovery. Unknown migration/write outcome follows existing reconciliation/quarantine, not a second grant or second profile.
8. A rollback removes docs only. B rollback selects the inherited V8 presentation/routing fixture before a session starts; never hot-switch ownership. C **cannot** roll back to V8 code on V9 data: use a V9-compatible roll-forward/read-only recovery or stop admissions. No automatic down-migration or backup overwrite after possible valuable writes. Preflight compatibility before rollout and keep the old writer out of the migrated QA namespace.

### Rebirth decision before C

Current whitelist would accidentally preserve an added island object. Proposed rule: stable island identity and 13 references survive; free sectors derive from the reset phase and therefore relock. Rebirth increments the island sequence and clears only its last unlock response, so pre-Rebirth requests cannot unlock land again through a cached success. It never resets the monotonic sequence or clears existing economic receipt histories. Preserve all existing retained collection/progression/receipt rules. No economic building may be lost in a relocked sector: C has no relocated stations; future C02 must define safe relocation or block Rebirth until resolved. Paid entitlements, if later introduced, live under reviewed permanent-rights rules and are never erased by a free-sector reset. **This proposal is not approved; no Rebirth code changes in A/B.**

## 7. Future visitors and paid areas — interface only, disabled

Proposed `authorizeIslandAction(actualPlayer, admission, action, target)` defaults to deny. Roles are not client arguments:

| Role | Proposed authority | B/C status |
| --- | --- | --- |
| Owner | Own allowed intents, land changes and invites after their own gates | One verified owner only |
| Invited visitor | View public presentation and navigate; no inventory snapshot/economic writes | Denied; invitations not implemented |
| Scoped builder | Future allowlisted decorative edits in a designated sector, versioned grant, audit/revert history | Denied; requires owner approval and separate durable edit protocol |

Revocation must be checked on every mutation, with membership revision after yields; stale invite/rejoin never restores a revoked grant. No guest administration, storage/Gold/manufacturing, item transfer, ownership or paid land on another owner's island. Owner-revert of future guest edits must be conflict-safe, not a snapshot that overwrites newer economic state.
Future `Entitlements.canUseArea(ownerUserId, slotId)` may read verified permanent owner rights: Double Island Game Pass or idempotent Developer Product slots are possible separate designs. No SKU, price, receipt handler, paid-right flag or purchase prompt is created now. Production advantage vs cosmetic capacity remains unresolved. All satellite access follows the same owner writer contract.

## 8. QA path, stage deliverables and acceptance

**Namespaces/permissions:** default Studio remains MemoryBackend. Proposed future private QA names: `PotionTycoon_AG76_QA_v1` and isolated AG76 QA trade/receipt journals + MemoryStore key prefix. Journal *protocols* stay unchanged; never let QA recovery scan existing journals. Deployment must fail closed if QA env/allowed experience-place IDs or namespace isolation do not match. No namespaces are created or settings changed in A.

Roblox now documents `TeleportAsync` testing in Studio Test/Team Test, with different JobId/PrivateServerId behaviour and possible ReservedServerId mismatch there. Use a separately gated test-context adapter and record its limitations; never relax live identity checks based on client input. Such tests cannot prove production admission/fencing. Full native routing still requires the separately approved **published private QA** environment from Issue #53; this task does not authorize creating/publishing it or changing access settings. See [teleport testing and limitations](https://create.roblox.com/docs/projects/teleport) and [MemoryStore's temporary role](https://create.roblox.com/docs/cloud-services/memory-stores).

| Stage | Deliverable / gate | Status in A |
| --- | --- | --- |
| A | This ADR, source inventory, topology supersession, test plan, stacked docs Draft PR; inherited portable checks/build | Documentation candidate; exact results in PR |
| B | Second stacked Draft PR; actual single-owner world, admission abstraction, Market UI, V8-only memory fixtures, ordinary game Play, reproducible isolated QA place | GATED on D1 routing/QA design review; no live Teleport rollout |
| C | Third stacked Draft PR; reviewed additive migration, one deterministic expansion, save/rejoin and fault fixtures | GATED on migration review, D2/D3 and B; not C02 completion |
| Later | Invitations/ACL UI and private live routing QA; Hub; then paid areas if separately approved | Deferred; runtime OFF |

Future test matrix (all unexecuted in A; portable tests cannot satisfy native rows):

| ID | Required cases / assertion | Where / stage |
| --- | --- | --- |
| T01 | Two owners, same-owner concurrent arrivals, direct joins, forged owner/ticket, expired/replayed tickets, cancellation/late callbacks; no cross-owner snapshot/write | Pure routing/admission fault fixtures B; real separate private servers later |
| T02 | Directory loss, teleport failure/retry exhaustion, generation replacement, split runtime identity, profile lease collision/expiry, unknown release | Portable adapter faults B/C + private backend routing QA |
| T03 | Exactly one island/lectern; no old Bazaar/plot/sign/collider; safe walk/jump/camera/reset; owner respawn after death/rejoin | B ordinary Studio Player and multi-client rejection fixture |
| T04 | AG75 fullscreen starter choice once, +5 click, first full production/order/automation cycle, both Green Slime Idles, Tab/P/G/touch; all 13 stations and anchor lookups | B inherited portable + ordinary Studio Play; real phone remains separate |
| T05 | Market four allowlisted operations at arbitrary owner location; normal balances/rules/retries; wrong owner/guest/closing/locked denial; summon/build still retain their guards; M4 and purchases OFF | B portable + ordinary Play |
| T06 | V1…V8 fixtures including new/migrated starter, all phases/epochs, partial jobs/cargo/orders, locks/receipts/collections; exact economic conservation, idempotent migration; identical offline advance | C pure migration/integration fixtures |
| T07 | Corrupt/future/oversize save, unknown island fields, ambiguous pre-V9 island, bad owner/template, NaN/fractions/duplicate/missing station refs; unknown DataStore writes, retry/rejoin/recovery | C ProfileStore fault injection + isolated real QA backend |
| T08 | One sector unlock, duplicate/conflicting/stale request, quota, under-level/forged/free coordinate, overlap/path block; save before visual grant, restart round-trip, no duplicate Instances | C portable + memory restart harness + native private rejoin |
| T09 | Approved Rebirth free-sector behaviour, retained collections and future-right fixtures, pending trade/receipt denial, no reset of operation sequence or repeated permanent rewards | C conservation/fault fixtures; later native backend |
| T10 | Full/Reduced/Minimal/Reduce Motion, mobile landscape/portrait UI, safe bounds; modest vs expanded island instance/replication/memory/render baseline after warmup | B/C native desktop/emulator and real modest phone, separately reported |
| T11 | Windows/Ubuntu inherited Luau/Node + new tests, pinned tools, analysis, reproducible Rojo and exact SHA; build-mode rollback | Every stage; no dropped preservation checks |

Performance procedure: same camera path and graphics quality, 60 s warmup + 120 s traversal/idle, 3 runs per modest/expanded fixture; report median and p95 frame time, peak client/server memory, instance/particle/light counts and replication if available. Compare AG75 baseline on the same device; investigate >10% regression as a diagnostic trigger, not an invented approved mobile FPS target. Synthetic CLI load is not device or real-server acceptance. Use textual metrics/errors, no requested video/screenshots.

Reproduce the A baseline locally: `npm run tools`, `npm test` (includes Rojo), then `node scripts/check-integration-base.mjs` on a clean committed HEAD. The last command deliberately rejects a dirty tree or a verification log from another SHA; do not edit a receipt to bypass it. The inherited output `build/PotionTycoon.rbxlx` is **the unchanged inherited game**, not a Personal Islands preview; the AG75-specific preview remains `build/PotionTycoon-AG75-OwnerFeedback-QA.rbxlx`. B must add a separately named QA project/build so a local test cannot be confused with production. Opening Studio or entering real backend QA is unnecessary for this docs-only stage.

A working-tree verification passed all 1,344 inherited Luau and 14 Node tests, compilation of 253 sources, preservation checks and Rojo builds. Two inherited portable-analysis warnings remain: `LocalShadow` in `tests/c01_economy_v2.spec.luau:232` and `LocalUnused` in `tests/c01_first_session.spec.luau:411`; no runtime changes are made to silence them. Documentation scope/local-link/code-fence checks and `git diff --check` passed. Final clean-HEAD local/CI results and repeat-build receipt belong in the PR. New island acceptance tests are specified above, not falsely counted as implemented/passing.

## 9. Concrete owner review gates

| Gate | Proposal to review | What it blocks |
| --- | --- | --- |
| D1 — routing and QA | Entry + reserved one-owner Island; future Hub separate; B local memory admission fixtures, no live place/settings change; direct untrusted entry denied; existing profile lease final writer fence | Approval of this A design before B |
| D2 — free geometry/progression | Compatibility-sized core above plus one 32×32 east sector at existing temple/phase 2, no new charge; later sector counts/themes deferred | C geometry/eligibility; not an approved balance change |
| D3 — Rebirth | Reset free progression sectors to reset-phase availability; retain stable identity/history; future paid rights permanent under a separate approved schema | C persistence/Rebirth |
| D4 — visitors/lifecycle | Initially social-only in a later feature; propose up to 4 invited visitors; owner departure returns visitors to Entry. B/C guests remain disabled | Guest work only; no construction/co-production implied |
| D5 — paid capacity | Leave price, area count, cosmetic vs production benefit and SKU type undecided; no implementation | Future monetization only; does not block A/B/C free scope |

Do not request permission to merge or publish as part of these design decisions. A is reviewable on its own; B/C remain separate Draft PRs after their gates. CI success does not mean STUDIO VERIFIED, OWNER ACCEPTED or PUBLISHED.
