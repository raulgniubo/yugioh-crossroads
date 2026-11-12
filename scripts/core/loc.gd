class_name Loc
## Languages. English is the source: every string in the code is English, and Spanish comes
## from a table keyed by that English text (scripts/core/es_strings.gd). Controls translate
## their own text; strings built with % go through Loc.t() first.

const LANGS := [["en", "English"], ["es", "Español"]]
static var _ready_done := false


static func setup(lang: String) -> void:
	if not _ready_done:
		_ready_done = true
		var tr := Translation.new()
		tr.locale = "es"
		var table: Dictionary = load("res://scripts/core/es_strings.gd").ES
		for k in table:
			tr.add_message(k, table[k])
		TranslationServer.add_translation(tr)
	TranslationServer.set_locale(lang if lang in ["en", "es"] else "en")


static func t(s: String) -> String:
	return TranslationServer.translate(s)


static func lang() -> String:
	return "es" if TranslationServer.get_locale().begins_with("es") else "en"
