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
	# (0.78.0) The story's ladder: Basic is the early deck, Strong the later one, "full" only when written so
	# (or on Extreme); decks without the show's versions keep the three.
	var cases := [["kaiba", "starter", 0, false, "anime1"], ["kaiba", "starter", 1, false, "anime2"], ["kaiba", "starter", 2, false, "anime2"],
		["kaiba", "starter", 2, true, "full"], ["kaiba", "full", 0, false, "full"], ["deck_water", "standard", 2, false, "anime1"],
		["deck_warrior", "starter", 1, false, "standard"], ["chazz", "anime1", 1, false, "anime2"], ["vector", "standard", 0, false, "anime1"]]
	var wrong := 0
	for c in cases:
		var got := DeckTiers.shift_in(str(c[0]), str(c[1]), int(c[2]), bool(c[3]))
		if got != str(c[4]):
			wrong += 1
			print("LADDER WRONG ", c, " -> ", got)
	print("STORY LADDER: %d of %d right" % [cases.size() - wrong, cases.size()])
	var roam := [DeckTiers.for_duel("joey", "joey", 1), DeckTiers.for_duel("joey", "joey", 3), DeckTiers.for_duel("joey", "joey", 5)]
	print("WORLDS: joey at 1, 3, 5 stars -> ", roam)
	get_tree().quit(0)
