import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {beforeAG76,seams,addedRuntime} from './ag76-preservation.mjs';
const base='fdb6494a96c9065783bf3b3ac1f6fd3f8c4888ae';
const normal=b=>b.toString().replaceAll('\r\n','\n');
const paths=execFileSync('git',['ls-tree','-r','--name-only',base,'src','tests','assets','qa'],{encoding:'utf8'}).trim().split('\n');
for(const path of [...paths,'default.project.json','tools.lock.json']) {
 const old=execFileSync('git',['show',`${base}:${path}`],{maxBuffer:64*1024*1024});
 const now=readFileSync(path);
 if(path.endsWith('.luau')) assert.equal(beforeAG76(path,normal(now)),normal(old),path);
 else if(/\.(json|md|svg|rbxmx|txt|mjs|py)$/.test(path)) assert.equal(normal(now),normal(old),path);
 else assert(now.equals(old),path);
}
const read=p=>normal(readFileSync(p));
const main=read('src/server/Main.server.luau');
assert(main.indexOf('AG76 QA cannot access live persistence')<main.indexOf('DataStoreService:GetDataStore'));
assert(main.indexOf('local plot = world:claim(player)')<main.indexOf('local profile, errorCode = store:load'));
assert(main.indexOf('world:activate(player,profile)')>main.indexOf('local saved, saveError = store:save'));
assert(main.includes('RunService:IsStudio()')&&main.includes('AG76QAOwnerUserId'));
const world=read('src/server/PersonalIslandWorld.luau');
assert(!/PlotCount|for index|FindFirstChild\("Bazaar"\)|DataStore|Teleport|FireServer/.test(world));
assert(world.includes('self.session:admit(player.UserId,player)')&&world.includes('function World:inBazaar(_player) return false end'));
assert(!/Instance\.new\("(?:RemoteEvent|RemoteFunction)"\)|SetAsync|UpdateAsync/.test(addedRuntime.map(read).join('\n')));
assert(!read('src/client/PersonalMarketUI.luau').includes('requestPurchase'));
assert(Object.keys(seams).length===5&&addedRuntime.length===5);
console.log('AG76B preservation: exact V8 economy/assets/legacy source outside five explicit adapter seams; local memory admission, no live routing/schema/paid enablement.');
