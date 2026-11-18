extends Node
## One-off (0.50.1): freezes the few card facts menus still read from the first rules code,
## and writes a baseline of every answer so the code that replaces it can be checked against it.

func _fallback(d: Dictionary) -> String:
	var st := str(d.get("st", "")).to_lower()
	return str({"quick-play": "quick", "continuous": "cont", "counter": "counter", "equip": "equip", "field": "field", "ritual": "ritual"}.get(st, "trap" if str(d.get("kind", "")) == "trap" else "normal"))


func _ready() -> void:
	var uni := {}
	for id in CardData.CARDS:
		uni[int(id)] = true
	for id in CardData.EXT:
		uni[int(id)] = true
	for id in CardData.TOKENS:
		uni[int(id)] = true
	var ids: Array = uni.keys()
	ids.sort()
	var st := DuelState.new()
	var ST_K := {}
	var SPEED := {}
	for n in SpellRules.FX:
		ST_K[n] = str(SpellRules.FX[n].get("k", ""))
		if int(SpellRules.FX[n].get("speed", 0)) != 0:
			SPEED[n] = int(SpellRules.FX[n].get("speed", 0))
	var KIND := {}
	var FIELD := {}
	var WORKS := {}
	var FX_ANY := {}
	var NOTE := {}
	var ALIAS := {}
	var base := {"not_ok": [], "works": [], "kind": {}, "spell_kind": {}, "swap": {}, "field": {}, "speed": {}}
	for id in ids:
		var d := CardData.get_card(id)
		var nm := str(d.get("name", ""))
		if not CardExact.ok(d):
			base["not_ok"].append(id)
		if SignatureDecks._works(id):
			base["works"].append(id)
			if not CardPool.has(id):
				WORKS[id] = true
		var sw := CardData.swap(id)
		if sw != id:
			base["swap"][str(id)] = sw
		if str(d["kind"]) != "monster":
			var c = st._make(id, 0)
			var k := SpellRules.kind(c)
			base["kind"][str(id)] = k
			base["spell_kind"][str(id)] = Collection._spell_kind(id)
			if k != _fallback(d):
				KIND[id] = k
			if k == "field":
				var sp: Dictionary = SpellRules.spec(c)
				if sp.has("boost") or sp.has("def_pos_boost"):
					var f := {}
					if sp.has("boost"):
						f["boost"] = sp["boost"]
					if sp.has("def_pos_boost"):
						f["def_pos_boost"] = sp["def_pos_boost"]
					FIELD[id] = f
					base["field"][str(id)] = var_to_str(f)
			base["speed"][str(id)] = int(SpellRules.FX.get(nm, {}).get("speed", 0))
		else:
			if str(d.get("frame", "")) != "effect" and CardEffects.of(nm).size() > 0:
				FX_ANY[nm] = true
			var txt := str(d.get("desc", ""))
			if txt == "":
				txt = str(CardData.EXT.get(id, {}).get("desc", ""))
			var note := str(CardEffects.of(nm).get("note", CardData.MONSTER_EFFECTS.get(nm, "")))
			if txt == "" and note != "":
				NOTE[nm] = note
		var e: Dictionary = CardEffects.of(nm)
		var al := {}
		for key in ["name_as", "name_as_fg", "also_named"]:
			if e.has(key):
				al[key] = e[key]
		if not al.is_empty():
			ALIAS[nm] = al
	base["all_cards"] = Collection.all_cards()
	base["decks"] = {}
	var keys := {}
	for k in CardData.DECKS:
		keys[str(k)] = true
	for k in CardData.ADDONS:
		keys[str(k)] = true
	for k in SignatureDecks.TUNE:
		keys[str(k)] = true
	for k in keys:
		base["decks"][k] = [CardData.deck_list(k), CardData.deck_list(k, true), CardData.legend_deck(k), CardData.extra_list(k), CardData.extra_list(k, true)]
	base["style"] = {}
	for k in keys:
		base["style"][k] = DuelAI.style_for(k)
	base["audit"] = {}
	for k in SignatureDecks.TUNE:
		base["audit"][str(k)] = str(SignatureDecks.audit(str(k)))
	var f2 := FileAccess.open("/tmp/facts/base.json", FileAccess.WRITE)
	f2.store_string(JSON.stringify(base, "", true))
	f2.close()
	var out := "class_name CardFacts\n"
	out += "## Small facts about cards that menus and the table's dressing read: what kind of Spell or Trap a card is,\n"
	out += "## what a Field Spell says it boosts, which of the game's own cards work. They were frozen from the game's\n"
	out += "## first rules code when it was removed (0.50.1, tests/facts_gen.gd). The rules engine plays every card by\n"
	out += "## its real script and reads none of this.\n\n"
	for pair in [["ST_K", ST_K, "Spell and Trap Cards the first rules knew by name -> their kind (\"\" when the card's own data says it)."],
			["SPEED", SPEED, "Speed Spells: the Speed Counters each one asks for."],
			["KIND", KIND, "Card id -> kind, where it is not simply what the card's data says."],
			["FIELD", FIELD, "Field Spell id -> what it boosts: [[who, ATK, DEF?]...] and a DEF boost for Defense Position monsters."],
			["WORKS", WORKS, "The game's own cards and tokens (not in the engine's pool) that work in a deck."],
			["FX_ANY", FX_ANY, "Monsters without the Effect frame that still have an effect (the Deck Builder's auto-build scores them higher)."],
			["NOTE", NOTE, "What a card of this game does, for cards with no printed text."],
			["ALIAS", ALIAS, "Cards that count as another name."]]:
		out += "## %s\nconst %s := %s\n\n" % [pair[2], pair[0], var_to_str(pair[1])]
	var f3 := FileAccess.open("/tmp/facts/tables.gd", FileAccess.WRITE)
	f3.store_string(out)
	f3.close()
	print("FACTS universe ", ids.size(), " ST_K ", ST_K.size(), " KIND ", KIND.size(), " FIELD ", FIELD.size(), " WORKS ", WORKS.size(), " FX_ANY ", FX_ANY.size(), " NOTE ", NOTE.size(), " ALIAS ", ALIAS.size(), " not_ok ", base["not_ok"].size(), " works ", base["works"].size())
	get_tree().quit()
