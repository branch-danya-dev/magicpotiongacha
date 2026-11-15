"""Fresh-import V2 files, compare actual rest/skin to V1, evaluate baked loops."""
import bpy
import bmesh
import hashlib
import json
from pathlib import Path

OUT = Path(__file__).resolve().parents[1]
V1 = OUT.parent/'rig_v1'
NAMES = {'Root', 'Contact', 'Body', 'Head', 'EdgeFL', 'EdgeFR', 'EdgeBL', 'EdgeBR'}
expected_texture = hashlib.sha256((V1/'GreenSlime.png').read_bytes()).hexdigest()


def snapshot(mesh, rig):
    return {'vertices': [list(v.co) for v in mesh.data.vertices],
            'polygons': [list(p.vertices) for p in mesh.data.polygons],
            'uv': [list(v.uv) for v in mesh.data.uv_layers.active.data],
            'skin': [{mesh.vertex_groups[g.group].name: g.weight for g in v.groups} for v in mesh.data.vertices],
            'bones': {b.name: {'parent': b.parent.name if b.parent else None,
                              'matrix': [list(r) for r in b.matrix_local]} for b in rig.data.bones}}


def load(path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(path), use_anim=True)
    objects = list(bpy.context.scene.objects)
    assert len(objects) == 2
    mesh = next(o for o in objects if o.type == 'MESH')
    rig = next(o for o in objects if o.type == 'ARMATURE')
    return mesh, rig


m, r = load(V1/'GreenSlime_Rig.fbx')
baseline = snapshot(m, r)
rows = []
for name, duration in [('Idle_Calm', 3.6), ('Idle_Active', 3.)]:
    m, r = load(OUT/(name+'.fbx'))
    current = snapshot(m, r)
    assert current == baseline, 'same exact FBX rest geometry/UV/weights/bone matrices as V1'
    assert set(current['bones']) == NAMES
    m.data.calc_loop_triangles()
    assert len(m.data.vertices) == 1321 and len(m.data.loop_triangles) == 2603
    assert len(m.data.uv_layers) == 1 and len(m.data.materials) == 1
    assert all(1 <= len(w) <= 4 and abs(sum(w.values())-1) < 1e-5 and 'Root' not in w for w in current['skin'])
    images = [i for i in bpy.data.images if i.packed_file]
    assert len(images) == 1 and hashlib.sha256(images[0].packed_file.data).hexdigest() == expected_texture
    bm = bmesh.new(); bm.from_mesh(m.data)
    eye_vertices = {v.index for e in bm.edges if e.is_boundary for v in e.verts}
    assert sum(e.is_boundary for e in bm.edges) == 35
    assert all(current['skin'][v] == {'Head': 1.0} for v in eye_vertices)
    bm.free()
    action = r.animation_data.action
    assert len(bpy.data.actions) == 1
    assert action.name == 'GreenSlimeRig|'+name
    first, last = action.frame_range
    fps = bpy.context.scene.render.fps
    assert abs((last-first)/fps-duration) < 1e-6
    edges = [(e.vertices[0], e.vertices[1], (m.data.vertices[e.vertices[0]].co-m.data.vertices[e.vertices[1]].co).length) for e in m.data.edges]
    samples = []
    min_ground, strain = 1e6, 0
    for i in range(round(duration*fps*2)+1):
        frame = first+i/2
        bpy.context.scene.frame_set(int(frame), subframe=frame % 1)
        bpy.context.view_layer.update()
        for bone in r.pose.bones:
            assert max(abs(v-1) for v in bone.scale) < 1e-6
        for bone in ['Root', 'Contact']:
            assert r.pose.bones[bone].location.length < 1e-6
            assert max(abs(v) for v in r.pose.bones[bone].rotation_euler) < 1e-6
        ev = m.evaluated_get(bpy.context.evaluated_depsgraph_get()); data = ev.to_mesh()
        points = [ev.matrix_world@v.co for v in data.vertices]; ev.to_mesh_clear()
        samples.append(points)
        min_ground = min(min_ground, min(p.z for p in points))
        strain = max(strain, max(abs((points[a]-points[b]).length/d-1) for a, b, d in edges if d > 1e-7))
    seam = max((a-b).length for a, b in zip(samples[0], samples[-1]))
    max_step = max((b-a).length for before, after in zip(samples, samples[1:]) for a, b in zip(before, after))
    assert seam < 1e-5 and min_ground >= -1e-5 and strain < .35
    rows.append({'clip': name, 'track': action.name, 'durationSeconds': duration,
                 'sameRestUvSkinAsV1': True, 'textureByteIdentical': True,
                 'eyesRigidHead': True, 'rootContactStationary': True, 'noAnimatedScale': True,
                 'loopMaxVertexDelta': seam, 'minimumGroundClearance': min_ground,
                 'maximumEdgeStrain': strain, 'maximumHalfFrameStep': max_step})
(OUT/'fbx-roundtrip.json').write_text(json.dumps({'blender': bpy.app.version_string, 'results': rows}, indent=2)+'\n', encoding='utf-8', newline='\n')
print('AG73 V2 FRESH IMPORT PASS', json.dumps(rows))
