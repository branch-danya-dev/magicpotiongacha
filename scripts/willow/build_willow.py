"""Willow prototype: preserved source wood, rebuilt curved atlas ribbons, nine bones.
Blender 4.5 LTS. No provider/API calls; deterministic seed and explicit output paths.
"""
import bpy, bmesh, math, random, pathlib, sys, json, hashlib
from mathutils import Vector

ROOT = pathlib.Path(__file__).resolve().parents[2]
ASSET = ROOT / 'assets/environment/willow'
OUT = ASSET / 'prepared'
REVIEW = ROOT / 'build/willow/review'
for p in (OUT, REVIEW): p.mkdir(parents=True, exist_ok=True)
random.seed(76117)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=str(ASSET/'source/Meshy_AI_model_20261117_generate.fbx'))
wood = next(o for o in bpy.context.scene.objects if o.type=='MESH')
wood.name='Willow_Trunk'
bpy.context.view_layer.objects.active=wood; wood.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
m=wood.data
parents=list(range(len(m.vertices)))
def find(i):
    while parents[i]!=i: parents[i]=parents[parents[i]]; i=parents[i]
    return i
for e in m.edges:
    a,b=map(find,e.vertices); parents[a]=b
components={}
for v in m.vertices: components.setdefault(find(v.index),[]).append(v.index)
clusters=sorted(components.values(),key=len,reverse=True)
keep=set(clusters[0])
# Preserve the source's natural branch/crown distribution, not a regular grid.
anchors=[]
for ids in clusters[1:]:
    pts=[m.vertices[i].co.copy() for i in ids]
    top=max(pts,key=lambda p:p.z)
    low=min(p.z for p in pts)
    if top.z>.02 and top.z-low>.022:
        anchors.append((top.copy(),top.z-low,len(ids)))
anchors.sort(key=lambda x:(-x[2],-x[1],x[0].x,x[0].y))
anchors=anchors[:84]
assert len(anchors)==84, len(anchors)
bm=bmesh.new(); bm.from_mesh(m); bm.verts.ensure_lookup_table()
bmesh.ops.delete(bm,geom=[v for v in bm.verts if v.index not in keep],context='VERTS')
# Connected triangular leaf fins have much longer edges than the fine woody tubes.
# Remove only upper-crown faces; roots and the main S-shaped trunk stay intact.
fins=[f for f in bm.faces if min(v.co.z for v in f.verts)>.015 and max(e.calc_length() for e in f.edges)>.065]
bmesh.ops.delete(bm,geom=fins,context='FACES')
bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
boundary=[e for e in bm.edges if e.is_boundary]
bmesh.ops.holes_fill(bm,edges=boundary,sides=10)
bmesh.ops.smooth_vert(bm,verts=list(bm.verts),factor=.13,use_axis_x=True,use_axis_y=True,use_axis_z=True)
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
bm.to_mesh(m); bm.free()
zmin=min(v.co.z for v in m.vertices)
scale=24/.71337890625
def position(p): return Vector((p.x*scale,p.y*scale,(p.z-zmin)*scale))
for v in m.vertices: v.co=position(v.co)
# Reconstruct a closed woody surface from the preserved silhouette. Meshy's
# branch intersections contained inward faces that looked like holes in Roblox.
remesh=wood.modifiers.new('RepairBranchIntersections','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.12
bpy.ops.object.modifier_apply(modifier=remesh.name)
smooth=wood.modifiers.new('GentleWoodRelaxation','SMOOTH');smooth.factor=.7;smooth.iterations=3
bpy.ops.object.modifier_apply(modifier=smooth.name)
wood.data.calc_loop_triangles()
decimate=wood.modifiers.new('WoodTriangleBudget','DECIMATE');decimate.ratio=min(1,2700/len(wood.data.loop_triangles));decimate.use_collapse_triangulate=True
bpy.ops.object.modifier_apply(modifier=decimate.name)
m=wood.data
bm=bmesh.new();bm.from_mesh(m)
bmesh.ops.dissolve_degenerate(bm,dist=.02,edges=list(bm.edges))
bmesh.ops.triangulate(bm,faces=list(bm.faces))
# Collapse/repair can leave coincident faces. Remove them explicitly so the
# FBX importer and the local mesh export have identical topology, without flicker.
bm.verts.index_update();seen=set();duplicates=[]
for face in bm.faces:
    key=tuple(sorted(v.index for v in face.verts))
    if key in seen:duplicates.append(face)
    else:seen.add(key)
bmesh.ops.delete(bm,geom=duplicates,context='FACES_ONLY')
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(m);bm.free()
if m.has_custom_normals: m.normals_split_custom_set([(0,0,0)]*len(m.loops))
for e in m.edges:e.use_edge_sharp=False
for p in m.polygons: p.use_smooth=True
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=math.radians(60),island_margin=.015)
bpy.ops.object.mode_set(mode='OBJECT')
# Blender may leave zero corner normals on very small decimated root triangles.
# Supply geometric fallback normals before both FBX and the local QA export.
m.calc_loop_triangles()
resolved=[n.vector.copy() for n in m.corner_normals]
for tri in m.loop_triangles:
    a,b,c=[m.vertices[i].co for i in tri.vertices]
    n=(b-a).cross(c-a);assert n.length>1e-9,'Degenerate wood face'
    n.normalize()
    for loop in tri.loops:
        if resolved[loop].length<.5:resolved[loop]=n
m.normals_split_custom_set([tuple(n.normalized()) for n in resolved])
m.update()

def material(name,filename,foliage=False):
    mat=bpy.data.materials.new(name); mat.use_nodes=True
    bs=mat.node_tree.nodes.get('Principled BSDF')
    image=bpy.data.images.load(str(ASSET/'textures'/filename),check_existing=True)
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=image
    mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
    bs.inputs['Roughness'].default_value=.86
    if foliage:
        # Cutout preview uses texture alpha directly; no baked opaque matte.
        mat.node_tree.links.new(tex.outputs['Alpha'],bs.inputs['Alpha'])
        bs.inputs['Subsurface Weight'].default_value=.04
        mat.surface_render_method='DITHERED'; mat.use_transparency_overlap=False
        mat.use_backface_culling=False
    return mat
wood.data.materials.clear(); wood.data.materials.append(material('Willow_Bark','Bark.png'))

# Controls are rooted in eight crown sectors; trunk is a separate unskinned mesh.
group_data=[]
for i,(source,length,_) in enumerate(anchors):
    a=position(source)
    sector=int((math.atan2(a.y,a.x)+math.pi)/(2*math.pi)*8)%8
    group_data.append({'anchor':a,'length':max(4.5,min(10.3,length*scale*1.6+2.4)), 'sector':sector})
control=[]
for s in range(8):
    pts=[g['anchor'] for g in group_data if g['sector']==s]
    control.append(sum(pts,Vector())/len(pts) if pts else Vector((0,0,19)))
armdata=bpy.data.armatures.new('Willow_Skeleton'); arm=bpy.data.objects.new('Willow_Rig',armdata)
bpy.context.collection.objects.link(arm); bpy.ops.object.select_all(action='DESELECT')
arm.select_set(True); bpy.context.view_layer.objects.active=arm; bpy.ops.object.mode_set(mode='EDIT')
root=armdata.edit_bones.new('Root'); root.head=(0,0,0); root.tail=(0,0,1)
for i,p in enumerate(control):
    bone=armdata.edit_bones.new('Crown_%02d'%(i+1)); bone.head=p; bone.tail=p+Vector((0,0,-1))
    bone.parent=root; bone.use_connect=False
bpy.ops.object.mode_set(mode='OBJECT'); arm.show_in_front=True
verts=[]; faces=[]; face_uv=[]; weights=[]
for i,g in enumerate(group_data):
    a=g['anchor']; yaw=random.uniform(0,math.tau)
    for blade in range(3):
        angle=yaw+blade*math.pi/3
        side=Vector((math.cos(angle),math.sin(angle),0))
        outward=Vector((-math.sin(angle),math.cos(angle),0))
        length=g['length']*random.uniform(.78,1.16)
        width=random.uniform(1.1,1.8)
        atlas=(i+blade)%4
        start=len(verts)
        for j in range(8):
            t=j/7
            center=a+outward*(math.sin(t*math.pi)*.9+t*.3)+Vector((0,0,-length*t))
            spread=width*(.60+.40*math.sin(math.pi*t))
            for sign in (-1,1):
                verts.append(tuple(center+side*(sign*spread/2)))
                weights.append((g['sector']+1, .9*t*t*(3-2*t)))
        for j in range(7):
            n=start+2*j; faces.append((n,n+1,n+3,n+2))
            u0=(atlas+.025)/4;u1=(atlas+.975)/4
            face_uv.append(((u0,1-j/7),(u1,1-j/7),(u1,1-(j+1)/7),(u0,1-(j+1)/7)))
fm=bpy.data.meshes.new('Willow_CurvedRibbons'); fm.from_pydata(verts,[],faces); fm.update()
fol=bpy.data.objects.new('Willow_Foliage',fm); bpy.context.collection.objects.link(fol)
uv=fm.uv_layers.new(name='FoliageAtlasUV')
for p,coords in zip(fm.polygons,face_uv):
    p.use_smooth=True
    for index,coord in zip(p.loop_indices,coords): uv.data[index].uv=coord
fol.data.materials.append(material('Willow_FoliageAtlas','FoliageAtlas.png',True))
groups=[fol.vertex_groups.new(name=n) for n in ['Root']+['Crown_%02d'%(i+1) for i in range(8)]]
for i,(bone,weight) in enumerate(weights):
    groups[0].add([i],1-weight,'REPLACE')
    if weight>0: groups[bone].add([i],weight,'REPLACE')
modifier=fol.modifiers.new('Willow_Skin','ARMATURE'); modifier.object=arm; fol.parent=arm
scene=bpy.context.scene;scene.render.fps=30;scene.frame_start=1;scene.frame_end=241
for frame in range(1,242,5):
    t=(frame-1)/30
    for i in range(8):
        b=arm.pose.bones['Crown_%02d'%(i+1)];phase=i*.79
        b.rotation_mode='XYZ'
        b.rotation_euler=(math.sin(t*math.tau/8+phase)*.035,math.cos(t*math.tau/8+phase)*.025,math.sin(t*math.tau/8+phase+1)*.012)
        b.keyframe_insert(data_path='rotation_euler',frame=frame,group=b.name)
arm.animation_data.action.name='Willow_WindPreview_8s'
scene.frame_set(1)

def vec(p): return [round(p.x,6),round(p.z,6),round(-p.y,6)]
payload={'schema':1,'seed':76117,'groups':84,'bones':[{'name':b.name,'position':vec(b.head_local)} for b in arm.data.bones], 'meshes':[]}
for obj in [wood,fol]:
    mesh=obj.data;mesh.calc_loop_triangles();uv=mesh.uv_layers.active
    data={'name':obj.name,'vertices':[vec(v.co) for v in mesh.vertices], 'triangles':[], 'uv':[], 'normals':[]}
    if obj==fol: data['weights']=[[b,round(w,6)] for b,w in weights]
    for tri in mesh.loop_triangles:
        data['triangles'].append(list(tri.vertices))
        data['uv'].append([[round(uv.data[l].uv.x,6),round(1-uv.data[l].uv.y,6)] for l in tri.loops])
        data['normals'].append([vec(mesh.corner_normals[l].vector) for l in tri.loops])
    payload['meshes'].append(data)
triangles=sum(len(x['triangles']) for x in payload['meshes'])
assert 4000<=triangles<=6500, triangles
(OUT/'Willow.mesh.json').write_text(json.dumps(payload,separators=(',',':')),encoding='utf-8')
bpy.ops.object.select_all(action='DESELECT')
for o in (wood,fol,arm):o.select_set(True)
bpy.context.view_layer.objects.active=arm
bpy.ops.export_scene.fbx(filepath=str(OUT/'Willow.fbx'),use_selection=True,object_types={'MESH','ARMATURE'},
    add_leaf_bones=False,apply_unit_scale=True,apply_scale_options='FBX_SCALE_UNITS',axis_forward='-Z',axis_up='Y',use_mesh_modifiers=False,
    bake_anim=True,bake_anim_use_all_bones=True,bake_anim_use_nla_strips=False,bake_anim_use_all_actions=False,
    bake_anim_step=1,bake_anim_simplify_factor=0,path_mode='COPY',embed_textures=True)

# Reproducible Blender review only. Studio evidence is captured separately.
world=bpy.data.worlds.new('Willow_Review_World');scene.world=world;world.use_nodes=True
world.node_tree.nodes['Background'].inputs[0].default_value=(.12,.15,.19,1)
world.node_tree.nodes['Background'].inputs[1].default_value=.65
center=Vector((0,0,11.5))
for name,power,pos in [('Key',12500,(-20,25,38)),('Fill',9000,(25,5,22)),('Rim',14000,(0,-20,30))]:
    d=bpy.data.lights.new(name,'AREA');o=bpy.data.objects.new(name,d);scene.collection.objects.link(o)
    o.location=pos;o.rotation_euler=(center-o.location).to_track_quat('-Z','Y').to_euler();d.energy=power;d.size=22
d=bpy.data.cameras.new('WillowReviewCamera');cam=bpy.data.objects.new('WillowReviewCamera',d);scene.collection.objects.link(cam)
scene.camera=cam;d.type='ORTHO';d.ortho_scale=39
cam.location=(0,65,20);cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
scene.render.engine='BLENDER_EEVEE_NEXT';scene.render.resolution_x=1200;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG'
for image in bpy.data.images:
    if image.source=='FILE':image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Willow.blend'))
report={'triangles':triangles,'trunkTriangles':len(payload['meshes'][0]['triangles']),'foliageTriangles':len(payload['meshes'][1]['triangles']),
    'groups':84,'ribbons':252,'segmentsPerRibbon':7,'bones':9,'maxInfluences':2,'materials':2,'meshParts':2,'removedConnectedFinFaces':len(fins)}
(OUT/'build-report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
if '--no-render' not in sys.argv:
    for name,location in [('front',(0,65,20)),('side',(65,0,20)),('angle',(45,60,26)),('back',(0,-65,20))]:
        cam.location=location;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
        scene.render.filepath=str(REVIEW/(name+'.png'));bpy.ops.render.render(write_still=True)
print('WILLOW_BUILD '+json.dumps(report))
