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

var camera: Camera3D
var _cards := {}  # uid -> Card3D
var _gy_cards: Array = [[], []]
var _opp_hand: Array[Card3D] = []
var _deck_piles: Array[Node3D] = []
var _deck_labels: Array[Label3D] = []
var _shake := 0.0
var _time := 0.0
var _zone_shader: Shader
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_build_environment()
	_build_mat()
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


## Orientation for a card lying on the table.
func table_basis(p: int, face_up: bool, attack_pos: bool) -> Basis:
	var yaw := 0.0 if p == 0 else PI
	if not attack_pos:
		yaw += PI / 2.0
	var pitch := -PI / 2.0 if face_up else PI / 2.0
	return Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)


# ------------------------------------------------------------------ build

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("03060b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a9c8ff")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 1.0
	env.fog_enabled = true
	env.fog_light_color = Color("08111f")
	env.fog_density = 0.02
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
		l.light_color = UITheme.ACCENT if side == 1 else Color("7b5cff")
		l.light_energy = 1.6
		l.omni_range = 7.0
		l.position = Vector3(5.5 * side, 1.5, -1.5 * side)
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
void fragment() {
	vec2 p = (UV - 0.5) * vec2(12.0, 7.6);
	vec2 gp = p * 2.0;
	vec2 g = abs(fract(gp) - 0.5) / fwidth(gp);
	float grid = 1.0 - min(min(g.x, g.y), 1.0);
	float r = length(p);
	float ring = 1.0 - smoothstep(0.0, 0.035, abs(r - 1.25));
	float ring2 = 1.0 - smoothstep(0.0, 0.02, abs(r - 1.55));
	float mid = 1.0 - smoothstep(0.0, 0.03, abs(p.y));
	float vig = smoothstep(7.0, 0.5, length(p * vec2(0.75, 1.15)));
	vec3 side = mix(accent, accent2, step(0.0, -p.y));
	vec3 col = base * (0.5 + 0.8 * vig);
	col += accent * grid * 0.035 * vig;
	col += side * (ring * 0.45 + ring2 * 0.2);
	col += mix(accent, accent2, 0.5) * mid * 0.3 * vig;
	ALBEDO = col;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	mi.material_override = m
	add_child(mi)


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
		var col := UITheme.ACCENT if p == 0 else Color("8a6dff")
		for z in 5:
			_zone(monster_zone_pos(p, z), Vector2(0.98, 0.98), col, 0.9)
			_zone(spell_zone_pos(p, z), Vector2(0.72, 0.98), col, 0.45)
		_zone(deck_pos(p), Vector2(0.72, 0.98), col, 0.6)
		_zone(gy_pos(p), Vector2(0.72, 0.98), col, 0.6)


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
	await _move(c, to, 0.14, 0.0)
	_burst(to.origin, UITheme.ACCENT if p == 0 else Color("a08cff"), 1.0 if set_card else 1.6)
	shake(0.12 if set_card else 0.25)
	if not set_card:
		await hologram(inst, to.origin)


func hologram(inst, at: Vector3, force_big := false) -> void:
	var big: bool = force_big or int(inst.data.get("level", 0)) >= 7
	var art := Cards.get_art(inst.id)
	var spr := Sprite3D.new()
	spr.texture = art
	spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	spr.shaded = false
	var h := 2.4 if big else 1.6
	spr.pixel_size = h / maxf(1.0, art.get_height())
	spr.position = at + Vector3(0, h * 0.55, 0)
	spr.modulate = Color(1.1, 1.2, 1.3, 0.0)
	spr.scale = Vector3(0.2, 0.2, 0.2)
	add_child(spr)
	var beam := _beam(at, big)
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, "scale", Vector3.ONE, Settings.t(0.35))
	tw.tween_property(spr, "modulate:a", 0.95, Settings.t(0.2))
	await tw.finished
	if big:
		shake(0.35)
	await _wait(0.75 if big else 0.4)
	var tw2 := create_tween().set_parallel()
	tw2.tween_property(spr, "modulate:a", 0.0, Settings.t(0.3))
	tw2.tween_property(spr, "position:y", spr.position.y - h * 0.4, Settings.t(0.3))
	tw2.tween_property(spr, "scale", Vector3(0.6, 0.6, 0.6), Settings.t(0.3))
	tw2.tween_property(beam, "scale:x", 0.01, Settings.t(0.3))
	tw2.tween_property(beam, "scale:z", 0.01, Settings.t(0.3))
	await tw2.finished
	spr.queue_free()
	beam.queue_free()


func _beam(at: Vector3, big: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.55 if big else 0.4
	cyl.bottom_radius = 0.45 if big else 0.32
	cyl.height = 5.0
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
	mi.position = at + Vector3(0, 2.5, 0)
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


func anim_tribute(inst) -> void:
	var c := card_for(inst)
	if c == null:
		return
	c.set_glow(true, UITheme.GOLD)
	var tw := create_tween().set_parallel()
	tw.tween_property(c, "position:y", 0.9, Settings.t(0.35))
	tw.tween_method(c.set_alpha, 1.0, 0.0, Settings.t(0.35))
	await tw.finished
	_cards.erase(inst.uid)
	c.queue_free()
	_add_to_gy(inst)


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
	await _move(c, lift, 0.2, 0.0)
	var hit := Transform3D(home.basis, home.origin.lerp(goal, 0.82) + Vector3(0, 0.25, 0))
	await _move(c, hit, 0.14, 0.15)
	_burst(goal + Vector3(0, 0.1, 0), Color("ff8a5c"), 1.3)
	shake(0.4)
	await _move(c, home, 0.32, 0.3)


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
	var tw2 := create_tween().set_parallel()
	tw2.tween_property(c, "position:y", 1.2, Settings.t(0.35))
	tw2.tween_property(c, "scale", Vector3(1.25, 1.25, 1.25), Settings.t(0.35))
	tw2.tween_method(c.set_alpha, 1.0, 0.0, Settings.t(0.35))
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
	var p: int = inst.owner
	var c := Card3D.new()
	c.setup(inst.id)
	c.inst = inst
	c.set_pickable(true)
	c.hovered.connect(func(card, inside): card_hovered.emit(card, inside))
	add_child(c)
	var pile: Array = _gy_cards[p]
	var y := 0.02 + pile.size() * 0.004
	var jitter := _rng.randf_range(-0.06, 0.06)
	c.transform = Transform3D(table_basis(p, true, true) * Basis(Vector3.BACK, jitter), gy_pos(p) + Vector3(0, y, 0))
	pile.append(c)
	if pile.size() > 5:
		var old: Card3D = pile.pop_front()
		old.queue_free()


# ------------------------------------------------------------------ camera

func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _process(delta: float) -> void:
	_time += delta
	_shake = move_toward(_shake, 0.0, delta * 1.6)
	var sway := Vector3(sin(_time * 0.35) * 0.06, sin(_time * 0.5) * 0.04, 0)
	var s := _shake * _shake * 0.35
	var jitter := Vector3(_rng.randf_range(-s, s), _rng.randf_range(-s, s), 0)
	camera.position = CAM_POS + sway + jitter
	camera.look_at(CAM_TARGET + jitter * 0.5)
