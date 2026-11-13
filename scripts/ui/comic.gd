class_name Comic
extends RefCounted
## Drawing helpers for the game's look: sharp slanted shapes on deep navy glass, thin light
## edges, soft shadows, one warm accent. (The name is from an earlier, louder style.)

const INK := Color("070b1a")
const BLUE := Color("2f7dff")
const BLUE_DEEP := Color("123a9a")
const RED := Color("f0465a")
const RED_DEEP := Color("8f1730")
const ORANGE := Color("ffb62e")
const ORANGE_DEEP := Color("d98a0f")
const YELLOW := Color("ffd766")
const SKY := Color("7fd0ff")
const CREAM := Color("f4f7ff")
const GREEN := Color("3fd97f")
const GLASS := Color(0.035, 0.055, 0.12, 0.92)
const GLASS_LIGHT := Color(0.09, 0.13, 0.25, 0.94)
const EDGE := Color(1, 1, 1, 0.16)

static var _fonts := {}


static func _font(file: String, spacing := 0) -> Font:
	var key := "%s/%d" % [file, spacing]
	if not _fonts.has(key):
		var fv := FontVariation.new()
		fv.base_font = load("res://assets/fonts/" + file)
		fv.fallbacks = [load("res://assets/fonts/Rajdhani-Bold.ttf")]
		fv.spacing_glyph = spacing
		_fonts[key] = fv
	return _fonts[key]


## The loudest face: VS, banners, damage numbers, DUEL!
static func shout_font() -> Font:
	return _font("BarlowCondensed-BlackItalic.ttf", 1)


## Titles: narrow, heavy, leaning forward.
static func chunky_font(_squeeze := 1.0, _slant := 0.0) -> Font:
	return _font("BarlowCondensed-ExtraBoldItalic.ttf", 1)


## Buttons and small headings: the same family, upright.
static func button_font() -> Font:
	return _font("BarlowCondensed-SemiBold.ttf", 1)


## A parallelogram inside `rect`. Positive skew leans it to the right (top edge moved right).
static func quad(rect: Rect2, skew: float) -> PackedVector2Array:
	var s := absf(skew)
	var a := rect.position
	var b := rect.end
	if skew >= 0.0:
		return PackedVector2Array([Vector2(a.x + s, a.y), Vector2(b.x, a.y), Vector2(b.x - s, b.y), Vector2(a.x, b.y)])
	return PackedVector2Array([Vector2(a.x, a.y), Vector2(b.x - s, a.y), Vector2(b.x, b.y), Vector2(a.x + s, b.y)])


## A filled shape: soft shadow under it, a top-to-bottom gradient, one thin light edge.
static func shape(ci: CanvasItem, pts: PackedVector2Array, top: Color, bottom: Color, ink_w := 4.0, shadow := Vector2(0, 6), _ink := INK) -> void:
	if shadow != Vector2.ZERO:
		var off := Vector2(signf(shadow.x) * minf(absf(shadow.x), 2.0), minf(absf(shadow.y), 5.0) * signf(shadow.y))
		for k in 3:
			var sh := PackedVector2Array()
			for p in pts:
				sh.append(p + off * (0.5 + k * 0.5))
			ci.draw_colored_polygon(sh, Color(0, 0, 0, 0.12))
	var lo := INF
	var hi := -INF
	for p in pts:
		lo = minf(lo, p.y)
		hi = maxf(hi, p.y)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(top.lerp(bottom, (p.y - lo) / maxf(hi - lo, 1.0)))
	ci.draw_polygon(pts, cols)
	if ink_w > 0.0:
		outline(ci, pts, INK, ink_w)


## The edge of a shape. A request for the old ink line becomes the thin light edge.
static func outline(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float) -> void:
	var loop := PackedVector2Array(pts)
	loop.append(pts[0])
	loop.append(pts[1])
	if col == INK:
		ci.draw_polyline(loop, EDGE, 1.5, true)
	else:
		ci.draw_polyline(loop, col, minf(w, 2.5), true)


static func slab(ci: CanvasItem, rect: Rect2, skew: float, top: Color, bottom: Color, ink_w := 4.0, shadow := Vector2(0, 6)) -> PackedVector2Array:
	var pts := quad(rect, skew)
	shape(ci, pts, top, bottom, ink_w, shadow)
	return pts


## Halftone dots belonged to the louder style. Kept as a no-op so callers stay simple.
static func dots(_ci: CanvasItem, _pts: PackedVector2Array, _color: Color, _from := Vector2(1, 1), _step := 13.0, _max_r := 4.6, _reach := 0.75) -> void:
	pass


## Speed streaks across a rect (for bands and cut-ins).
static func streaks(ci: CanvasItem, rect: Rect2, color: Color, count := 14, seed_n := 7) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_n
	for i in count:
		var y := rect.position.y + rng.randf() * rect.size.y
		var x := rect.position.x + rng.randf() * rect.size.x
		var w := rect.size.x * rng.randf_range(0.12, 0.45)
		var h := rng.randf_range(1.5, 5.0)
		ci.draw_rect(Rect2(x, y, w, h), Color(color, color.a * rng.randf_range(0.35, 1.0)))


## Text with a soft drop shadow (and a hairline of dark around it when it sits on a picture).
static func text(ci: CanvasItem, font: Font, pos: Vector2, txt: String, size: int, color := Color.WHITE, ow := 8, _ink := INK, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	if ow > 0:
		ci.draw_string(font, pos + Vector2(0, maxf(1.0, size * 0.05)), txt, align, width, size, Color(0, 0, 0, 0.45))
		ci.draw_string_outline(font, pos, txt, align, width, size, mini(ow, 3), Color(INK, 0.55))
	ci.draw_string(font, pos, txt, align, width, size, color)


## A title label: heavy italic, with a soft shadow so it reads over anything.
static func label(txt: String, size := 28, color := Color.WHITE, ow := -1, font: Font = null) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", font if font else chunky_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if ow != 0:
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		l.add_theme_constant_override("shadow_offset_x", 0)
		l.add_theme_constant_override("shadow_offset_y", maxi(1, int(size * 0.05)))
		l.add_theme_color_override("font_outline_color", Color(INK, 0.5))
		l.add_theme_constant_override("outline_size", 2 if size < 40 else 3)
	return l


## A flat box: thin light border, soft shadow, optional slant.
static func box(fill: Color, radius := 14, skew := 0.0, _ink_w := 3, drop := 5, _ink := INK) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = Color(1, 1, 1, 0.16) if fill.get_luminance() < 0.6 else Color(0, 0, 0, 0.18)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(mini(radius, 10))
	sb.skew = Vector2(skew * 0.85, 0)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	if drop > 0:
		sb.shadow_color = Color(0, 0, 0, 0.3)
		sb.shadow_size = 8
		sb.shadow_offset = Vector2(0, 3)
	sb.anti_aliasing = true
	return sb


## A five-point star polygon.
static func star(c: Vector2, r: float, inner := 0.46, rot := -PI / 2.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := rot + i * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * inner))
	return pts
