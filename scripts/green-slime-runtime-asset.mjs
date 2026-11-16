// Derive the runtime template from the real native export; no asset uploads.
import {readFileSync, writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
export const folder = 'assets/familiars/green_slime/';
export const sha = bytes => createHash('sha256').update(bytes).digest('hex');
const frame = (name,x=0,y=0,z=0) => `<CoordinateFrame name="${name}"><X>${x}</X><Y>${y}</Y><Z>${z}</Z><R00>1</R00><R01>0</R01><R02>0</R02><R10>0</R10><R11>1</R11><R12>0</R12><R20>0</R20><R21>0</R21><R22>1</R22></CoordinateFrame>`;
export function normalize(raw) {
  let xml=raw.replaceAll('\r\n','\n');
  assert.equal((xml.match(/class="MeshPart"/g)||[]).length,1);
  assert.equal((xml.match(/class="Bone"/g)||[]).length,8);
  assert(!/class="(?:Script|LocalScript|ModuleScript)"/.test(xml));
  // FBX importer metadata is not a runtime dependency; remove complete Folder subtrees.
  while(xml.includes('<Item class="Folder"')) {
    const begin=xml.indexOf('<Item class="Folder"'); let depth=0, end=-1;
    for(const token of xml.slice(begin).matchAll(/<Item\b[^>]*>|<\/Item>/g)) {
      depth+=token[0].startsWith('</')?-1:1;
      if(depth===0){end=begin+token.index+token[0].length;break;}
    }
    assert(end>begin); xml=xml.slice(0,begin)+xml.slice(end);
  }
  xml=xml.replace('<string name="Name">GreenSlime_Rig</string>','<string name="Name">GreenSlime</string>')
    .replace(/<Ref name="PrimaryPart">[^<]*<\/Ref>/,'<Ref name="PrimaryPart">AG74Proxy</Ref>');
  xml=xml.replace(/(<Item class="MeshPart"[^>]*>\s*<Properties>)([\s\S]*?)(<\/Properties>)/,(_,a,p,b)=>{
    for(const name of ['CanCollide','CanTouch','CanQuery','CastShadow']) p=p.replace(new RegExp(`(<bool name="${name}">)[^<]+`),'$1false');
    p=p.replace(/(<bool name="Massless">)[^<]+/,'$1true');
    p=p.replace(/<CoordinateFrame name="CFrame">[\s\S]*?<\/CoordinateFrame>/,frame('CFrame',0,0.290924847,0));
    p=p.replace(/<CoordinateFrame name="PivotOffset">[\s\S]*?<\/CoordinateFrame>/,frame('PivotOffset'));
    // White tint preserves the original PNG; Studio imported a neutral-grey tint.
    p=p.replace(/(<Color3uint8 name="Color3uint8">)[^<]+/,'$14294967295');
    return a+p+b;
  });
  xml=xml.replace(/(<Item class="AnimationController"[^>]*>\s*<Properties>[\s\S]*?<\/Properties>)/,'$1\n<Item class="Animator" referent="AG74Animator"><Properties><string name="Name">Animator</string></Properties></Item>');
  const proxy=`<Item class="Part" referent="AG74Proxy"><Properties><string name="Name">VisualProxy</string>${frame('CFrame')}<Vector3 name="size"><X>2.8</X><Y>0.6</Y><Z>2.5</Z></Vector3><bool name="Anchored">true</bool><bool name="CanCollide">false</bool><bool name="CanTouch">false</bool><bool name="CanQuery">false</bool><bool name="CastShadow">false</bool><float name="Transparency">1</float></Properties></Item>`;
  const end=xml.lastIndexOf('</Item>'); assert(end>0); xml=xml.slice(0,end)+proxy+'\n'+xml.slice(end);
  return xml;
}
if(process.argv.includes('--write')) {
  const raw=readFileSync(folder+'GreenSlime.imported.rbxmx');
  const xml=normalize(raw.toString()); writeFileSync(folder+'GreenSlime.rbxmx',xml);
  console.log('AG74 runtime template '+sha(xml));
}
