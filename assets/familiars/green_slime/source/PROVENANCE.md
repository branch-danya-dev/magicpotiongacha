# Green Slime source receipt

Owner supplied this existing Meshy model for Issue #48. No model generation,
paid API call, remesh or replacement texture was performed for AG73.

On 2026-11-15 the owner confirmed in the task conversation:
“Платный тариф, модель создана в моём аккаунте” (paid plan, generated in my account).
This is an owner attestation; the subscription invoice, Meshy task ID, original
prompt and input reference provenance were not supplied or independently audited.

[Meshy's ownership guidance](https://help.meshy.ai/en/articles/10137554-what-is-the-ownership-of-the-generated-models)
states that paid subscribers own generated outputs, subject to input rights and
the service terms. The [terms](https://www.meshy.ai/terms-of-use), reviewed on
2026-11-15 (page dated 2026-09-19), apply. These files are owner-provided project
assets, **not CC0**, and this receipt does not grant a separate redistribution
license to unrelated users. Repository inclusion is for the owner's requested
project delivery. Roblox asset permissions have not been created or verified.

| Local supplied file | Bytes | SHA-256 |
| --- | ---: | --- |
| `Meshy_AI_model_20261114_image-to-3d-texture.fbx` | 2,950,252 | `f3457fb1081549c6634e844350eb7e6fb24aaed39dc1a8814e28a730b18c9c7f` |
| `Meshy_AI_model_20261114_image-to-3d-texture.png` | 2,836,714 | `631f17ac3724ab7b689c11c5f038242ca68bb38198058c59ab84cf47337b5805` |

The copies here retain those exact bytes. The original files in the owner's
OneDrive/Desktop folder were not modified. The PNG is 2048×2048 RGBA.

## Recorded discrepancy with Issue #48

The FBX hash matches the issue. The supplied PNG does **not** match the issue's
`0af4adc1a06403bb316b2273217c06e145951eb51c909c32d5259da158148254`.
The supplied PNG is byte-identical to the complete PNG embedded in the verified
FBX (offset 113023). That provides a consistent original mesh/texture pair;
the recipe verifies both hashes and the embedded bytes before proceeding.
We have not claimed to retrieve the different PNG described by that issue hash.

Factory-empty import in Blender 4.5.9 found exactly `geometry_0`; no Cube,
Camera or Light. This differs from the issue's earlier inspection. The export
selects only the intended mesh and armature regardless. The 35 original boundary
edges are the two eye rims (16 and 19 edges); they are preserved, not filled.
