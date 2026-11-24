class_name TurboTrack
extends Node3D
## The world of a Turbo Duel: a night highway that never ends, streaking past under the
## holographic field while both duelists ride their runners along it. Everything here is
## set dressing that loops; `speed` (set from the Speed Counters) drives how fast it goes.

const RUNNERS := ["res://assets/models/vehicles/runner_a.glb", "res://assets/models/vehicles/runner_b.glb"]
const SPAN := 160.0          # props wrap around inside this length of road
## What every surface that slides past shares: the distance travelled, the blur of speed, the
## bend of the road, and noise fixed to the road so nothing swims when the speed changes.
const GLSL := """
uniform float offset = 0.0;
uniform float blur = 1.0;
uniform float curve = 0.0;
varying vec3 wp;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
void vertex() {
	// Where this point is on the straight road; the bend is applied after, so the paint and
	// the panels ride round a curve with everything else instead of sliding across it.
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float ahead = max(0.0, wp.x);
	VERTEX.z -= curve * ahead * ahead * 0.0035;
}
"""

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
var trail_scale := 1.0       # how long the light trails behind the runners are


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
	PerfPass.settle(self)      # no two surfaces left lying on top of each other (flicker)
	set_zone("")
	if "--turbo-party" in OS.get_cmdline_user_args():
		# (testing) the road as it is after a win, held, so a still picture shows it.
		celebrate.call_deferred([Color("ff8a3a"), Color("ff5a7a"), Color("ffd84a"), Color("2de2e6"), Color("5affc0")])


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
		_road.set_shader_parameter("indoors", 1.0 if z == "tunnel" else 0.0)
		_glow_base = [ga, gb]


# ------------------------------------------------------------------ the road answers the duel

## A Turbo Duel has no stands: the highway itself reacts. The light strips and the wet shine on
## the road jump to the color of what happened, the lamps flare, the streaks of speed burn
## brighter, and both runners pick up speed for a moment.
var _glow_base: Array = [Color("ff8a3a"), Color("2de2e6")]
var _pulse := 0.0
var _pulse_col := Color.WHITE
var _strobe := 0.0
var _party: Array = []          # colors the road cycles through after a win
var _dim := 1.0
var _lamps: Array = []          # [light, its usual energy, its usual color]
var _line_mats: Array = []      # [material, its usual color]


func react(strength: float, color := Color.WHITE) -> void:
	_pulse = maxf(_pulse, clampf(strength, 0.0, 1.0))
	_pulse_col = color
	if strength >= 0.5:
		target_speed += 4.0
		get_tree().create_timer(1.0).timeout.connect(func(): target_speed -= 4.0)


## The last hit: everything strobes.
func finish(color: Color) -> void:
	react(1.0, color)
	_strobe = 1.8


## You won: the road runs through the colors like a finish line.
func celebrate(colors: Array) -> void:
	_party = colors
	_pulse = 1.0
	target_speed += 6.0


## You lost: the lights go low and the road slows.
func hush() -> void:
	_dim = 0.45
	_pulse = 0.0
	_strobe = 0.0
	target_speed = maxf(14.0, target_speed - 8.0)


func _react_step(delta: float) -> void:
	if _lamps.is_empty() and _line_mats.is_empty():
		# Found once: the lamps over the road and the streaks of speed.
		for p in _props:
			for l in (p[0] as Node).find_children("*", "OmniLight3D", true, false):
				_lamps.append([l, (l as OmniLight3D).light_energy, (l as OmniLight3D).light_color])
		for l in _lines:
			var m := (l[0] as MeshInstance3D).material_override as StandardMaterial3D
			if m:
				_line_mats.append([m, m.albedo_color])
	if _pulse <= 0.0 and _strobe <= 0.0 and _party.is_empty() and is_equal_approx(_dim_now, _dim):
		return
	_pulse = maxf(0.0, _pulse - delta * (0.25 if not _party.is_empty() else 1.3))
	_strobe = maxf(0.0, _strobe - delta)
	_dim_now = move_toward(_dim_now, _dim, delta * 0.6)
	var col := _pulse_col
	if not _party.is_empty():
		var k := _t * 2.2
		col = (_party[int(k) % _party.size()] as Color).lerp(_party[(int(k) + 1) % _party.size()], fmod(k, 1.0))
		_pulse = maxf(_pulse, 0.75)
	var flash := 1.0 if (_strobe > 0.0 and fmod(_strobe, 0.14) > 0.07) else 0.0
	var k2 := clampf(_pulse * 0.85 + flash * 0.5, 0.0, 1.0)
	if _road:
		_road.set_shader_parameter("flash_col", col)
		_road.set_shader_parameter("flash", clampf(_pulse * 0.8 + flash * 0.4, 0.0, 1.0) * (0.55 if not _party.is_empty() else 1.0) * _dim_now)
		_road.set_shader_parameter("glow_a", ((_glow_base[0] as Color).lerp(col * 1.5, k2)) * _dim_now)
		_road.set_shader_parameter("glow_b", ((_glow_base[1] as Color).lerp(col * 1.5, k2)) * _dim_now)
	for e in _lamps:
		var l: OmniLight3D = e[0]
		if is_instance_valid(l):
			l.light_energy = float(e[1]) * (1.0 + 1.6 * _pulse + 2.0 * flash) * _dim_now
			l.light_color = (e[2] as Color).lerp(col, minf(1.0, _pulse * 0.8))
	for e in _line_mats:
		# The streaks of speed take the color of what happened and burn brighter.
		var base: Color = e[1]
		var lit := base.lerp(col, minf(1.0, _pulse * 0.9))
		lit.a = minf(1.0, base.a * (1.0 + 3.5 * _pulse + 2.0 * flash)) * _dim_now
		(e[0] as StandardMaterial3D).albedo_color = lit


var _dim_now := 1.0


func _build_tunnel() -> void:
	# Tiled walls and a roof with two rows of strip lights slide past with the road; ribs, fans
	# and phone niches go by as solid things.
	var shell := Node3D.new()
	for s: float in [-1.0, 1.0]:
		_run(shell, Vector3(260, 9.6, 0.4), Vector3(0, 4.8, s * 15.9), _tunnel_mat(0, Color(1.0, 0.72, 0.2)))
		# A kerb walkway along each wall with a rail.
		_run(shell, Vector3(260, 0.5, 1.0), Vector3(0, 0.25, s * 15.2), _bend(_solid(Color(0.12, 0.125, 0.14))))
		_run(shell, Vector3(260, 0.05, 0.05), Vector3(0, 1.45, s * 14.8), _bend(_solid(Color(0.5, 0.52, 0.56))))
		_run(shell, Vector3(260, 0.06, 0.12), Vector3(0, 0.52, s * 14.72), _bend(_glow(Color(1.0, 0.75, 0.25), 2.4)))
	_run(shell, Vector3(260, 0.4, 32.2), Vector3(0, 9.6, 0), _tunnel_mat(1, Color(1.0, 0.9, 0.7)))
	add_child(shell)
	_zones["tunnel"].append(shell)
	var conc := _solid(Color(0.16, 0.165, 0.18))
	var dark := _solid(Color(0.07, 0.072, 0.08))
	for i in 8:
		var rib := Node3D.new()
		# A concrete portal frame: a leg each side and a haunched beam.
		for s: float in [-1.0, 1.0]:
			_box(rib, Vector3(0.9, 9.4, 0.5), Vector3(0, 4.7, s * 15.5), conc)
			var haunch := _box(rib, Vector3(0.9, 0.5, 2.4), Vector3(0, 8.7, s * 14.4), conc)
			haunch.rotation.x = s * 0.5
			# Rail posts on the walkway, in step with the ribs.
			for k in 4:
				_box(rib, Vector3(0.05, 0.95, 0.05), Vector3(k * 5.0, 0.98, s * 14.8), _solid(Color(0.5, 0.52, 0.56)))
		_box(rib, Vector3(0.9, 0.5, 31.4), Vector3(0, 9.2, 0), conc)
		if i % 2 == 0:
			# Jet fans, a pair hung from the roof.
			for fz: float in [-3.4, 3.4]:
				var fan := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.62
				cm.bottom_radius = 0.62
				cm.height = 3.6
				cm.radial_segments = 14
				fan.mesh = cm
				fan.material_override = _solid(Color(0.34, 0.35, 0.38))
				fan.rotation.z = PI / 2.0
				fan.position = Vector3(10.0, 8.3, fz)
				rib.add_child(fan)
				for e: float in [-1.0, 1.0]:
					var lip := MeshInstance3D.new()
					var lm := CylinderMesh.new()
					lm.top_radius = 0.7
					lm.bottom_radius = 0.7
					lm.height = 0.14
					lm.radial_segments = 14
					lip.mesh = lm
					lip.material_override = dark
					lip.rotation.z = PI / 2.0
					lip.position = Vector3(10.0 + e * 1.8, 8.3, fz)
					rib.add_child(lip)
				_box(rib, Vector3(0.1, 0.8, 0.1), Vector3(9.0, 9.0, fz), dark)
				_box(rib, Vector3(0.1, 0.8, 0.1), Vector3(11.0, 9.0, fz), dark)
		else:
			# An emergency niche in each wall: a recess, an orange door, a light over it.
			for s: float in [-1.0, 1.0]:
				_box(rib, Vector3(2.2, 2.6, 0.2), Vector3(10.0, 1.8, s * 15.66), dark)
				_box(rib, Vector3(0.9, 2.1, 0.08), Vector3(10.0, 1.55, s * 15.54), _solid(Color(0.8, 0.36, 0.08)))
				_box(rib, Vector3(1.2, 0.2, 0.1), Vector3(10.0, 2.95, s * 15.52), _glow(Color(1.0, 0.5, 0.15), 3.0))
				_box(rib, Vector3(0.5, 0.7, 0.3), Vector3(11.0, 1.5, s * 15.5), _solid(Color(0.75, 0.1, 0.08)))
		var lamp := OmniLight3D.new()
		lamp.light_color = Color(1.0, 0.9, 0.7)
		lamp.light_energy = 2.4
		lamp.omni_range = 14.0
		lamp.position = Vector3(5.0, 7.6, 0)
		rib.add_child(lamp)
		_prop(rib, -SPAN / 2.0 + i * (SPAN / 8.0))
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
	var steel_b := _solid(Color(0.26, 0.3, 0.38))
	var cable := _solid(Color(0.46, 0.5, 0.58))
	for i in 4:
		var tower := Node3D.new()
		for s: float in [-1.0, 1.0]:
			# Each leg in two lifts, the upper one slimmer, standing on a pier; floodlit from
			# the deck, with a line of light up its inner edge and a warning light on top.
			_box(tower, Vector3(3.0, 3.0, 3.0), Vector3(0, -0.5, s * 15.9), _solid(Color(0.2, 0.21, 0.24)))
			_box(tower, Vector3(2.0, 18.0, 2.0), Vector3(0, 9.0, s * 15.9), steel_b)
			_box(tower, Vector3(1.5, 16.0, 1.5), Vector3(0, 26.0, s * 15.9), steel_b)
			_box(tower, Vector3(0.16, 31.0, 0.16), Vector3(-1.02, 17.0, s * 15.0), _glow(Color("5affd0"), 2.4))
			_box(tower, Vector3(0.1, 7.0, 1.6), Vector3(-1.03, 4.6, s * 15.9), _glow(Color(0.55, 0.47, 0.36), 0.5))
			var beacon := _box(tower, Vector3(0.5, 0.5, 0.5), Vector3(0, 34.4, s * 15.9), _glow(Color(1.0, 0.15, 0.15), 5.0))
			_beacons.append([beacon, float(i) * 0.4])
			# Hangers down to the deck on both sides of the leg, shorter the further out.
			for k in 9:
				_box(tower, Vector3(0.09, 26.0 - k * 2.4, 0.09), Vector3(-18.0 + k * 4.4, 13.0 - k * 1.2 + 1.0, s * 15.9), cable)
		# Two cross beams, the lower one carrying a light bar.
		_box(tower, Vector3(1.5, 1.8, 30.4), Vector3(0, 32.0, 0), steel_b)
		_box(tower, Vector3(1.7, 1.4, 29.8), Vector3(0, 18.4, 0), steel_b)
		_box(tower, Vector3(0.12, 0.16, 26.0), Vector3(-0.9, 17.6, 0), _glow(Color("5affd0"), 3.0))
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
	pm.subdivide_width = 120
	pm.subdivide_depth = 2
	mi.mesh = pm
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded;
uniform vec3 glow_a : source_color = vec3(1.0, 0.54, 0.23);
uniform vec3 glow_b : source_color = vec3(0.18, 0.89, 0.9);
uniform float wet = 0.7;
uniform sampler2D grain_tex : repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D blot_tex : repeat_enable, filter_linear_mipmap;
uniform vec3 sky_ref : source_color = vec3(1.0, 0.5, 0.42);   // what the wet road gives back far ahead
uniform float indoors = 0.0;
uniform vec3 flash_col : source_color = vec3(1.0);
uniform float flash = 0.0;       // the duel just did something big: the whole road takes its color
// (0.74.0) Lights going along the road (tail lights, the glow under each runner): on the wet
// asphalt each one throws a long streak toward the camera. xy = where (road x, z), z = how strong.
uniform vec4 refl[8];
uniform vec4 refl_col[8];
uniform int refl_n = 0;
""" + GLSL + """
// (pow() of a negative number is undefined: on some GPUs it gave white-hot pixels that the glow blew up into blobs)
float sq(float v) {
	return v * v;
}

void fragment() {
	float x = wp.x + offset;
	float z = wp.z;
	// How much road one pixel covers: anything finer than that fades out instead of shimmering.
	float px = max(fwidth(wp.x), fwidth(wp.z));
	float fine = 1.0 - smoothstep(0.03, 0.22, px);
	float az = abs(z);
	// Asphalt: fine stone from a texture laid on the road at two sizes (2.5 m and 10 m, so the
	// eye finds no repeat), and slow patches of older and newer surface. Nothing here is made
	// of squares, and far away it settles to an even grey instead of sparkling.
	float grain = texture(grain_tex, vec2(wp.x + mod(offset, 2.5), z) / 2.5).r;
	float grain2 = texture(grain_tex, vec2(wp.x + mod(offset, 10.0), z * 1.3 + 3.7) / 10.0).r;
	float big = texture(blot_tex, vec2(wp.x + mod(offset, 48.0), z * 1.6) / 48.0).r;
	float rut = texture(blot_tex, vec2((wp.x + mod(offset, 96.0)) / 96.0, z * 0.21)).r;
	vec3 col = vec3(0.07, 0.073, 0.084) * (0.42 + 0.85 * grain + 0.35 * grain2) * (0.85 + 0.3 * big);
	// Five lanes, 4.4 m each. Tyres polish two tracks down every lane; the middle stays darker
	// with dripped oil.
	float lane_u = fract(z / 4.4 + 0.5) - 0.5;
	float track_w = exp(-sq((abs(lane_u) * 4.4 - 0.95) / 0.42));
	float in_lanes = 1.0 - smoothstep(10.8, 11.1, az);
	col *= 1.0 + 0.2 * track_w * in_lanes;
	col *= 1.0 - 0.16 * exp(-sq(lane_u * 4.4 / 0.3)) * in_lanes * (0.5 + 0.5 * big);
	// Joints across the road every 20 m and the odd tar repair.
	float jx = fract(x / 20.0);
	float joint = 1.0 - smoothstep(0.0, 0.004 + px * 0.04, min(jx, 1.0 - jx));
	col = mix(col, vec3(0.014, 0.015, 0.02), joint * 0.85 * step(az, 13.6));
	float snake = 1.0 - smoothstep(0.0, 0.05 + px, abs(z - 3.0 * sin(x * 0.045) - 4.4 * floor(vnoise(vec2(x * 0.004, 2.0)) * 5.0 - 2.0)));
	col = mix(col, vec3(0.02, 0.021, 0.026), snake * 0.55 * step(0.62, vnoise(vec2(x * 0.02, 5.0))) * in_lanes);
	// Lane lines: dashes 4 m on, 8 m off. At speed their ends smear instead of strobing.
	float dx = fract(x / 12.0);
	float edge = 0.012 + px * 0.2 + (blur - 1.0) * 0.03;
	float dash = smoothstep(0.0, edge, dx) * smoothstep(0.34 + (blur - 1.0) * 0.06, 0.34 + (blur - 1.0) * 0.06 - edge, dx);
	vec3 paint = vec3(0.8, 0.83, 0.88) * (0.82 + 0.18 * grain);
	for (int i = 0; i < 4; i++) {
		float lz = (float(i) - 1.5) * 4.4;
		float d = abs(z - lz);
		float line = 1.0 - smoothstep(0.075, 0.095 + px, d);
		col = mix(col, paint, line * dash * 0.92);
		// A reflector stud in the gap after every dash.
		float eye = (1.0 - smoothstep(0.04, 0.07 + px, d)) * (1.0 - smoothstep(0.0, 0.006 + px * 0.06, abs(dx - 0.67)));
		col += vec3(1.0, 0.78, 0.36) * eye * 1.1;
	}
	// Solid edge lines, a rumble strip outside them, then the hard shoulder up to the barrier.
	float solid_l = 1.0 - smoothstep(0.08, 0.1 + px, abs(az - 11.0));
	col = mix(col, paint, solid_l * 0.9);
	float rum = smoothstep(0.3, 0.5, fract(x / 0.9)) * smoothstep(1.0, 0.8, fract(x / 0.9)) * (1.0 - smoothstep(0.2, 0.26, abs(az - 11.55)));
	col *= 1.0 - rum * 0.35 * fine;
	float shoulder = smoothstep(11.9, 12.1, az);
	col = mix(col, col * 0.8 + vec3(0.012) * grain, shoulder);
	// Hatching on the shoulder: slanted bars, sparse.
	float hatch = step(0.93, fract((x + az * 1.4) / 6.0)) * shoulder * (1.0 - smoothstep(13.3, 13.5, az));
	col = mix(col, paint * 0.7, hatch * 0.4);
	// Street lamps stand every 16 m on both sides, staggered. Each lays a pool of light on the
	// road under it, and on the wet surface a long streak toward you.
	float lamp_x = cos((x + 4.0 * step(0.0, z)) * 6.2832 / 16.0) * 0.5 + 0.5;
	float pool_l = pow(max(lamp_x, 0.0), 2.2) * exp(-sq((az - 8.6) / 5.6));
	col *= 1.0 + 1.25 * pool_l * (1.0 - indoors);
	float lamp = pow(max(lamp_x, 0.0), 5.0) * exp(-sq((az - 9.4) / 3.4));
	col += vec3(1.0, 0.87, 0.68) * lamp * 0.22 * wet * (0.6 + 0.4 * grain) * (1.0 - indoors);
	// Wet asphalt is a mirror at a low angle: far ahead it takes the color of the sky over the
	// city, most where water stands in the low patches.
	float fres = pow(1.0 - clamp(dot(normalize(VIEW), NORMAL), 0.0, 1.0), 5.0);
	// Water stands in long shallow ruts that run the way the traffic does.
	float puddle = smoothstep(0.5, 0.72, rut) * (0.6 + 0.4 * big);
	// Looking back down the road it is the cold side of the sky that it mirrors.
	float look_x = (INV_VIEW_MATRIX * vec4(0.0, 0.0, -1.0, 0.0)).x;
	vec3 mirror = mix(glow_b * 0.4 + vec3(0.06, 0.08, 0.3), sky_ref, smoothstep(-0.5, 0.5, look_x));
	col += mirror * min(fres, 0.72) * wet * (0.3 + 0.34 * puddle) * (0.7 + 0.3 * grain) * (1.0 - indoors * 0.75);
	// Wet stones catch the lamps: tiny glints right under each one.
	col += vec3(1.0, 0.9, 0.75) * pow(max(grain, 0.0), 5.0) * pool_l * 0.12 * fine * (1.0 - indoors);
	// Indoors the strip lights in the ceiling run down the road as two long bars of glare.
	float bars = exp(-sq((az - 5.2) / 1.5)) * (0.7 + 0.3 * smoothstep(0.1, 0.2, fract(x / 6.0)) * smoothstep(0.9, 0.8, fract(x / 6.0)));
	col += vec3(1.0, 0.9, 0.7) * bars * 0.16 * wet * indoors;
	// The barrier's strip of light bleeds across the shoulder.
	col += mix(glow_b, glow_a, step(0.0, z)) * exp(-(13.95 - az) * 0.6) * 0.3 * wet * step(az, 13.95);
	// Signs and lit windows going by overhead throw their color down too.
	float gx = (x * 0.5 + 3.0) / 36.0;
	float pool = pow(max(0.0, cos(gx * 6.2832)), 6.0) * (0.45 + 0.55 * hash(vec2(floor(gx + 0.5), 3.0)));
	col += mix(glow_a, glow_b, step(0.5, hash(vec2(floor(gx + 0.5), 9.0)))) * pool * smoothstep(13.0, 2.0, az) * 0.06 * wet * (1.0 - indoors);
	// The lights on the road, mirrored: a streak from each toward the eye, longer the wetter.
	vec2 eye_xz = CAMERA_POSITION_WORLD.xz;
	for (int i = 0; i < refl_n; i++) {
		vec2 L = refl[i].xy;
		vec2 to_eye = eye_xz - L;
		float le = length(to_eye);
		if (le < 0.01) { continue; }
		vec2 dir2 = to_eye / le;
		vec2 rel = vec2(wp.x, z) - L;
		float along = dot(rel, dir2);
		float across = abs(rel.x * dir2.y - rel.y * dir2.x);
		float reach = (3.0 + 7.0 * wet) * refl[i].w;
		float streak = exp(-sq(across / (0.22 + 0.05 * max(along, 0.0)))) * exp(-max(along, 0.0) / reach) * smoothstep(-0.6, 0.4, along) * step(along, le);
		col += refl_col[i].rgb * streak * refl[i].z * wet * (0.55 + 0.45 * grain) * (1.0 - indoors * 0.5);
	}
	// Fade into the dark far away.
	float fade = 1.0 - smoothstep(70.0, 126.0, abs(wp.x));
	// A wash of the color over the asphalt, strongest in bands that race back along the road.
	float band = 0.55 + 0.45 * sin((wp.x + offset * 0.6) * 0.5);
	col += flash_col * flash * (0.10 + 0.16 * band) + col * flash_col * flash * 1.4;
	// One bad pixel is enough for the glow to turn it into a white blob on the road: none get out.
	col = mix(col, vec3(0.03), vec3(isnan(col)));
	ALBEDO = clamp(col * fade, vec3(0.0), vec3(6.0));
}
"""
	_road = ShaderMaterial.new()
	_road.shader = sh
	_road.set_shader_parameter("glow_a", accent)
	_road.set_shader_parameter("glow_b", accent2)
	_road.set_shader_parameter("grain_tex", _noise_tex(0.11, true, 7))
	_road.set_shader_parameter("blot_tex", _noise_tex(0.012, false, 21))
	_road.set_shader_parameter("sky_ref", (accent * 0.8 + Color(0.35, 0.05, 0.25)))
	mi.material_override = _road
	mi.position = Vector3(0, -0.08, 0)
	mi.extra_cull_margin = 60.0
	add_child(mi)


## A tiling noise picture for a surface: stones (cellular) or slow patches.
func _noise_tex(freq: float, stones: bool, seed_n: int) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.seed = seed_n
	n.noise_type = FastNoiseLite.TYPE_CELLULAR if stones else FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = freq
	n.fractal_octaves = 3
	var t := NoiseTexture2D.new()
	t.width = 512
	t.height = 512
	t.seamless = true
	t.generate_mipmaps = true
	t.noise = n
	return t


var _scroll: Array[ShaderMaterial] = []
var _barrier_sh: Shader


## The low barrier: cast concrete in 6 m lengths, stained where the rain runs off it, a
## reflector on every length and the glow of its light strip down its face.
func _barrier_mat(col: Color, _pitch := 1.0) -> ShaderMaterial:
	if _barrier_sh == null:
		_barrier_sh = Shader.new()
		_barrier_sh.code = """
shader_type spatial;
render_mode unshaded;
uniform vec3 tint : source_color = vec3(0.2, 0.9, 0.9);
""" + GLSL + """
void fragment() {
	float x = wp.x + offset;
	float px = max(fwidth(wp.x), fwidth(wp.y));
	float fine = 1.0 - smoothstep(0.03, 0.2, px);
	float y = wp.y;
	// Cast concrete: pale, even, a little darker toward the foot where the spray lands.
	vec3 col = vec3(0.2, 0.205, 0.22) * (0.86 + 0.2 * vnoise(vec2(x * 0.5, y * 2.0)));
	col *= 0.72 + 0.28 * smoothstep(0.0, 0.5, y);
	// Rain streaks down from the top edge, faint.
	float streak = vnoise(vec2(x * 3.5, 1.0)) * smoothstep(0.1, 1.0, y);
	col *= 1.0 - 0.14 * smoothstep(0.55, 0.9, streak) * fine;
	// A joint between the 6 m lengths.
	float seam = fract(x / 6.0);
	col *= 1.0 - 0.5 * (1.0 - smoothstep(0.0, 0.005 + px * 0.04, min(seam, 1.0 - seam)));
	// One clean reflective band along the whole wall, and an amber stud on every length.
	float band = (1.0 - smoothstep(0.035, 0.04 + px * 0.3, abs(y - 0.62)));
	col = mix(col, vec3(0.62, 0.64, 0.68), band * 0.75);
	float refl = 1.0 - smoothstep(0.03, 0.04 + px * 0.1, length(vec2((seam - 0.5) * 6.0, y - 0.3)));
	col += vec3(1.0, 0.62, 0.14) * refl * 1.2;
	// The lamps overhead brighten it as they pass.
	col *= 0.85 + 0.45 * pow(max(cos(x * 6.2832 / 16.0) * 0.5 + 0.5, 0.0), 3.0);
	// Its own light strip washes down the face.
	col += tint * 0.42 * smoothstep(0.2, 1.05, y) * (0.8 + 0.2 * vnoise(vec2(x * 0.5, 3.0)));
	float fade = 1.0 - smoothstep(70.0, 126.0, abs(wp.x));
	ALBEDO = col * fade;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _barrier_sh
	m.set_shader_parameter("tint", col)
	_scroll.append(m)
	return m


var _glass_sh: Shader


## The tall wall behind the barrier: panes of tinted glass in steel frames. Through them the
## city goes by: two depths of lit windows and street lamps, each sliding at its own pace.
func _glass_mat(col: Color) -> ShaderMaterial:
	if _glass_sh == null:
		_glass_sh = Shader.new()
		_glass_sh.code = """
shader_type spatial;
render_mode unshaded, depth_draw_opaque;
uniform vec3 tint : source_color = vec3(0.2, 0.9, 0.9);
uniform float side = 1.0;
""" + GLSL + """
void fragment() {
	float x = wp.x + offset;
	float y = wp.y;
	float px = max(fwidth(wp.x), fwidth(wp.y));
	float fine = 1.0 - smoothstep(0.02, 0.12, px);
	float u = fract(x / 4.0);
	float lamp = pow(max(cos((x + 4.0 * step(0.0, side)) * 6.2832 / 16.0) * 0.5 + 0.5, 0.0), 6.0);
	// Below: a ribbed sound panel in dark painted steel.
	float panel = 1.0 - smoothstep(2.18, 2.2, y);
	float rib = 0.5 + 0.5 * sin(y * 52.0);
	vec3 metal = vec3(0.06, 0.068, 0.085) * (0.75 + 0.5 * rib * fine) + tint * 0.035;
	metal *= 0.85 + 0.6 * lamp;
	// Above: clear tinted glass. You see the city through it; the lamps slide along it as a
	// long soft reflection.
	vec3 glass = vec3(0.02, 0.035, 0.06) + tint * 0.05 + vec3(1.0, 0.9, 0.75) * lamp * 0.12 * smoothstep(4.2, 2.4, y);
	float glass_a = 0.3 + 0.25 * lamp * smoothstep(4.2, 2.4, y);
	// Frames: a post every 4 m, a rail where the panel meets the glass, and a top rail.
	float post = 1.0 - smoothstep(0.02, 0.022 + px * 0.06, min(u, 1.0 - u));
	float rail = max(1.0 - smoothstep(0.05, 0.06 + px * 0.2, abs(y - 2.2)), smoothstep(4.02, 4.04, y));
	float frame = max(post, rail);
	vec3 steel = vec3(0.11, 0.115, 0.13) * (0.85 + 0.5 * lamp) + tint * 0.05;
	vec3 col = mix(glass, metal, panel);
	col = mix(col, steel, frame);
	// A line of light along the top rail.
	float line = 1.0 - smoothstep(0.03, 0.05, abs(y - 4.12));
	col += tint * line * 1.3;
	float fade = 1.0 - smoothstep(70.0, 126.0, abs(wp.x));
	ALBEDO = col * fade;
	ALPHA = max(max(panel, frame), max(line, glass_a));
}
"""
	var m := ShaderMaterial.new()
	m.shader = _glass_sh
	m.set_shader_parameter("tint", col)
	_scroll.append(m)
	return m


var _tile_sh: Shader


## Tunnel walls and roof. kind 0: the wall, cream tile to shoulder height with a band of the
## road's color, bare concrete above with a cable tray. kind 1: the roof, dark, with two rows
## of strip lights.
func _tunnel_mat(kind: int, col: Color) -> ShaderMaterial:
	if _tile_sh == null:
		_tile_sh = Shader.new()
		_tile_sh.code = """
shader_type spatial;
render_mode unshaded;
uniform vec3 tint : source_color = vec3(1.0, 0.8, 0.3);
uniform int kind = 0;
""" + GLSL + """
void fragment() {
	float x = wp.x + offset;
	float px = max(fwidth(wp.x), max(fwidth(wp.y), fwidth(wp.z)));
	float fine = 1.0 - smoothstep(0.02, 0.14, px);
	vec3 col;
	if (kind == 0) {
		float y = wp.y;
		// Tiles 0.6 by 0.3, laid brick fashion, grout between, a few replaced in another shade.
		vec2 g = vec2(x / 0.6 + 0.5 * floor(y / 0.3), y / 0.3);
		vec2 cell = floor(g);
		vec2 f = fract(g);
		float grout = max(1.0 - smoothstep(0.0, 0.03 + px * 1.5, min(f.x, 1.0 - f.x)), 1.0 - smoothstep(0.0, 0.06 + px * 3.0, min(f.y, 1.0 - f.y)));
		vec3 tile = vec3(0.56, 0.54, 0.47) * (0.86 + 0.14 * hash(cell)) * mix(1.0, 0.8, step(0.96, hash(cell + 5.0)));
		tile = mix(tile, vec3(0.26, 0.25, 0.23), grout * fine * 0.8);
		// Soot climbs from the road and hangs under the lights.
		tile *= 0.62 + 0.38 * smoothstep(0.1, 1.6, y);
		tile *= 0.85 + 0.15 * vnoise(vec2(x * 0.3, y * 0.8));
		// The band: two tiles high, in the color of this stretch.
		float band = smoothstep(1.78, 1.8, y) * (1.0 - smoothstep(2.38, 2.4, y));
		tile = mix(tile, tint * 0.5 * (0.85 + 0.15 * hash(cell)), band * (1.0 - grout * 0.6 * fine));
		// Above the tile: concrete with form marks, a cable tray, a pipe.
		vec3 conc = vec3(0.12, 0.122, 0.13) * (0.8 + 0.3 * vnoise(vec2(x * 0.5, y * 1.5)));
		float form = fract(x / 2.4);
		conc *= 1.0 - 0.3 * (1.0 - smoothstep(0.0, 0.01 + px * 0.2, min(form, 1.0 - form)));
		float tray = smoothstep(5.0, 5.03, y) * (1.0 - smoothstep(5.36, 5.39, y));
		conc = mix(conc, vec3(0.05, 0.052, 0.06) + vec3(0.04) * step(0.5, fract(x / 0.4)), tray);
		float pipe = 1.0 - smoothstep(0.07, 0.09, abs(y - 6.0));
		conc = mix(conc, vec3(0.3, 0.16, 0.1) * (0.7 + 0.5 * smoothstep(0.09, 0.0, abs(y - 6.03))), pipe);
		col = mix(tile, conc, smoothstep(3.0, 3.02, y));
		// Light from the roof strips: brightest high on the tile, gone at the foot.
		col *= 0.75 + 0.65 * smoothstep(0.0, 3.0, y) * (1.0 - smoothstep(3.0, 8.0, y));
		// A lit sign box every 48 m: a green field with a white figure and an arrow.
		float sx = fract(x / 48.0) * 48.0 - 24.0;
		vec2 sg = vec2(sx, y - 2.75);
		float box = step(abs(sg.x), 0.75) * step(abs(sg.y), 0.3);
		float fig = step(length(sg - vec2(-0.3, 0.1)), 0.08) + step(abs(sg.x + 0.3), 0.06) * step(abs(sg.y + 0.08), 0.12);
		float arrow = step(abs(sg.y), 0.045) * step(abs(sg.x - 0.25), 0.3) + step(abs(sg.y) + (sg.x - 0.45), 0.16) * step(0.45, sg.x) * step(sg.x, 0.62);
		col = mix(col, vec3(0.05, 0.75, 0.35) * 1.3 + vec3(1.0) * clamp(fig + arrow, 0.0, 1.0), box);
	} else {
		// The roof: black concrete, and the lights: fittings 3 m long in two rows.
		float z = abs(wp.z);
		col = vec3(0.03, 0.031, 0.036) * (0.8 + 0.4 * vnoise(vec2(x * 0.4, wp.z * 0.4)));
		float along = fract(x / 6.0);
		float lit = smoothstep(0.08, 0.1, along) * smoothstep(0.62, 0.6, along);
		float row = 1.0 - smoothstep(0.32, 0.36, abs(z - 5.2));
		float housing = 1.0 - smoothstep(0.5, 0.54, abs(z - 5.2));
		col = mix(col, vec3(0.08, 0.082, 0.09), housing * step(0.04, along) * step(along, 0.66));
		col = mix(col, vec3(1.0, 0.93, 0.76) * 2.2, row * lit);
		// Glow round each fitting.
		col += vec3(1.0, 0.85, 0.6) * exp(-((z - 5.2) / 1.6) * ((z - 5.2) / 1.6)) * lit * 0.12;
		// A duct down the middle with a seam every few meters.
		float duct = 1.0 - smoothstep(0.7, 0.74, z);
		col = mix(col, vec3(0.07, 0.072, 0.08) * (0.8 + 0.2 * step(0.04, fract(x / 3.0))), duct);
	}
	float fade = 1.0 - smoothstep(70.0, 126.0, abs(wp.x));
	ALBEDO = col * fade;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _tile_sh
	m.set_shader_parameter("tint", col)
	m.set_shader_parameter("kind", kind)
	_scroll.append(m)
	return m


## A long box cut into enough pieces along the road that it can follow a bend.
func _run(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := _box(parent, size, pos, mat)
	(mi.mesh as BoxMesh).subdivide_width = 120
	mi.extra_cull_margin = 60.0
	return mi


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
	# A concrete barrier with a strip of light along its top, a wall of glass behind it with
	# the city going by on the far side, and lamps leaning in over the road.
	var steel := _solid(Color(0.14, 0.15, 0.18))
	for side in [-1.0, 1.0]:
		var col: Color = accent if side > 0.0 else accent2
		var wall := Node3D.new()
		_run(wall, Vector3(260, 1.1, 0.5), Vector3(0, 0.45, side * 14.2), _barrier_mat(col))
		_run(wall, Vector3(260, 0.07, 0.1), Vector3(0, 1.03, side * 14.0), _bend(_glow(col, 3.2)))
		_run(wall, Vector3(260, 0.05, 0.6), Vector3(0, 1.01, side * 14.25), _bend(_solid(Color(0.08, 0.085, 0.1))))
		add_child(wall)
		# The glass wall stands only out in the open: in the tunnel the tunnel is the wall.
		var glass := Node3D.new()
		var gm := _glass_mat(col)
		gm.set_shader_parameter("side", side)
		_run(glass, Vector3(260, 3.3, 0.16), Vector3(0, 2.62, side * 15.3), gm)
		add_child(glass)
		for zk in ["satellite", "tops", "bridge"]:
			_zones[zk].append(glass)
		for i in 10:
			var post := Node3D.new()
			# A tapered column, an arm curving out over the road in three pieces, the lamp head.
			var pole := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.09
			cm.bottom_radius = 0.16
			cm.height = 7.4
			cm.radial_segments = 8
			pole.mesh = cm
			pole.material_override = steel
			pole.position = Vector3(0, 3.7, side * 14.75)
			post.add_child(pole)
			_box(post, Vector3(0.5, 0.5, 0.5), Vector3(0, 0.25, side * 14.75), steel)
			for k in 3:
				var arm := _box(post, Vector3(0.1, 0.1, 1.15), Vector3(0, 7.45 + k * 0.16 - k * k * 0.05, side * (14.2 - k * 1.05)), steel)
				arm.rotation.x = side * (0.34 - k * 0.2)
			_box(post, Vector3(0.34, 0.12, 1.3), Vector3(0, 7.56, side * 11.3), steel)
			_box(post, Vector3(0.26, 0.05, 1.1), Vector3(0, 7.48, side * 11.3), _glow(Color(1.0, 0.95, 0.82), 4.5))
			# A soft cone of light under the head.
			var cone := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(9.0, 7.4)
			cone.mesh = qm
			cone.material_override = _cone_mat()
			cone.position = Vector3(0, 3.75, side * 11.3)
			cone.rotation.y = PI / 2.0
			post.add_child(cone)
			var lamp := OmniLight3D.new()
			lamp.light_color = Color(1.0, 0.9, 0.75)
			lamp.light_energy = 2.2
			lamp.omni_range = 11.0
			lamp.position = Vector3(0, 6.2, side * 11.5)
			post.add_child(lamp)
			_prop(post, -SPAN / 2.0 + i * (SPAN / 10.0) + (4.0 if side > 0.0 else 0.0))
			for zk in ["satellite", "tops", "bridge"]:
				_zones[zk].append(post)
	for i in 2:
		var gantry := Node3D.new()
		# A truss across the road on two legs, carrying the signs.
		for gy: float in [7.9, 8.6]:
			_box(gantry, Vector3(0.14, 0.14, 30.4), Vector3(0, gy, 0), steel)
		for k in 16:
			var brace := _box(gantry, Vector3(0.08, 0.92, 0.08), Vector3(0, 8.25, -14.2 + k * 1.9), steel)
			brace.rotation.x = 0.7 if k % 2 == 0 else -0.7
		for side in [-1.0, 1.0]:
			_box(gantry, Vector3(0.36, 8.7, 0.36), Vector3(0, 4.35, side * 15.0), steel)
		# Overhead signs: lane arrows and a moving readout, not blank panels.
		for gs in [[-6.0, accent2], [6.0, accent]]:
			var panel := MeshInstance3D.new()
			var qm2 := QuadMesh.new()
			qm2.size = Vector2(9.0, 1.7)
			panel.mesh = qm2
			panel.material_override = _holo(gs[1], 3.0 + i * 2.0 + float(gs[0]))
			panel.rotation.y = -PI / 2.0
			panel.position = Vector3(-0.3, 7.0, float(gs[0]))
			gantry.add_child(panel)
			_box(gantry, Vector3(0.14, 1.9, 9.2), Vector3(-0.2, 7.0, float(gs[0])), _solid(Color(0.05, 0.06, 0.09)))
		_prop(gantry, -SPAN / 2.0 + 30.0 + i * (SPAN / 2.0))
		for zk in ["satellite", "tops", "bridge"]:
			_zones[zk].append(gantry)


var _cone_sh: Shader
var _bent: Array[ShaderMaterial] = []


## The haze under a street lamp: brightest at the head, gone before it reaches the road.
func _cone_mat() -> ShaderMaterial:
	if _cone_sh == null:
		_cone_sh = Shader.new()
		_cone_sh.code = """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
void fragment() {
	float down = UV.y;
	float half_w = 0.04 + down * 0.46;
	float across = 1.0 - smoothstep(half_w * 0.2, half_w, abs(UV.x - 0.5));
	ALBEDO = vec3(1.0, 0.9, 0.72);
	ALPHA = across * pow(max(1.0 - down, 0.0), 1.6) * 0.16;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _cone_sh
	return m


var _bend_sh := {}


## A plain glowing or solid strip that still has to follow the bend of the road.
func _bend(src: StandardMaterial3D) -> ShaderMaterial:
	var lit := src.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED
	if not _bend_sh.has(lit):
		var sh := Shader.new()
		sh.code = """
shader_type spatial;
""" + ("" if lit else "render_mode unshaded;") + """
uniform vec3 tint : source_color = vec3(1.0);
uniform float energy = 1.0;
uniform float curve = 0.0;
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float ahead = max(0.0, w.x);
	VERTEX.z -= curve * ahead * ahead * 0.0035;
}
void fragment() {
	ALBEDO = tint * energy;
	ROUGHNESS = 0.6;
}
"""
		_bend_sh[lit] = sh
	var m := ShaderMaterial.new()
	m.shader = _bend_sh[lit]
	m.set_shader_parameter("tint", src.albedo_color)
	m.set_shader_parameter("energy", 1.0 if lit else maxf(1.0, src.emission_energy_multiplier * 0.6))
	_bent.append(m)
	return m


func _build_skyline() -> void:
	# Towers on both sides, far enough to drift past slowly. Three kinds of front: ribbons of
	# window floor by floor, single windows in a wall, and all glass lit in tall columns. Rooms
	# are lit warm or cool white like a real city at night; the colour comes from the signs.
	var rng := RandomNumberGenerator.new()
	rng.seed = 2077
	var win := Shader.new()
	win.code = """
shader_type spatial;
render_mode unshaded;
uniform vec3 tint : source_color = vec3(1.0, 0.8, 0.5);
uniform float seed = 0.0;
uniform float height = 30.0;
uniform float style = 0.0;
uniform vec3 haze : source_color = vec3(0.6, 0.2, 0.5);
varying vec3 lp;
varying vec3 ln;
float hash(vec2 p) { return fract(sin(dot(p, vec2(41.3, 289.1)) + seed) * 43758.5453); }
void vertex() { lp = VERTEX; ln = NORMAL; }
void fragment() {
	// Along the face and up it. Floors are 3.4 m; a bay is one window wide.
	float u = (abs(ln.x) > 0.5 ? lp.z : lp.x) + 40.0;
	float y = lp.y + height * 0.5;
	float roof = step(0.5, abs(ln.y));
	float bay = style < 0.5 ? 1.5 : (style < 1.5 ? 2.2 : 1.1);
	float fl = floor(y / 3.4);
	float fy = fract(y / 3.4);
	float bi = floor(u / bay);
	float fx = fract(u / bay);
	float px = max(fwidth(u) / bay, fwidth(y) / 3.4);
	float soft = 0.02 + px;
	// The opening in this bay on this floor.
	float open_x = style < 0.5 ? smoothstep(0.03, 0.03 + soft, fx) * smoothstep(0.97, 0.97 - soft, fx)
		: (style < 1.5 ? smoothstep(0.2, 0.2 + soft, fx) * smoothstep(0.8, 0.8 - soft, fx)
		: smoothstep(0.06, 0.06 + soft, fx) * smoothstep(0.94, 0.94 - soft, fx));
	float lo = style < 1.5 ? 0.3 : 0.08;
	float hi = style < 0.5 ? 0.82 : (style < 1.5 ? 0.8 : 0.94);
	float open_y = smoothstep(lo, lo + soft, fy) * smoothstep(hi, hi - soft, fy);
	float glass = open_x * open_y * (1.0 - roof);
	// Who is still in: rooms a few bays wide on ribbon floors, single rooms in a wall, whole
	// columns behind all-glass fronts. Some floors are dark, and a few are one long lit office.
	float room = style < 0.5 ? floor(bi / (1.0 + floor(hash(vec2(fl, 5.0)) * 3.0))) : bi;
	float lit = step(0.56, hash(vec2(room, style > 1.5 ? floor(fl / 5.0) : fl)));
	float floor_mood = hash(vec2(3.0, fl));
	lit = max(lit * step(0.2, floor_mood), step(0.93, floor_mood));
	float kind = hash(vec2(room + 9.0, fl + 2.0));
	vec3 lamp = kind < 0.6 ? vec3(1.0, 0.82, 0.56) : (kind < 0.94 ? vec3(0.78, 0.9, 1.0) : tint);
	float bright = 0.35 + 0.65 * hash(vec2(room, fl + 17.0));
	// Blinds half down in some rooms.
	bright *= mix(1.0, smoothstep(0.62, 0.55, fy), step(0.8, hash(vec2(room + 4.0, fl))));
	// Far away single windows melt into an even glow instead of crawling.
	float far = smoothstep(0.25, 0.6, px);
	vec3 wall = style < 1.5 ? vec3(0.03, 0.033, 0.045) : vec3(0.018, 0.022, 0.034);
	// A slab edge at every floor.
	wall *= 1.0 + 0.5 * (1.0 - smoothstep(0.02, 0.04 + px, fy)) * (1.0 - roof);
	vec3 dark_glass = vec3(0.035, 0.045, 0.075) + haze * 0.05;
	vec3 col = mix(wall, mix(dark_glass, lamp * bright, lit), glass);
	col = mix(col, wall + lamp * 0.16, far * (1.0 - roof));
	// Haze climbs the towers from the street, and the roof line catches a cool rim.
	col += haze * 0.2 * (1.0 - smoothstep(0.0, 0.3, y / height));
	col += tint * 0.1 * smoothstep(0.93, 1.0, y / height);
	ALBEDO = col;
}
"""
	var warm := [Color(1.0, 0.78, 0.48), Color(1.0, 0.86, 0.66)]
	var cool := [Color(0.62, 0.86, 1.0), Color(0.9, 0.95, 1.0)]
	var dark := _solid(Color(0.05, 0.055, 0.075))
	for side in [-1.0, 1.0]:
		for i in 22:
			var t := Node3D.new()
			var w := rng.randf_range(8.0, 17.0)
			var h := rng.randf_range(16.0, 66.0)
			var d := rng.randf_range(8.0, 15.0)
			var z: float = side * rng.randf_range(27.0, 70.0)
			var hz: Color = accent.lerp(Color(0.7, 0.2, 0.6), 0.6) if side > 0.0 else accent2.lerp(Color(0.3, 0.2, 0.7), 0.6)
			var style := float(rng.randi() % 3)
			var tint_c: Color = (warm if i % 2 == 0 else cool)[rng.randi() % 2]
			var seed_n := rng.randf() * 50.0
			var front := func(hh: float) -> ShaderMaterial:
				var mat := ShaderMaterial.new()
				mat.shader = win
				mat.set_shader_parameter("seed", seed_n)
				mat.set_shader_parameter("tint", tint_c)
				mat.set_shader_parameter("height", hh)
				mat.set_shader_parameter("style", style)
				mat.set_shader_parameter("haze", hz)
				return mat
			_box(t, Vector3(w, h, d), Vector3(0, h / 2.0 - 4.0, z), front.call(h))
			# A wider base at street level under the taller ones.
			if h > 26.0:
				_box(t, Vector3(w + 4.0, 9.0, d + 4.0), Vector3(0, 0.5, z), front.call(9.0))
				_box(t, Vector3(w + 4.4, 0.4, d + 4.4), Vector3(0, 5.2, z), dark)
			# A set-back upper part, a mast with a warning light, and now and then a moving sign.
			var top := h - 4.0
			if h > 34.0:
				var uh := h * rng.randf_range(0.18, 0.34)
				_box(t, Vector3(w * 0.64, uh, d * 0.64), Vector3(0, top + uh / 2.0, z), front.call(uh))
				_box(t, Vector3(w + 0.5, 0.5, d + 0.5), Vector3(0, top + 0.25, z), dark)
				top += uh
				_box(t, Vector3(0.18, 7.0, 0.18), Vector3(0, top + 3.5, z), dark)
				var beacon := _box(t, Vector3(0.5, 0.5, 0.5), Vector3(0, top + 7.0, z), _glow(Color(1.0, 0.15, 0.15), 5.0))
				_beacons.append([beacon, rng.randf() * 6.0])
			else:
				# Plant on the roof: a low box and a tank.
				_box(t, Vector3(w * 0.4, 1.6, d * 0.4), Vector3(w * 0.12, top + 0.8, z), dark)
			_box(t, Vector3(w + 0.3, 0.35, d + 0.3), Vector3(0, top + 0.18, z), dark)
			if rng.randf() < 0.3 and absf(z) < 48.0:
				var sign := _box(t, Vector3(w * 0.7, rng.randf_range(5.0, 9.0), 0.2), Vector3(0, rng.randf_range(8.0, h * 0.6), z - side * (d / 2.0 + 0.2)), _holo([accent, accent2, Color("ff4fd8"), Color("7cff6a")][rng.randi() % 4], rng.randf() * 9.0))
				sign.name = "holo"
			# A line of light up one corner on some, along the roof on others.
			var edge := rng.randf()
			if edge < 0.3:
				_box(t, Vector3(0.22, h * 0.9, 0.22), Vector3(-w / 2.0, h * 0.45 - 4.0, z - side * d / 2.0), _glow([accent, accent2][rng.randi() % 2], 2.2))
			elif edge < 0.62:
				_box(t, Vector3(w * 0.96, 0.3, 0.3), Vector3(0, h - 4.6, z - side * d / 2.0), _glow([accent, accent2][rng.randi() % 2], 2.5))
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
uniform float night = 0.0;      // (0.74.0) 0 dusk, 1 deep night
uniform float dawn = 0.0;       // 1: first light, cold blue going gold
uniform float rain = 0.0;       // 1: low cloud, no stars
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
	hor = mix(hor, hor * 0.3 + vec3(0.02, 0.02, 0.06), night);
	hor = mix(hor, mix(vec3(0.2, 0.32, 0.55), vec3(1.0, 0.72, 0.42), smoothstep(-0.4, 0.9, d.x)), dawn);
	hor = mix(hor, vec3(0.11, 0.115, 0.15) + hor * 0.25, rain * 0.75);
	mid = mix(mid, vec3(0.03, 0.02, 0.07), night);
	mid = mix(mid, vec3(0.16, 0.2, 0.36), dawn);
	mid = mix(mid, vec3(0.06, 0.065, 0.085), rain * 0.8);
	vec3 col = mix(hor, mid, smoothstep(0.0, 0.22, h));
	col = mix(col, top + vec3(0.04, 0.06, 0.12) * dawn, smoothstep(0.15, 0.7, h));
	// Stars, thinning toward the glow of the city.
	vec2 sp = d.xz / (abs(d.y) + 0.35) * 150.0;
	float st = step(0.99, hash(floor(sp))) * smoothstep(0.5, 0.2, length(fract(sp) - 0.5)) * smoothstep(0.12, 0.5, h);
	col += vec3(0.8, 0.85, 1.0) * st * (0.4 + 0.6 * hash(floor(sp) + 3.0)) * (0.7 + 0.3 * sin(TIME * 2.0 + hash(floor(sp)) * 20.0)) * (1.0 + night * 0.6 - dawn * 0.8) * (1.0 - rain);
	// Thin cloud bands lit from below.
	float cl = noise(vec2(d.x * 3.0 + TIME * 0.01, d.y * 16.0 + d.z * 2.0)) * noise(vec2(d.z * 4.0, d.y * 9.0));
	col += hor * cl * (0.55 + rain * 0.9) * smoothstep(0.02, 0.12, h) * smoothstep(0.5 + rain * 0.4, 0.18, h);
	// A big pale moon.
	vec3 md = normalize(vec3(0.55, 0.34, -0.76));
	float m = dot(d, md);
	float disc = smoothstep(0.9955, 0.9965, m);
	float crater = noise(d.xy * 60.0) * 0.25;
	col = mix(col, vec3(0.92, 0.94, 1.0) * (0.85 - crater), disc * (1.0 - rain) * (1.0 - dawn * 0.6));
	col += vec3(0.5, 0.6, 1.0) * pow(max(m, 0.0), 90.0) * 0.35;
	// Below the horizon it is just dark haze.
	col = mix(col, hor * 0.25, smoothstep(0.0, -0.12, d.y));
	ALBEDO = col;
}
"""
	var dm := ShaderMaterial.new()
	dm.shader = sh
	_dome = dm
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
	ALPHA = w * w * (1.0 - UV.y) * UV.y * 0.6;
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
## `look` is what the garage did to it: {"frame": 0 or 1, "trail": colour, "mark": what is
## painted on its side}. Left out, the runner is the stock one for that place on the road.
func add_rider(index: int, key: String, at: Vector3, color: Color, look := {}) -> RoamFigure:
	var made := _make_rider(index, key, at, color, look)
	_bikes.append([made[0], at, randf() * TAU])
	(made[0] as Node3D).set_meta("glow", color)
	(made[0] as Node3D).set_meta("fig", made[1])
	if bool(weather["rain"]) and int(Settings.gfx.get("detail", 2)) >= 2:
		var sp := _make_spray()
		(made[0] as Node3D).add_child(sp)
		_sprays.append(sp)
	return made[1]


## Swap the runner at `index` for one with a new look (the garage), where it stands.
func replace_rider(index: int, key: String, color: Color, look := {}) -> RoamFigure:
	if index >= _bikes.size():
		return null
	var old: Node3D = _bikes[index][0]
	var at: Vector3 = _bikes[index][1]
	for tr in old.find_children("*", "MeshInstance3D", true, false):
		_trails.erase(tr)
	_fx.erase(index)
	old.queue_free()
	var made := _make_rider(index, key, at, color, look)
	_bikes[index][0] = made[0]
	(made[0] as Node3D).set_meta("glow", color)
	(made[0] as Node3D).set_meta("fig", made[1])
	return made[1]


## A runner with nobody on it, see-through and glowing: the ghost of your best lap.
func ghost_runner(frame: int, color: Color) -> Node3D:
	var holder := Node3D.new()
	add_child(holder)
	var ps = load(RUNNERS[frame % RUNNERS.size()])
	if ps is PackedScene:
		var bike: Node3D = ps.instantiate()
		holder.add_child(bike)
		var box := _aabb(bike, Transform3D())
		var s := 2.55 / maxf(0.01, maxf(box.size.x, box.size.z))
		bike.scale = Vector3.ONE * s
		bike.rotation.y = PI if box.size.x >= box.size.z else PI / 2.0
		bike.position = Vector3(box.get_center().x * s, -box.position.y * s, box.get_center().z * s)
		var gm := StandardMaterial3D.new()
		gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		gm.albedo_color = Color(color, 0.32)
		for mi in bike.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = gm
	var tag := Label3D.new()
	tag.text = "BEST"
	tag.font_size = 40
	tag.pixel_size = 0.006
	tag.outline_size = 10
	tag.modulate = color
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0, 2.0, 0)
	holder.add_child(tag)
	return holder


func _make_rider(index: int, key: String, at: Vector3, color: Color, look: Dictionary) -> Array:
	var holder := Node3D.new()
	holder.position = at
	add_child(holder)
	var fi: int = int(look.get("frame", index % RUNNERS.size())) % RUNNERS.size()
	var trail_col: Color = look.get("trail", color)
	var ps = load(RUNNERS[fi])
	var own_bike := CityBuilder.own_instance(["runner_a", "runner_b"][fi])
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
		# What is painted on it: a number or a sign on both flanks.
		var mark := str(look.get("mark", ""))
		if mark != "":
			for sz: float in [-1.0, 1.0]:
				var ml := Label3D.new()
				ml.text = mark
				ml.font = load("res://assets/fonts/Rajdhani-SemiBold.ttf") if mark.is_valid_int() else null
				ml.font_size = 96
				ml.pixel_size = 0.0042
				ml.outline_size = 14
				ml.modulate = Color.WHITE
				ml.outline_modulate = Color(0.04, 0.05, 0.08)
				ml.shaded = false
				ml.position = Vector3(0.62 if fi == 0 else 0.22, 0.72 if fi == 0 else 0.8, sz * (box.size.z * s * 0.5 + 0.02) if box.size.x >= box.size.z else sz * (box.size.x * s * 0.5 + 0.02))
				ml.rotation.y = 0.0 if sz > 0.0 else PI
				holder.add_child(ml)
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
uniform float gain = 1.0;
void fragment() {
	float along = UV.x;
	float across = 1.0 - abs(UV.y - 0.5) * 2.0;
	float core = pow(max(across, 0.0), 5.0);
	float flick = 0.85 + 0.15 * sin(TIME * 40.0 + UV.x * 30.0);
	ALBEDO = mix(tint, vec3(1.0), core * 0.7);
	ALPHA = pow(max(along, 0.0), 1.6) * (0.25 * across + core) * flick * gain;
}
"""
	for k in 3:
		var trail := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(16.0, [0.5, 0.9, 0.34][k])
		trail.mesh = qm
		var m := ShaderMaterial.new()
		m.shader = _trail_sh
		m.set_shader_parameter("tint", trail_col)
		m.set_shader_parameter("gain", trail_scale if trail_scale < 1.0 and index == 0 else 1.0)
		trail.material_override = m
		if k == 1:
			# Flat on the road: the glow the runner leaves on the wet asphalt.
			trail.rotation.x = -PI / 2.0
			trail.position = Vector3(-8.6, 0.03, 0.0)
		else:
			trail.position = Vector3(-8.9, 0.42 + k * 0.2, 0.0)
		trail.set_meta("front", trail.position.x + 8.0)
		holder.add_child(trail)
		_trails.append(trail)
	return [holder, fig]


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
var _dome: ShaderMaterial
var weather := {"mood": "dusk", "rain": false}
var _rain_node: GPUParticles3D
var _sprays: Array = []


## (0.74.0) The hour and the weather on the road: "dusk" (the usual), "night" or "dawn", with or
## without rain. Rain soaks the road (longer mirrored lights), hides the stars and, when the
## graphics allow it, falls past `host` (the camera) and sprays off every rear wheel.
func set_weather(mood: String, rain: bool, host: Node3D = null) -> void:
	weather = {"mood": mood, "rain": rain}
	Sfx.weather("rain" if rain else "", -15.0)
	var detail := int(Settings.gfx.get("detail", 2))
	if _dome:
		_dome.set_shader_parameter("night", 1.0 if mood == "night" else 0.0)
		_dome.set_shader_parameter("dawn", 1.0 if mood == "dawn" else 0.0)
		_dome.set_shader_parameter("rain", 1.0 if rain else 0.0)
	if _road:
		_road.set_shader_parameter("wet", 1.0 if rain else 0.7)
		var ref: Color = accent * 0.8 + Color(0.35, 0.05, 0.25)
		if mood == "night":
			ref = ref * 0.45
		elif mood == "dawn":
			ref = Color(0.75, 0.62, 0.5)
		if rain:
			ref = ref.lerp(Color(0.32, 0.34, 0.4), 0.6)
		_road.set_shader_parameter("sky_ref", ref)
	if is_instance_valid(_rain_node):
		_rain_node.queue_free()
	for sp in _sprays:
		if is_instance_valid(sp):
			sp.queue_free()
	_sprays.clear()
	if rain and host != null and detail >= 1:
		_rain_node = _make_rain(320 if detail <= 1 else 700)
		host.add_child(_rain_node)
	if rain and detail >= 2:
		for i in _bikes.size():
			var sp := _make_spray()
			(_bikes[i][0] as Node3D).add_child(sp)
			_sprays.append(sp)


func _make_rain(n: int) -> GPUParticles3D:
	var gp := GPUParticles3D.new()
	gp.amount = n
	gp.lifetime = 0.7
	gp.preprocess = 0.7
	gp.local_coords = false
	gp.visibility_aabb = AABB(Vector3(-30, -20, -30), Vector3(60, 40, 60))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(15, 1, 9)
	pm.direction = Vector3(0, -1, 0.35)     # (in the camera's own frame: down and back past you)
	pm.spread = 4.0
	pm.initial_velocity_min = 26.0
	pm.initial_velocity_max = 32.0
	pm.gravity = Vector3.ZERO
	pm.particle_flag_align_y = true
	gp.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(0.018, 0.75)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.albedo_color = Color(0.7, 0.8, 1.0, 0.26)
	qm.material = m
	gp.draw_pass_1 = qm
	gp.position = Vector3(0.0, 7.0, -13.0)      # (all ahead of the lens: a drop right in front of it is a white bar)
	return gp


## Water thrown up behind a rear wheel on a wet road.
func _make_spray() -> CPUParticles3D:
	var sp := CPUParticles3D.new()
	sp.amount = 22
	sp.lifetime = 0.45
	sp.direction = Vector3(-1, 0.55, 0)
	sp.spread = 18.0
	sp.initial_velocity_min = 4.0
	sp.initial_velocity_max = 8.0
	sp.gravity = Vector3(0, -9, 0)
	sp.scale_amount_min = 0.6
	sp.scale_amount_max = 1.4
	var fade := Gradient.new()
	fade.set_color(0, Color(0.8, 0.85, 0.95, 0.35))
	fade.set_color(1, Color(0.8, 0.85, 0.95, 0.0))
	sp.color_ramp = fade
	var qm := QuadMesh.new()
	qm.size = Vector2(0.35, 0.35)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _puff()
	qm.material = m
	sp.mesh = qm
	sp.position = Vector3(-1.05, 0.15, 0)
	return sp


## Lights on the road for the wet asphalt to mirror: up to 8 of [Vector3 at, Color, strength].
## Most of them come from set_lights; the runners' own glow is added here every frame.
var _ext_lights: Array = []


func set_lights(list: Array) -> void:
	_ext_lights = list


func _push_reflections() -> void:
	if _road == null:
		return
	var pos := PackedVector4Array()
	var cols := PackedVector4Array()
	pos.resize(8)
	cols.resize(8)
	var n := 0
	if int(Settings.gfx.get("detail", 2)) >= 1:
		for b in _bikes:
			if n >= 8:
				break
			var h: Node3D = b[0]
			if not is_instance_valid(h) or not h.visible or absf(h.position.x) > 90.0:
				continue
			var lc: Color = h.get_meta("glow", Color(1, 0.6, 0.3))
			pos[n] = Vector4(h.position.x - 0.9, h.position.z, 0.55, 0.8)
			cols[n] = Vector4(lc.r, lc.g, lc.b, 1.0)
			n += 1
		for e in _ext_lights:
			if n >= 8:
				break
			var at: Vector3 = e[0]
			var c: Color = e[1]
			pos[n] = Vector4(at.x, at.z, float(e[2]), 1.0)
			cols[n] = Vector4(c.r, c.g, c.b, 1.0)
			n += 1
	_road.set_shader_parameter("refl", pos)
	_road.set_shader_parameter("refl_col", cols)
	_road.set_shader_parameter("refl_n", n)


## (0.74.1) Each runner's own engine, heard from where it is: pitch follows `rev` (0 idling
## along, 1 flat out), `base` sets the voice of the machine (a big bike lower, a light one higher).
var _engines := {}      # index -> [AudioStreamPlayer3D, base pitch, rev now, rev wanted]


func engine_on(i: int, base := 1.0, volume_db := -8.0) -> void:
	if i >= _bikes.size() or _engines.has(i):
		return
	var ap := AudioStreamPlayer3D.new()
	ap.bus = "SFX"
	ap.volume_db = volume_db
	ap.unit_size = 7.0
	ap.max_distance = 140.0
	ap.attenuation_filter_cutoff_hz = 9000.0
	ap.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_IDLE_STEP
	(_bikes[i][0] as Node3D).add_child(ap)
	_engines[i] = [ap, base, 0.3, 0.3]


func set_rev(i: int, rev: float) -> void:
	if _engines.has(i):
		_engines[i][3] = clampf(rev, 0.0, 1.2)


func _engines_step(delta: float) -> void:
	for i in _engines:
		var e: Array = _engines[i]
		var ap: AudioStreamPlayer3D = e[0]
		if not is_instance_valid(ap):
			continue
		if ap.stream == null:
			var st = Sfx.loop("engine")
			if st == null:
				continue
			ap.stream = st
			ap.play(randf() * 2.0)
		e[2] = lerpf(float(e[2]), float(e[3]), clampf(delta * 2.5, 0.0, 1.0))
		var fx: Dictionary = _fx.get(i, {})
		var kick := 0.18 if fx.has("surge") else (-0.12 if fx.has("wobble") else 0.0)
		ap.pitch_scale = clampf(float(e[1]) * (0.72 + 0.6 * float(e[2]) + kick), 0.4, 2.4)


func _exit_tree_sound() -> void:
	if bool(weather.get("rain", false)):
		Sfx.weather("")


## Sparks off a runner scraping along the barrier (ride mode), on or off.
func scrape(i: int, on: bool) -> void:
	if i >= _bikes.size():
		return
	var fx: Dictionary = _fx.get(i, {})
	if on:
		_sparks_for(i, fx)
		(fx["sparks"] as CPUParticles3D).emitting = true
	elif fx.has("sparks") and is_instance_valid(fx["sparks"]) and not fx.has("wobble"):
		(fx["sparks"] as CPUParticles3D).emitting = false
	_fx[i] = fx


## The rider tucks in behind the screen: 0 sitting up, 1 flat out (a boost).
func set_tuck(i: int, amount: float) -> void:
	if i < _bikes.size():
		(_bikes[i][0] as Node3D).set_meta("tuck", amount)


var _lead := [0.0, 0.0]        # how far ahead each runner rides right now (the Life Points lead)
var _lead_to := [0.0, 0.0]


var _side := [0.0, 0.0]        # pulled across toward the other runner (riding alongside)
var _side_to := [0.0, 0.0]


## (0.74.1) For `secs` this runner swings across next to the other one, then back to its line.
func alongside(i: int, secs: float) -> void:
	if i < 0 or i > 1 or _bikes.size() < 2:
		return
	var gap := (_bikes[1 - i][1] as Vector3).z - (_bikes[i][1] as Vector3).z
	if absf(gap) > 6.0:
		return      # (riding at the two ends of the field: the burst of speed says it alone)
	_side_to[i] = gap - signf(gap) * 1.5
	get_tree().create_timer(secs).timeout.connect(func(): _side_to[i] = 0.0)


## A thin trail of smoke from a runner in trouble, on or off.
func low_smoke(i: int, on: bool) -> void:
	if i >= _bikes.size():
		return
	var h: Node3D = _bikes[i][0]
	var sm = h.get_meta("low_smoke") if h.has_meta("low_smoke") else null
	if on and not (sm is CPUParticles3D and is_instance_valid(sm)):
		var sp := smoke(i)
		if sp:
			sp.amount = 18
			sp.scale_amount_max = 0.7
			h.set_meta("low_smoke", sp)
	elif not on and sm is CPUParticles3D and is_instance_valid(sm):
		(sm as CPUParticles3D).emitting = false
		h.remove_meta("low_smoke")
		get_tree().create_timer(1.5).timeout.connect(func(): if is_instance_valid(sm): sm.queue_free())


## Ride `x` meters ahead of (or behind, below 0) where this runner usually rides.
func set_lead(i: int, x: float) -> void:
	if i >= 0 and i < 2:
		_lead_to[i] = x


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
	_sparks_for(i, fx)
	(fx["sparks"] as CPUParticles3D).emitting = true
	_fx[i] = fx


func _sparks_for(i: int, fx: Dictionary) -> void:
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


var blow_busy := false


## Thick smoke off a runner that has been beaten.
func smoke(i: int) -> CPUParticles3D:
	if i >= _bikes.size():
		return null
	var sp := CPUParticles3D.new()
	sp.amount = 46
	sp.lifetime = 1.1
	sp.direction = Vector3(-1, 0.5, 0)
	sp.spread = 16.0
	sp.initial_velocity_min = 3.0
	sp.initial_velocity_max = 7.0
	sp.gravity = Vector3(-6, 2.2, 0)
	sp.scale_amount_min = 0.5
	sp.scale_amount_max = 1.1
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.35))
	grow.add_point(Vector2(1.0, 1.0))
	sp.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_color(0, Color(0.5, 0.42, 0.38, 0.75))
	fade.set_color(1, Color(0.08, 0.08, 0.09, 0.0))
	sp.color_ramp = fade
	var qm := QuadMesh.new()
	qm.size = Vector2(1.5, 1.5)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _puff()
	qm.material = m
	sp.mesh = qm
	sp.position = Vector3(-0.8, 0.7, 0)
	(_bikes[i][0] as Node3D).add_child(sp)
	return sp


var _puff_tex: GradientTexture2D


func _puff() -> GradientTexture2D:
	if _puff_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		_puff_tex = GradientTexture2D.new()
		_puff_tex.gradient = g
		_puff_tex.fill = GradientTexture2D.FILL_RADIAL
		_puff_tex.fill_from = Vector2(0.5, 0.5)
		_puff_tex.fill_to = Vector2(0.5, 0.0)
		_puff_tex.width = 64
		_puff_tex.height = 64
	return _puff_tex


## The last hit of a Turbo Duel, slowed right down: both runners pull out ahead of the field
## side by side, the beaten one shakes, starts to smoke and falls away behind while the winner
## goes clear. `blow_busy` is true until both are back where they ride.
func finish_blow(loser: int) -> void:
	if _bikes.size() < 2 or blow_busy or loser < 0 or loser > 1:
		return
	blow_busy = true
	var homes: Array = [_bikes[0][1], _bikes[1][1]]
	var slide := func(i: int, to: Vector3, secs: float) -> void:
		var from: Vector3 = _bikes[i][1]
		var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_method(func(v: Vector3): _bikes[i][1] = v, from, to, secs)
	Engine.time_scale = 0.3
	for i in 2:
		slide.call(i, Vector3(11.0, 0, signf((homes[i] as Vector3).z) * 1.9), 0.14)
	wobble(loser, true)
	smoke(loser)
	# (Dev: --blow-hold keeps this first beat up long enough for a still picture.)
	await get_tree().create_timer(30.0 if "--blow-hold" in OS.get_cmdline_user_args() else 0.8, true, false, true).timeout
	if not is_inside_tree():
		Engine.time_scale = 1.0
		return
	slide.call(loser, Vector3(3.5, 0, signf((homes[loser] as Vector3).z) * 2.8), 0.4)
	slide.call(1 - loser, Vector3(13.0, 0, signf((homes[1 - loser] as Vector3).z) * 1.3), 0.4)
	wobble(loser, true)
	await get_tree().create_timer(1.3, true, false, true).timeout
	Engine.time_scale = 1.0
	if not is_inside_tree():
		return
	slide.call(1 - loser, homes[1 - loser], 0.7)
	slide.call(loser, (homes[loser] as Vector3) + Vector3(-3.0, 0, 0), 0.7)
	await get_tree().create_timer(0.7).timeout
	blow_busy = false


func _exit_tree() -> void:
	_exit_tree_sound()
	if blow_busy:
		Engine.time_scale = 1.0


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


const TUCK_SIGN := 1.0


func _process(delta: float) -> void:
	_t += delta
	_push_reflections()
	_engines_step(delta)
	_react_step(delta)
	speed = lerpf(speed, target_speed, clampf(delta * 1.5, 0.0, 1.0))
	# Every repeat on the road (6, 12, 16, 20, 36, 48 ... meters) divides this, so nothing
	# jumps when the count starts over.
	_offset = fmod(_offset + speed * delta, 5760.0)
	_far_off += speed * delta
	for sm in _scroll:
		sm.set_shader_parameter("offset", _offset)
		sm.set_shader_parameter("blur", clampf(speed / 22.0, 0.8, 3.0))
		sm.set_shader_parameter("curve", curve)
	for bm2 in _bent:
		bm2.set_shader_parameter("curve", curve)
	if _sweep:
		_sweep.set_shader_parameter("offset", _far_off)
	if _road:
		_road.set_shader_parameter("offset", _offset)
		_road.set_shader_parameter("blur", clampf(speed / 22.0, 0.8, 3.0))
		_road.set_shader_parameter("curve", curve)
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
			var fg = h.get_meta("fig") if h.has_meta("fig") else null
			if fg is Node3D and is_instance_valid(fg):
				var tk := float(h.get_meta("tuck", 0.0))
				var fn := fg as Node3D
				if not fn.has_meta("home"):
					fn.set_meta("home", fn.position)
				fn.rotation.x = lerpf(fn.rotation.x, TUCK_SIGN * tk * 0.2, clampf(delta * 6.0, 0.0, 1.0))
				# (it bends at the hips, not at the feet: the legs stay where they are on the runner)
				var piv := Vector3(0, 0.95, 0) * fn.scale.x
				var home: Vector3 = fn.get_meta("home")
				fn.position = home + Basis.from_euler(Vector3(0, fn.rotation.y, 0)) * piv - Basis.from_euler(fn.rotation) * piv + Vector3(0, -0.04 * tk, 0)
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
		var across := 0.0
		if idx < 2:
			_lead[idx] = lerpf(float(_lead[idx]), float(_lead_to[idx]), clampf(delta * 0.9, 0.0, 1.0))
			_side[idx] = lerpf(float(_side[idx]), float(_side_to[idx]), clampf(delta * 2.0, 0.0, 1.0))
			across = float(_side[idx])
		var ahead := float(_lead[idx]) if idx < 2 else 0.0
		h.position = base + Vector3(ahead + sin(_t * 0.43 + ph) * 0.5 + surge * 2.4 - wob * 0.9, absf(sin(_t * 9.0 + ph)) * 0.012, across + sway * 0.28 + sin(_t * 24.0) * 0.22 * wob)
		h.rotation.x = cos(_t * 0.7 + ph) * 0.07 + sin(_t * 31.0) * 0.16 * wob
		h.rotation.z = surge * 0.2
	for tr in _trails:
		# The trail grows backwards only: its front end stays pinned just behind the rear wheel.
		# (It used to stretch from its middle, so at speed the front half came out ahead of the runner.)
		var k: float = (0.5 + speed / 40.0) * trail_scale + sin(_t * 30.0) * 0.04
		tr.scale.x = k
		tr.position.x = float(tr.get_meta("front", -0.6)) - 8.0 * k
	for bc in _beacons:
		(bc[0] as Node3D).visible = fmod(_t + float(bc[1]), 1.6) < 0.8
	for bm in _beams:
		var pv: Node3D = bm[0]
		pv.rotation.x = sin(_t * float(bm[2]) + float(bm[1])) * 0.45
		pv.rotation.z = cos(_t * float(bm[2]) * 0.7 + float(bm[1])) * 0.35
	for fl in _far:
		(fl[0] as ShaderMaterial).set_shader_parameter("offset", _far_off * float(fl[1]) * float(fl[2]) * -1.0)
