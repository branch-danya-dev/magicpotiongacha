import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
const read=p=>readFileSync(new URL('../'+p,import.meta.url));
const data=JSON.parse(read('assets/environment/willow-v2/prepared/WillowV2.mesh.json'));
test('all three crown/root variants retain bounded topology, UVs, weights and smooth normals',()=>{
 assert.equal(data.variants.length,3);
 for(const v of data.variants){assert.equal(v.bones.length,9);assert.equal(v.groups,76);assert.equal(v.meshes.reduce((n,m)=>n+m.triangles.length,0),5783);
  for(const m of v.meshes){assert.equal(m.uv.length,m.triangles.length);assert.equal(m.normals.length,m.triangles.length);
   for(const p of m.vertices)assert(p.every(Number.isFinite));
   for(const t of m.triangles)for(const i of t)assert(i>=0&&i<m.vertices.length);
   for(const face of m.uv)for(const uv of face)assert(uv.every(n=>Number.isFinite(n)&&n>=0&&n<=1));
   for(const face of m.normals)for(const n of face)assert(Math.abs(Math.hypot(...n)-1)<1e-4);
   if(m.weights){assert.equal(m.weights.length,m.vertices.length);for(const [bone,w]of m.weights)assert(bone>=1&&bone<=8&&w>=0&&w<=1);}
  }
 }
});
test('height is +30%, crown variants differ, roots remain grounded and low geometry clears building zone',()=>{
 const foliage=[],wood=[];
 for(const v of data.variants){const ps=v.meshes.flatMap(m=>m.vertices);const height=Math.max(...ps.map(p=>p[1]))-Math.min(...ps.map(p=>p[1]));assert(height/23.848>1.29&&height/23.848<1.31);
  const low=ps.filter(p=>p[1]<7);assert(Math.min(...low.map(p=>p[0]))*1.04+47>38.5);
  assert(Math.abs(Math.min(...ps.map(p=>p[1]))-.12)<.001);
  foliage.push(JSON.stringify(v.meshes[1].vertices));wood.push(JSON.stringify(v.meshes[0].vertices));
 }assert.equal(new Set(foliage).size,3);assert.equal(new Set(wood).size,3);
});
test('V1 source and shared atlas remain exact; no new image artifacts',()=>{
 const hash=p=>createHash('sha256').update(read(p)).digest('hex');
 assert.equal(hash('assets/environment/willow/prepared/Willow.mesh.json'),'7c7e9bd14794a802c0d1ccd7cdbdc99ab8c8ebe5ac905243f68ea32c03c340f0');
 assert.equal(hash('assets/environment/willow/textures/FoliageAtlas.png'),'169086eab654c01999381dfc8d659a4ff22cd63925773932eac7d9aaf4a08783');
});
test('tree controller has one scheduler and never writes global environment or gameplay',()=>{
 const s=read('qa/trees/TreeWindController.luau').toString();assert.equal((s.match(/Heartbeat:Connect/g)||[]).length,1);
 assert(!/GlobalWind\s*=|Lighting|FireServer|DataStore/.test(s.replace(/^--.*$/gm,'')));
 assert(s.includes('connection:Disconnect()'));assert(s.includes('CFrame.identity'));
});
