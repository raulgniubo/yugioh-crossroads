#!/usr/bin/env python3
"""The effect reader: turns a card's own text into a working effect.

It reads cards.json (your card database) and, for every effect monster the game does not
already know by hand, tries to understand the WHOLE text out of a set of exact wordings.
A card is only accepted when every sentence is understood. The result is written to
scripts/core/card_effects_auto.gd, in the same form the hand-written effects use.

usage: tools/effect_reader.py /path/to/cards.json
"""
import json, re, sys

N = r'(\d{2,4})'
ATTR = r'(DARK|LIGHT|EARTH|WATER|FIRE|WIND)'

def act(s):
    """One action sentence -> engine actions, or None."""
    s = s.strip().rstrip('.')
    m = re.fullmatch(r'(?:[Yy]ou can )?[Ii]nflict ' + N + r' damage to your opponent', s)
    if m: return [["damage", int(m[1])]]
    m = re.fullmatch(r'(?:You )?[Gg]ain ' + N + r' (?:LP|Life Points)', s)
    if m: return [["heal", int(m[1])]]
    m = re.fullmatch(r'(?:[Yy]ou can )?[Dd]raw (\d) cards?', s)
    if m: return [["draw", int(m[1])]]
    if re.fullmatch(r'(?:[Yy]ou can )?(?:[Tt]arget 1 monster on the field; destroy (?:that target|it)|[Dd]estroy 1 monster on the field)', s): return [["destroy", "best"]]
    if re.fullmatch(r'(?:[Yy]ou can )?(?:[Tt]arget 1 (?:face-up )?monster your opponent controls; destroy (?:that target|it)|[Dd]estroy 1 (?:face-up )?monster your opponent controls)', s): return [["destroy", "best"]]
    m = re.fullmatch(r'(?:[Yy]ou can )?Special Summon 1 ' + ATTR + r' monster with ' + N + r' or less ATK from your Deck(?:,? in (?:face-up )?Attack Position)?', s)
    if m: return [["special", "deck", {"attr": m[1], "max_atk": int(m[2])}, "atk", 1]]
    m = re.fullmatch(r'(?:[Yy]ou can )?[Aa]dd 1 monster with ' + N + r' or less ATK from your Deck to your hand', s)
    if m: return [["search", {"max_atk": int(m[1])}]]
    m = re.fullmatch(r'(?:[Yy]ou can )?[Aa]dd 1 Level (\d) or lower ([A-Z][a-z\-]+(?: [A-Z][a-z\-]+)?) monster from your Deck to your hand', s)
    if m: return [["search", {"max_lv": int(m[1]), "race": m[2]}]]
    m = re.fullmatch(r'(?:[Yy]ou can )?Special Summon 1 Level (\d) or lower monster from your hand', s)
    if m: return [["special", "hand", {"max_lv": int(m[1])}, "any", 1]]
    m = re.fullmatch(r'(?:[Yy]ou can )?[Aa]dd 1 "([^"]+)" from your Deck to your hand', s)
    if m: return [["search", {"name": m[1]}]] if m[1] in IN_GAME else None
    m = re.fullmatch(r'(?:[Yy]ou can )?[Aa]dd 1 "([^"]+)" monster from your Deck to your hand', s)
    if m: return [["search", {"has": m[1], "monster": True}]]
    m = re.fullmatch(r'(?:[Yy]ou can )?[Aa]dd 1 Level (\d) or lower "([^"]+)" monster from your Deck to your hand', s)
    if m: return [["search", {"has": m[2], "max_lv": int(m[1])}]]
    m = re.fullmatch(r'(?:[Yy]ou can )?Special Summon 1 "([^"]+)" from your Deck', s)
    if m: return [["special", "deck", {"name": m[1]}, "any", 1]] if m[1] in IN_GAME else None
    m = re.fullmatch(r'(?:[Yy]ou can )?Special Summon 1 Level (\d) or lower "([^"]+)" monster from your Deck', s)
    if m: return [["special", "deck", {"has": m[2], "max_lv": int(m[1])}, "any", 1]]
    m = re.fullmatch(r'(?:[Yy]ou can )?Special Summon 1 Level (\d) or lower monster from your (?:GY|Graveyard)(?: in (?:face-up )?Defense Position)?', s)
    if m: return [["special", "gy", {"max_lv": int(m[1])}, "def", 1]]
    m = re.fullmatch(r'(?:It|This card) gains ' + N + r' ATK', s)
    if m: return [["perm_atk", int(m[1])]]
    return None

TRIG = [
    (r'FLIP', 'flip'),
    (r'(?:When|If) this card is Normal Summoned', 'summon'),
    (r'(?:When|If) this card is (?:Normal or Special |Normal or Flip |)Summoned', 'any_summon'),
    (r'(?:When|If) this card is Special Summoned', 'any_summon'),
    (r'(?:When|If) this card is destroyed by battle(?: and sent to the (?:GY|Graveyard))?', 'death'),
    (r'(?:When|If) this card is sent from the field to the (?:GY|Graveyard)', 'gy'),
    (r'(?:When|If) this card inflicts battle damage to your opponent', 'damage'),
    (r'(?:When|If) this card destroys an opponent\'s monster by battle(?: and sends it to the (?:GY|Graveyard))?', 'kill'),
    (r'(?:Once per turn, d|D)uring (?:each of )?your Standby Phases?', 'standby'),
    (r'(?:Once per turn, d|D)uring (?:each of )?your End Phases?', 'end'),
]

HAND = r'(?:,? you can|: You can) Special Summon this card \(?from your hand\)?'
PASSIVE = [
    (r'If only your opponent controls a monster' + HAND, {"special_hand_if": "opp_only"}),
    (r'If your opponent controls a monster and you control no monsters' + HAND, {"special_hand_if": "opp_only"}),
    (r'If you control no monsters' + HAND, {"special_hand_if": "own_none"}),
    (r'During battle between this attacking card and a Defense Position monster whose DEF is lower than the ATK of this card, inflict the difference as [Bb]attle [Dd]amage to your opponent', {"piercing": True}),
    (r'If this card attacks a Defense Position monster, inflict piercing battle damage to your opponent', {"piercing": True}),
    (r'Once per turn, this card cannot be destroyed by battle', {"survive_once": True}),
    (r'This card can attack directly', {"direct": True}),
    (r'This card can attack twice during each Battle Phase', {"double_attack": True}),
    (r'If this card attacks a Defense Position monster, inflict piercing battle damage(?: to your opponent)?', {"piercing": True}),
    (r'This card can attack (?:your opponent )?directly', {"direct": True}),
    (r'This card can (?:make a second attack|attack twice) during each Battle Phase', {"double_attack": True}),
    (r'Cannot be destroyed by battle', {"battle_immune": True}),
    (r'If this card attacks, it is changed to Defense Position at the end of the (?:Battle Phase|Damage Step)(?:, and its battle position cannot be changed until the End Phase of your next turn)?', {"def_after_attack": True}),
]

# Sentences that only limit a trigger which, on these events, already happens once.
RIDER = r'\s*You can only use (?:this|the) effect of "[^"]+" once per turn\.|\s*Then shuffle your Deck\.|\s*\* The above text is unofficial[^.]*\.'
ONCE_OK = {"flip", "summon", "any_summon", "death", "gy"}
IN_GAME = set()

def read(desc):
    desc = desc.replace('\r', '').replace('\n', ' ').strip()
    rider = re.search(r'You can only use', desc) is not None
    desc = re.sub(RIDER, '', desc).strip()
    m = re.fullmatch(r'If you control an? "([^"]+)" monster' + HAND + r'\.?', desc)
    if m: return {"special_hand_if": "own_has:" + m[1]}
    out = _read(desc)
    if out and rider and not all(k in ONCE_OK for k in out if isinstance(out[k], list)):
        return None
    return out

def _read(desc):
    # No riders we do not model.
    if re.search(r'once per (?:turn|Duel)\b(?!, d)|You can only|negate|banish|Tribute|discard|Counter|equip|Token|Fusion|Synchro|Xyz|Link|Pendulum|Ritual', desc, re.I) and not re.search(r'^(?:Once per turn, d|D)uring', desc):
        return None
    out = {}
    for part in [p for p in re.split(r'(?<=\.)\s+', desc) if p]:
        s = part.strip().rstrip('.')
        done = False
        for rx, fx in PASSIVE:
            if re.fullmatch(rx, s):
                out.update(fx); done = True; break
        if done: continue
        m = re.fullmatch(r'If this card attacks, it gains ' + N + r' ATK during the Damage Step only', s)
        if m:
            out["atk_attack"] = int(m[1]); continue
        hit = False
        for rx, key in TRIG:
            m = re.fullmatch(rx + r'[:,] (.+)', s)
            if m:
                a = act(m[1])
                if a is None: return None
                out.setdefault(key, []).extend(a); hit = True; break
        if not hit: return None
    return out or None

def main():
    src = sys.argv[1] if len(sys.argv) > 1 else '/tmp/testassets2/cards.json'
    known = set(re.findall(r'^\t"((?:[^"\\]|\\.)+)": \{', open('scripts/core/card_effects.gd').read(), re.M))
    cards = json.load(open(src))
    spells = set(re.findall(r'^\t"((?:[^"\\]|\\.)+)": \{', open('scripts/duel/spell_rules.gd').read(), re.M))
    IN_GAME.update(known | spells | {c['name'] for c in cards if c.get('frameType') == 'normal'})
    got = {}
    for c in cards:
        ft = str(c.get('frameType', ''))
        if not ft.startswith('effect') or c['name'] in known: continue
        fx = read(str(c.get('desc', '')))
        if fx:
            fx["note"] = str(c['desc']).replace('\r', '').replace('\n', ' ')
            got[c['name']] = fx
    # A card that looks for its own family only counts when the family is in the game too.
    def family(fx):
        for k, v in fx.items():
            if isinstance(v, list):
                for a in v:
                    for x in a:
                        if isinstance(x, dict) and "has" in x:
                            return x["has"]
        return fx["special_hand_if"][8:] if str(fx.get("special_hand_if", "")).startswith("own_has:") else None
    while True:
        pool = IN_GAME | set(got)
        drop = [n for n, fx in got.items() if family(fx) and sum(1 for o in pool if family(fx) in o and o != n) < 2]
        if not drop: break
        for n in drop: del got[n]
    def gd(v):
        if v is True: return 'true'
        if isinstance(v, dict): return '{' + ', '.join('%s: %s' % (json.dumps(k), gd(x)) for k, x in v.items()) + '}'
        if isinstance(v, list): return '[' + ', '.join(gd(x) for x in v) + ']'
        return json.dumps(v, ensure_ascii=False)
    with open('scripts/core/card_effects_auto.gd', 'w') as f:
        f.write('class_name CardEffectsAuto\n## Written by tools/effect_reader.py from the card database. Do not edit by hand:\n## run the tool again instead. Every card here had its whole text understood.\n\nconst FX := {\n')
        for name in sorted(got):
            f.write('\t%s: %s,\n' % (json.dumps(name, ensure_ascii=False), gd(got[name])))
        f.write('}\n')
    eff = sum(1 for c in cards if str(c.get('frameType', '')).startswith('effect'))
    print('effect monsters in the database:', eff, ' known by hand:', len(known), ' read from text:', len(got))

if __name__ == '__main__':
    main()
