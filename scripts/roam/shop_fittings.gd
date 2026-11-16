class_name ShopFittings
## What a card shop sells from: the glass counter and the spinner rack, built here so the cards
## in them are REAL cards, sharp, from the player's own card folder (the bought-in models had
## cards painted on as a blur). Twenty different cards go round, so a shop full of them is
## twenty small draws.

const FACES := 20
static var _faces: Array = []            # [StandardMaterial3D]
static var _folder := ""
static var _card_mesh: QuadMesh
static var _back_mesh: BoxMesh
static var _back_mat: StandardMaterial3D


## The cards on show: the same twenty every time, picked across the whole card list.
static func faces() -> Array:
	if _folder != Settings.card_folder or _faces.is_empty():
		_folder = Settings.card_folder
		_faces = []
		var ids: Array = Collection.all_cards().duplicate()
		ids.sort()
		var monsters: Array = ids.filter(func(id): return CardData.get_card(id).get("kind", "") == "monster")
		if monsters.size() >= FACES:
			ids = monsters
		var rng := RandomNumberGenerator.new()
		rng.seed = 2026
		var picked := {}
		var tries := 0
		while picked.size() < mini(FACES, ids.size()) and tries < 400:
			picked[ids[rng.randi() % ids.size()]] = true
			tries += 1
		for id in picked:
			var m := StandardMaterial3D.new()
			m.albedo_texture = Cards.get_face(id)
			m.roughness = 0.35
			m.emission_enabled = true
			m.emission_texture = m.albedo_texture
			m.emission_energy_multiplier = 0.3
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			_faces.append(m)
	return _faces


## One card standing in a holder: a dark backing with the face a hair in front of it.
static func card(parent: Node3D, at: Vector3, basis: Basis, k: int, size := 1.0) -> void:
	if _card_mesh == null:
		_card_mesh = QuadMesh.new()
		_card_mesh.size = Vector2(0.2, 0.2915)
		_back_mesh = BoxMesh.new()
		_back_mesh.size = Vector3(0.212, 0.303, 0.008)
		_back_mat = StandardMaterial3D.new()
		_back_mat.albedo_color = Color(0.1, 0.09, 0.1)
		_back_mat.roughness = 0.6
	var f := faces()
	if f.is_empty():
		return
	var b := basis.scaled(Vector3(size, size, size))
	var back := MeshInstance3D.new()
	back.mesh = _back_mesh
	back.material_override = _back_mat
	back.transform = Transform3D(b, at)
	back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(back)
	var face := MeshInstance3D.new()
	face.mesh = _card_mesh
	face.material_override = f[posmod(k, f.size())]
	face.transform = Transform3D(b, at + basis.z * 0.006 * size)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(face)


static func _solid(city: CityBuilder, h: Node3D, size: Vector3, lpos: Vector3) -> void:
	if not city.make_solid:
		return
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	body.add_child(cs)
	body.position = lpos
	h.add_child(body)


## A glass display counter, `w` wide, its front toward +Z of `yaw`: two sloping shelves of cards
## behind glass, a wooden top at the staff end with the till on it, a card stand beside the till.
static func counter(city: CityBuilder, at: Vector3, yaw: float, w := 4.8) -> Node3D:
	var h := Node3D.new()
	h.position = at
	h.rotation.y = yaw
	city.add_child(h)
	var wood := city.surf("wood", Color(0.42, 0.27, 0.16), 0.9)
	var dark := city.mat(Color(0.2, 0.13, 0.08), 0.6)
	var steel := city.mat(Color(0.74, 0.76, 0.8), 0.3, 0.7)
	# The felt the cards lie on takes no shadows: the thin steel bars of the case and the cards a
	# few millimetres above it threw fine shadows on it that crawled as you moved (a flicker under
	# the cards). It is lit evenly instead, like a real lit display case.
	var felt := city.mat(Color(0.1, 0.16, 0.3), 0.95)
	felt.disable_receive_shadows = true
	felt.normal_enabled = false
	var d := 0.95
	var top := 1.05
	# The carcass: plinth, back, two ends, a floor of felt, the frame the glass sits in.
	city.round_box(Vector3(w, 0.12, d), Vector3(0, 0.06, 0), dark, 0.06, h)
	city.box(Vector3(w, top - 0.12, 0.06), Vector3(0, 0.12 + (top - 0.12) * 0.5, -d * 0.5 + 0.03), wood, false, h)
	for sx: float in [-1.0, 1.0]:
		city.round_box(Vector3(0.08, top - 0.12, d), Vector3(sx * (w * 0.5 - 0.04), 0.12 + (top - 0.12) * 0.5, 0), wood, 0.03, h)
	city.box(Vector3(w - 0.16, 0.03, d - 0.08), Vector3(0, 0.135, 0), felt, false, h)
	for y: float in [0.14, top]:
		city.box(Vector3(w, 0.035, 0.035), Vector3(0, y, d * 0.5 - 0.018), steel, false, h).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	city.box(Vector3(w, 0.035, 0.035), Vector3(0, top, -d * 0.5 + 0.08), steel, false, h).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var posts := maxi(2, int(round(w / 1.6)))
	for i in posts + 1:
		var x := -w * 0.5 + 0.018 + (w - 0.036) * i / float(posts)
		city.box(Vector3(0.035, top - 0.14, 0.035), Vector3(x, (top + 0.14) * 0.5, d * 0.5 - 0.018), steel, false, h).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		city.box(Vector3(0.035, 0.035, d - 0.1), Vector3(x, top, 0.015), steel, false, h).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Two shelves sloping toward the customer, each a row of cards leaning back on it.
	var k := 0
	var lean := Basis(Vector3.RIGHT, -0.95)
	for row in 2:
		var sy := 0.2 + row * 0.42
		var sz := 0.2 - row * 0.2
		var shelf := city.box(Vector3(w - 0.2, 0.02, 0.44), Vector3(0, sy + 0.1, sz), felt, false, h)
		shelf.rotation.x = 0.62
		var n := int((w - 0.3) / 0.26)
		for i in n:
			var cx := -(n - 1) * 0.13 + i * 0.26
			card(h, Vector3(cx, sy + 0.122, sz + 0.017), lean, k * 7 + row * 3)      # (a centimetre clear of the felt)
			k += 1
	# Glass over the front and the top.
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.75, 0.9, 1.0, 0.1)
	glass.roughness = 0.03
	glass.metallic = 0.2
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var gf := city.box(Vector3(w - 0.04, top - 0.16, 0.012), Vector3(0, (top + 0.14) * 0.5, d * 0.5 - 0.018), glass, false, h)
	gf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var gt := city.box(Vector3(w - 0.04, 0.012, d - 0.12), Vector3(0, top + 0.012, 0.03), glass, false, h)
	gt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The till on a wooden end of the top, and a stand with the card of the day beside it.
	var tx := -w * 0.5 + 0.75
	city.round_box(Vector3(1.3, 0.05, d - 0.06), Vector3(tx, top + 0.045, 0.0), wood, 0.05, h)
	var cream := city.mat(Color(0.86, 0.84, 0.78), 0.5)
	city.round_box(Vector3(0.62, 0.2, 0.52), Vector3(tx, top + 0.17, -0.05), cream, 0.05, h)
	var keys := city.round_box(Vector3(0.5, 0.05, 0.3), Vector3(tx, top + 0.3, 0.02), city.mat(Color(0.72, 0.7, 0.65), 0.5), 0.03, h)
	keys.rotation.x = 0.35
	for kx in 4:
		for kz in 3:
			var key := city.round_box(Vector3(0.07, 0.03, 0.05), Vector3(tx - 0.165 + kx * 0.11, top + 0.335 - kz * 0.028, -0.04 + kz * 0.075), city.mat(Color(0.95, 0.94, 0.9) if (kx + kz) % 4 != 0 else Color(0.9, 0.3, 0.25), 0.4), 0.012, h)
			key.rotation.x = 0.35
	city.round_box(Vector3(0.4, 0.26, 0.05), Vector3(tx, top + 0.5, -0.24), city.mat(Color(0.14, 0.15, 0.19), 0.4, 0.3), 0.02, h)
	var scr := city.box(Vector3(0.34, 0.2, 0.01), Vector3(tx, top + 0.5, -0.212), city.glow_mat(Color(0.5, 0.95, 1.0), 1.1), false, h)
	scr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	city.cyl(0.03, 0.03, 0.12, Vector3(tx, top + 0.32, -0.24), city.mat(Color(0.14, 0.15, 0.19), 0.4, 0.3), h, 8)
	card(h, Vector3(tx + 0.75, top + 0.2, 0.05), Basis(Vector3.RIGHT, -0.3), 5, 1.15)
	city.round_box(Vector3(0.28, 0.03, 0.14), Vector3(tx + 0.75, top + 0.035, 0.02), steel, 0.03, h)
	_solid(city, h, Vector3(w, 1.3, d), Vector3(0, 0.65, 0))
	return h


## A spinner rack: a pole on a round foot with four rings of card pockets all the way round and
## a knob on top. Every pocket holds a real card.
static func spinner(city: CityBuilder, at: Vector3, yaw: float, tall := 1.9) -> Node3D:
	var h := Node3D.new()
	h.position = at
	h.rotation.y = yaw
	city.add_child(h)
	var steel := city.mat(Color(0.8, 0.82, 0.86), 0.3, 0.8)
	var dark := city.mat(Color(0.16, 0.17, 0.2), 0.5, 0.4)
	city.cyl(0.3, 0.34, 0.05, Vector3(0, 0.025, 0), dark, h, 20)
	city.cyl(0.025, 0.025, tall, Vector3(0, tall * 0.5, 0), steel, h, 8)
	city.cyl(0.0, 0.05, 0.1, Vector3(0, tall + 0.05, 0), steel, h, 10)
	var tiers := 4
	var per := 8
	var r := 0.34
	for t in tiers:
		var y := 0.42 + t * (tall - 0.62) / float(tiers - 1)
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = r - 0.012
		tm.outer_radius = r + 0.012
		tm.rings = 24
		tm.ring_segments = 6
		ring.mesh = tm
		ring.material_override = steel
		ring.position = Vector3(0, y - 0.15, 0)
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		h.add_child(ring)
		for sp in 4:
			var arm := city.box(Vector3(r, 0.012, 0.012), Vector3(0, y - 0.15, 0), steel, false, h)
			arm.rotation.y = sp * PI * 0.5 + t * 0.4
			arm.position += Basis(Vector3.UP, arm.rotation.y) * Vector3(r * 0.5, 0, 0)
			arm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in per:
			var a := i * TAU / per + t * 0.39
			var out := Vector3(sin(a), 0, cos(a))
			var b := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, -0.16)
			card(h, out * (r + 0.02) + Vector3(0, y, 0), b, t * 5 + i * 3 + int(at.x * 3.0))
	_solid(city, h, Vector3(0.8, tall, 0.8), Vector3(0, tall * 0.5, 0))
	return h
