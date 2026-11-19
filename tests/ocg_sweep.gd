extends Node
## Dev: the sweep. Every deck the game has, then decks dealt from the whole card pool (leaning
## toward cards that have not been played yet), played out by the basic opponent on both sides.
## What it reports: how many of the game's cards were summoned or had an effect go on the chain
## at least once (being Set is not enough, except for a Normal Monster), which never were, and
## everything the card scripts complained about.
##   godot --headless res://tests/ocg_sweep.tscn -- <rounds of pool decks> [seed] [out file] [family key]
## With a family key the sweep is about that family only: its deck against the others, decks
## dealt from its cards, and what is left of it set up on the table.
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var rounds := int(args[0]) if args.size() > 0 else 400
	var seed0 := int(args[1]) if args.size() > 1 else 1
	var out_path := str(args[2]) if args.size() > 2 else "/tmp/sweep.txt"
	var focus_key := str(args[3]) if args.size() > 3 else ""
	if not OcgCore.ensure_loaded():
		print("ENGINE NOT LOADED")
		get_tree().quit(1)
		return
	OcgCore.register_originals()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed0
	var mains: Array = []
	var extras: Array = []
	for id in Collection.all_cards():
		var cd: Dictionary = CardData.get_card(int(id))
		if cd.is_empty() or int(id) in CardData.SPEED_SPELLS:
			continue
		if str(cd.get("frame", "")) in ["fusion", "synchro", "xyz"]:
			extras.append(int(id))
		else:
			mains.append(int(id))
	var want_mains: Array = mains
	var want_extras: Array = extras
	var fill_mains: Array = mains
	var focus_deck := ""
	if focus_key == "singles":
		# (the single cards of data/singles.json, card plan parts 4 and 5, in decks filled from the whole pool)
		var ids := {}
		var more := CardPool.singles()
		for e in more:
			for nm in more[e]:
				ids[int(CardData.NAME_TO_ID.get(str(nm).to_lower(), 0))] = true
		want_mains = mains.filter(func(id): return ids.has(id))
		want_extras = extras.filter(func(id): return ids.has(id))
		print("singles: ", want_mains.size(), " + ", want_extras.size(), " cards")
	elif focus_key == "added":
		# (the single cards named in CardPool.ADDED, in decks filled from the whole pool)
		var ids := {}
		for nm in CardPool.added_names():
			ids[int(CardData.NAME_TO_ID.get(str(nm).to_lower(), 0))] = true
		want_mains = mains.filter(func(id): return ids.has(id))
		want_extras = extras.filter(func(id): return ids.has(id))
		print("added singles: ", want_mains.size(), " + ", want_extras.size(), " cards")
	elif focus_key != "":
		var fam: Dictionary = Collection.FAMILIES[focus_key]
		var ids := {}
		for nm in fam["cards"]:
			ids[int(CardData.NAME_TO_ID.get(str(nm).to_lower(), 0))] = true
		want_mains = mains.filter(func(id): return ids.has(id))
		want_extras = extras.filter(func(id): return ids.has(id))
		focus_deck = str(fam["deck"])
		fill_mains = CardData.deck_list(focus_deck)
		print("family ", focus_key, ": ", want_mains.size(), " + ", want_extras.size(), " cards")
	var played := {}
	var errors := {}
	var n := {"duels": 0, "refused": 0}
	var t0 := Time.get_ticks_msec()
	var staged := {}        # put straight onto the table in a set-up position (phase 4)
	var staged_used := {}   # ... and it did something there
	var into: Array = [played]
	var note := func(r: Dictionary, tag: String):
		n["duels"] += 1
		n["refused"] += int(r.get("refused", 0))
		# A card counts when it was summoned or went on the chain. Merely being Set does not count,
		# except for a Normal Monster, which has nothing more to show.
		var did: Array = r.get("acted", [])
		for c in r.get("played", []):
			if did.has(c) or str(CardData.get_card(int(c)).get("frame", "")) == "normal":
				(into[0] as Dictionary)[int(c)] = true
		for l in r.get("logs", []):
			var k := str(l).left(150)
			if k.begins_with("9:"):
				continue
			if not errors.has(k):
				errors[k] = [0, tag]
			errors[k][0] += 1
	# 1. The game's own decks, each against the next, both ways.
	var keys: Array = (CardData.DECKS.keys() + CardData.NAMED_DECKS.keys()).filter(func(k): return CardData.deck_list(str(k)).size() >= 20)
	for ki in keys.size():
		var ka := str(keys[ki])
		var kb := str(keys[(ki + 1) % keys.size()])
		if focus_deck != "":
			if ka != focus_deck:
				continue
			kb = str(keys[(ki + 1 + int(seed0)) % keys.size()])
		for g in 6:
			for legend in 2:
				var plain := g % 2 == 1     # (the version a street duelist plays, not the owner's own)
				var da: Array = CardData.legend_deck(ka, plain) if legend == 1 else CardData.deck_list(ka, plain)
				var db: Array = CardData.legend_deck(kb, plain) if legend == 1 else CardData.deck_list(kb, plain)
				note.call(OcgCore.match_duel([da, db], [CardData.extra_list(ka, plain), CardData.extra_list(kb, plain)], [0, 0], seed0 + ki * 100 + g * 2 + legend, 0, 8000 if g < 3 else 16000, 50), ka)
	var pool_ids: Array = want_mains + want_extras
	var in_pool := func() -> int:
		var k := 0
		for id in pool_ids:
			if played.has(id):
				k += 1
		return k
	var after_decks: int = in_pool.call()
	var duels_decks: int = n["duels"]
	print("decks done: ", n["duels"], " duels, ", after_decks, " cards played, ms ", Time.get_ticks_msec() - t0)
	# 2. Decks dealt from the whole pool. Cards not played yet come first, three copies each.
	for r in rounds:
		var decks: Array = []
		var exs: Array = []
		for side in 2:
			var want: Array = want_mains.filter(func(id): return not played.has(id))
			var deck: Array = []
			_shuffle(want, rng)
			for id in want.slice(0, 10):
				for k in 3:
					deck.append(id)
			while deck.size() < 40:
				deck.append(fill_mains[rng.randi() % fill_mains.size()])
			var wx: Array = want_extras.filter(func(id): return not played.has(id))
			_shuffle(wx, rng)
			var ex: Array = wx.slice(0, 15)
			if focus_key != "":
				# (a family's own Extra Deck cards, never more than three of one)
				for id in want_extras:
					while ex.count(id) < 3 and ex.size() < 15:
						ex.append(id)
			while ex.size() < 15 and focus_key == "":
				ex.append(extras[rng.randi() % extras.size()])
			decks.append(deck)
			exs.append(ex)
		note.call(OcgCore.match_duel(decks, exs, [0, 0], seed0 * 1000 + r, 0, 16000, 60), "pool")
		if r % 200 == 199:
			print("pool round ", r + 1, ": ", played.size(), " cards played, ", errors.size(), " kinds of complaint, ms ", Time.get_ticks_msec() - t0)
	var after_pool: int = in_pool.call()
	var duels_pool: int = n["duels"] - duels_decks
	# 3. Cards that need their own deck around them: a Fusion Monster with its materials and
	# Polymerization, a Ritual Monster with every Ritual Spell the game has.
	var poly := int(CardData.NAME_TO_ID.get("polymerization", 0))
	var ritual_spells: Array = mains.filter(func(id): return str(CardData.get_card(id).get("st", "")) == "ritual")
	var fodder: Array = mains.filter(func(id):
		var cd: Dictionary = CardData.get_card(id)
		return str(cd.get("frame", "")) == "normal" and int(cd.get("level", 9)) <= 4 and int(cd.get("atk", 0)) >= 1500)
	for id in want_extras + want_mains:
		if played.has(id):
			continue
		var cd: Dictionary = CardData.get_card(id)
		var deck: Array = []
		var ex: Array = []
		if str(cd.get("frame", "")) == "fusion" and poly > 0:
			for k in 3:
				deck.append(poly)
			for m in CardData.fusion_materials(cd):
				if int(m) > 0:
					for k in 3:
						deck.append(int(m))
			ex = [id, id, id]
		elif str(cd.get("frame", "")) == "ritual":
			for k in 3:
				deck.append(id)
			for rs in ritual_spells:
				deck.append(rs)
				deck.append(rs)
		else:
			continue
		while deck.size() < 40:
			deck.append(fodder[rng.randi() % fodder.size()])
		var other: Array = []
		while other.size() < 40:
			other.append(fodder[rng.randi() % fodder.size()])
		for g in 6:
			note.call(OcgCore.match_duel([deck, other], [ex, []], [0, 0], seed0 * 77 + id % 1000 + g, 0, 16000, 40), "built")
			if played.has(id):
				break
	var after_built: int = in_pool.call()
	var duels_built: int = n["duels"] - duels_decks - duels_pool
	var duels_full: int = n["duels"]
	print("built decks done: ", after_built, " cards played, ms ", Time.get_ticks_msec() - t0)
	# 4. What is left gets put straight onto the table in a set-up position, a few times, and the
	# duel is played on from there. This checks that the card stands on the table and its effects
	# run without a complaint; it does not check the usual way the card gets there.
	into[0] = staged_used
	# (cards its script names, and cards whose scripts name it, go on the table with it: /tmp/refs.json, made from the script files)
	var refs := {}
	var back := {}
	if FileAccess.file_exists("/tmp/refs.json"):
		var rj = JSON.parse_string(FileAccess.get_file_as_string("/tmp/refs.json"))
		if rj is Dictionary:
			refs = rj.get("refs", {})
			back = rj.get("back", {})
	var some: Array = mains.filter(func(id): return str(CardData.get_card(id).get("kind", "")) == "monster")
	var backs: Array = mains.filter(func(id): return str(CardData.get_card(id).get("kind", "")) in ["spell", "trap"] and str(CardData.get_card(id).get("st", "")) in ["normal", "quick", ""])
	for id in want_mains + want_extras:
		if played.has(id) or (OS.get_environment("SWEEP_ONLY") != "" and str(id) != OS.get_environment("SWEEP_ONLY")):
			continue
		var cd: Dictionary = CardData.get_card(id)
		staged[id] = true
		var friends: Array = []
		for fid in (refs.get(str(id), []) as Array) + (back.get(str(id), []) as Array):
			if not friends.has(int(fid)):
				friends.append(int(fid))
		var frame := str(cd.get("frame", ""))
		for g in 8:
			var cards: Array = []
			var grng := RandomNumberGenerator.new()
			grng.seed = id * 31 + g
			# An Extra Deck monster, second half: what it is made from is put in reach (Polymerization
			# and its materials in the hand; monsters of the right Levels on the field), so the way it
			# normally arrives gets played, not only the monster standing there.
			var mats: Array = _materials(id, cd, mains, grng, poly) if g >= 4 and frame in ["fusion", "synchro", "xyz"] else []
			for side in 2:
				for k in 24:
					cards.append([side, some[grng.randi() % some.size()], 0x01, 0, 0x8])
				for k in 3:
					cards.append([side, mains[grng.randi() % mains.size()], 0x02, 0, 0x8])
				for k in 3:
					cards.append([side, some[grng.randi() % some.size()], 0x10, 0, 0x1])
				# (a Set card or two in each back row, so cards that answer or destroy one have something there)
				for k in 2:
					cards.append([side, backs[grng.randi() % backs.size()], 0x08, 3 + k, 0xa])
				if side == 0 and not mats.is_empty():
					var mz := 0
					for mt in mats:
						if frame == "fusion" and (g < 6 or int(mt) == poly):
							cards.append([0, int(mt), 0x02, 0, 0x8])
						elif mz <= 2:
							cards.append([0, int(mt), 0x04, mz, 0x1])
							mz += 1
					continue
				cards.append([side, fodder[grng.randi() % fodder.size()], 0x04, 1, 0x1])
				cards.append([side, some[grng.randi() % some.size()], 0x04, 2, 0x1 if side == 0 else 0x4])
			# Its friends: on the field, in the hand, in the Graveyard and on top of the Deck, turn about.
			var zone := 3
			for fi in friends.size():
				var fid: int = friends[fi]
				var fk := str(CardData.get_card(fid).get("kind", "monster"))
				var extra_deck := str(CardData.get_card(fid).get("frame", "")) in ["fusion", "synchro", "xyz"]
				var where := (fi + g) % 4
				if fk == "monster" and where == 0 and zone <= 4:
					cards.append([0, fid, 0x04, zone, 0x1])
					zone += 1
				elif where == 2 and not extra_deck:
					cards.append([0, fid, 0x10, 0, 0x1])
				elif extra_deck:
					cards.append([0, fid, 0x40, 0, 0x8])
				else:
					cards.append([0, fid, 0x02, 0, 0x8])
				if not extra_deck and g % 2 == 1:
					cards.append([0, fid, 0x01, 0, 0x8])
			var is_extra := str(cd.get("frame", "")) in ["fusion", "synchro", "xyz"]
			if g >= 4 and (not friends.is_empty() or not mats.is_empty()):
				# The second half: the card is not on the table yet. It is where it would come from.
				if is_extra:
					cards.append([0, id, 0x40, 0, 0x8])
				else:
					cards.append([0, id, 0x02, 0, 0x8])
					cards.append([0, id, 0x01, 0, 0x8])
					if str(cd.get("kind", "")) == "trap":
						cards.append([0, id, 0x08, 0, 0x8])
			elif str(cd.get("kind", "")) == "monster":
				cards.append([0, id, 0x04, 0, 0x1])
				if g >= 2:
					cards.append([0, id, 0x10, 0, 0x1])   # (and one in the Graveyard, for effects from there)
			elif str(cd.get("kind", "")) == "trap":
				cards.append([0, id, 0x08, 0, 0x8])
			else:
				cards.append([0, id, 0x02, 0, 0x8])
				cards.append([0, id, 0x02, 0, 0x8])
			if OS.get_environment("SWEEP_TRACE") != "":
				printerr("staging ", id, " ", g)
			note.call(_board(cards, seed0 + id + g, 8), "staged %d" % id)
	print("staged done: ", staged.size(), " staged, ", staged_used.size(), " did something, ms ", Time.get_ticks_msec() - t0)
	var total := want_mains.size() + want_extras.size()
	var never: Array = []
	var quiet: Array = []
	for id in want_mains + want_extras:
		if not played.has(id):
			if staged_used.has(id):
				pass
			else:
				quiet.append(id)
	var used_n := 0
	for id in staged:
		if staged_used.has(id):
			used_n += 1
	never = quiet
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_line("full duels %d (the game's decks %d, pool decks %d, decks built around a card %d)  set-up positions %d  cards in the pool %d  refused answers %d" % [duels_full, duels_decks, duels_pool, duels_built, n["duels"] - duels_full, total, n["refused"]])
	f.store_line("summoned or activated in a full duel %d (%.1f%%): after the game's own decks %d, after pool decks %d, after decks built around a card %d" % [after_built, 100.0 * float(after_built) / float(total), after_decks, after_pool, after_built])
	f.store_line("put on the table in a set-up position: %d, of which %d used an effect there and %d only stood there" % [staged.size(), used_n, quiet.size()])
	# The cards left over that have a hand-made position (tests/card_positions.json) are tried there.
	var pos_names := {}
	var pj = JSON.parse_string(FileAccess.get_file_as_string("res://tests/card_positions.json"))
	if pj is Array:
		for e in pj:
			if str(e.get("pass", "")) != "open":
				pos_names[str(e["card"]).to_lower()] = true
	var open_ones: Array = never.filter(func(id): return not pos_names.has(str(CardData.get_card(id).get("name", "")).to_lower()))
	f.store_line("of those %d, %d have a hand-made position and %d have none yet" % [never.size(), never.size() - open_ones.size(), open_ones.size()])
	never = open_ones
	var by := {}
	for id in never:
		var cd: Dictionary = CardData.get_card(id)
		var k := str(cd.get("frame", cd.get("kind", "?")))
		if not by.has(k):
			by[k] = []
		(by[k] as Array).append("%s (%d)" % [str(cd.get("name", "?")), id])
	for k in by:
		f.store_line("NO POSITION YET %s x%d: %s" % [k, (by[k] as Array).size(), ", ".join(PackedStringArray(by[k]))])
	var ek := errors.keys()
	ek.sort_custom(func(x, y): return int(errors[x][0]) > int(errors[y][0]))
	f.store_line("COMPLAINTS %d kinds" % ek.size())
	for k in ek:
		f.store_line("  x%d [%s] %s" % [int(errors[k][0]), str(errors[k][1]), k])
	f.close()
	print("SWEEP DONE: duels ", n["duels"], " played ", after_built, " of ", total, " staged ", staged.size(), " (used ", used_n, ") complaints ", ek.size(), " ms ", Time.get_ticks_msec() - t0, " -> ", out_path)
	get_tree().quit(0)


## What an Extra Deck monster is made from, as well as the card data can tell: a Fusion's listed
## materials and Polymerization; for a Synchro, a Tuner and a non-Tuner whose Levels add up; for an
## Xyz, three monsters of its Rank. Cards of the monster's own family come first.
func _materials(id: int, cd: Dictionary, mains: Array, rng: RandomNumberGenerator, poly: int) -> Array:
	var frame := str(cd.get("frame", ""))
	var out: Array = []
	if frame == "fusion":
		if poly > 0:
			out.append(poly)
			out.append(poly)
		for m in CardData.fusion_materials(cd):
			if int(m) > 0:
				out.append(int(m))
	var kin := {}
	for fk in Collection.FAMILIES:
		var names: Array = Collection.FAMILIES[fk]["cards"]
		if names.has(str(cd.get("name", ""))):
			for nm in names:
				kin[int(CardData.NAME_TO_ID.get(str(nm).to_lower(), 0))] = true
	if frame == "fusion":
		# ("2 monsters of the family" names nobody: a few of its own Main Deck monsters stand in)
		var fam_mons: Array = mains.filter(func(mid): return kin.has(mid) and str(CardData.get_card(mid).get("kind", "")) == "monster")
		while out.size() < 6 and not fam_mons.is_empty():
			out.append(fam_mons.pop_at(rng.randi() % fam_mons.size()))
		return out
	var lv := int(cd.get("level", 0))
	var pick := func(level: int, tuner: bool, n: int) -> Array:
		var own: Array = []
		var any: Array = []
		for mid in mains:
			var md: Dictionary = CardData.get_card(mid)
			if str(md.get("kind", "")) != "monster" or int(md.get("level", 0)) != level or bool(md.get("tuner", false)) != tuner:
				continue
			if str(md.get("frame", "")) == "ritual":
				continue
			(own if kin.has(mid) else any).append(mid)
		var got: Array = []
		while got.size() < n and not (own.is_empty() and any.is_empty()):
			var src: Array = own if not own.is_empty() else any
			got.append(src[rng.randi() % src.size()])
			if own.size() <= 1 and src == own:
				own = []
		return got
	if frame == "xyz":
		return pick.call(lv, false, 3) if rng.randi() % 2 == 0 else pick.call(lv, false, 2)
	if frame == "synchro":
		for t in [1, 2, 3, 4, 5].filter(func(x): return x < lv):
			var tl: int = [3, 2, 1, 4, 5][rng.randi() % 5] if t == 1 else t
			if tl >= lv:
				continue
			var tu: Array = pick.call(tl, true, 1)
			var nt: Array = pick.call(lv - tl, false, 1)
			if not tu.is_empty() and not nt.is_empty():
				return tu + nt
	return out


## A set position played on from there by the basic opponent on both sides (see ocg_boards).
func _board(cards: Array, seed: int, turns: int) -> Dictionary:
	var buf := StreamPeerBuffer.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in 4:
		buf.put_u64(rng.randi() | (rng.randi() << 32))
	buf.put_u64(OcgCore.DUEL_FLAGS | OcgCore.ATTACK_FIRST_TURN)
	buf.put_u32(8000)
	buf.put_u32(8000)
	buf.put_u32(0)
	buf.put_u32(0)
	buf.put_u32(0)
	buf.put_u32(turns)
	buf.put_u64(seed)
	buf.put_u32(cards.size())
	for c in cards:
		buf.put_u8(int(c[0]))
		buf.put_u32(int(c[1]))
		buf.put_u32(int(c[2]))
		buf.put_u32(int(c[3]))
		buf.put_u32(int(c[4]))
	var v = bytes_to_var(OcgCore.op(35, buf.data_array))
	return v if v is Dictionary else {}


func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var t = a[i]
		a[i] = a[j]
		a[j] = t
