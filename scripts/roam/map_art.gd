class_name MapArt
extends RefCounted
## What both maps draw with: the picture of the world, round portrait markers, name tags, pins.

const INK := Color(0.02, 0.035, 0.065)

## Cuts a map to a circle (the small map in the corner).
const ROUND_SHADER := """
shader_type canvas_item;
uniform vec2 size = vec2(256.0, 256.0);
varying vec2 lp;
void vertex() {
	lp = VERTEX;
}
void fragment() {
	float d = length(lp - size * 0.5) - (min(size.x, size.y) * 0.5 - 1.0);
	COLOR.a *= clamp(0.5 - d, 0.0, 1.0);
}
"""

static var _faces := {}


## The picture of the world, the part `world` (x, z metres) of it, fitted into `dest`. Where the
## view runs off the picture the backdrop color shows.
static func photo(ci: CanvasItem, dest: Rect2, world: Rect2, back := Color(0.035, 0.05, 0.08)) -> void:
	ci.draw_rect(dest, back)
	var tex := MapPhoto.tex
	if tex == null:
		return
	var all := Rect2(MapPhoto.mid - MapPhoto.half, MapPhoto.half * 2.0)
	var part := world.intersection(all)
	if part.size.x <= 0.0 or part.size.y <= 0.0:
		return
	var k := dest.size / world.size
	var d := Rect2(dest.position + (part.position - world.position) * k, part.size * k)
	var ts := Vector2(tex.get_size())
	var src := Rect2((part.position - all.position) / all.size * ts, part.size / all.size * ts)
	ci.draw_texture_rect_region(tex, d, src)


## The face of a character, cut square from the top of their portrait.
static var waiting := {}
static var _made_frame := -1
static var _made_n := 0      # faces asked for whose models are still being read

static func face(key: String) -> Texture2D:
	if key == "":
		return null
	if _faces.has(key) and is_instance_valid(_faces[key]):
		return _faces[key]
	# (0.80.1) Never read a model from disk in the middle of drawing (the mini map, the Knockout
	# screen): until it has been read on another thread the token shows its plain color.
	if key != "player" and Avatars.has_avatar(key) and not (Portraits.holds(key) or Avatars.ready_now(key)):
		Avatars.warm(key)
		waiting[key] = true
		return null
	if not Portraits.holds(key):
		# (Two new pictures a frame at most: each sets up a small 3D view.)
		if _made_frame != Engine.get_process_frames():
			_made_frame = Engine.get_process_frames()
			_made_n = 0
		if _made_n >= 2:
			waiting[key] = true
			return null
		_made_n += 1
	waiting.erase(key)
	var t: Texture2D = Portraits.get_portrait(key)
	_faces[key] = t
	return t


## A round portrait marker with a ring.
static func token(ci: CanvasItem, at: Vector2, r: float, key: String, ring: Color, fallback := Color("ffd166"), zoom := 1.0) -> void:
	ci.draw_circle(at + Vector2(0, 2), r + 3.5, Color(0, 0, 0, 0.45))
	ci.draw_circle(at, r + 2.5, ring)
	ci.draw_circle(at, r, INK)
	var t := face(key)
	if t == null:
		ci.draw_circle(at, r - 1.0, fallback)
		return
	var ts := Vector2(t.get_size())
	var side := minf(ts.x, ts.y) / zoom
	# The face sits in the upper middle of a portrait (zoom > 1 goes in on the head).
	var o := Vector2((ts.x - side) / 2.0, (ts.y - side) * (0.12 if zoom <= 1.0 else 0.42)) / ts
	var sc := Vector2(side, side) / ts
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		var u := Vector2(cos(a), sin(a))
		pts.append(at + u * r)
		uvs.append(o + (u * 0.5 + Vector2(0.5, 0.5)) * sc)
	ci.draw_colored_polygon(pts, Color.WHITE, uvs, t)
	ci.draw_arc(at, r, 0, TAU, 28, Color(0, 0, 0, 0.35), 1.0, true)


## A name tag: dark rounded pill, optional color dot, text. `at` is the middle of its top edge.
## Returns the box it covers.
static func tag_rect(font: Font, at: Vector2, text: String, fs: int, dot := false) -> Rect2:
	var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var w := ts.x + 18.0 + (14.0 if dot else 0.0)
	var h := fs + 9.0
	return Rect2(at.x - w / 2.0, at.y, w, h)


static func tag(ci: CanvasItem, font: Font, at: Vector2, text: String, fs: int, fg: Color, dot_color := Color(0, 0, 0, 0), lit := false, door := false) -> Rect2:
	var dot := dot_color.a > 0.0
	var r := tag_rect(font, at, text, fs, dot)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(INK, 0.94 if lit else 0.8)
	box.set_corner_radius_all(int(r.size.y / 2.0))
	if lit:
		box.border_color = Color(1, 1, 1, 0.9)
		box.set_border_width_all(2)
	else:
		box.border_color = Color(1, 1, 1, 0.12)
		box.set_border_width_all(1)
	ci.draw_style_box(box, r)
	var x := r.position.x + 9.0
	if dot:
		ci.draw_circle(Vector2(x + 4.0, r.position.y + r.size.y / 2.0), 5.5 if door else 4.5, dot_color)
		if door:
			# A white middle: a door you can walk through.
			ci.draw_circle(Vector2(x + 4.0, r.position.y + r.size.y / 2.0), 2.4, Color.WHITE)
		x += 14.0
	ci.draw_string(font, Vector2(x, r.position.y + fs + 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, fg)
	return r


## A five-point star (card shops).
static func star(ci: CanvasItem, at: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + TAU * i / 10.0
		pts.append(at + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	ci.draw_colored_polygon(pts, col)


## A place pin for the small map: a dot in the place's color, a gold star for a card shop,
## a white middle for a door you can walk through.
static func pin(ci: CanvasItem, at: Vector2, col: Color, shop: bool, enter: bool, r := 6.0) -> void:
	ci.draw_circle(at, r + 2.0, Color(0, 0, 0, 0.65))
	if shop:
		ci.draw_circle(at, r + 1.0, INK)
		star(ci, at, r + 1.5, Color("ffd166"))
		return
	ci.draw_circle(at, r, col)
	if enter:
		ci.draw_circle(at, r * 0.42, Color.WHITE)


## You: a soft cone for where you look and an arrow.
static func you(ci: CanvasItem, at: Vector2, fwd: Vector2, k: float, accent: Color) -> void:
	var side := Vector2(-fwd.y, fwd.x)
	var cone := PackedVector2Array([at])
	var cols := PackedColorArray([Color(1, 1, 1, 0.34)])
	for i in 9:
		var a := lerpf(-0.55, 0.55, i / 8.0)
		cone.append(at + (fwd * cos(a) + side * sin(a)) * k * 4.6)
		cols.append(Color(1, 1, 1, 0.0))
	ci.draw_polygon(cone, cols)
	var shape := PackedVector2Array([at + fwd * k * 1.3, at - fwd * k * 0.75 + side * k * 0.85, at - fwd * k * 0.3, at - fwd * k * 0.75 - side * k * 0.85])
	var sh := PackedVector2Array()
	for p in shape:
		sh.append(p + Vector2(0, 2))
	ci.draw_colored_polygon(sh, Color(0, 0, 0, 0.5))
	ci.draw_colored_polygon(shape, Color.WHITE)
	shape.append(shape[0])
	ci.draw_polyline(shape, accent, 2.0, true)


## Dark corners, so what is in the middle reads and the frame feels like one piece.
static func vignette(ci: CanvasItem, size: Vector2, depth: float, strength := 0.55) -> void:
	var edge := Color(INK, strength)
	var none := Color(INK, 0.0)
	ci.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, depth), Vector2(0, depth)]), PackedColorArray([edge, edge, none, none]))
	ci.draw_polygon(PackedVector2Array([Vector2(0, size.y - depth), Vector2(size.x, size.y - depth), Vector2(size.x, size.y), Vector2(0, size.y)]), PackedColorArray([none, none, edge, edge]))
	ci.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(depth, 0), Vector2(depth, size.y), Vector2(0, size.y)]), PackedColorArray([edge, none, none, edge]))
	ci.draw_polygon(PackedVector2Array([Vector2(size.x - depth, 0), Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(size.x - depth, size.y)]), PackedColorArray([none, edge, edge, none]))
