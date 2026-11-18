import sys
sys.path.insert(0, '/home/claude/work/families')
from mk import make

ONE = sys.argv[1] if len(sys.argv) > 1 else ''

SPECS = []

SPECS.append(({
 "key": "kuriboh", "era": "Duel Monsters", "drop": ["Toon Harpie Lady"],
 "pack": {"name": "Kuriboh and Company", "color": "b07a4a",
  "blurb": "Kuriboh and its many cousins, the Magnet Warriors who snap together into the Magna Warriors, and the Harpie Ladies with their pet dragons."},
 "deck": {"key": "deck_kuriboh", "name": "Kuriboh and Company", "art": "arcane", "cover": "Kuribabylon",
  "blurb": "A swarm of furballs that eat attacks for breakfast. Multiply them, call the five brothers out with Five Star Twilight, and when the field is full, Detonate takes their cards down with them.",
  "cards": {"Kuriboh": 1, "Kuribah": 1, "Kuribee": 1, "Kuriboo": 1, "Kuribeh": 1, "Kuribabylon": 1, "Winged Kuriboh": 2, "Multiplying Kuriboh!": 1, "Clear Kuriboh": 1,
   "Ankuriboh": 1, "Junkuriboh": 1, "Kuribohrn": 1, "Rainbow Kuriboh": 1, "Sphere Kuriboh": 1, "Relinkuriboh": 1, "Kuribandit": 1, "Skilled Brown Magician": 1,
   "Winged Kuriboh LV10": 1, "Winged Kuriboh LV9": 1, "Magikuriboh": 1,
   "Five Star Twilight": 2, "The Flute of Summoning Kuriboh": 2, "Multiply": 2, "Detonate": 1, "Generation Next": 1, "Monster Reborn": 1, "Swords of Revealing Light": 1,
   "Scapegoat": 1, "Mystical Space Typhoon": 1, "Card Destruction": 1,
   "Magic Cylinder": 1, "Mirror Force": 1, "Waboku": 1, "Negate Attack": 1, "Call of the Haunted": 1, "Torrential Tribute": 1},
  "extra": {}},
 "worlds": ["domino"], "stage": 0,
 "npc": {"id": "dome_fan", "new_duel": {"difficulty": 1, "intro": "Kuri kuri! Okay, I'll stop. Duel!"},
  "lines": ["I've been in line for the Duel Dome since five this morning.", "They say the finals arena floats. FLOATS.", "My deck is all Kuribohs. Laugh now. You won't get a single hit through."]},
}, [
 ("Kuriboh and Company", "Kuriboh y Compañía"),
 ("Kuriboh and its many cousins, the Magnet Warriors who snap together into the Magna Warriors, and the Harpie Ladies with their pet dragons.", "Kuriboh y sus muchos primos, los Magnet Warrior que se juntan en los Magna Warrior, y las Harpie Lady con sus dragones mascota."),
 ("A swarm of furballs that eat attacks for breakfast. Multiply them, call the five brothers out with Five Star Twilight, and when the field is full, Detonate takes their cards down with them.", "Un enjambre de bolas de pelo que se comen los ataques. Multiplícalos, llama a los cinco hermanos con Five Star Twilight y, cuando el Campo esté lleno, Detonate se lleva sus cartas con ellos."),
 ("Kuri kuri! Okay, I'll stop. Duel!", "¡Kuri kuri! Vale, ya paro. ¡A duelar!"),
 ("My deck is all Kuribohs. Laugh now. You won't get a single hit through.", "Mi deck es todo Kuribohs. Ríete ahora. No vas a pasar ni un golpe."),
]))

SPECS.append(({
 "key": "cloudian", "era": "GX",
 "pack": {"name": "Fog, Fangs and Fossils", "color": "c8d8e8",
  "blurb": "The Cloudians, who spread fog counters and burst on contact; the Venom snakes and their swamp; and the Fossil fusions dug up from both Graveyards."},
 "deck": {"key": "deck_cloudian", "name": "Rolling Fog", "art": "gale", "cover": "Cloudian - Eye of the Typhoon",
  "blurb": "Smoke Ball and Sheep Cloud fill the field with fog, Turbulence and Cirrostratus spend it to blow cards away, and every Cloudian that bursts comes back with Raging Cloudian.",
  "cards": {"Cloudian - Smoke Ball": 3, "Cloudian - Sheep Cloud": 2, "Cloudian - Poison Cloud": 2, "Cloudian - Ghost Fog": 1, "Cloudian - Acid Cloud": 2, "Cloudian - Altus": 2,
   "Cloudian - Cirrostratus": 2, "Cloudian - Turbulence": 2, "Cloudian - Storm Dragon": 2, "Cloudian - Nimbusman": 1, "Cloudian - Eye of the Typhoon": 1,
   "Summon Cloud": 2, "Cloudian Squall": 1, "Fog Control": 2, "Diamond-Dust Cyclone": 1, "Cloudian Aerosol": 2, "Lucky Cloud": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1,
   "Raging Cloudian": 2, "Rain Storm": 1, "Natural Disaster": 1, "Updraft": 1, "Waboku": 1, "Mirror Force": 1, "Call of the Haunted": 1, "Bottomless Trap Hole": 1},
  "extra": {"Number 39: Utopia": 1, "Castel, the Skyblaster Musketeer": 1, "Abyss Dweller": 1, "Daigusto Emeral": 1}},
 "worlds": ["academy"], "stage": 2,
 "npc": {"id": "captain", "new_duel": {"difficulty": 2, "intro": "Fog's rolling in. Hope you brought a compass."},
  "lines": ["The ferry runs to Domino City whenever you're ready.", "Step onto the pier when you want to head back.", "Out at sea the fog rolls in thick. I learned to duel with it. Want to see?"]},
}, [
 ("Fog, Fangs and Fossils", "Niebla, Colmillos y Fósiles"),
 ("The Cloudians, who spread fog counters and burst on contact; the Venom snakes and their swamp; and the Fossil fusions dug up from both Graveyards.", "Los Cloudian, que reparten contadores de niebla y estallan al contacto; las serpientes Venom y su pantano; y las fusiones Fossil desenterradas de ambos Cementerios."),
 ("Rolling Fog", "Niebla Rodante"),
 ("Smoke Ball and Sheep Cloud fill the field with fog, Turbulence and Cirrostratus spend it to blow cards away, and every Cloudian that bursts comes back with Raging Cloudian.", "Smoke Ball y Sheep Cloud llenan el Campo de niebla, Turbulence y Cirrostratus la gastan para barrer cartas, y cada Cloudian que estalla vuelve con Raging Cloudian."),
 ("Fog's rolling in. Hope you brought a compass.", "Llega la niebla. Espero que hayas traído brújula."),
 ("Out at sea the fog rolls in thick. I learned to duel with it. Want to see?", "En alta mar la niebla llega espesa. Aprendí a duelar con ella. ¿Quieres verlo?"),
]))

SPECS.append(({
 "key": "naturia", "era": "5D's",
 "pack": {"name": "Voice of the Forest", "color": "6ac46a",
  "blurb": "The Naturia: small plants and bugs that punish every card your opponent plays, and the Synchro beasts Barkion, Landoise and Naturia Beast that negate Spells, Traps and effects outright."},
 "deck": {"key": "deck_naturia", "name": "Voice of the Forest", "art": "forest", "cover": "Naturia Beast",
  "blurb": "Every time they act, the forest answers: Sunflower and Vein negate, Antjaw and Camellia grow new plants, and Naturia Beast and Barkion lock down Spells and Traps for good.",
  "cards": {"Naturia Mole Cricket": 1, "Naturia Camellia": 2, "Naturia Marron": 1, "Naturia Cliff": 2, "Naturia Pumpkin": 2, "Naturia Rosewhip": 1, "Naturia Sunflower": 2,
   "Naturia Vein": 1, "Naturia Antjaw": 1, "Naturia Beans": 1, "Naturia Mantis": 1, "Naturia Horneedle": 1, "Naturia Ladybug": 1, "Naturia Strawberry": 1, "Naturia Hydrangea": 1, "Naturia Stag Beetle": 1,
   "Naturia Forest": 1, "Naturia Blessing": 1, "Barkion's Bark": 1, "Landoise's Luminous Moss": 1, "Leodrake's Mane": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Dark Hole": 1,
   "Exterio's Fang": 2, "Naturia Sacred Tree": 2, "Solemn Judgment": 1, "Mirror Force": 1, "Bottomless Trap Hole": 1, "Call of the Haunted": 1, "Compulsory Evacuation Device": 1,
   "Torrential Tribute": 1, "Dimensional Prison": 1, "Fiendish Chain": 1},
  "extra": {"Naturia Barkion": 2, "Naturia Beast": 2, "Naturia Landoise": 1, "Naturia Leodrake": 1, "Naturia Exterio": 1, "Naturia Gaiastrio": 1, "Stardust Dragon": 1, "Formula Synchron": 1}},
 "worlds": ["satellite", "newdomino"], "stage": 3,
 "npc": {"id": "nd_cafe", "old_deck": "alexis", "intro": "Fresh from the garden. Espresso speed!",
  "swap": [["Help me test it?", "I grow the beans myself, and the deck too. Help me test it?"]]},
}, [
 ("Voice of the Forest", "La Voz del Bosque"),
 ("The Naturia: small plants and bugs that punish every card your opponent plays, and the Synchro beasts Barkion, Landoise and Naturia Beast that negate Spells, Traps and effects outright.", "Los Naturia: pequeñas plantas e insectos que castigan cada carta que juega tu adversario, y las bestias de Sincronía Barkion, Landoise y Naturia Beast, que niegan Mágicas, Trampas y efectos sin más."),
 ("Every time they act, the forest answers: Sunflower and Vein negate, Antjaw and Camellia grow new plants, and Naturia Beast and Barkion lock down Spells and Traps for good.", "Cada vez que actúan, el bosque responde: Sunflower y Vein niegan, Antjaw y Camellia hacen crecer plantas nuevas, y Naturia Beast y Barkion bloquean las Mágicas y Trampas para siempre."),
 ("Fresh from the garden. Espresso speed!", "Recién salido del jardín. ¡Velocidad espresso!"),
 ("I grow the beans myself, and the deck too. Help me test it?", "Cultivo el café yo misma, y el deck también. ¿Me ayudas a probarlo?"),
]))

SPECS.append(({
 "key": "tg", "era": "5D's",
 "pack": {"name": "Tech Genus", "color": "6ab0ff",
  "blurb": "The T.G. monsters: machines and beasts that fetch a new T.G. every time one is destroyed, and the T.G. Synchros, up to Halberd Cannon and Glaive Blaster, that stop Summons cold."},
 "deck": {"key": "deck_tg", "name": "Tech Genus", "art": "machines", "cover": "T.G. Halberd Cannon",
  "blurb": "Lose a T.G. and you get another. Striker and Warwolf jump in for free, Cyber Magician turns your hand into Synchro material, and Hyper Librarian draws a card for every Synchro after.",
  "cards": {"T.G. Striker": 2, "T.G. Warwolf": 2, "T.G. Rush Rhino": 2, "T.G. Catapult Dragon": 1, "T.G. Cyber Magician": 2, "T.G. Booster Raptor": 2, "T.G. Jet Falcon": 1,
   "T.G. Screw Serpent": 1, "T.G. Rocket Salamander": 1, "T.G. Tank Grub": 1, "T.G. Metal Skeleton": 1, "T.G. Drill Fish": 1, "T.G. Gear Zombie": 1,
   "T.G. Limiter Removal": 2, "T.G. All Clear": 1, "TGX300": 1, "TGX1-HL": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Dark Hole": 1,
   "Sonic Stun": 2, "T.G. Close": 1, "TG1-EM1": 1, "TGX3-DX2": 1, "TG-SX1": 1, "Mirror Force": 1, "Bottomless Trap Hole": 1, "Call of the Haunted": 1, "Solemn Judgment": 1,
   "Torrential Tribute": 1, "Compulsory Evacuation Device": 1, "Dimensional Prison": 1, "Fiendish Chain": 1},
  "extra": {"T.G. Hyper Librarian": 1, "T.G. Wonder Magician": 1, "T.G. Power Gladiator": 1, "T.G. Mighty Striker": 1, "T.G. Over Dragonar": 1, "T.G. Star Guardian": 1,
   "T.G. Recipro Dragonfly": 1, "T.G. Blade Blaster": 1, "T.G. Halberd Cannon": 1, "T.G. Glaive Blaster": 1, "Shooting Star Dragon T.G. EX": 1, "Stardust Dragon": 1}},
 "worlds": ["satellite", "newdomino"], "stage": 3,
 "npc": {"id": "nd_rider", "new_duel": {"difficulty": 2, "intro": "Engine's warm. Let's see what yours can do."},
  "lines": ["The gate behind me puts you straight onto the highway ring. Satellite is one exit down.", "There's a race flag at the start line. First across after a full lap takes the pot.", "I build my deck like I build engines. Break a part, a better one drops in."]},
}, [
 ("Tech Genus", "Tech Genus"),
 ("The T.G. monsters: machines and beasts that fetch a new T.G. every time one is destroyed, and the T.G. Synchros, up to Halberd Cannon and Glaive Blaster, that stop Summons cold.", "Los monstruos T.G.: máquinas y bestias que traen un T.G. nuevo cada vez que uno es destruido, y los Monstruos de Sincronía T.G., hasta Halberd Cannon y Glaive Blaster, que frenan las Invocaciones en seco."),
 ("Lose a T.G. and you get another. Striker and Warwolf jump in for free, Cyber Magician turns your hand into Synchro material, and Hyper Librarian draws a card for every Synchro after.", "Pierdes un T.G. y llega otro. Striker y Warwolf entran gratis, Cyber Magician convierte tu mano en material de Sincronía, y Hyper Librarian roba una carta por cada Sincronía que venga después."),
 ("Engine's warm. Let's see what yours can do.", "El motor está caliente. Veamos qué puede hacer el tuyo."),
 ("I build my deck like I build engines. Break a part, a better one drops in.", "Armo mi deck como armo motores. Se rompe una pieza y entra una mejor."),
]))

SPECS.append(({
 "key": "fire_fist", "era": "ZEXAL",
 "pack": {"name": "Brotherhood of the Fire Fist", "color": "ff8a2a",
  "blurb": "The Fire Fist: FIRE Beast-Warriors who Set Fire Formation Spells and Traps straight from the Deck, then burn them for power. Tiger King, Cardinal and Kirin lead the brotherhood."},
 "deck": {"key": "deck_fire_fist", "name": "Brotherhood of the Fire Fist", "art": "wild", "cover": "Brotherhood of the Fire Fist - Tiger King",
  "blurb": "Bear and Rooster set a Formation, send it away to break a card, and set the next one. Every Formation makes the brothers stronger, and two of them make a Tiger King.",
  "cards": {"Brotherhood of the Fire Fist - Bear": 2, "Brotherhood of the Fire Fist - Rooster": 2, "Brotherhood of the Fire Fist - Gorilla": 1, "Brotherhood of the Fire Fist - Raven": 1,
   "Brotherhood of the Fire Fist - Spirit": 1, "Brotherhood of the Fire Fist - Leopard": 1, "Brotherhood of the Fire Fist - Ram": 1, "Brotherhood of the Fire Fist - Wolf": 1,
   "Brotherhood of the Fire Fist - Coyote": 1, "Brotherhood of the Fire Fist - Panda": 1, "Brotherhood of the Fire Fist - Elephant": 1, "Brotherhood of the Fire Fist - Dragon": 1,
   "Brotherhood of the Fire Fist - Snake": 1, "Brotherhood of the Fire Fist - Buffalo": 1, "Brotherhood of the Fire Fist - Caribou": 1, "Brotherhood of the Fire Fist - Hawk": 1,
   "Brotherhood of the Fire Fist - Boar": 1, "Brotherhood of the Fire Fist - Swallow": 1,
   "Fire Formation - Tenki": 3, "Fire Formation - Gyokkou": 1, "Fire Formation - Tensu": 1, "Fire Formation - Yoko": 1, "Fire Formation - Ingen": 1, "Fire Fortress atop Liang Peak": 1,
   "Monster Reborn": 1, "Mystical Space Typhoon": 1,
   "Fire Formation - Kaiyo": 1, "Fire Formation - Tenken": 1, "Fire Formation - Tensen": 2, "Ultimate Fire Formation - Sinto": 1, "Ultimate Fire Formation - Seito": 1, "Mirror Force": 1, "Bottomless Trap Hole": 1,
   "Call of the Haunted": 1, "Solemn Judgment": 1},
  "extra": {"Brotherhood of the Fire Fist - Tiger King": 2, "Brotherhood of the Fire Fist - Cardinal": 1, "Brotherhood of the Fire Fist - Lion Emperor": 1, "Brotherhood of the Fire Fist - Swan": 1,
   "Brotherhood of the Fire Fist - Kirin": 1, "Brotherhood of the Fire Fist - Horse Prince": 1, "Number 39: Utopia": 1, "Diamond Dire Wolf": 1, "Castel, the Skyblaster Musketeer": 1}},
 "worlds": ["heartland"], "stage": 4,
 "npc": {"id": "hl_boy", "rotate": True, "intro": "Fists up. The Brotherhood is in town!",
  "lines_add": ["And on the hot days I fight with the Fire Fist. Three decks, one me."]},
}, [
 ("Brotherhood of the Fire Fist", "La Hermandad del Puño de Fuego"),
 ("The Fire Fist: FIRE Beast-Warriors who Set Fire Formation Spells and Traps straight from the Deck, then burn them for power. Tiger King, Cardinal and Kirin lead the brotherhood.", "Los Fire Fist: Bestias-Guerrero de FUEGO que Colocan Mágicas y Trampas Fire Formation directamente del Deck y luego las queman para ganar poder. Tiger King, Cardinal y Kirin lideran la hermandad."),
 ("Bear and Rooster set a Formation, send it away to break a card, and set the next one. Every Formation makes the brothers stronger, and two of them make a Tiger King.", "Bear y Rooster Colocan una Formación, la mandan al Cementerio para romper una carta y Colocan la siguiente. Cada Formación hace más fuertes a los hermanos, y dos de ellos forman un Tiger King."),
 ("Fists up. The Brotherhood is in town!", "¡Puños arriba! ¡La Hermandad ha llegado!"),
 ("And on the hot days I fight with the Fire Fist. Three decks, one me.", "Y los días de calor peleo con el Puño de Fuego. Tres decks, un solo yo."),
]))

for spec, strings in SPECS:
    if ONE and spec['key'] != ONE:
        continue
    make(spec, strings)
