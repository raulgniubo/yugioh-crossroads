extends Node
## Dev (0.77.0): every deck from the show (DeckTiers.ANIME) as the game reads it: forty cards in the
## Main Deck, nothing that belongs in the Extra Deck, and the Extra Deck as written.
##   godot --headless --path . res://tests/anime_decks.tscn -- --assets=<card folder>
func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--assets="):
			Settings.card_folder = a.substr(9)
	await get_tree().process_frame
	var bad := 0
	var n := 0
	for base in DeckTiers.ANIME:
		for v in DeckTiers.ANIME_VERSIONS:
			var ak := DeckTiers.anime_key(str(base), str(v))
			if ak == "":
				continue
			n += 1
			var key := DeckTiers.with_version(str(base), str(v))
			var main := CardData.deck_list(key)
			var extra := CardData.extra_list(key)
			var wrong := 0
			for id in main:
				var t := str(CardData.get_card(id).get("type", ""))
				if t.contains("Fusion") or t.contains("Synchro") or t.contains("XYZ") or t.contains("Link"):
					wrong += 1
			var ok := main.size() == 40 and wrong == 0 and CardData.has_deck(key)
			if not ok:
				bad += 1
			print("%s %-22s %-20s main %d extra %d %s  %s" % ["OK " if ok else "BAD", key, ak, main.size(), extra.size(), ("extra-in-main %d" % wrong) if wrong else "", CardData.deck_name(key)])
	print("ANIME DECKS: %d of %d fine" % [n - bad, n])
	get_tree().quit(0)
