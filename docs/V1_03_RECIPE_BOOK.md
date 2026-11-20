# V1-03 — Recipe Book and Alchemy Economy (Studio QA)

**Base:** `feat/v1-02-universal-garden` @ `0891fe5a7ba3c2ac2b4bd4f227d95250671faa01` / Draft PR #68. This is a **stacked, standalone Studio-memory-only code candidate**, not a new live DataStore schema or permission to merge/publish. The inherited release `src/` and `default.project.json` remain intact.

## Product contract

- Six ordered alchemy classes: **Новичок / Подмастерье / Адепт / Эксперт / Мастер / Грандмастер**. Every class has a tunable minimum craft XP; recipe class and required cauldron tier are independent gates.
- Six output grades: **Отвратительная / Простая / Добротная / Превосходная / Идеальная / Мастерская**. This is a quality **prefix**, not the recipe class. A separate rarity field is deterministic from grade and optional modifier. No random pay-to-win/odds or hidden per-pet boosts.
- Every recipe is uniquely keyed and uses the same model: **base + mandatory core + optional modifier**. An optional ingredient is never required to brew its plain recipe. It affects the suffix, quality, sale value, rarity, and placeholder effect metadata.
- **Gold** buys crop seeds/beds and registered alchemy bases/reagents (water, fire/frost salt, moon dew, Bayun whisker). **Essence** pays for a brewing batch. The source ingredients come from the shared V1-02 garden raw inventory; base/reagents have their own bounded supply inventory. Only successfully validated batches are charged.
- A brewing job consumes costs once when started and finishes in the existing server-owned one-second simulation, including offline progression within the inherited 7200-second cap. One cauldron = one active V1 job.
- Successful brewing produces one **individually owned potion record**, not immediate Gold. `sellPotion` is a separate authenticated intent; it removes that exact item once and adds its validated value. Each created item keeps a stable owner-specific serial. A full potion inventory postpones completion rather than deleting the paid batch.
- Potion effects are **intentionally metadata stubs** (`effectId`, `effectStrength`, `effectDuration`, `visual`). No actual Essence buffs or 3D effects are invented or enabled yet; compatibility for later gameplay and cosmetic VFX is preserved.
- Ingredient from a familiar such as `bayun_whisker` is a **purchasable material**, not a productivity stat and does not require owning the corresponding familiar. Existing familiars remain cosmetic in modern QA mode.

## QA content (not final pricing)

| Recipe | Class / machine | Base | Required core | Optional | Essence / brew time | Indicative sale |
|---|---|---|---|---|---|---|
| Настойка исцеления | Новичок / Cauldron 1 | Water x1 | Mandrake x2 | Moon Dew | 15 / 6s | 250 Gold |
| Настойка Огненного танца | Новичок / Cauldron 1 | Water x1 | Mandrake x1 + Fire Salt x1 | Bayun Whisker | 18 / 10s | 180 Gold |
| Настойка Северного укуса | Новичок / Cauldron 1 | Water x1 | Antarctic Biter x1 + Frost Salt x1 | Moon Dew | 28 / 14s | 270 Gold |
| Настойка Лунного эха | Подмастерье / Cauldron 2 | Water x2 | Mandrake x1 + Antarctic Biter x1 + Moon Dew x1 | Bayun Whisker | 45 / 28s | 430 Gold |

Rank thresholds, grade multipliers and reagent prices in `qa/alchemy_v1/Catalog.luau` are **provisional**. Classes III–VI have no invented recipes yet: the book renders them as future-content slots.

## Technical structure

- `qa/alchemy_v1/Catalog.luau`: recipes, classes, rarity/quality tables, supply shop and visual metadata.
- `qa/alchemy_v1/AlchemyV1.luau`: pure domain for strict validation, one-time consumption, deterministic timed craft, individual potion ownership and exact-once sale.
- `qa/alchemy_v1/PotionBook.client.luau`: real interactive book with rank requirements, ingredient shop, optional toggle, craft status, inventory and sell controls; no client-side awards.
- `scripts/apply-v1-alchemy.mjs`: generated QA integration into the **existing** Server/Protocol/Access/Factory and guide. Legacy C01 instant-sale controls are hidden and new V1 manual `brew`/`setAuto` intents denied. Prepaid historical in-flight jobs can still finish at their old rate; new V1 legacy auto cycles are suppressed.
- `profile.alchemyV1` is a **QA-only state extension** containing XP, supplies, discovered recipes, pending job and owned potion serials. In the live release it will need an approved, versioned **V9+** migration. No production V8 save write was performed.

## Run and verify

```sh
npm run tools
npm test
node scripts/build-alchemy-first.mjs --owner-user-id=YOUR_ROBLOX_ID
```

Build artifact: `build/PotionTycoon-Alchemy-First-QA.rbxlx`. Tests: `qa/alchemy_v1/run.luau` together with inherited `qa/alchemy/run.luau`, `qa/garden/run.luau`, Windows/Ubuntu full CI and Rojo build.

**Studio/F5, multiplayer, mobile viewport, live DataStore, user art approval and economy balance remain NOT VERIFIED** until real evidence. No Meshy models, published asset changes, payments, trading or merge. Revert to exact V1-02 SHA above if needed.
