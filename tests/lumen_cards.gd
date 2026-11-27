extends Node
## Dev: Lumen's cards, one position each, played out on the rules engine. Side 0 holds the card
## and plays at random (leaning toward doing things), side 1 is the basic opponent. A position
## passes when what the card says happened at least once in a few tries, with no script complaint.
##   godot --headless res://tests/lumen_cards.tscn [-- <part of a position's name>] [-v]
const S := 99200001
const CHORUS := 99200002
const COMET := 99200003
const ZENITH := 99200004
const AURORA := 99200006
const NOVA := 99200007
const CALL := 99200012
const VEIL := 99200013
const RITE := 99200014
const BOND := 99200015
const HALL := 99200016
const MERGE := 99200017
const MEMORY := 99200018
const RETURN := 99200019
const SILENCE := 99200020
const WISP := 99200021
const KEEPER := 99200022
const TWIN := 99200023
const MESSENGER := 99200024
const SENTINEL := 99200025
const ELF := 15025844          # Mystical Elf (filler)
const BEWD := 89631139
const VORSE := 14898066
const POLY := 24094653
const POT := 55144522


func has(log: Array, part: String) -> bool:
	for l in log:
		if part in str(l):
			return true
	return false


func positions() -> Array:
	return [
		{"name": "Echo Wisp: from the hand beside Lumen", "mons": [[[S, "atk"]], []], "hand": [[WISP], []],
			"want": func(log, _st): return has(log, "special|0|Echo Wisp")},
		{"name": "Comet: Lumen + Messenger + Wisp (Wisp draws, Messenger brings her back)", "mons": [[[S, "atk"], [MESSENGER, "atk"], [WISP, "atk"]], []], "extra": [COMET],
			"want": func(log, _st): return has(log, "special|0|Lumen, Echo Comet") and has(log, "draw|0|") and has(log, "FX|Echo Messenger") and has(log, "gy_to_hand|0|Lumen, Echo Spirit")},
		{"name": "Echo Lantern Keeper: finds an Echo Spell or Trap", "hand": [[KEEPER], []], "deck": [CALL, VEIL, BOND],
			"want": func(log, _st): return has(log, "summon|0|Echo Lantern Keeper") and (has(log, "search|0|Echo Call") or has(log, "search|0|Echo Veil") or has(log, "search|0|Echo Bond"))},
		{"name": "Echo Twin: follows Lumen from the hand", "hand": [[S, TWIN], []],
			"want": func(log, _st): return has(log, "special|0|Echo Twin")},
		{"name": "Echo Twin: follows Lumen from the Graveyard", "hand": [[S], []], "gy": [[TWIN], []],
			"want": func(log, _st): return has(log, "special|0|Echo Twin")},
		{"name": "Echo Sentinel: Tribute an Echo monster", "mons": [[[WISP, "atk"]], []], "hand": [[SENTINEL], []],
			"want": func(log, _st): return has(log, "special|0|Echo Sentinel")},
		{"name": "Echo Dawn Rite: Lumen alone is the whole Tribute", "mons": [[[S, "atk"]], []], "hand": [[RITE, AURORA], []],
			"want": func(log, _st): return has(log, "special|0|Lumen, Echo Aurora")},
		{"name": "Echo Dawn Rite: two Level 4 monsters", "mons": [[[KEEPER, "atk"], [TWIN, "atk"]], []], "hand": [[RITE, AURORA], []],
			"want": func(log, _st): return has(log, "special|0|Lumen, Echo Aurora")},
		{"name": "Aurora: negates what the opponent activates", "mons": [[[AURORA, "atk"]], []], "hand": [[], [POT, POT, POT]], "turns": 3,
			"want": func(log, _st): return has(log, "chain_negated")},
		{"name": "Nova: Lumen + Comet, then destroys", "mons": [[[S, "atk"], [COMET, "atk"]], [[VORSE, "atk"], [BEWD, "atk"]]], "hand": [[POLY], []], "gy": [[ZENITH], []], "extra": [NOVA],
			"want": func(log, _st): return has(log, "special|0|Lumen, Echo Nova") and has(log, "destroy|1|")},
		{"name": "Echo Bond: ATK up, and the destroyed Lumen comes back", "mons": [[[S, "atk"]], [[BEWD, "atk"]]], "hand": [[BOND], []], "turns": 3,
			"want": func(log, _st): return has(log, "ATK|Lumen, Echo Spirit|%d" % (int(CardData.get_card(S)["atk"]) + 300 + 100 * mini(5, StoryProgress.bonds()))) and has(log, "gy_to_hand|0|Lumen, Echo Spirit")},
		{"name": "Hall of Echoes: second Normal Summon, +300, +500 LP", "hand": [[HALL, S, KEEPER], []],
			"want": func(log, _st): return has(log, "summon|0|Lumen, Echo Spirit") and has(log, "summon|0|Echo Lantern Keeper") and has(log, "ATK|Echo Lantern Keeper|1900") and int(_st.players[0].lp) == 8500},
		{"name": "Echo Merge: Chorus with a monster from the Deck", "mons": [[[S, "atk"]], []], "hand": [[MERGE], []], "extra": [CHORUS],
			"want": func(log, _st): return has(log, "special|0|Lumen, Echo Chorus")},
		{"name": "Echo Merge: no Lumen on the field, hand only", "hand": [[MERGE, S, WISP], []], "extra": [CHORUS],
			"want": func(log, _st): return has(log, "special|0|Lumen, Echo Chorus")},
		{"name": "Echo Memory: shuffle back and draw", "hand": [[MEMORY], []], "gy": [[CALL, VEIL, S], []],
			"want": func(log, _st): return has(log, "gy_to_deck|0|") and has(log, "draw|0|")},
		{"name": "Echo Return: another Lumen comes back", "mons": [[[AURORA, "atk"]], [[BEWD, "atk"]]], "gy": [[S], []], "st": [[RETURN], []], "turns": 3,
			"want": func(log, _st): return has(log, "special|0|Lumen, Echo Spirit")},
		{"name": "Echo Silence: negates a Spell", "mons": [[[S, "def"]], []], "st": [[SILENCE], []], "hand": [[], [POT, POT, POT]], "turns": 3,
			"want": func(log, _st): return has(log, "chain_negated") and has(log, "FX|Echo Silence")},
		{"name": "Echo Call: reaches an Echo monster", "hand": [[CALL], []], "deck": [WISP],
			"want": func(log, _st): return has(log, "search|0|Echo Wisp")},
		{"name": "Zenith: Lumen counts as Level 4 beside a Level 4", "mons": [[[S, "atk"], [KEEPER, "atk"]], []], "extra": [ZENITH],
			"want": func(log, _st): return has(log, "special|0|Lumen, Echo Zenith")},
	]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var verbose := "-v" in args
	if not OcgCore.ensure_loaded():
		print("ENGINE NOT LOADED")
		get_tree().quit(1)
		return
	CardData.lumen_tuner_test = true
	OcgCore.register_originals()
	var bad := 0
	var n := 0
	for pz in positions():
		var name := str(pz["name"])
		if args.size() > 0 and not str(args[0]).begins_with("-") and not str(args[0]).to_lower() in name.to_lower():
			continue
		n += 1
		var ok := false
		var errs := {}
		var last: Array = []
		for seed in 40:
			var r := _play(pz, seed + 1)
			last = r["log"]
			for e in r["errors"]:
				if not str(e).begins_with("script: 9:"):
					errs[str(e).left(200)] = true
			if (pz["want"] as Callable).call(r["log"], r["st"]):
				ok = true
				if verbose:
					print("   seed ", seed + 1, ": ", "  ".join(r["log"]))
				break
		if ok and errs.is_empty():
			print("ok      ", name)
		else:
			bad += 1
			print("NOT OK  ", name, "  happened ", ok, "  ", errs.keys())
			print("   last try: ", "  ".join(last))
	print("LUMEN CARDS: ", n - bad, " pass, ", bad, " not ok")
	get_tree().quit(0)


func _play(pz: Dictionary, seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 7919 + 13
	var st := OcgMirror.new()
	var d := OcgDuel.new()
	var lay := {"hand": pz.get("hand", [[], []]), "mons": pz.get("mons", [[], []]), "gy": pz.get("gy", [[], []]), "st": pz.get("st", [[], []])}
	var mine: Array[int] = []
	for id in pz.get("deck", []):
		mine.append(int(id))
	for i in 12:
		mine.append(ELF if i % 2 == 0 else VORSE)
	var theirs: Array[int] = []
	for i in 14:
		theirs.append(ELF)
	var ex: Array[int] = []
	for id in pz.get("extra", []):
		ex.append(int(id))
	var none: Array[int] = []
	d.prepare(st, [mine, theirs], [ex, none], ["You", "Them"], 0, seed, lay)
	var log: Array = []
	if not d.start([8000, 8000], [0, 0], {}):
		return {"log": ["setup failed"], "errors": ["setup failed"], "st": st}
	var cpu := OcgCpu.new()
	cpu.rng.seed = seed
	var guard := 0
	var max_turn := int(pz.get("turns", 1))
	var seen_atk := {}
	while not d.over and guard < 500:
		guard += 1
		for e in d.advance():
			var t := str(e["type"])
			var cn := str(e["card"].cname()) if e.get("card") != null else ""
			if t in ["summon", "special", "search", "gy_to_hand", "gy_to_deck", "destroy", "lp", "chain_negated", "tribute", "draw", "banish", "mill", "material"]:
				log.append("%s|%s|%s|%s" % [t, str(e.get("player", "")), cn, str(e.get("amount", ""))])
			if t in ["effect", "activate", "trap"]:
				log.append("FX|" + (cn if cn != "" else str(e.get("text", ""))))
		for c in st.players[0].monsters():
			var k := "ATK|%s|%d" % [c.cname(), cpu._atk(d, c)]
			if not seen_atk.has(k):
				seen_atk[k] = true
				log.append(k)
		if d.over or d.request == null or st.turn > max_turn:
			break
		if int(d.request["p"]) == 0:
			d.answer(_eager(d, rng, cpu))
		else:
			d.answer(cpu.decide(d, false))
	var errs := d.errors.duplicate()
	d.close()
	return {"log": log, "errors": errs, "st": st}


## Side 0: do something whenever something can be done; otherwise as the basic opponent would.
func _eager(d: OcgDuel, rng: RandomNumberGenerator, cpu: OcgCpu) -> PackedByteArray:
	var m: Dictionary = d.request
	match int(m["t"]):
		11:
			var opts: Array = []
			for pair in [["summon", 0], ["spsummon", 1], ["chains", 5]]:
				for i in (m[pair[0]] as Array).size():
					opts.append((i << 16) | int(pair[1]))
			if opts.is_empty():
				return OcgDuel.i32(6 if int(m["to_bp"]) != 0 else 7)
			return OcgDuel.i32(opts[rng.randi() % opts.size()])
		10:
			var o2: Array = []
			for i in (m["chains"] as Array).size():
				o2.append(i << 16)
			if o2.is_empty():
				return OcgDuel.i32(3 if int(m["to_ep"]) != 0 else 2)
			return OcgDuel.i32(o2[rng.randi() % o2.size()])
		15:
			var n := (m["cards"] as Array).size()
			var lo := maxi(1, int(m["min"]))
			var hi := clampi(int(m["max"]), lo, n)
			var idx: Array = range(n)
			for i in n:
				var j := rng.randi() % n
				var tmp = idx[i]
				idx[i] = idx[j]
				idx[j] = tmp
			return OcgDuel.pick(idx.slice(0, rng.randi_range(lo, hi)))
		16:
			var nc := (m["chains"] as Array).size()
			if nc == 0:
				return OcgDuel.i32(-1)
			return OcgDuel.i32(rng.randi() % nc)
		12, 13:
			return OcgDuel.i32(1)
	return cpu.decide(d, false)
