import {beforeAG68} from './ag68-preservation.mjs';
import {readFileSync,mkdtempSync,readdirSync,rmSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {inflateSync} from 'node:zlib';
import assert from 'node:assert/strict';
const base='d026c02a3aa56b87e0883d6c9aac0f0854a81cb1';
const normal=s=>s.replace(/\r\n/g,'\n');
const files=execFileSync('git',['ls-tree','-r','--name-only',base,'src','tests','assets'],{encoding:'utf8'}).trim().split('\n');
for(const file of [...files,'default.project.json']) {
 const old=execFileSync('git',['show',`${base}:${file}`],{maxBuffer:64*1024*1024});
 // AG67B moves the accepted original owner, retaining this byte comparison.
 const current=readFileSync(file==='src/client/SpellbookEffects.luau'?'src/client/LegacySpellbookEffects.luau':file);
 if(/\.(luau|json|md|svg|rbxmx|txt)$/.test(file))assert.equal(beforeAG68(file,normal(current.toString())),normal(old.toString()),`Stage A cannot change ${file}`);
 else assert(current.equals(old),`Stage A cannot change ${file}`);
}
const dir='assets/vfx/ag67',manifest=JSON.parse(readFileSync(`${dir}/manifest.json`));
const hash=bytes=>createHash('sha256').update(bytes).digest('hex');
let bytes=0;
for(const [name,sha] of Object.entries(manifest.files)) {
 const data=readFileSync(`${dir}/${name}`);assert.equal(hash(data),sha,name);
 if(!name.endsWith('.png'))continue;
 assert.equal(data.readUInt32BE(0),0x89504e47);assert.equal(data[25],6,'RGBA transparency');
 const size=data.readUInt32BE(16);assert.equal(size,data.readUInt32BE(20));
 let offset=8,compressed=[];
 while(offset<data.length){const n=data.readUInt32BE(offset);if(data.toString('ascii',offset+4,offset+8)==='IDAT')compressed.push(data.subarray(offset+8,offset+8+n));offset+=n+12;}
 const raw=inflateSync(Buffer.concat(compressed));let clear=0,opaque=0;
 for(let y=0;y<size;y++)for(let x=0;x<size;x++){const a=raw[y*(size*4+1)+1+x*4+3];if(a===0)clear++;if(a>0)opaque++;}
 assert(clear>size*size*.2&&opaque>10,'Texture has transparent background and visible art');
 if(!name.startsWith('SoulAbsorption'))bytes+=size*size*4;
}
assert.equal(bytes,manifest.runtimeTextureBytesRGBA);assert.deepEqual(manifest.publishedAssetIds,[]);
const temp=mkdtempSync(join(tmpdir(),'ag67-art-'));
try {
 execFileSync(process.execPath,[resolve('scripts/build-ag67-art.mjs'),'--out',temp]);
 for(const name of readdirSync(dir))assert.equal(normal(readFileSync(join(temp,name)).toString('base64')),normal(readFileSync(join(dir,name)).toString('base64')),`Art generation drift ${name}`);
} finally {rmSync(temp,{recursive:true,force:true});}
const view=readFileSync('qa/ag67/View.luau','utf8');
assert(!/FireServer|InvokeServer|GetService\("Lighting"\)|rbxassetid:|TweenService|task\.spawn|task\.delay/.test(view));
assert.equal((view.match(/Heartbeat:Connect/g)||[]).length,1);assert.equal((view.match(/OnClientEvent:Connect/g)||[]).length,1);
assert(!readFileSync('default.project.json','utf8').includes('ag67'));
console.log('AG67 PASS: inherited source/assets/tests intact; original reproducible transparent art; isolated QA-only owner, no intents or Lighting writes.');
