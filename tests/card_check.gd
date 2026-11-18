extends Node
## Dev: the card check. One run answers, for every card in the game: does the card folder know
## it, does the rules engine load it without a complaint, does it have Spanish text, and is
## there a way to get it. And for every family: a booster pack, a theme deck in the shop, a
## legal deck list, and somebody in the worlds who plays it. Run it through tools/cards.sh,
## which first repacks the engine's data for whatever the game names now.
##   godot --headless res://tests/card_check.tscn -- [out file]
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out_path := str(args[0]) if args.size() > 0 else "/tmp/card_check.txt"
	var problems: Array = []
	var notes: Array = []
	if not OcgCore.ensure_loaded():
		print("CARD CHECK: the engine did not load: ", OcgCore.why_not())
		get_tree().quit(1)
		return
	OcgCore.register_originals()
	var pool: Array = []
	for id in Collection.all_cards():
		pool.append(int(id))
	pool.sort()
	var in_pool := {}
	for id in pool:
		in_pool[id] = true
	# 1. Names the game adds that the card folder does not know (a typo, or a card missing from the folder).
	for nm in CardPool.added_names():
		if int(CardData.NAME_TO_ID.get(str(nm).to_lower(), 0)) == 0:
			problems.append("not in the card folder: \"%s\"" % nm)
	# 2. The rules engine loads every card (its script runs once when the card is created).
	var chunk: Array = []
	var loaded := 0
	for i in pool.size() + 1:
		if i < pool.size():
			chunk.append(pool[i])
		if chunk.size() >= 50 or (i == pool.size() and not chunk.is_empty()):
			var h := OcgCore.create(7 + i, [8000, 8000], [0, 0])
			var cards: Array = []
			for id in chunk:
				var extra := str(CardData.get_card(id).get("frame", "")) in ["fusion", "synchro", "xyz"]
				cards.append([0, id, OcgCore.LOC_EXTRA if extra else OcgCore.LOC_DECK, OcgCore.POS_FD_DEF])
			OcgCore.add_cards(h, cards)
			OcgCore.start(h)
			OcgCore.process(h)
			var lg := OcgCore.logs(h)
			for l in lg.get("logs", []):
				if not str(l).begins_with("9:"):
					problems.append("engine: " + str(l).left(160))
			for l in lg.get("missing", []):
				problems.append("no script in the engine pack: " + str(l))
			OcgCore.destroy(h)
			loaded += chunk.size()
			chunk = []
	# 3. Spanish text.
	var es = JSON.parse_string(FileAccess.get_file_as_string("res://data/card_text_es.json"))
	var no_es: Array = []
	var no_flavor := 0
	for id in pool:
		var cd: Dictionary = CardData.get_card(id)
		var nm := str(cd.get("name", ""))
		if CardData.ORIGINALS.has(id) or id in CardData.SPEED_SPELLS:
			continue      # (the game's own cards: their text is in the game's strings)
		if not (es as Dictionary).has(nm):
			if str(cd.get("frame", "")) == "normal":
				no_flavor += 1
			else:
				no_es.append(nm)
	for nm in no_es:
		problems.append("no Spanish text: " + str(nm))
	if no_flavor > 0:
		notes.append("%d Normal Monsters have no Spanish flavor text (they have no effect to read, so this is a note, not a problem)" % no_flavor)
	# 4. Every deck: its cards exist, are in the game, and it is a legal list.
	var roam_src := ""
	for f in ["roam_data.gd", "interiors.gd", "street_duels.gd", "roam_scene.gd"]:
		roam_src += FileAccess.get_file_as_string("res://scripts/roam/" + f)
	for k in CardData.DECKS.keys() + CardData.NAMED_DECKS.keys():
		var main: Array = CardData.deck_list(str(k))
		var ex: Array = CardData.extra_list(str(k))
		if main.size() < 20:
			continue
		var count := {}
		for id in main + ex:
			count[id] = int(count.get(id, 0)) + 1
			if not in_pool.has(int(id)) and not CardData.ORIGINALS.has(int(id)) and not int(id) in CardData.SPEED_SPELLS:
				problems.append("deck %s plays a card that is not in the game: %s (%d)" % [k, str(CardData.get_card(int(id)).get("name", "?")), int(id)])
		for id in count:
			if int(count[id]) > 3:
				problems.append("deck %s has %d copies of %s" % [k, int(count[id]), str(CardData.get_card(int(id)).get("name", "?"))])
		if CardData.NAMED_DECKS.has(k) and (main.size() < 40 or main.size() > 60 or ex.size() > 15):
			problems.append("deck %s is not a legal list: %d cards, %d in the Extra Deck" % [k, main.size(), ex.size()])
	# 5. Every family: a pack, a theme deck, somebody who plays it, and every card of it obtainable.
	for fk in Collection.FAMILIES:
		var fam: Dictionary = Collection.FAMILIES[fk]
		var has_pack := false
		for p in Collection.PACKS:
			if str(p["key"]) == str(fk):
				has_pack = true
		if not has_pack:
			problems.append("family %s has no booster pack" % fk)
		var dk := str(fam.get("deck", ""))
		var has_theme := false
		for t in Collection.THEME_DECKS:
			if str(t["key"]) == dk:
				has_theme = true
		if not has_theme:
			problems.append("family %s has no theme deck in the shop" % fk)
		if not CardData.has_deck(dk):
			problems.append("family %s: its deck %s does not exist" % [fk, dk])
		if not roam_src.contains("\"%s\"" % dk):
			problems.append("family %s: nobody in the worlds plays %s" % [fk, dk])
		# The deck that reaches the table is the deck that was written down, card for card.
		var named: Dictionary = (CardData.NAMED_DECKS.get(dk, {}) as Dictionary).get("cards", {})
		var dealt := {}
		for id in CardData.deck_list(dk):
			var nm := str(CardData.get_card(int(id)).get("name", "?"))
			dealt[nm] = int(dealt.get(nm, 0)) + 1
		for nm in named:
			if int(dealt.get(nm, 0)) != int(named[nm]):
				problems.append("deck %s: %s is written %d times but dealt %d times" % [dk, nm, int(named[nm]), int(dealt.get(nm, 0))])
		var named_x: Dictionary = (CardData.NAMED_DECKS.get(dk, {}) as Dictionary).get("extra", {})
		var want_x := 0
		for nm in named_x:
			want_x += int(named_x[nm])
		if CardData.extra_list(dk).size() != want_x:
			problems.append("deck %s: its Extra Deck is written with %d cards but has %d" % [dk, want_x, CardData.extra_list(dk).size()])
		var got := Collection.family_ids(str(fk)).size()
		if got != (fam["cards"] as Array).size():
			problems.append("family %s: %d of its %d cards are in the game" % [fk, got, (fam["cards"] as Array).size()])
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_line("cards in the game: %d   loaded in the engine: %d   families: %d   problems: %d" % [pool.size(), loaded, Collection.FAMILIES.size(), problems.size()])
	for n in notes:
		f.store_line("note: " + str(n))
	for p in problems:
		f.store_line("PROBLEM " + str(p))
	f.close()
	print("CARD CHECK: cards ", pool.size(), "  problems ", problems.size(), "  -> ", out_path)
	for p in problems.slice(0, 40):
		print("  PROBLEM ", p)
	for n in notes:
		print("  note: ", n)
	get_tree().quit(0 if problems.is_empty() else 2)
