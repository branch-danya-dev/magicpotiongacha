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

**Статус: GATED / BLOCKED (owner import + permissions/license receipt).** **Depends:** AG-00 подтверждён на `7d6d47826e919683ee991c911185215cda0d3d2e`, Draft PR #29, Windows/Ubuntu PASS. **Files:** `assets/props/`, `src/server/SpellbookLectern.luau`, `SpellbookLecternPlan.luau`, импорт/manifest/tests.

Preflight и выбранный путь: [AG01_SPELLBOOK_INTEGRATION.md](AG01_SPELLBOOK_INTEGRATION.md).
Нужны владелец/experience, приватный импорт с проверенными ссылками, экспорт
`SpellbookLectern.rbxmx` и подтверждение применимой лицензии. Реализация остановлена
до этого шага по указанию пользователя. Частичный Draft PR содержит аудит и
manifest; новая runtime-интеграция и новые runtime-тесты ещё не выполнены.

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
