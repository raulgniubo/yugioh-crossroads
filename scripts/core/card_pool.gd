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
		"Magical Hats", "Blue Flame Swordsman", "Kunai with Chain", "Magical Arm Shield", "Shadow of Eyes", "Dark Spirit of the Silent", "Dark Designator"],
	"GX": ["Ambulanceroid",
		"Fusion Gate", "Mirror Gate", "Bubble Shuffle", "Common Soul", "Elemental HERO Divine Neos", "Infernal Incinerator", "Ojama Country",
		"Chthonian Blast", "Cyber Dragon Zwei", "Future Fusion", "Prima Light", "Vehicroid Connection Zone", "Destiny HERO - Diamond Dude",
		"Destiny HERO - Departed", "D - Time", "Guard Penalty"],
	"5D's": [
		"Equip Shot", "Confusion Chaff", "Trust Guardian", "Force Resonator", "Trap Eater", "Blackwing - Aurora the Northern Lights",
		"Blackwing - Abrolhos the Megaquake", "Black Return", "Fake Feather", "Black Garden", "Ivy Shackles", "Plant Food Chain", "Vengeful Servant",
		"Overdoom Line", "Dark Tuner Nightmare Hand", "Phantom Hand", "Gatling Ogre"],
	"ZEXAL": [
		"Dododo Bot", "Double or Nothing!", "Guard Go!", "Number 19: Freezadon", "Number 99: Utopic Dragon", "Scrap Shark", "Xyz Remora",
		"Torrential Reborn", "Explosive Urchin", "Full-Armored Xyz", "Xyz Unit", "Message in a Bottle", "Eternal Galaxy", "Malicevorous Spoon",
		"Don Thousand's Throne", "Number C5: Chaos Chimera Dragon"],
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
