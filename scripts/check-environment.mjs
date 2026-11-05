import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';
import { inflateSync } from 'node:zlib';
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
const a1Snapshot=JSON.parse(read('docs/evidence/m7-revision/source-snapshot.json'));
assert.equal(current.status, 'OWNER_REVIEW_PENDING');
assert.equal(current.graphicsQuality, 10);
for (const [path, hash] of Object.entries(current.sources)) {
  assert.equal(sha(a1Snapshot[path]), hash, `Archived A.1 Studio evidence source changed: ${path}`);
}
for (const name of ['day-overview','sunset-overview','night-overview','rain-overview','dawn-overview','day-spawn','day-bazaar','day-foliage','gameplay-ui','graphics-settings']) {
  assert.equal(createHash('sha256').update(readFileSync(resolve(root, 'docs/evidence/m7-revision', name+'.jpg'))).digest('hex'), current.images[name+'.jpg'], `Current capture integrity: ${name}`);
}
const a2=JSON.parse(read('docs/evidence/m7-a2/captures.json'));
const a2Snapshot=JSON.parse(read('docs/evidence/m7-a2/source-snapshot.json'));
assert.equal(a2.status,'OWNER_REVIEW_PENDING');
assert.equal(a2.parentCommit,'f343966580e91b20db4f1516741bae1d0e8ee291');
for (const [path,hash] of Object.entries(a2.sources)) {
  assert.equal(sha(a2Snapshot[path]),hash,`Historical A.2 captured source changed: ${path}`);
}
for (const [name,entry] of Object.entries(a2.images)) {
  assert(a2.builds[entry.build],`Unknown capture build: ${name}`);
  assert.equal(createHash('sha256').update(readFileSync(resolve(root,'docs/evidence/m7-a2',name))).digest('hex'),entry.sha256,`A.2 capture integrity: ${name}`);
}
for (const pose of ['day','sunset','night','rain','dawn']) {
  assert.equal(a2.images[pose+'-overview.jpg'].graphics,'Manual 10');
  assert.equal(a2.images[pose+'-overview.jpg'].build,'final');
}
for (const setting of ['auto','low5']) for (const pose of ['day','night']) {
  assert.equal(a2.images[`before-${setting}-${pose}.jpg`].build,'baseline');
  assert.equal(a2.images[`after-${setting}-${pose}.jpg`].build,'final');
}
for (const pose of ['day','night']) assert.equal(a2.images[`gameplay-${pose}.jpg`].build,'gameplay');
const skyReceipt=JSON.parse(read('assets/environment/atmosphere/receipt.json'));
assert.equal(skyReceipt.license,'CC0-1.0');
assert.equal(skyReceipt.max_edge_rgba_error,0);
assert.equal(sha(read(skyReceipt.generator)),skyReceipt.generator_sha256);
for(const [name,hash] of Object.entries(skyReceipt.files)) {
  assert.equal(createHash('sha256').update(readFileSync(resolve(root,'assets/environment/atmosphere',name))).digest('hex'),hash,`Atmosphere art integrity: ${name}`);
}
assert(receipt.texture_rgba8_mips_bytes+skyReceipt.rgba8_mips_bytes<=32*1024*1024,'Combined texture budget');
const polish=JSON.parse(read('assets/environment/polish/receipt.json'));
assert.equal(polish.license,'CC0-1.0'); assert.equal(polish.roblox_asset_ids,null);
assert.equal(sha(read(polish.generator)),polish.generator_sha256);
assert.deepEqual(Object.keys(polish.files).sort(),['LICENSE.txt','meadow.png','star.png']);
assert(receipt.texture_rgba8_mips_bytes+skyReceipt.rgba8_mips_bytes+polish.rgba8_mips_bytes<=32*1024*1024,'Combined A.2c texture budget');
for(const [name,hash] of Object.entries(polish.files)) assert.equal(sha(readFileSync(resolve(root,'assets/environment/polish',name))),hash);
// Decode delivered pixels: tile edges and sprite borders must stay seamless.
for(const [name,n] of [['meadow.png',128],['star.png',64]]) {
  const png=readFileSync(resolve(root,'assets/environment/polish',name));
  assert.equal(png.readUInt32BE(16),n); assert.equal(png.readUInt32BE(20),n);
  assert.equal(png[24],8); assert.equal(png[25],6); assert.equal(png[28],0);
  const chunks=[]; for(let p=8;p<png.length;) { const len=png.readUInt32BE(p); if(png.toString('ascii',p+4,p+8)==='IDAT') chunks.push(png.subarray(p+8,p+8+len)); p+=12+len; }
  const raw=inflateSync(Buffer.concat(chunks)),stride=n*4+1;
  assert.equal(raw.length,n*stride);
  const pixel=(x,y)=>raw.subarray(y*stride+1+x*4,y*stride+5+x*4);
  for(let y=0;y<n;y++) assert.equal(raw[y*stride],0);
  for(let i=0;i<n;i++) {
    if(name==='meadow.png') { assert.deepEqual(pixel(0,i),pixel(n-1,i)); assert.deepEqual(pixel(i,0),pixel(i,n-1)); }
    else for(const p of [pixel(0,i),pixel(n-1,i),pixel(i,0),pixel(i,n-1)]) assert.equal(p[3],0);
  }
  if(name==='meadow.png') for(let y=0;y<n;y++) for(let x=0;x<n;x++) {
    const p=pixel(x,y); assert.equal(p[3],255); assert(p[0]>=200 && p[0]<=232);
    if(x) assert(Math.abs(p[0]-pixel(x-1,y)[0])<=2,'High-frequency meadow edge');
  }
}
console.log('A.2c art PASS: original closed asset roster, opaque seamless low-frequency meadow, transparent star borders, combined memory budget');
// Independently decode the delivered PNG bytes, not the generator's receipt.
// Every shared ray on the six cube boundaries must have identical RGBA texels.
const edgePixels=new Map(); let shared=0;
for(const face of ['ft','bk','lf','rt','up','dn']) {
  const png=readFileSync(resolve(root,'assets/environment/atmosphere',face+'.png'));
  assert.equal(png.subarray(0,8).toString('hex'),'89504e470d0a1a0a');
  assert.equal(png.readUInt32BE(16),256); assert.equal(png.readUInt32BE(20),256);
  assert.equal(png[24],8); assert.equal(png[25],6); assert.equal(png[28],0);
  const chunks=[];
  for(let p=8;p<png.length;) { const n=png.readUInt32BE(p); if(png.toString('ascii',p+4,p+8)==='IDAT') chunks.push(png.subarray(p+8,p+8+n)); p+=12+n; }
  const raw=inflateSync(Buffer.concat(chunks)), stride=1025;
  assert.equal(raw.length,256*stride);
  for(let y=0;y<256;y++) assert.equal(raw[y*stride],0,'Expected unfiltered authored RGBA PNG');
  // Up/down must also survive the engine's quarter-turn/reflection convention.
  // This checks delivered pixels independently of our face-to-ray assumption.
  if(face==='up'||face==='dn') for(let y=0;y<256;y++) for(let x=0;x<256;x++) {
    const pixel=(a,b)=>raw.subarray(b*stride+1+a*4,b*stride+5+a*4).toString('hex');
    assert.equal(pixel(x,y),pixel(255-y,x),'Polar face quarter-turn discontinuity');
    assert.equal(pixel(x,y),pixel(255-x,y),'Polar face reflection discontinuity');
  }
  for(let y=0;y<256;y++) for(let x=0;x<256;x++) if(x===0||y===0||x===255||y===255) {
    const u=x*2-255,v=y*2-255;
    const key=({ft:[u,-v,-255],bk:[-u,-v,255],lf:[-255,-v,-u],rt:[255,-v,u],up:[v,255,-u],dn:[-v,-255,-u]})[face].join(',');
    const pixel=raw.subarray(y*stride+1+x*4,y*stride+5+x*4).toString('hex');
    if(edgePixels.has(key)) { assert.equal(pixel,edgePixels.get(key),`Sky seam: ${face} ${x},${y}`); shared++; }
    else edgePixels.set(key,pixel);
  }
}
assert.equal(edgePixels.size,3056); assert.equal(shared,3064);
console.log('A.2b cubemap PASS: decoded all six PNG faces; 3056 shared edge rays, zero RGBA discontinuities');
const a2b=JSON.parse(read('docs/evidence/m7-a2b/captures.json'));
const a2bSources=JSON.parse(read('docs/evidence/m7-a2b/source-snapshot.json'));
assert.equal(a2b.status,'ART_PENDING');
assert.equal(a2b.runtimeSourceCommit,'39788eafaf93de4c21f7817f0aff4cb4e38ffd35');
for(const [path,hash] of Object.entries(a2b.sources)) {
  assert.equal(sha(a2bSources[path]),hash,`A.2b archived source integrity: ${path}`);
  // A.2b is now historical; its immutable source snapshot remains checked above.
}
for(const [name,entry] of Object.entries(a2b.images)) {
  assert(a2b.builds[entry.build],`Unknown A.2b capture build: ${name}`);
  assert.equal(createHash('sha256').update(readFileSync(resolve(root,'docs/evidence/m7-a2b',name))).digest('hex'),entry.sha256,`A.2b image integrity: ${name}`);
}
for(const camera of ['overview','spawn']) for(const pose of ['day','sunset','night','rain','dawn','afterrain']) {
  const entry=a2b.images[`final-${camera}-${pose}.jpg`];
  assert.equal(entry.build,'final'); assert.equal(entry.graphics,'Manual 5'); assert.equal(entry.quality,'full');
}
assert.equal(a2b.video.durationSeconds,45);
assert.equal(createHash('sha256').update(readFileSync(resolve(root,'docs/evidence/m7-a2b',a2b.video.file))).digest('hex'),a2b.video.sha256,'A.2b video integrity');
assert.equal(createHash('sha256').update(readFileSync(resolve(root,'docs/evidence/m7-a2b/studio-audit.txt'))).digest('hex'),a2b.studioAuditSha256,'A.2b Studio audit integrity');
console.log('A.2b evidence PASS: exact captured sources, 12 matched final views, supporting captures and 45-second recording');
const a2c=JSON.parse(read('docs/evidence/m7-a2c/captures.json'));
const a2cSources=JSON.parse(read('docs/evidence/m7-a2c/source-snapshot.json'));
assert.equal(a2c.status,'ART_PENDING');
assert.equal(a2c.runtimeSourceCommit,'18d36466f86f4a0bf9b4d3723482dac5b313c751');
for(const [path,hash] of Object.entries(a2c.sources)) {
  assert.equal(sha(a2cSources[path]),hash,`A.2c archived source integrity: ${path}`);
  // A.2c is an immutable historical capture after owner Gate A approval.
  // Issue #18 changes only presentation; keep the approved atmospheric data/art exact.
  if(path.startsWith('src/shared/Environment') || path==='src/server/EnvironmentArt.luau')
    assert.equal(sha(read(path)),hash,`Approved atmosphere changed: ${path}`);
}
for(const [name,entry] of Object.entries(a2c.images)) {
  assert(a2c.builds[entry.build],`Unknown A.2c capture build: ${name}`);
  assert.equal(sha(readFileSync(resolve(root,'docs/evidence/m7-a2c',name))),entry.sha256,`A.2c image integrity: ${name}`);
}
for(const version of ['before','after']) for(const graphics of [5,10]) for(const pose of ['dawn','sunset','night','rain','afterrain']) {
  const entry=a2c.images[`${version}-${graphics}-${pose}.jpg`];
  assert.equal(entry.build,version==='before'?'baseline':'final');
  assert.equal(entry.graphics,`Manual ${graphics}`); assert.equal(entry.camera,'spawn'); assert.equal(entry.quality,'full');
}
assert.equal(a2c.video.durationSeconds,45);
assert.equal(sha(readFileSync(resolve(root,'docs/evidence/m7-a2c',a2c.video.file))),a2c.video.sha256,'A.2c video integrity');
assert.equal(sha(readFileSync(resolve(root,'docs/evidence/m7-a2c/studio-audit.txt'))),a2c.studioAuditSha256,'A.2c audit integrity');
console.log('A.2c evidence PASS: archived captured runtime, approved atmosphere data/art, 20 matched graphics 5/10 frames and native recording');
console.log(`M7 integrity PASS: ${Object.keys(baseline.unchanged).length} unchanged M6 files, gameplay World, release flags, art source hashes, A.2 capture provenance and isolated harness`);
