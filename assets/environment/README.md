# M7.1 inspected asset provenance

The owner approved the direct workflow on 2026-11-05: static inspection, local
optimization and Roblox Studio import of 14 selected free Quaternius models.
Missing game-dev is no longer a blocker for this explicitly authorized subset.
This is a documented direct import, **not a canonical game-dev receipt**.

Source: [Stylized Nature MegaKit Standard](https://quaternius.itch.io/stylized-nature-megakit),
2024 free Standard archive, 68 models. Archive SHA-256:
`298f6732b872e4cf7b30e6e7abf9641c7f6dc6b326df37ac089533ed7e3d58c9`.
[Exact bundled CC0 license](megakit/License_Standard.txt). The newer general QAL
site license is not used as proof for this archive or generalized to all releases.

[Source audit](megakit-source-audit.json) records ZIP integrity/safe paths, local
glTF dependencies, buffer/index validation, hashes and original triangle counts.
No source scripts, plugins, animations or remote code were executed/admitted.

## Reproduction

1. Acquire that exact archive from the author; verify its SHA-256 and bundled
   license. Extract the selected glTF files/dependencies into staging.
2. Run `scripts/prepare-environment-assets.py` with Blender 4.5.9 LTS, background,
   factory settings and disabled autoexec, as documented in the script. It checks
   selected source hashes, separates materials, normalizes size/pivot, simplifies
   bark, retains whole connected leaf cards and downsizes maps to <=1024.
3. Import the prepared `M7NatureLibrary.gltf` with Roblox Studio's importer.
   Anchor models, disable collisions/touch/query, enable DoubleSided and set
   foliage SurfaceAppearance AlphaMode=Transparency. Save the local import place.
   The importer produced actual rbxassetid references even with model upload off;
   model publication and game publication are separate from mesh/texture import.
4. Run `python scripts/admit-environment-assets.py IMPORT.rbxlx PREPARED_DIR`.
   It permits only Model/MeshPart/SurfaceAppearance and grounds each model. Keep
   `License_Standard.txt` in the admitted directory before sealing the receipt.
5. Run the normal verification command and inspect the actual Studio result.
   Re-importing produces new IDs: renew the receipt and screenshots together.

[Receipt](megakit/receipt.json) includes actual mesh/map IDs from Studio's saved
XML, import-place hash and all admitted file hashes. [Preparation report](megakit/prepared/preparation.json)
records exact counts/settings. 14 models / 21 inert MeshParts; trees <=2000,
small props <=500. Twelve unique maps total 27.96 MiB at RGBA8 plus mipmaps.
Prepared interchange files and textures are included; originals stay in staging.
Runtime stone paths use native Slate and no shadow casting; their templates set
[RenderFidelity.Precise](https://create.roblox.com/docs/reference/engine/enums/RenderFidelity)
before play to preserve thin faces under engine LOD; other assets retain
the inspected texture maps. No guessed IDs or Toolbox content.

The assets render in the owner's local Studio session. Permission/loading in a
published experience and on a second account is **not verified**. Real phone,
multiplayer, and artistic acceptance are separate outstanding gates.

The old Ultimate Stylized Nature download attempt and rejected native pilot remain
in manifest.json as history only; neither is the current source. Historical
captures pin archived source snapshots and are not evidence for this revision.
