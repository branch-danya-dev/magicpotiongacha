# AG71 Phase B — approved variant B vertical slice

Status: **IMPLEMENTED/CODE / PARTIAL STUDIO VERIFIED / ART OPEN / NOT PUBLISHED**.
Owner explicitly approved B and authorized implementation on 2026-11-14.
Base: Draft PR #45 `18b300ca2c7f7a7c67202e270d50602e4ad7ffd0`; inherited
Windows/Ubuntu CI 43602762059 PASS. Stacked PR base remains PR #43
`c8b546bc1734cc435159cfa6b1122f9a23b806a5`. No merge or publication.

## Implemented scope

- Icon + number balances at the upper right; short goal/level at upper left;
  horizontal Book/Familiars/Brew/Lab/More navigation. More retains Shop, Rewards
  and Settings. Real snapshots only; no fixed demonstration balances.
- Storybook page for `crystal`, with existing collect/upgrade intents and
  worker assignment access. Other windows keep their inherited contents.
- Compact owl/slime/cat selection and separate confirmation; native species
  IDs remain farmer/slime/brewer. Server one-time grant remains unchanged.
- Existing receipt validator drives one bounded, reused +N label and currency
  tint; initial/passive/replayed/rejected/foreign/capped receipts do not invent
  rewards. Reduce Motion removes label travel. No idle frame scheduler.
- One PotionTycoonUI, state subscription and existing dispatcher. Main and
  LandscapeHUD additions are removable named AG71 seams. Preservation checks
  restore the exact base source before checking every inherited runtime, test,
  QA, asset and Rojo configuration file. No server/economy/save changes.

## Delivery and rollback

Only Studio can enable AG71. `ArcadeHUDEnabled=false` restores AG64;
`LandscapeHUDEnabled=false` retains the inherited legacy rollback. Portrait
uses the inherited fallback. Published game stays OFF even if the review flag
is true. Asset delivery failure preserves AG64. No placeholder art is shown.

The single prepared atlas and its hash are in
[`assets/ui/ag71/upload-manifest.json`](../assets/ui/ag71/upload-manifest.json).
The owner separately authorized this exact file on 2026-11-14. Image
`127092357608242` was uploaded as addout studio (925845207), observed Restricted,
and access granted only to Experience 10776120489. The native game reports
`AG71AssetStatus=LOADED` and renders the sprites. Dashboard moderation was last
observed In Review; runtime delivery is verified separately. Repeat packing
reproduced SHA-256 `35acd2d7ca5fab36ee89e93db34fcad3f8140d982ceaddfb77e7092f64b645d5`
and preserved the existing receipt. No additional assets were uploaded.

Native diagnosis found that preloading an ID string did not invoke the status
callback. The final implementation preloads a temporary ImageLabel instance and
destroys it after completion. The pre-fix failure safely displayed AG64; the
corrected instance-based path displayed the approved artwork.

## Checks and unresolved gates

19 added portable tests cover snapshot projection, all seven routes, one-time
starter visibility, loading/pending/read-only/MAX, receipt semantics, Studio-only
gate and layouts at 844x390, 740x360, 1024x768, 1366x768, 1920x1080 and 780x360
for mouse/touch with CoreGui inset and native corner reservations. A narrow chat
layout retains the inherited safe coaching fallback. PNG dimensions, CRCs,
decoded size, exact hash, source and destination are checked offline.

Final exact-HEAD full test, reproducible build and Windows/Ubuntu CI results are
recorded in Draft PR #45. These do not certify Roblox rendering or device input.

## Native observations, 2026-11-14

Ordinary full-game F5, Studio 0.747.0.7471481, local memory-save preview, no QA
scene replacement or simulated currency grants. Candidate artifact
`AG71-B-Play.rbxlx` SHA-256
`f83a5685202f201fee22fc73a1cde4569d11f33c9491bc3428ab1366c4c0a7a5`.
This candidate predates only the final goal/reason text localization; the final
exact-HEAD smoke result and build digest belong in PR #45, not inferred here.

- Actual atlas visible; default Reduced, Full, Minimal and Reduce Motion toggled
  through Settings. Cyrillic text renders with Roblox font fallback.
- All seven destinations opened using the real buttons. More closes the prior
  window. Book opens/closes; its worker link opens the inherited selector and
  assigning the confirmed cat starts the existing passive Essence production.
- Starter portraits change local selection without granting. Confirmation near
  the altar grants one cat and hides the chooser; the collection contains 1/128.
  A first attempt from spawn was rejected by the existing interaction distance.
  The character was walked to the altar/book via temporary Humanoid:MoveTo in
  the Studio command bar, not teleported or granted inventory.
- Book collect produced server-confirmed balance 0→5 and one `+5 Essence` label.
  Physical E produced 5→10. Upgrade displayed real cost 900 and remained disabled
  before the first Healing sale, as required by the unchanged progression gate.
- 20 AG71→AG64→AG71 cycles passed restoration assertions, with exactly 85
  descendants on each recreated B root. Legacy HUD disable/restore also passed.
- Studio iPhone 17 Pro landscape emulator: book, counters and navigation fit
  around native notch/CoreGui, joystick and jump. Collect and close were usable
  with emulated touch. Opening chat hides HUD by inherited focus policy; closing
  chat restores it. This is not a real-device performance claim.
- Session used manual graphics Q6. No manual-Q5 or FPS/render timing claim.

Bounded native log observations (UTC): `14:40:50 AG71 BUTTON ... LOADED`,
`14:43:14 AG71 NOTICE ok Starter chosen`, `14:44:52 AG71 COLLECT 5 +5 Essence`,
`14:51:21 AG71 TOGGLES PASS 20 85`, `14:51:22 AG71 LEGACY ROLLBACK PASS`.
No new AG71 runtime error was observed. Existing avatar/plugin asset and chat
permission warnings appeared in the Studio log and are not certified resolved.

Still **NOT RUN / OPEN**: final owner art approval; real phone/tablet performance,
physical gamepad, 2–8 clients/live backend, successful paid upgrade after first
sale and delayed-network pending UX, separate new-profile grants for owl/slime,
native rapid-input stress and render timings. Portable checks cover the inherited
authority and pending/rejected/replayed receipt cases, but do not replace these
live gates. No video or exported screenshot evidence was created.

AG70 art acceptance and AG60/full V2 UI remain open; this slice closes neither.
