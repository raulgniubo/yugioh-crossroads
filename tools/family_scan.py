#!/usr/bin/env python3
"""List a whole card family before adding it: every member by the engine's own set codes, every
card that names the family in its text, and every outside card those scripts lean on.

  python3 tools/family_scan.py <probe folder> <cards.json> <ids file> <key> <set codes> <text regex> [extra.json] [-t]

  probe folder  holds BabelCDB/ and CardScripts/
  cards.json    the card folder's list (the cards the game can show)
  ids file      the ids the game names now (tests/ocg_sim.tscn -- ids <file>)
  set codes     comma separated, hex (0x2,0x45)
  extra.json    {"add": [names], "drop": [names]}  (optional)
  -t            also print the English text of every card that still needs Spanish

Writes /tmp/fam_<key>.json (the names, in order). Skips Link, Pendulum, tokens, alternate art,
and cards the card folder does not have. Nothing else is skipped.
"""
import sqlite3, glob, json, re, os, sys

probe, cards_json, ids_file, key, codes, rx = sys.argv[1:7]
rest = sys.argv[7:]
want_text = '-t' in rest
rest = [a for a in rest if a != '-t']
extra = json.load(open(rest[0])) if rest and os.path.exists(rest[0]) else {}
codes = [int(c, 16) for c in codes.split(',') if c]
ROOT = __file__.rsplit('/tools/', 1)[0]

cards = json.load(open(cards_json))
cards = cards['data'] if isinstance(cards, dict) and 'data' in cards else cards
byid = {x['id']: x for x in cards}
byname = {x['name']: x for x in cards}
pool = set(int(l) for l in open(ids_file).read().split() if l.strip().isdigit())
rows = {}
for f in sorted(glob.glob(probe + '/BabelCDB/*.cdb')):
    try:
        c = sqlite3.connect(f)
        for i, alias, setcode, typ, atk, de, lv, race, attr in c.execute('select id,alias,setcode,type,atk,def,level,race,attribute from datas'):
            rows[i] = dict(alias=alias, setcode=setcode, type=typ, atk=atk, level=lv)
        for i, n, d in c.execute('select id,name,desc from texts'):
            if i in rows:
                rows[i]['name'] = n; rows[i]['desc'] = d
    except Exception:
        pass

LINK, PEND, TOKEN = 0x4000000, 0x1000000, 0x4000

def in_set(i, code):
    sc = rows[i]['setcode']
    for k in range(4):
        v = (sc >> (16 * k)) & 0xffff
        if v and (v & 0xfff) == (code & 0xfff) and (v & code) == code:
            return True
    return False

def why_not(i):
    r = rows[i]
    if r['type'] & (LINK | PEND | TOKEN): return 'link/pendulum/token'
    if r.get('alias') and r['alias'] != i and abs(r['alias'] - i) < 20: return 'alternate art'
    if i not in byid: return 'not in the card folder'
    return ''

def kind(i):
    t = rows[i]['type']
    if t & 0x2: return 'Spell'
    if t & 0x4: return 'Trap'
    for bit, n in ((0x40, 'Fusion'), (0x2000, 'Synchro'), (0x800000, 'Xyz'), (0x80, 'Ritual')):
        if t & bit: return n
    return 'Monster L%d' % (rows[i]['level'] & 0xff)

def script_of(i):
    for d in ('official', 'unofficial'):
        p = '%s/CardScripts/%s/c%d.lua' % (probe, d, i)
        if os.path.exists(p): return p
    return ''

members = [i for i in rows if 'name' in rows[i] and any(in_set(i, c) for c in codes)]
mention = [i for i in rows if i not in set(members) and 'desc' in rows[i] and rx and re.search(rx, rows[i]['desc'])]

def show(title, ids):
    print('\n##', title, len(ids))
    for i in sorted(ids, key=lambda i: (kind(i), rows[i]['name'])):
        w = why_not(i)
        flags = (' [SKIP: %s]' % w if w else '') + (' [in game]' if i in pool else '')
        if not script_of(i) and not rows[i]['type'] & 0x10: flags += ' [NO SCRIPT]'
        print('  %-9d %-10s %s%s' % (i, kind(i), rows[i]['name'], flags))

show('members', members)
show('named in text', mention)

fam = [i for i in members + mention if not why_not(i)]
for n in extra.get('add', []):
    x = [i for i in rows if rows[i].get('name') == n and not why_not(i)]
    if not x: print('!! unknown extra name', n)
    else: fam.append(min(x))
fam = [i for i in dict.fromkeys(fam) if rows[i]['name'] not in extra.get('drop', [])]

out = {}
for i in fam:
    p = script_of(i)
    if not p: continue
    s = open(p, encoding='utf-8', errors='ignore').read()
    for m in set(int(x) for x in re.findall(r'(?<![\w.])(\d{5,9})(?![\w.])', s)):
        if m in rows and 'name' in rows[m] and m != i and m not in pool and m not in fam and not why_not(m):
            out.setdefault(m, []).append(rows[i]['name'])
print('\n## family', len(fam), 'new', sum(1 for i in fam if i not in pool))
for k, v in out.items():
    print('  outside card a script names:', rows[k]['name'], k, kind(k), '<-', v[:3])

names = [rows[i]['name'] for i in sorted(fam, key=lambda i: (kind(i), rows[i]['name']))]
json.dump(names, open('/tmp/fam_%s.json' % key, 'w'))
if want_text:
    es = json.load(open(ROOT + '/data/card_text_es.json'))
    n = 0
    for nm in names:
        x = byname.get(nm)
        if not x: print('!! not in folder', nm); continue
        if nm in es: continue
        print('@@', nm, '||', x['desc'].replace('\r', '').replace('\n', ' / ').replace(" /  / * The above text is unofficial and describes the card's functionality in the OCG.", ''))
        n += 1
    print('to translate', n)
