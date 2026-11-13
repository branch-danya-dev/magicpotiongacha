// Original AG-67B art, derived from the checked-in editable Stage A vocabulary.
// No providers, downloads, fonts or external libraries. Does not upload anything.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {deflateSync,inflateSync} from 'node:zlib';
import {createHash} from 'node:crypto';
const out=resolve(process.argv[2]==='--out'?process.argv[3]:'assets/vfx/ag67b');
mkdirSync(out,{recursive:true});
const source=JSON.parse(readFileSync('assets/vfx/ag67/design.json'));
const hash=b=>createHash('sha256').update(b).digest('hex');
function crc(bytes){let c=0xffffffff;for(const b of bytes){c^=b;for(let i=0;i<8;i++)c=(c>>>1)^((c&1)?0xedb88320:0);}return(c^0xffffffff)>>>0;}
function encode(w,h,rgba){
 const raw=Buffer.alloc(h*(w*4+1));for(let y=0;y<h;y++)rgba.copy(raw,y*(w*4+1)+1,y*w*4,(y+1)*w*4);
 const header=Buffer.alloc(13);header.writeUInt32BE(w);header.writeUInt32BE(h,4);header[8]=8;header[9]=6;
 const chunk=(type,data)=>{const t=Buffer.from(type),n=Buffer.alloc(4),c=Buffer.alloc(4);n.writeUInt32BE(data.length);c.writeUInt32BE(crc(Buffer.concat([t,data])));return Buffer.concat([n,t,data,c]);};
 return Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',header),chunk('IDAT',deflateSync(raw,{level:9})),chunk('IEND',Buffer.alloc(0))]);
}
function decode(file){
 const data=readFileSync(file),w=data.readUInt32BE(16),h=data.readUInt32BE(20);let p=8,chunks=[];
 while(p<data.length){const n=data.readUInt32BE(p);if(data.toString('ascii',p+4,p+8)==='IDAT')chunks.push(data.subarray(p+8,p+8+n));p+=n+12;}
 const raw=inflateSync(Buffer.concat(chunks)),rgba=Buffer.alloc(w*h*4);
 for(let y=0;y<h;y++){if(raw[y*(w*4+1)]!==0)throw new Error('Authored filter-0 PNG required');raw.copy(rgba,y*w*4,y*(w*4+1)+1,(y+1)*(w*4+1));}
 return {w,h,rgba};
}
const clamp=x=>Math.max(0,Math.min(1,x));
function strokes(paths,size){
 const pixels=Buffer.alloc(size*size*4),scale=size/1024;
 for(const [extra,opacity,color] of [[12,.30,[33,39,83]],[5,.14,[255,255,255]],[0,1,[255,255,255]]])for(const path of paths)for(let i=1;i<path.points.length;i++){
  const [ax,ay]=path.points[i-1].map(v=>v*scale),[bx,by]=path.points[i].map(v=>v*scale),dx=bx-ax,dy=by-ay,r=(path.width+extra)*scale/2;
  for(let y=Math.max(0,Math.floor(Math.min(ay,by)-r-1));y<Math.min(size,Math.ceil(Math.max(ay,by)+r+1));y++)for(let x=Math.max(0,Math.floor(Math.min(ax,bx)-r-1));x<Math.min(size,Math.ceil(Math.max(ax,bx)+r+1));x++){
   const t=clamp(((x+.5-ax)*dx+(y+.5-ay)*dy)/(dx*dx+dy*dy||1));
   const a=clamp(r+.5-Math.hypot(x+.5-ax-t*dx,y+.5-ay-t*dy))*opacity;if(!a)continue;
   const n=(y*size+x)*4,old=pixels[n+3]/255,alpha=a+old*(1-a);
   for(let j=0;j<3;j++)pixels[n+j]=Math.round((color[j]*a+pixels[n+j]*old*(1-a))/alpha);pixels[n+3]=Math.round(alpha*255);
  }
 }
 return pixels;
}
function place(dst,width,src,size,x,y){for(let row=0;row<size;row++)src.copy(dst,((y+row)*width+x)*4,row*size*4,(row+1)*size*4);}
const sectorCount=source.paths.filter(p=>p.group==='outer').length/6;
const strengthen=paths=>paths.map(p=>({...p,width:Math.max(6,p.width*2.2)}));
const sector=strengthen(source.paths.slice(0,sectorCount));
const inner=strengthen(source.paths.filter(p=>p.group==='inner'));
const channels=strengthen(source.paths.filter(p=>p.group==='channels'));
const atlas=Buffer.alloc(1024*1024*4);
place(atlas,1024,strokes(sector,512),512,0,0);
place(atlas,1024,strokes(inner,512),512,512,0);
place(atlas,1024,strokes(channels,512),512,0,512);
for(let i=0;i<4;i++){
 const glyph=source.glyphs[i].map(points=>({points:points.map(([x,y])=>[512+x*8,512+y*8]),width:58}));
 place(atlas,1024,strokes(glyph,256),256,512+(i%2)*256,512+Math.floor(i/2)*256);
}
const sigilPaths=strengthen(source.paths);
const svg=sigilPaths.map(p=>`<polyline points="${p.points.map(v=>v.map(x=>x.toFixed(2)).join(',')).join(' ')}" fill="none" stroke="${p.group==='inner'?'#b49aff':'#8de8ff'}" stroke-width="${p.width}" stroke-linejoin="round" stroke-linecap="round"/>`).join('\n');
writeFileSync(resolve(out,'SoulAbsorptionSigil.svg'),`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024"><title>AG67B Soul Absorption — original Receive / Conduct / Release / Bind grammar</title>${svg}</svg>\n`);
const paper=decode('assets/vfx/ag67/page.png');
const dist=new Float64Array(256*256).fill(999);
for(let y=0;y<256;y++)for(let x=0;x<256;x++){const n=y*256+x;if(!paper.rgba[n*4+3])dist[n]=0;else dist[n]=Math.min(dist[n],x?dist[n-1]+1:0,y?dist[n-256]+1:0);}
for(let y=255;y>=0;y--)for(let x=255;x>=0;x--){const n=y*256+x;dist[n]=Math.min(dist[n],x<255?dist[n+1]+1:0,y<255?dist[n+256]+1:0);}
const pages=Buffer.alloc(1024*1024*4),pageStats=[];
for(let frame=0;frame<8;frame++){
 const base=Buffer.alloc(256*256*4),edge=Buffer.alloc(256*256*4),progress=frame/7;let visible=0;
 for(let y=0;y<256;y++)for(let x=0;x<256;x++){
  const i=y*256+x,n=i*4;if(!paper.rgba[n+3])continue;
  const noise=.5+.22*Math.sin(x*.17+y*.09)+.15*Math.sin(y*.29-x*.13)+.13*Math.sin(x*.51+y*.43);
  // Advancing irregular perimeter plus internal tear fronts, monotone per pixel.
  const hole1=Math.hypot((x-100)*.9,(y-152)*.8),hole2=Math.hypot(x-175,y-97);
  const front=Math.min(dist[i]-progress*(18+noise*33),hole1+22-progress*65,hole2+30-progress*63);
  const a=frame===0?1:clamp(front);if(a<=0)continue;visible++;
  const char=clamp(progress*.9+(1-clamp(front/10))*.5);
  for(let j=0;j<3;j++)base[n+j]=Math.round(paper.rgba[n+j]*(1-char)+[38,25,52][j]*char);
  base[n+3]=Math.round(a*255);
  if(frame>0){const intensity=clamp(1-front/6)*a,hot=clamp(1-front/1.5);const violet=(x+y)%67<16;
   const warm=violet?[192,91,255]:[255,116,22];for(let j=0;j<3;j++)edge[n+j]=Math.round(warm[j]*(1-hot)+255*hot);edge[n+3]=Math.round(intensity*255);
  }
 }
 pageStats.push(visible);
 place(pages,1024,base,256,(frame%4)*256,Math.floor(frame/4)*256);
 place(pages,1024,edge,256,(frame%4)*256,512+Math.floor(frame/4)*256);
}
const soul=Buffer.alloc(256*256*4);
for(let y=0;y<256;y++)for(let x=0;x<256;x++){
 const u=x/255,v=y/255,curve=.5+Math.sin(u*8)*.095*(1-u),width=.018+.085*Math.sin(Math.PI*u);
 const ribbon=Math.exp(-Math.pow((v-curve)/width,2))*Math.pow(Math.sin(Math.PI*u),1.2);
 const mist=Math.exp(-Math.pow((v-curve)/(.10+width),2))*.18*Math.sin(Math.PI*u);
 const n=(y*256+x)*4;soul[n]=255;soul[n+1]=255;soul[n+2]=255;soul[n+3]=Math.round(clamp(ribbon+mist)*255);
}
const images=[['AG67B_SigilAtlas.png',1024,1024,atlas],['AG67B_PageBurnAtlas.png',1024,1024,pages],['AG67B_SoulWisp.png',256,256,soul]];
// Review montage composites RGBA correctly; it is not a runtime/upload texture.
const review=Buffer.alloc(1536*1024*4);
for(let i=0;i<1536*1024;i++){review[i*4]=18;review[i*4+1]=24;review[i*4+2]=39;review[i*4+3]=255;}
function reviewTile(pixels,w,h,dx,dy,scale){for(let y=0;y<h*scale;y++)for(let x=0;x<w*scale;x++){
 const i=(Math.floor(y/scale)*w+Math.floor(x/scale))*4,n=((dy+y)*1536+dx+x)*4,a=pixels[i+3]/255;
 for(let k=0;k<3;k++)review[n+k]=Math.round(pixels[i+k]*a+review[n+k]*(1-a));
}}
reviewTile(atlas,1024,1024,0,0,.5);reviewTile(pages,1024,1024,512,0,1);reviewTile(soul,256,256,128,640,1);
writeFileSync(resolve(out,'review.png'),encode(1536,1024,review));
const files=images.map(([name,w,h,data])=>{const png=encode(w,h,data);writeFileSync(resolve(out,name),png);return {name,width:w,height:h,bytes:png.length,sha256:hash(png),type:'Image',assetName:name.replace('.png',''),assetId:null};});
const manifest={task:'AG-67B',status:'PREPARED — OWNER UPLOAD APPROVAL REQUIRED',source:'scripts/build-ag67b-art.mjs + original assets/vfx/ag67/design.json and page.png',license:'Original project-authored art; no external licensed or paid content',sourceSha256:hash(readFileSync('assets/vfx/ag67/design.json')),creator:{type:'Group',name:'addout studio',id:925845207},universeId:10776120489,placeId:125724638469407,visibility:'Restricted; never Open Use or Creator Store',purpose:'Private game VFX textures for ordinary Rojo/Studio build',releaseEnabled:false,decodedRgbaBytes:1024*1024*8+256*256*4,pageVisiblePixels:pageStats,files};
writeFileSync(resolve(out,'upload-manifest.json'),JSON.stringify(manifest,null,2)+'\n');
console.log(JSON.stringify({prepared:files,decodedMiB:manifest.decodedRgbaBytes/1048576,pageVisiblePixels:pageStats},null,2));
