class_name Tournament
## Tournaments, one per world. You register at a desk, earn Finals Badges by beating duelists
## around that world (each win also takes a card from the loser's deck), then play an
## eight-duelist knockout: quarterfinals, semifinals, final. Lose and you are out until you
## enter again. Everything here is bookkeeping; the world and the bracket screen show it.

const SAVE := "user://tourney.cfg"
const ROUNDS := ["QUARTERFINALS", "SEMIFINALS", "FINAL", "CHAMPION"]
const DEFS := {
	"domino": {"name": "Domino Street Championship", "district": "domino", "need": 6, "field": "kaibacorp", "color": Color("ffd166"),
		"desk": Vector3(-6.2, 0.2, -37.6), "desk_yaw": 0.5, "prize_dp": 1500,
		"blurb": "Beat duelists anywhere in the city for Finals Badges. Every win also takes a card from their deck. Six badges opens the finals at the tower.",
		"pool": [{"char": "kaiba", "diff": 3}, {"char": "yugi", "diff": 3}, {"char": "joey", "diff": 2}, {"char": "mai", "diff": 2}, {"char": "bakura", "diff": 2},
			{"char": "marik", "diff": 3}, {"char": "pegasus", "diff": 3}, {"char": "weevil", "diff": 1}, {"char": "rex", "diff": 1}]},
	"academy": {"name": "Academy Dorm Cup", "district": "academy", "need": 4, "field": "academy", "color": Color("7cc4ff"),
		"desk": Vector3(12.6, 0.1, 27.0), "desk_yaw": 1.2, "prize_dp": 1200,
		"blurb": "Beat students around the island for Finals Badges. Every win also takes a card from their deck. Four badges opens the cup on the duel field.",
		"pool": [{"char": "jaden", "diff": 2}, {"char": "chazz", "diff": 2}, {"char": "alexis", "diff": 2}, {"char": "syrus", "diff": 1}, {"char": "zane", "diff": 3}, {"char": "aster", "diff": 3},
			{"char": "street_duelist", "name": "Rin Akagi", "deck": "jaden", "diff": 1}, {"char": "duelist_m5", "name": "Dax Morrow", "deck": "syrus", "diff": 2},
			{"char": "duelist_f1", "name": "Celeste Vane", "deck": "alexis", "diff": 3}]},
	"turbo": {"name": "Highway Grand Prix", "district": "ride", "need": 0, "field": "highway", "color": Color("ff8a3a"), "all_turbo": true, "prize_dp": 2000,
		"blurb": "Three rounds on the ring. Before each Turbo Duel you race a lap: the better you finish, the more Speed Counters you start with.",
		"pool": [{"char": "yusei", "diff": 2}, {"char": "jack", "diff": 3}, {"char": "crow", "diff": 1}, {"char": "akiza", "diff": 2}, {"char": "kalin", "diff": 2},
			{"char": "duelist_m9", "name": "Night Courier", "deck": "zane", "diff": 2}, {"char": "duelist_f1", "name": "Sector Queen", "deck": "mai", "diff": 2},
			{"char": "street_duelist", "name": "Satellite Ace", "deck": "joey", "diff": 1}, {"char": "duelist_m5", "name": "Overpass Ghost", "deck": "bakura", "diff": 3}]},
	"cup": {"name": "Crossroads Cup", "district": "domino", "need": 0, "field": "crossroads", "color": Color("c9a0ff"), "prize_dp": 4000,
		"requires": ["domino", "academy", "turbo"], "turbo_rounds": [1],
		"desk": Vector3(-22.0, 0.2, 57.4), "desk_yaw": PI,
		"blurb": "Champions only. Duelists from every era, a Turbo Duel in the semifinal, and one title above all the others.",
		"pool": [{"char": "yugi", "diff": 3}, {"char": "kaiba", "diff": 3}, {"char": "jaden", "diff": 3}, {"char": "zane", "diff": 3}, {"char": "yusei", "diff": 3},
			{"char": "jack", "diff": 3}, {"char": "yuma", "diff": 3}, {"char": "kite", "diff": 3}, {"char": "shark", "diff": 3}, {"char": "aster", "diff": 3},
			{"char": "marik", "diff": 3}, {"char": "pegasus", "diff": 3}]},
}

static var _loaded := false
static var data := {}


static func load_data() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		data = cfg.get_value("t", "data", {})


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("t", "data", data)
	cfg.save(SAVE)


static func st(id: String) -> Dictionary:
	load_data()
	if not data.has(id):
		data[id] = {"stage": "", "badges": 0, "from": [], "rounds": [], "round": 0, "titles": 0, "out_to": ""}
	return data[id]


static func in_district(district: String) -> Array:
	var out: Array = []
	for id in DEFS:
		if str(DEFS[id]["district"]) == district:
			out.append(str(id))
	return out


## The trophies you still need before this tournament lets you in ([] when it is open).
static func missing(id: String) -> Array:
	var out: Array = []
	for need in DEFS[id].get("requires", []):
		if titles(str(need)) <= 0:
			out.append(Loc.t(str(DEFS[need]["name"])))
	return out


## Is this round fought on runners?
static func is_turbo(id: String) -> bool:
	var d: Dictionary = DEFS[id]
	return d.get("all_turbo", false) or (d.get("turbo_rounds", []) as Array).has(int(st(id)["round"]))


static func titles(id: String) -> int:
	return int(st(id).get("titles", 0))


static func register(id: String) -> void:
	var s := st(id)
	s["stage"] = "qualify"
	s["badges"] = 0
	s["from"] = []
	s["rounds"] = []
	s["round"] = 0
	s["out_to"] = ""
	save()


## A duel won out in the world. Returns {} when it does not count, otherwise what you got.
static func street_win(district: String, npc_id: String, deck: String) -> Dictionary:
	for id in in_district(district):
		var s := st(id)
		if str(s["stage"]) != "qualify" or (s["from"] as Array).has(npc_id):
			continue
		(s["from"] as Array).append(npc_id)
		s["badges"] = int(s["badges"]) + 1
		# The ante: one card out of the loser's deck is yours now.
		var card := 0
		if CardData.has_deck(deck):
			var list: Array = Array(CardData.deck_list(deck))
			list.shuffle()
			for c in list:
				if int(Collection.owned.get(int(c), 0)) < 3:
					card = int(c)
					break
			if card != 0:
				Collection.owned[card] = int(Collection.owned.get(card, 0)) + 1
				Collection.save()
		save()
		return {"id": id, "badges": int(s["badges"]), "need": int(DEFS[id]["need"]), "card": card, "ready": int(s["badges"]) >= int(DEFS[id]["need"])}
	return {}


static func _entry(e: Dictionary) -> Dictionary:
	var info := Characters.get_char(str(e["char"]))
	return {"char": str(e["char"]), "name": str(e.get("name", info.get("short", info.get("name", e["char"])))),
		"deck": str(e.get("deck", info.get("deck", "joey"))), "diff": int(e.get("diff", 2)), "you": false}


## Draw the bracket: seven duelists from the pool and you, in random seats.
static func start_finals(id: String) -> void:
	var s := st(id)
	var pool: Array = []
	for e in DEFS[id]["pool"]:
		var en := _entry(e)
		if CardData.has_deck(str(en["deck"])):
			pool.append(en)
	pool.shuffle()
	var fallback := 0
	while pool.size() < 7:
		pool.append({"char": "street_duelist", "name": "Challenger %d" % (fallback + 1), "deck": ["joey", "kaiba", "yugi"][fallback % 3], "diff": 1, "you": false})
		fallback += 1
	var seats: Array = pool.slice(0, 7)
	seats.insert(randi() % 8, {"char": "player", "name": Profile.duelist_name, "deck": "", "diff": 2, "you": true})
	s["rounds"] = [seats]
	s["round"] = 0
	s["stage"] = "finals"
	s["out_to"] = ""
	save()


## Who you face next: {} if you are not in the finals.
static func my_match(id: String) -> Dictionary:
	var s := st(id)
	if str(s["stage"]) != "finals":
		return {}
	var now: Array = (s["rounds"] as Array)[int(s["round"])]
	for i in now.size():
		if now[i].get("you", false):
			return now[i ^ 1]
	return {}


static func duel_config(id: String) -> Dictionary:
	var opp := my_match(id)
	var d: Dictionary = DEFS[id]
	return {"opponent": str(opp["char"]), "opponent_name": str(opp["name"]), "opponent_deck": str(opp["deck"]),
		"player_deck": Collection.active_deck(), "player_char": "player", "difficulty": int(opp["diff"]),
		"field": str(d["field"]), "story": true, "lose_ok": true, "return_to": Router.ROAM, "tourney": id,
		"turbo": is_turbo(id), "continue_label": Loc.t("Back to the bracket")}


## Play out one round of the bracket. Matches without you are decided by who is stronger, with
## room for an upset. Returns {"won", "champion", "prize_dp", "cards"}.
static func resolve(id: String, won: bool) -> Dictionary:
	var s := st(id)
	var out := {"won": won, "champion": false, "prize_dp": 0, "cards": []}
	if str(s["stage"]) != "finals":
		return out
	var rounds: Array = s["rounds"]
	if not won:
		s["out_to"] = str(my_match(id).get("name", ""))
	# Finish this round, and if you are out, every round after it too.
	while (rounds.back() as Array).size() > 1:
		var now: Array = rounds.back()
		var nxt: Array = []
		for i in range(0, now.size(), 2):
			var a: Dictionary = now[i]
			var b: Dictionary = now[i + 1]
			if a.get("you", false) or b.get("you", false):
				var me: Dictionary = a if a.get("you", false) else b
				var foe: Dictionary = b if a.get("you", false) else a
				nxt.append(me if won else foe)
			else:
				var wa := float(int(a["diff"]) + 1)
				var wb := float(int(b["diff"]) + 1)
				nxt.append(a if randf() * (wa + wb) < wa else b)
		rounds.append(nxt)
		if won:
			break
	s["round"] = rounds.size() - 1
	if won and (rounds.back() as Array).size() == 1:
		s["stage"] = "won"
		s["titles"] = int(s.get("titles", 0)) + 1
		out["champion"] = true
		out["prize_dp"] = int(DEFS[id]["prize_dp"])
		Collection.dp += int(out["prize_dp"])
		# Three rare cards for the champion.
		var pools: Array = []
		for era in ["Duel Monsters", "GX", "5D's", "ZEXAL"]:
			pools.append_array(Collection.pool(era))
		var rare: Array = pools.filter(func(c): return CardData.rarity(int(c)) >= 2 and int(Collection.owned.get(int(c), 0)) < 3)
		rare.shuffle()
		for c in rare.slice(0, 3):
			Collection.owned[int(c)] = int(Collection.owned.get(int(c), 0)) + 1
			(out["cards"] as Array).append(int(c))
		Collection.save()
	elif not won:
		s["stage"] = "out"
	save()
	return out
