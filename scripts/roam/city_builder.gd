class_name CityBuilder
extends Node3D
## Builds Domino City downtown: wet streets, tiled sidewalks, buildings with lit windows
## and shopfronts, neon, props, traffic, and three times of day.

const TODS := ["night", "sunset", "day"]
const TOD_LOOK := {
	"night": {"top": Color("050816"), "horizon": Color("2c2458"), "ground": Color("0c0a14"), "sun": Color("a9bcff"), "sun_e": 0.8, "sun_rot": Vector3(-48, 30, 0),
		"amb": 1.3, "fog": Color("1a1638"), "fog_d": 0.0036, "windows": 1.0, "lamps": 1.0, "neon": 1.0, "exposure": 1.25,
		"cloud": 0.34, "cloud_col": Color("5a5f8c"), "cloud_shade": Color("191a34"), "stars": 1.0, "shadow": 0.6, "lift": 0.1},
	"sunset": {"top": Color("27367a"), "horizon": Color("ffa063"), "ground": Color("3a2420"), "sun": Color("ffb47a"), "sun_e": 1.9, "sun_rot": Vector3(-15, -60, 0),
		"amb": 1.2, "fog": Color("c07a62"), "fog_d": 0.0028, "windows": 0.3, "lamps": 0.5, "neon": 0.7, "exposure": 1.12,
		"cloud": 0.48, "cloud_col": Color("ffc79a"), "cloud_shade": Color("7a4a66"), "stars": 0.0, "shadow": 0.72, "lift": 0.03},
	"day": {"top": Color("2f74d6"), "horizon": Color("b8dcf6"), "ground": Color("5a6070"), "sun": Color("fff0d2"), "sun_e": 2.1, "sun_rot": Vector3(-50, -35, 0),
		"amb": 1.2, "fog": Color("cfe2f2"), "fog_d": 0.0011, "windows": 0.06, "lamps": 0.0, "neon": 0.25, "exposure": 0.98,
		"cloud": 0.46, "cloud_col": Color("ffffff"), "cloud_shade": Color("9fb4d0"), "stars": 0.0, "shadow": 0.78, "lift": 0.0},
}

var theme: Dictionary
var env: Environment
var sun: DirectionalLight3D
var sky_mat: ShaderMaterial
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

## A plain painted surface. Anything matte gets a fine grain laid over it in world space (so it
## never stretches, whatever the shape or size of the thing), which is what stops big walls and
## floors from reading as flat blocks of one color.
static var _grain: Texture2D
static var _grain_n: Texture2D


static func _grain_textures() -> void:
	if _grain != null:
		return
	var fn := FastNoiseLite.new()
	fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fn.frequency = 0.016
	fn.fractal_octaves = 3
	fn.fractal_gain = 0.6
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.9, 0.9, 0.9))
	ramp.set_color(1, Color(1.0, 1.0, 1.0))
	var t := NoiseTexture2D.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.generate_mipmaps = true
	t.noise = fn
	t.color_ramp = ramp
	_grain = t
	var fn2 := FastNoiseLite.new()
	fn2.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fn2.frequency = 0.03
	fn2.fractal_octaves = 3
	var nt := NoiseTexture2D.new()
	nt.width = 256
	nt.height = 256
	nt.seamless = true
	nt.generate_mipmaps = true
	nt.as_normal_map = true
	nt.bump_strength = 2.0
	nt.noise = fn2
	_grain_n = nt


func mat(c: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if rough >= 0.6 and metal < 0.3:
		_grain_textures()
		m.albedo_texture = _grain
		m.normal_enabled = true
		m.normal_texture = _grain_n
		m.normal_scale = 0.22
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(0.42, 0.42, 0.42)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


## A real surface: planks, roof tiles, rock, sand, brick, plaster, paving or concrete. The pattern
## is worked out from where each point is in the world, with relief the sun picks out, so it
## lines up across neighbouring blocks and never stretches.
const SURF := {"plaster": 0, "wood": 1, "roof": 2, "rock": 3, "sand": 4, "brick": 5, "paving": 6, "concrete": 7, "bark": 8}
static var _surf_shader: Shader


func surf(kind: String, c: Color, tile := 1.0) -> ShaderMaterial:
	if _surf_shader == null:
		_surf_shader = Shader.new()
		_surf_shader.code = """
shader_type spatial;
uniform vec3 base : source_color = vec3(0.7);
uniform int kind = 0;
uniform float tile = 1.0;
varying vec3 wp;
varying vec3 wn;
float h1(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h1(i), h1(i + vec2(1.0, 0.0)), f.x), mix(h1(i + vec2(0.0, 1.0)), h1(i + vec2(1.0, 1.0)), f.x), f.y);
}
float h3(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float n3(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(h3(i), h3(i + vec3(1.0, 0.0, 0.0)), f.x), mix(h3(i + vec3(0.0, 1.0, 0.0)), h3(i + vec3(1.0, 1.0, 0.0)), f.x), f.y);
	float b = mix(mix(h3(i + vec3(0.0, 0.0, 1.0)), h3(i + vec3(1.0, 0.0, 1.0)), f.x), mix(h3(i + vec3(0.0, 1.0, 1.0)), h3(i + vec3(1.0, 1.0, 1.0)), f.x), f.y);
	return mix(a, b, f.z);
}
float fbm3(vec3 p) { return n3(p) * 0.5 + n3(p * 2.1) * 0.3 + n3(p * 4.3) * 0.2; }
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	// Flat-face mapping: floors and roofs from above, walls from the side they face.
	vec3 an = abs(wn);
	vec2 uv = (an.y > 0.55) ? wp.xz : ((an.x > an.z) ? vec2(wp.z, wp.y) : vec2(wp.x, wp.y));
	uv /= tile;
	vec3 col = base;
	float hgt = 0.0;
	float rough = 0.85;
	// Size of one pixel on the surface, and the size of the pattern drawn on it. Once the
	// pattern is smaller than a few pixels it is faded to its average, so nothing shimmers.
	float fw = max(length(fwidth(wp)), 0.0001);
	float period = 0.2;
	float grain = mix(0.5, fbm3(wp * 6.0), 1.0 - smoothstep(0.03, 0.1, fw));
	if (kind == 1) {
		// Planks: long boards with a gap between, a little grain along each one.
		vec2 g = vec2(uv.x * 0.45, uv.y * 4.2);
		if (an.y > 0.55) { g = vec2(uv.y * 0.45, uv.x * 4.2); }
		float row = floor(g.y);
		g.x += h1(vec2(row, 3.0)) * 7.0;
		vec2 f = fract(g);
		float gap = smoothstep(0.0, 0.07, f.y) * smoothstep(1.0, 0.93, f.y) * smoothstep(0.0, 0.012, f.x) * smoothstep(1.0, 0.988, f.x);
		float streak = n2(vec2(g.x * 3.0, g.y * 26.0));
		col *= 0.8 + 0.3 * h1(vec2(row, floor(g.x))) ;
		col *= 0.88 + streak * 0.2;
		col *= mix(0.45, 1.0, gap);
		hgt = gap * 0.6 + streak * 0.12;
		rough = 0.78;
		period = 0.24 * tile;
	} else if (kind == 2) {
		// Roof tiles: overlapping rows, each tile rounded at the bottom.
		vec2 g = uv * vec2(2.6, 3.4);
		float row = floor(g.y);
		g.x += mod(row, 2.0) * 0.5;
		vec2 f = fract(g);
		float edge = smoothstep(0.0, 0.08, f.x) * smoothstep(1.0, 0.92, f.x);
		float lip = smoothstep(0.0, 0.22, f.y);
		col *= 0.78 + 0.32 * h1(vec2(floor(g.x), row));
		col *= mix(0.55, 1.0, lip) * mix(0.7, 1.0, edge);
		hgt = (1.0 - f.y) * 0.8 * edge;
		rough = 0.7;
		period = 0.3 * tile;
	} else if (kind == 3) {
		// Rock: broken strata, cracks and lighter weathered patches.
		float strata = n2(vec2(wp.y * 1.3 + fbm3(wp * 0.35) * 3.0, 0.0));
		float crack = smoothstep(0.42, 0.5, abs(fbm3(wp * 0.9) - 0.5) * 2.0 + 0.3);
		float big = fbm3(wp * 0.16);
		col *= 0.86 + strata * 0.16 + big * 0.14;
		col = mix(col * 0.8, col, crack);
		col *= 0.95 + grain * 0.1;
		// A little moss on the flat tops only.
		col = mix(col, vec3(0.22, 0.34, 0.14) * (0.8 + grain * 0.4), smoothstep(0.84, 0.95, wn.y) * smoothstep(0.4, 0.7, big + grain * 0.3) * 0.8);
		hgt = strata * 0.5 + crack * 0.5 + grain * 0.3;
		rough = 0.95;
		period = 1.2;
	} else if (kind == 4) {
		// Sand: wind ripples, damp darker patches and a sparkle of shell grit.
		float rip = sin((wp.x * 0.8 + wp.z * 2.6) + n2(wp.xz * 0.6) * 5.0);
		float damp = fbm3(wp * 0.12);
		col *= 0.9 + rip * 0.035 + damp * 0.14;
		col *= 0.94 + n2(wp.xz * 40.0) * 0.1;
		col += vec3(0.25) * step(0.992, h1(floor(wp.xz * 22.0)));
		hgt = rip * 0.25 + n2(wp.xz * 18.0) * 0.2;
		rough = 0.96;
		period = 0.35;
	} else if (kind == 5) {
		// Brick: staggered courses with mortar lines.
		vec2 g = uv * vec2(3.6, 9.0);
		float row = floor(g.y);
		g.x += mod(row, 2.0) * 0.5;
		vec2 f = fract(g);
		float mortar = smoothstep(0.0, 0.05, f.x) * smoothstep(1.0, 0.95, f.x) * smoothstep(0.0, 0.11, f.y) * smoothstep(1.0, 0.89, f.y);
		col *= 0.8 + 0.34 * h1(vec2(floor(g.x), row));
		col = mix(vec3(0.72, 0.7, 0.66) * 0.8, col, mortar);
		col *= 0.92 + grain * 0.16;
		hgt = mortar * 0.7 + grain * 0.15;
		rough = 0.88;
		period = 0.11 * tile;
	} else if (kind == 6) {
		// Paving: stone slabs of two sizes, worn edges, the odd darker stone.
		vec2 g = uv * 1.0;
		float row = floor(g.y);
		g.x = g.x * 0.62 + mod(row, 2.0) * 0.5 + h1(vec2(row, 9.0)) * 0.3;
		vec2 f = fract(g);
		float joint = smoothstep(0.0, 0.035, f.x) * smoothstep(1.0, 0.965, f.x) * smoothstep(0.0, 0.05, f.y) * smoothstep(1.0, 0.95, f.y);
		float tone = h1(vec2(floor(g.x), row));
		col *= 0.86 + 0.2 * tone;
		col *= 0.92 + fbm3(wp * 2.2) * 0.16;
		col = mix(col * 0.5, col, joint);
		hgt = joint * 0.7 + grain * 0.1;
		rough = mix(0.92, 0.78, joint);
		period = 1.0 * tile;
	} else if (kind == 7) {
		// Concrete: cast panels with seams, stains running down from the top.
		vec2 f = fract(uv * vec2(0.25, 0.33));
		float seam = smoothstep(0.0, 0.01, f.x) * smoothstep(1.0, 0.99, f.x) * smoothstep(0.0, 0.014, f.y) * smoothstep(1.0, 0.986, f.y);
		float stain = n2(vec2(uv.x * 1.6, uv.y * 0.12)) * n2(uv * 0.4);
		col *= 0.9 + grain * 0.16 - stain * 0.16;
		col = mix(col * 0.6, col, seam);
		hgt = seam * 0.5 + grain * 0.2;
		rough = 0.9;
		period = 3.0 * tile;
	} else if (kind == 8) {
		// Bark: deep ridges running up the trunk.
		float ridge = n2(vec2(atan(wn.x, wn.z) * 7.0 + wp.y * 0.6, wp.y * 2.2));
		col *= 0.6 + ridge * 0.7;
		hgt = ridge;
		rough = 0.95;
		period = 0.4;
	} else {
		// Plaster: soft blotches, fine grain, a little weathering near the ground.
		float blotch = fbm3(wp * 0.5);
		col *= 0.92 + blotch * 0.12 + grain * 0.06;
		hgt = grain * 0.35 + blotch * 0.2;
		rough = 0.9;
	}
	float keep = 1.0 - smoothstep(period * 0.1, period * 0.42, fw);
	col = mix(base * 0.92, col, keep);
	hgt *= keep;
	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = 0.3;
	// Relief without needing UVs: tilt the normal by how the height changes across the screen.
	vec3 dpx = dFdx(VERTEX);
	vec3 dpy = dFdy(VERTEX);
	float dhx = dFdx(hgt);
	float dhy = dFdy(hgt);
	vec3 r1 = cross(dpy, NORMAL);
	vec3 r2 = cross(NORMAL, dpx);
	float det = dot(dpx, r1);
	vec3 grad = sign(det) * (dhx * r1 + dhy * r2);
	float fade = clamp(1.0 - length(VERTEX) / 60.0, 0.0, 1.0);
	NORMAL = normalize(abs(det) * NORMAL - 0.035 * fade * grad);
}
"""
	var m := ShaderMaterial.new()
	m.shader = _surf_shader
	m.set_shader_parameter("base", c)
	m.set_shader_parameter("kind", int(SURF.get(kind, 0)))
	m.set_shader_parameter("tile", tile)
	return m


func glow_mat(c: Color, energy := 2.0) -> StandardMaterial3D:
	var m := mat(c, 0.4)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


## Flat things lying on the ground (paths, plazas, painted lines, rugs) are often laid one over
## another. Two tops at the same height flicker, so each new one is lifted clear of whatever
## flat thing is already under it. `no_grass` is where the ground is covered.
var no_grass: Array[Rect2] = []
var _flats := {}                 # grid cell -> [[Rect2, top height]]
const FLAT_GAP := 0.007


func _settle_flat(size: Vector3, pos: Vector3) -> Vector3:
	var r := Rect2(pos.x - size.x / 2.0, pos.z - size.z / 2.0, size.x, size.z)
	var top := pos.y + size.y / 2.0
	var c0 := Vector2i(floori(r.position.x / 24.0), floori(r.position.y / 24.0))
	var c1 := Vector2i(floori(r.end.x / 24.0), floori(r.end.y / 24.0))
	var cells: Array[Vector2i] = []
	if (c1.x - c0.x + 1) * (c1.y - c0.y + 1) > 64:
		cells.append(Vector2i(99999, 99999))      # huge slabs (the whole road) live in one shared list
	else:
		for cx in range(c0.x, c1.x + 1):
			for cz in range(c0.y, c1.y + 1):
				cells.append(Vector2i(cx, cz))
	var look: Array[Vector2i] = cells.duplicate()
	if not look.has(Vector2i(99999, 99999)):
		look.append(Vector2i(99999, 99999))
	var start := top
	for _pass in 6:
		var moved := false
		for cell in look:
			for e in _flats.get(cell, []):
				var other_top: float = e[1]
				if absf(other_top - top) < FLAT_GAP - 0.0002 and top >= other_top - 0.0005 and (e[0] as Rect2).intersects(r):
					top = other_top + FLAT_GAP
					moved = true
		if not moved:
			break
	var lift := top - start
	for cell in cells:
		if not _flats.has(cell):
			_flats[cell] = []
		(_flats[cell] as Array).append([r, top])
	if top < 0.6 and top > -0.2 and size.x * size.z >= 1.5:
		no_grass.append(r)
	return pos + Vector3(0, lift, 0)


func box(size: Vector3, pos: Vector3, m: Material, solid := true, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	var at := pos
	if parent == null and size.y <= 0.35 and size.x * size.z >= 0.25:
		at = _settle_flat(size, pos)
	mi.position = at
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
	if parent == null and h <= 0.5 and r_top >= 1.5 and pos.y < 0.6 and pos.y > -0.2 and r_top < 30.0:
		no_grass.append(Rect2(pos.x - r_top * 0.86, pos.z - r_top * 0.86, r_top * 1.72, r_top * 1.72))
	return mi


## Open water around an island: turquoise shallows fading to deep blue, small waves that catch
## the sun, and lines of foam rolling up the beach. `shore` is how far from `center` the
## waterline is.
func water_material(shore: float, center := Vector2.ZERO) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
uniform float shore = 79.0;
uniform vec2 center = vec2(0.0);
uniform vec3 deep : source_color = vec3(0.03, 0.2, 0.42);
uniform vec3 shallow : source_color = vec3(0.16, 0.62, 0.68);
uniform float lum = 1.0;
varying vec3 wp;
float h1(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h1(i), h1(i + vec2(1.0, 0.0)), f.x), mix(h1(i + vec2(0.0, 1.0)), h1(i + vec2(1.0, 1.0)), f.x), f.y);
}
float waves(vec2 p, float t) {
	return n2(p * 0.45 + vec2(t * 0.22, t * 0.1)) * 0.55 + n2(p * 1.3 - vec2(t * 0.25, -t * 0.3)) * 0.3 + n2(p * 3.4 + vec2(-t * 0.4, t * 0.5)) * 0.15;
}
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = wp.xz;
	float t = TIME;
	float d = length(p - center) - shore;
	float w = waves(p, t);
	float e = 0.35;
	float wx = waves(p + vec2(e, 0.0), t) - w;
	float wz = waves(p + vec2(0.0, e), t) - w;
	float near = clamp(1.0 - length(VERTEX) / 140.0, 0.0, 1.0);
	NORMAL_MAP = vec3(0.5 - wx * 2.2 * near, 0.5 - wz * 2.2 * near, 1.0);
	vec3 col = mix(shallow, deep, smoothstep(-2.0, 38.0, d));
	col *= 0.9 + w * 0.22;
	// Foam: a ragged white edge at the waterline and a few lines rolling in behind it.
	float rag = n2(p * 0.9 + vec2(t * 0.15, 0.0)) * 1.6;
	float edge = 1.0 - smoothstep(0.0, 1.5, d + rag - sin(t * 0.8) * 0.5);
	float roll = smoothstep(0.82, 1.0, sin(d * 1.15 - t * 0.9 + rag * 2.0)) * (1.0 - smoothstep(1.0, 11.0, d));
	float foam = clamp(edge + roll * (0.4 + 0.6 * n2(p * 2.5 + t * 0.3)), 0.0, 1.0);
	col = mix(col, vec3(0.96, 0.99, 1.0), foam * 0.9);
	ALBEDO = col * lum;
	ROUGHNESS = mix(0.07, 0.6, foam);
	METALLIC = 0.15;
	SPECULAR = 0.8;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("shore", shore)
	m.set_shader_parameter("center", center)
	_water_mats.append(m)
	return m


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
const TREE_KINDS := ["tree", "sakura", "palm"]
## Models that are meant to shine. Everything else (buildings, benches, trees) is matte: the
## shiny patches these models sometimes come with only make reflections crawl and sparkle.
const SHINY_PROPS := ["kei_car", "sedan", "motorcycle", "vending", "arcade_cabinet", "holo_pylon", "ferry"]
var _tree_spots: Array[Vector3] = []
static var _matte_done := {}
static var _sway_shader: Shader
static var _sway_mats := {}


## No two trees in the same spot.
func _tree_fits(pos: Vector3, gap := 3.2) -> bool:
	for t in _tree_spots:
		if Vector2(t.x - pos.x, t.z - pos.z).length() < gap:
			return false
	_tree_spots.append(pos)
	return true


func _matte(name: String, inst: Node) -> void:
	if _matte_done.has(name) or name in SHINY_PROPS:
		return
	_matte_done[name] = true
	for mi in Avatars._meshes(inst):
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(i) as BaseMaterial3D
			if m == null:
				continue
			m.metallic = 0.0
			m.metallic_texture = null
			m.roughness_texture = null
			m.roughness = 0.82
			m.metallic_specular = 0.35
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC


## Trees move a little in the wind, let some light through their leaves and keep a trace of
## their color at night instead of going grey.
func _sway(inst: Node) -> void:
	if _sway_shader == null:
		_sway_shader = Shader.new()
		_sway_shader.code = """
shader_type spatial;
render_mode world_vertex_coords;
uniform sampler2D tex : source_color, filter_linear_mipmap_anisotropic;
uniform float night_lift = 0.0;
void vertex() {
	float h = max(VERTEX.y - NODE_POSITION_WORLD.y - 1.2, 0.0);
	float ph = NODE_POSITION_WORLD.x * 0.7 + NODE_POSITION_WORLD.z * 0.5;
	float w = sin(TIME * 1.1 + ph) * 0.6 + sin(TIME * 2.3 + ph * 1.7 + VERTEX.x * 0.8) * 0.4;
	VERTEX.x += w * 0.014 * h;
	VERTEX.z += cos(TIME * 0.9 + ph + VERTEX.z * 0.5) * 0.009 * h;
}
void fragment() {
	vec4 t = texture(tex, UV);
	ALBEDO = t.rgb;
	ROUGHNESS = 0.9;
	SPECULAR = 0.12;
	BACKLIGHT = t.rgb * 0.3;
	EMISSION = t.rgb * night_lift;
}
"""
	for mi in Avatars._meshes(inst):
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(i) as BaseMaterial3D
			if m == null or m.albedo_texture == null:
				continue
			var sm: ShaderMaterial = _sway_mats.get(m)
			if sm == null:
				sm = ShaderMaterial.new()
				sm.shader = _sway_shader
				sm.set_shader_parameter("tex", m.albedo_texture)
				_sway_mats[m] = sm
			mi.set_surface_override_material(i, sm)
			if not _tree_mats.has(sm):
				_tree_mats.append(sm)


func prop(name: String, pos: Vector3, rot: float, size: float, by_height := false, parent: Node3D = null) -> Node3D:
	if not has_model(name):
		return null
	if name in TREE_KINDS and parent == null and not _tree_fits(pos):
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
		_matte(name, inst)
	if name in TREE_KINDS:
		_sway(inst)
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
	if parent == null and not (name in TREE_KINDS) and pos.y < 0.6:
		# Nothing grows under a building or a bench.
		var foot := box.size * k
		var square: bool = absf(sin(rot * 2.0)) > 0.2
		var fx: float = maxf(foot.x, foot.z) if square else (foot.z if absf(sin(rot)) > 0.7 else foot.x)
		var fz: float = maxf(foot.x, foot.z) if square else (foot.x if absf(sin(rot)) > 0.7 else foot.z)
		if fx * fz > 0.6:
			no_grass.append(Rect2(pos.x - fx / 2.0, pos.z - fz / 2.0, fx, fz))
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


# ------------------------------------------------------------------ many boxes, one mesh

## Hundreds of small boxes (railings, ledges, pipes, sills) built into a single mesh with one
## surface per material, so a detailed building costs a handful of draw calls instead of one per
## box.
class BoxBatch:
	var tools := {}          # Material -> SurfaceTool
	const FACES := [
		[Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)], [Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)],
		[Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(1, 0, 0)], [Vector3(0, -1, 0), Vector3(0, 0, -1), Vector3(1, 0, 0)],
		[Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)], [Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0)],
	]

	func add(size: Vector3, pos: Vector3, m: Material, basis := Basis.IDENTITY) -> void:
		var st: SurfaceTool = tools.get(m)
		if st == null:
			st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			tools[m] = st
		var h := size / 2.0
		for f in FACES:
			var n: Vector3 = f[0]
			var a: Vector3 = f[1]
			var b: Vector3 = f[2]
			var c := n * h
			var ua := a * h
			var ub := b * h
			var quad := [c - ua - ub, c + ua - ub, c + ua + ub, c - ua + ub]
			var wn := (basis * n).normalized()
			for i in [0, 2, 1, 0, 3, 2]:
				st.set_normal(wn)
				st.add_vertex(pos + basis * (quad[i] as Vector3))

	func commit(parent: Node3D, see := 0.0) -> MeshInstance3D:
		if tools.is_empty():
			return null
		var mesh := ArrayMesh.new()
		for m in tools:
			(tools[m] as SurfaceTool).commit(mesh)
			mesh.surface_set_material(mesh.get_surface_count() - 1, m)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		if see > 0.0:
			mi.visibility_range_end = see
			mi.visibility_range_end_margin = 6.0
		parent.add_child(mi)
		return mi


# ------------------------------------------------------------------ the plank dorm

## A two-storey plank house with a tiled gable roof: common room below, a row of bedrooms above
## that open onto an outside walkway, and an outside staircase up to it. Built in its own space
## (front faces +Z, the staircase comes down on the +X side) so it can be turned any way. With
## `walkable` everything you can stand on or bump into is solid: walk up the stairs, along the
## walkway, up to the doors. Returns the holder; its "upper_doors" meta lists where the bedroom
## doors are in the world, as [floor point, outward direction].
func plank_dorm(at: Vector3, yaw: float, trim: Color, walkable := true) -> Node3D:
	var h := Node3D.new()
	h.position = at
	h.rotation.y = yaw
	add_child(h)
	var wall := surf("wood", Color(0.62, 0.45, 0.3))
	var dark := surf("wood", Color(0.36, 0.25, 0.17))
	var deck := surf("wood", Color(0.5, 0.37, 0.25))
	var roof_m := surf("roof", trim.darkened(0.18))
	var paint := mat(trim, 0.8)
	var glass := glow_mat(Color(1.0, 0.86, 0.6), 0.5)
	var W := 13.0
	var D := 6.0
	var F := 3.0                      # height of one floor
	var walk := 1.6                   # depth of the walkway
	var zf := D / 2.0                 # the front wall
	var on: bool = walkable and make_solid
	# ---- the house
	box(Vector3(W, F * 2.0, D), Vector3(0, F, 0), wall, false, h)
	_dorm_solid(h, on, Vector3(W, F * 2.0, D), Vector3(0, F, 0))
	box(Vector3(W + 0.1, 0.5, D + 0.1), Vector3(0, 0.25, 0), surf("rock", Color(0.5, 0.48, 0.45)), false, h)
	box(Vector3(W + 0.06, 0.22, D + 0.06), Vector3(0, F, 0), dark, false, h)
	box(Vector3(W + 0.08, 0.3, D + 0.08), Vector3(0, F * 2.0 - 0.15, 0), paint, false, h)
	for cx: float in [-W / 2.0, W / 2.0]:
		for cz: float in [-zf, zf]:
			box(Vector3(0.24, F * 2.0, 0.24), Vector3(cx, F, cz), dark, false, h)
	# Roof: one long prism over the house and the walkway, a plank gable showing at each end.
	var span := D + walk + 1.2
	var rise := 2.3
	var rz := walk / 2.0
	var pm := PrismMesh.new()
	pm.size = Vector3(span, rise, W + 0.9)
	var roof := MeshInstance3D.new()
	roof.mesh = pm
	roof.material_override = roof_m
	roof.rotation.y = PI / 2.0
	roof.position = Vector3(0, F * 2.0 + rise / 2.0 + 0.04, rz)
	h.add_child(roof)
	# The gable ends poke out a hand's width so the planks show under the tiles.
	for sx: float in [-1.0, 1.0]:
		var gm := PrismMesh.new()
		gm.size = Vector3(span - 1.0, rise - 0.35, 0.12)
		var g := MeshInstance3D.new()
		g.mesh = gm
		g.material_override = dark
		g.rotation.y = PI / 2.0
		g.position = Vector3(sx * (W / 2.0 + 0.47), F * 2.0 + (rise - 0.35) / 2.0, rz)
		h.add_child(g)
	box(Vector3(W + 1.0, 0.16, 0.16), Vector3(0, F * 2.0 + rise + 0.04, rz), dark, false, h)
	# ---- the walkway and what holds it up
	var wz := zf + walk / 2.0
	box(Vector3(W, 0.16, walk), Vector3(0, F - 0.08, wz), deck, false, h)
	_dorm_solid(h, on, Vector3(W, 0.16, walk), Vector3(0, F - 0.08, wz))
	box(Vector3(W, 0.22, 0.14), Vector3(0, F - 0.2, zf + walk - 0.07), dark, false, h)
	for k in 5:
		var px := -W / 2.0 + 0.2 + k * (W - 0.4) / 4.0
		box(Vector3(0.18, F * 2.0 - 0.1, 0.18), Vector3(px, F - 0.05, zf + walk - 0.1), dark, false, h)
		_dorm_solid(h, on, Vector3(0.2, F - 0.2, 0.2), Vector3(px, (F - 0.2) / 2.0, zf + walk - 0.1))
		var brace := box(Vector3(0.1, 0.1, 0.9), Vector3(px, F - 0.5, zf + walk - 0.45), dark, false, h)
		brace.rotation.x = 0.75
	# Railing along the front and across the far end; open at the stairs end.
	var rail_z := zf + walk - 0.08
	box(Vector3(W, 0.09, 0.09), Vector3(0, F + 1.0, rail_z), dark, false, h)
	box(Vector3(W, 0.06, 0.06), Vector3(0, F + 0.5, rail_z), dark, false, h)
	for k in 27:
		box(Vector3(0.05, 1.0, 0.05), Vector3(-W / 2.0 + 0.1 + k * (W - 0.2) / 26.0, F + 0.5, rail_z), dark, false, h)
	_dorm_solid(h, on, Vector3(W, 1.15, 0.1), Vector3(0, F + 0.575, rail_z))
	box(Vector3(0.09, 0.09, walk), Vector3(-W / 2.0 + 0.05, F + 1.0, wz), dark, false, h)
	_dorm_solid(h, on, Vector3(0.1, 1.15, walk), Vector3(-W / 2.0 + 0.05, F + 0.575, wz))
	# ---- the outside stairs, down the +X side
	var run := 4.7
	var x0 := W / 2.0
	var steps := 16
	var slope := atan2(F, run)
	var length := sqrt(run * run + F * F)
	for i in steps:
		var t := (i + 0.5) / steps
		box(Vector3(run / steps + 0.05, 0.07, walk - 0.1), Vector3(x0 + run * (1.0 - t), F * t + F / steps / 2.0 - 0.035, wz), deck, false, h)
	for sz2: float in [zf + 0.06, zf + walk - 0.06]:
		var stringer := box(Vector3(length, 0.32, 0.1), Vector3(x0 + run / 2.0, F / 2.0 - 0.14, sz2), dark, false, h)
		stringer.rotation.z = -slope
		var hand := box(Vector3(length, 0.08, 0.08), Vector3(x0 + run / 2.0, F / 2.0 + 0.98, sz2), dark, false, h)
		hand.rotation.z = -slope
		for i in range(0, steps + 1, 3):
			var t2 := float(i) / steps
			box(Vector3(0.06, 1.0, 0.06), Vector3(x0 + run * (1.0 - t2), F * t2 + 0.5, sz2), dark, false, h)
		# A wall each side from the ground up to the handrail, stepped, so you can't slip
		# off the edge or walk in underneath.
		for k in 5:
			var xa := x0 + run * float(k) / 5.0
			var xb := x0 + run * float(k + 1) / 5.0
			var top_y := F * (1.0 - float(k) / 5.0) + 1.15
			_dorm_solid(h, on, Vector3(xb - xa, top_y, 0.1), Vector3((xa + xb) / 2.0, top_y / 2.0, sz2))
	# What you walk on: one smooth ramp under the steps.
	_dorm_solid(h, on, Vector3(length + 0.3, 0.2, walk), Vector3(x0 + run / 2.0, F / 2.0 - 0.1 * cos(slope), wz), Vector3(0, 0, -slope))
	_dorm_solid(h, on, Vector3(0.12, F - 0.3, walk), Vector3(x0 + 0.06, (F - 0.3) / 2.0, wz))
	for k in 2:
		box(Vector3(0.16, F * (0.5 - k * 0.0), 0.16), Vector3(x0 + run * 0.5, F * 0.25, zf + 0.1 + k * (walk - 0.2)), dark, false, h)
	# ---- doors and windows
	var ups: Array = []
	var xf := h.transform
	var out := xf.basis * Vector3(0, 0, 1)
	for i in 4:
		var dx := -W / 2.0 + 1.75 + i * 3.17
		box(Vector3(1.24, 2.3, 0.1), Vector3(dx, F + 1.15, zf + 0.03), dark, false, h)
		box(Vector3(1.0, 2.1, 0.08), Vector3(dx, F + 1.05, zf + 0.07), mat(trim.darkened(0.3), 0.7), false, h)
		box(Vector3(0.8, 0.8, 0.03), Vector3(dx, F + 1.5, zf + 0.115), mat(trim.darkened(0.42), 0.7), false, h)
		box(Vector3(0.8, 0.7, 0.03), Vector3(dx, F + 0.55, zf + 0.115), mat(trim.darkened(0.42), 0.7), false, h)
		box(Vector3(0.05, 0.14, 0.07), Vector3(dx + 0.38, F + 1.05, zf + 0.14), mat(Color(0.86, 0.7, 0.32), 0.3, 0.8), false, h)
		box(Vector3(0.3, 0.2, 0.03), Vector3(dx, F + 2.42, zf + 0.07), mat(Color(0.94, 0.9, 0.8), 0.8), false, h)
		box(Vector3(0.22, 0.26, 0.2), Vector3(dx - 0.85, F + 2.1, zf + 0.14), glow_mat(Color(1.0, 0.84, 0.58), 1.4), false, h)
		ups.append([xf * Vector3(dx, F, zf), out])
		# A window beside each door.
		var wx := dx + 1.5
		if wx < W / 2.0 - 0.6:
			_plank_window(h, Vector3(wx, F + 1.55, zf), dark, glass, 0.95, 1.05)
	for sx: float in [-1.0, 1.0]:
		for k in 2:
			_plank_window(h, Vector3(sx * (2.6 + k * 2.5), 1.75, zf), dark, glass, 1.2, 1.3)
		for fy: float in [1.75, F + 1.55]:
			var side_w := _plank_window(h, Vector3(sx * W / 2.0, fy, -0.6), dark, glass, 1.1, 1.2)
			side_w.rotation.y = sx * PI / 2.0
	for k in 4:
		_plank_window(h, Vector3(-4.8 + k * 3.2, F + 1.55, -zf), dark, glass, 1.0, 1.1).rotation.y = PI
		_plank_window(h, Vector3(-4.8 + k * 3.2, 1.75, -zf), dark, glass, 1.0, 1.1).rotation.y = PI
	# The front door: a double door under a little porch roof in the dorm's color.
	box(Vector3(2.5, 2.7, 0.12), Vector3(0, 1.35, zf + 0.03), dark, false, h)
	for sx: float in [-1.0, 1.0]:
		box(Vector3(1.02, 2.4, 0.08), Vector3(sx * 0.53, 1.2, zf + 0.08), mat(trim.darkened(0.25), 0.7), false, h)
		box(Vector3(0.7, 0.9, 0.03), Vector3(sx * 0.53, 1.75, zf + 0.125), glass, false, h)
		box(Vector3(0.05, 0.4, 0.07), Vector3(sx * 0.1, 1.2, zf + 0.15), mat(Color(0.86, 0.7, 0.32), 0.3, 0.8), false, h)
	box(Vector3(3.2, 0.5, 0.06), Vector3(0, F - 0.55, zf + walk - 0.16), paint, false, h)
	h.set_meta("upper_doors", ups)
	h.set_meta("size", Vector3(W, F * 2.0 + rise, D + walk))
	h.set_meta("front", [xf * Vector3(0, 0, zf), out])
	var c := xf * Vector3(run / 2.0, 0, walk / 2.0)
	var fx: float = (W + run + 1.0) if absf(sin(yaw)) < 0.7 else (D + walk + 1.0)
	var fz: float = (D + walk + 1.0) if absf(sin(yaw)) < 0.7 else (W + run + 1.0)
	no_grass.append(Rect2(c.x - fx / 2.0, c.z - fz / 2.0, fx, fz))
	return h


func _dorm_solid(h: Node3D, on: bool, size: Vector3, pos: Vector3, rot := Vector3.ZERO) -> void:
	if not on:
		return
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	body.add_child(cs)
	body.position = pos
	body.rotation = rot
	h.add_child(body)


func _plank_window(h: Node3D, at: Vector3, frame: Material, glass: Material, w: float, ht: float) -> Node3D:
	var n := Node3D.new()
	n.position = at
	h.add_child(n)
	box(Vector3(w + 0.2, ht + 0.2, 0.1), Vector3(0, 0, 0.03), frame, false, n)
	box(Vector3(w, ht, 0.04), Vector3(0, 0, 0.07), glass, false, n)
	box(Vector3(0.05, ht, 0.05), Vector3(0, 0, 0.1), frame, false, n)
	box(Vector3(w, 0.05, 0.05), Vector3(0, 0.05, 0.1), frame, false, n)
	box(Vector3(w + 0.36, 0.07, 0.2), Vector3(0, -ht / 2.0 - 0.12, 0.1), frame, false, n)
	return n


# ------------------------------------------------------------------ ground detail

## Tufts of grass, small flowers and pebbles over a round patch of lawn. They stay off anything
## paved or built on (`no_grass`), thin out with the "Ground detail" setting, and are split into
## chunks so only the ones near you are drawn.
func scatter_detail(center: Vector2, radius: float, y: float, bright := 1.0, seed := 77) -> void:
	var level := int(Settings.gfx.get("detail", 2))
	if level <= 0:
		return
	var per_m2: float = [0.0, 0.8, 1.7, 3.0][clampi(level, 0, 3)]
	# What is covered, by 8 m cell, so each point only checks what is near it.
	var grid := {}
	for r in no_grass:
		var g := r.grow(0.12)
		for cx in range(floori(g.position.x / 8.0), floori(g.end.x / 8.0) + 1):
			for cz in range(floori(g.position.y / 8.0), floori(g.end.y / 8.0) + 1):
				var k := Vector2i(cx, cz)
				if not grid.has(k):
					grid[k] = []
				(grid[k] as Array).append(g)
	var tuft := _tuft_mesh()
	var flower := _flower_mesh()
	var pebble := _pebble_mesh()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var chunk := 22.0
	var n := int(ceil(radius / chunk))
	var dark := Color(0.1, 0.27, 0.1) * bright
	var light := Color(0.27, 0.47, 0.14) * bright
	var petals := [Color("ffffff"), Color("ffe066"), Color("ff9ac8"), Color("b79cff"), Color("ff7a5a"), Color("8fd3ff")]
	for ix in range(-n, n):
		for iz in range(-n, n):
			var c0 := center + Vector2(ix * chunk, iz * chunk)
			if (c0 + Vector2(chunk, chunk) * 0.5 - center).length() > radius + chunk * 0.7:
				continue
			var tufts: Array = []
			var flowers: Array = []
			var pebbles: Array = []
			var want := int(chunk * chunk * per_m2)
			for i in want:
				var p := c0 + Vector2(rng.randf() * chunk, rng.randf() * chunk)
				if (p - center).length() > radius:
					continue
				var blocked := false
				for r in grid.get(Vector2i(floori(p.x / 8.0), floori(p.y / 8.0)), []):
					if (r as Rect2).has_point(p):
						blocked = true
						break
				if blocked:
					continue
				var roll := rng.randf()
				var xf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(p.x, y, p.y))
				if roll < 0.86:
					var sc := rng.randf_range(0.7, 1.5)
					tufts.append([xf.scaled_local(Vector3(sc, sc * rng.randf_range(0.7, 1.3), sc)), dark.lerp(light, rng.randf())])
				elif roll < 0.965:
					var sf := rng.randf_range(0.8, 1.3)
					flowers.append([xf.scaled_local(Vector3(sf, sf, sf)), petals[rng.randi() % petals.size()]])
				else:
					var sp := rng.randf_range(0.5, 1.6)
					pebbles.append([xf.scaled_local(Vector3(sp, sp * rng.randf_range(0.4, 0.7), sp * rng.randf_range(0.7, 1.2))), Color(0.5, 0.5, 0.5).lerp(Color(0.72, 0.7, 0.66), rng.randf())])
			var mid := Vector3(c0.x + chunk / 2.0, y, c0.y + chunk / 2.0)
			_detail_chunk(tuft, tufts, mid, 62.0)
			_detail_chunk(flower, flowers, mid, 48.0)
			_detail_chunk(pebble, pebbles, mid, 40.0)


func _detail_chunk(mesh: Mesh, items: Array, mid: Vector3, see: float) -> void:
	if items.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = items.size()
	for i in items.size():
		var xf: Transform3D = items[i][0]
		xf.origin -= mid
		mm.set_instance_transform(i, xf)
		mm.set_instance_color(i, items[i][1])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.position = mid
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = see
	mi.visibility_range_end_margin = 4.0
	add_child(mi)


static var _detail_meshes := {}


func _crossed_quads(w: float, h: float, shader_code: String, key: String) -> Mesh:
	if _detail_meshes.has(key):
		return _detail_meshes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for a in [0.0, PI / 2.0]:
		var dx := cos(a) * w / 2.0
		var dz := sin(a) * w / 2.0
		var pts := [Vector3(-dx, 0, -dz), Vector3(dx, 0, dz), Vector3(dx, h, dz), Vector3(-dx, h, -dz)]
		var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		for i in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.set_uv(uvs[i])
			st.add_vertex(pts[i])
	var mesh := st.commit()
	var sh := Shader.new()
	sh.code = shader_code
	var m := ShaderMaterial.new()
	m.shader = sh
	mesh.surface_set_material(0, m)
	_detail_meshes[key] = mesh
	return mesh


func _tuft_mesh() -> Mesh:
	return _crossed_quads(0.46, 0.25, """
shader_type spatial;
render_mode cull_disabled, shadows_disabled;
varying float tip;
void vertex() {
	tip = 1.0 - UV.y;
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.x += sin(TIME * 1.6 + w.x * 0.9 + w.z * 0.6) * 0.035 * tip;
	NORMAL = vec3(0.0, 1.0, 0.0);
}
float h1(float p) { return fract(sin(p * 127.1) * 43758.5453); }
void fragment() {
	// Seven blades, each its own height and lean, tapering to a point.
	float a = 0.0;
	for (int i = 0; i < 7; i++) {
		float fi = float(i);
		float cx = (fi + 0.5) / 7.0 + (h1(fi) - 0.5) * 0.08;
		float top = 0.45 + h1(fi + 7.0) * 0.55;
		float t = (1.0 - UV.y) / top;
		float lean = (h1(fi + 3.0) - 0.5) * 0.22 * t * t;
		float half_w = 0.05 * (1.0 - t);
		a = max(a, step(abs(UV.x - cx - lean), half_w) * step(t, 1.0));
	}
	if (a < 0.5) { discard; }
	ALBEDO = COLOR.rgb * mix(0.8, 1.18, tip);
	// Lit like the lawn it grows from, whichever side of the blade faces you.
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
}
""", "tuft")


func _flower_mesh() -> Mesh:
	return _crossed_quads(0.2, 0.3, """
shader_type spatial;
render_mode cull_disabled, shadows_disabled;
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.x += sin(TIME * 1.4 + w.x * 1.1 + w.z * 0.7) * 0.03 * (1.0 - UV.y);
	NORMAL = vec3(0.0, 1.0, 0.0);
}
void fragment() {
	vec2 p = UV - vec2(0.5, 0.26);
	p.y *= 0.67;
	float r = length(p);
	float petal = step(r, 0.2 + 0.05 * cos(atan(p.y, p.x) * 5.0));
	float heart = step(r, 0.06);
	float stem = step(abs(UV.x - 0.5), 0.035) * step(0.3, UV.y);
	if (petal + stem < 0.5) { discard; }
	vec3 c = mix(vec3(0.2, 0.42, 0.14), COLOR.rgb, petal);
	c = mix(c, vec3(1.0, 0.8, 0.2), heart);
	ALBEDO = c;
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ROUGHNESS = 0.9;
}
""", "flower")


func _pebble_mesh() -> Mesh:
	if _detail_meshes.has("pebble"):
		return _detail_meshes["pebble"]
	var sm := SphereMesh.new()
	sm.radius = 0.11
	sm.height = 0.2
	sm.radial_segments = 7
	sm.rings = 4
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.9
	sm.material = m
	_detail_meshes["pebble"] = sm
	return sm


## A boulder: a ball pushed about by noise, flat-shaded so it has chiselled faces. `size` is its
## rough width, height and depth. Used in clusters for cliffs and sea rocks.
func rock(pos: Vector3, size: Vector3, m: Material, seed := 1, rot := 0.0) -> MeshInstance3D:
	var fn := FastNoiseLite.new()
	fn.seed = seed
	fn.frequency = 0.9
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var rings := 6
	var segs := 9
	var pts: Array = []
	for r in rings + 1:
		var row: Array = []
		var v := float(r) / rings
		for sgi in segs:
			var u := float(sgi) / segs
			var d := Vector3(sin(v * PI) * cos(u * TAU), cos(v * PI), sin(v * PI) * sin(u * TAU))
			var k := 1.0 + fn.get_noise_3dv(d * 1.6) * 0.42 + fn.get_noise_3dv(d * 4.0) * 0.12
			var p := d * k
			p.y = maxf(p.y, -0.55)          # sits flat on the ground
			row.append(p * size * 0.5)
		pts.append(row)
	for r in rings:
		for sgi in segs:
			var a: Vector3 = pts[r][sgi]
			var b: Vector3 = pts[r][(sgi + 1) % segs]
			var c: Vector3 = pts[r + 1][sgi]
			var d2: Vector3 = pts[r + 1][(sgi + 1) % segs]
			for v3 in [a, b, c, b, d2, c]:
				st.add_vertex(v3)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	mi.position = pos
	mi.rotation.y = rot
	add_child(mi)
	return mi


# ------------------------------------------------------------------ environment

func _build_env() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	var sky := Sky.new()
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = _sky_shader()
	sky.radiance_size = Sky.RADIANCE_SIZE_128
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
	env.fog_sky_affect = 0.15
	env.fog_aerial_perspective = 0.5
	env.volumetric_fog_density = 0.0035
	env.volumetric_fog_anisotropy = 0.6
	env.volumetric_fog_length = 80.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.1
	env.adjustment_contrast = 1.04
	Settings.tune_environment(env)
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	Settings.tune_sun(sun)
	add_child(sun)
	Settings.gfx_changed.connect(_on_gfx_changed)


func _on_gfx_changed() -> void:
	Settings.tune_environment(env)
	Settings.tune_sun(sun)


## The sky: a soft gradient, a sun with a halo, drifting-looking cloud banks lit from the sun's
## side, and stars at night. Still (nothing moves in it), so it costs nothing after the first frame.
static var _sky_sh: Shader


func _sky_shader() -> Shader:
	if _sky_sh == null:
		_sky_sh = Shader.new()
		_sky_sh.code = """
shader_type sky;
uniform vec3 top : source_color = vec3(0.2, 0.45, 0.85);
uniform vec3 horizon : source_color = vec3(0.72, 0.86, 0.96);
uniform vec3 ground : source_color = vec3(0.35, 0.38, 0.44);
uniform vec3 sun_col : source_color = vec3(1.0, 0.95, 0.85);
uniform vec3 cloud_col : source_color = vec3(1.0);
uniform vec3 cloud_shade : source_color = vec3(0.6, 0.7, 0.82);
uniform float cloud = 0.45;
uniform float stars = 0.0;
float h1(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h1(i), h1(i + vec2(1.0, 0.0)), f.x), mix(h1(i + vec2(0.0, 1.0)), h1(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fbm(vec2 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 5; i++) { v += n2(p) * a; p = p * 2.03 + vec2(13.1, 7.7); a *= 0.5; }
	return v;
}
void sky() {
	vec3 d = normalize(EYEDIR);
	float y = d.y;
	vec3 col = mix(horizon, top, pow(clamp(y, 0.0, 1.0), 0.5));
	if (y < 0.0) {
		col = mix(horizon * 0.9, ground, clamp(-y * 5.0, 0.0, 1.0));
	}
	float sd = 0.0;
	if (LIGHT0_ENABLED) {
		sd = max(dot(d, LIGHT0_DIRECTION), 0.0);
		col += sun_col * (pow(sd, 900.0) * 5.0 + pow(sd, 40.0) * 0.22 + pow(sd, 6.0) * 0.08);
	}
	if (y > 0.0) {
		if (stars > 0.01) {
			vec2 sp = d.xz / (y + 0.35) * 90.0;
			float st = step(0.9965, h1(floor(sp))) * smoothstep(0.02, 0.25, y);
			col += vec3(0.9, 0.95, 1.0) * st * stars * (0.5 + 0.5 * h1(floor(sp) + 3.0));
		}
		vec2 uv = d.xz / (y + 0.16) * 1.1;
		float c = fbm(uv + vec2(4.0, 1.5));
		float wisps = fbm(uv * 2.7 + 11.0);
		float m = smoothstep(1.0 - cloud - 0.08, 1.0 - cloud + 0.2, c * 0.8 + wisps * 0.2 + 0.18);
		vec2 toward = LIGHT0_ENABLED ? LIGHT0_DIRECTION.xz : vec2(0.3, 0.2);
		float lit = clamp((c - fbm(uv + vec2(4.0, 1.5) + toward * 0.22)) * 3.5 + 0.55, 0.0, 1.0);
		vec3 cc = mix(cloud_shade, cloud_col, lit);
		cc += sun_col * pow(sd, 8.0) * 0.25;
		m *= smoothstep(0.0, 0.12, y);
		col = mix(col, cc, m * 0.94);
	}
	COLOR = col;
}
"""
	return _sky_sh


var _tree_mats: Array = []
var _water_mats: Array = []
var _pool_mats: Array = []


## Each world has its own color: the Academy bright and warm, Domino rich with deeper shadows,
## Satellite dusty and drained, the cities of the future clean and cool.
func grade(district_key: String) -> void:
	var g: Array = {"academy": [1.16, 1.04, 1.0], "domino": [1.1, 1.08, 0.98], "satellite": [0.9, 1.1, 0.96],
			"newdomino": [1.06, 1.05, 1.02], "heartland": [1.2, 1.02, 1.04]}.get(district_key, [1.1, 1.04, 1.0])
	env.adjustment_enabled = true
	env.adjustment_saturation = g[0]
	env.adjustment_contrast = g[1]
	env.adjustment_brightness = g[2]


## Light spilling out of a shop front onto the pavement: a soft pool that fades with distance
## from the window, lit only when the windows are.
func light_pool(at: Vector3, width: float, depth: float, col: Color, yaw := 0.0) -> void:
	var sh: Shader
	if has_meta("pool_shader"):
		sh = get_meta("pool_shader")
	else:
		sh = Shader.new()
		sh.code = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled, cull_disabled;
uniform vec3 tint : source_color = vec3(1.0, 0.8, 0.5);
uniform float power = 1.0;
void fragment() {
	float along = 1.0 - smoothstep(0.25, 0.5, abs(UV.x - 0.5));
	float outw = pow(1.0 - UV.y, 1.6);
	ALBEDO = tint;
	ALPHA = along * outw * 0.42 * power;
}
"""
		set_meta("pool_shader", sh)
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("tint", col)
	var q := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(width, depth)
	q.mesh = pm
	q.material_override = m
	q.position = at
	q.rotation.y = yaw
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(q)
	_pool_mats.append(m)


func apply_tod(t: String) -> void:
	tod = t if TOD_LOOK.has(t) else "night"
	var L: Dictionary = TOD_LOOK[tod]
	var accent: Color = theme.get("accent", Color.CYAN)
	sky_mat.set_shader_parameter("top", L["top"])
	sky_mat.set_shader_parameter("horizon", L["horizon"])
	sky_mat.set_shader_parameter("ground", L["ground"])
	sky_mat.set_shader_parameter("sun_col", L["sun"])
	sky_mat.set_shader_parameter("cloud", L["cloud"])
	sky_mat.set_shader_parameter("cloud_col", L["cloud_col"])
	sky_mat.set_shader_parameter("cloud_shade", L["cloud_shade"])
	sky_mat.set_shader_parameter("stars", L["stars"])
	sun.shadow_opacity = L["shadow"]
	for tm in _tree_mats:
		(tm as ShaderMaterial).set_shader_parameter("night_lift", L["lift"])
	for pmat in _pool_mats:
		(pmat as ShaderMaterial).set_shader_parameter("power", L["windows"])
	for wm in _water_mats:
		(wm as ShaderMaterial).set_shader_parameter("lum", {"night": 0.4, "sunset": 0.8}.get(tod, 1.0))
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
	float fw = length(fwidth(wp.xz));
	float grain = mix(0.5, n(wp.xz * 9.0) * 0.5 + n(wp.xz * 31.0) * 0.5, 1.0 - smoothstep(0.02, 0.09, fw));
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
	float fw = max(fwidth(g.x), fwidth(g.y));
	float line = (1.0 - step(0.035, f.x) * step(0.035, f.y)) * (1.0 - smoothstep(0.012, 0.06, fw));
	float v = h(floor(g)) * 0.12 * (1.0 - smoothstep(0.2, 0.6, fw));
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
	float fw = length(fwidth(wp.xz));
	float blades = mix(0.25, n(wp.xz * vec2(60.0, 14.0)) * n(wp.xz * vec2(13.0, 55.0)), 1.0 - smoothstep(0.006, 0.03, fw));
	vec3 dark = vec3(0.09, 0.24, 0.09) * bright;
	vec3 light = vec3(0.24, 0.44, 0.13) * bright;
	vec3 col = mix(dark, light, patch * 0.7 + stripe * 0.12);
	col *= 0.82 + blades * 0.5;
	// A few clover-yellow flecks.
	col += vec3(0.5, 0.45, 0.1) * step(0.985, h(floor(wp.xz * 9.0))) * 0.5 * (1.0 - smoothstep(0.02, 0.08, fw));
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
	// How much wall one pixel covers. Detail finer than that is faded out instead of being
	// left to sparkle and crawl as the camera moves.
	float fw = max(fwidth(u), fwidth(wp.y));
	float fine = 1.0 - smoothstep(0.02, 0.07, fw);
	float mid = 1.0 - smoothstep(0.05, 0.18, fw);
	vec3 col = wall.rgb;
	// Brick/concrete texture: running bond for style 0, panels for style 1
	vec2 b = vec2(u / (style > 0.5 ? 1.6 : 0.5), wp.y / (style > 0.5 ? 1.2 : 0.25));
	b.x += style > 0.5 ? 0.0 : step(1.0, mod(floor(b.y), 2.0)) * 0.5;
	vec2 bf = fract(b);
	float mortar = (1.0 - step(0.06, bf.x) * step(0.08, bf.y)) * fine;
	col *= mix(0.97, (0.9 + h(floor(b)) * 0.18) * mix(1.0, 0.7, mortar), max(fine, mid * 0.5));
	// Floor bands
	float band = step(fract(wp.y / 3.2), 0.07) * mid;
	col = mix(col, wall.rgb * 0.55, band);
	float rough = 0.85;
	float metal = 0.0;
	float hgt = -mortar * 0.25 - band * 0.2;
	vec3 emit = vec3(0.0);
	if (abs(wn.y) < 0.5) {
		if (wp.y < 3.3) {
			// Ground floor: shop windows with a sign strip
			float sx = fract(u / 4.0);
			float pane = step(0.08, sx) * step(sx, 0.92) * step(0.25, wp.y) * step(wp.y, 2.4);
			float strip = step(2.6, wp.y) * step(wp.y, 3.0) * step(0.08, sx) * step(sx, 0.92);
			col = mix(col, vec3(0.05, 0.06, 0.08), pane);
			rough = mix(rough, 0.14, pane);
			metal = pane * 0.2;
			hgt = -pane * 0.6;
			float on = step(0.3, h(floor(vec2(u / 4.0, 3.0))));
			emit += shop.rgb * pane * on * (0.25 + glow_strength * 0.9) * 0.6;
			emit += shop.rgb * strip * (0.2 + glow_strength * 1.6);
			col = mix(col, shop.rgb * 0.5, strip);
			// A striped awning lip over the windows and a dark plinth along the pavement.
			float awn = step(2.4, wp.y) * step(wp.y, 2.6) * step(0.08, sx) * step(sx, 0.92);
			col = mix(col, mix(shop.rgb * 0.8, vec3(0.92), mix(0.5, step(0.5, fract(u / 0.5)), mid)), awn);
			col = mix(col, wall.rgb * 0.4, step(wp.y, 0.25));
			// Window frames, and a door in every third bay.
			float fr = mid * pane * (1.0 - step(0.11, sx) * step(sx, 0.89) * step(0.32, wp.y) * step(wp.y, 2.33));
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
			float pil = step(fract(u / 5.1), 0.07) * mid;
			col = mix(col, wall.rgb * 1.18 + 0.02, pil);
			float wx0 = 0.16; float wx1 = 0.84; float wy0 = 0.24; float wy1 = 0.84;
			// Soft edges one pixel wide, so window outlines never stair-step or twinkle.
			float ax = clamp(fwidth(g.x), 0.0005, 0.25);
			float ay = clamp(fwidth(g.y), 0.0005, 0.25);
			float open = smoothstep(wx0 - ax, wx0 + ax, f.x) * smoothstep(wx1 + ax, wx1 - ax, f.x) * smoothstep(wy0 - ay, wy0 + ay, f.y) * smoothstep(wy1 + ay, wy1 - ay, f.y);
			float inner = smoothstep(wx0 + 0.045 - ax, wx0 + 0.045 + ax, f.x) * smoothstep(wx1 - 0.045 + ax, wx1 - 0.045 - ax, f.x) * smoothstep(wy0 + 0.03 - ay, wy0 + 0.03 + ay, f.y) * smoothstep(wy1 - 0.03 + ay, wy1 - 0.03 - ay, f.y);
			// Far away, windows melt into the wall instead of flickering.
			float far_fade = 1.0 - smoothstep(0.35, 0.9, max(ax, ay) * 2.0);
			open *= far_fade;
			inner *= far_fade;
			float frame = open * (1.0 - inner);
			float glass = open * inner;
			// Mullions: one down the middle, and on some windows one across.
			float mull = glass * mid * max(step(abs(f.x - 0.5), 0.014), step(abs(f.y - 0.58), 0.011) * step(0.5, h(cell + 9.0)));
			// A sill under every window and the rain streaks below it.
			float sill = step(wx0 - 0.04, f.x) * step(f.x, wx1 + 0.04) * step(wy0 - 0.055, f.y) * step(f.y, wy0) * mid * far_fade;
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
			ac *= mid;
			col = mix(col, vec3(0.74, 0.75, 0.77) * (0.8 + 0.2 * fine * step(0.5, fract(f.y * 60.0))), ac);
			// The glass sits back in the wall: the frame throws a shadow down its top and one side.
			float recess = max(smoothstep(wy1 - 0.1, wy1 - 0.03, f.y), smoothstep(wx0 + 0.11, wx0 + 0.045, f.x) * 0.8);
			col *= 1.0 - 0.42 * recess * glass;
			hgt = frame * 0.9 + sill * 1.3 + pil * 0.5 + mull * 0.5 - glass * 0.7 + ac * 1.6;
			rough = mix(rough, 0.16, glass * (1.0 - blinds));
			metal = mix(metal, 0.25, glass * (1.0 - blinds));
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
	// Relief the light can catch: frames and sills stand proud, glass and mortar sit back.
	vec3 dpx = dFdx(VERTEX);
	vec3 dpy = dFdy(VERTEX);
	vec3 r1 = cross(dpy, NORMAL);
	vec3 r2 = cross(NORMAL, dpx);
	float det = dot(dpx, r1);
	vec3 grad = sign(det) * (dFdx(hgt) * r1 + dFdy(hgt) * r2);
	float fade = clamp(1.0 - length(VERTEX) / 70.0, 0.0, 1.0);
	NORMAL = normalize(abs(det) * NORMAL - 0.03 * fade * grad);
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
	# Street level: a shop on each long side with a canvas awning and a lit name board.
	var names := ["RAMEN", "BOOKS", "DUEL GEAR", "CAFE", "BAKERY", "RECORDS", "FLOWERS", "NOODLES", "TOYS", "TAILOR", "CAMERA", "TEA HOUSE", "BIKES", "CURRY", "COMICS", "HOBBY"]
	var along_x := size.x >= size.z
	for side: float in [-1.0, 1.0]:
		var shop_col: Color = shops[rng.randi() % shops.size()]
		var w := (size.x if along_x else size.z) * 0.72
		var out := (size.z if along_x else size.x) / 2.0
		var c := pos + (Vector3(0, 0, side * out) if along_x else Vector3(side * out, 0, 0))
		var awn := box(Vector3(w, 0.1, 1.1) if along_x else Vector3(1.1, 0.1, w), c + (Vector3(0, 2.72, side * 0.5) if along_x else Vector3(side * 0.5, 2.72, 0)),
			mat(shop_col.darkened(0.25), 0.85), false)
		if along_x:
			awn.rotation.x = side * 0.2
		else:
			awn.rotation.z = -side * 0.2
		var board := box(Vector3(w * 0.7, 0.62, 0.1) if along_x else Vector3(0.1, 0.62, w * 0.7), c + (Vector3(0, 3.55, side * 0.08) if along_x else Vector3(side * 0.08, 3.55, 0)),
			mat(Color(0.08, 0.09, 0.12), 0.6), false)
		board.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var rot := (0.0 if side > 0.0 else PI) if along_x else (PI / 2.0 if side > 0.0 else -PI / 2.0)
		if make_solid and pos.y > -1.0:
			# PlaneMesh UV.y runs along local +Z: turn the pool so its bright edge is at the wall.
			light_pool(c + (Vector3(0, 0.19, side * 1.5) if along_x else Vector3(side * 1.5, 0.19, 0)), w, 3.0, shop_col.lerp(Color(1.0, 0.9, 0.7), 0.5), rot)
		var sign := neon_sign(names[rng.randi() % names.size()], c + (Vector3(0, 3.55, side * 0.15) if along_x else Vector3(side * 0.15, 3.55, 0)), shop_col.lightened(0.3), 44, rot, false)
		sign.pixel_size = 0.008
	if make_solid and pos.y > -1.0:
		_dress_building(pos, size, rng, shops[rng.randi() % shops.size()])
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


## What makes a block of flats look built instead of painted: ledges and a cornice you can see
## the edge of, pilasters between the shop windows, balconies with railings, window awnings, air
## conditioners, drain pipes, a fire escape, and a stair hut and vents on the roof. All of it is
## real geometry lined up with the painted windows, merged into one mesh per building, and only
## drawn when you are near enough to tell.
func _dress_building(pos: Vector3, size: Vector3, rng: RandomNumberGenerator, tint: Color) -> void:
	var batch := BoxBatch.new()
	var stone := mat(Color(0.62, 0.6, 0.57), 0.85)
	var dark := mat(Color(0.14, 0.15, 0.18), 0.5, 0.5)
	var metal := mat(Color(0.7, 0.72, 0.75), 0.4, 0.5)
	var cloth := mat(tint.darkened(0.2), 0.85)
	var slab := mat(Color(0.5, 0.49, 0.47), 0.85)
	var hgt := size.y
	# The four faces: [outward normal, along the wall, half depth, half width]
	var faces := [[Vector3(0, 0, 1), Vector3(1, 0, 0), size.z / 2.0, size.x / 2.0], [Vector3(0, 0, -1), Vector3(1, 0, 0), size.z / 2.0, size.x / 2.0],
			[Vector3(1, 0, 0), Vector3(0, 0, 1), size.x / 2.0, size.z / 2.0], [Vector3(-1, 0, 0), Vector3(0, 0, 1), size.x / 2.0, size.z / 2.0]]
	var escape_face := rng.randi() % 4 if hgt > 13.0 else -1
	for fi in faces.size():
		var n: Vector3 = faces[fi][0]
		var t: Vector3 = faces[fi][1]
		var out: float = faces[fi][2]
		var half: float = faces[fi][3]
		var basis := Basis(t, Vector3.UP, n) if t.cross(Vector3.UP).dot(n) > 0.0 else Basis(-t, Vector3.UP, n)
		var wall := pos + n * out
		var c_along: float = (pos.x if absf(t.x) > 0.5 else pos.z)
		# A ledge over the shops, a string course half way up tall buildings, the cornice.
		batch.add(Vector3(half * 2.0 + 0.5, 0.2, 0.46), wall + Vector3(0, 3.28, 0) + n * 0.2, stone, basis)
		batch.add(Vector3(half * 2.0 + 0.7, 0.34, 0.6), wall + Vector3(0, hgt - 0.3, 0) + n * 0.24, stone, basis)
		batch.add(Vector3(half * 2.0 + 0.5, 0.12, 0.3), wall + Vector3(0, hgt - 0.62, 0) + n * 0.12, slab, basis)
		# Pilasters between the shop windows (the painted bays are 4 m wide).
		var bay := ceili((c_along - half) / 4.0)
		while bay * 4.0 <= c_along + half:
			var u := bay * 4.0 - c_along
			if absf(u) < half - 0.15:
				batch.add(Vector3(0.36, 3.2, 0.2), wall + t * u + Vector3(0, 1.6, 0) + n * 0.09, stone, basis)
				batch.add(Vector3(0.46, 0.22, 0.26), wall + t * u + Vector3(0, 0.11, 0) + n * 0.12, slab, basis)
			bay += 1
		# A drain pipe down one edge.
		batch.add(Vector3(0.1, hgt - 0.5, 0.1), wall + t * (half - 0.35) + Vector3(0, hgt / 2.0 - 0.1, 0) + n * 0.07, dark, basis)
		# Window by window (the painted windows sit on a 1.7 m by 3.2 m grid).
		var col := ceili((c_along - half + 0.5) / 1.7 - 0.5)
		while (col + 0.5) * 1.7 <= c_along + half - 0.5:
			var u2 := (col + 0.5) * 1.7 - c_along
			var kind := rng.randi() % 10          # 0-1 balconies, 2 awnings, the rest plain
			var floor_i := 1
			while (floor_i + 1) * 3.2 < hgt - 0.6:
				var y0 := floor_i * 3.2
				var at := wall + t * u2 + Vector3(0, y0, 0)
				if fi == escape_face and absf(u2) < 1.0:
					# Fire escape: a landing at every floor, a ladder between them, a rail.
					batch.add(Vector3(2.4, 0.07, 0.95), at + Vector3(0, 0.6, 0) + n * 0.5, dark, basis)
					batch.add(Vector3(2.4, 0.05, 0.05), at + Vector3(0, 1.6, 0) + n * 0.95, dark, basis)
					batch.add(Vector3(2.4, 0.04, 0.04), at + Vector3(0, 1.1, 0) + n * 0.95, dark, basis)
					for sx: float in [-1.17, 1.17]:
						batch.add(Vector3(0.05, 1.0, 0.05), at + t * sx + Vector3(0, 1.1, 0) + n * 0.95, dark, basis)
						batch.add(Vector3(0.05, 0.05, 0.9), at + t * sx + Vector3(0, 1.6, 0) + n * 0.5, dark, basis)
					var ladder := Basis(Vector3(1, 0, 0), 0.0)
					batch.add(Vector3(0.06, 3.2, 0.06), at + t * 0.75 + Vector3(0, 2.2, 0) + n * 0.8, dark, basis)
					batch.add(Vector3(0.06, 3.2, 0.06), at + t * 0.3 + Vector3(0, 2.2, 0) + n * 0.8, dark, basis)
					for rung in 8:
						batch.add(Vector3(0.45, 0.04, 0.04), at + t * 0.525 + Vector3(0, 0.8 + rung * 0.4, 0) + n * 0.8, dark, basis * ladder)
				elif kind <= 1 and absf(u2) < half - 1.1:
					# A balcony: slab, three rails, posts and a little something on it.
					batch.add(Vector3(1.5, 0.1, 0.8), at + Vector3(0, 0.66, 0) + n * 0.4, slab, basis)
					for ry: float in [1.15, 1.42, 1.7]:
						batch.add(Vector3(1.5, 0.045, 0.045), at + Vector3(0, ry, 0) + n * 0.78, dark, basis)
					for sx: float in [-0.73, 0.0, 0.73]:
						batch.add(Vector3(0.045, 1.0, 0.045), at + t * sx + Vector3(0, 1.2, 0) + n * 0.78, dark, basis)
					for sx: float in [-0.73, 0.73]:
						batch.add(Vector3(0.045, 0.045, 0.78), at + t * sx + Vector3(0, 1.7, 0) + n * 0.39, dark, basis)
					if rng.randf() < 0.5:
						batch.add(Vector3(0.3, 0.3, 0.3), at + t * 0.45 + Vector3(0, 0.86, 0) + n * 0.5, mat(Color(0.6, 0.36, 0.24), 0.9), basis)
						batch.add(Vector3(0.34, 0.3, 0.34), at + t * 0.45 + Vector3(0, 1.14, 0) + n * 0.5, mat(Color(0.18, 0.42, 0.2), 0.95), basis)
				elif kind == 2:
					# An awning over the window.
					batch.add(Vector3(1.3, 0.05, 0.6), at + Vector3(0, 2.78, 0) + n * 0.28, cloth, basis * Basis(Vector3(1, 0, 0), 0.5))
				else:
					# A sill you can see the edge of, and now and then an air conditioner.
					batch.add(Vector3(1.3, 0.07, 0.16), at + Vector3(0, 0.72, 0) + n * 0.08, stone, basis)
					if rng.randf() < 0.14:
						batch.add(Vector3(0.7, 0.46, 0.4), at + t * 0.2 + Vector3(0, 0.4, 0) + n * 0.2, metal, basis)
						batch.add(Vector3(0.5, 0.3, 0.02), at + t * 0.2 + Vector3(0, 0.4, 0) + n * 0.41, dark, basis)
				floor_i += 1
			col += 1
	# On the roof: the stair hut with its door, two vents and a run of duct.
	var roof := pos + Vector3(0, hgt, 0)
	var hut := roof + Vector3(size.x * 0.18, 1.2, size.z * 0.12)
	batch.add(Vector3(2.4, 2.4, 2.8), hut, stone)
	batch.add(Vector3(2.6, 0.14, 3.0), hut + Vector3(0, 1.26, 0), slab)
	batch.add(Vector3(0.9, 1.9, 0.06), hut + Vector3(0, -0.25, 1.42), dark)
	for k in 2:
		batch.add(Vector3(0.5, 0.7, 0.5), roof + Vector3(-size.x * 0.25 + k * 1.2, 0.35, -size.z * 0.2), metal)
		batch.add(Vector3(0.62, 0.08, 0.62), roof + Vector3(-size.x * 0.25 + k * 1.2, 0.74, -size.z * 0.2), dark)
	batch.add(Vector3(size.x * 0.5, 0.3, 0.3), roof + Vector3(-size.x * 0.1, 0.25, size.z * 0.3), metal)
	batch.commit(self, 110.0)


## The Game Center: our own two-storey arcade. Dark walls, a wide glass front with the glow of
## the cabinets behind it, neon piping, a canopy studded with bulbs, round windows upstairs and
## a big sign on the roof. `pos` is the middle of its footprint, the front faces +Z.
func arcade_building(pos: Vector3, w := 9.0, d := 9.0) -> void:
	var hgt := 8.4
	var body := surf("plaster", Color(0.13, 0.11, 0.24))
	var trim := mat(Color(0.08, 0.07, 0.14), 0.5, 0.3)
	var mint := glow_mat(Color("5affc0"), 2.6)
	var pink := glow_mat(Color("ff5ab4"), 2.6)
	var gold := glow_mat(Color("ffd23a"), 2.4)
	box(Vector3(w, hgt, d), pos + Vector3(0, hgt / 2.0, 0), body)
	var batch := BoxBatch.new()
	var front := pos + Vector3(0, 0, d / 2.0)
	# The glass front: three tall panes either side of the door, cabinets glowing inside.
	var glass := mat(Color(0.05, 0.07, 0.12), 0.1, 0.3)
	var glows := [Color("5affc0"), Color("ff5ab4"), Color("ffd23a"), Color("7cc4ff"), Color("b06bff"), Color("ff8a3a")]
	for i in 6:
		var px := -w / 2.0 + 0.85 + i * (w - 1.7) / 5.0
		if absf(px) < 1.1:
			continue
		batch.add(Vector3(1.25, 2.7, 0.08), front + Vector3(px, 1.6, 0.02), glass)
		batch.add(Vector3(0.7, 1.2, 0.03), front + Vector3(px, 1.2, 0.07), glow_mat(glows[i % glows.size()], 1.3))
		batch.add(Vector3(0.5, 0.36, 0.035), front + Vector3(px, 2.2, 0.07), glow_mat(glows[(i + 2) % glows.size()], 2.0))
		batch.add(Vector3(1.37, 0.08, 0.14), front + Vector3(px, 2.99, 0.05), trim)
		batch.add(Vector3(1.37, 0.12, 0.14), front + Vector3(px, 0.22, 0.05), trim)
		for sx: float in [-0.66, 0.66]:
			batch.add(Vector3(0.07, 2.8, 0.14), front + Vector3(px + sx, 1.6, 0.05), trim)
	# The door, set back under a canopy with a row of bulbs along its edge.
	batch.add(Vector3(2.0, 2.6, 0.1), front + Vector3(0, 1.3, 0.02), mat(Color(0.03, 0.04, 0.08), 0.2, 0.3))
	for sx: float in [-0.5, 0.5]:
		batch.add(Vector3(0.9, 2.3, 0.05), front + Vector3(sx, 1.2, 0.09), mat(Color(0.2, 0.5, 0.6), 0.12, 0.4))
		batch.add(Vector3(0.05, 0.5, 0.06), front + Vector3(sx * 0.2, 1.2, 0.14), mat(Color(0.86, 0.7, 0.32), 0.3, 0.8))
	batch.add(Vector3(4.2, 0.3, 1.9), front + Vector3(0, 3.25, 0.95), trim)
	batch.add(Vector3(4.2, 0.08, 0.08), front + Vector3(0, 3.12, 1.86), mint)
	for i in 11:
		batch.add(Vector3(0.12, 0.12, 0.12), front + Vector3(-1.9 + i * 0.38, 3.02, 1.7), gold if i % 2 == 0 else pink)
	# Neon piping round the building, and round windows upstairs.
	for y: float in [3.5, hgt - 0.5]:
		batch.add(Vector3(w + 0.1, 0.09, 0.09), front + Vector3(0, y, 0.05), mint if y < 4.0 else pink)
		batch.add(Vector3(0.09, 0.09, d + 0.1), pos + Vector3(-w / 2.0 - 0.05, y, 0), mint if y < 4.0 else pink)
		batch.add(Vector3(0.09, 0.09, d + 0.1), pos + Vector3(w / 2.0 + 0.05, y, 0), mint if y < 4.0 else pink)
	for sx: float in [-w / 2.0 - 0.04, w / 2.0 + 0.04]:
		batch.add(Vector3(0.09, hgt - 4.0, 0.09), Vector3(pos.x + sx, 3.5 + (hgt - 4.0) / 2.0, front.z + 0.04), pink)
	batch.commit(self)
	for i in 4:
		var wx := -w / 2.0 + 1.4 + i * (w - 2.8) / 3.0
		var ring := cyl(0.62, 0.62, 0.1, front + Vector3(wx, 5.6, 0.03), trim, null, 20)
		ring.rotation.x = PI / 2.0
		var pane := cyl(0.5, 0.5, 0.12, front + Vector3(wx, 5.6, 0.035), glow_mat(glows[(i * 2 + 1) % glows.size()], 1.0), null, 20)
		pane.rotation.x = PI / 2.0
	# The side that faces the road gets round windows and a tall blade sign too.
	for i in 3:
		var wz := -d / 2.0 + 1.8 + i * (d - 3.6) / 2.0
		var ring2 := cyl(0.62, 0.62, 0.1, pos + Vector3(-w / 2.0 - 0.03, 5.6, wz), trim, null, 20)
		ring2.rotation.z = PI / 2.0
		var pane2 := cyl(0.5, 0.5, 0.12, pos + Vector3(-w / 2.0 - 0.035, 5.6, wz), glow_mat(glows[i * 2 % glows.size()], 1.0), null, 20)
		pane2.rotation.z = PI / 2.0
		box(Vector3(0.08, 2.4, 1.6), pos + Vector3(-w / 2.0 - 0.02, 1.6, wz), glass, false)
		box(Vector3(0.03, 1.0, 0.8), pos + Vector3(-w / 2.0 - 0.07, 1.3, wz), glow_mat(glows[(i + 3) % glows.size()], 1.2), false)
	box(Vector3(0.9, 4.6, 0.24), pos + Vector3(-w / 2.0 - 0.6, 5.4, d / 2.0 - 0.9), trim, false)
	box(Vector3(0.7, 4.3, 0.28), pos + Vector3(-w / 2.0 - 0.6, 5.4, d / 2.0 - 0.9), glow_mat(Color("ff5ab4"), 1.6), false)
	# Roof sign and parapet.
	box(Vector3(w + 0.3, 0.5, 0.3), pos + Vector3(0, hgt + 0.25, d / 2.0), trim, false)
	box(Vector3(w + 0.3, 0.5, 0.3), pos + Vector3(0, hgt + 0.25, -d / 2.0), trim, false)
	box(Vector3(0.3, 0.5, d), pos + Vector3(w / 2.0, hgt + 0.25, 0), trim, false)
	box(Vector3(0.3, 0.5, d), pos + Vector3(-w / 2.0, hgt + 0.25, 0), trim, false)
	box(Vector3(6.4, 1.7, 0.2), pos + Vector3(0, hgt + 1.5, d / 2.0 - 0.6), trim, false)
	for sx: float in [-2.6, 2.6]:
		box(Vector3(0.12, 1.2, 0.12), pos + Vector3(sx, hgt + 0.6, d / 2.0 - 0.6), trim, false)
	neon_sign("GAME CENTER", pos + Vector3(0, hgt + 1.5, d / 2.0 - 0.48), Color("5affc0"), 150, 0.0)
	neon_sign("ARCADE", pos + Vector3(-w / 2.0 - 0.08, 7.3, 0), Color("ffd23a"), 120, -PI / 2)
	var l := OmniLight3D.new()
	l.light_color = Color("5affc0")
	l.light_energy = 2.4
	l.omni_range = 9.0
	l.position = front + Vector3(0, 2.6, 2.2)
	add_child(l)
	_lamp_lights.append(l)
	no_grass.append(Rect2(pos.x - w / 2.0, pos.z - d / 2.0, w, d))


## Domino is a city in the middle of a tournament: poster columns on the corners showing real
## cards, banners on the lamp posts, and a giant screen over the crossing that cycles through
## the cards of the day.
var _screen_mat: StandardMaterial3D
var _screen_ids: Array = []
var _screen_t := 0.0


func _screen_show(id: int) -> void:
	var got := Cards.cover_art(id)
	var tex: Texture2D = got[0]
	if tex == null:
		return
	var region: Rect2 = got[1]
	var ts := tex.get_size()
	_screen_mat.albedo_texture = tex
	_screen_mat.uv1_scale = Vector3(region.size.x / ts.x, region.size.y / ts.y, 1.0)
	_screen_mat.uv1_offset = Vector3(region.position.x / ts.x, region.position.y / ts.y, 0.0)


func _tournament_dressing() -> void:
	var ids: Array = []
	for id in Collection.all_cards():
		var d := CardData.get_card(id)
		if d.get("kind", "") == "monster" and CardData.rarity(id) >= 2:
			ids.append(id)
	if ids.is_empty():
		return
	ids.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = 808
	var iron := mat(Color(0.12, 0.13, 0.16), 0.5, 0.6)
	var k := 0
	for at in [Vector3(-9.2, 0.16, -9.2), Vector3(10.8, 0.16, 15.2), Vector3(-9.4, 0.16, 20.0), Vector3(9.4, 0.16, -22.0), Vector3(-22.0, 0.16, 9.2), Vector3(22.0, 0.16, -9.2)]:
		cyl(0.62, 0.62, 2.9, at + Vector3(0, 1.45, 0), mat(Color(0.86, 0.84, 0.78), 0.8), null, 18)
		cyl(0.72, 0.72, 0.16, at + Vector3(0, 0.08, 0), iron, null, 18)
		cyl(0.76, 0.66, 0.22, at + Vector3(0, 3.0, 0), iron, null, 18)
		cyl(0.0, 0.7, 0.4, at + Vector3(0, 3.3, 0), mat(Color(0.2, 0.4, 0.34), 0.5, 0.4), null, 18)
		solid_cyl(0.66, 3.0, at + Vector3(0, 1.5, 0))
		for f in 3:
			var a := f * TAU / 3.0 + k * 0.4
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = Cards.get_face(ids[rng.randi() % ids.size()])
			pm.roughness = 0.5
			pm.emission_enabled = true
			pm.emission_texture = pm.albedo_texture
			pm.emission_energy_multiplier = 0.25
			var q := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(0.92, 1.34)
			q.mesh = qm
			q.material_override = pm
			q.position = at + Vector3(sin(a) * 0.635, 1.55, cos(a) * 0.635)
			q.rotation.y = a
			q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(q)
		k += 1
	# The big screen, on a frame over the south-west corner, facing the crossing.
	var sp := Vector3(-12.5, 9.5, 12.5)
	var holder := Node3D.new()
	holder.position = sp
	holder.rotation.y = -PI / 4.0 + PI
	add_child(holder)
	box(Vector3(8.6, 5.4, 0.5), Vector3.ZERO, iron, false, holder)
	for sx: float in [-3.6, 3.6]:
		box(Vector3(0.4, 9.5, 0.4), Vector3(sx, -7.4, -0.1), iron, false, holder)
	_screen_mat = StandardMaterial3D.new()
	_screen_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_screen_mat.albedo_color = Color(0.9, 0.9, 0.9)
	_screen_ids = []
	for i in 8:
		_screen_ids.append(ids[rng.randi() % ids.size()])
	_screen_show(_screen_ids[0])
	var q2 := MeshInstance3D.new()
	var qm2 := QuadMesh.new()
	qm2.size = Vector2(4.8, 4.8)
	q2.mesh = qm2
	q2.material_override = _screen_mat
	q2.position = Vector3(-1.7, 0, 0.27)
	q2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(q2)
	box(Vector3(3.2, 4.8, 0.02), Vector3(2.5, 0, 0.26), glow_mat(Color(0.05, 0.08, 0.16), 0.6), false, holder)
	var live := neon_sign("CARD OF\nTHE HOUR", sp + holder.transform.basis * Vector3(2.5, 0.9, 0.3), Color("ffd766"), 90, holder.rotation.y, false)
	live.pixel_size = 0.012
	var tag := neon_sign("BATTLE CITY  ·  LIVE", sp + holder.transform.basis * Vector3(2.5, -1.4, 0.3), Color("ff5a7a"), 60, holder.rotation.y, false)
	tag.pixel_size = 0.009
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.7, 0.8, 1.0)
	glow.light_energy = 2.0
	glow.omni_range = 14.0
	glow.position = sp + holder.transform.basis * Vector3(0, -1.0, 3.0)
	add_child(glow)
	_lamp_lights.append(glow)


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
	arcade_building(Vector3(12.5, 0.16, -16.4), 9.0, 9.0)
	_tournament_dressing()
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
	for t in _tree_spots:
		if Vector2(t.x - p.x, t.z - p.z).length() < 3.2:
			return
	if prop(kind, p + Vector3(0, 0.0, 0), fmod(p.x * 13.0, TAU), 5.2 * s, true):
		solid_cyl(0.35 * s, 3.0, p + Vector3(0, 1.5, 0))
		return
	_tree_spots.append(p)
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
	if _screen_mat and _screen_ids.size() > 1:
		_screen_t += delta
		if _screen_t > 6.0:
			_screen_t = 0.0
			_screen_ids.push_back(_screen_ids.pop_front())
			_screen_show(_screen_ids[0])
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
