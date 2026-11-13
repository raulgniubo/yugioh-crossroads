class_name Comic
extends RefCounted
## The bright comic look shared by the duel screen and the menus: bold ink outlines, slanted
## slabs, halftone dots and hard drop shadows. Everything here is drawn, nothing is an image.

const INK := Color("0a1236")
const BLUE := Color("2b6bff")
const BLUE_DEEP := Color("1235b0")
const RED := Color("ff3d55")
const RED_DEEP := Color("a80f2c")
const ORANGE := Color("ffa51f")
const ORANGE_DEEP := Color("ee5f0a")
const YELLOW := Color("ffe14d")
const SKY := Color("63d2ff")
const CREAM := Color("fffaf0")
const GREEN := Color("3fd97f")

static var _shout: Font
static var _chunky: Dictionary = {}


## The loud slanted face: VS, banners, damage numbers, DUEL!
static func shout_font() -> Font:
	if _shout == null:
		var f: FontFile = load("res://assets/fonts/Bangers-Regular.ttf")
		var fv := FontVariation.new()
		fv.base_font = f
		fv.fallbacks = [load("res://assets/fonts/Rajdhani-Bold.ttf")]
		fv.spacing_glyph = 2
		_shout = fv
	return _shout


## The round heavy face used for titles and buttons. `squeeze` narrows it a little so words
## written for the old thin face still fit.
static func chunky_font(squeeze := 0.92, slant := 0.0) -> Font:
	var key := "%.2f/%.2f" % [squeeze, slant]
	if not _chunky.has(key):
		var fv := FontVariation.new()
		fv.base_font = load("res://assets/fonts/LilitaOne-Regular.ttf")
		fv.fallbacks = [load("res://assets/fonts/Rajdhani-Bold.ttf")]
		fv.variation_transform = Transform2D(Vector2(squeeze, 0), Vector2(slant, 1), Vector2.ZERO)
		_chunky[key] = fv
	return _chunky[key]


## A parallelogram inside `rect`. Positive skew leans it to the right (top edge moved right).
static func quad(rect: Rect2, skew: float) -> PackedVector2Array:
	var s := absf(skew)
	var a := rect.position
	var b := rect.end
	if skew >= 0.0:
		return PackedVector2Array([Vector2(a.x + s, a.y), Vector2(b.x, a.y), Vector2(b.x - s, b.y), Vector2(a.x, b.y)])
	return PackedVector2Array([Vector2(a.x, a.y), Vector2(b.x - s, a.y), Vector2(b.x, b.y), Vector2(a.x + s, b.y)])


static func shape(ci: CanvasItem, pts: PackedVector2Array, top: Color, bottom: Color, ink_w := 4.0, shadow := Vector2(0, 6), ink := INK) -> void:
	if shadow != Vector2.ZERO:
		var sh := PackedVector2Array()
		for p in pts:
			sh.append(p + shadow)
		ci.draw_colored_polygon(sh, Color(ink, 0.6))
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
		outline(ci, pts, ink, ink_w)


static func outline(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float) -> void:
	var loop := PackedVector2Array(pts)
	loop.append(pts[0])
	loop.append(pts[1])
	ci.draw_polyline(loop, col, w, true)


## A slanted slab: gradient fill, ink outline, hard shadow underneath.
static func slab(ci: CanvasItem, rect: Rect2, skew: float, top: Color, bottom: Color, ink_w := 4.0, shadow := Vector2(0, 6)) -> PackedVector2Array:
	var pts := quad(rect, skew)
	shape(ci, pts, top, bottom, ink_w, shadow)
	return pts


## Halftone dots inside a shape, biggest near `from` (0..1 across the shape's box) and fading out.
static func dots(ci: CanvasItem, pts: PackedVector2Array, color: Color, from := Vector2(1, 1), step := 13.0, max_r := 4.6, reach := 0.75) -> void:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in pts:
		lo = lo.min(p)
		hi = hi.max(p)
	var size := hi - lo
	var origin := lo + size * from
	var far := size.length() * reach
	var row := 0
	var y := lo.y + step * 0.5
	while y < hi.y:
		var x := lo.x + (step * 0.5 if row % 2 == 0 else step)
		while x < hi.x:
			var p := Vector2(x, y)
			var r := max_r * (1.0 - p.distance_to(origin) / far)
			if r > 0.7 and Geometry2D.is_point_in_polygon(p, pts):
				ci.draw_circle(p, r, color)
			x += step
		y += step * 0.87
		row += 1


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


static func text(ci: CanvasItem, font: Font, pos: Vector2, txt: String, size: int, color := Color.WHITE, ow := 8, ink := INK, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	if ow > 0:
		ci.draw_string_outline(font, pos, txt, align, width, size, ow, ink)
	ci.draw_string(font, pos, txt, align, width, size, color)


## A label in the heavy face with an ink outline.
static func label(txt: String, size := 28, color := Color.WHITE, ow := -1, font: Font = null) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", font if font else chunky_font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", ow if ow >= 0 else int(clampf(size * 0.28, 4, 16)))
	return l


## A flat box with the comic ink border and a hard drop shadow.
static func box(fill: Color, radius := 14, skew := 0.0, ink_w := 3, drop := 5, ink := INK) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = ink
	sb.set_border_width_all(ink_w)
	sb.set_corner_radius_all(radius)
	sb.skew = Vector2(skew, 0)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	if drop > 0:
		sb.shadow_color = Color(ink, 0.55)
		sb.shadow_size = 1
		sb.shadow_offset = Vector2(0, drop)
	sb.anti_aliasing = true
	return sb


## A five-point star polygon.
static func star(c: Vector2, r: float, inner := 0.46, rot := -PI / 2.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := rot + i * PI / 5.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * inner))
	return pts
