class_name Knockout
extends RefCounted
## The Knockout in Free Duel (not the four world tournaments in tournament.gd): eight duelists, three rounds, one loss and you are out. You
## play your own matches; the others are decided off the table. It is kept on disk, so you can
## leave between rounds and come back to the same bracket.
##
## Also the duel of the day: one set duel with a twist, the same for the whole day, that pays
## the first time you win it.

static var SAVE := Saves.u("knockout.cfg")
const ROUNDS := ["Quarterfinal", "Semifinal", "Final"]
const PRIZES := [0, 600, 1000, 1500]            # for winning it, by difficulty (1 Easy .. 3 Hard)
const CUPS := ["", "Bronze cup", "Silver cup", "Gold cup"]
const CUP_COLORS := [Color.WHITE, Color("d98a4a"), Color("cfd6e2"), Color("ffd166")]
## Where each round is played: your opponent's own field, the Academy arena, the Duel Dome.
const FIELDS := ["auto", "academy", "kaibacorp"]

## {seeds: [8 keys, "player" among them], wins: [[4], [2], [1]] (who went through, per round),
##  round: the round you play next (0..2), difficulty, over: "" | "won" | "out", seed}
static var state := {}
static var _loaded := false
static var no_save := false          # tests: keep the bracket in memory only


static func load_data() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(SAVE) == OK:
		state = cfg.get_value("t", "state", {})


static func save_data() -> void:
	if no_save:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("t", "state", state)
	cfg.save(SAVE)


## Is there a bracket (running or just finished) to show?
static func has_bracket() -> bool:
	load_data()
	return state.has("seeds")


## Still in it, with a duel to play?
static func running() -> bool:
	return has_bracket() and str(state.get("over", "")) == ""


## Duelists you have met who have a deck.
static func pool() -> Array:
	var out: Array = []
	for k in Characters.ORDER:
		if str(k) != "player" and Characters.available(str(k)) and Unlocks.opponent(str(k)):
			out.append(str(k))
	return out


## Everybody with a deck, met or not.
static func everyone() -> Array:
	var out: Array = []
	for k in Characters.ORDER:
		if str(k) != "player" and Characters.available(str(k)):
			out.append(str(k))
	return out


static func can_enter() -> bool:
	return everyone().size() >= 7


## A new bracket: seven of the duelists you know, drawn at random, and you.
static func start(difficulty: int) -> void:
	load_data()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var seed_n := rng.randi()
	# The duelists you have met come first; if they are fewer than seven, the other seats go to
	# duelists you have not met yet (a win over one of them counts as meeting them).
	var others := _shuffled(pool(), rng)
	if others.size() < 7:
		var rest := _shuffled(everyone().filter(func(k): return not others.has(k)), rng)
		others.append_array(rest)
	var seeds: Array = _shuffled(others.slice(0, 7), rng)
	seeds.insert(rng.randi_range(0, 7), "player")
	state = {"seeds": seeds, "wins": [[], [], []], "round": 0, "difficulty": clampi(difficulty, 1, 3), "over": "", "seed": seed_n}
	save_data()


static func _shuffled(list: Array, rng: RandomNumberGenerator) -> Array:
	var out := list.duplicate()
	for i in range(out.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = out[i]
		out[i] = out[j]
		out[j] = t
	return out


## The pairs of a round: [[a, b], ...]. Round 0 is the seeds two by two; later rounds are the
## winners of the round before, two by two. A pair not decided yet has "" in it.
static func pairs(r: int) -> Array:
	var from: Array = state.get("seeds", []) if r == 0 else (state.get("wins", [[], [], []])[r - 1] as Array)
	var n := 4 >> r
	var out: Array = []
	for i in n:
		out.append([str(from[i * 2]) if i * 2 < from.size() else "", str(from[i * 2 + 1]) if i * 2 + 1 < from.size() else ""])
	return out


## Who you play next ("" when you are out or it is over).
static func opponent() -> String:
	if not running():
		return ""
	for p in pairs(int(state["round"])):
		if p[0] == "player":
			return str(p[1])
		if p[1] == "player":
			return str(p[0])
	return ""


static func round_name() -> String:
	return str(ROUNDS[clampi(int(state.get("round", 0)), 0, 2)])


## What the duel of your next round is set up as.
static func duel_config() -> Dictionary:
	var r := int(state.get("round", 0))
	var d := int(state.get("difficulty", 1))
	return {"player_char": "player", "opponent": opponent(), "player_deck": Engine.get_main_loop().root.get_node("Collection").active_deck(),
		"difficulty": mini(3, d + (1 if r == 2 else 0)), "field": FIELDS[r], "story": true, "lose_ok": true,
		"return_to": "res://scenes/main_menu.tscn", "continue_label": "Back to the bracket", "knockout": true}


## Your duel of this round is over: you go through or you are out, and every other match of the
## round is decided. If you are out the rest of the bracket is played to its end, so you can see
## who took it. Returns what happened: {round, won, champion, prize, cup}.
static func report(won: bool) -> Dictionary:
	var out := {"round": int(state.get("round", 0)), "won": won, "champion": "", "prize": 0, "cup": 0}
	if not running():
		return out
	var rng := RandomNumberGenerator.new()
	var r := int(state["round"])
	_play_round(r, won, rng)
	if won and r < 2:
		state["round"] = r + 1
	elif won:
		state["over"] = "won"
		out["champion"] = "player"
		var d := int(state.get("difficulty", 1))
		out["prize"] = int(PRIZES[d])
		out["cup"] = d
	else:
		state["over"] = "out"
		for later in range(r + 1, 3):
			_play_round(later, false, rng)
		out["champion"] = str((state["wins"][2] as Array)[0])
		out["prize"] = 100 * r                  # something for every round you did win
	save_data()
	return out


static func _play_round(r: int, i_won: bool, rng: RandomNumberGenerator) -> void:
	rng.seed = int(state.get("seed", 1)) + r * 7919
	var through: Array = []
	for p in pairs(r):
		if p[0] == "player" or p[1] == "player":
			var other := str(p[1]) if p[0] == "player" else str(p[0])
			through.append("player" if i_won else other)
		else:
			through.append(str(p[rng.randi_range(0, 1)]))
	(state["wins"] as Array)[r] = through


static func champion() -> String:
	var last: Array = state.get("wins", [[], [], []])[2]
	return str(last[0]) if not last.is_empty() else ""


static func clear() -> void:
	state = {}
	save_data()


# ------------------------------------------------------------------ the duel of the day

## The twists a day can have. `cfg` is laid over the duel's setup; "borrow" hands you another
## duelist's deck, "mirror" hands you your opponent's.
const TWISTS := [
	{"id": "half", "name": "Sudden death", "text": "You both start at 4000 Life Points.", "cfg": {"lp": 4000}},
	{"id": "long", "name": "Marathon", "text": "You both start at 16000 Life Points.", "cfg": {"lp": 16000}},
	{"id": "hand", "name": "Full hands", "text": "You both start with 7 cards.", "cfg": {"hand": 7}},
	{"id": "hard", "name": "No mercy", "text": "Hard difficulty, and nobody gets a Destiny Draw.", "cfg": {"difficulty": 3, "destiny": false}},
	{"id": "second", "name": "On the back foot", "text": "They take the first turn.", "cfg": {"first": 1}},
	{"id": "borrow", "name": "Borrowed deck", "text": "You play %s's deck instead of your own.", "cfg": {}},
	{"id": "mirror", "name": "Mirror match", "text": "You both play their deck.", "cfg": {}},
]
const DAILY_REWARD := 300


## Today's duel: {day, opponent, twist (one of TWISTS), text, lender, cfg}. The same all day.
static func daily() -> Dictionary:
	var day := Time.get_date_string_from_system()
	var who := pool()
	if who.size() < 2:
		who = everyone()
	if who.is_empty():
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("crossroads-daily-" + day)
	var opp := str(who[rng.randi_range(0, who.size() - 1)])
	var tw: Dictionary = TWISTS[rng.randi_range(0, TWISTS.size() - 1)]
	var lender := ""
	var others: Array = who.filter(func(k): return str(k) != opp)
	if str(tw["id"]) == "borrow" and others.is_empty():
		tw = TWISTS[0]
	var cfg := {"player_char": "player", "opponent": opp, "player_deck": Engine.get_main_loop().root.get_node("Collection").active_deck(),
		"difficulty": 2, "field": "auto", "story": true, "lose_ok": true, "return_to": "res://scenes/main_menu.tscn",
		"continue_label": "Back to Free Duel", "daily": day}
	for k in (tw["cfg"] as Dictionary):
		cfg[k] = tw["cfg"][k]
	var text := str(tw["text"])
	match str(tw["id"]):
		"borrow":
			lender = str(others[rng.randi_range(0, others.size() - 1)])
			cfg["player_deck"] = str(Characters.DATA[lender]["deck"])
		"mirror":
			cfg["player_deck"] = str(Characters.DATA[opp]["deck"])
	return {"day": day, "opponent": opp, "twist": tw, "text": text, "lender": lender, "cfg": cfg}


static func daily_done() -> bool:
	var rec: Dictionary = Engine.get_main_loop().root.get_node("Collection").record
	return str((rec.get("daily_duel", {}) as Dictionary).get("day", "")) == Time.get_date_string_from_system()


## How many days' duels you have won so far.
static func daily_count() -> int:
	var rec: Dictionary = Engine.get_main_loop().root.get_node("Collection").record
	return int((rec.get("daily_duel", {}) as Dictionary).get("count", 0))


## Today's duel was won: it pays once. Returns the Duel Points paid (0 if it already had).
static func daily_win(day: String) -> int:
	var col = Engine.get_main_loop().root.get_node("Collection")
	var dd: Dictionary = col.record.get("daily_duel", {})
	if str(dd.get("day", "")) == day or day != Time.get_date_string_from_system():
		return 0
	dd["day"] = day
	dd["count"] = int(dd.get("count", 0)) + 1
	col.record["daily_duel"] = dd
	col.last_reward.append([Loc.t("Duel of the day"), DAILY_REWARD])
	col.dp += DAILY_REWARD
	# Every third one won comes with a card of Lumen's you do not have three of yet.
	if int(dd["count"]) % 3 == 0:
		var gift: int = col.lumen_copy()
		if gift != 0:
			col.last_reward.append(["New card: " + str(CardData.get_card(gift).get("name", "")), 0])
	col.save()
	return DAILY_REWARD
