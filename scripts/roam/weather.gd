class_name Weather
extends Node3D
## Rain: streaks falling around the camera, splash rings on the ground, a darker and hazier
## sky, and the hiss of it. It comes and goes with the clock (WorldClock.rains): a shower
## clouds over, falls for a while and clears. Indoors you only hear it. In Satellite it is not
## rain but dust: the air goes brown and thick.

var scene: Node
var city: CityBuilder
var raining := false           # it is coming down right now (or dust is up)
var wet := 0.0                 # 0 dry .. 1 pouring; follows the weather over half a minute
var dust := false
var _built := false
var _force := 0                # dev: 1 always rain, -1 never
var _drops: GPUParticles3D
var _splash: GPUParticles3D
var _hiss: AudioStreamPlayer
var _veil: ColorRect
var _tick := 0.0
var _told := false


func setup(roam: Node) -> void:
	scene = roam
	city = roam.city
	var args := OS.get_cmdline_user_args()
	_force = 1 if "--rain" in args else (-1 if "--dry" in args else 0)
	dust = str(Router.roam.get("district", "")) == "satellite"
	if city:
		city.look_hook = _dim
	if _wants():
		# Already raining when you arrive: no slow start.
		wet = 1.0
		_build()
		_apply()
		city.refresh_look()
		Router.toast.call_deferred("A dust storm is blowing through." if dust else "It is raining.")
		_told = true


## Should it be coming down right now?
func _wants() -> bool:
	if _force != 0:
		return _force > 0
	var d := str(Router.roam.get("district", ""))
	if d == "museum":
		return false
	# A story scene plays in the weather it was written for; the free parts of a chapter follow the clock.
	if str(Router.roam.get("story", "")) != "" and not bool(Router.roam.get("story_free", false)):
		return false
	return WorldClock.rains(d)


func _build() -> void:
	if _built:
		return
	_built = true
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
	# Each streak points along its own fall (mesh +Y = the way it moves, so +Y is the leading end).
	pm.particle_flag_align_y = true
	_drops.process_material = pm
	var streak := BoxMesh.new()
	streak.size = Vector3(0.03, 0.7, 0.03)
	# A drop reads as falling when its bright, sharp end leads and its tail fades behind it.
	# Before, every streak was the same all along, and the lens streaks (below) were brightest at
	# the top: the shape of something rising.
	var dsh := Shader.new()
	dsh.code = """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
varying float along;
void vertex() { along = VERTEX.y / 0.7 + 0.5; }
void fragment() {
	ALBEDO = vec3(0.82, 0.9, 1.0);
	ALPHA = 0.62 * smoothstep(0.0, 0.85, along) * smoothstep(1.0, 0.94, along);
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = dsh
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
	# Rain on the lens: fine slanted streaks over the whole picture, so it reads at any distance.
	var layer := CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	_veil = ColorRect.new()
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec2 uv = UV * vec2(16.0 / 9.0, 1.0);
	float a = 0.0;
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		vec2 g = uv * vec2(90.0 + fi * 50.0, 5.0 + fi * 2.5);
		g.x += g.y * 0.6;
		g.y -= TIME * (9.0 + fi * 4.0);   // (UV.y grows downward: subtracting moves the streaks DOWN the screen)
		vec2 id = floor(g);
		vec2 f = fract(g);
		float on = step(0.86 - fi * 0.03, hash(id + fi * 17.0));
		// Head at the bottom (the leading end), tail fading upward.
		float line = smoothstep(0.5, 0.42, abs(f.x - 0.5) * 2.0 + 0.3) * smoothstep(0.05, 0.85, f.y) * smoothstep(1.0, 0.93, f.y);
		a += on * line * (0.2 - fi * 0.045);
	}
	COLOR = vec4(0.85, 0.92, 1.0, a);
}
"""
	var vm := ShaderMaterial.new()
	vm.shader = sh
	_veil.material = vm
	layer.add_child(_veil)
	_hiss = AudioStreamPlayer.new()
	_hiss.bus = "SFX"
	_hiss.volume_db = -19.0
	_hiss.pitch_scale = 1.35
	add_child(_hiss)
	if dust:
		_drops.visible = false
		_splash.visible = false


## The hour, made wet: less sun, more haze, by how hard it is coming down. Runs after every
## change of look, so it always sits on top of the right time of day.
func _dim() -> void:
	if city == null or city.env == null or city.sun == null or wet <= 0.001:
		return
	if dust:
		city.sun.light_energy *= lerpf(1.0, 0.62, wet)
		city.env.fog_density = city.env.fog_density * lerpf(1.0, 2.6, wet) + 0.0012 * wet
		city.env.fog_light_color = city.env.fog_light_color.lerp(Color(0.62, 0.48, 0.34), 0.6 * wet)
		return
	# Overcast, not milky: a dimmer sun and a touch more air, but the world keeps its contrast.
	city.sun.light_energy *= lerpf(1.0, 0.7, wet)
	city.env.fog_density = city.env.fog_density * lerpf(1.0, 1.4, wet) + 0.0006 * wet
	city.env.ambient_light_energy *= lerpf(1.0, 0.9, wet)
	city.env.fog_light_color = city.env.fog_light_color.lerp(Color(0.5, 0.56, 0.64), 0.35 * wet)


func _apply() -> void:
	if not _built:
		return
	var outside: bool = str(scene._inside) == ""
	var show := outside and wet > 0.02 and not dust
	_drops.visible = show
	_splash.visible = show
	_veil.visible = show
	_drops.amount_ratio = clampf(wet, 0.05, 1.0)
	_splash.amount_ratio = clampf(wet, 0.05, 1.0)
	_veil.modulate.a = wet


func _process(delta: float) -> void:
	if scene == null or scene._player == null:
		return
	_tick -= delta
	var want := _wants()
	if want and not _built:
		_build()
	if want != raining:
		raining = want
		if want and not _told:
			Router.toast("The wind is picking up dust." if dust else "It is starting to rain.")
		elif not want and wet > 0.5:
			Router.toast("The dust is settling." if dust else "The rain is letting up.")
		_told = false
	var before := wet
	wet = move_toward(wet, 1.0 if want else 0.0, delta / 24.0)
	if not _built:
		return
	if not is_equal_approx(before, wet) and _tick <= 0.0:
		# The sky follows a few times a second while it is clouding over or clearing.
		_tick = 0.25
		city.refresh_look()
	_apply()
	if wet <= 0.02:
		if _hiss.playing:
			_hiss.stop()
		return
	var outside: bool = str(scene._inside) == ""
	var cam := get_viewport().get_camera_3d()
	var at: Vector3 = cam.global_position if cam else scene._player.global_position
	_drops.global_position = Vector3(at.x, at.y + 9.0, at.z)
	var pp: Vector3 = scene._player.global_position
	_splash.global_position = Vector3(pp.x, pp.y + 0.06, pp.z)
	if dust:
		return
	if _hiss.stream == null:
		_hiss.stream = Sfx.stream("water")
	if _hiss.stream != null and not _hiss.playing:
		_hiss.play()
	_hiss.volume_db = lerpf(-40.0, -19.0 if outside else -31.0, wet)
