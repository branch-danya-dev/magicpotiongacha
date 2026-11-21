// Self-contained audit of the CURRENT V1-03 source chain, with an optional
// artifact/owner/sky-reconstruction check after build. Uses Node standard lib only.
import assert from "node:assert/strict";
import {existsSync,readFileSync} from "node:fs";
import {resolve,dirname} from "node:path";
import {fileURLToPath} from "node:url";
import {execFileSync} from "node:child_process";
import {createHash} from "node:crypto";
const root=resolve(dirname(fileURLToPath(import.meta.url)),"..");
const file=p=>resolve(root,p);
const read=p=>readFileSync(file(p),"utf8");
const exists=p=>assert(existsSync(file(p)),"Missing V1 handoff source: "+p);
const files=[
 "CLAUDE.md","docs/CURRENT_V1_03_HANDOFF.md","AGENTS.md","README.md",
 "src/shared/Factory.luau","src/shared/Config.luau","src/server/Main.server.luau",
 "scripts/build-alchemy-first.mjs","scripts/build-forest.mjs",
 "scripts/apply-v1-garden.mjs","scripts/apply-v1-garden-ui.mjs",
 "scripts/apply-v1-alchemy.mjs","scripts/apply-v1-stability.mjs",
 "scripts/check-v1-sky-restore.mjs",
 "qa/alchemy/Policy.luau","qa/garden/Catalog.luau",
 "qa/garden/GardenV1.luau","qa/garden/run.luau",
 "qa/alchemy_v1/Catalog.luau","qa/alchemy_v1/AlchemyV1.luau",
 "qa/alchemy_v1/PotionBook.client.luau","qa/alchemy_v1/run.luau",
 "qa/stability/CollisionPlan.luau","qa/stability/Colliders.luau",
 "qa/stability/StableLOD.luau","qa/stability/StableOcclusion.luau",
 "qa/stability/run.luau","qa/sky-landmark/SkyLandmark.luau",
 "qa/forest/Layout.luau","qa/lunar/Cycle.luau",
 "assets/props/spellbook-lectern.glb",
 "assets/familiars/green_slime/GreenSlime.rbxmx"
];
for(const p of files)exists(p);

const builder=read("scripts/build-alchemy-first.mjs");
const order=[
 "applyGardenV1({project,read,write,path});",
 "applyAlchemyV1({project,read,write,path});",
 "applyStudioStability({project,read,write,path});"
];
let prev=0;
for(const marker of order){
 const index=builder.indexOf(marker);
 assert(index>prev,"Build order drift: "+marker);
 assert.equal(builder.indexOf(marker,index+marker.length),-1,"Overlay applied twice: "+marker);
 prev=index;
}
assert(builder.includes("const ownerArg=process.argv.find(a=>a.startsWith('--owner-user-id='))"),"Owner must be explicit");
assert(builder.includes("Studio memory mode"),"Must keep Studio-only behavior documented");
assert(builder.includes("build/PotionTycoon-Alchemy-First-QA.rbxlx"),"V1 artifact path changed unexpectedly");

const stable=read("scripts/apply-v1-stability.mjs");
assert(stable.includes("stabilitySkipStarterQA"),"No mandatory-starter QA policy");
assert(stable.includes("V1Colliders"),"No server collision proxies");
assert(stable.includes("V1SkyBackdropRestored"),"Restored sky QA flag missing");
assert(!stable.includes("'local cloudAlpha=0 -- Native Terrain.Clouds owns cover; no black alpha gaps'"),"The deleted-cloud P0 regression reappeared");
assert(!stable.includes("'for i,b in ipairs({})do -- P0: no overlapping huge billboard cloud sheets'"),"The deleted-bank P0 regression reappeared");

const baseProject=JSON.parse(read("default.project.json"));
assert(!baseProject.tree.Workspace?.$attributes?.AlchemyV1QA,
 "Release default.project.json unexpectedly points at Studio QA; manual gate required");
const pkg=JSON.parse(read("package.json"));
assert(pkg.scripts?.test==="node scripts/check.mjs","Inherited CI runner changed");
assert(pkg.scripts?.["handoff:verify"]==="node scripts/verify-handoff.mjs",
 "Missing handoff self-check command");
const lock=JSON.parse(read("tools.lock.json"));
assert.equal(lock.rojo.version,"7.7.1");
assert.equal(lock.luau.version,"0.745");

let result={source:"OK",base:"V1-03 + P0 + R3 backdrop",overlayOrder:order};
if(process.argv.includes("--built")){
 exists("build/alchemy/game.project.json");
 exists("build/alchemy/build.json");
 const project=JSON.parse(read("build/alchemy/game.project.json"));
 const receipt=JSON.parse(read("build/alchemy/build.json"));
 const attr=project.tree.Workspace?.$attributes;
 for(const key of ["AlchemyFirstQA","GardenV1QA","AlchemyV1QA","V1NoMandatoryStarter","V1StableForest","V1SkyBackdropRestored"]){
  assert.equal(attr?.[key],true,"Missing active V1 QA flag: "+key);
 }
 assert.equal(attr?.V1SkyCloudFallback,false);
 assert.equal(attr?.AG76QAOwnerUserId,receipt.owner,"Owner stamp disagrees with receipt");
 assert.equal(receipt.studioOnly,true);
 assert.equal(receipt.memoryOnly,true);
 assert.equal(receipt.mainOrLiveIntegrated,false);
 assert.equal(receipt.paidFeatures,false);
 assert.equal(receipt.stabilityP0?.backdropRestored,true);
 assert.equal(receipt.stabilityP0?.noMandatoryStarter,true);
 assert.equal(receipt.alchemyV1?.recipes,4);
 assert.equal(receipt.alchemyV1?.classes,6);
 assert.deepEqual(receipt.gardenV1?.cropSpecies,["mandrake","antarctic_biter"]);
 const head=execFileSync("git",["rev-parse","HEAD"],{cwd:root,encoding:"utf8"}).trim();
 assert.equal(receipt.head,head,"Artifact built from another Git SHA");
 exists(receipt.artifact);
 const hash=createHash("sha256").update(readFileSync(file(receipt.artifact))).digest("hex");
 assert.equal(hash,receipt.sha256,"Rojo artifact differs from SHA-256 receipt");
 const sky=project.tree.StarterPlayer.StarterPlayerScripts.PotionTycoon.SkyLandmark?.$path;
 assert(sky,"SkyLandmark absent from built place");
 const script=read(sky);
 assert(script.includes("Model.ocean(Config)"),"Original R3 CloudOcean absent");
 assert(script.includes('set("CloudOcclusion",cloudAlpha,oceanColor)'),"Primary clouds missing");
 assert(script.includes('set("AtmosphericHaze",current.haze*Config.haze.opacity*layered,oceanColor)'),"Original haze missing");
 const environment=project.tree.StarterPlayer.StarterPlayerScripts.PotionTycoon.EnvironmentView?.$path;
 assert(environment,"EnvironmentView absent");
 assert(read(environment).includes("stableMoonTarget=moonDirection*Config.celestial.distance"),
  "Moon direction changed away from original Lighting controller");
 result={...result,sourceSha:head,owner:receipt.owner,artifact:receipt.artifact,sha256:hash,game:"OK"};
}
console.log(JSON.stringify(result,null,2));
