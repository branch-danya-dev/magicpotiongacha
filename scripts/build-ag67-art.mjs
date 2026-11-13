// Original AG67 vector artwork. No provider, stock symbols, fonts or dependencies.
// SVG and antialiased RGBA PNG share the same explicitly authored paths.
import {mkdirSync,writeFileSync,readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {deflateSync} from 'node:zlib';
import {createHash} from 'node:crypto';
const dir=resolve(process.argv[2]==='--out'?process.argv[3]:'assets/vfx/ag67'); mkdirSync(dir,{recursive:true});
const TAU=Math.PI*2, paths=[];
const stroke=(points,width=4,group='outer')=>({points,width,group});
const arc=(r,a,b,n=48)=>Array.from({length:n+1},(_,i)=>[512+r*Math.cos(a+(b-a)*i/n),512+r*Math.sin(a+(b-a)*i/n)]);
const glyphs=[
 // Receive: open vessel, inward branches, isolated retained seed.
 [[[-26,-30],[-26,5],[0,27],[26,5],[26,-30]],[[-40,-7],[-17,-7],[0,9],[17,-7],[40,-7]],[[0,-36],[0,-15]],[[0,37],[0,44]]],
 // Conduct: offset spine with two oriented gates, deliberately not a letter.
 [[[-18,-40],[-18,-12],[12,5],[12,38]],[[12,-30],[32,-10],[12,10],[-8,-10]],[[12,38],[-10,24],[-29,24]]],
 // Release: split seed, open wing and single descending root.
 [[[-35,0],[-8,-28],[18,-28],[35,-8]],[[35,0],[8,28],[-18,28],[-35,8]],[[0,-14],[12,0],[0,14],[-12,0],[0,-14]],[[0,28],[0,44]]],
 // Bind: an asymmetric cup and a crossing flow, no closed star polygon.
 [[[-28,-35],[-28,16],[0,35],[28,16],[28,-5]],[[0,35],[0,-32],[20,-17]],[[0,-4],[-40,-4]],[[28,16],[40,24]]],
];
function glyph(index,cx,cy,scale=1,angle=0,group='outer') {
 return glyphs[index].map(p=>stroke(p.map(([x,y])=>[cx+scale*(x*Math.cos(angle)-y*Math.sin(angle)),cy+scale*(x*Math.sin(angle)+y*Math.cos(angle))]),6*scale,group));
}
const sector=[];
sector.push(stroke(arc(444,-.40,.40),5),stroke(arc(410,-.36,.36),2));
for(const a of [-.40,.40]) sector.push(stroke([[512+395*Math.cos(a),512+395*Math.sin(a)],[512+458*Math.cos(a),512+458*Math.sin(a)]],5));
sector.push(...glyph(0,512+355,512,.60,Math.PI/2));
for(let i=0;i<6;i++) {
 const a=i*TAU/6;
 for(const path of sector) paths.push({...path,points:path.points.map(([x,y])=>[512+(x-512)*Math.cos(a)-(y-512)*Math.sin(a),512+(x-512)*Math.sin(a)+(y-512)*Math.cos(a)])});
}
const inner=[stroke(arc(273,.20,3.65),4,'inner'),stroke(arc(251,3.9,6.15),3,'inner')];
for(let k=0;k<3;k++) {
 const points=[];
 for(let i=0;i<=70;i++) {const t=i/70,a=k*TAU/3+t*2.95,r=220*(1-t)+43;points.push([512+Math.cos(a)*r,512+Math.sin(a)*r]);}
 inner.push(stroke(points,k===0?6:3,'inner'));
}
inner.push(...glyph(3,512,512,1.15,.2,'inner'));
paths.push(...inner);
const channels=[];
for(let k=0;k<3;k++) {
 const a=k*TAU/3+.35;
 channels.push(stroke([340,298,284].map(r=>[512+Math.cos(a)*r,512+Math.sin(a)*r]),5,'channels'));
 channels.push(stroke([[-8,-8],[0,0],[8,-8]].map(([x,y])=>[512+Math.cos(a)*306-Math.sin(a)*x+Math.cos(a)*y,512+Math.sin(a)*306+Math.cos(a)*x+Math.sin(a)*y]),4,'channels'));
}
paths.push(...channels);
function svg(name,entries,polygon=null,size=1024) {
 const lines=entries.map(p=>`<polyline points="${p.points.map(v=>v.map(x=>x.toFixed(2)).join(',')).join(' ')}" fill="none" stroke="${p.group==='inner'?'#b49aff':'#8de8ff'}" stroke-width="${p.width}" stroke-linecap="round" stroke-linejoin="round"/>`).join('\n');
 writeFileSync(resolve(dir,name+'.svg'),`<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 1024 1024"><title>AG67 ${name} — original Soul Absorption grammar</title><desc>Receive, Conduct, Release, Bind. Project-authored paths. No stock glyphs or pentagram.</desc>${polygon?`<polygon points="${polygon.map(p=>p.join(',')).join(' ')}" fill="#fff4dc"/>`:''}<g id="editable-paths">${lines}</g></svg>\n`);
}
function crc(bytes){let c=0xffffffff;for(const b of bytes){c^=b;for(let i=0;i<8;i++)c=(c>>>1)^((c&1)?0xedb88320:0);}return(c^0xffffffff)>>>0;}
function png(file,size,entries,polygon=null) {
 const rgba=Buffer.alloc(size*size*4), scale=size/1024;
 if(polygon) for(let y=0;y<size;y++)for(let x=0;x<size;x++) {
  let inside=false;const px=(x+.5)/scale,py=(y+.5)/scale;
  for(let i=0,j=polygon.length-1;i<polygon.length;j=i++) {const [a,b]=polygon[i],[c,d]=polygon[j];if((b>py)!=(d>py)&&px<(c-a)*(py-b)/(d-b)+a)inside=!inside;}
  if(inside){const n=(y*size+x)*4;rgba[n]=255;rgba[n+1]=247;rgba[n+2]=227;rgba[n+3]=255;}
 }
 for(const p of entries) for(let i=1;i<p.points.length;i++) {
  const [ax,ay]=p.points[i-1].map(v=>v*scale),[bx,by]=p.points[i].map(v=>v*scale),r=p.width*scale/2,dx=bx-ax,dy=by-ay;
  for(let y=Math.max(0,Math.floor(Math.min(ay,by)-r-1));y<Math.min(size,Math.ceil(Math.max(ay,by)+r+1));y++)
   for(let x=Math.max(0,Math.floor(Math.min(ax,bx)-r-1));x<Math.min(size,Math.ceil(Math.max(ax,bx)+r+1));x++) {
    const t=Math.max(0,Math.min(1,((x+.5-ax)*dx+(y+.5-ay)*dy)/(dx*dx+dy*dy||1)));
    const alpha=Math.max(0,Math.min(1,r+.5-Math.hypot(x+.5-ax-t*dx,y+.5-ay-t*dy)));
    const n=(y*size+x)*4;
    if(polygon){if(rgba[n+3]) for(let j=0;j<3;j++)rgba[n+j]=Math.round(rgba[n+j]*(1-alpha*.65));}
    else if(alpha*255>rgba[n+3]){const color=file==='SoulAbsorptionSigil'?(p.group==='inner'?[180,154,255]:[141,232,255]):[255,255,255];for(let k=0;k<3;k++)rgba[n+k]=color[k];rgba[n+3]=Math.round(alpha*255);}
   }
 }
 const raw=Buffer.alloc(size*(size*4+1));for(let y=0;y<size;y++)rgba.copy(raw,y*(size*4+1)+1,y*size*4,(y+1)*size*4);
 const header=Buffer.alloc(13);header.writeUInt32BE(size);header.writeUInt32BE(size,4);header[8]=8;header[9]=6;
 const chunk=(type,data)=>{const t=Buffer.from(type),n=Buffer.alloc(4),c=Buffer.alloc(4);n.writeUInt32BE(data.length);c.writeUInt32BE(crc(Buffer.concat([t,data])));return Buffer.concat([n,t,data,c]);};
 writeFileSync(resolve(dir,file+'.png'),Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',header),chunk('IDAT',deflateSync(raw,{level:9})),chunk('IEND',Buffer.alloc(0))]));
}
svg('SoulAbsorptionSigil',paths);png('SoulAbsorptionSigil',1024,paths);
for(const [name,entries] of [['sector',sector],['inner',inner],['channels',channels]]) {svg(name,entries);png(name,512,entries);}
for(let i=0;i<4;i++){const entries=glyph(i,512,512,8);svg('glyph'+i,entries);png('glyph'+i,128,entries);}
const torn=[[180,100],[430,82],[440,110],[470,84],[835,115],[812,330],[830,400],[804,418],[825,740],[774,731],[802,760],[795,918],[520,890],[490,920],[165,899],[183,670],[167,620],[188,600]];
const ink=[...glyph(2,512,338,2.5),...glyph(1,512,650,1.2)];
for(let i=0;i<4;i++)ink.push(stroke([[275,480+i*37],[700-(i%2)*65,480+i*37]],6,'paper'));
svg('page',ink,torn);png('page',256,ink,torn);
const edge=[stroke([...torn,torn[0]],23,'paper-edge')];svg('page-edge',edge);png('page-edge',256,edge);
// Compact authored trace descriptors also make the design editable in plain source.
writeFileSync(resolve(dir,'design.json'),JSON.stringify({title:'Soul Absorption Sigil',grammar:['Receive','Conduct','Release','Bind'],paths,glyphs},null,2)+'\n');
const files={};for(const name of ['SoulAbsorptionSigil','sector','inner','channels','glyph0','glyph1','glyph2','glyph3','page','page-edge'])for(const ext of ['svg','png']){const n=name+'.'+ext;files[n]=createHash('sha256').update(readFileSync(resolve(dir,n))).digest('hex');}
writeFileSync(resolve(dir,'manifest.json'),JSON.stringify({origin:'Original project-authored vector paths; no third-party model, glyph, stock circle or provider',source:'scripts/build-ag67-art.mjs; editable SVGs and design.json',localPrefix:'rbxasset://ag67-soul-v2/',publishedAssetIds:[],approval:'ART PENDING; private local Studio preview only',runtimeTextureBytesRGBA:3*512*512*4+4*128*128*4+2*256*256*4,files},null,2)+'\n');
console.log('AG67 original SVG / RGBA PNG pack generated; no uploads.');
