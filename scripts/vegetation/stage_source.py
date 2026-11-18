"""Stage an owner-selected official download. No network, execution or uploads.

The archive is retained unchanged; extracted files are data-only and hashed.
NoAI is checked before opening any asset bytes. Blender must use disable-autoexec.
"""
import argparse
import hashlib
import json
import pathlib
import stat
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
LIBRARY = ROOT / 'assets/environment/vegetation-v2'
EXTENSIONS = {'.blend', '.fbx', '.glb', '.gltf', '.obj', '.mtl', '.bin',
              '.png', '.jpg', '.jpeg', '.tga', '.tif', '.tiff', '.exr', '.hdr',
              '.txt', '.md', '.json', '.pdf'}


def source(key):
    if key == 'oak_maple':
        raise PermissionError('BLOCKED_NOAI: metadata audit only; do not read the source asset')
    audit = json.loads((LIBRARY / 'source-audit.json').read_text(encoding='utf-8'))
    model = next(m for m in audit['models'] if m['key'] == key)
    if model['status'] != 'METADATA_READ' or not model['downloadable']:
        raise PermissionError('Unavailable source')
    if model['license']['url'].rstrip('/') not in (
        'http://creativecommons.org/licenses/by/4.0',
        'https://creativecommons.org/licenses/by/4.0'):
        raise PermissionError('Unreviewed license')
    if 'noai' in [t.lower() for t in model['tags']]:
        raise PermissionError('BLOCKED_NOAI')
    return model


def members(archive):
    files = archive.infolist()
    if len(files)>2000 or sum(f.file_size for f in files)>500_000_000:
        raise ValueError('Archive budget exceeded')
    names = set()
    for info in files:
        p = pathlib.PurePosixPath(info.filename.replace('\\', '/'))
        if p.is_absolute() or '..' in p.parts: raise ValueError('Unsafe archive path')
        if not all(':' not in s and s.rstrip(' .') == s for s in p.parts): raise ValueError('Unsafe Windows path')
        if stat.S_ISLNK(info.external_attr >> 16): raise ValueError('Archive symlink')
        name = str(p).casefold()
        if name in names: raise ValueError('Duplicate archive path')
        names.add(name)
        if not info.is_dir():
            if p.suffix.lower() not in EXTENSIONS: raise ValueError('Unreviewed archive member: '+str(p))
            if info.flag_bits & 1: raise ValueError('Encrypted archive')
            yield info, p


def stage(key, path):
    model = source(key)
    data = pathlib.Path(path).read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    target = LIBRARY / 'sources' / key
    if target.exists(): raise FileExistsError('Source already staged; never overwrite the receipt')
    with zipfile.ZipFile(path) as archive:
        checked = list(members(archive))
        if archive.testzip() is not None: raise ValueError('Archive CRC mismatch')
        target.mkdir(parents=True)
        (target / 'original.zip').write_bytes(data)
        files = []
        for info, relative in checked:
            output = target / 'unpacked' / relative
            output.parent.mkdir(parents=True, exist_ok=True)
            content = archive.read(info)
            output.write_bytes(content)
            files.append({'path': str(relative), 'bytes': len(content), 'sha256': hashlib.sha256(content).hexdigest()})
    receipt = {'key': key, 'source': model['modelURL'], 'author': model['author'],
               'authorURL': model['authorURL'], 'license': model['license']['url'],
               'archiveBytes': len(data), 'archiveSHA256': digest, 'files': files,
               'method': 'Official authenticated Sketchfab Download / Original format',
               'imported': False, 'uploaded': False}
    (target / 'receipt.json').write_text(json.dumps(receipt, indent=2, ensure_ascii=False)+'\n', encoding='utf-8')
    print(json.dumps({'key':key, 'archiveSHA256':digest, 'files':len(files)}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--key', required=True)
    parser.add_argument('--archive', required=True, type=pathlib.Path)
    args = parser.parse_args()
    stage(args.key, args.archive)
