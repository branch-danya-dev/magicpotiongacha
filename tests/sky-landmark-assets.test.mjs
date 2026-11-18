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
const r2=JSON.parse(readFileSync(dir+'r2/manifest.json'));
test('R2 pins the new edit and original masters without increasing decoded image memory',()=>{
 for(const f of r2.files)assert.equal(createHash('sha256').update(readFileSync(f.path)).digest('hex'),f.sha256,f.path);
 for(const name of ['Cloud','Glow'])assert.deepEqual(readFileSync(dir+'r2/textures/'+name+'.png'),readFileSync(dir+'textures/'+name+'.png'));
 assert.equal(r2.textureBytes,6553600);assert.equal(r2.editableImages,4);assert.equal(r2.robloxUploads,0);assert.equal(r2.qaCaptures,0);
});
test('R2 crop metadata encloses all visible pixels without a hard cropped edge',()=>{
 for(const [name,shape]of Object.entries(r2.layers)){
  const d=decode(readFileSync(dir+'r2/textures/'+name+'.png')),c=shape.crop,v=shape.visible;
  let x0=d.w,y0=d.h,x1=0,y1=0,edge=0;
  for(let y=0;y<d.h;y++)for(let x=0;x<d.w;x++){let a=d.rgba[(y*d.w+x)*4+3];if(a>=32){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y)}
   if(x>=c.x&&x<c.x+c.width&&y>=c.y&&y<c.y+c.height&&(x===c.x||y===c.y||x===c.x+c.width-1||y===c.y+c.height-1))edge=Math.max(edge,a);
  }
  assert.deepEqual(v,{x:x0,y:y0,width:x1-x0+1,height:y1-y0+1});assert.equal(edge,shape.cropEdgeAlphaMax);assert(edge<=2);
  assert(c.height<d.h*.55);assert(c.width*c.height<d.w*d.h*.55);
 }
 assert.deepEqual(r2.layers.Tree.crop,{x:52,y:288,width:921,height:370});assert.deepEqual(r2.layers.Tree.visible,{x:61,y:296,width:903,height:341});
});
