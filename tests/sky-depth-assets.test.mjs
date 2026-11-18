import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {generate,hash} from '../scripts/prepare-sky-depth.mjs';
import {decode} from '../scripts/lunar-pixels.mjs';
const dir='assets/environment/sky-world-tree/r4',manifest=JSON.parse(readFileSync(`${dir}/manifest.json`));
test('R4 masks and trunk rebuild from pinned source byte-for-byte',()=>{
 const g=generate();assert.equal(hash(g.atlas),manifest.files[0].sha256);assert.equal(hash(g.geometry),manifest.files[1].sha256);
 assert.deepEqual(g.manifest,manifest);
 for(const f of manifest.files)assert.equal(hash(readFileSync(f.path)),f.sha256);
});
test('Atlas contains independent silhouettes, padded edges and bounded support',()=>{
 const {rgba}=decode(readFileSync(`${dir}/CanopyAtlas.png`));const masks=[];
 for(const r of manifest.atlas.rects){
  const mask=[];let area=0;
  for(let y=0;y<256;y++)for(let x=0;x<1024;x++){
   const a=rgba[((r.y-8+y)*1024+x)*4+3];
   if(y<8||y>=248||x<8||x>=1016)assert.equal(a,0);
   if(a>32)area++;mask.push(a);
  }
  assert(area>10000&&area<80000);masks.push(mask);
 }
 for(let i=0;i<3;i++)for(let j=i+1;j<3;j++){
  let intersection=0,union=0;for(let k=0;k<masks[i].length;k++){const a=masks[i][k]>32,b=masks[j][k]>32;if(a||b)union++;if(a&&b)intersection++;}
  assert(intersection/union<.16,'Cannot use shifted copies of the full tree');
 }
});
test('Trunk geometry is finite, bounded, closed and has no degenerate triangles',()=>{
 const {branches}=JSON.parse(readFileSync(`${dir}/trunk.json`));let triangles=0,vertices=0;
 for(const b of branches){
  assert(b.bounds.every(n=>n>0&&n<2048));const edges=new Map();
  for(const p of b.vertices)assert(p.every(Number.isFinite));
  for(const n of b.normals)assert(Math.abs(Math.hypot(...n)-1)<1e-9);
  for(const tri of b.triangles){
   assert(new Set(tri).size===3);for(const i of tri)assert(i>=0&&i<b.vertices.length);
   const [a,c,d]=tri.map(i=>b.vertices[i]);const u=c.map((v,i)=>v-a[i]),v=d.map((q,i)=>q-a[i]);
   assert(Math.hypot(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])>1e-6);
   for(let k=0;k<3;k++){const key=[tri[k],tri[(k+1)%3]].sort((a,b)=>a-b).join(':');edges.set(key,(edges.get(key)||0)+1);}
  }
  assert([...edges.values()].every(n=>n===2));triangles+=b.triangles.length;vertices+=b.vertices.length;
 }
 assert.equal(triangles,536);assert.equal(vertices,280);assert.equal(manifest.meshes,6);
 assert.equal(manifest.textureBytes,4194304);assert.equal(manifest.uploads,0);
});
