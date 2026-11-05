// Disposable Studio-only full-game preview. Never publish this artifact.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import assert from 'node:assert/strict';
const root=resolve(dirname(fileURLToPath(import.meta.url)), '..');
const project=JSON.parse(readFileSync(resolve(root,'default.project.json'),'utf8'));
function absolute(node) {
  for(const [key,value] of Object.entries(node)) {
    if(key==='$path') node[key]=resolve(root,value);
    else if(value && typeof value==='object') absolute(value);
  }
}
absolute(project);
// Plain delivery starts the full game without a diagnostic script or delayed pose jump.
if(process.argv.includes('--ui') || process.argv.includes('--safety') || process.argv.includes('--atmosphere') || process.argv.includes('--island') || process.argv.includes('--farm')) {
  const script=process.argv.includes('--farm')?'FarmReview':process.argv.includes('--island')?'IslandReview':process.argv.includes('--safety')?'SafetyReview':process.argv.includes('--ui')?'UIReview':'GameplayReview';
  project.tree.StarterPlayer.StarterPlayerScripts.A2VisualReview={$path:resolve(root,`qa/environment/${script}.client.luau`)};
}
if(process.argv.includes('--island')) project.tree.ServerScriptService.IslandReview={$path:resolve(root,'qa/environment/IslandReview.server.luau')};
if(process.argv.includes('--farm')) project.tree.ServerScriptService.FarmReview={$path:resolve(root,'qa/environment/FarmReview.server.luau')};
project.name='PotionTycoon-M7-LocalPreview';
project.tree.Lighting.$properties.Technology='Future';
project.tree.Lighting.$properties.LightingStyle='Realistic';
project.tree.Lighting.$properties.PrioritizeLightingQuality=true;
mkdirSync(resolve(root,'build'),{recursive:true});
const input=resolve(root,'build/local-preview.project.json');
const output=resolve(root,'build/PotionTycoon-M7-LocalPreview.rbxlx');
writeFileSync(input,JSON.stringify(project,null,2));
const result=spawnSync(resolve(root,'.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),['build',input,'-o',output],{cwd:root,stdio:'inherit'});
assert.equal(result.status,0,'Local preview build failed');
let xml=readFileSync(output,'utf8');
assert.equal(xml.split('EnvironmentArtEnabled = false').length,2);
xml=xml.replace('EnvironmentArtEnabled = false','EnvironmentArtEnabled = game:GetService("RunService"):IsStudio()');
assert(xml.includes('UseMemoryInStudio = true') && xml.includes('MonetizationEnabled = false') && xml.includes('TradingEnabled = false'));
writeFileSync(output,xml);
console.log('Studio-only art enabled; memory progress; commerce off. DO NOT PUBLISH: '+output);
