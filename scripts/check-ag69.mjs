// AG-69 source, identity and recorded native delivery verification. No network.
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync, mkdirSync, writeFileSync, readdirSync } from 'node:fs';
import { dirname, resolve, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { inflateSync } from 'node:zlib';
import {execFileSync} from 'node:child_process';
import {beforeAG69} from './ag69-preservation.mjs';

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
  const rgba=Buffer.concat(Array.from({length:height},(_,y)=>pixels.subarray(y*stride+1,(y+1)*stride)));
  return { width, height, decodedBytes: width * height * 4, decodedSha256:digest(rgba) };
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
      assert.equal(asset.decodedSha256,png.decodedSha256,'Decoded source hash');
      totalBytes += bytes.length; decodedBytes += png.decodedBytes;
    }
  }
  return { textures: manifest.assets.length, totalBytes, decodedBytes };
}

export function validateDelivery(manifest, readEvidence = read) {
  // Hashes bind recorded native evidence; CI never claims a new live session.
  assert.equal(manifest.status, 'STUDIO_VERIFIED_ART_OPEN');
  assert.deepEqual(manifest.delivery.ownerApproval, {
    received: '2026-11-13', source: 'owner reply in project chat',
    scope: 'exact 12 manifest PNGs; Restricted Group 925845207; permanent access only to Universe 10776120489',
  });
  assert.equal(manifest.delivery.uploadStatus, 'COMPLETED_IMAGE_IDS_VERIFIED');
  assert.equal(manifest.delivery.assetPrivacy, 'RESTRICTED_VERIFIED_12');
  assert.equal(manifest.delivery.runtimeIntegration, 'IMPLEMENTED');
  assert.equal(manifest.delivery.ordinaryPlay, 'PASS_LOCAL_FULL_GAME');
  assert.equal(manifest.delivery.experienceAccess, 'PASS_PRIVATE_EXPERIENCE_F5');
  assert.equal(manifest.delivery.uploadReceipt, 'docs/evidence/ag69/upload-access-receipt.json');
  const receipt = JSON.parse(readEvidence(manifest.delivery.uploadReceipt));
  assert.equal(receipt.schemaVersion, 1);
  assert.deepEqual(receipt.target, manifest.target);
  assert.equal(receipt.sourceIdentity, 'DECODED_RGBA_SHA256_MATCH_12');
  assert.equal(receipt.runtimeAccess, 'PASS_PRIVATE_EXPERIENCE_F5');
  const logs={};
  for(const [key,path] of Object.entries({privatePlay:'docs/evidence/ag69/private-f5-access.log',ordinaryPlay:'docs/evidence/ag69/ordinary-f5.log'})) {
    const proof=receipt.runtimeEvidence[key];
    assert.equal(proof.path,path);
    logs[key]=normal(readEvidence(path));
    assert.equal(digest(logs[key]),proof.sha256,'Native runtime evidence hash');
  }
  assert(logs.privatePlay.includes('AG69_PRIVATE_COMPLETE 10776120489 125724638469407 true true 12 0 nil'),'Private client context and all 12 completed');
  assert(logs.ordinaryPlay.includes('M7_19E_ASSETS failures=0 complete=true source=original-CC0-Roblox universe=0'),'Ordinary local build delivery completed');
  assert(logs.ordinaryPlay.includes('AG69_MATRIX_COMPLETE true'));
  assert(logs.ordinaryPlay.includes('AG69_OWNER_RESTORED true'));
  assert(/AG69_STATE after-E-and-mouse .* soul 8 2 10/.test(logs.ordinaryPlay),'Two real inputs: two feedbacks and 10 Essence');
  for(let i=1;i<=8;i++) assert(logs.ordinaryPlay.includes(`AG69_PLOT ${i} book=1 `),'Eight plot bindings');
  for(const quality of ['full','reduced','minimal']) for(const motion of [false,true]) for(const look of ['OFF','AG68']) {
    assert(logs.ordinaryPlay.includes(`AG69_STATE matrix ${quality} ${motion} true 0 false ${look} `),'Native quality/motion/look matrix');
  }
  const session=JSON.parse(readEvidence('docs/evidence/ag69/native-session.json'));
  assert.equal(session.baseSha,manifest.baseSha);
  assert.equal(session.buildSha256,'8eb14671401c78a8ca15792be3ec0769a3cce9b3e887ed685a5575ba43260e56');
  assert.deepEqual(Object.keys(session.runtimeSourceSha256).sort(),['src/client/EnvironmentView.luau','src/server/EnvironmentArt.luau','src/shared/EnvironmentAssets.luau']);
  // Historical receipt proves the uploaded Images and then-tested source only.
  // R1 changes the celestial consumer; do not relabel old preload as render proof.
  for(const [path,sha] of Object.entries(session.runtimeSourceSha256)) {
    const old=execFileSync('git',['show',`df5f3ee7f582764718390957d7234633bd6747e5:${path}`],{cwd:root});
    assert.equal(digest(normal(old)),sha,'Historical runtime must match its tested revision');
  }
  assert.equal(session.captures.length,8);
  const before=JSON.parse(readEvidence('docs/evidence/ag68/runtime.json'));
  for(const pose of ['day','sunset','night','rain']) for(const camera of ['near','wide']) {
    const name=`${pose}-reduced-${camera}-AG68`;
    const capture=session.captures.find(c=>c.pose===pose&&c.camera===camera);
    assert(capture,'All eight native comparisons');
    assert.equal(capture.path,`docs/evidence/ag69/${name}.jpg`);
    assert.equal(digest(readEvidence(capture.path)),capture.sha256,'Unmodified native capture');
    assert(logs.ordinaryPlay.includes(capture.nativeReadyRecord),'Native camera record');
    const baseline=before.records.find(r=>r.tag==='CAPTURE_READY'&&r.value.name===name).value;
    assert.deepEqual(capture.cframe,baseline.cframe,'Matched camera transform');
    assert.equal(capture.fov,baseline.fov);
  }
  assert.equal(receipt.identityEvidence.path,'docs/evidence/ag69/studio-image-identity.log');
  const identity=normal(readEvidence(receipt.identityEvidence.path));
  assert.equal(digest(identity),receipt.identityEvidence.sha256,'Native identity evidence hash');
  assert(identity.includes('AG69_IDENTIFY_COMPLETE 10776120489 125724638469407'),'Completed identity probe in approved context');
  assert.equal(receipt.images.length, 12);
  assert.equal(new Set(receipt.images.map(a => a.imageId)).size, 12, 'Unique uploaded Image IDs');
  for (const image of receipt.images) {
    assert.match(image.imageId, /^[1-9][0-9]{12,14}$/);
    assert.equal(image.assetType, 'Image');
    assert(logs.privatePlay.includes(`AG69_PRIVATE_ASSET rbxassetid://${image.imageId} Success`),'Private asset delivery');
    assert(logs.ordinaryPlay.includes(`AG69_ASSET rbxassetid://${image.imageId} Success`),'Ordinary asset delivery');
    assert.equal(image.creatorGroupId, manifest.target.creatorId);
    const source=manifest.assets.find(a=>a.key===image.sourceKey);
    assert(source && source.robloxImageId===image.imageId,'Image ID must match its proven source');
    assert.equal(source.decodedSha256,image.decodedSha256,'Decoded source identity');
    assert(identity.includes(`AG69_PIXELS ${image.imageId} ${source.width} ${source.height} ${source.decodedSha256}`),'Studio pixel hash must prove source identity');
    assert.equal(image.restricted, true);
    assert.deepEqual(image.grantedUniverseIds, [manifest.target.universeId], 'Only the approved Universe');
    for (const proof of image.evidence) {
      assert.match(proof.path, /^docs\/evidence\/ag69\/(restricted|grant-target|grant-saved)-[0-9]+\.(jpg|txt)$/);
      assert(proof.path.includes(`-${image.imageId}.`), 'Evidence belongs to this Image ID');
      const bytes = readEvidence(proof.path);
      assert.equal(digest(proof.path.endsWith('.txt') ? normal(bytes) : bytes), proof.sha256, 'Native evidence hash');
      if (proof.path.includes('/grant-saved-')) {
        assert(bytes.toString().includes(`/store/${image.imageId}/permissions`), 'Saved asset URL');
        assert(bytes.toString().includes('Changes Saved'), 'Native grant save acknowledgement');
      }
      if (proof.path.includes('/grant-target-') && proof.path.endsWith('.txt')) {
        assert(bytes.toString().includes('10776120489'), 'Native target Universe');
      }
    }
    assert.deepEqual(image.evidence.map(p => p.path.match(/\/(restricted|grant-target|grant-saved)-/)[1]).sort(),
      ['grant-saved', 'grant-target', 'restricted'], 'Three native evidence records per image');
  }
  for (const asset of manifest.assets) {
    assert.equal(asset.robloxDecalId, null);
    for (const key of ['creatorVerified', 'restrictedVerified']) assert.equal(asset[key], true);
    assert.equal(asset.experienceAccessVerified,true,'Private F5 evidence required above');
  }
}

export function validateRuntime(manifest) {
  const module=normal(read('src/shared/EnvironmentAssets.luau'));
  for(const asset of manifest.assets) assert(module.includes(`${asset.key}="${asset.robloxImageId}"`),'Runtime ID must match manifest');
  assert.equal((module.match(/="[0-9]{13,15}"/g)||[]).length,12,'No extra IDs');
  const base=manifest.baseSha;
  for(const path of ['src/client/EnvironmentView.luau','src/server/EnvironmentArt.luau']) {
    const current=normal(read(path));
    const original=execFileSync('git',['show',`${base}:${path}`],{cwd:root,encoding:'utf8',maxBuffer:8*1024*1024}).replaceAll('\r\n','\n');
    assert.equal(beforeAG69(path,current),original,'Only reviewed asset seams may differ from PR39');
    assert(!/Config\.(skyPrefix|polishPrefix)|Style\.skyPrefix/.test(current),'No local texture dependency in runtime consumers');
  }
  const view=normal(read('src/client/EnvironmentView.luau'));
  assert.equal((view.match(/PreloadAsync\(/g)||[]).length,1);
  assert(view.includes('ContentProvider:PreloadAsync(probes,'),'Use the native-verified typed Image loader');
  assert.equal((view.match(/clearProbes\(\)/g)||[]).length,3,'Probe cleanup on completion and stop');
  assert.equal((view.match(/RenderStepped:Connect/g)||[]).length,1);
  assert.equal((view.match(/:Connect\(/g)||[]).length,5);
  assert(view.includes('if active~=self then return end'),'Late preload cannot mutate a stopped owner');
  assert(view.includes('if Assets.skyReady(delivery) then for property,key in pairs(skyProperties)'));
  assert(view.includes('counts.assetComplete=delivery.complete'),'Pending must remain distinguishable from success');
  assert(view.includes('sky.SunTextureId=""; sky.MoonTextureId=""'),'No unsupported Sky celestial requests');
  assert(!/sky\.(Sun|Moon)TextureId=Assets/.test(view),'Never send Image IDs to the failing Sky celestial consumer');
  assert(view.includes('sunDisk.attachment.Position=sun*Config.celestial.distance'),'Sun tracks native lighting direction');
  assert(view.includes('sunDisk.image.IsLoaded') && view.includes('moon.image.IsLoaded'),'Report real consumer state');
  assert(!/FireServer|InvokeServer|HttpService/.test(module));
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  assert(args.every(a => ['--stage', '--require-delivery'].includes(a)), 'Unknown preflight argument');
  const manifest = JSON.parse(read('assets/environment/ag69-delivery.json'));
  const report = validateSources(manifest);
  validateDelivery(manifest);
  validateRuntime(manifest);
  if (args.includes('--require-delivery')) {
    console.log('AG69 RECORDED DELIVERY PASS: source identity, Restricted grants, private Experience F5 and ordinary full-game F5 evidence verified. Art/mobile/multiclient remain open.');
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
      console.log('Prepared exact-byte source copies in build/AG69-upload. Upload already completed; DO NOT upload again.');
    }
    console.log(`AG69 SOURCE/IDENTITY/CODE/RECORDED DELIVERY PASS: ${JSON.stringify(report)}; no new live session claimed by CI.`);
  }
}
