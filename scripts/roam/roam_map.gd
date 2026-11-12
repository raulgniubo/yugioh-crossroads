class_name RoamMap
extends Control
## The city map: a small one in the corner while you walk, and a big one on M.

const LANDMARKS := [
	{"name": "Kame Game", "pos": Vector2(-10, -19.5), "size": Vector2(9.5, 6), "color": Color("ffd166"), "enter": true},
	{"name": "KaibaCorp", "pos": Vector2(0, -47), "size": Vector2(12, 12), "color": Color("7cc4ff")},
	{"name": "Duel Dome", "pos": Vector2(-50, 0), "size": Vector2(16, 22), "color": Color("b48cff")},
	{"name": "Domino High", "pos": Vector2(50, 0), "size": Vector2(14, 24), "color": Color("ffe9a8")},
	{"name": "Clock Tower", "pos": Vector2(0, 46), "size": Vector2(7, 7), "color": Color("9ad6c8")},
	{"name": "Arcade", "pos": Vector2(12.5, -16.5), "size": Vector2(6, 9), "color": Color("5affc0")},
	{"name": "Cafe", "pos": Vector2(24, -12.5), "size": Vector2(8, 6), "color": Color("ffb030")},
	{"name": "Central Park", "pos": Vector2(19, 19), "size": Vector2(22, 22), "color": Color("4fbf6a"), "park": true},
	{"name": "Mart", "pos": Vector2(-24, -13), "size": Vector2(9, 5), "color": Color("9fb4c8")},
	{"name": "Ramen", "pos": Vector2(9.6, 26.5), "size": Vector2(3, 3.6), "color": Color("ff7a5a")},
]

var full := false
var title := "DOMINO CITY"
var area := "Downtown"
var layout := {}        # {"island": radius, "landmarks": [...], "paths": [[a, b], ...]} for places that aren't the city grid
var player_pos := Vector2.ZERO
var player_yaw := 0.0
var inside := ""
var npcs: Array = []   # [{pos: Vector2, state: "duel"|"beaten"|"talk", name}]
var accent := Color("2de2e6")
var _font: Font
var _bold: Font


func _ready() -> void:
	_font = UITheme.semi_font()
	_bold = UITheme.title_font()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.03, 0.05, 0.09, 0.93 if full else 0.8)
	bg.set_corner_radius_all(26 if full else 20)
	bg.border_color = Color(accent, 0.55)
	bg.set_border_width_all(2)
	draw_style_box(bg, r)
	var center := size / 2.0 + (Vector2(0, 26) if full else Vector2.ZERO)
	var span := 160.0 if layout.has("island") else 128.0
	var scale := (minf(size.x, size.y - 90.0) / span) if full else (2.4 if layout.has("island") else 3.3)
	var origin := Vector2.ZERO if full or inside != "" else player_pos
	if inside != "":
		origin = Vector2(-10, -19.5) if not full else Vector2.ZERO
	var to_map := func(w: Vector2) -> Vector2: return center + (w - origin) * scale
	var marks: Array = layout.get("landmarks", LANDMARKS)
	if layout.has("island"):
		# Sea, sand, grass and footpaths
		var rad := float(layout["island"])
		draw_rect(Rect2(to_map.call(Vector2(-80, -80)), Vector2(160, 160) * scale), Color(0.05, 0.16, 0.26))
		draw_circle(to_map.call(Vector2.ZERO), (rad + 6.0) * scale, Color(0.74, 0.67, 0.5))
		draw_circle(to_map.call(Vector2.ZERO), (rad - 6.0) * scale, Color(0.2, 0.36, 0.2))
		for pth in layout.get("paths", []):
			draw_line(to_map.call(pth[0]), to_map.call(pth[1]), Color(0.8, 0.76, 0.66), maxf(3.0, 4.0 * scale))
	else:
		draw_rect(Rect2(to_map.call(Vector2(-64, -64)), Vector2(128, 128) * scale), Color(0.09, 0.1, 0.13))
	for qx in ([-1, 1] if not layout.has("island") else []):
		for qz in [-1, 1]:
			var c := Vector2(qx * 21.5, qz * 21.5)
			draw_rect(Rect2(to_map.call(c - Vector2(15.5, 15.5)), Vector2(31, 31) * scale), Color(0.2, 0.21, 0.25))
	for i in (range(-12, 13) if not layout.has("island") else []):
		if absi(i) <= 1:
			continue
		draw_rect(Rect2(to_map.call(Vector2(i * 5.0 - 1.1, -0.12)), Vector2(2.2, 0.3) * scale), Color(0.95, 0.75, 0.2, 0.6))
		draw_rect(Rect2(to_map.call(Vector2(-0.12, i * 5.0 - 1.1)), Vector2(0.3, 2.2) * scale), Color(0.95, 0.75, 0.2, 0.6))
	draw_arc(to_map.call(Vector2.ZERO), 3.0 * scale, 0, TAU, 32, Color(accent, 0.8), 2.0)
	# Landmarks
	for l in marks:
		var sz: Vector2 = l["size"] * scale
		var p: Vector2 = to_map.call(l["pos"])
		var col: Color = l["color"]
		var box := StyleBoxFlat.new()
		box.bg_color = Color(col, 0.35 if l.get("park", false) else 0.8)
		box.set_corner_radius_all(int(maxf(3.0, 1.2 * scale)))
		if l.get("enter", false):
			box.border_color = Color.WHITE
			box.set_border_width_all(2)
		draw_style_box(box, Rect2(p - sz / 2.0, sz))
		if full:
			var label: String = l["name"] + ("  (enter)" if l.get("enter", false) else "")
			var w := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
			var ly := (-sz.y / 2.0 - 8.0) if l.get("enter", false) else (sz.y / 2.0 + 20.0)
			draw_string_outline(_font, p + Vector2(-w / 2.0, ly), Loc.t(label), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, 5, Color(0, 0, 0, 0.85))
			draw_string(_font, p + Vector2(-w / 2.0, ly), Loc.t(label), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, col.lightened(0.45))
	# People
	for n in npcs:
		var p: Vector2 = to_map.call(n["pos"])
		var col := Color("ff5a6e") if n["state"] == "duel" else (Color("5aff9a") if n["state"] == "beaten" else Color(1, 1, 1, 0.85))
		draw_circle(p, 6.0 if full else 4.5, Color(0, 0, 0, 0.7))
		draw_circle(p, 4.5 if full else 3.2, col)
		if full:
			draw_string_outline(_font, p + Vector2(9, 6), Loc.t(str(n["name"])), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, 4, Color(0, 0, 0, 0.85))
			draw_string(_font, p + Vector2(9, 6), Loc.t(str(n["name"])), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, col.lightened(0.3))
	# You
	var me: Vector2 = to_map.call(player_pos if inside == "" else Vector2(-10, -17.0))
	var fwd := Vector2(sin(player_yaw), cos(player_yaw)) * -1.0
	var side := Vector2(-fwd.y, fwd.x)
	var k := 11.0 if full else 9.0
	draw_colored_polygon(PackedVector2Array([me + fwd * k * 1.25, me - fwd * k * 0.7 + side * k * 0.8, me - fwd * k * 0.25, me - fwd * k * 0.7 - side * k * 0.8]), Color.WHITE)
	draw_polyline(PackedVector2Array([me + fwd * k * 1.25, me - fwd * k * 0.7 + side * k * 0.8, me - fwd * k * 0.25, me - fwd * k * 0.7 - side * k * 0.8, me + fwd * k * 1.25]), accent, 2.0)
	if full:
		draw_string(_bold, Vector2(34, 54), Loc.t(title), HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color.WHITE)
		var where := "You are inside Kame Game" if inside != "" else area
		draw_string(_font, Vector2(36, 82), Loc.t(where), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, accent)
		var lx := size.x - 600.0
		for item in [["wants to duel", Color("ff5a6e")], ["beaten", Color("5aff9a")], ["talk", Color(1, 1, 1, 0.85)]]:
			draw_circle(Vector2(lx, 47), 6.0, item[1])
			draw_string(_font, Vector2(lx + 13, 54), Loc.t(item[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.75))
			lx += 26.0 + _font.get_string_size(item[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 18.0
		draw_string(_font, Vector2(lx + 8, 54), Loc.t("M / Esc  close"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.5))
	else:
		draw_string_outline(_font, Vector2(14, size.y - 12), Loc.t("M  map"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(0, 0, 0, 0.8))
		draw_string(_font, Vector2(14, size.y - 12), Loc.t("M  map"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.75))
		draw_string_outline(_font, Vector2(size.x / 2.0 - 5, 20), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, Color(0, 0, 0, 0.8))
		draw_string(_font, Vector2(size.x / 2.0 - 5, 20), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, accent)
