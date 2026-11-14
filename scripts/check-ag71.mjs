import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {inflateSync} from 'node:zlib';
import {beforeAG71} from './ag71-preservation.mjs';
const base='18b300ca2c7f7a7c67202e270d50602e4ad7ffd0';
const normal=b=>b.toString().replaceAll('\r\n','\n');
const read=p=>normal(readFileSync(p));
const paths=execFileSync('git',['ls-tree','-r','--name-only',base,'src','tests','qa','assets'],{encoding:'utf8'}).trim().split('\n');
for(const path of [...paths,'default.project.json']) {
 const old=execFileSync('git',['show',`${base}:${path}`],{maxBuffer:64*1024*1024});
 const current=readFileSync(path);
 if(/\.(luau|json|md|svg|rbxmx|txt|mjs)$/.test(path)) assert.equal(beforeAG71(path,normal(current)),normal(old),`Inherited drift: ${path}`);
 else assert(current.equals(old),`Inherited bytes: ${path}`);
}
const main=read('src/client/Main.client.luau'),view=read('src/client/ArcadeHUD.luau');
assert.equal((main.match(/\bState\.OnClientEvent:Connect/g)||[]).length,1);
assert.equal((main.match(/Instance.new\("ScreenGui"\)/g)||[]).length,1);
assert(!/FireServer|InvokeServer|OnClientEvent|SetCoreGuiEnabled|Lighting|Instance.new\("ScreenGui"\)/.test(view));
assert(main.includes('send("chooseStarter",{speciesId=id})'));
assert(main.includes('collect=function() send("click",{}) end'));
assert(main.includes('LandscapeModel.upgrade(state,collectionPending).enabled'));
assert(view.includes('Legacy.feedback(self.cursor,value,owned,maxBalance)'));
assert(view.includes('if self.connection then return end'));
assert(view.includes('for _,c in ipairs(connections) do c:Disconnect() end'));
assert(!/docs\/art|B-hud|B-book|B-chooser|day-reduced/.test(view));
const manifest=JSON.parse(readFileSync('assets/ui/ag71/upload-manifest.json'));
const sha=b=>createHash('sha256').update(b).digest('hex');
assert.equal(sha(readFileSync(manifest.source.path)),manifest.source.sha256);
assert.equal(manifest.creator.id,925845207);assert.equal(manifest.universeId,10776120489);
assert.equal(manifest.privacy,'Restricted');assert.equal(manifest.creatorStore,false);
assert.equal(manifest.files.length,1);assert.equal(manifest.sprites.length,12);
const proof=manifest.files[0],png=readFileSync('assets/ui/ag71/'+proof.name);
assert.equal(sha(png),proof.sha256);assert.equal(png.length,proof.bytes);
assert(png.subarray(0,8).equals(Buffer.from('89504e470d0a1a0a','hex')));
assert.equal(png.readUInt32BE(16),1024);assert.equal(png.readUInt32BE(20),1024);assert.equal(png[24],8);assert.equal(png[25],6);
const compressed=[];let offset=8,ended=false;
function crc32(bytes) {let c=0xffffffff;for(const byte of bytes){c^=byte;for(let n=0;n<8;n++)c=(c>>>1)^((c&1)?0xedb88320:0);}return (c^0xffffffff)>>>0;}
while(offset<png.length){
 const size=png.readUInt32BE(offset),type=png.toString('ascii',offset+4,offset+8),end=offset+8+size;
 assert(end+4<=png.length);assert.equal(crc32(png.subarray(offset+4,end)),png.readUInt32BE(end));
 if(type==='IDAT')compressed.push(png.subarray(offset+8,end));
 offset=end+4;if(type==='IEND'){ended=true;break;}
}
assert(ended);assert.equal(offset,png.length);assert.equal(inflateSync(Buffer.concat(compressed)).length,1024*(1024*4+1));
for(const [i,sprite] of manifest.sprites.entries()) assert.deepEqual(sprite.rect,[i%4*256,Math.floor(i/4)*256,256,256]);
if(!manifest.uploadPerformed) assert(read('src/shared/ui/ArcadeAssets.luau').includes('image=""'),'Unuploaded art must not impersonate a Roblox ID');
else {assert(manifest.permissionGranted);assert.equal(manifest.observedPrivacy,'Restricted');assert(read('src/shared/ui/ArcadeAssets.luau').includes('rbxassetid://'+manifest.robloxImageId));}
console.log('AG71 preservation PASS: exact inherited authority, assets and tests; bounded client-only B slice. Native acceptance separate.');
