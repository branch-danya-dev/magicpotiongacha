"""Blender background inspection; no rendering, source modification or scripts."""
import bpy, json, pathlib, sys
from mathutils import Vector
ROOT=pathlib.Path(__file__).resolve().parents[2]
key=sys.argv[sys.argv.index('--')+1]
assert key in ('stylized_stefan','magic_igor'), 'First pair only'
source=ROOT/'assets/environment/vegetation-v2/sources'/key/'unpacked'
bpy.ops.wm.read_factory_settings(use_empty=True)
if key=='stylized_stefan':
    filename=next(source.rglob('*.blend'))
    with bpy.data.libraries.load(str(filename),link=False) as (data_in,data_out):
        data_out.objects=data_in.objects
    for obj in data_out.objects:
        if obj is not None: bpy.context.collection.objects.link(obj)
else:
    bpy.ops.import_scene.fbx(filepath=str(next(source.rglob('*.fbx'))),use_anim=False)
bpy.context.view_layer.update()
objects=[]
for obj in bpy.data.objects:
    item={'name':obj.name,'type':obj.type,'location':list(obj.location),'scale':list(obj.scale)}
    if obj.type=='MESH':
        mesh=obj.data;mesh.calc_loop_triangles()
        coords=[obj.matrix_world@v.co for v in mesh.vertices]
        item.update(vertices=len(mesh.vertices),triangles=len(mesh.loop_triangles),
            bounds=[[round(f(v[k] for v in coords),5) for k in range(3)] for f in (min,max)],
            materials=[{'slot':i,'name':m.name if m else None,'faces':sum(p.material_index==i for p in mesh.polygons)} for i,m in enumerate(mesh.materials)],
            uvLayers=[l.name for l in mesh.uv_layers],modifiers=[m.type for m in obj.modifiers],
            groups=[g.name for g in obj.vertex_groups])
    objects.append(item)
materials=[]
for mat in bpy.data.materials:
    nodes=[]
    if mat.use_nodes:
        for n in mat.node_tree.nodes:
            row={'type':n.type,'name':n.name}
            if n.type=='TEX_IMAGE': row.update(image=n.image.name if n.image else None,path=n.image.filepath if n.image else None,packed=bool(n.image.packed_file) if n.image else False,size=list(n.image.size) if n.image else None)
            if n.type=='VALTORGB': row['ramp']=[(e.position,list(e.color)) for e in n.color_ramp.elements]
            nodes.append(row)
    materials.append({'name':mat.name,'nodes':nodes,'links':[(l.from_node.name,l.from_socket.name,l.to_node.name,l.to_socket.name) for l in mat.node_tree.links] if mat.use_nodes else []})
out=ROOT/'build/vegetation';out.mkdir(parents=True,exist_ok=True)
report={'key':key,'blender':bpy.app.version_string,'objects':objects,'materials':materials}
(out/(key+'-inspection.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
