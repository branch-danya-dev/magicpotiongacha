import {beforeAG68} from './ag68-preservation.mjs';
// Freeze the inherited game; only bounded additions to its existing owner are allowed.
import { readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import assert from 'node:assert/strict';
const base='081bf33ba88178312207f8ad4f3a21b698511766';
const normalize=text=>text.replace(/\r\n/g,'\n');
const original=path=>normalize(execFileSync('git',['show',`${base}:${path}`],{encoding:'utf8',maxBuffer:16*1024*1024}));
const current=path=>normalize(readFileSync(path==='src/client/SpellbookEffects.luau'?'src/client/LegacySpellbookEffects.luau':path,'utf8'));
const inherited=execFileSync('git',['ls-tree','-r','--name-only',base,'src','tests'],{encoding:'utf8'}).trim().split('\n');
for(const path of [...inherited,'default.project.json']) {
  // AG64 owns bounded HUD additions; check-landscape-hud strips them and pins
  // every inherited file to the exact CI-green AG63 base (including this owner).
  if(!['src/client/EnvironmentView.luau','src/client/Main.client.luau','src/client/UIFoundationDemo.client.luau'].includes(path)) assert.equal(current(path),original(path),`${path}: AG63 must preserve inherited code/tests`);
}
const view=beforeAG68('src/client/EnvironmentView.luau',current('src/client/EnvironmentView.luau'));
const sections=[];
const stripped=view.replace(/^[\t ]*-- AG63_BEGIN_(\w+)\n[\s\S]*?^[\t ]*-- AG63_END_\1\n/gm,(_,name)=>{sections.push(name);return '';});
assert.deepEqual(sections,['IMPORT','STATE','APPLY','METHOD','STATS','INSPECT','REQUEST','STOP']);
assert.equal(stripped,original('src/client/EnvironmentView.luau'),'Original lighting, lifecycle and weather pipeline must remain byte-identical');
assert.equal((view.match(/:Connect\(/g)||[]).length,5,'No extra event connections');
assert.equal((view.match(/RenderStepped:Connect/g)||[]).length,1,'Single inherited frame owner');
assert.equal((view.match(/task\.spawn\(/g)||[]).length,1,'No added task/clock');
const additions=view.match(/-- AG63_BEGIN_\w+[\s\S]*?-- AG63_END_\w+/g).join('\n');
assert.deepEqual([...additions.matchAll(/Instance\.new\("([^"]+)"\)/g)].map(m=>m[1]),['BindableFunction'],'Only a Studio inspection endpoint; no new render effects');
assert(additions.includes('if not RunService:IsStudio() or not Look.valid(name) then return false end'));
assert(additions.includes('if lookInspect then lookInspect:Destroy(); lookInspect=nil end'));
assert(additions.includes('lookInspect.Parent=folder') && !additions.includes('lookInspect.Parent=root'),'QA endpoint must not re-enter the root ChildAdded reconcile during startup');
assert(!/SetAttribute\("EnvironmentArtEnabled"|FireServer|InvokeServer|BlurEffect|DepthOfFieldEffect|Skybox/.test(additions));
const look=current('src/shared/PostFXLook.luau');
assert(!/GetService|Instance\.new|task\.|os\.|rbxasset|require\(/.test(look),'Projection must stay portable, stateless and asset-free');
console.log('AG63 preservation PASS: inherited source/tests unchanged; sole environment owner + bounded look projection; no new visual instances, connections, assets, remotes or release flags.');
