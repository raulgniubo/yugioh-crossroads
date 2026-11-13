class_name UITheme
extends RefCounted
## Shared look: bright comic panels. Saturated blue slabs, orange and yellow accents, thick
## ink outlines and hard drop shadows (see Comic for the drawing helpers).

const BG := Color("0a1a52")
const PANEL := Color(0.045, 0.08, 0.25, 0.96)
const PANEL_LIGHT := Color(0.09, 0.16, 0.42, 0.96)
## The bright line around a deep navy card.
const EDGE := Color(0.42, 0.62, 1.0, 0.95)
const ACCENT := Color("ffa51f")
const ACCENT_2 := Color("3a86ff")
const TEXT := Color("ffffff")
const TEXT_DIM := Color(0.86, 0.92, 1.0, 0.82)
const DANGER := Color("ff4d6d")
const GOLD := Color("ffe14d")

static var _semi_font: Font
static var _body_font: FontVariation


static func title_font() -> Font:
	return Comic.chunky_font()


static func semi_font() -> Font:
	if _semi_font == null:
		_semi_font = load("res://assets/fonts/Rajdhani-Bold.ttf")
	return _semi_font


static func body_font() -> Font:
	if _body_font == null:
		_body_font = FontVariation.new()
		_body_font.base_font = load("res://assets/fonts/Inter.ttf")
		_body_font.variation_opentype = {"wght": 560}
	return _body_font


static func panel_box(color := PANEL, radius := 18, border := Color(1, 1, 1, 0.08)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	# A faint edge becomes the ink outline; a colored one keeps its color, drawn boldly.
	sb.border_color = EDGE if border.a < 0.5 else Color(border, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(18)
	sb.shadow_color = Color(Comic.INK, 0.5)
	sb.shadow_size = 1
	sb.shadow_offset = Vector2(0, 6)
	sb.anti_aliasing = true
	return sb


static func button_box(bg: Color, border: Color, radius := 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = Color(Comic.INK, minf(1.0, bg.a + 0.2)) if border.a < 0.25 else border
	sb.set_border_width_all(2)
	sb.border_width_bottom = 4
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.anti_aliasing = true
	return sb


## The standard slanted comic button, in any color.
static func comic_button(fill: Color, skew := 0.14) -> StyleBoxFlat:
	return Comic.box(fill, 12, skew, 3, 5)


static func _chip_box(fill: Color) -> StyleBoxFlat:
	var sb := Comic.box(fill, 12, 0.14, 3, 4)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	return sb


## A choice chip: cream with ink words, orange when it is the one picked. Every plain toggle
## button gets this automatically (see Router), other buttons can ask for it.
static func chip(b: Button, on_color := Comic.ORANGE) -> void:
	b.add_theme_stylebox_override("normal", _chip_box(Comic.CREAM))
	b.add_theme_stylebox_override("hover", _chip_box(Color("fff1b8")))
	b.add_theme_stylebox_override("pressed", _chip_box(on_color))
	b.add_theme_stylebox_override("hover_pressed", _chip_box(on_color.lightened(0.18)))
	var dis := _chip_box(Color(0.62, 0.68, 0.82, 0.55))
	dis.shadow_size = 0
	dis.border_color = Color(Comic.INK, 0.4)
	b.add_theme_stylebox_override("disabled", dis)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, Comic.INK)
	b.add_theme_color_override("font_disabled_color", Color(Comic.INK, 0.5))


## Paint one button as a primary (orange) or any other color, keeping the comic shape.
static func paint_button(b: Button, fill: Color, text := Color.WHITE) -> void:
	b.add_theme_stylebox_override("normal", comic_button(fill))
	b.add_theme_stylebox_override("hover", comic_button(fill.lightened(0.18)))
	b.add_theme_stylebox_override("pressed", comic_button(Comic.YELLOW))
	b.add_theme_color_override("font_color", text)
	b.add_theme_color_override("font_hover_color", text)


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = 20
	t.set_color("font_color", "Label", TEXT)

	t.set_font("font", "Button", Comic.chunky_font(0.9))
	t.set_font_size("font_size", "Button", 23)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Comic.INK)
	t.set_color("font_hover_pressed_color", "Button", Comic.INK)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.42))
	# No outline on button text: the selected state uses dark words on a bright fill, and an
	# ink outline around ink letters turns to mush.
	t.set_color("font_outline_color", "Button", Color(Comic.INK, 0.9))
	t.set_constant("outline_size", "Button", 0)
	t.set_stylebox("normal", "Button", comic_button(Color("2f66e8")))
	t.set_stylebox("hover", "Button", comic_button(Comic.ORANGE))
	t.set_stylebox("pressed", "Button", comic_button(Comic.YELLOW))
	var foc := comic_button(Color(0, 0, 0, 0))
	foc.border_color = Color(1, 1, 1, 0.9)
	foc.shadow_size = 0
	t.set_stylebox("focus", "Button", foc)
	var dis := comic_button(Color(0.2, 0.28, 0.5, 0.6))
	dis.border_color = Color(Comic.INK, 0.45)
	dis.shadow_size = 0
	t.set_stylebox("disabled", "Button", dis)

	t.set_stylebox("panel", "Panel", panel_box())
	t.set_stylebox("panel", "PanelContainer", panel_box())

	# Sliders
	var track := StyleBoxFlat.new()
	track.bg_color = Color(Comic.INK, 0.6)
	track.set_corner_radius_all(5)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	var fill := track.duplicate()
	fill.bg_color = ACCENT
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	t.set_icon("grabber", "HSlider", _dot(20, Color.WHITE))
	t.set_icon("grabber_highlight", "HSlider", _dot(22, Comic.YELLOW))

	# Dropdowns are cream boxes with ink words, like the chips: bright things on a deep card.
	t.set_stylebox("normal", "OptionButton", Comic.box(Comic.CREAM, 12, 0.0, 3, 3))
	t.set_stylebox("hover", "OptionButton", Comic.box(Color("fff1b8"), 12, 0.0, 3, 3))
	t.set_stylebox("pressed", "OptionButton", Comic.box(Color("fff1b8"), 12, 0.0, 3, 3))
	var ofoc := Comic.box(Color(0, 0, 0, 0), 12, 0.0, 3, 0)
	ofoc.border_color = ACCENT
	t.set_stylebox("focus", "OptionButton", ofoc)
	t.set_font("font", "OptionButton", body_font())
	t.set_font_size("font_size", "OptionButton", 20)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "OptionButton", Comic.INK)
	t.set_constant("modulate_arrow", "OptionButton", 1)
	t.set_constant("outline_size", "OptionButton", 0)
	t.set_stylebox("panel", "PopupMenu", panel_box(Color(0.05, 0.09, 0.28, 0.99), 12))
	t.set_stylebox("hover", "PopupMenu", button_box(Color(ACCENT, 0.9), Color(0, 0, 0, 0), 8))
	t.set_font_size("font_size", "PopupMenu", 20)

	# Checkbox as toggle
	t.set_font("font", "CheckButton", body_font())
	t.set_font_size("font_size", "CheckButton", 20)
	t.set_constant("outline_size", "CheckButton", 0)
	t.set_icon("checked", "CheckButton", _toggle(true))
	t.set_icon("unchecked", "CheckButton", _toggle(false))
	for s in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		t.set_stylebox(s, "CheckButton", StyleBoxEmpty.new())

	t.set_stylebox("normal", "LineEdit", Comic.box(Comic.CREAM, 10, 0.0, 3, 0))
	var lef := Comic.box(Comic.CREAM, 10, 0.0, 4, 0)
	lef.border_color = ACCENT
	t.set_stylebox("focus", "LineEdit", lef)
	t.set_color("font_color", "LineEdit", Comic.INK)
	t.set_color("font_placeholder_color", "LineEdit", Color(Comic.INK, 0.45))
	t.set_color("caret_color", "LineEdit", Comic.INK)
	t.set_color("selection_color", "LineEdit", Color(ACCENT, 0.5))
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
	var bg := Comic.GREEN if on else Color(0.03, 0.06, 0.2, 0.75)
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
