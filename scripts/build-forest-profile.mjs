// Adds only a bounded opt-in measurement harness to the already built candidate.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {resolve} from 'node:path';
import {execFileSync} from 'node:child_process';
const root=resolve(import.meta.dirname,'..'),path=p=>resolve(root,p);
const label=process.argv[2];if(!['Baseline','Candidate'].includes(label))throw Error('Baseline or Candidate required');
const project=JSON.parse(readFileSync(path('build/forest/game.project.json')));
project.tree.ReplicatedStorage.PotionTycoon.Shared.ForestPerfStats={$path:path('qa/forest/PerfStats.luau')};
project.tree.StarterPlayer.StarterPlayerScripts.ForestPerformance={$path:path('qa/forest/Profile.client.luau')};
mkdirSync(path('build/forest-p0'),{recursive:true});
const input=path(`build/forest-p0/${label}.project.json`),out=path(`build/PotionTycoon-Forest-P0-${label}.rbxlx`);
writeFileSync(input,JSON.stringify(project,null,2));
execFileSync(path('.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),['build',input,'-o',out],{stdio:'inherit'});
