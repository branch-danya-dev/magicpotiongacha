import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {beforeAG70} from './ag70-preservation.mjs';
const base='df5f3ee7f582764718390957d7234633bd6747e5';
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
console.log('AG70 scope PASS: exact AG69 gameplay/assets/HUD/Spellbook/legacy looks; one owner, same light/instance pools, published OFF.');
