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
  assert.equal(sha(read(path)), hash, `Art source integrity: ${path}`);
}
const captures = JSON.parse(read('docs/evidence/m7/captures.json'));
for (const [path, hash] of Object.entries(captures.sources)) {
  assert.equal(sha(read(path)), hash, `Studio capture source changed: ${path}`);
}
for (const [name, hash] of Object.entries(captures.images)) {
  assert.equal(createHash('sha256').update(readFileSync(resolve(root, 'docs/evidence/m7', name))).digest('hex'), hash, `Capture integrity: ${name}`);
}
const builder = read('src/server/EnvironmentArt.luau');
assert.match(builder, /p\.Anchored,p\.CanCollide,p\.CanTouch,p\.CanQuery=true,false,false,false/);
assert(!/rbxassetid:\/\/|HttpService|loadstring|RemoteEvent/.test(builder), 'Unreviewed external art dependency');
console.log(`M7 integrity PASS: ${Object.keys(baseline.unchanged).length} unchanged M6 files, gameplay World, release flags, art source hashes and isolated harness`);
