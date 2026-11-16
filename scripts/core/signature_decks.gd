class_name SignatureDecks
## What each duelist in the roster is known for playing: card names only, Main Deck and Extra
## Deck. This is the target their deck in this game is being built toward. A card only goes
## into a deck once its full printed effect works here (see CardExact); `audit()` says, for
## every duelist, which of these are ready, which still need their effect built, and which
## the card database does not have under that name.

const WISH := {
	"yugi": {"main": ["Graceful Charity", "Premature Burial", "Change of Heart", "Call of the Haunted", "Dark Magician", "Dark Magician Girl", "Buster Blader", "Black Luster Soldier", "Magician of Black Chaos", "Summoned Skull", "Gaia The Fierce Knight", "Curse of Dragon",
			"Celtic Guardian", "Obnoxious Celtic Guard", "Kuriboh", "Big Shield Gardna", "Alpha The Magnet Warrior", "Beta The Magnet Warrior", "Gamma The Magnet Warrior", "Valkyrion the Magna Warrior",
			"King's Knight", "Queen's Knight", "Jack's Knight", "Skilled Dark Magician", "Breaker the Magical Warrior", "Watapon", "Marshmallon", "Silent Magician LV4", "Silent Swordsman LV3",
			"Dark Magician of Chaos", "Sangan", "Catapult Turtle", "Giant Soldier of Stone", "Feral Imp", "Mystical Elf", "Beaver Warrior", "Gazelle the King of Mythical Beasts", "Berfomet", "Slifer the Sky Dragon",
			"Swords of Revealing Light", "Monster Reborn", "Polymerization", "Dark Magic Curtain", "Thousand Knives", "Magical Hats", "Multiply", "Mystic Box", "De-Spell", "Brain Control",
			"Card Destruction", "Pot of Greed", "Black Luster Ritual", "Dark Magic Attack", "Mirror Force", "Spellbinding Circle", "Magic Cylinder", "Lightforce Sword", "Chain Destruction", "Silent Swordsman LV5", "Silent Swordsman LV7", "Silent Magician LV8", "Sage's Stone", "Gandora the Dragon of Destruction", "Green Gadget", "Red Gadget", "Yellow Gadget", "Magic Formula", "Dedication through Light and Darkness", "Gold Sarcophagus", "Magician's Valkyria", "Sorcerer of Dark Magic", "Black Magic Ritual"],
		"extra": ["Gaia the Dragon Champion", "Dark Paladin", "Chimera the Flying Mythical Beast", "Arcana Knight Joker"]},
	"kaiba": {"main": ["Heavy Storm", "Premature Burial", "Graceful Charity", "Mirror Force", "Call of the Haunted", "Blue-Eyes White Dragon", "Lord of D.", "Kaibaman", "X-Head Cannon", "Y-Dragon Head", "Z-Metal Tank", "Vorse Raider", "Battle Ox", "La Jinn the Mystical Genie of the Lamp",
			"Saggi the Dark Clown", "Blade Knight", "Kaiser Sea Horse", "Different Dimension Dragon", "Spirit Ryu", "Vampire Lord", "Chaos Emperor Dragon - Envoy of the End", "Luster Dragon",
			"Ryu-Kishin Powered", "Judge Man", "Hitotsu-Me Giant", "Obelisk the Tormentor", "The Flute of Summoning Dragon", "Crush Card Virus", "Shrink", "Enemy Controller", "Negate Attack",
			"Ring of Destruction", "Polymerization", "Monster Reborn", "Soul Exchange", "Cost Down", "Burst Stream of Destruction", "Interdimensional Matter Transporter", "Pot of Greed"],
		"extra": ["Blue-Eyes Ultimate Dragon", "XYZ-Dragon Cannon", "XY-Dragon Cannon", "XZ-Tank Cannon", "YZ-Tank Dragon"]},
	"joey": {"main": ["Graceful Charity", "Premature Burial", "Mirror Force", "Call of the Haunted", "Red-Eyes Black Dragon", "Time Wizard", "Baby Dragon", "Alligator's Sword", "Panther Warrior", "Gearfried the Iron Knight", "Jinzo", "Rocket Warrior", "Axe Raider", "Battle Warrior",
			"Swordsman of Landstar", "Little-Winguard", "Copycat", "Blue Flame Swordsman", "Insect Queen", "The Legendary Fisherman", "Goblin Attack Force", "Scapegoat", "Graceful Dice",
			"Skull Dice", "Kunai with Chain", "Giant Trunade", "Polymerization", "Salamandra", "Shield & Sword", "Fairy Box", "Magical Arm Shield", "Nutrient Z", "Foolish Burial", "Summoned Skull", "Hayabusa Knight", "Reinforcement of the Army", "The Warrior Returning Alive", "Sakuretsu Armor", "Monster Reborn", "Pot of Greed"],
		"extra": ["Flame Swordsman", "Thousand Dragon", "Black Skull Dragon", "Alligator's Sword Dragon"]},
	"mai": {"main": ["Harpie Lady", "Harpie Lady Sisters", "Harpie's Pet Dragon", "Amazoness Swords Woman", "Amazoness Fighter",
			"Amazoness Chain Master", "Dunames Dark Witch", "Birdface", "Harpie's Feather Duster", "Elegant Egotist", "Cyber Shield", "Electro-Whip", "Shadow of Eyes", "Mirror Wall", "Amazoness Archers",
			"Harpies' Hunting Ground", "Gravity Bind", "Monster Reborn"],
		"extra": []},
	"bakura": {"main": ["Sangan", "Monster Reborn", "Pot of Greed", "Graceful Charity", "Dark Hole", "Raigeki", "Premature Burial", "Swords of Revealing Light", "Mirror Force", "Torrential Tribute", "Call of the Haunted", "Dark Necrofear", "Dark Ruler Ha Des", "The Portrait's Secret", "Headless Knight", "The Earl of Demise", "Gernia", "Earthbound Spirit", "Souls of the Forgotten",
			"The Gross Ghost of Fled Dreams", "Man-Eater Bug", "Morphing Jar", "Electric Lizard", "White Magical Hat", "Lady of Faith", "Goblin Zombie", "Diabound Kernel", "Destiny Board",
			"Spirit Message \"I\"", "Spirit Message \"N\"", "Spirit Message \"A\"", "Spirit Message \"L\"", "Dark Sanctuary", "Dark Spirit of the Silent", "Change of Heart", "Just Desserts",
			"Ectoplasmer", "Multiple Destruction", "The Dark Door", "Dark Designator"],
		"extra": []},
	"marik": {"main": ["Lava Golem", "Gil Garth", "Dark Jeroid", "Newdoria", "Helpoemer", "Drillago", "Legendary Fiend", "Viser Des", "Bowganian", "Lord Poison", "Makyura the Destructor", "Revival Jam",
			"Byser Shock", "Melchid the Four-Face Beast", "Juragedo", "Granadora", "The Winged Dragon of Ra", "Jam Breeding Machine", "Jam Defender", "Nightmare Wheel",
			"Coffin Seller", "Malevolent Catastrophe", "Metal Reflect Slime", "Card of Sanctity", "Remove Trap", "Rope of Life", "Left Arm Offering", "Machine Duplication",
			"Vengeful Bog Spirit", "Mirror Force", "Monster Reborn"],
		"extra": []},
	"pegasus": {"main": ["Thousand-Eyes Idol", "Polymerization", "Pot of Greed", "Graceful Charity", "Monster Reborn", "Change of Heart", "Raigeki", "Dark Hole", "Heavy Storm", "Swords of Revealing Light", "Mirror Force", "Magic Cylinder", "Torrential Tribute", "Call of the Haunted", "Ring of Destruction", "Toon World", "Toon Summoned Skull", "Toon Mermaid", "Blue-Eyes Toon Dragon", "Manga Ryu-Ran", "Toon Alligator", "Toon Dark Magician Girl", "Toon Gemini Elf",
			"Toon Goblin Attack Force", "Toon Cannon Soldier", "Toon Masked Sorcerer", "Dark Rabbit", "Parrot Dragon", "Bickuribox", "Relinquished", "Dragon Piper", "Illusionist Faceless Mage",
			"Dark-Eyes Illusionist", "Jigen Bakudan", "Black Illusion Ritual", "Dragon Capture Jar", "Doppelganger", "Copycat", "Toon Table of Contents", "Gorgon's Eye"],
		"extra": ["Thousand-Eyes Restrict"]},
	"weevil": {"main": ["Swords of Revealing Light", "Raigeki", "Dark Hole", "Heavy Storm", "Pot of Greed", "Graceful Charity", "Monster Reborn", "Change of Heart", "Mirror Force", "Magic Cylinder", "Torrential Tribute", "Call of the Haunted", "Insect Queen", "Great Moth", "Perfectly Ultimate Great Moth", "Petit Moth", "Larvae Moth", "Cocoon of Evolution", "Basic Insect", "Hercules Beetle", "Killer Needle", "Big Insect",
			"Gokibore", "Pinch Hopper", "Leghul", "Flying Kamakiri #1", "Kiseitai", "Parasite Paracide", "Insect Soldiers of the Sky", "Man-Eater Bug", "Skull-Mark Ladybug", "Cockroach Knight",
			"Needle Worm", "Insect Barrier", "Multiplication of Ants", "DNA Surgery", "Insect Armor with Laser Cannon", "Eradicating Aerosol"],
		"extra": []},
	"rex": {"main": ["Two-Headed King Rex", "Crawling Dragon #2", "Sword Arm of Dragon", "Megazowler", "Uraby", "Trakodon", "Serpent Night Dragon", "Black Tyranno", "Gilasaurus", "Dark Driceratops",
			"Mad Sword Beast", "Black Stego", "Giant Rex", "Babycerasaurus", "Hyper Hammerhead", "Frostosaurus", "Element Saurus", "Tail Swipe", "Hunting Instinct", "Fossil Excavation",
			"Jurassic World", "Ultra Evolution Pill", "Survival Instinct"],
		"extra": []},
	"jaden": {"main": ["Elemental HERO Avian", "Elemental HERO Burstinatrix", "Elemental HERO Clayman", "Elemental HERO Sparkman", "Elemental HERO Bubbleman", "Elemental HERO Wildheart",
			"Elemental HERO Bladedge", "Elemental HERO Necroshade", "Elemental HERO Neos", "Winged Kuriboh", "Winged Kuriboh LV10", "Wroughtweiler", "Dark Catapulter", "Hero Kid", "Card Trooper",
			"Neo-Spacian Aqua Dolphin", "Neo-Spacian Flare Scarab", "Neo-Spacian Dark Panther", "Neo-Spacian Air Hummingbird", "Neo-Spacian Grand Mole", "Neo-Spacian Glow Moss", "Yubel",
			"Polymerization", "Fusion Gate", "Miracle Fusion", "Skyscraper", "Hero Signal", "A Hero Emerges", "Draining Shield", "Negate Attack", "Mirror Gate", "Feather Shot", "Bubble Shuffle",
			"Burst Return", "Spark Blaster", "R - Righteous Justice", "O - Oversoul", "E - Emergency Call", "H - Heated Heart", "Transcendent Wings", "The Warrior Returning Alive", "Hero Barrier",
			"Edge Hammer", "Common Soul", "Neo Space", "Instant Neo Space", "Pot of Greed", "Monster Reborn", "Fake Hero", "Elemental HERO Neos", "Negate Attack", "Draining Shield"],
		"extra": ["Elemental HERO Flame Wingman", "Elemental HERO Shining Flare Wingman", "Elemental HERO Thunder Giant", "Elemental HERO Tempest", "Elemental HERO Rampart Blaster",
			"Elemental HERO Steam Healer", "Elemental HERO Mudballman", "Elemental HERO Wildedge", "Elemental HERO Wild Wingman", "Elemental HERO Necroid Shaman", "Elemental HERO Mariner",
			"Elemental HERO Electrum", "Elemental HERO Aqua Neos", "Elemental HERO Flare Neos", "Elemental HERO Dark Neos", "Elemental HERO Air Neos", "Elemental HERO Grand Neos",
			"Elemental HERO Glow Neos", "Elemental HERO Storm Neos", "Elemental HERO Magma Neos", "Elemental HERO Divine Neos", "Neos Wiseman"]},
	"chazz": {"main": ["Ojama Yellow", "Ojama Green", "Ojama Black", "Armed Dragon LV3", "Armed Dragon LV5", "Armed Dragon LV7", "Armed Dragon LV10", "X-Head Cannon", "Y-Dragon Head", "Z-Metal Tank",
			"V-Tiger Jet", "W-Wing Catapult", "Chthonian Soldier", "Infernal Incinerator", "Masked Dragon", "Ojama Delta Hurricane!!", "Ojamagic", "Ojama Country", "Ojamuscle", "Level Up!",
			"Chthonian Polymer", "Chthonian Blast", "Chthonian Alliance", "Call of the Haunted", "Ring of Destruction", "Pot of Greed", "Polymerization"],
		"extra": ["Ojama King", "Ojama Knight", "XYZ-Dragon Cannon", "VW-Tiger Catapult", "VWXYZ-Dragon Catapult Cannon"]},
	"zane": {"main": ["Cyber Dragon", "Proto-Cyber Dragon", "Cyber Barrier Dragon", "Cyber Laser Dragon", "Cyber Phoenix", "Cyber Kirin", "Cyberdark Horn", "Cyberdark Edge", "Cyberdark Keel",
			"Infernal Dragon", "Power Bond", "Polymerization", "Future Fusion", "Overload Fusion", "De-Fusion", "Different Dimension Capsule", "Photon Generator Unit", "Attack Reflector Unit",
			"Cyberdark Impact!", "Trap Jammer", "Call of the Haunted", "Limiter Removal", "Heavy Storm", "Pot of Greed"],
		"extra": ["Cyber Twin Dragon", "Cyber End Dragon", "Cyberdark Dragon", "Chimeratech Overdragon"]},
	"alexis": {"main": ["Etoile Cyber", "Blade Skater", "Cyber Tutu", "Cyber Gymnast", "Cyber Prima", "Cyber Angel Benten", "Cyber Angel Idaten", "Cyber Angel Dakini", "Machine Angel Ritual",
			"Doble Passe", "Hallowed Life Barrier", "Polymerization", "Fusion Weapon", "Prima Light", "Ritual Weapon", "Pot of Greed", "Monster Reborn"],
		"extra": ["Cyber Blader"]},
	"syrus": {"main": ["Gyroid", "Steamroid", "Jetroid", "Drillroid", "Patroid", "Submarineroid", "UFOroid", "Truckroid", "Stealthroid", "Expressroid", "Cycroid", "Ambulanceroid", "Rescueroid",
			"Decoyroid", "Armoroid", "Power Bond", "Polymerization", "Vehicroid Connection Zone", "Supercharge", "No Entry!!", "Shield Crush", "Wonder Garage", "Cyber Summon Blaster"],
		"extra": ["Super Vehicroid Jumbo Drill", "Steam Gyroid", "UFOroid Fighter", "Pair Cycroid", "Super Vehicroid - Stealth Union", "Ambulance Rescueroid"]},
	"aster": {"main": ["Destiny HERO - Doom Lord", "Destiny HERO - Captain Tenacious", "Destiny HERO - Diamond Dude", "Destiny HERO - Dreadmaster", "Destiny HERO - Double Dude", "Destiny HERO - Dasher",
			"Destiny HERO - Defender", "Destiny HERO - Dogma", "Destiny HERO - Plasma", "Destiny HERO - Fear Monger", "Destiny HERO - Blade Master", "Destiny HERO - Disk Commander",
			"Destiny HERO - Malicious", "Destiny HERO - Dunker", "Destiny HERO - Departed", "Clock Tower Prison", "D - Time", "D - Spirit", "D - Chain", "D - Shield", "Dark City", "Destiny Signal",
			"Eternal Dread", "Over Destiny", "Destruction of Destiny", "Destiny Draw", "Misfortune", "Ring of Magnetism", "Guard Penalty", "Pot of Greed"],
		"extra": ["Elemental HERO Phoenix Enforcer", "Elemental HERO Shining Phoenix Enforcer", "Destiny End Dragoon"]},
	"yusei": {"main": ["Junk Synchron", "Speed Warrior", "Quillbolt Hedgehog", "Sonic Chick", "Shield Warrior", "Max Warrior", "Turbo Synchron", "Nitro Synchron", "Road Synchron", "Debris Dragon",
			"Tuningware", "Turret Warrior", "Fortress Warrior", "Level Eater", "Hyper Synchron", "Drill Synchron", "Quickdraw Synchron", "Stardust Xiaolong", "Level Warrior",
			"Healing Wave Generator", "Ghost Gardna", "Rockstone Warrior", "Zero Gardna", "Effect Veiler", "Salvage Warrior", "Unknown Synchron", "Boost Warrior", "Synchron Explorer", "Doppelwarrior",
			"Tuning", "One for One", "Double Summon", "Fighting Spirit", "Junk Barrage", "Silver Wing", "Card Rotator", "Graceful Revival", "Scrap-Iron Scarecrow", "Defense Draw", "Limiter Overload",
			"Give and Take", "Equip Shot", "Starlight Road", "Cards of Consonance", "Urgent Tuning", "Synchro Strike", "Shooting Star", "Skill Successor", "Descending Lost Star",
			"Slip Summon", "Confusion Chaff", "Synchro Barrier"],
		"extra": ["Junk Warrior", "Stardust Dragon", "Nitro Warrior", "Turbo Warrior", "Armory Arm", "Road Warrior", "Junk Archer", "Junk Destroyer", "Junk Gardna", "Junk Berserker", "Drill Warrior",
			"Lightning Warrior", "Colossal Fighter", "Majestic Star Dragon", "Formula Synchron", "Shooting Star Dragon", "Shooting Quasar Dragon"]},
	"jack": {"main": ["Dark Resonator", "Vice Dragon", "Mad Archfiend", "Twin-Sword Marauder", "Big Piece Golem", "Medium Piece Golem", "Small Piece Golem", "Sinister Sprocket", "Battle Fader",
			"Power Supplier", "Dread Dragon", "Archfiend Interceptor", "Trust Guardian", "Flare Resonator", "Barrier Resonator", "Clock Resonator", "Force Resonator", "Creation Resonator",
			"Attack Gainer", "Power Breaker", "Trap Eater", "Lancer Archfiend", "Extra Veiler", "Strong Wind Dragon", "Synchro Soldier", "Red Gardna", "Crimson Fire",
			"Fiendish Chain", "Powerful Rebirth", "Changing Destiny", "Nightmare Archfiends", "Prideful Roar", "Half or Nothing", "Lineage of Destruction"],
		"extra": ["Red Dragon Archfiend", "Exploder Dragonwing", "Chaos King Archfiend", "Majestic Red Dragon", "Red Nova Dragon"]},
	"crow": {"main": ["Blackwing - Gale the Whirlwind", "Blackwing - Bora the Spear", "Blackwing - Sirocco the Dawn", "Blackwing - Blizzard the Far North", "Blackwing - Shura the Blue Flame",
			"Blackwing - Kalut the Moon Shadow", "Blackwing - Elphin the Raven", "Blackwing - Mistral the Silver Shield", "Blackwing - Vayu the Emblem of Honor", "Blackwing - Fane the Steel Chain",
			"Blackwing - Ghibli the Searing Wind", "Blackwing - Gust the Backblast", "Blackwing - Breeze the Zephyr", "Blackwing - Zephyros the Elite", "Blackwing - Aurora the Northern Lights",
			"Blackwing - Jetstream the Blue Sky", "Blackwing - Calima the Haze", "Blackwing - Kochi the Daybreak", "Blackwing - Etesian of Two Swords", "Blackwing - Abrolhos the Megaquake",
			"Black Whirlwind", "Delta Crow - Anti Reverse", "Blackwing - Backlash", "Blackwing - Bombardment", "Black Return", "Fake Feather", "Trap Stun", "Black Feather Beacon", "Urgent Tuning",
			"Mirror Force", "Raptor Wing Strike", "Cards for Black Feathers", "Against the Wind", "Black Sonic", "Black Thunder", "Blackback", "Level Retuner", "Blackboost"],
		"extra": ["Blackwing Armor Master", "Blackwing Armed Wing", "Blackwing - Silverwind the Ascendant", "Black-Winged Dragon"]},
	"akiza": {"main": ["Rose Tentacles", "Violet Witch", "Wall of Ivy", "Copy Plant", "Twilight Rose Knight", "Lord Poison", "Evil Thorn", "Phoenixian Seed", "Phoenixian Cluster Amaryllis", "Rose Fairy",
			"Witch of the Black Rose", "Dark Verger", "Hedge Guard", "Blue Rose Dragon", "Lonefire Blossom", "Black Garden", "Seed of Deception", "Mark of the Rose", "Thorn of Malice",
			"Wicked Rebirth", "Ivy Shackles", "Doppelganger", "Plant Food Chain", "Urgent Tuning", "Magic Planter", "Vengeful Servant", "Blossom Bombardment",
			"Nature's Reflection", "Overdoom Line"],
		"extra": ["Black Rose Dragon", "Splendid Rose", "Queen Angel of Roses"]},
	"kalin": {"main": ["Infernity Archfiend", "Infernity Necromancer", "Infernity Beast", "Infernity Beetle", "Infernity Destroyer", "Infernity Dwarf", "Infernity Guardian", "Infernity Knight",
			"Infernity Mirage", "Infernity Avenger", "Infernity Randomizer", "Infernity General", "Infernity Archer", "Dark Tuner Nightmare Hand", "Earthbound Immortal Ccapac Apu",
			"Infernity Launcher", "Infernity Force", "Infernity Inferno", "Infernity Reflector", "Infernity Break", "Infernity Barrier", "ZERO-MAX", "Phantom Hand",
			"Depth Amulet", "Full Salvo", "Void Trap Hole"],
		"extra": ["Infernity Doom Dragon", "Hundred Eyes Dragon", "Void Ogre Dragon", "Gatling Ogre"]},
	"yuma": {"main": ["Gagaga Magician", "Gogogo Golem", "Ganbara Knight", "Zubaba Knight", "Gagaga Girl", "Dododo Warrior", "Goblindbergh", "Kagetokage", "Kurivolt", "Achacha Archer", "Tasuke Knight",
			"Gogogo Giant", "Gagaga Gardna", "Dododo Bot", "Flelf", "Rai Rider", "Bite Bug", "Gagaga Caesar", "Gagaga Child", "Gagaga Clerk", "Gogogo Ghost", "Gogogo Goram", "Dododo Buster",
			"Gagaga Head", "Zubaba Buster", "Gagaga Sister", "Gagaga Mancer", "ZW - Unicorn Spear", "ZW - Phoenix Bow", "ZW - Lightning Blade", "ZW - Tornado Bringer", "ZW - Ultimate Shield",
			"ZW - Eagle Claw", "Double or Nothing!", "Battle Break", "Half Unbreak", "Bye Bye Damage", "Gagagabolt", "Gagagarevenge", "Gagagashield", "Gagagaback", "Xyz Gift", "Blustering Winds",
			"Wonder Wand", "Ego Boost", "Xyz Energy", "Onomatopaira", "Dodododraw", "Gagagatag", "Heartfelt Appeal", "Guard Go!", "Fiery Fervor",
			"Rank-Up-Magic Limited Barian's Force", "Impenetrable Attack"],
		"extra": ["Number 39: Utopia", "Number C39: Utopia Ray", "Number 17: Leviathan Dragon", "Number 34: Terror-Byte", "Number 61: Volcasaurus", "Number 19: Freezadon",
			"Number 12: Crimson Shadow Armor Ninja", "Number 25: Force Focus", "Number 6: Chronomaly Atlandis", "Number 83: Galaxy Queen", "Gagaga Cowboy", "Gagaga Samurai",
			"Number 39: Utopia Roots", "Number C39: Utopia Ray V", "Number 99: Utopic Dragon", "ZW - Leo Arms"]},
	"shark": {"main": ["Big Jaws", "Skull Kraken", "Drill Barnacle", "Needle Sunfish", "Jawsman", "Shocktopus", "Friller Rabca", "Shark Stickers", "Spear Shark", "Double Shark",
			"Hammer Shark", "Tripod Fish", "Hyper-Ancient Shark Megalodon", "Panther Shark", "Eagle Shark", "Saber Shark", "Double Fin Shark", "Depth Shark", "Scrap Shark", "Xyz Remora",
			"Silent Angler", "Cyber Shark", "Mermaid Shark", "Aqua Jet", "Surface", "Big Wave Small Wave", "Poseidon Wave", "Splash Capture", "Bubble Bringer", "Torrential Reborn",
			"Explosive Urchin", "Full-Armored Xyz", "Armored Xyz", "Xyz Unit"],
		"extra": ["Submersible Carrier Aero Shark", "Black Ray Lancer", "Number 17: Leviathan Dragon", "Number 32: Shark Drake", "Number C32: Shark Drake Veiss", "Number 47: Nightmare Shark",
			"Number 71: Rebarian Shark", "Number 73: Abyss Splash", "Number 101: Silent Honor ARK", "Number C101: Silent Honor DARK", "Number 37: Hope Woven Dragon Spider Shark", "Bahamut Shark"]},
	"kite": {"main": ["Galaxy-Eyes Photon Dragon", "Photon Thrasher", "Photon Crusher", "Photon Leo", "Photon Cerberus", "Photon Lizard", "Photon Circle", "Photon Pirate", "Daybreaker", "Photon Wyvern",
			"Photon Sabre Tiger", "Photon Slasher", "Photon Satellite", "Photon Chargeman", "Photon Caesar", "Galaxy Knight", "Galaxy Wizard", "Galaxy Soldier", "Galaxy Dragon",
			"Kuriphoton", "Dimension Wanderer", "Photon Veil", "Photon Sanctuary", "Photon Stream of Destruction", "Photon Lead", "Photon Booster", "Photon Trident", "Photon Current",
			"Galaxy Expedition", "Galaxy Zero", "Galaxy Storm", "Galaxy Queen's Light", "Message in a Bottle", "Triple Star Trion", "Lumenize", "Eternal Galaxy", "Accellight"],
		"extra": ["Neo Galaxy-Eyes Photon Dragon", "Number 62: Galaxy-Eyes Prime Photon Dragon", "Photon Papilloperative", "Starliege Paladynamo", "Starliege Lord Galaxion",
			"Number 10: Illumiknight", "Number 20: Giga-Brilliant", "Number 30: Acid Golem of Destruction", "Number 56: Gold Rat"]},
	"vector": {"main": ["Umbral Horror Ghoul", "Umbral Horror Unform", "Umbral Horror Will o' the Wisp", "Umbral Horror Ghost", "Malicevorous Fork", "Malicevorous Knife", "Malicevorous Spoon",
			"Rank-Up-Magic Barian's Force", "Rank-Up-Magic Limited Barian's Force", "Vain Betrayer", "Don Thousand's Throne", "Mirror Force", "Monster Reborn"],
		"extra": ["Number 66: Master Key Beetle", "Number 104: Masquerade", "Number C104: Umbral Horror Masquerade", "Number 65: Djinn Buster", "Number 43: Manipulator of Souls",
			"Number 96: Dark Mist", "Number C5: Chaos Chimera Dragon"]},
}


## What is changed in each deck today, with the cards that already work here: `out` are cards
## in the deck that are not theirs (stand-ins from before their own cards were built), `in`
## are signature cards that are ready, `extra_in` / `extra_out` the same for the Extra Deck.
## Everyday Spells and Traps (Pot of Greed, Monster Reborn and the like) stay for now where a
## deck would be too thin without them: they go as the duelist's own Spells and Traps get built.
const TUNE := {
	"yugi": {"out": ["Gemini Elf", "Book of Secret Arts", "Yami", "Magic Jammer", "Waboku", "Fissure"],
		"in": {"Dark Magician Girl": 1, "Alpha The Magnet Warrior": 1, "Beta The Magnet Warrior": 1, "Gamma The Magnet Warrior": 1, "Queen's Knight": 1, "Jack's Knight": 1,
			"Breaker the Magical Warrior": 1, "Gazelle the King of Mythical Beasts": 1, "Berfomet": 1, "Brain Control": 1, "Card Destruction": 1, "Monster Reborn": 1, "Spellbinding Circle": 1},
		# Yugi, deck pass (v0.33.36): a real Dark Magician deck (three of each Magician, Skilled Dark Magician x3, Dark Magic Curtain x2), the Magnet Warriors with Valkyrion, Slifer, Dark Magician of Chaos, the three Knights.
		"main": {"Dark Magician": 3, "Dark Magician Girl": 3, "Skilled Dark Magician": 3, "Breaker the Magical Warrior": 1, "Buster Blader": 1, "Dark Magician of Chaos": 1, "Slifer the Sky Dragon": 1, "Queen's Knight": 1, "King's Knight": 1, "Jack's Knight": 1, "Big Shield Gardna": 1, "Marshmallon": 1, "Kuriboh": 1, "Dark Magic Curtain": 2, "Thousand Knives": 1, "Dark Magic Attack": 1, "Sage's Stone": 1, "Polymerization": 1, "Swords of Revealing Light": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Graceful Charity": 1, "Premature Burial": 1, "Change of Heart": 1, "Mirror Force": 1, "Magic Cylinder": 2, "Spellbinding Circle": 1, "Call of the Haunted": 1, "Alpha The Magnet Warrior": 1, "Beta The Magnet Warrior": 1, "Gamma The Magnet Warrior": 1, "Valkyrion the Magna Warrior": 1},
		"extra": {"Dark Paladin": 1, "Arcana Knight Joker": 1}},
	"kaiba": {"out": ["Rude Kaiser", "Koumori Dragon", "Cyber Dragon", "Mystic Tomato", "Mountain", "Dragon Treasure", "Torrential Tribute", "Trap Hole"],
		"in": {"X-Head Cannon": 1, "Y-Dragon Head": 1, "Z-Metal Tank": 1, "Saggi the Dark Clown": 1, "Hitotsu-Me Giant": 1, "Luster Dragon": 2, "Vampire Lord": 1},
		"extra_in": {"XYZ-Dragon Cannon": 1},
		# Kaiba, deck pass (v0.33.36): Blue-Eyes with every way to get it out (Kaibaman x3, Kaiser Sea Horse x3, Lord of D. + Flute, Call of the Haunted), Obelisk, Vampire Lord, Crush Card. The single XYZ pieces and the vanilla filler are out.
		"main": {"Blue-Eyes White Dragon": 3, "Kaibaman": 3, "Lord of D.": 2, "Kaiser Sea Horse": 3, "Vorse Raider": 3, "Blade Knight": 2, "Vampire Lord": 2, "Obelisk the Tormentor": 1, "The Flute of Summoning Dragon": 2, "Burst Stream of Destruction": 1, "Cost Down": 1, "Polymerization": 2, "Monster Reborn": 1, "Pot of Greed": 1, "Enemy Controller": 2, "Shrink": 2, "Heavy Storm": 1, "Premature Burial": 1, "Graceful Charity": 1, "Crush Card Virus": 1, "Ring of Destruction": 1, "Negate Attack": 1, "Mirror Force": 1, "Call of the Haunted": 2},
		"extra": {"Blue-Eyes Ultimate Dragon": 2}},
	"joey": {"out": ["Garoozis", "Battle Steer", "Tiger Axe", "Dian Keto the Cure Master", "Sogen", "Waboku", "Trap Hole"],
		"in": {"Battle Warrior": 1, "Swordsman of Landstar": 2, "Goblin Attack Force": 1, "Salamandra": 1, "Giant Trunade": 1, "Foolish Burial": 1},
		# Joey, deck pass (v0.33.36): Red-Eyes, Jinzo x2, Gearfried x3, Goblin Attack Force x3, his dice and Scapegoat. The weak vanilla Warriors are out.
		"main": {"Red-Eyes Black Dragon": 2, "Jinzo": 2, "Summoned Skull": 1, "Panther Warrior": 2, "Gearfried the Iron Knight": 3, "Rocket Warrior": 2, "Goblin Attack Force": 3, "Baby Dragon": 1, "Time Wizard": 1, "Swordsman of Landstar": 1, "Alligator's Sword": 1, "Scapegoat": 2, "Polymerization": 2, "Graceful Dice": 2, "Giant Trunade": 1, "Foolish Burial": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Graceful Charity": 1, "Reinforcement of the Army": 2, "The Warrior Returning Alive": 1, "Premature Burial": 1, "Skull Dice": 2, "Sakuretsu Armor": 2, "Mirror Force": 1, "Call of the Haunted": 1},
		"extra": {"Thousand Dragon": 1, "Alligator's Sword Dragon": 1, "Black Skull Dragon": 1}},
	"mai": {"out": ["Hinotama", "Dian Keto the Cure Master", "Fissure", "Follow Wind", "Pot of Greed"],
		"in": {"Dunames Dark Witch": 2, "Amazoness Fighter": 2, "Amazoness Swords Woman": 2, "Harpie Lady Sisters": 2, "Elegant Egotist": 3, "Cyber Shield": 2, "Mirror Wall": 1, "Electro-Whip": 1}},
	"bakura": {"out": ["Newdoria", "Curse of Dragon", "Summoned Skull", "Ryu-Kishin", "Lord of the Lamp", "Fissure", "Dark Energy", "Dark Core", "Yami"],
		"in": {"The Portrait's Secret": 1, "Earthbound Spirit": 2, "Souls of the Forgotten": 1, "The Gross Ghost of Fled Dreams": 1, "Man-Eater Bug": 2, "Lady of Faith": 1,
			"Change of Heart": 1, "Just Desserts": 1, "The Dark Door": 1},
		# Bakura, deck pass (v0.33.36): Dark Necrofear x3 with enough Fiends to feed her, Destiny Board, and the old power cards.
		"main": {"Dark Necrofear": 3, "Dark Ruler Ha Des": 2, "Headless Knight": 3, "The Earl of Demise": 2, "Goblin Zombie": 2, "The Portrait's Secret": 2, "Earthbound Spirit": 2, "Morphing Jar": 1, "Man-Eater Bug": 3, "Sangan": 1, "Electric Lizard": 1, "White Magical Hat": 1, "Change of Heart": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Graceful Charity": 1, "Dark Hole": 1, "Raigeki": 1, "Premature Burial": 1, "Swords of Revealing Light": 1, "Destiny Board": 2, "Spirit Message \"I\"": 1, "Spirit Message \"N\"": 1, "Spirit Message \"A\"": 1, "Spirit Message \"L\"": 1, "Mirror Force": 1, "Torrential Tribute": 1, "Call of the Haunted": 1},
		"extra": {}},
	"marik": {"out": ["Dark Blade", "Vampire Lord", "Feral Imp", "Mystic Lamp", "Stone Statue of the Aztecs", "Hinotama", "Mystic Plasma Zone", "Malevolent Nuzzler", "Magic Jammer"],
		"in": {"Legendary Fiend": 1, "Lord Poison": 1, "Melchid the Four-Face Beast": 1, "Newdoria": 2, "Card of Sanctity": 1, "Mirror Force": 1, "Remove Trap": 1},
		# Marik's best deck: Lava Golem, Revival Jam, his Fiends, Nightmare Wheel and The Winged Dragon of Ra (v0.33.34).
		"main": {"Lava Golem": 2, "The Winged Dragon of Ra": 1, "Gil Garth": 3, "Revival Jam": 3, "Drillago": 2, "Bowganian": 2, "Granadora": 2, "Legendary Fiend": 1, "Lord Poison": 1,
			"Melchid the Four-Face Beast": 2, "Newdoria": 3, "Dark Jeroid": 2, "Byser Shock": 1,
			"Card of Sanctity": 2, "Monster Reborn": 1, "Pot of Greed": 1, "Vengeful Bog Spirit": 1, "Remove Trap": 1, "Dark Hole": 1, "Raigeki": 1,
			"Nightmare Wheel": 3, "Jam Defender": 1, "Malevolent Catastrophe": 1, "Mirror Force": 2}},
	"pegasus": {"out": ["Fissure", "Raigeki", "Shadow Spell", "Heavy Storm"], "in": {"Dark Rabbit": 1, "Parrot Dragon": 1, "Illusionist Faceless Mage": 1},
		# Pegasus, deck pass (v0.33.36): the Toons that hit hard, Relinquished, and the old power cards. The vanilla filler is out.
		"main": {"Toon Summoned Skull": 2, "Blue-Eyes Toon Dragon": 2, "Toon Dark Magician Girl": 2, "Toon Gemini Elf": 3, "Toon Mermaid": 3, "Toon Goblin Attack Force": 2, "Toon Cannon Soldier": 1, "Relinquished": 2, "Thousand-Eyes Idol": 1, "Toon World": 3, "Toon Table of Contents": 3, "Black Illusion Ritual": 2, "Polymerization": 1, "Pot of Greed": 1, "Graceful Charity": 1, "Monster Reborn": 1, "Change of Heart": 1, "Raigeki": 1, "Dark Hole": 1, "Heavy Storm": 1, "Swords of Revealing Light": 1, "Mirror Force": 1, "Magic Cylinder": 1, "Torrential Tribute": 1, "Call of the Haunted": 1, "Ring of Destruction": 1},
		"extra": {"Thousand-Eyes Restrict": 2}},
	"weevil": {"out": ["Insect Knight", "Neo Bug", "Gokipon", "Dian Keto the Cure Master", "Just Desserts", "Fissure"],
		"in": {"Big Insect": 2, "Flying Kamakiri #1": 2, "Gokibore": 2, "Man-Eater Bug": 2, "Needle Worm": 1, "Skull-Mark Ladybug": 1},
		# Weevil, deck pass (v0.33.36): the lock (DNA Surgery + Insect Barrier), Insect Queen, Parasite Paracide, and the old power cards. The vanilla Insects are out.
		"main": {"Insect Queen": 2, "Perfectly Ultimate Great Moth": 1, "Petit Moth": 1, "Cocoon of Evolution": 2, "Parasite Paracide": 2, "Pinch Hopper": 3, "Flying Kamakiri #1": 3, "Man-Eater Bug": 3, "Skull-Mark Ladybug": 1, "Leghul": 1, "Killer Needle": 1, "Insect Barrier": 2, "Insect Armor with Laser Cannon": 2, "Multiplication of Ants": 1, "Swords of Revealing Light": 1, "Raigeki": 1, "Dark Hole": 1, "Heavy Storm": 1, "Pot of Greed": 1, "Graceful Charity": 1, "Monster Reborn": 1, "Change of Heart": 1, "DNA Surgery": 3, "Mirror Force": 1, "Magic Cylinder": 1, "Torrential Tribute": 1, "Call of the Haunted": 1},
		"extra": {}},
	"rex": {"out": ["Hinotama", "Dian Keto the Cure Master", "Hammer Shot", "Fissure", "Rush Recklessly"],
		"in": {"Dark Driceratops": 1, "Frostosaurus": 1, "Serpent Night Dragon": 1, "Trakodon": 2, "Black Stego": 2, "Babycerasaurus": 2, "Hyper Hammerhead": 2, "Element Saurus": 2, "Fossil Excavation": 2}},
	# Jaden's best deck: Neos, the Neo-Spacians and Contact Fusion, with the first Elemental HEROes behind them (v0.33.32).
	"jaden": {"out": ["Celtic Guardian"], "in": {"Elemental HERO Bladedge": 1},
		# Jaden's best deck: Neos with the Neo-Spacians and Contact Fusions, the Elemental HEROes for Polymerization (v0.33.32).
		"main": {"Elemental HERO Neos": 3, "Neo-Spacian Grand Mole": 2, "Neo-Spacian Aqua Dolphin": 1, "Neo-Spacian Flare Scarab": 1, "Neo-Spacian Air Hummingbird": 1, "Neo-Spacian Glow Moss": 1, "Neo-Spacian Dark Panther": 1, "Elemental HERO Sparkman": 2, "Elemental HERO Avian": 1, "Elemental HERO Burstinatrix": 1, "Elemental HERO Clayman": 1, "Elemental HERO Bubbleman": 1, "Elemental HERO Wildheart": 1, "Elemental HERO Bladedge": 1, "Elemental HERO Necroshade": 1, "Card Trooper": 1, "Winged Kuriboh": 1, "Polymerization": 2, "Miracle Fusion": 1, "Fake Hero": 2, "O - Oversoul": 2, "E - Emergency Call": 2, "Neo Space": 2, "Instant Neo Space": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Hero Signal": 2, "A Hero Emerges": 1, "Negate Attack": 1, "Draining Shield": 1},
		"extra": {"Elemental HERO Grand Neos": 1, "Elemental HERO Flare Neos": 1, "Elemental HERO Glow Neos": 1, "Elemental HERO Air Neos": 1, "Elemental HERO Aqua Neos": 1, "Elemental HERO Dark Neos": 1, "Elemental HERO Magma Neos": 1, "Elemental HERO Storm Neos": 1, "Elemental HERO Flame Wingman": 1, "Elemental HERO Shining Flare Wingman": 1, "Elemental HERO Thunder Giant": 1, "Elemental HERO Tempest": 1, "Elemental HERO Rampart Blaster": 1, "Elemental HERO Wildedge": 1, "Elemental HERO Necroid Shaman": 1}},
	"chazz": {"out": ["Dragon Treasure", "Rush Recklessly"], "in": {"Masked Dragon": 2, "V-Tiger Jet": 1},
		# Chazz's best deck: the Armed Dragons up to LV10, the Ojamas with Ojama King, and VWXYZ (v0.33.35).
		"main": {"Armed Dragon LV3": 3, "Armed Dragon LV5": 2, "Armed Dragon LV7": 2, "Armed Dragon LV10": 1, "Masked Dragon": 2, "X-Head Cannon": 2, "Y-Dragon Head": 2, "Z-Metal Tank": 2, "V-Tiger Jet": 1, "W-Wing Catapult": 1, "Ojama Yellow": 2, "Ojama Green": 2, "Ojama Black": 2, "Chthonian Soldier": 1, "Level Up!": 2, "Ojamagic": 2, "Ojama Delta Hurricane!!": 1, "Ojamuscle": 1, "Polymerization": 2, "Pot of Greed": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 2, "Heavy Storm": 1, "Call of the Haunted": 1, "Ring of Destruction": 1},
		"extra": {"XYZ-Dragon Cannon": 1, "VW-Tiger Catapult": 1, "VWXYZ-Dragon Catapult Cannon": 1, "Ojama King": 1}},
	"zane": {"out": ["X-Head Cannon", "Elemental HERO Burstinatrix", "Charcoal Inpachi", "Millennium Shield"], "in": {"Call of the Haunted": 1},
		# Zane's best deck: Cyber Dragon into Cyber Twin and Cyber End with Power Bond, Limiter Removal and De-Fusion (v0.33.35).
		"main": {"Cyber Dragon": 3, "Proto-Cyber Dragon": 3, "Cyber Phoenix": 3, "Cyber Kirin": 2, "Cyber Larva": 3, "Cyber Laser Dragon": 1, "Cyber Barrier Dragon": 1, "Polymerization": 3, "Power Bond": 3, "Limiter Removal": 1, "De-Fusion": 2, "Photon Generator Unit": 1, "Different Dimension Capsule": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 2, "Heavy Storm": 1, "Raigeki": 1, "Attack Reflector Unit": 1, "Trap Jammer": 2, "Call of the Haunted": 2, "Mirror Force": 1, "Negate Attack": 1},
		"extra": {"Cyber Twin Dragon": 2, "Cyber End Dragon": 2}},
	"alexis": {"out": ["Dian Keto the Cure Master", "Luminous Spark", "Horn of the Unicorn", "Fissure", "Cyber Petit Angel"],
		"in": {"Hallowed Life Barrier": 1, "Machine Angel Ritual": 3, "Fusion Weapon": 1, "Ritual Weapon": 2}, "extra_in": {"Cyber Blader": 2}},
	"syrus": {"out": ["Elemental HERO Clayman", "Dian Keto the Cure Master"], "in": {"Shield Crush": 1},
		# Syrus's best deck: the Vehicroids with Power Bond into Super Vehicroid Jumbo Drill (v0.33.35).
		"main": {"Steamroid": 3, "Drillroid": 3, "Gyroid": 2, "Submarineroid": 3, "Expressroid": 2, "UFOroid": 2, "Cycroid": 2, "Stealthroid": 2, "Decoyroid": 1, "Rescueroid": 1, "Armoroid": 1, "Polymerization": 3, "Power Bond": 3, "Pot of Greed": 1, "Monster Reborn": 1, "Mystical Space Typhoon": 1, "Limiter Removal": 1, "Heavy Storm": 1, "No Entry!!": 2, "Supercharge": 2, "Negate Attack": 1, "Draining Shield": 1, "Shield Crush": 1},
		"extra": {"Steam Gyroid": 2, "Super Vehicroid Jumbo Drill": 2}},
	"aster": {"out": ["Celtic Guardian", "Mystic Plasma Zone"],
		# Aster's best deck: the Destiny HEROes with Plasma and Dogma (v0.33.35).
		"main": {"Destiny HERO - Plasma": 1, "Destiny HERO - Dogma": 1, "Destiny HERO - Doom Lord": 2, "Destiny HERO - Dasher": 2, "Destiny HERO - Defender": 3, "Destiny HERO - Captain Tenacious": 2, "Destiny HERO - Malicious": 3, "Destiny HERO - Dunker": 2, "Destiny HERO - Disk Commander": 2, "Destiny Draw": 3, "D - Spirit": 2, "Dark City": 2, "Misfortune": 1, "Pot of Greed": 1, "Monster Reborn": 2, "Dark Hole": 1, "Mystical Space Typhoon": 1, "Destiny Signal": 3, "Ring of Destruction": 1, "Mirror Force": 1, "Call of the Haunted": 2, "Negate Attack": 2},
		"extra": {}},
	# Yusei's best deck: the Shooting Star Dragon and Shooting Quasar Dragon one (v0.33.28).
	"yusei": {"out": ["Celtic Guardian", "Beaver Warrior"],
		"main": {"Junk Synchron": 3, "Quickdraw Synchron": 2, "Debris Dragon": 2, "Effect Veiler": 2, "Speed Warrior": 2, "Max Warrior": 2, "Quillbolt Hedgehog": 3, "Doppelwarrior": 3, "Level Eater": 2, "Synchron Explorer": 2, "Tuningware": 2, "Shield Warrior": 1, "Sonic Chick": 1, "Tuning": 3, "One for One": 1, "Double Summon": 1, "Cards of Consonance": 1, "Scrap-Iron Scarecrow": 3, "Starlight Road": 1, "Graceful Revival": 1, "Shooting Star": 1, "Defense Draw": 1},
		# (v0.33.35: 9 Tuners instead of 13, no single-copy Synchrons, 2 Stardust Dragon and 2 Junk Warrior)
		"extra": {"Stardust Dragon": 2, "Shooting Star Dragon": 1, "Shooting Quasar Dragon": 1, "Formula Synchron": 1, "Junk Warrior": 2, "Junk Destroyer": 1, "Junk Archer": 1, "Junk Berserker": 1, "Junk Gardna": 1, "Road Warrior": 1, "Turbo Warrior": 1, "Nitro Warrior": 1, "Lightning Warrior": 1}},
	# Jack's best deck: Red Dragon Archfiend on Resonators, with Exploder Dragonwing and Chaos King Archfiend beside it (v0.33.33).
	"jack": {"out": ["Molten Destruction", "Salamandra"],
		# Jack's best deck (v0.33.36): Resonators into Red Dragon Archfiend, then two more Tuners for Red Nova Dragon.
		"main": {"Dark Resonator": 3, "Flare Resonator": 2, "Creation Resonator": 2, "Chain Resonator": 2, "Synkron Resonator": 1, "Dread Dragon": 1, "Vice Dragon": 3, "Mad Archfiend": 2, "Big Piece Golem": 2, "Medium Piece Golem": 1, "Power Breaker": 2, "Strong Wind Dragon": 2, "Twin-Sword Marauder": 2, "Archfiend Interceptor": 1, "Battle Fader": 1, "Resonator Call": 3, "Scarlet Security": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Mystical Space Typhoon": 1, "Fiendish Chain": 2, "Powerful Rebirth": 2, "Call of the Haunted": 1, "Half or Nothing": 1},
		"extra": {"Red Dragon Archfiend": 2, "Scarlight Red Dragon Archfiend": 1, "Red Nova Dragon": 2, "Exploder Dragonwing": 1, "Chaos King Archfiend": 1}},
	# Crow's best deck: the Blackwing swarm with Black Whirlwind, into Armor Master, Silverwind and Black-Winged Dragon (v0.33.33).
	"crow": {"out": ["Curse of Dragon", "Dian Keto the Cure Master", "Follow Wind"],
		"main": {"Blackwing - Gale the Whirlwind": 3, "Blackwing - Bora the Spear": 3, "Blackwing - Shura the Blue Flame": 3, "Blackwing - Blizzard the Far North": 3,
			"Blackwing - Kalut the Moon Shadow": 3, "Blackwing - Sirocco the Dawn": 2, "Blackwing - Elphin the Raven": 1, "Blackwing - Fane the Steel Chain": 1,
			"Blackwing - Mistral the Silver Shield": 2, "Blackwing - Gust the Backblast": 1, "Blackwing - Ghibli the Searing Wind": 1,
			"Black Whirlwind": 3, "Against the Wind": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Mystical Space Typhoon": 2,
			"Blackwing - Backlash": 1, "Blackback": 2, "Trap Stun": 1, "Urgent Tuning": 1, "Mirror Force": 2, "Sakuretsu Armor": 2},
		"extra": {"Blackwing Armor Master": 2, "Blackwing Armed Wing": 2, "Blackwing - Silverwind the Ascendant": 1, "Black-Winged Dragon": 1}},
	# Akiza's best deck: Black Rose Dragon on a Plant base, with Amaryllis, Queen Angel of Roses and Thorn of Malice (v0.33.33).
	"akiza": {"out": ["Vile Germs", "Forest"],
		"main": {"Twilight Rose Knight": 3, "Witch of the Black Rose": 2, "Copy Plant": 2, "Lonefire Blossom": 2, "Rose Tentacles": 2, "Lord Poison": 2, "Evil Thorn": 2,
			"Dark Verger": 2, "Violet Witch": 2, "Rose Fairy": 2, "Phoenixian Seed": 2, "Phoenixian Cluster Amaryllis": 2, "Blue Rose Dragon": 1, "Queen Angel of Roses": 1,
			"Seed of Deception": 1, "Thorn of Malice": 2, "Monster Reborn": 1, "Pot of Greed": 1, "Mystical Space Typhoon": 1,
			"Wicked Rebirth": 2, "Blossom Bombardment": 1, "Urgent Tuning": 1, "Mirror Force": 1, "Sakuretsu Armor": 2},
		"extra": {"Black Rose Dragon": 2, "Splendid Rose": 1}},
	# Kalin's best deck: Infernity with an empty hand, into Infernity Doom Dragon, Void Ogre Dragon and Hundred Eyes Dragon (v0.33.33).
	"kalin": {"out": ["Hinotama", "Mystic Plasma Zone", "Dark Energy"],
		"main": {"Infernity Archfiend": 3, "Infernity Necromancer": 3, "Infernity Beast": 2, "Infernity Dwarf": 1, "Infernity Guardian": 2, "Infernity Knight": 2, "Infernity Mirage": 2,
			"Infernity Avenger": 2, "Infernity Beetle": 3, "Infernity Destroyer": 2, "Infernity Randomizer": 1, "Infernity Archer": 2,
			"Monster Reborn": 1, "Pot of Greed": 1, "Mystical Space Typhoon": 2, "Card Destruction": 1,
			"Infernity Inferno": 2, "Infernity Break": 2, "Infernity Barrier": 2, "Infernity Force": 2, "Void Trap Hole": 1, "Mirror Force": 1},
		"extra": {"Infernity Doom Dragon": 2, "Void Ogre Dragon": 1, "Hundred Eyes Dragon": 1}},
	"yuma": {"out": ["Celtic Guardian", "Beaver Warrior", "Battle Ox", "Masaki the Legendary Swordsman", "Silver Fang", "Dian Keto the Cure Master", "Lightning Blade", "Trap Hole"],
		"in": {"Achacha Archer": 2}, "extra_in": {"Number 17: Leviathan Dragon": 1},
		# Yuma's best deck: Utopia and its ranked-up forms on a Gagaga / Gogogo / Dododo / Zubaba base (v0.33.32).
		"main": {"Gagaga Magician": 3, "Gagaga Girl": 2, "Gogogo Golem": 3, "Gogogo Giant": 2, "Zubaba Knight": 2, "Goblindbergh": 3, "Kagetokage": 2,
			"Ganbara Knight": 1, "Dododo Warrior": 2, "Gagaga Gardna": 1, "Tasuke Knight": 1, "Achacha Archer": 1,
			"Gagagabolt": 2, "Onomatopaira": 2, "Gagagarevenge": 2, "Xyz Energy": 1, "Blustering Winds": 1, "Rank-Up-Magic Limited Barian's Force": 2,
			"Monster Reborn": 1, "Ego Boost": 1, "Pot of Greed": 1,
			"Half Unbreak": 2, "Battle Break": 1, "Bye Bye Damage": 1},
		"extra": {"Number 39: Utopia": 2, "Number C39: Utopia Ray": 1, "Number C39: Utopia Ray V": 1, "Gagaga Samurai": 1, "Gagaga Cowboy": 1,
			"Number 61: Volcasaurus": 1, "Number 17: Leviathan Dragon": 1}},
	# Shark's best deck: the WATER swarm into Bahamut Shark, Nightmare Shark, Shark Drake and Black Ray Lancer (v0.33.34).
	"shark": {"out": ["Dian Keto the Cure Master", "Steel Shell"], "in": {"Hyper-Ancient Shark Megalodon": 1},
		"main": {"Big Jaws": 2, "Skull Kraken": 2, "Shark Stickers": 2, "Spear Shark": 2, "Double Shark": 2, "Hammer Shark": 3, "Eagle Shark": 2, "Panther Shark": 2,
			"Hyper-Ancient Shark Megalodon": 1, "Cyber Shark": 2, "Silent Angler": 2, "Mermaid Shark": 1, "Needle Sunfish": 2, "Drill Barnacle": 1, "Jawsman": 1,
			"Aqua Jet": 2, "Surface": 2, "Monster Reborn": 1, "Pot of Greed": 1, "Mystical Space Typhoon": 2,
			"Mirror Force": 1, "Sakuretsu Armor": 2, "Call of the Haunted": 1, "Torrential Tribute": 1},
		"extra": {"Bahamut Shark": 2, "Number 32: Shark Drake": 1, "Black Ray Lancer": 2, "Number 17: Leviathan Dragon": 1, "Number 47: Nightmare Shark": 1, "Submersible Carrier Aero Shark": 1}},
	# Kite's best deck: Galaxy-Eyes Photon Dragon with every Photon and Galaxy way to bring it out, and Starliege Lord Galaxion to fetch it (v0.33.34).
	"kite": {"out": ["Luminous Spark"], "in": {"Galaxy Zero": 1},
		"main": {"Galaxy-Eyes Photon Dragon": 3, "Photon Thrasher": 3, "Photon Crusher": 2, "Photon Lizard": 2, "Photon Cerberus": 1, "Photon Leo": 1, "Photon Sabre Tiger": 2,
			"Galaxy Knight": 2, "Galaxy Soldier": 2, "Galaxy Wizard": 2, "Photon Slasher": 2, "Photon Caesar": 2, "Photon Wyvern": 1, "Photon Pirate": 1, "Daybreaker": 2,
			"Photon Circle": 1, "Photon Chargeman": 1,
			"Accellight": 2, "Galaxy Expedition": 2, "Photon Lead": 1, "Galaxy Storm": 1, "Galaxy Zero": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Mirror Force": 1},
		"extra": {"Neo Galaxy-Eyes Photon Dragon": 1, "Number 62: Galaxy-Eyes Prime Photon Dragon": 2, "Starliege Lord Galaxion": 2, "Starliege Paladynamo": 1, "Photon Papilloperative": 1, "Number 10: Illumiknight": 1}},
	"vector": {"out": ["Charcoal Inpachi", "Archfiend Soldier", "Summoned Skull", "Ryu-Kishin Powered", "Vorse Raider", "Hinotama", "Mystic Plasma Zone", "Malevolent Nuzzler"],
		"in": {"Mirror Force": 1}, "extra_out": ["Gagaga Cowboy"],
		# Vector's best deck: Umbral Horrors and Malicevorous Fiends into Masquerade, ranked up with Barian's Force (v0.33.34).
		"main": {"Umbral Horror Ghoul": 3, "Umbral Horror Unform": 3, "Umbral Horror Will o' the Wisp": 3, "Umbral Horror Ghost": 3, "Malicevorous Fork": 3, "Malicevorous Knife": 3,
			"Archfiend Soldier": 3, "Summoned Skull": 1,
			"Rank-Up-Magic Barian's Force": 2, "Rank-Up-Magic Limited Barian's Force": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Dark Hole": 1, "Fissure": 2, "Mystical Space Typhoon": 2,
			"Mirror Force": 2, "Shadow Spell": 2, "Dark Bribe": 2, "Sakuretsu Armor": 2},
		"extra": {"Number 104: Masquerade": 2, "Number C104: Umbral Horror Masquerade": 1, "Number 65: Djinn Buster": 1, "Number 96: Dark Mist": 1}},
}


## Does this card really work here? A monster with an effect has to be on the exact list (a
## monster nobody has written rules for would otherwise pass as "has no effect"); a Spell or
## Trap has to have rules of its own.
static func _works(id: int) -> bool:
	var d := CardData.get_card(id)
	if d.is_empty() or not CardExact.ok(d):
		return false
	var name := str(d.get("name", ""))
	if str(d.get("kind", "monster")) != "monster":
		return SpellRules.FX.has(name) or str(d.get("effect", "")) != ""
	if str(d.get("frame", "")) == "normal" or CardExact.MONSTERS.has(name):
		return true
	# A Fusion or Ritual Monster whose text is only how to summon it.
	return str(d.get("frame", "")) in ["fusion", "ritual"] and not CardEffects.has(name) and _only_summon_text(d)


## Is this Fusion or Ritual Monster's text nothing but its materials, or which Ritual Spell
## summons it? ("Gaia The Fierce Knight" + "Curse of Dragon"; You can Ritual Summon this card
## with "Black Luster Ritual".) Anything more is an effect, and an effect needs rules.
static func _only_summon_text(d: Dictionary) -> bool:
	var text := str(d.get("desc", d.get("text", "")))
	var paren := RegEx.new()
	paren.compile("\\([^)]*\\)")
	text = paren.sub(text, "", true).strip_edges()
	if str(d.get("frame", "")) == "ritual":
		var rit := RegEx.new()
		rit.compile("^You can Ritual Summon this card with \"[^\"]+\"\\.?$")
		return rit.search(text) != null
	return not text.contains(".") and text.contains("+")


static func _ids(names: Array) -> Dictionary:
	var out := {}
	for n in names:
		var id: int = CardData.NAME_TO_ID.get(str(n).to_lower(), 0)
		if id != 0:
			out[id] = true
	return out


## A deck's Main Deck after today's changes. A stand-in only leaves if the deck still makes
## forty without it (the rest is topped up with further copies of the duelist's own cards).
## The duelist a deck belongs to ("yusei" for the deck "yusei"), or "" when it is nobody's.
static func owner(deck_key: String) -> String:
	for k in WISH:
		if str(Characters.get_char(str(k)).get("deck", "")) == deck_key:
			return str(k)
	return ""


## Is this deck in somebody else's hands? A street duelist or a Rare Hunter who plays "Yusei's
## deck" plays the plain version: the written-out deck with the aces in it is Yusei's alone.
static func borrowed(deck_key: String, who_key: String) -> bool:
	var own := owner(deck_key)
	return own != "" and own != who_key and TUNE.get(deck_key, {}).has("main")


static func tune(deck_key: String, list: Array[int], plain := false) -> Array[int]:
	if not TUNE.has(deck_key) or list.is_empty():
		return list
	var t: Dictionary = TUNE[deck_key]
	var gone := _ids(t.get("out", []))
	if t.has("main") and not plain:
		# The whole deck is written out: exactly these cards, as many of each as it says. A card
		# that is not in this copy of the card folder (or does not work yet) leaves a gap, and the
		# gap is filled from the old list.
		var built: Array[int] = []
		for n in t["main"]:
			var id3: int = CardData.NAME_TO_ID.get(str(n).to_lower(), 0)
			if id3 == 0 or not _works(id3):
				continue
			for k in mini(3, int(t["main"][n])):
				built.append(id3)
		for id in list:
			if built.size() >= CardData.MIN_DECK:
				break
			if not gone.has(id) and built.count(id) < 3:
				built.append(id)
		if built.size() >= CardData.MIN_DECK:
			return built
	var kept: Array[int] = []
	var removed: Array[int] = []
	for id in list:
		if gone.has(id):
			removed.append(id)
		else:
			kept.append(id)
	var add: Dictionary = t.get("in", {})
	for n in add:
		var id2: int = CardData.NAME_TO_ID.get(str(n).to_lower(), 0)
		if id2 == 0 or not _works(id2):
			continue
		var have := kept.count(id2)
		for k in maxi(0, mini(3, int(add[n])) - have):
			kept.append(id2)
	kept = CardData.to_forty(kept)
	while kept.size() < CardData.MIN_DECK and not removed.is_empty():
		kept.append(removed.pop_front())
	return kept


static func tune_extra(deck_key: String, list: Array[int], plain := false) -> Array[int]:
	if not TUNE.has(deck_key):
		return list
	var t: Dictionary = TUNE[deck_key]
	var gone := _ids(t.get("extra_out", []))
	if t.has("extra") and not plain:
		var whole: Array[int] = []
		for n in t["extra"]:
			var id3: int = CardData.NAME_TO_ID.get(str(n).to_lower(), 0)
			if id3 == 0 or not _works(id3):
				continue
			for k in int(t["extra"][n]):
				if whole.size() < 15:
					whole.append(id3)
		if whole.size() >= 1:
			return whole
	var out: Array[int] = []
	for id in list:
		if not gone.has(id):
			out.append(id)
	var add: Dictionary = t.get("extra_in", {})
	for n in add:
		var id2: int = CardData.NAME_TO_ID.get(str(n).to_lower(), 0)
		if id2 == 0 or not _works(id2) or out.has(id2):
			continue
		for k in int(add[n]):
			out.append(id2)
	return out


## Where one duelist's deck stands. Returns:
##   {"plays": [names in the deck now], "stand_ins": [names in the deck now that are not theirs],
##    "ready": [signature cards that work here but are not in the deck yet],
##    "need_effect": [in the card database, effect not built yet],
##    "unknown": [not in the card database under that name], "in": [signature cards in the deck now]}
static func audit(key: String) -> Dictionary:
	var out := {"plays": [], "stand_ins": [], "ready": [], "need_effect": [], "unknown": [], "in": []}
	var info := Characters.get_char(key)
	var deck := str(info.get("deck", ""))
	if not WISH.has(key) or not CardData.has_deck(deck):
		return out
	var wish: Dictionary = WISH[key]
	var theirs := {}
	for n in (wish["main"] as Array) + (wish["extra"] as Array):
		theirs[str(n).to_lower()] = true
	var now := {}
	for id in Array(CardData.deck_list(deck)) + CardData.extra_list(deck):
		var nm := str(CardData.get_card(int(id)).get("name", "?"))
		if not now.has(nm.to_lower()):
			now[nm.to_lower()] = true
			(out["plays"] as Array).append(nm)
			if not theirs.has(nm.to_lower()):
				(out["stand_ins"] as Array).append(nm)
	for n in theirs:
		var id2: int = CardData.NAME_TO_ID.get(str(n), 0)
		var shown := str(CardData.get_card(id2).get("name", n)) if id2 != 0 else ""
		if id2 == 0:
			# Find the name as it was written in the list (the key is lower case).
			for w in (wish["main"] as Array) + (wish["extra"] as Array):
				if str(w).to_lower() == str(n):
					shown = str(w)
			(out["unknown"] as Array).append(shown)
		elif now.has(str(n)):
			(out["in"] as Array).append(shown)
		elif _works(id2):
			(out["ready"] as Array).append(shown)
		else:
			(out["need_effect"] as Array).append(shown)
	for k in ["in", "ready", "need_effect", "unknown"]:
		(out[k] as Array).sort()
	return out
