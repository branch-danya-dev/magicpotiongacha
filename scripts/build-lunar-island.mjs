// QA composition adapter: never edits src/ or any R4A geometry/grass source.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
import {decode} from './lunar-pixels.mjs';
const root=resolve(import.meta.dirname,'..'),path=p=>resolve(root,p),read=p=>readFileSync(path(p),'utf8').replaceAll('\r\n','\n');
const hash=b=>createHash('sha256').update(b).digest('hex'),base='56666c072e66f7357ec2f054f818a642cae0abd9';
const protectedPaths=execFileSync('git',['ls-tree','-r','--name-only',base,'src','qa/romantic-island','qa/wizard-island','qa/dynamic-grass','assets','default.project.json'],{cwd:root,encoding:'utf8'}).trim().split('\n');
for(const file of protectedPaths){const before=execFileSync('git',['show',`${base}:${file}`],{cwd:root,maxBuffer:64*1024*1024}),after=readFileSync(path(file));
 if(/\.(luau|json|md|svg|txt)$/.test(file))assert.equal(after.toString().replaceAll('\r\n','\n'),before.toString().replaceAll('\r\n','\n'),`R4B protected ${file}`);
 else assert.deepEqual(after,before,`R4B protected ${file}`);
}
execFileSync(process.execPath,['scripts/build-grass-island.mjs'],{cwd:root,stdio:'pipe'});
const manifest=JSON.parse(read('assets/environment/lunar/manifest.json'));
const disks=[];
for(const item of manifest.textures){
 for(const key of ['source','edited','texture'])assert.equal(hash(readFileSync(path(item[key].path))),item[key].sha256,`Lunar ${key} hash`);
 const img=decode(readFileSync(path(item.texture.path)));assert.equal(img.w,512);assert.equal(img.h,512);disks.push(img.rgba.toString('base64'));
}
mkdirSync(path('build'),{recursive:true});
writeFileSync(path('build/lunar-pixels.luau'),'-- Generated, three fixed local RGBA images; never uploaded.\nreturn {size=512,disks={\n'+disks.map(s=>'[=['+s+']=]').join(',\n')+'\n}}\n');
const project=JSON.parse(read('build/grass-island.project.json'));
project.name='WizardIsland-AG76B-R4B-Moons-ART-PENDING';
const shared=project.tree.ReplicatedStorage.PotionTycoon.Shared,client=project.tree.StarterPlayer.StarterPlayerScripts.WizardReview;
shared.R4AEnvironmentConfig=shared.EnvironmentConfig;
shared.EnvironmentConfig={$path:path('qa/lunar/EnvironmentConfig.luau')};
shared.LunarConfig={$path:path('qa/lunar/Config.luau')};shared.LunarCycle={$path:path('qa/lunar/Cycle.luau')};shared.LunarPixels={$path:path('build/lunar-pixels.luau')};
client.LunarDisks={$path:path('qa/lunar/Disks.luau')};
client.LunarDiagnostics={$path:path('qa/lunar/Diagnostics.luau')};
const adapt=(source,patches)=>{for(const [a,b]of patches){assert.equal(source.split(a).length,2,`QA anchor drift: ${a}`);source=source.replace(a,b);}return source;};
let view=adapt(read('src/client/EnvironmentView.luau'),[
 ['local View={}','local Lunar=require(Shared.LunarCycle)\nlocal LunarDisks=require(script.Parent.LunarDisks)\nlocal View={}'],
 ['\tassert(not active,','\tassert(RunService:IsStudio(),"R4B scene is Studio-only")\n\tassert(not active,'],
 ['\tactive=self','\tactive=self\n\tlocal lunarCycle=Lunar.new(); local forcedMoon="auto"; local lunarWeights={1,0,0}'],
 ['\tassetGui(moon.gui,"moon")','\tassetGui(moon.gui,"moon")\n\tlocal lunarDisks=LunarDisks.create(moon,Vista.moonSize)\n\tif lunarDisks.ready then assetGuis[moon.gui]=nil; moon.gui.Enabled=true end'],
 ['\tfunction self.setQuality(name)','\tfunction self.setMoon(name) if not Lunar.valid(name) then return false end;forcedMoon=name;return true end\n\tfunction self.setQuality(name)'],
 ['\t\tlocal flow=State.wind(sample,time,self.reduceMotion)','\t\tlunarWeights=lunarCycle.sample(time,now,forcedMoon)\n\t\tsample=Lunar.apply(sample,lunarWeights)\n\t\tlocal flow=State.wind(sample,time,self.reduceMotion)'],
 ['\t\tmoon.attachment.Position=Vector3.new(table.unpack(State.moon(sample.phase)))*Config.celestial.distance\n\t\tmoon.image.ImageTransparency=1-sample.celestial*.94','\t\tlocal moonDirection=Lighting:GetMoonDirection()\n\t\tmoon.attachment.Position=moonDirection*Config.celestial.distance\n\t\tlunarDisks.update(sample,lunarWeights,moonDirection,self.quality)'],
 ['\t\tcounts.moon=moon.image.ImageTransparency<1 and 1 or 0','\t\tcounts.moon=lunarDisks.alpha>0 and 1 or 0\n\t\tcounts.lunar=lunarDisks.stats();counts.lunar.forced=forcedMoon;counts.lunar.cycle=Lunar.index(workspace:GetServerTimeNow())\n\t\tcounts.lunar.alignment=moon.attachment.Position.Unit:Dot(Lighting:GetMoonDirection())'],
 ['counts.moonLoaded=moon.image.IsLoaded','counts.moonLoaded=lunarDisks.ready or moon.image.IsLoaded'],
 ['\t\tlocal function request()','\t\tlocal function request()\n\t\t\tlocal token=root:GetAttribute("EnvironmentReview")\n\t\t\tlocal name=type(token)=="string" and string.match(token,"^moon:(%a+)$")\n\t\t\tif name then self.setMoon(name);return end'],
 ['\t\tclearProbes()\n\t\tfor texture','\t\tlunarDisks.destroy()\n\t\tclearProbes()\n\t\tfor texture'],
]);
writeFileSync(path('build/lunar-view.luau'),view);client.EnvironmentView={$path:path('build/lunar-view.luau')};
let review=adapt(read('build/grass-review.client.luau'),[
 ['local view=View.start(root,{quality="full",pose="dusk"})','local Diagnostics=require(script.Parent.LunarDiagnostics)\nlocal beforeView=Diagnostics.snapshot()\nlocal view=View.start(root,{quality="full",pose="night"})\nscript.Destroying:Connect(function() view.stop() end)'],
 ['local cameras={','local cameras={\n\tmoon={Vector3.new(-43,8,14),Vector3.new(0,19,-8),78},\n\tdawnmoon={Vector3.new(43,8,14),Vector3.new(0,19,-8),78},'],
 ['local cameraMode="spawn";local pose="dusk"','local cameraMode="moon";local pose="night"'],
 ['({day=true,dusk=true,night=true})','({day=true,dusk=true,night=true,dawn=true,dawnend=true})'],
 ['\telseif action=="measure" then','\telseif action=="moon" then view.setMoon(value);return view.stats().lunar\n\telseif action=="inspect" then return view.stats()\n\telseif action=="auto" then view.setPose(nil);return true\n\telseif action=="preview" then view.setPreview(value);return true\n\telseif action=="weather" then view.setWeather(value);return true\n\telseif action=="stop" then view.stop();return Diagnostics.restored(beforeView)\n\telseif action=="measure" then'],
 ['\tlocal c=({[Enum.KeyCode.One]','\tlocal moonKey=({[Enum.KeyCode.Z]="pearl",[Enum.KeyCode.X]="blood",[Enum.KeyCode.C]="frost",[Enum.KeyCode.Zero]="auto"})[key.KeyCode]\n\tif moonKey then view.setMoon(moonKey);return end\n\tif key.KeyCode==Enum.KeyCode.Nine then cameraMode="moon";refresh();return end\n\tif key.KeyCode==Enum.KeyCode.T then pose="dawn";refresh();return end\n\tlocal c=({[Enum.KeyCode.One]'],
 ['R4A DYNAMIC GRASS / ART PENDING','R4B MOONS / ART PENDING'],
 ['Q Quality  R Motion"','Q Quality  R Motion  Z/X/C Moons  T Dawn"'],
 ['\t\tprint("WIZARD_PERF "..Http:JSONEncode(data));measuring=false','\t\tdata.effects=nil;data.lunar=view.stats().lunar\n\t\tprint("LUNAR_PERF "..Http:JSONEncode(data));measuring=false'],
]);
writeFileSync(path('build/lunar-review.client.luau'),review);client.Review={$path:path('build/lunar-review.client.luau')};
writeFileSync(path('build/lunar-island.project.json'),JSON.stringify(project,null,2)+'\n');
const artifact='build/WizardIsland-AG76B-R4B-Moons-ART-PENDING.rbxlx';
execFileSync(path('.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),['build',path('build/lunar-island.project.json'),'-o',path(artifact)],{stdio:'inherit'});
const xml=read(artifact);assert(!xml.includes('<string name="Name">Main</string>'));assert.equal((view.match(/RenderStepped:Connect/g)||[]).length,1);
const receipt={base,head:execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim(),artifact,sha256:hash(readFileSync(path(artifact))),
 protectedPaths,textureManifest:hash(readFileSync(path('assets/environment/lunar/manifest.json'))),localOnly:true,robloxUploads:0,
 added:{editableImages:4,pixelBytes:3162112,imageLabels:4,renderConnections:0,lights:0},ownerMoonArt:'PENDING',integrated:false};
writeFileSync(path('build/lunar-island-build.json'),JSON.stringify(receipt,null,2)+'\n');
console.log(`R4B built ${artifact} SHA256 ${receipt.sha256}`);
