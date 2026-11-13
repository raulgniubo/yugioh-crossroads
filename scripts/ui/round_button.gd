class_name RoundButton
extends Button
## A round comic icon button: colored disc, ink outline, hard shadow, a drawn icon.
## Icons: gear, log, piles, pause, back, close, home.

var kind := "gear"
var tint := Comic.BLUE
var _hover := 0.0


func _init(k := "gear", color := Comic.BLUE, d := 72.0) -> void:
	kind = k
	tint = color
	custom_minimum_size = Vector2(d, d)
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())
	mouse_entered.connect(func(): Sfx.play("blip", -18.0, 1.4))


func _process(delta: float) -> void:
	var goal := 1.0 if is_hovered() else 0.0
	if not is_equal_approx(_hover, goal):
		_hover = move_toward(_hover, goal, delta * 9.0)
		queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 4.0
	var down := button_pressed or is_pressed()
	var lift := Vector2(0, 3 if down else -2.0 * _hover)
	var col := tint.lerp(Comic.ORANGE if tint != Comic.ORANGE else Comic.YELLOW, _hover)
	draw_circle(c + Vector2(0, 6), r, Color(Comic.INK, 0.6))
	draw_circle(c + lift, r, Comic.INK)
	draw_circle(c + lift, r - 4.0, col.darkened(0.18))
	draw_circle(c + lift + Vector2(0, -2), r - 6.0, col)
	draw_arc(c + lift, r - 9.0, PI * 1.1, PI * 1.75, 12, Color(1, 1, 1, 0.5), 3.0, true)
	var o := c + lift
	var w := Color.WHITE
	var k := r / 32.0
	match kind:
		"gear":
			for i in 8:
				var a := i * TAU / 8.0
				var d := Vector2(cos(a), sin(a))
				draw_line(o + d * 9.0 * k, o + d * 18.0 * k, Comic.INK, 10.0 * k, true)
			draw_circle(o, 14.0 * k, Comic.INK)
			for i in 8:
				var a := i * TAU / 8.0
				var d := Vector2(cos(a), sin(a))
				draw_line(o + d * 9.0 * k, o + d * 16.5 * k, w, 6.0 * k, true)
			draw_circle(o, 12.0 * k, w)
			draw_circle(o, 5.0 * k, col.darkened(0.25))
		"log":
			for i in 3:
				var y := (-10.0 + i * 10.0) * k
				draw_circle(o + Vector2(-13.0 * k, y), 3.2 * k, w)
				draw_line(o + Vector2(-6.0 * k, y), o + Vector2(15.0 * k, y), w, 5.0 * k, true)
		"piles":
			for i in 3:
				var off := Vector2((i - 1) * 5.0, (1 - i) * 4.0) * k
				var rect := Rect2(o + off + Vector2(-9, -13) * k, Vector2(18, 26) * k)
				draw_rect(rect.grow(2.0), Comic.INK)
				draw_rect(rect, w if i == 2 else Color(0.82, 0.88, 1.0))
		"pause":
			draw_rect(Rect2(o + Vector2(-10, -12) * k, Vector2(7, 24) * k), w)
			draw_rect(Rect2(o + Vector2(3, -12) * k, Vector2(7, 24) * k), w)
		"back":
			draw_colored_polygon(PackedVector2Array([o + Vector2(-14, 0) * k, o + Vector2(2, -13) * k, o + Vector2(2, -5) * k, o + Vector2(14, -5) * k,
					o + Vector2(14, 5) * k, o + Vector2(2, 5) * k, o + Vector2(2, 13) * k]), w)
		"close":
			draw_line(o + Vector2(-10, -10) * k, o + Vector2(10, 10) * k, w, 6.0 * k, true)
			draw_line(o + Vector2(10, -10) * k, o + Vector2(-10, 10) * k, w, 6.0 * k, true)
		"power":
			draw_arc(o, 12.0 * k, -PI * 0.3, PI * 1.3, 20, w, 5.0 * k, true)
			draw_line(o + Vector2(0, -16) * k, o + Vector2(0, -2) * k, w, 5.0 * k, true)
