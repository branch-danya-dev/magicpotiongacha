// Extract only our own measurement JSON, never upload a raw Studio log.
import {readFileSync,writeFileSync} from 'node:fs';
const [log,out,label]=process.argv.slice(2);
if(!log||!out||!label)throw Error('log output run-label required');
const rows=[];let startup=null;let precedingStartup=null;
for(const line of readFileSync(log,'utf8').split(/\r?\n/)){
 const m=line.match(/FOREST_PERF (\w+) (\{.*\})$/);if(!m)continue;
 const data=JSON.parse(m[2]);
 if(m[1]==='startup')precedingStartup=data;
 if(data.run===label){if(!rows.length)startup=precedingStartup;rows.push({kind:m[1],...data});}
}
if(!rows.length)throw Error('No matching profiling run');
// Stalls only make sense for time samples, not drawcall/mesh/memory counters.
for(const r of rows)if(['resources','meshes'].includes(r.kind))for(const v of Object.values(r))if(v&&typeof v==='object'){
 delete v.stallsOver100;delete v.stallMs;delete v.framesOver33;
}
const result={label,startup,completed:rows.some(r=>r.kind==='complete'&&r.ok),rows};
writeFileSync(out,JSON.stringify(result,null,2)+'\n');
for(const r of rows.filter(r=>r.kind==='frames'))console.log(JSON.stringify({stage:r.stage,...r.all}));
console.log('Completed:',result.completed);
