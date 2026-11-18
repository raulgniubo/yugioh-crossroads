extends Node
## Checks the facts file (scripts/core/card_facts.gd) against the baseline taken from the first
## rules code before it was removed: writes every answer to /tmp/facts/now.json, to be compared
## with /tmp/facts/base.json (cmp, or python json equality).

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
	var base := {"not_ok": [], "works": [], "kind": {}, "spell_kind": {}, "swap": {}, "field": {}, "speed": {}}
	for id in ids:
		var d := CardData.get_card(id)
		var nm := str(d.get("name", ""))
		if not CardFacts.ok(d):
			base["not_ok"].append(id)
		if SignatureDecks._works(id):
			base["works"].append(id)
		var sw := CardData.swap(id)
		if sw != id:
			base["swap"][str(id)] = sw
		if str(d["kind"]) != "monster":
			var c = st._make(id, 0)
			var k := CardFacts.kind(c)
			base["kind"][str(id)] = k
			base["spell_kind"][str(id)] = Collection._spell_kind(id)
			if k == "field" and not CardFacts.field(c).is_empty():
				base["field"][str(id)] = var_to_str(CardFacts.field(c))
			base["speed"][str(id)] = int(CardFacts.SPEED.get(nm, 0))
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
		base["style"][k] = CardFacts.style_for(k)
	base["audit"] = {}
	for k in SignatureDecks.TUNE:
		base["audit"][str(k)] = str(SignatureDecks.audit(str(k)))
	var f2 := FileAccess.open("/tmp/facts/now.json", FileAccess.WRITE)
	f2.store_string(JSON.stringify(base, "", true))
	f2.close()
	print("FACTS CHECK written, universe ", ids.size())
	get_tree().quit()
