"""Evaluate the saved/baked preview action, including both fade boundaries."""
import bpy
import json
from pathlib import Path

OUT = Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(OUT/'GreenSlime_TwoIdles.blend'))
s = bpy.context.scene
r = bpy.data.objects['GreenSlimeRig']; m = bpy.data.objects['GreenSlime']
r.animation_data.action = bpy.data.actions['Calm_Active_Calm_QA']
end = round(r.animation_data.action.frame_range[1])
rest = [v.co.copy() for v in m.data.vertices]
edges = [(e.vertices[0], e.vertices[1], (rest[e.vertices[0]]-rest[e.vertices[1]]).length) for e in m.data.edges]


def points(frame):
    s.frame_set(int(frame), subframe=frame % 1)
    bpy.context.view_layer.update()
    ev = m.evaluated_get(bpy.context.evaluated_depsgraph_get()); data = ev.to_mesh()
    result = [ev.matrix_world@v.co for v in data.vertices]; ev.to_mesh_clear()
    return result


samples = [points(i/2) for i in range(end*2+1)]
ground = min(p.z for frame in samples for p in frame)
strain = max(abs((p[a]-p[b]).length/d-1) for p in samples for a, b, d in edges if d > 1e-7)
max_step = max((a-b).length for before, after in zip(samples, samples[1:]) for a, b in zip(before, after))
seam = max((a-b).length for a, b in zip(samples[0], samples[-1]))
boundaries = []
for time in [3.6, 3.9, 6.6, 6.9]:
    left, right = points(time*30-1e-5), points(time*30+1e-5)
    delta = max((a-b).length for a, b in zip(left, right))
    assert delta < 1e-6
    boundaries.append({'seconds': time, 'limitVertexDelta': delta})
assert ground >= 0 and strain < .35 and max_step < .005 and seam < 1e-6
report = {'action': 'Calm_Active_Calm_QA', 'durationSeconds': end/30, 'fadeSeconds': .3,
          'evaluatedBakedAction': True, 'samplesPerSecond': 60, 'minimumGroundClearance': ground,
          'maximumEdgeStrain': strain, 'maximumHalfFrameStep': max_step,
          'loopMaxVertexDelta': seam, 'boundaries': boundaries,
          'scope': 'Blender Euler-channel blend approximation; native AnimationTrack remains unverified'}
(OUT/'continuity.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8', newline='\n')
print('AG73 BAKED TRANSITION PASS', json.dumps(report))
