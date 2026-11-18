"""Deterministic data-only Blender derivation of the first two licensed sources.
Usage: blender --background --factory-startup --disable-autoexec --python ... -- KEY
No generators, renders, uploads or source overwrites. Roblox is Y up; Blender Z up.
"""
import bpy, math, json, pathlib, sys, hashlib
import numpy as np
from mathutils import Vector
from collections import defaultdict
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parent))
from stage_source import source as check_source

ROOT=pathlib.Path(__file__).resolve().parents[2]
LIB=ROOT/'assets/environment/vegetation-v2'
KEY=sys.argv[sys.argv.index('--')+1]
assert KEY in ('stylized_stefan','magic_igor'), 'Validate first pair before expanding'
check_source(KEY)
SOURCE=LIB/'sources'/KEY/'unpacked'
OUT=LIB/'prepared'/KEY;OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)

def smooth(x):
    x=max(0,min(1,x));return x*x*(3-2*x)
def rbx(v):return [round(v.x,6),round(v.z,6),round(-v.y,6)]
def rgb_image(file,size):
    image=bpy.data.images.load(str(SOURCE/'textures'/file),check_existing=False)
    image.colorspace_settings.name='Non-Color';image.scale(size,size)
    data=np.empty(size*size*4,dtype=np.float32);image.pixels.foreach_get(data)
    bpy.data.images.remove(image)
    return data.reshape((size,size,4))

if KEY=='stylized_stefan':
    with bpy.data.libraries.load(str(next(SOURCE.rglob('*.blend'))),link=False) as (a,b): b.objects=a.objects
    for obj in b.objects:
        if obj and obj.type=='MESH':bpy.context.collection.objects.link(obj)
    specs=[('Bark','LowPoly_DefaultMaterial_BaseColor.png',None),('Leaf','Leaves.png','SELF')]
    roles={'Material.001':('Bark',0),'Leaves':('Leaf',1)}
    height=24.;tile=256;atlas_size=512
else:
    bpy.ops.import_scene.fbx(filepath=str(next(SOURCE.rglob('*.fbx'))),use_anim=False)
    specs=[('Bark','TRUNK_LP_albedo.jpeg',None),('Leaf','LEAVES_LP_albedo.jpeg','LEAVES_LP_opacity.jpeg'),
           ('LeafSecondary','LEAVES_LP_spod_albedo.jpeg','LEAVES_LP_opacity.jpeg'),
           ('Leaf','FOLIAGE_HP_albedo.jpeg','FOLIAGE_HP_opacity.jpeg'),
           ('Magic','GEM_LP_albedo.jpeg',None),('Stone','KAMIEN_LP_albedo.jpeg',None)]
    roles={name:(role,i) for i,(name,(role,_,_)) in enumerate(zip(
        ['TRUNK_LP','LEAVES_LP','LEAVES_LP_spod','FOLIAGE_HP','GEM_LP','KAMIEN_LP'],specs))}
    height=28.;tile=256;atlas_size=1024
bpy.context.view_layer.update()
objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.name!='Plane.007']
assert all(len(o.data.uv_layers)>0 for o in objects)
all_points=[o.matrix_world@v.co for o in objects for v in o.data.vertices]
low=min(v.z for v in all_points);high=max(v.z for v in all_points);scale=height/(high-low)
# Translation preserves the original X/Y origin; ground is the lowest source point.
def normalized(obj,v):
    p=obj.matrix_world@v;p.z-=low;return p*scale

# Shared neutral albedo atlas enables tinting without painting over the source.
# Alpha masks are kept for foliage only. Padding prevents atlas tile bleeding.
atlas=np.ones((atlas_size,atlas_size,4),dtype=np.float32);atlas[:,:,:3]=.5
columns=atlas_size//tile;pad=3
for i,(role,file,mask) in enumerate(specs):
    image=rgb_image(file,tile-2*pad)
    if role in ('Leaf','LeafSecondary'):
        lum=image[:,:,:3]@np.array([.2126,.7152,.0722])
        image[:,:,:3]=np.repeat(np.clip(.55+.45*lum,0,1)[:,:,None],3,axis=2)
        mask_data=rgb_image(file if mask=='SELF' else mask,tile-2*pad)
        image[:,:,3]=mask_data[:,:,3 if mask=='SELF' else 0]
    elif role=='Magic':
        lum=np.max(image[:,:,:3],axis=2);image[:,:,:3]=np.repeat(lum[:,:,None],3,axis=2)
        image[:,:,3]=1
    else:image[:,:,3]=1
    padded=np.pad(image,((pad,pad),(pad,pad),(0,0)),mode='edge')
    x=(i%columns)*tile;y=(i//columns)*tile;atlas[y:y+tile,x:x+tile]=padded
atlas_image=bpy.data.images.new(KEY+'_Atlas',width=atlas_size,height=atlas_size,alpha=True)
atlas_image.colorspace_settings.name='Non-Color';atlas_image.pixels.foreach_set(atlas.ravel())
atlas_image.filepath_raw=str(OUT/'Atlas.png');atlas_image.file_format='PNG';atlas_image.save()

def atlas_uv(uv,slot):
    # Reject tiled UVs instead of silently folding triangles across an atlas seam.
    u,v=uv
    assert -1e-4<=u<=1.0001 and -1e-4<=v<=1.0001, 'Source requires explicit tiled-UV adaptation'
    u=max(0,min(1,u));v=max(0,min(1,v))
    return [((slot%columns)*tile+pad+u*(tile-2*pad))/atlas_size,
            ((slot//columns)*tile+pad+v*(tile-2*pad))/atlas_size]

records=[];source_triangles=0
for obj in objects:
    mesh=obj.data;mesh.calc_loop_triangles();source_triangles+=len(mesh.loop_triangles)
    # Connected components allow removal of entire leaf cards, never random faces.
    parents=list(range(len(mesh.vertices)))
    def find(i):
        while parents[i]!=i:parents[i]=parents[parents[i]];i=parents[i]
        return i
    for edge in mesh.edges:parents[find(edge.vertices[1])]=find(edge.vertices[0])
    groups=defaultdict(list)
    for tri in mesh.loop_triangles:groups[find(tri.vertices[0])].append(tri)
    ordered=sorted(groups)
    for gi,component in enumerate(ordered):
        for tri in groups[component]:
            mat=mesh.materials[tri.material_index].name
            role,slot=roles[mat]
            if KEY=='stylized_stefan' and obj.name=='Plane.002' and role=='Leaf':role='LeafSecondary'
            pts=[normalized(obj,mesh.vertices[v].co) for v in tri.vertices]
            part=role
            if role=='Bark':
                part='Roots' if max(p.z for p in pts)<height*.12 else 'Branches' if min(p.z for p in pts)>height*.43 else 'Trunk'
            elif role in ('Leaf','LeafSecondary'):part='Foliage' if role=='Leaf' else 'FoliageSecondary'
            else:part='Extras_'+role
            # Never thin a connected crown wholesale; only individual small cards.
            removable=role in ('Leaf','LeafSecondary') and len(groups[component])<=24 and len(ordered)>15
            records.append({'part':part,'role':role,'points':pts,
                'uv':[atlas_uv(mesh.uv_layers.active.data[l].uv,slot) for l in tri.loops],
                'densityRank':((gi*37+len(obj.name)*11)%100) if removable else 100})

# Remove imported scene objects without modifying or saving the source .blend.
for obj in list(bpy.data.objects):bpy.data.objects.remove(obj,do_unlink=True)
bpy.context.view_layer.update()
palette={'Bark':(.88,.77,.65),'Leaf':(.38,.78,.38),'LeafSecondary':(.24,.57,.43),
         'Magic':(.43,.85,1),'Stone':(.78,.81,.86)}
materials={}
for role,tint in palette.items():
    mat=bpy.data.materials.new(role);mat.use_nodes=True
    nodes=mat.node_tree.nodes;links=mat.node_tree.links;bs=nodes.get('Principled BSDF')
    tex=nodes.new('ShaderNodeTexImage');tex.image=atlas_image
    mult=nodes.new('ShaderNodeMixRGB');mult.blend_type='MULTIPLY';mult.inputs[0].default_value=1;mult.inputs[2].default_value=(*tint,1)
    links.new(tex.outputs['Color'],mult.inputs[1]);links.new(mult.outputs[0],bs.inputs['Base Color']);bs.inputs['Roughness'].default_value=.87
    if role in ('Leaf','LeafSecondary'):
        links.new(tex.outputs['Alpha'],bs.inputs['Alpha']);mat.surface_render_method='DITHERED';mat.use_transparency_overlap=False
    if role=='Magic':links.new(mult.outputs[0],bs.inputs['Emission Color']);bs.inputs['Emission Strength'].default_value=.25
    materials[role]=mat

presets=json.loads((LIB/'geometry-presets.json').read_text())
assert len(presets)==2 and [c['id'] for c in presets]==['Natural','Windswept']
for c in presets:
    assert .75<=c['TrunkHeight']<=1.3 and .7<=c['TrunkWidth']<=1.3 and abs(c['TrunkCurvature'])<=.15
    assert .7<=c['BranchSpread']<=1.3 and .7<=c['CrownSize']<=1.3 and .5<=c['FoliageDensity']<=1
    assert len(c['CrownShape'])==2 and all(.7<=n<=1.3 for n in c['CrownShape'])

def deform(p,c):
    x,y,z=p;h=z/height;canopy=smooth((h-.36)/.4);base=smooth(h/.16)
    radial=c['TrunkWidth']*(1-canopy)+c['BranchSpread']*c['CrownSize']*canopy
    x=x*radial*(1+(c['CrownShape'][0]-1)*canopy)+height*c['TrunkCurvature']*base*h*h
    y=y*radial*(1+(c['CrownShape'][1]-1)*canopy)
    z=z+(c['TrunkHeight']-1)*height*smooth((h-.06)/.94)+(c['CrownSize']-1)*(z-height*.6)*canopy
    return Vector((x,y,z))

def weights(p):
    h=p.z/height
    if h<=.18:return [[0,1.]]
    if h<.30:
        a=smooth((h-.18)/.12);return [[0,1-a],[1,a]]
    angle=(math.atan2(p.y,p.x)%(math.tau))/math.tau*4
    sector=int(angle)%4;next_sector=(sector+1)%4;mix=smooth(angle%1)
    angular=[(sector,1-mix),(next_sector,mix)]
    out=[]
    if h<.50:
        a=smooth((h-.30)/.20);out=[[1,1-a]]+[[2+i,a*w] for i,w in angular]
    else:
        a=smooth((h-.50)/.25);out=[[2+i,(1-a)*w] for i,w in angular]+[[6+i,a*w] for i,w in angular]
    return [[i,round(w,8)] for i,w in out if w>1e-7]

variants=[];blend_objects=[]
for vi,c in enumerate(presets):
    collection=bpy.data.collections.new(c['id']);bpy.context.scene.collection.children.link(collection)
    armdata=bpy.data.armatures.new(KEY+'_'+c['id']);arm=bpy.data.objects.new('TreeRig_'+c['id'],armdata);collection.objects.link(arm)
    for k,v in c.items():arm[k]=v
    bpy.context.view_layer.objects.active=arm;arm.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    bone_defs=[('Root',Vector((0,0,0)),'Root'),('Trunk',Vector((0,0,height*.06)),'Trunk')]
    for layer,y,radius in [('Branch',.40,.12),('Crown',.62,.23)]:
        for i in range(4):
            a=i*math.tau/4;bone_defs.append((layer+str(i+1),Vector((math.cos(a)*height*radius,math.sin(a)*height*radius,height*y)), 'Branch' if layer=='Branch' else 'Foliage'))
    bones=[];root_bone=None
    for name,p,role in bone_defs:
        at=deform(p,c);bone=armdata.edit_bones.new(name);bone.head=at;bone.tail=at+Vector((0,0,1))
        if root_bone:bone.parent=root_bone
        else:root_bone=bone
        bones.append({'name':name,'position':rbx(at),'role':role,'parent':0 if name!='Root' else -1})
    bpy.ops.object.mode_set(mode='OBJECT');arm.select_set(False)
    by_part=defaultdict(list)
    for r in records:
        if r['densityRank']<(1-c['FoliageDensity'])*100:continue
        by_part[r['part']].append(r)
    # Preserve smooth wood normals across the editable Roots/Trunk/Branches seams.
    wood_normals=defaultdict(lambda:Vector((0,0,0)))
    for faces in by_part.values():
        for f in faces:
            if f['role']!='Bark':continue
            a,b,d=[deform(p,c) for p in f['points']];n=(b-a).cross(d-a)
            for p in f['points']:wood_normals[tuple(round(x,7) for x in p)]+=n
    exported=[];parts=[]
    for part,faces in sorted(by_part.items()):
        role=faces[0]['role'];verts=[];tris=[];uvs=[];skin=[];lookup={}
        for f in faces:
            ids=[]
            for p in f['points']:
                key=tuple(round(x,7) for x in p)
                if key not in lookup:
                    lookup[key]=len(verts);verts.append(deform(p,c));skin.append([[0,1.]] if role in ('Stone','Magic') else weights(p))
                ids.append(lookup[key])
            if len(set(ids))<3:continue
            tris.append(ids);uvs.append(f['uv'])
        mesh=bpy.data.meshes.new(part);mesh.from_pydata(verts,[],tris);mesh.update();mesh.materials.append(materials[role])
        uv=mesh.uv_layers.new(name='UVMap')
        for f,coords in zip(mesh.polygons,uvs):
            f.use_smooth=role not in ('Magic','Stone')
            for l,xy in zip(f.loop_indices,coords):uv.data[l].uv=xy
        if role=='Bark':
            normal_list=[Vector((0,0,1)) for _ in verts]
            for key,index in lookup.items():
                n=wood_normals[key];normal_list[index]=n.normalized() if n.length>1e-9 else Vector((0,0,1))
            mesh.normals_split_custom_set_from_vertices(normal_list)
        obj=bpy.data.objects.new(part,mesh);collection.objects.link(obj);parts.append(obj)
        obj['VegetationRole']=role;obj['Source']=KEY;obj['GeometryVariant']=c['id'];obj.parent=arm
        vg=[obj.vertex_groups.new(name=b['name']) for b in bones]
        for i,ws in enumerate(skin):
            total=sum(w for _,w in ws)
            for bi,w in ws:vg[bi].add([i],w/total,'REPLACE')
        modifier=obj.modifiers.new('TreeSkin','ARMATURE');modifier.object=arm
        mesh.calc_loop_triangles()
        normals=[[rbx(mesh.corner_normals[l].vector.normalized()) for l in t.loops] for t in mesh.loop_triangles]
        exported.append({'name':part,'role':role,'vertices':[rbx(v) for v in verts],'triangles':tris,
                         'uv':[[[u,1-v] for u,v in f] for f in uvs],'normals':normals,'weights':skin})
    bpy.context.view_layer.update()
    # Preview action is optional authoring data; runtime wind uses GlobalWind instead.
    scene=bpy.context.scene;scene.render.fps=30;scene.frame_start=1;scene.frame_end=241
    for frame in range(1,242,5):
        t=(frame-1)/30
        for bi,b in enumerate(bones[1:]):
            bone=arm.pose.bones[b['name']];bone.rotation_mode='XYZ'
            strength=.12 if b['role']=='Trunk' else .65 if b['role']=='Branch' else 1
            a=math.sin(t*math.tau/8-bi*.35)*.055*strength
            bone.rotation_euler=(a,0,a*.35);bone.keyframe_insert('rotation_euler',frame=frame,group=bone.name)
    arm.animation_data.action.name=KEY+'_'+c['id']+'_WindPreview'
    arm.animation_data.action.use_fake_user=True
    arm.animation_data_clear()
    for b in arm.pose.bones:b.rotation_euler=(0,0,0)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [arm,*parts]:obj.hide_set(False);obj.select_set(True)
    bpy.context.view_layer.objects.active=arm
    bpy.ops.export_scene.fbx(filepath=str(OUT/(c['id']+'.fbx')),use_selection=True,object_types={'MESH','ARMATURE'},add_leaf_bones=False,
        apply_unit_scale=True,apply_scale_options='FBX_SCALE_UNITS',axis_forward='-Z',axis_up='Y',use_mesh_modifiers=False,
        bake_anim=False,path_mode='COPY',embed_textures=True)
    variants.append({'id':c['id'],'parameters':c,'bones':bones,'meshes':exported})
    blend_objects.append([arm,*parts])
    for obj in [arm,*parts]:obj.hide_set(vi>0)
atlas_image.pack()
bpy.data.orphans_purge(do_recursive=True)
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Editable.blend'))
data={'schema':1,'key':KEY,'height':height,'sourceTriangles':source_triangles,'atlasSize':atlas_size,
      'variants':variants,'sourceArchiveSHA256':json.loads((SOURCE.parent/'receipt.json').read_text())['archiveSHA256']}
(OUT/'Tree.mesh.json').write_text(json.dumps(data,separators=(',',':')),encoding='utf-8')
report={'key':KEY,'variants':[{'id':v['id'],'triangles':sum(len(m['triangles']) for m in v['meshes']),
    'authoringParts':len(v['meshes']),'bones':len(v['bones'])} for v in variants],
    'textureCount':1,'textureSize':atlas_size,'blenderVersion':bpy.app.version_string,
    'removed':['Original preview armature/action','Drop shadow plane'] if KEY=='magic_igor' else [],
    'sourceNormalsNotBaked':True,'screenshots':0,'uploads':0,'studioVerified':False}
(OUT/'build-report.json').write_text(json.dumps(report,indent=2)+'\n')
print('VEGETATION_BUILD '+json.dumps(report))
