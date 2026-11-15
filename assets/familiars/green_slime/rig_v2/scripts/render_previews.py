"""Render real Blender animation at calibrated proxy size; never a Studio claim."""
import bpy
import json
import math
import sys
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

OUT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(OUT/'scripts'))
from motion import sequence
PREVIEWS = OUT/'previews'
PREVIEWS.mkdir(exist_ok=True)
job = sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'stills'
v1 = job == 'v1-game'
bpy.ops.wm.open_mainfile(filepath=str(OUT.parent/'rig_v1/GreenSlime_Idle.blend' if v1 else OUT/'GreenSlime_TwoIdles.blend'))
s = bpy.context.scene
rig = bpy.data.objects['GreenSlimeRig']
mesh = bpy.data.objects['GreenSlime']
rig.scale = (2.4/(.958008*3.2),)*3
camera = s.camera
target = Vector((0, -.08, .15))
camera.location = target+Vector((0, -math.cos(math.radians(38)), math.sin(math.radians(38))))*12
camera.rotation_euler = (target-camera.location).to_track_quat('-Z', 'Y').to_euler()
camera.data.type = 'PERSP'
camera.data.sensor_fit = 'VERTICAL'
camera.data.sensor_height = 24
camera.data.lens = 12/math.tan(math.radians(70/2))
s.render.engine = 'CYCLES'
s.cycles.samples = 32
s.cycles.use_denoising = True
s.render.use_persistent_data = True
prefs = bpy.context.preferences.addons['cycles'].preferences
try:
    prefs.compute_device_type = 'OPTIX'; prefs.refresh_devices()
    devices = [d for d in prefs.devices if d.type == 'OPTIX']
    if devices:
        for d in prefs.devices:
            d.use = d in devices
        s.cycles.device = 'GPU'
        s.cycles.denoiser = 'OPTIX'
except (TypeError, RuntimeError):
    pass  # CPU fallback preserves geometry/camera/timing, not byte-identical pixels.
bpy.data.objects['QA_Ground'].scale = (5, 5, 5)
s.render.resolution_x = 960
s.render.resolution_y = 540
s.render.resolution_percentage = 100
s.render.fps = 30
s.render.film_transparent = False


def text(name, value, x, y, size):
    data = bpy.data.curves.new(name, 'FONT'); data.body = value; data.size = size
    obj = bpy.data.objects.new(name, data); s.collection.objects.link(obj)
    obj.parent = camera; obj.location = (x, y, -1)
    mat = bpy.data.materials.new(name+'_Emission'); mat.use_nodes = True
    nodes = mat.node_tree.nodes; nodes.clear()
    emission = nodes.new('ShaderNodeEmission'); emission.inputs[0].default_value = (.9, .95, 1, 1)
    output = nodes.new('ShaderNodeOutputMaterial'); mat.node_tree.links.new(emission.outputs[0], output.inputs['Surface'])
    data.materials.append(mat)
    return obj


caption = text('QA_Caption', '', -1.14, .59, .052)
text('QA_ScaleCaption', 'Blender scale preview | width 2.4 studs | camera 12 studs | vertical FOV 70', -1.14, -.58, .029)
text('QA_Disclaimer', 'Original rig and texture. Not Roblox Studio Play.', -1.14, -.64, .028)


def update_label(scene):
    if 'Calm_Active' in rig.animation_data.action.name:
        caption.data.body = 'AG73  |  '+sequence(scene.frame_current/30)[1]
    else:
        caption.data.body = 'AG73  |  '+rig.animation_data.action.name.replace('_', ' ')


bpy.app.handlers.frame_change_pre.append(update_label)


def select(name):
    rig.animation_data.action = bpy.data.actions[name]
    s.frame_start = 0
    s.frame_end = round(rig.animation_data.action.frame_range[1])-1


def still(name, frame, filename):
    select(name); s.frame_set(frame)
    s.render.image_settings.file_format = 'PNG'
    s.render.filepath = str(PREVIEWS/filename)
    bpy.ops.render.render(write_still=True)


def detail():
    camera.location = (.8, -4.4, 3.1)
    camera.rotation_euler = (Vector((0, -.1, .17))-camera.location).to_track_quat('-Z', 'Y').to_euler()
    camera.data.type = 'ORTHO'; camera.data.ortho_scale = 2.3
    # Camera-attached title locations adapt to the detail camera's frustum.
    for name in ['QA_Caption', 'QA_ScaleCaption', 'QA_Disclaimer']:
        obj = bpy.data.objects[name]; obj.location.x *= 1.45; obj.location.y *= 1.45; obj.data.size *= 1.45
    bpy.data.objects['QA_ScaleCaption'].data.body = 'Blender detail preview | same mesh, skin weights and timing'


if job == 'stills':
    for name, frame in [('Idle_Calm', 0), ('Idle_Calm', 48), ('Idle_Active', 0), ('Idle_Active', 40)]:
        still(name, frame, name+'_game_'+str(frame)+'.png')
    bpy.context.view_layer.update()
    evaluated = mesh.evaluated_get(bpy.context.evaluated_depsgraph_get()); data = evaluated.to_mesh()
    coords = [world_to_camera_view(s, camera, evaluated.matrix_world@v.co) for v in data.vertices]
    evaluated.to_mesh_clear()
    report = {'type': 'BLENDER_SCALE_PROXY_NOT_STUDIO_CAPTURE', 'sourceWidth': 'FamiliarView.client.luau WorkerProxy.Size.X=2.4',
              'widthStuds': 2.4, 'cameraDistanceStuds': 12, 'elevationDegrees': 38, 'verticalFovDegrees': 70,
              'cameraAssumption': 'Representative review framing; no exact current Studio camera was measured',
              'renderSize': [960, 540], 'visibleWidthPixels': (max(v.x for v in coords)-min(v.x for v in coords))*960,
              'renderer': 'Cycles 32 samples with denoising; OPTIX if available, CPU fallback; not device performance evidence'}
    (OUT/'preview-camera.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8', newline='\n')
    detail()
    for name, frame in [('Idle_Calm', 0), ('Idle_Calm', 48), ('Idle_Active', 0), ('Idle_Active', 40)]:
        still(name, frame, name+'_detail_'+str(frame)+'.png')
else:
    jobs = {'sequence-game': ('Calm_Active_Calm_QA', False),
            'sequence-detail': ('Calm_Active_Calm_QA', True),
            'calm-game': ('Idle_Calm', False), 'active-game': ('Idle_Active', False),
            'v1-game': ('GreenSlime_Idle_v1', False)}
    name, close = jobs[job]
    if close:
        detail()
    select(name)
    s.render.image_settings.file_format = 'FFMPEG'; s.render.ffmpeg.format = 'MPEG4'; s.render.ffmpeg.codec = 'H264'
    s.render.ffmpeg.constant_rate_factor = 'HIGH'; s.render.ffmpeg.ffmpeg_preset = 'GOOD'
    s.render.filepath = str(PREVIEWS/(job+'.mp4'))
    bpy.ops.render.render(animation=True)
print('AG73 PREVIEW PASS', job)
