import sys
sys.path.insert(0, '/home/claude/work/families')
from mk import make

ONE = sys.argv[1] if len(sys.argv) > 1 else ''

SPECS = []

SPECS.append(({
 "key": "guardian", "era": "Duel Monsters",
 "pack": {"name": "Gate of the Guardians", "color": "7a9cff",
  "blurb": "Sanga, Kazejin and Suijin, the three who stand at the gate, and the Gate Guardians they become. With them, the weapon Guardians who can only take the field once their own weapon is on it."},
 "deck": {"key": "deck_guardian", "name": "Gate of the Guardians", "art": "arsenal", "cover": "Gate Guardian",
  "blurb": "Thunder, wind and water hold the line until the three of them fuse into a Gate Guardian. Dark Element calls up the darkest one, and Guardian Eatos swings her sword between them.",
  "cards": {"Sanga of the Thunder": 3, "Kazejin": 3, "Suijin": 3, "Labyrinth Heavy Tank": 2, "Gate Guardian": 1, "Dark Guardian": 1,
   "Guardian Eatos": 2, "Guardian Dreadscythe": 1, "Guardian Grarl": 1, "Guardian Ceal": 1,
   "Labyrinth Wall Shadow": 2, "Dark Element": 2, "Double Attack! Wind and Thunder!!": 2, "Riryoku Guardian": 1, "Celestial Sword - Eatos": 1,
   "Reaper Scythe - Dreadscythe": 1, "Gravity Axe - Grarl": 1, "Shooting Star Bow - Ceal": 1, "Monster Reborn": 1, "Dark Hole": 1, "Upstart Goblin": 2, "Mystical Space Typhoon": 1,
   "Prey of the Jirai Gumo": 2, "Call of the Haunted": 2, "Mirror Force": 1, "Bottomless Trap Hole": 1},
  "extra": {"Gate Guardian of Thunder and Wind": 1, "Gate Guardian of Water and Thunder": 1, "Gate Guardian of Wind and Water": 1, "Gate Guardians Combined": 1}},
 "worlds": ["domino"], "stage": 0,
 "npc": {"id": "guard", "new_duel": {"difficulty": 2, "intro": "Nobody gets past the gate. Not today."},
  "lines": ["KaibaCorp Tower. The lobby is open to duelists during the tournament.", "The elevators are not. And if you want past me, you go through three of my guardians first."]},
}, [
 ("Gate of the Guardians", "La Puerta de los Guardianes"),
 ("Sanga, Kazejin and Suijin, the three who stand at the gate, and the Gate Guardians they become. With them, the weapon Guardians who can only take the field once their own weapon is on it.", "Sanga, Kazejin y Suijin, los tres que custodian la puerta, y los Gate Guardian en que se convierten. Con ellos, los Guardianes de las armas, que sólo salen al Campo cuando su propia arma ya está en él."),
 ("Thunder, wind and water hold the line until the three of them fuse into a Gate Guardian. Dark Element calls up the darkest one, and Guardian Eatos swings her sword between them.", "Trueno, viento y agua aguantan la línea hasta que los tres se fusionan en un Gate Guardian. Dark Element llama al más oscuro, y Guardian Eatos blande su espada entre ellos."),
 ("Nobody gets past the gate. Not today.", "Nadie pasa la puerta. Hoy no."),
 ("The elevators are not. And if you want past me, you go through three of my guardians first.", "Los ascensores no. Y si quieres pasar, primero tendrás que vencer a mis tres guardianes."),
]))

SPECS.append(({
 "key": "alien", "era": "GX",
 "pack": {"name": "Invasion of the A-Counters", "color": "8be04f",
  "blurb": "The Aliens: they mark your monsters with A-Counters, weaken every monster that carries one, and then take them over. Brainwashing Beam, Mass Hypnosis and the \"A\" Cell spells do the marking."},
 "deck": {"key": "deck_alien", "name": "Invasion of the A-Counters", "art": "beyond", "cover": "Alien Overlord",
  "blurb": "Every monster an Alien touches gets an A-Counter, and every A-Counter makes it weaker against them. Mark enough and Mass Hypnosis takes three of them home.",
  "cards": {"Alien Shocktrooper": 2, "Alien Warrior": 2, "Alien Hunter": 2, "Alien Telepath": 1, "Alien Grey": 2, "Alien Dog": 2, "Alien Stealthbuster": 2,
   "I.A.S. -Invasive Alien Species-": 1, "Alien Overlord": 1, "Alien Mother": 1, "Alien Ammonite": 2, "Alien Kid": 1, "Cosmic Horror Gangi'el": 1,
   "\"A\" Cell Recombination Device": 2, "\"A\" Cell Breeding Device": 2, "Corruption Cell \"A\"": 2, "Mysterious Triangle": 1, "Code A Ancient Ruins": 1,
   "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Otherworld - The \"A\" Zone": 1,
   "Brainwashing Beam": 2, "Mass Hypnosis": 1, "Cell Explosion Virus": 1, "Interdimensional Warp": 1, "Detonator Circle \"A\"": 1, "Planet Pollutant Virus": 1, "Mirror Force": 1, "Crop Circles": 1},
  "extra": {"Cosmic Fortress Gol'gar": 2, "Number 39: Utopia": 1, "Diamond Dire Wolf": 1, "Castel, the Skyblaster Musketeer": 1, "Abyss Dweller": 1, "Starliege Paladynamo": 1}},
 "worlds": ["academy"], "stage": 2,
 "npc": {"id": "ac_beach", "rotate": True, "intro": "Did you see the lights over the water last night? Those were mine.",
  "lines_add": ["Some nights there are lights over the water. I deal a different deck when they show up."]},
}, [
 ("Invasion of the A-Counters", "La Invasión de los Contadores A"),
 ("The Aliens: they mark your monsters with A-Counters, weaken every monster that carries one, and then take them over. Brainwashing Beam, Mass Hypnosis and the \"A\" Cell spells do the marking.", "Los Alien: marcan tus monstruos con Contadores A, debilitan a todo monstruo que lleve uno y después se los quedan. Brainwashing Beam, Mass Hypnosis y las Mágicas \"A\" Cell se encargan de marcar."),
 ("Every monster an Alien touches gets an A-Counter, and every A-Counter makes it weaker against them. Mark enough and Mass Hypnosis takes three of them home.", "Cada monstruo que toca un Alien recibe un Contador A, y cada Contador A lo hace más débil contra ellos. Marca suficientes y Mass Hypnosis se lleva tres a casa."),
 ("Did you see the lights over the water last night? Those were mine.", "¿Viste las luces sobre el agua anoche? Eran mías."),
 ("Some nights there are lights over the water. I deal a different deck when they show up.", "Algunas noches hay luces sobre el agua. Cuando aparecen, juego con otro deck."),
]))

SPECS.append(({
 "key": "volcanic", "era": "GX",
 "pack": {"name": "Volcano Island", "color": "ff6a2a",
  "blurb": "The Volcanics: Pyro monsters that burn, blow up and come back, and the Blaze Accelerator cannons that fire them. Volcanic Emperor and Volcanic Doomfire burn the whole field down."},
 "deck": {"key": "deck_volcanic", "name": "Volcano Island", "art": "wild", "cover": "Volcanic Emperor",
  "blurb": "Load the Blaze Accelerator, fire small Volcanics at their monsters, and every one that hits the Graveyard burns. When three Pyros are gone, Volcanic Emperor rises.",
  "cards": {"Volcanic Scattershot": 3, "Volcanic Shell": 2, "Volcanic Rimfire": 2, "Volcanic Trooper": 3, "Volcanic Rocket": 2, "Volcanic Slicer": 1, "Volcanic Blaster": 1,
   "Volcanic Counter": 1, "Volcanic Rat": 1, "Volcanic Hammerer": 1, "Volcanic Queen": 1, "Volcanic Emperor": 2, "Volcanic Doomfire": 1,
   "Blaze Accelerator": 2, "Tri-Blaze Accelerator": 1, "Volcanic Blaze Accelerator": 2, "Fire Ejection": 2, "Foolish Burial": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1,
   "Volcanic Emission": 2, "Volcanic Inferno": 2, "Blaze Accelerator Reload": 2, "Volcanic Recharge": 1, "Mirror Force": 1, "Bottomless Trap Hole": 1},
  "extra": {"Number 61: Volcasaurus": 1, "Number 30: Acid Golem of Destruction": 1, "Lavalval Chain": 1}},
 "worlds": ["academy"], "stage": 2,
 "npc": {"id": "student_a", "new_duel": {"difficulty": 2, "intro": "The volcano is glowing again. So am I."},
  "lines": ["Yellow dorm has the best curry on the island. It's not close.", "Did you see the volcano glowing last night? I built my deck out of it. Want to feel the heat?"]},
}, [
 ("Volcano Island", "La Isla del Volcán"),
 ("The Volcanics: Pyro monsters that burn, blow up and come back, and the Blaze Accelerator cannons that fire them. Volcanic Emperor and Volcanic Doomfire burn the whole field down.", "Los Volcanic: monstruos de Tipo Piro que queman, explotan y vuelven, y los cañones Blaze Accelerator que los disparan. Volcanic Emperor y Volcanic Doomfire arrasan el Campo entero."),
 ("Load the Blaze Accelerator, fire small Volcanics at their monsters, and every one that hits the Graveyard burns. When three Pyros are gone, Volcanic Emperor rises.", "Carga el Blaze Accelerator, dispara pequeños Volcanic a sus monstruos, y cada uno que cae al Cementerio quema. Cuando se han ido tres Piro, se alza Volcanic Emperor."),
 ("The volcano is glowing again. So am I.", "El volcán vuelve a brillar. Y yo también."),
 ("Did you see the volcano glowing last night? I built my deck out of it. Want to feel the heat?", "¿Viste el volcán brillar anoche? Armé mi deck con él. ¿Quieres sentir el calor?"),
]))

SPECS.append(({
 "key": "x_saber", "era": "5D's",
 "pack": {"name": "Sabers of the Sword Saints", "color": "c9b06a",
  "blurb": "The X-Sabers and XX-Sabers: EARTH swordsmen who call each other from the Deck and the Graveyard, and the Gottoms and Souza Synchros who lead them. Saber Slash cuts as many cards as they have blades."},
 "deck": {"key": "deck_x_saber", "name": "Sabers of the Sword Saints", "art": "warriors", "cover": "XX-Saber Gottoms",
  "blurb": "Boggart Knight and Pellina bring two swordsmen at once, Faultroll calls back the fallen, and the Synchro lords take over: Hyunlei clears the back row, Gottoms empties their hand.",
  "cards": {"XX-Saber Boggart Knight": 2, "X-Saber Pellina": 2, "X-Saber Bruno": 2, "XX-Saber Emmersblade": 2, "XX-Saber Darksoul": 1, "X-Saber Airbellum": 2,
   "X-Saber Galahad": 1, "XX-Saber Garsem": 1, "XX-Saber Fulhelmknight": 1, "XX-Saber Faultroll": 2, "XX-Saber Gardestrike": 1, "Commander Gottoms, Swordmaster": 1,
   "X-Saber Palomuro": 1, "XX-Saber Ragigura": 1, "X-Saber Uruz": 1, "X-Saber Anu Piranha": 1,
   "Saber Vault": 1, "Saber Slash": 1, "Saber Combination": 1, "Reinforcement of the Army": 2, "Gottoms' Second Call": 1, "Sword of Sparkles": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Dark Hole": 1,
   "Saber Reflection": 2, "Gottoms' Emergency Call": 2, "Saber Hole": 2, "At One With the Sword": 1, "Mirror Force": 1},
  "extra": {"X-Saber Gottoms": 1, "XX-Saber Gottoms": 1, "XX-Saber Hyunlei": 2, "X-Saber Souza": 1, "Commander Souza, Swordmaster": 1, "X-Saber Wayne": 1, "X-Saber Urbellum": 1,
   "M-X-Saber Invoker": 1, "Stardust Dragon": 1, "Scrap Dragon": 1, "Colossal Fighter": 1, "Number 39: Utopia": 1, "Castel, the Skyblaster Musketeer": 1}},
 "worlds": ["satellite", "newdomino"], "stage": 3,
 "npc": {"id": "nd_chief", "new_duel": {"difficulty": 2, "intro": "Draw your blade. Security does not lose."},
  "lines": ["The highway is the only road between here and Satellite. We watch every meter of it.", "My squad duels with swords. Every one of them brings a friend. Think you can keep up?"]},
}, [
 ("Sabers of the Sword Saints", "Los Sables de los Santos de la Espada"),
 ("The X-Sabers and XX-Sabers: EARTH swordsmen who call each other from the Deck and the Graveyard, and the Gottoms and Souza Synchros who lead them. Saber Slash cuts as many cards as they have blades.", "Los X-Saber y XX-Saber: espadachines de TIERRA que se llaman unos a otros desde el Deck y el Cementerio, y los Monstruos de Sincronía Gottoms y Souza que los dirigen. Saber Slash corta tantas cartas como espadas tengan."),
 ("Boggart Knight and Pellina bring two swordsmen at once, Faultroll calls back the fallen, and the Synchro lords take over: Hyunlei clears the back row, Gottoms empties their hand.", "Boggart Knight y Pellina traen dos espadachines a la vez, Faultroll llama a los caídos, y los señores de Sincronía toman el control: Hyunlei limpia la fila de atrás y Gottoms vacía su mano."),
 ("Draw your blade. Security does not lose.", "Desenvaina. Seguridad no pierde."),
 ("My squad duels with swords. Every one of them brings a friend. Think you can keep up?", "Mi escuadrón duela con espadas. Cada uno trae a un amigo. ¿Crees que puedes seguirnos el ritmo?"),
]))

SPECS.append(({
 "key": "gimmick_puppet", "era": "ZEXAL",
 "pack": {"name": "Mansion of the Dreadful Dolls", "color": "b05cff",
  "blurb": "The Gimmick Puppets: broken dolls that drop from the hand at Level 8, overlay into Numbers 15, 40 and 88, and rank up into the Chaos Numbers that can end a duel on their own."},
 "deck": {"key": "deck_gimmick_puppet", "name": "Mansion of the Dreadful Dolls", "art": "shadow", "cover": "Number 88: Gimmick Puppet of Leo",
  "blurb": "Rouge Doll and Fiendish Knight drag two dolls out at a time, Little Soldiers turn them into Level 8s, and Giant Grinder starts cutting. If Leo gets three counters, the duel is over.",
  "cards": {"Gimmick Puppet Rouge Doll": 2, "Gimmick Puppet Fiendish Knight": 2, "Gimmick Puppet Little Soldiers": 2, "Gimmick Puppet Humpty Dumpty": 2, "Gimmick Puppet Scissor Arms": 2,
   "Gimmick Puppet Terror Baby": 2, "Gimmick Puppet Magnet Doll": 2, "Gimmick Puppet Bisque Doll": 1, "Gimmick Puppet Dreary Doll": 2, "Gimmick Puppet Nightmare": 2,
   "Gimmick Puppet Shadow Feeler": 1, "Gimmick Puppet Twilight Joker": 1, "Gimmick Puppet Cattle Scream": 1, "Gimmick Puppet Egg Head": 1, "Gimmick Puppet Des Troy": 1,
   "Junk Puppet": 2, "Mansion of the Dreadful Dolls": 2, "Perform Puppet": 1, "Condolence Puppet": 1, "Rank-Up-Magic Barian's Force": 1, "Monster Reborn": 1, "Puppet Ritual": 1, "Dark Hole": 1, "Mystical Space Typhoon": 1,
   "Puppet Parade": 2, "Service Puppet Play": 1, "Mirror Force": 1, "Call of the Haunted": 1},
  "extra": {"Number 15: Gimmick Puppet Giant Grinder": 1, "Number 40: Gimmick Puppet of Strings": 1, "Number 88: Gimmick Puppet of Leo": 1, "Gimmick Puppet Fantasix Machinix": 1,
   "Gimmick Puppet Gigantes Doll": 1, "Number C15: Gimmick Puppet Giant Hunter": 1, "Number C40: Gimmick Puppet of Dark Strings": 1, "Number C88: Gimmick Puppet Disaster Leo": 1,
   "CXyz Gimmick Puppet Fanatix Machinix": 1, "Number 39: Utopia": 1, "Castel, the Skyblaster Musketeer": 1}},
 "worlds": ["heartland"], "stage": 4,
 "npc": {"id": "night_heartland", "rotate": True, "intro": "My dolls were waiting up for you.",
  "lines_add": ["Some nights the stones stay quiet and the dolls talk instead."]},
}, [
 ("Mansion of the Dreadful Dolls", "La Mansión de las Muñecas Terribles"),
 ("The Gimmick Puppets: broken dolls that drop from the hand at Level 8, overlay into Numbers 15, 40 and 88, and rank up into the Chaos Numbers that can end a duel on their own.", "Los Gimmick Puppet: muñecos rotos que salen de la mano con Nivel 8, se superponen en los Number 15, 40 y 88, y suben de Rango a los Number Caos, capaces de terminar un duelo por sí solos."),
 ("Rouge Doll and Fiendish Knight drag two dolls out at a time, Little Soldiers turn them into Level 8s, and Giant Grinder starts cutting. If Leo gets three counters, the duel is over.", "Rouge Doll y Fiendish Knight sacan dos muñecos a la vez, Little Soldiers los vuelve de Nivel 8, y Giant Grinder empieza a cortar. Si Leo llega a tres contadores, el duelo se acaba."),
 ("My dolls were waiting up for you.", "Mis muñecas te estaban esperando despiertas."),
 ("Some nights the stones stay quiet and the dolls talk instead.", "Algunas noches las piedras callan y hablan las muñecas."),
]))

SPECS.append(({
 "key": "battlin_boxer", "era": "ZEXAL",
 "pack": {"name": "Ring of Champions", "color": "ff4a3d",
  "blurb": "The Battlin' Boxers: FIRE fighters who come in pairs, take the hits for each other, and overlay into the Numbers 79 and 105. Jolt Counter and Last Counter answer every punch."},
 "deck": {"key": "deck_battlin_boxer", "name": "Ring of Champions", "art": "warriors", "cover": "Number 105: Battlin' Boxer Star Cestus",
  "blurb": "Promoter and Uppercutter fill the ring, King Dempsey keeps the corner stocked, and Star Cestus turns their own attacks back on them. Then Comet Cestus throws the last punch.",
  "cards": {"Battlin' Boxer Promoter": 3, "Battlin' Boxer Uppercutter": 3, "Battlin' Boxer Switchitter": 2, "Battlin' Boxer Headgeared": 2, "Battlin' Boxer Glassjaw": 2,
   "Battlin' Boxer Sparrer": 2, "Battlin' Boxer Chief Second": 2, "Battlin' Boxer Shadow": 1, "Battlin' Boxer Veil": 1, "Battlin' Boxer Counterpunch": 1,
   "Battlin' Boxer Rib Gardna": 1, "Battlin' Boxer Rabbit Puncher": 1, "Battlin' Boxer Big Bandage": 1,
   "Battlin' Boxing Spirits": 2, "Ring Announcer": 2, "Reinforcement of the Army": 1, "Rank-Up-Magic Barian's Force": 1, "Monster Reborn": 1, "Double Summon": 1, "Mystical Space Typhoon": 1, "Dark Hole": 1,
   "Jolt Counter": 2, "Last Counter": 1, "Battlin' Boxing Cross Counter": 2, "Mirror Force": 1, "Bottomless Trap Hole": 1, "Dimensional Prison": 1},
  "extra": {"Battlin' Boxer King Dempsey": 2, "Battlin' Boxer Lead Yoke": 1, "Number 79: Battlin' Boxer Nova Kaiser": 1, "Number C79: Battlin' Boxer General Kaiser": 1,
   "Number 105: Battlin' Boxer Star Cestus": 1, "Number C105: Battlin' Boxer Comet Cestus": 1, "Battlin' Boxer Cheat Commissioner": 1, "Number 39: Utopia": 1,
   "Diamond Dire Wolf": 1, "Castel, the Skyblaster Musketeer": 1}},
 "worlds": ["heartland"], "stage": 4,
 "npc": {"id": "hl_boy", "rotate": True, "intro": "Gloves on. Round one!",
  "lines_add": ["Some days I duel with Warriors, some days with boxers. Both hit hard."]},
}, [
 ("Ring of Champions", "El Ring de los Campeones"),
 ("The Battlin' Boxers: FIRE fighters who come in pairs, take the hits for each other, and overlay into the Numbers 79 and 105. Jolt Counter and Last Counter answer every punch.", "Los Battlin' Boxer: luchadores de FUEGO que llegan en parejas, encajan los golpes unos por otros y se superponen en los Number 79 y 105. Jolt Counter y Last Counter responden a cada puñetazo."),
 ("Promoter and Uppercutter fill the ring, King Dempsey keeps the corner stocked, and Star Cestus turns their own attacks back on them. Then Comet Cestus throws the last punch.", "Promoter y Uppercutter llenan el ring, King Dempsey mantiene la esquina surtida, y Star Cestus les devuelve sus propios ataques. Después, Comet Cestus lanza el último golpe."),
 ("Gloves on. Round one!", "¡Guantes puestos. Primer asalto!"),
 ("Some days I duel with Warriors, some days with boxers. Both hit hard.", "Algunos días duelo con Guerreros y otros con boxeadores. Los dos pegan fuerte."),
]))

for spec, strings in SPECS:
    if ONE and spec['key'] != ONE:
        continue
    make(spec, strings)
