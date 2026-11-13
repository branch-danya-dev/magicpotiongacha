// Local, reversible content installation only. Never uploads assets or changes permissions.
import {readFileSync,writeFileSync,copyFileSync,existsSync,mkdirSync,realpathSync} from 'node:fs';
import {resolve,dirname,basename,sep} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
assert(process.argv[2],'Pass the directory of the installed RobloxStudioBeta.exe');
const version=realpathSync(process.argv[2]);
assert(basename(version).startsWith('version-')&&existsSync(resolve(version,'RobloxStudioBeta.exe')),'Not a Studio version');
const content=realpathSync(resolve(version,'content'));assert(content.startsWith(version+sep),'Content escapes Studio');
const source=resolve(root,'assets/vfx/ag67');const manifest=JSON.parse(readFileSync(resolve(source,'manifest.json'),'utf8'));
assert.equal(manifest.localPrefix,'rbxasset://ag67-soul-v2/');assert.equal(manifest.publishedAssetIds.length,0);
const dest=resolve(content,'ag67-soul-v2');const files=Object.entries(manifest.files).filter(([n])=>n.endsWith('.png')&&!n.startsWith('SoulAbsorption'));
const hash=p=>createHash('sha256').update(readFileSync(p)).digest('hex');
for(const [name,expected] of files){assert.equal(basename(name),name);assert.equal(hash(resolve(source,name)),expected);if(existsSync(resolve(dest,name)))assert.equal(hash(resolve(dest,name)),expected,'Refusing to overwrite changed local art');}
mkdirSync(dest,{recursive:true});assert.equal(realpathSync(dest),dest,'Symlink rejected');
for(const [name,expected] of files){if(!existsSync(resolve(dest,name)))copyFileSync(resolve(source,name),resolve(dest,name));assert.equal(hash(resolve(dest,name)),expected);}
mkdirSync(resolve(root,'build'),{recursive:true});writeFileSync(resolve(root,'build/ag67-local-install.json'),JSON.stringify({destination:dest,files:Object.fromEntries(files),scope:'Local Studio only; no Roblox asset upload or experience access grant'},null,2));
console.log('Verified AG67 local textures: '+dest);
