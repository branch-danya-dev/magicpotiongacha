// Extract only this QA's own results, never copy account/network logs wholesale.
import {readFileSync,writeFileSync,readdirSync} from 'node:fs';
import {createHash} from 'node:crypto';
const root=new URL('../../',import.meta.url),out=new URL('docs/evidence/willow/',root);
const log=readFileSync(process.argv[2],'utf8');
const records=[];
for(const line of log.split(/\r?\n/)){
 const m=line.match(/^([^,]+).*\[FLog::CreatorOutput\] (WILLOW_[A-Z_]+) (\{.*\}|\d+)$/);
 if(m)records.push({utc:m[1],kind:m[2],value:JSON.parse(m[3])});
}
const hash=b=>createHash('sha256').update(b).digest('hex');
const captures=readdirSync(out).filter(n=>n.endsWith('.png')).map(name=>({name,sha256:hash(readFileSync(new URL(name,out)))}));
writeFileSync(new URL('telemetry.json',out),JSON.stringify({studio:'0.747.0.7471481',graphics:'Q6; NVIDIA GeForce RTX 5070 Ti',notes:'Native isolated Play. Frame interval is not GPU render time. All twenty clones are allocated before measurement; only 1 or 20 are parented. Earlier diagnostics are retained. Final live Unix-time correction is verified at 04:02:41 UTC; final performance runs follow at 04:02:53 through 04:03:32 UTC.',records,captures},null,2)+'\n');
