class_name DpPurse
extends PanelContainer
## Your Duel Points, always on screen. Counts up or down when the number changes and shows how
## much was just earned or spent.

var _shown := 0.0
var _target := 0
var _num: Label
var _delta: Label
var _delta_t := 0.0
var compact := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.09, 0.07, 0.02, 0.9), 14, Color(UITheme.GOLD, 0.85)))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(h)
	var coin := Control.new()
	coin.custom_minimum_size = Vector2(30, 30)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin.draw.connect(func():
		coin.draw_circle(Vector2(15, 15), 14.0, Color("b8860b"))
		coin.draw_circle(Vector2(15, 15), 11.5, UITheme.GOLD)
		coin.draw_colored_polygon(PackedVector2Array([Vector2(15, 6), Vector2(21, 15), Vector2(15, 24), Vector2(9, 15)]), Color("8a5a00")))
	h.add_child(coin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	if not compact:
		v.add_child(UITheme.label("DUEL POINTS", 14, Color(UITheme.GOLD, 0.8), UITheme.semi_font()))
	_num = UITheme.label("", 30, UITheme.GOLD, UITheme.title_font())
	v.add_child(_num)
	_delta = UITheme.label("", 22, Color("7dffb0"), UITheme.title_font())
	_delta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_delta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_delta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_delta.modulate.a = 0.0
	h.add_child(_delta)
	_target = Collection.dp
	_shown = float(_target)
	_num.text = _fmt(_target)
	Collection.changed.connect(_on_changed)


static func _fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


func _on_changed() -> void:
	if Collection.dp == _target:
		return
	var d := Collection.dp - _target
	_target = Collection.dp
	_delta.text = ("+%s" if d > 0 else "%s") % _fmt(d)
	_delta.add_theme_color_override("font_color", Color("7dffb0") if d > 0 else Color("ff8a8a"))
	_delta.modulate.a = 1.0
	_delta_t = 2.2
	pivot_offset = size / 2.0
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.08, 1.08), 0.1)
	tw.tween_property(self, "scale", Vector2.ONE, 0.25)


func _process(delta: float) -> void:
	if _num == null:
		return
	if absf(_shown - _target) > 0.5:
		_shown = lerpf(_shown, float(_target), clampf(delta * 7.0, 0.0, 1.0))
		if absf(_shown - _target) <= 0.5:
			_shown = float(_target)
		_num.text = _fmt(int(round(_shown)))
	if _delta_t > 0.0:
		_delta_t -= delta
		if _delta_t < 0.6:
			_delta.modulate.a = maxf(0.0, _delta_t / 0.6)
