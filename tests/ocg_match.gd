extends Node
## Dev: whole duels between two levels of the engine-side opponent, no screen.
##   godot --headless res://tests/ocg_match.tscn -- <deck a|all> <deck b> <level a> <level b> <duels> [seed] [ms] [out file]
## Sides swap who goes first every duel. Prints wins for a, wins for b, draws.
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var a := str(args[0]) if args.size() > 0 else "deck_monarchs"
	var b := str(args[1]) if args.size() > 1 else "deck_gem_knight"
	var la := int(args[2]) if args.size() > 2 else 0
	var lb := int(args[3]) if args.size() > 3 else 0
	var n := int(args[4]) if args.size() > 4 else 4
	var seed0 := int(args[5]) if args.size() > 5 else 1
	var ms := int(args[6]) if args.size() > 6 else 0
	var out_path := str(args[7]) if args.size() > 7 else ""
	if not OcgCore.ensure_loaded():
		print("ENGINE NOT LOADED")
		get_tree().quit(1)
		return
	OcgCore.register_originals()
	var keys: Array = [a]
	if a == "all":
		keys = CardData.DECKS.keys() + CardData.NAMED_DECKS.keys()
		keys = keys.filter(func(k): return CardData.deck_list(str(k)).size() >= 20)
	var wins := [0, 0, 0]
	var t0 := Time.get_ticks_msec()
	var think := 0
	var worst := 0
	var decisions := 0
	var sims := 0
	var refused := 0
	var turns := 0
	var cs := {}          # (0.76.0) the common-sense mistakes of both sides, by level
	var cs_ex: Array = []
	for g in n:
		# Each pair of decks is played twice with the sides swapped, so neither level gets the better deck.
		var pair := g / 2
		var ka := str(keys[(seed0 * 13 + pair * 5) % keys.size()])
		var kb := b if a != "all" else str(keys[(seed0 * 7 + pair * 11 + 3) % keys.size()])
		var decks := [CardData.deck_list(ka), CardData.deck_list(kb)]
		var extras := [CardData.extra_list(ka), CardData.extra_list(kb)]
		var levels := [la, lb]
		var flip := g % 2 == 1
		if flip:
			decks.reverse()
			extras.reverse()
			levels.reverse()
		var r := OcgCore.match_duel(decks, extras, levels, seed0 * 1000 + pair, ms)
		var w := int(r["winner"])
		if w < 2 and flip:
			w = 1 - w
		wins[w] += 1
		think += int(r.get("think_ms", 0))
		worst = maxi(worst, int(r.get("max_ms", 0)))
		decisions += int(r.get("decisions", 0))
		sims += int(r.get("sims", 0))
		refused += int(r.get("refused", 0))
		turns += int(r.get("turns", 0))
		for k in (r.get("cs", {}) as Dictionary):
			cs[k] = int(cs.get(k, 0)) + int(r["cs"][k])
		for e in r.get("cs_ex", []):
			if cs_ex.size() < 60:
				cs_ex.append("%s vs %s: %s" % [ka, kb, str(e)])
		if out_path != "":
			var f := FileAccess.open(out_path, FileAccess.WRITE)
			f.store_line("%d %d %d of %d" % [wins[0], wins[1], wins[2], g + 1])
			f.store_line(JSON.stringify(cs))
			f.close()
	print("MATCH level %d vs level %d: %s  duels %d  wall ms %d  think ms %d  worst decision ms %d  decisions %d  tries %d  refused %d  turns %d" % [la, lb, str(wins), n, Time.get_ticks_msec() - t0, think, worst, decisions, sims, refused, turns])
	var keys_cs: Array = cs.keys()
	keys_cs.sort()
	for k in keys_cs:
		print("CS %s %d" % [k, int(cs[k])])
	for e in cs_ex:
		print("CS EX ", e)
	get_tree().quit(0)
