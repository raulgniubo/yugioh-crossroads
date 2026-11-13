class_name MenuTile
extends Button
## One entry of the home screen: a slanted bar of dark glass with an amber stripe, a small
## heading, a big italic title and a line of small print. Under the pointer or focus it fills
## with amber and steps forward, so there is never a doubt about which one is picked.

var color := UITheme.ACCENT
var _kicker := ""
var _title := ""
var _sub := ""
var _badge := ""
var _big := false
var _hover := 0.0
var _target := 0.0
var _t := 0.0


func _init(kicker: String, title_text: String, subtitle: String, tint: Color, _glyph: String, size: Vector2, badge := "", big := false) -> void:
	color = tint
	# Drawn text does not translate itself the way a Label does.
	_kicker = Loc.t(kicker).to_upper()
	_title = Loc.t(title_text).to_upper()
	_sub = Loc.t(subtitle)
	_badge = badge
	_big = big
	custom_minimum_size = size
	self.size = size
	focus_mode = Control.FOCUS_ALL
	flat = true
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())
	mouse_entered.connect(func(): _wake())
	mouse_exited.connect(func(): _target = 1.0 if has_focus() else 0.0)
	focus_entered.connect(func(): _wake())
	focus_exited.connect(func(): _target = 1.0 if is_hovered() else 0.0)


func _wake() -> void:
	if _target < 0.5:
		Sfx.play("blip", -16.0, 1.25)
	_target = 1.0


func _process(delta: float) -> void:
	_t += delta
	var before := _hover
	_hover = move_toward(_hover, _target, delta * 12.0)
	if before != _hover or _hover > 0.0:
		queue_redraw()


func _draw() -> void:
	var e := ease(_hover, -2.0)
	var skew := 22.0 if _big else 16.0
	var r := Rect2(Vector2(2 + 10.0 * e, 4), size - Vector2(16, 12))
	var glass_top := Color(0.06, 0.09, 0.19, 0.9)
	var glass_bot := Color(0.03, 0.045, 0.1, 0.94)
	var top := glass_top.lerp(Comic.YELLOW, e)
	var bottom := glass_bot.lerp(Comic.ORANGE, e)
	if is_pressed():
		top = top.darkened(0.15)
		bottom = bottom.darkened(0.15)
	var pts := Comic.slab(self, r, skew, top, bottom, 1.0, Vector2(0, 4))
	# The amber stripe on the leading edge.
	draw_polyline(PackedVector2Array([pts[0], pts[3]]), Color(color, 1.0 - e * 0.4), 5.0, true)
	if _big and e < 0.99:
		Comic.outline(self, pts, Color(color, 0.55 * (1.0 - e)), 2.0)
	var f := Comic.chunky_font()
	var sf := Comic.button_font()
	var pad := 30.0 + skew * 0.6
	var room := r.size.x - pad - skew - 54.0
	var ink := Color.WHITE.lerp(Comic.INK, e)
	var y := r.position.y
	var has_sub := _sub != ""
	var ts := 58 if _big else 42
	while ts > 22 and f.get_string_size(_title, HORIZONTAL_ALIGNMENT_LEFT, -1, ts).x > room:
		ts -= 2
	var block := (20.0 if _kicker != "" else 0.0) + ts * 0.82 + (24.0 if has_sub else 0.0)
	var ty := y + (r.size.y - block) / 2.0
	var x := r.position.x + pad
	if _kicker != "":
		draw_string(sf, Vector2(x, ty + 15), _kicker, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(color, 1.0).lerp(Color(Comic.INK, 0.75), e))
		ty += 20.0
	draw_string(f, Vector2(x - 2, ty + ts * 0.78), _title, HORIZONTAL_ALIGNMENT_LEFT, -1, ts, ink)
	if has_sub:
		draw_string(UITheme.body_font(), Vector2(x, ty + ts * 0.82 + 19), _sub, HORIZONTAL_ALIGNMENT_LEFT, room + 30, 17 if not _big else 19,
				Color(0.78, 0.84, 0.95, 0.8).lerp(Color(Comic.INK, 0.8), e))
	# Chevrons on the right run while it is picked.
	for i in 2:
		var cx := r.end.x - skew - 40.0 + i * 13.0 + fmod(_t * 14.0, 6.0) * e
		var cy := y + r.size.y / 2.0
		draw_polyline(PackedVector2Array([Vector2(cx, cy - 9), Vector2(cx + 8, cy), Vector2(cx, cy + 9)]), Color(ink, 0.25 + 0.6 * e), 2.5, true)
	if _badge != "":
		var bw := sf.get_string_size(_badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		var br := Rect2(r.end.x - bw - 96, y + 10, bw + 24, 24)
		Comic.shape(self, Comic.quad(br, 6.0), Color(1, 1, 1, 0.14).lerp(Color(Comic.INK, 0.85), e), Color(1, 1, 1, 0.1).lerp(Color(Comic.INK, 0.85), e), 0.0, Vector2.ZERO)
		draw_string(sf, br.position + Vector2(13, 18), _badge, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
