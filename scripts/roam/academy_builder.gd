class_name AcademyBuilder
extends CityBuilder
## Duel Academy: a school on a volcanic island. Reuses CityBuilder's sky, lighting and prop helpers.

const SHORE := 72.0
const PIER := 12.0     # how much further out the pier sits than it used to


func _build_ground() -> void:
	# The sea: one big sheet with waves and foam on the beach.
	var sea := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1400, 1400)
	pm.subdivide_width = 4
	pm.subdivide_depth = 4
	sea.mesh = pm
	sea.material_override = water_material(SHORE + 7.3)
	sea.position = Vector3(0, -0.65, 0)
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sea)
	box(Vector3(900, 0.2, 900), Vector3(0, -2.4, 0), mat(Color(0.05, 0.16, 0.28), 0.9), false)
	# Sand, then grass, then stone paths
	cyl(SHORE + 4.0, SHORE + 9.0, 1.0, Vector3(0, -0.5, 0), surf("sand", Color(0.8, 0.72, 0.54)), null, 64)
	cyl(SHORE - 8.0, SHORE - 5.0, 0.3, Vector3(0, -0.06, 0), grass_material(1.5), null, 64)
	var floor_body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(200, 1, 200)
	cs.shape = sh
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.41, 0)
	add_child(floor_body)
	var path := surf("paving", Color(0.74, 0.7, 0.62), 1.15)
	box(Vector3(5.0, 0.12, 62.0 + PIER), Vector3(0, 0.1, 17.0 + PIER / 2.0), path, false)       # dock -> plaza -> academy
	box(Vector3(5.0, 0.12, 24.0), Vector3(0, 0.1, -20.0), path, false)
	box(Vector3(34.0, 0.12, 4.0), Vector3(-19.0, 0.1, 6.0), path, false)    # west to the red dorm
	box(Vector3(36.0, 0.12, 4.0), Vector3(20.0, 0.1, -4.0), path, false)    # east to the yellow dorm
	box(Vector3(4.0, 0.12, 22.0), Vector3(-30.0, 0.1, -6.0), path, false)   # up to the blue dorm
	box(Vector3(26.0, 0.12, 4.0), Vector3(30.0, 0.1, 30.0), path, false)    # to the lighthouse
	box(Vector3(4.0, 0.12, 30.0), Vector3(19.0, 0.1, 17.0), path, false)
	# Central plaza with the academy crest
	cyl(9.0, 9.0, 0.14, Vector3(0, 0.1, 0), _tile_material(Color(0.8, 0.76, 0.68), 1.0), null, 40)
	for rr in [[6.2, 6.5, 2.0], [3.0, 3.2, 1.4]]:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = rr[0]
		tm.outer_radius = rr[1]
		tm.rings = 64
		ring.mesh = tm
		ring.material_override = glow_mat(theme["accent"], rr[2])
		ring.scale = Vector3(1, 0.04, 1)
		ring.position.y = 0.19
		add_child(ring)
	# Wooden pier
	var wood := surf("wood", Color(0.56, 0.4, 0.25))
	box(Vector3(5.0, 0.3, 22.0), Vector3(0, 0.05, 59.0 + PIER), wood, false)
	for i in 6:
		for sx in [-1, 1]:
			cyl(0.18, 0.18, 2.4, Vector3(sx * 2.3, -0.5, 50.0 + PIER + i * 3.8), wood)
	_build_more_paths(path)


## Where each building's front door is: [floor point, outward direction]. The rooms behind them
## are in AcademyRooms; roam_scene reads this to put the doors in the right place.
var doors := {}


func _door(name: String, holder: Node3D, inset := 0.0) -> void:
	if holder == null:
		return
	var sz: Vector3 = holder.get_meta("size", Vector3.ONE)
	var out := Vector3(sin(holder.rotation.y), 0, cos(holder.rotation.y))
	var p := holder.position + out * (sz.z / 2.0 - inset)
	p.y = 0.0
	doors[name] = [p, out]
	set_meta("doors", doors)


func _build_buildings() -> void:
	if own_place("academy_main") != "":
		_own_academy()
	else:
		var main := prop("academy_main", Vector3(0, 0.05, -46.0), 0.0, 52.0)
		collide(main, 0.82)
		_door("academy_main", main, 0.0)
		neon_sign("DUEL ACADEMY", Vector3(0, 9.5, -30.5), Color("ffe9a8"), 260, 0.0, false)
	# The three dorms are our own houses, each a step up from the last: a plank house for Red,
	# a tiled manor with a front gable for Yellow, a white castle for Blue. Stairs outside, a
	# gallery along the upper floor, bedrooms that open onto it. (Drop your own dorm_red.glb,
	# dorm_yellow.glb or dorm_blue.glb in <card folder>/places and that model stands there
	# in place of ours.)
	if own_place("dorm_red") != "":
		_own_dorm("dorm_red", Vector3(-43.0, 0.05, 8.0), PI / 2, 14.0)
	else:
		var red := plank_dorm(Vector3(-43.0, 0.05, 8.0), PI / 2, Color("c8322a"))
		_dorm_doors("dorm_red", "red_room_%d", red)
	neon_sign("RED DORM", Vector3(-38.0, 2.65, 8.0), Color("ff8a7a"), 70, PI / 2, false)
	if own_place("dorm_yellow") != "":
		_own_dorm("dorm_yellow", Vector3(42.0, 0.05, -4.0), -PI / 2, 17.0)
	else:
		var yel := plank_dorm(Vector3(43.0, 0.05, -3.0), -PI / 2, Color("e8b21e"), true, {
			"wall": surf("plaster", Color(0.96, 0.9, 0.7)), "dark": surf("wood", Color(0.5, 0.34, 0.2)), "deck": surf("wood", Color(0.62, 0.46, 0.3)),
			"roof": surf("roof", Color(0.78, 0.56, 0.16)), "w": 17.0, "d": 7.6, "floor": 3.3, "rise": 3.0, "boxes": true, "manor": true})
		_dorm_doors("dorm_yellow", "yel_room_%d", yel)
		neon_sign("YELLOW DORM", Vector3(37.3, 2.95, -3.0), Color("ffe07a"), 70, -PI / 2, false)
	if own_place("dorm_blue") != "":
		_own_dorm("dorm_blue", Vector3(-34.0, 0.05, -25.0), 0.35, 24.0)
	else:
		var blu := plank_dorm(Vector3(-39.5, 0.05, -23.5), 0.35, Color("2f6fe0"), true, {
			"wall": surf("brick", Color(0.86, 0.88, 0.94), 1.6), "dark": mat(Color(0.74, 0.78, 0.86), 0.5, 0.1), "deck": mat(Color(0.7, 0.73, 0.8), 0.6),
			"roof": surf("roof", Color(0.18, 0.3, 0.6)), "w": 22.0, "d": 9.0, "floor": 3.8, "columns": true, "castle": true})
		_dorm_doors("dorm_blue", "blue_room_%d", blu)
		var bf: Array = blu.get_meta("front")
		neon_sign("BLUE DORM", (bf[0] as Vector3) + (bf[1] as Vector3) * 1.75 + Vector3(0, 3.45, 0), Color("9cc8ff"), 70, 0.35, false)
		# Two clipped trees in stone urns by the door.
		for sx: float in [-1.0, 1.0]:
			var up := (bf[0] as Vector3) + (bf[1] as Vector3) * 2.6 + (bf[1] as Vector3).cross(Vector3.UP) * sx * 2.4
			cyl(0.34, 0.24, 0.7, up + Vector3(0, 0.35, 0), mat(Color(0.9, 0.92, 0.96), 0.4, 0.1), null, 14)
			cyl(0.4, 0.34, 0.1, up + Vector3(0, 0.75, 0), mat(Color(0.86, 0.7, 0.32), 0.3, 0.8), null, 14)
			var bush := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.42
			sm.height = 0.8
			bush.mesh = sm
			bush.material_override = mat(Color(0.14, 0.4, 0.2), 0.95)
			bush.position = up + Vector3(0, 1.15, 0)
			add_child(bush)
			solid_cyl(0.36, 1.4, up + Vector3(0, 0.7, 0))
		# A paved way from the path to the castle doors.
		var way := box(Vector3(3.4, 0.12, 9.0), Vector3(-33.6, 0.1, -16.0), surf("paving", Color(0.74, 0.7, 0.62), 1.15), false)
		way.rotation.y = 0.75


## Your own model of a dorm: stood where ours would be, with a door in the middle of its front.
func _own_dorm(key: String, at: Vector3, yaw: float, size: float) -> void:
	var house := prop(key, at, yaw, size)
	collide(house, 0.85)
	_door(key, house, 0.6)


# ------------------------------------------------------------------ your own main building

const OWN_SIZE := 60.0        # its longest side, in meters
const OWN_FRONT := -24.5      # where its front edge stands (just behind the fountain)
var _own_rect := Rect2()      # its footprint on the island
var _own_grid := PackedFloat32Array()
var _own_nx := 0
var _own_nz := 0


## Your own model of the main building (<card folder>/places/academy_main.glb). It can be any
## shape, so nothing about it is assumed. It is stood with its front edge at the end of the
## path from the plaza, and the island is fitted to it: the ground you can walk on is read off
## the model itself (up a ramp, onto a terrace, stopped by a wall), the way in is put where a
## walk straight up the middle first meets the building, and people and statues that would end
## up inside it are moved out in front.
func _own_academy() -> void:
	var main := prop("academy_main", Vector3(0, 0.05, -46.0), 0.0, OWN_SIZE)
	var sz: Vector3 = main.get_meta("size")
	main.position.z = OWN_FRONT - sz.z / 2.0
	_own_rect = Rect2(-sz.x / 2.0, main.position.z - sz.z / 2.0, sz.x, sz.z)
	no_grass.append(_own_rect)
	_own_heights(main, sz)
	# The way in: walk up the middle from the front until something stands in the way.
	var door_z := OWN_FRONT
	var z := OWN_FRONT - 0.5
	while z > OWN_FRONT - sz.z * 0.45:
		if maxf(ground_at(0.0, z), maxf(ground_at(-0.8, z), ground_at(0.8, z))) > 1.3:
			break
		door_z = z
		z -= 0.5
	doors["academy_main"] = [Vector3(0, 0, door_z + 0.4), Vector3(0, 0, 1)]
	set_meta("doors", doors)
	set_meta("map_fix", {"Main Building": [Vector2(0, main.position.z), Vector2(sz.x, sz.z)], "Main Hall": [Vector2(0, door_z + 0.4), Vector2(4, 3)]})
	print("OWN academy_main size=", sz, " door z=", door_z, " grid=", _own_nx, "x", _own_nz)


## How high the model stands at each square meter of its footprint, taken from its vertices and
## kept on disk so a big model is only measured once. That grid is the ground you walk on.
func _own_heights(main: Node3D, sz: Vector3) -> void:
	_own_nx = int(ceil(sz.x)) + 1
	_own_nz = int(ceil(sz.z)) + 1
	var path := own_place("academy_main")
	var cache := "user://place_cache/academy_main_%d_%d_%dx%d.bin" % [FileAccess.get_modified_time(path), int(OWN_SIZE * 10.0), _own_nx, _own_nz]
	if FileAccess.file_exists(cache):
		var bytes := FileAccess.get_file_as_bytes(cache)
		if bytes.size() == _own_nx * _own_nz * 4:
			_own_grid = bytes.to_float32_array()
	if _own_grid.size() != _own_nx * _own_nz:
		_own_grid = PackedFloat32Array()
		_own_grid.resize(_own_nx * _own_nz)
		_own_grid.fill(-2.0)
		var inst := main.get_child(0) as Node3D
		for mi in Avatars._meshes(inst):
			if mi.mesh == null:
				continue
			# Mesh space -> the holder's space (which has its origin at the middle of the footprint).
			var xf := Transform3D.IDENTITY
			var n: Node = mi
			while n != null and n != main:
				if n is Node3D:
					xf = (n as Node3D).transform * xf
				n = n.get_parent()
			for si in mi.mesh.get_surface_count():
				var verts: PackedVector3Array = mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]
				for v in verts.size():
					var p := xf * verts[v]
					var ix := int(p.x + sz.x / 2.0 + 0.5)
					var iz := int(p.z + sz.z / 2.0 + 0.5)
					if ix < 0 or iz < 0 or ix >= _own_nx or iz >= _own_nz:
						continue
					var at := iz * _own_nx + ix
					if p.y > _own_grid[at]:
						_own_grid[at] = p.y
		DirAccess.make_dir_recursive_absolute("user://place_cache")
		var out := FileAccess.open(cache, FileAccess.WRITE)
		if out:
			out.store_buffer(_own_grid.to_byte_array())
	if not make_solid:
		return
	var shape := HeightMapShape3D.new()
	shape.map_width = _own_nx
	shape.map_depth = _own_nz
	shape.map_data = _own_grid
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = shape
	# The grid's first point is the footprint's corner; the shape is centred on its middle.
	cs.position = Vector3((_own_nx - 1) / 2.0 - sz.x / 2.0, 0, (_own_nz - 1) / 2.0 - sz.z / 2.0)
	body.add_child(cs)
	main.add_child(body)


## How high your own main building stands at this spot of the island (below zero: open ground).
func ground_at(x: float, z: float) -> float:
	if _own_grid.is_empty() or not _own_rect.has_point(Vector2(x, z)):
		return -2.0
	var ix := clampi(int(x - _own_rect.position.x + 0.5), 0, _own_nx - 1)
	var iz := clampi(int(z - _own_rect.position.y + 0.5), 0, _own_nz - 1)
	return _own_grid[iz * _own_nx + ix]


## Somebody or something that was placed for the game's own main building may now be standing
## inside yours: move them straight out in front of it, to open ground.
func clear_spot(p: Vector3) -> Vector3:
	if _own_grid.is_empty() or not _own_rect.grow(1.0).has_point(Vector2(p.x, p.z)):
		return p
	var q := p
	var tries := 0
	while tries < 80 and _blocked(q.x, q.z):
		q.z += 0.5
		tries += 1
	if q.z != p.z:
		q.z += 0.8
	return q


func _blocked(x: float, z: float) -> bool:
	for dx: float in [-0.9, 0.0, 0.9]:
		for dz: float in [-0.9, 0.0, 0.9]:
			if ground_at(x + dx, z + dz) > 0.3:
				return true
	return false


## Register a plank dorm's front door and its upstairs bedroom doors.
func _dorm_doors(key: String, room_fmt: String, house: Node3D) -> void:
	var front: Array = house.get_meta("front")
	doors[key] = [Vector3((front[0] as Vector3).x, 0, (front[0] as Vector3).z), front[1]]
	var ups: Array = house.get_meta("upper_doors")
	for i in ups.size():
		doors[room_fmt % (i + 1)] = ups[i]
	set_meta("doors", doors)


func _build_landmarks() -> void:
	collide(prop("lighthouse", Vector3(46.0, 0.0, 34.0), 0.0, 24.0, true), 0.6)
	var beam := SpotLight3D.new()
	beam.light_color = Color(1.0, 0.95, 0.8)
	beam.light_energy = 8.0
	beam.spot_range = 70.0
	beam.spot_angle = 14.0
	beam.position = Vector3(46.0, 21.5, 34.0)
	beam.rotation_degrees = Vector3(-8, 0, 0)
	beam.set_meta("spin", 0.5)
	add_child(beam)
	_spinners.append(beam)
	# The duel field where students settle things
	var stage := prop("duel_stage", Vector3(19.0, 0.1, 30.0), 0.0, 13.0)
	if stage == null:
		cyl(6.0, 6.0, 0.3, Vector3(19.0, 0.2, 30.0), mat(Color(0.5, 0.5, 0.56), 0.6), null, 32)
	# Ferry at the pier
	var boat := prop("ferry", Vector3(7.5, -0.7, 62.0 + PIER), 0.2, 15.0)
	if boat:
		_bobbers.append([boat, -0.7])
	# The volcano behind the school
	var rock_m := surf("rock", Color(0.34, 0.27, 0.24))
	cyl(16.0, 95.0, 70.0, Vector3(-30, 34, -175), rock_m, null, 22)
	cyl(13.0, 13.0, 1.0, Vector3(-30, 68.6, -175), glow_mat(Color(1.0, 0.36, 0.1), 3.0), null, 14)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.4, 0.15)
	glow.light_energy = 20.0
	glow.omni_range = 70.0
	glow.position = Vector3(-30, 76, -175)
	add_child(glow)
	# Cliffs along the north shore: clusters of weathered boulders, big ones behind, rubble
	# and sea rocks in front.
	var cliff_m := surf("rock", Color(0.5, 0.44, 0.38))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 16:
		var a := PI * 0.62 + i * (PI * 0.78 / 15.0) + PI * 0.5
		var r := SHORE + 7.0 + rng.randf_range(0, 5)
		var h := rng.randf_range(7.0, 15.0)
		var base := Vector3(cos(a) * r, -1.0, sin(a) * r - 4.0)
		rock(base + Vector3(0, h * 0.28, 0), Vector3(rng.randf_range(13, 18), h * 1.5, rng.randf_range(11, 15)), cliff_m, 40 + i, rng.randf() * TAU)
		for k in 3:
			var off := Vector3(rng.randf_range(-7, 7), 0, rng.randf_range(-6, 6))
			var hs := rng.randf_range(2.5, 6.5)
			rock(base + off + Vector3(0, hs * 0.2, 0), Vector3(rng.randf_range(4, 8), hs * 1.4, rng.randf_range(4, 7)), cliff_m, 200 + i * 7 + k, rng.randf() * TAU)
	# A few rocks standing in the shallows all the way round.
	for i in 22:
		var a2 := rng.randf() * TAU
		var r2 := SHORE + rng.randf_range(8.5, 20.0)
		var p2 := Vector3(cos(a2) * r2, -0.9, sin(a2) * r2)
		if absf(p2.x) < 12.0 and p2.z > 60.0:
			continue
		var s2 := rng.randf_range(1.2, 3.6)
		rock(p2 + Vector3(0, s2 * 0.25, 0), Vector3(s2 * rng.randf_range(1.0, 1.6), s2 * 1.2, s2), cliff_m, 500 + i, rng.randf() * TAU)


func _build_street_furniture() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	# Palms around the shore, leafy trees inland
	for i in 26:
		var a := i * TAU / 26.0 + rng.randf_range(-0.08, 0.08)
		var r := SHORE - rng.randf_range(1.5, 6.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if absf(p.x) < 5.0 and p.z > 50.0:
			continue
		if p.z < -40.0:
			continue
		var palm := prop("palm", p, rng.randf() * TAU, rng.randf_range(6.5, 9.0), true)
		if palm:
			solid_cyl(0.3, 3.0, p + Vector3(0, 1.5, 0))
		else:
			tree(p, 1.1)
	for p in [Vector3(-12, 0, 16), Vector3(-22, 0, 20), Vector3(10, 0, 14), Vector3(-10, 0, -10), Vector3(12, 0, -14), Vector3(28, 0, 8),
			Vector3(-16, 0, 34), Vector3(30, 0, 18), Vector3(-44, 0, -8), Vector3(10, 0, -24), Vector3(-12, 0, -24), Vector3(34, 0, -22)]:
		tree(p, rng.randf_range(0.9, 1.25))
	# Lamps and benches along the main path
	for z in [50.0, 38.0, 26.0, 13.0, -13.0, -24.0]:
		for sx in [-1, 1]:
			var lp := Vector3(sx * 3.4, 0.1, z)
			var lamp := prop("street_lamp", lp, PI / 2 if sx < 0 else -PI / 2, 5.0, true)
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.86, 0.62)
			l.light_energy = 2.4
			l.omni_range = 9.0
			l.position = lp + Vector3(-sx * 1.4, 4.4, 0)
			add_child(l)
			_lamp_lights.append(l)
			if lamp == null:
				cyl(0.07, 0.1, 4.4, lp + Vector3(0, 2.2, 0), mat(Color(0.15, 0.15, 0.18), 0.5, 0.6))
	for b in [[Vector3(-7.5, 0.1, 4.6), 0.0], [Vector3(7.5, 0.1, -5.4), PI], [Vector3(15.5, 0.1, 22.0), PI / 2], [Vector3(-3.6, 0.1, 32.0), PI / 2]]:
		collide(prop("bench", b[0], b[1], 1.9), 0.9)
	collide(prop("vending", Vector3(4.2, 0.1, 44.0 + PIER), -PI / 2, 1.95, true))
	collide(prop("fountain", Vector3(0, 0.12, -18.5), 0.0, 5.0), 0.8)
	# A statue by the school steps and banners at the dock
	collide(prop("dragon_statue", clear_spot(Vector3(-9.0, 0.1, -26.0)), 0.5, 4.5, true), 0.6)
	collide(prop("dragon_statue", clear_spot(Vector3(9.0, 0.1, -26.0)), -0.5, 4.5, true), 0.6)
	neon_sign("WELCOME TO DUEL ACADEMY", Vector3(0, 4.8, 47.0 + PIER), theme["accent2"], 120, PI, false)
	for sx in [-1, 1]:
		cyl(0.1, 0.1, 5.0, Vector3(sx * 6.0, 2.5, 47.0 + PIER), mat(Color(0.2, 0.2, 0.24), 0.4, 0.7))
	_build_new_places()
	_dress_dorms()
	_school_colors()
	# Last, once everything paved or built is known: grass, flowers and pebbles on the lawns.
	scatter_detail(Vector2.ZERO, SHORE - 9.0, 0.09, 1.5)


func _build_traffic() -> void:
	pass


func _build_walls() -> void:
	# Keep everyone on the island: a ring of invisible walls just inside the shoreline.
	for i in 34:
		var a := i * TAU / 34.0
		var r := SHORE - 3.0
		var p := Vector3(cos(a) * r, 2.0, sin(a) * r)
		if absf(p.x) < 4.0 and p.z > 50.0:
			continue
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(14.5, 6, 1.2)
		cs.shape = sh
		body.add_child(cs)
		body.position = p
		body.rotation.y = -a + PI / 2
		add_child(body)
	for w in [[Vector3(0, 2, 70.5 + PIER), Vector3(8, 6, 1)], [Vector3(-3.2, 2, 62 + PIER), Vector3(1, 6, 22)], [Vector3(3.2, 2, 62 + PIER), Vector3(1, 6, 22)]]:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = w[1]
		cs.shape = sh
		body.add_child(cs)
		body.position = w[0]
		add_child(body)


func _build_more_paths(path: Material) -> void:
	box(Vector3(4.0, 0.12, 28.0), Vector3(-40.0, 0.1, 24.0), path, false)    # red dorm down to the old woods
	box(Vector3(22.0, 0.12, 4.0), Vector3(-30.0, 0.1, 38.0), path, false)
	box(Vector3(22.0, 0.12, 4.0), Vector3(30.0, 0.1, 46.0), path, false)    # lighthouse down to the beach
	box(Vector3(4.0, 0.12, 18.0), Vector3(41.0, 0.1, 46.0), path, false)
	box(Vector3(16.0, 0.12, 4.0), Vector3(11.0, 0.1, -20.0), path, false)   # to the outdoor courts


## New on the island: an outdoor arena with stands, a beach, the old woods with a ruined dorm,
## tennis-court style practice duel fields and a cliff-top lookout.
func _build_new_places() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	# Stands around the outdoor duel field.
	var fc := Vector3(19.0, 0.1, 30.0)
	for k in 3:
		var a := PI * 0.5 + (k - 1) * 0.8
		var gp := fc + Vector3(cos(a), 0, sin(a)) * 11.0
		var g := prop("grandstand", gp, atan2(fc.x - gp.x, fc.z - gp.z), 9.0)
		if g:
			collide(g, 0.85)
	neon_sign("DUEL FIELD", fc + Vector3(0, 6.5, -9.0), Color("b48cff"), 140, 0.0, false)
	# The beach in the south-east: sand, umbrellas and towels.
	var sand := surf("sand", Color(0.82, 0.74, 0.55))
	cyl(16.0, 18.0, 0.2, Vector3(48.0, 0.0, 50.0), sand, null, 32)
	var cols := [Color("ff5a5a"), Color("ffd166"), Color("5ac8ff"), Color("7dffb0"), Color("ff8ad4")]
	for k in 6:
		var up := Vector3(40.0 + (k % 3) * 6.0, 0, 46.0 + (k / 3) * 7.0)
		cyl(0.05, 0.05, 2.6, up + Vector3(0, 1.3, 0), mat(Color(0.9, 0.9, 0.9), 0.5))
		var um := cyl(0.05, 1.5, 0.5, up + Vector3(0, 2.5, 0), mat(cols[k % cols.size()], 0.7), null, 10)
		um.rotation.z = 0.12
		box(Vector3(0.9, 0.03, 1.8), up + Vector3(1.0, 0.13, 0.6), mat(cols[(k + 2) % cols.size()], 0.9), false)
	# The old woods (south-west): dense trees around the ruins of an abandoned dorm.
	for i in 30:
		var p := Vector3(-48.0 + rng.randf_range(-14, 14), 0, 40.0 + rng.randf_range(-12, 14))
		if p.distance_to(Vector3(-46, 0, 42)) < 7.5 or Vector2(p.x, p.z).length() > SHORE - 6.0:
			continue
		tree(p, rng.randf_range(1.0, 1.5))
	var ruin := surf("brick", Color(0.52, 0.47, 0.44))
	var rc := Vector3(-46.0, 0, 42.0)
	box(Vector3(9.0, 0.3, 7.0), rc + Vector3(0, 0.15, 0), ruin)
	box(Vector3(9.0, 4.2, 0.4), rc + Vector3(0, 2.1, -3.3), ruin)
	box(Vector3(0.4, 3.0, 6.6), rc + Vector3(-4.3, 1.5, 0), ruin)
	box(Vector3(0.4, 2.0, 3.0), rc + Vector3(4.3, 1.0, -1.8), ruin)
	box(Vector3(3.4, 1.4, 0.4), rc + Vector3(-2.6, 0.7, 3.3), ruin)
	for k in 3:
		box(Vector3(1.0, 1.3, 0.06), rc + Vector3(-3.0 + k * 3.0, 2.6, -3.08), glow_mat(Color(0.5, 0.3, 0.8), 0.6), false)
	var boards := surf("wood", Color(0.4, 0.29, 0.2))
	for k in 4:
		var b := box(Vector3(2.6, 0.18, 0.06), rc + Vector3(-3.0 + (k % 2) * 6.0, 1.9 + (k / 2) * 0.7, -3.0), boards, false)
		b.rotation.z = 0.3 * (1 if k % 2 == 0 else -1)
	neon_sign("OLD DORM  ·  KEEP OUT", rc + Vector3(0, 4.6, -3.0), Color("b48cff"), 70, 0.0, false)
	var eerie := OmniLight3D.new()
	eerie.light_color = Color(0.6, 0.4, 1.0)
	eerie.light_energy = 2.0
	eerie.omni_range = 10.0
	eerie.position = rc + Vector3(0, 2.0, 0)
	add_child(eerie)
	# Practice fields by the main building: four painted duel mats with low fences.
	var courts := Vector3(18.0, 0.1, -22.0)
	for k in 2:
		var cp := courts + Vector3(k * 9.0, 0, 0)
		box(Vector3(7.5, 0.06, 5.5), cp + Vector3(0, 0.05, 0), mat(Color(0.2, 0.42, 0.5), 0.8), false)
		for side: float in [-1.0, 1.0]:
			box(Vector3(5.2, 0.065, 0.06), cp + Vector3(0, 0.06, side * 1.6), glow_mat(Color("7cc4ff"), 0.8), false)
			for z in 5:
				box(Vector3(0.7, 0.066, 0.9), cp + Vector3(-2.2 + z * 1.1, 0.06, side * 1.0), mat(Color(0.16, 0.3, 0.38), 0.8), false)
	neon_sign("PRACTICE FIELDS", courts + Vector3(4.5, 3.4, -3.6), Color("7cc4ff"), 90, 0.0, false)
	# A cliff-top lookout with a telescope, north-east.
	var lk := Vector3(40.0, 0, -36.0)
	cyl(4.0, 4.4, 0.4, lk + Vector3(0, 0.2, 0), surf("paving", Color(0.64, 0.62, 0.58), 0.9), null, 20)
	for k in 10:
		var a := PI * 1.1 + k * 0.12
		cyl(0.06, 0.06, 1.0, lk + Vector3(cos(a) * 3.8, 0.9, sin(a) * 3.8), mat(Color(0.25, 0.25, 0.28), 0.4, 0.6))
	var tel := cyl(0.12, 0.2, 1.2, lk + Vector3(1.4, 1.5, -1.6), mat(Color(0.7, 0.62, 0.3), 0.3, 0.8))
	tel.rotation.x = 0.9
	cyl(0.04, 0.06, 1.1, lk + Vector3(1.4, 0.75, -1.6), mat(Color(0.25, 0.25, 0.28), 0.4, 0.6))
	box(Vector3(14.0, 0.12, 4.0), Vector3(33.0, 0.1, -30.0), surf("paving", Color(0.74, 0.7, 0.62), 1.15), false)


## Each dorm gets a proper front yard: a paved forecourt, flower beds with a stone edge, a low
## hedge, lanterns by the door and a notice board.
func _dress_dorms() -> void:
	var stone := surf("paving", Color(0.7, 0.67, 0.6), 0.8)
	var edge := surf("rock", Color(0.6, 0.57, 0.52))
	var soil := mat(Color(0.3, 0.2, 0.13), 0.95)
	var hedge := mat(Color(0.14, 0.36, 0.14), 0.95)
	var wood := surf("wood", Color(0.46, 0.33, 0.2))
	var iron := mat(Color(0.14, 0.15, 0.18), 0.45, 0.7)
	var blooms := {"dorm_red": [Color("ff5a4a"), Color("ffb347")], "dorm_yellow": [Color("ffd84a"), Color("ffffff")], "dorm_blue": [Color("6fa8ff"), Color("e8e4ff")]}
	var rng := RandomNumberGenerator.new()
	rng.seed = 90
	for key in ["dorm_red", "dorm_yellow", "dorm_blue"]:
		if not doors.has(key):
			continue
		var door: Vector3 = doors[key][0]
		var out: Vector3 = doors[key][1]
		var side := Vector3(out.z, 0, -out.x)
		var yaw := atan2(out.x, out.z)
		var yard := Node3D.new()
		yard.position = door + out * 0.2
		yard.rotation.y = yaw
		add_child(yard)
		# Forecourt (local +Z is out from the door).
		var court := box(Vector3(6.4, 0.1, 5.0), Vector3(0, 0.12, 2.9), stone, false, yard)
		court.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var c0 := door + out * 3.1
		no_grass.append(Rect2(c0.x - 3.6, c0.z - 3.6, 7.2, 7.2))
		for sx: float in [-1.0, 1.0]:
			# A raised flower bed either side of the door, stone edge all round.
			var bed := Vector3(sx * 5.6, 0, 1.6)
			box(Vector3(4.2, 0.34, 1.7), bed + Vector3(0, 0.17, 0), edge, false, yard)
			box(Vector3(3.9, 0.1, 1.4), bed + Vector3(0, 0.36, 0), soil, false, yard)
			for k in 26:
				var fp := bed + Vector3(rng.randf_range(-1.8, 1.8), 0.4, rng.randf_range(-0.55, 0.55))
				var stem := cyl(0.012, 0.016, 0.3, fp + Vector3(0, 0.15, 0), hedge, yard, 5)
				stem.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var head := MeshInstance3D.new()
				var sm := SphereMesh.new()
				sm.radius = rng.randf_range(0.07, 0.12)
				sm.height = sm.radius * 1.5
				sm.radial_segments = 8
				sm.rings = 4
				head.mesh = sm
				head.material_override = mat((blooms[key] as Array)[k % 2], 0.8)
				head.position = fp + Vector3(0, 0.33, 0)
				head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				yard.add_child(head)
			for k in 7:
				var leaf := MeshInstance3D.new()
				var lm := SphereMesh.new()
				lm.radius = 0.28
				lm.height = 0.36
				lm.radial_segments = 8
				lm.rings = 4
				leaf.mesh = lm
				leaf.material_override = hedge
				leaf.position = bed + Vector3(-1.8 + k * 0.6, 0.46, rng.randf_range(-0.3, 0.3))
				yard.add_child(leaf)
			# A lantern on a post at each front corner of the forecourt.
			var lp := Vector3(sx * 3.0, 0, 5.2)
			cyl(0.05, 0.07, 2.3, lp + Vector3(0, 1.15, 0), iron, yard, 8)
			box(Vector3(0.3, 0.38, 0.3), lp + Vector3(0, 2.45, 0), glow_mat(Color(1.0, 0.86, 0.6), 1.2), false, yard)
			box(Vector3(0.38, 0.05, 0.38), lp + Vector3(0, 2.67, 0), iron, false, yard)
			box(Vector3(0.38, 0.05, 0.38), lp + Vector3(0, 2.24, 0), iron, false, yard)
			var wl := lp.rotated(Vector3.UP, yaw) + yard.position
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.84, 0.6)
			l.light_energy = 2.0
			l.omni_range = 7.0
			l.position = wl + Vector3(0, 2.5, 0)
			add_child(l)
			_lamp_lights.append(l)
			solid_cyl(0.12, 2.4, wl + Vector3(0, 1.2, 0))
			var wb := bed.rotated(Vector3.UP, yaw) + yard.position
			no_grass.append(Rect2(wb.x - 2.4, wb.z - 2.4, 4.8, 4.8))
			if make_solid:
				var body := StaticBody3D.new()
				var cs := CollisionShape3D.new()
				var bs := BoxShape3D.new()
				bs.size = Vector3(4.2, 0.6, 1.7)
				cs.shape = bs
				body.add_child(cs)
				body.position = bed + Vector3(0, 0.3, 0)
				body.collision_layer = 2
				yard.add_child(body)
		# The notice board, off to one side.
		var nb := Vector3(-4.6, 0, 4.6)
		for sx2: float in [-0.7, 0.7]:
			box(Vector3(0.1, 1.9, 0.1), nb + Vector3(sx2, 0.95, 0), wood, false, yard)
		box(Vector3(1.6, 1.0, 0.08), nb + Vector3(0, 1.35, 0), wood, false, yard)
		box(Vector3(1.4, 0.8, 0.02), nb + Vector3(0, 1.35, 0.05), mat(Color(0.42, 0.3, 0.2), 0.95), false, yard)
		for k in 5:
			var note := box(Vector3(0.26, 0.32, 0.01), nb + Vector3(-0.5 + (k % 3) * 0.5, 1.5 - (k / 3) * 0.36, 0.07), mat([Color("fff6d8"), Color("d8f0ff"), Color("ffe0e0")][k % 3], 0.9), false, yard)
			note.rotation.z = rng.randf_range(-0.12, 0.12)
		box(Vector3(1.8, 0.08, 0.3), nb + Vector3(0, 1.92, 0), surf("roof", Color(0.6, 0.25, 0.2)), false, yard)


## The three dorms are everywhere you look: banners in their colors on the lamp posts down the
## main path, bunting over the plaza, a pennant on a mast for each dorm, the school crest in
## the plaza paving, and smoke drifting off the volcano.
func _school_colors() -> void:
	var cols := [Color("d02030"), Color("f0c040"), Color("3070e0")]
	var k := 0
	for z in [50.0, 38.0, 26.0, 13.0, -13.0, -24.0]:
		for sx in [-1, 1]:
			var lp := Vector3(sx * 3.4, 0.1, z)
			var col: Color = cols[k % 3]
			var cloth := box(Vector3(0.04, 1.5, 0.6), lp + Vector3(sx * 0.12, 3.1, 0.42), mat(col, 0.8), false)
			cloth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			box(Vector3(0.05, 0.16, 0.62), lp + Vector3(sx * 0.12, 2.42, 0.42), mat(Color(0.95, 0.9, 0.78), 0.8), false)
			box(Vector3(0.05, 0.05, 0.7), lp + Vector3(sx * 0.12, 3.88, 0.4), mat(Color(0.2, 0.2, 0.24), 0.5, 0.5), false)
			k += 1
	# Bunting from four masts round the plaza to the middle one.
	var mast_m := mat(Color(0.8, 0.8, 0.84), 0.35, 0.6)
	for i in 6:
		var a := i * TAU / 6.0 + 0.3
		var mp := Vector3(cos(a) * 10.4, 0, sin(a) * 10.4)
		cyl(0.06, 0.09, 6.0, mp + Vector3(0, 3.0, 0), mast_m, null, 8)
		solid_cyl(0.12, 3.0, mp + Vector3(0, 1.5, 0))
		var a2 := (i + 1) * TAU / 6.0 + 0.3
		var np := Vector3(cos(a2) * 10.4, 0, sin(a2) * 10.4)
		for q in 12:
			var t := (q + 0.5) / 12.0
			var fp := (mp.lerp(np, t)) + Vector3(0, 5.8 - sin(t * PI) * 1.1, 0)
			var flag := box(Vector3(0.36, 0.44, 0.02), fp - Vector3(0, 0.22, 0), mat(cols[(q + i) % 3], 0.8), false)
			flag.rotation.y = atan2(np.x - mp.x, np.z - mp.z) + PI / 2.0
			flag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# A long pennant flying from the top of each mast.
		var pen := box(Vector3(1.5, 0.5, 0.03), mp + Vector3(0.78, 5.9, 0), mat(cols[i % 3], 0.8), false)
		pen.rotation.y = a + 0.6
		pen.position = mp + Vector3(cos(-a - 0.6) * 0.78, 5.9, sin(-a - 0.6) * 0.78)
	# The crest in the plaza: three wedges in the dorm colors round a gold disc.
	for i in 3:
		var a3 := i * TAU / 3.0 - PI / 2.0
		var wedge := box(Vector3(2.4, 0.02, 1.0), Vector3(cos(a3) * 1.9, 0.19, sin(a3) * 1.9), mat(cols[i], 0.7), false)
		wedge.rotation.y = -a3
		wedge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cyl(0.9, 0.9, 0.03, Vector3(0, 0.2, 0), mat(Color(0.86, 0.7, 0.32), 0.35, 0.7), null, 24)
	# Smoke off the crater.
	var smoke := GPUParticles3D.new()
	smoke.amount = 26
	smoke.lifetime = 14.0
	smoke.preprocess = 14.0
	var ppm := ParticleProcessMaterial.new()
	ppm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	ppm.emission_sphere_radius = 7.0
	ppm.direction = Vector3(0.35, 1.0, 0.1)
	ppm.spread = 12.0
	ppm.initial_velocity_min = 3.0
	ppm.initial_velocity_max = 5.0
	ppm.gravity = Vector3(0.5, 0.2, 0.0)
	ppm.scale_min = 0.6
	ppm.scale_max = 1.4
	var ramp := Curve.new()
	ramp.add_point(Vector2(0.0, 0.35))
	ramp.add_point(Vector2(1.0, 1.0))
	var ct := CurveTexture.new()
	ct.curve = ramp
	ppm.scale_curve = ct
	var fade := Gradient.new()
	fade.set_color(0, Color(0.5, 0.42, 0.4, 0.0))
	fade.add_point(0.15, Color(0.42, 0.38, 0.38, 0.55))
	fade.set_color(fade.get_point_count() - 1, Color(0.7, 0.7, 0.74, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = fade
	ppm.color_ramp = gt
	smoke.process_material = ppm
	var puff := SphereMesh.new()
	puff.radius = 9.0
	puff.height = 14.0
	puff.radial_segments = 10
	puff.rings = 6
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.vertex_color_use_as_albedo = true
	pm.disable_fog = true
	puff.material = pm
	smoke.draw_pass_1 = puff
	smoke.position = Vector3(-30, 72, -175)
	smoke.visibility_aabb = AABB(Vector3(-80, -10, -80), Vector3(220, 160, 160))
	smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(smoke)


var _spinners: Array = []
var _bobbers: Array = []


func _process(delta: float) -> void:
	super._process(delta)
	for s in _spinners:
		(s as Node3D).rotation.y += delta * float(s.get_meta("spin", 0.3))
	for b in _bobbers:
		(b[0] as Node3D).position.y = float(b[1]) + sin(_time * 0.9) * 0.12
		(b[0] as Node3D).rotation.z = sin(_time * 0.7) * 0.02
