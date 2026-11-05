import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const dir='docs/evidence/m7-19a/';
const hash=b=>createHash('sha256').update(b).digest('hex');
const manifest=JSON.parse(readFileSync(dir+'captures.json','utf8'));
const snapshot=JSON.parse(readFileSync(dir+'source-snapshot.json','utf8'));
for(const [path,expected] of Object.entries(manifest.sourcesNormalizedLF))
  assert.equal(hash(snapshot[path]),expected,`19a captured runtime changed: ${path}`);
for(const [file,expected] of Object.entries(manifest.files))
  assert.equal(hash(readFileSync(dir+file)),expected,`19a evidence changed: ${file}`);
assert.equal(manifest.build.qa,false);
assert.equal(manifest.build.runtimeSourceCommit,manifest.recordedBuild.runtimeSourceCommit);
for(const pair of manifest.comparisons) {
  const deltas=pair.after.camera.map((v,i)=>v-pair.before.camera[i]);
  assert.deepEqual(deltas,pair.cameraDelta);
  assert(Math.max(...deltas.map(Math.abs))<=.1,'Camera comparison exceeded documented settling tolerance');
  if(pair.view!=='west-coast') assert(deltas.every(v=>v===0),'Spawn/bazaar cameras must match exactly');
}
assert.equal(manifest.comparisons.length,6);
assert.equal(manifest.video.durationSeconds,80);
console.log(`19a evidence PASS: archived runtime, six graphics 5/10 pairs, real video; runtime ${manifest.runtimeSourceCommit}`);
