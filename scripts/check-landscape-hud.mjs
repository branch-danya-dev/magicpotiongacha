// AG64 extends two UI owners through removable blocks; the game stays pinned.
import {readFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import assert from 'node:assert/strict';
const base='0457a87b5cbff1200d1e96889986198244918213';
const normal=s=>s.replace(/\r\n/g,'\n');
const read=p=>normal(readFileSync(p==='src/client/SpellbookEffects.luau'?'src/client/LegacySpellbookEffects.luau':p,'utf8'));
const original=p=>normal(execFileSync('git',['show',`${base}:${p}`],{encoding:'utf8',maxBuffer:16*1024*1024}));
const extended=new Set(['src/client/Main.client.luau','src/client/UIFoundationDemo.client.luau']);
const files=execFileSync('git',['ls-tree','-r','--name-only',base,'src','tests'],{encoding:'utf8'}).trim().split('\n');
for(const p of [...files,'default.project.json']) {
 const source=read(p);
 const stripped=extended.has(p)?source.replace(/^[\t ]*-- AG64_BEGIN_(\w+)\n[\s\S]*?^[\t ]*-- AG64_END_\1\n/gm,''):source;
 assert.equal(stripped,original(p),`${p}: AG64 must preserve inherited behavior outside explicit HUD additions`);
}
const main=read('src/client/Main.client.luau');
assert.equal((main.match(/State\.OnClientEvent:Connect/g)||[]).length,(original('src/client/Main.client.luau').match(/State\.OnClientEvent:Connect/g)||[]).length,'No duplicate state subscription');
assert.equal((main.match(/Instance.new\("ScreenGui"\)/g)||[]).length,1);
assert(main.includes('if not LandscapeModel.upgrade(state,collectionPending).enabled then return end'));
assert(main.includes('send("buy",{upgradeId="crystal"}); syncLandscape()'));
const view=read('src/client/LandscapeHUD.luau');
assert(!/FireServer|InvokeServer|OnClientEvent|Instance.new\("ScreenGui"\)|GetService\("Lighting"\)|rbxassetid|https:\/\//.test(view));
assert(view.includes('function self.destroy() self.hideFeedback(); host.destroy(); root:Destroy() end'));
assert(view.includes('if self.connection then return end'),'Popup scheduler must be bounded');
assert(view.includes('local host=Kit.host()'),'Reuse native control/focus lifecycle');
assert(!/SetCoreGuiEnabled/.test(main+view));
assert(main.includes('LandscapeHUDEnabled'));
console.log('AG64 preservation PASS: one PotionTycoonUI/state subscriber; original intents, economy, saves, Spellbook/PostFX, assets and tests unchanged; reversible HUD only.');
