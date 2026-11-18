#!/usr/bin/env python3
"""Add a card family to the game from one spec file: its card list, booster pack, theme deck,
deck list, where it is sold, when it unlocks, and which ordinary duelist switches to it.

  python3 tools/add_family.py spec.json          (then run tools/cards.sh)

spec.json:
  key, era ("Duel Monsters" | "GX" | "5D's" | "ZEXAL"), cards [names],
  pack {name, color, blurb}, deck {key, name, art, cover, blurb, cards {name: n}, extra {name: n}},
  worlds [shops that sell the pack], stage (the story stage that opens it, like its era's),
  npc {id, old_deck | new_duel {difficulty, intro} (for someone who has no duel yet), lines [..] (optional), swap [[old line, new line], ..] (optional), intro (optional)}
"""
import json, re, sys
ROOT = __file__.rsplit('/tools/', 1)[0]
q = lambda s: json.dumps(s, ensure_ascii=False)

def edit(path, fn):
    p = ROOT + '/' + path
    s = open(p, encoding='utf-8').read()
    t = fn(s)
    assert t != s, 'nothing changed in ' + path
    open(p, 'w', encoding='utf-8').write(t)

def wrap(names, indent='\t\t', width=150):
    lines, cur = [], indent
    for i, n in enumerate(names):
        piece = q(n) + (', ' if i < len(names) - 1 else '')
        if len(cur) + len(piece) > width and cur.strip():
            lines.append(cur.rstrip()); cur = indent
        cur += piece
    lines.append(cur.rstrip())
    return '\n'.join(lines)

def main(spec):
    key, era, deck = spec['key'], spec['era'], spec['deck']
    dk = deck['key']
    assert sum(deck['cards'].values()) >= 40, 'deck has %d cards' % sum(deck['cards'].values())
    def collection(s):
        assert '"%s": {"era"' % key not in s, 'family already there'
        i = s.index('const FAMILIES := {'); j = s.index('\n}\n', i)
        fam = '\n\t%s: {"era": %s, "deck": %s, "cards": [\n%s]},' % (q(key), q(era), q(dk), wrap(spec['cards']))
        s = s[:j] + fam + s[j:]
        first = re.search(r'\n\t\{"key": "[a-z_]+", "tab": 1, ', s)
        pk = '\n\t{"key": %s, "tab": 1, "name": %s, "color": Color(%s), "family": true, "blurb": %s},' % (q(key), q(spec['pack']['name']), q(spec['pack']['color']), q(spec['pack']['blurb']))
        s = s[:first.start()] + pk + s[first.start():]
        m = s.index('\n\t{"key": "deck_monarchs", "art"')
        td = '\n\t{"key": %s, "art": %s, "cover": %s, "color": Color(%s), "era": %s, "blurb": %s},' % (q(dk), q(deck['art']), q(deck['cover']), q(spec['pack']['color']), q(era), q(deck['blurb']))
        return s[:m] + td + s[m:]
    edit('scripts/core/collection.gd', collection)
    def card_data(s):
        m = s.index('\n\t"deck_monarchs": {"name"')
        cards = ', '.join('%s: %d' % (q(n), c) for n, c in deck['cards'].items())
        extra = ', '.join('%s: %d' % (q(n), c) for n, c in deck.get('extra', {}).items())
        d = '\n\t%s: {"name": %s, "cards": {%s}' % (q(dk), q(deck['name']), cards) + (',\n\t\t"extra": {%s}' % extra if extra else '') + '},'
        return s[:m] + d + s[m:]
    edit('scripts/core/card_data.gd', card_data)
    def shop(s):
        for w in spec['worlds']:
            a = s.index('"%s": [' % w, s.index('const WORLD_PACKS')); b = s.index(']', a)
            s = s[:a] + s[a:b].replace(q(era), q(era) + ', ' + q(key), 1) + s[b:]
        return s
    edit('scripts/menu/pack_shop.gd', shop)
    edit('scripts/core/unlocks.gd', lambda s: s.replace('const PACK_STAGE := {', 'const PACK_STAGE := {%s: %d, ' % (q(key), spec['stage']), 1))
    npc = spec['npc']
    def roam(s):
        a = s.index('{"id": %s' % q(npc['id']))
        if npc.get('new_duel'):
            # someone who stands in that world already and has never dueled: they get this deck
            e = s.index(']}', a)
            assert '"duel": {' not in s[a:e], 'that duelist already has a duel'
            nd = npc['new_duel']
            if npc.get('lines'):
                head = re.sub(r'"lines": \[.*?\]$', lambda _: '"lines": [%s]' % ', '.join(q(l) for l in npc['lines']), s[a:e + 1], count=1, flags=re.S)
            else:
                head = s[a:e + 1]
            return s[:a] + head + ',\n\t\t\t\t"duel": {"deck": %s, "difficulty": %d, "intro": %s}' % (q(dk), int(nd.get('difficulty', 1)), q(nd.get('intro', ''))) + s[e + 1:]
        b = s.index('"duel": {', a); c = s.index('}}', b)
        block = s[a:c]
        assert block.count('{"id": ') == 1, 'that duelist has no duel of their own'
        assert '"deck": %s' % q(npc['old_deck']) in block, 'the duelist does not play ' + npc['old_deck']
        block = block.replace('"deck": %s' % q(npc['old_deck']), '"deck": %s' % q(dk))
        if npc.get('lines'):
            block = re.sub(r'"lines": \[.*?\]', lambda _: '"lines": [%s]' % ', '.join(q(l) for l in npc['lines']), block, count=1, flags=re.S)
        for old, new in npc.get('swap', []):
            assert q(old) in block, 'the duelist never says ' + old
            block = block.replace(q(old), q(new))
        if npc.get('intro'):
            block = re.sub(r'"intro": "(?:[^"\\]|\\.)*"', lambda _: '"intro": ' + q(npc['intro']), block, count=1)
        return s[:a] + block + s[c:]
    edit('scripts/roam/roam_data.gd', roam)
    print('added family %s: %d cards, deck %s (%d + %d)' % (key, len(spec['cards']), dk, sum(deck['cards'].values()), sum(deck.get('extra', {}).values())))

if __name__ == '__main__':
    main(json.load(open(sys.argv[1], encoding='utf-8')))
