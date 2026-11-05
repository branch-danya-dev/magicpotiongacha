"""Read-only optional diagnosis using Pillow, never a render/Play acceptance.
Usage: python scripts/diagnose-native-sky.py STUDIO_VERSION OUTPUT_JSON
Reads vendor sky DDS locally; records hashes and edge metrics, no vendor pixels.
"""
from pathlib import Path
from PIL import Image
import sys,json,hashlib
version=Path(sys.argv[1]); output=Path(sys.argv[2])
path=version/'PlatformContent/pc/textures/sky'
names=('ft','bk','lf','rt','up','dn')
faces={n:Image.open(path/f'sky512_{n}.tex').convert('RGB') for n in names}
def edge(im,s):
    n=im.width
    return [im.getpixel({'L':(0,i),'R':(n-1,i),'T':(i,0),'B':(i,n-1)}[s]) for i in range(n)]
def error(a,b): return sum(sum(abs(x-y) for x,y in zip(c,d)) for c,d in zip(a,b))/(len(a)*3)
result={}
for name,im in faces.items():
    for side in 'LRTB':
        candidates=[]; a=edge(im,side)
        for other,om in faces.items():
            if other==name: continue
            for os in 'LRTB':
                b=edge(om,os)
                for rev in (False,True): candidates.append((error(a,b[::-1] if rev else b),other,os,rev))
        best,second=sorted(candidates)[:2]
        assert best[0]<1.1 and second[0]>5, (name,side,best,second)
        result[name+side]={'neighbor':best[1]+best[2],'reverse':best[3],'meanRGBError':best[0],'nextBestError':second[0]}
report={'method':'Independent minimum absolute edge error across every face/edge/reversal in installed vendor DDS',
    'studioVersion':version.name,'vendorFilesSHA256':{n:hashlib.sha256((path/f'sky512_{n}.tex').read_bytes()).hexdigest() for n in names},
    'size':list(faces['ft'].size),'edges':result,'nativePlay':'NOT_PERFORMED',
    'vendorPixelsRedistributed':False,'conclusion':'Native lateral order ft -> lf -> bk -> rt differs from historical task06 assumptions. Regenerate project-owned CC0 faces; do not reuse vendor imagery.'}
output.parent.mkdir(parents=True,exist_ok=True)
output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Native sky diagnosis saved: '+str(output))
