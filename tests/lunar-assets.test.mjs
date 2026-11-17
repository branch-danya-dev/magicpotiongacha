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

test('R4B refinement preserves crater identity while softening detail and expanding edge alpha',()=>{
 const refined=JSON.parse(readFileSync('assets/environment/lunar/refinement/manifest.json'));
 assert.equal(refined.robloxUploads,0);assert.equal(refined.textures.length,3);
 for(const t of refined.textures){
  for(const k of ['input','edited','texture'])assert.equal(createHash('sha256').update(readFileSync(t[k].path)).digest('hex'),t[k].sha256);
  const a=decode(readFileSync(t.input.path)).rgba,b=decode(readFileSync(t.texture.path)).rgba;
  assert.deepEqual(b,downscale(decode(readFileSync(t.edited.path)),512));
  let n=0,sa=0,sb=0,saa=0,sbb=0,sab=0,da=0,db=0,edgeA=0,edgeB=0;
  for(let y=48;y<464;y++)for(let x=48;x<464;x++){
   const i=(y*512+x)*4;
   if(a[i+3]>10&&a[i+3]<245)edgeA++;if(b[i+3]>10&&b[i+3]<245)edgeB++;
   if(Math.hypot(x-256,y-256)>150)continue;
   const av=(a[i]+a[i+1]+a[i+2])/3,bv=(b[i]+b[i+1]+b[i+2])/3;
   n++;sa+=av;sb+=bv;saa+=av*av;sbb+=bv*bv;sab+=av*bv;
   da+=Math.abs(a[i]-a[i+4]);db+=Math.abs(b[i]-b[i+4]);
  }
  const correlation=(sab-sa*sb/n)/Math.sqrt((saa-sa*sa/n)*(sbb-sb*sb/n));
  assert(correlation>.95,`${t.name}: crater layout drift`);
  assert(db/da>.4&&db/da<.85,`${t.name}: detail not softened or excessively blurred`);
  assert(edgeB>edgeA*2,`${t.name}: no atmospheric alpha transition`);
 }
});

test('R4B manual comparison reuses images and the render update never writes pixels',()=>{
 const disks=readFileSync('qa/lunar/Disks.luau','utf8');
 const update=disks.split('function self.update')[1].split('function self.stats')[0];
 assert(!/WritePixelsBuffer|Base64Decode|editable\(|write\(/.test(update));
 assert(disks.includes('if self.style==style then return true end'));
 assert(disks.includes('self.images[4]'));assert(!disks.includes('self.images[5]'));
 const builder=readFileSync('scripts/build-lunar-island.mjs','utf8');
 assert(builder.includes('imageLabels:4,renderConnections:0,lights:0'));
 assert(builder.includes('Vector3.new(0,27,-8),78'));
});
