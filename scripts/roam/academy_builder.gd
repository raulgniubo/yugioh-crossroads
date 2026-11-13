class_name AcademyBuilder
extends CityBuilder
## Duel Academy: a school on a volcanic island. Reuses CityBuilder's sky, lighting and prop helpers.

const SHORE := 72.0
const PIER := 12.0     # how much further out the pier sits than it used to


func _build_ground() -> void:
	# The sea
	var sea := StandardMaterial3D.new()
	sea.albedo_color = Color(0.07, 0.3, 0.46)
	sea.roughness = 0.08
	sea.metallic = 0.35
	box(Vector3(900, 0.2, 900), Vector3(0, -0.75, 0), sea, false)
	# Sand, then grass, then stone paths
	cyl(SHORE + 4.0, SHORE + 9.0, 1.0, Vector3(0, -0.5, 0), mat(Color(0.86, 0.78, 0.58), 0.95), null, 48)
	cyl(SHORE - 8.0, SHORE - 5.0, 0.3, Vector3(0, -0.06, 0), grass_material(1.5), null, 48)
	var floor_body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(200, 1, 200)
	cs.shape = sh
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.41, 0)
	add_child(floor_body)
	var path := _tile_material(Color(0.72, 0.68, 0.6), 1.4)
	box(Vector3(5.0, 0.12, 62.0 + PIER), Vector3(0, 0.1, 17.0 + PIER / 2.0), path, false)       # dock -> plaza -> academy
	box(Vector3(5.0, 0.12, 24.0), Vector3(0, 0.1, -20.0), path, false)
	box(Vector3(34.0, 0.12, 4.0), Vector3(-19.0, 0.1, 6.0), path, false)    # west to the red dorm
	box(Vector3(36.0, 0.12, 4.0), Vector3(20.0, 0.1, -4.0), path, false)    # east to the yellow dorm
	box(Vector3(4.0, 0.12, 22.0), Vector3(-30.0, 0.1, -6.0), path, false)   # up to the blue dorm
	box(Vector3(26.0, 0.12, 4.0), Vector3(30.0, 0.1, 30.0), path, false)    # to the lighthouse
	box(Vector3(4.0, 0.12, 30.0), Vector3(19.0, 0.1, 17.0), path, false)
	# Central plaza with the academy crest
	cyl(9.0, 9.0, 0.14, Vector3(0, 0.1, 0), _tile_material(Color(0.8, 0.76, 0.68), 1.0), null, 40)
	for rr in [[6.2, 6.5, 2.0], [3.0, 3.2, 1.4]]:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = rr[0]
		tm.outer_radius = rr[1]
		tm.rings = 64
		ring.mesh = tm
		ring.material_override = glow_mat(theme["accent"], rr[2])
		ring.scale = Vector3(1, 0.04, 1)
		ring.position.y = 0.19
		add_child(ring)
	# Wooden pier
	var wood := mat(Color(0.5, 0.36, 0.22), 0.85)
	box(Vector3(5.0, 0.3, 22.0), Vector3(0, 0.05, 59.0 + PIER), wood, false)
	for i in 6:
		for sx in [-1, 1]:
			cyl(0.18, 0.18, 2.4, Vector3(sx * 2.3, -0.5, 50.0 + PIER + i * 3.8), wood)
	_build_more_paths(path)


## Where each building's front door is: [floor point, outward direction]. The rooms behind them
## are in AcademyRooms; roam_scene reads this to put the doors in the right place.
var doors := {}


func _door(name: String, holder: Node3D, inset := 0.0) -> void:
	if holder == null:
		return
	var sz: Vector3 = holder.get_meta("size", Vector3.ONE)
	var out := Vector3(sin(holder.rotation.y), 0, cos(holder.rotation.y))
	var p := holder.position + out * (sz.z / 2.0 - inset)
	p.y = 0.0
	doors[name] = [p, out]
	set_meta("doors", doors)


func _build_buildings() -> void:
	var main := prop("academy_main", Vector3(0, 0.05, -46.0), 0.0, 52.0)
	collide(main, 0.82)
	_door("academy_main", main, 0.0)
	neon_sign("DUEL ACADEMY", Vector3(0, 9.5, -30.5), Color("ffe9a8"), 260, 0.0, false)
	var red := prop("dorm_red", Vector3(-42.0, 0.05, 8.0), PI / 2, 15.0)
	collide(red, 0.85)
	_door("dorm_red", red, 0.6)
	neon_sign("RED DORM", Vector3(-33.8, 4.6, 8.0), Color("ff6b6b"), 110, PI / 2, false)
	var yel := prop("dorm_yellow", Vector3(42.0, 0.05, -6.0), -PI / 2, 16.0)
	collide(yel, 0.85)
	_door("dorm_yellow", yel, 0.6)
	neon_sign("YELLOW DORM", Vector3(33.4, 5.4, -6.0), Color("ffd166"), 110, -PI / 2, false)
	var blu := prop("dorm_blue", Vector3(-30.0, 0.05, -26.0), 0.35, 22.0)
	collide(blu, 0.85)
	_door("dorm_blue", blu, 0.6)
	neon_sign("BLUE DORM", Vector3(-27.5, 7.0, -15.5), Color("7cc4ff"), 120, 0.35, false)


func _build_landmarks() -> void:
	collide(prop("lighthouse", Vector3(46.0, 0.0, 34.0), 0.0, 24.0, true), 0.6)
	var beam := SpotLight3D.new()
	beam.light_color = Color(1.0, 0.95, 0.8)
	beam.light_energy = 8.0
	beam.spot_range = 70.0
	beam.spot_angle = 14.0
	beam.position = Vector3(46.0, 21.5, 34.0)
	beam.rotation_degrees = Vector3(-8, 0, 0)
	beam.set_meta("spin", 0.5)
	add_child(beam)
	_spinners.append(beam)
	# The duel field where students settle things
	var stage := prop("duel_stage", Vector3(19.0, 0.1, 30.0), 0.0, 13.0)
	if stage == null:
		cyl(6.0, 6.0, 0.3, Vector3(19.0, 0.2, 30.0), mat(Color(0.5, 0.5, 0.56), 0.6), null, 32)
	# Ferry at the pier
	var boat := prop("ferry", Vector3(7.5, -0.7, 62.0 + PIER), 0.2, 15.0)
	if boat:
		_bobbers.append([boat, -0.7])
	# The volcano behind the school
	var rock := mat(Color(0.26, 0.2, 0.18), 0.95)
	cyl(16.0, 95.0, 70.0, Vector3(-30, 34, -175), rock, null, 14)
	cyl(13.0, 13.0, 1.0, Vector3(-30, 68.6, -175), glow_mat(Color(1.0, 0.36, 0.1), 3.0), null, 14)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.4, 0.15)
	glow.light_energy = 20.0
	glow.omni_range = 70.0
	glow.position = Vector3(-30, 76, -175)
	add_child(glow)
	# Cliffs along the north shore
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 14:
		var a := PI * 0.62 + i * (PI * 0.78 / 13.0) + PI * 0.5
		var r := SHORE + 6.0 + rng.randf_range(0, 6)
		var h := rng.randf_range(5.0, 12.0)
		var m := cyl(rng.randf_range(4, 7), rng.randf_range(7, 11), h, Vector3(cos(a) * r, h / 2.0 - 1.0, sin(a) * r - 4.0), rock, null, 7)
		m.rotation.y = rng.randf() * TAU


func _build_street_furniture() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	# Palms around the shore, leafy trees inland
	for i in 26:
		var a := i * TAU / 26.0 + rng.randf_range(-0.08, 0.08)
		var r := SHORE - rng.randf_range(1.5, 6.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if absf(p.x) < 5.0 and p.z > 50.0:
			continue
		if p.z < -40.0:
			continue
		var palm := prop("palm", p, rng.randf() * TAU, rng.randf_range(6.5, 9.0), true)
		if palm:
			solid_cyl(0.3, 3.0, p + Vector3(0, 1.5, 0))
		else:
			tree(p, 1.1)
	for p in [Vector3(-12, 0, 16), Vector3(-22, 0, 20), Vector3(10, 0, 14), Vector3(-10, 0, -10), Vector3(12, 0, -14), Vector3(28, 0, 8),
			Vector3(-16, 0, 34), Vector3(30, 0, 18), Vector3(-44, 0, -8), Vector3(10, 0, -24), Vector3(-12, 0, -24), Vector3(34, 0, -22)]:
		tree(p, rng.randf_range(0.9, 1.25))
	# Lamps and benches along the main path
	for z in [50.0, 38.0, 26.0, 13.0, -13.0, -24.0]:
		for sx in [-1, 1]:
			var lp := Vector3(sx * 3.4, 0.1, z)
			var lamp := prop("street_lamp", lp, PI / 2 if sx < 0 else -PI / 2, 5.0, true)
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.86, 0.62)
			l.light_energy = 2.4
			l.omni_range = 9.0
			l.position = lp + Vector3(-sx * 1.4, 4.4, 0)
			add_child(l)
			_lamp_lights.append(l)
			if lamp == null:
				cyl(0.07, 0.1, 4.4, lp + Vector3(0, 2.2, 0), mat(Color(0.15, 0.15, 0.18), 0.5, 0.6))
	for b in [[Vector3(-7.5, 0.1, 4.6), 0.0], [Vector3(7.5, 0.1, -5.4), PI], [Vector3(15.5, 0.1, 22.0), PI / 2], [Vector3(-3.6, 0.1, 32.0), PI / 2]]:
		collide(prop("bench", b[0], b[1], 1.9), 0.9)
	collide(prop("vending", Vector3(4.2, 0.1, 44.0 + PIER), -PI / 2, 1.95, true))
	collide(prop("fountain", Vector3(0, 0.12, -18.5), 0.0, 5.0), 0.8)
	# A statue by the school steps and banners at the dock
	collide(prop("dragon_statue", Vector3(-9.0, 0.1, -26.0), 0.5, 4.5, true), 0.6)
	collide(prop("dragon_statue", Vector3(9.0, 0.1, -26.0), -0.5, 4.5, true), 0.6)
	neon_sign("WELCOME TO DUEL ACADEMY", Vector3(0, 4.8, 47.0 + PIER), theme["accent2"], 120, PI, false)
	for sx in [-1, 1]:
		cyl(0.1, 0.1, 5.0, Vector3(sx * 6.0, 2.5, 47.0 + PIER), mat(Color(0.2, 0.2, 0.24), 0.4, 0.7))
	_build_new_places()


func _build_traffic() -> void:
	pass


func _build_walls() -> void:
	# Keep everyone on the island: a ring of invisible walls just inside the shoreline.
	for i in 34:
		var a := i * TAU / 34.0
		var r := SHORE - 3.0
		var p := Vector3(cos(a) * r, 2.0, sin(a) * r)
		if absf(p.x) < 4.0 and p.z > 50.0:
			continue
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(14.5, 6, 1.2)
		cs.shape = sh
		body.add_child(cs)
		body.position = p
		body.rotation.y = -a + PI / 2
		add_child(body)
	for w in [[Vector3(0, 2, 70.5 + PIER), Vector3(8, 6, 1)], [Vector3(-3.2, 2, 62 + PIER), Vector3(1, 6, 22)], [Vector3(3.2, 2, 62 + PIER), Vector3(1, 6, 22)]]:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = w[1]
		cs.shape = sh
		body.add_child(cs)
		body.position = w[0]
		add_child(body)


func _build_more_paths(path: Material) -> void:
	box(Vector3(4.0, 0.12, 28.0), Vector3(-40.0, 0.1, 24.0), path, false)    # red dorm down to the old woods
	box(Vector3(22.0, 0.12, 4.0), Vector3(-30.0, 0.1, 38.0), path, false)
	box(Vector3(22.0, 0.12, 4.0), Vector3(30.0, 0.1, 46.0), path, false)    # lighthouse down to the beach
	box(Vector3(4.0, 0.12, 18.0), Vector3(41.0, 0.1, 46.0), path, false)
	box(Vector3(16.0, 0.12, 4.0), Vector3(11.0, 0.1, -20.0), path, false)   # to the outdoor courts


## New on the island: an outdoor arena with stands, a beach, the old woods with a ruined dorm,
## tennis-court style practice duel fields and a cliff-top lookout.
func _build_new_places() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	# Stands around the outdoor duel field.
	var fc := Vector3(19.0, 0.1, 30.0)
	for k in 3:
		var a := PI * 0.5 + (k - 1) * 0.8
		var gp := fc + Vector3(cos(a), 0, sin(a)) * 11.0
		var g := prop("grandstand", gp, atan2(fc.x - gp.x, fc.z - gp.z), 9.0)
		if g:
			collide(g, 0.85)
	neon_sign("DUEL FIELD", fc + Vector3(0, 6.5, -9.0), Color("b48cff"), 140, 0.0, false)
	# The beach in the south-east: sand, umbrellas and towels.
	var sand := mat(Color(0.9, 0.82, 0.6), 0.95)
	cyl(16.0, 18.0, 0.2, Vector3(48.0, 0.0, 50.0), sand, null, 32)
	var cols := [Color("ff5a5a"), Color("ffd166"), Color("5ac8ff"), Color("7dffb0"), Color("ff8ad4")]
	for k in 6:
		var up := Vector3(40.0 + (k % 3) * 6.0, 0, 46.0 + (k / 3) * 7.0)
		cyl(0.05, 0.05, 2.6, up + Vector3(0, 1.3, 0), mat(Color(0.9, 0.9, 0.9), 0.5))
		var um := cyl(0.05, 1.5, 0.5, up + Vector3(0, 2.5, 0), mat(cols[k % cols.size()], 0.7), null, 10)
		um.rotation.z = 0.12
		box(Vector3(0.9, 0.03, 1.8), up + Vector3(1.0, 0.13, 0.6), mat(cols[(k + 2) % cols.size()], 0.9), false)
	# The old woods (south-west): dense trees around the ruins of an abandoned dorm.
	for i in 30:
		var p := Vector3(-48.0 + rng.randf_range(-14, 14), 0, 40.0 + rng.randf_range(-12, 14))
		if p.distance_to(Vector3(-46, 0, 42)) < 7.5 or Vector2(p.x, p.z).length() > SHORE - 6.0:
			continue
		tree(p, rng.randf_range(1.0, 1.5))
	var ruin := mat(Color(0.5, 0.48, 0.46), 0.95)
	var rc := Vector3(-46.0, 0, 42.0)
	box(Vector3(9.0, 0.3, 7.0), rc + Vector3(0, 0.15, 0), ruin)
	box(Vector3(9.0, 4.2, 0.4), rc + Vector3(0, 2.1, -3.3), ruin)
	box(Vector3(0.4, 3.0, 6.6), rc + Vector3(-4.3, 1.5, 0), ruin)
	box(Vector3(0.4, 2.0, 3.0), rc + Vector3(4.3, 1.0, -1.8), ruin)
	box(Vector3(3.4, 1.4, 0.4), rc + Vector3(-2.6, 0.7, 3.3), ruin)
	for k in 3:
		box(Vector3(1.0, 1.3, 0.06), rc + Vector3(-3.0 + k * 3.0, 2.6, -3.08), glow_mat(Color(0.5, 0.3, 0.8), 0.6), false)
	var boards := mat(Color(0.36, 0.26, 0.18), 0.9)
	for k in 4:
		var b := box(Vector3(2.6, 0.18, 0.06), rc + Vector3(-3.0 + (k % 2) * 6.0, 1.9 + (k / 2) * 0.7, -3.0), boards, false)
		b.rotation.z = 0.3 * (1 if k % 2 == 0 else -1)
	neon_sign("OLD DORM  ·  KEEP OUT", rc + Vector3(0, 4.6, -3.0), Color("b48cff"), 70, 0.0, false)
	var eerie := OmniLight3D.new()
	eerie.light_color = Color(0.6, 0.4, 1.0)
	eerie.light_energy = 2.0
	eerie.omni_range = 10.0
	eerie.position = rc + Vector3(0, 2.0, 0)
	add_child(eerie)
	# Practice fields by the main building: four painted duel mats with low fences.
	var courts := Vector3(18.0, 0.1, -22.0)
	for k in 2:
		var cp := courts + Vector3(k * 9.0, 0, 0)
		box(Vector3(7.5, 0.06, 5.5), cp + Vector3(0, 0.05, 0), mat(Color(0.2, 0.42, 0.5), 0.8), false)
		for side: float in [-1.0, 1.0]:
			box(Vector3(5.2, 0.065, 0.06), cp + Vector3(0, 0.06, side * 1.6), glow_mat(Color("7cc4ff"), 0.8), false)
			for z in 5:
				box(Vector3(0.7, 0.066, 0.9), cp + Vector3(-2.2 + z * 1.1, 0.06, side * 1.0), mat(Color(0.16, 0.3, 0.38), 0.8), false)
	neon_sign("PRACTICE FIELDS", courts + Vector3(4.5, 3.4, -3.6), Color("7cc4ff"), 90, 0.0, false)
	# A cliff-top lookout with a telescope, north-east.
	var lk := Vector3(40.0, 0, -36.0)
	cyl(4.0, 4.4, 0.4, lk + Vector3(0, 0.2, 0), mat(Color(0.6, 0.58, 0.54), 0.9), null, 20)
	for k in 10:
		var a := PI * 1.1 + k * 0.12
		cyl(0.06, 0.06, 1.0, lk + Vector3(cos(a) * 3.8, 0.9, sin(a) * 3.8), mat(Color(0.25, 0.25, 0.28), 0.4, 0.6))
	var tel := cyl(0.12, 0.2, 1.2, lk + Vector3(1.4, 1.5, -1.6), mat(Color(0.7, 0.62, 0.3), 0.3, 0.8))
	tel.rotation.x = 0.9
	cyl(0.04, 0.06, 1.1, lk + Vector3(1.4, 0.75, -1.6), mat(Color(0.25, 0.25, 0.28), 0.4, 0.6))
	box(Vector3(14.0, 0.12, 4.0), Vector3(33.0, 0.1, -30.0), _tile_material(Color(0.72, 0.68, 0.6), 1.4), false)


var _spinners: Array = []
var _bobbers: Array = []


func _process(delta: float) -> void:
	super._process(delta)
	for s in _spinners:
		(s as Node3D).rotation.y += delta * float(s.get_meta("spin", 0.3))
	for b in _bobbers:
		(b[0] as Node3D).position.y = float(b[1]) + sin(_time * 0.9) * 0.12
		(b[0] as Node3D).rotation.z = sin(_time * 0.7) * 0.02
