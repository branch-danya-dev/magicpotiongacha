# ALCHEMY-FIRST — passive Essence + brewing-first island (Studio QA)

**Branch:** `feat/alchemy-first-passive-essence`. **Exact parent:** `fix/island-forest-p0` @ `33257ed84f9a8455329aaf77e22709a611a1ef32` (Draft #65). All production `src/`, assets, save schema V8 and the inherited forest remain unchanged. The candidate is an isolated generated Studio-memory place, not a live game or merged release.

## Player experience

- Essence generates by the existing server-owned 1-second simulation automatically from crystal level 1 at **1 Essence/sec**. Other V2 levels remain 2 / 6 / 18 / 48 Essence/sec. It also progresses while offline within the original 7,200-second cap.
- Manual `click` intents are rejected server-side for non-legacy V2 profiles in this QA candidate. Historical profiles retain their former behavior. The crystal prompt now opens information rather than granting currency. Both the crystal panel and Arcade HUD remove their manual-collect controls. The new onboarding stage advances on real passive accrual after the starter is selected.
- A purple **BrewingCube** sits on the canonical `cauldron` station anchor. Its existing authenticated ProximityPrompt opens the existing station UI: pay 300 Gold to build, choose Healing, load Essence and ingredients, then brew. Cube is a visual stand-in, not a second production machine.
- A **HerbGarden** soil patch with three rows sits on the canonical `garden` anchor. The established 200 Gold bed / seed purchase / plant / grow / harvest actions remain server-authoritative. The soil is ready for eventual ingredient 3D growth assets.
- **Книга зелий** is a separate responsive ScreenGui with a blank recipe list. It is intentionally **not wired to the old `discoveredRecipes` or unlocks yet**, which remain in the engine. It performs no writes and does not assert all recipes were removed.
- New visual parts are non-colliding and do not alter terrain, forest, 48 trees, 13 anchors, routing, owner identity or station instances. No added loops, lights, paid assets, remotes or backend operations.

## Build

```sh
npm run tools
npm test
node scripts/build-alchemy-first.mjs --owner-user-id=YOUR_ROBLOX_USER_ID
```

Output: `build/PotionTycoon-Alchemy-First-QA.rbxlx`, with SHA-256 and source-HEAD receipt `build/alchemy/build.json`. Open the **new file** in Roblox Studio and use normal **F5**. The builder creates a matching `build/PotionTycoon-Dense-Forest.rbxlx` base first; pass `--reuse-forest` only if the existing receipt is from the exact same HEAD and owner.

QA run: choose one starter, confirm 1 Essence/sec with no clicks; stand by purple cube, buy cauldron and brew through existing server intents after growing Mandrake in the garden; open/close blank Potion Book on PC and phone. Inspect grass, routes and first-load stutters. Test all three familiar choices and repeat F5. Also verify no-click exploitable remotes and a historical profile if one is explicitly loaded.

**Gates:** CLI tests and Rojo build must be verified by exact-HEAD Windows/Ubuntu CI. Real Studio F5, owner visual approval, mobile performance, multiplayer, live DataStore, economy rebalance and release integration remain **NOT RUN** until evidenced. The forest P0 startup hitch remains inherited, not fixed here.

## Rollback

Do not merge this branch. Reopen the unchanged `fix/island-forest-p0` candidate/place or remove the new QA scene. The original `src/` and persistence are not modified; no saved-data rollback or migration is necessary. No Roblox publication or Robux spending.
