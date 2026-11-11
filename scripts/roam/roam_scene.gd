extends Node3D
## Free roam: walk a district, talk to people, take on street duels.

const SPEED := 4.2
const RUN := 7.5
const TALK_RANGE := 2.6
const SAVE_PATH := "user://roam.cfg"

var district: Dictionary
var _player: CharacterBody3D
var _figure: RoamFigure
var _pivot: Node3D
var _arm: SpringArm3D
var _cam: Camera3D
var _yaw := 0.0
var _pitch := -0.32
var _npcs: Array = []  # [data, figure, marker]
var _near: Dictionary = {}
var _beaten := {}
var _dragging := false

# UI
var _ui: CanvasLayer
var _prompt: Label
var _dlg: PanelContainer
var _dlg_name: Label
var _dlg_text: Label
var _dlg_buttons: HBoxContainer
var _dlg_lines: Array = []
var _dlg_index := 0
var _dlg_npc: Dictionary = {}
var _talking := false
var _pause: Control
var _counter: Label
var _theme: Dictionary


func _ready() -> void:
	district = RoamData.district(Router.roam.get("district", "domino"))
	_theme = FieldThemes.resolve(district.get("theme", "battlecity"), "")
	_load_progress()
	_build_world()
	_build_player()
	_build_npcs()
	_build_ui()
	Music.play("menu")
	_after_duel()
	_debug()


# ------------------------------------------------------------------ progress

func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		_beaten = cfg.get_value("roam", "beaten", {})


func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("roam", "beaten", _beaten)
	cfg.save(SAVE_PATH)


func _after_duel() -> void:
	var who: String = Router.roam.get("last_duel", "")
	if who == "":
		return
	var won := Router.story_result == "won"
	Router.roam["last_duel"] = ""
	Router.story_result = ""
	for n in _npcs:
		if n[0]["id"] == who:
			if won:
				_beaten[who] = true
				_save_progress()
				_refresh_marker(n)
			var name: String = _npc_name(n[0])
			await get_tree().create_timer(0.8).timeout
			Router.toast(("You beat %s!" % name) if won else ("%s wins this time. Try again!" % name))
	_update_counter()


# ------------------------------------------------------------------ world

func _mat(c: Color, rough := 0.8, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _box(size: Vector3, pos: Vector3, mat: Material, solid := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	if solid:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		body.add_child(cs)
		body.position = pos
		add_child(body)
	return mi


func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = _theme["sky_top"]
	sm.sky_horizon_color = (_theme["sky_horizon"] as Color).lightened(0.15)
	sm.ground_horizon_color = _theme["sky_horizon"]
	sm.ground_bottom_color = Color(0.02, 0.02, 0.04)
	sm.sun_angle_max = 20
	sky.sky_material = sm
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 1.4
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.glow_enabled = true
	e.glow_intensity = 0.9
	e.glow_bloom = 0.15
	e.fog_enabled = true
	e.fog_light_color = _theme["fog"]
	e.fog_density = 0.012
	e.ssao_enabled = true
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.75, 0.6)
	sun.light_energy = 1.0
	sun.rotation_degrees = Vector3(-28, -35, 0)
	sun.shadow_enabled = true
	add_child(sun)

	# Ground: asphalt roads crossing at the plaza, sidewalks around them.
	_box(Vector3(120, 0.2, 120), Vector3(0, -0.1, 0), _mat(Color(0.07, 0.07, 0.09), 0.9))
	var walk := _mat(Color(0.32, 0.31, 0.34), 0.85)
	for qx in [-1, 1]:
		for qz in [-1, 1]:
			_box(Vector3(30, 0.16, 30), Vector3(qx * 21.0, 0.08, qz * 21.0), walk, false)
	# Lane markings and crosswalks.
	var paint := _mat(Color(0.9, 0.9, 0.85), 0.6)
	for i in range(-5, 6):
		if absi(i) <= 1:
			continue
		_box(Vector3(2.2, 0.02, 0.18), Vector3(i * 5.0, 0.01, 0), paint, false)
		_box(Vector3(0.18, 0.02, 2.2), Vector3(0, 0.01, i * 5.0), paint, false)
	for k in range(-4, 5):
		for side in [-1, 1]:
			_box(Vector3(0.5, 0.02, 2.4), Vector3(k * 1.0, 0.01, side * 5.2), paint, false)
			_box(Vector3(2.4, 0.02, 0.5), Vector3(side * 5.2, 0.01, k * 1.0), paint, false)
	# Plaza: a big duel emblem on the crossing.
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 2.6
	tm.outer_radius = 2.8
	ring.mesh = tm
	var rm := _mat(_theme["accent"])
	rm.emission_enabled = true
	rm.emission = _theme["accent"]
	rm.emission_energy_multiplier = 2.0
	ring.material_override = rm
	ring.scale = Vector3(1, 0.05, 1)
	ring.position.y = 0.02
	add_child(ring)

	_build_blocks()
	_build_landmarks()
	_build_lamps()
	# Invisible walls keep you in the district.
	var wall := StandardMaterial3D.new()
	wall.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wall.albedo_color = Color(0, 0, 0, 0)
	for side in [-1, 1]:
		_box(Vector3(80, 6, 1), Vector3(0, 3, side * 34.0), wall)
		_box(Vector3(1, 6, 80), Vector3(side * 34.0, 3, 0), wall)


func _window_material(tint: Color, seed: float) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
uniform vec4 wall : source_color = vec4(0.12, 0.12, 0.16, 1.0);
uniform vec4 glow : source_color = vec4(1.0, 0.8, 0.5, 1.0);
uniform float seed = 0.0;
varying vec3 wp;
varying vec3 wn;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233)) + seed) * 43758.5453); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); }
void fragment() {
	float u = abs(wn.x) > 0.5 ? wp.z : wp.x;
	vec2 cell = floor(vec2(u / 1.6, wp.y / 2.4));
	vec2 f = fract(vec2(u / 1.6, wp.y / 2.4));
	float win = step(0.18, f.x) * step(f.x, 0.82) * step(0.3, f.y) * step(f.y, 0.8);
	if (abs(wn.y) > 0.5 || wp.y < 2.2) { win = 0.0; }
	float lit = step(0.52, h(cell));
	ALBEDO = mix(wall.rgb, vec3(0.05, 0.07, 0.1), win);
	ROUGHNESS = mix(0.85, 0.2, win);
	METALLIC = win * 0.4;
	EMISSION = glow.rgb * win * lit * (0.8 + h(cell + 3.1) * 1.6);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("wall", tint)
	m.set_shader_parameter("seed", seed)
	m.set_shader_parameter("glow", Color(1.0, 0.82, 0.55).lerp(_theme["accent2"], 0.25))
	return m


func _build_blocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1999
	var tints := [Color(0.16, 0.15, 0.2), Color(0.22, 0.18, 0.18), Color(0.13, 0.17, 0.22), Color(0.2, 0.2, 0.22)]
	# Buildings line the outer edge of each block, leaving the inner sidewalks open.
	for qx in [-1, 1]:
		for qz in [-1, 1]:
			for i in 4:
				var along := -12.0 + i * 8.0
				for row in [0, 1]:
					var h := rng.randf_range(8.0, 26.0)
					var w := rng.randf_range(6.0, 7.6)
					var x: float
					var z: float
					if row == 0:  # back row along X
						x = qx * (21.0 + along * 0.0) + along
						z = qz * 32.0
					else:  # side row along Z
						x = qx * 32.0
						z = qz * 21.0 + along
					var m := _window_material(tints[rng.randi() % tints.size()], rng.randf() * 100.0)
					_box(Vector3(w, h, w), Vector3(x, h / 2.0, z), m)


func _sign(text: String, pos: Vector3, color: Color, size := 120, rot := 0.0) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.outline_size = 0
	l.modulate = color
	l.position = pos
	l.rotation.y = rot
	l.shaded = false
	l.double_sided = true
	l.font = load("res://assets/fonts/Rajdhani-SemiBold.ttf")
	add_child(l)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.5
	light.omni_range = 7.0
	light.position = pos + Vector3(0, 0, 1.0).rotated(Vector3.UP, rot)
	add_child(light)
	return l


func _build_landmarks() -> void:
	# Kame Game: the little shop on the corner.
	var shop := _mat(Color(0.55, 0.42, 0.3), 0.8)
	_box(Vector3(9, 6, 6), Vector3(-10, 3, -19), shop)
	_box(Vector3(9.6, 0.4, 6.6), Vector3(-10, 6.2, -19), _mat(Color(0.3, 0.18, 0.12)))
	var glass := _mat(Color(0.5, 0.75, 0.9), 0.1, 0.3)
	glass.emission_enabled = true
	glass.emission = Color(1.0, 0.85, 0.6)
	glass.emission_energy_multiplier = 0.8
	_box(Vector3(5, 2.6, 0.1), Vector3(-10, 1.5, -15.95), glass, false)
	var awning := _mat(Color(0.75, 0.15, 0.2), 0.7)
	var aw := _box(Vector3(7, 0.12, 1.6), Vector3(-10, 3.2, -15.4), awning, false)
	aw.rotation.x = 0.25
	_sign("KAME GAME", Vector3(-10, 4.4, -15.9), Color("ffd166"), 140)
	# KaibaCorp Tower looms at the end of the main street.
	var tower := _window_material(Color(0.2, 0.26, 0.38), 7.0)
	_box(Vector3(14, 70, 14), Vector3(0, 35, -46), tower)
	_box(Vector3(18, 4, 18), Vector3(0, 2, -46), _mat(Color(0.75, 0.8, 0.88), 0.3, 0.6))
	_sign("KC", Vector3(0, 60, -38.9), Color("7cc4ff"), 1100)
	# Park corner: grass, trees and a fountain with a hologram.
	var grass := _mat(Color(0.12, 0.24, 0.12), 0.95)
	_box(Vector3(22, 0.2, 22), Vector3(19, 0.1, 19), grass, false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 7:
		var p := Vector3(rng.randf_range(10, 28), 0, rng.randf_range(10, 28))
		if p.distance_to(Vector3(19, 0, 19)) < 4.5 or p.distance_to(Vector3(12, 0, 6)) < 3.0:
			continue
		_tree(p, rng.randf_range(0.8, 1.3))
	var basin := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 2.6
	cyl.bottom_radius = 2.8
	cyl.height = 0.6
	basin.mesh = cyl
	basin.material_override = _mat(Color(0.6, 0.6, 0.65), 0.6)
	basin.position = Vector3(19, 0.3, 19)
	add_child(basin)
	var water := _box(Vector3(4.6, 0.05, 4.6), Vector3(19, 0.58, 19), _mat(Color(0.2, 0.5, 0.7), 0.05, 0.2), false)
	water.mesh = CylinderMesh.new()
	(water.mesh as CylinderMesh).top_radius = 2.4
	(water.mesh as CylinderMesh).bottom_radius = 2.4
	(water.mesh as CylinderMesh).height = 0.05
	var col := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shp := CylinderShape3D.new()
	shp.radius = 2.8
	shp.height = 1.2
	cs.shape = shp
	col.add_child(cs)
	col.position = Vector3(19, 0.6, 19)
	add_child(col)
	# A slowly spinning card hologram above the fountain.
	var holo := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.6, 2.3)
	holo.mesh = q
	var hm := StandardMaterial3D.new()
	hm.albedo_texture = Cards.get_back()
	hm.albedo_color = Color(_theme["accent"], 0.75)
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.emission_enabled = true
	hm.emission = _theme["accent"]
	hm.emission_energy_multiplier = 1.4
	hm.cull_mode = BaseMaterial3D.CULL_DISABLED
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	holo.material_override = hm
	holo.position = Vector3(19, 2.6, 19)
	holo.name = "Holo"
	add_child(holo)
	var hl := OmniLight3D.new()
	hl.light_color = _theme["accent"]
	hl.light_energy = 2.0
	hl.omni_range = 8.0
	hl.position = Vector3(19, 2.2, 19)
	add_child(hl)
	# Big screen on a building: Battle City ads.
	_sign("BATTLE CITY", Vector3(-31.4, 14, 14), _theme["accent"], 260, PI / 2)
	_sign("DUEL DISK  ·  NOW ONLINE", Vector3(31.4, 10, -14), _theme["accent2"], 150, -PI / 2)


func _tree(p: Vector3, s: float) -> void:
	var trunk := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.15 * s
	c.bottom_radius = 0.22 * s
	c.height = 2.0 * s
	trunk.mesh = c
	trunk.material_override = _mat(Color(0.3, 0.2, 0.12))
	trunk.position = p + Vector3(0, s, 0)
	add_child(trunk)
	var top := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 1.4 * s
	sp.height = 2.6 * s
	top.mesh = sp
	top.material_override = _mat(Color(0.14, 0.32, 0.16), 0.9)
	top.position = p + Vector3(0, 2.8 * s, 0)
	add_child(top)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.3 * s
	sh.height = 3.0
	cs.shape = sh
	body.add_child(cs)
	body.position = p + Vector3(0, 1.5, 0)
	add_child(body)


func _build_lamps() -> void:
	var pole := _mat(Color(0.2, 0.21, 0.24), 0.4, 0.7)
	var bulb := _mat(Color(1, 0.9, 0.7))
	bulb.emission_enabled = true
	bulb.emission = Color(1.0, 0.85, 0.6)
	bulb.emission_energy_multiplier = 4.0
	for p in [Vector3(6.2, 0, 12), Vector3(-6.2, 0, -12), Vector3(6.2, 0, -24), Vector3(-6.2, 0, 24), Vector3(12, 0, -6.2), Vector3(-24, 0, 6.2), Vector3(24, 0, -6.2), Vector3(-12, 0, 6.2)]:
		_box(Vector3(0.18, 5, 0.18), p + Vector3(0, 2.5, 0), pole)
		_box(Vector3(0.6, 0.25, 0.6), p + Vector3(0, 5.1, 0), bulb, false)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.82, 0.6)
		l.light_energy = 2.2
		l.omni_range = 11.0
		l.position = p + Vector3(0, 4.8, 0)
		add_child(l)


# ------------------------------------------------------------------ player & camera

func _build_player() -> void:
	_player = CharacterBody3D.new()
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	cs.shape = cap
	cs.position.y = 0.85
	_player.add_child(cs)
	add_child(_player)
	var start = Router.roam.get("pos")
	_player.position = start if start is Vector3 else Vector3(0, 0, 8)
	_figure = RoamFigure.new()
	_player.add_child(_figure)
	_figure.setup("player", Profile.color(), "", false)
	_yaw = float(Router.roam.get("yaw", PI))
	_figure.rotation.y = _yaw + PI
	_pivot = Node3D.new()
	add_child(_pivot)
	_arm = SpringArm3D.new()
	_arm.spring_length = 5.2
	_arm.margin = 0.3
	var sh := SphereShape3D.new()
	sh.radius = 0.25
	_arm.shape = sh
	_arm.add_excluded_object(_player.get_rid())
	_pivot.add_child(_arm)
	_cam = Camera3D.new()
	_cam.fov = 60
	_arm.add_child(_cam)
	_cam.current = true


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	if not _talking and _pause == null:
		if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
			input.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
			input.y += 1
		if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
			input.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
			input.x += 1
		var stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
		if stick.length() > 0.2:
			input = stick
		var look := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
		if absf(look) > 0.2:
			_yaw -= look * delta * 2.5
		if Input.is_key_pressed(KEY_Q):
			_yaw += delta * 2.0
	input = input.limit_length(1.0)
	var run := Input.is_key_pressed(KEY_SHIFT) or Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER)
	var basis := Basis(Vector3.UP, _yaw)
	var dir := basis * Vector3(input.x, 0, input.y)
	var target := dir * (RUN if run else SPEED)
	_player.velocity.x = lerpf(_player.velocity.x, target.x, 1.0 - exp(-delta * 12.0))
	_player.velocity.z = lerpf(_player.velocity.z, target.z, 1.0 - exp(-delta * 12.0))
	_player.velocity.y = 0.0 if _player.is_on_floor() else _player.velocity.y - 20.0 * delta
	_player.move_and_slide()
	var flat := Vector2(_player.velocity.x, _player.velocity.z)
	_figure.set_speed(flat.length())
	if flat.length() > 0.3:
		var want := atan2(flat.x, flat.y)
		_figure.rotation.y = lerp_angle(_figure.rotation.y, want, 1.0 - exp(-delta * 12.0))
	_pivot.position = _pivot.position.lerp(_player.position + Vector3(0, 1.45, 0), 1.0 - exp(-delta * 10.0))
	_pivot.rotation = Vector3(_pitch, _yaw, 0)
	var holo := get_node_or_null("Holo")
	if holo:
		holo.rotation.y += delta * 0.8
	_update_near()


func _unhandled_input(event: InputEvent) -> void:
	if _pause:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause"):
			_close_pause()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_arm.spring_length = maxf(2.5, _arm.spring_length - 0.4)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_arm.spring_length = minf(9.0, _arm.spring_length + 0.4)
	elif event is InputEventMouseMotion and _dragging and not _talking:
		_yaw -= event.relative.x * 0.006
		_pitch = clampf(_pitch - event.relative.y * 0.004, -1.1, 0.15)
	if _talking:
		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_E, KEY_SPACE]):
			if _dlg_buttons.get_child_count() == 0:
				_advance()
				get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_talk()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A):
		_talk()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause"):
		_open_pause()
		get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ NPCs

func _npc_name(d: Dictionary) -> String:
	if d.get("name", "") != "":
		return d["name"]
	return Characters.get_char(d.get("char", "")).get("name", "Duelist")


func _npc_color(d: Dictionary) -> Color:
	if d.has("color"):
		return d["color"]
	return Characters.get_char(d.get("char", "")).get("color", Color.WHITE)


func _build_npcs() -> void:
	for d in district.get("npcs", []):
		var f := RoamFigure.new()
		add_child(f)
		f.position = d["pos"]
		f.rotation.y = d.get("face", 0.0)
		var model_key: String = d.get("char", "")
		if model_key == "":
			model_key = d["id"]
		f.setup(model_key, _npc_color(d), _npc_name(d))
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 0.35
		cap.height = 1.7
		cs.shape = cap
		cs.position.y = 0.85
		body.add_child(cs)
		f.add_child(body)
		var marker := Label3D.new()
		marker.font_size = 90
		marker.outline_size = 14
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.position = Vector3(0, 2.45, 0)
		marker.font = load("res://assets/fonts/Rajdhani-SemiBold.ttf")
		f.add_child(marker)
		var entry := [d, f, marker]
		_npcs.append(entry)
		_refresh_marker(entry)


func _refresh_marker(n: Array) -> void:
	var d: Dictionary = n[0]
	var m: Label3D = n[2]
	if not d.has("duel"):
		m.text = "…"
		m.modulate = Color(1, 1, 1, 0.8)
	elif _beaten.has(d["id"]):
		m.text = "✓"
		m.modulate = Color("5cf2a0")
	else:
		m.text = "!"
		m.modulate = Color("ffd166")


func _update_near() -> void:
	var best: Dictionary = {}
	var best_d := TALK_RANGE
	for n in _npcs:
		var f: Node3D = n[1]
		var dist := f.global_position.distance_to(_player.global_position)
		var m: Label3D = n[2]
		m.position.y = 2.45 + sin(Time.get_ticks_msec() / 300.0) * 0.06
		if dist < best_d:
			best_d = dist
			best = n[0]
	_near = best
	if _prompt:
		_prompt.visible = not _near.is_empty() and not _talking and _pause == null
		if _prompt.visible:
			_prompt.text = "E   Talk to %s" % _npc_name(_near)


func _talk() -> void:
	if _near.is_empty() or _talking:
		return
	var d := _near
	_dlg_npc = d
	_talking = true
	_dlg_lines = []
	for l in d.get("lines", []):
		_dlg_lines.append(str(l).replace("{player}", Profile.duelist_name))
	if d.has("duel"):
		var duel: Dictionary = d["duel"]
		if _beaten.has(d["id"]):
			_dlg_lines.append("Rematch? I won't go easy on you this time.")
		else:
			_dlg_lines.append("So? Are we dueling or what?")
	_dlg_index = 0
	# Turn to face each other.
	for n in _npcs:
		if n[0] == d:
			var f: Node3D = n[1]
			var to := _player.global_position - f.global_position
			create_tween().tween_property(f, "rotation:y", atan2(to.x, to.z), 0.3)
			var back := f.global_position - _player.global_position
			create_tween().tween_property(_figure, "rotation:y", atan2(back.x, back.z), 0.3)
			# Over-the-shoulder framing for the conversation.
			var want_yaw := atan2(to.x, to.z) + 0.6
			create_tween().tween_property(self, "_yaw", _yaw + wrapf(want_yaw - _yaw, -PI, PI), 0.45).set_trans(Tween.TRANS_SINE)
	_dlg.visible = true
	_dlg_name.text = _npc_name(d).to_upper()
	_dlg_name.add_theme_color_override("font_color", _npc_color(d).lightened(0.3))
	_show_line()
	Sfx.play("click")


func _show_line() -> void:
	for c in _dlg_buttons.get_children():
		c.queue_free()
	_dlg_text.text = _dlg_lines[_dlg_index]
	_dlg_text.visible_ratio = 0.0
	create_tween().tween_property(_dlg_text, "visible_ratio", 1.0, 0.02 * _dlg_text.text.length())
	var last := _dlg_index == _dlg_lines.size() - 1
	if last and _dlg_npc.has("duel"):
		var duel_btn := Button.new()
		duel_btn.text = "  Duel!  "
		duel_btn.add_theme_font_size_override("font_size", 26)
		duel_btn.pressed.connect(_start_duel)
		_dlg_buttons.add_child(duel_btn)
		var later := Button.new()
		later.text = "  Not now  "
		later.add_theme_font_size_override("font_size", 26)
		later.pressed.connect(_end_talk)
		_dlg_buttons.add_child(later)
		duel_btn.grab_focus.call_deferred()


func _advance() -> void:
	if _dlg_text.visible_ratio < 1.0:
		_dlg_text.visible_ratio = 1.0
		return
	if _dlg_index + 1 < _dlg_lines.size():
		_dlg_index += 1
		_show_line()
	else:
		_end_talk()


func _end_talk() -> void:
	_talking = false
	_dlg.visible = false
	for c in _dlg_buttons.get_children():
		c.queue_free()


func _start_duel() -> void:
	var d := _dlg_npc
	var duel: Dictionary = d["duel"]
	Router.roam["pos"] = _player.position
	Router.roam["yaw"] = _yaw
	Router.roam["last_duel"] = d["id"]
	var opp_key: String = d.get("char", "")
	if opp_key == "":
		opp_key = d["id"]
	Router.duel_config = {
		"opponent": opp_key, "opponent_deck": duel.get("deck", "joey"),
		"player_deck": Router.duel_config.get("player_deck", "echo"), "player_char": "player",
		"difficulty": duel.get("difficulty", 1), "field": district.get("theme", "battlecity"),
		"story": true, "lose_ok": true, "return_to": Router.ROAM, "continue_label": "Back to %s" % district.get("name", "town"),
	}
	_end_talk()
	Router.go(Router.DUEL)


# ------------------------------------------------------------------ UI

func _build_ui() -> void:
	_ui = CanvasLayer.new()
	add_child(_ui)
	# Location card, top left.
	var loc := VBoxContainer.new()
	loc.position = Vector2(48, 36)
	_ui.add_child(loc)
	loc.add_child(UITheme.label(district.get("name", "").to_upper(), 46, Color.WHITE, UITheme.title_font()))
	loc.add_child(UITheme.label(district.get("area", ""), 22, _theme["accent"], UITheme.semi_font()))
	_counter = UITheme.label("", 20, UITheme.TEXT_DIM)
	loc.add_child(_counter)
	_update_counter()
	# Controls, bottom left.
	var help := UITheme.label("WASD / stick  move     Shift  run     Drag  look     Scroll  zoom     E  talk     Esc  menu", 18, Color(1, 1, 1, 0.5))
	help.anchor_top = 1.0
	help.anchor_bottom = 1.0
	help.position = Vector2(48, -50)
	help.offset_top = -50
	help.offset_left = 48
	_ui.add_child(help)
	# Talk prompt.
	_prompt = Label.new()
	_prompt.add_theme_font_override("font", UITheme.semi_font())
	_prompt.add_theme_font_size_override("font_size", 30)
	var sb := UITheme.panel_box(Color(0.03, 0.06, 0.1, 0.9), 14, Color(UITheme.ACCENT, 0.6))
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	_prompt.add_theme_stylebox_override("normal", sb)
	_prompt.anchor_left = 0.5
	_prompt.anchor_right = 0.5
	_prompt.anchor_top = 1.0
	_prompt.anchor_bottom = 1.0
	_prompt.offset_top = -200
	_prompt.offset_left = -200
	_prompt.offset_right = 200
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.visible = false
	_ui.add_child(_prompt)
	# Dialogue box.
	_dlg = PanelContainer.new()
	_dlg.add_theme_stylebox_override("panel", UITheme.panel_box(Color(0.03, 0.05, 0.09, 0.94), 22, Color(UITheme.ACCENT, 0.4)))
	_dlg.anchor_left = 0.5
	_dlg.anchor_right = 0.5
	_dlg.anchor_top = 1.0
	_dlg.anchor_bottom = 1.0
	_dlg.offset_left = -620
	_dlg.offset_right = 620
	_dlg.offset_top = -290
	_dlg.offset_bottom = -60
	_dlg.visible = false
	_ui.add_child(_dlg)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_dlg.add_child(v)
	_dlg_name = UITheme.label("", 28, UITheme.ACCENT, UITheme.title_font())
	v.add_child(_dlg_name)
	_dlg_text = UITheme.label("", 30, Color.WHITE)
	_dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dlg_text.custom_minimum_size = Vector2(1180, 90)
	v.add_child(_dlg_text)
	_dlg_buttons = HBoxContainer.new()
	_dlg_buttons.add_theme_constant_override("separation", 14)
	_dlg_buttons.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(_dlg_buttons)


func _update_counter() -> void:
	if _counter == null:
		return
	var total := 0
	var won := 0
	for d in district.get("npcs", []):
		if d.has("duel"):
			total += 1
			if _beaten.has(d["id"]):
				won += 1
	_counter.text = "Street duels won  %d / %d" % [won, total]


func _open_pause() -> void:
	_pause = Control.new()
	_pause.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause.add_child(dim)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause.add_child(c)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	c.add_child(v)
	v.add_child(UITheme.label("PAUSED", 64, Color.WHITE, UITheme.title_font()))
	var resume := Button.new()
	resume.text = "Resume"
	resume.custom_minimum_size = Vector2(320, 60)
	resume.pressed.connect(_close_pause)
	v.add_child(resume)
	var menu := Button.new()
	menu.text = "Main Menu"
	menu.custom_minimum_size = Vector2(320, 60)
	menu.pressed.connect(func():
		Router.roam["pos"] = _player.position
		Router.roam["yaw"] = _yaw
		Router.go(Router.MAIN_MENU))
	v.add_child(menu)
	_ui.add_child(_pause)
	resume.grab_focus()


func _close_pause() -> void:
	if _pause:
		_pause.queue_free()
		_pause = null


# ------------------------------------------------------------------ debug

func _debug() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--roam-talk="):
			var who := a.substr(12)
			await get_tree().create_timer(1.0).timeout
			for n in _npcs:
				if n[0]["id"] == who:
					var f: Node3D = n[1]
					var fwd := Vector3(0, 0, 1).rotated(Vector3.UP, f.rotation.y)
					_player.position = f.position + fwd * 2.0
					_yaw = atan2(fwd.x, fwd.z)
					_pivot.position = _player.position + Vector3(0, 1.45, 0)
			await get_tree().create_timer(0.5).timeout
			_update_near()
			_talk()
			for i in 2:
				await get_tree().create_timer(0.4).timeout
				_advance()
		elif a == "--roam-walk":
			await get_tree().create_timer(0.5).timeout
			_yaw = PI * 0.8
			Input.action_press("ui_up")
