"""Read owner FBX in a disposable Blender scene; never save over the source."""
import bpy, bmesh, json, sys, math
from pathlib import Path
from mathutils import Vector

args=sys.argv[sys.argv.index('--')+1:]
source=Path(args[0]).resolve(); output=Path(args[1]).resolve()
output.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(source))
report={'blender':bpy.app.version_string,'objects':[]}
for obj in bpy.context.scene.objects:
    row={'name':obj.name,'type':obj.type,'dimensions':list(obj.dimensions),'location':list(obj.location),'rotation':list(obj.rotation_euler),'scale':list(obj.scale)}
    if obj.type=='MESH':
        obj.data.calc_loop_triangles()
        bm=bmesh.new(); bm.from_mesh(obj.data)
        row.update(vertices=len(obj.data.vertices),triangles=len(obj.data.loop_triangles),boundaryEdges=sum(e.is_boundary for e in bm.edges),nonManifoldEdges=sum(not e.is_manifold for e in bm.edges),looseVertices=sum(not v.link_edges for v in bm.verts))
        row['materials']=[m.name for m in obj.data.materials]
        row['uvLayers']=[uv.name for uv in obj.data.uv_layers]
        row['bounds']=[[min((obj.matrix_world@v.co)[i] for v in obj.data.vertices),max((obj.matrix_world@v.co)[i] for v in obj.data.vertices)] for i in range(3)]
        bm.free()
    report['objects'].append(row)
report['images']=[{'name':i.name,'size':list(i.size),'packed':i.packed_file is not None,'path':i.filepath} for i in bpy.data.images]
(output/'source-inspection.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
mesh=bpy.data.objects['geometry_0']
for obj in list(bpy.context.scene.objects):
    if obj!=mesh: bpy.data.objects.remove(obj,do_unlink=True)
world=bpy.data.worlds.new('InspectionWorld'); bpy.context.scene.world=world; world.use_nodes=True
world.node_tree.nodes['Background'].inputs[0].default_value=(.32,.36,.43,1)
world.node_tree.nodes['Background'].inputs[1].default_value=.7
for mat in mesh.data.materials:
    bsdf=mat.node_tree.nodes.get('Principled BSDF')
    if bsdf: bsdf.inputs['Roughness'].default_value=.55
bpy.ops.object.light_add(type='AREA',location=(1,-1,3)); bpy.context.object.data.energy=180; bpy.context.object.data.shape='DISK'; bpy.context.object.data.size=3
scene=bpy.context.scene; scene.render.engine='CYCLES'; scene.cycles.samples=24
scene.render.resolution_x=900; scene.render.resolution_y=700; scene.render.resolution_percentage=100
scene.view_settings.view_transform='Standard'
center=sum((mesh.matrix_world@Vector(c) for c in mesh.bound_box),Vector())/8
bpy.ops.object.camera_add(); cam=bpy.context.object; cam.data.type='ORTHO'; cam.data.ortho_scale=1.32; scene.camera=cam
for name,direction in [('front',(0,-1,.8)),('back',(0,1,.8)),('side',(1,0,.6)),('top',(0,0,1))]:
    cam.location=center+Vector(direction)*2
    cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(output/(name+'.png')); bpy.ops.render.render(write_still=True)
