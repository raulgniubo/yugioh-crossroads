class_name VsCard
extends Control
## The full-screen VS card before a duel: the two duelists on either side of a lit diagonal
## slash, each over their own color with speed lines behind, name plates, and a VS emblem that
## slams in. Call play() and await it.

var left := {}
var right := {}
var slide := 0.0          # 0: both halves off screen, 1: in place
var vs_k := 0.0           # VS emblem: 0 hidden, 1 landed
var flash := 0.0
var shake := 0.0
var leave := 0.0          # 0..1 wipes the card away
var _t := 0.0
var _polys: Array = []    # [Polygon2D, side]
var _title: Font
var _semi: Font
var _streaks: Array = []


func _init(l: Dictionary, r: Dictionary) -> void:
	left = l
	right = r


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_title = UITheme.title_font()
	_semi = UITheme.semi_font()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 46:
		_streaks.append([rng.randf(), rng.randf(), rng.randf_range(80.0, 420.0), rng.randf_range(1.0, 3.5), rng.randf_range(0.6, 1.6), i % 2])
	for side in 2:
		var d: Dictionary = left if side == 0 else right
		var pg := Polygon2D.new()
		pg.texture = Portraits.get_portrait(str(d.get("key", "")))
		pg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(pg)
		_polys.append([pg, side])
	var top := Control.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.draw.connect(func(): _draw_top(top))
	add_child(top)
	set_meta("top", top)


func _shape(side: int, w: float, h: float, off: float) -> PackedVector2Array:
	# The slash runs from 56% across at the top to 44% at the bottom.
	if side == 0:
		return PackedVector2Array([Vector2(-off, 0), Vector2(w * 0.56 - off, 0), Vector2(w * 0.44 - off, h), Vector2(-off, h)])
	return PackedVector2Array([Vector2(w * 0.56 + off, 0), Vector2(w + off, 0), Vector2(w + off, h), Vector2(w * 0.44 + off, h)])


func _process(delta: float) -> void:
	_t += delta
	var w := size.x
	var h := size.y
	var off := (1.0 - ease(slide, 0.25)) * w * 0.7 + leave * w * 0.8
	for e in _polys:
		var pg: Polygon2D = e[0]
		var side: int = e[1]
		var o := off * (1.0 if side == 1 else 1.0)
		var shape := _shape(side, w, h, o if side == 1 else o)
		if side == 0:
			shape = _shape(0, w, h, o)
		pg.polygon = shape
		# Cover the half with the portrait, face toward the middle, head near the top.
		var tex := pg.texture
		if tex == null:
			continue
		var ts := tex.get_size()
		var box_w := w * 0.58
		var k := maxf(box_w / ts.x, h * 1.12 / ts.y)
		var drift := sin(_t * 0.6) * 6.0
		var ox := (w * 0.29 - ts.x * k / 2.0 - o + drift) if side == 0 else (w * 0.71 - ts.x * k / 2.0 + o - drift)
		var oy := -h * 0.04
		var uv := PackedVector2Array()
		for p in shape:
			var u := (p.x - ox) / k
			if side == 1:
				u = ts.x - u     # mirror: both face the slash
			uv.append(Vector2(u, (p.y - oy) / k))
		pg.uv = uv
		pg.color = Color(1, 1, 1, 1.0 - leave)
		pg.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * 10.0
	shake = move_toward(shake, 0.0, delta * 3.0)
	flash = move_toward(flash, 0.0, delta * 2.6)
	queue_redraw()
	if has_meta("top"):
		(get_meta("top") as Control).queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var off := (1.0 - ease(slide, 0.25)) * w * 0.7 + leave * w * 0.8
	draw_rect(Rect2(0, 0, w, h), Color(0.01, 0.012, 0.03, 0.97 * (1.0 - leave)))
	for side in 2:
		var d: Dictionary = left if side == 0 else right
		var col: Color = d.get("color", UITheme.ACCENT)
		var shape := _shape(side, w, h, off)
		var dark := col.darkened(0.78)
		var mid := col.darkened(0.35)
		var cols := PackedColorArray([mid, dark, dark, mid]) if side == 0 else PackedColorArray([dark, mid, mid, dark])
		draw_polygon(shape, cols)
		# Speed lines streaking toward the slash.
		for s in _streaks:
			if int(s[5]) != side:
				continue
			var y: float = s[1] * h
			var len: float = s[2]
			var x: float = fposmod(float(s[0]) * w + _t * 900.0 * float(s[4]), w * 0.6 + len) - len
			var xa := (x - off) if side == 0 else (w - x + off)
			var xb := (xa + len) if side == 0 else (xa - len)
			draw_line(Vector2(xa, y), Vector2(xb, y), Color(col.lightened(0.5), 0.13), float(s[3]))
	# Portraits are drawn by the Polygon2D children over this. Everything below goes on top of
	# them through the overlay node.


func _draw_top(c: Control) -> void:
	var w := size.x
	var h := size.y
	var off := (1.0 - ease(slide, 0.25)) * w * 0.7 + leave * w * 0.8
	var a := 1.0 - leave
	# Shade the lower third so names read, on each half.
	for side in 2:
		var shape := _shape(side, w, h, off)
		var top_y := h * 0.58
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for p in shape:
			pts.append(Vector2(p.x, maxf(p.y, top_y)))
			cols.append(Color(0, 0, 0, (0.0 if p.y < h * 0.5 else 0.82) * a))
		c.draw_polygon(pts, cols)
	# The slash: a glowing white edge with colored halos.
	var s0 := Vector2(w * 0.56, -20)
	var s1 := Vector2(w * 0.44, h + 20)
	for g in 6:
		c.draw_line(s0, s1, Color(UITheme.ACCENT, 0.05 * a), 60.0 - g * 9.0)
	c.draw_line(s0, s1, Color(1, 1, 1, 0.95 * a * slide), 7.0)
	c.draw_line(s0 + Vector2(-14, 0), s1 + Vector2(-14, 0), Color(left.get("color", UITheme.ACCENT), 0.8 * a * slide), 3.0)
	c.draw_line(s0 + Vector2(14, 0), s1 + Vector2(14, 0), Color(right.get("color", UITheme.DANGER), 0.8 * a * slide), 3.0)
	# Name plates.
	for side in 2:
		var d: Dictionary = left if side == 0 else right
		var col: Color = d.get("color", UITheme.ACCENT)
		var name := str(d.get("name", "")).to_upper()
		var sub := str(d.get("sub", ""))
		var fs := 92
		while fs > 40 and _title.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > w * 0.4:
			fs -= 2
		var nw := _title.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var x := (w * 0.06 - off) if side == 0 else (w * 0.94 - nw + off)
		var y := h - 150.0
		# A slanted color bar behind the name.
		var bar_w := nw + 90.0
		var bx := x - 40.0 if side == 0 else x - 50.0
		var bar := PackedVector2Array([Vector2(bx + 30, y - fs * 0.86), Vector2(bx + bar_w + 30, y - fs * 0.86), Vector2(bx + bar_w, y + 14), Vector2(bx, y + 14)])
		c.draw_colored_polygon(bar, Color(col.darkened(0.2), 0.88 * a))
		c.draw_polyline(PackedVector2Array([bar[0], bar[1], bar[2], bar[3], bar[0]]), Color(col.lightened(0.5), 0.9 * a), 3.0)
		c.draw_string_outline(_title, Vector2(x, y), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 10, Color(0, 0, 0, 0.7 * a))
		c.draw_string(_title, Vector2(x, y), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, a))
		var sw := _semi.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
		var sx := (x + 4) if side == 0 else (x + nw - sw)
		c.draw_string_outline(_semi, Vector2(sx, y + 58), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 6, Color(0, 0, 0, 0.8 * a))
		c.draw_string(_semi, Vector2(sx, y + 58), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(col.lightened(0.6), a))
	# The VS emblem.
	if vs_k > 0.01:
		var center := Vector2(w * 0.5, h * 0.5)
		var k := lerpf(3.2, 1.0, ease(clampf(vs_k, 0.0, 1.0), 0.3))
		var al := clampf(vs_k * 2.0, 0.0, 1.0) * a
		c.draw_set_transform(center, -0.12, Vector2(k, k))
		var dia := PackedVector2Array([Vector2(0, -150), Vector2(170, 0), Vector2(0, 150), Vector2(-170, 0)])
		c.draw_colored_polygon(dia, Color(0.02, 0.03, 0.07, 0.92 * al))
		c.draw_polyline(PackedVector2Array([dia[0], dia[1], dia[2], dia[3], dia[0]]), Color(UITheme.GOLD, al), 6.0)
		c.draw_polyline(PackedVector2Array([dia[0] * 1.12, dia[1] * 1.12, dia[2] * 1.12, dia[3] * 1.12, dia[0] * 1.12]), Color(1, 1, 1, 0.35 * al), 2.0)
		var vs := "VS"
		var vw := _title.get_string_size(vs, HORIZONTAL_ALIGNMENT_LEFT, -1, 190).x
		c.draw_string_outline(_title, Vector2(-vw / 2.0, 66), vs, HORIZONTAL_ALIGNMENT_LEFT, -1, 190, 18, Color(UITheme.GOLD.darkened(0.55), al))
		c.draw_string(_title, Vector2(-vw / 2.0, 66), vs, HORIZONTAL_ALIGNMENT_LEFT, -1, 190, Color(1, 0.97, 0.86, al))
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if flash > 0.01:
		c.draw_rect(Rect2(0, 0, w, h), Color(1, 1, 1, flash * 0.55))


func play() -> void:
	var top: Control = get_meta("top")
	top.set_process(true)
	var redraw := func(_v = null): top.queue_redraw()
	Sfx.play("turn")
	var tw := create_tween()
	tw.tween_method(func(v: float):
		slide = v
		top.queue_redraw(), 0.0, 1.0, 0.55).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await tw.finished
	flash = 0.6
	var tv := create_tween()
	tv.tween_method(func(v: float):
		vs_k = v
		top.queue_redraw(), 0.0, 1.0, 0.28)
	await tv.finished
	Sfx.play("vs")
	shake = 1.0
	flash = 0.9
	var hold := 0.0
	while hold < 1.7:
		await get_tree().process_frame
		hold += get_process_delta_time()
		redraw.call()
	var out := create_tween()
	out.tween_method(func(v: float):
		leave = v
		top.queue_redraw(), 0.0, 1.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await out.finished
