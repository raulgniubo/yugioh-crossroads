extends Node3D
## Animated 3D backdrop for the main menu: drifting cards, a glowing duel ring,
## floating motes and a slowly moving camera.

const CARD_COUNT := 26

var _cards: Array[Card3D] = []
var _speeds: Array[Vector3] = []
var _camera: Camera3D
var _ring_a: MeshInstance3D
var _ring_b: MeshInstance3D
var _time := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 7
	_build_environment()
	_build_rings()
	_build_cards()
	_build_motes()


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("04070d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("8fb8ff")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.12
	env.glow_hdr_threshold = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color("0d1b2e")
	env.fog_density = 0.035
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key.light_color = Color("bfe9ff")
	key.light_energy = 0.9
	key.rotation_degrees = Vector3(-35, 25, 0)
	add_child(key)
	var rim := OmniLight3D.new()
	rim.light_color = UITheme.ACCENT
	rim.light_energy = 3.0
	rim.omni_range = 9.0
	rim.position = Vector3(3.5, 0.5, -1.5)
	add_child(rim)
	var violet := OmniLight3D.new()
	violet.light_color = Color("7b5cff")
	violet.light_energy = 2.0
	violet.omni_range = 10.0
	violet.position = Vector3(-4, -2, -3)
	add_child(violet)
	_camera = Camera3D.new()
	_camera.fov = 55
	_camera.position = Vector3(0, 0, 6)
	add_child(_camera)
	_camera.current = true


func _ring(radius: float, thickness: float, color: Color, energy: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = radius - thickness
	t.outer_radius = radius
	t.rings = 96
	t.ring_segments = 8
	mi.mesh = t
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	mi.material_override = m
	add_child(mi)
	return mi


func _build_rings() -> void:
	_ring_a = _ring(2.6, 0.025, UITheme.ACCENT, 3.0)
	_ring_a.position = Vector3(3.2, 0, -2.5)
	_ring_a.rotation_degrees = Vector3(70, 0, 15)
	_ring_b = _ring(1.9, 0.015, UITheme.ACCENT_2, 2.5)
	_ring_b.position = Vector3(3.2, 0, -2.5)
	_ring_b.rotation_degrees = Vector3(60, 30, -10)


func _build_cards() -> void:
	var pool: Array = CardData.CARDS.keys()
	for i in CARD_COUNT:
		var c := Card3D.new()
		c.setup(pool[_rng.randi() % pool.size()])
		c.set_pickable(false)
		c.position = Vector3(_rng.randf_range(-1.0, 9.0), _rng.randf_range(-6.0, 6.0), _rng.randf_range(-9.0, 0.5))
		c.rotation = Vector3(_rng.randf_range(-0.6, 0.6), _rng.randf_range(-1.2, 1.2), _rng.randf_range(-0.5, 0.5))
		var s := _rng.randf_range(0.8, 1.35)
		c.scale = Vector3(s, s, s)
		add_child(c)
		_cards.append(c)
		_speeds.append(Vector3(_rng.randf_range(0.08, 0.22), _rng.randf_range(-0.25, 0.25), _rng.randf_range(-0.15, 0.15)))


func _build_motes() -> void:
	var p := GPUParticles3D.new()
	p.amount = 160
	p.lifetime = 9.0
	p.preprocess = 9.0
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(9, 6, 5)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 25
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.25
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.4
	pm.scale_max = 1.2
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.03, 0.03)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color(0.6, 1.0, 1.0)
	m.emission_enabled = true
	m.emission = UITheme.ACCENT
	m.emission_energy_multiplier = 4.0
	q.material = m
	p.draw_pass_1 = q
	p.position = Vector3(2, 0, -3)
	p.visibility_aabb = AABB(Vector3(-12, -10, -10), Vector3(24, 20, 20))
	add_child(p)


func _process(delta: float) -> void:
	_time += delta
	_camera.position = Vector3(sin(_time * 0.11) * 0.35, cos(_time * 0.09) * 0.2, 6.0)
	_camera.look_at(Vector3(1.2, 0, -2))
	_ring_a.rotate_object_local(Vector3.UP, delta * 0.25)
	_ring_b.rotate_object_local(Vector3.UP, -delta * 0.18)
	for i in _cards.size():
		var c := _cards[i]
		var v := _speeds[i]
		c.position.y += v.x * delta
		c.rotate_y(v.y * delta)
		c.rotate_x(v.z * delta * 0.5)
		if c.position.y > 6.5:
			c.position.y = -6.5
			c.position.x = _rng.randf_range(-1.0, 9.0)
