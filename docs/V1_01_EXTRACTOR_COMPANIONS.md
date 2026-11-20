# V1-01 — Passive extractor and cosmetic familiars (isolated Studio QA)

**Parent:** `feat/alchemy-first-passive-essence` @ `b8d84ee5b09f973db0e8a87fd9a1da69f35e6cab`, Draft PR #66.
**Scope:** Economy rework of the *generated* Alchemy First QA place, not an overwrite of the historical M0–M6 source or live place. All mutable changes remain in this branch. `src/**`, `default.project.json`, schema V8, saved profiles and purchase/trade policy are not modified because AG-74/AG-76 source-preservation checks guard those baselines.

## Player-facing rules

- Essence comes from the **Botanical Essence Extractor** (preserved logical station id `crystal` for V8 save compatibility). It is passive at 1/sec at tier 1, then 2 / 6 / 18 / 48 Essence/sec. Server-owned online and capped 7,200-second offline calculations remain identical. The server rejects manual click intents in this V1 QA mode.
- The QA scene now shows a small **ExtractorPlaceholder** at the same station anchor; it hides the old Spellbook Lectern, not an uploaded Meshy GLB. The real extractor model will replace this placeholder later, without renaming station ids or changing the economy. V1 brew cube and garden remain placeholders too.
- Familiars remain **owned, selectable, preserved with stats/rarity/provenance and visible in the collection**. A selected starter has a small, local, non-colliding **companion visual placeholder** following the player; the real owl/cat/slime art and ambient behaviors will be integrated separately. This client visualization never grants money, submits requests or changes game state.
- For new V1 QA profiles, server rejects the `assign` action. A saved assignment from earlier V2 play remains present in the profile but contributes no Farming/Hauling/Brewing speed, double-chance, crystal/Essence bonus or slime-byproduct income. No pets are deleted and no stored stat is reset. Historical `legacyGrant` profiles retain the original behavior.
- Built production stations and logistics run at their baseline deterministic rates without worker requirements. **Automatic brewing still requires purchased equipment automation**; no free unlock or infinite recipe outputs. The starter garden remains manually seeded and harvested. The V1-02 watering feature and equipment-based upgrades are separate tasks.
- No protocol, purchase, payment, trading, save schema, or rollback migration is introduced. `Main.client` QA panel omits the worker assignment affordance and reports an equipment-first model. The underlying published source/menus remain unchanged.

## Build and tests

```sh
npm run tools
npm test
node scripts/build-alchemy-first.mjs --owner-user-id=YOUR_ROBLOX_USER_ID
```

Output: `build/PotionTycoon-Alchemy-First-QA.rbxlx` (source-HEAD and owner stamped receipt at `build/alchemy/build.json`). `qa/alchemy/run.luau` tests baseline passive income, denial of manual Essence, worker assignment rejection, invariance to saved worker stats, no slime byproduct, worker-independent source/logistics and purchased auto brewing, and legacy preservation. Full suite runs in Windows and Ubuntu CI. A successful CI proves only the generated code/build, not ordinary Roblox Studio performance or live DataStores.

**Owner Studio acceptance remaining:** open the generated place, press F5, choose owl/slime/cat, confirm companion visual appears, source produces +1 Essence/sec, old click does not grant anything, garden and first Healing still work, no worker assignment is available, equipment logistics can service input without pets, legacy trial is unchanged, no new first-load hitch. No merge or publish; no Robux spend.

## Rollback

Return to `feat/alchemy-first-passive-essence` and reopen its exact SHA's QA artifact. The original branch, `main` and all live saves remain unchanged; this commit only modifies the derived QA build source and tests. The design move to permanently ship V1 must be reviewed and integrated into a new versioned release implementation after the older AG-76 source preservation boundary is retired by explicit decision.
