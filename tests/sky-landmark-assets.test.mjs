import{test}from'node:test';import assert from'node:assert/strict';import{readFileSync}from'node:fs';import{createHash}from'node:crypto';
import{decode}from'../scripts/lunar-pixels.mjs';
const dir='assets/environment/sky-world-tree/',manifest=JSON.parse(readFileSync(dir+'manifest.json'));
test('Original concept and separate RGBA masters are pinned and local',()=>{
 assert.equal(manifest.files.length,8);for(const f of manifest.files)assert.equal(createHash('sha256').update(readFileSync(f.path)).digest('hex'),f.sha256,f.path);
 assert.equal(manifest.robloxUploads,0);assert.equal(manifest.qaCaptures,0);
});
test('All runtime layers have transparent borders, soft alpha and bounded memory',()=>{
 let bytes=0;for(const f of manifest.files.filter(x=>x.path.includes('/textures/'))){const d=decode(readFileSync(f.path));assert(d.w<=1024);assert.equal(d.w,d.h);bytes+=d.rgba.length;
 assert.equal(f.edgeAlphaMax,0,f.path);assert(f.softPixels>d.w*d.h*.04);assert(f.transparentPixels>d.w*d.h*.1);
 }assert.equal(bytes,6553600);
});
test('Tree lower border cannot be exposed by moving the independent cloud mask',()=>{
 const d=decode(readFileSync(dir+'textures/Tree.png'));let max=0;
 for(let y=Math.floor(d.h*.90);y<d.h;y++)for(let x=0;x<d.w;x++)max=Math.max(max,d.rgba[(y*d.w+x)*4+3]);assert.equal(max,0);
});
test('World billboard retains depth occlusion and adds no lighting/time owner',()=>{
 const text=readFileSync('qa/sky-landmark/SkyLandmark.luau','utf8');assert(text.includes('gui.AlwaysOnTop=false'));assert(text.includes('anchor.CanCollide=false'));assert(text.includes('anchor.CanQuery=false'));
 assert(!/RenderStepped:Connect|Heartbeat:Connect|Lighting\.[A-Za-z]+\s*=|GlobalWind\s*=|math\.random|RemoteEvent/.test(text));
 assert.equal((text.match(/WritePixelsBuffer/g)||[]).length,1);assert(text.indexOf('WritePixelsBuffer')<text.indexOf('function self.update'));
});
