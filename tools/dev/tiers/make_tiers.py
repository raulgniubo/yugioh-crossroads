#!/usr/bin/env python3
"""Deck strength by stars, the Full version: give each family's theme deck the best single cards of
its era (or an earlier one), swapped in for weak generic Spells and Traps (3 at most).

  python3 tools/dev/tiers/make_tiers.py [--write]

The Starter and Standard versions are not written out: scripts/core/deck_tiers.gd builds them from
the Full deck when a duel starts, so they follow the deck whenever it changes.
"""
import json, os, re, sqlite3, sys
ROOT = os.environ.get('YGO_ROOT') or os.path.abspath(__file__).rsplit('/tools/', 1)[0]
DB = '/home/claude/probe/BabelCDB/cards.cdb'
IDS = set(int(x) for x in open('/tmp/ocg_ids.txt') if x.strip())
ERAS = ["Duel Monsters", "GX", "5D's", "ZEXAL"]
BEST = {
    "Duel Monsters": ["Phoenix Wing Wind Blast", "Swords of Concealing Light", "Creature Swap", "Trap Dustshoot"],
    "GX": ["D.D. Crow", "Necro Gardna", "Gorz the Emissary of Darkness"],
    "5D's": ["Solemn Warning", "Pot of Duality", "Black Horn of Heaven"],
    "ZEXAL": ["Maxx \"C\"", "Twin Twisters", "Cosmic Cyclone", "Solemn Strike"],
}
WEAK = ["Waboku", "Negate Attack", "Threatening Roar", "Enchanted Javelin", "Trap Hole", "Magic Cylinder", "Hammer Shot",
        "Fissure", "Swords of Revealing Light", "Upstart Goblin", "Sakuretsu Armor"]
SKIP = {"deck_exodia", "deck_kuriboh"}   # stall decks: their Waboku and Negate Attack are the plan
SECOND_COPY = ["Call of the Haunted", "Mystical Space Typhoon", "Book of Moon"]   # a 2nd copy can go too

db = sqlite3.connect(DB)
FACT = {}
for cid, name, typ, lvl, race, attr, atk, de, alias in db.execute('select t.id,t.name,d.type,d.level,d.race,d.attribute,d.atk,d.def,d.alias from texts t join datas d using(id)'):
    if alias == 0 or name not in FACT:
        FACT.setdefault(name, dict(id=cid, type=typ, level=lvl & 0xff, race=race, attr=attr, atk=atk, de=de, ingame=False))
    if cid in IDS:
        FACT[name]['ingame'] = True

def kind(n):
    t = FACT[n]['type']
    if t & 1:
        if t & (0x40 | 0x2000 | 0x800000): return 'extra'
        return 'monster'
    return 'spell' if t & 2 else 'trap'

def is_normal(n): return bool(FACT[n]['type'] & 0x10) and not FACT[n]['type'] & 0x20

def braces(s, i):
    d = 0
    for j in range(i, len(s)):
        if s[j] == '{': d += 1
        elif s[j] == '}':
            d -= 1
            if d == 0: return j + 1
    raise ValueError

def jload(txt):
    return json.loads(re.sub(r',\s*([}\]])', r'\1', txt))

cd_path = ROOT + '/scripts/core/card_data.gd'
cd = open(cd_path, encoding='utf-8').read()
col = open(ROOT + '/scripts/core/collection.gd', encoding='utf-8').read()
fam = col[col.index('const FAMILIES := {'):]
fam = fam[:fam.index('\n}\n')]
families = []
for m in re.finditer(r'^\t"(\w+)": \{"era": "([^"]+)", "deck": "(\w+)", "cards": \[(.*?)\]', fam, re.M | re.S):
    names = [n.replace('\\"', '"') for n in re.findall(r'"((?:[^"\\]|\\.)*)"', m.group(4))]
    families.append(dict(key=m.group(1), era=m.group(2), deck=m.group(3), cards=names))

def deck_entry(key):
    i = cd.index('\t"%s": {' % key)
    j = braces(cd, cd.index('{', i))
    return i, j, jload(cd[cd.index('{', i):j])

def fmt(d):
    q = lambda s: json.dumps(s, ensure_ascii=False)
    return '{' + ', '.join('%s: %d' % (q(n), c) for n, c in d.items()) + '}'

def stronger(f, full):
    main = dict(full['cards'])
    era_i = ERAS.index(f['era'])
    best = [n for e in ERAS[:era_i + 1][::-1] for n in BEST[e] if FACT.get(n, {}).get('ingame') and n not in main]
    added = []
    fam = set(f['cards'])
    for n in best:
        if len(added) >= 3:
            break
        out = next((w for w in WEAK if main.get(w, 0) > 0 and w not in fam), None)
        if out is None:
            out = next((w for w in SECOND_COPY if main.get(w, 0) >= 2), None)
        if out is None:
            break
        main[out] -= 1
        if main[out] == 0:
            del main[out]
        main[n] = 1
        added.append('%s for %s' % (n, out))
    return main, added

edits = []
for f in families:
    try:
        i, j, full = deck_entry(f['deck'])
    except ValueError:
        continue
    main, added = stronger(f, full) if f['deck'] not in SKIP else (dict(full['cards']), [])
    assert sum(main.values()) == sum(full['cards'].values())
    print('%-22s %s' % (f['deck'], '; '.join(added) or '-'))
    if added:
        edits.append((i, j, main))
print(len(edits), 'decks changed')
if '--write' in sys.argv:
    s = cd
    for i, j, main in sorted(edits, key=lambda e: -e[0]):
        old = s[i:j]
        k = old.index('"cards": {') + len('"cards": ')
        rest = old[k:]
        rest = rest[braces(rest, 0):]
        s = s[:i] + old[:k] + fmt(main) + rest + s[j:]
    open(cd_path, 'w', encoding='utf-8').write(s)
    print('written')
