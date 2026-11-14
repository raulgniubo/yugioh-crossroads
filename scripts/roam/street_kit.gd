class_name StreetKit
extends RefCounted
## Our own small street buildings, in the same kit as the Game Center: real doors, glass with
## something going on behind it, signs, and the clutter a shop puts out on the pavement. Each is
## built in its own space (the front faces +Z) so it can be turned any way.
##   "mart"    a bright corner store, open all night
##   "cafe"    two floors of brick and plaster with a striped awning and tables outside
##   "shack"   Satellite's patched-up parts store, tin and tarps
##   "lounge"  Heartland's glass cafe with a drum tower and floating menu


static var _title := ""


static func shop(city: CityBuilder, kind: String, at: Vector3, yaw := 0.0, w := 9.0, d := 7.0, title := "") -> Node3D:
	_title = title
	var h := Node3D.new()
	h.position = at
	h.rotation.y = yaw
	city.add_child(h)
	var batch := CityBuilder.BoxBatch.new()
	var hgt := 4.2
	match kind:
		"cafe":
			hgt = _cafe(city, h, batch, w, d)
		"shack":
			hgt = _shack(city, h, batch, w, d)
		"lounge":
			hgt = _lounge(city, h, batch, w, d)
		_:
			hgt = _mart(city, h, batch, w, d)
	batch.commit(h)
	city._dorm_solid(h, city.make_solid, Vector3(w, hgt, d), Vector3(0, hgt / 2.0, 0))
	var r := maxf(w, d) + 3.0
	city.no_grass.append(Rect2(at.x - r / 2.0, at.z - r / 2.0, r, r))
	return h


static var _cache := {}
static var _cache_owner := 0


## One material per color for the whole kit: every box of the same color lands in one surface.
static func _m(city: CityBuilder, c: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
	if _cache_owner != city.get_instance_id():
		_cache.clear()
		_cache_owner = city.get_instance_id()
	var key := "%s/%.2f/%.2f" % [c.to_html(), rough, metal]
	if not _cache.has(key):
		_cache[key] = city.mat(c, rough, metal)
	return _cache[key]


static func _g(city: CityBuilder, c: Color, energy := 2.0) -> StandardMaterial3D:
	if _cache_owner != city.get_instance_id():
		_cache.clear()
		_cache_owner = city.get_instance_id()
	var key := "g%s/%.2f" % [c.to_html(), energy]
	if not _cache.has(key):
		_cache[key] = city.glow_mat(c, energy)
	return _cache[key]


static func _lamp(city: CityBuilder, h: Node3D, lpos: Vector3, col: Color, energy := 2.0, reach := 8.0) -> void:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = reach
	l.position = lpos
	h.add_child(l)
	city._lamp_lights.append(l)


static func _ball(city: CityBuilder, h: Node3D, lpos: Vector3, r: float, m: Material, squash := 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0 * squash
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = m
	mi.position = lpos
	h.add_child(mi)
	return mi


## Painted lettering (not neon: it keeps its color at every hour), in the holder's space.
static func _label(h: Node3D, text: String, lpos: Vector3, color: Color, size := 64, lrot := 0.0, pixel := 0.0085) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.outline_size = 0
	l.modulate = color
	l.pixel_size = pixel
	l.position = lpos
	l.rotation.y = lrot
	l.shaded = false
	l.double_sided = false
	l.font = load("res://assets/fonts/Rajdhani-SemiBold.ttf")
	h.add_child(l)
	return l


## Something to bump into, in the holder's space.
static func _solid(city: CityBuilder, h: Node3D, size: Vector3, lpos: Vector3) -> void:
	city._dorm_solid(h, city.make_solid, size, lpos)


## Parapet round a flat roof.
static func _parapet(batch: CityBuilder.BoxBatch, w: float, d: float, y: float, m: Material, tall := 0.4) -> void:
	batch.add(Vector3(w + 0.2, tall, 0.2), Vector3(0, y + tall / 2.0, d / 2.0), m)
	batch.add(Vector3(w + 0.2, tall, 0.2), Vector3(0, y + tall / 2.0, -d / 2.0), m)
	batch.add(Vector3(0.2, tall, d), Vector3(w / 2.0, y + tall / 2.0, 0), m)
	batch.add(Vector3(0.2, tall, d), Vector3(-w / 2.0, y + tall / 2.0, 0), m)


# ------------------------------------------------------------------ the corner store

static func _mart(city: CityBuilder, h: Node3D, batch: CityBuilder.BoxBatch, w: float, d: float) -> float:
	var hgt := 4.3
	var zf := d / 2.0
	var white := city.surf("plaster", Color(0.95, 0.95, 0.93))
	var base := _m(city, Color(0.3, 0.31, 0.34), 0.8)
	var frame := _m(city, Color(0.82, 0.84, 0.86), 0.35, 0.6)
	var teal := _m(city, Color("1fa184"), 0.6)
	var orange := _m(city, Color("ff8a3a"), 0.6)
	var lit := _g(city, Color(1.0, 0.98, 0.9), 0.85)
	var shelf := _m(city, Color(0.55, 0.57, 0.6), 0.6)
	city.box(Vector3(w, hgt, d), Vector3(0, hgt / 2.0, 0), white, false, h)
	batch.add(Vector3(w + 0.08, 0.35, d + 0.08), Vector3(0, 0.175, 0), base)
	# The fascia: three bands of color right round, and a lit name board over the door.
	for band in [[3.18, 0.22, teal], [3.4, 0.22, _m(city, Color(0.97, 0.97, 0.95), 0.6)], [3.62, 0.22, orange]]:
		batch.add(Vector3(w + 0.12, band[1], d + 0.12), Vector3(0, band[0], 0), band[2])
	batch.add(Vector3(w * 0.5, 0.86, 0.14), Vector3(0, 3.42, zf + 0.1), _g(city, Color(0.98, 1.0, 0.97), 0.75))
	_label(h, _title if _title != "" else "MART 24", Vector3(0, 3.42, zf + 0.19), Color(0.02, 0.26, 0.2), 64)
	# The front is glass from knee to lintel: a bright shop with its shelves showing.
	var gw := w - 1.0
	batch.add(Vector3(gw, 2.55, 0.06), Vector3(0, 1.72, zf + 0.02), lit)
	var goods := [Color("e9523d"), Color("f2c230"), Color("3aa0e0"), Color("3fbf8a"), Color("b46be0"), Color("ff8a3a"), Color("f4f1e6")]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(w * 31.0 + d * 7.0)
	for row in 4:
		var y := 0.72 + row * 0.56
		batch.add(Vector3(gw - 0.2, 0.045, 0.06), Vector3(0, y, zf + 0.045), shelf)
		var x := -gw / 2.0 + 0.25
		while x < gw / 2.0 - 0.3:
			var bw := rng.randf_range(0.16, 0.34)
			var bh := rng.randf_range(0.2, 0.42)
			if absf(x + bw / 2.0) > 1.15:
				batch.add(Vector3(bw, bh, 0.03), Vector3(x + bw / 2.0, y + 0.025 + bh / 2.0, zf + 0.06), _m(city, goods[rng.randi() % goods.size()], 0.7))
			x += bw + rng.randf_range(0.03, 0.12)
	# Mullions, sill and lintel in brushed metal.
	batch.add(Vector3(gw + 0.16, 0.1, 0.16), Vector3(0, 0.42, zf + 0.07), frame)
	batch.add(Vector3(gw + 0.16, 0.12, 0.16), Vector3(0, 3.03, zf + 0.07), frame)
	var n := int(gw / 1.45)
	for i in n + 1:
		var mx := -gw / 2.0 + i * gw / n
		if absf(mx) > 1.05:
			batch.add(Vector3(0.07, 2.6, 0.14), Vector3(mx, 1.72, zf + 0.07), frame)
	# Posters in the bottom of two panes, the way these shops always have.
	for sx: float in [-1.0, 1.0]:
		batch.add(Vector3(0.9, 0.62, 0.02), Vector3(sx * (gw / 2.0 - 0.8), 0.86, zf + 0.085), _m(city, Color("f2c230") if sx < 0.0 else Color("e9523d"), 0.7))
		batch.add(Vector3(0.7, 0.14, 0.022), Vector3(sx * (gw / 2.0 - 0.8), 1.0, zf + 0.09), _m(city, Color(0.98, 0.98, 0.96), 0.7))
	# Sliding doors with a sensor box over them and a mat outside.
	batch.add(Vector3(2.1, 2.62, 0.07), Vector3(0, 1.71, zf + 0.05), _m(city, Color(0.2, 0.24, 0.27), 0.5))
	for sx: float in [-0.5, 0.5]:
		batch.add(Vector3(0.94, 2.4, 0.04), Vector3(sx, 1.62, zf + 0.09), _m(city, Color(0.72, 0.9, 0.9), 0.08, 0.4))
		batch.add(Vector3(0.94, 0.1, 0.05), Vector3(sx, 1.5, zf + 0.1), teal)
	batch.add(Vector3(0.05, 2.4, 0.06), Vector3(0, 1.62, zf + 0.1), frame)
	batch.add(Vector3(0.6, 0.14, 0.2), Vector3(0, 2.96, zf + 0.14), base)
	batch.add(Vector3(2.0, 0.03, 1.1), Vector3(0, 0.02, zf + 0.7), _m(city, Color(0.2, 0.3, 0.28), 0.95))
	# A canopy the width of the shop with a light strip under its lip.
	batch.add(Vector3(w + 0.2, 0.12, 1.3), Vector3(0, 3.02, zf + 0.75), _m(city, Color(0.9, 0.9, 0.9), 0.5))
	batch.add(Vector3(w - 0.4, 0.04, 0.12), Vector3(0, 2.95, zf + 1.2), _g(city, Color(1.0, 0.98, 0.92), 2.2))
	# Out front: an ice chest, two capsule machines, a paper rack, a pair of bins and a banner.
	var chest := Vector3(-w / 2.0 + 1.3, 0, zf + 0.62)
	batch.add(Vector3(1.5, 0.82, 0.74), chest + Vector3(0, 0.41, 0), _m(city, Color(0.94, 0.95, 0.97), 0.4))
	batch.add(Vector3(1.52, 0.07, 0.76), chest + Vector3(0, 0.86, 0), _m(city, Color("3aa0e0"), 0.3, 0.2))
	batch.add(Vector3(1.1, 0.34, 0.02), chest + Vector3(0, 0.45, 0.38), _m(city, Color("7cc4ff"), 0.6))
	_solid(city, h, Vector3(1.5, 0.9, 0.74), chest + Vector3(0, 0.45, 0))
	for k in 2:
		var cap := Vector3(w / 2.0 - 1.0 - k * 0.6, 0, zf + 0.5)
		batch.add(Vector3(0.5, 0.75, 0.46), cap + Vector3(0, 0.375, 0), _m(city, Color("e9523d") if k == 0 else Color("f2c230"), 0.5))
		batch.add(Vector3(0.44, 0.44, 0.4), cap + Vector3(0, 0.98, 0), _m(city, Color(0.8, 0.92, 0.96), 0.08, 0.3))
		batch.add(Vector3(0.5, 0.06, 0.46), cap + Vector3(0, 1.23, 0), _m(city, Color(0.94, 0.95, 0.97), 0.4))
		for j in 5:
			_ball(city, h, cap + Vector3(-0.12 + (j % 3) * 0.12, 0.86 + (j / 3) * 0.12, 0.08), 0.06, _m(city, goods[(j + k * 2) % goods.size()], 0.5)).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_solid(city, h, Vector3(1.2, 1.25, 0.5), Vector3(w / 2.0 - 1.3, 0.62, zf + 0.5))
	var rack := Vector3(1.9, 0, zf + 0.5)
	batch.add(Vector3(0.7, 1.1, 0.06), rack + Vector3(0, 0.6, -0.1), base, Basis(Vector3(1, 0, 0), -0.2))
	for j in 3:
		batch.add(Vector3(0.6, 0.26, 0.05), rack + Vector3(0, 0.3 + j * 0.34, 0.0 - j * 0.06), _m(city, Color(0.96, 0.95, 0.9), 0.9), Basis(Vector3(1, 0, 0), -0.2))
	for k in 2:
		var bin := Vector3(-1.9 - k * 0.55, 0, zf + 0.42)
		batch.add(Vector3(0.48, 0.9, 0.44), bin + Vector3(0, 0.45, 0), _m(city, Color(0.5, 0.52, 0.55), 0.5, 0.4))
		batch.add(Vector3(0.3, 0.1, 0.03), bin + Vector3(0, 0.7, 0.23), _m(city, Color(0.08, 0.08, 0.1), 0.6))
		batch.add(Vector3(0.36, 0.14, 0.02), bin + Vector3(0, 0.36, 0.23), teal if k == 0 else orange)
	var flag := Vector3(w / 2.0 + 0.1, 0, zf + 1.5)
	city.cyl(0.025, 0.03, 2.6, flag + Vector3(0, 1.3, 0), frame, h, 6)
	city.cyl(0.2, 0.24, 0.12, flag + Vector3(0, 0.06, 0), base, h, 10)
	batch.add(Vector3(0.03, 1.6, 0.56), flag + Vector3(0, 1.7, 0.3), teal)
	batch.add(Vector3(0.035, 0.3, 0.56), flag + Vector3(0, 1.9, 0.3), _m(city, Color(0.97, 0.97, 0.95), 0.6))
	# A pole sign on the corner: the shop's square lit from inside, readable down the street.
	var pole := Vector3(-w / 2.0 - 0.4, 0, zf + 1.3)
	city.cyl(0.07, 0.09, 5.6, pole + Vector3(0, 2.8, 0), frame, h, 8)
	city.box(Vector3(1.3, 1.3, 0.24), pole + Vector3(0, 5.5, 0), _g(city, Color(0.98, 1.0, 0.97), 0.75), false, h)
	city.box(Vector3(1.34, 0.32, 0.26), pole + Vector3(0, 5.02, 0), teal, false, h)
	city.box(Vector3(1.34, 0.2, 0.26), pole + Vector3(0, 5.98, 0), orange, false, h)
	for sz: float in [-1.0, 1.0]:
		_label(h, "24", pole + Vector3(0, 5.5, sz * 0.13), Color(0.02, 0.26, 0.2), 90, 0.0 if sz > 0.0 else PI, 0.01)
	_solid(city, h, Vector3(0.2, 3.0, 0.2), pole + Vector3(0, 1.5, 0))
	# Side wall: a window with a blind and a delivery door.
	for sx: float in [-1.0, 1.0]:
		var side := Basis(Vector3.UP, sx * PI / 2.0)
		batch.add(Vector3(1.6, 1.2, 0.08), Vector3(sx * (w / 2.0 + 0.02), 1.9, 0.6), _m(city, Color(0.75, 0.86, 0.88), 0.2, 0.3), side)
		batch.add(Vector3(1.6, 0.5, 0.1), Vector3(sx * (w / 2.0 + 0.03), 2.26, 0.6), _m(city, Color(0.9, 0.9, 0.86), 0.8), side)
		batch.add(Vector3(1.76, 0.08, 0.14), Vector3(sx * (w / 2.0 + 0.04), 1.27, 0.6), frame, side)
		batch.add(Vector3(1.0, 2.1, 0.07), Vector3(sx * (w / 2.0 + 0.02), 1.4, -d / 2.0 + 1.2), _m(city, Color(0.5, 0.53, 0.56), 0.5, 0.4), side)
	# Roof: parapet, two chillers, a vent stack.
	_parapet(batch, w, d, hgt, base)
	for k in 2:
		batch.add(Vector3(1.4, 0.8, 1.0), Vector3(-1.6 + k * 2.6, hgt + 0.4, -0.8), _m(city, Color(0.74, 0.76, 0.78), 0.45, 0.5))
		batch.add(Vector3(1.0, 0.05, 0.7), Vector3(-1.6 + k * 2.6, hgt + 0.83, -0.8), _m(city, Color(0.2, 0.21, 0.24), 0.5))
	_lamp(city, h, Vector3(0, 2.6, zf + 2.0), Color(1.0, 0.98, 0.92), 2.2, 9.0)
	if city.make_solid:
		city.light_pool(h.transform * Vector3(0, 0.04, zf + 1.6), w - 1.0, 3.2, Color(1.0, 0.98, 0.9), h.rotation.y)
	return hgt


# ------------------------------------------------------------------ the cafe

static func _cafe(city: CityBuilder, h: Node3D, batch: CityBuilder.BoxBatch, w: float, d: float) -> float:
	var hgt := 7.4
	var zf := d / 2.0
	var brick := city.surf("brick", Color(0.6, 0.34, 0.27))
	var cream := city.surf("plaster", Color(0.95, 0.9, 0.78))
	var green := _m(city, Color(0.12, 0.3, 0.22), 0.55)
	var wood := city.surf("wood", Color(0.42, 0.28, 0.18))
	var stone := _m(city, Color(0.74, 0.7, 0.62), 0.85)
	var warm := _g(city, Color(1.0, 0.8, 0.52), 0.8)
	var gilt := _m(city, Color(0.86, 0.7, 0.32), 0.3, 0.8)
	var canvas_a := _m(city, Color(0.14, 0.38, 0.28), 0.9)
	var canvas_b := _m(city, Color(0.96, 0.93, 0.84), 0.9)
	city.box(Vector3(w, 3.5, d), Vector3(0, 1.75, 0), brick, false, h)
	city.box(Vector3(w, hgt - 3.5, d), Vector3(0, 3.5 + (hgt - 3.5) / 2.0, 0), cream, false, h)
	batch.add(Vector3(w + 0.1, 0.3, d + 0.1), Vector3(0, 0.15, 0), stone)
	batch.add(Vector3(w + 0.3, 0.24, d + 0.3), Vector3(0, 3.5, 0), stone)
	batch.add(Vector3(w + 0.4, 0.3, d + 0.4), Vector3(0, hgt - 0.15, 0), stone)
	batch.add(Vector3(w + 0.2, 0.12, d + 0.2), Vector3(0, hgt - 0.42, 0), green)
	# Two big windows either side of the door: the room inside glowing, a counter, hanging lamps.
	for sx: float in [-1.0, 1.0]:
		var cx := sx * (w / 4.0 + 0.45)
		var ww := w / 2.0 - 1.9
		batch.add(Vector3(ww, 2.1, 0.05), Vector3(cx, 1.65, zf + 0.02), warm)
		batch.add(Vector3(ww - 0.3, 0.5, 0.03), Vector3(cx, 0.9, zf + 0.05), _m(city, Color(0.3, 0.18, 0.1), 0.7))
		batch.add(Vector3(ww - 0.2, 0.06, 0.035), Vector3(cx, 1.17, zf + 0.05), _m(city, Color(0.2, 0.12, 0.07), 0.6))
		for k in 3:
			var lx := cx - ww / 2.0 + ww * (k + 0.5) / 3.0
			batch.add(Vector3(0.02, 0.5, 0.02), Vector3(lx, 2.45, zf + 0.05), _m(city, Color(0.1, 0.08, 0.06), 0.6))
			batch.add(Vector3(0.2, 0.16, 0.03), Vector3(lx, 2.14, zf + 0.055), _g(city, Color(1.0, 0.9, 0.6), 2.6))
			# Someone's head and shoulders at the counter, as a shape against the light.
			if k != 1:
				batch.add(Vector3(0.34, 0.4, 0.02), Vector3(lx + 0.1, 1.4, zf + 0.056), _m(city, Color(0.16, 0.1, 0.07), 0.8))
				batch.add(Vector3(0.2, 0.22, 0.02), Vector3(lx + 0.1, 1.72, zf + 0.056), _m(city, Color(0.16, 0.1, 0.07), 0.8))
		# Frame, glazing bars, a deep sill, and the name in gold on the glass.
		for y: float in [0.56, 2.74]:
			batch.add(Vector3(ww + 0.24, 0.12, 0.16), Vector3(cx, y, zf + 0.07), green)
		for ex: float in [-1.0, 1.0]:
			batch.add(Vector3(0.12, 2.3, 0.16), Vector3(cx + ex * (ww / 2.0 + 0.06), 1.65, zf + 0.07), green)
		batch.add(Vector3(0.05, 2.1, 0.08), Vector3(cx, 1.65, zf + 0.08), green)
		batch.add(Vector3(ww, 0.05, 0.08), Vector3(cx, 2.3, zf + 0.08), green)
		batch.add(Vector3(ww + 0.4, 0.08, 0.3), Vector3(cx, 0.48, zf + 0.14), stone)
		batch.add(Vector3(ww * 0.5, 0.05, 0.02), Vector3(cx, 2.52, zf + 0.085), gilt)
		# A planter under each window.
		batch.add(Vector3(ww + 0.1, 0.34, 0.4), Vector3(cx, 0.17, zf + 0.34), wood)
		for k in 5:
			_ball(city, h, Vector3(cx - ww / 2.0 + ww * (k + 0.5) / 5.0, 0.46, zf + 0.34), 0.24, _m(city, Color(0.16, 0.42, 0.2) if k % 2 == 0 else Color(0.2, 0.48, 0.24), 0.95), 0.8)
		_solid(city, h, Vector3(ww + 0.1, 0.7, 0.4), Vector3(cx, 0.35, zf + 0.34))
	# The door: wood and glass, a brass handle, a lantern over it.
	batch.add(Vector3(1.5, 2.7, 0.1), Vector3(0, 1.35, zf + 0.04), green)
	batch.add(Vector3(1.16, 2.4, 0.06), Vector3(0, 1.26, zf + 0.09), wood)
	batch.add(Vector3(0.8, 1.2, 0.03), Vector3(0, 1.72, zf + 0.125), warm)
	batch.add(Vector3(0.05, 0.36, 0.06), Vector3(0.42, 1.2, zf + 0.15), gilt)
	batch.add(Vector3(0.3, 0.2, 0.03), Vector3(0, 1.72, zf + 0.145), _m(city, Color(0.14, 0.38, 0.28), 0.6))
	# The awning: green and cream stripes, sloping out over the pavement, a scalloped edge.
	var slope := Basis(Vector3(1, 0, 0), 0.32)
	var stripes := int(w / 0.6)
	for i in stripes:
		var sx2 := -w / 2.0 + (i + 0.5) * w / stripes
		var cm: Material = canvas_a if i % 2 == 0 else canvas_b
		batch.add(Vector3(w / stripes, 0.05, 1.75), Vector3(sx2, 3.0, zf + 0.82), cm, slope)
		batch.add(Vector3(w / stripes, 0.24, 0.04), Vector3(sx2, 2.63, zf + 1.66), cm)
	for sx: float in [-1.0, 1.0]:
		batch.add(Vector3(0.05, 0.05, 1.7), Vector3(sx * (w / 2.0 - 0.03), 2.92, zf + 0.82), _m(city, Color(0.12, 0.12, 0.14), 0.5, 0.5), slope)
	# Name board over the awning and a round hanging sign on the corner.
	batch.add(Vector3(w * 0.56, 0.7, 0.1), Vector3(0, 4.05, zf + 0.06), green)
	batch.add(Vector3(w * 0.56 + 0.12, 0.06, 0.12), Vector3(0, 4.42, zf + 0.06), gilt)
	batch.add(Vector3(w * 0.56 + 0.12, 0.06, 0.12), Vector3(0, 3.68, zf + 0.06), gilt)
	var name := city.sign_on(h, _title if _title != "" else "CROSSROADS CAFE", Vector3(0, 4.05, zf + 0.13), Color(1.0, 0.86, 0.5), 54, 0.0, false)
	name.pixel_size = 0.0075
	batch.add(Vector3(0.06, 0.06, 1.0), Vector3(-w / 2.0 + 0.3, 5.3, zf + 0.5), _m(city, Color(0.12, 0.12, 0.14), 0.5, 0.5))
	var disc := city.cyl(0.5, 0.5, 0.08, Vector3(-w / 2.0 + 0.3, 4.72, zf + 0.82), green, h, 20)
	disc.rotation.z = PI / 2.0
	for sx: float in [-1.0, 1.0]:
		var cup := city.cyl(0.36, 0.36, 0.02, Vector3(-w / 2.0 + 0.3 + sx * 0.05, 4.72, zf + 0.82), _g(city, Color(1.0, 0.88, 0.6), 1.0), h, 20)
		cup.rotation.z = PI / 2.0
		city.box(Vector3(0.02, 0.2, 0.24), Vector3(-w / 2.0 + 0.3 + sx * 0.065, 4.7, zf + 0.82), _m(city, Color(0.3, 0.18, 0.1), 0.7), false, h)
		city.box(Vector3(0.02, 0.04, 0.36), Vector3(-w / 2.0 + 0.3 + sx * 0.065, 4.56, zf + 0.82), _m(city, Color(0.3, 0.18, 0.1), 0.7), false, h)
	# Upstairs: three windows with shutters and flower boxes.
	for k in 3:
		var ux := -w / 2.0 + w * (k + 0.5) / 3.0
		batch.add(Vector3(1.1, 1.5, 0.05), Vector3(ux, 5.55, zf + 0.02), _g(city, Color(1.0, 0.86, 0.6), 0.45))
		batch.add(Vector3(1.26, 0.1, 0.12), Vector3(ux, 6.36, zf + 0.05), stone)
		batch.add(Vector3(0.05, 1.5, 0.07), Vector3(ux, 5.55, zf + 0.05), _m(city, Color(0.96, 0.94, 0.88), 0.6))
		batch.add(Vector3(1.1, 0.05, 0.07), Vector3(ux, 5.7, zf + 0.05), _m(city, Color(0.96, 0.94, 0.88), 0.6))
		for ex: float in [-1.0, 1.0]:
			batch.add(Vector3(0.5, 1.56, 0.06), Vector3(ux + ex * 0.82, 5.55, zf + 0.05), green)
			for sl in 5:
				batch.add(Vector3(0.4, 0.03, 0.03), Vector3(ux + ex * 0.82, 5.0 + sl * 0.27, zf + 0.085), _m(city, Color(0.08, 0.22, 0.16), 0.6))
		batch.add(Vector3(1.3, 0.24, 0.3), Vector3(ux, 4.7, zf + 0.18), wood)
		for b in 5:
			_ball(city, h, Vector3(ux - 0.5 + b * 0.25, 4.9, zf + 0.2), 0.13, _m(city, [Color("ff6b6b"), Color("ffd84a"), Color("ffffff")][(b + k) % 3], 0.8)).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# A string of bulbs under the eaves.
	for i in 14:
		batch.add(Vector3(0.1, 0.1, 0.1), Vector3(-w / 2.0 + 0.3 + i * (w - 0.6) / 13.0, hgt - 0.62 - 0.12 * sin(i * PI / 13.0 * 3.0) * 0.6, zf + 0.12), _g(city, Color(1.0, 0.84, 0.5), 2.4))
	# Side walls get a window on each floor so no face is blank.
	for sx: float in [-1.0, 1.0]:
		var side := Basis(Vector3.UP, sx * PI / 2.0)
		for fy: float in [1.9, 5.55]:
			batch.add(Vector3(1.4, 1.4, 0.06), Vector3(sx * (w / 2.0 + 0.02), fy, 0.3), _g(city, Color(1.0, 0.84, 0.56), 0.5), side)
			batch.add(Vector3(1.6, 0.1, 0.16), Vector3(sx * (w / 2.0 + 0.05), fy - 0.76, 0.3), stone, side)
			batch.add(Vector3(0.05, 1.4, 0.08), Vector3(sx * (w / 2.0 + 0.04), fy, 0.3), green, side)
	# Tables on the pavement under umbrellas, two chairs each, and a chalkboard by the door.
	for k in 2:
		var t := Vector3((-1.0 if k == 0 else 1.0) * (w / 4.0 + 0.5), 0, zf + 2.5)
		city.cyl(0.45, 0.45, 0.04, t + Vector3(0, 0.74, 0), _m(city, Color(0.93, 0.92, 0.9), 0.4), h, 16)
		city.cyl(0.035, 0.035, 0.72, t + Vector3(0, 0.37, 0), _m(city, Color(0.14, 0.14, 0.16), 0.5, 0.6), h, 6)
		city.cyl(0.22, 0.26, 0.04, t + Vector3(0, 0.02, 0), _m(city, Color(0.14, 0.14, 0.16), 0.5, 0.6), h, 10)
		city.cyl(0.025, 0.025, 2.4, t + Vector3(0, 1.2, 0), wood, h, 6)
		city.cyl(0.05, 1.25, 0.5, t + Vector3(0, 2.4, 0), canvas_a if k == 0 else canvas_b, h, 8)
		city.cyl(0.06, 0.05, 0.09, t + Vector3(0.14, 0.81, 0.1), _m(city, Color(0.97, 0.96, 0.93), 0.4), h, 8)
		for c in 2:
			var cp := t + Vector3((-0.78 if c == 0 else 0.78), 0, 0.05)
			batch.add(Vector3(0.4, 0.05, 0.4), cp + Vector3(0, 0.46, 0), wood)
			batch.add(Vector3(0.05, 0.5, 0.4), cp + Vector3((-0.19 if c == 0 else 0.19), 0.72, 0), wood)
			for lx: float in [-0.17, 0.17]:
				for lz: float in [-0.17, 0.17]:
					batch.add(Vector3(0.04, 0.46, 0.04), cp + Vector3(lx, 0.23, lz), _m(city, Color(0.14, 0.14, 0.16), 0.5, 0.6))
		_solid(city, h, Vector3(1.9, 0.9, 0.9), t + Vector3(0, 0.45, 0))
	var board := Vector3(1.4, 0, zf + 0.9)
	batch.add(Vector3(0.62, 0.95, 0.04), board + Vector3(0, 0.5, 0.1), _m(city, Color(0.1, 0.12, 0.11), 0.9), Basis(Vector3(1, 0, 0), -0.22))
	batch.add(Vector3(0.62, 0.95, 0.04), board + Vector3(0, 0.5, -0.1), wood, Basis(Vector3(1, 0, 0), 0.22))
	for j in 4:
		batch.add(Vector3(0.4 - j * 0.06, 0.035, 0.01), board + Vector3(0, 0.78 - j * 0.14, 0.15 - (0.78 - j * 0.14 - 0.5) * 0.22), _m(city, Color(0.95, 0.94, 0.86) if j != 1 else Color("ffd84a"), 0.9), Basis(Vector3(1, 0, 0), -0.22))
	_parapet(batch, w, d, hgt, stone, 0.3)
	batch.add(Vector3(0.8, 1.5, 0.8), Vector3(w / 2.0 - 1.2, hgt + 0.75, -d / 2.0 + 1.2), brick)
	batch.add(Vector3(0.95, 0.12, 0.95), Vector3(w / 2.0 - 1.2, hgt + 1.56, -d / 2.0 + 1.2), stone)
	_lamp(city, h, Vector3(0, 2.3, zf + 1.8), Color(1.0, 0.8, 0.52), 2.0, 9.0)
	if city.make_solid:
		city.light_pool(h.transform * Vector3(0, 0.04, zf + 1.6), w - 1.0, 3.4, Color(1.0, 0.82, 0.55), h.rotation.y)
	return hgt


# ------------------------------------------------------------------ Satellite's parts store

static func _shack(city: CityBuilder, h: Node3D, batch: CityBuilder.BoxBatch, w: float, d: float) -> float:
	var hgt := 4.0
	var zf := d / 2.0
	var tin := _m(city, Color(0.4, 0.4, 0.4), 0.6, 0.5)
	var rust := _m(city, Color(0.5, 0.27, 0.16), 0.9, 0.2)
	var rust2 := _m(city, Color(0.38, 0.2, 0.13), 0.9, 0.2)
	var teal := _m(city, Color(0.2, 0.42, 0.42), 0.85, 0.2)
	var navy := _m(city, Color(0.2, 0.26, 0.4), 0.85, 0.2)
	var dark := _m(city, Color(0.11, 0.11, 0.12), 0.6, 0.4)
	var wood := city.surf("wood", Color(0.4, 0.3, 0.2))
	var bulb := _g(city, Color(1.0, 0.76, 0.42), 2.6)
	city.box(Vector3(w, hgt, d), Vector3(0, hgt / 2.0, 0), city.surf("concrete", Color(0.36, 0.34, 0.32)), false, h)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(w * 13.0 + d * 5.0) + 7
	# Walls patched from whatever sheet could be found, each with its ribs.
	var sheets := [tin, rust, teal, rust2, navy, tin, rust]
	for face in 3:
		var basis := Basis.IDENTITY if face == 0 else Basis(Vector3.UP, PI / 2.0 if face == 1 else -PI / 2.0)
		var half := w / 2.0 if face == 0 else d / 2.0
		var out := zf if face == 0 else w / 2.0
		var x := -half
		while x < half - 0.1:
			var sw := minf(rng.randf_range(1.0, 1.9), half - x)
			var top := rng.randf_range(hgt - 0.5, hgt + 0.25)
			var bot := rng.randf_range(0.0, 0.2)
			var sm: Material = sheets[rng.randi() % sheets.size()]
			var skip := face == 0 and x + sw > -w / 2.0 + 0.6 and x < w / 2.0 - 2.9   # the shop front
			if not skip:
				batch.add(Vector3(sw - 0.04, top - bot, 0.05), basis * Vector3(x + sw / 2.0, (top + bot) / 2.0, out + 0.03), sm, basis)
				var rx := x + 0.15
				while rx < x + sw - 0.1:
					batch.add(Vector3(0.06, top - bot, 0.035), basis * Vector3(rx, (top + bot) / 2.0, out + 0.07), sm, basis)
					rx += 0.3
			x += sw
	# The front: a roll shutter half up over a counter, shelves of parts in the lamplight behind.
	var fx := -1.15                        # middle of the opening
	var fw := w - 3.5
	batch.add(Vector3(fw, 2.5, 0.05), Vector3(fx, 1.55, zf + 0.02), _g(city, Color(1.0, 0.72, 0.4), 0.42))
	var parts := [Color(0.62, 0.64, 0.66), Color(0.75, 0.42, 0.2), Color(0.2, 0.5, 0.56), Color(0.78, 0.66, 0.24), Color(0.3, 0.3, 0.34), Color(0.66, 0.2, 0.16)]
	for row in 3:
		var y := 1.3 + row * 0.5
		batch.add(Vector3(fw - 0.2, 0.05, 0.05), Vector3(fx, y, zf + 0.045), wood)
		var px := fx - fw / 2.0 + 0.2
		while px < fx + fw / 2.0 - 0.3:
			var bw := rng.randf_range(0.14, 0.4)
			var bh := rng.randf_range(0.14, 0.38)
			batch.add(Vector3(bw, bh, 0.03), Vector3(px + bw / 2.0, y + 0.025 + bh / 2.0, zf + 0.06), _m(city, parts[rng.randi() % parts.size()], 0.7, 0.3))
			px += bw + rng.randf_range(0.04, 0.16)
	batch.add(Vector3(fw + 0.3, 0.12, 0.7), Vector3(fx, 1.02, zf + 0.3), wood)
	batch.add(Vector3(fw + 0.1, 1.0, 0.1), Vector3(fx, 0.5, zf + 0.06), rust2)
	for sl in 5:
		batch.add(Vector3(fw + 0.1, 0.17, 0.07), Vector3(fx, 2.95 - sl * 0.18, zf + 0.09 + (sl % 2) * 0.015), tin)
	batch.add(Vector3(fw + 0.3, 0.2, 0.22), Vector3(fx, 3.14, zf + 0.12), dark)
	for ex: float in [-1.0, 1.0]:
		batch.add(Vector3(0.14, 3.1, 0.16), Vector3(fx + ex * (fw / 2.0 + 0.07), 1.55, zf + 0.08), dark)
	# Things on the counter: a toolbox, a jar of bolts, an engine part.
	batch.add(Vector3(0.6, 0.26, 0.3), Vector3(fx - fw / 2.0 + 0.6, 1.21, zf + 0.34), _m(city, Color(0.7, 0.16, 0.12), 0.5, 0.4))
	batch.add(Vector3(0.3, 0.04, 0.05), Vector3(fx - fw / 2.0 + 0.6, 1.37, zf + 0.34), dark)
	city.cyl(0.1, 0.1, 0.24, Vector3(fx + 0.3, 1.2, zf + 0.36), _m(city, Color(0.7, 0.8, 0.82), 0.1, 0.3), h, 8)
	city.cyl(0.16, 0.16, 0.2, Vector3(fx + fw / 2.0 - 0.5, 1.18, zf + 0.34), _m(city, Color(0.5, 0.52, 0.55), 0.35, 0.8), h, 10)
	_solid(city, h, Vector3(fw + 0.3, 1.1, 0.7), Vector3(fx, 0.55, zf + 0.3))
	# The door: a steel one with a porthole, a bare bulb over it.
	var dx := w / 2.0 - 1.5
	batch.add(Vector3(1.2, 2.4, 0.08), Vector3(dx, 1.2, zf + 0.05), navy)
	batch.add(Vector3(1.34, 0.12, 0.12), Vector3(dx, 2.46, zf + 0.06), dark)
	var port := city.cyl(0.22, 0.22, 0.05, Vector3(dx, 1.7, zf + 0.1), _g(city, Color(1.0, 0.76, 0.42), 0.8), h, 12)
	port.rotation.x = PI / 2.0
	batch.add(Vector3(0.06, 0.3, 0.07), Vector3(dx - 0.42, 1.15, zf + 0.11), tin)
	batch.add(Vector3(0.1, 0.1, 0.1), Vector3(dx, 2.74, zf + 0.2), bulb)
	# A tin roof tipped toward the back, hanging over the front, with what ends up on roofs.
	var tip := Basis(Vector3(1, 0, 0), -0.1)
	batch.add(Vector3(w + 0.9, 0.08, d + 1.9), Vector3(0, hgt + 0.3, 0.45), rust, tip)
	var rr := -w / 2.0 - 0.3
	while rr < w / 2.0 + 0.4:
		batch.add(Vector3(0.07, 0.05, d + 1.9), Vector3(rr, hgt + 0.36, 0.45), rust2, tip)
		rr += 0.42
	for k in 3:
		var tyre := city.cyl(0.42, 0.42, 0.22, Vector3(-w / 2.0 + 1.4 + k * 1.3, hgt + 0.48 + k * 0.01, -0.6 - (k % 2) * 0.9), dark, h, 12)
		tyre.rotation.x = -0.1
	batch.add(Vector3(2.2, 0.06, 1.7), Vector3(w / 2.0 - 1.7, hgt + 0.42, 0.3), _m(city, Color(0.2, 0.36, 0.6), 0.9), tip)
	# A dish and a mast on the roof, a cable run to it.
	city.cyl(0.04, 0.05, 2.6, Vector3(w / 2.0 - 0.7, hgt + 1.5, -d / 2.0 + 0.8), tin, h, 6)
	var dish := city.cyl(0.7, 0.1, 0.24, Vector3(w / 2.0 - 0.7, hgt + 2.3, -d / 2.0 + 1.0), _m(city, Color(0.7, 0.7, 0.68), 0.5, 0.3), h, 14)
	dish.rotation.x = 1.0
	# Tarp awning on two poles, sagging in the middle.
	for part in 2:
		batch.add(Vector3(fw + 0.8, 0.04, 1.05), Vector3(fx, 3.02 - part * 0.24, zf + 0.6 + part * 0.98), _m(city, Color(0.82, 0.42, 0.16) if part == 0 else Color(0.74, 0.36, 0.14), 0.95), Basis(Vector3(1, 0, 0), 0.16 + part * 0.14))
	for ex: float in [-1.0, 1.0]:
		city.cyl(0.035, 0.035, 2.75, Vector3(fx + ex * (fw / 2.0 + 0.3), 1.37, zf + 2.0), wood, h, 6)
	for i in 7:
		batch.add(Vector3(0.09, 0.09, 0.09), Vector3(fx - fw / 2.0 + 0.2 + i * (fw - 0.4) / 6.0, 2.62 - 0.1 * sin(i * PI / 6.0), zf + 1.95), bulb)
	# The name on planks, hand lettered, and an OPEN that still lights.
	batch.add(Vector3(w * 0.62, 0.3, 0.06), Vector3(-0.4, hgt + 1.02, zf + 0.5), wood, Basis(Vector3(0, 0, 1), 0.03))
	batch.add(Vector3(w * 0.6, 0.3, 0.06), Vector3(-0.3, hgt + 0.7, zf + 0.5), city.surf("wood", Color(0.48, 0.36, 0.24)), Basis(Vector3(0, 0, 1), -0.02))
	for ex: float in [-1.0, 1.0]:
		batch.add(Vector3(0.08, 0.9, 0.08), Vector3(-0.35 + ex * w * 0.26, hgt + 0.7, zf + 0.44), dark)
	_label(h, _title if _title != "" else "PARTS & REPAIRS", Vector3(-0.35, hgt + 0.86, zf + 0.54), Color(0.96, 0.9, 0.74), 58, 0.0, 0.0078)
	city.sign_on(h, "OPEN", Vector3(dx, 3.1, zf + 0.12), Color("ff6a3a"), 46, 0.0, false).pixel_size = 0.008
	# The yard: drums, crates, a stack of tyres, a bench with a vice, scrap leaning on the wall.
	var drum_cols := [Color(0.62, 0.2, 0.14), Color(0.2, 0.36, 0.52), Color(0.72, 0.6, 0.2)]
	for k in 3:
		var dp := Vector3(w / 2.0 + 0.7 + (k % 2) * 0.75, 0, zf - 0.4 - k * 0.6)
		city.cyl(0.33, 0.33, 0.95, dp + Vector3(0, 0.475, 0), _m(city, drum_cols[k], 0.7, 0.4), h, 12)
		city.cyl(0.345, 0.345, 0.05, dp + Vector3(0, 0.3, 0), dark, h, 12)
		city.cyl(0.345, 0.345, 0.05, dp + Vector3(0, 0.68, 0), dark, h, 12)
	_solid(city, h, Vector3(1.6, 1.0, 1.9), Vector3(w / 2.0 + 1.0, 0.5, zf - 1.0))
	for k in 4:
		city.cyl(0.4, 0.4, 0.22, Vector3(-w / 2.0 - 0.75, 0.11 + k * 0.22, zf + 0.3), dark, h, 12).rotation.y = k * 0.4
	_solid(city, h, Vector3(0.85, 0.9, 0.85), Vector3(-w / 2.0 - 0.75, 0.45, zf + 0.3))
	for k in 3:
		var cp := Vector3(w / 2.0 - 0.3 - (k % 2) * 0.85, 0.3 + (k / 2) * 0.6, zf + 1.1 - (k / 2) * 0.1)
		batch.add(Vector3(0.74, 0.6, 0.7), cp, wood, Basis(Vector3.UP, k * 0.3))
		batch.add(Vector3(0.78, 0.07, 0.07), cp + Vector3(0, 0.2, 0.36), city.surf("wood", Color(0.3, 0.22, 0.15)), Basis(Vector3.UP, k * 0.3))
	_solid(city, h, Vector3(1.7, 1.2, 0.9), Vector3(w / 2.0 - 0.7, 0.6, zf + 1.1))
	for k in 4:
		batch.add(Vector3(0.9 + k * 0.2, 1.7 + (k % 2) * 0.5, 0.05), Vector3(-w / 2.0 - 0.3, 0.9 + (k % 2) * 0.2, -d / 2.0 + 0.9 + k * 0.5), sheets[k], Basis(Vector3.UP, PI / 2.0) * Basis(Vector3(1, 0, 0), -0.26))
	_lamp(city, h, Vector3(fx, 2.4, zf + 1.4), Color(1.0, 0.72, 0.4), 2.4, 8.5)
	if city.make_solid:
		city.light_pool(h.transform * Vector3(fx, 0.04, zf + 1.5), fw + 1.0, 3.2, Color(1.0, 0.72, 0.4), h.rotation.y)
	return hgt


# ------------------------------------------------------------------ Heartland's glass cafe

static func _lounge(city: CityBuilder, h: Node3D, batch: CityBuilder.BoxBatch, w: float, d: float) -> float:
	var hgt := 5.6
	var zf := d / 2.0
	var shell := _m(city, Color(0.95, 0.96, 0.98), 0.22, 0.1)
	var rim := _m(city, Color(0.82, 0.86, 0.92), 0.25, 0.5)
	var glass := _m(city, Color(0.2, 0.62, 0.78), 0.06, 0.55)
	var cyan := _g(city, Color("5ae0ff"), 2.4)
	var pink := _g(city, Color("ff7ac8"), 2.2)
	var inside := _g(city, Color(0.75, 0.95, 1.0), 0.7)
	city.box(Vector3(w, hgt, d), Vector3(0, hgt / 2.0, 0), shell, false, h)
	# The front is one wall of tinted glass with a bright room behind and a bar of light at the foot.
	var gw := w - 2.8
	var gx := 0.9
	batch.add(Vector3(gw, 3.5, 0.05), Vector3(gx, 2.05, zf + 0.02), inside)
	for k in 4:
		# Pod lamps and a long bar inside, as shapes in the light.
		var lx := gx - gw / 2.0 + gw * (k + 0.5) / 4.0
		batch.add(Vector3(0.36, 0.2, 0.03), Vector3(lx, 3.2, zf + 0.05), _g(city, Color(1.0, 1.0, 1.0), 2.6))
		batch.add(Vector3(0.02, 0.5, 0.02), Vector3(lx, 3.55, zf + 0.05), rim)
	batch.add(Vector3(gw - 0.6, 0.6, 0.03), Vector3(gx, 0.9, zf + 0.05), _m(city, Color(0.5, 0.76, 0.86), 0.3, 0.2))
	batch.add(Vector3(gw - 0.5, 0.05, 0.035), Vector3(gx, 1.22, zf + 0.05), _m(city, Color(0.96, 0.98, 1.0), 0.3))
	for k in 5:
		batch.add(Vector3(0.24, 0.3, 0.03), Vector3(gx - gw / 2.0 + 0.6 + k * (gw - 1.2) / 4.0, 1.45, zf + 0.05), _m(city, [Color("ff7ac8"), Color("ffd84a"), Color("5ae0ff"), Color("9cf06a"), Color("ffffff")][k], 0.5))
	var panes := int(gw / 1.3)
	for i in panes + 1:
		batch.add(Vector3(0.045, 3.5, 0.1), Vector3(gx - gw / 2.0 + i * gw / panes, 2.05, zf + 0.06), shell)
	batch.add(Vector3(gw + 0.1, 0.1, 0.14), Vector3(gx, 3.84, zf + 0.06), shell)
	batch.add(Vector3(gw + 0.1, 0.05, 0.05), Vector3(gx, 0.28, zf + 0.1), cyan)
	# A sliding door in the glass, marked by a pink frame of light.
	var dxx := gx + gw / 2.0 - 1.1
	batch.add(Vector3(1.5, 2.6, 0.04), Vector3(dxx, 1.3, zf + 0.1), glass)
	batch.add(Vector3(1.6, 0.05, 0.06), Vector3(dxx, 2.63, zf + 0.12), pink)
	for ex: float in [-1.0, 1.0]:
		batch.add(Vector3(0.05, 2.6, 0.06), Vector3(dxx + ex * 0.78, 1.3, zf + 0.12), pink)
	# The drum tower on the corner: white, with three rings of light and a glass crown.
	var tx := -w / 2.0 + 0.6
	var tz := zf - 0.4
	city.cyl(1.7, 1.7, hgt + 1.6, Vector3(tx, (hgt + 1.6) / 2.0, tz), shell, h, 28)
	for ry: float in [1.2, 3.4, hgt + 1.0]:
		city.cyl(1.74, 1.74, 0.09, Vector3(tx, ry, tz), cyan if ry < hgt else pink, h, 28)
	city.cyl(1.72, 1.72, 0.9, Vector3(tx, 2.3, tz), glass, h, 28)
	city.cyl(1.2, 1.5, 0.7, Vector3(tx, hgt + 1.95, tz), glass, h, 28)
	city.cyl(0.0, 1.2, 0.5, Vector3(tx, hgt + 2.55, tz), shell, h, 28)
	_solid(city, h, Vector3(3.0, hgt, 3.0), Vector3(tx, hgt / 2.0, tz))
	# A thin roof that floats a hand above the walls, lit from underneath.
	batch.add(Vector3(w + 1.4, 0.14, d + 1.6), Vector3(0.4, hgt + 0.22, 0.3), shell)
	batch.add(Vector3(w + 1.0, 0.05, 0.08), Vector3(0.4, hgt + 0.12, zf + 1.0), cyan)
	batch.add(Vector3(w - 0.2, 0.2, d - 0.2), Vector3(0, hgt + 0.05, 0), rim)
	# The name stands on the roof edge; a menu hangs in the air by the door.
	var name := city.sign_on(h, _title if _title != "" else "SKY LOUNGE", Vector3(gx, hgt + 0.9, zf + 0.9), Color("5ae0ff"), 110, 0.0, false)
	name.pixel_size = 0.009
	batch.add(Vector3(gw * 0.7, 0.05, 0.05), Vector3(gx, hgt + 0.36, zf + 0.9), pink)
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(0.4, 0.9, 1.0, 0.3)
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.emission_enabled = true
	mm.emission = Color(0.3, 0.8, 1.0)
	mm.emission_energy_multiplier = 0.8
	mm.cull_mode = BaseMaterial3D.CULL_DISABLED
	var menu := city.box(Vector3(1.3, 1.8, 0.03), Vector3(dxx + 1.75, 1.75, zf + 1.3), mm, false, h)
	menu.rotation.y = -0.35
	menu.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for j in 5:
		var line := city.box(Vector3(0.9 - (j % 2) * 0.3, 0.07, 0.01), Vector3(dxx + 1.75, 2.35 - j * 0.3, zf + 1.32), _g(city, Color(1.0, 1.0, 1.0) if j > 0 else Color("ff7ac8"), 1.6), false, h)
		line.rotation.y = -0.35
		line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	city.cyl(0.3, 0.36, 0.08, Vector3(dxx + 1.75, 0.04, zf + 1.3), rim, h, 14)
	city.cyl(0.2, 0.2, 0.03, Vector3(dxx + 1.75, 0.09, zf + 1.3), cyan, h, 14)
	# Pod seats round glowing tables on the terrace.
	for k in 2:
		var t := Vector3(gx - 1.8 + k * 3.2, 0, zf + 2.6)
		city.cyl(0.5, 0.5, 0.05, t + Vector3(0, 0.72, 0), shell, h, 18)
		city.cyl(0.42, 0.42, 0.02, t + Vector3(0, 0.75, 0), _g(city, Color("5ae0ff") if k == 0 else Color("ff7ac8"), 0.9), h, 18)
		city.cyl(0.08, 0.2, 0.7, t + Vector3(0, 0.35, 0), rim, h, 10)
		for c in 3:
			var a := c * TAU / 3.0 + k * 0.5
			var sp := t + Vector3(cos(a) * 0.95, 0, sin(a) * 0.95)
			_ball(city, h, sp + Vector3(0, 0.3, 0), 0.3, shell, 0.8)
			city.cyl(0.14, 0.2, 0.12, sp + Vector3(0, 0.06, 0), rim, h, 10)
		_solid(city, h, Vector3(2.3, 0.9, 2.3), t + Vector3(0, 0.45, 0))
	# A planter with a clipped tree at the far end.
	var pl := Vector3(w / 2.0 + 0.2, 0, zf + 1.6)
	city.cyl(0.55, 0.42, 0.6, pl + Vector3(0, 0.3, 0), shell, h, 16)
	city.cyl(0.57, 0.57, 0.05, pl + Vector3(0, 0.56, 0), cyan, h, 16)
	city.cyl(0.06, 0.08, 1.3, pl + Vector3(0, 1.2, 0), _m(city, Color(0.4, 0.3, 0.24), 0.9), h, 6)
	_ball(city, h, pl + Vector3(0, 2.2, 0), 0.75, _m(city, Color(0.2, 0.62, 0.42), 0.9))
	_solid(city, h, Vector3(1.0, 1.6, 1.0), pl + Vector3(0, 0.8, 0))
	# Side walls: a long slot window each.
	for sx: float in [-1.0, 1.0]:
		var side := Basis(Vector3.UP, sx * PI / 2.0)
		batch.add(Vector3(d - 2.4, 0.9, 0.05), Vector3(sx * (w / 2.0 + 0.02), 3.0, -0.3), glass, side)
		batch.add(Vector3(d - 2.2, 0.05, 0.07), Vector3(sx * (w / 2.0 + 0.03), 2.5, -0.3), cyan, side)
	_lamp(city, h, Vector3(gx, 2.6, zf + 2.0), Color(0.6, 0.92, 1.0), 2.0, 9.0)
	if city.make_solid:
		city.light_pool(h.transform * Vector3(gx, 0.04, zf + 1.6), gw, 3.4, Color(0.6, 0.92, 1.0), h.rotation.y)
	return hgt
