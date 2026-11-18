// Reproducible ordinary-game candidate; all production and former QA inputs intact.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const root=resolve(import.meta.dirname,'..'),path=p=>resolve(root,p);
const read=p=>readFileSync(path(p),'utf8').replaceAll('\r\n','\n'),node=p=>({$path:path(p)});
const hash=b=>createHash('sha256').update(b).digest('hex');
const head=execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim();
const owner=process.argv.find(a=>a.startsWith('--owner-user-id='));assert(owner,'Explicit owner required');
if(!process.argv.includes('--reuse-landscape'))execFileSync(process.execPath,['scripts/build-landscape.mjs',owner],{cwd:root,stdio:'pipe',maxBuffer:8e6});
const prior=JSON.parse(read('build/landscape/build.json'));
assert.equal(prior.owner,Number(owner.split('=')[1]));assert.equal(prior.head,head);
assert.equal(hash(readFileSync(path(prior.artifact))),prior.sha256,'Stale landscape input');
const project=JSON.parse(read('build/landscape/game.project.json'));
const shared=project.tree.ReplicatedStorage.PotionTycoon.Shared,server=project.tree.ServerScriptService;
const client=project.tree.StarterPlayer.StarterPlayerScripts.CurrentArt;
mkdirSync(path('build/forest'),{recursive:true});
const files=[];
function output(name,s){const file=`build/forest/${name}.luau`;writeFileSync(path(file),s);files.push(file);return node(file);}
function change(s,a,b){assert.equal(s.split(a).length,2,'Forest adapter drift: '+a);return s.replace(a,b);}
shared.ForestLayout=node('qa/forest/Layout.luau');shared.GroveBasePlan=node('qa/landscape/Plan.luau');
shared.ForestOcclusion=node('qa/forest/Occlusion.luau');
shared.ForestReadiness=node('qa/forest/Readiness.luau');
shared.PersonalIslandBase=node('src/shared/PersonalIsland.luau');
shared.PersonalIsland=output('Island','local S=script.Parent\nreturn require(S.ForestLayout).island(require(S.PersonalIslandBase))\n');
shared.LandscapePlan=output('Plan','local S=script.Parent\nreturn require(S.ForestLayout).apply(require(S.GroveBasePlan),require(S.Config),require(S.PersonalIsland),require(S.NatureGeometry))\n');
let art=read('build/landscape/art.luau');
art=change(art,'local Landscape=require(Shared.LandscapePlan)','local Landscape=require(Shared.LandscapePlan)\nlocal Forest=require(Shared.ForestLayout)');
art=change(art,'{1.6,124,116}','{1.6,Forest.width,Forest.depth}');
const oldRegion='Region3.new(O+Vector3.new(-68,-8,-72),O+Vector3.new(68,8,56))';
const newRegion='Region3.new(O+Vector3.new(-108,-8,-108),O+Vector3.new(108,12,100))';
art=change(art,oldRegion,newRegion);
art=change(art,'math.atan2((z+8)/53,x/59)','math.atan2((z+8)/Forest.rz,x/Forest.rx)');
art=change(art,'math.sqrt((x/59)^2+((z+8)/53)^2)','math.sqrt((x/Forest.rx)^2+((z+8)/Forest.rz)^2)');
server.PotionTycoon.PersonalIslandArt=output('Art',art);
let cliff=read('build/landscape/Cliff.luau');
cliff=change(cliff,'local Cliff={}','local Forest=require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.ForestLayout)\nlocal Cliff={}');
cliff=change(cliff,'math.cos(a)*59*r','math.cos(a)*Forest.rx*r');
cliff=change(cliff,'math.sin(a)*53*r','math.sin(a)*Forest.rz*r');
client.Cliff=output('Cliff',cliff);
// Camera-safe crowns: static parts remain with EnvironmentView, skinned parts
// remain with Grove. Both use the same pure occlusion rule, no competing writer.
let setup=read('qa/landscape/Setup.server.luau');
setup=change(setup,'p.Anchored=true;p.CanCollide=false;',
 'p:SetAttribute("ForestOccluder",name=="Pine_2" or name=="CommonTree_5");p.Anchored=true;p.CanCollide=false;');
server.LandscapeSetup=output('Setup.server',setup);
let grove=read('qa/landscape/Grove.luau');
grove=change(grove,'local ok,err=pcall(function()',`local ok,err=pcall(function()
		local hits=require(Shared.ForestReadiness).wait(P.trees,function(t)
			return workspace:Raycast(origin+Vector3.new(t.x,20,t.z),Vector3.new(0,-40,0),params)
		end,task.wait,os.clock,function()return root.Parent~=nil and folder.Parent~=nil end,20)`);
grove=change(grove,'local hit=workspace:Raycast(origin+Vector3.new(t.x,20,t.z),Vector3.new(0,-40,0),params)','local hit=hits[t.id]');
grove=change(grove,'local P=require(Shared.LandscapePlan)','local Occlusion=require(Shared.ForestOcclusion)\nlocal P=require(Shared.LandscapePlan)');
grove=change(grove,'table.insert(parts,p)','p:SetAttribute("ForestScale",t.scale);table.insert(parts,p)');
grove=change(grove,'p.LocalTransparencyModifier+=math.clamp(target-p.LocalTransparencyModifier,-.4,.4)',
 'target=math.max(target,Occlusion.target(p,workspace.CurrentCamera))\n\t\t\t\tp.LocalTransparencyModifier+=math.clamp(target-p.LocalTransparencyModifier,-.4,.4)');
client.LandscapeGrove=output('Grove',grove);
let tree=read('build/landscape/VegetationTreeModel.luau');
tree=change(tree,'local maps={ColorMap=Content.fromObject(image)};',
 'local lo,hi=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)\n\t\t\tfor _,v in ipairs(source.vertices)do local p=Vector3.new(table.unpack(v));lo=lo:Min(p);hi=hi:Max(p)end\n\t\t\tpart:SetAttribute("ForestOccluder",true);part:SetAttribute("ForestBoundCenter",(lo+hi)*.5);part:SetAttribute("ForestBoundHalf",(hi-lo)*.5)\n\t\t\tlocal maps={ColorMap=Content.fromObject(image)};');
client.VegetationTreeModel=output('TreeModel',tree);
const gameClient=project.tree.StarterPlayer.StarterPlayerScripts.PotionTycoon;
let view=readFileSync(gameClient.EnvironmentView.$path,'utf8').replaceAll('\r\n','\n');
view='local ForestOcclusion=require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.ForestOcclusion)\n'+view;
view=change(view,'else p.LocalTransparencyModifier=hidden and 1 or 0 end',
 'elseif p:GetAttribute("ForestOccluder")then local target=hidden and 1 or ForestOcclusion.target(p,camera);p.LocalTransparencyModifier+=math.clamp(target-p.LocalTransparencyModifier,-.4,.4) else p.LocalTransparencyModifier=hidden and 1 or 0 end');
gameClient.EnvironmentView=output('EnvironmentView',view);
let cover=read('build/current-game-cover.server.luau');
cover=change(cover,oldRegion,newRegion);server.GroundCover=output('Cover.server',cover);
let grass=read('qa/dynamic-grass/Plan.luau');
grass=change(grass,'local P={maxPlants=320,grassLength=.24,seed=7604}',
 'local S=script.Parent\nlocal Forest=require(S.ForestLayout)\nlocal Plan=require(S.LandscapePlan)\nlocal P={maxPlants=300,grassLength=.14,seed=7604}');
grass=change(grass,'function P.protected(x,z,r,config)','function P.protected(x,z,r,config)\n\tif Forest.path(x,z,r)then return true end');
grass=change(grass,'function P.surface(x,z,config)',
 'function P.surface(x,z,config)\n\tif Forest.path(x,z,1)then return "Ground" end\n\tif x>-39 and x<39 and z>-46 and z<30 then return P.protected(x,z,0,config) and "Ground" or "LeafyGrass" end');
grass=change(grass,'ipairs(layout.trees)','ipairs(Plan.trees)');
grass=change(grass,'for i=1,14 do','for i=1,3 do');
grass=change(grass,'math.cos(a)*59*r,-8+math.sin(a)*53*r','math.cos(a)*Forest.rx*r,-8+math.sin(a)*Forest.rz*r');
shared.GrassPlan=output('Grass',grass);
project.tree.Workspace.Terrain.$properties.GrassLength=.14;
let additions=read('build/landscape/additions.client.luau');
// Move only decorative water to the new eastern shore; no gameplay anchor moves.
additions=change(additions,'.create(root,O,Assets.uri("mist"))','.create(root,O+Vector3.new(28,0,0),Assets.uri("mist"))');
client.Additions=output('Additions.client',additions);
let checks=read('qa/current-game/Checks.server.luau');
checks=change(checks,'==124 and root:GetAttribute("IslandSurfaceDepth")==116','==Island.surface.width and root:GetAttribute("IslandSurfaceDepth")==Island.surface.depth');
server.CurrentGameChecks=output('Checks.server',checks);
project.name='PotionTycoon-Dense-Forest';project.tree.Workspace.$attributes.DenseForestQA=true;
const stats=JSON.parse(execFileSync(path('.tools/luau/luau'+(process.platform==='win32'?'.exe':'')),['scripts/forest-stats.luau'],{cwd:root,encoding:'utf8'}));
const sources=['qa/forest/Layout.luau','qa/forest/Occlusion.luau','qa/forest/Readiness.luau',...files];
const codeSHA256=hash(Buffer.from(sources.map(f=>f+'\n'+read(f)).join('\n')));
project.tree.Workspace.$attributes.ForestCodeSHA256=codeSHA256;
const input='build/forest/game.project.json',artifact='build/PotionTycoon-Dense-Forest.rbxlx';
writeFileSync(path(input),JSON.stringify(project,null,2)+'\n');
execFileSync(path('.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),['build',path(input),'-o',path(artifact)],{stdio:'inherit'});
const bytes=readFileSync(path(artifact));
assert(bytes.includes('AG76 QA cannot access live persistence'));
const receipt={base:'2cbc8d5b970d086ffe41bd3081a39ac68b519107',head,owner:prior.owner,artifact,bytes:bytes.length,sha256:hash(bytes),codeSHA256,
 predecessorSHA256:prior.sha256,width:184,depth:172,...stats,editableMeshes:17,editableImages:3,decodedAtlasBytes:6291456,
 animatedTrees:{full:8,reduced:4,minimal:1},fixedMeshResources:24,maxConcurrentExpandableMeshes:1,
 newLights:0,additionalFrameLoops:0,studioOnly:true,memoryOnly:true,uploads:0,productionIntegrated:false,ownerArt:'PENDING'};
writeFileSync(path('build/forest/build.json'),JSON.stringify(receipt,null,2)+'\n');console.log(JSON.stringify(receipt,null,2));
