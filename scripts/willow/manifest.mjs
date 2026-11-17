import {readFileSync,writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
const base=new URL('../../assets/environment/willow/',import.meta.url);
const files=['source/Meshy_AI_model_20261117_generate.fbx','source/willow-reference.png','source/trees-concept-v3.png','source/FoliageAtlas-generated.png','source/atlas-prompts.json','source/Quaternius-CC0.txt','textures/FoliageAtlas.png','textures/Bark.png','prepared/Willow.blend','prepared/Willow.fbx','prepared/Willow.mesh.json','prepared/build-report.json','prepared/validation.json'];
const manifest={schema:1,base:'fdaf931b179ad188555147c720b768dd9334b17b',meshyTask:'01a1e765-fba3-7739-ac6c-e560f44b6856',rights:'Owner confirmation for this willow pending; no public redistribution',integration:false,
 nativeImportIncident:{uploadCheckbox:false,result:'Online IDs nevertheless created under personal account crystymoore; permission audit blocked by Updated Agreements',model:'81045114472619',foliageMesh:'103393042017627',woodMesh:'85732748826171',foliageImage:'79171837674186',barkImage:'77979867898740',usedByQABuild:false},
 files:files.map(path=>{const b=readFileSync(new URL(path,base));return {path,bytes:b.length,sha256:createHash('sha256').update(b).digest('hex')};})};
writeFileSync(new URL('manifest.json',base),JSON.stringify(manifest,null,2)+'\n');
