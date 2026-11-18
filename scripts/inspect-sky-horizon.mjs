// Read-only SOURCE diagnostics. No capture, render, image edit or native PASS.
import{readFileSync,writeFileSync,mkdirSync}from'node:fs';
import{createHash}from'node:crypto';
import assert from'node:assert/strict';
import{decode}from'./lunar-pixels.mjs';
const delivery=JSON.parse(readFileSync('assets/environment/ag69-delivery.json'));
const faces={};const rows={};
for(const a of delivery.assets.filter(a=>a.key.startsWith('sky_'))){
 const bytes=readFileSync(a.source);assert.equal(createHash('sha256').update(bytes).digest('hex'),a.sha256);
 const d=decode(bytes),name=a.key.slice(4);faces[name]=d;
 if(name==='up'||name==='dn')continue;
 const means=[];for(let y=0;y<d.h;y++){let sum=0;for(let x=0;x<d.w;x++){const p=(y*d.w+x)*4;sum+=d.rgba[p]*.2126+d.rgba[p+1]*.7152+d.rgba[p+2]*.0722;}means.push(sum/d.w);}
 const changes=means.slice(1).map((v,i)=>({row:i+1,meanLuminanceDelta:Math.abs(v-means[i])}));
 rows[name]={maxAdjacentRowChange:changes.reduce((a,b)=>a.meanLuminanceDelta>b.meanLuminanceDelta?a:b),horizonBand:means.slice(117,138)};
}
const edge=(d,s)=>Array.from({length:d.w},(_,i)=>{const x=s==='L'?0:s==='R'?d.w-1:i,y=s==='T'?0:s==='B'?d.h-1:i;return [...d.rgba.subarray((y*d.w+x)*4,(y*d.w+x)*4+4)];});
const adjacency=JSON.parse(readFileSync('docs/evidence/m7-07a-batch/sky-diagnosis.json')).edges;
let maxEdgeError=0;
for(const [from,to]of Object.entries(adjacency)){
 const a=edge(faces[from.slice(0,2)],from[2]),b=edge(faces[to.neighbor.slice(0,2)],to.neighbor[2]);if(to.reverse)b.reverse();
 for(let i=0;i<a.length;i++)for(let j=0;j<4;j++)maxEdgeError=Math.max(maxEdgeError,Math.abs(a[i][j]-b[i][j]));
}
const r2=JSON.parse(readFileSync('assets/environment/sky-world-tree/r2/manifest.json'));
const report={kind:'source-only',skyFaceFilesMatchApprovedDelivery:true,maxSkyFaceEdgeChannelError:maxEdgeError,
 lateralRows:rows,cloudCropEdgeAlphaMax:r2.layers.Cloud.cropEdgeAlphaMax,
 knownSourceFeatures:['create-fantasy-sky.py contains three low ridge silhouette bands around the horizon','five soft cloud banks are baked into the sky, independent of R2 CloudOcean'],
 conclusion:'SOURCE METRICS ONLY: do not identify the reported native horizon line or dark fragments until visual layer ablation.',
 screenshots:0,video:0};
mkdirSync('build/sky-landmark',{recursive:true});writeFileSync('build/sky-landmark/horizon-source-audit.json',JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({skyFilesVerified:true,maxSkyFaceEdgeChannelError:maxEdgeError,cloudCropEdgeAlphaMax:report.cloudCropEdgeAlphaMax,sourceMaxRowChanges:Object.fromEntries(Object.entries(rows).map(([k,v])=>[k,v.maxAdjacentRowChange])),nativeCause:'UNCONFIRMED'},null,2));
