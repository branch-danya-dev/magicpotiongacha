import assert from 'node:assert/strict';
export function beforeAG74(path, source) {
  if(path!=='src/client/FamiliarView.client.luau') return source;
  const seen=[];
  const result=source.replace(/^-- AG74_BEGIN_(\w+)\n[\s\S]*?^-- AG74_END_\1\n/gm,(_,tag)=>{seen.push(tag);return '';});
  assert.deepEqual(seen,['IMPORT','STATE','CLEANUP','RENDER','DISPOSE']);
  return result;
}
