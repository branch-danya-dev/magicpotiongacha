// Preserve the exact AG69 native-tested owner beneath reviewed AG70 additions.
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const seams=JSON.parse(readFileSync(new URL('../tests/fixtures/ag70-original-seams.json',import.meta.url)));
export function beforeAG70(path,source) {
  if(!seams[path]) return source;
  const seen=[];
  const restored=source.replace(/^-- AG70_BEGIN_(\w+)\n[\s\S]*?^-- AG70_END_\1\n/gm,(_,tag)=>{
    assert(Object.hasOwn(seams[path],tag),`Unknown AG70 seam ${tag}`);
    seen.push(tag); return seams[path][tag];
  });
  assert.deepEqual(seen,Object.keys(seams[path]),'Missing/duplicated/reordered AG70 seam');
  return restored;
}
