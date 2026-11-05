"""Reproducible local Blender preparation for the approved CC0 Standard subset.

Run with portable Blender 4.5.9 --background --factory-startup --disable-autoexec
--python scripts/prepare-environment-assets.py -- SOURCE_DIR OUTPUT_DIR AUDIT_JSON.
Does not upload, publish, install plugins, or execute content from source assets.
The owner authorized direct preparation/import instead of missing game-dev.
"""
import bpy, bmesh, hashlib, json, math, sys, tempfile
from pathlib import Path
from mathutils import Vector

args = sys.argv[sys.argv.index('--')+1:]
source, output, audit_path = map(lambda p: Path(p).resolve(), args)
audit = json.loads(audit_path.read_text(encoding='utf-8'))
assert audit['sha256'] == '298f6732b872e4cf7b30e6e7abf9641c7f6dc6b326df37ac089533ed7e3d58c9'
roster = {r['path']:r['sha256'] for r in audit['files']}
for rel in audit['selected_files']:
    assert hashlib.sha256((source/rel).read_bytes()).hexdigest() == roster[rel], rel
output.mkdir(parents=True, exist_ok=True)
assert not list(output.glob('*.gltf')), 'Use an empty output directory; do not overwrite another preparation'
temp_root=output/'_temp'; temp_root.mkdir(exist_ok=True)
tempfile.tempdir=str(temp_root)
bpy.context.preferences.filepaths.temporary_directory=str(temp_root)

heights = {'CommonTree_1':25,'CommonTree_3':22,'CommonTree_5':19,
           'TwistedTree_1':24,'Pine_2':25,'Grass_Common_Short':1.1,
           'Grass_Wispy_Tall':1.8,'Bush_Common_Flowers':3.4,'Clover_2':.55,
           'Fern_1':1.9,'Flower_3_Group':1.6,'Rock_Medium_1':3.2,
           'Pebble_Round_1':.45,'RockPath_Round_Small_1':.12}
report = {'blender':bpy.app.version_string, 'source_archive_sha256':audit['sha256'],
          'authorization':'Owner approved direct verification, optimization and Studio import in chat on 2026-11-05; no game-dev receipt claimed',
          'license':'CC0-1.0, acquired License_Standard.txt',
          'settings':{'small_prop_triangles':500,'tree_triangles':2000,'max_texture_side':1024,
                      'texture_policy':'Bark diffuse and common leaf atlas 1024; other maps 512',
                      'pivot':'XZ center, bottom at zero','units':'Roblox studs, explicit per-model height'},
          'models':[], 'files':{}}
library = []
for n, entry in enumerate(audit['selected']):
    name = entry['name']
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    for data in list(bpy.data.meshes):
        if data.users == 0: bpy.data.meshes.remove(data)
    bpy.ops.import_scene.gltf(filepath=str(source/entry['path']))
    meshes = [o for o in bpy.context.scene.objects if o.type=='MESH']
    for obj in meshes:
        bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active=obj
        bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
        if len(obj.data.materials)>1:
            bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
            bpy.ops.mesh.separate(type='MATERIAL'); bpy.ops.object.mode_set(mode='OBJECT')
    meshes = [o for o in bpy.context.scene.objects if o.type=='MESH']
    points = [o.matrix_world@Vector(p) for o in meshes for p in o.bound_box]
    lo = Vector(tuple(min(p[i] for p in points) for i in range(3)))
    hi = Vector(tuple(max(p[i] for p in points) for i in range(3)))
    center = Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
    scale = heights[name]/(hi.z-lo.z)
    is_tree = 'Tree' in name or name.startswith('Pine')
    target_total = 1950 if is_tree else 480
    original_counts=[]
    for obj in meshes:
        obj.data.calc_loop_triangles(); original_counts.append(len(obj.data.loop_triangles))
    total_before = sum(original_counts)
    count_after = 0
    for j,(obj,before) in enumerate(zip(meshes,original_counts)):
        slot = obj.data.polygons[0].material_index if obj.data.polygons else 0
        material = obj.data.materials[slot] if obj.data.materials else None
        material_name = material.name if material else 'Default'
        target = (800 if 'Bark' in material_name else 1150) if is_tree else max(20,int(target_total*before/max(1,total_before)))
        bpy.ops.object.select_all(action='DESELECT'); obj.select_set(True); bpy.context.view_layer.objects.active=obj
        if 'Bark' in material_name:
            # Exported normals/UV seams duplicate coincident vertices. Welding
            # geometry preserves per-loop UVs and lets collapse simplify branches.
            bm=bmesh.new(); bm.from_mesh(obj.data)
            bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=0.00001)
            bm.to_mesh(obj.data); bm.free()
        if is_tree and 'Bark' not in material_name and before>target:
            # Alpha foliage is made of disconnected leaf cards. Collapsing each
            # card leaves irreducible isolated triangles and damages its outline.
            # Thin complete cards deterministically instead, preserving extrema.
            bm=bmesh.new(); bm.from_mesh(obj.data); remaining=set(bm.verts); groups=[]
            while remaining:
                first=next(iter(remaining)); stack=[first]; component=set()
                while stack:
                    v=stack.pop()
                    if v in component: continue
                    component.add(v); remaining.discard(v)
                    stack.extend(e.other_vert(v) for e in v.link_edges if e.other_vert(v) not in component)
                faces={f for v in component for f in v.link_faces}
                center_card=sum((v.co for v in component),Vector())/len(component)
                groups.append((component,sum(len(f.verts)-2 for f in faces),center_card))
            if len(groups)>8:
                groups.sort(key=lambda g:tuple(round(v,6) for v in g[2]))
                extremes={min(range(len(groups)),key=lambda k:groups[k][2][axis]) for axis in range(3)}
                extremes.update(max(range(len(groups)),key=lambda k:groups[k][2][axis]) for axis in range(3))
                order=sorted(range(len(groups)),key=lambda k:(k not in extremes,hashlib.sha256((','.join(f'{v:.5f}' for v in groups[k][2])).encode()).hexdigest()))
                keep=set(); used=0
                for k in order:
                    if used+groups[k][1]<=target: keep.add(k); used+=groups[k][1]
                remove=[v for k,g in enumerate(groups) if k not in keep for v in g[0]]
                bmesh.ops.delete(bm,geom=remove,context='VERTS'); bm.to_mesh(obj.data)
                obj.data.calc_loop_triangles(); before=len(obj.data.loop_triangles)
            bm.free()
        if before>target:
            modifier=obj.modifiers.new('M7_BoundedDecimation','DECIMATE')
            modifier.ratio=max(.01,(target-4)*.9/before); modifier.use_collapse_triangulate=True
            bpy.ops.object.modifier_apply(modifier=modifier.name)
            # Disconnected leaf cards can survive a collapse pass above its nominal
            # ratio. Triangulate explicitly and remeasure, never trust the ratio.
            obj.data.calc_loop_triangles()
            for attempt in range(3):
                measured=len(obj.data.loop_triangles)
                if measured<=target: break
                tri=obj.modifiers.new('M7_Triangulate','TRIANGULATE')
                bpy.ops.object.modifier_apply(modifier=tri.name)
                modifier=obj.modifiers.new('M7_EnforceBudget','DECIMATE')
                modifier.ratio=max(.01,(target-12)*.8/measured)
                modifier.use_collapse_triangulate=True
                bpy.ops.object.modifier_apply(modifier=modifier.name)
                obj.data.calc_loop_triangles()
        # Bake the transform into vertices; every reusable asset has a ground pivot.
        matrix=obj.matrix_world.copy()
        for vertex in obj.data.vertices: vertex.co=(matrix@vertex.co-center)*scale
        obj.matrix_world.identity(); obj.name=name+'_'+('Bark' if 'Bark' in material_name else 'Foliage' if is_tree else str(j+1))
        obj.data.calc_loop_triangles(); count_after+=len(obj.data.loop_triangles)
        print('M7_PART '+name+' '+material_name+' target='+str(target)+' actual='+str(len(obj.data.loop_triangles)),flush=True)
        if material and 'Bark' in material_name:
            material.surface_render_method='DITHERED'
            # Bark is opaque; remove accidental alpha-test mode inherited from source.
            material['gltf_alpha_mode']='OPAQUE'
        if material and material.use_nodes:
            for node in material.node_tree.nodes:
                if node.type=='TEX_IMAGE' and node.image:
                    img=node.image
                    detailed=('Bark_' in img.name and '_Normal' not in img.name.replace('Bark_NormalTree','BarkTree')) or 'Leaves_NormalTree' in img.name
                    limit=1024 if detailed else 512
                    if max(img.size)>limit:
                        fac=limit/max(img.size); img.scale(max(1,round(img.size[0]*fac)),max(1,round(img.size[1]*fac)))
    assert count_after <= (2000 if is_tree else 500), (name,count_after)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in meshes: obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(output/(name+'.gltf')),export_format='GLTF_SEPARATE',
        use_selection=True,export_texture_dir='textures',export_yup=True,export_animations=False,
        export_cameras=False,export_lights=False,export_apply=True,export_image_format='AUTO',export_extras=False)
    # Keep a normalized source file for repeatable inspection and contact-sheet rendering.
    bpy.ops.wm.save_as_mainfile(filepath=str(output/(name+'.blend')),check_existing=False)
    points=[o.matrix_world@Vector(p) for o in meshes for p in o.bound_box]
    bounds=[[min(p[i] for p in points) for i in range(3)],[max(p[i] for p in points) for i in range(3)]]
    report['models'].append({'name':name,'triangles_before':total_before,'triangles_after':count_after,
                             'mesh_parts':len(meshes),'height_studs':heights[name],'bounds_blender_xyz':bounds})
    print('M7_PREP '+name+' '+str(total_before)+' -> '+str(count_after),flush=True)

# Compose one import file, with models in a review grid. Runtime uses templates by name.
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
for i,entry in enumerate(report['models']):
    before=set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(output/(entry['name']+'.gltf')))
    imported=[o for o in bpy.context.scene.objects if o not in before]
    anchor=bpy.data.objects.new(entry['name'],None); bpy.context.scene.collection.objects.link(anchor)
    for obj in imported:
        if obj.parent is None: obj.parent=anchor
    anchor.location=((i%4)*35,(i//4)*35,0)
bpy.ops.export_scene.gltf(filepath=str(output/'M7NatureLibrary.gltf'),export_format='GLTF_SEPARATE',
    export_texture_dir='library-textures',export_yup=True,export_animations=False,export_cameras=False,
    export_lights=False,export_apply=True,export_extras=False)
bpy.ops.wm.save_as_mainfile(filepath=str(output/'M7NatureLibrary.blend'),check_existing=False)
for path in sorted(output.rglob('*')):
    if path.is_file() and path.suffix not in ('.blend','.blend1'):
        report['files'][path.relative_to(output).as_posix()]=hashlib.sha256(path.read_bytes()).hexdigest()
(output/'preparation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('M7_PREP_COMPLETE '+str(len(report['models'])),flush=True)
