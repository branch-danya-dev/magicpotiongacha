import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const dir='docs/evidence/m7-18a/';
const hash=b=>createHash('sha256').update(b).digest('hex');
const manifest=JSON.parse(readFileSync(dir+'captures.json','utf8'));
const snapshot=JSON.parse(readFileSync(dir+'source-snapshot.json','utf8'));
for(const [path,expected] of Object.entries(manifest.sourcesNormalizedLF))
  assert.equal(hash(snapshot[path]),expected,`18a captured runtime changed: ${path}`);
for(const [file,expected] of Object.entries(manifest.files))
  assert.equal(hash(readFileSync(dir+file)),expected,`18a evidence changed: ${file}`);
assert.equal(manifest.build.qa,false,'Delivered plain place must not contain QA');
console.log(`18a evidence PASS: ${manifest.captures.length} Studio captures, ${manifest.videos.length} real videos; runtime ${manifest.runtimeSourceCommit}`);
