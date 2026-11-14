extends Control
## Destiny Draw, the moment itself. The field goes dark, the duelist is close, a heartbeat, the
## spirit dives into the Deck, the top card lights up, and it is ripped off the Deck in a line
## of light and turned to the screen. About four seconds; a click or a key skips it.
## Everything is drawn in 2D over the duel and frees itself.
##
## Load with preload() (it has no class name): DestinyShow.play(host, {...}) and await it.

const GOLD := Color("ffd76a")
const HOT := Color("fff3c4")
const INK := Color("060a16")
const CARD := Vector2(300, 438)

const RAYS := """
shader_type canvas_item;
render_mode blend_add;
uniform vec2 focus = vec2(0.5, 0.5);
uniform float amt = 0.0;
uniform float aspect = 1.78;
uniform vec3 tint : source_color = vec3(1.0, 0.84, 0.42);
float hash(float p) { return fract(sin(p * 91.7) * 43758.5453); }
void fragment() {
	vec2 d = UV - focus;
	d.x *= aspect;
	float r = length(d);
	float a = atan(d.y, d.x);
	float seg = floor(a * 28.0);
	float f = fract(a * 28.0);
	float on = step(0.45, hash(seg + 3.0));
	float w = 0.5 - abs(f - 0.5);
	float ray = smoothstep(0.0, 0.25, w) * on;
	// Each ray is a streak running inward, toward the Deck.
	float run = fract(r * (1.2 + hash(seg) * 1.6) + TIME * (0.5 + hash(seg + 7.0)) );
	float streak = smoothstep(0.0, 0.3, run) * smoothstep(1.0, 0.55, run);
	float fall = smoothstep(0.06, 0.5, r) * (1.0 - smoothstep(0.9, 1.5, r));
	float core = exp(-r * 5.0) * 0.9;
	COLOR = vec4(tint, (ray * streak * fall * 0.55 + core) * amt);
}
"""

const SHINE := """
shader_type canvas_item;
uniform float t = -0.3;
uniform float glow = 0.0;
void fragment() {
	vec4 c = COLOR;   // already the texture's color times the node's
	float band = smoothstep(0.16, 0.0, abs((UV.x + UV.y * 0.55) - t * 1.9));
	c.rgb += vec3(1.0, 0.95, 0.8) * band * 0.75 * c.a;
	c.rgb += vec3(1.0, 0.86, 0.5) * glow * c.a;
	COLOR = c;
}
"""

var _skip := false
var _done := false
var _tweens: Array = []
var _shake := 0.0
var _beat_nodes: Array = []


## cfg: side (0 you, 1 them), key (duelist), color, back (Texture2D), face (Texture2D or null to
## keep the card hidden), name (card name or ""), spirit (Texture2D or null), who (duelist's name).
static func play(host: Control, cfg: Dictionary) -> void:
	if host == null or not host.is_inside_tree():
		return
	var show: Control = (load("res://scripts/duel/destiny_show.gd") as GDScript).new()
	show.set_anchors_preset(Control.PRESET_FULL_RECT)
	show.mouse_filter = Control.MOUSE_FILTER_STOP
	show.z_index = 90
	host.add_child(show)
	await show._run(cfg)


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_skip = true
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if _done:
		return
	if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventJoypadButton and event.pressed):
		_skip = true
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 14.0 * (_shake / 0.3)
	elif position != Vector2.ZERO:
		position = Vector2.ZERO


func _tw() -> Tween:
	var t := create_tween()
	_tweens.append(t)
	return t


## Wait, unless the player has asked to skip.
func _hold(seconds: float) -> void:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until and not _skip and is_inside_tree():
		await get_tree().process_frame


## Dev: cfg "freeze" names a moment to stop at, for a still picture of it.
var _freeze := ""

func _stage(name: String) -> void:
	if _freeze == name:
		await _hold(600.0)


func _glow_tex(inner: Color, size := 256) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, inner)
	g.set_color(1, Color(inner.r, inner.g, inner.b, 0.0))
	g.add_point(0.35, Color(inner.r, inner.g, inner.b, inner.a * 0.45))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = size
	t.height = size
	return t


func _add_mat() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m


func _sprite(tex: Texture2D, size: Vector2, at: Vector2, add := false) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.size = size
	r.pivot_offset = size / 2.0
	r.position = at - size / 2.0
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if add:
		r.material = _add_mat()
	add_child(r)
	return r


func _beat(strength := 1.0) -> void:
	Sfx.play("impact", -13.0 + strength * 3.0, 0.5)
	for n in _beat_nodes:
		if is_instance_valid(n):
			var base: Vector2 = n.get_meta("rest", Vector2.ONE)
			n.scale = base * (1.0 + 0.035 * strength)
			_tw().tween_property(n, "scale", base, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _run(cfg: Dictionary) -> void:
	var vs := get_viewport_rect().size
	_freeze = str(cfg.get("freeze", ""))
	var side := int(cfg.get("side", 0))
	var dir := 1.0 if side == 0 else -1.0
	var col: Color = cfg.get("color", GOLD)
	var face_tex: Texture2D = cfg.get("face")
	var back_tex: Texture2D = cfg.get("back")
	var deck_at := Vector2(vs.x * (0.7 if side == 0 else 0.3), vs.y * 0.56)
	var show_at := Vector2(vs.x * (0.57 if side == 0 else 0.43), vs.y * 0.52)

	# ---- the field goes dark
	var shade := ColorRect.new()
	shade.color = Color(INK, 0.0)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	_tw().tween_property(shade, "color:a", 0.88, 0.3)
	var rays := ColorRect.new()
	rays.set_anchors_preset(Control.PRESET_FULL_RECT)
	rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rm := ShaderMaterial.new()
	var rsh := Shader.new()
	rsh.code = RAYS
	rm.shader = rsh
	rm.set_shader_parameter("focus", deck_at / vs)
	rm.set_shader_parameter("aspect", vs.x / vs.y)
	rm.set_shader_parameter("amt", 0.0)
	rm.set_shader_parameter("tint", Vector3(GOLD.r, GOLD.g, GOLD.b).lerp(Vector3(col.r, col.g, col.b), 0.25))
	rays.material = rm
	add_child(rays)
	var set_rays := func(v: float): rm.set_shader_parameter("amt", v)
	_tw().tween_method(set_rays, 0.0, 0.45, 0.6)

	# ---- the duelist, close
	var ptex: Texture2D = Avatars.portrait(str(cfg.get("key", "")), true)
	if ptex == null:
		ptex = Portraits.get_portrait(str(cfg.get("key", "")))
	var who := TextureRect.new()
	who.texture = ptex
	who.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	who.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	# Close: the face sits in the upper third, the shoulders run off the bottom of the screen.
	who.size = Vector2(vs.y * 1.24, vs.y * 1.55)
	who.pivot_offset = Vector2(who.size.x / 2.0, who.size.y * 0.3)
	who.flip_h = side == 1
	var who_x := -vs.y * 0.14 if side == 0 else vs.x + vs.y * 0.14 - who.size.x
	who.position = Vector2(who_x - dir * 260.0, -vs.y * 0.3)
	who.modulate = Color(1, 1, 1, 0.0)
	who.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(who)
	var in_tw := _tw().set_parallel()
	in_tw.tween_property(who, "position:x", who_x, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	in_tw.tween_property(who, "modulate:a", 1.0, 0.25)
	# The slow push-in that runs under everything else.
	who.set_meta("rest", Vector2.ONE)
	_tw().tween_property(who, "scale", Vector2(1.07, 1.07), 4.5)

	# ---- their Deck
	var halo := _sprite(_glow_tex(Color(GOLD, 0.85)), Vector2(900, 900), deck_at, true)
	halo.modulate.a = 0.0
	halo.scale = Vector2(0.5, 0.5)
	var deck := Control.new()
	deck.position = deck_at
	deck.rotation = -0.1 * dir
	deck.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck.modulate.a = 0.0
	add_child(deck)
	var dsize := CARD * 0.78
	for i in 9:
		var layer := TextureRect.new()
		layer.texture = back_tex
		layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer.size = dsize
		layer.position = -dsize / 2.0 + Vector2(1.6, 2.2) * float(8 - i)
		layer.modulate = Color(1, 1, 1).darkened(0.35 - i * 0.04) if i < 8 else Color.WHITE
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		deck.add_child(layer)
	deck.set_meta("rest", Vector2.ONE)
	_beat_nodes = [deck, halo]
	halo.set_meta("rest", Vector2(0.8, 0.8))
	var deck_in := _tw().set_parallel()
	deck_in.tween_property(deck, "modulate:a", 1.0, 0.3).set_delay(0.15)
	deck_in.tween_property(halo, "modulate:a", 0.55, 0.5).set_delay(0.2)
	deck_in.tween_property(halo, "scale", Vector2(0.8, 0.8), 0.5).set_delay(0.2)
	# Motes of light lifting off it.
	var motes := CPUParticles2D.new()
	motes.position = deck_at
	motes.amount = 46
	motes.lifetime = 1.6
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = dsize * 0.55
	motes.direction = Vector2(0, -1)
	motes.spread = 24.0
	motes.gravity = Vector2(0, -60)
	motes.initial_velocity_min = 30.0
	motes.initial_velocity_max = 120.0
	motes.scale_amount_min = 2.0
	motes.scale_amount_max = 6.0
	motes.color = Color(HOT, 0.9)
	motes.material = _add_mat()
	motes.emitting = false
	add_child(motes)

	# ---- the words over it
	var kicker := UITheme.label(Loc.t("%s  ·  LIFE POINTS ON THE LINE") % str(cfg.get("who", "")).to_upper(), 24, HOT, UITheme.semi_font())
	kicker.modulate.a = 0.0
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kicker.size = Vector2(vs.x, 34)
	kicker.position = Vector2(0, vs.y * 0.085)
	kicker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(kicker)
	_tw().tween_property(kicker, "modulate:a", 0.9, 0.4).set_delay(0.3)

	await _hold(0.38)
	_beat(0.7)
	await _hold(0.22)
	_beat(1.0)
	motes.emitting = true

	# ---- the spirit goes in after the card
	var spirit_tex: Texture2D = cfg.get("spirit")
	if spirit_tex != null and not _skip:
		var from := Vector2(who_x + who.size.x * (0.7 if side == 0 else 0.3), vs.y * 0.3)
		var sp := _sprite(spirit_tex, Vector2(190, 190), from)
		sp.modulate.a = 0.0
		var trail_tex := _glow_tex(Color(0.5, 0.92, 1.0, 0.9), 64)
		var ctrl := (from + deck_at) / 2.0 + Vector2(0, -vs.y * 0.32)
		var last_trail := [0.0]
		var fly := func(t: float):
			if not is_instance_valid(sp):
				return
			var a := from.lerp(ctrl, t)
			var b := ctrl.lerp(deck_at, t)
			var p := a.lerp(b, t)
			sp.position = p - sp.size / 2.0
			sp.scale = Vector2.ONE * lerpf(1.0, 0.25, t * t)
			if t - float(last_trail[0]) > 0.035:
				last_trail[0] = t
				var dot := _sprite(trail_tex, Vector2(70, 70) * lerpf(1.0, 0.4, t), p, true)
				var fade := dot.create_tween()
				fade.tween_property(dot, "modulate:a", 0.0, 0.45)
				fade.tween_callback(dot.queue_free)
		_tw().tween_property(sp, "modulate:a", 1.0, 0.12)
		Sfx.play("whoosh", -10.0, 1.5)
		var fly_tw := _tw()
		fly_tw.tween_method(fly, 0.0, 1.0, 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await _hold(0.62)
		fly_tw.kill()
		if is_instance_valid(sp):
			sp.queue_free()
		# It lands: a ring of light runs out of the Deck.
		var ring := _sprite(_glow_tex(Color(0.6, 0.95, 1.0, 0.9)), Vector2(240, 240), deck_at, true)
		var ring_tw := ring.create_tween().set_parallel()
		ring_tw.tween_property(ring, "scale", Vector2(5.0, 5.0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ring_tw.tween_property(ring, "modulate:a", 0.0, 0.45)
		Sfx.play("spell", -7.0, 1.2)
	else:
		await _hold(0.35)
	_beat(0.8)
	await _hold(0.2)
	_beat(1.1)
	await _stage("deck")

	# ---- the top card answers
	var card := TextureRect.new()
	card.texture = back_tex
	card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card.size = CARD
	card.pivot_offset = CARD / 2.0
	card.scale = Vector2(0.78, 0.78)
	card.rotation = -0.1 * dir
	card.position = deck_at - CARD / 2.0
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cm := ShaderMaterial.new()
	var csh := Shader.new()
	csh.code = SHINE
	cm.shader = csh
	cm.set_shader_parameter("glow", 0.0)
	cm.set_shader_parameter("t", -0.3)
	card.material = cm
	add_child(card)
	var set_glow := func(v: float): cm.set_shader_parameter("glow", v)
	var lift := _tw().set_parallel()
	lift.tween_property(card, "position:y", card.position.y - 46.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	lift.tween_method(set_glow, 0.0, 0.55, 0.3)
	lift.tween_method(set_rays, 0.45, 1.0, 0.3)
	lift.tween_property(halo, "modulate:a", 1.0, 0.3)
	Sfx.play("turn", -8.0, 1.6)
	await _hold(0.42)
	await _stage("lift")

	# ---- DRAW
	var from_c := card.position + CARD / 2.0
	var bend := (from_c + show_at) / 2.0 + Vector2(-dir * vs.x * 0.05, -vs.y * 0.34)
	var arc := Line2D.new()
	arc.width = 46.0
	arc.default_color = Color(HOT, 0.95)
	arc.material = _add_mat()
	arc.joint_mode = Line2D.LINE_JOINT_ROUND
	arc.begin_cap_mode = Line2D.LINE_CAP_ROUND
	arc.end_cap_mode = Line2D.LINE_CAP_ROUND
	var wc := Curve.new()
	wc.add_point(Vector2(0.0, 0.0))
	wc.add_point(Vector2(0.75, 1.0))
	wc.add_point(Vector2(1.0, 0.35))
	arc.width_curve = wc
	add_child(arc)
	move_child(arc, card.get_index())
	var rip := func(t: float):
		var a := from_c.lerp(bend, t)
		var b := bend.lerp(show_at, t)
		var p := a.lerp(b, t)
		if is_instance_valid(arc):
			arc.add_point(p)
		if is_instance_valid(card):
			card.position = p - CARD / 2.0
			card.rotation = lerpf(-0.1 * dir, TAU * dir, t)
			card.scale = Vector2.ONE * lerpf(0.78, 1.18, t)
	var flash := ColorRect.new()
	flash.color = Color(1, 0.97, 0.88, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	Sfx.play("attack", -4.0, 1.25)
	if not _skip:
		_tw().tween_method(rip, 0.0, 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await _hold(0.24)
	rip.call(1.0)
	card.rotation = 0.0
	flash.color.a = 0.8
	_tw().tween_property(flash, "color:a", 0.0, 0.3)
	_tw().tween_property(arc, "modulate:a", 0.0, 0.5)
	_tw().tween_method(set_rays, 1.0, 0.5, 0.5)
	_tw().tween_method(set_glow, 0.55, 0.0, 0.4)
	rm.set_shader_parameter("focus", show_at / vs)
	halo.position = show_at - halo.size / 2.0
	motes.position = show_at
	_tw().tween_property(deck, "modulate:a", 0.0, 0.25)
	_shake = 0.3
	Sfx.play("impact", -2.0, 0.9)

	# ---- the name of the move
	var title := Comic.label(Loc.t("DESTINY DRAW"), 150, GOLD, 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(vs.x, 170)
	title.position = Vector2(0, vs.y * 0.045)
	title.pivot_offset = title.size / 2.0
	title.rotation = -0.035
	title.scale = Vector2(2.3, 2.3)
	title.modulate.a = 0.0
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	kicker.visible = false
	var slam := _tw().set_parallel()
	slam.tween_property(title, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	slam.tween_property(title, "modulate:a", 1.0, 0.08)
	Sfx.play("vs", -3.0, 1.1)
	await _hold(0.3)
	await _stage("title")

	# ---- what it is
	var named: Label = null
	if face_tex != null:
		if not _skip:
			_tw().tween_property(card, "scale:x", 0.0, 0.1)
			await _hold(0.1)
		card.texture = face_tex
		Sfx.play("card", -4.0, 0.9)
		var turn_tw := _tw()
		turn_tw.tween_property(card, "scale:x", 1.18, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var sweep := func(v: float): cm.set_shader_parameter("t", v)
		_tw().tween_method(sweep, -0.3, 1.3, 0.55).set_delay(0.12)
		Sfx.play("summon", -8.0, 1.2)
		named = Comic.label(str(cfg.get("name", "")), 46, Color.WHITE, 8)
		named.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		named.size = Vector2(vs.x, 60)
		named.position = Vector2(0, show_at.y + CARD.y * 0.59 + 14.0)
		named.modulate.a = 0.0
		named.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(named)
		_tw().tween_property(named, "modulate:a", 1.0, 0.2).set_delay(0.15)
		await _hold(1.25)
		await _stage("face")
	else:
		# Their card stays their secret.
		_tw().tween_method(set_glow, 0.0, 0.35, 0.25)
		await _hold(0.85)

	# ---- and into the hand
	_done = true
	var out := create_tween().set_parallel()
	var hand_at := Vector2(vs.x * 0.5, vs.y + 220.0) if side == 0 else Vector2(vs.x * 0.5, -260.0)
	out.tween_property(card, "position", hand_at - CARD / 2.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	out.tween_property(card, "scale", Vector2(0.5, 0.5), 0.28)
	for n in [shade, who, halo, title, flash, motes, arc]:
		if is_instance_valid(n):
			out.tween_property(n, "modulate:a", 0.0, 0.26)
	out.tween_method(set_rays, 0.5, 0.0, 0.24)
	if named != null:
		out.tween_property(named, "modulate:a", 0.0, 0.2)
	Sfx.play("draw", -4.0)
	await out.finished
	for t in _tweens:
		if t is Tween and t.is_valid():
			t.kill()
	queue_free()
