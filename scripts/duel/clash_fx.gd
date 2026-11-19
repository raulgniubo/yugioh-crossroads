class_name ClashFx
extends RefCounted
## Two monsters fight (0.58.0): their numbers come in from the two sides of the picture, crash
## into each other at the very moment the hit lands on the table, and the one that lost cracks
## in two and falls. A draw breaks them both. Against a Defense Position monster that holds,
## the attacker's number bounces off and dims instead.
##
## All of it is drawn over the duel (2D), so it reads the same from any camera.

const MINE := Color("5cc8ff")
const THEIRS := Color("ff5a7a")

## Keeps one side of a jagged line across a number: two copies of the same Label, one per
## side, are the two halves it breaks into.
const HALF := """
shader_type canvas_item;
uniform float side = 1.0;
uniform vec2 size = vec2(300.0, 120.0);
uniform float crack = 0.0;
varying vec2 lp;
void vertex() { lp = VERTEX; }
float line(vec2 p) {
	float x = p.x / size.x;
	float zig = abs(fract(x * 3.5) - 0.5) * 2.0 - 0.5;
	return (p.y - size.y * 0.5) - (x - 0.5) * size.y * 0.55 + zig * size.y * 0.22;
}
void fragment() {
	float d = line(lp) * side;
	if (d < 0.0) { discard; }
	float edge = (1.0 - smoothstep(0.0, 7.0, d)) * crack;
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), edge);
}
"""

## The burst where the two numbers meet.
const SPARK := """
shader_type canvas_item;
render_mode blend_add;
uniform vec4 tint : source_color = vec4(1.0);
uniform float t = 0.0;
float hash(float n) { return fract(sin(n * 91.7) * 43758.5); }
void fragment() {
	vec2 p = UV - 0.5;
	float r = length(p) * 2.0;
	float a = atan(p.y, p.x);
	float k = floor((a + 3.14159) / 6.28318 * 26.0);
	float ray = pow(abs(cos((a + 3.14159) / 6.28318 * 26.0 * 3.14159)), 6.0);
	float reach = (0.35 + hash(k) * 0.65) * t;
	float beam = ray * smoothstep(reach, reach * 0.3, r) * step(r, 1.0);
	float core = exp(-r * r * mix(60.0, 9.0, t)) * 1.6;
	float ring = exp(-pow((r - t * 0.9) * 14.0, 2.0)) * 0.8;
	float fade = 1.0 - smoothstep(0.45, 1.0, t);
	vec3 col = mix(vec3(1.0), tint.rgb, clamp(r * 1.6, 0.0, 1.0));
	COLOR = vec4(col * (beam + core + ring) * fade, 1.0);
}
"""

static var _half: Shader
static var _spark: Shader


## `a` is the attacker's ATK, `b` what it runs into (the target's ATK, or its DEF when it is
## in Defense Position). `a_mine`: the attacker is the player's. `hit_in`: seconds until the
## hit lands on the table.
static func play(host: Control, a: int, b: int, a_mine: bool, b_is_def: bool, hit_in: float) -> void:
	if not is_instance_valid(host):
		return
	var size := host.get_viewport_rect().size
	var k := size.y / 720.0
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = 40
	host.add_child(root)
	var cy := size.y * 0.3
	var mid := size.x * 0.5
	var gap := 118.0 * k
	# The player's number is always on the left, the opponent's on the right.
	var left_val := a if a_mine else b
	var right_val := b if a_mine else a
	var left_tag := "ATK" if a_mine else ("DEF" if b_is_def else "ATK")
	var right_tag := ("DEF" if b_is_def else "ATK") if a_mine else "ATK"
	var left := _number(root, left_val, left_tag, MINE, k)
	var right := _number(root, right_val, right_tag, THEIRS, k)
	var lw: float = left.get_meta("w")
	var rw: float = right.get_meta("w")
	var l_rest := Vector2(size.x * 0.2 - lw * 0.5, cy)
	var r_rest := Vector2(size.x * 0.8 - rw * 0.5, cy)
	var l_hit := Vector2(mid - gap * 0.5 - lw, cy)
	var r_hit := Vector2(mid + gap * 0.5, cy)
	left.position = l_rest - Vector2(size.x * 0.25, 0)
	right.position = r_rest + Vector2(size.x * 0.25, 0)
	left.modulate.a = 0.0
	right.modulate.a = 0.0
	var show_t := Settings.t(minf(0.14, hit_in * 0.35))
	var rush := Settings.t(0.13)
	var wait := maxf(0.0, Settings.t(hit_in) - show_t - rush)
	var tw := root.create_tween().set_parallel()
	tw.tween_property(left, "position", l_rest, show_t).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(right, "position", r_rest, show_t).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(left, "modulate:a", 1.0, show_t)
	tw.tween_property(right, "modulate:a", 1.0, show_t)
	tw.chain().tween_interval(wait)
	tw.chain().tween_property(left, "position", l_hit, rush).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(right, "position", r_hit, rush).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	await tw.finished
	if not is_instance_valid(root):
		return
	# --- the crash
	var a_wins := a > b
	var tie := a == b
	var spark_col := Color("fff0c0")
	_spark_at(root, Vector2(mid, cy + 52.0 * k), spark_col, 520.0 * k)
	var attacker := left if a_mine else right
	var defender := right if a_mine else left
	var loser: Array = []
	var bounced: Control = null
	if b_is_def:
		if a_wins:
			loser = [defender]
		elif not tie:
			bounced = attacker
		else:
			bounced = attacker
	elif tie:
		loser = [left, right]
	else:
		loser = [defender if a_wins else attacker]
	# Both jump back off the hit, shaking.
	var back := root.create_tween().set_parallel()
	back.tween_property(left, "position", l_hit - Vector2(34.0 * k, 0), Settings.t(0.1)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	back.tween_property(right, "position", r_hit + Vector2(34.0 * k, 0), Settings.t(0.1)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	back.tween_method(func(t: float):
		if is_instance_valid(left) and is_instance_valid(right):
			left.rotation = sin(t * 50.0) * 0.05 * (1.0 - t)
			right.rotation = -sin(t * 46.0) * 0.05 * (1.0 - t), 0.0, 1.0, Settings.t(0.22))
	for n in [left, right]:
		if not loser.has(n) and n != bounced:
			# The one still standing swells for a beat.
			var win := root.create_tween()
			win.tween_property(n, "scale", Vector2.ONE * 1.22, Settings.t(0.12)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			win.tween_property(n, "scale", Vector2.ONE, Settings.t(0.25))
	await root.get_tree().create_timer(Settings.t(0.2)).timeout
	if not is_instance_valid(root):
		return
	for n in loser:
		_break(root, n, k, n == left)
	if bounced != null:
		var away := -1.0 if bounced == left else 1.0
		var bt := root.create_tween().set_parallel()
		bt.tween_property(bounced, "position:x", bounced.position.x + away * 90.0 * k, Settings.t(0.3)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		bt.tween_property(bounced, "modulate", Color(0.55, 0.55, 0.6, 0.75), Settings.t(0.3))
	await root.get_tree().create_timer(Settings.t(0.62)).timeout
	if not is_instance_valid(root):
		return
	var out := root.create_tween()
	out.tween_property(root, "modulate:a", 0.0, Settings.t(0.22))
	out.tween_callback(root.queue_free)


## One number with its small tag over it, as a Control whose top-left is its position.
static func _number(root: Control, value: int, tag: String, color: Color, k: float) -> Control:
	var box := Control.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)
	var num := _label(str(value), int(104 * k), Color.WHITE, int(20 * k))
	num.add_theme_color_override("font_outline_color", color.darkened(0.55))
	num.add_theme_color_override("font_shadow_color", Color(color, 0.55))
	num.add_theme_constant_override("shadow_offset_x", 0)
	num.add_theme_constant_override("shadow_offset_y", int(7 * k))
	num.add_theme_constant_override("shadow_outline_size", int(30 * k))
	box.add_child(num)
	var ms := num.get_minimum_size()
	num.size = ms
	var cap := _label(tag, int(26 * k), color, int(9 * k))
	cap.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	box.add_child(cap)
	cap.position = Vector2(6.0 * k, -14.0 * k)
	box.size = ms
	box.pivot_offset = ms * 0.5
	box.set_meta("w", ms.x)
	box.set_meta("num", num)
	box.set_meta("color", color)
	return box


static func _label(text: String, size: int, color: Color, outline: int) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", UITheme.title_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", outline)
	return l


## The number that lost: a white crack runs across it, then its two halves come apart and fall.
static func _break(root: Control, box: Control, k: float, left_side: bool) -> void:
	if _half == null:
		_half = Shader.new()
		_half.code = HALF
	var num: Label = box.get_meta("num")
	var color: Color = box.get_meta("color")
	var halves: Array = []
	for side in [1.0, -1.0]:
		var piece: Label = num.duplicate()
		var m := ShaderMaterial.new()
		m.shader = _half
		m.set_shader_parameter("side", side)
		m.set_shader_parameter("size", num.size)
		m.set_shader_parameter("crack", 0.0)
		piece.material = m
		piece.pivot_offset = num.size * 0.5
		box.add_child(piece)
		halves.append(piece)
	num.visible = false
	Sfx.play("destroy", -9.0, 1.5)
	_spark_at(root, box.position + num.size * 0.5, color.lightened(0.4), 300.0 * k)
	var away := -1.0 if left_side else 1.0
	var tw := root.create_tween().set_parallel()
	for i in 2:
		var piece: Label = halves[i]
		var m: ShaderMaterial = piece.material
		var dir := 1.0 if i == 0 else -1.0     # (lower half, upper half)
		tw.tween_method(func(v: float): m.set_shader_parameter("crack", v), 0.0, 1.0, Settings.t(0.08))
		tw.tween_property(piece, "position", Vector2(away * (28.0 + 30.0 * float(i)) * k, (150.0 * dir if dir > 0.0 else 96.0) * k), Settings.t(0.55)).set_delay(Settings.t(0.1)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(piece, "rotation", away * dir * 0.5, Settings.t(0.55)).set_delay(Settings.t(0.1)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(piece, "modulate", Color(color.r, color.g, color.b, 0.0), Settings.t(0.4)).set_delay(Settings.t(0.25))


static func _spark_at(root: Control, at: Vector2, color: Color, size: float) -> void:
	if _spark == null:
		_spark = Shader.new()
		_spark.code = SPARK
	var r := ColorRect.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = _spark
	m.set_shader_parameter("tint", color)
	m.set_shader_parameter("t", 0.0)
	r.material = m
	r.size = Vector2(size, size)
	r.position = at - r.size * 0.5
	root.add_child(r)
	var tw := root.create_tween()
	tw.tween_method(func(v: float): m.set_shader_parameter("t", v), 0.0, 1.0, Settings.t(0.42)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(r.queue_free)
