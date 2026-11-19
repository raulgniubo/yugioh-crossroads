"""Spanish card names, so a card can be searched by either name (the game shows English names).
Every card the game hands out (/tmp/game_ids.txt, from tools/dev/dump_ids.tscn), its official Spanish name
from yaml-yugi (/tmp/dl_ygo/yy/cards.json) when it has one and it differs from the English one.
Writes data/card_names_es.json: {"<id>": "<Spanish name>"}, sorted, one entry per line.

  python3 tools/dev/cardes/names_es.py
"""
import json
ROOT = __file__.rsplit('/tools/', 1)[0]
y = json.load(open('/tmp/dl_ygo/yy/cards.json'))
by_pw, by_en = {}, {}
for c in y:
    if c.get('password'):
        by_pw[int(c['password'])] = c
        by_en.setdefault(c['name']['en'], c)
mine = {int(c['id']): c['name'] for c in json.load(open('/tmp/testassets3/cards.json'))}
ids = [int(l) for l in open('/tmp/game_ids.txt') if l.strip()]
out, none = {}, 0
for i in ids:
    c = by_pw.get(i) or by_en.get(mine.get(i, ''))
    es = ((c or {}).get('name') or {}).get('es')
    if not es:
        none += 1
        continue
    if es != (c['name'].get('en') or ''):
        out[str(i)] = es
with open(ROOT + '/data/card_names_es.json', 'w') as f:
    f.write('{\n' + ',\n'.join('%s: %s' % (json.dumps(k), json.dumps(v, ensure_ascii=False)) for k, v in sorted(out.items(), key=lambda kv: int(kv[0]))) + '\n}\n')
print(len(ids), 'cards;', len(out), 'Spanish names;', none, 'with no official Spanish name')
