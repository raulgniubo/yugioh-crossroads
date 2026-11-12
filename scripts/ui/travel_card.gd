class_name TravelCard
extends Control
## The trip between two worlds: a short ride across the screen (a ferry over the water, or a
## streak down the road) with where you are leaving and where you are going. Await play().

var from_name := ""
var to_name := ""
var by_sea := true
var _t := 0.0
var _title: Font
var _semi: Font


func _init(from_place: String, to_place: String, sea := true) -> void:
	from_name = from_place
	to_name = to_place
	by_sea = sea


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 200
	_title = UITheme.title_font()
	_semi = UITheme.semi_font()
	modulate.a = 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var k := clampf(_t / 2.6, 0.0, 1.0)
	if by_sea:
		# Sky, sun, sea in bands, a ferry crossing.
		for i in 12:
			draw_rect(Rect2(0, h * 0.62 * i / 12.0, w, h * 0.62 / 12.0 + 1), Color(0.35, 0.62, 0.92).lerp(Color(1.0, 0.82, 0.62), i / 11.0))
		draw_circle(Vector2(w * 0.74, h * 0.5), h * 0.11, Color(1.0, 0.93, 0.75))
		for i in 9:
			var y := h * 0.62 + (h * 0.38) * i / 9.0
			var pts := PackedVector2Array()
			var seg := 48
			for s in seg + 1:
				var x := w * s / float(seg)
				pts.append(Vector2(x, y + sin(x * 0.012 + _t * (1.4 + i * 0.25) + i) * (5.0 + i * 1.6)))
			pts.append(Vector2(w, h))
			pts.append(Vector2(0, h))
			draw_colored_polygon(pts, Color(0.08, 0.32, 0.55).lerp(Color(0.03, 0.14, 0.3), i / 8.0))
		var bx := lerpf(w * 0.12, w * 0.78, ease(k, -1.6))
		var by := h * 0.66 + sin(_t * 2.2) * 6.0
		var hull := PackedVector2Array([Vector2(bx - 150, by - 30), Vector2(bx + 170, by - 30), Vector2(bx + 120, by + 26), Vector2(bx - 120, by + 26)])
		draw_colored_polygon(hull, Color(0.95, 0.96, 0.98))
		draw_rect(Rect2(bx - 150, by - 12, 320, 8), Color(0.85, 0.2, 0.18))
		draw_rect(Rect2(bx - 90, by - 78, 170, 50), Color(0.9, 0.92, 0.95))
		for i in 5:
			draw_rect(Rect2(bx - 78 + i * 32, by - 66, 20, 18), Color(0.3, 0.6, 0.85))
		draw_rect(Rect2(bx + 10, by - 118, 34, 42), Color(0.85, 0.2, 0.18))
		for i in 4:
			draw_circle(Vector2(bx + 20 - i * 34 - fmod(_t * 40.0, 34.0), by - 132 - i * 16), 12.0 + i * 5.0, Color(1, 1, 1, 0.35 - i * 0.07))
		for i in 6:
			draw_circle(Vector2(bx - 170 - i * 26, by + 24 + sin(_t * 5.0 + i) * 3.0), 9.0 - i, Color(1, 1, 1, 0.5 - i * 0.07))
	else:
		draw_rect(Rect2(0, 0, w, h), Color(0.02, 0.03, 0.07))
		for i in 60:
			var y := fposmod(i * 97.0, h)
			var sp := 900.0 + (i % 7) * 260.0
			var x := fposmod(i * 211.0 - _t * sp, w + 400.0) - 200.0
			draw_line(Vector2(x, y), Vector2(x + 160.0 + (i % 5) * 60.0, y), Color(UITheme.ACCENT, 0.12 + (i % 4) * 0.06), 2.0 + i % 3)
	# Where from, where to.
	draw_rect(Rect2(0, h * 0.1, w, 150), Color(0, 0, 0, 0.45))
	var line := "%s   ▸   %s" % [Loc.t(from_name).to_upper(), Loc.t(to_name).to_upper()]
	var fs := 64
	while fs > 30 and _title.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > w - 120:
		fs -= 2
	var lw := _title.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(_title, Vector2((w - lw) / 2.0, h * 0.1 + 76), line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	var sub := Loc.t("The ferry is crossing...") if by_sea else Loc.t("On the way...")
	var sw := _semi.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	draw_string(_semi, Vector2((w - sw) / 2.0, h * 0.1 + 122), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(1, 1, 1, 0.75))
	# Progress dots.
	for i in 5:
		draw_circle(Vector2(w / 2.0 - 60 + i * 30, h * 0.9), 6.0, Color(1, 1, 1, 0.9 if k * 5.0 > i else 0.25))


func play() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.3)
	await tw.finished
	if by_sea:
		Sfx.play("wave", -6.0)
		get_tree().create_timer(0.8).timeout.connect(func(): Sfx.play("gull", -10.0))
	else:
		Sfx.play("whoosh", -6.0)
	await get_tree().create_timer(2.4).timeout
