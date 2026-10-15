"""Read-only package/font inspection with Python standard library only."""
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parent.parent
tracked = subprocess.check_output(
    ['git', '-C', str(ROOT / 'module'), 'ls-files', '-z']
).decode().strip('\0').split('\0')
font = (ROOT / 'module/system/fonts/NotoColorEmoji.ttf').read_bytes()
assert font[:4] == b'\x00\x01\x00\x00', 'Not a TrueType sfnt'
count = struct.unpack_from('>H', font, 4)[0]
tables = {}
for i in range(count):
    tag, checksum, offset, length = struct.unpack_from('>4sIII', font, 12 + i * 16)
    assert offset + length <= len(font), (tag, 'out of bounds')
    tables[tag.decode()] = {'offset': offset, 'length': length}
assert {'CBDT', 'CBLC', 'cmap', 'head', 'name'}.issubset(tables)
padded = font + b'\0' * (-len(font) % 4)
checksum = sum(value[0] for value in struct.iter_unpack('>I', padded)) & 0xFFFFFFFF
assert checksum == 0xB1B0AFBA, hex(checksum)
result = {
    'tracked_module_files': len(tracked),
    'font_bytes': len(font),
    'font_sha256': hashlib.sha256(font).hexdigest(),
    'sfnt_checksum_valid': True,
    'font_tables': sorted(tables),
}
asset = ROOT / 'Twemoji-Resurrection-17.0.3-ksu.zip'
if asset.exists():
    with zipfile.ZipFile(asset) as archive:
        names = archive.namelist()
        assert archive.testzip() is None
        result['local_zip'] = {
            'file': asset.name,
            'sha256': hashlib.sha256(asset.read_bytes()).hexdigest(),
            'files': len(names),
            'backslash_paths': [name for name in names if '\\' in name],
            'missing_tracked': sorted(set(tracked) - set(names)),
            'untracked_entries': sorted(set(names) - set(tracked)),
            'different_from_worktree': [
                name for name in tracked if name in names
                and archive.read(name) != (ROOT / 'module' / name).read_bytes()
            ],
            'module_prop': archive.read('module.prop').decode(),
        }
print(json.dumps(result, ensure_ascii=False, indent=2))
