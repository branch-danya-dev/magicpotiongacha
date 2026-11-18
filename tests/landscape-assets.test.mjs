import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {compactCliff,compactDepth,compactTrees} from '../scripts/landscape-memory.mjs';
const read=p=>readFileSync(p,'utf8'),json=p=>JSON.parse(read(p));
const plan=read('qa/landscape/Plan.luau');
const trees=[...plan.matchAll(/\{id="([^"]+)",source="([^"]+)",variant="([^"]+)",x=([^,]+),z=([^,]+),scale=([^,]+),yaw=([^,]+),radius=([^,]+)/g)].map(m=>({id:m[1],source:m[2],variant:m[3],scale:Number(m[6]),radius:Number(m[8])}));
test('Clearance envelopes contain actual scaled mesh vertices, not guessed trunk sizes',()=>{
 assert.equal(trees.length,3);
 for(const t of trees){
  const data=json(`assets/environment/vegetation-v2/prepared/${t.source}/Tree.mesh.json`);
  const v=data.variants.find(v=>v.id===t.variant);assert(v);
  const radius=Math.max(...v.meshes.flatMap(m=>m.vertices.map(p=>Math.hypot(p[0],p[2])*t.scale)));
  assert(radius+.1<=t.radius,`${t.id}: envelope ${t.radius}, geometry ${radius}`);
 }
});
test('First grove has bounded actual geometry and decoded texture allocation',()=>{
 let triangles=0,meshes=0,bytes=0;const pools=new Set();
 for(const t of trees){
  const d=json(`assets/environment/vegetation-v2/prepared/${t.source}/Tree.mesh.json`),v=d.variants.find(v=>v.id===t.variant);
  triangles+=v.meshes.reduce((n,m)=>n+m.triangles.length,0);
  if(!pools.has(t.source+t.variant)){pools.add(t.source+t.variant);meshes+=v.meshes.length;bytes+=d.atlasSize**2*4;}
 }
 assert.equal(triangles,14434);assert.equal(meshes,17);assert.equal(bytes,6291456);assert.equal(pools.size,3);
});
test('Reused CC0 template roster still matches the admitted source receipt',()=>{
 const receipt=json('assets/environment/woodland/receipt.json');assert.match(receipt.license,/CC0/);
 const bytes=readFileSync('assets/environment/woodland/M7NatureTemplates.rbxmx');
 assert.equal(createHash('sha256').update(bytes).digest('hex'),receipt.files['M7NatureTemplates.rbxmx']);
 for(const name of ['CommonTree_5','Pine_2','Bush_Common_Flowers','Fern_1','Grass_Common_Short','Flower_3_Group','Rock_Medium_1','Pebble_Round_1','RockPath_Round_Small_1'])assert(bytes.includes(`<string name="Name">${name}</string>`),name);
});
test('All three actual generated consumers use the shared compact allocator',()=>{
 for(const [path,adapt] of [['qa/wizard-island/Cliff.luau',compactCliff],['qa/sky-depth/Renderer.luau',compactDepth],['qa/vegetation/TreeModel.luau',compactTrees]]){
  const generated=adapt(read(path).replaceAll('\r\n','\n'));
  assert(!generated.includes(':CreateEditableMesh()'),path);assert(generated.includes('MeshFactory.build(function('),path);
 }
});
