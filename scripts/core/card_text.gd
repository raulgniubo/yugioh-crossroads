class_name CardText
## A card's text as the player reads it: in Spanish when the game is in Spanish and the card
## has a translation in data/card_text_es.json (our own translations, keyed by the card's English
## name). The rules always read the English text from the card data; this is only for showing.

static var _es: Dictionary = {}
static var _loaded := false


static func shown(name: String, english: String) -> String:
	if Loc.lang() != "es" or english == "":
		return english
	if not _loaded:
		_loaded = true
		var f := FileAccess.open("res://data/card_text_es.json", FileAccess.READ)
		if f:
			var got = JSON.parse_string(f.get_as_text())
			if got is Dictionary:
				_es = got
	return str(_es.get(name, english))


static func count() -> int:
	shown("", "x")
	return _es.size()
