import {readFileSync} from 'node:fs';
import assert from 'node:assert/strict';
const read=p=>readFileSync(p,'utf8').replaceAll('\r\n','\n');
const historical=JSON.parse(read('docs/evidence/m7-a2c/source-snapshot.json'));
const main=read('src/client/Main.client.luau');
const section=(s,a,b)=>s.slice(s.indexOf(a),s.indexOf(b));
// Cosmetic shell changes must not alter request sequencing or payment handling.
for(const [a,b] of [['local function send(', 'local function names('],['PurchasePrompt.OnClientEvent:', 'TradeState.OnClientEvent:']])
  assert.equal(section(main,a,b),section(historical['src/client/Main.client.luau'],a,b),'Protected intent/payment section');
const context=read('src/client/WorldContext.luau');
assert(!/FireServer|InvokeServer|InputHoldBegin|Triggered:|SetCoreGuiEnabled/.test(context),'Context must use native prompts and grant no authority');
assert(!/SetCoreGuiEnabled/.test(main),'Do not hide Roblox controls for UI acceptance');
assert(!read('default.project.json').includes('qa/'),'QA leaked to production');
assert.match(main,/ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets/);
console.log('UI18 contract PASS: original intent sequencing/payment handling; native prompts; CoreGui and release isolation');
