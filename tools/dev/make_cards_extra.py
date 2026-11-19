"""data/cards_extra.json: card entries the game falls back on when the player's cards.json (Crossroads Data)
doesn't know a card by the name the game uses, or doesn't have it at all (cards.json versions rename cards:
"Multiplying Kuriboh!" became "Kuriboh - Multiply!", and some versions drop cards). CardData.load_external
reads it after cards.json: a missing id is added, and the game's name always points at its id.

  python3 tools/dev/make_cards_extra.py <game ids file> <cards.json the game's names come from> <player's cards.json>
"""
import json, sys
ROOT = __file__.rsplit('/tools/', 1)[0]
ids = [int(x) for x in open(sys.argv[1]) if x.strip()]
ref = {x['id']: x for x in json.load(open(sys.argv[2]))}
mine = {x['id']: x for x in json.load(open(sys.argv[3]))}
names = {x['name'].lower() for x in mine.values()}
by_name = {}
for x in mine.values():
    by_name.setdefault(x['name'].lower(), x['id'])
yy = {c['password']: c for c in json.load(open('/tmp/dl_ygo/yy/cards.json')) if c.get('password')}
def from_yy(c, name):
    tl = c.get('monster_type_line') or ''
    if c['card_type'] in ('Spell', 'Trap'):
        return {'id': c['password'], 'name': name, 'type': c['card_type'] + ' Card', 'frameType': c['card_type'].lower(), 'desc': c['text']['en'], 'race': c.get('property', 'Normal')}
    parts = [x.strip() for x in tl.split('/')]
    frame = next((f.lower() for f in ['Fusion', 'Synchro', 'Xyz', 'Ritual'] if f in parts), 'effect' if 'Effect' in parts else 'normal')
    return {'id': c['password'], 'name': name, 'type': ' '.join(parts[1:]) + ' Monster', 'frameType': frame, 'desc': c['text']['en'], 'race': parts[0],
            'atk': c.get('atk', 0) if isinstance(c.get('atk'), int) else 0, 'def': c.get('def', 0) if isinstance(c.get('def'), int) else 0,
            'level': c.get('level', c.get('rank', 0)), 'attribute': c.get('attribute', '')}
out = []
for i in ids:
    name = (ref.get(i) or {}).get('name') or ((yy.get(i) or {}).get('name') or {}).get('en')
    if not name or (i in mine and mine[i]['name'] == name):
        continue
    if i not in mine and name.lower() in by_name:
        # (the player's file has this card under another id, a reprint's: keep the game's id, show that picture)
        e = dict(mine[by_name[name.lower()]]); e['id'] = i; e['name'] = name; e['image'] = by_name[name.lower()]
        for k in ('card_images', 'card_prices', 'ygoprodeck_url'):
            e.pop(k, None)
    elif i in mine:
        e = dict(mine[i]); e['name'] = name
        for k in ('card_images', 'card_prices', 'ygoprodeck_url'):
            e.pop(k, None)
    elif i in ref and 'race' in ref[i]:
        e = dict(ref[i])
    elif i in yy:
        e = from_yy(yy[i], name)
    else:
        print('no data for', i, name); continue
    out.append(e)
json.dump(out, open(ROOT + '/data/cards_extra.json', 'w'), ensure_ascii=False, indent=0)
print(len(out), 'entries:', ', '.join(e['name'] for e in out))
