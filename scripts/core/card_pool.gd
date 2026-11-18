class_name CardPool
extends RefCounted
## Which cards are in the game. The pool as it stood when duels moved to the rules engine is
## written down in data/pool.json (by set). Everything added since is named in the code: a whole
## family in Collection.FAMILIES, a single card in ADDED below. A card is in the game when it
## is in one of those and the card folder knows it. How a card plays is the rules engine's
## business (its script), not this file's.

## Single cards added after the pool was written down, by the era pack that hands them out.
const ADDED := {
	"Duel Monsters": ["Crass Clown", "Dream Clown"],     # (what Bickuribox is made of)
	"GX": ["Ambulanceroid"],                              # (what Ambulance Rescueroid is made of)
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


## Is this card in the game?
static func has(id: int) -> bool:
	_load()
	return _all.has(id)


## Every name the game adds on top of the written-down pool (for the tools that pack engine data).
static func added_names() -> Array:
	var out: Array = []
	for e in ADDED:
		out.append_array(ADDED[e])
	for fk in Collection.FAMILIES:
		out.append_array(Collection.FAMILIES[fk]["cards"])
	return out
