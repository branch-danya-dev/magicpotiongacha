// Full game, Studio-only visual QA. Normal project remains OFF; never publish this file.
import {readFileSync, writeFileSync, mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {spawnSync} from 'node:child_process';
import assert from 'node:assert/strict';
const root=resolve(import.meta.dirname,'..');
const project=JSON.parse(readFileSync(resolve(root,'default.project.json'),'utf8'));
function absolute(node){for(const [key,value] of Object.entries(node)){if(key==='$path')node[key]=resolve(root,value);else if(value&&typeof value==='object')absolute(value);}}
absolute(project);
project.name='PotionTycoon-AG74-GreenSlime-QA';
project.tree.ReplicatedStorage.FamiliarTemplates={$className:'Folder',GreenSlime:{$path:resolve(root,'assets/familiars/green_slime/GreenSlime.rbxmx')}};
project.tree.Workspace.$attributes.GreenSlimeRigPreviewEnabled=true;
project.tree.Workspace.$attributes.AG74TwoPets=true;
project.tree.StarterPlayer.StarterPlayerScripts.AG74Preview={$path:resolve(root,'qa/green-slime/Preview.client.luau')};
const checks=process.argv.includes('--checks');
if(checks) project.tree.StarterPlayer.StarterPlayerScripts.AG74Checks={$path:resolve(root,'qa/green-slime/Checks.client.luau')};
Object.assign(project.tree.Lighting.$properties,{Technology:'Future',LightingStyle:'Realistic',PrioritizeLightingQuality:true});
mkdirSync(resolve(root,'build'),{recursive:true});
const input=resolve(root,'build/ag74-preview.project.json'), output=resolve(root,checks?'build/AG74-NativeChecks.rbxlx':'build/PotionTycoon-AG74-GreenSlime-QA.rbxlx');
writeFileSync(input,JSON.stringify(project,null,2)+'\n');
const result=spawnSync(resolve(root,'.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),['build',input,'-o',output],{cwd:root,stdio:'inherit'});
assert.equal(result.status,0);
let xml=readFileSync(output,'utf8');
assert.equal(xml.split('EnvironmentArtEnabled = false').length,2);
xml=xml.replace('EnvironmentArtEnabled = false','EnvironmentArtEnabled = game:GetService("RunService"):IsStudio()');
assert(xml.includes('UseMemoryInStudio = true') && xml.includes('MonetizationEnabled = false') && xml.includes('TradingEnabled = false'));
writeFileSync(output,xml); console.log('AG74 Studio QA only; no grants; DO NOT PUBLISH: '+output);
