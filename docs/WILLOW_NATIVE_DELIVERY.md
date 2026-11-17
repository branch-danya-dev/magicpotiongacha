# Willow — authorized native delivery, 2026-11-17

**CODE CANDIDATE / NATIVE QA PLAY VERIFIED / RAW IMAGE DELIVERY ISSUE / OWNER ART PENDING / NOT INTEGRATED.**

The owner authorized final assets under addout studio (925845207), Restricted, and access to Experience 10776120489. Six assets were imported once from final `Willow.fbx` (SHA-256 `0fd537f88ab08ab59eceaad49529265b57b2bc33c5244c7a70bdb17590ca4a77`). The native importer showed 6,119 triangles, 28.38 × 23.80 × 13.48 studs. [IDs, Restricted evidence and saved grants](WILLOW_ASSET_PERMISSIONS.md). No additional paid generation, Creator Store distribution, game integration, merge or publication.

## Reproducible isolated scene

`assets/environment/willow/prepared/WillowRoblox.rbxmx` contains the exported native model: two MeshParts, nine bones, no scripts. The authoritative imported IDs are retained. Two SurfaceAppearances are prepared offline: Transparency for foliage and Overlay for bark. The initial LocalScript attempted to assign RenderFidelity and was rejected by Studio; that assignment was removed before successful Play verification. Protected material properties are no longer written at runtime, and the regression check covers this constraint.

Build with `node scripts/build-willow.mjs --native`; open `build/Willow-Native-Restricted-QA.rbxlx`, press F5. The source template is already included; no repeated upload is necessary. `scripts/willow/extract_native.py` records extraction/preparation from the preserved local raw import `build/willow/Willow-Imported.rbxlx`. Both the original upload-independent build and the native build remain available, with separate receipts. Neither maps production server Main, DataStores or gameplay remotes.

## Actual Studio Play verification

Windows Studio 0.747.0.7471481, local `.rbxlx`, account crystymoore. Ordinary F5 Play, not an external renderer. The scene was stopped and restarted successfully. Only its current Studio window is left open.

| Check | Result |
|---|---|
| Two native MeshParts | Instance-based preload Success for both exact IDs |
| Native materials | Bark and foliage visibly render; foliage gaps are transparent and double-sided |
| Imported animation | AnimationTrack Length = 8 seconds, IsPlaying = true; stopped/destroyed after test |
| Wind | Crown transform changes; Root transform remains identity and trunk CFrame remains fixed |
| Full / Reduced / Minimal | Runtime modes exercised with 20 trees; per-mode update cadence verified |
| Reduce Motion | All nine bones return to identity; wind is zero in the existing environment owner |
| Cleanup | QA folder/function/UI removed; GlobalWind restored; camera returns to Custom |
| Repeat F5 | WILLOW_READY again, final native geometry/materials visible |

Original captures: [Full/front](evidence/willow/native-full-front.png), [Reduced/angle](evidence/willow/native-reduced-angle.png), [Minimal/Reduce Motion](evidence/willow/native-minimal-reduce-motion.png). The visible personal inventory in Asset Manager is unrelated to the rendered model; runtime IDs and the permissions export identify the final group-owned assets.

### Delivery limitation that remains open

Raw foliage Image `101368619581292` returned **HTTP 502** when tested separately as an ImageLabel; IsLoaded was false after the initial check and a bounded retry. The bark ImageLabel loaded successfully. This is not reported as a clean raw-image delivery pass. The foliage's processed SurfaceAppearance does render, including alpha gaps. A local Studio session is not proof of a clean uncached remote-player load, even though the target Experience grant is confirmed.

An initial generic `PreloadAsync` call using bare strings incorrectly requested mesh/animation IDs as images (the log explicitly reports IncorrectAssetType). These failures are not mesh/animation permission failures: instance-based mesh preload and AnimationTrack playback subsequently passed. [Roblox documents](https://create.roblox.com/docs/reference/engine/classes/ContentProvider) that SurfaceAppearance itself is not supported by PreloadAsync. The raw foliage HTTP 502 remains a separate unresolved observation. No workaround permission change or duplicate upload was performed.

## Preliminary measurements

Ten-second windows, Studio graphics selector Q6; desktop under concurrent use. Frame intervals include the whole isolated scene and are not GPU timings or a controlled target-device benchmark. Native meshes use zero EditableMesh/EditableImage resources.

| Visible trees / mode | Median frame ms | p95 frame ms | p95 wind scheduler ms | Updates / 10 sec |
|---|---:|---:|---:|---:|
| 1 / Full | 4.37 | 6.46 | 0.048 | 246 |
| 20 / Full | 4.39 | 6.06 | 0.275 | 300 |
| 20 / Reduced | 4.24 | 5.68 | 0.124 | 150 |
| 20 / Minimal | 4.24 | 5.70 | 0.049 | 60 |

The first sample includes a focus/cadence interruption; do not use it to infer a 1-to-20-tree speedup. Studio total process memory was approximately 2.9 GB, not per-asset memory. [Filtered native telemetry](evidence/willow/native-studio-checks.json).

## Remaining gates

- Owner art approval: pending. Existing shape issues (peaked clusters, faceted wood, narrow side silhouette) have not been artistically accepted.
- Raw foliage Image HTTP 502 / clean remote-client fetch: unresolved.
- Published/private-server client, multiplayer, real phone, low-end GPU, GPU/alpha-overdraw profiling: not run.
- Candidate GitHub Windows/Ubuntu CI: not run; this branch is local. `npm run tools` passed. Final `npm test` exited 0: **1,396 Luau + 24 Node = 1,420 tests**, 294 Luau sources compiled. [Machine-readable checks](evidence/willow/native-checks.json). Repeating extraction and the native Rojo build produced byte-identical outputs.
- No integration or production admission. The 60-row grant export proves permissions, not every runtime delivery scenario.

Exact commit and final artifact hash are written to `build/willow/native-delivery.json`; the asset manifest pins source/export/template/receipt bytes.
