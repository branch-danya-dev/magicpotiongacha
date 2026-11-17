// Owner-requested full-game preview. Adapters live only in build/; production stays intact.
import {readFileSync,writeFileSync,readdirSync,mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const root=resolve(import.meta.dirname,'..'),path=p=>resolve(root,p);
const read=p=>readFileSync(path(p),'utf8').replaceAll('\r\n','\n');
const hash=p=>createHash('sha256').update(readFileSync(path(p))).digest('hex');
const base='c7f4764f7f18a6791cb41c21611d9a8f7d8ab19b';
const owner=Number(process.argv.find(x=>x.startsWith('--owner-user-id='))?.split('=')[1]);
assert(Number.isSafeInteger(owner)&&owner!==0,'Pass explicit --owner-user-id=11924805007');
const protectedPaths=execFileSync('git',['ls-tree','-r','--name-only',base,'src','default.project.json'],{cwd:root,encoding:'utf8'}).trim().split('\n');
for(const file of protectedPaths) assert.equal(read(file),execFileSync('git',['show',`${base}:${file}`],{cwd:root,encoding:'utf8'}).replaceAll('\r\n','\n'),`Production drift: ${file}`);
mkdirSync(path('build'),{recursive:true});
for(const args of [['scripts/build-lunar-island.mjs'],['scripts/build-ag76-preview.mjs',`--owner-user-id=${owner}`]])
 execFileSync(process.execPath,args,{cwd:root,stdio:'pipe'});
const project=JSON.parse(read('build/ag76-preview.project.json'));
const lunar=JSON.parse(read('build/lunar-island.project.json'));
project.name='PotionTycoon-Current-Game-QA';
const enumerate=directory=>Object.fromEntries(readdirSync(path(directory),{withFileTypes:true}).filter(f=>f.isDirectory()||f.name.endsWith('.luau')).map(f=>[f.name.replace(/(?:\.(?:client|server))?\.luau$/,''),{$path:path(directory+'/'+f.name)}]));
const server={$className:'Folder',...enumerate('src/server')};
const client={$className:'Folder',...enumerate('src/client')};
project.tree.ServerScriptService.PotionTycoon=server;
project.tree.StarterPlayer.StarterPlayerScripts.PotionTycoon=client;
project.tree.ReplicatedStorage.PotionTycoon.Shared=lunar.tree.ReplicatedStorage.PotionTycoon.Shared;
project.tree.ReplicatedStorage.WillowNativeTemplate={$path:path('assets/environment/willow/prepared/WillowRoblox.rbxmx')};
delete project.tree.ServerScriptService.AG76Checks; // Old checks intentionally assert the superseded faceted cliff.
project.tree.ServerScriptService.CurrentGameChecks={$path:path('qa/current-game/Checks.server.luau')};
project.tree.Workspace.Terrain=lunar.tree.Workspace.Terrain;
Object.assign(project.tree.Workspace.$attributes,{CurrentGameQA:true,AG75AtmosphereEnabled:false,CurrentGameBaseSHA:base});
const adapt=(source,a,b)=>{assert.equal(source.split(a).length,2,`Adapter anchor drift: ${a}`);return source.replace(a,b);};
// Reuse the exact approved prototype composition inside the existing owner World.
// Keep Art.prop/display, station anchors, server book, spawn and lifecycle untouched.
let art=read('src/server/PersonalIslandArt.luau').split('function Art.attach(root,plot)')[0];
let scene=read('qa/romantic-island/Scene.server.luau');
scene=scene.slice(scene.indexOf('local Storage='),scene.indexOf('-- Imported altar,'));
scene=adapt(scene,'local root=Instance.new("Folder");root.Name="PotionTycoonWorld";root.Parent=workspace','assert(root:GetAttribute("PersonalIsland")==true,"Expected owner island")');
const markers=scene.indexOf('-- Every protected gameplay anchor');
scene=scene.slice(0,markers)+scene.slice(scene.indexOf('-- Four small lanterns',markers));
art+='function Art.attach(root,plot)\nassert(game:GetService("RunService"):IsStudio() and workspace:GetAttribute("CurrentGameQA"),"Studio preview only")\n'+scene+
 '\nroot:SetAttribute("IslandSurfaceWidth",Island.surface.width);root:SetAttribute("IslandSurfaceDepth",Island.surface.depth)\nroot:SetAttribute("WizardReady",true)\nreturn floor,art\nend\nreturn Art\n';
writeFileSync(path('build/current-game-art.luau'),art);server.PersonalIslandArt={$path:path('build/current-game-art.luau')};
let cover=read('qa/dynamic-grass/Cover.server.luau');
cover=adapt(cover,'root:SetAttribute("GroundCoverReady",true)','root:SetAttribute("GroundCoverReady",true)\nroot:SetAttribute("EnvironmentArtEnabled",true)');
writeFileSync(path('build/current-game-cover.server.luau'),cover);
project.tree.ServerScriptService.GroundCover={$path:path('build/current-game-cover.server.luau')};
// The production Environment bootstrap remains the only caller of View.start.
client.EnvironmentView={$path:path('build/lunar-view.luau')};
client.LunarDisks={$path:path('qa/lunar/Disks.luau')};
let environment=read('src/client/Environment.client.luau');
environment=adapt(environment,'Controller.view=View.start(root,{quality=Controller.quality}); Controller.view.setReduceMotion(Controller.reduceMotion)',
 'Controller.view=View.start(root,{quality=Controller.quality}); Controller.view.setLook("OFF"); Controller.view.setReduceMotion(Controller.reduceMotion)');
writeFileSync(path('build/current-game-environment.client.luau'),environment);client.Environment={$path:path('build/current-game-environment.client.luau')};
project.tree.StarterPlayer.StarterPlayerScripts.CurrentArt={$className:'Folder',
 Additions:{$path:path('qa/current-game/Additions.client.luau')},Cliff:{$path:path('qa/wizard-island/Cliff.luau')},
 Waterfall:{$path:path('qa/romantic-island/Waterfall.luau')},NativeModel:{$path:path('qa/willow/NativeModel.luau')},
 Wind:{$path:path('qa/willow/Wind.luau')},WindModel:{$path:path('qa/willow/WindModel.luau')}};
const input=path('build/current-game.project.json');writeFileSync(input,JSON.stringify(project,null,2)+'\n');
const artifact='build/PotionTycoon-Current-Game-QA.rbxlx';
execFileSync(path('.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),['build',input,'-o',path(artifact)],{stdio:'inherit'});
const xml=read(artifact);
for(const required of ['UseMemoryInStudio = true','MonetizationEnabled = false','TradingEnabled = false','AG76 QA cannot access live persistence','WillowNativeTemplate','LunarPixels','GreenSlime','CurrentGameQA']) assert(xml.includes(required),required);
assert(!xml.includes('<string name="Name">WizardReview</string>'),'Art camera must not override game camera');
const receipt={base,head:execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim(),owner,artifact,sha256:hash(artifact),
 sourceHashes:Object.fromEntries(['scripts/build-current-game.mjs','qa/current-game/Additions.client.luau','qa/current-game/Checks.server.luau'].map(p=>[p,hash(p)])),
 protectedPaths,willowTemplate:hash('assets/environment/willow/prepared/WillowRoblox.rbxmx'),
 scope:'Combined local Studio gameplay preview; no production admission, merge or publication',memoryOnly:true,uploads:0,ownerArt:'PENDING'};
writeFileSync(path('build/current-game-build.json'),JSON.stringify(receipt,null,2)+'\n');
console.log(`Current full game: ${artifact}; owner ${owner}; SHA256 ${receipt.sha256}`);
