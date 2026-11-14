// Isolated static native review; never alters the ordinary release project.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const project=JSON.parse(readFileSync(resolve(root,'default.project.json'),'utf8'));
function absolute(o){for(const [k,v] of Object.entries(o)){if(k==='$path')o[k]=resolve(root,v);else if(v&&typeof v==='object')absolute(v);}}
absolute(project);project.name='AG72-STATIC-DESIGN-NOT-GAMEPLAY';
project.tree.StarterPlayer.StarterPlayerScripts.AG72DesignReview={$path:resolve(root,'qa/ag72/StarterCards.client.luau')};
Object.assign(project.tree.Lighting.$properties,{Technology:'Future',LightingStyle:'Realistic',PrioritizeLightingQuality:true});
mkdirSync(resolve(root,'build'),{recursive:true});
const input=resolve(root,'build/ag72-design.project.json'),output=resolve(root,'build/AG72-DesignReview.rbxlx');
writeFileSync(input,JSON.stringify(project,null,2));
execFileSync(resolve(root,'.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),['build',input,'-o',output],{cwd:root,stdio:'inherit'});
let xml=readFileSync(output,'utf8');assert.equal(xml.split('EnvironmentArtEnabled = false').length,2);
xml=xml.replace('EnvironmentArtEnabled = false','EnvironmentArtEnabled = game:GetService("RunService"):IsStudio()');
assert(xml.includes('UseMemoryInStudio = true')&&xml.includes('MonetizationEnabled = false')&&xml.includes('TradingEnabled = false'));
writeFileSync(output,xml);
console.log('STATIC REVIEW ONLY. No gameplay selection/grant. '+output);
console.log('SHA256 '+createHash('sha256').update(xml).digest('hex'));
