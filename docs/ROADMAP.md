# Milestones

| Stage | Scope | Exit gate |
| --- | --- | --- |
| M0 / M0.1 (dependency) | Repository/toolchain, deterministic core, validated requests, safe profile adapter, greybox playable chain | CLI/CI passed; Issue #2 live gates still BLOCKED |
| M1 (implemented, Draft / live acceptance BLOCKED) | Complete first factory loop, saved tutorial, quest-crate/Essence routing, failure/status UI, provisional balance traces | Portable coverage and exact-SHA Windows/Ubuntu CI; Studio, real DataStore, mobile and scale gates still required |
| M2 (implemented, Draft / live acceptance BLOCKED) | Ten familiar species, instance stat distributions, fixed shop, deterministic Fuse, PolicyService, V3 migration and durable commands | 203 inherited + 113 new portable tests; exact-SHA Windows/Ubuntu CI in Draft PR; live disclosure/policy/DataStore/mobile/2–8-client gates required |
| M3 (implemented, Draft / live acceptance BLOCKED) | Four phases, 13 fixed slots, parallel lines, three new potions, reachable NPC offers, guaranteed rare cauldron, V4 migration | 316 inherited + 88 new portable tests; three zero-resource economy traces; 8-plot synthetic workload; exact-SHA Windows/Ubuntu CI in Draft PR; Studio/real backend/phone/2–8-client gates remain |
| M4 (implemented, Draft / public trading disabled) | Same-server Bazaar, two-party exact-offer review, durable reservations/decision/recovery, bounded registry and V5 migration | 404 inherited + 177 new portable tests; all 16 write-boundary faults, 8-user synthetic load; exact-SHA Windows/Ubuntu evidence in Draft PR. Real DataStore crash/reconnect, PolicyService, phone and 2–8-client acceptance BLOCKED; TradingEnabled=false |
| M5 (implemented, Draft / live acceptance BLOCKED) | Atomic Rebirth, three repeating epochs × four phases, earned Time Shards/perks/direct-choice altar, UTC dailies, seven-day calendar and V6 migration | 581 inherited tests plus M5 conservation/replay/trade/UTC/failure tests; nine zero-admin routes, three 7200-s parity checks; exact final-SHA Windows/Ubuntu evidence in Draft PR. Live Studio/backend/policy/phone/2–8-client checks BLOCKED; no retention claim |
| M6 (implemented, Draft / purchases and trading disabled) | Fixed seasonal Wolf/cauldron and permanent cosmetic through earned Gold or separate native product/pass; V7, durable receipt proof, queued delivery, immutable SKU binding | 696 inherited + 114 additional cases = 810 tests; three zero-admin routes, four-boundary failures, both-platform exact-SHA CI in Draft PR. Real receipts/pass/DataStore/policy/phone/2–8-client acceptance BLOCKED; all SKUs=0, no merge/publication |
| M7 | Finished low-poly art/VFX/audio/mobile polish | Measured mobile and eight-player performance budgets |

This is sequencing, not a promised completion date. Fixed-slot art can be replaced without rewriting the domain model. Trading Plaza, inter-player Robux transactions and additional themes need separate product/platform review; they are not part of M0.

## Next product redesign — Core Loop V2 (design only, Cursor)

Owner direction dated 2026-11-06. **Status: SPECIFIED / NOT IMPLEMENTED.**
The existing M0–M6 implementation and M7 Draft PR #17 remain intact; there is no
new gameplay build, updated save schema, approved balance, monetization, merge or
publication from this plan. [Target mechanics](CORE_LOOP_V2_SPEC.md) and
[ordered implementation / acceptance tasks C00–C08](CORE_LOOP_V2_CURSOR_BACKLOG.md)
form the exact Cursor handoff.

1. **C00:** inventory existing code invariants, establish V8+ migration plan,
   define safe behaviour for legacy fixed stations, three granted starters,
   in-flight cargo and persistent inventory.
2. **C01:** preserve early clicker + Gold/Essence progression while adding starter
   Gold, exactly one selected new-profile familiar, seed market/plant timers,
   first cauldron and affordable automation. No required manual resource chore
   after upgrades; no softlocks after an unwise purchase.
3. **C02:** server-validated free station placement, quick build mode, temple
   upgrades and build-area expansion inside unchanged eight-plot ownership.
4. **C03:** keep/sell/contract potion routing; physical bottle inspection,
   Warehouse/Laboratory/Atlas and protected collection persistence.
5. **C04:** capped working-familiar slots, trainable Farming/Alchemy/Logistics;
   Defense reserved for later, no dependence on three workers to progress.
6. **C05:** three contract families (potion, crop, familiar training) with
   server-proof completion, one active order and exactly-once claims.
7. **C06:** optional late-game Enchanted Synthesizer after first legendary brew,
   blocked on owner-approved potion rarity ladder and precise reward policy.
8. **C07:** three-epoch Rebirth, persistent collection/skills and bounded academic
   charms with conservative paid/trading provenance.
9. **C08:** mobile/8-owner/security/persistence acceptance, asset readiness and
   independent monetization safety gates.

**Sequence note:** M7 07D ART APPROVED -> UX #18 -> 08 full island rollout still
requires separate explicit owner decisions. Implement V2 in a separate branch/
Draft PR sequence; do not use V2 as permission to merge/publish M7 or enable
trading and paid random items.
