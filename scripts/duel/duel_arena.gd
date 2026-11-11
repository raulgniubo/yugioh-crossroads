class_name DuelArena
extends CityBuilder
## The world around the duel field: a different place for every field theme.
## Mostly seen during the opening fly-in and the low attack / ace camera shots.

var _spin: Array[Node3D] = []
var _bob: Array = []  # [node, base_y, speed]


func build_arena(t: Dictionary) -> void:
	theme = t
	make_solid = false
	match str(t.get("key", "crossroads")):
		"battlecity":
			_rooftop()
		"kaibacorp":
			_dome()
		"academy":
			_academy()
		"satellite":
			_junkyard()
		"heartland":
			_heartland()
		_:
			_void()
	_stage_ring()
	_light_windows(0.5 if str(t.get("key", "")) in ["satellite", "heartland"] else 1.0)


func _light_windows(strength: float) -> void:
	for m in _window_mats:
		m.set_shader_parameter("glow_strength", strength)
		m.set_shader_parameter("day", 0.0)
	for n in _neon:
		(n[0] as Label3D).modulate = Color(n[2]) * 2.2


func _process(delta: float) -> void:
	_time += delta
	for n in _spin:
		n.rotation.y += delta * float(n.get_meta("spin", 0.1))
	for b in _bob:
		(b[0] as Node3D).position.y = float(b[1]) + sin(_time * float(b[2])) * 0.4


# ------------------------------------------------------------------ shared pieces

## A raised rim around the duel field so it reads as a stage.
func _stage_ring() -> void:
	var rim := mat(Color(theme["base"]).lightened(0.12), 0.35, 0.6)
	var glow := glow_mat(theme["accent"], 2.2)
	for side in [-1, 1]:
		box(Vector3(15.4, 0.35, 0.5), Vector3(0, -0.18, side * 5.35), rim, false)
		box(Vector3(0.5, 0.35, 11.2), Vector3(side * 7.45, -0.18, 0), rim, false)
		box(Vector3(15.4, 0.04, 0.06), Vector3(0, 0.0, side * 5.62), glow, false)
		box(Vector3(0.06, 0.04, 11.2), Vector3(side * 7.72, 0.0, 0), glow, false)


func _crowd(center: Vector3, radius_from: float, radius_to: float, rows: int, arc_from: float, arc_to: float, base_y: float, step_h: float) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cap := CapsuleMesh.new()
	cap.radius = 0.22
	cap.height = 0.9
	cap.radial_segments = 8
	cap.rings = 2
	var cm := StandardMaterial3D.new()
	cm.vertex_color_use_as_albedo = true
	cm.roughness = 0.9
	cap.material = cm
	mm.mesh = cap
	var per_row := 70
	mm.instance_count = rows * per_row
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var palette := [Color("e0533f"), Color("3f7be0"), Color("e8e8ee"), Color("2b2b33"), Color("f0c040"), Color("3fbf8a"), Color("8a4fd9")]
	var i := 0
	for r in rows:
		var rad := lerpf(radius_from, radius_to, float(r) / maxf(1.0, rows - 1.0))
		for k in per_row:
			var a := lerpf(arc_from, arc_to, (k + rng.randf() * 0.5) / per_row)
			var p := center + Vector3(sin(a) * rad, base_y + r * step_h + 0.45, cos(a) * rad)
			mm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * rng.randf_range(0.9, 1.1)), p))
			mm.set_instance_color(i, palette[rng.randi() % palette.size()].darkened(rng.randf() * 0.4))
			i += 1
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


func _stands(radius: float, rows: int, arc_from: float, arc_to: float, color: Color) -> void:
	var seat := mat(color, 0.7)
	for r in rows:
		var rad := radius + r * 1.3
		var segs := 40
		for k in segs:
			var a := lerpf(arc_from, arc_to, (k + 0.5) / segs)
			var len := rad * absf(arc_to - arc_from) / segs * 1.04
			var b := box(Vector3(len, 0.55, 1.3), Vector3(sin(a) * rad, r * 0.55 + 0.25, cos(a) * rad), seat, false)
			b.rotation.y = a
	_crowd(Vector3.ZERO, radius, radius + (rows - 1) * 1.3, rows, arc_from, arc_to, 0.5, 0.55)


func _screen(text: String, pos: Vector3, rot: float, w: float, h: float, color: Color) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = rot
	add_child(n)
	box(Vector3(w + 0.6, h + 0.6, 0.4), Vector3(0, 0, -0.25), mat(Color(0.1, 0.1, 0.12), 0.5, 0.5), false, n)
	box(Vector3(w, h, 0.05), Vector3.ZERO, glow_mat(Color(color).darkened(0.6), 1.0), false, n)
	var l := Label3D.new()
	l.text = text
	l.font_size = int(h * 90)
	l.pixel_size = 0.01
	l.modulate = Color(color) * 2.2
	l.shaded = false
	l.position = Vector3(0, 0, 0.05)
	l.font = load("res://assets/fonts/Rajdhani-SemiBold.ttf")
	n.add_child(l)


func _spotlight(pos: Vector3, target: Vector3, color: Color) -> void:
	var s := SpotLight3D.new()
	s.light_color = color
	s.light_energy = 6.0
	s.spot_range = 40.0
	s.spot_angle = 14.0
	s.light_volumetric_fog_energy = 3.0
	s.position = pos
	add_child(s)
	s.look_at_from_position(pos, target)
	cyl(0.25, 0.4, 0.6, pos, mat(Color(0.15, 0.15, 0.17), 0.4, 0.7))


# ------------------------------------------------------------------ themes

func _rooftop() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var concrete := _tile_material(Color(0.32, 0.31, 0.34), 2.0)
	box(Vector3(34, 0.2, 28), Vector3(0, -0.15, 0), concrete, false)
	var rail := mat(Color(0.6, 0.62, 0.66), 0.35, 0.8)
	for side in [-1, 1]:
		box(Vector3(34, 1.0, 0.4), Vector3(0, 0.5, side * 14.0), mat(Color(0.3, 0.3, 0.33)), false)
		box(Vector3(0.4, 1.0, 28), Vector3(side * 17.0, 0.5, 0), mat(Color(0.3, 0.3, 0.33)), false)
		box(Vector3(34, 0.08, 0.08), Vector3(0, 1.6, side * 14.0), rail, false)
		box(Vector3(0.08, 0.08, 28), Vector3(side * 17.0, 1.6, 0), rail, false)
	# Helipad-style marking and rooftop gear
	box(Vector3(2.0, 2.4, 3.0), Vector3(-14, 1.2, -10), mat(Color(0.5, 0.5, 0.55), 0.5, 0.5), false)
	box(Vector3(3.0, 3.0, 3.0), Vector3(13, 1.5, -11), mat(Color(0.35, 0.35, 0.4), 0.6), false)
	# Skyline all around
	for i in 46:
		var a := rng.randf() * TAU
		var d := rng.randf_range(32.0, 70.0)
		var h := rng.randf_range(14.0, 70.0)
		var w := rng.randf_range(7.0, 14.0)
		var p := Vector3(sin(a) * d, -30.0, cos(a) * d)
		building(p, Vector3(w, h + 30.0, w), rng)
	var tower := window_material(Color(0.3, 0.36, 0.5), 7.0, Color("7cc4ff"))
	tower.set_shader_parameter("style", 1.0)
	box(Vector3(16, 110, 16), Vector3(-26, 25, -60), tower, false)
	neon_sign("KC", Vector3(-26, 66, -51.9), Color("7cc4ff"), 1400, 0.0, false)
	# Floating blimp with a screen
	var blimp := Node3D.new()
	blimp.position = Vector3(18, 22, -40)
	add_child(blimp)
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 3.0
	cap.height = 14.0
	body.mesh = cap
	body.material_override = mat(Color(0.85, 0.86, 0.9), 0.4, 0.2)
	body.rotation.z = PI / 2
	blimp.add_child(body)
	box(Vector3(6, 2.2, 0.1), Vector3(0, 0, 3.0), glow_mat(theme["accent"], 2.0), false, blimp)
	_bob.append([blimp, 22.0, 0.3])


func _dome() -> void:
	box(Vector3(80, 0.2, 80), Vector3(0, -0.15, 0), mat(Color(0.06, 0.08, 0.14), 0.15, 0.7), false)
	_stands(17.0, 9, -PI, PI, Color(0.16, 0.2, 0.3))
	# Dome ribs
	var rib := mat(Color(0.75, 0.82, 0.95), 0.3, 0.8)
	for k in 12:
		var arc := Node3D.new()
		arc.rotation.y = k * TAU / 12
		add_child(arc)
		for s in 14:
			var a := s * (PI / 2) / 14
			var r := 30.0
			var seg := box(Vector3(0.5, 0.5, 2.4), Vector3(0, sin(a) * r * 0.7, cos(a) * r), rib, false, arc)
			seg.rotation.x = -a
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 27.0
	tm.outer_radius = 27.6
	tm.rings = 96
	ring.mesh = tm
	ring.material_override = glow_mat(theme["accent"], 3.0)
	ring.position.y = 10.0
	add_child(ring)
	for k in 4:
		var a := k * TAU / 4 + PI / 4
		_screen("KAIBACORP", Vector3(sin(a) * 26, 14, cos(a) * 26), a + PI, 10, 5, theme["accent"])
	for k in 6:
		var a := k * TAU / 6
		_spotlight(Vector3(sin(a) * 24, 18, cos(a) * 24), Vector3(0, 0, 0), Color(0.85, 0.92, 1.0))


func _academy() -> void:
	box(Vector3(80, 0.2, 80), Vector3(0, -0.15, 0), mat(Color(0.2, 0.08, 0.08), 0.3, 0.3), false)
	var lines := glow_mat(theme["accent2"], 1.5)
	for r in [10.5, 12.0]:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = r
		tm.outer_radius = r + 0.12
		tm.rings = 96
		ring.mesh = tm
		ring.material_override = lines
		ring.scale = Vector3(1, 0.05, 0.7)
		add_child(ring)
	_stands(16.0, 10, -PI * 0.92, PI * 0.92, Color(0.35, 0.12, 0.12))
	var banner_cols := [Color("d02030"), Color("f0c040"), Color("3070e0")]
	for k in 9:
		var a := lerpf(-PI * 0.8, PI * 0.8, k / 8.0)
		var n := Node3D.new()
		n.position = Vector3(sin(a) * 30, 12, cos(a) * 30)
		n.rotation.y = a + PI
		add_child(n)
		box(Vector3(2.4, 7.0, 0.1), Vector3.ZERO, mat(banner_cols[k % 3], 0.8), false, n)
		box(Vector3(2.6, 0.2, 0.2), Vector3(0, 3.6, 0), mat(Color(0.8, 0.7, 0.3), 0.3, 0.8), false, n)
	_screen("DUEL ACADEMY", Vector3(0, 16, -31), 0.0, 16, 6, theme["accent2"])
	for k in 4:
		var a := k * TAU / 4 + PI / 4
		_spotlight(Vector3(sin(a) * 26, 22, cos(a) * 26), Vector3(0, 0, 0), Color(1.0, 0.9, 0.75))


func _junkyard() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	box(Vector3(90, 0.2, 90), Vector3(0, -0.15, 0), mat(Color(0.18, 0.14, 0.11), 0.95), false)
	var rust := [Color(0.45, 0.25, 0.14), Color(0.3, 0.3, 0.32), Color(0.5, 0.42, 0.3), Color(0.25, 0.2, 0.18), Color(0.4, 0.15, 0.12)]
	for i in 140:
		var a := rng.randf() * TAU
		var d := rng.randf_range(13.0, 40.0)
		var p := Vector3(sin(a) * d, 0, cos(a) * d)
		var s := rng.randf_range(0.8, 3.4)
		var m := mat(rust[rng.randi() % rust.size()], rng.randf_range(0.6, 0.95), rng.randf_range(0.0, 0.6))
		var b: MeshInstance3D
		if rng.randf() < 0.6:
			b = box(Vector3(s, s * rng.randf_range(0.4, 1.0), s * rng.randf_range(0.6, 1.4)), p + Vector3(0, s * 0.3 + (d - 13.0) * 0.08, 0), m, false)
		else:
			b = cyl(s * 0.4, s * 0.4, s * 1.5, p + Vector3(0, s * 0.4 + (d - 13.0) * 0.08, 0), m)
		b.rotation = Vector3(rng.randf_range(-0.6, 0.6), rng.randf() * TAU, rng.randf_range(-0.6, 0.6))
	# Crane
	var steel := mat(Color(0.8, 0.55, 0.15), 0.6, 0.5)
	box(Vector3(1.2, 22, 1.2), Vector3(-20, 11, -24), steel, false)
	var arm := box(Vector3(26, 1.0, 1.0), Vector3(-12, 22, -24), steel, false)
	arm.rotation.y = 0.4
	# The bright city across the water
	for i in 30:
		var x := lerpf(-90, 90, i / 29.0) + rng.randf_range(-3, 3)
		var h := rng.randf_range(10, 45)
		building(Vector3(x, -10, -95 - rng.randf() * 15), Vector3(rng.randf_range(5, 10), h + 10, 8), rng)
	box(Vector3(220, 0.1, 50), Vector3(0, -0.4, -70), mat(Color(0.05, 0.07, 0.1), 0.02, 0.2), false)
	for k in 2:
		_spotlight(Vector3(-14 + k * 28, 9, -14), Vector3(0, 0, 0), Color(1.0, 0.7, 0.4))


func _heartland() -> void:
	box(Vector3(90, 0.2, 90), Vector3(0, -0.15, 0), _tile_material(Color(0.16, 0.12, 0.18), 3.0), false)
	var pink := glow_mat(theme["accent2"], 2.5)
	var gold := glow_mat(theme["accent"], 2.5)
	for k in 16:
		var a := k * TAU / 16
		var line := box(Vector3(0.12, 0.04, 30), Vector3(sin(a) * 25, 0.0, cos(a) * 25), pink if k % 2 == 0 else gold, false)
		line.rotation.y = a
	# Spire with floating rings
	var spire := Node3D.new()
	spire.position = Vector3(0, 0, -50)
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
	for i in 30:
		var a := rng.randf() * TAU
		var d := rng.randf_range(35.0, 75.0)
		building(Vector3(sin(a) * d, -10, cos(a) * d), Vector3(rng.randf_range(6, 12), rng.randf_range(20, 60), rng.randf_range(6, 12)), rng)


func _void() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var rock := mat(Color(0.18, 0.2, 0.26), 0.9)
	var top := mat(Color(0.12, 0.3, 0.32), 0.8)
	for i in 18:
		var a := rng.randf() * TAU
		var d := rng.randf_range(16.0, 45.0)
		var s := rng.randf_range(1.5, 5.0)
		var y := rng.randf_range(-8.0, 10.0)
		var island := Node3D.new()
		island.position = Vector3(sin(a) * d, y, cos(a) * d)
		add_child(island)
		cyl(s, s * 0.2, s * 1.8, Vector3(0, -s * 0.9, 0), rock, island, 7)
		cyl(s * 1.02, s, 0.25, Vector3(0, 0.05, 0), top, island, 7)
		_bob.append([island, y, rng.randf_range(0.2, 0.5)])
	for i in 3:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 22.0 + i * 6.0
		tm.outer_radius = 22.3 + i * 6.0
		tm.rings = 128
		ring.mesh = tm
		ring.material_override = glow_mat(theme["accent"] if i != 1 else theme["accent2"], 2.0)
		ring.rotation = Vector3(0.3 * (i - 1), 0, 0.2 * i)
		ring.set_meta("spin", 0.05 * (i + 1))
		add_child(ring)
		_spin.append(ring)
