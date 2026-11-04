# Project instructions

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
