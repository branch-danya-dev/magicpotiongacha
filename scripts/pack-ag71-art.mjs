// Repack the owner-approved icons, preserving the original SVG crop/aspect ratio.
// Local build only. This script never uploads or requests Roblox permissions.
import {readFileSync,writeFileSync,mkdirSync,existsSync} from 'node:fs';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const root=process.cwd(),dir=resolve(root,'assets/ui/ag71');mkdirSync(dir,{recursive:true});
const source='docs/art/ag71/concept-atlas.png',bytes=readFileSync(source);
const sha=b=>createHash('sha256').update(b).digest('hex');
assert.equal(sha(bytes),'821cd5e9416217fa9e5bdcea657822db12f985430db5a379843c2efbf1b31984');
const rects={gold:[25,110,285,285],essence:[336,76,260,320],book:[616,110,326,278],owl:[958,72,302,320],cat:[27,436,286,355],slime:[317,474,287,316],brew:[617,433,327,363],lab:[972,433,258,365],shop:[18,860,296,305],rewards:[327,860,286,310],settings:[627,855,282,312],more:[943,841,311,325]};
const build=resolve(root,'build/ag71-pack');mkdirSync(build,{recursive:true});
const html=`<!doctype html><canvas id="c" width="1024" height="1024"></canvas><output id="result"></output><script>
const image=new Image(); image.onload=()=>{const ctx=c.getContext('2d');ctx.imageSmoothingEnabled=true;ctx.imageSmoothingQuality='high';
Object.values(${JSON.stringify(rects)}).forEach(([x,y,w,h],i)=>{const s=232/Math.max(w,h);ctx.drawImage(image,x*image.width/1280,y*image.height/1280,w*image.width/1280,h*image.height/1280,(i%4)*256+(256-w*s)/2,Math.floor(i/4)*256+(256-h*s)/2,w*s,h*s)});
document.getElementById('result').textContent=c.toDataURL('image/png');};image.src='data:image/png;base64,${bytes.toString('base64')}';</script>`;
const file=resolve(build,'pack.html');writeFileSync(file,html);
const chrome=process.env.AG71_CHROME||'C:/Program Files/Google/Chrome/Application/chrome.exe';
const dom=execFileSync(chrome,['--headless=new','--no-first-run','--disable-background-networking','--disable-component-update','--disable-sync',`--user-data-dir=${resolve(build,'profile')}`,'--virtual-time-budget=2000','--dump-dom',pathToFileURL(file).href],{windowsHide:true,encoding:'utf8',stdio:['ignore','pipe','ignore'],timeout:30000,maxBuffer:8*1024*1024});
const match=dom.match(/<output id="result">data:image\/png;base64,([^<]+)<\/output>/);assert(match,'Canvas export incomplete');
const png=Buffer.from(match[1],'base64');assert.equal(png.readUInt32BE(16),1024);assert.equal(png.readUInt32BE(20),1024);assert.equal(png[25],6);
const name='AG71_ArcadeAtlas.png';
const receiptPath=resolve(dir,'upload-manifest.json');
if(existsSync(receiptPath)) {
 const existing=JSON.parse(readFileSync(receiptPath));
 if(existing.uploadPerformed) {
  assert.equal(sha(png),existing.files[0].sha256,'Repack differs from the authorized uploaded bytes; keep the existing asset and receipt');
  writeFileSync(resolve(dir,name),png);
  console.log(JSON.stringify({name,bytes:png.length,sha256:sha(png),receipt:'preserved'}));
  process.exit(0);
 }
}
writeFileSync(resolve(dir,name),png);
writeFileSync(resolve(dir,'upload-manifest.json'),JSON.stringify({task:'AG71',variant:'B',status:'AWAITING_OWNER_UPLOAD_APPROVAL',source:{path:source,sha256:sha(bytes),origin:'Original built-in image_gen illustration; approved B 2026-11-14',prompt:'docs/art/ag71/imagegen-prompt.txt'},transform:'Approved 1280-space SVG crops, aspect-fit to 232px inside padded 256px tiles; no redrawing',creator:{type:'Group',id:925845207,name:'addout studio'},universeId:10776120489,privacy:'Restricted',creatorStore:false,files:[{name,bytes:png.length,sha256:sha(png),width:1024,height:1024,rgba:true}],sprites:Object.keys(rects).map((name,i)=>({name,sourceCrop:rects[name],rect:[i%4*256,Math.floor(i/4)*256,256,256]})),uploadPerformed:false,permissionGranted:false},null,2)+'\n');
console.log(JSON.stringify({name,bytes:png.length,sha256:sha(png)}));
