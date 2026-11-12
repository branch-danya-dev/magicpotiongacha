// Deterministic repair of material factors omitted by Studio's GLB importer.
// This never creates/uploads meshes; it only edits properties of the real export.
import { readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import assert from 'node:assert/strict';
export const sha = b => createHash('sha256').update(b).digest('hex');
export const assetPath = 'assets/props/SpellbookLectern.rbxmx';
export const manifestPath = 'assets/props/spellbook-lectern.manifest.json';
export const meshProperties = xml => [...xml.matchAll(/<Item class="MeshPart"[^>]*>\s*<Properties>([\s\S]*?)<\/Properties>/g)].map(m => m[1]);
export const property = (p, key) => p.match(new RegExp(`<[^ >]+ name="${key}">([^<]*)<`))?.[1];
export const meshId = p => p.match(/<Content name="MeshContent">\s*<uri>(rbxassetid:\/\/\d+)<\/uri>/)?.[1];
const srgb = n => Math.round(255 * (n <= .0031308 ? 12.92 * n : 1.055 * n ** (1 / 2.4) - .055));
export function sourceContract() {
  const bytes = readFileSync('assets/props/spellbook-lectern.glb');
  assert.equal(bytes.length, 239260);
  assert.equal(sha(bytes), 'ff12f9f121daa74d444601240d3601a16849e1c9ee69dbf83a83c5db22b76a52');
  assert.equal(bytes.readUInt32LE(0), 0x46546c67);
  assert.equal(bytes.readUInt32LE(4), 2);
  assert.equal(bytes.readUInt32LE(8), bytes.length);
  const gltf = JSON.parse(bytes.subarray(20, 20 + bytes.readUInt32LE(12)));
  assert.equal(gltf.images?.length || 0, 0);
  assert.equal(gltf.textures?.length || 0, 0);
  assert(gltf.buffers.every(b => !b.uri));
  return gltf.meshes.flatMap(mesh => mesh.primitives.map((p, i) => {
    const material = gltf.materials[p.material];
    const rgb = material.pbrMetallicRoughness.baseColorFactor.slice(0, 3).map(srgb);
    // Explicit bounded approximation. No invented maps, global reflectance or lights.
    const nativeMaterial = material.name === 'Gold' ? 1088 : material.emissiveFactor ? 288 : 272;
    return { name: mesh.name + (i === 0 ? '' : i + 1), sourceMaterial: material.name,
      sourcePrimitive: i, sourceMesh: mesh.name, triangles: gltf.accessors[p.indices].count / 3,
      rgb, color: 0xff000000 + rgb[0] * 65536 + rgb[1] * 256 + rgb[2], nativeMaterial };
  }));
}
export function normalize(xml) {
  const contract = new Map(sourceContract().map(p => [p.name, p]));
  let count = 0;
  const normalized = xml.replace(/(<Item class="MeshPart"[^>]*>\s*<Properties>)([\s\S]*?)(<\/Properties>)/g, (_, start, props, end) => {
    const spec = contract.get(property(props, 'Name'));
    assert(spec, 'Unexpected native mesh');
    contract.delete(spec.name); count++;
    assert(meshId(props), 'Persistent native mesh ID required');
    const values = { DoubleSided: 'true', Anchored: 'true', CanCollide: 'false', CanTouch: 'false',
      CanQuery: 'false', Color3uint8: String(spec.color), Material: String(spec.nativeMaterial), Reflectance: '0' };
    for (const [name, value] of Object.entries(values)) {
      const pattern = new RegExp(`(<[^ >]+ name="${name}">)[^<]*(<)`);
      assert(pattern.test(props), `Missing exported property ${name}`);
      props = props.replace(pattern, (_, a, b) => a + value + b);
    }
    return start + props + end;
  });
  assert.equal(count, 23); assert.equal(contract.size, 0);
  return normalized;
}
if (process.argv.includes('--normalize')) {
  const raw = readFileSync(assetPath, 'utf8');
  const manifest = JSON.parse(readFileSync(manifestPath));
  manifest.native.rawExportSha256 ??= sha(Buffer.from(raw));
  const xml = normalize(raw);
  writeFileSync(assetPath, xml);
  manifest.native.exportSha256 = sha(Buffer.from(xml));
  manifest.native.meshParts = 23;
  manifest.native.modelAssetId = 92876851534007;
  const specs = new Map(sourceContract().map(p => [p.name, p]));
  manifest.native.parts = meshProperties(xml).map(p => ({ ...specs.get(property(p, 'Name')), meshId: meshId(p) }));
  manifest.native.assetIds = manifest.native.parts.map(p => p.meshId);
  manifest.native.materials = 9;
  manifest.native.materialConversion = 'Studio 0.747 omitted all factors/doubleSided. Restore glTF linear baseColorFactor as sRGB bytes and doubleSided=true. Gold=Metal, emissive Fire/Crystal/Magic=Neon, others=SmoothPlastic. Native roughness and emission are approximations, not exact glTF PBR reproduction; no maps/textures/lights added.';
  manifest.native.identitySource = 'Studio command bar: AG01_IDENTITY 10776120489 125724638469407 Group 925845207 on 2026-11-12';
  manifest.native.importSettings = { studioVersion: '0.747.0.7471481', creator: 'addout studio', uploadToRoblox: true,
    importOnlyAsModel: true, importAsPackage: false, addToWorkspace: true, setPivotToSceneOrigin: true,
    scaleUnit: 'Stud', scaleFactor: 1, mergeMeshes: false, anchored: true, invertNegativeFaces: false,
    importerDimensions: [6.24, 5.65, 6.24], importerPolygons: 4194 };
  manifest.native.budget = { perPlotMeshParts: 23, eightPlotMeshParts: 184, perPlotTriangles: 4194,
    eightPlotTriangles: 33552, textureCount: 0, newLights: 0, newEmitters: 0, attachmentsPerPlot: 2,
    textureChurn: false, motion: false, quality: 'same static geometry on Full/Reduced/Minimal and Reduce Motion' };
  manifest.status = 'NATIVE_IMPORTED_INTEGRATION_IN_PROGRESS';
  manifest.notes = ['Actual group import and native export completed 2026-11-12; runtime and fresh-build checks pending.'];
  writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + '\n');
  const rows = manifest.native.parts.map(p => `\t["${p.name}"] = "${p.meshId}",`).join('\n');
  writeFileSync('src/shared/SpellbookAssets.luau', `--!strict\n-- Generated from the inspected native export; scripts/spellbook-asset.mjs --normalize.\nlocal Assets: {[string]: string} = {\n${rows}\n}\nreturn Assets\n`);
  console.log('Spellbook: repaired 23 real MeshParts; preserved geometry, pivots and asset references.');
}
