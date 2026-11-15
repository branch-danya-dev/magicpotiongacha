"""Two cosmetic Idle poses on the unchanged V1 rig. No mesh/weight edits."""
import math
from mathutils import Euler, Vector

FPS = 30
SCALE = 3.2
CLIPS = {'Idle_Calm': 108, 'Idle_Active': 90}
FADE = .3
BONES = ['Root', 'Contact', 'Body', 'Head', 'EdgeFL', 'EdgeFR', 'EdgeBL', 'EdgeBR']


def smooth(x):
    x = min(1, max(0, x))
    return x*x*x*(10+x*(-15+6*x))


def swell(t):
    """Slow gathering, quicker release, then a short settled pause; C2 loop."""
    t %= 1
    if t < .48:
        return smooth(t/.48)
    if t < .86:
        return 1-smooth((t-.48)/.38)
    return 0


def pose(clip, seconds):
    t = (seconds/(CLIPS[clip]/FPS)) % 1
    active = clip == 'Idle_Active'
    a = math.tau*t
    pulse = swell(t)
    poses = {name: ([0., 0., 0.], [0., 0., 0.]) for name in BONES}
    # Translation axes here are bone local: Y is world up, -Z is world +Y.
    body, head = poses['Body'], poses['Head']
    body[0][0] = SCALE*(.008 if active else .004)*math.sin(a)*pulse
    body[0][1] = SCALE*(.011 if active else .007)*pulse
    body[0][2] = -SCALE*.004*math.sin(a)*pulse
    head[1][0] = math.radians(10 if active else 7)*pulse
    head[1][1] = math.radians(2 if active else 2.5)*math.sin(a)*pulse
    head[1][2] = math.radians(2 if active else 2.5)*math.sin(a)
    # Rotate the raised head around the low front contact, not through the floor.
    # This is a compensating bone translation, not a changed bind/rest pose.
    pivot = Vector((.12, -.09, .48))
    offset = pivot-Euler(head[1], 'XYZ').to_matrix()@pivot-Vector(body[0])
    head[0][:] = offset
    for i, name in enumerate(['EdgeFL', 'EdgeFR', 'EdgeBR', 'EdgeBL']):
        p = (t-i*.25) % 1
        wave = swell(p)
        gather = math.sin(math.tau*p)
        side = -1 if name.endswith('L') else 1
        back = 1 if name in ('EdgeBL', 'EdgeBR') else -1
        loc, rot = poses[name]
        loc[0] = SCALE*side*(.016 if active else .013)*gather
        loc[1] = SCALE*(.008 if active else .006)*wave
        loc[2] = -SCALE*back*(.012 if active else .009)*gather
        rot[0] = math.radians(2 if active else 1.5)*math.sin(math.tau*p)
    return poses


def blend(a, b, weight):
    # Small-angle rotations; native AnimationTrack blending remains a QA gate.
    return {name: tuple([x+(y-x)*weight for x, y in zip(va, vb)]
                        for va, vb in zip(a[name], b[name])) for name in BONES}


def sequence(seconds):
    # The outgoing loop continues through its first .3 s; the incoming clip
    # starts at 0 on the whole-cycle boundary. No early restart mid-cycle.
    calm = CLIPS['Idle_Calm']/FPS
    active = CLIPS['Idle_Active']/FPS
    if seconds < calm:
        return pose('Idle_Calm', seconds), 'Idle Calm'
    if seconds < calm+active:
        t = seconds-calm
        if t < FADE:
            return blend(pose('Idle_Calm', t), pose('Idle_Active', t), t/FADE), 'Calm > Active | 0.30 s'
        return pose('Idle_Active', t), 'Idle Active'
    t = seconds-calm-active
    if t < FADE:
        return blend(pose('Idle_Active', t), pose('Idle_Calm', t), t/FADE), 'Active > Calm | 0.30 s'
    return pose('Idle_Calm', t), 'Idle Calm'
