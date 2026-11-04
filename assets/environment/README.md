# M7.1 provenance and import handoff

`manifest.json` distinguishes **selected external assets** from **actually shipped
original geometry**. `sha256=null`, `robloxAssetId=null`, `admitted=false` mean no
asset was acquired/admitted; they are not placeholders for fabricated proof.

The official [Quaternius pack page](https://quaternius.com/packs/ultimatestylizednature.html)
advertises Ultimate Stylized Nature (May 2022, 63 models, CC0). Its download link
opens the public Drive folder recorded in the manifest. The selected OBJ/MTL names
and file IDs were read from that official folder. On 2026-11-05 the attempted
BirchTree_1.obj download returned a **Quota exceeded HTML page**, rejected before
import. There is no downloaded archive or usable source asset hash to report.
License: [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/).

Independent blocker: the installed Game Development Studio guidance requires
canonical package verification/admission using `game-dev`, which is not installed.
Its routing skill says: “If `game-dev` is unavailable, report the missing local CLI
and the blocked workflow. Do not install software, change credentials, solicit a
key, or substitute an unrequested remote service.” No software/provider purchase,
account changes, Toolbox scripts or external service substitution were performed.

When the source and package pipeline are available:

1. Download only selected OBJ/MTL pairs from the recorded official folder, outside
   runtime. Verify file signatures/content, SHA-256 and CC0 proof per file.
2. Inspect referenced materials/textures and dependencies. Reject scripts, unknown
   URLs and unrelated assets. Keep originals and conversion provenance.
3. Normalize scale/pivot/materials, triangulate, inspect the actual mesh. Target
   <=2,000 triangles/tree and <=500/small prop; hard ceiling <20,000/mesh. These are
   **import targets, not measured values of unavailable meshes**.
4. Produce and verify the canonical package, record receipt/manifest digest and
   admit the exact verified package under the authorized plan.
5. Import through the owner's permitted Roblox asset workflow; record actual
   asset IDs/owner permissions, source hashes, transforms and conversion settings.
   No publication or paid action is authorized by this handoff.
6. Replace native descriptor visual types, retain all logical anchors, rerun
   integrity/regression/Studio checks and renew the same-camera visual review.

The current fallback consists of original `EnvironmentPlan` descriptors, Parts
and built-in Sphere SpecialMeshes. It uses **no external mesh IDs or textures**.
The Sphere mesh is needed because PartType.Ball does not preserve ellipsoid
proportions; see [Roblox SpecialMesh](https://create.roblox.com/docs/reference/engine/classes/SpecialMesh).
Source hashes normalize CRLF to LF, so Windows/Ubuntu check the same source bytes.
CI validates those hashes, the unchanged M6 sources and the World gameplay seam.
