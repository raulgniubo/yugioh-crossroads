"""Joins an arm64 and an x86_64 Mach-O file into one universal file (what `lipo -create` does)."""
import struct, sys
arm, x64, out = sys.argv[1:4]
parts = []
for path, cputype, sub, align in ((x64, 0x01000007, 3, 12), (arm, 0x0100000C, 0, 14)):
    parts.append((open(path, 'rb').read(), cputype, sub, align))
header = struct.pack('>II', 0xCAFEBABE, len(parts))
offset = 8 + 20 * len(parts)
entries = b''
blobs = []
for data, cputype, sub, align in parts:
    offset = (offset + (1 << align) - 1) & ~((1 << align) - 1)
    entries += struct.pack('>IIIII', cputype, sub, offset, len(data), align)
    blobs.append((offset, data))
    offset += len(data)
with open(out, 'wb') as f:
    f.write(header + entries)
    for off, data in blobs:
        f.write(b'\0' * (off - f.tell()))
        f.write(data)
print('universal', out, [len(b[1]) for b in blobs])
