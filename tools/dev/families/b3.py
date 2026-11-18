import sys
sys.path.insert(0, '/home/claude/work/families')
from mk import make

ONE = sys.argv[1] if len(sys.argv) > 1 else ''

SPECS = []

SPECS.append(({
 "key": "exodia", "era": "Duel Monsters",
 "pack": {"name": "The Forbidden One", "color": "e0b040",
  "blurb": "Exodia's five pieces and every card that calls on them, plus the Batterymen and the Gadgets: small Thunder and Machine monsters that power each other up."},
 "deck": {"key": "deck_exodia", "name": "The Forbidden One", "art": "beyond", "cover": "Exodia the Forbidden One",
  "blurb": "Stall, draw, and dig. Waboku and Swords buy the turns, Mystic Tomato and Break the Seal fetch the pieces, and when all five are in your hand the duel just ends.",
  "cards": {"Exodia the Forbidden One": 1, "Right Arm of the Forbidden One": 1, "Left Arm of the Forbidden One": 1, "Right Leg of the Forbidden One": 1, "Left Leg of the Forbidden One": 1,
   "The Legendary Exodia Incarnate": 1, "Exodius the Ultimate Forbidden Lord": 1, "Exodia Necross": 1, "Mystic Tomato": 2, "Sangan": 1, "Battle Fader": 1,
   "Contract with Exodia": 1, "Millennium Ankh": 1, "Obliterate!!! Blaze": 1, "Upstart Goblin": 2, "Card Destruction": 1, "Swords of Revealing Light": 1, "Scapegoat": 1,
   "Gold Sarcophagus": 1, "Foolish Burial": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Book of Moon": 1, "Dark Hole": 1,
   "Break the Seal": 3, "Obliterate!!!": 2, "Exxod Fires of Rage": 1, "Waboku": 2, "Negate Attack": 2, "Magic Cylinder": 1, "Mirror Force": 1, "Sakuretsu Armor": 1, "Fiendish Chain": 1},
  "extra": {"The Unstoppable Exodia Incarnate": 1}},
 "worlds": ["domino"], "stage": 0,
 "npc": {"id": "kid", "old_deck": "joey", "intro": "If I draw all five, I win. That's the rule!",
  "swap": [["I just built my first deck! Wanna duel? Please?", "I just built my first deck! It has all five pieces of Exodia in it. Wanna duel? Please?"]]},
}, [
 ("The Forbidden One", "El Prohibido"),
 ("Exodia's five pieces and every card that calls on them, plus the Batterymen and the Gadgets: small Thunder and Machine monsters that power each other up.", "Las cinco piezas de Exodia y todas las cartas que las invocan, además de los Batteryman y los Gadget: pequeños monstruos de Tipo Trueno y Máquina que se dan energía unos a otros."),
 ("Stall, draw, and dig. Waboku and Swords buy the turns, Mystic Tomato and Break the Seal fetch the pieces, and when all five are in your hand the duel just ends.", "Aguanta, roba y busca. Waboku y Swords compran turnos, Mystic Tomato y Break the Seal traen las piezas, y cuando las cinco están en tu mano el duelo simplemente se acaba."),
 ("If I draw all five, I win. That's the rule!", "Si robo las cinco, gano. ¡Es la regla!"),
 ("I just built my first deck! It has all five pieces of Exodia in it. Wanna duel? Please?", "¡Acabo de armar mi primer deck! Tiene las cinco piezas de Exodia. ¿Duelamos? ¿Por favor?"),
]))

SPECS.append(({
 "key": "koaki_meiru", "era": "GX",
 "pack": {"name": "Iron Core", "color": "c8742c",
  "blurb": "The Koa'ki Meiru: strong monsters that fall apart at the End Phase unless you feed them an Iron Core or show the right monster. In return they shut down LIGHT and DARK, Spells and Traps."},
 "deck": {"key": "deck_koaki_meiru", "name": "Iron Core", "art": "arsenal", "cover": "Koa'ki Meiru Maximus",
  "blurb": "Big bodies for cheap, as long as you keep the cores coming. Urnight and Boulder fill the field, the Rock guards negate whatever they throw, and Maximus breaks a card every turn.",
  "cards": {"Koa'ki Meiru Urnight": 2, "Koa'ki Meiru Boulder": 2, "Koa'ki Meiru Supplier": 1, "Koa'ki Meiru Guardian": 2, "Koa'ki Meiru Wall": 1, "Koa'ki Meiru Sandman": 1,
   "Koa'ki Meiru Drago": 1, "Koa'ki Meiru Beetle": 1, "Koa'ki Meiru Crusader": 1, "Koa'ki Meiru Ice": 1, "Koa'ki Meiru Prototype": 1, "Koa'ki Meiru Maximus": 2, "Koa'ki Meiru Valafar": 1,
   "Iron Core of Koa'ki Meiru": 3, "Core Transport Unit": 1, "Diamond Core of Koa'ki Meiru": 2, "Koa'ki Meiru Initialize!": 1, "Core Overclock": 1, "Iron Core Specimen Lab": 1,
   "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Dark Hole": 1,
   "Iron Core Luster": 2, "Automatic Laser": 1, "Nega-Ton Corepanel": 1, "Core Reinforcement": 1, "Reckoned Power": 1, "Mirror Force": 1, "Bottomless Trap Hole": 1,
   "Solemn Judgment": 1, "Call of the Haunted": 1, "Compulsory Evacuation Device": 1},
  "extra": {"Number 39: Utopia": 1, "Diamond Dire Wolf": 1, "Castel, the Skyblaster Musketeer": 1, "Abyss Dweller": 1, "Starliege Paladynamo": 1, "Daigusto Emeral": 1}},
 "worlds": ["academy"], "stage": 2,
 "npc": {"id": "student_b", "old_deck": "joey", "intro": "Lunch-table rules! Iron cores and all.",
  "swap": [["Want to test that record?", "My monsters fall apart unless I feed them iron cores. Want to test that record?"]]},
}, [
 ("Iron Core", "El Núcleo de Hierro"),
 ("The Koa'ki Meiru: strong monsters that fall apart at the End Phase unless you feed them an Iron Core or show the right monster. In return they shut down LIGHT and DARK, Spells and Traps.", "Los Koa'ki Meiru: monstruos fuertes que se desmoronan en la End Phase a menos que les des un Núcleo de Hierro o muestres el monstruo correcto. A cambio, anulan a la LUZ y la OSCURIDAD, las Mágicas y las Trampas."),
 ("Big bodies for cheap, as long as you keep the cores coming. Urnight and Boulder fill the field, the Rock guards negate whatever they throw, and Maximus breaks a card every turn.", "Monstruos grandes por poco, mientras sigan llegando núcleos. Urnight y Boulder llenan el Campo, los guardianes de Roca niegan lo que te lancen, y Maximus rompe una carta cada turno."),
 ("Lunch-table rules! Iron cores and all.", "¡Reglas de la mesa del almuerzo! Con núcleos de hierro y todo."),
 ("My monsters fall apart unless I feed them iron cores. Want to test that record?", "Mis monstruos se desmoronan si no les doy núcleos de hierro. ¿Quieres poner a prueba ese récord?"),
]))

SPECS.append(({
 "key": "arcana_force", "era": "GX",
 "pack": {"name": "Turn of the Arcana", "color": "f0e0a0",
  "blurb": "The Arcana Force: Fairies that toss a coin when they are Summoned. Heads, a blessing; tails, a curse. Light Barrier lets you skip the coin and pick."},
 "deck": {"key": "deck_arcana_force", "name": "Turn of the Arcana", "art": "arcane", "cover": "Arcana Force EX - The Light Ruler",
  "blurb": "Every Summon is a coin toss until Light Barrier hits the field. After that you choose heads every time, and the three Rulers take over.",
  "cards": {"Arcana Force 0 - The Fool": 1, "Arcana Force I - The Magician": 2, "Arcana Force III - The Empress": 2, "Arcana Force IV - The Emperor": 2, "Arcana Force V - The Hierophant": 2,
   "Arcana Force VI - The Lovers": 2, "Arcana Force VII - The Chariot": 2, "Arcana Force XII - The Hangman": 1, "Arcana Force XIV - Temperance": 1, "Arcana Force XIX - The Sun": 1,
   "Arcana Force XV - The Fiend": 1, "Arcana Force XVIII - The Moon": 1, "Arcana Force XXI - The World": 1, "Arcana Force EX - The Light Ruler": 1, "Arcana Force EX - The Dark Ruler": 1,
   "Light Barrier": 3, "Light Force": 1, "Arcana Reading": 2, "Arcana Spread": 2, "Terraforming": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Double Summon": 1,
   "Reversal of Fate": 2, "Arcana Call": 1, "Mirror Force": 1, "Call of the Haunted": 1, "Bottomless Trap Hole": 1, "Solemn Judgment": 1},
  "extra": {"Arcana Force EX - The Chaos Ruler": 1, "Number 39: Utopia": 1, "Castel, the Skyblaster Musketeer": 1, "Diamond Dire Wolf": 1}},
 "worlds": ["academy"], "stage": 2,
 "npc": {"id": "ac_ghost", "rotate": True, "intro": "The cards told me you would come.",
  "lines_add": ["Some nights I don't pick my deck. I flip a coin and the Arcana pick it for me."]},
}, [
 ("Turn of the Arcana", "El Giro de los Arcanos"),
 ("The Arcana Force: Fairies that toss a coin when they are Summoned. Heads, a blessing; tails, a curse. Light Barrier lets you skip the coin and pick.", "Los Arcana Force: Hadas que lanzan una moneda al ser Invocadas. Cara, una bendición; cruz, una maldición. Light Barrier te deja saltarte la moneda y elegir."),
 ("Every Summon is a coin toss until Light Barrier hits the field. After that you choose heads every time, and the three Rulers take over.", "Cada Invocación es un lanzamiento de moneda hasta que Light Barrier llega al Campo. Desde entonces eliges cara siempre, y los tres Rulers toman el control."),
 ("The cards told me you would come.", "Las cartas me dijeron que vendrías."),
 ("Some nights I don't pick my deck. I flip a coin and the Arcana pick it for me.", "Algunas noches no elijo mi deck. Lanzo una moneda y los Arcanos lo eligen por mí."),
]))

SPECS.append(({
 "key": "ice_barrier", "era": "5D's",
 "pack": {"name": "Guardians of the Ice Barrier", "color": "8fd8ff",
  "blurb": "The Ice Barrier: WATER monsters who lock the field while another of them stands guard, and the Synchro dragons Brionac, Gungnir and Trishula they become."},
 "deck": {"key": "deck_ice_barrier", "name": "Guardians of the Ice Barrier", "art": "tide", "cover": "Trishula, Dragon of the Ice Barrier",
  "blurb": "Two Ice Barrier monsters on the field and the locks start: no big attackers, no Spells, no changing positions. Then a Tuner joins in and Trishula takes a card from everywhere.",
  "cards": {"General Wayne of the Ice Barrier": 1, "Georgius, Swordman of the Ice Barrier": 2, "Speaker for the Ice Barriers": 2, "Revealer of the Ice Barrier": 1, "Hexa Spirit of the Ice Barrier": 1,
   "Mirror Mage of the Ice Barrier": 1, "Zuijin of the Ice Barrier": 1, "Prior of the Ice Barrier": 1, "Dewdark of the Ice Barrier": 1, "Cryomancer of the Ice Barrier": 1,
   "Defender of the Ice Barrier": 1, "Strategist of the Ice Barrier": 2, "Shock Troops of the Ice Barrier": 1, "Dance Princess of the Ice Barrier": 1, "Judge of the Ice Barrier": 1,
   "General Gantala of the Ice Barrier": 1, "General Grunard of the Ice Barrier": 1,
   "Medallion of the Ice Barrier": 3, "Winds Over the Ice Barrier": 1, "Freezing Chains of the Ice Barrier": 1, "Magic Triangle of the Ice Barrier": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Dark Hole": 1,
   "Ice Barrier": 2, "Frozen Domain of the Ice Barrier": 1, "Terror of Trishula": 1, "Mirror Force": 1, "Bottomless Trap Hole": 1, "Solemn Judgment": 1, "Call of the Haunted": 1,
   "Compulsory Evacuation Device": 1, "Dimensional Prison": 1, "Torrential Tribute": 1},
  "extra": {"Brionac, Dragon of the Ice Barrier": 1, "Gungnir, Dragon of the Ice Barrier": 1, "Trishula, Dragon of the Ice Barrier": 1, "Trishula, Zero Dragon of the Ice Barrier": 1,
   "Dewloren, Tiger King of the Ice Barrier": 1, "Ekhajar, Descendant Dragon of the Ice Barrier": 1, "Lancea, Ancestral Dragon of the Ice Mountain": 1, "Stardust Dragon": 1, "Formula Synchron": 1, "Abyss Dweller": 1}},
 "worlds": ["satellite", "newdomino"], "stage": 3,
 "npc": {"id": "night_newdomino", "old_deck": "jack", "intro": "Cold out tonight. It gets colder."},
}, [
 ("Guardians of the Ice Barrier", "Los Guardianes de la Barrera de Hielo"),
 ("The Ice Barrier: WATER monsters who lock the field while another of them stands guard, and the Synchro dragons Brionac, Gungnir and Trishula they become.", "La Barrera de Hielo: monstruos de AGUA que bloquean el Campo mientras otro de ellos monta guardia, y los dragones de Sincronía Brionac, Gungnir y Trishula en que se convierten."),
 ("Two Ice Barrier monsters on the field and the locks start: no big attackers, no Spells, no changing positions. Then a Tuner joins in and Trishula takes a card from everywhere.", "Dos monstruos Ice Barrier en el Campo y empiezan los bloqueos: nada de atacantes grandes, nada de Mágicas, nada de cambiar posiciones. Luego se une un Cantante y Trishula se lleva una carta de todas partes."),
 ("Cold out tonight. It gets colder.", "Hace frío esta noche. Y hará más."),
]))

SPECS.append(({
 "key": "ninja", "era": "ZEXAL",
 "pack": {"name": "Way of the Ninja", "color": "4a5a7a",
  "blurb": "The Ninjas and their Ninjitsu Arts: monsters that hide face-down, swap places and strike from the shadows, and the Dragon Ninjas that need a Ninja and an Art to act."},
 "deck": {"key": "deck_ninja", "name": "Way of the Ninja", "art": "shadow", "cover": "Twilight Ninja Getsuga, the Shogun",
  "blurb": "Hanzo finds the Arts, Yellow Ninja and Kagero bring friends face-down, and Dancing Leaves trades one ninja for another whenever you like. They never see what's under the cover.",
  "cards": {"Ninja Grandmaster Hanzo": 2, "Yellow Ninja": 2, "Kagero the Cannon Ninja": 2, "Twilight Ninja Shingetsu": 1, "Upstart Golden Ninja": 1, "Green Ninja": 1, "Mitsu the Insect Ninja": 1,
   "Baku the Beast Ninja": 1, "Tobari the Sky Ninja": 1, "Senior Silver Ninja": 1, "Jioh the Gravity Ninja": 1, "Twilight Ninja Getsuga, the Shogun": 1, "Blue Dragon Ninja": 1,
   "Red Dragon Ninja": 1, "Twilight Ninja Nichirin, the Chunin": 1, "Black Dragon Ninja": 1, "White Ninja": 1, "Ninja Grandmaster Sasuke": 1,
   "Hidden Village of Ninjitsu Arts": 1, "Ninjitsu Art Notebook": 1, "Ninjitsu Art Notebook of Mystery": 1, "Ninjitsu Art Tool - Iron Digger": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Book of Moon": 1,
   "Ninjitsu Art of Dancing Leaves": 2, "Ninjitsu Art of Duplication": 1, "Armor Ninjitsu Art of Freezing": 1, "Ninjitsu Art of Shadow Sealing": 1, "Ninjitsu Art of Decoy": 1, "Ninjitsu Art of Transformation": 1,
   "Mirror Force": 1, "Bottomless Trap Hole": 1, "Call of the Haunted": 1, "Solemn Judgment": 1, "Fiendish Chain": 1},
  "extra": {"Meizen the Battle Ninja": 1, "Yaguramaru the Armor Ninja": 1, "Blade Armor Ninja": 1, "Number 12: Crimson Shadow Armor Ninja": 1, "Number 2: Ninja Shadow Mosquito": 1,
   "Number 39: Utopia": 1, "Castel, the Skyblaster Musketeer": 1, "Diamond Dire Wolf": 1}},
 "worlds": ["heartland"], "stage": 4,
 "npc": {"id": "hl_jeweler", "rotate": True, "intro": "You never saw me coming. That's the point.",
  "lines_add": ["On quiet days I close the shop early and practice a different art. You won't see it coming."]},
}, [
 ("Way of the Ninja", "El Camino del Ninja"),
 ("The Ninjas and their Ninjitsu Arts: monsters that hide face-down, swap places and strike from the shadows, and the Dragon Ninjas that need a Ninja and an Art to act.", "Los Ninja y sus Ninjitsu Arts: monstruos que se esconden boca abajo, cambian de lugar y atacan desde las sombras, y los Dragon Ninja, que necesitan un Ninja y un Arte para actuar."),
 ("Hanzo finds the Arts, Yellow Ninja and Kagero bring friends face-down, and Dancing Leaves trades one ninja for another whenever you like. They never see what's under the cover.", "Hanzo encuentra las Artes, Yellow Ninja y Kagero traen amigos boca abajo, y Dancing Leaves cambia un ninja por otro cuando quieras. Nunca ven lo que hay debajo."),
 ("You never saw me coming. That's the point.", "Nunca me viste venir. De eso se trata."),
 ("On quiet days I close the shop early and practice a different art. You won't see it coming.", "Los días tranquilos cierro la tienda temprano y practico otro arte. No lo verás venir."),
]))

for spec, strings in SPECS:
    if ONE and spec['key'] != ONE:
        continue
    make(spec, strings)
