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
		"main": {"Dark Magician": 3, "Dark Magician Girl": 3, "Skilled Dark Magician": 3, "Breaker the Magical Warrior": 1, "Buster Blader": 1, "Slifer the Sky Dragon": 1, "Queen's Knight": 1, "King's Knight": 1, "Jack's Knight": 1, "Marshmallon": 1, "Kuriboh": 1, "Dark Magic Curtain": 2, "Thousand Knives": 1, "Dark Magic Attack": 1, "Sage's Stone": 1, "Polymerization": 1, "Swords of Revealing Light": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Graceful Charity": 1, "Premature Burial": 1, "Change of Heart": 1, "Mirror Force": 1, "Magic Cylinder": 2, "Spellbinding Circle": 1, "Call of the Haunted": 1, "Alpha The Magnet Warrior": 1, "Beta The Magnet Warrior": 1, "Gamma The Magnet Warrior": 1, "Valkyrion the Magna Warrior": 1, "Knight's Title": 1, "Dark Magician Knight": 1},
		"extra": {"Dark Paladin": 1, "Arcana Knight Joker": 1}},
	"kaiba": {"out": ["Rude Kaiser", "Koumori Dragon", "Cyber Dragon", "Mystic Tomato", "Mountain", "Dragon Treasure", "Torrential Tribute", "Trap Hole"],
		"in": {"X-Head Cannon": 1, "Y-Dragon Head": 1, "Z-Metal Tank": 1, "Saggi the Dark Clown": 1, "Hitotsu-Me Giant": 1, "Luster Dragon": 2, "Vampire Lord": 1},
		"extra_in": {"XYZ-Dragon Cannon": 1},
		# Kaiba, deck pass (v0.33.36): Blue-Eyes with every way to get it out (Kaibaman x3, Kaiser Sea Horse x3, Lord of D. + Flute, Call of the Haunted), Obelisk, Vampire Lord, Crush Card. The single XYZ pieces and the vanilla filler are out. v0.33.37: Chaos Emperor Dragon in.
		"main": {"Blue-Eyes White Dragon": 3, "Kaibaman": 3, "Lord of D.": 2, "Kaiser Sea Horse": 3, "Vorse Raider": 3, "Blade Knight": 1, "Vampire Lord": 2, "Obelisk the Tormentor": 1, "The Flute of Summoning Dragon": 2, "Burst Stream of Destruction": 1, "Cost Down": 1, "Polymerization": 2, "Monster Reborn": 1, "Pot of Greed": 1, "Enemy Controller": 2, "Shrink": 1, "Heavy Storm": 1, "Premature Burial": 1, "Graceful Charity": 1, "Crush Card Virus": 1, "Ring of Destruction": 1, "Negate Attack": 1, "Mirror Force": 1, "Call of the Haunted": 2, "Blue-Eyes Shining Dragon": 1, "Chaos Emperor Dragon - Envoy of the End": 1},
		"extra": {"Blue-Eyes Ultimate Dragon": 2}},
	"joey": {"out": ["Garoozis", "Battle Steer", "Tiger Axe", "Dian Keto the Cure Master", "Sogen", "Waboku", "Trap Hole"],
		"in": {"Battle Warrior": 1, "Swordsman of Landstar": 2, "Goblin Attack Force": 1, "Salamandra": 1, "Giant Trunade": 1, "Foolish Burial": 1},
		# Joey, deck pass (v0.33.36): Red-Eyes, Jinzo x2, Gearfried x3, Goblin Attack Force x3, his dice and Scapegoat. The weak vanilla Warriors are out. v0.33.37: Metalmorph into Red-Eyes Black Metal Dragon.
		"main": {"Red-Eyes Black Dragon": 2, "Jinzo": 2, "Summoned Skull": 1, "Panther Warrior": 1, "Gearfried the Iron Knight": 2, "Rocket Warrior": 1, "Goblin Attack Force": 3, "Baby Dragon": 1, "Time Wizard": 1, "Scapegoat": 2, "Polymerization": 2, "Graceful Dice": 2, "Giant Trunade": 1, "Foolish Burial": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Graceful Charity": 1, "Reinforcement of the Army": 2, "The Warrior Returning Alive": 1, "Premature Burial": 1, "Skull Dice": 2, "Sakuretsu Armor": 2, "Mirror Force": 1, "Call of the Haunted": 1, "Gilford the Lightning": 1, "Release Restraint": 1, "Gearfried the Swordmaster": 1, "Metalmorph": 1, "Red-Eyes Black Metal Dragon": 1},
		"extra": {"Thousand Dragon": 1, "Black Skull Dragon": 1}},
	"mai": {"out": ["Hinotama", "Dian Keto the Cure Master", "Fissure", "Follow Wind", "Pot of Greed"],
		"in": {"Dunames Dark Witch": 2, "Amazoness Fighter": 2, "Amazoness Swords Woman": 2, "Harpie Lady Sisters": 2, "Elegant Egotist": 3, "Cyber Shield": 2, "Mirror Wall": 1, "Electro-Whip": 1},
		# Mai's best deck (v0.33.36): Harpie Ladies on Harpies' Hunting Ground with Elegant Egotist, Harpie's Pet Dragon, Phoenix Formation, Triangle Ecstasy Spark and Hysteric Party, plus her Amazonesses.
		"main": {"Harpie Lady": 3, "Harpie Queen": 2, "Harpie Channeler": 3, "Harpie Lady Sisters": 2, "Harpie's Pet Dragon": 3, "Birdface": 2, "Amazoness Paladin": 2, "Amazoness Swords Woman": 2, "Harpie Girl": 1, "Harpies' Hunting Ground": 3, "Elegant Egotist": 3, "Harpie Lady Phoenix Formation": 1, "Triangle Ecstasy Spark": 1, "Harpie's Feather Duster": 1, "Cyber Shield": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Hysteric Party": 2, "Amazoness Archers": 2, "Mirror Wall": 1, "Gravity Bind": 1, "Mirror Force": 1, "Call of the Haunted": 1},
		"extra": {}},
	"bakura": {"out": ["Newdoria", "Curse of Dragon", "Summoned Skull", "Ryu-Kishin", "Lord of the Lamp", "Fissure", "Dark Energy", "Dark Core", "Yami"],
		"in": {"The Portrait's Secret": 1, "Earthbound Spirit": 2, "Souls of the Forgotten": 1, "The Gross Ghost of Fled Dreams": 1, "Man-Eater Bug": 2, "Lady of Faith": 1,
			"Change of Heart": 1, "Just Desserts": 1, "The Dark Door": 1},
		# Bakura, deck pass (v0.33.36): Dark Necrofear x3 with enough Fiends to feed her, Diabound Kernel, Destiny Board, and the old power cards. v0.33.37: Dark Sanctuary.
		"main": {"Dark Necrofear": 3, "Dark Ruler Ha Des": 2, "Headless Knight": 3, "The Earl of Demise": 2, "The Portrait's Secret": 2, "Earthbound Spirit": 2, "Morphing Jar": 1, "Man-Eater Bug": 3, "Sangan": 1, "White Magical Hat": 1, "Change of Heart": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Graceful Charity": 1, "Dark Hole": 1, "Raigeki": 1, "Premature Burial": 1, "Swords of Revealing Light": 1, "Destiny Board": 2, "Spirit Message \"I\"": 1, "Spirit Message \"N\"": 1, "Spirit Message \"A\"": 1, "Spirit Message \"L\"": 1, "Mirror Force": 1, "Torrential Tribute": 1, "Call of the Haunted": 1, "Diabound Kernel": 2, "Dark Sanctuary": 1},
		"extra": {}},
	"marik": {"out": ["Dark Blade", "Vampire Lord", "Feral Imp", "Mystic Lamp", "Stone Statue of the Aztecs", "Hinotama", "Mystic Plasma Zone", "Malevolent Nuzzler", "Magic Jammer"],
		"in": {"Legendary Fiend": 1, "Lord Poison": 1, "Melchid the Four-Face Beast": 1, "Newdoria": 2, "Card of Sanctity": 1, "Mirror Force": 1, "Remove Trap": 1},
		# Marik's best deck (v0.33.36): Lava Golem, Revival Jam with Jam Defender, Viser Des and Helpoemer, Nightmare Wheel and Coffin Seller, and The Winged Dragon of Ra.
		"main": {"Lava Golem": 2, "The Winged Dragon of Ra": 1, "Gil Garth": 2, "Revival Jam": 3, "Drillago": 2, "Bowganian": 1, "Granadora": 1, "Legendary Fiend": 1, "Viser Des": 2, "Helpoemer": 2, "Melchid the Four-Face Beast": 1, "Newdoria": 2, "Dark Jeroid": 1, "Byser Shock": 1, "Card of Sanctity": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Dark Hole": 1, "Raigeki": 1, "Nightmare Wheel": 3, "Jam Defender": 2, "Coffin Seller": 2, "Metal Reflect Slime": 2, "Malevolent Catastrophe": 1, "Mirror Force": 1, "Call of the Haunted": 1, "Torrential Tribute": 1},
		"extra": {}},
	"pegasus": {"out": ["Fissure", "Raigeki", "Shadow Spell", "Heavy Storm"], "in": {"Dark Rabbit": 1, "Parrot Dragon": 1, "Illusionist Faceless Mage": 1},
		# Pegasus, deck pass (v0.33.39): Mystical Space Typhoon x2 and Sakuretsu Armor instead of Heavy Storm, Dark Hole and a Torrential Tribute (they killed his own Toons and Toon World).
		"main": {"Toon Summoned Skull": 2, "Blue-Eyes Toon Dragon": 2, "Toon Dark Magician Girl": 2, "Toon Gemini Elf": 2, "Toon Mermaid": 2, "Toon Goblin Attack Force": 2, "Toon Cannon Soldier": 1, "Relinquished": 2, "Thousand-Eyes Idol": 2, "Toon World": 3, "Toon Table of Contents": 3, "Black Illusion Ritual": 2, "Polymerization": 2, "Pot of Greed": 1, "Graceful Charity": 1, "Monster Reborn": 1, "Change of Heart": 1, "Raigeki": 1, "Swords of Revealing Light": 1, "Mirror Force": 1, "Magic Cylinder": 1, "Call of the Haunted": 1, "Ring of Destruction": 1, "Mystical Space Typhoon": 2, "Sakuretsu Armor": 1},
		"extra": {"Thousand-Eyes Restrict": 2}},
	"weevil": {"out": ["Insect Knight", "Neo Bug", "Gokipon", "Dian Keto the Cure Master", "Just Desserts", "Fissure"],
		"in": {"Big Insect": 2, "Flying Kamakiri #1": 2, "Gokibore": 2, "Man-Eater Bug": 2, "Needle Worm": 1, "Skull-Mark Ladybug": 1},
		# Weevil, deck pass (v0.33.36): the lock (DNA Surgery + Insect Barrier), Insect Queen, Parasite Paracide, and the old power cards. The vanilla Insects are out.
		"main": {"Insect Queen": 2, "Perfectly Ultimate Great Moth": 1, "Petit Moth": 1, "Cocoon of Evolution": 2, "Parasite Paracide": 2, "Pinch Hopper": 3, "Flying Kamakiri #1": 3, "Man-Eater Bug": 3, "Skull-Mark Ladybug": 1, "Leghul": 1, "Killer Needle": 1, "Insect Barrier": 2, "Insect Armor with Laser Cannon": 2, "Multiplication of Ants": 1, "Swords of Revealing Light": 1, "Raigeki": 1, "Dark Hole": 1, "Heavy Storm": 1, "Pot of Greed": 1, "Graceful Charity": 1, "Monster Reborn": 1, "Change of Heart": 1, "DNA Surgery": 3, "Mirror Force": 1, "Magic Cylinder": 1, "Torrential Tribute": 1, "Call of the Haunted": 1},
		"extra": {}},
	"rex": {"out": ["Hinotama", "Dian Keto the Cure Master", "Hammer Shot", "Fissure", "Rush Recklessly"],
		"in": {"Dark Driceratops": 1, "Frostosaurus": 1, "Serpent Night Dragon": 1, "Trakodon": 2, "Black Stego": 2, "Babycerasaurus": 2, "Hyper Hammerhead": 2, "Element Saurus": 2, "Fossil Excavation": 2},
		# Rex's best deck (v0.33.36): Dinosaurs with Gilasaurus and Babycerasaurus for Tributes, Black Tyranno, Dark Driceratops, Ultimate Tyranno and Super Conductor Tyranno, Jurassic World and Tail Swipe. v0.33.37: Tyrant Dragon.
		"main": {"Black Tyranno": 2, "Ultimate Tyranno": 1, "Super Conductor Tyranno": 1, "Dark Driceratops": 3, "Gilasaurus": 3, "Babycerasaurus": 2, "Sabersaurus": 3, "Element Saurus": 2, "Hyper Hammerhead": 2, "Black Stego": 2, "Two-Headed King Rex": 2, "Serpent Night Dragon": 1, "Jurassic World": 2, "Tail Swipe": 2, "Raise Body Heat": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Smashing Ground": 1, "Heavy Storm": 1, "Fossil Excavation": 2, "Call of the Haunted": 2, "Sakuretsu Armor": 1, "Mirror Force": 1, "Tyrant Dragon": 1},
		"extra": {}},
	# Jaden's best deck: Neos, the Neo-Spacians and Contact Fusion, with the first Elemental HEROes behind them (v0.33.32).
	"jaden": {"out": ["Celtic Guardian"], "in": {"Elemental HERO Bladedge": 1},
		# Jaden, deck pass (v0.33.39): tested over 60 duels each. Yubel and her forms are out (they sat dead in the hand: 3 Tributes), two of each fusion half, Clayman/Bubbleman x2, Wildheart, an extra Emergency Call and Miracle Fusion. 14 -> 21 wins of 60.
		"main": {"Elemental HERO Neos": 2, "Elemental HERO Sparkman": 3, "Elemental HERO Avian": 2, "Elemental HERO Burstinatrix": 2, "Elemental HERO Clayman": 2, "Elemental HERO Bladedge": 1, "Elemental HERO Necroshade": 1, "Elemental HERO Bubbleman": 2, "Neo-Spacian Grand Mole": 2, "Neo-Spacian Aqua Dolphin": 1, "Neo-Spacian Flare Scarab": 1, "Neo-Spacian Air Hummingbird": 1, "Card Trooper": 1, "Winged Kuriboh": 1, "Polymerization": 3, "Miracle Fusion": 3, "E - Emergency Call": 3, "O - Oversoul": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Hero Signal": 2, "Hero Barrier": 1, "Negate Attack": 1, "Mirror Force": 1, "Elemental HERO Wildheart": 1},
		"extra": {"Elemental HERO Grand Neos": 1, "Elemental HERO Flare Neos": 1, "Elemental HERO Air Neos": 1, "Elemental HERO Aqua Neos": 1, "Elemental HERO Storm Neos": 1, "Elemental HERO Magma Neos": 1, "Elemental HERO Flame Wingman": 2, "Elemental HERO Shining Flare Wingman": 2, "Elemental HERO Thunder Giant": 2, "Elemental HERO Rampart Blaster": 1, "Elemental HERO Tempest": 1, "Elemental HERO Electrum": 1}},
	"chazz": {"out": ["Dragon Treasure", "Rush Recklessly"], "in": {"Masked Dragon": 2, "V-Tiger Jet": 1},
		# Chazz's best deck (v0.33.36): the Armed Dragons up to LV10 with Level Up!, the Ojamas into Ojama King and Ojama Delta Hurricane!!, and the VWXYZ Union line. v0.33.37: Light and Darkness Dragon, Ojama Knight.
		"main": {"Armed Dragon LV3": 3, "Armed Dragon LV5": 2, "Armed Dragon LV7": 2, "Armed Dragon LV10": 1, "Masked Dragon": 2, "X-Head Cannon": 2, "Y-Dragon Head": 2, "Z-Metal Tank": 2, "V-Tiger Jet": 1, "W-Wing Catapult": 1, "Ojama Yellow": 3, "Ojama Green": 2, "Ojama Black": 2, "Ojama Red": 1, "Level Up!": 2, "Ojamagic": 1, "Ojama Delta Hurricane!!": 1, "Ojamuscle": 1, "Polymerization": 2, "Pot of Greed": 1, "Monster Reborn": 1, "Heavy Storm": 1, "Call of the Haunted": 2, "Ring of Destruction": 1, "Light and Darkness Dragon": 1},
		"extra": {"XYZ-Dragon Cannon": 1, "VW-Tiger Catapult": 1, "VWXYZ-Dragon Catapult Cannon": 1, "Ojama King": 2, "Ojama Knight": 1}},
	"zane": {"out": ["X-Head Cannon", "Elemental HERO Burstinatrix", "Charcoal Inpachi", "Millennium Shield"], "in": {"Call of the Haunted": 1},
		# Zane, deck pass (v0.33.37): Cyberdark Impact! and Chimeratech Overdragon in, Cyber Dragon Zwei for a fourth Cyber Dragon, one Polymerization out.
		"main": {"Cyber Dragon": 3, "Proto-Cyber Dragon": 2, "Cyber Phoenix": 2, "Cyber Kirin": 1, "Cyber Larva": 2, "Cyber Laser Dragon": 1, "Cyber Barrier Dragon": 1, "Cyberdark Horn": 2, "Cyberdark Edge": 2, "Cyberdark Keel": 2, "Masked Dragon": 1, "Polymerization": 2, "Power Bond": 3, "Limiter Removal": 1, "De-Fusion": 1, "Photon Generator Unit": 1, "Different Dimension Capsule": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Heavy Storm": 1, "Attack Reflector Unit": 1, "Trap Jammer": 2, "Call of the Haunted": 2, "Negate Attack": 1, "Mirror Force": 1, "Cyberdark Impact!": 1, "Cyber Dragon Zwei": 1},
		"extra": {"Cyber Twin Dragon": 2, "Cyber End Dragon": 2, "Cyberdark Dragon": 2, "Chimeratech Overdragon": 1}},
	"alexis": {"out": ["Dian Keto the Cure Master", "Luminous Spark", "Horn of the Unicorn", "Fissure", "Cyber Petit Angel"],
		"in": {"Hallowed Life Barrier": 1, "Machine Angel Ritual": 3, "Fusion Weapon": 1, "Ritual Weapon": 2}, "extra_in": {"Cyber Blader": 2},
		# Alexis, deck pass (v0.33.39): Mystical Space Typhoon instead of Heavy Storm.
		"main": {"Cyber Tutu": 3, "Etoile Cyber": 3, "Blade Skater": 3, "Cyber Gymnast": 3, "Cyber Prima": 1, "Cyber Petit Angel": 3, "Cyber Angel Benten": 2, "Cyber Angel Idaten": 1, "Cyber Angel Dakini": 2, "Machine Angel Ritual": 3, "Polymerization": 2, "Pot of Greed": 1, "Monster Reborn": 1, "Swords of Revealing Light": 1, "Fusion Weapon": 1, "Ritual Weapon": 1, "Doble Passe": 2, "Mirror Force": 1, "Sakuretsu Armor": 2, "Call of the Haunted": 2, "Hallowed Life Barrier": 1, "Mystical Space Typhoon": 1},
		"extra": {"Cyber Blader": 2}},
	"syrus": {"out": ["Elemental HERO Clayman", "Dian Keto the Cure Master"], "in": {"Shield Crush": 1},
		# Syrus, deck pass (v0.33.39): No Entry!! out (it turned his own attackers to Defense), Mirror Force and Sakuretsu Armor in. 17 -> 30 wins of 60.
		"main": {"Steamroid": 3, "Drillroid": 3, "Submarineroid": 2, "Gyroid": 2, "Expressroid": 2, "Truckroid": 2, "Stealthroid": 2, "UFOroid": 2, "Cycroid": 1, "Decoyroid": 1, "Rescueroid": 1, "Armoroid": 1, "Polymerization": 3, "Power Bond": 3, "Pot of Greed": 1, "Monster Reborn": 1, "Limiter Removal": 1, "Supercharge": 2, "Negate Attack": 1, "Draining Shield": 1, "Shield Crush": 1, "Call of the Haunted": 2, "Mirror Force": 1, "Sakuretsu Armor": 1},
		"extra": {"Steam Gyroid": 2, "Super Vehicroid Jumbo Drill": 2, "Super Vehicroid - Stealth Union": 2, "Pair Cycroid": 1}},
	"aster": {"out": ["Celtic Guardian", "Mystic Plasma Zone"],
		# Aster, deck pass (v0.33.39): two Clock Tower Prisons for Dreadmaster, Mystical Space Typhoon instead of Heavy Storm (it broke his own Prison). 14 -> 20 wins of 60.
		"main": {"Destiny HERO - Diamond Dude": 3, "Destiny HERO - Malicious": 3, "Destiny HERO - Disk Commander": 2, "Destiny HERO - Dasher": 2, "Destiny HERO - Plasma": 1, "Destiny HERO - Dreadmaster": 1, "Destiny HERO - Double Dude": 2, "Destiny HERO - Captain Tenacious": 1, "Destiny HERO - Dunker": 1, "Destiny Draw": 3, "Clock Tower Prison": 2, "D - Spirit": 1, "Dark City": 1, "Pot of Greed": 1, "Monster Reborn": 1, "Polymerization": 1, "Mystical Space Typhoon": 2, "Destiny Signal": 2, "Eternal Dread": 1, "D - Chain": 1, "Call of the Haunted": 1, "Mirror Force": 1, "Negate Attack": 1, "Destiny HERO - Dogma": 2, "Destiny HERO - Defender": 1, "Destiny HERO - Doom Lord": 1, "Swords of Revealing Light": 1},
		"extra": {"Destiny End Dragoon": 2}},
	# Yusei's best deck: the Shooting Star Dragon and Shooting Quasar Dragon one (v0.33.28).
	"yusei": {"out": ["Celtic Guardian", "Beaver Warrior"],
		# Yusei's best deck (v0.33.36): 9 Tuners, Junk Synchron into Junk Warrior and Stardust Dragon, Shooting Star and Shooting Quasar, Majestic Star Dragon.
		"main": {"Junk Synchron": 3, "Quickdraw Synchron": 2, "Debris Dragon": 2, "Effect Veiler": 2, "Speed Warrior": 2, "Max Warrior": 2, "Quillbolt Hedgehog": 3, "Doppelwarrior": 3, "Level Eater": 2, "Synchron Explorer": 2, "Tuningware": 2, "Shield Warrior": 1, "Tuning": 3, "One for One": 1, "Double Summon": 1, "Cards of Consonance": 1, "Scrap-Iron Scarecrow": 3, "Starlight Road": 1, "Graceful Revival": 1, "Shooting Star": 1, "Defense Draw": 1, "Majestic Dragon": 1},
		"extra": {"Stardust Dragon": 2, "Shooting Star Dragon": 1, "Shooting Quasar Dragon": 1, "Majestic Star Dragon": 1, "Formula Synchron": 1, "Junk Warrior": 2, "Junk Destroyer": 1, "Junk Archer": 1, "Junk Berserker": 1, "Road Warrior": 1, "Turbo Warrior": 1, "Nitro Warrior": 1, "Junk Gardna": 1}},
	# Jack's best deck: Red Dragon Archfiend on Resonators, with Exploder Dragonwing and Chaos King Archfiend beside it (v0.33.33).
	"jack": {"out": ["Molten Destruction", "Salamandra"],
		# Jack's best deck (v0.33.36): Resonators into Red Dragon Archfiend, then two more Tuners for Red Nova Dragon, and Majestic Red Dragon. v0.33.37: Assault Mode, Crimson Blader.
		"main": {"Dark Resonator": 3, "Flare Resonator": 2, "Creation Resonator": 2, "Chain Resonator": 2, "Synkron Resonator": 1, "Dread Dragon": 1, "Vice Dragon": 3, "Mad Archfiend": 2, "Big Piece Golem": 1, "Power Breaker": 1, "Strong Wind Dragon": 2, "Twin-Sword Marauder": 1, "Archfiend Interceptor": 1, "Battle Fader": 1, "Resonator Call": 3, "Scarlet Security": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Mystical Space Typhoon": 1, "Fiendish Chain": 2, "Powerful Rebirth": 2, "Call of the Haunted": 1, "Half or Nothing": 1, "Majestic Dragon": 1, "Red Dragon Archfiend/Assault Mode": 1, "Assault Mode Activate": 2},
		"extra": {"Red Dragon Archfiend": 2, "Scarlight Red Dragon Archfiend": 1, "Red Nova Dragon": 2, "Majestic Red Dragon": 1, "Exploder Dragonwing": 1, "Chaos King Archfiend": 1, "Crimson Blader": 1}},
	# Crow's best deck: the Blackwing swarm with Black Whirlwind, into Armor Master, Silverwind and Black-Winged Dragon (v0.33.33).
	"crow": {"out": ["Curse of Dragon", "Dian Keto the Cure Master", "Follow Wind"],
		# Crow's best deck (v0.33.36): Blackwings swarming with Gale, Bora, Shura, Blizzard and Kalut into Armor Master, Armed Wing, Silverwind and Black-Winged Dragon, with Black Whirlwind, Black Sonic and Delta Crow.
		"main": {"Blackwing - Gale the Whirlwind": 3, "Blackwing - Bora the Spear": 3, "Blackwing - Shura the Blue Flame": 3, "Blackwing - Blizzard the Far North": 3, "Blackwing - Kalut the Moon Shadow": 3, "Blackwing - Sirocco the Dawn": 2, "Blackwing - Elphin the Raven": 1, "Blackwing - Fane the Steel Chain": 1, "Blackwing - Mistral the Silver Shield": 2, "Blackwing - Gust the Backblast": 2, "Blackwing - Ghibli the Searing Wind": 1, "Black Whirlwind": 3, "Cards for Black Feathers": 1, "Against the Wind": 1, "Monster Reborn": 1, "Black Sonic": 2, "Delta Crow - Anti Reverse": 2, "Black Thunder": 1, "Blackwing - Backlash": 1, "Blackback": 2, "Trap Stun": 1, "Urgent Tuning": 1},
		"extra": {"Blackwing Armor Master": 2, "Blackwing Armed Wing": 2, "Blackwing - Silverwind the Ascendant": 1, "Black-Winged Dragon": 2}},
	# Akiza's best deck: Black Rose Dragon on a Plant base, with Amaryllis, Queen Angel of Roses and Thorn of Malice (v0.33.33).
	"akiza": {"out": ["Vile Germs", "Forest"],
		# Akiza's best deck (v0.33.36): Plants and Rose Tuners into Black Rose Dragon, Splendid Rose and Queen of Thorns, with Mark of the Rose and Wicked Rebirth. v0.33.37: Tytannial.
		"main": {"Twilight Rose Knight": 3, "Witch of the Black Rose": 2, "Copy Plant": 2, "Lonefire Blossom": 2, "Rose Tentacles": 2, "Lord Poison": 2, "Evil Thorn": 2, "Dark Verger": 3, "Violet Witch": 1, "Rose Fairy": 2, "Phoenixian Seed": 2, "Phoenixian Cluster Amaryllis": 1, "Blue Rose Dragon": 1, "Queen Angel of Roses": 1, "Seed of Deception": 1, "Thorn of Malice": 2, "Mark of the Rose": 2, "Monster Reborn": 1, "Pot of Greed": 1, "Wicked Rebirth": 2, "Blossom Bombardment": 1, "Urgent Tuning": 1, "Sakuretsu Armor": 1, "Mirror Force": 1, "Tytannial, Princess of Camellias": 1},
		"extra": {"Black Rose Dragon": 2, "Splendid Rose": 1, "Queen of Thorns": 1}},
	# Kalin's best deck: Infernity with an empty hand, into Infernity Doom Dragon, Void Ogre Dragon and Hundred Eyes Dragon (v0.33.33).
	"kalin": {"out": ["Hinotama", "Mystic Plasma Zone", "Dark Energy"],
		# Kalin, deck pass (v0.33.38): Infernity Launcher x2 to empty the hand and bring Infernities back.
		"main": {"Infernity Archfiend": 3, "Infernity Necromancer": 3, "Infernity Beetle": 3, "Infernity Mirage": 2, "Infernity Avenger": 2, "Infernity Destroyer": 2, "Infernity Beast": 2, "Infernity Guardian": 1, "Infernity Knight": 1, "Infernity General": 1, "Infernity Randomizer": 1, "ZERO-MAX": 2, "Card Destruction": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Infernity Inferno": 2, "Infernity Break": 2, "Infernity Barrier": 2, "Infernity Force": 2, "Infernity Reflector": 2, "Full Salvo": 1, "Void Trap Hole": 1, "Infernity Launcher": 2},
		"extra": {"Infernity Doom Dragon": 2, "Void Ogre Dragon": 1, "Hundred Eyes Dragon": 1}},
	"yuma": {"out": ["Celtic Guardian", "Beaver Warrior", "Battle Ox", "Masaki the Legendary Swordsman", "Silver Fang", "Dian Keto the Cure Master", "Lightning Blade", "Trap Hole"],
		"in": {"Achacha Archer": 2}, "extra_in": {"Number 17: Leviathan Dragon": 1},
		# Yuma's best deck (v0.33.36): the Gagaga engine into Utopia, the ZW weapons on Utopia Ray, Utopia Ray V and Victory, Utopia Beyond. v0.33.37: Utopia the Lightning, Utopic Future.
		"main": {"Gagaga Magician": 3, "Gagaga Girl": 2, "Gagaga Clerk": 2, "Gagaga Mancer": 1, "Gagaga Head": 1, "Gogogo Golem": 2, "Zubaba Knight": 2, "Goblindbergh": 3, "Kagetokage": 2, "Dododo Warrior": 1, "Gagaga Gardna": 1, "ZW - Unicorn Spear": 1, "ZW - Phoenix Bow": 1, "ZW - Lightning Blade": 1, "ZW - Tornado Bringer": 1, "Gagagatag": 1, "Onomatopaira": 2, "Gagagabolt": 2, "Rank-Up-Magic Limited Barian's Force": 1, "Xyz Gift": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Half Unbreak": 2, "Gagagarevenge": 2, "Battle Break": 1, "Bye Bye Damage": 1, "Xyz Energy": 1},
		"extra": {"Number 39: Utopia": 2, "Number C39: Utopia Ray": 2, "Number C39: Utopia Ray V": 1, "Number C39: Utopia Ray Victory": 1, "Number 39: Utopia Beyond": 1, "ZW - Leo Arms": 1, "Gagaga Samurai": 1, "Gagaga Cowboy": 1, "Number 34: Terror-Byte": 1, "Number 61: Volcasaurus": 1, "Number 17: Leviathan Dragon": 1, "Number S39: Utopia the Lightning": 1, "Number F0: Utopic Future": 1}},
	# Shark's best deck: the WATER swarm into Bahamut Shark, Nightmare Shark, Shark Drake and Black Ray Lancer (v0.33.34).
	"shark": {"out": ["Dian Keto the Cure Master", "Steel Shell"], "in": {"Hyper-Ancient Shark Megalodon": 1},
		# Shark's best deck (v0.33.36): WATER Fish into Shark Drake and Veiss, Silent Honor ARK ranked up to DARK, Spider Shark, Bahamut, Poseidon Wave.
		"main": {"Hammer Shark": 3, "Shark Stickers": 2, "Spear Shark": 2, "Double Shark": 2, "Big Jaws": 2, "Skull Kraken": 1, "Eagle Shark": 1, "Panther Shark": 2, "Silent Angler": 2, "Cyber Shark": 2, "Mermaid Shark": 2, "Double Fin Shark": 2, "Depth Shark": 2, "Needle Sunfish": 1, "Jawsman": 1, "Rank-Up-Magic Limited Barian's Force": 2, "Aqua Jet": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Mystical Space Typhoon": 1, "Poseidon Wave": 2, "Surface": 1, "Call of the Haunted": 1, "Torrential Tribute": 1, "Mirror Force": 1, "Sakuretsu Armor": 1},
		"extra": {"Number 32: Shark Drake": 1, "Number C32: Shark Drake Veiss": 1, "Number 101: Silent Honor ARK": 2, "Number C101: Silent Honor DARK": 1, "Number 37: Hope Woven Dragon Spider Shark": 1, "Black Ray Lancer": 1, "Bahamut Shark": 2, "Number 73: Abyss Splash": 1, "Number 47: Nightmare Shark": 1, "Submersible Carrier Aero Shark": 1, "Number 17: Leviathan Dragon": 1, "Number 71: Rebarian Shark": 1}},
	# Kite's best deck: Galaxy-Eyes Photon Dragon with every Photon and Galaxy way to bring it out, and Starliege Lord Galaxion to fetch it (v0.33.34).
	"kite": {"out": ["Luminous Spark"], "in": {"Galaxy Zero": 1},
		"main": {"Galaxy-Eyes Photon Dragon": 3, "Photon Thrasher": 3, "Photon Crusher": 2, "Photon Lizard": 2, "Photon Cerberus": 1, "Photon Leo": 1, "Photon Sabre Tiger": 2,
			"Galaxy Knight": 2, "Galaxy Soldier": 2, "Galaxy Wizard": 2, "Photon Slasher": 2, "Photon Caesar": 2, "Photon Wyvern": 1, "Photon Pirate": 1, "Daybreaker": 2,
			"Photon Circle": 1, "Photon Chargeman": 1,
			"Accellight": 2, "Galaxy Expedition": 2, "Photon Lead": 1, "Galaxy Storm": 1, "Galaxy Zero": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Mirror Force": 1},
		"extra": {"Neo Galaxy-Eyes Photon Dragon": 1, "Number 62: Galaxy-Eyes Prime Photon Dragon": 2, "Starliege Lord Galaxion": 2, "Starliege Paladynamo": 1, "Photon Papilloperative": 1, "Number 10: Illumiknight": 1}},
	"vector": {"out": ["Charcoal Inpachi", "Archfiend Soldier", "Summoned Skull", "Ryu-Kishin Powered", "Vorse Raider", "Hinotama", "Mystic Plasma Zone", "Malevolent Nuzzler"],
		"in": {"Mirror Force": 1}, "extra_out": ["Gagaga Cowboy"],
		# Vector, deck pass (v0.33.39): Torrential Tribute out (it kept wiping his own Xyz), Raigeki and a third Sakuretsu Armor in. 15 -> 23 wins of 60.
		"main": {"Umbral Horror Ghoul": 3, "Umbral Horror Unform": 3, "Umbral Horror Will o' the Wisp": 3, "Umbral Horror Ghost": 3, "Malicevorous Fork": 3, "Malicevorous Knife": 3, "Rank-Up-Magic Barian's Force": 2, "Rank-Up-Magic Limited Barian's Force": 1, "Monster Reborn": 1, "Pot of Greed": 1, "Dark Hole": 1, "Mystical Space Typhoon": 2, "Swords of Revealing Light": 1, "Book of Moon": 1, "Shadow Spell": 2, "Vain Betrayer": 2, "Dark Bribe": 2, "Mirror Force": 2, "Sakuretsu Armor": 2, "Call of the Haunted": 1, "Raigeki": 1},
		"extra": {"Number 104: Masquerade": 2, "Number C104: Umbral Horror Masquerade": 1, "Number 66: Master Key Beetle": 1, "Number 65: Djinn Buster": 1, "Number C65: King Overfiend": 1, "Number 96: Dark Mist": 1, "Number C96: Dark Storm": 1, "Number 43: Manipulator of Souls": 1}},
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
