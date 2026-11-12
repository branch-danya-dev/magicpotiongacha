# Milestones

> **Live status corrected 2026-11-12:** This file keeps historical M0–M7 planning and evidence. Use [PROJECT_AUDIT_2026-11-12.md](PROJECT_AUDIT_2026-11-12.md) for the verified last task and implemented-vs-live state, [RELEASE_ROADMAP_V2.md](RELEASE_ROADMAP_V2.md) for the v1.0 product goal/stages, and [AGENT_WORK_QUEUE.md](AGENT_WORK_QUEUE.md) for current agent task IDs. C00/C00b and C01 **are implemented as code candidates** on downstream Cursor branches; they are not published or fully live-accepted.

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

## Next product redesign — Core Loop V2 (C00/C01 code candidate; C02–C08 pending)

Owner direction dated 2026-11-06. **Status as of 2026-11-12: C00/C00b and C01
IMPLEMENTED/CODE CANDIDATE; C02–C08 OPEN; live acceptance BLOCKED.** V8 schema,
C01 gameplay and first-session economy are now present on downstream Cursor
branches, but this does **not** constitute merge, full Studio acceptance,
monetization approval or publication. Preserve the M0–M6 baseline and separate
M7 07D art gate. [Target mechanics](CORE_LOOP_V2_SPEC.md) and
[the original C00–C08 task definitions](CORE_LOOP_V2_CURSOR_BACKLOG.md) remain the
design contract; use [AGENT_WORK_QUEUE.md](AGENT_WORK_QUEUE.md) for *current*
implementation status and next tasks.

1. **C00/C00b — code candidate:** inventory existing invariants and establish V8
   migration for legacy fixed stations, three granted starters, in-flight cargo
   and persistent inventory. The written contract is
   [CORE_LOOP_V2_C00.md](CORE_LOOP_V2_C00.md). Runtime V8 migration and portable
   tests exist; live DataStore migration remains unverified. Release switches stay off.
2. **C01 — code candidate, live QA open:** starter Gold, exactly one selected
   new-profile familiar, seed market/plant timers, first cauldron, Healing sale,
   affordable automation and recovery routes are implemented and portable-tested.
   The normal Studio/mobile/reconnect/economy acceptance remains open.
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
