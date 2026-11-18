import sys
sys.path.insert(0, '/home/claude/work/families')
from mk import make

ONE = sys.argv[1] if len(sys.argv) > 1 else ''

SPECS = []

SPECS.append(({
 "key": "dark_magician", "era": "Duel Monsters",
 "drop": ["Master of Chaos", "Toon Dark Magician Girl", "Toon Dark Magician", "Illusion of Chaos", "Magician of Chaos", "Chaos Form", "Magikuriboh", "Multiplying Kuriboh!"],
 "pack": {"name": "School of Dark Magic", "color": "7a4ad8",
  "blurb": "Dark Magician, Dark Magician Girl and everything built around them: the spells that only they can cast, the knights they fuse into, and the dragon Timaeus who rides with them."},
 "deck": {"key": "deck_dark_magician", "name": "School of Dark Magic", "art": "spellbook", "cover": "Dark Magician",
  "blurb": "Rod and Robe bring the master out early, Magician Navigation drops two magicians at once, and Dark Magic Attack clears the board. Then teacher and student fuse into a Dragon Knight.",
  "cards": {"Dark Magician": 3, "Dark Magician Girl": 1, "Magician's Rod": 2, "Magician's Robe": 2, "Apprentice Illusion Magician": 1, "Magician of Dark Illusion": 1,
   "Palladium Oracle Mahad": 1, "Palladium Oracle Mana": 1, "Skilled Dark Magician": 1, "Timaeus the United Dragon": 1, "Chronicle Sorceress": 1, "Magicians' Souls": 1,
   "Dark Magic Attack": 1, "Secrets of Dark Magic": 1, "Soul Servant": 1, "Dark Magical Circle": 1, "Illusion Magic": 1, "Dark Magic Inheritance": 1, "Thousand Knives": 1,
   "Dark Burning Attack": 1, "Magician's Salvation": 1, "The Eye of Timaeus": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Polymerization": 1, "Dark Magic Twin Burst": 1,
   "Bond Between Teacher and Student": 1,
   "Eternal Soul": 1, "Magician Navigation": 2, "Magicians' Combination": 1, "Destined Rivals": 1, "Dark Magic Talisman": 1, "Mirror Force": 1, "Bottomless Trap Hole": 1, "Call of the Haunted": 1},
  "extra": {"The Dark Magicians": 1, "Dark Magician the Dragon Knight": 1, "Dark Magician Girl the Dragon Knight": 1, "Dark Cavalry": 1, "Amulet Dragon": 1,
   "Timaeus the United Magical Dragon": 1, "Dark Magician of Destruction": 1, "Dark Paladin": 1}},
 "worlds": ["domino"], "stage": 0,
 "npc": {"id": "tourist", "new_duel": {"difficulty": 2, "intro": "Let me show you a real magic trick!"},
  "lines": ["You can see Duel Academy's volcano from the end of the pier on a clear day!", "Somebody said a duelist stands out there every night, all alone.", "I brought my deck on vacation. It's all Dark Magicians. Want a souvenir duel?"]},
}, [
 ("School of Dark Magic", "La Escuela de Magia Oscura"),
 ("Dark Magician, Dark Magician Girl and everything built around them: the spells that only they can cast, the knights they fuse into, and the dragon Timaeus who rides with them.", "Dark Magician, Dark Magician Girl y todo lo que gira a su alrededor: los hechizos que sólo ellos pueden lanzar, los caballeros en que se fusionan y el dragón Timaeus que cabalga con ellos."),
 ("Rod and Robe bring the master out early, Magician Navigation drops two magicians at once, and Dark Magic Attack clears the board. Then teacher and student fuse into a Dragon Knight.", "Rod y Robe sacan pronto al maestro, Magician Navigation trae dos magos a la vez y Dark Magic Attack limpia el tablero. Después, maestro y aprendiz se fusionan en un Caballero Dragón."),
 ("Let me show you a real magic trick!", "¡Déjame enseñarte un truco de magia de verdad!"),
 ("I brought my deck on vacation. It's all Dark Magicians. Want a souvenir duel?", "Me traje el deck de vacaciones. Es todo Dark Magicians. ¿Un duelo de recuerdo?"),
]))

SPECS.append(({
 "key": "blue_eyes", "era": "Duel Monsters",
 "drop": ["Blue-Eyes Toon Ultimate Dragon", "Dragon Master Magia", "Blue-Eyes Toon Dragon", "Blue-Eyes Chaos Dragon", "Blue-Eyes Chaos MAX Dragon", "Chaos Form",
  "Chronicle Sorceress", "Chronicle Magician", "Strength in Unity", "Destined Rivals"],
 "pack": {"name": "Legend of the White Dragon", "color": "6ab4ff",
  "blurb": "Blue-Eyes White Dragon and every card that serves it: the maidens and sages with eyes of blue, the white stones, and the Ultimate, Twin Burst and Spirit dragons it becomes."},
 "deck": {"key": "deck_blue_eyes", "name": "Legend of the White Dragon", "art": "dragons", "cover": "Blue-Eyes White Dragon",
  "blurb": "The sages and stones find the dragons, the maiden calls one out the moment she's targeted, and three white dragons on the field means only one thing: Ultimate.",
  "cards": {"Blue-Eyes White Dragon": 3, "Blue-Eyes Alternative White Dragon": 2, "Sage with Eyes of Blue": 3, "The White Stone of Ancients": 1, "The White Stone of Legend": 2,
   "Maiden with Eyes of Blue": 1, "Kaibaman": 1, "Dragon Spirit of White": 1, "Blue-Eyes Abyss Dragon": 1, "Blue-Eyes Jet Dragon": 1, "Dictator of D.": 1, "Deep-Eyes White Dragon": 1,
   "Blue-Eyes Solid Dragon": 1,
   "Roar of the Blue-Eyed Dragons": 1, "Wishes for Eyes of Blue": 1, "Bingo Machine, Go!!!": 1, "Burst Stream of Destruction": 1, "Polymerization": 1, "Ultimate Fusion": 1,
   "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Vision with Eyes of Blue": 1, "Majesty with Eyes of Blue": 1,
   "True Light": 2, "Majesty of the White Dragons": 1, "The Ultimate Creature of Destruction": 1, "Mirror Force": 1, "Bottomless Trap Hole": 1, "Call of the Haunted": 1,
   "Compulsory Evacuation Device": 1, "Solemn Judgment": 1, "Torrential Tribute": 1, "Dimensional Prison": 1},
  "extra": {"Blue-Eyes Ultimate Dragon": 1, "Blue-Eyes Alternative Ultimate Dragon": 1, "Neo Blue-Eyes Ultimate Dragon": 1, "Blue-Eyes Twin Burst Dragon": 1, "Blue-Eyes Tyrant Dragon": 1,
   "Blue-Eyes Spirit Dragon": 1, "Blue-Eyes Ultimate Spirit Dragon": 1}},
 "worlds": ["domino"], "stage": 0,
 "npc": {"id": "official", "new_duel": {"difficulty": 3, "intro": "Registration check. Let's see that deck in action."},
  "lines": ["Battle City finals registration is right here on the plaza.", "Mr. Kaiba watches every duel in the city from up there. Every single one.", "Between registrations I duel. White dragons only. Don't ask where I got three."]},
}, [
 ("Legend of the White Dragon", "La Leyenda del Dragón Blanco"),
 ("Blue-Eyes White Dragon and every card that serves it: the maidens and sages with eyes of blue, the white stones, and the Ultimate, Twin Burst and Spirit dragons it becomes.", "Blue-Eyes White Dragon y todas las cartas que lo sirven: las doncellas y sabios de ojos azules, las piedras blancas, y los dragones Ultimate, Twin Burst y Spirit en que se convierte."),
 ("The sages and stones find the dragons, the maiden calls one out the moment she's targeted, and three white dragons on the field means only one thing: Ultimate.", "Los sabios y las piedras encuentran a los dragones, la doncella llama a uno en cuanto la seleccionan, y tres dragones blancos en el Campo sólo significan una cosa: Ultimate."),
 ("Registration check. Let's see that deck in action.", "Control de inscripción. Veamos ese deck en acción."),
 ("Between registrations I duel. White dragons only. Don't ask where I got three.", "Entre inscripciones, duelo. Sólo dragones blancos. No preguntes de dónde saqué tres."),
]))

SPECS.append(({
 "key": "red_eyes", "era": "Duel Monsters",
 "drop": ["Archfiend Black Skull Dragon", "Black Skull Dragon", "Red-Eyes Archfiend of Lightning", "Red-Eyes Toon Dragon", "Red-Eyes Dark Dragoon"],
 "pack": {"name": "Eyes of Red Potential", "color": "d83a3a",
  "blurb": "Red-Eyes Black Dragon and its whole brood: the chicks and black stones that hatch it, the metal, flare and darkness dragons it grows into, and Red-Eyes Fusion to tie it all together."},
 "deck": {"key": "deck_red_eyes", "name": "Eyes of Red Potential", "art": "dragons", "cover": "Red-Eyes Black Dragon",
  "blurb": "Not the strongest dragon, but the one with the most potential. The chick and the black stone bring it out, Red-Eyes Fusion skips the wait, and every Red-Eyes that falls burns on the way down.",
  "cards": {"Red-Eyes Black Dragon": 3, "Red-Eyes Wyvern": 1, "Black Dragon's Chick": 2, "Red-Eyes Retro Dragon": 1, "Red-Eyes Black Meteor Dragon": 1, "Red-Eyes Alternative Black Dragon": 1,
   "Red-Eyes Soul": 1, "Red-Eyes Darkness Metal Dragon": 1, "Red-Eyes Black Flare Dragon": 1, "Gearfried the Red-Eyes Iron Knight": 1, "Meteor Dragon Red-Eyes Impact": 1,
   "Red-Eyes Darkness Dragon": 1, "The Black Stone of Legend": 2, "Red-Eyes Baby Dragon": 1, "Black Metal Dragon": 1, "Lord of the Red": 1,
   "Red-Eyes Fusion": 2, "Red-Eyes Insight": 1, "Cards of the Red Stone": 1, "Inferno Fire Blast": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Dark Hole": 1, "Foolish Burial": 1,
   "Red-Eyes Transmigration": 1,
   "Return of the Red-Eyes": 1, "Red-Eyes Spirit": 1, "Red-Eyes Burn": 1, "Mirror Force": 1, "Call of the Haunted": 1, "Bottomless Trap Hole": 1, "Solemn Judgment": 1,
   "Torrential Tribute": 1, "Red-Eyes Fang with Chain": 1, "Compulsory Evacuation Device": 1},
  "extra": {"Red-Eyes Slash Dragon": 1, "Meteor Black Comet Dragon": 1, "Meteor Black Dragon": 1, "Red-Eyes Flare Metal Dragon": 1, "Red-Eyes Dark Dragoon": 1, "Black Skull Dragon": 1}},
 "worlds": ["domino"], "stage": 0,
 "npc": {"id": "night_domino", "old_deck": "kaiba", "intro": "The night shift starts now."},
}, [
 ("Eyes of Red Potential", "El Potencial de los Ojos Rojos"),
 ("Red-Eyes Black Dragon and its whole brood: the chicks and black stones that hatch it, the metal, flare and darkness dragons it grows into, and Red-Eyes Fusion to tie it all together.", "Red-Eyes Black Dragon y toda su camada: las crías y piedras negras que lo hacen nacer, los dragones de metal, llamas y oscuridad en que se convierte, y Red-Eyes Fusion para unirlo todo."),
 ("Not the strongest dragon, but the one with the most potential. The chick and the black stone bring it out, Red-Eyes Fusion skips the wait, and every Red-Eyes that falls burns on the way down.", "No es el dragón más fuerte, pero sí el de más potencial. La cría y la piedra negra lo traen, Red-Eyes Fusion se salta la espera, y cada Red-Eyes que cae quema al caer."),
]))

SPECS.append(({
 "key": "armed_dragon", "era": "GX",
 "drop": ["Winged Kuriboh LV10", "Winged Kuriboh Sabatiel LV10", "Winged Kuriboh LV6", "Winged Kuriboh LV9", "Magnet Circle LV2"],
 "pack": {"name": "Climbing Levels", "color": "8a9aa8",
  "blurb": "The Armed Dragons and every LV monster: they start small, level up by sending themselves away, and come back stronger. Armed Dragon LV10, Horus LV8 and Silent Magician LV8 wait at the top."},
 "deck": {"key": "deck_armed_dragon", "name": "Armed Dragon Ascent", "art": "dragons", "cover": "Armed Dragon LV10",
  "blurb": "LV3 becomes LV5, LV5 becomes LV7, and Level Up! skips the waiting. By the time LV10 lands, a single discard wipes their whole board.",
  "cards": {"Armed Dragon LV3": 3, "Armed Dragon LV5": 2, "Armed Dragon LV7": 2, "Armed Dragon LV10": 1, "Armed Dragon Thunder LV3": 1, "Armed Dragon Thunder LV5": 1,
   "Armed Dragon Thunder LV7": 1, "Armed Dragon Thunder LV10": 1, "Fist Armed Dragon": 1, "Drill Armed Dragon": 1, "Armed Dragon, the Armored Dragon": 1, "Dark Armed Dragon": 1,
   "Knight Armed Dragon, the Armored Knight Dragon": 1, "Hardened Armed Dragon": 1, "Pile Armed Dragon": 1, "Metaphys Armed Dragon": 1,
   "Level Up!": 2, "Armed Dragon Blitz": 1, "Armed Dragon Flash": 1, "Armed Dragon Lightning": 1, "Level Modulation": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Dark Hole": 1,
   "Foolish Burial": 1,
   "Armed Dragon Thunderbolt": 1, "Mirror Force": 1, "Bottomless Trap Hole": 1, "Call of the Haunted": 1, "Solemn Judgment": 1, "Torrential Tribute": 1,
   "Compulsory Evacuation Device": 1, "Sakuretsu Armor": 1, "Dimensional Prison": 1, "Fiendish Chain": 1},
  "extra": {"Number 39: Utopia": 1, "Diamond Dire Wolf": 1, "Castel, the Skyblaster Musketeer": 1, "Abyss Dweller": 1}},
 "worlds": ["academy"], "stage": 2,
 "npc": {"id": "dawn_academy", "old_deck": "chazz", "intro": "Before the bell, then.",
  "swap": [["Duel before breakfast and your hands remember it all day.", "Duel before breakfast and your hands remember it all day. My dragons level up the same way."]]},
}, [
 ("Climbing Levels", "Subiendo de Nivel"),
 ("The Armed Dragons and every LV monster: they start small, level up by sending themselves away, and come back stronger. Armed Dragon LV10, Horus LV8 and Silent Magician LV8 wait at the top.", "Los Armed Dragon y todos los monstruos LV: empiezan pequeños, suben de nivel mandándose al Cementerio y vuelven más fuertes. Armed Dragon LV10, Horus LV8 y Silent Magician LV8 esperan en la cima."),
 ("Armed Dragon Ascent", "El Ascenso del Armed Dragon"),
 ("LV3 becomes LV5, LV5 becomes LV7, and Level Up! skips the waiting. By the time LV10 lands, a single discard wipes their whole board.", "LV3 se convierte en LV5, LV5 en LV7, y Level Up! se salta la espera. Cuando llega LV10, un solo descarte barre todo su tablero."),
 ("Duel before breakfast and your hands remember it all day. My dragons level up the same way.", "Duela antes del desayuno y tus manos lo recuerdan todo el día. Mis dragones suben de nivel igual."),
]))

SPECS.append(({
 "key": "nordic", "era": "5D's",
 "pack": {"name": "Twilight of the Gods", "color": "8ab4d8",
  "blurb": "The Nordics: Alfar, Beasts and Ascendants who Summon each other in pairs, the Relics they carry, and the three Aesir gods Odin, Thor and Loki who come back every time they fall."},
 "deck": {"key": "deck_nordic", "name": "Twilight of the Gods", "art": "arcane", "cover": "Odin, Father of the Aesir",
  "blurb": "Dverg and Ljosalf bring a second Nordic every turn, the Beasts and Ascendants tune them up, and an Aesir hits the field. Destroy one and it comes back at the End Phase.",
  "cards": {"Dverg of the Nordic Alfar": 2, "Ljosalf of the Nordic Alfar": 1, "Svartalf of the Nordic Alfar": 2, "Mara of the Nordic Alfar": 1, "Mimir of the Nordic Ascendant": 1,
   "Vanadis of the Nordic Ascendant": 1, "Nordic Beast Gullinbursti": 1, "Tanngnjostr of the Nordic Beasts": 2, "Tanngrisnir of the Nordic Beasts": 1, "Guldfaxe of the Nordic Beasts": 1,
   "Garmr of the Nordic Beasts": 1, "Nordic Smith Ivaldi": 2, "Tyr of the Nordic Champions": 1,
   "Nordic Relic Hlidskjalf": 1, "Nordic Relic Draupnir": 1, "The Nordic Lights": 1, "March Towards Ragnarok": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Dark Hole": 1,
   "Gleipnir, the Fetters of Fenrir": 2, "Nordic Relic Megingjord": 1, "Nordic Relic Gungnir": 1, "Nordic Relic Svalinn": 1, "Nordic Relic Laevateinn": 1, "Divine Relic Mjollnir": 1,
   "Solemn Authority": 1, "Mirror Force": 1, "Bottomless Trap Hole": 1, "Call of the Haunted": 1, "Solemn Judgment": 1, "Torrential Tribute": 1, "Compulsory Evacuation Device": 1,
   "Dimensional Prison": 1, "Fiendish Chain": 1},
  "extra": {"Odin, Father of the Aesir": 1, "Thor, Lord of the Aesir": 1, "Loki, Lord of the Aesir": 1, "Stardust Dragon": 1, "Formula Synchron": 1}},
 "worlds": ["satellite", "newdomino"], "stage": 3,
 "npc": {"id": "nd_mc", "new_duel": {"difficulty": 2, "intro": "Laaadies and gentlemen! A surprise match!"},
  "lines": ["Laaadies and gentlemen! The Fortune Cup qualifiers are open to every duelist in New Domino!", "The King himself is waiting by the doors. Beat him and the crowd will never forget your name.", "Between announcements I warm up the crowd with a duel. Gods of the north, live on stage!"]},
}, [
 ("Twilight of the Gods", "El Ocaso de los Dioses"),
 ("The Nordics: Alfar, Beasts and Ascendants who Summon each other in pairs, the Relics they carry, and the three Aesir gods Odin, Thor and Loki who come back every time they fall.", "Los Nordic: Alfar, Bestias y Ascendientes que se Invocan unos a otros en parejas, las Reliquias que llevan, y los tres dioses Aesir, Odin, Thor y Loki, que vuelven cada vez que caen."),
 ("Dverg and Ljosalf bring a second Nordic every turn, the Beasts and Ascendants tune them up, and an Aesir hits the field. Destroy one and it comes back at the End Phase.", "Dverg y Ljosalf traen un segundo Nordic cada turno, las Bestias y los Ascendientes los sincronizan, y un Aesir llega al Campo. Destruye uno y vuelve en la End Phase."),
 ("Laaadies and gentlemen! A surprise match!", "¡Damaaas y caballeros! ¡Un duelo sorpresa!"),
 ("Between announcements I warm up the crowd with a duel. Gods of the north, live on stage!", "Entre anuncios caliento al público con un duelo. ¡Dioses del norte, en vivo en el escenario!"),
]))

SPECS.append(({
 "key": "bujin", "era": "ZEXAL",
 "pack": {"name": "Divine Warriors of the Sun", "color": "e0c070",
  "blurb": "The Bujin: Beast-Warrior gods and their Bujingi beast servants, who throw themselves from the hand to double an attack or stop one cold. The Bujintei Xyz lead them, one of each."},
 "deck": {"key": "deck_bujin", "name": "Divine Warriors of the Sun", "art": "warriors", "cover": "Bujintei Susanowo",
  "blurb": "Yamato searches every End Phase, Crane doubles its ATK from the hand, and Turtle and Hare make it untouchable. Two of them become Susanowo, who strikes every monster they have.",
  "cards": {"Bujin Yamato": 2, "Bujin Mikazuchi": 2, "Bujin Arasuda": 1, "Bujin Hirume": 1, "Bujin Torifune": 1, "Bujin Mahitotsu": 1, "Bujingi Crane": 2, "Bujingi Turtle": 2,
   "Bujingi Quilin": 2, "Bujingi Hare": 2, "Bujingi Centipede": 1, "Bujingi Peacock": 1, "Bujingi Wolf": 1, "Bujingi Pavo": 1,
   "Bujincarnation": 1, "Bujincandescence": 1, "Bujinunity": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Dark Hole": 1, "Book of Moon": 1,
   "Bujin Regalia - The Sword": 2, "Bujin Regalia - The Jewel": 1, "Bujinfidel": 1, "Bujincident": 1, "Mirror Force": 1, "Bottomless Trap Hole": 1, "Call of the Haunted": 1,
   "Solemn Judgment": 1, "Torrential Tribute": 1, "Compulsory Evacuation Device": 1, "Dimensional Prison": 1, "Fiendish Chain": 1},
  "extra": {"Bujintei Susanowo": 2, "Bujintei Kagutsuchi": 1, "Bujintei Tsukuyomi": 1, "Bujinki Amaterasu": 1, "Number 39: Utopia": 1, "Diamond Dire Wolf": 1,
   "Castel, the Skyblaster Musketeer": 1, "Abyss Dweller": 1}},
 "worlds": ["heartland"], "stage": 4,
 "npc": {"id": "hl_girl", "rotate": True, "intro": "The stars are out. So are the gods.",
  "lines_add": ["When the stars hide, I call on older names. The Bujin, the warrior gods."]},
}, [
 ("Divine Warriors of the Sun", "Los Guerreros Divinos del Sol"),
 ("The Bujin: Beast-Warrior gods and their Bujingi beast servants, who throw themselves from the hand to double an attack or stop one cold. The Bujintei Xyz lead them, one of each.", "Los Bujin: dioses Bestia-Guerrero y sus bestias sirvientes Bujingi, que se lanzan desde la mano para duplicar un ataque o frenarlo en seco. Los Xyz Bujintei los lideran, uno de cada uno."),
 ("Yamato searches every End Phase, Crane doubles its ATK from the hand, and Turtle and Hare make it untouchable. Two of them become Susanowo, who strikes every monster they have.", "Yamato busca en cada End Phase, Crane duplica su ATK desde la mano, y Turtle y Hare lo hacen intocable. Dos de ellos se convierten en Susanowo, que golpea a todos sus monstruos."),
 ("The stars are out. So are the gods.", "Han salido las estrellas. Y también los dioses."),
 ("When the stars hide, I call on older names. The Bujin, the warrior gods.", "Cuando las estrellas se esconden, invoco nombres más antiguos. Los Bujin, los dioses guerreros."),
]))

for spec, strings in SPECS:
    if ONE and spec['key'] != ONE:
        continue
    make(spec, strings)
