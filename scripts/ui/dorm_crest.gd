class_name DormCrest
extends Control
## A dorm's crest, drawn: a shield in the dorm's color with a paler shield inside it, a band
## across and a star. Ours, not anybody's emblem. `dorm`: 0 Red, 1 Yellow, 2 Blue; -1 a plain
## grey one (no game in that save).

var dorm := 0: set = set_dorm
var lit := 1.0          # 0..1: dimmed for an empty slot


func _init(d := 0, side := 96.0) -> void:
	dorm = d
	custom_minimum_size = Vector2(side, side * 1.14)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_dorm(d: int) -> void:
	dorm = d
	queue_redraw()


func _shield(w: float, h: float, inset: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var l := inset
	var r := w - inset
	var t := inset
	var mid := h * 0.56
	pts.append(Vector2(l, t))
	pts.append(Vector2(w * 0.5, t + (0.0 if inset > 0.0 else 0.0)))
	pts.append(Vector2(r, t))
	pts.append(Vector2(r, mid))
	# The rounded point at the foot.
	for i in 9:
		var k := float(i + 1) / 9.0
		var ang := k * PI * 0.5
		pts.append(Vector2(w * 0.5 + (r - w * 0.5) * cos(ang), mid + (h - inset - mid) * sin(ang)))
	for i in 9:
		var k := float(i + 1) / 9.0
		var ang := PI * 0.5 + k * PI * 0.5
		pts.append(Vector2(w * 0.5 + (r - w * 0.5) * cos(ang), mid + (h - inset - mid) * sin(ang)))
	return pts


func _draw() -> void:
	var w := size.x
	var h := size.y
	var base: Color = Color(0.45, 0.48, 0.56) if dorm < 0 else Campus.DORM_COLORS[clampi(dorm, 0, 2)]
	base = base.lerp(Color(0.2, 0.22, 0.28), 1.0 - lit)
	draw_colored_polygon(_shield(w, h, 0.0), Color(0.02, 0.03, 0.07, 0.9))
	draw_colored_polygon(_shield(w, h, w * 0.045), base.darkened(0.22))
	draw_colored_polygon(_shield(w, h, w * 0.1), base)
	# The band across, and the paler field over it.
	var band_y := h * 0.3
	draw_rect(Rect2(w * 0.1, band_y, w * 0.8, h * 0.085), base.lightened(0.55))
	draw_rect(Rect2(w * 0.1, band_y + h * 0.085, w * 0.8, h * 0.02), base.darkened(0.3))
	# A five-pointed star in the lower field.
	var c := Vector2(w * 0.5, h * 0.62)
	var ro := w * 0.2
	var ri := ro * 0.42
	var star := PackedVector2Array()
	for i in 10:
		var ang := -PI / 2.0 + i * PI / 5.0
		star.append(c + Vector2(cos(ang), sin(ang)) * (ro if i % 2 == 0 else ri))
	draw_colored_polygon(star, Color(1.0, 0.97, 0.88, 0.95 * lit + 0.25 * (1.0 - lit)))
	# Three small pips over the band: one per dorm, the one you are in lit.
	for i in 3:
		var pc: Color = Campus.DORM_COLORS[i]
		var on := i == dorm
		draw_circle(Vector2(w * (0.32 + i * 0.18), h * 0.19), w * 0.045, Color(0.02, 0.03, 0.07, 0.9))
		draw_circle(Vector2(w * (0.32 + i * 0.18), h * 0.19), w * 0.032, pc.lightened(0.25) if on else Color(pc.darkened(0.45), 0.9))
	draw_polyline(_shield(w, h, w * 0.045) + PackedVector2Array([_shield(w, h, w * 0.045)[0]]), Color(1, 1, 1, 0.18 * lit), 1.5, true)
