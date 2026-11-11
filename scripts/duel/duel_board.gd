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
const CAM_POS := Vector3(0, 9.0, 6.9)
const CAM_TARGET := Vector3(0, 0, 1.15)

signal ace_summoned(inst)

## Cinematic camera: blends from the table view toward cam_pos / cam_target by cam_weight.
var cam_pos := Vector3(0, 4, 12)
var cam_target := Vector3.ZERO
var cam_weight := 0.0
var _cam_tween: Tween

var camera: Camera3D
var _battle_mode := false
var theme: Dictionary = FieldThemes.resolve("auto", "")
var _cards := {}  # uid -> Card3D
var _gy_cards: Array = [[], []]
var _ban_cards: Array = [[], []]
var _ban_labels: Array = [null, null]
var state_ref: DuelState   # set by the scene, so piles know where a card really ended up
const BANISH_COLOR := Color("b06cff")
var _opp_hand: Array[Card3D] = []
var _deck_piles: Array[Node3D] = []
var _deck_labels: Array[Label3D] = []
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
	var key := DirectionalLight3D.new()
	key.light_color = Color("e6f3ff")
	key.light_energy = 0.75
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
	camera.position = CAM_POS
	add_child(camera)
	camera.look_at(CAM_TARGET)
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
	// Rotating emblem rings in the middle
	float r = length(p);
	float a = atan(p.y, p.x);
	float ring1 = line_aa(abs(r - 1.25), 0.03);
	float ring2 = line_aa(abs(r - 1.55), 0.015);
	float dash = step(0.5, fract((a + TIME * 0.15) * 12.0 / 6.28318));
	float ring3 = line_aa(abs(r - 1.85), 0.012) * dash;
	col += side * (ring1 * 0.5 + ring2 * 0.25 + ring3 * 0.35);
	// Center divider and a sweeping scan line
	float mid = line_aa(abs(p.y), 0.025);
	col += mix(accent, accent2, 0.5) * mid * 0.35 * vig;
	float sweep = 1.0 - smoothstep(0.0, 0.6, abs(p.x - (fract(TIME * 0.08) * 16.0 - 8.0)));
	col += side * sweep * 0.05 * vig;
	// Frame around the mat
	vec2 e = abs(p) - vec2(5.75, 3.6);
	float frame = line_aa(abs(max(e.x, e.y)), 0.03);
	col += side * frame * 0.8;
	ALBEDO = col;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
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


func _zone(pos: Vector3, size: Vector2, color: Color, intensity: float) -> MeshInstance3D:
	if _zone_shader == null:
		_zone_shader = Shader.new()
		_zone_shader.code = """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 color : source_color = vec4(0.18, 0.89, 0.9, 1.0);
uniform float intensity = 0.6;
void fragment() {
	vec2 d = abs(UV * 2.0 - 1.0);
	float edge = max(d.x, d.y);
	float border = smoothstep(0.88, 0.95, edge) * (1.0 - smoothstep(0.97, 1.0, edge));
	float corner = step(0.7, d.x) * step(0.78, d.y);
	float a = border * (0.55 + corner * 1.2) + 0.05;
	ALBEDO = color.rgb * a * intensity;
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
	mi.material_override = m
	mi.position = pos + Vector3(0, 0.002, 0)
	add_child(mi)
	return mi


func _build_zones() -> void:
	for p in 2:
		var col: Color = theme["accent"] if p == 0 else theme["accent2"]
		for z in 5:
			_zone(monster_zone_pos(p, z), Vector2(0.98, 0.98), col, 0.9)
			_zone(spell_zone_pos(p, z), Vector2(0.72, 0.98), col, 0.45)
		_zone(deck_pos(p), Vector2(0.72, 0.98), col, 0.6)
		_zone(gy_pos(p), Vector2(0.72, 0.98), col, 0.6)
		_zone(banish_pos(p), Vector2(0.72, 0.98), BANISH_COLOR, 0.35)
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
		top.setup(0)
		top.set_pickable(false)
		pile.add_child(top)
		_deck_piles.append(pile)
		var lbl := Label3D.new()
		lbl.font = UITheme.title_font()
		lbl.font_size = 64
		lbl.pixel_size = 0.004
		lbl.outline_size = 12
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.position = deck_pos(p) + Vector3(0, 0.5, 0.55 if p == 0 else -0.55)
		add_child(lbl)
		_deck_labels.append(lbl)
		set_deck_count(p, 0)


func set_deck_count(p: int, count: int) -> void:
	var h := maxf(0.004, count * 0.006)
	var pile := _deck_piles[p]
	var body := pile.get_child(0) as MeshInstance3D
	body.scale = Vector3(1, h, 1)
	body.position.y = h / 2.0
	var top := pile.get_child(1) as Card3D
	top.transform = Transform3D(table_basis(p, false, true), Vector3(0, h + 0.004, 0))
	pile.visible = count > 0
	_deck_labels[p].text = str(count)


# ------------------------------------------------------------------ cards

func _new_card(inst) -> Card3D:
	var c := Card3D.new()
	c.setup(inst.id)
	c.inst = inst
	add_child(c)
	c.clicked.connect(func(card): card_clicked.emit(card))
	c.hovered.connect(func(card, inside): card_hovered.emit(card, inside))
	_cards[inst.uid] = c
	return c


func card_for(inst) -> Card3D:
	return _cards.get(inst.uid)


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
		await _move(c, _near_camera_xform(), 0.35, 0.8)
		var tw := create_tween()
		tw.tween_method(c.set_alpha, 1.0, 0.0, Settings.t(0.12))
		await tw.finished
		_cards.erase(inst.uid)
		c.queue_free()
	else:
		_opp_hand.append(c)
		_layout_opp_hand()
		await _wait(0.22)


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
	await _move(c, hover, 0.38, 0.4)
	if not _orbs.is_empty():
		await _consume_orbs(to.origin)
	await _move(c, to, 0.14, 0.0)
	_burst(to.origin, UITheme.ACCENT if p == 0 else Color("a08cff"), 1.0 if set_card else 1.6)
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
	await hologram(inst, at, true)


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


func anim_activate(p: int, inst) -> void:
	var c: Card3D
	if p == 0:
		c = _new_card(inst)
		c.transform = _near_camera_xform()
	else:
		c = _take_from_opp_hand(inst)
	var to := Transform3D(table_basis(p, true, true), spell_zone_pos(p, 2) + Vector3(0, 0.02, 0))
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
	var up := Transform3D(Basis(Vector3.UP, 0.0 if p == 0 else PI) * Basis(Vector3.RIGHT, -0.6), spell_zone_pos(p, zone) + Vector3(0, 1.2, 0.3 if p == 0 else -0.3))
	c.set_glow(true, Color("ff4dd2"))
	await _move(c, up, 0.3, 0.2)
	_flash(up.origin, Color("ff4dd2"))
	_burst(up.origin, Color("ff4dd2"), 1.6)
	shake(0.3)
	var tw := create_tween()
	tw.tween_method(c.flash, 3.0, 0.2, Settings.t(0.5))
	await _wait(0.55)


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
	_impact(goal + Vector3(0, 0.15, 0), Color("ff8a5c"))
	await _wait(0.25)
	await _move(c, home, 0.32, 0.3)
	cam_release(0.45)
	c.set_glow(false)


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
	_impact(goal + Vector3(0, 0.15, 0), Color("ff8a5c"))
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
				pair = [_stat_label(), _stat_label(), _stat_label()]
				pair[2].text = "/"
				pair[2].modulate = Color(1, 1, 1, 0.4)
				_stats[m.uid] = pair
			var hidden: bool = not m.face_up and p == 1
			var base: Vector3 = monster_zone_pos(p, state.players[p].field.find(m))
			var off := Vector3(0, 0.08, 0.6)
			pair[0].position = base + off + Vector3(-0.27, 0, 0)
			pair[1].position = base + off + Vector3(0.27, 0, 0)
			pair[2].position = base + off
			var shown_atk := state.atk_of(m, false)
			pair[0].text = "?" if hidden else str(shown_atk)
			if not hidden and shown_atk != m.atk():
				pair[0].modulate = Color("ffd23a") if shown_atk > m.atk() else Color("ff7a7a")
			pair[1].text = "?" if hidden else str(m.def())
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
	for uid in _stats.keys():
		if not seen.has(uid):
			for l in _stats[uid]:
				l.queue_free()
			_stats.erase(uid)


func hide_stats_for(inst) -> void:
	if _stats.has(inst.uid):
		for l in _stats[inst.uid]:
			l.visible = false


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
	if _arrow == null or not _arrow.visible or _aim_from == null or not is_instance_valid(_aim_from):
		return
	var from := _aim_from.global_position + Vector3(0, 0.25, 0)
	var to: Vector3
	if _aim_target and is_instance_valid(_aim_target):
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


func cam_release(dur := 0.5) -> void:
	if _cam_tween:
		_cam_tween.kill()
	_cam_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_cam_tween.tween_property(self, "cam_weight", 0.0, Settings.t(dur))


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
	_shake = move_toward(_shake, 0.0, delta * 1.6)
	var sway := Vector3(sin(_time * 0.35) * 0.06, sin(_time * 0.5) * 0.04, 0)
	var s := _shake * _shake * 0.35
	var jitter := Vector3(_rng.randf_range(-s, s), _rng.randf_range(-s, s), 0)
	var pos := CAM_POS.lerp(cam_pos, cam_weight) + sway * (1.0 - cam_weight) + jitter
	var tgt := CAM_TARGET.lerp(cam_target, cam_weight) + jitter * 0.5
	camera.position = pos
	camera.look_at(tgt)
	_update_arrow()
