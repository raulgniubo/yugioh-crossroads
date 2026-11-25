class_name LegendScene
extends Control
## A short scene of Legendary Duels: a picture of the place, the two duelists at the sides and their
## words in a box at the bottom, one line at a time. Click, Space, E or Enter: the rest of the line,
## then the next. Esc or "Skip": straight to the end.
## (0.75.2) Shot like a film: black bars, the place behind out of focus, the duelists big with their
## legs running off the bottom into shadow. The one speaking is in focus with a rim of light in their
## color and a soft light of it behind them; the other is a step darker and softly out of focus. The scene before a duel opens with a VS
## card. Every line with a speaker is voiced (Voices.say, the English line is the key).

signal finished

## The figure: a rim of light in the character's color on the edges that face the light (from behind
## and above, towards the middle of the screen), and a camera focus: the one listening is a little
## darker and softly out of focus, never grayed out.
const FIG_SHADER := """shader_type canvas_item;
uniform vec4 rim_col : source_color = vec4(1.0);
uniform float rim = 1.0;
uniform vec2 light_dir = vec2(0.9, -0.45);
uniform float focus = 1.0;
uniform float bright = 1.0;
uniform float sat = 1.0;
void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	vec4 c = texture(TEXTURE, UV);
	float r = (1.0 - focus) * 3.0;
	if (r > 0.05) {
		vec4 acc = c;
		for (int i = 0; i < 8; i++) {
			float an = float(i) * 0.7854;
			acc += texture(TEXTURE, UV + vec2(cos(an), sin(an)) * px * r);
			acc += texture(TEXTURE, UV + vec2(cos(an + 0.39), sin(an + 0.39)) * px * r * 2.0);
		}
		c = acc / 17.0;
	}
	vec2 d = normalize(light_dir) * px;
	float a1 = texture(TEXTURE, UV + d * 4.0).a;
	float a2 = texture(TEXTURE, UV + d * 10.0).a;
	float edge = clamp(c.a - 0.55 * a1 - 0.45 * a2, 0.0, 1.0);
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 col = mix(vec3(g), c.rgb, sat) * bright;
	col += rim_col.rgb * edge * rim * 1.3;
	COLOR = vec4(col, c.a) * COLOR;
}"""

## A soft dark shadow of the figure behind it, so it stands off the picture behind.
const SHADOW_SHADER := """shader_type canvas_item;
uniform float amount = 0.55;
uniform float spread = 9.0;
void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE * spread;
	float a = texture(TEXTURE, UV).a;
	for (int i = 0; i < 12; i++) {
		float an = float(i) * 0.5236;
		a += texture(TEXTURE, UV + vec2(cos(an), sin(an)) * px).a;
		a += texture(TEXTURE, UV + vec2(cos(an), sin(an)) * px * 2.0).a;
	}
	COLOR = vec4(0.0, 0.0, 0.02, a / 25.0 * amount);
}"""

## The place behind them out of focus, darker and cooler, darker still at the corners.
const BG_SHADER := """shader_type canvas_item;
uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform float radius = 7.0;
uniform float dark = 0.62;
void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * radius;
	vec3 acc = texture(screen, SCREEN_UV).rgb;
	float n = 1.0;
	for (int ring = 1; ring <= 3; ring++) {
		float rr = float(ring) * 0.9;
		float tw = 1.0 / float(ring);
		for (int i = 0; i < 12; i++) {
			float an = float(i) * 0.5236 + float(ring) * 0.26;
			acc += texture(screen, SCREEN_UV + vec2(cos(an), sin(an)) * px * rr).rgb * tw;
			n += tw;
		}
	}
	vec3 c = acc / n;
	vec2 q = SCREEN_UV - 0.5;
	float vig = clamp(1.0 - dot(q * vec2(1.0, 1.3), q * vec2(1.0, 1.3)) * 1.6, 0.0, 1.0);
	c = c * dark * (0.35 + 0.65 * vig);
	c *= vec3(0.86, 0.9, 1.08);
	COLOR = vec4(c, 1.0);
}"""

var _lines: Array = []
var _i := -1
var _left_key := ""
var _right_key := ""
var _sides: Array = []      # one Dictionary per side: holder, fig, shadow, light, left, key, col, on, want, in
var _name: Label
var _name_box: PanelContainer
var _box: PanelContainer
var _text: Label
var _typing: Tween
var _done := false
var _versus := false
var _vs_layer: Control
var _t := 0.0
var _dev := Array(OS.get_cmdline_user_args()).any(func(a): return str(a).begins_with("--legend-test"))


func _init(lines: Array, left_key: String, right_key: String, picture: String, versus := false) -> void:
	_lines = lines
	_left_key = left_key
	_right_key = right_key
	_versus = versus
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bd := AcademyBackdrop.new(0.0, picture if ResourceLoader.exists(picture) else AcademyBackdrop.PICTURE)
	add_child(bd)
	if bd.get("_side") is CanvasItem:
		(bd.get("_side") as CanvasItem).visible = false      # (its dark left side is for menus, not for a scene)
	var blur := ColorRect.new()
	var bm := ShaderMaterial.new()
	var bs := Shader.new()
	bs.code = BG_SHADER
	bm.shader = bs
	blur.material = bm
	blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(blur)
	_portrait(left_key, true)
	_portrait(right_key, false)
	# The ground: the bottom of the screen goes dark, so the figures end in shadow, not in a cut.
	var ground := TextureRect.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([Color(0.01, 0.015, 0.04, 0.0), Color(0.01, 0.015, 0.04, 0.6), Color(0.01, 0.015, 0.04, 0.97)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	ground.texture = gt
	ground.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ground.stretch_mode = TextureRect.STRETCH_SCALE
	ground.anchor_right = 1.0
	ground.anchor_top = 0.6
	ground.anchor_bottom = 1.0
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)
	# Black bars at the top and the bottom, as in a film.
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color(0, 0, 0, 1)
		bar.anchor_right = 1.0
		bar.anchor_top = 0.0 if top else 1.0
		bar.anchor_bottom = 0.0 if top else 1.0
		bar.offset_top = 0.0 if top else -54.0
		bar.offset_bottom = 54.0 if top else 0.0
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bar)
		bar.create_tween().tween_property(bar, "offset_" + ("top" if top else "bottom"), bar.offset_top if top else 0.0, 0.5) \
				.from(-54.0 if top else 54.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# The words: a dark box across the bottom, the speaker's name on a tab above it.
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _box_style(Color(UITheme.GOLD, 0.7)))
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = -560
	box.offset_right = 560
	box.offset_top = -236
	box.offset_bottom = -72
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_box = box
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 34)
	m.add_theme_constant_override("margin_top", 30)
	m.add_theme_constant_override("margin_bottom", 18)
	box.add_child(m)
	_text = UITheme.label("", 27, Color(0.95, 0.97, 1.0))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	m.add_child(_text)
	_name_box = PanelContainer.new()
	_name_box.add_theme_stylebox_override("panel", _tab_style(UITheme.GOLD))
	_name_box.anchor_left = 0.5
	_name_box.anchor_top = 1.0
	_name_box.anchor_bottom = 1.0
	_name_box.offset_left = -540
	_name_box.offset_top = -258
	_name_box.offset_bottom = -218
	_name_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_box.visible = false
	add_child(_name_box)
	var nm := MarginContainer.new()
	nm.add_theme_constant_override("margin_left", 18)
	nm.add_theme_constant_override("margin_right", 18)
	_name_box.add_child(nm)
	_name = UITheme.label("", 23, Color.WHITE, UITheme.title_font())
	_name.add_theme_constant_override("outline_size", 6)
	_name.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	nm.add_child(_name)
	var skip := Button.new()
	skip.text = Loc.t("Skip")
	skip.focus_mode = Control.FOCUS_NONE
	skip.anchor_left = 1.0
	skip.anchor_right = 1.0
	skip.offset_left = -170
	skip.offset_right = -36
	skip.offset_top = 70
	skip.offset_bottom = 116
	skip.add_theme_font_size_override("font_size", 20)
	skip.pressed.connect(_finish)
	add_child(skip)
	var hint := UITheme.label(Loc.t("Click or Space: next"), 16, UITheme.TEXT_DIM)
	hint.anchor_left = 0.5
	hint.anchor_right = 0.5
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = 300
	hint.offset_right = 560
	hint.offset_top = -44
	hint.offset_bottom = -18
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(hint)


func _ready() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	_layout()
	for k in [_left_key, _right_key]:
		Avatars.portrait_warm(k, ["chat", "listen"])
	if _versus:
		_box.modulate.a = 0.0      # (the words come in after the VS card)
		_show_versus()
		await get_tree().create_timer(999.0 if "--legend-vs-hold" in OS.get_cmdline_user_args() else 1.7).timeout
		if not is_inside_tree() or _done:
			return
		_hide_versus()
	if _i < 0:
		_next()
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--legend-line="):
			for _k in int(str(a).get_slice("=", 1)):
				_next()
	if Array(OS.get_cmdline_user_args()).any(func(a): return str(a).begins_with("--legend-test")) and not "--legend-test=scene" in OS.get_cmdline_user_args():
		# (dev: the lines go by on their own)
		while not _done and is_inside_tree():
			await get_tree().create_timer(0.4).timeout
			_next()


## The words' box: dark glass, a line of the speaker's color along its top.
func _box_style(accent: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.015, 0.02, 0.05, 0.86)
	sb.set_corner_radius_all(14)
	sb.border_width_top = 3
	sb.border_color = accent
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 18
	sb.anti_aliasing = true
	return sb


## The name tab: filled with the speaker's color.
func _tab_style(c: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(c.darkened(0.25), 0.96)
	sb.set_corner_radius_all(9)
	sb.border_width_bottom = 2
	sb.border_color = c.lightened(0.3)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 8
	return sb


## A duelist at one side of the screen: a soft light of their color behind them, their shadow, then
## the figure with its rim of light. Placed by _layout, moved by _process.
func _portrait(key: String, left: bool) -> void:
	var col: Color = Characters.get_char(key).get("color", UITheme.ACCENT)
	var tex := Portraits.get_portrait(key, true)
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	var light := TextureRect.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	g.colors = PackedColorArray([Color(col.lightened(0.2), 0.75), Color(col, 0.25), Color(col, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 256
	gt.height = 256
	light.texture = gt
	light.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	light.stretch_mode = TextureRect.STRETCH_SCALE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	light.material = add
	light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(light)
	var shadow := TextureRect.new()
	shadow.texture = tex
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.stretch_mode = TextureRect.STRETCH_SCALE
	shadow.flip_h = not left
	var shm := ShaderMaterial.new()
	var shs := Shader.new()
	shs.code = SHADOW_SHADER
	shm.shader = shs
	shadow.material = shm
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(shadow)
	var fig := TextureRect.new()
	fig.texture = tex
	fig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fig.stretch_mode = TextureRect.STRETCH_SCALE
	fig.flip_h = not left
	var fm := ShaderMaterial.new()
	var fs := Shader.new()
	fs.code = FIG_SHADER
	fm.shader = fs
	fm.set_shader_parameter("rim_col", col.lightened(0.45))
	fig.material = fm
	fig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(fig)
	_sides.append({"holder": holder, "fig": fig, "shadow": shadow, "light": light, "left": left, "key": key, "col": col,
			"on": 0.6, "want": 0.6, "in": 0.0})


## Where everything stands for this window size (again on every resize).
func _layout() -> void:
	var w := size.x
	var h := size.y
	if w < 10 or h < 10:
		return
	for sd in _sides:
		var fig: TextureRect = sd["fig"]
		var tex: Texture2D = fig.texture
		var asp := float(tex.get_width()) / maxf(1.0, float(tex.get_height())) if tex else 0.8
		var fh := h * 1.32
		var fw := fh * asp
		var left: bool = sd["left"]
		# (in from its edge; the bottom of the picture is below the screen)
		var cx := w * 0.2 if left else w * 0.8
		var x := cx - fw * 0.5
		var y := h - fh * 0.86
		var holder: Control = sd["holder"]
		holder.position = Vector2.ZERO
		holder.size = Vector2(w, h)
		holder.pivot_offset = Vector2(cx, h)
		fig.position = Vector2(x, y)
		fig.size = Vector2(fw, fh)
		var shadow: TextureRect = sd["shadow"]
		shadow.position = Vector2(x + (-14.0 if left else 14.0), y + 10.0)
		shadow.size = Vector2(fw, fh)
		var light: TextureRect = sd["light"]
		light.size = Vector2(fw * 1.25, fh * 0.95)
		light.position = Vector2(cx - light.size.x * 0.5, y + fh * 0.05)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()


func _process(delta: float) -> void:
	_t += delta
	for k in _sides.size():
		var sd: Dictionary = _sides[k]
		sd["in"] = minf(1.0, float(sd["in"]) + delta * 2.4)
		sd["on"] = move_toward(float(sd["on"]), float(sd["want"]), delta * 3.5)
		var e := 1.0 - pow(1.0 - float(sd["in"]), 3.0)
		var on := float(sd["on"])
		var holder: Control = sd["holder"]
		# Slides in from its edge at the start; the one speaking stands a little further in.
		var out := (1.0 - e) * size.x * 0.3 + (1.0 - on) * 26.0
		holder.position.x = -out if sd["left"] else out
		var breath := 1.0 + 0.005 * sin(_t * 1.6 + k * 1.9)
		holder.scale = Vector2(1.0, breath) * (0.96 + 0.06 * on)
		holder.modulate = Color(1, 1, 1, e)
		# The camera's focus: the one speaking sharp and in full light, the other a step darker and soft.
		var fm := (sd["fig"] as TextureRect).material as ShaderMaterial
		fm.set_shader_parameter("bright", lerpf(0.66, 1.04, on))
		fm.set_shader_parameter("sat", lerpf(0.82, 1.06, on))
		fm.set_shader_parameter("focus", lerpf(0.3, 1.0, on))
		fm.set_shader_parameter("rim", lerpf(0.15, 1.0, on))
		var pulse := 0.92 + 0.08 * sin(_t * 1.3 + k)
		(sd["light"] as CanvasItem).modulate = Color(1, 1, 1, clampf((on - 0.3) / 0.7, 0.0, 1.0) * 0.8 * pulse)


## The opening card: both names in their colors and a VS between them, gone after a moment.
func _show_versus() -> void:
	_vs_layer = Control.new()
	_vs_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vs_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vs_layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.3)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vs_layer.add_child(dim)
	var keys := [_left_key, _right_key]
	for i in 2:
		var d := Characters.get_char(keys[i])
		var n := UITheme.label(str(d.get("name", keys[i])).to_upper(), 60, Color(d.get("color", Color.WHITE)).lightened(0.4), UITheme.title_font())
		n.add_theme_constant_override("outline_size", 10)
		n.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		n.anchor_left = 0.5
		n.anchor_right = 0.5
		n.anchor_top = 0.4
		n.anchor_bottom = 0.4
		n.offset_left = -760 if i == 0 else 95
		n.offset_right = -95 if i == 0 else 760
		n.offset_top = -45
		n.offset_bottom = 45
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if i == 0 else HORIZONTAL_ALIGNMENT_LEFT
		n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_vs_layer.add_child(n)
		n.modulate.a = 0.0
		var tw := n.create_tween().set_parallel()
		tw.tween_property(n, "modulate:a", 1.0, 0.25).set_delay(0.15)
		tw.tween_property(n, "offset_left", n.offset_left, 0.35).from(n.offset_left + (-140.0 if i == 0 else 140.0)).set_delay(0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(n, "offset_right", n.offset_right, 0.35).from(n.offset_right + (-140.0 if i == 0 else 140.0)).set_delay(0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var vs := UITheme.label("VS", 120, UITheme.GOLD, UITheme.title_font())
	vs.add_theme_constant_override("outline_size", 14)
	vs.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.0, 0.9))
	vs.anchor_left = 0.5
	vs.anchor_right = 0.5
	vs.anchor_top = 0.4
	vs.anchor_bottom = 0.4
	vs.offset_left = -90
	vs.offset_right = 90
	vs.offset_top = -80
	vs.offset_bottom = 80
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vs.pivot_offset = Vector2(90, 80)
	_vs_layer.add_child(vs)
	vs.scale = Vector2(2.2, 2.2)
	vs.modulate.a = 0.0
	var t2 := vs.create_tween().set_parallel()
	t2.tween_property(vs, "scale", Vector2.ONE, 0.3).set_delay(0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t2.tween_property(vs, "modulate:a", 1.0, 0.15).set_delay(0.3)
	Sfx.play("blip", -8.0, 0.6)


func _hide_versus() -> void:
	if _vs_layer == null or not is_instance_valid(_vs_layer):
		return
	var l := _vs_layer
	_vs_layer = null
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 0.0, 0.25)
	tw.tween_callback(l.queue_free)


func _next() -> void:
	_hide_versus()
	if _box.modulate.a < 1.0:
		_box.create_tween().tween_property(_box, "modulate:a", 1.0, 0.2)
	_i += 1
	if _i >= _lines.size():
		_finish()
		return
	var ln: Array = _lines[_i]
	var who := str(ln[0])
	var txt := Loc.t(str(ln[1]))
	_name_box.visible = who != ""
	_name.text = str(Characters.get_char(who).get("name", who)) if who != "" else ""
	# The name tab sits on the speaker's side of the box, in their color.
	var right_side := who != "" and who == _right_key and who != _left_key
	_name_box.anchor_left = 0.5
	_name_box.anchor_right = 0.5
	_name_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN if right_side else Control.GROW_DIRECTION_END
	_name_box.offset_left = 530 if right_side else -530
	_name_box.offset_right = 530 if right_side else -530
	var c: Color = Characters.get_char(who).get("color", UITheme.GOLD) if who != "" else UITheme.GOLD
	_name_box.add_theme_stylebox_override("panel", _tab_style(c))
	_box.add_theme_stylebox_override("panel", _box_style(Color(c.lightened(0.2), 0.9)))
	_text.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0) if who != "" else Color(1.0, 0.86, 0.55))
	_text.text = txt
	_text.visible_ratio = 0.0
	# The one speaking is lit and steps forward; the other waits in the shade (a narrator: both half lit).
	for sd in _sides:
		sd["want"] = 0.6 if who == "" else (1.0 if str(sd["key"]) == who else 0.0)
	# They move: the one speaking talks with their hands, the other listens.
	if who != "":
		for sd in _sides:
			var k := str(sd["key"])
			var mo := "chat" if k == who else "listen"
			var moved := Avatars.portrait_act(k, mo)
			if _dev:
				print("LEGEND ACT %s %s -> %s" % [k, mo, moved])
	# Their voice (the line before is cut: one voice at a time, and a click means "next").
	Voices.hush(true)
	if who != "":
		Voices.say(who, str(ln[1]), false, true)
	if _typing:
		_typing.kill()
	_typing = create_tween()
	_typing.tween_property(_text, "visible_ratio", 1.0, clampf(txt.length() * 0.022, 0.25, 2.2))
	Sfx.play("blip", -16.0, 1.2)


func _advance() -> void:
	if _done:
		return
	if _vs_layer != null:
		_next()
		return
	if _typing and _typing.is_running():
		_typing.kill()
		_text.visible_ratio = 1.0
		return
	_next()


func _finish() -> void:
	if _done:
		return
	_done = true
	Voices.hush(true)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	await tw.finished
	finished.emit()
	queue_free()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish()
	elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_E, KEY_ENTER]) \
			or (event is InputEventJoypadButton and event.pressed and Pad.b(event) == JOY_BUTTON_A):
		get_viewport().set_input_as_handled()
		_advance()
