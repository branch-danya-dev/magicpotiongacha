# AG-01 — Spellbook import decision and owner gate

**Status: BLOCKED / preflight only, not implemented or accepted.**
Base: `integration/ag00-base` @ **`7d6d47826e919683ee991c911185215cda0d3d2e`**,
[AG-00 Draft PR #29](https://github.com/branch-danya-dev/magicpotiongacha/pull/29).
[Windows and Ubuntu CI](https://github.com/branch-danya-dev/magicpotiongacha/actions/runs/43186127654)
passed on this exact head. AG-00 ordinary Play/build evidence is linked there.
Feature branch: `feat/ag01-spellbook-reproducible`.
Task: [Issue #28](https://github.com/branch-danya-dev/magicpotiongacha/issues/28).

The owner explicitly requested stopping when their Studio participation or
permissions are required. This PR records the findings and the next concrete
step; it does not upload assets, change access, add a placeholder, or alter
runtime/economy/schema. Existing files and historical evidence are preserved.

## Audit before implementation

The exact existing GLB is **239260 bytes**, SHA-256
`ff12f9f121daa74d444601240d3601a16849e1c9ee69dbf83a83c5db22b76a52`.
[Manifest](../assets/props/spellbook-lectern.manifest.json) records the source
inventory and explicitly empty native asset/permission fields.

- glTF 2.0: **10 nodes**, **9 meshes**, **23 material primitives**, **4194
  triangles**, **9 materials**, **0 images/textures**, no external buffer/image
  URI, animation or skin. The source site's “10 parts” is not a verified native
  MeshPart count. With separate glTF primitives the importer is expected to
  produce 23 MeshParts; actual export must be inspected.
- Source material factors and emissive extension are recorded verbatim as data
  in the manifest. Every source material is double-sided. Importer preservation
  of PBR factors/emission, final native material properties and draw calls are
  **NOT VERIFIED**; do not replace them speculatively with Neon or texture maps.
- `default.project.json` only includes `M7NatureTemplates` in ServerStorage.
  No Spellbook `.rbxmx`, mesh asset IDs, owner/experience IDs or permission receipt
  exists. GLB alone is not a Rojo-native template.
- `Main.server.luau` installs the adapter. `findTemplate()` searches ServerStorage,
  ServerStorage/PotionTycoon, then ReplicatedStorage/PotionTycoon. The current
  manual import is lost on rebuild. Missing/wrong-class templates return false
  silently; the procedural crystal remains.
- Current placement targets 6.5 studs high, bottom-centers on terrain with a
  fallback floor, and adds EnergyPoint/ParticlePoint. File bounds 6.24 × 5.664 ×
  6.24 and anchor offsets are inherited plan values, not new native measurements.
- **Contract defect to fix after the gate:** successful `ensure()` overwrites
  logical `anchor.Size` and `anchor.CFrame` with visual bounds. This conflicts
  with preserving click/prompt/upgrade reach. The missing-template baseline did
  not exercise this branch, so its ordinary Play does not certify the swap.
- Also requires validation before hiding the crystal, explicit bounded fallback
  diagnostics, clone ownership checks, and protection against repeated install
  wrappers. Current script stripping alone is not full template validation.

## Chosen delivery path (pending owner import, not claimed working)

Use one owner-authorized Studio import into the **existing private QA experience**,
with the correct user/group creator and private mesh permissions. Export the
resulting script-free Model as `assets/props/SpellbookLectern.rbxmx`, record all
referenced mesh/material IDs and hash the export. Wire that tracked file into
`ServerStorage.SpellbookLectern` in `default.project.json`. Subsequent clean Rojo
builds then carry the same template; no per-rebuild Import 3D, runtime InsertService
request, Toolbox code or auto-updating package is part of this proposal.

The exported file must actually reference persistent assets accessible to the
target experience. A local-only session import/cache and an unverified `.rbxmx`
do not prove delivery. Access must be checked again from a fresh build/session.
Roblox documents separate glTF primitive imports, creator selection and the
permission effect of insertion into an existing experience in its
[Importer guide](https://create.roblox.com/docs/studio/importer).

After the gate, validate template structure/assets before swapping; preserve the
logical anchor transform/size and prompts, keep clones anchored and non-colliding,
and validate local content loading/fallback as well as server structure. Do not
mark permission failures covered by a portable mock alone. Use the same model
on all qualities; only the two passive attachment anchors are planned (no new
emitters/lights). Source-derived upper estimate for 8 plots: 184 primitives and
33552 triangles before importer changes; this is **not measured GPU cost**.

## License receipt and unresolved date

Reviewed 2026-11-12: [model page](https://shuriken.studio/models/props/spellbook-lectern)
and [Free model license, version 2026-11-12](https://shuriken.studio/legal/models).
The current terms permit incorporating models into projects, including game
source/place files, while prohibiting standalone model distribution or Creator
Store listings. They state that the download-date version governs.

The repository first contains this GLB in `fd49911` dated **2026-11-07**. That is
not a download receipt. No license text/version from that acquisition is retained.
Therefore the manifest deliberately does **not** assert that today's version
governed the earlier download. Before admission, obtain that receipt, or download
the same model again under today's terms and verify the bytes/hash. No new model
download or asset admission was performed in this preflight. This corrects the
overbroad implication of the earlier audit; it does not discard the existing GLB.

## Exact owner step needed

1. Identify the existing **experience/universe and place ID**, plus its **user or
   group creator**. Do not create/publish a new game to satisfy this task. Confirm
   the license acquisition as described above.
2. In that experience's Studio edit session, import the selected GLB under that
   creator as a private project asset. Use scale unit Studs, preserve hierarchy
   and imported pivots, Merge Meshes off, Anchored on. Inspect importer warnings;
   do not turn on Creator Store distribution or auto-update packages.
3. Name the root Model `SpellbookLectern`. Export it using Save to File as XML
   **`SpellbookLectern.rbxmx`** into this branch's `assets/props/` directory.
   Retain the importer settings and all MeshIds/material references. Merely moving
   the model into the current place's ServerStorage will not survive Rojo.
4. Provide the creator/experience identifiers and evidence that the experience
   may use every restricted reference. No passwords, cookies or API secrets are
   needed. Asset upload/access changes are the owner step, not executed here.

If no suitable existing experience is available, remain BLOCKED and request a
separate owner decision; this task does not authorize game publication.

## Checks and resumption

| Gate | Current result |
| --- | --- |
| AG-00 dependency | PASS at exact base above; no merge needed to branch |
| GLB header/hash/structure | Inspected, matches issue; manifest contains source-only measurements |
| Existing tests/build | 1142 tests / 168 sources on confirmed base; final partial-PR SHA results in PR |
| New runtime/fallback/owner-isolation tests | NOT IMPLEMENTED; required after real template contract exists |
| Native import/IDs/experience permissions | BLOCKED, owner step above |
| Applicable acquisition license | BLOCKED, original receipt or verified reacquisition needed |
| Repeat-build book visibility, PC interaction/passive Essence | NOT RUN for a real template |
| Phone / eight clients / performance / real backend | NOT RUN / BLOCKED |
| AG-01 DONE / ACCEPTED; AG-02 visual gate | NO; remains blocked |

After receiving the export/permissions/receipt, inspect and pin its exact native
hierarchy, implement the visual-only adapter fixes and asset validation, add
meaningful failure/idempotency/ownership/hit-area tests, then run `npm run tools`,
`npm test`, the AG-00 build checker and exact-head Windows/Ubuntu CI. Perform a
fresh-checkout build, another rebuild and normal Play for visible models and
permission fallback, without admin currency or a temporary import. Report PC,
phone and all-eight-plot evidence separately; do not invent screenshots or video.
