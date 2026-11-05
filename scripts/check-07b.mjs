// Current derived package, independently compared to the immutable admitted XML.
import {readFileSync,readdirSync} from 'node:fs';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const read=p=>readFileSync(p,'utf8').replaceAll('\r\n','\n');
const sha=b=>createHash('sha256').update(b).digest('hex');
const dir='assets/environment/woodland/',base='assets/environment/megakit/';
const receipt=JSON.parse(read(dir+'receipt.json'));
assert.equal(receipt.parent_receipt_sha256,sha(readFileSync(base+'receipt.json')));
assert.equal(receipt.parent_templates_sha256,sha(readFileSync(base+'M7NatureTemplates.rbxmx')));
assert.equal(receipt.source_archive_sha256,'298f6732b872e4cf7b30e6e7abf9641c7f6dc6b326df37ac089533ed7e3d58c9');
assert(receipt.license.startsWith('CC0-1.0')); assert.equal(receipt.newMeshAssets,0); assert.equal(receipt.newTextureBytes,0);
assert.equal(sha(read(receipt.generator)),receipt.generator_sha256);
assert.equal(sha(read(receipt.geometry)),receipt.geometry_sha256);
assert.deepEqual(readdirSync(dir).sort(),[...Object.keys(receipt.files),'receipt.json'].sort());
for(const [p,h] of Object.entries(receipt.files)) assert.equal(sha(readFileSync(dir+p)),h,p);
const original=read(base+'M7NatureTemplates.rbxmx'),derived=read(dir+'M7NatureTemplates.rbxmx');
const normalize=s=>s.replace(/<(bool|float|token) name="(CastShadow|Transparency|RenderFidelity)">[^<]*<\/\1>/g,'').replace(/>\s+</g,'><').trim();
assert.equal(normalize(derived),normalize(original),'Only three explicit presentation properties may differ');
const props=xml=>[...xml.matchAll(/<Item class="MeshPart"[^>]*>\s*<Properties>([\s\S]*?)<\/Properties>/g)].map(m=>m[1]);
const name=p=>p.match(/<string name="Name">([^<]+)<\/string>/)[1];
const value=(p,key)=>p.match(new RegExp(`<[^ >]+ name="${key}">([^<]+)<`))?.[1];
const source=new Map(props(original).map(p=>[name(p),p]));
let alpha=0;
for(const p of props(derived)) {
  const n=name(p),old=source.get(n); assert(old,n);
  const leaf=/^(CommonTree_[135]|Pine_2|TwistedTree_1)_2$|^(Bush_Common_Flowers|Clover_2|Fern_1|Flower_3_Group)_/.test(n);
  for(const key of ['CastShadow','Transparency','RenderFidelity']) {
    assert.equal(value(p,key),leaf?({CastShadow:'false',Transparency:'0.02',RenderFidelity:'1'})[key]:value(old,key),n+'/'+key);
  }
  if(leaf) alpha++;
  assert.equal(value(p,'CanCollide'),'false'); assert.equal(value(p,'CanQuery'),'false'); assert.equal(value(p,'CanTouch'),'false');
}
assert.equal(alpha,11); assert.equal(source.size,21);
for(const path of ['default.project.json','qa/environment.project.json']) assert(read(path).includes('assets/environment/woodland/M7NatureTemplates.rbxmx'));
const audit=JSON.parse(read(dir+'inspection.json'));
assert.equal(Object.keys(audit.models).length,14);
for(const m of Object.values(audit.models)) assert.equal(m.exactDuplicateTriangles,0);
for(const [p,t] of Object.entries(audit.textures)) assert.equal(sha(readFileSync(base+'prepared/'+p)),t.sha256);
// The active forest must clone the admitted canopy; never a hidden fallback sphere.
const art=read('src/server/ForestArt.luau');
assert(!/Instance\.new\("(?:Part|SpecialMesh)"\)|MeshId\s*=|TextureID\s*=|HttpService|loadstring/.test(art));
assert(art.includes('model=source:Clone()')); assert(art.includes('ForestCanopy'));
console.log('07B integrity PASS: 14 existing CC0 models, exact mesh/map/ID preservation, 11 bounded smooth-alpha parts; native Low/Automatic NOT VERIFIED');
