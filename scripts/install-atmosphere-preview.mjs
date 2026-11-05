// Local Studio content only. Does not upload assets or change permissions.
import {readFileSync,writeFileSync,copyFileSync,existsSync,mkdirSync,realpathSync} from 'node:fs';
import {resolve,dirname,basename} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const version=realpathSync(process.argv[2]);
assert(basename(version).startsWith('version-') && existsSync(resolve(version,'RobloxStudioBeta.exe')),'Pass an existing Studio version directory');
const content=realpathSync(resolve(version,'content'));
assert(content.startsWith(version+'\\') || content.startsWith(version+'/'),'Content path escapes selected Studio');
const pack=process.argv[3] || 'atmosphere';
assert(['atmosphere','polish'].includes(pack),'Unknown local asset pack');
const src=resolve(root,'assets/environment',pack);
const receipt=JSON.parse(readFileSync(resolve(src,'receipt.json')));
assert.match(receipt.local_prefix,/^rbxasset:\/\/m7a2[bc]-v[0-9]+\/$/);
const dest=resolve(content,receipt.local_prefix.slice(11,-1));
const hash=p=>createHash('sha256').update(readFileSync(p)).digest('hex');
for(const [name,expected] of Object.entries(receipt.files)) {
  assert.equal(basename(name),name); assert.equal(hash(resolve(src,name)),expected);
  if(existsSync(resolve(dest,name))) assert.equal(hash(resolve(dest,name)),expected,'Refusing to overwrite different local art');
}
mkdirSync(dest,{recursive:true});
assert.equal(realpathSync(dest),dest,'Destination symlink rejected');
for(const name of Object.keys(receipt.files)) if(!existsSync(resolve(dest,name))) copyFileSync(resolve(src,name),resolve(dest,name));
for(const [name,expected] of Object.entries(receipt.files)) assert.equal(hash(resolve(dest,name)),expected);
mkdirSync(resolve(root,'build'),{recursive:true});
writeFileSync(resolve(root,`build/${pack}-local-install.json`),JSON.stringify({destination:dest,files:receipt.files,permission:'local Studio read only; published experience access NOT verified'},null,2));
console.log('Verified local Studio art: '+dest);
