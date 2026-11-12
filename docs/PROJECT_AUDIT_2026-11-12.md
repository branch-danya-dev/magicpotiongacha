# Potion Tycoon — репозиторный аудит на 2026-11-12

**Срез:** `branch-danya-dev/magicpotiongacha`, удалённые ветки проверены 2026-11-12.
**Последняя вершина разработки:** `cursor/spellbook-lectern-a4f2` @ `fd49911` (2026-11-07 17:22 UTC).
**Важно:** это **код-кандидат**, а не принятый, опубликованный Roblox place. `origin/main` остаётся на bootstrap `a1a5236`; основная работа находится в незавершённой цепочке веток. Наличие в ветке ≠ merge / live acceptance / publication.

## Последняя выполненная задача

`fd49911` — `feat(world): show an imported Spellbook Lectern in place of the crystal mesh`.

- Добавлен исходный GLB `assets/props/spellbook-lectern.glb` (239260 байт), серверный `src/server/SpellbookLectern.luau`, переносимый план `src/shared/SpellbookLecternPlan.luau` и `tests/spellbook_lectern.spec.luau`.
- SHA-256 GLB в дереве: `ff12f9f121daa74d444601240d3601a16849e1c9ee69dbf83a83c5db22b76a52`.
- При наличии шаблона `ServerStorage.SpellbookLectern` сервер клонирует визуал на участок, скрывает процедурный кристалл, создаёт `EnergyPoint` и `ParticlePoint`. Логический station id по-прежнему `crystal`; Essence, upgrade/prompt и серверный расчёт не переименовывались.
- **Незакрыто:** код самого модуля требует ручной `Import 3D → ServerStorage` после открытия `build/PotionTycoon.rbxlx`; при новой Rojo-сборке импорт исчезает. Без шаблона `Lectern.findTemplate()` возвращает `nil`, а замена визуала не происходит. Нет доказанного обычного Studio Play после этой вершины. Это **не** самодостаточная поставка игрового ассета.
- Лицензия Shuriken Studio *Free model license* (актуальная опубликованная версия `2026-11-12`) разрешает коммерческое использование внутри Roblox-игры, включая place/source, без атрибуции; запрещает отдельную перепродажу/раздачу исходных моделей или заливку как автономный Creator Store asset. Источник: <https://shuriken.studio/models/props/spellbook-lectern>; условия: <https://shuriken.studio/legal/models>. Для фиксации прав указывать версию, действовавшую на дату скачивания; впоследствии сохранить license receipt, hash и способ воспроизводимого импорта.

## Реализованное, запланированное и непроверенное

| Подсистема | Доказательство в HEAD | Достоверный статус |
| --- | --- | --- |
| M0–M6, экономика, защита запросов, торговый журнал, Rebirth, платежные receipts | `src/shared/Factory.luau`, `ProfileStore.luau`, `Trade*`, `Monetization.luau`, исторические тесты | **IMPLEMENTED/CODE**; живые бэкенды, платежи, policy и нагрузка **не приняты** |
| V8 и Core Loop V2 C00/C00b | `Config.schemaVersion=8`, `Factory.migrate`, `tests/v8_migration.spec.luau`, `CORE_LOOP_V2_C00.md` | **IMPLEMENTED/CODE**; настоящие DataStore-миграции **BLOCKED** |
| C01: первый цикл Economy V2 | `Config.firstSession.ownerApproved=true`, `economyV2`, `tests/c01_first_session.spec.luau`, `tests/c01_economy_v2.spec.luau`, `tests/c01_session_ux.spec.luau`, `C01_BALANCE.md` | **IMPLEMENTED/CODE CANDIDATE**; реальная мобильная/многопользовательская приёмка **BLOCKED** |
| C01 конкретно | 1000 стартового Gold; выбор **одного** начального owl/slime/cat; грядка 200, котёл 300, семя 20, Healing 250, автоматизация 500, Crystal L2 900; выращивание по таймеру; server-observed tutorial | **PROTOTYPE BALANCE**, не измеренная удерживаемость и не финальный прайс-лист |
| C02 — свободное строительство + храм | `layout`/`temple` в V8 сейчас в основном проекция прежних фиксированных станций | **NOT IMPLEMENTED**; 13 фиксированных слотов всё ещё базовая модель |
| C03–C05 — склад зелий/Atlas/Lab, мастерство фамильяров, три типа контрактов | `CORE_LOOP_V2_SPEC.md`, `CORE_LOOP_V2_CURSOR_BACKLOG.md` | **SPEC ONLY / OPEN**; M1–M6 аналоги не равны новым V2 функциям |
| C06 — редкий синтезатор | только целевой дизайн | **BLOCKED OWNER DECISION** о редкостях, шансах, результатах; не входит в минимальный безопасный релиз |
| C07 — V2 Rebirth/сохраняемые уникальные зелья/навыки/чары | M5 Rebirth существует, V2-поля только подготовлены | **PARTIAL HISTORICAL / V2 OPEN** |
| UI-01/UI-02A | `src/shared/ui/*`, `src/client/UIFoundationDemo.client.luau`, `UIFoundationDemo=true` в `default.project.json` | **STUDIO FOUNDATION/DEMO**, не завершённый production HUD для всего V2 |
| M7 визуальный мир | `src/server/Environment*`, Terra/asset docs/evidence | **PILOT CODE**, 07D owner art approval и полный восьмиучастковый rollout не подтверждены |
| Новый Spellbook Lectern | `fd49911`, см. выше | **VISUAL CODE CANDIDATE**, ручной импорт и обычный Play не закрыты |
| Trading/Robux | `ServerSettings.luau`: `TradingEnabled=false`, `MonetizationEnabled=false`, `PurchaseQAApproved=false`, SKU=0 | **DISABLED**. Нельзя включать по факту наличия кода |

## Главные риски перед следующими фичами

1. **Веточная модель:** `main` не содержит последовательную поставку M0–M7/C01/UI/Spellbook. Агентам нужен подтверждённый интеграционный HEAD, нельзя произвольно смешивать PR или обещать релиз из `main`.
2. **Невоспроизводимый визуальный артефакт:** GLB в git есть, но Rojo place не содержит импортированную книгу сам по себе. `SpellbookLectern.ensure()` тихо пропускает замену при отсутствии шаблона. Нужен воспроизводимый путь `GLB → импорт → Studio/Rojo → обычный Play` без фальшивого PASS.
3. **Расхождение документации:** исторические `docs/ROADMAP.md` и `docs/CORE_LOOP_V2_CURSOR_BACKLOG.md` обозначали C01 как ещё не начатый, хотя текущий HEAD уже содержит C01. Актуальный статус — этот аудит и [RELEASE_ROADMAP_V2.md](RELEASE_ROADMAP_V2.md).
4. **Платформенная приёмка:** portable Luau/fake backend/CI не доказывают поведение настоящего DataStore, PolicyService, MarketplaceService, Roblox Studio, физического телефона и 2–8 игроков.
5. **Неутверждённые решения:** свободное строительство/лимиты храма, активные слоты фамильяров, сериализация зелий и редкости/шансы синтеза — см. gate в [RELEASE_ROADMAP_V2.md](RELEASE_ROADMAP_V2.md). Не трактовать рекомендации документа как уже утверждённые пользователем.
6. **Арт не завершён:** наличие UI-demo, пилотной природы и артефакта Spellbook не означает, что весь мир выглядит единообразно и измерен на телефоне.

## Portable/build baseline на этом срезе

- На `fd49911` после `npm run tools` выполнен `npm test`: **1142 passed, 0 failed**. Сборки `build/PotionTycoon.rbxlx` и `build/M7PilotReview.rbxlx` созданы; Luau компилятор/анализатор обработал **168 source files**.
- Два существовавших предупреждения Luau analyzer в C01-тестах (`LocalShadow`, `LocalUnused`) не остановили команду. Это не evidence прохождения Roblox Studio/Windows+Ubuntu CI или live backend на последнем HEAD.

## Источники правды и правила доказательств

- **Код:** точный SHA/ветка и unit/portable-тесты; **дизайн:** `CORE_LOOP_V2_SPEC.md`, `DESIGN.md`; **история:** `ROADMAP.md`, `ACCEPTANCE.md` и M1–M7 отчёты.
- **Следующая очередь:** [AGENT_WORK_QUEUE.md](AGENT_WORK_QUEUE.md); **готовая игра и этапы:** [RELEASE_ROADMAP_V2.md](RELEASE_ROADMAP_V2.md).
- Каждый PASS записывать вместе с SHA, типом среды, версией Roblox Studio, backend namespace, устройством и воспроизводимыми шагами. Не выполненный Live gate остаётся `BLOCKED`, даже если все CLI-тесты зелёные.
- Этот аудит фиксирует состояние **2026-11-12**, а не автоматически обновляемый прогресс. Агент, изменяющий состояние, обновляет очередь и приводит конкретные доказательства; старые записи не стирает.
