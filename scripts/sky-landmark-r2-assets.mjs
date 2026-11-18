// Export preserved R2 artwork; no artistic pixel changes, only alpha-aware UV crops.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';
import {decode,downscale,encode} from './lunar-pixels.mjs';
const root=resolve(import.meta.dirname,'..'),prefix='assets/environment/sky-world-tree/',dir=resolve(root,prefix+'r2');
const hash=b=>createHash('sha256').update(b).digest('hex');
mkdirSync(resolve(dir,'textures'),{recursive:true});
const src=decode(readFileSync(resolve(dir,'source/Tree.png'))),n=1664,padded=Buffer.alloc(n*n*4);
const ox=(n-src.w)/2,oy=(n-src.h)/2;
if(!Number.isInteger(ox)||!Number.isInteger(oy)||ox<0||oy<0)throw Error('Master size changed');
for(let y=0;y<src.h;y++)src.rgba.copy(padded,((y+oy)*n+ox)*4,y*src.w*4,(y+1)*src.w*4);
for(const [name,size]of [['Tree',1024],['Minimal',512]])writeFileSync(resolve(dir,'textures/'+name+'.png'),encode(size,downscale({w:n,h:n,rgba:padded},size)));
for(const name of ['Cloud','Glow'])writeFileSync(resolve(dir,'textures/'+name+'.png'),readFileSync(resolve(root,prefix+'textures/'+name+'.png')));
function bounds(d,threshold){let x=d.w,y=d.h,r=0,b=0;for(let v=0;v<d.h;v++)for(let u=0;u<d.w;u++)if(d.rgba[(v*d.w+u)*4+3]>=threshold){x=Math.min(x,u);y=Math.min(y,v);r=Math.max(r,u);b=Math.max(b,v)}return {x,y,width:r-x+1,height:b-y+1};}
const files=[],layers={};let memory=0;
for(const name of ['Tree','Cloud','Glow','Minimal']){
 const path=prefix+'r2/textures/'+name+'.png',bytes=readFileSync(resolve(root,path)),d=decode(bytes);
 const support=bounds(d,3),visible=bounds(d,32),margin=Math.max(4,Math.round(d.w/128));
 const x=Math.max(0,support.x-margin),y=Math.max(0,support.y-margin),right=Math.min(d.w,support.x+support.width+margin),bottom=Math.min(d.h,support.y+support.height+margin);
 const crop={x,y,width:right-x,height:bottom-y};let edgeAlpha=0;
 for(let v=y;v<bottom;v++)for(let u=x;u<right;u++)if(u===x||v===y||u===right-1||v===bottom-1)edgeAlpha=Math.max(edgeAlpha,d.rgba[(v*d.w+u)*4+3]);
 layers[name]={size:d.w,crop,visible,support,cropEdgeAlphaMax:edgeAlpha};memory+=d.rgba.length;
 files.push({path,sha256:hash(bytes),bytes:bytes.length});
}
for(const path of [prefix+'r2/source/Tree.png',prefix+'r2/generation.json',prefix+'source/Tree.png',prefix+'source/Cloud.png',prefix+'source/Glow.png']){const bytes=readFileSync(resolve(root,path));files.push({path,sha256:hash(bytes),bytes:bytes.length});}
writeFileSync(resolve(dir,'manifest.json'),JSON.stringify({schema:2,task:'SKY-WORLD-TREE-R2',revisionBase:'2a047c401529632150c902b9d7f6ef188dd88ec4',
 origin:'Original project artwork; built-in image_gen limited tree contrast edit. Original cloud and glow retained byte-for-byte.',
 rights:'Generated project artwork subject to applicable OpenAI terms; no exclusive copyright or CC0 claim.',
 recipe:'1664-square transparent padding, alpha-preserving area downsample; crop from alpha>=3 plus margin, reported visible bounds alpha>=32. Runtime crops only; no per-frame writes.',
 textureBytes:memory,editableImages:4,layers,files,qaCaptures:0,robloxUploads:0,paidThirdPartyJobs:0},null,2)+'\n');
console.log(JSON.stringify({textureBytes:memory,layers},null,2));
