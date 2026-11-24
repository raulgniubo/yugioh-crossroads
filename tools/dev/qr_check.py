# Compares tests/qr_check.tscn's QR codes with Nayuki's reference encoder (pip install qrcodegen).
# (segno makes other, also valid, codes for some texts: it is not the reference here.)
import base64, sys
from qrcodegen import QrCode as Q, QrSegment
ok = n = 0
for line in open(sys.argv[1] if len(sys.argv) > 1 else '/tmp/qr_out.txt'):
    _, mk, t, rows = line.strip().split('|')
    t = base64.b64decode(t).decode()
    rows = rows.split(',')
    mk = int(mk)
    q = Q.encode_segments([QrSegment.make_bytes(t.encode())], Q.Ecc.MEDIUM, 1, 40, mk, False)
    ref = [''.join('1' if q.get_module(x, y) else '0' for x in range(q.get_size())) for y in range(q.get_size())]
    same = ref == rows
    print('version', q.get_version(), 'mask', mk, '->', q.get_mask(), 'bytes', len(t.encode()), 'SAME' if same else 'DIFF')
    ok += same; n += 1
print(ok, 'of', n, 'the same')
