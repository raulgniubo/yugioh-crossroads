class_name HomeTile
extends Button
## A tile of the home screen: one of the game's own pictures (the same ones the mode's own screen
## shows) under a dark veil, the mode's name over it, and a thin edge in the mode's colour. The
## picture stays still (moving pictures read as stutter on big screens); hovered or focused, the
## edge lights up.

var col := UITheme.ACCENT
var _clip: Panel
var _pics: Array = []            # Textures
var _a: TextureRect
var _b: TextureRect
var _hot := false
var _badge := ""
var _big := false
var _hint := ""
var _over: Control               # drawn on top of the picture: the edge, the frame, the badge, the button


## `pics`: res:// paths (the first one is shown; the rest are kept for set_picture). `big`: the Continue card (larger words).
## `hint`: a small call to action in the corner ("▶ Continue").
func _init(over: String, title: String, sub: String, color: Color, pics: Array, size_px: Vector2, badge := "", big := false, hint := "") -> void:
	col = color
	_badge = badge
	_big = big
	_hint = hint
	custom_minimum_size = size_px
	size = size_px
	flat = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())
	_clip = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.04, 0.1)
	sb.set_corner_radius_all(18 if big else 14)
	_clip.add_theme_stylebox_override("panel", sb)
	_clip.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_clip)
	for p in pics:
		if ResourceLoader.exists(str(p)):
			_pics.append(UiPictures.thumb(str(p)))
	_a = _pic_rect()
	_b = _pic_rect()
	_b.modulate.a = 0.0
	if not _pics.is_empty():
		_a.texture = _pics[0]
	# The veil: dark where the words are (left and bottom), clear towards the top right.
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	var deep := Color(0.02, 0.03, 0.08)
	g.colors = PackedColorArray([Color(deep, 0.93), Color(deep, 0.72 if big else 0.62), Color(deep, 0.12 if big else 0.22)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0.7)
	gt.fill_to = Vector2(1, 0.2)
	gt.width = 128
	gt.height = 64
	var veil := TextureRect.new()
	veil.texture = gt
	veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	veil.stretch_mode = TextureRect.STRETCH_SCALE
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.add_child(veil)
	# The words, bottom left.
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0 if not big else 2)
	v.anchor_top = 1.0
	v.anchor_bottom = 1.0
	v.anchor_right = 1.0
	v.grow_vertical = Control.GROW_DIRECTION_BEGIN
	v.offset_left = 30 if big else 22
	v.offset_right = -(250 if big else 22)
	v.offset_bottom = -(22 if big else 14)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	var o := UITheme.label(over.to_upper(), 17 if big else 14, col.lightened(0.3), UITheme.semi_font())
	o.add_theme_constant_override("outline_size", 0)
	v.add_child(o)
	var t := UITheme.label(title.to_upper() if not big else title, (40 if big else (34 if size_px.y >= 140 else 28)), Color.WHITE, UITheme.title_font())
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	t.add_theme_constant_override("shadow_offset_y", 3)
	t.add_theme_constant_override("shadow_outline_size", 8)
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	# (0.75.0) A long title in a narrow tile gets smaller instead of losing its end.
	var fnt := UITheme.title_font()
	var fs := (40 if big else (34 if size_px.y >= 140 else 28))
	var room := size_px.x - (30.0 + 250.0 if big else 44.0)
	while fnt != null and fs > 20 and fnt.get_string_size(t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > room:
		fs -= 1
	t.add_theme_font_size_override("font_size", fs)
	v.add_child(t)
	if sub != "":
		var s := UITheme.label(sub, 19 if big else 15, Color(0.88, 0.91, 1.0, 0.86))
		# (0.74.1) A short tile has room for one line only: two pushed the small heading out over
		# its top edge ("With friends" on Online, with a long group name).
		if size_px.x < 340.0 and size_px.y >= 120.0:
			s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			s.max_lines_visible = 2
		else:
			s.clip_text = true
		s.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(s)
	_over = Control.new()
	_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	_over.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_over.draw.connect(_paint)
	add_child(_over)
	mouse_entered.connect(_set_hot.bind(true))
	mouse_exited.connect(func(): _set_hot(has_focus()))
	focus_entered.connect(_set_hot.bind(true))
	focus_exited.connect(func(): _set_hot(is_hovered()))
	resized.connect(_fit)


func _ready() -> void:
	_fit()


func _pic_rect() -> TextureRect:
	var r := TextureRect.new()
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.add_child(r)
	return r


func _fit() -> void:
	for r in [_a, _b]:
		r.size = size
		r.position = Vector2.ZERO


func _set_hot(on: bool) -> void:
	if on == _hot:
		return
	_hot = on
	_over.queue_redraw()


func _paint() -> void:
	var c := _over
	var r := Rect2(Vector2.ZERO, size)
	var rad := 18.0 if _big else 14.0
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_corner_radius_all(int(rad))
	var lit := _hot
	sb.set_border_width_all(3 if lit else 1)
	sb.border_color = col if lit else Color(1, 1, 1, 0.16)
	c.draw_style_box(sb, r)
	# The mode's colour down the left edge.
	c.draw_rect(Rect2(0, rad * 0.75, 5.0, size.y - rad * 1.5), col)
	var f := UITheme.semi_font()
	if _badge != "":
		var fs := 16
		var w := f.get_string_size(_badge, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 22.0
		var br := Rect2(size.x - w - 14.0, 12.0, w, 28.0)
		var bb := StyleBoxFlat.new()
		bb.bg_color = Color(0.02, 0.03, 0.08, 0.82)
		bb.set_corner_radius_all(14)
		bb.border_color = Color(col, 0.7)
		bb.set_border_width_all(1)
		c.draw_style_box(bb, br)
		c.draw_string(f, Vector2(br.position.x + 11.0, br.position.y + 20.0), _badge, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UITheme.GOLD)
	if _hint != "":
		var fs2 := 22
		var w2 := f.get_string_size(_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x + 44.0
		var hr := Rect2(size.x - w2 - 24.0, size.y - 66.0, w2, 46.0)
		var hb := StyleBoxFlat.new()
		hb.bg_color = col if lit else Color(col.darkened(0.15), 0.92)
		hb.set_corner_radius_all(23)
		c.draw_style_box(hb, hr)
		c.draw_string(f, Vector2(hr.position.x + 22.0, hr.position.y + 31.0), _hint, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, Color(0.04, 0.05, 0.1))
