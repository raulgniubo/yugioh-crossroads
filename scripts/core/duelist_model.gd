class_name DuelistModel
extends Node3D
## An original anime-style duelist built from shapes: cel-shaded with ink outlines,
## big eyes, a few hair styles and outfits, a duel disk, and a hand-made walk cycle.
## Used for anyone who doesn't have a .vrm model yet. Faces +Z, feet at y = 0.

const HAIR_COLORS := [Color("2a2230"), Color("4a3226"), Color("7a4a2a"), Color("c99a5a"), Color("e8d39a"), Color("3a4a6a"), Color("6a2a3a"), Color("d8d8e0")]
const EYE_COLORS := [Color("3a7be0"), Color("2fae6a"), Color("8a5a2a"), Color("a040d0"), Color("e0a020"), Color("d04050"), Color("30b0c0")]
const SKIN := [Color("ffe2cf"), Color("f6d0b4"), Color("e0b090"), Color("b98262"), Color("8a5a40")]

var look := {}
var _j := {}   # joints
var _phase := 0.0
var _time := 0.0
var _speed := 0.0
var _blink_at := 2.0
var _eyes: Array[MeshInstance3D] = []
var _look_target := 0.0


## A stable look for a character key (not a copy of any official design: colors come from
## the character's theme color, everything else from a hash of the key).
static func look_for(key: String, color: Color, gender := -1) -> Dictionary:
	var h := absi(hash(key))
	var g := gender if gender >= 0 else (h >> 3) % 2
	return {
		"skin": SKIN[(h >> 5) % 3],
		"hair": HAIR_COLORS[h % HAIR_COLORS.size()],
		"hair_style": (h >> 7) % 4 if g == 0 else [2, 2, 3, 1][(h >> 7) % 4],
		"eyes": EYE_COLORS[(h >> 9) % EYE_COLORS.size()],
		"jacket": color,
		"shirt": [Color("f2f2f5"), Color("20222a"), Color("e8e0c8")][(h >> 11) % 3],
		"pants": [Color("1c1f2a"), Color("2a3550"), Color("3a3a40"), Color("e8e8ee")][(h >> 13) % 4],
		"outfit": (h >> 15) % 3,
		"build": g,
	}


## The player's look: from their name, color, pronouns and chosen tints.
static func player_look() -> Dictionary:
	var l := look_for(Profile.duelist_name, Profile.color(), 1 if Profile.gender == 1 else 0)
	for g in ["hair", "eyes"]:
		var t: Color = Profile.tints.get(g, Color.WHITE)
		if t != Color.WHITE:
			l[g] = t
	var o: Color = Profile.tints.get("outfit", Color.WHITE)
	if o != Color.WHITE:
		l["pants"] = o.darkened(0.5)
	return l


func build(l: Dictionary) -> void:
	look = l
	for c in get_children():
		c.queue_free()
	_j.clear()
	_eyes.clear()
	var fem: bool = int(l.get("build", 0)) == 1
	var skin := Toon.mat(l["skin"], 0.006)
	var jacket := Toon.mat(l["jacket"], 0.01, 0.15)
	var shirt := Toon.mat(l["shirt"], 0.008)
	var pants := Toon.mat(l["pants"], 0.01)
	var shoes := Toon.mat(Color("15161c"), 0.008, 0.4)
	var hair := Toon.mat(l["hair"], 0.012, 0.35)
	var s := 0.94 if fem else 1.0

	var hips := _joint("hips", self, Vector3(0, 0.93 * s, 0))
	var torso := _joint("torso", hips, Vector3(0, 0.02, 0))
	# Pelvis and belt
	_cap(torso, Vector3(0, 0.02, 0), 0.15 if fem else 0.14, 0.2, pants, Vector3(1.1, 1, 0.8))
	_box(torso, Vector3(0, 0.1, 0), Vector3(0.3 if fem else 0.29, 0.04, 0.2), Toon.mat(Color("2a2420"), 0.005, 0.5))
	_box(torso, Vector3(0.15, 0.06, 0.06), Vector3(0.07, 0.09, 0.05), Toon.mat(Color("5a4a3a"), 0.005))  # deck box
	# Chest: shirt core with a jacket shell
	var chest_w := 0.17 if fem else 0.19
	_cap(torso, Vector3(0, 0.33, 0), chest_w, 0.5, shirt, Vector3(1.0, 1, 0.68))
	match int(l.get("outfit", 0)):
		0:  # open jacket: two panels and a collar
			for side in [-1.0, 1.0]:
				var p := _cap(torso, Vector3(side * 0.095, 0.31, 0.02), 0.1, 0.5, jacket, Vector3(0.75, 1, 0.75))
				p.rotation.z = side * 0.06
			_collar(torso, jacket)
		1:  # long coat, flares below the waist
			for side in [-1.0, 1.0]:
				var p := _cap(torso, Vector3(side * 0.09, 0.3, 0.015), 0.115, 0.52, jacket, Vector3(0.85, 1, 0.75))
				p.rotation.z = side * 0.05
				var tail := _cone(torso, Vector3(side * 0.09, -0.16, -0.01), 0.11, 0.17, 0.45, jacket)
				tail.rotation.z = side * 0.05
			_collar(torso, jacket)
		2:  # closed jacket with a zip line
			_cap(torso, Vector3(0, 0.32, 0), chest_w + 0.012, 0.5, jacket, Vector3(1.0, 1, 0.7))
			_box(torso, Vector3(0, 0.33, 0.13), Vector3(0.012, 0.36, 0.01), Toon.mat(Color("d0d0d8"), 0.0, 0.6))
			_collar(torso, jacket)
	if fem:
		_cone(torso, Vector3(0, -0.06, 0), 0.24, 0.15, 0.26, Toon.mat(Color(l["pants"]).lightened(0.05), 0.01))

	# Neck and head
	_cap(torso, Vector3(0, 0.6, 0), 0.045, 0.12, skin)
	var head := _joint("head", torso, Vector3(0, 0.66, 0))
	_build_head(head, l, skin, hair, fem)

	# Arms
	for side in [1.0, -1.0]:
		var n := "l" if side > 0 else "r"
		var sh := _joint("shoulder_" + n, torso, Vector3(side * (chest_w + 0.04), 0.5, 0))
		sh.rotation.z = side * 0.12
		_sphere(sh, Vector3(0, -0.02, 0), 0.052, jacket, Vector3(1, 0.8, 1))
		_cap(sh, Vector3(0, -0.14, 0), 0.055, 0.3, jacket)
		var el := _joint("elbow_" + n, sh, Vector3(0, -0.28, 0))
		_cap(el, Vector3(0, -0.12, 0), 0.047, 0.27, jacket)
		_cap(el, Vector3(0, -0.245, 0), 0.05, 0.05, shirt, Vector3(1, 0.6, 1))  # cuff
		_sphere(el, Vector3(0, -0.29, 0.01), 0.045, skin, Vector3(0.9, 1.2, 0.8))  # hand
		if side > 0:
			_duel_disk(el, l)

	# Legs
	for side in [1.0, -1.0]:
		var n := "l" if side > 0 else "r"
		var th := _joint("thigh_" + n, hips, Vector3(side * 0.095, 0.0, 0))
		_cap(th, Vector3(0, -0.21, 0), 0.075, 0.46, pants)
		var kn := _joint("knee_" + n, th, Vector3(0, -0.42, 0))
		_cap(kn, Vector3(0, -0.2, 0), 0.062, 0.44, pants)
		var foot := _cap(kn, Vector3(0, -0.43, 0.05), 0.055, 0.24, shoes, Vector3(1.05, 0.75, 1))
		foot.rotation.x = PI / 2


func _build_head(head: Node3D, l: Dictionary, skin: Material, hair: Material, fem: bool) -> void:
	var r := 0.135
	_sphere(head, Vector3(0, 0.12, 0), r, skin, Vector3(0.95, 1.05, 0.98))
	# Jaw: a softer, slightly pointed chin
	var jaw := _sphere(head, Vector3(0, 0.06, 0.02), r * 0.78, skin, Vector3(0.88, 0.8, 0.92))
	jaw.name = "Jaw"
	# Ears
	for side in [-1.0, 1.0]:
		_sphere(head, Vector3(side * r * 0.95, 0.11, -0.005), 0.025, skin, Vector3(0.5, 1, 0.8))
	# Eyes (instance uniform drives the blink)
	for side in [-1.0, 1.0]:
		var e := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.058, 0.072) if not fem else Vector2(0.062, 0.078)
		e.mesh = q
		e.material_override = Toon.eye_mat(l["eyes"])
		e.position = Vector3(side * 0.05, 0.105, r * 0.93)
		e.rotation.y = side * 0.32
		e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		head.add_child(e)
		_eyes.append(e)
		var brow := _box(head, Vector3(side * 0.052, 0.163, r * 0.9), Vector3(0.05, 0.009, 0.01), Toon.mat(Color(l["hair"]).darkened(0.3), 0.0))
		brow.rotation = Vector3(0, side * 0.3, -side * 0.12)
	var mouth := _box(head, Vector3(0, 0.035, r * 0.86), Vector3(0.026, 0.005, 0.008), Toon.mat(Color("7a3a3a"), 0.0))
	mouth.name = "Mouth"
	# Hair: cap + style pieces
	var cap := _sphere(head, Vector3(0, 0.155, -0.012), r * 1.08, hair, Vector3(1.0, 0.92, 1.02))
	cap.name = "HairCap"
	var style := int(l.get("hair_style", 0))
	# Fringe: a soft band over the forehead with a few locks falling from it
	var fringe := _sphere(head, Vector3(0, 0.218, 0.04), r * 0.98, hair, Vector3(1.04, 0.4, 0.95))
	fringe.name = "Fringe"
	for i in 5:
		var x := (i - 2) * 0.04
		var b := _cone(head, Vector3(x, 0.182, r * 0.88 - absf(i - 2) * 0.012), 0.024, 0.0, 0.07, hair)
		b.rotation = Vector3(PI + 0.25, (i - 2) * 0.25, (i - 2) * 0.12)
	match style:
		0:  # spiky
			var spikes := [[0.0, 0.9, 0.0], [0.5, 0.6, 0.5], [-0.5, 0.6, -0.5], [0.0, 0.5, 1.0], [0.9, 0.35, 0.8], [-0.9, 0.35, -0.8], [0.35, 0.25, 1.4], [-0.35, 0.25, -1.4]]
			for sp in spikes:
				var c := _cone(head, Vector3(sp[0] * 0.07, 0.2 + sp[1] * 0.06, -0.05), 0.06, 0.0, 0.2, hair)
				c.rotation = Vector3(-0.9 + sp[1] * 0.6, 0, sp[2] * 0.55)
		1:  # swept to one side
			var sw := _cap(head, Vector3(0.05, 0.24, 0.03), 0.07, 0.3, hair, Vector3(1, 1, 0.8))
			sw.rotation = Vector3(0.5, 0, -1.2)
			for i in 3:
				var c := _cone(head, Vector3(-0.08 + i * 0.02, 0.17, -0.11), 0.05, 0.0, 0.16, hair)
				c.rotation = Vector3(-2.3, 0, 0.4 - i * 0.3)
		2:  # long
			var back := _cap(head, Vector3(0, 0.02, -0.08), 0.12, 0.42, hair, Vector3(1.15, 1, 0.55))
			back.rotation.x = 0.12
			for side in [-1.0, 1.0]:
				var lock := _cap(head, Vector3(side * 0.12, 0.03, 0.03), 0.035, 0.26, hair)
				lock.rotation.z = side * 0.08
		3:  # short and neat
			_sphere(head, Vector3(0, 0.12, -0.05), r * 1.02, hair, Vector3(1.0, 0.95, 0.9))


func _collar(parent: Node3D, m: Material) -> void:
	for side in [-1.0, 1.0]:
		var c := _box(parent, Vector3(side * 0.07, 0.56, 0.06), Vector3(0.09, 0.07, 0.02), m)
		c.rotation = Vector3(-0.35, side * 0.5, side * 0.35)


func _duel_disk(arm: Node3D, l: Dictionary) -> void:
	var base := Toon.mat(Color("c8ccd8"), 0.006, 0.7)
	var accent: Color = l["jacket"]
	var glow := Toon.mat(accent.lightened(0.3), 0.0, 0.0, accent * 1.6)
	var disk := Node3D.new()
	disk.position = Vector3(0.06, -0.15, 0.0)
	disk.rotation = Vector3(0, 0, -PI / 2)
	arm.add_child(disk)
	var hub := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.07
	cyl.bottom_radius = 0.075
	cyl.height = 0.035
	hub.mesh = cyl
	hub.material_override = base
	disk.add_child(hub)
	var ring := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.045
	tor.outer_radius = 0.06
	ring.mesh = tor
	ring.material_override = glow
	ring.position.y = 0.02
	disk.add_child(ring)
	# The blade with card slots
	var blade := _box(disk, Vector3(0, 0.0, 0.2), Vector3(0.11, 0.015, 0.32), base)
	for i in 5:
		_box(disk, Vector3(0, 0.01, 0.07 + i * 0.06), Vector3(0.08, 0.006, 0.045), glow)
	blade.name = "Blade"


# ------------------------------------------------------------------ animation

func set_speed(v: float) -> void:
	_speed = v


func _process(delta: float) -> void:
	if _j.is_empty():
		return
	_time += delta
	var walk := clampf(_speed / 4.2, 0.0, 1.8)
	_phase += delta * (1.5 + _speed * 1.9)
	var s := sin(_phase)
	var c := cos(_phase)
	var breathe := sin(_time * 1.8)
	# Hips bob and sway; torso counter-twists.
	(_j["hips"] as Node3D).position.y = (_j["hips_base"] as float) - absf(s) * 0.035 * walk + breathe * 0.002
	(_j["hips"] as Node3D).rotation.y = s * 0.12 * walk
	(_j["torso"] as Node3D).rotation = Vector3(0.08 * walk, -s * 0.18 * walk, s * 0.02 * walk)
	(_j["torso"] as Node3D).scale = Vector3(1, 1 + breathe * 0.006, 1)
	# Legs: thigh swings, knee bends on the back swing.
	for side in [1.0, -1.0]:
		var n := "l" if side > 0 else "r"
		var ls: float = s * side
		(_j["thigh_" + n] as Node3D).rotation.x = -ls * 0.6 * walk
		(_j["knee_" + n] as Node3D).rotation.x = maxf(0.0, (c * side + 0.3)) * 0.9 * walk
		# Arms swing opposite, elbows bend a bit more when moving.
		(_j["shoulder_" + n] as Node3D).rotation.x = ls * 0.5 * walk + breathe * 0.01
		(_j["elbow_" + n] as Node3D).rotation.x = -0.15 - 0.45 * walk - maxf(0.0, ls) * 0.3 * walk
	# Head: steadies itself and glances around when idle.
	var head: Node3D = _j["head"]
	if walk < 0.1 and fmod(_time, 6.0) < delta:
		_look_target = randf_range(-0.5, 0.5)
	head.rotation.y = lerpf(head.rotation.y, _look_target if walk < 0.1 else 0.0, delta * 2.0)
	head.rotation.x = -0.04 * walk + sin(_time * 0.9) * 0.02
	# Blink
	var b := 0.0
	var t := _time - _blink_at
	if t >= 0.0:
		b = clampf(1.0 - absf(t - 0.06) / 0.06, 0.0, 1.0)
		if t > 0.12:
			_blink_at = _time + randf_range(2.0, 5.0)
	for e in _eyes:
		e.set_instance_shader_parameter("blink", b)


# ------------------------------------------------------------------ shapes

func _joint(n: String, parent: Node3D, pos: Vector3) -> Node3D:
	var j := Node3D.new()
	j.name = n
	j.position = pos
	parent.add_child(j)
	_j[n] = j
	if n == "hips":
		_j["hips_base"] = pos.y
	return j


func _mi(parent: Node3D, mesh: Mesh, m: Material, pos: Vector3, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.scale = scl
	parent.add_child(mi)
	return mi


func _cap(parent: Node3D, pos: Vector3, r: float, h: float, m: Material, scl := Vector3.ONE) -> MeshInstance3D:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = maxf(h, r * 2.0)
	c.radial_segments = 20
	c.rings = 6
	return _mi(parent, c, m, pos, scl)


func _sphere(parent: Node3D, pos: Vector3, r: float, m: Material, scl := Vector3.ONE) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 24
	sm.rings = 12
	return _mi(parent, sm, m, pos, scl)


func _box(parent: Node3D, pos: Vector3, size: Vector3, m: Material) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return _mi(parent, b, m, pos)


func _cone(parent: Node3D, pos: Vector3, r_bottom: float, r_top: float, h: float, m: Material) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.bottom_radius = r_bottom
	c.top_radius = r_top
	c.height = h
	c.radial_segments = 10
	var mi := _mi(parent, c, m, pos)
	return mi
