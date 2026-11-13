class_name DuelArena
extends CityBuilder
## The world around the duel field: a different place for every field theme.
## Mostly seen during the opening fly-in and the low attack / ace camera shots.

var _spin: Array[Node3D] = []
var _bob: Array = []  # [node, base_y, speed]


func build_arena(t: Dictionary) -> void:
	theme = t
	make_solid = false
	match str(t.get("key", "crossroads")):
		"battlecity":
			_rooftop()
		"kaibacorp":
			_dome()
		"academy":
			_academy()
		"satellite":
			_junkyard()
		"heartland":
			_heartland()
		"meadow", "volcano", "peak", "ruins", "tide":
			_wild(str(t.get("key", "")))
			return
		"shadow":
			_void()
			_stone_rim(Color(0.12, 0.06, 0.18))
			return
		_:
			_void()
	_stage_ring()
	_light_windows(0.5 if str(t.get("key", "")) in ["satellite", "heartland"] else 1.0)


func _light_windows(strength: float) -> void:
	for m in _window_mats:
		m.set_shader_parameter("glow_strength", strength)
		m.set_shader_parameter("day", 0.0)
	for n in _neon:
		(n[0] as Label3D).modulate = Color(n[2]) * 2.2


func _process(delta: float) -> void:
	_time += delta
	for n in _spin:
		n.rotation.y += delta * float(n.get_meta("spin", 0.1))
	for b in _bob:
		(b[0] as Node3D).position.y = float(b[1]) + sin(_time * float(b[2])) * 0.4
	for h in _spin_z:
		(h as Node3D).rotation.z += delta * float((h as Node3D).get_meta("spin_z", 0.4))


# ------------------------------------------------------------------ shared pieces

## A raised rim around the duel field so it reads as a stage.
func _stage_ring() -> void:
	var rim := mat(Color(theme["base"]).lightened(0.12), 0.35, 0.6)
	var glow := glow_mat(theme["accent"], 2.2)
	for side in [-1, 1]:
		box(Vector3(15.4, 0.35, 0.5), Vector3(0, -0.18, side * 5.35), rim, false)
		box(Vector3(0.5, 0.35, 11.2), Vector3(side * 7.45, -0.18, 0), rim, false)
		box(Vector3(15.4, 0.04, 0.06), Vector3(0, 0.0, side * 5.62), glow, false)
		box(Vector3(0.06, 0.04, 11.2), Vector3(side * 7.72, 0.0, 0), glow, false)
	# Hologram projector pylons at the four corners, with light beams feeding the field.
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var at := Vector3(sx * 8.7, -0.3, sz * 6.5)
			if prop("holo_pylon", at, atan2(-at.x, -at.z), 3.6, true) == null:
				continue
			var l := OmniLight3D.new()
			l.light_color = theme["accent"] if sz > 0 else theme["accent2"]
			l.light_energy = 2.2
			l.omni_range = 7.0
			l.position = at + Vector3(0, 3.5, 0)
			add_child(l)
			var beam := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.03
			cm.bottom_radius = 0.16
			cm.height = 9.0
			cm.radial_segments = 8
			beam.mesh = cm
			var bm := StandardMaterial3D.new()
			bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			bm.albedo_color = Color(l.light_color, 0.16)
			bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			bm.cull_mode = BaseMaterial3D.CULL_DISABLED
			beam.material_override = bm
			beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			beam.position = at + Vector3(0, 3.4 + 4.5, 0)
			add_child(beam)
			_bob.append([beam, beam.position.y, 0.6 + 0.1 * (sx + sz)])
	# Stone guardians watching from both flanks.
	for sx in [-1, 1]:
		var st := prop("dragon_statue", Vector3(sx * 12.2, -0.3, 0), -sx * PI / 2, 5.4, true)
		if st:
			var up := SpotLight3D.new()
			up.light_color = Color(theme["accent"]).lerp(Color.WHITE, 0.4)
			up.light_energy = 5.0
			up.spot_range = 9.0
			up.spot_angle = 38.0
			up.position = Vector3(sx * 9.6, 0.3, 0)
			add_child(up)
			up.look_at(Vector3(sx * 12.2, 3.0, 0))


const CROWD_SH := """
shader_type spatial;
render_mode cull_back;
uniform int part = 0;            // 0 body, 1 head, 2 arms, 3 glow stick
varying vec3 lp;
varying float h;
float hash(float p) { return fract(sin(p * 78.233) * 43758.5453); }
void vertex() {
	float id = float(INSTANCE_ID);
	h = hash(id + 5.0);
	float ph = hash(id) * 6.283;
	// Some fans are calm, some never sit still, and now and then a wave goes round the stands.
	float excite = 0.5 + 0.5 * sin(TIME * 0.5 + hash(id + 2.0) * 6.283);
	float ang = atan(MODEL_MATRIX[3].x, MODEL_MATRIX[3].z);
	float wave = smoothstep(0.6, 1.0, sin(TIME * 1.1 - ang * 2.0));
	float jump = abs(sin(TIME * (3.0 + hash(id + 1.0) * 2.5) + ph)) * (0.03 + 0.16 * max(excite * excite * 0.6, wave));
	lp = VERTEX;
	if (part >= 2) {
		float up = max(wave, smoothstep(0.7, 0.95, excite));
		if (part == 3 && h < 0.72) { VERTEX *= 0.0; }
		vec3 pv = VERTEX - vec3(0.0, 0.62, 0.0);
		float a = up * (2.5 + 0.3 * sin(TIME * 7.0 + ph));
		float c = cos(a); float s = sin(a);
		pv = vec3(pv.x, pv.y * c - pv.z * s, pv.y * s + pv.z * c);
		VERTEX = pv + vec3(0.0, 0.62, 0.0);
	}
	VERTEX.y += jump;
	VERTEX.x += sin(TIME * 1.3 + ph) * 0.03;
}
void fragment() {
	vec3 col = COLOR.rgb;
	if (part == 1) {
		vec3 skin = mix(vec3(0.96, 0.8, 0.66), vec3(0.42, 0.28, 0.2), h * h);
		vec3 hair = mix(vec3(0.08, 0.06, 0.05), mix(vec3(0.55, 0.35, 0.12), vec3(0.85, 0.75, 0.4), fract(h * 7.0)), step(0.45, fract(h * 3.0)));
		float cap = smoothstep(0.76, 0.8, lp.y - lp.z * 0.35);
		col = mix(skin, hair, cap);
	} else if (part == 2) {
		col = mix(col, mix(vec3(0.96, 0.8, 0.66), vec3(0.42, 0.28, 0.2), h * h), step(lp.y, 0.34) * step(0.5, fract(h * 11.0)));
	}
	ALBEDO = col;
	ROUGHNESS = 0.85;
	if (part == 3) {
		vec3 g = fract(h * 5.0) < 0.34 ? vec3(0.2, 0.95, 1.0) : (fract(h * 5.0) < 0.67 ? vec3(1.0, 0.3, 0.75) : vec3(1.0, 0.85, 0.2));
		ALBEDO = g;
		EMISSION = g * 3.0;
	}
}
"""

const FLASH_SH := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
float hash(float p) { return fract(sin(p * 91.7) * 43758.5453); }
varying float id;
void vertex() {
	id = float(INSTANCE_ID);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	float on = step(0.985, hash(id + floor(TIME * 9.0) * 13.0));
	float d = length(UV - 0.5) * 2.0;
	float star = max(0.0, 1.0 - d) + max(0.0, 0.25 - abs(UV.x - 0.5) * abs(UV.y - 0.5) * 60.0);
	ALBEDO = vec3(1.0, 0.98, 0.9);
	ALPHA = clamp(star, 0.0, 1.0) * on;
}
"""

var _crowd_mesh: ArrayMesh


## One fan: body, head, two arms and a glow stick, each its own surface so the shader can tell
## them apart. Low-poly on purpose; there are a thousand of them.
func _fan_mesh() -> ArrayMesh:
	if _crowd_mesh:
		return _crowd_mesh
	var sh := Shader.new()
	sh.code = CROWD_SH
	var am := ArrayMesh.new()
	var parts: Array = []
	var body := CapsuleMesh.new()
	body.radius = 0.2
	body.height = 0.66
	body.radial_segments = 8
	body.rings = 2
	parts.append([[body, Transform3D(Basis.IDENTITY, Vector3(0, 0.33, 0))]])
	var head := SphereMesh.new()
	head.radius = 0.15
	head.height = 0.3
	head.radial_segments = 10
	head.rings = 5
	parts.append([[head, Transform3D(Basis.IDENTITY, Vector3(0, 0.78, 0))]])
	var arm := CapsuleMesh.new()
	arm.radius = 0.06
	arm.height = 0.42
	arm.radial_segments = 6
	arm.rings = 1
	parts.append([[arm, Transform3D(Basis.IDENTITY, Vector3(-0.26, 0.42, 0))], [arm, Transform3D(Basis.IDENTITY, Vector3(0.26, 0.42, 0))]])
	var stick := BoxMesh.new()
	stick.size = Vector3(0.045, 0.34, 0.045)
	parts.append([[stick, Transform3D(Basis.IDENTITY, Vector3(0.26, 0.06, 0))]])
	for k in parts.size():
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for piece in parts[k]:
			st.append_from(piece[0], 0, piece[1])
		st.commit(am)
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("part", k)
		am.surface_set_material(k, m)
	_crowd_mesh = am
	return am


func _crowd(center: Vector3, radius_from: float, radius_to: float, rows: int, arc_from: float, arc_to: float, base_y: float, step_h: float) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _fan_mesh()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var palette := [Color("e0533f"), Color("3f7be0"), Color("e8e8ee"), Color("2b2b33"), Color("f0c040"), Color("3fbf8a"), Color("8a4fd9"), Color("d9d2c4"), Color("26364f")]
	var spots: Array = []
	for r in rows:
		var rad := lerpf(radius_from, radius_to, float(r) / maxf(1.0, rows - 1.0))
		# Rows fill by how long they are, with the odd empty seat.
		var per_row := int(rad * absf(arc_to - arc_from) / 0.62)
		for k in per_row:
			if rng.randf() < 0.1:
				continue
			var a := lerpf(arc_from, arc_to, (k + 0.2 + rng.randf() * 0.6) / per_row)
			spots.append([a, rad, base_y + r * step_h + 0.02])
	mm.instance_count = spots.size()
	for i in spots.size():
		var a: float = spots[i][0]
		var p := center + Vector3(sin(a) * float(spots[i][1]), float(spots[i][2]), cos(a) * float(spots[i][1]))
		var sc := rng.randf_range(0.9, 1.12)
		# Facing the field; arms lift toward it.
		var bs := Basis(Vector3.UP, a + PI + rng.randf_range(-0.25, 0.25)).scaled(Vector3(sc, sc * rng.randf_range(0.92, 1.08), sc))
		mm.set_instance_transform(i, Transform3D(bs, p))
		mm.set_instance_color(i, palette[rng.randi() % palette.size()].darkened(rng.randf() * 0.35))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	# Camera flashes popping all over the stands.
	var fm := MultiMesh.new()
	fm.transform_format = MultiMesh.TRANSFORM_3D
	var q := QuadMesh.new()
	q.size = Vector2(1.5, 1.5)
	var fsh := Shader.new()
	fsh.code = FLASH_SH
	var fmat := ShaderMaterial.new()
	fmat.shader = fsh
	q.material = fmat
	fm.mesh = q
	fm.instance_count = mini(90, spots.size())
	for i in fm.instance_count:
		var sp: Array = spots[rng.randi() % spots.size()]
		fm.set_instance_transform(i, Transform3D(Basis.IDENTITY, center + Vector3(sin(float(sp[0])) * float(sp[1]), float(sp[2]) + 0.8, cos(float(sp[0])) * float(sp[1]))))
	var fmi := MultiMeshInstance3D.new()
	fmi.multimesh = fm
	fmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fmi.extra_cull_margin = 4.0
	add_child(fmi)


func _stands(radius: float, rows: int, arc_from: float, arc_to: float, color: Color) -> void:
	var seat := mat(color, 0.7)
	for r in rows:
		var rad := radius + r * 1.3
		var segs := 40
		for k in segs:
			var a := lerpf(arc_from, arc_to, (k + 0.5) / segs)
			var len := rad * absf(arc_to - arc_from) / segs * 1.04
			var b := box(Vector3(len, 0.55, 1.3), Vector3(sin(a) * rad, r * 0.55 + 0.25, cos(a) * rad), seat, false)
			b.rotation.y = a
	_crowd(Vector3.ZERO, radius, radius + (rows - 1) * 1.3, rows, arc_from, arc_to, 0.5, 0.55)


func _screen(text: String, pos: Vector3, rot: float, w: float, h: float, color: Color) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = rot
	add_child(n)
	box(Vector3(w + 0.6, h + 0.6, 0.4), Vector3(0, 0, -0.25), mat(Color(0.1, 0.1, 0.12), 0.5, 0.5), false, n)
	box(Vector3(w, h, 0.05), Vector3.ZERO, glow_mat(Color(color).darkened(0.6), 1.0), false, n)
	var l := Label3D.new()
	l.text = text
	l.font_size = int(h * 90)
	l.pixel_size = 0.01
	l.modulate = Color(color) * 2.2
	l.shaded = false
	l.position = Vector3(0, 0, 0.05)
	l.font = load("res://assets/fonts/Rajdhani-SemiBold.ttf")
	n.add_child(l)


func _spotlight(pos: Vector3, target: Vector3, color: Color) -> void:
	var s := SpotLight3D.new()
	s.light_color = color
	s.light_energy = 6.0
	s.spot_range = 40.0
	s.spot_angle = 14.0
	s.light_volumetric_fog_energy = 3.0
	s.position = pos
	add_child(s)
	s.look_at_from_position(pos, target)
	cyl(0.25, 0.4, 0.6, pos, mat(Color(0.15, 0.15, 0.17), 0.4, 0.7))


# ------------------------------------------------------------------ themes

func _rooftop() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var concrete := _tile_material(Color(0.32, 0.31, 0.34), 2.0)
	box(Vector3(34, 0.2, 28), Vector3(0, -0.15, 0), concrete, false)
	var rail := mat(Color(0.6, 0.62, 0.66), 0.35, 0.8)
	for side in [-1, 1]:
		box(Vector3(34, 1.0, 0.4), Vector3(0, 0.5, side * 14.0), mat(Color(0.3, 0.3, 0.33)), false)
		box(Vector3(0.4, 1.0, 28), Vector3(side * 17.0, 0.5, 0), mat(Color(0.3, 0.3, 0.33)), false)
		box(Vector3(34, 0.08, 0.08), Vector3(0, 1.6, side * 14.0), rail, false)
		box(Vector3(0.08, 0.08, 28), Vector3(side * 17.0, 1.6, 0), rail, false)
	# Helipad-style marking and rooftop gear
	box(Vector3(2.0, 2.4, 3.0), Vector3(-14, 1.2, -10), mat(Color(0.5, 0.5, 0.55), 0.5, 0.5), false)
	box(Vector3(3.0, 3.0, 3.0), Vector3(13, 1.5, -11), mat(Color(0.35, 0.35, 0.4), 0.6), false)
	# Skyline all around
	for i in 46:
		var a := rng.randf() * TAU
		var d := rng.randf_range(32.0, 70.0)
		var h := rng.randf_range(14.0, 70.0)
		var w := rng.randf_range(7.0, 14.0)
		var p := Vector3(sin(a) * d, -30.0, cos(a) * d)
		building(p, Vector3(w, h + 30.0, w), rng)
	var tower := window_material(Color(0.3, 0.36, 0.5), 7.0, Color("7cc4ff"))
	tower.set_shader_parameter("style", 1.0)
	box(Vector3(16, 110, 16), Vector3(-26, 25, -60), tower, false)
	neon_sign("KC", Vector3(-26, 66, -51.9), Color("7cc4ff"), 1400, 0.0, false)
	# Floating blimp with a screen
	var blimp := Node3D.new()
	blimp.position = Vector3(18, 22, -40)
	add_child(blimp)
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 3.0
	cap.height = 14.0
	body.mesh = cap
	body.material_override = mat(Color(0.85, 0.86, 0.9), 0.4, 0.2)
	body.rotation.z = PI / 2
	blimp.add_child(body)
	box(Vector3(6, 2.2, 0.1), Vector3(0, 0, 3.0), glow_mat(theme["accent"], 2.0), false, blimp)
	_bob.append([blimp, 22.0, 0.3])


func _dome() -> void:
	box(Vector3(80, 0.2, 80), Vector3(0, -0.15, 0), mat(Color(0.06, 0.08, 0.14), 0.15, 0.7), false)
	_stands(17.0, 9, -PI, PI, Color(0.16, 0.2, 0.3))
	# Dome ribs
	var rib := mat(Color(0.75, 0.82, 0.95), 0.3, 0.8)
	for k in 12:
		var arc := Node3D.new()
		arc.rotation.y = k * TAU / 12
		add_child(arc)
		for s in 14:
			var a := s * (PI / 2) / 14
			var r := 30.0
			var seg := box(Vector3(0.5, 0.5, 2.4), Vector3(0, sin(a) * r * 0.7, cos(a) * r), rib, false, arc)
			seg.rotation.x = -a
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 27.0
	tm.outer_radius = 27.6
	tm.rings = 96
	ring.mesh = tm
	ring.material_override = glow_mat(theme["accent"], 3.0)
	ring.position.y = 10.0
	add_child(ring)
	for k in 4:
		var a := k * TAU / 4 + PI / 4
		_screen("KAIBACORP", Vector3(sin(a) * 26, 14, cos(a) * 26), a + PI, 10, 5, theme["accent"])
	for k in 6:
		var a := k * TAU / 6
		_spotlight(Vector3(sin(a) * 24, 18, cos(a) * 24), Vector3(0, 0, 0), Color(0.85, 0.92, 1.0))


func _academy() -> void:
	box(Vector3(80, 0.2, 80), Vector3(0, -0.15, 0), mat(Color(0.2, 0.08, 0.08), 0.3, 0.3), false)
	var lines := glow_mat(theme["accent2"], 1.5)
	for r in [10.5, 12.0]:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = r
		tm.outer_radius = r + 0.12
		tm.rings = 96
		ring.mesh = tm
		ring.material_override = lines
		ring.scale = Vector3(1, 0.05, 0.7)
		add_child(ring)
	_stands(16.0, 10, -PI * 0.92, PI * 0.92, Color(0.35, 0.12, 0.12))
	var banner_cols := [Color("d02030"), Color("f0c040"), Color("3070e0")]
	for k in 9:
		var a := lerpf(-PI * 0.8, PI * 0.8, k / 8.0)
		var n := Node3D.new()
		n.position = Vector3(sin(a) * 30, 12, cos(a) * 30)
		n.rotation.y = a + PI
		add_child(n)
		box(Vector3(2.4, 7.0, 0.1), Vector3.ZERO, mat(banner_cols[k % 3], 0.8), false, n)
		box(Vector3(2.6, 0.2, 0.2), Vector3(0, 3.6, 0), mat(Color(0.8, 0.7, 0.3), 0.3, 0.8), false, n)
	_screen("DUEL ACADEMY", Vector3(0, 16, -31), 0.0, 16, 6, theme["accent2"])
	for k in 4:
		var a := k * TAU / 4 + PI / 4
		_spotlight(Vector3(sin(a) * 26, 22, cos(a) * 26), Vector3(0, 0, 0), Color(1.0, 0.9, 0.75))


func _junkyard() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	box(Vector3(90, 0.2, 90), Vector3(0, -0.15, 0), mat(Color(0.18, 0.14, 0.11), 0.95), false)
	var rust := [Color(0.45, 0.25, 0.14), Color(0.3, 0.3, 0.32), Color(0.5, 0.42, 0.3), Color(0.25, 0.2, 0.18), Color(0.4, 0.15, 0.12)]
	for i in 140:
		var a := rng.randf() * TAU
		var d := rng.randf_range(13.0, 40.0)
		var p := Vector3(sin(a) * d, 0, cos(a) * d)
		var s := rng.randf_range(0.8, 3.4)
		var m := mat(rust[rng.randi() % rust.size()], rng.randf_range(0.6, 0.95), rng.randf_range(0.0, 0.6))
		var b: MeshInstance3D
		if rng.randf() < 0.6:
			b = box(Vector3(s, s * rng.randf_range(0.4, 1.0), s * rng.randf_range(0.6, 1.4)), p + Vector3(0, s * 0.3 + (d - 13.0) * 0.08, 0), m, false)
		else:
			b = cyl(s * 0.4, s * 0.4, s * 1.5, p + Vector3(0, s * 0.4 + (d - 13.0) * 0.08, 0), m)
		b.rotation = Vector3(rng.randf_range(-0.6, 0.6), rng.randf() * TAU, rng.randf_range(-0.6, 0.6))
	# Crane
	var steel := mat(Color(0.8, 0.55, 0.15), 0.6, 0.5)
	box(Vector3(1.2, 22, 1.2), Vector3(-20, 11, -24), steel, false)
	var arm := box(Vector3(26, 1.0, 1.0), Vector3(-12, 22, -24), steel, false)
	arm.rotation.y = 0.4
	# The bright city across the water
	for i in 30:
		var x := lerpf(-90, 90, i / 29.0) + rng.randf_range(-3, 3)
		var h := rng.randf_range(10, 45)
		building(Vector3(x, -10, -95 - rng.randf() * 15), Vector3(rng.randf_range(5, 10), h + 10, 8), rng)
	box(Vector3(220, 0.1, 50), Vector3(0, -0.4, -70), mat(Color(0.05, 0.07, 0.1), 0.02, 0.2), false)
	for k in 2:
		_spotlight(Vector3(-14 + k * 28, 9, -14), Vector3(0, 0, 0), Color(1.0, 0.7, 0.4))


func _heartland() -> void:
	box(Vector3(90, 0.2, 90), Vector3(0, -0.15, 0), _tile_material(Color(0.16, 0.12, 0.18), 3.0), false)
	var pink := glow_mat(theme["accent2"], 2.5)
	var gold := glow_mat(theme["accent"], 2.5)
	for k in 16:
		var a := k * TAU / 16
		var line := box(Vector3(0.12, 0.04, 30), Vector3(sin(a) * 25, 0.0, cos(a) * 25), pink if k % 2 == 0 else gold, false)
		line.rotation.y = a
	# Spire with floating rings
	var spire := Node3D.new()
	spire.position = Vector3(0, 0, -50)
	add_child(spire)
	cyl(1.5, 6.0, 90, Vector3(0, 45, 0), mat(Color(0.85, 0.8, 0.9), 0.25, 0.7), spire, 24)
	for i in 5:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 7.0 + i * 1.5
		tm.outer_radius = 7.5 + i * 1.5
		tm.rings = 64
		ring.mesh = tm
		ring.material_override = pink if i % 2 == 0 else gold
		ring.position = Vector3(0, 20 + i * 14, 0)
		ring.rotation.x = 0.25
		ring.set_meta("spin", 0.15 + i * 0.05)
		spire.add_child(ring)
		_spin.append(ring)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for i in 30:
		var a := rng.randf() * TAU
		var d := rng.randf_range(35.0, 75.0)
		building(Vector3(sin(a) * d, -10, cos(a) * d), Vector3(rng.randf_range(6, 12), rng.randf_range(20, 60), rng.randf_range(6, 12)), rng)


# ------------------------------------------------------------------ fields out in the world

## A low stone border around the playmat, for fields with no stage under them.
func _stone_rim(col: Color) -> void:
	var m := mat(col, 0.9)
	for side in [-1, 1]:
		box(Vector3(12.9, 0.22, 0.42), Vector3(0, 0.02, side * 4.02), m, false)
		box(Vector3(0.42, 0.22, 8.4), Vector3(side * 6.22, 0.02, 0), m, false)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			box(Vector3(0.7, 0.5, 0.7), Vector3(sx * 6.22, 0.12, sz * 4.02), mat(col.lightened(0.12), 0.85), false)


func _blob(pos: Vector3, size: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 14
	sm.rings = 7
	mi.mesh = sm
	mi.material_override = m
	mi.scale = size
	mi.position = pos
	add_child(mi)
	return mi


func _cone(pos: Vector3, r: float, h: float, m: Material, sides := 7, top := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = top
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = sides
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos + Vector3(0, h / 2.0, 0)
	add_child(mi)
	return mi


## The land around an open-air field: the same painted ground as the mat running out to the
## horizon, and what belongs in that place standing on it.
func _wild(kind: String) -> void:
	var surface := int(theme.get("surface", 1))
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(260, 260)
	ground.mesh = pm
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded;
uniform int surface = 1;
uniform vec3 haze : source_color = vec3(0.8, 0.9, 1.0);
""" + FieldThemes.GROUND_GLSL + """
void fragment() {
	vec2 p = (UV - 0.5) * 260.0;
	vec3 col = ground_color(p, surface, TIME) * 0.92;
	float far = smoothstep(26.0, 120.0, length(p));
	ALBEDO = mix(col, haze, far * 0.85);
}
"""
	var gm := ShaderMaterial.new()
	gm.shader = sh
	gm.set_shader_parameter("surface", surface)
	gm.set_shader_parameter("haze", theme["fog"])
	ground.material_override = gm
	ground.position = Vector3(0, -0.03, 0)
	add_child(ground)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77 + surface
	# Somewhere to stand: a ring of places around the field, never on it.
	var spots: Array = []
	for i in 46:
		var a := rng.randf() * TAU
		var d := rng.randf_range(13.0, 58.0)
		var p := Vector3(sin(a) * d, 0, cos(a) * d)
		if absf(p.x) < 9.5 and absf(p.z) < 10.5:
			continue
		spots.append(p)
	match kind:
		"meadow":
			_stone_rim(Color(0.62, 0.6, 0.55))
			for i in spots.size():
				var p: Vector3 = spots[i]
				if i % 3 == 0:
					_blob(p + Vector3(0, 0.25, 0), Vector3(rng.randf_range(0.8, 2.0), rng.randf_range(0.5, 1.0), rng.randf_range(0.8, 1.6)), mat(Color(0.55, 0.56, 0.58), 0.95))
				else:
					var s := rng.randf_range(0.8, 1.5)
					cyl(0.14 * s, 0.24 * s, 2.4 * s, p + Vector3(0, 1.2 * s, 0), mat(Color(0.34, 0.23, 0.14), 0.95))
					for k in 3:
						_blob(p + Vector3(rng.randf_range(-0.6, 0.6) * s, (2.7 + k * 0.6) * s, rng.randf_range(-0.6, 0.6) * s), Vector3.ONE * rng.randf_range(1.8, 2.6) * s,
								mat(Color(0.16, 0.42, 0.16).lerp(Color(0.34, 0.6, 0.2), rng.randf()), 0.95))
			for i in 9:
				var a := i * TAU / 9.0 + 0.3
				_blob(Vector3(sin(a) * 95.0, -6.0, cos(a) * 95.0), Vector3(rng.randf_range(60, 90), rng.randf_range(22, 40), rng.randf_range(50, 80)), mat(Color(0.2, 0.46, 0.2).lerp(Color(0.5, 0.7, 0.5), 0.35), 1.0))
			# A windmill on the hill behind the far duelist.
			var wm := Vector3(-16.0, 0, -30.0)
			_cone(wm, 2.2, 8.0, mat(Color(0.92, 0.9, 0.84), 0.9), 10, 1.4)
			_cone(wm + Vector3(0, 8.0, 0), 1.9, 2.2, mat(Color(0.62, 0.22, 0.16), 0.8), 10)
			var hub := Node3D.new()
			hub.position = wm + Vector3(0, 7.0, 1.7)
			add_child(hub)
			for k in 4:
				var blade := box(Vector3(0.9, 5.2, 0.08), Vector3(0, 2.8, 0), mat(Color(0.95, 0.93, 0.88), 0.8), false, hub)
				blade.position = Vector3(sin(k * PI / 2.0) * 2.8, cos(k * PI / 2.0) * 2.8, 0)
				blade.rotation.z = -k * PI / 2.0
			hub.set_meta("spin_z", 0.5)
			_spin_z.append(hub)
		"volcano":
			_stone_rim(Color(0.1, 0.08, 0.08))
			var basalt := mat(Color(0.09, 0.075, 0.07), 0.95)
			for i in spots.size():
				var p: Vector3 = spots[i]
				if i % 4 == 0:
					cyl(rng.randf_range(1.0, 2.6), rng.randf_range(1.2, 3.0), 0.05, p + Vector3(0, 0.0, 0), glow_mat(Color("ff6a1a"), 2.6), null, 12)
				else:
					var h := rng.randf_range(1.2, 5.5)
					_cone(p, rng.randf_range(0.6, 1.8), h, basalt, 5 + i % 3).rotation.z = rng.randf_range(-0.2, 0.2)
			var vc := Vector3(8.0, 0, -62.0)
			_cone(vc, 30.0, 26.0, mat(Color(0.11, 0.08, 0.075), 1.0), 12, 7.0)
			cyl(6.6, 6.6, 0.3, vc + Vector3(0, 25.9, 0), glow_mat(Color("ff7a1a"), 4.0), null, 12)
			for k in 3:
				box(Vector3(1.6 - k * 0.3, 14.0, 0.3), vc + Vector3(-5.0 + k * 5.0, 17.0 - k * 2.0, 22.0 - k * 2.5), glow_mat(Color("ff5a10"), 3.0), false).rotation.x = -0.72
			_cone(Vector3(-52.0, 0, -44.0), 18.0, 14.0, mat(Color(0.1, 0.08, 0.075), 1.0), 9, 4.0)
			var glow := OmniLight3D.new()
			glow.light_color = Color("ff6a2a")
			glow.light_energy = 3.0
			glow.omni_range = 26.0
			glow.position = Vector3(0, 5.0, -8.0)
			add_child(glow)
		"peak":
			_stone_rim(Color(0.5, 0.53, 0.6))
			var stone := mat(Color(0.36, 0.38, 0.44), 0.95)
			var snow := mat(Color(0.93, 0.96, 1.0), 0.8)
			for i in spots.size():
				var p: Vector3 = spots[i]
				if i % 3 == 0:
					# A pine: three stacked cones dusted white.
					var s := rng.randf_range(0.8, 1.4)
					cyl(0.12 * s, 0.2 * s, 1.0 * s, p + Vector3(0, 0.5 * s, 0), mat(Color(0.28, 0.2, 0.14), 0.95))
					for k in 3:
						_cone(p + Vector3(0, (0.8 + k * 1.0) * s, 0), (1.3 - k * 0.32) * s, 1.6 * s, mat(Color(0.1, 0.28, 0.2).lerp(Color(0.9, 0.95, 1.0), 0.18 + k * 0.14), 0.9), 8)
				else:
					var bs := Vector3(rng.randf_range(1.0, 3.0), rng.randf_range(0.8, 2.0), rng.randf_range(1.0, 2.4))
					_blob(p + Vector3(0, bs.y * 0.3, 0), bs, stone)
					_blob(p + Vector3(0, bs.y * 0.62, 0), bs * Vector3(0.8, 0.5, 0.8), snow)
			for i in 11:
				var a := i * TAU / 11.0 + 0.2
				var d := rng.randf_range(75.0, 110.0)
				var h := rng.randf_range(34.0, 62.0)
				var at := Vector3(sin(a) * d, -6.0, cos(a) * d)
				_cone(at, h * 0.62, h, mat(Color(0.34, 0.38, 0.48), 1.0), 7)
				_cone(at + Vector3(0, h * 0.58, 0), h * 0.265, h * 0.43, snow, 7)
		"ruins":
			_stone_rim(Color(0.66, 0.58, 0.44))
			var sandstone := mat(Color(0.72, 0.62, 0.44), 0.95)
			for i in spots.size():
				var p: Vector3 = spots[i]
				match i % 4:
					0:
						var h := rng.randf_range(2.0, 6.5)
						cyl(0.5, 0.56, h, p + Vector3(0, h / 2.0, 0), sandstone, null, 12)
						box(Vector3(1.4, 0.3, 1.4), p + Vector3(0, 0.15, 0), sandstone, false)
						if h > 5.0:
							box(Vector3(1.5, 0.4, 1.5), p + Vector3(0, h + 0.2, 0), sandstone, false)
					1:
						var lying := cyl(0.46, 0.5, rng.randf_range(2.0, 4.0), p + Vector3(0, 0.46, 0), sandstone, null, 12)
						lying.rotation = Vector3(PI / 2.0, rng.randf() * TAU, 0)
					2:
						_blob(p + Vector3(0, 0.1, 0), Vector3(rng.randf_range(4.0, 9.0), rng.randf_range(0.8, 1.8), rng.randf_range(3.0, 7.0)), mat(Color(0.8, 0.68, 0.44), 1.0))
					3:
						box(Vector3(rng.randf_range(1.0, 2.2), rng.randf_range(0.6, 1.6), rng.randf_range(1.0, 2.0)), p + Vector3(0, 0.4, 0), sandstone, false).rotation.y = rng.randf() * TAU
			# A gate behind the far duelist and pyramids on the horizon.
			for sx: float in [-1.0, 1.0]:
				cyl(0.8, 0.9, 9.0, Vector3(sx * 4.6, 4.5, -15.0), sandstone, null, 12)
			box(Vector3(12.0, 1.3, 2.0), Vector3(0, 9.6, -15.0), sandstone, false)
			for py in [[Vector3(-40, 0, -70), 30.0], [Vector3(26, 0, -86), 40.0], [Vector3(70, 0, -40), 22.0]]:
				_cone(py[0], float(py[1]), float(py[1]) * 0.78, mat(Color(0.78, 0.66, 0.44), 1.0), 4).rotation.y = PI / 4.0
		"tide":
			# The field sits on a stone slab in knee-deep water.
			box(Vector3(14.6, 0.5, 9.6), Vector3(0, -0.29, 0), mat(Color(0.6, 0.62, 0.6), 0.9), false)
			_stone_rim(Color(0.7, 0.72, 0.7))
			for i in spots.size():
				var p: Vector3 = spots[i]
				if i % 3 == 0:
					# A palm: a leaning trunk and a fan of leaves.
					var lean := rng.randf_range(-0.2, 0.2)
					var h := rng.randf_range(4.0, 6.5)
					_blob(p + Vector3(0, -0.2, 0), Vector3(5.0, 0.9, 5.0), mat(Color(0.86, 0.78, 0.56), 1.0))
					var trunk := cyl(0.14, 0.24, h, p + Vector3(0, h / 2.0, 0), mat(Color(0.5, 0.38, 0.24), 0.95), null, 8)
					trunk.rotation.z = lean
					var top := p + Vector3(-sin(lean) * h * 0.5, h * 0.98, 0)
					for k in 7:
						var leaf := box(Vector3(2.6, 0.06, 0.6), top, mat(Color(0.16, 0.5, 0.22), 0.9), false)
						leaf.rotation = Vector3(0, k * TAU / 7.0, -0.45)
						leaf.position += Vector3(cos(-k * TAU / 7.0), -0.25, sin(-k * TAU / 7.0)) * 1.1
				else:
					_blob(p + Vector3(0, 0.0, 0), Vector3(rng.randf_range(1.0, 3.2), rng.randf_range(0.8, 2.2), rng.randf_range(1.0, 2.6)), mat(Color(0.42, 0.44, 0.46), 0.95))
			for i in 6:
				var a := i * TAU / 6.0 + 0.5
				_blob(Vector3(sin(a) * 100.0, -4.0, cos(a) * 100.0), Vector3(rng.randf_range(40, 70), rng.randf_range(14, 26), rng.randf_range(30, 50)), mat(Color(0.2, 0.5, 0.28), 1.0))


var _spin_z: Array = []


func _void() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var rock := mat(Color(0.18, 0.2, 0.26), 0.9)
	var top := mat(Color(0.12, 0.3, 0.32), 0.8)
	for i in 18:
		var a := rng.randf() * TAU
		var d := rng.randf_range(16.0, 45.0)
		var s := rng.randf_range(1.5, 5.0)
		var y := rng.randf_range(-8.0, 10.0)
		var island := Node3D.new()
		island.position = Vector3(sin(a) * d, y, cos(a) * d)
		add_child(island)
		cyl(s, s * 0.2, s * 1.8, Vector3(0, -s * 0.9, 0), rock, island, 7)
		cyl(s * 1.02, s, 0.25, Vector3(0, 0.05, 0), top, island, 7)
		_bob.append([island, y, rng.randf_range(0.2, 0.5)])
	for i in 3:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 22.0 + i * 6.0
		tm.outer_radius = 22.3 + i * 6.0
		tm.rings = 128
		ring.mesh = tm
		ring.material_override = glow_mat(theme["accent"] if i != 1 else theme["accent2"], 2.0)
		ring.rotation = Vector3(0.3 * (i - 1), 0, 0.2 * i)
		ring.set_meta("spin", 0.05 * (i + 1))
		add_child(ring)
		_spin.append(ring)
