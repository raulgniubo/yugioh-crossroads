extends Node
## Dev: is this card in the game, and which pack in the shop hands it out?
##   godot --headless --path . res://tests/find_card.tscn -- "Five-Headed Dragon"
func _ready() -> void:
	CardData.get_card(46986414)
	for want in OS.get_cmdline_user_args():
		var hits := 0
		for lower in CardData.NAME_TO_ID:
			if str(lower).contains(str(want).to_lower()):
				var id := int(CardData.NAME_TO_ID[lower])
				var where: Array = []
				for p in Collection.shop_packs():
					if id in Collection.pool(str(p["key"])):
						where.append("%s (%s)" % [Collection.pack_title(p), str(p["key"])])
				print("CARD %s  id %d  es: %s  packs: %s" % [str(CardData.get_card(id).get("name", "")), id, CardSearch.es_name(id), ", ".join(where) if not where.is_empty() else "NONE"])
				hits += 1
		if hits == 0:
			print("CARD not in the game: ", want)
	get_tree().quit()
