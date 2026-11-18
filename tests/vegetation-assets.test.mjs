import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync,existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {decode} from '../scripts/lunar-pixels.mjs';
const root=new URL('../',import.meta.url),read=p=>readFileSync(new URL(p,root));
const json=p=>JSON.parse(read(p)),hash=b=>createHash('sha256').update(b).digest('hex');
const dir='assets/environment/vegetation-v2/',audit=json(dir+'source-audit.json');
const pair=['stylized_stefan','magic_igor'];
test('all nine sources have attribution records; NoAI remains metadata-only',()=>{
 assert.equal(audit.models.length,9);assert.equal(new Set(audit.models.map(m=>m.uid)).size,9);
 for(const m of audit.models){assert.equal(m.status,'METADATA_READ');assert(m.downloadable);assert.match(m.license.url,/creativecommons.org\/licenses\/by\/4.0\/?$/);assert(m.author&&m.authorURL&&m.modelURL);}
 assert(audit.models.find(m=>m.key==='oak_maple').tags.includes('noai'));
 assert(!existsSync(new URL(dir+'sources/oak_maple/',root)));
 const dungdao=audit.models.find(m=>m.key==='curved_dungdao');assert.equal(dungdao.author,'dungdao');assert.equal(dungdao.license.slug,'by');
});
test('download bytes and every retained original remain pinned to source receipts',()=>{
 for(const key of pair){const prefix=dir+'sources/'+key+'/',receipt=json(prefix+'receipt.json');
  const archive=read(prefix+'original.zip');assert.equal(archive.length,receipt.archiveBytes);assert.equal(hash(archive),receipt.archiveSHA256);
  for(const file of receipt.files){const b=read(prefix+'unpacked/'+file.path);assert.equal(b.length,file.bytes);assert.equal(hash(b),file.sha256);}
 }
 for(const f of json(dir+'manifest.json').files){const b=read(f.path);assert.equal(b.length,f.bytes);assert.equal(hash(b),f.sha256);}
});
test('both species have two distinct bounded geometry variants and complete materials',()=>{
 for(const key of pair){const data=json(dir+'prepared/'+key+'/Tree.mesh.json');assert.equal(data.variants.length,2);
  const geometries=[];
  for(const variant of data.variants){assert.equal(variant.bones.length,10);assert.equal(variant.bones[0].name,'Root');
   assert(variant.meshes.some(m=>m.role==='Bark'));assert(variant.meshes.some(m=>m.role==='Leaf'));assert(variant.meshes.some(m=>m.role==='LeafSecondary'));
   const triangles=variant.meshes.reduce((n,m)=>n+m.triangles.length,0);assert(triangles<=data.sourceTriangles);
   for(const m of variant.meshes){assert.equal(m.triangles.length,m.uv.length);assert.equal(m.triangles.length,m.normals.length);assert.equal(m.vertices.length,m.weights.length);
    for(const p of m.vertices)assert(p.length===3&&p.every(Number.isFinite));
    for(const tri of m.triangles)assert(new Set(tri).size===3&&tri.every(i=>Number.isInteger(i)&&i>=0&&i<m.vertices.length));
    for(const face of m.uv)for(const uv of face)assert(uv.every(n=>Number.isFinite(n)&&n>=0&&n<=1));
    for(const face of m.normals)for(const n of face)assert(Math.abs(Math.hypot(...n)-1)<1e-4);
    for(const ws of m.weights){assert(ws.length>=1&&ws.length<=4);assert(Math.abs(ws.reduce((n,w)=>n+w[1],0)-1)<1e-5);assert(new Set(ws.map(w=>w[0])).size===ws.length);for(const [i,w]of ws)assert(Number.isInteger(i)&&i>=0&&i<10&&w>=0&&w<=1);}
    if(m.name==='Roots'||m.role==='Stone'||m.role==='Magic')for(const ws of m.weights)assert.deepEqual(ws,[[0,1]]);
   }
   geometries.push(hash(Buffer.from(JSON.stringify(variant.meshes.map(m=>m.vertices)))));
  }assert.notEqual(geometries[0],geometries[1]);
 }
});
test('Blender FBX reimport verifies deforming foliage and static roots for all four exports',()=>{
 for(const key of pair){const v=json(dir+'prepared/'+key+'/validation.json');assert(v.packedTextures);assert.equal(v.fbxRoundtrip.length,2);
  for(const r of v.fbxRoundtrip){assert(r.rootsFixed&&r.weightsNormalized);assert.equal(r.bones,10);assert(Object.entries(r.maxDeformation).some(([name,n])=>name.startsWith('Foliage')&&n>.01));}
  for(const file of ['Editable.blend','Natural.fbx','Windswept.fbx'])assert(read(dir+'prepared/'+key+'/'+file).length>1000);
 }
});
test('atlas memory is limited to five MiB for the pair and includes foliage alpha',()=>{
 let bytes=0;
 for(const key of pair){const image=decode(read(dir+'prepared/'+key+'/Atlas.png'));assert(image.w===image.h&&image.w<=1024);bytes+=image.rgba.length;
  let transparent=0,opaque=0;for(let i=3;i<image.rgba.length;i+=4){if(image.rgba[i]<10)transparent++;if(image.rgba[i]>245)opaque++;}assert(transparent>0&&opaque>0);
 }assert.equal(bytes,5*1024*1024);
});
test('preview replaces the QA wind entry point without editing world, lighting or economy',()=>{
 const builder=read('scripts/build-vegetation.mjs').toString();assert(builder.includes('delete client.TreeWindController'));
 const wind=read('qa/vegetation/TreeWindController.luau').toString().replace(/^--.*$/gm,'');assert.equal((wind.match(/Heartbeat:Connect/g)||[]).length,1);
 assert(!/GlobalWind\s*=|Lighting|FireServer|DataStore/.test(wind));assert(wind.includes('connection:Disconnect()'));
 const model=read('qa/vegetation/TreeModel.luau').toString();assert(model.includes('part.CanCollide=false'));assert(!/CreateAssetAsync|LoadAssetAsync|Publish/.test(model));
});
