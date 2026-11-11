class_name UITheme
extends RefCounted
## Shared look: dark navy glass panels, teal/blue accents, Rajdhani + Inter.

const BG := Color("060a12")
const PANEL := Color(0.05, 0.08, 0.14, 0.86)
const PANEL_LIGHT := Color(0.09, 0.14, 0.23, 0.9)
const ACCENT := Color("2de2e6")
const ACCENT_2 := Color("3a86ff")
const TEXT := Color("e8f1ff")
const TEXT_DIM := Color(0.72, 0.8, 0.92, 0.7)
const DANGER := Color("ff4d6d")
const GOLD := Color("ffd166")

static var _title_font: Font
static var _semi_font: Font
static var _body_font: FontVariation


static func title_font() -> Font:
	if _title_font == null:
		_title_font = load("res://assets/fonts/Rajdhani-Bold.ttf")
	return _title_font


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
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(18)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 18
	sb.anti_aliasing = true
	return sb


static func button_box(bg: Color, border: Color, radius := 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.anti_aliasing = true
	return sb


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 20
	t.set_color("font_color", "Label", TEXT)

	t.set_font("font", "Button", semi_font())
	t.set_font_size("font_size", "Button", 24)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", BG)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.3))
	t.set_stylebox("normal", "Button", button_box(Color(0.08, 0.12, 0.2, 0.75), Color(1, 1, 1, 0.1)))
	t.set_stylebox("hover", "Button", button_box(Color(0.1, 0.2, 0.3, 0.9), ACCENT))
	t.set_stylebox("pressed", "Button", button_box(ACCENT, ACCENT))
	t.set_stylebox("focus", "Button", button_box(Color(0, 0, 0, 0), Color(ACCENT, 0.8)))
	t.set_stylebox("disabled", "Button", button_box(Color(0.06, 0.08, 0.12, 0.5), Color(1, 1, 1, 0.04)))

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

	# Option buttons and popups
	t.set_stylebox("normal", "OptionButton", button_box(Color(0.08, 0.12, 0.2, 0.75), Color(1, 1, 1, 0.1)))
	t.set_stylebox("hover", "OptionButton", button_box(Color(0.1, 0.2, 0.3, 0.9), ACCENT))
	t.set_stylebox("pressed", "OptionButton", button_box(Color(0.1, 0.2, 0.3, 0.9), ACCENT))
	t.set_stylebox("focus", "OptionButton", button_box(Color(0, 0, 0, 0), Color(ACCENT, 0.8)))
	t.set_font("font", "OptionButton", body_font())
	t.set_font_size("font_size", "OptionButton", 20)
	t.set_stylebox("panel", "PopupMenu", panel_box(Color(0.06, 0.09, 0.15, 0.98), 12))
	t.set_stylebox("hover", "PopupMenu", button_box(Color(ACCENT, 0.2), Color(0, 0, 0, 0), 8))
	t.set_font_size("font_size", "PopupMenu", 20)

	# Checkbox as toggle
	t.set_font("font", "CheckButton", body_font())
	t.set_font_size("font_size", "CheckButton", 20)
	t.set_icon("checked", "CheckButton", _toggle(true))
	t.set_icon("unchecked", "CheckButton", _toggle(false))
	for s in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		t.set_stylebox(s, "CheckButton", StyleBoxEmpty.new())

	t.set_stylebox("normal", "LineEdit", button_box(Color(0.03, 0.05, 0.09, 0.8), Color(1, 1, 1, 0.12), 10))
	t.set_stylebox("focus", "LineEdit", button_box(Color(0.03, 0.05, 0.09, 0.8), ACCENT, 10))
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
	var bg := ACCENT if on else Color(1, 1, 1, 0.18)
	var knob_x := w - h / 2.0 if on else h / 2.0
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var cx := clampf(p.x, h / 2.0, w - h / 2.0)
			var d := p.distance_to(Vector2(cx, h / 2.0))
			var col := Color(bg, clampf(h / 2.0 - d, 0.0, 1.0))
			var kd := p.distance_to(Vector2(knob_x, h / 2.0))
			var ka := clampf(h / 2.0 - 3.0 - kd, 0.0, 1.0)
			col = col.lerp(Color(1, 1, 1, maxf(col.a, ka)), ka)
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
