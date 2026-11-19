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
shared.ForestTreeLOD=node('qa/forest/LOD.luau');
client.ForestStaticLOD=node('qa/forest/StaticLOD.luau');
shared.PersonalIslandBase=node('src/shared/PersonalIsland.luau');
shared.PersonalIsland=output('Island','local S=script.Parent\nreturn require(S.ForestLayout).island(require(S.PersonalIslandBase))\n');
shared.LandscapePlan=output('Plan','local S=script.Parent\nreturn require(S.ForestLayout).apply(require(S.GroveBasePlan),require(S.Config),require(S.PersonalIsland),require(S.NatureGeometry),require(S.RomanticLayout))\n');
let art=read('build/landscape/art.luau');
art=change(art,'local Landscape=require(Shared.LandscapePlan)','local Landscape=require(Shared.LandscapePlan)\nlocal Forest=require(Shared.ForestLayout)');
art=change(art,'{1.6,124,116}','{1.6,Forest.width,Forest.depth}');
const oldRegion='Region3.new(O+Vector3.new(-68,-8,-72),O+Vector3.new(68,8,56))';
const newRegion='Region3.new(O+Vector3.new(-108,-8,-108),O+Vector3.new(108,12,100))';
art=change(art,oldRegion,newRegion);
art=change(art,'math.atan2((z+8)/53,x/59)','math.atan2((z+8)/Forest.rz,x/Forest.rx)');
art=change(art,'math.sqrt((x/59)^2+((z+8)/53)^2)','math.sqrt((x/Forest.rx)^2+((z+8)/Forest.rz)^2)');
const clusterStart=art.indexOf('for n,c in ipairs(Landscape.keepClusters(Layout.clusters)) do');
const clusterEnd=art.indexOf('-- Sparse small rock outcrops',clusterStart);
assert(clusterStart>=0 && clusterEnd>clusterStart);
art=art.slice(0,clusterStart)+'-- Compatible legacy cluster children are owned once by LandscapeSetup.\n'+art.slice(clusterEnd);
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
 'p:SetAttribute("ForestOccluder",name=="Pine_2" or name=="CommonTree_5");p:SetAttribute("ForestUnderstory",id:match("^Undergrowth_")~=nil);p.Anchored=true;p.CanCollide=false;');
server.LandscapeSetup=output('Setup.server',setup);
let grove=read('qa/landscape/Grove.luau');
grove=change(grove,'local ok,err=pcall(function()',`local ok,err=pcall(function()
		local hits=require(Shared.ForestReadiness).wait(P.trees,function(t)
			return workspace:Raycast(origin+Vector3.new(t.x,20,t.z),Vector3.new(0,-40,0),params)
		end,task.wait,os.clock,function()return root.Parent~=nil and folder.Parent~=nil end,20)`);
grove=change(grove,'local hit=workspace:Raycast(origin+Vector3.new(t.x,20,t.z),Vector3.new(0,-40,0),params)','local hit=hits[t.id]');
grove=change(grove,'local P=require(Shared.LandscapePlan)','local Occlusion=require(Shared.ForestOcclusion)\nlocal LOD=require(Shared.ForestTreeLOD)\nlocal StaticLOD=require(script.Parent.ForestStaticLOD)\nlocal P=require(Shared.LandscapePlan)');
grove=change(grove,'libraries[key]=Model.load(data,Pixels[t.source],t.variant)',
 'libraries[key]=Model.load(data,Pixels[t.source],t.variant);StaticLOD.load(libraries[key],data,t.variant)');
grove=change(grove,'table.insert(parts,p)','p:SetAttribute("ForestScale",t.scale);table.insert(parts,p)');
grove=change(grove,'if dead or not workspace.CurrentCamera then return end',`if dead or not workspace.CurrentCamera then return end
		local started=os.clock();local candidates={}
		for id,e in pairs(entries)do
			table.insert(candidates,{id=id,high=e.high==true,distance=(e.rest.Position-workspace.CurrentCamera.CFrame.Position).Magnitude})
		end
		local high=LOD.select(candidates,self.quality);self.highTrees=0`);
grove=change(grove,'for _,p in ipairs(e.parts)do\n\t\t\t\tlocal target=',`e.high=high[e.descriptor.id]==true;e.tree:SetAttribute("ForestWindActive",e.high)
			if e.high then self.highTrees+=1 end
			for _,p in ipairs(e.parts)do
				local target=`);
grove=change(grove,'p.LocalTransparencyModifier+=math.clamp(target-p.LocalTransparencyModifier,-.4,.4)',
 `local visible=(p:GetAttribute("ForestStaticLOD")==true)~=e.high
				if visible then
					target=math.max(target,Occlusion.target(p,workspace.CurrentCamera))
					target=p.LocalTransparencyModifier+math.clamp(target-p.LocalTransparencyModifier,-.4,.4)
				else target=1 end
				-- Setting even an unchanged transparency can invalidate skinned rendering.
				if math.abs(target-p.LocalTransparencyModifier)>.0001 then p.LocalTransparencyModifier=target end`);
grove=change(grove,'newLights=0,clientMemoryMiB=', 'highTrees=self.highTrees or 0,newLights=0,clientMemoryMiB=');
grove=change(grove,'tree:ScaleTo(t.scale)','tree:ScaleTo(t.scale);task.wait()');
client.LandscapeGrove=output('Grove',grove);
let wind=read('qa/vegetation/TreeWindController.luau');
wind=change(wind,'and camera and not self.reduceMotion then',
 'and camera and not self.reduceMotion and e.tree:GetAttribute("ForestWindActive")~=false then');
client.VegetationWindController=output('WindController',wind);
let tree=read('build/landscape/VegetationTreeModel.luau');
tree=change(tree,'local maps={ColorMap=Content.fromObject(image)};',
 'local lo,hi=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)\n\t\t\tfor _,v in ipairs(source.vertices)do local p=Vector3.new(table.unpack(v));lo=lo:Min(p);hi=hi:Max(p)end\n\t\t\tpart:SetAttribute("ForestOccluder",true);part:SetAttribute("ForestBoundCenter",(lo+hi)*.5);part:SetAttribute("ForestBoundHalf",(hi-lo)*.5)\n\t\t\tlocal maps={ColorMap=Content.fromObject(image)};');
tree=change(tree,'mesh:SetFaceUVs(face,uvs);mesh:SetFaceNormals(face,normals)',
 'mesh:SetFaceUVs(face,uvs);mesh:SetFaceNormals(face,normals);if i%256==0 then task.wait()end');
tree=change(tree,'mesh:SetVertexBones(ids[i],bi);mesh:SetVertexBoneWeights(ids[i],bw)',
 'mesh:SetVertexBones(ids[i],bi);mesh:SetVertexBoneWeights(ids[i],bw);if i%512==0 then task.wait()end');
tree=change(tree,'part.CFrame=CFrame.identity;part.Parent=tree',
 'part.CFrame=CFrame.identity;part.LocalTransparencyModifier=1;part.Parent=tree');
client.VegetationTreeModel=output('TreeModel',tree);
const gameClient=project.tree.StarterPlayer.StarterPlayerScripts.PotionTycoon;
let view=readFileSync(gameClient.EnvironmentView.$path,'utf8').replaceAll('\r\n','\n');
view='local ForestOcclusion=require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.ForestOcclusion)\nlocal TreeLOD=require(game:GetService("ReplicatedStorage").PotionTycoon.Shared.ForestTreeLOD)\n'+view;
view=change(view,'else p.LocalTransparencyModifier=hidden and 1 or 0 end',
 'elseif p:GetAttribute("ForestOccluder")then local target=hidden and 1 or ForestOcclusion.target(p,camera);p.LocalTransparencyModifier+=math.clamp(target-p.LocalTransparencyModifier,-.4,.4) elseif p:GetAttribute("ForestUnderstory") then p.LocalTransparencyModifier=math.max(hidden and 1 or 0,TreeLOD.detailAlpha(detail,self.quality,(p.Position-camera.CFrame.Position).Magnitude)) else p.LocalTransparencyModifier=hidden and 1 or 0 end');
gameClient.EnvironmentView=output('EnvironmentView',view);
let sky=readFileSync(gameClient.SkyLandmark.$path,'utf8').replaceAll('\r\n','\n');
sky=change(sky,'local depth','local depth;local depthFactory;local depthAttempted=false');
sky=change(sky,'depth=Depth.create(folder,images.Cloud,Data.Cloud.crop)',
 'depthFactory=function()return Depth.create(folder,images.Cloud,Data.Cloud.crop)end');
sky=change(sky,'local enabled=depth and depth.update',`if not depthAttempted and quality~="minimal" and workspace:GetAttribute("SkyTreeDepthMode")=="R4" then
			depthAttempted=true
			task.spawn(function()
				local ok,result=pcall(depthFactory)
				if ok then if self.destroyed then result.destroy()else depth=result end else warn("FOREST_R4_FALLBACK",result)end
			end)
		end
		local enabled=depth and depth.update`);
gameClient.SkyLandmark=output('SkyLandmark',sky);
let cover=read('build/current-game-cover.server.luau');
cover=change(cover,oldRegion,newRegion);server.GroundCover=output('Cover.server',cover);
let grass=read('qa/dynamic-grass/Plan.luau');
grass=change(grass,'local P={maxPlants=320,grassLength=.24,seed=7604}',
 'local S=script.Parent\nlocal Forest=require(S.ForestLayout)\nlocal Plan=require(S.LandscapePlan)\nlocal P={maxPlants=300,grassLength=.24,seed=7604}');
grass=change(grass,'function P.protected(x,z,r,config)','function P.protected(x,z,r,config)\n\tif Forest.path(x,z,r)then return true end');
grass=change(grass,'function P.surface(x,z,config)',
 'function P.surface(x,z,config)\n\tif Forest.path(x,z,1)then return "Ground" end');
grass=change(grass,'local g=geometry[kind];local radius=g.radius*scale+.22',`local g=geometry[kind];local radius=g.radius*scale+.22
		for _,v in ipairs(Plan.cover)do
			local gap=math.min(radius,geometry[v[1]].radius*v[4])*.9
			if (x-v[2])^2+(z-v[3])^2<gap*gap then return end
		end`);
grass=change(grass,'ipairs(layout.trees)','ipairs(Plan.trees)');
grass=change(grass,'for i=1,14 do','for i=1,3 do');
grass=change(grass,'math.cos(a)*59*r,-8+math.sin(a)*53*r','math.cos(a)*Forest.rx*r,-8+math.sin(a)*Forest.rz*r');
shared.GrassPlan=output('Grass',grass);
project.tree.Workspace.Terrain.$properties.GrassLength=.24;
// R4's trunk cut exposes sky at the trunk. Keep the prototype available, but
// ordinary Play uses the intact approved R3 surface until R4 is repaired.
project.tree.Workspace.$attributes.SkyTreeDepthMode='R3';
let additions=read('build/landscape/additions.client.luau');
// Move only decorative water to the new eastern shore; no gameplay anchor moves.
additions=change(additions,'.create(root,O,Assets.uri("mist"))','.create(root,O+Vector3.new(28,0,0),Assets.uri("mist"))');
client.Additions=output('Additions.client',additions);
let checks=read('qa/current-game/Checks.server.luau');
checks=change(checks,'==124 and root:GetAttribute("IslandSurfaceDepth")==116','==Island.surface.width and root:GetAttribute("IslandSurfaceDepth")==Island.surface.depth');
server.CurrentGameChecks=output('Checks.server',checks);
project.name='PotionTycoon-Dense-Forest';project.tree.Workspace.$attributes.DenseForestQA=true;
const stats=JSON.parse(execFileSync(path('.tools/luau/luau'+(process.platform==='win32'?'.exe':'')),['scripts/forest-stats.luau'],{cwd:root,encoding:'utf8'}));
const sources=['qa/forest/Layout.luau','qa/forest/Occlusion.luau','qa/forest/Readiness.luau','qa/forest/LOD.luau','qa/forest/StaticLOD.luau',...files];
const codeSHA256=hash(Buffer.from(sources.map(f=>f+'\n'+read(f)).join('\n')));
project.tree.Workspace.$attributes.ForestCodeSHA256=codeSHA256;
const input='build/forest/game.project.json',artifact='build/PotionTycoon-Dense-Forest.rbxlx';
writeFileSync(path(input),JSON.stringify(project,null,2)+'\n');
execFileSync(path('.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),['build',path(input),'-o',path(artifact)],{stdio:'inherit'});
const bytes=readFileSync(path(artifact));
assert(bytes.includes('AG76 QA cannot access live persistence'));
const receipt={base:'2cbc8d5b970d086ffe41bd3081a39ac68b519107',head,owner:prior.owner,artifact,bytes:bytes.length,sha256:hash(bytes),codeSHA256,
 predecessorSHA256:prior.sha256,width:184,depth:172,...stats,editableMeshes:23,editableImages:3,decodedAtlasBytes:6291456,
 animatedTrees:{full:8,reduced:4,minimal:1},fixedMeshResources:24,experimentalR4PeakResources:30,maxConcurrentExpandableMeshes:1,
 worldTreeDefault:'R3',experimentalR4:'lazy, known trunk-hole defect retained for separate repair',staticLODPartsPerTree:2,
 newLights:0,additionalFrameLoops:0,studioOnly:true,memoryOnly:true,uploads:0,productionIntegrated:false,ownerArt:'PENDING'};
writeFileSync(path('build/forest/build.json'),JSON.stringify(receipt,null,2)+'\n');console.log(JSON.stringify(receipt,null,2));
