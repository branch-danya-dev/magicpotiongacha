"""Derive 07B render settings from the already admitted 14 CC0 models.

Python + Pillow, offline. Never reimports/uploads or changes meshes/maps/IDs.
The explicit owner-approved direct workflow remains in force for this subset.
"""
from pathlib import Path
import hashlib, json, math, struct, xml.etree.ElementTree as ET
from PIL import Image

root=Path(__file__).resolve().parents[1]
source=root/'assets/environment/megakit'
dest=root/'assets/environment/woodland'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def prop(i,k): return i.find(f'Properties/*[@name="{k}"]')
def vector(i,k): return [float(prop(i,k).findtext(c)) for c in 'XYZ']
def put(i,kind,key,value):
    p=prop(i,key)
    if p is None: p=ET.SubElement(i.find('Properties'),kind,{'name':key})
    p.text=str(value).lower()
receipt=json.loads((source/'receipt.json').read_text())
assert receipt['source_archive_sha256']=='298f6732b872e4cf7b30e6e7abf9641c7f6dc6b326df37ac089533ed7e3d58c9'
assert 'CC0-1.0' in receipt['license']
for name,digest in receipt['files'].items(): assert sha(source/name)==digest,name
assert set(p.name for p in dest.iterdir())<= {'M7NatureTemplates.rbxmx','receipt.json','inspection.json'} if dest.exists() else True
dest.mkdir(exist_ok=True)
tree=ET.parse(source/'M7NatureTemplates.rbxmx')
models={}; inspection={'method':'offline source geometry/alpha audit; NOT a native render result','models':{},'textures':{}}

for model in tree.findall('.//Item[@class="Model"]'):
    name=prop(model,'Name').text
    gltf=json.loads((source/'prepared'/f'{name}.gltf').read_text())
    record=next(m for m in receipt['models'] if m['name']==name)
    is_tree='Tree' in name or name.startswith('Pine')
    parts=[]; foliage_count=0
    # The admitted trees contain one opaque bark and one alpha canopy. Grass
    # and rocks use opaque color maps even though the old importer set alpha=1.
    cutout=name in ('Bush_Common_Flowers','Clover_2','Fern_1','Flower_3_Group')
    for p in model.findall('Item[@class="MeshPart"]'):
        part_name=prop(p,'Name').text
        foliage=(is_tree and part_name.endswith('_2')) or cutout
        if foliage:
            foliage_count+=1
            # Roblox documents >=.02 as smooth blending rather than coverage
            # alpha. No translucent trunk/rock and no runtime texture churn.
            put(p,'float','Transparency',.02)
            put(p,'bool','CastShadow',False)
            put(p,'token','RenderFidelity',1) # Precise: don't collapse leaf cards.
        size=vector(p,'size'); center=vector(p,'CFrame')
        parts.append({'name':part_name,'size':size,'position':center,'foliage':foliage})
    radius=max(math.hypot(abs(p['position'][0])+p['size'][0]/2,abs(p['position'][2])+p['size'][2]/2) for p in parts)+.001
    height=max(p['position'][1]+p['size'][1]/2 for p in parts)
    bark=0; duplicate=0; triangles=0
    for mesh in gltf['meshes']:
        for primitive in mesh['primitives']:
            accessor=gltf['accessors'][primitive['indices']]; n=accessor['count']//3
            triangles+=n
            if 'Bark' in gltf['materials'][primitive['material']]['name']: bark+=n
            # Exact coincident triangles in a primitive are a z-fighting risk.
            def data(a):
                a=gltf['accessors'][a]; view=gltf['bufferViews'][a['bufferView']]
                b=(source/'prepared'/gltf['buffers'][view['buffer']]['uri']).read_bytes()
                fmt={5123:'H',5125:'I',5126:'f'}[a['componentType']]
                components={'SCALAR':1,'VEC3':3}[a['type']]; size=struct.calcsize(fmt)*components
                offset=view.get('byteOffset',0)+a.get('byteOffset',0); stride=view.get('byteStride',size)
                return [struct.unpack_from('<'+fmt*components,b,offset+i*stride) for i in range(a['count'])]
            positions=data(primitive['attributes']['POSITION']); indices=[v[0] for v in data(primitive['indices'])]
            seen=set()
            for i in range(0,len(indices),3):
                key=tuple(sorted(tuple(round(c,6) for c in positions[j]) for j in indices[i:i+3]))
                if key in seen: duplicate+=1
                seen.add(key)
    assert triangles==record['triangles']
    models[name]={'radius':radius,'height':height,'triangles':triangles,'barkTriangles':bark,'parts':parts}
    inspection['models'][name]={'triangles':triangles,'exactDuplicateTriangles':duplicate,'smoothAlphaParts':foliage_count,'radius':radius,'height':height}
    for mat in gltf['materials']:
        texture=mat['pbrMetallicRoughness'].get('baseColorTexture')
        if not texture: continue
        uri=gltf['images'][gltf['textures'][texture['index']]['source']]['uri']
        path=source/'prepared'/uri
        if uri in inspection['textures']: continue
        image=Image.open(path).convert('RGBA'); hist=image.getchannel('A').histogram(); total=image.width*image.height
        inspection['textures'][uri]={'sha256':sha(path),'size':list(image.size),'transparentPixels':hist[0],
            'opaquePixels':hist[255],'fractionalAlphaPixels':sum(hist[1:255]),'fractionalAlphaFraction':sum(hist[1:255])/total}

ET.indent(tree)
tree.write(dest/'M7NatureTemplates.rbxmx',encoding='utf-8',xml_declaration=True)
(dest/'inspection.json').write_text(json.dumps(inspection,indent=2)+'\n',encoding='utf-8',newline='\n')
def luau(value):
    if isinstance(value,dict): return '{'+','.join('['+json.dumps(k)+']='+luau(v) for k,v in sorted(value.items()))+'}'
    if isinstance(value,list): return '{'+','.join(map(luau,value))+'}'
    if isinstance(value,bool): return 'true' if value else 'false'
    if isinstance(value,str): return json.dumps(value)
    return str(value)
geometry=root/'src/shared/NatureGeometry.luau'
geometry.write_text('--!nonstrict\n-- Generated from hash-verified, actual admitted MeshPart bounds; do not estimate crown radii.\nreturn {\n'+''.join('\t['+json.dumps(k)+']='+luau(v)+',\n' for k,v in sorted(models.items()))+'}\n',encoding='utf-8',newline='\n')
out={'name':'M7 07B Quaternius woodland presentation','version':1,'license':receipt['license'],
    'source':'https://quaternius.itch.io/stylized-nature-megakit','tier':'Standard free / 14 already admitted models',
    'source_archive_sha256':receipt['source_archive_sha256'],'parent_receipt_sha256':sha(source/'receipt.json'),
    'parent_templates_sha256':sha(source/'M7NatureTemplates.rbxmx'),
    'generator':'scripts/prepare-woodland.py','generator_sha256':hashlib.sha256(Path(__file__).read_text().replace('\r\n','\n').encode()).hexdigest(),
    'geometry':'src/shared/NatureGeometry.luau','geometry_sha256':sha(geometry),
    'workflow':'Existing owner-authorized direct subset; derived presentation only, no new provider admission or import; not a game-dev receipt',
    'changes':['Only cutout foliage: Transparency .02, CastShadow false, RenderFidelity Precise',
        'All geometry, UVs, asset IDs, textures, AlphaMode and licenses unchanged'],
    'roblox_reference':'https://create.roblox.com/docs/art/modeling/surface-appearance',
    'nativeLowAutomatic':'NOT VERIFIED; smooth-alpha sorting/overdraw and foliage readability require ordinary Play',
    'experience_permissions':'BLOCKED','newTextureBytes':0,'newMeshAssets':0,
    'files':{p.name:sha(p) for p in sorted(dest.iterdir()) if p.name!='receipt.json'}}
(dest/'receipt.json').write_text(json.dumps(out,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps({'models':len(models),'smoothAlphaParts':sum(m['smoothAlphaParts'] for m in inspection['models'].values()),
    'duplicateTriangles':{n:m['exactDuplicateTriangles'] for n,m in inspection['models'].items() if m['exactDuplicateTriangles']},
    'fractionalAlpha':{n:round(t['fractionalAlphaFraction'],5) for n,t in inspection['textures'].items()},'nativeRender':'NOT_VERIFIED'},indent=2))
