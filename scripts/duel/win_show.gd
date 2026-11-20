class_name WinShow
extends Node3D
## The other ways a duel ends without Life Points reaching zero (0.61.0), each with a short
## show of its own before the win screen. (Exodia has ExodiaShow.)
##   "destiny_board": a spirit flame rises over each of the five cards and lets go a letter;
##                    the letters gather into the word and a wave of shadow rolls over the loser.
##   "countdown":     a clock face on the floor, its hand sweeping through the twenty turns; on
##                    the last one the bell tolls and the field burns.
##   "deckout":       the loser's Deck is empty: the place where it stood flickers and goes dark.
##   "card:<id>":     any other card that wins the duel by its own effect stands over the field.
## The same plays whoever wins. Esc, Enter, Space or a controller button skips it (not a mouse click). Drawn with light: no models.

var _skip := false
var _born := Time.get_ticks_msec()
var _done := false
var _board
var _hud
var _keep: Array = []


static func play(_scene: Node, board, hud, winner: int, kind: String) -> void:
	var show := WinShow.new()
	show._board = board
	show._hud = hud
	board.add_child(show)
	if kind == "destiny_board":
		await show._destiny(winner)
	elif kind == "countdown":
		await show._countdown(winner)
	elif kind == "deckout":
		await show._deckout(winner)
	elif kind.begins_with("card:"):
		await show._card(winner, int(kind.substr(5)))
	show._end()
	if is_instance_valid(show):
		show.queue_free()


func _unhandled_input(e: InputEvent) -> void:
	if _done:
		return
	# (0.63.1) Only a press that means "skip" skips it: Esc, Enter, Space or a controller button, and not
	# in its first second. A mouse click or the mouse wheel used to count too, so a click meant for the
	# duel (or scrolling a card's text) cut the show off in the middle and the ending started over it.
	if Time.get_ticks_msec() - _born < 1000:
		return
	var key_skip: bool = e is InputEventKey and e.pressed and not e.echo and (e as InputEventKey).keycode in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]
	if key_skip or (e is InputEventJoypadButton and e.pressed):
		_skip = true
		get_viewport().set_input_as_handled()


func _w(sec: float) -> bool:
	var left := Settings.t(sec)
	while left > 0.0 and not _skip:
		await get_tree().process_frame
		left -= get_process_delta_time()
	return _skip


func _end() -> void:
	if _done:
		return
	_done = true
	Music.set_boost(0.0)
	if is_instance_valid(_hud) and "_hand_root" in _hud and _hud._hand_root != null:
		_hud._hand_root.visible = true
	for k in _keep:
		if k != null and is_instance_valid(k):
			if k is MeshInstance3D:
				DuelFx.fade(k, 0.25)
			else:
				k.queue_free()
	if is_instance_valid(_board):
		_board.cam_release(0.5)


func _open(dim: float) -> void:
	Music.set_boost(-20.0)
	if "_hand_root" in _hud and _hud._hand_root != null:
		_hud._hand_root.visible = false      # (your hand stays out of the picture while it plays)
	_board._dim_field(dim)
	ScreenFx.letterbox(_hud, Settings.t(dim - 0.6))


func _letter(text: String, at: Vector3, color: Color, size := 260) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = UITheme.title_font()
	l.font_size = size
	l.pixel_size = 0.004
	l.outline_size = 34
	l.outline_modulate = Color(color.darkened(0.7), 0.95)
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 4
	l.position = at
	add_child(l)
	return l


# ---------------------------------------------------------------- Destiny Board

func _destiny(winner: int) -> void:
	var board = _board
	var lz := -1.0 if winner == 0 else 1.0
	var violet := Color("b98cff")
	var deep := Color("4a12a0")
	var pale := Color("efe0ff")
	_open(6.4)
	Sfx.play("el_dark_up", -4.0, 0.6)
	var row_z: float = board.spell_zone_pos(winner, 2).z
	board.cam_shot(Vector3(0.0, 4.9, row_z * 0.4 + 7.0), Vector3(0, 0.9, row_z * 0.75), 0.6)
	var word := "FINAL"
	var letters: Array = []
	# A flame over each of the five cards, and a letter out of each.
	for i in 5:
		var spot: Vector3 = board.spell_zone_pos(winner, i)
		ElementFx.puff(board, spot + Vector3(0, 0.55, 0), 4, violet, deep, 1.3, 0.9, 0.3)
		ElementFx.decal(board, spot, 2, violet, deep, 1.4, 1.2)
		DuelFx.rect(board, Vector3(spot.x, 0.03, spot.z), violet, 1.0, 1.5, 0.5, false, 1.9, 0.7)
		var l := _letter(word[i], spot + Vector3(0, 0.3, 0), pale)
		l.scale = Vector3.ONE * 0.2
		l.modulate.a = 0.0
		letters.append(l)
		var tw := create_tween().set_parallel()
		tw.tween_property(l, "position:y", 1.3, Settings.t(0.5)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(l, "scale", Vector3.ONE * 0.75, Settings.t(0.4)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(l, "modulate:a", 1.0, Settings.t(0.2))
		Sfx.play("gong", -8.0, 0.55 + i * 0.06)
		Sfx.play("el_dark", -12.0, 0.8 + i * 0.08)
		board.shake(0.15)
		if await _w(0.34):
			return
	if await _w(0.3):
		return
	# They gather over the middle of the field, on the board they were written on.
	var mid := Vector3(0, 2.3, 0)
	var seal: MeshInstance3D = DuelFx.glyph(board, Vector3(0, 0.02, 0), violet, 2.3, 6.0, {"rings": 2, "ticks": 26, "star": 0, "turn": -2.0, "energy": 1.5, "keep": true})
	_keep.append(seal)
	DuelFx.spiral(board, Vector3(0, 0.03, 0), violet, deep, 2.0, 3.6, {"arms": 2, "twist": 4.0, "speed": 2.5, "energy": 1.2})
	for i in 5:
		var l2: Label3D = letters[i]
		var tw2 := create_tween().set_parallel()
		tw2.tween_property(l2, "position", mid + Vector3((i - 2) * 1.05, 0, 0), Settings.t(0.55)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw2.tween_property(l2, "scale", Vector3.ONE * 1.25, Settings.t(0.55))
	board.cam_shot(Vector3(0.0, 2.5, 5.9), Vector3(0, 2.0, 0), 0.6)
	Sfx.play("whoosh", -6.0, 0.6)
	if await _w(0.7):
		return
	# The word is read out, letter by letter.
	for i in 5:
		var l3: Label3D = letters[i]
		var at3: Vector3 = l3.position
		DuelFx.glow(board, at3, violet, 1.6, 0.35, 0.6, 1.6, true)
		DuelFx.ring(board, Vector3(at3.x, 0.03, 0), violet, 0.2, 0.9, 0.4, 0.05, 0.0, 1.7)
		var tw3 := create_tween()
		tw3.tween_property(l3, "scale", Vector3.ONE * 1.6, Settings.t(0.08))
		tw3.tween_property(l3, "scale", Vector3.ONE * 1.25, Settings.t(0.16))
		Sfx.play("chain", -6.0, 0.6 + i * 0.1)
		if await _w(0.15):
			return
	board.shake(0.7)
	board.cam_punch(3.5)
	Sfx.play("gong", -2.0, 0.45)
	_hud.cut_in(winner, "FINAL", Loc.t("The message is complete"), violet, 0.8, true)
	if await _w(1.0):
		return
	# The shadow rolls over the loser.
	var far := Vector3(0, 0.05, lz * 8.5)
	ElementFx.ribbon(board, Vector3(0, 0.05, 0), far, 4, violet, deep, 9.0, 0.45, {"flat": true, "hold": 0.6, "fade": 0.5})
	ElementFx.ribbon(board, mid, Vector3(0, 1.2, lz * 8.5), 4, violet, deep, 3.2, 0.4, {"hold": 0.5, "fade": 0.4})
	ElementFx.decal(board, Vector3(0, 0, lz * 5.6), 2, violet, deep, 6.0, 1.6)
	for i in 4:
		ElementFx.puff(board, Vector3((i - 1.5) * 1.3, 1.0, lz * 4.5), 4, violet, deep, 2.6, 1.0, 0.6, 0.15 + i * 0.07)
	Sfx.play("el_dark_hit", 0.0, 0.7)
	board.shake(1.1)
	board.house(0.9, violet, far, 1.0)
	board.duelist_body(1 - winner, "hurt", 2.0)
	if await _w(0.45):
		return
	ScreenFx.flash(_hud, Color(0.16, 0.05, 0.3), 1.0, 0.92)
	for l4 in letters:
		var tw4 := create_tween().set_parallel()
		tw4.tween_property(l4, "modulate:a", 0.0, Settings.t(0.6))
		tw4.tween_property(l4, "position:y", (l4 as Label3D).position.y + 0.6, Settings.t(0.6))
	await _w(0.9)


# ---------------------------------------------------------------- Final Countdown

func _countdown(winner: int) -> void:
	var board = _board
	var lz := -1.0 if winner == 0 else 1.0
	var amber := Color("ffb03a")
	var red := Color("ff3a1e")
	var hot := Color("fff0b0")
	_open(6.2)
	board.cam_shot(Vector3(0.0, 7.8, 3.4), Vector3(0, 0, -0.2), 0.6)
	Sfx.play("el_earth_up", -6.0, 0.7)
	var face: MeshInstance3D = DuelFx.glyph(board, Vector3(0, 0.02, 0), amber, 2.4, 6.0, {"rings": 2, "ticks": 20, "star": 0, "turn": 0.0, "energy": 1.6, "keep": true})
	_keep.append(face)
	# The hand of the clock.
	var hand := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.07, 0.02, 1.9)
	hand.mesh = bm
	hand.material_override = StrikeFx._add_mat(hot, 0.95)
	hand.position = Vector3(0, 0, -0.95)
	var pivot := Node3D.new()
	pivot.position = Vector3(0, 0.07, 0)
	add_child(pivot)
	pivot.add_child(hand)
	var count := _letter("1", Vector3(0, 1.5, 0.3), hot, 300)
	if await _w(0.5):
		return
	# Twenty turns go by, the last ones slower.
	for i in 20:
		var n := i + 1
		pivot.rotation.y = -TAU * float(n) / 20.0
		count.text = str(n)
		var tip := Vector3(sin(TAU * n / 20.0) * 2.05, 0.03, -cos(TAU * n / 20.0) * 2.05)
		DuelFx.glow(board, tip + Vector3(0, 0.1, 0), red if n >= 18 else amber, 0.7, 0.25, 0.0, 1.8)
		Sfx.play("blip", -6.0 + n * 0.25, 0.7 + n * 0.035)
		if n >= 18:
			count.modulate = red.lightened(0.3)
			DuelFx.ring(board, Vector3(0, 0.03, 0), red, 2.4, 0.4, 0.3, 0.05, 0.0, 1.8)
			Sfx.play("gong", -6.0, 0.5)
			board.shake(0.3)
		if await _w(0.07 if n < 17 else 0.32):
			return
	# The last toll.
	count.scale = Vector3.ONE * 1.5
	board.shake(0.9)
	board.cam_punch(4.0)
	Sfx.play("gong", 0.0, 0.4)
	_hud.cut_in(winner, "20", Loc.t("The countdown is over"), red, 0.8, true)
	if await _w(1.0):
		return
	board.cam_shot(Vector3(2.4 * -lz, 3.0, -lz * 6.4), Vector3(0, 0.9, lz * 2.0), 0.4)
	ElementFx.twister(board, Vector3.ZERO, hot, amber, 0.8, 1.4, 5.0, 1.2, 0.0, 1.2, 1.4)
	ElementFx.decal(board, Vector3.ZERO, 0, amber, red, 5.5, 2.2)
	for i in 3:
		DuelFx.ring(board, Vector3(0, 0.03, 0), amber.lerp(red, i * 0.4), 0.4, 3.0 + i * 1.4, 0.7, 0.06, i * 0.08, 1.8)
	ElementFx.ribbon(board, Vector3(0, 0.05, 0), Vector3(0, 0.05, lz * 8.5), 0, amber, red, 7.0, 0.35, {"flat": true, "hold": 0.6, "fade": 0.5})
	ElementFx.ribbon(board, Vector3(0, 1.2, 0), Vector3(0, 1.2, lz * 8.5), 0, amber, red, 3.0, 0.3, {"hold": 0.5, "fade": 0.4})
	for i in 5:
		ElementFx.puff(board, Vector3((i - 2) * 1.2, 0.9, lz * (2.0 + (i % 2) * 1.5)), 0, amber, red, 2.4, 0.9, 0.5, 0.1 + i * 0.06, 1.2)
	Sfx.play("el_fire_hit", 2.0, 0.6)
	Sfx.play("el_thunder_hit", -2.0, 0.6)
	board.shake(1.3)
	board.house(1.0, amber, Vector3(0, 0, lz * 4.0), 1.0)
	board.duelist_body(1 - winner, "hurt", 2.0)
	Pad.rumble(0.8, 1.0, 0.7)
	if await _w(0.35):
		return
	var vs: Vector2 = _hud.get_viewport_rect().size
	ScreenFx.flash(_hud, Color(1.0, 0.8, 0.5), 0.8, 0.95)
	ScreenFx.shatter(_hud, vs * 0.5, 1.0)
	var tw := create_tween().set_parallel()
	tw.tween_property(count, "modulate:a", 0.0, Settings.t(0.4))
	tw.tween_property(pivot, "scale", Vector3(0.01, 1, 0.01), Settings.t(0.4))
	await _w(0.9)


# ---------------------------------------------------------------- no cards left

func _deckout(winner: int) -> void:
	var board = _board
	var loser := 1 - winner
	var cold := Color("8fb4e0")
	var grey := Color("5a6a8a")
	var dp: Vector3 = board.deck_pos(loser)
	var f := Vector3(dp.x, 0.03, dp.z)
	_open(4.2)
	board.cam_shot(Vector3(dp.x * 0.55, 2.3, dp.z + 3.6), f + Vector3(0, 0.2, 0), 0.6)
	Sfx.play("el_wind", -8.0, 0.6)
	if await _w(0.6):
		return
	# The place where the Deck stood: its outline closes in on nothing, three times.
	for i in 3:
		DuelFx.rect(board, f, cold, 1.9, 1.0, 0.36, false, 1.8, 0.0)
		Sfx.play("card", -6.0, 0.6 - i * 0.08)
		if i == 2:
			# A last card that is not there: it rises as an outline and blows away as dust.
			DuelFx.rect(board, f + Vector3(0, 0.5, 0), Color.WHITE, 1.0, 1.05, 0.5, false, 1.5, 0.35)
			DuelFx.sparks(board, f + Vector3(0, 0.6, 0), cold, 30, 2.2, 0.2, 1.0, -1.5, 0.05)
			ElementFx.puff(board, f + Vector3(0, 0.6, 0), 3, cold.darkened(0.2), grey.darkened(0.4), 1.5, 1.0, 0.4, 0.0, 1.7)
		if await _w(0.4):
			return
	DuelFx.ring(board, f, cold, 1.6, 0.2, 0.6, 0.05, 0.0, 1.6)
	ElementFx.decal(board, f, 2, cold, grey, 2.4, 1.6)
	board.shake(0.4)
	Sfx.play("negate", -4.0, 0.7)
	_hud.cut_in(loser, Loc.t("NO CARDS LEFT"), Loc.t("The Deck is empty"), cold, 0.8, true)
	board.duelist_body(loser, "hurt", 1.2)
	if await _w(1.2):
		return
	ScreenFx.flash(_hud, Color(0.04, 0.07, 0.14), 0.8, 0.85)
	await _w(0.6)


# ---------------------------------------------------------------- a card that wins by itself

func _card(winner: int, id: int) -> void:
	var board = _board
	var gold := Color("ffd76a")
	var amber := Color("ff9a1a")
	_open(5.0)
	board.cam_shot(Vector3(0.6, 1.1, 5.7), Vector3(0, 2.3, 0), 0.6)
	var seal: MeshInstance3D = DuelFx.glyph(board, Vector3(0, 0.02, 0), gold, 2.2, 5.0, {"rings": 2, "ticks": 32, "star": 4, "turn": 4.0, "energy": 1.5, "keep": true})
	_keep.append(seal)
	Sfx.play("el_light_up", -4.0, 0.7)
	if await _w(0.45):
		return
	var c := Card3D.new()
	c.setup(id)
	c.set_pickable(false)
	add_child(c)
	var stand: Basis = Basis(Vector3.RIGHT, PI * 0.5) * board.table_basis(0, true, true)
	c.transform = Transform3D(stand, Vector3(0, 0.3, 0))
	c.scale = Vector3.ONE * 0.4
	var tw := create_tween().set_parallel()
	tw.tween_property(c, "position:y", 2.5, Settings.t(0.6)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "scale", Vector3.ONE * 2.6, Settings.t(0.6)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_method(c.flash, 2.5, 0.0, Settings.t(0.8))
	DuelFx.pillar(board, Vector3(0, 0, -0.6), amber, 1.4, 9.0, 3.2, 0.0, 0.6)
	DuelFx.embers(board, Vector3(0, 0.03, 0), gold, 1.4, 50, 3.0, 4.0, 0.07)
	if await _w(0.65):
		return
	DuelFx.rays(board, Vector3(0, 2.5, -0.4), gold, 5.0, 0.8, 34, false, 1.6)
	DuelFx.glow(board, Vector3(0, 2.5, -0.5), amber, 7.0, 2.6, 0.0, 0.5)
	board.shake(0.8)
	board.cam_punch(3.5)
	Sfx.play("gong", -2.0, 0.5)
	Sfx.play("impact", -2.0, 0.6)
	var nm := str(CardData.get_card(id).get("name", ""))
	_hud.cut_in(winner, nm.to_upper(), Loc.t("Special victory"), gold, 0.9, true)
	board.cam_drift(Vector3(-0.6, 1.25, 5.9), Settings.t(2.4))
	if await _w(1.5):
		return
	for i in 3:
		DuelFx.ring(board, Vector3(0, 0.03, 0), gold.lerp(amber, i * 0.4), 0.4, 3.0 + i * 1.4, 0.7, 0.06, i * 0.08, 1.8)
	ScreenFx.flash(_hud, Color(1.0, 0.95, 0.8), 0.9, 0.9)
	Sfx.play("el_light_hit", 0.0, 0.7)
	board.house(0.9, gold, Vector3.ZERO, 1.0)
	var tw2 := create_tween().set_parallel()
	tw2.tween_method(c.set_alpha, 1.0, 0.0, Settings.t(0.6))
	tw2.tween_property(c, "position:y", 3.3, Settings.t(0.6))
	await _w(0.8)
