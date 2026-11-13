class_name WorldLife
extends Node3D
## Everything that makes a district feel lived in: street dressing, clouds, lamp halos, birds that
## scatter, cats to pet, people sitting and chatting, benches you can sit on, vending machines,
## favors to do for people, and the small sounds of the place.

var scene: Node                 # the RoamScene
var city: CityBuilder
var key := "domino"
var _t := 0.0
var _clouds: Array = []
var _halos: Array = []          # [Sprite3D, OmniLight3D]
var _flocks: Array = []         # [{birds: [...], home: Vector3, state, t}]
var _gulls: Array = []
var _flutter: Array = []        # butterflies: [node, center, phase]
var _pairs: Array = []          # chatting pairs: [figure a, figure b, timer, who]
var _items: Array = []          # errand items lying around: [node, errand]
var _water: Array = []          # fountain sounds waiting for their stream
var _amb_t := 3.0
var _waves: Array = []
var errands := {}               # id -> 0 not started, 1 looking, 2 item found, 3 done
var seated := false
var duels: StreetDuels
var _seat_out := Vector3.ZERO

const PEOPLE := ["student_boy", "student_girl", "office_worker", "stylish_woman", "street_duelist", "duelist_f1", "duelist_m5", "duelist_m9"]

## Favors people ask of you. "giver" is the id of someone in the district.
const ERRANDS := {
	"domino": [
		{"id": "dom_card", "giver": "kid", "thing": "a lost card", "at": Vector3(21.0, 0, 62.5),
			"ask": ["Oh no, oh no... I dropped my best card somewhere by the harbor benches.", "If you see it, could you bring it back? I'll make it worth your while!"],
			"wait": ["Any luck? I dropped it down by the harbor, near the benches."],
			"done": ["My card! You found it! Here, take this. You earned it."], "reward": 250},
		{"id": "dom_parcel", "giver": "vendor", "thing": "the parcel", "at": Vector3(-3.5, 0, -41.0),
			"ask": ["A courier left my parcel of sleeves in the KaibaCorp plaza by mistake.", "My knees aren't what they were. Would you fetch it for me?"],
			"wait": ["The parcel should still be in the plaza, up north by the tower."],
			"done": ["That's the one. Not a scratch on it. Thank you, here's something for your trouble."], "reward": 250},
	],
	"academy": [
		{"id": "ac_deckbox", "giver": "syrus", "thing": "Syrus's deck box", "at": Vector3(50.5, 0, 53.0),
			"ask": ["I left my deck box on the beach this morning and now I can't find it...", "If you're heading that way, could you look for it? Please?"],
			"wait": ["It's a small blue box. I think I left it near the umbrellas on the beach."],
			"done": ["You found it! Oh man, thank you. I thought I'd have to tell my brother. Take this!"], "reward": 250},
		{"id": "ac_notes", "giver": "professor", "thing": "the lecture notes", "at": Vector3(41.5, 0, -34.0),
			"ask": ["I was reading at the lookout and the wind took my lecture notes right out of my hands.", "Would you be so kind as to gather them up?"],
			"wait": ["The lookout is past the practice fields, at the north-east cliff."],
			"done": ["Every page! Splendid. Consider this extra credit."], "reward": 250},
	],
}


func setup(roam: Node) -> void:
	scene = roam
	city = roam.city
	key = str(Router.roam.get("district", "domino"))
	errands = roam.extras._errands if roam.extras else {}
	_build_clouds()
	_build_halos()
	if key == "academy":
		_decor_academy()
	else:
		_decor_domino()
	_build_seats()
	_room_extras()
	duels = StreetDuels.new()
	add_child(duels)
	# Story scenes stage their own crowd; the street duels sit out a chapter.
	if str(Router.roam.get("story", "")) == "":
		duels.setup(self, key)
	if "--sit" in OS.get_cmdline_user_args():
		get_tree().create_timer(0.5).timeout.connect(debug_sit)
	_build_errands()
	for pl in city.places:
		if pl[0] == "fountain":
			var a := AudioStreamPlayer3D.new()
			a.position = (pl[1] as Vector3) + Vector3(0, 1.0, 0)
			a.unit_size = 4.0
			a.max_distance = 26.0
			a.volume_db = -8.0
			a.bus = "SFX"
			add_child(a)
			_water.append(a)


# ------------------------------------------------------------------ small builders

func _m(c: Color, rough := 0.8, metal := 0.0) -> StandardMaterial3D:
	return city.mat(c, rough, metal)


func _box(size: Vector3, pos: Vector3, m: Material, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	(parent if parent else self).add_child(mi)
	return mi


func _cyl(rt: float, rb: float, h: float, pos: Vector3, m: Material, parent: Node3D = null, segs := 12) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = segs
	mi.mesh = c
	mi.material_override = m
	mi.position = pos
	(parent if parent else self).add_child(mi)
	return mi


func _ball(r: float, pos: Vector3, m: Material, parent: Node3D = null, squash := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = m
	mi.position = pos
	mi.scale = squash
	(parent if parent else self).add_child(mi)
	return mi


func _solid(r: float, h: float, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = h
	cs.shape = sh
	body.add_child(cs)
	body.position = pos + Vector3(0, h / 2.0, 0)
	body.collision_layer = 2
	add_child(body)


func bin(p: Vector3) -> void:
	_cyl(0.26, 0.22, 0.8, p + Vector3(0, 0.4, 0), _m(Color(0.16, 0.34, 0.26), 0.6, 0.3))
	_cyl(0.28, 0.28, 0.06, p + Vector3(0, 0.83, 0), _m(Color(0.1, 0.2, 0.16), 0.5, 0.4))
	_solid(0.26, 0.9, p)


func planter(p: Vector3, long := 1.6, rot := 0.0, flowers := true) -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = rot
	add_child(n)
	_box(Vector3(long, 0.5, 0.6), Vector3(0, 0.25, 0), _m(Color(0.62, 0.6, 0.56), 0.9), n)
	_box(Vector3(long - 0.1, 0.06, 0.5), Vector3(0, 0.5, 0), _m(Color(0.24, 0.16, 0.1), 1.0), n)
	var leaf := _m(Color(0.22, 0.5, 0.26), 0.9)
	var cols := [Color("ff6b8a"), Color("ffd166"), Color("ffffff"), Color("c78bff"), Color("ff9a3c")]
	var k := 0
	var x := -long / 2.0 + 0.3
	while x < long / 2.0 - 0.1:
		_ball(0.24, Vector3(x, 0.66, 0), leaf, n, Vector3(1, 0.8, 1))
		if flowers:
			for f in 3:
				_ball(0.06, Vector3(x + cos(f * 2.1 + k) * 0.14, 0.86 + 0.03 * f, sin(f * 2.1 + k) * 0.14), _m(cols[(k + f) % cols.size()], 0.7), n)
		x += 0.42
		k += 1
	_solid(0.34, 0.6, p)


func hydrant(p: Vector3) -> void:
	var red := _m(Color(0.82, 0.14, 0.12), 0.5, 0.2)
	_cyl(0.11, 0.13, 0.55, p + Vector3(0, 0.28, 0), red)
	_ball(0.12, p + Vector3(0, 0.56, 0), red)
	_cyl(0.05, 0.05, 0.34, p + Vector3(0, 0.4, 0), red).rotation.z = PI / 2
	_solid(0.14, 0.7, p)


func cone(p: Vector3) -> void:
	_cyl(0.03, 0.16, 0.45, p + Vector3(0, 0.24, 0), _m(Color(1.0, 0.45, 0.1), 0.6))
	_cyl(0.085, 0.105, 0.08, p + Vector3(0, 0.26, 0), _m(Color.WHITE, 0.6))
	_box(Vector3(0.36, 0.03, 0.36), p + Vector3(0, 0.02, 0), _m(Color(1.0, 0.45, 0.1), 0.6))


func mailbox(p: Vector3, rot := 0.0) -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = rot
	add_child(n)
	_box(Vector3(0.5, 0.75, 0.45), Vector3(0, 0.85, 0), _m(Color(0.85, 0.16, 0.14), 0.45, 0.2), n)
	_cyl(0.225, 0.225, 0.5, Vector3(0, 1.22, 0), _m(Color(0.85, 0.16, 0.14), 0.45, 0.2), n).rotation.z = PI / 2
	_box(Vector3(0.3, 0.04, 0.02), Vector3(0, 1.0, 0.23), _m(Color(0.1, 0.1, 0.1)), n)
	_cyl(0.05, 0.05, 0.5, Vector3(0, 0.25, 0), _m(Color(0.2, 0.2, 0.22), 0.4, 0.6), n)
	_solid(0.28, 1.4, p)


func a_sign(p: Vector3, rot: float, col: Color) -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = rot
	add_child(n)
	for s: float in [-1.0, 1.0]:
		var b := _box(Vector3(0.6, 0.9, 0.04), Vector3(0, 0.45, s * 0.14), _m(Color(0.12, 0.12, 0.14), 0.7), n)
		b.rotation.x = -s * 0.28
		var f := _box(Vector3(0.5, 0.5, 0.02), Vector3(0, 0.55, s * 0.175), city.glow_mat(col, 0.5), n)
		f.rotation.x = -s * 0.28


func crate_stack(p: Vector3, n := 3) -> void:
	var wood := _m(Color(0.56, 0.4, 0.24), 0.9)
	for i in n:
		var b := _box(Vector3(0.7, 0.6, 0.7), p + Vector3((i % 2) * 0.72, 0.3 + (i / 2) * 0.6, 0), wood)
		b.rotation.y = i * 0.2
	_solid(0.6, 1.0, p + Vector3(0.36, 0, 0))


func cafe_table(p: Vector3, col: Color) -> void:
	var metal := _m(Color(0.85, 0.86, 0.88), 0.3, 0.7)
	_cyl(0.5, 0.5, 0.04, p + Vector3(0, 0.74, 0), _m(Color(0.95, 0.95, 0.93), 0.4))
	_cyl(0.04, 0.04, 0.74, p + Vector3(0, 0.37, 0), metal)
	_cyl(0.26, 0.26, 0.03, p + Vector3(0, 0.02, 0), metal)
	_cyl(0.03, 0.03, 2.3, p + Vector3(0, 1.15, 0), metal)
	_cyl(0.04, 1.25, 0.42, p + Vector3(0, 2.36, 0), _m(col, 0.8), null, 8)
	for a in 3:
		var cp := p + Vector3(cos(a * 2.1 + 0.4) * 0.85, 0, sin(a * 2.1 + 0.4) * 0.85)
		_cyl(0.2, 0.2, 0.04, cp + Vector3(0, 0.46, 0), _m(col.darkened(0.2), 0.7))
		_cyl(0.025, 0.14, 0.46, cp + Vector3(0, 0.23, 0), metal)
	_cyl(0.05, 0.04, 0.1, p + Vector3(0.15, 0.81, 0.1), _m(Color.WHITE, 0.4))
	_solid(0.5, 0.9, p)


func bunting(a: Vector3, b: Vector3, n := 12) -> void:
	var cols := [Color("ff5a5a"), Color("ffd166"), Color("5ac8ff"), Color("7dffb0"), Color("c78bff")]
	var line := _box(Vector3(0.02, 0.02, a.distance_to(b)), (a + b) / 2.0, _m(Color(0.1, 0.1, 0.1)))
	line.look_at_from_position((a + b) / 2.0, b)
	for i in n:
		var t := (i + 0.5) / n
		var p := a.lerp(b, t) - Vector3(0, sin(t * PI) * 0.5 + 0.2, 0)
		var f := _box(Vector3(0.34, 0.4, 0.01), p, _m(cols[i % cols.size()], 0.8))
		f.look_at_from_position(p, p + (b - a).cross(Vector3.UP))
		f.set_meta("sway", i * 0.7)
		_waves.append(f)


func puddle(p: Vector3, r: float) -> void:
	var m := _m(Color(0.1, 0.13, 0.18, 0.8), 0.02, 0.9)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var d := _cyl(r, r, 0.004, p + Vector3(0, 0.014, 0), m, null, 18)
	d.scale = Vector3(1.0, 1.0, 0.62)
	d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func manhole(p: Vector3) -> void:
	_cyl(0.42, 0.42, 0.006, p + Vector3(0, 0.013, 0), _m(Color(0.2, 0.2, 0.22), 0.5, 0.7), null, 18).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func bike(p: Vector3, rot: float, col: Color) -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = rot
	n.rotation.z = 0.12
	add_child(n)
	var tire := _m(Color(0.08, 0.08, 0.09), 0.7)
	for s: float in [-1.0, 1.0]:
		var w := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.27
		tm.outer_radius = 0.33
		w.mesh = tm
		w.material_override = tire
		w.rotation.x = PI / 2
		w.position = Vector3(s * 0.5, 0.33, 0)
		n.add_child(w)
	var fr := _m(col, 0.4, 0.5)
	_box(Vector3(0.9, 0.04, 0.04), Vector3(0, 0.62, 0), fr, n)
	_box(Vector3(0.04, 0.5, 0.04), Vector3(-0.2, 0.62, 0), fr, n)
	_box(Vector3(0.04, 0.6, 0.04), Vector3(0.45, 0.66, 0), fr, n).rotation.z = 0.25
	_box(Vector3(0.24, 0.05, 0.12), Vector3(-0.2, 0.9, 0), tire, n)
	_box(Vector3(0.04, 0.04, 0.5), Vector3(0.52, 0.98, 0), tire, n)


func signpost(p: Vector3, arrows: Array) -> void:
	_cyl(0.05, 0.06, 2.6, p + Vector3(0, 1.3, 0), _m(Color(0.36, 0.26, 0.18), 0.8))
	_solid(0.12, 2.0, p)
	for i in arrows.size():
		var a: Array = arrows[i]
		var holder := Node3D.new()
		holder.position = p + Vector3(0, 2.35 - i * 0.36, 0)
		holder.rotation.y = float(a[1])
		add_child(holder)
		_box(Vector3(1.5, 0.28, 0.05), Vector3(0.7, 0, 0), _m(Color(0.93, 0.89, 0.78), 0.8), holder)
		for face: float in [1.0, -1.0]:
			var l := Label3D.new()
			l.text = Loc.t(str(a[0])) + ("  ▸" if face > 0 else "")
			if face < 0:
				l.text = "◂  " + Loc.t(str(a[0]))
			l.font = UITheme.semi_font()
			l.font_size = 40
			l.pixel_size = 0.0042
			l.modulate = Color(0.2, 0.14, 0.1)
			l.outline_size = 0
			l.double_sided = false
			l.position = Vector3(0.7, 0, 0.03 * face)
			l.rotation.y = 0.0 if face > 0 else PI
			holder.add_child(l)


func cat(p: Vector3, rot: float, fur_col: Color, name := "cat") -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = rot
	add_child(n)
	var fur := _m(fur_col, 0.95)
	_ball(0.17, Vector3(0, 0.17, 0), fur, n, Vector3(1.0, 1.0, 1.5))
	_ball(0.11, Vector3(0, 0.3, 0.2), fur, n)
	for e: float in [-1.0, 1.0]:
		_cyl(0.0, 0.035, 0.08, Vector3(e * 0.06, 0.41, 0.2), fur, n, 4)
		_ball(0.014, Vector3(e * 0.04, 0.32, 0.3), city.glow_mat(Color("b8ff7a"), 0.6), n)
	var tail := _cyl(0.02, 0.028, 0.34, Vector3(0.1, 0.12, -0.26), fur, n)
	tail.rotation = Vector3(PI / 2, 0, 0.7)
	tail.set_meta("tail", true)
	_waves.append(tail)
	var who := name
	scene._spots.append({"pos": p, "range": 1.5, "label": "Pet the cat", "action": func(): _pet(n, who)})


func _pet(n: Node3D, who: String) -> void:
	Sfx.play("meow", -6.0, randf_range(0.9, 1.2))
	Sfx.play("purr", -6.0)
	scene._figure.gesture("listen", 0.2)
	scene._figure._hold = 1.6
	var tw := create_tween()
	tw.tween_property(n, "scale", Vector3(1.08, 0.9, 1.08), 0.15)
	tw.tween_property(n, "scale", Vector3.ONE, 0.25)
	var flag := "cat_%s_%s" % [who, scene._today()]
	Collection.daily_bump("cat")
	if not scene._shop_flag(flag):
		scene._shop_set(flag, true)
		Collection.dp += 5
		Collection.save()
		Router.toast(Loc.t("The cat purrs.  +5 Duel Points"))
	else:
		Collection.save()
		Router.toast(Loc.t(["The cat purrs.", "The cat rolls over.", "The cat blinks slowly at you."][randi() % 3]))


# ------------------------------------------------------------------ sky and light

func _build_clouds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1, 1, 1, 0.85)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_fog = true
	set_meta("cloud_mat", m)
	for i in 14:
		var c := Node3D.new()
		c.position = Vector3(rng.randf_range(-260, 260), rng.randf_range(70, 110), rng.randf_range(-260, 260))
		add_child(c)
		for k in rng.randi_range(4, 7):
			var puff := _ball(rng.randf_range(9, 16), Vector3(rng.randf_range(-22, 22), rng.randf_range(-2, 3), rng.randf_range(-9, 9)), m, c, Vector3(1.6, 0.45, 1.0))
			puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_clouds.append([c, rng.randf_range(1.2, 2.6)])


func _build_halos() -> void:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	grad.colors = PackedColorArray([Color(1, 0.92, 0.75, 0.9), Color(1, 0.85, 0.6, 0.28), Color(1, 0.8, 0.5, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 128
	gt.height = 128
	for l in city._lamp_lights:
		if not is_instance_valid(l):
			continue
		var s := Sprite3D.new()
		s.texture = gt
		s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		s.pixel_size = 0.022
		s.shaded = false
		s.transparent = true
		s.no_depth_test = false
		s.modulate = Color(1, 0.9, 0.7, 0.8)
		s.position = (l as Node3D).global_position
		add_child(s)
		_halos.append([s, l])


# ------------------------------------------------------------------ animals

func flock(home: Vector3, n := 7, col := Color(0.55, 0.56, 0.62)) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(home.x * 13 + home.z * 7)
	var birds: Array = []
	var body := _m(col, 0.9)
	for i in n:
		var b := Node3D.new()
		var off := Vector3(rng.randf_range(-1.6, 1.6), 0, rng.randf_range(-1.6, 1.6))
		b.position = home + off
		b.rotation.y = rng.randf() * TAU
		add_child(b)
		_ball(0.09, Vector3(0, 0.1, 0), body, b, Vector3(1, 1, 1.5))
		_ball(0.055, Vector3(0, 0.19, 0.11), body, b)
		_cyl(0.0, 0.02, 0.05, Vector3(0, 0.18, 0.18), _m(Color(0.9, 0.6, 0.2)), b, 4).rotation.x = PI / 2
		var wings: Array = []
		for s: float in [-1.0, 1.0]:
			var w := _box(Vector3(0.22, 0.015, 0.13), Vector3(s * 0.12, 0.13, 0), body, b)
			w.visible = false
			wings.append(w)
		birds.append({"n": b, "home": home + off, "wings": wings, "dir": Vector3(off.x, 0, off.z).normalized() if off.length() > 0.1 else Vector3(1, 0, 0), "ph": rng.randf() * 6.0})
	_flocks.append({"birds": birds, "home": home, "state": 0, "t": 0.0})


func gulls(center: Vector3, n := 5) -> void:
	var white := _m(Color(0.96, 0.96, 0.96), 0.9)
	for i in n:
		var b := Node3D.new()
		add_child(b)
		_ball(0.14, Vector3.ZERO, white, b, Vector3(1, 0.8, 2.0))
		var wings: Array = []
		for s: float in [-1.0, 1.0]:
			wings.append(_box(Vector3(0.7, 0.02, 0.2), Vector3(s * 0.4, 0, 0), white, b))
		_gulls.append({"n": b, "c": center + Vector3(i * 9.0 - 18.0, i * 2.0, (i % 2) * 14.0), "r": 14.0 + i * 5.0, "sp": 0.25 + i * 0.04, "ph": i * 1.3, "wings": wings})


func butterflies(center: Vector3, n := 5) -> void:
	var cols := [Color("ffd166"), Color("ff8ad4"), Color("7dd3ff"), Color("ffffff"), Color("ff9a3c")]
	for i in n:
		var b := Node3D.new()
		add_child(b)
		var m := city.glow_mat(cols[i % cols.size()], 0.4)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		var wings: Array = []
		for s: float in [-1.0, 1.0]:
			wings.append(_box(Vector3(0.09, 0.004, 0.11), Vector3(s * 0.05, 0, 0), m, b))
		_flutter.append({"n": b, "c": center, "ph": i * 2.3, "wings": wings})


# ------------------------------------------------------------------ people who are just there

func _person(model: String, pos: Vector3, rot: float, stance := "stand", dorm := "") -> RoamFigure:
	var f := RoamFigure.new()
	add_child(f)
	f.position = pos
	f.rotation.y = rot
	f.setup(model if Avatars.has_avatar(model) else "student_boy", Color.GRAY, "", false)
	f.stance = stance
	f.greets = false
	f.watch = scene._player
	if dorm != "":
		f.wear_uniform(Avatars.DORM_COLORS[dorm])
	return f


## Two people talking: they take turns, one moves their hands while the other listens.
func chat_pair(at: Vector3, yaw: float, a: String, b: String, dorm_a := "", dorm_b := "") -> void:
	var dir := Vector3(sin(yaw), 0, cos(yaw))
	var fa := _person(a, at - dir * 0.55, yaw, "stand", dorm_a)
	var fb := _person(b, at + dir * 0.55, yaw + PI, "stand", dorm_b)
	fa.lively = false
	fb.lively = false
	fa.watch = null
	fb.watch = null
	_pairs.append([fa, fb, randf_range(0.5, 3.0), 0])
	_solid(0.75, 1.7, at)


## People who are just there: in line at the counter, on the arcade cabinets, talking in the hall.
## They have nothing to say to you, which is what makes a room feel busy.
func _room_extras() -> void:
	var rooms := Interiors.all_rooms()
	var extras := {
		"burger": [["line", Vector3(-1.2, 0, -2.2), PI, "office_worker", ""], ["line", Vector3(-1.2, 0, -1.2), PI, "student_girl", ""],
			["pair", Vector3(1.6, 0, 3.2), 0.4, "duelist_m5", "stylish_woman"]],
		"arcade": [["line", Vector3(-1.5, 0, -3.3), PI, "student_boy", ""], ["line", Vector3(1.5, 0, -3.3), PI, "duelist_f1", ""],
			["pair", Vector3(-0.2, 0, 2.6), 1.2, "student_girl", "duelist_m9"]],
		"kc_lobby": [["pair", Vector3(3.8, 0, 3.0), 0.8, "office_worker", "stylish_woman"], ["line", Vector3(-2.2, 0, -2.2), PI, "office_worker", ""]],
		"ac_hall": [["pair", Vector3(-6.0, 0, 4.5), 0.5, "student_boy", "student_girl", "red", "blue"], ["pair", Vector3(7.0, 0, 1.0), -0.9, "student_girl", "student_boy", "yellow", "red"],
			["line", Vector3(-9.5, 0, -2.0), 1.4, "student_boy", "blue"]],
		"dorm_blue": [["pair", Vector3(4.0, 0, 3.0), 0.3, "student_boy", "student_girl", "blue", "blue"]],
		"dorm_yellow": [["pair", Vector3(-3.5, 0, 2.6), -0.4, "student_girl", "student_boy", "yellow", "yellow"]],
		"mart": [["line", Vector3(4.4, 0, -0.9), PI, "student_boy", ""]],
		"ac_library": [["line", Vector3(-7.9, 0, -1.0), -PI / 2.0, "student_girl", "red"], ["line", Vector3(7.9, 0, -3.0), PI / 2.0, "student_boy", "blue"]],
	}
	for rk in extras:
		if not rooms.has(rk) or str(rooms[rk].get("district", "domino")) != key:
			continue
		var o: Vector3 = rooms[rk]["at"]
		for e in extras[rk]:
			if e[0] == "pair":
				chat_pair(o + (e[1] as Vector3), float(e[2]), str(e[3]), str(e[4]), str(e[5]) if e.size() > 5 else "", str(e[6]) if e.size() > 6 else "")
			else:
				var f := _person(str(e[3]), o + (e[1] as Vector3), float(e[2]), "browse" if rk in ["mart", "ac_library", "arcade"] else "stand", str(e[4]))
				f.watch = null


func sitter(seat_pos: Vector3, rot: float, model: String, dorm := "") -> void:
	var dir := Vector3(sin(rot), 0, cos(rot))
	_person(model, seat_pos + dir * 0.02, rot, "rest", dorm)


func _build_seats() -> void:
	var i := 0
	for pl in city.places:
		var pos: Vector3 = pl[1]
		var rot: float = pl[2]
		if pl[0] == "bench":
			var front := Vector3(sin(rot), 0, cos(rot))
			# Some benches are taken; the rest are yours to sit on.
			if i % 3 == 1:
				sitter(Vector3(pos.x, 0.16 if key != "academy" else 0.1, pos.z), rot, PEOPLE[(i * 3) % PEOPLE.size()], ["red", "yellow", "blue"][i % 3] if key == "academy" else "")
			else:
				var sp := Vector3(pos.x, 0, pos.z)
				scene._spots.append({"pos": sp + front * 0.9, "range": 1.5, "label": "Sit down", "action": func(): sit(sp, rot)})
			i += 1
		elif pl[0] == "vending":
			var vfront := Vector3(sin(rot), 0, cos(rot))
			var vp := Vector3(pos.x, 0, pos.z)
			scene._spots.append({"pos": vp + vfront * 1.0, "range": 1.4, "label": "Buy a drink  ·  10 DP", "action": _drink})


## Dev: --sit puts the player on the first free bench and prints where, for a screenshot.
func debug_sit() -> void:
	for pl in city.places:
		if pl[0] == "bench":
			var pos: Vector3 = pl[1]
			sit(Vector3(pos.x, 0, pos.z), pl[2])
			print("SIT at ", pos, " rot ", pl[2])
			return


func sit(seat: Vector3, rot: float) -> void:
	if seated:
		return
	seated = true
	var front := Vector3(sin(rot), 0, cos(rot))
	_seat_out = seat + front * 1.0
	scene._player.velocity = Vector3.ZERO
	scene._player.global_position = seat + front * 0.02 + Vector3(0, scene._player.global_position.y, 0)
	scene._figure.rotation.y = rot
	scene._figure.stance = "rest"
	scene._figure._cur_clip = ""
	Sfx.play("sit", -6.0)
	Collection.daily_bump("sit")
	Collection.save()
	Router.toast(Loc.t("You take a seat. Move to stand up."))


func stand_up() -> void:
	if not seated:
		return
	seated = false
	scene._figure.stance = "stand"
	scene._figure._cur_clip = ""
	scene._player.global_position = Vector3(_seat_out.x, scene._player.global_position.y, _seat_out.z)


const DRINKS := ["A cold Duel Cola. Refreshing.", "Melon soda. Bright green, tastes like summer.", "Canned coffee. Still warm.",
	"Mystery flavor. You still don't know what it was.", "Peach tea. Good choice."]


func _drink() -> void:
	if Collection.dp < 10:
		Router.toast("Not enough Duel Points")
		Sfx.play("error", -6.0)
		return
	Collection.dp -= 10
	Sfx.play("can", -4.0)
	get_tree().create_timer(0.5).timeout.connect(func(): Sfx.play("fizz", -10.0))
	scene._figure.gesture("phone", 0.25)
	scene._figure._hold = 2.2
	if randi() % 8 == 0:
		Collection.dp += 60
		Router.toast(Loc.t("A winning can! The machine pays out.  +60 Duel Points"))
		Sfx.play("coin", -3.0)
	else:
		Router.toast(Loc.t(DRINKS[randi() % DRINKS.size()]))
	Collection.save()


# ------------------------------------------------------------------ favors

func _errand_for(npc_id: String) -> Dictionary:
	for e in ERRANDS.get(key, []):
		if e["giver"] == npc_id:
			return e
	return {}


func _build_errands() -> void:
	for e in ERRANDS.get(key, []):
		if int(errands.get(e["id"], 0)) == 1:
			_drop_item(e)


func _drop_item(e: Dictionary) -> void:
	var n := Node3D.new()
	n.position = (e["at"] as Vector3) + Vector3(0, 0.5, 0)
	add_child(n)
	_box(Vector3(0.34, 0.24, 0.24), Vector3.ZERO, city.glow_mat(Color("7dd3ff"), 1.4), n)
	_box(Vector3(0.36, 0.05, 0.26), Vector3(0, 0.1, 0), city.glow_mat(Color("ffd166"), 1.6), n)
	var l := OmniLight3D.new()
	l.light_color = Color("9fe0ff")
	l.light_energy = 1.6
	l.omni_range = 4.0
	n.add_child(l)
	var beam := _cyl(0.05, 0.3, 5.0, Vector3(0, 2.4, 0), city.glow_mat(Color(0.6, 0.85, 1.0), 0.8), n)
	(beam.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	(beam.material_override as StandardMaterial3D).albedo_color.a = 0.25
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_items.append([n, e])


## What someone says when you talk to them, if a favor is involved. Empty when it isn't.
func errand_talk(npc: Dictionary) -> Array:
	var e := _errand_for(str(npc.get("id", "")))
	if e.is_empty():
		return []
	var st := int(errands.get(e["id"], 0))
	match st:
		0:
			errands[e["id"]] = 1
			_save()
			_drop_item(e)
			if scene.extras:
				scene.extras.set_waypoint(e["at"], Loc.t(str(e["thing"])).capitalize())
			Router.toast(Loc.t("New favor: find %s") % Loc.t(str(e["thing"])))
			Sfx.play("quest", -6.0)
			return e["ask"]
		1:
			if scene.extras and not scene.extras.has_waypoint():
				scene.extras.set_waypoint(e["at"], Loc.t(str(e["thing"])).capitalize())
			return e["wait"]
		2:
			errands[e["id"]] = 3
			_save()
			Collection.dp += int(e["reward"])
			Collection.daily_bump("errand")
			Collection.save()
			Router.toast(Loc.t("Favor done!  +%d Duel Points") % int(e["reward"]))
			Sfx.play("quest", -3.0)
			return e["done"]
	return []


func _save() -> void:
	if scene.extras:
		scene.extras._errands = errands
		scene.extras._save()


# ------------------------------------------------------------------ Domino City

func _decor_domino() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	# Along the kerbs: bins, planters, hydrants, bikes. Kept clear of the crossings.
	var k := 0
	for z: float in [11.0, 16.5, 21.0, 27.5, 31.0]:
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				var p := Vector3(sx * 6.45, 0.16, sz * z)
				var q := Vector3(sz * z, 0.16, sx * 6.45)
				match k % 5:
					0: planter(p, 1.6, PI / 2)
					1: bin(q)
					2: bike(p + Vector3(sx * 0.2, 0, 0), PI / 2 + 0.2, [Color("e0533f"), Color("3f7be0"), Color("3fbf8a")][k % 3])
					3: planter(q, 1.6, 0.0)
					4: hydrant(p)
				k += 1
	mailbox(Vector3(-6.8, 0.16, 8.6), PI / 2)
	mailbox(Vector3(8.6, 0.16, -6.8), 0.0)
	# The cafe terrace and a few boards outside the shops.
	for i in 3:
		cafe_table(Vector3(20.0 + i * 2.6, 0.16, -8.4), [Color("d9342b"), Color("f2f2ee"), Color("d9342b")][i])
	a_sign(Vector3(-11.8, 0.16, -14.6), 0.3, Color("ffd166"))
	a_sign(Vector3(18.2, 0.16, -9.6), -0.4, Color("ff8a5a"))
	a_sign(Vector3(-20.0, 0.16, -9.6), 0.2, Color("7dffb0"))
	crate_stack(Vector3(-17.5, 0.16, 20.5), 3)
	crate_stack(Vector3(27.0, 0.16, 18.0), 4)
	for c in [Vector3(3.2, 0, 16.0), Vector3(3.6, 0, 17.2), Vector3(-3.4, 0, -22.0)]:
		cone(c)
	# Festival bunting over the main streets.
	bunting(Vector3(-6.6, 6.0, 12.0), Vector3(6.6, 6.0, 12.0))
	bunting(Vector3(-6.6, 6.0, -12.0), Vector3(6.6, 6.0, -12.0))
	bunting(Vector3(12.0, 6.0, -6.6), Vector3(12.0, 6.0, 6.6))
	bunting(Vector3(-12.0, 6.0, -6.6), Vector3(-12.0, 6.0, 6.6))
	bunting(Vector3(-6.6, 6.2, -30.0), Vector3(6.6, 6.2, -30.0))
	# The road itself: covers and puddles that catch the lights.
	for p in [Vector3(2.5, 0, 14), Vector3(-2.4, 0, -18), Vector3(15, 0, 2.6), Vector3(-21, 0, -2.2), Vector3(2.2, 0, 30)]:
		manhole(p)
	for p in [Vector3(-3.6, 0, 9.5), Vector3(4.4, 0, -15.5), Vector3(-17.5, 0, 3.8), Vector3(22.0, 0, -3.5), Vector3(-4.0, 0, 26.0), Vector3(9.5, 0, 4.4)]:
		puddle(p, rng.randf_range(0.8, 1.5))
	# Pigeons where there is room for them, a couple of cats, butterflies in the park.
	flock(Vector3(19.0, 0.18, 14.5))
	flock(DominoPlus.PLAZA + Vector3(7.0, 0.05, 3.0), 9)
	flock(Vector3(-6.0, 0.05, 62.0), 6, Color(0.9, 0.9, 0.9))
	gulls(Vector3(0, 22, 78), 4)
	cat(Vector3(-13.6, 0.16, -14.4), 0.9, Color(0.9, 0.55, 0.2), "ginger")
	cat(Vector3(23.4, 0.16, 20.6), -2.0, Color(0.18, 0.18, 0.2), "black")
	cat(Vector3(-9.0, 0.02, 61.0), 2.4, Color(0.92, 0.92, 0.9), "harbor")
	butterflies(Vector3(19.0, 1.0, 22.0), 5)
	# People who are just out and about.
	chat_pair(Vector3(12.0, 0.16, 20.5), 0.9, "stylish_woman", "office_worker")
	chat_pair(Vector3(-20.2, 0.16, -8.0), -0.6, "student_girl", "student_boy")
	chat_pair(DominoPlus.PLAZA + Vector3(-8.5, 0.02, 4.0), 2.2, "duelist_m5", "street_duelist")
	chat_pair(Vector3(10.0, 0.02, 57.0), 1.57, "duelist_f1", "office_worker")


# ------------------------------------------------------------------ Duel Academy

func _decor_academy() -> void:
	# Hedges and flower beds along the main walk, lanterns at the forks.
	for z: float in [44.0, 32.0, 20.0, -11.0, -17.0]:
		for sx: float in [-1.0, 1.0]:
			planter(Vector3(sx * 4.4, 0.1, z), 2.4, PI / 2)
	for a in 8:
		var ang := a * TAU / 8.0 + 0.39
		planter(Vector3(cos(ang) * 10.6, 0.1, sin(ang) * 10.6), 2.2, -ang + PI / 2)
	signpost(Vector3(3.6, 0.1, 8.6), [["Red Dorm", PI], ["Yellow Dorm", 0.0], ["Main Hall", PI / 2]])
	signpost(Vector3(-3.6, 0.1, 40.0), [["Old Dorm", PI], ["Beach", 0.0], ["Ferry", -PI / 2]])
	signpost(Vector3(16.6, 0.1, -1.4), [["Duel Field", -PI / 2], ["Lighthouse", -PI / 2 + 0.5], ["Practice Fields", PI / 2]])
	signpost(Vector3(-27.6, 0.1, 3.6), [["Blue Dorm", PI / 2], ["Plaza", 0.0]])
	# Dorm colors on flags by each door, banners at the school steps.
	var flag_at := {"dorm_red": Color("d9342b"), "dorm_yellow": Color("f2c230"), "dorm_blue": Color("2f6fe0"), "academy_main": Color("ffe9a8")}
	var doors: Dictionary = city.get_meta("doors", {})
	for dk in doors:
		var d: Vector3 = doors[dk][0]
		var out: Vector3 = doors[dk][1]
		var side := out.cross(Vector3.UP)
		for s: float in [-1.0, 1.0]:
			var fp: Vector3 = d + out * 1.4 + side * s * (2.4 if dk != "academy_main" else 4.2)
			_cyl(0.05, 0.06, 4.6, fp + Vector3(0, 2.3, 0), _m(Color(0.85, 0.85, 0.88), 0.3, 0.7))
			var fl := _box(Vector3(1.3, 0.8, 0.02), fp + Vector3(0, 4.0, 0) + side * 0.7, _m(flag_at.get(dk, Color.WHITE), 0.8))
			fl.rotation.y = atan2(side.x, side.z) + PI / 2
			fl.set_meta("sway", s)
			_waves.append(fl)
			_solid(0.1, 2.0, fp)
	# Picnic blankets on the plaza lawn, a ball and boards on the beach.
	for b in [[Vector3(-14.0, 0.1, 22.0), Color("ff6b6b")], [Vector3(13.0, 0.1, 12.0), Color("5ac8ff")], [Vector3(-18.0, 0.1, -6.0), Color("ffd166")]]:
		var bl := _box(Vector3(2.4, 0.02, 1.8), (b[0] as Vector3) + Vector3(0, 0.04, 0), _m(b[1], 0.95))
		bl.rotation.y = 0.4
		_cyl(0.22, 0.18, 0.2, (b[0] as Vector3) + Vector3(0.5, 0.15, 0.2), _m(Color(0.7, 0.5, 0.3), 0.9))
	_ball(0.3, Vector3(45.0, 0.42, 44.0), _m(Color("ff5a5a"), 0.5))
	for i in 3:
		var sb := _box(Vector3(0.5, 2.0, 0.08), Vector3(53.0 + i * 0.7, 1.05, 45.0), _m([Color("5ac8ff"), Color("ffd166"), Color("ff8ad4")][i], 0.4))
		sb.rotation.x = -0.22
	# Sailboats out on the water.
	for i in 4:
		var bp := Vector3(-120.0 + i * 85.0, -0.4, 120.0 + (i % 2) * 40.0)
		var boat := Node3D.new()
		boat.position = bp
		add_child(boat)
		_box(Vector3(5.0, 1.0, 1.8), Vector3(0, 0.3, 0), _m(Color(0.95, 0.95, 0.95), 0.6), boat)
		_cyl(0.08, 0.08, 7.0, Vector3(0, 4.0, 0), _m(Color(0.5, 0.4, 0.3)), boat)
		var sail := _cyl(0.0, 2.6, 6.0, Vector3(1.0, 4.2, 0), _m(Color(1, 1, 1), 0.9), boat, 3)
		sail.scale = Vector3(1, 1, 0.08)
		boat.set_meta("boat", i)
		_waves.append(boat)
	# Birds, butterflies, a cat that lives at the Red dorm.
	gulls(Vector3(20, 26, 50), 6)
	flock(Vector3(6.0, 0.14, 4.0), 6, Color(0.92, 0.92, 0.92))
	flock(Vector3(42.0, 0.22, 52.0), 5, Color(0.92, 0.92, 0.92))
	butterflies(Vector3(-4.4, 1.0, 32.0), 4)
	butterflies(Vector3(8.0, 1.0, -8.0), 4)
	butterflies(Vector3(-14.0, 1.0, 22.0), 3)
	cat(Vector3(-36.6, 0.1, 5.0), 1.2, Color(0.75, 0.6, 0.4), "pharaoh")
	# Students between classes.
	chat_pair(Vector3(-6.0, 0.1, 14.0), 0.5, "student_girl", "student_boy", "yellow", "red")
	chat_pair(Vector3(6.5, 0.1, -13.5), -0.9, "stylish_woman", "street_duelist", "blue", "blue")
	chat_pair(Vector3(24.0, 0.1, 20.5), 2.0, "student_boy", "student_girl", "red", "yellow")
	chat_pair(Vector3(-30.0, 0.1, 31.0), 0.0, "street_duelist", "student_boy", "red", "red")


# ------------------------------------------------------------------ every frame

func _process(delta: float) -> void:
	_t += delta
	var pp: Vector3 = scene._player.global_position
	var outside: bool = scene._inside == ""
	var night: bool = city.tod == "night"
	# Clouds drift; they pick up the color of the hour.
	var cm: StandardMaterial3D = get_meta("cloud_mat")
	var want := Color(1, 1, 1, 0.85) if city.tod == "day" else (Color(1.0, 0.72, 0.6, 0.8) if city.tod == "sunset" else Color(0.22, 0.24, 0.36, 0.7))
	cm.albedo_color = cm.albedo_color.lerp(want, clampf(delta * 1.5, 0.0, 1.0))
	for c in _clouds:
		var n: Node3D = c[0]
		n.position.x += float(c[1]) * delta
		if n.position.x > 280.0:
			n.position.x = -280.0
	for h in _halos:
		(h[0] as Sprite3D).visible = is_instance_valid(h[1]) and bool(h[1].get_meta("want", true)) and city.tod != "day"
	# Flags, bunting, tails and boats.
	for w in _waves:
		var n: Node3D = w
		if n.has_meta("sway"):
			n.rotation.z = sin(_t * 2.2 + float(n.get_meta("sway"))) * 0.14
		elif n.has_meta("tail"):
			n.rotation.z = 0.7 + sin(_t * 1.6) * 0.35
		elif n.has_meta("boat"):
			n.position.x += delta * 1.4
			n.rotation.z = sin(_t * 0.8 + int(n.get_meta("boat"))) * 0.05
			if n.position.x > 220.0:
				n.position.x = -220.0
	_birds(delta, pp)
	# Chatting pairs trade turns.
	for pr in _pairs:
		pr[2] = float(pr[2]) - delta
		if float(pr[2]) <= 0.0:
			pr[2] = randf_range(3.5, 6.5)
			pr[3] = 1 - int(pr[3])
			(pr[0] as RoamFigure).speak(int(pr[3]) == 0)
			(pr[1] as RoamFigure).speak(int(pr[3]) == 1)
			if randf() < 0.3:
				(pr[int(pr[3])] as RoamFigure).do_nod()
	# Things you were asked to find.
	for it in _items.duplicate():
		var n: Node3D = it[0]
		n.rotation.y = _t * 1.5
		n.position.y = 0.5 + sin(_t * 2.0) * 0.1
		if outside and Vector2(pp.x - n.position.x, pp.z - n.position.z).length() < 1.3:
			var e: Dictionary = it[1]
			errands[e["id"]] = 2
			_save()
			_items.erase(it)
			n.queue_free()
			Sfx.play("pickup", -3.0)
			Router.toast(Loc.t("You found %s. Take it back.") % Loc.t(str(e["thing"])))
			if scene.extras:
				scene.extras.clear_waypoint()
	# Fountains start splashing once their sound is ready.
	for a in _water:
		var ap: AudioStreamPlayer3D = a
		if not ap.playing and Sfx.stream("water") != null:
			ap.stream = Sfx.stream("water")
			ap.play()
	# The sounds of the place, now and then.
	_amb_t -= delta
	if _amb_t <= 0.0 and outside:
		_amb_t = randf_range(2.5, 7.0)
		if night:
			Sfx.play("cricket", -20.0, randf_range(0.95, 1.05))
		elif key == "academy":
			Sfx.play(["gull", "chirp", "chirp2", "wave", "wave"][randi() % 5], -17.0, randf_range(0.9, 1.1))
		else:
			Sfx.play(["chirp", "chirp2", "horn", "chirp"][randi() % 4], -20.0, randf_range(0.9, 1.1))


func _birds(delta: float, pp: Vector3) -> void:
	for fl in _flocks:
		var near := Vector2(pp.x - (fl["home"] as Vector3).x, pp.z - (fl["home"] as Vector3).z).length()
		fl["t"] = float(fl["t"]) + delta
		if int(fl["state"]) == 0 and near < 4.2 and scene._inside == "":
			fl["state"] = 1
			fl["t"] = 0.0
			Sfx.play("flutter", -5.0)
		elif int(fl["state"]) == 1 and float(fl["t"]) > 9.0 and near > 9.0:
			fl["state"] = 2
			fl["t"] = 0.0
		elif int(fl["state"]) == 2 and float(fl["t"]) > 2.5:
			fl["state"] = 0
		for b in fl["birds"]:
			var n: Node3D = b["n"]
			var home: Vector3 = b["home"]
			var wings: Array = b["wings"]
			match int(fl["state"]):
				0:
					# Pecking about.
					for w in wings:
						(w as Node3D).visible = false
					n.position = home
					var peck := sin(_t * 3.0 + float(b["ph"]))
					n.rotation.x = maxf(0.0, peck) * 0.5
					if peck < -0.98:
						n.rotation.y += 0.3
				1, 2:
					var tt := float(fl["t"])
					var up := Vector3(0, 9.0, 0) + (b["dir"] as Vector3) * 9.0
					var orbit := Vector3(cos(_t * 0.9 + float(b["ph"])), 0, sin(_t * 0.9 + float(b["ph"]))) * 4.0
					var target := home + up + orbit
					if int(fl["state"]) == 2:
						target = home
					n.position = n.position.lerp(target, clampf(delta * (1.6 if int(fl["state"]) == 1 else 1.3), 0.0, 1.0))
					n.rotation.x = 0.0
					var vel := target - n.position
					if Vector2(vel.x, vel.z).length() > 0.2:
						n.rotation.y = atan2(vel.x, vel.z)
					for wi in wings.size():
						var w: Node3D = wings[wi]
						w.visible = true
						w.rotation.z = sin(_t * 22.0 + float(b["ph"])) * 0.9 * (1.0 if wi == 0 else -1.0)
					if tt > 0.0:
						pass
	for g in _gulls:
		var n: Node3D = g["n"]
		var a := _t * float(g["sp"]) + float(g["ph"])
		var c: Vector3 = g["c"]
		n.position = c + Vector3(cos(a) * float(g["r"]), sin(a * 0.7) * 2.0, sin(a) * float(g["r"]))
		n.rotation.y = -a
		var wings: Array = g["wings"]
		for wi in wings.size():
			(wings[wi] as Node3D).rotation.z = sin(_t * 5.0 + float(g["ph"])) * 0.45 * (1.0 if wi == 0 else -1.0)
	for f in _flutter:
		var n: Node3D = f["n"]
		var ph := float(f["ph"])
		var c: Vector3 = f["c"]
		n.position = c + Vector3(sin(_t * 0.7 + ph) * 2.2, sin(_t * 1.9 + ph) * 0.4, cos(_t * 0.5 + ph * 1.7) * 2.2)
		n.rotation.y = _t * 0.7 + ph
		var wings: Array = f["wings"]
		for wi in wings.size():
			(wings[wi] as Node3D).rotation.z = sin(_t * 18.0 + ph) * 1.0 * (1.0 if wi == 0 else -1.0)
