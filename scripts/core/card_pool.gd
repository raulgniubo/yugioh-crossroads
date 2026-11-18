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
	"Duel Monsters": ["Crass Clown", "Dream Clown",
		"Magical Hats", "Blue Flame Swordsman", "Kunai with Chain", "Magical Arm Shield", "Shadow of Eyes", "Dark Spirit of the Silent", "Dark Designator",
		# 0.47.0: what the characters' rebuilt decks need (the plan "competitive character decks").
		"Magician's Rod", "Magicians' Souls", "Apprentice Illusion Magician", "Timaeus the United Dragon", "Magikuriboh", "Palladium Oracle Mahad",
		"Dark Magical Circle", "Soul Servant", "Magician's Salvation", "Secrets of Dark Magic", "The Eye of Timaeus", "Bond Between Teacher and Student",
		"Illusion Magic", "Eternal Soul", "Magician Navigation", "Dark Magician the Dragon Knight", "Amulet Dragon",
		"Dark Magician Girl the Dragon Knight", "The Dark Magicians", "Dark Cavalry", "Ebon Illusion Magician", "Ebon High Magician",
		"Magi Magi ☆ Magician Gal", "Quintet Magician", "Blue-Eyes Alternative White Dragon", "Blue-Eyes Jet Dragon", "Blue-Eyes Abyss Dragon",
		"Dragon Spirit of White", "Sage with Eyes of Blue", "Maiden of White", "Neo Kaiser Sea Horse", "Dictator of D.", "The White Stone of Ancients",
		"The White Stone of Legend", "Wishes for Eyes of Blue", "Roar of the Blue-Eyed Dragons", "The Melody of Awakening Dragon", "Trade-In",
		"Bingo Machine, Go!!!", "Ultimate Fusion", "Return of the Dragon Lords", "True Light", "Majesty of the White Dragons",
		"The Ultimate Creature of Destruction", "Blue-Eyes Spirit Dragon", "Blue-Eyes Ultimate Spirit Dragon", "Azure-Eyes Silver Dragon",
		"Blue-Eyes Twin Burst Dragon", "Neo Blue-Eyes Ultimate Dragon", "Blue-Eyes Tyrant Dragon", "Indigo-Eyes Silver Dragon",
		"Red-Eyes Black Flare Dragon", "Meteor Dragon Red-Eyes Impact", "Red-Eyes Baby Dragon", "Red-Eyes Wyvern", "The Black Stone of Legend",
		"Red-Eyes Darkness Metal Dragon", "Gearfried the Red-Eyes Iron Knight", "Black Metal Dragon", "Red-Eyes Black Fullmetal Dragon", "Red-Eyes Fusion",
		"Red-Eyes Insight", "Cards of the Red Stone", "Dragon Shrine", "Inferno Fire Blast", "Red-Eyes Spirit", "Return of the Red-Eyes", "Red-Eyes Burn",
		"Max Metalmorph", "Red-Eyes Slash Dragon", "Meteor Black Comet Dragon", "Red-Eyes Flare Metal Dragon", "Harpie Harpist", "Harpie Perfumer",
		"Harpie Dancer", "Harpie Oracle", "Harpie's Pet Dragon - Fearsome Fire Blast", "Harpie's Pet Baby Dragon", "Hysteric Sign",
		"Harpie's Feather Rest", "Swallow's Nest", "Harpie's Feather Storm", "Harpie's Pet Phantasmal Dragon", "Curse Necrofear", "Dark Spirit of Malice",
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
	"GX": ["Ambulanceroid",
		"Fusion Gate", "Mirror Gate", "Bubble Shuffle", "Common Soul", "Elemental HERO Divine Neos", "Infernal Incinerator", "Ojama Country",
		"Chthonian Blast", "Cyber Dragon Zwei", "Future Fusion", "Prima Light", "Vehicroid Connection Zone", "Destiny HERO - Diamond Dude",
		"Destiny HERO - Departed", "D - Time", "Guard Penalty",
		# 0.47.0: what the characters' rebuilt decks need (the plan "competitive character decks").
		"Elemental HERO Stratos", "Vision HERO Vyon", "Vision HERO Faris", "Vision HERO Increase", "Elemental HERO Shadow Mist",
		"Elemental HERO Liquid Soldier", "Elemental HERO Solid Soldier", "Elemental HERO Blazeman", "Elemental HERO Honest Neos",
		"Elemental HERO Spirit of Neos", "A Hero Lives", "Super Polymerization", "Mask Change", "Neos Fusion", "Elemental HERO Sunrise",
		"Elemental HERO Absolute Zero", "Elemental HERO Great Tornado", "Elemental HERO The Shining", "Elemental HERO Nova Master", "Elemental HERO Gaia",
		"Elemental HERO Escuridao", "Elemental HERO Brave Neos", "Elemental HERO Flame Wingman - Infernal Rage", "Wake Up Your Elemental HERO",
		"Masked HERO Dark Law", "Masked HERO Acid", "Vision HERO Adoration", "Vision HERO Trinity", "Armed Dragon Thunder LV10",
		"Armed Dragon Thunder LV7", "Armed Dragon Thunder LV5", "Armed Dragon Thunder LV3", "Armed Dragon LV10 White", "Pile Armed Dragon",
		"Tempest, Dragon Ruler of Storms", "Armed Dragon Flash", "Armed Dragon Blitz", "Armed Dragon Lightning", "Armed Dragon Thunderbolt", "Ojama Trio",
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
		"Equip Shot", "Confusion Chaff", "Trust Guardian", "Force Resonator", "Trap Eater", "Blackwing - Aurora the Northern Lights",
		"Blackwing - Abrolhos the Megaquake", "Black Return", "Fake Feather", "Black Garden", "Ivy Shackles", "Plant Food Chain", "Vengeful Servant",
		"Overdoom Line", "Dark Tuner Nightmare Hand", "Phantom Hand", "Gatling Ogre",
		# 0.47.0: what the characters' rebuilt decks need (the plan "competitive character decks").
		"Junk Converter", "Jet Synchron", "Stardust Synchron", "Assault Synchron", "Revolution Synchron", "Synchron Carrier", "Stardust Trail",
		"Stardust Illumination", "Junk Speeder", "Stardust Warrior", "T.G. Hyper Librarian", "Stardust Charge Warrior", "Accel Synchro Stardust Dragon",
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
		"Dododo Bot", "Double or Nothing!", "Guard Go!", "Number 19: Freezadon", "Number 99: Utopic Dragon", "Scrap Shark", "Xyz Remora",
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
	for fk in Collection.FAMILIES:
		out.append_array(Collection.FAMILIES[fk]["cards"])
	return out
