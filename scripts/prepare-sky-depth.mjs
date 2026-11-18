// Offline masks and swept branch geometry. Original art is never overwritten.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {decode,encode} from './lunar-pixels.mjs';
import {fileURLToPath} from 'node:url';
const dir='assets/environment/sky-world-tree/r4';
export const hash=b=>createHash('sha256').update(b).digest('hex');
export function polygon(x,y,points,feather){
 let inside=false,d=Infinity;
 for(let i=0,j=points.length-1;i<points.length;j=i++){
  const [ax,ay]=points[j],[bx,by]=points[i],dx=bx-ax,dy=by-ay;
  if((ay>y)!==(by>y)&&x<(bx-ax)*(y-ay)/(by-ay)+ax)inside=!inside;
  const t=Math.max(0,Math.min(1,((x-ax)*dx+(y-ay)*dy)/(dx*dx+dy*dy)));
  d=Math.min(d,Math.hypot(x-ax-t*dx,y-ay-t*dy));
 }
 const t=Math.max(0,Math.min(1,.5+(inside?d:-d)/(2*feather)));
 return t*t*(3-2*t);
}
const sub=(a,b)=>a.map((v,i)=>v-b[i]),cross=(a,b)=>[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];
const unit=a=>{const n=Math.hypot(...a);return a.map(v=>v/n);};
function tube(name,points,sides=10){
 const vertices=[],normals=[],triangles=[];
 for(let k=0;k<points.length;k++){
  const tangent=unit(sub(points[Math.min(k+1,points.length-1)].slice(0,3),points[Math.max(0,k-1)].slice(0,3)));
  const u=unit(cross(tangent,Math.abs(tangent[2])<.9?[0,0,1]:[0,1,0])),v=cross(tangent,u);
  for(let j=0;j<sides;j++){
   const a=j*2*Math.PI/sides,n=u.map((q,i)=>q*Math.cos(a)+v[i]*Math.sin(a));
   vertices.push(n.map((q,i)=>+(points[k][i]+q*points[k][3]).toFixed(5)));normals.push(n);
  }
 }
 for(let k=0;k<points.length-1;k++)for(let j=0;j<sides;j++){
  const a=k*sides+j,b=k*sides+(j+1)%sides,c=a+sides,d=b+sides;
  triangles.push([a,b,c],[b,d,c]);
 }
 // Small closed end caps; roots deliberately overlap inside the parent branch.
 for(const k of [0,points.length-1])for(let j=1;j<sides-1;j++)triangles.push(k===0?[0,j+1,j]:[k*sides,k*sides+j,k*sides+j+1]);
 const min=[0,1,2].map(i=>Math.min(...vertices.map(v=>v[i]))),max=[0,1,2].map(i=>Math.max(...vertices.map(v=>v[i]))),center=min.map((v,i)=>(v+max[i])/2);
 return {name,center,vertices:vertices.map(p=>sub(p,center)),normals,triangles,bounds:max.map((v,i)=>v-min[i])};
}
export function generate(){
 const recipe=JSON.parse(readFileSync(`${dir}/recipe.json`)),raw=readFileSync(recipe.source),source=decode(raw),c=recipe.crop;
 const rgba=Buffer.alloc(1024*1024*4),w=1008,h=240,stats=[0,0,0,0];
 for(let y=0;y<h;y++)for(let x=0;x<w;x++){
  const u=(x+.5)/w,v=(y+.5)/h,sx=Math.min(source.w-1,Math.floor(c.x+u*c.width)),sy=Math.min(source.h-1,Math.floor(c.y+v*c.height));
  const p=(sy*source.w+sx)*4;
  const f=Math.max(...recipe.front.map(poly=>polygon(u,v,poly,recipe.feather)));
  const m=Math.max(...recipe.middle.map(poly=>polygon(u,v,poly,recipe.feather)));
  const cut=polygon(u,v,recipe.trunkCut,.016);
  const a=source.rgba[p+3]/255*(1-cut),front=a*f,remaining=(a-front)/Math.max(1e-8,1-front),mid=remaining*m;
  const back=(remaining-mid)/Math.max(1e-8,1-mid);
  // Local accents only on the foreground foliage's upper-facing painted ridges.
  const luma=(source.rgba[p]*.21+source.rgba[p+1]*.72+source.rgba[p+2]*.07)/255;
  const accent=front*Math.max(0,(luma-.45)/.55)*.8;
  for(const [row,alpha]of [back,mid,front,accent].entries()){
   const q=((row*256+8+y)*1024+8+x)*4;source.rgba.copy(rgba,q,p,p+3);rgba[q+3]=Math.round(alpha*255);if(rgba[q+3]>32)stats[row]++;
  }
 }
 const branches=[
  tube('Heartwood',[[70,-1370,60,180],[20,-1160,60,220],[110,-960,40,205],[240,-740,0,170],[380,-530,-30,135],[490,-340,-60,80]]),
  tube('RightBough',[[280,-660,-20,155],[630,-430,-50,130],[1010,-290,-120,100],[1370,-30,-190,70],[1470,250,-260,20]]),
  tube('LeftBough',[[170,-960,45,175],[-150,-740,120,145],[-520,-610,170,105],[-900,-590,210,75],[-1280,-770,200,28]]),
  tube('WestCrown', [[-900,-590,210,80],[-1270,-520,230,65],[-1650,-360,290,48],[-2030,-320,320,14]]),
  tube('UpperFork',[[380,-530,-30,100],[150,-260,-280,75],[-100,-80,-410,50],[-280,200,-510,16]]),
  tube('EastCrown',[[1010,-290,-120,90],[1320,-450,-140,68],[1620,-390,-200,48],[1900,-220,-330,14]])
 ];
 const atlas=encode(1024,rgba),geometry=Buffer.from(JSON.stringify({branches})+'\n');
 const files=[{path:`${dir}/CanopyAtlas.png`,sha256:hash(atlas),bytes:atlas.length},{path:`${dir}/trunk.json`,sha256:hash(geometry),bytes:geometry.length}];
 const manifest={task:'SKY-WORLD-TREE-R4',base:'c1689262ae73a06426a7308b02235b501cf6c167',source:recipe.source,sourceSHA256:hash(raw),recipeSHA256:hash(readFileSync(`${dir}/recipe.json`)),rights:'Derived masks of original project artwork; inherited r2 manifest provenance/terms. Original authored swept geometry, no external models.',recipe:'scripts/prepare-sky-depth.mjs',atlas:{size:1024,slots:['rear','middle','front','accent'],rects:[0,1,2,3].map(i=>({x:8,y:i*256+8,width:w,height:h})),supportPixels:stats},textureBytes:rgba.length,images:1,meshes:branches.length,vertices:branches.reduce((s,b)=>s+b.vertices.length,0),triangles:branches.reduce((s,b)=>s+b.triangles.length,0),geometryPayloadBytes:geometry.length,uploads:0,paidJobs:0,files};
 return {atlas,geometry,manifest};
}
if(process.argv[1]===fileURLToPath(import.meta.url)){
 const out=generate();mkdirSync(dir,{recursive:true});writeFileSync(`${dir}/CanopyAtlas.png`,out.atlas);writeFileSync(`${dir}/trunk.json`,out.geometry);writeFileSync(`${dir}/manifest.json`,JSON.stringify(out.manifest,null,2)+'\n');console.log(JSON.stringify(out.manifest,null,2));
}
