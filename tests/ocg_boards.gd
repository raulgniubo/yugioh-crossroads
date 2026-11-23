extends Node
## Dev: test boards for the thinking opponent. Each is a position where a careless player goes
## wrong (a missed win, an attack into a bigger monster, a wasted card). The opponent under test
## is side 0 and it is its turn; side 1 is the basic policy.
##   godot --headless res://tests/ocg_boards.tscn -- <level> [runs per board]
const F := "Mystical Elf"     # (the Decks are filler: nobody decks out)

var ids := {}


func b(name: String, me: Dictionary, opp: Dictionary, want: Callable, turns := 1) -> Dictionary:
	return {"name": name, "me": me, "opp": opp, "want": want, "turns": turns}


func boards() -> Array:
	var win := func(r): return int(r["winner"]) == 0
	return [
		b("Win: two attackers, open field", {"m": [["Vorse Raider", 1], ["Gemini Elf", 1]]}, {"lp": 3800}, win),
		b("Win: kill the blocker, then go in", {"m": [["Blue-Eyes White Dragon", 1], ["Vorse Raider", 1]]}, {"lp": 3500, "m": [["Celtic Guardian", 1]]}, win),
		b("Win: the right monster takes the blocker", {"m": [["Summoned Skull", 1], ["Celtic Guardian", 1]]}, {"lp": 2000, "m": [["Vorse Raider", 1]]}, win),
		b("Win: burn for exactly enough", {"hand": ["Ookazi"]}, {"lp": 800}, win),
		b("Win: burn plus an attack", {"m": [["Battle Ox", 1]], "hand": ["Hinotama"]}, {"lp": 2200}, win),
		b("Win: Raigeki clears the way", {"m": [["Vorse Raider", 1]], "hand": ["Raigeki"]}, {"lp": 1900, "m": [["Blue-Eyes White Dragon", 1]]}, win),
		b("Win: equip to reach it", {"m": [["Battle Ox", 1]], "hand": ["Axe of Despair"]}, {"lp": 2700}, win),
		b("Win: summon, then both attack", {"m": [["Battle Ox", 1]], "hand": ["Vorse Raider"]}, {"lp": 3600}, win),
		b("Win: Tribute for the finisher", {"m": [["Kuriboh", 1]], "hand": ["Summoned Skull"]}, {"lp": 2500}, win),
		b("Win: take their monster and swing", {"m": [["Vorse Raider", 1]], "hand": ["Change of Heart"]}, {"lp": 4900, "m": [["Blue-Eyes White Dragon", 1]]}, win),
		b("Win: Monster Reborn for the last points", {"m": [["Battle Ox", 1]], "hand": ["Monster Reborn"], "gy": ["Summoned Skull"]}, {"lp": 4200}, win),
		b("Win: through a Defense wall", {"m": [["Blue-Eyes White Dragon", 1], ["Battle Ox", 1]]}, {"lp": 1700, "m": [["Giant Soldier of Stone", 4]]}, win),
		b("Win: Brain Control for the last points", {"m": [["Vorse Raider", 1]], "hand": ["Brain Control"]}, {"lp": 4400, "m": [["Summoned Skull", 1]]}, win),
		b("Safe: no attack into a bigger monster", {"m": [["Battle Ox", 1]]}, {"m": [["Vorse Raider", 1]]},
			func(r): return int(r["lp"][0]) == 8000 and (r["mons"][0] as Array).size() == 1),
		b("Safe: no attack into a higher DEF", {"m": [["La Jinn the Mystical Genie of the Lamp", 1]]}, {"m": [["Giant Soldier of Stone", 4]]},
			func(r): return int(r["lp"][0]) == 8000),
		b("Safe: only the attack that works", {"m": [["Summoned Skull", 1], ["Kuriboh", 1]]}, {"m": [["Vorse Raider", 1], ["Blue-Eyes White Dragon", 1]]},
			func(r): return int(r["lp"][0]) == 8000 and (r["mons"][0] as Array).size() == 2 and (r["mons"][1] as Array).size() == 1),
		b("Safe: a wall goes down in Defense", {"hand": ["Giant Soldier of Stone"]}, {"m": [["Vorse Raider", 1]]},
			func(r): return int(r["lp"][0]) >= 8000, 2),
		b("Safe: a weak monster turns to Defense", {"m": [["Mystical Elf", 1]]}, {"m": [["Vorse Raider", 1]]},
			func(r): return int(r["lp"][0]) >= 8000, 2),
		b("Cards: Raigeki is not thrown at an empty field", {"m": [["Vorse Raider", 1]], "hand": ["Raigeki"]}, {},
			func(r): return int(r["hand"][0]) == 1 and int(r["st"][0]) == 0 and int(r["lp"][1]) == 6100),
		b("Cards: no Dark Hole into its own lead", {"m": [["Blue-Eyes White Dragon", 1], ["Summoned Skull", 1]], "hand": ["Dark Hole"]}, {"m": [["Kuriboh", 1]]},
			func(r): return (r["mons"][0] as Array).size() == 2),
		b("Cards: Dark Hole when it is behind", {"hand": ["Dark Hole"]}, {"m": [["Blue-Eyes White Dragon", 1], ["Summoned Skull", 1]]},
			func(r): return (r["mons"][1] as Array).size() == 0),
		b("Cards: Change of Heart takes the big one", {"hand": ["Change of Heart"]}, {"m": [["Blue-Eyes White Dragon", 1], ["Kuriboh", 1]]},
			func(r): return int(r["lp"][1]) <= 5300),
		b("Cards: Monster Reborn brings back the best", {"hand": ["Monster Reborn"], "gy": ["Celtic Guardian"]}, {"gy": ["Blue-Eyes White Dragon"]},
			func(r): return int(r["lp"][1]) <= 5000),
		b("Cards: Fissure, then the attack", {"m": [["Battle Ox", 1]], "hand": ["Fissure"]}, {"m": [["Vorse Raider", 1]]},
			func(r): return (r["mons"][1] as Array).size() == 0 and int(r["lp"][1]) == 6300),
		b("Cards: Smashing Ground on the wall", {"m": [["Vorse Raider", 1]], "hand": ["Smashing Ground"]}, {"m": [["Giant Soldier of Stone", 4]]},
			func(r): return int(r["lp"][1]) <= 6100),
		b("Cards: Lightning Vortex is worth the discard", {"m": [["Vorse Raider", 1]], "hand": ["Lightning Vortex", "Kuriboh"]}, {"m": [["Blue-Eyes White Dragon", 1], ["Summoned Skull", 1]]},
			func(r): return (r["mons"][1] as Array).size() == 0),
		b("Tempo: summon and attack an open field", {"hand": ["Vorse Raider"]}, {},
			func(r): return int(r["lp"][1]) == 6100),
		b("Tempo: Pot of Greed gets played", {"hand": ["Pot of Greed"]}, {},
			func(r): return int(r["gy"][0]) >= 1),
		b("Tempo: the better monster is not Tributed away", {"m": [["Summoned Skull", 1]], "hand": ["Jinzo"]}, {"m": [["Vorse Raider", 1]]},
			func(r):
				var top := 0
				for c in r["mons"][0]:
					top = maxi(top, int(c["atk"]))
				return top >= 2500),
		b("Rules: Power Bond's End Phase damage", {"m": [["Cyber Dragon", 1], ["Cyber Dragon", 1]], "hand": ["Power Bond"], "extra": ["Cyber Twin Dragon"]}, {"lp": 8000, "m": [["Gate Guardian", 1]]},
			func(r): return int(r["lp"][0]) == 8000 - 2800),
		b("Tempo: direct attack instead of a pointless trade", {"m": [["Vorse Raider", 1]], "hand": ["Fissure"]}, {"lp": 1900, "m": [["Gemini Elf", 1]]}, win),
	]


func cards_of(side: Dictionary, team: int, out: Array) -> void:
	var zone := 0
	for m in side.get("m", []):
		out.append([team, ids[m[0]], 0x04, zone, int(m[1])])
		zone += 1
	zone = 0
	for st in side.get("st", []):
		out.append([team, ids[st], 0x08, zone, 0xa])
		zone += 1
	for h in side.get("hand", []):
		out.append([team, ids[h], 0x02, 0, 0xa])
	for g in side.get("gy", []):
		out.append([team, ids[g], 0x10, 0, 0x1])
	for x in side.get("extra", []):
		out.append([team, ids[x], 0x40, 0, 0x8])
	for i in 10:
		out.append([team, ids[F], 0x01, 0, 0xa])


func play(board: Dictionary, level: int, seed: int) -> Dictionary:
	var cards: Array = []
	cards_of(board["me"], 0, cards)
	cards_of(board["opp"], 1, cards)
	var buf := StreamPeerBuffer.new()
	for i in 4:
		buf.put_u64(seed * 7919 + i * 104729 + 1)
	buf.put_u64(OcgCore.DUEL_FLAGS | 0x02)       # (the first turn may attack: the board is the middle of a duel)
	buf.put_u32(int(board["me"].get("lp", 8000)))
	buf.put_u32(int(board["opp"].get("lp", 8000)))
	buf.put_u32(level)
	buf.put_u32(0)
	buf.put_u32(0)
	buf.put_u32(int(board["turns"]))
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


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var level := int(args[0]) if args.size() > 0 else 2
	var runs := int(args[1]) if args.size() > 1 else 3
	if not OcgCore.ensure_loaded():
		print("ENGINE NOT LOADED")
		get_tree().quit(1)
		return
	for id in Collection.all_cards():
		ids[str(CardData.get_card(int(id)).get("name", ""))] = int(id)
	var passed := 0
	var list := boards()
	var t0 := Time.get_ticks_msec()
	var only := str(args[2]) if args.size() > 2 else ""
	for board in list:
		if only != "" and not str(board["name"]).contains(only):
			continue
		var ok := 0
		var last := {}
		for s in runs:
			last = play(board, level, 11 + s * 5)
			if not last.is_empty() and (board["want"] as Callable).call(last):
				ok += 1
		var good := ok * 2 > runs
		if good:
			passed += 1
		print("%s  %d/%d  %s%s" % ["PASS" if good else "FAIL", ok, runs, board["name"],
			"" if good else "   -> LP %s, monsters %d vs %d, hand %s, winner %s" % [str(last.get("lp")), (last.get("mons", [[], []])[0] as Array).size(), (last.get("mons", [[], []])[1] as Array).size(), str(last.get("hand")), str(last.get("winner"))]])
	print("BOARDS level %d: %d of %d passed  (%d ms)" % [level, passed, list.size(), Time.get_ticks_msec() - t0])
	get_tree().quit(0)
