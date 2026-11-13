import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { test } from 'node:test';
import { validateSources, inspectOriginalPng, assertPendingDelivery } from '../scripts/check-ag69.mjs';

const manifest = JSON.parse(readFileSync('assets/environment/ag69-delivery.json'));
const copy = () => structuredClone(manifest);
test('all 12 original assets validate without claiming delivery', () => {
  assert.deepEqual(validateSources(manifest), { textures: 12, totalBytes: 83181, decodedBytes: 1982464 });
  assertPendingDelivery(manifest);
});
test('changed image bytes fail the original receipt', () => {
  assert.throws(() => validateSources(manifest, path => {
    const bytes = readFileSync(path);
    if (path === manifest.assets[0].source) bytes[50] ^= 1;
    return bytes;
  }), /Receipt hash/);
});
test('PNG decoder rejects bad CRC and trailing payload', () => {
  const bytes = readFileSync(manifest.assets[0].source);
  const broken = Buffer.from(bytes); broken[50] ^= 1;
  assert.throws(() => inspectOriginalPng(broken), /PNG CRC/);
  assert.throws(() => inspectOriginalPng(Buffer.concat([bytes, Buffer.from('payload')])), /PNG trailing/);
});
test('missing, duplicate and unexpected source files are rejected', () => {
  for (const modify of [m => m.assets.pop(), m => m.assets.push(m.assets[0]), m => { m.assets[0].source = '../other.png'; }]) {
    const m = copy(); modify(m); assert.throws(() => validateSources(m), /Exact 12 source paths/);
  }
});
test('manifest cannot substitute a hash or change image dimensions', () => {
  const hash = copy(); hash.assets[0].sha256 = '0'.repeat(64);
  assert.throws(() => validateSources(hash), /Manifest hash/);
  const size = copy(); size.assets[0].width *= 2;
  assert.throws(() => validateSources(size));
});
test('changed license or generator invalidates provenance', () => {
  for (const suffix of ['/LICENSE.txt', '/create-stability-sky.py']) {
    assert.throws(() => validateSources(manifest, path => path.endsWith(suffix) ? Buffer.from('replacement') : readFileSync(path)), /Original (license|generator)/);
  }
});
test('wrong group or Place ID substituted for Universe ID is rejected', () => {
  for (const modify of [m => { m.target.creatorId = 1; }, m => { m.target.universeId = m.target.placeId; }]) {
    const m = copy(); modify(m); assert.throws(() => validateSources(m), /Only the proposed owner/);
  }
});
test('unverified IDs/access cannot silently be labelled approved', () => {
  for (const modify of [m => { m.assets[0].robloxImageId = 123; }, m => { m.assets[0].experienceAccessVerified = true; }, m => { m.delivery.ownerApproval = 'assumed'; }]) {
    const m = copy(); modify(m); assert.throws(() => assertPendingDelivery(m));
  }
});
test('delivery gate exits nonzero while preflight is green', () => {
  const result = spawnSync(process.execPath, ['scripts/check-ag69.mjs', '--require-delivery'], { encoding: 'utf8' });
  assert.equal(result.status, 2); assert.match(result.stderr, /AG69 BLOCKED/);
});
