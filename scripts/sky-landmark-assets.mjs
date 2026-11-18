// Mechanical alpha-preserving export of original ImageGen layers, not new artwork.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';
import {decode,downscale,encode} from './lunar-pixels.mjs';
const root=resolve(import.meta.dirname,'..'),dir=resolve(root,'assets/environment/sky-world-tree');
const hash=b=>createHash('sha256').update(b).digest('hex');
const spec={Tree:1024,Cloud:512,Glow:256};
const layers={};mkdirSync(resolve(dir,'textures'),{recursive:true});
function pad(image){
 const n=1664,rgba=Buffer.alloc(n*n*4),ox=(n-image.w)/2,oy=(n-image.h)/2;
 for(let y=0;y<image.h;y++)image.rgba.copy(rgba,((y+oy)*n+ox)*4,y*image.w*4,(y+1)*image.w*4);
 return {w:n,h:n,rgba};
}
for(const [name,n]of Object.entries(spec)){
 const source=decode(readFileSync(resolve(dir,'source',name+'.png')));
 const padded=pad(source),rgba=downscale(padded,n);layers[name]={w:n,h:n,rgba};
 writeFileSync(resolve(dir,'textures',name+'.png'),encode(n,rgba));
}
// The Minimal atlas is the same layers in the same order and fixed positions.
const n=512,base=Buffer.alloc(n*n*4);
for(const [name,opacity,shift]of [['Glow',.10,0],['Tree',1,0],['Cloud',.9,.06]]){
 const src=layers[name],rgba=src.w===n?src.rgba:src.w>n?downscale(src,n):null;
 for(let y=0;y<n;y++)for(let x=0;x<n;x++){
  const sy=y-Math.round(shift*n);if(sy<0||sy>=n)continue;
  const j=(sy*n+x)*4,i=(y*n+x)*4;
  const at=rgba?j:(Math.min(src.h-1,Math.floor(sy*src.h/n))*src.w+Math.min(src.w-1,Math.floor(x*src.w/n)))*4;
  const data=rgba||src.rgba,a=data[at+3]/255*opacity,b=base[i+3]/255,out=a+b*(1-a);
  for(let c=0;c<3;c++)base[i+c]=out?Math.round((data[at+c]*a+base[i+c]*b*(1-a))/out):0;
  base[i+3]=Math.round(out*255);
 }
}
writeFileSync(resolve(dir,'textures/Minimal.png'),encode(n,base));
const files=[];
for(const category of ['source','textures'])for(const name of category==='source'?['Concept','Tree','Cloud','Glow']:['Tree','Cloud','Glow','Minimal']){
 const rel=`assets/environment/sky-world-tree/${category}/${name}.png`,b=readFileSync(resolve(root,rel));
 const item={path:rel,bytes:b.length,sha256:hash(b),width:b.readUInt32BE(16),height:b.readUInt32BE(20)};
 if(name!=='Concept'){const d=decode(b);let transparent=0,soft=0,edgeMax=0;
  for(let y=0;y<d.h;y++)for(let x=0;x<d.w;x++){const a=d.rgba[(y*d.w+x)*4+3];if(!a)transparent++;else if(a<255)soft++;if(x===0||y===0||x===d.w-1||y===d.h-1)edgeMax=Math.max(edgeMax,a);}
  Object.assign(item,{transparentPixels:transparent,softPixels:soft,edgeAlphaMax:edgeMax});
 }files.push(item);
}
writeFileSync(resolve(dir,'manifest.json'),JSON.stringify({schema:1,task:'SKY-WORLD-TREE',base:'6540ba350cb933c598d5abe0eb22167878e55fc9',
 origin:'Original host-native OpenAI ImageGen artwork generated 2026-11-18 for this project. No third-party game imagery or paid-provider job.',
 rights:'Project-created generated artwork; use subject to applicable OpenAI terms. No claim of exclusive copyright or third-party CC0 licensing. Roblox upload NOT PERFORMED.',
 recipe:'Preserve masters; transparent 1664-square padding; premultiplied-alpha area resampling. Minimal compositing: Glow .10, Tree 1, Cloud .90 shifted +.06Y.',
 generation:{path:'assets/environment/sky-world-tree/generation.json',sha256:hash(readFileSync(resolve(dir,'generation.json')))},
 textureBytes:6553600,editableImages:4,files,qaCaptures:0,robloxUploads:0,productionIntegrated:false},null,2)+'\n');
console.log('Sky landmark: four original masters + four optimized layers, 6.25 MiB decoded RGBA');
