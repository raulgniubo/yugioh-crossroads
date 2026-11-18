#!/usr/bin/env python3
"""Which cards each card's script names, and which scripts name it (for tests/ocg_sweep.gd, which
puts a card's friends on the table with it).   script_refs.py <CardScripts folder> <ids file> <out>"""
import json, os, re, sys
sc, ids_file, out = sys.argv[1:4]
ROOT = __file__.rsplit('/tools/', 1)[0]
ids = [int(l) for l in open(ids_file).read().split() if l.strip().isdigit()]
pool = set(ids)
refs, back = {}, {}
for i in ids:
    p = next((q for q in ('%s/native/custom/c%d.lua' % (ROOT, i), '%s/official/c%d.lua' % (sc, i), '%s/unofficial/c%d.lua' % (sc, i)) if os.path.exists(q)), '')
    if not p: continue
    s = open(p, encoding='utf-8', errors='ignore').read()
    for m in sorted(set(int(x) for x in re.findall(r'(?<![\w.])(\d{5,9})(?![\w.])', s))):
        if m != i and m in pool:
            refs.setdefault(str(i), []).append(m)
            back.setdefault(str(m), []).append(i)
back = {k: v[:6] for k, v in back.items()}
json.dump({'refs': refs, 'back': back}, open(out, 'w'))
print('script refs: %d cards name another, %d are named' % (len(refs), len(back)))
