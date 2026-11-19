import sys
sys.path.insert(0, '/home/claude/work/families')
from mk import make

ONE = next((a for a in sys.argv[1:] if not a.startswith('--')), '')
CHECK = '--check' in sys.argv
SPECS = []
def add(spec, strings):
    SPECS.append((spec, strings))

add({"key": "dd", "era": "Duel Monsters",
 "pack": {"name": "Different Dimension", "color": "5a6ad8",
  "blurb": "The D.D. monsters who banish whatever they touch and come back from the other side, the gates and jars that open the way, and the cards that call the banished home."},
 "deck": {"key": "deck_dd", "name": "Different Dimension", "art": "arcane", "cover": "D.D.M. - Different Dimension Master",
  "blurb": "Send monsters across to the other dimension, yours and theirs, then bring your own back stronger. D.D. Survivor and D.D.R. never stay gone for long.",
  "cards": {"D.D. Warrior Lady": 2, "D.D. Assailant": 2, "D.D. Survivor": 3, "D.D. Scout Plane": 2, "D.D. Guide": 1, "D.D. Crazy Beast": 2, "D.D. Unicorn Knight": 2,
   "D.D. Destroyer": 1, "D.D.M. - Different Dimension Master": 1, "Dimensional Alchemist": 2, "D.D. Crow": 1,
   "D.D.R. - Different Dimension Reincarnation": 2, "Dimension Fusion": 1, "Burial from a Different Dimension": 1, "Different Dimension Gate": 1, "D.D. Borderline": 1,
   "Dimensional Fissure": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1,
   "Return from the Different Dimension": 1, "D.D. Dynamite": 1, "D.D. Trap Hole": 2, "Dimension Wall": 2, "Dimensional Prison": 2, "Macro Cosmos": 1,
   "Escape from the Dark Dimension": 1, "Mirror Force": 1, "Call of the Haunted": 1}},
 "worlds": ["domino"], "stage": 0,
 "npc": {"id": "guard", "rotate": True, "intro": "KaibaCorp studies the other dimension. Today you get to see it up close.",
  "lines_add": ["Some days I carry the D.D. deck. Whatever you summon, it ends up somewhere else."]},
}, [
 ("Different Dimension", "Otra Dimensión"),
 ("The D.D. monsters who banish whatever they touch and come back from the other side, the gates and jars that open the way, and the cards that call the banished home.", "Los monstruos D.D. que destierran todo lo que tocan y vuelven del otro lado, las puertas y jarras que abren el camino, y las cartas que traen de vuelta a los desterrados."),
 ("Send monsters across to the other dimension, yours and theirs, then bring your own back stronger. D.D. Survivor and D.D.R. never stay gone for long.", "Manda monstruos a la otra dimensión, tuyos y suyos, y después trae los tuyos de vuelta más fuertes. D.D. Survivor y D.D.R. nunca se quedan fuera mucho tiempo."),
 ("KaibaCorp studies the other dimension. Today you get to see it up close.", "KaibaCorp estudia la otra dimensión. Hoy la vas a ver de cerca."),
 ("Some days I carry the D.D. deck. Whatever you summon, it ends up somewhere else.", "Algunos días llevo el deck D.D. Invoques lo que invoques, acaba en otra parte."),
])

add({"key": "goblin", "era": "Duel Monsters",
 "pack": {"name": "Goblin Gang", "color": "6a9a3a",
  "blurb": "The goblins of every squad and trade: the Attack Forces that hit hard and then need a nap, the thieves and salesmen, and the Ogre Grottos they live in."},
 "deck": {"key": "deck_goblin", "name": "Goblin Gang", "art": "wild", "cover": "Goblin Elite Attack Force",
  "blurb": "Big hits from small goblins. The Attack Forces swing for 2200 and then rest, so the rest of the gang keeps the field busy while they get up again.",
  "cards": {"Goblin Elite Attack Force": 2, "Goblin Attack Force": 2, "Goblin Marauding Squad": 2, "Goblin Recon Squad": 2, "Goblin Black Ops": 2, "Blindly Loyal Goblin": 2,
   "Coach Goblin": 1, "Goblin Pothole Squad": 1, "Goblin Decoy Squad": 1, "Goblindbergh": 2, "Goblin King": 1, "Crow Goblin": 1, "Goblin of Greed": 1,
   "Goblin Thief": 2, "Goblin's Secret Remedy": 1, "Upstart Goblin": 2, "Goblin Circus": 1, "Peeking Goblin": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1,
   "Robbin' Goblin": 1, "Goblin Fan": 1, "Goblin Out of the Frying Pan": 1, "Good Goblin Housekeeping": 1, "Hard-sellin' Goblin": 1, "Minor Goblin Official": 1,
   "Mirror Force": 1, "Call of the Haunted": 1, "Sakuretsu Armor": 1, "Bottomless Trap Hole": 2}},
 "worlds": ["domino"], "stage": 0,
 "npc": {"id": "dome_fan", "rotate": True, "intro": "My goblins are small, loud and always hungry. Just like me!",
  "lines_add": ["Some days I bring the goblins. They hit hard, then they take a nap."]},
}, [
 ("Goblin Gang", "La Banda de los Goblins"),
 ("The goblins of every squad and trade: the Attack Forces that hit hard and then need a nap, the thieves and salesmen, and the Ogre Grottos they live in.", "Los goblins de todos los escuadrones y oficios: las Attack Forces que pegan fuerte y luego necesitan una siesta, los ladrones y vendedores, y las Ogre Grottos donde viven."),
 ("Big hits from small goblins. The Attack Forces swing for 2200 and then rest, so the rest of the gang keeps the field busy while they get up again.", "Golpes grandes de goblins pequeños. Las Attack Forces pegan con 2200 y luego descansan, así que el resto de la banda mantiene ocupado el Campo mientras se levantan."),
 ("My goblins are small, loud and always hungry. Just like me!", "Mis goblins son pequeños, ruidosos y siempre tienen hambre. ¡Como yo!"),
 ("Some days I bring the goblins. They hit hard, then they take a nap.", "Algunos días traigo a los goblins. Pegan fuerte y después se echan una siesta."),
])

add({"key": "mask", "era": "Duel Monsters",
 "pack": {"name": "Masks and Curses", "color": "8a3a5a",
  "blurb": "The Masked Beast and the curse that summons it, the masks that weaken, bind and steal, and the old curses that age, freeze and punish whoever they fall on."},
 "deck": {"key": "deck_mask", "name": "Masks and Curses", "art": "shadow", "cover": "The Masked Beast",
  "blurb": "Curses and masks wear the other side down while you ready the ritual. When the Masked Beast rises, Des Gardius waits behind it to take whatever is left.",
  "cards": {"The Masked Beast": 2, "Masked Beast Des Gardius": 1, "Masked Sorcerer": 2, "Masked Chameleon": 2, "Mask of Darkness": 2, "Masked Clown": 1, "Masked Dragon": 2,
   "Grand Tiki Elder": 2, "Melchid the Four-Face Beast": 2, "Masked Chopper": 1, "Cursed Fig": 1,
   "Curse of the Masked Beast": 2, "The Mask of Remnants": 1, "Mask of the Accursed": 1, "Mask of Dispel": 1, "Mask of Brutality": 1, "Curse of Fiend": 1,
   "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Dark Hole": 1,
   "Mask of Restrict": 1, "Mask of Weakness": 2, "Tutan Mask": 1, "Curse of Aging": 1, "Curse of Anubis": 1, "Curse of Darkness": 1, "Curse of Royal": 1,
   "Mirror Force": 1, "Call of the Haunted": 1, "Bottomless Trap Hole": 1, "Sakuretsu Armor": 1}},
 "worlds": ["domino"], "stage": 0,
 "npc": {"id": "night_domino", "rotate": True, "intro": "Every mask in my collection has a story. Most of them end badly.",
  "lines_add": ["Some nights I bring the masks instead. They remember every face they've worn."]},
}, [
 ("Masks and Curses", "Máscaras y Maldiciones"),
 ("The Masked Beast and the curse that summons it, the masks that weaken, bind and steal, and the old curses that age, freeze and punish whoever they fall on.", "La Bestia Enmascarada y la maldición que la invoca, las máscaras que debilitan, atan y roban, y las viejas maldiciones que envejecen, congelan y castigan a quien caigan."),
 ("Curses and masks wear the other side down while you ready the ritual. When the Masked Beast rises, Des Gardius waits behind it to take whatever is left.", "Las maldiciones y las máscaras desgastan al otro lado mientras preparas el ritual. Cuando se alza la Bestia Enmascarada, Des Gardius espera detrás para llevarse lo que quede."),
 ("Every mask in my collection has a story. Most of them end badly.", "Cada máscara de mi colección tiene una historia. Casi todas acaban mal."),
 ("Some nights I bring the masks instead. They remember every face they've worn.", "Algunas noches traigo las máscaras. Recuerdan todas las caras que han llevado."),
])

add({"key": "toy", "era": "Duel Monsters",
 "pack": {"name": "Toy Box Troubles", "color": "d87a3a",
  "blurb": "The chess Puppets from pawn to king, the Toy soldiers and magicians that hide in the Spell & Trap Zone until they spring out, and the puppeteers who pull every string."},
 "deck": {"key": "deck_toy", "name": "Toy Box Troubles", "art": "arcane", "cover": "Puppet King",
  "blurb": "The Toys hide face-down as Spells and jump out when they're needed, the Toy Box sets them up, and the Puppet King comes back every time he falls.",
  "cards": {"Puppet Pawn": 2, "Puppet Rook": 2, "Puppet Queen": 2, "Puppet King": 2, "Puppet Plant": 1, "Puppet Master": 1, "Mysterious Puppeteer": 2, "Toy Magician": 2,
   "Toy Soldier": 2, "Toy Knight": 2, "Malice Doll of Demise": 2, "Perditious Puppeteer": 1,
   "Toy Box": 2, "The Puppet Magic of Dark Ruler": 1, "Bait Doll": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Dark Hole": 1,
   "Mirror Force": 1, "Call of the Haunted": 2, "Sakuretsu Armor": 2, "Bottomless Trap Hole": 2, "Torrential Tribute": 1, "Compulsory Evacuation Device": 1,
   "Solemn Judgment": 1, "Dimensional Prison": 2}},
 "worlds": ["domino"], "stage": 0,
 "npc": {"id": "kid", "rotate": True, "intro": "My toys come alive when you're not looking. Wanna see?",
  "lines_add": ["Some days I bring my toys. The puppet king is my favorite."]},
}, [
 ("Toy Box Troubles", "Problemas en la Caja de Juguetes"),
 ("The chess Puppets from pawn to king, the Toy soldiers and magicians that hide in the Spell & Trap Zone until they spring out, and the puppeteers who pull every string.", "Las Marionetas de ajedrez, del peón al rey, los soldados y magos Toy que se esconden en la Zona de Magia y Trampas hasta que saltan, y los titiriteros que tiran de todos los hilos."),
 ("The Toys hide face-down as Spells and jump out when they're needed, the Toy Box sets them up, and the Puppet King comes back every time he falls.", "Los Toy se esconden boca abajo como Cartas Mágicas y saltan cuando hacen falta, la Toy Box los prepara, y el Puppet King vuelve cada vez que cae."),
 ("My toys come alive when you're not looking. Wanna see?", "Mis juguetes cobran vida cuando no miras. ¿Quieres verlo?"),
 ("Some days I bring my toys. The puppet king is my favorite.", "Algunos días traigo mis juguetes. El rey marioneta es mi favorito."),
])

add({"key": "barrier", "era": "GX",
 "pack": {"name": "Wardens of the Barrier", "color": "e0d070",
  "blurb": "The six Barrier Statues that lock out every Attribute but their own, and the Counter Fairies who answer every Counter Trap with a reward."},
 "deck": {"key": "deck_barrier", "name": "Wardens of the Barrier", "art": "arcane", "cover": "Splendid Venus",
  "blurb": "A Barrier Statue shuts out a whole Attribute, and every Counter Trap you chain lets a Counter Fairy draw, destroy or come back. Say no to everything.",
  "cards": {"Barrier Statue of the Inferno": 1, "Barrier Statue of the Abyss": 1, "Barrier Statue of the Stormwinds": 1, "Barrier Statue of the Heavens": 1,
   "Barrier Statue of the Drought": 1, "Barrier Statue of the Torrent": 1, "Harvest Angel of Wisdom": 2, "Bountiful Artemis": 2, "Layard the Liberator": 2,
   "Meltiel, Sage of the Sky": 2, "Mei-Kou, Master of Barriers": 1, "Voltanis the Adjudicator": 1, "Splendid Venus": 1,
   "Monster Reborn": 1, "Mystical Space Typhoon": 2, "Pot of Duality": 1, "Pot of Greed": 1,
   "Solemn Judgment": 2, "Solemn Warning": 1, "Magic Jammer": 2, "Seven Tools of the Bandit": 2, "Dark Bribe": 2, "Divine Wrath": 1, "Negate Attack": 2,
   "Synthetic Seraphim": 2, "Black Horn of Heaven": 2, "Horn of Heaven": 1, "Trap Jammer": 1}},
 "worlds": ["academy"], "stage": 2,
 "npc": {"id": "ac_blue_1", "rotate": True, "intro": "A prefect keeps order. My deck keeps order too. Nothing gets through.",
  "lines_add": ["Some days I duel with the Barrier Statues. Pick an Attribute. It's not allowed."]},
}, [
 ("Wardens of the Barrier", "Guardianes de la Barrera"),
 ("The six Barrier Statues that lock out every Attribute but their own, and the Counter Fairies who answer every Counter Trap with a reward.", "Las seis Estatuas de la Barrera que cierran el paso a todos los Atributos menos el suyo, y las Hadas de Contraefecto que responden a cada Trampa de Contraefecto con una recompensa."),
 ("A Barrier Statue shuts out a whole Attribute, and every Counter Trap you chain lets a Counter Fairy draw, destroy or come back. Say no to everything.", "Una Estatua de la Barrera deja fuera un Atributo entero, y cada Trampa de Contraefecto que encadenas deja a un Hada de Contraefecto robar, destruir o volver. Dile que no a todo."),
 ("A prefect keeps order. My deck keeps order too. Nothing gets through.", "Un prefecto mantiene el orden. Mi deck también. No pasa nada."),
 ("Some days I duel with the Barrier Statues. Pick an Attribute. It's not allowed.", "Algunos días duelo con las Estatuas de la Barrera. Elige un Atributo. No está permitido."),
])

add({"key": "frog", "era": "GX",
 "pack": {"name": "Frogs and Penguins", "color": "4ab08a",
  "blurb": "The Frogs that swap, copy and sacrifice themselves for each other, the frog Xyz that rules the pond, and the Penguins that flip up to send your monsters home."},
 "deck": {"key": "deck_frog", "name": "Frogs and Penguins", "art": "tide", "cover": "The Great Emperor Penguin",
  "blurb": "Swap Frog and Ronintoadin keep the pond full, Dupe Frog takes the hits, and the Penguins flip up to bounce whatever comes too close.",
  "cards": {"Treeborn Frog": 1, "Submarine Frog": 1, "Dupe Frog": 2, "Swap Frog": 2, "Ronintoadin": 2, "Flip Flop Frog": 1, "Poison Draw Frog": 1, "Unifrog": 1,
   "Beelze Frog": 1, "Des Frog": 2, "Tradetoad": 1, "T.A.D.P.O.L.E.": 1, "Substitoad": 1, "Penguin Soldier": 2, "Penguin Knight": 1, "Nightmare Penguin": 1,
   "Penguin Ninja": 1, "Puny Penguin": 1, "The Great Emperor Penguin": 1, "Guard Penguin": 1, "Penguin Torpedo": 1,
   "Polymerization": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Salvage": 1, "Pot of Duality": 1,
   "Froggy Forcefield": 2, "Mirror Force": 1, "Call of the Haunted": 1, "Bottomless Trap Hole": 2, "Torrential Tribute": 1, "Compulsory Evacuation Device": 1,
   "Solemn Judgment": 1},
  "extra": {"D.3.S. Frog": 1, "Toadally Awesome": 1}},
 "worlds": ["academy"], "stage": 2,
 "npc": {"id": "captain", "rotate": True, "intro": "The ferry runs on time and so do my frogs. Mostly.",
  "lines_add": ["Some days the frogs and penguins ride with me. They don't get seasick."]},
}, [
 ("Frogs and Penguins", "Ranas y Pingüinos"),
 ("The Frogs that swap, copy and sacrifice themselves for each other, the frog Xyz that rules the pond, and the Penguins that flip up to send your monsters home.", "Las Ranas que se intercambian, se copian y se sacrifican unas por otras, el Xyz rana que manda en el estanque, y los Pingüinos que se voltean para devolver tus monstruos a casa."),
 ("Swap Frog and Ronintoadin keep the pond full, Dupe Frog takes the hits, and the Penguins flip up to bounce whatever comes too close.", "Swap Frog y Ronintoadin mantienen lleno el estanque, Dupe Frog recibe los golpes, y los Pingüinos se voltean para devolver lo que se acerque demasiado."),
 ("The ferry runs on time and so do my frogs. Mostly.", "El ferry sale a su hora, y mis ranas también. Casi siempre."),
 ("Some days the frogs and penguins ride with me. They don't get seasick.", "Algunos días las ranas y los pingüinos viajan conmigo. No se marean."),
])

if __name__ == '__main__':
    import json, sqlite3
    IDS = set(int(x) for x in open('/tmp/ocg_ids.txt') if x.strip())
    db = sqlite3.connect('/home/claude/probe/BabelCDB/cards.cdb')
    ing = set(n for cid, n in db.execute('select id,name from texts') if cid in IDS)
    for spec, strings in SPECS:
        if ONE and spec['key'] != ONE:
            continue
        fam = set(json.load(open('/tmp/fam_%s.json' % spec['key'])))
        d = spec['deck']
        bad = [n for n in list(d['cards']) + list(d.get('extra', {})) if n not in fam and n not in ing]
        n = sum(d['cards'].values())
        if CHECK or bad or n != 40:
            print(spec['key'], n, 'cards', 'not in game:', bad)
            continue
        make(spec, strings)
