import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {beforeAG70} from './ag70-preservation.mjs';
const base='6467bfd9b024dbf618496ca2901f5b6cac20abb1';
const normal=b=>b.toString().replaceAll('\r\n','\n');
const paths=execFileSync('git',['ls-tree','-r','--name-only',base,'src','tests','qa','assets'],{encoding:'utf8'}).trim().split('\n');
for(const path of [...paths,'default.project.json']) {
  const old=execFileSync('git',['show',`${base}:${path}`],{maxBuffer:64*1024*1024});
  const current=readFileSync(path);
  if(path==='src/client/EnvironmentView.luau') assert.equal(beforeAG70(path,normal(current)),normal(old),'AG69 owner exactly preserved outside reviewed AG70 seams');
  else if(/\.(luau|json|md|svg|rbxmx|txt|mjs)$/.test(path)) assert.equal(normal(current),normal(old),`Inherited source/asset/test changed: ${path}`);
  else assert(current.equals(old),`Inherited bytes changed: ${path}`);
}
const view=normal(readFileSync('src/client/EnvironmentView.luau'));
const blocks=[...view.matchAll(/^-- AG70_BEGIN_(\w+)\n([\s\S]*?)^-- AG70_END_\1/gm)];
const added=blocks.map(b=>b[2]).join('\n');
assert(!/Instance\.new|:Connect|task\.|GetService|SetAttribute|FireServer|InvokeServer|rbxasset|Skybox|Blur|DepthOfField|LightingStyle\s*=|PrioritizeLightingQuality\s*=/.test(added),'No extra instances, owners, texture churn, release writes or engine tier override');
assert.equal((view.match(/RenderStepped:Connect/g)||[]).length,1);
assert.equal((view.match(/:Connect\(/g)||[]).length,5);
assert(added.includes('ArcaneForest.default(RunService:IsStudio())'));
assert(added.includes('if RunService:IsStudio() and name=="AG70"'));
const model=normal(readFileSync('src/shared/ArcaneForest.luau'));
assert(!/GetService|Instance|task\.|os\.|rbxasset|require\(/.test(model),'Pure bounded projection');
assert(model.includes('releaseEnabled=false'));
// Validate recorded evidence, never pretend that CI performs a fresh Studio run.
const evidence='docs/evidence/ag70/r2/';
const receipt=JSON.parse(readFileSync(evidence+'manifest.json'));
assert.equal(receipt.runtimeSourceSha,'89804f0ea070b3b685a9939b00872fa0b5fe2b55');
assert.equal(receipt.baseSha,base);
assert.equal(receipt.generatedOrRetouched,false);
for(const proof of receipt.files) {
  assert(!proof.file.includes('/')&&!proof.file.includes('\\'), 'Evidence stays in its receipt directory');
  const bytes=readFileSync(evidence+proof.file);
  assert.equal(bytes.length,proof.bytes);
  assert.equal(createHash('sha256').update(bytes).digest('hex'),proof.sha256,'Recorded native evidence integrity');
}
execFileSync('git',['diff','--exit-code',receipt.runtimeSourceSha,'--','src'],{maxBuffer:64*1024*1024});
assert.equal(receipt.matchedPairs.length,16);
assert(receipt.matchedPairs.every(p=>p.matched&&p.sameTimeWeather));
for(const capture of receipt.captures) assert(receipt.files.some(p=>p.file===capture.name+'.jpg'),'Native image required for every capture');
const records=JSON.parse(readFileSync(evidence+'native-records.json'));
const get=tag=>records.filter(r=>r.tag===tag).map(r=>r.data);
const coverage=get('AG70_R1 COVERAGE');
assert.equal(coverage.length,30);
assert(coverage.every(r=>r.restored&&r.sameInstances&&r.weatherVerified&&r.poolRestored));
assert(get('AG70_R1 COVERAGE_COMPLETE').includes(120));
assert.equal(get('AG70_R1 FALLBACK').length,3);
assert(get('AG70_R1 FALLBACK').every(r=>r.lightingPreserved&&r.errors===0&&r.tracked===8&&r.folders===1));
assert(get('AG70 OWNER_RESTORE').some(r=>r.restored&&r.sameInstances&&r.windRestored&&r.weatherRemoved&&r.restartedLook==='AG70'));
assert.deepEqual(get('AG70 ESSENCE').map(r=>r.value),[0,5,10]);
assert.equal(get('AG70 PLOT').length,8);
assert.equal(get('AG70 PERF').length,12);
assert(get('AG70 BENCHMARK_DONE').includes(true));
assert.equal(JSON.parse(readFileSync(evidence+'diagnostics.json')).skySunMoonFailures,0);
console.log('AG70 scope PASS: exact AG69 gameplay/assets/HUD/Spellbook/legacy looks; one owner, same light/instance pools, published OFF.');
