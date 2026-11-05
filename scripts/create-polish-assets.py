"""Original A.2c material/sprite functions, CC0. No source imagery is edited.
128px low-frequency periodic albedo avoids the native Grass micro-normal noise.
Matte native shading needs no PBR texture pack or runtime texture swapping.
"""
import hashlib, json, math, struct, zlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/environment/polish'
OUT.mkdir(parents=True,exist_ok=True)
def png(name,n,fn):
    def chunk(t,d): return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d))
    raw=b''.join(b'\0'+bytes(c for x in range(n) for c in fn(x,y)) for y in range(n))
    (OUT/name).write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',n,n,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b''))
def ground(x,y):
    u,v=x/127*math.tau,y/127*math.tau
    value=round(216+8*math.sin(u+math.sin(v))+5*math.cos(2*v-u)+3*math.sin(3*u+2*v))
    return value,value,value,255
png('meadow.png',128,ground)
def star(x,y):
    u,v=(x-31.5)/31.5,(y-31.5)/31.5
    r=math.sqrt(u*u+v*v)
    a=max(0,1-r/.6)**2
    a=max(a,max(0,1-abs(u)*15-abs(v)*1.5)*.45,max(0,1-abs(v)*15-abs(u)*1.5)*.45)
    return 223,236,255,round(255*a)
png('star.png',64,star)
(OUT/'LICENSE.txt').write_text('Original A.2c mathematical material and star art. CC0-1.0 dedication.\nNo downloaded, Nintendo/Zelda, marketplace or provider imagery.\nGenerator: scripts/create-polish-assets.py\nhttps://creativecommons.org/publicdomain/zero/1.0/\n',encoding='utf-8')
files={name:hashlib.sha256((OUT/name).read_bytes()).hexdigest() for name in ['meadow.png','star.png','LICENSE.txt']}
receipt={'license':'CC0-1.0','local_prefix':'rbxasset://m7a2c-v2/','generator':'scripts/create-polish-assets.py',
 'generator_sha256':hashlib.sha256(Path(__file__).read_bytes().replace(b'\r\n',b'\n')).hexdigest(),
 'files':files,'rgba8_mips_bytes':math.ceil((128*128+64*64)*4*4/3),
 'permissions':'LOCAL_STUDIO_ONLY; experience asset permissions BLOCKED','roblox_asset_ids':None}
(OUT/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print('Original A.2c assets with closed SHA-256 roster; bytes with mips:',receipt['rgba8_mips_bytes'])
