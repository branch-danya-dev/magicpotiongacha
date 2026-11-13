import {readFileSync,mkdtempSync,readdirSync,rmSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {inflateSync} from 'node:zlib';
import assert from 'node:assert/strict';
const base='4a158b96e2b679605e89e2b36fe3425208fea315';
const normal=s=>s.replace(/\r\n/g,'\n');
const hash=data=>createHash('sha256').update(data).digest('hex');
const inherited=execFileSync('git',['ls-tree','-r','--name-only',base,'src','tests','qa','assets'],{encoding:'utf8'}).trim().split('\n');
for(const file of [...inherited,'default.project.json']) {
  const old=execFileSync('git',['show',`${base}:${file}`],{maxBuffer:64*1024*1024});
  const current=readFileSync(file==='src/client/SpellbookEffects.luau'?'src/client/LegacySpellbookEffects.luau':file);
  if(/\.(luau|json|md|svg|rbxmx|txt)$/.test(file))assert.equal(normal(current.toString()),normal(old.toString()),`Inherited behavior drift: ${file}`);
  else assert(current.equals(old),`Inherited asset drift: ${file}`);
}
const dir='assets/vfx/ag67b';
const manifest=JSON.parse(readFileSync(`${dir}/upload-manifest.json`));
const uploads=JSON.parse(readFileSync(`${dir}/roblox-assets.json`));
const assets=readFileSync('src/shared/SpellbookSoulAssets.luau','utf8');
assert.equal(uploads.creatorId,925845207);assert.equal(uploads.universeId,10776120489);
assert.equal(uploads.assets.length,3);assert.equal(new Set(uploads.assets.map(x=>x.assetId)).size,3);
let decoded=0;
for(const file of manifest.files) {
  const png=readFileSync(`${dir}/${file.name}`);
  assert.equal(hash(png),file.sha256);assert.equal(png.length,file.bytes);
  assert.equal(png.readUInt32BE(16),file.width);assert.equal(png.readUInt32BE(20),file.height);assert.equal(png[25],6);
  let offset=8;const compressed=[];
  while(offset<png.length){const n=png.readUInt32BE(offset);if(png.toString('ascii',offset+4,offset+8)==='IDAT')compressed.push(png.subarray(offset+8,offset+8+n));offset+=n+12;}
  const rgba=inflateSync(Buffer.concat(compressed));let transparent=0,visible=0;
  for(let y=0;y<file.height;y++)for(let x=0;x<file.width;x++){
    const alpha=rgba[y*(file.width*4+1)+1+x*4+3];if(alpha===0)transparent++;else visible++;
  }
  assert(transparent>file.width*file.height*.2&&visible>100,'Transparent original art, not a solid disc');
  decoded+=file.width*file.height*4;
  const upload=uploads.assets.find(x=>x.name===file.assetName);
  assert(upload&&upload.sha256===file.sha256&&Number.isSafeInteger(upload.assetId)&&upload.assetId>0);
  assert(assets.includes(`rbxassetid://${upload.assetId}`),'Every approved uploaded image is pinned in the ordinary build');
}
assert.equal(decoded,8650752);assert.equal(decoded,manifest.decodedRgbaBytes);
assert(manifest.pageVisiblePixels.every((count,i,a)=>i===0||count<a[i-1]),'Burning must erode the actual silhouette');
const temp=mkdtempSync(join(tmpdir(),'ag67b-art-'));
try {
  execFileSync(process.execPath,[resolve('scripts/build-ag67b-art.mjs'),'--out',temp]);
  for(const name of readdirSync(temp))assert(readFileSync(join(temp,name)).equals(readFileSync(join(dir,name))),`Reproducible art: ${name}`);
} finally {rmSync(temp,{recursive:true,force:true});}
const dispatcher=readFileSync('src/client/SpellbookEffects.luau','utf8');
const view=readFileSync('src/client/SpellbookSoul/View.luau','utf8');
const primitives=readFileSync('src/client/SpellbookSoul/Primitives.luau','utf8');
const production=dispatcher+view+primitives;
assert(!/FireServer|InvokeServer|GetService\("Lighting"\)|rbxasset:\/\/ag67|AG67SoulPreview|TweenService/.test(production));
assert.equal((view.match(/Heartbeat:Connect/g)||[]).length,1);
assert.equal((view.match(/OnClientEvent:Connect/g)||[]).length,1);
assert.equal((production.match(/Instance\.new\("PointLight"\)/g)||[]).length,1);
assert(view.includes('r.light.Shadows = false; r.light.Range = 7'));
assert(primitives.includes('e.Enabled = false; e.Rate = 0'));
assert(primitives.includes('Instance.new("BillboardGui")')&&primitives.includes('gui.AlwaysOnTop = false'));
assert(dispatcher.includes('if owner then owner.stop(); owner = nil end'));
assert(dispatcher.includes('if not Policy.enabled(studio, nil) then return Legacy.start() end'));
assert(view.includes('player.CharacterRemoving:Connect(clearVisuals)'));
assert(view.includes('if r.owned or ritualBook == model then clearPool() end'));
assert(view.includes('Feedback.consume(cursor, snapshot.presentation and snapshot.presentation.essenceClick, owned)'));
assert(!/task\.spawn|task\.delay/.test(view+primitives),'No click/page coroutines');
const project=JSON.parse(readFileSync('default.project.json'));
assert(JSON.stringify(project).includes('src/client')&&JSON.stringify(project).includes('src/shared'));
const evidence=JSON.parse(readFileSync('docs/evidence/ag67b/manifest.json'));
assert.equal(evidence.baseSha,base);
for(const source of evidence.runtime)assert.equal(hash(normal(readFileSync(source.path,'utf8'))),source.normalizedSha256,`Captured runtime changed: ${source.path}`);
for(const file of evidence.files)assert.equal(hash(readFileSync(`docs/evidence/ag67b/${file.name}`)),file.sha256,`Native evidence changed: ${file.name}`);
if(process.argv.includes('--built'))assert.equal(hash(readFileSync('build/PotionTycoon.rbxlx')),evidence.capturedBuild.sha256,'Rebuilt ordinary place must match captured place');
console.log('AG67B PASS: inherited game/legacy byte-preserved; original reproducible art + approved upload IDs; automatic Studio gate, release OFF, bounded local VFX and no economy/remotes/Lighting changes.');
