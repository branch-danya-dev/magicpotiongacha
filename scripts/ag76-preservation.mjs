import assert from 'node:assert/strict';
export const seams={
 'src/server/Main.server.luau':['WORLD','SPAWN','DENIED','ACTIVATE'],
 'src/server/CharacterSafety.server.luau':['BOUNDS'],
 'src/client/Main.client.luau':['NAV','MARKET','BOOK'],
 'src/client/SimplifiedScene.luau':['OWNED_WORLD'],
 'src/shared/RPGNavigation.luau':['MARKET_LABEL'],
};
export const addedRuntime=[
 'src/shared/PersonalIsland.luau','src/shared/IslandSession.luau',
 'src/server/PersonalIslandWorld.luau','src/server/PersonalIslandArt.luau',
 'src/client/PersonalMarketUI.luau',
];
export function beforeAG76(path,source) {
 if(path==='src/client/Main.client.luau'&&source.includes('-- AG76R1_BEGIN_')) {
  const r1=[];
  source=source.replace(/^[\t ]*-- AG76R1_BEGIN_(\w+)\n[\s\S]*?^[\t ]*-- AG76R1_END_\1\n/gm,(_,tag)=>{r1.push(tag);return '';});
  assert.deepEqual(r1,['PLAYERLIST_SETUP','PLAYERLIST_RESTORE'],'AG76-R1 must only change reviewed Tab PlayerList blocks');
 }
 if(!seams[path]) return source;
 const seen=[];
 const result=source.replace(/^[\t ]*-- AG76_BEGIN_(\w+)\n[\s\S]*?^[\t ]*-- AG76_END_\1\n/gm,(_,tag)=>{seen.push(tag);return '';});
 assert.deepEqual(seen,seams[path],`AG76 missing/duplicated/reordered seam: ${path}`);
 return result;
}
