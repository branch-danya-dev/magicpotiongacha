// Deterministic downscale of the checked-in image_gen cutouts; keeps the generated alpha.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {resolve} from 'node:path';
import {decode,downscale,encode} from './lunar-pixels.mjs';
const root=resolve(import.meta.dirname,'..'),p=s=>resolve(root,s),dir='assets/environment/lunar',hash=b=>createHash('sha256').update(b).digest('hex');
const expected=['3f62f4e440abe5b8aacc3904f2c829429abf7ee3a135663313ccf188f157dd58','20a3609b2baeae61b6ffb60b1011fcb060334bd4e3daf400d31a4eb4ff46f2ac','82b7e938643f2f841d8982f9412915038c76d9ac9f504bcbd6495006b6673fb4'];
const library=['libfile_fde3_f-3051d55733288191b68b921eb9ff842a_72129a2f176c81919add0c85246d9626','libfile_fde3_f-3664602a72888191acfcd7b985e76597_72129a2f176c81919add0c85246d9626','libfile_fde3_f-56dd242bf1a4819197b64e7a71861a7e_72129a2f176c81919add0c85246d9626'];
mkdirSync(p(dir+'/textures'),{recursive:true});
const info=path=>{const b=readFileSync(p(path));return {path,sha256:hash(b),bytes:b.length};};
const textures=['pearl','blood','frost'].map((name,i)=>{
 const source=info(`${dir}/source/${name}_moon_concept_v1.png`);if(source.sha256!==expected[i])throw Error('Owner source hash mismatch');
 const edited=info(`${dir}/edited/${name}-disc.png`),image=decode(readFileSync(p(edited.path)));
 const rgba=downscale(image,512),path=`${dir}/textures/${name}-moon.png`;writeFileSync(p(path),encode(512,rgba));
 return {name,source:{...source,url:'https://chatgpt.com/library?file_id='+library[i]+'&account_id=personal'},edited,texture:{...info(path),width:512,height:512,rgbaSha256:hash(rgba)}};
});
writeFileSync(p(dir+'/manifest.json'),JSON.stringify({task:'AG-76B-R4B',provenance:'Owner-supplied original ChatGPT Library concepts; exact supplied SHA-256 validated. Built-in image_gen cutout edits, prompts.json. No third-party game art.',
 license:'Owner-authorized project artwork; no third-party license claimed',robloxAssetIds:null,robloxUploadApproved:false,delivery:'Local Studio-only EditableImage RGBA buffers; no upload or API setting change',
 preparation:'node scripts/prepare-lunar-assets.mjs (area downscale only, generated alpha preserved); node scripts/build-lunar-island.mjs (validate + encode fixed pixel buffers)',textures},null,2)+'\n');
console.log(textures.map(t=>({name:t.name,...t.texture})));
