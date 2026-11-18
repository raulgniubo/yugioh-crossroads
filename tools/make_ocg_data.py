#!/usr/bin/env python3
"""Packs the engine's card table and card scripts for the game.

  python3 tools/make_ocg_data.py <BabelCDB folder> <CardScripts folder> <Distribution folder> [<card ids file>]

Writes data/ocg/cards.bin (every card in cards.cdb) and data/ocg/scripts.bin (gzip: the
library scripts plus the card scripts: every official one, or with a card ids file only the
ones the game's cards need. The ids file comes from
`godot --headless res://tests/ocg_sim.tscn -- ids <file>`). With the
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
import re
files = sorted(glob.glob(os.path.join(scr, '*.lua')))
ids_file = [a for a in sys.argv[4:] if not a.startswith('--')]
if ids_file:
    # Only the scripts the game's own cards need (and whatever those scripts load in turn).
    alias = {r[0]: r[1] for r in rows}
    want = set()
    for line in open(ids_file[0]):
        if line.strip():
            want.add(int(line))
    todo = list(want)
    seen = set()
    while todo:
        cid = todo.pop()
        if cid in seen:
            continue
        seen.add(cid)
        if alias.get(cid):
            todo.append(alias[cid])
        f = os.path.join(scr, 'official', 'c%d.lua' % cid)
        if not os.path.exists(f):
            # (a card whose text was changed keeps its number, and its current script sits in
            # "pre-errata" beside the old one: Red-Eyes Darkness Metal Dragon)
            f = os.path.join(scr, 'pre-errata', 'c%d.lua' % cid)
        if os.path.exists(f):
            files.append(f)
            for ref in re.findall(r'Load(?:Card)?Script\("c(\d+)\.lua"\)', open(f, encoding='utf-8', errors='ignore').read()):
                todo.append(int(ref))
    files = files[:25] + sorted(files[25:])
else:
    files += sorted(glob.glob(os.path.join(scr, 'official', '*.lua')))
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
    # Tokens are not cards of the game's own data: keep their names and numbers for the table.
    attrs = {1: 'EARTH', 2: 'WATER', 4: 'FIRE', 8: 'WIND', 16: 'LIGHT', 32: 'DARK', 64: 'DIVINE'}
    races = ["Warrior", "Spellcaster", "Fairy", "Fiend", "Zombie", "Machine", "Aqua", "Pyro", "Rock", "Winged Beast", "Plant", "Insect",
             "Thunder", "Dragon", "Beast", "Beast-Warrior", "Dinosaur", "Fish", "Sea Serpent", "Reptile", "Psychic", "Divine-Beast", "Creator God", "Wyrm", "Cyberse"]
    names = {r[0]: r[1] for r in db.execute('select id,name from texts')}
    tokens = {}
    for cid, alias, setc, typ, atk, de, lvl, race, attr in rows:
        if typ & 0x4000:
            rn = ''
            for i, n in enumerate(races):
                if race & (1 << i):
                    rn = n
            tokens[str(cid)] = {'name': names.get(cid, 'Token'), 'atk': max(0, atk), 'def': max(0, de), 'level': lvl & 0xff,
                                'attribute': attrs.get(attr, ''), 'race': rn}
    strings['tokens'] = tokens
    json.dump(strings, open(os.path.join(out, 'strings.json'), 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
print('cards', len(rows), 'scripts', len(files), 'raw MB', round(len(raw) / 1e6, 1),
      'packed MB', round(os.path.getsize(os.path.join(out, 'scripts.bin')) / 1e6, 1))
