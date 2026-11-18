extends Node
## Dev: placeholder CPU against placeholder CPU on the new engine, no screen.
##   godot --headless -s tests/ocg_sim.gd -- <deck a|all> <deck b> <duels> [seed] [-v] [-L<level>: deck a thinks in the engine; -B: deck b too]
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var a := str(args[0]) if args.size() > 0 else "deck_monarchs"
	var b := str(args[1]) if args.size() > 1 else "deck_gem_knight"
	var n := int(args[2]) if args.size() > 2 else 3
	var seed0 := int(args[3]) if args.size() > 3 else 1
	var verbose := "-v" in args
	if a == "deck":
		# (dev: the list a deck is really dealt, after SignatureDecks has had its say)
		for key in (Characters.ORDER if b == "all" else [b]):
			var dk := str(Characters.get_char(str(key)).get("deck", key)) if b == "all" else str(key)
			var cnt := {}
			for id in CardData.deck_list(dk):
				var nm := str(CardData.get_card(int(id)).get("name", "?"))
				cnt[nm] = int(cnt.get(nm, 0)) + 1
			var cx := {}
			for id in CardData.extra_list(dk):
				var nm2 := str(CardData.get_card(int(id)).get("name", "?"))
				cx[nm2] = int(cx.get(nm2, 0)) + 1
			print("DECK ", dk, " ", JSON.stringify({"main": cnt, "extra": cx}))
		get_tree().quit()
		return
	if a == "ids":
		# Dev: every card id the game can put in a duel, for tools/make_ocg_data.py.
		var ids := {}
		for id in Collection.all_cards():
			ids[int(id)] = true
		for id in CardData.ORIGINALS:
			ids[int(id)] = true
		for k in CardData.DECKS.keys() + CardData.NAMED_DECKS.keys():
			for id in CardData.deck_list(str(k)) + CardData.extra_list(str(k)) + CardData.legend_deck(str(k)) + CardData.deck_list(str(k), true) + CardData.extra_list(str(k), true) + CardData.legend_deck(str(k), true):
				ids[int(id)] = true
		# (what a Fusion Monster is made of, even when that card is not in the game yet: its script is there if it ever is)
		for id in ids.keys():
			for m in CardData.fusion_materials(CardData.get_card(int(id))):
				if int(m) > 0:
					ids[int(m)] = true
		for pz in Puzzles.LIST:
			for nm in Puzzles.names(pz):
				ids[Puzzles._id(str(nm))] = true
		# (every name the game adds on top of the written-down pool, whether or not anything else lists it yet)
		for nm in CardPool.added_names():
			var aid := int(CardData.NAME_TO_ID.get(str(nm).to_lower(), 0))
			if aid != 0:
				ids[aid] = true
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
	if a == "card":
		# Dev: one card, three copies of it in a deck, a few duels by the basic opponent.
		#   -- card <card id> <deck key> [duels]     (to find the card behind a hang or a complaint)
		var cid := int(b)
		var key := str(args[2]) if args.size() > 2 else "deck_monarchs"
		var deck: Array = CardData.deck_list(key)
		var ex: Array = CardData.extra_list(key)
		if str(CardData.get_card(cid).get("frame", "")) in ["fusion", "synchro", "xyz"]:
			ex = [cid, cid, cid] + ex.slice(0, 12)
		else:
			deck = [cid, cid, cid] + deck.slice(3)
		var errs := {}
		var seen := false
		var games := int(args[3]) if args.size() > 3 else 6
		for g in games:
			var r: Dictionary = OcgCore.match_duel([deck, CardData.deck_list(key)], [ex, CardData.extra_list(key)], [0, 0], 500 + g, 0, 16000, 50)
			seen = seen or (cid in (r.get("played", []) as Array))
			for l in r.get("logs", []):
				if not str(l).begins_with("9:"):
					errs[str(l).left(140)] = true
		print("card ", cid, " ", str(CardData.get_card(cid).get("name", "?")), ": played ", seen, " complaints ", errs.keys())
		get_tree().quit(0)
		return
	if a == "freeze":
		# Dev: the card pool as the game works it out today, written down (data/pool.json is made from this).
		var out := {}
		for era in Collection.SERIES:
			var l: Array = []
			for id in Collection.pool(str(era)):
				l.append(int(id))
			l.sort()
			out[str(era)] = l
		var all: Array = []
		for id in Collection.all_cards():
			all.append(int(id))
		all.sort()
		out["all"] = all
		var every: Array = []
		for id in Collection.every_playable():
			every.append(int(id))
		every.sort()
		out["every_playable"] = every
		var lost: Array = []
		for fk in Collection.FAMILIES:
			for nm in Collection.FAMILIES[fk]["cards"]:
				var fid := int(CardData.NAME_TO_ID.get(str(nm).to_lower(), 0))
				if fid == 0 or not all.has(fid):
					lost.append("%s: %s (%d)" % [fk, nm, fid])
		out["family_names_not_in_pool"] = lost
		var f2 := FileAccess.open(b, FileAccess.WRITE)
		f2.store_string(JSON.stringify(out))
		f2.close()
		print("freeze: all ", all.size(), " every_playable ", every.size(), " family names not in pool ", lost.size(), " -> ", b)
		for l in lost:
			print("   ", l)
		get_tree().quit(0)
		return
	if a == "gaps":
		# Dev: Fusion Monsters in the game whose listed materials are not in the game.
		var pool := {}
		for id in Collection.all_cards():
			pool[int(id)] = true
		for id in pool.keys():
			var cd: Dictionary = CardData.get_card(int(id))
			var lacking: Array = []
			for m in CardData.fusion_materials(cd):
				if int(m) > 0 and not pool.has(int(m)):
					lacking.append("%s (%d)" % [OcgCore.card_name(int(m)) if OcgCore.ensure_loaded() else "?", int(m)])
			if not lacking.is_empty():
				print("GAP ", cd.get("name", "?"), " (", id, ") needs ", lacking)
		get_tree().quit(0)
		return
	if a == "puzzles":
		# Dev: every puzzle, laid out as the duel screen lays it out, with the thinking opponent in your seat.
		var solved := 0
		for pz in Puzzles.LIST:
			if b != "x" and str(pz["id"]) != b:
				continue
			var best := false
			for attempt in maxi(1, n):
				if puzzle(pz, seed0 + attempt, verbose):
					best = true
					break
			var how := "by the Extreme CPU"
			if not best:
				# Not found by the CPU: is there a line at all? Random legal play, many times.
				for attempt in 1500:
					if puzzle(pz, seed0 + attempt, false, true):
						best = true
						how = "by random play, try %d (the CPU missed it)" % attempt
						break
			print("PUZZLE ", pz["id"], ": ", ("solved " + how) if best else "NOT SOLVED")
			solved += int(best)
		print("PUZZLES solved ", solved, " of ", Puzzles.LIST.size())
		get_tree().quit(0)
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
	# (The CPU plays both sides here, so both get the list the CPU is given; HUMAN_LISTS=1 for the player's.)
	SignatureDecks.cpu = OS.get_environment("HUMAN_LISTS") == ""
	var decks := [CardData.deck_list(ka), CardData.deck_list(kb)]
	var extras := [CardData.extra_list(ka), CardData.extra_list(kb)]
	SignatureDecks.cpu = false
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
	var args := OS.get_cmdline_user_args()
	var turbo := "-T" in args
	var fate := "-D" in args
	if turbo:
		for side in 2:
			var l2: Array[int] = []
			l2.append_array(decks[side])
			for id in [CardData.SPEED_SPELLS[0], CardData.SPEED_SPELLS[0], CardData.SPEED_SPELLS[1]] + CardData.SPEED_SPELLS.slice(2 + (seed + side) % 4).slice(0, 4):
				l2.append(int(id))
			decks[side] = l2
	d.prepare(st, decks, extras, ["A", "B"], seed % 2, seed, {"turbo": turbo})
	var lp0 := 4000 if fate else 8000
	if not OcgCore.ensure_loaded() or not d.start([lp0, lp0], [5, 5], {"speed": [seed % 3, 0], "destiny": [fate, fate]}):
		return {"winner": 2, "errors": ["setup failed"]}
	var seen_fx := {}
	var fate_next := false
	var fate_want := 0
	var top_speed := [0, 0]
	var cpus := [OcgCpu.new(), OcgCpu.new()]
	cpus[0].rng.seed = seed
	cpus[1].rng.seed = seed + 7
	var log_ev := OS.get_environment("DUEL_LOG") != ""
	var guard := 0
	var last_retries := 0
	while not d.over and guard < 6000:
		guard += 1
		for e in d.advance():
			if log_ev and (e["type"] in ["summon", "special", "set", "activate", "effect", "attack", "lp", "turn", "destroy"] or OS.get_environment("DUEL_LOG") == "all"):
				# (dev: DUEL_LOG=1 prints what each side did, to see how the CPU plays a deck)
				print("  T", st.turn, " p", e.get("player", "?"), " ", e["type"], " ", str(e["text"]) if e.has("text") else str(e["card"].cname() if e.get("card") != null else ""), " ", e.get("amount", ""))
			if e["type"] in ["effect", "activate"]:
				var nm := str(e["text"]) if e.has("text") else str(e["card"].cname() if e.get("card") != null else "?")
				if nm.begins_with("Speed "):
					seen_fx[nm.left(40)] = int(seen_fx.get(nm.left(40), 0)) + 1
			elif e["type"] == "draw" and fate_want > 0:
				seen_fx["destiny " + ("hit" if int(e["card"].id) == fate_want else "MISS")] = int(seen_fx.get("destiny " + ("hit" if int(e["card"].id) == fate_want else "MISS"), 0)) + 1
				fate_want = 0
			elif e["type"] == "speed":
				top_speed[int(e["player"])] = maxi(int(top_speed[int(e["player"])]), int(e["speed"]))
		if fate and d.request != null and int(d.request["t"]) == 13 and int(d.request["desc"]) == (OcgCore.DESTINY << 20):
			seen_fx["destiny offer"] = int(seen_fx.get("destiny offer", 0)) + 1
			fate_next = true
		elif fate_next and d.request != null and int(d.request["t"]) == 15:
			fate_next = false
			var pickd: PackedByteArray = cpus[int(d.request["p"])].decide(d, false)
			fate_want = int(d.request["cards"][pickd.decode_s32(8)]["code"])
			d.answer(pickd)
			continue
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
		if _native_level > 0 and (p == 0 or "-B" in OS.get_cmdline_user_args()) and not safe:
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
	if turbo or fate:
		print("  top speed ", top_speed, " seen ", seen_fx, " turns ", st.turn, " errors ", d.errors.size())
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


## A random legal answer to the questions a puzzle turn asks (it keeps playing while it can).
func _random_answer(d: OcgDuel, rng: RandomNumberGenerator, cpu: OcgCpu) -> PackedByteArray:
	var m: Dictionary = d.request
	match int(m["t"]):
		11:
			var opts: Array = []
			for pair in [["summon", 0], ["spsummon", 1], ["repos", 2], ["sset", 4], ["chains", 5]]:
				for i in (m[pair[0]] as Array).size():
					opts.append((i << 16) | int(pair[1]))
			if int(m["to_bp"]) != 0 and (opts.is_empty() or rng.randf() < 0.22):
				return OcgDuel.i32(6)
			if opts.is_empty():
				return OcgDuel.i32(7)
			return OcgDuel.i32(opts[rng.randi() % opts.size()])
		10:
			var o2: Array = []
			for i in (m["attacks"] as Array).size():
				o2.append((i << 16) | 1)
			for i in (m["chains"] as Array).size():
				o2.append(i << 16)
			if o2.is_empty():
				return OcgDuel.i32(3 if int(m["to_ep"]) != 0 else 2)
			return OcgDuel.i32(o2[rng.randi() % o2.size()])
		15:
			var n := (m["cards"] as Array).size()
			var lo := maxi(1, int(m["min"]))
			var idx: Array = range(n)
			for i in n:
				var j := rng.randi() % n
				var tmp = idx[i]
				idx[i] = idx[j]
				idx[j] = tmp
			return OcgDuel.pick(idx.slice(0, lo))
		16:
			var nc := (m["chains"] as Array).size()
			if nc == 0 or (int(m["forced"]) == 0 and rng.randf() < 0.5):
				return OcgDuel.i32(-1)
			return OcgDuel.i32(rng.randi() % nc)
		12, 13:
			return OcgDuel.i32(rng.randi() % 2)
	return cpu.decide(d, false)


func puzzle(pz: Dictionary, seed: int, verbose: bool, random := false) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 7919 + 13
	var st := OcgMirror.new()
	var d := OcgDuel.new()
	var lay := {"hand": [Puzzles.hand_ids(pz), []], "mons": [[], []], "gy": [[], []]}
	for side in 2:
		for pair in pz.get("mine" if side == 0 else "theirs", []):
			(lay["mons"][side] as Array).append([Puzzles._id(str(pair[0])), str(pair[1])])
		for nm in pz.get("my_gy" if side == 0 else "their_gy", []):
			(lay["gy"][side] as Array).append(Puzzles._id(str(nm)))
	var none: Array[int] = []
	d.prepare(st, [none, Puzzles.filler_ids()], [none, none], ["You", "Puzzle"], 0, seed, lay)
	if not d.start([int(pz.get("my_lp", 4000)), int(pz.get("opp_lp", 4000))], [0, 5], {"flags": OcgCore.ATTACK_FIRST_TURN}):
		print("  setup failed")
		return false
	var cpu := OcgCpu.new()
	var guard := 0
	while not d.over and guard < 400:
		guard += 1
		var evs := d.advance()
		if verbose:
			for e in evs:
				if e["type"] in ["summon", "special", "activate", "effect", "attack", "damage", "lp", "set"]:
					print("    ", e["type"], " ", e.get("text", e["card"].cname() if e.get("card") != null else ""), " ", e.get("amount", ""))
		if d.over or d.request == null or st.turn >= 2:
			break
		if int(d.request["p"]) == 0 and random:
			d.answer(_random_answer(d, rng, cpu))
		elif int(d.request["p"]) == 0:
			var th := OcgCore.think(d.handle, 3, 0, seed + guard)
			if verbose:
				print("    think ask ", int(d.request["t"]), " cands ", th.get("cands"), " sims ", th.get("sims"), " ms ", th.get("ms"))
			d.answer(th["answer"])
		else:
			d.answer(cpu.decide(d, false))
	var won: bool = st.winner == 0
	var real: Array = d.errors.filter(func(e): return not str(e).begins_with("script: 9:"))
	if not real.is_empty() and not random:
		print("  errors ", real.slice(0, 5))
	if verbose:
		print("  turn ", st.turn, " LP ", st.players[0].lp, "/", st.players[1].lp, " mine ", _names(st.players[0].monsters()), " theirs ", _names(st.players[1].monsters()), " hand ", _names(st.players[0].hand))
	d.close()
	return won
