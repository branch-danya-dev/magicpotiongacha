# Willow asset permissions audit — 2026-11-17

Read-only verification completed in the owner's native Chrome session. The owner resolved the agreements prompt; no agreement was accepted by the agent. No new uploads, permission changes, integration, merge or game publication occurred.

All five existing assets belong to the personal `crystymoore` account, not group `addout studio` (925845207). Every Configure page shows **Restricted**; every Collaborators page shows **No collaborators yet**.

| Asset | Roblox ID | Type | Privacy | Experience 10776120489 |
|---|---|---|---|---|
| Willow-Studio-6119_Scene | 81045114472619 | Animation | Restricted | No grant in export |
| Willow_Foliage | 103393042017627 | Mesh | Restricted | No grant in export |
| Willow_Trunk | 85732748826171 | Mesh | Restricted | No grant in export |
| Foliage base_color_texture | 79171837674186 | Image | Restricted | No grant in export |
| Bark base_color_texture | 77979867898740 | Image | Restricted | No grant in export |

**Correction:** the initial Studio record called ID 81045114472619 a model. Dashboard identifies it as an **Animation**, named `Willow-Studio-6119_Scene`.

## Experience access evidence

The individual asset's Experiences tab explicitly says previously granted experiences are not displayed. An empty panel is therefore not evidence of missing access. Following the official [View permissions procedure](https://create.roblox.com/docs/projects/assets/privacy#view-permissions), the audit opened the group's target game's **Configurations → Permissions → Assets** and exported the complete list.

The [original CSV](evidence/willow/permissions/10776120489_asset_permissions.csv) contains 54 asset rows, matching the Dashboard pagination total. None of the five exact Willow IDs occurs in the export. Thus no permission grant to **Experience 10776120489 / Place 125724638469407** is recorded at the time of this audit. This does not establish the status of any unrelated experience.

The game Overview also showed Private; no publication settings were changed. Creator Store listing status was not independently audited. Restricted use permissions are confirmed; do not equate that with a claim that metadata can never be viewed publicly.

## Evidence and limits

- Configure captures: [bark](evidence/willow/permissions/bark-configure.png), [foliage image](evidence/willow/permissions/foliage-image-configure.png), [foliage mesh](evidence/willow/permissions/foliage-mesh-configure.png), [trunk mesh](evidence/willow/permissions/trunk-mesh-configure.png), [animation](evidence/willow/permissions/animation-configure.png).
- [Game permissions screen](evidence/willow/permissions/experience-assets.png), [asset Experiences panel warning](evidence/willow/permissions/bark-experiences.png).
- [Structured audit and CSV SHA-256](../assets/environment/willow/source/roblox-permission-audit.json). Read-only accessibility snapshots accompany the captures.

These IDs belong to the intermediate 6,142-triangle import, before duplicate removal. The final 6,119-triangle FBX was not uploaded again. The isolated QA uses local EditableMesh/EditableImage data and none of these IDs. Granting the old IDs would not validate delivery of the final asset.

The Dashboard inspection blocker is closed. Production readiness remains gated on owner art review and a separately authorized final-asset upload/access plan. No new upload or access grant is implied by this audit. Runtime/asset bytes are unchanged; the four existing Willow asset checks pass. The prior full 1,419-test run remains the runtime verification baseline; no new native loading or CI run is claimed by this documentation update.
