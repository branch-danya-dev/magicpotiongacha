# M7 visual recovery and build contract (2026-11-06)

The missing scenery was not deleted from Git. The accepted M7 pilot is preserved
on `feat/m7-environment-artpass` at `34f617b5f36975d5f71638746494c0341e88bf45`
and is an ancestor of the C01 source at `0f852333910a98300f4dd27b7388eadc5564efd1`.
The normal game's greybox came from the publication gate
`ServerSettings.EnvironmentArtEnabled = false`, not a missing asset commit.

## Canonical visual source

- `src/server/EnvironmentArt.luau`: pilot assembly, forest props, vista hookup.
- `src/server/PropArt.luau`: themed station replacements.
- `src/server/IslandLandscape.luau`, `FarmLandscape.luau`,
  `ForestArt.luau`, `VistaArt.luau`: island, farm, canopy, distant vistas.
- `src/client/Environment.client.luau`, `EnvironmentView.luau`:
  atmosphere, weather, moon, motion and quality.
- `src/shared/EnvironmentConfig.luau`: pilot layout and sky/material settings.
- `assets/environment/woodland/M7NatureTemplates.rbxmx`:
  tracked woodland model templates; source and license receipts are under
  `assets/environment/`.
- `docs/M7_07C_COMPOSITION.md`, `docs/M7_REWORK_PLAN.md`:
  last art pass, design and open approval gates.

Historic real Studio evidence (not synthetic renders):

- `docs/evidence/m7/01-day-overview.jpg`, `03-night-overview.jpg`.
- `docs/evidence/m7-a2c/after-10-sunset.jpg`,
  `after-10-night.jpg`, `after-10-rain.jpg`.
- `docs/evidence/m7-19a/after-wide-g10.jpg`,
  `after-west-g10.jpg`, `plain-play-desktop.jpg`.
- `docs/evidence/m7-18a/after-day-g10.jpg`,
  `final-landscape-open.jpg`.

## Reproduce safely

1. Run `npm run tools` (once per machine) then `npm test`.
2. Open the newly built `build/PotionTycoon.rbxlx` in Roblox Studio,
   press **Play**, and use the configured in-memory Studio backend.
   M7 pilot art now turns on only in this isolated full-game Studio session.
3. The published server still ships with `EnvironmentArtEnabled=false`.
   `build/M7PilotReview.rbxlx` is the separate visuals-only harness.
4. Check `workspace.PotionTycoonWorld` attribute `EnvironmentArtEnabled=true`
   inside Studio and inspect pilot plot 1. The other seven plots remain greybox
   until owner acceptance of the eight-plot rollout.

`npm test` now rejects disappearance of source models, art modules, Studio
preview wiring and their serialized Rojo instances from either build.
This is a reproducibility check, **not a native Studio visual acceptance**.

Manual edits to an opened Studio place are not in Git until explicitly exported
and committed. Preserve any valuable Studio-only scene as an `.rbxlx` or exported
`.rbxmx` before regenerating, and check Studio autosaves/version history for
uncommitted objects. Do not overwrite the source-of-truth art with a greybox
or publish an unapproved M7 preview.

## Known limits

07D owner visual acceptance and stage 08 rollout remain open. Some atmosphere
asset IDs still require correct experience permissions. Real phone, Roblox
DataStore and multiplayer checks are separate from CLI/CI success.
