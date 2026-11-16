// Additive Studio-only grass variant of the exact reviewed R3 place.
import {readFileSync,writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const root=resolve(import.meta.dirname,'..'),path=p=>resolve(root,p);
const read=p=>readFileSync(path(p),'utf8');
const base='d5f39fad50ac84e660365299f1b3c4de600e3a80';
// Every production file, all R3 objects/lighting, island collision and authored references are protected.
const protectedPaths=execFileSync('git',['ls-tree','-r','--name-only',base,'src','qa/romantic-island','qa/wizard-island','docs/references/ag76r3','default.project.json'],{cwd:root,encoding:'utf8'}).trim().split('\n');
for(const file of protectedPaths) {
 const before=execFileSync('git',['show',`${base}:${file}`],{cwd:root,maxBuffer:32*1024*1024});
 const after=readFileSync(path(file));
 if(/\.(luau|json|md|svg|txt)$/.test(file)) assert.equal(after.toString().replaceAll('\r\n','\n'),before.toString().replaceAll('\r\n','\n'),`R4A must preserve ${file}`);
 else assert.deepEqual(after,before,`R4A must preserve ${file}`);
}
execFileSync(process.execPath,['scripts/build-romantic-island.mjs'],{cwd:root,stdio:'pipe'});
const project=JSON.parse(read('build/romantic-island.project.json'));
project.name='WizardIsland-AG76B-R4A-Grass-ART-PENDING';
const shared=project.tree.ReplicatedStorage.PotionTycoon.Shared;
shared.GrassPlan={$path:path('qa/dynamic-grass/Plan.luau')};
shared.GrassWind={$path:path('qa/dynamic-grass/Wind.luau')};
shared.RomanticAtmosphereStyle=shared.AtmosphereStyle;
shared.AtmosphereStyle={$path:path('qa/dynamic-grass/Style.luau')};
project.tree.ServerScriptService.GroundCover={$path:path('qa/dynamic-grass/Cover.server.luau')};
project.tree.Workspace.Terrain={$className:'Terrain',$properties:{Decoration:true,GrassLength:.24}};
// Reuse the R3 review implementation verbatim, only adding two camera entries and a readiness barrier.
let review=read('qa/romantic-island/Review.client.luau');
const replace=(from,to)=>{assert.equal(review.split(from).length,2,`Review adapter anchor changed: ${from}`);review=review.replace(from,to);};
replace('local cameras={','local cameras={\n\tgrass={Vector3.new(-16,4.8,32),Vector3.new(-25,1.2,38),65},\n\tgrove={Vector3.new(30,5.2,-15),Vector3.new(45,1.4,-30),68},');
replace('while not root:GetAttribute("WizardReady") do task.wait() end','while not root:GetAttribute("GroundCoverReady") do task.wait() end');
replace('FORGOTTEN SANCTUARY / ART PENDING','R4A DYNAMIC GRASS / ART PENDING');
writeFileSync(path('build/grass-review.client.luau'),review);
project.tree.StarterPlayer.StarterPlayerScripts.WizardReview.Review={$path:path('build/grass-review.client.luau')};
const input=path('build/grass-island.project.json');writeFileSync(input,JSON.stringify(project,null,2)+'\n');
const artifact='build/WizardIsland-AG76B-R4A-Grass-ART-PENDING.rbxlx';
execFileSync(path('.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),['build',input,'-o',path(artifact)],{stdio:'inherit'});
const xml=read(artifact);
assert(xml.includes('<bool name="Decoration">true</bool>'));
assert(/name="GrassLength">0\.24/.test(xml));
assert(!xml.includes('<string name="Name">Main</string>'));
const sha=p=>createHash('sha256').update(readFileSync(path(p))).digest('hex');
const sources=['qa/dynamic-grass/Plan.luau','qa/dynamic-grass/Wind.luau','qa/dynamic-grass/Style.luau','qa/dynamic-grass/Cover.server.luau','build/grass-review.client.luau','scripts/build-grass-island.mjs'];
const receipt={base,head:execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim(),artifact,sha256:sha(artifact),
 sourceHashes:Object.fromEntries(sources.map(p=>[p,sha(p)])),protectedPaths,
 grass:{decoration:true,length:.24,maxAddedMeshes:320,motionSlots:{full:64,reduced:32,minimal:0},nativeMotion:'Workspace.GlobalWind via unchanged EnvironmentView'},
 assets:'Existing admitted CC0 woodland receipt and R3 assets, no new upload',scope:'Standalone Studio-only art pass; no gameplay or persistence',ownerArtApproval:'PENDING'};
writeFileSync(path('build/grass-island-build.json'),JSON.stringify(receipt,null,2)+'\n');
console.log(`R4A built ${artifact} SHA256 ${receipt.sha256}`);
