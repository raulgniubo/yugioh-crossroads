class_name CardFinder
extends RefCounted
## Where to find a card (0.54.0): which packs hold it and which world's card shop sells them,
## which ready-made decks in the shops include it, and which duelists in the worlds play it.
## It only tells you where to go: buying still means walking into that shop.

static var _packs_of := {}      # card id -> [shop pack entries]
static var _decks_of := {}      # card id -> [theme deck keys]
static var _duelists_of := {}   # card id -> [[name, world key, hours]]
static var _built := -1


static func _build() -> void:
	if _built == CardData.EXT.size():
		return
	_built = CardData.EXT.size()
	_packs_of = {}
	_decks_of = {}
	_duelists_of = {}
	for p in Collection.shop_packs():
		if str(p["key"]) == "echo":
			continue
		for id in Collection.pool(str(p["key"])):
			if not _packs_of.has(int(id)):
				_packs_of[int(id)] = []
			(_packs_of[int(id)] as Array).append(p)
	for t in Collection.THEME_DECKS:
		var dk := str(t["key"])
		if not CardData.has_deck(dk):
			continue
		for id in CardData.deck_list(dk) + CardData.extra_list(dk):
			if not _decks_of.has(int(id)):
				_decks_of[int(id)] = []
			if not (_decks_of[int(id)] as Array).has(dk):
				(_decks_of[int(id)] as Array).append(dk)
	for w in RoamData.DISTRICTS:
		for npc in RoamData.DISTRICTS[w].get("npcs", []) + RoamData.DISTRICTS[w].get("shop_npcs", []):
			var duel: Dictionary = npc.get("duel", {})
			if duel.is_empty():
				continue
			# (Ordinary duelists only: the show's characters are listed under "Played by".)
			var nm := str(npc.get("name", ""))
			if nm == "" or str(npc.get("char", "")) != "":
				continue
			var decks: Array = duel.get("decks", [duel.get("deck", "")])
			for dk in decks:
				if not CardData.has_deck(str(dk)):
					continue
				for id in CardData.deck_list(str(dk)) + CardData.extra_list(str(dk)):
					if not _duelists_of.has(int(id)):
						_duelists_of[int(id)] = []
					var row := [nm, str(w), npc.get("hours", [])]
					if not (_duelists_of[int(id)] as Array).any(func(r): return r[0] == nm):
						(_duelists_of[int(id)] as Array).append(row)


## A world's name for the player ("Domino City").
static func world_name(w: String) -> String:
	return Loc.t(str(RoamData.DISTRICTS.get(w, {}).get("name", w)))


## Which worlds' card shops sell this pack.
static func shops_for(pack: Dictionary) -> Array:
	var out: Array = []
	if int(pack.get("tab", 0)) > 1:
		return [Loc.t("every card shop")]       # (the Type and Element packs are on every shelf)
	var base := Collection.base_key(str(pack["key"]))
	for w in PackShop.WORLD_PACKS:
		if (PackShop.WORLD_PACKS[w] as Array).has(base):
			out.append(world_name(str(w)))
	return out


## Lines for the album's card view: packs, shop decks, duelists. Each list is cut short with
## "and N more" so it fits.
static func lines(id: int) -> Array:
	_build()
	var out: Array = []
	var packs: Array = _packs_of.get(id, [])
	if not packs.is_empty():
		var bits: Array = []
		for p in packs.slice(0, 3):
			var shops := shops_for(p)
			bits.append("%s (%s)" % [Collection.pack_title(p), ", ".join(shops) if not shops.is_empty() else Loc.t("no shop")])
		var more := "" if packs.size() <= 3 else " " + Loc.t("and %d more") % (packs.size() - 3)
		out.append(Loc.t("Packs: %s") % ("; ".join(bits) + more))
	var decks: Array = _decks_of.get(id, [])
	if not decks.is_empty():
		var bits: Array = []
		for dk in decks.slice(0, 3):
			var where: Array = []
			for w in RoamData.DISTRICTS:
				if Collection.theme_sold_in(str(dk), str(w)):
					where.append(world_name(str(w)))
			bits.append("%s (%s)" % [Loc.t(CardData.deck_name(str(dk))), ", ".join(where)])
		var more := "" if decks.size() <= 3 else " " + Loc.t("and %d more") % (decks.size() - 3)
		out.append(Loc.t("Ready-made decks: %s") % ("; ".join(bits) + more))
	var who: Array = _duelists_of.get(id, [])
	if not who.is_empty():
		var bits: Array = []
		for r in who.slice(0, 4):
			var when := ""
			var h: Array = r[2]
			if h.size() == 2:
				when = ", " + (Loc.t("early mornings") if int(h[0]) < 9 and int(h[1]) <= 12 else Loc.t("at night") if int(h[0]) >= 19 or int(h[1]) <= 5 else Loc.t("some hours"))
			bits.append("%s (%s%s)" % [Loc.t(str(r[0])), world_name(str(r[1])), when])
		var more := "" if who.size() <= 4 else " " + Loc.t("and %d more") % (who.size() - 4)
		out.append(Loc.t("Duelists who play it: %s") % (", ".join(bits) + more))
	if out.is_empty():
		out.append(Loc.t("Not sold in any shop: it comes from the story or from duels."))
	return out
