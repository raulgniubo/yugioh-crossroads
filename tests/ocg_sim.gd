extends Node
## Dev: placeholder CPU against placeholder CPU on the new engine, no screen.
##   godot --headless -s tests/ocg_sim.gd -- <deck a|all> <deck b> <duels> [seed] [-v]
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var a := str(args[0]) if args.size() > 0 else "deck_monarchs"
	var b := str(args[1]) if args.size() > 1 else "deck_gem_knight"
	var n := int(args[2]) if args.size() > 2 else 3
	var seed0 := int(args[3]) if args.size() > 3 else 1
	var verbose := "-v" in args
	if a == "ids":
		# Dev: every card id the game can put in a duel, for tools/make_ocg_data.py.
		var ids := {}
		for id in Collection.all_cards():
			ids[int(id)] = true
		for id in CardData.ORIGINALS:
			ids[int(id)] = true
		for k in CardData.DECKS.keys() + CardData.NAMED_DECKS.keys():
			for id in CardData.deck_list(str(k)) + CardData.extra_list(str(k)) + CardData.legend_deck(str(k)):
				ids[int(id)] = true
		var f := FileAccess.open(b, FileAccess.WRITE)
		for id in ids:
			f.store_line(str(id))
		f.close()
		print("ids ", ids.size(), " -> ", b)
		get_tree().quit(0)
		return
	if not OcgCore.ensure_loaded():
		print("ENGINE NOT LOADED: ", OcgCore.why_not())
		get_tree().quit(1)
		return
	var keys: Array = [a]
	if a == "all":
		keys = CardData.DECKS.keys() + CardData.NAMED_DECKS.keys()
		keys = keys.filter(func(k): return CardData.deck_list(str(k)).size() >= 20)
	var bad := 0
	var total := 0
	var t0 := Time.get_ticks_msec()
	var all_errors := {}
	for ki in keys.size():
		var ka := str(keys[ki])
		var kb := b if a != "all" else str(keys[(ki + 1) % keys.size()])
		var wins := [0, 0, 0]
		for g in n:
			var r := one(ka, kb, seed0 + g + ki * 100, verbose)
			total += 1
			wins[r["winner"]] += 1
			if not (r["errors"] as Array).is_empty():
				bad += 1
				for e in r["errors"]:
					var k := str(e).left(90)
					all_errors[k] = int(all_errors.get(k, 0)) + 1
				if verbose or a != "all":
					print("  duel ", g, " errors: ", (r["errors"] as Array).slice(0, 6))
		print("%s vs %s: %s  (%d duels)" % [ka, kb, str(wins), n])
	print("TOTAL duels ", total, " with errors ", bad, " ms ", Time.get_ticks_msec() - t0)
	var ek := all_errors.keys()
	ek.sort_custom(func(x, y): return int(all_errors[x]) > int(all_errors[y]))
	for k in ek.slice(0, 40):
		print("  x", all_errors[k], "  ", k)
	get_tree().quit(0)


var _native_level := 0


func _names(cards: Array) -> String:
	var out: Array = []
	for c in cards:
		out.append("%s%s" % [c.cname().left(18), "" if c.face_up else "(fd)"])
	return str(out)


## Card numbers in the search notes become names.
func _pretty(notes: String) -> String:
	var rx := RegEx.new()
	rx.compile("([a-z]+)(\\d{4,9})@")
	var out := notes
	for m in rx.search_all(notes):
		out = out.replace(m.get_string(0), m.get_string(1) + ":" + str(CardData.get_card(int(m.get_string(2))).get("name", "?")).left(16) + "@")
	return out


func one(ka: String, kb: String, seed: int, verbose: bool) -> Dictionary:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("-L"):
			_native_level = int(a.substr(2))
	var st := OcgMirror.new()
	var d := OcgDuel.new()
	d.log_msgs = verbose and "-m" in OS.get_cmdline_user_args()
	var decks := [CardData.deck_list(ka), CardData.deck_list(kb)]
	var extras := [CardData.extra_list(ka), CardData.extra_list(kb)]
	if ka == "lumen_test":
		# Your partner and her cards, with plain monsters around them.
		CardData.lumen_tuner_test = true
		var l: Array[int] = []
		for pair in [[99200001, 3], [99200005, 2], [99200011, 3], [99200012, 3], [99200013, 3]]:
			for i in int(pair[1]):
				l.append(int(pair[0]))
		for id in CardData.deck_list("deck_gem_knight"):
			if l.size() < 40 and CardData.get_card(id)["kind"] == "monster" and int(CardData.get_card(id).get("level", 9)) <= 4:
				l.append(id)
		for id in CardData.deck_list("deck_monarchs"):
			if l.size() < 40 and CardData.get_card(id)["kind"] == "monster" and int(CardData.get_card(id).get("level", 9)) <= 4:
				l.append(id)
		decks[0] = l
		var ex: Array[int] = [99200002, 99200003, 99200003, 99200004, 99200004]
		extras[0] = ex
	if not d.setup(st, decks, extras, ["A", "B"], seed % 2, [8000, 8000], [5, 5], seed):
		return {"winner": 2, "errors": ["setup failed"]}
	var cpus := [OcgCpu.new(), OcgCpu.new()]
	cpus[0].rng.seed = seed
	cpus[1].rng.seed = seed + 7
	var guard := 0
	var last_retries := 0
	while not d.over and guard < 6000:
		guard += 1
		d.advance()
		if d.over or d.request == null:
			break
		var p := int(d.request["p"])
		var safe := d.retries > last_retries
		if d.retries > last_retries + 2:
			d.errors.append("gave up after refused answers")
			break
		if not safe:
			last_retries = d.retries
		elif d.retries > last_retries:
			pass
		if _native_level > 0 and p == 0 and not safe:
			var th := OcgCore.think(d.handle, _native_level, 0, seed + guard)
			if verbose and int(th["cands"]) > 1 and int(d.request["t"]) in [10, 11, 15, 16]:
				var lg := OcgCore.logs(d.handle)
				print("T", st.turn, " ask ", int(d.request["t"]), " LP ", st.players[0].lp, "/", st.players[1].lp, " mine ", _names(st.players[0].monsters()), " theirs ", _names(st.players[1].monsters()), " hand ", _names(st.players[0].hand))
				for l in lg["logs"]:
					if str(l).begins_with("9:"):
						print("    ", _pretty(str(l).substr(2)))
			d.answer(th["answer"])
		else:
			d.answer(cpus[p].decide(d, safe))
		if st.turn > 80:
			break
	if ka == "lumen_test":
		var seen := {}
		for c in st.players[0].gy + st.players[0].banished + st.players[0].monsters() + st.players[0].hand:
			if c.id >= 99200000:
				seen[c.cname()] = int(seen.get(c.cname(), 0)) + 1
		print("  lumen cards that got out: ", seen)
	if "-t" in OS.get_cmdline_user_args():
		var hb := PackedByteArray()
		hb.resize(8)
		hb.encode_u32(0, d.handle)
		hb.encode_u32(4, 20)
		var tr := OcgCore.op(34, hb)
		print("  timing: new duel ", tr.decode_u32(0), " us, replay of ", tr.decode_u32(8), " answers ", tr.decode_u32(4), " us")
	var w: int = st.winner if st.winner in [0, 1] else 2
	if guard >= 6000:
		d.errors.append("too many steps")
	var errs := d.errors.duplicate()
	if verbose:
		print("winner ", w, " turns ", st.turn, " steps ", guard, " why ", st.win_reason)
	d.close()
	return {"winner": w, "errors": errs}
