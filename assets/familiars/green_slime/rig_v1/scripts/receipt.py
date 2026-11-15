"""Explicitly fingerprint a reviewed AG73 delivery; CI never rewrites receipts."""
import hashlib
import json
from pathlib import Path

PACKAGE = Path(__file__).resolve().parents[2]
ROOT = PACKAGE.parents[2]
files = []
for folder in [PACKAGE, ROOT / 'docs/evidence/ag73']:
    for path in sorted(folder.rglob('*')):
        if not path.is_file() or path.name == 'manifest.json' or path.suffix == '.blend1':
            continue
        if any(p == '__pycache__' or p.endswith('.fbm') for p in path.parts):
            continue
        data = path.read_bytes()
        files.append({'path': path.relative_to(ROOT).as_posix(), 'bytes': len(data),
                      'sha256': hashlib.sha256(data).hexdigest()})
receipt = {
    'version': 1,
    'task': 'AG-73 / Issue #48',
    'status': 'PHASE_A_CANDIDATE_STUDIO_PLAY_BLOCKED',
    'baseSha': '8dc804ab33e3f9d052dc4d15a97d90b3cd46a02b',
    'source': {
        'provider': 'Meshy',
        'ownerAttestation': {'date': '2026-11-15', 'plan': 'paid', 'ownAccount': True},
        'taskId': None,
        'fbxSha256': 'f3457fb1081549c6634e844350eb7e6fb24aaed39dc1a8814e28a730b18c9c7f',
        'issuePngSha256': '0af4adc1a06403bb316b2273217c06e145951eb51c909c32d5259da158148254',
        'actualPngSha256': '631f17ac3724ab7b689c11c5f038242ca68bb38198058c59ab84cf47337b5805',
        'pngMatchesEmbeddedFbx': True,
        'licenseReceipt': 'source/PROVENANCE.md',
    },
    'recipe': {'blender': '4.5.9 LTS', 'buildHash': '8bf95cbd38d1',
               'entrypoint': 'rig_v1/scripts/build_rig.py',
               'byteIdenticalRebuildPromised': False},
    'roblox': {'assetIds': [], 'uploadPerformed': False, 'importerPreview': 'PASS',
               'ordinaryPlay': 'BLOCKED_PENDING_OWNER_ART_AND_UPLOAD_APPROVAL'},
    'ownerArtAcceptance': 'PENDING',
    'files': files,
}
(PACKAGE / 'manifest.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
print(f'AG73 receipt: {len(files)} files')
