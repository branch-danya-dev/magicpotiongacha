"""Read-only FBX audit and clay render; writes only to the explicit audit directory."""
import bpy, bmesh, json, sys, pathlib, hashlib, math
from mathutils import Vector

args = sys.argv[sys.argv.index('--')+1:]
source, dest = [pathlib.Path(p).resolve() for p in args[:2]]
wood_only='--wood-only' in args[2:]
dest.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(source))
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
report = {'sourceSha256': hashlib.sha256(source.read_bytes()).hexdigest(), 'objects': []}
all_points = []
for obj in meshes:
    m = obj.data
    m.calc_loop_triangles()
    points = [obj.matrix_world @ v.co for v in m.vertices]
    all_points.extend(points)
    parent = list(range(len(m.vertices)))
    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i
    for edge in m.edges:
        a, b = map(find, edge.vertices)
        parent[a] = b
    components = {}
    for v in m.vertices:
        k = find(v.index)
        components.setdefault(k, []).append(v.index)
    sizes = sorted([len(v) for v in components.values()], reverse=True)
    if wood_only:
        keep=set(max(components.values(),key=len))
        bm=bmesh.new(); bm.from_mesh(m); bm.verts.ensure_lookup_table()
        bmesh.ops.delete(bm,geom=[v for v in bm.verts if v.index not in keep],context='VERTS')
        bm.to_mesh(m); bm.free(); m.calc_loop_triangles()
    report['objects'].append({'name': obj.name, 'vertices': len(m.vertices),
        'triangles': len(m.loop_triangles), 'polygons': len(m.polygons),
        'uvLayers': [u.name for u in m.uv_layers], 'materials': [x.name if x else None for x in m.materials],
        'components': len(components), 'componentSizes': sizes,
        'bounds': [[min(p[i] for p in points) for i in range(3)], [max(p[i] for p in points) for i in range(3)]]})
    mat = bpy.data.materials.new('AuditClay'); mat.diffuse_color=(.46,.38,.26,1)
    m.materials.clear(); m.materials.append(mat)
    for poly in m.polygons: poly.material_index=0
report['bones'] = sum(len(o.data.bones) for o in bpy.context.scene.objects if o.type=='ARMATURE')
report['images'] = [i.name for i in bpy.data.images]
(dest/'source-audit.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
lo = Vector([min(p[i] for p in all_points) for i in range(3)])
hi = Vector([max(p[i] for p in all_points) for i in range(3)])
center = (lo+hi)/2; span=max(hi-lo)
world=bpy.data.worlds.new('AuditWorld'); bpy.context.scene.world=world
world.use_nodes=True; world.node_tree.nodes['Background'].inputs[0].default_value=(.1,.12,.15,1)
world.node_tree.nodes['Background'].inputs[1].default_value=.5
for name,pos,power,size in [('Key',(3,-4,5),500,4),('Fill',(-3,-2,2),240,4),('Rim',(1,3,4),400,3)]:
    d=bpy.data.lights.new(name,'AREA'); o=bpy.data.objects.new(name,d); bpy.context.scene.collection.objects.link(o)
    o.location=center+Vector(pos)*span; o.rotation_euler=(center-o.location).to_track_quat('-Z','Y').to_euler()
    d.energy=power*span*span; d.shape='DISK'; d.size=size*span
d=bpy.data.cameras.new('AuditCamera'); camera=bpy.data.objects.new('AuditCamera',d); bpy.context.scene.collection.objects.link(camera)
bpy.context.scene.camera=camera; d.type='ORTHO'; d.ortho_scale=span*1.18
scene=bpy.context.scene; scene.render.engine='BLENDER_EEVEE_NEXT'
scene.render.resolution_x=1000; scene.render.resolution_y=1000; scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX'; scene.render.image_settings.file_format='PNG'
for name,direction in [('front',(0,-4,1)),('side',(4,0,1)),('angle',(3,-4,1.7))]:
    camera.location=center+Vector(direction)*span
    camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(dest/(name+'.png')); bpy.ops.render.render(write_still=True)
print('WILLOW_SOURCE_AUDIT '+json.dumps(report))
