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
	_test_spell_rules()
	_test_full_rules()
	_test_choices()
	_test_turbo()
	_test_vault()
	_test_toons()
	_test_unions()
	_test_heroes_angels()
	_test_batch_31()
	_test_batch_32()
	_test_batch_33()
	_test_batch_34()
	_test_destiny()
	_test_stakes()
	_test_decks()
	_test_clock_and_story()
	var stress := OS.get_environment("STRESS_FOLDER")
	if stress != "":
		CardData.load_external(stress)
		var all: Array = Characters.ORDER.filter(func(k): return CardData.has_deck(Characters.DATA[k]["deck"]))
		_test_card_numbers()
		_test_field_looks()
		_test_academy_week()
		_test_signature_decks()
		_test_cards_27()
		_test_cards_28()
		_test_cards_32()
		_test_cards_33()
		_test_cards_34()
		_test_cards_35()
		_test_cards_36()
		_test_cards_37()
		_test_cards_38()
		_test_cards_39()
		_test_cards_40()
		_test_cards_41()
		_test_cards_42()
		_test_turbo_setup()
		_test_knockout()
		_test_lumen()
		_test_ai_targets()
		if OS.get_environment("WORKS_FILE") != "":
			# Dev: which of these cards (one name per line) work in the game right now?
			var yes: Array = []
			var no: Array = []
			var gone: Array = []
			for nm in FileAccess.get_file_as_string(OS.get_environment("WORKS_FILE")).split("\n", false):
				var wid := _cid(nm.strip_edges())
				if wid == 0:
					gone.append(nm)
				elif SignatureDecks._works(wid):
					yes.append(nm)
				else:
					no.append(nm)
			print("WORKS: %s" % "|".join(yes))
			print("NEEDS: %s" % "|".join(no))
			print("NOT IN DB: %s" % "|".join(gone))
			get_tree().quit(0)
			return
		if OS.get_environment("YUSEI_SIM") != "":
			# How does the computer play Yusei's deck? (A look, not a pass/fail test.)
			made.clear()
			var sim_deck := OS.get_environment("SIM_DECK") if OS.get_environment("SIM_DECK") != "" else "yusei"
			DuelAI.aces = [int(Characters.get_char(sim_deck).get("ace", _cid("Stardust Dragon"))), 0]
			var wins := 0
			var games := int(OS.get_environment("YUSEI_SIM"))
			var g_from := int(OS.get_environment("SIM_FROM")) if OS.get_environment("SIM_FROM") != "" else 0
			for gi in games:
				var g: int = gi + g_from
				var foe: String = Characters.DATA[all[(g * 5 + 1) % all.size()]]["deck"]
				trace = OS.get_environment("YUSEI_TRACE") != "" and gi < 3
				if OS.get_environment("SIM_PROGRESS") != "":
					print("SIM game %d vs %s" % [g, foe])
				if trace:
					print("--- game %d vs %s" % [g, foe])
				if _ai_vs_ai(4000 + g, sim_deck, foe, 2, 2) == 0:
					wins += 1
			print("YUSEI SIM: %d wins of %d" % [wins, games])
			print("YUSEI MADE: %s" % str(made))
			DuelAI.aces = [0, 0]
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
	var xh := 0
	var xgames := int(OS.get_environment("XH_GAMES")) if OS.get_environment("XH_GAMES") != "" else 30
	var t0 := Time.get_ticks_msec()
	for seed in xgames:
		var k: String = keys[seed % keys.size()]
		var first_x := seed % 2 == 0
		var w := _ai_vs_ai(700 + seed, k, k, 3 if first_x else 2, 2 if first_x else 3)
		if (w == 0) == first_x:
			xh += 1
	print("Expert vs Hard: Expert won %d of %d  (%.1f s per game)" % [xh, xgames, (Time.get_ticks_msec() - t0) / 1000.0 / maxf(1.0, xgames)])
	check(xh * 100 >= xgames * 40, "Expert holds its own against Hard (%d/%d)" % [xh, xgames])
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
	_put(s, 0, 95360850, 1)  # Shield Warrior L3
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


## What the computer chose to do in the AI-against-AI games (Extra Deck summons, effects used).
var made := {}
var trace := false


func _ai_vs_ai(seed: int, a := "yugi", b := "kaiba", lv_a := 1, lv_b := 1) -> int:
	var s := _new_state(seed, a, b, lv_a >= 2, lv_b >= 2)
	var start_total := _total(s)
	var guard := 0
	while not s.is_over() and guard < 200:
		guard += 1
		s.begin_turn()
		if s.is_over():
			break
		var p := s.current
		var lv := lv_a if p == 0 else lv_b
		if trace:
			print(" == T%d P%d LP %d/%d | A field: %s | B field: %s" % [s.turn, p, s.players[0].lp, s.players[1].lp, ", ".join(s.players[0].monsters().map(func(m): return "%s(%d%s)" % [m.cname(), s.atk_of(m, false), "" if m.attack_pos else "D"])), ", ".join(s.players[1].monsters().map(func(m): return "%s(%d%s)" % [m.cname(), s.atk_of(m, false), "" if m.attack_pos else "D"]))])
		var steps := 0
		while steps < 20:
			steps += 1
			var act := DuelAI.next_main_action(s, p, lv)
			if act.is_empty():
				break
			if trace:
				print("  P%d %s %s%s" % [p, act["do"], act["card"].cname() if act.has("card") else "", (" | hand: " + ", ".join(s.players[0].hand.map(func(h): return h.cname()))) if p == 0 else ""])
			var ev := _run(s, p, act)
			if act["do"] in ["extra", "ignite", "special_hand", "gy_ignite"]:
				var key := "%s %s" % [act["do"], act["card"].cname()]
				made[key] = int(made.get(key, 0)) + 1
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
				if trace:
					print("    P%d attack %s -> %s" % [p, atk["card"].cname(), atk["target"].cname() if atk["target"] != null else "direct"])
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
		t += ps.deck.size() + ps.hand.size() + ps.gy.size() + ps.extra.size() + ps.banished.size()
		t += 1 if ps.field_spell != null else 0
		for st in ps.spells:
			t += 1 if st != null else 0
		for m in ps.monsters():
			t += (0 if m.is_token() else 1) + m.overlays.size()
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
		"hand_ignite":
			return s.hand_ignite(p, act["card"])
		"gy_ignite":
			return s.gy_ignite(p, act["card"])
		"speed":
			return s.speed_world(p, int(act["cost"]))
	return []


func _test_vault() -> void:
	# Giant Germ: 500 damage when it dies in battle.
	var s := _new_state(31)
	_battle_ready(s)
	var big := _fake(s, 0, "Big", 2000, 0, 0)
	var germ := _fake(s, 1, "Giant Germ", 1000, 100, 0)
	var lp0 := s.players[0].lp
	var lp1 := s.players[1].lp
	s.attack(0, big, germ)
	check(s.players[1].lp == lp1 - 1000 and s.players[0].lp == lp0 - 500, "Giant Germ burns 500 when destroyed by battle")
	# Airknight Parshath: piercing, and a draw when it deals damage.
	s = _new_state(32)
	_battle_ready(s)
	var air := _fake(s, 0, "Airknight Parshath", 1900, 1400, 0)
	var wall := _fake(s, 1, "Wall", 0, 500, 0)
	wall.attack_pos = false
	var hand := s.players[0].hand.size()
	lp1 = s.players[1].lp
	s.attack(0, air, wall)
	check(s.players[1].lp == lp1 - 1400, "Airknight Parshath pierces")
	check(s.players[0].hand.size() == hand + 1, "Airknight Parshath draws after dealing damage")
	# Goblin Attack Force goes to Defense after attacking.
	s = _new_state(33)
	_battle_ready(s)
	var gob := _fake(s, 0, "Goblin Attack Force", 2300, 0, 0)
	var t := _fake(s, 1, "Target", 1500, 1000, 0)
	s.attack(0, gob, t)
	check(gob.attack_pos, "Goblin Attack Force is still in Attack Position right after the attack")
	s.enter_main2()
	check(not gob.attack_pos, "Goblin Attack Force changes to Defense Position at the end of the Battle Phase")
	s.end_turn()
	s.begin_turn()
	s.end_turn()
	s.begin_turn()
	check(not s.can_change_position(0, gob), "Goblin Attack Force cannot change position on your next turn")
	# ---- the aces, by their printed text
	# Number 39: Utopia with no material is destroyed when it is targeted for an attack.
	s = _new_state(34)
	_battle_ready(s)
	var uto := _put(s, 1, CardData.NAME_TO_ID["number 39: utopia"], 0)
	var uto_hit := _fake(s, 0, "Hitter", 1000, 0, 0)
	s.declare_attack(0, uto_hit, uto)
	check(not s.players[1].field.has(uto), "Utopia with no material is destroyed when attacked")
	# Number 17: Leviathan Dragon cannot attack directly without material.
	s = _new_state(35)
	_battle_ready(s)
	var lev := _put(s, 0, CardData.NAME_TO_ID["number 17: leviathan dragon"], 0)
	check(not s.can_direct_attack_with(0, lev), "Leviathan Dragon cannot attack directly without material")
	lev.overlays = [s._make(40640057, 0)]
	check(s.can_direct_attack_with(0, lev), "Leviathan Dragon attacks directly with material")
	# Stardust Dragon: Tribute to negate a destruction effect, and it returns in the End Phase.
	s = _new_state(36)
	_battle_ready(s)
	s.phase = DuelState.Phase.MAIN1
	s.current = 1
	var star := _put(s, 0, CardData.NAME_TO_ID["stardust dragon"], 0)
	var sd_friend := _fake(s, 0, "Friend", 1000, 1000, 1)
	var rg := s._make(CardData.NAME_TO_ID["smashing ground"], 1)
	s.players[1].hand.append(rg)
	s.chain_add(1, rg, null, "open", null)
	check(s.responses(0, "chain", s.chain.back()).has(star), "Stardust Dragon is offered against a destruction Spell")
	s.respond(0, star, null)
	s.chain_resolve()
	check(s.players[0].field.has(sd_friend) and s.players[0].gy.has(star), "Stardust Dragon negated it and went to the Graveyard")
	s.begin_end()
	check(s.players[0].field.has(star), "Stardust Dragon returns in the End Phase")
	# Red Dragon Archfiend: in your End Phase, your monsters that did not attack are destroyed.
	s = _new_state(37)
	_battle_ready(s)
	var rda := _put(s, 0, CardData.NAME_TO_ID["red dragon archfiend"], 0)
	var rda_lazy := _fake(s, 0, "Lazy", 1000, 1000, 1)
	s.begin_end()
	check(s.players[0].field.has(rda) and not s.players[0].field.has(rda_lazy), "Red Dragon Archfiend destroys your monsters that did not attack")
	# Blackwing Armor Master: Wedge Counter, then 0 ATK and DEF.
	s = _new_state(38)
	_battle_ready(s)
	var am := _put(s, 0, CardData.NAME_TO_ID["blackwing armor master"], 0)
	var am_wall := _fake(s, 1, "Wall", 3000, 3000, 0)
	s.attack(0, am, am_wall)
	check(am_wall.wedge and s.players[0].field.has(am) and s.players[0].lp == DuelState.START_LP, "Armor Master places a Wedge Counter and takes no damage")
	s.phase = DuelState.Phase.MAIN2
	check(s.can_ignite(0, am), "Armor Master can remove the Wedge Counters")
	s.ignite(0, am)
	check(s.atk_of(am_wall, false) == 0 and s.def_of(am_wall) == 0, "The wedged monster drops to 0 ATK and DEF")
	# Galaxy-Eyes Photon Dragon: both monsters leave the battle and come back at the end of the Battle Phase.
	s = _new_state(39)
	_battle_ready(s)
	var ge := _put(s, 0, CardData.NAME_TO_ID["galaxy-eyes photon dragon"], 0)
	var ge_xyz := _put(s, 1, CardData.NAME_TO_ID["number 39: utopia"], 0)
	ge_xyz.overlays = [s._make(40640057, 1), s._make(40640057, 1)]
	s.declare_attack(0, ge, ge_xyz)
	check(s.responses(0, "attack", ge).has(ge), "Galaxy-Eyes is offered in the Battle Step")
	s.respond(0, ge, ge)
	s.resolve_attack()
	check(not s.players[0].field.has(ge) and not s.players[1].field.has(ge_xyz), "Both monsters are banished")
	s.enter_main2()
	check(s.players[0].field.has(ge) and s.players[1].field.has(ge_xyz) and s.atk_of(ge, false) == 4000, "They return, and Galaxy-Eyes gained 500 for each material (got %d)" % s.atk_of(ge, false))
	# Black Rose Dragon: banish a Plant, a Defense monster is forced to Attack with 0 ATK.
	s = _new_state(40)
	_battle_ready(s)
	s.phase = DuelState.Phase.MAIN1
	var br := _put(s, 0, CardData.NAME_TO_ID["black rose dragon"], 0)
	s.players[0].gy.append(s._make(CardData.NAME_TO_ID["lord poison"], 0))
	var br_turtle := _fake(s, 1, "Turtle", 1500, 2500, 0)
	br_turtle.attack_pos = false
	check(s.can_ignite(0, br), "Black Rose Dragon can use its effect")
	s.ignite(0, br)
	check(br_turtle.attack_pos and s.atk_of(br_turtle, false) == 0 and s.players[0].banished.size() == 1, "The Defense monster is in Attack Position with 0 ATK")
	# Dark Magician Girl counts Magician of Black Chaos too.
	s = _new_state(41)
	_battle_ready(s)
	var dmg := _put(s, 0, CardData.NAME_TO_ID["dark magician girl"], 0)
	s.players[1].gy.append(s._make(CardData.NAME_TO_ID["dark magician"], 1))
	if CardData.NAME_TO_ID.has("magician of black chaos"):
		s.players[0].gy.append(s._make(CardData.NAME_TO_ID["magician of black chaos"], 0))
		check(s.atk_of(dmg, false) == 2600, "Dark Magician Girl gains 300 for each (got %d)" % s.atk_of(dmg, false))
	# Synchro materials by name: Junk Warrior needs Junk Synchron.
	s = _new_state(42)
	_battle_ready(s)
	s.phase = DuelState.Phase.MAIN1
	var jw := s._make(CardData.NAME_TO_ID["junk warrior"], 0)
	s.players[0].extra.append(jw)
	var other_tuner := _fake(s, 0, "Some Tuner", 500, 500, 0, {"level": 3, "tuner": true})
	_fake(s, 0, "Level Two", 500, 500, 1, {"level": 2})
	check(not s.can_extra_summon(0, jw), "Junk Warrior cannot be made with another Tuner")
	other_tuner.data["name"] = "Junk Synchron"
	check(s.can_extra_summon(0, jw), "Junk Warrior can be made with Junk Synchron")
	# Exiled Force tributes itself to destroy a monster.
	s = _new_state(34)
	s.begin_turn()
	var ex := _fake(s, 0, "Exiled Force", 1000, 1000, 0)
	var foe := _fake(s, 1, "Foe", 2800, 2000, 0)
	check(s.can_ignite(0, ex), "Exiled Force can use its effect")
	s.ignite(0, ex)
	s.chain_resolve()
	check(not s.players[1].monsters().has(foe) and not s.players[0].monsters().has(ex), "Exiled Force tributes itself and destroys a monster")
	# The Forbidden/Limited list limits what a deck may hold.
	check(CardData.rarity(89631139) >= 2, "A 3000 ATK monster is a Super or Ultra Rare")
	print("vault tests done")


func _test_turbo() -> void:
	var s := _new_state(21)
	s.turbo = true
	s.begin_turn()
	check(s.players[0].speed == 0 and s.players[1].speed == 0, "Turbo: no Speed Counters on the first turn")
	var pot := s._make(55144522, 0)   # Pot of Greed
	s.players[0].hand.append(pot)
	check(s.speed_need(pot) == 5, "Turbo: a heavy Spell needs 5 Speed Counters")
	check(not s.can_activate(0, pot), "Turbo: Spells cannot be played without the speed")
	s.end_turn()
	s.begin_turn()
	check(s.players[0].speed == 1 and s.players[1].speed == 1, "Turbo: both riders gain 1 Speed Counter each Standby Phase")
	s.players[1].speed = 8
	s._damage(1, 2300)
	check(s.players[1].speed == 6, "Turbo: 2300 damage costs 2 Speed Counters (%d)" % s.players[1].speed)
	s._damage(1, 900)
	check(s.players[1].speed == 6, "Turbo: under 1000 damage costs nothing")
	# Speed World 2, the three effects.
	s.players[1].speed = 12
	var hand_before := s.players[1].hand.size()
	check(s.can_speed_world(1, 7), "Turbo: 7 counters can be spent to draw")
	s.speed_world(1, 7)
	check(s.players[1].hand.size() == hand_before + 1 and s.players[1].speed == 5, "Turbo: Speed World 2 draws 1 for 7")
	check(not s.can_speed_world(1, 4), "Turbo: Speed World 2 is once per turn")
	s.end_turn()
	s.begin_turn()
	s.players[0].speed = 10
	var lp := s.players[1].lp
	var spells: int = s.players[0].hand.filter(func(c): return not c.is_monster() and not c.is_trap()).size()
	s.speed_world(0, 4)
	check(s.players[1].lp == lp - 800 * spells and spells >= 1, "Turbo: Speed World 2 burns 800 for each Speed Spell in hand (%d)" % spells)
	check(s.can_activate(0, pot), "Turbo: with enough speed the Spell can be played")
	var c2 := s.clone()
	check(c2.turbo and c2.players[0].speed == s.players[0].speed, "Turbo: a copy of the duel keeps the Speed Counters")
	# Whole games with the AI on both sides stay sound.
	for seed in 6:
		var g := _new_state(900 + seed, "yusei", "kaiba", true, true)
		g.turbo = true
		var guard := 0
		while not g.is_over() and guard < 120:
			guard += 1
			g.begin_turn()
			if g.is_over():
				break
			var p := g.current
			var steps := 0
			while steps < 20:
				steps += 1
				var act := DuelAI.next_main_action(g, p, 2)
				if act.is_empty() or _run(g, p, act).is_empty():
					break
			if g.can_enter_battle():
				g.enter_battle()
				steps = 0
				while steps < 10 and not g.is_over():
					steps += 1
					var atk := DuelAI.next_attack(g, p, 2)
					if atk.is_empty() or g.declare_attack(p, atk["card"], atk["target"]).is_empty():
						break
					g.resolve_attack()
			if not g.is_over():
				g.end_turn()
		check(g.is_over(), "Turbo: an AI game reaches an end (seed %d)" % seed)
		check(g.players[0].speed <= 12 and g.players[1].speed <= 12, "Turbo: Speed Counters stay within 12")
	print("turbo tests done")



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


## A Spell/Trap by name, in hand ("hand") or Set last turn ("set").
func _st(s: DuelState, p: int, name: String, where := "hand", kind := "spell", extra := {}) -> DuelState.CardInst:
	var c := s._make(40640057, p)
	var d := {"name": name, "kind": kind, "frame": kind}
	d.merge(extra, true)
	c.data = d
	if where == "hand":
		s.players[p].hand.append(c)
	else:
		c.face_up = false
		c.set_turn = s.turn - 1
		s.players[p].spells[s.players[p].spells.find(null)] = c
	return c


func _main_ready(seed: int) -> DuelState:
	var s := _new_state(seed)
	_battle_ready(s)
	s.phase = DuelState.Phase.MAIN1
	return s


func _test_spell_rules() -> void:
	# Field Spell: boosts the right monsters on both sides, sits in the Field Zone
	var s := _main_ready(41)
	var dragon := _fake(s, 0, "Dragon", 2000, 1000, 0, {"race": "Dragon"})
	var warrior := _fake(s, 1, "Warrior", 1500, 1000, 0)
	var mountain := _st(s, 0, "Mountain")
	check(s.can_activate(0, mountain), "Field Spell can be activated")
	s.activate(0, mountain)
	check(s.players[0].field_spell == mountain, "Field Spell sits in the Field Zone")
	check(s.atk_of(dragon, false) == 2200 and s.def_of(dragon) == 1200 and s.atk_of(warrior, false) == 1500, "Mountain boosts Dragons only")
	var yami := _st(s, 0, "Yami")
	s.activate(0, yami)
	check(s.players[0].field_spell == yami and s.players[0].gy.has(mountain), "A new Field Spell replaces the old one")
	# Equip Spell: boosts, and leaves with its monster
	s = _main_ready(42)
	var m := _fake(s, 0, "Knight", 1500, 1000, 0)
	var foe := _fake(s, 1, "Foe", 2000, 1000, 0)
	var axe := _st(s, 0, "Axe of Despair")
	s.activate(0, axe, m)
	check(axe.equipped_to == m and s.atk_of(m, false) == 2500 and s.players[0].spells.has(axe), "Axe of Despair equips for +1000")
	s.phase = DuelState.Phase.BATTLE
	s.attack(0, m, foe)
	check(not s.players[1].field.has(foe), "Equipped monster wins the battle")
	s._destroy(m)
	check(not s.players[0].spells.has(axe) and s.players[0].gy.has(axe), "Equip card is destroyed with its monster")
	# Continuous Spell stays and locks attacks; upkeep is paid in the Standby Phase
	s = _main_ready(43)
	var strong := _fake(s, 0, "Strong", 1800, 0, 0)
	var weak := _fake(s, 0, "Weak", 1000, 0, 1)
	var peace := _st(s, 0, "Messenger of Peace")
	s.activate(0, peace)
	check(s.players[0].spells.has(peace) and peace.face_up, "Continuous Spell stays on the field")
	s.phase = DuelState.Phase.BATTLE
	check(not s.can_attack(0, strong) and s.can_attack(0, weak), "Messenger of Peace stops 1500+ ATK attackers")
	var lp := s.players[0].lp
	s.end_turn()
	s.begin_turn()
	s.end_turn()
	s.begin_turn()
	check(s.players[0].lp == lp - 100, "Messenger of Peace upkeep is paid")
	# Chain: Mystical Space Typhoon in response does not stop a Normal Spell, a Counter Trap does
	s = _main_ready(44)
	_fake(s, 1, "Victim", 1500, 0, 0)
	var ookazi := _st(s, 0, "Ookazi")
	var mst := _st(s, 1, "Mystical Space Typhoon", "set")
	lp = s.players[1].lp
	s.chain_add(0, ookazi)
	check(s.responses(1, "chain", s.chain.back()).has(mst), "Set Quick-Play Spell can be chained")
	s.chain_add(1, mst, ookazi, "chain", s.chain.back())
	check(s.chain.size() == 2, "Chain has two links")
	s.chain_resolve()
	check(s.players[1].lp == lp - 800 and s.players[0].gy.has(ookazi), "Chained MST does not negate a Normal Spell")
	s = _main_ready(45)
	var ookazi2 := _st(s, 0, "Ookazi")
	var jammer := _st(s, 1, "Magic Jammer", "set", "trap")
	s.players[1].hand.clear()
	_st(s, 1, "Fodder")
	lp = s.players[1].lp
	s.chain_add(0, ookazi2)
	check(s.responses(1, "chain", s.chain.back()).has(jammer), "Counter Trap can answer a Spell")
	s.chain_add(1, jammer, null, "chain", s.chain.back())
	s.chain_resolve()
	check(s.players[1].lp == lp and s.players[0].gy.has(ookazi2) and s.players[1].hand.is_empty(), "Magic Jammer negates the Spell (discard paid)")
	# Solemn Judgment negates a summon for half your Life Points
	s = _main_ready(46)
	var big := _fake(s, 0, "Big", 3000, 0, 0)
	big.summoned_turn = s.turn
	var solemn := _st(s, 1, "Solemn Judgment", "set", "trap")
	check(s.responses(1, "summon", big).has(solemn), "Solemn Judgment answers a summon")
	lp = s.players[1].lp
	s.chain_add(1, solemn, null, "summon", big)
	s.chain_resolve()
	check(not s.players[0].field.has(big) and s.players[1].lp == lp / 2, "Solemn Judgment negates the summon")
	# Quick-Play from the hand during your own Battle Phase
	s = _main_ready(47)
	var a1 := _fake(s, 0, "Attacker", 1500, 0, 0)
	var d1 := _fake(s, 1, "Wall", 2000, 0, 0)
	var rush := _st(s, 0, "Rush Recklessly")
	s.phase = DuelState.Phase.BATTLE
	s.declare_attack(0, a1, d1)
	check(s.responses(0, "attack").has(rush), "Quick-Play Spell from hand on your own turn")
	s.chain_add(0, rush, a1, "attack")
	s.chain_resolve()
	s.resolve_attack()
	check(not s.players[1].field.has(d1) and s.players[0].field.has(a1), "Rush Recklessly wins the battle")
	# Control: Change of Heart until the End Phase, Snatch Steal while equipped
	s = _main_ready(48)
	var prize := _fake(s, 1, "Prize", 2400, 0, 0)
	var coh := _st(s, 0, "Change of Heart")
	s.activate(0, coh, prize)
	check(s.players[0].field.has(prize) and not s.players[1].field.has(prize), "Change of Heart takes control")
	s.end_turn()
	check(s.players[1].field.has(prize) and prize.owner == 1, "The monster goes back at the End Phase")
	s = _main_ready(49)
	prize = _fake(s, 1, "Prize", 2400, 0, 0)
	var snatch := _st(s, 0, "Snatch Steal")
	s.activate(0, snatch, prize)
	check(s.players[0].field.has(prize), "Snatch Steal takes control")
	s._destroy_st(snatch)
	check(s.players[1].field.has(prize), "Control returns when Snatch Steal leaves")
	s = _main_ready(50)
	prize = _fake(s, 1, "Prize", 2400, 0, 0)
	s.activate(0, _st(s, 0, "Change of Heart"), prize)
	s._destroy(prize)
	check(s.players[1].gy.has(prize) and not s.players[0].gy.has(prize), "A borrowed monster goes to its owner's Graveyard")
	# Call of the Haunted
	s = _main_ready(51)
	var dead := _fake(s, 0, "Dead", 2500, 0, -1)
	s.players[0].gy.append(dead)
	var call := _st(s, 0, "Call of the Haunted", "set", "trap")
	check(s.can_activate(0, call), "A free Trap can be flipped in your own Main Phase")
	s.activate(0, call)
	check(s.players[0].field.has(dead) and s.players[0].spells.has(call), "Call of the Haunted revives and stays")
	s._destroy_st(call)
	check(not s.players[0].field.has(dead), "The revived monster dies with Call of the Haunted")
	# Royal Decree shuts off other Traps
	s = _main_ready(52)
	var decree := _st(s, 0, "Royal Decree", "set", "trap")
	s.activate(0, decree)
	var mf := _st(s, 1, "Mirror Force", "set", "trap")
	var att := _fake(s, 0, "Att", 2000, 0, 0)
	s.phase = DuelState.Phase.BATTLE
	s.declare_attack(0, att, null)
	check(not s.responses(1, "attack").has(mf), "Royal Decree blocks Mirror Force")
	s.resolve_attack()
	# Mirror Force through the chain
	s = _main_ready(53)
	mf = _st(s, 1, "Mirror Force", "set", "trap")
	att = _fake(s, 0, "Att", 2000, 0, 0)
	var att2 := _fake(s, 0, "Att2", 1000, 0, 1)
	s.phase = DuelState.Phase.BATTLE
	s.declare_attack(0, att, null)
	check(s.responses(1, "attack").has(mf), "Mirror Force answers an attack")
	lp = s.players[1].lp
	s.respond(1, mf)
	s.resolve_attack()
	check(s.players[0].monsters().is_empty() and s.players[1].lp == lp, "Mirror Force destroys attackers and stops the attack")
	# Ritual Summon
	s = _main_ready(54)
	s.players[0].hand.clear()
	var rit := _fake(s, 0, "Relinquished", 0, 0, -1, {"frame": "ritual", "level": 1, "desc": "You can Ritual Summon this card with \"Black Illusion Ritual\"."})
	s.players[0].hand.append(rit)
	var fod := _fake(s, 0, "Fodder", 500, 0, -1, {"level": 2})
	s.players[0].hand.append(fod)
	var rs := _st(s, 0, "Black Illusion Ritual", "hand", "spell", {"st": "ritual"})
	check(s.can_activate(0, rs), "Ritual Spell is playable")
	s.activate(0, rs)
	check(s.players[0].field.has(rit) and s.players[0].gy.has(fod), "Ritual Summon tributes and summons")
	# Exodia
	s = _main_ready(55)
	s.players[0].hand.clear()
	for n in DuelState.EXODIA.slice(0, 4):
		s.players[0].hand.append(_fake(s, 0, n, 200, 300, -1))
	s.players[0].deck.append(_fake(s, 0, DuelState.EXODIA[4], 200, 300, -1))
	s._draw(0)
	check(s.is_over() and s.winner == 0, "Exodia wins the duel")
	# Assorted cards
	s = _main_ready(56)
	var up := _fake(s, 1, "Up", 1800, 500, 0)
	s.activate(0, _st(s, 0, "Book of Moon"), up)
	check(not up.face_up and not up.attack_pos, "Book of Moon flips a monster face-down")
	_st(s, 1, "SetA", "set", "trap")
	_st(s, 0, "SetB", "set", "trap")
	s.activate(0, _st(s, 0, "Heavy Storm"))
	check(s.players[0].set_cards().is_empty() and s.players[1].set_cards().is_empty(), "Heavy Storm clears every Spell/Trap")
	s = _main_ready(57)
	var ringed := _fake(s, 1, "Ringed", 2000, 0, 0)
	var ring := _st(s, 0, "Ring of Destruction", "set", "trap")
	var lp0 := s.players[0].lp
	lp = s.players[1].lp
	check(not s.can_activate(0, ring), "Ring of Destruction cannot be used on your own turn")
	s.current = 1
	check(SpellRules.fits(s, 0, ring, "phase", null), "Ring of Destruction fits during the opponent's turn")
	s.chain_add(0, ring, ringed, "phase", null)
	s.chain_resolve()
	check(not s.players[1].field.has(ringed) and s.players[0].lp == lp0 - 2000 and s.players[1].lp == lp - 2000, "Ring of Destruction burns both players")
	s = _main_ready(58)
	var bnc := _fake(s, 1, "Bounce", 2000, 0, 0)
	s.activate(0, _st(s, 0, "Compulsory Evacuation Device", "set", "trap"), bnc)
	check(s.players[1].hand.has(bnc), "Compulsory Evacuation Device returns a monster to the hand")
	var hs := s.players[0].hand.size()
	s.activate(0, _st(s, 0, "Graceful Charity"))
	check(s.players[0].hand.size() == hs + 1, "Graceful Charity: draw 3, discard 2")
	# Derived Equip / Field text, clone keeps everything
	s = _main_ready(59)
	var eq := _st(s, 0, "Test Blade", "hand", "spell", {"st": "equip", "desc": "The equipped monster gains 600 ATK."})
	var hero := _fake(s, 0, "Hero", 1000, 0, 0)
	s.activate(0, eq, hero)
	check(s.atk_of(hero, false) == 1600, "Equip Spells are read from their card text")
	var fs := _st(s, 0, "Test Land", "hand", "spell", {"st": "field", "desc": "All Warrior monsters on the field gain 300 ATK."})
	s.activate(0, fs)
	check(s.atk_of(hero, false) == 1900, "Field Spells are read from their card text")
	var cl := s.clone()
	check(cl.atk_of(cl.players[0].field[0], false) == 1900 and cl.players[0].field_spell != null, "Clone keeps equips and the Field Spell")
	print("spell rules tests done")


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


## The duel screen's way of running an action: try it on a copy, answer each choice, replay.
## `pick` gets the need and returns card uids (or [index] for an option).
## v0.22: nothing is chosen for the player, and cards only work at their own moment.
func _test_choices() -> void:
	# Enemy Controller: asks which effect, then which target
	var s := _main_ready(81)
	s.manual = [true, false]
	var a := _fake(s, 1, "Foe A", 1800, 1000, 0)
	var b := _fake(s, 1, "Foe B", 2400, 1000, 1)
	var mine := _fake(s, 0, "Mine", 500, 500, 0)
	var ec := _st(s, 0, "Enemy Controller")
	var needs := []
	_decide(s, func(st): return st.activate(0, st.find_uid(ec.uid)), func(need):
		needs.append(need)
		return [0] if need.has("options") else [b.uid])
	check(needs.size() == 2 and needs[0].has("options") and (needs[0]["options"] as Array).size() == 2, "Enemy Controller asks which effect, then the target (asked %d)" % needs.size())
	check(not b.attack_pos and a.attack_pos, "Enemy Controller changes the position of the chosen monster")
	# The other effect: Tribute, then take control until the End Phase
	s = _main_ready(82)
	s.manual = [true, false]
	a = _fake(s, 1, "Foe A", 1800, 1000, 0)
	mine = _fake(s, 0, "Mine", 500, 500, 0)
	ec = _st(s, 0, "Enemy Controller")
	needs = []
	_decide(s, func(st): return st.activate(0, st.find_uid(ec.uid)), func(need):
		needs.append(need)
		if need.has("options"):
			return [1]
		return [need["cands"][0]])
	check(s.players[0].field.has(a) and s.players[0].gy.has(mine), "Enemy Controller's second effect Tributes and takes control")
	check(needs.size() == 3, "Enemy Controller (control) asks effect, target and the Tribute (asked %d)" % needs.size())
	# With no monster to Tribute only the first effect is offered
	s = _main_ready(83)
	a = _fake(s, 1, "Foe A", 1800, 1000, 0)
	ec = _st(s, 0, "Enemy Controller")
	check(SpellRules.open_modes(s, 0, ec, "open", null) == [0], "Enemy Controller: no Tribute, no second effect")
	# A lone target still asks
	s = _main_ready(84)
	s.manual = [true, false]
	a = _fake(s, 1, "Only", 1800, 1000, 0)
	var mst := _st(s, 0, "Book of Moon")
	needs = []
	_decide(s, func(st): return st.activate(0, st.find_uid(mst.uid)), func(need):
		needs.append(need)
		return [a.uid])
	check(needs.size() == 1 and not a.face_up, "A card with one possible target still asks for it")
	# Ego Boost: when a monster declares an attack (not in the Main Phase)
	s = _main_ready(85)
	mine = _fake(s, 0, "Mine", 1500, 500, 0)
	var ego := _st(s, 0, "Ego Boost")
	check(not s.can_activate(0, ego), "Ego Boost cannot be activated in the Main Phase")
	s.phase = DuelState.Phase.BATTLE
	s.declare_attack(0, mine, null)
	check(SpellRules.fits(s, 0, ego, "attack", null), "Ego Boost fits when your monster attacks directly")
	s = _main_ready(86)
	mine = _fake(s, 0, "Mine", 1500, 500, 0)
	a = _fake(s, 1, "Foe", 1000, 500, 0)
	ego = _st(s, 0, "Ego Boost")
	s.phase = DuelState.Phase.BATTLE
	s.declare_attack(0, mine, a)
	check(SpellRules.fits(s, 0, ego, "attack", null), "Ego Boost fits when any monster declares an attack")
	# Smashing Ground: a tie is the player's choice
	s = _main_ready(87)
	s.manual = [true, false]
	a = _fake(s, 1, "Wall A", 1000, 2000, 0)
	b = _fake(s, 1, "Wall B", 500, 2000, 1)
	var sg := _st(s, 0, "Smashing Ground")
	needs = []
	_decide(s, func(st): return st.activate(0, st.find_uid(sg.uid)), func(need):
		needs.append(need)
		return [b.uid])
	check(needs.size() == 1 and s.players[1].gy.has(b) and s.players[1].field.has(a), "Smashing Ground asks when the highest DEF is tied")
	# Traps and Quick-Plays cannot be used the turn they were Set
	s = _main_ready(88)
	a = _fake(s, 1, "Foe", 1800, 1000, 0)
	var jar := _st(s, 0, "Jar of Greed", "set", "trap")
	jar.set_turn = s.turn
	check(not s.can_activate(0, jar), "A Trap cannot be activated the turn it was Set")
	jar.set_turn = s.turn - 1
	check(s.can_activate(0, jar), "A Trap Set last turn can be activated")
	var bm := _st(s, 0, "Book of Moon", "set")
	bm.set_turn = s.turn
	check(not s.can_activate(0, bm), "A Quick-Play Spell cannot be activated the turn it was Set")
	# First turn: no Battle Phase
	s = _new_state(89)
	s.begin_turn()
	check(not s.can_enter_battle(), "No Battle Phase on the first turn of the duel")
	# One Normal Summon or Set per turn; a summoned monster cannot change position that turn
	s = _main_ready(90)
	var h1 := _fake(s, 0, "H1", 1000, 1000, -1)
	var h2 := _fake(s, 0, "H2", 1000, 1000, -1)
	s.players[0].hand.append(h1)
	s.players[0].hand.append(h2)
	s.normal_summon(0, h1, [], false)
	check(not s.can_normal_summon(0, h2), "Only one Normal Summon or Set per turn")
	check(not s.can_change_position(0, h1), "A monster cannot change position the turn it was summoned")
	# A Set monster cannot be Flip Summoned the same turn
	s = _main_ready(91)
	h1 = _fake(s, 0, "H1", 1000, 1000, -1)
	s.players[0].hand.append(h1)
	s.normal_summon(0, h1, [], true)
	check(not s.can_flip_summon(0, h1), "A monster Set this turn cannot be Flip Summoned")
	# A monster that attacked cannot change position; one that changed position can still attack
	s = _main_ready(92)
	mine = _fake(s, 0, "Mine", 1500, 500, 0)
	mine.summoned_turn = 1
	a = _fake(s, 1, "Foe", 1000, 500, 0)
	s.phase = DuelState.Phase.BATTLE
	s.attack(0, mine, a)
	s.phase = DuelState.Phase.MAIN2
	check(not s.can_change_position(0, mine), "A monster that attacked cannot change position in Main Phase 2")
	# Defense Position monsters cannot attack
	s = _main_ready(93)
	mine = _fake(s, 0, "Mine", 1500, 500, 0)
	mine.attack_pos = false
	s.phase = DuelState.Phase.BATTLE
	check(not s.can_attack(0, mine), "A Defense Position monster cannot attack")
	# No direct attack while they have a monster
	s = _main_ready(94)
	mine = _fake(s, 0, "Mine", 1500, 500, 0)
	a = _fake(s, 1, "Foe", 1000, 500, 0)
	s.phase = DuelState.Phase.BATTLE
	check(not s.can_direct_attack(0), "No direct attack while the opponent controls a monster")
	# Attacking a Defense Position monster with higher DEF: the attacker takes the difference, nothing dies
	s = _main_ready(95)
	mine = _fake(s, 0, "Mine", 1500, 500, 0)
	a = _fake(s, 1, "Wall", 0, 2000, 0)
	a.attack_pos = false
	s.phase = DuelState.Phase.BATTLE
	var lp0: int = s.players[0].lp
	s.attack(0, mine, a)
	check(s.players[0].lp == lp0 - 500 and s.players[0].field.has(mine) and s.players[1].field.has(a), "Attacking into higher DEF costs the difference and destroys nothing")
	# Equal ATK in Attack Position: both are destroyed, no damage
	s = _main_ready(96)
	mine = _fake(s, 0, "Mine", 1500, 500, 0)
	a = _fake(s, 1, "Foe", 1500, 500, 0)
	s.phase = DuelState.Phase.BATTLE
	lp0 = s.players[0].lp
	var lp1: int = s.players[1].lp
	s.attack(0, mine, a)
	check(not s.players[0].field.has(mine) and not s.players[1].field.has(a) and s.players[0].lp == lp0 and s.players[1].lp == lp1, "Equal ATK: both destroyed, no damage")
	# Destroying a Defense Position monster deals no damage
	s = _main_ready(97)
	mine = _fake(s, 0, "Mine", 2000, 500, 0)
	a = _fake(s, 1, "Wall", 0, 1000, 0)
	a.attack_pos = false
	s.phase = DuelState.Phase.BATTLE
	lp1 = s.players[1].lp
	s.attack(0, mine, a)
	check(s.players[1].lp == lp1 and not s.players[1].field.has(a), "Destroying a Defense Position monster deals no battle damage")
	# Level 5-6 need one Tribute, 7 and up need two
	s = _main_ready(98)
	var lv6 := _fake(s, 0, "Six", 2400, 1000, -1, {"level": 6})
	var lv8 := _fake(s, 0, "Eight", 3000, 2500, -1, {"level": 8})
	check(s.tributes_needed(lv6) == 1 and s.tributes_needed(lv8) == 2, "Tribute counts: 1 for Level 5-6, 2 for Level 7+")
	# Decking out loses the duel
	s = _main_ready(99)
	s.players[1].deck.clear()
	s.current = 0
	s.end_turn()
	s.begin_turn()
	check(s.is_over() and s.winner == 0, "A player who cannot draw loses")


func _decide(s: DuelState, fn: Callable, pick: Callable) -> Array:
	var answers: Array = []
	for guard in 30:
		var sim := s.clone()
		sim.manual = s.manual.duplicate()
		sim.answers = answers.duplicate(true)
		fn.call(sim)
		if sim.need == null:
			break
		answers.append(pick.call(sim.need))
	s.answers = answers
	s.need = null
	var ev: Array = fn.call(s)
	s.answers = []
	return ev


func _test_full_rules() -> void:
	# Hand limit: the player picks the discard, not the rules
	var s := _main_ready(71)
	s.manual = [true, false]
	s.players[0].hand.clear()
	var hand: Array = []
	for i in 8:
		hand.append(_fake(s, 0, "H%d" % i, 1000 + i * 100, 1000, -1))
		s.players[0].hand.append(hand[i])
	var asked := []
	_decide(s, func(st): return st.end_turn(), func(need):
		asked.append(need)
		return [hand[7].uid, hand[6].uid])
	check(asked.size() == 1 and asked[0]["n"] == 2, "Hand limit asks for 2 discards")
	check(s.players[0].gy.has(hand[7]) and s.players[0].gy.has(hand[6]) and s.players[0].hand.has(hand[0]), "Hand limit discards the cards the player chose")
	# Monster Reborn: choose which monster, and its position
	s = _main_ready(72)
	s.manual = [true, false]
	var big := _fake(s, 0, "Big", 3000, 1000, -1)
	var small := _fake(s, 1, "Small", 500, 1000, -1)
	s.players[0].gy.append(big)
	s.players[1].gy.append(small)
	var reborn := _st(s, 0, "Monster Reborn", "hand", "spell", {"effect": "reborn"})
	var needs := []
	_decide(s, func(st): return st.activate(0, st.find_uid(reborn.uid)), func(need):
		needs.append(need)
		return [1] if need.has("options") else [small.uid])
	check(s.players[0].field.has(small) and not small.attack_pos, "Monster Reborn brings back the chosen monster in the chosen position")
	check(needs.size() == 2, "Monster Reborn asks for the monster and the position (asked %d)" % needs.size())
	# Extra Deck monsters only come back if they were properly summoned
	s = _main_ready(73)
	var fus := _fake(s, 0, "Fusion Guy", 2800, 2000, -1, {"frame": "fusion"})
	s.players[0].gy.append(fus)
	check(not s.can_revive(fus), "A Fusion Monster that was never Fusion Summoned cannot be revived")
	fus.proper = true
	check(s.can_revive(fus), "A properly summoned Fusion Monster can be revived")
	var rit := _fake(s, 0, "Ritual Guy", 2000, 2000, -1, {"frame": "ritual", "level": 4})
	s.players[0].hand.append(rit)
	check(not s.can_normal_summon(0, rit), "Ritual Monsters cannot be Normal Summoned")
	var nomi := _fake(s, 0, "Nomi", 2000, 2000, -1, {"desc": "Cannot be Normal Summoned/Set. Must first be Special Summoned."})
	s.players[0].hand.append(nomi)
	check(not s.can_normal_summon(0, nomi), "'Cannot be Normal Summoned' monsters cannot be Normal Summoned")
	# Monster effects use the chain when deferred, and can be negated there
	s = _main_ready(74)
	s.defer_fx = true
	var prize := _st(s, 1, "Waboku", "set", "trap")
	var bug := _fake(s, 0, "Granmarg the Rock Monarch", 2400, 1000, -1)
	s.players[0].hand.append(bug)
	s.normal_summon(0, bug, [])
	check(s.players[1].spells.has(prize) and s.pending_fx.size() == 1, "A summon effect waits to go on the chain")
	s.fx_to_chain()
	check(s.chain.size() == 1 and s.chain[0]["kind"] == "fx", "The effect is a chain link")
	var wrath := _st(s, 1, "Divine Wrath", "set", "trap")
	s.players[1].hand.append(_fake(s, 1, "Fodder", 100, 100, -1))
	check(s.responses(1, "chain", s.chain.back()).has(wrath), "Divine Wrath can answer a monster effect")
	s.chain_add(1, wrath, null, "chain", s.chain.back())
	check(not SpellRules.fits(s, 0, _st(s, 0, "Mystical Space Typhoon", "set", "spell"), "chain", s.chain.back()), "Only a Counter Trap can answer a Counter Trap")
	s.chain_resolve()
	check(s.players[1].spells.has(prize) and not s.players[0].field.has(bug), "Divine Wrath negates the effect and destroys the monster")
	# Without a negation the deferred effect resolves on the chain
	s = _main_ready(741)
	s.defer_fx = true
	prize = _st(s, 1, "Waboku", "set", "trap")
	bug = _fake(s, 0, "Granmarg the Rock Monarch", 2400, 1000, -1)
	s.players[0].hand.append(bug)
	s.normal_summon(0, bug, [])
	s.fx_to_chain()
	s.chain_resolve()
	check(not s.players[1].spells.has(prize), "The effect resolves when the chain does")
	# Tokens
	s = _main_ready(75)
	var goat := _st(s, 0, "Scapegoat")
	s.activate(0, goat)
	var toks: Array = s.players[0].monsters()
	check(toks.size() == 4 and toks[0].is_token() and not toks[0].attack_pos, "Scapegoat makes 4 Sheep Tokens in Defense Position")
	var gy0 := s.players[0].gy.size()
	s._destroy(toks[0])
	check(s.players[0].gy.size() == gy0 and s.players[0].monsters().size() == 3, "A destroyed Token does not go to the Graveyard")
	var boss := _fake(s, 0, "Boss", 2500, 2000, -1, {"level": 6})
	s.players[0].hand.append(boss)
	s.turn += 2
	check(not s.can_normal_summon(0, boss), "Sheep Tokens cannot be Tributed for a Tribute Summon")
	# Skill Drain
	s = _main_ready(76)
	var eff := _fake(s, 0, "Luster Dragon", 1900, 1600, 0)
	var drain := _st(s, 0, "Skill Drain", "set", "trap")
	s.activate(0, drain)
	check(s.players[0].lp == 7000 and eff.negated, "Skill Drain costs 1000 and negates face-up monsters")
	check(EffectRunner.fx(eff).is_empty(), "A negated monster has no effects")
	s._destroy_st(drain)
	s._cleanup()
	check(not eff.negated, "Effects return when Skill Drain leaves")
	# Replay
	s = _main_ready(77)
	s.phase = DuelState.Phase.BATTLE
	var atk := _fake(s, 0, "Attacker", 2000, 1000, 0)
	var d1 := _fake(s, 1, "D1", 1000, 1000, 0)
	s.declare_attack(0, atk, d1)
	check(not s.replay_needed(), "No replay while nothing changed")
	var d2 := _fake(s, 1, "D2", 500, 1000, 1)
	check(s.replay_needed(), "A new monster on the defender's side causes a replay")
	s.replay_attack(d2)
	s.resolve_attack()
	check(not s.players[1].field.has(d2) and s.players[1].field.has(d1), "The replayed attack hits the new target")
	# Damage Step: only ATK / DEF changers
	s = _main_ready(78)
	s.phase = DuelState.Phase.BATTLE
	var a2 := _fake(s, 0, "A2", 1500, 1000, 0)
	var b2 := _fake(s, 1, "B2", 1800, 1000, 0)
	var rush := _st(s, 0, "Rush Recklessly", "set", "spell")
	var typhoon := _st(s, 0, "Mystical Space Typhoon", "set", "spell")
	_st(s, 1, "Waboku", "set", "trap")
	s.declare_attack(0, a2, b2)
	var dmg_opts := s.responses(0, "damage")
	check(dmg_opts.has(rush) and not dmg_opts.has(typhoon), "Damage Step allows Rush Recklessly but not Mystical Space Typhoon")
	# A draw
	s = _main_ready(79)
	s.players[0].lp = 500
	s.players[1].lp = 500
	s._damage(0, 1000)
	s._damage(1, 1000)
	check(s.winner == DuelState.DRAW, "Both players at 0 in the same resolution is a draw")
	# Phases one at a time
	s = _new_state(80)
	s.begin_turn(true)
	check(s.phase == DuelState.Phase.DRAW, "Stepped turn stops in the Draw Phase")
	s.begin_standby()
	check(s.phase == DuelState.Phase.STANDBY, "Then the Standby Phase")
	s.begin_main1()
	check(s.phase == DuelState.Phase.MAIN1, "Then Main Phase 1")
	# Mirror Force does not stop a monster that Traps cannot touch
	s = _main_ready(81)
	s.phase = DuelState.Phase.BATTLE
	var wild := _fake(s, 0, "Elemental HERO Wildheart", 1500, 1600, 0)
	var other := _fake(s, 0, "Other", 1500, 1000, 1)
	var prey := _fake(s, 1, "Prey", 1000, 1000, 0)
	var mf := _st(s, 1, "Mirror Force", "set", "trap")
	s.declare_attack(0, wild, prey)
	s.chain_add(1, mf, null, "attack", null)
	s.chain_resolve()
	s.resolve_attack()
	check(s.players[0].field.has(wild) and not s.players[0].field.has(other) and not s.players[1].field.has(prey), "Wildheart survives Mirror Force and finishes its attack")
	print("full rules tests done")


## The Toons, to their printed text: Toon World, who may come out, who may attack whom, the toll.
func _test_toons() -> void:
	var s := _main_ready(801)
	var tw := _st(s, 0, "Toon World")
	var mer := _fake(s, 0, "Toon Mermaid", 1400, 1500, -1)
	s.players[0].hand.append(mer)
	var skull := _fake(s, 0, "Toon Summoned Skull", 2500, 1200, -1, {"level": 6})
	s.players[0].hand.append(skull)
	check(not s.can_special_from_hand(0, mer), "Toon Mermaid stays in the hand without Toon World")
	var lp0: int = s.players[0].lp
	_run(s, 0, {"do": "activate", "card": tw})
	check(s.players[0].lp == lp0 - 1000, "Toon World costs 1000 LP to activate")
	check(s.toon_world(0) and not s.toon_world(1), "Toon World is face-up on its owner's side only")
	check(s.can_special_from_hand(0, mer), "With Toon World out, Toon Mermaid can be Special Summoned from the hand")
	check(not s.can_special_from_hand(0, skull), "Toon Summoned Skull needs a monster to Tribute")
	_run(s, 0, {"do": "special_hand", "card": mer})
	check(s.players[0].field.has(mer), "Toon Mermaid arrives")
	check(s.can_special_from_hand(0, skull), "Now there is a Tribute for Toon Summoned Skull")
	var wall := _fake(s, 1, "Wall", 2000, 2000, 0)
	s.phase = DuelState.Phase.BATTLE
	check(not s.can_attack(0, mer), "Toon Mermaid cannot attack the turn it is Special Summoned")
	mer.summoned_turn = s.turn - 2
	check(s.can_attack(0, mer) and s.can_direct_attack_with(0, mer), "Later it attacks directly, past their monster")
	var mine: int = s.players[0].lp
	var theirs: int = s.players[1].lp
	s.attack(0, mer, null)
	check(s.players[0].lp == mine - 500, "Toon Mermaid pays 500 LP to declare its attack")
	check(s.players[1].lp == theirs - 1400, "and hits directly for 1400")
	# A Toon across the table: the big Toons must attack it and nothing else.
	var gator := _fake(s, 1, "Toon Alligator", 800, 1600, 1, {"frame": "normal"})
	mer.attack_count = 0
	mer.attacked_turn = -1
	check(not s.can_direct_attack_with(0, mer), "With a Toon across the table, no direct attack")
	check(s.attack_targets_for(0, mer).size() == 1 and s.attack_targets_for(0, mer)[0] == gator, "It may only attack the Toon")
	check(s.declare_attack(0, mer, wall).is_empty(), "An attack on the non-Toon is refused")
	# The small Toons need their own Toon World to go direct.
	var elf := _fake(s, 0, "Toon Gemini Elf", 1900, 900, 2)
	elf.summoned_turn = s.turn - 2
	s.players[1].field[1] = null
	check(s.can_direct_attack_with(0, elf), "Toon Gemini Elf attacks directly with Toon World out and no Toon across the table")
	var elf2 := _fake(s, 1, "Toon Gemini Elf", 1900, 900, 3)
	check(not s.can_direct_attack_with(0, elf), "but not when the other side has a Toon")
	s.players[1].field[3] = null
	# No toll, no attack.
	s.players[0].lp = 400
	check(not s.can_attack(0, mer), "Toon Mermaid cannot attack without 500 LP to pay")
	s.players[0].lp = 4000
	# Toon World destroyed: every Toon that says so goes with it.
	s._destroy_st(tw)
	check(s.players[0].gy.has(mer) and s.players[0].gy.has(elf), "When Toon World is destroyed the Toons are destroyed")
	check(s.players[1].field.has(wall), "and nothing else is")
	# Toon Cannon Soldier: Tribute any monster, as often as there are monsters.
	s = _main_ready(802)
	var cannon := _fake(s, 0, "Toon Cannon Soldier", 1400, 1300, 0)
	var fodder := _fake(s, 0, "Fodder", 300, 300, 1)
	var before: int = s.players[1].lp
	check(s.can_ignite(0, cannon), "Toon Cannon Soldier can fire")
	_run(s, 0, {"do": "ignite", "card": cannon})
	check(s.players[1].lp == before - 500 and s.players[0].gy.has(fodder), "It Tributes a monster for 500 damage")
	check(s.can_ignite(0, cannon), "and can fire again the same turn (no once per turn on the card)")
	_run(s, 0, {"do": "ignite", "card": cannon})
	check(s.players[1].lp == before - 1000 and s.players[0].gy.has(cannon), "The second shot Tributes itself")


## X, Y and Z: Union equips, the stand-in rule, and XYZ-Dragon Cannon by banishing all three.
func _test_unions() -> void:
	var s := _main_ready(811)
	var x := _fake(s, 0, "X-Head Cannon", 1800, 1500, 0, {"frame": "normal"})
	var y := _fake(s, 0, "Y-Dragon Head", 1500, 1600, 1)
	var z := _fake(s, 0, "Z-Metal Tank", 1500, 1300, 2)
	check(s.can_ignite(0, y), "Y-Dragon Head can equip to X-Head Cannon")
	_run(s, 0, {"do": "ignite", "card": y})
	check(s.players[0].spells.has(y) and y.equipped_to == x and not s.players[0].field.has(y), "Y-Dragon Head becomes an Equip Card on X-Head Cannon")
	check(s.atk_of(x, false) == 2200 and s.def_of(x) == 1900, "X-Head Cannon gains 400 ATK and DEF")
	check(not s.can_ignite(0, y), "Once per turn: it cannot come straight back off")
	# The equipped monster would be destroyed: the Union goes instead.
	s._destroy(x)
	check(s.players[0].field.has(x) and s.players[0].gy.has(y), "Y-Dragon Head is destroyed in place of X-Head Cannon")
	check(s.atk_of(x, false) == 1800, "and the bonus is gone with it")
	# Z rides, then comes off again next turn.
	_run(s, 0, {"do": "ignite", "card": z})
	check(z.equipped_to == x and s.atk_of(x, false) == 2400, "Z-Metal Tank gives 600")
	z.ignite_turn = -1
	check(s.can_ignite(0, z), "Next turn Z-Metal Tank can be taken off")
	_run(s, 0, {"do": "ignite", "card": z})
	check(s.players[0].field.has(z) and z.equipped_to == null and s.atk_of(x, false) == 1800, "Z-Metal Tank is Special Summoned back and the bonus ends")
	# XYZ-Dragon Cannon: banish the three you control, one of them riding as an Equip Card.
	s = _main_ready(812)
	x = _fake(s, 0, "X-Head Cannon", 1800, 1500, 0, {"frame": "normal"})
	y = _fake(s, 0, "Y-Dragon Head", 1500, 1600, 1)
	z = _fake(s, 0, "Z-Metal Tank", 1500, 1300, 2)
	var xyz := _fake(s, 0, "XYZ-Dragon Cannon", 2800, 2600, -1, {"frame": "fusion", "level": 8})
	s.players[0].extra.append(xyz)
	_run(s, 0, {"do": "ignite", "card": z})
	check(s.can_extra_summon(0, xyz), "XYZ-Dragon Cannon can be called with X, Y and an equipped Z")
	_run(s, 0, {"do": "extra", "card": xyz})
	check(s.players[0].field.has(xyz), "XYZ-Dragon Cannon arrives")
	check(s.players[0].banished.has(x) and s.players[0].banished.has(y) and s.players[0].banished.has(z), "X, Y and Z are banished, not sent to the Graveyard")
	# Its effect: discard 1, destroy any 1 card of theirs, as often as you can pay.
	var foe := _fake(s, 1, "Foe", 3000, 3000, 0)
	var trap := _st(s, 1, "Mirror Force", "set", "trap")
	s.players[0].hand.clear()
	s.players[0].hand.append(_fake(s, 0, "Junk A", 100, 100, -1))
	s.players[0].hand.append(_fake(s, 0, "Junk B", 100, 100, -1))
	_run(s, 0, {"do": "ignite", "card": xyz})
	check(s.players[1].gy.has(foe), "XYZ-Dragon Cannon discards 1 and destroys their monster")
	check(s.can_ignite(0, xyz), "and can do it again the same turn")
	_run(s, 0, {"do": "ignite", "card": xyz})
	check(s.players[1].gy.has(trap) and s.players[0].hand.is_empty(), "The second discard destroys their Set card")


## Destiny HERO - Disk Commander and Malicious, and the Cyber Angels' Tribute effects.
func _test_heroes_angels() -> void:
	# Malicious: banish it from the Graveyard, another one comes from the Deck.
	var s := _main_ready(821)
	var mal := _fake(s, 0, "Destiny HERO - Malicious", 800, 800, -1, {"level": 6})
	var mal2 := _fake(s, 0, "Destiny HERO - Malicious", 800, 800, -1, {"level": 6})
	s.players[0].gy.append(mal)
	s.players[0].deck.append(mal2)
	check(s.gy_effects(0).has(mal), "Malicious in the Graveyard can use its effect")
	_run(s, 0, {"do": "gy_ignite", "card": mal})
	check(s.players[0].banished.has(mal) and s.players[0].field.has(mal2), "Malicious is banished and another is Special Summoned from the Deck")
	check(s.gy_effects(0).is_empty(), "With no Malicious left in the Graveyard there is nothing to use")
	# Disk Commander: not the turn it went to the Graveyard; revived, it draws 2, once per Duel.
	s = _main_ready(822)
	var disk := _fake(s, 0, "Destiny HERO - Disk Commander", 300, 300, 0, {"level": 1})
	s._destroy(disk)
	check(not s.can_revive(disk), "Disk Commander cannot come back the turn it was sent to the Graveyard")
	disk.gy_turn = s.turn - 1
	check(s.can_revive(disk), "A later turn it can")
	var hand0: int = s.players[0].hand.size()
	s.players[0].gy.erase(disk)
	s._special(0, disk, "reborn")
	check(s.players[0].hand.size() == hand0 + 2, "Special Summoned from the Graveyard, Disk Commander draws 2")
	s.players[0].field[s.players[0].field.find(disk)] = null
	s._special(0, disk, "reborn")
	check(s.players[0].hand.size() == hand0 + 2, "Only once per Duel")
	var disk2 := _fake(s, 0, "Destiny HERO - Disk Commander", 300, 300, -1, {"level": 1})
	s._special(0, disk2, "effect")
	check(s.players[0].hand.size() == hand0 + 2, "and not when it is Special Summoned from somewhere else")
	# Cyber Angel Idaten Tributed: every Ritual Monster you control gains 1000 ATK and DEF.
	s = _main_ready(823)
	var ida := _fake(s, 0, "Cyber Angel Idaten", 1600, 2000, 0, {"frame": "ritual", "level": 6})
	var dak := _fake(s, 0, "Cyber Angel Dakini", 2700, 2400, 1, {"frame": "ritual", "level": 8})
	s.players[0].field[0] = null
	s._to_gy(s.players[0], ida)
	EffectRunner.trigger(s, ida, "tributed")
	check(s.atk_of(dak, false) == 3700 and s.def_of(dak) == 3400, "Idaten Tributed: Dakini gains 1000 ATK and DEF")
	# Dakini: every Ritual Monster you control pierces; the opponent gives up a monster of their choice.
	check(EffectRunner.piercing(s, 0, dak), "Dakini gives your Ritual Monsters piercing")
	var plain := _fake(s, 0, "Plain", 1000, 1000, 2)
	check(not EffectRunner.piercing(s, 0, plain), "but not your other monsters")
	var a := _fake(s, 1, "Strong", 2600, 2000, 0)
	var b := _fake(s, 1, "Weak", 400, 400, 1)
	EffectRunner.trigger(s, dak, "ritual_summoned")
	check(s.players[1].gy.has(b) and s.players[1].field.has(a), "Dakini Ritual Summoned: the opponent sends a monster of their choice to the Graveyard")
	# Benten Tributed: a LIGHT Fairy from the Deck.
	var ben := _fake(s, 0, "Cyber Angel Benten", 1800, 1500, -1, {"frame": "ritual", "level": 6})
	var fairy := _fake(s, 0, "Shining Friend", 1300, 1100, -1, {"attribute": "LIGHT", "race": "Fairy"})
	s.players[0].deck.append(fairy)
	s._to_gy(s.players[0], ben)
	EffectRunner.trigger(s, ben, "tributed")
	check(s.players[0].hand.has(fairy), "Benten Tributed: a LIGHT Fairy monster comes from the Deck")


## Quillbolt Hedgehog, Stygian Street Patrol, the two Synchro helpers, Galaxy Soldier and Knight,
## Max Warrior and Twin-Sword Marauder, to their printed text.
func _test_batch_31() -> void:
	# Quillbolt Hedgehog: back from the Graveyard only beside a Tuner; banished when it leaves.
	var s := _main_ready(831)
	var hog := _fake(s, 0, "Quillbolt Hedgehog", 800, 800, -1, {"level": 2})
	s.players[0].gy.append(hog)
	check(not s.gy_effects(0).has(hog), "Quillbolt Hedgehog stays in the Graveyard with no Tuner")
	_fake(s, 0, "Tuner", 500, 500, 0, {"tuner": true, "level": 3})
	check(s.gy_effects(0).has(hog), "With a Tuner it can come back")
	_run(s, 0, {"do": "gy_ignite", "card": hog})
	check(s.players[0].field.has(hog), "Quillbolt Hedgehog is Special Summoned from the Graveyard")
	s._destroy(hog)
	check(s.players[0].banished.has(hog) and not s.players[0].gy.has(hog), "and it is banished when it leaves the field")
	# Stygian Street Patrol: burn by the original Level; from the Graveyard it calls a Fiend from the hand.
	s = _main_ready(832)
	s.phase = DuelState.Phase.BATTLE
	var pat := _fake(s, 0, "Stygian Street Patrol", 1600, 1200, 0, {"race": "Fiend", "attribute": "DARK"})
	var six := _fake(s, 1, "Six Stars", 1000, 1000, 0, {"level": 6})
	var lp1: int = s.players[1].lp
	s.attack(0, pat, six)
	check(s.players[1].lp == lp1 - 600 - 600, "Stygian Street Patrol: 600 battle damage, then 600 for a Level 6")
	s = _main_ready(833)
	pat = _fake(s, 0, "Stygian Street Patrol", 1600, 1200, -1, {"race": "Fiend", "attribute": "DARK"})
	s.players[0].gy.append(pat)
	var big := _fake(s, 0, "Big Fiend", 2400, 1000, -1, {"race": "Fiend", "level": 6})
	s.players[0].hand = [big]
	check(not s.gy_effects(0).has(pat), "Stygian Street Patrol: a Fiend over 2000 ATK does not count")
	var imp := _fake(s, 0, "Imp", 2000, 0, -1, {"race": "Fiend", "level": 6})
	s.players[0].hand.append(imp)
	check(s.gy_effects(0).has(pat), "A Fiend with 2000 ATK does")
	_run(s, 0, {"do": "gy_ignite", "card": pat})
	check(s.players[0].banished.has(pat) and s.players[0].field.has(imp) and s.players[0].hand.has(big), "Patrol is banished and the Fiend comes from the hand")
	# Nitro Synchron draws only for a "Nitro" Synchro; Sinister Sprocket only for a DARK one.
	for round in 2:
		s = _main_ready(834 + round)
		var nit := _fake(s, 0, "Nitro Synchron", 300, 100, 0, {"tuner": true, "level": 2})
		_fake(s, 0, "Four", 1000, 1000, 1, {"level": 4})
		var syn := _fake(s, 0, "Nitro Something" if round == 0 else "Plain Synchro", 2400, 1800, -1, {"frame": "synchro", "level": 6})
		s.players[0].extra = [syn]
		var h0: int = s.players[0].hand.size()
		check(s.can_extra_summon(0, syn), "The test Synchro can be made")
		s.extra_summon(0, syn)
		check(s.players[0].gy.has(nit), "Nitro Synchron went to the Graveyard as material")
		if round == 0:
			check(s.players[0].hand.size() == h0 + 1, "Nitro Synchron draws for a Nitro Synchro Monster")
		else:
			check(s.players[0].hand.size() == h0, "and not for any other Synchro Monster")
	for round in 2:
		s = _main_ready(836 + round)
		_fake(s, 0, "Sinister Sprocket", 400, 0, 0, {"tuner": true, "level": 1, "attribute": "DARK"})
		_fake(s, 0, "Five", 1000, 1000, 1, {"level": 5})
		var syn2 := _fake(s, 0, "Test Synchro", 2400, 1800, -1, {"frame": "synchro", "level": 6, "attribute": "DARK" if round == 0 else "WIND"})
		s.players[0].extra = [syn2]
		var up := _st(s, 1, "Mountain", "hand")
		s.players[1].spells[0] = up
		up.face_up = true
		var down := _st(s, 1, "Mirror Force", "set", "trap")
		s.extra_summon(0, syn2)
		if round == 0:
			check(s.players[1].gy.has(up) and s.players[1].spells.has(down), "Sinister Sprocket destroys a face-up Spell or Trap for a DARK Synchro, never a Set one")
		else:
			check(not s.players[1].gy.has(up), "and does nothing for a Synchro Monster that is not DARK")
	# Galaxy Soldier: another LIGHT monster from the hand pays for it; it arrives in Defense and searches.
	s = _main_ready(838)
	var sol := _fake(s, 0, "Galaxy Soldier", 2000, 0, -1, {"level": 5, "attribute": "LIGHT", "race": "Machine"})
	var dark := _fake(s, 0, "Dark One", 1000, 1000, -1, {"attribute": "DARK"})
	s.players[0].hand = [sol, dark]
	check(not EffectRunner.can_special_hand(s, 0, sol), "Galaxy Soldier needs another LIGHT monster in the hand")
	var light := _fake(s, 0, "Light One", 1000, 1000, -1, {"attribute": "LIGHT"})
	s.players[0].hand.append(light)
	var gal := _fake(s, 0, "Galaxy Friend", 1500, 1000, -1, {"attribute": "LIGHT"})
	s.players[0].deck.append(gal)
	check(EffectRunner.can_special_hand(s, 0, sol), "With one it can come out")
	EffectRunner.special_hand(s, 0, sol)
	check(s.players[0].field.has(sol) and not sol.attack_pos and s.players[0].gy.has(light), "Galaxy Soldier arrives in Defense and the LIGHT monster is in the Graveyard")
	check(s.players[0].hand.has(gal) and s.players[0].hand.has(dark), "and it adds a Galaxy monster from the Deck")
	# Galaxy Knight: no Tribute beside a Photon or Galaxy monster, 1000 ATK weaker this turn, Galaxy-Eyes returns.
	s = _main_ready(839)
	var kn := _fake(s, 0, "Galaxy Knight", 2800, 2600, -1, {"level": 8, "attribute": "LIGHT"})
	s.players[0].hand = [kn]
	_fake(s, 0, "Photon Friend", 1000, 1000, 0, {"attribute": "LIGHT"})
	var eyes := _fake(s, 0, "Galaxy-Eyes Photon Dragon", 3000, 2500, -1, {"level": 8, "attribute": "LIGHT", "race": "Dragon"})
	s.players[0].gy.append(eyes)
	s.normal_summoned = false
	check(s.tributes_needed(kn) == 0, "Galaxy Knight needs no Tribute beside a Photon monster")
	s.normal_summon(0, kn, [], false)
	check(s.players[0].field.has(kn) and s.atk_of(kn, false) == 1800, "Summoned that way it has 1800 ATK this turn")
	check(s.players[0].field.has(eyes) and not eyes.attack_pos, "and Galaxy-Eyes Photon Dragon comes back in Defense")
	s.turn += 1
	check(s.atk_of(kn, false) == 2800, "Next turn Galaxy Knight is at 2800 again")
	# Max Warrior: +400 on the attack; after a kill it is Level 2 at half strength until your next Standby Phase.
	s = _main_ready(840)
	s.phase = DuelState.Phase.BATTLE
	var mx := _fake(s, 0, "Max Warrior", 1800, 800, 0)
	var prey := _fake(s, 1, "Prey", 2000, 1000, 0)
	s.attack(0, mx, prey)
	check(s.players[1].gy.has(prey), "Max Warrior at 2200 beats a 2000 ATK monster")
	check(mx.level() == 2 and s.atk_of(mx, false) == 900 and s.def_of(mx) == 400, "then it is Level 2 with 900 ATK and 400 DEF")
	EffectRunner.standby(s, 0)
	check(mx.level() == 4 and s.atk_of(mx, false) == 1800 and s.def_of(mx) == 800, "and itself again at your next Standby Phase")
	# Twin-Sword Marauder: the second attack only after it attacked a Defense Position monster.
	s = _main_ready(841)
	s.phase = DuelState.Phase.BATTLE
	var tw := _fake(s, 0, "Twin-Sword Marauder", 1600, 1000, 0)
	var a1 := _fake(s, 1, "Standing", 1000, 1000, 0)
	_fake(s, 1, "Other", 1000, 1000, 1)
	s.attack(0, tw, a1)
	check(not s.can_attack(0, tw), "Twin-Sword Marauder: no second attack after hitting an Attack Position monster")
	s = _main_ready(842)
	s.phase = DuelState.Phase.BATTLE
	tw = _fake(s, 0, "Twin-Sword Marauder", 1600, 1000, 0)
	var d1 := _fake(s, 1, "Crouching", 1000, 1000, 0)
	d1.attack_pos = false
	_fake(s, 1, "Other", 1000, 1000, 1)
	var lp2: int = s.players[1].lp
	s.attack(0, tw, d1)
	check(s.players[1].lp == lp2 - 600, "It pierces a Defense Position monster")
	check(s.can_attack(0, tw), "and may attack once more after that")


## Freed, Gilasaurus, Revival Jam, Breaker, the Envoy of the Beginning, Bazoo, Harpie Channeler,
## Insect Queen and Doom Lord, to their printed text.
func _test_batch_32() -> void:
	# Freed: 2 LIGHT monsters from the Graveyard, and only a monster with MORE ATK than Freed.
	var s := _main_ready(851)
	var freed := _fake(s, 0, "Freed the Brave Wanderer", 1700, 1200, 0, {"attribute": "LIGHT"})
	var weak := _fake(s, 1, "Weak", 1500, 1000, 0)
	var l1 := _fake(s, 0, "L1", 1000, 1000, -1, {"attribute": "LIGHT"})
	var l2 := _fake(s, 0, "L2", 1000, 1000, -1, {"attribute": "LIGHT"})
	s.players[0].gy = [l1]
	check(not s.can_ignite(0, freed), "Freed needs 2 LIGHT monsters in the Graveyard")
	s.players[0].gy.append(l2)
	check(not s.can_ignite(0, freed), "and a monster with more ATK than his to aim at")
	var strong := _fake(s, 1, "Strong", 2400, 1000, 1)
	check(s.can_ignite(0, freed), "With both he can use it")
	_run(s, 0, {"do": "ignite", "card": freed})
	check(s.players[1].gy.has(strong) and s.players[1].field.has(weak), "Freed destroys the stronger monster and leaves the weaker one")
	check(s.players[0].banished.has(l1) and s.players[0].banished.has(l2), "and both LIGHT monsters are banished")
	# Gilasaurus: from the hand for free, and the opponent may bring a monster back.
	s = _main_ready(852)
	var gila := _fake(s, 0, "Gilasaurus", 1400, 400, -1, {"level": 3, "race": "Dinosaur"})
	s.players[0].hand = [gila]
	var dead := _fake(s, 1, "Fallen", 2500, 2000, -1)
	s.players[1].gy = [dead]
	EffectRunner.special_hand(s, 0, gila)
	check(s.players[0].field.has(gila), "Gilasaurus is Special Summoned from the hand")
	check(s.players[1].field.has(dead), "and the opponent Special Summons a monster from their Graveyard")
	# Revival Jam: pay 1000 now, back in Defense at your next Standby Phase, not before.
	s = _main_ready(853)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	var jam := _fake(s, 0, "Revival Jam", 1500, 500, 0, {"race": "Aqua", "attribute": "WATER"})
	var hitter := _fake(s, 1, "Hitter", 2000, 1000, 0)
	var lp0: int = s.players[0].lp
	s.attack(1, hitter, jam)
	check(s.players[0].gy.has(jam) and s.players[0].lp == lp0 - 500 - 1000, "Revival Jam: 500 battle damage and 1000 LP paid")
	check(not s.players[0].field.has(jam), "It does not come back at once")
	EffectRunner.standby(s, 0)
	check(s.players[0].field.has(jam) and not jam.attack_pos, "It is back in Defense at your next Standby Phase")
	# Breaker: a Spell Counter on a Normal Summon, 300 ATK for it, spent to destroy a Spell or Trap.
	s = _main_ready(854)
	var br := _fake(s, 0, "Breaker the Magical Warrior", 1600, 1000, -1, {"race": "Spellcaster", "attribute": "DARK"})
	s.players[0].hand = [br]
	s.normal_summoned = false
	s.normal_summon(0, br, [], false)
	check(br.counter == 1 and s.atk_of(br, false) == 1900, "Breaker Normal Summoned: 1 Spell Counter and 1900 ATK")
	var trap := _st(s, 1, "Mirror Force", "set", "trap")
	check(s.can_ignite(0, br), "With a counter and a Spell or Trap on the field it can use its effect")
	_run(s, 0, {"do": "ignite", "card": br})
	check(s.players[1].gy.has(trap) and br.counter == 0 and s.atk_of(br, false) == 1600, "The counter is gone, the Set card is destroyed, Breaker is at 1600")
	check(not s.can_ignite(0, br), "No counter, no effect")
	var br2 := _fake(s, 0, "Breaker the Magical Warrior", 1600, 1000, -1, {"race": "Spellcaster"})
	s._special(0, br2, "effect")
	EffectRunner.on_summon(s, 0, br2, "special")
	check(br2.counter == 0, "Special Summoned, Breaker gets no counter")
	# Envoy of the Beginning: banish OR a second attack after a kill, never both.
	s = _main_ready(855)
	var bls := _fake(s, 0, "Black Luster Soldier - Envoy of the Beginning", 3000, 2500, 0, {"level": 8, "attribute": "LIGHT"})
	var v1 := _fake(s, 1, "V1", 1000, 1000, 0)
	var v2 := _fake(s, 1, "V2", 1200, 1000, 1)
	s.phase = DuelState.Phase.BATTLE
	s.attack(0, bls, v1)
	check(s.can_attack(0, bls), "The Envoy may attack again after destroying a monster by battle")
	s.attack(0, bls, v2)
	check(not s.can_attack(0, bls), "but only once more")
	s.phase = DuelState.Phase.MAIN2
	_fake(s, 1, "V3", 900, 900, 2)
	check(not s.can_ignite(0, bls), "After the second attack it cannot also banish this turn")
	s = _main_ready(856)
	bls = _fake(s, 0, "Black Luster Soldier - Envoy of the Beginning", 3000, 2500, 0, {"level": 8, "attribute": "LIGHT"})
	var hidden := _fake(s, 1, "Hidden", 500, 2000, 0)
	hidden.face_up = false
	hidden.attack_pos = false
	check(s.can_ignite(0, bls), "The Envoy can target a face-down monster")
	_run(s, 0, {"do": "ignite", "card": bls})
	check(s.players[1].banished.has(hidden), "and banish it")
	s.phase = DuelState.Phase.BATTLE
	check(not s.can_attack(0, bls), "It cannot attack the turn it banished")
	# Bazoo: 300 for each, through the end of the opponent's next turn.
	s = _main_ready(857)
	var baz := _fake(s, 0, "Bazoo the Soul-Eater", 1600, 900, 0)
	for i in 3:
		s.players[0].gy.append(_fake(s, 0, "Soul %d" % i, 1000, 1000, -1))
	_run(s, 0, {"do": "ignite", "card": baz})
	check(s.players[0].banished.size() == 3 and s.atk_of(baz, false) == 2500, "Bazoo banishes 3 and has 2500 ATK")
	s.turn += 1
	check(s.atk_of(baz, false) == 2500, "It keeps the ATK through the opponent's turn")
	s.turn += 1
	check(s.atk_of(baz, false) == 1600, "and is back to 1600 after that")
	# Harpie Channeler: the discard must be a Harpie card; Level 7 beside a Dragon.
	s = _main_ready(858)
	var ch := _fake(s, 0, "Harpie Channeler", 1400, 1300, 0, {"race": "Winged Beast", "attribute": "WIND"})
	var lady := _fake(s, 0, "Harpie Lady 1", 1300, 1400, -1, {"race": "Winged Beast"})
	s.players[0].deck.append(lady)
	s.players[0].hand = [_fake(s, 0, "Something Else", 1000, 1000, -1)]
	check(not s.can_ignite(0, ch), "Harpie Channeler cannot discard a card that is not a Harpie card")
	var hunt := _st(s, 0, "Harpies' Hunting Ground")
	check(s.can_ignite(0, ch), "A Harpie Spell will do")
	_run(s, 0, {"do": "ignite", "card": ch})
	check(s.players[0].gy.has(hunt) and s.players[0].field.has(lady) and not lady.attack_pos, "It discards the Harpie card and calls a Harpie in Defense")
	var ch2 := _fake(s, 0, "Harpie Channeler", 1400, 1300, 2, {"race": "Winged Beast"})
	s.players[0].hand.append(_st(s, 0, "Harpies' Hunting Ground"))
	check(not s.can_ignite(0, ch2), "Only one Harpie Channeler effect each turn")
	s._cleanup()
	check(ch.level() == 4, "Harpie Channeler is Level 4 with no Dragon")
	var pet := _fake(s, 0, "Pet Dragon", 1200, 600, 3, {"race": "Dragon"})
	s._cleanup()
	check(ch.level() == 7, "and Level 7 while you control a Dragon")
	s.players[0].field[3] = null
	s._cleanup()
	check(ch.level() == 4 and pet != null, "and Level 4 again when the Dragon is gone")
	# Insect Queen: a Tribute for every attack; a Token at the End Phase after a kill.
	s = _main_ready(859)
	s.phase = DuelState.Phase.BATTLE
	var queen := _fake(s, 0, "Insect Queen", 2200, 2400, 0, {"level": 7, "race": "Insect"})
	var food := _fake(s, 1, "Food", 1000, 1000, 0)
	check(not s.can_attack(0, queen), "Insect Queen cannot attack with nothing to Tribute")
	var grub := _fake(s, 0, "Grub", 300, 300, 1, {"race": "Insect"})
	check(s.atk_of(queen, false) == 2600, "Insect Queen: 200 ATK for each Insect on the field")
	check(s.can_attack(0, queen), "With another monster she can")
	s.attack(0, queen, food)
	check(s.players[0].gy.has(grub) and s.players[1].gy.has(food), "The other monster is Tributed and the attack goes through")
	EffectRunner.end_phase_any(s)
	var tok: Array = s.players[0].monsters().filter(func(m): return m.is_token())
	check(tok.size() == 1 and tok[0].attack_pos and tok[0].atk() == 100, "End Phase: an Insect Monster Token in Attack Position")
	EffectRunner.end_phase_any(s)
	check(s.players[0].monsters().filter(func(m): return m.is_token()).size() == 1, "Only one Token each turn")
	# Doom Lord: gone until your 2nd Standby Phase after, and no attacks that turn.
	s = _main_ready(860)
	var doom := _fake(s, 0, "Destiny HERO - Doom Lord", 600, 800, 0, {"level": 3, "attribute": "DARK"})
	var prey := _fake(s, 1, "Prey", 2800, 2000, 0)
	doom.attack_pos = false
	check(not s.can_ignite(0, doom), "Doom Lord must be in Attack Position")
	doom.attack_pos = true
	_run(s, 0, {"do": "ignite", "card": doom})
	check(s.players[1].banished.has(prey), "Doom Lord banishes the monster")
	s.phase = DuelState.Phase.BATTLE
	check(not s.can_attack(0, doom), "and you cannot attack that turn")
	EffectRunner.standby(s, 0)
	check(s.players[1].banished.has(prey), "It is still gone at your 1st Standby Phase after")
	EffectRunner.standby(s, 0)
	check(s.players[1].field.has(prey) and prey.attack_pos, "and returns to their field at the 2nd")
	# Harpie Queen and Channeler are "Harpie Lady" only on the field and in the Graveyard.
	var queen_d := {"name": "Harpie Queen", "kind": "monster", "frame": "effect"}
	check(not CardEffects.matches(queen_d, {"name": "Harpie Lady"}), "Harpie Queen in the Deck is not a Harpie Lady")
	check(CardEffects.matches(queen_d, {"name": "Harpie Lady", "zone": "gy"}), "In the Graveyard she is")
	check(CardEffects.matches({"name": "Harpie Lady 1", "kind": "monster", "frame": "effect"}, {"name": "Harpie Lady"}), "Harpie Lady 1 always is")
	# "Must first be Special Summoned": no revival before its own summon, fine after it.
	s = _main_ready(861)
	var env := _fake(s, 0, "Black Luster Soldier - Envoy of the Beginning", 3000, 2500, -1, {"level": 8, "attribute": "LIGHT", "desc": "Cannot be Normal Summoned/Set. Must first be Special Summoned (from your hand) by banishing 1 LIGHT and 1 DARK monster from your GY."})
	s.players[0].gy = [env]
	check(not s.can_revive(env), "The Envoy cannot be revived before it was summoned its own way")
	s.players[0].gy = [_fake(s, 0, "Li", 1000, 1000, -1, {"attribute": "LIGHT"}), _fake(s, 0, "Da", 1000, 1000, -1, {"attribute": "DARK"})]
	s.players[0].hand = [env]
	check(EffectRunner.can_special_hand(s, 0, env), "With a LIGHT and a DARK monster in the Graveyard it can come out")
	EffectRunner.special_hand(s, 0, env)
	s._destroy(env)
	check(s.players[0].gy.has(env) and s.can_revive(env), "After that it can be brought back from the Graveyard")
	# Harpie Queen: discarded from the hand, she fetches Harpies' Hunting Ground.
	s = _main_ready(862)
	var hq := _fake(s, 0, "Harpie Queen", 1900, 1200, -1, {"race": "Winged Beast", "attribute": "WIND"})
	s.players[0].hand = [hq]
	check(not s.can_hand_ignite(0, hq), "Harpie Queen: nothing to fetch with no Hunting Ground in the Deck")
	var hg := _st(s, 0, "Harpies' Hunting Ground")
	s.players[0].hand.erase(hg)
	s.players[0].deck.append(hg)
	check(s.can_hand_ignite(0, hq), "With one in the Deck she can be discarded")
	_run(s, 0, {"do": "hand_ignite", "card": hq})
	check(s.players[0].gy.has(hq) and s.players[0].hand.has(hg), "Harpie Queen goes to the Graveyard and Harpies' Hunting Ground comes to the hand")


## Destiny Draw: only when you are in trouble, once per duel, and the card you chose is the draw.
func _test_destiny() -> void:
	var s := _main_ready(901)
	s.destiny = true
	s.destiny_who = [true, true]
	s.current = 0
	s.turn = 4
	s.players[0].lp = 8000
	s.players[1].lp = 8000
	check(not s.can_destiny(0), "No Destiny Draw while you are not in trouble")
	s.players[0].lp = 3900
	check(s.can_destiny(0), "Less than half of their Life Points: Destiny Draw is offered")
	s.players[0].lp = 2000
	s.players[1].lp = 2500
	check(s.can_destiny(0), "2000 Life Points or less: offered")
	check(not s.can_destiny(1), "Not on the other duelist's turn")
	var deck: Array = s.players[0].deck
	var want: DuelState.CardInst = deck[0]          # the bottom card
	var hand0: int = s.players[0].hand.size()
	var deck0: int = deck.size()
	check(s.set_destiny(0, want), "A card in the Deck can be chosen")
	var copy := s.clone()
	check(copy.destiny_next[0] != null and copy.destiny_next[0] != want and copy.destiny_next[0].uid == want.uid, "A copy of the duel keeps the choice, on its own card")
	var ev := s.begin_turn(true)
	check(s.players[0].hand.has(want) and s.players[0].hand.size() == hand0 + 1 and s.players[0].deck.size() == deck0 - 1, "The chosen card is the one drawn, and it is the only draw")
	check(ev.filter(func(e): return e["type"] == "destiny").size() == 1, "The duel says a Destiny Draw happened")
	check(s.destiny_used[0] and not s.can_destiny(0), "Only once per duel")
	# Not when the Draw Phase is skipped, not when it is switched off, not for a duelist who may not.
	s = _main_ready(902)
	s.destiny = true
	s.current = 0
	s.turn = 4
	s.players[0].lp = 1000
	s.players[0].skip_draw = 1
	check(not s.can_destiny(0), "No Destiny Draw when the Draw Phase is skipped")
	s.players[0].skip_draw = 0
	s.destiny = false
	check(not s.can_destiny(0), "Switched off: never offered")
	s.destiny = true
	s.destiny_who = [false, true]
	check(not s.can_destiny(0), "A duelist who may not use it is not offered it")
	# The computer picks something it can use.
	s = _main_ready(903)
	s.destiny = true
	s.destiny_who = [true, true]
	s.current = 1
	s.turn = 4
	s.players[1].lp = 1500
	var pick := DuelAI.pick_destiny(s, 1)
	check(pick != null and s.players[1].deck.has(pick), "The computer chooses a card from its Deck")


## The card a duelist puts on the line: there before the first two wins, and it is the card you get.
func _test_stakes() -> void:
	var keep_owned: Dictionary = Collection.owned.duplicate()
	var keep_rec: Dictionary = Collection.record.duplicate(true)
	var keep_dp: int = Collection.dp
	Collection.record["beaten"] = {}
	Collection.record["vs"] = {}
	var top := Collection.stake_for("kaiba", "kaiba", 5)
	var low := Collection.stake_for("some_student", "kaiba", 1)
	check(top != 0 and low != 0, "A duelist you have not beaten puts a card on the line")
	check(CardData.rarity(top) >= CardData.rarity(low), "A 5 star duelist stakes at least as good a card as a 1 star one")
	check(Collection.playable(top) and Collection.playable(low), "Only cards that are in the game are staked")
	var had := int(Collection.owned.get(top, 0))
	Collection.reward(true, 3, {"opponent": "kaiba", "deck": "kaiba", "stake": top})
	check(Collection.last_prize == top and int(Collection.owned.get(top, 0)) == mini(3, had + 1), "Winning hands you exactly the staked card")
	Collection.reward(false, 3, {"opponent": "kaiba", "deck": "kaiba", "stake": top})
	check(Collection.last_prize == 0, "Losing hands you nothing")
	Collection.owned = keep_owned
	Collection.record = keep_rec
	Collection.dp = keep_dp
	Collection.save()


## As many decks as you like: new, copy, reorder, delete; a bought deck is one of yours and
## can be put back to its original list.
func _test_decks() -> void:
	var c := Collection
	var keep := {"slots": c.slots.duplicate(true), "slot": c.slot, "main": c.main.duplicate(), "extra": c.extra.duplicate(), "side": c.side.duplicate(),
		"name": c.deck_name, "active": c.active, "owned": c.owned.duplicate(), "decks": c.decks_owned.duplicate(), "dropped": c.dropped.duplicate()}
	c.slots = [{"name": "Mine", "main": Array(CardData.deck_list("yugi")), "extra": [], "side": []}]
	c.slot = 0
	c._take_slot()
	c.active = "custom"
	c.decks_owned = ["echo"]
	c.dropped = []
	c._adopt_decks()
	check(c.slots.size() == 2 and c.origin_slot("echo") == 1, "the starter deck is one of your decks")
	check(not c.slot_changed(1), "an untouched starter is not marked changed")
	var n := c.new_slot()
	check(n == 2 and c.slots.size() == 3 and c.slot_empty(n) and not c.slot_ok(n), "a new deck is added at the end, empty")
	check(c.slot == 0 and c.deck_name == "Mine", "making a deck does not switch the deck on the table")
	var d := c.duplicate_slot(0)
	check(d == 3 and (c.slots[d]["main"] as Array).size() == c.main.size() and str(c.slots[d]["name"]) == "Mine copy", "a deck can be duplicated")
	var at := c.move_slot(3, -1)
	check(at == 2 and str(c.slots[2]["name"]) == "Mine copy", "a deck moves up the list")
	check(c.move_slot(0, -1) == 0, "the first deck cannot move further up")
	check(c.move_slot(0, 1) == 1 and c.slot == 1 and c.deck_name == "Mine", "the deck in use keeps its place in hand when it moves")
	c.move_slot(1, -1)
	# Change the starter, then put it back.
	var echo := c.origin_slot("echo")
	c.load_slot(echo)
	var first: int = c.main[0]
	c.main.remove_at(0)
	c.save()
	check(c.slot_changed(echo), "a starter you edited is marked changed")
	c.restore_slot(echo)
	check(not c.slot_changed(echo) and c.main.has(first) and c.main.size() == CardData.deck_list("echo").size(), "the original list can be restored")
	# Deleting: the list shrinks, the deck in use changes hands, a thrown-away bought deck stays away.
	c.use_deck("custom")
	var before: int = c.slots.size()
	c.delete_slot(echo)
	check(c.slots.size() == before - 1 and c.origin_slot("echo") == -1 and c.dropped.has("echo"), "a deck can be deleted")
	c._adopt_decks()
	check(c.origin_slot("echo") == -1, "a bought deck you deleted does not come back by itself")
	c.use_owned("echo")
	check(c.origin_slot("echo") >= 0 and c.using_origin("echo") and not c.dropped.has("echo"), "asking for it again at the shop brings it back, in use")
	while c.slots.size() > 1:
		c.delete_slot(c.slots.size() - 1)
	c.delete_slot(0)
	check(c.slots.size() == 1 and c.slot_empty(0), "the last deck is emptied, not removed")
	# Empty decks from the old five slots are dropped when a save loads.
	c.slots = [{"name": "A", "main": [1, 2], "extra": [], "side": []}, {"name": "Deck 2", "main": [], "extra": [], "side": []},
		{"name": "C", "main": [3], "extra": [], "side": []}, {"name": "Deck 4", "main": [], "extra": [], "side": []}]
	c.slot = 2
	c._take_slot()
	c._fill_slots()
	check(c.slots.size() == 2 and c.slot == 1 and str(c.slots[1]["name"]) == "C", "empty slots from old saves are dropped and the deck in hand is kept")
	c.slots = keep["slots"]
	c.slot = keep["slot"]
	c.main = keep["main"]
	c.extra = keep["extra"]
	c.side = keep["side"]
	c.deck_name = keep["name"]
	c.active = keep["active"]
	c.owned = keep["owned"]
	c.decks_owned = keep["decks"]
	c.dropped = keep["dropped"]
	c.save()


## v0.32: the world clock, and the shape of the story script (lists, clashes, who is in it).
func _test_clock_and_story() -> void:
	var keep_m := WorldClock.minutes
	var keep_d := WorldClock.day
	WorldClock._loaded = true
	WorldClock.minutes = 660.0
	WorldClock.day = 1
	check(WorldClock.look() == "day", "eleven in the morning is day")
	WorldClock.add_minutes(WorldClock.DUEL_COST)
	check(is_equal_approx(WorldClock.minutes, 720.0), "a duel costs an hour")
	WorldClock.go_to(1290.0)
	check(WorldClock.look() == "night" and WorldClock.day == 1, "waiting until night stays in the same day")
	WorldClock.go_to(450.0)
	check(WorldClock.day == 2, "waiting for morning is tomorrow")
	WorldClock.add_minutes(1440.0 * 2.0 + 30.0)
	check(WorldClock.day == 4 and is_equal_approx(WorldClock.minutes, 480.0), "the clock wraps at midnight")
	for m in [0.0, 300.0, 390.0, 445.0, 760.0, 1055.0, 1100.0, 1157.0, 1215.0, 1439.0]:
		WorldClock.minutes = m
		var mx := WorldClock.mix()
		check(mx.size() == 3 and float(mx[2]) >= 0.0 and float(mx[2]) <= 1.0 and str(mx[0]) in ["dawn", "day", "sunset", "night"], "the sky blend is sane at minute %d" % int(m))
	WorldClock.minutes = 1100.0
	check(WorldClock.look() == "sunset", "the story's sunset reads as sunset")
	WorldClock.minutes = keep_m
	WorldClock.day = keep_d
	# The script: every free list hands back to a scene, asks for things that exist, and can finish.
	var worlds := ["domino", "academy", "satellite", "newdomino", "heartland", "museum"]
	var lists := 0
	var clashes := 0
	for ch in StoryData.SCRIPTS:
		var steps: Array = StoryData.SCRIPTS[ch]
		var set_flags := {"won": true, "lost": true}
		for st in steps:
			_story_flags(st, set_flags)
		for i in steps.size():
			var st: Dictionary = steps[i]
			_story_line(ch, st, set_flags)
			if st.has("clash"):
				clashes += 1
				_story_clash(ch, st["clash"])
			if not st.has("tasks"):
				continue
			lists += 1
			check(i + 1 < steps.size() and (steps[i + 1] as Dictionary).has("scene"), "%s: a free list is followed by a scene" % ch)
			check(str(st.get("title", "")) != "" or str(st.get("aim", "")) != "", "%s: a free list has a title" % ch)
			check(str(st.get("aim", "")) != "", "%s list %d: the list says what it is all for" % [ch, i])
			# Every lead mark on a line before this list points at a lead that exists.
			var back := i - 1
			while back >= 0 and not (steps[back] as Dictionary).has("tasks"):
				for key in ["lead", "told"]:
					if (steps[back] as Dictionary).has(key):
						var marks: Array = steps[back][key] if steps[back][key] is Array else [steps[back][key]]
						for mk in marks:
							check(int(mk) >= 0 and int(mk) < (st["tasks"] as Array).size(), "%s list %d: a line gives a lead that is on the list" % [ch, i])
				back -= 1
			var tasks: Array = st["tasks"]
			var must := 0
			for ti in tasks.size():
				var t: Dictionary = tasks[ti]
				check(str(t.get("label", "")) != "", "%s list %d: task %d says what to do" % [ch, i, ti])
				check(str(t.get("why", "")) != "" and (str(t.get("from", "")) == "lumen" or not Characters.get_char(str(t.get("from", ""))).is_empty()),
					"%s list %d: lead %d has a face and a reason" % [ch, i, ti])
				if t.get("hidden", false):
					check(t.get("optional", false), "%s list %d: a lead you have to find is never required (%d)" % [ch, i, ti])
				for j in t.get("reveals", []):
					check(int(j) >= 0 and int(j) < tasks.size(), "%s list %d: lead %d turns up a real lead" % [ch, i, ti])
				var kinds := 0
				for k in ["talk", "look", "go", "travel", "wins", "until"]:
					if t.has(k):
						kinds += 1
				check(kinds == 1, "%s list %d: task %d is one kind of thing" % [ch, i, ti])
				if not t.get("optional", false):
					must += 1
				for n in t.get("needs", []):
					check(int(n) >= 0 and int(n) < tasks.size() and int(n) != ti and not (tasks[int(n)] as Dictionary).get("optional", false),
						"%s list %d: task %d waits on a real, required task" % [ch, i, ti])
				if t.has("talk"):
					check(not Characters.get_char(str(t["talk"])).is_empty(), "%s: %s is somebody" % [ch, str(t.get("talk"))])
				if t.has("in") or t.has("travel"):
					check(str(t.get("in", t.get("travel"))) in worlds, "%s list %d: task %d is in a real world" % [ch, i, ti])
				if t.has("when") or t.has("until"):
					check(str(t.get("when", t.get("until"))) in ["dawn", "day", "sunset", "night"], "%s list %d: task %d names a real time of day" % [ch, i, ti])
				for part in ["say", "retry", "after"]:
					for ln in t.get(part, []):
						_story_line(ch, ln, set_flags)
						if (ln as Dictionary).has("clash"):
							clashes += 1
							_story_clash(ch, ln["clash"])
				if t.has("duel"):
					check(t.has("after") and CardData.has_deck(str(t["duel"].get("opp_deck", ""))) or CardData.has_deck(str(t["duel"].get("fallback", "kairo"))), "%s list %d: task %d has a duel that can be played" % [ch, i, ti])
			check(must >= 1, "%s list %d: there is something that has to be done" % [ch, i])
	check(lists >= 11, "the story hands over to you at least eleven times (%d)" % lists)
	check(clashes >= 7, "seven duels are fought by somebody else (%d)" % clashes)
	check(StoryProgress.SCRIPT_VERSION >= 5, "old saves in the middle of a chapter start that chapter again")


func _story_flags(st: Dictionary, into: Dictionary) -> void:
	for opt in st.get("choice", []):
		into[str(opt[1])] = true
	if st.has("remember") and st["remember"] is String:
		into[str(st["remember"])] = true
	for t in st.get("tasks", []):
		for k in ["flag", "remember"]:
			if (t as Dictionary).has(k):
				into[str(t[k])] = true
		for part in ["say", "retry", "after"]:
			for ln in (t as Dictionary).get(part, []):
				_story_flags(ln, into)


func _story_line(ch: String, st: Dictionary, flags: Dictionary) -> void:
	if st.has("s") and str(st["s"]) not in ["", "player", "lumen"]:
		check(not Characters.get_char(str(st["s"])).is_empty(), "%s: the speaker %s is somebody" % [ch, str(st["s"])])
	for k in ["if", "unless"]:
		if st.has(k):
			var known := false
			for other in StoryData.SCRIPTS:
				var f := {"won": true, "lost": true}
				for os in StoryData.SCRIPTS[other]:
					_story_flags(os, f)
				if f.has(str(st[k])):
					known = true
					break
			check(known, "%s: the flag %s is set somewhere in the story" % [ch, str(st[k])])


func _story_clash(ch: String, c: Dictionary) -> void:
	var lp: Array = (c.get("lp", [4000, 4000]) as Array).duplicate()
	for b in c.get("beats", []):
		check((b as Array).size() >= 3 and str(b[0]) in ["a", "b"], "%s: a clash beat names its side" % ch)
		if (b as Array).size() > 3:
			var other := 1 if str(b[0]) == "a" else 0
			lp[other] = maxi(0, int(lp[other]) - int(b[3]))
	var win := 0 if str(c.get("win", "a")) == "a" else 1
	check(int(lp[1 - win]) == 0 and int(lp[win]) > 0, "%s: %s against %s ends with the loser at zero" % [ch, str(c.get("a")), str(c.get("b"))])
	check(not Characters.get_char(str(c.get("a"))).is_empty() and not Characters.get_char(str(c.get("b"))).is_empty(), "%s: both sides of a clash are somebody" % ch)



## Skull-Mark Ladybug, Infernity Guardian, Dragon Piper, Skull Kraken, Gernia, Submarineroid:
## each sentence of the printed text, one check at a time.
func _test_batch_33() -> void:
	# Skull-Mark Ladybug: 1000 LP when it is sent to the Graveyard, from the field or from the hand.
	var s := _main_ready(861)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	var bug := _fake(s, 0, "Skull-Mark Ladybug", 500, 1500, 0, {"race": "Insect"})
	bug.attack_pos = false
	var hit := _fake(s, 1, "Hitter", 2000, 1000, 0)
	var lp0: int = s.players[0].lp
	s.attack(1, hit, bug)
	s._cleanup()
	check(s.players[0].gy.has(bug) and s.players[0].lp == lp0 + 1000, "Skull-Mark Ladybug destroyed in Defense: 1000 LP gained")
	var bug2 := _fake(s, 0, "Skull-Mark Ladybug", 500, 1500, -1, {"race": "Insect"})
	s.players[0].hand = [bug2]
	lp0 = s.players[0].lp
	s.players[0].hand.erase(bug2)
	s._to_gy(s.players[0], bug2)
	s._cleanup()
	check(s.players[0].lp == lp0 + 1000, "Discarded from the hand it gives 1000 LP too")
	# Infernity Guardian: with an empty hand, neither battle nor a card effect destroys it.
	s = _main_ready(862)
	var guard := _fake(s, 0, "Infernity Guardian", 1200, 1700, 0, {"race": "Fiend", "attribute": "DARK"})
	s.players[0].hand = []
	s.effect_by = 1
	s._destroy(guard)
	s.effect_by = -1
	check(s.players[0].field.has(guard), "Infernity Guardian with no cards in hand is not destroyed by a card effect")
	s.players[0].hand = [_fake(s, 0, "Filler", 1000, 1000, -1)]
	s._destroy(guard)
	check(not s.players[0].field.has(guard), "With a card in hand it is destroyed like anything else")
	# Dragon Piper: nothing happens to the Dragons unless a face-up Dragon Capture Jar was destroyed.
	s = _main_ready(863)
	var piper := _fake(s, 0, "Dragon Piper", 200, 1800, 0, {"race": "Pyro"})
	var drake := _fake(s, 1, "Drake", 2000, 1000, 0, {"race": "Dragon"})
	drake.attack_pos = false
	EffectRunner.run_list(s, 0, piper, [["all_dragons_attack"]], {"_now": true})
	check(not drake.attack_pos, "Dragon Piper with no Dragon Capture Jar on the field: the Dragon stays in Defense")
	var jar := _st(s, 1, "Dragon Capture Jar", "up", "trap")
	jar.face_up = true
	EffectRunner.run_list(s, 0, piper, [["all_dragons_attack"]], {"_now": true})
	check(not s.players[1].spells.has(jar) and drake.attack_pos, "With a face-up Jar: the Jar is destroyed and the Dragon turns to Attack Position")
	# Skull Kraken: a face-up Spell of the opponent's (not a Set card, not a Trap); and its own switch.
	s = _main_ready(864)
	var kr := _fake(s, 0, "Skull Kraken", 600, 1600, -1, {"race": "Aqua", "attribute": "DARK", "level": 3})
	var set_trap := _st(s, 1, "Mirror Force", "set", "trap")
	s.players[0].hand = [kr]
	s.normal_summoned = false
	s.normal_summon(0, kr, [], false)
	check(s.players[1].spells.has(set_trap), "Skull Kraken does not touch a Set card")
	check(s.can_ignite(0, kr), "It can change its own battle position, even on the turn it was summoned")
	_run(s, 0, {"do": "ignite", "card": kr})
	check(not kr.attack_pos and not s.can_ignite(0, kr), "It is in Defense now, and that is once per turn")
	s = _main_ready(865)
	var kr2 := _fake(s, 0, "Skull Kraken", 600, 1600, -1, {"race": "Aqua", "attribute": "DARK", "level": 3})
	var up_spell := _st(s, 1, "Banner of Courage", "up", "spell")
	up_spell.face_up = true
	s.players[0].hand = [kr2]
	s.normal_summoned = false
	s.normal_summon(0, kr2, [], false)
	check(not s.players[1].spells.has(up_spell), "Normal Summoned, Skull Kraken destroys a face-up Spell the opponent controls")
	# Gernia: only an opponent's card effect brings it back, and only at its owner's next Standby Phase.
	s = _main_ready(866)
	var ger := _fake(s, 0, "Gernia", 1300, 1200, 0, {"race": "Zombie", "attribute": "DARK"})
	s.effect_by = 1
	s._destroy(ger)
	s.effect_by = -1
	check(s.players[0].gy.has(ger) and ger.back_pos != "", "Gernia destroyed by the opponent's card effect waits in the Graveyard")
	EffectRunner.standby(s, 0)
	check(s.players[0].field.has(ger), "It is Special Summoned at its owner's next Standby Phase")
	s.effect_by = 0
	s._destroy(ger)
	s.effect_by = -1
	check(s.players[0].gy.has(ger) and ger.back_pos == "", "Destroyed by its owner's own effect it stays in the Graveyard")
	s = _main_ready(867)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	var ger2 := _fake(s, 0, "Gernia", 1300, 1200, 0, {"race": "Zombie"})
	var hit2 := _fake(s, 1, "Hitter", 2000, 1000, 0)
	s.attack(1, hit2, ger2)
	check(s.players[0].gy.has(ger2) and ger2.back_pos == "", "Destroyed by battle it stays in the Graveyard")
	# Submarineroid: direct with a monster in the way deals its ORIGINAL ATK; after battling it may go to Defense.
	s = _main_ready(868)
	s.phase = DuelState.Phase.BATTLE
	var sub := _fake(s, 0, "Submarineroid", 800, 1800, 0, {"race": "Machine", "attribute": "WATER"})
	sub.atk_mod = 500
	var wall := _fake(s, 1, "Wall", 100, 3000, 0)
	var lp1: int = s.players[1].lp
	check(s.can_direct_attack_with(0, sub), "Submarineroid can attack directly past a monster")
	s.attack(0, sub, null)
	check(s.players[1].lp == lp1 - 800, "Attacking past a monster with a boosted Submarineroid deals its original 800")
	check(not sub.attack_pos, "After it battled it changed to Defense Position (its DEF is higher)")
	check(s.players[1].field.has(wall), "The monster it went past is untouched")
	# Medium Piece Golem: only with a Big Piece Golem on your side, only a Small Piece Golem, and negated.
	s = _main_ready(869)
	var med := _fake(s, 0, "Medium Piece Golem", 1600, 0, -1, {"race": "Rock"})
	var small := _fake(s, 0, "Small Piece Golem", 1100, 0, -1, {"race": "Rock", "level": 3})
	var other := _fake(s, 0, "Pebble", 300, 300, -1, {"race": "Rock", "level": 1})
	s.players[0].deck.append(other)
	s.players[0].deck.append(small)
	s.players[0].hand = [med]
	s.normal_summoned = false
	s.normal_summon(0, med, [], false)
	check(s.players[0].deck.has(small), "Medium Piece Golem without a Big Piece Golem: nothing is summoned")
	s = _main_ready(870)
	_fake(s, 0, "Big Piece Golem", 2100, 0, 1, {"race": "Rock", "level": 5})
	var med2 := _fake(s, 0, "Medium Piece Golem", 1600, 0, -1, {"race": "Rock"})
	var small2 := _fake(s, 0, "Small Piece Golem", 1100, 0, -1, {"race": "Rock", "level": 3})
	var other2 := _fake(s, 0, "Pebble", 300, 300, -1, {"race": "Rock", "level": 1})
	s.players[0].deck.append(other2)
	s.players[0].deck.append(small2)
	s.players[0].hand = [med2]
	s.normal_summoned = false
	s.normal_summon(0, med2, [], false)
	check(s.players[0].field.has(small2) and small2.neg_perm and s.players[0].deck.has(other2), "With a Big Piece Golem: Small Piece Golem comes from the Deck with its effects negated, and nothing else does")


## Vampire Lord, Umbral Horror Unform, Dimensional Alchemist, Starliege Paladynamo, Rose Tentacles.
func _test_batch_34() -> void:
	# Vampire Lord: a declared type leaves the opponent's Deck; only an opponent's card effect brings it back.
	var s := _main_ready(871)
	s.phase = DuelState.Phase.BATTLE
	var vamp := _fake(s, 0, "Vampire Lord", 2000, 1500, 0, {"race": "Zombie", "attribute": "DARK", "level": 5})
	var gy0: int = s.players[1].gy.size()
	var deck0: int = s.players[1].deck.size()
	s.attack(0, vamp, null)
	s._cleanup()
	check(s.players[1].gy.size() == gy0 + 1 and s.players[1].deck.size() == deck0 - 1 and s.players[1].gy[-1].is_monster(), "Vampire Lord deals damage: the opponent sends 1 Monster (the declared type) from the Deck to the Graveyard")
	s.effect_by = 1
	s._destroy(vamp)
	s.effect_by = -1
	check(s.players[0].gy.has(vamp) and vamp.back_pos != "", "Destroyed by the opponent's card effect it waits for the next Standby Phase")
	EffectRunner.standby(s, 0)
	check(s.players[0].field.has(vamp), "Vampire Lord is back at its owner's next Standby Phase")
	s = _main_ready(872)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	var vamp2 := _fake(s, 0, "Vampire Lord", 2000, 1500, 0, {"race": "Zombie", "level": 5})
	var big := _fake(s, 1, "Big", 3000, 1000, 0)
	s.attack(1, big, vamp2)
	check(s.players[0].gy.has(vamp2) and vamp2.back_pos == "", "Destroyed by battle it does not come back")
	# Umbral Horror Unform: only when it was the one attacking, and only if 2 can come out.
	s = _main_ready(873)
	s.phase = DuelState.Phase.BATTLE
	var unf := _fake(s, 0, "Umbral Horror Unform", 0, 0, 0, {"race": "Fiend", "attribute": "DARK"})
	var u1 := _fake(s, 0, "Umbral Horror Ghoul", 1800, 0, -1, {"race": "Fiend"})
	var u2 := _fake(s, 0, "Umbral Horror Ghost", 200, 200, -1, {"race": "Fiend", "level": 2})
	s.players[0].deck.append(u1)
	s.players[0].deck.append(u2)
	var foe := _fake(s, 1, "Foe", 1500, 1000, 0)
	s.attack(0, unf, foe)
	check(s.players[0].field.has(u1) and s.players[0].field.has(u2), "Umbral Horror Unform destroyed while attacking a monster: 2 Umbral Horror monsters come from the Deck")
	s = _main_ready(874)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	var unf2 := _fake(s, 0, "Umbral Horror Unform", 0, 0, 0, {"race": "Fiend"})
	var u3 := _fake(s, 0, "Umbral Horror Ghoul", 1800, 0, -1, {"race": "Fiend"})
	var u4 := _fake(s, 0, "Umbral Horror Ghost", 200, 200, -1, {"race": "Fiend", "level": 2})
	s.players[0].deck.append(u3)
	s.players[0].deck.append(u4)
	var foe2 := _fake(s, 1, "Foe", 1500, 1000, 0)
	s.attack(1, foe2, unf2)
	check(s.players[0].deck.has(u3) and s.players[0].deck.has(u4), "Destroyed while being attacked: nothing comes out")
	s = _main_ready(875)
	s.phase = DuelState.Phase.BATTLE
	var unf3 := _fake(s, 0, "Umbral Horror Unform", 0, 0, 0, {"race": "Fiend"})
	var u5 := _fake(s, 0, "Umbral Horror Ghoul", 1800, 0, -1, {"race": "Fiend"})
	s.players[0].deck.append(u5)
	var foe3 := _fake(s, 1, "Foe", 1500, 1000, 0)
	s.attack(0, unf3, foe3)
	check(s.players[0].deck.has(u5), "With only 1 Umbral Horror in the Deck the effect cannot be used")
	# Dimensional Alchemist: top card banished for 500 ATK this turn; a banished monster back to the hand when it falls.
	s = _main_ready(876)
	var alc := _fake(s, 0, "Dimensional Alchemist", 1300, 200, 0, {"race": "Fairy", "attribute": "LIGHT"})
	var topc := _fake(s, 0, "Top Card", 900, 900, -1)
	s.players[0].deck.append(topc)
	check(s.can_ignite(0, alc), "Dimensional Alchemist can use its effect in the Main Phase")
	_run(s, 0, {"do": "ignite", "card": alc})
	check(s.players[0].banished.has(topc) and s.atk_of(alc, false) == 1800 and not s.can_ignite(0, alc), "The top card of the Deck is banished, it has 1800 ATK, once per turn")
	var hand0: int = s.players[0].hand.size()
	s._destroy(alc)
	check(s.players[0].hand.has(topc) and s.players[0].hand.size() == hand0 + 1 and not s.players[0].banished.has(topc), "Destroyed and sent to the Graveyard: a banished monster comes to the hand")
	# Starliege Paladynamo: 0 ATK and no effects for good; a card when the opponent's card destroys it.
	s = _main_ready(877)
	var pal := _fake(s, 0, "Starliege Paladynamo", 2000, 1000, 0, {"frame": "xyz", "attribute": "LIGHT"})
	pal.overlays = [s._make(40640057, 0), s._make(40640057, 0)]
	var prey := _fake(s, 1, "Prey", 2500, 1000, 0)
	check(s.can_ignite(0, pal), "Paladynamo with 2 materials can use its effect")
	_run(s, 0, {"do": "ignite", "card": pal})
	check(pal.overlays.is_empty() and s.atk_of(prey, false) == 0 and prey.neg_perm, "Both materials are detached; the target has 0 ATK and its effects are negated")
	s.turn += 1
	check(s.atk_of(prey, false) == 0, "It is still 0 on the next turn")
	var hand1: int = s.players[0].hand.size()
	s.effect_by = 1
	s._destroy(pal)
	s.effect_by = -1
	check(s.players[0].hand.size() == hand1 + 1, "Destroyed by the opponent's card effect: draw 1 card")
	s = _main_ready(878)
	var pal2 := _fake(s, 0, "Starliege Paladynamo", 2000, 1000, 0, {"frame": "xyz"})
	var hand2: int = s.players[0].hand.size()
	s.effect_by = 0
	s._destroy(pal2)
	s.effect_by = -1
	check(s.players[0].hand.size() == hand2, "Destroyed by its owner's own card: no draw")
	# Rose Tentacles: one more attack for each Plant the opponent controls when the Battle Phase starts.
	s = _main_ready(879)
	var rose := _fake(s, 0, "Rose Tentacles", 2200, 1200, 0, {"race": "Plant", "attribute": "EARTH", "level": 6})
	_fake(s, 1, "Fern", 500, 500, 0, {"race": "Plant"})
	_fake(s, 1, "Moss", 400, 400, 1, {"race": "Plant"})
	_fake(s, 1, "Rock", 300, 300, 2, {"race": "Rock"})
	s.phase = DuelState.Phase.MAIN1
	s.enter_battle()
	check(s.attacks_left(rose) == 3, "Rose Tentacles with 2 Plants across the field: 3 attacks this turn")
	check(not s.can_revive(rose) or not s.players[0].gy.has(rose), "It cannot be Special Summoned")
	# Gagaga Cowboy: one effect, two results, by the position it is in when it resolves.
	s = _main_ready(880)
	var cow := _fake(s, 0, "Gagaga Cowboy", 1500, 2400, 0, {"frame": "xyz"})
	cow.overlays = [s._make(40640057, 0), s._make(40640057, 0)]
	var tgt := _fake(s, 1, "Target", 2200, 1000, 0)
	_run(s, 0, {"do": "ignite", "card": cow})
	check(cow.overlays.size() == 1 and s.atk_of(cow, false) == 1500, "Gagaga Cowboy in Attack Position: 1 material detached, no change outside of battle")
	check(s.atk_of(cow, true, tgt, true) == 2500 and s.atk_of(tgt, false, cow, true) == 1700, "Attacking a monster: 2500 against 1700 during the Damage Step")
	s.phase = DuelState.Phase.BATTLE
	s.attack(0, cow, tgt)
	check(s.players[1].gy.has(tgt) and s.players[0].field.has(cow), "It wins the battle it would have lost")
	s = _main_ready(881)
	var cow2 := _fake(s, 0, "Gagaga Cowboy", 1500, 2400, 0, {"frame": "xyz"})
	cow2.attack_pos = false
	cow2.overlays = [s._make(40640057, 0)]
	var lp8: int = s.players[1].lp
	_run(s, 0, {"do": "ignite", "card": cow2})
	check(s.players[1].lp == lp8 - 800 and cow2.overlays.is_empty(), "In Defense Position: 800 damage to the opponent")
	# Umbral Horror Will o' the Wisp: a Level from another Umbral Horror; only in Attack Position does it take its killer along.
	s = _main_ready(882)
	var wisp := _fake(s, 0, "Umbral Horror Will o' the Wisp", 0, 0, -1, {"race": "Fiend", "level": 1})
	var gh := _fake(s, 0, "Umbral Horror Ghoul", 1800, 0, -1, {"race": "Fiend", "level": 4})
	s.players[0].gy.append(gh)
	s.players[0].hand = [wisp]
	s.normal_summoned = false
	s.normal_summon(0, wisp, [], false)
	check(wisp.level() == 4, "Will o' the Wisp Normal Summoned takes the Level of an Umbral Horror in the Graveyard")
	s.turn += 2
	s.begin_turn()
	check(wisp.level() == 4, "The Level stays")
	s = _main_ready(883)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	var wisp2 := _fake(s, 0, "Umbral Horror Will o' the Wisp", 0, 0, 0, {"race": "Fiend", "level": 1})
	var slayer := _fake(s, 1, "Slayer", 1500, 1000, 0)
	s.attack(1, slayer, wisp2)
	check(s.players[1].gy.has(slayer), "Destroyed by battle in Attack Position it destroys the monster that did it")
	s = _main_ready(884)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	var wisp3 := _fake(s, 0, "Umbral Horror Will o' the Wisp", 0, 0, 0, {"race": "Fiend", "level": 1})
	wisp3.attack_pos = false
	var slayer2 := _fake(s, 1, "Slayer", 1500, 1000, 0)
	s.attack(1, slayer2, wisp3)
	check(s.players[0].gy.has(wisp3) and s.players[1].field.has(slayer2), "Destroyed in Defense Position it does not")
	# Infernity Archfiend: drawn into an empty hand it can come straight out, and then it searches.
	s = _main_ready(885)
	var arch := _fake(s, 0, "Infernity Archfiend", 1800, 1200, -1, {"race": "Fiend", "attribute": "DARK"})
	var inf_spell := _st(s, 0, "Infernity Launcher", "hand", "spell")
	s.players[0].hand = []
	s.players[0].deck.append(inf_spell)
	s.players[0].deck.append(arch)
	s._draw(0, 1)
	check(s.players[0].field.has(arch), "Infernity Archfiend drawn with an empty hand is Special Summoned")
	check(s.players[0].hand.has(inf_spell), "Special Summoned with an empty hand it adds an Infernity card (a Spell counts) to the hand")
	s = _main_ready(886)
	var arch2 := _fake(s, 0, "Infernity Archfiend", 1800, 1200, -1, {"race": "Fiend"})
	var keep := _fake(s, 0, "Something", 1000, 1000, -1)
	s.players[0].hand = [keep]
	s.players[0].deck.append(arch2)
	s._draw(0, 1)
	check(s.players[0].hand.has(arch2), "Drawn while there are other cards in hand it stays in the hand")
	var inf2 := _fake(s, 0, "Infernity Beast", 1600, 1200, -1, {"race": "Beast"})
	s.players[0].deck.append(inf2)
	s.players[0].hand.erase(arch2)
	s._special(0, arch2, "effect")
	EffectRunner.on_summon(s, 0, arch2, "special")
	check(s.players[0].deck.has(inf2), "Special Summoned while there is a card in hand: no search")


## The Free Duel Knockout: the bracket fills round by round and ends with one champion, whether
## you win it or go out; the duel of the day is the same all day and has a deck for both sides.
func _test_knockout() -> void:
	Knockout._loaded = true
	Knockout.no_save = true
	check(Knockout.can_enter(), "with a card folder there are enough duelists for a bracket")
	for d in [1, 2, 3]:
		Knockout.start(d)
		var seeds: Array = Knockout.state["seeds"]
		check(seeds.size() == 8 and seeds.count("player") == 1, "eight seats, one of them yours")
		var uniq := {}
		for k in seeds:
			uniq[k] = true
		check(uniq.size() == 8, "nobody is drawn twice")
		check(Knockout.opponent() != "" and Knockout.opponent() != "player", "you have somebody to duel in round one")
		check(int(Knockout.duel_config()["difficulty"]) == d, "the first rounds are at the level you picked")
		var a := Knockout.report(true)
		check(str(a["champion"]) == "" and (Knockout.state["wins"][0] as Array).size() == 4 and Knockout.round_name() == "Semifinal", "a win in the quarterfinal: four go through, you among them")
		check((Knockout.state["wins"][0] as Array).has("player"), "you are in the semifinal")
		Knockout.report(true)
		check(str(Knockout.duel_config()["field"]) == "kaibacorp" and int(Knockout.duel_config()["difficulty"]) == mini(3, d + 1), "the final is in the Duel Dome, one step harder")
		var c := Knockout.report(true)
		check(str(c["champion"]) == "player" and int(c["prize"]) == int(Knockout.PRIZES[d]) and int(c["cup"]) == d, "three wins take the cup and its prize")
		check(not Knockout.running() and Knockout.champion() == "player", "the bracket is over")
	Knockout.start(2)
	Knockout.report(true)
	var out := Knockout.report(false)
	var beat_me := str((Knockout.state["wins"][1] as Array).filter(func(k): return true)[0])
	check(str(out["champion"]) != "" and str(out["champion"]) != "player" and int(out["prize"]) == 100, "out in the semifinal: somebody else takes it, and one won round pays 100")
	check((Knockout.state["wins"][2] as Array).size() == 1 and not (Knockout.state["wins"][1] as Array).has("player") and beat_me != "", "the rest of the bracket is played out")
	check(Knockout.report(true)["champion"] == "", "a finished bracket takes no more results")
	Knockout.clear()
	check(not Knockout.has_bracket(), "a cleared bracket is gone")
	var day := Knockout.daily()
	var again := Knockout.daily()
	check(not day.is_empty() and str(day["opponent"]) == str(again["opponent"]) and str(day["twist"]["id"]) == str(again["twist"]["id"]), "the duel of the day is the same all day")
	check(CardData.has_deck(str(day["cfg"]["player_deck"])) and Characters.available(str(day["opponent"])), "the duel of the day has a deck on both sides")
	# Every twist gives a duel that can be set up.
	for tw in Knockout.TWISTS:
		check(str(tw["name"]) != "" and str(tw["text"]) != "", "twist %s has a name and a line" % str(tw["id"]))
	Knockout.no_save = false


## Lumen's forms and the cards around her (cards of this game): each one does what it prints.
## Every card the game carries itself has the number the card database has for that name
## (Max Warrior once carried Batteryman AA's number and showed its picture and text).
func _test_card_numbers() -> void:
	var wrong: Array = []
	for id in CardData.CARDS:
		if int(id) >= 99000000 or not CardData.EXT.has(id):
			continue
		var mine := str(CardData.CARDS[id].get("name", "")).to_lower()
		var theirs := str(CardData.EXT[id].get("name", "")).to_lower()
		if mine != theirs:
			wrong.append("%d %s is %s in the database" % [id, mine, theirs])
	check(wrong.is_empty(), "every built-in card has the database's number for its name" + ("" if wrong.is_empty() else ": " + ", ".join(wrong)))
	var c := CardData.get_card(94538053)
	check(str(c.get("name", "")) == "Max Warrior" and int(c.get("atk", 0)) == 1800, "Max Warrior is card 94538053")
	check(int(CardData.RENUMBERED.get(63142001, 0)) == 94538053, "the old Max Warrior number moves to the right one in saves")


## Every Field Spell the game plays has a place to turn the field into and says what it does;
## what it adds to a monster is what the rules add.
func _test_field_looks() -> void:
	var missing: Array = []
	for nm in FieldLooks.BY_NAME:
		var id := int(CardData.NAME_TO_ID.get(str(nm).to_lower(), 0))
		if id == 0:
			continue
		var s0 := _new_state(3)
		var c := s0._make(id, 0)
		var look := FieldLooks.look_for(c)
		if not FieldLooks.LOOKS.has(str(look.get("key", ""))) or int(look.get("surface", 0)) <= 0 or FieldLooks.says(c).is_empty():
			missing.append(nm)
	check(missing.is_empty(), "every Field Spell has a place and says what it does" + ("" if missing.is_empty() else ": " + ", ".join(missing)))
	var s := _new_state(4, "kaiba", "yugi")
	s.begin_turn()
	s.current = 0
	s.phase = DuelState.Phase.MAIN1
	var drag := _put(s, 0, int(CardData.NAME_TO_ID.get("luster dragon", 0)), 0)
	var mage := _put(s, 1, int(CardData.NAME_TO_ID.get("dark magician", 0)), 0)
	check(FieldLooks.delta(s, drag) == [0, 0], "no Field Spell, no mark on a monster")
	var mt := s._make(int(CardData.NAME_TO_ID.get("mountain", 0)), 0)
	s.players[0].hand.append(mt)
	s.activate(0, mt)
	check(s.players[0].field_spell == mt, "Mountain is in the Field Zone")
	check(FieldLooks.delta(s, drag) == [200, 200] and s.atk_of(drag, false) == drag.atk() + 200, "Mountain marks a Dragon with +200 / +200, as the rules count it")
	check(FieldLooks.delta(s, mage) == [0, 0], "and leaves a Spellcaster alone")
	check(str(FieldLooks.look_for(mt)["key"]) == "peak", "Mountain turns the field into a snowy peak")
	# A Field Spell the game reads from its text (no entry of its own) still gets a place.
	var auto_look := ""
	for id2 in CardData.EXT:
		var d: Dictionary = CardData.EXT[id2]
		if str(d.get("st", "")) == "field" and not FieldLooks.BY_NAME.has(str(d.get("name", ""))) and not SpellRules.FX.has(str(d.get("name", ""))):
			var c2 := s._make(int(id2), 0)
			if not SpellRules.spec(c2).is_empty():
				auto_look = str(FieldLooks.look_for(c2)["key"])
				break
	check(auto_look == "" or FieldLooks.LOOKS.has(auto_look), "a Field Spell read from its text gets a place by what it boosts")


func _test_lumen() -> void:
	var M1 := DuelState.Phase.MAIN1
	for id in CardData.ORIGINALS:
		var d := CardData.get_card(id)
		check(CardExact.ok(d) and bool(d.get("original", false)) and CardData.set_code(id).begins_with("CR-"), "%s is a card of this game and plays" % str(d.get("name", "")))
	# --- Fusion: "Lumen, Echo Spirit" + 1 monster, with Polymerization.
	var f := _new_state(11, "yugi", "kaiba")
	f.begin_turn()
	f.current = 0
	f.phase = M1
	var fp: DuelState.PlayerState = f.players[0]
	fp.hand.clear()
	fp.extra.clear()
	var chorus := f._make(99200002, 0)
	fp.extra.append(chorus)
	var poly := f._make(24094653, 0)
	fp.hand.append(poly)
	check(not f.can_activate(0, poly), "no Echo Chorus without Lumen")
	var lum := _put(f, 0, 99200001, 0)
	check(not f.can_activate(0, poly), "Lumen alone is not enough: it asks for 1 more monster")
	var other := f._make(91152256, 0)
	fp.hand.append(other)
	check(f.can_activate(0, poly), "Lumen on the field + a monster in hand: Polymerization can be played")
	f.activate(0, poly)
	check(fp.field.has(chorus) and fp.gy.has(lum) and fp.gy.has(other), "Echo Chorus is Fusion Summoned, both materials go to the Graveyard")
	check(fp.hand.size() == 1, "Fusion Summoned: it draws 1 card")
	f._destroy(chorus)
	check(fp.field.has(lum) and not lum.attack_pos, "sent to the Graveyard: Lumen comes back in Defense Position")
	# --- Synchro: Lumen is a Tuner once the story says so. Level 2 + Level 4 = 6.
	var y := _new_state(12, "yusei", "kaiba")
	y.begin_turn()
	y.current = 0
	y.phase = M1
	var yp: DuelState.PlayerState = y.players[0]
	yp.extra.clear()
	var comet := y._make(99200003, 0)
	yp.extra.append(comet)
	CardData.lumen_tuner_test = false
	var plain := _put(y, 0, 99200001, 0)
	_put(y, 0, 91152256, 1)
	if Unlocks.stage() < CardData.LUMEN_TUNER_STAGE:
		check(not y.can_extra_summon(0, comet), "before the riders' worlds Lumen is no Tuner: no Echo Comet")
	yp.field[0] = null
	CardData.lumen_tuner_test = true
	var tuner := _put(y, 0, 99200001, 0)
	check(tuner.is_tuner() and plain != tuner, "after them she is a Tuner")
	var foe := _put(y, 1, 89631139, 0)
	check(y.can_extra_summon(0, comet), "Lumen (Tuner, Level 2) + a Level 4: Echo Comet")
	y.extra_summon(0, comet)
	check(yp.field.has(comet) and not y.players[1].field.has(foe), "Synchro Summoned: it destroys 1 card the opponent controls")
	check(EffectRunner.fx(comet).get("piercing", false), "and it pierces")
	# A Synchro Monster that names another Tuner does not take her.
	var z2 := _new_state(13, "yusei", "kaiba")
	z2.begin_turn()
	z2.current = 0
	z2.phase = M1
	_put(z2, 0, 99200001, 0)
	_put(z2, 0, 9365703, 1)      # Speed Warrior, Level 2... with Lumen that is 4, not Junk Warrior's 5
	var jw: DuelState.CardInst = null
	for x in z2.players[0].extra:
		if x.id == 60800381:
			jw = x
	check(jw == null or not z2.can_extra_summon(0, jw), "Junk Warrior still asks for Junk Synchron")
	CardData.lumen_tuner_test = false
	# --- Xyz: 2 Level 4 monsters, and 1 Lumen can stand in for one of them.
	var x4 := _new_state(14, "yuma", "kaiba")
	x4.begin_turn()
	x4.current = 0
	x4.phase = M1
	var xp: DuelState.PlayerState = x4.players[0]
	xp.extra.clear()
	var zenith := x4._make(99200004, 0)
	xp.extra.append(zenith)
	var l1 := _put(x4, 0, 99200001, 0)
	check(not x4.can_extra_summon(0, zenith), "Lumen alone: no Echo Zenith")
	var l2 := _put(x4, 0, 99200001, 1)
	check(not x4.can_extra_summon(0, zenith), "two Lumens: only one of them can stand in")
	xp.field[1] = null
	_put(x4, 0, 91152256, 1)
	check(l2 != l1 and x4.can_extra_summon(0, zenith), "Lumen + a Level 4: Echo Zenith")
	x4.extra_summon(0, zenith)
	check(xp.field.has(zenith) and zenith.overlays.size() == 2, "Echo Zenith has 2 materials")
	check(not x4.can_ignite(0, zenith), "nothing of Lumen's in the Graveyard: no use detaching")
	var dead := x4._make(99200001, 0)
	xp.gy.append(dead)
	check(x4.can_ignite(0, zenith), "a Lumen in the Graveyard: it can detach")
	x4.ignite(0, zenith)
	check(zenith.overlays.size() == 1 and xp.field.has(dead), "detach 1: a Lumen monster comes back from the Graveyard")
	check(not x4.can_ignite(0, zenith), "once per turn")
	# --- Echo Resonance: Tribute a Lumen that was not Summoned this turn, Echo Radiant comes out of the Deck.
	var r := _new_state(15, "yugi", "kaiba")
	r.begin_turn()
	r.current = 0
	r.phase = M1
	var rp: DuelState.PlayerState = r.players[0]
	rp.hand.clear()
	var res := r._make(99200011, 0)
	rp.hand.append(res)
	var radiant := r._make(99200005, 0)
	rp.deck.append(radiant)
	check(not r.can_activate(0, res), "Echo Resonance needs a Lumen, Echo Spirit")
	var rl := _put(r, 0, 99200001, 0)
	rl.summoned_turn = r.turn
	check(not r.can_activate(0, res), "not the turn she was Summoned")
	rp.lp = 2000
	check(r.can_activate(0, res), "...unless your Life Points are 2000 or less")
	rp.lp = 8000
	rl.summoned_turn = r.turn - 1
	check(r.can_activate(0, res), "a Lumen from an earlier turn: Echo Resonance can be played")
	var their := _put(r, 1, 89631139, 0)
	r.activate(0, res)
	check(rp.field.has(radiant) and rp.gy.has(rl) and not rp.deck.has(radiant), "Lumen is Tributed and Echo Radiant comes out of the Deck")
	check(not r.players[1].field.has(their), "Summoned by Echo Resonance: it destroys 1 card the opponent controls")
	var in_hand := r._make(99200005, 0)
	rp.hand.append(in_hand)
	r.normal_summoned = false
	check(not r.can_normal_summon(0, in_hand), "Echo Radiant cannot be Normal Summoned or Set")
	rp.gy.append(in_hand)
	rp.hand.erase(in_hand)
	check(not r.can_revive(in_hand), "and nothing else brings it out")
	# --- Echo Call: any "Lumen" monster from the Deck (not a Spell, not the Extra Deck).
	var c := _new_state(16, "yugi", "kaiba")
	c.begin_turn()
	c.current = 0
	c.phase = M1
	var cp: DuelState.PlayerState = c.players[0]
	cp.hand.clear()
	var call := c._make(99200012, 0)
	cp.hand.append(call)
	check(not c.can_activate(0, call), "Echo Call with no Lumen in the Deck does nothing")
	cp.deck.append(c._make(99200011, 0))
	check(not c.can_activate(0, call), "Echo Resonance is not a Lumen monster")
	var in_deck := c._make(99200001, 0)
	cp.deck.append(in_deck)
	check(c.can_activate(0, call), "a Lumen in the Deck: Echo Call can be played")
	c.activate(0, call)
	check(cp.hand.has(in_deck), "and she is in your hand")
	# --- Echo Veil: the attack is negated; with a Lumen on your field you also draw 1.
	for with_lumen in [false, true]:
		var v := _new_state(17)
		v.begin_turn()
		v.end_turn()
		v.begin_turn()      # player 1, turn 2
		var veil := v._make(99200013, 0)
		v.players[0].spells[0] = veil
		veil.face_up = false
		veil.set_turn = 1
		if with_lumen:
			_put(v, 0, 99200001, 0).attack_pos = false
		var atk := _put(v, 1, 89631139, 0)
		atk.summoned_turn = 1
		var held: int = v.players[0].hand.size()
		v.enter_battle()
		v.declare_attack(1, atk, v.players[0].field[0] if with_lumen else null)
		check(v.responses(0, "attack").has(veil), "Echo Veil is offered on an attack")
		v.respond(0, veil)
		var ev := v.resolve_attack()
		check(ev.size() == 1 and ev[0]["type"] == "attack_stopped" and v.players[0].lp == DuelState.START_LP, "Echo Veil negates the attack")
		check(v.players[0].hand.size() == held + (1 if with_lumen else 0), "Echo Veil draws 1 only with a Lumen on your field" if with_lumen else "Echo Veil alone draws nothing")
		if with_lumen:
			check(v.players[0].field[0] != null, "and Lumen is still there")


## The computer never helps you: a boost goes on its own monster or stays in its hand.
func _test_ai_targets() -> void:
	for lvl in [DuelAI.EASY, DuelAI.NORMAL, DuelAI.HARD]:
		var s := _new_state(31, "yugi", "kaiba")
		s.begin_turn()
		s.end_turn()
		s.begin_turn()       # player 1 (the computer's side in this test), turn 2
		s.phase = DuelState.Phase.MAIN1
		var ai: DuelState.PlayerState = s.players[1]
		ai.hand.clear()
		var treasure := s._make(CardData.NAME_TO_ID.get("dragon treasure", 0), 1)
		ai.hand.append(treasure)
		var yours := _put(s, 0, 39191307, 0)       # your Masked Dragon: the only Dragon on the field
		check(s.can_activate(1, treasure), "Dragon Treasure could legally go on your Dragon")
		check(not DuelAI.has_use(s, 1, treasure), "...but it is no use to them there")
		for i in 12:
			var act := DuelAI.next_main_action(s, 1, lvl)
			check(not (str(act.get("do", "")) == "activate" and act.get("card") == treasure), "level %d: they do not equip your monster" % lvl)
		check(s.atk_of(yours, false) == 1400, "your Masked Dragon is still 1400")
		var theirs := _put(s, 1, 11091375, 0)        # their own Luster Dragon
		check(DuelAI.has_use(s, 1, treasure) and SpellRules.auto_target(s, 1, treasure) == theirs, "with a Dragon of their own it goes on that one")
		s.activate(1, treasure)
		check(s.atk_of(theirs, false) == 2200 and s.atk_of(yours, false) == 1400, "and it does")
	# An Equip Card goes to the Graveyard the moment its monster is Tributed, whoever played it.
	var q := _new_state(32, "yugi", "kaiba")
	q.begin_turn()
	q.current = 0
	q.phase = DuelState.Phase.MAIN1
	var worn := _put(q, 0, 39191307, 0)
	var eq := q._make(CardData.NAME_TO_ID.get("dragon treasure", 0), 1)
	q.players[1].spells[0] = eq
	eq.face_up = true
	eq.equipped_to = worn
	check(q.atk_of(worn, false) == 1700, "an Equip Card of theirs on your monster counts (1400 + 300)")
	var big := q._make(CardData.NAME_TO_ID.get("luster dragon #2", 0), 0)
	q.players[0].hand.append(big)
	q.normal_summoned = false
	q.normal_summon(0, big, [worn])
	check(q.players[0].field.has(big) and not q.players[1].spells.has(eq) and q.players[1].gy.has(eq), "Tribute the monster: the Equip Card is in its owner's Graveyard at once")
	check(q.atk_of(big, false) == 2400, "and the new monster has nothing on it")



## A week at the Academy: merits, the assignment, the prize case, the report card, the table.
func _test_academy_week() -> void:
	var keep: Dictionary = Academy.d.duplicate(true) if Academy._loaded else {}
	var keep_dp: int = Collection.dp
	var keep_owned: Dictionary = Collection.owned.duplicate()
	Academy._loaded = true
	Academy.d = Academy._defaults()
	Academy.d["enrolled"] = true
	var t := Academy.today()
	check(str(t["kind"]) == "class" and str(t.get("subject", "")) != "" and not (t.get("assignment", {}) as Dictionary).is_empty(), "a class duel has a subject and an assignment")
	# Win with the assignment done: 2 merits for the win, 1 for the assignment.
	var a: Dictionary = t["assignment"]
	Router.last_stats = {"won": true, "lp": 8000, "turns": 5, "low": 8000}
	Academy.start(t)
	var lines := Academy.resolve(true)
	check(int(Academy.d["merits"]) == 3 and int(Academy.d["week_assign"]) == 1, "a class win with the assignment done is 3 merits (got %d)" % int(Academy.d["merits"]))
	check(str(lines).contains("Assignment done"), "the result says the assignment was done")
	# Win without it: 2 merits, and that reaches 5: the prize case opens once.
	Router.last_stats = {"won": true, "lp": 100, "turns": 40, "low": 100}
	Academy.start(Academy.today())
	lines = Academy.resolve(true)
	check(int(Academy.d["merits"]) == 5 and int(Academy.d["merit_prizes"]) == 1, "5 merits opens the prize case once (merits %d, prizes %d)" % [int(Academy.d["merits"]), int(Academy.d["merit_prizes"])])
	check(str(lines).contains("Assignment missed") and str(lines).contains("prize case"), "the result names the missed assignment and the prize")
	check(Academy.merit_goal() == [5, 10], "the next prize is at 10 merits")
	# Lose the third class, then pass the exam: promoted, report card, new dorm table.
	Academy.start(Academy.today())
	Academy.resolve(false)
	check(str(Academy.today()["kind"]) == "exam", "after three class days comes the exam")
	Academy.start(Academy.today())
	lines = Academy.resolve(true)
	check(int(Academy.d["dorm"]) == 1 and int(Academy.d["week"]) == 2 and int(Academy.d["day"]) == 0, "passing the exam with two class wins moves you up a dorm")
	check(str(lines).contains("Report card") and int(Academy.d["merits"]) == 8, "the exam gives a report card and 3 merits (merits %d)" % int(Academy.d["merits"]))
	check(int(Academy.d["dorm_pts"]) == 0 and int(Academy.d["week_assign"]) == 0, "a new dorm starts its table from nothing")
	var table := Academy.standings()
	check(table.size() == 8 and Academy.my_rank() >= 1 and Academy.my_rank() <= 8, "the dorm table has eight names and you are on it")
	check(Tournament.next_step() != "" and Tournament.status("domino") != "", "the tournaments say where you stand and what is next")
	Academy.d = keep if not keep.is_empty() else Academy._defaults()
	Collection.dp = keep_dp
	Collection.owned = keep_owned
	Router.last_stats = {}


## What your Momentum on the highway is worth when a Turbo Duel starts.
func _test_turbo_setup() -> void:
	var ride = load("res://scripts/turbo/turbo_ride.gd").new()
	var worth := {}
	for m in [0.0, 24.0, 25.0, 49.0, 50.0, 74.0, 75.0, 99.0, 100.0]:
		ride._mom = m
		worth[m] = ride._mom_worth()
	check(worth[0.0] == [0, false] and worth[25.0] == [1, false] and worth[49.0] == [1, false] and worth[50.0] == [2, true]
		and worth[75.0] == [3, true] and worth[100.0] == [4, true], "Momentum: a Speed Counter every quarter, the first turn from half (%s)" % str(worth))
	ride._gain(500.0)
	check(is_equal_approx(ride._mom, 100.0), "Momentum stops at 100")
	ride.free()
	check(TurboGarage.gives("engine", 0) == "Standard" and TurboGarage.gives("engine", 2) == "+14 km/h", "garage parts say what they give")



## Every duelist's deck after today's changes: forty or more, nothing over three copies, the
## stand-ins that were named are gone, and every card that was added works here.
func _test_signature_decks() -> void:
	var bad: Array = []
	for key in Characters.ORDER:
		var deck := str(Characters.get_char(str(key)).get("deck", ""))
		if not CardData.has_deck(deck):
			continue
		var list := CardData.deck_list(deck)
		if list.size() < CardData.MIN_DECK or list.size() > 60:
			bad.append("%s has %d cards" % [key, list.size()])
		var counts := {}
		for id in list:
			counts[id] = int(counts.get(id, 0)) + 1
			# (The Fusion decks were built with a fourth Polymerization long before this: left alone.)
			if counts[id] == 4 and str(CardData.get_card(id).get("name", "")) != "Polymerization":
				bad.append("%s has four of %s" % [key, CardData.get_card(id).get("name", "?")])
			if not CardExact.ok(CardData.get_card(id)):
				bad.append("%s plays %s without its effect" % [key, CardData.get_card(id).get("name", "?")])
		for id in CardData.extra_list(deck):
			if not CardExact.ok(CardData.get_card(int(id))):
				bad.append("%s has %s in the Extra Deck without its effect" % [key, CardData.get_card(int(id)).get("name", "?")])
	check(bad.is_empty(), "every duelist's deck is forty or more, three copies at most, every card working" + ("" if bad.is_empty() else ": " + "; ".join(bad.slice(0, 6))))
	var yusei := CardData.deck_list("yusei").map(func(id): return str(CardData.get_card(id).get("name", "")))
	check(not yusei.has("Beaver Warrior") and not yusei.has("Celtic Guardian"), "Yusei no longer plays Beaver Warrior or Celtic Guardian")
	var yugi := CardData.deck_list("yugi").map(func(id): return str(CardData.get_card(id).get("name", "")))
	check(yugi.has("Dark Magician Girl") and yugi.has("Alpha The Magnet Warrior") and not yugi.has("Gemini Elf"), "Yugi plays Dark Magician Girl and the Magnet Warriors, not Gemini Elf")
	var au := SignatureDecks.audit("kaiba")
	check((au["in"] as Array).has("X-Head Cannon") and (au["plays"] as Array).size() > 10, "the audit says what Kaiba plays and what is his")



func _cid(name: String) -> int:
	return int(CardData.NAME_TO_ID.get(name.to_lower(), 0))


## The cards built in v0.33.27 (Mai, Rex, Alexis), each against its printed text.
func _test_cards_27() -> void:
	# Amazoness Swords Woman: the battle damage you would take goes to the opponent.
	var s := _new_state(71)
	_battle_ready(s)
	var blue := _put(s, 0, _cid("Blue-Eyes White Dragon"), 0)
	var sw := _put(s, 1, _cid("Amazoness Swords Woman"), 0)
	for m in [blue, sw]:
		m.face_up = true
		m.attack_pos = true
	var lp0: int = s.players[0].lp
	var lp1: int = s.players[1].lp
	s.declare_attack(0, blue, sw)
	s.resolve_attack()
	check(s.players[1].lp == lp1 and s.players[0].lp == lp0 - 1500, "Amazoness Swords Woman: the attacker's side takes the 1500 (LP %d / %d)" % [s.players[0].lp, s.players[1].lp])
	# Amazoness Fighter: no battle damage to her controller.
	s = _new_state(72)
	_battle_ready(s)
	blue = _put(s, 0, _cid("Blue-Eyes White Dragon"), 0)
	var fi := _put(s, 1, _cid("Amazoness Fighter"), 0)
	for m in [blue, fi]:
		m.face_up = true
		m.attack_pos = true
	lp1 = s.players[1].lp
	s.declare_attack(0, blue, fi)
	s.resolve_attack()
	check(s.players[1].lp == lp1 and not s.players[1].field.has(fi), "Amazoness Fighter: destroyed, but no battle damage")
	# Black Stego: attacked in Attack Position, it turns to Defense (2000 DEF holds a 1800 attacker).
	s = _new_state(73)
	_battle_ready(s)
	var att := _put(s, 0, _cid("Luster Dragon"), 0)
	var stego := _put(s, 1, _cid("Black Stego"), 0)
	for m in [att, stego]:
		m.face_up = true
		m.attack_pos = true
	s.declare_attack(0, att, stego)
	check(not stego.attack_pos, "Black Stego changes to Defense Position when it is attacked")
	s.resolve_attack()
	check(s.players[1].field.has(stego), "Black Stego survives the 1900 attacker behind 2000 DEF")
	# Hyper Hammerhead: the monster that beat it goes back to the hand.
	s = _new_state(74)
	_battle_ready(s)
	blue = _put(s, 0, _cid("Blue-Eyes White Dragon"), 0)
	var ham := _put(s, 1, _cid("Hyper Hammerhead"), 0)
	for m in [blue, ham]:
		m.face_up = true
		m.attack_pos = true
	s.declare_attack(0, blue, ham)
	s.resolve_attack()
	check(not s.players[0].field.has(blue) and s.players[0].hand.has(blue), "Hyper Hammerhead: the monster that battled it and lived returns to the hand")
	# Element Saurus: +500 with a FIRE monster on the field.
	s = _new_state(75)
	_battle_ready(s)
	var saur := _put(s, 0, _cid("Element Saurus"), 0)
	saur.face_up = true
	check(s.atk_of(saur, false) == 1500, "Element Saurus is 1500 with no FIRE monster on the field")
	var fire := _fake(s, 1, "Fire Thing", 500, 500, 0, {"attribute": "FIRE"})
	fire.face_up = true
	check(s.atk_of(saur, false) == 2000, "Element Saurus is 2000 with a FIRE monster on the field (got %d)" % s.atk_of(saur, false))
	# Babycerasaurus: destroyed by a card effect, it brings a Level 4 or lower Dinosaur from the Deck.
	s = _new_state(76, "rex", "kaiba")
	_battle_ready(s)
	var baby := _put(s, 0, _cid("Babycerasaurus"), 0)
	baby.face_up = true
	s.effect_by = 1
	s._destroy(baby)
	var dino := false
	for m in s.players[0].monsters():
		if str(m.data.get("race", "")) == "Dinosaur" and int(m.data.get("level", 9)) <= 4:
			dino = true
	check(dino, "Babycerasaurus destroyed by an effect: a Level 4 or lower Dinosaur comes from the Deck")
	# Cyber Blader: 1 monster = not destroyed by battle, 2 = ATK doubled, 3 = their effects are negated.
	s = _new_state(77)
	_battle_ready(s)
	var blader := _put(s, 0, _cid("Cyber Blader"), 0)
	blader.face_up = true
	var a1 := _fake(s, 1, "One", 3000, 0, 0)
	check(EffectRunner.survives_battle(s, blader), "Cyber Blader, opponent has 1 monster: not destroyed by battle")
	var a2 := _fake(s, 1, "Two", 100, 0, 1)
	check(s.atk_of(blader, false) == 4200, "Cyber Blader, opponent has 2 monsters: ATK doubled (got %d)" % s.atk_of(blader, false))
	check(not EffectRunner.blader_negates(s, 1), "Cyber Blader, 2 monsters: nothing negated yet")
	var a3 := _fake(s, 1, "Three", 100, 0, 2)
	check(EffectRunner.blader_negates(s, 1) and not EffectRunner.blader_negates(s, 0), "Cyber Blader, opponent has 3 monsters: their activated effects are negated")
	check(s.atk_of(blader, false) == 2100, "Cyber Blader with 3 opposing monsters is back to 2100")
	# Elegant Egotist: needs a Harpie Lady on the field, brings Harpie Lady Sisters from the Deck.
	s = _main_ready(78)
	var ego := _st(s, 0, "Elegant Egotist")
	check(not SpellRules.feasible(s, 0, ego, "open", null), "Elegant Egotist cannot be played without Harpie Lady on the field")
	var lady := _put(s, 0, _cid("Harpie Lady"), 0)
	lady.face_up = true
	var sis := s._make(_cid("Harpie Lady Sisters"), 0)
	s.players[0].deck.append(sis)
	check(not s.can_normal_summon(0, sis), "Harpie Lady Sisters cannot be Normal Summoned")
	check(SpellRules.feasible(s, 0, ego, "open", null), "Elegant Egotist can be played with Harpie Lady on the field")
	s.activate(0, ego)
	s.chain_resolve()
	var out := false
	for m in s.players[0].monsters():
		if m.cname() in ["Harpie Lady Sisters", "Harpie Lady"] and m != lady:
			out = true
	check(out, "Elegant Egotist Special Summons a Harpie Lady or Harpie Lady Sisters")
	# Equips: who they fit.
	s = _main_ready(79)
	var fw := _st(s, 0, "Fusion Weapon")
	var cs := _st(s, 0, "Cyber Shield")
	var fus := _put(s, 0, _cid("Flame Swordsman"), 0)
	fus.face_up = true
	var big := _put(s, 0, _cid("Blue-Eyes Ultimate Dragon"), 1)
	big.face_up = true
	var hl := _put(s, 0, _cid("Harpie Lady"), 2)
	hl.face_up = true
	var tf := SpellRules.targets(s, 0, fw)
	check(tf.has(fus) and not tf.has(big) and not tf.has(hl), "Fusion Weapon fits a Level 6 or lower Fusion Monster only")
	var tc := SpellRules.targets(s, 0, cs)
	check(tc.has(hl) and not tc.has(fus), "Cyber Shield fits Harpie Lady only")
	# Mirror Wall: an attacker is halved, and stays halved while the wall stands.
	s = _new_state(80)
	_battle_ready(s)
	blue = _put(s, 0, _cid("Blue-Eyes White Dragon"), 0)
	blue.face_up = true
	blue.attack_pos = true
	var wall := _st(s, 1, "Mirror Wall", "set", "trap")
	wall.face_up = true
	s.declare_attack(0, blue, null)
	check(s.atk_of(blue, true, null, true) == 1500, "Mirror Wall halves the attacking monster (got %d)" % s.atk_of(blue, true, null, true))
	s.players[1].spells[s.players[1].spells.find(wall)] = null
	check(s.atk_of(blue, false) == 3000, "...and it is whole again once the wall is gone")


func _in(s: DuelState, p: int, name: String, where: String) -> DuelState.CardInst:
	var c := s._make(_cid(name), p)
	match where:
		"hand": s.players[p].hand.append(c)
		"gy": s.players[p].gy.append(c)
		"deck": s.players[p].deck.append(c)
		"extra": s.players[p].extra.append(c)
	return c


func _mon(s: DuelState, p: int, name: String, zone: int, atk_pos := true) -> DuelState.CardInst:
	var c := _put(s, p, _cid(name), zone)
	c.face_up = true
	c.attack_pos = atk_pos
	return c


## The cards built in v0.33.28 (Yusei's best deck), each against its printed text.
func _test_cards_28() -> void:
	# ---------------------------------------------------------------- main deck monsters
	# Sonic Chick: not destroyed by battle with a 1900+ ATK monster, destroyed by a weaker one.
	var s := _new_state(81)
	_battle_ready(s)
	var blue := _mon(s, 0, "Blue-Eyes White Dragon", 0)
	var weak := _fake(s, 0, "Soldier", 1800, 0, 1)
	var chick := _mon(s, 1, "Sonic Chick", 0, false)
	s.declare_attack(0, blue, chick)
	s.resolve_attack()
	check(s.players[1].field.has(chick), "Sonic Chick survives a battle with a 3000 ATK monster")
	s.declare_attack(0, weak, chick)
	s.resolve_attack()
	check(not s.players[1].field.has(chick), "Sonic Chick is destroyed by a monster with less than 1900 ATK")
	# Synchron Explorer: Normal Summoned, it brings a "Synchron" back with its effects negated.
	s = _main_ready(82)
	var junk_gy := _in(s, 0, "Junk Synchron", "gy")
	var explorer := _in(s, 0, "Synchron Explorer", "hand")
	s.normal_summoned = false
	s.normal_summon(0, explorer, [])
	check(s.players[0].field.has(junk_gy) and junk_gy.neg_perm, "Synchron Explorer brings Junk Synchron back with its effects negated")
	# Unknown Synchron: only when the opponent alone has a monster, once per Duel.
	s = _main_ready(83)
	_mon(s, 1, "Blue-Eyes White Dragon", 0)
	var unk := _in(s, 0, "Unknown Synchron", "hand")
	var unk2 := _in(s, 0, "Unknown Synchron", "hand")
	check(s.can_special_from_hand(0, unk), "Unknown Synchron can be Special Summoned while only the opponent has a monster")
	s.special_from_hand(0, unk)
	check(s.players[0].field.has(unk), "Unknown Synchron is on the field")
	s.players[0].field = [null, null, null, null, null]
	check(not s.can_special_from_hand(0, unk2), "Unknown Synchron: only once per Duel this way")
	# Boost Warrior: with a Tuner, from the hand in Defense Position; Warriors gain 300.
	s = _main_ready(84)
	var js := _mon(s, 0, "Junk Synchron", 0)
	var boost := _in(s, 0, "Boost Warrior", "hand")
	check(s.can_special_from_hand(0, boost), "Boost Warrior can come out while you control a Tuner")
	s.special_from_hand(0, boost)
	check(s.players[0].field.has(boost) and not boost.attack_pos, "Boost Warrior arrives in Defense Position")
	check(s.atk_of(js, false) == 1600 and s.atk_of(boost, false) == 600, "Boost Warrior: every Warrior you control gains 300 (Junk Synchron %d, itself %d)" % [s.atk_of(js, false), s.atk_of(boost, false)])
	# Fortress Warrior: no battle damage, and once per turn it is not destroyed by battle.
	s = _new_state(85)
	_battle_ready(s)
	blue = _mon(s, 0, "Blue-Eyes White Dragon", 0)
	var blue2 := _mon(s, 0, "Blue-Eyes White Dragon", 1)
	var fort := _mon(s, 1, "Fortress Warrior", 0)
	var lp1: int = s.players[1].lp
	s.declare_attack(0, blue, fort)
	s.resolve_attack()
	check(s.players[1].field.has(fort) and s.players[1].lp == lp1, "Fortress Warrior: the first battle each turn does not destroy it, and no battle damage")
	s.declare_attack(0, blue2, fort)
	s.resolve_attack()
	check(not s.players[1].field.has(fort) and s.players[1].lp == lp1, "Fortress Warrior: the second battle destroys it, still no battle damage")
	# Rockstone Warrior: it attacks, is destroyed, no damage, 2 Rockstone Tokens.
	s = _new_state(86)
	_battle_ready(s)
	var rock := _mon(s, 0, "Rockstone Warrior", 0)
	blue = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	var lp0: int = s.players[0].lp
	s.declare_attack(0, rock, blue)
	s.resolve_attack()
	var toks: Array = s.players[0].monsters().filter(func(m): return m.is_token())
	check(s.players[0].lp == lp0 and toks.size() == 2, "Rockstone Warrior: no battle damage and 2 Rockstone Tokens (LP %d, tokens %d)" % [s.players[0].lp, toks.size()])
	# Stardust Xiaolong: rises from the Graveyard when Stardust Dragon is Synchro Summoned.
	s = _main_ready(87)
	_mon(s, 0, "Junk Synchron", 0)
	var sp5 := _fake(s, 0, "Five", 1000, 1000, 1, {"level": 5})
	var xiao := _in(s, 0, "Stardust Xiaolong", "gy")
	var star := _in(s, 0, "Stardust Dragon", "extra")
	check(s.can_extra_summon(0, star), "Stardust Dragon can be made from Junk Synchron and a Level 5")
	s.extra_summon(0, star)
	check(s.players[0].field.has(xiao) and xiao.attack_pos, "Stardust Xiaolong returns in Attack Position when Stardust Dragon is Synchro Summoned")
	check(int(star.tags.get("non_tuners", 0)) == 1 and int(star.tags.get("mats", 0)) == 2, "A Synchro Monster remembers what it was made with")
	# Healing Wave Generator: LP equal to another monster's Level x 100.
	s = _main_ready(88)
	var heal := _mon(s, 0, "Healing Wave Generator", 0)
	_mon(s, 0, "Blue-Eyes White Dragon", 1)
	lp0 = s.players[0].lp
	check(s.can_ignite(0, heal), "Healing Wave Generator can use its effect with another monster out")
	s.ignite(0, heal)
	check(s.players[0].lp == lp0 + 800, "Healing Wave Generator: +800 LP from a Level 8 monster (got %d)" % (s.players[0].lp - lp0))
	# Level Warrior: Level 4 from the hand; Level 2 by Normal Summon on an empty field.
	s = _main_ready(89)
	_mon(s, 1, "Blue-Eyes White Dragon", 0)
	var lw := _in(s, 0, "Level Warrior", "hand")
	s.special_from_hand(0, lw)
	check(s.players[0].field.has(lw) and lw.level() == 4, "Level Warrior is Level 4 when Special Summoned from the hand (Level %d)" % lw.level())
	s = _main_ready(90)
	lw = _in(s, 0, "Level Warrior", "hand")
	s.normal_summoned = false
	s.normal_summon(0, lw, [])
	check(lw.level() == 2, "Level Warrior is Level 2 when Normal Summoned with no monsters on the field (Level %d)" % lw.level())
	# Turret Warrior: Tribute a Warrior, gain its original ATK.
	s = _main_ready(91)
	var fod := _fake(s, 0, "Big Warrior", 1800, 0, 0)
	var turret := _in(s, 0, "Turret Warrior", "hand")
	check(s.can_special_from_hand(0, turret), "Turret Warrior can come out by Tributing a Warrior")
	s.special_from_hand(0, turret)
	check(s.players[0].field.has(turret) and not s.players[0].field.has(fod) and s.atk_of(turret, false) == 3000, "Turret Warrior: 1200 + the Tributed Warrior's 1800 (got %d)" % s.atk_of(turret, false))
	# Zero Gardna: Tributed in the opponent's turn, no battle destruction and no battle damage.
	s = _new_state(92)
	_battle_ready(s)
	blue = _mon(s, 0, "Blue-Eyes White Dragon", 0)
	var zero := _mon(s, 1, "Zero Gardna", 0)
	var friend := _fake(s, 1, "Friend", 1000, 0, 1)
	lp1 = s.players[1].lp
	s.declare_attack(0, blue, friend)
	check(s.responses(1, "attack").has(zero), "Zero Gardna can answer an attack")
	s.respond(1, zero)
	s.resolve_attack()
	check(s.players[1].field.has(friend) and s.players[1].lp == lp1 and not s.players[1].field.has(zero), "Zero Gardna: Tributed; the monster lives and no battle damage")
	# Ghost Gardna: takes the attack; destroyed, the attacker loses 1000 ATK until the End Phase.
	s = _new_state(93)
	_battle_ready(s)
	blue = _mon(s, 0, "Blue-Eyes White Dragon", 0)
	var ghost := _mon(s, 1, "Ghost Gardna", 0, false)
	friend = _fake(s, 1, "Friend", 1000, 0, 1)
	s.declare_attack(0, blue, friend)
	check(s.responses(1, "attack").has(ghost), "Ghost Gardna can take an attack aimed at another monster")
	s.respond(1, ghost)
	s.resolve_attack()
	check(s.players[1].field.has(friend) and not s.players[1].field.has(ghost), "Ghost Gardna took the attack and was destroyed")
	check(s.atk_of(blue, false) == 2000, "Ghost Gardna: the opponent's monster loses 1000 ATK until the End Phase (got %d)" % s.atk_of(blue, false))
	# Debris Dragon: brings back a 500 ATK or less monster, negated; only for a Dragon Synchro, no Level 4 partners.
	s = _main_ready(94)
	var sw := _in(s, 0, "Speed Warrior", "gy")
	sw.data = sw.data.duplicate()
	var chick_gy := _in(s, 0, "Sonic Chick", "gy")
	var debris := _in(s, 0, "Debris Dragon", "hand")
	s.normal_summoned = false
	s.normal_summon(0, debris, [])
	check(s.players[0].field.has(chick_gy) and chick_gy.attack_pos and chick_gy.neg_perm, "Debris Dragon brings back a 500 ATK or less monster in Attack Position, negated")
	var lv3 := _fake(s, 0, "Three", 500, 500, 2, {"level": 3})
	star = _in(s, 0, "Stardust Dragon", "extra")
	var jw := _in(s, 0, "Junk Warrior", "extra")
	var colossal := _in(s, 0, "Colossal Fighter", "extra")
	check(s.can_extra_summon(0, star), "Debris Dragon (4) + Level 3 + Level 1 makes Stardust Dragon")
	check(not s.can_extra_summon(0, colossal), "Debris Dragon cannot be a material for a non-Dragon Synchro Monster")
	lv3.data["level"] = 4
	chick_gy.lv_set = 0
	s.players[0].field[s.players[0].field.find(chick_gy)] = null
	check(not s.can_extra_summon(0, star), "Debris Dragon cannot be used with a Level 4 material")
	# Salvage Warrior: Tribute Summoned, a Tuner from the hand or Graveyard.
	s = _main_ready(95)
	var trib := _fake(s, 0, "Fodder", 500, 500, 0)
	var salv := _in(s, 0, "Salvage Warrior", "hand")
	var tun_h := _in(s, 0, "Junk Synchron", "gy")
	s.normal_summoned = false
	s.normal_summon(0, salv, [trib])
	check(s.players[0].field.has(salv) and s.players[0].field.has(tun_h), "Salvage Warrior: Tribute Summoned, it brings a Tuner out of the Graveyard")
	# Tuningware: counts as Level 2 for a Synchro Summon, and draws 1.
	s = _main_ready(96)
	_mon(s, 0, "Junk Synchron", 0)
	var ware := _mon(s, 0, "Tuningware", 1)
	jw = _in(s, 0, "Junk Warrior", "extra")
	check(s.can_extra_summon(0, jw), "Junk Synchron (3) + Tuningware as Level 2 makes the Level 5 Junk Warrior")
	var hand_n: int = s.players[0].hand.size()
	s.extra_summon(0, jw)
	check(s.players[0].field.has(jw) and s.players[0].hand.size() == hand_n + 1, "Tuningware: draw 1 card when it is sent to the Graveyard as a Synchro Material")
	# Road Synchron: Level 2 for anything but Road Warrior; Road Warrior needs 2 non-Tuners.
	s = _main_ready(97)
	var road := _mon(s, 0, "Road Synchron", 0)
	var two_a := _fake(s, 0, "Two A", 500, 500, 1, {"level": 2})
	var arm := _in(s, 0, "Armory Arm", "extra")
	var rw := _in(s, 0, "Road Warrior", "extra")
	check(s.can_extra_summon(0, arm), "Road Synchron counts as Level 2: with a Level 2 it makes the Level 4 Armory Arm")
	check(not s.can_extra_summon(0, rw), "Road Warrior needs 2 or more non-Tuners")
	var two_b := _fake(s, 0, "Two B", 500, 500, 2, {"level": 2})
	check(s.can_extra_summon(0, rw), "Road Synchron (4) + 2 + 2 makes the Level 8 Road Warrior")
	s.phase = DuelState.Phase.BATTLE
	var dummy := _fake(s, 1, "Wall", 0, 3000, 0)
	dummy.attack_pos = false
	s.declare_attack(0, road, dummy)
	s.resolve_attack()
	check(road.level() == 5, "Road Synchron: Level +1 after it attacks (Level %d)" % road.level())
	# Turbo Synchron: the target turns to Defense; the damage taken brings a monster out of the hand.
	s = _new_state(98)
	_battle_ready(s)
	var turbo := _mon(s, 0, "Turbo Synchron", 0)
	var wall2 := _fake(s, 1, "Wall", 2000, 1600, 0)
	s.players[0].hand.clear()
	var small := _in(s, 0, "Speed Warrior", "hand")
	s.declare_attack(0, turbo, wall2)
	check(not wall2.attack_pos, "Turbo Synchron turns its attack target to Defense Position")
	s.resolve_attack()
	check(s.players[0].field.has(small), "Turbo Synchron: 1500 battle damage taken brings a 900 ATK monster out of the hand")
	# Drill Synchron: your Warriors pierce, and you draw 1 once per turn.
	s = _new_state(99)
	_battle_ready(s)
	_mon(s, 0, "Drill Synchron", 0)
	var war := _fake(s, 0, "Warrior", 2000, 0, 1)
	var soft := _fake(s, 1, "Soft", 0, 500, 0)
	soft.attack_pos = false
	lp1 = s.players[1].lp
	hand_n = s.players[0].hand.size()
	s.declare_attack(0, war, soft)
	s.resolve_attack()
	check(s.players[1].lp == lp1 - 1500 and s.players[0].hand.size() == hand_n + 1, "Drill Synchron: a Warrior deals 1500 piercing damage and you draw 1")
	# Hyper Synchron: the Dragon it made gains 800 ATK and is banished in the End Phase.
	s = _main_ready(100)
	_mon(s, 0, "Hyper Synchron", 0)
	_fake(s, 0, "Four", 500, 500, 1, {"level": 4})
	star = _in(s, 0, "Stardust Dragon", "extra")
	s.extra_summon(0, star)
	check(s.players[0].field.has(star) and s.atk_of(star, false) == 3300, "Hyper Synchron: the Dragon Synchro Monster gains 800 ATK (got %d)" % s.atk_of(star, false))
	s.begin_end()
	check(s.players[0].banished.has(star), "Hyper Synchron: that monster is banished in the End Phase")
	# Quickdraw Synchron: by sending a monster from the hand; stands in for Junk Synchron; not for a generic Tuner.
	s = _main_ready(101)
	var quick := _in(s, 0, "Quickdraw Synchron", "hand")
	var cost_m := _in(s, 0, "Speed Warrior", "hand")
	check(s.can_special_from_hand(0, quick), "Quickdraw Synchron can come out by sending a monster from the hand to the Graveyard")
	s.special_from_hand(0, quick)
	check(s.players[0].field.has(quick) and s.players[0].gy.has(cost_m), "Quickdraw Synchron is out and the monster is in the Graveyard")
	_fake(s, 0, "Three", 500, 500, 1, {"level": 3})
	var destroyer := _in(s, 0, "Junk Destroyer", "extra")
	star = _in(s, 0, "Stardust Dragon", "extra")
	check(s.can_extra_summon(0, destroyer), "Quickdraw Synchron stands in for Junk Synchron (5 + 3 = Junk Destroyer)")
	check(not s.can_extra_summon(0, star), "Quickdraw Synchron cannot be used for a monster that does not name a \"Synchron\" Tuner")
	# Level Eater: from the Graveyard, eating a Level of a Level 5 or higher monster.
	s = _main_ready(102)
	star = _mon(s, 0, "Stardust Dragon", 0)
	var eater := _in(s, 0, "Level Eater", "gy")
	check(s.gy_effects(0).has(eater), "Level Eater can use its effect with a Level 8 monster out")
	s.gy_ignite(0, eater)
	check(s.players[0].field.has(eater) and star.level() == 7, "Level Eater is Special Summoned and Stardust Dragon is Level 7 (Level %d)" % star.level())
	check(not s.can_tribute_fx(eater), "Level Eater cannot be Tributed for an effect")
	# Doppelwarrior: follows a monster out of the Graveyard; 2 Doppel Tokens as a Synchro Material.
	s = _main_ready(103)
	var dop := _in(s, 0, "Doppelwarrior", "hand")
	var dead := _in(s, 0, "Speed Warrior", "gy")
	s.players[0].gy.erase(dead)
	s._special(0, dead, "reborn")
	check(s.players[0].field.has(dop), "Doppelwarrior comes out of the hand when a monster is Special Summoned from your Graveyard")
	_mon(s, 0, "Junk Synchron", 2)
	s.players[0].field[s.players[0].field.find(dead)] = null
	jw = _in(s, 0, "Junk Warrior", "extra")
	s.extra_summon(0, jw)
	toks = s.players[0].monsters().filter(func(m): return m.is_token())
	check(s.players[0].field.has(jw) and toks.size() == 2 and toks[0].attack_pos and toks[0].atk() == 400, "Doppelwarrior: 2 Doppel Tokens (400 ATK) in Attack Position (tokens %d)" % toks.size())
	# Effect Veiler: from the hand in the opponent's Main Phase, a monster's effects are negated this turn.
	s = _main_ready(104)
	var veil := _in(s, 1, "Effect Veiler", "hand")
	var bw := _mon(s, 0, "Boost Warrior", 0)
	check(s.responses(1, "phase").has(veil), "Effect Veiler can be used from the hand in the opponent's Main Phase")
	s.respond(1, veil)
	check(bw.negated and s.players[1].gy.has(veil) and s.atk_of(bw, false) == 300, "Effect Veiler: the monster's effects are negated (Boost Warrior back to 300, got %d)" % s.atk_of(bw, false))
	# ---------------------------------------------------------------- the Extra Deck
	# Formula Synchron: draw 1; a Synchro Summon in the opponent's Main Phase. Shooting Star Dragon's materials.
	s = _main_ready(105)
	_mon(s, 0, "Unknown Synchron", 0)
	_fake(s, 0, "One", 100, 100, 1, {"level": 1})
	var formula := _in(s, 0, "Formula Synchron", "extra")
	hand_n = s.players[0].hand.size()
	check(s.can_extra_summon(0, formula), "Formula Synchron: 1 Tuner + 1 non-Tuner (1 + 1)")
	s.extra_summon(0, formula)
	check(s.players[0].field.has(formula) and s.players[0].hand.size() == hand_n + 1 and formula.is_tuner(), "Formula Synchron is a Tuner and draws 1 when Synchro Summoned")
	star = _mon(s, 0, "Stardust Dragon", 2)
	var ssd := _in(s, 0, "Shooting Star Dragon", "extra")
	check(s.can_extra_summon(0, ssd), "Shooting Star Dragon: 1 Tuner Synchro Monster + Stardust Dragon")
	s.current = 1
	check(s.responses(0, "phase").has(formula), "Formula Synchron can Synchro Summon in the opponent's Main Phase")
	s.respond(0, formula)
	check(s.players[0].field.has(ssd) and ssd.proper, "Formula Synchron + Stardust Dragon: Shooting Star Dragon in the opponent's turn")
	# Shooting Star Dragon: a generic Tuner is not enough.
	s = _main_ready(106)
	_mon(s, 0, "Junk Synchron", 0)
	_mon(s, 0, "Stardust Dragon", 1)
	ssd = _in(s, 0, "Shooting Star Dragon", "extra")
	check(not s.can_extra_summon(0, ssd), "Shooting Star Dragon needs a Tuner that is a Synchro Monster")
	# Shooting Star Dragon: one attack for each Tuner among the top 5.
	s = _main_ready(107)
	ssd = _mon(s, 0, "Shooting Star Dragon", 0)
	s.players[0].deck.clear()
	for nm in ["Junk Synchron", "Speed Warrior", "Nitro Synchron", "Sonic Chick", "Turbo Synchron", "Max Warrior"]:
		_in(s, 0, nm, "deck")
	s.players[0].deck.reverse()   # the top of the Deck is the end of the list: Junk Synchron first
	check(s.can_ignite(0, ssd), "Shooting Star Dragon can reveal the top 5 cards in Main Phase 1")
	s.ignite(0, ssd)
	s.phase = DuelState.Phase.BATTLE
	check(s.attacks_left(ssd) == 3, "Shooting Star Dragon: 3 Tuners among the top 5 cards = 3 attacks (got %d)" % s.attacks_left(ssd))
	# ...negates an effect that would destroy a card, and destroys that card.
	s = _main_ready(108)
	ssd = _mon(s, 0, "Shooting Star Dragon", 0)
	s.current = 1
	var boom := _st(s, 1, "Dark Hole")
	boom.data = CardData.get_card(_cid("Dark Hole")).duplicate()
	check(not s.chain_add(1, boom).is_empty(), "The opponent activates Dark Hole")
	check(s.responses(0, "chain", s.chain.back()).has(ssd), "Shooting Star Dragon can answer an effect that would destroy a card")
	s.respond(0, ssd)
	s.chain_resolve()
	check(s.players[0].field.has(ssd) and s.players[1].gy.has(boom), "Shooting Star Dragon negated Dark Hole, destroyed it, and is still on the field")
	# ...and steps out of an attack: banished, the attack is negated, back in the End Phase.
	s = _new_state(109)
	_battle_ready(s)
	blue = _mon(s, 0, "Blue-Eyes White Dragon", 0)
	ssd = _mon(s, 1, "Shooting Star Dragon", 0)
	var weak1 := _fake(s, 1, "Weak", 500, 0, 1)
	lp1 = s.players[1].lp
	s.declare_attack(0, blue, weak1)
	check(s.responses(1, "attack").has(ssd), "Shooting Star Dragon can answer an opponent's attack")
	s.respond(1, ssd)
	s.resolve_attack()
	check(s.players[1].banished.has(ssd) and s.players[1].field.has(weak1) and s.players[1].lp == lp1, "Shooting Star Dragon is banished and the attack is negated")
	s.begin_end()
	check(s.players[1].field.has(ssd), "Shooting Star Dragon returns in the End Phase")
	# Shooting Quasar Dragon: Tuner Synchro + 2 non-Tuner Synchros; 2 attacks; negates; leaves Shooting Star Dragon behind.
	s = _main_ready(110)
	_mon(s, 0, "Formula Synchron", 0)
	_mon(s, 0, "Junk Warrior", 1)
	var quasar := _in(s, 0, "Shooting Quasar Dragon", "extra")
	check(not s.can_extra_summon(0, quasar), "Shooting Quasar Dragon needs 2 or more non-Tuner Synchro Monsters")
	_mon(s, 0, "Junk Warrior", 2)
	check(s.can_extra_summon(0, quasar), "Formula Synchron (2) + Junk Warrior (5) + Junk Warrior (5) = Shooting Quasar Dragon (12)")
	s.extra_summon(0, quasar)
	check(s.players[0].field.has(quasar) and EffectRunner.max_attacks(quasar) == 2, "Shooting Quasar Dragon: 2 non-Tuners, 2 attacks (got %d)" % EffectRunner.max_attacks(quasar))
	ssd = _in(s, 0, "Shooting Star Dragon", "extra")
	s.current = 1
	var pot := _st(s, 1, "Pot of Greed")
	pot.data = CardData.get_card(_cid("Pot of Greed")).duplicate()
	var opp_hand: int = s.players[1].hand.size()
	s.phase = DuelState.Phase.MAIN1
	check(not s.chain_add(1, pot).is_empty(), "The opponent activates Pot of Greed")
	check(s.responses(0, "chain", s.chain.back()).has(quasar), "Shooting Quasar Dragon can answer any activation")
	s.respond(0, quasar)
	s.chain_resolve()
	check(s.players[1].hand.size() == opp_hand - 1 and s.players[1].gy.has(pot), "Shooting Quasar Dragon negated Pot of Greed (no draw) and destroyed it")
	s._banish(quasar)
	check(s.players[0].field.has(ssd), "Shooting Quasar Dragon leaves the field: Shooting Star Dragon comes out of the Extra Deck")
	check(not s.can_revive(quasar), "Shooting Quasar Dragon must be Synchro Summoned")
	# Junk Destroyer: destroys up to as many cards as non-Tuners used.
	s = _main_ready(111)
	_mon(s, 0, "Junk Synchron", 0)
	_fake(s, 0, "Two", 100, 100, 1, {"level": 2})
	_fake(s, 0, "Three", 100, 100, 2, {"level": 3})
	_mon(s, 1, "Blue-Eyes White Dragon", 0)
	_mon(s, 1, "Blue-Eyes White Dragon", 1)
	_mon(s, 1, "Blue-Eyes White Dragon", 2)
	destroyer = _in(s, 0, "Junk Destroyer", "extra")
	s.extra_summon(0, destroyer)
	check(s.players[0].field.has(destroyer) and s.players[1].monsters().size() == 1, "Junk Destroyer: 2 non-Tuners, 2 cards destroyed (their monsters left: %d)" % s.players[1].monsters().size())
	# Junk Archer: banished until the End Phase.
	s = _main_ready(112)
	var archer := _mon(s, 0, "Junk Archer", 0)
	blue = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	s.ignite(0, archer)
	check(s.players[1].banished.has(blue), "Junk Archer banishes a monster")
	s.begin_end()
	check(s.players[1].field.has(blue), "Junk Archer: the monster returns in the End Phase")
	# Junk Berserker: a "Junk" monster banished from the Graveyard takes its ATK off a monster; Defense monsters die at once.
	s = _main_ready(113)
	var bers := _mon(s, 0, "Junk Berserker", 0)
	_in(s, 0, "Junk Warrior", "gy")
	blue = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	var def_m := _fake(s, 1, "Big Wall", 0, 4000, 1)
	def_m.attack_pos = false
	check(s.can_ignite(0, bers), "Junk Berserker can use a \"Junk\" monster in the Graveyard")
	s.ignite(0, bers)
	check(s.atk_of(blue, false) == 700, "Junk Berserker: Blue-Eyes loses Junk Warrior's 2300 ATK (got %d)" % s.atk_of(blue, false))
	s.phase = DuelState.Phase.BATTLE
	lp0 = s.players[0].lp
	s.declare_attack(0, bers, def_m)
	s.resolve_attack()
	check(not s.players[1].field.has(def_m) and s.players[0].lp == lp0, "Junk Berserker destroys a Defense Position monster at the start of the Damage Step")
	# Junk Gardna: in the opponent's turn it turns the attacker to Defense Position, and the attack stops.
	s = _new_state(114)
	_battle_ready(s)
	blue = _mon(s, 0, "Blue-Eyes White Dragon", 0)
	var gardna := _mon(s, 1, "Junk Gardna", 0)
	gardna.attack_pos = true
	s.declare_attack(0, blue, gardna)
	check(s.responses(1, "attack").has(gardna), "Junk Gardna can answer an attack")
	s.respond(1, gardna)
	s.resolve_attack()
	check(not blue.attack_pos and s.players[1].field.has(gardna), "Junk Gardna: the attacker is turned to Defense Position and the attack stops")
	# Road Warrior: a Level 2 or lower Warrior or Machine from the Deck.
	s = _main_ready(115)
	rw = _mon(s, 0, "Road Warrior", 0)
	s.players[0].deck.clear()
	var from_deck := _in(s, 0, "Speed Warrior", "deck")
	_in(s, 0, "Blue-Eyes White Dragon", "deck")
	check(s.can_ignite(0, rw), "Road Warrior can call a Level 2 or lower Warrior or Machine")
	s.ignite(0, rw)
	check(s.players[0].field.has(from_deck), "Road Warrior Special Summons Speed Warrior from the Deck")
	# Turbo Warrior: halves a Level 6+ Synchro Monster it attacks; Level 6 or lower monsters cannot target it.
	s = _new_state(116)
	_battle_ready(s)
	var tw := _mon(s, 0, "Turbo Warrior", 0)
	var big := _mon(s, 1, "Stardust Dragon", 0)
	lp1 = s.players[1].lp
	s.declare_attack(0, tw, big)
	s.resolve_attack()
	check(not s.players[1].field.has(big) and s.players[1].lp == lp1 - 1250, "Turbo Warrior: Stardust Dragon fights at 1250 and loses (LP -%d)" % (lp1 - s.players[1].lp))
	check(not EffectRunner.can_target(_fake(s, 1, "Four", 0, 0, -1), tw) and EffectRunner.can_target(_fake(s, 1, "Seven", 0, 0, -1, {"level": 7}), tw), "Turbo Warrior cannot be targeted by a Level 6 or lower monster's effect")
	# Nitro Warrior: after a kill, a Defense Position monster is turned up and it attacks that one next.
	s = _new_state(117)
	_battle_ready(s)
	var nitro := _mon(s, 0, "Nitro Warrior", 0)
	var first := _fake(s, 1, "First", 1000, 0, 0)
	var second := _fake(s, 1, "Second", 500, 2000, 1)
	second.attack_pos = false
	var third := _fake(s, 1, "Third", 100, 0, 2)
	s.declare_attack(0, nitro, first)
	s.resolve_attack()
	check(second.attack_pos and s.attacks_left(nitro) == 1, "Nitro Warrior: the Defense Position monster is turned to Attack Position and it can attack again")
	check(s.attack_targets_for(0, nitro).size() == 1 and s.attack_targets_for(0, nitro)[0] == second and not s.can_direct_attack_with(0, nitro), "Nitro Warrior's second attack is on that monster only")
	s.declare_attack(0, nitro, second)
	s.resolve_attack()
	check(not s.players[1].field.has(second) and s.players[1].field.has(third) and s.attacks_left(nitro) == 0, "Nitro Warrior: the second attack lands and there is no third")
	# Armory Arm: equipped, +1000 ATK; a kill burns for the destroyed monster's ATK.
	s = _main_ready(118)
	arm = _mon(s, 0, "Armory Arm", 0)
	var host := _fake(s, 0, "Host", 2000, 0, 1)
	var prey := _fake(s, 1, "Prey", 1500, 0, 0)
	check(s.can_ignite(0, arm), "Armory Arm can equip itself to a monster")
	s.ignite(0, arm)
	check(arm.equipped_to == host and s.atk_of(host, false) == 3000 and s.def_of(host) == 0, "Armory Arm: the equipped monster gains 1000 ATK only (ATK %d)" % s.atk_of(host, false))
	s.phase = DuelState.Phase.BATTLE
	lp1 = s.players[1].lp
	s.declare_attack(0, host, prey)
	s.resolve_attack()
	check(s.players[1].lp == lp1 - 1500 - 1500, "Armory Arm: 1500 battle damage and 1500 more for the destroyed monster's ATK (LP -%d)" % (lp1 - s.players[1].lp))
	# Drill Warrior: half ATK for a direct attack; dig in and come back with a monster.
	s = _main_ready(119)
	var drill := _mon(s, 0, "Drill Warrior", 0)
	_mon(s, 1, "Blue-Eyes White Dragon", 0)
	check(s.can_ignite(0, drill), "Drill Warrior can use an effect")
	s.ignite(0, drill)
	check(s.atk_of(drill, false) == 1200 and s.can_direct_attack_with(0, drill), "Drill Warrior: ATK halved to 1200 and it can attack directly")
	_in(s, 0, "Speed Warrior", "hand")
	var back_m := _in(s, 0, "Junk Synchron", "gy")
	check(s.can_ignite(0, drill), "Drill Warrior can still use its other effect this turn")
	s.ignite(0, drill)
	check(s.players[0].banished.has(drill), "Drill Warrior: discard 1 card, it is banished")
	s.current = 0
	s.begin_standby()
	check(s.players[0].field.has(drill) and (s.players[0].hand.has(back_m) or s.players[0].hand.any(func(h): return h.is_monster())), "Drill Warrior returns in your next Standby Phase and a monster comes back to the hand")
	# Lightning Warrior: 300 for each card in the opponent's hand.
	s = _new_state(120)
	_battle_ready(s)
	var lightning := _mon(s, 0, "Lightning Warrior", 0)
	prey = _fake(s, 1, "Prey", 2400 - 100, 0, 0)
	lp1 = s.players[1].lp
	var cards_h: int = s.players[1].hand.size()
	s.declare_attack(0, lightning, prey)
	s.resolve_attack()
	check(cards_h > 0 and s.players[1].lp == lp1 - 100 - 300 * cards_h, "Lightning Warrior: 300 damage for each of the %d cards in their hand" % cards_h)
	# Colossal Fighter: +100 for each Warrior in the Graveyards; destroyed by battle, a Warrior returns.
	s = _new_state(121)
	_battle_ready(s)
	var col := _mon(s, 1, "Colossal Fighter", 0)
	col.proper = true
	s.players[0].gy.clear()
	s.players[1].gy.clear()
	_in(s, 0, "Speed Warrior", "gy")
	_in(s, 1, "Junk Synchron", "gy")
	check(s.atk_of(col, false) == 3000, "Colossal Fighter: 2800 + 100 for each of the 2 Warriors in the Graveyards (got %d)" % s.atk_of(col, false))
	var giant := _fake(s, 0, "Giant", 5000, 0, 0)
	s.declare_attack(0, giant, col)
	s.resolve_attack()
	check(s.players[1].field.has(col), "Colossal Fighter: destroyed by battle, it brings a Warrior back (itself, the strongest)")
	# ---------------------------------------------------------------- Spells and Traps
	# Tuning: a "Synchron" Tuner to the hand, then the top card of the Deck to the Graveyard.
	s = _main_ready(122)
	s.players[0].deck.clear()
	var syn := _in(s, 0, "Junk Synchron", "deck")
	var top_c := _in(s, 0, "Speed Warrior", "deck")
	var tuning := _st(s, 0, "Tuning")
	check(s.can_activate(0, tuning), "Tuning can be activated with a \"Synchron\" Tuner in the Deck")
	s.activate(0, tuning)
	check(s.players[0].hand.has(syn) and s.players[0].gy.has(top_c), "Tuning: Junk Synchron to the hand, the top card to the Graveyard")
	# One for One: send a monster, a Level 1 from the hand or Deck.
	s = _main_ready(123)
	s.players[0].deck.clear()
	s.players[0].hand.clear()
	var lv1 := _in(s, 0, "Tuningware", "deck")
	var sent := _in(s, 0, "Speed Warrior", "hand")
	var ofo := _st(s, 0, "One for One")
	check(s.can_activate(0, ofo), "One for One can be activated")
	s.activate(0, ofo)
	check(s.players[0].gy.has(sent) and s.players[0].field.has(lv1), "One for One: a monster goes to the Graveyard, a Level 1 comes out of the Deck")
	# Double Summon: a second Normal Summon this turn.
	s = _main_ready(124)
	s.players[0].hand.clear()
	var a1 := _in(s, 0, "Speed Warrior", "hand")
	var a2 := _in(s, 0, "Sonic Chick", "hand")
	s.normal_summoned = false
	s.normal_summon(0, a1, [])
	check(not s.can_normal_summon(0, a2), "One Normal Summon each turn")
	var dbl := _st(s, 0, "Double Summon")
	s.activate(0, dbl)
	check(s.can_normal_summon(0, a2), "Double Summon: a second Normal Summon")
	s.normal_summon(0, a2, [])
	var a3 := _in(s, 0, "Sonic Chick", "hand")
	check(s.players[0].field.has(a2) and not s.can_normal_summon(0, a3), "Double Summon: two, not three")
	# Cards of Consonance: discard a Dragon Tuner with 1000 or less ATK, draw 2.
	s = _main_ready(125)
	s.players[0].hand.clear()
	var coc := _st(s, 0, "Cards of Consonance")
	check(not s.can_activate(0, coc), "Cards of Consonance needs a Dragon Tuner with 1000 or less ATK in the hand")
	var deb := _in(s, 0, "Debris Dragon", "hand")
	check(s.can_activate(0, coc), "Cards of Consonance can be activated with Debris Dragon in the hand")
	s.activate(0, coc)
	check(s.players[0].gy.has(deb) and s.players[0].hand.size() == 2, "Cards of Consonance: Debris Dragon discarded, 2 cards drawn")
	# Card Rotator: every monster they control changes position.
	s = _main_ready(126)
	blue = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	var hidden := _fake(s, 1, "Hidden", 500, 500, 1)
	hidden.face_up = false
	hidden.attack_pos = false
	_in(s, 0, "Speed Warrior", "hand")
	var rot := _st(s, 0, "Card Rotator")
	s.activate(0, rot)
	check(not blue.attack_pos and hidden.face_up and hidden.attack_pos, "Card Rotator: Attack to Defense, face-down Defense to face-up Attack")
	# Fighting Spirit: 300 for each monster they control; it is destroyed in the monster's place.
	s = _main_ready(127)
	var fighter := _fake(s, 0, "Fighter", 1000, 0, 0)
	blue = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	_mon(s, 1, "Blue-Eyes White Dragon", 1)
	var spirit := _st(s, 0, "Fighting Spirit")
	s.activate(0, spirit, fighter)
	check(s.atk_of(fighter, false) == 1600, "Fighting Spirit: +300 for each of their 2 monsters (got %d)" % s.atk_of(fighter, false))
	s.current = 1
	s.phase = DuelState.Phase.BATTLE
	s.declare_attack(1, blue, fighter)
	s.resolve_attack()
	check(s.players[0].field.has(fighter) and s.players[0].gy.has(spirit), "Fighting Spirit is destroyed instead of the monster")
	# Silver Wing: only a Level 8+ Dragon Synchro; twice per turn no battle destruction; takes an effect's hit.
	s = _main_ready(128)
	star = _mon(s, 0, "Stardust Dragon", 0)
	var plain := _fake(s, 0, "Plain", 1000, 0, 1)
	var wing := _st(s, 0, "Silver Wing")
	check(SpellRules.targets(s, 0, wing) == [star], "Silver Wing can only be equipped to a Level 8 or higher Dragon Synchro Monster")
	s.activate(0, wing, star)
	var g1 := _fake(s, 1, "G1", 4000, 0, 0)
	var g2 := _fake(s, 1, "G2", 4000, 0, 1)
	var g3 := _fake(s, 1, "G3", 4000, 0, 2)
	s.current = 1
	s.phase = DuelState.Phase.BATTLE
	for g in [g1, g2]:
		s.declare_attack(1, g, star)
		s.resolve_attack()
	check(s.players[0].field.has(star), "Silver Wing: twice per turn the monster is not destroyed by battle")
	s.declare_attack(1, g3, star)
	s.resolve_attack()
	check(not s.players[0].field.has(star), "Silver Wing: the third battle destroys it")
	s = _main_ready(129)
	star = _mon(s, 0, "Stardust Dragon", 0)
	wing = _st(s, 0, "Silver Wing")
	s.activate(0, wing, star)
	s.effect_by = 1
	s._destroy(star)
	s.effect_by = -1
	check(s.players[0].field.has(star) and s.players[0].gy.has(wing), "Silver Wing is destroyed instead when a card effect would destroy the monster")
	# Graceful Revival: a Level 2 or lower monster in Attack Position; they go together.
	s = _main_ready(130)
	s.players[0].gy.clear()
	var small_gy := _in(s, 0, "Speed Warrior", "gy")
	_in(s, 0, "Blue-Eyes White Dragon", "gy")
	var grace := _st(s, 0, "Graceful Revival", "set", "trap")
	check(s.can_activate(0, grace), "Graceful Revival can be activated")
	s.activate(0, grace)
	check(s.players[0].field.has(small_gy) and small_gy.attack_pos, "Graceful Revival: the Level 2 monster returns in Attack Position")
	s._destroy_st(grace)
	check(not s.players[0].field.has(small_gy), "Graceful Revival leaves the field: the monster is destroyed")
	# Shooting Star: only with a "Stardust" monster on the field.
	s = _main_ready(131)
	blue = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	var shoot := _st(s, 0, "Shooting Star", "set", "trap")
	check(not s.can_activate(0, shoot), "Shooting Star needs a \"Stardust\" monster on the field")
	_mon(s, 0, "Stardust Dragon", 0)
	check(s.can_activate(0, shoot), "Shooting Star can be activated with Stardust Dragon out")
	s.activate(0, shoot, blue)
	check(not s.players[1].field.has(blue), "Shooting Star destroys the target")
	# Synchro Strike: 500 for each material.
	s = _main_ready(132)
	_mon(s, 0, "Junk Synchron", 0)
	_fake(s, 0, "Two", 100, 100, 1, {"level": 2})
	jw = _in(s, 0, "Junk Warrior", "extra")
	s.extra_summon(0, jw)
	var base_atk: int = s.atk_of(jw, false)
	var strike := _st(s, 0, "Synchro Strike", "set", "trap")
	s.activate(0, strike, jw)
	check(s.atk_of(jw, false) == base_atk + 1000, "Synchro Strike: +500 for each of the 2 materials (got +%d)" % (s.atk_of(jw, false) - base_atk))
	# Skill Successor: +400 as a Trap; +800 from the Graveyard, not the turn it got there.
	s = _main_ready(133)
	var hero := _fake(s, 0, "Hero", 1000, 0, 0)
	var skill := _st(s, 0, "Skill Successor", "set", "trap")
	s.activate(0, skill, hero)
	check(s.atk_of(hero, false) == 1400 and s.players[0].gy.has(skill), "Skill Successor: +400 ATK until the end of the turn")
	check(not s.gy_effects(0).has(skill), "Skill Successor cannot be used from the Graveyard the turn it was sent there")
	s.turn += 2
	check(s.gy_effects(0).has(skill), "Skill Successor can be banished from the Graveyard in a later turn of yours")
	s.gy_ignite(0, skill)
	check(s.atk_of(hero, false) == 1800 and s.players[0].banished.has(skill), "Skill Successor from the Graveyard: +800 ATK (got %d)" % s.atk_of(hero, false))
	# Descending Lost Star: a Synchro Monster back in Defense, negated, a Level lower, 0 DEF, locked.
	s = _main_ready(134)
	star = _in(s, 0, "Stardust Dragon", "gy")
	star.proper = true
	var lost := _st(s, 0, "Descending Lost Star", "set", "trap")
	check(s.can_activate(0, lost), "Descending Lost Star can be activated with a Synchro Monster in the Graveyard")
	s.activate(0, lost)
	check(s.players[0].field.has(star) and not star.attack_pos and star.negated and star.level() == 7 and s.def_of(star) == 0 and not s.can_change_position(0, star), "Descending Lost Star: Defense Position, negated, Level 7, 0 DEF, position locked")
	# Synchro Barrier: Tribute a Synchro Monster; no damage until the End Phase of the next turn.
	s = _main_ready(135)
	jw = _mon(s, 0, "Junk Warrior", 0)
	var barrier := _st(s, 0, "Synchro Barrier", "set", "trap")
	check(s.can_activate(0, barrier), "Synchro Barrier can be activated with a Synchro Monster to Tribute")
	s.activate(0, barrier)
	lp0 = s.players[0].lp
	s._damage(0, 1000)
	s.turn += 1
	s._damage(0, 1000, true)
	check(not s.players[0].field.has(jw) and s.players[0].lp == lp0, "Synchro Barrier: no damage this turn or the next")
	s.turn += 1
	s._damage(0, 1000)
	check(s.players[0].lp == lp0 - 1000, "Synchro Barrier is over after the next turn")
	# Starlight Road: an effect that would destroy 2 or more of your cards is negated, and Stardust Dragon arrives.
	s = _main_ready(136)
	_fake(s, 0, "Mine A", 1000, 0, 0)
	_fake(s, 0, "Mine B", 1000, 0, 1)
	star = _in(s, 0, "Stardust Dragon", "extra")
	var roadt := _st(s, 0, "Starlight Road", "set", "trap")
	s.current = 1
	boom = _st(s, 1, "Dark Hole")
	boom.data = CardData.get_card(_cid("Dark Hole")).duplicate()
	s.chain_add(1, boom)
	check(s.responses(0, "chain", s.chain.back()).has(roadt), "Starlight Road can answer an effect that would destroy 2 of your cards")
	s.chain_add(0, roadt, null, "chain", s.chain.back())
	s.chain_resolve()
	check(s.players[0].monsters().size() == 3 and s.players[0].field.has(star), "Starlight Road: Dark Hole is negated and Stardust Dragon comes out of the Extra Deck")
	s = _main_ready(137)
	_fake(s, 0, "Mine A", 1000, 0, 0)
	roadt = _st(s, 0, "Starlight Road", "set", "trap")
	s.current = 1
	boom = _st(s, 1, "Dark Hole")
	boom.data = CardData.get_card(_cid("Dark Hole")).duplicate()
	s.chain_add(1, boom)
	check(not s.responses(0, "chain", s.chain.back()).has(roadt), "Starlight Road does not answer an effect that would destroy only 1 of your cards")
	# Defense Draw: at damage calculation in the opponent's turn, no battle damage and draw 1.
	s = _new_state(138)
	_battle_ready(s)
	blue = _mon(s, 0, "Blue-Eyes White Dragon", 0)
	var dd := _st(s, 1, "Defense Draw", "set", "trap")
	lp1 = s.players[1].lp
	hand_n = s.players[1].hand.size()
	s.declare_attack(0, blue, null)
	check(not s.responses(1, "attack").has(dd) and s.responses(1, "damage").has(dd), "Defense Draw is for damage calculation only")
	s.chain_add(1, dd, null, "damage", null)
	s.chain_resolve()
	s.resolve_attack()
	check(s.players[1].lp == lp1 and s.players[1].hand.size() == hand_n + 1, "Defense Draw: no battle damage from this battle, draw 1")
	# Urgent Tuning: a Synchro Summon in the Battle Phase.
	s = _new_state(139)
	_battle_ready(s)
	_mon(s, 0, "Junk Synchron", 0)
	_fake(s, 0, "Two", 100, 100, 1, {"level": 2})
	jw = _in(s, 0, "Junk Warrior", "extra")
	var urgent := _st(s, 0, "Urgent Tuning", "set", "trap")
	check(s.responses(0, "battle_start").has(urgent), "Urgent Tuning can be activated in the Battle Phase")
	s.chain_add(0, urgent, null, "battle_start", null)
	s.chain_resolve()
	check(s.players[0].field.has(jw) and jw.proper, "Urgent Tuning: Junk Warrior is Synchro Summoned in the Battle Phase")
	# Give and Take: a monster to their field in Defense; one of yours gains its Level.
	s = _main_ready(140)
	s.players[0].gy.clear()
	var gift := _in(s, 0, "Speed Warrior", "gy")
	var taker := _mon(s, 0, "Junk Synchron", 0)
	var gat := _st(s, 0, "Give and Take", "set", "trap")
	s.activate(0, gat)
	check(s.players[1].field.has(gift) and not gift.attack_pos and taker.level() == 5, "Give and Take: Speed Warrior on their field in Defense, Junk Synchron is Level 5 (Level %d)" % taker.level())
	# Slip Summon: when they Summon; back to the hand in the End Phase.
	s = _main_ready(141)
	s.current = 1
	var theirs := _mon(s, 1, "Blue-Eyes White Dragon", 0)
	var slip := _st(s, 0, "Slip Summon", "set", "trap")
	s.players[0].hand.clear()
	var slipped := _in(s, 0, "Speed Warrior", "hand")
	check(s.responses(0, "summon", theirs).has(slip), "Slip Summon can answer a Summon")
	s.chain_add(0, slip, null, "summon", theirs)
	s.chain_resolve()
	check(s.players[0].field.has(slipped) and not slipped.attack_pos, "Slip Summon: a Level 4 or lower monster from the hand in Defense Position")
	s.begin_end()
	check(s.players[0].hand.has(slipped), "Slip Summon: it returns to the hand in the End Phase")
	# Limiter Overload: sent to the Graveyard, Speed Warrior comes out.
	s = _main_ready(142)
	s.players[0].deck.clear()
	var spd := _in(s, 0, "Speed Warrior", "deck")
	var lim := _st(s, 0, "Limiter Overload", "set", "trap")
	s._destroy_st(lim)
	s._cleanup()
	check(s.players[0].field.has(spd), "Limiter Overload: sent to the Graveyard, it Special Summons Speed Warrior from the Deck")
	# Yusei's deck is his own: 40 cards, 15 in the Extra Deck, nothing borrowed.
	var au := SignatureDecks.audit("yusei")
	check((au["stand_ins"] as Array).is_empty() and CardData.deck_list("yusei").size() == 40 and CardData.extra_list("yusei").size() == 15, "Yusei's deck: 40 + 15, no stand-ins (stand-ins %s)" % str(au["stand_ins"]))
	check(CardData.legend_deck("yusei").size() == 40 and not CardData.legend_deck("yusei").has(_cid("Pot of Greed")), "Yusei's deck is the same 40 cards on Hard and Expert")
	# The written-out deck is Yusei's alone: a street duelist with "his deck" plays the plain one.
	check(SignatureDecks.owner("yusei") == "yusei" and SignatureDecks.borrowed("yusei", "hunter") and not SignatureDecks.borrowed("yusei", "yusei"), "The deck \"yusei\" belongs to Yusei; a Rare Hunter only borrows it")
	check(not CardData.extra_list("yusei", true).has(_cid("Shooting Star Dragon")) and CardData.extra_list("yusei").has(_cid("Shooting Star Dragon")) and CardData.deck_list("yusei", true).size() >= 40, "The borrowed version has no Shooting Star Dragon")
	# Every roster duelist owns their deck, and in the open world they duel with that deck
	# (so the deck Free Duel shows is the deck they play when you walk up to them).
	var roam_src := FileAccess.get_file_as_string("res://scripts/roam/roam_data.gd")
	var met := 0
	for k in SignatureDecks.WISH:
		var own_deck := str(Characters.get_char(str(k)).get("deck", ""))
		check(SignatureDecks.owner(own_deck) == str(k) and not SignatureDecks.borrowed(own_deck, str(k)), "%s owns the deck \"%s\"" % [k, own_deck])
		var at := roam_src.find("\"char\": \"%s\"" % k)
		while at != -1:
			var stop := roam_src.find("{\"id\":", at)
			var seg := roam_src.substr(at, (stop - at) if stop != -1 else 900)
			var dk := seg.find("\"duel\": {\"deck\": \"")
			if dk != -1:
				met += 1
				var named := seg.substr(dk + 18).get_slice("\"", 0)
				check(named == own_deck, "In the open world %s duels with their own deck (found \"%s\")" % [k, named])
			at = roam_src.find("\"char\": \"%s\"" % k, at + 8)
	check(met >= 20, "The roster duelists can be challenged in the open world (%d found)" % met)
	# Free Duel: any of your saved decks can be played by either side ("slot:N").
	var keep_slots: Array = Collection.slots.duplicate(true)
	var keep_slot: int = Collection.slot
	var keep_main: Array = Collection.main.duplicate()
	var keep_extra: Array = Collection.extra.duplicate()
	var keep_ban: bool = Collection.banlist
	Collection.banlist = false
	Collection.slots = [{"name": "First", "main": Array(CardData.deck_list("kaiba")), "extra": [], "side": []},
		{"name": "Second", "main": Array(CardData.deck_list("yusei")), "extra": Array(CardData.extra_list("yusei")), "side": []},
		{"name": "Short", "main": [_cid("Kuriboh")], "extra": [], "side": []}]
	Collection.slot = 0
	Collection.main = Array(CardData.deck_list("kaiba"))
	Collection.extra = []
	check(CardData.has_deck("slot:1") and not CardData.has_deck("slot:2") and not CardData.has_deck("slot:9"), "A saved deck that is ready can be dueled with; a 1-card deck cannot")
	check(CardData.deck_name("slot:1") == "Second" and CardData.deck_list("slot:1").size() == 40 and CardData.extra_list("slot:1").size() == 15, "A saved deck is read by its place in the list: name, 40 cards, 15 in the Extra Deck")
	check(Collection.my_decks().size() == 2 and bool(Collection.my_decks()[0]["open"]), "Free Duel lists the saved decks that are ready (2 of 3), the open one marked")
	check(CardData.legend_deck("slot:1").size() == 40, "A saved deck in the opponent's hands is the same 40 cards on Hard")
	Collection.slots = keep_slots
	Collection.slot = keep_slot
	Collection.main = keep_main
	Collection.extra = keep_extra
	Collection.banlist = keep_ban
	# The 5D's packs carry the new cards.
	var pool5: Array = Collection.pool(str(Characters.DATA["yusei"]["era"]))
	for nm in ["Shooting Star Dragon", "Shooting Quasar Dragon", "Formula Synchron", "Quickdraw Synchron", "Level Eater", "Starlight Road", "Zero Gardna", "Colossal Fighter", "Urgent Tuning"]:
		check(pool5.has(_cid(nm)), "%s is in the 5D's card pool (packs and shops)" % nm)


## The cards built in v0.33.32 (Yugi's best deck), each against its printed text.
func _test_cards_32() -> void:
	# Buster Blader: +500 for each Dragon the opponent controls or has in the Graveyard.
	var s := _main_ready(201)
	var bb := _mon(s, 0, "Buster Blader", 0)
	s.players[1].gy.clear()
	_mon(s, 1, "Blue-Eyes White Dragon", 0)
	_in(s, 1, "Blue-Eyes White Dragon", "gy")
	check(s.atk_of(bb, false) == 3600, "Buster Blader: 2600 + 500 for each of their 2 Dragons (got %d)" % s.atk_of(bb, false))
	# Dark Paladin: Dark Magician + Buster Blader; +500 per Dragon anywhere; negates a Spell by discarding.
	s = _main_ready(202)
	s.players[0].hand.clear()
	s.players[0].gy.clear()
	s.players[1].gy.clear()
	_mon(s, 0, "Dark Magician", 0)
	_mon(s, 0, "Buster Blader", 1)
	var pal := _in(s, 0, "Dark Paladin", "extra")
	var poly := _st(s, 0, "Polymerization")
	poly.data = CardData.get_card(_cid("Polymerization")).duplicate()
	check(s.can_activate(0, poly), "Polymerization can make Dark Paladin from Dark Magician and Buster Blader")
	s.activate(0, poly, pal)
	check(s.players[0].field.has(pal), "Dark Paladin is Fusion Summoned")
	_mon(s, 1, "Blue-Eyes White Dragon", 0)
	check(s.atk_of(pal, false) == 3400, "Dark Paladin: 2900 + 500 for the Dragon on the field (got %d)" % s.atk_of(pal, false))
	var fodder := _in(s, 0, "Kuriboh", "hand")
	s.current = 1
	var pot := _st(s, 1, "Pot of Greed")
	pot.data = CardData.get_card(_cid("Pot of Greed")).duplicate()
	var h1: int = s.players[1].hand.size()
	s.chain_add(1, pot)
	check(s.responses(0, "chain", s.chain.back()).has(pal), "Dark Paladin can answer a Spell Card")
	s.respond(0, pal)
	s.chain_resolve()
	check(s.players[0].gy.has(fodder) and s.players[1].hand.size() == h1 - 1 and s.players[1].gy.has(pot), "Dark Paladin: 1 card discarded, the Spell negated and destroyed")
	# Obnoxious Celtic Guard: not by battle with a 1900+ ATK monster.
	s = _new_state(203)
	_battle_ready(s)
	var blue := _mon(s, 0, "Blue-Eyes White Dragon", 0)
	var ocg := _mon(s, 1, "Obnoxious Celtic Guard", 0, false)
	s.declare_attack(0, blue, ocg)
	s.resolve_attack()
	check(s.players[1].field.has(ocg), "Obnoxious Celtic Guard survives a battle with a 3000 ATK monster")
	# Marshmallon: never destroyed by battle; attacked face-down, the attacker's side takes 1000.
	s = _new_state(204)
	_battle_ready(s)
	blue = _mon(s, 0, "Blue-Eyes White Dragon", 0)
	var marsh := _mon(s, 1, "Marshmallon", 0, false)
	marsh.face_up = false
	var lp0: int = s.players[0].lp
	s.declare_attack(0, blue, marsh)
	s.resolve_attack()
	check(s.players[1].field.has(marsh) and s.players[0].lp == lp0 - 1000, "Marshmallon: not destroyed, and 1000 damage to the attacking player (LP -%d)" % (lp0 - s.players[0].lp))
	# Big Shield Gardna: attacked, it changes to Attack Position at the end of the Damage Step.
	s = _new_state(205)
	_battle_ready(s)
	var weak := _fake(s, 0, "Weak", 1000, 0, 0)
	var shield := _mon(s, 1, "Big Shield Gardna", 0, false)
	s.declare_attack(0, weak, shield)
	s.resolve_attack()
	check(s.players[1].field.has(shield) and shield.attack_pos, "Big Shield Gardna changes to Attack Position after it is attacked")
	# ...and negates a Spell that targets it while it is face-down.
	s = _main_ready(206)
	shield = _mon(s, 1, "Big Shield Gardna", 0, false)
	shield.face_up = false
	_mon(s, 0, "Dark Magician", 0)
	var knives := _st(s, 0, "Thousand Knives")
	s.chain_add(0, knives, shield)
	check(s.responses(1, "chain", s.chain.back()).has(shield), "Big Shield Gardna can answer a Spell that targets it face-down")
	s.respond(1, shield)
	s.chain_resolve()
	check(s.players[1].field.has(shield) and shield.face_up and not shield.attack_pos, "Big Shield Gardna: face-up in Defense Position, the Spell negated")
	# Catapult Turtle: half the Tributed monster's ATK as damage.
	s = _main_ready(207)
	var turtle := _mon(s, 0, "Catapult Turtle", 0)
	blue = _mon(s, 0, "Blue-Eyes White Dragon", 1)
	var lp1: int = s.players[1].lp
	s.ignite(0, turtle)
	check(not s.players[0].field.has(blue) and s.players[1].lp == lp1 - 1500, "Catapult Turtle: Blue-Eyes Tributed for 1500 damage")
	# King's Knight: with Queen's Knight, Jack's Knight comes from the Deck.
	s = _main_ready(208)
	s.players[0].deck.clear()
	var jack := _in(s, 0, "Jack's Knight", "deck")
	_mon(s, 0, "Queen's Knight", 0)
	var king := _in(s, 0, "King's Knight", "hand")
	s.normal_summoned = false
	s.normal_summon(0, king, [])
	check(s.players[0].field.has(jack), "King's Knight calls Jack's Knight while you control Queen's Knight")
	# Arcana Knight Joker: the three Knights; negates an effect that targets it by discarding the same kind.
	var joker := _in(s, 0, "Arcana Knight Joker", "extra")
	poly = _st(s, 0, "Polymerization")
	poly.data = CardData.get_card(_cid("Polymerization")).duplicate()
	s.activate(0, poly, joker)
	check(s.players[0].field.has(joker), "Arcana Knight Joker is Fusion Summoned from the three Knights")
	s.players[0].hand.clear()
	var my_spell := _st(s, 0, "Dark Magic Attack")
	_mon(s, 1, "Dark Magician", 0)
	s.current = 1
	knives = _st(s, 1, "Thousand Knives")
	s.chain_add(1, knives, joker)
	check(s.responses(0, "chain", s.chain.back()).has(joker), "Arcana Knight Joker can answer a Spell that targets it")
	s.respond(0, joker)
	s.chain_resolve()
	check(s.players[0].field.has(joker) and s.players[0].gy.has(my_spell), "Arcana Knight Joker: a Spell discarded, the Spell that targeted it negated")
	# Skilled Dark Magician: 3 Spells, then Dark Magician.
	s = _main_ready(209)
	s.players[0].deck.clear()
	s.players[0].hand.clear()
	s.players[0].gy.clear()
	var dm := _in(s, 0, "Dark Magician", "deck")
	for i in 6:
		_in(s, 0, "Kuriboh", "deck")
	var skilled := _mon(s, 0, "Skilled Dark Magician", 0)
	for i in 3:
		var p1 := _st(s, 0, "Pot of Greed")
		p1.data = CardData.get_card(_cid("Pot of Greed")).duplicate()
		s.activate(0, p1)
	check(skilled.counter == 3 and s.can_ignite(0, skilled), "Skilled Dark Magician has 3 Spell Counters after 3 Spells")
	s.ignite(0, skilled)
	check(s.players[0].field.has(dm) and not s.players[0].field.has(skilled), "Skilled Dark Magician is Tributed for Dark Magician")
	# Watapon: added from the Deck by a card effect, it can be Special Summoned.
	s = _main_ready(210)
	s.players[0].deck.clear()
	s.players[0].hand.clear()
	var wata := _in(s, 0, "Watapon", "deck")
	_in(s, 0, "Kuriboh", "deck")
	s.players[0].deck.reverse()
	var p2 := _st(s, 0, "Pot of Greed")
	p2.data = CardData.get_card(_cid("Pot of Greed")).duplicate()
	s.activate(0, p2)
	check(s.players[0].field.has(wata), "Watapon is Special Summoned when a card effect adds it to the hand")
	# The Gadgets fetch each other.
	s = _main_ready(211)
	s.players[0].deck.clear()
	var red := _in(s, 0, "Red Gadget", "deck")
	var green := _in(s, 0, "Green Gadget", "hand")
	s.normal_summoned = false
	s.normal_summon(0, green, [])
	check(s.players[0].hand.has(red), "Green Gadget adds Red Gadget to the hand")
	# Magician's Valkyria: the other Spellcasters cannot be attacked.
	s = _new_state(212)
	_battle_ready(s)
	blue = _mon(s, 0, "Blue-Eyes White Dragon", 0)
	var valk := _mon(s, 1, "Magician's Valkyria", 0)
	var dmg := _mon(s, 1, "Dark Magician Girl", 1)
	var tg: Array = s.attack_targets_for(0, blue)
	check(tg.has(valk) and not tg.has(dmg), "Magician's Valkyria: only she can be attacked among the Spellcasters")
	# Silent Swordsman LV3 -> LV5 -> LV7.
	s = _main_ready(213)
	s.players[0].deck.clear()
	var lv5 := _in(s, 0, "Silent Swordsman LV5", "deck")
	var lv7 := _in(s, 0, "Silent Swordsman LV7", "deck")
	var lv3 := _mon(s, 0, "Silent Swordsman LV3", 0)
	lv3.summoned_turn = s.turn - 1
	s.begin_standby()
	check(s.players[0].field.has(lv5) and s.players[0].gy.has(lv3), "Silent Swordsman LV3 becomes LV5 in your Standby Phase")
	s.phase = DuelState.Phase.BATTLE
	s.declare_attack(0, lv5, null)
	s.resolve_attack()
	s.turn += 2
	s.begin_standby()
	check(s.players[0].field.has(lv7), "Silent Swordsman LV5 becomes LV7 in your next Standby Phase after a direct hit")
	s.phase = DuelState.Phase.MAIN1
	var p3 := _st(s, 0, "Pot of Greed")
	p3.data = CardData.get_card(_cid("Pot of Greed")).duplicate()
	check(not s.can_activate(0, p3), "Silent Swordsman LV7: Spell effects are negated, no Spell can be activated")
	# Silent Swordsman LV5 is unaffected by the opponent's Spells.
	s = _main_ready(214)
	lv5 = _mon(s, 1, "Silent Swordsman LV5", 0)
	_mon(s, 0, "Dark Magician", 0)
	knives = _st(s, 0, "Thousand Knives")
	s.activate(0, knives, lv5)
	check(s.players[1].field.has(lv5), "Silent Swordsman LV5 is unaffected by the opponent's Spell")
	# Silent Magician LV4: counters when the opponent draws, then LV8.
	s = _main_ready(215)
	s.players[0].deck.clear()
	var lv8 := _in(s, 0, "Silent Magician LV8", "deck")
	var sm := _mon(s, 0, "Silent Magician LV4", 0)
	for i in 5:
		s._draw(1, 1)
	check(sm.counter == 5 and s.atk_of(sm, false) == 3500, "Silent Magician LV4: 5 counters, 3500 ATK (got %d / %d)" % [sm.counter, s.atk_of(sm, false)])
	s.turn += 2
	s.begin_standby()
	check(s.players[0].field.has(lv8), "Silent Magician LV4 becomes LV8 in your Standby Phase after the 5th counter")
	# Gandora: half your LP, everything else destroyed and banished, +300 each; gone in the End Phase.
	s = _main_ready(216)
	var gan := _in(s, 0, "Gandora the Dragon of Destruction", "hand")
	var t1 := _fake(s, 0, "T1", 0, 0, 0)
	var t2 := _fake(s, 0, "T2", 0, 0, 1)
	_mon(s, 1, "Blue-Eyes White Dragon", 0)
	_mon(s, 1, "Blue-Eyes White Dragon", 1)
	s.normal_summoned = false
	s.normal_summon(0, gan, [t1, t2])
	lp0 = s.players[0].lp
	check(s.can_ignite(0, gan), "Gandora can use its effect")
	s.ignite(0, gan)
	check(s.players[0].lp == lp0 / 2 and s.players[1].monsters().is_empty() and s.atk_of(gan, false) == 600, "Gandora: half LP paid, 2 cards destroyed and banished, 600 ATK (got %d)" % s.atk_of(gan, false))
	s.begin_end()
	check(s.players[0].gy.has(gan), "Gandora goes to the Graveyard in the End Phase of the turn it was Summoned")
	# Valkyrion: Alpha, Beta and Gamma; and back again.
	s = _main_ready(217)
	s.players[0].hand.clear()
	var alpha := _mon(s, 0, "Alpha The Magnet Warrior", 0)
	var beta := _in(s, 0, "Beta The Magnet Warrior", "hand")
	var gamma := _in(s, 0, "Gamma The Magnet Warrior", "hand")
	var valky := _in(s, 0, "Valkyrion the Magna Warrior", "hand")
	check(s.can_special_from_hand(0, valky), "Valkyrion can be Special Summoned with Alpha, Beta and Gamma in the hand and on the field")
	s.special_from_hand(0, valky)
	check(s.players[0].field.has(valky) and s.players[0].gy.has(alpha) and s.players[0].gy.has(beta) and s.players[0].gy.has(gamma), "Valkyrion is out, the three Magnet Warriors are in the Graveyard")
	s.ignite(0, valky)
	check(s.players[0].field.has(alpha) and s.players[0].field.has(beta) and s.players[0].field.has(gamma) and s.players[0].gy.has(valky), "Valkyrion Tributed: Alpha, Beta and Gamma return")
	# Chimera: destroyed, Berfomet or Gazelle returns.
	s = _main_ready(218)
	s.players[0].gy.clear()
	var chim := _mon(s, 0, "Chimera the Flying Mythical Beast", 0)
	var gaz := _in(s, 0, "Gazelle the King of Mythical Beasts", "gy")
	s._destroy(chim)
	check(s.players[0].field.has(gaz), "Chimera destroyed: Gazelle returns from the Graveyard")
	# Dark Magician of Chaos: a Spell back in the End Phase; banished when it leaves.
	s = _main_ready(219)
	s.players[0].gy.clear()
	var sp_gy := _in(s, 0, "Pot of Greed", "gy")
	var dmoc := _in(s, 0, "Dark Magician of Chaos", "hand")
	s.players[0].hand.erase(dmoc)
	s._special(0, dmoc, "effect")
	s.begin_end()
	check(s.players[0].hand.has(sp_gy), "Dark Magician of Chaos: a Spell from the Graveyard to the hand in the End Phase of the turn it was Summoned")
	s._destroy(dmoc)
	check(s.players[0].banished.has(dmoc), "Dark Magician of Chaos is banished when it leaves the field")
	# Sorcerer of Dark Magic: 2 Level 6+ Spellcasters; negates a Trap.
	s = _main_ready(220)
	_mon(s, 0, "Dark Magician", 0)
	_mon(s, 0, "Dark Magician Girl", 1)
	var sorc := _in(s, 0, "Sorcerer of Dark Magic", "hand")
	check(s.can_special_from_hand(0, sorc), "Sorcerer of Dark Magic can come out by Tributing 2 Level 6+ Spellcasters")
	s.special_from_hand(0, sorc)
	check(s.players[0].field.has(sorc) and s.players[0].monsters().size() == 1, "Sorcerer of Dark Magic is out, the two Spellcasters are Tributed")
	var trap := _st(s, 1, "Graceful Revival", "set", "trap")
	_in(s, 1, "Sonic Chick", "gy")
	s.chain_add(1, trap)
	check(s.responses(0, "chain", s.chain.back()).has(sorc), "Sorcerer of Dark Magic can answer a Trap Card")
	s.respond(0, sorc)
	s.chain_resolve()
	check(s.players[1].gy.has(trap) and s.players[1].monsters().is_empty(), "Sorcerer of Dark Magic negated the Trap and destroyed it")
	# Slifer the Sky Dragon: 3 Tributes, 1000 per card in hand, 2000 off anything Summoned in Attack Position.
	s = _main_ready(221)
	s.players[0].hand.clear()
	var slifer := _in(s, 0, "Slifer the Sky Dragon", "hand")
	for i in 3:
		_in(s, 0, "Kuriboh", "hand")
	var a1 := _fake(s, 0, "A1", 0, 0, 0)
	var a2 := _fake(s, 0, "A2", 0, 0, 1)
	var a3 := _fake(s, 0, "A3", 0, 0, 2)
	check(s.tributes_needed(slifer) == 3, "Slifer needs 3 Tributes")
	s.normal_summoned = false
	check(s.normal_summon(0, slifer, [a1, a2, a3], true).is_empty(), "Slifer cannot be Set")
	s.normal_summon(0, slifer, [a1, a2, a3])
	check(s.players[0].field.has(slifer) and s.atk_of(slifer, false) == 3000 and s.def_of(slifer) == 3000 and s.last_summoned == null, "Slifer: 3000 / 3000 with 3 cards in hand, and no answer to its Summon (ATK %d)" % s.atk_of(slifer, false))
	s.current = 1
	s.normal_summoned = false
	var small := _in(s, 1, "Kuriboh", "hand")
	s.normal_summon(1, small, [])
	check(not s.players[1].field.has(small), "Slifer: a 300 ATK monster Summoned in Attack Position loses 2000 and is destroyed")
	var big := _in(s, 1, "Blue-Eyes White Dragon", "hand")
	s.players[1].hand.erase(big)
	s._special(1, big, "effect")
	check(s.players[1].field.has(big) and s.atk_of(big, false) == 1000, "Slifer: Blue-Eyes loses 2000 ATK and stays (got %d)" % s.atk_of(big, false))
	# ---- Spells and Traps
	# The Ritual Spells.
	s = _main_ready(222)
	s.players[0].hand.clear()
	var bls := _in(s, 0, "Black Luster Soldier", "hand")
	_in(s, 0, "Blue-Eyes White Dragon", "hand")
	var rit := _st(s, 0, "Black Luster Ritual")
	rit.data = CardData.get_card(_cid("Black Luster Ritual")).duplicate()
	check(s.can_activate(0, rit), "Black Luster Ritual can be activated with a Level 8 Tribute in hand")
	s.activate(0, rit)
	check(s.players[0].field.has(bls), "Black Luster Soldier is Ritual Summoned")
	# Dark Magic Attack and Thousand Knives need Dark Magician.
	s = _main_ready(223)
	_st(s, 1, "Mirror Force", "set", "trap")
	_st(s, 1, "Magic Cylinder", "set", "trap")
	blue = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	var dma := _st(s, 0, "Dark Magic Attack")
	knives = _st(s, 0, "Thousand Knives")
	check(not s.can_activate(0, dma) and not s.can_activate(0, knives), "Dark Magic Attack and Thousand Knives need Dark Magician on your field")
	_mon(s, 0, "Dark Magician", 0)
	s.activate(0, dma)
	check(s.players[1].set_cards().is_empty(), "Dark Magic Attack destroys every Spell and Trap they control")
	s.activate(0, knives, blue)
	check(not s.players[1].field.has(blue), "Thousand Knives destroys the target")
	# Dark Magic Curtain: half LP, Dark Magician from the Deck, no other Summons.
	s = _main_ready(224)
	s.players[0].deck.clear()
	s.players[0].hand.clear()
	dm = _in(s, 0, "Dark Magician", "deck")
	var curtain := _st(s, 0, "Dark Magic Curtain")
	var later := _in(s, 0, "Kuriboh", "hand")
	lp0 = s.players[0].lp
	s.normal_summoned = false
	s.activate(0, curtain)
	check(s.players[0].field.has(dm) and s.players[0].lp == lp0 / 2, "Dark Magic Curtain: half LP, Dark Magician from the Deck")
	check(s.normal_summon(0, later, []).is_empty() and not s.normal_summon(0, later, [], true).is_empty(), "Dark Magic Curtain: no other Summon this turn, but a Set is allowed")
	# Sage's Stone: with Dark Magician Girl, Dark Magician from the hand or Deck.
	s = _main_ready(225)
	s.players[0].deck.clear()
	s.players[0].hand.clear()
	dm = _in(s, 0, "Dark Magician", "deck")
	var stone := _st(s, 0, "Sage's Stone")
	check(not s.can_activate(0, stone), "Sage's Stone needs a face-up Dark Magician Girl")
	_mon(s, 0, "Dark Magician Girl", 0)
	s.activate(0, stone)
	check(s.players[0].field.has(dm), "Sage's Stone calls Dark Magician")
	# Magic Formula: +700 on Dark Magician; 1000 LP when it goes from the field to the Graveyard.
	var formula := _st(s, 0, "Magic Formula", "hand", "spell", {"st": "equip"})
	check(SpellRules.targets(s, 0, formula).size() == 2, "Magic Formula can only be equipped to Dark Magician or Dark Magician Girl")
	s.activate(0, formula, dm)
	check(s.atk_of(dm, false) == 3200, "Magic Formula: +700 ATK (got %d)" % s.atk_of(dm, false))
	lp0 = s.players[0].lp
	s._destroy_st(formula)
	check(s.players[0].lp == lp0 + 1000, "Magic Formula: 1000 LP when it is sent from the field to the Graveyard")
	# Dedication through Light and Darkness.
	s = _main_ready(226)
	s.players[0].deck.clear()
	dmoc = _in(s, 0, "Dark Magician of Chaos", "deck")
	dm = _mon(s, 0, "Dark Magician", 0)
	var ded := _st(s, 0, "Dedication through Light and Darkness", "hand", "spell", {"st": "quick-play"})
	s.activate(0, ded)
	check(s.players[0].field.has(dmoc) and s.players[0].gy.has(dm), "Dedication through Light and Darkness: Dark Magician Tributed for Dark Magician of Chaos")
	# Multiply: Kuriboh becomes a field of Kuriboh Tokens.
	s = _main_ready(227)
	var kuri := _mon(s, 0, "Kuriboh", 0)
	var mult := _st(s, 0, "Multiply", "hand", "spell", {"st": "quick-play"})
	s.activate(0, mult)
	var toks: Array = s.players[0].monsters().filter(func(m): return m.is_token())
	check(toks.size() == 5 and not toks[0].attack_pos and s.players[0].gy.has(kuri) and s.players[0].no_summon_turn != s.turn, "Multiply: 5 Kuriboh Tokens in Defense Position (got %d)" % toks.size())
	# Mystic Box: their monster destroyed, one of yours handed over.
	s = _main_ready(228)
	blue = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	var gift := _fake(s, 0, "Gift", 100, 0, 0)
	var box := _st(s, 0, "Mystic Box")
	s.activate(0, box, blue)
	check(not s.players[1].field.has(blue) and s.players[1].field.has(gift), "Mystic Box: their monster is destroyed and yours is theirs now")
	# De-Spell: a Set Spell is destroyed, a Set Trap is only revealed.
	s = _main_ready(229)
	var set_spell := _st(s, 1, "Pot of Greed", "set", "spell")
	var set_trap := _st(s, 1, "Mirror Force", "set", "trap")
	var de1 := _st(s, 0, "De-Spell")
	s.activate(0, de1, set_trap)
	check(s.players[1].spells.has(set_trap), "De-Spell: a Set Trap is revealed, not destroyed")
	var de2 := _st(s, 0, "De-Spell")
	s.activate(0, de2, set_spell)
	check(not s.players[1].spells.has(set_spell), "De-Spell destroys a Set Spell")
	# Lightforce Sword: a card from their hand is gone for 4 of their turns.
	s = _main_ready(230)
	s.players[1].hand.clear()
	var held := _in(s, 1, "Kuriboh", "hand")
	var sword := _st(s, 0, "Lightforce Sword", "set", "trap")
	s.activate(0, sword)
	check(not s.players[1].hand.has(held), "Lightforce Sword takes a card out of their hand")
	s.current = 1
	for i in 3:
		s.begin_standby()
	check(not s.players[1].hand.has(held), "Lightforce Sword: still gone after 3 of their Standby Phases")
	s.begin_standby()
	check(s.players[1].hand.has(held), "Lightforce Sword: the card returns in their 4th Standby Phase")
	# Chain Destruction: the copies in hand and Deck go.
	s = _main_ready(231)
	s.current = 1
	s.players[1].deck.clear()
	s.players[1].hand.clear()
	var c1 := _in(s, 1, "Kuriboh", "hand")
	var c2 := _in(s, 1, "Kuriboh", "deck")
	var keep := _in(s, 1, "Blue-Eyes White Dragon", "deck")
	var out_m := _mon(s, 1, "Kuriboh", 0)
	var chain_d := _st(s, 0, "Chain Destruction", "set", "trap")
	check(s.responses(0, "summon", out_m).has(chain_d), "Chain Destruction can answer the Summon of a 2000 ATK or less monster")
	s.chain_add(0, chain_d, null, "summon", out_m)
	s.chain_resolve()
	check(s.players[1].gy.has(c1) and s.players[1].gy.has(c2) and s.players[1].deck.has(keep) and s.players[1].field.has(out_m), "Chain Destruction: the copies in their hand and Deck are destroyed, the monster stays")
	# Gold Sarcophagus: a card from the Deck, in hand 2 Standby Phases later.
	s = _main_ready(232)
	s.players[0].deck.clear()
	var sealed := _in(s, 0, "Dark Magician", "deck")
	var gold := _st(s, 0, "Gold Sarcophagus")
	s.activate(0, gold)
	check(s.players[0].banished.has(sealed), "Gold Sarcophagus banishes a card from the Deck")
	# Yugi's deck is his own: 40 cards, Dark Paladin and Arcana Knight Joker in the Extra Deck.
	var au := SignatureDecks.audit("yugi")
	check((au["stand_ins"] as Array).is_empty() and CardData.deck_list("yugi").size() == 40 and CardData.extra_list("yugi").size() == 2, "Yugi's deck: 40 + 2, no stand-ins (stand-ins %s, main %d, extra %d)" % [str(au["stand_ins"]), CardData.deck_list("yugi").size(), CardData.extra_list("yugi").size()])
	s.begin_standby()
	check(not s.players[0].hand.has(sealed), "Gold Sarcophagus: not yet after 1 Standby Phase")
	s.begin_standby()
	check(s.players[0].hand.has(sealed), "Gold Sarcophagus: the card is in the hand in your 2nd Standby Phase")


## A real Spell/Trap by name: in the hand, or Set last turn.
func _rst(s: DuelState, p: int, name: String, where := "hand") -> DuelState.CardInst:
	var c := s._make(_cid(name), p)
	if where == "hand":
		s.players[p].hand.append(c)
	else:
		c.face_up = false
		c.set_turn = s.turn - 1
		s.players[p].spells[s.players[p].spells.find(null)] = c
	return c


## A Main Phase with nothing in either hand or Graveyard (the decks stay).
func _bare(seed: int) -> DuelState:
	var s := _main_ready(seed)
	for p in 2:
		s.players[p].hand.clear()
		s.players[p].gy.clear()
		s.players[p].extra.clear()
	return s


## The cards built in v0.33.32 for Jaden's best deck, each against its printed text.
func _test_cards_33() -> void:
	# ---- Contact Fusion: the materials are shuffled into the Deck, no Polymerization.
	var s := _bare(301)
	var neos := _mon(s, 0, "Elemental HERO Neos", 0)
	var mole := _mon(s, 0, "Neo-Spacian Grand Mole", 1)
	var gn := _in(s, 0, "Elemental HERO Grand Neos", "extra")
	var an := _in(s, 0, "Elemental HERO Aqua Neos", "extra")
	var poly := _rst(s, 0, "Polymerization")
	_in(s, 0, "Neo-Spacian Aqua Dolphin", "hand")
	check(s.fusion_targets(0, poly).filter(func(o): return o["card"] == an).is_empty(), "Polymerization cannot make Aqua Neos")
	check(s.can_extra_summon(0, gn) and not s.can_extra_summon(0, an), "Grand Neos can be made by Contact Fusion, Aqua Neos cannot (no Dolphin on the field)")
	var deck0: int = s.players[0].deck.size()
	s.extra_summon(0, gn)
	check(s.players[0].field.has(gn) and s.players[0].deck.has(neos) and s.players[0].deck.has(mole) and s.players[0].deck.size() == deck0 + 2, "Grand Neos: Neos and Grand Mole are shuffled into the Deck")
	var foe := _mon(s, 1, "Blue-Eyes White Dragon", 0)
	check(s.can_ignite(0, gn), "Grand Neos can use its effect")
	s.ignite(0, gn)
	check(s.players[1].hand.has(foe), "Grand Neos returns an opponent's monster to the hand")
	check(not s.can_ignite(0, gn), "Grand Neos: once per turn")
	s.begin_end()
	check(s.players[0].extra.has(gn) and not s.players[0].field.has(gn), "Grand Neos returns to the Extra Deck in the End Phase")
	# ---- Neo Space: +500 for Neos and its fusions, and they may stay.
	s = _bare(302)
	neos = _mon(s, 0, "Elemental HERO Neos", 0)
	var scarab := _mon(s, 0, "Neo-Spacian Flare Scarab", 1)
	var fn := _in(s, 0, "Elemental HERO Flare Neos", "extra")
	var ns := _rst(s, 0, "Neo Space")
	_rst(s, 1, "Mirror Force", "set")
	check(s.atk_of(scarab, false) == 900, "Flare Scarab: 500 + 400 for their 1 Spell/Trap (got %d)" % s.atk_of(scarab, false))
	check(s.can_activate(0, ns), "Neo Space can be activated")
	s.activate(0, ns)
	check(s.players[0].field_spell == ns and s.atk_of(neos, false) == 3000, "Neo Space: Neos has 3000 ATK (got %d)" % s.atk_of(neos, false))
	s.extra_summon(0, fn)
	check(s.atk_of(fn, false) == 2500 + 500 + 800, "Flare Neos: 2500 + 500 (Neo Space) + 400 for each of the 2 Spells/Traps on the field (got %d)" % s.atk_of(fn, false))
	s.begin_end()
	check(s.players[0].field.has(fn), "Flare Neos stays on the field while Neo Space is up")
	# ---- Air Neos: the Life Point gap.
	s = _bare(303)
	_mon(s, 0, "Elemental HERO Neos", 0)
	_mon(s, 0, "Neo-Spacian Air Hummingbird", 1)
	var air := _in(s, 0, "Elemental HERO Air Neos", "extra")
	s.players[0].lp = 3000
	s.players[1].lp = 8000
	s.extra_summon(0, air)
	check(s.atk_of(air, false) == 7500, "Air Neos: 2500 + the 5000 Life Point gap (got %d)" % s.atk_of(air, false))
	s.players[0].lp = 8000
	check(s.atk_of(air, false) == 2500, "Air Neos: no gain when you are not behind")
	# ---- Air Hummingbird.
	s = _bare(304)
	var hum := _mon(s, 0, "Neo-Spacian Air Hummingbird", 0)
	_in(s, 1, "Kuriboh", "hand")
	_in(s, 1, "Kuriboh", "hand")
	var lp0: int = s.players[0].lp
	s.ignite(0, hum)
	check(s.players[0].lp == lp0 + 1000, "Air Hummingbird: 500 LP for each of the 2 cards in their hand")
	# ---- Magma Neos: 400 for each card on the field; End Phase, every card returns to the hand.
	s = _bare(305)
	_mon(s, 0, "Elemental HERO Neos", 0)
	_mon(s, 0, "Neo-Spacian Flare Scarab", 1)
	_mon(s, 0, "Neo-Spacian Grand Mole", 2)
	var mg := _in(s, 0, "Elemental HERO Magma Neos", "extra")
	foe = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	var their_set := _rst(s, 1, "Mirror Force", "set")
	check(s.can_extra_summon(0, mg), "Magma Neos can be made from its three materials")
	s.extra_summon(0, mg)
	check(s.atk_of(mg, false) == 3000 + 1200, "Magma Neos: 3000 + 400 for each of the 3 cards on the field (got %d)" % s.atk_of(mg, false))
	s.begin_end()
	check(s.players[0].extra.has(mg) and s.players[1].hand.has(foe) and s.players[1].hand.has(their_set), "Magma Neos: it returns to the Extra Deck and every card on the field returns to the hand")
	# ---- Storm Neos: destroy every Spell/Trap; End Phase, every card is shuffled into the Deck.
	s = _bare(306)
	_mon(s, 0, "Elemental HERO Neos", 0)
	_mon(s, 0, "Neo-Spacian Air Hummingbird", 1)
	_mon(s, 0, "Neo-Spacian Aqua Dolphin", 2)
	var st := _in(s, 0, "Elemental HERO Storm Neos", "extra")
	foe = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	their_set = _rst(s, 1, "Mirror Force", "set")
	s.extra_summon(0, st)
	s.ignite(0, st)
	check(s.players[1].gy.has(their_set), "Storm Neos destroys every Spell and Trap on the field")
	s.begin_end()
	check(s.players[0].extra.has(st) and s.players[1].deck.has(foe) and s.players[1].monsters().is_empty(), "Storm Neos: it returns to the Extra Deck and every card on the field is shuffled into the Deck")
	# ---- Dark Neos: its target's effects are negated while Dark Neos is face-up.
	s = _bare(307)
	_mon(s, 0, "Elemental HERO Neos", 0)
	_mon(s, 0, "Neo-Spacian Dark Panther", 1)
	var dn := _in(s, 0, "Elemental HERO Dark Neos", "extra")
	var bb := _mon(s, 1, "Buster Blader", 0)
	_mon(s, 0, "Blue-Eyes White Dragon", 3)
	s.extra_summon(0, dn)
	check(s.atk_of(bb, false) == 3100, "Buster Blader has 3100 ATK against a Dragon (got %d)" % s.atk_of(bb, false))
	s.ignite(0, dn)
	s._cleanup()
	check(bb.negated and s.atk_of(bb, false) == 2600, "Dark Neos negates Buster Blader's effect (got %d)" % s.atk_of(bb, false))
	check(not s.can_ignite(0, dn), "Dark Neos: one target at a time")
	s._destroy(dn)
	s._cleanup()
	check(not bb.negated and s.atk_of(bb, false) == 3100, "Buster Blader's effect is back once Dark Neos is gone")
	# ---- Glow Neos: destroy a face-up Spell, then it can attack directly.
	s = _bare(308)
	_mon(s, 0, "Elemental HERO Neos", 0)
	_mon(s, 0, "Neo-Spacian Glow Moss", 1)
	var gl := _in(s, 0, "Elemental HERO Glow Neos", "extra")
	foe = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	foe.face_up = false
	var up_spell := _rst(s, 1, "Swords of Revealing Light", "set")
	up_spell.face_up = true
	s.extra_summon(0, gl)
	s.ignite(0, gl)
	check(s.players[1].gy.has(up_spell), "Glow Neos destroys a face-up Spell")
	s.phase = DuelState.Phase.BATTLE
	gl.summoned_turn = 1
	check(s.can_direct_attack_with(0, gl), "Glow Neos can attack directly this turn after destroying a Spell")
	# ---- Aqua Neos and Aqua Dolphin.
	s = _bare(309)
	_mon(s, 0, "Elemental HERO Neos", 0)
	var dol := _mon(s, 0, "Neo-Spacian Aqua Dolphin", 1)
	_in(s, 0, "Kuriboh", "hand")
	_in(s, 0, "Kuriboh", "hand")
	var weak := _in(s, 1, "Kuriboh", "hand")
	var lp1: int = s.players[1].lp
	s.ignite(0, dol)
	check(s.players[1].gy.has(weak) and s.players[1].lp == lp1 - 500 and s.players[0].hand.size() == 1, "Aqua Dolphin: 1 discard, the weaker monster in their hand is destroyed and they take 500")
	var aq := _in(s, 0, "Elemental HERO Aqua Neos", "extra")
	s.extra_summon(0, aq)
	var in_hand := _in(s, 1, "Pot of Greed", "hand")
	s.ignite(0, aq)
	check(s.players[1].gy.has(in_hand) and s.players[0].hand.is_empty(), "Aqua Neos: 1 discard, 1 random card in their hand is destroyed")
	s = _bare(310)
	dol = _mon(s, 0, "Neo-Spacian Aqua Dolphin", 0)
	_in(s, 0, "Kuriboh", "hand")
	var big := _in(s, 1, "Blue-Eyes White Dragon", "hand")
	lp0 = s.players[0].lp
	s.ignite(0, dol)
	check(s.players[1].hand.has(big) and s.players[0].lp == lp0 - 500, "Aqua Dolphin: a monster stronger than all of yours stays, and you take 500")
	# ---- Grand Mole: both monsters back to the hand at the start of the Damage Step.
	s = _bare(311)
	s.phase = DuelState.Phase.BATTLE
	mole = _mon(s, 0, "Neo-Spacian Grand Mole", 0)
	mole.summoned_turn = 1
	foe = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	lp0 = s.players[0].lp
	s.declare_attack(0, mole, foe)
	s.resolve_attack()
	check(s.players[0].hand.has(mole) and s.players[1].hand.has(foe) and s.players[0].lp == lp0, "Grand Mole: both monsters return to the hand and there is no battle")
	# ---- Glow Moss: the opponent draws and shows; a monster ends the Battle Phase.
	s = _bare(312)
	s.phase = DuelState.Phase.BATTLE
	var moss := _mon(s, 0, "Neo-Spacian Glow Moss", 0)
	moss.summoned_turn = 1
	var other := _mon(s, 0, "Elemental HERO Neos", 1)
	other.summoned_turn = 1
	foe = _mon(s, 1, "Kuriboh", 0)
	s.players[1].deck.append(s._make(_cid("Blue-Eyes White Dragon"), 1))
	s.declare_attack(0, moss, foe)
	s.resolve_attack()
	check(s.players[1].hand.size() == 1 and s.players[1].field.has(foe) and not s.can_attack(0, other), "Glow Moss: they drew a monster, so the Battle Phase ends")
	# ---- Dark Panther: takes a monster's name (and effects) until the End Phase.
	s = _bare(313)
	var pan := _mon(s, 0, "Neo-Spacian Dark Panther", 0)
	bb = _mon(s, 1, "Buster Blader", 0)
	_mon(s, 1, "Blue-Eyes White Dragon", 1)
	s.ignite(0, pan)
	check(pan.cname() == "Buster Blader" and s.atk_of(pan, false) == 1500, "Dark Panther is Buster Blader now: 1000 + 500 for their Dragon (got %d)" % s.atk_of(pan, false))
	s.begin_end()
	check(pan.cname() == "Neo-Spacian Dark Panther", "Dark Panther is itself again after the End Phase")
	# ---- Instant Neo Space: only on a Neos fusion; it stays; when it leaves, Neos comes out.
	s = _bare(314)
	_mon(s, 0, "Elemental HERO Neos", 0)
	_mon(s, 0, "Neo-Spacian Grand Mole", 1)
	gn = _in(s, 0, "Elemental HERO Grand Neos", "extra")
	var ins := _rst(s, 0, "Instant Neo Space")
	check(not s.can_activate(0, ins), "Instant Neo Space cannot be equipped to Neos himself")
	s.extra_summon(0, gn)
	check(s.can_activate(0, ins), "Instant Neo Space can be equipped to Grand Neos")
	s.activate(0, ins, gn)
	s.begin_end()
	check(s.players[0].field.has(gn), "Grand Neos stays with Instant Neo Space on it")
	s._destroy(gn)
	s._cleanup()
	var out_neos: Array = s.players[0].monsters().filter(func(m): return m.cname() == "Elemental HERO Neos")
	check(out_neos.size() == 1 and s.players[0].gy.has(ins), "Instant Neo Space: Grand Neos left the field, so Neos is Special Summoned from the Deck")
	# ---- Fake Hero.
	s = _bare(315)
	neos = _in(s, 0, "Elemental HERO Neos", "hand")
	var fake := _rst(s, 0, "Fake Hero")
	s.activate(0, fake)
	check(s.players[0].field.has(neos), "Fake Hero Special Summons Neos from the hand")
	s.phase = DuelState.Phase.BATTLE
	check(not s.can_attack(0, neos), "The monster Fake Hero brought out cannot attack")
	s.begin_end()
	check(s.players[0].hand.has(neos), "It returns to the hand in the End Phase")
	# ---- O - Oversoul: an "Elemental HERO" Normal Monster only.
	s = _bare(316)
	_in(s, 0, "Elemental HERO Bubbleman", "gy")
	var over := _rst(s, 0, "O - Oversoul")
	check(not s.can_activate(0, over), "O - Oversoul cannot bring back Bubbleman (an Effect Monster)")
	neos = _in(s, 0, "Elemental HERO Neos", "gy")
	check(s.can_activate(0, over), "O - Oversoul can bring back Neos")
	s.activate(0, over)
	check(s.players[0].field.has(neos), "O - Oversoul Special Summons Neos from the Graveyard")
	# ---- Hero Signal.
	s = _bare(317)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	var att := _mon(s, 1, "Blue-Eyes White Dragon", 0)
	att.summoned_turn = 1
	var avian := _mon(s, 0, "Elemental HERO Avian", 0)
	var sig := _rst(s, 0, "Hero Signal", "set")
	s.players[0].deck.append(s._make(_cid("Elemental HERO Sparkman"), 0))
	s.declare_attack(1, att, avian)
	check(not s.responses(0, "attack").has(sig), "Hero Signal is not offered when the attack is declared")
	s.resolve_attack()
	check(s.players[0].gy.has(avian) and s.players[0].gy.has(sig) and s.players[0].monsters().size() == 1 and s.players[0].monsters()[0].level() <= 4, "Hero Signal: a Level 4 or lower Elemental HERO comes out when yours is destroyed by battle")
	# ---- A Hero Emerges, Hero Barrier.
	s = _bare(318)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	att = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	att.summoned_turn = 1
	neos = _in(s, 0, "Elemental HERO Neos", "hand")
	var emerges := _rst(s, 0, "A Hero Emerges", "set")
	var barrier := _rst(s, 0, "Hero Barrier", "set")
	s.declare_attack(1, att, null)
	check(s.responses(0, "attack").has(emerges) and not s.responses(0, "attack").has(barrier), "A Hero Emerges is offered; Hero Barrier is not without an Elemental HERO")
	s.respond(0, emerges)
	check(s.players[0].field.has(neos), "A Hero Emerges: the card picked was a monster, so it is Special Summoned")
	check(s.responses(0, "attack").has(barrier), "Hero Barrier is offered now that an Elemental HERO is on the field")
	s.respond(0, barrier)
	lp0 = s.players[0].lp
	s.resolve_attack()
	check(s.players[0].lp == lp0, "Hero Barrier negates the attack")
	# ---- R - Righteous Justice, H - Heated Heart.
	s = _bare(319)
	avian = _mon(s, 0, "Elemental HERO Avian", 0)
	_mon(s, 0, "Elemental HERO Sparkman", 1)
	var t1 := _rst(s, 1, "Mirror Force", "set")
	var t2 := _rst(s, 1, "Negate Attack", "set")
	var rj := _rst(s, 0, "R - Righteous Justice")
	s.activate(0, rj)
	check(s.players[1].gy.has(t1) and s.players[1].gy.has(t2), "R - Righteous Justice destroys 2 Spells/Traps for 2 Elemental HEROes")
	var hh := _rst(s, 0, "H - Heated Heart")
	s.activate(0, hh, avian)
	check(s.atk_of(avian, false) == 1500 and EffectRunner.piercing(s, 0, avian), "H - Heated Heart: +500 ATK and piercing this turn")
	# ---- Edge Hammer, Burst Return.
	s = _bare(320)
	var edge := _mon(s, 0, "Elemental HERO Bladedge", 0)
	foe = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	var hammer := _rst(s, 0, "Edge Hammer", "set")
	lp1 = s.players[1].lp
	s.activate(0, hammer, foe)
	check(s.players[0].gy.has(edge) and s.players[1].gy.has(foe) and s.players[1].lp == lp1 - 3000, "Edge Hammer: Bladedge Tributed, the monster destroyed, 3000 damage")
	s = _bare(321)
	var burst := _mon(s, 0, "Elemental HERO Burstinatrix", 0)
	avian = _mon(s, 0, "Elemental HERO Avian", 1)
	var br := _rst(s, 0, "Burst Return")
	s.activate(0, br)
	check(s.players[0].hand.has(avian) and s.players[0].field.has(burst), "Burst Return: the other Elemental HEROes return to the hand")
	# ---- Feather Shot.
	s = _bare(322)
	avian = _mon(s, 0, "Elemental HERO Avian", 0)
	avian.summoned_turn = 1
	var spark := _mon(s, 0, "Elemental HERO Sparkman", 1)
	spark.summoned_turn = 1
	var k1 := _mon(s, 1, "Kuriboh", 0)
	var k2 := _mon(s, 1, "Kuriboh", 1)
	var fs := _rst(s, 0, "Feather Shot")
	s.activate(0, fs, avian)
	s.phase = DuelState.Phase.BATTLE
	check(not s.can_attack(0, spark), "Feather Shot: the other monsters cannot attack")
	s.declare_attack(0, avian, k1)
	s.resolve_attack()
	check(s.can_attack(0, avian), "Feather Shot: Avian can attack a second time (2 monsters)")
	s.declare_attack(0, avian, k2)
	s.resolve_attack()
	check(not s.can_attack(0, avian) and s.players[1].monsters().is_empty(), "Feather Shot: two attacks, no third")
	# ---- Transcendent Wings and Winged Kuriboh LV10.
	s = _bare(323)
	var wk := _mon(s, 0, "Winged Kuriboh", 0)
	var lv10 := _in(s, 0, "Winged Kuriboh LV10", "hand")
	_in(s, 0, "Kuriboh", "hand")
	var wings := _rst(s, 0, "Transcendent Wings")
	check(not s.can_activate(0, wings), "Transcendent Wings needs 2 other cards in the hand besides the LV10")
	_in(s, 0, "Kuriboh", "hand")
	check(s.can_activate(0, wings), "Transcendent Wings can be activated")
	s.activate(0, wings)
	check(s.players[0].field.has(lv10) and s.players[0].gy.has(wk) and s.players[0].hand.is_empty(), "Transcendent Wings: Winged Kuriboh and 2 cards to the Graveyard, LV10 Special Summoned")
	s.current = 1
	s.phase = DuelState.Phase.BATTLE
	att = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	att.summoned_turn = 1
	var att2 := _mon(s, 1, "Dark Magician", 1)
	lp1 = s.players[1].lp
	s.declare_attack(1, att, lv10)
	check(s.responses(0, "attack").has(lv10), "Winged Kuriboh LV10 is offered in the opponent's Battle Phase")
	s.respond(0, lv10)
	check(s.players[1].monsters().is_empty() and s.players[1].lp == lp1 - 5500 and s.players[0].gy.has(lv10), "Winged Kuriboh LV10: their Attack Position monsters are destroyed, 5500 damage")
	s.resolve_attack()
	# ---- The Elemental HERO fusions.
	s = _bare(324)
	var sfw := _mon(s, 0, "Elemental HERO Shining Flare Wingman", 0)
	_in(s, 0, "Elemental HERO Avian", "gy")
	_in(s, 0, "Elemental HERO Sparkman", "gy")
	_in(s, 0, "Kuriboh", "gy")
	check(s.atk_of(sfw, false) == 3100, "Shining Flare Wingman: 2500 + 300 for each of the 2 Elemental HEROes in the Graveyard (got %d)" % s.atk_of(sfw, false))
	s.phase = DuelState.Phase.BATTLE
	sfw.summoned_turn = 1
	foe = _mon(s, 1, "Dark Magician", 0)
	lp1 = s.players[1].lp
	s.declare_attack(0, sfw, foe)
	s.resolve_attack()
	check(s.players[1].lp == lp1 - 600 - 2500, "Shining Flare Wingman: 600 battle damage and 2500 more for the destroyed monster (LP %d)" % s.players[1].lp)
	s = _bare(325)
	s.phase = DuelState.Phase.BATTLE
	var healer := _mon(s, 0, "Elemental HERO Steam Healer", 0)
	healer.summoned_turn = 1
	foe = _mon(s, 1, "Celtic Guardian", 0)
	lp0 = s.players[0].lp
	s.declare_attack(0, healer, foe)
	s.resolve_attack()
	check(s.players[0].lp == lp0 + 1400, "Steam Healer: gain the destroyed monster's 1400 ATK as LP")
	s = _bare(326)
	s.phase = DuelState.Phase.BATTLE
	var we := _mon(s, 0, "Elemental HERO Wildedge", 0)
	we.summoned_turn = 1
	k1 = _mon(s, 1, "Kuriboh", 0)
	k2 = _mon(s, 1, "Kuriboh", 1)
	s.declare_attack(0, we, k1)
	s.resolve_attack()
	check(s.can_attack(0, we) and not s.attack_targets_for(0, we).has(k1) or not s.players[1].field.has(k1), "Wildedge can attack again, on the other monster")
	s.declare_attack(0, we, k2)
	s.resolve_attack()
	check(s.players[1].monsters().is_empty() and not s.can_attack(0, we), "Wildedge attacked each monster once and cannot attack directly after")
	s = _bare(327)
	s.phase = DuelState.Phase.BATTLE
	var rb := _mon(s, 0, "Elemental HERO Rampart Blaster", 0, false)
	rb.summoned_turn = 1
	_mon(s, 1, "Blue-Eyes White Dragon", 0)
	lp1 = s.players[1].lp
	check(s.can_attack(0, rb) and s.can_direct_attack_with(0, rb) and s.attack_targets_for(0, rb).is_empty(), "Rampart Blaster in Defense Position can attack, and only directly")
	s.declare_attack(0, rb, null)
	s.resolve_attack()
	check(s.players[1].lp == lp1 - 1000, "Rampart Blaster: half its 2000 ATK as damage")
	s = _bare(328)
	s.phase = DuelState.Phase.BATTLE
	var mar := _mon(s, 0, "Elemental HERO Mariner", 0)
	mar.summoned_turn = 1
	_mon(s, 1, "Blue-Eyes White Dragon", 0)
	check(not s.can_direct_attack_with(0, mar), "Mariner cannot attack directly with no Set card")
	_rst(s, 0, "Mirror Force", "set")
	check(s.can_direct_attack_with(0, mar), "Mariner can attack directly while you have a Set Spell/Trap")
	s = _bare(329)
	_mon(s, 0, "Elemental HERO Wildheart", 0)
	_in(s, 0, "Elemental HERO Necroshade", "hand")
	var shaman := _in(s, 0, "Elemental HERO Necroid Shaman", "extra")
	poly = _rst(s, 0, "Polymerization")
	foe = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	var their_gy := _in(s, 1, "Kuriboh", "gy")
	s.activate(0, poly, shaman)
	check(s.players[0].field.has(shaman) and s.players[1].gy.has(foe) and s.players[1].field.has(their_gy), "Necroid Shaman: their monster is destroyed and 1 monster from their Graveyard comes back to their field")
	s = _bare(330)
	var el := _mon(s, 0, "Elemental HERO Electrum", 0)
	_mon(s, 1, "Blue-Eyes White Dragon", 0)
	_mon(s, 1, "Dark Magician", 1)
	check(s.atk_of(el, false) == 3200, "Electrum: 2900 + 300 for their LIGHT monster, nothing for the DARK one (got %d)" % s.atk_of(el, false))
	var ban := s._make(_cid("Kuriboh"), 1)
	s.players[1].banished.append(ban)
	EffectRunner.run_list(s, 0, el, [["electrum"]], {"_now": true})
	check(s.players[1].deck.has(ban) and s.players[1].banished.is_empty(), "Electrum: banished cards are shuffled into the Deck")
	s = _bare(331)
	s.phase = DuelState.Phase.MAIN1
	var tem := _mon(s, 0, "Elemental HERO Tempest", 0)
	var guarded := _mon(s, 0, "Kuriboh", 1)
	var spare := _rst(s, 0, "Mirror Force", "set")
	s.manual = [false, false]
	s.ignite(0, tem)
	check(s.players[0].gy.has(spare) or s.players[0].gy.has(guarded), "Tempest: 1 other card you control goes to the Graveyard")
	var kept: Array = s.players[0].monsters().filter(func(m): return m.tags.has("guard_by"))
	check(kept.size() == 1 and EffectRunner.survives_battle(s, kept[0]), "Tempest: the chosen monster cannot be destroyed by battle")
	s._destroy(tem)
	check(kept.is_empty() or not EffectRunner.survives_battle(s, kept[0]) or kept[0] == tem, "Tempest gone: the guard ends")
	s = _bare(332)
	var ww := _mon(s, 0, "Elemental HERO Wild Wingman", 0)
	_in(s, 0, "Kuriboh", "hand")
	their_set = _rst(s, 1, "Mirror Force", "set")
	s.ignite(0, ww)
	check(s.players[1].gy.has(their_set) and s.players[0].hand.is_empty(), "Wild Wingman: discard 1, destroy a Spell/Trap")
	# ---- Necroshade: one Level 5+ Elemental HERO without Tributing, once.
	s = _bare(333)
	var shade := _in(s, 0, "Elemental HERO Necroshade", "gy")
	neos = _in(s, 0, "Elemental HERO Neos", "hand")
	var neos2 := _in(s, 0, "Elemental HERO Neos", "hand")
	check(s.tributes_needed(neos) == 0 and s.can_normal_summon(0, neos), "Necroshade in the Graveyard: Neos needs no Tribute")
	s.normal_summon(0, neos, [])
	check(s.players[0].field.has(neos) and shade.once, "Neos is Normal Summoned without Tributing, and Necroshade's effect is spent")
	check(s.tributes_needed(neos2) == 2, "The second Neos needs its 2 Tributes")
	# ---- Card Trooper, Wroughtweiler, Hero Kid.
	s = _bare(334)
	var tr := _mon(s, 0, "Card Trooper", 0)
	var d0: int = s.players[0].deck.size()
	s.ignite(0, tr)
	check(s.players[0].deck.size() == d0 - 3 and s.atk_of(tr, false) == 1900, "Card Trooper: 3 cards sent, 400 + 1500 ATK this turn (got %d)" % s.atk_of(tr, false))
	var h0: int = s.players[0].hand.size()
	s._destroy(tr)
	check(s.players[0].hand.size() == h0 + 1, "Card Trooper destroyed: draw 1 card")
	s = _bare(335)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	att = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	att.summoned_turn = 1
	var dog := _mon(s, 0, "Wroughtweiler", 0, false)
	var gy_hero := _in(s, 0, "Elemental HERO Neos", "gy")
	var gy_poly := _in(s, 0, "Polymerization", "gy")
	s.declare_attack(1, att, dog)
	s.resolve_attack()
	check(s.players[0].hand.has(gy_hero) and s.players[0].hand.has(gy_poly), "Wroughtweiler: an Elemental HERO and Polymerization return to the hand")
	s = _bare(336)
	var kid := _in(s, 0, "Hero Kid", "hand")
	s.players[0].deck.append(s._make(_cid("Hero Kid"), 0))
	s.players[0].deck.append(s._make(_cid("Hero Kid"), 0))
	s._special(0, kid, "effect")
	s.players[0].hand.erase(kid)
	EffectRunner.on_summon(s, 0, kid, "special")
	check(s.players[0].monsters().filter(func(m): return m.cname() == "Hero Kid").size() == 3, "Hero Kid: Special Summoned, the other 2 come out of the Deck")
	# ---- The computer makes a Contact Fusion when it will stay (Neo Space), and holds it otherwise.
	s = _bare(337)
	s.players[0].extra.clear()
	_mon(s, 0, "Elemental HERO Neos", 0)
	_mon(s, 0, "Neo-Spacian Grand Mole", 1)
	gn = _in(s, 0, "Elemental HERO Grand Neos", "extra")
	_mon(s, 1, "Blue-Eyes White Dragon", 0)
	_mon(s, 1, "Blue-Eyes White Dragon", 1)
	s.normal_summoned = true
	check(DuelAI._contact_worth(s, 0, gn) == 0, "The computer does not make Grand Neos when it would only go back")
	ns = _rst(s, 0, "Neo Space")
	var act := DuelAI.next_main_action(s, 0, DuelAI.HARD)
	check(act.get("do", "") == "activate" and act.get("card") == ns, "The computer plays Neo Space first")
	s.activate(0, ns)
	act = DuelAI.next_main_action(s, 0, DuelAI.HARD)
	check(act.get("do", "") == "extra" and act.get("card") == gn, "With Neo Space up, the computer makes Grand Neos (got %s)" % str(act.get("do", "")))


## The cards built in v0.33.32 for Yuma's best deck, each against its printed text.
func _test_cards_34() -> void:
	# ---- Kagetokage follows a Level 4 Normal Summon; Gagaga Girl copies Gagaga Magician's Level.
	var s := _bare(401)
	var mag := _in(s, 0, "Gagaga Magician", "hand")
	var kage := _in(s, 0, "Kagetokage", "hand")
	check(not s.can_normal_summon(0, kage), "Kagetokage cannot be Normal Summoned")
	s.normal_summon(0, mag, [])
	check(s.players[0].field.has(kage), "Kagetokage is Special Summoned when a Level 4 monster is Normal Summoned")
	var girl := _mon(s, 0, "Gagaga Girl", 3)
	mag.lv_set = 6
	mag.lv_turn = s.turn
	s.ignite(0, girl)
	check(girl.level() == 6, "Gagaga Girl becomes Gagaga Magician's current Level (got %d)" % girl.level())
	# ---- Gagaga Girl's gift: an Xyz Monster made of Gagaga monsters only zeroes a Special Summoned monster.
	s = _bare(402)
	mag = _mon(s, 0, "Gagaga Magician", 0)
	girl = _mon(s, 0, "Gagaga Girl", 1)
	girl.lv_set = 4
	var cow := _in(s, 0, "Gagaga Cowboy", "extra")
	var foe := s._make(_cid("Blue-Eyes White Dragon"), 1)
	s._special(1, foe, "effect", "atk")
	check(s.can_extra_summon(0, cow), "Gagaga Cowboy can be made from Gagaga Magician and a Level 4 Gagaga Girl")
	s.extra_summon(0, cow)
	check(s.atk_of(foe, false) == 0, "Gagaga Girl's gift: the Special Summoned monster's ATK becomes 0 (got %d)" % s.atk_of(foe, false))
	# ---- Ganbara Knight, Dododo Warrior.
	s = _bare(403)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	var att := _mon(s, 1, "Blue-Eyes White Dragon", 0)
	att.summoned_turn = 1
	var gan := _mon(s, 0, "Ganbara Knight", 0)
	var lp0: int = s.players[0].lp
	s.declare_attack(1, att, gan)
	s.resolve_attack()
	check(not gan.attack_pos and s.players[0].lp == lp0, "Ganbara Knight changes to Defense Position when it is targeted, so no battle damage")
	s = _bare(404)
	var dw := _in(s, 0, "Dododo Warrior", "hand")
	check(s.tributes_needed(dw) == 0, "Dododo Warrior can be Normal Summoned without Tributing")
	s.normal_summon(0, dw, [])
	check(s.players[0].field.has(dw) and s.atk_of(dw, false) == 1800, "Dododo Warrior: 1800 ATK when Summoned without a Tribute (got %d)" % s.atk_of(dw, false))
	s.phase = DuelState.Phase.BATTLE
	dw.summoned_turn = 1
	var sangan := _mon(s, 1, "Sangan", 0)
	var h1: int = s.players[1].hand.size()
	s.declare_attack(0, dw, sangan)
	s.resolve_attack()
	check(s.players[1].gy.has(sangan) and s.players[1].hand.size() == h1, "Dododo Warrior attacking: Sangan's effect in the Graveyard is negated")
	# ---- Gogogo Giant.
	s = _bare(405)
	var giant := _in(s, 0, "Gogogo Giant", "hand")
	var golem := _in(s, 0, "Gogogo Golem", "gy")
	s.normal_summon(0, giant, [])
	check(s.players[0].field.has(golem) and not golem.attack_pos and not giant.attack_pos, "Gogogo Giant: Gogogo Golem comes back in Defense Position and the Giant changes to Defense Position")
	# ---- Gagaga Gardna, Tasuke Knight, Gagaga Samurai's guard.
	s = _bare(406)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	att = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	att.summoned_turn = 1
	var gar := _in(s, 0, "Gagaga Gardna", "hand")
	s.declare_attack(1, att, null)
	check(s.responses(0, "attack").has(gar), "Gagaga Gardna is offered from the hand on a direct attack")
	s.respond(0, gar)
	check(s.players[0].field.has(gar), "Gagaga Gardna is Special Summoned from the hand")
	s.resolve_attack()
	s = _bare(407)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	att = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	att.summoned_turn = 1
	var att2 := _mon(s, 1, "Dark Magician", 1)
	att2.summoned_turn = 1
	var tas := _in(s, 0, "Tasuke Knight", "gy")
	s.declare_attack(1, att, null)
	check(s.responses(0, "attack").has(tas), "Tasuke Knight is offered from the Graveyard with an empty hand")
	s.respond(0, tas)
	lp0 = s.players[0].lp
	s.resolve_attack()
	check(s.players[0].field.has(tas) and s.players[0].lp == lp0 and not s.can_attack(1, att2), "Tasuke Knight: it comes back and the Battle Phase ends")
	s.declare_attack(1, att2, null)
	check(not s.responses(0, "attack").has(tas), "Tasuke Knight: once per Duel")
	s = _bare(408)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	att = _mon(s, 1, "Celtic Guardian", 0)
	att.summoned_turn = 1
	var sam := _mon(s, 0, "Gagaga Samurai", 0)
	var weak := _mon(s, 0, "Kuriboh", 1)
	s.declare_attack(1, att, weak)
	check(s.responses(0, "attack").has(sam), "Gagaga Samurai can take an attack aimed at another monster")
	s.respond(0, sam)
	s.resolve_attack()
	check(s.players[0].field.has(weak) and not sam.attack_pos and s.players[0].field.has(sam), "Gagaga Samurai changed to Defense Position and took the attack")
	# ---- Gagaga Samurai's second attack, Volcasaurus.
	s = _bare(409)
	sam = _mon(s, 0, "Gagaga Samurai", 0)
	sam.overlays = [s._make(_cid("Kuriboh"), 0)]
	mag = _mon(s, 0, "Gagaga Magician", 1)
	mag.summoned_turn = 1
	s.ignite(0, sam)
	s.phase = DuelState.Phase.BATTLE
	check(s.attacks_left(mag) == 2 or s.attacks_left(sam) == 2, "Gagaga Samurai: a Gagaga monster can attack twice this turn")
	s = _bare(410)
	var vol := _mon(s, 0, "Number 61: Volcasaurus", 0)
	vol.overlays = [s._make(_cid("Kuriboh"), 0)]
	foe = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	var lp1: int = s.players[1].lp
	s.ignite(0, vol)
	check(s.players[1].gy.has(foe) and s.players[1].lp == lp1 - 3000, "Volcasaurus: the monster is destroyed and its 3000 ATK is dealt as damage")
	s.phase = DuelState.Phase.BATTLE
	vol.summoned_turn = 1
	check(not s.can_direct_attack_with(0, vol), "Volcasaurus cannot attack directly the turn it used its effect")
	# ---- Utopia Ray on top of Utopia; Rank-Up-Magic into Utopia Ray V.
	s = _bare(411)
	var uto := _mon(s, 0, "Number 39: Utopia", 0)
	uto.overlays = [s._make(_cid("Kuriboh"), 0), s._make(_cid("Kuriboh"), 0)]
	var ray := _in(s, 0, "Number C39: Utopia Ray", "extra")
	check(s.can_extra_summon(0, ray), "Utopia Ray can be Xyz Summoned on top of Utopia")
	s.extra_summon(0, ray)
	check(s.players[0].field.has(ray) and ray.overlays.size() == 3 and ray.overlays.has(uto), "Utopia Ray: Utopia and its 2 materials are under it")
	check(not s.can_ignite(0, ray), "Utopia Ray's effect needs 1000 LP or less")
	s.players[0].lp = 1000
	foe = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	s.ignite(0, ray)
	check(s.atk_of(ray, false) == 3000 and s.atk_of(foe, false) == 2000, "Utopia Ray: +500 ATK, and their monster loses 1000 (got %d and %d)" % [s.atk_of(ray, false), s.atk_of(foe, false)])
	s = _bare(412)
	uto = _mon(s, 0, "Number 39: Utopia", 0)
	uto.overlays = [s._make(_cid("Kuriboh"), 0)]
	var rayv := _in(s, 0, "Number C39: Utopia Ray V", "extra")
	var rum := _rst(s, 0, "Rank-Up-Magic Limited Barian's Force")
	check(s.can_activate(0, rum), "Rank-Up-Magic Limited Barian's Force can be activated on Utopia")
	s.activate(0, rum)
	check(s.players[0].field.has(rayv) and rayv.overlays.has(uto) and rayv.overlays.size() == 2, "Utopia ranks up into Utopia Ray V with its materials")
	foe = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	lp1 = s.players[1].lp
	s.ignite(0, rayv)
	check(s.players[1].gy.has(foe) and s.players[1].lp == lp1 - 3000, "Utopia Ray V: the monster is destroyed and its ATK is dealt as damage")
	# ---- The Spells and Traps.
	s = _bare(413)
	var bolt := _rst(s, 0, "Gagagabolt")
	foe = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	check(not s.can_activate(0, bolt), "Gagagabolt needs a Gagaga monster")
	_mon(s, 0, "Gagaga Magician", 0)
	s.activate(0, bolt, foe)
	check(s.players[1].gy.has(foe), "Gagagabolt destroys the target")
	s = _bare(414)
	var ono := _rst(s, 0, "Onomatopaira")
	_in(s, 0, "Kuriboh", "hand")
	s.players[0].deck.append(s._make(_cid("Gagaga Magician"), 0))
	s.players[0].deck.append(s._make(_cid("Gogogo Golem"), 0))
	s.players[0].deck.append(s._make(_cid("Gagaga Girl"), 0))
	s.activate(0, ono)
	var names_o: Array = s.players[0].hand.map(func(h): return h.cname())
	check(s.players[0].hand.size() == 2 and names_o.has("Gogogo Golem") and (names_o.has("Gagaga Magician") or names_o.has("Gagaga Girl")), "Onomatopaira: 1 discard, then 1 Gagaga and 1 Gogogo monster from the Deck (got %s)" % str(names_o))
	var ono2 := _rst(s, 0, "Onomatopaira")
	check(not s.can_activate(0, ono2), "Onomatopaira: once per turn")
	s = _bare(415)
	mag = _in(s, 0, "Gagaga Magician", "gy")
	var rev := _rst(s, 0, "Gagagarevenge")
	s.activate(0, rev)
	check(s.players[0].field.has(mag) and rev.equipped_to == mag, "Gagagarevenge brings Gagaga Magician back and is equipped to it")
	var gol := _mon(s, 0, "Gogogo Golem", 2)
	uto = _in(s, 0, "Number 39: Utopia", "extra")
	s.extra_summon(0, uto)
	check(s.players[0].field.has(uto) and s.atk_of(uto, false) == 2800, "Gagagarevenge: its monster became Xyz Material, so your Xyz Monsters gain 300 ATK (got %d)" % s.atk_of(uto, false))
	s = _bare(416)
	uto = _mon(s, 0, "Number 39: Utopia", 0)
	uto.overlays = [s._make(_cid("Kuriboh"), 0)]
	foe = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	var en := _rst(s, 0, "Xyz Energy")
	s.activate(0, en, foe)
	check(s.players[1].gy.has(foe) and uto.overlays.is_empty(), "Xyz Energy: 1 material detached, the monster destroyed")
	var winds := _rst(s, 0, "Blustering Winds")
	s.activate(0, winds, uto)
	check(s.atk_of(uto, false) == 3500 and s.def_of(uto) == 3000, "Blustering Winds: +1000 ATK and DEF (got %d / %d)" % [s.atk_of(uto, false), s.def_of(uto)])
	s.turn += 2
	check(s.atk_of(uto, false) == 2500 and s.def_of(uto) == 2000, "Blustering Winds ends at your next Standby Phase")
	s = _bare(417)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	att = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	att.summoned_turn = 1
	weak = _mon(s, 0, "Celtic Guardian", 0)
	var hu := _rst(s, 0, "Half Unbreak", "set")
	s.chain_add(0, hu, weak, "free")
	s.chain_resolve()
	lp0 = s.players[0].lp
	s.declare_attack(1, att, weak)
	s.resolve_attack()
	check(s.players[0].field.has(weak) and s.players[0].lp == lp0 - 800, "Half Unbreak: not destroyed, and the 1600 battle damage is halved (LP %d)" % s.players[0].lp)
	s = _bare(418)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	att = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	att.summoned_turn = 1
	att2 = _mon(s, 1, "Dark Magician", 1)
	att2.summoned_turn = 1
	var bbk := _rst(s, 0, "Battle Break", "set")
	s.declare_attack(1, att, null)
	s.respond(0, bbk)
	s.resolve_attack()
	check(s.players[1].gy.has(att) and not s.can_attack(1, att2), "Battle Break: the attacker is destroyed and the Battle Phase ends (no monster in their hand to reveal)")
	s = _bare(419)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	att = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	att.summoned_turn = 1
	weak = _mon(s, 0, "Celtic Guardian", 0)
	var bye := _rst(s, 0, "Bye Bye Damage", "set")
	s.declare_attack(1, att, weak)
	check(s.responses(0, "damage").has(bye), "Bye Bye Damage is offered at damage calculation")
	s.respond(0, bye)
	lp0 = s.players[0].lp
	lp1 = s.players[1].lp
	s.resolve_attack()
	check(s.players[0].field.has(weak) and s.players[0].lp == lp0 - 1600 and s.players[1].lp == lp1 - 3200, "Bye Bye Damage: not destroyed, you take 1600 and they take 3200")


## The cards built in v0.33.32 for Kaiba's best deck, each against its printed text.
func _test_cards_35() -> void:
	# ---- Kaibaman, Kaiser Sea Horse, Blade Knight.
	var s := _bare(501)
	var km := _mon(s, 0, "Kaibaman", 0)
	var be := _in(s, 0, "Blue-Eyes White Dragon", "hand")
	s.ignite(0, km)
	check(s.players[0].gy.has(km) and s.players[0].field.has(be), "Kaibaman: Tributed, Blue-Eyes White Dragon comes out of the hand")
	s = _bare(502)
	var ksh := _mon(s, 0, "Kaiser Sea Horse", 0)
	var other := _mon(s, 0, "Battle Ox", 1)
	be = _in(s, 0, "Blue-Eyes White Dragon", "hand")
	var dm := _in(s, 0, "Dark Magician", "hand")
	check(s.tributes_needed(be) == 1 and s.tributes_needed(dm) == 2, "Kaiser Sea Horse counts as 2 Tributes for a LIGHT monster only")
	s.normal_summon(0, be, [other])
	check(s.players[0].field.has(be) and s.players[0].gy.has(ksh) and s.players[0].field.has(other), "Blue-Eyes is Tribute Summoned with Kaiser Sea Horse alone")
	s = _bare(503)
	var bk := _mon(s, 0, "Blade Knight", 0)
	check(s.atk_of(bk, false) == 2000, "Blade Knight: 2000 ATK with 1 or fewer cards in hand (got %d)" % s.atk_of(bk, false))
	_in(s, 0, "Kuriboh", "hand")
	_in(s, 0, "Kuriboh", "hand")
	check(s.atk_of(bk, false) == 1600, "Blade Knight: 1600 ATK with 2 cards in hand")
	# ---- Lord of D. and The Flute of Summoning Dragon; Obelisk cannot be targeted.
	s = _bare(504)
	var flute := _rst(s, 0, "The Flute of Summoning Dragon")
	be = _in(s, 0, "Blue-Eyes White Dragon", "hand")
	var be2 := _in(s, 0, "Blue-Eyes White Dragon", "hand")
	check(not s.can_activate(0, flute), "The Flute of Summoning Dragon needs Lord of D. on the field")
	_mon(s, 0, "Lord of D.", 0)
	s.activate(0, flute)
	check(s.players[0].field.has(be) and s.players[0].field.has(be2), "The Flute of Summoning Dragon: 2 Dragons come out of the hand")
	var ec := _rst(s, 1, "Change of Heart")
	check(not SpellRules.targets(s, 1, ec).has(be), "Lord of D.: Dragons cannot be targeted by card effects")
	s._cleanup()
	check(not EffectRunner.can_target(null, be), "Lord of D.: monster effects cannot target a Dragon either")
	s = _bare(505)
	var ob := _mon(s, 0, "Obelisk the Tormentor", 0)
	var coh := _rst(s, 1, "Change of Heart")
	check(not SpellRules.targets(s, 1, coh).has(ob), "Obelisk the Tormentor cannot be targeted")
	var f1 := _mon(s, 0, "Battle Ox", 1)
	var f2 := _mon(s, 0, "Vorse Raider", 2)
	var e1 := _mon(s, 1, "Dark Magician", 0)
	var e2 := _mon(s, 1, "Celtic Guardian", 1)
	check(s.tributes_needed(ob) == 3, "Obelisk needs 3 Tributes")
	s.ignite(0, ob)
	check(s.players[0].gy.has(f1) and s.players[0].gy.has(f2) and s.players[1].monsters().is_empty(), "Obelisk: 2 monsters Tributed, every monster on the other side destroyed")
	s.phase = DuelState.Phase.BATTLE
	ob.summoned_turn = 1
	check(not s.can_attack(0, ob), "Obelisk cannot attack the turn it used that effect")
	# ---- XY-Dragon Cannon, XZ-Tank Cannon, YZ-Tank Dragon.
	s = _bare(506)
	var x := _mon(s, 0, "X-Head Cannon", 0)
	var y := _mon(s, 0, "Y-Dragon Head", 1)
	var xy := _in(s, 0, "XY-Dragon Cannon", "extra")
	_in(s, 0, "Kuriboh", "hand")
	var up := _rst(s, 1, "Swords of Revealing Light", "set")
	up.face_up = true
	s.extra_summon(0, xy)
	check(s.players[0].field.has(xy) and s.players[0].banished.has(x) and s.players[0].banished.has(y), "XY-Dragon Cannon: X and Y are banished from the field")
	s.ignite(0, xy)
	check(s.players[1].gy.has(up) and s.players[0].hand.is_empty(), "XY-Dragon Cannon: discard 1, destroy a face-up Spell/Trap")
	s = _bare(507)
	var xz := _mon(s, 0, "XZ-Tank Cannon", 0)
	var yz := _mon(s, 0, "YZ-Tank Dragon", 1)
	_in(s, 0, "Kuriboh", "hand")
	_in(s, 0, "Kuriboh", "hand")
	var down_st := _rst(s, 1, "Mirror Force", "set")
	var down_m := _mon(s, 1, "Dark Magician", 0, false)
	down_m.face_up = false
	s.ignite(0, xz)
	s.ignite(0, yz)
	check(s.players[1].gy.has(down_st) and s.players[1].gy.has(down_m), "XZ-Tank Cannon destroys a Set Spell/Trap, YZ-Tank Dragon a face-down monster")
	# ---- Crush Card Virus, Cost Down, Burst Stream of Destruction, Interdimensional Matter Transporter.
	s = _bare(508)
	var saggi := _mon(s, 0, "Saggi the Dark Clown", 0)
	var virus := _rst(s, 0, "Crush Card Virus", "set")
	var big := _mon(s, 1, "Blue-Eyes White Dragon", 0)
	var small := _mon(s, 1, "Kuriboh", 1)
	var hand_big := _in(s, 1, "Dark Magician", "hand")
	var hand_small := _in(s, 1, "Kuriboh", "hand")
	s.activate(0, virus)
	check(s.players[0].gy.has(saggi) and s.players[1].gy.has(big) and s.players[1].gy.has(hand_big) and s.players[1].field.has(small) and s.players[1].hand.has(hand_small), "Crush Card Virus: their 1500+ ATK monsters on the field and in the hand are destroyed, the small ones stay")
	var lp1: int = s.players[1].lp
	s._damage(1, 1000)
	check(s.players[1].lp == lp1, "Crush Card Virus: the opponent takes no damage until the end of the next turn")
	s = _bare(509)
	var cd := _rst(s, 0, "Cost Down")
	_in(s, 0, "Kuriboh", "hand")
	be = _in(s, 0, "Blue-Eyes White Dragon", "hand")
	var ox := _mon(s, 0, "Battle Ox", 0)
	s.activate(0, cd)
	check(be.level() == 6 and s.tributes_needed(be) == 1, "Cost Down: Blue-Eyes is Level 6 this turn and needs 1 Tribute (Level %d)" % be.level())
	s = _bare(510)
	var burst := _rst(s, 0, "Burst Stream of Destruction")
	_mon(s, 1, "Dark Magician", 0)
	check(not s.can_activate(0, burst), "Burst Stream of Destruction needs Blue-Eyes White Dragon")
	be = _mon(s, 0, "Blue-Eyes White Dragon", 0)
	be.summoned_turn = 1
	s.activate(0, burst)
	s.phase = DuelState.Phase.BATTLE
	check(s.players[1].monsters().is_empty() and not s.can_attack(0, be), "Burst Stream of Destruction: their monsters are destroyed and Blue-Eyes cannot attack this turn")
	s = _bare(511)
	s.current = 1
	be = _mon(s, 0, "Blue-Eyes White Dragon", 0)
	var imt := _rst(s, 0, "Interdimensional Matter Transporter", "set")
	s.chain_add(0, imt, be, "free")
	s.chain_resolve()
	check(s.players[0].banished.has(be) and not s.players[0].field.has(be), "Interdimensional Matter Transporter banishes the monster")
	s.begin_end()
	check(s.players[0].field.has(be), "It returns in the End Phase")


## The cards built in v0.33.33 for Joey's best deck, each against its printed text.
func _test_cards_36() -> void:
	# ---- Time Wizard: one side's monsters go, either way.
	var s := _bare(601)
	var tw := _mon(s, 0, "Time Wizard", 0)
	var mine := _mon(s, 0, "Red-Eyes Black Dragon", 1)
	var foe := _mon(s, 1, "Blue-Eyes White Dragon", 0)
	var lp0: int = s.players[0].lp
	s.ignite(0, tw)
	var won: bool = s.players[1].monsters().is_empty() and s.players[0].field.has(mine) and s.players[0].lp == lp0
	var lost: bool = s.players[0].monsters().is_empty() and s.players[1].field.has(foe) and s.players[0].lp == lp0 - (500 + 2400) / 2
	check(won or lost, "Time Wizard: their monsters are destroyed, or yours are and you take half their ATK (LP %d)" % s.players[0].lp)
	# ---- Panther Warrior, Gearfried, Jinzo.
	s = _bare(602)
	s.phase = DuelState.Phase.BATTLE
	var pw := _mon(s, 0, "Panther Warrior", 0)
	pw.summoned_turn = 1
	check(not s.can_attack(0, pw), "Panther Warrior cannot attack with no monster to Tribute")
	var fod := _mon(s, 0, "Kuriboh", 1)
	check(s.can_attack(0, pw), "Panther Warrior can attack with a monster to Tribute")
	s.declare_attack(0, pw, null)
	check(s.players[0].gy.has(fod), "Panther Warrior: 1 monster is Tributed to attack")
	s.resolve_attack()
	s = _bare(603)
	var gf := _mon(s, 0, "Gearfried the Iron Knight", 0)
	var eq := _rst(s, 0, "Lightning Blade")
	if s.can_activate(0, eq):
		s.activate(0, eq, gf)
	check(s.players[0].gy.has(eq) and s.atk_of(gf, false) == 1800, "Gearfried the Iron Knight destroys an Equip Card put on it (ATK %d)" % s.atk_of(gf, false))
	s = _bare(604)
	s.phase = DuelState.Phase.BATTLE
	_mon(s, 0, "Jinzo", 0)
	var att := _mon(s, 0, "Red-Eyes Black Dragon", 1)
	att.summoned_turn = 1
	var mf := _rst(s, 1, "Mirror Force", "set")
	s.declare_attack(0, att, null)
	check(not s.responses(1, "attack").has(mf), "Jinzo: Trap Cards cannot be activated")
	s.resolve_attack()
	# ---- Rocket Warrior.
	s = _bare(605)
	s.phase = DuelState.Phase.BATTLE
	var rw := _mon(s, 0, "Rocket Warrior", 0)
	rw.summoned_turn = 1
	foe = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	lp0 = s.players[0].lp
	s.declare_attack(0, rw, foe)
	s.resolve_attack()
	check(s.players[0].field.has(rw) and s.players[0].lp == lp0 and s.atk_of(foe, false) == 2500, "Rocket Warrior: not destroyed, no damage, and the target loses 500 ATK (got %d)" % s.atk_of(foe, false))
	# ---- Copycat, Graceful Dice, Skull Dice, Shield & Sword.
	s = _bare(606)
	foe = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	var cc := _in(s, 0, "Copycat", "hand")
	s.normal_summon(0, cc, [])
	check(s.atk_of(cc, false) == 3000 and s.def_of(cc) == 2500, "Copycat takes the monster's original ATK and DEF (got %d / %d)" % [s.atk_of(cc, false), s.def_of(cc)])
	var gd := _rst(s, 0, "Graceful Dice")
	s.activate(0, gd)
	var up_by: int = s.atk_of(cc, false) - 3000
	check(up_by >= 100 and up_by <= 600 and up_by % 100 == 0 and s.def_of(cc) == 2500 + up_by, "Graceful Dice: +100 to +600 ATK and DEF for your monsters (got +%d)" % up_by)
	var sd := _rst(s, 0, "Skull Dice", "set")
	s.activate(0, sd)
	var down_by: int = 3000 - s.atk_of(foe, false)
	check(down_by >= 100 and down_by <= 600 and s.def_of(foe) == 2500 - down_by, "Skull Dice: -100 to -600 ATK and DEF for their monsters (got -%d)" % down_by)
	s = _bare(607)
	var bg := _mon(s, 0, "Big Shield Gardna", 0)
	var ss := _rst(s, 0, "Shield & Sword")
	s.activate(0, ss)
	check(s.atk_of(bg, false) == 2600 and s.def_of(bg) == 100, "Shield & Sword: Big Shield Gardna is 2600 / 100 this turn (got %d / %d)" % [s.atk_of(bg, false), s.def_of(bg)])
	s.turn += 1
	check(s.atk_of(bg, false) == 100 and s.def_of(bg) == 2600, "Shield & Sword ends with the turn")


## The cards built in v0.33.33 for Jack's best deck, each against its printed text.
func _test_cards_37() -> void:
	# ---- Exploder Dragonwing, Chaos King Archfiend.
	var s := _bare(701)
	s.phase = DuelState.Phase.BATTLE
	var ex := _mon(s, 0, "Exploder Dragonwing", 0)
	ex.summoned_turn = 1
	var foe := _mon(s, 1, "Celtic Guardian", 0)
	var lp1: int = s.players[1].lp
	s.declare_attack(0, ex, foe)
	s.resolve_attack()
	check(s.players[1].gy.has(foe) and s.players[1].lp == lp1 - 1400, "Exploder Dragonwing: the weaker monster is destroyed before the battle and its 1400 ATK is dealt as damage (LP %d)" % s.players[1].lp)
	s = _bare(702)
	s.phase = DuelState.Phase.BATTLE
	var ck := _mon(s, 0, "Chaos King Archfiend", 0)
	ck.summoned_turn = 1
	foe = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	lp1 = s.players[1].lp
	s.declare_attack(0, ck, foe)
	check(s.atk_of(foe, false) == 2500 and s.def_of(foe) == 3000, "Chaos King Archfiend: Blue-Eyes is 2500 / 3000 for this Battle Phase (got %d / %d)" % [s.atk_of(foe, false), s.def_of(foe)])
	s.resolve_attack()
	check(s.players[1].gy.has(foe) and s.players[1].lp == lp1 - 100, "Chaos King Archfiend beats the switched Blue-Eyes by 100")
	# ---- The Resonators.
	s = _bare(703)
	var flare := _mon(s, 0, "Flare Resonator", 0)
	var mat := _mon(s, 0, "Mad Archfiend", 1)
	mat.lv_set = 5
	var rda := _in(s, 0, "Red Dragon Archfiend", "extra")
	check(s.can_extra_summon(0, rda), "Red Dragon Archfiend can be made with Flare Resonator")
	s.extra_summon(0, rda)
	check(s.atk_of(rda, false) == 3300, "Flare Resonator: the Synchro Monster gains 300 ATK (got %d)" % s.atk_of(rda, false))
	var crea := _in(s, 0, "Creation Resonator", "hand")
	check(s.can_special_from_hand(0, crea), "Creation Resonator can be Special Summoned while you control a Level 8 Synchro Monster")
	s = _bare(704)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	var att := _mon(s, 1, "Blue-Eyes White Dragon", 0)
	att.summoned_turn = 1
	var clock := _mon(s, 0, "Clock Resonator", 0, false)
	s.declare_attack(1, att, clock)
	s.resolve_attack()
	check(s.players[0].field.has(clock), "Clock Resonator in Defense Position survives one battle a turn")
	s.effect_by = 1
	s._destroy(clock)
	s.effect_by = -1
	check(not s.players[0].field.has(clock), "Clock Resonator: only once per turn")
	# ---- Power Breaker, Strong Wind Dragon, Small Piece Golem, Archfiend Interceptor, Attack Gainer, Dread Dragon.
	s = _bare(705)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	att = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	att.summoned_turn = 1
	var up := _rst(s, 1, "Swords of Revealing Light", "set")
	up.face_up = true
	var pb := _mon(s, 0, "Power Breaker", 0)
	var inter := _mon(s, 0, "Archfiend Interceptor", 1)
	lp1 = s.players[1].lp
	s.declare_attack(1, att, pb)
	check(s.players[1].lp == lp1 - 500, "Archfiend Interceptor: 500 damage when their monster declares an attack")
	s.resolve_attack()
	check(s.players[0].gy.has(pb) and s.players[1].gy.has(up), "Power Breaker destroyed by their attack: a face-up Spell/Trap of theirs is destroyed")
	s = _bare(706)
	var vice := _mon(s, 0, "Vice Dragon", 0)
	var swd := _in(s, 0, "Strong Wind Dragon", "hand")
	s.normal_summon(0, swd, [vice])
	check(s.players[0].field.has(swd) and s.atk_of(swd, false) == 3400 and EffectRunner.piercing(s, 0, swd), "Strong Wind Dragon: 2400 + half of Vice Dragon's 2000, and it pierces (got %d)" % s.atk_of(swd, false))
	s = _bare(707)
	_mon(s, 0, "Big Piece Golem", 0)
	var small := _in(s, 0, "Small Piece Golem", "hand")
	s.players[0].deck.append(s._make(_cid("Medium Piece Golem"), 0))
	s.normal_summon(0, small, [])
	var med: Array = s.players[0].monsters().filter(func(m): return m.cname() == "Medium Piece Golem")
	check(med.size() == 1 and med[0].negated, "Small Piece Golem: Medium Piece Golem comes out of the Deck with its effect negated")
	s = _bare(708)
	var gain := _mon(s, 0, "Attack Gainer", 1)
	var m5 := _mon(s, 0, "Mad Archfiend", 2)
	m5.lv_set = 7
	rda = _in(s, 0, "Red Dragon Archfiend", "extra")
	foe = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	if s.can_extra_summon(0, rda):
		s.extra_summon(0, rda)
	check(s.players[0].field.has(rda) and s.atk_of(foe, false) == 2000, "Attack Gainer used as Synchro Material: their monster loses 1000 ATK (got %d)" % s.atk_of(foe, false))
	s = _bare(709)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	att = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	att.summoned_turn = 1
	var dread := _mon(s, 0, "Dread Dragon", 0, false)
	s.players[0].deck.append(s._make(_cid("Baby Dragon"), 0))
	s.declare_attack(1, att, dread)
	s.resolve_attack()
	check(s.players[0].hand.size() == 1 and s.players[0].hand[0].level() <= 3, "Dread Dragon destroyed by battle: a Level 3 or lower Dragon is added to the hand")
	# ---- Fiendish Chain, Powerful Rebirth, Half or Nothing.
	s = _bare(710)
	s.current = 1
	var bb := _mon(s, 1, "Buster Blader", 0)
	bb.summoned_turn = 1
	_mon(s, 0, "Blue-Eyes White Dragon", 0)
	var fc := _rst(s, 0, "Fiendish Chain", "set")
	s.chain_add(0, fc, bb, "free")
	s.chain_resolve()
	s._cleanup()
	s.phase = DuelState.Phase.BATTLE
	check(bb.negated and s.atk_of(bb, false) == 2600 and not s.can_attack(1, bb), "Fiendish Chain: the monster's effects are negated and it cannot attack")
	s = _bare(711)
	s.current = 1
	var gy_m := _in(s, 0, "Mad Archfiend", "gy")
	var pr := _rst(s, 0, "Powerful Rebirth", "set")
	s.chain_add(0, pr, null, "free")
	s.chain_resolve()
	check(s.players[0].field.has(gy_m) and gy_m.level() == 5 and s.atk_of(gy_m, false) == 1900, "Powerful Rebirth: back from the Graveyard, 1 Level higher and +100 ATK (Level %d, ATK %d)" % [gy_m.level(), s.atk_of(gy_m, false)])
	s = _bare(712)
	s.current = 1
	s.phase = DuelState.Phase.BATTLE
	att = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	att.summoned_turn = 1
	var hon := _rst(s, 0, "Half or Nothing", "set")
	s.chain_add(0, hon, null, "free")
	s.chain_resolve()
	check(s.atk_of(att, false) == 1500 or not s.can_attack(1, att), "Half or Nothing: their ATK is halved, or the Battle Phase ends")


## The cards built in v0.33.33 for Crow's best deck, each against its printed text.
func _test_cards_38() -> void:
	# ---- Sirocco, Gust, Mistral, Ghibli.
	var s := _bare(801)
	var sir := _in(s, 0, "Blackwing - Sirocco the Dawn", "hand")
	check(s.tributes_needed(sir) == 1, "Sirocco needs a Tribute on an empty board")
	_mon(s, 1, "Celtic Guardian", 0)
	check(s.tributes_needed(sir) == 0, "Sirocco needs no Tribute when only the opponent controls a monster")
	s.normal_summon(0, sir, [])
	var bora := _mon(s, 0, "Blackwing - Bora the Spear", 1)
	s.ignite(0, sir)
	check(s.atk_of(sir, false) == 3700 or s.atk_of(bora, false) == 3700, "Sirocco: one Blackwing gains the other's ATK (got %d / %d)" % [s.atk_of(sir, false), s.atk_of(bora, false)])
	s.phase = DuelState.Phase.BATTLE
	sir.summoned_turn = 1
	bora.summoned_turn = 1
	check(s.can_attack(0, sir) != s.can_attack(0, bora), "Sirocco: only the chosen monster can attack this turn")
	s = _bare(802)
	var gust := _in(s, 0, "Blackwing - Gust the Backblast", "hand")
	check(s.can_special_from_hand(0, gust), "Gust can be Special Summoned while you control no cards")
	s.players[0].hand.erase(gust)
	s._special(0, gust, "effect", "atk")
	var shura := _mon(s, 0, "Blackwing - Shura the Blue Flame", 1)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	var att := _mon(s, 1, "Vorse Raider", 0)
	att.summoned_turn = 1
	var lp0: int = s.players[0].lp
	s.declare_attack(1, att, shura)
	s.resolve_attack()
	check(s.players[0].field.has(shura) and s.players[1].gy.has(att), "Gust: Vorse Raider (1900) loses 300 attacking Shura (1800) and is destroyed")
	s = _bare(803)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	att = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	att.summoned_turn = 1
	var att2 := _mon(s, 1, "Vorse Raider", 1)
	att2.summoned_turn = 1
	var mis := _mon(s, 0, "Blackwing - Mistral the Silver Shield", 0, false)
	var ghi := _in(s, 0, "Blackwing - Ghibli the Searing Wind", "hand")
	s.declare_attack(1, att, mis)
	s.resolve_attack()
	lp0 = s.players[0].lp
	s.declare_attack(1, att2, null)
	check(s.responses(0, "attack").has(ghi), "Ghibli is offered from the hand on a direct attack")
	s.resolve_attack()
	check(s.players[0].lp == lp0, "Mistral: the next battle damage this turn is 0")
	# ---- Black Whirlwind, Blackback, Against the Wind, Backlash, Trap Stun.
	s = _bare(804)
	var bw := _rst(s, 0, "Black Whirlwind")
	s.activate(0, bw)
	s.players[0].deck.append(s._make(_cid("Blackwing - Gale the Whirlwind"), 0))
	var sh := _in(s, 0, "Blackwing - Shura the Blue Flame", "hand")
	s.normal_summon(0, sh, [])
	check(s.players[0].hand.size() == 1 and s.players[0].hand[0].cname() == "Blackwing - Gale the Whirlwind", "Black Whirlwind: a weaker Blackwing is added from the Deck when one is Normal Summoned")
	var back := _rst(s, 0, "Blackback", "set")
	_in(s, 0, "Blackwing - Bora the Spear", "gy")
	check(not s.can_activate(0, back), "Blackback cannot be activated after a Normal Summon")
	s = _bare(805)
	back = _rst(s, 0, "Blackback", "set")
	var gy_b := _in(s, 0, "Blackwing - Bora the Spear", "gy")
	s.activate(0, back)
	check(s.players[0].field.has(gy_b) and s.normal_summoned, "Blackback: a Blackwing with 2000 or less ATK comes back, and no Normal Summon this turn")
	var atw := _rst(s, 0, "Against the Wind")
	var gy_g := _in(s, 0, "Blackwing - Gale the Whirlwind", "gy")
	lp0 = s.players[0].lp
	s.activate(0, atw)
	check(s.players[0].hand.has(gy_g) and s.players[0].lp == lp0 - 1300, "Against the Wind: take its ATK as damage and add it to the hand")
	s = _bare(806)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	att = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	att.summoned_turn = 1
	var bl := _rst(s, 0, "Blackwing - Backlash", "set")
	for i in 5:
		_in(s, 0, "Blackwing - Gale the Whirlwind", "gy")
	s.declare_attack(1, att, null)
	check(s.responses(0, "attack").has(bl), "Blackwing - Backlash is offered with 5 Blackwings in the Graveyard")
	s.respond(0, bl)
	check(s.players[1].monsters().is_empty(), "Blackwing - Backlash destroys every monster the opponent controls")
	s.resolve_attack()
	s = _bare(807)
	s.phase = DuelState.Phase.BATTLE
	var mine := _mon(s, 0, "Blue-Eyes White Dragon", 0)
	mine.summoned_turn = 1
	var stun := _rst(s, 0, "Trap Stun", "set")
	var mf := _rst(s, 1, "Mirror Force", "set")
	s.chain_add(0, stun, null, "free")
	s.chain_resolve()
	s.declare_attack(0, mine, null)
	check(not s.responses(1, "attack").has(mf), "Trap Stun: their Trap cannot be used this turn")
	s.resolve_attack()
	# ---- Silverwind the Ascendant, Black-Winged Dragon.
	s = _bare(808)
	var gale := _mon(s, 0, "Blackwing - Gale the Whirlwind", 0)
	var m1 := _mon(s, 0, "Blackwing - Shura the Blue Flame", 1)
	var m2 := _mon(s, 0, "Kuriboh", 2)
	var sw := _in(s, 0, "Blackwing - Silverwind the Ascendant", "extra")
	var e1 := _mon(s, 1, "Blue-Eyes White Dragon", 0)
	var e2 := _mon(s, 1, "Dark Magician", 1)
	check(s.can_extra_summon(0, sw), "Silverwind can be made with a Blackwing Tuner and 2 non-Tuners (3 + 4 + 1)")
	s.extra_summon(0, sw)
	check(s.players[0].field.has(sw) and s.players[1].monsters().is_empty(), "Silverwind: 2 monsters with DEF under 2800 are destroyed")
	s.phase = DuelState.Phase.BATTLE
	sw.summoned_turn = 1
	check(not s.can_attack(0, sw), "Silverwind: no Battle Phase the turn that effect is used")
	s = _bare(809)
	var bwd := _mon(s, 0, "Black-Winged Dragon", 0)
	lp0 = s.players[0].lp
	s._damage(0, 800)
	check(s.players[0].lp == lp0 and bwd.counter == 1 and s.atk_of(bwd, false) == 2100, "Black-Winged Dragon: effect damage becomes a counter, and it loses 700 ATK (got %d)" % s.atk_of(bwd, false))
	var e3 := _mon(s, 1, "Blue-Eyes White Dragon", 0)
	var lp1: int = s.players[1].lp
	s.ignite(0, bwd)
	check(bwd.counter == 0 and s.atk_of(bwd, false) == 2800 and s.atk_of(e3, false) == 2300 and s.players[1].lp == lp1 - 700, "Black-Winged Dragon: counters removed, their monster loses 700 ATK and they take 700")


## The cards built in v0.33.33 for Akiza's best deck, each against its printed text.
func _test_cards_39() -> void:
	# ---- Violet Witch and Rose Fairy; Witch of the Black Rose.
	var s := _bare(901)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	var att := _mon(s, 1, "Blue-Eyes White Dragon", 0)
	att.summoned_turn = 1
	var vw := _mon(s, 0, "Violet Witch", 0, false)
	s.players[0].deck.append(s._make(_cid("Rose Fairy"), 0))
	s.declare_attack(1, att, vw)
	s.resolve_attack()
	check(s.players[0].monsters().filter(func(m): return m.cname() == "Rose Fairy").size() == 1, "Violet Witch fetches Rose Fairy, and Rose Fairy Special Summons itself when it is added from the Deck")
	s = _bare(902)
	var wbr := _in(s, 0, "Witch of the Black Rose", "hand")
	s.players[0].deck.append(s._make(_cid("Pot of Greed"), 0))
	s.normal_summon(0, wbr, [])
	check(s.players[0].gy.has(wbr) and s.players[0].hand.is_empty(), "Witch of the Black Rose: the card drawn was not a monster, so it goes to the Graveyard and she is destroyed")
	s = _bare(903)
	wbr = _in(s, 0, "Witch of the Black Rose", "hand")
	s.players[0].deck.append(s._make(_cid("Kuriboh"), 0))
	s.normal_summon(0, wbr, [])
	check(s.players[0].field.has(wbr) and s.players[0].hand.size() == 1, "Witch of the Black Rose: a monster drawn stays in the hand and she stays")
	# ---- Phoenixian Seed and Phoenixian Cluster Amaryllis.
	s = _bare(904)
	var seed := _mon(s, 0, "Phoenixian Seed", 0)
	var ama := _in(s, 0, "Phoenixian Cluster Amaryllis", "hand")
	_in(s, 0, "Lonefire Blossom", "gy")
	s.ignite(0, seed)
	check(s.players[0].field.has(ama) and s.players[0].gy.has(seed), "Phoenixian Seed goes to the Graveyard and Amaryllis comes out of the hand")
	s.phase = DuelState.Phase.BATTLE
	ama.summoned_turn = 1
	var lp1: int = s.players[1].lp
	s.declare_attack(0, ama, null)
	s.resolve_attack()
	check(s.players[0].gy.has(ama) and s.players[1].lp == lp1 - 2200 - 800, "Amaryllis: 2200 direct, then it is destroyed and deals 800 more (LP %d)" % s.players[1].lp)
	s.begin_end()
	check(s.players[0].field.has(ama) and not ama.attack_pos and s.players[0].banished.size() == 1, "Amaryllis: in your End Phase it comes back in Defense Position by banishing a Plant from the Graveyard")
	# ---- Blue Rose Dragon, Queen Angel of Roses.
	s = _bare(905)
	var brd := _mon(s, 0, "Blue Rose Dragon", 0)
	var gy_p := _in(s, 0, "Lonefire Blossom", "gy")
	s.effect_by = 1
	s._destroy(brd)
	s.effect_by = -1
	check(s.players[0].field.has(gy_p), "Blue Rose Dragon destroyed: a Plant monster comes back from the Graveyard")
	s = _bare(906)
	var plant := _mon(s, 0, "Lonefire Blossom", 0)
	var other := _mon(s, 0, "Twilight Rose Knight", 1)
	var queen := _in(s, 0, "Queen Angel of Roses", "hand")
	check(s.tributes_needed(queen) == 1, "Queen Angel of Roses needs 1 Tribute when you control a Plant")
	s.normal_summon(0, queen, [other])
	check(s.players[0].field.has(queen) and s.players[0].gy.has(plant) and s.players[0].field.has(other), "Queen Angel of Roses is Tribute Summoned with the Plant")
	var weak := _mon(s, 1, "Kuriboh", 0)
	EffectRunner.standby(s, 0)
	check(s.players[1].gy.has(weak), "Queen Angel of Roses: in your Standby Phase the monster with the lowest ATK is destroyed")
	# ---- Seed of Deception, Thorn of Malice, Wicked Rebirth, Blossom Bombardment.
	s = _bare(907)
	var sod := _rst(s, 0, "Seed of Deception")
	seed = _in(s, 0, "Phoenixian Seed", "hand")
	s.activate(0, sod)
	check(s.players[0].field.has(seed), "Seed of Deception Special Summons a Level 2 or lower Plant from the hand")
	s = _bare(908)
	var rose := _mon(s, 0, "Black Rose Dragon", 0)
	rose.summoned_turn = 1
	var thorn := _rst(s, 0, "Thorn of Malice")
	var warrior := _mon(s, 0, "Celtic Guardian", 1)
	check(not SpellRules.targets(s, 0, thorn).has(warrior) and SpellRules.targets(s, 0, thorn).has(rose), "Thorn of Malice goes on Black Rose Dragon or a Plant only")
	s.activate(0, thorn, rose)
	var foe := _mon(s, 1, "Dark Magician", 0)
	lp1 = s.players[1].lp
	s.phase = DuelState.Phase.BATTLE
	s.declare_attack(0, rose, foe)
	s.resolve_attack()
	check(s.players[1].field.has(foe) and s.players[1].lp == lp1 - 500 and s.atk_of(foe, false) == 1900 and s.def_of(foe) == 1500, "Thorn of Malice: 3000 against 2500, the monster is not destroyed and loses 600 ATK and DEF (LP %d, %d / %d)" % [s.players[1].lp, s.atk_of(foe, false), s.def_of(foe)])
	s = _bare(909)
	s.current = 1
	var gy_s := _in(s, 0, "Black Rose Dragon", "gy")
	gy_s.proper = true
	var wr := _rst(s, 0, "Wicked Rebirth", "set")
	var lp0: int = s.players[0].lp
	s.chain_add(0, wr, null, "free")
	s.chain_resolve()
	check(s.players[0].field.has(gy_s) and gy_s.negated and s.players[0].lp == lp0 - 800, "Wicked Rebirth: 800 LP, the Synchro Monster comes back with its effects negated")
	s = _bare(910)
	s.phase = DuelState.Phase.BATTLE
	var bb := _rst(s, 0, "Blossom Bombardment", "set")
	bb.face_up = true
	var lone := _mon(s, 0, "Rose Tentacles", 0)
	lone.summoned_turn = 1
	foe = _mon(s, 1, "Celtic Guardian", 0)
	lp1 = s.players[1].lp
	s.declare_attack(0, lone, foe)
	s.resolve_attack()
	check(s.players[1].lp == lp1 - 800 - 1400, "Blossom Bombardment: 800 battle damage and the destroyed monster's 1400 ATK (LP %d)" % s.players[1].lp)


## The cards built in v0.33.33 for Kalin's best deck, each against its printed text.
func _test_cards_40() -> void:
	# ---- Infernity Beetle, Destroyer, Randomizer, Archer.
	var s := _bare(1001)
	var beetle := _mon(s, 0, "Infernity Beetle", 0)
	s.players[0].deck.append(s._make(_cid("Infernity Beetle"), 0))
	s.players[0].deck.append(s._make(_cid("Infernity Beetle"), 0))
	s.ignite(0, beetle)
	check(s.players[0].gy.has(beetle) and s.players[0].monsters().filter(func(m): return m.cname() == "Infernity Beetle").size() == 2, "Infernity Beetle: Tributed with an empty hand, 2 more come out of the Deck")
	s = _bare(1002)
	s.phase = DuelState.Phase.BATTLE
	var des := _mon(s, 0, "Infernity Destroyer", 0)
	des.summoned_turn = 1
	var arch := _mon(s, 0, "Infernity Archer", 1)
	arch.summoned_turn = 1
	var foe := _mon(s, 1, "Celtic Guardian", 0)
	var lp1: int = s.players[1].lp
	check(s.can_direct_attack_with(0, arch), "Infernity Archer can attack directly with an empty hand")
	s.declare_attack(0, des, foe)
	s.resolve_attack()
	check(s.players[1].lp == lp1 - 900 - 1600, "Infernity Destroyer: 900 battle damage and 1600 more with an empty hand (LP %d)" % s.players[1].lp)
	_in(s, 0, "Kuriboh", "hand")
	foe = _mon(s, 1, "Celtic Guardian", 0)
	check(not s.can_direct_attack_with(0, arch), "Infernity Archer cannot attack directly with a card in hand")
	s = _bare(1003)
	var ran := _mon(s, 0, "Infernity Randomizer", 0)
	s.players[0].deck.append(s._make(_cid("Blue-Eyes White Dragon"), 0))
	lp1 = s.players[1].lp
	s.ignite(0, ran)
	check(s.players[1].lp == lp1 - 1600 and s.players[0].hand.size() == 1, "Infernity Randomizer: a Level 8 monster drawn means 1600 damage")
	check(not s.can_ignite(0, ran), "Infernity Randomizer needs an empty hand")
	# ---- Hundred Eyes Dragon, Void Ogre Dragon.
	s = _bare(1004)
	var hed := _mon(s, 0, "Hundred Eyes Dragon", 0)
	var gy_d := _in(s, 0, "Infernity Destroyer", "gy")
	s.ignite(0, hed)
	check(s.players[0].banished.has(gy_d) and hed.cname() == "Infernity Destroyer", "Hundred Eyes Dragon banishes a DARK monster from the Graveyard and takes its name and effects")
	s.begin_end()
	check(hed.cname() == "Hundred Eyes Dragon", "Hundred Eyes Dragon is itself again after the End Phase")
	s = _bare(1005)
	s.current = 1
	var vod := _mon(s, 0, "Void Ogre Dragon", 0)
	var pot := _rst(s, 1, "Pot of Greed")
	var h1: int = s.players[1].hand.size()
	s.chain_add(1, pot)
	check(s.responses(0, "chain", s.chain.back()).has(vod), "Void Ogre Dragon can answer a Spell Card with an empty hand")
	s.respond(0, vod)
	s.chain_resolve()
	check(s.players[1].gy.has(pot) and s.players[1].hand.size() == h1 - 1, "Void Ogre Dragon negates the Spell and destroys it")
	# ---- Infernity Inferno, Break, Barrier, Force; Void Trap Hole.
	s = _bare(1006)
	var inf := _rst(s, 0, "Infernity Inferno", "set")
	_in(s, 0, "Kuriboh", "hand")
	_in(s, 0, "Kuriboh", "hand")
	var d1 := s._make(_cid("Infernity Archfiend"), 0)
	var d2 := s._make(_cid("Infernity Necromancer"), 0)
	s.players[0].deck.append(d1)
	s.players[0].deck.append(d2)
	s.activate(0, inf)
	check(s.players[0].hand.is_empty() and s.players[0].gy.has(d1) and s.players[0].gy.has(d2), "Infernity Inferno: 2 discards, 2 Infernity cards from the Deck to the Graveyard")
	var brk := _rst(s, 0, "Infernity Break", "set")
	foe = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	s.activate(0, brk)
	check(s.players[1].gy.has(foe) and s.players[0].banished.size() == 1, "Infernity Break: an Infernity card banished from the Graveyard, their card destroyed")
	s = _bare(1007)
	s.current = 1
	_mon(s, 0, "Infernity Archfiend", 0)
	var bar := _rst(s, 0, "Infernity Barrier", "set")
	pot = _rst(s, 1, "Pot of Greed")
	h1 = s.players[1].hand.size()
	s.chain_add(1, pot)
	check(s.responses(0, "chain", s.chain.back()).has(bar), "Infernity Barrier can answer with an Attack Position Infernity monster and an empty hand")
	s.chain_add(0, bar, null, "chain", s.chain.back())
	s.chain_resolve()
	check(s.players[1].hand.size() == h1 - 1 and s.players[1].gy.has(pot), "Infernity Barrier negates the activation")
	s = _bare(1008)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	var att := _mon(s, 1, "Blue-Eyes White Dragon", 0)
	att.summoned_turn = 1
	var tgt := _mon(s, 0, "Infernity Archfiend", 0)
	var gy_i := _in(s, 0, "Infernity Destroyer", "gy")
	var force := _rst(s, 0, "Infernity Force", "set")
	s.declare_attack(1, att, tgt)
	check(s.responses(0, "attack").has(force), "Infernity Force is offered when an Infernity monster is attacked with an empty hand")
	s.respond(0, force)
	check(s.players[1].gy.has(att) and s.players[0].field.has(gy_i), "Infernity Force: the attacker is destroyed and an Infernity monster comes back")
	s.resolve_attack()
	s = _bare(1009)
	var vth := _rst(s, 0, "Void Trap Hole", "set")
	s.current = 1
	var big := s._make(_cid("Blue-Eyes White Dragon"), 1)
	s._special(1, big, "effect", "atk")
	check(s.responses(0, "summon", big).has(vth), "Void Trap Hole is offered when a 2000+ ATK monster is Special Summoned")
	s.respond(0, vth, big)
	check(s.players[1].gy.has(big), "Void Trap Hole destroys it")


## The cards built in v0.33.34 for Kite's best deck, each against its printed text.
func _test_cards_41() -> void:
	# ---- Starliege Lord Galaxion: 2 Level 4 Photon monsters; detach 2 to bring Galaxy-Eyes out of the Deck.
	var s := _bare(1101)
	var a1 := _mon(s, 0, "Photon Thrasher", 0)
	var a2 := _mon(s, 0, "Celtic Guardian", 1)
	var gal := _in(s, 0, "Starliege Lord Galaxion", "extra")
	check(not s.can_extra_summon(0, gal), "Galaxion needs 2 Photon monsters (Celtic Guardian does not count)")
	var a3 := _mon(s, 0, "Photon Crusher", 2)
	check(s.can_extra_summon(0, gal), "Galaxion can be made with 2 Level 4 Photon monsters")
	s.extra_summon(0, gal)
	var ge := s._make(_cid("Galaxy-Eyes Photon Dragon"), 0)
	s.players[0].deck.append(ge)
	s.ignite(0, gal)
	check(s.players[0].field.has(ge) and gal.overlays.is_empty(), "Galaxion: 2 materials detached, Galaxy-Eyes Photon Dragon comes out of the Deck")
	var sl := _in(s, 0, "Photon Slasher", "hand")
	check(s.can_special_from_hand(0, sl), "Photon Slasher can be Special Summoned while an Xyz Monster is on the field")
	# ---- Photon Wyvern, Photon Caesar, Daybreaker.
	s = _bare(1102)
	var wy := _in(s, 0, "Photon Wyvern", "hand")
	var f1 := _mon(s, 0, "Kuriboh", 0)
	var f2 := _mon(s, 0, "Kuriboh", 1)
	var set_st := _rst(s, 1, "Mirror Force", "set")
	var set_m := _mon(s, 1, "Dark Magician", 0, false)
	set_m.face_up = false
	var up_m := _mon(s, 1, "Celtic Guardian", 1)
	s.normal_summon(0, wy, [f1, f2])
	check(s.players[1].gy.has(set_st) and s.players[1].gy.has(set_m) and s.players[1].field.has(up_m), "Photon Wyvern: every Set card on the other side is destroyed, face-up ones stay")
	s = _bare(1103)
	var cz := _in(s, 0, "Photon Caesar", "hand")
	s.players[0].deck.append(s._make(_cid("Photon Caesar"), 0))
	f1 = _mon(s, 0, "Kuriboh", 0)
	f2 = _mon(s, 0, "Kuriboh", 1)
	s.normal_summon(0, cz, [f1, f2])
	check(s.players[0].monsters().filter(func(m): return m.cname() == "Photon Caesar").size() == 2, "Photon Caesar: a second one comes out of the Deck")
	s = _bare(1104)
	var d1 := _in(s, 0, "Daybreaker", "hand")
	var d2 := _in(s, 0, "Daybreaker", "hand")
	s.players[0].hand.erase(d1)
	s._special(0, d1, "effect")
	EffectRunner.on_summon(s, 0, d1, "special")
	check(s.players[0].field.has(d2), "Daybreaker Special Summoned: another one follows from the hand")
	# ---- Photon Chargeman, Photon Pirate, Photon Circle, Galaxy Wizard.
	s = _bare(1105)
	var ch := _mon(s, 0, "Photon Chargeman", 0)
	ch.summoned_turn = 1
	s.ignite(0, ch)
	s.phase = DuelState.Phase.BATTLE
	check(s.atk_of(ch, false) == 2000 and not s.can_attack(0, ch), "Photon Chargeman: 2000 ATK, and it cannot attack this turn")
	s = _bare(1106)
	var pi := _mon(s, 0, "Photon Pirate", 0)
	_in(s, 0, "Photon Thrasher", "gy")
	_in(s, 0, "Photon Crusher", "gy")
	_in(s, 0, "Photon Leo", "gy")
	s.ignite(0, pi)
	s.ignite(0, pi)
	check(s.atk_of(pi, false) == 3000 and not s.can_ignite(0, pi), "Photon Pirate: +1000 twice (3000), and no third time (got %d)" % s.atk_of(pi, false))
	s = _bare(1107)
	s.phase = DuelState.Phase.BATTLE
	s.current = 1
	var att := _mon(s, 1, "Blue-Eyes White Dragon", 0)
	att.summoned_turn = 1
	var circ := _mon(s, 0, "Photon Circle", 0)
	var lp0: int = s.players[0].lp
	s.declare_attack(1, att, circ)
	s.resolve_attack()
	check(s.players[0].lp == lp0 - 1000, "Photon Circle: the 2000 battle damage is halved (LP %d)" % s.players[0].lp)
	s = _bare(1108)
	var gw := _mon(s, 0, "Galaxy Wizard", 0)
	s.ignite(0, gw)
	check(gw.level() == 8, "Galaxy Wizard is Level 8 this turn (no Galaxy card to search)")
	s = _bare(1109)
	gw = _mon(s, 0, "Galaxy Wizard", 0)
	var gk := s._make(_cid("Galaxy Knight"), 0)
	s.players[0].deck.append(gk)
	s.ignite(0, gw)
	check(s.players[0].gy.has(gw) and s.players[0].hand.has(gk), "Galaxy Wizard Tributed: a Galaxy card is added from the Deck")
	# ---- Photon Papilloperative, Number 10: Illumiknight.
	s = _bare(1110)
	var pap := _mon(s, 0, "Photon Papilloperative", 0)
	pap.overlays = [s._make(_cid("Kuriboh"), 0)]
	var wall := _mon(s, 1, "Big Shield Gardna", 0, false)
	wall.face_up = false
	s.ignite(0, pap)
	check(wall.face_up and wall.attack_pos and s.atk_of(wall, false) == 0, "Photon Papilloperative: the Defense monster is turned to Attack Position and loses 600 ATK (got %d)" % s.atk_of(wall, false))
	s = _bare(1111)
	var ill := _mon(s, 0, "Number 10: Illumiknight", 0)
	ill.overlays = [s._make(_cid("Kuriboh"), 0)]
	var junk := _in(s, 0, "Kuriboh", "hand")
	s.ignite(0, ill)
	check(s.players[0].gy.has(junk) and s.players[0].hand.size() == 1, "Illumiknight: 1 card from the hand to the Graveyard, 1 card drawn")
	# ---- Photon Lead, Accellight, Galaxy Expedition, Galaxy Storm.
	s = _bare(1112)
	var lead := _rst(s, 0, "Photon Lead")
	var th := _in(s, 0, "Photon Thrasher", "hand")
	s.activate(0, lead)
	check(s.players[0].field.has(th) and th.attack_pos, "Photon Lead Special Summons a Level 4 or lower LIGHT monster in Attack Position")
	var acc := _rst(s, 0, "Accellight")
	check(not s.can_activate(0, acc), "Accellight needs an empty field")
	s = _bare(1113)
	acc = _rst(s, 0, "Accellight")
	var crusher := s._make(_cid("Photon Crusher"), 0)
	s.players[0].deck.append(crusher)
	s.activate(0, acc)
	check(s.players[0].field.has(crusher) and s.normal_summoned, "Accellight: a Level 4 or lower Photon monster from the Deck, and no Normal Summon this turn")
	s = _bare(1114)
	var exp := _rst(s, 0, "Galaxy Expedition")
	ge = s._make(_cid("Galaxy-Eyes Photon Dragon"), 0)
	s.players[0].deck.append(ge)
	check(not s.can_activate(0, exp), "Galaxy Expedition needs a Level 5 or higher Photon or Galaxy monster")
	_mon(s, 0, "Photon Leo", 0)
	s.activate(0, exp)
	check(s.players[0].field.has(ge) and not ge.attack_pos, "Galaxy Expedition: Galaxy-Eyes Photon Dragon from the Deck in Defense Position")
	s = _bare(1115)
	var storm := _rst(s, 0, "Galaxy Storm")
	var x_full := _mon(s, 1, "Number 39: Utopia", 0)
	x_full.overlays = [s._make(_cid("Kuriboh"), 1)]
	check(not s.can_activate(0, storm), "Galaxy Storm cannot hit an Xyz Monster that has material")
	x_full.overlays.clear()
	s.activate(0, storm, x_full)
	check(s.players[1].gy.has(x_full), "Galaxy Storm destroys an Xyz Monster with no material")


## The cards built in v0.33.34 for Shark's best deck, each against its printed text.
func _test_cards_42() -> void:
	# ---- Drill Barnacle, Needle Sunfish, Jawsman.
	var s := _bare(1201)
	s.phase = DuelState.Phase.BATTLE
	var db := _mon(s, 0, "Drill Barnacle", 0)
	db.summoned_turn = 1
	var wall := _mon(s, 1, "Blue-Eyes White Dragon", 0)
	var lp1: int = s.players[1].lp
	check(s.can_direct_attack_with(0, db), "Drill Barnacle can attack directly past a monster")
	s.declare_attack(0, db, null)
	s.resolve_attack()
	check(s.players[1].lp == lp1 - 300 and s.atk_of(db, false) == 1300, "Drill Barnacle: 300 direct damage, then it gains 1000 ATK (got %d)" % s.atk_of(db, false))
	s = _bare(1202)
	var ns := _mon(s, 0, "Needle Sunfish", 0)
	wall = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	s._destroy(ns)
	check(s.atk_of(wall, false) == 2500, "Needle Sunfish sent to the Graveyard: their monster loses 500 ATK (got %d)" % s.atk_of(wall, false))
	s = _bare(1203)
	var jaw := _in(s, 0, "Jawsman", "hand")
	var earth := _mon(s, 0, "Celtic Guardian", 0)
	check(not s.can_normal_summon(0, jaw), "Jawsman cannot be Tribute Summoned with a non-WATER Tribute")
	var w1 := _mon(s, 0, "Big Jaws", 1)
	var w2 := _mon(s, 0, "Hammer Shark", 2)
	s.normal_summon(0, jaw, [earth])
	check(s.players[0].field.has(jaw) and s.players[0].field.has(earth) and s.atk_of(jaw, false) == 2900, "Jawsman: a WATER monster is Tributed instead, and it has 2600 + 300 for the other WATER monster (got %d)" % s.atk_of(jaw, false))
	# ---- Panther Shark, Cyber Shark, Silent Angler, Mermaid Shark.
	s = _bare(1204)
	var ps0 := _in(s, 0, "Panther Shark", "hand")
	var cy := _in(s, 0, "Cyber Shark", "hand")
	var ang := _in(s, 0, "Silent Angler", "hand")
	check(s.tributes_needed(ps0) == 1 and s.tributes_needed(cy) == 1 and not s.can_special_from_hand(0, ang), "With nothing on the field: Panther Shark and Cyber Shark need a Tribute, Silent Angler stays in the hand")
	_mon(s, 1, "Kuriboh", 0)
	_mon(s, 1, "Kuriboh", 1)
	check(s.tributes_needed(ps0) == 0, "Panther Shark needs no Tribute when the opponent controls 2 monsters")
	_mon(s, 0, "Eagle Shark", 0)
	check(s.tributes_needed(cy) == 0 and s.can_special_from_hand(0, ps0) and s.can_special_from_hand(0, ang), "With Eagle Shark out: Cyber Shark is free, Panther Shark and Silent Angler can be Special Summoned")
	s.special_from_hand(0, ang)
	check(s.players[0].field.has(ang) and not s.can_special_from_hand(0, ps0), "Silent Angler: no more Special Summons from the hand this turn")
	s = _bare(1205)
	var mer := _in(s, 0, "Mermaid Shark", "hand")
	var fish := s._make(_cid("Hammer Shark"), 0)
	s.players[0].deck.append(fish)
	s.normal_summon(0, mer, [])
	check(s.players[0].hand.has(fish), "Mermaid Shark adds a Level 3 to 5 Fish from the Deck")
	# ---- Aqua Jet, Surface.
	s = _bare(1206)
	var bj := _mon(s, 0, "Big Jaws", 0)
	var aj := _rst(s, 0, "Aqua Jet")
	s.activate(0, aj, bj)
	check(s.atk_of(bj, false) == 2800, "Aqua Jet: +1000 ATK (got %d)" % s.atk_of(bj, false))
	var sf := _rst(s, 0, "Surface")
	var gy_f := _in(s, 0, "Skull Kraken", "gy")
	_in(s, 0, "Jawsman", "gy")
	s.activate(0, sf)
	check(s.players[0].field.has(gy_f) and not gy_f.attack_pos, "Surface: a Level 3 or lower Fish comes back in Defense Position")
	# ---- Aero Shark, Nightmare Shark, Bahamut Shark.
	s = _bare(1207)
	var aero := _mon(s, 0, "Submersible Carrier Aero Shark", 0)
	aero.overlays = [s._make(_cid("Kuriboh"), 0)]
	for i in 3:
		s.players[0].banished.append(s._make(_cid("Kuriboh"), 0))
	lp1 = s.players[1].lp
	s.ignite(0, aero)
	check(s.players[1].lp == lp1 - 300, "Aero Shark: 100 damage for each of your 3 banished monsters")
	s = _bare(1208)
	var x1 := _mon(s, 0, "Big Jaws", 0)
	var x2 := _mon(s, 0, "Skull Kraken", 1)
	var extra_mat := _in(s, 0, "Needle Sunfish", "hand")
	var n47 := _in(s, 0, "Number 47: Nightmare Shark", "extra")
	s.extra_summon(0, n47)
	check(s.players[0].field.has(n47) and n47.overlays.size() == 3 and n47.overlays.has(extra_mat), "Nightmare Shark: a Level 3 WATER monster from the hand is attached as a third material")
	wall = _mon(s, 1, "Blue-Eyes White Dragon", 0)
	s.ignite(0, n47)
	s.phase = DuelState.Phase.BATTLE
	n47.summoned_turn = 1
	check(s.can_direct_attack_with(0, n47), "Nightmare Shark: a WATER monster can attack directly this turn")
	s = _bare(1209)
	var b1 := _mon(s, 0, "Hammer Shark", 0)
	var b2 := _mon(s, 0, "Double Shark", 1)
	var bah := _in(s, 0, "Bahamut Shark", "extra")
	var brl := _in(s, 0, "Submersible Carrier Aero Shark", "extra")
	check(s.can_extra_summon(0, bah), "Bahamut Shark can be made with 2 Level 4 WATER monsters")
	s.extra_summon(0, bah)
	s.ignite(0, bah)
	check(s.players[0].field.has(brl), "Bahamut Shark: a Rank 3 WATER Xyz Monster comes out of the Extra Deck")
	s.phase = DuelState.Phase.BATTLE
	bah.summoned_turn = 1
	check(not s.can_attack(0, bah), "Bahamut Shark cannot attack the turn it used that effect")
