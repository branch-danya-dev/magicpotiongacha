// Local art-only adapter; V1 and production bytes are immutable.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
import {decode,downscale} from './lunar-pixels.mjs';
const root=resolve(import.meta.dirname,'..'),path=p=>resolve(root,p),base='08e7603a124807318236ed6521e97ac1ea9f6277';
const hash=b=>createHash('sha256').update(b).digest('hex');
const manifest=JSON.parse(readFileSync(path('assets/environment/willow-v2/manifest.json'),'utf8'));
for(const entry of [...manifest.files,...manifest.sources])assert.equal(hash(readFileSync(path(entry.path))),entry.sha256,entry.path);
const protectedPaths=execFileSync('git',['ls-tree','-r','--name-only',base,'src','assets/environment/willow','qa/willow','default.project.json'],{cwd:root,encoding:'utf8'}).trim().split('\n');
for(const p of protectedPaths){const a=execFileSync('git',['show',`${base}:${p}`],{cwd:root,maxBuffer:64*1024*1024}),b=readFileSync(path(p));
 if(/\.(luau|md|json|txt|svg)$/.test(p)||/\/\.git(attributes|ignore)$/.test(p))assert.equal(b.toString().replaceAll('\r\n','\n'),a.toString().replaceAll('\r\n','\n'),p);else assert.deepEqual(b,a,p);
}
execFileSync(process.execPath,['scripts/build-lunar-island.mjs'],{cwd:root,stdio:'pipe'});
const data=readFileSync(path('assets/environment/willow-v2/prepared/WillowV2.mesh.json'),'utf8');
mkdirSync(path('build/willow-v2'),{recursive:true});
writeFileSync(path('build/willow-v2/data.luau'),'return game:GetService("HttpService"):JSONDecode([==['+data+']==])\n');
const maps={};
for(const [key,file,size] of [['bark','Bark',512],['foliage','FoliageAtlas',1024]]){
 const img=decode(readFileSync(path(`assets/environment/willow/textures/${file}.png`)));const rgba=img.w===size?img.rgba:downscale(img,size);
 maps[key]=`{size=${size},rgba=[==[${rgba.toString('base64')}]==]}`;
}
writeFileSync(path('build/willow-v2/pixels.luau'),`return {bark=${maps.bark},foliage=${maps.foliage}}\n`);
const project=JSON.parse(readFileSync(path('build/lunar-island.project.json'),'utf8')),node=p=>({$path:path(p)});
project.name='WillowV2-ArtPolish-OWNER-ART-PENDING';project.tree.Workspace.$attributes.WillowV2QA=true;
const shared=project.tree.ReplicatedStorage.PotionTycoon.Shared,client=project.tree.StarterPlayer.StarterPlayerScripts.WizardReview;
shared.WillowV2Data=node('build/willow-v2/data.luau');shared.WillowV2Pixels=node('build/willow-v2/pixels.luau');
client.Review=node('qa/willow-v2/Review.client.luau');
for(const file of ['TreeModel','TreeVisualConfig','TreeWindModel','TreeWindController'])client[file]=node('qa/trees/'+file+'.luau');
const output='build/WillowV2-ArtPolish-QA.rbxlx';
writeFileSync(path('build/willow-v2/review.project.json'),JSON.stringify(project,null,2)+'\n');
execFileSync(path('.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),['build',path('build/willow-v2/review.project.json'),'-o',path(output)],{stdio:'inherit'});
const bytes=readFileSync(path(output));assert(!bytes.includes('<string name="Name">Main</string>'));
writeFileSync(path('build/willow-v2/build.json'),JSON.stringify({base,head:execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim(),artifact:output,sha256:hash(bytes),meshSha256:hash(Buffer.from(data)),protectedPaths,studioOnly:true,uploads:0,screenshots:0,integrated:false},null,2)+'\n');
console.log('Willow V2 QA built '+output);
