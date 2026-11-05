# Task 05 / #19d — layered pilot forest

**Implemented in code and build; engine/art/device acceptance not claimed.**
On 2026-11-05 the owner explicitly removed screenshots, frames and video from
the ongoing workflow and requested the next task. No new media or camera helper
is produced. The ordinary full-game place is the handoff. PR #17 stays Draft.

## Result

The 15 isolated imported trees are replaced by 28 new tree assemblies in three
layers around the northwest pilot. Five silhouettes use the already admitted
Quaternius bark meshes, with different trunk proportions and four solid crown
lobes each. The old leaf-card meshes are omitted. These are new compositions of
existing bark and original native crown geometry, not newly imported tree assets.
Twenty-four fern groups, 11 large boulders, three mossy fallen logs and two clear
glades give the forest a ground layer. Existing pilot grass/flowers are retained.

The authored tree palette has darker lower lobes and lighter upper crowns, with
small color/scale variations. Pine and narrow birch forms break up broad oak,
apple and elder silhouettes. Each tree keeps three connected core crown lobes
even at Minimal; the fourth lobe is nearby detail. Trees remain upright, fallen
logs align to the terrain normal, and cut ends remain visible with moss culled.
New forest placement samples visible Terrain, excluding hidden floor slabs.

All forest objects are anchored/noncolliding/nontouching/nonqueryable. Crown
bounds reserve all eight original work floors and the central access route.
The plan rejects water planting and preserves the glades. The tree canopy fits
the protected placement radius even when rotated. Only the pilot perimeter is
dressed; the remaining farms/bazaar rollout is still task 08.

No new external asset IDs, textures, uploads, paid generation or dependencies.
The original admitted asset package and license/hash receipt remain unchanged.
The earlier rejected primitive-only pilot is not restored: the sculpted admitted
trunks remain, while the new crowns use native Sphere SpecialMeshes. The latter
support the authored ellipsoid dimensions; ordinary Ball parts do not provide
the same scaling behavior. See the official [SpecialMesh reference](https://create.roblox.com/docs/reference/engine/classes/SpecialMesh)
and [mesh scaling reference](https://create.roblox.com/docs/reference/engine/classes/DataModelMesh/Scale).
These references establish API semantics, not the appearance of this build.

## Quality and budgets

Forest LOD runs inside the existing EnvironmentView. It adds no render connection
or separate lighting/weather owner. Group anchors keep trunks and core crowns
together. Visibility has an 18-stud smooth distance band and a bounded temporal
fade; turning the camera or changing quality cannot instantly pop alpha. The
original local transparency is restored when the owner stops. No Instances are
created/destroyed while changing quality, and no textures are swapped.

| Forest visibility distance (studs) | Full | Reduced | Minimal |
| --- | ---: | ---: | ---: |
| Core silhouettes / logs / boulders | 290 | 240 | 185 |
| Extra crown lobes / log moss | 115 | 75 | Off |
| Fern undergrowth | 105 | 70 | Off |

Distance selection stays at most 2 Hz; alpha updates use the existing at-most
30 Hz loop and only write changing values. Trees/forest understory remain static;
this patch adds no motion slots. Task-04 grass wind and Reduce Motion are intact.
Hiding distant details reduces drawing, not the number of replicated Instances.

The forest contributes **190 parts**, including 127 native primitives and 63
admitted MeshParts. Of those native primitives, 118 have built-in Sphere meshes.
Exact imported forest mesh triangles: **30,722**. A planning charge of 1,024 per
sphere and 192 per cylinder produces **153,282** for the forest. Native geometry
is tessellated by the engine; these charges are estimates, not GPU measurements
or guaranteed renderer upper bounds.

The complete planned pilot art is **753 parts / 260,965 triangle charges**.
The explicit cap increases from **650 to 850 parts** and **150,000 to 300,000
triangle charges**. The inherited nonforest/grass subset still has its original
650/150,000 test limit. Texture memory stays 27.96 MiB / 12 catalog textures;
the inherited combined texture/lighting/particle/motion checks remain intact.
These limits do not count unrelated gameplay, Terrain or UI objects.

## Validation and handoff

964 cases: all 949 inherited tests plus 15 new forest tests. Coverage includes
determinism, all five forms and three depth layers, crown/work-zone clearance,
dry land and glades, crown bounds at rotation, connected core volumes, logs,
full-plan budgets, all quality tiers, continuous fades and invalid-distance
handling. Inherited atmosphere/asset/evidence hashes and 70 protected M6 files
are still checked. Compile/portable analysis covers 123 Luau sources.

Run `npm run tools`, then `npm test`. Build ordinary full-game Play with
`node scripts/build-local-preview.mjs`. No task-05 diagnostic/capture script is
needed. Art is enabled only in Studio; progress remains in memory, trading and
monetization stay disabled. The existing local atmosphere textures remain a
prerequisite on another computer.

The parent workspace handoff folder is `outputs/M7-19d-review`. Its manifest
records the exact committed source, place SHA-256, serialized-source validation
and Windows/Ubuntu CI result. No Studio start or visual evidence is asserted.

## Remaining limits

- Live appearance, terrain contact, material loading, translucency during LOD
  fades and actual frame time remain unverified. Code tests are not art approval.
- Physical smartphones, experience asset permissions and multiplayer load remain
  **BLOCKED**. The geometry budget increase especially needs device measurement
  before any release or island-wide dressing.
- Trees remain static; no new forest wind system was introduced. Further unified
  atmosphere/vegetation refinement belongs to task 06.
- Colored station proxies/crystal/bazaar models and previous UI issues remain.
  Tasks 06–08 are untouched. Task 08 still requires explicit final pilot APPROVED.
- No purchases, trade activation, merge or game publication.

The owner removed media delivery as a requirement; missing screenshots/video are
therefore not a blocker for continuing the ordered work.
