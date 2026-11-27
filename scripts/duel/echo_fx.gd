extends RefCounted
## What sets Lumen's cards apart on the table (0.81.0). Everything of hers leaves echoes: copies
## of the card made of light that gather into it when it arrives, follow it when it attacks and
## strike again a moment after it does. Her bonds are threads of light that run into her.
##   const EchoFx := preload("res://scripts/duel/echo_fx.gd")

const CYAN := Color("7fe8ff")
const GOLD := Color("ffd766")
const BOND_COLORS := [Color("ffd766"), Color("ff8ad0"), Color("8dffb0"), Color("b08aff"), Color("7fe8ff")]


## One of Lumen's cards (any of them: her forms, the Echo monsters, the Spells and Traps).
static func is_echo(id: int) -> bool:
	return CardData.LUMEN_CARDS.has(id)


## The look of the summon set piece for one of her forms ("" for any other card).
static func summon_look(id: int) -> String:
	return str({99200002: "chorus", 99200003: "comet", 99200004: "zenith", 99200006: "aurora", 99200007: "nova"}.get(id, ""))


## A copy of a card made of light.
static func _ghost(board: Node3D, id: int, xf: Transform3D, alpha: float, tint := CYAN) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Card3D.SIZE
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_BACK
	m.albedo_texture = Cards.get_face(id)
	m.albedo_color = Color(tint.r, tint.g, tint.b, alpha)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	board.add_child(mi)
	mi.transform = xf
	return mi


## The echoes gather: copies of the card appear round it and close into it, with a flash.
## Wait for it (about a third of a second).
static func gather(board: Node3D, c: Card3D, count := 4, radius := 0.95, tint := CYAN) -> void:
	if c == null or not is_instance_valid(c):
		return
	var xf := c.transform
	var right := xf.basis.x.normalized()
	var up := xf.basis.y.normalized()
	var dur := Settings.t(0.3)
	for i in count:
		var a := TAU * float(i) / float(count) + 0.5
		var off := (right * cos(a) + up * sin(a) * 0.8) * radius
		var g := _ghost(board, c.card_id, Transform3D(xf.basis, xf.origin + off), 0.0, tint)
		var gm: StandardMaterial3D = g.material_override
		var tw := board.create_tween()
		tw.tween_interval(Settings.t(0.035) * i)
		tw.tween_property(gm, "albedo_color:a", 0.8, dur * 0.3)
		tw.parallel().tween_property(g, "position", xf.origin, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(gm, "albedo_color:a", 0.0, Settings.t(0.1))
		tw.tween_callback(g.queue_free)
	Sfx.play("blip", -10.0, 1.7)
	await board.get_tree().create_timer(dur + Settings.t(0.035) * count).timeout
	if not is_instance_valid(c):
		return
	DuelFx.glow(board, c.position, Color(0.85, 1.0, 1.0), 1.7, 0.4, 0.7, 2.4)
	board.create_tween().tween_method(c.flash, 2.6, 0.3, Settings.t(0.3))
	Sfx.play("blip", -6.0, 2.2)


## The echoes follow: the card leaves copies of itself behind as it moves, each fading out.
static func trail(board: Node3D, c: Card3D, seconds: float) -> void:
	if c == null or not is_instance_valid(c):
		return
	var n := clampi(int(seconds / 0.03) + 1, 3, 9)
	for i in n:
		var tw := board.create_tween()
		tw.tween_interval(Settings.t(seconds) * float(i) / float(n))
		tw.tween_callback(func():
			if not is_instance_valid(c):
				return
			var g := _ghost(board, c.card_id, c.transform, 0.45)
			var fade := board.create_tween()
			fade.tween_property(g.material_override, "albedo_color:a", 0.0, Settings.t(0.34))
			fade.tween_callback(g.queue_free))


## The echoes strike: copies of the card cross the same road a moment after it and land where
## it landed, each with its own ring of light.
static func strikes(board: Node3D, id: int, from: Transform3D, goal: Vector3, count := 2) -> void:
	for i in count:
		var g := _ghost(board, id, from, 0.0)
		var gm: StandardMaterial3D = g.material_override
		var land := goal + Vector3(0, 0.25, 0)
		var tw := board.create_tween()
		tw.tween_interval(Settings.t(0.1) * (i + 1))
		tw.tween_property(gm, "albedo_color:a", 0.7, 0.02)
		tw.tween_property(g, "position", land, Settings.t(0.12)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			DuelFx.ring(board, Vector3(goal.x, 0.03, goal.z), CYAN.lightened(0.25 * i), 0.2, 1.3 + 0.5 * i, 0.42, 0.05)
			DuelFx.sparks(board, goal + Vector3(0, 0.2, 0), CYAN.lightened(0.3), 14, 4.0, 0.5, 0.5)
			DuelFx.glow(board, land, CYAN, 1.2, 0.25, 0.4)
			Sfx.play("impact", -13.0, 1.7 + 0.25 * i))
		tw.tween_property(gm, "albedo_color:a", 0.0, Settings.t(0.12))
		tw.tween_callback(g.queue_free)


## Her bonds: threads of light, one for each bond, come in from around the field and run into her.
static func bonds(board: Node3D, at: Vector3, count: int) -> void:
	count = clampi(count, 1, 5)
	for k in count:
		var a := PI * (0.12 + 0.76 * (float(k) + 0.5) / float(count))
		var from := at + Vector3(cos(a) * 3.4, 1.5 + 0.5 * sin(a * 2.0), -sin(a) * 1.9 + 1.0)
		var col: Color = BOND_COLORS[k % BOND_COLORS.size()]
		var orb := DuelFx.orb(board, from, col, 0.2)
		orb.trail = true
		var mid := (from + at) * 0.5 + Vector3(0, 0.9, 0)
		var tw := board.create_tween()
		tw.tween_interval(Settings.t(0.09) * k)
		tw.tween_method(func(t: float):
			if is_instance_valid(orb):
				orb.position = from.lerp(mid, t).lerp(mid.lerp(at + Vector3(0, 0.2, 0), t), t), 0.0, 1.0, Settings.t(0.5)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_callback(func():
			if is_instance_valid(orb):
				orb.pop(0.7)
			DuelFx.ring(board, at, col, 0.2, 1.0 + 0.12 * k, 0.4, 0.04)
			Sfx.play("blip", -12.0, 1.2 + 0.15 * k))
	var done := board.create_tween()
	done.tween_interval(Settings.t(0.5 + 0.09 * count))
	done.tween_callback(func():
		DuelFx.glow(board, at + Vector3(0, 0.3, 0), Color(1, 1, 0.92), 1.8, 0.45, 0.6)
		DuelFx.sparks(board, at + Vector3(0, 0.2, 0), GOLD, 18, 2.6, 0.9, 0.7, 0.5, 0.04))


## The last blow of the duel, when one of hers lands it: every echo she has gathers first.
static func finisher_gather(board: Node3D, c: Card3D) -> void:
	if c == null or not is_instance_valid(c):
		return
	DuelFx.glyph(board, Vector3(c.position.x, 0.03, c.position.z), CYAN, 1.7, 1.3, {"rings": 2, "ticks": 36, "star": 0, "turn": -2.6, "energy": 2.6})
	gather(board, c, 8, 1.5)
	await board.get_tree().create_timer(Settings.t(0.2)).timeout
	await gather(board, c, 6, 1.0, Color(1.0, 0.95, 0.75))


## The last blow has landed: the echoes go out from it, ring after ring.
static func finisher_burst(board: Node3D, floor_at: Vector3) -> void:
	for i in 5:
		DuelFx.ring(board, floor_at, CYAN.lerp(Color.WHITE, 0.15 * i), 0.3, 2.0 + i * 1.5, 0.8 + 0.12 * i, 0.05, 0.11 * i)
	DuelFx.rays(board, floor_at, CYAN, 5.0, 0.7, 44)
	DuelFx.sparks(board, floor_at + Vector3(0, 0.4, 0), GOLD, 60, 7.0, 0.6, 1.2)
