import {readFileSync,writeFileSync,readdirSync} from 'node:fs';
import {resolve,relative} from 'node:path';
import {createHash} from 'node:crypto';
const root=resolve(import.meta.dirname,'../..'),dir=resolve(root,'assets/environment/willow-v2');
const entry=p=>{const b=readFileSync(p);return {path:relative(root,p).replaceAll('\\','/'),bytes:b.length,sha256:createHash('sha256').update(b).digest('hex')}};
const files=readdirSync(resolve(dir,'prepared')).sort().map(n=>entry(resolve(dir,'prepared',n)));
const manifest={schema:1,task:'WILLOW-V2',base:'08e7603a124807318236ed6521e97ac1ea9f6277',
 rights:'Derivative of owner-paid Meshy willow; owner confirmation retained in V1. CC0 Quaternius bark and original generated foliage atlas retained unchanged.',
 sources:['assets/environment/willow/source/owner-confirmation.json','assets/environment/willow/source/Quaternius-CC0.txt','assets/environment/willow/prepared/Willow.mesh.json','assets/environment/willow/textures/FoliageAtlas.png','assets/environment/willow/textures/Bark.png'].map(p=>entry(resolve(root,p))),
 process:'Existing mesh only, local Blender 4.5.9 derivation. Three crown/root variants; shared unchanged maps, material tint in TreeVisualConfig. No rendering, generation or uploads.',
 files,studioPreview:'Local EditableMesh/EditableImage; not a native V2 asset permission receipt',nativeV2Upload:'NOT AUTHORIZED / NOT PERFORMED',integrated:false,ownerArt:'PENDING'};
writeFileSync(resolve(dir,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
console.log('Willow V2 manifest: '+files.length+' derived files');
