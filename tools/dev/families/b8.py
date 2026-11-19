import sys
sys.path.insert(0, '/home/claude/work/families')
from mk import make
ONE = next((a for a in sys.argv[1:] if not a.startswith('--')), '')
CHECK = '--check' in sys.argv
SPECS = []
T = {"Mirror Force": 1, "Bottomless Trap Hole": 2, "Solemn Judgment": 1, "Torrential Tribute": 1, "Call of the Haunted": 1}
def deck(d, *more):
    out = dict(d)
    for m in more:
        for k, v in m.items():
            out[k] = out.get(k, 0) + v
    return out
def add(key, era, color, pname, pes, pblurb, pblurb_es, dname, des, cover, art, dblurb, dblurb_es, cards, extra, npc, intro, intro_es, line, line_es):
    worlds = ["satellite", "newdomino"] if era == "5D's" else ["heartland"]
    stage = 3 if era == "5D's" else 4
    n = {"id": npc, "rotate": True, "intro": intro, "lines_add": [line]} if npc else None
    spec = {"key": key, "era": era, "pack": {"name": pname, "color": color, "blurb": pblurb},
        "deck": {"key": "deck_" + key, "name": dname, "art": art, "cover": cover, "blurb": dblurb, "cards": cards, "extra": extra},
        "worlds": worlds, "stage": stage, "npc": n}
    strings = [(pname, pes), (pblurb, pblurb_es), (dblurb, dblurb_es), (intro, intro_es), (line, line_es)]
    if dname != pname:
        strings.append((dname, des))
    SPECS.append((spec, strings))

add("worm", "5D's", "8ab060", "The Worm Invasion", "La Invasión Worm",
 "The Worms, LIGHT Reptiles from another planet: they flip face-down, swarm the field and turn every flip into a trick, until Worm Zero takes their place.",
 "Los Worm, Reptiles de LUZ de otro planeta: se ponen boca abajo, llenan el Campo y convierten cada volteo en un truco, hasta que Worm Zero ocupa su lugar.",
 "The Worm Invasion", "", "Worm King", "wild",
 "Flip the Worms face-up one after another: each one sets up the next, and the King and Queen come down when the field is full of them.",
 "Voltea a los Worm uno tras otro: cada uno prepara al siguiente, y el Rey y la Reina bajan cuando el Campo está lleno de ellos.",
 deck({"Worm Xex": 3, "Worm Yagan": 2, "Worm Opera": 2, "Worm Linx": 2, "Worm Ugly": 1, "Worm Gulse": 2, "Worm Rakuyeh": 2, "Worm Solid": 1, "Worm Tentacles": 1,
  "Worm Jetelikpse": 1, "Worm Falco": 1, "Worm Prince": 1, "Worm King": 1, "Worm Queen": 1, "Worm Warlord": 1, "Worm Noble": 1, "Worm Hope": 1,
  "Worm Bait": 1, "Worm Call": 2, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Pot of Duality": 1,
  "Compulsory Evacuation Device": 1, "Dimensional Prison": 2, "Sakuretsu Armor": 1}, T),
 {"Worm Zero": 1}, "sat_kid", "I found these in a crater out past the junkyard. They look friendly. Mostly.", "Los encontré en un cráter más allá del basurero. Parecen simpáticos. Casi todos.",
 "Some days I bring the space worms. Don't ask where they came from.", "Algunos días traigo a los gusanos del espacio. No preguntes de dónde salieron.")

add("swarm", "5D's", "6a4a7a", "Swarm of the Lswarm", "El Enjambre Lswarm",
 "The Steelswarm demons and the Evilswarm they became after the Infestation: Tributes for the old ones, Xyz Summons for the new, and the Infestation cards that spread through both.",
 "Los demonios Steelswarm y los Evilswarm en los que se convirtieron tras la Infestación: Sacrificios para los viejos, Invocaciones Xyz para los nuevos, y las cartas Infestation que se extienden por ambos.",
 "Swarm of the Lswarm", "", "Evilswarm Ophion", "shadow",
 "Line up two Level 4 Evilswarm and overlay them. Ophion locks out big monsters, Bahamut steals the field, and the Infestation traps keep the swarm coming back.",
 "Pon en fila dos Evilswarm de Nivel 4 y superponlos. Ophion bloquea a los monstruos grandes, Bahamut roba el Campo, y las Trampas Infestation hacen que el enjambre siempre vuelva.",
 {"Steelswarm Caller": 2, "Steelswarm Scout": 1, "Steelswarm Sentinel": 2, "Steelswarm Genome": 1, "Steelswarm Sting": 2, "Steelswarm Gatekeeper": 1,
  "Steelswarm Mantis": 1, "Steelswarm Moth": 1, "Steelswarm Girastag": 1, "Steelswarm Caucastag": 1, "Evilswarm Castor": 3, "Evilswarm Mandragora": 2,
  "Evilswarm Salamandra": 2, "Evilswarm Kerykeion": 2, "Evilswarm Heliotrope": 1,
  "Infestation Pandemic": 2, "First Step Towards Infestation": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1,
  "Infestation Wave": 2, "Infestation Infection": 1, "Infestation Terminus": 1, "Infestation Ripples": 1, "Bottomless Trap Hole": 2, "Solemn Judgment": 1,
  "Torrential Tribute": 1, "Mirror Force": 1, "Call of the Haunted": 1, "Dimensional Prison": 1},
 {"Evilswarm Ophion": 1, "Evilswarm Bahamut": 1, "Evilswarm Ouroboros": 1, "Evilswarm Thanatos": 1, "Evilswarm Exciton Knight": 1, "Steelswarm Roach": 1, "Evilswarm Nightmare": 1},
 "night_satellite", "Something crawled out of the old reactor. I made it a deck.", "Algo salió arrastrándose del viejo reactor. Le hice un deck.",
 "Some nights I bring the swarm. They're hungry after dark.", "Algunas noches traigo el enjambre. De noche tienen hambre.")

add("vylon", "5D's", "e0e8ff", "Vylon Assembly", "Ensamblaje Vylon",
 "The Vylon, LIGHT machine-angels that Synchro Summon and then equip themselves with the Vylon Equip Spells, and the Vylon Omega and Disigma at the top.",
 "Los Vylon, ángeles máquina de LUZ que Invocan por Sincronía y después se equipan con las Mágicas de Equipo Vylon, y Vylon Omega y Disigma en lo más alto.",
 "Vylon Assembly", "", "Vylon Omega", "machines",
 "Tune a Vylon, Synchro Summon, and every Vylon that leaves the field brings an Equip Spell with it. The more equips you stack, the stronger they get.",
 "Afina un Vylon, Invoca por Sincronía, y cada Vylon que deja el Campo trae una Mágica de Equipo con él. Cuantos más equipos acumules, más fuertes se vuelven.",
 deck({"Vylon Stigma": 2, "Vylon Prism": 2, "Vylon Ohm": 2, "Vylon Hept": 1, "Vylon Soldier": 1, "Vylon Charger": 2, "Vylon Vanguard": 2, "Vylon Cube": 2,
  "Vylon Tetra": 2, "Vylon Sphere": 2, "Vylon Stella": 2, "Vylon Tesseract": 1, "Vylon Pentachloro": 1,
  "Vylon Material": 1, "Vylon Element": 1, "Vylon Component": 1, "Vylon Polytope": 1, "Vylon Segment": 1, "Vylon Filament": 1, "Vylon Matter": 1,
  "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Bottomless Trap Hole": 2, "Dimensional Prison": 2, "Compulsory Evacuation Device": 1},
  {"Mirror Force": 1, "Solemn Judgment": 1, "Torrential Tribute": 1, "Call of the Haunted": 1}),
 {"Vylon Alpha": 1, "Vylon Delta": 1, "Vylon Epsilon": 1, "Vylon Omega": 1, "Vylon Sigma": 1, "Vylon Disigma": 1},
 "nd_resident", "Up in the Tops we have angels on the payroll. Mechanical ones.", "Arriba en los Tops tenemos ángeles en nómina. Mecánicos.",
 "Some days I bring the Vylon. They polish themselves.", "Algunos días traigo los Vylon. Se pulen solos.")

add("gishki", "5D's", "3a7ad8", "The Aquamirror", "El Espejo de Agua",
 "The Gishki ritualists of the water and the Evigishki they summon through the Aquamirror, with the Aquamirror spells that find a ritual in the Deck.",
 "Los ritualistas Gishki del agua y los Evigishki que invocan a través del Espejo de Agua, con las Mágicas Aquamirror que encuentran un ritual en el Deck.",
 "The Aquamirror", "", "Evigishki Gustkraken", "tide",
 "The Gishki find the ritual and the monster, the Aquamirror brings them across, and Gustkraken looks at the other side's hand before it sends it away.",
 "Los Gishki encuentran el ritual y el monstruo, el Espejo de Agua los trae al otro lado, y Gustkraken mira la mano del adversario antes de devolverla.",
 deck({"Gishki Ariel": 2, "Gishki Avance": 1, "Gishki Beast": 1, "Gishki Chain": 2, "Gishki Diviner": 1, "Gishki Marker": 1, "Gishki Mollusk": 1, "Gishki Noellia": 2,
  "Gishki Shadow": 2, "Gishki Vision": 2, "Gishki Natalia": 1, "Gishki Emilia": 1, "Evigishki Gustkraken": 2, "Evigishki Levianima": 1, "Evigishki Soul Ogre": 1,
  "Evigishki Mind Augus": 1, "Gishki Psychelone": 1, "Evigishki Tetrogre": 1,
  "Gishki Aquamirror": 3, "Contact with the Aquamirror": 1, "Forbidden Arts of the Gishki": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Salvage": 1,
  "Aquamirror Illusion": 1, "Aquamirror Cycle": 1}, T),
 {"Evigishki Merrowgeist": 1}, "night_newdomino", "The water remembers every duel. Look into it.", "El agua recuerda cada duelo. Mírala.",
 "Some nights the mirror comes with me. It shows what you'll draw.", "Algunas noches el espejo viene conmigo. Enseña lo que vas a robar.")

add("watt", "5D's", "f0d040", "Wattage", "Vatios",
 "The Watt monsters, small LIGHT Thunder beasts that strike for their effects when they deal damage, and the Watt Synchros that charge through.",
 "Los monstruos Watt, pequeñas bestias Trueno de LUZ que activan sus efectos al hacer daño, y los Sincronía Watt que cargan a través de todo.",
 "Wattage", "", "Wattaildragon", "arcane",
 "Small Watt monsters that hit the other duelist directly and get a reward each time. Keep the current flowing and Wattchimera never stops.",
 "Pequeños monstruos Watt que atacan directamente al otro duelista y reciben una recompensa cada vez. Mantén la corriente y Wattchimera no para.",
 deck({"Wattcobra": 2, "Wattgiraffe": 2, "Wattpheasant": 2, "Wattkiwi": 2, "Wattsquirrel": 2, "Wattwoodpecker": 2, "Wattdragonfly": 2, "Wattfox": 2,
  "Wattlemur": 2, "Wattmole": 1, "Wattberyx": 1, "Wattsychic Fighter": 2, "Wattaildragon": 1, "Wattkid": 1, "Watthopper": 1, "Wattbetta": 1,
  "Wattcube": 1, "Wattjustment": 1, "Wattkey": 1, "Wattcastle": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Wattcannon": 1, "Wattkeeper": 1}, T),
 {"Wattchimera": 1, "Watthydra": 1}, "nd_rider", "Every runner engine needs a spark. Here's mine.", "Todo motor de runner necesita una chispa. Aquí está la mía.",
 "Some days I bring the Watt deck. It runs on pure static.", "Algunos días traigo el deck Watt. Funciona con pura electricidad estática.")

add("laval", "5D's", "e04a2a", "Laval Eruption", "Erupción Laval",
 "The Laval of the volcano: FIRE monsters that grow stronger with every Laval in the Graveyard, and the Lavalval Synchros and Xyz they melt into.",
 "Los Laval del volcán: monstruos de FUEGO que se hacen más fuertes con cada Laval en el Cementerio, y los Sincronía y Xyz Lavalval en los que se funden.",
 "Laval Eruption", "", "Laval Stennon", "wild",
 "Fill the Graveyard with Laval and the ones on the field burn hotter. The Volcano Handmaiden sends more down and the Synchros finish the job.",
 "Llena el Cementerio de Laval y los del Campo arden más. La Volcano Handmaiden manda más abajo y los Sincronía terminan el trabajo.",
 {"Laval Volcano Handmaiden": 2, "Laval Lakeside Lady": 2, "Laval Forest Sprite": 2, "Laval Phlogis": 2, "Laval Magma Cannoneer": 2, "Laval Warrior": 2,
  "Laval Cannon": 2, "Laval Blaster": 2, "Laval Burner": 2, "Laval Coatl": 2, "Laval Miller": 2, "Laval Lancelord": 1, "Laval Judgment Lord": 1,
  "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Pot of Duality": 1, "Dark Hole": 1,
  "Mirror Force": 1, "Call of the Haunted": 2, "Bottomless Trap Hole": 2, "Torrential Tribute": 1, "Compulsory Evacuation Device": 1, "Solemn Judgment": 1,
  "Dimensional Prison": 2, "Sakuretsu Armor": 2},
 {"Laval Dual Slasher": 1, "Laval Stennon": 1, "Laval the Greater": 1, "Lavalval Dragon": 1, "Lavalval Dragun": 1, "Lavalval Ignis": 1, "Lavalval Chain": 1},
 "nd_chief", "Security keeps the city cool. My deck runs hot.", "Seguridad mantiene fría la ciudad. Mi deck va caliente.",
 "Some days I bring the Laval. The fire marshal hates it.", "Algunos días traigo a los Laval. El jefe de bomberos lo odia.")

add("ally_justice", "5D's", "a0a0b0", "Allies of Justice", "Aliados de la Justicia",
 "The Ally of Justice machines built to hunt LIGHT monsters, from the little Cycle Reader up to Decisive Armor and the Field Marshal.",
 "Las máquinas Ally of Justice construidas para cazar monstruos de LUZ, desde el pequeño Cycle Reader hasta Decisive Armor y el Field Marshal.",
 "Allies of Justice", "", "Ally of Justice Decisive Armor", "machines",
 "Machines that punish LIGHT monsters: they destroy them in battle, take their attacks, and tune into Synchros that lock them out.",
 "Máquinas que castigan a los monstruos de LUZ: los destruyen en combate, aguantan sus ataques y se afinan en Sincronías que los dejan fuera.",
 {"Ally of Justice Garadholg": 2, "Ally of Justice Cycle Reader": 2, "Ally of Justice Clausolas": 1, "Ally of Justice Core Destroyer": 2, "Ally of Justice Cosmic Gateway": 1,
  "Ally of Justice Cyclone Creator": 2, "Ally of Justice Enemy Catcher": 1, "Ally of Justice Nullfier": 2, "Ally of Justice Omni-Weapon": 1, "Ally of Justice Quarantine": 2,
  "Ally of Justice Reverse Break": 2, "Ally of Justice Searcher": 2, "Ally of Justice Thousand Arms": 2, "Ally of Justice Thunder Armor": 1,
  "Ally of Justice Unknown Crusher": 2, "Ally of Justice Unlimiter": 1,
  "Monster Reborn": 1, "Mystical Space Typhoon": 2, "Pot of Duality": 1, "Dark Hole": 1,
  "Mirror Force": 1, "Bottomless Trap Hole": 2, "Solemn Judgment": 1, "Torrential Tribute": 1, "Dimensional Prison": 2, "Call of the Haunted": 1, "Compulsory Evacuation Device": 1},
 {"Ally of Justice Catastor": 1, "Ally of Justice Decisive Armor": 1, "Ally of Justice Field Marshal": 1, "Ally of Justice Light Gazer": 1},
 "nd_collector", "I collect machines that were built for one job. This deck's job is you.", "Colecciono máquinas construidas para un solo trabajo. El trabajo de este deck eres tú.",
 "Some days I bring the Allies of Justice. LIGHT decks hate me.", "Algunos días traigo a los Ally of Justice. Los decks de LUZ me odian.")

add("flamvell", "5D's", "ff7a3a", "Flamvell Fire", "Fuego Flamvell",
 "The Flamvell, FIRE dragons and fiends from a world of fire, and the Neo Flamvell who burn the other side's Graveyard to ash.",
 "Los Flamvell, dragones y demonios de FUEGO de un mundo de fuego, y los Neo Flamvell que queman el Cementerio del adversario hasta las cenizas.",
 "Flamvell Fire", "", "Ancient Flamvell Deity", "wild",
 "Small FIRE monsters that search each other out and tune into the Ancient Flamvell Deity, while the Neo Flamvell banish whatever the other side wanted back.",
 "Pequeños monstruos de FUEGO que se buscan entre sí y se afinan en Ancient Flamvell Deity, mientras los Neo Flamvell destierran lo que el adversario quería recuperar.",
 {"Flamvell Guard": 2, "Flamvell Poun": 2, "Flamvell Baby": 2, "Flamvell Archer": 2, "Flamvell Firedog": 2, "Flamvell Grunika": 2, "Flamvell Fiend": 1,
  "Flamvell Commando": 1, "Neo Flamvell Garuda": 2, "Neo Flamvell Hedgehog": 2, "Neo Flamvell Origin": 2, "Neo Flamvell Sabre": 2, "Neo Flamvell Shaman": 2,
  "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Pot of Duality": 1, "Dark Hole": 1,
  "Flamvell Counter": 1, "Mirror Force": 1, "Bottomless Trap Hole": 2, "Solemn Judgment": 1, "Torrential Tribute": 1, "Call of the Haunted": 2, "Dimensional Prison": 2,
  "Compulsory Evacuation Device": 1, "Sakuretsu Armor": 1},
 {"Ancient Flamvell Deity": 1}, "nd_mc", "Light the stage! My deck brings its own pyrotechnics.", "¡Enciendan el escenario! Mi deck trae su propia pirotecnia.",
 "Some days I bring the Flamvell. The crowd likes fire.", "Algunos días traigo a los Flamvell. Al público le gusta el fuego.")

add("reptilianne", "5D's", "6aa04a", "Reptilianne Den", "La Guarida Reptilianne",
 "The Reptilianne, serpent-women who turn monsters to stone: they drop the other side's ATK to 0 and then feed on what is left.",
 "Las Reptilianne, mujeres serpiente que convierten a los monstruos en piedra: dejan el ATK del adversario en 0 y después se alimentan de lo que queda.",
 "Reptilianne Den", "", "Reptilianne Vaskii", "wild",
 "Drop their monsters to 0 ATK and they're easy prey. Gorgon and Scylla bring the stone, Vaskii comes out when the field is full of statues.",
 "Deja sus monstruos en 0 ATK y son presas fáciles. Gorgon y Scylla traen la piedra, Vaskii sale cuando el Campo está lleno de estatuas.",
 {"Reptilianne Naga": 2, "Reptilianne Servant": 2, "Reptilianne Viper": 2, "Reptilianne Gardna": 2, "Reptilianne Gorgon": 3, "Reptilianne Scylla": 3,
  "Reptilianne Medusa": 1, "Reptilianne Vaskii": 1, "Sinister Serpent": 1,
  "Reptilianne Spawn": 2, "Reptilianne Rage": 1, "Reptilianne Poison": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 2, "Pot of Duality": 1, "Dark Hole": 1,
  "Mirror Force": 1, "Call of the Haunted": 2, "Bottomless Trap Hole": 2, "Torrential Tribute": 1, "Compulsory Evacuation Device": 1, "Solemn Judgment": 1,
  "Dimensional Prison": 2, "Sakuretsu Armor": 2, "Negate Attack": 1, "Magic Jammer": 1},
 {"Reptilianne Hydra": 1}, "nd_rep", "Our showcase has a new exhibit. Don't look it in the eye.", "Nuestra exposición tiene una pieza nueva. No la mires a los ojos.",
 "Some days I bring the Reptilianne. Statues sell well.", "Algunos días traigo a las Reptilianne. Las estatuas se venden bien.")

add("evol", "ZEXAL", "d86a3a", "Evolution of the Dinosaurs", "La Evolución de los Dinosaurios",
 "The Evoltiles that flip and evolve into Evolsaurs, the Evolzar dragons they become, and the Evo- cards that drive the change.",
 "Los Evoltile que se voltean y evolucionan en Evolsaur, los dragones Evolzar en los que se convierten, y las cartas Evo- que impulsan el cambio.",
 "Evolution of the Dinosaurs", "", "Evolzar Solda", "wild",
 "Flip an Evoltile and it calls an Evolsaur from the Deck. Two of those make an Evolzar, and the Evolzar stop Summons and traps cold.",
 "Voltea un Evoltile y llama a un Evolsaur desde el Deck. Dos de ellos forman un Evolzar, y los Evolzar detienen Invocaciones y Trampas en seco.",
 {"Evoltile Westlo": 2, "Evoltile Odonto": 2, "Evoltile Najasho": 1, "Evoltile Lagosucho": 2, "Evoltile Casinerio": 1, "Evoltile Elginero": 1, "Evoltile Pleuro": 1,
  "Evoltile Gephyro": 1, "Evolsaur Cerato": 2, "Evolsaur Diplo": 2, "Evolsaur Vulcano": 2, "Evolsaur Pelta": 1, "Evolsaur Darwino": 1, "Evolsaur Terias": 1,
  "Evolsaur Elias": 1, "Evo-Force": 2, "Evo-Karma": 1, "Evo-Miracle": 1, "Evo-Diversity": 1, "Evo-Price": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1,
  "Evo-Singularity": 1, "Evo-Branch": 1, "Evo-Instant": 1, "Evolutionary Bridge": 1, "Bottomless Trap Hole": 2, "Solemn Judgment": 1, "Torrential Tribute": 1,
  "Mirror Force": 1, "Call of the Haunted": 1, "Dimensional Prison": 1},
 {"Evolzar Laggia": 1, "Evolzar Dolkka": 1, "Evolzar Solda": 1}, None, "", "", "", "")

add("phantom_beast", "ZEXAL", "5a8ab0", "Mecha Phantom Beasts", "Bestias Fantasma Mecánicas",
 "The Mecha Phantom Beasts, WIND machines that make Tokens to protect themselves and fight together in the air, with Dracossack at their head and the Phantom Beasts of old.",
 "Las Bestias Fantasma Mecánicas, máquinas de VIENTO que crean Fichas para protegerse y luchan juntas en el aire, con Dracossack a la cabeza y las Bestias Fantasma de antaño.",
 "Mecha Phantom Beasts", "", "Mecha Phantom Beast Dracossack", "machines",
 "Every Mecha Phantom Beast makes a Hamstrat Token or two. The Tokens keep them alive, raise their Levels and become Xyz material for Dracossack.",
 "Cada Bestia Fantasma Mecánica crea una o dos Fichas. Las Fichas las mantienen con vida, suben sus Niveles y sirven de material Xyz para Dracossack.",
 {"Mecha Phantom Beast Blackfalcon": 2, "Mecha Phantom Beast Coltwing": 2, "Mecha Phantom Beast Harrliard": 2, "Mecha Phantom Beast Megaraptor": 2,
  "Mecha Phantom Beast Sabre Hawk": 1, "Mecha Phantom Beast Tetherwolf": 2, "Mecha Phantom Beast Aerosguin": 2, "Mecha Phantom Beast Blue Impala": 2,
  "Mecha Phantom Beast Hamstrat": 2, "Mecha Phantom Beast Stealthray": 1, "Mecha Phantom Beast Turtletracer": 1, "Mecha Phantom Beast O-Lion": 2,
  "Mecha Phantom Beast Warbluran": 1, "Mecha Phantom Beast Kalgriffin": 1, "Gazelle the King of Mythical Beasts": 1, "Phantom Beast Wild-Horn": 1,
  "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Pot of Duality": 1,
  "Horn of the Phantom Beast": 2, "Mirror Force": 1, "Bottomless Trap Hole": 2, "Solemn Judgment": 1, "Torrential Tribute": 1, "Call of the Haunted": 2,
  "Dimensional Prison": 2, "Compulsory Evacuation Device": 1},
 {"Mecha Phantom Beast Dracossack": 1, "Mecha Phantom Beast Concoruda": 1}, None, "", "", "", "")

add("noble_knight", "ZEXAL", "c0a050", "Knights of the Round Table", "Caballeros de la Mesa Redonda",
 "The Noble Knights of Artorigus's round table, the Noble Arms they carry, Gwenhwyfar their queen, and the Ignoble Knights who turned against them.",
 "Los Caballeros Nobles de la mesa redonda de Artorigus, las Armas Nobles que portan, Gwenhwyfar su reina, y los Caballeros Innobles que se volvieron contra ellos.",
 "Knights of the Round Table", "", "Artorigus, King of the Noble Knights", "warriors",
 "Each Noble Knight picks up a Noble Arms and passes it on. Two of them at Level 4 call the King to the table.",
 "Cada Caballero Noble recoge un Arma Noble y la pasa al siguiente. Dos de ellos de Nivel 4 llaman al Rey a la mesa.",
 {"Noble Knight Artorigus": 2, "Noble Knight Gawayn": 2, "Noble Knight Medraut": 2, "Noble Knight Drystan": 2, "Noble Knight Peredur": 1, "Noble Knight Borz": 2,
  "Noble Knight Joan": 2, "Noble Knight Gwalchavad": 2, "Noble Knight Eachtar": 1, "Noble Knight Brothers": 1, "Gwenhwyfar, Queen of Noble Arms": 1,
  "Ignoble Knight of Black Laundsallyn": 1,
  "Noble Arms - Caliburn": 2, "Noble Arms - Gallatin": 2, "Noble Arms - Arfeudutyr": 1, "Noble Arms - Excaliburn": 1, "Noble Arms of Destiny": 1,
  "Noble Knights of the Round Table": 1, "Celestial Sword - Eatos": 1, "Reinforcement of the Army": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1,
  "Mirror Force": 1, "Bottomless Trap Hole": 2, "Solemn Judgment": 1, "Torrential Tribute": 1, "Call of the Haunted": 1, "Dimensional Prison": 2,
  "Compulsory Evacuation Device": 1},
 {"Artorigus, King of the Noble Knights": 1, "Sacred Noble Knight of King Artorigus": 1, "Ignoble Knight of High Laundsallyn": 1}, None, "", "", "", "")

add("gears", "ZEXAL", "8a8aa0", "Gears and Rails", "Engranajes y Raíles",
 "The Geargia machines that gear up into Xyz, and the trains of the railway: Level 10 locomotives, their freight cars and the Superdreadnought Rail Cannons.",
 "Las máquinas Geargia que se ensamblan en Xyz, y los trenes del ferrocarril: locomotoras de Nivel 10, sus vagones y los Superdreadnought Rail Cannons.",
 "Gears and Rails", "", "Superdreadnought Rail Cannon Gustav Max", "machines",
 "The Geargia flip and search each other into a Rank 3, and when the big trains roll in, two Level 10s make a Rail Cannon.",
 "Los Geargia se voltean y se buscan entre ellos hasta formar un Rango 3, y cuando llegan los trenes grandes, dos de Nivel 10 forman un Rail Cannon.",
 {"Geargiano": 2, "Geargiano Mk-II": 2, "Geargiano Mk-III": 1, "Geargiarmor": 3, "Geargiattacker": 2, "Geargiarsenal": 2, "Geargiaccelerator": 2, "Geargiauger": 1,
  "Construction Train Signal Red": 1, "Express Train Trolley Olley": 1, "Ruffian Railcar": 1, "Lionhearted Locomotive": 1, "Night Express Knight": 1,
  "Rocket Arrow Express": 1, "Snow Plow Hustle Rustle": 1,
  "Train Connection": 1, "Special Schedule": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Pot of Duality": 1, "Dark Hole": 1,
  "Geargiagear": 2, "Mirror Force": 1, "Bottomless Trap Hole": 2, "Solemn Judgment": 1, "Torrential Tribute": 1, "Call of the Haunted": 1, "Dimensional Prison": 2,
  "Compulsory Evacuation Device": 1, "Sakuretsu Armor": 1},
 {"Geargiagear Gigant XG": 1, "Superdreadnought Rail Cannon Gustav Max": 1, "Number 81: Superdreadnought Rail Cannon Super Dora": 1}, None, "", "", "", "")

add("inzektor", "ZEXAL", "4a8a3a", "Inzektor Hive", "La Colmena Inzektor",
 "The Inzektor, DARK insects that equip to each other and fire their effects when they let go, and the Exa Xyz that rule the hive.",
 "Los Inzektor, insectos de OSCURIDAD que se equipan entre sí y disparan sus efectos cuando se sueltan, y los Xyz Exa que gobiernan la colmena.",
 "Inzektor Hive", "", "Inzektor Exa-Beetle", "forest",
 "Dragonfly and Centipede equip Hornet and Ladybug, then send them off to destroy a card. Every swap is another card gone from the other side.",
 "Dragonfly y Centipede equipan a Hornet y Ladybug, y después los mandan fuera para destruir una carta. Cada cambio es otra carta menos para el adversario.",
 {"Inzektor Dragonfly": 3, "Inzektor Hornet": 3, "Inzektor Centipede": 2, "Inzektor Ladybug": 2, "Inzektor Firefly": 1, "Inzektor Ant": 1, "Inzektor Earwig": 1,
  "Inzektor Hopper": 1, "Inzektor Giga-Mantis": 1, "Inzektor Giga-Weevil": 1, "Inzektor Giga-Cricket": 1,
  "Inzektor Sword - Zektkaliber": 1, "Inzektor Axe - Zektahawk": 1, "Inzektor Crossbow - Zektarrow": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 2,
  "Pot of Duality": 1, "Dark Hole": 1,
  "Inzektor Orb": 1, "Inzektor Gauntlet": 1, "Mirror Force": 1, "Bottomless Trap Hole": 2, "Solemn Judgment": 1, "Torrential Tribute": 1, "Call of the Haunted": 2,
  "Dimensional Prison": 2, "Compulsory Evacuation Device": 1, "Sakuretsu Armor": 2, "Magic Jammer": 1},
 {"Inzektor Exa-Beetle": 1, "Inzektor Exa-Stag": 1}, None, "", "", "", "")

add("sylvan", "ZEXAL", "5aa04a", "Sylvan Grove", "La Arboleda Sylvan",
 "The Sylvan plants of the high mountain: they dig through the top of the Deck, send Plants to the Graveyard and grow into the Sylvan High Protector and High Arbiter.",
 "Las plantas Sylvan de la alta montaña: excavan la parte superior del Deck, mandan Plantas al Cementerio y crecen hasta ser el Alto Protector y el Alto Árbitro Sylvan.",
 "Sylvan Grove", "", "Orea, the Sylvan High Arbiter", "forest",
 "Excavate the top of the Deck: every Plant that gets sent to the Graveyard sets off a Sylvan's effect, and the big trees grow out of what's left.",
 "Excava la parte superior del Deck: cada Planta que se manda al Cementerio activa el efecto de un Sylvan, y los árboles grandes crecen con lo que queda.",
 {"Sylvan Marshalleaf": 2, "Sylvan Komushroomo": 2, "Sylvan Peaskeeper": 2, "Sylvan Cherubsprout": 2, "Sylvan Mikorange": 2,
  "Sylvan Hermitree": 2, "Sylvan Snapdrassinagon": 2, "Sylvan Sagequoia": 1, "Sylvan Lotuswain": 1, "Sylvan Guardioak": 1, "Sylvan Bladefender": 1, "Sylvan Flowerknight": 1,
  "Sylvan Princessprout": 1, "Mount Sylvania": 2, "Sylvan Charity": 2, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Pot of Duality": 1,
  "Sylvan Waterslide": 1, "Sylvan Blessing": 2, "Mirror Force": 1, "Bottomless Trap Hole": 2, "Solemn Judgment": 1, "Torrential Tribute": 1, "Call of the Haunted": 1,
  "Dimensional Prison": 2, "Compulsory Evacuation Device": 1, "Sakuretsu Armor": 1},
 {"Alsei, the Sylvan High Protector": 1, "Orea, the Sylvan High Arbiter": 1}, None, "", "", "", "")

add("hazy", "ZEXAL", "ff6a2a", "Hazy Flame and Fire Kings", "Llama Brumosa y Reyes de Fuego",
 "The Hazy Flame beasts that cannot be targeted and need FIRE Tributes, and the Fire King Avatars that burn themselves to rise again.",
 "Las bestias Llama Brumosa que no pueden ser seleccionadas y necesitan Sacrificios de FUEGO, y los Avatares Rey de Fuego que se queman a sí mismos para volver a alzarse.",
 "Hazy Flame and Fire Kings", "", "Fire King High Avatar Garunix", "wild",
 "Level 6 Hazy Flames nobody can target, and Fire King Avatars that destroy a card of their own to come back from the flames.",
 "Llamas Brumosas de Nivel 6 que nadie puede seleccionar, y Avatares Rey de Fuego que destruyen una carta propia para volver de las llamas.",
 {"Hazy Flame Cerbereus": 2, "Hazy Flame Griffin": 2, "Hazy Flame Hydra": 1, "Hazy Flame Hyppogrif": 2, "Hazy Flame Mantikor": 2, "Hazy Flame Peryton": 2,
  "Hazy Flame Sphynx": 2, "Fire King Avatar Barong": 2, "Fire King Avatar Garunix": 2, "Fire King Avatar Kirin": 2, "Fire King Avatar Yaksha": 2,
  "Fire King High Avatar Garunix": 1, "Hazy Pillar": 2, "Circle of the Fire Kings": 1, "Onslaught of the Fire Kings": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1,
  "Hazy Glory": 1, "Mirror Force": 1, "Bottomless Trap Hole": 2, "Solemn Judgment": 1, "Torrential Tribute": 1, "Call of the Haunted": 2, "Dimensional Prison": 2,
  "Compulsory Evacuation Device": 1, "Sakuretsu Armor": 1},
 {"Hazy Flame Basiltrice": 1}, None, "", "", "", "")

add("hieratic", "ZEXAL", "e0c060", "Hieratic Dynasty", "La Dinastía Hierática",
 "The Hieratic dragons of the sun: they Tribute each other from the hand and the field to call Dragon Normal Monsters, and the Sun Dragon Overlord rises over them all.",
 "Los dragones Hieráticos del sol: se Sacrifican entre sí desde la mano y el Campo para llamar Dragones Normales, y el Señor Dragón del Sol se alza sobre todos ellos.",
 "Hieratic Dynasty", "", "Hieratic Sun Dragon Overlord of Heliopolis", "dragons",
 "Tribute a Hieratic and it pulls a Dragon Normal Monster out of the Deck with its ATK and DEF at 0. Pile them up into Atum and Heliopolis.",
 "Sacrifica un Hierático y saca un Dragón Normal del Deck con su ATK y DEF en 0. Acumúlalos para formar a Atum y Heliopolis.",
 {"Hieratic Dragon of Tefnuit": 2, "Hieratic Dragon of Su": 2, "Hieratic Dragon of Gebeb": 2, "Hieratic Dragon of Nuit": 2, "Hieratic Dragon of Eset": 2,
  "Hieratic Dragon of Nebthet": 2, "Hieratic Dragon of Asar": 1, "Hieratic Dragon of Sutekh": 1, "Hieratic Seal of the Dragon King": 1,
  "Hieratic Seal of the Sun Dragon Overlord": 1, "Alexandrite Dragon": 2,
  "Hieratic Seal of Convocation": 2, "Hieratic Seal of Supremacy": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 2, "Pot of Duality": 1, "Dark Hole": 1,
  "Hieratic Seal From the Ashes": 1, "Hieratic Seal of Banishment": 1, "Hieratic Seal of Reflection": 1, "Mirror Force": 1, "Bottomless Trap Hole": 2,
  "Solemn Judgment": 1, "Torrential Tribute": 1, "Call of the Haunted": 2, "Dimensional Prison": 2, "Compulsory Evacuation Device": 1, "Sakuretsu Armor": 1},
 {"Hieratic Dragon King of Atum": 1, "Hieratic Sun Dragon Overlord of Heliopolis": 1}, None, "", "", "", "")

add("artifact", "ZEXAL", "a0b0d0", "Artifact Armory", "La Armería Artefacto",
 "The Artifacts, LIGHT weapons of the gods that sit face-down as Spells and come out the moment the other side destroys them.",
 "Los Artefactos, armas de LUZ de los dioses que esperan boca abajo como Cartas Mágicas y salen en cuanto el adversario las destruye.",
 "Artifact Armory", "", "Artifact Moralltach", "arcane",
 "Set the Artifacts in the Spell & Trap Zone and wait. When the other duelist destroys one on their turn, it jumps out and strikes back.",
 "Coloca los Artefactos en la Zona de Magia y Trampas y espera. Cuando el otro duelista destruya uno en su turno, salta y contraataca.",
 {"Artifact Moralltach": 2, "Artifact Beagalltach": 2, "Artifact Caduceus": 2, "Artifact Failnaught": 2, "Artifact Labrys": 2, "Artifact Scythe": 1,
  "Artifact Achilleshield": 2, "Artifact Aegis": 1, "Artifact Ignition": 2, "Artifacts Unleashed": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 3,
  "Pot of Duality": 1, "Dark Hole": 1, "Artifact Sanctum": 2, "Mirror Force": 1, "Bottomless Trap Hole": 2, "Solemn Judgment": 2, "Torrential Tribute": 1,
  "Call of the Haunted": 2, "Dimensional Prison": 2, "Compulsory Evacuation Device": 1, "Sakuretsu Armor": 2, "Magic Jammer": 1, "Negate Attack": 1},
 {"Artifact Durendal": 1}, None, "", "", "", "")

add("heraldic", "ZEXAL", "8a5ac0", "Heraldic Beasts", "Bestias Heráldicas",
 "The Heraldic Beasts of the coats of arms, the Heraldry spells that copy and return them, and the Heraldry Numbers they build.",
 "Las Bestias Heráldicas de los escudos de armas, las Mágicas Heraldry que las copian y devuelven, y los Números Heraldry que forman.",
 "Heraldic Beasts", "", "Number 69: Heraldry Crest", "arcane",
 "Level 4 beasts that call each other and turn into Heraldry Numbers. Heraldry Crest takes the other side's effects for its own.",
 "Bestias de Nivel 4 que se llaman entre sí y se convierten en Números Heraldry. Heraldry Crest toma los efectos del adversario como suyos.",
 {"Heraldic Beast Leo": 2, "Heraldic Beast Aberconway": 2, "Heraldic Beast Basilisk": 2, "Heraldic Beast Berners Falcon": 2, "Heraldic Beast Eale": 2,
  "Heraldic Beast Twin-Headed Eagle": 2, "Heraldic Beast Unicorn": 2, "Gene-Warped Warwolf": 2,
  "Heraldry Reborn": 1, "Augmented Heraldry": 1, "Advanced Heraldry Art": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 2, "Pot of Duality": 1, "Dark Hole": 1,
  "Heraldry Change": 1, "Heraldry Record": 1, "Mirror Force": 1, "Bottomless Trap Hole": 2, "Solemn Judgment": 1, "Torrential Tribute": 1, "Call of the Haunted": 2,
  "Dimensional Prison": 2, "Compulsory Evacuation Device": 1, "Sakuretsu Armor": 2, "Magic Jammer": 1, "Negate Attack": 1},
 {"Number 8: Heraldic King Genom-Heritage": 1, "Number 18: Heraldry Patriarch": 1, "Number 69: Heraldry Crest": 1, "Number C69: Heraldry Crest of Horror": 1}, None, "", "", "", "")

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
        over = [k for k, v in d['cards'].items() if v > 3]
        n = sum(d['cards'].values())
        if CHECK or bad or n != 40 or over:
            print(spec['key'], n, 'cards', 'not in game:', bad, 'over 3:', over)
            continue
        make(spec, [x for x in strings if x[0]])
