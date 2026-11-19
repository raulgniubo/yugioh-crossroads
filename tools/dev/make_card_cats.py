"""What each card does, as the card database tags it (the "category" bits EDOPro searches by): destroy, draw,
Special Summon, damage... Written to data/card_cats.json as {"<id>": bits}, for the look a card's activation
gets in a duel (scripts/duel/card_fx.gd). Cards with no tag are left out.

  python3 tools/dev/make_card_cats.py [BabelCDB folder]     (needs /tmp/game_ids.txt from tools/dev/dump_ids.tscn)
"""
import sqlite3, glob, json, sys, os
ROOT = os.path.dirname(os.path.abspath(__file__)).rsplit('/tools/', 1)[0]
cdb = sys.argv[1] if len(sys.argv) > 1 else '/home/claude/probe/BabelCDB'
ids = {int(l) for l in open('/tmp/game_ids.txt') if l.strip()}
cats = {}
for f in sorted(glob.glob(os.path.join(cdb, '*.cdb'))):
    if 'rush' in f or 'skill' in f:
        continue
    try:
        for i, c in sqlite3.connect(f).execute('SELECT id, category FROM datas'):
            if i in ids and c and i not in cats:
                cats[i] = int(c) & 0xffffffff
    except sqlite3.Error as e:
        print('skip', f, e)
with open(ROOT + '/data/card_cats.json', 'w') as out:
    out.write('{' + ','.join('"%d":%d' % kv for kv in sorted(cats.items())) + '}\n')
print(len(ids), 'cards;', len(cats), 'with a category')
