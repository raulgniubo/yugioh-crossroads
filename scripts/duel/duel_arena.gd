class_name DuelArena
extends CityBuilder
## The world around the duel field: a different place for every field theme.
## Mostly seen during the opening fly-in and the low attack / ace camera shots.

var _spin: Array[Node3D] = []
var _bob: Array = []  # [node, base_y, speed]


func build_arena(t: Dictionary) -> void:
	theme = t
	make_solid = false
	var key := str(t.get("key", "crossroads"))
	match key:
		"battlecity":
			_land(Vector2(34, 28))
			_rooftop()
			_rooftop_extras()
		"kaibacorp":
			_land(Vector2(80, 80))
			_dome()
			_dome_extras()
		"academy":
			_land(Vector2(80, 80))
			_academy()
			_hall_extras()
		"satellite":
			_land(Vector2(180, 180))
			_junkyard()
			_junk_extras()
		"heartland":
			_land(Vector2(180, 180))
			_heartland()
		"reddorm":
			_reddorm()
			return
		"bluehall":
			_bluehall()
			return
		"highway":
			_highway()
			_light_windows(1.0)
			return
		"pier":
			_pier()
			return
		"meadow", "volcano", "peak", "ruins", "tide":
			_wild(key)
			return
		"shadow":
			_void()
			_stone_rim(Color(0.12, 0.06, 0.18))
			return
		_:
			_void()
	_stage_ring()
	_light_windows(0.5 if key in ["satellite", "heartland"] else 1.0)


## The ground the field is painted on, running out as far as `size`: the same surface as the
## mat, so the mat is simply the marked-out part of the floor.
func _land(size: Vector2, at := Vector3(0, -0.03, 0), haze := 0.85) -> MeshInstance3D:
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	ground.mesh = pm
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded;
uniform int surface = 1;
uniform vec2 size = vec2(100.0);
uniform vec2 shift = vec2(0.0);
uniform float haze_amount = 0.85;
uniform vec3 haze : source_color = vec3(0.8, 0.9, 1.0);
""" + FieldThemes.GROUND_GLSL + """
void fragment() {
	vec2 p = (UV - 0.5) * size + shift;
	vec3 col = ground_color(p, surface, TIME) * 0.92;
	float far = smoothstep(26.0, 120.0, length(p));
	ALBEDO = mix(col, haze, far * haze_amount);
}
"""
	var gm := ShaderMaterial.new()
	gm.shader = sh
	gm.set_shader_parameter("surface", int(theme.get("surface", 1)))
	gm.set_shader_parameter("size", size)
	gm.set_shader_parameter("shift", Vector2(at.x, at.z))
	gm.set_shader_parameter("haze_amount", haze)
	gm.set_shader_parameter("haze", theme["fog"])
	ground.material_override = gm
	ground.position = at
	add_child(ground)
	return ground


## People watching from given spots: [position, which way they face].
func _fans(spots: Array, seed := 9) -> void:
	if spots.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _fan_mesh()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var palette: Array = theme.get("crowd", [Color("e0533f"), Color("3f7be0"), Color("e8e8ee"), Color("2b2b33"), Color("f0c040"), Color("3fbf8a"), Color("8a4fd9"), Color("d9d2c4"), Color("26364f")])
	mm.instance_count = spots.size()
	for i in spots.size():
		var sc := rng.randf_range(0.9, 1.12)
		var bs := Basis(Vector3.UP, float(spots[i][1]) + rng.randf_range(-0.2, 0.2)).scaled(Vector3(sc, sc * rng.randf_range(0.92, 1.08), sc))
		mm.set_instance_transform(i, Transform3D(bs, spots[i][0]))
		mm.set_instance_color(i, (palette[rng.randi() % palette.size()] as Color).darkened(rng.randf() * 0.25))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


## A row of onlookers from a to b, all turned toward the middle of the field.
func _fan_row(a: Vector3, b: Vector3, n: int, seed := 9) -> void:
	var spots: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 7 + n
	for i in n:
		var p := a.lerp(b, (i + rng.randf_range(0.2, 0.8)) / n)
		spots.append([p, atan2(-p.x, -p.z)])
	_fans(spots, seed)


## A string of little flags from a to b, sagging in the middle.
func _bunting(a: Vector3, b: Vector3, cols: Array, n := 14) -> void:
	for i in n:
		var t := (i + 0.5) / n
		var p := a.lerp(b, t) - Vector3(0, sin(t * PI) * 0.7, 0)
		var f := box(Vector3(0.34, 0.42, 0.02), p - Vector3(0, 0.2, 0), mat(cols[i % cols.size()], 0.8), false)
		f.rotation.y = atan2(b.x - a.x, b.z - a.z) + PI / 2.0
		f.rotation.z = 0.2 * sin(i * 1.7)
	var rope := box(Vector3(0.025, 0.025, a.distance_to(b)), (a + b) / 2.0 - Vector3(0, 0.3, 0), mat(Color(0.2, 0.18, 0.16), 0.8), false)
	rope.look_at_from_position(rope.position, b - Vector3(0, 0.3, 0))


## A flag on a pole, the cloth held out flat enough to read from above.
func _flag(at: Vector3, col: Color, height := 4.2, yaw := 0.0) -> void:
	cyl(0.05, 0.07, height, at + Vector3(0, height / 2.0, 0), mat(Color(0.75, 0.76, 0.8), 0.35, 0.7), null, 8)
	var cloth := box(Vector3(1.7, 0.03, 1.0), at + Vector3(0.9 * cos(yaw), height - 0.55, -0.9 * sin(yaw)), mat(col, 0.8), false)
	cloth.rotation.y = yaw
	cloth.rotation.x = 0.5
	var trim := box(Vector3(1.7, 0.035, 0.14), at + Vector3(0.9 * cos(yaw), height - 0.55, -0.9 * sin(yaw)), mat(Color(0.95, 0.9, 0.75), 0.8), false)
	trim.rotation.y = yaw
	trim.rotation.x = 0.5


# ------------------------------------------------------------------ what stands by the field

## Duel hall: the three dorms sit along the sidelines behind low boards in their colors.
func _hall_extras() -> void:
	var cols := [Color("d02030"), Color("f0c040"), Color("3070e0")]
	for sx: float in [-1.0, 1.0]:
		for k in 3:
			var z := -3.0 + k * 3.0
			var col: Color = cols[(k + (0 if sx < 0.0 else 1)) % 3]
			box(Vector3(0.18, 0.7, 2.7), Vector3(sx * 8.0, 0.35, z), mat(col, 0.6), false)
			box(Vector3(0.22, 0.06, 2.74), Vector3(sx * 8.0, 0.72, z), mat(Color(0.95, 0.92, 0.85), 0.5), false)
			# A bench of students behind each board.
			box(Vector3(0.5, 0.42, 2.5), Vector3(sx * 9.0, 0.21, z), mat(Color(0.3, 0.2, 0.14), 0.6), false)
			theme["crowd"] = [col, col.lightened(0.2), col.darkened(0.2), Color("e8e8ee")]
			_fan_row(Vector3(sx * 9.0, 0.42, z - 1.1), Vector3(sx * 9.0, 0.42, z + 1.1), 4, 20 + k + int(sx) * 5)
		theme.erase("crowd")
	for k in 3:
		_flag(Vector3(-4.6 + k * 4.6, 0, -8.2), cols[k], 5.0, 0.0)
	# A referee's table with a bell on the near side line.
	box(Vector3(1.6, 0.74, 0.7), Vector3(-9.6, 0.37, 5.2), mat(Color(0.86, 0.84, 0.8), 0.6), false)
	cyl(0.12, 0.16, 0.14, Vector3(-9.6, 0.82, 5.2), mat(Color(0.9, 0.74, 0.3), 0.3, 0.8), null, 12)


func _dome_extras() -> void:
	# Camera crews and floor lights along the sidelines, crash barriers behind them.
	var steel := mat(Color(0.5, 0.55, 0.65), 0.35, 0.8)
	for sx: float in [-1.0, 1.0]:
		for k in 5:
			var z := -4.2 + k * 2.1
			box(Vector3(0.12, 0.9, 1.9), Vector3(sx * 8.9, 0.45, z), steel, false)
			box(Vector3(0.14, 0.2, 1.9), Vector3(sx * 8.9, 0.75, z), glow_mat(theme["accent"], 1.2), false)
		for k in 3:
			var at := Vector3(sx * 7.9, 0, -3.0 + k * 3.0)
			cyl(0.2, 0.26, 0.16, at + Vector3(0, 0.08, 0), mat(Color(0.12, 0.13, 0.16), 0.4, 0.6), null, 12)
			cyl(0.16, 0.16, 0.03, at + Vector3(0, 0.17, 0), glow_mat(Color(0.85, 0.93, 1.0), 3.0), null, 12)
		_fan_row(Vector3(sx * 10.0, 0, -4.0), Vector3(sx * 10.0, 0, 4.0), 9, 31)


func _rooftop_extras() -> void:
	# Air units, a water tank, vents and cables: the clutter of a real roof, off to the sides.
	var metal := mat(Color(0.55, 0.57, 0.62), 0.4, 0.6)
	var dark := mat(Color(0.16, 0.16, 0.19), 0.6)
	for e in [[Vector3(-9.2, 0, -2.8), 1.5], [Vector3(-9.6, 0, 1.4), 1.2], [Vector3(9.4, 0, 2.6), 1.5], [Vector3(9.0, 0, -1.2), 1.1]]:
		var at: Vector3 = e[0]
		var sz: float = e[1]
		box(Vector3(sz, 0.9, sz * 0.8), at + Vector3(0, 0.45, 0), metal, false)
		cyl(sz * 0.3, sz * 0.3, 0.05, at + Vector3(0, 0.92, 0), dark, null, 14)
		for k in 4:
			box(Vector3(sz * 0.56, 0.02, 0.05), at + Vector3(0, 0.95, 0), metal, false).rotation.y = k * PI / 4.0
	for sx: float in [-1.0, 1.0]:
		var pipe := cyl(0.09, 0.09, 9.0, Vector3(sx * 8.1, 0.14, 0), mat(Color(0.5, 0.3, 0.2), 0.6, 0.4), null, 8)
		pipe.rotation.x = PI / 2.0
	cyl(1.3, 1.3, 2.2, Vector3(-11.8, 2.3, -6.0), mat(Color(0.45, 0.32, 0.22), 0.9), null, 14)
	cyl(0.0, 1.4, 0.7, Vector3(-11.8, 3.75, -6.0), mat(Color(0.3, 0.22, 0.16), 0.9), null, 14)
	for lx in [-0.8, 0.8]:
		for lz in [-0.8, 0.8]:
			cyl(0.07, 0.07, 1.2, Vector3(-11.8 + lx, 0.6, -6.0 + lz), dark, null, 6)
	_fan_row(Vector3(-8.6, 0, 5.6), Vector3(-11.5, 0, 3.0), 4, 41)
	_fan_row(Vector3(8.6, 0, -5.6), Vector3(11.5, 0, -3.4), 4, 42)


func _junk_extras() -> void:
	# Oil drums with fires in them, tyres, a wrecked car and a few locals on the sidelines.
	var drum := mat(Color(0.3, 0.2, 0.14), 0.7, 0.3)
	for e in [Vector3(-8.2, 0, -3.2), Vector3(8.3, 0, 3.0), Vector3(-8.6, 0, 3.8), Vector3(8.0, 0, -3.9)]:
		cyl(0.32, 0.32, 0.9, e + Vector3(0, 0.45, 0), drum, null, 12)
		cyl(0.26, 0.26, 0.04, e + Vector3(0, 0.9, 0), glow_mat(Color(1.0, 0.5, 0.12), 4.0), null, 12)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.55, 0.2)
		l.light_energy = 2.2
		l.omni_range = 5.0
		l.position = e + Vector3(0, 1.3, 0)
		add_child(l)
	var rubber := mat(Color(0.06, 0.06, 0.07), 0.9)
	for e in [[Vector3(-9.4, 0, 0.4), 3], [Vector3(9.3, 0, -0.6), 4], [Vector3(-7.6, 0, 5.4), 2]]:
		for k in int(e[1]):
			var tyre := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 0.2
			tm.outer_radius = 0.42
			tyre.mesh = tm
			tyre.material_override = rubber
			tyre.position = (e[0] as Vector3) + Vector3(sin(k * 2.1) * 0.08, 0.11 + k * 0.21, cos(k * 1.3) * 0.08)
			add_child(tyre)
	var wreck := prop("sedan", Vector3(10.6, 0, 3.6), 2.3, 4.2)
	if wreck:
		wreck.rotation.z = 0.06
	_fan_row(Vector3(-10.4, 0, -2.4), Vector3(-10.0, 0, 2.6), 5, 51)
	_fan_row(Vector3(10.2, 0, -3.0), Vector3(10.6, 0, 0.8), 4, 52)


# ------------------------------------------------------------------ new places

## The lawn on the cliff beside the red dorm, at sunset: the plank dorm behind, the sea below,
## the volcano on the horizon, students watching from the grass.
func _reddorm() -> void:
	_land(Vector2(70, 64), Vector3(-6, -0.03, 2), 0.0)
	# The headland drops away on the far side and the right: rock, then the sea.
	var rock_m := surf("rock", Color(0.44, 0.36, 0.3))
	box(Vector3(70, 14, 2.0), Vector3(-6, -7.05, -29.2), rock_m, false)
	box(Vector3(2.0, 14, 64), Vector3(28.2, -7.05, 2), rock_m, false)
	box(Vector3(70, 14, 2.0), Vector3(-6, -7.05, 33.2), rock_m, false)
	box(Vector3(2.0, 14, 64), Vector3(-40.2, -7.05, 2), rock_m, false)
	for i in 14:
		rock(Vector3(-36.0 + i * 5.0, -1.2, -29.5 + sin(i * 2.3) * 1.2), Vector3(6.5, 4.5 + (i % 3), 5.0), rock_m, 70 + i, i * 0.9)
		rock(Vector3(28.6 + sin(i * 1.7), -1.4, -28.0 + i * 4.6), Vector3(5.0, 4.0 + (i % 2) * 1.5, 6.5), rock_m, 90 + i, i * 0.6)
	var sea := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1400, 1400)
	sea.mesh = pm
	var wm := water_material(-4000.0)
	wm.set_shader_parameter("deep", Color(0.1, 0.22, 0.42))
	wm.set_shader_parameter("shallow", Color(0.6, 0.45, 0.4))
	sea.material_override = wm
	sea.position = Vector3(0, -12.0, 0)
	add_child(sea)
	# The dorm, up on the left behind the far duelist, lamps lit.
	plank_dorm(Vector3(-17.0, 0, -17.5), 0.5, Color("c8322a"), false)
	for k in 3:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.8, 0.5)
		l.light_energy = 2.4
		l.omni_range = 7.0
		l.position = Vector3(-19.0 + k * 3.4, 4.6, -13.0 - k * 1.8)
		add_child(l)
	# The volcano, far off across the water, and the lighthouse on the point.
	var cone := cyl(10.0, 62.0, 46.0, Vector3(60, 10, -210), surf("rock", Color(0.3, 0.22, 0.24)), null, 22)
	cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cyl(9.0, 9.0, 0.6, Vector3(60, 33.2, -210), glow_mat(Color(1.0, 0.4, 0.12), 3.0), null, 14)
	prop("lighthouse", Vector3(22.0, 0, -24.0), 0.0, 17.0, true)
	# Trees, a fence along the cliff edge, bunting from the dorm to a pole.
	for p in [Vector3(-13, 0, 9), Vector3(13.5, 0, -11), Vector3(-24, 0, 4), Vector3(17, 0, 10), Vector3(-30, 0, -8), Vector3(6, 0, -22)]:
		prop("sakura" if int(p.x) % 2 == 0 else "tree", p, p.x, 6.0, true)
	var wood := surf("wood", Color(0.42, 0.3, 0.2))
	for i in 26:
		var fx := -36.0 + i * 2.5
		box(Vector3(0.14, 1.1, 0.14), Vector3(fx, 0.55, -27.6), wood, false)
		box(Vector3(2.5, 0.1, 0.08), Vector3(fx + 1.25, 0.9, -27.6), wood, false)
		box(Vector3(2.5, 0.1, 0.08), Vector3(fx + 1.25, 0.5, -27.6), wood, false)
	for i in 22:
		var fz := -27.6 + i * 2.6
		box(Vector3(0.14, 1.1, 0.14), Vector3(26.6, 0.55, fz), wood, false)
		box(Vector3(0.08, 0.1, 2.6), Vector3(26.6, 0.9, fz + 1.3), wood, false)
	var reds := [Color("d9342b"), Color("fff0d8"), Color("f2a23a")]
	cyl(0.06, 0.08, 4.6, Vector3(8.6, 2.3, -6.4), wood, null, 8)
	cyl(0.06, 0.08, 4.6, Vector3(-8.6, 2.3, -6.4), wood, null, 8)
	_bunting(Vector3(-8.6, 4.5, -6.4), Vector3(8.6, 4.5, -6.4), reds, 22)
	_flag(Vector3(-8.2, 0, 4.6), Color("c8322a"), 4.4, 0.4)
	_flag(Vector3(8.2, 0, -4.6), Color("c8322a"), 4.4, PI + 0.4)
	# Students on picnic rugs and a bench, watching.
	theme["crowd"] = [Color("c8322a"), Color("d9483a"), Color("e8e8ee"), Color("b02822"), Color("f2c230"), Color("2f6fe0")]
	for e in [[Vector3(-8.6, 0, -1.6), Color("f2e8d0")], [Vector3(8.8, 0, 1.4), Color("e85a4a")], [Vector3(-9.2, 0, 2.6), Color("7ab8e8")]]:
		var at: Vector3 = e[0]
		var rug := box(Vector3(1.9, 0.02, 2.5), at + Vector3(0, 0.012, 0), mat(e[1], 0.95), false)
		rug.rotation.y = 0.2 * signf(at.x)
		_fan_row(at + Vector3(0, -0.5, -0.9), at + Vector3(0, -0.5, 0.9), 3, int(at.z * 10.0) + 60)
	box(Vector3(0.5, 0.45, 2.6), Vector3(9.4, 0.22, -2.6), wood, false)
	_fan_row(Vector3(9.4, 0.42, -3.6), Vector3(9.4, 0.42, -1.6), 3, 66)
	theme.erase("crowd")
	for i in 5:
		var basket := Vector3(-9.6 + (i % 2) * 18.6, 0, -0.4 + i * 0.9)
		cyl(0.18, 0.14, 0.2, basket + Vector3(0, 0.1, 0), surf("wood", Color(0.62, 0.46, 0.28)), null, 10)


## The blue dorm's great hall: marble, columns, banners, a chandelier, a rope line of
## students down each side and more up on the balcony.
func _bluehall() -> void:
	_land(Vector2(48, 44), Vector3(0, -0.03, 0), 0.0)
	var white := mat(Color(0.93, 0.94, 0.97), 0.3, 0.1)
	var gold := mat(Color(0.86, 0.7, 0.32), 0.3, 0.8)
	var blue := mat(Color("2f5fc0"), 0.75)
	var wall := surf("plaster", Color(0.86, 0.89, 0.95))
	var H := 16.0
	box(Vector3(48, H, 0.6), Vector3(0, H / 2.0, -22), wall, false)
	box(Vector3(48, H, 0.6), Vector3(0, H / 2.0, 22), wall, false)
	for sx: float in [-1.0, 1.0]:
		box(Vector3(0.6, H, 44), Vector3(sx * 24, H / 2.0, 0), wall, false)
	box(Vector3(48, 0.5, 44), Vector3(0, H + 0.25, 0), mat(Color(0.2, 0.24, 0.36), 0.9), false)
	for k in 5:
		box(Vector3(48, 0.5, 0.5), Vector3(0, H - 0.25, -18.0 + k * 9.0), gold, false)
	# Tall windows with evening light on the back wall and both sides, a banner between each.
	for k in 5:
		var wx := -16.0 + k * 8.0
		box(Vector3(3.4, 9.4, 0.2), Vector3(wx, 7.2, -21.6), gold, false)
		box(Vector3(3.0, 9.0, 0.22), Vector3(wx, 7.2, -21.58), glow_mat(Color(0.5, 0.68, 1.0), 1.3), false)
		box(Vector3(0.12, 9.0, 0.26), Vector3(wx, 7.2, -21.56), gold, false)
		for by: float in [4.4, 7.2, 10.0]:
			box(Vector3(3.0, 0.1, 0.26), Vector3(wx, by, -21.56), gold, false)
		if k < 4:
			box(Vector3(1.8, 7.5, 0.1), Vector3(wx + 4.0, 8.0, -21.5), blue, false)
			box(Vector3(2.0, 0.24, 0.16), Vector3(wx + 4.0, 11.8, -21.5), gold, false)
			box(Vector3(1.0, 1.0, 0.12), Vector3(wx + 4.0, 9.0, -21.42), gold, false).rotation.z = PI / 4.0
	for sx: float in [-1.0, 1.0]:
		for k in 4:
			var wz := -13.5 + k * 9.0
			box(Vector3(0.22, 9.0, 3.0), Vector3(sx * 23.6, 7.2, wz), glow_mat(Color(0.5, 0.68, 1.0), 1.1), false)
			box(Vector3(0.26, 9.4, 0.14), Vector3(sx * 23.56, 7.2, wz - 1.6), gold, false)
			box(Vector3(0.26, 9.4, 0.14), Vector3(sx * 23.56, 7.2, wz + 1.6), gold, false)
	# Two rows of columns.
	for sx: float in [-1.0, 1.0]:
		for k in 5:
			var cp := Vector3(sx * 12.5, 0, -16.0 + k * 8.0)
			cyl(0.62, 0.7, H, cp + Vector3(0, H / 2.0, 0), white, null, 20)
			cyl(0.95, 0.95, 0.5, cp + Vector3(0, 0.25, 0), gold, null, 20)
			cyl(1.0, 0.72, 0.7, cp + Vector3(0, H - 0.35, 0), gold, null, 20)
	# The balcony over the back, full of students.
	box(Vector3(47, 0.5, 5.0), Vector3(0, 5.2, -19.4), white, false)
	box(Vector3(47, 0.12, 0.12), Vector3(0, 6.5, -17.0), gold, false)
	for k in 48:
		cyl(0.05, 0.05, 1.0, Vector3(-23.0 + k * 0.98, 6.0, -17.0), gold, null, 6)
	theme["crowd"] = [Color("2f5fc0"), Color("3c74dc"), Color("e8ecf6"), Color("1f3f8a"), Color("f0f0f6")]
	_fan_row(Vector3(-21, 5.45, -17.8), Vector3(21, 5.45, -17.8), 40, 71)
	_fan_row(Vector3(-21, 5.45, -19.0), Vector3(21, 5.45, -19.0), 34, 72)
	# Blue runners down both sidelines, gold posts and a rope, a line of students behind.
	for sx: float in [-1.0, 1.0]:
		box(Vector3(1.5, 0.02, 12.0), Vector3(sx * 7.9, 0.012, 0), blue, false)
		box(Vector3(0.08, 0.022, 12.0), Vector3(sx * 7.2, 0.014, 0), gold, false)
		box(Vector3(0.08, 0.022, 12.0), Vector3(sx * 8.6, 0.014, 0), gold, false)
		for k in 7:
			var pp := Vector3(sx * 9.0, 0, -5.4 + k * 1.8)
			cyl(0.05, 0.05, 1.0, pp + Vector3(0, 0.5, 0), gold, null, 8)
			cyl(0.11, 0.14, 0.06, pp + Vector3(0, 0.03, 0), gold, null, 10)
			cyl(0.08, 0.08, 0.08, pp + Vector3(0, 1.02, 0), gold, null, 10)
		var rope := box(Vector3(0.05, 0.05, 10.8), Vector3(sx * 9.0, 0.88, 0), mat(Color(0.5, 0.1, 0.16), 0.8), false)
		rope.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_fan_row(Vector3(sx * 9.8, 0, -5.0), Vector3(sx * 9.8, 0, 5.0), 11, 73 + int(sx))
		_fan_row(Vector3(sx * 10.7, 0, -4.6), Vector3(sx * 10.7, 0, 4.6), 9, 75 + int(sx))
	theme.erase("crowd")
	# The chandelier.
	var ch := Vector3(0, 11.5, 0)
	cyl(0.06, 0.06, 4.5, ch + Vector3(0, 2.3, 0), gold, null, 8)
	for tier in 3:
		var r := 3.2 - tier * 0.95
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = r - 0.06
		tm.outer_radius = r + 0.06
		tm.rings = 48
		ring.mesh = tm
		ring.material_override = gold
		ring.position = ch + Vector3(0, -tier * 0.9, 0)
		add_child(ring)
		for k in 12:
			var a := k * TAU / 12.0
			var bulb := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.14
			sm.height = 0.28
			bulb.mesh = sm
			bulb.material_override = glow_mat(Color(1.0, 0.94, 0.78), 4.0)
			bulb.position = ch + Vector3(cos(a) * r, -tier * 0.9 + 0.2, sin(a) * r)
			add_child(bulb)
	var cl := OmniLight3D.new()
	cl.light_color = Color(1.0, 0.93, 0.8)
	cl.light_energy = 5.0
	cl.omni_range = 30.0
	cl.position = ch - Vector3(0, 2.0, 0)
	add_child(cl)
	for sx: float in [-1.0, 1.0]:
		var fl := OmniLight3D.new()
		fl.light_color = Color(0.75, 0.86, 1.0)
		fl.light_energy = 2.4
		fl.omni_range = 16.0
		fl.position = Vector3(sx * 14, 6, 4)
		add_child(fl)


## A closed stretch of elevated highway at night: barriers, lamps, a gantry sign, parked duel
## runners and cones on the lane, the city lit up far below on both sides.
func _highway() -> void:
	var deck := _land(Vector2(320, 21), Vector3(0, -0.03, 0), 0.0)
	deck.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var concrete := surf("concrete", Color(0.5, 0.5, 0.54))
	var steel := mat(Color(0.5, 0.53, 0.6), 0.35, 0.8)
	box(Vector3(320, 3.0, 21), Vector3(0, -1.56, 0), concrete, false)
	for sz: float in [-1.0, 1.0]:
		box(Vector3(320, 0.95, 0.5), Vector3(0, 0.47, sz * 10.3), concrete, false)
		box(Vector3(320, 0.08, 0.1), Vector3(0, 1.25, sz * 10.3), steel, false)
		box(Vector3(320, 0.06, 0.04), Vector3(0, 0.7, sz * 10.03), glow_mat(Color(1.0, 0.55, 0.12), 1.4), false)
		for k in 21:
			var lx := -150.0 + k * 15.0
			cyl(0.11, 0.15, 7.0, Vector3(lx, 3.5, sz * 10.6), steel, null, 8)
			var arm := box(Vector3(0.12, 0.12, 2.6), Vector3(lx, 6.9, sz * 9.4), steel, false)
			arm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			box(Vector3(0.5, 0.1, 0.9), Vector3(lx, 6.8, sz * 8.4), glow_mat(Color(1.0, 0.8, 0.5), 3.0), false)
			if absf(lx) < 40.0:
				var l := OmniLight3D.new()
				l.light_color = Color(1.0, 0.78, 0.48)
				l.light_energy = 2.6
				l.omni_range = 11.0
				l.position = Vector3(lx, 6.2, sz * 8.2)
				add_child(l)
		# Pillars holding the road up.
		for k in 9:
			box(Vector3(2.4, 40, 2.4), Vector3(-128.0 + k * 32.0, -23.0, sz * 6.0), concrete, false)
	# A gantry over the road behind each duelist... along the road, that is left and right.
	for sx: float in [-1.0, 1.0]:
		var gx := sx * 19.0
		for sz: float in [-1.0, 1.0]:
			cyl(0.18, 0.22, 8.4, Vector3(gx, 4.2, sz * 10.8), steel, null, 8)
		box(Vector3(0.4, 0.5, 21.6), Vector3(gx, 8.2, 0), steel, false)
		box(Vector3(0.2, 2.2, 8.0), Vector3(gx - sx * 0.2, 6.9, -3.0), mat(Color(0.05, 0.22, 0.14), 0.6), false)
		var txt := neon_sign("DUEL LANE  ·  CLOSED TO TRAFFIC", Vector3(gx - sx * 0.34, 6.9, -3.0), Color("e8fff0"), 70, -sx * PI / 2.0, false)
		txt.pixel_size = 0.011
		box(Vector3(0.2, 1.2, 1.2), Vector3(gx - sx * 0.2, 6.9, 5.4), glow_mat(Color(1.0, 0.3, 0.2), 2.4), false)
	# Cones and striped boards closing the lane, duel runners parked up, a few riders watching.
	var cone_m := mat(Color(1.0, 0.45, 0.08), 0.7)
	for sx: float in [-1.0, 1.0]:
		for k in 7:
			var cp := Vector3(sx * (7.4 + (k % 2) * 0.5), 0, -4.8 + k * 1.6)
			cyl(0.03, 0.17, 0.5, cp + Vector3(0, 0.25, 0), cone_m, null, 10)
			box(Vector3(0.4, 0.03, 0.4), cp + Vector3(0, 0.015, 0), cone_m, false)
		for k in 2:
			var bp := Vector3(sx * 12.5, 0, -4.5 + k * 9.0)
			box(Vector3(0.14, 0.9, 3.2), bp + Vector3(0, 0.75, 0), mat(Color(0.95, 0.95, 0.9), 0.6), false)
			for q in 4:
				box(Vector3(0.15, 0.3, 0.4), bp + Vector3(0, 0.75, -1.2 + q * 0.8), mat(Color(0.9, 0.2, 0.14), 0.6), false)
			for leg: float in [-1.3, 1.3]:
				box(Vector3(0.7, 0.06, 0.08), bp + Vector3(0, 0.03, leg), steel, false)
				box(Vector3(0.06, 0.75, 0.06), bp + Vector3(0, 0.38, leg), steel, false)
	for e in [[Vector3(-8.8, 0, 6.6), 0.5], [Vector3(-10.2, 0, 7.4), 0.9], [Vector3(8.9, 0, -6.6), PI + 0.5], [Vector3(10.4, 0, -7.2), PI + 0.2]]:
		prop("motorcycle", e[0], e[1], 2.3)
	_fan_row(Vector3(-9.2, 0, 4.4), Vector3(-10.4, 0, 1.6), 3, 81)
	_fan_row(Vector3(9.2, 0, -4.4), Vector3(10.4, 0, -1.8), 3, 82)
	# The city below and around: towers rising past the road on both sides.
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	for i in 70:
		var side := -1.0 if i % 2 == 0 else 1.0
		var d := rng.randf_range(24.0, 120.0)
		var x := rng.randf_range(-150.0, 150.0)
		var hgt := rng.randf_range(30.0, 95.0)
		var w := rng.randf_range(8.0, 16.0)
		building(Vector3(x, -42.0, side * d), Vector3(w, hgt, w), rng)
	var haze := OmniLight3D.new()
	haze.light_color = theme["accent2"]
	haze.light_energy = 1.2
	haze.omni_range = 40.0
	haze.position = Vector3(0, 9, 0)
	add_child(haze)


## An old wooden pier at sunset: planks over the water, mooring posts and rope, crates and
## barrels, a boat tied up, warehouses and cranes across the harbor.
func _pier() -> void:
	_land(Vector2(34, 24), Vector3(0, -0.03, 0), 0.0)
	var wood := surf("wood", Color(0.42, 0.3, 0.2))
	var dark := surf("wood", Color(0.28, 0.2, 0.14))
	box(Vector3(34, 0.5, 24), Vector3(0, -0.3, 0), dark, false)
	var sea := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1400, 1400)
	sea.mesh = pm
	var wm := water_material(-4000.0)
	wm.set_shader_parameter("deep", Color(0.12, 0.26, 0.42))
	wm.set_shader_parameter("shallow", Color(0.7, 0.5, 0.4))
	sea.material_override = wm
	sea.position = Vector3(0, -2.2, 0)
	add_child(sea)
	# Piles under the deck and mooring posts with rope along the edges.
	for ix in 8:
		for iz in 4:
			cyl(0.28, 0.3, 4.4, Vector3(-15.8 + ix * 4.5, -2.4, -10.6 + iz * 7.0), dark, null, 10)
	var rope_m := mat(Color(0.72, 0.62, 0.44), 0.9)
	for sz: float in [-1.0, 1.0]:
		for k in 12:
			var pp := Vector3(-16.4 + k * 3.0, 0, sz * 11.6)
			cyl(0.16, 0.18, 1.1, pp + Vector3(0, 0.5, 0), dark, null, 10)
			cyl(0.2, 0.2, 0.08, pp + Vector3(0, 1.08, 0), wood, null, 10)
			if k < 11:
				var r := box(Vector3(3.0, 0.06, 0.06), pp + Vector3(1.5, 0.72, 0), rope_m, false)
				r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for sx: float in [-1.0, 1.0]:
		for k in 8:
			var pp := Vector3(sx * 16.6, 0, -10.5 + k * 3.0)
			cyl(0.16, 0.18, 1.1, pp + Vector3(0, 0.5, 0), dark, null, 10)
	# Crates, barrels, nets and coiled rope along the sidelines.
	var crate := surf("wood", Color(0.6, 0.46, 0.3))
	for e in [[Vector3(-8.6, 0, -2.6), 1.0], [Vector3(-9.5, 0, -1.5), 0.8], [Vector3(-8.7, 1.0, -2.5), 0.7], [Vector3(8.8, 0, 2.4), 1.1], [Vector3(9.8, 0, 1.2), 0.8],
			[Vector3(-9.0, 0, 3.4), 0.9], [Vector3(9.2, 0, -3.6), 1.0], [Vector3(9.3, 1.0, -3.5), 0.6]]:
		var sz3: float = e[1]
		var c := box(Vector3(sz3, sz3, sz3), (e[0] as Vector3) + Vector3(0, sz3 / 2.0, 0), crate, false)
		c.rotation.y = (e[0] as Vector3).x * 0.37
	var barrel := mat(Color(0.36, 0.22, 0.14), 0.75)
	for e in [Vector3(-8.0, 0, 0.6), Vector3(-8.7, 0, 1.2), Vector3(8.2, 0, -0.8), Vector3(10.4, 0, -1.8), Vector3(8.0, 0, 4.6)]:
		cyl(0.36, 0.36, 0.95, e + Vector3(0, 0.475, 0), barrel, null, 14)
		for by: float in [0.2, 0.75]:
			cyl(0.375, 0.375, 0.05, e + Vector3(0, by, 0), mat(Color(0.3, 0.3, 0.32), 0.4, 0.7), null, 14)
	for e in [Vector3(-10.4, 0, 0.2), Vector3(10.0, 0, 3.6)]:
		for k in 3:
			var coil := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 0.28
			tm.outer_radius = 0.42
			coil.mesh = tm
			coil.material_override = rope_m
			coil.position = e + Vector3(0, 0.07 + k * 0.13, 0)
			add_child(coil)
	var net := box(Vector3(2.4, 0.03, 1.8), Vector3(-9.6, 0.02, 5.6), mat(Color(0.2, 0.36, 0.34), 0.9), false)
	net.rotation.y = 0.4
	# Lamps at the corners of the field, warm against the dusk.
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var lp := Vector3(sx * 7.6, 0, sz * 5.2)
			cyl(0.07, 0.1, 3.4, lp + Vector3(0, 1.7, 0), mat(Color(0.14, 0.15, 0.18), 0.45, 0.7), null, 8)
			box(Vector3(0.34, 0.42, 0.34), lp + Vector3(0, 3.6, 0), glow_mat(Color(1.0, 0.8, 0.5), 2.2), false)
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.76, 0.46)
			l.light_energy = 2.0
			l.omni_range = 8.0
			l.position = lp + Vector3(0, 3.4, 0)
			add_child(l)
	# A boat tied up alongside, and the far side of the harbor.
	var boat := prop("ferry", Vector3(-23.0, -2.6, -2.0), PI / 2.0 + 0.1, 15.0)
	if boat:
		_bob.append([boat, -2.6, 0.5])
	var brick := surf("brick", Color(0.5, 0.3, 0.24))
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for i in 9:
		var wx := -70.0 + i * 17.0
		var wh := rng.randf_range(8.0, 14.0)
		box(Vector3(15.0, wh, 12.0), Vector3(wx, wh / 2.0 - 2.0, -64.0), brick, false)
		var roofb := box(Vector3(15.6, 0.6, 12.6), Vector3(wx, wh - 1.7, -64.0), surf("roof", Color(0.36, 0.3, 0.3)), false)
		roofb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for k in 3:
			box(Vector3(2.2, 2.6, 0.2), Vector3(wx - 4.5 + k * 4.5, 1.0, -57.9), glow_mat(Color(1.0, 0.78, 0.45), 0.9), false)
	box(Vector3(170, 1.6, 6.0), Vector3(0, -1.8, -56.0), surf("concrete", Color(0.5, 0.48, 0.46)), false)
	var crane_m := mat(Color(0.8, 0.36, 0.14), 0.6, 0.3)
	for cx: float in [-40.0, 12.0, 52.0]:
		box(Vector3(1.4, 30, 1.4), Vector3(cx, 13.0, -55.0), crane_m, false)
		box(Vector3(1.4, 30, 1.4), Vector3(cx + 7.0, 13.0, -55.0), crane_m, false)
		box(Vector3(9.8, 1.4, 1.6), Vector3(cx + 3.5, 28.0, -55.0), crane_m, false)
		var jib := box(Vector3(1.2, 1.2, 30.0), Vector3(cx + 3.5, 29.6, -46.0), crane_m, false)
		jib.rotation.x = 0.12
	prop("lighthouse", Vector3(64.0, -2.0, -30.0), 0.0, 22.0, true)
	# Dock workers and kids watching from the crates.
	_fan_row(Vector3(-10.6, 0, -4.4), Vector3(-10.9, 0, -0.8), 4, 91)
	_fan_row(Vector3(10.6, 0, 0.2), Vector3(11.0, 0, 3.0), 3, 92)
	_fan_row(Vector3(-11.2, 0, 2.4), Vector3(-11.0, 0, 5.0), 3, 93)


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
	for h in _spin_z:
		(h as Node3D).rotation.z += delta * float((h as Node3D).get_meta("spin_z", 0.4))


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
	# Hologram projector pylons at the four corners, with light beams feeding the field.
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var at := Vector3(sx * 8.7, -0.3, sz * 6.5)
			if prop("holo_pylon", at, atan2(-at.x, -at.z), 3.6, true) == null:
				continue
			var l := OmniLight3D.new()
			l.light_color = theme["accent"] if sz > 0 else theme["accent2"]
			l.light_energy = 2.2
			l.omni_range = 7.0
			l.position = at + Vector3(0, 3.5, 0)
			add_child(l)
			var beam := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.03
			cm.bottom_radius = 0.16
			cm.height = 9.0
			cm.radial_segments = 8
			beam.mesh = cm
			var bm := StandardMaterial3D.new()
			bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			bm.albedo_color = Color(l.light_color, 0.16)
			bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			bm.cull_mode = BaseMaterial3D.CULL_DISABLED
			beam.material_override = bm
			beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			beam.position = at + Vector3(0, 3.4 + 4.5, 0)
			add_child(beam)
			_bob.append([beam, beam.position.y, 0.6 + 0.1 * (sx + sz)])
	# Stone guardians watching from both flanks.
	for sx in [-1, 1]:
		var st := prop("dragon_statue", Vector3(sx * 12.2, -0.3, 0), -sx * PI / 2, 5.4, true)
		if st:
			var up := SpotLight3D.new()
			up.light_color = Color(theme["accent"]).lerp(Color.WHITE, 0.4)
			up.light_energy = 5.0
			up.spot_range = 9.0
			up.spot_angle = 38.0
			up.position = Vector3(sx * 9.6, 0.3, 0)
			add_child(up)
			up.look_at(Vector3(sx * 12.2, 3.0, 0))


const CROWD_SH := """
shader_type spatial;
render_mode cull_back;
uniform int part = 0;            // 0 body, 1 head, 2 arms, 3 glow stick
varying vec3 lp;
varying float h;
float hash(float p) { return fract(sin(p * 78.233) * 43758.5453); }
void vertex() {
	float id = float(INSTANCE_ID);
	h = hash(id + 5.0);
	float ph = hash(id) * 6.283;
	// Some fans are calm, some never sit still, and now and then a wave goes round the stands.
	float excite = 0.5 + 0.5 * sin(TIME * 0.5 + hash(id + 2.0) * 6.283);
	float ang = atan(MODEL_MATRIX[3].x, MODEL_MATRIX[3].z);
	float wave = smoothstep(0.6, 1.0, sin(TIME * 1.1 - ang * 2.0));
	float jump = abs(sin(TIME * (3.0 + hash(id + 1.0) * 2.5) + ph)) * (0.03 + 0.16 * max(excite * excite * 0.6, wave));
	lp = VERTEX;
	if (part >= 2) {
		float up = max(wave, smoothstep(0.7, 0.95, excite));
		if (part == 3 && h < 0.72) { VERTEX *= 0.0; }
		vec3 pv = VERTEX - vec3(0.0, 0.62, 0.0);
		float a = up * (2.5 + 0.3 * sin(TIME * 7.0 + ph));
		float c = cos(a); float s = sin(a);
		pv = vec3(pv.x, pv.y * c - pv.z * s, pv.y * s + pv.z * c);
		VERTEX = pv + vec3(0.0, 0.62, 0.0);
	}
	VERTEX.y += jump;
	VERTEX.x += sin(TIME * 1.3 + ph) * 0.03;
}
void fragment() {
	vec3 col = COLOR.rgb;
	if (part == 1) {
		vec3 skin = mix(vec3(0.96, 0.8, 0.66), vec3(0.42, 0.28, 0.2), h * h);
		vec3 hair = mix(vec3(0.08, 0.06, 0.05), mix(vec3(0.55, 0.35, 0.12), vec3(0.85, 0.75, 0.4), fract(h * 7.0)), step(0.45, fract(h * 3.0)));
		float cap = smoothstep(0.76, 0.8, lp.y - lp.z * 0.35);
		col = mix(skin, hair, cap);
	} else if (part == 2) {
		col = mix(col, mix(vec3(0.96, 0.8, 0.66), vec3(0.42, 0.28, 0.2), h * h), step(lp.y, 0.34) * step(0.5, fract(h * 11.0)));
	}
	ALBEDO = col;
	ROUGHNESS = 0.85;
	if (part == 3) {
		vec3 g = fract(h * 5.0) < 0.34 ? vec3(0.2, 0.95, 1.0) : (fract(h * 5.0) < 0.67 ? vec3(1.0, 0.3, 0.75) : vec3(1.0, 0.85, 0.2));
		ALBEDO = g;
		EMISSION = g * 3.0;
	}
}
"""

const FLASH_SH := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
float hash(float p) { return fract(sin(p * 91.7) * 43758.5453); }
varying float id;
void vertex() {
	id = float(INSTANCE_ID);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	float on = step(0.985, hash(id + floor(TIME * 9.0) * 13.0));
	float d = length(UV - 0.5) * 2.0;
	float star = max(0.0, 1.0 - d) + max(0.0, 0.25 - abs(UV.x - 0.5) * abs(UV.y - 0.5) * 60.0);
	ALBEDO = vec3(1.0, 0.98, 0.9);
	ALPHA = clamp(star, 0.0, 1.0) * on;
}
"""

var _crowd_mesh: ArrayMesh


## One fan: body, head, two arms and a glow stick, each its own surface so the shader can tell
## them apart. Low-poly on purpose; there are a thousand of them.
func _fan_mesh() -> ArrayMesh:
	if _crowd_mesh:
		return _crowd_mesh
	var sh := Shader.new()
	sh.code = CROWD_SH
	var am := ArrayMesh.new()
	var parts: Array = []
	var body := CapsuleMesh.new()
	body.radius = 0.2
	body.height = 0.66
	body.radial_segments = 8
	body.rings = 2
	parts.append([[body, Transform3D(Basis.IDENTITY, Vector3(0, 0.33, 0))]])
	var head := SphereMesh.new()
	head.radius = 0.15
	head.height = 0.3
	head.radial_segments = 10
	head.rings = 5
	parts.append([[head, Transform3D(Basis.IDENTITY, Vector3(0, 0.78, 0))]])
	var arm := CapsuleMesh.new()
	arm.radius = 0.06
	arm.height = 0.42
	arm.radial_segments = 6
	arm.rings = 1
	parts.append([[arm, Transform3D(Basis.IDENTITY, Vector3(-0.26, 0.42, 0))], [arm, Transform3D(Basis.IDENTITY, Vector3(0.26, 0.42, 0))]])
	var stick := BoxMesh.new()
	stick.size = Vector3(0.045, 0.34, 0.045)
	parts.append([[stick, Transform3D(Basis.IDENTITY, Vector3(0.26, 0.06, 0))]])
	for k in parts.size():
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for piece in parts[k]:
			st.append_from(piece[0], 0, piece[1])
		st.commit(am)
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("part", k)
		am.surface_set_material(k, m)
	_crowd_mesh = am
	return am


func _crowd(center: Vector3, radius_from: float, radius_to: float, rows: int, arc_from: float, arc_to: float, base_y: float, step_h: float) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _fan_mesh()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var palette := [Color("e0533f"), Color("3f7be0"), Color("e8e8ee"), Color("2b2b33"), Color("f0c040"), Color("3fbf8a"), Color("8a4fd9"), Color("d9d2c4"), Color("26364f")]
	var spots: Array = []
	for r in rows:
		var rad := lerpf(radius_from, radius_to, float(r) / maxf(1.0, rows - 1.0))
		# Rows fill by how long they are, with the odd empty seat.
		var per_row := int(rad * absf(arc_to - arc_from) / 0.62)
		for k in per_row:
			if rng.randf() < 0.1:
				continue
			var a := lerpf(arc_from, arc_to, (k + 0.2 + rng.randf() * 0.6) / per_row)
			spots.append([a, rad, base_y + r * step_h + 0.02])
	mm.instance_count = spots.size()
	for i in spots.size():
		var a: float = spots[i][0]
		var p := center + Vector3(sin(a) * float(spots[i][1]), float(spots[i][2]), cos(a) * float(spots[i][1]))
		var sc := rng.randf_range(0.9, 1.12)
		# Facing the field; arms lift toward it.
		var bs := Basis(Vector3.UP, a + PI + rng.randf_range(-0.25, 0.25)).scaled(Vector3(sc, sc * rng.randf_range(0.92, 1.08), sc))
		mm.set_instance_transform(i, Transform3D(bs, p))
		mm.set_instance_color(i, palette[rng.randi() % palette.size()].darkened(rng.randf() * 0.35))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	# Camera flashes popping all over the stands.
	var fm := MultiMesh.new()
	fm.transform_format = MultiMesh.TRANSFORM_3D
	var q := QuadMesh.new()
	q.size = Vector2(1.5, 1.5)
	var fsh := Shader.new()
	fsh.code = FLASH_SH
	var fmat := ShaderMaterial.new()
	fmat.shader = fsh
	q.material = fmat
	fm.mesh = q
	fm.instance_count = mini(90, spots.size())
	for i in fm.instance_count:
		var sp: Array = spots[rng.randi() % spots.size()]
		fm.set_instance_transform(i, Transform3D(Basis.IDENTITY, center + Vector3(sin(float(sp[0])) * float(sp[1]), float(sp[2]) + 0.8, cos(float(sp[0])) * float(sp[1]))))
	var fmi := MultiMeshInstance3D.new()
	fmi.multimesh = fm
	fmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fmi.extra_cull_margin = 4.0
	add_child(fmi)


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


# ------------------------------------------------------------------ fields out in the world

## A low stone border around the playmat, for fields with no stage under them.
func _stone_rim(col: Color) -> void:
	var m := mat(col, 0.9)
	for side in [-1, 1]:
		box(Vector3(12.9, 0.22, 0.42), Vector3(0, 0.02, side * 4.02), m, false)
		box(Vector3(0.42, 0.22, 8.4), Vector3(side * 6.22, 0.02, 0), m, false)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			box(Vector3(0.7, 0.5, 0.7), Vector3(sx * 6.22, 0.12, sz * 4.02), mat(col.lightened(0.12), 0.85), false)


func _blob(pos: Vector3, size: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 14
	sm.rings = 7
	mi.mesh = sm
	mi.material_override = m
	mi.scale = size
	mi.position = pos
	add_child(mi)
	return mi


func _cone(pos: Vector3, r: float, h: float, m: Material, sides := 7, top := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = top
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = sides
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos + Vector3(0, h / 2.0, 0)
	add_child(mi)
	return mi


## The land around an open-air field: the same painted ground as the mat running out to the
## horizon, and what belongs in that place standing on it.
func _wild(kind: String) -> void:
	var surface := int(theme.get("surface", 1))
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(260, 260)
	ground.mesh = pm
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded;
uniform int surface = 1;
uniform vec3 haze : source_color = vec3(0.8, 0.9, 1.0);
""" + FieldThemes.GROUND_GLSL + """
void fragment() {
	vec2 p = (UV - 0.5) * 260.0;
	vec3 col = ground_color(p, surface, TIME) * 0.92;
	float far = smoothstep(26.0, 120.0, length(p));
	ALBEDO = mix(col, haze, far * 0.85);
}
"""
	var gm := ShaderMaterial.new()
	gm.shader = sh
	gm.set_shader_parameter("surface", surface)
	gm.set_shader_parameter("haze", theme["fog"])
	ground.material_override = gm
	ground.position = Vector3(0, -0.03, 0)
	add_child(ground)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77 + surface
	# Somewhere to stand: a ring of places around the field, never on it.
	var spots: Array = []
	for i in 46:
		var a := rng.randf() * TAU
		var d := rng.randf_range(13.0, 58.0)
		var p := Vector3(sin(a) * d, 0, cos(a) * d)
		if absf(p.x) < 9.5 and absf(p.z) < 10.5:
			continue
		spots.append(p)
	match kind:
		"meadow":
			_stone_rim(Color(0.62, 0.6, 0.55))
			for i in spots.size():
				var p: Vector3 = spots[i]
				if i % 3 == 0:
					_blob(p + Vector3(0, 0.25, 0), Vector3(rng.randf_range(0.8, 2.0), rng.randf_range(0.5, 1.0), rng.randf_range(0.8, 1.6)), mat(Color(0.55, 0.56, 0.58), 0.95))
				else:
					var s := rng.randf_range(0.8, 1.5)
					cyl(0.14 * s, 0.24 * s, 2.4 * s, p + Vector3(0, 1.2 * s, 0), mat(Color(0.34, 0.23, 0.14), 0.95))
					for k in 3:
						_blob(p + Vector3(rng.randf_range(-0.6, 0.6) * s, (2.7 + k * 0.6) * s, rng.randf_range(-0.6, 0.6) * s), Vector3.ONE * rng.randf_range(1.8, 2.6) * s,
								mat(Color(0.16, 0.42, 0.16).lerp(Color(0.34, 0.6, 0.2), rng.randf()), 0.95))
			for i in 9:
				var a := i * TAU / 9.0 + 0.3
				_blob(Vector3(sin(a) * 95.0, -6.0, cos(a) * 95.0), Vector3(rng.randf_range(60, 90), rng.randf_range(22, 40), rng.randf_range(50, 80)), mat(Color(0.2, 0.46, 0.2).lerp(Color(0.5, 0.7, 0.5), 0.35), 1.0))
			# A windmill on the hill behind the far duelist.
			var wm := Vector3(-16.0, 0, -30.0)
			_cone(wm, 2.2, 8.0, mat(Color(0.92, 0.9, 0.84), 0.9), 10, 1.4)
			_cone(wm + Vector3(0, 8.0, 0), 1.9, 2.2, mat(Color(0.62, 0.22, 0.16), 0.8), 10)
			var hub := Node3D.new()
			hub.position = wm + Vector3(0, 7.0, 1.7)
			add_child(hub)
			for k in 4:
				var blade := box(Vector3(0.9, 5.2, 0.08), Vector3(0, 2.8, 0), mat(Color(0.95, 0.93, 0.88), 0.8), false, hub)
				blade.position = Vector3(sin(k * PI / 2.0) * 2.8, cos(k * PI / 2.0) * 2.8, 0)
				blade.rotation.z = -k * PI / 2.0
			hub.set_meta("spin_z", 0.5)
			_spin_z.append(hub)
		"volcano":
			_stone_rim(Color(0.1, 0.08, 0.08))
			var basalt := mat(Color(0.09, 0.075, 0.07), 0.95)
			for i in spots.size():
				var p: Vector3 = spots[i]
				if i % 4 == 0:
					cyl(rng.randf_range(1.0, 2.6), rng.randf_range(1.2, 3.0), 0.05, p + Vector3(0, 0.0, 0), glow_mat(Color("ff6a1a"), 2.6), null, 12)
				else:
					var h := rng.randf_range(1.2, 5.5)
					_cone(p, rng.randf_range(0.6, 1.8), h, basalt, 5 + i % 3).rotation.z = rng.randf_range(-0.2, 0.2)
			var vc := Vector3(8.0, 0, -62.0)
			_cone(vc, 30.0, 26.0, mat(Color(0.11, 0.08, 0.075), 1.0), 12, 7.0)
			cyl(6.6, 6.6, 0.3, vc + Vector3(0, 25.9, 0), glow_mat(Color("ff7a1a"), 4.0), null, 12)
			for k in 3:
				box(Vector3(1.6 - k * 0.3, 14.0, 0.3), vc + Vector3(-5.0 + k * 5.0, 17.0 - k * 2.0, 22.0 - k * 2.5), glow_mat(Color("ff5a10"), 3.0), false).rotation.x = -0.72
			_cone(Vector3(-52.0, 0, -44.0), 18.0, 14.0, mat(Color(0.1, 0.08, 0.075), 1.0), 9, 4.0)
			var glow := OmniLight3D.new()
			glow.light_color = Color("ff6a2a")
			glow.light_energy = 3.0
			glow.omni_range = 26.0
			glow.position = Vector3(0, 5.0, -8.0)
			add_child(glow)
		"peak":
			_stone_rim(Color(0.5, 0.53, 0.6))
			var stone := mat(Color(0.36, 0.38, 0.44), 0.95)
			var snow := mat(Color(0.93, 0.96, 1.0), 0.8)
			for i in spots.size():
				var p: Vector3 = spots[i]
				if i % 3 == 0:
					# A pine: three stacked cones dusted white.
					var s := rng.randf_range(0.8, 1.4)
					cyl(0.12 * s, 0.2 * s, 1.0 * s, p + Vector3(0, 0.5 * s, 0), mat(Color(0.28, 0.2, 0.14), 0.95))
					for k in 3:
						_cone(p + Vector3(0, (0.8 + k * 1.0) * s, 0), (1.3 - k * 0.32) * s, 1.6 * s, mat(Color(0.1, 0.28, 0.2).lerp(Color(0.9, 0.95, 1.0), 0.18 + k * 0.14), 0.9), 8)
				else:
					var bs := Vector3(rng.randf_range(1.0, 3.0), rng.randf_range(0.8, 2.0), rng.randf_range(1.0, 2.4))
					_blob(p + Vector3(0, bs.y * 0.3, 0), bs, stone)
					_blob(p + Vector3(0, bs.y * 0.62, 0), bs * Vector3(0.8, 0.5, 0.8), snow)
			for i in 11:
				var a := i * TAU / 11.0 + 0.2
				var d := rng.randf_range(75.0, 110.0)
				var h := rng.randf_range(34.0, 62.0)
				var at := Vector3(sin(a) * d, -6.0, cos(a) * d)
				_cone(at, h * 0.62, h, mat(Color(0.34, 0.38, 0.48), 1.0), 7)
				_cone(at + Vector3(0, h * 0.58, 0), h * 0.265, h * 0.43, snow, 7)
		"ruins":
			_stone_rim(Color(0.66, 0.58, 0.44))
			var sandstone := mat(Color(0.72, 0.62, 0.44), 0.95)
			for i in spots.size():
				var p: Vector3 = spots[i]
				match i % 4:
					0:
						var h := rng.randf_range(2.0, 6.5)
						cyl(0.5, 0.56, h, p + Vector3(0, h / 2.0, 0), sandstone, null, 12)
						box(Vector3(1.4, 0.3, 1.4), p + Vector3(0, 0.15, 0), sandstone, false)
						if h > 5.0:
							box(Vector3(1.5, 0.4, 1.5), p + Vector3(0, h + 0.2, 0), sandstone, false)
					1:
						var lying := cyl(0.46, 0.5, rng.randf_range(2.0, 4.0), p + Vector3(0, 0.46, 0), sandstone, null, 12)
						lying.rotation = Vector3(PI / 2.0, rng.randf() * TAU, 0)
					2:
						_blob(p + Vector3(0, 0.1, 0), Vector3(rng.randf_range(4.0, 9.0), rng.randf_range(0.8, 1.8), rng.randf_range(3.0, 7.0)), mat(Color(0.8, 0.68, 0.44), 1.0))
					3:
						box(Vector3(rng.randf_range(1.0, 2.2), rng.randf_range(0.6, 1.6), rng.randf_range(1.0, 2.0)), p + Vector3(0, 0.4, 0), sandstone, false).rotation.y = rng.randf() * TAU
			# A gate behind the far duelist and pyramids on the horizon.
			for sx: float in [-1.0, 1.0]:
				cyl(0.8, 0.9, 9.0, Vector3(sx * 4.6, 4.5, -15.0), sandstone, null, 12)
			box(Vector3(12.0, 1.3, 2.0), Vector3(0, 9.6, -15.0), sandstone, false)
			for py in [[Vector3(-40, 0, -70), 30.0], [Vector3(26, 0, -86), 40.0], [Vector3(70, 0, -40), 22.0]]:
				_cone(py[0], float(py[1]), float(py[1]) * 0.78, mat(Color(0.78, 0.66, 0.44), 1.0), 4).rotation.y = PI / 4.0
		"tide":
			# The field sits on a stone slab in knee-deep water.
			box(Vector3(14.6, 0.5, 9.6), Vector3(0, -0.29, 0), mat(Color(0.6, 0.62, 0.6), 0.9), false)
			_stone_rim(Color(0.7, 0.72, 0.7))
			for i in spots.size():
				var p: Vector3 = spots[i]
				if i % 3 == 0:
					# A palm: a leaning trunk and a fan of leaves.
					var lean := rng.randf_range(-0.2, 0.2)
					var h := rng.randf_range(4.0, 6.5)
					_blob(p + Vector3(0, -0.2, 0), Vector3(5.0, 0.9, 5.0), mat(Color(0.86, 0.78, 0.56), 1.0))
					var trunk := cyl(0.14, 0.24, h, p + Vector3(0, h / 2.0, 0), mat(Color(0.5, 0.38, 0.24), 0.95), null, 8)
					trunk.rotation.z = lean
					var top := p + Vector3(-sin(lean) * h * 0.5, h * 0.98, 0)
					for k in 7:
						var leaf := box(Vector3(2.6, 0.06, 0.6), top, mat(Color(0.16, 0.5, 0.22), 0.9), false)
						leaf.rotation = Vector3(0, k * TAU / 7.0, -0.45)
						leaf.position += Vector3(cos(-k * TAU / 7.0), -0.25, sin(-k * TAU / 7.0)) * 1.1
				else:
					_blob(p + Vector3(0, 0.0, 0), Vector3(rng.randf_range(1.0, 3.2), rng.randf_range(0.8, 2.2), rng.randf_range(1.0, 2.6)), mat(Color(0.42, 0.44, 0.46), 0.95))
			for i in 6:
				var a := i * TAU / 6.0 + 0.5
				_blob(Vector3(sin(a) * 100.0, -4.0, cos(a) * 100.0), Vector3(rng.randf_range(40, 70), rng.randf_range(14, 26), rng.randf_range(30, 50)), mat(Color(0.2, 0.5, 0.28), 1.0))


var _spin_z: Array = []


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
