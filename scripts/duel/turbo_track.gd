class_name TurboTrack
extends Node3D
## The world of a Turbo Duel: a night highway that never ends, streaking past under the
## holographic field while both duelists ride their runners along it. Everything here is
## set dressing that loops; `speed` (set from the Speed Counters) drives how fast it goes.

const RUNNERS := ["res://assets/models/vehicles/runner_a.glb", "res://assets/models/vehicles/runner_b.glb"]
const SPAN := 160.0          # props wrap around inside this length of road

var speed := 26.0
var target_speed := 26.0
var accent := Color("ff8a3a")
var accent2 := Color("2de2e6")
var _road: ShaderMaterial
var _offset := 0.0
var _props: Array = []       # [node, parallax]
var _bikes: Array = []       # [holder, base position, phase]
var _trails: Array = []
var _lines: Array = []
var _t := 0.0
var _zones := {"satellite": [], "tops": [], "tunnel": [], "bridge": []}   # scenery by stretch of road
var zone := ""
var curve := 0.0             # how hard the road is bending (ride mode); swings the far scenery


func build(a: Color, b: Color) -> void:
	accent = a
	accent2 = b
	_build_backdrop()
	_build_road()
	_build_sides()
	_build_arches()
	_build_skyline()
	_build_tunnel()
	_build_bridge()
	_build_speed_lines()
	set_zone("")


## Which stretch of the highway is showing: "satellite", "tops", "tunnel", "bridge", or ""
## for the mixed skyline used in duels.
func set_zone(z: String) -> void:
	zone = z
	# A node can belong to more than one stretch (the sky, the arches): hide all, then show.
	for k in _zones:
		for n in _zones[k]:
			(n as Node3D).visible = false
	for k in _zones:
		if k == z or (z == "" and k in ["satellite", "tops"]):
			for n in _zones[k]:
				(n as Node3D).visible = true
	if _road:
		var ga := accent
		var gb := accent2
		if z == "tops":
			ga = Color("7cc4ff")
			gb = Color("f2f2f2")
		elif z == "tunnel":
			ga = Color("ffd23a")
			gb = Color("ffd23a")
		elif z == "bridge":
			ga = Color("5affd0")
			gb = Color("7cc4ff")
		_road.set_shader_parameter("glow_a", ga)
		_road.set_shader_parameter("glow_b", gb)


func _build_tunnel() -> void:
	# Ribs of light overhead and close walls.
	for i in 16:
		var rib := Node3D.new()
		_box(rib, Vector3(0.6, 0.5, 31.0), Vector3(0, 9.0, 0), _solid(Color(0.1, 0.1, 0.13)))
		_box(rib, Vector3(0.25, 0.12, 30.0), Vector3(0, 8.7, 0), _glow(Color(1.0, 0.85, 0.45), 3.5))
		for s: float in [-1.0, 1.0]:
			_box(rib, Vector3(0.6, 9.0, 0.6), Vector3(0, 4.5, s * 15.2), _solid(Color(0.1, 0.1, 0.13)))
			_box(rib, Vector3(9.6, 9.0, 0.3), Vector3(5.0, 4.5, s * 15.6), _solid(Color(0.06, 0.065, 0.085)))
			_box(rib, Vector3(9.6, 0.2, 0.1), Vector3(5.0, 2.2, s * 15.4), _glow(Color(1.0, 0.85, 0.45), 2.0))
		_box(rib, Vector3(9.6, 0.3, 31.0), Vector3(5.0, 9.4, 0), _solid(Color(0.05, 0.055, 0.075)))
		_prop(rib, -SPAN / 2.0 + i * (SPAN / 16.0))
		_zones["tunnel"].append(rib)


func _build_bridge() -> void:
	# Open water on both sides, suspension towers and cables going by.
	var water := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	water.mesh = pm
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(0.02, 0.07, 0.13)
	wm.roughness = 0.05
	wm.metallic = 0.6
	water.material_override = wm
	water.position = Vector3(0, -6.0, 0)
	add_child(water)
	_zones["bridge"].append(water)
	for i in 4:
		var tower := Node3D.new()
		for s: float in [-1.0, 1.0]:
			_box(tower, Vector3(1.6, 34.0, 1.6), Vector3(0, 13.0, s * 15.6), _solid(Color(0.75, 0.78, 0.84)))
			_box(tower, Vector3(0.3, 30.0, 0.3), Vector3(0.9, 13.0, s * 15.6), _glow(Color("5affd0"), 2.2))
			for k in 9:
				var c := _box(tower, Vector3(0.12, 26.0 - k * 2.4, 0.12), Vector3(-18.0 + k * 4.4, 13.0 - k * 1.2 + 1.0, s * 15.6), _solid(Color(0.8, 0.82, 0.86)))
				c.rotation.z = 0.0
		_box(tower, Vector3(1.6, 1.6, 32.8), Vector3(0, 29.0, 0), _solid(Color(0.75, 0.78, 0.84)))
		_prop(tower, -SPAN / 2.0 + 20.0 + i * (SPAN / 4.0))
		_zones["bridge"].append(tower)
	# A far shore of lights.
	for s: float in [-1.0, 1.0]:
		for i in 14:
			var far := Node3D.new()
			var hgt := 6.0 + float((i * 37) % 23)
			_box(far, Vector3(9.0, hgt, 6.0), Vector3(0, hgt / 2.0 - 6.0, s * (120.0 + float((i * 13) % 40))), _glow(Color(0.25, 0.4, 0.6), 0.5))
			_prop(far, -SPAN / 2.0 + i * (SPAN / 14.0), 0.05)
			_zones["bridge"].append(far)


func _build_road() -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(260, 30)
	mi.mesh = pm
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded;
uniform float offset = 0.0;
uniform float blur = 1.0;
uniform vec3 glow_a : source_color = vec3(1.0, 0.54, 0.23);
uniform vec3 glow_b : source_color = vec3(0.18, 0.89, 0.9);
varying vec3 wp;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float x = wp.x + offset;
	float z = wp.z;
	// How much road one pixel covers here: detail finer than that is faded out instead of
	// being left to shimmer, which is what made the surface crawl at speed.
	float px = max(fwidth(wp.x), fwidth(wp.z));
	float fine = 1.0 - smoothstep(0.02, 0.12, px);
	// Asphalt: grain stretched along the direction of travel, more the faster you go.
	float stretch = 0.25 / blur;
	float g1 = hash(vec2(floor(x * stretch), floor(z * 9.0)));
	float g2 = hash(vec2(floor(x * stretch * 0.31 + 7.0), floor(z * 3.0)));
	vec3 col = vec3(0.034, 0.039, 0.054) + (g1 * 0.018 + g2 * 0.012) * fine;
	// Long streaks worn into each lane by tires.
	float lane_c = abs(fract(z / 4.4 + 0.5) - 0.5) * 4.4;
	float wear = smoothstep(1.5, 0.5, abs(lane_c - 1.1)) * (0.6 + 0.4 * g2);
	col *= 1.0 - wear * 0.22;
	// Expansion joints flick past: at speed they are what tells you how fast you are going.
	float jx = fract(x / 22.0);
	float joint = (1.0 - smoothstep(0.0, 0.012 + px * 0.03, min(jx, 1.0 - jx)));
	col = mix(col, vec3(0.012, 0.014, 0.02), joint * 0.8);
	// Lane dashes: they stretch into streaks as speed builds, with soft ends so they never strobe.
	float duty = clamp(0.5 + (blur - 1.0) * 0.12, 0.5, 0.78);
	float dx = fract(x / 9.0);
	float edge = 0.03 + px * 0.25 + (blur - 1.0) * 0.05;
	float dash = smoothstep(0.0, edge, dx) * smoothstep(duty, duty - edge, dx);
	for (int i = -2; i <= 2; i++) {
		float lz = float(i) * 4.4;
		float d = abs(z - lz);
		float line = 1.0 - smoothstep(0.07, 0.11 + px, d);
		col = mix(col, vec3(0.78, 0.83, 0.93), line * dash * 0.8);
		// Cat's eyes between the dashes, lit by your headlight.
		float eye = (1.0 - smoothstep(0.03, 0.07 + px, d)) * (1.0 - smoothstep(0.0, 0.02 + px * 0.2, abs(dx - 0.86)));
		col += vec3(1.0, 0.75, 0.3) * eye * 0.9;
	}
	// Solid lines just inside the barriers, and rumble strips beyond them.
	float sl = 1.0 - smoothstep(0.06, 0.1, abs(abs(z) - 11.2));
	col = mix(col, vec3(0.8, 0.84, 0.92), sl * 0.6);
	float rum = step(0.5, fract(x / 1.6)) * (1.0 - smoothstep(0.25, 0.3, abs(abs(z) - 11.75)));
	col = mix(col, mix(glow_b, glow_a, step(0.0, z)) * 0.55, rum * 0.7);
	// Wet road: the street lamps and the neon smear into long streaks.
	float lamp = pow(max(0.0, cos((x + 4.0 * step(0.0, z)) * 6.2832 / 16.0)), 24.0);
	float lz = 1.0 - smoothstep(0.0, 5.5, abs(abs(z) - 9.6));
	col += vec3(1.0, 0.88, 0.7) * lamp * lz * 0.2;
	float sheen = hash(vec2(floor(x * 0.06), floor(z * 2.5)));
	col += mix(glow_b, glow_a, step(0.0, z)) * smoothstep(5.0, 12.4, abs(z)) * (0.05 + sheen * 0.07);
	// Glowing edges.
	float ea = 1.0 - smoothstep(0.0, 0.9, abs(z - 12.4));
	float eb = 1.0 - smoothstep(0.0, 0.9, abs(z + 12.4));
	col += glow_a * ea * 1.4 + glow_b * eb * 1.4;
	// Chevrons racing down the middle lanes.
	float chev = abs(fract((x - abs(z) * 0.8) / 14.0) - 0.5);
	float cz = 1.0 - smoothstep(6.0, 9.5, abs(z));
	col += mix(glow_b, glow_a, step(0.0, z)) * (1.0 - smoothstep(0.02, 0.06, chev)) * 0.22 * cz;
	// Hex plating under the paint, only just visible.
	vec2 hx = vec2(x * 0.5, z * 0.5);
	float hl = 1.0 - smoothstep(0.02, 0.05, min(fract(hx.x), fract(hx.y)));
	col += vec3(0.05, 0.07, 0.1) * hl * 0.5;
	// Fade into the dark far away.
	float fade = 1.0 - smoothstep(60.0, 120.0, abs(wp.x));
	ALBEDO = col * fade;
}
"""
	_road = ShaderMaterial.new()
	_road.shader = sh
	_road.set_shader_parameter("glow_a", accent)
	_road.set_shader_parameter("glow_b", accent2)
	mi.material_override = _road
	mi.position = Vector3(0, -0.08, 0)
	add_child(mi)


var _scroll: Array[ShaderMaterial] = []
var _barrier_sh: Shader


## Concrete barrier with lit panels and chevrons that slide past with the road.
func _barrier_mat(col: Color, pitch := 1.0) -> ShaderMaterial:
	if _barrier_sh == null:
		_barrier_sh = Shader.new()
		_barrier_sh.code = """
shader_type spatial;
render_mode unshaded;
uniform float offset = 0.0;
uniform float blur = 1.0;
uniform float pitch = 1.0;
uniform vec3 tint : source_color = vec3(0.2, 0.9, 0.9);
varying vec3 wp;
float hash(float p) { return fract(sin(p * 127.1) * 43758.5453); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float x = wp.x + offset;
	float px = fwidth(wp.x);
	vec3 col = vec3(0.06, 0.068, 0.09) * (0.8 + 0.2 * hash(floor(x / 6.0)));
	// Panel seams.
	float seam = fract(x / 6.0);
	col *= 1.0 - 0.5 * (1.0 - smoothstep(0.0, 0.01 + px * 0.05, min(seam, 1.0 - seam)));
	// A light slot in every panel; at speed the slots smear into one streak.
	float len = clamp(0.35 + (blur - 1.0) * 0.2, 0.35, 0.92);
	float slot_x = smoothstep(0.5 - len * 0.5 - 0.03, 0.5 - len * 0.5 + 0.03, seam) * smoothstep(0.5 + len * 0.5 + 0.03, 0.5 + len * 0.5 - 0.03, seam);
	float band = fract(wp.y * pitch * 0.9);
	float slot_y = smoothstep(0.38, 0.44, band) * smoothstep(0.62, 0.56, band);
	float on = step(0.25, hash(floor(x / 6.0) + 9.0));
	col += tint * slot_x * slot_y * on * 1.6;
	// Chevrons on the lowest band.
	float ch = abs(fract((x + abs(wp.y - 0.45) * 1.2) / 3.0) - 0.5);
	col += tint * (1.0 - smoothstep(0.03, 0.09 + px * 0.2, ch)) * step(wp.y, 0.9) * 0.35;
	float fade = 1.0 - smoothstep(60.0, 120.0, abs(wp.x));
	ALBEDO = col * fade;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _barrier_sh
	m.set_shader_parameter("tint", col)
	m.set_shader_parameter("pitch", pitch)
	_scroll.append(m)
	return m


func _glow(color: Color, energy := 2.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


func _solid(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.6
	m.metallic = 0.3
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _prop(node: Node3D, x: float, parallax := 1.0) -> void:
	node.position.x = x
	add_child(node)
	_props.append([node, parallax])


func _build_sides() -> void:
	# Barriers with light strips, lamp arches overhead, and the odd sign gantry.
	for side in [-1.0, 1.0]:
		var col: Color = accent if side > 0.0 else accent2
		var wall := Node3D.new()
		_box(wall, Vector3(260, 1.1, 0.5), Vector3(0, 0.45, side * 14.2), _barrier_mat(col))
		_box(wall, Vector3(260, 0.08, 0.08), Vector3(0, 1.02, side * 13.92), _glow(col, 3.0))
		# A second, taller sound wall behind it with slim light slots, so the edge of the road
		# reads as a wall of streaks at speed.
		_box(wall, Vector3(260, 3.2, 0.3), Vector3(0, 2.6, side * 15.4), _barrier_mat(col.lerp(Color.WHITE, 0.3), 2.0))
		add_child(wall)
		for i in 10:
			var post := Node3D.new()
			_box(post, Vector3(0.3, 7.0, 0.3), Vector3(0, 3.5, side * 14.6), _solid(Color(0.1, 0.11, 0.15)))
			_box(post, Vector3(0.25, 0.25, 3.4), Vector3(0, 6.9, side * 13.0), _solid(Color(0.1, 0.11, 0.15)))
			_box(post, Vector3(0.5, 0.1, 1.2), Vector3(0, 6.75, side * 11.8), _glow(Color(1.0, 0.95, 0.82), 4.0))
			var lamp := OmniLight3D.new()
			lamp.light_color = Color(1.0, 0.9, 0.75)
			lamp.light_energy = 2.2
			lamp.omni_range = 11.0
			lamp.position = Vector3(0, 6.2, side * 11.5)
			post.add_child(lamp)
			_prop(post, -SPAN / 2.0 + i * (SPAN / 10.0) + (4.0 if side > 0.0 else 0.0))
	for i in 2:
		var gantry := Node3D.new()
		_box(gantry, Vector3(0.5, 0.6, 30.0), Vector3(0, 8.2, 0), _solid(Color(0.09, 0.1, 0.14)))
		# Overhead signs: lane arrows and a moving readout, not blank panels.
		for gs in [[-6.0, accent2], [6.0, accent]]:
			var panel := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(9.0, 1.7)
			panel.mesh = qm
			panel.material_override = _holo(gs[1], 3.0 + i * 2.0 + float(gs[0]))
			panel.rotation.y = -PI / 2.0
			panel.position = Vector3(-0.3, 7.2, float(gs[0]))
			gantry.add_child(panel)
			_box(gantry, Vector3(0.14, 1.9, 9.2), Vector3(-0.2, 7.2, float(gs[0])), _solid(Color(0.05, 0.06, 0.09)))
		_prop(gantry, -SPAN / 2.0 + 30.0 + i * (SPAN / 2.0))


func _build_skyline() -> void:
	# Towers on both sides, far enough to drift past slowly.
	var rng := RandomNumberGenerator.new()
	rng.seed = 2077
	var win := Shader.new()
	win.code = """
shader_type spatial;
render_mode unshaded;
uniform vec3 tint : source_color = vec3(1.0, 0.8, 0.5);
uniform float seed = 0.0;
uniform float height = 30.0;
uniform vec3 haze : source_color = vec3(0.6, 0.2, 0.5);
varying vec3 lp;
float hash(vec2 p) { return fract(sin(dot(p, vec2(41.3, 289.1)) + seed) * 43758.5453); }
void vertex() { lp = VERTEX; }
void fragment() {
	vec2 g = vec2(lp.x + lp.z, lp.y) * vec2(1.1, 0.75);
	vec2 cell = floor(g);
	vec2 f = fract(g);
	// Whole floors go dark, and lit rooms flicker a different warmth each.
	float floor_on = step(0.25, hash(vec2(3.0, cell.y)));
	float lit = step(0.55, hash(cell)) * floor_on;
	float w = smoothstep(0.12, 0.2, f.x) * smoothstep(0.88, 0.8, f.x) * smoothstep(0.22, 0.3, f.y) * smoothstep(0.82, 0.74, f.y);
	vec3 body = vec3(0.022, 0.026, 0.05);
	// Haze climbs the towers from the street.
	body += haze * 0.22 * (1.0 - smoothstep(-0.5, 0.2, lp.y / height));
	// A cool rim along the roof line.
	body += tint * 0.12 * smoothstep(0.46, 0.5, lp.y / height);
	ALBEDO = body + tint * lit * w * (0.35 + 0.75 * hash(cell + 7.0));
}
"""
	for side in [-1.0, 1.0]:
		for i in 22:
			var t := Node3D.new()
			var w := rng.randf_range(7.0, 16.0)
			var h := rng.randf_range(14.0, 62.0)
			var d := rng.randf_range(7.0, 14.0)
			var mat := ShaderMaterial.new()
			mat.shader = win
			mat.set_shader_parameter("seed", rng.randf() * 50.0)
			mat.set_shader_parameter("tint", [Color(1.0, 0.72, 0.4), Color(1.0, 0.5, 0.75)][rng.randi() % 2] if i % 2 == 0 else [Color(0.6, 0.88, 1.0), Color(0.95, 0.97, 1.0)][rng.randi() % 2])
			var z: float = side * rng.randf_range(26.0, 70.0)
			mat.set_shader_parameter("height", h)
			mat.set_shader_parameter("haze", accent.lerp(Color(0.7, 0.2, 0.6), 0.6) if side > 0.0 else accent2.lerp(Color(0.3, 0.2, 0.7), 0.6))
			_box(t, Vector3(w, h, d), Vector3(0, h / 2.0 - 4.0, z), mat)
			# Stepped crown, a mast with a warning light, and now and then a moving sign.
			if h > 30.0:
				_box(t, Vector3(w * 0.6, 4.0, d * 0.6), Vector3(0, h - 2.0, z), mat)
				_box(t, Vector3(0.18, 7.0, 0.18), Vector3(0, h + 3.5, z), _solid(Color(0.08, 0.09, 0.12)))
				var beacon := _box(t, Vector3(0.5, 0.5, 0.5), Vector3(0, h + 7.0, z), _glow(Color(1.0, 0.15, 0.15), 5.0))
				_beacons.append([beacon, rng.randf() * 6.0])
			if rng.randf() < 0.3 and absf(z) < 48.0:
				var sign := _box(t, Vector3(w * 0.7, rng.randf_range(5.0, 9.0), 0.2), Vector3(0, rng.randf_range(8.0, h * 0.6), z - side * (d / 2.0 + 0.2)), _holo([accent, accent2, Color("ff4fd8"), Color("7cff6a")][rng.randi() % 4], rng.randf() * 9.0))
				sign.name = "holo"
			if rng.randf() < 0.4:
				_box(t, Vector3(w * 0.9, 0.5, 0.3), Vector3(0, h - 4.0, z - side * d / 2.0), _glow([accent, accent2][rng.randi() % 2], 2.5))
			_prop(t, rng.randf_range(-SPAN / 2.0, SPAN / 2.0), 0.18 + 6.0 / absf(z))
			_zones["satellite" if i % 2 == 0 else "tops"].append(t)


var _trail_sh: Shader
var _far_off := 0.0
var _beacons: Array = []
var _beams: Array = []
var _far: Array = []
var _holo_sh: Shader


## A sign that moves: bars, sweeps and a pulse, no words on it.
func _holo(color: Color, seed: float) -> ShaderMaterial:
	if _holo_sh == null:
		_holo_sh = Shader.new()
		_holo_sh.code = """
shader_type spatial;
render_mode unshaded;
uniform vec3 tint : source_color = vec3(1.0, 0.5, 0.2);
uniform float seed = 0.0;
float hash(float p) { return fract(sin(p * 91.7 + seed) * 43758.5453); }
void fragment() {
	vec2 uv = UV;
	float t = TIME * 0.6 + seed;
	float kind = hash(1.0);
	float v = 0.0;
	if (kind < 0.34) {
		float bars = floor(uv.x * 9.0);
		v = step(1.0 - uv.y, 0.25 + 0.6 * abs(sin(t * 1.7 + bars * 1.3)));
		v *= step(0.15, fract(uv.x * 9.0));
	} else if (kind < 0.67) {
		v = smoothstep(0.04, 0.0, abs(fract(uv.y * 3.0 - t * 0.5) - 0.5) - 0.18);
		v *= 0.5 + 0.5 * step(0.5, fract(uv.x * 2.0 + floor(uv.y * 3.0 - t * 0.5) * 0.5));
	} else {
		vec2 c = uv - 0.5;
		float r = length(c * vec2(1.0, 1.4));
		v = smoothstep(0.03, 0.0, abs(fract(r * 4.0 - t) - 0.5) - 0.12) * smoothstep(0.55, 0.2, r);
	}
	float frame = max(step(uv.x, 0.03), max(step(0.97, uv.x), max(step(uv.y, 0.03), step(0.97, uv.y))));
	float scan = 0.85 + 0.15 * sin(uv.y * 240.0);
	ALBEDO = tint * (0.08 + v * 1.5 * scan + frame * 1.2);
}
"""
	var m := ShaderMaterial.new()
	m.shader = _holo_sh
	m.set_shader_parameter("tint", color)
	m.set_shader_parameter("seed", seed)
	return m


## Everything behind the towers: the night sky, a far wall of city, haze and searchlights.
func _build_backdrop() -> void:
	var dome := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 430.0
	sm.height = 860.0
	sm.radial_segments = 32
	sm.rings = 16
	dome.mesh = sm
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_front, fog_disabled;
uniform vec3 glow_a : source_color = vec3(1.0, 0.54, 0.23);
uniform vec3 glow_b : source_color = vec3(0.18, 0.89, 0.9);
varying vec3 dir;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
void vertex() { dir = normalize(VERTEX); }
void fragment() {
	vec3 d = normalize(dir);
	float h = clamp(d.y, -0.2, 1.0);
	vec3 top = vec3(0.012, 0.016, 0.05);
	vec3 mid = vec3(0.1, 0.04, 0.2);
	// The side of the sky you ride toward burns warm, the other side stays cold.
	vec3 hor = mix(glow_b * 0.55 + vec3(0.1, 0.05, 0.3), glow_a * 0.8 + vec3(0.35, 0.05, 0.25), smoothstep(-0.6, 0.8, d.x));
	vec3 col = mix(hor, mid, smoothstep(0.0, 0.22, h));
	col = mix(col, top, smoothstep(0.15, 0.7, h));
	// Stars, thinning toward the glow of the city.
	vec2 sp = d.xz / (abs(d.y) + 0.35) * 150.0;
	float st = step(0.99, hash(floor(sp))) * smoothstep(0.5, 0.2, length(fract(sp) - 0.5)) * smoothstep(0.12, 0.5, h);
	col += vec3(0.8, 0.85, 1.0) * st * (0.4 + 0.6 * hash(floor(sp) + 3.0)) * (0.7 + 0.3 * sin(TIME * 2.0 + hash(floor(sp)) * 20.0));
	// Thin cloud bands lit from below.
	float cl = noise(vec2(d.x * 3.0 + TIME * 0.01, d.y * 16.0 + d.z * 2.0)) * noise(vec2(d.z * 4.0, d.y * 9.0));
	col += hor * cl * 0.55 * smoothstep(0.02, 0.12, h) * smoothstep(0.5, 0.18, h);
	// A big pale moon.
	vec3 md = normalize(vec3(0.55, 0.34, -0.76));
	float m = dot(d, md);
	float disc = smoothstep(0.9955, 0.9965, m);
	float crater = noise(d.xy * 60.0) * 0.25;
	col = mix(col, vec3(0.92, 0.94, 1.0) * (0.85 - crater), disc);
	col += vec3(0.5, 0.6, 1.0) * pow(max(m, 0.0), 90.0) * 0.35;
	// Below the horizon it is just dark haze.
	col = mix(col, hor * 0.25, smoothstep(0.0, -0.12, d.y));
	ALBEDO = col;
}
"""
	var dm := ShaderMaterial.new()
	dm.shader = sh
	dm.set_shader_parameter("glow_a", accent)
	dm.set_shader_parameter("glow_b", accent2)
	dome.material_override = dm
	dome.extra_cull_margin = 2000.0
	add_child(dome)
	_zones["satellite"].append(dome)
	_zones["tops"].append(dome)
	_zones["bridge"].append(dome)
	# Far wall of city: a strip of rooftops cut out against the glow, sliding by very slowly.
	var far := Shader.new()
	far.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform float offset = 0.0;
uniform vec3 tint : source_color = vec3(0.5, 0.3, 0.8);
uniform float layer = 0.0;
float hash(float p) { return fract(sin(p * 127.1 + layer * 17.0) * 43758.5453); }
void fragment() {
	float x = UV.x * 90.0 + offset;
	float b = floor(x);
	float f = fract(x);
	float ht = 0.25 + 0.6 * hash(b) * hash(b + 40.0) + 0.12 * hash(floor(x * 0.25));
	float gap = step(0.06, f) * step(f, 0.94);
	float y = 1.0 - UV.y;
	float inside = step(y, ht) * gap;
	// A few lit windows.
	vec2 wc = floor(vec2(x * 6.0, y * 70.0));
	float wl = step(0.86, fract(sin(dot(wc, vec2(12.9, 78.2)) + layer) * 43758.5)) * step(0.3, fract(x * 6.0)) * step(0.4, fract(y * 70.0));
	vec3 col = tint * 0.1 + tint * wl * 0.9;
	col += tint * 0.5 * smoothstep(0.35, 0.0, y);
	ALBEDO = col;
	ALPHA = inside;
}
"""
	for side in [-1.0, 1.0]:
		for k in 2:
			var mi := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(900, 70.0 + k * 40.0)
			mi.mesh = qm
			var fm := ShaderMaterial.new()
			fm.shader = far
			fm.set_shader_parameter("layer", float(k) + (side + 1.0))
			fm.set_shader_parameter("tint", (accent if side > 0.0 else accent2).lerp(Color(0.45, 0.25, 0.8), 0.55 + k * 0.2).darkened(k * 0.25))
			mi.material_override = fm
			mi.position = Vector3(0, qm.size.y / 2.0 - 6.0, side * (95.0 + k * 45.0))
			mi.rotation.y = 0.0 if side < 0.0 else PI
			add_child(mi)
			_far.append([fm, 0.02 / (1.0 + k), side])
			for zk in ["satellite", "tops"]:
				_zones[zk].append(mi)
	# Searchlights sweeping from somewhere deep in the city.
	var beam_sh := Shader.new()
	beam_sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, fog_disabled;
uniform vec3 tint : source_color = vec3(0.6, 0.8, 1.0);
void fragment() {
	float w = 1.0 - abs(UV.x - 0.5) * 2.0;
	ALBEDO = tint;
	ALPHA = pow(w, 2.0) * (1.0 - UV.y) * UV.y * 0.6;
}
"""
	for i in 6:
		var side := -1.0 if i % 2 == 0 else 1.0
		var pivot := Node3D.new()
		pivot.position = Vector3(-90.0 + i * 36.0, 0.0, side * (78.0 + (i % 3) * 9.0))
		var bm := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(7.0, 150.0)
		bm.mesh = q
		var mat := ShaderMaterial.new()
		mat.shader = beam_sh
		mat.set_shader_parameter("tint", [accent2, Color(0.9, 0.95, 1.0), accent][i % 3])
		bm.material_override = mat
		bm.position.y = 75.0
		pivot.add_child(bm)
		add_child(pivot)
		_beams.append([pivot, randf() * 6.0, 0.25 + 0.1 * (i % 3)])
		for zk in ["satellite", "tops"]:
			_zones[zk].append(pivot)


## Light rings over the road: you ride through one every few seconds.
func _build_arches() -> void:
	for i in 4:
		var arch := Node3D.new()
		var col: Color = [accent2, accent][i % 2]
		var dark := _solid(Color(0.08, 0.09, 0.13))
		for side in [-1.0, 1.0]:
			_box(arch, Vector3(0.7, 10.5, 0.7), Vector3(0, 5.25, side * 15.2), dark)
			_box(arch, Vector3(0.12, 9.6, 0.12), Vector3(-0.42, 5.2, side * 14.8), _glow(col, 4.0))
			var slant := _box(arch, Vector3(0.6, 5.0, 0.6), Vector3(0, 11.6, side * 13.6), dark)
			slant.rotation.x = side * 0.75
			var sl := _box(arch, Vector3(0.12, 4.6, 0.12), Vector3(-0.4, 11.5, side * 13.3), _glow(col, 4.0))
			sl.rotation.x = side * 0.75
		_box(arch, Vector3(0.7, 0.7, 24.4), Vector3(0, 13.3, 0), dark)
		_box(arch, Vector3(0.12, 0.14, 23.6), Vector3(-0.42, 12.95, 0), _glow(col, 4.5))
		for k in 5:
			_box(arch, Vector3(0.3, 0.12, 1.5), Vector3(0, 12.9, -9.0 + k * 4.5), _glow(Color(1.0, 0.96, 0.86), 5.0))
		var lamp := OmniLight3D.new()
		lamp.light_color = col
		lamp.light_energy = 3.0
		lamp.omni_range = 16.0
		lamp.position = Vector3(0, 9.0, 0)
		arch.add_child(lamp)
		_prop(arch, -SPAN / 2.0 + 10.0 + i * (SPAN / 4.0))
		for zk in ["satellite", "tops"]:
			_zones[zk].append(arch)


func _build_speed_lines() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 46:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(rng.randf_range(2.0, 7.0), 0.02, 0.03)
		mi.mesh = bm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_color = Color(0.8, 0.9, 1.0, rng.randf_range(0.08, 0.3))
		mi.material_override = m
		mi.position = Vector3(rng.randf_range(-40, 40), rng.randf_range(0.15, 4.5), rng.randf_range(-13.0, 13.0))
		add_child(mi)
		_lines.append([mi, rng.randf_range(1.3, 2.4)])


## A runner with its rider. `at` is where it rides; it faces +X (the way the road goes).
func add_rider(index: int, key: String, at: Vector3, color: Color) -> RoamFigure:
	var holder := Node3D.new()
	holder.position = at
	add_child(holder)
	var ps = load(RUNNERS[index % RUNNERS.size()])
	var own_bike := CityBuilder.own_instance(["runner_a", "runner_b"][index % 2])
	if own_bike != null or ps is PackedScene:
		var bike: Node3D = own_bike if own_bike != null else ps.instantiate()
		holder.add_child(bike)
		var box := _aabb(bike, Transform3D())
		var s := 2.55 / maxf(0.01, maxf(box.size.x, box.size.z))
		bike.scale = Vector3.ONE * s
		# The models are built nose toward -X: turn them to face down the road.
		bike.rotation.y = PI if box.size.x >= box.size.z else PI / 2.0
		bike.position = Vector3(box.get_center().x * s, -box.position.y * s, box.get_center().z * s)
		# Each rider's runner wears their color: a thin coat over the model's own paint.
		var coat := StandardMaterial3D.new()
		coat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		coat.albedo_color = Color(color, 0.34)
		coat.metallic = 0.6
		coat.roughness = 0.35
		for mi in bike.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_overlay = coat
	var fig := RoamFigure.new()
	fig.rotation.y = PI / 2.0
	fig.position = Vector3(-0.2, 0.0, 0.0)
	fig.scale = Vector3.ONE * 1.08
	holder.add_child(fig)
	fig.setup(key, color, "", false)
	fig.ride_pose.call_deferred()
	# Light under the runner and a trail behind it.
	var under := OmniLight3D.new()
	under.light_color = color
	under.light_energy = 3.0
	under.omni_range = 4.5
	under.position = Vector3(0, 0.4, 0)
	holder.add_child(under)
	if _trail_sh == null:
		_trail_sh = Shader.new()
		_trail_sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;
uniform vec3 tint : source_color = vec3(1.0, 0.5, 0.2);
void fragment() {
	float along = UV.x;
	float across = 1.0 - abs(UV.y - 0.5) * 2.0;
	float core = pow(across, 5.0);
	float flick = 0.85 + 0.15 * sin(TIME * 40.0 + UV.x * 30.0);
	ALBEDO = mix(tint, vec3(1.0), core * 0.7);
	ALPHA = pow(along, 1.6) * (0.25 * across + core) * flick;
}
"""
	for k in 3:
		var trail := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(16.0, [0.5, 0.9, 0.34][k])
		trail.mesh = qm
		var m := ShaderMaterial.new()
		m.shader = _trail_sh
		m.set_shader_parameter("tint", color)
		trail.material_override = m
		if k == 1:
			# Flat on the road: the glow the runner leaves on the wet asphalt.
			trail.rotation.x = -PI / 2.0
			trail.position = Vector3(-8.6, 0.03, 0.0)
		else:
			trail.position = Vector3(-8.9, 0.42 + k * 0.2, 0.0)
		holder.add_child(trail)
		_trails.append(trail)
	_bikes.append([holder, at, randf() * TAU])
	return fig


var _sweep: ShaderMaterial


## Light from the street lamps sliding over the duel field as you ride under them, plus the
## road's own glow pulsing along its length. Lay it just above the board.
func lamp_sweep(size: Vector2, y := 0.03) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	mi.mesh = pm
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float offset = 0.0;
uniform vec3 warm : source_color = vec3(1.0, 0.9, 0.72);
uniform vec3 glow_a : source_color = vec3(1.0, 0.54, 0.23);
uniform vec3 glow_b : source_color = vec3(0.18, 0.89, 0.9);
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	// A soft bar of lamp light every 16 m of road, slanted a little like a real shadow edge.
	float x = wp.x + offset + wp.z * 0.35;
	float lamp = pow(max(0.0, cos(x * 6.2832 / 16.0)), 10.0);
	// Thin fast streaks along the lanes.
	float lane = pow(max(0.0, cos((wp.x + offset * 1.0) * 6.2832 / 5.0 + wp.z * 3.0)), 40.0) * step(0.5, fract(wp.z * 0.37 + 0.2));
	vec3 col = warm * lamp * 0.16 + mix(glow_b, glow_a, step(0.0, wp.z)) * lane * 0.1;
	vec2 e = abs(UV - 0.5) * 2.0;
	float fade = smoothstep(1.0, 0.75, max(e.x, e.y));
	ALBEDO = col * fade;
	ALPHA = clamp((lamp * 0.16 + lane * 0.1) * fade, 0.0, 1.0);
}
"""
	_sweep = ShaderMaterial.new()
	_sweep.shader = sh
	_sweep.set_shader_parameter("glow_a", accent)
	_sweep.set_shader_parameter("glow_b", accent2)
	mi.material_override = _sweep
	mi.position.y = y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


var _fx := {}      # rider index -> {"surge": 1..0, "wobble": 1..0, "sparks": node}


## The rider guns it for a moment: used when their monster attacks.
func surge(i: int) -> void:
	if i >= _bikes.size():
		return
	var fx: Dictionary = _fx.get(i, {})
	fx["surge"] = 1.0
	_fx[i] = fx
	target_speed += 3.0
	get_tree().create_timer(1.2).timeout.connect(func(): target_speed -= 3.0)


## The runner shakes and throws sparks: used when its rider takes damage.
func wobble(i: int, hard := false) -> void:
	if i >= _bikes.size():
		return
	var fx: Dictionary = _fx.get(i, {})
	fx["wobble"] = 1.0 if not hard else 1.5
	if not fx.has("sparks") or not is_instance_valid(fx["sparks"]):
		var sp := CPUParticles3D.new()
		sp.amount = 40
		sp.lifetime = 0.5
		sp.one_shot = false
		sp.explosiveness = 0.2
		sp.direction = Vector3(-1, 0.4, 0)
		sp.spread = 28.0
		sp.initial_velocity_min = 6.0
		sp.initial_velocity_max = 14.0
		sp.gravity = Vector3(0, -12, 0)
		sp.scale_amount_min = 0.5
		sp.scale_amount_max = 1.2
		var qm := QuadMesh.new()
		qm.size = Vector2(0.07, 0.07)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.albedo_color = Color(1.0, 0.75, 0.3)
		m.emission_enabled = true
		m.emission = Color(1.0, 0.6, 0.2)
		m.emission_energy_multiplier = 4.0
		qm.material = m
		sp.mesh = qm
		sp.position = Vector3(-0.9, 0.12, 0)
		(_bikes[i][0] as Node3D).add_child(sp)
		fx["sparks"] = sp
	(fx["sparks"] as CPUParticles3D).emitting = true
	_fx[i] = fx


## Move a rider (ride mode drives the runners itself). `lean` tips the runner into a turn.
func place_rider(i: int, at: Vector3, lean := 0.0) -> void:
	if i < _bikes.size():
		_bikes[i][1] = at
		(_bikes[i][0] as Node3D).rotation.z = 0.0
		_bikes[i].resize(4)
		_bikes[i][3] = lean


func rider_node(i: int) -> Node3D:
	return _bikes[i][0] if i < _bikes.size() else null


func _aabb(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	var here := xf
	if n is Node3D:
		here = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		out = here * (n as MeshInstance3D).mesh.get_aabb()
		first = false
	for c in n.get_children():
		var b := _aabb(c, here)
		if b.size == Vector3.ZERO:
			continue
		out = b if first else out.merge(b)
		first = false
	return out


func _process(delta: float) -> void:
	_t += delta
	speed = lerpf(speed, target_speed, clampf(delta * 1.5, 0.0, 1.0))
	_offset = fmod(_offset + speed * delta, 1260.0)
	_far_off += speed * delta
	for sm in _scroll:
		sm.set_shader_parameter("offset", _offset)
		sm.set_shader_parameter("blur", clampf(speed / 22.0, 0.8, 3.0))
	if _sweep:
		_sweep.set_shader_parameter("offset", _far_off)
	if _road:
		_road.set_shader_parameter("offset", _offset)
		_road.set_shader_parameter("blur", clampf(speed / 22.0, 0.8, 3.0))
	for p in _props:
		var n: Node3D = p[0]
		n.position.x -= speed * delta * float(p[1])
		if n.position.x < -SPAN / 2.0:
			n.position.x += SPAN
		# A bend in the road swings whatever is ahead to one side.
		n.position.z = -curve * maxf(0.0, n.position.x) * maxf(0.0, n.position.x) * 0.0035
	for l in _lines:
		var mi: MeshInstance3D = l[0]
		mi.position.x -= speed * delta * float(l[1])
		if mi.position.x < -45.0:
			mi.position.x += 90.0
	for b in _bikes:
		var h: Node3D = b[0]
		var base: Vector3 = b[1]
		var ph: float = b[2]
		# Riders drift a little in their lane and lean with it.
		if b.size() > 3:
			# Driven from outside: just the engine shake and the lean it was given.
			h.position = base + Vector3(0, absf(sin(_t * 9.0 + ph)) * 0.012, 0)
			h.rotation.x = lerpf(h.rotation.x, float(b[3]), clampf(delta * 8.0, 0.0, 1.0))
			continue
		var sway := sin(_t * 0.7 + ph)
		var idx := _bikes.find(b)
		var fx: Dictionary = _fx.get(idx, {})
		# A surge is a short burst ahead with the front wheel light; a wobble is a hit taken.
		var surge := 0.0
		var wob := 0.0
		if fx.has("surge"):
			fx["surge"] = float(fx["surge"]) - delta / 0.9
			surge = sin(clampf(1.0 - float(fx["surge"]), 0.0, 1.0) * PI)
			if float(fx["surge"]) <= 0.0:
				fx.erase("surge")
		if fx.has("wobble"):
			fx["wobble"] = float(fx["wobble"]) - delta / 0.8
			wob = clampf(float(fx["wobble"]), 0.0, 1.0)
			if float(fx["wobble"]) <= 0.0:
				fx.erase("wobble")
				if fx.has("sparks") and is_instance_valid(fx["sparks"]):
					(fx["sparks"] as CPUParticles3D).emitting = false
		h.position = base + Vector3(sin(_t * 0.43 + ph) * 0.5 + surge * 2.4 - wob * 0.9, absf(sin(_t * 9.0 + ph)) * 0.012, sway * 0.28 + sin(_t * 24.0) * 0.22 * wob)
		h.rotation.x = cos(_t * 0.7 + ph) * 0.07 + sin(_t * 31.0) * 0.16 * wob
		h.rotation.z = surge * 0.2
	for tr in _trails:
		tr.scale.x = 0.5 + speed / 40.0 + sin(_t * 30.0) * 0.04
	for bc in _beacons:
		(bc[0] as Node3D).visible = fmod(_t + float(bc[1]), 1.6) < 0.8
	for bm in _beams:
		var pv: Node3D = bm[0]
		pv.rotation.x = sin(_t * float(bm[2]) + float(bm[1])) * 0.45
		pv.rotation.z = cos(_t * float(bm[2]) * 0.7 + float(bm[1])) * 0.35
	for fl in _far:
		(fl[0] as ShaderMaterial).set_shader_parameter("offset", _far_off * float(fl[1]) * float(fl[2]) * -1.0)
