"""0.56.0: the seven New Frontier theme decks (Heartland deck counter, after the story)."""
import json, sys
ROOT = '/home/claude/yugioh-crossroads'
q = lambda s: json.dumps(s, ensure_ascii=False)
H = {"Infinite Impermanence": 2, "Solemn Strike": 1, "Evenly Matched": 1, "Torrential Tribute": 1}
def plus(*ds):
    out = {}
    for d in ds:
        for k, v in d.items(): out[k] = out.get(k, 0) + v
    return out
DECKS = [
 dict(key="deck_branded", name="Branded Despia", name_es="Despia Marcada", art="dragons", cover="Fallen of Albaz", color="c86a3a",
  blurb="Fallen of Albaz fuses with whatever stands across from it. Branded Fusion pulls two cards straight from the Deck, and every Fusion that leaves the field brings the next Branded card with it.",
  blurb_es="Fallen of Albaz se fusiona con lo que tenga enfrente. Fusión Marcada saca dos cartas directamente del Deck, y cada Fusión que deja el Campo trae consigo la siguiente carta Marcada.",
  cards={"Fallen of Albaz": 3, "Aluber the Jester of Despia": 3, "Despian Tragedy": 1, "Despian Comedy": 1, "Guiding Quem, the Virtuous": 1, "Albion the Shrouded Dragon": 1,
   "The Bystial Aluber": 1, "Bystial Magnamhut": 1, "Bystial Saronir": 1, "Albaz the Ashen": 1, "Ash Blossom & Joyous Spring": 2,
   "Branded Fusion": 3, "Branded Opening": 2, "Branded in Red": 1, "Branded Lost": 1, "Branded in High Spirits": 1, "Branded Regained": 1,
   "Despia, Theater of the Branded": 1, "Called by the Grave": 1, "Branded Bond": 1, "Dark Ruler No More": 1, "Triple Tactics Talent": 1,
   "Branded Retribution": 2, "Branded Expulsion": 1, "Branded Banishment": 2, "Branded Beast": 1, "Infinite Impermanence": 2, "Branded Sword": 1, "Screams of the Branded": 1},
  extra={"Mirrorjade the Iceblade Dragon": 1, "Albion the Branded Dragon": 2, "Titaniklad the Ash Dragon": 1, "Lubellion the Searing Dragon": 1, "Granguignol the Dusk Dragon": 1,
   "Brigrand the Glory Dragon": 1, "Alba-Lenatus the Abyss Dragon": 1, "Sprind the Irondash Dragon": 1, "Despian Quaeritis": 1, "Rindbrumm the Striking Dragon": 1,
   "Masquerade the Blazing Dragon": 1, "Despian Luluwalilith": 1}),
 dict(key="deck_drytron", name="Drytron Constellation", name_es="Constelación Drytron", art="machines", cover="Drytron Meteonis Draconids", color="8ab4ff",
  blurb="The Drytron are Rituals with no Ritual Spell needed: they Tribute each other from the hand to come out, and Meteonis Drytron calls the Level 12 Draconids down on top of them.",
  blurb_es="Los Drytron son Rituales que no necesitan Mágica de Ritual: se Sacrifican entre ellos desde la mano para salir, y Meteonis Drytron hace caer encima a los Draconids de Nivel 12.",
  cards=plus({"Drytron Alpha Thuban": 3, "Drytron Beta Rastaban": 2, "Drytron Gamma Eltanin": 2, "Drytron Zeta Aldhibah": 3, "Drytron Delta Altais": 1,
   "Drytron Meteonis Draconids": 2, "Drytron Meteonis Quadrantids": 1, "Ash Blossom & Joyous Spring": 3, "Ghost Ogre & Snow Rabbit": 1,
   "Meteonis Drytron": 3, "Drytron Nova": 2, "Drytron Fafnir": 1, "Drytron Asterism": 1, "Drytron Eclipse": 1, "Pot of Prosperity": 1, "Called by the Grave": 1,
   "Dark Ruler No More": 1, "Triple Tactics Talent": 1, "Drytron Meteor Shower": 2, "Dimensional Barrier": 1, "Solemn Judgment": 1}, H, {"Infinite Impermanence": 1}),
  extra={"Drytron Mu Beta Fafnir": 2, "Divine Arsenal AA-ZEUS - Sky Thunder": 1}),
 dict(key="deck_dragonmaid", name="Dragonmaid Household", name_es="Casa Dragonmaid", art="dragons", cover="House Dragonmaid", color="7ad0c0",
  blurb="Maids by day, dragons when it matters. Each little Dragonmaid trades places with its big dragon form at the end of the Battle Phase, and House Dragonmaid keeps them coming.",
  blurb_es="Sirvientas de día, dragones cuando hace falta. Cada pequeña Dragonmaid cambia de lugar con su forma de dragón al final de la Battle Phase, y House Dragonmaid hace que sigan llegando.",
  cards=plus({"Kitchen Dragonmaid": 3, "Nurse Dragonmaid": 3, "Laundry Dragonmaid": 3, "Parlor Dragonmaid": 2, "Chamber Dragonmaid": 2, "Dragonmaid Lorpar": 1,
   "Dragonmaid Tinkhec": 1, "Dragonmaid Ernus": 1, "Dragonmaid Nudyarl": 1, "Ash Blossom & Joyous Spring": 2,
   "Dragonmaid Welcome": 1, "Dragonmaid Changeover": 3, "Dragonmaid Hospitality": 1, "Dragonmaid Send-Off": 1, "Called by the Grave": 1, "Pot of Prosperity": 1,
   "Dark Ruler No More": 1, "Triple Tactics Talent": 1, "Polymerization": 1,
   "Dragonmaid Tidying": 2, "Dragonmaid Downtime": 1, "Dimensional Barrier": 1, "Ice Dragon's Prison": 1}, H),
  extra={"House Dragonmaid": 2, "Dragonmaid Sheou": 2}),
 dict(key="deck_swordsoul", name="Swordsoul Mountain", name_es="Montaña Swordsoul", art="warriors", cover="Swordsoul Grandmaster - Chixiao", color="5ac0a0",
  blurb="Every Swordsoul makes a Wyrm Token tuner as it lands, so one card is already a Synchro Summon. Chixiao searches the next one and Chengying banishes whatever is in the way.",
  blurb_es="Cada Swordsoul crea un Token Wyrm cantante al llegar, así que una sola carta ya es una Invocación por Sincronía. Chixiao busca la siguiente y Chengying destierra lo que estorbe.",
  cards=plus({"Swordsoul of Mo Ye": 3, "Swordsoul of Taia": 3, "Swordsoul Strategist Longyuan": 3, "Swordsoul Auspice Chunjun": 1, "The Iris Swordsoul": 1, "The Golden Swordsoul": 1,
   "Ash Blossom & Joyous Spring": 3, "Ghost Belle & Haunted Mansion": 1, "Droll & Lock Bird": 1,
   "Swordsoul Emergence": 3, "Swordsoul Sacred Summit": 2, "Called by the Grave": 1, "Pot of Prosperity": 2, "Dark Ruler No More": 1, "Triple Tactics Talent": 1, "Swordsoul Punishment": 1,
   "Swordsoul Strife": 2, "Swordsoul Blackout": 2, "Swordsoul Assessment": 1, "Dimensional Barrier": 1}, H, {"Infinite Impermanence": 1}),
  extra={"Swordsoul Grandmaster - Chixiao": 2, "Swordsoul Supreme Sovereign - Chengying": 2, "Swordsoul Sinister Sovereign - Qixing Longyuan": 1, "Baronne de Fleur": 1,
   "Crystal Wing Synchro Dragon": 1, "Stardust Dragon": 1, "Herald of the Arc Light": 1, "Tri-Edge Master": 1, "Coral Dragon": 1, "Ravenous Crocodragon Archethys": 1, "Groza, Tyrant of Thunder": 1}),
 dict(key="deck_witchcrafter", name="Witchcrafter Atelier", name_es="Taller Witchcrafter", art="arcane", cover="Witchcrafter Madame Verre", color="c890e0",
  blurb="The Witchcrafters pay for their magic by discarding Spells, and every Witchcrafter Spell comes back from the Graveyard at the End Phase. Madame Verre wins the fights the others start.",
  blurb_es="Las Witchcrafter pagan su magia descartando Mágicas, y cada Mágica Witchcrafter vuelve del Cementerio en la End Phase. Madame Verre gana las peleas que las demás empiezan.",
  cards=plus({"Witchcrafter Genni": 3, "Witchcrafter Potterie": 2, "Witchcrafter Pittore": 3, "Witchcrafter Schmietta": 3, "Witchcrafter Edel": 1, "Witchcrafter Haine": 2,
   "Witchcrafter Madame Verre": 2, "Witchcrafter Golem Aruru": 1, "Ash Blossom & Joyous Spring": 2,
   "Witchcrafter Creation": 3, "Witchcrafter Holiday": 2, "Witchcrafter Confusion Confession": 1, "Witchcrafter Collaboration": 1, "Witchcrafter Draping": 1,
   "Witchcrafter Scroll": 1, "Witchcrafter Bystreet": 1, "Witchcrafter Unveiling": 1, "Called by the Grave": 1, "Dark Ruler No More": 1,
   "Witchcrafter Masterpiece": 1, "Witchcrafter Patronus": 1, "Dimensional Barrier": 1}, H),
  extra={"Witchcrafter Vice-Madame": 2, "Abyss Dweller": 1}),
 dict(key="deck_true_draco", name="True Draco Throne", name_es="Trono True Draco", art="dragons", cover="Master Peace, the True Dracoslayer", color="d0a040",
  blurb="Big Wyrms that Tribute Summon fast. The True Dracos get stronger the more Continuous Spells and Traps you Tribute for them, and the True Kings come out of the hand by destroying cards.",
  blurb_es="Grandes Wyrm que se Invocan por Sacrificio rápido. Los True Draco se hacen más fuertes cuantas más Mágicas y Trampas Continuas Sacrificas por ellos, y los True King salen de la mano destruyendo cartas.",
  cards=plus({"Master Peace, the True Dracoslayer": 2, "Master Peace, the True Dracoslaying King": 1, "Dinomight Knight, the True Dracofighter": 2, "Ignis Heat, the True Dracowarrior": 2,
   "Majesty Maiden, the True Dracocaster": 2, "Dreiath III, the True Dracocavalry General": 1, "Metaltron XII, the True Dracombatant": 1, "True King Agnimazud, the Vanisher": 2,
   "True King Bahrastos, the Fathomer": 1, "True King Lithosagym, the Disaster": 1, "Mariamne, the True Dracophoenix": 1, "Ash Blossom & Joyous Spring": 2,
   "True Draco Heritage": 1, "Disciples of the True Dracophoenix": 1, "Dragonic Diagram": 3, "Pot of Prosperity": 1, "Called by the Grave": 1, "Dark Ruler No More": 1,
   "Triple Tactics Talent": 1, "Foolish Burial Goods": 1, "Monster Reborn": 1,
   "True Draco Apocalypse": 2, "True King's Return": 2, "Solemn Judgment": 1, "Ice Dragon's Prison": 1}, H),
  extra={"True King of All Calamities": 1}),
 dict(key="deck_cipher", name="Cipher Squadron", name_es="Escuadrón Cipher", art="machines", cover="Galaxy-Eyes Cipher Dragon", color="6a9aff",
  blurb="Two Level 4 Ciphers make Galaxy-Eyes Cipher Dragon, the same dragon Kite flies. It takes control of the other side's best monster, and the Cipher spells and traps rank it up.",
  blurb_es="Dos Cipher de Nivel 4 forman a Galaxy-Eyes Cipher Dragon, el mismo dragón que pilota Kite. Toma el control del mejor monstruo del otro lado, y las Mágicas y Trampas Cipher lo suben de Rango.",
  cards=plus({"Cipher Wing": 3, "Cipher Twin Raptor": 3, "Cipher Mirror Knight": 2, "Cipher Biplane": 2, "Cipher Etranger": 2, "Photon Thrasher": 2, "Galaxy Soldier": 2,
   "Photon Vanisher": 1, "Cipher Soldier": 2, "Ash Blossom & Joyous Spring": 2,
   "Double Cipher": 2, "Cipher Interference": 1, "Double Exposure": 1, "Rank-Up-Magic Cipher Ascension": 1, "Galaxy Expedition": 1, "Called by the Grave": 1,
   "Pot of Prosperity": 1, "Dark Ruler No More": 1, "Triple Tactics Talent": 1,
   "Cipher Spectrum": 2, "Dimensional Barrier": 1, "Cipher Bit": 1}, H),
  extra={"Galaxy-Eyes Cipher Dragon": 2, "Neo Galaxy-Eyes Cipher Dragon": 1, "Number 62: Galaxy-Eyes Prime Photon Dragon": 1, "Abyss Dweller": 1, "Number 39: Utopia": 1}),
]
if __name__ == '__main__':
    for D in DECKS:
        n = sum(D['cards'].values())
        print(D['key'], n, sum(D['extra'].values()), max(D['cards'].values()))
        assert n == 40, D['key']
    if '--write' in sys.argv:
        p = ROOT + '/scripts/core/collection.gd'; s = open(p, encoding='utf-8').read()
        m = s.index('\n\t{"key": "deck_monarchs", "art"')
        add = ''.join('\n\t{"key": %s, "worlds": ["heartland"], "stage": 6, "art": %s, "cover": %s, "color": Color(%s), "era": "", "blurb": %s},' % (q(D['key']), q(D['art']), q(D['cover']), q(D['color']), q(D['blurb'])) for D in DECKS)
        s = s[:m] + add + s[m:]; open(p, 'w', encoding='utf-8').write(s)
        p = ROOT + '/scripts/core/card_data.gd'; s = open(p, encoding='utf-8').read()
        m = s.index('\n\t"deck_monarchs": {"name"')
        add = ''.join('\n\t%s: {"name": %s, "cards": {%s},\n\t\t"extra": {%s}},' % (q(D['key']), q(D['name']), ', '.join('%s: %d' % (q(k), v) for k, v in D['cards'].items()), ', '.join('%s: %d' % (q(k), v) for k, v in D['extra'].items())) for D in DECKS)
        s = s[:m] + add + s[m:]; open(p, 'w', encoding='utf-8').write(s)
        with open('/home/claude/work/i18n/es/extras.tsv', 'a', encoding='utf-8') as t:
            for D in DECKS:
                t.write(D['name'] + '\t' + D['name_es'] + '\n' + D['blurb'] + '\t' + D['blurb_es'] + '\n')
        print('written')
