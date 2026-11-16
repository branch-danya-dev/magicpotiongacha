# AG-75 — owner feedback: launch, scene, atmosphere and navigation

**Status:** CODE_CANDIDATE; desktop/mobile visual approval and normal Studio Play **NOT RUN** in this environment. **Never publish this QA place.**

**Base:** Draft PR #51 / `feat/ag74-green-slime-runtime` @ `f421ccdaa5da6c55535ebf4c1048eb186ccfb5d4`.

## Scope

1. `SimplifiedScene` hides greybox stations, desks, shop counter, purchase pads, signs, billboards and their local collisions. The imported `SpellbookLectern` stays. If its template is absent, the fallback crystal pedestal stays; floors, environment terrain and lantern lighting are preserved. This is *local, Studio-only, reversible*; the server retains station positions, predicates, saves and progress, including inaccessible hidden stations during this temporary art review. Disable `AG75SimplifiedSceneEnabled` to restore presentation.
2. `StarterCards` mounts a separate full-viewport three-card selector for unclaimed first-session profiles. Every portrait and stat comes from the existing approved atlas and server `Config.starterPets`. A confirmation screen issues the existing `chooseStarter` intent exactly once per tap; error/timeout permits retry. The old AG71 upper-left chooser is hidden. The server now allows *this action only* regardless of altar distance when the player owns an assigned plot and is alive; `Factory` still enforces once-only claim and persistence. No extra economy or grant source.
3. `AG75Atmosphere` projects a dimmer, less exposed day onto the existing `ArcaneForest` lighting owner and strengthens bloom, mist and rain streaks. Night uses six *existing* Full-tier light slots for lanterns rather than wasting two on sun spots; six lightweight distant emissive glints reuse the already-approved star image. There is one bounded two-attachment shooting-star Beam. PC Studio begins at Full quality, touch devices retain Reduced; player quality overrides remain honored. **Cricket audio is not shipped:** no approved/licensed cricket sound asset was provided, so no new sound upload/rights were assumed. Long-range physical illumination must be visually checked; attenuation is still intrinsic to Roblox PointLights.
4. Green Slime rig has a uniform preview scale of **1.65** instead of 1.0; its underlying mesh, texture, eight-bone rig and two 50/50 Idles are unchanged. Texture optimized-representation warning remains open from AG74.
5. RPG navigation groups existing actions as Inventory (bag, warehouse, brewing, farm, supplies, orders and exchange), Character (overview, progression, rebirth, rewards, graphics) and Companions (collection/altar). Desktop shortcuts: **Tab, P, G**. Mobile: three bottom buttons, moved above tutorial coaching during onboarding. Old oversized quick rail and landscape dock are hidden in Studio; no server state or new remote.

All changes are Studio-gated and reversible; default `default.project.json` does **not** opt the released game in. The AG74 source and accepted historical artifacts are guarded by removable AG75 seams and inheritance tests.

## Native QA matrix — awaiting owner/Work

| Check | Status | Procedure |
| --- | --- | --- |
| Desktop Play / first launch | NOT RUN | Open `build/PotionTycoon-AG75-OwnerFeedback-QA.rbxlx`; check three cards cover the screen, old upper-left HUD absent, crystal/lectern remains and no invisible collision walls |
| Starter server validation | NOT RUN | Select each pet on a fresh Studio-memory run, confirm one grant; reject double click/non-owner/dead avatar; error and 10-second retry |
| Art/lighting | NOT RUN | `workspace.PotionTycoonWorld:SetAttribute("EnvironmentReview", "day")`, then `night`, `rain`, `afterrain`; examine spawn, 10/30/60 stud walk and distant lanterns; compare Full/Reduced |
| Green Slime | NOT RUN | Observe 1.65 scale, contact point, material/texture and Calm/Active transitions at real game camera, walking and hauling |
| Mobile emulator | NOT RUN | 390x844 and 844x390, device safe area; portrait scroll, landscape horizontal scroll, bottom nav and tutorial clearance |
| Reset/rejoin | NOT RUN | Reset while cards active and after claim, respawn and long-term grant; verify no duplicate GUI/rig/light owner |
| Real server / 2–8 players | NOT RUN | Server-owned grant, plot isolation, background art perf; DataStore is not exercised in Studio memory mode |
| Historic preservation | CODE PASS | `npm run tools`, full `npm test` (1,344 Luau and 14 Node tests, 253 Luau sources compiled), AG74 preservation and AG75 QA build passed; CI on final SHA TBD |

### QA artifact

Run `node scripts/build-ag75-preview.mjs`. Output: `build/PotionTycoon-AG75-OwnerFeedback-QA.rbxlx`, local Studio-memory preview only. The build embeds the approved private Green Slime template and two-pet QA fixtures, with explicit AG75 flags and Studio-only environmental artwork. It must never be published. `AG74TwoPets=false` hides the QA dummy pair to review only naturally assigned worker pets.

## Rollback / permissions

- Remove AG75 integration seams and new modules, restore `FamiliarVisualRegistry.scale=1`; production build remains unchanged.
- Runtime: `AG75StarterCardsEnabled=false`, `AG75SimplifiedSceneEnabled=false`, `AG75AtmosphereEnabled=false`, `AG75GroupedHUDEnabled=false` disable respective Studio presentations on next Play. No migration or saved schema edits.
- Historical PRs #45/#47/#49/#51 are not merged or overwritten. No new upload, Roblox publication, monetization change or real-world spend authorized.
