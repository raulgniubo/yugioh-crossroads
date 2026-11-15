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
