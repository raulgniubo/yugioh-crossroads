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
var _gy_ready: Label3D      # (0.79.1) your Graveyard (or banished) has a card that can use its effect now
var _gy_ring: MeshInstance3D
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
	# Face-down is the same card turned over along its long side, like turning a page: the picture on
	# the back then reads the right way up from its owner's seat (it used to be upside down).
	var b := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -PI / 2.0)
	return b if face_up else b * Basis(Vector3.UP, PI)


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
	_sky_mat = sky_mat
	var env := Environment.new()
	_env = env
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
	Settings.fplus_env(env)
	var key := DirectionalLight3D.new()
	key.light_color = Color("fff1d6") if theme.get("day", false) else Color("e6f3ff")
	key.light_energy = 1.25 if theme.get("day", false) else 0.75
	key.rotation_degrees = Vector3(-62, -18, 0)
	key.shadow_enabled = true
	add_child(key)
	_key = key
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
		camera.fov = 47
	for a in OS.get_cmdline_user_args():
		# --duel-cam=px,py,pz,tx,ty,tz (testing): where the table camera sits, for wide pictures.
		if a.begins_with("--duel-cam="):
			var cv := a.substr(11).split(",")
			if cv.size() == 6:
				cam_home = Vector3(float(cv[0]), float(cv[1]), float(cv[2]))
				cam_home_target = Vector3(float(cv[3]), float(cv[4]), float(cv[5]))
	if "--crowd-shot" in OS.get_cmdline_user_args():
		# (testing) a big cheer and the camera's glance at the people watching, held.
		get_tree().create_timer(4.0).timeout.connect(func():
			house(0.95, Color(1.0, 0.8, 0.3), Vector3.ZERO, 6.0)
			crowd_shot(8.0))
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
// A Field Spell: its ground, spreading out from the Field Zone it was played in.
uniform int field_surface = 0;
uniform float field_r = 0.0;
uniform vec2 field_o = vec2(0.0);
uniform vec3 field_glow : source_color = vec3(1.0);
uniform float field_dark = 0.0;
uniform float field_shade = 1.0;
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
		col = ground_lit(p, surface, TIME) * (0.78 + 0.3 * vig);
	}
	float dark_p = dark_paint;
	if (field_surface > 0 && field_r > 0.01) {
		// The Field Spell's place takes the ground over from where the card lies: a ragged
		// front running outward, lit along its edge.
		float fd = length((p - field_o) * vec2(1.0, 1.2)) + (g_fbm(p * 1.4 + 5.0) - 0.5) * 1.5;
		float fm = 1.0 - smoothstep(field_r - 0.45, field_r, fd);
		vec3 fc = ground_lit(p, field_surface, TIME) * (0.8 + 0.28 * vig) * field_shade;
		col = mix(col, fc, fm);
		float front = (1.0 - smoothstep(0.0, 0.3, abs(fd - field_r + 0.2))) * (1.0 - smoothstep(16.0, 19.0, field_r));
		col += field_glow * front * 1.5;
		wild = max(wild, fm);
		dark_p = mix(dark_p, field_dark, fm);
	}
	// Rotating emblem rings in the middle
	float r = length(p);
	float a = atan(p.y, p.x);
	float ring1 = line_aa(abs(r - 1.25), 0.03);
	float ring2 = line_aa(abs(r - 1.55), 0.015);
	float dash = step(0.5, fract((a + TIME * 0.15) * 12.0 / 6.28318));
	float ring3 = line_aa(abs(r - 1.85), 0.012) * dash;
	// Outdoors the middle is one painted circle, like the center of a pitch.
	vec3 paint = mix(mix(side, vec3(1.0), 0.7), vec3(0.08, 0.14, 0.36), dark_p);
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
	# A Turbo Duel's field is a hologram over the road, never painted ground.
	m.set_shader_parameter("surface", 0 if turbo else int(theme.get("surface", 0)))
	m.set_shader_parameter("dark_paint", 1.0 if theme.get("dark_paint", false) else 0.0)
	m.set_shader_parameter("base", theme["base"])
	m.set_shader_parameter("accent", theme["accent"])
	m.set_shader_parameter("accent2", theme["accent2"])
	m.set_shader_parameter("pattern", theme["pattern"])
	mi.material_override = m
	_mat_m = m
	add_child(mi)


## Floor beyond the mat, corner pylons and drifting particles.

# ------------------------------------------------------------------ a Field Spell takes the field

var _mat_m: ShaderMaterial
var _env: Environment
var _sky_mat: ProceduralSkyMaterial
var _key: DirectionalLight3D
var _field_key := ""              # which place the field is right now ("" = its own)
var _field_glow_c := Color.WHITE
var _zone_mats: Array[ShaderMaterial] = []
var _zone_dark := -1.0            # how dark the zones are painted right now (-1 = not read yet)
var _zone_tw: Tween


## The zones are painted light on a dark ground and dark on a pale one. A Field Spell can turn
## one into the other, so their paint follows the ground they are on.
func _zone_paint(dark: float, secs: float) -> void:
	if _zone_dark < 0.0:
		_zone_dark = 1.0 if theme.get("dark_paint", false) else 0.0
	if _zone_tw:
		_zone_tw.kill()
	_zone_tw = create_tween()
	_zone_tw.tween_method(func(v: float):
		_zone_dark = v
		for zm in _zone_mats:
			zm.set_shader_parameter("dark_paint", v), _zone_dark, dark, Settings.t(secs))
var _field_tw: Tween
var _field_env_tw: Tween
var _field_nodes: Node3D          # what stands at the edges, and what drifts over it
var _field_light: OmniLight3D
var _field_home := {}             # the field's own light, to go back to


## The field becomes the place of a Field Spell: its ground spreads out from `at` (where the
## card lies), the light and the air follow, and what belongs there rises at the edges.
func set_field_look(look: Dictionary, at: Vector3) -> void:
	if turbo or _mat_m == null:
		return       # a Turbo Duel's field is a hologram over the road
	var key := str(look.get("key", ""))
	if key == _field_key:
		return
	var had := _field_key != ""
	_field_key = key
	_field_glow_c = look.get("glow", Color.WHITE)
	if _field_home.is_empty() and _env != null:
		_field_home = {"amb": _env.ambient_light_color, "amb_e": _env.ambient_light_energy, "fog": _env.fog_light_color,
			"top": _sky_mat.sky_top_color, "hor": _sky_mat.sky_horizon_color, "key": _key.light_color, "key_e": _key.light_energy}
	if _field_tw:
		_field_tw.kill()
	_field_tw = create_tween()
	if had:
		# One place gives way to the next: the old ground pulls back first.
		_field_tw.tween_method(_field_radius, float(_mat_m.get_shader_parameter("field_r")), 0.0, Settings.t(0.35)).set_trans(Tween.TRANS_SINE)
		_drop_field_nodes()
	_field_tw.tween_callback(func():
		_mat_m.set_shader_parameter("field_surface", int(look.get("surface", 6)))
		_mat_m.set_shader_parameter("field_o", Vector2(at.x, at.z))
		_mat_m.set_shader_parameter("field_glow", look.get("glow", Color.WHITE))
		_mat_m.set_shader_parameter("field_dark", 1.0 if look.get("dark", false) else 0.0)
		_mat_m.set_shader_parameter("field_shade", float(look.get("shade", 1.0)))
		_raise_field_nodes(look, at)
		Sfx.play("summon", -8.0, 0.7))
	_field_tw.tween_method(_field_radius, 0.0, 20.0, Settings.t(1.5)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_field_env(look, 1.2)
	_zone_paint(1.0 if look.get("dark", false) else 0.0, 1.0)


## The card left the field: its place pulls back into the Field Zone and the field is itself again.
func clear_field_look() -> void:
	if _field_key == "" or _mat_m == null:
		return
	_field_key = ""
	if _field_tw:
		_field_tw.kill()
	_field_tw = create_tween()
	_field_tw.tween_method(_field_radius, float(_mat_m.get_shader_parameter("field_r")), 0.0, Settings.t(0.9)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_field_tw.tween_callback(func(): _mat_m.set_shader_parameter("field_surface", 0))
	_drop_field_nodes()
	_field_env({}, 0.9)
	_zone_paint(1.0 if theme.get("dark_paint", false) else 0.0, 0.9)


## The color of the place the field is right now (white when it is its own).
func field_glow() -> Color:
	return _field_glow_c if _field_key != "" else Color("8dffb0")


func _field_radius(r: float) -> void:
	_mat_m.set_shader_parameter("field_r", r)


## The light and the sky lean toward the Field Spell's place (and back, with an empty look).
func _field_env(look: Dictionary, secs: float) -> void:
	if _env == null or _field_home.is_empty():
		return
	var amb: Color = _field_home["amb"]
	var amb_e: float = _field_home["amb_e"]
	var fog: Color = _field_home["fog"]
	var top: Color = _field_home["top"]
	var hor: Color = _field_home["hor"]
	var kc: Color = _field_home["key"]
	var ke: float = _field_home["key_e"]
	if not look.is_empty():
		var glow: Color = look.get("glow", Color.WHITE)
		var day: bool = look.get("day", false)
		amb = amb.lerp(glow.lerp(Color.WHITE, 0.55), 0.6)
		amb_e = lerpf(amb_e, 0.95 if day else 0.6, 0.6)
		fog = fog.lerp(look.get("fog", fog), 0.75)
		top = top.lerp((look["sky"] as Array)[0], 0.8)
		hor = hor.lerp((look["sky"] as Array)[1], 0.8)
		kc = kc.lerp(glow.lerp(Color.WHITE, 0.7), 0.5)
		ke = lerpf(ke, 1.2 if day else 0.7, 0.5)
	if _field_env_tw:
		_field_env_tw.kill()
	_field_env_tw = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	var t := Settings.t(secs)
	_field_env_tw.tween_property(_env, "ambient_light_color", amb, t)
	_field_env_tw.tween_property(_env, "ambient_light_energy", amb_e, t)
	_field_env_tw.tween_property(_env, "fog_light_color", fog, t)
	_field_env_tw.tween_property(_sky_mat, "sky_top_color", top, t)
	_field_env_tw.tween_property(_sky_mat, "sky_horizon_color", hor, t)
	_field_env_tw.tween_property(_sky_mat, "ground_horizon_color", hor, t)
	_field_env_tw.tween_property(_key, "light_color", kc, t)
	_field_env_tw.tween_property(_key, "light_energy", ke, t)


func _drop_field_nodes() -> void:
	if _field_nodes == null or not is_instance_valid(_field_nodes):
		return
	var old := _field_nodes
	_field_nodes = null
	for c in old.get_children():
		if c is CPUParticles3D:
			(c as CPUParticles3D).emitting = false
	var tw := create_tween().set_parallel()
	for c in old.get_children():
		if c is Node3D and not (c is CPUParticles3D):
			tw.tween_property(c, "scale", Vector3(1.0, 0.001, 1.0), Settings.t(0.6)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		if c is OmniLight3D:
			tw.tween_property(c, "light_energy", 0.0, Settings.t(0.6))
	tw.chain().tween_interval(2.4)       # (the last of what drifts gets to land)
	tw.chain().tween_callback(old.queue_free)


func _fmat(c: Color, glow := 0.0, rough := 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = glow
	return m


func _fpart(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO, sc := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = sc
	parent.add_child(mi)
	return mi


func _cone(r: float, h: float, sides := 7) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = 0.0
	m.bottom_radius = r
	m.height = h
	m.radial_segments = sides
	m.rings = 1
	return m


func _cyl(r0: float, r1: float, h: float, sides := 8) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = r0
	m.bottom_radius = r1
	m.height = h
	m.radial_segments = sides
	m.rings = 1
	return m


func _ball(r: float, squash := 1.0) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0 * squash
	m.radial_segments = 12
	m.rings = 6
	return m


func _brick(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


## Where things can stand: along both long sides of the field and behind the far end, clear of
## the two duelists and low enough near you that nothing gets between the camera and the cards.
## Each spot: [position, how big something may be there].
func _field_spots(rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	for side in [-1.0, 1.0]:
		for i in 5:
			var z := -4.6 + i * 1.75 + rng.randf_range(-0.3, 0.3)
			out.append([Vector3(side * (7.3 + rng.randf_range(0.0, 1.5)), 0.0, z), 1.0 - 0.14 * i])
		for i in 3:
			out.append([Vector3(side * (2.6 + i * 1.7 + rng.randf_range(-0.3, 0.3)), 0.0, -5.4 - rng.randf_range(0.0, 1.6)), 1.05])
	return out


## What belongs in the Field Spell's place rises at the edges of the field, and its air starts.
func _raise_field_nodes(look: Dictionary, at: Vector3) -> void:
	_drop_field_nodes()
	_field_nodes = Node3D.new()
	add_child(_field_nodes)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(look.get("key", "")))
	var glow: Color = look.get("glow", Color.WHITE)
	var kind := str(look.get("props", ""))
	var i := 0
	for spot in _field_spots(rng):
		var holder := Node3D.new()
		holder.position = spot[0]
		holder.rotation.y = rng.randf() * TAU
		_field_nodes.add_child(holder)
		_field_prop(holder, kind, float(spot[1]), glow, rng)
		holder.scale = Vector3(1.0, 0.001, 1.0)
		var tw := create_tween()
		tw.tween_interval(Settings.t(0.25 + ((spot[0] as Vector3) - at).length() * 0.07))
		tw.tween_property(holder, "scale", Vector3.ONE, Settings.t(0.7)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1
	# A wash of the place's own light over the cards.
	_field_light = OmniLight3D.new()
	_field_light.light_color = glow
	_field_light.light_energy = 0.0
	_field_light.omni_range = 11.0
	_field_light.position = Vector3(0, 3.2, 0)
	_field_nodes.add_child(_field_light)
	create_tween().tween_property(_field_light, "light_energy", 1.1, Settings.t(1.2))
	_field_air(str(look.get("air", "none")), glow)


func _field_prop(h: Node3D, kind: String, k: float, glow: Color, rng: RandomNumberGenerator) -> void:
	match kind:
		"trees":
			var hgt := rng.randf_range(2.2, 3.4) * k
			_fpart(h, _cyl(0.1, 0.17, hgt * 0.5), _fmat(Color(0.3, 0.2, 0.12)), Vector3(0, hgt * 0.25, 0))
			var leaf := _fmat(Color(0.1, 0.36, 0.14).lerp(Color(0.2, 0.5, 0.16), rng.randf()))
			for j in 3:
				_fpart(h, _cone(0.95 - j * 0.22, hgt * 0.42, 8), leaf, Vector3(0, hgt * (0.45 + j * 0.2), 0))
			_fpart(h, _ball(0.3, 0.6), _fmat(Color(0.14, 0.36, 0.12)), Vector3(rng.randf_range(-0.9, 0.9), 0.14, rng.randf_range(-0.9, 0.9)))
		"grass":
			var blade := _fmat(Color(0.3, 0.6, 0.16))
			for j in 9:
				var a := rng.randf() * TAU
				var d := rng.randf_range(0.0, 0.9)
				_fpart(h, _cone(0.05, rng.randf_range(0.45, 0.95) * k, 4), blade, Vector3(cos(a) * d, 0.3, sin(a) * d), Vector3(rng.randf_range(-0.25, 0.25), 0, rng.randf_range(-0.25, 0.25)))
			if rng.randf() < 0.5:
				_fpart(h, _ball(0.4, 0.7), _fmat(Color(0.5, 0.5, 0.48)), Vector3(0.5, 0.18, -0.3))
			else:
				for j in 3:
					_fpart(h, _ball(0.07), _fmat(Color(1.0, 0.9, 0.4), 0.4), Vector3(rng.randf_range(-0.7, 0.7), 0.5, rng.randf_range(-0.7, 0.7)))
		"rocks":
			var rock := _fmat(Color(0.36, 0.38, 0.44))
			var hgt := rng.randf_range(1.6, 3.2) * k
			_fpart(h, _cone(0.9, hgt, 5), rock, Vector3(0, hgt * 0.5, 0), Vector3(0, 0, rng.randf_range(-0.12, 0.12)))
			_fpart(h, _cone(0.42, hgt * 0.34, 5), _fmat(Color(0.92, 0.96, 1.0)), Vector3(0, hgt * 0.84, 0))
			_fpart(h, _cone(0.55, hgt * 0.55, 5), rock, Vector3(0.75, hgt * 0.27, 0.3))
		"dead":
			var wood := _fmat(Color(0.3, 0.24, 0.18))
			if rng.randf() < 0.55:
				var hgt := rng.randf_range(1.4, 2.4) * k
				_fpart(h, _cyl(0.05, 0.13, hgt, 6), wood, Vector3(0, hgt * 0.5, 0), Vector3(0, 0, 0.08))
				_fpart(h, _cyl(0.02, 0.06, hgt * 0.5, 5), wood, Vector3(0.28, hgt * 0.72, 0), Vector3(0, 0, -0.9))
				_fpart(h, _cyl(0.02, 0.05, hgt * 0.4, 5), wood, Vector3(-0.22, hgt * 0.6, 0.05), Vector3(0, 0, 0.8))
			else:
				_fpart(h, _ball(0.55, 0.6), _fmat(Color(0.56, 0.44, 0.3)), Vector3(0, 0.22, 0))
				_fpart(h, _cyl(0.035, 0.035, 0.9, 5), _fmat(Color(0.88, 0.85, 0.76)), Vector3(0.6, 0.05, 0.2), Vector3(0, 0.6, PI / 2.0))
		"coral":
			var cols := [Color(1.0, 0.5, 0.45), Color(1.0, 0.72, 0.4), Color(0.95, 0.45, 0.75)]
			var cm := _fmat(cols[rng.randi() % 3], 0.15)
			for j in 4:
				var a := rng.randf() * TAU
				_fpart(h, _cyl(0.05, 0.1, rng.randf_range(0.5, 1.2) * k, 6), cm, Vector3(cos(a) * 0.3, 0.4, sin(a) * 0.3), Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4)))
			_fpart(h, _ball(0.5, 0.5), _fmat(Color(0.86, 0.82, 0.66)), Vector3(0, 0.1, 0))
			_fpart(h, _ball(0.16), _fmat(Color(0.8, 0.97, 1.0, 1.0), 0.3), Vector3(0.5, 0.2, 0.3))
		"lava":
			var hgt := rng.randf_range(1.0, 2.2) * k
			_fpart(h, _cone(0.8, hgt, 6), _fmat(Color(0.11, 0.08, 0.07)), Vector3(0, hgt * 0.5, 0))
			_fpart(h, _cone(0.26, hgt * 0.3, 6), _fmat(Color(1.0, 0.45, 0.08), 2.6), Vector3(0, hgt * 0.9, 0))
			_fpart(h, _ball(0.3, 0.3), _fmat(Color(1.0, 0.35, 0.05), 2.2), Vector3(0.7, 0.03, 0.4))
		"spires":
			var hgt := rng.randf_range(2.0, 3.6) * k
			_fpart(h, _cone(0.42, hgt, 5), _fmat(Color(0.08, 0.05, 0.13)), Vector3(0, hgt * 0.5, 0), Vector3(0, 0, rng.randf_range(-0.1, 0.1)))
			_fpart(h, _cone(0.1, hgt * 0.5, 4), _fmat(glow, 2.4), Vector3(0, hgt * 0.78, 0))
			_fpart(h, _ball(0.12), _fmat(glow, 3.0), Vector3(rng.randf_range(-0.5, 0.5), hgt * rng.randf_range(0.4, 0.9), rng.randf_range(-0.5, 0.5)))
		"pillars":
			var hgt := rng.randf_range(1.8, 3.0) * k
			var stone := _fmat(Color(0.93, 0.91, 0.84), 0.0, 0.5)
			_fpart(h, _cyl(0.2, 0.22, hgt, 12), stone, Vector3(0, hgt * 0.5, 0))
			_fpart(h, _brick(Vector3(0.62, 0.14, 0.62)), stone, Vector3(0, 0.07, 0))
			_fpart(h, _brick(Vector3(0.6, 0.14, 0.6)), _fmat(Color(1.0, 0.86, 0.42), 0.5, 0.35), Vector3(0, hgt + 0.07, 0))
			_fpart(h, _ball(0.16), _fmat(glow, 2.6), Vector3(0, hgt + 0.42, 0))
		"clouds":
			var cm := _fmat(Color(1, 1, 1), 0.25)
			var y := rng.randf_range(0.5, 1.7)
			for j in 4:
				_fpart(h, _ball(rng.randf_range(0.45, 0.8), 0.6), cm, Vector3(j * 0.55 - 0.8, y + rng.randf_range(-0.12, 0.12), rng.randf_range(-0.2, 0.2)))
		"towers":
			var hgt := rng.randf_range(2.6, 4.4) * k
			var w := rng.randf_range(0.7, 1.1)
			_fpart(h, _brick(Vector3(w, hgt, w)), _fmat(Color(0.07, 0.08, 0.13), 0.0, 0.4), Vector3(0, hgt * 0.5, 0))
			var win := _fmat(Color(1.0, 0.8, 0.42).lerp(glow, rng.randf() * 0.5), 1.1)
			for j in int(hgt / 0.42):
				for f in 4:
					# A floor with its lights on, on this side: about half of them are.
					if rng.randf() < 0.5:
						var n := Vector3(sin(f * PI / 2.0), 0, cos(f * PI / 2.0))
						_fpart(h, _brick(Vector3(w * rng.randf_range(0.25, 0.6), 0.055, 0.02)), win, n * (w * 0.5 + 0.008) + Vector3(0, 0.36 + j * 0.42, 0), Vector3(0, f * PI / 2.0, 0))
			_fpart(h, _brick(Vector3(0.05, 0.6, 0.05)), _fmat(Color(1.0, 0.2, 0.2), 3.0), Vector3(0, hgt + 0.3, 0))
		"ruins":
			var stone := _fmat(Color(0.74, 0.63, 0.44))
			var hgt := rng.randf_range(0.9, 2.3) * k
			_fpart(h, _cyl(0.24, 0.27, hgt, 10), stone, Vector3(0, hgt * 0.5, 0))
			_fpart(h, _brick(Vector3(0.7, 0.16, 0.7)), stone, Vector3(0, 0.08, 0))
			if rng.randf() < 0.5:
				_fpart(h, _cyl(0.24, 0.24, 0.8, 10), stone, Vector3(0.75, 0.24, 0.2), Vector3(PI / 2.0, 0.4, 0))
			else:
				_fpart(h, _brick(Vector3(0.6, 0.4, 0.5)), stone, Vector3(-0.7, 0.2, 0.3), Vector3(0, 0.5, 0.1))
		_:
			_fpart(h, _ball(0.2), _fmat(glow, 2.0), Vector3(0, 0.8, 0))


## What drifts over the field: leaves, snow, embers, dust...
func _field_air(kind: String, glow: Color) -> void:
	if kind == "none" or _field_nodes == null:
		return
	var p := CPUParticles3D.new()
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(7.0, 0.3, 4.6)
	p.position = Vector3(0, 3.4, 0)
	p.amount = 70
	p.lifetime = 4.5
	p.preprocess = 0.0
	p.direction = Vector3(0.2, -1, 0.1)
	p.spread = 14.0
	p.gravity = Vector3(0, -0.5, 0)
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var quad := QuadMesh.new()
	quad.size = Vector2(0.09, 0.09)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	# (0.61.0) Keep the particle's own scale: a speck that has not been let go yet has none, so it
	# stays hidden. Without this every waiting speck was drawn at the emitter, black and full size
	# (a dark blot over the field for the first seconds of a place).
	m.billboard_keep_scale = true
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var col := Color.WHITE
	match kind:
		"leaves":
			col = Color(0.7, 0.62, 0.16, 0.95)
			quad.size = Vector2(0.13, 0.08)
			p.angular_velocity_min = -160.0
			p.angular_velocity_max = 160.0
			p.amount = 46
		"petals":
			col = Color(1.0, 0.82, 0.9, 0.9)
			quad.size = Vector2(0.08, 0.06)
			p.amount = 40
			p.angular_velocity_min = -120.0
			p.angular_velocity_max = 120.0
		"snow":
			col = Color(1, 1, 1, 0.9)
			quad.size = Vector2(0.06, 0.06)
			p.amount = 110
			p.initial_velocity_min = 0.8
			p.initial_velocity_max = 1.4
		"dust":
			col = Color(0.86, 0.72, 0.5, 0.4)
			quad.size = Vector2(0.3, 0.3)
			p.amount = 34
			p.direction = Vector3(1, -0.1, 0.2)
			p.gravity = Vector3(0.4, -0.05, 0)
			p.position = Vector3(-3.0, 1.0, 0)
			p.emission_box_extents = Vector3(5.0, 0.9, 4.6)
			p.initial_velocity_min = 0.9
			p.initial_velocity_max = 1.7
		"spray":
			col = Color(0.85, 0.97, 1.0, 0.7)
			quad.size = Vector2(0.07, 0.07)
			p.amount = 60
			p.direction = Vector3(0, 1, 0)
			p.gravity = Vector3(0, 0.25, 0)
			p.position = Vector3(0, 0.1, 0)
			p.emission_box_extents = Vector3(7.0, 0.05, 4.6)
			p.initial_velocity_min = 0.2
			p.initial_velocity_max = 0.55
			p.lifetime = 3.2
		"embers":
			col = Color(1.0, 0.55, 0.12, 0.95)
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			quad.size = Vector2(0.055, 0.055)
			p.amount = 80
			p.direction = Vector3(0, 1, 0)
			p.gravity = Vector3(0.1, 0.5, 0)
			p.position = Vector3(0, 0.1, 0)
			p.emission_box_extents = Vector3(7.0, 0.05, 4.6)
			p.initial_velocity_min = 0.4
			p.initial_velocity_max = 1.0
			p.lifetime = 3.5
		"motes_dark", "motes_light", "sparks":
			col = Color(glow, 0.85)
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			quad.size = Vector2(0.06, 0.06) if kind != "sparks" else Vector2(0.04, 0.04)
			p.amount = 60 if kind != "sparks" else 90
			p.direction = Vector3(0, 1, 0)
			p.gravity = Vector3(0, 0.12, 0)
			p.position = Vector3(0, 0.15, 0)
			p.emission_box_extents = Vector3(7.0, 0.1, 4.6)
			p.initial_velocity_min = 0.15
			p.initial_velocity_max = 0.5 if kind != "sparks" else 1.4
			p.lifetime = 4.0 if kind != "sparks" else 1.6
		"wind":
			col = Color(1, 1, 1, 0.35)
			quad.size = Vector2(0.7, 0.025)
			m.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
			p.amount = 26
			p.direction = Vector3(1, 0, 0)
			p.spread = 2.0
			p.gravity = Vector3.ZERO
			p.position = Vector3(-7.0, 1.3, 0)
			p.emission_box_extents = Vector3(0.5, 1.0, 4.6)
			p.initial_velocity_min = 5.0
			p.initial_velocity_max = 8.0
			p.lifetime = 2.4
	if not (kind in ["leaves", "petals", "wind"]):
		# Soft round specks, not squares.
		var rg := Gradient.new()
		rg.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		rg.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0)])
		var rt := GradientTexture2D.new()
		rt.gradient = rg
		rt.fill = GradientTexture2D.FILL_RADIAL
		rt.fill_from = Vector2(0.5, 0.5)
		rt.fill_to = Vector2(1.0, 0.5)
		rt.width = 32
		rt.height = 32
		m.albedo_texture = rt
		quad.size *= 1.5
	# Each one fades in and out instead of popping.
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.15, 0.8, 1.0])
	g.colors = PackedColorArray([Color(col, 0.0), col, col, Color(col, 0.0)])
	p.color_ramp = g
	quad.material = m
	p.mesh = quad
	_field_nodes.add_child(p)


var arena: DuelArena = null


## The place answers what happens on the field: the stands get up, cameras flash, the lights
## jump in the color of the moment and swing to where it happened. (No arena on the highway.)
func house(strength: float, color := Color.WHITE, at := Vector3.ZERO, hold := 0.0) -> void:
	if Settings.anim_speed > 4.0:
		return
	if arena != null:
		arena.react(strength, color, at, hold)
	elif track != null:
		track.react(strength, color)


var _crowd_shot_at := -100.0


## A glance at the people watching, up on their feet after a big hit, then back to the table.
## False when nobody is watching here, or when they were shown a moment ago (then the caller
## simply goes back to the table).
func crowd_shot(hold := 1.2) -> bool:
	var testing := "--crowd-shot" in OS.get_cmdline_user_args()
	if arena == null or ((not Settings.crowd_cam or Settings.anim_speed > 2.0 or _time - _crowd_shot_at < 30.0) and not testing):
		return false
	var v: Array = arena.crowd_view()
	if v.is_empty():
		return false
	_crowd_shot_at = _time
	var from: Vector3 = v[0]
	var at: Vector3 = v[1]
	cam_cut(from, at)
	cam_drift(from + (from - at).normalized() * 0.9, Settings.t(hold) + 0.4)
	var mine := _cam_tween
	get_tree().create_timer(Settings.t(hold)).timeout.connect(func():
		# Only if the camera is still on them: another shot may have taken over since.
		if _cam_tween == mine:
			cam_release(0.5))
	return true


func _build_arena() -> void:
	arena = DuelArena.new()
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
	_zone_mats.append(m)
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
	_gy_ready = _extra_ready.duplicate() as Label3D
	_gy_ready.text = Loc.t("EFFECT READY")
	_gy_ready.modulate = Color("4fd18b")
	_gy_ready.position = gy_pos(0) + Vector3(-0.35, 0.75, 0.2)
	_gy_ready.visible = false
	add_child(_gy_ready)
	_gy_ring = _extra_ring.duplicate() as MeshInstance3D
	var gm := (_extra_ring.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
	gm.albedo_color = Color("4fd18b")
	_gy_ring.material_override = gm
	_gy_ring.position = gy_pos(0) + Vector3(0, 0.02, 0)
	_gy_ring.visible = false
	add_child(_gy_ring)


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


## (0.79.1) How many cards in your Graveyard or banished pile can use an effect right now: a green
## ring and "EFFECT READY" over your Graveyard, like the Extra Deck's "SUMMON READY".
func set_gy_ready(ready: int) -> void:
	if _gy_ready == null:
		return
	_gy_ready.visible = ready > 0
	_gy_ring.visible = ready > 0
	_gy_ready.text = Loc.t("EFFECT READY") if ready == 1 else Loc.t("EFFECT READY  x%d") % ready


func _process_extra(t: float) -> void:
	if _extra_ring and _extra_ring.visible:
		var k := 1.0 + sin(t * 4.0) * 0.06
		_extra_ring.scale = Vector3(k, 0.3, 1.25 * k)
		_extra_ready.position.y = extra_pos(0).y + 0.75 + sin(t * 3.0) * 0.05
	if _gy_ring and _gy_ring.visible:
		var g := 1.0 + sin(t * 4.0 + 1.0) * 0.06
		_gy_ring.scale = Vector3(g, 0.3, 1.25 * g)
		_gy_ready.position.y = gy_pos(0).y + 0.75 + sin(t * 3.0 + 1.0) * 0.05


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
	var old = _cards.get(inst.uid)
	if old != null and is_instance_valid(old):
		old.queue_free()   # (a card moving between zones, like a Trap that becomes a monster, leaves no copy behind)
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


# ------------------------------------------------------------------ choosing cards on the field

var _pick_marks := {}    # card uid -> the marker floating over it
var _pick_dimmed := false


## The player has to tap some of these cards: each one gets a bouncing arrow with `word` over
## it, the ones already chosen turn green, and everything else on the field steps back.
func show_picks(cands: Array, chosen: Array, word := "TAP", done_word := "CHOSEN") -> void:
	var keep := {}
	for inst in cands:
		var c := card_for(inst)
		if c == null:
			continue
		keep[inst.uid] = true
		var mk: Node3D = _pick_marks.get(inst.uid)
		if mk == null or not is_instance_valid(mk):
			mk = _pick_marker()
			add_child(mk)
			_pick_marks[inst.uid] = mk
		var picked := chosen.has(inst)
		var col := Color("5df07a") if picked else UITheme.GOLD
		var tall: bool = holo_for(inst) != null
		mk.position = c.global_position + Vector3(0, 1.62 if tall else 0.62, 0)
		mk.set_meta("base_y", mk.position.y)
		mk.set_meta("picked", picked)
		var l: Label3D = mk.get_node("word")
		l.text = Loc.t(done_word if picked else word)
		l.modulate = col
		((mk.get_node("arrow") as MeshInstance3D).material_override as StandardMaterial3D).albedo_color = col
	for uid in _pick_marks.keys():
		if not keep.has(uid):
			if is_instance_valid(_pick_marks[uid]):
				_pick_marks[uid].queue_free()
			_pick_marks.erase(uid)
	_pick_dimmed = true
	for uid in _cards:
		var c2: Card3D = _cards[uid]
		if is_instance_valid(c2):
			c2.set_dim(not keep.has(uid))
	for uid in _holos:
		if is_instance_valid(_holos[uid]):
			(_holos[uid] as MonsterHolo).set_shade(1.0 if keep.has(uid) else 0.4)


func clear_picks() -> void:
	for uid in _pick_marks:
		if is_instance_valid(_pick_marks[uid]):
			_pick_marks[uid].queue_free()
	_pick_marks.clear()
	if not _pick_dimmed:
		return
	_pick_dimmed = false
	for uid in _cards:
		if is_instance_valid(_cards[uid]):
			(_cards[uid] as Card3D).set_dim(false)
	for uid in _holos:
		if is_instance_valid(_holos[uid]):
			(_holos[uid] as MonsterHolo).set_shade(1.0)


func _pick_marker() -> Node3D:
	var n := Node3D.new()
	var arrow := MeshInstance3D.new()
	arrow.name = "arrow"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.19
	cone.bottom_radius = 0.0
	cone.height = 0.3
	cone.radial_segments = 4
	arrow.mesh = cone
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.no_depth_test = true
	m.render_priority = 6
	m.albedo_color = UITheme.GOLD
	arrow.material_override = m
	arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(arrow)
	var l := Label3D.new()
	l.name = "word"
	l.font = Comic.button_font()
	l.font_size = 64
	l.pixel_size = 0.0034
	l.outline_size = 18
	l.outline_modulate = Color(0.03, 0.04, 0.09, 0.95)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 7
	l.outline_render_priority = 6
	l.position.y = 0.4
	n.add_child(l)
	return n


func _process_picks(t: float) -> void:
	for uid in _pick_marks:
		var mk: Node3D = _pick_marks[uid]
		if not is_instance_valid(mk):
			continue
		var by: float = mk.get_meta("base_y", mk.position.y)
		var picked: bool = mk.get_meta("picked", false)
		mk.position.y = by + (0.0 if picked else absf(sin(t * 4.2)) * 0.16)
		(mk.get_node("arrow") as Node3D).rotation.y = t * 2.4


var cam_home := CAM_POS
var cam_home_target := CAM_TARGET
var deal_fast := false
var _holos := {}      # card uid -> MonsterHolo
var ace_ids := {}     # card ids of the two duelists' ace monsters (their holograms get the ace idle)


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
			var had = _holos.get(m.uid)
			var h: MonsterHolo = had if had != null and is_instance_valid(had) else null
			if h == null:
				h = MonsterHolo.new()
				add_child(h)
				h.setup(m, c, ATTR_COLORS.get(str(m.data.get("attribute", "")), UITheme.ACCENT), Settings.t(0.75), ace_ids.has(int(m.id)))
				_holos[m.uid] = h
			h.card = c
			h.set_defense(not m.attack_pos)
			if "overlays" in m and (m.overlays.size() > 0 or _orbits.has(m.uid)):
				set_overlays(m)
	for uid in _holos.keys():
		if not seen.has(uid):
			var h2 = _holos[uid]
			if h2 != null and is_instance_valid(h2):
				(h2 as MonsterHolo).shatter()
			_holos.erase(uid)


## The hologram standing over a card, if there is one.
func holo_for(inst) -> MonsterHolo:
	if inst == null:
		return null
	var h = _holos.get(inst.uid)
	return (h as MonsterHolo) if h != null and is_instance_valid(h) else null


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


## Where the card you are playing is on the screen (in your hand, or where you let go of it).
## The duel sets it just before the card is played, so the card on the table starts its flight
## from that very spot instead of from the middle of the screen.
var fly_from := Vector2(-1, -1)
var fly_at := 0

func _hand_xform() -> Transform3D:
	if fly_from.x < 0.0 or Time.get_ticks_msec() - fly_at > 600:
		return _near_camera_xform()
	var sp := fly_from
	fly_from = Vector2(-1, -1)
	# (at this depth the card is as big as it is in your hand)
	return Transform3D(camera.global_transform.basis, camera.project_position(sp, 5.2))


## A straight, accelerating move: the way a card is slammed down or an attacker lunges.
func _dash(c: Card3D, to: Transform3D, dur: float) -> void:
	var from := c.transform
	var q0 := from.basis.get_rotation_quaternion()
	var q1 := to.basis.get_rotation_quaternion()
	var tw := create_tween()
	tw.tween_method(func(t: float):
		var e := t * t * t
		c.transform = Transform3D(Basis(q0.slerp(q1, minf(1.0, t * 1.6))), from.origin.lerp(to.origin, e)), 0.0, 1.0, Settings.t(dur))
	await tw.finished


## The little bounce of a card that just landed.
func _land(c: Card3D, amount := 0.14) -> void:
	c.scale = Vector3.ONE * (1.0 + amount)
	var tw := create_tween()
	tw.tween_property(c, "scale", Vector3.ONE, Settings.t(0.22)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


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
		# (a line of light follows the card off the Deck)
		var trail := DuelFx.orb(self, c.position, Color("9fd8ff"), 0.22)
		var ttw := create_tween()
		ttw.tween_method(func(_t: float):
			if is_instance_valid(trail) and is_instance_valid(c):
				trail.position = c.position, 0.0, 1.0, Settings.t(0.3))
		ttw.tween_callback(trail.queue_free)
		DuelFx.ring(self, deck_pos(p), Color("9fd8ff"), 0.2, 0.75, 0.35, 0.05)
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
		c.transform = _hand_xform()
	else:
		c = _take_from_opp_hand(inst)
	c.set_pickable(true)
	var to := Transform3D(table_basis(p, not set_card, not set_card), monster_zone_pos(p, zone) + Vector3(0, 0.02, 0))
	duelist_look(to.origin)
	var col: Color = Comic.SKY if p == 0 else Color("ff8a98")
	if set_card:
		# Set: its zone draws a quiet outline, the card glides in low and is laid face-down in it.
		var violet := Color("9d7bff")
		DuelFx.rect(self, to.origin, violet, 1.5, 1.0, 0.36, true, 1.5)
		await _move(c, Transform3D(to.basis, to.origin + Vector3(0, 0.5, 0)), 0.3, 0.45)
		if not _orbs.is_empty():
			await _consume_orbs(to.origin)
		await _move(c, to, 0.16, 0.0)
		_land(c, 0.07)
		DuelFx.rect(self, to.origin, violet, 1.0, 1.4, 0.45, true, 2.2, 0.6)
		DuelFx.sparks(self, to.origin + Vector3(0, 0.04, 0), Color("c9b8ff"), 10, 1.7, 0.0, 0.5, -0.5, 0.04)
		Sfx.play("set", -6.0)
		shake(0.08)
		return
	# Summon: the zone locks on, the card comes over it and shows itself for a beat, then it is
	# slammed down and the zone answers with light.
	DuelFx.rect(self, to.origin, col, 1.8, 1.0, 0.4, false, 1.6)
	var hover := Transform3D(to.basis * Basis(Vector3.RIGHT, 0.35), to.origin + Vector3(0, 1.25, 0.25 if p == 0 else -0.25))
	await _move(c, hover, 0.28, 0.4)
	if not _orbs.is_empty():
		await _consume_orbs(to.origin)
	create_tween().tween_method(c.flash, 1.4, 0.2, Settings.t(0.14))
	await _wait(0.08)
	await _dash(c, to, 0.11)
	_land(c)
	slam(to.origin, col, 1.0)
	create_tween().tween_method(c.flash, 1.8, 0.0, Settings.t(0.45))
	await hologram(inst, to.origin)


## A card hits the table hard: the outline of the card flashes outward, a ring runs over the
## floor, light is thrown along it and the table shakes. `k` is how hard (1 = a Normal Summon).
func slam(at: Vector3, col: Color, k := 1.0, sideways := false) -> void:
	DuelFx.rect(self, at, Color.WHITE.lerp(col, 0.35), 1.0, 1.5 + 0.5 * k, 0.4 + 0.1 * k, sideways, 3.0, 1.0)
	DuelFx.ring(self, at, col, 0.35, 1.3 + 0.9 * k, 0.5 + 0.1 * k, 0.05)
	DuelFx.rays(self, at, col.lightened(0.25), 1.5 + 0.9 * k, 0.4, int(20 + 10 * k))
	DuelFx.glow(self, at + Vector3(0, 0.25, 0), col.lightened(0.5), 1.6 + 1.2 * k, 0.35, 0.6 * k, 2.6)
	DuelFx.sparks(self, at + Vector3(0, 0.06, 0), col.lightened(0.3), int(14 + 16 * k), 3.2 + 1.5 * k, 0.12, 0.6, -3.0)
	Sfx.play("land", -5.0, 1.0 - 0.12 * (k - 1.0))
	shake(0.3 * k)
	cam_punch(1.6 * k)
	house(clampf(0.15 * k, 0.1, 0.6), col, at)


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
		_ring_fx(at + Vector3(0, 0.05, 0), col, 1.4, 0.0, 0.0)
		_ring_fx(at + Vector3(0, 0.05, 0), col, 2.2, 0.15, 0.0)
		_flash(at + Vector3(0, h * 0.5, 0), col)
		# (0.58.0) The camera drops almost to the floor on one side and looks up at it...
		var swing := -1.0 if at.x > 0.0 else 1.0
		cam_shot(at + Vector3(2.6 * swing, 0.45, 5.1), at + Vector3(0, h * 0.56, 0), 0.42)
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "scale", Vector3.ONE, Settings.t(0.45 if big else 0.35))
	tw.tween_property(spr, "modulate:a", 0.97, Settings.t(0.25))
	tw.tween_property(glow, "modulate:a", 0.35, Settings.t(0.4))
	await tw.finished
	if big:
		shake(0.45)
		cam_punch(3.0, 0.03 * (-1.0 if at.x > 0.0 else 1.0))
		# ...then swings slowly round in front of it while it stands there.
		var swing2 := -1.0 if at.x > 0.0 else 1.0
		cam_drift(at + Vector3(-1.5 * swing2, 0.8, 5.5), Settings.t(1.9))
		Sfx.play("impact")
		# (The monster is seen standing there for a moment before its name crosses the screen.)
		get_tree().create_timer(Settings.t(0.4)).timeout.connect(func(): ace_summoned.emit(inst))
	# Idle: a gentle float while it is on screen.
	var float_tw := create_tween().set_loops(2).set_trans(Tween.TRANS_SINE)
	float_tw.tween_property(spr, "position:y", spr.position.y + 0.12, Settings.t(0.4))
	float_tw.tween_property(spr, "position:y", spr.position.y, Settings.t(0.4))
	await _wait(1.95 if big else 0.55)
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
	# (a ring of light spreading over the floor; drawn by DuelFx since 0.57.0)
	DuelFx.ring(self, at + Vector3(0, 0.02, 0), color, 0.2 * size, 1.1 * size, 0.5, 0.055)


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
			c.transform = _hand_xform()
		else:
			c = _take_from_opp_hand(inst)
	if c == null:
		return
	c.set_pickable(false)
	c.set_glow(true, Color.WHITE)
	var to := Transform3D(Basis(Vector3.RIGHT, -0.4) * Basis(Vector3.UP, randf_range(-0.6, 0.6)), center + Vector3(randf_range(-0.9, 0.9), 1.6, randf_range(-0.3, 0.3)))
	await _move(c, to, 0.32, 0.4)


# ---- the chain (see ChainFx)

var chain_fx: ChainFx


## Where a card that goes on the chain is, as far as the table can show it.
func chain_spot(inst, p: int) -> Vector3:
	var c := card_for(inst) if inst != null else null
	if c != null and not is_instance_valid(c):
		c = null
	if c != null and _opp_hand.has(c):
		return Vector3(c.position.x * 0.8, 0.2, -3.0)
	if c != null and is_instance_valid(c):
		# (on the table, not where a card held up to be read happens to be)
		return Vector3(c.position.x, 0.03, c.position.z - (0.3 if c.position.y > 0.6 else 0.0))
	if inst != null and state_ref != null:
		var ps = state_ref.players[int(inst.owner)]
		if ps.gy.has(inst):
			return gy_pos(int(inst.owner)) + Vector3(0, 0.1, 0)
		if ps.banished.has(inst):
			return banish_pos(int(inst.owner)) + Vector3(0, 0.1, 0)
	return Vector3(0, 0.25, 3.2 if p == 0 else -3.0)


func chain_link(n: int, p: int, inst) -> void:
	if chain_fx == null:
		chain_fx = ChainFx.new(self)
		add_child(chain_fx)
	chain_fx.link(n, p, inst, chain_spot(inst, p))


func special_center(p: int, zone: int) -> Vector3:
	return monster_zone_pos(p, zone)


## A Special Summon. The Extra Deck and Ritual Summons get their set piece with the real
## materials (SummonFx); a monster back from the Graveyard rises out of it; anything else comes
## from where it was (hand, Deck, Extra Deck, banished). `origin` is the engine's location.
func anim_special(p: int, inst, zone: int, method: String, materials: Array, origin := 0) -> void:
	duelist_look(monster_zone_pos(p, zone), 2.2)
	var col: Color = METHOD_COLORS.get(method, UITheme.ACCENT)
	var from_gy := method == "reborn"
	var at := monster_zone_pos(p, zone) + Vector3(0, 0.02, 0)
	var core := at + Vector3(0, 1.6, 0)
	var grand: bool = method in ["fusion", "synchro", "xyz", "ritual"]
	var attack: bool = true if not ("attack_pos" in inst) else bool(inst.attack_pos)
	var to := Transform3D(table_basis(p, true, attack), at)
	if grand:
		# The camera drops low and looks up at the summon while the field goes dark.
		var side := 1.0 if at.x <= 0.0 else -1.0
		if method == "fusion":
			# (the whirl hangs in the air: seen from low down)
			cam_shot(at + Vector3(2.6 * side, 1.5, 4.6 if p == 0 else 5.4), core + Vector3(0, 0.5, 0), 0.5)
		else:
			# (rings, a galaxy, a magic circle: seen from above, at an angle, so the floor shows)
			cam_shot(at + Vector3(2.3 * side, 4.4, 4.7 if p == 0 else 5.5), at + Vector3(0, 1.15, 0), 0.5)
		_dim_field(2.3)
		house(0.6, col, at, 1.2)
		var flying: Array = materials.filter(func(m): return card_for(m) != null)
		await SummonFx.play(self, method, at, core, flying)
	for m in materials:
		var mc := card_for(m)
		if mc:
			_cards.erase(m.uid)
			mc.queue_free()
		if method != "xyz":
			_add_to_gy(m)
	var c: Card3D
	if grand:
		c = _new_card(inst)
		match method:
			"xyz":
				# It rises out of the galaxy, turning, and settles on its zone.
				c.transform = Transform3D(to.basis, at + Vector3(0, 0.05, 0))
				c.scale = Vector3.ONE * 0.25
				var up := create_tween().set_parallel()
				up.tween_property(c, "position:y", at.y + 1.25, Settings.t(0.34)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				up.tween_property(c, "scale", Vector3.ONE, Settings.t(0.3)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				up.tween_property(c, "rotation:y", c.rotation.y + TAU, Settings.t(0.34)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				up.tween_method(c.flash, 3.0, 0.4, Settings.t(0.34))
				await up.finished
				c.transform = Transform3D(to.basis, at + Vector3(0, 1.25, 0))
				await _wait(0.06)
				await _dash(c, to, 0.12)
			"ritual":
				# It comes down inside the pillar of light.
				c.transform = Transform3D(to.basis, at + Vector3(0, 4.2, 0))
				c.flash(2.5)
				var down := create_tween().set_parallel()
				down.tween_property(c, "position:y", at.y, Settings.t(0.42)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				down.tween_method(c.flash, 2.5, 0.6, Settings.t(0.42))
				await down.finished
				c.transform = to
			_:
				# It takes shape in the light, hangs there for a beat, and is slammed down.
				c.transform = Transform3D(to.basis * Basis(Vector3.RIGHT, 0.3), core)
				c.scale = Vector3.ONE * 0.1
				c.flash(3.0)
				var grow := create_tween().set_parallel()
				grow.tween_property(c, "scale", Vector3.ONE * 1.15, Settings.t(0.22)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				grow.tween_method(c.flash, 3.0, 0.5, Settings.t(0.3))
				await grow.finished
				await _wait(0.1)
				c.scale = Vector3.ONE
				await _dash(c, to, 0.12)
		_land(c, 0.18)
		slam(at, col, 1.8, not attack)
		create_tween().tween_method(c.flash, 2.2, 0.0, Settings.t(0.5))
		if method == "xyz":
			set_overlays(inst)
	else:
		# From where it was: the Graveyard, the hand, a Deck, the banished pile.
		var start := Transform3D(to.basis * Basis(Vector3.RIGHT, 0.3), core)
		var gold := Color("ffe9a8")
		if from_gy:
			var gp := gy_pos(int(inst.owner)) + Vector3(0, 0.12, 0)
			remove_from_gy(inst)
			start = Transform3D(table_basis(int(inst.owner), true, true), gp)
			DuelFx.pillar(self, gp, gold, 0.42, 4.0, 0.75, 0.0, 2.4)
			DuelFx.glyph(self, gp, gold, 0.7, 0.8, {"rings": 1, "ticks": 24, "star": 0, "turn": 1.2})
			DuelFx.sparks(self, gp, gold, 20, 2.6, 0.9, 0.8, 1.0)
		elif origin == OcgCore.LOC_HAND:
			if p == 0:
				c = _new_card(inst)
				c.transform = _hand_xform()
			else:
				c = _take_from_opp_hand(inst)
		elif origin == OcgCore.LOC_DECK:
			start = Transform3D(table_basis(p, false, true), deck_pos(p) + Vector3(0, 0.4, 0))
		elif origin == OcgCore.LOC_EXTRA:
			start = Transform3D(table_basis(p, false, true), extra_pos(p) + Vector3(0, 0.4, 0))
		elif origin == OcgCore.LOC_REMOVED:
			remove_from_banished(inst)
			start = Transform3D(table_basis(p, true, true), banish_pos(int(inst.owner)) + Vector3(0, 0.3, 0))
			_rift(start.origin + Vector3(0, 0.4, 0))
		if c == null:
			c = _new_card(inst)
			c.transform = start
			if origin == 0 and not from_gy:
				# (made out of nothing: a Token)
				c.scale = Vector3.ONE * 0.1
				create_tween().tween_property(c, "scale", Vector3.ONE, Settings.t(0.22)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				DuelFx.glow(self, core, col, 2.0, 0.4, 0.6)
		c.set_pickable(true)
		var lit: Color = gold if from_gy else col
		DuelFx.glyph(self, at, lit, 0.85, 0.75, {"rings": 1, "ticks": 28, "star": 0, "turn": 1.4})
		var orb := DuelFx.orb(self, c.position, lit, 0.3)
		var hover := Transform3D(to.basis * Basis(Vector3.RIGHT, 0.35), at + Vector3(0, 1.25, 0.25 if p == 0 else -0.25))
		var ot := create_tween()
		ot.tween_property(orb, "position", hover.origin, Settings.t(0.34))
		ot.tween_callback(orb.queue_free)
		orb.trail = from_gy or origin != OcgCore.LOC_HAND
		orb.visible = orb.trail
		await _move(c, hover, 0.34, 0.9 if from_gy else 0.5)
		await _wait(0.06)
		await _dash(c, to, 0.11)
		_land(c)
		slam(at, lit, 1.25, not attack)
		create_tween().tween_method(c.flash, 2.0, 0.0, Settings.t(0.45))
	await hologram(inst, at, grand)
	if grand:
		cam_release(0.6)


var _orbits := {}    # Xyz Monster uid -> the lights of its materials


## The Xyz Materials of a monster circle its card as lights, one for each.
func set_overlays(inst) -> void:
	var c := card_for(inst)
	if c == null:
		return
	var n: int = inst.overlays.size() if "overlays" in inst else 0
	# (untyped on purpose: lights that freed themselves with their card are still in the list,
	# and a freed object cannot be put in a typed variable)
	var had = _orbits.get(inst.uid)
	var o: FxOrbit = had if had != null and is_instance_valid(had) else null
	if o == null:
		if n == 0:
			_orbits.erase(inst.uid)
			return
		o = FxOrbit.new()
		add_child(o)
		_orbits[inst.uid] = o
	o.card = c
	o.set_count(n)


func _ring_fx(at: Vector3, color: Color, size: float, delay: float, rise: float) -> void:
	# A ring that lights, lifts by `rise`, then widens and fades.
	var m := DuelFx._mat("glyph", DuelFx.HEAD + DuelFx.GLYPH, {"color": color, "energy": 2.4, "alpha": 0.0, "radius": 0.86, "width": 0.035, "soft": 0.07, "spin": 0.0})
	var mi := DuelFx._piece(self, DuelFx._quad(0.6 * size * 2.33, true), m, at)
	var tw := create_tween()
	tw.tween_interval(Settings.t(delay))
	tw.tween_property(m, "shader_parameter/alpha", 1.0, Settings.t(0.12))
	tw.parallel().tween_property(mi, "position:y", at.y + rise, Settings.t(0.6))
	tw.tween_property(m, "shader_parameter/alpha", 0.0, Settings.t(0.35))
	tw.parallel().tween_property(mi, "scale", Vector3(1.8, 1, 1.8), Settings.t(0.35))
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


## Tribute lights that no Summon came to collect (a Tribute paid as a cost) fade out.
func clear_orbs() -> void:
	for o in _orbs:
		if is_instance_valid(o):
			var tw := create_tween()
			tw.tween_property(o, "scale", Vector3(0.01, 0.01, 0.01), Settings.t(0.25))
			tw.tween_callback(o.queue_free)
	_orbs.clear()


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
	_land(c, 0.1)
	slam(to.origin, UITheme.ACCENT, 0.6, not bool(inst.attack_pos))


func anim_position(p: int, inst, zone: int) -> void:
	var c := card_for(inst)
	if c == null:
		return
	var to := Transform3D(table_basis(p, inst.face_up, inst.attack_pos), monster_zone_pos(p, zone) + Vector3(0, 0.02, 0))
	await _move(c, to, 0.3, 0.25)
	DuelFx.rect(self, to.origin, Color("9fd8ff"), 1.0, 1.3, 0.35, not bool(inst.attack_pos), 1.8)


func anim_activate(p: int, inst, zone := 2) -> void:
	var c: Card3D
	if p == 0:
		c = _new_card(inst)
		c.transform = _hand_xform()
	else:
		c = _take_from_opp_hand(inst)
	c.set_pickable(true)
	var to := Transform3D(table_basis(p, true, true), st_pos(p, zone if zone >= 0 else 2) + Vector3(0, 0.02, 0))
	var teal := Color("2de2a0")
	# Its zone lights, the card comes down on it face-up, and a circle of light opens under it.
	DuelFx.rect(self, to.origin, teal, 1.7, 1.0, 0.36, false, 1.6)
	await _move(c, Transform3D(to.basis, to.origin + Vector3(0, 0.8, 0)), 0.32, 0.3)
	c.set_glow(true, teal)
	var tw := create_tween()
	tw.tween_method(c.flash, 2.5, 0.0, Settings.t(0.55))
	await _dash(c, to, 0.12)
	_land(c, 0.1)
	DuelFx.rect(self, to.origin, Color.WHITE.lerp(teal, 0.5), 1.0, 1.7, 0.45, false, 2.8, 0.9)
	DuelFx.glyph(self, to.origin, teal, 0.95, 0.85, {"rings": 1, "ticks": 30, "star": 0, "turn": 2.0, "energy": 2.6})
	DuelFx.pillar(self, to.origin, teal.lightened(0.3), 0.36, 2.6, 0.6, 0.0, 1.8)
	DuelFx.sparks(self, to.origin + Vector3(0, 0.1, 0), teal.lightened(0.3), 18, 2.4, 0.85, 0.7, 0.5, 0.04)
	shake(0.14)
	await _wait(0.4)
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
		c.transform = _hand_xform()
	else:
		c = _take_from_opp_hand(inst)
	c.set_pickable(true)
	var to := Transform3D(table_basis(p, false, true), spell_zone_pos(p, zone) + Vector3(0, 0.02, 0))
	var violet := Color("b98cff")
	DuelFx.rect(self, to.origin, violet, 1.5, 1.0, 0.34, false, 1.4)
	await _move(c, Transform3D(to.basis, to.origin + Vector3(0, 0.4, 0)), 0.28, 0.4)
	await _move(c, to, 0.13, 0.0)
	_land(c, 0.07)
	DuelFx.rect(self, to.origin, violet, 1.0, 1.4, 0.42, false, 2.2, 0.6)
	DuelFx.sparks(self, to.origin + Vector3(0, 0.04, 0), Color("d8c8ff"), 8, 1.5, 0.0, 0.45, -0.5, 0.04)
	Sfx.play("set", -8.0)
	shake(0.06)


## A set trap flips up with a flash.
func anim_trap(p: int, inst, zone: int) -> void:
	var c := card_for(inst)
	if c == null:
		return
	duelist_look(c.position, 1.8)
	# The card lifts and shows its face to you, whoever flipped it.
	var up := Transform3D(Basis(Vector3.RIGHT, -0.6 if p == 0 else -0.25), st_pos(p, zone) + Vector3(0, 1.2 if p == 0 else 1.5, 0.3))
	c.set_glow(true, Color("ff4dd2"))
	await _move(c, up, 0.3, 0.2)
	var pink := Color("ff4dd2")
	_flash(up.origin, pink)
	# It springs open: light bursts from behind the card and its zone flares under it.
	DuelFx.rays(self, up.origin + Vector3(0, 0, -0.05), pink, 1.9, 0.45, 26, false, 2.8)
	DuelFx.glow(self, up.origin, pink.lightened(0.4), 2.6, 0.4, 0.8, 2.6)
	var zp := st_pos(p, zone)
	DuelFx.rect(self, zp, pink, 1.0, 1.8, 0.5, false, 2.6, 0.8)
	DuelFx.ring(self, zp, pink, 0.3, 1.5, 0.5, 0.05)
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


## Where a duelist's hand is, for lights that fly to it or out of it.
func hand_pos(p: int) -> Vector3:
	return Vector3(0, 0.9, 4.3) if p == 0 else Vector3(0, 1.0, -3.75)


## What is left of a card flies somewhere as a light with a trail: to the Graveyard, the
## banished pile, the hand, the Deck. It arcs over the table and lands with a small ring.
## Not awaited: it is over in `dur` seconds on its own.
func soul(from: Vector3, to: Vector3, color: Color, dur := 0.32, size := 0.3) -> void:
	var o := DuelFx.orb(self, from, color, size)
	var mid := (from + to) * 0.5 + Vector3(0, 0.9 + from.distance_to(to) * 0.12, 0)
	var tw := create_tween()
	tw.tween_method(func(t: float):
		if is_instance_valid(o):
			o.position = from.lerp(mid, t).lerp(mid.lerp(to, t), t), 0.0, 1.0, Settings.t(dur)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		if is_instance_valid(o):
			o.queue_free()
		DuelFx.glow(self, to, color, size * 3.0, 0.3, 0.4)
		if to.y < 0.6:
			DuelFx.ring(self, Vector3(to.x, 0.03, to.z), color, 0.15, 0.6, 0.35, 0.05))


## The card just put on a pile (Graveyard or banished) stays unseen until the light carrying it gets there.
func _pile_arrives(inst, delay: float) -> void:
	for piles in [_gy_cards, _ban_cards]:
		for pile in piles:
			for gc in pile:
				if is_instance_valid(gc) and gc.inst == inst:
					(gc as Card3D).set_alpha(0.0)
					var tw := (gc as Card3D).create_tween()
					tw.tween_interval(Settings.t(delay))
					tw.tween_method((gc as Card3D).set_alpha, 0.0, 1.0, Settings.t(0.12))
					return


## A card on the field goes back to the hand (or Extra Deck): a gust lifts it off the table
## and it is gone, a light flying back to its owner's hand.
func anim_bounce(inst) -> void:
	var c := card_for(inst)
	if c == null:
		return
	var wind := Color("9fd0ff")
	c.set_glow(true, wind)
	var at := c.position
	DuelFx.spiral(self, at + Vector3(0, 0.5, 0), Color.WHITE, wind, 0.95, 0.55, {"flat": false, "arms": 3, "twist": 3.0, "speed": 9.0, "energy": 2.0, "open": 0.18})
	DuelFx.ring(self, Vector3(at.x, 0.03, at.z), wind, 0.3, 1.1, 0.4, 0.05)
	Sfx.play("whoosh", -6.0, 1.5)
	var tw := create_tween().set_parallel()
	tw.tween_property(c, "position:y", c.position.y + 1.1, Settings.t(0.26)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(c, "rotation:y", c.rotation.y + PI * 1.5, Settings.t(0.26)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(c, "scale", Vector3.ONE * 0.4, Settings.t(0.26)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_method(c.set_alpha, 1.0, 0.0, Settings.t(0.26))
	await tw.finished
	var to_extra: bool = inst.has_method("frame") and inst.frame() in ["fusion", "synchro", "xyz"]
	soul(at + Vector3(0, 1.1, 0), extra_pos(int(inst.owner)) + Vector3(0, 0.2, 0) if to_extra else hand_pos(int(inst.owner)), wind, 0.28)
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
		c.transform = _hand_xform()
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
	var floor_at := Vector3(at.x, 0.03, at.z)
	var sideways: bool = "attack_pos" in inst and not bool(inst.attack_pos)
	DuelFx.rect(self, floor_at, color, 1.0, 1.7, 0.5, sideways, 2.6, 0.7)
	DuelFx.glyph(self, floor_at, color, 0.95, 0.9, {"rings": 1, "ticks": 28, "star": 0, "turn": 2.2, "energy": 2.4})
	DuelFx.pillar(self, Vector3(at.x, 0.0, at.z), color, 0.42, 2.8, 0.7, 0.0, 1.7)
	DuelFx.sparks(self, at + Vector3(0, 0.15, 0), color.lightened(0.3), 16, 2.2, 0.9, 0.7, 0.8, 0.04)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 0.0
	light.omni_range = 4.5
	light.position = Vector3(at.x, 0.8, at.z)
	add_child(light)
	var d := Settings.t(1.0)
	var tw := create_tween().set_parallel()
	tw.tween_property(light, "light_energy", 5.0, 0.1 * d)
	tw.tween_property(light, "light_energy", 0.0, 0.5 * d).set_delay(0.12 * d)
	tw.tween_method(c.flash, 3.0, 0.0, 0.7 * d)
	var home := c.position
	tw.tween_property(c, "position:y", home.y + 0.32, 0.14 * d).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "position:y", home.y, 0.3 * d).set_delay(0.4 * d).set_trans(Tween.TRANS_SINE)
	tw.chain().tween_callback(func():
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
	duelist_look(home.origin, 0.6, 1 - p)      # (the one attacked looks at what is coming...)
	duelist_look(goal, 1.8, p)                 # (...and the attacker at what they are sending it into)
	var dir := (goal - home.origin)
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3(0, 0, -1.0 if p == 0 else 1.0)
	# It rises, leans back like a drawn bow, and a ring locks on to what it is about to hit.
	var lean := Basis(dir.cross(Vector3.UP).normalized(), 0.3) * home.basis
	var lift := Transform3D(lean, home.origin + Vector3(0, 0.75, 0) - dir * 0.35)
	_lock_on(goal, target == null)
	# (0.60.0) Beat 1: its element gathers around it.
	var tier := ElementFx.tier_of(inst)
	if not turbo and Settings.anim_speed <= 2.0:
		ElementFx.gather(self, inst, home.origin, tier)
	await _move(c, lift, 0.24, 0.0)
	if tier >= 2 and not turbo and Settings.anim_speed <= 2.0:
		await _wait(0.16)      # (a strong monster holds the pose a beat longer)


## A red ring that closes on the target of an attack.
func _lock_on(at: Vector3, direct: bool) -> void:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.56
	t.outer_radius = 0.63
	t.rings = 40
	t.ring_segments = 6
	mi.mesh = t
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.no_depth_test = true
	m.albedo_color = Color("ff4d5e", 0.0)
	mi.material_override = m
	mi.position = Vector3(at.x, 0.12, at.z)
	var big := 3.4 if direct else 2.6
	var small := 1.5 if direct else 0.95
	mi.scale = Vector3(big, 1, big)
	add_child(mi)
	var tw := create_tween()
	tw.tween_property(m, "albedo_color:a", 0.95, Settings.t(0.08))
	tw.parallel().tween_property(mi, "scale", Vector3(small, 1, small), Settings.t(0.24)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(mi, "rotation:y", 1.6, Settings.t(0.24))
	tw.tween_interval(Settings.t(0.3))
	tw.tween_property(m, "albedo_color:a", 0.0, Settings.t(0.18))
	tw.tween_callback(mi.queue_free)


## How long after anim_battle starts the hit lands, for what has to land with it (the numbers
## of the clash, the speed lines). A strong monster winds up a little longer.
func battle_hit_time(inst) -> float:
	var tier := ElementFx.tier_of(inst)
	return BATTLE_WAIT[tier] + BATTLE_DASH[tier]


const BATTLE_WAIT := [0.26, 0.28, 0.36]
const BATTLE_DASH := [0.15, 0.16, 0.2]


func anim_battle(p: int, inst, target) -> void:
	var c := card_for(inst)
	if c == null:
		return
	var home: Transform3D = c.get_meta("home", c.transform)
	var goal := _attack_goal(p, target)
	var tier := ElementFx.tier_of(inst)
	var shoots := ElementFx.ranged(inst)
	var show := Settings.anim_speed <= 2.0
	_battle_shot(p, home.origin, goal)
	await _wait(BATTLE_WAIT[tier])
	# The lunge: slow off the mark, fastest at the moment it lands. A monster that shoots
	# (a dragon's breath, a spell) throws itself forward a little and lets the element go;
	# one that fights up close goes all the way in.
	var reach := 0.3 if shoots and show else 0.84
	var hit := Transform3D(home.basis, home.origin.lerp(goal, reach) + Vector3(0, 0.25 if not shoots else 0.45, 0))
	# (0.58.0) The camera goes with it: it runs down the field behind the attacker and
	# arrives as the blow lands, leaning into the side the hit comes from.
	_battle_follow(p, home.origin, goal, target == null, tier if show else 0)
	# (0.60.0) Beat 2: its element crosses the field with it.
	if show:
		ElementFx.travel(self, inst, home.origin, goal, tier, BATTLE_DASH[tier])
	await _dash(c, hit, BATTLE_DASH[tier])
	StrikeFx.play(self, inst, home.origin, goal)
	# Beat 3: it lands.
	_impact(goal + Vector3(0, 0.15, 0), ATTR_COLORS.get(ElementFx.attr_of(inst), Color("ff8a5c")))
	if show:
		ElementFx.impact(self, inst, home.origin, goal, tier)
	var lean := 0.035 if goal.x >= home.origin.x else -0.035
	var th := holo_for(target)
	if th:
		th.hit()
	var tc := card_for(target) if target != null else null
	if tc != null:
		_jolt(tc, (goal - home.origin).normalized())
		cam_punch(3.2 + clampf(float(inst.atk()) / 1000.0, 0.0, 4.0) * 0.6, lean)
	else:
		# Nothing in the way: the blow goes all the way to the duelist.
		_burst(Vector3(goal.x, 0.05, goal.z), Color("ff5a6a"), 2.4)
		_flash(goal, Color("ffd0c0"))
		shake(0.5)
		cam_punch(5.5, lean * 1.6)
	await hit_stop(0.1 if target != null else 0.14)
	if target == null and _duelists.has(1 - p) and not turbo:
		# The camera whips round to the duelist who took it.
		duelist_shot(1 - p, 0.2)
		cam_punch(-3.0)
	# A short recoil off the hit, then home.
	await _move(c, Transform3D(home.basis, hit.origin.lerp(home.origin, 0.18) + Vector3(0, 0.3, 0)), 0.1, 0.0)
	await _wait(0.14 + (0.12 * tier if show else 0.0))      # (the bigger the hit, the longer you get to look at it)
	await _move(c, home, 0.3, 0.3)
	if target == null and _duelists.has(1 - p) and not turbo:
		await _wait(0.2)
	cam_release(0.45)
	c.set_glow(false)


signal finisher_hit(at: Vector3, color: Color)


## The last attack of the duel (0.57.0). The attacker gathers itself over a circle of light,
## the clock slows, it crosses the whole field with a trail behind it and lands like a bomb.
## The duel screen answers finisher_hit with the flash and the breaking glass.
func anim_finisher(p: int, inst, target) -> void:
	var c := card_for(inst)
	if c == null:
		return
	var home: Transform3D = c.get_meta("home", c.transform)
	var tc := card_for(target) if target != null else null
	var toward := -1.0 if p == 0 else 1.0
	var goal: Vector3 = tc.position if tc != null else Vector3(0, 0.9, toward * 5.4)
	var floor_at := Vector3(goal.x, 0.02, goal.z)
	var col: Color = ATTR_COLORS.get(str(inst.data.get("attribute", "")), Color("ffd27a"))
	var slow_ok := absf(Engine.time_scale - 1.0) < 0.01 and Settings.anim_speed <= 2.0
	var dir := goal - home.origin
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3(0, 0, toward)
	# The wind-up: low behind the attacker, looking down the field at what it is about to hit.
	var sx := 1.0 if home.origin.x <= 0.0 else -1.0
	cam_shot(home.origin + Vector3(1.7 * sx, 1.25, -toward * 3.1), home.origin.lerp(goal, 0.55) + Vector3(0, 0.7, 0), 0.4)
	DuelFx.glyph(self, home.origin, col, 1.25, 1.2, {"rings": 1, "ticks": 30, "star": 0, "turn": 3.4, "energy": 2.6})
	DuelFx.embers(self, home.origin, col.lightened(0.2), 0.55, 44, 0.85, 2.6, 0.08)
	ElementFx.gather(self, inst, home.origin, 2)
	c.set_glow(true, col)
	create_tween().tween_method(c.flash, 0.0, 3.0, Settings.t(0.5))
	Sfx.play("charge", -3.0, 0.8)
	var back := Transform3D(Basis(dir.cross(Vector3.UP).normalized(), 0.45) * home.basis, home.origin + Vector3(0, 1.15, 0) - dir * 0.75)
	await _move(c, back, 0.5, 0.0)
	await _wait(0.1)
	# The lunge, in slow motion.
	if slow_ok:
		Engine.time_scale = 0.32
	var orb := DuelFx.orb(self, c.position, col.lightened(0.35), 0.75)
	var hit := Transform3D(home.basis, home.origin.lerp(goal, 0.9) + Vector3(0, 0.3, 0))
	create_tween().tween_property(orb, "position", hit.origin, Settings.t(0.2)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	Sfx.play("attack", 0.0, 0.7)
	ElementFx.travel(self, inst, home.origin, floor_at, 2, 0.2)
	await _dash(c, hit, 0.2)
	if is_instance_valid(orb):
		orb.pop(1.6)
	# The hit.
	StrikeFx.play(self, inst, home.origin, goal)
	ElementFx.impact(self, inst, home.origin, floor_at, 2)
	finisher_hit.emit(goal, col)
	DuelFx.glow(self, goal + Vector3(0, 0.5, 0), Color.WHITE, 3.6, 0.55, 1.0, 2.6)
	for i in 3:
		DuelFx.ring(self, floor_at, col.lightened(0.15 * i), 0.4, 2.4 + i * 1.4, 0.7 + 0.15 * i, 0.07, 0.08 * i)
	DuelFx.rays(self, floor_at, col, 4.2, 0.6, 40)
	DuelFx.rays(self, goal + Vector3(0, 0.6, 0), Color.WHITE, 3.4, 0.5, 30, false)
	DuelFx.pillar(self, Vector3(goal.x, 0.0, goal.z), col.lightened(0.3), 1.0, 8.0, 1.1, 0.0, 2.0)
	DuelFx.sparks(self, goal + Vector3(0, 0.3, 0), col.lightened(0.2), 110, 9.0, 0.5, 1.2)
	_flash(goal + Vector3(0, 1.0, 0), col)
	Sfx.play("impact", 2.0, 0.6)
	Sfx.play("direct", -2.0)
	shake(1.3)
	house(1.0, col, goal, 1.0)
	var th := holo_for(target)
	if th:
		th.hit()
	if tc != null:
		_jolt(tc, dir)
	if slow_ok:
		# A held breath on the frame of the hit, then the world comes back up to speed.
		Engine.time_scale = 0.04
		await get_tree().create_timer(0.24, true, false, true).timeout
		Engine.time_scale = 0.5
		await get_tree().create_timer(0.45, true, false, true).timeout
		Engine.time_scale = 1.0
	else:
		await _wait(0.3)
	await _move(c, home, 0.34, 0.3)
	c.set_glow(false)
	cam_release(0.6)


## A card that was just hit is knocked back a hand's width and settles again.
func _jolt(c: Card3D, dir: Vector3) -> void:
	if c == null or not is_instance_valid(c):
		return
	var home := c.position
	var push := Vector3(dir.x, 0.0, dir.z).normalized() * 0.22
	var tw := create_tween()
	tw.tween_property(c, "position", home + push + Vector3(0, 0.08, 0), Settings.t(0.05))
	tw.tween_property(c, "position", home - push * 0.25, Settings.t(0.09))
	tw.tween_property(c, "position", home, Settings.t(0.12)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Freeze the whole table for a blink when a hit lands. Skipped when the duel is being
## fast-forwarded, so tests and the Very fast setting keep their pace.
func hit_stop(sec: float) -> void:
	if Engine.time_scale > 1.01 or Engine.time_scale < 0.99 or Settings.anim_speed > 2.0:
		return      # fast-forwarded, or already slowed for a Turbo Duel's last hit
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
	if turbo:
		# (0.74.0) On the road: the camera drops in behind the attacker's runner, the field
		# floating ahead of it and the blow going out across it.
		var r := rider_at(p)
		var out := 1.0 if r.z >= 0.0 else -1.0
		cam_shot(r + Vector3(-3.6, 2.2, out * 2.2), goal.lerp(r, 0.35) + Vector3(0, 0.6, 0), 0.35)
		return
	if p == 0:
		cam_shot(from + Vector3(from.x * 0.15, 2.3, 4.2), goal.lerp(from, 0.25) + Vector3(0, 0.4, 0), 0.35)
	else:
		var mid := from.lerp(goal, 0.5)
		cam_shot(Vector3(mid.x * 0.5 + 1.5, 2.6, goal.z + 5.0), mid + Vector3(0, 0.6, 0), 0.35)


## The camera follows an attack down the field. Yours: it runs in behind the attacker, low,
## and ends just short of the target. Theirs: it swings round to meet the blow where it lands.
func _battle_follow(p: int, from: Vector3, goal: Vector3, direct: bool, tier := 0) -> void:
	if turbo:
		# Then it rides up alongside the blow and is there when it lands: on a monster, or on
		# the other runner itself when nothing is in the way.
		var out := 1.0 if goal.z >= 0.0 else -1.0
		var w := 0.5 * tier
		cam_shot(goal + Vector3(-3.4 - w, 1.9 + w * 0.4, out * (2.8 + w)), goal + Vector3(0.3, 0.5, 0), 0.17)
		return
	# (a bigger attack is seen from a little further back, so all of it fits in the picture)
	var wide := 0.55 * tier
	var dir := goal - from
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3(0, 0, -1)
	var side := 1.0 if from.x <= goal.x else -1.0
	if p == 0:
		# (off to one side and above the attacker's shoulder, so its card never fills the lens)
		var back := (3.9 if direct else 3.3) + wide
		cam_shot(goal - dir * back + Vector3(-1.7 * side, 1.95 + wide * 0.5, 0.0), goal + Vector3(0, 0.55 + wide * 0.3, 0) - dir * 0.2, 0.17)
	else:
		cam_shot(Vector3(goal.x * 0.6 + 1.3 * side, 1.9 + wide * 0.5, goal.z + (3.6 if direct else 3.9) + wide), goal + Vector3(0, 0.5 + wide * 0.3, 0) - dir * 0.3, 0.17)


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
	house(0.3, color, at)
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
	qm.albedo_texture = DuelFx.dot_tex()
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
	house(0.4, color, at)
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
	if turbo:
		return rider_at(1 - p) + Vector3(0.5, 1.0, 0)
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
		goal = _attack_goal(p, null)
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


## A card is removed from play: it lifts, a violet rift opens behind it and pulls it in, and
## what is left of it lands on the banished pile as a light.
func anim_banish(inst, from: String, side: int) -> void:
	var c := card_for(inst)
	if from == "gy":
		remove_from_gy(inst)
	elif from == "hand" and side == 1:
		c = _take_from_opp_hand(inst)
	var at: Vector3 = c.position if c else gy_pos(inst.owner) + Vector3(0, 0.1, 0)
	if c == null and from == "hand" and side == 0:
		at = hand_pos(0)
	elif c == null and from == "deck":
		at = deck_pos(int(inst.owner)) + Vector3(0, 0.3, 0)
	var hole := at + Vector3(0, 0.75, 0)
	if c:
		c.set_glow(true, BANISH_COLOR)
		DuelFx.spiral(self, hole, BANISH_COLOR.lightened(0.3), Color(0.25, 0.05, 0.5), 0.85, 0.62, {"flat": false, "arms": 2, "twist": 6.0, "speed": 8.0, "hole": 0.16, "energy": 2.2, "open": 0.2})
		_rift(hole)
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
		DuelFx.rays(self, hole, BANISH_COLOR.lightened(0.2), 1.3, 0.35, 16, false)
	else:
		_rift(hole)
	var pile := banish_pos(inst.owner) + Vector3(0, 0.12, 0)
	soul(hole, pile, BANISH_COLOR.lightened(0.25), 0.3)
	_add_to_banished(inst)
	_pile_arrives(inst, 0.28)
	await _wait(0.2)


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


## A card is destroyed: it shudders and cracks white, bursts into shards, and what is left of
## it flies to the Graveyard as a light.
func anim_destroy(inst, overlays: Array = []) -> void:
	var c := card_for(inst)
	if c == null:
		return
	for o in overlays:
		_add_to_gy(o)
	c.set_glow(true, UITheme.DANGER)
	var home := c.position
	duelist_look(home, 1.4)      # (both of them watch it go)
	var red := Color("ff6a5a")
	var tw := create_tween()
	tw.tween_method(func(t: float):
		if is_instance_valid(c):
			c.position = home + Vector3(sin(t * 60.0) * 0.04, 0.03, cos(t * 47.0) * 0.03)
			c.flash(t * 3.0), 0.0, 1.0, Settings.t(0.15))
	await tw.finished
	var floor_at := Vector3(home.x, 0.03, home.z)
	_shatter(home, _frame_color(inst))
	DuelFx.rays(self, floor_at, red, 1.8, 0.4, 22)
	DuelFx.ring(self, floor_at, red, 0.3, 1.5, 0.5, 0.05)
	DuelFx.glow(self, home + Vector3(0, 0.3, 0), Color(1.0, 0.85, 0.8), 1.9, 0.35, 0.5, 2.4)
	shake(0.25)
	var tw2 := create_tween().set_parallel()
	tw2.tween_property(c, "position:y", 0.5, Settings.t(0.18))
	tw2.tween_property(c, "scale", Vector3(1.15, 1.15, 1.15), Settings.t(0.18))
	tw2.tween_method(c.set_alpha, 1.0, 0.0, Settings.t(0.18))
	await tw2.finished
	_cards.erase(inst.uid)
	c.queue_free()
	soul(home + Vector3(0, 0.45, 0), gy_pos(int(inst.owner)) + Vector3(0, 0.15, 0), Color("c8d4ff"), 0.3)
	_add_to_gy(inst)
	_pile_arrives(inst, 0.28)


## A card is discarded from the hand: it goes to the Graveyard as a light.
func anim_discard(p: int, inst) -> void:
	var from := hand_pos(p)
	if p == 1:
		var c := _take_from_opp_hand(inst)
		_cards.erase(inst.uid)
		if c != null and is_instance_valid(c):
			from = c.position
			c.queue_free()
	soul(from, gy_pos(int(inst.owner)) + Vector3(0, 0.15, 0), Color("c8d4ff"), 0.3)
	_add_to_gy(inst)
	_pile_arrives(inst, 0.28)
	await _wait(0.24)


## A card moves between piles without touching the field (0.58.0): each trip has its own
## colour. A search fans a glow out of the Deck and a gold light flies to the hand; a card
## taken back from the Graveyard rises out of it in green; one shuffled back sinks into the
## Deck in blue; a milled card drops off the top of the Deck into the Graveyard.
func anim_travel(kind: String, p: int, inst) -> void:
	var own: int = int(inst.owner) if inst != null else p
	var deck := deck_pos(own) + Vector3(0, 0.25, 0)
	var gy := gy_pos(own) + Vector3(0, 0.15, 0)
	if turbo or Settings.anim_speed > 2.0:
		if kind == "mill":
			_add_to_gy(inst)
		return
	match kind:
		"search":
			var gold := Color("ffd76a")
			pile_flare(deck, gold)
			_deck_fan(own, gold)
			Sfx.play("sparkle", -8.0, 1.3)
			await _wait(0.2)
			soul(deck + Vector3(0, 0.3, 0), hand_pos(p), gold, 0.3, 0.34)
			await _wait(0.26)
		"gy_to_hand":
			var green := Color("8dffb0")
			pile_flare(gy, green)
			Sfx.play("sparkle", -9.0, 1.0)
			await _wait(0.14)
			soul(gy + Vector3(0, 0.3, 0), hand_pos(p), green, 0.3, 0.32)
			await _wait(0.26)
		"gy_to_deck":
			var blue := Color("7ab8ff")
			pile_flare(gy, blue)
			soul(gy + Vector3(0, 0.3, 0), deck, blue, 0.3)
			await _wait(0.3)
			DuelFx.ring(self, Vector3(deck.x, 0.03, deck.z), blue, 0.3, 0.9, 0.35, 0.05)
		"mill":
			soul(deck, gy, Color("c8d4ff"), 0.26, 0.26)
			_add_to_gy(inst)
			_pile_arrives(inst, 0.24)
			Sfx.play("card", -8.0, 1.2)
			await _wait(0.16)


## The Deck opens like a fan for a moment: five ghost cards spread out over it and fold back.
func _deck_fan(p: int, color: Color) -> void:
	var at := deck_pos(p) + Vector3(0, 0.35, 0)
	var facing := 1.0 if p == 0 else -1.0
	for i in 5:
		var q := MeshInstance3D.new()
		var mesh := QuadMesh.new()
		mesh.size = Vector2(0.62, 0.9)
		q.mesh = mesh
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.albedo_color = Color(color, 0.0)
		q.material_override = m
		q.position = at
		q.rotation = Vector3(-0.5 * facing, 0.0 if p == 0 else PI, 0)
		add_child(q)
		var spread := float(i - 2)
		var tw := create_tween().set_parallel()
		tw.tween_property(q, "position", at + Vector3(spread * 0.34 * facing, 0.5 - absf(spread) * 0.08, 0.0), Settings.t(0.2)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(q, "rotation:z", -spread * 0.2 * facing, Settings.t(0.2))
		tw.tween_property(m, "albedo_color:a", 0.5, Settings.t(0.12))
		tw.chain().tween_interval(Settings.t(0.12))
		tw.chain().tween_property(q, "position", at, Settings.t(0.16)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(m, "albedo_color:a", 0.0, Settings.t(0.16))
		tw.chain().tween_callback(q.queue_free)


## An effect is negated (0.58.0): a red seal stamps down over the card, holds it for a beat,
## then cracks and flies apart. The card shudders under it.
func anim_negated(inst) -> void:
	if inst == null:
		return
	var c := card_for(inst)
	if c != null and (not is_instance_valid(c) or _opp_hand.has(c) or c.position.y > 0.6):
		c = null      # (in a hand, or held up to be read: the seal lands where it stands on the table)
	var spot := chain_spot(inst, int(inst.owner))
	var at := Vector3(spot.x, 0.05, spot.z)
	var red := Color("ff3b4a")
	var seal := DuelFx.glyph(self, at, red, 0.9, 1.0, {"rings": 2, "ticks": 12, "star": 4, "turn": -0.5, "energy": 3.2, "keep": true})
	DuelFx.rect(self, at, red, 1.7, 1.0, 0.3, false, 3.0, 0.8)
	DuelFx.pillar(self, Vector3(at.x, 0.0, at.z), red, 0.5, 2.4, 0.4, 0.0, 1.6)
	var home := c.position if c != null else Vector3.ZERO
	if c != null:
		c.set_glow(true, red)
	var tw := create_tween()
	tw.tween_method(func(t: float):
		if c != null and is_instance_valid(c):
			c.position = home + Vector3(sin(t * 70.0) * 0.035 * (1.0 - t), 0.0, 0.0), 0.0, 1.0, Settings.t(0.3))
	tw.tween_interval(Settings.t(0.25))
	tw.tween_callback(func():
		# The seal cracks.
		DuelFx.fade(seal, 0.12)
		DuelFx.rays(self, at, red.lightened(0.3), 1.6, 0.35, 14)
		DuelFx.ring(self, at, red, 0.7, 1.6, 0.4, 0.04)
		DuelFx.sparks(self, at + Vector3(0, 0.1, 0), red.lightened(0.2), 20, 3.0, 0.5, 0.6, -5.0, 0.06)
		Sfx.play("destroy", -10.0, 1.7)
		if c != null and is_instance_valid(c):
			c.position = home
			c.set_glow(false))


## A pile lights up: a card is coming out of it or going onto it (the Deck for a search, the
## Graveyard for a card that comes back).
func pile_flare(at: Vector3, color: Color) -> void:
	DuelFx.glyph(self, Vector3(at.x, 0.02, at.z), color, 0.7, 0.6, {"rings": 1, "ticks": 20, "star": 0, "turn": 1.6})
	DuelFx.pillar(self, Vector3(at.x, 0.0, at.z), color, 0.3, 2.2, 0.5, 0.0, 1.8)


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
			if not hidden and m.face_up:
				# (0.58.0) A change of ATK or DEF pops up over the card, up in gold or down in red.
				var now_def := int(state.def_of(m))
				if _last_stats.has(m.uid):
					var was: Array = _last_stats[m.uid]
					if int(was[0]) != int(shown_atk) or int(was[1]) != now_def:
						_stat_pop(base, int(shown_atk) - int(was[0]), now_def - int(was[1]))
				_last_stats[m.uid] = [int(shown_atk), now_def]
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
			# (0.72.5) The star shows the Level the monster has NOW: an effect that raised or lowered
			# it used to work (a Synchro counted the new Level) while the star kept the printed one.
			var star_l := pair[3].get_child(0) as Label3D if (pair[3] as Node).get_child_count() > 0 else null
			if star_l != null:
				var printed := int(m.data.get("level", 0))
				var lv := int(m.level())
				var is_xyz: bool = str(m.data.get("frame", "")) == "xyz"
				star_l.text = str(lv)
				if lv == printed:
					star_l.modulate = Color("ffd23a") if is_xyz else Color("0a1236")
				else:
					star_l.modulate = (Color("7dffa0") if is_xyz else Color("0b6b2a")) if lv > printed else (Color("ff8a8a") if is_xyz else Color("c21414"))
				if not hidden and m.face_up:
					if _last_lv.has(m.uid) and int(_last_lv[m.uid]) != lv:
						_level_pop(base, pair[3], lv, lv > int(_last_lv[m.uid]))
					_last_lv[m.uid] = lv
			# What the Field Spell in force does to this one: a mark on the card's far corner,
			# up in the place's color or down in red, with the numbers.
			var fd: Array = FieldLooks.delta(state, m) if m.face_up else [0, 0]
			if pair.size() < 5:
				var fl := _stat_label()
				fl.font_size = 50
				fl.outline_size = 14
				pair.append(fl)
			var mark: Label3D = pair[4]
			if int(fd[0]) == 0 and int(fd[1]) == 0:
				mark.visible = false
			else:
				var lead := int(fd[0]) if int(fd[0]) != 0 else int(fd[1])
				var bits: Array = []
				if int(fd[0]) != 0:
					bits.append("%+d" % int(fd[0]))
				if int(fd[1]) != 0 and int(fd[1]) != int(fd[0]):
					bits.append("%+d DEF" % int(fd[1]))
				mark.text = ("▲ " if lead > 0 else "▼ ") + "  ".join(bits)
				mark.modulate = field_glow().lerp(Color.WHITE, 0.25) if lead > 0 else Color("ff8a8a")
				mark.position = base + Vector3(0.0, 0.12, -0.72 if m.attack_pos else -0.56)
				mark.visible = true
	for uid in _stats.keys():
		if not seen.has(uid):
			for l in _stats[uid]:
				l.queue_free()
			_stats.erase(uid)
	for uid in _last_stats.keys():
		if not seen.has(uid):
			_last_stats.erase(uid)
	for uid in _last_lv.keys():
		if not seen.has(uid):
			_last_lv.erase(uid)


var _last_stats := {}    # monster uid -> [ATK, DEF] as last shown
var _last_lv := {}       # monster uid -> the Level as last shown


## The Level changed: the star jumps and the new Level rises (gold) or sinks (red) over the card.
func _level_pop(base: Vector3, star: Node3D, lv: int, up: bool) -> void:
	var col := Color("ffd23a") if up else Color("ff6a6a")
	var l := _stat_label()
	l.text = ("▲ " if up else "▼ ") + "★ " + str(lv)
	l.font_size = 84
	l.outline_size = 20
	l.modulate = col
	l.position = base + Vector3(-0.35, 0.6, 0.3)
	l.visible = true
	l.scale = Vector3.ONE * 0.4
	var tw := create_tween().set_parallel()
	tw.tween_property(l, "scale", Vector3.ONE, Settings.t(0.16)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y + (0.45 if up else -0.25), Settings.t(1.0)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, Settings.t(0.3)).set_delay(Settings.t(0.85))
	tw.chain().tween_callback(l.queue_free)
	if is_instance_valid(star):
		star.scale = Vector3.ONE * 1.7
		create_tween().tween_property(star, "scale", Vector3.ONE, Settings.t(0.35)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("charge" if up else "fizz", -12.0, 1.3 if up else 0.9)


## "+500" rising in gold with light going up, or "-500" sinking in red with light going down.
func _stat_pop(base: Vector3, d_atk: int, d_def: int) -> void:
	var lead := d_atk if d_atk != 0 else d_def
	if lead == 0:
		return
	var up := lead > 0
	var col := Color("ffd23a") if up else Color("ff6a6a")
	var bits: Array = []
	if d_atk != 0:
		bits.append("%+d" % d_atk)
	if d_def != 0 and d_def != d_atk:
		bits.append("%+d DEF" % d_def)
	var l := _stat_label()
	l.text = ("▲ " if up else "▼ ") + "  ".join(bits)
	l.font_size = 96
	l.outline_size = 22
	l.modulate = col
	l.position = base + Vector3(0, 0.75, 0.1)
	l.visible = true
	l.scale = Vector3.ONE * 0.4
	var tw := create_tween().set_parallel()
	tw.tween_property(l, "scale", Vector3.ONE, Settings.t(0.16)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y + (0.55 if up else -0.3), Settings.t(0.9)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, Settings.t(0.3)).set_delay(Settings.t(0.75))
	tw.chain().tween_callback(l.queue_free)
	var floor_at := Vector3(base.x, 0.03, base.z)
	DuelFx.rect(self, floor_at, col, 1.0, 1.35, 0.5, false, 2.2, 0.6)
	if up:
		DuelFx.embers(self, floor_at, col, 0.42, 22, 0.55, 2.4, 0.06)
		Sfx.play("charge", -12.0, 1.4)
	else:
		DuelFx.sparks(self, base + Vector3(0, 1.0, 0), col, 16, 1.2, 0.0, 0.7, -6.0, 0.05)
		Sfx.play("fizz", -10.0, 0.8)


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

var _drop_bands: Array = []      # per row: the whole row, its left half, its right half: {node, mat, label, on, row, half}


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


## Where on your rows a dropped card lands: [row, half]. row as drop_row; half 0 = left, 1 = right.
func drop_cell(screen: Vector2) -> Array:
	var w := table_point(screen)
	return [drop_row(screen), 0 if w.x < 0.0 else 1]


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
func show_drop(rows: Array, on: bool) -> void:
	# rows = [front row, back row]; each a list of the words to show: none (the row stays dark),
	# one (the whole row), or two (its left half and its right half).
	if _drop_bands.is_empty():
		if not on:
			return
		var wide := ZONE_SPACING * 5.0 + 0.3
		for r in 2:
			var z := MONSTER_ROW if r == 0 else SPELL_ROW
			# [x of its middle, width, half it answers to (-1: the whole row)]
			for part in [[0.0, wide, -1], [-wide * 0.25 - 0.03, wide * 0.5 - 0.06, 0], [wide * 0.25 + 0.03, wide * 0.5 - 0.06, 1]]:
				var mi := MeshInstance3D.new()
				var pm := PlaneMesh.new()
				pm.size = Vector2(float(part[1]), 1.2)
				mi.mesh = pm
				var m := StandardMaterial3D.new()
				m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
				m.albedo_color = Color(theme["accent"], 0.12)
				mi.material_override = m
				mi.position = Vector3(float(part[0]), 0.03, z)
				mi.visible = false
				add_child(mi)
				var l := Label3D.new()
				l.font = UITheme.title_font()
				l.font_size = 110 if int(part[2]) == -1 else 92
				l.pixel_size = 0.0042
				l.outline_size = 20
				l.outline_modulate = Color(0, 0, 0, 0.75)
				l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				l.no_depth_test = true
				l.position = Vector3(float(part[0]), 0.5, z)
				l.visible = false
				add_child(l)
				_drop_bands.append({"node": mi, "mat": m, "label": l, "on": false, "row": r, "half": int(part[2])})
	for b in _drop_bands:
		var words: Array = rows[int(b["row"])] if on and int(b["row"]) < rows.size() else []
		var text := ""
		if words.size() == 1 and int(b["half"]) == -1:
			text = str(words[0])
		elif words.size() >= 2 and int(b["half"]) >= 0:
			text = str(words[int(b["half"])])
		b["on"] = text != ""
		(b["node"] as Node3D).visible = text != ""
		(b["label"] as Label3D).visible = text != ""
		(b["label"] as Label3D).text = text


func _update_drop() -> void:
	if _drop_bands.is_empty():
		return
	var cell := drop_cell(get_viewport().get_mouse_position())
	for b in _drop_bands:
		if not b["on"]:
			continue
		var hot: bool = int(b["row"]) == int(cell[0]) and (int(b["half"]) == -1 or int(b["half"]) == int(cell[1]))
		var pulse := 0.5 + 0.5 * sin(_time * 6.0)
		# Face-up plays in the field's own color, Set (the right half) in a cooler one, so the two
		# halves of a row read as two different places to drop.
		var base: Color = Color("9fb4ff") if int(b["half"]) == 1 else Color(theme["accent"])
		(b["mat"] as StandardMaterial3D).albedo_color = Color(Color("ffd98a") if hot else base, (0.3 + 0.12 * pulse) if hot else (0.09 + 0.05 * pulse))
		(b["label"] as Label3D).modulate = Color("fff2c8") if hot else Color(base.lightened(0.5), 0.8)
		(b["label"] as Label3D).position.y = 0.5 + (0.12 if hot else 0.0)


# ------------------------------------------------------------------ pointing at a zone

var _zone_marks: Array = []      # {node, mat, rim, label, zone}
var _zone_word := ""


## Where a zone is. zone = [player, location (4 = Monster Zone, 8 = Spell & Trap Zone), sequence].
func zone_pos(zone: Array) -> Vector3:
	var p := int(zone[0])
	return monster_zone_pos(p, int(zone[2])) if int(zone[1]) == 4 else st_pos(p, int(zone[2]))


## Light up the zones a card may go to (an empty list puts the lights out). The one under the
## pointer burns brighter and shows `word`.
func show_zone_picks(zones: Array, word := "") -> void:
	for m in _zone_marks:
		if is_instance_valid(m["node"]):
			(m["node"] as Node3D).queue_free()
	_zone_marks.clear()
	_zone_word = word
	for z in zones:
		var monster := int(z[1]) == 4
		var size := Vector2(0.98, 0.98) if monster else Vector2(0.72, 0.98)
		var root := Node3D.new()
		root.position = zone_pos(z) + Vector3(0, 0.035, 0)
		add_child(root)
		var mi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = size
		mi.mesh = pm
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.albedo_color = Color(Comic.SKY, 0.2)
		mi.material_override = mat
		root.add_child(mi)
		# Four bright bars around it, so the zone reads as a frame and not as a blur.
		var rim := StandardMaterial3D.new()
		rim.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rim.albedo_color = Comic.SKY
		rim.emission_enabled = true
		rim.emission = Comic.SKY
		rim.emission_energy_multiplier = 2.2
		for side in 4:
			var bar := MeshInstance3D.new()
			var bm := BoxMesh.new()
			var along_x := side < 2
			bm.size = Vector3(size.x + 0.05, 0.02, 0.045) if along_x else Vector3(0.045, 0.02, size.y + 0.05)
			bar.mesh = bm
			bar.material_override = rim
			bar.position = Vector3(0, 0, (size.y / 2.0) * (1 if side == 0 else -1)) if along_x else Vector3((size.x / 2.0) * (1 if side == 2 else -1), 0, 0)
			root.add_child(bar)
		var l := Label3D.new()
		l.font = Comic.button_font()
		l.font_size = 60
		l.pixel_size = 0.0034
		l.outline_size = 18
		l.outline_modulate = Color(0.03, 0.04, 0.09, 0.95)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.render_priority = 7
		l.outline_render_priority = 6
		l.position.y = 0.55
		l.text = Loc.t(word) if word != "" else ""
		l.visible = false
		root.add_child(l)
		# Each one rises out of the table a beat after its neighbour.
		root.scale = Vector3(0.6, 1, 0.6)
		var tw := create_tween()
		tw.tween_property(root, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.025 * _zone_marks.size())
		_zone_marks.append({"node": root, "mat": mat, "rim": rim, "label": l, "zone": z})


## The lit zone a point of the screen is over, or null.
func zone_at(screen: Vector2, zones: Array):
	var w := table_point(screen)
	var best = null
	var best_d := 1.08      # (1.0 = the edge of the zone; a little slop around it)
	for z in zones:
		var zp := zone_pos(z)
		var d := maxf(absf(w.x - zp.x) / (0.62 if int(z[1]) == 4 else 0.5), absf(w.z - zp.z) / 0.62)
		if d < best_d:
			best_d = d
			best = z
	return best


func _update_zone_marks() -> void:
	if _zone_marks.is_empty():
		return
	var zones: Array = []
	for m in _zone_marks:
		zones.append(m["zone"])
	var hot = zone_at(get_viewport().get_mouse_position(), zones)
	var pulse := 0.5 + 0.5 * sin(_time * 5.0)
	for m in _zone_marks:
		if not is_instance_valid(m["node"]):
			continue
		var on: bool = hot != null and m["zone"] == hot
		var col: Color = Color("ffe28a") if on else Comic.SKY
		(m["mat"] as StandardMaterial3D).albedo_color = Color(col, (0.42 + 0.14 * pulse) if on else (0.1 + 0.1 * pulse))
		(m["rim"] as StandardMaterial3D).albedo_color = col
		(m["rim"] as StandardMaterial3D).emission = col
		(m["rim"] as StandardMaterial3D).emission_energy_multiplier = 3.4 if on else (1.4 + 1.0 * pulse)
		var n: Node3D = m["node"]
		n.position.y = lerpf(n.position.y, 0.11 if on else 0.035, 0.3)
		(m["label"] as Label3D).visible = on and _zone_word != ""
		(m["label"] as Label3D).modulate = Color("fff2c8")


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
	_update_zone_marks()
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


## The last hit of a Turbo Duel: slow motion, both runners side by side out ahead of the
## field and the camera low in front of them, looking back.
func turbo_blow(loser: int) -> void:
	if track == null or track.blow_busy:
		return
	track.finish_blow(loser)
	var side := 1.0 if loser == 1 else -1.0      # lean the shot toward the winner
	cam_cut(Vector3(18.2, 0.95, side * 1.1), Vector3(10.5, 1.2, 0.0))


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
const TURBO_RIDER := [Vector3(0, 0, 6.7), Vector3(0, 0, -7.3)]


## Where a rider is on the road right now (a Turbo Duel), for a blow or a camera to find them.
func rider_at(p: int) -> Vector3:
	if track != null:
		var n := track.rider_node(p)
		if n != null:
			return n.position
	return TURBO_RIDER[clampi(p, 0, 1)]


## The two duelists stand at their ends of the field, each on a lit plate.
func add_duelists(me_key: String, opp_key: String) -> void:
	if turbo:
		for p in 2:
			var col: Color = theme["accent"] if p == 0 else theme["accent2"]
			var side := 1.0 if p == 0 else -1.0
			var look := {}
			if p == 0 and me_key == "player":
				# Your own runner, the way you left it in the garage.
				look = {"frame": TurboGarage.frame(), "trail": TurboGarage.trail(TurboGarage.paint(col)), "mark": TurboGarage.mark()}
				col = TurboGarage.paint(col)
			# (0.74.1) Back at the two ends of the field (0.74.0 had them side by side at its left
			# edge: the card panel covered them, the intro looked at an empty road and their hand
			# floated with nobody holding it). Theirs rides just behind the cards they hold; yours
			# is in your corner picture, live on its runner.
			_duelists[p] = track.add_rider(p, me_key if p == 0 else opp_key, TURBO_RIDER[p], col, look)
			# (0.74.1) Two engines you can tell apart: yours a little higher, theirs deeper.
			track.engine_on(p, 1.08 if p == 0 else 0.86, -9.0)
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
		_style[p] = style_of(key)
		_dkey[p] = key
		# (friendly: the calm stand itself. Its own stance held the hands together at the belly, which
		# sank the arm and the Duel Disk into the body on some duelists.)
		if str(_style[p]) != "kind":
			fig.stand_as("st_" + str(_style[p]))
		# Where they look: at the other duelist, and at the action when there is some (duelist_look).
		var eye := Node3D.new()
		eye.position = Vector3(0.0, 0.0, -side * DUELIST_Z)      # (a figure looks 1.5 above what it watches: a person's feet)
		add_child(eye)
		_focus[p] = eye
		fig.watch = eye
		fig.watch_far = true
		var spot := SpotLight3D.new()
		spot.light_color = Color.WHITE.lerp(col, 0.25)
		spot.light_energy = 7.0
		spot.spot_range = 9.0
		spot.spot_angle = 30.0
		spot.shadow_enabled = false
		spot.position = Vector3(1.6 * side, 5.2, side * (DUELIST_Z - 2.6))
		add_child(spot)
		spot.look_at(Vector3(0, 1.3, side * DUELIST_Z))


## How a duelist carries themselves (0.63.0): one of the five personalities. A named duelist has their
## own; anybody else gets one from their name, always the same one; yours is the Style on your profile.
var _style := {}
const STYLES := ["kind", "cocky", "cool", "wild", "dark"]
## What each personality does when it wins and when it loses: [motion, speed, from, to, hold it?].
const STYLE_WIN := {"kind": ["cheer_one", 1.0, 0.0, 0.0], "cocky": ["shrug", 0.8, 0.0, 0.0], "cool": ["hip", 1.0, 0.0, 0.0],
	"wild": ["hop", 1.0, 0.0, 0.0], "dark": ["scheme", 0.9, 0.0, 0.0]}
const STYLE_LOSE := {"kind": "defeat", "cocky": "head_hold", "cool": "defeat", "wild": "kneel_down", "dark": "kneel_down"}

## Signature moves (0.63.0): every duelist with a model of their own has their own pair, a pose for the
## face-off and a gesture for the monster they are known for. Moves made for this game; the six leads
## each have a face-off pose nobody else uses. key -> [face-off motion, ace motion].
const SIGNATURE := {
	"yugi": ["fo_chest", "ace_sky"], "kaiba": ["fo_open", "ace_sweep"], "joey": ["fist_pump", "punch_pose"],
	"jaden": ["fo_salute", "ace_snap"], "yusei": ["fo_glove", "ace_slam"], "yuma": ["punch_pose", "ace_both"],
	"mai": ["fo_hair", "ace_snap"], "akiza": ["hip", "ace_sweep"], "alexis": ["fo_bow", "ace_sky"],
	"aster": ["shrug", "ace_snap"], "bakura": ["scheme", "ace_both"], "marik": ["fo_beckon", "ace_slam"],
	"pegasus": ["fo_bow", "ace_sweep"], "weevil": ["scheme", "ace_snap"], "rex": ["shout", "ace_slam"],
	"chazz": ["hip", "summon_big"], "crow": ["challenge", "ace_sweep"], "jack": ["battle_pose", "ace_both"],
	"kalin": ["shrug", "ace_slam"], "kite": ["challenge", "ace_sky"], "shark": ["battle_pose", "ace_sweep"],
	"syrus": ["fo_bow", "ace_both"], "vector": ["fo_beckon", "ace_snap"], "zane": ["challenge", "ace_slam"],
	"grandpa": ["fo_bow", "summon_big"]}
## Everybody else squares up the way their personality does.
const STYLE_FACEOFF := {"kind": "challenge", "cocky": "hip", "cool": "battle_pose", "wild": "punch_pose", "dark": "scheme"}
const STYLE_TAUNT := {"kind": "talk_open", "cocky": "shrug", "cool": "hip", "wild": "shout", "dark": "scheme"}
var _dkey := {}      # player -> the duelist's key


static func style_of(key: String) -> String:
	if key == "player":
		var mine := str(Profile.STYLES[Profile.style])
		return mine if mine != "" else "kind"
	var pers := str(Characters.get_char(key).get("personality", ""))
	if pers in STYLES:
		return pers
	return str(STYLES[absi(key.hash()) % STYLES.size()])


## The winner's moment and the loser's, each in their own way. hold: the loser stays down.
func duelist_win(p: int) -> void:
	if not has_duelist(p):
		return
	var fig: RoamFigure = _duelists[p]
	var w: Array = STYLE_WIN.get(str(_style.get(p, "kind")), STYLE_WIN["kind"])
	if not fig.act(str(w[0]), 0.2, float(w[1]), float(w[2]), float(w[3])):
		fig.play_once("victory", 2)
	else:
		# ...and then the long cheer, so they are not standing still while the results come up.
		var first := fig._hold
		get_tree().create_timer(maxf(0.4, first)).timeout.connect(func():
			if is_instance_valid(fig) and fig.act("win_a" if str(_style.get(p, "")) in ["kind", "wild"] else "hip", 0.3):
				fig._hold = 30.0)


func duelist_lose(p: int) -> void:
	if not has_duelist(p):
		return
	var fig: RoamFigure = _duelists[p]
	var m := str(STYLE_LOSE.get(str(_style.get(p, "kind")), "defeat"))
	if fig.act(m, 0.25, 1.0):
		fig._hold = 30.0      # (they stay that way: the clip ends in the pose)
	else:
		fig.play_once("lose")


## The duelist at the table acts out what they just said.
## (0.63.1: "agree" and "stomp" are out of duels. On the real models' longer arms one arm stuck straight
## out to the side and a hand crossed the face. Losing a monster or being negated is a step back now,
## going second is a nod, and a chained card has its own card motion.)
## ("-": this moment has a motion of its own, played by duelist_act; the line adds no gesture to it)
const TALK_MOVES := {"intro": "challenge", "taunt": "chat", "ace": "-", "attack": "-", "react": "scratch",
	"destroyed": "back_off", "low": "alert", "hurt": "-", "hurt_big": "-", "trap": "-", "spell": "-", "set": "-", "set_mon": "-",
	"draw": "-", "summon": "-", "direct": "-", "end": "-", "battle": "challenge", "first": "challenge", "second": "",
	"big_hit": "fist_pump", "comeback": "fist_pump", "ace_lost": "head_hold", "turn": "", "draw_pressure": "scratch",
	"chain": "-", "negate": "challenge", "negated": "back_off", "fusion": "-", "synchro": "-", "xyz": "-", "ritual": "-"}


func duelist_gesture(p: int, kind: String) -> void:
	if not _duelists.has(p) or not (_duelists[p] is RoamFigure):
		return
	var fig: RoamFigure = _duelists[p]
	var move := str(TALK_MOVES.get(kind, "chat"))
	if move == "-":
		return
	if kind == "taunt":
		# A jab between turns, each personality in its own way.
		var tm := str(STYLE_TAUNT.get(str(_style.get(p, "kind")), "talk_open"))
		if fig.act(tm, 0.2, 1.0):
			fig._hold = minf(fig._hold, 2.6)
			return
	if kind == "intro":
		# The face-off: their own pose, or their personality's.
		var sig: Array = SIGNATURE.get(str(_dkey.get(p, "")), [])
		var fo := str(sig[0]) if not sig.is_empty() else str(STYLE_FACEOFF.get(str(_style.get(p, "kind")), "challenge"))
		if fo != "challenge" and fig.act(fo, 0.2, 1.0):
			fig._hold = minf(fig._hold, 3.2)
			return
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


## What a duelist does at each moment of a duel (0.63.0): motions of the arms and the torso, made for
## duels, in place of the whole figure tilting as one piece. moment -> [clip, speed, from, to (seconds
## of the clip, 0 = to its end)], or a list of those to pick from.
const ACTS := {
	"draw": ["draw", 1.2, 0.0, 0.0], "summon": ["play", 1.0, 0.0, 0.0], "summon_big": ["summon_big", 1.2, 0.0, 0.0],
	"set": ["cset", 1.0, 0.0, 0.0], "spell": ["cspell", 1.0, 0.0, 0.0], "trap": ["ctrap", 1.0, 0.0, 0.0],
	"attack": [["point", 1.3, 0.0, 0.0], ["challenge", 1.6, 0.0, 0.0]], "direct": ["direct", 1.2, 0.0, 0.0], "end": ["endturn", 1.2, 0.0, 0.0],
	"hurt": [["hit2", 1.0, 0.0, 0.0], ["hit_waist", 1.25, 0.0, 0.0]], "hurt_big": [["hit", 1.0, 0.0, 0.0], ["hit_waist", 1.0, 0.0, 0.0]],
	"think": ["think", 1.0, 0.0, 0.0], "ace_lost": ["head_hold", 1.1, 0.0, 0.0], "cheer": ["fist_pump", 1.0, 0.0, 0.0],
	"ready": ["battle_pose", 1.0, 0.0, 0.0]}
## When a card shows in the duelist's hand during a motion: moment -> [from, for how long] (seconds of the clip).
## (0.63.1: timed to the hand-made motions in Avatars.MADE_MOTIONS: the card appears as the hand lifts off
## the deck and is gone as it touches the Duel Disk.)
const CARD_IN_HAND := {"draw": [0.55, 1.35], "summon": [0.0, 0.76], "set": [0.0, 0.8], "spell": [0.0, 1.0]}
## The old whole-body move for a moment, for a figure that cannot play the motion.
const ACT_OLD := {"draw": "draw", "summon": "summon", "summon_big": "summon", "ace": "summon", "attack": "attack", "direct": "attack", "hurt": "hurt", "hurt_big": "hurt"}


## The duelist acts out a moment of the duel. True when a real motion played.
var _act_log := "--pose-debug" in OS.get_cmdline_user_args()
var _act_last := {}      # player -> [moment, the time its motion ends]
var _act_pick := {}      # "<player>|<moment>" -> which version played last

func duelist_act(p: int, moment: String, strength := 1.0) -> bool:
	if turbo or not _duelists.has(p) or not is_instance_valid(_duelists[p]) or not (_duelists[p] is RoamFigure):
		return false
	var fig: RoamFigure = _duelists[p]
	var a: Array = ACTS.get(moment, [])
	# The same motion is not started over while it is still playing (five cards dealt in a row are
	# one pull of the arm, not five).
	var now := Time.get_ticks_msec() / 1000.0
	var last: Array = _act_last.get(p, ["", 0.0])
	if str(last[0]) == moment and now < float(last[1]):
		return true
	if moment == "ace":
		# The monster they are known for: their own gesture when they have one.
		var sig: Array = SIGNATURE.get(str(_dkey.get(p, "")), [])
		a = [str(sig[1]) if sig.size() > 1 else "summon_big", 1.15, 0.0, 0.0]
	if not a.is_empty() and a[0] is Array:
		# (two versions of a moment: never the same one twice in a row)
		var pick := randi() % a.size()
		if a.size() > 1 and int(_act_pick.get("%d|%s" % [p, moment], -1)) == pick:
			pick = (pick + 1) % a.size()
		_act_pick["%d|%s" % [p, moment]] = pick
		a = a[pick]
	if not a.is_empty() and fig.act(str(a[0]), 0.18, float(a[1]) / maxf(Settings.t(1.0), 0.2), float(a[2]), float(a[3])):
		_act_last[p] = [moment, now + fig._hold]
		if CARD_IN_HAND.has(moment):
			var ch: Array = CARD_IN_HAND[moment]
			fig.hold_card(float(ch[1]) / maxf(float(a[1]), 0.1), float(ch[0]) / maxf(float(a[1]), 0.1))
		if _act_log:
			print("ACT p%d %s %s t=%d" % [p, moment, str(a[0]), Time.get_ticks_msec()])
		return true
	if ACT_OLD.has(moment):
		duelist_body(p, str(ACT_OLD[moment]), strength)
	return false


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
func duelist_shot(p: int, dur := 0.6, cheer := false, aside := 0.0, dist := 3.6) -> void:
	if not _duelists.has(p):
		return
	var side := 1.0 if p == 0 else -1.0
	var z := side * DUELIST_Z
	_aside = aside
	var from := Vector3(-1.35 * side * dist / 3.6, 1.55, z - side * dist)
	var at := Vector3((0.1 - aside) * side, 1.45, z)
	if turbo:
		# (0.74.1) On a runner: out ahead of it and to the outside, looking back at the rider's face.
		var r := rider_at(p)
		from = r + Vector3(dist * 0.95, 1.5, side * dist * 0.45)
		at = r + Vector3(0.25, 1.3, 0)
	if dur <= 0.0:
		# A cut (from one duelist to the other: no flight down the table in between), with a little drift.
		cam_cut(from, at)
		cam_drift(from + Vector3(0.25 * side, 0.05, side * 0.2), 4.0)
	else:
		cam_shot(from, at, dur)
	if cheer:
		duelist_win(p)
		if _duelists.has(1 - p) and (_duelists[1 - p] as RoamFigure)._hold < 5.0:
			duelist_lose(1 - p)


## Both duelists turn their heads to a spot on the table for a moment, then back to each other.
var _focus := {}
var _focus_tw := {}

func duelist_look(at: Vector3, secs := 1.6, only := -1) -> void:
	for p in _focus:
		if only >= 0 and p != only:
			continue
		var eye: Node3D = _focus[p]
		if not is_instance_valid(eye):
			continue
		if _focus_tw.has(p) and _focus_tw[p]:
			(_focus_tw[p] as Tween).kill()
		var side := 1.0 if p == 0 else -1.0
		eye.position = Vector3(at.x, -1.3, at.z)
		var tw := create_tween()
		tw.tween_interval(Settings.t(secs))
		tw.tween_property(eye, "position", Vector3(0.0, 0.0, -side * DUELIST_Z), 0.4)
		_focus_tw[p] = tw


# ------------------------------------------------------------------ live portraits (0.63.0)
## The two duelists in the corners of the screen are these same figures, each drawn by a small camera
## of its own that sees nothing but duelists (render layer 10) and follows their head. Whatever they
## do at the table (a draw, a stagger, a kneel, a card in the hand) shows there, all through the duel.
const PORTRAIT_LAYER := 1 << 9
var _pview := {}      # player -> SubViewport
var _pcam := {}       # player -> Camera3D
var _phead := {}      # player -> where their head is, smoothed
var _pbone := {}      # player -> [Skeleton3D, head bone]
## Framing, yours (a tall strip: head to waist) and theirs (a square: head and shoulders):
## [how far the camera stands, lens, how far under the head it aims, how far to the side it stands].
## (0.63.1: a long lens from further back. From 1.75 m a hand reaching toward the camera came out
## half as big again as it is; from 3.2 m it does not. The framing at the duelist is the same.)
const PORTRAIT_FRAME := [[3.2, 22.6, 0.25, 0.77], [3.1, 16.2, 0.13, 0.70]]
const PORTRAIT_WIDE_MAX := 1.5      # how far back the camera may step for a big gesture
var _pwide := {}      # player -> how far back it stands now (1 = the close framing)

func live_portrait(p: int, px: Vector2i) -> Texture2D:
	if not _has_fig(p):
		return null
	if _pview.has(p):
		return (_pview[p] as SubViewport).get_texture()
	var fig: RoamFigure = _duelists[p]
	fig.show_on_layers(PORTRAIT_LAYER)
	if turbo and fig.get_parent() is Node3D:
		# (0.74.1) In a Turbo Duel the picture is of the rider on their runner: the runner too.
		for mi in (fig.get_parent() as Node3D).find_children("*", "MeshInstance3D", true, false):
			if not fig.is_ancestor_of(mi) and not ((mi as MeshInstance3D).mesh is QuadMesh):      # (not the light trails)
				(mi as VisualInstance3D).layers |= PORTRAIT_LAYER
	var vp := SubViewport.new()
	vp.size = px
	vp.transparent_bg = true
	vp.world_3d = get_viewport().find_world_3d()
	vp.msaa_3d = Settings.small_view_msaa()
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var cam := Camera3D.new()
	cam.cull_mask = PORTRAIT_LAYER
	cam.fov = float(PORTRAIT_FRAME[p][1]) * ((1.45 if p == 0 else 1.7) if turbo else 1.0)
	cam.near = 0.2
	cam.far = 12.0
	# Its own light and air: the same in every arena, so a face is never lost in a dark field.
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.82, 0.86, 1.0)
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	cam.environment = env
	vp.add_child(cam)
	cam.current = true
	_pview[p] = vp
	_pcam[p] = cam
	_update_portrait(p, 1.0)
	return vp.get_texture()


func duelist_mouth(p: int, secs: float) -> void:
	if has_duelist(p):
		(_duelists[p] as RoamFigure).mouth_for(secs)
		if _act_log:
			print("MOUTH p%d %.1fs face parts %d" % [p, secs, (_duelists[p] as RoamFigure)._face_parts.size()])


func duelist_ready(p: int) -> bool:
	return _has_fig(p) and (_duelists[p] as RoamFigure).ready_to_show


## A duelist figure is there at all (on foot, or on a runner in a Turbo Duel).
func _has_fig(p: int) -> bool:
	return _duelists.has(p) and is_instance_valid(_duelists[p]) and (_duelists[p] is RoamFigure)


func _update_portrait(p: int, k: float, delta := 0.0) -> void:
	var cam: Camera3D = _pcam.get(p)
	if cam == null or not _has_fig(p):
		return
	var fig: RoamFigure = _duelists[p]
	var side := 1.0 if p == 0 else -1.0
	var head := fig.global_position + Vector3(0, 1.62 * fig.scale.y, 0)
	if not _pbone.has(p) and fig._model != null and fig.ready_to_show:
		var sk := Avatars._first_skeleton(fig._model)
		if sk != null and sk.find_bone("Head") >= 0:
			_pbone[p] = [sk, sk.find_bone("Head"), sk.find_bone("LeftHand"), sk.find_bone("RightHand")]
	var hands: Array = []
	if _pbone.has(p) and is_instance_valid(_pbone[p][0]):
		var sk2: Skeleton3D = _pbone[p][0]
		head = sk2.global_transform * sk2.get_bone_global_pose(int(_pbone[p][1])).origin + Vector3(0, 0.06, 0)
		for hi in [2, 3]:
			if int(_pbone[p][hi]) >= 0:
				hands.append(sk2.global_transform * sk2.get_bone_global_pose(int(_pbone[p][hi])).origin)
	# (the camera follows the head softly: a stagger or a nod moves them inside the picture)
	_phead[p] = head if not _phead.has(p) or k >= 1.0 else (_phead[p] as Vector3).lerp(head, k)
	var h: Vector3 = _phead[p]
	var f: Array = PORTRAIT_FRAME[p]
	# The picture opens up for a big gesture: when a hand comes up or is thrown out past the edge of
	# the frame, the camera steps back just enough to keep it in (quickly), and comes back in slowly.
	var wide := float(_pwide.get(p, 1.0))
	if delta > 0.0:
		var vp: SubViewport = _pview[p]
		var half_h := float(f[0]) * tan(deg_to_rad(float(f[1])) * 0.5)
		var half_w := half_h * float(vp.size.x) / maxf(float(vp.size.y), 1.0)
		var right := cam.global_transform.basis.x
		var up := cam.global_transform.basis.y
		var aim := Vector3(lerpf(h.x, 0.0, 0.5), h.y - float(f[2]), lerpf(h.z, side * DUELIST_Z, 0.5))
		var need := 1.0
		for hp in hands:
			var rel: Vector3 = (hp as Vector3) - aim
			if (hp as Vector3).y < h.y - 0.5:
				continue      # a hand at the hip or hanging down is not a gesture
			need = maxf(need, maxf(absf(rel.dot(right)) / (half_w * 0.8), absf(rel.dot(up)) / (half_h * 0.8)))
		need = clampf(need, 1.0, PORTRAIT_WIDE_MAX)
		wide = lerpf(wide, need, 1.0 - exp(-delta * (7.0 if need > wide else 1.5)))
		_pwide[p] = wide
	var drop := float(f[2]) + (wide - 1.0) * 0.2
	if turbo:
		# On the runner the rider faces down the road (+x): the camera rides ahead of them, a
		# little to the side, and takes in the rider and the front of the machine.
		var at2 := h - Vector3(-0.2, 0.42 if p == 0 else 0.32, 0)
		cam.global_position = at2 + Vector3(float(f[0]) * 0.9, 0.3, side * 1.3)
		cam.look_at(at2)
		return
	var at := Vector3(lerpf(h.x, 0.0, 0.5), h.y - drop, lerpf(h.z, side * DUELIST_Z, 0.5))
	cam.global_position = at + Vector3(-float(f[3]) * side, drop * 0.35, -side * float(f[0]) * wide)
	cam.look_at(at)


## A hit reaches the duelist's body: a flash of light on them and sparks off the chest, sized to the hit.
func duelist_hit(p: int, big: bool) -> void:
	if not has_duelist(p):
		return
	var side := 1.0 if p == 0 else -1.0
	var at := Vector3(0.0, 1.25, side * (DUELIST_Z - 0.35))
	_flash(at, Color("ffd0c0") if big else Color("ffb0a0"))
	_sparks(at, Color("ff6a5a"), 46 if big else 20)
	if big:
		_burst(Vector3(0.0, 0.04, side * DUELIST_Z), Color("ff5a6a"), 1.5)


func has_duelist(p: int) -> bool:
	return not turbo and _duelists.has(p) and is_instance_valid(_duelists[p]) and (_duelists[p] is RoamFigure)


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


## The end of the ending scene: the camera pulls back and up from across the table, the winner small
## at the far end with the house behind them, and keeps drifting while the results are up.
func outro_pullback(p: int, dur := 2.0) -> void:
	var side := 1.0 if p == 0 else -1.0
	if _cam_tween:
		_cam_tween.kill()
	cam_weight = 1.0
	if turbo:
		# (0.74.1) A Turbo Duel ends on the winner riding on: the camera out ahead of their
		# runner, looking back at them, and slowly letting them pull toward it.
		var r := rider_at(p)
		cam_pos = r + Vector3(6.4, 2.2, side * 3.8)
		# (aimed off to the side, so the rider sits left in the picture, clear of the results)
		var fwd := (r - cam_pos).normalized()
		var right := fwd.cross(Vector3.UP).normalized()
		cam_target = r + Vector3(0, 1.0, 0) + right * 2.4
		_cam_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_cam_tween.tween_property(self, "cam_pos", r + Vector3(8.6, 3.0, side * 5.0), dur + 9.0)
		return
	var to := Vector3(-4.2 * side, 5.0, -side * (DUELIST_Z - 0.6))
	_cam_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_cam_tween.set_parallel()
	_cam_tween.tween_property(self, "cam_pos", to, dur)
	_cam_tween.tween_property(self, "cam_target", Vector3(0.0, 1.9, side * DUELIST_Z), dur)
	_cam_tween.chain().tween_property(self, "cam_pos", to + Vector3(-1.6 * side, 1.1, -side * 1.8), 9.0)


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


var _punch := 0.0       # degrees of field of view taken off (a quick push in)
var _tilt := 0.0        # roll, in radians
var _fov_home := 0.0
var road_rush := 0.0      # Turbo Duels: 0 to 1, how fast the duel is riding (set from the Speed Counters)
var _rush_now := 0.0


## The camera lunges in for an instant (`deg` degrees narrower) and tips sideways by `roll`.
func cam_punch(deg := 3.0, roll := 0.0) -> void:
	if Settings.anim_speed > 2.0:
		return
	_punch = clampf(maxf(_punch, deg) if deg >= 0.0 else deg, -8.0, 9.0)
	if roll != 0.0:
		_tilt = clampf(roll, -0.09, 0.09)


func _process(delta: float) -> void:
	_time += delta
	_process_extra(_time)
	_process_picks(_time)
	for pp in _pcam:
		_update_portrait(pp, 1.0 - exp(-delta * 3.5), delta)
	_shake = move_toward(_shake, 0.0, delta * 1.6)
	var sway := Vector3(sin(_time * 0.35) * 0.06, sin(_time * 0.5) * 0.04, 0)
	var s := _shake * _shake * 0.35
	var jitter := Vector3(_rng.randf_range(-s, s), _rng.randf_range(-s, s), 0)
	if turbo:
		# (0.74.0) The road under you: a fine shake that grows with the Speed Counters.
		_rush_now = lerpf(_rush_now, road_rush, 1.0 - exp(-delta * 1.5))
		var hum := 0.006 + 0.016 * _rush_now
		jitter += Vector3(sin(_time * 37.0) * hum, sin(_time * 53.0 + 1.3) * hum, 0)
	var pos := cam_home.lerp(cam_pos, cam_weight) + sway * (1.0 - cam_weight) + jitter
	var tgt := cam_home_target.lerp(cam_target, cam_weight) + jitter * 0.5
	camera.position = pos
	camera.look_at(tgt)
	# (0.58.0) The lens kicks in on a hit and the horizon tips, then both settle.
	_punch = lerpf(_punch, 0.0, 1.0 - exp(-delta * 7.0))
	_tilt = lerpf(_tilt, 0.0, 1.0 - exp(-delta * 5.0))
	if _fov_home <= 0.0:
		_fov_home = camera.fov
	camera.fov = clampf(_fov_home + 6.0 * _rush_now - _punch, 20.0, 80.0)
	if absf(_tilt) > 0.0005:
		camera.rotate_object_local(Vector3(0, 0, 1), _tilt)
	_update_arrow()
