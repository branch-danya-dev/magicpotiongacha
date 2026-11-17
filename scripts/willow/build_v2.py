"""Non-destructive V1 derivation, Blender 4.5. No renders, uploads or providers.
Three shared crown meshes, three root meshes; 2 meshes per instantiated tree.
"""
import bpy, math, json, pathlib, hashlib, copy
from mathutils import Vector

ROOT=pathlib.Path(__file__).resolve().parents[2]
SOURCE=ROOT/'assets/environment/willow'
OUT=ROOT/'assets/environment/willow-v2/prepared'
OUT.mkdir(parents=True,exist_ok=True)
original=json.loads((SOURCE/'prepared/Willow.mesh.json').read_text())
assert hashlib.sha256((SOURCE/'prepared/Willow.mesh.json').read_bytes()).hexdigest()=='7c7e9bd14794a802c0d1ccd7cdbdc99ab8c8ebe5ac905243f68ea32c03c340f0'
bpy.ops.wm.read_factory_settings(use_empty=True)
def smooth(t):
    t=max(0,min(1,t));return t*t*(3-2*t)
def lift(y):return 7.15*smooth((y-1.8)/13.8)
def to_blender(p):return Vector((p[0],-p[2],p[1]))
def to_roblox(p):return [round(p.x,6),round(p.z,6),round(-p.y,6)]
def material(name,file,tint,foliage=False):
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    nodes=mat.node_tree.nodes;links=mat.node_tree.links;bs=nodes.get('Principled BSDF')
    tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(SOURCE/'textures'/file),check_existing=True)
    mult=nodes.new('ShaderNodeMixRGB');mult.blend_type='MULTIPLY';mult.inputs[0].default_value=1;mult.inputs[2].default_value=(*tint,1)
    links.new(tex.outputs['Color'],mult.inputs[1]);links.new(mult.outputs[0],bs.inputs['Base Color'])
    bs.inputs['Roughness'].default_value=.9
    if foliage:
        links.new(tex.outputs['Alpha'],bs.inputs['Alpha']);mat.surface_render_method='DITHERED';mat.use_transparency_overlap=False;mat.use_backface_culling=False
    return mat
bark=material('WillowV2_Bark','Bark.png',(.94,.83,.69))
leaves=material('WillowV2_Leaves','FoliageAtlas.png',(.70,.84,.82),True)
payload={'schema':2,'source':'willow/prepared/Willow.mesh.json','seed':76217,'materials':2,'textures':2,'variants':[]}
reports=[]
for variant in range(3):
    wood=copy.deepcopy(original['meshes'][0]);fol=original['meshes'][1]
    wood['name']='Willow_Trunk'
    for p in wood['vertices']:
        x,y,z=p;rootfade=1-smooth(y/4.2);a=math.atan2(z,x)
        # Local root flare, smoothly zero above 4.2 studs. Same trunk topology.
        flare=[0,.09,-.075][variant]*math.sin(a*3+variant)*rootfade
        p[:]=[x*(1+flare),y+lift(y),z*(1-flare*.6)]
    positions=[];triangles=[];uvs=[];weights=[];groups=[]
    # Spatially scattered omissions: 76 groups remain in every variation.
    omitted=set((variant*17+j*11)%84 for j in range(8))
    for group in range(84):
        if group in omitted:continue
        for blade in range(3):
            start=group*48+blade*16;old=fol['vertices'][start:start+16]
            anchor=[(old[0][k]+old[1][k])/2 for k in range(3)]
            sector=fol['weights'][start+14][0]
            phase=group*1.618+variant*2.17+blade*.72
            yaw=math.sin(phase)*(.16+variant*.025)
            co,si=math.cos(yaw),math.sin(yaw)
            # Each strip stays attached at its original branch. Broader open gaps,
            # rounded curled tips instead of a single sharp triangular termination.
            width=(.79+.09*math.sin(phase))
            offset=len(positions)
            for j in range(8):
                t=j/7;tip=smooth((t-.66)/.34)
                center=[(old[2*j][k]+old[2*j+1][k])/2 for k in range(3)]
                center[0]+=math.sin(phase+t*2)*.55*t*t
                center[2]+=math.cos(phase+t*1.3)*.48*t*t
                for side in range(2):
                    p=old[2*j+side]
                    dx=(center[0]-anchor[0])+(p[0]-(old[2*j][0]+old[2*j+1][0])/2)*width*(1-.24*tip)
                    dz=(center[2]-anchor[2])+(p[2]-(old[2*j][2]+old[2*j+1][2])/2)*width*(1-.24*tip)
                    y=p[1]+lift(anchor[1])*(1-.44*t)+.23*tip*tip
                    positions.append([anchor[0]+dx*co-dz*si,y,anchor[2]+dx*si+dz*co])
                    weights.append(copy.deepcopy(fol['weights'][start+2*j+side]))
            # Preserve approved texture's alpha edge, all UVs inside original tile.
            for k in range(14):
                tri_index=(group*3+blade)*14+k
                triangles.append([offset+i-start for i in fol['triangles'][tri_index]])
                uvs.append(copy.deepcopy(fol['uv'][tri_index]))
            groups.append({'id':group,'blade':blade,'sector':sector,'length':anchor[1]-old[-1][1]})
    foliage={'name':'Willow_Foliage','vertices':positions,'triangles':triangles,'uv':uvs,'weights':weights}
    bones=copy.deepcopy(original['bones'])
    for b in bones[1:]:b['position'][1]+=lift(b['position'][1])
    armdata=bpy.data.armatures.new('WillowV2_Skeleton_%d'%variant);arm=bpy.data.objects.new('WillowV2_Rig_%d'%variant,armdata)
    bpy.context.collection.objects.link(arm);bpy.ops.object.select_all(action='DESELECT');arm.select_set(True);bpy.context.view_layer.objects.active=arm;bpy.ops.object.mode_set(mode='EDIT')
    root=None
    for i,b in enumerate(bones):
        bone=armdata.edit_bones.new(b['name']);bone.head=to_blender(b['position']);bone.tail=bone.head+Vector((0,0,1 if i==0 else -1))
        if i==0:root=bone
        else:bone.parent=root
    bpy.ops.object.mode_set(mode='OBJECT')
    objects=[]
    for data,mat in [(wood,bark),(foliage,leaves)]:
        mesh=bpy.data.meshes.new(data['name']+'_V%d'%variant);mesh.from_pydata([to_blender(p) for p in data['vertices']],[],data['triangles']);mesh.update()
        obj=bpy.data.objects.new(data['name']+'_V%d'%variant,mesh);bpy.context.collection.objects.link(obj);objects.append(obj)
        uv=mesh.uv_layers.new(name='UVMap')
        for face,coords in zip(mesh.polygons,data['uv']):
            face.use_smooth=True
            for loop,xy in zip(face.loop_indices,coords):uv.data[loop].uv=(xy[0],1-xy[1])
        mesh.materials.append(mat)
        if 'weights' in data:
            vg=[obj.vertex_groups.new(name=b['name']) for b in bones]
            for index,(bone,w) in enumerate(data['weights']):
                vg[0].add([index],1-w,'REPLACE')
                if w>0:vg[bone].add([index],w,'REPLACE')
            obj.parent=arm;modifier=obj.modifiers.new('WillowV2_Skin','ARMATURE');modifier.object=arm
        mesh.calc_loop_triangles()
        normals=[]
        for face in mesh.loop_triangles:
            a,b,c=[mesh.vertices[i].co for i in face.vertices];n=(b-a).cross(c-a)
            assert n.length>1e-9
            normals.append([to_roblox(mesh.corner_normals[l].vector.normalized() if mesh.corner_normals[l].vector.length>.5 else n.normalized()) for l in face.loops])
        data['normals']=normals
    scene=bpy.context.scene;scene.render.fps=30;scene.frame_start=1;scene.frame_end=241
    for frame in range(1,242,5):
        t=(frame-1)/30
        for i in range(8):
            b=arm.pose.bones['Crown_%02d'%(i+1)];b.rotation_mode='XYZ';p=i*.79
            b.rotation_euler=(math.sin(t*math.tau/8+p)*.049,math.cos(t*math.tau/8+p)*.035,math.sin(t*math.tau/8+p+1)*.0168)
            b.keyframe_insert(data_path='rotation_euler',frame=frame,group=b.name)
    arm.animation_data.action.name='WillowV2_WindPreview_8s_V%d'%variant;scene.frame_set(1)
    bpy.ops.object.select_all(action='DESELECT')
    for o in [*objects,arm]:o.select_set(True)
    bpy.context.view_layer.objects.active=arm
    bpy.ops.export_scene.fbx(filepath=str(OUT/('WillowV2_%d.fbx'%(variant+1))),use_selection=True,object_types={'MESH','ARMATURE'},add_leaf_bones=False,apply_unit_scale=True,apply_scale_options='FBX_SCALE_UNITS',axis_forward='-Z',axis_up='Y',use_mesh_modifiers=False,bake_anim=True,bake_anim_use_all_bones=True,bake_anim_use_nla_strips=False,bake_anim_use_all_actions=False,bake_anim_step=1,bake_anim_simplify_factor=0,path_mode='COPY',embed_textures=True)
    length_factors=[]
    for sector in range(1,9):
        ls=[g['length'] for g in groups if g['sector']==sector]
        length_factors.append(round(max(.72,min(1.3,sum(ls)/len(ls)/8)),4))
    entry={'id':variant+1,'groups':76,'bones':bones,'branchFactors':length_factors,'meshes':[wood,foliage]};payload['variants'].append(entry)
    combined=wood['vertices']+foliage['vertices'];bounds=[[round(f(p[k] for p in combined),5) for k in range(3)] for f in (min,max)]
    reports.append({'variant':variant+1,'triangles':sum(len(m['triangles']) for m in entry['meshes']),'groups':76,'bounds':bounds,'heightRatio':round((bounds[1][1]-bounds[0][1])/(23.968-.12),5),'branchFactors':length_factors})
    collection=bpy.data.collections.new('WillowV2_Variant_%d'%(variant+1));scene.collection.children.link(collection)
    for o in [*objects,arm]:
        for c in list(o.users_collection):c.objects.unlink(o)
        collection.objects.link(o)
    collection.hide_viewport=variant>0
for image in bpy.data.images:
    if image.source=='FILE':image.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'WillowV2.blend'))
(OUT/'WillowV2.mesh.json').write_text(json.dumps(payload,separators=(',',':')),encoding='utf-8')
(OUT/'build-report.json').write_text(json.dumps({'variants':reports,'uniqueMeshes':6,'meshesPerTree':2,'bonesPerTree':9,'materials':2,'sourceTexturesUnchanged':True,'rendersCreated':0,'uploads':0},indent=2))
print('WILLOW_V2_BUILD '+json.dumps(reports))
