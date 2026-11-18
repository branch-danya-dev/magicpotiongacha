// R4 isolated composition. R3's EnvironmentView and renderer sources stay intact.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {execFileSync} from 'node:child_process';
import assert from 'node:assert/strict';
import {decode} from './lunar-pixels.mjs';
import {hash} from './prepare-sky-depth.mjs';
const root=resolve(import.meta.dirname,'..'),path=p=>resolve(root,p),read=p=>readFileSync(path(p),'utf8').replaceAll('\r\n','\n');
const base='c1689262ae73a06426a7308b02235b501cf6c167',owner=process.argv.find(a=>a.startsWith('--owner-user-id='));assert(owner,'Explicit owner required');
execFileSync('git',['diff','--exit-code','--ignore-cr-at-eol',base,'--','src','default.project.json','qa/sky-landmark','qa/lunar','qa/trees','qa/current-game','scripts/build-sky-landmark.mjs','assets/environment/sky-world-tree/r2'],{cwd:root});
if(!process.argv.includes('--reuse-r3'))execFileSync(process.execPath,['scripts/build-sky-landmark.mjs',owner],{cwd:root,stdio:'pipe',maxBuffer:8e6});
const r3=JSON.parse(read('build/sky-landmark/build.json'));assert.equal(r3.owner,Number(owner.split('=')[1]));assert.equal(r3.autoCheck,false);
const dir='assets/environment/sky-world-tree/r4',manifest=JSON.parse(read(`${dir}/manifest.json`));
assert.equal(hash(readFileSync(path(manifest.source))),manifest.sourceSHA256);
assert.equal(hash(readFileSync(path(`${dir}/recipe.json`))),manifest.recipeSHA256);
for(const f of manifest.files)assert.equal(hash(readFileSync(path(f.path))),f.sha256,f.path);
const atlas=decode(readFileSync(path(`${dir}/CanopyAtlas.png`))),geometry=JSON.parse(read(`${dir}/trunk.json`));
const lua=v=>Array.isArray(v)?'{'+v.map(lua).join(',')+'}':v&&typeof v==='object'?'{'+Object.entries(v).map(([k,x])=>k+'='+lua(x)).join(',')+'}':typeof v==='string'?JSON.stringify(v):String(v);
mkdirSync(path('build/sky-depth'),{recursive:true});
writeFileSync(path('build/sky-depth/data.luau'),'return '+lua({rgba:atlas.rgba.toString('base64'),rects:manifest.atlas.rects,branches:geometry.branches,vertices:manifest.vertices,triangles:manifest.triangles})+'\n');
let renderer=read('qa/sky-landmark/SkyLandmark.luau');
function patch(a,b){assert.equal(renderer.split(a).length,2,'R3 renderer adapter drift: '+a);renderer=renderer.replace(a,b);}
patch('local M={}','local Depth=require(script.Parent.SkyDepthRenderer)\nlocal M={}');
patch('local oceanEnabled=true','local oceanEnabled=true\n\tlocal depth');
patch('if folder then folder:Destroy();folder=nil end;table.clear(labels);table.clear(banks);pool.destroy()','if depth then depth.destroy() end\n\t\tif folder then folder:Destroy();folder=nil end;table.clear(labels);table.clear(banks);pool.destroy()');
patch('self.ready=true;cleanupConnection=folder.Destroying:Connect(dispose)','depth=Depth.create(folder,images.Cloud,Data.Cloud.crop)\n\t\tself.ready=true;cleanupConnection=folder.Destroying:Connect(dispose)');
patch('self.updates+=1;self.lastMs=(os.clock()-started)*1000',`local enabled=depth and depth.update(current,quality,workspace:GetAttribute("SkyTreeDepthMode"),oceanEnabled)
\t\tif enabled then for _,name in ipairs({"WorldTree","MinimalComposition","CrownTop","CrownLeft","CrownRight"})do labels[name].ImageTransparency=1 end end
\t\tself.updates+=1;self.lastMs=(os.clock()-started)*1000`);
patch('ready=self.ready,error=self.error,destroyed=self.destroyed,images=#pool.items','depth=depth and depth.stats() or nil,ready=self.ready,error=self.error,destroyed=self.destroyed,images=#pool.items');
writeFileSync(path('build/sky-depth/renderer.luau'),renderer);
const project=JSON.parse(read('build/sky-landmark/game.project.json')),node=p=>({$path:path(p)});
const shared=project.tree.ReplicatedStorage.PotionTycoon.Shared,client=project.tree.StarterPlayer.StarterPlayerScripts.PotionTycoon;
shared.SkyDepthModel=node('qa/sky-depth/Model.luau');shared.SkyDepthData=node('build/sky-depth/data.luau');
client.SkyLandmark=node('build/sky-depth/renderer.luau');client.SkyDepthRenderer=node('qa/sky-depth/Renderer.luau');client.SkyDiagnostics=node('qa/sky-depth/Diagnostics.client.luau');
project.name='PotionTycoon-SkyWorldTree-R4-Experimental';project.tree.Workspace.$attributes.SkyTreeDepthMode='R4';
project.tree.Workspace.$attributes.SkyDepthAutoCheck=process.argv.includes('--verify');
writeFileSync(path('build/sky-depth/game.project.json'),JSON.stringify(project,null,2)+'\n');
const output='build/PotionTycoon-SkyWorldTree-R4-Experimental.rbxlx';
execFileSync(path('.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),['build',path('build/sky-depth/game.project.json'),'-o',path(output)],{stdio:'inherit'});
const xml=read(output);assert(xml.includes('AG76 QA cannot access live persistence'));assert(xml.includes('UseMemoryInStudio = true'));
const receipt={base,head:execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim(),owner:r3.owner,artifact:output,sha256:hash(readFileSync(path(output))),r3ArtifactSHA256:r3.sha256,environmentViewSHA256:hash(readFileSync(path('build/sky-landmark/environment-view.luau'))),autoCheck:process.argv.includes('--verify'),mode:'R4',minimalFallback:'R3',ordinaryCamera:true,addedInstances:26,totalInstances:71,additionalTextureBytes:manifest.textureBytes,totalTextureBytes:r3.textureBytes+manifest.textureBytes,additionalImages:1,additionalMeshes:manifest.meshes,vertices:manifest.vertices,triangles:manifest.triangles,newFrameConnections:0,newLights:0,productionIntegrated:false,horizon:'Unresolved R3 defect; not changed by R4',uploads:0};
writeFileSync(path('build/sky-depth/build.json'),JSON.stringify(receipt,null,2)+'\n');console.log(JSON.stringify(receipt,null,2));
