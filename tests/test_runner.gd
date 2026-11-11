extends Node
## Headless checks: runs AI vs AI duels to the end and checks rules invariants.
## Run: godot --headless --path . res://tests/test_runner.tscn

var failures := 0


func _ready() -> void:
	_test_tributes()
	_test_battle_math()
	_test_synchro_xyz_fusion()
	_test_traps()
	_test_effects()
	_test_banish()
	var stress := OS.get_environment("STRESS_FOLDER")
	if stress != "":
		CardData.load_external(stress)
		var all: Array = Characters.ORDER.filter(func(k): return CardData.has_deck(Characters.DATA[k]["deck"]))
		var n := 0
		for seed in int(OS.get_environment("STRESS_GAMES")) if OS.get_environment("STRESS_GAMES") != "" else 48:
			var a: String = Characters.DATA[all[seed % all.size()]]["deck"]
			var b: String = Characters.DATA[all[(seed * 7 + 3) % all.size()]]["deck"]
			_ai_vs_ai(900 + seed, a, b, seed % 3, (seed + 1) % 3)
			n += 1
		print("stress: %d games across %d decks" % [n, all.size()])
		print("effects fired for %d different cards: %s" % [EffectRunner.fired.size(), str(EffectRunner.fired)])
		print("TESTS DONE, failures: %d" % failures)
		get_tree().quit(1 if failures > 0 else 0)
		return
	var keys: Array = CardData.DECKS.keys()
	for seed in 60:
		_ai_vs_ai(seed, keys[seed % keys.size()], keys[(seed / keys.size() + 1 + seed) % keys.size()], seed % 3, seed % 3)
	# Hard should beat Easy most of the time with mirrored decks.
	var hard_wins := 0
	for seed in 40:
		var k: String = keys[seed % keys.size()]
		if _ai_vs_ai(100 + seed, k, k, 2, 0) == 0:
			hard_wins += 1
	print("Hard vs Easy: Hard won %d of 40" % hard_wins)
	check(hard_wins >= 30, "Hard beats Easy most of the time (%d/40)" % hard_wins)
	var hn := 0
	var games := int(OS.get_environment("HN_GAMES")) if OS.get_environment("HN_GAMES") != "" else 40
	for seed in games:
		var k: String = keys[seed % keys.size()]
		var first_hard := seed % 2 == 0
		var w := _ai_vs_ai(300 + seed, k, k, 2 if first_hard else 1, 1 if first_hard else 2)
		if (w == 0) == first_hard:
			hn += 1
	print("Hard vs Normal: Hard won %d of %d" % [hn, games])
	check(hn * 100 >= games * 60, "Hard beats Normal clearly (%d/%d)" % [hn, games])
	print("TESTS DONE, failures: %d" % failures)
	get_tree().quit(1 if failures > 0 else 0)


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		push_error("FAIL: " + msg)


func _new_state(seed := 1, a := "yugi", b := "kaiba", legend_a := false, legend_b := false) -> DuelState:
	var s := DuelState.new()
	s.bonus_cards = [1 if legend_a else 0, 1 if legend_b else 0]
	s.setup(CardData.legend_deck(a) if legend_a else CardData.deck_list(a),
			CardData.legend_deck(b) if legend_b else CardData.deck_list(b), "A", "B", 0, seed,
			CardData.extra_list(a), CardData.extra_list(b))
	return s


func _test_traps() -> void:
	var s := _new_state(11)
	s.begin_turn()
	s.end_turn()
	s.begin_turn()  # player 1, turn 2
	var mf := s._make(44095762, 0)
	s.players[0].spells[0] = mf
	mf.face_up = false
	mf.set_turn = 1
	var a1 := _put(s, 1, 89631139, 0)
	var a2 := _put(s, 1, 14898066, 1)
	a1.summoned_turn = 1
	a2.summoned_turn = 1
	s.enter_battle()
	s.declare_attack(1, a1, null)
	var opts := s.responses(0, "attack")
	check(opts.has(mf), "Mirror Force is offered on attack")
	s.respond(0, mf)
	check(s.players[1].monsters().is_empty(), "Mirror Force wipes attack-position monsters")
	var ev := s.resolve_attack()
	check(ev.size() == 1 and ev[0]["type"] == "attack_stopped", "attack stops after Mirror Force")
	check(s.players[0].lp == DuelState.START_LP, "no damage after Mirror Force")
	# Magic Cylinder
	var t := _new_state(12)
	t.begin_turn()
	t.end_turn()
	t.begin_turn()
	var mc := t._make(62279055, 0)
	t.players[0].spells[1] = mc
	mc.set_turn = 1
	var b := _put(t, 1, 70781052, 0)
	t.enter_battle()
	t.declare_attack(1, b, null)
	t.respond(0, mc)
	t.resolve_attack()
	check(t.players[1].lp == DuelState.START_LP - 2500, "Magic Cylinder bounces 2500")
	check(t.players[0].lp == DuelState.START_LP, "Magic Cylinder blocks the hit")


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


func _ai_vs_ai(seed: int, a := "yugi", b := "kaiba", lv_a := 1, lv_b := 1) -> int:
	var s := _new_state(seed, a, b, lv_a == 2, lv_b == 2)
	var start_total := _total(s)
	var guard := 0
	while not s.is_over() and guard < 200:
		guard += 1
		s.begin_turn()
		if s.is_over():
			break
		var p := s.current
		var lv := lv_a if p == 0 else lv_b
		var steps := 0
		while steps < 20:
			steps += 1
			var act := DuelAI.next_main_action(s, p, lv)
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
				var atk := DuelAI.next_attack(s, p, lv)
				if atk.is_empty():
					break
				if s.declare_attack(p, atk["card"], atk["target"]).is_empty():
					break
				var d := s.opponent(p)
				var r := DuelAI.choose_response(s, d, "attack", s.responses(d, "attack"), lv_b if d == 1 else lv_a)
				if r != null:
					s.respond(d, r)
				s.resolve_attack()
			s.enter_main2()
			steps = 0
			while steps < 10 and not s.is_over():
				steps += 1
				var act2 := DuelAI.next_main_action(s, p, lv)
				if act2.is_empty() or _run(s, p, act2).is_empty():
					break
		if s.is_over():
			break
		s.end_turn()
		for i in 2:
			check(s.players[i].hand.size() <= DuelState.HAND_LIMIT or i == s.current, "hand limit")
		check(_total(s) == start_total, "card count stays %d (got %d)" % [start_total, _total(s)])
	check(s.is_over(), "duel %d ended (turns: %d)" % [seed, s.turn])
	return s.winner


func _total(s: DuelState) -> int:
	var t := 0
	for ps in s.players:
		t += ps.deck.size() + ps.hand.size() + ps.gy.size() + ps.extra.size() + ps.set_cards().size()
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
		"set_st":
			return s.set_st(p, act["card"])
		"special_hand":
			return s.special_from_hand(p, act["card"])
		"ignite":
			return s.ignite(p, act["card"])
	return []



func _fake(s: DuelState, p: int, name: String, atk: int, def: int, zone: int, extra := {}) -> DuelState.CardInst:
	var c := s._make(40640057, p)
	var d := {"name": name, "kind": "monster", "frame": "effect", "atk": atk, "def": def, "level": 4, "attribute": "EARTH", "race": "Warrior"}
	d.merge(extra, true)
	c.data = d
	if zone >= 0:
		s.players[p].field[zone] = c
	return c


func _battle_ready(s: DuelState) -> void:
	for p in 2:
		s.players[p].field = [null, null, null, null, null]
		s.players[p].spells = [null, null, null, null, null]
	s.current = 0
	s.turn = 3
	s.phase = DuelState.Phase.BATTLE


func _test_banish() -> void:
	# D.D. Warrior Lady takes her attacker out of the duel with her
	var s := _new_state(31)
	_battle_ready(s)
	var big := _fake(s, 0, "Big", 2400, 0, 0)
	var lady := _fake(s, 1, "D.D. Warrior Lady", 1500, 1600, 0)
	s.attack(0, big, lady)
	check(s.players[0].banished.has(big) and s.players[1].banished.has(lady), "D.D. Warrior Lady banishes both")
	check(not s.players[1].gy.has(lady) and not s.players[0].field.has(big), "Banished cards leave the field and GY")
	# Bottomless Trap Hole banishes instead of sending to the GY
	s = _new_state(32)
	_battle_ready(s)
	s.phase = DuelState.Phase.MAIN1
	var victim := _fake(s, 0, "Victim", 1800, 0, 0)
	victim.summoned_turn = s.turn
	var trap := s._make(29401950, 1)
	trap.face_up = false
	s.players[1].spells[0] = trap
	s.respond(1, trap, victim)
	check(s.players[0].banished.has(victim) and not s.players[0].gy.has(victim), "Bottomless Trap Hole banishes")
	# Soul Release empties the opponent's Graveyard
	s = _new_state(33)
	_battle_ready(s)
	s.phase = DuelState.Phase.MAIN1
	for i in 3:
		s.players[1].gy.append(_fake(s, 1, "Dead%d" % i, 1000 + i * 100, 0, -1))
	var sr := s._make(40640057, 0)
	sr.data = {"name": "Soul Release", "kind": "spell", "frame": "spell", "effect": "soul_release"}
	s.players[0].hand.append(sr)
	check(s.can_activate(0, sr), "Soul Release can be played")
	s.activate(0, sr)
	check(s.players[1].gy.is_empty() and s.players[1].banished.size() == 3, "Soul Release banishes the Graveyard")
	# Chaos Sorcerer: Special Summon by banishing LIGHT + DARK, then banish a monster
	s = _new_state(34)
	_battle_ready(s)
	s.phase = DuelState.Phase.MAIN1
	s.players[0].gy.append(_fake(s, 0, "Lite", 500, 0, -1, {"attribute": "LIGHT"}))
	s.players[0].gy.append(_fake(s, 0, "Dork", 500, 0, -1, {"attribute": "DARK"}))
	var cs := _fake(s, 0, "Chaos Sorcerer", 2300, 2000, -1, {"attribute": "DARK", "level": 6})
	s.players[0].hand.append(cs)
	check(s.can_special_from_hand(0, cs), "Chaos Sorcerer can be Special Summoned")
	s.special_from_hand(0, cs)
	check(s.players[0].field.has(cs) and s.players[0].banished.size() == 2, "Chaos Sorcerer banishes LIGHT + DARK")
	var foe := _fake(s, 1, "Foe", 3000, 0, 0)
	check(s.can_ignite(0, cs), "Chaos Sorcerer effect is ready")
	s.ignite(0, cs)
	check(s.players[1].banished.has(foe), "Chaos Sorcerer banishes a monster")
	# Banisher of the Light: destroyed monsters are banished instead
	s = _new_state(35)
	_battle_ready(s)
	_fake(s, 0, "Banisher of the Light", 100, 2000, 1)
	var a2 := _fake(s, 0, "Hitter", 2000, 0, 0)
	var d2 := _fake(s, 1, "Weak", 500, 0, 0)
	s.attack(0, a2, d2)
	check(s.players[1].banished.has(d2) and not s.players[1].gy.has(d2), "Banisher of the Light redirects to banished")
	# Gren Maju counts banished cards; clone keeps the banished pile
	s = _new_state(36)
	_battle_ready(s)
	var gm := _fake(s, 0, "Gren Maju Da Eiza", 0, 0, 0)
	for i in 4:
		s.players[0].banished.append(_fake(s, 0, "B%d" % i, 0, 0, -1))
	check(s.atk_of(gm, true) == 1600, "Gren Maju gains 400 per banished card (got %d)" % s.atk_of(gm, true))
	check(s.clone().players[0].banished.size() == 4, "Clone copies the banished pile")
	print("banish tests done")


func _test_effects() -> void:
	# Flame Wingman burns for the destroyed monster's ATK
	var s := _new_state(5)
	_battle_ready(s)
	var w := _fake(s, 0, "Elemental HERO Flame Wingman", 2100, 1200, 0, {"frame": "fusion", "level": 6})
	var t := _fake(s, 1, "Target", 1500, 1000, 0)
	var lp := s.players[1].lp
	s.attack(0, w, t)
	check(s.players[1].lp == lp - 600 - 1500, "Flame Wingman burns (got %d)" % (lp - s.players[1].lp))
	# Piercing
	s = _new_state(6)
	_battle_ready(s)
	var msb := _fake(s, 0, "Mad Sword Beast", 1400, 1200, 0)
	var wall := _fake(s, 1, "Wall", 0, 500, 0)
	wall.attack_pos = false
	lp = s.players[1].lp
	s.attack(0, msb, wall)
	check(s.players[1].lp == lp - 900, "Piercing damage")
	# Gyroid survives the first battle each turn
	s = _new_state(7)
	_battle_ready(s)
	var big := _fake(s, 0, "Big", 2000, 0, 0)
	var big2 := _fake(s, 0, "Big2", 2000, 0, 1)
	var gy := _fake(s, 1, "Gyroid", 1000, 1000, 0)
	s.attack(0, big, gy)
	check(s.players[1].field.has(gy), "Gyroid survives once")
	s.attack(0, big2, gy)
	check(not s.players[1].field.has(gy), "Gyroid falls the second time")
	# Direct attacker past a blocker
	s = _new_state(8)
	_battle_ready(s)
	var leg := _fake(s, 0, "Leghul", 300, 350, 0)
	_fake(s, 1, "Blocker", 2000, 2000, 0)
	lp = s.players[1].lp
	s.attack(0, leg, null)
	check(s.players[1].lp == lp - 300, "Leghul attacks directly")
	# Double attack
	s = _new_state(9)
	_battle_ready(s)
	var twin := _fake(s, 0, "Cyber Twin Dragon", 2800, 2100, 0)
	lp = s.players[1].lp
	s.attack(0, twin, null)
	check(s.can_attack(0, twin), "Cyber Twin Dragon can attack again")
	s.attack(0, twin, null)
	check(s.players[1].lp == lp - 5600 and not s.can_attack(0, twin), "Two attacks, then done")
	# Ignition: Thunder Giant discards to destroy a weaker monster
	s = _new_state(10)
	_battle_ready(s)
	s.phase = DuelState.Phase.MAIN1
	var tg := _fake(s, 0, "Elemental HERO Thunder Giant", 2400, 1500, 0)
	var weak := _fake(s, 1, "Weak", 1800, 1000, 0)
	check(s.can_ignite(0, tg), "Thunder Giant can use its effect")
	var hand_before := s.players[0].hand.size()
	s.ignite(0, tg)
	check(not s.players[1].field.has(weak) and s.players[0].hand.size() == hand_before - 1, "Thunder Giant destroyed a monster")
	check(not s.can_ignite(0, tg), "Once per turn")
	# Standby burn
	s = _new_state(11)
	_battle_ready(s)
	_fake(s, 1, "Bowganian", 1300, 1000, 0)
	s.current = 1
	lp = s.players[0].lp
	s.begin_turn()
	check(s.players[0].lp == lp - 600, "Bowganian burns at Standby")
	# Aura
	s = _new_state(12)
	_battle_ready(s)
	_fake(s, 0, "Harpie Lady 1", 1300, 1400, 0, {"attribute": "WIND"})
	var bird := _fake(s, 1, "Wind bird", 1000, 1000, 0, {"attribute": "WIND"})
	check(s.atk_of(bird, false) == 1300, "Harpie Lady 1 powers up WIND monsters")
	print("effects tests done")
