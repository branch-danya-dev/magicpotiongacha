import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {decode,downscale,encode} from '../scripts/lunar-pixels.mjs';
const manifest=JSON.parse(readFileSync('assets/environment/lunar/manifest.json'));
test('R4B three source identities and exact reproducible texture pixels',()=>{
 assert.equal(manifest.textures.length,3);assert.equal(manifest.robloxAssetIds,null);assert.equal(manifest.robloxUploadApproved,false);
 for(const t of manifest.textures){
  for(const k of ['source','edited','texture'])assert.equal(createHash('sha256').update(readFileSync(t[k].path)).digest('hex'),t[k].sha256);
  const rgba=downscale(decode(readFileSync(t.edited.path)),512);
  assert.deepEqual(decode(readFileSync(t.texture.path)).rgba,rgba);
  assert.deepEqual(decode(encode(512,rgba)).rgba,rgba);
 }
});
test('R4B transparent border, opaque lunar interior and antialiased silhouette',()=>{
 for(const t of manifest.textures){const {w,h,rgba}=decode(readFileSync(t.texture.path));let aa=0;
  for(let y=0;y<h;y++)for(let x=0;x<w;x++){const a=rgba[(y*w+x)*4+3];
   // Image editor leaves at most one 8-bit alpha step in Pearl/Blood padding.
   if(x<16||y<16||x>=w-16||y>=h-16)assert(a<=1);
   if(Math.hypot(x-w/2,y-h/2)<w*.31)assert(a>245);
   if(a>10&&a<245)aa++;
  }assert(aa>500);assert(aa<16000);
 }
});
test('R4B one inherited Lighting/wind owner with bounded fixed images and stop disposal',()=>{
 const view=readFileSync('build/lunar-view.luau','utf8'),base=readFileSync('src/client/EnvironmentView.luau','utf8'),disks=readFileSync('qa/lunar/Disks.luau','utf8');
 assert.equal((view.match(/RenderStepped:Connect/g)||[]).length,(base.match(/RenderStepped:Connect/g)||[]).length);
 assert(!/RenderStepped|Heartbeat|GlobalWind|GetService\("Lighting"\)/.test(disks));
 assert(view.includes('Lighting:GetMoonDirection()'));assert(view.includes('sky.MoonAngularSize=0'));
 assert(view.includes('assert(not workspace:FindFirstChild("M7ClientWeather")'));
 assert(view.indexOf('assert(not workspace:FindFirstChild("M7ClientWeather")')<view.indexOf('active=self'));
 assert(view.includes('lunarDisks.destroy()'));assert(view.includes('for k,v in pairs(saved) do Lighting[k]=v end'));assert(view.includes('workspace.GlobalWind=savedWind'));
 assert(!/RemoteEvent|DataStore|MarketplaceService|PromptCreatePlatformContent|CreateAsset/.test(disks));
});
