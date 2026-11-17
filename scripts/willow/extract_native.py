"""Extract the authorized Studio import; configure immutable textures before Play."""
import sys
from pathlib import Path
import xml.etree.ElementTree as E

root = Path(__file__).resolve().parents[2]
source = Path(sys.argv[1]) if len(sys.argv) > 1 else root / 'build/willow/Willow-Imported.rbxlx'
document = E.parse(source).getroot()
workspace = next(x for x in document.findall('Item') if x.attrib['class'] == 'Workspace')
model = next(x for x in workspace.findall('Item') if x.findtext("Properties/string[@name='Name']") == 'Willow')
assert len(model.findall(".//Item[@class='MeshPart']")) == 2
assert len(model.findall(".//Item[@class='Bone']")) == 9
assert not any(x.attrib['class'] in ('Script', 'LocalScript', 'ModuleScript') for x in model.iter('Item'))
for part in model.findall(".//Item[@class='MeshPart']"):
    props = part.find('Properties')
    foliage = props.findtext("string[@name='Name']") == 'Willow_Foliage'
    texture = props.find("Content[@name='TextureContent']")
    uri = texture.findtext('uri') or texture.findtext('url')
    assert uri == ('rbxassetid://101368619581292' if foliage else 'rbxassetid://103562800749987')
    texture.clear(); texture.set('name', 'TextureContent'); E.SubElement(texture, 'null')
    surface = E.SubElement(part, 'Item', {'class': 'SurfaceAppearance', 'referent': 'WillowSurfaceFoliage' if foliage else 'WillowSurfaceBark'})
    sp = E.SubElement(surface, 'Properties')
    E.SubElement(sp, 'string', {'name': 'Name'}).text = 'WillowSurface'
    content = E.SubElement(sp, 'Content', {'name': 'ColorMap'})
    E.SubElement(content, 'url').text = uri
    E.SubElement(sp, 'token', {'name': 'AlphaMode'}).text = '1' if foliage else '0'
out = E.Element('roblox', {'version': '4'})
for value in ('null', 'nil'): E.SubElement(out, 'External').text = value
out.append(model)
shared = document.find('SharedStrings')
if shared is not None: out.append(shared)
target = root / 'assets/environment/willow/prepared/WillowRoblox.rbxmx'
E.ElementTree(out).write(target, encoding='utf-8', xml_declaration=True)
print(target, target.stat().st_size)
