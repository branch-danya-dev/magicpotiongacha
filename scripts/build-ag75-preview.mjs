// Explicit AG75 Studio Play deliverable. Never publish this place as a game.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {spawnSync} from 'node:child_process';
import assert from 'node:assert/strict';
const root=resolve(import.meta.dirname,'..');
const project=JSON.parse(readFileSync(resolve(root,'default.project.json'),'utf8'));
function absolute(node) {for(const [key,value] of Object.entries(node)) {
 if(key==='$path') node[key]=resolve(root,value);
 else if(value&&typeof value==='object') absolute(value);
}}
absolute(project);
project.name='PotionTycoon-AG75-OwnerFeedback-QA';
project.tree.ReplicatedStorage.FamiliarTemplates={$className:'Folder',GreenSlime:{$path:resolve(root,'assets/familiars/green_slime/GreenSlime.rbxmx')}};
Object.assign(project.tree.Workspace.$attributes,{
 GreenSlimeRigPreviewEnabled:true, AG74TwoPets:true,
 AG75StarterCardsEnabled:true,AG75SimplifiedSceneEnabled:true,
 AG75AtmosphereEnabled:true,AG75GroupedHUDEnabled:true,
});
project.tree.StarterPlayer.StarterPlayerScripts.AG74Preview={$path:resolve(root,'qa/green-slime/Preview.client.luau')};
Object.assign(project.tree.Lighting.$properties,{Technology:'Future',LightingStyle:'Realistic',PrioritizeLightingQuality:true});
mkdirSync(resolve(root,'build'),{recursive:true});
const input=resolve(root,'build/ag75-preview.project.json');
const output=resolve(root,'build/PotionTycoon-AG75-OwnerFeedback-QA.rbxlx');
writeFileSync(input,JSON.stringify(project,null,2)+'\n');
const rojo=resolve(root,'.tools/rojo/rojo'+(process.platform==='win32'?'.exe':''));
const result=spawnSync(rojo,['build',input,'-o',output],{cwd:root,stdio:'inherit'});
assert.equal(result.status,0);
let xml=readFileSync(output,'utf8');
assert.equal(xml.split('EnvironmentArtEnabled = false').length,2);
xml=xml.replace('EnvironmentArtEnabled = false','EnvironmentArtEnabled = game:GetService("RunService"):IsStudio()');
assert(xml.includes('UseMemoryInStudio = true')&&xml.includes('MonetizationEnabled = false')&&xml.includes('TradingEnabled = false'));
writeFileSync(output,xml);
console.log('AG75 owner QA: '+output+' (Studio only; no saving, merge or publication).');
