class_name Academy
## Duel Academy mode: pass the entrance exam, then climb the three dorms. Each week is three
## class duels and a Friday exam; pass the exam with enough class wins and you move up a dorm.
## From Ra Yellow on you can also enter the Academy Tournament, an 8-duelist knockout.

const SAVE := "user://academy.cfg"
const DORMS := [
	{"key": "red", "name": "Slifer Red", "color": Color("d9342b"), "motto": "The underdogs. Everybody starts somewhere."},
	{"key": "yellow", "name": "Ra Yellow", "color": Color("f2c230"), "motto": "Solid duelists who earned their place."},
	{"key": "blue", "name": "Obelisk Blue", "color": Color("2f6fe0"), "motto": "The elite. Everyone here wants your spot."},
]
const DAYS := ["Monday", "Wednesday", "Friday morning", "Friday exam"]
const NEED_WINS := 2

## Class opponents per dorm: [character key, shown name, deck, difficulty].
const CLASSES := [
	[["red_student", "Red Dorm Student", "joey", 0], ["syrus", "", "syrus", 0], ["student_girl", "First-Year Student", "yuma", 0],
		["jaden", "", "jaden", 1], ["student_boy", "Lunch-Table Champ", "yugi", 0]],
	[["yellow_student", "Yellow Dorm Student", "rex", 1], ["student_girl", "Honor Student", "mai", 1], ["jaden", "", "jaden", 1],
		["yellow_student", "Dorm Strategist", "weevil", 1], ["syrus", "", "syrus", 1]],
	[["chazz", "", "chazz", 2], ["alexis", "", "alexis", 2], ["blue_student", "Blue Dorm Elite", "kaiba", 2],
		["aster", "", "aster", 2], ["blue_student", "Blue Dorm Prefect", "kite", 2]],
]
## Friday exam proctors: the entrance exam is index 0, then one per dorm.
const EXAMS := [
	{"char": "professor", "name": "Exam Proctor", "deck": "rex", "difficulty": 0, "title": "Entrance Exam"},
	{"char": "professor", "name": "Exam Proctor", "deck": "kaiba", "difficulty": 1, "title": "Slifer Red Promotion Exam"},
	{"char": "chazz", "name": "", "deck": "chazz", "difficulty": 2, "title": "Ra Yellow Promotion Exam"},
	{"char": "zane", "name": "", "deck": "zane", "difficulty": 3, "title": "Graduation Duel"},
]
const TOURNEY_POOL := [["jaden", "jaden", 2], ["chazz", "chazz", 2], ["alexis", "alexis", 2], ["syrus", "syrus", 1],
	["aster", "aster", 3], ["zane", "zane", 3], ["blue_student", "kaiba", 2], ["yellow_student", "rex", 1], ["red_student", "joey", 1]]
const FALLBACK_DECKS := ["jaden", "joey", "kaiba", "yugi", "yusei", "yuma"]

static var _loaded := false
static var d := {}


static func _defaults() -> Dictionary:
	return {"enrolled": false, "dorm": 0, "week": 1, "day": 0, "wins": 0, "graduated": false, "log": [],
		"pending": {}, "tourney": {}, "trophies": 0, "uniform": true, "class_wins": 0, "exams_passed": 0}


static func load_data() -> void:
	if _loaded:
		return
	_loaded = true
	d = _defaults()
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		var got = cfg.get_value("academy", "data", {})
		if got is Dictionary:
			for k in got:
				d[k] = got[k]


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("academy", "data", d)
	cfg.save(SAVE)


static func reset() -> void:
	d = _defaults()
	save()


static func dorm() -> Dictionary:
	load_data()
	return DORMS[clampi(int(d["dorm"]), 0, 2)]


static func enrolled() -> bool:
	load_data()
	return bool(d["enrolled"])


## The jacket color the player wears on the island, or null when not enrolled.
static func uniform_color() -> Variant:
	load_data()
	if not d["enrolled"] or not d.get("uniform", true):
		return null
	return dorm()["color"]


static func rank_title() -> String:
	load_data()
	if not d["enrolled"]:
		return "Applicant"
	if d["graduated"]:
		return "Academy Graduate"
	return str(dorm()["name"])


static func _deck(want: String, salt: int) -> String:
	if CardData.has_deck(want):
		return want
	return FALLBACK_DECKS[absi(salt) % FALLBACK_DECKS.size()]


static func _name(key: String, shown: String) -> String:
	if shown != "":
		return shown
	return str(Characters.get_char(key).get("name", key.capitalize()))


## What today's duel is: {kind, char, name, deck, difficulty, title}.
static func today() -> Dictionary:
	load_data()
	if not d["enrolled"]:
		var e: Dictionary = EXAMS[0]
		return {"kind": "entrance", "char": e["char"], "name": _name(e["char"], e["name"]), "deck": _deck(e["deck"], 0),
			"difficulty": e["difficulty"], "title": e["title"]}
	var dm := int(d["dorm"])
	if int(d["day"]) >= 3:
		var e2: Dictionary = EXAMS[dm + 1]
		return {"kind": "exam", "char": e2["char"], "name": _name(e2["char"], e2["name"]), "deck": _deck(e2["deck"], dm),
			"difficulty": e2["difficulty"], "title": e2["title"]}
	var pool: Array = CLASSES[dm]
	var c: Array = pool[(int(d["week"]) * 3 + int(d["day"])) % pool.size()]
	return {"kind": "class", "char": c[0], "name": _name(c[0], c[1]), "deck": _deck(c[2], int(d["week"]) + int(d["day"])),
		"difficulty": c[3], "title": "Class Duel"}


static func duel_config(t: Dictionary) -> Dictionary:
	return {
		"opponent": t["char"], "opponent_deck": t["deck"], "opponent_name": t["name"],
		"player_deck": Engine.get_main_loop().root.get_node("Router").duel_config.get("player_deck", "echo"), "player_char": "player",
		"difficulty": t["difficulty"], "field": "academy",
		"story": true, "lose_ok": true, "return_to": "res://scenes/main_menu.tscn", "continue_label": "Back to the Academy",
	}


static func start(t: Dictionary) -> void:
	d["pending"] = {"kind": t["kind"], "name": t["name"]}
	save()


## Apply the result of the duel that was started with start(). Returns lines to show the player.
static func resolve(won: bool) -> Array:
	load_data()
	var p: Dictionary = d.get("pending", {})
	if p.is_empty():
		return []
	d["pending"] = {}
	var out := []
	var col = Engine.get_main_loop().root.get_node("Collection")
	match str(p.get("kind", "")):
		"entrance":
			if won:
				d["enrolled"] = true
				d["dorm"] = 0
				d["week"] = 1
				d["day"] = 0
				d["wins"] = 0
				col.dp += 300
				out = ["ENTRANCE EXAM PASSED", "Welcome to Duel Academy. You start in Slifer Red, like every legend did.", "+300 Duel Points"]
			else:
				out = ["EXAM FAILED", "The proctor will see you again whenever you are ready. There is no limit on retakes."]
		"class":
			d["day"] = int(d["day"]) + 1
			var lg: Array = d.get("log", [])
			lg.append(won)
			d["log"] = lg
			if won:
				d["wins"] = int(d["wins"]) + 1
				d["class_wins"] = int(d.get("class_wins", 0)) + 1
				col.dp += 60
				out = ["CLASS DUEL WON", "That counts toward this week's grade.", "+60 Duel Points"]
			else:
				out = ["CLASS DUEL LOST", "No credit today. The week goes on."]
		"exam":
			var enough := int(d["wins"]) >= NEED_WINS
			if won and enough:
				d["exams_passed"] = int(d.get("exams_passed", 0)) + 1
				if int(d["dorm"]) >= 2:
					d["graduated"] = true
					col.dp += 2000
					out = ["GRADUATION DUEL WON", "You beat the Kaiser. Duel Academy has a new top duelist.", "+2000 Duel Points"]
				else:
					d["dorm"] = int(d["dorm"]) + 1
					col.dp += 600
					out = ["PROMOTED TO %s" % str(DORMS[int(d["dorm"])]["name"]).to_upper(), "A new jacket is waiting for you on the island.", "+600 Duel Points"]
			elif won:
				col.dp += 150
				out = ["EXAM PASSED", "A pass, but you needed %d class wins this week to move up. Next week." % NEED_WINS, "+150 Duel Points"]
			else:
				out = ["EXAM FAILED", "A new week starts Monday. Win your class duels and try again."]
			d["week"] = int(d["week"]) + 1
			d["day"] = 0
			d["wins"] = 0
			d["log"] = []
		"tourney":
			out = _tourney_result(won)
	col.save()
	save()
	return out


# ------------------------------------------------------------------ tournament

static func tourney_open() -> bool:
	load_data()
	return d["enrolled"] and (int(d["dorm"]) >= 1 or d["graduated"])


static func tourney_active() -> bool:
	load_data()
	return not d.get("tourney", {}).is_empty() and not d["tourney"].get("done", false)


## Draw a fresh bracket: 8 slots, the player in a random one.
static func tourney_new() -> void:
	var pool := TOURNEY_POOL.duplicate()
	pool.shuffle()
	var slots := []
	for i in 7:
		var e: Array = pool[i]
		slots.append({"char": e[0], "name": _name(e[0], ""), "deck": _deck(e[1], i), "power": e[2]})
	slots.insert(randi() % 8, {"char": "player", "name": "", "deck": "", "power": 2})
	d["tourney"] = {"rounds": [slots], "round": 0, "done": false, "won": false}
	save()


static func tourney_round_name(r: int) -> String:
	return ["Quarterfinal", "Semifinal", "Final"][clampi(r, 0, 2)]


## The player's next opponent in the bracket, or {} when out or finished.
static func tourney_next() -> Dictionary:
	if not tourney_active():
		return {}
	var t: Dictionary = d["tourney"]
	var cur: Array = t["rounds"][int(t["round"])]
	for i in cur.size():
		if cur[i]["char"] == "player":
			return cur[i ^ 1]
	return {}


static func tourney_today() -> Dictionary:
	var o := tourney_next()
	if o.is_empty():
		return {}
	var r := int(d["tourney"]["round"])
	return {"kind": "tourney", "char": o["char"], "name": o["name"], "deck": o["deck"], "difficulty": mini(3, int(o["power"]) + (1 if r == 2 else 0)),
		"title": "Academy Tournament: " + tourney_round_name(r)}


static func _tourney_result(won: bool) -> Array:
	var t: Dictionary = d.get("tourney", {})
	if t.is_empty():
		return []
	var r := int(t["round"])
	var cur: Array = t["rounds"][r]
	var next := []
	for i in range(0, cur.size(), 2):
		var a: Dictionary = cur[i]
		var b: Dictionary = cur[i + 1]
		if a["char"] == "player" or b["char"] == "player":
			var me: Dictionary = a if a["char"] == "player" else b
			var other: Dictionary = b if a["char"] == "player" else a
			next.append(me if won else other)
		else:
			var pa := float(a["power"]) + 1.0
			var pb := float(b["power"]) + 1.0
			next.append(a if randf() < pa / (pa + pb) else b)
	t["rounds"].append(next)
	var col = Engine.get_main_loop().root.get_node("Collection")
	if not won:
		# Play the rest out so the bracket shows who took it.
		while t["rounds"].back().size() > 1:
			var last: Array = t["rounds"].back()
			var nx := []
			for i in range(0, last.size(), 2):
				var pa2 := float(last[i]["power"]) + 1.0
				var pb2 := float(last[i + 1]["power"]) + 1.0
				nx.append(last[i] if randf() < pa2 / (pa2 + pb2) else last[i + 1])
			t["rounds"].append(nx)
		t["done"] = true
		t["round"] = t["rounds"].size() - 1
		return ["KNOCKED OUT", "Out in the %s. The bracket shows who went on to win." % tourney_round_name(r).to_lower()]
	if next.size() == 1:
		t["done"] = true
		t["won"] = true
		t["round"] = r + 1
		d["trophies"] = int(d.get("trophies", 0)) + 1
		col.dp += 1500
		return ["TOURNAMENT CHAMPION", "You won the Academy Tournament. The trophy goes on your shelf.", "+1500 Duel Points"]
	t["round"] = r + 1
	col.dp += 200
	return ["%s WON" % tourney_round_name(r).to_upper(), "You are through to the %s." % tourney_round_name(r + 1).to_lower(), "+200 Duel Points"]
