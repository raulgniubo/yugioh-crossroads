class_name SpeechBox
extends Control
## A speech box: clean white, a small tail toward the speaker and their name on a slim tag.

var side := 0
var _label: Label
var _name := ""
var tail := ""                   # "dl" down-left, "dr" down-right, "ur" up-right; "" = by side


func _init(p: int) -> void:
	side = p
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 30
	_label = UITheme.label("", 25, Comic.INK, UITheme.body_font())
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func set_line(who: String, text: String) -> void:
	_name = who.to_upper()
	_label.text = text
	var f := UITheme.body_font()
	var one := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 25).x
	var w := clampf(one + 6.0, 170.0, 440.0)
	var h := f.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, w, 25).y
	_label.position = Vector2(22, 24)
	_label.size = Vector2(w, h)
	size = Vector2(w + 44, h + 42)
	queue_redraw()


func _draw() -> void:
	var col := Comic.BLUE if side == 0 else Comic.RED
	var kind := tail if tail != "" else ("dl" if side == 0 else "ur")
	var tip := PackedVector2Array([Vector2(30, size.y - 2), Vector2(-12, size.y + 22), Vector2(64, size.y - 2)])
	if kind == "dr":
		tip = PackedVector2Array([Vector2(size.x - 64, size.y - 2), Vector2(size.x + 12, size.y + 22), Vector2(size.x - 30, size.y - 2)])
	elif kind == "ur":
		tip = PackedVector2Array([Vector2(size.x - 64, 2), Vector2(size.x + 12, -20), Vector2(size.x - 30, 2)])
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.97, 0.98, 1.0, 0.98)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 12
	sb.shadow_offset = Vector2(0, 4)
	sb.anti_aliasing = true
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	draw_colored_polygon(tip, Color(0.97, 0.98, 1.0, 0.98))
	# The name: a slim tag in the speaker's color on the top edge.
	var f := Comic.button_font()
	var nw := f.get_string_size(_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	var tag := Rect2(14 if kind != "ur" and kind != "dr" else size.x - nw - 46, -13, nw + 32, 26)
	Comic.shape(self, Comic.quad(tag, 8.0), col, col.darkened(0.25), 0.0, Vector2(0, 2))
	draw_string(f, tag.position + Vector2(16, 19), _name, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
