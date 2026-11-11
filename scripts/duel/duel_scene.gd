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
var _autoplay := "--autoplay" in OS.get_cmdline_user_args()

signal _turn_finished


func _ready() -> void:
	get_viewport().physics_object_picking = true
	board = DuelBoard.new()
	add_child(board)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = DuelHUD.new()
	hud.theme = UITheme.build()
	layer.add_child(hud)
	board.card_clicked.connect(_on_board_card_clicked)
	board.card_hovered.connect(_on_board_card_hovered)
	hud.hand_card_pressed.connect(_on_hand_card_pressed)
	hud.hand_card_hovered.connect(func(inst): hud.inspect(inst))
	hud.phase_button.connect(_on_phase_button)
	hud.action_chosen.connect(_on_action)
	hud.cancel_pressed.connect(_cancel_mode)
	hud.direct_attack_pressed.connect(_on_direct_attack)
	hud.pause_action.connect(_on_pause_action)
	_start()


func _start() -> void:
	var cfg: Dictionary = Router.duel_config
	var my_deck: String = cfg.get("player_deck", "yugi")
	var opp_deck: String = cfg.get("opponent_deck", "kaiba")
	var opp_name: String = CardData.DECKS[opp_deck]["duelist"]
	hud.set_names("You", opp_name)
	var first := randi() % 2
	var events := state.setup(CardData.deck_list(my_deck), CardData.deck_list(opp_deck), "You", opp_name, first)
	for p in 2:
		board.set_deck_count(p, state.players[p].deck.size() + 5)
	_update_counts()
	hud.set_phase_buttons("", false, false)
	await get_tree().create_timer(0.6).timeout
	await hud.banner("DUEL!", UITheme.ACCENT)
	await _play(events)
	await hud.banner("You go first" if first == ME else "%s goes first" % opp_name, UITheme.TEXT)
	_loop()


func _loop() -> void:
	while not state.is_over():
		await _play(state.begin_turn())
		if state.is_over():
			break
		if state.current == AI or _autoplay:
			await _ai_turn(state.current)
		else:
			_turn_done = false
			_refresh()
			await _turn_finished
		if state.is_over():
			break
		_cancel_mode()
		await _play(state.end_turn())
	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	_cancel_mode()
	hud.set_phase_buttons("", false, false)
	hud.set_playable([])
	await get_tree().create_timer(0.6).timeout
	var won := state.winner == ME
	hud.show_result(won, "You surrendered." if _surrendered else state.win_reason)


# ------------------------------------------------------------------ events

func _play(events: Array) -> void:
	busy = true
	_refresh()
	for ev in events:
		await _play_event(ev)
	busy = false
	_update_counts()
	_refresh()


func _play_event(ev: Dictionary) -> void:
	var p: int = ev.get("player", 0)
	match ev["type"]:
		"turn":
			var mine := p == ME
			await hud.banner("YOUR TURN" if mine else "%s'S TURN" % state.players[AI].name.to_upper(),
					UITheme.ACCENT if mine else Color("a08cff"))
		"phase":
			hud.set_phase(ev["phase"], state.current == ME)
		"draw":
			_update_counts()
			await board.anim_draw(p, ev["card"], ev["deck"])
			if p == ME:
				hud.add_hand_card(ev["card"])
		"summon", "set":
			if p == ME:
				hud.remove_hand_card(ev["card"])
			await board.anim_summon(p, ev["card"], ev["zone"], ev["type"] == "set")
		"tribute":
			await board.anim_tribute(ev["card"])
		"flip", "reveal":
			await board.anim_flip(p, ev["card"], ev["zone"])
		"position":
			await board.anim_position(p, ev["card"], ev["zone"])
		"activate":
			if p == ME:
				hud.remove_hand_card(ev["card"])
			hud.inspect(ev["card"])
			await board.anim_activate(p, ev["card"])
		"spell_done":
			await board.anim_spell_done(ev["card"])
		"attack":
			await board.anim_attack(p, ev["card"], ev["target"])
		"destroy":
			await board.anim_destroy(ev["card"])
		"discard":
			if p == ME:
				hud.remove_hand_card(ev["card"])
			await board.anim_discard(p, ev["card"])
		"lp":
			hud.set_lp(p, ev["lp"], ev["delta"])
			if ev["delta"] < 0:
				board.shake(0.5)
			await get_tree().create_timer(Settings.t(0.45)).timeout
	_update_counts()


func _update_counts() -> void:
	for p in 2:
		var ps := state.players[p]
		hud.set_counts(p, ps.deck.size(), ps.hand.size(), ps.gy.size())


# ------------------------------------------------------------------ player input

func _my_turn() -> bool:
	return state.current == ME and not busy and not state.is_over() and not hud.overlay_visible()


func _refresh() -> void:
	if not _my_turn():
		hud.set_phase_buttons("", false, false)
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
	var playable := []
	for c in state.players[ME].hand:
		if state.can_normal_summon(ME, c) or state.can_activate(ME, c):
			playable.append(c)
	hud.set_playable(playable)
	_clear_glows()
	if mode == "":
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
			await _play(state.enter_battle())
		elif state.phase == DuelState.Phase.BATTLE:
			await _play(state.enter_main2())
	elif action == "end":
		_turn_finished.emit()


func _on_hand_card_pressed(inst, at: Vector2) -> void:
	if not _my_turn() or mode != "":
		return
	_menu_card = inst
	hud.inspect(inst)
	if inst.is_monster():
		var can := state.can_normal_summon(ME, inst)
		var need := state.tributes_needed(inst)
		var suffix := "" if need == 0 else " (%d tribute%s)" % [need, "" if need == 1 else "s"]
		hud.show_actions(at, [["summon", "Summon" + suffix, can], ["set", "Set", can]])
	else:
		hud.show_actions(at, [["activate", "Activate", state.can_activate(ME, inst)]])


func _on_action(action: String) -> void:
	var c = _menu_card
	_menu_card = null
	if c == null or not _my_turn():
		return
	match action:
		"summon", "set":
			var need := state.tributes_needed(c)
			if need == 0:
				await _play(state.normal_summon(ME, c, [], action == "set"))
			else:
				mode = "tribute"
				_pending_card = c
				_pending_set = action == "set"
				_tributes = []
				_refresh_tribute()
		"activate":
			await _play(state.activate(ME, c))
		"flip":
			await _play(state.flip_summon(ME, c))
		"position":
			await _play(state.change_position(ME, c))


func _refresh_tribute() -> void:
	var need := state.tributes_needed(_pending_card)
	hud.show_prompt("Choose %d monster%s to tribute" % [need - _tributes.size(), "" if need - _tributes.size() == 1 else "s"])
	_clear_glows()
	for m in state.players[ME].monsters():
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
	if mode == "tribute":
		if mine:
			if _tributes.has(inst):
				_tributes.erase(inst)
			else:
				_tributes.append(inst)
			if _tributes.size() == state.tributes_needed(_pending_card):
				var c = _pending_card
				var t := _tributes.duplicate()
				var s := _pending_set
				_cancel_mode()
				await _play(state.normal_summon(ME, c, t, s))
			else:
				_refresh_tribute()
		return
	if mode == "attack":
		if theirs:
			var a = _attacker
			_cancel_mode()
			await _play(state.attack(ME, a, inst))
		elif mine and state.can_attack(ME, inst):
			_start_attack(inst)
		return
	if not mine:
		return
	if state.phase == DuelState.Phase.BATTLE and state.can_attack(ME, inst):
		_start_attack(inst)
		return
	var opts := []
	if state.can_flip_summon(ME, inst):
		opts.append(["flip", "Flip Summon", true])
	if state.can_change_position(ME, inst):
		opts.append(["position", "To Defense" if inst.attack_pos else "To Attack", true])
	if opts.is_empty():
		return
	_menu_card = inst
	hud.show_actions(get_viewport().get_mouse_position(), opts)


func _start_attack(inst) -> void:
	mode = "attack"
	_attacker = inst
	_clear_glows()
	board.card_for(inst).set_glow(true, UITheme.GOLD)
	for t in state.attack_targets(ME):
		var c := board.card_for(t)
		if c:
			c.set_glow(true, UITheme.DANGER)
	hud.show_prompt("Choose a target for %s" % inst.data.get("name", ""), state.can_direct_attack(ME))


func _on_direct_attack() -> void:
	if mode != "attack" or not _my_turn():
		return
	var a = _attacker
	_cancel_mode()
	await _play(state.attack(ME, a, null))


func _cancel_mode() -> void:
	mode = ""
	_pending_card = null
	_attacker = null
	_tributes = []
	hud.hide_prompt()
	hud.hide_actions()
	_refresh()


func _on_board_card_hovered(card: Card3D, inside: bool) -> void:
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
		"menu":
			Router.go(Router.MAIN_MENU)


# ------------------------------------------------------------------ AI

func _ai_turn(who: int) -> void:
	await _ai_wait(0.6)
	var steps := 0
	while steps < 20 and not state.is_over() and not _finished:
		steps += 1
		var act := DuelAI.next_main_action(state, who)
		if act.is_empty():
			break
		var ev := _run_ai(act, who)
		if ev.is_empty():
			break
		await _play(ev)
		await _ai_wait(0.35)
	if state.can_enter_battle() and not state.is_over() and not _finished:
		var any_attack := not DuelAI.next_attack(state, who).is_empty()
		if any_attack:
			await _play(state.enter_battle())
			await _ai_wait(0.3)
			steps = 0
			while steps < 10 and not state.is_over() and not _finished:
				steps += 1
				var atk := DuelAI.next_attack(state, who)
				if atk.is_empty():
					break
				await _play(state.attack(who, atk["card"], atk["target"]))
				await _ai_wait(0.3)
	await _ai_wait(0.3)


func _ai_wait(sec: float) -> void:
	await get_tree().create_timer(Settings.t(sec)).timeout


func _run_ai(act: Dictionary, who: int) -> Array:
	match act["do"]:
		"activate":
			return state.activate(who, act["card"])
		"summon":
			return state.normal_summon(who, act["card"], act["tributes"], false)
		"set":
			return state.normal_summon(who, act["card"], act["tributes"], true)
		"flip":
			return state.flip_summon(who, act["card"])
		"position":
			return state.change_position(who, act["card"])
	return []
