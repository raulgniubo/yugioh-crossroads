extends Node
## Headless checks: runs AI vs AI duels to the end and checks rules invariants.
## Run: godot --headless --path . res://tests/test_runner.tscn

var failures := 0


func _ready() -> void:
	_test_tributes()
	_test_battle_math()
	_test_synchro_xyz_fusion()
	var keys: Array = CardData.DECKS.keys()
	for seed in 60:
		_ai_vs_ai(seed, keys[seed % keys.size()], keys[(seed / keys.size() + 1 + seed) % keys.size()])
	print("TESTS DONE, failures: %d" % failures)
	get_tree().quit(1 if failures > 0 else 0)


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		push_error("FAIL: " + msg)


func _new_state(seed := 1, a := "yugi", b := "kaiba") -> DuelState:
	var s := DuelState.new()
	s.setup(CardData.deck_list(a), CardData.deck_list(b), "A", "B", 0, seed,
			CardData.extra_list(a), CardData.extra_list(b))
	return s


func _put(s: DuelState, p: int, id: int, zone: int) -> DuelState.CardInst:
	var c := s._make(id, p)
	s.players[p].field[zone] = c
	return c


func _test_synchro_xyz_fusion() -> void:
	var s := _new_state(5, "yusei", "yuma")
	s.begin_turn()
	s.current = 0
	s.phase = DuelState.Phase.MAIN1
	_put(s, 0, 63977008, 0)  # Junk Synchron L3 tuner
	_put(s, 0, 59546797, 1)  # Shield Warrior L3
	_put(s, 0, 9365703, 2)   # Speed Warrior L2
	var stardust: DuelState.CardInst = null
	for x in s.players[0].extra:
		if x.id == 44508094:
			stardust = x
	check(s.can_extra_summon(0, stardust), "Stardust needs tuner 3 + 3 + 2")
	var ev := s.extra_summon(0, stardust)
	check(s.players[0].field.has(stardust), "Stardust on field")
	check(s.players[0].monsters().size() == 1, "materials left field")
	check(ev.filter(func(e): return e["type"] == "material").size() == 3, "3 material events")
	# Xyz
	var y := _new_state(6, "yuma", "yusei")
	y.begin_turn()
	y.phase = DuelState.Phase.MAIN1
	_put(y, 0, 26082117, 0)
	_put(y, 0, 62476815, 1)
	var utopia: DuelState.CardInst = null
	for x in y.players[0].extra:
		if x.id == 84013237:
			utopia = x
	check(y.can_extra_summon(0, utopia), "Utopia from two Level 4s")
	y.extra_summon(0, utopia)
	check(utopia.overlays.size() == 2, "Utopia has 2 materials")
	# Fusion
	var f := _new_state(7, "jaden", "yugi")
	f.begin_turn()
	f.phase = DuelState.Phase.MAIN1
	f.players[0].hand.clear()
	var poly := f._make(24094653, 0)
	f.players[0].hand.append(poly)
	f.players[0].hand.append(f._make(21844576, 0))
	_put(f, 0, 58932615, 0)
	check(f.can_activate(0, poly), "Polymerization usable with Avian + Burstinatrix")
	f.activate(0, poly)
	var wingman := f.players[0].monsters()
	check(wingman.size() == 1 and wingman[0].id == 35809262, "Flame Wingman fused")


func _test_tributes() -> void:
	var s := _new_state()
	s.begin_turn()
	var blue := DuelState.CardInst.new()
	blue.data = CardData.get_card(89631139)
	blue.owner = 0
	s.players[0].hand.append(blue)
	check(s.tributes_needed(blue) == 2, "Blue-Eyes needs 2 tributes")
	check(not s.can_normal_summon(0, blue), "can't summon Blue-Eyes with empty field")


func _test_battle_math() -> void:
	var s := _new_state(3)
	s.turn = 2
	s.current = 0
	s.phase = DuelState.Phase.BATTLE
	var a := DuelState.CardInst.new()
	a.data = CardData.get_card(70781052)  # 2500
	a.owner = 0
	var d := DuelState.CardInst.new()
	d.data = CardData.get_card(15025844)  # 800/2000 in def
	d.owner = 1
	d.attack_pos = false
	d.face_up = false
	s.players[0].field[0] = a
	s.players[1].field[0] = d
	var ev := s.attack(0, a, d)
	check(s.players[1].field[0] == null, "2500 ATK destroys 2000 DEF")
	check(s.players[1].lp == DuelState.START_LP, "no damage attacking defense")
	check(ev.any(func(e): return e["type"] == "reveal"), "face-down target gets revealed")


func _ai_vs_ai(seed: int, a := "yugi", b := "kaiba") -> void:
	var s := _new_state(seed, a, b)
	var start_total := _total(s)
	var guard := 0
	while not s.is_over() and guard < 200:
		guard += 1
		s.begin_turn()
		if s.is_over():
			break
		var p := s.current
		var steps := 0
		while steps < 20:
			steps += 1
			var act := DuelAI.next_main_action(s, p)
			if act.is_empty():
				break
			var ev := _run(s, p, act)
			check(not ev.is_empty(), "AI action did something (%s)" % act["do"])
			if ev.is_empty():
				break
		if s.can_enter_battle():
			s.enter_battle()
			steps = 0
			while steps < 10 and not s.is_over():
				steps += 1
				var atk := DuelAI.next_attack(s, p)
				if atk.is_empty():
					break
				s.attack(p, atk["card"], atk["target"])
			s.enter_main2()
		if s.is_over():
			break
		s.end_turn()
		for i in 2:
			check(s.players[i].hand.size() <= DuelState.HAND_LIMIT or i == s.current, "hand limit")
		check(_total(s) == start_total, "card count stays %d (got %d)" % [start_total, _total(s)])
	check(s.is_over(), "duel %d ended (turns: %d)" % [seed, s.turn])
	print("duel %s vs %s seed %d: winner %d after %d turns (%s)" % [a, b, seed, s.winner, s.turn, s.win_reason])


func _total(s: DuelState) -> int:
	var t := 0
	for ps in s.players:
		t += ps.deck.size() + ps.hand.size() + ps.gy.size() + ps.extra.size()
		for m in ps.monsters():
			t += 1 + m.overlays.size()
	return t


func _run(s: DuelState, p: int, act: Dictionary) -> Array:
	match act["do"]:
		"activate":
			return s.activate(p, act["card"], act.get("choice"))
		"extra":
			return s.extra_summon(p, act["card"])
		"summon":
			return s.normal_summon(p, act["card"], act["tributes"], false)
		"set":
			return s.normal_summon(p, act["card"], act["tributes"], true)
		"flip":
			return s.flip_summon(p, act["card"])
		"position":
			return s.change_position(p, act["card"])
	return []
