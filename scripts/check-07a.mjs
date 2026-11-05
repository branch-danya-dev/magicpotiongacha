// Independent native edge-pair test. Deliberately does NOT reuse generator rays.
import {readFileSync,readdirSync} from 'node:fs';
import {inflateSync} from 'node:zlib';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const dir='assets/environment/stability-sky/';
const sha=b=>createHash('sha256').update(b).digest('hex');
const receipt=JSON.parse(readFileSync(dir+'receipt.json'));
assert.equal(receipt.local_prefix,'rbxasset://m7task07a-v1/');
assert.equal(receipt.license,'CC0-1.0'); assert.equal(receipt.roblox_asset_ids,null);
for(const key of ['generator','art_generator']) assert.equal(sha(readFileSync(receipt[key],'utf8').replaceAll('\r\n','\n')),receipt[key+'_sha256']);
assert.deepEqual(readdirSync(dir).sort(),[...Object.keys(receipt.files),'receipt.json'].sort());
for(const [file,digest] of Object.entries(receipt.files)) assert.equal(sha(readFileSync(dir+file)),digest,file);
const names=['ft','bk','lf','rt','up','dn'];
function decode(path) {
  const b=readFileSync(path); assert.equal(b.readUInt32BE(16),256); assert.equal(b.readUInt32BE(20),256);
  assert.equal(b[24],8); assert.equal(b[25],6); assert.equal(b[28],0);
  const chunks=[]; for(let p=8;p<b.length;) {const n=b.readUInt32BE(p); if(b.toString('ascii',p+4,p+8)==='IDAT') chunks.push(b.subarray(p+8,p+8+n)); p+=12+n;}
  const raw=inflateSync(Buffer.concat(chunks)); assert.equal(raw.length,256*1025);
  return Array.from({length:256},(_,y)=>{assert.equal(raw[y*1025],0); return Array.from({length:256},(_,x)=>{
    const c=[...raw.subarray(y*1025+1+x*4,y*1025+5+x*4)]; assert.equal(c[3],255); return c;
  });});
}
const edge=(f,s,i)=>s==='L'?f[i][0]:s==='R'?f[i][255]:s==='T'?f[0][i]:f[255][i];
// Observed from installed Roblox sky512 DDS adjacency, including polar rotations.
const joins=[['ft','L','rt','R',false],['ft','R','lf','L',false],['bk','L','lf','R',false],['bk','R','rt','L',false],
  ['ft','T','up','R',true],['ft','B','dn','R',false],['bk','T','up','L',false],['bk','B','dn','L',true],
  ['lf','T','up','T',true],['lf','B','dn','B',true],['rt','T','up','B',false],['rt','B','dn','T',false]];
function errors(folder) {
  const faces=Object.fromEntries(names.map(n=>[n,decode(folder+n+'.png')]));
  return joins.map(([a,as,b,bs,reverse])=>{
    let worst=0;
    for(let i=0;i<256;i++) {
      const ca=edge(faces[a],as,i), cb=edge(faces[b],bs,reverse?255-i:i);
      for(let c=0;c<3;c++) worst=Math.max(worst,Math.abs(ca[c]-cb[c]));
    }
    return {join:a+as+'='+b+bs+(reverse?' reversed':''),maxRGBError:worst};
  });
}
const before=errors('assets/environment/fantasy/'),after=errors(dir);
assert(before.some(e=>e.maxRGBError>30),'Negative control failed: task06 orientation should expose the defect');
for(const e of after) assert.equal(e.maxRGBError,0,e.join);
const get=p=>JSON.parse(readFileSync('assets/environment/'+p+'/receipt.json'));
const old=get('atmosphere'),nature=get('megakit'),polish=get('polish');
const resident=nature.texture_rgba8_mips_bytes+old.rgba8_mips_bytes-6*256*256*4*4/3+receipt.rgba8_mips_bytes+polish.rgba8_mips_bytes;
assert(resident<=32*1024*1024); assert.equal(receipt.rgba8_mips_bytes,6*256*256*4*4/3);
console.log('07A sky native topology: '+JSON.stringify({before,after,runtimeTextureMiB:resident/1024**2,nativeRender:'NOT_VERIFIED'}));
