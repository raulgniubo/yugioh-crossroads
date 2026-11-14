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


## Lights that never hold still: [light, steady energy, speed, what burns with it]. The last is
## nothing, one mesh (a welder's spark, shown only while the arc is lit) or a list of flames.
var _flick: Array = []


func _process(delta: float) -> void:
	super._process(delta)
	for f in _flick:
		var l: OmniLight3D = f[0]
		var sp: float = f[2]
		var n := sin(_time * sp) * 0.5 + sin(_time * sp * 2.37 + 1.3) * 0.3 + sin(_time * sp * 5.1 + 0.4) * 0.2
		if f[3] is MeshInstance3D:
			# A welder works in bursts: a second or two of arc, then a look at the seam.
			var on := fmod(_time, 5.0) < 2.6 and n > -0.35
			l.light_energy = float(f[1]) * (1.0 + n * 0.5) if on else 0.0
			(f[3] as MeshInstance3D).visible = on
		elif f[3] is Array:
			l.light_energy = float(f[1]) * (0.82 + n * 0.22)
			var k := 0
			for fl in f[3]:
				(fl as Node3D).scale = Vector3(1.0 + sin(_time * (7.0 + k * 2.3) + k) * 0.18, 1.0 + sin(_time * (9.0 + k * 3.1) + k * 2.0) * 0.3, 1.0)
				k += 1
		else:
			l.light_energy = float(f[1]) * (0.94 + n * 0.06)


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
		StreetKit.shop(self, "lounge", Vector3(-24, 0, -18), 0.9)
		arcade_building(Vector3(25, 0, -17), 9.0, 8.0, -0.9)
		collide(prop("card_shop", Vector3(22, 0, 19), -2.3, 8.5, true))
		collide(prop("clock_tower", Vector3(-26, 0, 20), 2.2, 16.0, true), 0.6)
		for b in [Vector3(-6, 0, 14), Vector3(6, 0, 14), Vector3(-15, 0, -6), Vector3(15, 0, -6)]:
			collide(prop("bench", b, PI if b.z > 0 else 0.0, 2.2), 0.7)
		neon_sign("HEARTLAND", Vector3(0, 7.5, -32), Color(theme["accent"]), 260)
		ArenaScenery.heartland(self)
	else:
		for i in 4:
			collide(prop("motorcycle", Vector3(-14.0 + i * 2.4, 0, 12.5), 0.5 + i * 0.2, 2.3), 0.7)
		collide(prop("motorcycle", Vector3(13, 0, -11), -2.2, 2.3), 0.7)
		collide(prop("food_stall", Vector3(18, 0, 14), -2.4, 4.6), 0.8)
		StreetKit.shop(self, "shack", Vector3(-25, 0, -16), 0.9)
		collide(prop("card_shop", Vector3(24, 0, -18), -0.9, 8.5, true))
		collide(prop("vending", Vector3(-20, 0, 12), 1.2, 2.2, true), 0.8)
		collide(prop("bus_stop", Vector3(7.5, 0, 27.5), PI, 4.2), 0.7)
		for b in [Vector3(-12, 0, -14), Vector3(8, 0, 16)]:
			collide(prop("bench", b, 0.6, 2.2), 0.7)
		neon_sign("SATELLITE", Vector3(0, 6.5, -30), Color(theme["accent"]), 240)
		ArenaScenery.satellite(self)
	make_solid = false


## Satellite: open ground with the scrap heaped up around the edge and the bright city far off.
func _junk_scene() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	# Beaten earth far out, a slab of cracked concrete where the town stands, two tarred roads.
	box(Vector3(260, 0.2, 260), Vector3(0, -0.17, 0), mat(Color(0.2, 0.16, 0.13), 0.95), false)
	box(Vector3(96, 0.1, 96), Vector3(0, -0.06, 0), surf("concrete", Color(0.33, 0.31, 0.29), 0.6), false)
	box(Vector3(5.0, 0.03, 70), Vector3(0, 0.0, 2), mat(Color(0.1, 0.098, 0.1), 0.9), false)
	box(Vector3(60, 0.03, 4.0), Vector3(0, 0.0, 20), mat(Color(0.1, 0.098, 0.1), 0.9), false)
	# The bright city across the water: near enough to see, too far to reach.
	for i in 34:
		var x := lerpf(-130, 130, i / 33.0) + rng.randf_range(-3, 3)
		building(Vector3(x, -10, -120 - rng.randf() * 20), Vector3(rng.randf_range(6, 11), rng.randf_range(20, 60), 8), rng)
	box(Vector3(320, 0.1, 50), Vector3(0, -0.1, -92), mat(Color(0.05, 0.07, 0.1), 0.02, 0.2), false)


## Heartland: a tiled plaza with glowing lines, the tower with its rings, towers all around.
func _heartland_scene() -> void:
	box(Vector3(260, 0.2, 260), Vector3(0, -0.15, 0), _tile_material(Color(0.5, 0.48, 0.58), 3.0), false)
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
	ArenaScenery.towers(self)
