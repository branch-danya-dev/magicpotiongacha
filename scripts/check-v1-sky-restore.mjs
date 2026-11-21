// Prevent the P0 "black void" regression: preserve ALL authored R3 sky layers.
// This checks the actual generated Rojo inputs, not only the source overlay.
import assert from "node:assert/strict";
import {readFileSync} from "node:fs";
import {resolve} from "node:path";
const root=resolve(import.meta.dirname,"..");
const read=p=>readFileSync(resolve(root,p),"utf8");
const project=JSON.parse(read("build/alchemy/game.project.json"));
const client=project.tree.StarterPlayer.StarterPlayerScripts.PotionTycoon;
assert.equal(project.tree.Workspace.$attributes.V1SkyBackdropRestored,true);
assert.equal(project.tree.Workspace.$attributes.V1SkyCloudFallback,false);
const sky=read(client.SkyLandmark.$path);
const view=read(client.EnvironmentView.$path);
for(const [label,re] of [
 ["all authored banks",/for i,b in ipairs\(Model\.ocean\(Config\)\)do/],
 ["weather-driven cloud opacity",/local cloudAlpha=oceanEnabled and current\.cloud\*Config\.cloud\.density\*Config\.cloud\.opacity or 0/],
 ["primary CloudOcclusion",/set\("CloudOcclusion",cloudAlpha,oceanColor\)/],
 ["AtmosphericHaze",/set\("AtmosphericHaze",current\.haze\*Config\.haze\.opacity\*layered,oceanColor\)/],
 ["CloudBank graphics",/Name="CloudBank"\.\.i/],
 ["ocean billboard texture",/Name="CloudMass"/],
]){
 assert(re.test(sky),"Lost original sky component: "+label);
}
for(const [label,re] of [
 ["original horizon mode",/local horizonMode="candidate"/],
 ["continuous moon target using original direction",/stableMoonTarget=moonDirection\*Config\.celestial\.distance/],
 ["per-frame moon interpolation",/moon\.attachment\.Position=moon\.attachment\.Position:Lerp\(stableMoonTarget/],
 ["native cloud lighting source",/clouds\.Cover=sample\.cover; clouds\.Density=sample\.cloudDensity; clouds\.Color=color\(sample\.cloudColor\)/],
]){
 assert(re.test(view),"Lost original environment behavior: "+label);
}
for(const forbidden of [
 "local cloudAlpha=0",
 "for i,b in ipairs({})do",
 'set("AtmosphericHaze",0,oceanColor)',
 'local horizonMode="baseline"',
 "stableMoonTarget=Vector3.new(table.unpack(State.moon(sample.phase)))",
]){assert(!sky.includes(forbidden)&&!view.includes(forbidden),"Regressive sky replacement present: "+forbidden)}
const receipt=JSON.parse(read("build/alchemy/build.json"));
assert.equal(receipt.stabilityP0.backdropRestored,true);
assert.equal(receipt.stabilityP0.noMandatoryStarter,true);
assert.equal(receipt.stabilityP0.physicalTreeColliders,true);
assert.equal(receipt.stabilityP0.persistentStaticForest,true);
console.log("PASS V1-03 sky restoration: 7 authored banks, cloud layers/haze, original horizon/direction, P0 gameplay intact");
