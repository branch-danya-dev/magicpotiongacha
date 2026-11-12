# AG-00 — integration baseline, 2026-11-12

**Task scope:** establish one development base, verify ancestry, build and minimal
ordinary Play, and document unresolved gates. No runtime/economy/schema changes.
No merge, publication, upload, payment or trade activation. No save migration is
introduced; rollback is switching back to the documented parent.

**Canonical development branch: `integration/ag00-base`.** Its parent is
`2c04c8dbf3dc20af1112c69b785fc0b72a1ab4e0` (`docs/agent-roadmap-20261112`, PR #27),
which adds seven documentation files/updates on top of code
`fd49911f7b72653e15e02c567e648a126d07954a` (PR #26). The AG-00 PR head and
`build/ag00-integration.json.sourceSha` identify the exact delivery commit; never
infer the tested SHA from a moving branch name. Start AG-01 from that successful
AG-00 head. `main` remains the old bootstrap, not the development base.

## Provenance and PR map

All seven exact commits in [AG00_BASELINE.json](AG00_BASELINE.json) were checked as
ancestors of the code/documentation base, rather than inferred from PR titles.
The remote compare results had zero commits missing from the candidate.

| Stage / branch | Tip at inspection | Relationship / action |
| --- | --- | --- |
| `cursor/c00b-v8-migration-a4f2` | `d847b5b` | V8 ancestor included; preserve migration review |
| `cursor/c01-economy-v2-fix` | `0f85233` | C01 economy fix included; no price changes |
| `cursor/c01-first-session-ux-a4f2` | `a2a0daf` | C01 UX included; full first-session live gate open |
| `cursor/ui-01-foundation-a4f2` | `ff3c569` | UI foundation included; still a preview |
| `cursor/ui-02a-alchemy-skin-a4f2` | `9082d48` | Skin included; native UI acceptance remains open |
| `cursor/spellbook-lectern-a4f2`, PR #26 | `fd49911` | Adapter/source GLB included, actual template absent |
| `docs/agent-roadmap-20261112`, Draft PR #27 | `2c04c8d` | Documentation-only parent of this PR |
| `feat/m7-environment-artpass`, Draft PR #17 | `34f617b` | Historical art work is an ancestor; do not restart AG tasks here |
| `integration/ag00-base`, this Draft PR | See PR head / CI receipt | Proposed shared base, no merge requested |
| `main` | `a1a5236` | Bootstrap only; owner decides eventual stack integration |

Existing PRs remain open and unchanged. Included ancestor branches need no
cherry-pick/rebase merely to populate this base. New independent work branched
from old `main`/M7 must be reviewed and rebased onto the confirmed integration
head before integration; do not blindly retarget or merge the historical stack.
Review this small PR against `docs/agent-roadmap-20261112`. AG-01 will be a separate
Draft PR against `integration/ag00-base`; unrelated Factory/Config/ProfileStore/
Protocol/World work must be sequenced rather than combined here.

## Reproduce and identify the build

```powershell
git clone --branch integration/ag00-base https://github.com/branch-danya-dev/magicpotiongacha.git
cd magicpotiongacha
git rev-parse HEAD
npm run tools
npm test
node scripts/check-integration-base.mjs
```

Use full Git history (`git fetch --unshallow` if the clone is shallow). The
checker refuses missing ancestry, tracked edits or a test log from another SHA,
rebuilds the ordinary place and compares its bytes. Both CI jobs run this on the
actual PR head, and upload `build/ag00-integration.json` with place/log artifacts.
This is build provenance, not proof of asset permissions or native gameplay.

Open **`build/PotionTycoon.rbxlx`** in Studio and use **Play**, not Run, the pilot
place or `PotionTycoon-M7-LocalPreview.rbxlx`. No Rojo server/plugin connection is
needed. Do not save engine migration or test-session edits back into the source.

## Executed evidence

Clean isolated worktree, Windows x64, Node **26.13.0**, npm **11.20.0**, hash-pinned
Luau **0.745** and Rojo **7.7.1**. The original M7 checkout was left untouched.
The first full test/build and the ordinary Play below used exact source
**`2c04c8dbf3dc20af1112c69b785fc0b72a1ab4e0`**. AG-00 changes only docs/checks/CI;
the final exact-head run is recorded separately in the PR and CI receipt.

| Check | Result / scope |
| --- | --- |
| Dependency ancestry | PASS, exact commits in manifest |
| `npm run tools`, `npm test` | PASS: **1142 tests, 0 failed**, **168 Luau sources**, both Rojo places and sourcemaps |
| Portable analyzer | PASS with two inherited warnings: `LocalShadow` C01 economy test line 232; `LocalUnused` first-session test line 411 |
| Repeated ordinary Rojo build | PASS, identical SHA-256 (below) |
| Ordinary Studio Play, single local client | PASS for boot/spawn, rendered pilot, tutorial/choice screen and opening Factory menu only |
| UI-01/UI-02A coexistence | Preview loads but overlays real HUD; not accepted as production UI |
| Spellbook rendering | MISSING, known AG-01 scope; original crystal fallback remains |
| Full C01 starter/progression/rejoin | NOT VERIFIED; one Owl choice click did not visibly advance; no completion claim |
| Native assets / latest Studio visuals | NOT ACCEPTED; warnings detailed below |
| Windows/Ubuntu CI on final PR head | See linked exact-head runs in PR and uploaded receipt; never substitute local Windows for Ubuntu |
| Real DataStore / Policy / purchases / phones / 2–8 clients | BLOCKED, no live evidence |
| Owner art approval / merge / published game | Not granted by AG-00 |

Initial artifact SHA-256:

- `build/PotionTycoon.rbxlx` (and repeat):
  `3c395c1a25a20fd23db0c6b506fa877b38aee723803b75e645821600e96aeed6`
- `build/M7PilotReview.rbxlx`:
  `799f626838c95a42b732f2bab3d193064f6b5033e03dd30df8fd41c66d6eceb4`

Studio **0.747.0.7471481**, ordinary Play started **2026-11-12 08:43 UTC**, local
place 0, `UseMemoryInStudio=true`, one client; no real persistence or namespace
was exercised. Observed avatar, pilot terrain/trees, original crystal and C01
choice screen. UI demo initially shows fixture `Essence 40`; that is not the
profile balance. After observing this default behavior, the client-only test
attribute was set in the Play command bar:

```lua
workspace:SetAttribute("UIFoundationDemo", false)
```

This exposed the real HUD (**Gold 1K, Essence 0**) and working Factory menu. It
did not grant currency, teleport the player or change files. Play was stopped;
the built place and default demo setting remain unchanged. The brief starter
click is not evidence of a completed C01 flow. No media capture deliverable was
requested for this baseline; UI observations were made directly during the run.

Known native limitations observed in this run:

- Studio automatically migrated legacy Compatibility lighting to Voxel/Soft
  when opening the file; its informational dialog was dismissed. No migrated
  file was saved. This requires separate visual review on the new engine.
- Local place 0 logged `rbxassethash` asset-resolution warnings: a valid
  universe/place is required. Avatar wrap-deformer warning also occurred.
  Neither remote permissions nor successful delivery of every texture is proven.
- The newly updated Studio content directory lacks the local M7 preview packs;
  no installation into that directory or permission change was performed.
  Use the existing documented install/asset-permission workflow for art review.
- The installed Rojo plugin tried the absent local sync server; the standalone
  `.rbxlx` nevertheless booted. Running a sync server is unnecessary for this test.

**AG-00 confirms a development base with a bounded boot check, not a releasable
game.** AG-01 can address the missing real template on this exact base. AG-02,
07D, production UI, native assets and owner release gates remain separate.
