extends Node
## Dev: DuelWhy on made-up engine messages: what is in force, and the reasons it gives.
##   godot --headless --path . res://tests/why_unit.tscn
var fails := 0


class FakeDuel:
	var st: DuelState
	func _loc_card(_l):
		return null


func id_of(name: String) -> int:
	for id in Collection.all_cards():
		if str(CardData.get_card(int(id)).get("name", "")) == name:
			return int(id)
	return 0


func check(what: String, ok: bool) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		fails += 1


func run(msgs: Array, d) -> Array:
	var w := DuelWhy.new()
	w.names = ["You", "Rival"]
	var ev: Array = []
	for m in msgs:
		w.read(m, ev, d)
	return [w, ev]


func whys(ev: Array) -> Array:
	return ev.filter(func(e): return e["type"] == "why")


func link(id: int, con: int) -> Array:
	return [{"t": 70, "card": {"code": id, "con": con, "loc": 8, "seq": 0}, "n": 1}, {"t": 72, "n": 1}, {"t": 73, "n": 1}, {"t": 74}]


func battle_direct(con: int, atk: int) -> Array:
	return [{"t": 110, "a": {"con": con, "loc": 4, "seq": 0}, "b": {"con": con, "loc": 0, "seq": 0, "pos": 0}},
		{"t": 111, "a": {"con": con, "loc": 4, "seq": 0}, "aa": atk, "b": {"con": con, "loc": 0, "seq": 0, "pos": 0}, "da": 0, "dd": 0}]


func _ready() -> void:
	var d := FakeDuel.new()
	d.st = DuelState.new()
	d.st.players = [DuelState.PlayerState.new(), DuelState.PlayerState.new()]
	var waboku := id_of("Waboku")
	var roar := id_of("Threatening Roar")
	var peace := id_of("One Day of Peace")
	var bond := id_of("Power Bond")
	var kuri := id_of("Kuriboh")
	var bind := id_of("Gravity Bind")
	check("cards found", waboku * roar * peace * bond * kuri * bind != 0)
	# Waboku in the opponent's Battle Phase: the attack lands, no damage, the reason is Waboku.
	var r := run([{"t": 40, "p": 1}] + link(waboku, 0) + battle_direct(1, 2500) + [{"t": 10}], d)
	var w: DuelWhy = r[0]
	check("Waboku: no battle damage for you this turn", w.statuses(0).any(func(x): return str(x["kind"]) == "no_bdmg"))
	var ws := whys(r[1])
	check("Waboku: the battle says why", ws.size() >= 2 and str(ws[-1]["text"]).contains("Waboku") and str(ws[-1]["text"]).contains("2500"))
	# Damage that does land: no reason given.
	r = run([{"t": 40, "p": 1}] + battle_direct(1, 1800) + [{"t": 91, "p": 0, "v": 1800}, {"t": 10}], d)
	check("damage that lands: no reason", whys(r[1]).is_empty())
	# Threatening Roar: the rival can't attack this turn.
	r = run([{"t": 40, "p": 1}] + link(roar, 0), d)
	w = r[0]
	check("Threatening Roar: the rival can't attack", w.statuses(1).size() == 1 and str(w.statuses(1)[0]["kind"]) == "no_attack")
	check("Threatening Roar: gone next turn", (run([{"t": 40, "p": 1}] + link(roar, 0) + [{"t": 40, "p": 0}], d)[0] as DuelWhy).statuses(1).is_empty())
	# One Day of Peace on your turn lasts through the rival's next turn, then ends.
	r = run([{"t": 40, "p": 0}] + link(peace, 0) + [{"t": 40, "p": 1}], d)
	w = r[0]
	check("One Day of Peace: still on in the rival's turn", w.statuses(0).size() == 1 and w.statuses(1).size() == 1)
	r = run([{"t": 40, "p": 0}] + link(peace, 0) + [{"t": 40, "p": 1}, {"t": 40, "p": 0}], d)
	check("One Day of Peace: over on your next turn", (r[0] as DuelWhy).statuses(0).is_empty())
	# Power Bond under One Day of Peace: the End Phase bill is explained.
	r = run([{"t": 40, "p": 0}] + link(peace, 0) + [{"t": 40, "p": 1}] + link(bond, 1) + [{"t": 41, "phase": 0x200}, {"t": 40, "p": 0}], d)
	ws = whys(r[1])
	check("Power Bond: no damage, says One Day of Peace", ws.any(func(e): return str(e["text"]).contains("Power Bond") and str(e["text"]).contains("One Day of Peace")))
	# Power Bond with nothing in the way: the damage comes, no reason.
	r = run([{"t": 40, "p": 1}] + link(bond, 1) + [{"t": 41, "phase": 0x200}, {"t": 91, "p": 1, "v": 2800}, {"t": 40, "p": 0}], d)
	check("Power Bond paid: no reason", whys(r[1]).is_empty())
	# Kuriboh discarded during the battle: the reason is Kuriboh.
	r = run([{"t": 40, "p": 1}, battle_direct(1, 3000)[0]] + link(kuri, 0) + [battle_direct(1, 3000)[1], {"t": 10}], d)
	ws = whys(r[1])
	check("Kuriboh: the battle says Kuriboh", ws.size() == 1 and str(ws[0]["text"]).contains("Kuriboh"))
	# A face-up Gravity Bind: shown for both players, as "some monsters".
	var gb := DuelState.CardInst.new()
	gb.id = bind
	gb.data = CardData.get_card(bind)
	gb.face_up = true
	d.st.players[0].spells[0] = gb
	r = run([{"t": 40, "p": 0}, {"t": 11}], d)
	w = r[0]
	check("Gravity Bind face-up: shown on both sides", w.statuses(0).size() == 1 and w.statuses(1).size() == 1 and w.statuses(0)[0].get("partial", false))
	d.st.players[0].spells[0] = null
	# Something unknown stops the damage: still a line, never silence.
	r = run([{"t": 40, "p": 1}] + battle_direct(1, 1200) + [{"t": 10}], d)
	ws = whys(r[1])
	check("unknown cause: a generic reason", ws.size() == 1 and str(ws[0]["text"]).contains("1200"))
	print("WHY UNIT DONE, failures: %d" % fails)
	get_tree().quit(1 if fails > 0 else 0)
