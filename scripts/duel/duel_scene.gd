extends Node
## Runs a duel: turn loop, player input, AI turns, and plays state events
## through the board (3D) and the HUD (2D).

const ME := 0
const AI := 1

var state := DuelState.new()
var board: DuelBoard
var hud: DuelHUD
var busy := false
var mode := ""  # "", "tribute", "attack"
var _pending_card = null
var _pending_set := false
var _tributes: Array = []
var _attacker = null
var _menu_card = null
var _turn_done := false
var _finished := false
var _surrendered := false
var _autoplay := "--autoplay" in OS.get_cmdline_user_args() or "--auto-story" in OS.get_cmdline_user_args()
var _opp_key := "kaiba"
var _me_key := "player"
var _pending_tributes := 0
var _said_low := false
var _won := false
var _ai_level := 1
var _materials: Array = []

signal _turn_finished


func _ready() -> void:
	get_viewport().physics_object_picking = true
	Music.play("duel")
	board = DuelBoard.new()
	var cfg0: Dictionary = Router.duel_config
	board.theme = FieldThemes.resolve(str(cfg0.get("field", Settings.field_theme)), str(cfg0.get("opponent", "kaiba")))
	add_child(board)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = DuelHUD.new()
	hud.theme = UITheme.build()
	layer.add_child(hud)
	board.card_clicked.connect(_on_board_card_clicked)
	board.card_hovered.connect(_on_board_card_hovered)
	board.ace_summoned.connect(func(inst):
		hud.summon_cinematic(inst.cname(), int(inst.data.get("atk", 0)), int(inst.data.get("def", 0)),
			board._frame_color(inst), inst.owner == ME))
	hud.hand_card_pressed.connect(_on_hand_card_pressed)
	hud.hand_card_hovered.connect(func(inst): hud.inspect(inst))
	hud.phase_button.connect(_on_phase_button)
	hud.action_chosen.connect(_on_action)
	hud.cancel_pressed.connect(_cancel_mode)
	hud.direct_attack_pressed.connect(_on_direct_attack)
	hud.pause_action.connect(_on_pause_action)
	hud.extra_pressed.connect(_on_extra_pressed)
	hud.extra_chosen.connect(_on_extra_chosen)
	_start()


func _debug_cine() -> void:
	await get_tree().create_timer(4.0).timeout
	var inst = state._make(89631139, ME)
	if "--battle-demo" in OS.get_cmdline_user_args():
		# Two monsters on the field, ours attacks theirs and it shatters.
		var foe = state._make(89631139, AI)
		await board.anim_summon(ME, inst, 2, false)
		await board.anim_summon(AI, foe, 2, false)
		await board.anim_declare(ME, inst, foe)
		await board.anim_battle(ME, inst, foe)
		await board.anim_destroy(foe)
		return
	board.hologram(inst, board.monster_zone_pos(ME, 2))


func _start() -> void:
	if "--cine" in OS.get_cmdline_user_args() or "--battle-demo" in OS.get_cmdline_user_args():
		_debug_cine()
	var cfg: Dictionary = Router.duel_config
	_opp_key = cfg.get("opponent", "kaiba")
	_ai_level = int(cfg.get("difficulty", 1))
	var opp: Dictionary = Characters.get_char(_opp_key)
	var my_deck: String = cfg.get("player_deck", "yugi")
	var opp_deck: String = cfg.get("opponent_deck", opp.get("deck", "kaiba"))
	var opp_name: String = opp.get("name", "Rival")
	_me_key = cfg.get("player_char", "player")
	var me_info := Portraits.info(_me_key)
	var me_name: String = me_info.get("name", Profile.duelist_name)
	hud.set_names(me_name, opp_name)
	hud.set_portraits(_me_key, _opp_key)
	var first := randi() % 2
	if not _autoplay and not cfg.has("first"):
		# Coin toss: the winner decides who takes the first turn.
		var toss := randi() % 2
		if toss == ME:
			first = ME if await hud.ask_choice("You won the coin toss", ["Go first", "Go second"]) == 0 else AI
		else:
			first = AI
	state.defer_fx = true
	state.manual = [not _autoplay, false]
	var opp_list := CardData.legend_deck(opp_deck) if _ai_level >= 2 else CardData.deck_list(opp_deck)
	state.bonus_cards = [0, 1 if _ai_level >= 2 else 0]
	board.state_ref = state
	var events := state.setup(CardData.deck_list(my_deck), opp_list, me_name, opp_name, first, -1,
			CardData.extra_list(my_deck), CardData.extra_list(opp_deck))
	for p in 2:
		board.set_deck_count(p, state.players[p].deck.size() + 5 + state.bonus_cards[p])
	_update_counts()
	hud.set_phase_buttons("", false, false)
	hud.set_extra_button(state.players[ME].extra.size(), 0, false)
	board.add_duelists(_me_key, _opp_key)
	var fly := "--no-fly" not in OS.get_cmdline_user_args()
	if not _autoplay:
		if fly:
			board.intro_hold()
		await hud.vs_intro(
			{"key": _me_key, "name": me_name, "color": me_info.get("color", Profile.color()), "sub": "%s Deck" % CardData.deck_name(my_deck)},
			{"key": _opp_key, "name": opp_name, "color": opp.get("color", UITheme.DANGER),
				"sub": "%s  ·  %s Deck" % [opp.get("title", ""), CardData.deck_name(opp_deck)]})
		hud.say(AI, Characters.line(_opp_key, "intro"))
		if fly:
			await board.intro_duelists()
	else:
		if fly:
			board.intro_flyover(2.5)
		await get_tree().create_timer(0.5).timeout
		hud.say(AI, Characters.line(_opp_key, "intro"))
	await hud.banner("DUEL!", UITheme.ACCENT)
	if "--end-test" in OS.get_cmdline_user_args():
		state.winner = AI if "--lose" in OS.get_cmdline_user_args() else ME
		state.win_reason = "Test finish."
		_finish()
		return
	await _play(events)
	await hud.banner("You go first" if first == ME else "%s goes first" % opp.get("short", opp_name), UITheme.TEXT)
	_loop()


func _speaker(p: int) -> String:
	return _me_key if p == ME else _opp_key


func _loop() -> void:
	while not state.is_over():
		# Draw Phase, Standby Phase, then Main Phase 1. Both players may act in each.
		await _act("begin_turn", [true])
		if state.is_over():
			break
		await _phase_window("Draw Phase")
		if not state.is_over():
			await _act("begin_standby", [])
			await _phase_window("Standby Phase")
		if state.is_over():
			break
		await _act("begin_main1", [])
		if state.current == AI or _autoplay:
			await _ai_turn(state.current)
		else:
			_turn_done = false
			_refresh()
			if "--demo-actions" in OS.get_cmdline_user_args():
				_demo_actions()
			await _turn_finished
		if state.is_over():
			break
		_cancel_mode()
		await _act("begin_end", [])
		await _phase_window("End Phase")
		if state.is_over():
			break
		await _act("finish_turn", [])
	_finish()


## A chance for both players to act in a phase (the turn player first).
func _phase_window(phase_name: String) -> void:
	if state.is_over() or _finished:
		return
	await _window(state.current, "phase", null, "%s. Activate a card?" % phase_name)


# ------------------------------------------------------------------ running the rules

## Run a rules action for real. Every choice it leaves to the human (a discard, a target, a
## material, a position) is found first by trying the action on a copy of the duel, asked,
## then replayed in the same order. Nothing is picked for you.
func _run(fn: Callable, args: Array = [], settle := true) -> Array:
	var answers: Array = []
	if not _autoplay:
		var guard := 0
		while guard < 30:
			guard += 1
			var sim := state.clone()
			sim.manual = state.manual.duplicate()
			sim.answers = answers.duplicate(true)
			fn.call(sim, _map(sim, args))
			if sim.need == null:
				break
			answers.append(await _ask(sim.need))
	state.answers = answers
	state.need = null
	var ev: Array = fn.call(state, args)
	state.answers = []
	await _play(ev)
	if settle:
		await _settle()
	return ev


func _act(method: String, args: Array = [], settle := true) -> Array:
	return await _run(func(st, a): return st.callv(method, a), args, settle)


## The same cards / chain links inside a copy of the duel.
func _map(st: DuelState, v):
	if st == state:
		return v
	if v is DuelState.CardInst:
		return st.find_uid(v.uid)
	if v is Array:
		var out: Array = []
		for x in v:
			out.append(_map(st, x))
		return out
	if v is Dictionary:
		var idx := state.chain.find(v)
		if idx != -1 and idx < st.chain.size():
			return st.chain[idx]
		var d := {}
		for k in v:
			d[k] = _map(st, v[k])
		return d
	return v


func _where(c) -> String:
	for q in 2:
		var ps: DuelState.PlayerState = state.players[q]
		var who := "Your" if q == ME else "Their"
		if ps.hand.has(c): return who + " hand"
		if ps.field.has(c) or ps.spells.has(c) or ps.field_spell == c: return who + " field"
		if ps.gy.has(c): return who + " Graveyard"
		if ps.deck.has(c): return who + " Deck"
		if ps.banished.has(c): return who + " banished"
		if ps.extra.has(c): return who + " Extra Deck"
	return ""


## Put one decision in front of the player. Returns card uids, or [index] for an option.
func _ask(need: Dictionary) -> Array:
	var was := _flow
	_flow = true
	var src = state.find_uid(int(need.get("source", -1)))
	if need.has("options"):
		var idx: int = await hud.ask_choice(str(need["prompt"]), need["options"], src)
		_flow = was
		return [idx]
	var cands: Array = []
	for uid in need["cands"]:
		var x = state.find_uid(int(uid))
		if x != null:
			cands.append(x)
	var n: int = int(need["n"])
	var picked: Array = []
	while picked.size() < n and not cands.is_empty():
		var text := str(need["prompt"])
		if n > 1:
			text += "   (%d of %d)" % [picked.size() + 1, n]
		var hidden: Array = []
		var labels := {}
		for x in cands:
			labels[x.uid] = _where(x)
			if x.owner != ME and not x.face_up and (state.players[AI].field.has(x) or state.players[AI].spells.has(x)):
				hidden.append(x)
			elif state.players[AI].hand.has(x):
				hidden.append(x)
		var got = await hud.ask_pick(text, cands, "Select", "Skip" if need.get("optional", false) else "", hidden, labels)
		if got == null:
			picked = []
			break
		picked.append(got.uid)
		cands.erase(got)
	_flow = was
	return picked


## Effects that triggered and are waiting go on a chain, and the chain plays out.
func _settle() -> void:
	if not state.pending_fx.is_empty() and not state.is_over() and not _finished:
		await _window(state.opponent(state.current), "chain", null, "")


func _finish() -> void:
	if _finished:
		return
	_finished = true
	_cancel_mode()
	hud.set_phase_buttons("", false, false)
	hud.set_playable([])
	await get_tree().create_timer(0.6).timeout
	var won := state.winner == ME
	var tied := state.winner == DuelState.DRAW
	if "--auto-story" in OS.get_cmdline_user_args():
		get_tree().create_timer(2.0).timeout.connect(func():
			Router.story_result = "won" if state.winner == ME else "lost"
			Router.go(Router.STORY))
	print("DUEL OVER: winner %d (%s) LP %d vs %d turn %d" % [state.winner, state.win_reason, state.players[0].lp, state.players[1].lp, state.turn])
	var earned := 0
	if not _autoplay:
		Profile.record_result(won)
		earned = Collection.reward(won and not _surrendered, _ai_level)
	Sfx.play("win" if won else "lose")
	hud.say(AI, Characters.line(_opp_key, "lose" if won else "win"))
	# The winner gets the camera.
	var champ := ME if won else AI
	board.duelist_shot(champ, 0.9, not tied, 1.0)
	await get_tree().create_timer(1.5).timeout
	board.duelist_orbit(champ)
	var cfg: Dictionary = Router.duel_config
	var why: String = "You surrendered." if _surrendered else state.win_reason
	if earned > 0:
		why += "\n+%d Duel Points  (you have %d)" % [earned, Collection.dp]
	hud.show_result(won, why, cfg.get("story", false), cfg.get("lose_ok", false), cfg.get("continue_label", "Continue Story"),
			{"turns": state.turn, "lp": [state.players[ME].lp, state.players[AI].lp], "names": [state.players[ME].name, state.players[AI].name],
			"free": not cfg.has("return_to") and not cfg.get("story", false), "draw": tied})
	_won = won


# ------------------------------------------------------------------ events

func _play(events: Array) -> void:
	busy = true
	_refresh()
	for ev in events:
		await _play_event(ev)
		board.refresh_stats(state)
	busy = false
	_update_counts()
	_refresh()
	# A win can happen mid-turn (an attack or a burn spell). Release the turn wait.
	if state.is_over() and not _finished:
		_turn_finished.emit()


func _play_event(ev: Dictionary) -> void:
	var p: int = ev.get("player", 0)
	match ev["type"]:
		"turn":
			var mine := p == ME
			Sfx.play("turn")
			if randf() < 0.45:
				hud.say(p, Characters.line(_speaker(p), "turn"))
			await hud.banner("YOUR TURN" if mine else "%s'S TURN" % state.players[AI].name.to_upper(),
					UITheme.ACCENT if mine else Color("a08cff"))
		"phase":
			var ph: int = ev["phase"]
			hud.set_phase(ph, state.current == ME)
			board.set_battle_mode(ph == DuelState.Phase.BATTLE)
			var names := {DuelState.Phase.BATTLE: "BATTLE PHASE", DuelState.Phase.MAIN2: "MAIN PHASE 2", DuelState.Phase.END: "END PHASE"}
			if names.has(ph):
				var col: Color = UITheme.DANGER if ph == DuelState.Phase.BATTLE else (UITheme.ACCENT if state.current == ME else Color("a08cff"))
				await hud.phase_sweep(names[ph], col)
				if ph == DuelState.Phase.END and state.current == AI and randf() < 0.3:
					hud.say(AI, Characters.line(_opp_key, "taunt"))
		"draw":
			_update_counts()
			Sfx.play("draw", -6.0)
			await board.anim_draw(p, ev["card"], ev["deck"])
			if p == ME:
				hud.add_hand_card(ev["card"])
		"summon", "set":
			if p == ME:
				hud.remove_hand_card(ev["card"])
			Sfx.play("card")
			var is_ace: bool = ev["type"] == "summon" and (ev["card"].level() >= 7 or ev["card"].id == Characters.get_char(_opp_key).get("ace", 0))
			if ev["type"] == "summon":
				get_tree().create_timer(Settings.t(0.5)).timeout.connect(func(): Sfx.play("summon", -4.0))
			if is_ace:
				hud.say(p, Characters.line(_speaker(p), "ace"))
				hud.react(p, "ace")
			if ev["type"] == "summon" and _pending_tributes > 0:
				hud.banner("TRIBUTE SUMMON", UITheme.GOLD)
			_pending_tributes = 0
			await board.anim_summon(p, ev["card"], ev["zone"], ev["type"] == "set")
			if p == ME and ev["type"] == "summon" and ev["card"].atk() >= 2000 and randf() < 0.65:
				hud.say(AI, Characters.line(_opp_key, "react"))
		"tribute":
			_pending_tributes += 1
			Sfx.play("spell", -4.0, 0.8)
			board.hide_stats_for(ev["card"])
			await board.anim_tribute(ev["card"])
		"flip", "reveal":
			await board.anim_flip(p, ev["card"], ev["zone"])
		"position":
			await board.anim_position(p, ev["card"], ev["zone"])
		"activate":
			if p == ME:
				hud.remove_hand_card(ev["card"])
			hud.inspect(ev["card"])
			Sfx.play("spell")
			if SpellRules.kind(ev["card"]) in ["field", "equip", "cont", "ritual", "quick"]:
				var titles := {"field": "FIELD SPELL", "equip": "EQUIP SPELL", "cont": "CONTINUOUS SPELL", "ritual": "RITUAL SPELL", "quick": "QUICK-PLAY SPELL"}
				hud.effect_text("%s  ·  %s" % [titles[SpellRules.kind(ev["card"])], ev["card"].cname()], Color("7dffc8"))
			await board.anim_activate(p, ev["card"], int(ev.get("zone", 2)))
		"st_settle":
			await board.anim_settle(p, ev["card"], int(ev["zone"]))
		"st_reset":
			await board.anim_reset(p, ev["card"], int(ev["zone"]))
		"chain":
			Sfx.play("spell", -2.0, 1.25)
			hud.banner("CHAIN %d" % int(ev["n"]), Color("ffd23a"))
			await get_tree().create_timer(Settings.t(0.35)).timeout
		"control":
			Sfx.play("special", -3.0)
			board.hide_stats_for(ev["card"])
			hud.effect_text("%s changes sides!" % ev["card"].cname(), Color("ff8ad8"))
			await board.anim_control(p, ev["card"], int(ev["zone"]))
		"bounce":
			board.hide_stats_for(ev["card"])
			Sfx.play("card", -2.0)
			await board.anim_bounce(ev["card"])
			if not ev.get("extra", false):
				if p == ME:
					hud.add_hand_card(ev["card"])
				else:
					await board.anim_add_to_opp_hand(ev["card"])
		"gy_to_deck":
			board.remove_from_gy(ev["card"])
			board.set_deck_count(p, ev["deck"])
		"spell_done":
			await board.anim_spell_done(ev["card"])
		"attack":
			if ev["target"] == null or randf() < 0.3:
				hud.say(p, Characters.line(_speaker(p), "attack"))
			Sfx.play("attack")
			await board.anim_declare(p, ev["card"], ev["target"])
		"battle":
			get_tree().create_timer(Settings.t(0.12)).timeout.connect(func(): Sfx.play("impact"))
			await board.anim_battle(p, ev["card"], ev["target"])
		"attack_stopped":
			await board.anim_attack_stopped(ev["card"])
		"set_st":
			if p == ME:
				hud.remove_hand_card(ev["card"])
			Sfx.play("card")
			await board.anim_set_st(p, ev["card"], ev["zone"])
		"trap":
			Sfx.play("spell", 0.0, 0.8)
			hud.inspect(ev["card"])
			hud.banner(str(ev["card"].data["name"]).to_upper(), Color("ff4dd2"))
			await board.anim_trap(p, ev["card"], ev["zone"])
		"st_done":
			await board.anim_spell_done(ev["card"])
		"destroy_st":
			Sfx.play("destroy", -4.0)
			await board.anim_destroy(ev["card"])
		"hand_effect":
			if p == ME:
				hud.remove_hand_card(ev["card"])
			hud.effect_text(ev["text"])
			await board.anim_hand_effect(p, ev["card"])
		"effect":
			if ev["card"] != null:
				board.pulse(ev["card"], UITheme.GOLD)
			hud.effect_text(ev["text"])
			Sfx.play("heal", -6.0, 1.3)
			await get_tree().create_timer(Settings.t(0.5)).timeout
		"search":
			if p == ME:
				hud.add_hand_card(ev["card"])
			else:
				await board.anim_add_to_opp_hand(ev["card"])
			board.set_deck_count(p, ev["deck"])
		"detach":
			board.set_overlays(ev["card"])
		"swords_end":
			hud.effect_text("Swords of Revealing Light fades")
		"destroy":
			if p == AI and randf() < 0.5:
				hud.say(AI, Characters.line(_opp_key, "destroyed"))
			board.hide_stats_for(ev["card"])
			Sfx.play("destroy", -3.0)
			await board.anim_destroy(ev["card"], ev.get("overlays", []))
		"material":
			board.hide_stats_for(ev["card"])
			if ev["from"] == "hand" and p == ME:
				hud.remove_hand_card(ev["card"])
			_materials.append(ev["card"])
			Sfx.play("card", -4.0)
			await board.anim_material(p, ev["card"], ev["from"], board.monster_zone_pos(p, 2))
		"special":
			var method: String = ev["method"]
			if p == ME:
				hud.remove_hand_card(ev["card"])
			var titles := {"fusion": "FUSION SUMMON", "synchro": "SYNCHRO SUMMON", "xyz": "XYZ SUMMON", "reborn": "REVIVED"}
			Sfx.play("special")
			hud.say(p, Characters.line(_speaker(p), "ace"))
			hud.react(p, "ace")
			hud.banner(titles.get(method, "SPECIAL SUMMON"), board.METHOD_COLORS.get(method, UITheme.ACCENT))
			var mats := _materials.duplicate()
			_materials.clear()
			await board.anim_special(p, ev["card"], ev["zone"], method, mats)
		"discard":
			if p == ME:
				hud.remove_hand_card(ev["card"])
			await board.anim_discard(p, ev["card"])
		"banish":
			board.hide_stats_for(ev["card"])
			if ev["from"] == "hand" and int(ev.get("side", p)) == ME:
				hud.remove_hand_card(ev["card"])
			Sfx.play("destroy", -6.0)
			hud.effect_text("%s is banished" % ev["card"].cname(), Color("c9a0ff"))
			await board.anim_banish(ev["card"], ev["from"], int(ev.get("side", p)))
		"unbanish":
			board.remove_from_banished(ev["card"])
			if ev.get("to", "gy") == "gy":
				board._add_to_gy(ev["card"])
			await get_tree().create_timer(Settings.t(0.2)).timeout
		"gy_to_hand":
			board.remove_from_gy(ev["card"])
			if p == ME:
				hud.add_hand_card(ev["card"])
			else:
				await board.anim_add_to_opp_hand(ev["card"])
		"mill":
			board._add_to_gy(ev["card"])
			board.set_deck_count(p, ev["deck"])
		"redraw":
			if p == ME:
				for e in hud._hand.duplicate():
					hud.remove_hand_card(e["inst"])
			board.set_deck_count(p, ev["deck"])
		"lp":
			hud.set_lp(p, ev["lp"], ev["delta"])
			if ev["delta"] < 0:
				board.shake(0.5)
				Sfx.play("damage")
				hud.react(p, "hurt")
				if p == AI and ev["lp"] <= 2000 and not _said_low:
					_said_low = true
					hud.say(AI, Characters.line(_opp_key, "low"))
				elif ev["delta"] <= -1000:
					hud.say(p, Characters.line(_speaker(p), "hurt"))
			else:
				Sfx.play("heal")
			await get_tree().create_timer(Settings.t(0.45)).timeout
	_update_counts()


func _update_counts() -> void:
	for p in 2:
		var ps := state.players[p]
		hud.set_counts(p, ps.deck.size(), ps.hand.size(), ps.gy.size(), ps.banished.size())
		hud.piles[p] = [ps.gy, ps.banished]


# ------------------------------------------------------------------ player input

var _flow := false   # true while a chain / target prompt is running


func _my_turn() -> bool:
	if _flow:
		return false
	return state.current == ME and not busy and not state.is_over() and not hud.overlay_visible()


func _refresh() -> void:
	if not _my_turn():
		hud.set_phase_buttons("", false, false)
		hud.set_extra_button(state.players[ME].extra.size() if state.players.size() > 0 else 0, 0, false)
		hud.set_playable([])
		_clear_glows()
		return
	match state.phase:
		DuelState.Phase.MAIN1:
			hud.set_phase_buttons("Battle Phase", state.can_enter_battle(), true)
		DuelState.Phase.BATTLE:
			hud.set_phase_buttons("Main Phase 2", true, true)
		DuelState.Phase.MAIN2:
			hud.set_phase_buttons("", false, true)
		_:
			hud.set_phase_buttons("", false, false)
	var ready := 0
	for x in state.players[ME].extra:
		if state.can_extra_summon(ME, x):
			ready += 1
	hud.set_extra_button(state.players[ME].extra.size(), ready, true)
	var playable := []
	for c in state.players[ME].hand:
		if state.can_normal_summon(ME, c) or state.can_activate(ME, c) or state.can_special_from_hand(ME, c) or (c.is_trap() and state.can_set_st(ME, c)):
			playable.append(c)
	hud.set_playable(playable)
	_clear_glows()
	if mode == "":
		for st in state.players[ME].spells:
			var sc := board.card_for(st) if st != null else null
			if sc and not st.face_up:
				sc.set_glow(state.can_activate(ME, st), Color("ff4dd2"))
			elif sc and SpellRules.can_fire(state, ME, st):
				sc.set_glow(true, Color("ffd23a"))
		for m in state.players[ME].monsters():
			var c := board.card_for(m)
			if c and (state.can_attack(ME, m) or state.can_flip_summon(ME, m) or state.can_change_position(ME, m)):
				c.set_glow(true, UITheme.ACCENT)


func _clear_glows() -> void:
	for p in 2:
		for m in state.players[p].monsters():
			var c := board.card_for(m)
			if c:
				c.set_glow(false)


func _on_phase_button(action: String) -> void:
	if not _my_turn():
		return
	_cancel_mode()
	if action == "battle":
		if state.phase == DuelState.Phase.MAIN1:
			await _act("enter_battle", [])
			await _window(AI, "battle_start", null, "")
		elif state.phase == DuelState.Phase.BATTLE:
			await _act("enter_main2", [])
			await _window(AI, "phase", null, "")
	elif action == "end":
		_turn_finished.emit()


func _on_hand_card_pressed(inst, at: Vector2) -> void:
	if not _my_turn() or mode != "":
		return
	_menu_card = inst
	hud.inspect(inst)
	hud.focus_hand_card(inst)
	at = hud.hand_card_anchor(inst)
	if inst.is_monster():
		var can := state.can_normal_summon(ME, inst)
		var need := state.tributes_needed(inst)
		var suffix := "" if need == 0 else " (%d tribute%s)" % [need, "" if need == 1 else "s"]
		var opts := [["summon", "Summon" + suffix, can], ["set", "Set", can]]
		if inst.cname() == "Cyber Dragon":
			opts.push_front(["special_hand", "Special Summon", state.can_special_from_hand(ME, inst)])
		hud.show_actions(at, opts)
	elif inst.is_trap():
		hud.show_actions(at, [["set_st", "Set", state.can_set_st(ME, inst)]])
	else:
		hud.show_actions(at, [["activate", "Activate", state.can_activate(ME, inst)], ["set_st", "Set", state.can_set_st(ME, inst)]])


func _on_action(action: String) -> void:
	var c = _menu_card
	_menu_card = null
	if c == null or not _my_turn():
		return
	if action.begins_with("fuse:"):
		var uid := int(action.substr(5))
		for x in state.players[ME].extra:
			if x.uid == uid:
				await _activate_flow(ME, c, x)
				return
		return
	match action:
		"summon", "set":
			var need := state.tributes_needed(c)
			if need == 0:
				await _act("normal_summon", [ME, c, [], action == "set"], false)
				await _after_summon(ME)
			else:
				mode = "tribute"
				_pending_card = c
				_pending_set = action == "set"
				_tributes = []
				_refresh_tribute()
		"activate":
			if c.data.get("effect", "") == "fusion":
				var opts := state.fusion_targets(ME, c)
				if opts.size() > 1:
					_menu_card = c
					var list := []
					for o in opts:
						list.append(["fuse:%d" % o["card"].uid, o["card"].data["name"], true])
					hud.show_actions(get_viewport().get_mouse_position(), list)
					return
			await _activate_flow(ME, c, null)
		"fire":
			await _run(func(st, a): return SpellRules.fire(st, ME, a[0]), [c])
		"attack":
			if state.phase == DuelState.Phase.MAIN1:
				await _act("enter_battle", [])
				await _window(AI, "battle_start", null, "")
			if state.can_attack(ME, c):
				_start_attack(c)
		"flip":
			await _act("flip_summon", [ME, c], false)
			await _after_summon(ME)
		"ignite":
			await _act("ignite", [ME, c], false)
			await _after_summon(ME)
		"set_st":
			await _act("set_st", [ME, c])
		"special_hand":
			await _act("special_from_hand", [ME, c], false)
			await _after_summon(ME)
		"position":
			await _act("change_position", [ME, c])


func _refresh_tribute() -> void:
	var need := state.tributes_needed(_pending_card)
	hud.show_prompt("Choose %d monster%s to tribute" % [need - _tributes.size(), "" if need - _tributes.size() == 1 else "s"])
	_clear_glows()
	for m in state.tributable(ME):
		var c := board.card_for(m)
		if c:
			c.set_glow(true, UITheme.GOLD if _tributes.has(m) else UITheme.ACCENT)


func _on_board_card_clicked(card: Card3D) -> void:
	if not _my_turn() or hud.actions_visible():
		hud.hide_actions()
		return
	var inst = card.inst
	if inst == null:
		return
	var mine: bool = state.players[ME].field.has(inst)
	var theirs: bool = state.players[AI].field.has(inst)
	if mode == "materials":
		if mine:
			_toggle_material(inst)
		return
	if mode == "" and state.players[ME].spells.has(inst):
		# Your own Spell & Trap cards: flip a Set one, or fire a charged one.
		var st_opts := []
		if not inst.face_up and state.can_activate(ME, inst):
			st_opts.append(["activate", "Activate", true])
		if SpellRules.can_fire(state, ME, inst):
			st_opts.append(["fire", "Fire (%d damage)" % (inst.counter * int(SpellRules.spec(inst)["cannon"])), true])
		if not st_opts.is_empty():
			_menu_card = inst
			hud.show_actions(board.screen_pos(inst) + Vector2(60, 0), st_opts)
		return
	if mode == "tribute":
		if mine and state.tributable(ME).has(inst):
			if _tributes.has(inst):
				_tributes.erase(inst)
			else:
				_tributes.append(inst)
			if _tributes.size() == state.tributes_needed(_pending_card):
				var c = _pending_card
				var t := _tributes.duplicate()
				var s := _pending_set
				_cancel_mode()
				await _act("normal_summon", [ME, c, t, s], false)
				await _after_summon(ME)
			else:
				_refresh_tribute()
		return
	if mode == "attack":
		if theirs:
			var a = _attacker
			_cancel_mode()
			await _do_attack(ME, a, inst)
		elif mine and state.can_attack(ME, inst):
			_start_attack(inst)
		return
	if not mine:
		return
	if state.phase == DuelState.Phase.BATTLE and state.can_attack(ME, inst):
		_start_attack(inst)
		return
	var opts := []
	if state.phase == DuelState.Phase.MAIN1 and state.can_enter_battle() and inst.face_up and inst.attack_pos and inst.attacked_turn != state.turn:
		opts.append(["attack", "Attack", true])
	if state.can_ignite(ME, inst):
		opts.append(["ignite", "Effect: " + str(EffectRunner.ignite_spec(inst).get("label", "Activate")), true])
	if state.can_flip_summon(ME, inst):
		opts.append(["flip", "Flip Summon", true])
	if state.can_change_position(ME, inst):
		opts.append(["position", "To Defense" if inst.attack_pos else "To Attack", true])
	if opts.is_empty():
		return
	_menu_card = inst
	hud.show_actions(board.screen_pos(inst) + Vector2(60, 0), opts)


func _on_extra_pressed() -> void:
	if not _my_turn():
		return
	_cancel_mode()
	var opts := []
	var has_poly := false
	for h in state.players[ME].hand:
		if h.data.get("effect", "") == "fusion":
			has_poly = true
	for x in state.players[ME].extra:
		var status := ""
		var ok := false
		match x.frame():
			"fusion":
				status = "Use Polymerization" if has_poly else "Needs Polymerization"
			"synchro":
				ok = state.can_extra_summon(ME, x)
				status = "Synchro Summon" if ok else "Tuner + %d levels" % x.level()
			"xyz":
				ok = state.can_extra_summon(ME, x)
				status = "Xyz Summon" if ok else "2 Level %d monsters" % x.level()
		opts.append([x, status, ok])
	hud.show_extra(opts)


var _extra_target = null
var _extra_sel: Array = []


## Pick materials yourself: tap monsters on your field, or press Auto.
func _on_extra_chosen(inst) -> void:
	if not _my_turn():
		return
	var options := state.extra_materials(ME, inst)
	if options.is_empty():
		return
	mode = "materials"
	_extra_target = inst
	_extra_sel = []
	_refresh_materials()


func _material_candidates() -> Array:
	var out := []
	for opt in state.extra_materials(ME, _extra_target):
		for m in opt:
			if not out.has(m):
				out.append(m)
	return out


func _refresh_materials() -> void:
	var what := "Synchro" if _extra_target.frame() == "synchro" else "Xyz"
	var hint := "a Tuner plus monsters adding up to Level %d" % _extra_target.level() if what == "Synchro" else "2 Level %d monsters" % _extra_target.level()
	hud.show_prompt("%s Summon %s: pick %s" % [what, _extra_target.data["name"], hint], true, "Auto-pick")
	_clear_glows()
	for m in _material_candidates():
		var c := board.card_for(m)
		if c:
			c.set_glow(true, Color("ffd23a") if _extra_sel.has(m) else UITheme.ACCENT)


func _toggle_material(inst) -> void:
	if not _material_candidates().has(inst):
		return
	if _extra_sel.has(inst):
		_extra_sel.erase(inst)
	else:
		_extra_sel.append(inst)
	Sfx.play("card", -6.0, 1.2)
	for opt in state.extra_materials(ME, _extra_target):
		if opt.size() == _extra_sel.size() and opt.all(func(m): return _extra_sel.has(m)):
			var target = _extra_target
			var mats := _extra_sel.duplicate()
			_cancel_mode()
			await _act("extra_summon", [ME, target, mats], false)
			await _after_summon(ME)
			return
	_refresh_materials()


## Declare, give the defender a chance to respond, then resolve.
func _do_attack(p: int, attacker, target) -> void:
	var ev: Array = await _act("declare_attack", [p, attacker, target], false)
	if ev.is_empty():
		return
	await _window(state.opponent(p), "attack", null, "%s attacks! Respond?" % attacker.data["name"])
	# Replay: the defender's monsters changed, so the attacker chooses again.
	var replays := 0
	while state.replay_needed() and replays < 3:
		replays += 1
		var opts: Array = state.attack_targets(p)
		var pick = null
		var go := true
		if p == AI or _autoplay:
			var again := DuelAI.next_attack(state, p, _level_for(p))
			go = not again.is_empty() and again["card"] == attacker
			pick = again.get("target") if go else null
		else:
			var labels := []
			for m in opts:
				labels.append("Attack %s" % (m.cname() if m.face_up else "the face-down monster"))
			if state.can_direct_attack_with(p, attacker):
				labels.append("Attack directly")
			labels.append("Stop the attack")
			var idx: int = await hud.ask_choice("Replay! Their monsters changed. %s:" % attacker.cname(), labels, attacker)
			go = idx < labels.size() - 1
			pick = opts[idx] if idx < opts.size() else null
		if not go:
			await _act("cancel_attack", [])
			return
		await _act("replay_attack", [pick], false)
	# Damage Step: only ATK / DEF changers and Counter Traps.
	if not state.pending_attack.is_empty() and not state.pending_attack["negated"]:
		await _window(p, "damage", null, "Damage Step. Change ATK or DEF?")
	await _act("resolve_attack", [])


## After a summon, the other player may respond (Trap Hole, Solemn Judgment and friends).
func _after_summon(p: int) -> void:
	var subj = state.last_summoned
	if subj == null or state.is_over():
		await _settle()
		return
	state.last_summoned = null
	await _window(state.opponent(p), "summon", subj, "%s was summoned. Respond?" % subj.data["name"])


## Activate a Spell/Trap with the full chain: target, the other player's response, then resolve.
func _activate_flow(who: int, c, target) -> void:
	var sp := SpellRules.spec(c)
	if target == null and who == ME and not _autoplay and not sp.has("legacy") and SpellRules._needs_target(sp):
		target = await _pick_target(who, c)
		if target == null:
			return
	_flow = true
	var ev: Array = await _act("chain_add", [who, c, target, "open", null], false)
	if ev.is_empty():
		_flow = false
		return
	await _window(state.opponent(who), "chain", null, "")
	_flow = false
	_refresh()
	await _after_summon(who)


func _pick_target(who: int, c):
	var cands := SpellRules.targets(state, who, c)
	if cands.is_empty():
		return null
	if cands.size() == 1 or who == AI or _autoplay:
		return SpellRules.auto_target(state, who, c) if (who == AI or _autoplay) else cands[0]
	var hidden := []
	for x in cands:
		if x.owner != who and not x.face_up:
			hidden.append(x)
	_flow = true
	var pick = await hud.ask_pick("Choose a target for %s" % c.cname(), cands, "Select", "Cancel", hidden)
	_flow = false
	return pick


## A response window. Players take turns adding to the chain until both pass, then it resolves.
## window: "attack" | "summon" | "chain" | "battle_start". `first` gets the first chance.
func _window(first: int, window: String, subject, prompt: String) -> void:
	var who := first
	var passes := 0
	var was_flow := _flow
	_flow = true
	if not state.pending_fx.is_empty():
		await _act("fx_to_chain", [], false)
	while passes < 2 and not state.is_over() and not _finished:
		var win := window if state.chain.is_empty() else "chain"
		var subj = subject if state.chain.is_empty() else state.chain.back()
		var opts := state.responses(who, win, subj)
		if win == "chain" and window in ["attack", "summon"] and str(state.chain.back()["spec"].get("k", "")) != "counter":
			# Cards made for the original trigger still fit while the chain builds.
			for o in state.responses(who, window, subject):
				if not opts.has(o) and not o.is_monster() and SpellRules.kind(o) != "counter":
					opts.append(o)
		var choice = null
		if not opts.is_empty():
			if who == AI or _autoplay:
				choice = DuelAI.choose_response(state, who, win, opts, _level_for(who))
				if choice != null:
					await _ai_wait(0.3)
			else:
				var text := prompt
				if win == "chain":
					text = "Chain to %s%s?" % [state.chain.back()["card"].cname(), "'s effect" if state.chain.back()["kind"] == "fx" else ""]
				elif window == "battle_start":
					text = "The Battle Phase begins. Respond?"
				choice = await hud.ask_response(text, opts)
		if choice != null:
			if choice.is_monster() or (choice.cname() == "Kuriboh" and state.players[who].hand.has(choice)):
				await _act("respond", [who, choice, subject], false)
			else:
				var target = null
				var sp := SpellRules.spec(choice)
				if not sp.has("legacy") and SpellRules._needs_target(sp):
					target = await _pick_target(who, choice)
					_flow = true
					if target == null:
						passes += 1
						who = state.opponent(who)
						continue
				await _act("chain_add", [who, choice, target, win, subj], false)
			passes = 0
		else:
			passes += 1
		who = state.opponent(who)
	if not state.chain.is_empty():
		await _act("chain_resolve", [], false)
	_flow = was_flow
	# Effects that triggered while that chain resolved start a chain of their own.
	if not state.pending_fx.is_empty() and not state.is_over() and not _finished:
		await _window(state.opponent(state.current), "chain", null, "")


func _start_attack(inst) -> void:
	mode = "attack"
	_attacker = inst
	_clear_glows()
	board.card_for(inst).set_glow(true, UITheme.GOLD)
	for t in state.attack_targets(ME):
		var c := board.card_for(t)
		if c:
			c.set_glow(true, UITheme.DANGER)
	board.start_aim(inst)
	if state.can_direct_attack(ME):
		hud.show_prompt("No monsters in the way. Attack directly!", true)
	elif state.can_direct_attack_with(ME, inst):
		hud.show_prompt("Tap a monster, or %s can attack directly!" % inst.data.get("name", ""), true, "Direct attack")
	else:
		hud.show_prompt("Tap a monster to attack with %s" % inst.data.get("name", ""), false)


func _on_direct_attack() -> void:
	if mode == "materials" and _my_turn():
		var target = _extra_target
		_cancel_mode()
		await _act("extra_summon", [ME, target, []], false)
		await _after_summon(ME)
		return
	if mode != "attack" or not _my_turn():
		return
	var a = _attacker
	_cancel_mode()
	await _do_attack(ME, a, null)


func _cancel_mode() -> void:
	board.stop_aim()
	mode = ""
	_pending_card = null
	_attacker = null
	_tributes = []
	hud.hide_prompt()
	hud.hide_actions()
	_refresh()


func _on_board_card_hovered(card: Card3D, inside: bool) -> void:
	if mode == "attack" and card.inst != null and state.players[AI].field.has(card.inst):
		board.set_aim_target(card if inside else null)
	if not inside or card.inst == null:
		return
	var inst = card.inst
	var hidden: bool = not inst.face_up and inst.owner == AI and state.players[AI].field.has(inst)
	if state.players[AI].hand.has(inst):
		hidden = true
	hud.inspect(inst, hidden)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_pause"):
		if mode != "" or hud.actions_visible():
			_cancel_mode()
		elif not hud.overlay_visible() and not _finished:
			hud.show_pause()
		elif hud.overlay_visible() and not _finished:
			hud.hide_overlay()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_cancel_mode()


func _on_pause_action(action: String) -> void:
	match action:
		"open":
			if not _finished and not hud.overlay_visible():
				_cancel_mode()
				hud.show_pause()
		"resume":
			hud.hide_overlay()
			_refresh()
		"settings":
			SettingsPanel.open(hud)
		"surrender":
			hud.hide_overlay()
			_surrendered = true
			state.winner = AI
			state.win_reason = "You surrendered."
			_turn_finished.emit()
			if state.current == AI or busy:
				_finish()
		"rematch":
			Router.go(Router.DUEL)
		"select":
			Router.menu_open = "select"
			Router.go(Router.MAIN_MENU)
		"story_continue":
			Router.story_result = "won" if _won else "lost"
			Router.go(Router.duel_config.get("return_to", Router.STORY))
		"menu":
			Router.go(Router.MAIN_MENU)


# ------------------------------------------------------------------ AI

func _ai_turn(who: int) -> void:
	await _ai_wait(0.6)
	var steps := 0
	while steps < 20 and not state.is_over() and not _finished:
		steps += 1
		var act := DuelAI.next_main_action(state, who, _level_for(who))
		if act.is_empty():
			break
		if act["do"] == "activate":
			var n0 := state.players[who].hand.size() + state.players[who].set_cards().size()
			await _activate_flow(who, act["card"], act.get("choice"))
			if state.players[who].hand.size() + state.players[who].set_cards().size() == n0:
				break
			await _ai_wait(0.35)
			continue
		var ev: Array = await _run(func(st, a): return DuelAI.apply(st, who, a[0]), [act], false)
		if ev.is_empty():
			break
		if act["do"] in ["summon", "extra", "special_hand", "flip"]:
			await _after_summon(who)
		await _settle()
		await _ai_wait(0.35)
	if state.can_enter_battle() and not state.is_over() and not _finished:
		var any_attack := false
		for m in state.players[who].monsters():
			if m.face_up and m.attack_pos and state.attacks_left(m) > 0:
				any_attack = true
		if any_attack:
			await _act("enter_battle", [])
			await _window(state.opponent(who), "battle_start", null, "")
			await _ai_wait(0.3)
			steps = 0
			while steps < 10 and not state.is_over() and not _finished:
				steps += 1
				var atk := DuelAI.next_attack(state, who, _level_for(who))
				if atk.is_empty():
					break
				await _do_attack(who, atk["card"], atk["target"])
				await _ai_wait(0.3)
			if not state.is_over() and not _finished:
				await _act("enter_main2", [])
				await _window(state.opponent(who), "phase", null, "Main Phase 2 begins. Activate a card?")
				steps = 0
				while steps < 10 and not state.is_over() and not _finished:
					steps += 1
					var act2 := DuelAI.next_main_action(state, who, _level_for(who))
					if act2.is_empty():
						break
					if act2["do"] == "activate":
						var n1 := state.players[who].hand.size() + state.players[who].set_cards().size()
						await _activate_flow(who, act2["card"], act2.get("choice"))
						if state.players[who].hand.size() + state.players[who].set_cards().size() == n1:
							break
						await _ai_wait(0.3)
						continue
					var ev2: Array = await _run(func(st, a): return DuelAI.apply(st, who, a[0]), [act2], false)
					if ev2.is_empty():
						break
					if act2["do"] in ["summon", "extra", "special_hand", "flip"]:
						await _after_summon(who)
					await _settle()
					await _ai_wait(0.3)
	await _ai_wait(0.3)


func _level_for(who: int) -> int:
	return _ai_level if who == AI else 1


func _ai_wait(sec: float) -> void:
	await get_tree().create_timer(Settings.t(sec)).timeout


func _run_ai(act: Dictionary, who: int) -> Array:
	match act["do"]:
		"activate":
			return state.activate(who, act["card"], act.get("choice"))
		"extra":
			return state.extra_summon(who, act["card"])
		"summon":
			return state.normal_summon(who, act["card"], act["tributes"], false)
		"set":
			return state.normal_summon(who, act["card"], act["tributes"], true)
		"flip":
			return state.flip_summon(who, act["card"])
		"position":
			return state.change_position(who, act["card"])
		"ignite":
			return state.ignite(who, act["card"])
	return []



func _demo_actions() -> void:
	await get_tree().create_timer(0.6).timeout
	for c in state.players[ME].hand:
		if c.is_monster():
			hud.inspect(c)
			_on_hand_card_pressed(c, Vector2.ZERO)
			return
