// Exact same harness, only engine LightingStyle differs. No runtime owner.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import assert from 'node:assert/strict';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const project=JSON.parse(readFileSync(resolve(root,'qa/environment.project.json')));
function paths(node) { for(const [k,v] of Object.entries(node)) { if(k==='$path') node[k]=resolve(root,'qa',v); else if(v && typeof v==='object') paths(v); } }
paths(project); mkdirSync(resolve(root,'build'),{recursive:true});
for(const style of ['Soft','Realistic']) {
  project.tree.Lighting.$properties.LightingStyle=style;
  // Rojo 7.7.1's missing Technology serializes Compatibility and Studio then
  // overwrites modern settings during migration (rbx-dom #637). Explicit
  // legacy equivalents migrate to the intended style + quality priority.
  project.tree.Lighting.$properties.Technology=style==='Soft'?'ShadowMap':'Future';
  project.tree.Lighting.$properties.PrioritizeLightingQuality=true;
  const path=resolve(root,`build/atmosphere-${style}.project.json`);
  writeFileSync(path,JSON.stringify(project,null,2));
  const r=spawnSync(resolve(root,'.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),['build',path,'-o',`build/M7A2b-${style}-Verified.rbxlx`],{cwd:root,stdio:'inherit'});
  assert.equal(r.status,0);
}
