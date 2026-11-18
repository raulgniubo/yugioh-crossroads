class_name CardFacts
## Small facts about cards that menus and the table's dressing read: what kind of Spell or Trap a card is,
## what a Field Spell says it boosts, which of the game's own cards work. They were frozen from the game's
## first rules code when it was removed (0.50.1, tests/facts_gen.gd). The rules engine plays every card by
## its real script and reads none of this.

## Spell and Trap Cards the first rules knew by name -> their kind ("" when the card's own data says it).
const ST_K := {
"A Hero Emerges": "trap",
"A Legendary Ocean": "field",
"Absorb Fusion": "normal",
"Accellight": "normal",
"Adhesion Trap Hole": "trap",
"Against the Wind": "normal",
"Amazoness Archers": "trap",
"Ancient Gear Advance": "cont",
"Ancient Gear Castle": "field",
"Ancient Gear Catapult": "normal",
"Ancient Gear Drill": "normal",
"Ancient Gear Duel": "ctrap",
"Ancient Gear Explosive": "normal",
"Ancient Gear Factory": "normal",
"Ancient Gear Fist": "equip",
"Ancient Gear Fortress": "cont",
"Ancient Gear Fusion": "normal",
"Ancient Gear Reborn": "ctrap",
"Ancient Gear Tank": "equip",
"Ancient Gear Workshop": "normal",
"Aqua Jet": "normal",
"Armored Xyz": "trap",
"Assault Armor": "equip",
"Assault Mode Activate": "trap",
"Attack Reflector Unit": "trap",
"Axe of Despair": "equip",
"Backfire": "ctrap",
"Banner of Courage": "cont",
"Battle Break": "trap",
"Beast Fangs": "equip",
"Beginning of Heaven and Earth": "trap",
"Big Bang Shot": "equip",
"Big Wave Small Wave": "normal",
"Black Feather Beacon": "trap",
"Black Illusion Ritual": "ritual",
"Black Luster Ritual": "ritual",
"Black Magic Ritual": "ritual",
"Black Pendant": "equip",
"Black Sonic": "trap",
"Black Thunder": "trap",
"Black Whirlwind": "cont",
"Blackback": "trap",
"Blackboost": "trap",
"Blackwing - Backlash": "trap",
"Blackwing - Bombardment": "trap",
"Blossom Bombardment": "ctrap",
"Blue Medicine": "normal",
"Blustering Winds": "normal",
"Book of Moon": "quick",
"Book of Secret Arts": "equip",
"Book of Taiyou": "normal",
"Bottomless Trap Hole": "trap",
"Brain Control": "normal",
"Breakthrough Skill": "trap",
"Brilliant Fusion": "cont",
"Brilliant Spark": "trap",
"Bubble Bringer": "ctrap",
"Burning Land": "cont",
"Burst Return": "normal",
"Burst Stream of Destruction": "normal",
"Bye Bye Damage": "trap",
"Call of the Haunted": "ctrap",
"Card Destruction": "normal",
"Card Rotator": "normal",
"Card of Sanctity": "normal",
"Cards for Black Feathers": "normal",
"Cards of Consonance": "normal",
"Ceasefire": "trap",
"Chain Destruction": "trap",
"Change of Heart": "normal",
"Changing Destiny": "trap",
"Chaos End": "normal",
"Chaos Form": "ritual",
"Chaos Greed": "normal",
"Chaos Magical Hats": "quick",
"Chaos Mystic Box": "trap",
"Chaos Space": "normal",
"Charge of the Light Brigade": "normal",
"Chorus of Sanctuary": "field",
"Chthonian Alliance": "equip",
"Chthonian Polymer": "trap",
"Clock Tower Prison": "field",
"Coffin Seller": "ctrap",
"Compulsory Evacuation Device": "trap",
"Cost Down": "normal",
"Crimson Fire": "trap",
"Cross-Dimensional Duel": "trap",
"Crush Card Virus": "trap",
"Cursed Seal of the Forbidden Spell": "counter",
"Cyber Shield": "equip",
"Cyber Summon Blaster": "ctrap",
"Cyberdark Impact!": "normal",
"Cyclon Laser": "equip",
"D - Chain": "trap",
"D - Shield": "ctrap",
"D - Spirit": "normal",
"DNA Surgery": "ctrap",
"Dark Bribe": "counter",
"Dark City": "field",
"Dark Core": "normal",
"Dark Energy": "equip",
"Dark Factory of Mass Production": "normal",
"Dark Magic Attack": "normal",
"Dark Magic Curtain": "normal",
"Dark Sanctuary": "field",
"De-Fusion": "quick",
"De-Spell": "normal",
"Dedication through Light and Darkness": "quick",
"Defense Draw": "trap",
"Delta Crow - Anti Reverse": "trap",
"Depth Amulet": "ctrap",
"Descending Lost Star": "trap",
"Destiny Board": "ctrap",
"Destiny Draw": "normal",
"Destiny Signal": "trap",
"Destruction of Destiny": "trap",
"Dian Keto the Cure Master": "normal",
"Different Dimension Capsule": "cont",
"Dimensional Fissure": "cont",
"Dimensional Prison": "trap",
"Divine Wrath": "counter",
"Doble Passe": "trap",
"Dodododraw": "normal",
"Domain of the True Monarchs": "field",
"Doppelganger": "trap",
"Double Summon": "normal",
"Dragon Capture Jar": "ctrap",
"Dragon Treasure": "equip",
"Dragon's Mirror": "normal",
"Draining Shield": "trap",
"Dust Tornado": "trap",
"E - Emergency Call": "normal",
"Echo Call": "normal",
"Echo Resonance": "normal",
"Echo Veil": "trap",
"Ectoplasmer": "cont",
"Edge Hammer": "trap",
"Ego Boost": "quick",
"Electro-Whip": "equip",
"Elegant Egotist": "normal",
"Elf's Light": "equip",
"Enchanted Javelin": "trap",
"Enemy Controller": "quick",
"Eradicating Aerosol": "normal",
"Escalation of the Monarchs": "ctrap",
"Eternal Dread": "trap",
"Exchange of the Spirit": "trap",
"Fairy Box": "ctrap",
"Fairy Meteor Crush": "equip",
"Fake Hero": "normal",
"Feather Shot": "normal",
"Fiendish Chain": "ctrap",
"Fiery Fervor": "ctrap",
"Fighting Spirit": "equip",
"Final Flame": "normal",
"Follow Wind": "equip",
"Foolish Burial": "normal",
"Forbidden Chalice": "quick",
"Forbidden Lance": "quick",
"Forest": "field",
"Fossil Excavation": "ctrap",
"Fragment Fusion": "trap",
"Frost Blast of the Monarchs": "normal",
"Full Salvo": "trap",
"Fusion Weapon": "equip",
"Gagagaback": "trap",
"Gagagabolt": "normal",
"Gagagarevenge": "equip",
"Gagagashield": "ctrap",
"Gagagatag": "normal",
"Gaia Power": "field",
"Galaxy Expedition": "normal",
"Galaxy Queen's Light": "normal",
"Galaxy Storm": "normal",
"Galloping Gaia": "cont",
"Gateway to Chaos": "cont",
"Geartown": "field",
"Gem-Enhancement": "trap",
"Gem-Knight Dispersion": "normal",
"Gem-Knight Fusion": "normal",
"Giant Trunade": "normal",
"Give and Take": "trap",
"Glorious Illusion": "ctrap",
"Goblin's Secret Remedy": "normal",
"Gold Sarcophagus": "normal",
"Gorgon's Eye": "trap",
"Graceful Charity": "normal",
"Graceful Dice": "quick",
"Graceful Revival": "ctrap",
"Gravekeeper's Inscription": "cont",
"Gravekeeper's Servant": "cont",
"Gravekeeper's Stele": "normal",
"Gravekeeper's Trap": "ctrap",
"Gravity Bind": "ctrap",
"Gust Fan": "equip",
"H - Heated Heart": "normal",
"Half Unbreak": "trap",
"Half or Nothing": "trap",
"Hallowed Life Barrier": "trap",
"Hammer Shot": "normal",
"Harpie Lady Phoenix Formation": "normal",
"Harpie's Feather Duster": "normal",
"Harpies' Hunting Ground": "field",
"Heart of Clear Water": "equip",
"Heartfelt Appeal": "trap",
"Heavy Storm": "normal",
"Hero Barrier": "trap",
"Hero Signal": "trap",
"Hidden Temples of Necrovalley": "cont",
"Horn of Heaven": "counter",
"Horn of the Unicorn": "equip",
"Hunting Instinct": "trap",
"Hysteric Party": "trap",
"Icarus Attack": "trap",
"Impenetrable Attack": "trap",
"Imperial Order": "ctrap",
"Imperial Tombs of Necrovalley": "counter",
"Infernity Barrier": "counter",
"Infernity Break": "trap",
"Infernity Force": "trap",
"Infernity Inferno": "trap",
"Infernity Launcher": "cont",
"Infernity Reflector": "trap",
"Insect Armor with Laser Cannon": "equip",
"Insect Barrier": "cont",
"Instant Neo Space": "equip",
"Interdimensional Matter Transporter": "trap",
"Jam Breeding Machine": "cont",
"Jam Defender": "ctrap",
"Jar of Greed": "trap",
"Junk Barrage": "equip",
"Jurassic World": "field",
"Just Desserts": "trap",
"Knight's Title": "normal",
"Laser Cannon Armor": "equip",
"Left Arm Offering": "normal",
"Legendary Sword": "equip",
"Level Limit - Area B": "cont",
"Level Retuner": "trap",
"Level Up!": "normal",
"Light Spiral": "ctrap",
"Light and Darkness Ritual": "ritual",
"Lightforce Sword": "trap",
"Lightning Blade": "equip",
"Lightning Vortex": "normal",
"Lightsworn Aegis": "trap",
"Lightsworn Barrier": "ctrap",
"Lightsworn Judgment": "trap",
"Lightsworn Sabre": "equip",
"Lightsworn Sanctuary": "cont",
"Limiter Overload": "trap",
"Limiter Removal": "quick",
"Lineage of Destruction": "trap",
"Lumenize": "trap",
"Luminous Spark": "field",
"Machine Angel Ritual": "ritual",
"Machine Conversion Factory": "equip",
"Machine Duplication": "normal",
"Macro Cosmos": "ctrap",
"Mage Power": "equip",
"Magic Cylinder": "trap",
"Magic Formula": "equip",
"Magic Jammer": "counter",
"Magic Planter": "normal",
"Malevolent Catastrophe": "trap",
"Malevolent Nuzzler": "equip",
"March of the Dark Brigade": "normal",
"March of the Monarchs": "cont",
"Mark of the Rose": "equip",
"Megamorph": "equip",
"Messenger of Peace": "cont",
"Metal Reflect Slime": "trap",
"Metalmorph": "ctrap",
"Meteor of Destruction": "normal",
"Mind Control": "normal",
"Mind Shuffle": "ctrap",
"Miracle Fusion": "normal",
"Mirror Force": "trap",
"Mirror Wall": "ctrap",
"Misfortune": "normal",
"Mist Body": "equip",
"Molten Destruction": "field",
"Monarchic Perfection": "ctrap",
"Monster Reincarnation": "normal",
"Mountain": "field",
"Multiple Destruction": "trap",
"Multiplication of Ants": "normal",
"Multiply": "quick",
"Mystic Box": "normal",
"Mystic Plasma Zone": "field",
"Mystical Moon": "equip",
"Mystical Space Typhoon": "quick",
"Nature's Reflection": "trap",
"Necrovalley": "field",
"Necrovalley Temple": "ctrap",
"Necrovalley Throne": "normal",
"Negate Attack": "counter",
"Neo Space": "field",
"Nightmare Archfiends": "trap",
"Nightmare Wheel": "ctrap",
"Nightmare's Steelcage": "cont",
"No Entry!!": "trap",
"Nobleman of Crossout": "normal",
"Nobleman of Extermination": "normal",
"Nutrient Z": "trap",
"O - Oversoul": "normal",
"Offerings to the Doomed": "quick",
"Ojama Delta Hurricane!!": "normal",
"Ojamagic": "normal",
"Ojamuscle": "normal",
"One for One": "normal",
"Onomatopaira": "normal",
"Ookazi": "normal",
"Over Destiny": "normal",
"Overload Fusion": "normal",
"Pantheism of the Monarchs": "normal",
"Particle Fusion": "normal",
"Pharaoh's Treasure": "trap",
"Photon Booster": "normal",
"Photon Current": "trap",
"Photon Generator Unit": "normal",
"Photon Lead": "quick",
"Photon Sanctuary": "normal",
"Photon Stream of Destruction": "quick",
"Photon Trident": "quick",
"Photon Veil": "normal",
"Poison of the Old Man": "quick",
"Poseidon Wave": "trap",
"Pot of Avarice": "normal",
"Power of Kaishin": "equip",
"Powerful Rebirth": "ctrap",
"Premature Burial": "equip",
"Prideful Roar": "trap",
"Pyroxene Fusion": "trap",
"R - Righteous Justice": "normal",
"Raigeki Break": "trap",
"Raise Body Heat": "equip",
"Rank-Up-Magic Barian's Force": "normal",
"Rank-Up-Magic Limited Barian's Force": "normal",
"Raptor Wing Strike": "normal",
"Realm of Light": "field",
"Reckless Greed": "trap",
"Red Medicine": "normal",
"Reinforcement of the Army": "normal",
"Release Restraint": "normal",
"Remove Trap": "normal",
"Resonator Call": "normal",
"Restoration of the Monarchs": "equip",
"Return of the Monarchs": "cont",
"Ring of Destruction": "trap",
"Ring of Magnetism": "equip",
"Rising Air Current": "field",
"Rite of Spirit": "trap",
"Ritual Weapon": "equip",
"Rope of Life": "trap",
"Royal Decree": "ctrap",
"Royal Tribute": "normal",
"Rush Recklessly": "quick",
"Sage's Stone": "normal",
"Sakuretsu Armor": "trap",
"Salamandra": "equip",
"Salvage": "normal",
"Sangan's Call": "normal",
"Scapegoat": "quick",
"Scarlet Security": "normal",
"Scatter Fusion": "cont",
"Scrap-Iron Scarecrow": "trap",
"Seed of Deception": "normal",
"Seven Tools of the Bandit": "counter",
"Shadow Spell": "ctrap",
"Share the Pain": "normal",
"Shield & Sword": "normal",
"Shield Crush": "normal",
"Shooting Star": "trap",
"Shrink": "quick",
"Silver Bow and Arrow": "equip",
"Silver Wing": "equip",
"Skill Drain": "ctrap",
"Skill Successor": "trap",
"Skull Dice": "trap",
"Skyscraper": "field",
"Slip Summon": "trap",
"Smashing Ground": "normal",
"Snatch Steal": "equip",
"Sogen": "field",
"Solar Recharge": "normal",
"Solemn Judgment": "counter",
"Solidarity": "cont",
"Soul Exchange": "normal",
"Soul of the Pure": "normal",
"Spark Blaster": "equip",
"Sparks": "normal",
"Speed Spell - Afterburner": "normal",
"Speed Spell - Full Throttle": "normal",
"Speed Spell - Overtake": "normal",
"Speed Spell - Pit Stop": "normal",
"Speed Spell - Redline": "normal",
"Speed Spell - Road Clear": "quick",
"Speed Spell - Shockwave": "normal",
"Speed Spell - Slipstream Strike": "quick",
"Speed Spell - Tailwind": "normal",
"Speed Spell - Twin Turbo": "normal",
"Spell Gear": "normal",
"Spell Shield Type-8": "counter",
"Spellbinding Circle": "ctrap",
"Spiral Discharge": "ctrap",
"Spiral Spear Strike": "cont",
"Spirit Message \"A\"": "cont",
"Spirit Message \"I\"": "cont",
"Spirit Message \"L\"": "cont",
"Spirit Message \"N\"": "cont",
"Splash Capture": "trap",
"Stamping Destruction": "normal",
"Starlight Road": "trap",
"Steel Shell": "equip",
"Stop Defense": "normal",
"Strike of the Monarchs": "normal",
"Super Soldier Rebirth": "trap",
"Super Soldier Ritual": "ritual",
"Super Soldier Shield": "trap",
"Super Soldier Synthesis": "ritual",
"Supercharge": "trap",
"Surface": "normal",
"Survival Instinct": "trap",
"Sword of Dark Destruction": "equip",
"Sword of Deep-Seated": "equip",
"Synchro Barrier": "trap",
"Synchro Strike": "trap",
"Tail Swipe": "normal",
"Tenacity of the Monarchs": "normal",
"Terraforming": "normal",
"The Dark Door": "cont",
"The First Monarch": "trap",
"The Flute of Summoning Dragon": "normal",
"The Monarchs Awaken": "trap",
"The Monarchs Erupt": "ctrap",
"The Monarchs Masterplan": "normal",
"The Monarchs Revolt": "normal",
"The Monarchs Stormforth": "normal",
"The Prime Monarch": "ctrap",
"The Reliable Guardian": "quick",
"The Warrior Returning Alive": "normal",
"Thorn of Malice": "equip",
"Thousand Knives": "normal",
"Threatening Roar": "trap",
"Toon Table of Contents": "normal",
"Toon World": "cont",
"Torrential Tribute": "trap",
"Transcendent Wings": "quick",
"Trap Hole": "trap",
"Trap Jammer": "counter",
"Trap Stun": "trap",
"Tremendous Fire": "normal",
"Triangle Ecstasy Spark": "normal",
"Tribute to The Doomed": "normal",
"Tuning": "normal",
"Twilight Cloth": "normal",
"Twilight Eraser": "trap",
"Twilight Twin Dragons": "normal",
"Ultra Evolution Pill": "normal",
"Umi": "field",
"Umiiruka": "field",
"United We Stand": "equip",
"Upstart Goblin": "normal",
"Urgent Tuning": "trap",
"Vain Betrayer": "ctrap",
"Vanquishing Light": "counter",
"Vengeful Bog Spirit": "cont",
"Vile Germs": "equip",
"Violet Crystal": "equip",
"Void Trap Hole": "trap",
"Waboku": "trap",
"Wasteland": "field",
"Wave-Motion Cannon": "cont",
"Wicked Rebirth": "ctrap",
"Widespread Ruin": "trap",
"Windstorm of Etaqua": "trap",
"Wonder Garage": "trap",
"Wonder Wand": "equip",
"Xyz Energy": "normal",
"Xyz Gift": "normal",
"Yami": "field",
"ZERO-MAX": "normal",
"Zero Gravity": "trap"
}

## Speed Spells: the Speed Counters each one asks for.
const SPEED := {
"Speed Spell - Afterburner": 4,
"Speed Spell - Overtake": 6,
"Speed Spell - Pit Stop": 2,
"Speed Spell - Redline": 8,
"Speed Spell - Road Clear": 5,
"Speed Spell - Shockwave": 7,
"Speed Spell - Slipstream Strike": 3,
"Speed Spell - Tailwind": 2,
"Speed Spell - Twin Turbo": 4
}

## Card id -> kind, where it is not simply what the card's data says.
const KIND := {
1435851: "equip",
1557499: "equip",
2106266: "cont",
2370081: "equip",
2372506: "quick",
3136426: "cont",
3492538: "equip",
3819470: "counter",
4064925: "cont",
4614116: "equip",
5318639: "quick",
5494820: "equip",
6178850: "equip",
7394770: "cont",
8279188: "ctrap",
8842266: "quick",
9059700: "counter",
10012614: "cont",
10080320: "field",
11913700: "equip",
11961740: "cont",
13438207: "ctrap",
14087893: "quick",
14094090: "ritual",
14315573: "counter",
15052462: "equip",
15259703: "cont",
16430187: "quick",
16625614: "field",
16762927: "cont",
18161786: "field",
18235309: "ctrap",
18446701: "ctrap",
18807108: "ctrap",
19230407: "quick",
19252988: "counter",
19384334: "field",
19870120: "cont",
20436034: "equip",
21082832: "ritual",
21558682: "ctrap",
21598948: "ctrap",
21770260: "cont",
22046459: "equip",
22201234: "ctrap",
22359980: "ctrap",
22702055: "field",
23171610: "quick",
23424603: "field",
23440062: "ctrap",
23615409: "cont",
23869735: "ctrap",
24294108: "cont",
24749710: "ctrap",
25231813: "equip",
25573054: "quick",
25769732: "equip",
25789292: "quick",
27243130: "quick",
27967615: "equip",
29267084: "ctrap",
29477860: "ctrap",
30170981: "cont",
30241314: "ctrap",
30502181: "equip",
30606547: "cont",
31893528: "cont",
32233746: "counter",
32268901: "equip",
33599853: "ritual",
35577420: "ctrap",
35848254: "quick",
36099620: "field",
36607978: "equip",
37120512: "equip",
37457534: "equip",
37694547: "field",
37820550: "equip",
38275183: "counter",
38992735: "cont",
39774685: "equip",
39897277: "equip",
39996157: "ritual",
40089744: "cont",
40597694: "cont",
40619825: "equip",
40703222: "quick",
40830387: "equip",
41420027: "counter",
41426869: "ritual",
42015635: "field",
44656491: "cont",
45247637: "equip",
45778932: "field",
45948430: "ritual",
45986603: "equip",
46009906: "equip",
46910446: "equip",
47355498: "field",
47482043: "ctrap",
47529357: "equip",
48716527: "ctrap",
49010598: "counter",
49328340: "cont",
50045299: "ctrap",
50078509: "ctrap",
50913601: "field",
51267887: "equip",
51452091: "ctrap",
51589188: "quick",
52665542: "cont",
53527835: "field",
53541822: "ctrap",
54241725: "ctrap",
54351224: "equip",
54704216: "ctrap",
55226821: "equip",
55321970: "equip",
55713623: "quick",
55761792: "ritual",
56594520: "field",
56747793: "equip",
56773577: "ctrap",
58531587: "ctrap",
58775978: "cont",
58851034: "counter",
59197169: "field",
59494222: "cont",
59983249: "ctrap",
61127349: "equip",
61466310: "cont",
61740673: "ctrap",
61854111: "equip",
61962135: "ctrap",
62868900: "ctrap",
63035430: "field",
63224564: "equip",
63477921: "ctrap",
64047146: "equip",
64801562: "equip",
65079854: "equip",
65169794: "equip",
65830223: "ctrap",
66957584: "cont",
67227834: "equip",
67287533: "cont",
67775894: "equip",
68054593: "ctrap",
68540058: "ctrap",
69542930: "quick",
70000776: "cont",
70046172: "quick",
70147689: "cont",
70828912: "equip",
72044448: "quick",
73046708: "trap",
73178098: "quick",
73915051: "quick",
74137509: "quick",
74701381: "ctrap",
75041269: "field",
75782277: "field",
75983808: "trap",
76792184: "ritual",
77007920: "equip",
77027445: "equip",
77414722: "counter",
77538567: "counter",
79068663: "equip",
81380218: "field",
81674782: "cont",
81777047: "field",
82052602: "trap",
82705573: "ctrap",
82732705: "ctrap",
82999629: "field",
83746708: "equip",
83747250: "normal",
84171830: "field",
84298614: "ctrap",
85742772: "ctrap",
86318356: "field",
86780027: "cont",
87430998: "field",
88190790: "equip",
90434657: "counter",
90673413: "equip",
91351370: "cont",
91595718: "equip",
92001300: "field",
94212438: "ctrap",
94772232: "cont",
94933468: "ctrap",
95220856: "cont",
95286165: "quick",
97077563: "ctrap",
97342942: "cont",
97362768: "equip",
97687912: "equip",
98045062: "quick",
98069388: "counter",
98252586: "equip",
98273947: "ctrap",
98495314: "equip",
98552723: "equip",
98715423: "ctrap",
99100004: "quick",
99100007: "quick",
99597615: "equip"
}

## Field Spell id -> what it boosts: [[who, ATK, DEF?]...] and a DEF boost for Defense Position monsters.
const FIELD := {
10080320: {
"boost": [[{
"race": "Dinosaur"
}, 300, 300]]
},
18161786: {
"boost": [[{
"attr": "DARK"
}, 500, -400]]
},
19384334: {
"boost": [[{
"attr": "FIRE"
}, 500, -400]]
},
22702055: {
"boost": [[{
"race": "Fish"
}, 200, 200], [{
"race": "Sea Serpent"
}, 200, 200], [{
"race": "Thunder"
}, 200, 200], [{
"race": "Aqua"
}, 200, 200], [{
"race": "Machine"
}, -200, -200], [{
"race": "Pyro"
}, -200, -200]]
},
23424603: {
"boost": [[{
"race": "Dinosaur"
}, 200, 200], [{
"race": "Zombie"
}, 200, 200], [{
"race": "Rock"
}, 200, 200]]
},
45778932: {
"boost": [[{
"attr": "WIND"
}, 500, -400]]
},
47355498: {
"boost": [[{
"has": "Gravekeeper"
}, 500, 500]]
},
50913601: {
"boost": [[{
"race": "Dragon"
}, 200, 200], [{
"race": "Winged Beast"
}, 200, 200], [{
"race": "Thunder"
}, 200, 200]]
},
56594520: {
"boost": [[{
"attr": "EARTH"
}, 500, -400]]
},
59197169: {
"boost": [[{
"race": "Fiend"
}, 200, 200], [{
"race": "Spellcaster"
}, 200, 200], [{
"race": "Fairy"
}, -200, -200]]
},
75782277: {
"boost": [[{
"race": "Winged Beast"
}, 200, 200]]
},
81380218: {
"def_pos_boost": 500
},
81777047: {
"boost": [[{
"attr": "LIGHT"
}, 500, -400]]
},
82999629: {
"boost": [[{
"attr": "WATER"
}, 500, -400]]
},
86318356: {
"boost": [[{
"race": "Warrior"
}, 200, 200], [{
"race": "Beast-Warrior"
}, 200, 200]]
},
87430998: {
"boost": [[{
"race": "Insect"
}, 200, 200], [{
"race": "Beast"
}, 200, 200], [{
"race": "Plant"
}, 200, 200], [{
"race": "Beast-Warrior"
}, 200, 200]]
},
92001300: {
"boost": [[{
"has": "Ancient Gear"
}, 300, 0]]
}
}

## The game's own cards and tokens (not in the engine's pool) that work in a deck.
const WORKS := {
99100001: true,
99100002: true,
99100003: true,
99100004: true,
99100005: true,
99100006: true,
99100007: true,
99100008: true,
99100009: true,
99100010: true,
99200011: true,
99200012: true,
99200013: true
}

## Monsters without the Effect frame that still have an effect (the Deck Builder's auto-build scores them higher).
const FX_ANY := {
"Alligator's Sword Dragon": true,
"Ambulance Rescueroid": true,
"Ancient Gear Howitzer": true,
"Ancient Gear Megaton Golem": true,
"Arcana Knight Joker": true,
"Arcanite Magician": true,
"Armory Arm": true,
"Bahamut Shark": true,
"Black Luster Soldier - Legendary Swordsman": true,
"Black Luster Soldier - Soldier of Light and Darkness": true,
"Black Luster Soldier - Super Soldier": true,
"Black Ray Lancer": true,
"Black Rose Dragon": true,
"Black-Winged Dragon": true,
"Blackwing - Silverwind the Ascendant": true,
"Blackwing Armed Wing": true,
"Blackwing Armor Master": true,
"Blue-Eyes Chaos Dragon": true,
"Blue-Eyes Chaos MAX Dragon": true,
"Cat Shark": true,
"Chaos Ancient Gear Giant": true,
"Chaos King Archfiend": true,
"Chimera the Flying Mythical Beast": true,
"Chimeratech Overdragon": true,
"Colossal Fighter": true,
"Crimson Blader": true,
"Cyber Angel Benten": true,
"Cyber Angel Dakini": true,
"Cyber Angel Idaten": true,
"Cyber Blader": true,
"Cyber End Dragon": true,
"Cyber Twin Dragon": true,
"Cyberdark Dragon": true,
"Dark Paladin": true,
"Destiny End Dragoon": true,
"Dragon Master Knight": true,
"Dragon Master Magia": true,
"Drill Warrior": true,
"Elemental HERO Air Neos": true,
"Elemental HERO Aqua Neos": true,
"Elemental HERO Dark Neos": true,
"Elemental HERO Electrum": true,
"Elemental HERO Flame Wingman": true,
"Elemental HERO Flare Neos": true,
"Elemental HERO Glow Neos": true,
"Elemental HERO Grand Neos": true,
"Elemental HERO Magma Neos": true,
"Elemental HERO Mariner": true,
"Elemental HERO Mudballman": true,
"Elemental HERO Necroid Shaman": true,
"Elemental HERO Phoenix Enforcer": true,
"Elemental HERO Rampart Blaster": true,
"Elemental HERO Shining Flare Wingman": true,
"Elemental HERO Shining Phoenix Enforcer": true,
"Elemental HERO Steam Healer": true,
"Elemental HERO Storm Neos": true,
"Elemental HERO Tempest": true,
"Elemental HERO Thunder Giant": true,
"Elemental HERO Wild Wingman": true,
"Elemental HERO Wildedge": true,
"Enlightenment Dragon": true,
"Exploder Dragonwing": true,
"Explosive Magician": true,
"Five-Headed Dragon": true,
"Formula Synchron": true,
"Gagaga Cowboy": true,
"Gagaga Samurai": true,
"Gaia the Magical Knight of Dragons": true,
"Gem-Knight Amethyst": true,
"Gem-Knight Aquamarine": true,
"Gem-Knight Citrine": true,
"Gem-Knight Lady Brilliant Diamond": true,
"Gem-Knight Lady Lapis Lazuli": true,
"Gem-Knight Lady Rose Diamond": true,
"Gem-Knight Master Diamond": true,
"Gem-Knight Master Diamond Dispersion": true,
"Gem-Knight Prismaura": true,
"Gem-Knight Ruby": true,
"Gem-Knight Seraphinite": true,
"Gem-Knight Topaz": true,
"Gem-Knight Zirconia": true,
"Gravekeeper's Supernaturalist": true,
"Hundred Eyes Dragon": true,
"Illusion of Chaos": true,
"Infernity Doom Dragon": true,
"Junk Archer": true,
"Junk Berserker": true,
"Junk Destroyer": true,
"Junk Gardna": true,
"Junk Warrior": true,
"King Dragun": true,
"Lightning Warrior": true,
"Lumen, Echo Chorus": true,
"Lumen, Echo Comet": true,
"Lumen, Echo Zenith": true,
"Magician of Black Chaos MAX": true,
"Magician of Chaos": true,
"Magician of Dark Chaos - Black Chaos": true,
"Majestic Red Dragon": true,
"Majestic Star Dragon": true,
"Master of Chaos": true,
"Michael, the Arch-Lightsworn": true,
"Minerva, the Athenian Lightsworn": true,
"Minerva, the Exalted Lightsworn": true,
"Mist Valley Thunder Lord": true,
"Neo Galaxy-Eyes Photon Dragon": true,
"Nitro Warrior": true,
"Number 101: Silent Honor ARK": true,
"Number 104: Masquerade": true,
"Number 10: Illumiknight": true,
"Number 12: Crimson Shadow Armor Ninja": true,
"Number 17: Leviathan Dragon": true,
"Number 20: Giga-Brilliant": true,
"Number 25: Force Focus": true,
"Number 30: Acid Golem of Destruction": true,
"Number 32: Shark Drake": true,
"Number 34: Terror-Byte": true,
"Number 37: Hope Woven Dragon Spider Shark": true,
"Number 39: Utopia": true,
"Number 39: Utopia Beyond": true,
"Number 39: Utopia Roots": true,
"Number 43: Manipulator of Souls": true,
"Number 47: Nightmare Shark": true,
"Number 56: Gold Rat": true,
"Number 61: Volcasaurus": true,
"Number 62: Galaxy-Eyes Prime Photon Dragon": true,
"Number 65: Djinn Buster": true,
"Number 66: Master Key Beetle": true,
"Number 6: Chronomaly Atlandis": true,
"Number 71: Rebarian Shark": true,
"Number 73: Abyss Splash": true,
"Number 83: Galaxy Queen": true,
"Number 96: Dark Mist": true,
"Number C101: Silent Honor DARK": true,
"Number C104: Umbral Horror Masquerade": true,
"Number C32: Shark Drake Veiss": true,
"Number C39: Utopia Ray": true,
"Number C39: Utopia Ray V": true,
"Number C39: Utopia Ray Victory": true,
"Number C65: King Overfiend": true,
"Number C96: Dark Storm": true,
"Number F0: Utopic Future": true,
"Number S39: Utopia the Lightning": true,
"Ojama King": true,
"Ojama Knight": true,
"Pair Cycroid": true,
"Photon Papilloperative": true,
"Photon Token": true,
"Queen of Thorns": true,
"Red Dragon Archfiend": true,
"Red Nova Dragon": true,
"Red-Eyes Black Dragon": true,
"Relinquished": true,
"Road Warrior": true,
"Scarlight Red Dragon Archfiend": true,
"Shooting Quasar Dragon": true,
"Shooting Star Dragon": true,
"Sky Galloping Gaia the Dragon Champion": true,
"Splendid Rose": true,
"Stardust Dragon": true,
"Starliege Lord Galaxion": true,
"Starliege Paladynamo": true,
"Submersible Carrier Aero Shark": true,
"Super Vehicroid - Stealth Union": true,
"Super Vehicroid Jumbo Drill": true,
"Thousand-Eyes Restrict": true,
"Turbo Warrior": true,
"UFOroid Fighter": true,
"Ultimate Ancient Gear Golem": true,
"VW-Tiger Catapult": true,
"VWXYZ-Dragon Catapult Cannon": true,
"Void Ogre Dragon": true,
"XY-Dragon Cannon": true,
"XYZ-Dragon Cannon": true,
"XZ-Tank Cannon": true,
"YZ-Tank Dragon": true,
"ZW - Leo Arms": true
}

## What a card of this game does, for cards with no printed text.
const NOTE := {}

## Cards that count as another name.
const ALIAS := {
"Ancient Gear Dark Golem": {
"name_as_fg": "Ancient Gear Golem"
},
"Brilliant Rose": {
"also_named": "Gem-Knight"
},
"Cyber Dragon Zwei": {
"name_as": "Cyber Dragon"
},
"Gaia the Magical Knight": {
"also_named": "Gaia The Fierce Knight"
},
"Gaia the Magical Knight of Dragons": {
"name_as": "Gaia the Dragon Champion"
},
"Harpie Channeler": {
"name_as_fg": "Harpie Lady"
},
"Harpie Queen": {
"name_as_fg": "Harpie Lady"
},
"Heart of Gaia": {
"also_named": "Gaia The Fierce Knight"
},
"Magician of Chaos": {
"name_as_fg": "Dark Magician"
},
"Proto-Cyber Dragon": {
"name_as": "Cyber Dragon"
},
"Scarlight Red Dragon Archfiend": {
"name_as": "Red Dragon Archfiend"
},
"Sky Galloping Gaia the Dragon Champion": {
"name_as": "Gaia the Dragon Champion"
}
}


## Is this card in the game? The rules engine plays what is in the pool; the game's own cards and tokens too.
static func ok(d: Dictionary) -> bool:
	var id := int(d.get("id", 0))
	return bool(d.get("original", false)) or CardData.ORIGINALS.has(id) or CardData.TOKENS.has(id) or CardPool.has(id)


## Can this card go in a deck and do its job?
static func works(id: int) -> bool:
	return CardPool.has(id) or WORKS.has(id)


## What kind of Spell or Trap a card is: "normal", "quick", "cont", "field", "equip", "ritual", "counter", "trap", "ctrap"...
static func kind(c) -> String:
	if c == null or c.is_monster():
		return ""
	if KIND.has(int(c.id)):
		return str(KIND[int(c.id)])
	var st := str(c.data.get("st", "")).to_lower()
	return str({"quick-play": "quick", "continuous": "cont", "counter": "counter", "equip": "equip", "field": "field", "ritual": "ritual"}.get(st, "trap" if c.is_trap() else "normal"))


## What a Field Spell boosts ({} when it boosts nothing, or is not one).
static func field(c) -> Dictionary:
	return FIELD.get(int(c.id), {}) if c != null else {}


## How a duelist plays, for the line under their name: "aggro", "wall", "trap" or "".
static func style_for(key: String) -> String:
	if key == "zane":
		return "aggro"
	return {"cocky": "aggro", "wild": "aggro", "cool": "wall", "dark": "trap"}.get(str(Characters.get_char(key).get("personality", "")), "")


## Does a card match a filter dictionary?
static func matches(d: Dictionary, f: Dictionary) -> bool:
	if f.get("monster", true) and (d.get("kind", "monster") != "monster" or str(d.get("frame", "")) in ["spell", "trap"]):
		return false
	if f.has("frame") and str(d.get("frame", "")) != f["frame"]:
		return false
	if f.has("kind") and str(d.get("kind", "monster")) != f["kind"]:
		return false
	var n := str(d.get("name", ""))
	var alias := str((ALIAS.get(n, {}) as Dictionary).get("name_as", ""))
	if alias == "" and str(f.get("zone", "")) in ["field", "gy"]:
		# "This card's name becomes ... while on the field or in the GY" (Harpie Queen, Harpie Channeler).
		alias = str((ALIAS.get(n, {}) as Dictionary).get("name_as_fg", ""))
	if f.has("name") and n != f["name"] and alias != f["name"]:
		return false
	if f.has("not") and n == f["not"]:
		return false
	if f.has("has"):
		var ok := false
		var also := str((ALIAS.get(n, {}) as Dictionary).get("also_named", ""))   # Brilliant Rose: "This card is always treated as a "Gem-Knight" card."
		for part in str(f["has"]).split("|"):
			if n.contains(part) or alias.contains(part) or (also != "" and also.contains(part)):
				ok = true
		if not ok:
			return false
	if f.get("monarch_st", false) and not (n.contains("Monarch") and str(d.get("kind", "monster")) != "monster"):
		return false   # "Monarch" Spells/Traps
	if f.has("atk_in") and not (int(d.get("atk", -1)) in (f["atk_in"] as Array)):
		return false   # (the Monarchs: "2400 ATK/1000 DEF, or 2800 ATK/1000 DEF")
	if f.has("def_eq") and int(d.get("def", -1)) != int(f["def_eq"]):
		return false
	if f.has("min_atk") and int(d.get("atk", 0)) < int(f["min_atk"]):
		return false
	if f.get("gaia", false):
		# "Gaia The Fierce Knight" monsters: the name has it, or the card is always treated as one (Gaia the Magical Knight, Heart of Gaia).
		if not ((n.contains("Gaia") and n.contains("Fierce Knight")) or str((ALIAS.get(n, {}) as Dictionary).get("also_named", "")) == "Gaia The Fierce Knight"):
			return false
	if f.has("names") and not (n in (f["names"] as Array)) and not (alias != "" and alias in (f["names"] as Array)):
		return false
	if f.has("race") and str(d.get("race", "")) != f["race"]:
		return false
	if f.has("attr") and str(d.get("attribute", "")) != f["attr"]:
		return false
	if f.has("min_lv") and int(d.get("level", 0)) < int(f["min_lv"]):
		return false
	if f.has("max_lv") and int(d.get("level", 0)) > int(f["max_lv"]):
		return false
	if f.has("min_lv") and (int(d.get("level", 0)) < int(f["min_lv"]) or str(d.get("frame", "")) == "xyz"):
		return false
	if f.has("tuner") and bool(d.get("tuner", false)) != bool(f["tuner"]):
		return false
	if f.has("races") and not (str(d.get("race", "")) in (f["races"] as Array)):
		return false
	if f.has("lv") and int(d.get("level", 0)) != int(f["lv"]):
		return false
	if f.has("max_atk") and int(d.get("atk", 0)) > int(f["max_atk"]):
		return false
	if f.has("max_def") and int(d.get("def", 0)) > int(f["max_def"]):
		return false
	if f.has("min_atk") and int(d.get("atk", 0)) < int(f["min_atk"]):
		return false
	return true

