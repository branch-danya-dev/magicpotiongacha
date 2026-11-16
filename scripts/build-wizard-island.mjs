// Reproducible, separate art place. No production source or release project mutation.
import {readFileSync,writeFileSync,readdirSync,mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
import assert from 'node:assert/strict';
const root=resolve(import.meta.dirname,'..');
const path=p=>resolve(root,p),sha=p=>createHash('sha256').update(readFileSync(path(p))).digest('hex');
const read=p=>JSON.parse(readFileSync(path(p),'utf8'));
const receipt=read('assets/environment/woodland/receipt.json');
for(const [file,hash] of Object.entries(receipt.files)) assert.equal(sha('assets/environment/woodland/'+file),hash,file);
assert(receipt.license.startsWith('CC0'));
const source=readFileSync(path('qa/wizard-island/Scene.server.luau'),'utf8');
assert(!source.includes('WedgePart"'));
assert(!/DataStoreService|FireServer|RemoteEvent|UpdateAsync/.test(source));
const shared={$className:'Folder'};
for(const file of readdirSync(path('src/shared'),{withFileTypes:true})) {
 if(file.isDirectory()) shared[file.name]={$path:path('src/shared/'+file.name)};
 else if(file.name.endsWith('.luau')) shared[file.name.slice(0,-5)]={$path:path('src/shared/'+file.name)};
}
shared.EnvironmentBase=shared.EnvironmentConfig;
shared.EnvironmentConfig={$path:path('qa/wizard-island/EnvironmentConfig.luau')};
shared.AtmosphereStyleBase=shared.AtmosphereStyle;
shared.AtmosphereStyle={$path:path('qa/wizard-island/AtmosphereStyle.luau')};
const project={name:'WizardIsland-AG76B-R2-ART-PENDING',tree:{$className:'DataModel',
 ReplicatedStorage:{PotionTycoon:{$className:'Folder',Shared:shared}},
 ServerScriptService:{WizardScene:{$path:path('qa/wizard-island/Scene.server.luau')}},
 ServerStorage:{M7NatureTemplates:{$path:path('assets/environment/woodland/M7NatureTemplates.rbxmx')},SpellbookLectern:{$path:path('assets/props/SpellbookLectern.rbxmx')}},
 StarterPlayer:{$properties:{DevCameraOcclusionMode:'Zoom'},StarterPlayerScripts:{WizardReview:{$className:'Folder',Review:{$path:path('qa/wizard-island/Review.client.luau')},Cliff:{$path:path('qa/wizard-island/Cliff.luau')},EnvironmentView:{$path:path('src/client/EnvironmentView.luau')}}}},
 Workspace:{$properties:{StreamingEnabled:false,Gravity:196.2},$attributes:{WizardIslandArtOnly:true}},
 Lighting:{$properties:{Technology:'Future',LightingStyle:'Realistic',PrioritizeLightingQuality:true,ClockTime:17.65}}
}};
mkdirSync(path('build'),{recursive:true});
const input=path('build/wizard-island.project.json');writeFileSync(input,JSON.stringify(project,null,2)+'\n');
const output=path('build/WizardIsland-AG76B-R2-ART-PENDING.rbxlx');
const tool=n=>path('.tools/'+n+'/'+n+(process.platform==='win32'?'.exe':''));
execFileSync(tool('rojo'),['build',input,'-o',output],{stdio:'inherit'});
const xml=readFileSync(output,'utf8');
assert(!xml.includes('<string name="Name">Main</string>'),'Production bootstrap accidentally included');
const report={head:execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim(),artifact:output,sha256:createHash('sha256').update(xml).digest('hex'),
 sourceHashes:Object.fromEntries(['qa/wizard-island/Scene.server.luau','qa/wizard-island/Review.client.luau','qa/wizard-island/Cliff.luau','qa/wizard-island/AtmosphereStyle.luau','qa/wizard-island/EnvironmentConfig.luau','src/client/EnvironmentView.luau'].map(p=>[p,sha(p)])),
 source:'Original local Cliff.luau geometry plus existing owner-admitted CC0 Quaternius subset and licensed Spellbook; no uploads',
 originalGeometry:{source:'qa/wizard-island/Cliff.luau',runtime:'Studio client EditableMesh -> one MeshPart',vertices:3936,triangles:7868,uploaded:false},
 templates:{nature:sha('assets/environment/woodland/M7NatureTemplates.rbxmx'),lectern:sha('assets/props/SpellbookLectern.rbxmx')},
 runtimeScope:'Studio-only standalone art scene. No production integration, gameplay bootstrap or persistence.',ownerArtApproval:'PENDING'};
writeFileSync(path('build/wizard-island-build.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify(report,null,2));
