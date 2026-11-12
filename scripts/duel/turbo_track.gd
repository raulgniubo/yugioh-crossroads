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
	_build_road()
	_build_sides()
	_build_skyline()
	_build_tunnel()
	_build_bridge()
	_build_speed_lines()
	set_zone("")


## Which stretch of the highway is showing: "satellite", "tops", "tunnel", "bridge", or ""
## for the mixed skyline used in duels.
func set_zone(z: String) -> void:
	zone = z
	for k in _zones:
		var on: bool = k == z or (z == "" and k in ["satellite", "tops"])
		for n in _zones[k]:
			(n as Node3D).visible = on
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
	// Asphalt, smeared along the direction of travel.
	float grain = hash(vec2(floor(x * (0.25 / blur)), floor(z * 9.0)));
	vec3 col = vec3(0.035, 0.04, 0.055) + grain * 0.02;
	// Lane dashes.
	float dash = step(0.5, fract(x / 9.0));
	for (int i = -2; i <= 2; i++) {
		float lz = float(i) * 4.4;
		float d = abs(z - lz);
		float line = 1.0 - smoothstep(0.07, 0.11, d);
		col = mix(col, vec3(0.75, 0.8, 0.9), line * dash * 0.75);
	}
	// Glowing edges.
	float ea = 1.0 - smoothstep(0.0, 0.9, abs(z - 12.4));
	float eb = 1.0 - smoothstep(0.0, 0.9, abs(z + 12.4));
	col += glow_a * ea * 1.4 + glow_b * eb * 1.4;
	// Chevrons racing down the middle lanes.
	float chev = abs(fract((x - abs(z) * 0.8) / 14.0) - 0.5);
	float cz = 1.0 - smoothstep(6.0, 9.5, abs(z));
	col += mix(glow_b, glow_a, step(0.0, z)) * (1.0 - smoothstep(0.02, 0.06, chev)) * 0.16 * cz;
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
		_box(wall, Vector3(260, 1.1, 0.5), Vector3(0, 0.45, side * 14.2), _solid(Color(0.07, 0.08, 0.11)))
		_box(wall, Vector3(260, 0.08, 0.08), Vector3(0, 0.95, side * 13.92), _glow(col, 3.0))
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
		_box(gantry, Vector3(0.12, 1.6, 9.0), Vector3(-0.2, 7.2, -6.0), _glow(accent2.darkened(0.3), 1.6))
		_box(gantry, Vector3(0.12, 1.6, 9.0), Vector3(-0.2, 7.2, 6.0), _glow(accent.darkened(0.3), 1.6))
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
varying vec3 lp;
float hash(vec2 p) { return fract(sin(dot(p, vec2(41.3, 289.1)) + seed) * 43758.5453); }
void vertex() { lp = VERTEX; }
void fragment() {
	vec2 g = vec2(lp.x + lp.z, lp.y) * vec2(0.7, 0.6);
	vec2 cell = floor(g);
	vec2 f = fract(g);
	float lit = step(0.62, hash(cell));
	float w = step(0.18, f.x) * step(f.x, 0.82) * step(0.2, f.y) * step(f.y, 0.8);
	ALBEDO = vec3(0.02, 0.025, 0.045) + tint * lit * w * (0.5 + 0.5 * hash(cell + 7.0));
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
			_box(t, Vector3(w, h, d), Vector3(0, h / 2.0 - 4.0, z), mat)
			if rng.randf() < 0.4:
				_box(t, Vector3(w * 0.9, 0.5, 0.3), Vector3(0, h - 4.0, z - side * d / 2.0), _glow([accent, accent2][rng.randi() % 2], 2.5))
			_prop(t, rng.randf_range(-SPAN / 2.0, SPAN / 2.0), 0.18 + 6.0 / absf(z))
			_zones["satellite" if i % 2 == 0 else "tops"].append(t)


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
	if ps is PackedScene:
		var bike: Node3D = ps.instantiate()
		holder.add_child(bike)
		var box := _aabb(bike, Transform3D())
		var s := 2.55 / maxf(0.01, maxf(box.size.x, box.size.z))
		bike.scale = Vector3.ONE * s
		# The models are built nose toward -X: turn them to face down the road.
		bike.rotation.y = PI if box.size.x >= box.size.z else PI / 2.0
		bike.position = Vector3(box.get_center().x * s, -box.position.y * s, box.get_center().z * s)
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
	for k in 2:
		var trail := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(9.0, 0.03, 0.16)
		trail.mesh = bm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_color = Color(color, 0.5 - k * 0.25)
		trail.material_override = m
		trail.position = Vector3(-5.6 - k * 2.0, 0.05, 0.0)
		holder.add_child(trail)
		_trails.append(trail)
	_bikes.append([holder, at, randf() * TAU])
	return fig


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
		h.position = base + Vector3(sin(_t * 0.43 + ph) * 0.5, absf(sin(_t * 9.0 + ph)) * 0.012, sway * 0.28)
		h.rotation.x = cos(_t * 0.7 + ph) * 0.07
	for tr in _trails:
		tr.scale.x = 0.7 + speed / 40.0 + sin(_t * 30.0) * 0.05
