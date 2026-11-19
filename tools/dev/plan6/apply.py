"""0.56.0: put the 533 picked cards into the game. Four-show cards go to their family (if the game has
one) or to their era's singles; the general-use cards and the 7 newer families go to the "frontier" set."""
import json, re, sys
sys.path.insert(0, '/home/claude/yugioh-crossroads/tools/dev/plan6')
ROOT = '/home/claude/yugioh-crossroads'
p = json.load(open(ROOT + '/tools/dev/plan6/picked.json'))
d = json.load(open('/tmp/dl_ygo/yy/cards.json'))
bypw = {c['password']: c for c in d if c.get('password')}
_mp = open(ROOT + '/tools/dev/plan6/make_plan.py').read()
exec(_mp[_mp.index('FOUR_GROUPS='):_mp.index('four=[n for n,v')])   # FOUR_GROUPS, MOVE_Z, MOVE_G
FAMKEY = [("dark_magician", ["Magician Girl", "Chaos Scepter Blast"]),
    ("chaos", ["Chaos Angel", "Chaos Beast", "Chaos Core", "Chaos Grepher", "Chaos Mirage", "Chaos Nephthys", "Chaos Phantasm", "Chaos Ruler", "Chaos Summoning", "Chaos Witch", "Core of Chaos", "Eternal Chaos", "Shell of Chaos", "The Chaos Creator", "Gaia", "Curse of Dragon", "Spiral"]),
    ("hero", ["HERO", "Neo-Spacian", "Neos", "Neo Space", "NEXT", "Contact", "EN ", "Yubel", "Favorite", "Double Hero", "Skydive", "Battle of Sleeping", "Protection of the Elements", "Over Fusion", "Cross Keeper", "Doctor D", "D Cubed", "D - Force", "Break the Destiny", "Magistery", "Evil Mind", "Mask Charge", "Supreme King", "Nightmare", "Samsara D", "Mature Chronicle", "Gruesome", "Geistgrinder"]),
    ("cyber", ["Cyber Dragon", "Cybernetic"]),
    ("synchron", ["Stardust", "Majestic", "Synchron", "Junk", "Converging", "Shooting", "Synchro Chase", "Synchro Dilemma", "Cosmic Flare", "Arrive in Light", "Final Cross", "Rush Warrior", "On Your Mark"]),
    ("watt", ["Watt"]), ("laval", ["Laval"]), ("fortune_lady", ["Fortune"]), ("morphtronic", ["Power Tool"]),
    ("artifact", ["Artifact"]), ("evol", ["Evol", "Evo"]), ("noble_knight", ["Noble", "Merlin", "Morgan, the Enchantress", "Camelot", "Heritage of the Chalice", "Continuing Epic of Charles", "Floral Knights", "Custennin"]),
    ("gears", ["Geargia"]), ("hazy", ["Fire King"]), ("phantom_beast", ["Mecha Phantom"]), ("meklord", ["Earthbound"]), ("archfiend", ["Infernity", "Creepy Little Punk", "Void Cauldron", "Contract with the Void", "Red Cocoon", "Red Supremacy", "King Scarlet", "Red Zone", "Fiendish Golem"]), ("armed_dragon", ["Ojama"]), ("noble_knight", ["Celtic Guard"]), ("hieratic", ["Hieratic"]), ("heraldic", ["Heraldic", "Heraldry"]), ("sylvan", ["Sylvan"])]
def era_of(n):
    c = bypw[p[n]['password']]; t = (c.get('text') or {}).get('en', '')
    if n in MOVE_Z: return 'ZEXAL'
    for g, keys in FOUR_GROUPS:
        if g == 'ZEXAL' or any(k in n or f'"{k}' in t for k in keys):
            return g
fam_add, singles_add, frontier = {}, {}, []
for n, v in p.items():
    g = v['group']
    if g == 'four' and n not in MOVE_G:
        c = bypw[v['password']]; t = (c.get('text') or {}).get('en', '')
        fk = next((k for k, keys in FAMKEY if any(x in n for x in keys)), None)
        if fk:
            fam_add.setdefault(fk, []).append(n)
        else:
            singles_add.setdefault(era_of(n), []).append(n)
    else:
        frontier.append(n)
print({k: len(v) for k, v in fam_add.items()}, {k: len(v) for k, v in singles_add.items()}, 'frontier', len(frontier))
if '--write' in sys.argv:
    s = open(ROOT + '/scripts/core/collection.gd', encoding='utf-8').read()
    for fk, names in fam_add.items():
        m = re.search(r'\n\t"%s": \{"era": "[^"]+", "deck": "[^"]+", "cards": \[(.*?)\]\}' % fk, s, re.S)
        assert m, fk
        have = re.findall(r'"((?:[^"\\]|\\.)*)"', m.group(1))
        extra = [x for x in sorted(names) if x not in have]
        ins = ',\n\t\t' + ', '.join(json.dumps(x, ensure_ascii=False) for x in extra) + '  # 0.56.0' if False else ''
        body = m.group(1).rstrip() + ',\n\t\t' + ', '.join(json.dumps(x, ensure_ascii=False) for x in extra)
        s = s[:m.start(1)] + body + s[m.end(1):]
    open(ROOT + '/scripts/core/collection.gd', 'w', encoding='utf-8').write(s)
    sj = json.load(open(ROOT + '/data/singles.json', encoding='utf-8'))
    for e, names in singles_add.items():
        sj['eras'][e] = sj['eras'][e] + [x for x in sorted(names) if x not in sj['eras'][e]]
    sj['eras']['frontier'] = sorted(frontier)
    sj['note'] += ' "frontier" (0.56.0): the New Frontier pack, cards from after ZEXAL picked for this game.'
    out = '{\n "note": ' + json.dumps(sj['note'], ensure_ascii=False) + ',\n "eras": {\n' + ',\n'.join('  %s: [\n%s\n  ]' % (json.dumps(e), ',\n'.join('   ' + json.dumps(x, ensure_ascii=False) for x in l)) for e, l in sj['eras'].items()) + '\n }\n}\n'
    open(ROOT + '/data/singles.json', 'w', encoding='utf-8').write(out)
    json.dump({'fam': fam_add, 'singles': singles_add, 'frontier': frontier}, open(ROOT + '/tools/dev/plan6/placed.json', 'w'), indent=1, ensure_ascii=False)
    print('written')
