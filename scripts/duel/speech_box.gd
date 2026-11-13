class_name SpeechBox
extends Control
## A comic speech box: bold white box, thick ink outline, a tail toward the speaker and the
## speaker's name on a slanted tag that pops out of the top corner.

var side := 0
var _label: Label
var _name := ""
var tail := ""                   # "dl" down-left, "dr" down-right, "ur" up-right; "" = by side


func _init(p: int) -> void:
	side = p
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 30
	_label = UITheme.label("", 27, Comic.INK, UITheme.title_font())
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_constant_override("outline_size", 0)
	_label.add_theme_constant_override("line_spacing", -2)
	add_child(_label)


func set_line(who: String, text: String) -> void:
	_name = who.to_upper()
	_label.text = text
	var f := UITheme.title_font()
	var one := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 27).x
	var w := clampf(one + 4.0, 190.0, 430.0)
	_label.custom_minimum_size = Vector2(w, 0)
	_label.size = Vector2(w, 0)
	var h := f.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, w, 27).y
	_label.position = Vector2(26, 30)
	_label.size = Vector2(w, h)
	size = Vector2(w + 52, h + 52)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var col := Comic.BLUE if side == 0 else Comic.RED
	# The tail points at the speaker: down-left for you, up-right for them.
	var kind := tail if tail != "" else ("dl" if side == 0 else "ur")
	var up := kind == "ur"
	var tail := PackedVector2Array([Vector2(34, size.y - 6), Vector2(-26, size.y + 34), Vector2(84, size.y - 6)])
	if kind == "dr":
		tail = PackedVector2Array([Vector2(size.x - 84, size.y - 6), Vector2(size.x + 26, size.y + 34), Vector2(size.x - 34, size.y - 6)])
	elif kind == "ur":
		tail = PackedVector2Array([Vector2(size.x - 84, 6), Vector2(size.x + 26, -30), Vector2(size.x - 34, 6)])
	var sb := StyleBoxFlat.new()
	sb.bg_color = Comic.CREAM
	sb.border_color = Comic.INK
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(20)
	sb.shadow_color = Color(Comic.INK, 0.55)
	sb.shadow_size = 1
	sb.shadow_offset = Vector2(0, 7)
	sb.anti_aliasing = true
	var t2 := PackedVector2Array()
	for p in tail:
		t2.append(p + Vector2(0, 7))
	draw_colored_polygon(t2, Color(Comic.INK, 0.55))
	draw_colored_polygon(tail, Comic.INK)
	draw_style_box(sb, r)
	# The tail's inside, drawn over the border so the box and the tail read as one shape.
	var c := (tail[0] + tail[2]) / 2.0
	var inner := PackedVector2Array()
	for p in tail:
		inner.append(p.lerp(c, 0.2) + (Vector2(0, 7) if up else Vector2(0, -7)))
	draw_colored_polygon(inner, Comic.CREAM)
	# Halftone in the far corner.
	Comic.dots(self, PackedVector2Array([Vector2(12, 12), Vector2(size.x - 12, 12), Vector2(size.x - 12, size.y - 12), Vector2(12, size.y - 12)]),
			Color(col, 0.16), Vector2(1, 1) if side == 0 else Vector2(0, 1), 12.0, 4.5, 0.42)
	# The name tag.
	var f := Comic.chunky_font()
	var nw := f.get_string_size(_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	var tag := Rect2(16 if side == 0 else size.x - nw - 62, -20, nw + 46, 38)
	Comic.slab(self, tag, 12.0, col.lightened(0.1), col.darkened(0.2), 4.0, Vector2(0, 4))
	Comic.text(self, f, tag.position + Vector2(22, 28), _name, 22, Color.WHITE, 6)
