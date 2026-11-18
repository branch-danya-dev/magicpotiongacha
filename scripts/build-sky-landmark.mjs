// Ordinary-game Studio composition stacked on PR60. No production source edits.
import{readFileSync,writeFileSync,mkdirSync}from'node:fs';
import{resolve}from'node:path';
import{execFileSync}from'node:child_process';
import{createHash}from'node:crypto';
import assert from'node:assert/strict';
import{decode}from'./lunar-pixels.mjs';
const root=resolve(import.meta.dirname,'..'),path=p=>resolve(root,p),read=p=>readFileSync(path(p),'utf8').replaceAll('\r\n','\n');
const base='6540ba350cb933c598d5abe0eb22167878e55fc9',hash=b=>createHash('sha256').update(b).digest('hex');
const owner=process.argv.find(x=>x.startsWith('--owner-user-id='));assert(owner,'Pass explicit owner UserId');
// Git ignores platform newline conversion; strict asset bytes are checked by each inherited builder.
execFileSync('git',['diff','--exit-code','--ignore-cr-at-eol',base,'--','src','default.project.json','qa/lunar','qa/trees','qa/current-game','assets/environment/lunar','assets/environment/willow','assets/environment/willow-v2'],{cwd:root});
if(!process.argv.includes('--reuse-game'))execFileSync(process.execPath,['scripts/build-willow-v2-game.mjs',owner],{cwd:root,stdio:'pipe',maxBuffer:8e6});
const receipt=JSON.parse(read('build/willow-v2/game-build.json'));assert.equal(receipt.owner,Number(owner.split('=')[1]));
const manifest=JSON.parse(read('assets/environment/sky-world-tree/manifest.json'));
for(const f of manifest.files)assert.equal(hash(readFileSync(path(f.path))),f.sha256,f.path);
mkdirSync(path('build/sky-landmark'),{recursive:true});
const pixels={};for(const name of ['Tree','Cloud','Glow','Minimal']){const d=decode(readFileSync(path(`assets/environment/sky-world-tree/textures/${name}.png`)));pixels[name]=`{size=${d.w},rgba=[==[${d.rgba.toString('base64')}]==]}`;}
writeFileSync(path('build/sky-landmark/pixels.luau'),'return {'+Object.entries(pixels).map(([k,v])=>k+'='+v).join(',\n')+'}\n');
const project=JSON.parse(read('build/willow-v2/game.project.json')),node=p=>({$path:path(p)});
const shared=project.tree.ReplicatedStorage.PotionTycoon.Shared,client=project.tree.StarterPlayer.StarterPlayerScripts.PotionTycoon;
// Native Studio 0.748 exhausted EditableMesh budget while eagerly caching all six
// Willow variants alongside the sky layers. This ordinary scene uses one hero:
// allocate its exact two selected meshes, preserving the base source and pixels.
let treeModel=read('qa/trees/TreeModel.luau');
function treePatch(a,b){assert.equal(treeModel.split(a).length,2,'Hero tree adapter drift');treeModel=treeModel.replace(a,b);}
treePatch('local variants={}','local variants={};local choice=Config.select("willow","island-hero")');
treePatch('for mi,source in ipairs(variant.meshes)do','for mi,source in ipairs(variant.meshes)do\n\t\t\tif (mi==1 and vi==choice.root) or (mi==2 and vi==choice.crown) then');
treePatch('\t\t\tend\n\t\tend\n\tend)','\t\t\tend\n\t\t\tend\n\t\tend\n\tend)');
writeFileSync(path('build/sky-landmark/hero-model.luau'),treeModel);
project.tree.StarterPlayer.StarterPlayerScripts.CurrentArt.TreeModel=node('build/sky-landmark/hero-model.luau');
for(const name of ['Config','Model','Resources'])shared['SkyLandmark'+name]=node('qa/sky-landmark/'+name+'.luau');
shared.SkyLandmarkPixels=node('build/sky-landmark/pixels.luau');client.SkyLandmark=node('qa/sky-landmark/SkyLandmark.luau');
let view=read('build/lunar-view.luau');
const patch=(a,b)=>{assert.equal(view.split(a).length,2,'Environment bridge drift: '+a);view=view.replace(a,b);};
patch('local View={}','local SkyLandmark=require(script.Parent.SkyLandmark)\nlocal View={}');
patch('local saved={}; local savedWind=workspace.GlobalWind','self.skyBaseline=require(script.Parent.LunarDiagnostics).snapshot()\n\tlocal saved={}; local savedWind=workspace.GlobalWind');
patch('local lunarDisks=LunarDisks.create(moon,Vista.moonSize)','local lunarDisks=LunarDisks.create(moon,Vista.moonSize)\n\tlocal skyLandmark=SkyLandmark.create(folder)');
patch('lunarDisks.update(sample,lunarWeights,moonDirection,self.quality)','lunarDisks.update(sample,lunarWeights,moonDirection,self.quality)\n\t\tskyLandmark.update(sample,lunarWeights,workspace.GlobalWind,self.quality,self.reduceMotion,elapsed)');
patch('counts.lunar=lunarDisks.stats();','counts.skyLandmark=skyLandmark.stats();counts.lunar=lunarDisks.stats();');
patch('lunarDisks.destroy()','skyLandmark.destroy()\n\t\tlunarDisks.destroy()');
writeFileSync(path('build/sky-landmark/environment-view.luau'),view);client.EnvironmentView=node('build/sky-landmark/environment-view.luau');
client.SkyDiagnostics=node('qa/sky-landmark/Diagnostics.client.luau');client.LunarDiagnostics=node('qa/lunar/Diagnostics.luau');
project.name='PotionTycoon-SkyWorldTree-QA';project.tree.Workspace.$attributes.SkyLandmarkQA=true;
project.tree.Workspace.$attributes.SkyLandmarkAutoCheck=process.argv.includes('--verify');
writeFileSync(path('build/sky-landmark/game.project.json'),JSON.stringify(project,null,2)+'\n');
const output='build/PotionTycoon-SkyWorldTree-QA.rbxlx';
execFileSync(path('.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),['build',path('build/sky-landmark/game.project.json'),'-o',path(output)],{stdio:'inherit'});
assert.equal((view.match(/RenderStepped:Connect/g)||[]).length,1);
const xml=read(output);for(const key of ['UseMemoryInStudio = true','AG76 QA cannot access live persistence','WILLOW_V2_GAME_READY','SkyLandmark','<string name="Name">Main</string>'])assert(xml.includes(key),key);
assert(!xml.includes('WillowV2ReviewCamera'));assert(!xml.includes('<string name="Name">WizardReview</string>'));
writeFileSync(path('build/sky-landmark/build.json'),JSON.stringify({base,head:execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim(),artifact:output,sha256:hash(readFileSync(path(output))),owner:receipt.owner,ordinaryCamera:true,autoCheck:process.argv.includes('--verify'),textureBytes:manifest.textureBytes,images:4,renderConnections:0,addedLights:0,uploads:0,productionIntegrated:false},null,2)+'\n');
console.log('Sky World Tree ordinary game built: '+output);
