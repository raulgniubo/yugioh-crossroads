class_name ShopInterior
extends RefCounted
## The inside of Kame Game. Built far away from the streets; you step in through the shop door.

const AT := Vector3(400, 0, 400)
const HALF := Vector2(7.0, 5.0)
const HEIGHT := 4.2


static func build(city: CityBuilder) -> void:
	var o := AT
	var wood := city.mat(Color(0.5, 0.36, 0.24), 0.75)
	var wall := city.mat(Color(0.92, 0.86, 0.74), 0.9)
	var trim := city.mat(Color(0.32, 0.2, 0.13), 0.7)
	city.box(Vector3(HALF.x * 2 + 0.6, 0.3, HALF.y * 2 + 0.6), o + Vector3(0, -0.15, 0), wood)
	# Plank lines on the floor
	for i in range(-6, 7):
		city.box(Vector3(0.03, 0.01, HALF.y * 2), o + Vector3(i * 1.0 + 0.5, 0.006, 0), trim, false)
	city.box(Vector3(HALF.x * 2 + 0.6, 0.3, HALF.y * 2 + 0.6), o + Vector3(0, HEIGHT + 0.15, 0), city.mat(Color(0.86, 0.82, 0.74), 0.95), false)
	for sx in [-1, 1]:
		city.box(Vector3(0.3, HEIGHT, HALF.y * 2 + 0.6), o + Vector3(sx * (HALF.x + 0.15), HEIGHT / 2.0, 0), wall)
		city.box(Vector3(0.08, 0.9, HALF.y * 2), o + Vector3(sx * (HALF.x - 0.03), 0.45, 0), trim, false)
	for sz in [-1, 1]:
		city.box(Vector3(HALF.x * 2 + 0.6, HEIGHT, 0.3), o + Vector3(0, HEIGHT / 2.0, sz * (HALF.y + 0.15)), wall)
		city.box(Vector3(HALF.x * 2, 0.9, 0.08), o + Vector3(0, 0.45, sz * (HALF.y - 0.03)), trim, false)
	# Ceiling beams and warm lights
	for i in range(-2, 3):
		city.box(Vector3(0.25, 0.25, HALF.y * 2), o + Vector3(i * 3.0, HEIGHT - 0.13, 0), trim, false)
	for p in [Vector3(-4, 3.4, -1.5), Vector3(4, 3.4, -1.5), Vector3(0, 3.4, 2.4), Vector3(0, 3.2, -3.4)]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.86, 0.66)
		l.light_energy = 2.2
		l.omni_range = 9.0
		l.shadow_enabled = false
		l.position = o + p
		city.add_child(l)
		var bulb := city.cyl(0.22, 0.34, 0.2, o + p + Vector3(0, 0.35, 0), city.glow_mat(Color(1.0, 0.86, 0.6), 2.4))
		bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Furniture
	city.collide(city.prop("shop_counter", o + Vector3(0, 0, -2.9), 0.0, 4.8), 0.95)
	for x in [-5.6, -3.0, 3.0, 5.6]:
		city.collide(city.prop("shop_shelf", o + Vector3(x, 0, -4.45), 0.0, 2.7, true))
	for z in [-2.2, 0.6]:
		city.collide(city.prop("shop_shelf", o + Vector3(-6.45, 0, z), PI / 2, 2.7, true))
		city.collide(city.prop("shop_shelf", o + Vector3(6.45, 0, z), -PI / 2, 2.7, true))
	city.collide(city.prop("card_rack", o + Vector3(-2.6, 0, -0.4), 0.4, 1.9, true), 0.7)
	city.collide(city.prop("card_rack", o + Vector3(2.7, 0, 0.2), -0.6, 1.9, true), 0.7)
	var dt0 := city.prop("duel_table", o + Vector3(-3.9, 0, 2.9), 0.0, 2.5)
	city.collide(dt0, 0.75)
	city.collide(city.prop("duel_table", o + Vector3(4.0, 0, 2.9), 0.0, 2.5), 0.75)
	city.collide(city.prop("arcade_cabinet", o + Vector3(6.35, 0, 3.6), -PI / 2, 1.9, true))
	city.collide(city.prop("vending", o + Vector3(-6.45, 0, -4.2), PI / 2, 1.95, true))
	# Mirror (change your look) and the door out
	var frame := city.box(Vector3(0.12, 2.3, 1.3), o + Vector3(-6.92, 1.35, 3.4), trim, false)
	frame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var glass := city.mat(Color(0.75, 0.88, 0.95), 0.04, 0.9)
	glass.emission_enabled = true
	glass.emission = Color(0.55, 0.75, 0.9)
	glass.emission_energy_multiplier = 0.25
	city.box(Vector3(0.05, 2.1, 1.1), o + Vector3(-6.85, 1.35, 3.4), glass, false)
	city.exit_door(o + Vector3(0, 0, HALF.y))
	MoreRooms.kame(city, o, HALF, HEIGHT)
	_sign(city, "KAME GAME", o + Vector3(0, 3.35, -HALF.y + 0.12), 0.0, Color("ffd166"), 130)
	_sign(city, "NEW BOOSTERS IN STOCK", o + Vector3(4.3, 3.3, -HALF.y + 0.12), 0.0, Color("ff8ac0"), 54)
	_sign(city, "DUEL TABLES  ·  FREE PLAY", o + Vector3(HALF.x - 0.12, 3.2, 2.6), -PI / 2, Color("7cc4ff"), 54)
	_sign(city, "FITTING MIRROR", o + Vector3(-HALF.x + 0.12, 2.9, 3.4), PI / 2, Color("b8f0ff"), 46)
	_dress(city, o)


## Everything that makes it feel like a shop people actually hang out in.
static func _dress(city: CityBuilder, o: Vector3) -> void:
	var trim := city.mat(Color(0.32, 0.2, 0.13), 0.7)
	var brass := city.mat(Color(0.82, 0.66, 0.3), 0.35, 0.8)
	# A big rug in the middle of the floor.
	city.box(Vector3(5.6, 0.02, 3.4), o + Vector3(0.2, 0.012, 1.5), city.mat(Color(0.45, 0.12, 0.14), 0.95), false)
	city.box(Vector3(5.2, 0.022, 3.0), o + Vector3(0.2, 0.014, 1.5), city.mat(Color(0.62, 0.2, 0.18), 0.95), false)
	city.box(Vector3(4.4, 0.024, 2.2), o + Vector3(0.2, 0.016, 1.5), city.mat(Color(0.5, 0.14, 0.15), 0.95), false)
	for k in 4:
		var c := o + Vector3(0.2 + (2.35 if k % 2 == 0 else -2.35), 0.02, 1.5 + (1.25 if k < 2 else -1.25))
		city.cyl(0.16, 0.16, 0.012, c, city.mat(Color(0.85, 0.7, 0.36), 0.8))
	# The pack wall behind the counter: this season's boosters, framed and lit.
	var keys := ["dm", "gx", "5ds", "zexal", "vault"]
	for i in 5:
		var px := -1.72 + i * 0.86
		var at := o + Vector3(px, 2.25, -HALF.y + 0.06)
		city.box(Vector3(0.72, 1.02, 0.05), at, brass, false)
		var path := "res://assets/ui/packs/%s.jpg" % keys[i]
		if ResourceLoader.exists(path):
			var pm := StandardMaterial3D.new()
			pm.albedo_texture = load(path)
			pm.emission_enabled = true
			pm.emission_texture = pm.albedo_texture
			pm.emission_energy_multiplier = 0.45
			pm.roughness = 0.25
			var q := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(0.64, 0.94)
			q.mesh = qm
			q.material_override = pm
			q.position = at + Vector3(0, 0, 0.03)
			city.add_child(q)
		city.box(Vector3(0.3, 0.06, 0.12), at + Vector3(0, 0.62, 0.1), city.glow_mat(Color(1.0, 0.92, 0.75), 2.2), false)
	# A glass case with the three best cards in the shop, turning slowly under a spotlight.
	var case_at := o + Vector3(-0.9, 0, 0.95)
	city.box(Vector3(1.5, 0.9, 0.7), case_at + Vector3(0, 0.45, 0), trim)
	city.box(Vector3(1.56, 0.06, 0.76), case_at + Vector3(0, 0.93, 0), brass, false)
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.7, 0.9, 1.0, 0.16)
	glass.roughness = 0.05
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	city.box(Vector3(1.5, 0.75, 0.7), case_at + Vector3(0, 1.33, 0), glass, false)
	city.box(Vector3(1.56, 0.05, 0.76), case_at + Vector3(0, 1.72, 0), brass, false)
	var best: Array = []
	for era in ["Duel Monsters", "GX", "5D's"]:
		var pool: Array = Collection.pool(era).duplicate()
		pool.sort_custom(func(a, b): return CardData.rarity(a) * 10000 + int(CardData.get_card(a).get("atk", 0)) > CardData.rarity(b) * 10000 + int(CardData.get_card(b).get("atk", 0)))
		if not pool.is_empty():
			best.append(pool[0])
	for i in best.size():
		var holder := Node3D.new()
		holder.position = case_at + Vector3(-0.45 + i * 0.45, 1.33, 0)
		city.add_child(holder)
		for side in 2:
			var cm := StandardMaterial3D.new()
			cm.albedo_texture = Cards.get_face(best[i]) if side == 0 else Cards.get_back()
			cm.emission_enabled = true
			cm.emission_texture = cm.albedo_texture
			cm.emission_energy_multiplier = 0.35
			var card := MeshInstance3D.new()
			var cq := QuadMesh.new()
			cq.size = Vector2(0.34, 0.5)
			card.mesh = cq
			card.material_override = cm
			card.rotation.y = PI if side == 1 else 0.0
			card.position.z = 0.002 if side == 0 else -0.002
			holder.add_child(card)
		var spin := holder.create_tween().set_loops()
		spin.tween_property(holder, "rotation:y", TAU, 9.0 + i * 1.5).from(0.0)
	var case_light := SpotLight3D.new()
	case_light.light_color = Color(1.0, 0.95, 0.85)
	case_light.light_energy = 6.0
	case_light.spot_range = 4.0
	case_light.spot_angle = 30.0
	case_light.position = case_at + Vector3(0, 3.6, 0)
	case_light.rotation.x = -PI / 2
	city.add_child(case_light)
	# A little hanging board over the case, lettered on both faces.
	city.box(Vector3(1.5, 0.34, 0.05), case_at + Vector3(0, 2.02, 0), city.mat(Color(0.14, 0.09, 0.06), 0.6), false)
	for wire: float in [-0.6, 0.6]:
		city.box(Vector3(0.012, HEIGHT - 2.19, 0.012), case_at + Vector3(wire, 2.19 + (HEIGHT - 2.19) / 2.0, 0), brass, false)
	_sign(city, "TODAY'S BEST", case_at + Vector3(0, 2.02, 0.03), 0.0, Color("ffd166"), 30, true)
	_sign(city, "TODAY'S BEST", case_at + Vector3(0, 2.02, -0.03), PI, Color("ffd166"), 30, true)
	# Pennants strung across the ceiling.
	var cols := [Color("d9342b"), Color("f2c230"), Color("2f6fe0"), Color("2aa46a"), Color("f2f2f2")]
	for row: float in [-1.6, 1.9]:
		city.box(Vector3(HALF.x * 2 - 0.4, 0.015, 0.015), o + Vector3(0, 3.72, row), trim, false)
		for i in 17:
			var flag := city.box(Vector3(0.36, 0.36, 0.012), o + Vector3(-6.4 + i * 0.8, 3.52 - absf(8.0 - i) * 0.006, row), city.mat(cols[i % cols.size()], 0.8), false)
			flag.rotation.z = PI / 4
			flag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# A window onto the street on one side of the door, the notice board on the other.
	city.box(Vector3(2.7, 1.7, 0.1), o + Vector3(3.7, 1.95, HALF.y - 0.04), trim, false)
	city.box(Vector3(2.5, 1.5, 0.06), o + Vector3(3.7, 1.95, HALF.y - 0.1), city.glow_mat(Color(0.62, 0.78, 1.0), 0.8), false)
	city.box(Vector3(0.06, 1.5, 0.08), o + Vector3(3.7, 1.95, HALF.y - 0.12), trim, false)
	city.box(Vector3(2.5, 0.06, 0.08), o + Vector3(3.7, 1.95, HALF.y - 0.12), trim, false)
	city.box(Vector3(2.4, 1.5, 0.06), o + Vector3(-3.5, 1.95, HALF.y - 0.06), city.mat(Color(0.62, 0.46, 0.3), 0.95), false)
	city.box(Vector3(2.56, 1.66, 0.04), o + Vector3(-3.5, 1.95, HALF.y - 0.03), trim, false)
	var notes := [Color("fff3a8"), Color("ffc9d6"), Color("c9ecff"), Color("d8ffc9"), Color("fff3a8"), Color("ffffff")]
	for i in 6:
		var note := city.box(Vector3(0.42, 0.5, 0.012), o + Vector3(-4.35 + (i % 3) * 0.82, 2.28 - (i / 3) * 0.66, HALF.y - 0.1), city.mat(notes[i], 0.9), false)
		note.rotation.z = (i * 37 % 9 - 4) * 0.03
		city.box(Vector3(0.04, 0.04, 0.02), o + Vector3(-4.35 + (i % 3) * 0.82, 2.48 - (i / 3) * 0.66, HALF.y - 0.115), city.mat(Color("d9342b"), 0.5), false)
	_sign(city, "WEEKLY TOURNAMENT  ·  FRIDAYS", o + Vector3(-3.5, 2.95, HALF.y - 0.12), PI, Color("ffd166"), 36)
	# Plants in the corners and a bench by the window.
	for c2 in [Vector3(-6.3, 0, 4.3), Vector3(6.3, 0, -4.3)]:
		city.cyl(0.3, 0.22, 0.5, o + c2 + Vector3(0, 0.25, 0), city.mat(Color(0.7, 0.42, 0.28), 0.8))
		for k in 5:
			var leaf := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.26
			sm.height = 0.9
			leaf.mesh = sm
			leaf.material_override = city.mat(Color(0.22, 0.5, 0.26).lerp(Color(0.36, 0.64, 0.3), k / 4.0), 0.9)
			leaf.position = o + c2 + Vector3(cos(k * 1.26) * 0.2, 0.9 + (k % 2) * 0.16, sin(k * 1.26) * 0.2)
			leaf.rotation = Vector3(cos(k * 1.26) * 0.5, 0, -sin(k * 1.26) * 0.5)
			city.add_child(leaf)
	var bench := city.prop("bench", o + Vector3(3.7, 0, 4.35), PI, 2.0)
	if bench:
		city.collide(bench, 0.8)
	# The trader's binder stand by the right-hand rack.
	city.box(Vector3(0.9, 0.95, 0.5), o + Vector3(4.55, 0.475, -1.45), trim)
	var binder := city.box(Vector3(0.7, 0.04, 0.42), o + Vector3(4.55, 0.98, -1.45), city.mat(Color(0.12, 0.2, 0.42), 0.6), false)
	binder.rotation.x = -0.25
	for k in 6:
		var slot := city.box(Vector3(0.18, 0.006, 0.14), o + Vector3(4.33 + (k % 3) * 0.22, 1.012 + (0.02 if k < 3 else -0.02), -1.53 + (k / 3) * 0.17), city.glow_mat([Color("ffd166"), Color("7cc4ff"), Color("ff7ad9")][k % 3], 0.5), false)
		slot.rotation.x = -0.25
	# The shop cat, asleep on the end of the counter.
	var fur := city.mat(Color(0.9, 0.62, 0.3), 0.95)
	var cat := o + Vector3(-1.75, 1.08, -2.85)
	var body := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.2
	bm.height = 0.26
	body.mesh = bm
	body.material_override = fur
	body.scale = Vector3(1.5, 1.0, 1.0)
	body.position = cat
	city.add_child(body)
	var breathe := body.create_tween().set_loops()
	breathe.tween_property(body, "scale:y", 1.12, 1.4).set_trans(Tween.TRANS_SINE)
	breathe.tween_property(body, "scale:y", 1.0, 1.4).set_trans(Tween.TRANS_SINE)
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.11
	hm.height = 0.2
	head.mesh = hm
	head.material_override = fur
	head.position = cat + Vector3(0.27, 0.0, 0.08)
	city.add_child(head)
	for e: float in [-1.0, 1.0]:
		var ear := city.cyl(0.0, 0.04, 0.08, cat + Vector3(0.27 + e * 0.06, 0.12, 0.08), fur, null, 4)
		ear.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tail := city.cyl(0.03, 0.035, 0.36, cat + Vector3(-0.3, -0.06, 0.12), fur)
	tail.rotation = Vector3(PI / 2, 0, 0.9)


static func _sign(city: CityBuilder, text: String, pos: Vector3, rot: float, color: Color, size: int, one_face := false) -> void:
	var l := Label3D.new()
	l.double_sided = not one_face
	l.text = text
	l.font = load("res://assets/fonts/Rajdhani-SemiBold.ttf")
	l.font_size = size
	l.pixel_size = 0.006
	l.outline_size = 8
	l.modulate = color * 1.5
	l.outline_modulate = Color(0, 0, 0, 0.7)
	l.position = pos
	l.rotation.y = rot
	city.add_child(l)
