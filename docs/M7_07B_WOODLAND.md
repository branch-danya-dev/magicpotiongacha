# 07B — complete Quaternius woodland in the pilot

## Input and owner gate

The owner accepted the delivered 07A candidate `04d3aea` in chat on 2026-11-06:
“Да, все супер. Далее к наполнению и ассетам. Технические пробелы вроде как устранены”.
This authorizes 07B. It is owner-reported acceptance, not a new agent Studio run,
phone measurement, experience permission check, or final 07D artistic approval.

**07B IMPLEMENTED in code/assets/build; new native appearance NOT VERIFIED.**
One ordinary full-game build is delivered without a camera helper or media task.
07C composition, final 07D approval, UX and eight-farm rollout remain subsequent
stages. No Lighting, camera, physical boundary, gameplay, economy or save edits.

## What changes in the actual scene

- All **29 trees** use complete, already imported Quaternius bark and foliage
  meshes: CommonTree_1 **10**, CommonTree_3 **8**, CommonTree_5 **4**, Pine_2 **4**,
  TwistedTree_1 **3**. Three existing planting layers and clearings are preserved.
  No Sphere SpecialMesh crowns remain in the active forest; this replaces the
  whole pilot forest, not a few sample props. Five source silhouettes, varied
  height/rotation and subtle leaf tint give recognizable differences.
- **29 undergrowth groups:** 12 ferns, six flowering shrubs, six clover patches,
  five wildflower groups. Eleven larger boulders remain. Three fallen-wood props
  reuse the real curved CommonTree_3 bark mesh, grounded and aligned to slopes;
  these are derivative fallen branches, not newly imported stump/log models.
- The **456-plant meadow** retains its count and protected paths. Short-grass
  scale changes from 4.8–5.9 to 3.0–4.1, with less vertical compression; tall grass
  appears every 11th grass site instead of every 23rd. Flowers use three quiet
  tint variations. The palette comes from the same already reviewed pack.
- Bounds come from the actual imported MeshPart Size/CFrame, not assumed crown
  widths. Every orientation stays outside all eight factory footprints, the
  common route and clearings. Nature is inert/noncolliding; the accepted 07A
  physical boundaries and camera code are unchanged.

## Asset provenance and bounded rendering change

The original Standard free archive hash was rechecked locally:
`298f6732b872e4cf7b30e6e7abf9641c7f6dc6b326df37ac089533ed7e3d58c9`.
The bundled [CC0 license](../assets/environment/megakit/License_Standard.txt),
original [source audit](../assets/environment/megakit-source-audit.json) and all
parent receipt hashes remain exact. No paid pack, Marketplace scripts, new IDs,
new maps, shader package, upload or second provider package is introduced.

`game-dev` is unavailable on PATH. The owner's earlier explicit direct-workflow
exception for these 14 models still applies; this step derives presentation
settings from that admitted subset. It does not claim a canonical game-dev receipt
or broaden permission to a new external package. The immutable original XML is
retained; both current projects use a separately sealed woodland XML.

[Woodland receipt](../assets/environment/woodland/receipt.json) records the source,
tier, parent hashes, generator, actual file roster and limitations.
[Offline inspection](../assets/environment/woodland/inspection.json) records
geometry and alpha diagnostics. `scripts/prepare-woodland.py` reproduces the
derivation offline with Python/Pillow; CI requires only the independent Node check.

The prepared primitives have **zero exact duplicate triangles**. This excludes
that narrow source defect; it does not prove zero intersections or GPU z-fighting.
The principal tree atlas contains **11.068% fractional-alpha pixels**, pine
**0.890%**, twisted-tree **3.048%**. That is evidence of soft alpha edges, not proof
of the cause of every previously observed Low-quality artifact.

For exactly **11 cutout foliage MeshParts** in the template library, the derivative
sets Transparency **0.02**, CastShadow **false**, RenderFidelity **Precise**. Roblox
documents this transparency range as a smooth-blending path rather than opaque
coverage; [official behavior and tradeoffs](https://create.roblox.com/docs/art/modeling/surface-appearance).
Geometry/UVs, mesh/map IDs, SurfaceAppearance AlphaMode and all texture bytes stay
unchanged. Trunks, rocks and opaque grass keep their original settings. Precise is
serialized before play; no restricted runtime property write or texture churn.

**Tradeoff:** transparent foliage can increase overdraw and sorting errors and
does not cast canopy shadows. Precise prevents automatic simplification of these
already bounded small meshes. This is a targeted candidate for the old stippling,
not a claimed native fix. Ordinary Play at Low/Automatic, Reduced, Full and Manual
5 must confirm edge quality, overlaps, forest readability and cost before 07D.

## Budgets and regression evidence

| Measure | 07A | 07B | Existing cap |
| --- | ---: | ---: | ---: |
| Forest objects represented by BaseParts | 190 | 112 | 260 |
| Forest triangles / previous native planning charges | 153282 | 69170 | 195000 |
| Whole pilot art Parts, including eight ridge blockers | 1175 | 1097 | 1320 |
| Whole pilot mesh triangles + native prop planning charges | 324957 | 246032 | 465000 |
| Resident texture estimate | 30.484 MiB | 30.484 MiB | 32 MiB |

The forest now uses exact admitted mesh triangle counts with **zero native proxy
parts**. Other props still use conservative planning charges; these are not GPU
measurements. Four inherited fence fillers, gameplay anchors, Terrain, UI and
weather pools remain outside the historical art count, as before. BaseParts,
instances, draw calls and GPU cost are distinct; a lower count is not an FPS claim.

Lighting caps remain Full **6**, Reduced **3**, Minimal **0**. Canopy wind is attached
to real foliage and charged per moving mesh against the existing **12/4/0** pool.
Meadow movement remains **64/32/0**; Reduce Motion restores base transforms.
One EnvironmentView still owns quality/LOD/wind/weather; no new connection loop.

The suite retains **1037 prior scenarios** and adds **8** 07B integration cases.
Four old forest tests are updated to the requested mesh/bounds/fallen-wood contract
instead of asserting the visually rejected spheres and cylinders. No gameplay,
authority, persistence, camera or 07A scenario is removed. New checks cover the
whole forest/catalog, rotated real bounds, undergrowth diversity, meadow footprints,
complete pool limits and wind accounting. The independent package checker permits
only the three documented foliage-property changes against the original XML.
Final build SHA, test log and exact Windows/Ubuntu results accompany the delivery.

## Remaining acceptance

Open the single delivered `M7-07B-Play.rbxlx` and press F5. Walk the pilot and its
forest edge with ordinary UI/camera; check all five tree silhouettes, flowers,
ferns, ground contact, route clearance and leaf edges while turning. Compare Full,
Reduced and Minimal, Reduce Motion and Roblox Low/Automatic/Manual 5. Use the
existing `EnvironmentReview` commands from [07A](M7_07A_BATCH_RESULT.md) for weather.
No screenshots, video or new camera helper are required.

The new forest has not been viewed by the agent in native Studio. Smooth-alpha
sorting, thin-leaf readability and real-device performance remain unverified;
physical phones, experience asset permissions and live multiplayer remain BLOCKED.
PR #17 stays Draft. No merge, publishing, paid purchase or trade activation.
