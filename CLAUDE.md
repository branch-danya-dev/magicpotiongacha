# Claude Code — Potion Tycoon current development context

**START HERE.** The canonical working branch for this handoff is `handoff/claude-code-v1-03`, forked from the latest owner-tested development line `fix/v1-03-restore-sky-backdrop` @ `49cc43e1c09ebe638647107506f457fc86d1675a` (Draft PR #71). It includes the entire stacked ancestry through V1-01, V1-02, V1-03 and Studio P0. **`main` is only the bootstrap repository, not the game.** Do not start from `main`, `integration/ag00-base` or an old C00/C01 branch.

Read `docs/CURRENT_V1_03_HANDOFF.md` before proposing or changing code. That document supersedes older *status claims* in `README.md`, `docs/PROJECT_AUDIT_2026-11-12.md`, `docs/RELEASE_ROADMAP_V2.md` and `docs/AGENT_WORK_QUEUE.md` for the **current V1-03 QA build only**. Historic technical contracts and security requirements in those files remain relevant.

## Absolute rules

1. This is a **Studio-memory QA prototype**, not a published game. Never silently merge/publish, enable live DataStore, Marketplace/Robux/trading, or introduce migrations/paid randomness. Require explicit owner approval for those changes.
2. The **actual V1-03 game is NOT built by `default.project.json`**. The older `src/` remains the V8 M0–M6 basis, and V1 features are assembled into an isolated candidate through `scripts/build-alchemy-first.mjs`. Do not overwrite production `src/` blindly or confuse the historical `build/PotionTycoon.rbxlx` with the current place.
3. The generated V1-03 chain is:
   `build-forest.mjs` → `build-alchemy-first.mjs` → `apply-v1-garden.mjs` → `apply-v1-alchemy.mjs` → `apply-v1-stability.mjs` → Rojo `.rbxlx`. Base extractor and pet de-buffing are assembled in `build-alchemy-first.mjs` before those three overlays. The sky-restoration correction lives in the P0 stability overlay.
4. Keep all currency, crafting, harvest, inventories and profile validation **server authoritative**. Preserve deterministic online/offline advancement and exactly-once debits/credits.
5. **Familiars have no compulsory first-choice or production bonuses in V1 QA.** Do not delete saved pets, stats or historical provenance. Choosing a companion may be reintroduced only in a later approved feature.
6. The owner explicitly deferred new Meshy model imports. Focus on mechanics, UI, QA, economy and frame stability unless asked to integrate particular assets. Do not silently upload or replace textures.
7. Sky composition is high-risk: retain the original R3 CloudOcean banks, CloudOcclusion, AtmosphericHaze, CloudDrift, native Terrain.Clouds and original `Lighting:GetMoonDirection()`. Previous P0 deleted the clouds and broke the background. `scripts/check-v1-sky-restore.mjs` guards against this exact regression; the original black cloud seams remain an OPEN visual issue. Any sky change must be isolated, tested and approved from real Studio screenshots.
8. Existing Studio-memory owner gate is intentional. **Never** disable ownership or embed a permanent personal UserId or secret in model/project instructions. Supply `--owner-user-id=<YOUR_ROBLOX_USER_ID>` only when building a personal Studio place. CI's `-1` is test-only and kicks ordinary owner accounts.
9. Use Git feature branches, narrow changes, portable Luau unit tests, CI on Windows and Ubuntu. Report separately: CODE / CI, Roblox Studio F5, performance, mobile, persistence, owner visual acceptance and publication. A CLI pass is not an art/FPS PASS.
10. Do not commit API keys, proxy URLs with secrets, `.env`, private credentials or generated `build/`/ `.tools/`. Claude Code's model and API gateway configuration is external to this repository.

## Reproduce the exact V1 candidate

Windows PowerShell or another supported shell; requires Git, Node.js **22+**, npm and Roblox Studio. The pinned tools are downloaded by the project:

```sh
git switch handoff/claude-code-v1-03
npm run tools
npm run handoff:verify
npm test
node scripts/build-alchemy-first.mjs --owner-user-id=<YOUR_ROBLOX_USER_ID>
node scripts/verify-handoff.mjs --built
```

Open **`build/PotionTycoon-Alchemy-First-QA.rbxlx`** in Studio using File → Open from File → Play (F5). Do not open `build/PotionTycoon.rbxlx` for V1-03. No Rojo Studio plugin required for file-based testing. The builder also writes `build/alchemy/build.json` containing exact Git SHA, owner, SHA-256, memory-only flags and build path. Do not use `--reuse-forest` with a different owner or Git SHA.

`npm test` builds in isolated CI owner `-1`; this is correct for automated Luau checks but is not a usable local owner file. The standalone owner build above intentionally rebuilds the forest to stamp the correct ID.

## Current scope and code map

| Area | Canonical current sources |
| --- | --- |
| Immutable production/historic compatibility | `src/shared/Factory.luau`, `Config.luau`, `Protocol.luau`, `src/server/ProfileStore.luau` |
| Passive Essence and no worker buffs | `scripts/build-alchemy-first.mjs`, `qa/alchemy/Policy.luau` |
| V1 Garden and crop registry | `qa/garden/Catalog.luau`, `GardenV1.luau`, `run.luau`; `scripts/apply-v1-garden*.mjs` |
| V1 recipe book, Gold/Essence, potion inventory | `qa/alchemy_v1/Catalog.luau`, `AlchemyV1.luau`, `PotionBook.client.luau`; `scripts/apply-v1-alchemy.mjs` |
| Optional starter, collision, forest static LOD | `qa/stability/`, `scripts/apply-v1-stability.mjs` |
| Authored forest, lunar cycle, sky | `scripts/build-forest.mjs`, `qa/forest/`, `qa/sky-landmark/`, `qa/lunar/` |
| End-to-end verification | `scripts/check.mjs`, `scripts/check-v1-sky-restore.mjs`, `scripts/verify-handoff.mjs`, `.github/workflows/ci.yml` |

**Current mechanical content:** passive Essence +1/sec at L1; mandrake and Antarctic Biter with species-specific water/growth; three independent bed slots; optional sprinkler; six alchemy ranks and six potion qualities; four concrete recipes; optional modifiers, independent potion instances and manual Gold sale. Higher-rank content and potion effects are intentionally stubbed. Current economy numbers are provisional. No production V9 schema or QA save migration is approved.

**Known open technical/art gates:** visual/FPS issues require owner F5 checks; original cloud seams and night/day transitions still need measured diagnosis; stable tree fallback intentionally suspends some wind; all imported Meshy props are outside this build; mobile and real persistence remain unverified. See `docs/CURRENT_V1_03_HANDOFF.md` for the task order and required evidence.

## First turn / agent behavior

1. Print `git status --short --branch`, current `git rev-parse HEAD`, `git log -5 --oneline` and read `docs/CURRENT_V1_03_HANDOFF.md`.
2. Run `npm run handoff:verify` before proposing edits, then the existing full `npm test` before submitting a change.
3. Confirm the requested task, make a separate `feat/` or `fix/` branch from the handoff head, and state what it will **not** change.
4. Never assume an unverified owner screenshot is proof of a fixed issue. If a task concerns rendering/performance, give a reproducible Studio F5 experiment and measured comparison, rather than deleting scene layers.
5. Deliver a small Draft PR, exact SHA and CI evidence; do not merge without instructions.
