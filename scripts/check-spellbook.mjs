import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
import { sha, assetPath, manifestPath, meshProperties, property, meshId, sourceContract, normalize } from './spellbook-asset.mjs';
const read = path => readFileSync(path, 'utf8');
const manifest = JSON.parse(read(manifestPath));
const xml = read(assetPath);
assert.equal(sha(readFileSync(assetPath)), manifest.native.exportSha256);
assert.equal(normalize(xml), xml, 'Material repair must be deterministic/idempotent');
const specs = sourceContract();
assert.equal(specs.reduce((sum, p) => sum + p.triangles, 0), 4194);
assert.equal(new Set(specs.map(p => p.sourceMaterial)).size, 9);
const meshes = meshProperties(xml);
assert.equal(meshes.length, 23);
assert.equal(new Set(meshes.map(meshId)).size, 23);
assert.equal([...xml.matchAll(/<Item class="([^"]+)"/g)].filter(m => !['Model', 'MeshPart'].includes(m[1])).length, 0);
assert(!/rbxasset:\/\/|https?:\/\/(?!www\.(?:roblox|w3)\.)/.test(xml), 'No local cache/external dependencies');
assert(xml.includes('<string name="Name">SpellbookLectern</string>'));
const allowlist = read('src/shared/SpellbookAssets.luau');
for (const p of meshes) {
  assert(allowlist.includes(`["${property(p, 'Name')}"] = "${meshId(p)}"`));
  assert.equal(property(p, 'Transparency'), '0');
  assert.equal(property(p, 'Reflectance'), '0');
  const spec = manifest.native.parts.find(x => x.name === property(p, 'Name'));
  assert.equal(spec.meshId, meshId(p));
}
const project = JSON.parse(read('default.project.json'));
assert.equal(project.tree.ServerStorage.SpellbookLectern.$path, assetPath);
// Guard the interaction contract in the engine adapter as well as portable policy.
const server = read('src/server/SpellbookLectern.luau');
assert(!/anchor\.(?:Size|CFrame|Position|Transparency|Material|CanQuery|CanCollide)\s*=/.test(server));
assert(!/function world\.update|FireServer|Instance\.new\("(?:Script|RemoteEvent|ParticleEmitter|PointLight)"\)/.test(server));
const client = read('src/client/SpellbookVisual.client.luau');
assert(!/FireServer|InvokeServer|RenderStepped|Heartbeat|Instance\.new/.test(client));
assert.equal((client.match(/ContentProvider:PreloadAsync\(/g) || []).length, 1);
assert.equal(manifest.native.budget.eightPlotMeshParts, 184);
if (process.argv.includes('--built')) {
  const built = read('build/PotionTycoon.rbxlx');
  for (const id of manifest.native.assetIds) assert(built.includes(id), `Build missing ${id}`);
  assert(built.includes('SpellbookVisual') && built.includes('SpellbookLectern'));
}
console.log('AG01 asset PASS: actual 23-mesh export, 9 source materials, 4194 triangles, pinned IDs/hash, inert geometry and unchanged anchor contract. Native permission/Play checks are separate.');
