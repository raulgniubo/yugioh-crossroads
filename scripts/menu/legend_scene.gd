class_name LegendScene
extends Control
## A short scene of Legendary Duels: a picture of the place, the two duelists at the sides and their
## words in a box at the bottom, one line at a time. Click, Space, E or Enter: the rest of the line,
## then the next. Esc or "Skip": straight to the end.
## (0.75.1) The duelists stand big, their legs running off the bottom of the screen into shadow, with
## a slanted slab of their color and a soft glow of it behind them, so nobody floats. Whoever speaks
## is lit and steps forward; the other waits in the shade. The scene before a duel opens with a VS
## card. Every line with a speaker is voiced (Voices.say, the English line is the key).

signal finished

const AURA_SHADER := """shader_type canvas_item;
uniform vec4 tint : source_color = vec4(1.0);
uniform float spread = 6.0;
void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE * spread;
	float a = texture(TEXTURE, UV).a * 0.2;
	for (int i = 0; i < 12; i++) {
		float an = float(i) * 0.5236;
		vec2 d = vec2(cos(an), sin(an)) * px;
		a += texture(TEXTURE, UV + d).a * 0.0667;
		a += texture(TEXTURE, UV + d * 2.2).a * 0.0667;
	}
	COLOR = vec4(tint.rgb, clamp(a, 0.0, 1.0) * tint.a);
}"""

var _lines: Array = []
var _i := -1
var _left_key := ""
var _right_key := ""
var _sides: Array = []      # one Dictionary per side: holder, fig, aura, slab, left, col, on, want, in
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
	add_child(AcademyBackdrop.new(0.3, picture if ResourceLoader.exists(picture) else AcademyBackdrop.PICTURE))
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
	# The words: a dark box across the bottom, the speaker's name on a tab above it.
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.045, 0.1, 0.9), 20, Color(UITheme.GOLD, 0.45)))
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = -560
	box.offset_right = 560
	box.offset_top = -230
	box.offset_bottom = -40
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
	_name_box.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.1, 0.07, 0.02, 0.95), 10, Color(UITheme.GOLD, 0.8)))
	_name_box.anchor_left = 0.5
	_name_box.anchor_top = 1.0
	_name_box.anchor_bottom = 1.0
	_name_box.offset_left = -540
	_name_box.offset_top = -254
	_name_box.offset_bottom = -212
	_name_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_box.visible = false
	add_child(_name_box)
	var nm := MarginContainer.new()
	nm.add_theme_constant_override("margin_left", 18)
	nm.add_theme_constant_override("margin_right", 18)
	_name_box.add_child(nm)
	_name = UITheme.label("", 24, UITheme.GOLD, UITheme.title_font())
	nm.add_child(_name)
	var skip := Button.new()
	skip.text = Loc.t("Skip")
	skip.focus_mode = Control.FOCUS_NONE
	skip.anchor_left = 1.0
	skip.anchor_right = 1.0
	skip.offset_left = -170
	skip.offset_right = -36
	skip.offset_top = 32
	skip.offset_bottom = 82
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
	hint.offset_top = -36
	hint.offset_bottom = -12
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


## A duelist at one side of the screen: a slanted slab of their color, then a soft glow of that
## color around the figure, then the figure. Placed by _layout, moved by _process.
func _portrait(key: String, left: bool) -> void:
	var col: Color = Characters.get_char(key).get("color", UITheme.ACCENT)
	var tex := Portraits.get_portrait(key, true)
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	var slab := Polygon2D.new()
	holder.add_child(slab)
	var aura := TextureRect.new()
	aura.texture = tex
	aura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	aura.stretch_mode = TextureRect.STRETCH_SCALE
	aura.flip_h = not left
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = AURA_SHADER
	sm.shader = sh
	sm.set_shader_parameter("tint", Color(col.lightened(0.3), 0.0))
	aura.material = sm
	aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(aura)
	var fig := TextureRect.new()
	fig.texture = tex
	fig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fig.stretch_mode = TextureRect.STRETCH_SCALE
	fig.flip_h = not left
	fig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(fig)
	_sides.append({"holder": holder, "fig": fig, "aura": aura, "slab": slab, "left": left, "key": key, "col": col,
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
		# (in from its edge; the bottom fifth of the picture is below the screen)
		var cx := w * 0.17 if left else w * 0.83
		var x := cx - fw * 0.5
		var y := h - fh * 0.86
		var holder: Control = sd["holder"]
		holder.position = Vector2.ZERO
		holder.size = Vector2(w, h)
		holder.pivot_offset = Vector2(cx, h)
		var aura: TextureRect = sd["aura"]
		for n in [fig, aura]:
			(n as Control).position = Vector2(x, y)
			(n as Control).size = Vector2(fw, fh)
		aura.pivot_offset = Vector2(fw * 0.5, fh)
		aura.scale = Vector2(1.02, 1.01)
		# The slab: a slanted band from the top of the screen to the bottom, behind the figure.
		var bw := w * 0.15
		var lean := h * 0.2 * (1.0 if left else -1.0)
		var slab: Polygon2D = sd["slab"]
		slab.polygon = PackedVector2Array([Vector2(cx - bw * 0.5 + lean, 0), Vector2(cx + bw * 0.5 + lean, 0),
				Vector2(cx + bw * 0.5 - lean, h), Vector2(cx - bw * 0.5 - lean, h)])
		var c: Color = sd["col"]
		slab.vertex_colors = PackedColorArray([Color(c, 0.0), Color(c, 0.0), Color(c.darkened(0.15), 0.55), Color(c.darkened(0.15), 0.55)])


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()


func _process(delta: float) -> void:
	_t += delta
	for k in _sides.size():
		var sd: Dictionary = _sides[k]
		sd["in"] = minf(1.0, float(sd["in"]) + delta * 2.4)
		sd["on"] = move_toward(float(sd["on"]), float(sd["want"]), delta * 4.0)
		var e := 1.0 - pow(1.0 - float(sd["in"]), 3.0)
		var on := float(sd["on"])
		var holder: Control = sd["holder"]
		# Slides in from its edge at the start; the one speaking stands a little further in.
		var out := (1.0 - e) * size.x * 0.3 + (1.0 - on) * 30.0
		holder.position.x = -out if sd["left"] else out
		var breath := 1.0 + 0.005 * sin(_t * 1.6 + k * 1.9)
		holder.scale = Vector2(1.0, breath) * (0.95 + 0.09 * on)
		holder.modulate = Color(1, 1, 1, e)
		# (the one listening goes dark and cold, the one speaking is in full light with their glow)
		(sd["fig"] as CanvasItem).self_modulate = Color(0.26, 0.29, 0.38).lerp(Color.WHITE, on)
		(sd["slab"] as CanvasItem).self_modulate = Color(1, 1, 1, 0.15 + 0.85 * on)
		var pulse := 0.85 + 0.15 * sin(_t * 2.4 + k)
		var c: Color = Color(sd["col"]).lightened(0.3)
		((sd["aura"] as TextureRect).material as ShaderMaterial).set_shader_parameter("tint", Color(c, (0.85 * on * on) * pulse))


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
	_name_box.offset_left = 540 if right_side else -540
	_name_box.offset_right = 540 if right_side else -540
	if who != "":
		_name.add_theme_color_override("font_color", Color(Characters.get_char(who).get("color", UITheme.GOLD)).lightened(0.45))
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
