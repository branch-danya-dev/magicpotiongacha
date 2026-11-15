"""Update the full package receipt after V2 review, preserving source provenance."""
import hashlib
import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parents[2]
ROOT = PACKAGE.parents[2]
receipt = json.loads((PACKAGE/'manifest.json').read_text(encoding='utf-8'))
files = []
for folder in [PACKAGE, ROOT/'docs/evidence/ag73']:
    for path in sorted(folder.rglob('*')):
        if not path.is_file() or path.name == 'manifest.json' or path.suffix == '.blend1':
            continue
        if any(p == '__pycache__' or p.endswith('.fbm') for p in path.parts):
            continue
        data = path.read_bytes()
        files.append({'path': path.relative_to(ROOT).as_posix(), 'bytes': len(data),
                      'sha256': hashlib.sha256(data).hexdigest()})
receipt.update(version=2, continuationBaseSha='59eda121a3c42cf68e820c0ac87a4a76b143161f')
receipt['recipe']['entrypoint'] = 'rig_v2/scripts/build_idles.py'
receipt['recipe']['unchangedV1Dependency'] = 'rig_v1/GreenSlime_Idle.blend'
receipt['roblox']['importerPreview'] = 'V1_ONLY_HISTORICAL_PASS_V2_NOT_RUN'
receipt['idlePair'] = {'clips': [{'name': 'Idle_Calm', 'durationSeconds': 3.6},
                                 {'name': 'Idle_Active', 'durationSeconds': 3.0}],
                      'weights': {'Idle_Calm': .5, 'Idle_Active': .5},
                      'fadeSeconds': .3, 'liveSelectorImplemented': False,
                      'commonRestRig': 'rig_v1/GreenSlime_Rig.fbx',
                      'previewSequence': 'Calm 3.6s -> Active 3.0s -> Calm 3.6s',
                      'studioQa': 'BLOCKED_PENDING_OWNER_ART_AND_UPLOAD_APPROVAL'}
receipt['files'] = files
(PACKAGE/'manifest.json').write_text(json.dumps(receipt, indent=2)+'\n', encoding='utf-8', newline='\n')
print('AG73 V2 receipt:', len(files), 'files')
