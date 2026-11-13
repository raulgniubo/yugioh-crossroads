class_name MenuTile
extends Button
## A slanted comic ribbon on the home screen: orange with halftone dots, a bold outlined title,
## a small kicker tab on its top edge and a line of small print. The big one (Story) is gold.
## It lifts, brightens and leans a little under the pointer or focus.

var color := Comic.ORANGE
var _kicker := ""
var _title := ""
var _sub := ""
var _glyph := ""
var _badge := ""
var _big := false
var _hover := 0.0
var _target := 0.0
var _t := 0.0


func _init(kicker: String, title_text: String, subtitle: String, tint: Color, glyph: String, size: Vector2, badge := "", big := false) -> void:
	color = tint
	_kicker = kicker.to_upper()
	_title = title_text
	_sub = subtitle
	_glyph = glyph
	_badge = badge
	_big = big
	custom_minimum_size = size
	self.size = size
	focus_mode = Control.FOCUS_ALL
	flat = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())
	pivot_offset = size / 2.0
	mouse_entered.connect(func(): _wake())
	mouse_exited.connect(func(): _target = 1.0 if has_focus() else 0.0)
	focus_entered.connect(func(): _wake())
	focus_exited.connect(func(): _target = 0.0)


func _wake() -> void:
	if _target < 0.5:
		Sfx.play("blip", -16.0, 1.25)
	_target = 1.0


func _process(delta: float) -> void:
	_t += delta
	var before := _hover
	_hover = move_toward(_hover, _target, delta * 8.0)
	var e := ease(_hover, -2.0)
	scale = Vector2.ONE * (1.0 + 0.045 * e)
	rotation = -0.012 * e
	z_index = 1 if e > 0.01 else 0
	if before != _hover or _hover > 0.0:
		queue_redraw()


func _draw() -> void:
	var e := ease(_hover, -2.0)
	var down := is_pressed()
	var skew := 30.0 if _big else 22.0
	var r := Rect2(Vector2(4, 12), size - Vector2(8, 24))
	var top := Comic.YELLOW if _big else Comic.ORANGE
	var bottom := Comic.ORANGE if _big else Comic.ORANGE_DEEP
	top = top.lerp(Color("fff3a8"), 0.55 * e)
	bottom = bottom.lerp(Comic.YELLOW, 0.5 * e)
	if down:
		top = top.darkened(0.12)
		bottom = bottom.darkened(0.12)
	var pts := Comic.slab(self, r, skew, top, bottom, 5.0, Vector2(0, 3) if down else Vector2(3, 9.0 + 3.0 * e))
	Comic.dots(self, pts, Color(1, 1, 1, 0.3), Vector2(1, 0.2), 14.0, 6.5, 0.62)
	# A stripe of light across the top.
	draw_polyline(PackedVector2Array([pts[0] + Vector2(10, 7), pts[1] + Vector2(-14, 7)]), Color(1, 1, 1, 0.5), 3.0, true)
	var f := Comic.chunky_font()
	# The big faint symbol on the right.
	if _glyph != "":
		var gs := int(r.size.y * (0.82 if _big else 0.78))
		var gw := UITheme.semi_font().get_string_size(_glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, gs).x
		draw_string(UITheme.semi_font(), Vector2(r.end.x - gw - skew - 18, r.position.y + r.size.y * 0.5 + gs * 0.34), _glyph,
				HORIZONTAL_ALIGNMENT_LEFT, -1, gs, Color(Comic.INK, 0.16 + 0.08 * e))
	var pad := 30.0 + skew * 0.5
	var room := r.size.x - pad - skew - 20.0
	# The title, shrunk until it fits.
	var ts := 58 if _big else 42
	while ts > 22 and f.get_string_size(_title, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x > room:
		ts -= 2
	var has_sub := _sub != ""
	var base_y := r.position.y + r.size.y * (0.56 if has_sub else 0.62) + ts * 0.2
	if _big:
		base_y = r.position.y + r.size.y * 0.55
	Comic.text(self, f, Vector2(pad, base_y), _title, ts, Color.WHITE, 12 if _big else 10)
	if has_sub:
		var sf := UITheme.semi_font()
		var ss := 21 if _big else 18
		draw_string(sf, Vector2(pad - 4, base_y + (34 if _big else 25)), _sub, HORIZONTAL_ALIGNMENT_LEFT, room + 10, ss, Color(Comic.INK, 0.92))
	# The kicker rides the top edge on its own dark tab.
	if _kicker != "":
		var ks := 19 if _big else 16
		var kw := f.get_string_size(_kicker, HORIZONTAL_ALIGNMENT_LEFT, -1, ks).x
		var tab := Rect2(pad - 8, 0, kw + 36, 28 if _big else 25)
		Comic.slab(self, tab, 8.0, Comic.INK, Comic.INK, 0.0, Vector2.ZERO)
		Comic.text(self, f, tab.position + Vector2(20, tab.size.y - 7), _kicker, ks, Comic.YELLOW, 0)
	if _badge != "":
		var bw := f.get_string_size(_badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		var br := Rect2(r.end.x - bw - 62, 2, bw + 34, 30)
		Comic.slab(self, br, 8.0, Comic.RED, Comic.RED_DEEP, 3.0, Vector2(0, 3))
		Comic.text(self, f, br.position + Vector2(19, 23), _badge, 18, Color.WHITE, 4)
	if has_focus() and not is_hovered():
		Comic.outline(self, pts, Color(1, 1, 1, 0.75 + 0.25 * sin(_t * 6.0)), 3.0)
