"""Re-import exported FBX into fresh Blender scenes and audit actual skin/clip."""
import bpy, json, hashlib
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parent.parent
expected={'Root','Contact','Body','Head','EdgeFL','EdgeFR','EdgeBL','EdgeBR'}
results=[]
for name,animated in [('GreenSlime_Rig.fbx',False),('GreenSlime_Idle.fbx',True)]:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(OUT/name),use_anim=True)
    objects=list(bpy.context.scene.objects)
    meshes=[o for o in objects if o.type=='MESH']; rigs=[o for o in objects if o.type=='ARMATURE']
    assert len(meshes)==1 and len(rigs)==1 and len(objects)==2
    mesh,rig=meshes[0],rigs[0]; mesh.data.calc_loop_triangles()
    assert set(b.name for b in rig.data.bones)==expected
    assert len(mesh.data.vertices)==1321 and len(mesh.data.loop_triangles)==2603
    assert len(mesh.data.uv_layers)==1 and len(mesh.data.materials)==1
    assert any(m.type=='ARMATURE' and m.object==rig for m in mesh.modifiers)
    max_weights=0; root_weights=0
    for v in mesh.data.vertices:
        weights=[g for g in v.groups if g.weight>1e-7]; max_weights=max(max_weights,len(weights))
        assert 1<=len(weights)<=4 and abs(sum(g.weight for g in weights)-1)<1e-5
        root_weights+=sum(1 for g in weights if mesh.vertex_groups[g.group].name=='Root')
    assert root_weights==0
    images=[i for i in bpy.data.images if i.packed_file]
    assert len(images)==1 and tuple(images[0].size)==(2048,2048)
    assert hashlib.sha256(images[0].packed_file.data).hexdigest()=='631f17ac3724ab7b689c11c5f038242ca68bb38198058c59ab84cf47337b5805'
    row={'file':name,'objects':[(o.name,o.type) for o in objects],'bones':sorted(expected),'vertices':len(mesh.data.vertices),'triangles':len(mesh.data.loop_triangles),'maxWeights':max_weights,'rootWeights':root_weights,'textureByteIdentical':True}
    if animated:
        assert rig.animation_data and rig.animation_data.action
        action=rig.animation_data.action
        first,last=action.frame_range
        # FBX time is in seconds: Blender imports at the current scene FPS.
        row.update(action=action.name,range=[first,last],fps=bpy.context.scene.render.fps)
        duration=(last-first)/bpy.context.scene.render.fps
        assert abs(duration-3.2)<1e-5
        positions=[]; min_ground=1e6
        for i in range(97):
            t=first+(last-first)*i/96; bpy.context.scene.frame_set(int(t),subframe=t-int(t)); bpy.context.view_layer.update()
            obj=mesh.evaluated_get(bpy.context.evaluated_depsgraph_get()); data=obj.to_mesh()
            pts=[obj.matrix_world@v.co for v in data.vertices]; positions.append(pts); obj.to_mesh_clear()
            min_ground=min(min_ground,min(p.z for p in pts))
        seam=max((a-b).length for a,b in zip(positions[0],positions[-1]))
        travel=max((a-b).length for a,b in zip(positions[0],positions[24]))
        assert seam<1e-5 and travel>.005 and min_ground>=-1e-5
        row.update(durationSeconds=duration,loopMaxVertexDelta=seam,quarterCycleTravel=travel,minimumGroundClearance=min_ground)
    else: assert not rig.animation_data or not rig.animation_data.action
    results.append(row)
(OUT/'fbx-roundtrip.json').write_text(json.dumps({'blender':bpy.app.version_string,'results':results},indent=2)+'\n',encoding='utf-8')
print('AG73 FBX ROUNDTRIP PASS',json.dumps(results))
