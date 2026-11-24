"""Put the current native/custom/*.lua into data/ocg/scripts.bin without a full repack.
Same-name entries are replaced, new ones appended. Usage: python3 tools/dev/patch_scripts.py"""
import gzip, struct, glob, os
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
path = os.path.join(root, 'data', 'ocg', 'scripts.bin')
raw = gzip.open(path).read()
n = struct.unpack_from('<I', raw, 0)[0]; at = 4; files = []
for _ in range(n):
    ln = struct.unpack_from('<H', raw, at)[0]; at += 2
    name = raw[at:at + ln]; at += ln
    dl = struct.unpack_from('<I', raw, at)[0]; at += 4
    files.append([name, raw[at:at + dl]]); at += dl
idx = {f[0]: i for i, f in enumerate(files)}
changed = 0
for f in sorted(glob.glob(os.path.join(root, 'native', 'custom', '*.lua'))):
    name = os.path.basename(f).encode(); data = open(f, 'rb').read()
    if name in idx:
        if files[idx[name]][1] != data:
            files[idx[name]][1] = data; changed += 1
    else:
        files.append([name, data]); changed += 1
parts = [struct.pack('<I', len(files))] + [struct.pack('<H', len(a)) + a + struct.pack('<I', len(b)) + b for a, b in files]
with gzip.GzipFile(path, 'wb', compresslevel=9, mtime=0) as g:
    g.write(b''.join(parts))
print('scripts', len(files), 'changed', changed)
