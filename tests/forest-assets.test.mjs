import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const read=p=>readFileSync(p,'utf8');
const rows=[...read('qa/forest/Layout.luau').matchAll(/\{"([NWMP C])",(-?[\d.]+),(-?[\d.]+),([\d.]+),(\d+)\}/g)].map(m=>({kind:m[1],scale:Number(m[4])}));
test('Dense forest reuses three pools while budgeting rendered instance geometry',()=>{
 assert.equal(rows.length,48);const pools=new Map();let triangles=0,rigged=0;
 for(const r of rows.filter(r=>!['P','C'].includes(r.kind))){
  const source=r.kind==='M'?'magic_igor':'stylized_stefan',variant=r.kind==='W'?'Windswept':'Natural';
  const d=JSON.parse(read(`assets/environment/vegetation-v2/prepared/${source}/Tree.mesh.json`)),v=d.variants.find(v=>v.id===variant);
  const radius=Math.max(...v.meshes.flatMap(m=>m.vertices.map(p=>Math.hypot(p[0],p[2]))));
  assert(radius<(r.kind==='M'?22.4:r.kind==='W'?14:11));
  pools.set(source+variant,{meshes:v.meshes.length,bytes:d.atlasSize**2*4});
  triangles+=v.meshes.reduce((n,m)=>n+m.triangles.length,0);rigged++;
 }
 assert.equal(rigged,29);assert.equal(pools.size,3);assert.equal([...pools.values()].reduce((n,p)=>n+p.meshes,0),17);
 assert.equal([...pools.values()].reduce((n,p)=>n+p.bytes,0),6291456);assert(triangles<150000);
});
