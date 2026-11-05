// Independent checks of delivered runtime texture bytes; no screenshots/rendering.
import {readFileSync,readdirSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {inflateSync} from 'node:zlib';
import assert from 'node:assert/strict';
const dir='assets/environment/fantasy/';
const receipt=JSON.parse(readFileSync(dir+'receipt.json','utf8'));
const hash=b=>createHash('sha256').update(b).digest('hex');
assert.equal(receipt.license,'CC0-1.0'); assert.equal(receipt.roblox_asset_ids,null);
assert.equal(receipt.local_prefix,'rbxasset://m7task06-v1/');
assert.equal(hash(readFileSync(receipt.generator,'utf8').replaceAll('\r\n','\n')),receipt.generator_sha256);
assert.deepEqual(readdirSync(dir).sort(),[...Object.keys(receipt.files),'receipt.json'].sort());
for(const [file,digest] of Object.entries(receipt.files)) assert.equal(hash(readFileSync(dir+file)),digest,file);
const sides=['ft','bk','lf','rt','up','dn']; const edges=new Map(); let shared=0,minimum=255,maximum=0;
for(const face of sides) {
  const b=readFileSync(dir+face+'.png'); assert.equal(b.subarray(0,8).toString('hex'),'89504e470d0a1a0a');
  assert.equal(b.readUInt32BE(16),256); assert.equal(b.readUInt32BE(20),256);
  assert.equal(b[24],8); assert.equal(b[25],6); assert.equal(b[28],0);
  const chunks=[]; for(let p=8;p<b.length;) { const n=b.readUInt32BE(p); if(b.toString('ascii',p+4,p+8)==='IDAT') chunks.push(b.subarray(p+8,p+8+n)); p+=12+n; }
  const data=inflateSync(Buffer.concat(chunks)); assert.equal(data.length,256*1025);
  const pixel=(x,y)=>data.subarray(y*1025+1+x*4,y*1025+5+x*4);
  for(let y=0;y<256;y++) {
    assert.equal(data[y*1025],0);
    for(let x=0;x<256;x++) {
      const c=pixel(x,y); assert.equal(c[3],255); minimum=Math.min(minimum,c[0]); maximum=Math.max(maximum,c[0]);
      if(face==='up'||face==='dn') { assert.deepEqual(c,pixel(255-y,x)); assert.deepEqual(c,pixel(255-x,y)); }
      if(x!==0&&y!==0&&x!==255&&y!==255) continue;
      const u=x*2-255,v=y*2-255;
      const ray=({ft:[u,-v,-255],bk:[-u,-v,255],lf:[-255,-v,-u],rt:[255,-v,u],up:[v,255,-u],dn:[-v,-255,-u]})[face].join(',');
      const value=c.toString('hex');
      if(edges.has(ray)) { assert.equal(value,edges.get(ray),`seam ${face} ${x} ${y}`); shared++; } else edges.set(ray,value);
    }
  }
}
assert.equal(edges.size,3056); assert.equal(shared,3064); assert.equal(receipt.max_edge_rgba_error,0);
assert(maximum-minimum>70,'Sky lacks authored tonal range');
assert(new Set(sides.slice(0,4).map(f=>receipt.files[f+'.png'])).size===4,'Directional cloud banks missing');
assert.equal(receipt.rgba8_mips_bytes,6*256*256*4*4/3);
const bark=JSON.parse(readFileSync('assets/environment/megakit/receipt.json'));
const old=JSON.parse(readFileSync('assets/environment/atmosphere/receipt.json'));
const polish=JSON.parse(readFileSync('assets/environment/polish/receipt.json'));
const resident=bark.texture_rgba8_mips_bytes+old.rgba8_mips_bytes-6*256*256*4*4/3+receipt.rgba8_mips_bytes+polish.rgba8_mips_bytes;
assert(resident<=32*1024*1024,'Current runtime texture memory exceeds inherited cap');
console.log(`Historical 19e art integrity PASS: six decoded faces and original assumed topology; native topology is tested separately by check-07a.mjs; textures ${(resident/1024**2).toFixed(3)} MiB`);
