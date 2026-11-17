// Owner-requested ordinary game preview, with V2 substituted only in generated QA.
import {readFileSync,writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const root=resolve(import.meta.dirname,'..'),path=p=>resolve(root,p),node=p=>({$path:path(p)});
const owner=process.argv.find(s=>s.startsWith('--owner-user-id='));assert(owner,'Pass explicit --owner-user-id');
for(const args of [['scripts/build-willow-v2.mjs'],['scripts/build-current-game.mjs',owner]])execFileSync(process.execPath,args,{cwd:root,stdio:'pipe'});
const project=JSON.parse(readFileSync(path('build/current-game.project.json'),'utf8'));
const shared=project.tree.ReplicatedStorage.PotionTycoon.Shared,client=project.tree.StarterPlayer.StarterPlayerScripts.CurrentArt;
shared.WillowV2Data=node('build/willow-v2/data.luau');shared.WillowV2Pixels=node('build/willow-v2/pixels.luau');
for(const file of ['TreeModel','TreeVisualConfig','TreeWindModel','TreeWindController'])client[file]=node('qa/trees/'+file+'.luau');
const adapt=(text,a,b)=>{assert.equal(text.split(a).length,2,`Willow game adapter drift: ${a}`);return text.replace(a,b)};
let additions=readFileSync(path('qa/current-game/Additions.client.luau'),'utf8').replaceAll('\r\n','\n');
additions=adapt(additions,'local models=require(script.Parent.NativeModel).load()',
 'local models=require(script.Parent.TreeModel).load(require(Shared.WillowV2Data),require(Shared.WillowV2Pixels))');
additions=adapt(additions,'local tree=models.create(art,CFrame.new(O+Vector3.new(47,.5,-29)),1)',
 'local tree=models.create(art,CFrame.new(O+Vector3.new(47,.38,-29)),"willow","island-hero")\nroot:SetAttribute("WillowV2Ready",true)');
additions=adapt(additions,'local wind=require(script.Parent.Wind).start({tree})','local wind=require(script.Parent.TreeWindController).start({tree})');
additions=adapt(additions,'print("CURRENT_GAME_CLIENT_READY",game:GetService("HttpService"):JSONEncode(inspect()))',
 'print("WILLOW_V2_GAME_READY",game:GetService("HttpService"):JSONEncode({bones=9,triangles=5783,quality=quality,images=#models.images,meshes=#models.meshes,crown=tree:GetAttribute("crown"),root=tree:GetAttribute("root"),scale=tree:GetAttribute("scale"),camera=workspace.CurrentCamera.CameraType.Name}))');
writeFileSync(path('build/willow-v2/game-additions.client.luau'),additions);
client.Additions=node('build/willow-v2/game-additions.client.luau');
delete client.NativeModel;delete client.Wind;delete client.WindModel;delete project.tree.ReplicatedStorage.WillowNativeTemplate;
project.name='PotionTycoon-WillowV2-Game-QA';project.tree.Workspace.$attributes.WillowV2QA=true;
const output='build/PotionTycoon-WillowV2-Game-QA.rbxlx',projectFile='build/willow-v2/game.project.json';
writeFileSync(path(projectFile),JSON.stringify(project,null,2)+'\n');
execFileSync(path('.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),['build',path(projectFile),'-o',path(output)],{stdio:'inherit'});
const bytes=readFileSync(path(output));
for(const marker of ['<string name="Name">Main</string>','AG76 QA cannot access live persistence','UseMemoryInStudio = true','MonetizationEnabled = false','TradingEnabled = false','WILLOW_V2_GAME_READY'])assert(bytes.includes(marker),marker);
for(const forbidden of ['WillowV2ReviewCamera','WillowV2OffIslandBenchmark','<string name="Name">WizardReview</string>'])assert(!bytes.includes(forbidden),forbidden);
const report={base:'08e7603a124807318236ed6521e97ac1ea9f6277',head:execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim(),artifact:output,sha256:createHash('sha256').update(bytes).digest('hex'),owner:Number(owner.split('=')[1]),studioOnly:true,memoryOnly:true,ordinaryCamera:true,hud:true,uploads:0,screenshots:0,productionIntegrated:false};
writeFileSync(path('build/willow-v2/game-build.json'),JSON.stringify(report,null,2)+'\n');
console.log('Willow V2 ordinary game: '+output);
