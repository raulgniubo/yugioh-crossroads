class_name AcademyBuilder
extends CityBuilder
## Duel Academy: a school on a volcanic island. Reuses CityBuilder's sky, lighting and prop helpers.

const SHORE := 60.0


func _build_ground() -> void:
	# The sea
	var sea := StandardMaterial3D.new()
	sea.albedo_color = Color(0.07, 0.3, 0.46)
	sea.roughness = 0.08
	sea.metallic = 0.35
	box(Vector3(900, 0.2, 900), Vector3(0, -0.75, 0), sea, false)
	# Sand, then grass, then stone paths
	cyl(SHORE + 4.0, SHORE + 9.0, 1.0, Vector3(0, -0.5, 0), mat(Color(0.86, 0.78, 0.58), 0.95), null, 48)
	cyl(SHORE - 8.0, SHORE - 5.0, 0.3, Vector3(0, -0.06, 0), mat(Color(0.3, 0.52, 0.24), 0.95), null, 48)
	var floor_body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(200, 1, 200)
	cs.shape = sh
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.41, 0)
	add_child(floor_body)
	var path := _tile_material(Color(0.72, 0.68, 0.6), 1.4)
	box(Vector3(5.0, 0.12, 62.0), Vector3(0, 0.1, 17.0), path, false)       # dock -> plaza -> academy
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
	box(Vector3(5.0, 0.3, 22.0), Vector3(0, 0.05, 59.0), wood, false)
	for i in 6:
		for sx in [-1, 1]:
			cyl(0.18, 0.18, 2.4, Vector3(sx * 2.3, -0.5, 50.0 + i * 3.8), wood)


func _build_buildings() -> void:
	collide(prop("academy_main", Vector3(0, 0.05, -46.0), 0.0, 52.0), 0.82)
	neon_sign("DUEL ACADEMY", Vector3(0, 9.5, -30.5), Color("ffe9a8"), 260, 0.0, false)
	collide(prop("dorm_red", Vector3(-42.0, 0.05, 8.0), PI / 2, 15.0), 0.85)
	neon_sign("RED DORM", Vector3(-33.8, 4.6, 8.0), Color("ff6b6b"), 110, PI / 2, false)
	collide(prop("dorm_yellow", Vector3(42.0, 0.05, -6.0), -PI / 2, 16.0), 0.85)
	neon_sign("YELLOW DORM", Vector3(33.4, 5.4, -6.0), Color("ffd166"), 110, -PI / 2, false)
	collide(prop("dorm_blue", Vector3(-30.0, 0.05, -26.0), 0.35, 22.0), 0.85)
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
	var boat := prop("ferry", Vector3(7.5, -0.7, 62.0), 0.2, 15.0)
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
		if absf(p.x) < 5.0 and p.z > 40.0:
			continue
		if p.z < -40.0:
			continue
		var palm := prop("palm", p, rng.randf() * TAU, rng.randf_range(6.5, 9.0), true)
		if palm:
			solid_cyl(0.3, 3.0, p + Vector3(0, 1.5, 0))
		else:
			tree(p, 1.1)
	for p in [Vector3(-12, 0, 16), Vector3(-22, 0, 20), Vector3(10, 0, 14), Vector3(-10, 0, -10), Vector3(12, 0, -14), Vector3(28, 0, 8),
			Vector3(-16, 0, 34), Vector3(-26, 0, 30), Vector3(30, 0, 18), Vector3(-44, 0, -8), Vector3(10, 0, -24), Vector3(-12, 0, -24), Vector3(34, 0, -22)]:
		tree(p, rng.randf_range(0.9, 1.25))
	# Lamps and benches along the main path
	for z in [38.0, 26.0, 13.0, -13.0, -24.0]:
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
	collide(prop("vending", Vector3(4.2, 0.1, 44.0), -PI / 2, 1.95, true))
	collide(prop("fountain", Vector3(0, 0.12, -27.0), 0.0, 5.0), 0.8)
	# A statue by the school steps and banners at the dock
	collide(prop("dragon_statue", Vector3(-9.0, 0.1, -26.0), 0.5, 4.5, true), 0.6)
	collide(prop("dragon_statue", Vector3(9.0, 0.1, -26.0), -0.5, 4.5, true), 0.6)
	neon_sign("WELCOME TO DUEL ACADEMY", Vector3(0, 4.8, 47.0), theme["accent2"], 120, PI, false)
	for sx in [-1, 1]:
		cyl(0.1, 0.1, 5.0, Vector3(sx * 6.0, 2.5, 47.0), mat(Color(0.2, 0.2, 0.24), 0.4, 0.7))


func _build_traffic() -> void:
	pass


func _build_walls() -> void:
	# Keep everyone on the island: a ring of invisible walls just inside the shoreline.
	for i in 28:
		var a := i * TAU / 28.0
		var r := SHORE - 3.0
		var p := Vector3(cos(a) * r, 2.0, sin(a) * r)
		if absf(p.x) < 4.0 and p.z > 40.0:
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
	for w in [[Vector3(0, 2, 70.5), Vector3(8, 6, 1)], [Vector3(-3.2, 2, 62), Vector3(1, 6, 22)], [Vector3(3.2, 2, 62), Vector3(1, 6, 22)]]:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = w[1]
		cs.shape = sh
		body.add_child(cs)
		body.position = w[0]
		add_child(body)


var _spinners: Array = []
var _bobbers: Array = []


func _process(delta: float) -> void:
	super._process(delta)
	for s in _spinners:
		(s as Node3D).rotation.y += delta * float(s.get_meta("spin", 0.3))
	for b in _bobbers:
		(b[0] as Node3D).position.y = float(b[1]) + sin(_time * 0.9) * 0.12
		(b[0] as Node3D).rotation.z = sin(_time * 0.7) * 0.02
