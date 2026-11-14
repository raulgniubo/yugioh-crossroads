extends SceneTree
## Dev tool: plays every duel puzzle through the rules engine.
## For each one it looks for a way to win this turn (trying every order of plays and attacks)
## and checks that attacking without playing a card does not already win.
## godot --headless -s tools/puzzle_check.gd

var nodes := 0


func _initialize() -> void:
	CardData.load_external("/tmp/testassets2")
	var bad := 0
	for pz in Puzzles.LIST:
		if not Puzzles.ready(pz):
			print("PUZZLE ", pz["id"], ": MISSING CARDS ", Puzzles.names(pz).filter(func(n): return Puzzles._id(n) == 0))
			bad += 1
			continue
		var s := DuelState.new()
		s.manual = [false, false]
		Puzzles.begin(s, pz)
		Puzzles.place(s, pz)
		s.begin_turn()
		nodes = 0
		var naive := _battle(s.clone(), 0)
		var line: Array = []
		var win := _main(s, 0, line)
		print("PUZZLE ", pz["id"], ": ", "SOLVABLE" if win else "NO SOLUTION", "  attack-only wins: ", naive, "  positions tried: ", nodes, "  line: ", line)
		if not win or naive:
			bad += 1
	print("PUZZLES CHECKED: ", Puzzles.LIST.size(), "  problems: ", bad)
	quit()


func _main(s: DuelState, depth: int, line: Array) -> bool:
	nodes += 1
	if s.is_over():
		return s.winner == 0
	if depth > 7 or nodes > 60000:
		return false
	if _battle(s.clone(), 0):
		line.append("attack")
		return true
	for act in DuelAI._candidates(s, 0):
		var c2 := s.clone()
		c2.manual = [false, false]
		var a2 := DuelAI._map_action(c2, act)
		var ev := DuelAI.apply(c2, 0, a2)
		if ev.is_empty():
			continue
		if not c2.chain.is_empty():
			c2.chain_resolve()
		line.append("%s %s" % [act["do"], act["card"].cname()])
		if _main(c2, depth + 1, line):
			return true
		line.pop_back()
	# Also: set any Spell or Trap face-down (a person can do this with every card).
	for c in s.players[0].hand:
		if not c.is_monster() and s.can_set_st(0, c):
			var c3 := s.clone()
			c3.manual = [false, false]
			c3.set_st(0, c3.find_uid(c.uid))
			line.append("set %s" % c.cname())
			if _main(c3, depth + 1, line):
				return true
			line.pop_back()
	return false


func _battle(s: DuelState, depth: int) -> bool:
	nodes += 1
	if s.is_over():
		return s.winner == 0
	if depth == 0:
		if not s.can_enter_battle():
			return false
		s.enter_battle()
	if depth > 6:
		return false
	for m in s.players[0].monsters():
		if not s.can_attack(0, m):
			continue
		var targets: Array = s.attack_targets(0)
		var opts: Array = targets.duplicate()
		if s.can_direct_attack(0) or s.can_direct_attack_with(0, m):
			opts.append(null)
		for t in opts:
			var c2 := s.clone()
			c2.manual = [false, false]
			c2.attack(0, c2.find_uid(m.uid), c2.find_uid(t.uid) if t != null else null)
			if _battle(c2, depth + 1):
				return true
	return false
