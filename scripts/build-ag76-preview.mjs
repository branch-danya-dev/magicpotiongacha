// Isolated Studio-memory artifact. An explicit owner is required; never first-join wins.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {spawnSync} from 'node:child_process';
import assert from 'node:assert/strict';
const root=resolve(import.meta.dirname,'..');
const argument=process.argv.find(x=>x.startsWith('--owner-user-id='));
assert(argument,'Pass --owner-user-id=<Studio Player UserId>; -1 is the first local multi-client fixture.');
const owner=Number(argument.split('=')[1]);
assert(Number.isSafeInteger(owner)&&owner!==0,'Invalid explicit QA owner');
const project=JSON.parse(readFileSync(resolve(root,'default.project.json'),'utf8'));
function absolute(node) { for(const [key,value] of Object.entries(node)) {
 if(key==='$path') node[key]=resolve(root,value);
 else if(value&&typeof value==='object') absolute(value);
}}
absolute(project);project.name='PotionTycoon-AG76B-PersonalIsland-QA';
project.tree.ReplicatedStorage.FamiliarTemplates={$className:'Folder',GreenSlime:{$path:resolve(root,'assets/familiars/green_slime/GreenSlime.rbxmx')}};
project.tree.ServerScriptService.AG76Checks={$path:resolve(root,'qa/personal-island/Checks.server.luau')};
project.tree.StarterPlayer.StarterPlayerScripts.AG76Checks={$path:resolve(root,'qa/personal-island/Checks.client.luau')};
Object.assign(project.tree.Workspace.$attributes,{
 AG76PersonalIsland:true,AG76QAOwnerUserId:owner,
 GreenSlimeRigPreviewEnabled:true,AG75StarterCardsEnabled:true,
 AG75SimplifiedSceneEnabled:false,AG75AtmosphereEnabled:true,AG75GroupedHUDEnabled:true,
});
Object.assign(project.tree.Lighting.$properties,{Technology:'Future',LightingStyle:'Realistic',PrioritizeLightingQuality:true});
mkdirSync(resolve(root,'build'),{recursive:true});
const input=resolve(root,'build/ag76-preview.project.json');
// Keep the owner-ready artifact separate: npm test builds the -1 multi-client fixture.
const suffix=owner>0?`-Owner${owner}`:'';
const output=resolve(root,`build/PotionTycoon-AG76B-PersonalIsland-QA${suffix}.rbxlx`);
writeFileSync(input,JSON.stringify(project,null,2)+'\n');
const result=spawnSync(resolve(root,'.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),['build',input,'-o',output],{cwd:root,stdio:'inherit'});
assert.equal(result.status,0);
const xml=readFileSync(output,'utf8');
assert(xml.includes('UseMemoryInStudio = true')&&xml.includes('MonetizationEnabled = false')&&xml.includes('TradingEnabled = false'));
assert(xml.includes('AG76 QA cannot access live persistence'));
console.log(`AG76B isolated Studio QA: ${output}; configured owner ${owner}. Never publish.`);
