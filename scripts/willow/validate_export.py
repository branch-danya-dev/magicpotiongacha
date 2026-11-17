"""Round-trip exported FBX, assert rig/UV/weights and measured deformation."""
import bpy, pathlib, json, math, hashlib
ROOT=pathlib.Path(__file__).resolve().parents[2]
ASSET=ROOT/'assets/environment/willow';OUT=ASSET/'prepared'
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.scene.render.fps=30
bpy.ops.import_scene.fbx(filepath=str(OUT/'Willow.fbx'))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
assert len(meshes)==2 and len(rigs)==1
arm=rigs[0];assert len(arm.data.bones)==9
assert set(b.name for b in arm.data.bones)=={'Root'}|{'Crown_%02d'%(i+1) for i in range(8)}
report={'roundtrip':'PASS','meshes':[],'bones':9}
for o in meshes:
    m=o.data;m.calc_loop_triangles();assert len(m.uv_layers)==1
    assert len(m.materials)==1
    for uv in m.uv_layers[0].data:assert all(math.isfinite(n) for n in uv.uv)
    if o.name=='Willow_Foliage':
        for v in m.vertices:
            assert 1<=len(v.groups)<=2
            assert abs(sum(g.weight for g in v.groups)-1)<1e-5
            assert all(0<=g.weight<=1 for g in v.groups)
    else:assert len(o.vertex_groups)==0
    report['meshes'].append({'name':o.name,'vertices':len(m.vertices),'triangles':len(m.loop_triangles),'uvLayers':len(m.uv_layers)})
assert sum(x['triangles'] for x in report['meshes'])<=6500
scene=bpy.context.scene
def evaluated(frame):
    scene.frame_set(frame);deps=bpy.context.evaluated_depsgraph_get()
    result={}
    for o in meshes:
        e=o.evaluated_get(deps);m=e.to_mesh();result[o.name]=[e.matrix_world@v.co for v in m.vertices];e.to_mesh_clear()
    return result
a=evaluated(1);b=evaluated(61);end=evaluated(241)
for name in a:
    displacement=max((p-q).length for p,q in zip(a[name],b[name]))
    seam=max((p-q).length for p,q in zip(a[name],end[name]))
    report[name]={'maxDisplacement':displacement,'loopSeam':seam}
    assert seam<.01,(name,seam) # FBX baked curve quantization: under 0.05% of tree height.
    if name=='Willow_Trunk':assert displacement<1e-7
    else:assert .005<displacement<2
report['sourceSha256']=hashlib.sha256((ASSET/'source/Meshy_AI_model_20261117_generate.fbx').read_bytes()).hexdigest()
report['fbxSha256']=hashlib.sha256((OUT/'Willow.fbx').read_bytes()).hexdigest()
report['meshSha256']=hashlib.sha256((OUT/'Willow.mesh.json').read_bytes()).hexdigest()
assert report['sourceSha256']=='c6d4ce5eac77a3d260bb184583e86f5f0d3adb65f974fd923c47a9ed30a515a6'
(OUT/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('WILLOW_VALIDATION '+json.dumps(report))
