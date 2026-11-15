"""Read completed video streams using Blender's movie decoder."""
import bpy
import json
from pathlib import Path

OUT = Path(__file__).resolve().parents[1]
rows = []
for name, frames in [('sequence-game', 306), ('sequence-detail', 306),
                     ('calm-game', 108), ('active-game', 90), ('v1-game', 96)]:
    path = OUT/'previews'/(name+'.mp4')
    assert path.stat().st_size > 1000
    clip = bpy.data.movieclips.load(str(path), check_existing=False)
    assert tuple(clip.size) == (960, 540)
    assert clip.frame_duration == frames
    assert abs(clip.fps-30) < 1e-5
    rows.append({'file': path.name, 'frames': clip.frame_duration, 'fps': clip.fps,
                 'size': list(clip.size), 'durationSeconds': clip.frame_duration/clip.fps})
    bpy.data.movieclips.remove(clip)
(OUT/'video-validation.json').write_text(json.dumps(rows, indent=2)+'\n', encoding='utf-8', newline='\n')
print('AG73 VIDEO DECODE/METADATA PASS', json.dumps(rows))
