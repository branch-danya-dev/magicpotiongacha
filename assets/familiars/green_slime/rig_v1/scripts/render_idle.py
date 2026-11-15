"""Render the saved Idle, excluding duplicate endpoint. No image synthesis."""
import bpy
from pathlib import Path
OUT=Path(__file__).resolve().parent.parent
bpy.ops.wm.open_mainfile(filepath=str(OUT/'GreenSlime_Idle.blend'))
s=bpy.context.scene; s.frame_start=0; s.frame_end=95
s.render.resolution_x=800; s.render.resolution_y=600; s.cycles.samples=12
s.render.image_settings.file_format='FFMPEG'; s.render.ffmpeg.format='MPEG4'; s.render.ffmpeg.codec='H264'
s.render.ffmpeg.constant_rate_factor='MEDIUM'; s.render.ffmpeg.ffmpeg_preset='GOOD'
s.render.filepath=str(OUT/'previews/GreenSlime_Idle.mp4')
bpy.ops.render.render(animation=True)
print('AG73 IDLE PREVIEW 96 frames / 30 fps / 3.2 seconds')
