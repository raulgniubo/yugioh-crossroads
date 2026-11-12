class_name ArenaDistrict
extends DuelArena
## A walkable district built from a duel arena's scenery: the Satellite junkyard (5D's) and
## Heartland plaza (ZEXAL). A duel ring sits in the middle, the people of that era stand around it.

const RADIUS := 40.0


func build(t: Dictionary, time_of_day: String) -> void:
	theme = t
	_build_env()
	make_solid = false
	if str(t.get("key", "")) == "heartland":
		_heartland_scene()
	else:
		_junk_scene()
	_stage_ring()
	_light_windows(0.6)
	_floor_and_ring()
	_dress(str(t.get("key", "")))
	apply_tod(time_of_day)


func apply_tod(t: String) -> void:
	super.apply_tod(t)
	_light_windows(0.6 if t != "day" else 0.1)


func _floor_and_ring() -> void:
	var floor_body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(240, 1, 240)
	cs.shape = sh
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.5, 0)
	add_child(floor_body)
	for i in 24:
		var a := i * TAU / 24.0
		var body := StaticBody3D.new()
		var c2 := CollisionShape3D.new()
		var s2 := BoxShape3D.new()
		s2.size = Vector3(11.5, 8, 1.2)
		c2.shape = s2
		body.add_child(c2)
		body.position = Vector3(cos(a) * RADIUS, 3.0, sin(a) * RADIUS)
		body.rotation.y = -a + PI / 2
		add_child(body)
	# The duel ring in the middle: a lit mat inside the stage rim.
	box(Vector3(12, 0.04, 7.6), Vector3(0, 0.0, 0), mat(Color(theme["base"]).lightened(0.08), 0.4, 0.3), false)
	var line := glow_mat(theme["accent"], 1.6)
	box(Vector3(12, 0.05, 0.08), Vector3(0, 0.02, 0), line, false)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.6
	tm.outer_radius = 1.72
	ring.mesh = tm
	ring.material_override = line
	ring.scale = Vector3(1, 0.1, 1)
	ring.position = Vector3(0, 0.03, 0)
	add_child(ring)


func _dress(key: String) -> void:
	make_solid = true
	var lamp_at := [Vector3(-9, 0, 9), Vector3(9, 0, 9), Vector3(-9, 0, -9), Vector3(9, 0, -9), Vector3(-20, 0, 0), Vector3(20, 0, 0), Vector3(0, 0, 22), Vector3(0, 0, -22)]
	for p in lamp_at:
		var l := prop("street_lamp", p, 0.0, 5.2, true)
		var o := OmniLight3D.new()
		o.light_color = Color(1.0, 0.85, 0.6) if key != "heartland" else Color(1.0, 0.7, 0.95)
		o.light_energy = 2.4
		o.omni_range = 11.0
		o.position = p + Vector3(0, 4.6, 0)
		add_child(o)
		_lamp_lights.append(o)
		if l:
			collide(l, 0.25)
	if key == "heartland":
		for i in 10:
			var a := i * TAU / 10.0 + 0.3
			var p := Vector3(cos(a) * 33.0, 0, sin(a) * 33.0)
			if absf(p.x) < 7.0:
				continue
			var tr := prop("sakura" if i % 2 == 0 else "tree", p, a, 6.5, true)
			if tr:
				collide(tr, 0.2)
		collide(prop("fountain", Vector3(0, 0, 17), 0.0, 5.0), 0.8)
		collide(prop("cafe", Vector3(-24, 0, -18), 0.9, 9.0, true))
		collide(prop("arcade", Vector3(25, 0, -17), -0.9, 9.5, true))
		collide(prop("card_shop", Vector3(22, 0, 19), -2.3, 8.5, true))
		collide(prop("clock_tower", Vector3(-26, 0, 20), 2.2, 16.0, true), 0.6)
		for b in [Vector3(-6, 0, 14), Vector3(6, 0, 14), Vector3(-15, 0, -6), Vector3(15, 0, -6)]:
			collide(prop("bench", b, PI if b.z > 0 else 0.0, 2.2), 0.7)
		neon_sign("HEARTLAND", Vector3(0, 7.5, -32), Color(theme["accent"]), 260)
	else:
		for i in 4:
			collide(prop("motorcycle", Vector3(-14.0 + i * 2.4, 0, 12.5), 0.5 + i * 0.2, 2.3), 0.7)
		collide(prop("motorcycle", Vector3(13, 0, -11), -2.2, 2.3), 0.7)
		collide(prop("food_stall", Vector3(18, 0, 14), -2.4, 4.6), 0.8)
		collide(prop("konbini", Vector3(-25, 0, -16), 0.9, 9.0), 0.9)
		collide(prop("card_shop", Vector3(24, 0, -18), -0.9, 8.5, true))
		collide(prop("vending", Vector3(-20, 0, 12), 1.2, 2.2, true), 0.8)
		collide(prop("bus_stop", Vector3(-6, 0, 24), PI, 4.2), 0.7)
		for b in [Vector3(-12, 0, -14), Vector3(8, 0, 16)]:
			collide(prop("bench", b, 0.6, 2.2), 0.7)
		neon_sign("SATELLITE", Vector3(0, 6.5, -30), Color(theme["accent"]), 240)
		neon_sign("DUEL RUNNER GARAGE", Vector3(-9, 3.2, 13.6), Color(theme["accent2"]), 70, 0.0, false)
	make_solid = false


## Satellite: open ground with the scrap heaped up around the edge and the bright city far off.
func _junk_scene() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	box(Vector3(240, 0.2, 240), Vector3(0, -0.15, 0), mat(Color(0.2, 0.16, 0.13), 0.95), false)
	box(Vector3(5.0, 0.03, 70), Vector3(0, 0.0, 2), mat(Color(0.12, 0.11, 0.11), 0.8), false)
	box(Vector3(60, 0.03, 4.0), Vector3(0, 0.0, 20), mat(Color(0.12, 0.11, 0.11), 0.8), false)
	var rust := [Color(0.45, 0.25, 0.14), Color(0.3, 0.3, 0.32), Color(0.5, 0.42, 0.3), Color(0.25, 0.2, 0.18), Color(0.4, 0.15, 0.12)]
	for i in 190:
		var a := rng.randf() * TAU
		var d := rng.randf_range(RADIUS + 1.5, RADIUS + 26.0)
		var p := Vector3(sin(a) * d, 0, cos(a) * d)
		var sz := rng.randf_range(1.2, 4.4)
		var m := mat(rust[rng.randi() % rust.size()], rng.randf_range(0.6, 0.95), rng.randf_range(0.0, 0.6))
		var b: MeshInstance3D
		var lift := (d - RADIUS) * 0.22
		if rng.randf() < 0.6:
			b = box(Vector3(sz, sz * rng.randf_range(0.4, 1.0), sz * rng.randf_range(0.6, 1.4)), p + Vector3(0, sz * 0.3 + lift, 0), m, false)
		else:
			b = cyl(sz * 0.4, sz * 0.4, sz * 1.5, p + Vector3(0, sz * 0.4 + lift, 0), m)
		b.rotation = Vector3(rng.randf_range(-0.6, 0.6), rng.randf() * TAU, rng.randf_range(-0.6, 0.6))
	var steel := mat(Color(0.8, 0.55, 0.15), 0.6, 0.5)
	box(Vector3(1.4, 30, 1.4), Vector3(-34, 15, -36), steel, false)
	var arm := box(Vector3(34, 1.2, 1.2), Vector3(-22, 30, -36), steel, false)
	arm.rotation.y = 0.4
	for i in 34:
		var x := lerpf(-130, 130, i / 33.0) + rng.randf_range(-3, 3)
		building(Vector3(x, -10, -120 - rng.randf() * 20), Vector3(rng.randf_range(6, 11), rng.randf_range(20, 60), 8), rng)
	box(Vector3(320, 0.1, 50), Vector3(0, -0.1, -92), mat(Color(0.05, 0.07, 0.1), 0.02, 0.2), false)


## Heartland: a tiled plaza with glowing lines, the tower with its rings, towers all around.
func _heartland_scene() -> void:
	box(Vector3(240, 0.2, 240), Vector3(0, -0.15, 0), _tile_material(Color(0.42, 0.4, 0.5), 3.0), false)
	var pink := glow_mat(theme["accent2"], 2.2)
	var gold := glow_mat(theme["accent"], 2.2)
	for k in 12:
		var a := k * TAU / 12
		var line := box(Vector3(0.14, 0.04, 22), Vector3(sin(a) * 26, 0.0, cos(a) * 26), pink if k % 2 == 0 else gold, false)
		line.rotation.y = a
	var spire := Node3D.new()
	spire.position = Vector3(0, 0, -58)
	add_child(spire)
	cyl(1.5, 6.0, 90, Vector3(0, 45, 0), mat(Color(0.85, 0.8, 0.9), 0.25, 0.7), spire, 24)
	for i in 5:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 7.0 + i * 1.5
		tm.outer_radius = 7.5 + i * 1.5
		tm.rings = 64
		ring.mesh = tm
		ring.material_override = pink if i % 2 == 0 else gold
		ring.position = Vector3(0, 20 + i * 14, 0)
		ring.rotation.x = 0.25
		ring.set_meta("spin", 0.15 + i * 0.05)
		spire.add_child(ring)
		_spin.append(ring)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 40:
		var a := i * TAU / 40.0 + rng.randf_range(-0.05, 0.05)
		var d := rng.randf_range(RADIUS + 9.0, RADIUS + 40.0)
		if absf(sin(a) * d) < 12.0 and cos(a) * d < 0:
			continue
		building(Vector3(sin(a) * d, 0, cos(a) * d), Vector3(rng.randf_range(7, 12), rng.randf_range(18, 55), rng.randf_range(7, 12)), rng)
