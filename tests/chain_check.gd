extends Node
## Dev: Accumulated Fortune in the real engine. "Activate only as Chain Link 4 or higher. You cannot
## activate this card if multiple cards/effects with the same name are in that Chain."
##   godot --headless --path . res://tests/chain_check.tscn [-- -v]
const AF := 98444741
const JAR := 83968380
const RECKLESS := 37576645
const YATA := 30461781       # Legacy of Yata-Garasu
const GOBLIN := 9744376      # Good Goblin Housekeeping
var verbose := false
var fails := 0


## Player 0 has `sets` face-down and activates them in that order, one on top of the other (player 1
## never answers). Returns, for each chain length reached, whether Accumulated Fortune was on offer.
func run(sets: Array, order: Array) -> Dictionary:
	var st := DuelState.new()
	var d := OcgDuel.new()
	var filler: Array = []
	for i in 40:
		filler.append(12607053 if i % 2 == 0 else 36361633)
	d.prepare(st, [filler, filler], [[], []], ["A", "B"], 0, 7, {"st": [sets, []]})
	if not d.start([8000, 8000], [0, 0]):
		return {}
	var offered := {}      # chain length -> was AF on offer
	var todo := order.duplicate()
	var guard := 0
	while not d.over and guard < 400:
		guard += 1
		d.advance()
		var m = d.request
		if m == null:
			break
		var t := int(m["t"])
		var who := int(m.get("p", m.get("player", 0)))
		if verbose:
			print("  ask t=%d p=%d chain=%d keys=%s" % [t, who, d.chain_cards.size(), str(m.keys())])
		if t == 11 or t == 10:
			# The main phase: start the chain with the first card of the plan.
			if who != 0 or todo.is_empty():
				break
			var acts: Array = m.get("act", m.get("activate", []))
			var hit := -1
			for i in acts.size():
				if int(acts[i]["code"]) == int(todo[0]):
					hit = i
					break
			if hit < 0:
				offered["start"] = false
				break
			todo.pop_front()
			d.answer(OcgDuel.i32((hit << 16) | 5))
		elif t == 16:
			var ch: Array = m["chains"]
			if who != 0:
				d.answer(OcgDuel.i32(-1))
				continue
			var has_af := false
			for c in ch:
				if int(c["code"]) == AF:
					has_af = true
			offered[d.chain_cards.size()] = has_af
			if verbose:
				var codes: Array = []
				for c in ch:
					codes.append(OcgCore.card_name(int(c["code"])))
				print("    on offer at chain %d: %s   next in the plan: %s" % [d.chain_cards.size(), str(codes), OcgCore.card_name(int(todo[0])) if not todo.is_empty() else "-"])
			var hit := -1
			if not todo.is_empty():
				for i in ch.size():
					if int(ch[i]["code"]) == int(todo[0]):
						hit = i
						break
			if hit >= 0:
				todo.pop_front()
			d.answer(OcgDuel.i32(hit))
			if hit < 0:
				break
		else:
			# (anything else: the first choice)
			if verbose:
				print("    other question: ", str(m).left(300))
			break
	d.close()
	return offered


func check(ok: bool, what: String) -> void:
	print(("  ok    " if ok else "  FAIL  ") + what)
	if not ok:
		fails += 1


func _ready() -> void:
	verbose = "-v" in OS.get_cmdline_user_args()
	if not OcgCore.ensure_loaded():
		print("ENGINE NOT LOADED")
		get_tree().quit(1)
		return
	var r := run([JAR, RECKLESS, YATA, AF], [JAR, RECKLESS, YATA])
	print("Jar of Greed, Reckless Greed, Legacy of Yata-Garasu: ", r)
	check(bool(r.get(3, false)), "Chain Link 4 with one Jar of Greed in the chain: Accumulated Fortune can be activated")
	check(not bool(r.get(2, true)) and not bool(r.get(1, true)), "as Chain Link 2 or 3 it cannot")
	r = run([JAR, JAR, YATA, AF], [JAR, JAR, YATA])
	print("Jar of Greed, Jar of Greed, Legacy of Yata-Garasu: ", r)
	check(r.has(3) and not bool(r.get(3, true)), "Chain Link 4 with two Jar of Greed in the chain: it cannot")
	r = run([GOBLIN, RECKLESS, YATA, AF], [GOBLIN, RECKLESS, YATA])
	print("Good Goblin Housekeeping, Reckless Greed, Legacy of Yata-Garasu: ", r)
	check(bool(r.get(3, false)), "Chain Link 4, no repeated names, no Jar of Greed: it can")
	# A second copy on top of the first is legal: when it is activated there is still only one in the
	# chain (the old official ruling for these cards says so in as many words). A third is not.
	r = run([JAR, RECKLESS, YATA, AF, AF], [JAR, RECKLESS, YATA, AF, AF])
	print("...then a second Accumulated Fortune on top of the first: ", r)
	check(bool(r.get(3, false)) and bool(r.get(4, false)), "a second Accumulated Fortune on top of the first: it can (the chain had only one when it was activated)")
	print("CHAIN CHECK: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	get_tree().quit(fails)
