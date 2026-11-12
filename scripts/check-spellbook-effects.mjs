// AG62A must not silently expand into gameplay, permissions or asset changes.
import { readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import assert from 'node:assert/strict';
const base='341b7f6dd9ac1692781f865bf25fed63a05e9d8a';
const protectedFiles=['src/shared/Factory.luau','src/shared/Config.luau','src/shared/Protocol.luau',
  'src/shared/Access.luau','src/server/ProfileStore.luau','src/server/World.luau',
  'src/server/ServerSettings.luau','src/server/SpellbookLectern.luau',
  'assets/props/SpellbookLectern.rbxmx','assets/props/spellbook-lectern.glb','default.project.json'];
for(const path of protectedFiles) {
  const before=execFileSync('git',['show',`${base}:${path}`],{maxBuffer:4*1024*1024});
  const after=readFileSync(path);
  assert.equal(after.toString().replace(/\r\n/g,'\n'),before.toString().replace(/\r\n/g,'\n'),`${path}: AG62A scope regression`);
}
const client=readFileSync('src/client/SpellbookEffects.luau','utf8');
assert(!/FireServer|InvokeServer|ServerStorage|SpotLight|SurfaceLight|GetService\("Lighting"\)/.test(client));
assert.equal((client.match(/Instance\.new\("PointLight"\)/g)||[]).length,1);
assert(client.includes('localLight.Shadows=false; localLight.Range=8'));
assert.equal((client.match(/RunService\.Heartbeat:Connect/g)||[]).length,1);
assert.equal((client.match(/OnClientEvent:Connect/g)||[]).length,1);
const main=readFileSync('src/server/Main.server.luau','utf8');
const old=execFileSync('git',['show',`${base}:src/server/Main.server.luau`],{encoding:'utf8'});
assert.deepEqual([...main.matchAll(/remote\("([^"]+)"\)/g)].map(m=>m[1]),[...old.matchAll(/remote\("([^"]+)"\)/g)].map(m=>m[1]),'No new remote');
const revisionBase='f1882ad0ffc7a5e4803dc13f75d752ba01df229a';
const unchanged=['src/server/Main.server.luau','src/shared/SpellbookFeedback.luau',
  ...execFileSync('git',['ls-tree','-r','--name-only',revisionBase,'src'],{encoding:'utf8'}).trim().split('\n').filter(p=>/Environment|Weather|Lighting/.test(p))];
for(const path of unchanged) {
  assert.equal(readFileSync(path,'utf8').replace(/\r\n/g,'\n'),execFileSync('git',['show',`${revisionBase}:${path}`],{encoding:'utf8'}).replace(/\r\n/g,'\n'),`${path}: R1 must preserve receipt/global environment`);
}
console.log('AG62A scope PASS: economy, permissions, hitboxes, saves, imported assets and release flags unchanged; one client scheduler and existing State remote.');
