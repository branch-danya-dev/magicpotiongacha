# Agent Work Queue — Potion Tycoon V2 → Release 1.0

**Дата ревизии:** 2026-11-12. **Актуальный код-кандидат:** `cursor/spellbook-lectern-a4f2` @ `fd49911`.

План: [RELEASE_ROADMAP_V2.md](RELEASE_ROADMAP_V2.md); аудит: [PROJECT_AUDIT_2026-11-12.md](PROJECT_AUDIT_2026-11-12.md); основной контракт: [CORE_LOOP_V2_SPEC.md](CORE_LOOP_V2_SPEC.md). Исторические C00–C08 спецификации остаются обязательными по смыслу, но их чекбоксы **не отражают** уже реализованный C00/C01.

## Как агенту брать задачу

1. Прочитать корневой `AGENTS.md`, аудит и текущий HEAD/ветку. Зафиксировать базовый SHA, существующий uncommitted diff, активные PR и владельца изменяемых модулей. **Не** начинать с `main` как будто там есть M6/C01; он ещё bootstrap.
2. Выбрать **одну** задачу со статусом `READY`, создать отдельную ветку от подтверждённой интеграционной базы. Если одновременно меняются `Factory`, `Config`, `ProfileStore`, `Protocol` или `World`, согласовать последовательность PR и не объединять независимые runtime-schema изменения.
3. До кода записать границу изменения, миграцию, безопасность, rollback/invalid-save сценарии и критерии. Не изменять значения C01 v0.1 без балансового решения и тестов. Не добавлять UI-авторитетные начисления.
4. Выполнить `npm run tools && npm test`; записать **точный SHA**, число тестов, Luau анализ, Rojo place и результат Windows/Ubuntu CI. Отдельной таблицей сообщить нормальный Studio Play, телефон, backend, 2–8 клиентов: `PASS` только с evidence, иначе `BLOCKED/NOT RUN`.
5. Обновить статус **только своей** задачи и приложить evidence в PR. Не удалять чужие изменения. Не сливать PR, не публиковать Roblox place, не расходовать Robux и не включать flags без отдельного разрешения пользователя.

Статусы: `READY` — можно брать код; `CODE_CANDIDATE` — код есть, не прошёл все live gates; `GATED` — нужно решение владельца/предыдущий этап; `OPTIONAL` — не блокирует 1.0; `ACCEPTED` — есть конкретный owner sign-off и проверка.

## Ближайшие конкретные задачи (P0)

### AG-00 — Каноническая интеграционная база

**Статус: CODE_CANDIDATE / BASE VERIFIED, owner merge gate OPEN.** **Depends:** `fd49911` + документация `2c04c8d`. **Files:** документы, CI/ветки и скрипты сборки; экономические алгоритмы не переписывать.

Результат: `integration/ag00-base`, [матрица происхождения и проверок](AG00_INTEGRATION_BASE.md).
Чистая сборка: 1142/0; минимальный обычный Play выполнен на `2c04c8d`.
Точный SHA поставки и Windows/Ubuntu CI фиксируются в Draft PR и
`build/ag00-integration.json`. Новые задачи начинать с прошедшего CI head этой
ветки; `main` и старая M7-ветка не являются текущей базой. Missing Spellbook,
полная C01/asset/mobile/backend-приёмка остаются открыты.

- Проверить, что C00b V8, C01 + экономика/UX fix, UI-01/UI-02A и Spellbook действительно присутствуют и совместимы на одной базе. Сверить remote DAG и PR, не выводить merge-статус из имени ветки.
- Сделать чистую воспроизводимую сборку и минимальный обычный Play-прогон; записать SHA, .rbxlx и ограничения. Привести текущий статус в README/roadmap/acceptance; **не** склеивать весь стек в `main` без разрешения.
- Создать предложенный release-integration PR/branch map и отметить ветви, которым нужен rebase/review; historical M0–M7 не переписывать.

**Done:** один однозначный HEAD для следующих агентов и матрица происхождения/проверок. Отдельный owner merge gate остаётся открытым.

### AG-01 — Spellbook Lectern как воспроизводимый игровой ассет

**Статус: IMPLEMENTED / scoped STUDIO VERIFIED / OWNER GATE OPEN.** **Depends:** AG-00 подтверждён на `7d6d47826e919683ee991c911185215cda0d3d2e`, Draft PR #29, Windows/Ubuntu PASS. **Files:** `assets/props/`, `src/server/SpellbookLectern.luau`, `SpellbookLecternPlan.luau`, импорт/manifest/tests.

Результат: [AG01_SPELLBOOK_INTEGRATION.md](AG01_SPELLBOOK_INTEGRATION.md), Draft PR #30.
Повторное получение GLB и лицензия от 12.11.2026 проверены. Выполнен разрешённый
приватный импорт от addout studio, сохранён нативный `SpellbookLectern.rbxmx`,
23 MeshId подтверждены за группой. Чистая и повторная Rojo-сборки совпали;
обычный Play показал книгу на восьми участках, E начисляет прежние 5 Essence,
возврат старого визуала и режимы качества проверены. 1142 исходных + 13 новых
тестов проходят. Точный HEAD/CI и границы нативных проверок записаны в PR и отчёте.
Нативные mouse/touch/upgrade UI, телефон, реальные 2–8 клиентов, backend и
художественная приёмка владельцем остаются открыты. Публикации/merge не было.

- Устранить зависимость от исчезающего после сборки ручного `ServerStorage.SpellbookLectern`, не подставляя фальшивую геометрию. Выбрать поддерживаемый воспроизводимый путь GLB → private Roblox asset/проверяемый package → загрузка в game/Studio, с проверкой прав и при необходимости явным ручным владельческим шагом. **Не** публиковать исходный модельный файл отдельным Creator Store item.
- Записать source URL/license/SHA-256, точные вложенные MeshParts и материалы, pivot/scale, anchors. Не добавлять скрипты из Toolbox и не ломать конфиг `crystal`/`Essence`.
- Проверить, что runtime visual swap не переносит logical prompt/hitbox и не меняет доступность upgrade/дистанции. Показать обычный Play после **fresh rebuild**, включая fallback при отсутствии private asset/permission.

**Done:** clean checkout + build + Play показывает книгу у каждого plot; UI/highlight, клик и пассив Essence неизменны; доказательство доступно в PR. Если upload/Studio недоступен — явно `BLOCKED` с точной инструкцией владельцу, без заявления полного completion.

### AG-02 — C01 normal Play и устойчивость первой сессии

**Статус: CODE_CANDIDATE / LIVE GATE OPEN.** **Depends:** AG-00, AG-01 для финальных визуальных снимков. **Files:** `src/shared/Factory`, `Config`, `FirstSessionView`, server/client Main, тесты.

- Проверить три пути выбора стартового owl/slime/cat и возврат legacy-аккаунтов с тремя питомцами; Gold 1000 выдаётся один раз, грядка 200, котёл 300, семена 20, Healing 250, автоматизация 500, кристалл L2 900.
- Повторить настоящий обучающий путь с нулевой Essence, неудачной тратой, отсутствующим семенем, пустым/переполненным складом, потерей соединения и сменой сервера; исправлять только воспроизводимые баги.
- Проверить отсутствие ложного повторного Gold/Essence начисления, 7200-с parity без кликов и реакции UI в portrait/landscape. Сопоставить реальные времена игроков с *модельными* числами `C01_BALANCE.md`.

**Done:** обычный Play + mobile-тесты и подтверждённый первый устойчивый idle цикл с документированными recovery маршрутами.

## V2 gameplay delivery

| ID | Stage | Status / dependencies | Конкретный объём и контрольный результат |
| --- | --- | --- | --- |
| **AG-10** | R2 / C02-A | `GATED` AG-02 + D1 | Зафиксировать V9+ schema для station instances и миграцию 13 legacy slots/jobs/cargo с устойчивыми IDs. Portable до/после отказа записи, 8 owners; старые карты и права сохранены. |
| **AG-11** | R2 / C02-B | `GATED` AG-10 | Server-authoritative place/move/rotate/remove/upgrade, owned bounds/overlap/paths/budget; UI preview, presets и touch. Нет покупки/переноса из клиентской картинки без durable server acknowledgment. |
| **AG-20** | R3 / C03-A | `GATED` AG-11 + D3 (stack/unique) | Состояние склада зелий, output route auto-sell/keep/contract; атомарное резервирование/продажа/переключение, миграция старых заказов/стоков без дюпов. |
| **AG-21** | R3 / C03-B | `GATED` AG-20 | Atlas persistent, Laboratory inventory and inspect/hold bottle; визуал on-demand, real item IDs на сервере, защищённые уникальные предметы. |
| **AG-30** | R4 / C04 | `GATED` AG-11 + D2 | 3 *предлагаемых* active slots, 128 owned, Farming/Alchemy/Logistics XP, однократный starter, старые питомцы не теряются, Fuse/paid origin/provenance сохранены. |
| **AG-40** | R5 / C05 | `GATED` AG-20 + AG-30 | Контракты potion/crop/training, достижимость, подтверждение фактического производства/выращивания/XP, safe expiry/claim/replay. Три предложения и один активный контракт. |
| **AG-50** | R6 / C07 | `GATED` AG-21 + AG-30 + AG-40 + D4 | Rebirth новой V2-фабрики, сохранение Atlas, умений и уникального inventory при обнулении временной экономики; атомарный Time Shard и 3 эпохи без дюпа. |

## Art, UX, safety, rollout

### AG-68 — World Look 2.0 / Arcane Forest 2.0

**Status: IN PROGRESS; OWNER ART ACCEPTED: NO; PUBLISHED: NO.** Issue #38.
Base Draft PR #37 `feat/ag67b-soul-absorption-integration` at
`34db02c7a09a0208c881d04ad14c51d0a663e55e`; remote HEAD unchanged, CI
43407466365 Windows/Ubuntu PASS, base worktree clean. Separate branch
`feat/ag68-world-look`. First diagnose the actual ordinary Play AG63 owner,
OFF/A/B/C and inherited texture failures; then implement one visible look within
EnvironmentView. Automatic Studio review only, published release OFF; preserve
time/weather, reversible baseline, quality/motion and original owner restoration.
No server/economy/saves/remotes/HUD/Spellbook VFX/asset ID or rights changes.
No migrations or changed invalid-save handling. Verify paired ordinary-camera
captures, two directions, landscape emulator, live videos, bounded switching and
same-scenario performance. Phone/multiplayer/owner art remain open until evidenced.
No merge, publishing, asset upload or final release activation.

### AG-67B — Soul Absorption production integration and sigil VFX

**Status: IMPLEMENTED/CODE / scoped STUDIO VERIFIED; owner art acceptance OPEN.**
Explicit owner request AG-67B, 2026-11-13, authorizes continuing Stage B despite
the earlier Stage A gate. Base Draft PR #36 `feat/ag67-soul-absorption-prototype`
@ `4a158b96e2b679605e89e2b36fe3425208fea315`, CI 43395509209 Windows/Ubuntu PASS;
remote HEAD verified, local diff empty. Branch `feat/ag67b-soul-absorption-integration`.
Scope: production client VFX owner, stronger original sigil/spirits/pages,
ordinary Studio build enabled automatically, published release disabled,
immediate legacy rollback, finite quality/lifecycle budgets and new tests.
No economy/profile/server/remotes/imported mesh edits or save migration.
The owner approved the exact three-image manifest and confirmed Asset Privacy ON;
all three uploaded to addout studio, typed loading verified in the private
experience and ordinary local Play. Independent permissions UI review is open.
Prior review evidence and legacy VFX are preserved byte-for-byte.
Rollback and invalid-save handling remain unchanged; unavailable textures must
fall back to legacy without hiding the book or replaying receipts. Native Play,
quality, rejection, lifecycle, eight plots, recordings and performance PASS in
ordinary local Play; moving R6/R15, death cleanup and normal respawn PASS.
1254 tests (1233 inherited + 21 new); exact HEAD/CI in the stacked Draft PR.
Real phone/backend/multiplayer remain NOT RUN. Report: `docs/AG67B_PRODUCTION_INTEGRATION.md`.
No merge, game publication or automatic release enablement.

### AG-67 — Spellbook Soul Absorption VFX 2.0

**Status: IMPLEMENTED/CODE (Stage A only) / scoped STUDIO VERIFIED; OWNER ART GATE OPEN.**
Explicit owner specification, 2026-11-13. Base Draft PR #35,
`feat/ag64-landscape-hud` @ `d026c02a3aa56b87e0883d6c9aac0f0854a81cb1`;
Windows/Ubuntu CI 43263392408 PASS, remote HEAD verified unchanged.
Branch: `feat/ag67-soul-absorption-prototype`.
Scope now: original editable sigil + transparent raster, independent rune orbits,
pooled burning pages and chest-targeted soul streams in an opt-in Studio prototype.
The default ordinary Rojo game and all inherited production modules stay unchanged.
No economy/profile/remote/physics/imported mesh edits; old/new comparison required.
Deliver real Studio idle/ritual clips and seal/budget evidence before owner review.
Delivered: [Stage A report and recordings](AG67_STAGE_A.md), original SVG/PNG,
12-second idle and 13.5-second ritual videos at two cameras, 1233 passing tests,
native quality caps / 20 switches / simulated fallback diagnostics. Default game
build remains byte-identical to the base; no production integration yet.
Stage B integration is BLOCKED until explicit artistic approval; CI cannot unlock it.
No merge, publication or external asset upload is authorized.

### AG-64 — Figma Landscape Gameplay HUD

**Status: IMPLEMENTED/CODE / scoped STUDIO VERIFIED / OWNER REVIEW OPEN / PUBLISHED: NO.** Base Draft PR #34,
`feat/ag63-postfx-lookdev` @ `0457a87b5cbff1200d1e96889986198244918213`;
Windows/Ubuntu CI 43243560877 PASS. Branch `feat/ag64-landscape-hud`.
Approved design: Figma `4Qfq1mf8p4oNLVqQH85yfI`, node `7:21`, 844×390.
This explicit request authorizes the HUD task despite the older AG63 next-UI gate;
it does not select or approve a PostFX preset.
Scope: native presentation inside the existing PotionTycoonUI, real snapshot data,
existing menus/intents, receipt-only Essence feedback, responsive safe placement.
No economy/profile/server/Spellbook/PostFX/asset changes. No new internal windows.
Rollback: Workspace `LandscapeHUDEnabled=false` restores the inherited HUD.
Draft PR #35. 1193 unchanged inherited + 26 new tests PASS; repeated Rojo build
matches the native review build. Ordinary Play verified all seven menu routes,
server-confirmed E/tap +5, actual safe book upgrade, bounded feedback, 20 rollback
cycles, quality/motion and five screen sizes. Final runtime source:
`99534d7ba1b9342eacb0cf19570369a798987f27`. Native captures, comparison, CI links
and exact evidence provenance: [AG64_LANDSCAPE_HUD.md](AG64_LANDSCAPE_HUD.md).
Real phones, physical gamepad, real backend and owner visual acceptance remain open.
No merge, publication, paid asset upload or broader UI task is authorized.

### AG-63 — reversible global PostFX look development

**Status: IMPLEMENTED/CODE; bounded STUDIO VERIFIED; OWNER comparison OPEN;
PUBLISHED: NO.** Issue #32, explicitly requested. Draft PR #34.
Base: Draft PR #33 `feat/ag62a-spellbook-idle-vfx` @
`081bf33ba88178312207f8ad4f3a21b698511766`, Windows/Ubuntu CI 43233181998 PASS.
Branch: `feat/ag63-postfx-lookdev`. AG00 and AG01 ancestry confirmed.
Scope: OFF/A/B/C inside the existing EnvironmentView owner; Studio-only opt-in,
default OFF. No economy, save migration, server/remote, local Spellbook VFX,
sky assets or release flags. OFF restores the evolving baseline; reverting this
branch removes the experiment. Delivered 12 comparable native Studio frames,
Full/Reduced/Minimal/Reduce Motion checks, four 20-switch restoration passes,
rain/cleanup checks and desktop timings. 1193 tests and runtime Windows/Ubuntu CI
43239583185 PASS. Native build `6fe6649868420cfc7a8bb73e4d6cc894d8c2a271`;
clean repeated build verified. See `docs/AG63_POSTFX_LOOKDEV.md` for evidence,
parameters, final PR HEAD link and remaining mobile/M7 asset/art gates.
No next UI task, merge, publication or final look selection is authorized.

### AG-62A-R1 — enhanced Spellbook ambient / interaction VFX

**Status: IMPLEMENTED / scoped STUDIO VERIFIED / OWNER GATE OPEN.**
Owner-requested revision in existing Draft PR #33.
Base: `feat/ag62a-spellbook-idle-vfx` @ `f1882ad0ffc7a5e4803dc13f75d752ba01df229a`,
remote HEAD and Windows/Ubuntu CI 43227213157 confirmed before edits.
Client-only rune glow/aura, rising Essence, bounded transient paper spiral and at
most one shadowless local light. Keep the existing server receipt and idle motion;
no economy, assets, global Lighting or AG-63 changes. Owner art gate remains open.
1181 tests PASS; clean repeat build and Windows/Ubuntu runtime CI PASS. Ordinary
Play verifies E/mouse +5, 3/5-sheet caps, expiry, quality/motion, spam coalescing,
fallback/recovery and eight ready books. Native evidence and limits:
`docs/AG62A_R1_ENHANCED_VFX.md`. No new owner approval or release gate is implied.

### AG-62A — bounded Spellbook idle/VFX slice

**Status: IMPLEMENTED / scoped STUDIO VERIFIED / OWNER GATE OPEN.** Issue #31;
stacked Draft PR #33, branch `feat/ag62a-spellbook-idle-vfx`.
Base: CI-green PR #30, `341b7f6dd9ac1692781f865bf25fed63a05e9d8a`.
Only client presentation of the imported book: rigid loose pages/runes, gentle
glow/flame and bounded particles, quality/motion settings, full fallback cleanup.
Successful manual Essence feedback uses a session-only server receipt in existing
State snapshots; no new remote, permissions, rewards, save fields or migration.
The full AG-62 remains gated on AG-60; AG-01 owner acceptance stays open.
Rollback: revert this stacked feature; AG-01 static book and fallback remain intact.
Verification: 1155 inherited + 18 new tests PASS; Windows/Ubuntu CI and clean
repeat-build PASS. Ordinary Play: eight books, static anchors, quality/motion,
fallback/reappearance, native E/mouse and upgrade button verified. Phone, second
account, 2–8 real players, backend and low-end performance NOT RUN. Exact build,
runtime measurements and remaining owner gates: `docs/AG62A_SPELLBOOK_EFFECTS.md`.

| ID | Stage | Status / dependencies | Проверяемый результат |
| --- | --- | --- | --- |
| **AG-60** | R7 / UI | `GATED` AG-02, стабильный UI contract | Перенести UI-01/UI-02A из `UIFoundationDemo` в настоящие панели: компактная иконочная навигация, контекстные окна, читаемость, изменение магической палитры по действию; touch/gamepad/accessibility и Reduced Motion. |
| **AG-61A** | R7 / M7 pilot | `GATED` AG-00, без full rollout | Довести один арт-пилот до 07D owner review: визуалы/ассеты/коллизии/LOD и скриншоты, отдельно подтвердить отсутствие вмешательства в геймплей и получить решение владельца. |
| **AG-61B** | R7 / M7 rollout | `GATED` AG-61A, 07D owner approval + UX gate | Только после явной приёмки пилота — восемь участков, Bazaar и биомы, collision/nav-safe, manifest, quality tiers и performance evidence. Не включать EnvironmentArtEnabled без gate. |
| **AG-62** | R7 / VFX | `GATED` AG-01 + AG-60 | Idle книги/страниц/рун, мягкие soul/Essence частицы и отзывчивый feedback; котёл/зелья/familiar silhouettes и SFX. Визуальные эффекты независимы от серверного учёта. |
| **AG-70** | R8 / QA | `GATED` R2–R7 | Отдельные real backend DataStore/policy/migration/rejoin, 2–8 игроков, мобильная производительность, противодействие exploit, graceful error и telemetry. Отдельно off flags M4/M6. |
| **AG-80** | R9 / Beta | `GATED` AG-70 + owner private-beta approval | Тестирование в закрытом QA experience, события first-click/first-sale/first-auto/rejoin/stall, реальные сессии, баланс и исправления P0/P1. Без выдачи тестовой статистики за retention. |
| **AG-90** | R9 / Release | `GATED` AG-80 + owner publication sign-off | Финальный SHA, документы и приватные/публичные права, release checklist, CI+live evidence, контролируемый rollout; публикация только по отдельному поручению. |

## Не блокирующие 1.0 задачи

- **AG-O1 / C06 — OPTIONAL/BLOCKED D3:** Enchanted Synthesizer, точные редкости/шансы, owned potion input IDs, консервативный paid provenance, nonce/receipt. Без согласования — не реализовывать.
- **AG-O2 / monetization — OPTIONAL/BLOCKED:** private QA native products/passes, реальные receipts/PolicyService, все SKU=0 до явного разрешения. Gold альтернативы и бесплатно достижимый core обязательны.
- **AG-O3 / trading — OPTIONAL/BLOCKED:** реальные двухсторонние политики, резервирования и crash/reconnect, не открывать глобальную торговлю.

## Шаблон отчёта по каждой задаче

```text
Task ID / branch / base SHA / HEAD SHA:
Changed files and migration/saved-data effects:
Features included; explicitly not included:
Local: npm run tools, npm test (count / fail), place + sourcemap:
Windows exact-HEAD CI / Ubuntu exact-HEAD CI (links):
Normal Studio Play / phone portrait+landscape / 2–8 clients:
Real DataStore / PolicyService / MarketplaceService:
Security, offline parity, performance and asset license evidence:
BLOCKED gates + owner decisions needed:
Next task unlocked; no merge/publish/trading/payments performed:
```

**Правило статуса:** нельзя поставить `ACCEPTED` на основании одних Luau-тестов, интерфейсного демо, синтетического моделирования, неоткрытого PR или неподтверждённой Studio-сцены.
