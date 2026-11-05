"""Extract the inspected Studio import into inert, grounded Rojo templates.

Usage: python scripts/admit-environment-assets.py IMPORT.rbxlx PREPARED_DIR
No network calls, dynamic asset loading, scripts, or invented Roblox IDs.
"""
import copy, hashlib, json, math, shutil, struct, sys
import xml.etree.ElementTree as ET
from pathlib import Path

root = Path(__file__).resolve().parents[1]
scene_path, prepared = map(Path, sys.argv[1:])
report = json.loads((prepared/'preparation.json').read_text())
scene = ET.parse(scene_path).getroot()
dest = root/'assets/environment/megakit'
dest.mkdir(parents=True, exist_ok=True)
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def prop(item, name): return item.find(f'Properties/*[@name="{name}"]')
def name(item): return prop(item, 'Name').text
library = next(i for i in scene.iter('Item') if i.get('class')=='Model' and name(i)=='Scene')
assert len(library.findall('Item')) == 14
allowed = {'Model','MeshPart','SurfaceAppearance'}
assert all(i.get('class') in allowed for i in library.iter('Item'))
output = ET.Element('roblox', {'version':'4'})
folder = ET.SubElement(output,'Item',{'class':'Folder','referent':'M7Templates'})
fp=ET.SubElement(folder,'Properties'); ET.SubElement(fp,'string',{'name':'Name'}).text='M7NatureTemplates'
receipt={'source_archive_sha256':report['source_archive_sha256'],
    'license':'CC0-1.0 / License_Standard.txt',
    'workflow':'Owner-approved direct static inspection, Blender optimization, Studio importer; not a game-dev receipt',
    'studio_import_sha256':sha(scene_path),'models':[], 'files':{}}
serial=0
for source_model in library.findall('Item'):
    model_name=name(source_model)
    entry=next(m for m in report['models'] if m['name']==model_name)
    parts=[i for i in source_model.iter('Item') if i.get('class')=='MeshPart']
    boxes=[]
    for p in parts:
        cf=prop(p,'CFrame'); size=prop(p,'size')
        assert all(abs(float(cf.findtext(f'R{i}{j}'))-(1 if i==j else 0))<1e-5 for i in range(3) for j in range(3))
        boxes.append(([float(cf.findtext(k)) for k in 'XYZ'],[float(size.findtext(k)) for k in 'XYZ']))
    lo=[min(c[k]-s[k]/2 for c,s in boxes) for k in range(3)]
    hi=[max(c[k]+s[k]/2 for c,s in boxes) for k in range(3)]
    pivot=[(lo[0]+hi[0])/2,lo[1],(lo[2]+hi[2])/2]
    assert abs(hi[1]-lo[1]-entry['height_studs'])<.5,(model_name,hi,lo)
    model=ET.SubElement(folder,'Item',{'class':'Model','referent':model_name})
    mp=ET.SubElement(model,'Properties'); ET.SubElement(mp,'string',{'name':'Name'}).text=model_name
    record={'name':model_name,'triangles':entry['triangles_after'],'parts':[]}
    for index,(original,(center,size)) in enumerate(zip(parts,boxes)):
        serial+=1; item=ET.SubElement(model,'Item',{'class':'MeshPart','referent':f'M7Mesh{serial}'})
        props=ET.SubElement(item,'Properties')
        for key in ('MeshId','TextureID','size','InitialSize','CFrame'):
            props.append(copy.deepcopy(prop(original,key)))
        for k,offset in zip('XYZ',pivot): props.find(f'CoordinateFrame/{k}').text=str(center['XYZ'.index(k)]-offset)
        ET.SubElement(props,'string',{'name':'Name'}).text=f'{model_name}_{index+1}'
        for key,val in {'Anchored':True,'CanCollide':False,'CanTouch':False,'CanQuery':False,'DoubleSided':True,'CastShadow':True}.items():
            ET.SubElement(props,'bool',{'name':key}).text=str(val).lower()
        ET.SubElement(props,'Color3uint8',{'name':'Color3uint8'}).text='4294967295'
        ET.SubElement(props,'token',{'name':'CollisionFidelity'}).text='2'
        # Preserve thin path geometry. Precise=1 is set in the Studio template;
        # runtime scripts cannot write this property.
        if model_name=='RockPath_Round_Small_1':
            ET.SubElement(props,'token',{'name':'RenderFidelity'}).text='1'
        surface=original.find('Item[@class="SurfaceAppearance"]')
        assert surface is not None, (model_name,'Studio alpha/material validation required')
        sa=ET.SubElement(item,'Item',{'class':'SurfaceAppearance','referent':f'M7Surface{serial}'})
        sp=ET.SubElement(sa,'Properties')
        for key in ('AlphaMode','ColorMap','NormalMap'):
            value=prop(surface,key)
            if value is not None: sp.append(copy.deepcopy(value))
        ET.SubElement(sp,'string',{'name':'Name'}).text='SurfaceAppearance'
        ids={k:prop(original,k).findtext('url') for k in ('MeshId','TextureID')}
        ids['ColorMap']=prop(surface,'ColorMap').findtext('url')
        normal=prop(surface,'NormalMap'); ids['NormalMap']=normal.findtext('url') if normal is not None else None
        assert all(not v or (v.startswith('rbxassetid://') and v[13:].isdigit()) for v in ids.values())
        record['parts'].append(ids)
    receipt['models'].append(record)
ET.indent(output)
ET.ElementTree(output).write(dest/'M7NatureTemplates.rbxmx',encoding='utf-8',xml_declaration=True)
# Keep the precise imported interchange files, normalized materials and bundled license.
for file in prepared.rglob('*'):
    if not file.is_file() or file.suffix not in ('.gltf','.bin','.png','.json'): continue
    rel=file.relative_to(prepared)
    if '_temp' in rel.parts: continue
    target=dest/'prepared'/rel; target.parent.mkdir(parents=True,exist_ok=True); shutil.copyfile(file,target)
texture_bytes=0
for file in (prepared/'library-textures').glob('*.png'):
    data=file.read_bytes(); assert data[:8]==b'\x89PNG\r\n\x1a\n'
    w,h=struct.unpack('>II',data[16:24]); assert max(w,h)<=1024
    texture_bytes+=math.ceil(w*h*4*4/3) # uncompressed RGBA8 plus full mip chain, conservative
assert texture_bytes<=32*1024**2
receipt['texture_rgba8_mips_bytes']=texture_bytes
for file in sorted(dest.rglob('*')):
    if file.is_file() and file.name!='receipt.json': receipt['files'][file.relative_to(dest).as_posix()]=sha(file)
(dest/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(f'ADMITTED {len(receipt["models"])} models, {serial} inert mesh parts, RGBA8+mips {texture_bytes/1024**2:.2f} MiB')
