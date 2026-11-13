# AG-69 — M7 texture delivery preflight

**BLOCKED / OWNER UPLOAD APPROVAL REQUIRED. Not DONE; AG-70 (#41) not started.**

Issue [#40](https://github.com/branch-danya-dev/magicpotiongacha/issues/40).
Branch `feat/ag69-m7-asset-restore`, stacked on Draft PR #39 / `feat/ag68-world-look`
at `418d85f519232ea10e373a4b1944132ee389acd2` (Windows/Ubuntu CI
`43482710612` PASS). AG-00 `7d6d47826e919683ee991c911185215cda0d3d2e` is an
ancestor. The source worktree was clean before branching. Exact delivery HEAD
and its own CI results belong in this task's Draft PR; base CI is not this PR's CI.

## Diagnosis and scope

The ordinary game references twelve `rbxasset://` files that are not bundled in
Rojo's place and have no Roblox IDs. The AG-68 native evidence records twelve
File-not-found / invalid-image failures. That evidence is the **before** baseline,
not a new AG-69 F5 run. Installing into a developer's `version-*/content` masks the
problem locally and does not establish Experience access.

This preflight changes no runtime file, original texture, historical receipt,
palette, release flag, economy, save, remote, HUD or Spellbook VFX. No new
controller, reload loop, Marketplace package or upload tool was added. It adds a
closed source/delivery manifest, integrity checks, exact-byte upload staging,
negative tests and owner instructions. No local vendoring/admission is needed:
these are original assets already tracked in the game repository.

## Verified sources and exact proposed upload set

Canonical source of truth: [ag69-delivery.json](../assets/environment/ag69-delivery.json).
It maps all twelve **original paths and legacy URIs** to upload names, exact
SHA-256, byte count, dimensions, existing receipt/license, and **null** Image/Decal
IDs. Unknown ownership/access is explicitly false, never implied by CC0.

| Proposed filename | Original folder / filename | Pixels | Bytes |
|---|---|---:|---:|
| AG69_Sky_BK.png | stability-sky/bk.png | 256×256 | 11613 |
| AG69_Sky_DN.png | stability-sky/dn.png | 256×256 | 667 |
| AG69_Sky_FT.png | stability-sky/ft.png | 256×256 | 10935 |
| AG69_Sky_LF.png | stability-sky/lf.png | 256×256 | 13086 |
| AG69_Sky_RT.png | stability-sky/rt.png | 256×256 | 11899 |
| AG69_Sky_UP.png | stability-sky/up.png | 256×256 | 7065 |
| AG69_Sun.png | atmosphere/sun.png | 128×128 | 4431 |
| AG69_Moon.png | atmosphere/moon.png | 128×128 | 1897 |
| AG69_Mist.png | atmosphere/mist.png | 128×128 | 3429 |
| AG69_Rainbow.png | atmosphere/rainbow.png | 256×128 | 12943 |
| AG69_Meadow.png | polish/meadow.png | 128×128 | 4354 |
| AG69_Star.png | polish/star.png | 64×64 | 862 |

All folders are under `assets/environment`. Total: **83,181 encoded bytes**, or
1,982,464 decoded RGBA8 bytes before mipmaps. No texture resolution/budget increase.

Provenance: original project-authored mathematical images, no downloaded pixels,
Nintendo/Zelda images or external provider output. Authoring sources are
`scripts/create-stability-sky.py` (uses `create-fantasy-sky.py`),
`scripts/create-atmosphere-assets.py` and `scripts/create-polish-assets.py`.
Their LF-normalized hashes and each byte-exact PNG/license match the original
receipts. The licenses dedicate the images/generators to **CC0-1.0**, permitting
use/modification/distribution in this Roblox project; this does not grant Roblox
platform access. No individual human author is asserted beyond the repository's
original project contribution. Existing receipt commits:

- stability-sky: `04d3aea63964e86c3a0d46f49ec055971b3bfca6`;
- atmosphere: `39788eafaf93de4c21f7817f0aff4cb4e38ffd35`;
- polish: `8c91195d6b2f94456646ad045e624e07e943bf23`.

Unmodified generators were rerun in isolated `build/AG69-regeneration`, preserving
the repository originals. All twelve resulting PNGs match byte for byte:
[source-reproduction.json](evidence/ag69/source-reproduction.json).
The inherited native-adjacency seam test remains enabled; mathematical continuity
does not prove Roblox's uploaded texture sampling or visual seam acceptance.

## Approval requested — no Roblox action performed yet

The proposed operation is to upload **only the twelve files above** as **Restricted**
images owned by **addout studio / Group 925845207**, then grant/verify use only for
**Experience (Universe) 10776120489**, whose existing private place is
**125724638469407**. No Creator Store listing, Open Use, collaborator grant,
ownership transfer, Robux expense, place publication or release enablement.
If any workflow requires those extra actions, stop and describe the blocker.

Issue #40 explicitly requires separate approval before upload/access changes.
The previous AG-67B approval covers three different PNGs and is not reused here.
Asset Privacy must be checked again **before** import; an old confirmation does
not prove the new assets' eventual privacy. Roblox documents that Open Use and
game access grants are irreversible. A game grant may also give access to that
game's owner; it is distinct from making the game public. See
[Roblox asset privacy](https://create.roblox.com/docs/projects/assets/privacy).

## Executable owner/agent procedure after approval

1. From this checkout run `node scripts/check-ag69.mjs --stage`. This validates the
   closed roster, hashes, original receipts/licenses/generators, PNG CRCs/decoded
   rows and target IDs, then creates only identical copies in `build/AG69-upload`.
   Unexpected files in that directory stop staging. It performs no upload.
2. Open the existing private Experience in Studio; verify Group **925845207**,
   Universe **10776120489**, Place **125724638469407**. In Creator Dashboard select
   the group and verify Asset Privacy makes new Images/Decals Restricted. If off,
   do not change a group-wide setting under this approval: request the owner.
3. In Asset Manager bulk image import choose the twelve staged PNGs with group
   ownership. Inspect the final selection/creator before Start Import. Stop for
   any purchase, Open Use, unknown owner, moderation failure or inaccessible UI.
4. Record the **Image ID used by texture properties**, any Decal wrapper ID,
   creator Group ID, moderation status and Restricted state for each file. Do not
   guess an Image ID from a Decal ID or a similarly named asset. Resolve its actual
   dependency through Studio/Dashboard and include supporting evidence.
5. In each asset's Permissions → Experiences, inspect whether Universe
   **10776120489** already has access. If missing, after approval add **that Universe
   ID only**, then Done. Never substitute the Place ID. Verify all dependent Image
   IDs, including any Decal wrapper used by the workflow. Capture/export the
   Experience's Configurations → Permissions list. Stop if the owner cannot grant
   access. Do not treat a successful creator-only preview as game permission.
6. Fill the manifest and retain upload/ownership/access receipts. Add one shared
   immutable ID mapping used by `EnvironmentView` (sky faces, sun/moon, sprites,
   preload) and `EnvironmentArt` (meadow). Keep `EnvironmentView` the sole owner
   and the existing once-per-session preload; no texture churn or new remotes.
   Update preservation checks only at the explicitly reviewed asset-URI seams;
   retain checks for all gameplay, Spellbook/HUD, palette and release flags.
7. Build from a clean checkout with no Studio content install. Compare repeat
   Rojo hashes; run ordinary F5 and independently verify the **correct private
   Experience context**, not an unassociated local place. Use the existing
   unpublished testing workflow only. If proving the context needs publishing or
   privileged owner action, stop with that precise blocker instead.
8. Record the twelve individual preload outcomes and completion (not just an
   initial zero count). Expected final `assetFailures=0`. Exercise all eight
   plots, OFF/AG68, Full/Reduced/Minimal, Reduce Motion, E/mouse +5 Essence and
   lighting restoration. Capture matched day/sunset/night/rain near/wide pairs
   against the AG-68 baseline; check seams, sun/moon, fog/rainbow/meadow/stars.
   Only then propose AG-69 completion and hand off to AG-70 #41.

## Fallback and rollback

Until approval, the game stays byte-identical to PR #39, including its existing
missing-texture defect. No fake IDs, hidden logs or local content workaround.
After integration, retain the historical URI map for explicit local diagnosis;
it is **not** a production fallback. If a private asset fails, keep native scene
geometry/lighting and gameplay alive, report the failing ID, and hide only its
unavailable sprite. A failed sky set must fall back as a complete set, rather
than mix arbitrary faces. Implement/test this within the existing visual owner.
Code rollback returns the reviewed asset mapping/seams to the PR #39 baseline,
leaving saved data untouched. Reverting Git cannot revoke Roblox game grants.

## Checks and remaining blockers

`node scripts/check-ag69.mjs` is **source preflight**, not upload/permission PASS.
`node scripts/check-ag69.mjs --require-delivery` deliberately exits **2 / BLOCKED**
in this patch. It must not be made green by filling booleans without native proof.
Nine Node tests cover correct originals, tampering/CRC/trailing data, missing or
duplicate paths, hash/dimension mismatch, changed license/generator, wrong owner
or Universe, unsupported approval claims and the nonzero delivery gate.

| Gate | Status in this preflight |
|---|---|
| Twelve source hashes, CC0 receipts, PNG structure, regeneration | PASS |
| Nine new preflight/negative tests | PASS |
| Inherited 1268 Luau tests, compile/analyze, Rojo, Windows/Ubuntu CI | Exact-HEAD results recorded in Draft PR |
| Roblox upload / moderation / owner / Restricted | BLOCKED: owner approval; not attempted |
| Correct Experience access for all twelve images | BLOCKED: no canonical IDs yet |
| Clean F5, all eight plots, matched after captures, quality controls | NOT RUN for AG-69; requires integration after approval |
| Actual smartphones / 2–8 clients | NOT RUN |
| Owner artistic acceptance | OPEN; AG-70 not started |
| Merge / place publication / public access | NOT PERFORMED |

Known inherited defects remain: twelve texture load failures, graphics-5 shadow
stippling, mobile starter-modal occlusion, unfinished outer-plot art. This PR
does not claim to fix them before upload and native verification.
