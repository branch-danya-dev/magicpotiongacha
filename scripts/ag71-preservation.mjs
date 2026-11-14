// AG71 adds only removable client presentation seams to two inherited owners.
import assert from 'node:assert/strict';
const tags={
 'src/client/Main.client.luau':['IMPORT','STARTER','STARTER_END','SWITCH','RESTORE','CALLBACKS','PRESENT','ASSET_GATE','BACK'],
 'src/client/LandscapeHUD.luau':['FACTORY'],
};
export function beforeAG71(path,source) {
 if(!tags[path]) return source;
 const seen=[];
 const result=source.replace(/^-- AG71_BEGIN_(\w+)\n[\s\S]*?^-- AG71_END_\1\n/gm,(_,tag)=>{seen.push(tag);return '';});
 assert.deepEqual(seen,tags[path],`AG71 missing/duplicated/reordered seam ${path}`);
 return result;
}
