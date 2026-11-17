// Only deterministic size reduction here; preserve image_gen output and alpha.
import {readFileSync,writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {decode,downscale,encode} from './lunar-pixels.mjs';
const dir='assets/environment/lunar/refinement',hash=b=>createHash('sha256').update(b).digest('hex');
const info=path=>({path,sha256:hash(readFileSync(path)),bytes:readFileSync(path).length});
const before=JSON.parse(readFileSync('assets/environment/lunar/manifest.json'));
const textures=before.textures.map(t=>{
 const edited=info(`${dir}/${t.name}-soft-source.png`),rgba=downscale(decode(readFileSync(edited.path)),512);
 const path=`${dir}/${t.name}-soft.png`;writeFileSync(path,encode(512,rgba));
 return {name:t.name,input:t.texture,edited,texture:{...info(path),width:512,height:512,rgbaSha256:hash(rgba)}};
});
writeFileSync(`${dir}/manifest.json`,JSON.stringify({base:'463cf0ddc2562239c589bcececeba9b0b93c4ada',
 provenance:'Edits of approved lunar textures, same original concepts and rights as ../manifest.json; prompts.json',
 preparation:'node scripts/prepare-lunar-refinement.mjs; area downscale only',robloxUploads:0,textures},null,2)+'\n');
console.log(textures.map(t=>({name:t.name,sha256:t.texture.sha256})));
