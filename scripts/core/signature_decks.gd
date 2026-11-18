class_name SignatureDecks
## What each duelist in the roster is known for playing: card names only, Main Deck and Extra
## Deck. This is the target their deck in this game is being built toward. A card only goes
## into a deck once its full printed effect works here (see CardExact); `audit()` says, for
## every duelist, which of these are ready, which still need their effect built, and which
## the card database does not have under that name.

const WISH := {
	"yugi": {"main": ["Knight's Title", "Dark Magician Knight", "Graceful Charity", "Premature Burial", "Change of Heart", "Call of the Haunted", "Dark Magician", "Dark Magician Girl", "Buster Blader", "Black Luster Soldier", "Magician of Black Chaos", "Summoned Skull", "Gaia The Fierce Knight", "Curse of Dragon",
			"Celtic Guardian", "Obnoxious Celtic Guard", "Kuriboh", "Big Shield Gardna", "Alpha The Magnet Warrior", "Beta The Magnet Warrior", "Gamma The Magnet Warrior", "Valkyrion the Magna Warrior",
			"King's Knight", "Queen's Knight", "Jack's Knight", "Skilled Dark Magician", "Breaker the Magical Warrior", "Watapon", "Marshmallon", "Silent Magician LV4", "Silent Swordsman LV3",
			"Dark Magician of Chaos", "Sangan", "Catapult Turtle", "Giant Soldier of Stone", "Feral Imp", "Mystical Elf", "Beaver Warrior", "Gazelle the King of Mythical Beasts", "Berfomet", "Slifer the Sky Dragon",
			"Swords of Revealing Light", "Monster Reborn", "Polymerization", "Dark Magic Curtain", "Thousand Knives", "Magical Hats", "Multiply", "Mystic Box", "De-Spell", "Brain Control",
			"Card Destruction", "Pot of Greed", "Black Luster Ritual", "Dark Magic Attack", "Mirror Force", "Spellbinding Circle", "Magic Cylinder", "Lightforce Sword", "Chain Destruction", "Silent Swordsman LV5", "Silent Swordsman LV7", "Silent Magician LV8", "Sage's Stone", "Gandora the Dragon of Destruction", "Green Gadget", "Red Gadget", "Yellow Gadget", "Magic Formula", "Dedication through Light and Darkness", "Gold Sarcophagus", "Magician's Valkyria", "Sorcerer of Dark Magic", "Black Magic Ritual"],
		"extra": ["Gaia the Dragon Champion", "Dark Paladin", "Chimera the Flying Mythical Beast", "Arcana Knight Joker"]},
	"kaiba": {"main": ["Blue-Eyes Shining Dragon", "Heavy Storm", "Premature Burial", "Graceful Charity", "Mirror Force", "Call of the Haunted", "Blue-Eyes White Dragon", "Lord of D.", "Kaibaman", "X-Head Cannon", "Y-Dragon Head", "Z-Metal Tank", "Vorse Raider", "Battle Ox", "La Jinn the Mystical Genie of the Lamp",
			"Saggi the Dark Clown", "Blade Knight", "Kaiser Sea Horse", "Different Dimension Dragon", "Spirit Ryu", "Vampire Lord", "Chaos Emperor Dragon - Envoy of the End", "Luster Dragon",
			"Ryu-Kishin Powered", "Judge Man", "Hitotsu-Me Giant", "Obelisk the Tormentor", "The Flute of Summoning Dragon", "Crush Card Virus", "Shrink", "Enemy Controller", "Negate Attack",
			"Ring of Destruction", "Polymerization", "Monster Reborn", "Soul Exchange", "Cost Down", "Burst Stream of Destruction", "Interdimensional Matter Transporter", "Pot of Greed"],
		"extra": ["Blue-Eyes Ultimate Dragon", "XYZ-Dragon Cannon", "XY-Dragon Cannon", "XZ-Tank Cannon", "YZ-Tank Dragon"]},
	"joey": {"main": ["Metalmorph", "Red-Eyes Black Metal Dragon", "Gilford the Lightning", "Release Restraint", "Gearfried the Swordmaster", "Graceful Charity", "Premature Burial", "Mirror Force", "Call of the Haunted", "Red-Eyes Black Dragon", "Time Wizard", "Baby Dragon", "Alligator's Sword", "Panther Warrior", "Gearfried the Iron Knight", "Jinzo", "Rocket Warrior", "Axe Raider", "Battle Warrior",
			"Swordsman of Landstar", "Little-Winguard", "Copycat", "Blue Flame Swordsman", "Insect Queen", "The Legendary Fisherman", "Goblin Attack Force", "Scapegoat", "Graceful Dice",
			"Skull Dice", "Kunai with Chain", "Giant Trunade", "Polymerization", "Salamandra", "Shield & Sword", "Fairy Box", "Magical Arm Shield", "Nutrient Z", "Foolish Burial", "Summoned Skull", "Hayabusa Knight", "Reinforcement of the Army", "The Warrior Returning Alive", "Sakuretsu Armor", "Monster Reborn", "Pot of Greed"],
		"extra": ["Flame Swordsman", "Thousand Dragon", "Black Skull Dragon", "Alligator's Sword Dragon"]},
	"mai": {"main": ["Harpie Queen", "Harpie Channeler", "Amazoness Paladin", "Harpie Girl", "Harpie Lady Phoenix Formation", "Triangle Ecstasy Spark", "Pot of Greed", "Hysteric Party", "Mirror Force", "Call of the Haunted", "Harpie Lady", "Harpie Lady Sisters", "Harpie's Pet Dragon", "Amazoness Swords Woman", "Amazoness Fighter",
			"Amazoness Chain Master", "Dunames Dark Witch", "Birdface", "Harpie's Feather Duster", "Elegant Egotist", "Cyber Shield", "Electro-Whip", "Shadow of Eyes", "Mirror Wall", "Amazoness Archers",
			"Harpies' Hunting Ground", "Gravity Bind", "Monster Reborn"],
		"extra": []},
	"bakura": {"main": ["Sangan", "Monster Reborn", "Pot of Greed", "Graceful Charity", "Dark Hole", "Raigeki", "Premature Burial", "Swords of Revealing Light", "Mirror Force", "Torrential Tribute", "Call of the Haunted", "Dark Necrofear", "Dark Ruler Ha Des", "The Portrait's Secret", "Headless Knight", "The Earl of Demise", "Gernia", "Earthbound Spirit", "Souls of the Forgotten",
			"The Gross Ghost of Fled Dreams", "Man-Eater Bug", "Morphing Jar", "Electric Lizard", "White Magical Hat", "Lady of Faith", "Goblin Zombie", "Diabound Kernel", "Destiny Board",
			"Spirit Message \"I\"", "Spirit Message \"N\"", "Spirit Message \"A\"", "Spirit Message \"L\"", "Dark Sanctuary", "Dark Spirit of the Silent", "Change of Heart", "Just Desserts",
			"Ectoplasmer", "Multiple Destruction", "The Dark Door", "Dark Designator"],
		"extra": []},
	"marik": {"main": ["Pot of Greed", "Dark Hole", "Raigeki", "Call of the Haunted", "Torrential Tribute", "Lava Golem", "Gil Garth", "Dark Jeroid", "Newdoria", "Helpoemer", "Drillago", "Legendary Fiend", "Viser Des", "Bowganian", "Lord Poison", "Makyura the Destructor", "Revival Jam",
			"Byser Shock", "Melchid the Four-Face Beast", "Juragedo", "Granadora", "The Winged Dragon of Ra", "Jam Breeding Machine", "Jam Defender", "Nightmare Wheel",
			"Coffin Seller", "Malevolent Catastrophe", "Metal Reflect Slime", "Card of Sanctity", "Remove Trap", "Rope of Life", "Left Arm Offering", "Machine Duplication",
			"Vengeful Bog Spirit", "Mirror Force", "Monster Reborn"],
		"extra": []},
	"pegasus": {"main": ["Mystical Space Typhoon", "Sakuretsu Armor", "Thousand-Eyes Idol", "Polymerization", "Pot of Greed", "Graceful Charity", "Monster Reborn", "Change of Heart", "Raigeki", "Dark Hole", "Heavy Storm", "Swords of Revealing Light", "Mirror Force", "Magic Cylinder", "Torrential Tribute", "Call of the Haunted", "Ring of Destruction", "Toon World", "Toon Summoned Skull", "Toon Mermaid", "Blue-Eyes Toon Dragon", "Manga Ryu-Ran", "Toon Alligator", "Toon Dark Magician Girl", "Toon Gemini Elf",
			"Toon Goblin Attack Force", "Toon Cannon Soldier", "Toon Masked Sorcerer", "Dark Rabbit", "Parrot Dragon", "Bickuribox", "Relinquished", "Dragon Piper", "Illusionist Faceless Mage",
			"Dark-Eyes Illusionist", "Jigen Bakudan", "Black Illusion Ritual", "Dragon Capture Jar", "Doppelganger", "Copycat", "Toon Table of Contents", "Gorgon's Eye"],
		"extra": ["Thousand-Eyes Restrict"]},
	"weevil": {"main": ["Swords of Revealing Light", "Raigeki", "Dark Hole", "Heavy Storm", "Pot of Greed", "Graceful Charity", "Monster Reborn", "Change of Heart", "Mirror Force", "Magic Cylinder", "Torrential Tribute", "Call of the Haunted", "Insect Queen", "Great Moth", "Perfectly Ultimate Great Moth", "Petit Moth", "Larvae Moth", "Cocoon of Evolution", "Basic Insect", "Hercules Beetle", "Killer Needle", "Big Insect",
			"Gokibore", "Pinch Hopper", "Leghul", "Flying Kamakiri #1", "Kiseitai", "Parasite Paracide", "Insect Soldiers of the Sky", "Man-Eater Bug", "Skull-Mark Ladybug", "Cockroach Knight",
			"Needle Worm", "Insect Barrier", "Multiplication of Ants", "DNA Surgery", "Insect Armor with Laser Cannon", "Eradicating Aerosol"],
		"extra": []},
	"rex": {"main": ["Tyrant Dragon", "Ultimate Tyranno", "Super Conductor Tyranno", "Sabersaurus", "Raise Body Heat", "Pot of Greed", "Monster Reborn", "Smashing Ground", "Heavy Storm", "Call of the Haunted", "Sakuretsu Armor", "Mirror Force", "Two-Headed King Rex", "Crawling Dragon #2", "Sword Arm of Dragon", "Megazowler", "Uraby", "Trakodon", "Serpent Night Dragon", "Black Tyranno", "Gilasaurus", "Dark Driceratops",
			"Mad Sword Beast", "Black Stego", "Giant Rex", "Babycerasaurus", "Hyper Hammerhead", "Frostosaurus", "Element Saurus", "Tail Swipe", "Hunting Instinct", "Fossil Excavation",
			"Jurassic World", "Ultra Evolution Pill", "Survival Instinct"],
		"extra": []},
	"jaden": {"main": ["Mirror Force", "Yubel - Terror Incarnate", "Yubel - The Ultimate Nightmare", "Elemental HERO Avian", "Elemental HERO Burstinatrix", "Elemental HERO Clayman", "Elemental HERO Sparkman", "Elemental HERO Bubbleman", "Elemental HERO Wildheart",
			"Elemental HERO Bladedge", "Elemental HERO Necroshade", "Elemental HERO Neos", "Winged Kuriboh", "Winged Kuriboh LV10", "Wroughtweiler", "Dark Catapulter", "Hero Kid", "Card Trooper",
			"Neo-Spacian Aqua Dolphin", "Neo-Spacian Flare Scarab", "Neo-Spacian Dark Panther", "Neo-Spacian Air Hummingbird", "Neo-Spacian Grand Mole", "Neo-Spacian Glow Moss", "Yubel",
			"Polymerization", "Fusion Gate", "Miracle Fusion", "Skyscraper", "Hero Signal", "A Hero Emerges", "Draining Shield", "Negate Attack", "Mirror Gate", "Feather Shot", "Bubble Shuffle",
			"Burst Return", "Spark Blaster", "R - Righteous Justice", "O - Oversoul", "E - Emergency Call", "H - Heated Heart", "Transcendent Wings", "The Warrior Returning Alive", "Hero Barrier",
			"Edge Hammer", "Common Soul", "Neo Space", "Instant Neo Space", "Pot of Greed", "Monster Reborn", "Fake Hero", "Elemental HERO Neos", "Negate Attack", "Draining Shield"],
		"extra": ["Elemental HERO Flame Wingman", "Elemental HERO Shining Flare Wingman", "Elemental HERO Thunder Giant", "Elemental HERO Tempest", "Elemental HERO Rampart Blaster",
			"Elemental HERO Steam Healer", "Elemental HERO Mudballman", "Elemental HERO Wildedge", "Elemental HERO Wild Wingman", "Elemental HERO Necroid Shaman", "Elemental HERO Mariner",
			"Elemental HERO Electrum", "Elemental HERO Aqua Neos", "Elemental HERO Flare Neos", "Elemental HERO Dark Neos", "Elemental HERO Air Neos", "Elemental HERO Grand Neos",
			"Elemental HERO Glow Neos", "Elemental HERO Storm Neos", "Elemental HERO Magma Neos", "Elemental HERO Divine Neos", "Neos Wiseman"]},
	"chazz": {"main": ["Light and Darkness Dragon", "Ojama Red", "Ojama Blue", "Monster Reborn", "Heavy Storm", "Ojama Yellow", "Ojama Green", "Ojama Black", "Armed Dragon LV3", "Armed Dragon LV5", "Armed Dragon LV7", "Armed Dragon LV10", "X-Head Cannon", "Y-Dragon Head", "Z-Metal Tank",
			"V-Tiger Jet", "W-Wing Catapult", "Chthonian Soldier", "Infernal Incinerator", "Masked Dragon", "Ojama Delta Hurricane!!", "Ojamagic", "Ojama Country", "Ojamuscle", "Level Up!",
			"Chthonian Polymer", "Chthonian Blast", "Chthonian Alliance", "Call of the Haunted", "Ring of Destruction", "Pot of Greed", "Polymerization"],
		"extra": ["Ojama King", "Ojama Knight", "XYZ-Dragon Cannon", "VW-Tiger Catapult", "VWXYZ-Dragon Catapult Cannon"]},
	"zane": {"main": ["Cyber Dragon Zwei", "Cyber Larva", "Masked Dragon", "Monster Reborn", "Negate Attack", "Mirror Force", "Cyber Dragon", "Proto-Cyber Dragon", "Cyber Barrier Dragon", "Cyber Laser Dragon", "Cyber Phoenix", "Cyber Kirin", "Cyberdark Horn", "Cyberdark Edge", "Cyberdark Keel",
			"Infernal Dragon", "Power Bond", "Polymerization", "Future Fusion", "Overload Fusion", "De-Fusion", "Different Dimension Capsule", "Photon Generator Unit", "Attack Reflector Unit",
			"Cyberdark Impact!", "Trap Jammer", "Call of the Haunted", "Limiter Removal", "Heavy Storm", "Pot of Greed"],
		"extra": ["Cyber Twin Dragon", "Cyber End Dragon", "Cyberdark Dragon", "Chimeratech Overdragon"]},
	"alexis": {"main": ["Mystical Space Typhoon", "Cyber Petit Angel", "Heavy Storm", "Swords of Revealing Light", "Mirror Force", "Call of the Haunted", "Sakuretsu Armor", "Etoile Cyber", "Blade Skater", "Cyber Tutu", "Cyber Gymnast", "Cyber Prima", "Cyber Angel Benten", "Cyber Angel Idaten", "Cyber Angel Dakini", "Machine Angel Ritual",
			"Doble Passe", "Hallowed Life Barrier", "Polymerization", "Fusion Weapon", "Prima Light", "Ritual Weapon", "Pot of Greed", "Monster Reborn"],
		"extra": ["Cyber Blader"]},
	"syrus": {"main": ["Mirror Force", "Sakuretsu Armor", "Pot of Greed", "Monster Reborn", "Limiter Removal", "Negate Attack", "Draining Shield", "Call of the Haunted", "Gyroid", "Steamroid", "Jetroid", "Drillroid", "Patroid", "Submarineroid", "UFOroid", "Truckroid", "Stealthroid", "Expressroid", "Cycroid", "Ambulanceroid", "Rescueroid",
			"Decoyroid", "Armoroid", "Power Bond", "Polymerization", "Vehicroid Connection Zone", "Supercharge", "No Entry!!", "Shield Crush", "Wonder Garage", "Cyber Summon Blaster"],
		"extra": ["Super Vehicroid Jumbo Drill", "Steam Gyroid", "UFOroid Fighter", "Pair Cycroid", "Super Vehicroid - Stealth Union", "Ambulance Rescueroid"]},
	"aster": {"main": ["Graceful Charity", "Swords of Revealing Light", "Mystical Space Typhoon", "Monster Reborn", "Heavy Storm", "Polymerization", "Call of the Haunted", "Mirror Force", "Negate Attack", "Destiny HERO - Doom Lord", "Destiny HERO - Captain Tenacious", "Destiny HERO - Diamond Dude", "Destiny HERO - Dreadmaster", "Destiny HERO - Double Dude", "Destiny HERO - Dasher",
			"Destiny HERO - Defender", "Destiny HERO - Dogma", "Destiny HERO - Plasma", "Destiny HERO - Fear Monger", "Destiny HERO - Blade Master", "Destiny HERO - Disk Commander",
			"Destiny HERO - Malicious", "Destiny HERO - Dunker", "Destiny HERO - Departed", "Clock Tower Prison", "D - Time", "D - Spirit", "D - Chain", "D - Shield", "Dark City", "Destiny Signal",
			"Eternal Dread", "Over Destiny", "Destruction of Destiny", "Destiny Draw", "Misfortune", "Ring of Magnetism", "Guard Penalty", "Pot of Greed"],
		"extra": ["Elemental HERO Phoenix Enforcer", "Elemental HERO Shining Phoenix Enforcer", "Destiny End Dragoon"]},
	"yusei": {"main": ["Majestic Dragon", "Junk Synchron", "Speed Warrior", "Quillbolt Hedgehog", "Sonic Chick", "Shield Warrior", "Max Warrior", "Turbo Synchron", "Nitro Synchron", "Road Synchron", "Debris Dragon",
			"Tuningware", "Turret Warrior", "Fortress Warrior", "Level Eater", "Hyper Synchron", "Drill Synchron", "Quickdraw Synchron", "Stardust Xiaolong", "Level Warrior",
			"Healing Wave Generator", "Ghost Gardna", "Rockstone Warrior", "Zero Gardna", "Effect Veiler", "Salvage Warrior", "Unknown Synchron", "Boost Warrior", "Synchron Explorer", "Doppelwarrior",
			"Tuning", "One for One", "Double Summon", "Fighting Spirit", "Junk Barrage", "Silver Wing", "Card Rotator", "Graceful Revival", "Scrap-Iron Scarecrow", "Defense Draw", "Limiter Overload",
			"Give and Take", "Equip Shot", "Starlight Road", "Cards of Consonance", "Urgent Tuning", "Synchro Strike", "Shooting Star", "Skill Successor", "Descending Lost Star",
			"Slip Summon", "Confusion Chaff", "Synchro Barrier"],
		"extra": ["Junk Warrior", "Stardust Dragon", "Nitro Warrior", "Turbo Warrior", "Armory Arm", "Road Warrior", "Junk Archer", "Junk Destroyer", "Junk Gardna", "Junk Berserker", "Drill Warrior",
			"Lightning Warrior", "Colossal Fighter", "Majestic Star Dragon", "Formula Synchron", "Shooting Star Dragon", "Shooting Quasar Dragon"]},
	"jack": {"main": ["Red Dragon Archfiend/Assault Mode", "Assault Mode Activate", "Chain Resonator", "Synkron Resonator", "Resonator Call", "Scarlet Security", "Monster Reborn", "Pot of Greed", "Mystical Space Typhoon", "Call of the Haunted", "Majestic Dragon", "Dark Resonator", "Vice Dragon", "Mad Archfiend", "Twin-Sword Marauder", "Big Piece Golem", "Medium Piece Golem", "Small Piece Golem", "Sinister Sprocket", "Battle Fader",
			"Power Supplier", "Dread Dragon", "Archfiend Interceptor", "Trust Guardian", "Flare Resonator", "Barrier Resonator", "Clock Resonator", "Force Resonator", "Creation Resonator",
			"Attack Gainer", "Power Breaker", "Trap Eater", "Lancer Archfiend", "Extra Veiler", "Strong Wind Dragon", "Synchro Soldier", "Red Gardna", "Crimson Fire",
			"Fiendish Chain", "Powerful Rebirth", "Changing Destiny", "Nightmare Archfiends", "Prideful Roar", "Half or Nothing", "Lineage of Destruction"],
		"extra": ["Crimson Blader", "Scarlight Red Dragon Archfiend", "Red Dragon Archfiend", "Exploder Dragonwing", "Chaos King Archfiend", "Majestic Red Dragon", "Red Nova Dragon"]},
	"crow": {"main": ["Monster Reborn", "Blackwing - Gale the Whirlwind", "Blackwing - Bora the Spear", "Blackwing - Sirocco the Dawn", "Blackwing - Blizzard the Far North", "Blackwing - Shura the Blue Flame",
			"Blackwing - Kalut the Moon Shadow", "Blackwing - Elphin the Raven", "Blackwing - Mistral the Silver Shield", "Blackwing - Vayu the Emblem of Honor", "Blackwing - Fane the Steel Chain",
			"Blackwing - Ghibli the Searing Wind", "Blackwing - Gust the Backblast", "Blackwing - Breeze the Zephyr", "Blackwing - Zephyros the Elite", "Blackwing - Aurora the Northern Lights",
			"Blackwing - Jetstream the Blue Sky", "Blackwing - Calima the Haze", "Blackwing - Kochi the Daybreak", "Blackwing - Etesian of Two Swords", "Blackwing - Abrolhos the Megaquake",
			"Black Whirlwind", "Delta Crow - Anti Reverse", "Blackwing - Backlash", "Blackwing - Bombardment", "Black Return", "Fake Feather", "Trap Stun", "Black Feather Beacon", "Urgent Tuning",
			"Mirror Force", "Raptor Wing Strike", "Cards for Black Feathers", "Against the Wind", "Black Sonic", "Black Thunder", "Blackback", "Level Retuner", "Blackboost"],
		"extra": ["Blackwing Armor Master", "Blackwing Armed Wing", "Blackwing - Silverwind the Ascendant", "Black-Winged Dragon"]},
	"akiza": {"main": ["Tytannial, Princess of Camellias", "Monster Reborn", "Pot of Greed", "Sakuretsu Armor", "Mirror Force", "Rose Tentacles", "Violet Witch", "Wall of Ivy", "Copy Plant", "Twilight Rose Knight", "Lord Poison", "Evil Thorn", "Phoenixian Seed", "Phoenixian Cluster Amaryllis", "Rose Fairy",
			"Witch of the Black Rose", "Dark Verger", "Hedge Guard", "Blue Rose Dragon", "Lonefire Blossom", "Black Garden", "Seed of Deception", "Mark of the Rose", "Thorn of Malice",
			"Wicked Rebirth", "Ivy Shackles", "Doppelganger", "Plant Food Chain", "Urgent Tuning", "Magic Planter", "Vengeful Servant", "Blossom Bombardment",
			"Nature's Reflection", "Overdoom Line"],
		"extra": ["Queen of Thorns", "Black Rose Dragon", "Splendid Rose", "Queen Angel of Roses"]},
	"kalin": {"main": ["Card Destruction", "Monster Reborn", "Pot of Greed", "Infernity Archfiend", "Infernity Necromancer", "Infernity Beast", "Infernity Beetle", "Infernity Destroyer", "Infernity Dwarf", "Infernity Guardian", "Infernity Knight",
			"Infernity Mirage", "Infernity Avenger", "Infernity Randomizer", "Infernity General", "Infernity Archer", "Dark Tuner Nightmare Hand", "Earthbound Immortal Ccapac Apu",
			"Infernity Launcher", "Infernity Force", "Infernity Inferno", "Infernity Reflector", "Infernity Break", "Infernity Barrier", "ZERO-MAX", "Phantom Hand",
			"Depth Amulet", "Full Salvo", "Void Trap Hole"],
		"extra": ["Infernity Doom Dragon", "Hundred Eyes Dragon", "Void Ogre Dragon", "Gatling Ogre"]},
	"yuma": {"main": ["Monster Reborn", "Pot of Greed", "Gagaga Magician", "Gogogo Golem", "Ganbara Knight", "Zubaba Knight", "Gagaga Girl", "Dododo Warrior", "Goblindbergh", "Kagetokage", "Kurivolt", "Achacha Archer", "Tasuke Knight",
			"Gogogo Giant", "Gagaga Gardna", "Dododo Bot", "Flelf", "Rai Rider", "Bite Bug", "Gagaga Caesar", "Gagaga Child", "Gagaga Clerk", "Gogogo Ghost", "Gogogo Goram", "Dododo Buster",
			"Gagaga Head", "Zubaba Buster", "Gagaga Sister", "Gagaga Mancer", "ZW - Unicorn Spear", "ZW - Phoenix Bow", "ZW - Lightning Blade", "ZW - Tornado Bringer", "ZW - Ultimate Shield",
			"ZW - Eagle Claw", "Double or Nothing!", "Battle Break", "Half Unbreak", "Bye Bye Damage", "Gagagabolt", "Gagagarevenge", "Gagagashield", "Gagagaback", "Xyz Gift", "Blustering Winds",
			"Wonder Wand", "Ego Boost", "Xyz Energy", "Onomatopaira", "Dodododraw", "Gagagatag", "Heartfelt Appeal", "Guard Go!", "Fiery Fervor",
			"Rank-Up-Magic Limited Barian's Force", "Impenetrable Attack"],
		"extra": ["Number S39: Utopia the Lightning", "Number F0: Utopic Future", "Number C39: Utopia Ray Victory", "Number 39: Utopia Beyond", "Number 39: Utopia", "Number C39: Utopia Ray", "Number 17: Leviathan Dragon", "Number 34: Terror-Byte", "Number 61: Volcasaurus", "Number 19: Freezadon",
			"Number 12: Crimson Shadow Armor Ninja", "Number 25: Force Focus", "Number 6: Chronomaly Atlandis", "Number 83: Galaxy Queen", "Gagaga Cowboy", "Gagaga Samurai",
			"Number 39: Utopia Roots", "Number C39: Utopia Ray V", "Number 99: Utopic Dragon", "ZW - Leo Arms"]},
	"shark": {"main": ["Rank-Up-Magic Limited Barian's Force", "Monster Reborn", "Pot of Greed", "Mystical Space Typhoon", "Call of the Haunted", "Torrential Tribute", "Mirror Force", "Sakuretsu Armor", "Big Jaws", "Skull Kraken", "Drill Barnacle", "Needle Sunfish", "Jawsman", "Shocktopus", "Friller Rabca", "Shark Stickers", "Spear Shark", "Double Shark",
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
	"vector": {"main": ["Raigeki", "Pot of Greed", "Dark Hole", "Mystical Space Typhoon", "Swords of Revealing Light", "Book of Moon", "Shadow Spell", "Dark Bribe", "Sakuretsu Armor", "Call of the Haunted", "Torrential Tribute", "Umbral Horror Ghoul", "Umbral Horror Unform", "Umbral Horror Will o' the Wisp", "Umbral Horror Ghost", "Malicevorous Fork", "Malicevorous Knife", "Malicevorous Spoon",
			"Rank-Up-Magic Barian's Force", "Rank-Up-Magic Limited Barian's Force", "Vain Betrayer", "Don Thousand's Throne", "Mirror Force", "Monster Reborn"],
		"extra": ["Number C65: King Overfiend", "Number C96: Dark Storm", "Number 66: Master Key Beetle", "Number 104: Masquerade", "Number C104: Umbral Horror Masquerade", "Number 65: Djinn Buster", "Number 43: Manipulator of Souls",
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
		# v0.47.0, the competitive list: Pure Dark Magician.
		"main": {"Dark Magician": 3, "Dark Magician Girl": 1, "Magician's Rod": 3, "Magicians' Souls": 3, "Apprentice Illusion Magician": 2, "Illusion of Chaos": 2, "Timaeus the United Dragon": 1, "Magikuriboh": 1, "Palladium Oracle Mahad": 1, "Dark Magical Circle": 3, "Soul Servant": 3, "Magician's Salvation": 2, "Secrets of Dark Magic": 1, "The Eye of Timaeus": 1, "Bond Between Teacher and Student": 1, "Illusion Magic": 1, "Pot of Greed": 1, "Graceful Charity": 1, "Monster Reborn": 1, "Eternal Soul": 3, "Magician Navigation": 3, "Mirror Force": 1, "Magic Cylinder": 1},
		"extra": {"Dark Magician the Dragon Knight": 1, "Amulet Dragon": 1, "Dark Magician Girl the Dragon Knight": 1, "The Dark Magicians": 2, "Dark Cavalry": 1, "Master of Chaos": 1, "Dark Paladin": 1, "Ebon Illusion Magician": 2, "Ebon High Magician": 1, "Magi Magi ☆ Magician Gal": 1, "Number 11: Big Eye": 1, "Mecha Phantom Beast Dracossack": 1, "Quintet Magician": 1}},
	"kaiba": {"out": ["Rude Kaiser", "Koumori Dragon", "Cyber Dragon", "Mystic Tomato", "Mountain", "Dragon Treasure", "Torrential Tribute", "Trap Hole"],
		"in": {"X-Head Cannon": 1, "Y-Dragon Head": 1, "Z-Metal Tank": 1, "Saggi the Dark Clown": 1, "Hitotsu-Me Giant": 1, "Luster Dragon": 2, "Vampire Lord": 1},
		"extra_in": {"XYZ-Dragon Cannon": 1},
		# Kaiba, deck pass (v0.33.36): Blue-Eyes with every way to get it out (Kaibaman x3, Kaiser Sea Horse x3, Lord of D. + Flute, Call of the Haunted), Obelisk, Vampire Lord, Crush Card. The single XYZ pieces and the vanilla filler are out. v0.33.37: Chaos Emperor Dragon in.
		# v0.47.0, the competitive list: Blue-Eyes with all of its modern support.
		"main": {"Blue-Eyes White Dragon": 3, "Blue-Eyes Alternative White Dragon": 2, "Blue-Eyes Jet Dragon": 1, "Blue-Eyes Abyss Dragon": 1, "Dragon Spirit of White": 1, "Sage with Eyes of Blue": 3, "Maiden of White": 2, "Neo Kaiser Sea Horse": 1, "Dictator of D.": 2, "The White Stone of Ancients": 3, "The White Stone of Legend": 1, "Wishes for Eyes of Blue": 3, "Roar of the Blue-Eyed Dragons": 2, "The Melody of Awakening Dragon": 2, "Trade-In": 2, "Bingo Machine, Go!!!": 2, "Ultimate Fusion": 1, "Return of the Dragon Lords": 1, "Pot of Greed": 1, "Monster Reborn": 1, "True Light": 1, "Majesty of the White Dragons": 2, "The Ultimate Creature of Destruction": 1, "Crush Card Virus": 1},
		"extra": {"Blue-Eyes Spirit Dragon": 2, "Blue-Eyes Ultimate Spirit Dragon": 2, "Azure-Eyes Silver Dragon": 1, "Blue-Eyes Twin Burst Dragon": 1, "Neo Blue-Eyes Ultimate Dragon": 1, "Blue-Eyes Tyrant Dragon": 1, "Blue-Eyes Ultimate Dragon": 1, "Indigo-Eyes Silver Dragon": 1, "Number 38: Hope Harbinger Dragon Titanic Galaxy": 1, "Thunder End Dragon": 1, "Hieratic Sun Dragon Overlord of Heliopolis": 1, "Number 97: Draglubion": 1, "Divine Dragon Knight Felgrand": 1}},
	"joey": {"out": ["Garoozis", "Battle Steer", "Tiger Axe", "Dian Keto the Cure Master", "Sogen", "Waboku", "Trap Hole"],
		"in": {"Battle Warrior": 1, "Swordsman of Landstar": 2, "Goblin Attack Force": 1, "Salamandra": 1, "Giant Trunade": 1, "Foolish Burial": 1},
		# Joey, deck pass (v0.33.36): Red-Eyes, Jinzo x2, Gearfried x3, Goblin Attack Force x3, his dice and Scapegoat. The weak vanilla Warriors are out. v0.33.37: Metalmorph into Red-Eyes Black Metal Dragon.
		# v0.47.0, the competitive list: Red-Eyes Fusion.
		"main": {"Red-Eyes Black Dragon": 3, "Red-Eyes Black Flare Dragon": 2, "Meteor Dragon Red-Eyes Impact": 1, "Red-Eyes Baby Dragon": 2, "Red-Eyes Wyvern": 1, "The Black Stone of Legend": 3, "Red-Eyes Darkness Metal Dragon": 1, "Gearfried the Red-Eyes Iron Knight": 1, "Black Metal Dragon": 1, "Summoned Skull": 1, "Red-Eyes Black Fullmetal Dragon": 1, "Red-Eyes Fusion": 3, "Red-Eyes Insight": 3, "Cards of the Red Stone": 2, "Dragon Shrine": 2, "Inferno Fire Blast": 1, "Foolish Burial": 1, "Scapegoat": 1, "Pot of Greed": 1, "Graceful Charity": 1, "Monster Reborn": 1, "Red-Eyes Spirit": 2, "Return of the Red-Eyes": 2, "Red-Eyes Burn": 1, "Max Metalmorph": 2},
		"extra": {"Red-Eyes Slash Dragon": 2, "Meteor Black Comet Dragon": 2, "Archfiend Black Skull Dragon": 2, "Black Skull Dragon": 1, "Red-Eyes Flare Metal Dragon": 2, "Number 11: Big Eye": 1, "Mecha Phantom Beast Dracossack": 1, "Odd-Eyes Absolute Dragon": 1, "Number 42: Galaxy Tomahawk": 1, "Number 74: Master of Blades": 1, "Gaia Dragon, the Thunder Charger": 1}},
	"mai": {"out": ["Hinotama", "Dian Keto the Cure Master", "Fissure", "Follow Wind", "Pot of Greed"],
		"in": {"Dunames Dark Witch": 2, "Amazoness Fighter": 2, "Amazoness Swords Woman": 2, "Harpie Lady Sisters": 2, "Elegant Egotist": 3, "Cyber Shield": 2, "Mirror Wall": 1, "Electro-Whip": 1},
		# Mai's best deck (v0.33.36): Harpie Ladies on Harpies' Hunting Ground with Elegant Egotist, Harpie's Pet Dragon, Phoenix Formation, Triangle Ecstasy Spark and Hysteric Party, plus her Amazonesses.
		# v0.47.0, the competitive list: Harpies that swarm and make Rank 4 Xyz.
		"main": {"Harpie Channeler": 3, "Harpie Harpist": 3, "Harpie Perfumer": 3, "Harpie Dancer": 3, "Harpie Queen": 3, "Harpie Oracle": 2, "Harpie's Pet Dragon": 1, "Harpie's Pet Dragon - Fearsome Fire Blast": 1, "Harpie's Pet Baby Dragon": 1, "Hysteric Sign": 3, "Elegant Egotist": 2, "Harpies' Hunting Ground": 2, "Harpie's Feather Duster": 1, "Harpie's Feather Rest": 1, "Harpie Lady Phoenix Formation": 1, "Swallow's Nest": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Harpie's Feather Storm": 3, "Hysteric Party": 2, "Icarus Attack": 2},
		"extra": {"Steelswarm Roach": 1, "Harpie's Pet Phantasmal Dragon": 2, "Lightning Chidori": 2, "Ice Beast Zerofyne": 1, "Castel, the Skyblaster Musketeer": 1, "Abyss Dweller": 1, "Daigusto Emeral": 1, "Diamond Dire Wolf": 1, "Tornado Dragon": 1, "Evilswarm Exciton Knight": 1, "Gagaga Cowboy": 1, "Number 50: Blackship of Corn": 1, "Dark Rebellion Xyz Dragon": 1}},
	"bakura": {"out": ["Newdoria", "Curse of Dragon", "Summoned Skull", "Ryu-Kishin", "Lord of the Lamp", "Fissure", "Dark Energy", "Dark Core", "Yami"],
		"in": {"The Portrait's Secret": 1, "Earthbound Spirit": 2, "Souls of the Forgotten": 1, "The Gross Ghost of Fled Dreams": 1, "Man-Eater Bug": 2, "Lady of Faith": 1,
			"Change of Heart": 1, "Just Desserts": 1, "The Dark Door": 1},
		# Bakura, deck pass (v0.33.36): Dark Necrofear x3 with enough Fiends to feed her, Diabound Kernel, Destiny Board, and the old power cards. v0.33.37: Dark Sanctuary.
		# v0.47.0, the competitive list: Fiends that fill the Graveyard for Dark Necrofear, with Destiny Board as a second way to win.
		"main": {"Dark Necrofear": 3, "Curse Necrofear": 1, "Dark Spirit of Malice": 1, "Dark Spirit of Banishment": 1, "Diabound Kernel": 2, "Tour Guide From the Underworld": 2, "Sangan": 1, "Fiendish Rhino Warrior": 2, "Absolute King Back Jack": 2, "Lilith, Lady of Lament": 2, "Morphing Jar": 1, "Dark Spirit's Mastery": 3, "Dark Sanctuary": 1, "Spirit Message \"I\"": 1, "Spirit Message \"N\"": 1, "Spirit Message \"A\"": 1, "Spirit Message \"L\"": 1, "Allure of Darkness": 2, "Change of Heart": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Destiny Board": 2, "Sentence of Doom": 2, "Fiend Griefing": 2, "Torrential Tribute": 1, "Mirror Force": 1, "Call of the Haunted": 1},
		"extra": {"Dante, Traveler of the Burning Abyss": 1, "Leviair the Sea Dragon": 1, "Wind-Up Zenmaines": 1, "Ghostrick Alucard": 1, "Mechquipped Angineer": 1, "Number 30: Acid Golem of Destruction": 1, "Number 17: Leviathan Dragon": 1, "Number 23: Lancelot, Dark Knight of the Underworld": 1, "Number 22: Zombiestein": 1, "Number 68: Sanaphond the Sky Prison": 1}},
	"marik": {"out": ["Dark Blade", "Vampire Lord", "Feral Imp", "Mystic Lamp", "Stone Statue of the Aztecs", "Hinotama", "Mystic Plasma Zone", "Malevolent Nuzzler", "Magic Jammer"],
		"in": {"Legendary Fiend": 1, "Lord Poison": 1, "Melchid the Four-Face Beast": 1, "Newdoria": 2, "Card of Sanctity": 1, "Mirror Force": 1, "Remove Trap": 1},
		# Marik's best deck (v0.33.36): Lava Golem, Revival Jam with Jam Defender, Viser Des and Helpoemer, Nightmare Wheel and Coffin Seller, and The Winged Dragon of Ra.
		# v0.47.0, the competitive list: The Winged Dragon of Ra, built so Ra really comes out.
		"main": {"The Winged Dragon of Ra": 2, "The Winged Dragon of Ra - Sphere Mode": 1, "The Winged Dragon of Ra - Immortal Phoenix": 1, "Guardian Slime": 3, "Reactor Slime": 3, "Revival Jam": 1, "Lava Golem": 3, "Ra's Disciple": 2, "Makyura the Destructor": 1, "Juragedo": 1, "Ancient Chant": 3, "The True Sun God": 2, "Millennium Revelation": 1, "Blaze Cannon": 1, "Soul Crossing": 1, "Mystical Space Typhoon": 1, "Swords of Revealing Light": 1, "Dark Hole": 1, "Raigeki": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Metal Reflect Slime": 3, "Sun God Unification": 1, "Nightmare Wheel": 1, "Torrential Tribute": 1, "Mirror Force": 1, "Call of the Haunted": 1},
		"extra": {"Egyptian God Slime": 3, "Superdreadnought Rail Cannon Gustav Max": 1, "Number 35: Ravenous Tarantula": 1, "Skypalace Gangaridai": 1}},
	"pegasus": {"out": ["Fissure", "Raigeki", "Shadow Spell", "Heavy Storm"], "in": {"Dark Rabbit": 1, "Parrot Dragon": 1, "Illusionist Faceless Mage": 1},
		# Pegasus, deck pass (v0.33.39): Mystical Space Typhoon x2 and Sakuretsu Armor instead of Heavy Storm, Dark Hole and a Torrential Tribute (they killed his own Toons and Toon World).
		# v0.47.0, the competitive list: Toons that attack directly, with Toon Kingdom protecting them and Toon Bookmark and Table of Contents finding every piece.
		"main": {"Red-Eyes Toon Dragon": 3, "Toon Harpie Lady": 3, "Toon Dark Magician": 2, "Toon Dark Magician Girl": 2, "Toon Cyber Dragon": 2, "Toon Black Luster Soldier": 1, "Toon Gemini Elf": 1, "Blue-Eyes Toon Dragon": 1, "Toon Summoned Skull": 1, "Toon Table of Contents": 3, "Toon Bookmark": 3, "Toon Kingdom": 3, "Toon Page-Flip": 2, "Toon World": 1, "Instant Fusion": 2, "Terraforming": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Toon Terror": 3, "Fiendish Chain": 1, "Mirror Force": 1, "Torrential Tribute": 1, "Call of the Haunted": 1},
		"extra": {"Thousand-Eyes Restrict": 2, "Millennium-Eyes Restrict": 2, "Number 11: Big Eye": 1, "Mecha Phantom Beast Dracossack": 1, "Red-Eyes Flare Metal Dragon": 1, "Ebon Illusion Magician": 1, "Castel, the Skyblaster Musketeer": 1, "Abyss Dweller": 1, "Evilswarm Exciton Knight": 1, "Diamond Dire Wolf": 1, "Tornado Dragon": 1, "Gagaga Cowboy": 1}},
	"weevil": {"out": ["Insect Knight", "Neo Bug", "Gokipon", "Dian Keto the Cure Master", "Just Desserts", "Fissure"],
		"in": {"Big Insect": 2, "Flying Kamakiri #1": 2, "Gokibore": 2, "Man-Eater Bug": 2, "Needle Worm": 1, "Skull-Mark Ladybug": 1},
		# Weevil, deck pass (v0.33.36): the lock (DNA Surgery + Insect Barrier), Insect Queen, Parasite Paracide, and the old power cards. The vanilla Insects are out.
		# v0.47.0, the competitive list: Insects that replace themselves.
		"main": {"Resonance Insect": 3, "Gokipole": 3, "Beetrooper Scout Buggy": 3, "Beetrooper Assault Roller": 3, "Beetrooper Sting Lancer": 2, "Beetrooper Scale Bomber": 2, "Beetrooper Light Flapper": 1, "Heavy Beetrooper Mighty Neptune": 1, "Insect Queen": 1, "Metamorphosed Insect Queen": 1, "Doom Dozer": 1, "Retaliating \"C\"": 1, "Beetrooper Landing": 2, "Beetrooper Formation": 2, "Beetrooper Descent": 2, "Verdant Sanctuary": 2, "Insect Barrier": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Dark Hole": 1, "Beetrooper Fly & Sting": 2, "Beetrooper Squad": 1, "Mirror Force": 1, "Torrential Tribute": 1, "Call of the Haunted": 1},
		"extra": {"Ultra Beetrooper Absolute Hercules": 2, "Beetrooper Cruel Saturnas": 2, "Number 20: Giga-Brilliant": 1, "Number 3: Cicada King": 1, "Number 70: Malevolent Sin": 1, "Number 28: Titanic Moth": 1, "Number 11: Big Eye": 1, "Mecha Phantom Beast Dracossack": 1, "Leviair the Sea Dragon": 1, "Wind-Up Zenmaines": 1, "Mechquipped Angineer": 1, "Abyss Dweller": 1, "Castel, the Skyblaster Musketeer": 1}},
	"rex": {"out": ["Hinotama", "Dian Keto the Cure Master", "Hammer Shot", "Fissure", "Rush Recklessly"],
		"in": {"Dark Driceratops": 1, "Frostosaurus": 1, "Serpent Night Dragon": 1, "Trakodon": 2, "Black Stego": 2, "Babycerasaurus": 2, "Hyper Hammerhead": 2, "Element Saurus": 2, "Fossil Excavation": 2},
		# Rex's best deck (v0.33.36): Dinosaurs with Gilasaurus and Babycerasaurus for Tributes, Black Tyranno, Dark Driceratops, Ultimate Tyranno and Super Conductor Tyranno, Jurassic World and Tail Swipe. v0.33.37: Tyrant Dragon.
		# v0.47.0, the competitive list: Modern Dinosaurs.
		"main": {"Souleating Oviraptor": 3, "Miscellaneousaurus": 3, "Babycerasaurus": 3, "Petiteranodon": 3, "Giant Rex": 3, "Ultimate Conductor Tyranno": 3, "Megalosmasher X": 2, "Overtex Qoatlus": 1, "Animadorned Archosaur": 1, "Xeno Meteorus": 1, "Super Conductor Tyranno": 1, "Fossil Dig": 3, "Lost World": 3, "Terraforming": 1, "Dark Hole": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Survival's End": 3, "Mirror Force": 1, "Torrential Tribute": 1, "Call of the Haunted": 1},
		"extra": {"Evolzar Laggia": 2, "Evolzar Dolkka": 2, "Tornado Dragon": 1, "Castel, the Skyblaster Musketeer": 1, "Abyss Dweller": 1, "Diamond Dire Wolf": 1, "Number 38: Hope Harbinger Dragon Titanic Galaxy": 1, "Number 97: Draglubion": 1, "Divine Dragon Knight Felgrand": 1, "Gachi Gachi Gantetsu": 1, "Sky Cavalry Centaurea": 1, "Herald of Pure Light": 1, "Number 107: Galaxy-Eyes Tachyon Dragon": 1}},
	# Jaden's best deck: Neos, the Neo-Spacians and Contact Fusion, with the first Elemental HEROes behind them (v0.33.32).
	"jaden": {"out": ["Celtic Guardian"], "in": {"Elemental HERO Bladedge": 1},
		# Jaden, deck pass (v0.33.39): tested over 60 duels each. Yubel and her forms are out (they sat dead in the hand: 3 Tributes), two of each fusion half, Clayman/Bubbleman x2, Wildheart, an extra Emergency Call and Miracle Fusion. 14 -> 21 wins of 60.
		# v0.47.0, the competitive list: HERO Fusion at full speed.
		"main": {"Elemental HERO Stratos": 3, "Vision HERO Vyon": 3, "Vision HERO Faris": 2, "Vision HERO Increase": 1, "Elemental HERO Shadow Mist": 2, "Elemental HERO Liquid Soldier": 2, "Elemental HERO Solid Soldier": 1, "Elemental HERO Blazeman": 2, "Elemental HERO Neos": 1, "Elemental HERO Honest Neos": 1, "Elemental HERO Spirit of Neos": 1, "Destiny HERO - Malicious": 1, "E - Emergency Call": 3, "A Hero Lives": 2, "Polymerization": 3, "Miracle Fusion": 2, "Super Polymerization": 2, "Mask Change": 2, "Neos Fusion": 2, "Reinforcement of the Army": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Hero Signal": 1},
		"extra": {"Elemental HERO Sunrise": 2, "Elemental HERO Absolute Zero": 1, "Elemental HERO Great Tornado": 1, "Elemental HERO The Shining": 1, "Elemental HERO Nova Master": 1, "Elemental HERO Gaia": 1, "Elemental HERO Escuridao": 1, "Elemental HERO Brave Neos": 1, "Elemental HERO Flame Wingman - Infernal Rage": 1, "Wake Up Your Elemental HERO": 1, "Masked HERO Dark Law": 1, "Masked HERO Acid": 1, "Vision HERO Adoration": 1, "Vision HERO Trinity": 1}},
	"chazz": {"out": ["Dragon Treasure", "Rush Recklessly"], "in": {"Masked Dragon": 2, "V-Tiger Jet": 1},
		# Chazz's best deck (v0.33.36): the Armed Dragons up to LV10 with Level Up!, the Ojamas into Ojama King and Ojama Delta Hurricane!!, and the VWXYZ Union line. v0.33.37: Light and Darkness Dragon, Ojama Knight.
		# v0.47.0, the competitive list: Armed Dragon Thunder.
		"main": {"Armed Dragon Thunder LV10": 2, "Armed Dragon Thunder LV7": 3, "Armed Dragon Thunder LV5": 3, "Armed Dragon Thunder LV3": 3, "Armed Dragon LV10 White": 1, "Armed Dragon LV10": 1, "Armed Dragon LV7": 1, "Pile Armed Dragon": 2, "Tempest, Dragon Ruler of Storms": 2, "Light and Darkness Dragon": 1, "Armed Dragon Flash": 3, "Armed Dragon Blitz": 2, "Armed Dragon Lightning": 2, "Level Up!": 1, "Dragon Shrine": 2, "Foolish Burial": 1, "Heavy Storm": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Armed Dragon Thunderbolt": 2, "Ojama Trio": 2, "Mirror Force": 1, "Torrential Tribute": 1, "Call of the Haunted": 1},
		"extra": {"Number 11: Big Eye": 1, "Mecha Phantom Beast Dracossack": 1, "Red-Eyes Flare Metal Dragon": 1, "Odd-Eyes Absolute Dragon": 1, "Number 61: Volcasaurus": 1, "Tiras, Keeper of Genesis": 1, "Adreus, Keeper of Armageddon": 1, "Leviair the Sea Dragon": 1, "Wind-Up Zenmaines": 1, "Superdreadnought Rail Cannon Gustav Max": 1}},
	"zane": {"out": ["X-Head Cannon", "Elemental HERO Burstinatrix", "Charcoal Inpachi", "Millennium Shield"], "in": {"Call of the Haunted": 1},
		# Zane, deck pass (v0.33.37): Cyberdark Impact! and Chimeratech Overdragon in, Cyber Dragon Zwei for a fourth Cyber Dragon, one Polymerization out.
		# v0.47.0, the competitive list: Cyber Dragon.
		"main": {"Cyber Dragon": 3, "Cyber Dragon Core": 3, "Cyber Dragon Herz": 3, "Cyber Dragon Nachster": 2, "Cyber Dragon Vier": 1, "Cyber Dragon Drei": 1, "Galaxy Soldier": 2, "Cyber Eltanin": 1, "Cyber Emergency": 3, "Cyber Repair Plant": 2, "Cybernetic Horizon": 2, "Power Bond": 2, "Overload Fusion": 2, "Machine Duplication": 2, "Cyber Revsystem": 1, "Cyberload Fusion": 1, "Limiter Removal": 1, "De-Fusion": 1, "Heavy Storm": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Cybernetic Overflow": 3, "Call of the Haunted": 1},
		"extra": {"Cyber End Dragon": 2, "Cyber Twin Dragon": 2, "Chimeratech Rampage Dragon": 2, "Chimeratech Overdragon": 1, "Chimeratech Fortress Dragon": 1, "Constellar Pleiades": 1, "Cyber Eternity Dragon": 1, "Cyber Dragon Nova": 2, "Cyber Dragon Infinity": 2, "Number 61: Volcasaurus": 1}},
	"alexis": {"out": ["Dian Keto the Cure Master", "Luminous Spark", "Horn of the Unicorn", "Fissure", "Cyber Petit Angel"],
		"in": {"Hallowed Life Barrier": 1, "Machine Angel Ritual": 3, "Fusion Weapon": 1, "Ritual Weapon": 2}, "extra_in": {"Cyber Blader": 2},
		# Alexis, deck pass (v0.33.39): Mystical Space Typhoon instead of Heavy Storm.
		# v0.47.0, the competitive list: Cyber Angel Rituals.
		"main": {"Cyber Angel Benten": 3, "Cyber Angel Idaten": 2, "Cyber Angel Dakini": 2, "Cyber Angel Natasha": 1, "Cyber Angel Vrash": 1, "Cyber Angel Izana": 1, "Cyber Petit Angel": 3, "Cyber Egg Angel": 2, "Manju of the Ten Thousand Hands": 3, "Etoile Cyber": 1, "Blade Skater": 1, "Honest": 1, "Machine Angel Ritual": 3, "Machine Angel Absolute Ritual": 2, "Pre-Preparation of Rites": 3, "Preparation of Rites": 1, "Ritual Sanctuary": 1, "Merciful Machine Angel": 1, "Magnificent Machine Angel": 1, "Incarnated Machine Angel": 1, "Polymerization": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Mirror Force": 1, "Torrential Tribute": 1, "Call of the Haunted": 1},
		"extra": {"Cyber Blader": 2, "Constellar Ptolemy M7": 1, "Photon Strike Bounzer": 1, "Number 38: Hope Harbinger Dragon Titanic Galaxy": 1, "Divine Dragon Knight Felgrand": 1, "Herald of Pure Light": 1, "Castel, the Skyblaster Musketeer": 1}},
	"syrus": {"out": ["Elemental HERO Clayman", "Dian Keto the Cure Master"], "in": {"Shield Crush": 1},
		# Syrus, deck pass (v0.33.39): No Entry!! out (it turned his own attackers to Defense), Mirror Force and Sakuretsu Armor in. 17 -> 30 wins of 60.
		# v0.47.0, the competitive list: Vehicroids with their own search cards.
		"main": {"Expressroid": 3, "Mixeroid": 3, "Submarineroid": 2, "Drillroid": 2, "Steamroid": 1, "Stealthroid": 1, "Truckroid": 1, "Armoroid": 1, "UFOroid": 1, "Ambulanceroid": 1, "Rescueroid": 1, "Cyber Dragon": 1, "Megaroid City": 3, "Vehicroid Connection Zone": 3, "Power Bond": 2, "Polymerization": 2, "Terraforming": 1, "Limiter Removal": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Emergeroid Call": 3, "Supercharge": 2, "Mirror Force": 1, "Call of the Haunted": 1, "Torrential Tribute": 1},
		"extra": {"Super Vehicroid - Mobile Base": 2, "Barbaroid, the Ultimate Battle Machine": 1, "Super Vehicroid Jumbo Drill": 1, "Super Vehicroid - Stealth Union": 1, "Ambulance Rescueroid": 1, "Steam Gyroid": 1, "Pair Cycroid": 1, "UFOroid Fighter": 1, "Gear Gigant X": 2, "Castel, the Skyblaster Musketeer": 1, "Abyss Dweller": 1, "Tornado Dragon": 1, "Evilswarm Exciton Knight": 1}},
	"aster": {"out": ["Celtic Guardian", "Mystic Plasma Zone"],
		# Aster, deck pass (v0.33.39): two Clock Tower Prisons for Dreadmaster, Mystical Space Typhoon instead of Heavy Storm (it broke his own Prison). 14 -> 20 wins of 60.
		# v0.47.0, the competitive list: Destiny HERO around Fusion Destiny.
		"main": {"Vision HERO Vyon": 3, "Vision HERO Faris": 2, "Vision HERO Increase": 1, "Destiny HERO - Malicious": 2, "Destiny HERO - Celestial": 2, "Destiny HERO - Denier": 2, "Destiny HERO - Dasher": 1, "Destiny HERO - Drawhand": 1, "Destiny HERO - Disk Commander": 1, "Destiny HERO - Dynatag": 1, "Destiny HERO - Diamond Dude": 1, "Destiny HERO - Plasma": 1, "Elemental HERO Stratos": 2, "Fusion Destiny": 3, "Destiny Draw": 2, "E - Emergency Call": 2, "A Hero Lives": 2, "Allure of Darkness": 2, "Polymerization": 1, "Foolish Burial": 1, "Reinforcement of the Army": 1, "Pot of Greed": 1, "Monster Reborn": 1, "D-Fusion": 2, "D - Tactics": 1, "Mirror Force": 1},
		"extra": {"Destiny HERO - Destroyer Phoenix Enforcer": 3, "Destiny HERO - Dangerous": 2, "Destiny HERO - Dystopia": 1, "Destiny HERO - Dusktopia": 1, "Destiny HERO - Dominance": 1, "Destiny End Dragoon": 1, "Vision HERO Adoration": 2, "Vision HERO Trinity": 1, "Elemental HERO Escuridao": 1, "Abyss Dweller": 1, "Castel, the Skyblaster Musketeer": 1}},
	# Yusei's best deck: the Shooting Star Dragon and Shooting Quasar Dragon one (v0.33.28).
	"yusei": {"out": ["Celtic Guardian", "Beaver Warrior"],
		# Yusei's best deck (v0.33.36): 9 Tuners, Junk Synchron into Junk Warrior and Stardust Dragon, Shooting Star and Shooting Quasar, Majestic Star Dragon.
		# v0.47.0, the competitive list: Synchron combo.
		"main": {"Junk Synchron": 3, "Junk Converter": 3, "Doppelwarrior": 3, "Jet Synchron": 2, "Stardust Synchron": 2, "Assault Synchron": 2, "Revolution Synchron": 1, "Quickdraw Synchron": 1, "Synchron Carrier": 1, "Synchron Explorer": 1, "Stardust Trail": 1, "Level Eater": 2, "Tuningware": 2, "Quillbolt Hedgehog": 1, "Effect Veiler": 2, "Tuning": 3, "Reinforcement of the Army": 2, "Stardust Illumination": 1, "One for One": 1, "Foolish Burial": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Scrap-Iron Scarecrow": 1, "Starlight Road": 1, "Graceful Revival": 1},
		"extra": {"Junk Speeder": 2, "Junk Warrior": 1, "Formula Synchron": 1, "T.G. Hyper Librarian": 1, "Stardust Charge Warrior": 1, "Accel Synchro Stardust Dragon": 1, "Stardust Dragon": 1, "Shooting Riser Dragon": 1, "Satellite Warrior": 1, "Shooting Star Dragon": 1, "Stardust Warrior": 1, "Cosmic Blazar Dragon": 1, "Shooting Quasar Dragon": 1, "Crimson Dragon": 1}},
	# Jack's best deck: Red Dragon Archfiend on Resonators, with Exploder Dragonwing and Chaos King Archfiend beside it (v0.33.33).
	"jack": {"out": ["Molten Destruction", "Salamandra"],
		# Jack's best deck (v0.33.36): Resonators into Red Dragon Archfiend, then two more Tuners for Red Nova Dragon, and Majestic Red Dragon. v0.33.37: Assault Mode, Crimson Blader.
		# v0.47.0, the competitive list: Resonators into Red Dragon Archfiend.
		"main": {"Soul Resonator": 3, "Crimson Resonator": 3, "Vision Resonator": 3, "Red Resonator": 2, "Synkron Resonator": 2, "Dark Resonator": 1, "Bone Archfiend": 2, "Wandering King Wildwind": 2, "Red Nova": 1, "Red Gardna": 1, "Resonator Call": 3, "Crimson Gaia": 3, "Absolute Powerforce": 1, "Scarlet Security": 1, "One for One": 1, "Foolish Burial": 1, "Allure of Darkness": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Red Reign": 2, "Fiendish Chain": 2, "King's Synchro": 1, "Red Carpet": 1, "Call of the Haunted": 1},
		"extra": {"Red Rising Dragon": 3, "Red Dragon Archfiend": 1, "Scarlight Red Dragon Archfiend": 2, "Hot Red Dragon Archfiend Abyss": 2, "Hot Red Dragon Archfiend Bane": 1, "Hot Red Dragon Archfiend King Calamity": 1, "Red Nova Dragon": 1, "Tyrant Red Dragon Archfiend": 1, "Red Supernova Dragon": 1, "Scarred Dragon Archfiend": 1, "Crimson Dragon": 1}},
	# Crow's best deck: the Blackwing swarm with Black Whirlwind, into Armor Master, Silverwind and Black-Winged Dragon (v0.33.33).
	"crow": {"out": ["Curse of Dragon", "Dian Keto the Cure Master", "Follow Wind"],
		# Crow's best deck (v0.33.36): Blackwings swarming with Gale, Bora, Shura, Blizzard and Kalut into Armor Master, Armed Wing, Silverwind and Black-Winged Dragon, with Black Whirlwind, Black Sonic and Delta Crow.
		# v0.47.0, the competitive list: Blackwings that swarm from the hand.
		"main": {"Blackwing - Simoon the Poison Wind": 3, "Blackwing - Gale the Whirlwind": 3, "Blackwing - Kris the Crack of Dawn": 2, "Blackwing - Oroshi the Squall": 2, "Blackwing - Vata the Emblem of Wandering": 2, "Blackwing - Shamal the Sandstorm": 2, "Blackwing - Kalut the Moon Shadow": 2, "Blackwing - Zephyros the Elite": 1, "Blackwing - Sudri the Phantom Glimmer": 1, "Blackwing - Harmattan the Dust": 1, "Blackwing - Steam the Cloak": 1, "Blackwing - Bora the Spear": 1, "Blackwing - Shura the Blue Flame": 1, "Blackwing - Chinook the Snow Blast": 1, "Black Whirlwind": 3, "Allure of Darkness": 2, "Black Feather Whirlwind": 1, "Foolish Burial": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Blackbird Close": 3, "Delta Crow - Anti Reverse": 2, "Black Shadow Squall": 1, "Blackwing - Twin Shadow": 1, "Blackwing - Boobytrap": 1},
		"extra": {"Black-Winged Dragon": 1, "Black-Winged Assault Dragon": 1, "Blackwing Full Armor Master": 2, "Blackwing Armor Master": 1, "Assault Blackwing - Raikiri the Rain Shower": 2, "Assault Blackwing - Chidori the Rain Sprinkling": 1, "Assault Blackwing - Onimaru the Divine Thunder": 1, "Assault Blackwing - Sohaya the Rain Storm": 1, "Blackwing - Nothung the Starlight": 1, "Blackwing Tamer - Obsidian Hawk Joe": 1, "Blackwing - Boreastorm the Wicked Wind": 1, "Blackwing - Silverwind the Ascendant": 1, "Crimson Dragon": 1}},
	# Akiza's best deck: Black Rose Dragon on a Plant base, with Amaryllis, Queen Angel of Roses and Thorn of Malice (v0.33.33).
	"akiza": {"out": ["Vile Germs", "Forest"],
		# Akiza's best deck (v0.33.36): Plants and Rose Tuners into Black Rose Dragon, Splendid Rose and Queen of Thorns, with Mark of the Rose and Wicked Rebirth. v0.33.37: Tytannial.
		# v0.47.0, the competitive list: Rose Dragons and Plants.
		"main": {"Red Rose Dragon": 3, "Roxrose Dragon": 3, "White Rose Dragon": 2, "Blue Rose Dragon": 1, "Lonefire Blossom": 3, "Twilight Rose Knight": 2, "Rose Fairy": 1, "Witch of the Black Rose": 1, "Rose Princess": 1, "Spore": 1, "Dandylion": 1, "Glow-Up Bulb": 1, "Copy Plant": 1, "Tytannial, Princess of Camellias": 1, "Frozen Rose": 3, "Rose Bell of Revelation": 2, "Basal Rose Shoot": 1, "White Rose Cloister": 1, "One for One": 1, "Foolish Burial": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Blooming of the Darkest Rose": 2, "Wicked Rebirth": 1, "Urgent Tuning": 1, "Mirror Force": 1, "Torrential Tribute": 1, "Call of the Haunted": 1},
		"extra": {"Black Rose Dragon": 2, "Ruddy Rose Dragon": 2, "Black Rose Moonlight Dragon": 1, "Garden Rose Maiden": 2, "Garden Rose Flora": 2, "Queen of Thorns": 1, "Splendid Rose": 1, "Crimson Dragon": 1, "Meliae of the Trees": 1}},
	# Kalin's best deck: Infernity with an empty hand, into Infernity Doom Dragon, Void Ogre Dragon and Hundred Eyes Dragon (v0.33.33).
	"kalin": {"out": ["Hinotama", "Mystic Plasma Zone", "Dark Energy"],
		# Kalin, deck pass (v0.33.38): Infernity Launcher x2 to empty the hand and bring Infernities back.
		# v0.47.0, the competitive list: Infernity, played the way it is meant to be: empty the hand, then Infernity Archfiend, Necromancer and Launcher bring out the whole Graveyard.
		"main": {"Infernity Archfiend": 3, "Infernity Necromancer": 3, "Infernity Mirage": 2, "Infernity Beetle": 2, "Infernity Sage": 2, "Infernity Wildcat": 2, "Infernity Avenger": 1, "Infernity Destroyer": 1, "Infernity General": 1, "Stygian Street Patrol": 2, "Dark Grepher": 2, "Armageddon Knight": 1, "Infernity Launcher": 3, "Allure of Darkness": 2, "Foolish Burial": 1, "Reinforcement of the Army": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Infernity Barrier": 3, "Infernity Break": 2, "Infernity Suppression": 2, "Infernity Inferno": 1, "Void Trap Hole": 1},
		"extra": {"Void Ogre Dragon": 2, "Hundred Eyes Dragon": 2, "Infernity Doom Dragon": 1, "Infernity Doom Archfiend": 1, "Beelze of the Diabolic Dragons": 1, "Lavalval Chain": 2, "Leviair the Sea Dragon": 1, "Abyss Dweller": 1, "Number 66: Master Key Beetle": 1, "Crimson Dragon": 1}},
	"yuma": {"out": ["Celtic Guardian", "Beaver Warrior", "Battle Ox", "Masaki the Legendary Swordsman", "Silver Fang", "Dian Keto the Cure Master", "Lightning Blade", "Trap Hole"],
		"in": {"Achacha Archer": 2}, "extra_in": {"Number 17: Leviathan Dragon": 1},
		# Yuma's best deck (v0.33.36): the Gagaga engine into Utopia, the ZW weapons on Utopia Ray, Utopia Ray V and Victory, Utopia Beyond. v0.33.37: Utopia the Lightning, Utopic Future.
		# v0.47.0, the competitive list: Utopia with the Gagaga, Gogogo, Dododo and Zubaba cards merged into two monsters that search and summon each other.
		"main": {"Zubababancho Gagagacoat": 3, "Dodododwarf Gogogoglove": 3, "Gagaga Magician": 2, "Gagaga Sister": 2, "Gagaga Girl": 2, "Utopic Onomatopoeia": 1, "ZS - Ascended Sage": 2, "ZS - Armed Sage": 1, "ZW - Pegasus Twin Saber": 1, "ZW - Sylphid Wing": 1, "ZW - Eagle Claw": 1, "Goblindbergh": 1, "Onomatopaira": 3, "Onomatopickup": 2, "Zexal Construction": 2, "Zexal Entrust": 2, "Double or Nothing!": 2, "Rank-Up-Magic Zexal Force": 1, "Xyz Change Tactics": 1, "Reinforcement of the Army": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Xyz Reborn": 1, "Mirror Force": 1, "Torrential Tribute": 1, "Call of the Haunted": 1},
		"extra": {"Number 39: Utopia": 1, "Number 39: Utopia Double": 2, "Number S39: Utopia the Lightning": 1, "Number S39: Utopia Prime": 1, "Number 39: Utopia Rising": 1, "Number C39: Utopia Ray": 1, "Number 39: Utopia Beyond": 1, "Number 99: Utopic Dragon": 1, "Number 93: Utopia Kaiser": 1, "Number F0: Utopic Future": 1, "Number F0: Utopic Draco Future": 1, "ZW - Dragonic Halberd": 1, "Gagagaga Magician": 1, "Gagagaga Girl": 1}},
	# Shark's best deck: the WATER swarm into Bahamut Shark, Nightmare Shark, Shark Drake and Black Ray Lancer (v0.33.34).
	"shark": {"out": ["Dian Keto the Cure Master", "Steel Shell"], "in": {"Hyper-Ancient Shark Megalodon": 1},
		# Shark's best deck (v0.33.36): WATER Fish into Shark Drake and Veiss, Silent Honor ARK ranked up to DARK, Spider Shark, Bahamut, Poseidon Wave.
		# v0.47.0, the competitive list: WATER Xyz that never stops summoning.
		"main": {"Buzzsaw Shark": 3, "Lantern Shark": 3, "Abyss Shark": 3, "Crystal Shark": 2, "Silent Angler": 2, "Surfacing Big Jaws": 2, "Saber Shark": 1, "Double Fin Shark": 1, "Hammer Shark": 1, "Xyz Remora": 1, "Cyber Shark": 1, "Beautunaful Princess": 1, "Shark Stickers": 1, "Surface": 2, "Torpedo Takedown": 2, "Salvage": 1, "Water Hazard": 1, "Moray of Greed": 1, "Rank-Up-Magic - The Seventh One": 1, "Rank-Up-Magic Barian's Force": 1, "Foolish Burial": 1, "Mystical Space Typhoon": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Torrential Tribute": 1, "Poseidon Wave": 1, "Xyz Reborn": 1, "Mirror Force": 1, "Call of the Haunted": 1},
		"extra": {"Bahamut Shark": 2, "Toadally Awesome": 1, "Number 101: Silent Honor ARK": 1, "Number C101: Silent Honor DARK": 1, "N.As.H. Knight": 1, "CXyz N.As.Ch. Knight": 1, "Number 4: Stealth Kragen": 1, "Number 71: Rebarian Shark": 1, "Number 37: Hope Woven Dragon Spider Shark": 1, "Valiant Shark Lancer": 1, "Number 32: Shark Drake": 1, "Number 73: Abyss Splash": 1, "Black Ray Lancer": 1, "Number 47: Nightmare Shark": 1}},
	# Kite's best deck: Galaxy-Eyes Photon Dragon with every Photon and Galaxy way to bring it out, and Starliege Lord Galaxion to fetch it (v0.33.34).
	"kite": {"out": ["Luminous Spark"], "in": {"Galaxy Zero": 1},
		# v0.47.0, the competitive list: Galaxy-Eyes Photon Dragon every turn.
		"main": {"Galaxy-Eyes Photon Dragon": 3, "Galaxy-Eyes Afterglow Dragon": 2, "Photon Orbital": 3, "Photon Vanisher": 3, "Galaxy Soldier": 3, "Galaxy Wizard": 2, "Photon Thrasher": 2, "Photon Advancer": 2, "Galaxy Knight": 1, "Galaxy Summoner": 1, "Photon Emperor": 1, "Galaxy Brave": 1, "Photon Sanctuary": 3, "Galaxy Expedition": 2, "Trade-In": 2, "Galaxy Trance": 1, "Photon Hand": 1, "Accellight": 1, "Photon Stream of Destruction": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Eternal Galaxy": 1, "Photon Change": 1, "Mirror Force": 1},
		"extra": {"Number 62: Galaxy-Eyes Prime Photon Dragon": 2, "Neo Galaxy-Eyes Photon Dragon": 1, "Galaxy-Eyes Full Armor Photon Dragon": 2, "Number 90: Galaxy-Eyes Photon Lord": 2, "Galaxy-Eyes Cipher Dragon": 1, "Galaxy-Eyes Cipher Blade Dragon": 1, "Galaxy-Eyes Cipher X Dragon": 1, "Number 95: Galaxy-Eyes Dark Matter Dragon": 1, "Galaxy Photon Dragon": 1, "Starliege Photon Blast Dragon": 1, "Starliege Lord Galaxion": 1, "Number 38: Hope Harbinger Dragon Titanic Galaxy": 1}},
	"vector": {"out": ["Charcoal Inpachi", "Archfiend Soldier", "Summoned Skull", "Ryu-Kishin Powered", "Vorse Raider", "Hinotama", "Mystic Plasma Zone", "Malevolent Nuzzler"],
		"in": {"Mirror Force": 1}, "extra_out": ["Gagaga Cowboy"],
		# Vector, deck pass (v0.33.39): Torrential Tribute out (it kept wiping his own Xyz), Raigeki and a third Sakuretsu Armor in. 15 -> 23 wins of 60.
		# v0.47.0, the competitive list: Two plans.
		"main": {"Umbral Horror Ghoul": 3, "Umbral Horror Unform": 3, "Umbral Horror Will o' the Wisp": 3, "Umbral Horror Ghost": 2, "Malicevorous Fork": 2, "Malicevorous Knife": 2, "Malicevorous Spoon": 1, "Numeron Wall": 1, "Numeron Network": 3, "Numeron Calling": 3, "Terraforming": 1, "Allure of Darkness": 2, "Rank-Up-Magic Barian's Force": 1, "Rank-Up-Magic - The Seventh One": 1, "Mystical Space Typhoon": 1, "Dark Hole": 1, "Raigeki": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Fiendish Chain": 2, "Vain Betrayer": 1, "Dark Bribe": 1, "Mirror Force": 1, "Torrential Tribute": 1, "Call of the Haunted": 1},
		"extra": {"Number 104: Masquerade": 2, "Number C104: Umbral Horror Masquerade": 1, "Number 1: Numeron Gate Ekam": 1, "Number 2: Numeron Gate Dve": 1, "Number 3: Numeron Gate Trini": 1, "Number 4: Numeron Gate Catvari": 1, "Number C1: Numeron Chaos Gate Sunya": 1, "Number C1000: Numerounius": 1, "Number iC1000: Numerounius Numerounia": 1, "Number 66: Master Key Beetle": 1, "Number 96: Dark Mist": 1, "Number C96: Dark Storm": 1, "Number 65: Djinn Buster": 1, "Number C65: King Overfiend": 1}},
}


## Does this card really work here? A monster with an effect has to be on the exact list (a
## monster nobody has written rules for would otherwise pass as "has no effect"); a Spell or
## Trap has to have rules of its own.
static func _works(id: int) -> bool:
	var d := CardData.get_card(id)
	if d.is_empty() or not CardExact.ok(d):
		return false
	if CardPool.has(id):
		return true       # (in the game's pool: the rules engine plays it by its real script)
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
	if text.strip_edges() == "":
		# (A card written into the game itself carries no text of its own: the card folder's.)
		text = str((CardData.EXT.get(int(d.get("id", 0)), {}) as Dictionary).get("desc", ""))
		if text == "":
			text = str((CardData.EXT.get(int(CardData.NAME_TO_ID.get(str(d.get("name", "")).to_lower(), 0)), {}) as Dictionary).get("desc", ""))
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
