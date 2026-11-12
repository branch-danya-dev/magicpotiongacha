# Project instructions

- Before a new task, read `docs/PROJECT_AUDIT_2026-11-12.md`, `docs/RELEASE_ROADMAP_V2.md`, and `docs/AGENT_WORK_QUEUE.md`; claim exactly one task ID and record its base SHA. Treat older C00/C01 checkboxes in `docs/ROADMAP.md` and `docs/CORE_LOOP_V2_CURSOR_BACKLOG.md` as historical until reconciled with current code.
- `origin/main` is still bootstrap, not the live M6/V2 head. Confirm the current integration branch and full dependency ancestry before starting a feature; never accidentally implement C02 on old main, replace another agent's work, or infer release acceptance from code alone.
- Distinguish `IMPLEMENTED/CODE`, `STUDIO VERIFIED`, `OWNER ACCEPTED`, and `PUBLISHED` in all reports. Do not mark an unperformed live DataStore, phone, multi-client, art or purchase gate as passed.
- Third-party visual assets require source/license/hash/permissions and a reproducible build path; a manually imported Studio model that disappears on Rojo rebuild is not an accepted game-ready asset.
- Keep gameplay authority on the server. Clients send validated intents only.
- Preserve the decisions in docs/DESIGN.md. Do not silently add paid randomness, trading or new currencies.
- Factory/Config/Protocol and ProfileStore must remain runnable in the standalone Luau CLI.
- Use the same deterministic factory simulation for online and offline progression; never recalculate rewards on a UI claim.
- Do not overwrite failed/future/invalid saves with defaults. Quarantine partially failed simulations.
- A single-profile session lease does not make trading atomic. Trading needs its own persistent protocol and failure tests before activation.
- Keep art and visual motion separate from production accounting. Do not import marketplace scripts or remote assets without review.
- Run `npm run tools` then `npm test` before delivery. Preserve SHA-256-pinned tool downloads and pinned CI actions.
- Studio/real-backend/mobile checks must be reported separately from CLI tests; do not claim unperformed acceptance.
- Make changes on a feature branch. Do not merge to main without the owner's request.
