class_name RoundButton
extends Button
## A round icon button: glass disc, thin edge, a drawn icon. Amber under the pointer or focus.
## Icons: gear, log, piles, pause, back, close, power.

var kind := "gear"
var tint := Comic.BLUE
var _hover := 0.0


func _init(k := "gear", color := Comic.BLUE, d := 64.0) -> void:
	kind = k
	tint = color
	custom_minimum_size = Vector2(d, d)
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())
	mouse_entered.connect(func(): Sfx.play("blip", -18.0, 1.4))
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _process(delta: float) -> void:
	var goal := 1.0 if is_hovered() or has_focus() else 0.0
	if not is_equal_approx(_hover, goal):
		_hover = move_toward(_hover, goal, delta * 9.0)
		queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 3.0
	var down := is_pressed()
	var o := c + Vector2(0, 1 if down else 0)
	draw_circle(c + Vector2(0, 3), r + 1.0, Color(0, 0, 0, 0.3))
	draw_circle(o, r, Color(0.05, 0.075, 0.16, 0.95).lerp(UITheme.ACCENT, _hover))
	draw_arc(o, r, 0.0, TAU, 48, Color(1, 1, 1, 0.22).lerp(Color.WHITE, _hover), 1.5, true)
	var w := Color.WHITE.lerp(Comic.INK, _hover)
	if tint == Comic.RED and _hover < 0.5:
		w = Color("ff8a98")
	var k := r / 30.0
	match kind:
		"gear":
			for i in 8:
				var a := i * TAU / 8.0
				var d := Vector2(cos(a), sin(a))
				draw_line(o + d * 8.0 * k, o + d * 15.0 * k, w, 5.0 * k, true)
			draw_arc(o, 8.5 * k, 0.0, TAU, 24, w, 4.5 * k, true)
		"log":
			for i in 3:
				var y := (-9.0 + i * 9.0) * k
				draw_circle(o + Vector2(-12.0 * k, y), 2.4 * k, w)
				draw_line(o + Vector2(-6.0 * k, y), o + Vector2(13.0 * k, y), w, 3.4 * k, true)
		"piles":
			for i in 2:
				var off := Vector2((i * 2 - 1) * 3.5, (1 - i * 2) * 3.0) * k
				var rect := Rect2(o + off + Vector2(-8, -12) * k, Vector2(16, 24) * k)
				draw_rect(rect, Color(0.05, 0.075, 0.16).lerp(UITheme.ACCENT, _hover))
				draw_rect(rect, w, false, 2.4 * k)
		"pause":
			draw_rect(Rect2(o + Vector2(-9, -11) * k, Vector2(6, 22) * k), w)
			draw_rect(Rect2(o + Vector2(3, -11) * k, Vector2(6, 22) * k), w)
		"back":
			draw_polyline(PackedVector2Array([o + Vector2(3, -11) * k, o + Vector2(-8, 0) * k, o + Vector2(3, 11) * k]), w, 4.0 * k, true)
		"close":
			draw_line(o + Vector2(-9, -9) * k, o + Vector2(9, 9) * k, w, 4.0 * k, true)
			draw_line(o + Vector2(9, -9) * k, o + Vector2(-9, 9) * k, w, 4.0 * k, true)
		"power":
			draw_arc(o, 11.0 * k, -PI * 0.28, PI * 1.28, 20, w, 3.6 * k, true)
			draw_line(o + Vector2(0, -15) * k, o + Vector2(0, -2) * k, w, 3.6 * k, true)
