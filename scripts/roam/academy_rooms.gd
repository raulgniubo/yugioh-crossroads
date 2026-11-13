class_name AcademyRooms
## Duel Academy's rooms: the main hall (card shop, indoor duel arena, exam office) and the three
## dorms. The shells (floor, walls, lights, exit door) come from Interiors.build; this fills them.

const ROOMS := {
	"ac_hall": {"district": "academy", "door_of": "academy_main", "name": "Academy Main Hall", "area": "Card shop, duel arena and the exam office",
		"at": Vector3(400, 0, -400), "half": Vector2(15.0, 11.0), "height": 8.0, "label": "Enter the main building", "music": "shop",
		"floor": Color(0.78, 0.74, 0.66), "wall": Color(0.95, 0.91, 0.82), "trim": Color("e0b04a")},
	"dorm_red": {"district": "academy", "door_of": "dorm_red", "name": "Red Dorm", "area": "Common room, bedrooms upstairs",
		"at": Vector3(480, 0, -400), "half": Vector2(6.5, 7.4), "height": 6.2, "label": "Enter the Red Dorm", "music": "shop",
		"floor": Color(0.52, 0.36, 0.24), "wall": Color(0.9, 0.82, 0.7), "trim": Color("d9342b")},
	"dorm_yellow": {"district": "academy", "door_of": "dorm_yellow", "name": "Yellow Dorm", "area": "Study hall, kitchen, bedrooms upstairs",
		"at": Vector3(560, 0, -400), "half": Vector2(9.0, 8.8), "height": 6.3, "label": "Enter the Yellow Dorm", "music": "shop",
		"floor": Color(0.74, 0.6, 0.4), "wall": Color(0.98, 0.93, 0.74), "trim": Color("f2c230")},
	"dorm_blue": {"district": "academy", "door_of": "dorm_blue", "name": "Blue Dorm", "area": "The grand hall and the suites",
		"at": Vector3(640, 0, -400), "half": Vector2(12.5, 11.8), "height": 8.0, "label": "Enter the Blue Dorm", "music": "shop",
		"floor": Color(0.86, 0.87, 0.9), "wall": Color(0.93, 0.95, 0.99), "trim": Color("2f6fe0")},
}

const PEOPLE := {
	"ac_hall": [
		{"id": "ac_vendor", "char": "", "model": "shopkeeper", "name": "Academy Card Shop", "color": Color("ffd166"), "pos": Vector3(9.2, 0, -8.6), "face": 0.0, "shop": true,
			"chats": [["Welcome to the Academy card shop! Same packs as the mainland, same prices too.", "Packs, a ready-made deck, or a look at your own decks?"],
				["Exam week again. Everybody suddenly wants Traps.", "What can I get you?"]]},
		{"id": "ac_shop_kid", "char": "", "model": "student_boy", "dorm": "red", "name": "Red Dorm Student", "color": Color("d9342b"), "pos": Vector3(6.0, 0, -6.0), "face": -2.6,
			"wander": [[Vector3(6.0, 0, -6.0), 3.14], [Vector3(12.6, 0, -6.4), 3.14], [Vector3(13.0, 0, -2.0), 1.57]], "order": [1, 2, 1, 0],
			"chats": [["I've got exactly enough for one pack. One. This is the one."], ["The Beyond the Limit set has every Fusion monster. My wallet hates it."]]},
		{"id": "ac_proctor", "char": "", "model": "duelist_m3", "name": "Exam Proctor", "color": Color("c9a76a"), "pos": Vector3(9.5, 0, 5.4), "face": -1.57,
			"lines": ["The exam office. Class duels, the weekly exam and the tournament are all signed up here.", "Step up to the desk when you're ready."]},
		{"id": "ac_arena", "char": "", "model": "duelist_m4", "dorm": "yellow", "name": "Arena Champion", "color": Color("f2c230"), "pos": Vector3(-6.0, 0, -5.2), "face": 0.3,
			"lines": ["The indoor arena is for practice. Nobody is grading you here.", "...But I'm still not losing."],
			"duel": {"deck": "deck_machine", "difficulty": 2, "intro": "Arena rules. Winner keeps the stage."}},
		{"id": "ac_fan_a", "char": "", "model": "student_girl", "dorm": "blue", "name": "Spectator", "color": Color("2f6fe0"), "pos": Vector3(-12.2, 0, 2.3), "face": 3.3, "pose": "sit", "seat": false,
			"chats": [["I come here between classes just to watch."], ["Somebody summoned a ten-thousand ATK monster in here last week. The floor still has a mark."]]},
		{"id": "ac_fan_b", "char": "", "model": "street_duelist", "dorm": "red", "name": "Spectator", "color": Color("d9342b"), "pos": Vector3(-0.2, 0, 2.3), "face": 2.95, "pose": "sit", "seat": false,
			"chats": [["Go on, challenge the champion. I want to see a good duel."]]},
	],
	"dorm_red": [
		{"id": "red_head", "char": "", "model": "duelist_m3", "name": "Red Dorm Head", "color": Color("d9342b"), "pos": Vector3(-3.0, 0, -2.6), "face": 0.6,
			"chats": [["Welcome to the Red dorm. The roof leaks, the food is great and nobody here gives up.", "Dinner is fried shrimp. Again. Nobody has ever complained."],
				["Grades are a number. A duelist is a heart. Write that down."]]},
		{"id": "red_bunk", "char": "", "model": "student_boy", "dorm": "red", "name": "Red Dorm Roommate", "color": Color("d9342b"), "pos": Vector3(1.4, 0, -0.4), "face": -2.4, "pose": "rest",
			"lines": ["Shh, I'm planning my deck for the exam. ...Okay, I'm napping. Same thing.", "Want to duel? Loser does the dishes."],
			"duel": {"deck": "deck_warrior", "difficulty": 1, "intro": "Dish duty is on the line!"}},
	],
	"dorm_yellow": [
		{"id": "yel_cook", "char": "", "model": "shopkeeper", "name": "Dorm Cook", "color": Color("f2c230"), "pos": Vector3(5.6, 0, -6.6), "face": 0.0,
			"chats": [["Curry's on! Yellow dorm curry wins more duels than any card.", "Second helpings are free if you win a duel in the study hall."]]},
		{"id": "yel_study", "char": "", "model": "student_girl", "dorm": "yellow", "name": "Yellow Dorm Scholar", "color": Color("f2c230"), "pos": Vector3(-4.6, 0, -0.68), "face": 3.1416, "pose": "sit", "seat": false,
			"lines": ["I've charted the odds for every pack in the shop. Want to see my spreadsheet?", "No? A duel, then. I'll show you the numbers in action."],
			"duel": {"deck": "deck_arcane", "difficulty": 2, "intro": "Probability is on my side."}},
		{"id": "yel_reader", "char": "", "model": "student_boy", "dorm": "yellow", "name": "Yellow Dorm Student", "color": Color("f2c230"), "pos": Vector3(-1.0, 0, 3.32), "face": 3.1416, "pose": "sit", "seat": false,
			"chats": [["The library closes at nine, so I moved in here.", "The Blue dorm has a chandelier. We have a chalkboard. We use the chalkboard."]]},
	],
	"dorm_blue": [
		{"id": "blue_butler", "char": "", "model": "office_worker", "name": "Dorm Steward", "color": Color("2f6fe0"), "pos": Vector3(0, 0, 5.4), "face": 3.14,
			"chats": [["Welcome to the Blue dorm. Please wipe your feet. Twice.", "The grand hall is open to visitors until curfew."]]},
		{"id": "blue_queen", "char": "", "model": "stylish_woman", "dorm": "blue", "name": "Blue Dorm Senior", "color": Color("2f6fe0"), "pos": Vector3(-7.7, 0, 1.52), "face": 3.1416, "pose": "sit", "seat": false,
			"lines": ["A visitor from the lower dorms. How brave.", "Shall we see if you belong in this hall?"],
			"duel": {"deck": "deck_wind", "difficulty": 2, "intro": "Elegance first."}},
		{"id": "blue_elite", "char": "blue_student", "name": "Blue Dorm Elite", "color": Color("2f6fe0"), "pos": Vector3(7.6, 0, -3.0), "face": -1.0,
			"lines": ["Top of the ranking table. Third year running.", "You can try. Everyone tries."],
			"duel": {"deck": "deck_dragon", "difficulty": 3, "intro": "Know your place."}},
		{"id": "blue_piano", "char": "", "model": "student_girl", "dorm": "blue", "name": "Blue Dorm Student", "color": Color("2f6fe0"), "pos": Vector3(-9.4, 0, -5.0), "face": 3.1416,
			"chats": [["Nobody actually plays the piano. It's just here to look expensive."]]},
	],
}


static func dress(city: CityBuilder, key: String, o: Vector3, half: Vector2, hgt: float) -> void:
	match key:
		"ac_hall": _hall(city, o, half, hgt)
		"dorm_red": _red(city, o, half, hgt)
		"dorm_yellow": _yellow(city, o, half, hgt)
		"dorm_blue": _blue(city, o, half, hgt)


static func _sign(city: CityBuilder, text: String, pos: Vector3, rot: float, color: Color, size: int) -> void:
	var l := Label3D.new()
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


static func _block(city: CityBuilder, size: Vector3, pos: Vector3) -> void:
	if not city.make_solid:
		return
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	body.add_child(cs)
	body.position = pos
	city.add_child(body)


static func _light(city: CityBuilder, at: Vector3, col: Color, energy := 2.0, rng := 9.0) -> void:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.shadow_enabled = false
	l.position = at
	city.add_child(l)


static func _ball(city: CityBuilder, at: Vector3, r: float, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	mi.material_override = m
	mi.position = at
	city.add_child(mi)
	return mi


static func _plant(city: CityBuilder, at: Vector3, s := 1.0) -> void:
	city.cyl(0.32 * s, 0.24 * s, 0.55 * s, at + Vector3(0, 0.275 * s, 0), city.mat(Color(0.72, 0.5, 0.32), 0.8))
	var leaf := city.mat(Color(0.24, 0.5, 0.28), 0.9)
	for k in 5:
		var b := _ball(city, at + Vector3(cos(k * 1.26) * 0.22 * s, (0.9 + (k % 2) * 0.2) * s, sin(k * 1.26) * 0.22 * s), 0.3 * s, leaf)
		b.scale = Vector3(1, 1.3, 1)


static func _ring(city: CityBuilder, at: Vector3, r: float, w: float, col: Color, energy := 1.6) -> void:
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = r
	tm.outer_radius = r + w
	tm.rings = 64
	ring.mesh = tm
	ring.material_override = city.glow_mat(col, energy)
	ring.scale = Vector3(1, 0.04, 1)
	ring.position = at
	city.add_child(ring)


# ------------------------------------------------------------------ the main hall

static func _hall(city: CityBuilder, o: Vector3, half: Vector2, hgt: float) -> void:
	var gold := Color("e0b04a")
	var stone := city.mat(Color(0.86, 0.83, 0.76), 0.5)
	var dark := city.mat(Color(0.2, 0.16, 0.12), 0.6)
	# Floor inlay: the academy crest in the middle of the hall.
	_ring(city, o + Vector3(0, 0.03, 2.0), 3.2, 0.14, gold, 1.2)
	_ring(city, o + Vector3(0, 0.03, 2.0), 2.2, 0.08, gold, 1.0)
	city.box(Vector3(3.0, 0.02, 30.0), o + Vector3(0, 0.012, 0), city.mat(Color(0.55, 0.12, 0.14), 0.95), false)
	# Columns and a gallery band.
	for sx: float in [-1.0, 1.0]:
		for z: float in [-6.0, 0.0, 6.0]:
			var cp := o + Vector3(sx * 3.2, 0, z)
			city.cyl(0.42, 0.48, hgt, cp + Vector3(0, hgt / 2.0, 0), stone)
			city.solid_cyl(0.5, 3.0, cp)
			city.cyl(0.6, 0.6, 0.3, cp + Vector3(0, 0.15, 0), stone)
			city.cyl(0.6, 0.5, 0.4, cp + Vector3(0, hgt - 0.2, 0), stone)
	city.box(Vector3(half.x * 2, 0.5, 0.4), o + Vector3(0, hgt - 1.2, -half.y + 0.2), city.mat(Color(0.82, 0.78, 0.7), 0.6), false)
	# Back wall: the name, the crest, tall windows.
	_sign(city, "DUEL ACADEMY", o + Vector3(0, hgt - 2.2, -half.y + 0.16), 0.0, Color("ffe9a8"), 210)
	for rr in [[1.2, 0.12], [0.8, 0.08]]:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = rr[0]
		tm.outer_radius = rr[0] + rr[1]
		ring.mesh = tm
		ring.material_override = city.glow_mat(gold, 1.6)
		ring.rotation.x = PI / 2
		ring.position = o + Vector3(0, hgt - 4.2, -half.y + 0.12)
		city.add_child(ring)
	for sx: float in [-1.0, 1.0]:
		for k in 2:
			var wx := sx * (6.0 + k * 4.0)
			city.box(Vector3(2.0, 4.2, 0.06), o + Vector3(wx, 3.6, -half.y + 0.05), city.glow_mat(Color(0.75, 0.88, 1.0), 0.9), false)
			city.box(Vector3(2.3, 0.18, 0.12), o + Vector3(wx, 5.75, -half.y + 0.08), dark, false)
			city.box(Vector3(0.08, 4.2, 0.1), o + Vector3(wx, 3.6, -half.y + 0.08), dark, false)
	# Chandeliers.
	for z: float in [-5.0, 4.0]:
		var c := o + Vector3(0, hgt - 1.6, z)
		city.cyl(0.04, 0.04, 1.4, c + Vector3(0, 0.8, 0), dark)
		_ring(city, c, 0.9, 0.08, Color(1.0, 0.86, 0.6), 2.4)
		for k in 6:
			_ball(city, c + Vector3(cos(k * TAU / 6.0) * 0.9, 0.12, sin(k * TAU / 6.0) * 0.9), 0.1, city.glow_mat(Color(1.0, 0.9, 0.7), 3.0))
		_light(city, c - Vector3(0, 0.6, 0), Color(1.0, 0.88, 0.7), 2.6, 14.0)
	# ---- the indoor duel arena (west)
	var ac := o + Vector3(-6.2, 0, -1.6)
	var stage := city.prop("duel_stage", ac, 0.0, 7.0)
	if stage == null:
		city.cyl(3.4, 3.6, 0.4, ac + Vector3(0, 0.2, 0), city.mat(Color(0.3, 0.32, 0.4), 0.4, 0.4), null, 40)
	_ring(city, ac + Vector3(0, 0.06, 0), 4.0, 0.12, Color("7cc4ff"), 2.0)
	var spot := SpotLight3D.new()
	spot.light_color = Color(0.85, 0.92, 1.0)
	spot.light_energy = 5.0
	spot.spot_range = 12.0
	spot.spot_angle = 32.0
	spot.position = ac + Vector3(0, hgt - 0.5, 0)
	spot.rotation_degrees = Vector3(-90, 0, 0)
	city.add_child(spot)
	_sign(city, "ARENA", o + Vector3(-half.x + 0.14, 5.0, -1.6), PI / 2, Color("7cc4ff"), 120)
	# Two rows of seats in front of the stage, where people watch.
	var seat := city.mat(Color(0.18, 0.3, 0.6), 0.6)
	for row in 2:
		for k in 5:
			var sp := o + Vector3(-12.2 + k * 3.0, 0, 2.4 + row * 1.4)
			city.box(Vector3(2.4, 0.45, 0.6), sp + Vector3(0, 0.225 + row * 0.3, 0), seat)
			city.box(Vector3(2.4, 0.6, 0.12), sp + Vector3(0, 0.75 + row * 0.3, 0.32), seat, false)
			if row == 1:
				city.box(Vector3(2.4, 0.3, 0.6), sp + Vector3(0, 0.15, 0), dark, false)
	# ---- the card shop (east)
	var counter := city.prop("shop_counter", o + Vector3(9.2, 0, -7.2), PI, 4.6)
	if counter:
		city.collide(counter, 0.95)
	else:
		city.box(Vector3(4.6, 1.05, 0.9), o + Vector3(9.2, 0.525, -7.2), city.mat(Color(0.5, 0.36, 0.24), 0.7))
	for x in [6.6, 9.2, 11.8]:
		var sh := city.prop("shop_shelf", o + Vector3(x, 0, -half.y + 0.5), 0.0, 2.6, true)
		if sh:
			city.collide(sh)
	var rack := city.prop("card_rack", o + Vector3(13.0, 0, -3.6), -0.8, 1.9, true)
	if rack:
		city.collide(rack, 0.7)
	city.box(Vector3(7.4, 0.9, 0.1), o + Vector3(9.2, 3.6, -half.y + 0.08), city.mat(Color(0.3, 0.12, 0.1), 0.6), false)
	_sign(city, "ACADEMY CARD SHOP", o + Vector3(9.2, 3.6, -half.y + 0.16), 0.0, Color("ffd166"), 70)
	var packs := ["dm", "gx", "5ds", "zexal", "beyond", "dragons"]
	for i in packs.size():
		var path := "res://assets/ui/packs/%s.jpg" % packs[i]
		if not ResourceLoader.exists(path):
			continue
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.6, 0.8)
		q.mesh = qm
		var m := StandardMaterial3D.new()
		m.albedo_texture = load(path)
		m.emission_enabled = true
		m.emission_texture = m.albedo_texture
		m.emission_energy_multiplier = 0.35
		q.material_override = m
		q.position = o + Vector3(6.4 + i * 1.1, 4.7, -half.y + 0.1)
		city.add_child(q)
	_light(city, o + Vector3(9.2, 3.2, -6.0), Color(1.0, 0.9, 0.72), 2.0, 8.0)
	# ---- the exam office (front right)
	var desk := city.mat(Color(0.42, 0.28, 0.18), 0.6)
	city.box(Vector3(1.0, 1.05, 4.0), o + Vector3(8.2, 0.525, 5.4), desk)
	city.box(Vector3(1.2, 0.08, 4.2), o + Vector3(8.2, 1.09, 5.4), city.mat(Color(0.86, 0.82, 0.74), 0.4), false)
	city.box(Vector3(0.5, 0.4, 0.6), o + Vector3(8.4, 1.33, 4.6), city.mat(Color(0.2, 0.2, 0.24), 0.5), false)
	city.box(Vector3(0.04, 0.3, 0.5), o + Vector3(8.14, 1.36, 4.6), city.glow_mat(Color("7dffb0"), 0.8), false)
	for k in 3:
		city.box(Vector3(0.3, 0.04, 0.4), o + Vector3(8.0, 1.15 + k * 0.04, 6.0), city.mat(Color(0.95, 0.95, 0.92), 0.8), false)
	city.box(Vector3(0.1, 2.2, 6.0), o + Vector3(half.x - 0.1, 2.6, 5.4), city.mat(Color(0.12, 0.2, 0.16), 0.8), false)
	_sign(city, "EXAM OFFICE", o + Vector3(half.x - 0.18, 4.2, 5.4), -PI / 2, Color("ffd166"), 90)
	for row in 3:
		_sign(city, ["RED  ·  CLASS DUELS", "YELLOW  ·  WEEKLY EXAM", "BLUE  ·  TOURNAMENT"][row], o + Vector3(half.x - 0.18, 3.1 - row * 0.5, 5.4), -PI / 2,
				[Color("ff8a8a"), Color("ffe07a"), Color("8ac4ff")][row], 40)
	city.box(Vector3(2.2, 0.03, 1.4), o + Vector3(6.6, 0.03, 5.4), city.glow_mat(Color("ffd166"), 1.2), false)
	# Benches and plants along the front.
	for sx: float in [-1.0, 1.0]:
		var bench := city.prop("bench", o + Vector3(sx * 6.0, 0, half.y - 1.6), PI, 2.0)
		if bench:
			city.collide(bench, 0.8)
		_plant(city, o + Vector3(sx * (half.x - 1.0), 0, half.y - 1.0), 1.4)
		_plant(city, o + Vector3(sx * (half.x - 1.0), 0, -half.y + 1.4), 1.4)
	for sx: float in [-1.0, 1.0]:
		var st := city.prop("dragon_statue", o + Vector3(sx * 2.0, 0, -half.y + 1.6), 0.0, 3.0, true)
		if st:
			city.collide(st, 0.6)


# ------------------------------------------------------------------ red dorm

static func _red(city: CityBuilder, o: Vector3, half: Vector2, hgt: float) -> void:
	var wood := city.mat(Color(0.46, 0.3, 0.2), 0.8)
	var light_wood := city.mat(Color(0.66, 0.5, 0.34), 0.8)
	var red := city.mat(Color("c8322a"), 0.7)
	# Plank walls and exposed beams.
	for i in range(-6, 7):
		city.box(Vector3(0.04, hgt, 0.02), o + Vector3(i * 1.0, hgt / 2.0, -half.y + 0.03), wood, false)
	for i in 4:
		city.box(Vector3(half.x * 2, 0.22, 0.22), o + Vector3(0, hgt - 0.12, -half.y + 1.4 + i * 2.6), wood, false)
	_sign(city, "RED DORM", o + Vector3(0, hgt - 0.7, -half.y + 0.1), 0.0, Color("ff8a8a"), 90)
	# Two bunk beds on the left wall.
	for k in 2:
		var bp := o + Vector3(-half.x + 0.7, 0, -3.2 + k * 2.6)
		for lv in 2:
			var y := 0.45 + lv * 1.3
			city.box(Vector3(1.0, 0.18, 2.1), bp + Vector3(0, y, 0), light_wood)
			city.box(Vector3(0.9, 0.16, 1.9), bp + Vector3(0.0, y + 0.17, 0.05), city.mat(Color(0.94, 0.92, 0.86), 0.9), false)
			city.box(Vector3(0.9, 0.14, 1.0), bp + Vector3(0.0, y + 0.3, 0.45), red, false)
			city.box(Vector3(0.5, 0.14, 0.32), bp + Vector3(0.0, y + 0.32, -0.75), city.mat(Color.WHITE, 0.9), false)
		for c in [Vector2(-0.45, -1.0), Vector2(0.45, -1.0), Vector2(-0.45, 1.0), Vector2(0.45, 1.0)]:
			city.box(Vector3(0.08, 2.6, 0.08), bp + Vector3(c.x, 1.3, c.y), wood, false)
		_block(city, Vector3(1.1, 2.6, 2.2), bp + Vector3(0, 1.3, 0))
	# A low table with cushions in the middle.
	var t := o + Vector3(0.2, 0, -0.6)
	city.box(Vector3(2.2, 0.08, 1.4), t + Vector3(0, 0.42, 0), light_wood)
	for c in [Vector2(-1.0, -0.6), Vector2(1.0, -0.6), Vector2(-1.0, 0.6), Vector2(1.0, 0.6)]:
		city.box(Vector3(0.1, 0.4, 0.1), t + Vector3(c.x, 0.2, c.y), wood, false)
	for c in [Vector3(-1.4, 0, 0), Vector3(1.4, 0, 0), Vector3(0, 0, 1.1)]:
		city.box(Vector3(0.7, 0.14, 0.7), t + c + Vector3(0, 0.07, 0), red, false)
	for k in 5:
		city.box(Vector3(0.2, 0.01, 0.28), t + Vector3(-0.6 + k * 0.3, 0.47, 0.1 * sin(k)), city.mat(Color("f2d27a") if k % 2 == 0 else Color("8a4fd9"), 0.6), false)
	# A bowl of fried shrimp, obviously.
	city.cyl(0.22, 0.16, 0.12, t + Vector3(0.7, 0.52, -0.3), city.mat(Color(0.95, 0.95, 0.92), 0.5))
	for k in 3:
		var sh := city.box(Vector3(0.06, 0.06, 0.26), t + Vector3(0.66 + k * 0.05, 0.6, -0.3), city.mat(Color("e8a040"), 0.8), false)
		sh.rotation.y = k * 0.5
	# Fridge, a small TV on a crate, posters and a window.
	city.box(Vector3(0.8, 1.6, 0.7), o + Vector3(half.x - 0.5, 0.8, -half.y + 0.5), city.mat(Color(0.92, 0.92, 0.9), 0.4, 0.2))
	city.box(Vector3(0.04, 0.5, 0.04), o + Vector3(half.x - 0.85, 1.1, -half.y + 0.86), city.mat(Color(0.6, 0.6, 0.62), 0.3, 0.8), false)
	city.box(Vector3(1.2, 0.6, 0.6), o + Vector3(half.x - 0.7, 0.3, -half.y + 2.2), wood)
	city.box(Vector3(0.9, 0.6, 0.5), o + Vector3(half.x - 0.7, 0.9, -half.y + 2.2), city.mat(Color(0.12, 0.12, 0.14), 0.5))
	city.box(Vector3(0.03, 0.46, 0.38), o + Vector3(half.x - 1.16, 0.92, -half.y + 2.2), city.glow_mat(Color("7cc4ff"), 0.9), false)
	for k in 3:
		city.box(Vector3(0.7, 0.9, 0.02), o + Vector3(-1.8 + k * 1.6, 2.1, -half.y + 0.06), city.mat([Color("ffd166"), Color("7dd3ff"), Color("ff8a8a")][k], 0.8), false)
	_light(city, o + Vector3(0, hgt - 0.6, -1.0), Color(1.0, 0.8, 0.55), 2.0, 9.0)
	_ball(city, o + Vector3(0, hgt - 0.35, -1.0), 0.16, city.glow_mat(Color(1.0, 0.82, 0.5), 3.0))
	_upstairs(city, o, half, hgt, {"h": 3.4, "side": 1.0, "rooms": 3, "wood": city.surf("wood", Color(0.5, 0.34, 0.22)),
		"wall": city.surf("wood", Color(0.72, 0.56, 0.4)), "floor": city.surf("wood", Color(0.6, 0.44, 0.3)), "rail": city.mat(Color(0.3, 0.2, 0.13), 0.7),
		"accent": Color("c8322a"), "first": 101})


# ------------------------------------------------------------------ yellow dorm

static func _yellow(city: CityBuilder, o: Vector3, half: Vector2, hgt: float) -> void:
	var wood := city.mat(Color(0.58, 0.4, 0.24), 0.7)
	var yellow := city.mat(Color("f2c230"), 0.6)
	_sign(city, "YELLOW DORM  ·  STUDY HALL", o + Vector3(0, hgt - 0.8, -half.y + 0.12), 0.0, Color("ffe07a"), 80)
	# Chalkboard with notes.
	city.box(Vector3(5.0, 1.8, 0.08), o + Vector3(-3.2, 2.2, -half.y + 0.06), city.mat(Color(0.12, 0.22, 0.16), 0.9), false)
	city.box(Vector3(5.2, 0.12, 0.14), o + Vector3(-3.2, 1.25, -half.y + 0.1), wood, false)
	for row in 4:
		city.box(Vector3(1.4 + (row % 2) * 1.2, 0.05, 0.02), o + Vector3(-4.4 + (row % 2) * 0.6, 2.8 - row * 0.35, -half.y + 0.11), city.mat(Color(0.95, 0.95, 0.9), 0.9), false)
	# Study desks in rows, each with a lamp and books.
	for row in 2:
		for k in 2:
			var dp := o + Vector3(-5.2 + k * 3.6, 0, -1.4 + row * 4.0)
			city.box(Vector3(2.6, 0.08, 1.0), dp + Vector3(0, 0.76, 0), wood)
			for c in [Vector2(-1.2, -0.42), Vector2(1.2, -0.42), Vector2(-1.2, 0.42), Vector2(1.2, 0.42)]:
				city.box(Vector3(0.07, 0.76, 0.07), dp + Vector3(c.x, 0.38, c.y), wood, false)
			city.cyl(0.03, 0.03, 0.42, dp + Vector3(0.9, 1.0, -0.2), city.mat(Color(0.2, 0.2, 0.22), 0.4, 0.6))
			city.cyl(0.06, 0.16, 0.14, dp + Vector3(0.9, 1.24, -0.12), yellow)
			_light(city, dp + Vector3(0.9, 1.1, 0), Color(1.0, 0.9, 0.6), 0.6, 3.0)
			for b in 3:
				city.box(Vector3(0.22, 0.05, 0.3), dp + Vector3(-0.8, 0.83 + b * 0.05, 0), city.mat([Color("2f6fe0"), Color("d9342b"), Color("3fbf8a")][b], 0.8), false)
			for sx: float in [-1.0, 1.0]:
				var ch := dp + Vector3(sx * 0.6, 0, 0.75)
				city.box(Vector3(0.48, 0.06, 0.48), ch + Vector3(0, 0.46, 0), wood, false)
				city.box(Vector3(0.48, 0.5, 0.06), ch + Vector3(0, 0.72, 0.22), wood, false)
	# Bookshelves down the right wall.
	for z: float in [-3.0, 0.2, 3.4]:
		city.box(Vector3(0.5, 2.6, 2.6), o + Vector3(half.x - 0.3, 1.3, z), wood)
		for shelf in 4:
			for b in 7:
				var bh := 0.36 + 0.08 * ((b * 3 + shelf) % 3)
				city.box(Vector3(0.3, bh, 0.24), o + Vector3(half.x - 0.58, 0.32 + shelf * 0.62 + bh / 2.0, z - 1.0 + b * 0.32),
						city.mat([Color("2f6fe0"), Color("d9342b"), Color("3fbf8a"), Color("f2c230"), Color("8a4fd9")][(b + shelf) % 5], 0.8), false)
	# The curry kitchen corner.
	city.box(Vector3(4.6, 1.0, 0.8), o + Vector3(5.6, 0.5, -half.y + 0.5), city.mat(Color(0.9, 0.88, 0.84), 0.4))
	city.box(Vector3(4.7, 0.06, 0.9), o + Vector3(5.6, 1.03, -half.y + 0.5), city.mat(Color(0.3, 0.3, 0.32), 0.3, 0.6), false)
	city.cyl(0.36, 0.32, 0.42, o + Vector3(5.0, 1.27, -half.y + 0.5), city.mat(Color(0.25, 0.25, 0.28), 0.3, 0.8))
	city.cyl(0.33, 0.33, 0.02, o + Vector3(5.0, 1.47, -half.y + 0.5), city.mat(Color("c98a2a"), 0.6))
	_sign(city, "CURRY", o + Vector3(5.6, 2.6, -half.y + 0.12), 0.0, Color("ffb030"), 70)
	var dining := o + Vector3(5.6, 0, -1.6)
	city.box(Vector3(3.4, 0.08, 1.4), dining + Vector3(0, 0.76, 0), wood)
	for c in [Vector2(-1.6, -0.6), Vector2(1.6, -0.6), Vector2(-1.6, 0.6), Vector2(1.6, 0.6)]:
		city.box(Vector3(0.08, 0.76, 0.08), dining + Vector3(c.x, 0.38, c.y), wood, false)
	for k in 4:
		city.cyl(0.18, 0.14, 0.08, dining + Vector3(-1.2 + k * 0.8, 0.84, 0), city.mat(Color.WHITE, 0.5))
		city.cyl(0.14, 0.14, 0.02, dining + Vector3(-1.2 + k * 0.8, 0.88, 0), city.mat(Color("c98a2a"), 0.6))
	_plant(city, o + Vector3(-half.x + 0.9, 0, half.y - 0.9), 1.2)
	_plant(city, o + Vector3(half.x - 1.2, 0, half.y - 0.9), 1.2)
	for x: float in [-4.0, 0.0, 4.0]:
		_light(city, o + Vector3(x, hgt - 0.5, 0), Color(1.0, 0.92, 0.72), 1.6, 9.0)
		city.box(Vector3(1.4, 0.06, 0.4), o + Vector3(x, hgt - 0.05, 0), city.glow_mat(Color(1.0, 0.95, 0.8), 2.0), false)
	_upstairs(city, o, half, hgt, {"h": 3.4, "side": -1.0, "rooms": 4, "wood": city.surf("wood", Color(0.6, 0.42, 0.26)),
		"wall": city.surf("plaster", Color(0.98, 0.93, 0.76)), "floor": city.surf("wood", Color(0.7, 0.54, 0.36)), "rail": city.mat(Color(0.5, 0.36, 0.2), 0.6),
		"accent": Color("f2c230"), "first": 201})


# ------------------------------------------------------------------ blue dorm

static func _blue(city: CityBuilder, o: Vector3, half: Vector2, hgt: float) -> void:
	var white := city.mat(Color(0.95, 0.96, 0.98), 0.25, 0.1)
	var blue := city.mat(Color("2f5fc0"), 0.7)
	var gold := city.mat(Color(0.86, 0.7, 0.32), 0.3, 0.8)
	var dark_wood := city.mat(Color(0.28, 0.16, 0.1), 0.4)
	# A long blue carpet from the door to the stairs, with a gold edge.
	city.box(Vector3(3.2, 0.02, half.y * 2 - 2.0), o + Vector3(0, 0.012, 1.0), blue, false)
	for sx: float in [-1.0, 1.0]:
		city.box(Vector3(0.1, 0.022, half.y * 2 - 2.0), o + Vector3(sx * 1.6, 0.013, 1.0), gold, false)
	# Grand staircase up to a landing on the back wall.
	var steps := 9
	var sz0 := -half.y + 6.25                 # the first step; the ninth meets the landing
	for i in steps:
		var y := (i + 1) * 0.28
		city.box(Vector3(5.0, 0.28, 0.5), o + Vector3(0, y - 0.14, sz0 - i * 0.5), white, false)
		city.box(Vector3(5.0, y - 0.28, 0.5), o + Vector3(0, (y - 0.28) / 2.0, sz0 - i * 0.5), white, false)
		city.box(Vector3(3.2, 0.02, 0.5), o + Vector3(0, y + 0.01, sz0 - i * 0.5), blue, false)
	# What your feet walk on: one smooth ramp under the steps, and a wall each side of it.
	_ramp(city, o + Vector3(0, 0, sz0 + 0.5), o + Vector3(0, steps * 0.28, sz0 - steps * 0.5 + 0.25), 5.0)
	for sx: float in [-1.0, 1.0]:
		_block(city, Vector3(0.12, 3.6, 4.6), o + Vector3(sx * 2.56, 1.8, sz0 - 2.0))
	city.box(Vector3(half.x * 2, 0.3, 2.0), o + Vector3(0, steps * 0.28 - 0.15, -half.y + 1.0), white)
	city.box(Vector3(half.x * 2, 0.02, 1.2), o + Vector3(0, steps * 0.28 + 0.01, -half.y + 1.0), blue, false)
	for sx: float in [-1.0, 1.0]:
		for i in steps + 1:
			city.cyl(0.04, 0.04, 0.9, o + Vector3(sx * 2.5, i * 0.28 + 0.45, sz0 + 0.25 - i * 0.5), gold)
		var rail := city.box(Vector3(0.1, 0.1, 5.2), o + Vector3(sx * 2.5, steps * 0.14 + 0.9, sz0 - 2.0), gold, false)
		rail.rotation.x = atan2(steps * 0.28, steps * 0.5)
		# A balustrade along the landing either side of the stairs.
		var la := 2.6
		var lb := half.x - 0.1
		city.box(Vector3(lb - la, 0.08, 0.08), o + Vector3(sx * (la + lb) / 2.0, steps * 0.28 + 0.95, -half.y + 1.95), gold, false)
		for k in 8:
			city.cyl(0.035, 0.035, 0.95, o + Vector3(sx * lerpf(la, lb, k / 7.0), steps * 0.28 + 0.475, -half.y + 1.95), gold, null, 8)
		_block(city, Vector3(lb - la, 1.1, 0.1), o + Vector3(sx * (la + lb) / 2.0, steps * 0.28 + 0.55, -half.y + 1.95))
	_sign(city, "BLUE DORM", o + Vector3(0, hgt - 1.0, -half.y + 0.12), 0.0, Color("9cc8ff"), 150)
	# Portraits of past champions along the landing.
	for k in 4:
		var px := -7.5 + k * 5.0
		if absf(px) < 3.0:
			continue
		city.box(Vector3(1.6, 2.0, 0.1), o + Vector3(px, steps * 0.28 + 1.8, -half.y + 0.08), gold, false)
		city.box(Vector3(1.36, 1.76, 0.04), o + Vector3(px, steps * 0.28 + 1.8, -half.y + 0.14), city.mat([Color("2f4a7a"), Color("4a2f6a"), Color("2f6a5a"), Color("6a3a2f")][k], 0.8), false)
	# Columns.
	for sx: float in [-1.0, 1.0]:
		for z: float in [-2.0, 3.5]:
			var cp := o + Vector3(sx * 4.6, 0, z)
			city.cyl(0.45, 0.45, hgt, cp + Vector3(0, hgt / 2.0, 0), white)
			city.solid_cyl(0.5, 3.0, cp)
			city.cyl(0.6, 0.6, 0.3, cp + Vector3(0, 0.15, 0), gold)
			city.cyl(0.6, 0.6, 0.3, cp + Vector3(0, hgt - 0.15, 0), gold)
	# The chandelier.
	var ch := o + Vector3(0, hgt - 1.8, 1.0)
	city.cyl(0.04, 0.04, 1.6, ch + Vector3(0, 0.9, 0), gold)
	for tier in 2:
		_ring(city, ch + Vector3(0, -tier * 0.5, 0), 1.3 - tier * 0.5, 0.08, Color(1.0, 0.9, 0.65), 2.4)
		for k in 8:
			var a := k * TAU / 8.0
			_ball(city, ch + Vector3(cos(a) * (1.3 - tier * 0.5), 0.12 - tier * 0.5, sin(a) * (1.3 - tier * 0.5)), 0.09, city.glow_mat(Color(1.0, 0.95, 0.8), 3.4))
	_light(city, ch - Vector3(0, 0.8, 0), Color(1.0, 0.92, 0.8), 3.0, 16.0)
	# Sitting room (west): sofas facing a fireplace.
	var fp := o + Vector3(-half.x + 0.5, 0, -1.0)
	city.box(Vector3(1.0, 2.4, 3.2), fp + Vector3(0, 1.2, 0), white)
	city.box(Vector3(0.6, 1.0, 1.6), fp + Vector3(0.25, 0.6, 0), city.mat(Color(0.08, 0.06, 0.06), 0.9), false)
	city.box(Vector3(0.3, 0.5, 1.2), fp + Vector3(0.3, 0.35, 0), city.glow_mat(Color(1.0, 0.5, 0.15), 2.6), false)
	_light(city, fp + Vector3(1.0, 0.8, 0), Color(1.0, 0.55, 0.25), 2.2, 7.0)
	city.box(Vector3(1.2, 0.1, 3.6), fp + Vector3(0.1, 2.45, 0), gold, false)
	var sofa := city.mat(Color("1f3f8a"), 0.8)
	for s in [[Vector3(-7.2, 0, 1.6), 0.0], [Vector3(-7.2, 0, -3.6), PI]]:
		var sp: Vector3 = o + s[0]
		var holder := Node3D.new()
		holder.position = sp
		holder.rotation.y = s[1]
		city.add_child(holder)
		city.box(Vector3(3.0, 0.45, 0.9), Vector3(0, 0.225, 0), sofa, false, holder)
		_block(city, Vector3(3.2, 1.0, 1.0), sp + Vector3(0, 0.5, 0))
		city.box(Vector3(3.0, 0.7, 0.24), Vector3(0, 0.75, 0.36), sofa, false, holder)
		for sx: float in [-1.0, 1.0]:
			city.box(Vector3(0.24, 0.65, 0.9), Vector3(sx * 1.38, 0.5, 0), sofa, false, holder)
	city.box(Vector3(1.8, 0.08, 1.2), o + Vector3(-7.2, 0.45, -1.0), dark_wood)
	city.box(Vector3(1.4, 0.4, 0.8), o + Vector3(-7.2, 0.2, -1.0), dark_wood, false)
	# A piano in the corner.
	var pn := o + Vector3(-9.4, 0, -6.0)
	city.box(Vector3(1.6, 1.1, 0.7), pn + Vector3(0, 0.55, 0), city.mat(Color(0.05, 0.05, 0.06), 0.15, 0.3))
	city.box(Vector3(1.4, 0.06, 0.28), pn + Vector3(0, 0.78, 0.45), city.mat(Color(0.95, 0.95, 0.95), 0.3), false)
	# Duel corner (east): a table and a holo pylon.
	var dt := city.prop("duel_table", o + Vector3(7.6, 0, 1.4), 0.0, 2.4)
	if dt:
		city.collide(dt, 0.75)
	var py := city.prop("holo_pylon", o + Vector3(half.x - 1.0, 0, -4.0), -PI / 2, 3.2, true)
	if py:
		city.collide(py, 0.5)
	_upstairs(city, o, half, hgt, {"h": 3.8, "side": 1.0, "rooms": 4, "wood": white,
		"wall": city.surf("plaster", Color(0.93, 0.95, 0.99)), "floor": city.mat(Color(0.82, 0.84, 0.9), 0.35, 0.1), "rail": gold,
		"accent": Color("2f5fc0"), "first": 301, "depth": 5.4})
	for sx: float in [-1.0, 1.0]:
		_plant(city, o + Vector3(sx * (half.x - 1.0), 0, half.y - 1.2), 1.5)
		city.box(Vector3(0.06, 3.6, 2.0), o + Vector3(sx * (half.x - 0.04), 3.4, 3.0), city.glow_mat(Color(0.75, 0.88, 1.0), 0.9), false)
		for fz: float in [-1.0, 1.0]:
			city.box(Vector3(0.1, 3.8, 0.12), o + Vector3(sx * (half.x - 0.08), 3.4, 3.0 + fz * 1.0), gold, false)
		city.box(Vector3(0.1, 0.12, 2.1), o + Vector3(sx * (half.x - 0.08), 5.25, 3.0), gold, false)


# ------------------------------------------------------------------ upstairs

## An invisible ramp from `foot` (on the floor) up to `head`, `width` wide. Steps are only for
## show: this is what you actually walk on, so climbing is smooth.
static func _ramp(city: CityBuilder, foot: Vector3, head: Vector3, width: float) -> void:
	var run := Vector2(head.x - foot.x, head.z - foot.z).length()
	var rise := head.y - foot.y
	var length := sqrt(run * run + rise * rise)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(width, 0.2, length)
	cs.shape = sh
	body.add_child(cs)
	city.add_child(body)
	var mid := (foot + head) / 2.0
	# Local +Z runs up the slope; drop it half its thickness so the top face is the walking line.
	var fwd := (head - foot).normalized()
	var right := Vector3.UP.cross(fwd).normalized()
	var up := fwd.cross(right).normalized()
	body.transform = Transform3D(Basis(right, up, fwd), mid - up * 0.1)


## The upper floor of a dorm: a gallery over the entrance, reached by a staircase along one
## side wall, with a row of bedrooms you can walk into. cfg: h (floor height), side (which wall
## the stairs climb: -1 left, 1 right), rooms, wood / wall / floor / rail materials, accent
## color, first (number on the first door), depth.
static func _upstairs(city: CityBuilder, o: Vector3, half: Vector2, hgt: float, cfg: Dictionary) -> void:
	var H: float = cfg["h"]
	var side: float = cfg["side"]
	var depth: float = cfg.get("depth", 4.7)
	var wood: Material = cfg["wood"]
	var wall: Material = cfg["wall"]
	var floor_m: Material = cfg["floor"]
	var rail_m: Material = cfg["rail"]
	var accent: Color = cfg["accent"]
	var n: int = cfg["rooms"]
	var ze := half.y - depth                   # the gallery's open edge
	var zw := ze + 1.55                        # the wall the bedroom doors are in
	var stair_w := 1.5
	var xs := side * (half.x - stair_w / 2.0)
	# The floor and the beam along its edge.
	city.box(Vector3(half.x * 2, 0.24, depth), o + Vector3(0, H - 0.12, half.y - depth / 2.0), floor_m)
	city.box(Vector3(half.x * 2, 0.36, 0.22), o + Vector3(0, H - 0.2, ze + 0.02), wood, false)
	city.box(Vector3(half.x * 2, 0.04, depth - 0.1), o + Vector3(0, H - 0.26, half.y - depth / 2.0), city.mat(Color(0.82, 0.8, 0.76), 0.9), false)
	for px: float in [-half.x * 0.5, half.x * 0.5]:
		city.box(Vector3(0.26, H - 0.24, 0.26), o + Vector3(px, (H - 0.24) / 2.0, ze + 0.1), wood, false)
		city.solid_cyl(0.2, H - 0.3, o + Vector3(px, (H - 0.3) / 2.0, ze + 0.1))
	for lx: float in [-half.x * 0.5, half.x * 0.5]:
		_light(city, o + Vector3(lx, H - 0.6, half.y - depth / 2.0), Color(1.0, 0.9, 0.72), 1.3, 6.5)
		city.box(Vector3(0.8, 0.05, 0.3), o + Vector3(lx, H - 0.3, half.y - depth / 2.0), city.glow_mat(Color(1.0, 0.94, 0.8), 2.0), false)
	# ---- the staircase
	var run := H * 1.5
	var z0 := ze - run
	var foot := o + Vector3(xs, 0, z0)
	var head := o + Vector3(xs, H, ze)
	_ramp(city, foot + Vector3(0, 0, -0.25), head + Vector3(0, 0, 0.0), stair_w)
	var count := int(ceil(H / 0.19))
	var rise := H / count
	var tread := run / count
	for i in count:
		city.box(Vector3(stair_w - 0.08, 0.06, tread + 0.05), o + Vector3(xs, (i + 1) * rise - 0.03, z0 + (i + 0.5) * tread), floor_m, false)
		city.box(Vector3(stair_w - 0.12, rise - 0.06, 0.04), o + Vector3(xs, (i + 0.5) * rise - 0.03, z0 + i * tread + 0.02), wood, false)
	var slope := atan2(H, run)
	var length := sqrt(run * run + H * H)
	var inner := xs - side * (stair_w / 2.0)             # the open side of the stairs
	for sx2: float in [inner, xs + side * (stair_w / 2.0 - 0.06)]:
		var stringer := city.box(Vector3(0.1, 0.36, length), o + Vector3(sx2, H / 2.0 - 0.12, z0 + run / 2.0), wood, false)
		stringer.rotation.x = -slope
	var hand := city.box(Vector3(0.08, 0.08, length), o + Vector3(inner, H / 2.0 + 0.98, z0 + run / 2.0), rail_m, false)
	hand.rotation.x = -slope
	for i in range(0, count + 1, 2):
		city.box(Vector3(0.06, 0.98, 0.06), o + Vector3(inner, i * rise + 0.49, z0 + i * tread), rail_m, false)
	# Nobody steps off the open side: a thin wall that follows the handrail.
	var guard := StaticBody3D.new()
	var gcs := CollisionShape3D.new()
	var gsh := BoxShape3D.new()
	gsh.size = Vector3(0.1, 1.2, length)
	gcs.shape = gsh
	guard.add_child(gcs)
	city.add_child(guard)
	guard.position = o + Vector3(inner, H / 2.0 + 0.6, z0 + run / 2.0)
	guard.rotation.x = -slope
	# ---- the railing along the gallery, open where the stairs arrive
	var open_a := minf(inner, xs + side * stair_w / 2.0)
	var open_b := maxf(inner, xs + side * stair_w / 2.0)
	var spans: Array = [[-half.x, open_a], [open_b, half.x]]
	for sp in spans:
		var a: float = sp[0]
		var b: float = sp[1]
		if b - a < 0.3:
			continue
		city.box(Vector3(b - a, 0.08, 0.08), o + Vector3((a + b) / 2.0, H + 1.0, ze + 0.08), rail_m, false)
		city.box(Vector3(b - a, 0.05, 0.05), o + Vector3((a + b) / 2.0, H + 0.5, ze + 0.08), rail_m, false)
		var posts := int((b - a) / 1.1) + 1
		for k in posts + 1:
			city.box(Vector3(0.06, 1.0, 0.06), o + Vector3(lerpf(a, b, float(k) / posts), H + 0.5, ze + 0.08), rail_m, false)
		_block(city, Vector3(b - a, 1.2, 0.1), o + Vector3((a + b) / 2.0, H + 0.6, ze + 0.08))
	# A runner down the corridor.
	city.box(Vector3(half.x * 2 - stair_w - 0.6, 0.015, 0.9), o + Vector3(-side * (stair_w / 2.0), H + 0.01, ze + 0.85), city.mat(accent.darkened(0.15), 0.9), false)
	# ---- the bedrooms
	var room_h := hgt - H
	var bw := (half.x * 2) / n
	var rng := RandomNumberGenerator.new()
	rng.seed = int(cfg["first"])
	var blanket := city.mat(accent, 0.85)
	var linen := city.mat(Color(0.95, 0.94, 0.9), 0.9)
	var dark := city.mat(Color(0.16, 0.16, 0.2), 0.6)
	var posters := [Color("ffd166"), Color("7dd3ff"), Color("ff8a8a"), Color("b79cff"), Color("8be0a4")]
	for i in n:
		var xa := -half.x + i * bw
		var xb := xa + bw
		var xm := (xa + xb) / 2.0
		var dw := 1.15
		# The corridor wall with its doorway, and the wall between this room and the next.
		for seg in [[xa, xm - dw / 2.0], [xm + dw / 2.0, xb]]:
			var sa: float = seg[0]
			var sb: float = seg[1]
			city.box(Vector3(sb - sa, room_h, 0.14), o + Vector3((sa + sb) / 2.0, H + room_h / 2.0, zw), wall)
		city.box(Vector3(dw, room_h - 2.15, 0.14), o + Vector3(xm, H + 2.15 + (room_h - 2.15) / 2.0, zw), wall, false)
		for fx: float in [-1.0, 1.0]:
			city.box(Vector3(0.09, 2.2, 0.2), o + Vector3(xm + fx * (dw / 2.0 + 0.02), H + 1.1, zw), wood, false)
		city.box(Vector3(dw + 0.22, 0.1, 0.2), o + Vector3(xm, H + 2.2, zw), wood, false)
		# The door stands open, swung back against the wall inside.
		var leaf := city.box(Vector3(dw - 0.08, 2.08, 0.05), o + Vector3(xm - dw / 2.0 + 0.04, H + 1.05, zw + 0.07 + (dw - 0.08) / 2.0), wood, false)
		leaf.rotation.y = PI / 2.0
		city.box(Vector3(0.05, 0.12, 0.05), o + Vector3(xm - dw / 2.0 + 0.1, H + 1.02, zw + dw - 0.12), city.mat(Color(0.86, 0.7, 0.32), 0.3, 0.8), false)
		_sign(city, str(int(cfg["first"]) + i), o + Vector3(xm + dw / 2.0 + 0.42, H + 1.75, zw - 0.09), PI, accent.lightened(0.45), 34)
		if i > 0:
			city.box(Vector3(0.14, room_h, half.y - zw), o + Vector3(xa, H + room_h / 2.0, (zw + half.y) / 2.0), wall)
		# Bed along the outside wall, under the window.
		var bx := xm + (0.25 if i % 2 == 0 else -0.25)
		var bz := half.y - 0.62
		city.box(Vector3(2.05, 0.3, 1.0), o + Vector3(bx, H + 0.2, bz), wood, false)
		city.box(Vector3(1.95, 0.16, 0.92), o + Vector3(bx, H + 0.42, bz), linen, false)
		city.box(Vector3(1.25, 0.1, 0.96), o + Vector3(bx + 0.34, H + 0.5, bz), blanket, false)
		city.box(Vector3(0.42, 0.12, 0.6), o + Vector3(bx - 0.72, H + 0.55, bz), linen, false)
		city.box(Vector3(0.08, 0.75, 1.0), o + Vector3(bx - 1.02, H + 0.5, bz), wood, false)
		_block(city, Vector3(2.1, 0.7, 1.0), o + Vector3(bx, H + 0.35, bz))
		# Window over the bed: frame, glass with daylight, a cross bar and a sill.
		var wy := H + 1.65
		city.box(Vector3(1.5, 1.2, 0.06), o + Vector3(xm, wy, half.y - 0.03), wood, false)
		city.box(Vector3(1.32, 1.02, 0.03), o + Vector3(xm, wy, half.y - 0.07), city.glow_mat(Color(0.72, 0.88, 1.0), 1.1), false)
		city.box(Vector3(0.05, 1.02, 0.04), o + Vector3(xm, wy, half.y - 0.09), wood, false)
		city.box(Vector3(1.32, 0.05, 0.04), o + Vector3(xm, wy, half.y - 0.09), wood, false)
		city.box(Vector3(1.6, 0.06, 0.2), o + Vector3(xm, wy - 0.64, half.y - 0.1), wood, false)
		for cs2: float in [-1.0, 1.0]:
			city.box(Vector3(0.3, 1.3, 0.05), o + Vector3(xm + cs2 * 0.86, wy, half.y - 0.12), blanket, false)
		# Desk and chair against the side wall, a lamp, a few cards and a book.
		var dx := xa + 0.42 if i % 2 == 0 else xb - 0.42
		var ds := 1.0 if i % 2 == 0 else -1.0
		var dz := zw + 0.95
		city.box(Vector3(0.6, 0.06, 1.2), o + Vector3(dx, H + 0.76, dz), wood, false)
		for lz: float in [-0.52, 0.52]:
			city.box(Vector3(0.52, 0.74, 0.06), o + Vector3(dx, H + 0.37, dz + lz), wood, false)
		_block(city, Vector3(0.6, 0.8, 1.2), o + Vector3(dx, H + 0.4, dz))
		city.cyl(0.025, 0.025, 0.34, o + Vector3(dx - ds * 0.12, H + 0.96, dz - 0.4), dark, null, 8)
		city.cyl(0.05, 0.13, 0.12, o + Vector3(dx - ds * 0.12, H + 1.16, dz - 0.4), blanket, null, 10)
		for k in 3:
			var card := city.box(Vector3(0.13, 0.008, 0.19), o + Vector3(dx + ds * 0.02, H + 0.8, dz + 0.02 + k * 0.17), city.mat(posters[(i + k) % posters.size()], 0.6), false)
			card.rotation.y = rng.randf_range(-0.4, 0.4)
		city.box(Vector3(0.42, 0.05, 0.42), o + Vector3(dx + ds * 0.62, H + 0.46, dz), wood, false)
		city.box(Vector3(0.05, 0.5, 0.42), o + Vector3(dx + ds * 0.84, H + 0.72, dz), wood, false)
		for c in [Vector2(-0.18, -0.18), Vector2(0.18, -0.18), Vector2(-0.18, 0.18), Vector2(0.18, 0.18)]:
			city.box(Vector3(0.04, 0.44, 0.04), o + Vector3(dx + ds * 0.62 + c.x, H + 0.22, dz + c.y), wood, false)
		# A rug, a shelf with a trophy and books, two posters, a ceiling light.
		city.box(Vector3(1.7, 0.014, 1.15), o + Vector3(xm, H + 0.008, zw + 1.35), city.mat(accent.lerp(Color(0.9, 0.86, 0.78), 0.55), 0.95), false)
		city.box(Vector3(1.3, 0.016, 0.8), o + Vector3(xm, H + 0.009, zw + 1.35), city.mat(accent.darkened(0.1), 0.95), false)
		var shx := xb - 0.12 if i % 2 == 0 else xa + 0.12
		city.box(Vector3(0.22, 0.04, 1.3), o + Vector3(shx - ds * 0.04, H + 1.6, zw + 1.6), wood, false)
		for b2 in 5:
			var bh := 0.2 + 0.05 * ((b2 * 2 + i) % 3)
			city.box(Vector3(0.16, bh, 0.06), o + Vector3(shx - ds * 0.04, H + 1.62 + bh / 2.0, zw + 1.1 + b2 * 0.09), city.mat(posters[(b2 + i) % posters.size()].darkened(0.2), 0.8), false)
		city.cyl(0.05, 0.03, 0.14, o + Vector3(shx - ds * 0.04, H + 1.69, zw + 2.05), city.mat(Color(0.9, 0.74, 0.3), 0.3, 0.8), null, 10)
		for k in 2:
			var pz := zw + 0.6 + k * 1.2
			var px2 := (xb - 0.08) if i % 2 == 0 else (xa + 0.08)
			if i == n - 1 and i % 2 == 0:
				px2 = xb - 0.01
			if i == 0 and i % 2 == 1:
				px2 = xa + 0.01
			city.box(Vector3(0.02, 0.8, 0.58), o + Vector3(px2, H + 2.25 - k * 0.0, pz), city.mat(posters[(i * 2 + k + 1) % posters.size()], 0.85), false)
		_light(city, o + Vector3(xm, hgt - 0.5, zw + 1.5), Color(1.0, 0.92, 0.78), 1.1, 5.0)
		_ball(city, o + Vector3(xm, hgt - 0.22, zw + 1.5), 0.12, city.glow_mat(Color(1.0, 0.92, 0.75), 2.6))
