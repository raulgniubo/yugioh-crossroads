class_name Weather
extends Node3D
## Rain: streaks falling around the camera, splash rings on the ground, a darker and hazier
## sky, and the hiss of it. It rains on some visits and not others; indoors you only hear it.

var scene: Node
var city: CityBuilder
var raining := false
var _drops: GPUParticles3D
var _splash: GPUParticles3D
var _hiss: AudioStreamPlayer
var _dimmed := ""
var _base := {}


func setup(roam: Node) -> void:
	scene = roam
	city = roam.city
	var args := OS.get_cmdline_user_args()
	var t := Time.get_datetime_dict_from_system()
	var roll := absi(hash("%s-%d-%d-%s" % [Time.get_date_string_from_system(), int(t["hour"]) / 3, 7, str(Router.roam.get("district", ""))])) % 100
	raining = "--rain" in args or (roll < 28 and not "--dry" in args and str(Router.roam.get("story", "")) == "")
	if not raining:
		return
	_drops = GPUParticles3D.new()
	_drops.amount = 900
	_drops.lifetime = 0.9
	_drops.preprocess = 0.9
	_drops.visibility_aabb = AABB(Vector3(-30, -20, -30), Vector3(60, 40, 60))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(16, 0.5, 16)
	pm.direction = Vector3(0.12, -1, 0.05)
	pm.spread = 2.0
	pm.initial_velocity_min = 17.0
	pm.initial_velocity_max = 21.0
	pm.gravity = Vector3(0, -6.0, 0)
	_drops.process_material = pm
	var streak := BoxMesh.new()
	streak.size = Vector3(0.014, 0.5, 0.014)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.albedo_color = Color(0.78, 0.86, 1.0, 0.34)
	streak.material = sm
	_drops.draw_pass_1 = streak
	_drops.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_drops)
	# Rings where drops land, just above the ground around the player.
	_splash = GPUParticles3D.new()
	_splash.amount = 110
	_splash.lifetime = 0.45
	_splash.visibility_aabb = AABB(Vector3(-20, -2, -20), Vector3(40, 4, 40))
	var sp := ParticleProcessMaterial.new()
	sp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	sp.emission_box_extents = Vector3(11, 0.0, 11)
	sp.gravity = Vector3.ZERO
	sp.scale_min = 0.3
	sp.scale_max = 1.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.2))
	curve.add_point(Vector2(1, 1.0))
	var ct := CurveTexture.new()
	ct.curve = curve
	sp.scale_curve = ct
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.5))
	grad.set_color(1, Color(1, 1, 1, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	sp.color_ramp = gt
	_splash.process_material = sp
	var ring := TorusMesh.new()
	ring.inner_radius = 0.1
	ring.outer_radius = 0.13
	ring.rings = 10
	ring.ring_segments = 3
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.vertex_color_use_as_albedo = true
	rm.albedo_color = Color(0.85, 0.92, 1.0, 0.5)
	ring.material = rm
	_splash.draw_pass_1 = ring
	_splash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_splash)
	_hiss = AudioStreamPlayer.new()
	_hiss.bus = "SFX"
	_hiss.volume_db = -19.0
	_hiss.pitch_scale = 1.35
	add_child(_hiss)
	Router.toast.call_deferred("It is raining.")


## Make the hour look wet: less sun, more haze. Called again whenever the time of day changes.
func _dim() -> void:
	if city == null or city.env == null or city.sun == null:
		return
	_dimmed = city.tod
	_base = {"sun": city.sun.light_energy, "fog": city.env.fog_density, "amb": city.env.ambient_light_energy}
	city.sun.light_energy = float(_base["sun"]) * 0.55
	city.env.fog_density = float(_base["fog"]) * 2.4 + 0.004
	city.env.ambient_light_energy = float(_base["amb"]) * 0.82
	city.env.fog_light_color = city.env.fog_light_color.lerp(Color(0.5, 0.56, 0.64), 0.5)


func _process(_delta: float) -> void:
	if not raining or scene == null or scene._player == null:
		return
	if _dimmed != city.tod:
		_dim()
	var outside: bool = str(scene._inside) == ""
	var cam := get_viewport().get_camera_3d()
	var at: Vector3 = cam.global_position if cam else scene._player.global_position
	_drops.visible = outside
	_splash.visible = outside
	_drops.global_position = Vector3(at.x, at.y + 9.0, at.z)
	var pp: Vector3 = scene._player.global_position
	_splash.global_position = Vector3(pp.x, pp.y + 0.06, pp.z)
	if _hiss.stream == null:
		_hiss.stream = Sfx.stream("water")
	if _hiss.stream != null and not _hiss.playing:
		_hiss.play()
	_hiss.volume_db = -19.0 if outside else -31.0
