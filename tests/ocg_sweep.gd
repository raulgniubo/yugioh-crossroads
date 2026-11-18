extends Node
## Dev: the sweep. Every deck the game has, then decks dealt from the whole card pool (leaning
## toward cards that have not been played yet), played out by the basic opponent on both sides.
## What it reports: how many of the game's cards were summoned or had an effect go on the chain
## at least once, which never were, and everything the card scripts complained about.
##   godot --headless res://tests/ocg_sweep.tscn -- <rounds of pool decks> [seed] [out file]
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var rounds := int(args[0]) if args.size() > 0 else 400
	var seed0 := int(args[1]) if args.size() > 1 else 1
	var out_path := str(args[2]) if args.size() > 2 else "/tmp/sweep.txt"
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
		for c in r.get("played", []):
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
		for g in 6:
			for legend in 2:
				var plain := g % 2 == 1     # (the version a street duelist plays, not the owner's own)
				var da: Array = CardData.legend_deck(ka, plain) if legend == 1 else CardData.deck_list(ka, plain)
				var db: Array = CardData.legend_deck(kb, plain) if legend == 1 else CardData.deck_list(kb, plain)
				note.call(OcgCore.match_duel([da, db], [CardData.extra_list(ka, plain), CardData.extra_list(kb, plain)], [0, 0], seed0 + ki * 100 + g * 2 + legend, 0, 8000 if g < 3 else 16000, 50), ka)
	var after_decks := played.size()
	print("decks done: ", n["duels"], " duels, ", after_decks, " cards played, ms ", Time.get_ticks_msec() - t0)
	# 2. Decks dealt from the whole pool. Cards not played yet come first, three copies each.
	for r in rounds:
		var decks: Array = []
		var exs: Array = []
		for side in 2:
			var want: Array = mains.filter(func(id): return not played.has(id))
			var deck: Array = []
			_shuffle(want, rng)
			for id in want.slice(0, 10):
				for k in 3:
					deck.append(id)
			while deck.size() < 40:
				deck.append(mains[rng.randi() % mains.size()])
			var wx: Array = extras.filter(func(id): return not played.has(id))
			_shuffle(wx, rng)
			var ex: Array = wx.slice(0, 15)
			while ex.size() < 15:
				ex.append(extras[rng.randi() % extras.size()])
			decks.append(deck)
			exs.append(ex)
		note.call(OcgCore.match_duel(decks, exs, [0, 0], seed0 * 1000 + r, 0, 16000, 60), "pool")
		if r % 200 == 199:
			print("pool round ", r + 1, ": ", played.size(), " cards played, ", errors.size(), " kinds of complaint, ms ", Time.get_ticks_msec() - t0)
	var after_pool := played.size()
	# 3. Cards that need their own deck around them: a Fusion Monster with its materials and
	# Polymerization, a Ritual Monster with every Ritual Spell the game has.
	var poly := int(CardData.NAME_TO_ID.get("polymerization", 0))
	var ritual_spells: Array = mains.filter(func(id): return str(CardData.get_card(id).get("st", "")) == "ritual")
	var fodder: Array = mains.filter(func(id):
		var cd: Dictionary = CardData.get_card(id)
		return str(cd.get("frame", "")) == "normal" and int(cd.get("level", 9)) <= 4 and int(cd.get("atk", 0)) >= 1500)
	for id in extras + mains:
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
	var after_built := played.size()
	print("built decks done: ", after_built, " cards played, ms ", Time.get_ticks_msec() - t0)
	# 4. What is left gets put straight onto the table in a set-up position, a few times, and the
	# duel is played on from there. This checks that the card stands on the table and its effects
	# run without a complaint; it does not check the usual way the card gets there.
	into[0] = staged_used
	var some: Array = mains.filter(func(id): return str(CardData.get_card(id).get("kind", "")) == "monster")
	for id in mains + extras:
		if played.has(id):
			continue
		var cd: Dictionary = CardData.get_card(id)
		staged[id] = true
		for g in 4:
			var cards: Array = []
			var grng := RandomNumberGenerator.new()
			grng.seed = id * 31 + g
			for side in 2:
				for k in 24:
					cards.append([side, some[grng.randi() % some.size()], 0x01, 0, 0x8])
				for k in 3:
					cards.append([side, mains[grng.randi() % mains.size()], 0x02, 0, 0x8])
				for k in 3:
					cards.append([side, some[grng.randi() % some.size()], 0x10, 0, 0x1])
				cards.append([side, fodder[grng.randi() % fodder.size()], 0x04, 1, 0x1])
				cards.append([side, some[grng.randi() % some.size()], 0x04, 2, 0x1 if side == 0 else 0x4])
			if str(cd.get("kind", "")) == "monster":
				cards.append([0, id, 0x04, 0, 0x1])
				if g >= 2:
					cards.append([0, id, 0x10, 0, 0x1])   # (and one in the Graveyard, for effects from there)
			elif str(cd.get("kind", "")) == "trap":
				cards.append([0, id, 0x08, 0, 0x8])
			else:
				cards.append([0, id, 0x02, 0, 0x8])
				cards.append([0, id, 0x02, 0, 0x8])
			note.call(_board(cards, seed0 + id + g, 8), "staged %d" % id)
	print("staged done: ", staged.size(), " staged, ", staged_used.size(), " did something, ms ", Time.get_ticks_msec() - t0)
	var total := mains.size() + extras.size()
	var never: Array = []
	var quiet: Array = []
	for id in mains + extras:
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
	f.store_line("duels %d  cards in the pool %d  refused answers %d" % [n["duels"], total, n["refused"]])
	f.store_line("played in a full duel %d (%.1f%%): after the game's own decks %d, after pool decks %d, after decks built around a card %d" % [played.size() if played.size() <= total else total, 100.0 * float(after_built) / float(total), after_decks, after_pool, after_built])
	f.store_line("put on the table in a set-up position: %d, of which %d used an effect there and %d only stood there" % [staged.size(), used_n, quiet.size()])
	var by := {}
	for id in never:
		var cd: Dictionary = CardData.get_card(id)
		var k := str(cd.get("frame", cd.get("kind", "?")))
		if not by.has(k):
			by[k] = []
		(by[k] as Array).append("%s (%d)" % [str(cd.get("name", "?")), id])
	for k in by:
		f.store_line("ONLY STOOD THERE %s x%d: %s" % [k, (by[k] as Array).size(), ", ".join(PackedStringArray(by[k]))])
	var ek := errors.keys()
	ek.sort_custom(func(x, y): return int(errors[x][0]) > int(errors[y][0]))
	f.store_line("COMPLAINTS %d kinds" % ek.size())
	for k in ek:
		f.store_line("  x%d [%s] %s" % [int(errors[k][0]), str(errors[k][1]), k])
	f.close()
	print("SWEEP DONE: duels ", n["duels"], " played ", after_built, " of ", total, " staged ", staged.size(), " (used ", used_n, ") complaints ", ek.size(), " ms ", Time.get_ticks_msec() - t0, " -> ", out_path)
	get_tree().quit(0)


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
