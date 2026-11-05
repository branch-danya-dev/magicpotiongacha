"""Original mathematical art, no downloaded imagery or provider dependencies.

Reproducible source for the A.2b CC0 cubemap and local effect sprites. One smooth
direction function is sampled by every face, including identical edge texels.
This is a direct project authoring receipt, NOT a game-dev canonical receipt.
"""
import hashlib, json, math, struct, zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/environment/atmosphere'
OUT.mkdir(parents=True, exist_ok=True)

def png(path, width, height, pixel):
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    raw = b''.join(b'\0' + bytes(c for x in range(width) for c in pixel(x, y)) for y in range(height))
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))

def clamp(x): return max(0, min(1, x))
def smooth(x): x=clamp(x); return x*x*(3-2*x)
def blend(a,b,t): return tuple(round(x+(y-x)*t) for x,y in zip(a,b))
def direction(face,u,v):
    # Right-handed Roblox cube, top-left image origin; opposite edges share rays.
    xyz={'ft':(u,-v,-1),'bk':(-u,-v,1),'lf':(-1,-v,-u),'rt':(1,-v,u),'up':(u,1,v),'dn':(u,-1,-v)}[face]
    norm=math.sqrt(sum(x*x for x in xyz)); return tuple(x/norm for x in xyz)

def sky(d):
    x,y,z=d
    # A quiet neutral-blue foundation accepts rose/amber scattering without
    # multiplying a saturated cyan into muddy brown at low solar elevations.
    base=blend((232,235,241),(137,161,187),smooth(max(0,y)**.65))
    # Quiet brush-like high wisps, continuous over all six faces. Weather clouds
    # are authored by the engine Clouds layer, never baked storm silhouettes.
    ribbon=math.sin(13*y+1.2*math.sin(3*x)+.6*math.cos(4*z))
    wisps=smooth((ribbon-.78)/.22)*smooth((y-.12)/.18)*(1-smooth((y-.7)/.25))*.2
    return (*blend(base,(227,241,235),wisps),255)

N=256
edges={}
for face in ('ft','bk','lf','rt','up','dn'):
    png(OUT/(face+'.png'),N,N,lambda x,y:sky(direction(face,2*x/(N-1)-1,2*y/(N-1)-1)))
    for j in range(N):
        for u,v in ((-1,2*j/(N-1)-1),(1,2*j/(N-1)-1),(2*j/(N-1)-1,-1),(2*j/(N-1)-1,1)):
            d=direction(face,u,v); key=tuple(round(a,9) for a in d)
            edges.setdefault(key,[]).append(sky(d))
assert all(len(v)>=2 and len(set(v))==1 for v in edges.values())

def radial(x,y,kind):
    u,v=(x-63.5)/63.5,(y-63.5)/63.5; r=math.sqrt(u*u+v*v)
    if kind=='mist': return (230,247,241,round(110*max(0,1-r*r)**3))
    if kind=='sun': return (255,239,196,round(255*(1-smooth((r-.42)/.32))))
    outer=1-smooth((r-.73)/.035); cut=smooth((math.sqrt((u-.32)**2+(v+.17)**2)-.66)/.035)
    return (216,238,250,round(255*outer*cut))

for kind in ('mist','sun','moon'): png(OUT/(kind+'.png'),128,128,lambda x,y:radial(x,y,kind))

def rainbow(x,y):
    u,v=(x-127.5)/120,(127.5-y)/120; radius=math.sqrt(u*u+v*v)
    colors=((199,150,216),(153,185,235),(137,218,201),(229,226,160),(239,188,151),(235,158,163))
    t=clamp((radius-.76)/.14); f=t*(len(colors)-1); i=min(len(colors)-2,int(f))
    alpha=smooth((radius-.75)/.025)*(1-smooth((radius-.89)/.025))*smooth(v/.2)
    return (*blend(colors[i],colors[i+1],f-i),round(alpha*150))
png(OUT/'rainbow.png',256,128,rainbow)

license_text='''Original A.2b atmosphere textures — CC0-1.0

These textures are authored entirely by the mathematical functions in
scripts/create-atmosphere-assets.py for this project. No Zelda, Nintendo,
marketplace, photographic, downloaded or generated-provider source is used.
To the extent copyright applies, the project contribution is dedicated to the
public domain under CC0 1.0: https://creativecommons.org/publicdomain/zero/1.0/
No warranties. This dedication covers these PNGs and their generator only,
not Quaternius assets, Roblox code or the rest of the game.
'''
(OUT/'LICENSE.txt').write_text(license_text,encoding='utf-8')
roster={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(OUT.iterdir()) if p.suffix=='.png' or p.name=='LICENSE.txt'}
receipt={'name':'original-cozy-atmosphere','version':2,'license':'CC0-1.0','authoring':'deterministic project-native mathematical art; no external sources',
    'generator':'scripts/create-atmosphere-assets.py','generator_sha256':hashlib.sha256(Path(__file__).read_bytes().replace(b'\r\n',b'\n')).hexdigest(),
    'files':roster,'cube_size':N,'matched_edge_rays':len(edges),'max_edge_rgba_error':0,
    'rgba8_mips_bytes':math.ceil((6*N*N+3*128*128+256*128)*4*4/3),
    'roblox_asset_ids':None,'permissions':'LOCAL_STUDIO_ONLY; no upload/publication performed; experience access remains BLOCKED',
    'local_prefix':'rbxasset://m7a2b-v2/'}
(OUT/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print(f'Original cubemap: {len(edges)} identical edge rays; {receipt["rgba8_mips_bytes"]/1024**2:.3f} MiB RGBA8+mips; closed SHA-256 roster')
