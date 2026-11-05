import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const dir='docs/evidence/m7-19b/';
const hash=b=>createHash('sha256').update(b).digest('hex');
const manifest=JSON.parse(readFileSync(dir+'captures.json','utf8'));
const snapshot=JSON.parse(readFileSync(dir+'source-snapshot.json','utf8'));
for(const [path,expected] of Object.entries(manifest.sourcesNormalizedLF))
  assert.equal(hash(snapshot[path]),expected,`19b captured runtime changed: ${path}`);
for(const [file,expected] of Object.entries(manifest.files))
  assert.equal(hash(readFileSync(dir+file)),expected,`19b evidence changed: ${file}`);
assert.equal(manifest.status,'TASK_03_REVIEW_PENDING');
assert.equal(manifest.build.qa,false);
assert.equal(manifest.build.serializedSourcesVerified,55);
assert.equal(manifest.build.runtimeSourceCommit,manifest.recordedBuild.runtimeSourceCommit);
assert.equal(manifest.comparisons.length,8);
for(const view of ['spawn','farm','bazaar','build']) for(const graphics of [5,10]) {
  const pair=manifest.comparisons.find(p=>p.view===view && p.graphics===graphics);
  assert(pair,`missing ${view}/${graphics}`);
  assert.deepEqual(pair.before.camera,pair.after.camera);
  for(const frame of [pair.before,pair.after]) {
    assert.equal(frame.quality,'reduced'); assert.equal(frame.graphics,graphics); assert.equal(frame.gold,0);
  }
  assert.equal(pair.before.pool,0); assert.equal(pair.after.pool,23); assert.equal(pair.after.glow,0);
  assert(manifest.files[pair.beforeFile] && manifest.files[pair.afterFile]);
}
for(const quality of ['full','reduced','minimal']) {
  assert(manifest.supplementalFrames.some(f=>f.quality===quality && f.graphics===5 && f.gold===70 && f.glow===3 && f.pool===23));
}
const audit=readFileSync(dir+'studio-audit.txt','utf8');
const candidate=audit.split('=== candidate ===')[1].split('=== plain-delivery ===')[0];
for(let step=1;step<=12;step++) assert(candidate.includes(`M7_19B_WALK step=${step} reached=true alive=true`));
for(let batch=1;batch<=5;batch++) assert(candidate.includes(`M7_19B_EARN batch=${batch} gold=${batch*14}`));
assert(candidate.includes('samples=2888 highest=0.40625 lowest=0.4052734375 anchors=PASS integrated=true'));
assert.equal(manifest.budgets.newLocalParts,23);
assert.equal(manifest.budgets.terrainCells,1082880);
assert.equal(manifest.video.durationSeconds,44.87);
assert(audit.split('=== plain-delivery ===')[1].includes('M7_19A_TERRAIN'));
console.log(`19b evidence PASS: eight camera pairs, bounded glow, 12 walk segments, ordinary Play; runtime ${manifest.runtimeSourceCommit}`);
