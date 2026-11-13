class_name NewDominoBuilder
extends CityBuilder
## New Domino City, the clean upper city of the 5D's world: a boulevard from the highway gate
## up to the stadium, Security headquarters on the west side, the Tops towers and their
## garden on the east, and the highway ring hanging over all of it.

const GATE := Vector3(0, 0, 47)
const PLAZA := Vector3(0, 0, 4)
const STADIUM := Vector3(0, 0, -36)
const SECURITY := Vector3(-38, 0, 2)
const TOPS := Vector3(38, 0, -6)
const SHOP := Vector3(30, 0, 28)


func build(t: Dictionary, time_of_day: String) -> void:
	theme = t
	_build_env()
	_ground()
	_boulevard()
	_plaza()
	_stadium()
	_security()
	_tops()
	_gate()
	_ring()
	_showcase()
	_terrace()
	_market()
	_green()
	_billboards()
	_backdrop()
	_edges()
	apply_tod(time_of_day)


func _lamp(at: Vector3, color := Color(0.85, 0.93, 1.0)) -> void:
	cyl(0.06, 0.09, 5.2, at + Vector3(0, 2.6, 0), mat(Color(0.9, 0.92, 0.95), 0.3, 0.6))
	box(Vector3(1.3, 0.08, 0.3), at + Vector3(0, 5.2, 0), glow_mat(color, 3.0), false)
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = 2.2
	l.omni_range = 11.0
	l.shadow_enabled = false
	l.position = at + Vector3(0, 4.8, 0)
	add_child(l)
	_lamp_lights.append(l)


func _ground() -> void:
	box(Vector3(260, 0.2, 260), Vector3(0, -0.1, 0), mat(Color(0.13, 0.15, 0.19), 0.85))
	var white := _tile_material(Color(0.6, 0.64, 0.71), 2.0)
	box(Vector3(104, 0.06, 104), Vector3(0, 0.03, 0), white, false)
	# The boulevard: a dark lane with light strips, running from the gate to the stadium.
	var lane := mat(Color(0.1, 0.11, 0.15), 0.6)
	box(Vector3(11, 0.02, 100), Vector3(0, 0.07, 0), lane, false)
	box(Vector3(100, 0.02, 9), Vector3(0, 0.07, 4), lane, false)
	for s: float in [-1.0, 1.0]:
		box(Vector3(0.14, 0.03, 100), Vector3(s * 5.5, 0.08, 0), glow_mat(Color("7cc4ff"), 2.2), false)
		box(Vector3(100, 0.03, 0.14), Vector3(0, 0.08, 4 + s * 4.5), glow_mat(Color("7cc4ff"), 2.2), false)
	for k in range(-9, 10):
		box(Vector3(0.2, 0.025, 2.4), Vector3(0, 0.085, k * 5.0), glow_mat(Color(0.9, 0.95, 1.0), 0.9), false)


func _boulevard() -> void:
	for k in 5:
		var z := 40.0 - k * 7.0
		for s: float in [-1.0, 1.0]:
			_lamp(Vector3(s * 7.2, 0, z))
			if k % 2 == 0:
				if has_model("sakura"):
					prop("sakura", Vector3(s * 10.5, 0, z - 3.0), 0.0, 5.5, true)
				else:
					tree(Vector3(s * 10.5, 0, z - 3.0), 1.1)
			else:
				var py := prop("holo_pylon", Vector3(s * 10.5, 0, z - 3.0), 0.0, 4.0, true)
				if py:
					collide(py, 0.5)
	for k in 4:
		var z2 := -8.0 - k * 6.5
		for s: float in [-1.0, 1.0]:
			_lamp(Vector3(s * 7.2, 0, z2))
	neon_sign("NEW DOMINO CITY", Vector3(0, 9.5, 30), Color("7cc4ff"), 190, PI)
	neon_sign("WELCOME, DUELISTS", Vector3(0, 7.6, 30), Color("ffd166"), 80, PI, false)
	for s: float in [-1.0, 1.0]:
		cyl(0.3, 0.4, 11.0, Vector3(s * 8.5, 5.5, 30), mat(Color(0.88, 0.9, 0.94), 0.3, 0.5))
	box(Vector3(17.5, 0.5, 0.6), Vector3(0, 10.8, 30), mat(Color(0.88, 0.9, 0.94), 0.3, 0.5), false)


func _plaza() -> void:
	# A round plaza with a duel ring, a fountain of light and benches all around.
	var ring_m := glow_mat(Color("2de2e6"), 2.0)
	for r in [7.5, 8.2]:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = r - 0.08
		tm.outer_radius = r
		tm.rings = 64
		ring.mesh = tm
		ring.material_override = ring_m
		ring.scale = Vector3(1, 0.05, 1)
		ring.position = PLAZA + Vector3(0, 0.1, 0)
		add_child(ring)
	var stage := prop("duel_stage", PLAZA + Vector3(0, 0, 0), 0.0, 9.0)
	if stage == null:
		box(Vector3(8, 0.2, 5), PLAZA + Vector3(0, 0.1, 0), mat(Color(0.2, 0.24, 0.32), 0.5), false)
	for i in 8:
		var a := TAU * i / 8.0 + 0.39
		var p := PLAZA + Vector3(cos(a) * 11.0, 0, sin(a) * 11.0)
		if absf(p.x) < 6.5 or absf(p.z - 4.0) < 5.0:
			continue
		var bench := prop("bench", p, -a + PI / 2, 2.0)
		if bench:
			collide(bench, 0.8)
			places.append(["bench", p, -a + PI / 2])
	var f1 := prop("fountain", Vector3(-16, 0, 16), 0.0, 5.5)
	if f1:
		collide(f1, 0.85)
		places.append(["fountain", Vector3(-16, 0, 16), 0.0])
	var f2 := prop("fountain", Vector3(16, 0, -10), 0.0, 5.5)
	if f2:
		collide(f2, 0.85)
		places.append(["fountain", Vector3(16, 0, -10), 0.0])


func _stadium() -> void:
	var dome := prop("duel_dome", STADIUM + Vector3(0, 0, -14), 0.0, 46.0)
	if dome:
		collide(dome, 0.9)
	else:
		box(Vector3(40, 16, 24), STADIUM + Vector3(0, 8, -14), window_material(Color(0.5, 0.56, 0.66), 3.0, Color("7cc4ff")))
	neon_sign("NEW DOMINO STADIUM", STADIUM + Vector3(0, 12.5, 2.2), Color("ffd166"), 180)
	neon_sign("FORTUNE CUP  ·  QUALIFIERS OPEN", STADIUM + Vector3(0, 10.6, 2.2), Color("ff5a7a"), 80, 0.0, false)
	for s: float in [-1.0, 1.0]:
		var gs := prop("grandstand", STADIUM + Vector3(s * 19.0, 0, 5.0), -s * PI / 2, 12.0)
		if gs:
			collide(gs, 0.9)
		for k in 3:
			cyl(0.06, 0.06, 8.0, STADIUM + Vector3(s * (6.5 + k * 3.0), 4.0, 6.0), mat(Color(0.86, 0.88, 0.92), 0.3, 0.7))
			box(Vector3(1.6, 1.0, 0.04), STADIUM + Vector3(s * (6.5 + k * 3.0) + 0.85, 7.3, 6.0), glow_mat([Color("ffd166"), Color("ff5a7a"), Color("7cc4ff")][k], 0.8), false)
		var st := prop("dragon_statue", STADIUM + Vector3(s * 9.0, 0, 9.5), -s * 0.4, 4.6, true)
		if st:
			collide(st, 0.6)


func _security() -> void:
	# Sector Security: a dark tower with a searchlight, patrol runners parked outside.
	var glass := window_material(Color(0.1, 0.13, 0.2), 11.0, Color("3a86ff"))
	glass.set_shader_parameter("style", 1.0)
	box(Vector3(18, 44, 18), SECURITY + Vector3(-14, 22, 0), glass)
	box(Vector3(20, 3.2, 20), SECURITY + Vector3(-14, 1.6, 0), mat(Color(0.14, 0.16, 0.22), 0.5, 0.4))
	box(Vector3(6, 4.4, 0.4), SECURITY + Vector3(-4.2, 2.2, 0), glow_mat(Color("3a86ff"), 0.6), false)
	neon_sign("SECTOR SECURITY", SECURITY + Vector3(-3.6, 7.2, 0), Color("ff5a5a"), 120, PI / 2)
	neon_sign("HEADQUARTERS", SECURITY + Vector3(-3.6, 5.8, 0), Color("7cc4ff"), 70, PI / 2, false)
	for k in 3:
		var bike := prop("motorcycle", SECURITY + Vector3(2.0, 0, -6.0 + k * 3.0), PI / 2, 2.3)
		if bike:
			collide(bike, 0.7)
	for s: float in [-1.0, 1.0]:
		_lamp(SECURITY + Vector3(1.0, 0, s * 9.0), Color("9fc4ff"))
		box(Vector3(0.6, 1.1, 5.0), SECURITY + Vector3(4.5, 0.55, s * 12.5), mat(Color(0.9, 0.4, 0.1), 0.6))
	# Light bars up the tower, a roof mast and the Security shield over the door.
	for k in 4:
		box(Vector3(0.12, 40.0, 0.5), SECURITY + Vector3(-4.9, 22, -7.5 + k * 5.0), glow_mat(Color("3a86ff"), 1.6), false)
	cyl(0.25, 0.4, 12.0, SECURITY + Vector3(-14, 50, 0), mat(Color(0.2, 0.22, 0.28), 0.4, 0.6))
	box(Vector3(0.5, 0.5, 0.5), SECURITY + Vector3(-14, 56.2, 0), glow_mat(Color("ff3a3a"), 4.0), false)
	var shield := cyl(2.1, 2.1, 0.3, SECURITY + Vector3(-4.7, 11.5, 0), glow_mat(Color("3a86ff"), 1.2), null, 6)
	shield.rotation.z = PI / 2
	var core := cyl(1.2, 1.2, 0.34, SECURITY + Vector3(-4.6, 11.5, 0), glow_mat(Color("f2f6ff"), 1.4), null, 6)
	core.rotation.z = PI / 2
	# Barricades and a checkpoint booth on the forecourt.
	box(Vector3(2.4, 2.6, 2.4), SECURITY + Vector3(3.2, 1.3, 9.0), mat(Color(0.16, 0.18, 0.24), 0.5, 0.3))
	box(Vector3(2.5, 0.5, 2.5), SECURITY + Vector3(3.2, 2.2, 9.0), glow_mat(Color("3a86ff"), 0.9), false)
	var spot := SpotLight3D.new()
	spot.light_color = Color("cfe0ff")
	spot.light_energy = 14.0
	spot.spot_range = 70.0
	spot.spot_angle = 14.0
	spot.position = SECURITY + Vector3(-14, 45, 0)
	add_child(spot)
	spot.look_at(Vector3(0, 0, 4), Vector3.UP)


func _tops() -> void:
	# White residential towers with gold trim, and a garden between them.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for k in 3:
		var tw := window_material(Color(0.82, 0.84, 0.88), 20.0 + k, Color("ffd166"))
		var hgt := 38.0 + k * 9.0
		var pos := TOPS + Vector3(14.0, 0, -14.0 + k * 13.0)
		box(Vector3(11, hgt, 10), pos + Vector3(0, hgt / 2.0, 0), tw)
		box(Vector3(11.6, 0.5, 10.6), pos + Vector3(0, hgt + 0.25, 0), glow_mat(Color("ffd166"), 1.4), false)
	var grass := mat(Color(0.3, 0.55, 0.32), 0.95)
	box(Vector3(14, 0.05, 26), TOPS + Vector3(-1.0, 0.09, 0), grass, false)
	for k in 4:
		var tz := -10.0 + k * 6.6
		if has_model("sakura"):
			prop("sakura", TOPS + Vector3(-5.0 + (k % 2) * 8.0, 0, tz), 0.0, 6.0, true)
		else:
			tree(TOPS + Vector3(-5.0 + (k % 2) * 8.0, 0, tz), 1.2)
	for k in 3:
		var bench := prop("bench", TOPS + Vector3(-8.6, 0, -8.0 + k * 8.0), PI / 2, 2.0)
		if bench:
			collide(bench, 0.8)
	neon_sign("THE TOPS", TOPS + Vector3(-8.2, 6.4, 0), Color("ffd166"), 130, -PI / 2, false)
	# Shops on the south-east corner: the card shop and a cafe.
	var shop := prop("card_shop", SHOP + Vector3(6, 0, 0), -PI / 2, 9.5)
	if shop:
		collide(shop, 0.9)
	else:
		box(Vector3(8, 5, 9), SHOP + Vector3(6, 2.5, 0), window_material(Color(0.4, 0.3, 0.26), 5.0, Color("ffd166")))
	neon_sign("CARD SHOP", SHOP + Vector3(1.4, 5.6, 0), Color("ffd166"), 110, -PI / 2)
	var cafe := prop("cafe", Vector3(-30, 0, 30), PI / 2, 9.0)
	if cafe:
		collide(cafe, 0.9)
	neon_sign("CAFE LA GEEN", Vector3(-25.2, 5.2, 30), Color("ff8ac0"), 90, PI / 2, false)
	var vend := prop("vending", Vector3(-24.5, 0, 22.5), PI / 2, 2.0, true)
	if vend:
		collide(vend, 0.9)


func _gate() -> void:
	# The highway gate: where runners come down off the ring.
	var steel := mat(Color(0.86, 0.88, 0.92), 0.3, 0.6)
	for s: float in [-1.0, 1.0]:
		box(Vector3(1.2, 7.0, 1.2), GATE + Vector3(s * 7.0, 3.5, 2.0), steel)
		box(Vector3(0.2, 6.0, 0.2), GATE + Vector3(s * 6.3, 3.0, 1.4), glow_mat(Color("ff8a3a"), 2.4), false)
	box(Vector3(15.2, 1.4, 1.2), GATE + Vector3(0, 7.4, 2.0), steel, false)
	neon_sign("HIGHWAY  ·  RUNNER GATE", GATE + Vector3(0, 7.4, 1.3), Color("ff8a3a"), 100, PI)
	for k in 2:
		var bike := prop("motorcycle", GATE + Vector3(-3.5 + k * 7.0, 0, -1.0), PI, 2.3)
		if bike:
			collide(bike, 0.7)
	box(Vector3(12, 0.03, 4.0), GATE + Vector3(0, 0.09, 0.5), glow_mat(Color("ff8a3a"), 0.5), false)


func _ring() -> void:
	# The highway ring overhead, on pillars, with light strips racing along it.
	var deck := mat(Color(0.2, 0.22, 0.28), 0.5, 0.3)
	for seg in [[Vector3(0, 15, 54), Vector3(130, 1.2, 10)], [Vector3(0, 15, -62), Vector3(130, 1.2, 10)],
			[Vector3(-60, 15, -4), Vector3(10, 1.2, 126)], [Vector3(60, 15, -4), Vector3(10, 1.2, 126)]]:
		box(seg[1], seg[0], deck, false)
		var sz: Vector3 = seg[1]
		var long_x := sz.x > sz.z
		for e: float in [-1.0, 1.0]:
			var off := Vector3(0, 0.75, e * 4.9) if long_x else Vector3(e * 4.9, 0.75, 0)
			var strip := Vector3(sz.x, 0.12, 0.12) if long_x else Vector3(0.12, 0.12, sz.z)
			box(strip, (seg[0] as Vector3) + off, glow_mat(Color("ff8a3a") if e > 0.0 else Color("2de2e6"), 2.6), false)
		for k in 5:
			var along := -52.0 + k * 26.0
			var pp := (seg[0] as Vector3) + (Vector3(along, 0, 0) if long_x else Vector3(0, 0, along))
			box(Vector3(1.6, 15.0, 1.6), Vector3(pp.x, 7.5, pp.z), deck, false)


## A vehicle model from assets/models/vehicles, sized by its length.
func _vehicle(file: String, pos: Vector3, rot: float, length: float, parent: Node3D = null) -> Node3D:
	var path := "res://assets/models/vehicles/%s.glb" % file
	if not ResourceLoader.exists(path):
		return null
	var inst: Node3D = (load(path) as PackedScene).instantiate()
	var holder := Node3D.new()
	holder.add_child(inst)
	var bb := _aabb(inst, Transform3D.IDENTITY)
	var k := length / maxf(maxf(bb.size.x, bb.size.z), 0.001)
	inst.scale = Vector3.ONE * k
	inst.position = Vector3(-bb.get_center().x * k, -bb.position.y * k, -bb.get_center().z * k)
	holder.position = pos
	holder.rotation.y = rot
	(parent if parent else self).add_child(holder)
	return holder


## North-west: the Duel Runner showcase. Three machines turning slowly on lit podiums under
## a glass canopy.
func _showcase() -> void:
	var c := Vector3(-29, 0, -18.5)
	var steel := mat(Color(0.88, 0.9, 0.94), 0.3, 0.6)
	var dark := mat(Color(0.1, 0.11, 0.15), 0.5, 0.3)
	box(Vector3(20, 0.14, 13), c + Vector3(0, 0.1, 0), dark, false)
	box(Vector3(20.4, 0.05, 13.4), c + Vector3(0, 0.05, 0), glow_mat(Color("ff8a3a"), 1.2), false)
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.6, 0.85, 1.0, 0.22)
	glass.roughness = 0.1
	glass.metallic = 0.4
	box(Vector3(21, 0.25, 14), c + Vector3(0, 6.2, 0), glass, false)
	box(Vector3(21.4, 0.3, 0.3), c + Vector3(0, 6.2, 7.0), steel, false)
	box(Vector3(21.4, 0.3, 0.3), c + Vector3(0, 6.2, -7.0), steel, false)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			cyl(0.22, 0.28, 6.2, c + Vector3(sx * 10.2, 3.1, sz * 6.7), steel)
			solid_cyl(0.35, 3.0, c + Vector3(sx * 10.2, 0, sz * 6.7))
	var files := ["runner_a", "runner_b", "runner_a"]
	var tints := [Color("ff5a3a"), Color("2de2e6"), Color("ffd166")]
	for k in 3:
		var pc := c + Vector3(-6.4 + k * 6.4, 0, 0)
		cyl(2.3, 2.5, 0.5, pc + Vector3(0, 0.35, 0), mat(Color(0.16, 0.18, 0.24), 0.4, 0.5))
		var rim := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 2.22
		tm.outer_radius = 2.36
		rim.mesh = tm
		rim.material_override = glow_mat(tints[k], 2.4)
		rim.scale = Vector3(1, 0.3, 1)
		rim.position = pc + Vector3(0, 0.62, 0)
		add_child(rim)
		solid_cyl(2.4, 2.0, pc)
		var turn := Node3D.new()
		turn.position = pc + Vector3(0, 0.6, 0)
		add_child(turn)
		var bike := _vehicle(files[k], Vector3.ZERO, 0.0, 3.3, turn)
		if bike == null:
			var alt := prop("motorcycle", Vector3.ZERO, 0.0, 2.6, false, turn)
			if alt == null:
				box(Vector3(2.6, 0.9, 0.7), Vector3(0, 0.5, 0), glow_mat(tints[k], 0.6), false, turn)
		var tw := turn.create_tween().set_loops()
		tw.tween_property(turn, "rotation:y", TAU, 14.0 + k * 2.0).from(0.0)
		var l := SpotLight3D.new()
		l.light_color = tints[k].lightened(0.5)
		l.light_energy = 9.0
		l.spot_range = 8.0
		l.spot_angle = 34.0
		l.position = pc + Vector3(0, 6.0, 0)
		l.rotation.x = -PI / 2
		add_child(l)
	neon_sign("DUEL RUNNER SHOWCASE", c + Vector3(0, 7.3, 7.1), Color("ff8a3a"), 120, 0.0)
	neon_sign("ACCELERATION  ·  NEW MODELS THIS SEASON", c + Vector3(0, 5.5, 7.1), Color("f2f6ff"), 56, 0.0, false)
	for sx: float in [-1.0, 1.0]:
		var bench := prop("bench", c + Vector3(sx * 6.0, 0, 9.4), PI, 2.0)
		if bench:
			collide(bench, 0.8)


## South-west: the cafe terrace, with tables under parasols.
func _terrace() -> void:
	var c := Vector3(-18.5, 0, 31)
	var deck := mat(Color(0.5, 0.36, 0.26), 0.8)
	box(Vector3(12, 0.12, 14), c + Vector3(0, 0.09, 0), deck, false)
	var cols := [Color("ff8ac0"), Color("f2f6ff"), Color("ff8ac0"), Color("f2f6ff")]
	var i := 0
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var tp := c + Vector3(sx * 2.9, 0, sz * 3.6)
			cyl(0.05, 0.05, 2.5, tp + Vector3(0, 1.25, 0), mat(Color(0.9, 0.9, 0.92), 0.4, 0.6))
			cyl(0.7, 0.7, 0.06, tp + Vector3(0, 0.82, 0), mat(Color(0.95, 0.95, 0.96), 0.5))
			cyl(0.05, 1.5, 0.5, tp + Vector3(0, 2.55, 0), mat(cols[i], 0.8))
			solid_cyl(0.6, 1.2, tp)
			for a: float in [0.6, 3.7]:
				box(Vector3(0.45, 0.5, 0.45), tp + Vector3(cos(a) * 1.15, 0.32, sin(a) * 1.15), mat(Color(0.2, 0.22, 0.28), 0.6), false)
			i += 1
	for k in 4:
		box(Vector3(0.9, 0.7, 0.9), c + Vector3(-6.4, 0.35, -5.4 + k * 3.6), mat(Color(0.86, 0.88, 0.92), 0.6))
		box(Vector3(0.75, 0.5, 0.75), c + Vector3(-6.4, 0.9, -5.4 + k * 3.6), mat(Color(0.3, 0.6, 0.34), 0.95), false)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.8, 0.7)
	l.light_energy = 1.6
	l.omni_range = 10.0
	l.position = c + Vector3(0, 3.2, 0)
	add_child(l)
	_lamp_lights.append(l)


## South-east: the night market row beside the card shop.
func _market() -> void:
	var names := ["RAMEN", "TAKOYAKI", "CARD SLEEVES"]
	var cols := [Color("ff7a5a"), Color("ffd166"), Color("7cc4ff")]
	for k in 3:
		var sp := Vector3(11.5 + k * 6.0, 0, 41.5)
		var stall := prop("food_stall", sp, PI, 3.8)
		if stall:
			collide(stall, 0.85)
		else:
			box(Vector3(3.4, 2.6, 2.2), sp + Vector3(0, 1.3, 0), mat(Color(0.5, 0.3, 0.2), 0.8))
		neon_sign(names[k], sp + Vector3(0, 3.5, -1.3), cols[k], 60, PI, false)
		var lantern := OmniLight3D.new()
		lantern.light_color = cols[k]
		lantern.light_energy = 1.5
		lantern.omni_range = 6.0
		lantern.position = sp + Vector3(0, 2.6, -1.6)
		add_child(lantern)
		_lamp_lights.append(lantern)
	# A string of lanterns over the row.
	for k in 9:
		var lx := 9.0 + k * 2.4
		box(Vector3(0.32, 0.42, 0.32), Vector3(lx, 4.3 - absf(float(k) - 4.0) * 0.06, 39.2), glow_mat([Color("ff7a5a"), Color("ffd166")][k % 2], 2.2), false)
	box(Vector3(20.5, 0.03, 0.03), Vector3(18.6, 4.55, 39.2), mat(Color(0.1, 0.1, 0.12), 0.8), false)
	for sx in 2:
		cyl(0.06, 0.06, 4.6, Vector3(8.4 + sx * 20.4, 2.3, 39.2), mat(Color(0.2, 0.2, 0.24), 0.6))
	neon_sign("DAIMON MARKET", Vector3(18.6, 5.4, 39.2), Color("ff8a3a"), 90, PI, false)
	var vend := prop("vending", Vector3(27.5, 0, 36.0), -PI / 2, 2.0, true)
	if vend:
		collide(vend, 0.9)
		places.append(["vending", Vector3(27.5, 0, 36.0), -PI / 2])


## Planted strips along the boulevard and the cross street, so the white city has some green.
func _green() -> void:
	var soil := mat(Color(0.26, 0.5, 0.3), 0.95)
	var edge := mat(Color(0.9, 0.92, 0.95), 0.5)
	for sx: float in [-1.0, 1.0]:
		for seg in [[10.0, 21.0], [26.5, 33.0], [36.5, 41.0], [-27.0, -17.5], [-13.5, -3.0]]:
			var z0: float = seg[0]
			var z1: float = seg[1]
			var mid := Vector3(sx * 12.4, 0, (z0 + z1) / 2.0)
			box(Vector3(1.6, 0.3, z1 - z0), mid + Vector3(0, 0.15, 0), edge)
			box(Vector3(1.3, 0.12, z1 - z0 - 0.3), mid + Vector3(0, 0.34, 0), soil, false)
			var n := int((z1 - z0) / 3.0)
			for k in n:
				var bz := z0 + 1.5 + k * 3.0
				var bush := MeshInstance3D.new()
				var sm := SphereMesh.new()
				sm.radius = 0.62
				sm.height = 1.0
				bush.mesh = sm
				bush.material_override = mat(Color(0.2, 0.46, 0.26).lerp(Color(0.36, 0.62, 0.3), float(k % 3) / 2.0), 0.95)
				bush.position = Vector3(sx * 12.4, 0.75, bz)
				add_child(bush)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var mid2 := Vector3(sx * 23.5, 0, 4.0 + sz * 6.6)
			box(Vector3(15.0, 0.3, 1.4), mid2 + Vector3(0, 0.15, 0), edge)
			box(Vector3(14.7, 0.12, 1.1), mid2 + Vector3(0, 0.34, 0), soil, false)
			for k in 4:
				var tp := mid2 + Vector3(-5.4 + k * 3.6, 0.2, 0)
				if has_model("tree"):
					prop("tree", tp, float(k) * 1.3, 4.2, true)
				else:
					tree(tp, 0.8)


## Giant holo screens on masts, like the ones that broadcast the Fortune Cup.
func _billboards() -> void:
	for b in [[Vector3(19, 0, -22), -0.5, "FORTUNE CUP", "LIVE FROM THE STADIUM", Color("ff5a7a")],
			[Vector3(-22, 0, 14.5), 2.4, "RIDING DUEL", "ACCELERATION!", Color("ff8a3a")],
			[Vector3(24, 0, 17), -2.5, "KING JACK ATLAS", "UNDEFEATED  ·  42 WINS", Color("ffd166")]]:
		var at: Vector3 = b[0]
		var rot: float = b[1]
		var col: Color = b[4]
		var holder := Node3D.new()
		holder.position = at
		holder.rotation.y = rot
		add_child(holder)
		var steel := mat(Color(0.86, 0.88, 0.92), 0.3, 0.6)
		cyl(0.22, 0.32, 7.0, Vector3(0, 3.5, 0), steel, holder)
		box(Vector3(9.4, 4.6, 0.3), Vector3(0, 9.0, 0), mat(Color(0.06, 0.07, 0.1), 0.4, 0.4), false, holder)
		var screen := StandardMaterial3D.new()
		screen.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		screen.albedo_color = col.darkened(0.72)
		box(Vector3(9.0, 4.2, 0.06), Vector3(0, 9.0, 0.19), screen, false, holder)
		box(Vector3(9.0, 0.1, 0.08), Vector3(0, 11.15, 0.2), glow_mat(col, 2.6), false, holder)
		box(Vector3(9.0, 0.1, 0.08), Vector3(0, 6.85, 0.2), glow_mat(col, 2.6), false, holder)
		var t1 := neon_sign(str(b[2]), Vector3.ZERO, col, 270, 0.0, false)
		t1.get_parent().remove_child(t1)
		holder.add_child(t1)
		t1.position = Vector3(0, 9.6, 0.26)
		t1.rotation.y = 0.0
		var t2 := neon_sign(str(b[3]), Vector3.ZERO, Color("f2f6ff"), 100, 0.0, false)
		t2.get_parent().remove_child(t2)
		holder.add_child(t2)
		t2.position = Vector3(0, 8.0, 0.26)
		t2.rotation.y = 0.0
		solid_cyl(0.45, 3.0, at)


func _backdrop() -> void:
	# Runners on the ring: streaks of light doing laps overhead.
	var corners := [Vector3(-60, 16.1, 54), Vector3(60, 16.1, 54), Vector3(60, 16.1, -62), Vector3(-60, 16.1, -62)]
	for k in 5:
		var streak := Node3D.new()
		add_child(streak)
		var colr: Color = [Color("ff8a3a"), Color("2de2e6"), Color("ffd166"), Color("ff5a7a"), Color("7cc4ff")][k]
		box(Vector3(0.5, 0.5, 2.6), Vector3(0, 0, 0), glow_mat(colr, 4.0), false, streak)
		var start := k % 4
		streak.position = corners[start]
		var tw := streak.create_tween().set_loops()
		for j in 4:
			var to: Vector3 = corners[(start + j + 1) % 4]
			var from: Vector3 = corners[(start + j) % 4]
			tw.tween_callback(streak.look_at.bind(to + Vector3(0, 0.001, 0), Vector3.UP))
			tw.tween_property(streak, "position", to, from.distance_to(to) / (26.0 + k * 3.0))
	# Towers beyond the ring so the skyline goes on.
	var rng := RandomNumberGenerator.new()
	rng.seed = 808
	for i in 46:
		var a := TAU * i / 46.0 + rng.randf() * 0.1
		var d := rng.randf_range(84.0, 118.0)
		var hgt := rng.randf_range(24.0, 88.0)
		var w := rng.randf_range(9.0, 16.0)
		var tw := window_material(Color(0.6, 0.64, 0.72).lerp(Color(0.2, 0.24, 0.34), rng.randf()), rng.randf() * 90.0, Color("7cc4ff"))
		box(Vector3(w, hgt, w), Vector3(cos(a) * d, hgt / 2.0, sin(a) * d - 4.0), tw, false)


func _edges() -> void:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0, 0, 0, 0)
	for s: float in [-1.0, 1.0]:
		box(Vector3(104, 6, 1), Vector3(0, 3, s * 50.5), m).visible = false
		box(Vector3(1, 6, 104), Vector3(s * 50.5, 3, 0), m).visible = false
