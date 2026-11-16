// AG75 extends only these reviewed seams. Inherited project assertions can
// still compare exact pre-AG75 code; this does not waive checks on other paths.
import assert from 'node:assert/strict';
import {beforeAG76} from './ag76-preservation.mjs';
const tags={
 'src/client/Main.client.luau':['IMPORT','MENU_STATE','MENU_SCROLLER','MENU_GROUP_REFRESH','MENU_OVERVIEW',
  'MENU_CHARACTER_TAB','MENU_TAB_REF','MENU_BAR','MENU_HIDE_LEGACY','MENU_BIND','STARTER','UPDATE','MENU_UPDATE','NOTICE'],
 'src/client/ArcadeHUD.luau':['HIDE_CHOOSER'],
 'src/client/EnvironmentView.luau':['IMPORT','METEOR_CREATE','LANTERN_GLOW_STATE','LANTERN_GLOW_BIND',
  'TONEMAP','METEOR_UPDATE','LIGHT_ALLOCATION','LANTERN_GLOW_UPDATE','RAIN_TRAILS','FOG'],
 'src/shared/Access.luau':['STARTER'],
 'src/server/World.luau':['STARTER'],
};
export function beforeAG75(path,source) {
 source=beforeAG76(path,source);
 if(!tags[path]) return source;
 const seen=[];
 const result=source.replace(/^[\t ]*-- AG75_BEGIN_(\w+)\n[\s\S]*?^[\t ]*-- AG75_END_\1\n/gm,(_,tag)=>{seen.push(tag);return '';});
 assert.deepEqual(seen,tags[path],`AG75 missing/duplicated/unordered seam: ${path}`);
 return result;
}
