// Auxiliary evidence only, never an art acceptance test. Original native JPEGs untouched.
// node scripts/measure-ag68-captures.mjs <existing ffmpeg executable>
import {readFileSync,writeFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {resolve} from 'node:path';
const dir=resolve('docs/evidence/ag68');
const ffmpeg=process.argv[2]; if(!ffmpeg) throw Error('Pass existing ffmpeg executable');
const captures=JSON.parse(readFileSync(resolve(dir,'captures.json'),'utf8')).filter(s=>s.index<=32);
const rects=[[0,206,510,620],[850,260,1325,350],[1780,260,1930,735],[710,665,1140,1080],[0,206,220,340],[1560,1040,1660,1140]];
// Same conservative union mask for both cameras: HUD, avatar/book/sigil/runes,
// cursor. Reduce Motion stabilizes world foliage for both halves.
const mask=(x,y)=>rects.some(([l,t,r,b])=>x>=l&&x<r&&y>=t&&y<b);
const linear=Array.from({length:256},(_,v)=>{v/=255;return v<=.04045?v/12.92:((v+.055)/1.055)**2.4;});
const f=x=>x>.008856451679?Math.cbrt(x):7.787037*x+16/116;
function lab(rgb,i){const r=linear[rgb[i]],g=linear[rgb[i+1]],b=linear[rgb[i+2]];
 const x=f((.4124564*r+.3575761*g+.1804375*b)/.95047),y=f(.2126729*r+.7151522*g+.072175*b),z=f((.0193339*r+.119192*g+.9503041*b)/1.08883);
 return [116*y-16,500*(x-y),200*(y-z)];}
function pixels(name){const file=resolve(dir,name+'.jpg');

 const rgb=execFileSync(ffmpeg,['-v','error','-i',file,'-f','rawvideo','-pix_fmt','rgb24','pipe:1'],{maxBuffer:12*1024*1024});
 if(rgb.length!==2560*1392*3)throw Error('Unmatched native dimensions '+name);return rgb;}
const pairs=[];
for(const off of captures.filter(x=>x.look==='OFF')){
 const on=captures.find(x=>x.name===off.name.replace(/OFF$/,'AG68'));
 for(const key of ['cframe','fov','viewport','pose','quality','reduceMotion'])if(JSON.stringify(off[key])!==JSON.stringify(on[key]))throw Error('Unmatched '+key);
 const a=pixels(off.name),b=pixels(on.name),delta=[];
 for(let y=206;y<1321;y+=3)for(let x=2;x<2115;x+=3){if(mask(x,y))continue;const i=(y*2560+x)*3,u=lab(a,i),v=lab(b,i);delta.push(Math.hypot(...u.map((n,k)=>n-v[k])));}
 delta.sort((a,b)=>a-b);pairs.push({off:off.name,on:on.name,samples:delta.length,meanDeltaE76:delta.reduce((a,b)=>a+b,0)/delta.length,
  medianDeltaE76:delta[Math.floor(delta.length*.5)],p95DeltaE76:delta[Math.floor(delta.length*.95)],fractionAbove5:delta.filter(x=>x>5).length/delta.length});
}
writeFileSync(resolve(dir,'perceptual-difference.json'),JSON.stringify({method:'sRGB D65 CIELAB Delta E 1976; every third pixel; native JPEG decoded by ffmpeg without transforms',
 viewport:[2,206,2115,1321],excludedRectangles:rects,caveats:'Auxiliary only, no acceptance threshold. Sky has inherited missing textures; avatar/HUD/local VFX/cursor masked. Tiny residual motion/renderer noise possible.',pairs},null,2)+'\n');
console.log(JSON.stringify(pairs.map(x=>({pair:x.off,mean:+x.meanDeltaE76.toFixed(2),median:+x.medianDeltaE76.toFixed(2),above5:+(x.fractionAbove5*100).toFixed(1)})),null,2));
