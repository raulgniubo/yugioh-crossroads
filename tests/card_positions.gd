extends Node
## Dev: hand-made positions for single cards that random duels never get to play. Each entry of
## tests/card_positions.json puts a card where its effect can be used (the right monsters around
## it, the right cards in the Graveyard) and plays on from there with the basic opponent on both
## sides. The card passes when it was summoned or activated (not merely Set) without a script complaint.
##   godot --headless res://tests/card_positions.tscn [-- <part of a card name>]
const FILL := "Mystical Elf"

func _id(n: String) -> int:
	var id := int(CardData.NAME_TO_ID.get(n.to_lower(), 0))
	if id == 0:
		# (the cards of this game are in no card database: look for the name among them)
		for oid in CardData.ORIGINALS:
			if str(CardData.CARDS[oid].get("name", "")).to_lower() == n.to_lower():
				return int(oid)
	return id


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not OcgCore.ensure_loaded():
		print("ENGINE NOT LOADED")
		get_tree().quit(1)
		return
	OcgCore.register_originals()
	var list = JSON.parse_string(FileAccess.get_file_as_string("res://tests/card_positions.json"))
	var bad := 0
	var n := 0
	var open_n := 0
	var never_n := 0
	for e in list:
		var name := str(e["card"])
		if args.size() > 0 and not str(args[0]).to_lower() in name.to_lower():
			continue
		n += 1
		var cid := _id(name)
		if str(e.get("pass", "")) == "open":
			# (no working position yet: listed so it is not forgotten, never counted as checked)
			print("open    ", name, ": ", str(e.get("why", "")))
			open_n += 1
			continue
		if str(e.get("pass", "")) == "never":
			# (a card the rules of this game can never let you use; the reason is written with it)
			print("never   ", name, ": ", str(e.get("why", "")))
			never_n += 1
			continue
		if cid == 0:
			print("?? unknown card ", name)
			bad += 1
			continue
		var seen := false
		var logs := {}
		var unknown: Array = []
		for seed in 6:
			var cards: Array = []
			for side in 2:
				var d: Dictionary = e.get("me" if side == 0 else "opp", {})
				for k in 14:
					cards.append([side, _id(FILL), 0x01, 0, 0x8])
				for x in d.get("deck", []):
					cards.append([side, _need(str(x), unknown), 0x01, 0, 0x8])
				for x in d.get("hand", []):
					cards.append([side, _need(str(x), unknown), 0x02, 0, 0x8])
				for x in d.get("gy", []):
					cards.append([side, _need(str(x), unknown), 0x10, 0, 0x1])
				for x in d.get("rm", []):
					cards.append([side, _need(str(x), unknown), 0x20, 0, 0x1])
				for x in d.get("extra", []):
					cards.append([side, _need(str(x), unknown), 0x40, 0, 0x8])
				var z := 0
				for x in d.get("m", []):
					var how := str(x[1]) if x is Array else "atk"
					cards.append([side, _need(str(x[0]) if x is Array else str(x), unknown), 0x04, z, 0x1 if how == "atk" else (0x4 if how == "def" else 0x8)])
					z += 1
				z = 0
				for x in d.get("st", []):
					cards.append([side, _need(str(x), unknown), 0x08, z, 0xa])
					z += 1
				for x in d.get("up", []):
					cards.append([side, _need(str(x), unknown), 0x08, z, 0x1])
					z += 1
				for x in d.get("fieldspell", []):
					cards.append([side, _need(str(x), unknown), 0x08, 5, 0x1])
			var r := _board(cards, 77 + seed * 13 + cid % 1000, int(e.get("turns", 3)), [int((e.get("me", {}) as Dictionary).get("lp", 8000)), int((e.get("opp", {}) as Dictionary).get("lp", 8000))])
			if "-v" in args:
				print("  seed ", seed, ": turns ", r.get("turns"), " lp ", r.get("lp"), " hand ", r.get("hand"), " gy ", r.get("gy"), " st ", r.get("st"), " mons ", (r.get("mons", []) as Array).map(func(row): return (row as Array).map(func(c): return OcgCore.card_name(int(c["code"])))), " acted ", (r.get("acted", []) as Array).map(func(c): return OcgCore.card_name(int(c))))
			# "pass": "placed" = another card's effect puts it on the table (it never activates itself).
			# "pass": "stands" = its effect is always on: it stands face-up through the turns without a complaint.
			var how := str(e.get("pass", ""))
			if cid in (r.get("acted", []) as Array) or (how == "placed" and cid in (r.get("played", []) as Array)) or how == "stands":
				seen = true
			for l in r.get("logs", []):
				if not str(l).begins_with("9:"):
					logs[str(l).left(160)] = true
			if seen and logs.is_empty():
				break
		if not unknown.is_empty():
			print("?? ", name, ": not in the game: ", unknown)
			bad += 1
		elif not seen or not logs.is_empty():
			bad += 1
			print("NOT OK  ", name, "  played ", seen, "  ", logs.keys())
		else:
			print("ok      ", name)
	print("CARD POSITIONS: ", n - bad - open_n - never_n, " pass, ", bad, " not ok, ", open_n, " with no working position yet, ", never_n, " that this game's rules never let you use")
	get_tree().quit(0)


func _need(n: String, unknown: Array) -> int:
	var id := _id(n)
	if id == 0 and not unknown.has(n):
		unknown.append(n)
	return id


func _board(cards: Array, seed: int, turns: int, lp: Array) -> Dictionary:
	var buf := StreamPeerBuffer.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in 4:
		buf.put_u64(rng.randi() | (rng.randi() << 32))
	buf.put_u64(OcgCore.DUEL_FLAGS | OcgCore.ATTACK_FIRST_TURN)
	buf.put_u32(int(lp[0]))
	buf.put_u32(int(lp[1]))
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
