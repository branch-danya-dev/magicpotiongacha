// Offline artifact audit; reads real FBX skin/animation data, not just receipts.
import assert from 'node:assert/strict';
import { readFile, readdir } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { inflateSync } from 'node:zlib';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const folder = 'assets/familiars/green_slime';
const manifest = JSON.parse(await readFile(resolve(root, folder, 'manifest.json'), 'utf8'));
const sha = b => createHash('sha256').update(b).digest('hex');
assert.equal(manifest.status, 'PHASE_A_CANDIDATE_STUDIO_PLAY_BLOCKED');
assert.equal(manifest.version, 2);
assert.deepEqual(manifest.idlePair.weights, { Idle_Calm: 0.5, Idle_Active: 0.5 });
assert.equal(manifest.idlePair.fadeSeconds, 0.3);
assert.equal(manifest.idlePair.liveSelectorImplemented, false);
assert.equal(manifest.source.ownerAttestation.plan, 'paid');
assert.deepEqual(manifest.roblox.assetIds, []);
for (const item of manifest.files) {
  assert(!item.path.includes('..') && !item.path.includes('\\') && !item.path.startsWith('/'));
  assert(item.path.startsWith(folder + '/') || item.path.startsWith('docs/evidence/ag73/'));
  const bytes = await readFile(resolve(root, item.path));
  assert.equal(bytes.length, item.bytes, item.path + ' size');
  assert.equal(sha(bytes), item.sha256, item.path + ' hash');
}
const listed = new Set(manifest.files.map(x => x.path));
assert.equal(listed.size, manifest.files.length, 'no duplicate manifest paths');
async function checkCoverage(dir) {
  for (const entry of await readdir(resolve(root, dir), { withFileTypes: true })) {
    if (entry.name.endsWith('.blend1') || entry.name.endsWith('.fbm') || entry.name === '__pycache__') continue;
    const path = dir + '/' + entry.name;
    if (entry.isDirectory()) await checkCoverage(path);
    else if (entry.name !== 'manifest.json') assert(listed.has(path), 'unreceipted file: ' + path);
  }
}
await checkCoverage(folder);
await checkCoverage('docs/evidence/ag73');

// Blender's pinned exporter emits FBX 7400 (32-bit node offsets). Intentionally
// fail closed on another FBX version instead of guessing its layout.
function fbx(bytes) {
  assert.equal(bytes.subarray(0, 21).toString(), 'Kaydara FBX Binary  \0');
  assert.equal(bytes.readUInt32LE(23), 7400);
  let at = 27;
  function property() {
    const type = String.fromCharCode(bytes[at++]);
    const scalar = { Y: ['readInt16LE', 2], C: ['readUInt8', 1], I: ['readInt32LE', 4],
      F: ['readFloatLE', 4], D: ['readDoubleLE', 8], L: ['readBigInt64LE', 8] }[type];
    if (scalar) { const v = bytes[scalar[0]](at); at += scalar[1]; return v; }
    if (type === 'S' || type === 'R') {
      const size = bytes.readUInt32LE(at); at += 4;
      const data = bytes.subarray(at, at + size); at += size;
      return type === 'S' ? data.toString('utf8') : data;
    }
    const spec = { f: ['readFloatLE', 4], d: ['readDoubleLE', 8], i: ['readInt32LE', 4],
      l: ['readBigInt64LE', 8], b: ['readUInt8', 1] }[type];
    assert(spec, 'unsupported FBX property ' + type);
    const count = bytes.readUInt32LE(at), encoding = bytes.readUInt32LE(at + 4), size = bytes.readUInt32LE(at + 8);
    at += 12;
    assert(encoding === 0 || encoding === 1);
    const packed = bytes.subarray(at, at + size); at += size;
    const data = encoding ? inflateSync(packed) : packed;
    assert.equal(data.length, count * spec[1]);
    return Array.from({ length: count }, (_, i) => data[spec[0]](i * spec[1]));
  }
  function node() {
    const end = bytes.readUInt32LE(at), count = bytes.readUInt32LE(at + 4);
    const propBytes = bytes.readUInt32LE(at + 8), nameLength = bytes[at + 12]; at += 13;
    if (end === 0) return null;
    assert(end <= bytes.length && end > at);
    const name = bytes.toString('utf8', at, at + nameLength); at += nameLength;
    const propStart = at, props = Array.from({ length: count }, property);
    assert.equal(at - propStart, propBytes);
    const children = [];
    while (at < end) { const child = node(); if (!child) break; children.push(child); }
    assert.equal(at, end);
    return { name, props, children };
  }
  const nodes = [];
  while (at < bytes.length) { const n = node(); if (!n) break; nodes.push(n); }
  return nodes;
}
const child = (n, name) => n.children.find(c => c.name === name);
const values = (n, name) => child(n, name)?.props[0];
const bones = ['Body', 'Contact', 'EdgeBL', 'EdgeBR', 'EdgeFL', 'EdgeFR', 'Head', 'Root'];
const texture = await readFile(resolve(root, folder, 'source/GreenSlime.original.png'));
const source = await readFile(resolve(root, folder, 'source/GreenSlime.original.fbx'));
assert.equal(sha(source), manifest.source.fbxSha256);
assert.equal(sha(texture), manifest.source.actualPngSha256);
assert(source.includes(texture), 'owner PNG is the embedded FBX texture');
const specs = [
  ['rig_v1/GreenSlime_Rig.fbx', 0, 0], ['rig_v1/GreenSlime_Idle.fbx', 3.2, 97],
  ['rig_v2/Idle_Calm.fbx', 3.6, 109], ['rig_v2/Idle_Active.fbx', 3.0, 91],
];
let restIdentity;
const pairCurves = [];
for (const [file, duration, frames] of specs) {
  const animated = duration > 0;
  const bytes = await readFile(resolve(root, folder, file));
  const nodes = fbx(bytes), objects = nodes.find(n => n.name === 'Objects').children;
  const connectionNodes = nodes.find(n => n.name === 'Connections').children;
  const links = connectionNodes.map(c => c.props);
  const models = objects.filter(n => n.name === 'Model');
  const boneModels = models.filter(n => n.props[2] === 'LimbNode');
  const names = new Map(boneModels.map(n => [n.props[0], n.props[1].split('\0')[0]]));
  assert.deepEqual([...names.values()].sort(), bones, file + ' bones');
  for (const [id, name] of names) {
    const parent = links.find(p => p[0] === 'OO' && p[1] === id && names.has(p[2]));
    if (name === 'Root') assert(!parent, 'Root has no bone parent');
    else assert.equal(names.get(parent?.[2]), name === 'Head' ? 'Body' : 'Root', name + ' parent');
  }
  assert(models.every(n => ['Null', 'Mesh', 'LimbNode'].includes(n.props[2])), 'no camera/light');
  const geometry = objects.filter(n => n.name === 'Geometry');
  assert.equal(geometry.length, 1);
  assert.equal(values(geometry[0], 'Vertices').length, 1321 * 3);
  const indices = values(geometry[0], 'PolygonVertexIndex');
  assert.equal(indices.length, 2603 * 3);
  assert.equal(indices.filter(x => x < 0).length, 2603);
  assert(indices.every(x => (x < 0 ? -x - 1 : x) < 1321));
  assert.equal(geometry[0].children.filter(n => n.name === 'LayerElementUV').length, 1);
  assert.equal(objects.filter(n => n.name === 'Material').length, 1);
  const deformers = objects.filter(n => n.name === 'Deformer');
  assert.equal(deformers.filter(n => n.props[2] === 'Skin').length, 1);
  const influence = Array.from({ length: 1321 }, () => []);
  const skin = [];
  for (const c of deformers.filter(n => n.props[2] === 'Cluster')) {
    const linked = links.find(p => p[0] === 'OO' && p[2] === c.props[0] && names.has(p[1]));
    assert(linked, 'skin cluster is bound to a bone');
    const bone = names.get(linked[1]), ix = values(c, 'Indexes') ?? [], weights = values(c, 'Weights') ?? [];
    skin.push({ bone, ix, weights, transform: values(c, 'Transform'), link: values(c, 'TransformLink') });
    assert.equal(ix.length, weights.length);
    ix.forEach((v, i) => { assert(v >= 0 && v < 1321); if (weights[i] > 1e-7) {
      assert(bone !== 'Root' && weights[i] <= 1 && Number.isFinite(weights[i]));
      influence[v].push(weights[i]);
    } });
  }
  assert(influence.every(w => w.length >= 1 && w.length <= 4 && Math.abs(w.reduce((a, b) => a + b, 0) - 1) < 1e-5));
  const identity = { vertices: values(geometry[0], 'Vertices'), indices,
    uv: geometry[0].children.filter(n => n.name === 'LayerElementUV'), skin: skin.sort((a, b) => a.bone.localeCompare(b.bone)) };
  if (!restIdentity) restIdentity = identity;
  else assert.deepEqual(identity, restIdentity, file + ' uses the exact same rest surface, UV, skin and bind matrices');
  assert(bytes.includes(texture), 'export embeds exact owner texture');
  const stacks = objects.filter(n => n.name === 'AnimationStack');
  const curves = objects.filter(n => n.name === 'AnimationCurve');
  assert.equal(stacks.length, animated ? 1 : 0);
  assert.equal(curves.length > 0, animated);
  for (const curve of curves) {
    const times = values(curve, 'KeyTime'), keys = values(curve, 'KeyValueFloat');
    assert.equal(times.length, keys.length);
    assert.equal(times.length, frames, 'one baked sample per frame');
    assert.equal(Number(times.at(-1) - times[0]) / 46186158000, duration);
    assert(keys.every(Number.isFinite));
    assert(Math.abs(keys[0] - keys.at(-1)) < 1e-5, 'closed animation seam');
    const curveLink = links.find(p => p[0] === 'OP' && p[1] === curve.props[0]);
    const target = links.find(p => p[0] === 'OP' && p[1] === curveLink?.[2] && models.some(m => m.props[0] === p[2]));
    assert(target, 'animation curve has a model target');
    if (['Root', 'Contact'].includes(names.get(target[2])) || target[3] === 'Lcl Scaling') {
      assert(keys.every(v => Math.abs(v - keys[0]) < 1e-6), 'stationary Root/Contact and no animated scale');
    }
  }
  if (file.startsWith('rig_v2/')) pairCurves.push(curves.map(c => values(c, 'KeyValueFloat')));
  console.log(`AG73 ${file}: 1321 vertices, 2603 triangles, 8 bones, normalized <=4 skin weights, ${curves.length} curves PASS`);
}
assert.notDeepEqual(pairCurves[0], pairCurves[1], 'two distinct Idle clips');
const v2 = JSON.parse(await readFile(resolve(root, folder, 'rig_v2/validation.json'), 'utf8'));
assert.equal(v2.unchangedFromV1, true);
for (const clip of v2.clips) {
  assert(clip.loopMaxVertexDelta < 1e-6 && clip.minimumGroundClearance >= 0);
  assert(clip.maximumEdgeStrain < 0.35 && clip.maximumHalfFrameStep < 0.005);
}
const transition = JSON.parse(await readFile(resolve(root, folder, 'rig_v2/continuity.json'), 'utf8'));
assert.equal(transition.evaluatedBakedAction, true);
assert.equal(transition.durationSeconds, 10.2);
assert.equal(transition.fadeSeconds, 0.3);
assert.deepEqual(transition.boundaries.map(b => b.seconds), [3.6, 3.9, 6.6, 6.9]);
assert(transition.boundaries.every(b => b.limitVertexDelta < 1e-6));
assert(transition.minimumGroundClearance >= 0 && transition.maximumEdgeStrain < .35 && transition.maximumHalfFrameStep < .005);
console.log(`AG73 ${manifest.files.length} artifact digests PASS; Blender roundtrip recorded; Studio Play BLOCKED, owner art PENDING.`);
