// AG-69 source preflight only. No network, upload, permission change or Studio install.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync, mkdirSync, writeFileSync, readdirSync } from 'node:fs';
import { dirname, resolve, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { inflateSync } from 'node:zlib';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const read = path => readFileSync(resolve(root, path));
const normal = bytes => bytes.toString('utf8').replaceAll('\r\n', '\n');
const packs = {
  'stability-sky': ['bk', 'dn', 'ft', 'lf', 'rt', 'up'],
  atmosphere: ['sun', 'moon', 'mist', 'rainbow'],
  polish: ['meadow', 'star'],
};
export function crc32(bytes) {
  let crc = 0xffffffff;
  for (const byte of bytes) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
  }
  return (crc ^ 0xffffffff) >>> 0;
}

// The original generators emit non-interlaced RGBA8 PNGs with unfiltered rows.
// Validate the complete file, not just the IHDR; reject damaged/trailing data.
export function inspectOriginalPng(bytes) {
  assert(bytes.subarray(0, 8).equals(Buffer.from('89504e470d0a1a0a', 'hex')), 'PNG signature');
  let offset = 8, width, height, ended = false;
  const idat = [];
  while (offset < bytes.length) {
    assert(!ended && offset + 12 <= bytes.length, 'PNG trailing/truncated data');
    const size = bytes.readUInt32BE(offset);
    assert(size <= bytes.length - offset - 12, 'PNG chunk length');
    const type = bytes.toString('ascii', offset + 4, offset + 8);
    const data = bytes.subarray(offset + 8, offset + 8 + size);
    assert.equal(crc32(bytes.subarray(offset + 4, offset + 8 + size)), bytes.readUInt32BE(offset + 8 + size), 'PNG CRC');
    if (offset === 8) {
      assert.equal(type, 'IHDR'); assert.equal(size, 13);
      width = data.readUInt32BE(0); height = data.readUInt32BE(4);
      assert(width > 0 && width <= 256 && height > 0 && height <= 256, 'PNG source dimensions');
      assert.deepEqual([...data.subarray(8)], [8, 6, 0, 0, 0], 'RGBA8 non-interlaced PNG');
    } else if (type === 'IDAT') idat.push(data);
    else { assert.equal(type, 'IEND'); assert.equal(size, 0); ended = true; }
    offset += size + 12;
  }
  assert(ended && idat.length > 0, 'PNG missing image/end');
  const stride = width * 4 + 1;
  const pixels = inflateSync(Buffer.concat(idat), { maxOutputLength: stride * height });
  assert.equal(pixels.length, stride * height, 'PNG decompressed length');
  for (let y = 0; y < height; y++) assert.equal(pixels[y * stride], 0, 'Original PNG row filter');
  return { width, height, decodedBytes: width * height * 4 };
}

export function validateSources(manifest, readSource = read) {
  assert.equal(manifest.schemaVersion, 1);
  assert.equal(manifest.task, 'AG-69'); assert.equal(manifest.issue, 40);
  assert.equal(manifest.baseSha, '418d85f519232ea10e373a4b1944132ee389acd2');
  assert.deepEqual(manifest.target, {
    creatorType: 'Group', creatorName: 'addout studio', creatorId: 925845207,
    universeId: 10776120489, placeId: 125724638469407,
  }, 'Only the proposed owner and Experience are in scope');
  const expected = Object.entries(packs).flatMap(([pack, names]) => names.map(name => `assets/environment/${pack}/${name}.png`));
  assert.deepEqual(manifest.assets.map(a => a.source).sort(), expected.sort(), 'Exact 12 source paths; no omissions/duplicates/extras');
  let totalBytes = 0, decodedBytes = 0;
  for (const [pack, names] of Object.entries(packs)) {
    const dir = `assets/environment/${pack}`;
    const receipt = JSON.parse(readSource(`${dir}/receipt.json`));
    assert.equal(receipt.license, 'CC0-1.0');
    const license = readSource(`${dir}/LICENSE.txt`);
    assert.equal(digest(license), receipt.files['LICENSE.txt'], `Original license: ${pack}`);
    assert(license.toString().includes('https://creativecommons.org/publicdomain/zero/1.0/'));
    for (const key of ['generator', ...(receipt.art_generator ? ['art_generator'] : [])]) {
      assert.equal(digest(normal(readSource(receipt[key]))), receipt[`${key}_sha256`], `Original generator: ${pack}/${key}`);
    }
    for (const name of names) {
      const asset = manifest.assets.find(a => a.source === `${dir}/${name}.png`);
      const bytes = readSource(asset.source);
      assert.equal(asset.key, pack === 'stability-sky' ? `sky_${name}` : name);
      assert.equal(asset.uploadName, `AG69_${pack === 'stability-sky' ? `Sky_${name.toUpperCase()}` : name[0].toUpperCase() + name.slice(1)}`);
      assert.equal(asset.legacyUri, receipt.local_prefix + `${name}.png`);
      assert.equal(asset.receipt, `${dir}/receipt.json`); assert.equal(asset.license, `${dir}/LICENSE.txt`);
      assert.equal(digest(bytes), receipt.files[`${name}.png`], `Receipt hash: ${asset.source}`);
      assert.equal(asset.sha256, digest(bytes), `Manifest hash: ${asset.source}`);
      assert.equal(asset.bytes, bytes.length);
      const png = inspectOriginalPng(bytes);
      assert.equal(asset.width, png.width); assert.equal(asset.height, png.height);
      totalBytes += bytes.length; decodedBytes += png.decodedBytes;
    }
  }
  return { textures: manifest.assets.length, totalBytes, decodedBytes };
}

export function assertPendingDelivery(manifest) {
  // This first patch does not pretend that metadata booleans prove live access.
  // Replace this guard only alongside approved upload receipts + runtime wiring.
  assert.equal(manifest.status, 'BLOCKED_UPLOAD_APPROVAL');
  assert.equal(manifest.delivery.ownerApproval, null);
  assert.equal(manifest.delivery.uploadStatus, 'NOT_STARTED');
  assert.equal(manifest.delivery.runtimeIntegration, 'NOT_STARTED');
  assert.equal(manifest.delivery.ordinaryPlay, 'NOT_RUN');
  assert.equal(manifest.delivery.experienceAccess, 'NOT_VERIFIED');
  for (const asset of manifest.assets) {
    assert.equal(asset.robloxImageId, null); assert.equal(asset.robloxDecalId, null);
    for (const key of ['creatorVerified', 'restrictedVerified', 'experienceAccessVerified']) assert.equal(asset[key], false);
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  assert(args.every(a => ['--stage', '--require-delivery'].includes(a)), 'Unknown preflight argument');
  const manifest = JSON.parse(read('assets/environment/ag69-delivery.json'));
  const report = validateSources(manifest);
  assertPendingDelivery(manifest);
  if (args.includes('--require-delivery')) {
    console.error('AG69 BLOCKED: owner approval, 12 Restricted Image IDs, verified Experience access, runtime wiring and clean ordinary F5 are still required. Source preflight cannot certify delivery.');
    process.exitCode = 2;
  } else {
    if (args.includes('--stage')) {
      const dir = resolve(root, 'build/AG69-upload');
      mkdirSync(dir, { recursive: true });
      const allowed = manifest.assets.map(a => `${a.uploadName}.png`);
      assert(readdirSync(dir).every(name => allowed.includes(name)), 'Unexpected staging file: inspect manually; nothing deleted');
      for (const asset of manifest.assets) {
        assert.equal(basename(asset.uploadName), asset.uploadName);
        writeFileSync(resolve(dir, `${asset.uploadName}.png`), read(asset.source), { flag: 'w' });
        assert.equal(digest(readFileSync(resolve(dir, `${asset.uploadName}.png`))), asset.sha256);
      }
      console.log('Prepared exact-byte copies in build/AG69-upload. NOT uploaded; no assets admitted or installed.');
    }
    console.log(`AG69 SOURCE PREFLIGHT PASS: ${JSON.stringify(report)}; DELIVERY BLOCKED pending approval and native verification.`);
  }
}
