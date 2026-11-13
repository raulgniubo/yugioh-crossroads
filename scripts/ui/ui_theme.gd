class_name UITheme
extends RefCounted
## Shared look: deep navy glass, thin light edges, soft shadows, one warm accent (amber).
## Narrow italic titles (Barlow Condensed), Rajdhani for small labels, Inter for reading.

const BG := Color("070b1a")
const PANEL := Color(0.035, 0.055, 0.12, 0.92)
const PANEL_LIGHT := Color(0.09, 0.13, 0.25, 0.94)
const ACCENT := Color("ffb62e")
const ACCENT_2 := Color("3a86ff")
const TEXT := Color("eef3ff")
const TEXT_DIM := Color(0.75, 0.82, 0.94, 0.75)
const DANGER := Color("ff4d6d")
const GOLD := Color("ffd766")
const EDGE := Color(1, 1, 1, 0.14)

static var _semi_font: Font
static var _body_font: FontVariation


static func title_font() -> Font:
	return Comic.chunky_font()


static func semi_font() -> Font:
	if _semi_font == null:
		_semi_font = load("res://assets/fonts/Rajdhani-SemiBold.ttf")
	return _semi_font


static func body_font() -> Font:
	if _body_font == null:
		_body_font = FontVariation.new()
		_body_font.base_font = load("res://assets/fonts/Inter.ttf")
		_body_font.variation_opentype = {"wght": 500}
	return _body_font


static func panel_box(color := PANEL, radius := 18, border := Color(1, 1, 1, 0.08)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	# A faint edge stays a faint light line; a colored one is drawn a little bolder.
	var strong := border.a >= 0.5
	sb.border_color = Color(border, minf(border.a, 0.9)) if strong else Color(1, 1, 1, maxf(border.a, 0.12))
	if not strong and border.a > 0.15 and border.get_luminance() < 0.95:
		sb.border_color = border
	sb.set_border_width_all(2 if strong else 1)
	sb.set_corner_radius_all(mini(radius, 14))
	sb.set_content_margin_all(18)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 16
	sb.shadow_offset = Vector2(0, 4)
	sb.anti_aliasing = true
	return sb


static func button_box(bg: Color, border: Color, radius := 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2 if border.a >= 0.5 else 1)
	sb.set_corner_radius_all(mini(radius, 10))
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.anti_aliasing = true
	return sb


## The standard slanted button, in any color.
static func comic_button(fill: Color, skew := 0.12) -> StyleBoxFlat:
	return Comic.box(fill, 8, skew, 1, 4)


## Paint one button in a solid color (the primary action of a screen).
static func paint_button(b: Button, fill: Color, text := Color.WHITE) -> void:
	var dark := fill.get_luminance() > 0.5
	var col := Comic.INK if dark and text == Color.WHITE else text
	b.add_theme_stylebox_override("normal", comic_button(fill))
	b.add_theme_stylebox_override("hover", comic_button(fill.lightened(0.18)))
	b.add_theme_stylebox_override("pressed", comic_button(fill.darkened(0.15)))
	var dis := comic_button(Color(fill.darkened(0.55), 0.55))
	dis.shadow_size = 0
	b.add_theme_stylebox_override("disabled", dis)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, col)


static func _chip_box(fill: Color) -> StyleBoxFlat:
	var sb := Comic.box(fill, 8, 0.12, 1, 3)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	return sb


## A choice chip: glass when it is not picked, amber with dark words when it is. Every plain
## toggle button gets this automatically (see Router), other buttons can ask for it.
static func chip(b: Button, on_color := ACCENT) -> void:
	b.add_theme_stylebox_override("normal", _chip_box(Color(0.09, 0.13, 0.25, 0.94)))
	var hov := _chip_box(Color(0.14, 0.2, 0.36, 0.96))
	hov.border_color = Color(on_color, 0.9)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", _chip_box(on_color))
	b.add_theme_stylebox_override("hover_pressed", _chip_box(on_color.lightened(0.15)))
	var dis := _chip_box(Color(0.08, 0.1, 0.18, 0.6))
	dis.shadow_size = 0
	b.add_theme_stylebox_override("disabled", dis)
	for c in ["font_color", "font_hover_color", "font_focus_color"]:
		b.add_theme_color_override(c, TEXT)
	for c in ["font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, Comic.INK)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))


## The look of whatever has the keyboard or pad focus: an amber frame nobody can miss.
static func focus_box(skew := 0.12, radius := 8) -> StyleBoxFlat:
	var sb := Comic.box(Color(ACCENT, 0.16), radius, skew, 1, 0)
	sb.border_color = ACCENT
	sb.set_border_width_all(3)
	sb.set_expand_margin_all(2)
	return sb


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 20
	t.set_color("font_color", "Label", TEXT)

	t.set_font("font", "Button", Comic.button_font())
	t.set_font_size("font_size", "Button", 25)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Comic.INK)
	t.set_color("font_hover_pressed_color", "Button", Comic.INK)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.32))
	t.set_constant("outline_size", "Button", 0)
	t.set_stylebox("normal", "Button", comic_button(Color(0.09, 0.13, 0.25, 0.94)))
	var hov := comic_button(Color(0.14, 0.2, 0.36, 0.97))
	hov.border_color = ACCENT
	t.set_stylebox("hover", "Button", hov)
	t.set_stylebox("pressed", "Button", comic_button(ACCENT))
	t.set_stylebox("focus", "Button", focus_box())
	var dis := comic_button(Color(0.06, 0.08, 0.14, 0.6))
	dis.border_color = Color(1, 1, 1, 0.06)
	dis.shadow_size = 0
	t.set_stylebox("disabled", "Button", dis)

	t.set_stylebox("panel", "Panel", panel_box())
	t.set_stylebox("panel", "PanelContainer", panel_box())

	# Sliders
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.12)
	track.set_corner_radius_all(4)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	var fill := track.duplicate()
	fill.bg_color = ACCENT
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	t.set_icon("grabber", "HSlider", _dot(18, Color.WHITE))
	t.set_icon("grabber_highlight", "HSlider", _dot(20, ACCENT))

	# Dropdowns
	t.set_stylebox("normal", "OptionButton", button_box(Color(0.09, 0.13, 0.25, 0.94), Color(1, 1, 1, 0.14), 8))
	t.set_stylebox("hover", "OptionButton", button_box(Color(0.14, 0.2, 0.36, 0.97), ACCENT, 8))
	t.set_stylebox("pressed", "OptionButton", button_box(Color(0.14, 0.2, 0.36, 0.97), ACCENT, 8))
	t.set_stylebox("focus", "OptionButton", focus_box(0.0))
	t.set_font("font", "OptionButton", body_font())
	t.set_font_size("font_size", "OptionButton", 20)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "OptionButton", TEXT)
	t.set_constant("modulate_arrow", "OptionButton", 1)
	t.set_stylebox("panel", "PopupMenu", panel_box(Color(0.05, 0.075, 0.16, 0.99), 10))
	t.set_stylebox("hover", "PopupMenu", button_box(Color(ACCENT, 0.25), Color(0, 0, 0, 0), 6))
	t.set_font_size("font_size", "PopupMenu", 20)

	# Checkbox as toggle
	t.set_font("font", "CheckButton", body_font())
	t.set_font_size("font_size", "CheckButton", 20)
	t.set_icon("checked", "CheckButton", _toggle(true))
	t.set_icon("unchecked", "CheckButton", _toggle(false))
	for s in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		t.set_stylebox(s, "CheckButton", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "CheckButton", TEXT)

	t.set_stylebox("normal", "LineEdit", button_box(Color(0.03, 0.045, 0.1, 0.9), Color(1, 1, 1, 0.14), 8))
	t.set_stylebox("focus", "LineEdit", button_box(Color(0.03, 0.045, 0.1, 0.9), ACCENT, 8))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", Color(1, 1, 1, 0.35))
	t.set_color("caret_color", "LineEdit", ACCENT)
	return t


static func _dot(size: int, color: Color) -> Texture2D:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size, size) / 2.0
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			img.set_pixel(x, y, Color(color, clampf(size / 2.0 - d, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


static func _toggle(on: bool) -> Texture2D:
	var w := 52
	var h := 28
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var bg := ACCENT if on else Color(0.17, 0.21, 0.34, 1.0)
	var knob := Color(1, 1, 1) if on else Color(0.62, 0.67, 0.8)
	var knob_x := w - h / 2.0 if on else h / 2.0
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var cx := clampf(p.x, h / 2.0, w - h / 2.0)
			var d := p.distance_to(Vector2(cx, h / 2.0))
			var col := Color(bg, clampf(h / 2.0 - d, 0.0, 1.0))
			var kd := p.distance_to(Vector2(knob_x, h / 2.0))
			var ka := clampf(h / 2.0 - 3.0 - kd, 0.0, 1.0)
			col = col.lerp(Color(knob, maxf(col.a, ka)), ka)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


static func label(text: String, size := 20, color := TEXT, font: Font = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font:
		l.add_theme_font_override("font", font)
	return l
