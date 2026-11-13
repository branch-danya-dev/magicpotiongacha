// Isolated full-game art preview: default project and production modules stay intact.
import {readFileSync,writeFileSync,mkdirSync,readdirSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const project=JSON.parse(readFileSync(resolve(root,'default.project.json'),'utf8'));
function absolute(node){if(node&&typeof node==='object') for(const [k,v] of Object.entries(node)){if(k==='$path')node[k]=resolve(root,v);else absolute(v);}}
absolute(project);project.name='AG67 Art Prototype';
const client={$className:'Folder'};
for(const entry of readdirSync(resolve(root,'src/client'),{withFileTypes:true})) {
 const name=entry.name.replace(/(?:\.client|\.server)?\.luau$/,'');
 client[name]={$path:resolve(root,'src/client',entry.name)};
}
client.LegacySpellbookEffects=client.SpellbookEffects;
client.SpellbookEffects={$path:resolve(root,'qa/ag67/Adapter.luau')};
client.AG67={$className:'Folder',Policy:{$path:resolve(root,'qa/ag67/Policy.luau')},View:{$path:resolve(root,'qa/ag67/View.luau')}};
project.tree.StarterPlayer.StarterPlayerScripts.PotionTycoon=client;
project.tree.Workspace.$attributes.AG67SoulPreview=false;
mkdirSync(resolve(root,'build'),{recursive:true});
writeFileSync(resolve(root,'build/ag67.project.json'),JSON.stringify(project,null,2)+'\n');
const result=spawnSync(resolve(root,'.tools/rojo/rojo'+(process.platform==='win32'?'.exe':'')),['build','build/ag67.project.json','-o','build/AG67-Prototype.rbxlx'],{cwd:root,encoding:'utf8'});
console.log(result.stdout);if(result.error)throw result.error;if(result.status!==0){console.error(result.stderr);process.exit(result.status||1);}
