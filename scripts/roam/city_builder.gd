class_name CityBuilder
extends Node3D
## Builds Domino City downtown: wet streets, tiled sidewalks, buildings with lit windows
## and shopfronts, neon, props, traffic, and three times of day.

const TODS := ["night", "sunset", "day"]
const TOD_LOOK := {
	"night": {"top": Color("060818"), "horizon": Color("3a2160"), "ground": Color("0c0a14"), "sun": Color("9db4ff"), "sun_e": 0.75, "sun_rot": Vector3(-48, 30, 0),
		"amb": 1.25, "fog": Color("1a1236"), "fog_d": 0.007, "windows": 1.0, "lamps": 1.0, "neon": 1.0, "exposure": 1.25},
	"sunset": {"top": Color("2a3a78"), "horizon": Color("ff9a5a"), "ground": Color("3a2420"), "sun": Color("ffb880"), "sun_e": 1.9, "sun_rot": Vector3(-15, -60, 0),
		"amb": 1.2, "fog": Color("b06a5a"), "fog_d": 0.006, "windows": 0.3, "lamps": 0.5, "neon": 0.7, "exposure": 1.15},
	"day": {"top": Color("3a7ad8"), "horizon": Color("bcd8f0"), "ground": Color("5a6070"), "sun": Color("fff4e0"), "sun_e": 2.2, "sun_rot": Vector3(-52, -35, 0),
		"amb": 1.0, "fog": Color("c4d6ea"), "fog_d": 0.0026, "windows": 0.06, "lamps": 0.0, "neon": 0.25, "exposure": 0.95},
}

var theme: Dictionary
var env: Environment
var sun: DirectionalLight3D
var sky_mat: ProceduralSkyMaterial
var tod := "night"
var cars: Array = []          # [node, lane_z or lane_x, dir, axis, speed]
var _window_mats: Array[ShaderMaterial] = []
var _lamp_lights: Array[OmniLight3D] = []
var _lamp_bulbs: Array[StandardMaterial3D] = []
var _neon: Array = []          # [Label3D, OmniLight3D, Color]
var _signals: Array = []       # traffic light lamps [[red, yellow, green] materials]
var _time := 0.0
var player: Node3D
var make_solid := true
var places: Array = []        # [kind, position, rotation] of benches, vending machines, fountains
var wide := false             # the full city: DominoPlus builds the outer walls


func build(t: Dictionary, time_of_day: String) -> void:
	theme = t
	_build_env()
	_build_ground()
	_build_buildings()
	_build_landmarks()
	_build_street_furniture()
	_build_traffic()
	if wide:
		DominoPlus.build(self)
	else:
		_build_walls()
	apply_tod(time_of_day)


# ------------------------------------------------------------------ helpers

func mat(c: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func glow_mat(c: Color, energy := 2.0) -> StandardMaterial3D:
	var m := mat(c, 0.4)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


func box(size: Vector3, pos: Vector3, m: Material, solid := true, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	(parent if parent else self).add_child(mi)
	if solid and make_solid:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		body.add_child(cs)
		body.position = pos
		add_child(body)
	return mi


func cyl(r_top: float, r_bottom: float, h: float, pos: Vector3, m: Material, parent: Node3D = null, segs := 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bottom
	c.height = h
	c.radial_segments = segs
	mi.mesh = c
	mi.material_override = m
	mi.position = pos
	(parent if parent else self).add_child(mi)
	return mi


func solid_cyl(r: float, h: float, pos: Vector3) -> void:
	if not make_solid:
		return
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = h
	cs.shape = sh
	body.add_child(cs)
	body.position = pos
	body.collision_layer = 2
	add_child(body)


# ------------------------------------------------------------------ real models

const MODELS := "res://assets/models/city/%s.glb"
static var _model_cache := {}


func has_model(name: String) -> bool:
	return ResourceLoader.exists(MODELS % name) or own_place(name) != ""


## Your own building or prop: <card folder>/places/<name>.glb replaces the game's model of the
## same name (card_shop, corp_tower, duel_table, ...). It is fitted to the same spot and size.
static var _own_places := {}


static func own_place(name: String) -> String:
	var p := Settings.card_folder.path_join("places/%s.glb" % name)
	return p if FileAccess.file_exists(p) else ""


static func own_instance(name: String) -> Node3D:
	var p := own_place(name)
	if p == "":
		return null
	var src = _own_places.get(p)
	if src == null or not is_instance_valid(src):
		src = Avatars._load_glb(p)
		if src == null:
			return null
		_own_places[p] = src
	var copy = (src as Node).duplicate()
	return copy as Node3D


## The way out of a room: a framed double door on the +Z wall, daylight in its glass, brass
## handles, a doormat and a lit EXIT sign above. `at` is the floor point on the wall's inner face.
func exit_door(at: Vector3, leaf := Color(0.42, 0.27, 0.16), frame := Color(0.2, 0.13, 0.08), width := 1.9) -> void:
	var fm := mat(frame, 0.6)
	var lm := mat(leaf, 0.55)
	var dark := mat(leaf.darkened(0.25), 0.6)
	var brass := mat(Color(0.86, 0.68, 0.3), 0.3, 0.8)
	var day := glow_mat(Color(0.78, 0.9, 1.0), 1.25)
	var h := 2.5
	# Daylight behind the door, the frame around it.
	box(Vector3(width + 0.5, h + 0.45, 0.1), at + Vector3(0, (h + 0.45) / 2.0, -0.03), fm, false)
	for sx: float in [-1.0, 1.0]:
		box(Vector3(0.16, h + 0.12, 0.2), at + Vector3(sx * (width / 2.0 + 0.08), (h + 0.12) / 2.0, -0.1), fm, false)
		# One leaf: rail and stile frame, a tall pane above, a panel below, a handle.
		var cx := sx * width / 4.0
		var lw := width / 2.0 - 0.03
		box(Vector3(lw, h, 0.07), at + Vector3(cx, h / 2.0, -0.11), lm, false)
		box(Vector3(lw - 0.3, 1.15, 0.03), at + Vector3(cx, 1.62, -0.15), day, false)
		box(Vector3(0.035, 1.15, 0.045), at + Vector3(cx, 1.62, -0.155), lm, false)
		box(Vector3(lw - 0.3, 0.035, 0.045), at + Vector3(cx, 1.62, -0.155), lm, false)
		box(Vector3(lw - 0.3, 0.72, 0.025), at + Vector3(cx, 0.52, -0.15), dark, false)
		var handle := cyl(0.022, 0.022, 0.5, at + Vector3(sx * 0.11, 1.08, -0.2), brass)
		handle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for hy: float in [0.86, 1.3]:
			box(Vector3(0.03, 0.03, 0.07), at + Vector3(sx * 0.11, hy, -0.17), brass, false)
		box(Vector3(lw, 0.16, 0.085), at + Vector3(cx, 0.08, -0.115), brass, false)
	box(Vector3(width + 0.32, 0.18, 0.2), at + Vector3(0, h + 0.09, -0.1), fm, false)
	box(Vector3(0.02, h, 0.08), at + Vector3(0, h / 2.0, -0.115), fm, false)
	# Light spilling in over the threshold, and a mat to wipe your feet on.
	box(Vector3(width, 0.012, 0.5), at + Vector3(0, 0.008, -0.42), glow_mat(Color(0.85, 0.93, 1.0), 0.5), false)
	box(Vector3(width - 0.1, 0.03, 0.95), at + Vector3(0, 0.02, -0.95), mat(Color(0.16, 0.3, 0.22), 0.95), false)
	box(Vector3(width - 0.4, 0.034, 0.65), at + Vector3(0, 0.02, -0.95), mat(Color(0.24, 0.42, 0.3), 0.95), false)
	# EXIT, lit.
	box(Vector3(1.0, 0.36, 0.08), at + Vector3(0, h + 0.5, -0.1), mat(Color(0.05, 0.1, 0.07), 0.5), false)
	box(Vector3(0.92, 0.28, 0.03), at + Vector3(0, h + 0.5, -0.15), glow_mat(Color("38e08a"), 1.6), false)
	var l := Label3D.new()
	l.text = "EXIT"
	l.font = load("res://assets/fonts/Rajdhani-SemiBold.ttf")
	l.font_size = 56
	l.pixel_size = 0.0045
	l.outline_size = 0
	l.modulate = Color(0.02, 0.1, 0.05)
	l.position = at + Vector3(0, h + 0.5, -0.17)
	l.rotation.y = PI
	add_child(l)


## Place a Meshy-made model. Scaled so its largest side (or its height, if `by_height`) is `size`,
## sitting on the ground at `pos`, turned by `rot` (radians). Model fronts face +Z.
func prop(name: String, pos: Vector3, rot: float, size: float, by_height := false, parent: Node3D = null) -> Node3D:
	if not has_model(name):
		return null
	var inst: Node3D = own_instance(name)
	if inst == null:
		if not ResourceLoader.exists(MODELS % name):
			return null
		var ps: PackedScene = _model_cache.get(name)
		if ps == null:
			ps = load(MODELS % name)
			_model_cache[name] = ps
		inst = ps.instantiate()
	var holder := Node3D.new()
	holder.add_child(inst)
	var box := _aabb(inst, Transform3D.IDENTITY)
	var ref := box.size.y if by_height else maxf(box.size.x, maxf(box.size.y, box.size.z))
	var k := size / maxf(ref, 0.001)
	inst.scale = Vector3.ONE * k
	inst.position = Vector3(-box.get_center().x * k, -box.position.y * k, -box.get_center().z * k)
	holder.position = pos
	holder.rotation.y = rot
	holder.set_meta("size", box.size * k)
	(parent if parent else self).add_child(holder)
	if parent == null and name in ["bench", "vending", "fountain"]:
		places.append([name, pos, rot])
	return holder


func _aabb(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	var t: Transform3D = xf * ((n as Node3D).transform if n is Node3D else Transform3D.IDENTITY)
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		out = t * (n as MeshInstance3D).mesh.get_aabb()
		first = false
	for c in n.get_children():
		var b := _aabb(c, t)
		if b.size != Vector3.ZERO:
			out = b if first else out.merge(b)
			first = false
	return out


## Invisible box collider matching a placed prop.
func collide(holder: Node3D, shrink := 0.9) -> void:
	if holder == null or not make_solid:
		return
	var sz: Vector3 = holder.get_meta("size", Vector3.ONE)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(sz.x * shrink, sz.y, sz.z * shrink)
	cs.shape = sh
	cs.position.y = sz.y / 2.0
	body.add_child(cs)
	# Small things (benches, bikes, lamps) stop your feet but not the camera.
	if maxf(sz.x, sz.z) < 3.6 and sz.y < 6.5:
		body.collision_layer = 2
	holder.add_child(body)


# ------------------------------------------------------------------ environment

func _build_env() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	var sky := Sky.new()
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sun_angle_max = 25
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.9
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.fog_enabled = true
	env.fog_sky_affect = 0.4
	env.volumetric_fog_density = 0.012
	env.volumetric_fog_anisotropy = 0.6
	env.volumetric_fog_length = 60.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.05
	Settings.tune_environment(env)
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	sun.shadow_blur = 1.5
	add_child(sun)


func apply_tod(t: String) -> void:
	tod = t if TOD_LOOK.has(t) else "night"
	var L: Dictionary = TOD_LOOK[tod]
	var accent: Color = theme.get("accent", Color.CYAN)
	sky_mat.sky_top_color = L["top"]
	sky_mat.sky_horizon_color = L["horizon"]
	sky_mat.ground_horizon_color = (L["horizon"] as Color).darkened(0.3)
	sky_mat.ground_bottom_color = L["ground"]
	sky_mat.sun_angle_max = 30 if tod == "sunset" else 15
	sun.light_color = L["sun"]
	sun.light_energy = L["sun_e"]
	sun.rotation_degrees = L["sun_rot"]
	env.ambient_light_energy = L["amb"]
	env.fog_light_color = L["fog"]
	env.fog_density = L["fog_d"]
	env.volumetric_fog_albedo = (L["fog"] as Color).lightened(0.4)
	env.tonemap_exposure = L["exposure"]
	for m in _window_mats:
		m.set_shader_parameter("glow_strength", L["windows"])
		m.set_shader_parameter("day", 1.0 if tod == "day" else (0.5 if tod == "sunset" else 0.0))
	for l in _lamp_lights:
		l.light_energy = 2.4 * L["lamps"]
		l.set_meta("want", L["lamps"] > 0.0)
		l.visible = L["lamps"] > 0.0 and not l.get_meta("far", false)
	for b in _lamp_bulbs:
		b.emission_energy_multiplier = 0.2 + 4.0 * L["lamps"]
	for n in _neon:
		var c: Color = n[2]
		var lab: Label3D = n[0]
		lab.modulate = Color(c.r, c.g, c.b) * (0.8 + 1.6 * L["neon"])
		(n[1] as OmniLight3D).light_energy = 1.8 * L["neon"]
	var road: ShaderMaterial = get_meta("road_mat") if has_meta("road_mat") else null
	if road:
		road.set_shader_parameter("wet", 1.0 if tod != "day" else 0.45)


# ------------------------------------------------------------------ ground

func _road_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
uniform float wet = 1.0;
varying vec3 wp;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y);
}
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float grain = n(wp.xz * 9.0) * 0.5 + n(wp.xz * 31.0) * 0.5;
	float patches = n(wp.xz * 0.35);
	float puddle = smoothstep(0.64, 0.7, n(wp.xz * 0.22 + 7.3) * 0.7 + patches * 0.3) * wet;
	vec3 base = vec3(0.055, 0.056, 0.065) * (0.8 + grain * 0.4) * (0.85 + patches * 0.3);
	ALBEDO = mix(base, base * 0.7, puddle);
	ROUGHNESS = mix(mix(0.82, 0.55, wet * 0.4), 0.04, puddle);
	SPECULAR = mix(0.4, 0.8, puddle);
	NORMAL_MAP = vec3(0.5 + (grain - 0.5) * 0.12 * (1.0 - puddle), 0.5, 1.0);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


func _tile_material(base: Color, tile: float) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
uniform vec4 base : source_color;
uniform float tile = 1.2;
varying vec3 wp;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 g = wp.xz / tile;
	vec2 f = fract(g);
	float line = 1.0 - step(0.035, f.x) * step(0.035, f.y);
	float v = h(floor(g)) * 0.12;
	ALBEDO = base.rgb * (0.92 + v) * mix(1.0, 0.55, line);
	ROUGHNESS = mix(0.7, 0.9, line);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("base", base)
	m.set_shader_parameter("tile", tile)
	return m


func _build_ground() -> void:
	var road := _road_material()
	set_meta("road_mat", road)
	box(Vector3(140, 0.2, 140), Vector3(0, -0.1, 0), road)
	var walk := _tile_material(Color(0.42, 0.41, 0.44), 1.2)
	var curb := mat(Color(0.55, 0.55, 0.58), 0.7)
	for qx in [-1, 1]:
		for qz in [-1, 1]:
			box(Vector3(31, 0.16, 31), Vector3(qx * 21.5, 0.08, qz * 21.5), walk, false)
			# Curbs along the road edges
			box(Vector3(31, 0.18, 0.25), Vector3(qx * 21.5, 0.09, qz * 6.1), curb, false)
			box(Vector3(0.25, 0.18, 31), Vector3(qx * 6.1, 0.09, qz * 21.5), curb, false)
	var paint := mat(Color(0.92, 0.92, 0.88), 0.55)
	var yellow := mat(Color(0.95, 0.75, 0.2), 0.55)
	for i in range(-6, 7):
		if absi(i) <= 1:
			continue
		box(Vector3(2.4, 0.02, 0.16), Vector3(i * 5.0, 0.012, 0.0), yellow, false)
		box(Vector3(0.16, 0.02, 2.4), Vector3(0.0, 0.012, i * 5.0), yellow, false)
	for k in range(-4, 5):
		for side in [-1, 1]:
			box(Vector3(0.55, 0.02, 2.6), Vector3(k * 1.05, 0.012, side * 7.4), paint, false)
			box(Vector3(2.6, 0.02, 0.55), Vector3(side * 7.4, 0.012, k * 1.05), paint, false)
	# Glowing duel emblem in the middle of the crossing.
	for rr in [[2.6, 2.8, 2.5], [3.4, 3.48, 1.2]]:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = rr[0]
		tm.outer_radius = rr[1]
		tm.rings = 64
		ring.mesh = tm
		ring.material_override = glow_mat(theme["accent"], rr[2])
		ring.scale = Vector3(1, 0.04, 1)
		ring.position.y = 0.02
		add_child(ring)


# ------------------------------------------------------------------ buildings

## Lawn: patches, mowing stripes and fine blades, so grass never reads as one flat color.
func grass_material(bright := 1.0) -> ShaderMaterial:
	var sh: Shader
	if has_meta("grass_shader"):
		sh = get_meta("grass_shader")
	else:
		sh = Shader.new()
		sh.code = """
shader_type spatial;
uniform float bright = 1.0;
varying vec3 wp;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float n(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y);
}
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	// Soft patches of lighter and darker lawn, mowing stripes, and fine blades up close.
	float patch = n(wp.xz * 0.35) * 0.6 + n(wp.xz * 1.4) * 0.4;
	float stripe = 0.5 + 0.5 * sin(wp.x * 2.2);
	float blades = n(wp.xz * vec2(60.0, 14.0)) * n(wp.xz * vec2(13.0, 55.0));
	vec3 dark = vec3(0.09, 0.24, 0.09) * bright;
	vec3 light = vec3(0.24, 0.44, 0.13) * bright;
	vec3 col = mix(dark, light, patch * 0.7 + stripe * 0.12);
	col *= 0.82 + blades * 0.5;
	// A few clover-yellow flecks.
	col += vec3(0.5, 0.45, 0.1) * step(0.985, h(floor(wp.xz * 9.0))) * 0.5;
	ALBEDO = col;
	ROUGHNESS = 0.95;
}
"""
		set_meta("grass_shader", sh)
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("bright", bright)
	return m


func window_material(tint: Color, seed: float, storefront: Color) -> ShaderMaterial:
	var sh: Shader
	if has_meta("win_shader"):
		sh = get_meta("win_shader")
	else:
		sh = Shader.new()
		sh.code = """
shader_type spatial;
uniform vec4 wall : source_color = vec4(0.2, 0.2, 0.24, 1.0);
uniform vec4 glow : source_color = vec4(1.0, 0.8, 0.5, 1.0);
uniform vec4 shop : source_color = vec4(0.4, 0.9, 1.0, 1.0);
uniform float seed = 0.0;
uniform float glow_strength = 1.0;
uniform float day = 0.0;
uniform float style = 0.0;
varying vec3 wp;
varying vec3 wn;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233)) + seed) * 43758.5453); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); }
void fragment() {
	float u = abs(wn.x) > 0.5 ? wp.z : wp.x;
	vec3 col = wall.rgb;
	// Brick/concrete texture: running bond for style 0, panels for style 1
	vec2 b = vec2(u / (style > 0.5 ? 1.6 : 0.5), wp.y / (style > 0.5 ? 1.2 : 0.25));
	b.x += style > 0.5 ? 0.0 : step(1.0, mod(floor(b.y), 2.0)) * 0.5;
	vec2 bf = fract(b);
	float mortar = 1.0 - step(0.06, bf.x) * step(0.08, bf.y);
	col *= (0.9 + h(floor(b)) * 0.18) * mix(1.0, 0.7, mortar);
	// Floor bands
	float band = step(fract(wp.y / 3.2), 0.07);
	col = mix(col, wall.rgb * 0.55, band);
	float rough = 0.85;
	float metal = 0.0;
	vec3 emit = vec3(0.0);
	if (abs(wn.y) < 0.5) {
		if (wp.y < 3.3) {
			// Ground floor: shop windows with a sign strip
			float sx = fract(u / 4.0);
			float pane = step(0.08, sx) * step(sx, 0.92) * step(0.25, wp.y) * step(wp.y, 2.4);
			float strip = step(2.6, wp.y) * step(wp.y, 3.0) * step(0.08, sx) * step(sx, 0.92);
			col = mix(col, vec3(0.05, 0.06, 0.08), pane);
			rough = mix(rough, 0.06, pane);
			metal = pane * 0.3;
			float on = step(0.3, h(floor(vec2(u / 4.0, 3.0))));
			emit += shop.rgb * pane * on * (0.25 + glow_strength * 0.9) * 0.6;
			emit += shop.rgb * strip * (0.2 + glow_strength * 1.6);
			col = mix(col, shop.rgb * 0.5, strip);
			// A striped awning lip over the windows and a dark plinth along the pavement.
			float awn = step(2.4, wp.y) * step(wp.y, 2.6) * step(0.08, sx) * step(sx, 0.92);
			col = mix(col, mix(shop.rgb * 0.8, vec3(0.92), step(0.5, fract(u / 0.5))), awn);
			col = mix(col, wall.rgb * 0.4, step(wp.y, 0.25));
			// Window frames, and a door in every third bay.
			float fr = pane * (1.0 - step(0.11, sx) * step(sx, 0.89) * step(0.32, wp.y) * step(wp.y, 2.33));
			col = mix(col, vec3(0.16, 0.17, 0.2), fr);
			float bay = floor(u / 4.0);
			float door = step(0.66, h(vec2(bay, 7.0))) * step(0.36, sx) * step(sx, 0.64) * step(0.25, wp.y) * step(wp.y, 2.3);
			col = mix(col, shop.rgb * 0.22 + 0.04, door);
			col = mix(col, vec3(0.8, 0.7, 0.4), door * step(abs(sx - 0.6), 0.008) * step(abs(wp.y - 1.2), 0.12));
			emit *= 1.0 - door * 0.8;
		} else {
			vec2 g = vec2(u / 1.7, wp.y / 3.2);
			vec2 cell = floor(g);
			vec2 f = fract(g);
			// A pilaster every third bay breaks up the wall.
			float pil = step(fract(u / 5.1), 0.07);
			col = mix(col, wall.rgb * 1.18 + 0.02, pil);
			float wx0 = 0.16; float wx1 = 0.84; float wy0 = 0.24; float wy1 = 0.84;
			float open = step(wx0, f.x) * step(f.x, wx1) * step(wy0, f.y) * step(f.y, wy1);
			float inner = step(wx0 + 0.045, f.x) * step(f.x, wx1 - 0.045) * step(wy0 + 0.03, f.y) * step(f.y, wy1 - 0.03);
			float frame = open * (1.0 - inner);
			float glass = open * inner;
			// Mullions: one down the middle, and on some windows one across.
			float mull = glass * max(step(abs(f.x - 0.5), 0.014), step(abs(f.y - 0.58), 0.011) * step(0.5, h(cell + 9.0)));
			// A sill under every window and the rain streaks below it.
			float sill = step(wx0 - 0.04, f.x) * step(f.x, wx1 + 0.04) * step(wy0 - 0.055, f.y) * step(f.y, wy0);
			float stain = step(wx0, f.x) * step(f.x, wx1) * step(f.y, wy0 - 0.055) * (f.y / (wy0 - 0.055));
			col *= 1.0 - 0.16 * stain * h(cell + 21.0);
			// Blinds pulled part of the way down on some of them.
			float bl = h(cell + 11.0);
			float blinds = glass * step(wy1 - bl * 0.55 * (wy1 - wy0), f.y) * step(0.45, h(cell + 13.0));
			float lit = step(0.45, h(cell));
			vec3 sky = mix(vec3(0.05, 0.07, 0.12), vec3(0.45, 0.6, 0.8), day);
			vec3 gcol = sky * (0.6 + 0.4 * h(cell + 2.0)) * (0.75 + 0.6 * (f.y - wy0));
			col = mix(col, gcol, glass);
			col = mix(col, vec3(0.82, 0.8, 0.74) * (0.65 + 0.3 * h(cell + 17.0)), blinds);
			col = mix(col, wall.rgb * 1.45 + 0.07, frame);
			col = mix(col, wall.rgb * 1.3 + 0.05, sill);
			col = mix(col, wall.rgb * 1.3 + 0.1, mull);
			// The odd air conditioner hanging under a window.
			float ac = step(0.84, h(cell + 31.0)) * step(0.52, f.x) * step(f.x, 0.8) * step(0.05, f.y) * step(f.y, 0.185);
			col = mix(col, vec3(0.74, 0.75, 0.77) * (0.8 + 0.2 * step(0.5, fract(f.y * 60.0))), ac);
			rough = mix(rough, 0.05, glass * (1.0 - blinds));
			metal = mix(metal, 0.5, glass * (1.0 - blinds));
			float warmth = h(cell + 5.0);
			vec3 wc = mix(glow.rgb, vec3(0.7, 0.85, 1.0), step(0.75, warmth));
			emit += wc * glass * (1.0 - mull) * (1.0 - blinds * 0.55) * lit * glow_strength * (0.6 + h(cell + 3.1) * 1.4);
		}
		// Street grime: walls are darker near the pavement.
		col *= mix(0.78, 1.0, smoothstep(0.0, 5.0, wp.y));
	} else if (wn.y > 0.5) {
		col = wall.rgb * 0.45;
	}
	ALBEDO = col;
	ROUGHNESS = rough;
	METALLIC = metal;
	EMISSION = emit;
}
"""
		set_meta("win_shader", sh)
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("wall", tint)
	m.set_shader_parameter("seed", seed)
	m.set_shader_parameter("shop", storefront)
	m.set_shader_parameter("style", float(int(seed) % 2))
	m.set_shader_parameter("glow", Color(1.0, 0.8, 0.52))
	_window_mats.append(m)
	return m


func building(pos: Vector3, size: Vector3, rng: RandomNumberGenerator) -> void:
	var tints := [Color(0.42, 0.3, 0.26), Color(0.32, 0.32, 0.36), Color(0.5, 0.46, 0.4), Color(0.26, 0.3, 0.38), Color(0.55, 0.38, 0.3), Color(0.36, 0.38, 0.34)]
	var shops := [theme["accent"], theme["accent2"], Color("ff5a7a"), Color("5affc0"), Color("ffd060"), Color("7aa8ff")]
	var m := window_material(tints[rng.randi() % tints.size()], rng.randf() * 100.0 + float(rng.randi() % 2), shops[rng.randi() % shops.size()])
	box(size, pos + Vector3(0, size.y / 2.0, 0), m)
	# Roof: parapet, AC units, water tank or antenna
	var roof := pos + Vector3(0, size.y, 0)
	var trim := mat(Color(0.25, 0.25, 0.28), 0.8)
	box(Vector3(size.x + 0.3, 0.5, 0.3), roof + Vector3(0, 0.25, size.z / 2.0), trim, false)
	box(Vector3(size.x + 0.3, 0.5, 0.3), roof + Vector3(0, 0.25, -size.z / 2.0), trim, false)
	box(Vector3(0.3, 0.5, size.z), roof + Vector3(size.x / 2.0, 0.25, 0), trim, false)
	box(Vector3(0.3, 0.5, size.z), roof + Vector3(-size.x / 2.0, 0.25, 0), trim, false)
	var metal := mat(Color(0.6, 0.62, 0.66), 0.4, 0.6)
	for i in rng.randi_range(1, 3):
		box(Vector3(1.2, 0.8, 1.0), roof + Vector3(rng.randf_range(-size.x / 3, size.x / 3), 0.4, rng.randf_range(-size.z / 3, size.z / 3)), metal, false)
	match rng.randi() % 3:
		0:
			var tank := roof + Vector3(size.x * 0.2, 0, -size.z * 0.15)
			for lx in [-0.6, 0.6]:
				for lz in [-0.6, 0.6]:
					cyl(0.06, 0.06, 1.6, tank + Vector3(lx, 0.8, lz), trim)
			cyl(1.0, 1.0, 1.8, tank + Vector3(0, 2.5, 0), mat(Color(0.45, 0.32, 0.22), 0.9))
			cyl(0.0, 1.05, 0.6, tank + Vector3(0, 3.7, 0), mat(Color(0.3, 0.22, 0.16), 0.9))
		1:
			cyl(0.05, 0.08, 6.0, roof + Vector3(-size.x * 0.25, 3.0, size.z * 0.2), metal)
			var tip := glow_mat(Color(1, 0.2, 0.2), 6.0)
			var b := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.15
			sm.height = 0.3
			b.mesh = sm
			b.material_override = tip
			b.position = roof + Vector3(-size.x * 0.25, 6.1, size.z * 0.2)
			add_child(b)


func _build_buildings() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1999
	# Outer ring of tall buildings on every block.
	for qx in [-1, 1]:
		for qz in [-1, 1]:
			for i in 4:
				var along := -12.0 + i * 8.0
				var h := rng.randf_range(10.0, 30.0)
				var w := rng.randf_range(6.8, 7.8)
				var back_rot := 0.0 if qz < 0 else PI
				var side_rot := PI / 2 if qx < 0 else -PI / 2
				if i % 3 == 1 and has_model("apartment"):
					collide(prop("apartment", Vector3(qx * 21.0 + along, 0.16, qz * 32.0), back_rot, rng.randf_range(15.0, 20.0), true))
				else:
					building(Vector3(qx * 21.0 + along, 0, qz * 33.0), Vector3(w, h, 7.5), rng)
				h = rng.randf_range(10.0, 30.0)
				if i % 3 == 2 and has_model("apartment"):
					collide(prop("apartment", Vector3(qx * 32.0, 0.16, qz * 21.0 + along), side_rot, rng.randf_range(15.0, 20.0), true))
				else:
					building(Vector3(qx * 33.0, 0, qz * 21.0 + along), Vector3(7.5, h, w), rng)
	# Mid-block buildings so streets feel like streets.
	var mids := [[Vector3(-24, 0, -13), Vector3(8, 9, 7), "konbini", 0.0], [Vector3(24, 0, -12.5), Vector3(8, 14, 7), "cafe" if has_model("cafe") else "apartment", 0.0],
			[Vector3(-25, 0, 22), Vector3(8, 11, 9), "apartment", PI], [Vector3(-14, 0, 25), Vector3(7, 7, 7), "konbini", PI / 2],
			[Vector3(14, 0, -27), Vector3(6, 18, 6), "apartment", -PI / 2]]
	for b in mids:
		var holder: Node3D = null
		if b[2] == "konbini":
			holder = prop("konbini", b[0] + Vector3(0, 0.16, 0), b[3], 9.0)
		elif b[2] == "cafe":
			holder = prop("cafe", b[0] + Vector3(0, 0.16, 0), b[3], 9.0, true)
		else:
			holder = prop("apartment", b[0] + Vector3(0, 0.16, 0), b[3], (b[1] as Vector3).y + 4.0, true)
		if holder:
			collide(holder)
		else:
			building(b[0], b[1], rng)


func neon_sign(text: String, pos: Vector3, color: Color, size := 120, rot := 0.0, light := true) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.outline_size = 0
	l.modulate = color * 2.0
	l.position = pos
	l.rotation.y = rot
	l.shaded = false
	l.double_sided = false
	l.font = load("res://assets/fonts/Rajdhani-SemiBold.ttf")
	add_child(l)
	var o := OmniLight3D.new()
	o.light_color = color
	o.light_energy = 1.8
	o.omni_range = 8.0
	o.position = pos + Vector3(0, 0, 1.2).rotated(Vector3.UP, rot)
	o.visible = light
	add_child(o)
	_neon.append([l, o, color])
	return l


func _build_landmarks() -> void:
	# Kame Game: the real shop model when we have it
	var kame := prop("card_shop", Vector3(-10, 0.16, -19.5), 0.0, 9.5)
	if kame:
		collide(kame, 0.85)
		neon_sign("KAME GAME", Vector3(-10, 5.6, -14.8), Color("ffd166"), 150)
	else:
		_kame_boxes()
	_rest_of_landmarks()


func _kame_boxes() -> void:
	var shop := mat(Color(0.62, 0.48, 0.34), 0.85)
	box(Vector3(9, 6, 6), Vector3(-10, 3, -19), shop)
	box(Vector3(9.6, 0.4, 6.6), Vector3(-10, 6.2, -19), mat(Color(0.3, 0.18, 0.12)))
	var glass := mat(Color(0.12, 0.16, 0.2), 0.05, 0.4)
	glass.emission_enabled = true
	glass.emission = Color(1.0, 0.8, 0.55)
	glass.emission_energy_multiplier = 0.3
	box(Vector3(5, 2.6, 0.1), Vector3(-10, 1.5, -15.95), glass, false)
	box(Vector3(1.4, 2.4, 0.12), Vector3(-6.3, 1.2, -15.94), mat(Color(0.35, 0.22, 0.14), 0.7), false)
	for i in 8:
		var stripe := box(Vector3(0.88, 0.1, 1.7), Vector3(-13.5 + i * 1.0, 3.2, -15.3), mat(Color(0.85, 0.15, 0.2) if i % 2 == 0 else Color(0.95, 0.95, 0.92), 0.7), false)
		stripe.rotation.x = 0.3
	neon_sign("KAME GAME", Vector3(-10, 4.5, -15.9), Color("ffd166"), 150)


func _rest_of_landmarks() -> void:
	# KaibaCorp Tower
	# In the full city the tower stands back, behind its plaza.
	var kz := -16.0 if wide else 0.0
	var kc := prop("corp_tower", Vector3(0, 0, -50 + kz), 0.0, 78.0, true)
	if kc:
		# The model's base flares out wider than anything you can bump into, so in the full
		# city the solid part is pulled in to where the steps start.
		collide(kc, 0.78 if wide else 0.9)
		var beacon := OmniLight3D.new()
		beacon.light_color = Color("7cc4ff")
		beacon.light_energy = 6.0
		beacon.omni_range = 40.0
		beacon.position = Vector3(0, 40, -44 + kz)
		add_child(beacon)
	else:
		var tower := window_material(Color(0.28, 0.34, 0.48), 7.0, Color("7cc4ff"))
		tower.set_shader_parameter("style", 1.0)
		box(Vector3(14, 72, 14), Vector3(0, 36, -48 + kz), tower)
		box(Vector3(18, 5, 18), Vector3(0, 2.5, -48 + kz), mat(Color(0.78, 0.82, 0.9), 0.25, 0.7))
		box(Vector3(10, 6, 10), Vector3(0, 75, -48 + kz), mat(Color(0.7, 0.75, 0.85), 0.3, 0.8))
		neon_sign("KC", Vector3(0, 62, -40.9 + kz), Color("7cc4ff"), 1100, 0.0, false)
	neon_sign("KAIBACORP", Vector3(0, 6.2, -38.95 + kz), Color("aee0ff"), 260)
	# Landmarks at the far end of each road
	var dome := prop("duel_dome", Vector3(-54, 0, 0), PI / 2, 34.0)
	if dome:
		neon_sign("DUEL DOME", Vector3(-38.5, 9.5, 0), theme["accent"], 300, PI / 2)
	var school := prop("school", Vector3(54, 0, 0), -PI / 2, 30.0)
	if school:
		neon_sign("DOMINO HIGH", Vector3(38.5, 12.5, 0), Color("ffe9a8"), 220, -PI / 2, false)
	prop("clock_tower", Vector3(0, 0, 46), PI, 30.0, true)
	# Inside the blocks
	collide(prop("arcade", Vector3(12.5, 0.16, -16.5), -PI / 2, 9.0))
	if has_model("arcade"):
		neon_sign("ARCADE", Vector3(7.6, 6.4, -16.5), Color("5affc0"), 150, -PI / 2)
	collide(prop("food_stall", Vector3(9.6, 0.16, 26.5), -PI / 2, 3.6), 0.8)
	if has_model("food_stall"):
		var lantern := OmniLight3D.new()
		lantern.light_color = Color(1.0, 0.55, 0.3)
		lantern.light_energy = 1.6
		lantern.omni_range = 6.0
		lantern.position = Vector3(8.8, 2.6, 26.5)
		add_child(lantern)
		_lamp_lights.append(lantern)
	collide(prop("dragon_statue", Vector3(27.5, 0.2, 27.5), -PI * 0.75, 4.2, true), 0.6)
	collide(prop("motorcycle", Vector3(-7.4, 0.16, -9.2), PI / 2, 2.1), 0.7)
	collide(prop("motorcycle", Vector3(7.6, 0.16, 10.4), -PI / 2, 2.1), 0.7)
	# Neon around town
	neon_sign("CARD SHOP", Vector3(-29.1, 6, -13), Color("ff5ab4"), 140, PI / 2)
	neon_sign("GAME CENTER", Vector3(29.1, 5, 10), Color("5affc0"), 150, -PI / 2)
	neon_sign("BURGER WORLD" if not has_model("cafe") else "CAFE", Vector3(24, 6.6, -8.3), Color("ffb030"), 140, 0.0)
	neon_sign("BATTLE CITY", Vector3(-29.1, 16, 14), theme["accent"], 280, PI / 2)
	neon_sign("DUEL DISK  ·  NOW ONLINE", Vector3(29.1, 12, -16), theme["accent2"], 160, -PI / 2)
	neon_sign("HOTEL", Vector3(-25, 9.5, 17.45), Color("ff6060"), 150, 0.0)
	# Park
	var grass := grass_material()
	box(Vector3(22, 0.22, 22), Vector3(19, 0.11, 19), grass, false)
	var hedge := mat(Color(0.1, 0.22, 0.1), 0.95)
	box(Vector3(9, 0.7, 0.6), Vector3(12.5, 0.35, 8.2), hedge)
	box(Vector3(9, 0.7, 0.6), Vector3(25.5, 0.35, 8.2), hedge)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 9:
		var p := Vector3(rng.randf_range(10, 29), 0, rng.randf_range(10, 29))
		if p.distance_to(Vector3(19, 0, 19)) < 4.8 or p.distance_to(Vector3(12, 0, 6)) < 3.0 or absf(p.x - 7.0) < 1.6:
			continue
		tree(p, rng.randf_range(0.85, 1.3))
	if prop("fountain", Vector3(19, 0.2, 19), 0.0, 5.8):
		solid_cyl(2.8, 1.2, Vector3(19, 0.6, 19))
	else:
		var stone := mat(Color(0.62, 0.62, 0.66), 0.6)
		cyl(2.6, 2.8, 0.6, Vector3(19, 0.3, 19), stone, null, 32)
		solid_cyl(2.8, 1.2, Vector3(19, 0.6, 19))
		var water := mat(Color(0.12, 0.3, 0.42), 0.02, 0.1)
		cyl(2.4, 2.4, 0.05, Vector3(19, 0.58, 19), water, null, 32)
		cyl(0.3, 0.45, 1.2, Vector3(19, 1.1, 19), stone)
	var holo := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.6, 2.3)
	holo.mesh = q
	var hm := StandardMaterial3D.new()
	hm.albedo_texture = Cards.get_back()
	hm.albedo_color = Color(theme["accent"], 0.8)
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.emission_enabled = true
	hm.emission = theme["accent"]
	hm.emission_energy_multiplier = 1.4
	hm.cull_mode = BaseMaterial3D.CULL_DISABLED
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	holo.material_override = hm
	holo.position = Vector3(19, 6.2, 19)
	holo.name = "Holo"
	add_child(holo)
	var hl := OmniLight3D.new()
	hl.light_color = theme["accent"]
	hl.light_energy = 2.0
	hl.omni_range = 9.0
	hl.position = Vector3(19, 2.6, 19)
	add_child(hl)


func tree(p: Vector3, s: float) -> void:
	var kind := "sakura" if int(absf(p.x * 7.0 + p.z * 3.0)) % 3 == 0 else "tree"
	if prop(kind, p + Vector3(0, 0.2, 0), fmod(p.x * 13.0, TAU), 5.2 * s, true):
		solid_cyl(0.35 * s, 3.0, p + Vector3(0, 1.5, 0))
		return
	var bark := mat(Color(0.3, 0.2, 0.13), 0.95)
	cyl(0.12 * s, 0.22 * s, 2.2 * s, p + Vector3(0, 1.1 * s, 0), bark)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(p.x * 100 + p.z)
	for i in 4:
		var leaf := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = rng.randf_range(0.9, 1.3) * s
		sm.height = sm.radius * 1.7
		leaf.mesh = sm
		leaf.material_override = mat(Color(0.12, 0.3, 0.14).lerp(Color(0.2, 0.38, 0.12), rng.randf()), 0.95)
		leaf.position = p + Vector3(rng.randf_range(-0.6, 0.6) * s, (2.5 + rng.randf_range(0.0, 1.0)) * s, rng.randf_range(-0.6, 0.6) * s)
		add_child(leaf)
	solid_cyl(0.3 * s, 3.0, p + Vector3(0, 1.5, 0))


# ------------------------------------------------------------------ street furniture

func _build_street_furniture() -> void:
	var pole := mat(Color(0.16, 0.17, 0.2), 0.4, 0.7)
	# Street lamps with curved arms
	for p in [Vector3(6.6, 0, 13), Vector3(-6.6, 0, -13), Vector3(6.6, 0, -25), Vector3(-6.6, 0, 25), Vector3(13, 0, -6.6), Vector3(-25, 0, 6.6), Vector3(25, 0, -6.6), Vector3(-13, 0, 6.6), Vector3(6.6, 0, 26), Vector3(-6.6, 0, -27)]:
		var toward := Vector3(-signf(p.x) if absf(p.x) < 7.0 else 0.0, 0, -signf(p.z) if absf(p.z) < 7.0 else 0.0)
		var lamp_rot := 0.0 if toward.x < 0 else (PI if toward.x > 0 else (-PI / 2 if toward.z < 0 else PI / 2))
		var lm := prop("street_lamp", p + Vector3(0, 0.16, 0), lamp_rot, 5.8, true)
		if lm:
			solid_cyl(0.15, 5.0, p + Vector3(0, 2.5, 0))
			var ll := OmniLight3D.new()
			ll.light_color = Color(1.0, 0.8, 0.58)
			ll.omni_range = 12.0
			ll.omni_attenuation = 1.4
			ll.light_volumetric_fog_energy = 2.5
			ll.position = p + Vector3(0, 5.2, 0) + toward * 2.0
			add_child(ll)
			_lamp_lights.append(ll)
			continue
		box(Vector3(0.16, 5.4, 0.16), p + Vector3(0, 2.7, 0), pole)
		box(Vector3(0.12, 0.12, 0.12) + toward.abs() * 1.3, p + Vector3(0, 5.35, 0) + toward * 0.65, pole, false)
		var bulb := glow_mat(Color(1.0, 0.86, 0.62), 4.0)
		_lamp_bulbs.append(bulb)
		box(Vector3(0.5, 0.14, 0.3) if toward.x != 0 else Vector3(0.3, 0.14, 0.5), p + Vector3(0, 5.25, 0) + toward * 1.2, bulb, false)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.8, 0.58)
		l.omni_range = 12.0
		l.omni_attenuation = 1.4
		l.light_volumetric_fog_energy = 2.5
		l.position = p + Vector3(0, 4.9, 0) + toward * 1.2
		add_child(l)
		_lamp_lights.append(l)
	# Traffic lights on the four corners
	for cx in [-1, 1]:
		for cz in [-1, 1]:
			var base := Vector3(cx * 6.4, 0, cz * 6.4)
			box(Vector3(0.14, 4.2, 0.14), base + Vector3(0, 2.1, 0), pole)
			var head := Node3D.new()
			head.position = base + Vector3(0, 3.8, 0)
			head.rotation.y = 0.0 if cz < 0 else PI
			add_child(head)
			box(Vector3(0.36, 1.0, 0.3), Vector3.ZERO, mat(Color(0.12, 0.12, 0.14), 0.6), false, head)
			var lamps := []
			for k in 3:
				var lm := glow_mat([Color(1, 0.15, 0.1), Color(1, 0.7, 0.1), Color(0.2, 1, 0.4)][k], 0.0)
				var s := MeshInstance3D.new()
				var sm := SphereMesh.new()
				sm.radius = 0.1
				sm.height = 0.2
				s.mesh = sm
				s.material_override = lm
				s.position = Vector3(0, 0.3 - k * 0.3, 0.16)
				head.add_child(s)
				lamps.append(lm)
			_signals.append(lamps)
	# Benches, bins, vending machines, a bus stop
	var wood := mat(Color(0.5, 0.33, 0.2), 0.8)
	for b in [[Vector3(9, 0.16, 13), 0.0], [Vector3(9, 0.16, 24), 0.0], [Vector3(-9, 0.16, 11), PI], [Vector3(15, 0.16, -9), PI / 2]]:
		if prop("bench", b[0], b[1], 1.9):
			box(Vector3(1.8, 1.0, 0.6), b[0] + Vector3(0, 0.5, 0), mat(Color.BLACK), true).visible = false
			continue
		var n := Node3D.new()
		n.position = b[0]
		n.rotation.y = b[1]
		add_child(n)
		box(Vector3(1.8, 0.08, 0.5), Vector3(0, 0.45, 0), wood, false, n)
		box(Vector3(1.8, 0.4, 0.06), Vector3(0, 0.75, -0.25), wood, false, n)
		for x in [-0.8, 0.8]:
			box(Vector3(0.06, 0.45, 0.45), Vector3(x, 0.22, 0), pole, false, n)
		box(Vector3(1.8, 1.0, 0.6), b[0] + Vector3(0, 0.5, 0), mat(Color.BLACK), true).visible = false  # collision only
	for v in [[Vector3(-7.0, 0.16, -10.5), PI / 2, Color("ff4060")], [Vector3(7.0, 0.16, 9.5), -PI / 2, Color("40a0ff")], [Vector3(-7.0, 0.16, 18), PI / 2, Color("40ff9a")]]:
		var vm := prop("vending", v[0], v[1], 1.95, true)
		if vm:
			collide(vm)
			var gl := OmniLight3D.new()
			gl.light_color = Color(0.9, 0.95, 1.0)
			gl.light_energy = 1.2
			gl.omni_range = 3.5
			gl.position = Vector3(0, 1.3, 0.9)
			vm.add_child(gl)
			continue
		var n := Node3D.new()
		n.position = v[0]
		n.rotation.y = v[1]
		add_child(n)
		box(Vector3(1.0, 1.9, 0.75), Vector3(0, 0.95, 0), mat(v[2], 0.4), false, n)
		var front := glow_mat(Color(1, 1, 1).lerp(v[2], 0.3), 1.2)
		box(Vector3(0.75, 1.0, 0.02), Vector3(0, 1.25, 0.38), front, false, n)
		for k in 6:
			box(Vector3(0.09, 0.2, 0.03), Vector3(-0.28 + (k % 3) * 0.28, 1.5 - (k / 3) * 0.4, 0.4), mat([Color.RED, Color.ORANGE, Color.SKY_BLUE, Color.LIME_GREEN, Color.WHITE, Color.YELLOW][k], 0.5), false, n)
		var vl := OmniLight3D.new()
		vl.light_color = Color(1, 1, 1).lerp(v[2], 0.4)
		vl.light_energy = 1.0
		vl.omni_range = 3.0
		vl.position = Vector3(0, 1.3, 0.8)
		n.add_child(vl)
		var col := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(1.0, 1.9, 0.75)
		cs.shape = sh
		cs.position.y = 0.95
		col.add_child(cs)
		n.add_child(col)
	for p in [Vector3(7.2, 0.16, 16), Vector3(-7.2, 0.16, -9), Vector3(16, 0.16, -7.2), Vector3(-16, 0.16, 7.2)]:
		cyl(0.3, 0.27, 0.9, p + Vector3(0, 0.45, 0), mat(Color(0.2, 0.32, 0.25), 0.6))
		solid_cyl(0.3, 0.9, p + Vector3(0, 0.45, 0))
	# Bus stop shelter
	var bs := prop("bus_stop", Vector3(-18, 0.16, 6.6), PI, 4.2)
	if bs:
		box(Vector3(4, 2.4, 0.4), Vector3(-18, 1.3, 6.0), mat(Color.BLACK), true).visible = false
		return
	var bus := Node3D.new()
	bus.position = Vector3(-18, 0.16, 7.0)
	add_child(bus)
	box(Vector3(4, 0.1, 1.6), Vector3(0, 2.4, -0.3), mat(Color(0.2, 0.22, 0.26), 0.4, 0.6), false, bus)
	var pane := mat(Color(0.6, 0.8, 0.95, 0.25), 0.05)
	pane.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	box(Vector3(4, 2.3, 0.05), Vector3(0, 1.2, -1.05), pane, false, bus)
	box(Vector3(1.2, 2.0, 0.06), Vector3(1.6, 1.2, -1.0), glow_mat(theme["accent2"], 1.0), false, bus)
	for x in [-1.9, 1.9]:
		box(Vector3(0.08, 2.4, 0.08), Vector3(x, 1.2, 0.4), pole, false, bus)
	box(Vector3(4, 2.4, 0.4), Vector3(-18, 1.3, 6.0), mat(Color.BLACK), true).visible = false


func _process(delta: float) -> void:
	_time += delta
	var holo := get_node_or_null("Holo")
	if holo:
		holo.rotation.y += delta * 0.8
	# Traffic signals: X road gets green for 8 s, then yellow, then red.
	var phase := fmod(_time, 20.0)
	for i in _signals.size():
		var lamps: Array = _signals[i]
		var xroad := i % 2 == 0
		var t := phase if xroad else fmod(phase + 10.0, 20.0)
		var state := 2 if t < 8.0 else (1 if t < 10.0 else 0)
		for k in 3:
			(lamps[k] as StandardMaterial3D).emission_energy_multiplier = 4.0 if k == state else 0.05
	_move_cars(delta)


# ------------------------------------------------------------------ traffic

func car(color: Color) -> Node3D:
	if has_model("kei_car"):
		var n := Node3D.new()
		var kind := "kei_car" if color.r > color.b else "sedan"
		var m := prop(kind, Vector3.ZERO, PI / 2, 4.2 if kind == "sedan" else 3.6, false, n)
		var spot := SpotLight3D.new()
		spot.light_color = Color(1, 0.95, 0.85)
		spot.light_energy = 3.0
		spot.spot_range = 14.0
		spot.spot_angle = 30.0
		spot.position = Vector3(0, 0.75, 2.2)
		spot.rotation.x = -0.12
		spot.rotation.y = PI
		n.add_child(spot)
		return n
	var n := Node3D.new()
	var paint := mat(color, 0.25, 0.6)
	paint.clearcoat_enabled = true
	paint.clearcoat = 0.8
	var glass := mat(Color(0.06, 0.08, 0.12), 0.05, 0.4)
	box(Vector3(1.8, 0.6, 4.2), Vector3(0, 0.62, 0), paint, false, n)
	box(Vector3(1.6, 0.55, 2.1), Vector3(0, 1.18, -0.2), glass, false, n)
	box(Vector3(1.62, 0.06, 2.0), Vector3(0, 1.47, -0.2), paint, false, n)
	var tire := mat(Color(0.05, 0.05, 0.06), 0.9)
	for x in [-0.85, 0.85]:
		for z in [-1.35, 1.35]:
			var w := cyl(0.34, 0.34, 0.26, Vector3(x, 0.34, z), tire, n)
			w.rotation.z = PI / 2
	var head := glow_mat(Color(1, 0.95, 0.85), 3.0)
	var tail := glow_mat(Color(1, 0.1, 0.1), 2.5)
	for x in [-0.6, 0.6]:
		box(Vector3(0.35, 0.14, 0.05), Vector3(x, 0.72, 2.1), head, false, n)
		box(Vector3(0.35, 0.12, 0.05), Vector3(x, 0.74, -2.1), tail, false, n)
	var spot := SpotLight3D.new()
	spot.light_color = Color(1, 0.95, 0.85)
	spot.light_energy = 3.0
	spot.spot_range = 14.0
	spot.spot_angle = 30.0
	spot.position = Vector3(0, 0.75, 2.2)
	spot.rotation.x = -0.12
	spot.rotation.y = PI
	n.add_child(spot)
	return n


func _build_traffic() -> void:
	var colors := [Color("c02030"), Color("e8e8f0"), Color("202a40"), Color("e0a020"), Color("2a6aa0"), Color("303034")]
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	# Parked cars along the curbs, with collision.
	for p in [[Vector3(4.2, 0, 16), 0.0], [Vector3(-4.2, 0, 21), PI], [Vector3(4.2, 0, -16), 0.0], [Vector3(16, 0, 4.2), PI / 2], [Vector3(-21, 0, -4.2), -PI / 2], [Vector3(-14, 0, 4.2), PI / 2]]:
		var c := car(colors[rng.randi() % colors.size()])
		c.position = p[0]
		c.rotation.y = p[1]
		add_child(c)
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(1.9, 1.5, 4.3)
		cs.shape = sh
		cs.position.y = 0.75
		body.add_child(cs)
		c.add_child(body)
	# Moving cars: two per road, opposite lanes.
	for spec in [["x", 2.0, 1.0, -30.0], ["x", -2.0, -1.0, 12.0], ["z", -2.0, 1.0, -8.0], ["z", 2.0, -1.0, 24.0]]:
		var c := car(colors[rng.randi() % colors.size()])
		add_child(c)
		cars.append({"node": c, "axis": spec[0], "lane": spec[1], "dir": spec[2], "pos": spec[3], "speed": 9.0})


func _move_cars(delta: float) -> void:
	for c in cars:
		var target := 9.0
		var n: Node3D = c["node"]
		var ahead: Vector3 = Vector3(c["dir"], 0, 0) if c["axis"] == "x" else Vector3(0, 0, c["dir"])
		# Stop for the player or for a red light before the crossing.
		if player:
			var to := player.global_position - n.global_position
			to.y = 0
			if to.dot(ahead) > 0.0 and to.dot(ahead) < 7.0 and absf(to.dot(Vector3(ahead.z, 0, ahead.x))) < 1.6:
				target = 0.0
		var p: float = c["pos"]
		var before_cross := (p * float(c["dir"])) < -8.5 and (p * float(c["dir"])) > -12.0
		var phase := fmod(_time, 20.0)
		var green := (phase < 9.0) if c["axis"] == "x" else (phase >= 10.0 and phase < 19.0)
		if before_cross and not green:
			target = 0.0
		c["speed"] = move_toward(c["speed"], target, delta * (14.0 if target < c["speed"] else 5.0))
		if wide:
			# The avenues end at plazas now, so traffic turns around at the end of each one.
			var lane: float = c["lane"]
			var d: float = c["dir"]
			if c.has("turn"):
				var t: float = float(c["turn"]) + delta * maxf(float(c["speed"]), 3.0) * 0.55 / (PI * absf(lane))
				var ang := t * PI
				var along := d * (31.0 + absf(lane) * sin(ang))
				var across := lane * cos(ang)
				var vel_along := d * cos(ang)
				var vel_across := -lane / absf(lane) * sin(ang)
				if c["axis"] == "x":
					n.position = Vector3(along, 0, across)
					n.rotation.y = atan2(vel_along, vel_across)
				else:
					n.position = Vector3(across, 0, along)
					n.rotation.y = atan2(vel_across, vel_along)
				if t >= 1.0:
					c.erase("turn")
					c["lane"] = -lane
					c["dir"] = -d
					c["pos"] = d * 31.0
				else:
					c["turn"] = t
				continue
			p += d * float(c["speed"]) * delta
			if p * d > 31.0:
				c["turn"] = 0.0
				p = d * 31.0
		else:
			p += float(c["dir"]) * c["speed"] * delta
			if p > 40.0:
				p = -40.0
			elif p < -40.0:
				p = 40.0
		c["pos"] = p
		if c["axis"] == "x":
			n.position = Vector3(p, 0, c["lane"])
			n.rotation.y = PI / 2 if c["dir"] > 0 else -PI / 2
		else:
			n.position = Vector3(c["lane"], 0, p)
			n.rotation.y = 0.0 if c["dir"] > 0 else PI


func _build_walls() -> void:
	var wall := StandardMaterial3D.new()
	wall.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wall.albedo_color = Color(0, 0, 0, 0)
	for side in [-1, 1]:
		box(Vector3(80, 6, 1), Vector3(0, 3, side * 34.5), wall).visible = false
		box(Vector3(1, 6, 80), Vector3(side * 34.5, 3, 0), wall).visible = false
