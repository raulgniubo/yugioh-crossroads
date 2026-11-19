class_name CardPool
extends RefCounted
## Which cards are in the game. The pool as it stood when duels moved to the rules engine is
## written down in data/pool.json (by set). Everything added since is named in the code: a whole
## family in Collection.FAMILIES, a single card in ADDED below. A card is in the game when it
## is in one of those and the card folder knows it. How a card plays is the rules engine's
## business (its script), not this file's.

## Single cards added after the pool was written down, by the era pack that hands them out.
const ADDED := {
	# Crass Clown and Dream Clown are what Bickuribox is made of; Ambulanceroid, Ambulance Rescueroid.
	# The rest of each era's list are the last cards its story duelists are known for
	# (SignatureDecks.WISH): single cards that belong to no family.
	"Duel Monsters": [
		# 0.52.0: card plan part 3, single cards (staples and support that belong to no family).
		"Andro Sphinx", "Sphinx Teleia", "Theinen the Great Sphinx", "Fortress Whale's Oath", "The First Sarcophagus", "The Second Sarcophagus", "The Third Sarcophagus", "The Sanctuary in the Sky",
		"Witch of the Black Forest", "Sinister Serpent", "Tribe-Infecting Virus", "Fiber Jar", "Sacred Phoenix of Nephthys", "Night Assailant",
		"Spirit Reaper", "Abyss Soldier", "Twin-Headed Behemoth", "Dekoichi the Battlechanted Locomotive", "Sasuke Samurai #4", "Hand of Nephthys",
		"Mirage Dragon", "Delinquent Duo", "Confiscation", "The Forceful Sentry", "Painful Choice", "Card of Safe Return", "Dimension Fusion",
		"Return from the Different Dimension", "Last Turn", "Swords of Concealing Light", "Creature Swap", "Phoenix Wing Wind Blast", "Trap Dustshoot",
		"Magical Dimension", "Zombie Master", "Pyramid Turtle", "Book of Life", "Il Blud", "Ryu Kokki", "Despair from the Dark", "Spirit of the Pharaoh",
		"Nimble Momonga", "Pyramid of Light", "Miracle Jurassic Egg", "Big Evolution Pill", "Insect Imitation", "Howling Insect", "Fortress Whale",
		"Levia-Dragon - Daedalus", "Rainbow Bridge", "Regenesis", "Penguin Soldier", "Hane-Hane", "Mataza the Zapper", "Ryu Senshi", "Kaiser Glider",
		"Element Dragon", "Dragon's Gunfire", "Slate Warrior", "Des Feral Imp", "Morphing Jar #2", "Muka Muka", "Freed the Matchless General",
		"Warrior Lady of the Wasteland", "Des Koala", "Spiritual Water Art - Aoi", "Spiritual Fire Art - Kurenai", "Spiritual Earth Art - Kurogane",
		"Spiritual Wind Art - Miyabi", "Amphibious Bugroth MK-3", "Mermaid Knight", "Ocean Dragon Lord - Neo-Daedalus", "Fusionist", "Solemn Wishes",
		"Pot of Generosity", "Magic Drain", "Riryoku Field", "Dark Elf", "Ancient Lamp", "Dark Balter the Terrible", "Mask of Darkness",
		"Wall of Illusion", "Archlord Zerato", "Guardian Angel Joan", "Tribute Doll", "Chain Burst", "Toll", "Magical Mallet", "Emergency Provisions",
		"Robbin' Goblin", "Remove Brainwashing", "Dark Mirror Force", "Covering Fire", "Maha Vailo", "Elemental Mistress Doriado", "Doriado's Blessing",
		"Guardian Sphinx", "Sword Hunter", "Gilford the Legend", "Lava Battleguard", "Swamp Battleguard", "Battleguard Howling", "Barrel Dragon",
		"Blowback Dragon","Crass Clown", "Dream Clown",
		"Magical Hats", "Blue Flame Swordsman", "Kunai with Chain", "Magical Arm Shield", "Shadow of Eyes", "Dark Spirit of the Silent", "Dark Designator",
		# 0.47.0: what the characters' rebuilt decks need (the plan "competitive character decks").
		"Ebon Illusion Magician", "Ebon High Magician",
		"Magi Magi ☆ Magician Gal", "Quintet Magician",
		"The Melody of Awakening Dragon", "Trade-In",
		"Return of the Dragon Lords",
		"Azure-Eyes Silver Dragon",
		"Indigo-Eyes Silver Dragon",
		"Dragon Shrine",
		"Max Metalmorph",
		"Swallow's Nest", "Curse Necrofear", "Dark Spirit of Malice",
		"Dark Spirit of Banishment", "Fiendish Rhino Warrior", "Absolute King Back Jack", "Lilith, Lady of Lament", "Dark Spirit's Mastery",
		"Sentence of Doom", "Fiend Griefing", "The Winged Dragon of Ra - Sphere Mode", "The Winged Dragon of Ra - Immortal Phoenix", "Guardian Slime",
		"Reactor Slime", "Ra's Disciple", "Ancient Chant", "The True Sun God", "Millennium Revelation", "Blaze Cannon", "Soul Crossing",
		"Sun God Unification", "Egyptian God Slime", "Instant Fusion", "Millennium-Eyes Restrict", "Resonance Insect", "Gokipole",
		"Beetrooper Scout Buggy", "Beetrooper Assault Roller", "Beetrooper Sting Lancer", "Beetrooper Scale Bomber", "Beetrooper Light Flapper",
		"Heavy Beetrooper Mighty Neptune", "Metamorphosed Insect Queen", "Doom Dozer", "Retaliating \"C\"", "Beetrooper Landing", "Beetrooper Formation",
		"Beetrooper Descent", "Verdant Sanctuary", "Beetrooper Fly & Sting", "Beetrooper Squad", "Ultra Beetrooper Absolute Hercules",
		"Beetrooper Cruel Saturnas", "Souleating Oviraptor", "Miscellaneousaurus", "Petiteranodon", "Ultimate Conductor Tyranno", "Overtex Qoatlus",
		"Animadorned Archosaur", "Xeno Meteorus", "Fossil Dig", "Double Evolution Pill", "Lost World", "Survival's End", "Evolzar Laggia",
		"Evolzar Dolkka"],
	"GX": [
		# 0.52.0: card plan part 3, single cards (staples and support that belong to no family).
		"Treeborn Frog", "Cyber-Stein", "Royal Oppression", "Magical Explosion", "Phantom of Chaos", "Dark Crusader", "Gorz the Emissary of Darkness",
		"Tragoedia", "Kycoo the Ghost Destroyer", "Doomcaliber Knight", "Mezuki", "Zombie World", "Magical Stone Excavation", "Ultimate Offering",
		"Prohibition", "Light-Imprisoning Mirror", "Shadow-Imprisoning Mirror", "Burden of the Mighty", "Mask of Restrict", "D.D. Crow", "Necro Gardna",
		"Swift Scarecrow", "Rescue Cat", "Dragon Ice", "Eclipse Wyvern", "Card Guard", "Fusion Sage", "King of the Swamp", "Fusion Recovery",
		"Hydrogeddon", "Oxygeddon", "Water Dragon", "Bonding - H2O", "Burst Breath", "Mausoleum of the Emperor", "Ancient Rules", "Hidden Armory",
		"Monster Gate", "Doomkaiser Dragon", "Skyscraper 2 - Hero City", "Fifth Hope", "Hero Blast", "Hero Counterattack", "D - Counter",
		"Card of the Soul", "Pharaonic Advent", "Desert Twister", "Sky Scourge Norleras", "Sky Scourge Invicil", "Sky Scourge Enrise",
		"Princess of Tsurugi", "Prometheus, King of the Shadows", "Phoenix Gearfried", "Spirit Caller", "Dark Nephthys", "Montage Dragon",
		"Barrel Behind the Door", "Chain Energy", "Brain Jacker", "Unshaven Angler", "Contact Out", "Convert Contact", "Bubble Illusion",
		"Bubble Blaster","Ambulanceroid",
		"Fusion Gate", "Mirror Gate", "Bubble Shuffle", "Common Soul", "Elemental HERO Divine Neos", "Infernal Incinerator", "Ojama Country",
		"Chthonian Blast", "Cyber Dragon Zwei", "Future Fusion", "Prima Light", "Vehicroid Connection Zone", "Destiny HERO - Diamond Dude",
		"Destiny HERO - Departed", "D - Time", "Guard Penalty",
		# 0.47.0: what the characters' rebuilt decks need (the plan "competitive character decks").
		"Elemental HERO Stratos", "Vision HERO Vyon", "Vision HERO Faris", "Vision HERO Increase", "Elemental HERO Shadow Mist",
		"Elemental HERO Liquid Soldier", "Elemental HERO Solid Soldier", "Elemental HERO Blazeman", "Elemental HERO Honest Neos",
		"Elemental HERO Spirit of Neos", "A Hero Lives", "Super Polymerization", "Mask Change", "Neos Fusion", "Elemental HERO Sunrise",
		"Elemental HERO Absolute Zero", "Elemental HERO Great Tornado", "Elemental HERO The Shining", "Elemental HERO Nova Master", "Elemental HERO Gaia",
		"Elemental HERO Escuridao", "Elemental HERO Brave Neos", "Elemental HERO Flame Wingman - Infernal Rage", "Wake Up Your Elemental HERO",
		"Masked HERO Dark Law", "Masked HERO Acid", "Vision HERO Adoration", "Vision HERO Trinity",
		"Tempest, Dragon Ruler of Storms", "Ojama Trio",
		"Cyber Dragon Core", "Cyber Dragon Herz", "Cyber Dragon Nachster", "Cyber Dragon Vier", "Cyber Dragon Drei", "Cyber Emergency",
		"Cyber Repair Plant", "Cybernetic Horizon", "Cyber Revsystem", "Cyberload Fusion", "Cybernetic Overflow", "Chimeratech Rampage Dragon",
		"Chimeratech Fortress Dragon", "Cyber Eternity Dragon", "Cyber Dragon Nova", "Cyber Dragon Infinity",
		"Cyber Angel Natasha", "Cyber Angel Vrash", "Cyber Angel Izana", "Cyber Egg Angel", "Manju of the Ten Thousand Hands", "Honest",
		"Machine Angel Absolute Ritual", "Pre-Preparation of Rites", "Preparation of Rites", "Ritual Sanctuary", "Merciful Machine Angel",
		"Magnificent Machine Angel", "Incarnated Machine Angel", "Mixeroid", "Megaroid City", "Emergeroid Call", "Super Vehicroid - Mobile Base",
		"Barbaroid, the Ultimate Battle Machine", "Destiny HERO - Celestial", "Destiny HERO - Denier", "Destiny HERO - Drawhand", "Destiny HERO - Dynatag",
		"Fusion Destiny", "D-Fusion", "D - Tactics", "Destiny HERO - Destroyer Phoenix Enforcer", "Destiny HERO - Dangerous", "Destiny HERO - Dystopia",
		"Destiny HERO - Dusktopia", "Destiny HERO - Dominance"],
	"5D's": [
		# 0.53.0: a Synchro the plan listed with the Synchron family that belongs to none.
		"Magical Android",
		# 0.52.0: card plan part 3, single cards (staples and support that belong to no family).
		"Fire Ant Ascator", "Supay", "Oracle of the Sun",
		"Ancient Fairy Dragon", "Goyo Guardian", "Stardust Spark Dragon", "Ally of Justice Catastor", "Mist Wurm", "Ancient Sacred Wyvern",
		"Avenging Knight Parshath", "Iron Chain Dragon", "Dark Highlander", "Goyo Chaser", "Gaia Knight, the Force of Earth", "Sun Dragon Inti",
		"Moon Dragon Quilla", "Hyper Psychic Blaster", "Psychic Lifetrancer", "Krebons", "Psychic Commander", "Mind Protector", "Emergency Teleport",
		"Doctor Cranium", "Hydra Viper", "Cardcar D", "Reborn Tengu", "Thunder King Rai-Oh", "Pot of Duality", "Burial from a Different Dimension",
		"Book of Eclipse", "Solemn Warning", "Mirror of Oaths", "Black Horn of Heaven", "Wiretap", "Super Junior Confrontation",
		"Stardust Dragon/Assault Mode", "Gaia Plate the Earth Giant", "Dark Strike Fighter", "Ancient Pixie Dragon", "Light End Dragon",
		"Celestial Wolf Lord, Blue Sirius", "Chaos Goddess", "Arcanite Magician/Assault Mode", "Mental Seeker", "Rose Lover", "Psychic Snail",
		"Telekinetic Charging Cell", "Psychokinesis", "Mind Master", "Esper Girl", "Power Giant", "Dark Tinker", "Red Wyvern", "Scarred Warrior",
		"Ally of Justice Decisive Armor", "Ally of Justice Garadholg", "Ally of Justice Cycle Reader", "Turbo Booster", "Turbo Rocket", "Synchro Material",
		"Dark Diviner", "Revived King Ha Des", "Tour Bus From the Underworld", "Spell Striker", "Zeman the Ape King", "Earthbound Linewalker",
		"Fortune Fairy Hikari", "Night Wing Sorceress", "Necro Defender", "Earthbound Release",
		"Equip Shot", "Confusion Chaff", "Trust Guardian", "Force Resonator", "Trap Eater", "Blackwing - Aurora the Northern Lights",
		"Blackwing - Abrolhos the Megaquake", "Black Return", "Fake Feather", "Black Garden", "Ivy Shackles", "Plant Food Chain", "Vengeful Servant",
		"Overdoom Line", "Dark Tuner Nightmare Hand", "Phantom Hand", "Gatling Ogre",
		# 0.47.0: what the characters' rebuilt decks need (the plan "competitive character decks").
		"Junk Converter", "Jet Synchron", "Stardust Synchron", "Assault Synchron", "Revolution Synchron", "Synchron Carrier", "Stardust Trail",
		"Stardust Illumination", "Junk Speeder", "Stardust Warrior", "Stardust Charge Warrior", "Accel Synchro Stardust Dragon",
		"Shooting Riser Dragon", "Satellite Warrior", "Cosmic Blazar Dragon", "Crimson Dragon", "Soul Resonator",
		"Crimson Resonator", "Vision Resonator", "Red Resonator", "Wandering King Wildwind", "Red Nova", "Crimson Gaia", "Absolute Powerforce",
		"Red Reign", "King's Synchro", "Red Carpet", "Red Rising Dragon", "Red Supernova Dragon", "Blackwing - Simoon the Poison Wind",
		"Blackwing - Kris the Crack of Dawn", "Blackwing - Oroshi the Squall", "Blackwing - Vata the Emblem of Wandering",
		"Blackwing - Shamal the Sandstorm", "Blackwing - Sudri the Phantom Glimmer", "Blackwing - Harmattan the Dust", "Blackwing - Steam the Cloak",
		"Blackwing - Chinook the Snow Blast", "Black Feather Whirlwind", "Blackbird Close", "Black Shadow Squall", "Blackwing - Twin Shadow",
		"Blackwing - Boobytrap", "Black-Winged Assault Dragon", "Blackwing Full Armor Master", "Assault Blackwing - Raikiri the Rain Shower",
		"Assault Blackwing - Chidori the Rain Sprinkling", "Assault Blackwing - Onimaru the Divine Thunder", "Assault Blackwing - Sohaya the Rain Storm",
		"Blackwing - Nothung the Starlight", "Blackwing Tamer - Obsidian Hawk Joe", "Blackwing - Boreastorm the Wicked Wind", "Red Rose Dragon",
		"Roxrose Dragon", "White Rose Dragon", "Rose Princess", "Spore", "Frozen Rose", "Rose Bell of Revelation", "Basal Rose Shoot",
		"White Rose Cloister", "Blooming of the Darkest Rose", "Ruddy Rose Dragon", "Black Rose Moonlight Dragon", "Garden Rose Maiden",
		"Garden Rose Flora", "Infernity Sage", "Infernity Wildcat", "Armageddon Knight", "Infernity Suppression", "Beelze of the Diabolic Dragons"],
	"ZEXAL": [
		# 0.52.0: card plan part 3, single cards (staples and support that belong to no family).
		"Maxx \"C\"", "Soul Charge", "Number 16: Shock Master", "Number 85: Crazy Box", "Number 82: Heartlandraco", "Number 44: Sky Pegasus",
		"Number 52: Diamond Crab King", "Maestroke the Symphony Djinn", "Downerd Magician", "Kachi Kochi Dragon", "Grenosaurus", "Number 106: Giant Hand",
		"Number 103: Ragnazero", "Number 24: Dragulas the Vampiric Dragon", "Armades, Keeper of Boundaries", "Sylvan Princessprout", "Fairy Cheer Girl",
		"Felgrand Dragon", "Fishborg Blaster", "Tin Goldfish", "Summoner Monk", "Mystic Mine", "Xyz Encore", 
		"Rank-Up-Magic Numeron Force", "Overlay Regen", "Wonder Xyz", "Xyz Effect", "Twin Twisters", "Cosmic Cyclone", "Pot of Desires",
		"Vanity's Emptiness", "Mind Drain", "Thunder of Ruler", "Dimensional Barrier", "Safe Zone", "Debunk", "Solemn Strike",
		"Number 92: Heart-eartH Dragon", "Number 91: Thunder Spark Dragon", "Number 69: Heraldry Crest", "Number 94: Crystalzero",
		"Number 98: Antitopian", "Number 100: Numeron Dragon", "Number C107: Neo Galaxy-Eyes Tachyon Dragon",
		"Number 9: Dyson Sphere", "Number 54: Lion Heart", "Number 13: Embodiment of Crime", "Number 31: Embodiment of Punishment",
		"Number 48: Shadow Lich", "Number 57: Tri-Head Dust Dragon", "Number 59: Crooked Cook", "Number 63: Shamoji Soldier", "Number 84: Pain Gainer",
		"Number 87: Queen of the Night", "Number 89: Diablosis the Mind Hacker", "Number 7: Lucky Straight", "Number 14: Greedy Sarameya",
		"Number 18: Heraldry Patriarch", "Number 21: Frozen Lady Justice", "Number 26: Spaceway Octobypass", "Number 27: Dreadnought Dreadnoid",
		"Number 29: Mannequin Cat", "Number 41: Bagooska the Terribly Tired Tapir", "Number 45: Crumble Logos the Prophet of Demolition",
		"Number 46: Dragluon", "Number 49: Fortune Tune", "Number 53: Heart-eartH", "Number 58: Burner Visor", "Number 60: Dugares the Timeless",
		"Number 64: Ronin Raccoon Sandayu", "Number 67: Pair-a-Dice Smasher", "Number 72: Shogi Rook", "Number 75: Bamboozling Gossip Shadow",
		"Number 76: Harmonizer Gradielle", "Number 77: The Seven Sins", "Number 78: Number Archive", "Number 81: Superdreadnought Rail Cannon Super Dora",
		"Number C80: Requiem in Berserk", "Number C103: Ragnafinity", "Number C106: Giant Red Hand", "Number C9: Chaos Dyson Sphere",
		"Number C69: Heraldry Crest of Horror", "Number C73: Abyss Supra Splash", "Number C92: Heart-eartH Chaos Dragon", "Rank-Up-Magic Astral Force",
		"Number Wall", "Xyz Universe", "Xyz Revenge Shuffle", "Xyz Territory",
		"Xyz Override", "Overlay Capture", "Hope for Escape", "Heavy Slump", "Gagaga Academy Emergency Network", "Dododo Witch", "Bacon Saver",
		# 0.51.0: named by a card of the Ninja family (Bat, the Forest Ninja).
		"Fairy Tale Prologue: Journey's Dawn",
		"Dododo Bot", "Double or Nothing!", "Guard Go!", "Number 19: Freezadon", "Number 99: Utopic Dragon", "Xyz Remora",
		"Torrential Reborn", "Explosive Urchin", "Full-Armored Xyz", "Xyz Unit", "Message in a Bottle", "Eternal Galaxy", "Malicevorous Spoon",
		"Don Thousand's Throne", "Number C5: Chaos Chimera Dragon",
		# 0.47.0: what the characters' rebuilt decks need (the plan "competitive character decks").
		"Number 11: Big Eye", "Mecha Phantom Beast Dracossack", "Number 38: Hope Harbinger Dragon Titanic Galaxy", "Thunder End Dragon",
		"Number 97: Draglubion", "Divine Dragon Knight Felgrand", "Odd-Eyes Absolute Dragon", "Number 42: Galaxy Tomahawk", "Number 74: Master of Blades",
		"Gaia Dragon, the Thunder Charger", "Steelswarm Roach", "Lightning Chidori", "Ice Beast Zerofyne", "Castel, the Skyblaster Musketeer",
		"Abyss Dweller", "Daigusto Emeral", "Diamond Dire Wolf", "Tornado Dragon", "Evilswarm Exciton Knight", "Number 50: Blackship of Corn",
		"Dark Rebellion Xyz Dragon", "Dante, Traveler of the Burning Abyss", "Wind-Up Zenmaines", "Ghostrick Alucard", "Mechquipped Angineer",
		"Number 23: Lancelot, Dark Knight of the Underworld", "Number 68: Sanaphond the Sky Prison", "Superdreadnought Rail Cannon Gustav Max",
		"Number 35: Ravenous Tarantula", "Skypalace Gangaridai", "Number 3: Cicada King", "Number 70: Malevolent Sin", "Number 28: Titanic Moth",
		"Gachi Gachi Gantetsu", "Sky Cavalry Centaurea", "Herald of Pure Light", "Number 107: Galaxy-Eyes Tachyon Dragon", "Tiras, Keeper of Genesis",
		"Photon Strike Bounzer", "Gear Gigant X", "Meliae of the Trees", "Lavalval Chain", "Zubababancho Gagagacoat", "Dodododwarf Gogogoglove",
		"Utopic Onomatopoeia", "ZS - Ascended Sage", "ZS - Armed Sage", "ZW - Pegasus Twin Saber", "ZW - Sylphid Wing", "Onomatopickup",
		"Zexal Construction", "Zexal Entrust", "Rank-Up-Magic Zexal Force", "Xyz Change Tactics", "Xyz Reborn", "Number 39: Utopia Double",
		"Number S39: Utopia Prime", "Number 39: Utopia Rising", "Number 93: Utopia Kaiser", "Number F0: Utopic Draco Future", "ZW - Dragonic Halberd",
		"Gagagaga Magician", "Gagagaga Girl", "Buzzsaw Shark", "Lantern Shark", "Abyss Shark", "Crystal Shark", "Surfacing Big Jaws",
		"Beautunaful Princess", "Torpedo Takedown", "Water Hazard", "Moray of Greed", "Rank-Up-Magic - The Seventh One", "Toadally Awesome",
		"N.As.H. Knight", "CXyz N.As.Ch. Knight", "Number 4: Stealth Kragen", "Valiant Shark Lancer", "Galaxy-Eyes Afterglow Dragon", "Photon Orbital",
		"Photon Vanisher", "Photon Advancer", "Galaxy Summoner", "Photon Emperor", "Galaxy Brave", "Galaxy Trance", "Photon Hand", "Photon Change",
		"Galaxy-Eyes Full Armor Photon Dragon", "Number 90: Galaxy-Eyes Photon Lord", "Galaxy-Eyes Cipher Dragon", "Galaxy-Eyes Cipher Blade Dragon",
		"Galaxy-Eyes Cipher X Dragon", "Number 95: Galaxy-Eyes Dark Matter Dragon", "Galaxy Photon Dragon", "Starliege Photon Blast Dragon",
		"Numeron Wall", "Numeron Network", "Numeron Calling", "Number 1: Numeron Gate Ekam", "Number 2: Numeron Gate Dve", "Number 3: Numeron Gate Trini",
		"Number 4: Numeron Gate Catvari", "Number C1: Numeron Chaos Gate Sunya", "Number C1000: Numerounius", "Number iC1000: Numerounius Numerounia"],
	# Three Fusion Monsters the shop's theme decks always played, but no pack handed out:
	"Vault": ["Twin-Headed Thunder Dragon", "Rabid Horseman", "Kwagar Hercules"],
}

static var _singles := {}


## The single cards of card plan parts 4 and 5 (data/singles.json): {era: [names]}.
static func singles() -> Dictionary:
	if _singles.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/singles.json"))
		_singles = (parsed as Dictionary).get("eras", {}) if parsed is Dictionary else {}
		if _singles.is_empty():
			_singles = {"_": []}
	return _singles


static var _eras := {}
static var _all := {}
static var _n := -1


static func _load() -> void:
	if _n == CardData.EXT.size() and not _eras.is_empty():
		return
	_n = CardData.EXT.size()
	_eras = {}
	_all = {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/pool.json"))
	var eras: Dictionary = (parsed as Dictionary).get("eras", {}) if parsed is Dictionary else {}
	for e in eras:
		var l: Array = []
		for id in eras[e]:
			l.append(int(id))
			_all[int(id)] = true
		_eras[str(e)] = l
	var more := singles()
	for e in more:
		for n in more[e]:
			var id := int(CardData.NAME_TO_ID.get(str(n).to_lower(), 0))
			if id != 0:
				if not _eras.has(str(e)):
					_eras[str(e)] = []
				(_eras[str(e)] as Array).append(id)
				_all[id] = true
	for e in ADDED:
		for n in ADDED[e]:
			var id := int(CardData.NAME_TO_ID.get(str(n).to_lower(), 0))
			if id != 0:
				if not _eras.has(str(e)):
					_eras[str(e)] = []
				(_eras[str(e)] as Array).append(id)
				_all[id] = true
	for fk in Collection.FAMILIES:
		for n in Collection.FAMILIES[fk]["cards"]:
			var id := int(CardData.NAME_TO_ID.get(str(n).to_lower(), 0))
			if id != 0:
				_all[id] = true


## The written-down cards of a set (plus the single cards added to it since).
static func era(e: String) -> Array:
	_load()
	return _eras.get(e, [])


## Is this card in the game? (Never a Pendulum or Link Monster: this game has no zones for them.)
static func has(id: int) -> bool:
	_load()
	if not _all.has(id):
		return false
	var d: Dictionary = CardData.EXT.get(id, {})
	if bool(d.get("pendulum", false)) or str(d.get("frame", "")) == "link":
		return false
	return OcgCore.type_of(id) & (OcgCore.TYPE_PENDULUM | OcgCore.TYPE_LINK) == 0


## Every name the game adds on top of the written-down pool (for the tools that pack engine data).
static func added_names() -> Array:
	var out: Array = []
	for e in ADDED:
		out.append_array(ADDED[e])
	var more := singles()
	for e in more:
		out.append_array(more[e])
	for fk in Collection.FAMILIES:
		out.append_array(Collection.FAMILIES[fk]["cards"])
	return out
