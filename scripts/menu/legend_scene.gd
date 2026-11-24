class_name LegendScene
extends Control
## A short scene of Legendary Duels (0.75.0): a picture of the place, the two duelists standing
## left and right, and their words in a box at the bottom, one line at a time. Whoever speaks is
## lit, the other waits in the shade. Click, Space, E or Enter: the rest of the line, then the next.
## Esc or "Skip": straight to the end. No voices yet.

signal finished

var _lines: Array = []
var _i := -1
var _left_key := ""
var _right_key := ""
var _left: TextureRect
var _right: TextureRect
var _name: Label
var _name_box: PanelContainer
var _text: Label
var _typing: Tween
var _done := false


func _init(lines: Array, left_key: String, right_key: String, picture: String) -> void:
	_lines = lines
	_left_key = left_key
	_right_key = right_key
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(AcademyBackdrop.new(0.3, picture if ResourceLoader.exists(picture) else AcademyBackdrop.PICTURE))
	_left = _portrait(left_key, true)
	_right = _portrait(right_key, false)
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
	_next()
	if Array(OS.get_cmdline_user_args()).any(func(a): return str(a).begins_with("--legend-test")) and not "--legend-test=scene" in OS.get_cmdline_user_args():
		# (dev: the lines go by on their own)
		while not _done and is_inside_tree():
			await get_tree().create_timer(0.4).timeout
			_next()


## A duelist standing at one side, as tall as the screen allows, their back to the edge.
func _portrait(key: String, left: bool) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Portraits.get_portrait(key, true)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.anchor_top = 0.0
	t.anchor_bottom = 1.0
	t.offset_top = 40
	t.offset_bottom = -60      # (down behind the words: no hard edge where the picture ends)
	if left:
		t.anchor_left = 0.0
		t.anchor_right = 0.0
		t.offset_left = 20
		t.offset_right = 560
	else:
		t.anchor_left = 1.0
		t.anchor_right = 1.0
		t.offset_left = -560
		t.offset_right = -20
		t.flip_h = true
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(t)
	return t


func _next() -> void:
	_i += 1
	if _i >= _lines.size():
		_finish()
		return
	var ln: Array = _lines[_i]
	var who := str(ln[0])
	var txt := Loc.t(str(ln[1]))
	_name_box.visible = who != ""
	_name.text = str(Characters.get_char(who).get("name", who)) if who != "" else ""
	_text.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0) if who != "" else Color(1.0, 0.86, 0.55))
	_text.text = txt
	_text.visible_ratio = 0.0
	# The one speaking is lit and steps forward a little; the other waits in the shade.
	for side in [[_left, _left_key], [_right, _right_key]]:
		var on: bool = who == "" or str(side[1]) == who
		var tw := create_tween().set_parallel()
		tw.tween_property(side[0], "modulate", Color(1, 1, 1, 1) if on else Color(0.42, 0.45, 0.55, 1), 0.2)
		tw.tween_property(side[0], "scale", Vector2(1.03, 1.03) if on and who != "" else Vector2.ONE, 0.2)
		(side[0] as TextureRect).pivot_offset = (side[0] as TextureRect).size * Vector2(0.5, 1.0)
	if _typing:
		_typing.kill()
	_typing = create_tween()
	_typing.tween_property(_text, "visible_ratio", 1.0, clampf(txt.length() * 0.022, 0.25, 2.2))
	Sfx.play("blip", -16.0, 1.2)


func _advance() -> void:
	if _done:
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
