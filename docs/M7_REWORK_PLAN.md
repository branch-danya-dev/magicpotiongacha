# M7 — revised sequential world rework

Owner's 2026-11-05 sequence, amended by the latest instruction: continue
**without frames, screenshots or video**. Deliver code, an ordinary full-game
Studio build, regression checks/Windows+Ubuntu CI, and honest remaining limits.
No media production or diagnostic camera helper is required for subsequent work.
Historical evidence remains immutable. Passing code/build checks does not imply
that unperformed Studio, artistic or real-device checks passed.

| Order | Task | Scope and acceptance | Current status |
| --- | --- | --- | --- |
| 01 / #18a | Critical defects | Smooth time changes including diagnostics; fence collisions; fall recovery; mobile Factory entry. Continuous actual Play evidence. | Implemented; [visual review pending](evidence/m7-18a/README.md) |
| 02 / #19a | Island landscape | One island for 4×2 farms and bazaar; hills, slopes, shoreline/water; hide exposed common base; retain gameplay coordinates and access. Individual farm integration follows in 03. | Implemented; [visual review pending](evidence/m7-19a/README.md) |
| 03 / #19b | Farm integration | Remove green plot plate; thin yellow ground boundary; local soft green build affordance; natural paths and approaches. | Implemented; [first visual checkpoint pending](evidence/m7-19b/README.md) |
| 04 / #19c | Grass and flowers | Volumetric varied grass, visible wind, flowers/clover; clear station/path zones; quality-tier checks. | [Code/build delivered; media requirement waived](M7_TASK04.md) |
| 05 / #19d | Forest | Expressive stylized trees, deep edge forest, understory, rocks, fallen logs and clearings; distant vegetation optimization. | [Implemented; code/build checks, no media requested](M7_TASK05.md) |
| 06 / #19e | Fantasy atmosphere | Artistic sky/horizon; spatial light and haze; restrained pollen/glints; unified weather/wind/vegetation cycle; convincing Reduced Play. | [Implemented in code/build; Studio appearance unverified, media waived](M7_TASK06.md) |
| 07 / #19f | Gameplay props | Replace pilot station blocks, crystal, lanterns and nearby bazaar; coherent construction/upgrade states; preserve mechanics/economy. | [Implemented in code/build; final pilot artistic approval pending](M7_TASK07.md) |
| 08 / #19g | Whole-island rollout | Dress remaining seven farms and bazaar; coherent variation; routes/collisions/interactions; regression and available performance checks. | Blocked by final pilot APPROVED |

After 03: first visual checkpoint — island/farm no longer read as rectangular
platforms. After 06: nature acceptance — living fantasy forest with grass, relief,
trees and atmosphere. After 07: full pilot artistic gate; only the owner's explicit
**APPROVED** permits 08. Earlier Gate A approval is historical and does not approve
the new completed pilot, the UI gate or the eight-farm rollout.

PR #17 remains Draft on `feat/m7-environment-artpass`. No merge or publishing.
Physical smartphones, experience asset permissions and multiplayer load remain
BLOCKED until actually checked. No paid acquisition or trade activation.
