#!/usr/bin/env python3
"""Packs the engine's card table and card scripts for the game.

  python3 tools/make_ocg_data.py <BabelCDB folder> <CardScripts folder> [<Distribution folder>]

Writes data/ocg/cards.bin (every card in cards.cdb) and data/ocg/scripts.bin (gzip: the
library scripts plus every official card script). With the
Distribution folder it also writes data/ocg/strings.json (the words of the engine's questions).
Run it again to pick up new cards.
"""
import sqlite3, struct, sys, os, gzip, glob
cdb, scr = sys.argv[1], sys.argv[2]
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data', 'ocg')
os.makedirs(out, exist_ok=True)
db = sqlite3.connect(os.path.join(cdb, 'cards.cdb'))
rows = db.execute('select id,alias,setcode,type,atk,def,level,race,attribute from datas').fetchall()
buf = [struct.pack('<I', len(rows))]
for cid, alias, setc, typ, atk, de, lvl, race, attr in rows:
    sets = [(setc >> (16 * i)) & 0xffff for i in range(4)]
    sets = [x for x in sets if x]
    link = de if typ & 0x4000000 else 0
    buf.append(struct.pack('<IIIIIQiiIIIB', cid, alias, typ, lvl & 0xff, attr, race & 0xffffffffffffffff, atk, 0 if link else de,
                           (lvl >> 24) & 0xff, (lvl >> 16) & 0xff, link, len(sets)))
    buf.append(struct.pack('<%dH' % len(sets), *sets))
open(os.path.join(out, 'cards.bin'), 'wb').write(b''.join(buf))
files = sorted(glob.glob(os.path.join(scr, '*.lua'))) + sorted(glob.glob(os.path.join(scr, 'official', '*.lua')))
# The cards of this game (Lumen and hers) have their scripts in native/custom.
files += sorted(glob.glob(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'native', 'custom', '*.lua')))
parts = [struct.pack('<I', len(files))]
for f in files:
    name = os.path.basename(f).encode()
    data = open(f, 'rb').read()
    parts.append(struct.pack('<H', len(name)) + name + struct.pack('<I', len(data)) + data)
raw = b''.join(parts)
with gzip.GzipFile(os.path.join(out, 'scripts.bin'), 'wb', compresslevel=9, mtime=0) as g:
    g.write(raw)
# The words the engine uses in its questions: system lines (English and Spanish) and each card's own lines.
import json
def conf(path):
    d = {'system': {}, 'victory': {}, 'counter': {}}
    for line in open(path, encoding='utf-8', errors='ignore'):
        if not line.startswith('!'):
            continue
        parts = line.rstrip('\n').split(' ', 2)
        kind = parts[0][1:]
        if kind in d and len(parts) == 3:
            try:
                d[kind][str(int(parts[1], 0))] = parts[2]
            except ValueError:
                pass
    return d
strings = {}
if len(sys.argv) > 3:
    strings['en'] = conf(os.path.join(sys.argv[3], 'config', 'strings.conf'))
    es = os.path.join(sys.argv[3], 'config', 'languages', 'Español', 'strings.conf')
    if os.path.exists(es):
        strings['es'] = conf(es)
    card = {}
    for r in db.execute('select * from texts'):
        strs = [x or '' for x in r[3:19]]
        while strs and strs[-1] == '':
            strs.pop()
        if strs:
            card[str(r[0])] = strs
    strings['card'] = card
    json.dump(strings, open(os.path.join(out, 'strings.json'), 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
print('cards', len(rows), 'scripts', len(files), 'raw MB', round(len(raw) / 1e6, 1),
      'packed MB', round(os.path.getsize(os.path.join(out, 'scripts.bin')) / 1e6, 1))
