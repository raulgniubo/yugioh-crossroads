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
	check(not gob.attack_pos, "Goblin Attack Force changes to Defense Position after attacking")
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
	s.activate(0, ring, ringed)
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
	# Ego Boost: not in the Main Phase, not on their attack, only on your own direct attack
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
	check(not SpellRules.fits(s, 0, ego, "attack", null), "Ego Boost does not fit an attack on a monster")
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
