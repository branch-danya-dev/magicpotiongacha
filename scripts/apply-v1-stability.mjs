// P0 isolated Roblox Studio stability overlay for V1-03. Does not modify release source,
// production DataStore or historical profiles. All replacements fail on adapter drift.
import assert from "node:assert/strict";
const once=(s,a,b,reason)=>{
 const parts=s.split(a);
 assert.equal(parts.length,2,"V1 Studio stability drift: "+reason);
 return parts.join(b);
};
export function applyStudioStability({project,read,write,path}){
 const shared=project.tree.ReplicatedStorage.PotionTycoon.Shared;
 const server=project.tree.ServerScriptService.PotionTycoon;
 const client=project.tree.StarterPlayer.StarterPlayerScripts.PotionTycoon;
 const workspace=project.tree.Workspace.$attributes;
 // Runtime uses static forest silhouettes at stable transparency, not a skinned/static
 // switch triggered by camera position. The high-detail rig stays in the art source.
 shared.ForestTreeLOD={$path:path("qa/stability/StableLOD.luau")};
 shared.ForestOcclusion={$path:path("qa/stability/StableOcclusion.luau")};
 shared.V1CollisionPlan={$path:path("qa/stability/CollisionPlan.luau")};
 server.V1Colliders={$path:path("qa/stability/Colliders.luau")};

 // No invented starter pet: skip UI and claim a valid QA-only no-choice profile.
 let config=read(shared.Config.$path);
 config=once(config,
  'Config.alchemyV1QA=true',
  'Config.stabilitySkipStarterQA=true\nConfig.alchemyV1QA=true',
  "explicit QA policy switch");
 shared.Config=write("Config",config);
 let factory=read(shared.Factory.$path);
 factory=once(factory,
  '\t\telse\n\t\t\tlocal definition = starterDefinition(starter.choice)\n\t\t\tlocal pet = definition and profile.pets[starterPetId(profile.userId, definition)]\n\t\t\tif not pet or pet.species ~= starter.choice or pet.provenance.source ~= "starter" then\n\t\t\t\treturn false, "Invalid starter marker"\n\t\t\tend\n\t\t\tfor _, other in ipairs(config.starterPets) do\n\t\t\t\tif other.species ~= starter.choice and profile.pets[starterPetId(profile.userId, other)] then\n\t\t\t\t\treturn false, "Invalid starter marker"\n\t\t\t\tend\n\t\t\tend\n\t\tend\n\t\tif not exactKeys(profile.workforce',
  '\t\telse\n'+
  '\t\t\tif not (config.stabilitySkipStarterQA and starter.choice==nil and starter.claimed==true) then\n'+
  '\t\t\t\tlocal definition = starterDefinition(starter.choice)\n'+
  '\t\t\t\tlocal pet = definition and profile.pets[starterPetId(profile.userId, definition)]\n'+
  '\t\t\t\tif not pet or pet.species ~= starter.choice or pet.provenance.source ~= "starter" then\n'+
  '\t\t\t\t\treturn false, "Invalid starter marker"\n'+
  '\t\t\t\tend\n'+
  '\t\t\t\tfor _, other in ipairs(config.starterPets) do\n'+
  '\t\t\t\t\tif other.species ~= starter.choice and profile.pets[starterPetId(profile.userId, other)] then\n'+
  '\t\t\t\t\t\treturn false, "Invalid starter marker"\n'+
  '\t\t\t\t\tend\n'+
  '\t\t\t\tend\n'+
  '\t\t\tend\n'+
  '\t\tend\n\t\tif not exactKeys(profile.workforce',
  "QA skips starter selection without fabricating a familiar");
 factory=once(factory,
  '\tfunction engine.claimStarterBudget(profile)',
  '\t-- Preserves all owned pets. New local QA sessions can proceed without picking one.\n'+
  '\tfunction engine.deferStarter(profile)\n'+
  '\t\tif not config.stabilitySkipStarterQA or not AlchemyFirst.active(config,profile) then return false end\n'+
  '\t\tif profile.starter.claimed then return true end\n'+
  '\t\tprofile.starter.claimed=true\n'+
  '\t\tprofile.tutorial.familiar=true\n'+
  '\t\tprofile.tutorial.workers=true\n'+
  '\t\treturn true\n'+
  '\tend\n\n'+
  '\tfunction engine.claimStarterBudget(profile)',
  "server-only skip without pet grant");
 shared.Factory=write("Factory",factory);
 let main=read(server.Main.$path);
 main=once(main,
  '\tFactory.claimStarterBudget(profile)',
  '\tFactory.claimStarterBudget(profile)\n'+
  '\tif Config.stabilitySkipStarterQA then Factory.deferStarter(profile) end\n'+
  '\tassert(Factory.validate(profile),"Invalid QA profile after starter deferral")',
  "authenticated profile load skips starter before first snapshot");
 server.Main=write("Main.server",main);
 workspace.AG75StarterCardsEnabled=false;
 workspace.V1NoMandatoryStarter=true;
 workspace.V1StableForest=true;
 workspace.V1SkyCloudFallback=true;

 let island=read(server.PersonalIslandWorld.$path);
 island=once(island,
  '\tArt.attach(self.root,plot)\n\trequire(script.Parent.AlchemyStarterProps).attach(plot)',
  '\tArt.attach(self.root,plot)\n'+
  '\trequire(script.Parent.V1Colliders).attach(self.root,plot)\n'+
  '\trequire(script.Parent.AlchemyStarterProps).attach(plot)',
  "colliders added on server before owner activation");
 server.PersonalIslandWorld=write("PersonalIslandWorld",island);

 // Quality/debug feature flag does not erase rigs from the repository; it only
 // stabilizes the actual Studio scene. Every LOD tree has a visible static mesh.
 let sky=read(client.SkyLandmark.$path);
 sky=once(sky,
  'for i,b in ipairs(Model.ocean(Config))do',
  'for i,b in ipairs({})do -- P0: no overlapping huge billboard cloud sheets',
  "suppress billboard sky ocean planes");
 sky=once(sky,
  'local cloudAlpha=oceanEnabled and current.cloud*Config.cloud.density*Config.cloud.opacity or 0',
  'local cloudAlpha=0 -- Native Terrain.Clouds owns cover; no black alpha gaps',
  "native cloud fallback");
 sky=once(sky,
  'set("AtmosphericHaze",current.haze*Config.haze.opacity*layered,oceanColor)',
  'set("AtmosphericHaze",0,oceanColor)',
  "avoid huge haze overlay at night");
 client.SkyLandmark=write("SkyLandmark",sky);

 let view=read(client.EnvironmentView.$path);
 view=once(view,
  'local horizonMode="candidate"',
  'local horizonMode="baseline" -- reported candidate caused horizon wedge',
  "restore known atmosphere offset from QA candidate");
 view=once(view,
  'local moon=celestialSprite("Moon",Assets.uri("moon"),Vista.moonSize,Vector3.new(0,1,0))',
  'local moon=celestialSprite("Moon",Assets.uri("moon"),Vista.moonSize,Vector3.new(0,1,0))\n'+
  '\tlocal stableMoonTarget=moon.attachment.Position',
  "retain moon position for continuous frame interpolation");
 view=once(view,
  'step+=dt; lod+=dt; labelsDirty+=dt; if step<1/30 then return end; local elapsed=step; step=0',
  'step+=dt; lod+=dt; labelsDirty+=dt\n'+
  '\t\tmoon.attachment.Position=moon.attachment.Position:Lerp(stableMoonTarget,1-math.exp(-math.clamp(dt,0,.1)*14))\n'+
  '\t\tif step<1/30 then return end; local elapsed=step; step=0',
  "render-frequency moon smoothing without extra frame connection");
 view=once(view,
  'moon.attachment.Position=Vector3.new(table.unpack(State.moon(sample.phase)))*Config.celestial.distance',
  'stableMoonTarget=Vector3.new(table.unpack(State.moon(sample.phase)))*Config.celestial.distance',
  "moon moves toward continuously interpolated target");
 view=once(view,
  'clouds.Cover=sample.cover; clouds.Density=sample.cloudDensity; clouds.Color=color(sample.cloudColor)',
  'clouds.Cover=sample.cover; clouds.Density=sample.cloudDensity\n'+
  '\t\tclouds.Color=color(sample.cloudColor):Lerp(Color3.fromRGB(161,175,200),math.clamp(sample.night,0,1)*.55)',
  "native clouds remain softly moonlit at night");
 client.EnvironmentView=write("EnvironmentView",view);

 // Collision for visual-only props while preserving the intentional walkable soil.
 let props=read(server.AlchemyStarterProps.$path);
 props=once(props,
  'p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false',
  'p.CanCollide=name=="ExtractorBoiler" or name=="BrewingCube";p.CanTouch=false;p.CanQuery=p.CanCollide;p.CastShadow=false',
  "non-colliding QA equipment becomes solid");
 server.AlchemyStarterProps=write("Props",props);
 project.name="PotionTycoon-V1-03-Stable-Studio";
}
