"""AG73 local-only deterministic rig recipe. Blender 4.5 LTS; no network/provider.

blender --background --factory-startup --python build_rig.py -- --render
Outputs are confined to rig_v1. Owner source files are verified and never edited.
"""
import bpy, bmesh, math, json, hashlib, shutil, sys
from pathlib import Path
from mathutils import Vector

OUT=Path(__file__).resolve().parent.parent
SOURCE=OUT.parent/'source'
FBX=SOURCE/'GreenSlime.original.fbx'; PNG=SOURCE/'GreenSlime.original.png'
EXPECTED_FBX='f3457fb1081549c6634e844350eb7e6fb24aaed39dc1a8814e28a730b18c9c7f'
EXPECTED_PNG='631f17ac3724ab7b689c11c5f038242ca68bb38198058c59ab84cf47337b5805'
SCALE=3.2; CLEARANCE=.004; FPS=30; END=96
def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
assert digest(FBX)==EXPECTED_FBX, 'Unexpected owner FBX'
assert digest(PNG)==EXPECTED_PNG, 'Unexpected owner texture'
assert PNG.read_bytes() in FBX.read_bytes(), 'Texture must match FBX embedded bytes'
OUT.mkdir(parents=True,exist_ok=True)
shutil.copyfile(PNG,OUT/'GreenSlime.png')
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(FBX))
imported=[{'name':o.name,'type':o.type} for o in bpy.context.scene.objects]
mesh=bpy.data.objects.get('geometry_0'); assert mesh and mesh.type=='MESH'
for o in list(bpy.context.scene.objects):
    if o!=mesh: bpy.data.objects.remove(o,do_unlink=True)
mesh.name='GreenSlime'; mesh.data.name='GreenSlime_Surface'
bpy.context.view_layer.objects.active=mesh; mesh.select_set(True)
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
min_z=min(v.co.z for v in mesh.data.vertices)
for v in mesh.data.vertices: v.co=Vector((v.co.x*SCALE,v.co.y*SCALE,(v.co.z-min_z+CLEARANCE)*SCALE))
mesh.data.update(); mesh.data.calc_loop_triangles()
assert len(mesh.data.vertices)==1321 and len(mesh.data.loop_triangles)==2603
rest=[v.co.copy() for v in mesh.data.vertices]
uv_digest=hashlib.sha256(json.dumps([list(l.uv) for l in mesh.data.uv_layers.active.data]).encode()).hexdigest()
bm=bmesh.new(); bm.from_mesh(mesh.data)
boundary_vertices={v.index for e in bm.edges if e.is_boundary for v in e.verts}
boundary_edges=sum(e.is_boundary for e in bm.edges); bm.free()
# Source boundaries are the two eye rims. Preserve their topology/UV and give
# their complete neighbourhood rigid head influence; closing them changes eyes.
image=bpy.data.images.load(str(OUT/'GreenSlime.png'),check_existing=False); image.name='GreenSlime_Diffuse'; image.pack()
for mat in mesh.data.materials:
    mat.name='GreenSlime_DiffuseMaterial'; mat.use_nodes=True
    tex=next(n for n in mat.node_tree.nodes if n.type=='TEX_IMAGE'); tex.image=image
    bsdf=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    bsdf.inputs['Roughness'].default_value=.48
    bsdf.inputs['Metallic'].default_value=0
    # Base colour RGB only: source UV atlas padding must not punch skin holes.
    for link in list(mat.node_tree.links):
        if link.to_node==bsdf and link.to_socket==bsdf.inputs['Alpha']: mat.node_tree.links.remove(link)
    bsdf.inputs['Alpha'].default_value=1
rigdata=bpy.data.armatures.new('GreenSlime_Skeleton'); rig=bpy.data.objects.new('GreenSlimeRig',rigdata)
bpy.context.collection.objects.link(rig); rig.show_in_front=True
bpy.context.view_layer.objects.active=rig; mesh.select_set(False); rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
layout={
 'Root':((0,0,0),None),
 'Contact':((0,0,.006),'Root'),
 'Body':((0,0,.055),'Root'),
 'Head':((-.02,-.225,.060),'Body'),
 'EdgeFL':((-.30,-.24,.035),'Root'),
 'EdgeFR':((.30,-.24,.035),'Root'),
 'EdgeBL':((-.29,.25,.035),'Root'),
 'EdgeBR':((.29,.25,.035),'Root')}
for name,(p,parent) in layout.items():
    b=rigdata.edit_bones.new(name); b.head=Vector(p)*SCALE; b.tail=b.head+Vector((0,0,.065*SCALE))
    if parent: b.parent=rigdata.edit_bones[parent]
    b.use_deform=name!='Root'
bpy.ops.object.mode_set(mode='OBJECT')
groups={name:mesh.vertex_groups.new(name=name) for name in layout if name!='Root'}
def smooth(lo,hi,x):
    t=max(0,min(1,(x-lo)/(hi-lo))); return t*t*(3-2*t)
weights=[]
for v in mesh.data.vertices:
    x,y,z=(v.co/SCALE); height=z-CLEARANCE
    head=smooth(.13,.27,-y)*(1-smooth(.14,.255,abs(x+.02)))*smooth(.005,.055,height)
    if v.index in boundary_vertices: head=1
    grounded=1-smooth(.007,.035,height)
    mobile=(1-head)*(1-grounded)
    radial=math.sqrt((x/.48)**2+(y/.43)**2)
    edge=smooth(.35,.92,radial)*.92
    side=smooth(-.20,.20,x); rear=smooth(-.15,.20,y)
    w={'Head':head,'Contact':(1-head)*grounded,'Body':mobile*(1-edge),
       'EdgeFL':mobile*edge*(1-side)*(1-rear),'EdgeFR':mobile*edge*side*(1-rear),
       'EdgeBL':mobile*edge*(1-side)*rear,'EdgeBR':mobile*edge*side*rear}
    pairs=sorted(((k,a) for k,a in w.items() if a>1e-7),key=lambda kv:(-kv[1],kv[0]))[:4]
    total=sum(a for _,a in pairs); assert total>0
    normalized={k:a/total for k,a in pairs}; weights.append(normalized)
    for k,a in normalized.items(): groups[k].add([v.index],a,'REPLACE')
mesh.parent=rig; modifier=mesh.modifiers.new('GreenSlimeSkin','ARMATURE'); modifier.object=rig
# Linear skinning matches the target; no corrective shape keys or Blender-only jiggle.
modifier.use_deform_preserve_volume=False
for b in rig.pose.bones: b.rotation_mode='XYZ'
def reset():
    for b in rig.pose.bones: b.location=(0,0,0); b.rotation_euler=(0,0,0); b.scale=(1,1,1)
def motion(t):
    reset(); a=2*math.pi*t
    rig.pose.bones['Body'].location=(0,SCALE*(.003+.003*math.sin(a)),0)
    h=rig.pose.bones['Head']; h.rotation_euler=(math.radians(3.5)*math.sin(a),math.radians(1.2)*math.sin(a),math.radians(3)*math.sin(a))
    h.location=(0,SCALE*.002*(1-math.cos(a)),0)
    for i,name in enumerate(['EdgeFL','EdgeFR','EdgeBR','EdgeBL']):
        b=rig.pose.bones[name]; phase=a+i*math.pi/2
        # Always lift, never push the thin rim through the ground.
        dz=.006*(1+math.sin(phase)); sign=-1 if name.endswith('L') else 1
        b.location=(SCALE*.009*sign*math.sin(phase),SCALE*dz,-SCALE*.006*math.cos(phase))
        b.rotation_euler.x=math.radians(1.5)*math.sin(phase)
scene=bpy.context.scene; scene.render.fps=FPS; scene.frame_start=0; scene.frame_end=END
scene.unit_settings.system='NONE'; scene.unit_settings.scale_length=1
for frame in range(END+1):
    scene.frame_set(frame); motion(frame/END)
    for name in layout:
        b=rig.pose.bones[name]; b.keyframe_insert('location',frame=frame,group=name); b.keyframe_insert('rotation_euler',frame=frame,group=name)
action=rig.animation_data.action; action.name='GreenSlime_Idle_v1'
for fc in action.fcurves:
    for key in fc.keyframe_points: key.interpolation='LINEAR'
    fc.modifiers.new('CYCLES')
def evaluated_positions():
    bpy.context.view_layer.update(); dg=bpy.context.evaluated_depsgraph_get(); ev=mesh.evaluated_get(dg)
    data=ev.to_mesh(); points=[ev.matrix_world@v.co for v in data.vertices]; ev.to_mesh_clear(); return points
samples=[]; min_ground=1e9; max_move=0; max_strain=0; worst_edge=None
edge_lengths=[(e.vertices[0],e.vertices[1],(rest[e.vertices[0]]-rest[e.vertices[1]]).length) for e in mesh.data.edges]
for frame in range(END+1):
    scene.frame_set(frame); points=evaluated_positions(); samples.append(points)
    min_ground=min(min_ground,min(v.z for v in points)); max_move=max(max_move,max((v-rest[i]).length for i,v in enumerate(points)))
    for a,b,d in edge_lengths:
        if d<=1e-7: continue
        strain=abs((points[a]-points[b]).length/d-1)
        if strain>max_strain: max_strain=strain; worst_edge=(frame,a,b,list(rest[a]),list(rest[b]),weights[a],weights[b])
seam=max((a-b).length for a,b in zip(samples[0],samples[-1]))
velocity_seam=max(((b-a)-(d-c)).length for a,b,c,d in zip(samples[0],samples[1],samples[-2],samples[-1]))
print('AG73 deformation metrics',seam,min_ground,max_strain,velocity_seam,worst_edge,flush=True)
assert seam<1e-6 and min_ground>=-1e-6 and max_strain<.35
assert all(abs(sum(w.values())-1)<1e-6 and 1<=len(w)<=4 and 'Root' not in w for w in weights)
assert all(weights[i]=={'Head':1.0} for i in boundary_vertices)
assert all(tuple(b.scale)==(1,1,1) for b in rig.pose.bones)
report={'blender':bpy.app.version_string,'importedObjects':imported,'sourceHashes':{'fbx':EXPECTED_FBX,'png':EXPECTED_PNG},
 'vertices':len(rest),'triangles':len(mesh.data.loop_triangles),'boundaryEdgesPreserved':boundary_edges,
 'boundaryReason':'Two original eye rims; rigid Head influence, no destructive cap/remesh',
 'bones':list(layout),'rootWeightedVertices':0,'maxInfluences':max(map(len,weights)),
 'uvDigest':uv_digest,'geometryPolicy':'Original vertices/faces/UV unchanged except uniform scale and ground-origin translation',
 'scale':SCALE,'durationSeconds':END/FPS,'fps':FPS,'firstFrame':0,'lastFrame':END,
 'loopMaxVertexDelta':seam,'loopVelocityStepDelta':velocity_seam,'minimumGroundClearance':min_ground,
 'maximumVertexTravel':max_move,'maximumEdgeStrain':max_strain,'noAnimatedScale':True,
 'nativeStudio':'NOT RUN','ownerArtAcceptance':'PENDING'}
# Rig-only rest export plus one baked action file. No camera/light/proxy exported.
bpy.ops.object.select_all(action='DESELECT'); rig.select_set(True); mesh.select_set(True); bpy.context.view_layer.objects.active=rig
export=dict(use_selection=True,object_types={'ARMATURE','MESH'},apply_scale_options='FBX_SCALE_UNITS',
 add_leaf_bones=False,use_armature_deform_only=False,armature_nodetype='NULL',
 axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,
 bake_anim_use_all_bones=True,bake_anim_use_nla_strips=False,bake_anim_use_all_actions=False,bake_anim_step=1,bake_anim_simplify_factor=0)
rig.animation_data.action=None; reset(); bpy.context.view_layer.update()
bpy.ops.export_scene.fbx(filepath=str(OUT/'GreenSlime_Rig.fbx'),bake_anim=False,**export)
rig.animation_data.action=action; scene.frame_set(0)
bpy.ops.export_scene.fbx(filepath=str(OUT/'GreenSlime_Idle.fbx'),bake_anim=True,**export)
image.filepath='//GreenSlime.png'
# Separate presentation collection is excluded from every FBX export.
preview=bpy.data.collections.new('QA_Presentation_NOT_EXPORTED'); scene.collection.children.link(preview)
def into_preview(o):
    for c in list(o.users_collection): c.objects.unlink(o)
    preview.objects.link(o)
bpy.ops.mesh.primitive_plane_add(size=200); floor=bpy.context.object; floor.name='QA_Ground'; into_preview(floor)
mat=bpy.data.materials.new('QA_Ground_Material'); mat.diffuse_color=(.12,.15,.19,1); floor.data.materials.append(mat)
world=bpy.data.worlds.new('QA_World'); scene.world=world; world.use_nodes=True
world.node_tree.nodes['Background'].inputs[0].default_value=(.25,.31,.4,1); world.node_tree.nodes['Background'].inputs[1].default_value=.5
for name,pos,energy,size,color in [('Key',(-3,-4,5),500,5,(1,.93,.8)),('Fill',(3,-1,4),250,4,(.65,.82,1)),('Rim',(0,4,3),400,3,(.8,1,.7))]:
    bpy.ops.object.light_add(type='AREA',location=pos); lamp=bpy.context.object; lamp.name='QA_'+name; into_preview(lamp)
    lamp.data.energy=energy; lamp.data.size=size; lamp.data.color=color
    lamp.rotation_euler=(Vector((0,0,.2))-lamp.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(.8,-4.4,3.1)); camera=bpy.context.object; camera.name='QA_Camera'; into_preview(camera)
camera.rotation_euler=(Vector((0,-.1,.17))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.type='ORTHO'; camera.data.ortho_scale=4.4; scene.camera=camera
scene.render.engine='CYCLES'; scene.cycles.samples=24; scene.cycles.use_denoising=True
scene.render.resolution_x=1000; scene.render.resolution_y=750; scene.render.resolution_percentage=100
scene.view_settings.view_transform='Standard'
bpy.ops.object.select_all(action='DESELECT'); rig.select_set(True); bpy.context.view_layer.objects.active=rig
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D': area.spaces.active.region_3d.view_perspective='CAMERA'; area.spaces.active.shading.type='MATERIAL'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'GreenSlime_Idle.blend'))
(OUT/'validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
if '--render' in sys.argv:
    images=OUT/'previews'; images.mkdir(exist_ok=True)
    for name,frame in [('idle_00',0),('idle_24',24),('idle_48',48),('idle_72',72),('idle_96',96)]:
        scene.frame_set(frame); scene.render.filepath=str(images/(name+'.png')); bpy.ops.render.render(write_still=True)
    rig.animation_data.action=None; reset()
    scene.render.filepath=str(images/'neutral.png'); bpy.ops.render.render(write_still=True)
    h=rig.pose.bones['Head']; h.rotation_euler=(math.radians(7),0,math.radians(6))
    scene.render.filepath=str(images/'head_test.png'); bpy.ops.render.render(write_still=True)
    reset(); rig.pose.bones['Body'].location.y=.025*SCALE
    for i,name in enumerate(['EdgeFL','EdgeFR','EdgeBL','EdgeBR']): rig.pose.bones[name].location.y=(.022 if i%2==0 else .004)*SCALE
    scene.render.filepath=str(images/'edge_test.png'); bpy.ops.render.render(write_still=True)
    reset(); rig.pose.bones['Body'].location.y=-.01*SCALE
    assert min(v.z for v in evaluated_positions()) >= -1e-6
    scene.render.filepath=str(images/'center_compression.png'); bpy.ops.render.render(write_still=True)
print('AG73 BUILD PASS',json.dumps(report))
