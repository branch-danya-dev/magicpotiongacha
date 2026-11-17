import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {decode} from '../scripts/lunar-pixels.mjs';
const dir=new URL('../assets/environment/willow/',import.meta.url);
const read=p=>readFileSync(new URL(p,dir));
const mesh=JSON.parse(read('prepared/Willow.mesh.json'));
test('Willow source is preserved exactly and separate from export',()=>{
 assert.equal(createHash('sha256').update(read('source/Meshy_AI_model_20261117_generate.fbx')).digest('hex'),'c6d4ce5eac77a3d260bb184583e86f5f0d3adb65f974fd923c47a9ed30a515a6');
 assert(!read('prepared/Willow.fbx').equals(read('source/Meshy_AI_model_20261117_generate.fbx')));
});
test('Willow geometry, ribbons, UVs and weight budgets survive export',()=>{
 assert.equal(mesh.groups,84);assert.equal(mesh.bones.length,9);assert.equal(mesh.meshes.length,2);
 let triangles=0;
 for(const m of mesh.meshes){triangles+=m.triangles.length;assert.equal(m.uv.length,m.triangles.length);assert.equal(m.normals.length,m.triangles.length);
  assert.equal(new Set(m.triangles.map(t=>[...t].sort((a,b)=>a-b).join(','))).size,m.triangles.length,'No overlapping duplicate faces');
  for(const p of m.vertices)assert(p.length===3&&p.every(Number.isFinite));
  m.triangles.forEach((t,i)=>{assert.equal(new Set(t).size,3);assert(t.every(v=>Number.isInteger(v)&&v>=0&&v<m.vertices.length));
   for(const uv of m.uv[i])assert(uv.every(Number.isFinite));
   for(const n of m.normals[i])assert(Math.abs(Math.hypot(...n)-1)<.001);
  });
  if(m.weights){assert.equal(m.weights.length,m.vertices.length);for(const [b,w]of m.weights)assert(b>=1&&b<=8&&w>=0&&w<=.9);}
 }
 assert(triangles>=4000&&triangles<=6500);
 const roundtrip=JSON.parse(read('prepared/validation.json'));assert.equal(roundtrip.roundtrip,'PASS');assert.equal(roundtrip.Willow_Trunk.maxDisplacement,0);
 assert.equal(roundtrip.fbxSha256,createHash('sha256').update(read('prepared/Willow.fbx')).digest('hex'));
 assert.equal(roundtrip.meshSha256,createHash('sha256').update(read('prepared/Willow.mesh.json')).digest('hex'));
 assert.equal(roundtrip.meshes.reduce((n,m)=>n+m.triangles,0),triangles);
 assert(roundtrip.Willow_Foliage.maxDisplacement>.005&&roundtrip.Willow_Foliage.loopSeam<.01);
});
test('Willow atlas is 1024 RGBA with real transparent gaps and detailed opaque leaves',()=>{
 const atlas=decode(read('textures/FoliageAtlas.png'));assert.equal(atlas.w,1024);assert.equal(atlas.h,1024);
 let empty=0,solid=0,brightFringe=0;
 for(let i=0;i<atlas.rgba.length;i+=4){const [r,g,b,a]=atlas.rgba.subarray(i,i+4);if(a<8)empty++;if(a>240)solid++;if(a>32&&g>220&&b<65&&(r<80||r>220))brightFringe++;}
 assert(empty>1024*1024*.25);assert(solid>1024*1024*.20);assert(brightFringe<20);
});
test('Willow driver only consumes GlobalWind and QA never maps production server Main',()=>{
 const wind=readFileSync(new URL('../qa/willow/Wind.luau',import.meta.url),'utf8');
 assert(!/GlobalWind\s*=/.test(wind));assert(!/RemoteEvent|FireServer|DataStore|Lighting/.test(wind));
 assert.equal((wind.match(/Heartbeat:Connect/g)||[]).length,1);assert(wind.includes('connection:Disconnect()'));
 const build=readFileSync(new URL('../scripts/build-willow.mjs',import.meta.url),'utf8');assert(!build.includes('src/server/Main'));
});
