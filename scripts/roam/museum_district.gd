class_name MuseumDistrict
extends DuelArena
## The Curator's museum: white galleries adrift in the dark between the ages. One long walk
## from the door (south, +Z) through three galleries to the round hall at the end, where the
## empty plinth of Exhibit Zero stands. Story only: you cannot travel here from the map.

const WALK_W := 7.0
const HALLS := [22.0, 2.0, -18.0]          # centres of the three galleries (z)
const HALL_SIZE := Vector2(26.0, 15.0)
const ROTUNDA := Vector3(0, 0, -44.0)
const ROTUNDA_R := 13.5
const DOOR_Z := 40.0

var _frames: Array = []     # floating pictures: [node, base y, speed, phase]
var _marble: Material
var _gold: Material
var _dark: Material


func build(t: Dictionary, time_of_day: String) -> void:
	theme = t
	_build_env()
	make_solid = false
	var before := get_child_count()
	_void()
	# The drifting rocks keep their distance: nothing touches the galleries.
	for i in range(before, get_child_count()):
		var n := get_child(i)
		if n is Node3D and not (n is MeshInstance3D):
			var p: Vector3 = (n as Node3D).position
			(n as Node3D).position = Vector3(signf(p.x if p.x != 0.0 else 1.0) * (absf(p.x) + 34.0), p.y - 6.0, p.z * 1.6 - 8.0)
			for b in _bob:
				if b[0] == n:
					b[1] = (n as Node3D).position.y
	_marble = mat(Color(0.84, 0.85, 0.9), 0.3, 0.05)
	_gold = glow_mat(Color("ffd98a"), 1.3)
	_dark = mat(Color(0.16, 0.18, 0.26), 0.5, 0.2)
	_floors()
	_colonnades()
	_gallery(0, Color("ffcf8a"))
	_gallery(1, Color("9fe0ff"))
	_gallery(2, Color("ffa3c4"))
	_rotunda()
	_door()
	_sky_frames()
	apply_tod(time_of_day)


func _slab(size: Vector3, pos: Vector3) -> void:
	box(size, pos, _marble, false)
	# A gold line around the edge and a darker underside, so it reads as a thing that floats.
	box(Vector3(size.x + 0.3, 0.5, size.z + 0.3), pos + Vector3(0, -0.4, 0), _dark, false)
	for sx: float in [-1.0, 1.0]:
		box(Vector3(0.12, 0.03, size.z - 0.4), pos + Vector3(sx * (size.x * 0.5 - 0.35), size.y * 0.5 + 0.005, 0), _gold, false)


func _wall(size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	body.add_child(cs)
	body.position = pos
	add_child(body)


func _floors() -> void:
	var floor_body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(240, 1, 240)
	cs.shape = sh
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.5, 0)
	add_child(floor_body)
	# The walk, door to rotunda.
	var south := DOOR_Z + 4.0
	var north := ROTUNDA.z + ROTUNDA_R - 1.0
	_slab(Vector3(WALK_W, 0.1, south - north), Vector3(0, -0.05, (south + north) * 0.5))
	for z: float in HALLS:
		_slab(Vector3(HALL_SIZE.x, 0.12, HALL_SIZE.y), Vector3(0, -0.045, z))
	# Rails you cannot walk through: the edge of every floor.
	var hw := WALK_W * 0.5
	var edges: Array = [south]
	for z: float in HALLS:
		edges.append(z + HALL_SIZE.y * 0.5)
		edges.append(z - HALL_SIZE.y * 0.5)
	edges.append(north)
	for i in range(0, edges.size(), 2):
		var a: float = edges[i]
		var b: float = edges[i + 1]
		for sx: float in [-1.0, 1.0]:
			_wall(Vector3(0.4, 4, a - b), Vector3(sx * (hw + 0.2), 2, (a + b) * 0.5))
	_wall(Vector3(WALK_W + 1, 4, 0.4), Vector3(0, 2, south + 0.2))
	for z: float in HALLS:
		var hx := HALL_SIZE.x * 0.5
		var hz := HALL_SIZE.y * 0.5
		for sx: float in [-1.0, 1.0]:
			_wall(Vector3(0.4, 4, HALL_SIZE.y), Vector3(sx * (hx + 0.2), 2, z))
			for sz: float in [-1.0, 1.0]:
				_wall(Vector3(hx - hw, 4, 0.4), Vector3(sx * (hw + (hx - hw) * 0.5), 2, z + sz * (hz + 0.2)))
	# The rotunda: a disc, with a ring of short walls.
	var disc := cyl(ROTUNDA_R, ROTUNDA_R, 0.14, ROTUNDA + Vector3(0, -0.04, 0), _marble, null, 48)
	disc.set_meta("see_through", true)
	cyl(ROTUNDA_R + 0.3, ROTUNDA_R - 1.5, 0.7, ROTUNDA + Vector3(0, -0.5, 0), _dark, null, 48)
	for i in 28:
		var a := float(i) / 28.0 * TAU
		var p := ROTUNDA + Vector3(sin(a), 0, cos(a)) * (ROTUNDA_R + 0.2)
		if absf(p.x) < hw and p.z > ROTUNDA.z:
			continue
		var body := StaticBody3D.new()
		var c2 := CollisionShape3D.new()
		var s2 := BoxShape3D.new()
		s2.size = Vector3(3.4, 4, 0.4)
		c2.shape = s2
		body.add_child(c2)
		body.position = p + Vector3(0, 2, 0)
		body.rotation.y = a
		add_child(body)
	# Rings of gold set into the rotunda floor.
	for r: float in [4.0, 8.5, 12.6]:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = r - 0.06
		tm.outer_radius = r + 0.06
		tm.rings = 64
		ring.mesh = tm
		ring.material_override = _gold
		ring.scale = Vector3(1, 0.12, 1)
		ring.position = ROTUNDA + Vector3(0, 0.04, 0)
		ring.set_meta("see_through", true)
		add_child(ring)


func _column(at: Vector3, h := 7.0) -> void:
	cyl(0.34, 0.4, h, at + Vector3(0, h * 0.5, 0), _marble, null, 14)
	box(Vector3(1.0, 0.25, 1.0), at + Vector3(0, 0.12, 0), _marble, false)
	box(Vector3(1.0, 0.25, 1.0), at + Vector3(0, h + 0.1, 0), _marble, false)
	cyl(0.42, 0.42, 0.06, at + Vector3(0, h - 0.3, 0), _gold, null, 14)
	solid_cyl(0.42, 3.0, at)


func _colonnades() -> void:
	# Columns down both sides of the walk, between the galleries, with a beam across the top.
	var z := DOOR_Z + 1.0
	var skip: Array = []
	for hz: float in HALLS:
		skip.append([hz - HALL_SIZE.y * 0.5 - 0.5, hz + HALL_SIZE.y * 0.5 + 0.5])
	while z > ROTUNDA.z + ROTUNDA_R:
		var inside := false
		for s in skip:
			if z > float(s[0]) and z < float(s[1]):
				inside = true
		if not inside:
			for sx: float in [-1.0, 1.0]:
				_column(Vector3(sx * (WALK_W * 0.5 - 0.5), 0, z))
			box(Vector3(WALK_W + 0.6, 0.35, 0.5), Vector3(0, 7.45, z), _marble, false)
		z -= 4.0


## A picture that holds a moment: a frame, a pane of warm light, a small plaque.
func _picture(at: Vector3, yaw: float, w: float, h: float, col: Color, parent: Node3D = null) -> Node3D:
	var n := Node3D.new()
	n.position = at
	n.rotation.y = yaw
	(parent if parent else self).add_child(n)
	box(Vector3(w + 0.3, h + 0.3, 0.12), Vector3.ZERO, _gold, false, n)
	var pane := box(Vector3(w, h, 0.14), Vector3(0, 0, 0.01), glow_mat(col.darkened(0.12), 0.75), false, n)
	pane.set_meta("see_through", true)
	# Something inside the light: the shape of a day, never quite a picture.
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(at.x * 31.0 + at.z * 17.0 + at.y * 7.0))
	for i in 3:
		var blob := box(Vector3(rng.randf_range(0.15, 0.4) * w, rng.randf_range(0.2, 0.55) * h, 0.15), Vector3(rng.randf_range(-0.3, 0.3) * w, rng.randf_range(-0.25, 0.1) * h, 0.02), glow_mat(col.lightened(0.35), 1.25), false, n)
		blob.set_meta("see_through", true)
	return n


func _plinth(at: Vector3, r := 0.85, h := 0.5) -> void:
	cyl(r, r + 0.1, h, at + Vector3(0, h * 0.5, 0), _marble, null, 20)
	cyl(r + 0.02, r + 0.02, 0.05, at + Vector3(0, h - 0.02, 0), _gold, null, 20)


func _gallery(i: int, col: Color) -> void:
	var z: float = HALLS[i]
	var hx := HALL_SIZE.x * 0.5
	var hz := HALL_SIZE.y * 0.5
	# Back walls on the two sides, hung with pictures.
	for sx: float in [-1.0, 1.0]:
		box(Vector3(0.5, 6.5, HALL_SIZE.y - 1.0), Vector3(sx * (hx - 0.25), 3.25, z), _marble, false)
		box(Vector3(0.6, 0.3, HALL_SIZE.y - 0.6), Vector3(sx * (hx - 0.25), 6.6, z), _gold, false)
		for k in 3:
			_picture(Vector3(sx * (hx - 0.6), 3.1, z + (float(k) - 1.0) * 4.2), -sx * PI / 2.0, 2.6, 3.4, col.lerp(Color.WHITE, 0.15 * float(k)))
		# Corner columns.
		for sz: float in [-1.0, 1.0]:
			_column(Vector3(sx * (hx - 1.2), 0, z + sz * (hz - 1.2)), 6.4)
	# Plinths for the people kept here. The story stands its Hollows on these.
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_plinth(Vector3(sx * 7.5, 0, z + sz * 3.6))
	# A bench in the middle, as if anyone ever sat down in here.
	for sx: float in [-1.0, 1.0]:
		box(Vector3(0.5, 0.45, 2.6), Vector3(sx * 4.6, 0.22, z), _marble)
	var l := OmniLight3D.new()
	l.light_color = col.lerp(Color.WHITE, 0.5)
	l.light_energy = 2.4
	l.omni_range = 20.0
	l.position = Vector3(0, 6.0, z)
	l.shadow_enabled = false
	add_child(l)
	var name_y := 5.4
	for sx: float in [-1.0, 1.0]:
		var lab := Label3D.new()
		lab.text = ["GALLERY I  ·  FIRST WINS", "GALLERY II  ·  BEST FRIENDS", "GALLERY III  ·  LAST LAPS"][i]
		lab.font = UITheme.semi_font()
		lab.font_size = 64
		lab.pixel_size = 0.006
		lab.modulate = Color(0.25, 0.22, 0.16)
		lab.position = Vector3(sx * (hx - 0.55), name_y + 0.5, z)
		lab.rotation.y = -sx * PI / 2.0
		add_child(lab)


func _rotunda() -> void:
	# A ring of tall columns, an open sky, and in the middle the one plinth that is empty.
	for i in 12:
		var a := (float(i) + 0.5) / 12.0 * TAU
		_column(ROTUNDA + Vector3(sin(a), 0, cos(a)) * (ROTUNDA_R - 1.0), 9.0)
	_plinth(ROTUNDA, 1.5, 0.7)
	var zero := Label3D.new()
	zero.text = "EXHIBIT 0"
	zero.font = UITheme.title_font()
	zero.font_size = 90
	zero.pixel_size = 0.006
	zero.modulate = Color(0.35, 0.3, 0.2)
	zero.position = ROTUNDA + Vector3(0, 0.42, 1.62)
	add_child(zero)
	# The great frame that hangs over it: a ring of gold with nothing inside. It turns.
	var frame := Node3D.new()
	frame.position = ROTUNDA + Vector3(0, 6.2, 0)
	add_child(frame)
	for r: float in [3.0, 3.6]:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = r - 0.08
		tm.outer_radius = r + 0.08
		tm.rings = 48
		ring.mesh = tm
		ring.material_override = _gold
		ring.rotation = Vector3(PI / 2.0 if r < 3.3 else 0.4, 0, 0.3 if r > 3.3 else 0.0)
		ring.set_meta("see_through", true)
		frame.add_child(ring)
	_spin.append(frame)
	var l := OmniLight3D.new()
	l.light_color = Color("fff1d0")
	l.light_energy = 3.2
	l.omni_range = 26.0
	l.position = ROTUNDA + Vector3(0, 7.5, 0)
	l.shadow_enabled = false
	add_child(l)
	# Pictures between the columns: the masterpieces.
	for i in 6:
		var a := (float(i) + 0.5) / 6.0 * TAU
		if absf(sin(a)) < 0.3 and cos(a) > 0.0:
			continue
		var p := ROTUNDA + Vector3(sin(a), 0, cos(a)) * (ROTUNDA_R - 0.4)
		_picture(p + Vector3(0, 3.6, 0), a + PI, 3.4, 4.6, [Color("ffcf8a"), Color("9fe0ff"), Color("ffa3c4"), Color("c9a8ff"), Color("a8ffc9"), Color("ffe680")][i])


func _door() -> void:
	# Where you come in: a tall white arch with the dark behind it.
	for sx: float in [-1.0, 1.0]:
		box(Vector3(0.9, 8.0, 0.9), Vector3(sx * 2.6, 4.0, DOOR_Z + 3.2), _marble, false)
	box(Vector3(6.6, 0.9, 0.9), Vector3(0, 8.3, DOOR_Z + 3.2), _marble, false)
	box(Vector3(6.8, 0.14, 1.0), Vector3(0, 7.8, DOOR_Z + 3.2), _gold, false)
	var sign := Label3D.new()
	sign.text = "NOTHING HERE EVER ENDS"
	sign.font = UITheme.title_font()
	sign.font_size = 110
	sign.pixel_size = 0.006
	sign.modulate = Color(0.3, 0.26, 0.18)
	sign.position = Vector3(0, 8.3, DOOR_Z + 2.7)
	sign.rotation.y = PI
	add_child(sign)
	var l := OmniLight3D.new()
	l.light_color = Color("dfeaff")
	l.light_energy = 2.0
	l.omni_range = 16.0
	l.position = Vector3(0, 5.0, DOOR_Z - 2.0)
	l.shadow_enabled = false
	add_child(l)
	for z: float in [32.0, 12.0, -8.0, -28.0]:
		var wl := OmniLight3D.new()
		wl.light_color = Color("eef2ff")
		wl.light_energy = 1.3
		wl.omni_range = 11.0
		wl.position = Vector3(0, 5.0, z)
		wl.shadow_enabled = false
		add_child(wl)


func _sky_frames() -> void:
	# Hundreds of days, hanging in the dark as far as you can see.
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var cols := [Color("ffcf8a"), Color("9fe0ff"), Color("ffa3c4"), Color("c9a8ff"), Color("a8ffc9"), Color("ffe680")]
	for i in 90:
		var side := 1.0 if i % 2 == 0 else -1.0
		var p := Vector3(side * rng.randf_range(20.0, 62.0), rng.randf_range(-6.0, 26.0), rng.randf_range(-70.0, 50.0))
		var s := rng.randf_range(1.2, 3.6)
		var n := _picture(p, -side * PI / 2.0 + rng.randf_range(-0.5, 0.5), s, s * 1.3, cols[rng.randi() % cols.size()])
		_frames.append([n, p.y, rng.randf_range(0.2, 0.6), rng.randf() * TAU])


func _process(delta: float) -> void:
	super._process(delta)
	for f in _frames:
		(f[0] as Node3D).position.y = float(f[1]) + sin(_time * float(f[2]) + float(f[3])) * 0.5
