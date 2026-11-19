import json,collections
p=json.load(open('picked.json'))
d=json.load(open('/tmp/dl_ygo/yy/cards.json'))
bypw={c['password']:c for c in d if c.get('password')}
FOUR_GROUPS=[("Duel Monsters",["Dark Magician","Magician Girl","Blue-Eyes","Red-Eyes","Black Luster Soldier","Chaos","Exodia","Toon","Kuriboh","Jinzo","Gaia","Celtic Guard","Psychic","Cosmos","Everlasting Alloy","Curse of Dragon","Spiral"]),
 ("GX",["Elemental HERO","Destiny HERO","Evil HERO","HERO","Neo-Spacian","Neos","Neo Space","NEXT","Contact","EN ","Yubel","Cyber Dragon","Cybernetic","Ojama","Supreme King","Nightmare","Samsara D","Eternal Favorite","Mature Chronicle","Gruesome","Geistgrinder","Battle of Sleeping","Double Hero","Skydive","Protection of the Elements","Over Fusion","Cross Keeper","Doctor D","D Cubed","D - Force","Break the Destiny","Magistery","Evil Mind","Mask Charge","Super Strident"]),
 ("5D's",["Stardust","Majestic","Synchron","Junk","Black Rose","Blackwing","Red Dragon Archfiend","Power Tool","Earthbound","Malefic","Infernity","Watt","Laval","Fortune","Scrap","Red ","Ruddy","Synchro","Shooting","Converging","Final Cross","Arrive in Light","Rush Warrior","On Your Mark","Fiendish","King Scarlet","Life Extreme","Gathering Light","Ultimaya","Cosmic Flare","Void","Creepy Little Punk","Contract with the Void","Glowing Crossbow","Wattkinetic"]),
 ("ZEXAL",[""])]
MOVE_Z={'Tachyon Spiral Galaxy','Tachyon Spiral of Destruction',"Barian's Chaos Draw",'Numeron Chaos Ritual'}
MOVE_G={'Celestial Apparatus Tesea','Celestial Double Star Shaman','Celestial Observatory'}
four=[n for n,v in p.items() if v['group']=='four']
assigned=collections.OrderedDict((g,[]) for g,_ in FOUR_GROUPS)
for n in four:
    c=bypw[p[n]['password']]; t=(c.get('text') or {}).get('en','')
    if n in MOVE_Z:
        assigned["ZEXAL"].append(n); continue
    if n in MOVE_G:
        continue
    for g,keys in FOUR_GROUPS:
        if g=="ZEXAL" or any(k in n or f'"{k}' in t for k in keys):
            assigned[g].append(n); break
staples=sorted([n for n,v in p.items() if v['group']=='staple']+list(MOVE_G))
names={"Branded":"Branded and Despia (Fusion, 2020+)","Despia":"Branded and Despia (Fusion, 2020+)","Albaz":"Branded and Despia (Fusion, 2020+)","Drytron":"Drytron (Ritual machine dragons, 2020)","Witchcraft":"Witchcrafter (Spellcasters, 2019)","Dragonmaid":"Dragonmaid (Fusion dragons, 2019)","True Draco":"True Draco and True King (Tribute Summons, 2016)","Swordsoul":"Swordsoul (Synchro, 2021)","Cipher":"Cipher (Xyz, goes with Galaxy-Eyes Cipher Dragon)"}
fams=collections.OrderedDict()
for n,v in p.items():
    if v['group'].startswith('fam:'):
        fams.setdefault(names[v['group'][4:]],[]).append(n)
total=len(p)
md=[]
md.append(f"## The plan in one line\n\nInstead of every card after ZEXAL (4,512), bring in a picked set of **{total} cards** that fit a game about the four shows. Today: 7,851 cards. After this build: **{7851+total:,}**.\n")
md.append("## Why not all of them\n\n- The game is about Duel Monsters, GX, 5D's and ZEXAL. 4,500 cards from later shows would make about a third of the pool come from shows that aren't in the game.\n- Packs would fill up with cards nobody in the worlds plays, and the cards you want would come up less.\n- The newest cards are much stronger and would push aside the character decks.\n- Link and Pendulum monsters aren't in the game, so families built on them would come in half broken.\n")
md.append(f"## What's in the {total}\n\n| Group | Cards |\n|---|---|\n| Newer cards for the four shows' families and aces | {len(four)-len(MOVE_G)} |\n| General-use cards (hand traps, removal, draw, Extra Deck monsters any deck can use) | {len(staples)} |\n| 7 newer families that work fully without Links or Pendulums | {sum(len(v) for v in fams.values())} |\n| **Total** | **{total}** |\n")
md.append("## Rules\n\n- No Link or Pendulum monsters, and no card whose text mentions Links or Pendulums (even ones that would half work). Every card here works fully under this game's rules.\n- Every card works exactly as its text says. Families come in whole.\n- Cards already in the game (many general-use cards came in with parts 4 and 5) aren't counted again.\n- No new worlds, characters or street duelists.\n")
md.append("## Where they go\n\n- **The four-show cards** join the packs of their family or era, next to the older cards of that family (for example, newer Stardust cards go with the 5D's Stardust cards).\n- **The general-use cards and the 7 newer families** go into one new special pack, **New Frontier**, in volumes of about 120 cards. It's sold only at the Heartland City card shop and opens after you finish the story, so it feels like a bonus and not the main game.\n- **Theme decks** for the 7 newer families, sold at the Heartland deck counter, also after the story.\n- The card guide (Where to find it) and the pack card lists update by themselves.\n")
md.append("## The build\n\nOne build, **0.56.0**. Every new card goes through the full engine sweep before it ships. Spanish text comes from the official Spanish cards.\n")
md.append("## The full list\n")
for g,l in assigned.items():
    if l: md.append(f"### {g} families and aces ({len(l)})\n\n"+" · ".join(sorted(l))+"\n")
md.append(f"### General-use cards ({len(staples)})\n\n"+" · ".join(staples)+"\n")
for f,l in fams.items():
    md.append(f"### {f} ({len(l)})\n\n"+" · ".join(sorted(l))+"\n")
md.append("Say \"go\" and I build 0.56.0. If you want any card or family in or out, tell me and I'll change the list first.\n")
open('plan.md','w').write("\n".join(md))
print(total, {g:len(l) for g,l in assigned.items()}, {f:len(l) for f,l in fams.items()})
