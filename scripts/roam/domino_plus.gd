class_name DominoPlus
## The rest of Domino City: the four avenues now lead somewhere. North to KaibaCorp Plaza,
## south past the Clock Tower to the harbor and Domino Pier, west to the Duel Dome forecourt
## and east to the Domino High gate. Built on top of CityBuilder's downtown crossroads.

const PLAZA := Vector3(0, 0, -45.5)
const HARBOR := Vector3(0, 0, 56)
const PIER_END := Vector3(0, 0, 90)


static func build(city: CityBuilder) -> void:
	_walls(city)
	_plaza(city)
	_harbor(city)
	_forecourts(city)


static func _wall(city: CityBuilder, size: Vector3, pos: Vector3) -> void:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0, 0, 0, 0)
	city.box(size, pos, m).visible = false


## The edge of the walkable city: the old square, open where the avenues leave it.
static func _walls(city: CityBuilder) -> void:
	for s: float in [-1.0, 1.0]:
		for h: float in [-1.0, 1.0]:
			_wall(city, Vector3(28, 6, 1), Vector3(h * 21.0, 3, s * 34.5))
			_wall(city, Vector3(1, 6, 28), Vector3(s * 34.5, 3, h * 21.0))
	# KaibaCorp Plaza.
	for s: float in [-1.0, 1.0]:
		_wall(city, Vector3(1, 6, 22), Vector3(s * 28.0, 3, -45.0))
		_wall(city, Vector3(21, 6, 1), Vector3(s * 17.5, 3, -34.5))
	_wall(city, Vector3(58, 6, 1), Vector3(0, 3, -55.6))
	for s: float in [-1.0, 1.0]:
		_edge(city, Vector3(0.05, 1.5, 19.0), Vector3(s * 27.6, 0.8, -46.0))
		_edge(city, Vector3(13.0, 1.5, 0.05), Vector3(s * 21.0, 0.8, -55.3))
		_edge(city, Vector3(0.05, 1.5, 24.0), Vector3(s * 30.6, 0.8, 49.0))
		_edge(city, Vector3(0.05, 1.5, 26.0), Vector3(s * 42.8, 0.8, 0))
	# Harbor and pier.
	for s: float in [-1.0, 1.0]:
		_wall(city, Vector3(1, 6, 29), Vector3(s * 31.0, 3, 48.5))
		_wall(city, Vector3(24, 6, 1), Vector3(s * 19.0, 3, 34.5))
		_wall(city, Vector3(27, 6, 1), Vector3(s * 17.5, 3, 62.6))
		_wall(city, Vector3(1, 6, 30), Vector3(s * 4.2, 3, 77.5))
	_wall(city, Vector3(9, 6, 1), Vector3(0, 3, 92.6))
	# Duel Dome and Domino High forecourts.
	for s: float in [-1.0, 1.0]:
		for h: float in [-1.0, 1.0]:
			_wall(city, Vector3(9, 6, 1), Vector3(s * 39.0, 3, h * 13.0))
			_wall(city, Vector3(1, 6, 7), Vector3(s * 34.5, 3, h * 9.5))
		_wall(city, Vector3(1, 6, 27), Vector3(s * 43.2, 3, 0))


## A low line of light where the city stops, so the edge of each new area is plain to see.
static func _edge(city: CityBuilder, size: Vector3, pos: Vector3) -> void:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(0.3, 0.75, 1.0, 0.16)
	var wall := city.box(size, pos, m, false)
	wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var top := Vector3(size.x, 0.06, size.z)
	if size.x < size.z:
		top.x = 0.08
	else:
		top.z = 0.08
	city.box(top, pos + Vector3(0, size.y / 2.0, 0), city.glow_mat(Color("7cc4ff"), 2.4), false)
	city.box(top, pos + Vector3(0, -size.y / 2.0 + 0.05, 0), city.glow_mat(Color("7cc4ff"), 1.4), false)


## A shipping container: ribbed sides, a frame and doors on one end.
static func _container(city: CityBuilder, at: Vector3, col: Color) -> void:
	city.box(Vector3(5.6, 2.4, 2.4), at, city.mat(col, 0.6, 0.3))
	var rib := city.mat(col.darkened(0.18), 0.6, 0.3)
	for i in 13:
		for sz: float in [-1.0, 1.0]:
			city.box(Vector3(0.14, 2.2, 0.06), at + Vector3(-2.52 + i * 0.42, 0, sz * 1.22), rib, false)
	var frame := city.mat(col.darkened(0.4), 0.5, 0.4)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			city.box(Vector3(0.16, 2.44, 0.16), at + Vector3(sx * 2.76, 0, sz * 1.16), frame, false)
	city.box(Vector3(0.06, 2.1, 0.06), at + Vector3(2.83, 0, 0), frame, false)
	for sz: float in [-0.5, 0.5]:
		city.box(Vector3(0.05, 1.7, 0.05), at + Vector3(2.84, 0, sz), city.mat(Color(0.75, 0.76, 0.8), 0.4, 0.7), false)


static func _lamp(city: CityBuilder, at: Vector3, color := Color(1.0, 0.9, 0.72)) -> void:
	var post := city.prop("street_lamp", at, 0.0, 5.0, true)
	if post == null:
		city.cyl(0.07, 0.1, 4.6, at + Vector3(0, 2.3, 0), city.mat(Color(0.14, 0.15, 0.18), 0.5))
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = 2.4
	l.omni_range = 11.0
	l.shadow_enabled = false
	l.position = at + Vector3(0, 4.5, 0)
	city.add_child(l)


static func _plaza(city: CityBuilder) -> void:
	# An open square from the end of the avenue (z -36.5) to the tower doors (z -55).
	var tile := city._tile_material(Color(0.5, 0.54, 0.62), 1.6)
	city.box(Vector3(56, 0.06, 20), PLAZA + Vector3(0, 0.03, -0.5), tile, false)
	city.box(Vector3(160, 0.2, 40), Vector3(0, -0.1, -89), city.mat(Color(0.07, 0.08, 0.11), 0.9), false)
	# A blue inlay running from the avenue to the tower doors, with the KC ring in the middle.
	city.box(Vector3(5.0, 0.02, 20), PLAZA + Vector3(0, 0.07, -0.5), city.glow_mat(Color("1d4fd0"), 0.25), false)
	for rr: Array in [[5.2, 5.4, 0.9], [3.9, 3.98, 0.6]]:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = rr[0]
		tm.outer_radius = rr[1]
		tm.rings = 64
		ring.mesh = tm
		ring.material_override = city.glow_mat(Color("7cc4ff"), rr[2])
		ring.scale = Vector3(1, 0.04, 1)
		ring.position = PLAZA + Vector3(0, 0.09, 0)
		city.add_child(ring)
	for s: float in [-1.0, 1.0]:
		city.box(Vector3(0.12, 0.03, 20), PLAZA + Vector3(s * 2.6, 0.075, -0.5), city.glow_mat(Color("7cc4ff"), 0.9), false)
		# White dragons guard the doors.
		var statue := city.prop("dragon_statue", PLAZA + Vector3(s * 9.5, 0, 1.6), -s * 0.5, 4.8, true)
		if statue:
			city.collide(statue, 0.6)
			var up := SpotLight3D.new()
			up.light_color = Color("9fd0ff")
			up.light_energy = 9.0
			up.spot_range = 9.0
			up.spot_angle = 40.0
			up.position = PLAZA + Vector3(s * 9.5, 0.3, 4.0)
			city.add_child(up)
			up.look_at(PLAZA + Vector3(s * 9.5, 3.0, 1.6), Vector3.UP)
		# Holo pylons showing the tournament.
		var py := city.prop("holo_pylon", PLAZA + Vector3(s * 13.5, 0, 4.5), 0.0, 4.4, true)
		if py:
			city.collide(py, 0.5)
		# Flags along the tower front.
		for k in 3:
			var fx := s * (15.0 + k * 4.0)
			city.cyl(0.05, 0.05, 6.4, PLAZA + Vector3(fx, 3.2, -9.0), city.mat(Color(0.8, 0.82, 0.86), 0.3, 0.8))
			city.box(Vector3(1.5, 0.9, 0.04), PLAZA + Vector3(fx + 0.8, 5.7, -9.0), city.glow_mat([Color("2a6cff"), Color("f2f2f2"), Color("d9342b")][k], 0.7), false)
		for k in 2:
			var bench := city.prop("bench", PLAZA + Vector3(s * (11.0 + k * 8.0), 0, 7.6), PI, 2.0)
			if bench:
				city.collide(bench, 0.8)
		_lamp(city, PLAZA + Vector3(s * 5.0, 0, 7.0), Color("cfe4ff"))
		_lamp(city, PLAZA + Vector3(s * 24.5, 0, -1.0), Color("cfe4ff"))
		_lamp(city, PLAZA + Vector3(s * 5.0, 0, -5.4), Color("cfe4ff"))
		city.tree(PLAZA + Vector3(s * 25.5, 0, 6.6), 1.1)
		city.tree(PLAZA + Vector3(s * 25.5, 0, -7.0), 1.1)
	var fountain := city.prop("fountain", PLAZA + Vector3(-17.5, 0, -1.5), 0.0, 5.6)
	if fountain:
		city.collide(fountain, 0.85)
	var stage := city.prop("duel_stage", PLAZA + Vector3(17.5, 0, -1.8), 0.0, 6.5)
	if stage:
		city.collide(stage, 0.8)
	city.neon_sign("BATTLE CITY", PLAZA + Vector3(17.5, 5.4, -1.8), Color("ffd166"), 120, 0.0, false)
	city.neon_sign("FINALS REGISTRATION", PLAZA + Vector3(17.5, 4.5, -1.8), Color("f2f6ff"), 60, 0.0, false)


static func _harbor(city: CityBuilder) -> void:
	var tile := city._tile_material(Color(0.56, 0.5, 0.44), 1.3)
	city.box(Vector3(62, 0.06, 26), Vector3(0, 0.03, 49.5), tile, false)
	# The water, right up against the quay.
	var sea := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded;
varying vec3 wp;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float n = noise(wp.xz * 0.35 + vec2(TIME * 0.25, TIME * 0.12)) * 0.6 + noise(wp.xz * 1.3 - vec2(TIME * 0.4, 0.0)) * 0.4;
	vec3 deep = vec3(0.03, 0.13, 0.24);
	vec3 lit = vec3(0.16, 0.5, 0.68);
	float glint = smoothstep(0.72, 0.8, n);
	ALBEDO = mix(deep, lit, n * 0.6) + glint * vec3(0.5, 0.6, 0.7);
}
"""
	sea.shader = sh
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(420, 220)
	water.mesh = pm
	water.material_override = sea
	water.position = Vector3(0, 0.12, 62.6 + 110.0)
	city.add_child(water)
	# Quay wall, railing and bollards.
	var stone := city.mat(Color(0.38, 0.38, 0.42), 0.9)
	var rail := city.mat(Color(0.86, 0.88, 0.9), 0.35, 0.7)
	for s: float in [-1.0, 1.0]:
		city.box(Vector3(27, 0.5, 0.6), Vector3(s * 17.5, 0.25, 62.3), stone, false)
		city.box(Vector3(27, 0.06, 0.06), Vector3(s * 17.5, 1.05, 62.3), rail, false)
		for k in 10:
			city.cyl(0.04, 0.04, 1.0, Vector3(s * (4.6 + k * 2.9), 0.55, 62.3), rail)
		for k in 4:
			city.cyl(0.22, 0.28, 0.5, Vector3(s * (7.0 + k * 6.5), 0.25, 60.6), city.mat(Color(0.12, 0.12, 0.14), 0.6))
		_lamp(city, Vector3(s * 9.0, 0, 60.4))
		_lamp(city, Vector3(s * 24.0, 0, 60.4))
		_lamp(city, Vector3(s * 26.0, 0, 44.0))
		for k in 2:
			var bench := city.prop("bench", Vector3(s * (14.0 + k * 6.0), 0, 59.2), 0.0, 2.0)
			if bench:
				city.collide(bench, 0.8)
		city.tree(Vector3(s * 27.5, 0, 52.0), 1.2)
		city.tree(Vector3(s * 12.0, 0, 40.0), 1.0)
	# Warehouses and stacked containers on the west side, a food stall and vending on the east.
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for k in 3:
		var col: Color = [Color("c2452f"), Color("2f6fb0"), Color("d9a13a")][k]
		_container(city, Vector3(-22.0 + k * 0.4, 1.2, 43.0 + k * 2.7), col)
		if k < 2:
			_container(city, Vector3(-21.6, 3.6, 43.6 + k * 2.7), col.darkened(0.25))
	var stall := city.prop("food_stall", Vector3(21.5, 0, 45.5), -PI / 2, 4.2)
	if stall:
		city.collide(stall, 0.85)
	var vend := city.prop("vending", Vector3(25.5, 0, 55.5), -PI / 2, 2.0, true)
	if vend:
		city.collide(vend, 0.9)
	# The pier: planks, posts, rope rails, lamps, and a sign over the entrance.
	var plank := city.mat(Color(0.47, 0.33, 0.2), 0.85)
	var dark := city.mat(Color(0.26, 0.18, 0.11), 0.9)
	city.box(Vector3(7.6, 0.1, 30.5), Vector3(0, 0.15, 77.6), plank, false)
	# Something solid to stand on: the city's ground stops at the quay.
	city.box(Vector3(9.0, 0.4, 32.0), Vector3(0, -0.2, 77.6), dark)
	for k in 31:
		city.box(Vector3(7.6, 0.012, 0.05), Vector3(0, 0.205, 62.8 + k * 1.0), dark, false)
	for s: float in [-1.0, 1.0]:
		for k in 8:
			var pz := 63.5 + k * 4.0
			city.cyl(0.14, 0.16, 1.5, Vector3(s * 3.75, 0.75, pz), dark)
			if k < 7:
				city.box(Vector3(0.05, 0.05, 4.0), Vector3(s * 3.75, 1.05, pz + 2.0), city.mat(Color(0.8, 0.72, 0.5), 0.9), false)
		_lamp(city, Vector3(s * 3.4, 0, 70.0))
		_lamp(city, Vector3(s * 3.4, 0, 84.0))
	for s: float in [-1.0, 1.0]:
		city.cyl(0.16, 0.18, 5.0, Vector3(s * 3.9, 2.5, 62.9), dark)
	city.box(Vector3(8.2, 0.9, 0.2), Vector3(0, 4.7, 62.9), dark, false)
	city.neon_sign("DOMINO PIER", Vector3(0, 4.7, 62.75), Color("7cf0ff"), 110, PI)
	# Boats, a lighthouse on the breakwater, a ferry out on the water.
	for b in [[-12.0, 72.0, 0.3, Color("e8e2d0")], [13.0, 79.0, -0.5, Color("d05a3a")], [-16.0, 88.0, 1.2, Color("3a78b0")]]:
		var boat := Node3D.new()
		boat.position = Vector3(b[0], 0.1, b[1])
		boat.rotation.y = b[2]
		city.add_child(boat)
		city.box(Vector3(2.2, 0.8, 5.6), Vector3(0, 0.4, 0), city.mat(b[3], 0.5), false, boat)
		city.box(Vector3(1.6, 1.0, 1.8), Vector3(0, 1.3, -0.8), city.mat(Color(0.92, 0.92, 0.9), 0.5), false, boat)
		city.cyl(0.05, 0.05, 2.6, Vector3(0, 2.4, 0.9), city.mat(Color(0.3, 0.3, 0.32), 0.5), boat)
	var lh := city.prop("lighthouse", Vector3(24.0, 0, 86.0), 0.0, 17.0, true)
	if lh:
		var beam := OmniLight3D.new()
		beam.light_color = Color(1.0, 0.95, 0.8)
		beam.light_energy = 7.0
		beam.omni_range = 34.0
		beam.position = Vector3(24.0, 15.0, 86.0)
		city.add_child(beam)
	city.box(Vector3(9, 1.2, 9), Vector3(24.0, 0.3, 86.0), stone, false)
	city.prop("ferry", Vector3(-34.0, 0.0, 104.0), 0.7, 22.0)
	city.neon_sign("DOMINO HARBOR", Vector3(-14.5, 5.6, 37.0), Color("ffd166"), 110, 0.0, false)
	city.neon_sign("FERRIES  ·  PIER  ·  FISH MARKET", Vector3(14.5, 5.6, 37.0), Color("7cf0ff"), 64, 0.0, false)


static func _forecourts(city: CityBuilder) -> void:
	var tile := city._tile_material(Color(0.46, 0.44, 0.5), 1.2)
	for s: float in [-1.0, 1.0]:
		city.box(Vector3(8.6, 0.06, 25.5), Vector3(s * 38.8, 0.03, 0), tile, false)
		for h: float in [-1.0, 1.0]:
			_lamp(city, Vector3(s * 41.5, 0, h * 10.5), Color("d9c8ff") if s < 0.0 else Color(1.0, 0.92, 0.75))
			var bench := city.prop("bench", Vector3(s * 41.6, 0, h * 5.5), -s * PI / 2, 2.0)
			if bench:
				city.collide(bench, 0.8)
	# West: the Duel Dome. Banners and a ticket booth.
	for h: float in [-1.0, 1.0]:
		city.cyl(0.07, 0.07, 7.0, Vector3(-41.8, 3.5, h * 8.0), city.mat(Color(0.8, 0.82, 0.86), 0.3, 0.8))
		city.box(Vector3(0.05, 3.6, 1.5), Vector3(-41.8, 4.8, h * 8.0 - h * 0.85), city.glow_mat(Color("b48cff"), 0.9), false)
	city.neon_sign("DUEL DOME", Vector3(-42.4, 6.4, 0), Color("b48cff"), 150, PI / 2)
	city.neon_sign("TONIGHT  ·  OPEN CHALLENGE", Vector3(-42.4, 4.9, 0), Color("ffd166"), 64, PI / 2, false)
	# East: Domino High. A gate, a notice board and cherry trees.
	var gate := city.mat(Color(0.86, 0.82, 0.74), 0.8)
	for h: float in [-1.0, 1.0]:
		city.box(Vector3(0.9, 3.2, 0.9), Vector3(42.4, 1.6, h * 3.6), gate)
		if city.has_model("sakura"):
			city.prop("sakura", Vector3(41.5, 0, h * 9.2), 0.0, 6.0, true)
		else:
			city.tree(Vector3(41.5, 0, h * 9.2), 1.1)
	city.box(Vector3(0.5, 0.5, 8.2), Vector3(42.4, 3.45, 0), gate, false)
	city.neon_sign("DOMINO HIGH", Vector3(42.0, 4.3, 0), Color("ffe9a8"), 110, -PI / 2, false)
