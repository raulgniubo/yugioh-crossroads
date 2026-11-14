class_name ArenaScenery
extends RefCounted
## What makes Satellite and Heartland places of their own instead of a ring with props round it.
## Satellite is a scrapyard town under a broken highway: a runner garage you can walk into,
## homes made of shipping containers, sagging power lines, a fire in a barrel, fences patched
## from tin. Heartland is a city that is half fairground: glass towers, a monorail doing laps
## overhead, a big wheel turning beyond the roofs, balloons, floating screens and flower beds.

const R := 40.0     # the walkable radius (ArenaDistrict.RADIUS)


static func _rot(yaw: float, pitch := 0.0, roll := 0.0) -> Basis:
	return Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch) * Basis(Vector3.BACK, roll)


static func _ball(c: CityBuilder, pos: Vector3, r: float, m: Material, parent: Node3D = null, squash := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 14
	sm.rings = 7
	mi.mesh = sm
	mi.material_override = m
	mi.position = pos
	mi.scale = squash
	(parent if parent else c).add_child(mi)
	return mi


static func _torus(c: CityBuilder, pos: Vector3, radius: float, tube: float, m: Material, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = radius - tube
	tm.outer_radius = radius + tube
	tm.rings = 48
	tm.ring_segments = 8
	mi.mesh = tm
	mi.material_override = m
	mi.position = pos
	(parent if parent else c).add_child(mi)
	return mi


## Hundreds of small blooms as one draw call per color instead of one per flower.
class Blooms:
	var by_mat := {}          # Material -> Array of Transform3D

	func add(m: Material, at: Vector3, r: float) -> void:
		if not by_mat.has(m):
			by_mat[m] = []
		(by_mat[m] as Array).append(Transform3D(Basis.from_scale(Vector3(r, r * 0.7, r)), at))

	func commit(parent: Node3D) -> void:
		for m in by_mat:
			var list: Array = by_mat[m]
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			var sm := SphereMesh.new()
			sm.radius = 1.0
			sm.height = 2.0
			sm.radial_segments = 8
			sm.rings = 4
			sm.material = m
			mm.mesh = sm
			mm.instance_count = list.size()
			for i in list.size():
				mm.set_instance_transform(i, list[i])
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(mmi)


static func _holder(c: CityBuilder, at: Vector3, yaw: float) -> Node3D:
	var h := Node3D.new()
	h.position = at
	h.rotation.y = yaw
	c.add_child(h)
	return h


static func _smoke(c: CityBuilder, at: Vector3, size: float, rise: float, life: float, tint: Color, amount := 14) -> void:
	var smoke := GPUParticles3D.new()
	smoke.amount = amount
	smoke.lifetime = life
	smoke.preprocess = life
	var ppm := ParticleProcessMaterial.new()
	ppm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	ppm.emission_sphere_radius = size * 0.4
	ppm.direction = Vector3(0.3, 1.0, 0.1)
	ppm.spread = 10.0
	ppm.initial_velocity_min = rise * 0.8
	ppm.initial_velocity_max = rise * 1.2
	ppm.gravity = Vector3(rise * 0.12, rise * 0.04, 0.0)
	ppm.scale_min = 0.5
	ppm.scale_max = 1.2
	var ramp := Curve.new()
	ramp.add_point(Vector2(0.0, 0.3))
	ramp.add_point(Vector2(1.0, 1.0))
	var ct := CurveTexture.new()
	ct.curve = ramp
	ppm.scale_curve = ct
	var fade := Gradient.new()
	fade.set_color(0, Color(tint, 0.0))
	fade.add_point(0.15, Color(tint, 0.5))
	fade.set_color(fade.get_point_count() - 1, Color(tint.lightened(0.3), 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = fade
	ppm.color_ramp = gt
	smoke.process_material = ppm
	var puff := SphereMesh.new()
	puff.radius = size
	puff.height = size * 1.6
	puff.radial_segments = 10
	puff.rings = 6
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.vertex_color_use_as_albedo = true
	pm.disable_fog = true
	puff.material = pm
	smoke.draw_pass_1 = puff
	smoke.position = at
	var reach := rise * life * 1.3 + size * 3.0
	smoke.visibility_aabb = AABB(Vector3(-reach, -size, -reach), Vector3(reach * 2.0, reach + size * 2.0, reach * 2.0))
	smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	c.add_child(smoke)


# ====================================================================== Satellite

static func satellite(c: ArenaDistrict) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	_sat_ground(c, rng)
	_sat_heaps(c, rng)
	_sat_garage(c)
	_sat_containers(c, Vector3(31.5, 0, 5.0), -PI / 2.0)
	_sat_overpass(c, rng)
	_sat_poles(c)
	_sat_yard(c, rng)
	_sat_far(c)


## Cracked concrete, a patched road with what is left of its paint, oil, dirt and standing water.
static func _sat_ground(c: ArenaDistrict, rng: RandomNumberGenerator) -> void:
	var batch := CityBuilder.BoxBatch.new()
	var patch := c.mat(Color(0.07, 0.068, 0.074), 0.95)
	var paint := c.mat(Color(0.6, 0.52, 0.26), 0.92)
	var white := c.mat(Color(0.58, 0.58, 0.55), 0.92)
	var crack := c.mat(Color(0.035, 0.034, 0.04), 1.0)
	var dirt := c.mat(Color(0.3, 0.27, 0.23), 0.98)
	var oil := c.mat(Color(0.03, 0.03, 0.04), 0.12, 0.5)
	var wet := c.mat(Color(0.2, 0.23, 0.27), 0.03, 0.75)
	# What is left of the center line: most dashes worn half away, some gone.
	for k in range(-7, 9):
		if rng.randf() < 0.25 or absf(k * 4.2 + 2.0) < 5.2:
			continue
		batch.add(Vector3(0.16, 0.012, rng.randf_range(0.9, 2.2)), Vector3(rng.randf_range(-0.05, 0.05), 0.034, k * 4.2 + 2.0), paint)
	for k in range(-6, 7):
		if rng.randf() < 0.25 or absf(k * 4.4) < 3.5:
			continue
		batch.add(Vector3(rng.randf_range(0.9, 2.2), 0.012, 0.16), Vector3(k * 4.4, 0.034, 20.0 + rng.randf_range(-0.05, 0.05)), paint)
	# Edge lines, broken up, and a stop bar where the roads meet.
	for s: float in [-1.0, 1.0]:
		var z := -32.0
		while z < 36.0:
			var run := rng.randf_range(1.5, 6.0)
			if absf(z + run / 2.0 - 20.0) > 3.4 and absf(z + run / 2.0) > 5.6:
				batch.add(Vector3(0.1, 0.012, run), Vector3(s * 2.25, 0.034, z + run / 2.0), white)
			z += run + rng.randf_range(0.6, 3.0)
	batch.add(Vector3(4.2, 0.012, 0.34), Vector3(0, 0.034, 16.9), white)
	# Patches of newer tar, potholes, and cracks running off across the concrete.
	for k in 22:
		var on_cross := k % 3 == 0
		var p := Vector3(rng.randf_range(-28.0, 28.0), 0.03, 20.0 + rng.randf_range(-1.6, 1.6)) if on_cross else Vector3(rng.randf_range(-2.0, 2.0), 0.03, rng.randf_range(-31.0, 35.0))
		if p.length() < 7.0:
			continue
		batch.add(Vector3(rng.randf_range(0.6, 2.0), 0.012, rng.randf_range(0.6, 2.4)), p, patch, _rot(rng.randf_range(-0.3, 0.3)))
	for k in 46:
		var a := rng.randf() * TAU
		var d := rng.randf_range(7.0, 38.0)
		var p2 := Vector3(cos(a) * d, 0.022, sin(a) * d)
		var yaw := rng.randf() * TAU
		for seg in rng.randi_range(2, 5):
			var ln := rng.randf_range(0.7, 2.4)
			batch.add(Vector3(ln, 0.01, rng.randf_range(0.025, 0.05)), p2, crack, _rot(yaw))
			p2 += Vector3(cos(-yaw), 0, sin(-yaw)) * ln * 0.5
			yaw += rng.randf_range(-0.9, 0.9)
			p2 += Vector3(cos(-yaw), 0, sin(-yaw)) * ln * 0.5
	batch.commit(c)
	# Dirt blown in from the heaps, oil where the runners park, puddles from the last rain.
	for k in 26:
		var a2 := rng.randf() * TAU
		var d2 := rng.randf_range(9.0, 39.0)
		var p3 := Vector3(cos(a2) * d2, 0.016, sin(a2) * d2)
		if absf(p3.x) < 3.4 or absf(p3.z - 20.0) < 2.8:
			continue
		var rr := rng.randf_range(1.2, 4.2)
		var disc := c.cyl(rr, rr, 0.008, p3, dirt, null, 12)
		disc.scale = Vector3(1.0, 1.0, rng.randf_range(0.45, 0.9))
		disc.rotation.y = rng.randf() * TAU
		disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for spot in [Vector3(-12.5, 0, 11.6), Vector3(-9.4, 0, 12.0), Vector3(12.4, 0, -10.2), Vector3(-9.0, 0, 15.2), Vector3(1.2, 0, 26.0), Vector3(-1.0, 0, -14.0)]:
		var o := c.cyl(0.55, 0.55, 0.006, (spot as Vector3) + Vector3(0, 0.04, 0), oil, null, 12)
		o.scale = Vector3(1.0, 1.0, 0.7)
		o.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for pud in [[Vector3(5.2, 0, 11.0), 1.6], [Vector3(-16.0, 0, -4.0), 2.2], [Vector3(14.0, 0, 26.5), 1.9], [Vector3(-4.0, 0, -22.0), 2.6], [Vector3(22.0, 0, 3.0), 1.4],
			[Vector3(-28.0, 0, 14.0), 2.0], [Vector3(9.0, 0, -19.0), 1.5], [Vector3(1.6, 0, 31.0), 1.2]]:
		var w := c.cyl(pud[1], pud[1], 0.006, (pud[0] as Vector3) + Vector3(0, 0.045, 0), wet, null, 16)
		w.scale = Vector3(1.0, 1.0, 0.6)
		w.rotation.y = (pud[0] as Vector3).x
		w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## The heaps round the edge: sheet, beams, crushed bales, dead appliances, pipes and tyres,
## piled on mounds of earth instead of the loose cubes that stood here before.
static func _sat_heaps(c: ArenaDistrict, rng: RandomNumberGenerator) -> void:
	var batch := CityBuilder.BoxBatch.new()
	var mats: Array = [c.mat(Color(0.45, 0.25, 0.14), 0.9, 0.3), c.mat(Color(0.32, 0.31, 0.32), 0.7, 0.5), c.mat(Color(0.5, 0.42, 0.3), 0.9, 0.1),
			c.mat(Color(0.26, 0.2, 0.17), 0.95, 0.2), c.mat(Color(0.4, 0.16, 0.12), 0.9, 0.3), c.mat(Color(0.2, 0.36, 0.38), 0.85, 0.3),
			c.mat(Color(0.56, 0.48, 0.2), 0.85, 0.3), c.mat(Color(0.7, 0.7, 0.68), 0.6, 0.2), c.mat(Color(0.2, 0.26, 0.38), 0.85, 0.3)]
	var earth := c.mat(Color(0.17, 0.14, 0.11), 1.0)
	var tyre := c.mat(Color(0.06, 0.06, 0.065), 0.9)
	var mounds := 13
	for hi in mounds:
		var ang := hi * TAU / mounds + 0.2 + rng.randf_range(-0.08, 0.08)
		var far: bool = hi % 2 == 1
		var d := R + (rng.randf_range(17.0, 24.0) if far else rng.randf_range(8.0, 12.5))
		var center := Vector3(sin(ang) * d, 0, cos(ang) * d)
		# Keep the way under the overpass and the view of the far city open.
		if center.z < -30.0 and absf(center.x) < 26.0 and not far:
			continue
		var rad := minf(rng.randf_range(7.0, 10.5), d - R - 0.6) if not far else rng.randf_range(9.0, 14.0)
		var hgt := rng.randf_range(3.2, 5.6) if not far else rng.randf_range(6.0, 10.0)
		var core := c.cyl(rad * 0.22, rad * 0.98, hgt * 0.86, center + Vector3(0, hgt * 0.43 - 0.05, 0), earth, null, 9)
		core.rotation.y = rng.randf() * TAU
		for k in (52 if not far else 40):
			var rr := sqrt(rng.randf()) * rad
			var aa := rng.randf() * TAU
			var y := hgt * 0.86 * (1.0 - rr / rad)
			var p := center + Vector3(cos(aa) * rr, y, sin(aa) * rr)
			var m: Material = mats[rng.randi() % mats.size()]
			var lean := _rot(rng.randf() * TAU, rng.randf_range(-0.7, 0.7), rng.randf_range(-0.7, 0.7))
			match rng.randi() % 9:
				0, 1, 2, 3:
					batch.add(Vector3(rng.randf_range(1.2, 3.4), 0.07, rng.randf_range(0.8, 2.2)), p + Vector3(0, 0.2, 0), m, lean)
				4, 5:
					batch.add(Vector3(rng.randf_range(0.8, 2.0), rng.randf_range(0.5, 1.2), rng.randf_range(0.8, 2.2)), p + Vector3(0, 0.3, 0), m, lean)
				6:
					batch.add(Vector3(0.22, 0.26, rng.randf_range(3.0, 6.5)), p + Vector3(0, 0.5, 0), mats[1], lean)
				7:
					batch.add(Vector3(0.75, 1.5, 0.7), p + Vector3(0, 0.4, 0), mats[7] if rng.randf() < 0.6 else mats[5], lean)
				8:
					batch.add(Vector3(1.7, 0.5, 3.6), p + Vector3(0, 0.3, 0), m, lean)
					batch.add(Vector3(1.5, 0.45, 1.8), p + lean * Vector3(0, 0.45, -0.2) + Vector3(0, 0.3, 0), m, lean)
		for k in (7 if not far else 3):
			var rr2 := sqrt(rng.randf()) * rad
			var aa2 := rng.randf() * TAU
			var p2 := center + Vector3(cos(aa2) * rr2, hgt * 0.86 * (1.0 - rr2 / rad) + 0.25, sin(aa2) * rr2)
			if k % 2 == 0:
				var t := c.cyl(0.42, 0.42, 0.24, p2, tyre, null, 12)
				t.rotation = Vector3(rng.randf_range(-1.2, 1.2), rng.randf() * TAU, rng.randf_range(-0.5, 0.5))
			else:
				var pipe := c.cyl(0.2, 0.2, rng.randf_range(2.5, 5.0), p2 + Vector3(0, 0.3, 0), mats[rng.randi() % 3], null, 8)
				pipe.rotation = Vector3(rng.randf_range(1.0, 1.6), rng.randf() * TAU, 0.0)
	batch.commit(c)


## The runner garage: a tin shed with its door rolled up. You can walk in: a runner up on the
## lift, tools on the wall, somebody welding in the corner.
static func _sat_garage(c: ArenaDistrict) -> void:
	var w := 10.0
	var d := 6.2
	var hgt := 4.6
	var zf := d / 2.0
	var h := _holder(c, Vector3(-10.5, 0, 19.2), PI)
	var batch := CityBuilder.BoxBatch.new()
	var tin := c.mat(Color(0.36, 0.37, 0.38), 0.6, 0.5)
	var tin2 := c.mat(Color(0.3, 0.3, 0.31), 0.6, 0.5)
	var rust := c.mat(Color(0.46, 0.25, 0.15), 0.9, 0.2)
	var dark := c.mat(Color(0.1, 0.1, 0.11), 0.6, 0.4)
	var slab := c.surf("concrete", Color(0.4, 0.39, 0.37))
	var wood := c.surf("wood", Color(0.42, 0.31, 0.2))
	var red := c.mat(Color(0.68, 0.15, 0.11), 0.5, 0.4)
	var on: bool = c.make_solid
	c.box(Vector3(w + 0.6, 0.1, d + 2.6), Vector3(0, 0.03, 0.9), slab, false, h)
	# Walls: back, two sides, and the office end of the front. The rest of the front is the door.
	var open_l := -4.6
	var open_r := 1.6
	for wall in [[Vector3(w, hgt, 0.16), Vector3(0, hgt / 2.0, -zf + 0.08)], [Vector3(0.16, hgt, d), Vector3(-w / 2.0 + 0.08, hgt / 2.0, 0)], [Vector3(0.16, hgt, d), Vector3(w / 2.0 - 0.08, hgt / 2.0, 0)],
			[Vector3(w / 2.0 - open_r, hgt, 0.16), Vector3((w / 2.0 + open_r) / 2.0, hgt / 2.0, zf - 0.08)], [Vector3(open_l + w / 2.0, hgt, 0.16), Vector3((open_l - w / 2.0) / 2.0, hgt / 2.0, zf - 0.08)]]:
		c.box(wall[0], wall[1], tin, false, h)
		c._dorm_solid(h, on, wall[0], wall[1])
	c.box(Vector3(open_r - open_l, hgt - 3.5, 0.16), Vector3((open_l + open_r) / 2.0, 3.5 + (hgt - 3.5) / 2.0, zf - 0.08), tin, false, h)
	# Ribs on every wall, a rust streak under each rivet line.
	for face in 4:
		var basis := [Basis.IDENTITY, _rot(PI), _rot(PI / 2.0), _rot(-PI / 2.0)][face] as Basis
		var half := w / 2.0 if face < 2 else d / 2.0
		var out := zf if face < 2 else w / 2.0
		var x := -half + 0.2
		while x < half:
			var skip := face == 0 and x > open_l - 0.1 and x < open_r + 0.1
			batch.add(Vector3(0.07, (hgt - 3.6) if skip else hgt, 0.04), basis * Vector3(x, (3.5 + (hgt - 3.5) / 2.0) if skip else hgt / 2.0, out + 0.02), tin2, basis)
			x += 0.4
		batch.add(Vector3(half * 2.0, 0.5, 0.03), basis * Vector3(0, 0.25, out + 0.015), rust, basis)
	# The door rolled up under the lintel, its guides down either side.
	for sl in 4:
		batch.add(Vector3(open_r - open_l, 0.16, 0.12), Vector3((open_l + open_r) / 2.0, 3.42 - sl * 0.15, zf + 0.04 + (sl % 2) * 0.02), tin2)
	for ex: float in [open_l, open_r]:
		batch.add(Vector3(0.12, 3.5, 0.2), Vector3(ex, 1.75, zf + 0.02), dark)
	batch.add(Vector3(open_r - open_l + 0.3, 0.3, 0.3), Vector3((open_l + open_r) / 2.0, 3.66, zf + 0.06), dark)
	# A tin roof, tipped to shed the rain off the back.
	var tip := _rot(0.0, -0.09)
	batch.add(Vector3(w + 0.9, 0.08, d + 1.6), Vector3(0, hgt + 0.28, 0.25), rust, tip)
	var rx := -w / 2.0 - 0.3
	while rx < w / 2.0 + 0.4:
		batch.add(Vector3(0.07, 0.05, d + 1.6), Vector3(rx, hgt + 0.34, 0.25), c.mat(Color(0.36, 0.2, 0.13), 0.9, 0.2), tip)
		rx += 0.45
	# The office end: a window with a blind, a door, a board with the day's prices.
	batch.add(Vector3(1.5, 1.1, 0.06), Vector3(3.4, 1.9, zf + 0.03), c.glow_mat(Color(1.0, 0.8, 0.5), 0.6))
	for sl in 5:
		batch.add(Vector3(1.5, 0.05, 0.03), Vector3(3.4, 1.5 + sl * 0.2, zf + 0.07), c.mat(Color(0.8, 0.78, 0.7), 0.8))
	batch.add(Vector3(1.66, 0.08, 0.14), Vector3(3.4, 1.32, zf + 0.06), dark)
	batch.add(Vector3(1.0, 1.3, 0.05), Vector3(2.2, 2.2, zf + 0.04), c.mat(Color(0.08, 0.1, 0.09), 0.9))
	for j in 4:
		batch.add(Vector3(0.7 - (j % 2) * 0.2, 0.05, 0.01), Vector3(2.2, 2.65 - j * 0.26, zf + 0.07), c.mat(Color(0.9, 0.88, 0.8), 0.9))
	# Inside. Back wall: a tool board in the light of a strip lamp, shelves of parts.
	batch.add(Vector3(5.2, 1.5, 0.06), Vector3(-1.6, 2.1, -zf + 0.2), wood)
	var tools := [[-3.6, 0.7, 0.08], [-3.2, 0.5, 0.1], [-2.8, 0.9, 0.06], [-2.3, 0.4, 0.3], [-1.7, 0.8, 0.07], [-1.3, 0.6, 0.12], [-0.8, 0.7, 0.07], [-0.3, 0.35, 0.35], [0.3, 0.9, 0.08], [0.7, 0.5, 0.1]]
	for t in tools:
		batch.add(Vector3(t[2], t[1], 0.03), Vector3(t[0], 2.2 + (0.9 - float(t[1])) / 2.0 - 0.2, -zf + 0.25), c.mat(Color(0.62, 0.64, 0.66), 0.35, 0.8))
	batch.add(Vector3(5.0, 0.07, 0.1), Vector3(-1.6, 3.35, -zf + 0.3), c.glow_mat(Color(1.0, 0.95, 0.82), 2.4))
	for row in 2:
		batch.add(Vector3(2.6, 0.06, 0.5), Vector3(3.4, 1.1 + row * 0.8, -zf + 0.4), wood)
		for k in 6:
			batch.add(Vector3(0.3, 0.26 + (k % 3) * 0.08, 0.3), Vector3(2.3 + k * 0.43, 1.28 + row * 0.8 + (k % 3) * 0.04, -zf + 0.4),
					c.mat([Color(0.62, 0.64, 0.66), Color(0.75, 0.42, 0.2), Color(0.2, 0.5, 0.56), Color(0.78, 0.66, 0.24)][(k + row) % 4], 0.6, 0.3))
	c._dorm_solid(h, on, Vector3(2.8, 2.2, 0.6), Vector3(3.4, 1.1, -zf + 0.4))
	# The lift, with a runner up on it.
	var lift := Vector3(-1.6, 0, 0.0)
	batch.add(Vector3(3.0, 0.14, 1.3), lift + Vector3(0, 0.95, 0), c.mat(Color(0.8, 0.6, 0.12), 0.6, 0.4))
	batch.add(Vector3(3.2, 0.1, 1.5), lift + Vector3(0, 0.05, 0), dark)
	for sx: float in [-1.0, 1.0]:
		batch.add(Vector3(2.9, 0.1, 0.1), lift + Vector3(0, 0.5, sx * 0.5), dark, _rot(0.0, 0.0, 0.3))
		batch.add(Vector3(2.9, 0.1, 0.1), lift + Vector3(0, 0.5, sx * 0.5), dark, _rot(0.0, 0.0, -0.3))
	var bike := c.prop("motorcycle", lift + Vector3(0, 1.02, 0), PI / 2.0, 2.3, false, h)
	if bike == null:
		batch.add(Vector3(2.0, 0.6, 0.5), lift + Vector3(0, 1.4, 0), red)
	c._dorm_solid(h, on, Vector3(3.2, 2.0, 1.5), lift + Vector3(0, 1.0, 0))
	# A red tool chest on wheels, a bench with a vice, tyres against the wall, a jack.
	var chest := Vector3(-4.0, 0, -1.6)
	batch.add(Vector3(0.9, 1.0, 0.55), chest + Vector3(0, 0.6, 0), red)
	for dr in 4:
		batch.add(Vector3(0.8, 0.03, 0.03), chest + Vector3(0, 0.3 + dr * 0.22, 0.29), c.mat(Color(0.8, 0.8, 0.8), 0.3, 0.8))
	c._dorm_solid(h, on, Vector3(0.9, 1.2, 0.6), chest + Vector3(0, 0.6, 0))
	var bench := Vector3(3.6, 0, 1.2)
	batch.add(Vector3(0.8, 0.08, 2.2), bench + Vector3(0, 0.9, 0), wood)
	for lz: float in [-1.0, 1.0]:
		batch.add(Vector3(0.7, 0.9, 0.08), bench + Vector3(0, 0.45, lz), dark)
	batch.add(Vector3(0.24, 0.2, 0.3), bench + Vector3(0, 1.04, -0.6), c.mat(Color(0.2, 0.3, 0.5), 0.5, 0.5))
	batch.add(Vector3(0.5, 0.26, 0.3), bench + Vector3(0, 1.07, 0.5), red)
	c._dorm_solid(h, on, Vector3(0.8, 1.0, 2.2), bench + Vector3(0, 0.5, 0))
	for k in 3:
		c.cyl(0.4, 0.4, 0.22, Vector3(-4.3, 0.11 + k * 0.22, 1.8), dark, h, 12)
	c.cyl(0.4, 0.4, 0.22, Vector3(-4.55, 0.42, 0.9), dark, h, 12).rotation.z = 1.2
	# The lamp over the lift swings a warm pool; the welder's arc flickers blue from the corner.
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.86, 0.62)
	lamp.light_energy = 2.6
	lamp.omni_range = 7.5
	lamp.position = Vector3(-1.6, 3.3, 0.2)
	h.add_child(lamp)
	c.cyl(0.26, 0.05, 0.2, Vector3(-1.6, 3.6, 0.2), dark, h, 10)
	c.box(Vector3(0.14, 0.1, 0.14), Vector3(-1.6, 3.48, 0.2), c.glow_mat(Color(1.0, 0.9, 0.7), 3.0), false, h)
	var arc := OmniLight3D.new()
	arc.light_color = Color(0.6, 0.8, 1.0)
	arc.light_energy = 3.0
	arc.omni_range = 5.0
	arc.position = Vector3(1.0, 0.9, -1.9)
	h.add_child(arc)
	var spark := c.box(Vector3(0.1, 0.1, 0.1), Vector3(1.0, 0.72, -1.9), c.glow_mat(Color(0.8, 0.92, 1.0), 6.0), false, h)
	c._flick.append([arc, 3.0, 31.0, spark])
	batch.add(Vector3(1.2, 0.6, 0.6), Vector3(1.0, 0.3, -2.0), c.mat(Color(0.3, 0.3, 0.32), 0.6, 0.5))
	# The name over the door, a drum and a compressor outside.
	c.sign_on(h, "DUEL RUNNER GARAGE", Vector3((open_l + open_r) / 2.0, 4.12, zf + 0.12), Color(c.theme["accent2"]), 62, 0.0, false).pixel_size = 0.0085
	for k in 2:
		c.cyl(0.33, 0.33, 0.95, Vector3(-w / 2.0 - 0.6, 0.475, zf - 0.6 - k * 0.8), c.mat([Color(0.2, 0.36, 0.52), Color(0.72, 0.6, 0.2)][k], 0.7, 0.4), h, 12)
	c._dorm_solid(h, on, Vector3(0.8, 1.0, 1.7), Vector3(-w / 2.0 - 0.6, 0.5, zf - 1.0))
	batch.commit(h)
	c._flick.append([lamp, 2.6, 1.3, null])


## Homes made of shipping containers: two on the ground, one on top, a deck on the other roof
## with a tarp over it. Long axis along local X, the doors face +Z.
static func _sat_containers(c: ArenaDistrict, at: Vector3, yaw: float) -> void:
	var h := _holder(c, at, yaw)
	var batch := CityBuilder.BoxBatch.new()
	var cols := [Color(0.52, 0.2, 0.14), Color(0.16, 0.38, 0.4), Color(0.66, 0.52, 0.18)]
	var dark := c.mat(Color(0.1, 0.1, 0.11), 0.6, 0.4)
	var wood := c.surf("wood", Color(0.44, 0.32, 0.21))
	var warm := c.glow_mat(Color(1.0, 0.8, 0.5), 0.9)
	var boxes := [[Vector3(-3.1, 1.3, 0), 0], [Vector3(3.1, 1.3, 0), 1], [Vector3(-2.2, 3.92, -0.05), 2]]
	for b in boxes:
		var p: Vector3 = b[0]
		var body := c.mat(cols[b[1]], 0.75, 0.35)
		var rib := c.mat((cols[b[1]] as Color).darkened(0.18), 0.75, 0.35)
		batch.add(Vector3(6.06, 2.6, 2.44), p, body)
		batch.add(Vector3(6.1, 0.14, 2.48), p + Vector3(0, 1.26, 0), rib)
		batch.add(Vector3(6.1, 0.14, 2.48), p + Vector3(0, -1.26, 0), rib)
		var x := -2.85
		while x < 2.9:
			for sz: float in [-1.0, 1.0]:
				batch.add(Vector3(0.1, 2.3, 0.05), p + Vector3(x, 0, sz * 1.235), rib)
			x += 0.3
		# What makes it a home: a door cut in, a window with a light on, a number painted on.
		var dx := -1.6 if b[1] != 1 else 1.4
		batch.add(Vector3(0.95, 2.05, 0.08), p + Vector3(dx, -0.22, 1.26), c.mat(Color(0.2, 0.2, 0.22), 0.6, 0.4))
		batch.add(Vector3(0.06, 0.2, 0.06), p + Vector3(dx + 0.36, -0.2, 1.31), c.mat(Color(0.8, 0.8, 0.8), 0.3, 0.8))
		batch.add(Vector3(1.3, 0.9, 0.06), p + Vector3(dx + 2.0 if dx < 0.0 else dx - 2.0, 0.25, 1.26), warm)
		batch.add(Vector3(1.42, 0.07, 0.1), p + Vector3(dx + 2.0 if dx < 0.0 else dx - 2.0, -0.24, 1.28), dark)
		batch.add(Vector3(0.05, 0.9, 0.08), p + Vector3(dx + 2.0 if dx < 0.0 else dx - 2.0, 0.25, 1.28), dark)
		batch.add(Vector3(1.5, 0.05, 0.7), p + Vector3(dx, 0.98, 1.6), c.mat(Color(0.2, 0.34, 0.56) if b[1] == 0 else Color(0.74, 0.36, 0.14), 0.95), _rot(0.0, 0.25))
	c._dorm_solid(h, c.make_solid, Vector3(12.3, 5.2, 2.6), Vector3(0, 2.6, 0))
	c._dorm_solid(h, c.make_solid, Vector3(2.9, 2.6, 1.1), Vector3(7.5, 1.3, 0.4))
	# The deck on the second roof: planks, a rail, a tarp on poles, a chair and a pot plant.
	batch.add(Vector3(5.9, 0.08, 2.4), Vector3(3.1, 2.66, 0), wood)
	for rz: float in [-1.15, 1.15]:
		batch.add(Vector3(5.9, 0.06, 0.06), Vector3(3.1, 3.6, rz), dark)
		for k in 5:
			batch.add(Vector3(0.06, 0.95, 0.06), Vector3(0.3 + k * 1.4, 3.15, rz), dark)
	batch.add(Vector3(0.06, 0.06, 2.3), Vector3(6.0, 3.6, 0), dark)
	batch.add(Vector3(3.4, 0.04, 2.7), Vector3(4.2, 4.9, 0), c.mat(Color(0.2, 0.36, 0.6), 0.95), _rot(0.0, 0.0, 0.08))
	for px: float in [2.6, 5.8]:
		for pz: float in [-1.1, 1.1]:
			batch.add(Vector3(0.05, 2.2, 0.05), Vector3(px, 3.8, pz), wood)
	batch.add(Vector3(0.5, 0.06, 0.5), Vector3(4.6, 3.12, -0.3), c.mat(Color(0.7, 0.2, 0.16), 0.8))
	batch.add(Vector3(0.5, 0.5, 0.06), Vector3(4.6, 3.38, -0.55), c.mat(Color(0.7, 0.2, 0.16), 0.8))
	batch.add(Vector3(0.36, 0.34, 0.36), Vector3(1.0, 2.87, 0.7), c.mat(Color(0.6, 0.36, 0.24), 0.9))
	_ball(c, Vector3(1.0, 3.3, 0.7), 0.34, c.mat(Color(0.2, 0.42, 0.22), 0.95), h)
	# Steps up the end, a ladder to the top box, washing on a line, bulbs along the front.
	for k in 8:
		batch.add(Vector3(0.36, 0.06, 1.0), Vector3(6.35 + (7 - k) * 0.34, 0.3 + k * 0.32, 0.4), wood)
	batch.add(Vector3(2.9, 0.08, 0.08), Vector3(7.7, 1.5, 0.92), dark, _rot(0.0, 0.0, -0.76))
	for sx: float in [-0.25, 0.25]:
		batch.add(Vector3(0.05, 2.7, 0.05), Vector3(0.4 + sx, 3.95, 1.3), dark)
	for k in 7:
		batch.add(Vector3(0.5, 0.04, 0.04), Vector3(0.4, 2.8 + k * 0.36, 1.3), dark)
	var wash := [Color(0.92, 0.92, 0.9), Color(0.5, 0.66, 0.86), Color(0.9, 0.5, 0.46), Color(0.94, 0.84, 0.5), Color(0.6, 0.8, 0.6)]
	batch.add(Vector3(5.6, 0.015, 0.015), Vector3(-2.4, 5.5, 1.5), dark)
	for k in 6:
		batch.add(Vector3(0.5, 0.55 + (k % 3) * 0.14, 0.02), Vector3(-4.6 + k * 0.85, 5.2 - (k % 3) * 0.07, 1.5), c.mat(wash[k % wash.size()], 0.95))
	for ex: float in [-5.2, 0.4]:
		batch.add(Vector3(0.05, 0.5, 0.05), Vector3(ex, 5.35, 1.5), dark)
	for i in 12:
		batch.add(Vector3(0.09, 0.09, 0.09), Vector3(-5.6 + i * 1.02, 2.5 - 0.1 * sin(i * PI / 11.0 * 2.0), 1.75), c.glow_mat(Color(1.0, 0.78, 0.44), 2.4))
	batch.commit(h)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.78, 0.5)
	l.light_energy = 1.8
	l.omni_range = 8.0
	l.position = Vector3(0, 2.4, 2.6)
	h.add_child(l)
	c._lamp_lights.append(l)


## The highway that was never finished: it comes in over the north edge and stops in mid air,
## rebar hanging out of the broken end. The district's name hangs under it.
static func _sat_overpass(c: ArenaDistrict, rng: RandomNumberGenerator) -> void:
	var conc := c.surf("concrete", Color(0.47, 0.46, 0.44))
	var conc2 := c.surf("concrete", Color(0.38, 0.37, 0.36))
	var steel := c.mat(Color(0.3, 0.2, 0.15), 0.8, 0.5)
	var z := -37.0
	var top := 10.4
	for px: float in [-2.0, -24.0, -46.0, -68.0, -90.0]:
		c.box(Vector3(2.4, top - 1.6, 2.4), Vector3(px, (top - 1.6) / 2.0, z), conc, px > -30.0)
		c.box(Vector3(3.2, 1.2, 10.4), Vector3(px, top - 1.6, z), conc2, false)
		c.box(Vector3(3.0, 0.5, 3.0), Vector3(px, 0.25, z), conc2, false)
	# The deck in three strips so the break can be ragged.
	for k in 3:
		var end := [3.6, 1.2, 5.0][k] as float
		var zz := z - 3.4 + k * 3.4
		c.box(Vector3(end + 110.0, 1.0, 3.42), Vector3((end - 110.0) / 2.0, top - 0.5, zz), conc, false)
		for r in 5:
			var rod := c.cyl(0.03, 0.03, rng.randf_range(0.8, 2.2), Vector3(end + 0.5, top - 0.2 - r * 0.15, zz - 1.3 + r * 0.65), steel, null, 5)
			rod.rotation.z = PI / 2.0 + rng.randf_range(-0.9, 0.2)
	for s: float in [-1.0, 1.0]:
		c.box(Vector3(112.0, 0.9, 0.3), Vector3(-54.0, top + 0.45, z + s * 5.0), conc2, false)
	# A slab that broke off and hangs by its steel, and what already fell.
	var slab := c.box(Vector3(3.0, 0.6, 3.0), Vector3(5.6, top - 2.4, z + 0.4), conc, false)
	slab.rotation = Vector3(0.2, 0.3, -0.9)
	for r in 3:
		var hang := c.cyl(0.03, 0.03, 2.6, Vector3(4.4, top - 1.5, z - 0.6 + r * 1.0), steel, null, 5)
		hang.rotation.z = -0.8
	for k in 7:
		var p := Vector3(rng.randf_range(2.0, 9.0), 0, z + rng.randf_range(-4.0, 3.0))
		var sz := rng.randf_range(0.6, 1.8)
		var chunk := c.box(Vector3(sz, sz * 0.6, sz * 1.2), p + Vector3(0, sz * 0.25, 0), conc if k % 2 == 0 else conc2, false)
		chunk.rotation = Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * TAU, rng.randf_range(-0.4, 0.4))
		if p.length() < R:
			c.solid_cyl(sz * 0.6, 1.2, p + Vector3(0, 0.6, 0))
	# Paint on the nearest pillar and a road sign nobody took down.
	var paints := [Color("ff8a3a"), Color("2de2e6"), Color("f2f2f2"), Color("ffd23a"), Color("ff5a7a")]
	for k in 5:
		var st := c.box(Vector3(rng.randf_range(0.5, 1.6), rng.randf_range(0.25, 0.6), 0.02), Vector3(-2.0 + rng.randf_range(-0.5, 0.5), 1.0 + k * 0.5, z + 1.22), c.mat(paints[k], 0.9), false)
		st.rotation.z = rng.randf_range(-0.5, 0.5)
		st.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	c.box(Vector3(6.4, 2.0, 0.12), Vector3(-13.0, top - 2.3, z + 5.25), c.mat(Color(0.12, 0.3, 0.2), 0.8), false)
	c.box(Vector3(6.6, 0.1, 0.14), Vector3(-13.0, top - 1.28, z + 5.25), c.mat(Color(0.8, 0.8, 0.78), 0.7), false)
	c.box(Vector3(6.6, 0.1, 0.14), Vector3(-13.0, top - 3.32, z + 5.25), c.mat(Color(0.8, 0.8, 0.78), 0.7), false)
	var road := Label3D.new()
	road.text = "NEW DOMINO   12"
	road.font = load("res://assets/fonts/Rajdhani-SemiBold.ttf")
	road.font_size = 64
	road.pixel_size = 0.011
	road.modulate = Color(0.82, 0.84, 0.8)
	road.shaded = false
	road.outline_size = 0
	road.position = Vector3(-13.0, top - 2.1, z + 5.33)
	c.add_child(road)
	var bar := c.box(Vector3(6.9, 0.34, 0.03), Vector3(-13.0, top - 2.3, z + 5.36), c.mat(Color(0.7, 0.12, 0.1), 0.85), false)
	bar.rotation.z = 0.24
	var closed := Label3D.new()
	closed.text = "ROAD ENDS"
	closed.font = load("res://assets/fonts/Rajdhani-SemiBold.ttf")
	closed.font_size = 40
	closed.pixel_size = 0.011
	closed.modulate = Color(0.9, 0.86, 0.6)
	closed.shaded = false
	closed.outline_size = 0
	closed.position = Vector3(-13.0, top - 2.86, z + 5.34)
	c.add_child(closed)
	# The frame the district's name hangs on.
	c.box(Vector3(15.0, 2.5, 0.16), Vector3(0, 6.5, -30.25), c.mat(Color(0.07, 0.07, 0.08), 0.7, 0.3), false)
	for sx: float in [-1.0, 1.0]:
		c.box(Vector3(0.3, 7.9, 0.3), Vector3(sx * 6.9, 3.95, -30.4), steel, true)
		var brace := c.box(Vector3(0.14, 4.0, 0.14), Vector3(sx * 6.9, 2.0, -31.6), steel, false)
		brace.rotation.x = -0.6


## Power poles round the yard with their lines sagging between them, a bulb on most.
static func _sat_poles(c: ArenaDistrict) -> void:
	var batch := CityBuilder.BoxBatch.new()
	var wood := c.surf("wood", Color(0.3, 0.23, 0.17))
	var wire := c.mat(Color(0.05, 0.05, 0.055), 0.8)
	var bulb := c.glow_mat(Color(1.0, 0.8, 0.5), 3.0)
	var tops: Array = []
	for i in 8:
		var a := i * TAU / 8.0 + 0.39
		var p := Vector3(cos(a) * 36.5, 0, sin(a) * 36.5)
		var lean := c.cyl(0.11, 0.16, 8.2, p + Vector3(0, 4.1, 0), wood, null, 8)
		lean.rotation.z = sin(i * 2.3) * 0.04
		var tangent := _rot(-a + PI / 2.0)
		batch.add(Vector3(2.3, 0.12, 0.12), p + Vector3(0, 7.6, 0), wood, tangent)
		batch.add(Vector3(1.5, 0.1, 0.1), p + Vector3(0, 7.0, 0), wood, tangent)
		for sx: float in [-1.0, 0.0, 1.0]:
			batch.add(Vector3(0.08, 0.16, 0.08), p + tangent * Vector3(sx * 1.0, 0.14, 0) + Vector3(0, 7.6, 0), c.mat(Color(0.75, 0.78, 0.76), 0.3))
		batch.add(Vector3(0.36, 0.5, 0.3), p + tangent * Vector3(0, 0, 0.26) + Vector3(0, 6.2, 0), c.mat(Color(0.4, 0.42, 0.44), 0.6, 0.4), tangent)
		if c.make_solid:
			c.solid_cyl(0.2, 3.0, p + Vector3(0, 1.5, 0))
		tops.append([p + Vector3(0, 7.7, 0), tangent])
	for i in tops.size():
		var a0: Vector3 = tops[i][0]
		var b0: Vector3 = tops[(i + 1) % tops.size()][0]
		for lane: float in [-1.0, 0.0, 1.0]:
			var a1 := a0 + (tops[i][1] as Basis) * Vector3(lane, 0, 0)
			var b1 := b0 + (tops[(i + 1) % tops.size()][1] as Basis) * Vector3(lane, 0, 0)
			var prev := a1
			for sgi in range(1, 9):
				var t := sgi / 8.0
				var pt := a1.lerp(b1, t) - Vector3(0, 1.5 * 4.0 * t * (1.0 - t) * (1.0 + absf(lane) * 0.12), 0)
				var dirv := pt - prev
				var basis := Basis.looking_at(dirv.normalized(), Vector3.UP)
				batch.add(Vector3(0.025, 0.025, dirv.length() + 0.02), (prev + pt) / 2.0, wire, basis)
				prev = pt
		if i % 2 == 0:
			var mid := a0.lerp(b0, 0.5) - Vector3(0, 1.5, 0)
			batch.add(Vector3(0.02, 0.9, 0.02), mid - Vector3(0, 0.45, 0), wire)
			batch.add(Vector3(0.16, 0.2, 0.16), mid - Vector3(0, 1.0, 0), bulb)
	batch.commit(c)


## What stands about the yard: the fire in its barrel, the water tank, a painted wall, a car
## on blocks, and a fence patched from tin and wire round most of the edge.
static func _sat_yard(c: ArenaDistrict, rng: RandomNumberGenerator) -> void:
	var batch := CityBuilder.BoxBatch.new()
	var dark := c.mat(Color(0.1, 0.1, 0.11), 0.6, 0.4)
	var rust := c.mat(Color(0.46, 0.25, 0.15), 0.9, 0.2)
	var wood := c.surf("wood", Color(0.42, 0.31, 0.2))
	# The fire barrel: holes punched in the side glowing, flames, a light that never holds still.
	var fb := Vector3(11.0, 0, 23.2)
	c.cyl(0.36, 0.33, 0.95, fb + Vector3(0, 0.475, 0), c.mat(Color(0.2, 0.13, 0.1), 0.9, 0.4), null, 12)
	c.cyl(0.3, 0.3, 0.04, fb + Vector3(0, 0.93, 0), c.glow_mat(Color(1.0, 0.45, 0.12), 3.0), null, 12)
	for k in 7:
		var ha := k * TAU / 7.0
		var hole := c.box(Vector3(0.08, 0.1, 0.02), fb + Vector3(cos(ha) * 0.345, 0.3 + (k % 3) * 0.2, sin(ha) * 0.345), c.glow_mat(Color(1.0, 0.5, 0.15), 4.0), false)
		hole.rotation.y = -ha + PI / 2.0
	var flames: Array = []
	for k in 3:
		var fl := c.cyl(0.0, 0.16 - k * 0.03, 0.5 + k * 0.12, fb + Vector3((k - 1) * 0.1, 1.15 + k * 0.03, (k % 2) * 0.1 - 0.05), c.glow_mat([Color(1.0, 0.5, 0.1), Color(1.0, 0.72, 0.2), Color(1.0, 0.36, 0.08)][k], 3.2), null, 6)
		fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flames.append(fl)
	var fire := OmniLight3D.new()
	fire.light_color = Color(1.0, 0.55, 0.22)
	fire.light_energy = 3.4
	fire.omni_range = 9.0
	fire.position = fb + Vector3(0, 1.5, 0)
	c.add_child(fire)
	c._flick.append([fire, 3.4, 9.0, flames])
	if c.make_solid:
		c.solid_cyl(0.42, 1.2, fb + Vector3(0, 0.6, 0))
	_smoke(c, fb + Vector3(0, 1.7, 0), 0.5, 1.1, 5.0, Color(0.2, 0.19, 0.2), 10)
	for k in 3:
		var ca := 0.6 + k * 2.1
		var cp := fb + Vector3(cos(ca) * 1.5, 0.22, sin(ca) * 1.5)
		batch.add(Vector3(0.6, 0.44, 0.5), cp, wood, _rot(ca))
		if c.make_solid:
			c.solid_cyl(0.36, 0.5, cp)
	# The water tank on its legs, streaked with rust, a ladder up one side.
	var wt := Vector3(33.0, 0, 20.5)
	for lx: float in [-1.3, 1.3]:
		for lz: float in [-1.3, 1.3]:
			batch.add(Vector3(0.18, 6.0, 0.18), wt + Vector3(lx, 3.0, lz), rust)
		batch.add(Vector3(0.1, 0.1, 3.9), wt + Vector3(lx, 3.0, 0), rust, _rot(0.0, 0.85))
		batch.add(Vector3(3.9, 0.1, 0.1), wt + Vector3(0, 3.0, lx), rust, _rot(0.0, 0.0, 0.85))
	batch.add(Vector3(3.2, 0.2, 3.2), wt + Vector3(0, 6.1, 0), dark)
	c.cyl(1.7, 1.7, 3.0, wt + Vector3(0, 7.7, 0), c.mat(Color(0.4, 0.3, 0.24), 0.85, 0.4), null, 16)
	c.cyl(0.0, 1.8, 0.8, wt + Vector3(0, 9.6, 0), rust, null, 16)
	for band: float in [6.6, 7.7, 8.8]:
		c.cyl(1.74, 1.74, 0.1, wt + Vector3(0, band, 0), dark, null, 16)
	for k in 14:
		batch.add(Vector3(0.4, 0.04, 0.04), wt + Vector3(-1.3, 0.5 + k * 0.42, 1.42), dark)
	for sx: float in [-0.2, 0.2]:
		batch.add(Vector3(0.04, 6.2, 0.04), wt + Vector3(-1.3 + sx, 3.1, 1.42), dark)
	if c.make_solid:
		c._dorm_solid(c, true, Vector3(3.0, 6.0, 3.0), wt + Vector3(0, 3.0, 0))
	# A wall somebody keeps painting.
	var gw := _holder(c, Vector3(-34.5, 0, 5.5), PI / 2.0)
	c.box(Vector3(9.5, 3.3, 0.4), Vector3(0, 1.65, 0), c.surf("concrete", Color(0.5, 0.49, 0.47)), false, gw)
	c._dorm_solid(gw, c.make_solid, Vector3(9.5, 3.3, 0.5), Vector3(0, 1.65, 0))
	var sprays := [Color("ff8a3a"), Color("2de2e6"), Color("ff5a7a"), Color("ffd23a"), Color("9cf06a"), Color("b46be0"), Color("f2f2f2")]
	for k in 16:
		var sp := c.box(Vector3(rng.randf_range(0.5, 2.2), rng.randf_range(0.3, 1.0), 0.02), Vector3(rng.randf_range(-4.0, 4.0), rng.randf_range(0.5, 2.7), 0.212 + k * 0.001), c.mat(sprays[k % sprays.size()], 0.9), false, gw)
		sp.rotation.z = rng.randf_range(-0.6, 0.6)
		sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for k in 3:
		var arrow := c.cyl(0.0, 0.5, 0.02, Vector3(-2.6 + k * 2.6, 1.7, 0.235), c.mat(sprays[(k * 2 + 2) % sprays.size()], 0.9), gw, 3)
		arrow.rotation = Vector3(PI / 2.0, 0, 0.5 * k)
		arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tag := Label3D.new()
	tag.text = "RIDE FREE"
	tag.font = load("res://assets/fonts/Rajdhani-SemiBold.ttf")
	tag.font_size = 96
	tag.pixel_size = 0.012
	tag.modulate = Color(0.98, 0.98, 0.96)
	tag.outline_size = 14
	tag.outline_modulate = Color(0.06, 0.06, 0.08)
	tag.shaded = false
	tag.position = Vector3(0.4, 1.5, 0.25)
	tag.rotation.z = 0.08
	gw.add_child(tag)
	for k in 5:
		c.cyl(0.07, 0.07, 0.2, gw.transform * Vector3(-3.6 + k * 0.5, 0.1, 0.6 + (k % 2) * 0.2), c.mat(sprays[k], 0.5, 0.4), null, 8)
	# A car up on blocks with its wheels gone, tyres stacked beside it.
	var car := c.prop("sedan", Vector3(29.0, 0.32, -8.4), 2.1, 4.2)
	if car:
		car.rotation.z = 0.04
		c.collide(car, 0.85)
		for bx: float in [-1.0, 1.0]:
			for bz: float in [-1.0, 1.0]:
				batch.add(Vector3(0.4, 0.34, 0.5), Vector3(29.0, 0.17, -8.4) + _rot(2.1) * Vector3(bx * 0.7, 0, bz * 1.3), c.surf("concrete", Color(0.45, 0.44, 0.42)), _rot(2.1))
	for k in 4:
		c.cyl(0.38, 0.38, 0.22, Vector3(26.6, 0.11 + k * 0.22, -5.6), dark, null, 12).rotation.y = k * 0.5
	if c.make_solid:
		c.solid_cyl(0.42, 0.9, Vector3(26.6, 0.45, -5.6))
	# The fence: posts all the way round, between them tin sheet, planks, wire, or a gap.
	var net := StandardMaterial3D.new()
	net.albedo_color = Color(0.55, 0.57, 0.6, 0.32)
	net.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	net.cull_mode = BaseMaterial3D.CULL_DISABLED
	net.roughness = 0.6
	net.metallic = 0.5
	var sheets := [c.mat(Color(0.36, 0.37, 0.38), 0.6, 0.5), rust, c.mat(Color(0.2, 0.36, 0.38), 0.85, 0.3), c.mat(Color(0.2, 0.26, 0.38), 0.85, 0.3), c.mat(Color(0.56, 0.48, 0.2), 0.85, 0.3)]
	var seg := 48
	for i in seg:
		var a := i * TAU / seg
		var a2 := (i + 1) * TAU / seg
		var p := Vector3(cos(a) * (R - 0.5), 0, sin(a) * (R - 0.5))
		var q := Vector3(cos(a2) * (R - 0.5), 0, sin(a2) * (R - 0.5))
		var mid := (p + q) / 2.0
		# Open under the overpass, where the name board stands, and here and there.
		if mid.z < -36.0 and absf(mid.x) < 11.0:
			continue
		var along := _rot(-(a + a2) / 2.0 + PI / 2.0)
		var span := p.distance_to(q)
		batch.add(Vector3(0.1, 2.5, 0.1), p + Vector3(0, 1.25, 0), dark)
		var kind := rng.randi() % 10
		if kind < 2:
			continue
		batch.add(Vector3(span, 0.05, 0.05), mid + Vector3(0, 2.3, 0), dark, along)
		batch.add(Vector3(span, 0.05, 0.05), mid + Vector3(0, 0.3, 0), dark, along)
		if kind < 5:
			var pane := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(span, 2.0)
			pane.mesh = qm
			pane.material_override = net
			pane.position = mid + Vector3(0, 1.3, 0)
			pane.basis = along
			pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			c.add_child(pane)
			for wv in 3:
				batch.add(Vector3(span, 0.02, 0.02), mid + Vector3(0, 2.42 + wv * 0.07, 0), dark, along * Basis(Vector3.BACK, 0.02 * (wv - 1)))
		elif kind < 8:
			var x := -span / 2.0
			while x < span / 2.0 - 0.1:
				var sw := minf(rng.randf_range(0.8, 1.5), span / 2.0 - x)
				var top := rng.randf_range(2.0, 2.9)
				batch.add(Vector3(sw - 0.03, top, 0.05), mid + along * Vector3(x + sw / 2.0, 0, 0) + Vector3(0, top / 2.0, 0), sheets[rng.randi() % sheets.size()], along * Basis(Vector3.BACK, rng.randf_range(-0.04, 0.04)))
				x += sw
		else:
			var x2 := -span / 2.0 + 0.1
			while x2 < span / 2.0:
				var top2 := rng.randf_range(1.7, 2.5)
				batch.add(Vector3(0.22, top2, 0.04), mid + along * Vector3(x2, 0, 0) + Vector3(0, top2 / 2.0, 0), wood, along * Basis(Vector3.BACK, rng.randf_range(-0.06, 0.06)))
				x2 += 0.27
	batch.commit(c)


## Far off: the crane working over the heaps, smokestacks with their warning lights.
static func _sat_far(c: ArenaDistrict) -> void:
	var steel := c.mat(Color(0.8, 0.55, 0.15), 0.6, 0.5)
	var dark := c.mat(Color(0.12, 0.12, 0.13), 0.6, 0.4)
	var base := Vector3(-34.0, 0, -52.0)
	# A lattice tower: four legs and cross braces.
	for lx: float in [-0.8, 0.8]:
		for lz: float in [-0.8, 0.8]:
			c.box(Vector3(0.22, 30.0, 0.22), base + Vector3(lx, 15.0, lz), steel, false)
	for k in 10:
		for side in 4:
			var br := c.box(Vector3(2.3, 0.12, 0.12), base + Vector3(0, 1.5 + k * 3.0, 0) + [Vector3(0, 0, 0.8), Vector3(0, 0, -0.8), Vector3(0.8, 0, 0), Vector3(-0.8, 0, 0)][side], steel, false)
			br.rotation = Vector3(0, 0.0 if side < 2 else PI / 2.0, 0.75 if k % 2 == 0 else -0.75)
	var pivot := Node3D.new()
	pivot.position = base + Vector3(0, 30.5, 0)
	pivot.set_meta("spin", 0.05)
	c.add_child(pivot)
	c._spin.append(pivot)
	c.box(Vector3(2.4, 2.0, 2.4), Vector3(0, 0.6, 0), steel, false, pivot)
	c.box(Vector3(1.0, 1.1, 0.06), Vector3(0.6, 0.7, 1.22), c.glow_mat(Color(1.0, 0.9, 0.7), 0.8), false, pivot)
	c.box(Vector3(34.0, 1.0, 1.0), Vector3(15.0, 2.2, 0), steel, false, pivot)
	c.box(Vector3(10.0, 1.2, 1.2), Vector3(-7.0, 2.0, 0), steel, false, pivot)
	c.box(Vector3(3.0, 2.4, 2.0), Vector3(-10.5, 1.0, 0), dark, false, pivot)
	c.box(Vector3(0.14, 5.0, 0.14), Vector3(0, 4.6, 0), steel, false, pivot)
	for tie in [[Vector3(8.0, 4.6, 0), 16.4, -0.3], [Vector3(-5.0, 4.6, 0), 10.6, 0.5]]:
		var cable := c.box(Vector3(tie[1], 0.06, 0.06), tie[0], dark, false, pivot)
		cable.rotation.z = tie[2]
	c.box(Vector3(0.07, 16.0, 0.07), Vector3(26.0, -6.2, 0), dark, false, pivot)
	c.box(Vector3(0.9, 0.9, 0.5), Vector3(26.0, -14.6, 0), steel, false, pivot)
	c.box(Vector3(2.6, 0.3, 2.0), Vector3(26.0, -15.6, 0), c.mat(Color(0.4, 0.2, 0.14), 0.9, 0.3), false, pivot)
	c.box(Vector3(0.4, 0.4, 0.4), Vector3(32.0, 3.0, 0), c.glow_mat(Color(1.0, 0.2, 0.15), 5.0), false, pivot)
	# Stacks on the far side with their smoke leaning in the wind.
	for st in [[Vector3(74.0, 0, -66.0), 44.0], [Vector3(88.0, 0, -58.0), 36.0], [Vector3(-80.0, 0, 62.0), 40.0]]:
		var sp: Vector3 = st[0]
		var sh: float = st[1]
		c.cyl(1.7, 2.6, sh, sp + Vector3(0, sh / 2.0, 0), c.surf("concrete", Color(0.5, 0.46, 0.44)), null, 14)
		for band in 3:
			c.cyl(1.82 + band * 0.02, 1.9 + band * 0.02, 1.6, sp + Vector3(0, sh - 2.0 - band * 5.0, 0), c.mat(Color(0.75, 0.2, 0.15) if band % 2 == 0 else Color(0.9, 0.9, 0.88), 0.8), null, 14)
		c.box(Vector3(0.5, 0.5, 0.5), sp + Vector3(0, sh + 0.4, 1.9), c.glow_mat(Color(1.0, 0.15, 0.12), 5.0), false)
		_smoke(c, sp + Vector3(0, sh + 3.0, 0), 4.0, 2.6, 12.0, Color(0.34, 0.31, 0.3), 16)


# ====================================================================== Heartland

static var _glass_sh: Shader
static var _holo_sh: Shader


## A glass tower wall: panes with pale mullions, some rooms lit, the color of the sky in it.
static func _glass(c: ArenaDistrict, tint: Color, seed: float) -> ShaderMaterial:
	if _glass_sh == null:
		_glass_sh = Shader.new()
		_glass_sh.code = """
shader_type spatial;
uniform vec3 tint : source_color = vec3(0.7, 0.8, 0.9);
uniform vec3 lit : source_color = vec3(1.0, 0.92, 0.75);
uniform float glow_strength = 0.3;
uniform float day = 0.0;
uniform float seed = 0.0;
varying vec3 wp;
varying vec3 wn;
float h(vec2 p) { return fract(sin(dot(p, vec2(41.3, 289.1)) + seed) * 43758.5453); }
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	float side = step(abs(wn.y), 0.5);
	float u = abs(wn.x) > 0.5 ? wp.z : wp.x;
	vec2 g = vec2(u / 2.2, wp.y / 3.4);
	vec2 f = fract(g);
	vec2 cell = floor(g);
	float px = max(fwidth(g.x), fwidth(g.y));
	float fine = 1.0 - smoothstep(0.12, 0.45, px);
	float mull = 1.0 - smoothstep(0.03, 0.03 + px, min(f.x, 1.0 - f.x));
	float slab = 1.0 - smoothstep(0.06, 0.06 + px, min(f.y, 1.0 - f.y));
	float frame = max(mull, slab) * fine * side;
	vec3 col = mix(tint * (0.7 + 0.3 * h(cell)), vec3(0.86, 0.89, 0.95), frame);
	// Sky in the glass: paler toward the top of the tower.
	col = mix(col, vec3(0.75, 0.88, 1.0), side * (1.0 - frame) * clamp(wp.y / 90.0, 0.0, 0.22));
	float on = step(0.6, h(cell + 3.0)) * (1.0 - frame) * side * mix(0.4, 1.0, fine);
	ALBEDO = col + day * 0.0;
	ROUGHNESS = mix(0.1, 0.5, frame);
	METALLIC = mix(0.5, 0.1, frame) * side;
	EMISSION = lit * on * glow_strength * 1.5 + tint * 0.05;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _glass_sh
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("seed", seed)
	c._window_mats.append(m)
	return m


## A screen that hangs in the air and never shows the same thing twice running.
static func _holo(color: Color, seed: float) -> ShaderMaterial:
	if _holo_sh == null:
		_holo_sh = Shader.new()
		_holo_sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled;
uniform vec3 tint : source_color = vec3(1.0, 0.5, 0.8);
uniform float seed = 0.0;
float hash(float p) { return fract(sin(p * 91.7 + seed) * 43758.5453); }
void fragment() {
	vec2 uv = UV;
	float t = TIME * 0.5 + seed;
	float kind = hash(1.0);
	float v = 0.0;
	if (kind < 0.34) {
		float bars = floor(uv.x * 9.0);
		v = step(1.0 - uv.y, 0.25 + 0.6 * abs(sin(t * 1.7 + bars * 1.3))) * step(0.15, fract(uv.x * 9.0));
	} else if (kind < 0.67) {
		vec2 c = uv - 0.5;
		float r = length(c * vec2(1.0, 0.6));
		v = smoothstep(0.03, 0.0, abs(fract(r * 5.0 - t) - 0.5) - 0.14) * smoothstep(0.5, 0.15, r);
	} else {
		// A star turning over a field of drifting dots.
		vec2 c = (uv - 0.5) * vec2(1.7, 1.0);
		float a = atan(c.y, c.x) + t;
		float r = length(c);
		v = smoothstep(0.02, 0.0, r - 0.22 - 0.09 * cos(a * 5.0));
		vec2 d = fract(uv * vec2(9.0, 5.0) + vec2(t * 0.2, 0.0)) - 0.5;
		v += smoothstep(0.12, 0.05, length(d)) * 0.35;
	}
	float frame = max(step(uv.x, 0.02), max(step(0.98, uv.x), max(step(uv.y, 0.035), step(0.965, uv.y))));
	float scan = 0.85 + 0.15 * sin(uv.y * 160.0 + TIME * 3.0);
	ALBEDO = tint * (0.1 + v * 1.2 * scan + frame);
	ALPHA = clamp(0.2 + v * 0.7 + frame * 0.8, 0.0, 1.0);
}
"""
	var m := ShaderMaterial.new()
	m.shader = _holo_sh
	m.set_shader_parameter("tint", color)
	m.set_shader_parameter("seed", seed)
	return m


static func heartland(c: ArenaDistrict) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	_hl_ground(c, rng)
	_hl_monorail(c)
	_hl_wheel(c, Vector3(-52.0, 0, -45.0))
	_hl_sky(c)
	_hl_plaza(c, rng)


## Towers of glass round the plaza, in the pale colors of the place, each with a line of light
## at its crown. Kept back far enough for the monorail to pass in front of them.
static func towers(c: ArenaDistrict) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var tints := [Color(0.34, 0.54, 0.86), Color(0.6, 0.44, 0.84), Color(0.28, 0.7, 0.74), Color(0.78, 0.8, 0.92), Color(0.86, 0.48, 0.66), Color(0.42, 0.6, 0.9)]
	var crowns := [Color("ff7ac8"), Color("5ae0ff"), Color("ffd84a"), Color("ffffff")]
	var shell := c.mat(Color(0.95, 0.96, 0.98), 0.25, 0.1)
	for i in 44:
		var a := i * TAU / 44.0 + rng.randf_range(-0.04, 0.04)
		var d := rng.randf_range(R + 18.0, R + 52.0)
		var p := Vector3(sin(a) * d, 0, cos(a) * d)
		if absf(p.x) < 13.0 and p.z < 0.0:
			continue          # the spire stands here
		if p.distance_to(Vector3(-52.0, 0, -45.0)) < 24.0:
			continue          # and the big wheel here
		var w := rng.randf_range(8.0, 13.0)
		var dd := rng.randf_range(8.0, 13.0)
		var hgt := rng.randf_range(22.0, 62.0) * (0.8 + 0.4 * (d - R) / 52.0)
		var m := _glass(c, tints[rng.randi() % tints.size()], rng.randf() * 60.0)
		c.box(Vector3(w, hgt, dd), p + Vector3(0, hgt / 2.0, 0), m, false)
		c.box(Vector3(w + 0.6, 4.0, dd + 0.6), p + Vector3(0, 2.0, 0), shell, false)
		var crown: Color = crowns[rng.randi() % crowns.size()]
		c.box(Vector3(w + 0.3, 0.4, dd + 0.3), p + Vector3(0, hgt + 0.2, 0), c.glow_mat(crown, 1.8), false)
		match rng.randi() % 4:
			0:
				# A stepped top with a second line of light.
				c.box(Vector3(w * 0.62, 6.0, dd * 0.62), p + Vector3(0, hgt + 3.0, 0), m, false)
				c.box(Vector3(w * 0.62 + 0.3, 0.3, dd * 0.62 + 0.3), p + Vector3(0, hgt + 6.1, 0), c.glow_mat(crown, 1.8), false)
			1:
				# A dome.
				_ball(c, p + Vector3(0, hgt, 0), minf(w, dd) * 0.46, shell, null, Vector3(1.0, 0.7, 1.0))
			2:
				# A ring floating over the roof, turning.
				var ring := _torus(c, p + Vector3(0, hgt + 3.5, 0), minf(w, dd) * 0.5, 0.18, c.glow_mat(crown, 2.0))
				ring.rotation.x = 0.3
				ring.set_meta("spin", rng.randf_range(0.2, 0.5))
				c._spin.append(ring)
			_:
				c.cyl(0.08, 0.14, 9.0, p + Vector3(0, hgt + 4.5, 0), shell, null, 6)
				c.box(Vector3(0.4, 0.4, 0.4), p + Vector3(0, hgt + 9.2, 0), c.glow_mat(Color("ff7ac8"), 4.0), false)


## Pale paving with rings of color set into it, a bed of flowers under every tree.
static func _hl_ground(c: ArenaDistrict, rng: RandomNumberGenerator) -> void:
	var inlays := [[13.0, Color("ff7ac8")], [25.5, Color("5ae0ff")], [38.0, Color("ffd84a")]]
	for ring in inlays:
		var t := _torus(c, Vector3(0, 0.02, 0), ring[0], 0.16, c.glow_mat(ring[1], 1.2))
		t.scale = Vector3(1.0, 0.08, 1.0)
		t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# A wide band of warmer stone between the two outer rings, cut by the radial lines of light.
	var band := c.surf("paving", Color(0.93, 0.87, 0.9), 1.4)
	for k in 12:
		var a := (k + 0.5) * TAU / 12.0
		var slab := c.box(Vector3(11.2, 0.03, 11.0), Vector3(sin(a) * 31.8, 0.012, cos(a) * 31.8), band, false)
		slab.rotation.y = a
		slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Flower beds: a white kerb, dark earth, blooms in the colors of the rings.
	var kerb := c.mat(Color(0.95, 0.95, 0.97), 0.4)
	var soil := c.mat(Color(0.26, 0.19, 0.14), 0.95)
	var grass := c.mat(Color(0.36, 0.66, 0.36), 0.95)
	var blooms := [c.mat(Color("ff7ac8"), 0.8), c.mat(Color("ffd84a"), 0.8), c.mat(Color("ffffff"), 0.8), c.mat(Color("5ae0ff"), 0.8), c.mat(Color("ff9a5a"), 0.8)]
	var flowers := Blooms.new()
	for i in 10:
		var a2 := i * TAU / 10.0 + 0.3
		var p := Vector3(cos(a2) * 33.0, 0, sin(a2) * 33.0)
		if absf(p.x) < 7.0:
			continue
		c.cyl(2.5, 2.6, 0.3, p + Vector3(0, 0.15, 0), kerb, null, 20)
		c.cyl(2.3, 2.3, 0.06, p + Vector3(0, 0.31, 0), grass if i % 2 == 0 else soil, null, 20)
		if c.make_solid:
			c.solid_cyl(2.5, 0.7, p + Vector3(0, 0.35, 0))
		for k in 46:
			var fa := rng.randf() * TAU
			var fr := rng.randf_range(0.7, 2.15)
			flowers.add(blooms[(k + i) % blooms.size()], p + Vector3(cos(fa) * fr, 0.42, sin(fa) * fr), rng.randf_range(0.08, 0.14))
	# Round tubs of flowers by the fountain.
	for k in 6:
		var ta := k * TAU / 6.0 + 0.52
		var tp := Vector3(cos(ta) * 4.6, 0, 17.0 + sin(ta) * 4.6)
		c.cyl(0.5, 0.4, 0.5, tp + Vector3(0, 0.25, 0), kerb, null, 14)
		c.cyl(0.52, 0.52, 0.04, tp + Vector3(0, 0.5, 0), c.glow_mat([Color("ff7ac8"), Color("5ae0ff")][k % 2], 1.0), null, 14)
		c.cyl(0.46, 0.46, 0.05, tp + Vector3(0, 0.53, 0), grass, null, 14)
		for j in 13:
			var jr := 0.12 + (j % 3) * 0.13
			flowers.add(blooms[(j + k) % blooms.size()], tp + Vector3(cos(j * 2.4) * jr, 0.6, sin(j * 2.4) * jr), 0.075)
		if c.make_solid:
			c.solid_cyl(0.5, 0.9, tp + Vector3(0, 0.45, 0))
	flowers.commit(c)


## The monorail: a white beam on Y-shaped pylons right round the plaza, and a train that never
## stops doing laps of it.
static func _hl_monorail(c: ArenaDistrict) -> void:
	var rad := 46.0
	var hgt := 9.6
	var shell := c.mat(Color(0.95, 0.96, 0.98), 0.25, 0.1)
	var rim := c.mat(Color(0.8, 0.84, 0.9), 0.3, 0.5)
	var beam := _torus(c, Vector3(0, hgt, 0), rad, 0.42, shell)
	beam.scale = Vector3(1.0, 1.3, 1.0)
	var under := _torus(c, Vector3(0, hgt - 0.5, 0), rad, 0.1, c.glow_mat(Color("5ae0ff"), 1.8))
	under.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 14:
		var a := i * TAU / 14.0 + 0.11
		var p := Vector3(cos(a) * rad, 0, sin(a) * rad)
		c.cyl(0.36, 0.55, hgt - 1.8, p + Vector3(0, (hgt - 1.8) / 2.0, 0), shell, null, 12)
		c.cyl(0.9, 0.36, 1.4, p + Vector3(0, hgt - 1.1, 0), shell, null, 12)
		c.cyl(0.6, 0.6, 0.08, p + Vector3(0, 0.3, 0), c.glow_mat(Color("ff7ac8") if i % 2 == 0 else Color("5ae0ff"), 1.6), null, 12)
		c.cyl(0.8, 0.9, 0.3, p + Vector3(0, 0.15, 0), rim, null, 12)
	# The train rides a pivot at the middle of the ring.
	var pivot := Node3D.new()
	pivot.set_meta("spin", -0.2)
	c.add_child(pivot)
	c._spin.append(pivot)
	var glass := c.glow_mat(Color(0.5, 0.9, 1.0), 0.9)
	var stripe := c.glow_mat(Color("ff7ac8"), 1.4)
	var cars := 4
	for k in cars:
		var a2 := -k * 0.185
		var car := Node3D.new()
		car.position = Vector3(cos(a2) * rad, hgt + 1.75, sin(a2) * rad)
		car.rotation.y = -a2
		pivot.add_child(car)
		# Long axis along local Z (the way it travels).
		c.box(Vector3(2.5, 2.3, 7.4), Vector3.ZERO, shell, false, car)
		c.box(Vector3(2.54, 0.8, 6.6), Vector3(0, 0.35, 0), glass, false, car)
		c.box(Vector3(2.56, 0.16, 7.42), Vector3(0, -0.5, 0), stripe, false, car)
		c.box(Vector3(2.2, 0.3, 7.0), Vector3(0, 1.2, 0), rim, false, car)
		c.box(Vector3(1.4, 0.9, 7.0), Vector3(0, -1.5, 0), rim, false, car)
		for kz in 4:
			c.box(Vector3(2.58, 0.84, 0.14), Vector3(0, 0.35, -2.5 + kz * 1.66), shell, false, car)
		if k == 0 or k == cars - 1:
			# A rounded nose at each end of the train.
			var nose := _ball(c, Vector3(0, -0.1, 3.7 if k == 0 else -3.7), 1.2, shell, car, Vector3(1.04, 0.96, 1.5))
			nose.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			c.box(Vector3(1.6, 0.5, 0.2), Vector3(0, 0.25, 5.1 if k == 0 else -5.1), glass, false, car)
			c.box(Vector3(0.9, 0.14, 0.1), Vector3(0, -0.5, 5.42 if k == 0 else -5.42), c.glow_mat(Color(1.0, 1.0, 0.9) if k == 0 else Color(1.0, 0.2, 0.2), 4.0), false, car)


## The big wheel beyond the roofs: a rim of lights, spokes, a gondola at the end of each.
static func _hl_wheel(c: ArenaDistrict, at: Vector3) -> void:
	var shell := c.mat(Color(0.95, 0.96, 0.98), 0.25, 0.1)
	var h := _holder(c, at, atan2(-at.x, -at.z))
	var rad := 17.0
	var hub_y := 21.0
	# Two A-frames holding the axle.
	for sz: float in [-1.6, 1.6]:
		for sx: float in [-1.0, 1.0]:
			var leg := c.box(Vector3(0.7, hub_y + 1.0, 0.7), Vector3(sx * 4.6, hub_y / 2.0, sz), shell, false, h)
			leg.rotation.z = sx * 0.42
	c.cyl(0.8, 0.8, 4.4, Vector3(0, hub_y, 0), shell, h, 14).rotation.x = PI / 2.0
	c.box(Vector3(14.0, 1.2, 5.0), Vector3(0, 0.6, 0), shell, false, h)
	c.box(Vector3(14.2, 0.2, 5.2), Vector3(0, 1.25, 0), c.glow_mat(Color("5ae0ff"), 1.4), false, h)
	var hub := Node3D.new()
	hub.position = Vector3(0, hub_y, 0)
	hub.set_meta("spin_z", 0.11)
	h.add_child(hub)
	c._spin_z.append(hub)
	for sz: float in [-0.9, 0.9]:
		var rim := _torus(c, Vector3(0, 0, sz), rad, 0.16, shell, hub)
		rim.rotation.x = PI / 2.0
	var glow_rim := _torus(c, Vector3.ZERO, rad - 0.7, 0.1, c.glow_mat(Color("ff7ac8"), 2.2), hub)
	glow_rim.rotation.x = PI / 2.0
	var gcols := [Color("ff7ac8"), Color("5ae0ff"), Color("ffd84a"), Color("9cf06a"), Color("ffffff"), Color("ff9a5a")]
	var n := 16
	for i in n:
		var a := i * TAU / n
		var dirv := Vector3(cos(a), sin(a), 0)
		var spoke := c.box(Vector3(rad, 0.12, 0.12), dirv * rad / 2.0, shell, false, hub)
		spoke.rotation.z = a
		if i % 2 == 0:
			var lit := c.box(Vector3(rad * 0.7, 0.07, 0.07), dirv * rad * 0.55 + Vector3(0, 0, 0.12), c.glow_mat(gcols[(i / 2) % gcols.size()], 2.0), false, hub)
			lit.rotation.z = a
		# Gondolas are round, so it does not matter that they turn with the wheel.
		_ball(c, dirv * (rad + 0.2), 1.25, c.mat(gcols[i % gcols.size()], 0.4, 0.1), hub)
		_ball(c, dirv * (rad + 0.2) + Vector3(0, 0, 0.5), 0.95, c.glow_mat(Color(1.0, 0.95, 0.8), 0.7), hub, Vector3(1.0, 0.6, 1.0))
	_ball(c, Vector3(0, 0, 1.2), 1.6, c.glow_mat(Color("ffd84a"), 1.6), hub, Vector3(1.0, 1.0, 0.4))


## Balloons riding high over the city and screens that float over the edge of the plaza.
static func _hl_sky(c: ArenaDistrict) -> void:
	var shell := c.mat(Color(0.95, 0.96, 0.98), 0.25, 0.1)
	var two := [[Color("ff7ac8"), Color("ffffff")], [Color("5ae0ff"), Color("ffd84a")], [Color("ffd84a"), Color("ff9a5a")], [Color("9cf06a"), Color("ffffff")]]
	var spots := [Vector3(60.0, 46.0, 30.0), Vector3(-40.0, 58.0, 62.0), Vector3(78.0, 64.0, -50.0), Vector3(-90.0, 50.0, -10.0)]
	for i in spots.size():
		var b := Node3D.new()
		b.position = spots[i]
		c.add_child(b)
		_ball(c, Vector3(0, 3.0, 0), 5.0, c.mat(two[i][0], 0.6), b, Vector3(1.0, 1.15, 1.0))
		for k in 6:
			var gore := _ball(c, Vector3(0, 3.0, 0), 5.03, c.mat(two[i][1], 0.6), b, Vector3(0.16, 1.15, 1.0))
			gore.rotation.y = k * PI / 6.0
		c.cyl(1.3, 2.4, 2.4, Vector3(0, -3.0, 0), c.mat(two[i][0], 0.6), b, 12)
		c.box(Vector3(1.5, 1.2, 1.5), Vector3(0, -6.4, 0), c.surf("wood", Color(0.5, 0.36, 0.22)), false, b)
		for sx: float in [-0.7, 0.7]:
			for sz: float in [-0.7, 0.7]:
				c.box(Vector3(0.04, 2.4, 0.04), Vector3(sx, -4.8, sz), shell, false, b)
		c._bob.append([b, b.position.y, 0.25 + i * 0.07])
	# Screens: one over each of the four ways in, tilted down to face the plaza.
	var names := ["DUEL CARNIVAL", "HEARTLAND", "TODAY: OPEN DUELS", "WELCOME"]
	var cols := [Color("ff7ac8"), Color("5ae0ff"), Color("ffd84a"), Color("9cf06a")]
	for i in 4:
		var a := i * TAU / 4.0 + PI / 4.0
		var p := Vector3(cos(a) * 36.0, 7.2, sin(a) * 36.0)
		var s := Node3D.new()
		s.position = p
		s.rotation.y = atan2(-p.x, -p.z)
		c.add_child(s)
		var panel := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(7.5, 3.4)
		panel.mesh = qm
		panel.material_override = _holo(cols[i], 3.0 + i * 2.7)
		panel.rotation.x = -0.14
		s.add_child(panel)
		var lab := Label3D.new()
		lab.text = names[i]
		lab.font = load("res://assets/fonts/Rajdhani-SemiBold.ttf")
		lab.font_size = 96
		lab.pixel_size = 0.011
		lab.modulate = Color(1, 1, 1)
		lab.outline_size = 10
		lab.outline_modulate = Color((cols[i] as Color).darkened(0.5), 0.8)
		lab.shaded = false
		lab.position = Vector3(0, -2.3, 0.05)
		s.add_child(lab)
		for sx: float in [-1.0, 1.0]:
			var orb := _ball(c, Vector3(sx * 4.2, 0, 0), 0.3, c.glow_mat(cols[i], 2.4), s)
			orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		c._bob.append([s, 7.2, 0.5 + i * 0.13])


## On the plaza itself: arches of light at the four ways in, strings of colored lamps between
## the lamp posts, an ice cream cart, a balloon seller's stand, a little stage of screens.
static func _hl_plaza(c: ArenaDistrict, rng: RandomNumberGenerator) -> void:
	var batch := CityBuilder.BoxBatch.new()
	var shell := c.mat(Color(0.95, 0.96, 0.98), 0.25, 0.1)
	var rim := c.mat(Color(0.8, 0.84, 0.9), 0.3, 0.5)
	var cols := [Color("ff7ac8"), Color("5ae0ff"), Color("ffd84a"), Color("9cf06a"), Color("ffffff"), Color("ff9a5a")]
	var glows: Array = []
	for col in cols:
		glows.append(c.glow_mat(col, 2.4))
	# Arches: a half ring of light on two white feet.
	for i in 4:
		var a := i * TAU / 4.0
		var p := Vector3(cos(a) * 37.2, 0, sin(a) * 37.2)
		if i == 3:
			continue          # the name of the city stands at the north side already
		var arch := _holder(c, p, -a + PI / 2.0)
		var ring := _torus(c, Vector3(0, 0.4, 0), 4.6, 0.2, glows[i % 2], arch)
		ring.rotation.x = PI / 2.0
		var inner := _torus(c, Vector3(0, 0.4, 0), 4.15, 0.07, glows[4], arch)
		inner.rotation.x = PI / 2.0
		for sx: float in [-1.0, 1.0]:
			c.cyl(0.5, 0.7, 1.3, Vector3(sx * 4.6, 0.65, 0), shell, arch, 12)
			if c.make_solid:
				c.solid_cyl(0.7, 2.0, arch.transform * Vector3(sx * 4.6, 1.0, 0))
	# Strings of lamps from post to post.
	var posts := [Vector3(-9, 0, 9), Vector3(9, 0, 9), Vector3(9, 0, -9), Vector3(-9, 0, -9)]
	var outer := [Vector3(0, 0, 22), Vector3(20, 0, 0), Vector3(0, 0, -22), Vector3(-20, 0, 0)]
	var wire := c.mat(Color(0.2, 0.2, 0.24), 0.6)
	var runs: Array = []
	for i in 4:
		runs.append([posts[i], outer[i]])
		runs.append([posts[i], outer[(i + 3) % 4]])
	for run in runs:
		var a0: Vector3 = (run[0] as Vector3) + Vector3(0, 4.9, 0)
		var b0: Vector3 = (run[1] as Vector3) + Vector3(0, 4.9, 0)
		var prev := a0
		for k in range(1, 13):
			var t := k / 12.0
			var pt := a0.lerp(b0, t) - Vector3(0, 1.1 * 4.0 * t * (1.0 - t), 0)
			var dv := pt - prev
			batch.add(Vector3(0.02, 0.02, dv.length() + 0.02), (prev + pt) / 2.0, wire, Basis.looking_at(dv.normalized(), Vector3.UP))
			if k < 12:
				batch.add(Vector3(0.13, 0.16, 0.13), pt - Vector3(0, 0.12, 0), glows[k % glows.size()])
			prev = pt
	# The ice cream cart: a striped umbrella, a freezer on wheels, a cone on a pole.
	var cart := _holder(c, Vector3(11.5, 0, 25.5), -0.4)
	c.box(Vector3(1.9, 0.9, 1.0), Vector3(0, 0.75, 0), shell, false, cart)
	c.box(Vector3(1.94, 0.12, 1.04), Vector3(0, 0.62, 0), c.mat(Color("ff7ac8"), 0.5), false, cart)
	c.box(Vector3(1.94, 0.06, 1.04), Vector3(0, 1.22, 0), c.mat(Color("5ae0ff"), 0.4, 0.2), false, cart)
	for wx: float in [-0.7, 0.7]:
		c.cyl(0.3, 0.3, 0.1, Vector3(wx, 0.3, 0.52), rim, cart, 14).rotation.x = PI / 2.0
	c.cyl(0.03, 0.03, 2.6, Vector3(0, 1.9, 0), rim, cart, 6)
	c.cyl(0.0, 1.5, 0.5, Vector3(0, 3.2, 0), c.mat(cols[0], 0.8), cart, 8)
	for k in 4:
		# Every other panel of the umbrella is white: a thin wedge laid just over the pink.
		var wedge := c.box(Vector3(0.62, 0.02, 1.45), Vector3.ZERO, c.mat(cols[4], 0.8), false, cart)
		wedge.transform = Transform3D(_rot(k * TAU / 4.0 + TAU / 16.0) * Basis(Vector3.RIGHT, 0.32), Vector3(0, 3.21, 0) + _rot(k * TAU / 4.0 + TAU / 16.0) * Vector3(0, 0, 0.72))
	c.cyl(0.0, 0.16, 0.5, Vector3(-1.2, 1.55, 0), c.mat(Color(0.86, 0.66, 0.36), 0.8), cart, 10).rotation.x = PI
	_ball(c, Vector3(-1.2, 1.9, 0), 0.2, c.mat(Color("ff7ac8"), 0.6), cart)
	_ball(c, Vector3(-1.2, 2.12, 0), 0.16, c.mat(Color(0.98, 0.96, 0.9), 0.6), cart)
	c.cyl(0.02, 0.02, 1.3, Vector3(-1.2, 0.65, 0), rim, cart, 6)
	for k in 3:
		c.box(Vector3(0.3, 0.24, 0.02), Vector3(-0.5 + k * 0.5, 0.86, 0.515), c.mat(cols[k], 0.6), false, cart)
	c._dorm_solid(cart, c.make_solid, Vector3(2.0, 1.4, 1.1), Vector3(0, 0.7, 0))
	# The balloon stand: a weighted pole and a bunch that strains at its strings.
	var stand := _holder(c, Vector3(-12.5, 0, 26.0), 0.0)
	c.cyl(0.4, 0.5, 0.3, Vector3(0, 0.15, 0), rim, stand, 12)
	c.cyl(0.03, 0.03, 2.0, Vector3(0, 1.0, 0), rim, stand, 6)
	for k in 11:
		var ba := k * 2.4
		var br := 0.25 + (k % 4) * 0.2
		var bp := Vector3(cos(ba) * br, 2.6 + (k % 5) * 0.34, sin(ba) * br)
		_ball(c, bp, 0.3, c.mat(cols[k % cols.size()], 0.25, 0.1), stand, Vector3(1.0, 1.2, 1.0))
		var from := Vector3(0, 2.0, 0)
		var line := c.box(Vector3(0.008, 0.008, from.distance_to(bp)), (from + bp) / 2.0, wire, false, stand)
		line.basis = Basis.looking_at((bp - from).normalized(), Vector3.RIGHT)
	if c.make_solid:
		c.solid_cyl(0.5, 1.6, Vector3(-12.5, 0.8, 26.0))
	# Low posts with a light on top along the inner ring, and a few floor lamps set flush.
	for i in 24:
		var a3 := i * TAU / 24.0 + 0.13
		var bp2 := Vector3(cos(a3) * 13.0, 0, sin(a3) * 13.0)
		if absf(bp2.x) < 2.6 or (bp2.z > 11.0 and absf(bp2.x) < 7.0):
			continue
		batch.add(Vector3(0.16, 0.5, 0.16), bp2 + Vector3(0, 0.25, 0), shell)
		batch.add(Vector3(0.18, 0.08, 0.18), bp2 + Vector3(0, 0.54, 0), glows[0] if i % 2 == 0 else glows[1])
	batch.commit(c)
