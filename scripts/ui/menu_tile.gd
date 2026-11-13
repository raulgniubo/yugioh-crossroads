class_name MenuTile
extends Button
## A big card on the home screen: a colored kicker, a title, a line under it, a huge faint
## symbol in the corner and an optional badge. Lifts and lights up under the pointer or focus.

var color := UITheme.ACCENT
var _hover := 0.0
var _target := 0.0
var _box: StyleBoxFlat
var _glyph: Label
var _title: Label
var _bar: ColorRect
var _sheen: ColorRect


func _init(kicker: String, title_text: String, subtitle: String, tint: Color, glyph: String, size: Vector2, badge := "", big := false) -> void:
	color = tint
	custom_minimum_size = size
	self.size = size
	focus_mode = Control.FOCUS_ALL
	clip_contents = true
	_box = StyleBoxFlat.new()
	_box.bg_color = Color(0.035, 0.05, 0.09, 0.9)
	_box.set_corner_radius_all(22)
	_box.border_color = Color(tint, 0.35)
	_box.set_border_width_all(2)
	_box.shadow_color = Color(0, 0, 0, 0.5)
	_box.shadow_size = 14
	_box.shadow_offset = Vector2(0, 6)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(st, _box)
	# A wash of the tile's color from the top-left corner.
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([Color(tint, 0.34), Color(tint, 0.07), Color(tint, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 1)
	var wash := TextureRect.new()
	wash.texture = gt
	wash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wash.stretch_mode = TextureRect.STRETCH_SCALE
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.offset_left = 2
	wash.offset_top = 2
	wash.offset_right = -2
	wash.offset_bottom = -2
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)
	_glyph = UITheme.label(glyph, int(size.y * (0.95 if big else 1.05)), Color(tint.lightened(0.3), 0.13), UITheme.title_font())
	_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_glyph.offset_right = -14
	add_child(_glyph)
	_bar = ColorRect.new()
	_bar.color = tint
	_bar.position = Vector2(0, 22)
	_bar.size = Vector2(5, size.y - 44)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bar)
	var pad := 28.0
	var k := UITheme.label(kicker.to_upper(), 16 if not big else 18, tint.lightened(0.35), UITheme.semi_font())
	k.position = Vector2(pad, 18 if not big else 24)
	k.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(k)
	_title = UITheme.label(title_text, 38 if not big else 54, Color.WHITE, UITheme.title_font())
	_title.position = Vector2(pad, 36 if not big else 50)
	_title.size = Vector2(size.x - pad * 2, 60 if not big else 80)
	_title.clip_text = true
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)
	var s := UITheme.label(subtitle, 16 if not big else 19, Color(0.8, 0.87, 0.97, 0.78))
	s.position = Vector2(pad + 2, size.y - (58 if not big else 76))
	s.size = Vector2(size.x - pad * 2 - 6, 46 if not big else 56)
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	s.clip_text = true
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(s)
	if badge != "":
		var b := UITheme.label(badge, 15, Color(0.03, 0.05, 0.09), UITheme.semi_font())
		var bb := StyleBoxFlat.new()
		bb.bg_color = tint.lightened(0.25)
		bb.set_corner_radius_all(10)
		bb.content_margin_left = 10
		bb.content_margin_right = 10
		bb.content_margin_top = 2
		bb.content_margin_bottom = 2
		b.add_theme_stylebox_override("normal", bb)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(b)
		b.reset_size()
		b.position = Vector2(size.x - b.size.x - 18, 16)
	# A band of light that crosses the tile when it wakes up.
	_sheen = ColorRect.new()
	_sheen.color = Color(1, 1, 1, 0.07)
	_sheen.size = Vector2(70, size.y * 2.0)
	_sheen.rotation = 0.35
	_sheen.position = Vector2(-140, -size.y * 0.4)
	_sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sheen)
	pivot_offset = size / 2.0
	mouse_entered.connect(func(): _wake())
	mouse_exited.connect(func(): _target = 1.0 if has_focus() else 0.0)
	focus_entered.connect(func(): _wake())
	focus_exited.connect(func(): _target = 0.0)


func _wake() -> void:
	if _target < 0.5:
		_sheen.position.x = -140
		create_tween().tween_property(_sheen, "position:x", size.x + 80, 0.45).set_trans(Tween.TRANS_SINE)
	_target = 1.0


func _process(delta: float) -> void:
	_hover = move_toward(_hover, _target, delta * 7.0)
	var e := ease(_hover, -2.0)
	scale = Vector2.ONE * (1.0 + 0.025 * e)
	z_index = 1 if e > 0.01 else 0
	_box.border_color = Color(color.lerp(Color.WHITE, 0.3 * e), 0.35 + 0.65 * e)
	_box.bg_color = Color(0.035, 0.05, 0.09, 0.9).lerp(Color(color.darkened(0.78), 0.96), e)
	_box.shadow_color = Color(0, 0, 0, 0.5).lerp(Color(color, 0.55), e)
	_box.shadow_size = int(14 + 14 * e)
	_glyph.add_theme_color_override("font_color", Color(color.lightened(0.3), 0.13 + 0.2 * e))
	_bar.size.x = 5.0 + 4.0 * e
