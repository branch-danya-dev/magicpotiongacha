# V1-03 Studio P0 — first-play stability and rendering candidate

**Parent:** `feat/v1-03-alchemy-recipe-book` at `24c9e9f9d21e29194bd676b02d8f0eac884d3bf6`.
**Branch:** `fix/v1-03-studio-stability-p0`. **Target:** an isolated Studio-memory QA build for the actual owner `11924805007`. Do not merge or publish.

## Seven reported defects and changes

1. **Mandatory familiar choice** — the QA server now defers the starter selection after loading the profile and granting the existing approved starter budget. The profile remains valid with `starter.claimed=true`, `choice=nil` and no fabricated pet. Existing owned pets are not deleted. Both the full-screen AG75 cards and inherited choice intents are no longer required for the tutorial to proceed. The code does not change the permanent released V8 schema; production migration is required for future release.
2. **1-second hitching** — desktop Studio no longer forces full rendering quality at first entry; `reduced` is the QA default. Expensive per-tree skinned/static LOD switching is frozen to persistent static silhouettes, which also avoids animated bone work. This intentionally pauses tree skeletal wind while the frame freezes are diagnosed. A successful compiler/test run does not prove FPS; measure F5 render spikes before release.
3. **Trees/meshes disappearing** — the unstable camera-bounds alpha fade is disabled for full-size forest meshes, and the static fallback never becomes a hidden zero-frame swap. Small understory detail may still be culled in Minimal.
4. **No collision** — new server-owned, invisible physical trunk and rock proxies use the **same authored island tree descriptors** as the visual layers. Lantern posts and placeholder boiler/cauldron are solid. Canopy/leaves, small flora and grass remain pass-through by design. Proxies never move when the camera rotates.
5. **Jerky moon** — reuse the existing EnvironmentView update connection, interpolate the target moon position on every render invocation (no extra RenderStepped loop), and preserve original cycle selection/timing.
6. **Dusk/night horizon wedge and clouds** — restore the baseline atmosphere offset (the original `candidate` horizon experiment was unresolved); native Roblox `Terrain.Clouds` is the sole cloud-cover owner, with gentle moonlit tint at night.
7. **Black seams inside clouds** — remove layered/billboard custom cloud-ocean sheets while keeping the world-tree panorama. Native cloud rendering remains; no sky video, GLB or mesh upload.

All changes apply **only to generated QA source** via `scripts/apply-v1-stability.mjs`, after V1-01, V1-02, V1-03. The original production `src/`, metadata, multiplayer, DataStore, monetization, trade, runtime pets and scene assets are left alone.

## Reproduction and regression gates

- GitHub CI: `npm test`, includes `qa/stability/run.luau` and inherited alchemy/garden tests.
- Pure tests assert starting with no familiar does not mint a pet or Gold, the full mandrake workflow remains available, owned pets persist, legacy profiles retain their rules, stable LOD never switches, and physical proxy geometry stays deterministic.
- In Studio with owner account, run **F5**, confirm there is **no mandatory choice** and the garden is the next tutorial step after passive Essence. Gold/Essence must still progress.
- Walk into large trunks, stones and cauldron; verify physical obstruction, but not on leaves or bushes.
- Turn camera toward/away from forest trees for 60 seconds at reduced and full quality; no visible pop or vanished tree.
- Watch at least one complete dusk-night-dawn transition. Moon movement should be continuous and no dark diagonal sky wedge or cloud cuts should appear. Night clouds may be moonlit blue.
- Measure frame-time at steady state and during rotation/night transitions. **Actual Roblox Studio F5/perf still requires user QA; never assert confirmed fixed based solely on CI.**

## Build a fresh QA place

```sh
npm run tools
npm test
node scripts/build-alchemy-first.mjs --owner-user-id=11924805007
```

Open `build/PotionTycoon-Alchemy-First-QA.rbxlx` with **Roblox Studio → File → Open from File** and test with the same account. The dedicated P0 workflow also exports a renamed owner-stamped copy as a downloadable build. Reusing a previous `--owner-user-id=-1` artifact is not permitted; owner mismatch triggers a kick.

Unverified: actual FPS, moon visuals at your GPU resolution, physical response in Roblox Studio, mobile rendering, and live data persistence. These require the owner's F5 inspection; do not replace the prior approved art branch or publish without a separate gate.
