class_name CardFinder
extends RefCounted
## Where to find a card (0.54.0): which packs hold it and which world's card shop sells them,
## which ready-made decks in the shops include it, and which duelists in the worlds play it.
## It only tells you where to go: buying still means walking into that shop.

static var _packs_of := {}      # card id -> [shop pack entries]
static var _decks_of := {}      # card id -> [theme deck keys]
static var _duelists_of := {}   # card id -> [[name, world key, hours]]
static var _built := -1
static var _decks_any := {}     # card id -> [deck catalog entries] (theme decks and duelists' decks, 0.55.3)
static var _people := {}        # card id -> [{name, world, place, hours, color}] (everyone, the show's characters too)

## The worlds in travel order, and what their card shop is called.
const WORLD_ORDER := ["domino", "academy", "satellite", "newdomino", "heartland"]
const SHOP_NAME := {"domino": "Kame Game", "academy": "Academy card shop", "satellite": "The Card Dealer", "newdomino": "Card shop", "heartland": "Card shop"}


static func _build() -> void:
	if _built == CardData.EXT.size():
		return
	_built = CardData.EXT.size()
	_packs_of = {}
	_decks_of = {}
	_duelists_of = {}
	for p in Collection.shop_packs():
		Router.pulse()
		if str(p["key"]) == "echo":
			continue
		for id in Collection.pool(str(p["key"])):
			Router.pulse()
			if not _packs_of.has(int(id)):
				_packs_of[int(id)] = []
			(_packs_of[int(id)] as Array).append(p)
	for t in Collection.THEME_DECKS:
		Router.pulse()
		var dk := str(t["key"])
		if not CardData.has_deck(dk):
			continue
		for id in CardData.deck_list(dk) + CardData.extra_list(dk):
			Router.pulse()
			if not _decks_of.has(int(id)):
				_decks_of[int(id)] = []
			if not (_decks_of[int(id)] as Array).has(dk):
				(_decks_of[int(id)] as Array).append(dk)
	_decks_any = {}
	_people = {}
	for e in Collection.deck_catalog():
		Router.pulse()
		for id in CardData.deck_list(str(e["key"])) + CardData.extra_list(str(e["key"])):
			Router.pulse()
			if not _decks_any.has(int(id)):
				_decks_any[int(id)] = []
			if not (_decks_any[int(id)] as Array).any(func(x): return x["key"] == e["key"]):
				(_decks_any[int(id)] as Array).append(e)
	var where := {}         # (who stands in which world: the streets, the shop, and the rooms you walk into)
	var place_of := {}      # npc id -> where in the world they stand
	for w in RoamData.DISTRICTS:
		Router.pulse()
		where[w] = RoamData.DISTRICTS[w].get("npcs", []) + RoamData.DISTRICTS[w].get("shop_npcs", [])
		for npc in RoamData.DISTRICTS[w].get("shop_npcs", []):
			Router.pulse()
			place_of[str(npc.get("id", ""))] = str(SHOP_NAME.get(w, "Card shop"))
	var rooms := Interiors.all_rooms()
	for rk in rooms:
		Router.pulse()
		var w := str(rooms[rk].get("district", "domino"))
		if where.has(w):
			where[w] = (where[w] as Array) + Interiors.people(str(rk))
			for npc in Interiors.people(str(rk)):
				place_of[str(npc.get("id", ""))] = str(rooms[rk].get("name", ""))
	for w in where:
		Router.pulse()
		for npc in where[w]:
			Router.pulse()
			var duel: Dictionary = npc.get("duel", {})
			if duel.is_empty():
				continue
			# Everyone who duels, for the "Where to find it" window: the show's characters too.
			var who_nm := str(npc.get("name", ""))
			var ck := str(npc.get("char", ""))
			if who_nm == "" and ck != "":
				who_nm = str(Characters.get_char(ck).get("name", ""))
			if who_nm == "" and Characters.DATA.has(str(npc.get("id", ""))):
				who_nm = str(Characters.get_char(str(npc.get("id", ""))).get("name", ""))
			if who_nm != "":
				var person := {"name": who_nm, "world": str(w), "place": str(place_of.get(str(npc.get("id", "")), "")), "hours": npc.get("hours", []),
					"color": npc.get("color", Characters.get_char(ck if ck != "" else str(npc.get("id", ""))).get("color", Color.WHITE))}
				for dk2 in duel.get("decks", [duel.get("deck", "")]):
					if not CardData.has_deck(str(dk2)):
						continue
					for id2 in CardData.deck_list(str(dk2)) + CardData.extra_list(str(dk2)):
						if not _people.has(int(id2)):
							_people[int(id2)] = []
						if not (_people[int(id2)] as Array).any(func(r): return r["name"] == who_nm and r["world"] == str(w)):
							(_people[int(id2)] as Array).append(person)
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
		if (PackShop.WORLD_PACKS[w] as Array).has(base) or (pack.get("families", []) as Array).any(func(f): return (PackShop.WORLD_PACKS[w] as Array).has(f)):
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


## When someone is around: "" (all day), "early mornings" or "at night".
static func when_text(h: Array) -> String:
	if h.size() != 2:
		return ""
	if int(h[0]) < 9 and int(h[1]) <= 12:
		return Loc.t("early mornings")
	if int(h[0]) >= 19 or int(h[1]) <= 5:
		return Loc.t("at night")
	return Loc.t("some hours")


## Everything the "Where to find it" window shows (0.55.3), world by world:
## {"everywhere": [packs on every shelf], "worlds": [{key, name, color, shop, packs, decks, people}]}
static func places(id: int) -> Dictionary:
	_build()
	var out := {"everywhere": [], "worlds": []}
	var packs: Array = _packs_of.get(id, [])
	for p in packs:
		if int(p.get("tab", 0)) > 1:
			(out["everywhere"] as Array).append(p)
	var colors := {}
	for wd in RoamData.WORLDS:
		colors[str(wd[0])] = wd[3]
	for w in WORLD_ORDER:
		var row := {"key": w, "name": world_name(w), "color": colors.get(w, UITheme.ACCENT), "shop": Loc.t(str(SHOP_NAME.get(w, "Card shop"))), "packs": [], "decks": [], "people": []}
		for p in packs:
			if int(p.get("tab", 0)) > 1:
				continue
			var base := Collection.base_key(str(p["key"]))
			var shelf: Array = PackShop.WORLD_PACKS.get(w, [])
			if shelf.has(base) or (p.get("families", []) as Array).any(func(f): return shelf.has(f)):
				(row["packs"] as Array).append(p)
		for e in _decks_any.get(id, []):
			var sold := false
			if str(e["kind"]) == "theme":
				sold = Collection.theme_sold_in(str(e["key"]), w)
			else:
				sold = str(e.get("era", "")) == str(Collection.WORLD_ERA.get(w, "-"))
			if sold:
				(row["decks"] as Array).append(e)
		for r in _people.get(id, []):
			if str(r["world"]) == w:
				(row["people"] as Array).append(r)
		if not (row["packs"] as Array).is_empty() or not (row["decks"] as Array).is_empty() or not (row["people"] as Array).is_empty():
			(out["worlds"] as Array).append(row)
	return out


## One line for the album's side panel: "3 packs · 2 decks · 4 duelists".
static func summary(id: int) -> String:
	var pl := places(id)
	var np := (pl["everywhere"] as Array).size()
	var nd := {}
	var nw := 0
	var who := {}
	for row in pl["worlds"]:
		np += (row["packs"] as Array).size()
		for e in row["decks"]:
			nd[str(e["key"])] = true
		for r in row["people"]:
			who[str(r["name"])] = true
	var bits: Array = []
	if np > 0:
		bits.append(Loc.t("%d packs") % np if np != 1 else Loc.t("1 pack"))
	if not nd.is_empty():
		bits.append(Loc.t("%d decks") % nd.size() if nd.size() != 1 else Loc.t("1 deck"))
	if not who.is_empty():
		bits.append(Loc.t("%d duelists") % who.size() if who.size() != 1 else Loc.t("1 duelist"))
	return "  ·  ".join(bits)
