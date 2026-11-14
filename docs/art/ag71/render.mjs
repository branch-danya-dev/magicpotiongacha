// Design-only HTML export. Never injects a screenshot/HTML GUI into Roblox.
import {execFileSync} from 'node:child_process';
import {mkdirSync,readFileSync,writeFileSync,readdirSync} from 'node:fs';
import {resolve,dirname,relative} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const here=dirname(fileURLToPath(import.meta.url));
const root=resolve(here,'../../..');
const chrome=process.env.AG71_CHROME || 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const profile=resolve(root,'build/ag71-design-browser');mkdirSync(profile,{recursive:true});
const outputs=[];
const common=['--headless=new','--no-first-run','--no-default-browser-check','--disable-background-networking','--disable-component-update','--disable-sync','--hide-scrollbars','--force-device-scale-factor=1',`--user-data-dir=${profile}`,'--allow-file-access-from-files'];
function render(name,query,w,h){
 const path=resolve(here,name);const url=pathToFileURL(resolve(here,'index.html'));url.search=query;
 execFileSync(chrome,[...common,`--window-size=${w},${h}`,'--run-all-compositor-stages-before-draw','--virtual-time-budget=1500',`--screenshot=${path}`,url.href],{windowsHide:true,stdio:'ignore',timeout:30000});
 const bytes=readFileSync(path);if(bytes.readUInt32BE(16)!==w||bytes.readUInt32BE(20)!==h)throw Error('Wrong PNG export size');
 outputs.push({file:name,width:w,height:h,bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')});
 console.log(`Exported ${name}: ${w}x${h}`);
}
for(const variant of ['A','B']){
 for(const state of ['hud','receipt','book','chooser'])render(`${variant}-${state}.png`,`variant=${variant}&state=${state}&capture=1`,844,390);
 render(`${variant}-board.png`,`variant=${variant}&sheet=1`,1740,960);
}
writeFileSync(resolve(here,'exports.json'),JSON.stringify({kind:'DESIGN_CONCEPT_NOT_STUDIO_CAPTURE',outputs},null,2)+'\n');
const dom=execFileSync(chrome,[...common,'--window-size=1740,2000','--dump-dom',pathToFileURL(resolve(here,'index.html')).href],{windowsHide:true,encoding:'utf8',stdio:['ignore','pipe','ignore'],timeout:30000});
const audit=JSON.parse(dom.match(/<script id="design-audit" type="application\/json">(.*?)<\/script>/s)[1]);
assert.equal(audit.length,8);
for(const frame of audit) for(const b of frame.buttons){
 assert(b.w>=44&&b.h>=44,`Small target: ${b.name}`);
 assert(b.x>=47&&b.y>=58&&b.x+b.w<=797&&b.y+b.h<=380,`Unsafe edge: ${b.name}`);
 const hits=(x,y,w,h)=>b.x<x+w&&b.x+b.w>x&&b.y<y+h&&b.y+b.h>y;
 assert(!hits(0,250,148,140)&&!hits(696,250,148,140),`Touch control overlap: ${b.name}`);
}
writeFileSync(resolve(here,'layout-audit.json'),JSON.stringify({scope:'HTML concept geometry only; NOT Roblox/device verification',frames:audit},null,2)+'\n');
console.log('Concept audit PASS: eight frames, 44px targets, reserved CoreGui and touch regions.');
function proof(path){const b=readFileSync(path);return {path:relative(root,path).replaceAll('\\','/'),bytes:b.length,sha256:createHash('sha256').update(b).digest('hex')};}
const atlas=resolve(here,'concept-atlas.png'),png=readFileSync(atlas);
assert.equal(png[25],6,'Generated atlas has an RGBA channel');
const manifest={task:'AG-71 Phase A',status:'OWNER_DESIGN_GATE_OPEN',phaseBStarted:false,
 baseSha:'c8b546bc1734cc435159cfa6b1122f9a23b806a5',
 background:{...proof(resolve(root,'docs/evidence/ag70/r2/day-reduced-near-AG70.jpg')),
 runtimeSha:'89804f0ea070b3b685a9939b00872fa0b5fe2b55',nativeStudioEvidence:true,freshR3Capture:false,
 sourceSize:[2560,1392],crop:[500,470,1280,390/(844/1280)],scale:844/1280,retouched:false},
 illustration:{...proof(atlas),tool:'built-in image_gen',origin:'original generated concept art',
 size:[png.readUInt32BE(16),png.readUInt32BE(20)],rgba:true,prompt:'imagegen-prompt.txt',robloxUpload:false,productionAccepted:false},
 files:readdirSync(here).filter(f=>f!=='manifest.json').sort().map(f=>proof(resolve(here,f))),
 runtimeEdits:false,nativeGuiVerification:false};
writeFileSync(resolve(here,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
