"""FBX round-trip, skinning and loop validation. Never renders."""
import bpy,pathlib,json,math,hashlib
ROOT=pathlib.Path(__file__).resolve().parents[2];OUT=ROOT/'assets/environment/willow-v2/prepared'
reports=[]
for variant in range(1,4):
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.scene.render.fps=30
    path=OUT/f'WillowV2_{variant}.fbx';bpy.ops.import_scene.fbx(filepath=str(path))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH'];rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
    assert len(meshes)==2 and len(rigs)==1 and len(rigs[0].data.bones)==9
    report={'variant':variant,'fbxSha256':hashlib.sha256(path.read_bytes()).hexdigest(),'meshes':[]}
    for obj in meshes:
        mesh=obj.data;mesh.calc_loop_triangles();assert len(mesh.uv_layers)==1 and len(mesh.materials)==1
        for uv in mesh.uv_layers[0].data:assert all(math.isfinite(n) for n in uv.uv)
        for v in mesh.vertices:
            if 'Foliage' in obj.name:
                assert 1<=len(v.groups)<=2 and abs(sum(g.weight for g in v.groups)-1)<1e-5
            else:assert len(v.groups)==0
        report['meshes'].append({'name':obj.name,'triangles':len(mesh.loop_triangles),'vertices':len(mesh.vertices)})
    assert sum(m['triangles'] for m in report['meshes'])==5783
    def at(frame):
        bpy.context.scene.frame_set(frame);deps=bpy.context.evaluated_depsgraph_get();points={}
        for obj in meshes:
            e=obj.evaluated_get(deps);m=e.to_mesh();points[obj.name]=[e.matrix_world@v.co for v in m.vertices];e.to_mesh_clear()
        return points
    a,b,end=at(1),at(61),at(241)
    for name in a:
        motion=max((p-q).length for p,q in zip(a[name],b[name]));seam=max((p-q).length for p,q in zip(a[name],end[name]))
        assert seam<.01
        if 'Trunk' in name:assert motion<1e-7
        else:assert .005<motion<2
        report[name]={'motion':motion,'loopSeam':seam}
    reports.append(report)
(OUT/'validation.json').write_text(json.dumps({'roundtrip':'PASS','variants':reports,'rendersCreated':0},indent=2))
print('WILLOW_V2_VALIDATION '+json.dumps(reports))
