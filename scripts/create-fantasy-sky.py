"""Task 06: original seamless painted-cloud sky; project-native mathematical art.

No external imagery, provider, screenshot or renderer is used. Historical sky
bytes stay immutable. Run with Python 3; output is six runtime texture assets.
"""
import hashlib, json, math, struct, zlib
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/environment/fantasy'
N=256
FACES=('ft','bk','lf','rt','up','dn')

def smooth(v):
    v=max(0,min(1,v)); return v*v*(3-2*v)

def mix(a,b,t): return tuple(x+(y-x)*t for x,y in zip(a,b))

def direction(face,u,v):
    p={'ft':(u,-v,-1),'bk':(-u,-v,1),'lf':(-1,-v,-u),'rt':(1,-v,u),'up':(v,1,-u),'dn':(-v,-1,-u)}[face]
    length=math.sqrt(sum(x*x for x in p)); return tuple(x/length for x in p)

def sky(d):
    x,y,z=d; az=math.atan2(x,-z)
    # Broad chromatic bands, no speckle/noise or baked sun/moon.
    base=mix((210,227,219),(91,154,182),smooth(max(0,y)**.65))
    # Three original, periodic distant ridge silhouettes belong to the sky only.
    # They are deliberately low so they never read as nearby traversable land.
    for layer in range(3):
        ridge=.012+layer*.010+.016*math.sin(3*az+layer*.8)+.009*math.cos(7*az-layer*.6)
        amount=(1-smooth((y-ridge+.018)/.036))*.34
        base=mix(base,((151,182,182),(130,168,174),(111,155,164))[layer],amount)
    # Cloud banks composed from overlapping soft lobes. Angular distance uses
    # cosine, so banks crossing +/-pi remain seamless. Polar faces stay isotropic.
    cloud=0; shadow=0
    for index,(bearing,height,width) in enumerate(((-2.7,.19,.25),(-1.25,.31,.24),(-.1,.23,.29),(1.2,.36,.22),(2.4,.17,.27))):
        for lobe in range(5):
            center=bearing+(lobe-2)*width*.52
            top=height+(.035 if lobe in (1,2,3) else 0)+.012*math.sin(index+lobe*2)
            horizontal=2*(1-math.cos(az-center))/(width*width)
            vertical=((y-top)/(.052+.007*(lobe%3)))**2
            field=math.exp(-1.8*(horizontal+vertical))
            cloud=max(cloud,smooth((field-.12)/.50))
            shadow=max(shadow,smooth((field-.10)/.65)*smooth((top-y+.03)/.08))
    envelope=smooth((y-.065)/.035)*(1-smooth((y-.46)/.09))
    cloud*=envelope; shadow*=envelope
    cloud_color=mix((229,231,212),(157,183,189),shadow*.43)
    base=mix(base,cloud_color,cloud*.86)
    return tuple(round(max(0,min(255,v))) for v in base)+(255,)

def png(path,pixel):
    def chunk(kind,data): return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data))
    raw=b''.join(b'\0'+bytes(v for x in range(N) for v in pixel(x,y)) for y in range(N))
    path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',N,N,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b''))

def main():
    OUT.mkdir(parents=True,exist_ok=True); edges={}
    for face in FACES:
        png(OUT/(face+'.png'),lambda x,y:sky(direction(face,2*x/(N-1)-1,2*y/(N-1)-1)))
        for j in range(N):
            for u,v in ((-1,2*j/(N-1)-1),(1,2*j/(N-1)-1),(2*j/(N-1)-1,-1),(2*j/(N-1)-1,1)):
                d=direction(face,u,v); edges.setdefault(tuple(round(a,9) for a in d),[]).append(sky(d))
    assert all(len(v)>=2 and len(set(v))==1 for v in edges.values())
    (OUT/'LICENSE.txt').write_text('''Original task-06 fantasy sky textures — CC0-1.0

Original mathematical art authored in scripts/create-fantasy-sky.py for this
project. No external imagery, copyrighted game assets, provider output or
screenshots are incorporated. To the extent copyright applies, these six PNGs
and their generator are dedicated to the public domain under CC0 1.0:
https://creativecommons.org/publicdomain/zero/1.0/
This dedication does not cover Quaternius assets or the rest of the game.
''',encoding='utf-8',newline='\n')
    files={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(OUT.iterdir()) if p.suffix=='.png' or p.name=='LICENSE.txt'}
    receipt={'name':'task06-fantasy-sky','version':1,'license':'CC0-1.0','authoring':'Original project mathematical art; no external inputs',
        'generator':'scripts/create-fantasy-sky.py','generator_sha256':hashlib.sha256(Path(__file__).read_bytes().replace(b'\r\n',b'\n')).hexdigest(),
        'files':files,'cube_size':N,'matched_edge_rays':len(edges),'max_edge_rgba_error':0,'rgba8_mips_bytes':6*N*N*4*4//3,
        'replaces':'six sky faces only; sun/moon/mist/rainbow keep their historical sprite prefix',
        'roblox_asset_ids':None,'local_prefix':'rbxasset://m7task06-v1/','permissions':'LOCAL_STUDIO_ONLY; no upload/publication; experience access remains BLOCKED'}
    (OUT/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(f'Task06 sky: {len(edges)} matching rays; six {N}x{N} RGBA faces; {receipt["rgba8_mips_bytes"]} RGBA8+mip bytes')

if __name__=='__main__': main()
