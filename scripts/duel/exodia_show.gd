class_name ExodiaShow
extends Node3D
## Winning with the five pieces of Exodia (0.60.0). Before, the duel just ended.
## The field goes dark; the five cards fly out of the hand one by one and land, each with a
## gong, on the points of a gold seal on the floor, chained to one another; the chains snap, the
## cards rise and stand together as one towering figure (head, two arms, two legs: the cards
## themselves, from the card folder); its name crosses the screen; it gathers light and lets go
## a beam down the whole field at the loser, and the picture goes white and breaks.
## The same plays when the opponent does it to you. Any key or button skips it.
## Our own staging, drawn with light: no models.

const HEAD := 33396948
const R_ARM := 70903634
const L_ARM := 7902349
const R_LEG := 8124921
const L_LEG := 44519536
const GOLD := Color("ffd76a")
const AMBER := Color("ff9a1a")
const PALE := Color("fff6d0")

var _skip := false
var _board
var _hud
var _cards: Array = []
var _chains: Array = []
var _done := false
var _elapsed := 0.0
var _keep: Array = []      # pieces on the board that do not free themselves


## Plays the whole thing and returns when it is over (or was skipped). `winner` is 0 or 1.
static func play(scene: Node, board, hud, winner: int) -> void:
	var show := ExodiaShow.new()
	show._board = board
	show._hud = hud
	board.add_child(show)
	await show._run(scene, winner)
	if is_instance_valid(show):
		show.queue_free()


func _unhandled_input(e: InputEvent) -> void:
	if _done:
		return
	if (e is InputEventKey or e is InputEventMouseButton or e is InputEventJoypadButton) and e.is_pressed():
		_skip = true
		get_viewport().set_input_as_handled()


## Waits, and says whether the player asked to skip meanwhile.
func _w(sec: float) -> bool:
	var left := Settings.t(sec)
	while left > 0.0 and not _skip:
		await get_tree().process_frame
		left -= get_process_delta_time()
		_elapsed += get_process_delta_time()
	return _skip


func _end() -> void:
	_done = true
	Music.set_boost(0.0)
	if is_instance_valid(_board):
		# (once the camera is back on your side of the table)
		var b = _board
		b.get_tree().create_timer(0.7).timeout.connect(func():
			if is_instance_valid(b):
				for oc in b._opp_hand:
					if is_instance_valid(oc):
						oc.visible = true)
	if OS.has_environment("FX_TAG"):
		print("EXODIA show: ", snappedf(_elapsed, 0.01), " s")
	if is_instance_valid(_hud) and "_hand_root" in _hud and _hud._hand_root != null:
		_hud._hand_root.visible = true
	for k in _keep + _chains:
		if k != null and is_instance_valid(k):
			DuelFx.fade(k, 0.25)
	if is_instance_valid(_board):
		_board.cam_release(0.5)


func _run(_scene: Node, winner: int) -> void:
	var board = _board
	var lz := -1.0 if winner == 0 else 1.0        # which end of the field the loser is at
	Music.set_boost(-22.0)
	# (the opponent's hand and your own stay out of the picture while it plays)
	for oc in board._opp_hand:
		if is_instance_valid(oc):
			oc.visible = false
	if "_hand_root" in _hud and _hud._hand_root != null:
		_hud._hand_root.visible = false
	board._dim_field(8.2)
	ScreenFx.letterbox(_hud, Settings.t(7.8))
	Sfx.play("el_dark_up", -4.0, 0.6)
	# ---- 1. the seal draws itself
	board.cam_shot(Vector3(0.0, 7.6, 3.4), Vector3(0, 0, -0.25), 0.6)
	var seal: MeshInstance3D = DuelFx.glyph(board, Vector3(0, 0.02, 0), GOLD, 2.35, 9.0, {"rings": 2, "ticks": 40, "star": 5, "turn": 5.0, "energy": 1.5, "keep": true})
	_keep.append(seal)
	DuelFx.ring(board, Vector3(0, 0.03, 0), AMBER, 0.3, 2.6, 0.7, 0.05)
	if await _w(0.55):
		_end()
		return
	# ---- 2. the five pieces, one by one
	var ids := [R_LEG, L_LEG, R_ARM, L_ARM, HEAD]
	var spots := [Vector3(-1.0, 0.03, 1.38), Vector3(1.0, 0.03, 1.38), Vector3(-1.62, 0.03, -0.52), Vector3(1.62, 0.03, -0.52), Vector3(0, 0.03, -1.7)]
	var flat: Basis = board.table_basis(0, true, true)
	var from: Vector3 = board.hand_pos(winner)
	for i in 5:
		var c := Card3D.new()
		c.setup(int(ids[i]))
		c.set_pickable(false)
		add_child(c)
		c.transform = Transform3D(Basis(Vector3.RIGHT, -0.5) * flat, from + Vector3((i - 2) * 0.3, 0, 0))
		c.scale = Vector3.ONE * 0.6
		_cards.append(c)
		var spot: Vector3 = spots[i]
		var high := Transform3D(flat, spot + Vector3(0, 1.5, 0))
		var tw := create_tween()
		tw.tween_method(_fly.bind(c, c.transform, high, 0.6, 1.25), 0.0, 1.0, Settings.t(0.26)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_method(_fly.bind(c, high, Transform3D(flat, spot + Vector3(0, 0.02, 0)), 1.25, 1.1), 0.0, 1.0, Settings.t(0.1)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		Sfx.play("whoosh", -10.0, 0.8 + i * 0.1)
		if await _w(0.36):
			_end()
			return
		# It lands.
		c.set_glow(true, GOLD)
		DuelFx.rect(board, spot, PALE, 1.1, 1.8, 0.45, false, 2.4, 1.0)
		DuelFx.ring(board, spot, GOLD, 0.25, 1.5, 0.5, 0.05)
		DuelFx.pillar(board, Vector3(spot.x, 0, spot.z), GOLD, 0.3, 5.0, 0.6, 0.0, 1.4)
		DuelFx.sparks(board, spot + Vector3(0, 0.1, 0), GOLD, 18, 3.5, 0.5, 0.7, -4.0, 0.05)
		Sfx.play("gong", -5.0, 0.7 + i * 0.09)
		Sfx.play("land", -6.0, 0.8)
		board.shake(0.3 + i * 0.06)
		board.cam_punch(1.5)
		# Chains of light to the pieces across from it: the five chains draw a five-point star, so every
		# piece ends up linked to the two that are not its neighbours. (0.62.0: they used to go from each
		# piece to the one before it, which left the star incomplete.)
		for pair in [[0, 4], [4, 1], [1, 2], [2, 3], [3, 0]]:
			var other := -1
			if pair[0] == i and pair[1] < i:
				other = pair[1]
			elif pair[1] == i and pair[0] < i:
				other = pair[0]
			if other >= 0:
				_chains.append(DuelFx.chain(board, spots[other] + Vector3(0, 0.1, 0), spot + Vector3(0, 0.1, 0), GOLD, board.camera, 0.2, 0.22))
		if await _w(0.12 if i < 4 else 0.45):
			_end()
			return
	# ---- 3. the chains snap, the seal opens
	for ch in _chains:
		DuelFx.snap_chain(ch, 0.2)
		Sfx.play("chain", -6.0, 0.7)
		board.shake(0.2)
		if await _w(0.09):
			_end()
			return
	_chains.clear()
	DuelFx.rays(board, Vector3(0, 0.03, 0), PALE, 4.2, 0.6, 40, true, 2.0)
	for i in 3:
		DuelFx.ring(board, Vector3(0, 0.03, 0), GOLD.lerp(AMBER, i * 0.4), 0.4, 2.6 + i * 1.2, 0.7, 0.06, i * 0.08, 1.8)
	DuelFx.pillar(board, Vector3(0, 0, -lz * 2.4), AMBER, 1.6, 10.0, 4.6, 0.0, 0.55)
	Sfx.play("el_thunder_hit", -4.0, 0.7)
	board.shake(0.8)
	board.house(0.8, GOLD, Vector3.ZERO, 1.0)
	# The cards rise and stand together: the camera goes to the loser's end and looks up.
	board.cam_shot(Vector3(0.7 * lz, 0.8, lz * 5.6), Vector3(0, 2.75, -lz * 1.6), 0.75)
	var stand: Basis = Basis(Vector3.RIGHT, PI * 0.5) * flat
	if lz < 0.0:
		stand = Basis(Vector3.UP, PI) * stand
	# (seen from the loser's end: its right arm and leg are on the viewer's left)
	var sx := lz
	# (it stands back from the loser's end, so all of it fits in the picture)
	var base := Vector3(0, 0, -lz * 1.6)
	var poses := [
		[Vector3(-0.74 * sx, 1.32, 0), 0.06 * sx],      # right leg
		[Vector3(0.74 * sx, 1.32, 0), -0.06 * sx],      # left leg
		[Vector3(-1.5 * sx, 3.25, 0), 0.3 * sx],        # right arm
		[Vector3(1.5 * sx, 3.25, 0), -0.3 * sx],        # left arm
		[Vector3(0, 4.5, 0), 0.0],                      # head
	]
	for i in 5:
		var c2: Card3D = _cards[i]
		var to := Transform3D(Basis(Vector3(0, 0, 1), float(poses[i][1])) * stand, base + poses[i][0])
		var tw2 := create_tween()
		tw2.tween_interval(Settings.t(0.05 * i))
		tw2.tween_method(_fly.bind(c2, c2.transform, to, 1.1, 2.0), 0.0, 1.0, Settings.t(0.6)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw2.parallel().tween_method(c2.flash, 2.5, 0.0, Settings.t(0.7))
	DuelFx.embers(board, Vector3(0, 0.03, 0), GOLD, 1.6, 60, 4.2, 4.5, 0.08)
	if await _w(0.85):
		_end()
		return
	# The figure: light behind it, a seal standing at its back, its heart lit.
	var chest := base + Vector3(0, 3.0, 0)
	var back := chest - Vector3(0, 0, lz * 0.5)
	var halo := _standing_seal(back, 3.3)
	_keep.append(halo)
	DuelFx.glow(board, back, AMBER, 7.5, 3.6, 0.0, 0.5)
	DuelFx.rays(board, back, GOLD, 5.5, 0.9, 34, false, 1.6)
	board.shake(0.9)
	board.cam_punch(4.0)
	Sfx.play("impact", 0.0, 0.5)
	Sfx.play("gong", -2.0, 0.5)
	board.cam_drift(Vector3(-0.6 * lz, 1.0, lz * 5.9), Settings.t(3.0))
	# ---- 4. its name, the light, the blast
	_hud.cut_in(winner, "EXODIA", Loc.t("The Forbidden One"), GOLD, 0.95, true)
	if await _w(1.1):
		_end()
		return
	Sfx.play("charge", 0.0, 0.6)
	Sfx.play("el_light_up", -3.0, 0.6)
	for i in 4:
		DuelFx.glow(board, chest + Vector3(0, 0, lz * 0.3), PALE if i % 2 == 0 else GOLD, 1.0 + i * 0.75, 0.5, 1.0, 1.8)
		DuelFx.ring(board, Vector3(0, 0.03, 0), GOLD, 3.2 - i * 0.2, 0.4, 0.3, 0.05, 0.0, 1.8)
		for c3 in _cards:
			(c3 as Card3D).flash(1.0 + i * 0.6)
		board.shake(0.25 + 0.12 * i)
		if await _w(0.17):
			_end()
			return
	# The beam, down the whole field.
	var target := Vector3(0, 1.2, lz * 9.0)
	var muzzle := chest + Vector3(0, 0, lz * 0.4)
	ElementFx.ribbon(board, muzzle, target, 6, PALE, AMBER, 4.2, 0.16, {"hold": 0.55, "fade": 0.3, "energy": 2.2})
	ElementFx.ribbon(board, muzzle, target, 3, Color.WHITE, GOLD, 1.9, 0.12, {"hold": 0.6, "fade": 0.25, "energy": 2.4})
	ElementFx.ribbon(board, Vector3(0, 0.05, lz * 0.5), Vector3(0, 0.05, lz * 8.0), 3, GOLD, AMBER, 3.0, 0.16, {"flat": true, "hold": 0.6, "fade": 0.4, "alpha": 0.7})
	DuelFx.glow(board, muzzle, Color.WHITE, 4.5, 0.6, 1.0, 2.4)
	Sfx.play("el_thunder", 2.0, 0.6)
	Sfx.play("el_fire_hit", 0.0, 0.6)
	board.shake(1.4)
	board.cam_punch(6.0)
	Pad.rumble(0.9, 1.0, 0.9)
	if await _w(0.2):
		_end()
		return
	var vs: Vector2 = _hud.get_viewport_rect().size
	ScreenFx.flash(_hud, Color.WHITE, 0.9, 1.0)
	ScreenFx.speed_lines(_hud, vs * 0.5, GOLD, 0.9)
	Sfx.play("el_thunder_hit", 2.0, 0.55)
	Sfx.play("direct", -2.0)
	board.house(1.0, GOLD, Vector3(0, 0, lz * 4.0), 1.2)
	board.duelist_body(1 - winner, "hurt", 2.2)
	if await _w(0.3):
		_end()
		return
	ScreenFx.shatter(_hud, vs * Vector2(0.5, 0.45), 1.1)
	Sfx.play("destroy", 0.0, 0.6)
	# What is left: the figure fades back into light.
	for c4 in _cards:
		var tw3 := create_tween().set_parallel()
		tw3.tween_method((c4 as Card3D).set_alpha, 1.0, 0.0, Settings.t(0.7))
		tw3.tween_property(c4, "position:y", (c4 as Card3D).position.y + 0.8, Settings.t(0.7))
	DuelFx.fade(seal, 0.6)
	DuelFx.fade(halo, 0.6)
	_keep.clear()
	DuelFx.embers(board, Vector3(0, 0.03, 0), GOLD, 1.8, 50, 1.2, 3.0, 0.07)
	await _w(0.75)
	_end()


## A card on its way from one place to another, growing or shrinking as it goes.
func _fly(t: float, c: Card3D, a: Transform3D, b: Transform3D, s0: float, s1: float) -> void:
	if not is_instance_valid(c):
		return
	var q := a.basis.orthonormalized().get_rotation_quaternion().slerp(b.basis.orthonormalized().get_rotation_quaternion(), clampf(t, 0.0, 1.0))
	c.transform = Transform3D(Basis(q), a.origin.lerp(b.origin, t))
	c.scale = Vector3.ONE * lerpf(s0, s1, t)


## The seal again, standing upright behind the figure and turning.
func _standing_seal(at: Vector3, radius: float) -> MeshInstance3D:
	var m: ShaderMaterial = DuelFx._mat("glyph_bill", DuelFx.HEAD + DuelFx.BILLBOARD + DuelFx.GLYPH, {"color": GOLD, "energy": 1.5, "alpha": 0.0, "radius": 0.86, "width": 0.016,
		"soft": 0.04, "rings": 2.0, "ticks": 48.0, "star": 5.0, "dash": 0.0, "spin": 0.0})
	var q := QuadMesh.new()
	q.size = Vector2(radius * 2.2, radius * 2.2)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 8.0
	mi.position = at
	_board.add_child(mi)
	mi.scale = Vector3.ONE * 0.2
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(m, "shader_parameter/alpha", 1.0, Settings.t(0.25))
	tw.tween_property(mi, "scale", Vector3.ONE, Settings.t(0.45)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "shader_parameter/spin", 3.0, Settings.t(6.0))
	return mi
