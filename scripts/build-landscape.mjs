// Stage-1 ordinary-game scene. Protected gameplay/R4/Vegetation sources stay intact.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const root=resolve(import.meta.dirname,'..'),path=p=>resolve(root,p),read=p=>readFileSync(path(p),'utf8').replaceAll('\r\n','\n');
const hash=b=>createHash('sha256').update(b).digest('hex'),node=p=>({$path:path(p)});
const base='b9c5a3c1ba99f5f6079a91ffe9f53f3f823bcf1e';
const owner=process.argv.find(a=>a.startsWith('--owner-user-id='));assert(owner,'Explicit owner required');
execFileSync('git',['diff','--exit-code','--ignore-cr-at-eol',base,'--','src','default.project.json','qa/trees','qa/sky-landmark','qa/sky-depth','qa/current-game','qa/vegetation','assets'],{cwd:root});
const args=['scripts/build-vegetation.mjs',owner];if(process.argv.includes('--reuse-r4'))args.push('--reuse-r4');
execFileSync(process.execPath,args,{cwd:root,stdio:'pipe',maxBuffer:8e6});
const prior=JSON.parse(read('build/vegetation/build.json'));
assert.equal(prior.owner,Number(owner.split('=')[1]));
const project=JSON.parse(read('build/vegetation/game.project.json'));
const shared=project.tree.ReplicatedStorage.PotionTycoon.Shared,client=project.tree.StarterPlayer.StarterPlayerScripts.CurrentArt;
mkdirSync(path('build/landscape'),{recursive:true});
shared.LandscapePlan=node('qa/landscape/Plan.luau');client.LandscapeGrove=node('qa/landscape/Grove.luau');
project.tree.ServerScriptService.LandscapeSetup=node('qa/landscape/Setup.server.luau');
function adapt(source,a,b){assert.equal(source.split(a).length,2,'Landscape adapter drift: '+a);return source.replace(a,b);}
let art=read('build/current-game-art.luau');
art=adapt(art,'local Art={}','local Landscape=require(Shared.LandscapePlan)\nlocal Art={}');
art=adapt(art,'ipairs(Layout.trees)','ipairs(Landscape.keepTrees(Layout.trees))');
art=adapt(art,'ipairs(Layout.clusters)','ipairs(Landscape.keepClusters(Layout.clusters))');
writeFileSync(path('build/landscape/art.luau'),art);project.tree.ServerScriptService.PotionTycoon.PersonalIslandArt=node('build/landscape/art.luau');
let additions=read('build/vegetation/additions.client.luau');
const start=additions.indexOf('local models='),end=additions.indexOf('local cloudAnchor=');assert(start>0&&end>start);
additions=additions.slice(0,start)+'while not root:GetAttribute("LandscapeReady") do task.wait(.1) end\nlocal wind=require(script.Parent.LandscapeGrove).start(root,O)\n'+additions.slice(end);
additions=adapt(additions,'if quality==Controller.quality and motion==Controller.reduceMotion then return end','if quality==Controller.quality and motion==Controller.reduceMotion then wind.update();return end');
additions=adapt(additions,'local bones=0;for _,v in ipairs(tree:GetDescendants()) do if v:IsA("Bone") then bones+=1 end end','local grove=wind.stats()');
additions=adapt(additions,'willowBones=bones,windUpdates=wind.updates','willowBones=0,grove=grove');
additions=adapt(additions,'wind.stop();models.destroy();','wind.stop();');
const oldReady=additions.split('\n').find(line=>line.startsWith('print("WILLOW_V2_GAME_READY"'));
assert(oldReady,'Missing inherited willow diagnostic');
additions=adapt(additions,oldReady,'print("LANDSCAPE_GAME_READY",game:GetService("HttpService"):JSONEncode(inspect()))');
writeFileSync(path('build/landscape/additions.client.luau'),additions);client.Additions=node('build/landscape/additions.client.luau');
// No allocation or replication of inactive willow assets, but original source files retained.
delete shared.WillowV2Data;delete shared.WillowV2Pixels;delete project.tree.ReplicatedStorage.WillowNativeTemplate;
for(const name of ['VegetationPreview','TreeModel','NativeModel','Wind','WindModel'])delete client[name];
delete project.tree.Workspace.$attributes.WillowV2QA;
const gameClient=project.tree.StarterPlayer.StarterPlayerScripts.PotionTycoon;
for(const [key,file] of Object.entries({SkyLandmarkDiagnostics:'qa/sky-landmark/Diagnostics.client.luau',SkyDiagnostics:'qa/sky-depth/Diagnostics.client.luau'})){
 if(!gameClient[key])continue;
 const text=read(file).replaceAll('WillowV2Ready','LandscapeRiggedReady').replaceAll('Willow must also load','Pilot grove must also load');
 const output=`build/landscape/${key}.client.luau`;writeFileSync(path(output),text);gameClient[key]=node(output);
}
project.name='PotionTycoon-Island-Vegetation-Pilot';project.tree.Workspace.$attributes.LandscapePilotQA=true;
project.tree.Workspace.$attributes.SkyLandmarkAutoCheck=false;project.tree.Workspace.$attributes.SkyDepthAutoCheck=false;
const output='build/PotionTycoon-Island-Vegetation-Pilot.rbxlx';
writeFileSync(path('build/landscape/game.project.json'),JSON.stringify(project,null,2)+'\n');
execFileSync(path('.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),['build',path('build/landscape/game.project.json'),'-o',path(output)],{stdio:'inherit'});
const bytes=readFileSync(path(output));assert(bytes.includes('AG76 QA cannot access live persistence'));
assert(!additions.includes('models.create')&&!additions.includes('models.destroy')&&!additions.includes('WillowV2Ready'));
assert(!/\b(?:models|tree)\b/.test(additions),'Stale active willow reference');
const report={base,head:execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim(),owner:prior.owner,artifact:output,bytes:bytes.length,sha256:hash(bytes),
 sourceAssets:prior.assets,environmentViewSHA256:hash(readFileSync(path(gameClient.EnvironmentView.$path))),
 vegetationBaseSHA256:prior.sha256,r4ArtifactSHA256:prior.r4ArtifactSHA256,stage:1,wholeIslandApproved:false,
 riggedTrees:3,staticTrees:2,undergrowthModels:22,editableMeshes:17,editableImages:3,decodedAtlasBytes:6291456,
 newLights:0,additionalFrameLoops:0,sharedBoneSchedulers:1,studioOnly:true,memoryOnly:true,ordinaryCamera:true,
 activeWillow:false,sourceWillowRetained:true,uploads:0,screenshots:0,productionIntegrated:false};
writeFileSync(path('build/landscape/build.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));
