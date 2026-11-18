"""Fresh FBX round-trip and numerical skin deformation checks, without images."""
import bpy, json, pathlib, sys, math
from mathutils import Vector
ROOT=pathlib.Path(__file__).resolve().parents[2]
KEY=sys.argv[sys.argv.index('--')+1]
assert KEY in ('stylized_stefan','magic_igor')
OUT=ROOT/'assets/environment/vegetation-v2/prepared'/KEY
data=json.loads((OUT/'Tree.mesh.json').read_text())
report=[]
for variant in data['variants']:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(OUT/(variant['id']+'.fbx')),use_anim=False)
    bpy.context.view_layer.update()
    arms=[o for o in bpy.context.scene.objects if o.type=='ARMATURE'];assert len(arms)==1
    arm=arms[0];assert len(arm.data.bones)==10 and set(arm.data.bones.keys())==set(b['name'] for b in variant['bones'])
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];assert len(meshes)==len(variant['meshes'])
    deps=bpy.context.evaluated_depsgraph_get()
    def positions(obj):
        evaluated=obj.evaluated_get(deps);mesh=evaluated.to_mesh()
        points=[obj.matrix_world@v.co for v in mesh.vertices];evaluated.to_mesh_clear();return points
    before={o.name:positions(o) for o in meshes}
    for o in meshes:
        assert o.parent==arm
        for v in o.data.vertices:
            weights=[g.weight for g in v.groups if g.weight>1e-6]
            assert 1<=len(weights)<=4 and abs(sum(weights)-1)<1e-5
        o.data.calc_loop_triangles()
    triangles=sum(len(o.data.loop_triangles) for o in meshes)
    expected=sum(len(m['triangles']) for m in variant['meshes']);assert triangles==expected,(triangles,expected)
    for b in arm.pose.bones:
        if b.name!='Root':b.rotation_mode='XYZ';b.rotation_euler=(.045,.025,-.02)
    bpy.context.view_layer.update();deps.update()
    displacements={}
    for o in meshes:
        after=positions(o);delta=[(a-b).length for a,b in zip(after,before[o.name])]
        displacements[o.name]=max(delta)
        if o.name.startswith(('Roots','Extras')):assert max(delta)<1e-5,(o.name,max(delta))
        if o.name.startswith('Foliage'):assert max(delta)>.01,(o.name,max(delta))
    all_points=[p for points in before.values() for p in points]
    bounds=[[round(f(p[k] for p in all_points),6) for k in range(3)] for f in (min,max)]
    report.append({'variant':variant['id'],'triangles':triangles,'bones':len(arm.data.bones),
                   'boundsBlender':bounds,'maxDeformation':displacements,'rootsFixed':True,'weightsNormalized':True})
# Editable source must contain both organized variants and no external images.
bpy.ops.wm.open_mainfile(filepath=str(OUT/'Editable.blend'),load_ui=False,use_scripts=False)
assert all(c in bpy.data.collections for c in ('Natural','Windswept'))
external=[i.name for i in bpy.data.images if i.source=='FILE' and not i.packed_file];assert not external,external
assert len([a for a in bpy.data.actions if 'WindPreview' in a.name])==2
result={'key':KEY,'blender':bpy.app.version_string,'fbxRoundtrip':report,'packedTextures':True,
        'renders':0,'studioPlay':'NOT_RUN','artReview':'PENDING'}
(OUT/'validation.json').write_text(json.dumps(result,indent=2)+'\n')
print('VEGETATION_VALIDATION '+json.dumps(result))
