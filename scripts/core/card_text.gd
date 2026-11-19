class_name CardText
## A card's text as the player reads it: in Spanish when the game is in Spanish and the card
## has a translation in data/card_text_es.json (our own translations, keyed by the card's English
## name). The rules always read the English text from the card data; this is only for showing.

static var _es: Dictionary = {}
static var _loaded := false


static func shown(name: String, english: String) -> String:
	if Loc.lang() != "es" or english == "":
		return english
	_load()
	return str(_es.get(name, english))


## The card's Spanish text whatever language the game is in, or "" (for searching).
static func spanish(name: String) -> String:
	_load()
	return str(_es.get(name, ""))


static func _load() -> void:
	if not _loaded:
		_loaded = true
		var f := FileAccess.open("res://data/card_text_es.json", FileAccess.READ)
		if f:
			var got = JSON.parse_string(f.get_as_text())
			if got is Dictionary:
				_es = got


## What the card does, in one short line (for the caption when it is activated): the part of
## its text after the condition ("When ... : Destroy all ..." -> "Destroy all ...").
static func gist(name: String, english: String, most := 110) -> String:
	var t := shown(name, english).replace("\n", " ").strip_edges()
	if t == "":
		return ""
	# The first sentence that does something.
	var first := t
	var cut := t.find(". ")
	if cut > 0:
		first = t.substr(0, cut + 1)
	var colon := maxi(first.rfind(": "), first.rfind("; "))
	if colon > 0 and colon < first.length() - 8:
		first = first.substr(colon + 2)
	first = first.strip_edges()
	if first.length() > 0:
		first = first.substr(0, 1).to_upper() + first.substr(1)
	if first.length() > most:
		first = first.substr(0, most - 1).strip_edges() + "…"
	return first


static func count() -> int:
	shown("", "x")
	return _es.size()
