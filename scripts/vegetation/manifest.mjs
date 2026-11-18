// Local derivative receipt, not a game-dev canonical admission or a Roblox upload receipt.
import {readFileSync,writeFileSync,readdirSync} from 'node:fs';
import {resolve,relative} from 'node:path';
import {createHash} from 'node:crypto';
const root=resolve(import.meta.dirname,'../..'),dir=resolve(root,'assets/environment/vegetation-v2');
const files=[];
for(const key of ['stylized_stefan','magic_igor'])for(const name of readdirSync(resolve(dir,'prepared',key)).sort()){
 const path=resolve(dir,'prepared',key,name),bytes=readFileSync(path);
 files.push({path:relative(root,path).replaceAll('\\','/'),bytes:bytes.length,sha256:createHash('sha256').update(bytes).digest('hex')});
}
writeFileSync(resolve(dir,'manifest.json'),JSON.stringify({schema:1,kind:'LOCAL_DERIVATIVE_RECEIPT',canonicalGameDevReceipt:false,
 studioVerified:false,productionAdmitted:false,sourceAudit:'source-audit.json',files},null,2)+'\n');
console.log(`Vegetation receipt: ${files.length} local artifacts; Studio gate remains open.`);
