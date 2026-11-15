"""Blender 4.5.9: derive two clips from immutable V1 rig, without editing skin."""
import bpy
import hashlib
import json
import sys
from pathlib import Path

OUT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(OUT/'scripts'))
from motion import FPS, CLIPS, BONES, pose, sequence

V1 = OUT.parent/'rig_v1'
source = V1/'GreenSlime_Idle.blend'
assert hashlib.sha256(source.read_bytes()).hexdigest() == 'b3eb5f083e0a3ed67513326e2a042cc56954127b7313067330682885b97f324d'
bpy.ops.wm.open_mainfile(filepath=str(source))
rig = bpy.data.objects['GreenSlimeRig']
mesh = bpy.data.objects['GreenSlime']
scene = bpy.context.scene
rig.animation_data_clear()
for a in list(bpy.data.actions):
    bpy.data.actions.remove(a)
scene.render.fps = FPS
scene.frame_start = 0
rest = [v.co.copy() for v in mesh.data.vertices]
edges = [(e.vertices[0], e.vertices[1], (rest[e.vertices[0]]-rest[e.vertices[1]]).length) for e in mesh.data.edges]


def signature():
    data = {'vertices': [list(v.co) for v in mesh.data.vertices],
            'polygons': [list(p.vertices) for p in mesh.data.polygons],
            'uv': [list(v.uv) for v in mesh.data.uv_layers.active.data],
            'weights': [[(mesh.vertex_groups[w.group].name, w.weight) for w in v.groups] for v in mesh.data.vertices],
            'bones': [(b.name, b.parent.name if b.parent else None, [list(r) for r in b.matrix_local]) for b in rig.data.bones]}
    return hashlib.sha256(json.dumps(data, sort_keys=True).encode()).hexdigest()


baseline = signature()


def set_pose(value):
    for name in BONES:
        b = rig.pose.bones[name]
        b.rotation_mode = 'XYZ'
        b.location, b.rotation_euler = value[name]
        b.scale = (1, 1, 1)


def points():
    bpy.context.view_layer.update()
    obj = mesh.evaluated_get(bpy.context.evaluated_depsgraph_get())
    data = obj.to_mesh()
    result = [obj.matrix_world@v.co for v in data.vertices]
    obj.to_mesh_clear()
    return result


def measure(name, end, sample):
    frames = []
    ground, strain, travel = 1e6, 0, 0
    worst = None
    # 60 Hz evaluation covers halfway poses between the 30 FPS baked keys.
    for i in range(end*2+1):
        t = i/(FPS*2)
        set_pose(sample(t)); p = points(); frames.append(p)
        ground = min(ground, min(v.z for v in p))
        travel = max(travel, max((v-rest[k]).length for k, v in enumerate(p)))
        for a, b, d in edges:
            if d < 1e-7:
                continue
            s = abs((p[a]-p[b]).length/d-1)
            if s > strain:
                strain, worst = s, (i/2, a, b)
    seam = max((a-b).length for a, b in zip(frames[0], frames[-1]))
    span = max((a-b).length for a, b in zip(frames[0], frames[end]))
    step = max((b-a).length for before, after in zip(frames, frames[1:]) for a, b in zip(before, after))
    row = {'name': name, 'durationSeconds': end/FPS, 'frames': end+1,
           'loopMaxVertexDelta': seam, 'minimumGroundClearance': ground,
           'maximumEdgeStrain': strain, 'maximumVertexTravelFromRest': travel,
           'halfCycleDisplacement': span, 'maximumHalfFrameStep': step, 'worstEdge': worst}
    print('AG73 V2 METRICS', json.dumps(row), flush=True)
    return row


reports = [measure(n, end, lambda t, n=n: pose(n, t)) for n, end in CLIPS.items()]
sequence_end = 2*CLIPS['Idle_Calm']+CLIPS['Idle_Active']
reports.append(measure('Calm_Active_Calm_QA', sequence_end, lambda t: sequence(t)[0]))
if '--probe' in sys.argv:
    print('PROBE ONLY; no exported files changed')
    sys.exit(0)
for r in reports:
    assert r['loopMaxVertexDelta'] < 1e-6
    assert r['minimumGroundClearance'] >= -1e-6
    # Preserve the V1 diagnostic cap; do not raise it to accommodate motion.
    assert r['maximumEdgeStrain'] < .35, r
assert signature() == baseline, 'rig, rest geometry, UV and weights must remain identical'

actions = {}
for name, end in [*CLIPS.items(), ('Calm_Active_Calm_QA', sequence_end)]:
    rig.animation_data_clear()
    for frame in range(end+1):
        scene.frame_set(frame)
        set_pose(sequence(frame/FPS)[0] if name.endswith('_QA') else pose(name, frame/FPS))
        for b in rig.pose.bones:
            b.keyframe_insert('location', frame=frame, group=b.name)
            b.keyframe_insert('rotation_euler', frame=frame, group=b.name)
    action = rig.animation_data.action
    action.name = name
    action.use_fake_user = True
    for fc in action.fcurves:
        for key in fc.keyframe_points:
            key.interpolation = 'LINEAR'
        if not name.endswith('_QA'):
            fc.modifiers.new('CYCLES')
    actions[name] = action

bpy.ops.object.select_all(action='DESELECT')
rig.select_set(True); mesh.select_set(True)
bpy.context.view_layer.objects.active = rig
for name, end in CLIPS.items():
    rig.animation_data.action = actions[name]
    scene.name = name
    scene.frame_end = end; scene.frame_set(0)
    bpy.ops.export_scene.fbx(filepath=str(OUT/(name+'.fbx')), use_selection=True,
        object_types={'ARMATURE', 'MESH'}, apply_scale_options='FBX_SCALE_UNITS',
        add_leaf_bones=False, use_armature_deform_only=False, armature_nodetype='NULL',
        axis_forward='-Z', axis_up='Y', path_mode='COPY', embed_textures=True,
        bake_anim=True, bake_anim_use_all_bones=True, bake_anim_use_nla_strips=False,
        bake_anim_use_all_actions=False, bake_anim_step=1, bake_anim_simplify_factor=0)
for image in bpy.data.images:
    if image.name == 'GreenSlime_Diffuse':
        image.filepath = '//../rig_v1/GreenSlime.png'
rig.animation_data.action = actions['Calm_Active_Calm_QA']
scene.name = 'GreenSlime_IdlePair'
scene.frame_end = sequence_end; scene.frame_set(0)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'GreenSlime_TwoIdles.blend'))
report = {'blender': bpy.app.version_string, 'sourceBlendSha256': hashlib.sha256(source.read_bytes()).hexdigest(),
          'restRigUvWeightsSignature': baseline, 'unchangedFromV1': True,
          'fps': FPS, 'crossfadeSeconds': .3, 'samplesPerSecond': 60,
          'clips': reports, 'ownerArtAcceptance': 'PENDING', 'studioPlay': 'BLOCKED_NO_UPLOAD_APPROVAL'}
(OUT/'validation.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8', newline='\n')
print('AG73 TWO IDLES BUILD PASS')
