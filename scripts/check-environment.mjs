import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const read = p => readFileSync(resolve(root, p), 'utf8').replaceAll('\r\n', '\n');
const sha = text => createHash('sha256').update(text).digest('hex');
const baseline = JSON.parse(read('tests/fixtures/m6-environment-contract.json'));
for (const [path, expected] of Object.entries(baseline.unchanged)) {
  assert.equal(sha(read(path)), expected, `M6 protected source changed: ${path}`);
}
// Remove only the explicit presentation seams; everything else, including every
// anchor, prompt, callback, owner check and update branch must match the M6 World.
let world = read('src/server/World.luau');
for (const line of baseline.worldPresentationLines) {
  assert.equal(world.split(line).length, 2, `Missing/duplicated World seam: ${line}`);
  world = world.replace(line, '');
}
world = world.replace('config, count, callbacks, environmentArtEnabled)', 'config, count, callbacks)');
assert.equal(sha(world), baseline.worldSha256, 'M6 gameplay World contract changed');
const settings = read('src/server/ServerSettings.luau');
for (const name of ['EnvironmentArtEnabled', 'MonetizationEnabled', 'TradingEnabled']) {
  assert.match(settings, new RegExp(`${name}\\s*=\\s*false`), `${name} must ship off`);
}
assert(!read('default.project.json').includes('qa/'), 'Visual harness leaked into release');
const manifest = JSON.parse(read('assets/environment/manifest.json'));
assert.equal(manifest.quaternius.status, 'BLOCKED');
for (const asset of manifest.quaternius.selected) {
  assert.equal(asset.sha256, null); assert.equal(asset.robloxAssetId, null);
}
for (const [path, hash] of Object.entries(manifest.nativeFallback.sources)) {
  assert.equal(sha(read(`${manifest.nativeFallback.sourceSnapshotRoot}/${path}`)), hash, `Rejected art snapshot integrity: ${path}`);
}
const captures = JSON.parse(read('docs/evidence/m7/captures.json'));
for (const [path, hash] of Object.entries(captures.sources)) {
  assert.equal(sha(read(`${captures.sourceSnapshotRoot}/${path}`)), hash, `Historical Studio capture source changed: ${path}`);
}
for (const [name, hash] of Object.entries(captures.images)) {
  assert.equal(createHash('sha256').update(readFileSync(resolve(root, 'docs/evidence/m7', name))).digest('hex'), hash, `Capture integrity: ${name}`);
}
const builder = read('src/server/EnvironmentArt.luau');
const receipt = JSON.parse(read('assets/environment/megakit/receipt.json'));
assert.equal(receipt.models.length, 14);
assert(receipt.texture_rgba8_mips_bytes <= 32*1024*1024);
for (const [path, hash] of Object.entries(receipt.files)) {
  assert.equal(createHash('sha256').update(readFileSync(resolve(root, 'assets/environment/megakit', path))).digest('hex'), hash, `Imported asset changed: ${path}`);
}
const template=read('assets/environment/megakit/M7NatureTemplates.rbxmx');
for (const match of template.matchAll(/<Item class="([^"]+)"/g)) assert(['Folder','Model','MeshPart','SurfaceAppearance'].includes(match[1]), 'Executable/unreviewed imported content');
assert.equal((template.match(/class="MeshPart"/g)||[]).length,21);
for (const model of receipt.models) {
  const gltf=JSON.parse(read(`assets/environment/megakit/prepared/${model.name}.gltf`));
  const triangles=gltf.meshes.flatMap(m=>m.primitives).reduce((n,p)=>n+gltf.accessors[p.indices].count/3,0);
  assert.equal(triangles,model.triangles);
  assert(triangles<=((model.name.includes('Tree')||model.name.startsWith('Pine'))?2000:500));
}
assert.match(builder, /p\.Anchored,p\.CanCollide,p\.CanTouch,p\.CanQuery=true,false,false,false/);
assert(!/rbxassetid:\/\/|HttpService|loadstring|RemoteEvent/.test(builder), 'Unreviewed external art dependency');
const current = JSON.parse(read('docs/evidence/m7-revision/captures.json'));
assert.equal(current.status, 'OWNER_REVIEW_PENDING');
assert.equal(current.graphicsQuality, 10);
for (const [path, hash] of Object.entries(current.sources)) {
  assert.equal(sha(read(path)), hash, `Current Studio evidence source changed: ${path}; recapture the affected views`);
}
for (const name of ['day-overview','sunset-overview','night-overview','rain-overview','dawn-overview','day-spawn','day-bazaar','day-foliage','gameplay-ui','graphics-settings']) {
  assert.equal(createHash('sha256').update(readFileSync(resolve(root, 'docs/evidence/m7-revision', name+'.jpg'))).digest('hex'), current.images[name+'.jpg'], `Current capture integrity: ${name}`);
}
console.log(`M7 integrity PASS: ${Object.keys(baseline.unchanged).length} unchanged M6 files, gameplay World, release flags, art source hashes and isolated harness`);
