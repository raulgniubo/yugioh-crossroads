class_name LumenSpirit
extends Node3D
## Lumen, your partner: a small duel spirit made of light. She is built here from simple
## shapes (no model file): a round body, two long ears that trail behind her, big eyes, a
## comet tail and a broken ring of light that turns around her. She bobs in the air, looks at
## things, blinks, talks, and now and then her picture tears for a split second, because her
## memory is not all there.

const BODY := Color("f4fbff")
const GLOW := Color("7fe8ff")
const DEEP := Color("2a7bd6")
const GOLD := Color("ffd76a")
const INK := Color("101a3a")

var watch: Node3D = null          # who she looks at
var look_at_point = null          # or a place (Vector3)
var mood := "calm"                # calm, happy, scared, sad, curious
var bonds := 0                    # more bonds: more ring pieces, a brighter gem
var size := 0.72                # in the world she is about as big as a football
## Which of her forms this is (her cards): 0 the spirit you travel with, 1 Echo Chorus,
## 2 Echo Comet, 3 Echo Zenith, 4 Echo Radiant. Set before she enters the tree.
var form := 0
var _tip: ShaderMaterial
var _extras: Array = []           # [node, home position, sway]: the parts a form adds, drifting a little
var head_height := 0.2           # for the story camera
var _t := randf() * 10.0
var _core: Node3D                 # everything that bobs and turns
var _body: MeshInstance3D
var _ears: Array = []
var _eyes: Array = []
var _lids := 1.0
var _blink := 2.0
var _mouth: MeshInstance3D
var _talk := 0.0
var _tail: Array = []
var _hands: Array = []
var _ring: Node3D
var _gem: MeshInstance3D
var _light: OmniLight3D
var _mat: ShaderMaterial
var _glitch := 0.0
var _glitch_in := 5.0
var _hop := 0.0
var _spin := 0.0
var _speed := 0.0
var _last_pos := Vector3.ZERO
var frozen := false

const SHADER := """
shader_type spatial;
render_mode cull_back, diffuse_toon, specular_disabled;
uniform vec4 base : source_color = vec4(0.96, 0.98, 1.0, 1.0);
uniform vec4 rim : source_color = vec4(0.5, 0.91, 1.0, 1.0);
uniform vec4 shade : source_color = vec4(0.62, 0.8, 1.0, 1.0);
uniform float glow = 0.55;
uniform float tear = 0.0;
varying float low;
void vertex() {
	// A torn picture: bands of her slide sideways for a moment.
	float band = step(0.5, fract(VERTEX.y * 9.0 + TIME * 13.0));
	VERTEX.x += (band - 0.5) * tear * 0.16;
	low = clamp(0.5 - NORMAL.y * 0.6, 0.0, 1.0);
}
void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.4);
	vec3 col = mix(base.rgb, shade.rgb, low * 0.75);
	ALBEDO = mix(col, rim.rgb, f * 0.8);
	EMISSION = (col * 0.16 + rim.rgb * f * 0.9) * glow * (1.0 + tear * 2.0);
	ROUGHNESS = 0.95;
}
"""


func _ready() -> void:
	_build()
	if form > 0:
		_evolve()
	_core.scale = Vector3.ONE * size
	_last_pos = global_position


func _m(col: Color, rim := GLOW, glow := 0.55) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _shader()
	m.set_shader_parameter("base", col)
	m.set_shader_parameter("rim", rim)
	m.set_shader_parameter("glow", glow * 0.7)
	return m


static var _sh: Shader
static func _shader() -> Shader:
	if _sh == null:
		_sh = Shader.new()
		_sh.code = SHADER
	return _sh


func _flat(col: Color, energy := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = energy
	return m


func _ball(r: float, pos: Vector3, mat: Material, squash := Vector3.ONE, parent: Node3D = null, segs := 24) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = segs
	sm.rings = maxi(6, segs / 2)
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	mi.scale = squash
	mi.set_meta("see_through", true)
	(parent if parent else _core).add_child(mi)
	return mi


func _build() -> void:
	_core = Node3D.new()
	add_child(_core)
	_mat = _m(BODY)
	# Body: a round wisp. The top curls back into a little flame, the bottom thins to a tail.
	_body = _ball(0.2, Vector3(0, 0.22, 0), _mat, Vector3(1.0, 0.94, 0.96))
	var tip_mat := _m(GLOW, Color.WHITE, 1.3)
	_tip = tip_mat
	for w in [[0.4, -0.03, 0.088], [0.485, -0.085, 0.062], [0.545, -0.155, 0.042], [0.57, -0.225, 0.026]]:
		var curl := _ball(float(w[2]), Vector3(0, float(w[0]), float(w[1])), tip_mat if float(w[2]) < 0.03 else _mat, Vector3.ONE, null, 14)
		_ears.append([curl, curl.position])
	# Eyes: big, dark, with a light in them. They sit on the surface of the face.
	for sx: float in [-1.0, 1.0]:
		var eye := Node3D.new()
		eye.position = Vector3(0.074 * sx, 0.245, 0.168)
		eye.rotation.y = 0.33 * sx
		_core.add_child(eye)
		_ball(0.043, Vector3.ZERO, _flat(INK), Vector3(0.82, 1.1, 0.34), eye, 16)
		_ball(0.024, Vector3(0.0, -0.004, 0.012), _flat(DEEP.lightened(0.15), 0.6), Vector3(0.8, 1.0, 0.3), eye, 12)
		_ball(0.012, Vector3(-0.012 * sx, 0.018, 0.02), _flat(Color.WHITE, 1.2), Vector3(1, 1, 0.4), eye, 8)
		_ball(0.006, Vector3(0.012 * sx, -0.016, 0.02), _flat(Color.WHITE, 1.2), Vector3(1, 1, 0.4), eye, 8)
		_eyes.append(eye)
	# Cheeks and a small mouth.
	for sx: float in [-1.0, 1.0]:
		_ball(0.022, Vector3(0.118 * sx, 0.195, 0.148), _flat(Color("ffb7d9")), Vector3(1.0, 0.6, 0.3), null, 10)
	_mouth = _ball(0.013, Vector3(0, 0.185, 0.192), _flat(Color("3a2a5a")), Vector3(1.0, 0.5, 0.4), null, 10)
	# The gem on her forehead: a small diamond that holds what she remembers.
	_gem = MeshInstance3D.new()
	var gm := SphereMesh.new()
	gm.radius = 0.026
	gm.height = 0.07
	gm.radial_segments = 4
	gm.rings = 1
	_gem.mesh = gm
	_gem.material_override = _flat(GOLD, 2.2)
	_gem.position = Vector3(0, 0.335, 0.165)
	_gem.rotation.x = -0.35
	_gem.set_meta("see_through", true)
	_core.add_child(_gem)
	# Two small hands that float beside her, not joined to anything.
	for sx: float in [-1.0, 1.0]:
		_hands.append([_ball(0.036, Vector3(0.21 * sx, 0.15, 0.09), _mat, Vector3(1, 0.9, 1), null, 12), sx])
	# The tail: she thins out to nothing underneath, like a candle flame upside down.
	for w in [[0.075, -0.05, 0.105], [-0.005, -0.115, 0.066], [-0.05, -0.185, 0.04], [-0.07, -0.25, 0.022]]:
		var bead := _ball(float(w[2]), Vector3(0, float(w[0]), float(w[1])), tip_mat if float(w[2]) < 0.03 else _mat, Vector3.ONE, null, 14)
		_tail.append([bead, bead.position])
	# The ring: pieces of a broken frame turning around her. One more piece per bond.
	_ring = Node3D.new()
	_ring.position.y = 0.22
	_ring.rotation = Vector3(0.2, 0, 0.12)
	_core.add_child(_ring)
	_build_ring()
	_light = OmniLight3D.new()
	_light.light_color = GLOW
	_light.light_energy = 0.55
	_light.omni_range = 3.4
	_light.omni_attenuation = 1.4
	_light.position.y = 0.3
	_light.shadow_enabled = false
	add_child(_light)
	# Sparkles that drift off her.
	var p := CPUParticles3D.new()
	p.amount = 14
	p.lifetime = 1.3
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.22
	p.gravity = Vector3(0, 0.25, 0)
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.2
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var pm := SphereMesh.new()
	pm.radius = 0.012
	pm.height = 0.024
	pm.radial_segments = 6
	pm.rings = 3
	pm.material = _flat(Color("d6faff"), 2.5)
	p.mesh = pm
	p.position.y = 0.2
	p.local_coords = false
	add_child(p)


# ------------------------------------------------------------------ her forms

func _part(mesh: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE, sway := 0.0, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	mi.set_meta("see_through", true)
	(parent if parent else _core).add_child(mi)
	if sway > 0.0:
		_extras.append([mi, pos, sway])
	return mi


func _torus(r: float, thick: float) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = r - thick
	t.outer_radius = r + thick
	t.rings = 40
	t.ring_segments = 10
	return t


func _blade(len: float) -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = len * 0.5
	sm.height = len
	sm.radial_segments = 14
	sm.rings = 8
	return sm


func _recolor(base: Color, rim: Color, shade: Color, glow: float, tip: Color) -> void:
	_mat.set_shader_parameter("base", base)
	_mat.set_shader_parameter("rim", rim)
	_mat.set_shader_parameter("shade", shade)
	_mat.set_shader_parameter("glow", glow)
	_tip.set_shader_parameter("base", tip)
	_tip.set_shader_parameter("rim", Color.WHITE)
	_light.light_color = rim


## What she becomes. The spirit is still in there (the face, the gem, the hands), and each
## form adds what that world taught her.
func _evolve() -> void:
	_glitch_in = 1.0e9          # a form is whole: no tear runs through her
	match form:
		1:
			# Echo Chorus (Fusion): two voices in one. A second curl beside the first, rose on
			# one side and sky on the other, and wings that are rings of sound.
			_recolor(Color("fff4fb"), Color("ff8fd6"), Color("c9b8ff"), 0.6, Color("ff9ad5"))
			var rose := _m(Color("ffd0ec"), Color("ff6fc8"), 1.2)
			var sky := _m(Color("d0f0ff"), Color("5fc8ff"), 1.2)
			for e in _ears:
				(e[0] as Node3D).position.x += 0.085
				e[1] = (e[0] as Node3D).position
				(e[0] as MeshInstance3D).material_override = sky
			for w in [[0.4, -0.03, 0.088], [0.485, -0.085, 0.062], [0.545, -0.155, 0.042], [0.57, -0.225, 0.026]]:
				var twin := _ball(float(w[2]), Vector3(-0.085, float(w[0]), float(w[1])), rose, Vector3.ONE, null, 14)
				_ears.append([twin, twin.position])
			(_hands[0][0] as MeshInstance3D).material_override = rose
			(_hands[1][0] as MeshInstance3D).material_override = sky
			for sx: float in [-1.0, 1.0]:
				var ring_m := _flat(Color("ff8fd6") if sx < 0.0 else Color("6fd0ff"), 2.4)
				for k in 3:
					_part(_torus(0.085 + k * 0.058, 0.009 - k * 0.0015), ring_m, Vector3(sx * (0.3 + k * 0.035), 0.3 + k * 0.012, -0.1 - k * 0.03), Vector3(PI * 0.5, 0, sx * 0.25), Vector3.ONE, 0.012 + k * 0.006)
			# A second gem: two memories now.
			_gem.position.x = 0.03
			var gem2 := _part(_gem.mesh, _flat(Color("ff9ad5"), 2.2), Vector3(-0.03, 0.33, 0.165), Vector3(-0.35, 0, 0), Vector3(0.8, 0.8, 0.8))
			gem2.set_meta("see_through", true)
			size *= 1.1
		2:
			# Echo Comet (Synchro): everything swept back. The curl has become a tail of light
			# streaming behind her, and she has fins to steer by.
			_recolor(Color("f2fdff"), Color("3fd8ff"), Color("8fd0ff"), 0.75, Color("9ff0ff"))
			for e in _ears:
				(e[0] as Node3D).visible = false
			var trail := _m(Color("c8f6ff"), Color.WHITE, 1.6)
			for k in 9:
				var f := k / 8.0
				var bead := _ball(lerpf(0.1, 0.012, f), Vector3(0, 0.36 + f * 0.2, -0.04 - f * 0.78), trail, Vector3(1.0, 1.0, 1.5), null, 12)
				_ears.append([bead, bead.position])
				bead.visible = true
			var fin := _m(Color("d8fbff"), Color("3fd8ff"), 1.3)
			for sx: float in [-1.0, 1.0]:
				_part(_blade(0.44), fin, Vector3(sx * 0.27, 0.27, -0.14), Vector3(0.0, sx * -0.5, sx * -1.0), Vector3(0.34, 1.0, 0.1), 0.01)
				_part(_blade(0.26), fin, Vector3(sx * 0.22, 0.12, -0.12), Vector3(0.0, sx * -0.5, sx * -1.5), Vector3(0.34, 1.0, 0.1), 0.01)
			# The gem is a four-pointed star now.
			_gem.visible = false
			var star_m := _flat(GOLD, 2.6)
			for k in 2:
				_part(_blade(0.12), star_m, Vector3(0, 0.335, 0.168), Vector3(-0.35, 0, k * PI * 0.5), Vector3(0.22, 1.0, 0.12))
			size *= 1.08
		3:
			# Echo Zenith (Xyz): the night sky in the shape of her. Stars in her body, a crescent
			# over her head, and a gold ring going round her with two lights on it.
			_recolor(Color("2d2678"), Color("b9a6ff"), Color("120d3d"), 1.0, Color("d9ccff"))
			var star_w := _flat(Color("f4f0ff"), 2.4)
			var rng := RandomNumberGenerator.new()
			rng.seed = 404
			for k in 16:
				var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.9, 0.9), rng.randf_range(0.15, 1.0)).normalized()
				if absf(dir.x) < 0.5 and dir.y > -0.1 and dir.y < 0.45 and dir.z > 0.6:
					continue      # (not across her face)
				_ball(rng.randf_range(0.005, 0.011), Vector3(0, 0.22, 0) + dir * Vector3(0.2, 0.188, 0.192) * 1.01, star_w, Vector3.ONE, null, 6)
			var moon := _flat(GOLD, 2.4)
			for k in 19:
				var a := deg_to_rad(15.0 + k * 8.4)
				var fat := sin(PI * k / 18.0)
				_part(_blade(0.062), moon, Vector3(cos(a) * 0.15, 0.5 + sin(a) * 0.15, -0.06), Vector3.ZERO, Vector3(1.0, 1.0, 0.5) * (0.2 + fat * 0.8))
			var orbit := Node3D.new()
			orbit.position.y = 0.22
			orbit.rotation = Vector3(0.38, 0, 0.3)
			_core.add_child(orbit)
			_part(_torus(0.37, 0.006), moon, Vector3.ZERO, Vector3.ZERO, Vector3.ONE, 0.0, orbit)
			for a2: float in [0.6, 0.6 + PI]:
				_ball(0.034, Vector3(cos(a2) * 0.37, 0, sin(a2) * 0.37), _flat(Color("fff6c8"), 3.0), Vector3.ONE, orbit, 12)
			_extras.append([orbit, orbit.position, -1.0])       # (it turns: see _process)
			for h in _hands:
				(h[0] as MeshInstance3D).material_override = _m(Color("4a40a8"), Color("d9ccff"), 1.1)
			size *= 1.12
		4:
			# Echo Radiant: all of it at once. Gold and white, four wings of light, a halo, and
			# ribbons where the little tail was. The gem is a crest of three.
			_recolor(Color("fff8dc"), Color("ffab1f"), Color("ffcf70"), 0.9, Color("ffd45a"))
			var feather := _m(Color("ffeeb0"), Color("ff9d00"), 1.5)
			for sx: float in [-1.0, 1.0]:
				for k in 4:
					# Upper wing: four feathers fanned up and out.
					_part(_blade(0.5 - k * 0.05), feather, Vector3(sx * (0.2 + k * 0.045), 0.42 + k * 0.01, -0.13 - k * 0.012), Vector3(0.1, 0, sx * -(0.35 + k * 0.33)), Vector3(0.2, 1.0, 0.07), 0.008 + k * 0.004)
				for k in 3:
					# Lower wing: three, down and out.
					_part(_blade(0.34 - k * 0.04), feather, Vector3(sx * (0.2 + k * 0.04), 0.12 - k * 0.02, -0.13), Vector3(0.1, 0, sx * -(2.0 + k * 0.32)), Vector3(0.2, 1.0, 0.07), 0.008 + k * 0.004)
			var gold := _flat(Color("ffcf4a"), 2.8)
			_part(_torus(0.15, 0.011), gold, Vector3(0, 0.72, -0.1), Vector3(0.22, 0, 0), Vector3.ONE, 0.012)
			_gem.scale = Vector3.ONE * 1.5
			for sx: float in [-1.0, 1.0]:
				_part(_gem.mesh, gold, Vector3(sx * 0.055, 0.325, 0.172), Vector3(-0.35, 0, sx * -0.3), Vector3(0.8, 0.8, 0.8))
			var ribbon := _m(Color("fff0b8"), Color("ffb300"), 1.5)
			for sx: float in [-1.0, 1.0]:
				for k in 7:
					var f2 := k / 6.0
					var bead2 := _ball(lerpf(0.045, 0.012, f2), Vector3(sx * (0.1 + f2 * 0.3), 0.04 - f2 * 0.3, -0.1 - f2 * 0.12), ribbon, Vector3.ONE, null, 10)
					_tail.append([bead2, bead2.position])
			bonds = 5
			_build_ring()
			size *= 1.3
	if form > 0:
		_light.light_energy = 0.8


func _build_ring() -> void:
	for c in _ring.get_children():
		c.queue_free()
	# Blank cards that circle her. One fills in (turns gold) for every bond you make.
	var pieces := 5
	for i in pieces:
		var holder := Node3D.new()
		holder.rotation.y = TAU * float(i) / float(pieces)
		_ring.add_child(holder)
		var card := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.058, 0.084, 0.004)
		card.mesh = bm
		card.material_override = _flat(GOLD if i < bonds else Color("c9f3ff"), 1.6 if i < bonds else 0.9)
		card.position = Vector3(0, sin(float(i) * 2.4) * 0.05, 0.4)
		card.rotation = Vector3(0.15, 0, 0.22 * (1.0 if i % 2 == 0 else -1.0))
		card.set_meta("see_through", true)
		holder.add_child(card)


func set_bonds(n: int) -> void:
	if n == bonds:
		return
	bonds = n
	if _ring:
		_build_ring()


## She says something: the mouth moves for a while.
func speak(seconds := 1.6) -> void:
	_talk = seconds


## A little jump of joy (or fright).
func hop() -> void:
	_hop = 1.0


func spin() -> void:
	_spin = 1.0


## Eyes fully open and no tear running through her: a good moment to hold a still picture of her.
## (A picture stopped mid-blink left her card with one eye half shut.)
## Also none of the blank cards circling her is passing in front of her face (the pictures are
## taken from the front): one did, and on her card it looked like a line through her eye.
func at_rest() -> bool:
	if _lids < 1.0 or _glitch > 0.0 or _talk > 0.0:
		return false
	if _ring and is_inside_tree():
		for holder in _ring.get_children():
			for card in (holder as Node3D).get_children():
				var p: Vector3 = (card as Node3D).global_position - global_position
				if p.z > 0.15 and absf(p.x) < 0.14 * maxf(size, 0.1):
					return false
	return true


## Her picture tears for a moment.
func glitch(seconds := 0.25) -> void:
	_glitch = seconds


# The story director treats the cast alike: these keep it happy.
func set_speed(s: float) -> void:
	_speed = s


func gesture(motion: String, _blend := 0.3) -> bool:
	if motion in ["victory", "cheer", "wave"]:
		spin()
	else:
		hop()
	return true


func play_once(motion: String, _loops := 1) -> bool:
	return gesture(motion)


func _process(delta: float) -> void:
	if frozen:
		return
	_t += delta
	var moved := (global_position - _last_pos) / maxf(delta, 0.001)
	_last_pos = global_position
	var fly := clampf(Vector2(moved.x, moved.z).length() / 4.0, 0.0, 1.0)
	# Bob, lean into the direction of travel.
	_core.position.y = sin(_t * 2.3) * 0.035 + absf(sin(_hop * PI)) * 0.22
	_core.rotation.x = lerpf(_core.rotation.x, fly * 0.35, clampf(delta * 6.0, 0.0, 1.0))
	if _hop > 0.0:
		_hop = maxf(0.0, _hop - delta * 2.4)
	if _spin > 0.0:
		_spin = maxf(0.0, _spin - delta * 1.5)
		_core.rotation.y = (1.0 - _spin) * TAU
	else:
		_core.rotation.y = 0.0
	# Squash and stretch with the bob.
	var breathe := 1.0 + sin(_t * 2.3 + 1.2) * 0.03
	_body.scale = Vector3(1.0 / breathe, 0.94 * breathe, 0.96 / breathe)
	# The curl on her head sways, and flattens when she is scared or flying fast.
	var fold := 0.5 if mood == "scared" else (0.25 if mood == "sad" else 0.0)
	for i in _ears.size():
		var curl: MeshInstance3D = _ears[i][0]
		var home: Vector3 = _ears[i][1]
		var k := minf(float(i + 1) / 4.0, 1.0)
		curl.position = home + Vector3(sin(_t * 2.0 - k * 1.6) * 0.03 * k, -fold * 0.12 * k - fly * 0.06 * k, -fly * 0.12 * k - fold * 0.06 * k)
	for i in _tail.size():
		var bead: MeshInstance3D = _tail[i][0]
		var home_t: Vector3 = _tail[i][1]
		var kt := minf(float(i + 1) / 4.0, 1.0) if i < 4 else float((i - 4) % 7 + 1) / 7.0
		bead.position = home_t + Vector3(sin(_t * 3.0 - kt * 2.2) * 0.035 * kt, fly * 0.07 * kt, -fly * 0.16 * kt)
	for h in _hands:
		var hand: MeshInstance3D = h[0]
		var sx: float = h[1]
		var up := 0.2 if mood == "happy" else (0.1 if _talk > 0.0 else 0.0)
		var hide := 0.07 if mood == "scared" else 0.0
		hand.position = Vector3((0.21 - hide) * sx, 0.15 + up + sin(_t * 2.6 + sx * 1.3) * 0.02 + (absf(sin(_t * 9.0)) * 0.04 if _talk > 0.0 else 0.0), 0.09 + hide)
	_ring.rotation.y += delta * (0.9 + fly * 2.0)
	for i in _extras.size():
		var ex: Array = _extras[i]
		if float(ex[2]) < 0.0:
			(ex[0] as Node3D).rotation.y += delta * 0.7        # (the Zenith ring turns)
		else:
			(ex[0] as Node3D).position = (ex[1] as Vector3) + Vector3(0, sin(_t * 2.1 + i * 0.7) * float(ex[2]), 0)
	_gem.rotation.y += delta * 2.0
	# Blink.
	_blink -= delta
	if _blink < 0.0:
		_blink = randf_range(1.8, 5.0)
		_lids = 0.0
	_lids = minf(1.0, _lids + delta * 7.0)
	var open := _lids * (0.72 if mood == "sad" else (1.18 if mood in ["scared", "curious"] else 1.0))
	if mood == "happy":
		open *= 0.85
	for eye in _eyes:
		(eye as Node3D).scale.y = maxf(0.08, open)
	# Mouth.
	if _talk > 0.0:
		_talk -= delta
		_mouth.scale = Vector3(1.0, 0.5 + absf(sin(_t * 17.0)) * 1.3, 0.4)
	else:
		_mouth.scale = Vector3(1.6, 0.35, 0.4) if mood == "happy" else Vector3(1.0, 0.5, 0.4)
	# Look where she is looking: the whole of her turns, she is mostly head.
	var target = look_at_point
	if target == null and watch and is_instance_valid(watch):
		target = watch.global_position + Vector3(0, 1.45, 0)
	if target != null and _spin <= 0.0:
		var to: Vector3 = (target as Vector3) - global_position
		if Vector2(to.x, to.z).length() > 0.25 and fly < 0.25:
			rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), clampf(delta * 5.0, 0.0, 1.0))
	# The tear.
	_glitch_in -= delta
	if _glitch_in < 0.0:
		_glitch_in = randf_range(6.0, 16.0)
		_glitch = 0.14
	if _glitch > 0.0:
		_glitch -= delta
	_mat.set_shader_parameter("tear", 1.0 if _glitch > 0.0 else 0.0)
	_light.light_energy = (0.55 + sin(_t * 3.1) * 0.08) * (1.8 if _glitch > 0.0 else 1.0)


# ------------------------------------------------------------------ her picture

static var _vp: SubViewport
static var _awake_until := 0.0


static var _form_vps := {}        # form -> SubViewport


## A picture of one of her forms (1..4; 0 is her everyday portrait). It is drawn for a few
## seconds each time it is asked for and then holds still.
static func portrait_form(host: Node, f: int) -> Texture2D:
	if f <= 0:
		return portrait(host)
	var vp: SubViewport = _form_vps.get(f)
	if vp == null or not is_instance_valid(vp):
		vp = SubViewport.new()
		vp.size = Vector2i(640, 640)
		vp.own_world_3d = true
		vp.msaa_3d = Viewport.MSAA_4X
		vp.transparent_bg = true
		host.add_child(vp)
		var env := WorldEnvironment.new()
		var e := Environment.new()
		e.background_mode = Environment.BG_CLEAR_COLOR
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color(0.8, 0.86, 1.0)
		e.ambient_light_energy = 1.0
		env.environment = e
		vp.add_child(env)
		var sun := DirectionalLight3D.new()
		sun.rotation = Vector3(-0.7, 0.6, 0)
		sun.light_energy = 0.8
		vp.add_child(sun)
		var l := LumenSpirit.new()
		l.form = f
		l.size = 1.0
		l.rotation.y = [0.0, 0.25, 0.55, 0.3, 0.18][f]
		vp.add_child(l)
		var cam := Camera3D.new()
		cam.fov = 30.0
		# Far enough back for wings, rings and tails.
		cam.position = [Vector3.ZERO, Vector3(0.0, 0.38, 1.75), Vector3(-0.1, 0.42, 1.8), Vector3(0.0, 0.38, 1.9), Vector3(0.0, 0.46, 2.45)][f]
		vp.add_child(cam)
		cam.look_at([Vector3.ZERO, Vector3(0, 0.36, 0), Vector3(-0.02, 0.4, -0.1), Vector3(0, 0.38, 0), Vector3(0, 0.46, 0)][f], Vector3.UP)
		_form_vps[f] = vp
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var held := vp
	var tree := host.get_tree()
	var hold_still := func(again: Callable) -> void:
		if not is_instance_valid(held):
			return
		var her = held.get_children().filter(func(n): return n is LumenSpirit)
		if her.is_empty() or (her[0] as LumenSpirit).at_rest():
			held.render_target_update_mode = SubViewport.UPDATE_DISABLED
		else:
			tree.create_timer(0.1).timeout.connect(func(): again.call(again))   # (not mid-blink: wait for her eyes to open)
	tree.create_timer(3.0).timeout.connect(func(): hold_still.call(hold_still))
	return vp.get_texture()


## Her portrait only redraws while somebody is looking at it: call this when it goes on screen.
static func wake(seconds := 6.0) -> void:
	_awake_until = maxf(_awake_until, Time.get_ticks_msec() / 1000.0 + seconds)
	if _vp and is_instance_valid(_vp):
		_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS


## Her, alive, on a see-through picture: for floating her over a 2D screen (beside your duelist
## in a duel). Returns [the picture's SubViewport, her]. Free the SubViewport to end it.
static func floating(host: Node, px := 300) -> Array:
	var vp := SubViewport.new()
	vp.size = Vector2i(px, px)
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	host.add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.86, 1.0)
	e.ambient_light_energy = 1.0
	env.environment = e
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.7, 0.6, 0)
	sun.light_energy = 0.8
	vp.add_child(sun)
	var l := LumenSpirit.new()
	l.size = 1.0
	l.rotation.y = 0.35
	vp.add_child(l)
	var cam := Camera3D.new()
	cam.fov = 30.0
	cam.position = Vector3(0.0, 0.3, 1.3)
	vp.add_child(cam)
	cam.look_at(Vector3(0, 0.27, 0), Vector3.UP)
	return [vp, l]


## A live portrait for dialogue boxes and menus.
static func portrait(host: Node) -> Texture2D:
	if _vp and is_instance_valid(_vp):
		wake(3.0)
		return _vp.get_texture()
	_awake_until = Time.get_ticks_msec() / 1000.0 + 3.0
	_vp = SubViewport.new()
	_vp.size = Vector2i(512, 640)
	_vp.own_world_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.msaa_3d = Viewport.MSAA_4X
	# No backdrop of her own: like everybody else's picture she stands on whatever is behind
	# her (a dark square stuck out over the top of the talk box).
	_vp.transparent_bg = true
	host.add_child(_vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.86, 1.0)
	e.ambient_light_energy = 1.0
	env.environment = e
	_vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.7, 0.6, 0)
	sun.light_energy = 0.8
	_vp.add_child(sun)
	var l := LumenSpirit.new()
	l.size = 1.0
	l.rotation.y = 0.28
	_vp.add_child(l)
	var cam := Camera3D.new()
	cam.fov = 30.0
	cam.position = Vector3(0.0, 0.3, 1.5)
	_vp.add_child(cam)
	cam.look_at(Vector3(0, 0.27, 0), Vector3.UP)
	# A small watcher that puts the picture to sleep when nobody has asked for it lately.
	var nap := Timer.new()
	nap.wait_time = 0.5
	nap.autostart = true
	nap.timeout.connect(func():
		if is_instance_valid(_vp) and Time.get_ticks_msec() / 1000.0 > _awake_until and (not is_instance_valid(l) or l.at_rest()):
			_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED)
	_vp.add_child(nap)
	return _vp.get_texture()
