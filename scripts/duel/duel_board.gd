class_name DuelBoard
extends Node3D
## The 3D duel field: mat, zones, cards, camera and every duel animation.
## Player 0 sits at +Z (near the camera), player 1 at -Z.

signal card_clicked(card: Card3D)
signal card_hovered(card: Card3D, inside: bool)

const ZONE_SPACING := 1.3
const MONSTER_ROW := 1.05
const SPELL_ROW := 2.35
const SIDE_X := 4.15
const CAM_POS := Vector3(0, 10.2, 5.2)
const CAM_TARGET := Vector3(0, 0, 0.98)

signal ace_summoned(inst)
signal direct_clicked
signal extra_clicked
signal deck_clicked
signal pile_clicked(p: int)

## Cinematic camera: blends from the table view toward cam_pos / cam_target by cam_weight.
var cam_pos := Vector3(0, 4, 12)
var cam_target := Vector3.ZERO
var cam_weight := 0.0
var _cam_tween: Tween

var camera: Camera3D
var _battle_mode := false
var theme: Dictionary = FieldThemes.resolve("auto", "")
var turbo := false           # a Turbo Duel: the field rides down a highway
var track: TurboTrack
var _cards := {}  # uid -> Card3D
var _gy_cards: Array = [[], []]
var _ban_cards: Array = [[], []]
var _ban_labels: Array = [null, null]
var state_ref: DuelState   # set by the scene, so piles know where a card really ended up
const BANISH_COLOR := Color("b06cff")
var _opp_hand: Array[Card3D] = []
var _deck_piles: Array[Node3D] = []
var _deck_labels: Array[Label3D] = []
var _extra_piles: Array[Node3D] = []
var _extra_labels: Array[Label3D] = []
var _extra_ready: Label3D
var _extra_ring: MeshInstance3D
var _shake := 0.0
var _time := 0.0
var _zone_shader: Shader
var _stats := {}  # uid -> [atk_label, def_label]
var _aim_from: Card3D = null
var _aim_target: Card3D = null
var _arrow: Node3D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_build_environment()
	_build_mat()
	if turbo:
		track = TurboTrack.new()
		track.name = "Track"
		add_child(track)
		track.build(theme["accent"], theme["accent2"])
		add_child(track.lamp_sweep(Vector2(17.0, 11.0), 0.045))
	else:
		_build_arena()
	_build_zones()
	_build_decks()


# ------------------------------------------------------------------ layout

func monster_zone_pos(p: int, zone: int) -> Vector3:
	var x := (zone - 2) * ZONE_SPACING
	return Vector3(x, 0.01, MONSTER_ROW) if p == 0 else Vector3(-x, 0.01, -MONSTER_ROW)


func spell_zone_pos(p: int, zone: int) -> Vector3:
	var x := (zone - 2) * ZONE_SPACING
	return Vector3(x, 0.01, SPELL_ROW) if p == 0 else Vector3(-x, 0.01, -SPELL_ROW)


func deck_pos(p: int) -> Vector3:
	return Vector3(SIDE_X, 0.01, SPELL_ROW) if p == 0 else Vector3(-SIDE_X, 0.01, -SPELL_ROW)


func gy_pos(p: int) -> Vector3:
	return Vector3(SIDE_X, 0.01, MONSTER_ROW) if p == 0 else Vector3(-SIDE_X, 0.01, -MONSTER_ROW)


## The Extra Deck: face down, left of the Spell & Trap row (across from the Deck).
func extra_pos(p: int) -> Vector3:
	return Vector3(-SIDE_X, 0.01, SPELL_ROW) if p == 0 else Vector3(SIDE_X, 0.01, -SPELL_ROW)


## The Field Zone: left of the monster row.
func field_pos(p: int) -> Vector3:
	return Vector3(-SIDE_X, 0.01, MONSTER_ROW) if p == 0 else Vector3(SIDE_X, 0.01, -MONSTER_ROW)


## Spell & Trap zone 0-4, or 5 for the Field Zone.
func st_pos(p: int, zone: int) -> Vector3:
	return field_pos(p) if zone >= 5 else spell_zone_pos(p, zone)


## The banished pile sits just outside the Graveyard.
func banish_pos(p: int) -> Vector3:
	return Vector3(SIDE_X + 0.92, 0.01, MONSTER_ROW) if p == 0 else Vector3(-SIDE_X - 0.92, 0.01, -MONSTER_ROW)


## Orientation for a card lying on the table.
func table_basis(p: int, face_up: bool, attack_pos: bool) -> Basis:
	var yaw := 0.0 if p == 0 else PI
	if not attack_pos:
		yaw += PI / 2.0
	var pitch := -PI / 2.0 if face_up else PI / 2.0
	return Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)


# ------------------------------------------------------------------ build

func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = theme["sky_top"]
	sky_mat.sky_horizon_color = theme["sky_horizon"]
	sky_mat.ground_bottom_color = Color(theme["base"]).darkened(0.5)
	sky_mat.ground_horizon_color = theme["sky_horizon"]
	sky_mat.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(theme["accent"]).lerp(Color.WHITE, 0.6)
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.1
	env.glow_hdr_threshold = 0.95
	env.fog_enabled = true
	env.fog_light_color = theme["fog"]
	env.fog_density = 0.006
	env.fog_sky_affect = 0.4
	Settings.tune_environment(env)
	env.sdfgi_enabled = false
	env.volumetric_fog_density = 0.004
	env.volumetric_fog_albedo = Color(theme["fog"]).lightened(0.3)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	if theme.get("day", false):
		# Open air: a real sun, a paler haze and no night-time bloom on everything.
		env.ambient_light_color = Color(theme["sky_horizon"]).lerp(Color.WHITE, 0.5)
		env.ambient_light_energy = 0.95
		env.fog_density = 0.0035
		env.glow_intensity = 0.25
		sky_mat.sun_angle_max = 8.0
	var key := DirectionalLight3D.new()
	key.light_color = Color("fff1d6") if theme.get("day", false) else Color("e6f3ff")
	key.light_energy = 1.25 if theme.get("day", false) else 0.75
	key.rotation_degrees = Vector3(-62, -18, 0)
	key.shadow_enabled = true
	add_child(key)
	for side in [-1, 1]:
		var l := OmniLight3D.new()
		l.light_color = theme["accent"] if side == 1 else theme["accent2"]
		l.light_energy = 1.8
		l.omni_range = 8.0
		l.position = Vector3(5.8 * side, 1.6, -1.5 * side)
		add_child(l)
	camera = Camera3D.new()
	camera.fov = 44
	if turbo:
		# Lower and further back on the road: the far rider and the skyline stay in the picture.
		cam_home = Vector3(0, 7.0, 9.3)
		cam_home_target = Vector3(0, 0.0, 0.55)
		camera.fov = 46
	camera.position = cam_home
	add_child(camera)
	camera.look_at(cam_home_target)
	camera.current = true


func _build_mat() -> void:
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(12, 7.6)
	mi.mesh = plane
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded;
uniform vec3 base : source_color = vec3(0.025, 0.045, 0.085);
uniform vec3 accent : source_color = vec3(0.18, 0.89, 0.9);
uniform vec3 accent2 : source_color = vec3(0.48, 0.36, 1.0);
uniform int pattern = 0;
uniform int surface = 0;
uniform float dark_paint = 0.0;
//GROUND//

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float line_aa(float d, float w) { return 1.0 - smoothstep(w, w + fwidth(d) * 1.5, d); }

float hex_edge(vec2 p) {
	vec2 r = vec2(1.0, 1.7320508);
	vec2 h = r * 0.5;
	vec2 a = mod(p, r) - h;
	vec2 b = mod(p - h, r) - h;
	vec2 g = dot(a, a) < dot(b, b) ? a : b;
	vec2 q = abs(g);
	float d = max(dot(q, normalize(vec2(1.0, 1.7320508))), q.x);
	return 0.5 - d;
}

float pattern_value(vec2 p) {
	if (pattern == 1) {
		return line_aa(hex_edge(p * 1.6), 0.02);
	} else if (pattern == 2) {
		vec2 g = p * 2.0;
		vec2 cell = floor(g);
		vec2 f = fract(g);
		float hzn = step(0.62, hash(cell)) * line_aa(abs(f.y - 0.5), 0.02);
		float vrt = step(0.7, hash(cell + 17.0)) * line_aa(abs(f.x - 0.5), 0.02);
		float node = step(0.85, hash(cell + 3.0)) * (1.0 - smoothstep(0.06, 0.09, length(f - 0.5)));
		return max(max(hzn, vrt), node);
	} else if (pattern == 3) {
		float r = length(p);
		float rings = line_aa(abs(fract(r * 1.2) - 0.5), 0.02);
		float a = atan(p.y, p.x);
		float ticks = line_aa(abs(fract(a * 6.0 / 3.14159) - 0.5), 0.015) * step(0.5, fract(r * 0.6));
		return max(rings * 0.8, ticks);
	} else if (pattern == 4) {
		vec2 d = vec2(p.x + p.y, p.x - p.y) * 1.2;
		vec2 g = abs(fract(d) - 0.5);
		return line_aa(min(g.x, g.y), 0.015);
	}
	vec2 gp = p * 2.0;
	vec2 g = abs(fract(gp) - 0.5) / fwidth(gp);
	return 1.0 - min(min(g.x, g.y), 1.0);
}

void fragment() {
	vec2 p = (UV - 0.5) * vec2(12.0, 7.6);
	float vig = smoothstep(7.2, 0.5, length(p * vec2(0.72, 1.1)));
	vec3 side = mix(accent, accent2, step(0.0, -p.y));
	vec3 col = base * (0.55 + 0.9 * vig);
	// Patterned floor, brighter near the center
	col += side * pattern_value(p) * 0.075 * vig;
	float wild = step(0.5, float(surface));
	if (surface > 0) {
		// Open-air fields: the ground is the mat, the markings are painted on it.
		col = ground_color(p, surface, TIME) * (0.78 + 0.3 * vig);
	}
	// Rotating emblem rings in the middle
	float r = length(p);
	float a = atan(p.y, p.x);
	float ring1 = line_aa(abs(r - 1.25), 0.03);
	float ring2 = line_aa(abs(r - 1.55), 0.015);
	float dash = step(0.5, fract((a + TIME * 0.15) * 12.0 / 6.28318));
	float ring3 = line_aa(abs(r - 1.85), 0.012) * dash;
	// Outdoors the middle is one painted circle, like the center of a pitch.
	vec3 paint = mix(mix(side, vec3(1.0), 0.7), vec3(0.08, 0.14, 0.36), dark_paint);
	// (No emblem in the middle any more: the center of the field stays clear.)
	col += side * (ring1 + ring2 + ring3) * 0.0;
	// Center divider and a sweeping scan line
	float mid = line_aa(abs(p.y), 0.025);
	col += mix(accent, accent2, 0.5) * mid * 0.35 * vig * (1.0 - wild);
	col = mix(col, paint, line_aa(abs(p.y), 0.014) * 0.5 * wild);
	float sweep = 1.0 - smoothstep(0.0, 0.6, abs(p.x - (fract(TIME * 0.08) * 16.0 - 8.0)));
	col += side * sweep * 0.05 * vig * (1.0 - wild);
	// Frame around the mat
	vec2 e = abs(p) - vec2(5.75, 3.6);
	float frame = line_aa(abs(max(e.x, e.y)), 0.03);
	col += side * frame * 0.8 * (1.0 - wild);
	col = mix(col, paint, line_aa(abs(max(e.x, e.y)), 0.02) * 0.7 * wild);
	ALBEDO = col;
}
"""
	if turbo:
		# The field is a hologram over the road: let the highway show through it.
		sh.code = sh.code.replace("ALBEDO = col;", "ALBEDO = col; ALPHA = clamp(0.42 + dot(col, vec3(1.0)) * 1.6, 0.0, 1.0);")
	sh.code = sh.code.replace("//GROUND//", FieldThemes.GROUND_GLSL)
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("surface", int(theme.get("surface", 0)))
	m.set_shader_parameter("dark_paint", 1.0 if theme.get("dark_paint", false) else 0.0)
	m.set_shader_parameter("base", theme["base"])
	m.set_shader_parameter("accent", theme["accent"])
	m.set_shader_parameter("accent2", theme["accent2"])
	m.set_shader_parameter("pattern", theme["pattern"])
	mi.material_override = m
	add_child(mi)


## Floor beyond the mat, corner pylons and drifting particles.
func _build_arena() -> void:
	var arena := DuelArena.new()
	arena.name = "Arena"
	add_child(arena)
	arena.build_arena(theme)
	for corner in [Vector3(-6.4, 0, -4.1), Vector3(6.4, 0, -4.1), Vector3(-6.4, 0, 4.1), Vector3(6.4, 0, 4.1)]:
		var col: Color = theme["accent"] if corner.z > 0 else theme["accent2"]
		var pylon := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.1
		cyl.bottom_radius = 0.2
		cyl.height = 1.8
		pylon.mesh = cyl
		var pm := StandardMaterial3D.new()
		pm.albedo_color = Color("1a2130")
		pm.metallic = 0.8
		pm.roughness = 0.3
		pylon.material_override = pm
		pylon.position = corner + Vector3(0, 0.9, 0)
		add_child(pylon)
		var orb := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.16
		sm.height = 0.32
		orb.mesh = sm
		var om := StandardMaterial3D.new()
		om.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		om.albedo_color = col
		om.emission_enabled = true
		om.emission = col
		om.emission_energy_multiplier = 5.0
		orb.material_override = om
		orb.position = corner + Vector3(0, 1.9, 0)
		add_child(orb)
		var tw := create_tween().set_loops()
		tw.tween_property(orb, "position:y", 2.05, 1.4).set_trans(Tween.TRANS_SINE)
		tw.tween_property(orb, "position:y", 1.9, 1.4).set_trans(Tween.TRANS_SINE)
	var motes := GPUParticles3D.new()
	motes.amount = 50
	motes.lifetime = 7.0
	motes.preprocess = 7.0
	var ppm := ParticleProcessMaterial.new()
	ppm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	ppm.emission_box_extents = Vector3(7, 0.1, 4.5)
	ppm.direction = Vector3(0, 1, 0)
	ppm.spread = 15
	ppm.initial_velocity_min = 0.05
	ppm.initial_velocity_max = 0.2
	ppm.gravity = Vector3.ZERO
	ppm.scale_min = 0.5
	ppm.scale_max = 1.3
	motes.process_material = ppm
	var q := QuadMesh.new()
	q.size = Vector2(0.025, 0.025)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.albedo_color = Color(theme["accent"]).lightened(0.4)
	qm.emission_enabled = true
	qm.emission = theme["accent"]
	qm.emission_energy_multiplier = 1.5
	q.material = qm
	motes.draw_pass_1 = q
	motes.visibility_aabb = AABB(Vector3(-10, -1, -8), Vector3(20, 10, 16))
	add_child(motes)


## One zone, painted on the ground like a line on a sports field: a thin outline with bolder
## corners and a small icon in the middle saying what goes there. No glow, no filled plate.
## icon: 1 monster, 2 Spell/Trap, 3 Deck, 4 Graveyard, 5 banished, 6 Field Spell, 7 Extra Deck.
func _zone(pos: Vector3, size: Vector2, color: Color, intensity: float, icon := 0, flip := false) -> MeshInstance3D:
	if _zone_shader == null:
		_zone_shader = Shader.new()
		_zone_shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform vec4 color : source_color = vec4(0.18, 0.89, 0.9, 1.0);
uniform float intensity = 0.6;
uniform int icon = 0;
uniform float dark_paint = 0.0;
uniform vec2 extent = vec2(1.0, 1.0);
uniform float flip = 1.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float sd_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}
float fill(float d) { return 1.0 - smoothstep(0.0, 0.06, d); }
void fragment() {
	vec2 p = (UV - 0.5) * extent;
	float d = sd_box(p, extent * 0.5 - 0.03, 0.085);
	float aa = fwidth(d) * 1.2;
	float w = 0.009;
	float line = 1.0 - smoothstep(w, w + aa, abs(d));
	// The corners are drawn a little heavier, fading smoothly into the sides.
	vec2 q = abs(p) / (extent * 0.5);
	float corner = smoothstep(0.5, 0.9, q.x) * smoothstep(0.5, 0.9, q.y);
	float bold = (1.0 - smoothstep(w * 1.9, w * 1.9 + aa, abs(d))) * corner;
	float wear = 1.0;
	float a = max(line * 0.75, bold);
	vec2 ip = p / 0.15;
	ip.y *= flip;
	float ic = 0.0;
	if (icon == 1) {
		float s = pow(abs(ip.x), 0.62) + pow(abs(ip.y), 0.62);
		ic = 1.0 - smoothstep(0.92, 1.02, s);
	} else if (icon == 2) {
		float r = length(ip);
		ic = max(1.0 - smoothstep(0.1, 0.16, abs(r - 0.72)), 1.0 - smoothstep(0.2, 0.26, r));
	} else if (icon == 3) {
		ic = 1.0 - smoothstep(0.07, 0.12, abs(sd_box(ip, vec2(0.5, 0.74), 0.12)));
		ic = max(ic, 1.0 - smoothstep(0.05, 0.1, abs(sd_box(ip, vec2(0.22, 0.34), 0.08))));
	} else if (icon == 4) {
		float bar_v = fill(sd_box(ip, vec2(0.13, 0.8), 0.04));
		float bar_h = fill(sd_box(ip + vec2(0.0, 0.28), vec2(0.5, 0.13), 0.04));
		ic = max(bar_v, bar_h);
	} else if (icon == 5) {
		vec2 r = vec2(ip.x + ip.y, ip.x - ip.y) * 0.7071;
		ic = max(fill(sd_box(r, vec2(0.12, 0.8), 0.04)), fill(sd_box(r, vec2(0.8, 0.12), 0.04)));
	} else if (icon == 6) {
		float tri = max(abs(ip.x) * 1.25 - ip.y * 0.72 - 0.42, ip.y - 0.62);
		ic = fill(tri);
	} else if (icon == 7) {
		float ang = atan(ip.x, -ip.y);
		float r = length(ip);
		ic = 1.0 - smoothstep(0.0, 0.08, r - (0.52 + 0.3 * cos(ang * 5.0)));
	}
	a = max(a, ic * 0.42 * wear);
	ALBEDO = mix(mix(color.rgb, vec3(1.0), 0.62), mix(color.rgb * 0.3, vec3(0.05, 0.1, 0.3), 0.6), dark_paint);
	ALPHA = a * clamp(0.5 + intensity * 0.45, 0.0, 0.95);
}
"""
	var mi := MeshInstance3D.new()
	var q := PlaneMesh.new()
	q.size = size
	mi.mesh = q
	var m := ShaderMaterial.new()
	m.shader = _zone_shader
	m.set_shader_parameter("color", color)
	m.set_shader_parameter("intensity", intensity)
	m.set_shader_parameter("icon", icon)
	m.set_shader_parameter("extent", size)
	m.set_shader_parameter("flip", -1.0 if flip else 1.0)
	m.set_shader_parameter("dark_paint", 1.0 if theme.get("dark_paint", false) else 0.0)
	mi.material_override = m
	mi.position = pos + Vector3(0, 0.002, 0)
	add_child(mi)
	return mi


func _build_zones() -> void:
	for p in 2:
		var col: Color = theme["accent"] if p == 0 else theme["accent2"]
		var up := p == 1
		for z in 5:
			_zone(monster_zone_pos(p, z), Vector2(0.98, 0.98), col, 0.9, 1, up)
			_zone(spell_zone_pos(p, z), Vector2(0.72, 0.98), col, 0.6, 2, up)
		_zone(deck_pos(p), Vector2(0.72, 0.98), col, 0.6, 3, up)
		_zone(gy_pos(p), Vector2(0.72, 0.98), col, 0.6, 4, up)
		_zone(banish_pos(p), Vector2(0.72, 0.98), BANISH_COLOR, 0.35, 5, up)
		_zone(field_pos(p), Vector2(0.72, 0.98), Color("3ddc97"), 0.6, 6, up)
		_zone(extra_pos(p), Vector2(0.72, 0.98), Color("b06bff"), 0.6, 7, up)
		var bl := Label3D.new()
		bl.text = "BANISHED"
		bl.font = UITheme.semi_font()
		bl.font_size = 34
		bl.pixel_size = 0.004
		bl.modulate = Color(BANISH_COLOR, 0.0)
		bl.outline_modulate = Color(0, 0, 0, 0.0)
		bl.rotation = Vector3(-PI / 2, 0.0 if p == 0 else PI, 0)
		bl.position = banish_pos(p) + Vector3(0, 0.012, 0.64 if p == 0 else -0.64)
		add_child(bl)
		_ban_labels[p] = bl


func _build_decks() -> void:
	for p in 2:
		var pile := Node3D.new()
		pile.position = deck_pos(p)
		add_child(pile)
		var body := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(Card3D.SIZE.x, 1.0, Card3D.SIZE.y)
		body.mesh = box
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color("1a2233")
		body.material_override = bm
		pile.add_child(body)
		var top := Card3D.new()
		top.setup(0, p)
		top.set_pickable(p == 0)
		if p == 0:
			top.clicked.connect(func(_c): deck_clicked.emit())
			top.hovered.connect(func(_c, inside): top.set_glow(inside, Color("ffd98a")))
		pile.add_child(top)
		_deck_piles.append(pile)
		var lbl := _count_chip(deck_pos(p) + Vector3(0, 0, 0.7 if p == 0 else -0.7), Color.WHITE)
		_deck_labels.append(lbl)
		_gy_labels.append(_count_chip(gy_pos(p) + Vector3(0, 0, 0.7 if p == 0 else -0.7), Color("c9d6ff")))
		set_deck_count(p, 0)
		# The Extra Deck pile. Yours opens when you click it.
		var ep := Node3D.new()
		ep.position = extra_pos(p)
		add_child(ep)
		var eb := MeshInstance3D.new()
		var ebox := BoxMesh.new()
		ebox.size = Vector3(Card3D.SIZE.x, 1.0, Card3D.SIZE.y)
		eb.mesh = ebox
		var em := StandardMaterial3D.new()
		em.albedo_color = Color("2a1a3d")
		eb.material_override = em
		ep.add_child(eb)
		var etop := Card3D.new()
		etop.setup(0, p)
		etop.set_pickable(p == 0)
		if p == 0:
			etop.clicked.connect(func(_c): extra_clicked.emit())
			etop.hovered.connect(func(_c, inside): etop.set_glow(inside, Color("b06bff")))
		ep.add_child(etop)
		_extra_piles.append(ep)
		var el := _count_chip(extra_pos(p) + Vector3(0, 0, 0.7 if p == 0 else -0.7), Color("d9b8ff"))
		_extra_labels.append(el)
		set_extra_count(p, 0)
	_extra_ready = Label3D.new()
	_extra_ready.text = "SUMMON READY"
	_extra_ready.font = UITheme.title_font()
	_extra_ready.font_size = 40
	_extra_ready.pixel_size = 0.004
	_extra_ready.outline_size = 12
	_extra_ready.modulate = Color("ffd23a")
	_extra_ready.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_extra_ready.position = extra_pos(0) + Vector3(0, 0.75, 0.2)
	_extra_ready.visible = false
	add_child(_extra_ready)
	_extra_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.62
	tm.outer_radius = 0.7
	_extra_ring.mesh = tm
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color("ffd23a")
	_extra_ring.material_override = rm
	_extra_ring.position = extra_pos(0) + Vector3(0, 0.02, 0)
	_extra_ring.scale = Vector3(1, 0.3, 1.25)
	_extra_ring.visible = false
	add_child(_extra_ring)


var _gy_labels: Array[Label3D] = []


## A pile's count: a number on a small dark chip painted on the table just outside the pile,
## where it never sits half on the cards.
func _count_chip(pos: Vector3, color: Color) -> Label3D:
	var l := Label3D.new()
	l.font = Comic.button_font()
	l.font_size = 60
	l.pixel_size = 0.0036
	l.outline_size = 0
	l.modulate = color
	l.rotation = Vector3(-PI / 2.0, 0, 0)
	l.position = pos + Vector3(0, 0.014, 0)
	l.render_priority = 2
	l.visible = false
	add_child(l)
	var chip := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.46, 0.27)
	chip.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.03, 0.045, 0.1, 0.82)
	chip.material_override = m
	chip.position = Vector3(0, 0, -0.004)
	l.add_child(chip)
	return l


func _set_chip(l: Label3D, text: String) -> void:
	l.text = text
	l.visible = text != ""


func set_gy_count(p: int, count: int) -> void:
	if p < _gy_labels.size():
		_set_chip(_gy_labels[p], str(count) if count > 0 else "")


func set_extra_count(p: int, count: int, ready := 0) -> void:
	if p >= _extra_piles.size():
		return
	var h := maxf(0.004, count * 0.012)
	var pile := _extra_piles[p]
	var body := pile.get_child(0) as MeshInstance3D
	body.scale = Vector3(1, h, 1)
	body.position.y = h / 2.0
	var top := pile.get_child(1) as Card3D
	top.transform = Transform3D(table_basis(p, false, true), Vector3(0, h + 0.004, 0))
	pile.visible = count > 0
	_set_chip(_extra_labels[p], str(count) if count > 0 else "")
	if p == 0 and _extra_ready:
		_extra_ready.visible = ready > 0
		_extra_ring.visible = ready > 0
		_extra_ready.text = Loc.t("SUMMON READY") if ready == 1 else Loc.t("SUMMON READY  x%d") % ready


func _process_extra(t: float) -> void:
	if _extra_ring and _extra_ring.visible:
		var k := 1.0 + sin(t * 4.0) * 0.06
		_extra_ring.scale = Vector3(k, 0.3, 1.25 * k)
		_extra_ready.position.y = extra_pos(0).y + 0.75 + sin(t * 3.0) * 0.05


func set_deck_count(p: int, count: int) -> void:
	var h := maxf(0.004, count * 0.006)
	var pile := _deck_piles[p]
	var body := pile.get_child(0) as MeshInstance3D
	body.scale = Vector3(1, h, 1)
	body.position.y = h / 2.0
	var top := pile.get_child(1) as Card3D
	top.transform = Transform3D(table_basis(p, false, true), Vector3(0, h + 0.004, 0))
	pile.visible = count > 0
	_set_chip(_deck_labels[p], str(count) if count > 0 else "")


# ------------------------------------------------------------------ cards

func _new_card(inst) -> Card3D:
	var c := Card3D.new()
	c.setup(inst.id, int(inst.owner))
	c.inst = inst
	add_child(c)
	c.clicked.connect(func(card): card_clicked.emit(card))
	c.hovered.connect(func(card, inside): card_hovered.emit(card, inside))
	_cards[inst.uid] = c
	return c


func card_for(inst) -> Card3D:
	return _cards.get(inst.uid)


var cam_home := CAM_POS
var cam_home_target := CAM_TARGET
var deal_fast := false
var _holos := {}      # card uid -> MonsterHolo


## Keep one hologram over every face-up monster on the field, and break the ones that left.
func sync_holos(state) -> void:
	var seen := {}
	for p in state.players.size():
		for m in state.players[p].monsters():
			if m == null or not m.face_up:
				continue
			var c := card_for(m)
			if c == null:
				continue
			seen[m.uid] = true
			var h: MonsterHolo = _holos.get(m.uid)
			if h == null or not is_instance_valid(h):
				h = MonsterHolo.new()
				add_child(h)
				h.setup(m, c, ATTR_COLORS.get(str(m.data.get("attribute", "")), UITheme.ACCENT), Settings.t(0.75))
				_holos[m.uid] = h
			h.card = c
			h.set_defense(not m.attack_pos)
	for uid in _holos.keys():
		if not seen.has(uid):
			var h2: MonsterHolo = _holos[uid]
			if is_instance_valid(h2):
				h2.shatter()
			_holos.erase(uid)


## The hologram standing over a card, if there is one.
func holo_for(inst) -> MonsterHolo:
	if inst == null:
		return null
	var h: MonsterHolo = _holos.get(inst.uid)
	return h if h != null and is_instance_valid(h) else null


func _move(c: Card3D, to: Transform3D, dur: float, arc := 0.6) -> void:
	var from := c.transform
	var q0 := from.basis.get_rotation_quaternion()
	var q1 := to.basis.get_rotation_quaternion()
	var tw := create_tween()
	tw.tween_method(func(t: float):
		var e := ease(t, -2.2)
		var pos := from.origin.lerp(to.origin, e)
		pos.y += sin(PI * e) * arc
		c.transform = Transform3D(Basis(q0.slerp(q1, e)), pos), 0.0, 1.0, Settings.t(dur))
	await tw.finished


func _wait(sec: float) -> void:
	await get_tree().create_timer(Settings.t(sec)).timeout


func _near_camera_xform() -> Transform3D:
	var b := Basis(Vector3.RIGHT, -0.75)
	return Transform3D(b, Vector3(0, 4.6, 4.3))


func _layout_opp_hand() -> void:
	var n := _opp_hand.size()
	for i in n:
		var c := _opp_hand[i]
		var x := (i - (n - 1) / 2.0) * 0.5
		var b := Basis(Vector3.UP, PI) * Basis(Vector3.RIGHT, 0.55) * Basis(Vector3.BACK, (i - (n - 1) / 2.0) * 0.06)
		var t := Transform3D(b, Vector3(x, 1.0 + abs(i - (n - 1) / 2.0) * -0.03, -3.75))
		var tw := create_tween()
		tw.tween_property(c, "transform", t, Settings.t(0.25))


func anim_draw(p: int, inst, deck_count: int) -> void:
	var c := _new_card(inst)
	c.set_pickable(false)
	c.transform = Transform3D(table_basis(p, false, true), deck_pos(p) + Vector3(0, deck_count * 0.006 + 0.02, 0))
	set_deck_count(p, deck_count)
	if p == 0:
		if deal_fast:
			# Dealing: the card is already on its way to the hand when the next one leaves the deck.
			var fly := func():
				await _move(c, _near_camera_xform(), 0.24, 0.7)
				var ftw := create_tween()
				ftw.tween_method(c.set_alpha, 1.0, 0.0, Settings.t(0.08))
				await ftw.finished
				_cards.erase(inst.uid)
				c.queue_free()
			fly.call()
			await _wait(0.16)
			return
		await _move(c, _near_camera_xform(), 0.3, 0.8)
		var tw := create_tween()
		tw.tween_method(c.set_alpha, 1.0, 0.0, Settings.t(0.1))
		await tw.finished
		_cards.erase(inst.uid)
		c.queue_free()
	else:
		_opp_hand.append(c)
		_layout_opp_hand()
		await _wait(0.1 if deal_fast else 0.2)


## Removes a card from the opponent's 3D hand and returns its node.
func _take_from_opp_hand(inst) -> Card3D:
	var c := card_for(inst)
	if c == null:
		c = _new_card(inst)
	_opp_hand.erase(c)
	_layout_opp_hand()
	return c


func anim_summon(p: int, inst, zone: int, set_card: bool) -> void:
	var c: Card3D
	if p == 0:
		c = _new_card(inst)
		c.transform = _near_camera_xform()
	else:
		c = _take_from_opp_hand(inst)
	c.set_pickable(true)
	var to := Transform3D(table_basis(p, not set_card, not set_card), monster_zone_pos(p, zone) + Vector3(0, 0.02, 0))
	var hover := Transform3D(to.basis, to.origin + Vector3(0, 1.1, 0))
	await _move(c, hover, 0.3, 0.4)
	if not _orbs.is_empty():
		await _consume_orbs(to.origin)
	await _move(c, to, 0.11, 0.0)
	_burst(to.origin, Comic.SKY if p == 0 else Color("ff8a98"), 1.0 if set_card else 1.6)
	shake(0.12 if set_card else 0.25)
	if not set_card:
		await hologram(inst, to.origin)


func hologram(inst, at: Vector3, force_big := false) -> void:
	var big: bool = force_big or int(inst.data.get("level", 0)) >= 7
	var art := Cards.get_art(inst.id)
	var col: Color = _frame_color(inst)
	var spr := Sprite3D.new()
	spr.texture = art
	spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	spr.shaded = false
	var h := 3.3 if big else 2.2
	spr.pixel_size = h / maxf(1.0, art.get_height())
	spr.position = at + Vector3(0, h * 0.55, 0)
	spr.modulate = Color(1.1, 1.2, 1.3, 0.0)
	spr.scale = Vector3(0.15, 0.02, 0.15)
	add_child(spr)
	# A thin glowing frame behind the art reads as a "projected" monster.
	var glow := Sprite3D.new()
	glow.texture = art
	glow.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	glow.shaded = false
	glow.pixel_size = spr.pixel_size * 1.06
	glow.modulate = Color(col.r * 2.0, col.g * 2.0, col.b * 2.0, 0.0)
	glow.position = Vector3(0, 0, -0.02)
	spr.add_child(glow)
	var beam := _beam(at, big)
	if big:
		ace_summoned.emit(inst)
		_ring_fx(at + Vector3(0, 0.05, 0), col, 1.4, 0.0, 0.0)
		_ring_fx(at + Vector3(0, 0.05, 0), col, 2.2, 0.15, 0.0)
		_flash(at + Vector3(0, h * 0.5, 0), col)
		cam_shot(at + Vector3(at.x * -0.3, 0.9, 5.2), at + Vector3(0, h * 0.62, 0), 0.5)
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "scale", Vector3.ONE, Settings.t(0.45 if big else 0.35))
	tw.tween_property(spr, "modulate:a", 0.97, Settings.t(0.25))
	tw.tween_property(glow, "modulate:a", 0.35, Settings.t(0.4))
	await tw.finished
	if big:
		shake(0.45)
		Sfx.play("impact")
	# Idle: a gentle float while it is on screen.
	var float_tw := create_tween().set_loops(2).set_trans(Tween.TRANS_SINE)
	float_tw.tween_property(spr, "position:y", spr.position.y + 0.12, Settings.t(0.4))
	float_tw.tween_property(spr, "position:y", spr.position.y, Settings.t(0.4))
	await _wait(1.6 if big else 0.55)
	float_tw.kill()
	if big:
		cam_release(0.55)
	var tw2 := create_tween().set_parallel()
	tw2.tween_property(spr, "modulate:a", 0.0, Settings.t(0.35))
	tw2.tween_property(glow, "modulate:a", 0.0, Settings.t(0.25))
	tw2.tween_property(spr, "position:y", spr.position.y - h * 0.4, Settings.t(0.35))
	tw2.tween_property(spr, "scale", Vector3(0.6, 0.6, 0.6), Settings.t(0.35))
	tw2.tween_property(beam, "scale:x", 0.01, Settings.t(0.35))
	tw2.tween_property(beam, "scale:z", 0.01, Settings.t(0.35))
	await tw2.finished
	spr.queue_free()
	beam.queue_free()


func _frame_color(inst) -> Color:
	match inst.frame() if inst.has_method("frame") else "":
		"fusion":
			return Color("b06cff")
		"synchro":
			return Color("f2f2f2")
		"xyz":
			return Color("ffd23a")
		"effect":
			return Color("ff9a3c")
	return UITheme.ACCENT


func _beam(at: Vector3, big: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.85 if big else 0.55
	cyl.bottom_radius = 0.6 if big else 0.42
	cyl.height = 7.0
	cyl.cap_top = false
	cyl.cap_bottom = false
	mi.mesh = cyl
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(UITheme.ACCENT, 0.18)
	mi.material_override = m
	mi.position = at + Vector3(0, 3.5, 0)
	add_child(mi)
	return mi


func _burst(at: Vector3, color: Color, size: float) -> void:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.42
	t.outer_radius = 0.5
	t.rings = 48
	t.ring_segments = 6
	mi.mesh = t
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(color, 1.0)
	mi.material_override = m
	mi.position = at + Vector3(0, 0.05, 0)
	mi.scale = Vector3(0.4, 0.4, 0.4)
	add_child(mi)
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(mi, "scale", Vector3(size * 2.2, 1, size * 2.2), Settings.t(0.5))
	tw.tween_property(m, "albedo_color:a", 0.0, Settings.t(0.5))
	tw.chain().tween_callback(mi.queue_free)


const METHOD_COLORS := {
	"fusion": Color("b15cff"),
	"synchro": Color("6dff9a"),
	"xyz": Color("ffd23a"),
	"reborn": Color("ffe9a8"),
	"ritual": Color("5aa8ff"),
}


## A card leaves (hand or field) to become material. Flies to the summon point.
func anim_material(p: int, inst, from: String, center: Vector3) -> void:
	var c := card_for(inst)
	if from == "hand":
		if p == 0:
			c = _new_card(inst)
			c.transform = _near_camera_xform()
		else:
			c = _take_from_opp_hand(inst)
	if c == null:
		return
	c.set_pickable(false)
	c.set_glow(true, Color.WHITE)
	var to := Transform3D(Basis(Vector3.RIGHT, -0.4) * Basis(Vector3.UP, randf_range(-0.6, 0.6)), center + Vector3(randf_range(-0.9, 0.9), 1.6, randf_range(-0.3, 0.3)))
	await _move(c, to, 0.32, 0.4)


func special_center(p: int, zone: int) -> Vector3:
	return monster_zone_pos(p, zone)


## Pull the materials together, play the method's effect, then land the monster.
func anim_special(p: int, inst, zone: int, method: String, materials: Array) -> void:
	var col: Color = METHOD_COLORS.get(method, UITheme.ACCENT)
	if method == "reborn":
		remove_from_gy(inst)
	var at := monster_zone_pos(p, zone) + Vector3(0, 0.02, 0)
	var core := at + Vector3(0, 1.6, 0)
	var grand: bool = method in ["fusion", "synchro", "xyz", "ritual"]
	if grand:
		# The camera drops low and looks up at the summon while the field goes dark.
		var side := 1.0 if at.x <= 0.0 else -1.0
		cam_shot(at + Vector3(2.6 * side, 1.5, 4.6 if p == 0 else 5.4), core + Vector3(0, 0.5, 0), 0.5)
		_dim_field(1.9)
		_summon_scene(method, at, core, col, materials.size())
	# Materials spiral into the core and vanish
	var tw: Tween = create_tween().set_parallel() if materials.size() > 0 else null
	for m in materials:
		var mc := card_for(m)
		if mc == null:
			continue
		tw.tween_property(mc, "position", core, Settings.t(0.45)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_property(mc, "scale", Vector3(0.2, 0.2, 0.2), Settings.t(0.45))
		tw.tween_method(mc.set_alpha, 1.0, 0.0, Settings.t(0.45))
	match method:
		"synchro":
			for i in 3:
				_ring_fx(at + Vector3(0, 0.3 + i * 0.7, 0), col, 0.8, 0.12 * i, 1.0)
		"xyz":
			_vortex(core, col)
		"fusion":
			_swirl(core, col)
		_:
			_ring_fx(at + Vector3(0, 0.1, 0), col, 1.0, 0.0, 1.0)
	if tw:
		await tw.finished
	else:
		await _wait(0.45)
	if grand:
		await _wait(0.55)
	for m in materials:
		var mc := card_for(m)
		if mc:
			_cards.erase(m.uid)
			mc.queue_free()
		if method != "xyz":
			_add_to_gy(m)
	shake(0.6)
	_flash(core, col)
	var c := _new_card(inst)
	c.transform = Transform3D(table_basis(p, true, true), core)
	c.scale = Vector3(0.1, 0.1, 0.1)
	var grow := create_tween()
	grow.tween_property(c, "scale", Vector3.ONE, Settings.t(0.25)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await grow.finished
	await _move(c, Transform3D(table_basis(p, true, true), at), 0.25, 0.0)
	_burst(at, col, 2.2)
	if method == "xyz":
		set_overlays(inst)
	if grand:
		for i in 3:
			_burst(at, col.lightened(0.2 * i), 2.6 + i * 1.2)
		_sparks(at + Vector3(0, 0.4, 0), col.lightened(0.3), 70)
		shake(0.9)
	await hologram(inst, at, true)
	if grand:
		cam_release(0.6)


func set_overlays(inst) -> void:
	var c := card_for(inst)
	if c == null:
		return
	var lbl := c.get_node_or_null("Overlays") as Label3D
	if lbl == null:
		lbl = Label3D.new()
		lbl.name = "Overlays"
		lbl.font = UITheme.title_font()
		lbl.font_size = 56
		lbl.pixel_size = 0.004
		lbl.outline_size = 14
		lbl.modulate = Color("ffd23a")
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = true
		lbl.position = Vector3(0.3, 0.42, 0.25)
		c.add_child(lbl)
	lbl.text = "◆ %d" % inst.overlays.size()
	lbl.visible = inst.overlays.size() > 0


func _ring_fx(at: Vector3, color: Color, size: float, delay: float, rise: float) -> void:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.55
	t.outer_radius = 0.6
	t.rings = 48
	t.ring_segments = 6
	mi.mesh = t
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(color, 0.0)
	mi.material_override = m
	mi.position = at
	mi.scale = Vector3(size, 1, size)
	add_child(mi)
	var tw := create_tween()
	tw.tween_interval(Settings.t(delay))
	tw.tween_property(m, "albedo_color:a", 1.0, Settings.t(0.12))
	tw.parallel().tween_property(mi, "position:y", at.y + rise, Settings.t(0.6))
	tw.tween_property(m, "albedo_color:a", 0.0, Settings.t(0.35))
	tw.parallel().tween_property(mi, "scale", Vector3(size * 1.8, 1, size * 1.8), Settings.t(0.35))
	tw.tween_callback(mi.queue_free)


## The lights go down for a big summon and come back.
func _dim_field(dur: float) -> void:
	var veil := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(60, 60)
	veil.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0, 0, 0.03, 0.0)
	veil.material_override = m
	veil.rotation.x = -PI / 2.0
	veil.position = Vector3(0, 0.012, 0)
	add_child(veil)
	var tw := create_tween()
	tw.tween_property(m, "albedo_color:a", 0.62, Settings.t(0.3))
	tw.tween_interval(Settings.t(dur))
	tw.tween_property(m, "albedo_color:a", 0.0, Settings.t(0.5))
	tw.tween_callback(veil.queue_free)


## The set piece for each kind of Extra Deck or Ritual Summon.
func _summon_scene(method: String, at: Vector3, core: Vector3, col: Color, count: int) -> void:
	match method:
		"synchro":
			# Green rings stack up into a tunnel and a pillar of light runs through them.
			for i in maxi(3, count + 2):
				_ring_fx(at + Vector3(0, 0.2 + i * 0.55, 0), col, 1.0 - i * 0.05, 0.1 * i, 0.5)
			var beam := _beam(at, true)
			(beam.material_override as StandardMaterial3D).albedo_color = Color(col, 0.0)
			var tw := create_tween()
			tw.tween_interval(Settings.t(0.45))
			tw.tween_property(beam.material_override, "albedo_color:a", 0.5, Settings.t(0.15))
			tw.tween_property(beam.material_override, "albedo_color:a", 0.0, Settings.t(0.9))
			tw.tween_callback(beam.queue_free)
			_star_shower(core, Color.WHITE, 26)
		"xyz":
			# A galaxy opens on the floor and pulls everything in before it bursts.
			for i in 5:
				_spin_ring(at + Vector3(0, 0.05, 0), col.lerp(Color("b15cff"), i / 5.0), 2.2 - i * 0.36, 1.2 + i * 0.5)
			_vortex(core, Color("b15cff"))
			_star_shower(core + Vector3(0, 1.0, 0), col, 30)
		"fusion":
			# Two colors spiral into each other.
			_swirl(core, Color("ff8a3a"))
			_swirl(core + Vector3(0, 0.2, 0), Color("3aa0ff"))
			for i in 3:
				_spin_ring(core, col.lightened(i * 0.15), 1.6 - i * 0.4, 2.0 + i)
		"ritual":
			# A circle of blue flames around the altar, then the light comes down.
			for i in 8:
				var a := TAU * i / 8.0
				var fp := at + Vector3(cos(a) * 1.25, 0, sin(a) * 1.25)
				for k in 3:
					_ring_fx(fp + Vector3(0, 0.05, 0), col.lerp(Color.WHITE, k * 0.25), 0.16, 0.05 * i + 0.1 * k, 1.1)
			_spin_ring(at + Vector3(0, 0.05, 0), col, 1.9, 1.5)
			var b2 := _beam(at, true)
			(b2.material_override as StandardMaterial3D).albedo_color = Color(col, 0.0)
			var tw2 := create_tween()
			tw2.tween_interval(Settings.t(0.5))
			tw2.tween_property(b2.material_override, "albedo_color:a", 0.45, Settings.t(0.2))
			tw2.tween_property(b2.material_override, "albedo_color:a", 0.0, Settings.t(0.8))
			tw2.tween_callback(b2.queue_free)


## A flat ring that spins on the floor and shrinks away.
func _spin_ring(at: Vector3, color: Color, radius: float, turns: float) -> void:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = radius - 0.05
	t.outer_radius = radius
	t.rings = 40
	t.ring_segments = 5
	mi.mesh = t
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(color, 0.0)
	mi.material_override = m
	mi.position = at
	mi.scale = Vector3(1.0, 0.2, 0.55)
	add_child(mi)
	var tw := create_tween().set_parallel()
	tw.tween_property(m, "albedo_color:a", 0.95, Settings.t(0.2))
	tw.tween_property(mi, "rotation:y", TAU * turns, Settings.t(1.1))
	tw.chain().tween_property(mi, "scale", Vector3(0.02, 0.02, 0.02), Settings.t(0.25))
	tw.chain().tween_callback(mi.queue_free)


## Points of light that fall inward to a spot.
func _star_shower(to: Vector3, color: Color, amount: int) -> void:
	for i in amount:
		var s := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.035
		sm.height = 0.07
		sm.radial_segments = 6
		sm.rings = 3
		s.mesh = sm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = color
		s.material_override = m
		var ang := randf() * TAU
		s.position = to + Vector3(cos(ang) * randf_range(1.5, 3.2), randf_range(0.5, 3.0), sin(ang) * randf_range(1.5, 3.2))
		add_child(s)
		var tw := create_tween()
		tw.tween_interval(Settings.t(randf() * 0.4))
		tw.tween_property(s, "position", to, Settings.t(0.5)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(s.queue_free)


func _swirl(at: Vector3, color: Color) -> void:
	for i in 4:
		var mi := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = 0.7 + i * 0.12
		t.outer_radius = 0.74 + i * 0.12
		mi.mesh = t
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_color = Color(color.lerp(Color("ff8a3a"), i / 4.0), 0.9)
		mi.material_override = m
		mi.position = at
		mi.rotation = Vector3(randf() * PI, randf() * PI, 0)
		add_child(mi)
		var tw := create_tween().set_parallel()
		tw.tween_property(mi, "rotation", mi.rotation + Vector3(PI * 2.0, PI, 0), Settings.t(0.9))
		tw.tween_property(mi, "scale", Vector3(0.05, 0.05, 0.05), Settings.t(0.9)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(mi.queue_free)


func _vortex(at: Vector3, color: Color) -> void:
	var sphere := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.6
	sm.height = 1.2
	sphere.mesh = sm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.02, 0.0, 0.08, 0.85)
	sphere.material_override = m
	sphere.position = at
	sphere.scale = Vector3(0.1, 0.1, 0.1)
	add_child(sphere)
	var tw := create_tween()
	tw.tween_property(sphere, "scale", Vector3.ONE, Settings.t(0.3)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(Settings.t(0.35))
	tw.tween_property(sphere, "scale", Vector3(0.01, 0.01, 0.01), Settings.t(0.2))
	tw.tween_callback(sphere.queue_free)
	for i in 3:
		_ring_fx(at + Vector3(0, -0.2 + i * 0.2, 0), color, 1.1 - i * 0.2, i * 0.08, 0.0)


func _flash(at: Vector3, color: Color) -> void:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = 0.0
	l.omni_range = 8.0
	l.position = at
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "light_energy", 12.0, Settings.t(0.08))
	tw.tween_property(l, "light_energy", 0.0, Settings.t(0.6))
	tw.tween_callback(l.queue_free)


var _orbs: Array[MeshInstance3D] = []


## Tributes rise, glow gold, and turn into orbs of light that wait over the field
## until the new monster lands (see anim_summon).
func anim_tribute(inst) -> void:
	var c := card_for(inst)
	if c == null:
		return
	c.set_glow(true, UITheme.GOLD)
	var rise := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	rise.tween_property(c, "position:y", 0.9, Settings.t(0.3))
	rise.tween_method(c.flash, 0.0, 3.0, Settings.t(0.3))
	await rise.finished
	var orb := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.32
	orb.mesh = sm
	var om := StandardMaterial3D.new()
	om.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	om.albedo_color = Color("ffe28a")
	om.emission_enabled = true
	om.emission = UITheme.GOLD
	om.emission_energy_multiplier = 6.0
	orb.material_override = om
	orb.position = c.position
	add_child(orb)
	_orbs.append(orb)
	var fade := create_tween().set_parallel()
	fade.tween_method(c.set_alpha, 1.0, 0.0, Settings.t(0.2))
	fade.tween_property(c, "scale", Vector3(0.3, 0.3, 0.3), Settings.t(0.2))
	var gather := Vector3(0, 1.8, 1.0) + Vector3((_orbs.size() - 1.5) * 0.5, 0, 0)
	fade.tween_property(orb, "position", gather, Settings.t(0.35)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await fade.finished
	_cards.erase(inst.uid)
	c.queue_free()
	_add_to_gy(inst)


func _consume_orbs(at: Vector3) -> void:
	if _orbs.is_empty():
		return
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	for orb in _orbs:
		tw.tween_property(orb, "position", at + Vector3(0, 0.3, 0), Settings.t(0.3))
		tw.tween_property(orb, "scale", Vector3(0.4, 0.4, 0.4), Settings.t(0.3))
	await tw.finished
	for orb in _orbs:
		orb.queue_free()
	_orbs.clear()
	_flash(at + Vector3(0, 0.5, 0), UITheme.GOLD)
	_ring_fx(at + Vector3(0, 0.1, 0), UITheme.GOLD, 1.0, 0.0, 1.2)


## Battle Phase: the field tints and the camera leans in.


func set_battle_mode(on: bool) -> void:
	_battle_mode = on
	var tw := create_tween()
	tw.tween_property(camera, "fov", 40.0 if on else 44.0, Settings.t(0.5)).set_trans(Tween.TRANS_CUBIC)


func anim_flip(p: int, inst, zone: int) -> void:
	var c := card_for(inst)
	if c == null:
		return
	var to := Transform3D(table_basis(p, true, inst.attack_pos), monster_zone_pos(p, zone) + Vector3(0, 0.02, 0))
	await _move(c, to, 0.4, 0.7)
	_burst(to.origin, UITheme.ACCENT, 1.1)


func anim_position(p: int, inst, zone: int) -> void:
	var c := card_for(inst)
	if c == null:
		return
	var to := Transform3D(table_basis(p, inst.face_up, inst.attack_pos), monster_zone_pos(p, zone) + Vector3(0, 0.02, 0))
	await _move(c, to, 0.3, 0.25)


func anim_activate(p: int, inst, zone := 2) -> void:
	var c: Card3D
	if p == 0:
		c = _new_card(inst)
		c.transform = _near_camera_xform()
	else:
		c = _take_from_opp_hand(inst)
	c.set_pickable(true)
	var to := Transform3D(table_basis(p, true, true), st_pos(p, zone if zone >= 0 else 2) + Vector3(0, 0.02, 0))
	await _move(c, Transform3D(to.basis, to.origin + Vector3(0, 0.8, 0)), 0.35, 0.3)
	c.set_glow(true, UITheme.ACCENT)
	var tw := create_tween()
	tw.tween_method(c.flash, 2.5, 0.0, Settings.t(0.5))
	_burst(to.origin + Vector3(0, 0.8, 0), Color("2de2a0"), 1.4)
	await _move(c, to, 0.15, 0.0)
	await _wait(0.35)
	c.set_glow(false)


func anim_spell_done(inst) -> void:
	var c := card_for(inst)
	if c == null:
		_add_to_gy(inst)
		return
	var tw := create_tween()
	tw.tween_method(c.set_alpha, 1.0, 0.0, Settings.t(0.25))
	await tw.finished
	_cards.erase(inst.uid)
	c.queue_free()
	_add_to_gy(inst)


func anim_set_st(p: int, inst, zone: int) -> void:
	var c: Card3D
	if p == 0:
		c = _new_card(inst)
		c.transform = _near_camera_xform()
	else:
		c = _take_from_opp_hand(inst)
	c.set_pickable(true)
	var to := Transform3D(table_basis(p, false, true), spell_zone_pos(p, zone) + Vector3(0, 0.02, 0))
	await _move(c, to, 0.32, 0.4)
	_burst(to.origin, Color("b98cff"), 0.8)


## A set trap flips up with a flash.
func anim_trap(p: int, inst, zone: int) -> void:
	var c := card_for(inst)
	if c == null:
		return
	# The card lifts and shows its face to you, whoever flipped it.
	var up := Transform3D(Basis(Vector3.RIGHT, -0.6 if p == 0 else -0.25), st_pos(p, zone) + Vector3(0, 1.2 if p == 0 else 1.5, 0.3))
	c.set_glow(true, Color("ff4dd2"))
	await _move(c, up, 0.3, 0.2)
	_flash(up.origin, Color("ff4dd2"))
	_burst(up.origin, Color("ff4dd2"), 1.6)
	shake(0.3)
	var tw := create_tween()
	tw.tween_method(c.flash, 3.0, 0.2, Settings.t(0.5))
	await _wait(0.55)


## A Continuous / Field / Equip card stays: it settles face-up in its zone with a soft glow.
func anim_settle(p: int, inst, zone: int) -> void:
	var c := card_for(inst)
	if c == null:
		return
	var to := Transform3D(table_basis(p, true, true), st_pos(p, zone) + Vector3(0, 0.02, 0))
	await _move(c, to, 0.28, 0.2)
	c.set_glow(true, Color("3ddc97") if zone >= 5 else Color("7fd8ff"))
	_burst(to.origin, Color("3ddc97") if zone >= 5 else Color("7fd8ff"), 0.9)
	if inst.equipped_to != null and card_for(inst.equipped_to) != null:
		_link_beam(to.origin + Vector3(0, 0.1, 0), card_for(inst.equipped_to).position + Vector3(0, 0.15, 0), Color("7fd8ff"))
		pulse(inst.equipped_to, Color("7fd8ff"))


## A card that re-Sets itself (Scrap-Iron Scarecrow).
func anim_reset(p: int, inst, zone: int) -> void:
	var c := card_for(inst)
	if c == null:
		return
	c.set_glow(false)
	await _move(c, Transform3D(table_basis(p, false, true), st_pos(p, zone) + Vector3(0, 0.02, 0)), 0.3, 0.3)


## A monster changes sides.
func anim_control(p: int, inst, zone: int) -> void:
	var c := card_for(inst)
	if c == null:
		return
	c.set_glow(true, Color("ff8ad8"))
	_flash(c.position + Vector3(0, 0.3, 0), Color("ff8ad8"))
	await _move(c, Transform3D(table_basis(p, inst.face_up, inst.attack_pos), monster_zone_pos(p, zone) + Vector3(0, 0.02, 0)), 0.5, 1.1)
	_burst(c.position, Color("ff8ad8"), 1.2)
	c.set_glow(false)


## A card on the field goes back to the hand (or Extra Deck).
func anim_bounce(inst) -> void:
	var c := card_for(inst)
	if c == null:
		return
	c.set_glow(true, Color("9fd0ff"))
	var tw := create_tween().set_parallel()
	tw.tween_property(c, "position:y", c.position.y + 1.3, Settings.t(0.28)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_method(c.set_alpha, 1.0, 0.0, Settings.t(0.28))
	await tw.finished
	_cards.erase(inst.uid)
	c.queue_free()


## A quick line of light between two points (equip links).
func _link_beam(a: Vector3, b: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.035, 0.035, a.distance_to(b))
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 4.0
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	add_child(mi)
	mi.position = (a + b) / 2.0
	if a.distance_to(b) > 0.01:
		mi.look_at(b)
	var tw := create_tween()
	tw.tween_property(m, "albedo_color:a", 0.0, Settings.t(0.6))
	tw.tween_callback(mi.queue_free)


## A card shown from the hand (Kuriboh) then sent to the GY.
func anim_hand_effect(p: int, inst) -> void:
	var c: Card3D
	if p == 0:
		c = _new_card(inst)
		c.transform = _near_camera_xform()
	else:
		c = _take_from_opp_hand(inst)
	var show_at := Transform3D(Basis(Vector3.RIGHT, -0.7), Vector3(0, 2.2, 1.6 if p == 0 else -0.6))
	await _move(c, show_at, 0.3, 0.2)
	c.set_glow(true, UITheme.GOLD)
	_flash(show_at.origin, UITheme.GOLD)
	await _wait(0.5)
	await anim_spell_done(inst)


func anim_add_to_opp_hand(inst) -> void:
	var c := _new_card(inst)
	c.set_pickable(false)
	c.transform = Transform3D(table_basis(1, false, true), deck_pos(1) + Vector3(0, 0.3, 0))
	_opp_hand.append(c)
	_layout_opp_hand()
	await _wait(0.25)


func pulse(inst, color: Color) -> void:
	var c := card_for(inst)
	if c == null:
		return
	c.set_glow(true, color)
	var tw := create_tween()
	tw.tween_method(c.flash, 2.5, 0.0, Settings.t(0.5))
	tw.tween_callback(func(): if is_instance_valid(c): c.set_glow(false))


## A monster's effect goes off: it lifts off the table, a ring bursts out from under it and
## light pours up through the card.
func effect_burst(inst, color: Color) -> void:
	var c := card_for(inst)
	if c == null:
		return
	c.set_glow(true, color)
	var at := c.global_position
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.42
	tm.outer_radius = 0.5
	tm.rings = 40
	ring.mesh = tm
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	rm.albedo_color = Color(color, 0.95)
	ring.material_override = rm
	ring.scale = Vector3(0.6, 0.12, 0.6)
	ring.position = Vector3(at.x, 0.05, at.z)
	add_child(ring)
	var beam := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 0.42
	cm.height = 2.6
	cm.cap_top = false
	cm.cap_bottom = false
	beam.mesh = cm
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	bm.albedo_color = Color(color, 0.32)
	beam.material_override = bm
	beam.position = Vector3(at.x, 1.3, at.z)
	beam.scale = Vector3(1, 0.05, 1)
	add_child(beam)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 0.0
	light.omni_range = 4.5
	light.position = Vector3(at.x, 0.8, at.z)
	add_child(light)
	var d := Settings.t(1.0)
	var tw := create_tween().set_parallel()
	tw.tween_property(ring, "scale", Vector3(3.4, 0.12, 3.4), 0.6 * d).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(rm, "albedo_color:a", 0.0, 0.6 * d)
	tw.tween_property(beam, "scale", Vector3(1, 1, 1), 0.18 * d).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(bm, "albedo_color:a", 0.0, 0.45 * d).set_delay(0.25 * d)
	tw.tween_property(light, "light_energy", 5.0, 0.1 * d)
	tw.tween_property(light, "light_energy", 0.0, 0.5 * d).set_delay(0.12 * d)
	tw.tween_method(c.flash, 3.0, 0.0, 0.7 * d)
	var home := c.position
	tw.tween_property(c, "position:y", home.y + 0.32, 0.14 * d).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "position:y", home.y, 0.3 * d).set_delay(0.4 * d).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_callback(func():
		ring.queue_free()
		beam.queue_free()
		light.queue_free()
		if is_instance_valid(c):
			c.set_glow(false))


## Declaring an attack: the attacker rises and leans toward its target.
func anim_declare(p: int, inst, target) -> void:
	var c := card_for(inst)
	if c == null:
		return
	c.set_glow(true, UITheme.DANGER)
	var home := c.transform
	c.set_meta("home", home)
	var goal := _attack_goal(p, target)
	var lift := Transform3D(home.basis, home.origin + Vector3(0, 0.7, 0) + (goal - home.origin) * 0.08)
	await _move(c, lift, 0.22, 0.0)


func anim_battle(p: int, inst, target) -> void:
	var c := card_for(inst)
	if c == null:
		return
	var home: Transform3D = c.get_meta("home", c.transform)
	var goal := _attack_goal(p, target)
	_battle_shot(p, home.origin, goal)
	await _wait(0.3)
	var hit := Transform3D(home.basis, home.origin.lerp(goal, 0.82) + Vector3(0, 0.25, 0))
	await _move(c, hit, 0.16, 0.15)
	StrikeFx.play(self, inst, home.origin, goal)
	_attr_hit(inst, home.origin, goal + Vector3(0, 0.15, 0))
	var th := holo_for(target)
	if th:
		th.hit()
	await hit_stop(0.1 if target != null else 0.14)
	await _wait(0.25)
	await _move(c, home, 0.32, 0.3)
	cam_release(0.45)
	c.set_glow(false)


## Freeze the whole table for a blink when a hit lands. Skipped when the duel is being
## fast-forwarded, so tests and the Very fast setting keep their pace.
func hit_stop(sec: float) -> void:
	if Engine.time_scale > 1.01 or Settings.anim_speed > 2.0:
		return
	Engine.time_scale = 0.06
	await get_tree().create_timer(sec, true, false, true).timeout
	Engine.time_scale = 1.0


func anim_attack_stopped(inst) -> void:
	var c := card_for(inst)
	if c == null:
		return
	var home: Transform3D = c.get_meta("home", c.transform)
	await _move(c, home, 0.3, 0.1)
	c.set_glow(false)


## Low camera for attacks: behind your attacker, or facing the incoming one.
func _battle_shot(p: int, from: Vector3, goal: Vector3) -> void:
	if p == 0:
		cam_shot(from + Vector3(from.x * 0.15, 2.3, 4.2), goal.lerp(from, 0.25) + Vector3(0, 0.4, 0), 0.35)
	else:
		var mid := from.lerp(goal, 0.5)
		cam_shot(Vector3(mid.x * 0.5 + 1.5, 2.6, goal.z + 5.0), mid + Vector3(0, 0.6, 0), 0.35)


const ATTR_COLORS := {"FIRE": Color("ff5a2a"), "WATER": Color("3aa0ff"), "WIND": Color("6dff9a"), "EARTH": Color("d99a4a"),
	"LIGHT": Color("fff2a8"), "DARK": Color("b15cff"), "DIVINE": Color("ffd23a")}


## An attack lands the way its monster's Attribute would: fire erupts, water splashes out in
## rings, wind spins, earth cracks and shakes, light comes down as a beam, dark opens a rift.
func _attr_hit(inst, from: Vector3, at: Vector3) -> void:
	var attr := str(inst.data.get("attribute", "")) if inst != null else ""
	var col: Color = ATTR_COLORS.get(attr, Color("ff8a5c"))
	_link_beam(from + Vector3(0, 0.5, 0), at + Vector3(0, 0.2, 0), col)
	_impact(at, col)
	match attr:
		"FIRE":
			for i in 3:
				_ring_fx(at + Vector3(0, 0.1, 0), col.lerp(Color("ffd23a"), i / 3.0), 0.5 + i * 0.25, i * 0.06, 1.6)
			_sparks(at, Color("ffd23a"), 50)
			Sfx.play("effect", -6.0, 0.7)
		"WATER":
			for i in 4:
				_burst(at + Vector3(0, 0.02 * i, 0), col.lightened(i * 0.12), 1.2 + i * 0.7)
			_ring_fx(at, Color("c8f0ff"), 0.6, 0.1, 0.9)
			Sfx.play("whoosh", -5.0, 0.8)
		"WIND":
			_swirl(at + Vector3(0, 0.6, 0), col)
			_ring_fx(at, col, 0.9, 0.0, 1.4)
			_ring_fx(at, col.lightened(0.3), 0.6, 0.12, 1.8)
			Sfx.play("whoosh", -3.0, 1.4)
		"EARTH":
			shake(0.9)
			_shatter(at, col)
			_burst(at, col.darkened(0.2), 2.4)
			Sfx.play("impact", -5.0, 0.6)
		"LIGHT":
			var beam := _beam(at, true)
			(beam.material_override as StandardMaterial3D).albedo_color = Color(col, 0.45)
			var tw := create_tween()
			tw.tween_property(beam.material_override, "albedo_color:a", 0.0, Settings.t(0.55))
			tw.tween_callback(beam.queue_free)
			_flash(at + Vector3(0, 1.2, 0), col)
			Sfx.play("sparkle", -4.0)
		"DARK":
			_vortex(at + Vector3(0, 0.6, 0), col)
			_rift(at)
			Sfx.play("banish", -8.0, 0.8)
		"DIVINE":
			var b2 := _beam(at, true)
			(b2.material_override as StandardMaterial3D).albedo_color = Color(col, 0.55)
			var tw2 := create_tween()
			tw2.tween_property(b2.material_override, "albedo_color:a", 0.0, Settings.t(0.8))
			tw2.tween_callback(b2.queue_free)
			for i in 3:
				_burst(at, col, 1.5 + i)
			shake(1.0)
			Sfx.play("gong", -6.0)


## Hit: a flash, a ring, sparks flying out and a hard shake.
func _impact(at: Vector3, color: Color) -> void:
	_burst(at, color, 1.5)
	_flash(at + Vector3(0, 0.6, 0), color)
	_sparks(at, color, 40)
	shake(0.55)
	Sfx.play("impact", -4.0)


func _sparks(at: Vector3, color: Color, amount: int) -> void:
	var ps := GPUParticles3D.new()
	ps.one_shot = true
	ps.explosiveness = 0.95
	ps.amount = amount
	ps.lifetime = 0.9
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 80.0
	pm.initial_velocity_min = 3.0
	pm.initial_velocity_max = 7.0
	pm.gravity = Vector3(0, -9.0, 0)
	pm.damping_min = 1.0
	pm.damping_max = 2.0
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(color, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	ps.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.05, 0.05)
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.vertex_color_use_as_albedo = true
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	qm.albedo_color = Color(color.r * 2.0, color.g * 2.0, color.b * 2.0)
	q.material = qm
	ps.draw_pass_1 = q
	ps.position = at
	add_child(ps)
	ps.emitting = true
	get_tree().create_timer(1.5).timeout.connect(ps.queue_free)


## The card bursts into glowing shards that tumble away.
func _shatter(at: Vector3, color: Color) -> void:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color.lightened(0.3)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 2.5
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	create_tween().tween_property(m, "albedo_color:a", 0.0, Settings.t(0.6)).set_delay(Settings.t(0.3))
	for i in 18:
		var shard := MeshInstance3D.new()
		var pr := PrismMesh.new()
		pr.size = Vector3(_rng.randf_range(0.12, 0.3), _rng.randf_range(0.15, 0.35), 0.01)
		shard.mesh = pr
		shard.material_override = m
		shard.position = at + Vector3(_rng.randf_range(-0.4, 0.4), 0.3, _rng.randf_range(-0.5, 0.5))
		shard.rotation = Vector3(_rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU)
		add_child(shard)
		var vel := Vector3(_rng.randf_range(-2.5, 2.5), _rng.randf_range(2.0, 4.5), _rng.randf_range(-2.0, 2.0))
		var spin := Vector3(_rng.randf_range(-8, 8), _rng.randf_range(-8, 8), _rng.randf_range(-8, 8))
		var start := shard.position
		var start_rot := shard.rotation
		var dur := Settings.t(0.9)
		var tw := create_tween().set_parallel()
		tw.tween_method(func(t: float):
			shard.position = start + vel * t + Vector3(0, -6.0, 0) * t * t * 0.5
			shard.rotation = start_rot + spin * t, 0.0, dur, dur)
		tw.chain().tween_callback(shard.queue_free)
	_sparks(at + Vector3(0, 0.3, 0), color, 30)


func _attack_goal(p: int, target) -> Vector3:
	if target != null and card_for(target) != null:
		return card_for(target).position
	return Vector3(0, 0.6, -3.4) if p == 0 else Vector3(0, 0.6, 3.6)


func anim_attack(p: int, inst, target) -> void:
	var c := card_for(inst)
	if c == null:
		return
	var home := c.transform
	var goal: Vector3
	if target != null and card_for(target) != null:
		goal = card_for(target).position
	else:
		goal = Vector3(0, 0.6, -3.4) if p == 0 else Vector3(0, 0.6, 3.6)
	var lift := Transform3D(home.basis, home.origin + Vector3(0, 0.7, 0) + (goal - home.origin) * -0.08)
	_battle_shot(p, home.origin, goal)
	await _move(c, lift, 0.3, 0.0)
	var hit := Transform3D(home.basis, home.origin.lerp(goal, 0.82) + Vector3(0, 0.25, 0))
	await _move(c, hit, 0.16, 0.15)
	StrikeFx.play(self, inst, home.origin, goal)
	_attr_hit(inst, home.origin, goal + Vector3(0, 0.15, 0))
	var th := holo_for(target)
	if th:
		th.hit()
	await hit_stop(0.1 if target != null else 0.14)
	await _wait(0.25)
	await _move(c, home, 0.32, 0.3)
	cam_release(0.45)


func remove_from_banished(inst) -> void:
	for pile in _ban_cards:
		for gc in pile:
			if gc.inst == inst:
				pile.erase(gc)
				gc.queue_free()
				return


func _add_to_banished(inst) -> void:
	var p: int = inst.owner
	var c := Card3D.new()
	c.setup(inst.id)
	c.inst = inst
	c.set_pickable(true)
	c.clicked.connect(func(_c): pile_clicked.emit(int(inst.owner)))
	c.hovered.connect(func(card, inside): card_hovered.emit(card, inside))
	add_child(c)
	var pile: Array = _ban_cards[p]
	var y := 0.02 + pile.size() * 0.015
	c.transform = Transform3D(table_basis(p, true, true) * Basis(Vector3.BACK, _rng.randf_range(-0.14, 0.14)), banish_pos(p) + Vector3(0, y, 0))
	c.set_glow(true, BANISH_COLOR)
	pile.append(c)
	if pile.size() > 3:
		var old: Card3D = pile.pop_front()
		old.queue_free()
		for k in pile.size():
			(pile[k] as Card3D).position.y = 0.02 + k * 0.015
	var bl: Label3D = _ban_labels[p]
	if bl and bl.modulate.a < 0.5:
		create_tween().tween_property(bl, "modulate:a", 0.9, Settings.t(0.4))


## A card is removed from play: it lifts, twists into a violet rift and lands on the banished pile.
func anim_banish(inst, from: String, side: int) -> void:
	var c := card_for(inst)
	if from == "gy":
		remove_from_gy(inst)
	elif from == "hand" and side == 1:
		c = _take_from_opp_hand(inst)
	var at: Vector3 = c.position if c else gy_pos(inst.owner) + Vector3(0, 0.1, 0)
	if c:
		c.set_glow(true, BANISH_COLOR)
		var tw := create_tween().set_parallel()
		tw.tween_property(c, "position:y", at.y + 0.7, Settings.t(0.22)).set_trans(Tween.TRANS_SINE)
		tw.tween_method(c.flash, 0.0, 2.2, Settings.t(0.22))
		await tw.finished
		var tw2 := create_tween().set_parallel()
		tw2.tween_property(c, "scale", Vector3(0.02, 1.25, 1.0), Settings.t(0.2)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw2.tween_property(c, "rotation:y", c.rotation.y + PI, Settings.t(0.2))
		tw2.tween_method(c.set_alpha, 1.0, 0.0, Settings.t(0.2))
		await tw2.finished
		_cards.erase(inst.uid)
		c.queue_free()
	_rift(at + Vector3(0, 0.5, 0))
	_impact(banish_pos(inst.owner) + Vector3(0, 0.1, 0), BANISH_COLOR)
	_add_to_banished(inst)
	await _wait(0.18)


## A thin violet tear in the air where a card left the duel.
func _rift(at: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 1.5)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.9, 0.75, 1.0)
	m.emission_enabled = true
	m.emission = BANISH_COLOR
	m.emission_energy_multiplier = 6.0
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.position = at
	mi.scale = Vector3(0.2, 0.1, 1)
	add_child(mi)
	var tw := create_tween()
	tw.tween_property(mi, "scale", Vector3(1.6, 1.0, 1), Settings.t(0.1))
	tw.tween_property(mi, "scale", Vector3(0.05, 1.3, 1), Settings.t(0.28))
	tw.parallel().tween_property(m, "albedo_color:a", 0.0, Settings.t(0.28))
	tw.tween_callback(mi.queue_free)


func remove_from_gy(inst) -> void:
	for pile in _gy_cards:
		for gc in pile:
			if gc.inst == inst:
				pile.erase(gc)
				gc.queue_free()
				return


func anim_destroy(inst, overlays: Array = []) -> void:
	var c := card_for(inst)
	if c == null:
		return
	for o in overlays:
		_add_to_gy(o)
	c.set_glow(true, UITheme.DANGER)
	var tw := create_tween()
	tw.tween_method(c.flash, 0.0, 3.0, Settings.t(0.12))
	await tw.finished
	_shatter(c.position, _frame_color(inst))
	var tw2 := create_tween().set_parallel()
	tw2.tween_property(c, "position:y", 0.5, Settings.t(0.2))
	tw2.tween_property(c, "scale", Vector3(1.15, 1.15, 1.15), Settings.t(0.2))
	tw2.tween_method(c.set_alpha, 1.0, 0.0, Settings.t(0.2))
	await tw2.finished
	_cards.erase(inst.uid)
	c.queue_free()
	_add_to_gy(inst)


func anim_discard(p: int, inst) -> void:
	if p == 1:
		var c := _take_from_opp_hand(inst)
		_cards.erase(inst.uid)
		c.queue_free()
	_add_to_gy(inst)
	await _wait(0.2)


func _add_to_gy(inst) -> void:
	if state_ref and state_ref.players[inst.owner].banished.has(inst):
		_add_to_banished(inst)   # "banish instead" effects
		return
	var p: int = inst.owner
	var c := Card3D.new()
	c.setup(inst.id)
	c.inst = inst
	c.set_pickable(true)
	c.hovered.connect(func(card, inside): card_hovered.emit(card, inside))
	# Tap a Graveyard to look through it (yours or theirs).
	c.clicked.connect(func(_c): pile_clicked.emit(p))
	add_child(c)
	var pile: Array = _gy_cards[p]
	var y := 0.02 + pile.size() * 0.015
	var jitter := _rng.randf_range(-0.06, 0.06)
	c.transform = Transform3D(table_basis(p, true, true) * Basis(Vector3.BACK, jitter), gy_pos(p) + Vector3(0, y, 0))
	pile.append(c)
	if pile.size() > 3:
		var old: Card3D = pile.pop_front()
		old.queue_free()
		for k in pile.size():
			var gc: Card3D = pile[k]
			gc.position.y = 0.02 + k * 0.015


# ------------------------------------------------------------------ stats & aiming

## Master Duel style ATK / DEF readout under every monster on the field.
func refresh_stats(state: DuelState) -> void:
	var seen := {}
	for p in 2:
		for m in state.players[p].monsters():
			var c := card_for(m)
			if c == null:
				continue
			seen[m.uid] = true
			var pair: Array = _stats.get(m.uid, [])
			if pair.is_empty():
				pair = [_stat_label(), _stat_label(), _stat_label(), _star_badge(m)]
				pair[2].text = "/"
				pair[2].modulate = Color(1, 1, 1, 0.4)
				_stats[m.uid] = pair
			var hidden: bool = not m.face_up and p == 1
			var base: Vector3 = monster_zone_pos(p, state.players[p].field.find(m))
			var off := Vector3(0, 0.08, 0.6)
			pair[0].position = base + off + Vector3(-0.27, 0, 0)
			pair[1].position = base + off + Vector3(0.27, 0, 0)
			pair[2].position = base + off
			# The Level or Rank star sits on the card's corner nearest you.
			pair[3].position = base + Vector3(-0.4 if m.attack_pos else -0.5, 0.1, 0.36 if m.attack_pos else 0.24)
			var shown_atk := state.atk_of(m, false)
			pair[0].text = "?" if hidden else str(shown_atk)
			if not hidden and shown_atk != m.atk():
				pair[0].modulate = Color("ffd23a") if shown_atk > m.atk() else Color("ff7a7a")
			pair[1].text = "?" if hidden else str(state.def_of(m))
			var active := Color("ffffff")
			var dim := Color(0.75, 0.82, 0.95, 0.55)
			pair[0].modulate = (active if m.attack_pos else dim) if not hidden else dim
			if not hidden and shown_atk != m.atk() and m.attack_pos:
				pair[0].modulate = Color("ffd23a") if shown_atk > m.atk() else Color("ff8a8a")
			pair[1].modulate = (Color("7fd8ff") if not m.attack_pos else dim) if not hidden else dim
			pair[0].font_size = 72 if m.attack_pos else 54
			pair[1].font_size = 72 if not m.attack_pos else 54
			for l in pair:
				l.visible = true
			pair[3].visible = not hidden
	for uid in _stats.keys():
		if not seen.has(uid):
			for l in _stats[uid]:
				l.queue_free()
			_stats.erase(uid)


func hide_stats_for(inst) -> void:
	if _stats.has(inst.uid):
		for l in _stats[inst.uid]:
			l.visible = false


static var _star_tex: Array = [null, null]


## A star with the Level in it (gold star), or the Rank (black star, gold number) for Xyz.
func _star_badge(m) -> Sprite3D:
	var xyz: bool = str(m.data.get("frame", "")) == "xyz"
	var k := 1 if xyz else 0
	if _star_tex[k] == null:
		var n := 96
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		var outer := Comic.star(Vector2(n, n) / 2.0, n * 0.49, 0.52)
		var inner := Comic.star(Vector2(n, n) / 2.0, n * 0.39, 0.52)
		var fill := Color("23263a") if xyz else Color("ffd23a")
		var rim := Color("ffd23a") if xyz else Color("0a1236")
		for y in n:
			for x in n:
				var pt := Vector2(x + 0.5, y + 0.5)
				if Geometry2D.is_point_in_polygon(pt, inner):
					img.set_pixel(x, y, fill.lightened(0.25 * (1.0 - float(y) / n)) if not xyz else fill)
				elif Geometry2D.is_point_in_polygon(pt, outer):
					img.set_pixel(x, y, rim)
		_star_tex[k] = ImageTexture.create_from_image(img)
	var sp := Sprite3D.new()
	sp.texture = _star_tex[k]
	sp.pixel_size = 0.0042
	sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sp.no_depth_test = true
	sp.render_priority = 2
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	add_child(sp)
	var l := Label3D.new()
	l.text = str(int(m.data.get("level", 0)))
	l.font = UITheme.title_font()
	l.font_size = 56
	l.pixel_size = 0.0035
	l.modulate = Color("ffd23a") if xyz else Color("0a1236")
	l.outline_size = 0 if not xyz else 6
	l.outline_modulate = Color(0, 0, 0, 0.9)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 3
	l.position = Vector3(0, 0.0, 0.012)
	sp.add_child(l)
	return sp


func _stat_label() -> Label3D:
	var l := Label3D.new()
	l.font = UITheme.title_font()
	l.font_size = 64
	l.pixel_size = 0.0035
	l.outline_size = 16
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 2
	add_child(l)
	return l


func screen_pos(inst) -> Vector2:
	var c := card_for(inst)
	if c == null:
		return get_viewport().get_visible_rect().size / 2.0
	return camera.unproject_position(c.global_position)


# ------------------------------------------------------------------ dropping a card from the hand

var _drop_bands: Array = []      # [front row, back row]: {node, mat, label, on}


## Where on the table a point of the screen lands.
func table_point(screen: Vector2) -> Vector3:
	var o := camera.project_ray_origin(screen)
	var d := camera.project_ray_normal(screen)
	if absf(d.y) < 0.001:
		return Vector3(0, -100, 0)
	return o + d * ((0.02 - o.y) / d.y)


## 0 = your half of the field, 1 = theirs, -1 = off the table.
func side_at(screen: Vector2) -> int:
	var w := table_point(screen)
	if absf(w.x) > 5.6 or absf(w.z) > 3.5:
		return -1
	return 0 if w.z > 0.0 else 1


## Which of your two rows a dropped card lands in: 0 = monster row, 1 = back row, -1 = neither.
func drop_row(screen: Vector2) -> int:
	var w := table_point(screen)
	if absf(w.x) > 5.4 or w.z < 0.3 or w.z > 3.4:
		return -1
	return 0 if w.z < (MONSTER_ROW + SPELL_ROW) / 2.0 else 1


## The opponent's monster nearest to a point of the screen, if one is close enough.
func enemy_card_at(screen: Vector2, monsters: Array) -> Card3D:
	var best: Card3D = null
	var best_d := 95.0 * get_viewport().get_visible_rect().size.y / 1080.0
	for inst in monsters:
		var c := card_for(inst)
		if c == null:
			continue
		var d := camera.unproject_position(c.global_position).distance_to(screen)
		if d < best_d:
			best_d = d
			best = c
	return best


## Light up your rows while a card is being dragged. labels = [front row text, back row text];
## an empty text leaves that row dark.
func show_drop(labels: Array, on: bool) -> void:
	if _drop_bands.is_empty():
		if not on:
			return
		for r in 2:
			var z := MONSTER_ROW if r == 0 else SPELL_ROW
			var mi := MeshInstance3D.new()
			var pm := PlaneMesh.new()
			pm.size = Vector2(ZONE_SPACING * 5.0 + 0.3, 1.2)
			mi.mesh = pm
			var m := StandardMaterial3D.new()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			m.albedo_color = Color(theme["accent"], 0.12)
			mi.material_override = m
			mi.position = Vector3(0, 0.03, z)
			add_child(mi)
			var l := Label3D.new()
			l.font = UITheme.title_font()
			l.font_size = 110
			l.pixel_size = 0.0042
			l.outline_size = 20
			l.outline_modulate = Color(0, 0, 0, 0.75)
			l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			l.no_depth_test = true
			l.position = Vector3(0, 0.5, z)
			add_child(l)
			_drop_bands.append({"node": mi, "mat": m, "label": l, "on": false})
	for r in 2:
		var b: Dictionary = _drop_bands[r]
		var text := str(labels[r]) if on and r < labels.size() else ""
		b["on"] = text != ""
		(b["node"] as Node3D).visible = text != ""
		(b["label"] as Label3D).visible = text != ""
		(b["label"] as Label3D).text = text


func _update_drop() -> void:
	if _drop_bands.is_empty():
		return
	var row := drop_row(get_viewport().get_mouse_position())
	for r in 2:
		var b: Dictionary = _drop_bands[r]
		if not b["on"]:
			continue
		var hot := r == row
		var pulse := 0.5 + 0.5 * sin(_time * 6.0)
		(b["mat"] as StandardMaterial3D).albedo_color = Color(Color("ffd98a") if hot else Color(theme["accent"]), (0.3 + 0.12 * pulse) if hot else (0.08 + 0.05 * pulse))
		(b["label"] as Label3D).modulate = Color("fff2c8") if hot else Color(Color(theme["accent"]).lightened(0.5), 0.75)
		(b["label"] as Label3D).position.y = 0.5 + (0.12 if hot else 0.0)


# ------------------------------------------------------------------ direct attack target

var _direct: Node3D
var _direct_hover := false
var _direct_ring: MeshInstance3D
var _direct_label: Label3D


## A big target over the opponent's side of the field: click it (or anywhere on their monster
## row) to attack directly. The aiming arrow snaps to it.
func show_direct_target(on: bool) -> void:
	if _direct == null:
		if not on:
			return
		_direct = Node3D.new()
		_direct.position = monster_zone_pos(1, 2) + Vector3(0, 0.06, 0)
		add_child(_direct)
		_direct_ring = MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.92
		tm.outer_radius = 1.05
		_direct_ring.mesh = tm
		var rm := StandardMaterial3D.new()
		rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rm.albedo_color = Color("ff5a5a")
		rm.emission_enabled = true
		rm.emission = Color("ff3b3b")
		rm.emission_energy_multiplier = 3.0
		_direct_ring.material_override = rm
		_direct_ring.scale = Vector3(1, 0.2, 1)
		_direct.add_child(_direct_ring)
		for i in 2:
			var bar := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(2.5, 0.02, 0.07)
			bar.mesh = bm
			bar.material_override = rm
			bar.rotation.y = PI / 2 * i
			_direct.add_child(bar)
		_direct_label = Label3D.new()
		_direct_label.text = Loc.t("DIRECT ATTACK")
		_direct_label.font = UITheme.title_font()
		_direct_label.font_size = 96
		_direct_label.pixel_size = 0.0042
		_direct_label.outline_size = 22
		_direct_label.modulate = Color("ffe3e3")
		_direct_label.outline_modulate = Color("7a0d16")
		_direct_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_direct_label.no_depth_test = true
		_direct_label.position = Vector3(0, 0.95, 0)
		_direct.add_child(_direct_label)
		var area := Area3D.new()
		area.name = "Hit"
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(8.6, 0.9, 2.2)
		cs.shape = box
		area.add_child(cs)
		area.position = Vector3(0, 0.3, 0)
		area.mouse_entered.connect(func(): _direct_hover = true)
		area.mouse_exited.connect(func(): _direct_hover = false)
		area.input_event.connect(func(_cam, ev, _pos, _n, _i):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				direct_clicked.emit())
		_direct.add_child(area)
	_direct.visible = on
	(_direct.get_node("Hit") as Area3D).input_ray_pickable = on
	if not on:
		_direct_hover = false


func start_aim(inst) -> void:
	_aim_from = card_for(inst)
	if _arrow == null:
		_arrow = _make_arrow()
	_arrow.visible = _aim_from != null


func set_aim_target(card: Card3D) -> void:
	_aim_target = card


func stop_aim() -> void:
	_aim_from = null
	_aim_target = null
	if _arrow:
		_arrow.visible = false


func _make_arrow() -> Node3D:
	var root := Node3D.new()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color("ff5a5a")
	m.emission_enabled = true
	m.emission = Color("ff3b3b")
	m.emission_energy_multiplier = 3.0
	m.no_depth_test = true
	var shaft := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.09, 0.02, 1.0)
	shaft.mesh = box
	shaft.material_override = m
	shaft.name = "Shaft"
	root.add_child(shaft)
	var head := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.22
	cone.height = 0.4
	head.mesh = cone
	head.material_override = m
	head.name = "Head"
	head.rotation_degrees = Vector3(-90, 0, 0)
	root.add_child(head)
	root.visible = false
	add_child(root)
	return root


func _update_arrow() -> void:
	_update_drop()
	if _arrow == null or not _arrow.visible or _aim_from == null or not is_instance_valid(_aim_from):
		return
	var from := _aim_from.global_position + Vector3(0, 0.25, 0)
	var to: Vector3
	if _direct != null and _direct.visible:
		var pulse := 1.0 + sin(_time * 5.0) * 0.07
		_direct_ring.scale = Vector3(pulse, 0.2, pulse) * (1.12 if _direct_hover else 1.0)
		_direct_label.modulate = Color.WHITE if _direct_hover else Color("ffc9c9")
	if _direct != null and _direct.visible and _direct_hover:
		to = _direct.global_position + Vector3(0, 0.25, 0)
	elif _aim_target and is_instance_valid(_aim_target):
		to = _aim_target.global_position + Vector3(0, 0.25, 0)
	else:
		var mp := get_viewport().get_mouse_position()
		var o := camera.project_ray_origin(mp)
		var d := camera.project_ray_normal(mp)
		if absf(d.y) < 0.001:
			return
		var t := (0.25 - o.y) / d.y
		to = o + d * t
	var dir := to - from
	var length := maxf(dir.length(), 0.3)
	var pulse := 1.0 + sin(_time * 10.0) * 0.08
	_arrow.global_position = from
	_arrow.look_at(to if to.distance_to(from) > 0.01 else from + Vector3.FORWARD, Vector3.UP)
	var shaft := _arrow.get_node("Shaft") as MeshInstance3D
	shaft.scale = Vector3(pulse, 1, length - 0.35)
	shaft.position = Vector3(0, 0, -(length - 0.35) / 2.0)
	var head := _arrow.get_node("Head") as MeshInstance3D
	head.position = Vector3(0, 0, -length + 0.2)
	head.scale = Vector3(pulse, pulse, pulse)


# ------------------------------------------------------------------ camera

## Move the camera to a shot and hold it; call cam_release() to go back to the table.
func cam_shot(pos: Vector3, target: Vector3, dur := 0.45) -> void:
	if _cam_tween:
		_cam_tween.kill()
	if cam_weight < 0.05:
		cam_pos = pos
		cam_target = target
	_cam_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_cam_tween.tween_property(self, "cam_pos", pos, Settings.t(dur))
	_cam_tween.tween_property(self, "cam_target", target, Settings.t(dur))
	_cam_tween.tween_property(self, "cam_weight", 1.0, Settings.t(dur))


## Cut straight to a shot, no travel.
func cam_cut(pos: Vector3, target: Vector3) -> void:
	if _cam_tween:
		_cam_tween.kill()
	cam_pos = pos
	cam_target = target
	cam_weight = 1.0


## Slide slowly from the current shot toward another spot, for a little life in a held shot.
func cam_drift(pos: Vector3, dur: float) -> void:
	if _cam_tween:
		_cam_tween.kill()
	_cam_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_cam_tween.tween_property(self, "cam_pos", pos, dur)


func cam_release(dur := 0.5) -> void:
	if _cam_tween:
		_cam_tween.kill()
	_cam_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_cam_tween.tween_property(self, "cam_weight", 0.0, Settings.t(dur))


# ------------------------------------------------------------------ duelists

var _duelists := {}   # player index -> RoamFigure
var _aside := 0.0
const DUELIST_Z := 6.7


## The two duelists stand at their ends of the field, each on a lit plate.
func add_duelists(me_key: String, opp_key: String) -> void:
	if turbo:
		for p in 2:
			var col: Color = theme["accent"] if p == 0 else theme["accent2"]
			var side := 1.0 if p == 0 else -1.0
			_duelists[p] = track.add_rider(p, me_key if p == 0 else opp_key, Vector3(0, 0, side * DUELIST_Z), col)
		return
	for p in 2:
		var key := me_key if p == 0 else opp_key
		var side := 1.0 if p == 0 else -1.0
		var col: Color = theme["accent"] if p == 0 else theme["accent2"]
		var plate := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 1.25
		cm.bottom_radius = 1.45
		cm.height = 0.5
		plate.mesh = cm
		var pm := StandardMaterial3D.new()
		pm.albedo_color = Color(theme["base"]).lightened(0.1)
		pm.metallic = 0.6
		pm.roughness = 0.35
		plate.material_override = pm
		plate.position = Vector3(0, -0.25, side * DUELIST_Z)
		add_child(plate)
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 1.12
		tm.outer_radius = 1.24
		ring.mesh = tm
		var rm := StandardMaterial3D.new()
		rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rm.albedo_color = col
		rm.emission_enabled = true
		rm.emission = col
		rm.emission_energy_multiplier = 2.5
		ring.material_override = rm
		ring.position = Vector3(0, 0.02, side * DUELIST_Z)
		ring.scale = Vector3(1, 0.25, 1)
		add_child(ring)
		var fig := RoamFigure.new()
		fig.position = Vector3(0, 0.0, side * DUELIST_Z)
		fig.rotation.y = PI if p == 0 else 0.0
		fig.scale = Vector3.ONE * 1.2
		add_child(fig)
		fig.setup(key, col, "", false)
		fig.lively = false
		fig.greets = false
		_duelists[p] = fig
		var spot := SpotLight3D.new()
		spot.light_color = Color.WHITE.lerp(col, 0.25)
		spot.light_energy = 7.0
		spot.spot_range = 9.0
		spot.spot_angle = 30.0
		spot.shadow_enabled = false
		spot.position = Vector3(1.6 * side, 5.2, side * (DUELIST_Z - 2.6))
		add_child(spot)
		spot.look_at(Vector3(0, 1.3, side * DUELIST_Z))


## The duelist at the table acts out what they just said.
const TALK_MOVES := {"intro": "challenge", "taunt": "chat", "ace": "cheer", "attack": "agree", "react": "scratch",
	"destroyed": "stomp", "low": "alert", "hurt": "alert", "trap": "agree", "spell": "chat", "set": "listen",
	"big_hit": "cheer", "comeback": "cheer", "turn": "", "draw_pressure": "scratch"}


func duelist_gesture(p: int, kind: String) -> void:
	if not _duelists.has(p) or not (_duelists[p] is RoamFigure):
		return
	var fig: RoamFigure = _duelists[p]
	var move := str(TALK_MOVES.get(kind, "chat"))
	if move == "":
		fig.do_nod()
		return
	if move == "cheer":
		fig.play_once("cheer")
	elif not fig.gesture(move, 0.18 if move == "challenge" else 0.25):
		print("GESTURE FAILED ", move)
		fig.do_nod()
	if "--pose-debug" in OS.get_cmdline_user_args():
		print("POSE ", move, " playing=", fig._anim.current_animation if fig._anim else "none", " hold=", fig._hold, " t=", Time.get_ticks_msec())
	# Big moves run long; trim them so the duelist is back in their stance soon.
	fig._hold = minf(fig._hold, 3.0 if move in ["stomp", "cheer", "bow", "challenge"] else 2.4)


## The duelist's whole body sells the moment: a step into an attack, a stagger when hit,
## a pull of the arm on a draw. Works with any model, since it moves the figure itself.
var _body_tw := {}

func duelist_body(p: int, kind: String, strength := 1.0) -> void:
	if turbo or not _duelists.has(p) or not is_instance_valid(_duelists[p]) or not (_duelists[p] is RoamFigure):
		return
	var fig: Node3D = _duelists[p]
	var side := 1.0 if p == 0 else -1.0
	var home := Vector3(0, 0.0, side * DUELIST_Z)
	if _body_tw.has(p) and _body_tw[p] and (_body_tw[p] as Tween).is_valid():
		(_body_tw[p] as Tween).kill()
	fig.position = home
	fig.rotation.x = 0.0
	fig.rotation.z = 0.0
	var tw := create_tween()
	_body_tw[p] = tw
	match kind:
		"attack":
			# Wind up, then throw the whole body at the field.
			tw.tween_property(fig, "rotation:x", -0.1, 0.12)
			tw.parallel().tween_property(fig, "position:z", home.z + side * 0.12, 0.12)
			tw.tween_property(fig, "rotation:x", 0.24 * strength, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(fig, "position:z", home.z - side * 0.5 * strength, 0.1)
			tw.tween_interval(0.35)
			tw.tween_property(fig, "rotation:x", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
			tw.parallel().tween_property(fig, "position:z", home.z, 0.3).set_trans(Tween.TRANS_SINE)
		"hurt":
			# Knocked back on the heels, a shudder, then squaring up again.
			var k := clampf(strength, 0.4, 1.6)
			tw.tween_property(fig, "rotation:x", -0.22 * k, 0.07)
			tw.parallel().tween_property(fig, "position:z", home.z + side * 0.42 * k, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			for i in 3:
				tw.tween_property(fig, "rotation:z", 0.07 * k * (1.0 if i % 2 == 0 else -1.0), 0.05)
			tw.tween_property(fig, "rotation:z", 0.0, 0.05)
			tw.tween_interval(0.2)
			tw.tween_property(fig, "rotation:x", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
			tw.parallel().tween_property(fig, "position:z", home.z, 0.4).set_trans(Tween.TRANS_SINE)
		"summon":
			# Up on the toes as the card hits the disk.
			tw.tween_property(fig, "position:y", 0.14 * strength, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(fig, "rotation:x", 0.12 * strength, 0.1)
			tw.tween_property(fig, "position:y", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_property(fig, "rotation:x", 0.0, 0.25)
		"draw":
			tw.tween_property(fig, "rotation:x", -0.08, 0.1)
			tw.tween_property(fig, "rotation:x", 0.06, 0.12)
			tw.tween_property(fig, "rotation:x", 0.0, 0.2)
		_:
			tw.tween_interval(0.01)


## Close-up on one duelist (0 = you, 1 = opponent), from the front and slightly below.
## `aside` slides the duelist toward the left of the frame, leaving room for a panel.
func duelist_shot(p: int, dur := 0.6, cheer := false, aside := 0.0) -> void:
	if not _duelists.has(p):
		return
	var side := 1.0 if p == 0 else -1.0
	var z := side * DUELIST_Z
	_aside = aside
	cam_shot(Vector3(-1.35 * side, 1.55, z - side * 3.6), Vector3((0.1 - aside) * side, 1.45, z), dur)
	if cheer:
		(_duelists[p] as RoamFigure).play_once("victory", 2)
		if _duelists.has(1 - p):
			(_duelists[1 - p] as RoamFigure).play_once("lose")


## Park the camera on the opening shot (your rival) while the VS card is up.
func intro_hold() -> void:
	if _duelists.size() < 2:
		return
	if _cam_tween:
		_cam_tween.kill()
	cam_pos = Vector3(2.2, 1.2, -DUELIST_Z + 4.6)
	cam_target = Vector3(0.0, 1.55, -DUELIST_Z)
	cam_weight = 1.0


## Opening: a look at your rival, then at you from behind, then up and over to the table.
func intro_duelists() -> void:
	if _duelists.size() < 2:
		await intro_flyover(2.6)
		return
	var oz := -DUELIST_Z
	intro_hold()
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "cam_pos", Vector3(1.2, 1.5, oz + 3.3), 1.5)
	_cam_tween = tw
	await get_tree().create_timer(1.5).timeout
	tw.kill()
	# Over your own shoulder, looking down the field at them.
	cam_pos = Vector3(1.5, 2.3, DUELIST_Z + 3.4)
	cam_target = Vector3(-0.3, 1.2, 0.0)
	var tw2 := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw2.tween_property(self, "cam_pos", Vector3(0.9, 2.7, DUELIST_Z + 2.4), 1.2)
	_cam_tween = tw2
	await get_tree().create_timer(1.2).timeout
	tw2.kill()
	var tw3 := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw3.tween_property(self, "cam_weight", 0.0, 1.0)
	_cam_tween = tw3
	await tw3.finished


## Slow drift around whoever the camera is on. Call after duelist_shot.
func duelist_orbit(p: int, dur := 6.0) -> void:
	if not _duelists.has(p):
		return
	var side := 1.0 if p == 0 else -1.0
	var z := side * DUELIST_Z
	if _cam_tween:
		_cam_tween.kill()
	_cam_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_cam_tween.tween_property(self, "cam_pos", Vector3(0.6 * side, 1.75, z - side * 3.9), dur)


## Opening shot: a sweep over the arena that settles on the table.
func intro_flyover(dur := 3.2) -> void:
	cam_pos = Vector3(-16, 5.5, 15)
	cam_target = Vector3(0, 3.0, -8)
	cam_weight = 1.0
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "cam_pos", Vector3(6, 3.2, 11), dur * 0.55)
	tw.tween_property(self, "cam_target", Vector3(0, 1.5, -2), dur * 0.55)
	tw.chain().tween_property(self, "cam_weight", 0.0, dur * 0.45).set_trans(Tween.TRANS_CUBIC)
	_cam_tween = tw
	await tw.finished


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _process(delta: float) -> void:
	_time += delta
	_process_extra(_time)
	_shake = move_toward(_shake, 0.0, delta * 1.6)
	var sway := Vector3(sin(_time * 0.35) * 0.06, sin(_time * 0.5) * 0.04, 0)
	var s := _shake * _shake * 0.35
	var jitter := Vector3(_rng.randf_range(-s, s), _rng.randf_range(-s, s), 0)
	var pos := cam_home.lerp(cam_pos, cam_weight) + sway * (1.0 - cam_weight) + jitter
	var tgt := cam_home_target.lerp(cam_target, cam_weight) + jitter * 0.5
	camera.position = pos
	camera.look_at(tgt)
	_update_arrow()
