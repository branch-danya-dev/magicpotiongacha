import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { test } from 'node:test';
import { validateSources, inspectOriginalPng, validateDelivery } from '../scripts/check-ag69.mjs';

const manifest = JSON.parse(readFileSync('assets/environment/ag69-delivery.json'));
const copy = () => structuredClone(manifest);
test('all 12 original assets and recorded delivery proofs validate', () => {
  assert.deepEqual(validateSources(manifest), { textures: 12, totalBytes: 83181, decodedBytes: 1982464 });
  validateDelivery(manifest);
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
  for (const modify of [m => { m.assets[0].robloxImageId = 123; }, m => { m.assets[0].experienceAccessVerified = false; }, m => { m.delivery.ownerApproval = 'assumed'; }]) {
    const m = copy(); modify(m); assert.throws(() => validateDelivery(m));
  }
});
test('delivery gate validates recorded native evidence', () => {
  const result = spawnSync(process.execPath, ['scripts/check-ag69.mjs', '--require-delivery'], { encoding: 'utf8' });
  assert.equal(result.status, 0); assert.match(result.stdout, /AG69 RECORDED DELIVERY PASS/);
});

test('upload receipt rejects duplicate IDs and unapproved grant targets', () => {
  const receiptPath = manifest.delivery.uploadReceipt;
  const original = JSON.parse(readFileSync(receiptPath));
  for (const modify of [r => { r.images[1] = r.images[0]; }, r => { r.images[0].grantedUniverseIds.push(1); }]) {
    const receipt = structuredClone(original); modify(receipt);
    assert.throws(() => validateDelivery(manifest, path => path === receiptPath
      ? Buffer.from(JSON.stringify(receipt)) : readFileSync(path)));
  }
});

test('changed native acknowledgement is rejected rather than treated as live proof', () => {
  assert.throws(() => validateDelivery(manifest, path => path.includes('/grant-saved-')
    ? Buffer.from('synthetic Changes Saved') : readFileSync(path)), /Native evidence hash/);
});

test('saved grants cannot replace pixel identity or mark ordinary Play verified', () => {
  const changed = copy(); changed.delivery.ordinaryPlay = 'PASS';
  assert.throws(() => validateDelivery(changed));
  const receiptPath = manifest.delivery.uploadReceipt;
  const receipt = JSON.parse(readFileSync(receiptPath)); receipt.images[0].sourceKey = 'sky_bk';
  assert.throws(() => validateDelivery(manifest, path => path === receiptPath
    ? Buffer.from(JSON.stringify(receipt)) : readFileSync(path)), /Image ID must match its proven source/);
});

test('missing or altered runtime evidence cannot be replaced by saved grants', () => {
  for (const missing of ['private-f5-access.log', 'ordinary-f5.log']) {
    assert.throws(() => validateDelivery(manifest, path => path.endsWith(missing)
      ? Buffer.from('Changes Saved') : readFileSync(path)), /Native runtime evidence hash/);
  }
});
