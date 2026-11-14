// Historical guards still compare the original source outside AG69 URI/delivery seams.
import {readFileSync} from 'node:fs';
import assert from 'node:assert/strict';
const originals=JSON.parse(readFileSync(new URL('../tests/fixtures/ag69-original-seams.json',import.meta.url)));
export function beforeAG69(path,source) {
  const seams=originals[path]; if(!seams) return source;
  const seen=[];
  const restored=source.replace(/^-- AG69_BEGIN_(\w+)\n[\s\S]*?^-- AG69_END_\1\n/gm,(_,tag)=>{
    assert(Object.hasOwn(seams,tag),`Unknown AG69 seam ${path}/${tag}`);
    seen.push(tag); return seams[tag];
  });
  assert.deepEqual(seen,Object.keys(seams),`Missing/duplicated/reordered AG69 seams in ${path}`);
  return restored;
}
