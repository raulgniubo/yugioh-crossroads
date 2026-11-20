class_name CardSearch
## Finding a card by what the player types (0.59.0). The game shows the English name, but a
## card can be found by its English name or its official Spanish name, whatever language the
## game is in: someone playing in Spanish may know a card only by its English name, and the
## other way round. Accents, capitals and punctuation do not matter ("ojos azules",
## "Blue Eyes" and "blue-eyes" all find Blue-Eyes White Dragon).
## Spanish names: data/card_names_es.json (made by tools/dev/cardes/names_es.py).

static var _es: Dictionary = {}
static var _loaded := false
static var _folded := {}     # id -> [folded English, folded Spanish]

const ACCENTS := {"á": "a", "à": "a", "â": "a", "ä": "a", "é": "e", "è": "e", "ê": "e", "ë": "e", "í": "i", "ì": "i", "î": "i", "ï": "i",
	"ó": "o", "ò": "o", "ô": "o", "ö": "o", "ú": "u", "ù": "u", "û": "u", "ü": "u", "ñ": "n", "ç": "c", "☆": " ", "★": " "}


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var f := FileAccess.open("res://data/card_names_es.json", FileAccess.READ)
	if f:
		var got = JSON.parse_string(f.get_as_text())
		if got is Dictionary:
			_es = got


## The card's official Spanish name, or "" when it has none (or it is the same as the English one).
static func es_name(id: int) -> String:
	_load()
	return str(_es.get(str(id), ""))


## Lower case, no accents, anything that is not a letter or a digit becomes one space.
static func fold(s: String) -> String:
	var t := s.to_lower()
	var out := ""
	for ch in t:
		ch = ACCENTS.get(ch, ch)
		var u := ch.unicode_at(0) if ch.length() > 0 else 32
		var keep := (u >= 97 and u <= 122) or (u >= 48 and u <= 57) or u > 127
		out += ch if keep else " "
	while out.contains("  "):
		out = out.replace("  ", " ")
	return out.strip_edges()


static func _names(id: int, english: String) -> Array:
	if not _folded.has(id):
		_folded[id] = [fold(english), fold(es_name(id))]
	return _folded[id]


## What players call a card for short (0.63.1): "FGD" is Five-Headed Dragon (from its Japanese name,
## Five God Dragon), "BLS" is Black Luster Soldier... Each one lists how the English name starts.
const NICKNAMES := {
	"fgd": ["five headed dragon"],
	"bls": ["black luster soldier"],
	"beud": ["blue eyes ultimate dragon"],
	"dad": ["dark armed dragon"],
	"jd": ["judgment dragon"],
	"tgu": ["tour guide from the underworld"],
	"trish": ["trishula"],
	"cydra": ["cyber dragon"],
	"gk": ["gravekeeper"],
}
static var _initials := {}     # id -> the first letter of each word of the English name ("bewd")


## Is what was typed this card's short name, or the initials of its name ("BEWD", "F.G.D.", "dmg")?
## `tight`: the query with its spaces taken out ("f g d" -> "fgd").
static func _short_hit(id: int, english: String, tight: String) -> bool:
	if tight.length() < 2 or tight.length() > 6:
		return false
	var name: String = _names(id, english)[0]
	for start in NICKNAMES.get(tight, []):
		if name.begins_with(str(start)):
			return true
	if tight.length() < 3:
		return false
	if not _initials.has(id):
		var ini := ""
		for w in name.split(" ", false):
			ini += w[0]
		_initials[id] = ini
	return str(_initials[id]) == tight


## How well a card's names fit what was typed: 4 a name is exactly it, 3 a name starts with it, 2 a word in a name
## starts with it, 1 it is somewhere in a name, 0 not at all. `query` must already be folded
## (fold() it once per search, not once per card).
static func score(id: int, english: String, query: String) -> int:
	if query == "":
		return 1
	var best := 0
	if query.length() <= 11 and _short_hit(id, english, query.replace(" ", "")):
		best = 3
	for n in _names(id, english):
		if n == "":
			continue
		if n == query:
			return 4
		if n.begins_with(query):
			best = maxi(best, 3)
			continue
		if n.contains(" " + query):
			best = maxi(best, 2)
		elif n.contains(query):
			best = maxi(best, 1)
		elif best == 0 and query.contains(" ") and _all_words(n, query):
			best = 1
	return best


## Every word typed is in the name, in any order ("absorb kid" finds Absorbing Kid from the Sky).
static func _all_words(name: String, query: String) -> bool:
	for w in query.split(" ", false):
		if not name.contains(w):
			return false
	return true


static func matches(id: int, english: String, query: String) -> bool:
	return score(id, english, query) > 0


## The name to show next to a match found by its other language's name ("" when the shown name matched).
static func other_name(id: int, english: String, query: String) -> String:
	var es := es_name(id)
	if es == "" or query == "" or fold(english).contains(query):
		return ""
	return es if fold(es).contains(query) else ""
