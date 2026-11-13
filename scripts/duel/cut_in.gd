class_name CutIn
extends Control
## Anime-style cut-in: a slanted band sweeps across the screen with the duelist's live portrait,
## speed lines and a line of text. Also holds the impact flash used when attacks land.
## Nothing here blocks input, and every piece frees itself.

const BAND := """
shader_type canvas_item;
uniform float center = 0.5;
uniform float half_h = 0.16;
uniform float slant = 0.08;
uniform float progress = 0.0;      // 0..1 wipe in
uniform float fade = 1.0;
uniform float dir = 1.0;           // 1: sweeps in from the left, -1: from the right
uniform vec3 tint : source_color = vec3(0.2, 0.9, 0.9);
float hash(float p) { return fract(sin(p * 127.1) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	float x = dir > 0.0 ? uv.x : 1.0 - uv.x;
	float c = center + (uv.x - 0.5) * slant;
	float d = abs(uv.y - c);
	float inside = 1.0 - smoothstep(half_h - 0.002, half_h, d);
	// The leading edge is slanted too, so the band reads as a slash.
	float lead = progress * 1.25 - (uv.y - center) * 0.35;
	float wipe = 1.0 - smoothstep(lead - 0.02, lead, x);
	// A deep band in the duelist's color: dark at the far end, lit toward their side, thin
	// speed streaks, and a fine bright line along both edges.
	vec3 deep = mix(vec3(0.03, 0.05, 0.11), tint * 0.22, 0.6);
	vec3 col = mix(deep, tint * 0.72 + vec3(0.04), pow(1.0 - x, 1.6));
	float row = floor((uv.y - c) * 110.0);
	float sp = 1.5 + hash(row) * 3.0;
	float ln = fract(x * (1.0 + hash(row + 9.0) * 2.0) - TIME * sp * dir * dir + hash(row + 3.0));
	float streak = smoothstep(0.0, 0.5, ln) * smoothstep(1.0, 0.5, ln) * step(0.62, hash(row + 5.0));
	col += vec3(1.0) * streak * 0.16;
	float rail = smoothstep(half_h - 0.0085, half_h - 0.006, d) * inside;
	col = mix(col, mix(vec3(1.0), tint, 0.25), rail * 0.95);
	float a = inside * wipe * fade;
	COLOR = vec4(col, a * mix(0.94, 1.0, rail));
}
"""

const FACE := """
shader_type canvas_item;
uniform float center = 0.5;
uniform float half_h = 0.16;
uniform float slant = 0.08;
uniform float fade = 1.0;
uniform float over = 0.05;         // how far the head may poke out above the band
uniform vec3 tint : source_color = vec3(0.2, 0.9, 0.9);
void fragment() {
	vec4 t = texture(TEXTURE, UV);
	vec2 uv = SCREEN_UV;
	float c = center + (uv.x - 0.5) * slant;
	float below = 1.0 - smoothstep(c + half_h - 0.004, c + half_h, uv.y);
	float above = smoothstep(c - half_h - over - 0.004, c - half_h - over, uv.y);
	// A colored rim so the figure pops off the band.
	float rim = smoothstep(0.75, 0.2, t.a) * t.a;
	vec3 col = t.rgb * 1.08 + tint * rim * 0.9;
	COLOR = vec4(col, t.a * below * above * fade);
}
"""

const LINES := """
shader_type canvas_item;
uniform float amount = 1.0;
uniform vec2 focus = vec2(0.5, 0.5);
uniform vec3 tint : source_color = vec3(1.0, 1.0, 1.0);
float hash(float p) { return fract(sin(p * 91.3) * 43758.5453); }
void fragment() {
	vec2 p = SCREEN_UV - focus;
	p.x *= 16.0 / 9.0;
	float ang = atan(p.y, p.x);
	float r = length(p);
	float seg = floor(ang * 38.0);
	float w = hash(seg + floor(TIME * 24.0) * 7.0);
	float spoke = step(0.55, w) * smoothstep(0.5, 0.0, abs(fract(ang * 38.0) - 0.5) * (1.0 + w * 2.0));
	float reach = smoothstep(0.16 + w * 0.2, 0.75, r);
	float a = spoke * reach * amount;
	float flash = smoothstep(0.35, 0.0, r) * amount * 0.35;
	COLOR = vec4(mix(tint, vec3(1.0), 0.6), clamp(a * 0.85 + flash, 0.0, 1.0));
}
"""

const BLUR := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float amount = 0.0;
void fragment() {
	vec3 c = textureLod(screen_tex, SCREEN_UV, amount * 3.4).rgb;
	c = mix(c, c * vec3(0.5, 0.56, 0.85), amount * 0.65);
	COLOR = vec4(c, 1.0);
}
"""

static var _blur_sh: Shader
static var _band_sh: Shader
static var _face_sh: Shader
static var _lines_sh: Shader


static func _shader(code: String, slot: String) -> Shader:
	var sh: Shader = _band_sh if slot == "band" else (_face_sh if slot == "face" else _lines_sh)
	if sh == null:
		sh = Shader.new()
		sh.code = code
		if slot == "band":
			_band_sh = sh
		elif slot == "face":
			_face_sh = sh
		else:
			_lines_sh = sh
	return sh


## Where the eyes sit in a portrait, as a fraction of its height from the top.
const EYE_LINE := 0.29

## Show a cut-in for player `p` (0 = you, bottom band from the left; 1 = rival, top band from
## the right). `key` is the character, `title` the big words, `sub` the small line under them.
## `hold` is how long it stays once it is in. Await it, or just call it and carry on.
static func play(host: Control, p: int, key: String, title: String, sub: String, color: Color, hold := 0.75, big := false) -> void:
	if host == null or not host.is_inside_tree():
		return
	var ci := CutIn.new()
	ci.set_anchors_preset(Control.PRESET_FULL_RECT)
	ci.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ci.z_index = 45
	host.add_child(ci)
	await ci._run(p, key, title, sub, color, hold, big)


func _run(p: int, key: String, title: String, sub: String, color: Color, hold: float, big: bool) -> void:
	var vs := get_viewport_rect().size
	var dir := 1.0 if p == 0 else -1.0
	# Your cut-in runs along the top of the picture and theirs along the bottom, each away
	# from that side's own monsters, so the summon or attack under it stays in view.
	var center := 0.2 if p == 0 else 0.78
	var half_h := 0.135 if big else 0.105
	var slant := -0.1
	# The big moments get the eye close-up: one band across the middle, the camera tight on the
	# duelist's eyes, and the field out of focus behind it.
	var eyes := big
	var blur: ColorRect = null
	var blur_m: ShaderMaterial = null
	if eyes:
		center = 0.46
		half_h = 0.165
		if _blur_sh == null:
			_blur_sh = Shader.new()
			_blur_sh.code = BLUR
		blur = ColorRect.new()
		blur.set_anchors_preset(Control.PRESET_FULL_RECT)
		blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
		blur_m = ShaderMaterial.new()
		blur_m.shader = _blur_sh
		blur_m.set_shader_parameter("amount", 0.0)
		blur.material = blur_m
		add_child(blur)
		create_tween().tween_method(func(v: float): blur_m.set_shader_parameter("amount", v), 0.0, 1.0, Settings.t(0.18))
	var band := ColorRect.new()
	band.set_anchors_preset(Control.PRESET_FULL_RECT)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bm := ShaderMaterial.new()
	bm.shader = _shader(BAND, "band")
	for kv in [["center", center], ["half_h", half_h], ["slant", slant], ["dir", dir], ["tint", color], ["progress", 0.0], ["fade", 1.0]]:
		bm.set_shader_parameter(kv[0], kv[1])
	band.material = bm
	add_child(band)
	# The duelist: the live 3D portrait when there is a model, the drawn one otherwise.
	var tex: Texture2D = Avatars.portrait(key, true)
	if tex == null:
		tex = Portraits.get_portrait(key)
	var face := TextureRect.new()
	face.texture = tex
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fh := vs.y * (half_h * 2.0 + 0.12)
	face.size = Vector2(fh * 0.8, fh)
	if eyes:
		# The whole portrait is as tall as the screen, so only the strip around the eyes
		# (about a quarter of the way down the picture) shows inside the band.
		face.size = Vector2(vs.y * 0.8, vs.y) * 2.05
	face.flip_h = p == 1
	var fm := ShaderMaterial.new()
	fm.shader = _shader(FACE, "face")
	for kv in [["center", center], ["half_h", half_h], ["slant", slant], ["tint", color], ["fade", 1.0], ["over", 0.0 if eyes else 0.05]]:
		fm.set_shader_parameter(kv[0], kv[1])
	face.material = fm
	var face_x := vs.x * 0.06 if p == 0 else vs.x * 0.94 - face.size.x
	var face_y := vs.y * (center + (0.05 if p == 0 else -0.05) - half_h - 0.1)
	if eyes:
		face_x = vs.x * (0.22 if p == 0 else 0.78) - face.size.x / 2.0
		face_y = vs.y * (center + (0.026 if p == 0 else -0.026)) - face.size.y * EYE_LINE
	face.position = Vector2(face_x - dir * vs.x * 0.35, face_y)
	add_child(face)
	# The words, leaning the same way as the band.
	var words := Control.new()
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.rotation = -0.056
	add_child(words)
	var tl := UITheme.label(title, 104 if big else 76, Color.WHITE, Comic.shout_font())
	tl.add_theme_color_override("font_outline_color", Comic.INK)
	tl.add_theme_constant_override("outline_size", 18)
	tl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	tl.add_theme_constant_override("shadow_offset_x", 5)
	tl.add_theme_constant_override("shadow_offset_y", 5)
	words.add_child(tl)
	var sl := UITheme.label(sub, 32, Comic.YELLOW, UITheme.title_font())
	sl.add_theme_color_override("font_outline_color", Comic.INK)
	sl.add_theme_constant_override("outline_size", 8)
	words.add_child(sl)
	await get_tree().process_frame
	if not is_inside_tree():
		return
	# Long names shrink to fit the space beside the portrait.
	var room := vs.x * (0.5 if eyes else 0.62)
	if tl.size.x > room:
		tl.scale = Vector2.ONE * (room / tl.size.x)
	if sl.size.x > room:
		sl.scale = Vector2.ONE * (room / sl.size.x)
	var tw_w := tl.size.x * tl.scale.x
	var sub_w := sl.size.x * sl.scale.x
	var text_x := face_x + face.size.x + 40.0 if p == 0 else face_x - 40.0 - maxf(tw_w, sub_w)
	if eyes:
		text_x = vs.x * 0.45 if p == 0 else vs.x * 0.55 - maxf(tw_w, sub_w)
	var text_y := vs.y * center - (tl.size.y * tl.scale.y + (sl.size.y if sub != "" else 0.0)) * 0.5 + 10.0
	tl.position = Vector2.ZERO
	sl.position = Vector2(6 if p == 0 else maxf(tw_w, sub_w) - sub_w - 6, tl.size.y * tl.scale.y - 6)
	if p == 1:
		tl.position.x = maxf(tw_w, sub_w) - tw_w
	words.position = Vector2(text_x + dir * vs.x * 0.5, text_y)
	words.modulate.a = 0.0
	Sfx.play("whoosh", -7.0, 1.1 if p == 0 else 0.95)
	var tin := create_tween().set_parallel()
	tin.tween_method(func(v: float): bm.set_shader_parameter("progress", v), 0.0, 1.0, Settings.t(0.22)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tin.tween_property(face, "position:x", face_x, Settings.t(0.3)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(Settings.t(0.05))
	tin.tween_property(words, "position:x", text_x, Settings.t(0.28)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(Settings.t(0.1))
	tin.tween_property(words, "modulate:a", 1.0, Settings.t(0.15)).set_delay(Settings.t(0.1))
	await tin.finished
	if not is_inside_tree():
		return
	# While it holds, everything keeps drifting a little: nothing on screen is ever frozen.
	var drift := create_tween().set_parallel()
	drift.tween_property(face, "position:x", face_x + dir * 14.0, Settings.t(hold))
	drift.tween_property(words, "position:x", text_x - dir * 22.0, Settings.t(hold))
	await drift.finished
	if not is_inside_tree():
		return
	var out := create_tween().set_parallel()
	var fade_all := func(v: float):
		bm.set_shader_parameter("fade", v)
		fm.set_shader_parameter("fade", v)
	out.tween_method(fade_all, 1.0, 0.0, Settings.t(0.2))
	if blur_m:
		out.tween_method(func(v: float): blur_m.set_shader_parameter("amount", v), 1.0, 0.0, Settings.t(0.2))
	out.tween_property(words, "modulate:a", 0.0, Settings.t(0.15))
	out.tween_property(words, "position:x", text_x - dir * vs.x * 0.2, Settings.t(0.2)).set_ease(Tween.EASE_IN)
	out.tween_property(face, "position:x", face_x + dir * vs.x * 0.12, Settings.t(0.2)).set_ease(Tween.EASE_IN)
	await out.finished
	queue_free()


## Radial speed lines and a flash around `at` (screen position): the hit lands.
static func impact(host: Control, at: Vector2, color: Color, strength := 1.0) -> void:
	if host == null or not host.is_inside_tree():
		return
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.z_index = 30
	var m := ShaderMaterial.new()
	m.shader = _shader(LINES, "lines")
	var vs := host.get_viewport_rect().size
	m.set_shader_parameter("focus", Vector2(at.x / maxf(1.0, vs.x), at.y / maxf(1.0, vs.y)))
	m.set_shader_parameter("tint", color)
	m.set_shader_parameter("amount", strength)
	r.material = m
	host.add_child(r)
	var tw := r.create_tween()
	tw.tween_method(func(v: float): m.set_shader_parameter("amount", v), strength, 0.0, Settings.t(0.2 + 0.25 * strength)).set_ease(Tween.EASE_OUT)
	tw.tween_callback(r.queue_free)
