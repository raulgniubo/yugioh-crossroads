class_name StoryEmblem
extends Control
## The main story's mark for a save: a blank card standing on its edge, framed in the color of
## the era the chapter is in, with a small light in the middle (the story starts with a deck of
## blank cards). Ours: no card back, no emblem of anybody's. `era`: index into ERA_COLORS, -1
## for a plain grey one (no story in that save). `mark`: a short word under the light ("2", "P").

const ERA_COLORS := {
	"Crossroads": Color("7fe8ff"),
	"Duel Monsters": Color("c08cff"),
	"GX": Color("ff4d5e"),
	"5D's": Color("ff8a3a"),
	"ZEXAL": Color("ffd23a"),
}

var color := Color("7fe8ff"): set = set_color
var mark := ""
var lit := 1.0          # 0..1: dimmed for an empty slot
var _t := 0.0


func _init(col := Color("7fe8ff"), word := "", side := 96.0) -> void:
	color = col
	mark = word
	custom_minimum_size = Vector2(side * 0.78, side * 1.1)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


static func era_color(era: String) -> Color:
	return ERA_COLORS.get(era, Color(0.45, 0.48, 0.56))


func set_color(c: Color) -> void:
	color = c
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _ready() -> void:
	set_process(lit > 0.5)
	if mark != "":
		var l := UITheme.label(mark, int(custom_minimum_size.y * 0.22), Color(1, 1, 1, 0.95 * lit + 0.3 * (1.0 - lit)), UITheme.title_font())
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.offset_top = custom_minimum_size.y * 0.52
		l.offset_bottom = -custom_minimum_size.y * 0.06
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(l)


func _round_rect(r: Rect2, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad),
		Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
	var start := [-PI / 2.0, 0.0, PI / 2.0, PI]
	for i in 4:
		for k in 7:
			var ang: float = start[i] + float(k) / 6.0 * PI / 2.0
			pts.append(corners[i] + Vector2(cos(ang), sin(ang)) * rad)
	return pts


func _draw() -> void:
	var w := size.x
	var h := size.y
	var col := color.lerp(Color(0.2, 0.22, 0.28), 1.0 - lit)
	var outer := Rect2(Vector2.ZERO, Vector2(w, h))
	draw_colored_polygon(_round_rect(outer, w * 0.12), Color(0.02, 0.03, 0.07, 0.92))
	draw_colored_polygon(_round_rect(outer.grow(-w * 0.05), w * 0.1), col.darkened(0.25))
	# The blank face: pale, with a soft wash of the era's color at the foot.
	var face := outer.grow(-w * 0.1)
	draw_colored_polygon(_round_rect(face, w * 0.07), Color(0.93, 0.95, 1.0).lerp(col, 0.12).lerp(Color(0.3, 0.32, 0.38), 1.0 - lit))
	var foot := Rect2(face.position + Vector2(0, face.size.y * 0.5), Vector2(face.size.x, face.size.y * 0.5))
	draw_colored_polygon(_round_rect(foot, w * 0.07), Color(col, 0.55 * lit + 0.1))
	# The light in the middle of the blank face: a four-pointed spark that breathes.
	var c := Vector2(w * 0.5, h * 0.36)
	var breath := 0.85 + 0.15 * sin(_t * 1.6) if lit > 0.5 else 0.8
	var ro := w * 0.24 * breath
	var ri := ro * 0.22
	var spark := PackedVector2Array()
	for i in 8:
		var ang := -PI / 2.0 + i * PI / 4.0
		spark.append(c + Vector2(cos(ang), sin(ang)) * (ro if i % 2 == 0 else ri))
	draw_circle(c, ro * 0.9, Color(col.lightened(0.4), 0.18 * lit))
	draw_colored_polygon(spark, Color(col.darkened(0.15), 0.95 * lit + 0.2 * (1.0 - lit)))
	draw_circle(c, ri * 0.9, Color(1, 1, 1, 0.95 * lit + 0.3 * (1.0 - lit)))
	draw_polyline(_round_rect(outer.grow(-w * 0.05), w * 0.1) + PackedVector2Array([_round_rect(outer.grow(-w * 0.05), w * 0.1)[0]]), Color(1, 1, 1, 0.22 * lit), 1.5, true)
