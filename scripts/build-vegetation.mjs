// Ordinary-game first-pair preview on the exact R4 stack, without source integration.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
import {decode} from './lunar-pixels.mjs';
const root=resolve(import.meta.dirname,'..'),path=p=>resolve(root,p),read=p=>readFileSync(path(p),'utf8').replaceAll('\r\n','\n');
const hash=b=>createHash('sha256').update(b).digest('hex');
const base='deb2ba18e1dda7f68713923a1e6164abd0df7f0f';
const owner=process.argv.find(x=>x.startsWith('--owner-user-id='));assert(owner,'Explicit owner required');
execFileSync('git',['diff','--exit-code','--ignore-cr-at-eol',base,'--','src','default.project.json','qa/trees','qa/sky-landmark','qa/sky-depth','qa/lunar','qa/current-game','assets/environment/sky-world-tree'],{cwd:root});
if(!process.argv.includes('--reuse-r4'))execFileSync(process.execPath,['scripts/build-sky-depth.mjs',owner],{cwd:root,stdio:'pipe',maxBuffer:8e6});
const r4=JSON.parse(read('build/sky-depth/build.json'));assert.equal(r4.owner,Number(owner.split('=')[1]));
const catalog=JSON.parse(read('assets/environment/vegetation-v2/source-audit.json'));
const keys=['stylized_stefan','magic_igor'];const models=[],pixels={};const assets=[];
for(const file of JSON.parse(read('assets/environment/vegetation-v2/manifest.json')).files){
 const bytes=readFileSync(path(file.path));assert.equal(bytes.length,file.bytes);assert.equal(hash(bytes),file.sha256,file.path);
}
for(const key of keys){
 const source=catalog.models.find(m=>m.key===key);assert(source.downloadable&&!source.tags.includes('noai'));
 const dir=`assets/environment/vegetation-v2/prepared/${key}`;
 const receipt=JSON.parse(read(`assets/environment/vegetation-v2/sources/${key}/receipt.json`));
 assert.equal(hash(readFileSync(path(`assets/environment/vegetation-v2/sources/${key}/original.zip`))),receipt.archiveSHA256);
 const data=JSON.parse(read(`${dir}/Tree.mesh.json`));assert.equal(data.sourceArchiveSHA256,receipt.archiveSHA256);
 const validation=JSON.parse(read(`${dir}/validation.json`));assert(validation.fbxRoundtrip.every(v=>v.rootsFixed&&v.weightsNormalized));
 models.push(data);const image=decode(readFileSync(path(`${dir}/Atlas.png`)));pixels[key]={size:image.w,rgba:image.rgba.toString('base64')};
 assets.push({key,meshSHA256:hash(readFileSync(path(`${dir}/Tree.mesh.json`))),atlasSHA256:hash(readFileSync(path(`${dir}/Atlas.png`))),textureBytes:image.rgba.length,
  variants:data.variants.map(v=>({id:v.id,triangles:v.meshes.reduce((n,m)=>n+m.triangles.length,0),meshes:v.meshes.length,bones:v.bones.length}))});
}
mkdirSync(path('build/vegetation'),{recursive:true});
const luaJSON=v=>'return game:GetService("HttpService"):JSONDecode([==['+JSON.stringify(v)+']==])\n';
writeFileSync(path('build/vegetation/data.luau'),luaJSON(models));writeFileSync(path('build/vegetation/pixels.luau'),luaJSON(pixels));
const project=JSON.parse(read('build/sky-depth/game.project.json')),node=p=>({$path:path(p)});
const shared=project.tree.ReplicatedStorage.PotionTycoon.Shared,client=project.tree.StarterPlayer.StarterPlayerScripts.CurrentArt;
shared.VegetationData=node('build/vegetation/data.luau');shared.VegetationPixels=node('build/vegetation/pixels.luau');
for(const [name,file] of Object.entries({VegetationTreeModel:'TreeModel',VegetationWindController:'TreeWindController',TreeWindPolicy:'TreeWindPolicy',Appearance:'Appearance',VegetationPreview:'Preview'}))client[name]=node(`qa/vegetation/${file}.luau`);
let additions=read('build/willow-v2/game-additions.client.luau');
const from='local wind=require(script.Parent.TreeWindController).start({tree})';assert.equal(additions.split(from).length,2);
additions=additions.replace(from,'local wind=require(script.Parent.VegetationPreview).start(root,O,tree)');
writeFileSync(path('build/vegetation/additions.client.luau'),additions);client.Additions=node('build/vegetation/additions.client.luau');
delete client.TreeWindController; // No second scheduler; willow joins the same controller.
project.name='PotionTycoon-VegetationV2-FirstPair';project.tree.Workspace.$attributes.VegetationV2QA=true;
const output='build/PotionTycoon-VegetationV2-FirstPair.rbxlx';
writeFileSync(path('build/vegetation/game.project.json'),JSON.stringify(project,null,2)+'\n');
execFileSync(path('.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),['build',path('build/vegetation/game.project.json'),'-o',path(output)],{stdio:'inherit'});
const bytes=readFileSync(path(output));assert(bytes.includes('AG76 QA cannot access live persistence'));
const report={base,head:execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim(),owner:r4.owner,artifact:output,sha256:hash(bytes),
 r4ArtifactSHA256:r4.sha256,assets,firstPairOnly:true,studioOnly:true,memoryOnly:true,ordinaryCamera:true,uploads:0,screenshots:0,productionIntegrated:false};
writeFileSync(path('build/vegetation/build.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));
