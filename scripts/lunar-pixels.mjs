// Dependency-free PNG validation/downscaling/packaging. No recoloring or generated art.
import {inflateSync,deflateSync} from 'node:zlib';
import assert from 'node:assert/strict';
export const crc=bytes=>{let c=0xffffffff;for(const b of bytes){c^=b;for(let i=0;i<8;i++)c=(c>>>1)^((c&1)?0xedb88320:0);}return(c^0xffffffff)>>>0;};
export function decode(data){
 assert(data.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10])));
 let p=8,w,h,idat=[],ended=false;
 while(p<data.length){const n=data.readUInt32BE(p),type=data.toString('ascii',p+4,p+8),b=data.subarray(p+8,p+8+n);
  assert.equal(crc(data.subarray(p+4,p+8+n)),data.readUInt32BE(p+8+n));p+=n+12;
  if(type==='IHDR'){w=b.readUInt32BE(0);h=b.readUInt32BE(4);assert.equal(b[8],8);assert.equal(b[9],6);assert.equal(b[12],0);}
  if(type==='IDAT')idat.push(b);if(type==='IEND'){ended=true;break;}
 }
 assert(ended&&p===data.length&&w>0&&w<=4096&&h>0&&h<=4096);
 const stride=w*4,raw=inflateSync(Buffer.concat(idat),{maxOutputLength:(stride+1)*h}),rgba=Buffer.alloc(stride*h);
 assert.equal(raw.length,(stride+1)*h);
 const paeth=(a,b,c)=>{const v=a+b-c,aa=Math.abs(v-a),bb=Math.abs(v-b),cc=Math.abs(v-c);return aa<=bb&&aa<=cc?a:bb<=cc?b:c;};
 for(let y=0;y<h;y++){const f=raw[y*(stride+1)];assert(f<=4);for(let x=0;x<stride;x++){
  const i=y*stride+x,a=x>=4?rgba[i-4]:0,b=y?rgba[i-stride]:0,c=y&&x>=4?rgba[i-stride-4]:0;
  rgba[i]=(raw[y*(stride+1)+1+x]+[0,a,b,Math.floor((a+b)/2),paeth(a,b,c)][f])&255;
 }}return {w,h,rgba};
}
export function downscale(image,n){
 const {w,h,rgba}=image;assert(w===h&&n<=w);const out=Buffer.alloc(n*n*4),scale=w/n;
 // Area average in premultiplied alpha: preserves transparent fringe colors correctly.
 for(let y=0;y<n;y++)for(let x=0;x<n;x++){
  let a=0,r=0,g=0,b=0;
  for(let sy=Math.floor(y*scale);sy<Math.ceil((y+1)*scale);sy++)for(let sx=Math.floor(x*scale);sx<Math.ceil((x+1)*scale);sx++){
   const weight=(Math.min(sy+1,(y+1)*scale)-Math.max(sy,y*scale))*(Math.min(sx+1,(x+1)*scale)-Math.max(sx,x*scale));
   const i=(sy*w+sx)*4,alpha=rgba[i+3]*weight;a+=alpha;r+=rgba[i]*alpha;g+=rgba[i+1]*alpha;b+=rgba[i+2]*alpha;
  }
  const i=(y*n+x)*4;out[i]=a?Math.round(r/a):0;out[i+1]=a?Math.round(g/a):0;out[i+2]=a?Math.round(b/a):0;out[i+3]=Math.round(a/(scale*scale));
 }return out;
}
export function encode(n,rgba){
 const raw=Buffer.alloc(n*(n*4+1));for(let y=0;y<n;y++)rgba.copy(raw,y*(n*4+1)+1,y*n*4,(y+1)*n*4);
 const header=Buffer.alloc(13);header.writeUInt32BE(n);header.writeUInt32BE(n,4);header[8]=8;header[9]=6;
 const chunk=(type,data)=>{const t=Buffer.from(type),len=Buffer.alloc(4),c=Buffer.alloc(4);len.writeUInt32BE(data.length);c.writeUInt32BE(crc(Buffer.concat([t,data])));return Buffer.concat([len,t,data,c]);};
 return Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',header),chunk('IDAT',deflateSync(raw,{level:9})),chunk('IEND',Buffer.alloc(0))]);
}
