"""07A: correct Roblox face adjacency; retain the original CC0 procedural art.

The installed Roblox sky512 DDS faces were inspected read-only. Their edge
correspondences differ from task06's assumed cube. No Roblox imagery is copied.
"""
import hashlib, json, math, runpy
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'scripts/create-fantasy-sky.py'
source=runpy.run_path(str(BASE))
receipt=json.loads((ROOT/'assets/environment/fantasy/receipt.json').read_text())
assert hashlib.sha256(BASE.read_bytes().replace(b'\r\n',b'\n')).hexdigest()==receipt['generator_sha256']
OUT=ROOT/'assets/environment/stability-sky'
N=256
def direction(face,u,v):
    # ft(-Z) is our arbitrary world bearing. Native neighbor orientation is the
    # contract: ft.R=lf.L, lf.R=bk.L, bk.R=rt.L, rt.R=ft.L.
    p={'ft':(u,-v,-1),'bk':(-u,-v,1),'lf':(1,-v,u),'rt':(-1,-v,-u),
       'up':(-v,1,-u),'dn':(v,-1,-u)}[face]
    m=math.sqrt(sum(x*x for x in p)); return tuple(x/m for x in p)
def main():
    OUT.mkdir(parents=True,exist_ok=True)
    for face in ('ft','bk','lf','rt','up','dn'):
        source['png'](OUT/(face+'.png'),lambda x,y:source['sky'](direction(face,2*x/(N-1)-1,2*y/(N-1)-1)))
    (OUT/'LICENSE.txt').write_text('Original project procedural sky — CC0-1.0.\n'
        'Generated from the original CC0 task06 mathematical art with corrected face orientation.\n'
        'No Roblox/Zelda/third-party image pixels are included.\n'
        'https://creativecommons.org/publicdomain/zero/1.0/\n',encoding='utf-8',newline='\n')
    files={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(OUT.iterdir()) if p.name!='receipt.json'}
    result={'name':'07a-native-adjacency-sky','version':1,'license':'CC0-1.0',
        'generator':'scripts/create-stability-sky.py','generator_sha256':hashlib.sha256(Path(__file__).read_bytes().replace(b'\r\n',b'\n')).hexdigest(),
        'art_generator':'scripts/create-fantasy-sky.py','art_generator_sha256':receipt['generator_sha256'],
        'files':files,'cube_size':N,'rgba8_mips_bytes':6*N*N*4*4//3,
        'local_prefix':'rbxasset://m7task07a-v1/','roblox_asset_ids':None,
        'permissions':'LOCAL_STUDIO_ONLY; experience permissions BLOCKED',
        'diagnosis':'docs/evidence/m7-07a-batch/sky-diagnosis.json',
        'runtime_render_status':'NOT_VERIFIED; final ordinary Play required'}
    (OUT/'receipt.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('07A sky generated: six 256x256 original CC0 faces; corrected native edge adjacency')
if __name__=='__main__': main()
