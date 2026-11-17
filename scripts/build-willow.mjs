// Separate local QA, no edits to production tree, no remote upload or plugin install.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {decode,downscale} from './lunar-pixels.mjs';
import assert from 'node:assert/strict';
const root=resolve(import.meta.dirname,'..'),path=p=>resolve(root,p);
const data=readFileSync(path('assets/environment/willow/prepared/Willow.mesh.json'),'utf8');
const parsed=JSON.parse(data);assert.equal(parsed.bones.length,9);
assert(parsed.meshes.reduce((n,m)=>n+m.triangles.length,0)<=6500);
mkdirSync(path('build/willow'),{recursive:true});
writeFileSync(path('build/willow/data.luau'),'-- Generated from deterministic Blender export.\nreturn game:GetService("HttpService"):JSONDecode([==['+data+']==])\n');
const textures={};
for(const [key,file,size] of [['bark','Bark',512],['foliage','FoliageAtlas',1024]]){
 const image=decode(readFileSync(path(`assets/environment/willow/textures/${file}.png`)));
 const rgba=image.w===size?image.rgba:downscale(image,size);
 textures[key]=`{size=${size},rgba=[==[${rgba.toString('base64')}]==]}`;
}
writeFileSync(path('build/willow/pixels.luau'),`-- RGBA export transport. Written once; shared by every tree.\nreturn {bark=${textures.bark},foliage=${textures.foliage}}\n`);
const node=p=>({$path:path(p)});
const shared=node('src/shared');shared.WillowData=node('build/willow/data.luau');shared.WillowPixels=node('build/willow/pixels.luau');
const client={$className:'Folder',Review:node('qa/willow/Review.client.luau'),Model:node('qa/willow/Model.luau'),Wind:node('qa/willow/Wind.luau'),WindModel:node('qa/willow/WindModel.luau'),EnvironmentView:node('src/client/EnvironmentView.luau')};
const project={name:'Willow-Prototype-ART-PENDING',tree:{$className:'DataModel',
 ReplicatedStorage:{PotionTycoon:{$className:'Folder',Shared:shared}},
 ServerScriptService:{WillowSetup:node('qa/willow/Setup.server.luau')},
 StarterPlayer:{StarterPlayerScripts:{WillowReview:client}},
 Workspace:{$properties:{Gravity:196.2}},
 Lighting:{$properties:{ClockTime:14,Brightness:2.5,LightingStyle:'Realistic',Technology:'Future',PrioritizeLightingQuality:true}}
}};
writeFileSync(path('build/willow/willow.project.json'),JSON.stringify(project,null,2)+'\n');
const artifact='build/Willow-Prototype-ART-PENDING.rbxlx';
execFileSync(path('.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),['build',path('build/willow/willow.project.json'),'-o',path(artifact)],{stdio:'inherit'});
const hash=b=>createHash('sha256').update(b).digest('hex');
writeFileSync(path('build/willow/build.json'),JSON.stringify({base:'fdaf931b179ad188555147c720b768dd9334b17b',head:execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim(),artifact,sha256:hash(readFileSync(path(artifact))),meshSha256:hash(Buffer.from(data)),automatedBuildUploads:0,integrated:false},null,2)+'\n');
console.log('Willow QA built: '+artifact);
