# M7 — revised sequential world rework

Owner's 2026-11-05 sequence. Every task must show a visible improvement in ordinary
full-game Play, with a runnable Studio place, matched before/after cameras at
graphics 5/10, actual gameplay video, remaining defects and regression checks.
Code/tests or a separate beauty scene alone do not satisfy visual acceptance.

| Order | Task | Scope and acceptance | Current status |
| --- | --- | --- | --- |
| 01 / #18a | Critical defects | Smooth time changes including diagnostics; fence collisions; fall recovery; mobile Factory entry. Continuous actual Play evidence. | Implemented; [visual review pending](evidence/m7-18a/README.md) |
| 02 / #19a | Island landscape | One island for 4×2 farms and bazaar; hills, slopes, shoreline/water; hide exposed common base; retain gameplay coordinates and access. Individual farm integration follows in 03. | Implemented; [visual review pending](evidence/m7-19a/README.md) |
| 03 / #19b | Farm integration | Remove green plot plate; thin yellow ground boundary; local soft green build affordance; natural paths and approaches. | Implemented; [first visual checkpoint pending](evidence/m7-19b/README.md) |
| 04 / #19c | Grass and flowers | Volumetric varied grass, visible wind, flowers/clover; clear station/path zones; video at graphics 5/10. | [Code/build prepared; Studio deferred by owner](M7_TASK04.md) |
| 05 / #19d | Forest | Expressive stylized trees, deep edge forest, understory, rocks, fallen logs and clearings; distant vegetation optimization. | Not started |
| 06 / #19e | Fantasy atmosphere | Artistic sky/horizon; spatial light and haze; restrained pollen/glints; unified weather/wind/vegetation cycle; convincing Reduced Play. | Not started |
| 07 / #19f | Gameplay props | Replace pilot station blocks, crystal, lanterns and nearby bazaar; coherent construction/upgrade states; preserve mechanics/economy. | Not started |
| 08 / #19g | Whole-island rollout | Dress remaining seven farms and bazaar; coherent variation; routes/collisions/interactions; regression and available performance checks. | Blocked by final pilot APPROVED |

After 03: first visual checkpoint — island/farm no longer read as rectangular
platforms. After 06: nature acceptance — living fantasy forest with grass, relief,
trees and atmosphere. After 07: full pilot artistic gate; only the owner's explicit
**APPROVED** permits 08. Earlier Gate A approval is historical and does not approve
the new completed pilot, the UI gate or the eight-farm rollout.

PR #17 remains Draft on `feat/m7-environment-artpass`. No merge or publishing.
Physical smartphones, experience asset permissions and multiplayer load remain
BLOCKED until actually checked. No paid acquisition or trade activation.
